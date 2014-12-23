(import 
    [config             [*base-filenames* *store-path*]]
    [cProfile           [Profile]]
    [datetime           [datetime]]
    [hashlib            [sha1]]
    [logging            [getLogger Formatter]]
    [models             [add-wiki-link add-wiki-page index-wiki-page init-db]]
    [os.path            [basename dirname]]
    [pstats             [Stats]]
    [render             [render-page]]
    [store              [is-page? gen-pages get-page]]
    [time               [sleep time]]
    [transform          [apply-transforms extract-internal-links extract-plaintext]]
    [watchdog.observers [Observer]]
    [watchdog.events    [FileSystemEventHandler]])


(setv log (getLogger))

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


(defn index-one [item]
    ; update a single page
    (.info log (% "Indexing %s" (:path item)))
    (let [[pagename   (:path item)]
          [mtime      (:mtime item)]
          [page       (get-page pagename)]
          [headers    (:headers page)]
          [doc        (apply-transforms (render-page page) pagename)]
          [plaintext  (extract-plaintext doc)]
          [links      (extract-internal-links doc)]]
        (for [link links]
            (apply add-wiki-link []
                {"page" pagename 
                 "link" link}))
        (apply index-wiki-page []
            {"name"  pagename
             "body"  (if (hide-from-search? headers) "" plaintext)
             "hash"  (.hexdigest (sha1 (.encode plaintext "utf-8")))
             "title" (.get headers "title" "Untitled")
             "tags"  (transform-tags (.get headers "tags" ""))
             "mtime" (.fromtimestamp datetime mtime)})))


(defn index-pass [path perform-indexing]
    ; walk the filesystem
    (for [item (gen-pages path)]
        (if perform-indexing
            (try
                (index-one item)
                (catch [e Exception]
                    (.error log (% "Error %s handling %s" (, e item)))))
            (apply add-wiki-page []
                {"name"  (:path item)
                 "mtime" (:mtime item)}))))


(defclass IndexingHandler [FileSystemEventHandler]
    ; handle file notifications
    [[on-any-event ; TODO: handle deletions and moves separately
        (fn [self event]
            (let [[filename (basename (. event src-path))]
                  [path     (dirname  (. event src-path))]]
                (if (in filename *base-filenames*)
                    (index-one
                        {:path (slice path (+ 1 (len *store-path*)))
                         :mtime (time)}))))]])


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
        (init-db)
        (index-pass *store-path* false)
        (.info log "First pass done.")
        (.enable p)
        (index-pass *store-path* true)
        (.disable p)
        (.info log "Second pass done.")
        (.dump_stats (Stats p) "out.pstats"))
    (if (in "watch" args)
        (do
            (.info log "Starting watcher...")
            (observer *store-path*))))


