(import 
    [bottle    [abort get :as handle-get request redirect response static-file view :as render-view]]
    [config    [*debug-mode* *exclude-from-feeds* *feed-css* *feed-ttl* *home-page* *page-media-base* *page-route-base* *rss-date-format* *site-copyright* *site-description* *site-name* *static-path* *store-path*]]
    [datetime  [datetime]]
    [feeds     [render-feed-items]]
    [logging   [getLogger]]
    [models    [search get-links get-all]]
    [os        [environ]]
    [pytz      [*utc*]]
    [render    [render-page]]
    [store     [get-page]]
    [transform [apply-transforms inner-html]]
    [utils     [ttl-cache report-processing-time]])


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
    (handle-get "/rss")
    (report-processing-time)
    (ttl-cache 300)
    (render-view "rss")
    (defn serve-feed []
        (setv (. response content-type) "application/rss+xml")
        {"pubdate"          (.strftime (.localize *utc* (.now datetime)) *rss-date-format*)
         "items"            (render-feed-items)
         "feed_ttl"         *feed-ttl*
         "site_name"        *site-name*
         "site_description" *site-description*
         "site_copyright"   *site-copyright*
         "page_route_base"  *page-route-base*
         "base_url"         (base-url)}))


; Sitemap
(with-decorator
    (handle-get "/sitemap.xml")
    (report-processing-time)
    (ttl-cache 3600)
    (render-view "sitemap")
    (defn serve-sitemap []
        (setv (. response content-type) "text/xml")
        {"items"            (get-all)
         "page_route_base"  *page-route-base*
         "base_url"         (base-url)}))


; robots.txt
(with-decorator
    (handle-get "/robots.txt")
    (report-processing-time)
    (ttl-cache 3600)
    (render-view "robots")
    (defn serve-robots []
        (setv (. response content-type) "text/plain")
        {"base_url"         (base-url)
         "page_route_base"  *page-route-base*}))


; OpenSearch metadata
(with-decorator
    (handle-get "/opensearch.xml")
    (report-processing-time)
    (ttl-cache 3600)
    (render-view "opensearch")
    (defn handle-opensearch []
        (setv (. response content-type) "text/xml")
        {"base_url"         (base-url)
         "site_description" *site-description*
         "site_name"        *site-name*}))

         
; search
(with-decorator
    (handle-get "/search")
    (report-processing-time)
    (ttl-cache 30 "q")
    (render-view "search")
    (defn handle-search []
        (if (in "q" (.keys (. request query)))
            {"results"          (search (. request query q))
             "query"            (. request query q)
             "headers"          {}
             "site_description" *site-description*
             "site_name"        *site-name*}
            {"headers"          {}
             "site_description" *site-description*
             "site_name"        *site-name*})))

            
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
    (report-processing-time)
    (ttl-cache 30)
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
