(import
    [config             [*base-filenames* *bind-address* *store-path* *profiler* *update-socket* *indexer-count* *indexer-fanout* *indexer-control* *database-sink*]]
    [cProfile           [Profile]]
    [datetime           [datetime]]
    [dateutil.parser    [parse :as parse-date]]
    [hashlib            [sha1]]
    [json               [dumps]]
    [logging            [getLogger Formatter]]
    [models             [db add-wiki-link index-wiki-page init-db]]
    [multiprocessing    [Process cpu-count]]
    [os.path            [basename dirname]]
    [pstats             [Stats]]
    [pytz               [timezone]]
    [render             [render-page]]
    [store              [is-page? gen-pages get-page]]
    [time               [sleep time]]
    [transform          [apply-transforms extract-internal-links extract-plaintext]]
    [watchdog.observers [Observer]]
    [watchdog.events    [FileSystemEventHandler]]
    [zmq                [Context Poller *pub* *sub* *push* *pull* *sndhwm* *rcvhwm* *pollin* *subscribe*]])


(setv log (getLogger --name--))

(setv *utc* (timezone "UTC"))


(defn transform-tags [line]
    ; expand tags to be "tag:value", which enables us to search for tags using FTS
    (let [[tags (.split (.strip line) ",")]]
        (if (!= tags [""])
            (.join ", " (list (map (fn [tag] (+ "tag:" (.strip tag))) tags)))
            "")))


(defn hide-from-search? [headers]
    (reduce (fn [x y] (or x y))
        (map (fn [header]
                (if (and (in header headers)
                         (in (.lower (get headers header)) ["off" "no"]))
                    true
                    false))
            ["x-index" "index" "search"])
        false))


(defn utc-date [string fallback]
    (let [[date (try
                    (parse-date string)
                    (catch [e Exception]
                        fallback))]]
        (if (. date tzinfo)
            (.astimezone date *utc*)
            date)))


(defn gather-item-data [item]
    ; Takes a map with basic item info and builds all the required indexing data
    ;(.debug log (:path item))
    (let [[pagename     (:path item)]
          [mtime        (.fromtimestamp datetime (:mtime item))]
          [page         (get-page pagename)]
          [headers      (:headers page)]
          [doc          (apply-transforms (render-page page) pagename)]
          [plaintext    (extract-plaintext doc)]
          [links        (extract-internal-links doc)]]
        {"name"     pagename
         "body"     (if (hide-from-search? headers) "" plaintext)
         "hash"     (.hexdigest (sha1 (.encode plaintext "utf-8")))
         "title"    (.get headers "title" "Untitled")
         "tags"     (transform-tags (.get headers "tags" ""))
         ; this allows us to override the filesystem modification time through front matter
         "mtime"    (utc-date (.get headers "last-modified") mtime)
         ; if there isn't any front matter info, fall back to mtime
         "pubtime"  (utc-date (.get headers "date") mtime)
         "headers"  headers
         "links"    (list links)}))


(defn index-one [item &optional [sock None]]
    (let [[pagename (.get item "pagename")]
          [headers  (.get item "headers")]
          [links    (.get item "links")]]
        (if sock
            (.send-multipart sock
                [(str "indexing")
                 (dumps {"pagename" pagename
                         "title"    (.get headers "title" "Untitled")})]))

        (for [link links]
            (apply add-wiki-link []
                {"page" pagename
                 "link" link}))
        (apply index-wiki-page [] item)))


(defn filesystem-walker [path worker-count]
    ; walk the filesystem and perform full-text and front matter indexing
    (let [[ctx        (Context)]
          [sock       (.socket ctx *push*)]
          [cnt-sock   (.socket ctx *push*)]
          [item-count 0]]
        (.bind sock *indexer-fanout*)
        (.bind cnt-sock *indexer-count*)
        (.setsockopt sock *sndhwm* worker-count)
        (try
            (for [item (gen-pages path)]
                (.send-pyobj sock item)
                (setv item-count (inc item-count)))
            (catch [e Exception]
                (.error log (% "%s:%s handling %s" (, (type e) e item)))))
        ; let the database worker know how many items to expect
        (.send-pyobj cnt-sock item-count)
        (.debug log (% "exiting filesystem walker: %d items handled" item-count))))


(defn indexing-worker [worker-count]
    (let [[ctx      (Context)]
          [poller   (Poller)]
          [in-sock  (.socket ctx *pull*)]
          [out-sock (.socket ctx *push*)]
          [ctl-sock (.socket ctx *sub*)]
          [item     true]]
        (.connect in-sock *indexer-fanout*)
        (.connect out-sock *database-sink*)
        (.connect ctl-sock *indexer-control*)
        (.setsockopt-string ctl-sock *subscribe* "")
        (.setsockopt out-sock *sndhwm* worker-count)
        (.register poller in-sock *pollin*)
        (.register poller ctl-sock *pollin*)
        (.debug log "indexing worker")
        (while item
            (setv socks (dict (.poll poller)))
            (cond   [(= (.get socks ctl-sock) *pollin*)
                        (setv item (.recv-pyobj ctl-sock))]
                    [(= (.get socks in-sock) *pollin*)
                        (do
                            (setv item (.recv-pyobj in-sock))
                            (try
                                (.send-pyobj out-sock (gather-item-data item))
                                (catch [e Exception]
                                    ; keep database worker count in sync                                    
                                    (.send-pyobj out-sock nil)
                                    (.error log 
                                        (%  "%s:%s while handling %s" 
                                            (, (type e) e (try (:path item) (catch [e KeyError] nil))))))))]))
        (.debug log "exiting indexing worker")))


(defn database-worker [worker-count]
    (let [[ctx              (Context)]
          [in-sock          (.socket ctx *pull*)]
          [cnt-sock         (.socket ctx *pull*)]
          [ctl-sock         (.socket ctx *pub*)]
          [item-limit       -1]
          [item-count       0]
          [item             nil]]
        (.bind ctl-sock *indexer-control*)
        (.bind in-sock *database-sink*)
        (.connect cnt-sock *indexer-count*)
        (.setsockopt in-sock *rcvhwm* worker-count)
        (.debug log "database worker")
        (setv item-limit (.recv-pyobj cnt-sock))
        (.info log (% "waiting for %d items" item-limit))
        (try
            (while (!= item-count item-limit)
                (if (= 0 (% item-count 100))
                    (.debug log (% "indexed %d of %d" (, item-count item-limit))))
                (setv item (.recv-pyobj in-sock))
                (if item
                    (index-one item))
                (setv item-count (inc item-count)))
            (catch [e Exception]
                (.error log (% "%s:%s while inserting" (, (type e) e)))))
        (.send-pyobj ctl-sock nil)
        (.info log (% "exiting database worker: %d items" item-count))))


(defclass IndexingHandler [FileSystemEventHandler]
    ; handle file notifications
    [[--init--
        (fn [self]
            (let [[ctx (Context)]
                  [(. self sock) (.socket ctx *pub*)]]
                (.bind (. self sock) *update-socket*)))]

     [on-any-event ; TODO: handle deletions and moves separately
        (fn [self event]
            (let [[filename (basename (. event src-path))]
                  [path     (dirname  (. event src-path))]]
                (if (in filename *base-filenames*)
                    (index-one
                        {:path (slice path (+ 1 (len *store-path*)))
                         :mtime (time)}
                        (. self sock)))))]])


(defn observer [path]
    ; file change observer setup
    (let [[observer (Observer)]
          [handler  (IndexingHandler)]]
        (.debug log (% "Preparing to watch %s" path))
        (apply .schedule [observer handler path] {"recursive" true})
        (.start observer)
        (try
            (while true
                (sleep 1))
            (catch [e KeyboardInterrupt]
                (.stop observer)))
        (.join observer)))


(defn perform-indexing [path count]
    (let [[procs [(apply Process [] {"target" database-worker "args" (, count)})]]]
        (for [i (range count)]
            (.append procs (apply Process [] {"target" indexing-worker "args" (, count)})))
        (.append procs (apply Process [] {"target" filesystem-walker "args" (, path count)}))
        (for [p procs]
            (.start p))
        (for [p procs]
            (.join p))))


(defmain [&rest args]
    (let [[p (Profile)]]
        (if *profiler*
            (.enable p))
        (init-db)
        ; close database connection to remove contention
        (.close db)
        (setv start-time (time))
        (perform-indexing *store-path* (int (cpu-count)))
        (.info log "Indexing done in %fs" (- (time) start-time))
        (if *profiler*
            (do
                (.disable p)
                (.info log "dumping stats")
                (.dump_stats (Stats p) "indexer.pstats")))
    (if (in "watch" args)
        (do
            (.info log "Starting watcher...")
            (observer *store-path*)))))


