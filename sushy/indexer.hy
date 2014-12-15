(import 
    [datetime  [datetime]]
    [config    [*store-path*]]
    [logging   [getLogger]]
    [hashlib   [sha1]]
    [models    [create-db add-entry]]
    [store     [get-page gen-pages]]
    [render    [render-page]]
    [transform [extract-plaintext]])


(setv log (getLogger))

(create-db)

(defn transform-tags [line]
    ; expand tags to be "tag:value", which enables us to search for tags using FTS
    (let [[tags (.split (.strip line) ",")]]
        (if (!= tags [""])
            (.join ", " (list (map (fn [tag] (+ "tag:" (.strip tag))) tags)))
            "")))


(defn build-index []
    (for [item (gen-pages *store-path*)]
        (let [[id       (:path item)]
              [page     (get-page id)]
              [headers  (:headers page)]
              [body     (extract-plaintext (render-page page) id)]]
            (apply add-entry []
                {"id"    id
                 "body"  body
                 "hash"  (.hexdigest (sha1 body))
                 "title" (.get headers "title" "Untitled")
                 "tags"  (transform-tags (.get headers "tags" ""))
                 "mtime" (.fromtimestamp datetime (:mtime item))}))))


(defmain [&rest args]
    (build-index))
