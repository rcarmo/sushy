(import 
    [logging   [getLogger]]
    [bottle    [get :as handle-get request redirect view :as render-view static-file]]
    [config    [*home-page* *page-route-base* *static-path*]]
    [store     [get-page]]
    [render    [render-page]]
    [transform [apply-transforms]])


(setv log (getLogger))

(with-decorator 
    (handle-get "/")
    (fn []
        (redirect *home-page*)))

(with-decorator 
    (handle-get "/static/<filename:path>")
    (fn [filename]
        (apply static-file [filename] {"root" *static-path*})))

; TODO: page media handling        

(with-decorator 
    (handle-get (+ *page-route-base* "/<pagename:path>"))
    (render-view "wiki")
    (fn [pagename] 
        ; TODO: fuzzy URL matching, error handling
        (let [[page (get-page pagename)]]
            {"headers" (:headers page)
             "body"    (-> page 
                           (render-page)
                           (apply-transforms page))})))
