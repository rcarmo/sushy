(import 
    [bottle    [abort get :as handle-get request redirect response static-file view :as render-view]]
    [config    [*debug-mode* *home-page* *page-media-base* *page-route-base* *site-description* *site-name* *static-path* *store-path*]]
    [feeds     [render-feed render-sitemap render-robots]]
    [logging   [getLogger]]
    [models    [search get-links]]
    [os        [environ]]
    [render    [render-page]]
    [store     [get-page]]
    [transform [apply-transforms inner-html]]
    [utils     [ttl-cache]])


(setv log (getLogger))


(defn base-url []
    (slice (. request url) 0 (- (len (. request path)))))


; TODO: etags and HTTP header handling for caching

(with-decorator 
    (handle-get "/")
    (handle-get *page-route-base*)
    (defn home-page []
        (redirect *home-page*)))


; environment dump
(with-decorator
    (handle-get "/env")
    (render-view "debug")
    (defn debug-dump []
        (if *debug-mode*
            {"headers" {"title" "Environment dump"}
             "environ"  (dict environ)}
            (abort (int 404) "Page Not Found"))))


; RSS feed
(with-decorator
    (ttl-cache 300)
    (handle-get "/rss")
    (defn serve-feed []
        (try
            (let [[buffer (render-feed (base-url))]]
                (setv (. response content-type) "application/rss+xml")
                buffer)
            (catch [e Exception]
                (.error log (% "%s:%s serving feed" (, (type e) e)))  
                (abort (int 503) "Error generating feed.")))))


; Sitemap
(with-decorator
    (ttl-cache 3600)
    (handle-get "/sitemap.xml")
    (defn serve-sitemap []
        (try
            (let [[buffer (render-sitemap (base-url))]]
                (setv (. response content-type) "text/xml")
                buffer)
            (catch [e Exception]
                (.error log (% "%s:%s serving sitemap" (, (type e) e)))  
                (abort (int 503) "Error generating sitemap.")))))


; robots.txt
(with-decorator
    (ttl-cache 3600)
    (handle-get "/robots.txt")
    (defn serve-robots []
        (try
            (let [[buffer (render-robots (base-url))]]
                (setv (. response content-type) "text/plain")
                buffer)
            (catch [e Exception]
                (.error log (% "%s:%s serving robots.txt" (, (type e) e)))  
                (abort (int 503) "Error generating robots.txt.")))))


; OpenSearch metadata
(with-decorator
    (ttl-cache 3600)
    (handle-get "/opensearch.xml")
    (render-view "opensearch")
    (defn handle-opensearch []
        (setv (. response content-type) "text/xml")
        {"base_url"         (base-url)
         "site_description" *site-description*
         "site_name"        *site-name*})

         
; search
(with-decorator
    (handle-get "/search")
    (render-view "search")
    (defn handle-search []
        (if (in "q" (.keys (. request query)))
            {"results" (search (. request query q))
             "query"   (. request query q)
             "headers" {}}
            {"headers" {}})))

            
; static files
(with-decorator 
    (handle-get "/static/<filename:path>")
    (defn static-files [filename]
        (apply static-file [filename] {"root" *static-path*})))

        
; page media
(with-decorator 
    (handle-get (+ *page-media-base* "/<filename:path>"))
    (defn page-media [filename]
        (apply static-file [filename] {"root" *store-path*})))


; page content
(with-decorator 
    (handle-get (+ *page-route-base* "/<pagename:path>"))
    (render-view "wiki")
    (defn wiki-page [pagename] 
        ; TODO: fuzzy URL matching, error handling
        (let [[page (get-page pagename)]]
            {"headers"   (:headers page)
             "pagename"  pagename
             "base_url"  *page-route-base*
             "site_name" *site-name*
             "seealso"   (list (get-links pagename))
             "body"      (inner-html (apply-transforms (render-page page) pagename))})))
