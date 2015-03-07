Title: Multiprocessing and 0MQ
Date: 2015-03-07 23:30:00
From: Rui Carmo

After a few months dithering about with other things, I finally put in the time to rebuild the indexer using `multiprocessing` (with `pyzmq` for IPC), cutting down the time for content indexing to nearly half on a dual-core machine (and to nearly a third on a quad-core machine).

FTS indexing still takes a fair amount of time, but it can't be sped up any further (since it's done inside SQLite). The big improvement is that all the markup processing and link gathering is done in parallel and ahead of database operations, saving a considerable amount of time for large (7000+ pages) sites.

I expect this will also be helpful when running under `PyPy`, since the JIT will have some nice, tight code loops to tackle.

Now I can get back to the HTTP handling and templating stuff.