#!/usr/bin/python
# -*- coding: utf-8 -*-

"""
Copyright (c) 2012, Rui Carmo
Description: In-process job management
License: MIT (see LICENSE.md for details)
"""

from Queue import Empty, Queue, PriorityQueue
from collections import defaultdict
from functools import partial
from signal import signal, SIGINT, SIGTERM, SIGHUP
import sys, logging 
from threading import Semaphore, Thread
import time, traceback, ctypes
from uuid import uuid4
from cPickle import dumps, loads
import multiprocessing

log = logging.getLogger(__name__)

DEFAULT_PRIORITY = 0
MAX_WORKERS = multiprocessing.cpu_count() * 2
channels = {}
closed = {}

class Pool:
    """Represents a thread pool"""

    def __init__(self, workers = MAX_WORKERS, rate_limit = 1000):
        self.MAX_WORKERS = workers
        self.mutex       = Semaphore()
        self.results     = {}
        self.retries     = defaultdict(int)
        self.queue       = PriorityQueue()
        self.threads     = []
        self.rate_limit  = rate_limit
        self.running     = True

    def _tick(self):
        time.sleep(1.0/self.rate_limit)
        # clean up finished threads
        self.threads = [t for t in self.threads if t.isAlive()]
        return (not self.queue.empty()) or (len(self.threads) > 0)


    def _loop(self):
        """Handle task submissions"""

        def run_task(priority, f, uuid, retries, args, kwargs):
            """Run a single task"""
            try:
                t.name = getattr(f, '__name__', None)
                result = f(*args, **kwargs)
            except Exception as e:
                # Retry the task if applicable
                if log:
                    log.error(traceback.format_exc())
                if retries > 0:
                    with self.mutex:
                        self.retries[uuid] += 1
                    # re-queue the task with a lower (i.e., higher-valued) priority
                    self.queue.put((priority+1, dumps((f, uuid, retries - 1, args, kwargs))))
                    self.queue.task_done()
                    return
                result = e
            with self.mutex:
                self.results[uuid] = dumps(result)
                self.retries[uuid] += 1
            self.queue.task_done()

        while self._tick():
            # spawn more threads to fill free slots
            log.debug("Running %d/%d threads" % (len(self.threads),self.MAX_WORKERS))
            if self.running and len(self.threads) < self.MAX_WORKERS:
                log.debug("Queue Length: %d" % self.queue.qsize())
                try:
                    priority, data = self.queue.get(True, 1.0/self.rate_limit)
                except Empty:
                    continue
                f, uuid, retries, args, kwargs = loads(data)
                log.debug(f)
                t = Thread(target=run_task, args=[priority, f, uuid, retries, args, kwargs])
                t.setDaemon(True)
                self.threads.append(t)
                t.start()
        log.debug("Exited loop.")
        for t in self.threads:
            t.join()


    def kill_all(self):
        """Very hacky way to kill threads by tossing an exception into their state"""
        for t in self.threads:
            ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(t.ident), ctypes.py_object(SystemExit))


    def stop(self):
        """Flush the job queue"""
        self.running = False
        self.queue = PriorityQueue()


    def start(self, daemonize=False):
        """Pool entry point"""

        self.results = {}
        self.retries = defaultdict(int)

        if daemonize:
            t = Thread(target = self._loop, args=[self])
            t.setDaemon(True)
            t.start()
            return
        else:
            self._loop()


default_pool = Pool()

class Deferred(object):
    """Allows lookup of task results and status"""
    def __init__(self, pool, uuid):
        self.uuid    = uuid
        self.pool    = pool
        self._result = None

    @property
    def result(self):
        if self._result is None:
            with self.pool.mutex:
                if self.uuid in self.pool.results.keys():
                   self._result = loads(self.pool.results[self.uuid])
        return self._result

    @property
    def retries(self):
        return self.pool.retries[self.uuid]


def task(func=None, pool=None, max_retries=0, priority=DEFAULT_PRIORITY):
    """Task decorator - setus up a .delay() attribute in the task function"""

    if func is None:
        return partial(task, pool=pool, max_retries=max_retries)

    if pool is None:
        pool = default_pool

    def delay(*args, **kwargs):
        uuid = str(uuid4()) # one for each task
        pool.queue.put((priority,dumps((func, uuid, max_retries, args, kwargs))))
        return Deferred(pool, uuid)
    func.delay = delay
    func.pool = pool
    return func


def go(*args, **kwargs):
    """Queue up a function, Go-style"""
    uuid = str(uuid4()) # one for each task
    default_pool.queue.put((DEFAULT_PRIORITY,dumps((args[0], uuid, 0, args[1:], kwargs))))
    return Deferred(default_pool, uuid)


class Channel:
    """A serializable shim that proxies to a Queue object"""
    def __init__(self, size):
        self.uuid = str(uuid4()) # one for each task
        channels[self.uuid] = Queue(size)

    def recv(self):
        return channels[self.uuid].get()

    def send(self, item):
        if self.uuid in closed:
            raise RuntimeError("Channel is closed.")
        channels[self.uuid].put(item)

    def close(self):
        closed[self.uuid] = True

    def __iter__(self):
        yield self.recv()
        while True:
            try:
                res = channels[self.uuid].get(True, 1.0/default_pool.rate_limit)
                yield res
            except Empty:
                # check channel again and end iteration if closed
                if channels[self.uuid].empty() and (self.uuid in closed):
                    return


def chan(size = 0):
    """Return a shim that acts like a Go channel"""
    return Channel(size)


def halt(signal, frame):
    default_pool.stop()
    default_pool.kill_all()
    sys.exit()


def start(daemonize = False):
    signal(SIGINT, halt)
    signal(SIGTERM, halt)
    default_pool.start(daemonize = daemonize)