(import 
    [config             [*base-filenames* *store-path*]]
    [datetime           [datetime]]
    [hashlib            [sha1]]
    [logging            [getLogger]]
    [models             [add-wiki-link add-wiki-page init-db]]
    [os.path            [basename dirname]]
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


(defn update-one [pagename mtime]
    ; update a single page - TODO: intra-wiki links for SeeAlso
    (.debug log (% "Updating %s" pagename))
    (let [[page       (get-page pagename)]
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


(defn build-index []
    ; index all pages
    (for [item (gen-pages *store-path*)]
        (update-one (:path item) (:mtime item))))


(defclass IndexingHandler [FileSystemEventHandler]
    ; handle file notifications
    [[on-any-event ; TODO: handle deletions and moves separately
        (fn [self event]
            (let [[filename (basename (. event src-path))]
                  [path     (dirname  (. event src-path))]]
                (if (in filename *base-filenames*)
                    (update-one (slice path (+ 1 (len *store-path*))) 
                        (time)))))]])


(defmain [&rest args]
    (init-db)
    (build-index)
    (if (in "watch" args)
        (let [[observer (Observer)]
              [handler  (IndexingHandler)]]
            (.debug log (% "Preparing to watch %s" *store-path*))
            (apply .schedule [observer handler *store-path*] {"recursive" true})
            (.start observer)
            (try
                (while true
                    (sleep 1))
                (catch [e KeyboardInterrupt]
                    (.stop observer)))
            (.join observer))))
