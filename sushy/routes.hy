(import 
    [bottle    [abort get :as handle-get request redirect static-file view :as render-view]]
    [config    [*debug-mode* *home-page* *page-media-base* *page-route-base* *static-path* *store-path*]]
    [logging   [getLogger]]
    [models    [search]]
    [os        [environ]]
    [render    [render-page]]
    [store     [get-page]]
    [transform [apply-transforms inner-html]])


(setv log (getLogger))


; TODO: etags and HTTP header handling for caching

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
            ; TODO: proper reporting of search result length, move messages to template
            {"results" (search (. request query q))
             "headers" {"title" (% "Search Results for '%s'" (. request query q))}}
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
             "body"    (inner-html (apply-transforms (render-page page) pagename))})))
