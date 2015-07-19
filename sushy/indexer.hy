(import
    [config             [*base-filenames* *bind-address* *store-path* *profiler* *update-socket* *indexer-count* *indexer-fanout* *indexer-control* *database-sink*]]
    [cProfile           [Profile]]
    [datetime           [datetime]]
    [hashlib            [sha1]]
    [json               [dumps]]
    [logging            [getLogger Formatter]]
    [models             [db add-wiki-link index-wiki-page init-db]]
    [os.path            [basename dirname]]
    [pstats             [Stats]]
    [render             [render-page]]
    [store              [is-page? gen-pages get-page]]
    [time               [sleep time]]
    [transform          [apply-transforms extract-internal-links extract-plaintext]]
    [utils              [utc-date]]
    [watchdog.observers [Observer]]
    [watchdog.events    [FileSystemEventHandler]]
    [zmq                [Context Poller *pub* *sub* *push* *pull* *sndhwm* *rcvhwm* *pollin* *subscribe*]])


(setv log (getLogger --name--))

(def *logging-modulo* 10)

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
            (.send-pyobj sock
                [(str "indexing")
                 (dumps {"pagename" pagename
                         "title"    (.get headers "title" "Untitled")})]))

        (for [link links]
            (apply add-wiki-link []
                {"page" pagename
                 "link" link}))
        (apply index-wiki-page [] item)))


(defn filesystem-walk [path]
    ; walk the filesystem and perform full-text and front matter indexing
    (let [[item-count 0]]
        (try
            (for [item (gen-pages path)]
                (if (= 0 (% item-count *logging-modulo*))
                    (.debug log (% "indexing %d" item-count)))
                (index-one (gather-item-data item))
                (setv item-count (inc item-count)))
            (catch [e Exception]
                (.error log (% "%s:%s handling %s" (, (type e) e item)))))
        (.debug log (% "exiting filesystem walker: %d items handled" item-count))))


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


(defmain [&rest args]
    (let [[p (Profile)]]
        (if *profiler*
            (.enable p))
        (init-db)
        ; close database connection to remove contention
        (.close db)
        (setv start-time (time))
        (filesystem-walk *store-path*)
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
