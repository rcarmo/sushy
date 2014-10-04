(import 
    [logging   [getLogger]]
    [bottle    [get :as handle-get request redirect view :as render-view static-file]]
    [config    [*home-page* *page-route-base* *page-media-base* *static-path* *store-path*]]
    [store     [get-page]]
    [render    [render-page]]
    [transform [apply-transforms]])


(setv log (getLogger))

(with-decorator 
    (handle-get "/")
    (handle-get *page-route-base*)
    (fn []
        (redirect *home-page*)))


; static files
(with-decorator 
    (handle-get "/static/<filename:path>")
    (fn [filename]
        (apply static-file [filename] {"root" *static-path*})))


; page media
(with-decorator 
    (handle-get (+ *page-media-base* "/<filename:path>"))
    (fn [filename]
        (apply static-file [filename] {"root" *store-path*})))


; page content
(with-decorator 
    (handle-get (+ *page-route-base* "/<pagename:path>"))
    (render-view "wiki")
    (fn [pagename] 
        ; TODO: fuzzy URL matching, error handling
        (let [[page (get-page pagename)]]
            {"headers" (:headers page)
             "body"    (apply-transforms (render-page page) pagename)})))
