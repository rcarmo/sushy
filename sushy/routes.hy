(import
    [binascii    [b2a-base64]]
    [bottle      [abort get :as handle-get request redirect response static-file view :as render-view template]]
    [config      [*debug-mode* *exclude-from-feeds* *feed-css* *feed-ttl* *home-page* *page-media-base* *page-route-base* *rss-date-format* *site-copyright* *site-description* *site-name* *static-path* *store-path*]]
    [datetime    [datetime]]
    [dateutil.relativedelta  [relativedelta]]
    [email.utils [parsedate]]
    [feeds       [render-feed-items]]
    [hashlib     [sha1]]
    [logging     [getLogger]]
    [models      [search get-links get-all get-metadata get-latest]]
    [os          [environ]]
    [pytz        [*utc*]]
    [render      [render-page]]
    [store       [get-page]]
    [time        [mktime]]
    [transform   [apply-transforms inner-html]]
    [utils       [*gmt-format* lru-cache ttl-cache report-processing-time]])


(setv log (getLogger))


(defn base-url []
    (slice (. request url) 0 (- (len (. request path)))))


; compute a sha1 hash for the HTML layout, so that etag generation is related to HTTP payload
(def *layout-hash* (.hexdigest (sha1 (template "layout" {"base" "" "headers" {"title" ""} "site_name" "" "site_description" ""}))))


; a little etag helper
(defn compute-etag [&rest args]
    (let [[hash (sha1)]]
        (for [a args]
            (.update hash a))
        (.format "W/\"{}\"" (.strip (b2a-base64 (.digest hash))))))


; grab page metadata or generate a minimal shim based on the last update
(with-decorator
    (ttl-cache 30)
    (defn wrap-metadata [pagename]
        (if pagename
            (get-metadata pagename)
            (try
                (next (get-latest 1))
                (catch [e Exception]
                    {"hash"  ""
                     "mtime" (.now datetime)})))))

 
; HTTP enrichment decorator - note that bottle automatically maps HEAD to GET, so no special handling is required for that.
(defn http-caching [page-key content-type seconds]
    (defn inner [func]
        (defn wrap-fn [&rest args &kwargs kwargs]
            (let [[pagename    (if page-key (get kwargs page-key) nil)]
                  [etag-seed   (if page-key *layout-hash* (. request url))] 
                  [metadata    (wrap-metadata pagename)]
                  [req-headers (. request headers)]]
                (if metadata
                    (let [[pragma (if seconds "public" "no-cache, must-revalidate")]
                          [etag   (compute-etag etag-seed content-type (get metadata "hash"))]]
                        (if (and (in "If-None-Match" req-headers)
                                 (= etag (get req-headers "If-None-Match")))
                            (abort (int 304) "Not modified"))
                        (if (and (in "If-Modified-Since" req-headers)
                                 (<= (get metadata "mtime")
                                     (.fromtimestamp datetime (mktime (parsedate (get req-headers "If-Modified-Since"))))))
                            (abort (int 304) "Not modified"))
                        (.set-header response (str "ETag") etag)
                        (.set-header response (str "Last-Modified") (.strftime (get metadata "mtime") *gmt-format*))
                        (.set-header response (str "Expires") (.strftime (+ (.now datetime) (apply relativedelta [] {"seconds" seconds})) *gmt-format*))
                        (.set-header response (str "Cache-Control") (.format "{}, max-age={}" pragma seconds))
                        (.set-header response (str "Pragma") pragma))))
                (.set-header response (str "Content-Type") content-type)
            (apply func args kwargs))
        wrap-fn)
    inner)


(with-decorator 
    (handle-get "/")
    (handle-get *page-route-base*)
    (defn home-page []
        (redirect *home-page*)))


; environment dump
(with-decorator
    (handle-get "/env")
    (report-processing-time)
    (http-caching nil "text/html" 0)
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
    (http-caching nil "application/rss+xml" *feed-ttl*)
    (ttl-cache (/ *feed-ttl* 4))
    (render-view "rss")
    (defn serve-feed []
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
    (http-caching nil "text/xml" *feed-ttl*)
    (ttl-cache (/ *feed-ttl* 4))
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
    (http-caching nil "text/plain" 3600)
    (ttl-cache 3600)
    (render-view "robots")
    (defn serve-robots []
        {"base_url"         (base-url)
         "page_route_base"  *page-route-base*}))


; OpenSearch metadata
(with-decorator
    (handle-get "/opensearch.xml")
    (report-processing-time)
    (http-caching nil "text/xml" 3600)
    (ttl-cache 3600)
    (render-view "opensearch")
    (defn handle-opensearch []
        {"base_url"         (base-url)
         "site_description" *site-description*
         "site_name"        *site-name*}))

         
; search
(with-decorator
    (handle-get "/search")
    (report-processing-time)
    (http-caching nil "text/html" 30)
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
    (http-caching "pagename" "text/html" 3600)
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
