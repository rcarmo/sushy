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


(defn update-one [item]
    ; update a single page
    (.info log (% "Updating %s" item))
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


(defn build-index [page-channel path]
    ; index all pages
    (for [item (gen-pages path)]
        (.send page-channel item))
    (.info log "Done.")
    (.close page-channel))


(defn index-task [page-channel]
    (for [item page-channel]
        (try
            (update-one item)
            (catch [e Exception]
                (.error log (% "Error %s handling %s" (, e item)))))))


(defclass IndexingHandler [FileSystemEventHandler]
    ; handle file notifications
    [[on-any-event ; TODO: handle deletions and moves separately
        (fn [self event]
            (let [[filename (basename (. event src-path))]
                  [path     (dirname  (. event src-path))]]
                (if (in filename *base-filenames*)
                    (update-one
                        {:path (slice path (+ 1 (len *store-path*)))
                         :mtime (time)}))))]])


(defn observer [path]
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
        (go build-index page-channel *store-path*)
        (for [i (range *max-workers*)]
            (go index-task page-channel))
        (start))
    (.info log "Starting watcher...")
    (if (in "watch" args)
        (observer *store-path*)))

