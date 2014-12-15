(import 
    [os [environ]]
    [logging   [getLogger]]
    [bottle    [get :as handle-get request redirect view :as render-view static-file abort]]
    [config    [*home-page* *page-route-base* *page-media-base* *static-path* *store-path* *debug-mode*]]
    [store     [get-page]]
    [models    [search]]
    [render    [render-page]]
    [transform [apply-transforms]])


(setv log (getLogger))

(with-decorator 
    (handle-get "/")
    (handle-get *page-route-base*)
    (fn []
        (redirect *home-page*)))

; environment dump
(with-decorator
    (handle-get "/env")
    (render-view "debug")
    (fn []
        (if *debug-mode*
            {"headers" {"title" "Environment dump"}
             "environ"  environ}
            (abort 404 "Page Not Found"))))

; search
(with-decorator
    (handle-get "/search")
    (render-view "search")
    (fn []
        (if (in "q" (.keys (. request query)))
            {"results" (list (search (. request query q)))
             "headers" {"title" "Search Results"}}
            {"results" nil "headers" "No Results"})))
            
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
