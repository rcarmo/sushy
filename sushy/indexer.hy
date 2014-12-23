(import 
    [config             [*base-filenames* *store-path*]]
    [datetime           [datetime]]
    [hashlib            [sha1]]
    [logging            [getLogger Formatter]]
    [models             [add-wiki-link add-wiki-page init-db]]
    [os.path            [basename dirname]]
    [render             [render-page]]
    [store              [is-page? gen-pages get-page]]
    [scheduler          [go chan start stop *max-workers*]]
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
        (apply add-wiki-page []
            {"name"  pagename
             "body"  plaintext
             "hash"  (.hexdigest (sha1 (.encode plaintext "utf-8")))
             "title" (.get headers "title" "Untitled")
             "tags"  (transform-tags (.get headers "tags" ""))
             "mtime" (.fromtimestamp datetime mtime)})))


(defn walk-filesystem-task [page-channel path]
    ; worker task for walking the filesystem
    (for [item (gen-pages path)]
        (.send page-channel item))
    (.info log "Indexing done.")
    (.close page-channel))


(defn index-task [page-channel]
    ; worker task for indexing single items
    (for [item page-channel]
        (try
            (index-one item)
            (catch [e Exception]
                (.error log (% "Error %s handling %s" (, e item)))))))


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
    (init-db)
    (let [[page-channel (chan *max-workers*)]]
        (go walk-filesystem-task page-channel *store-path*)
        (for [i (range *max-workers*)]
            (go index-task page-channel))
        (start))
    (.info log "Starting watcher...")
    (if (in "watch" args)
        (observer *store-path*)))

