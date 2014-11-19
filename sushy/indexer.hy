(import 
    [datetime  [datetime]]
    [config    [*store-path*]]
    [models    [create-db add-entry]]
    [store     [get-page gen-pages]]
    [render    [render-page]]
    [transform [extract-plaintext]])


(setv log (getLogger))

(create-db)

(defn build-index []
    (for [item gen-pages]
        (let [[id       (:path item)]
              [page     (get-page id)]
              [headers  (:headers page)]
              [body     (extract-plaintext (render-page page id))]]
            (apply add-entry []
                {"id"    id
                 "body"  body
                 "title" (.get headers "title" "Untitled")
                 "tags"  (.get headers "tags" "")
                 "mtime" (.fromtimestamp datetime (:mtime item))}))))
