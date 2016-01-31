(import
    [bottle      [abort get :as handle-get request redirect response static-file view :as render-view]]
    [config      [*debug-mode* *exclude-from-feeds* *feed-css* *feed-ttl* *home-page* *layout-hash* *page-media-base* *page-route-base* *placeholder-image* *rss-date-format* *site-copyright* *site-description* *site-name* *static-path* *store-path* *thumb-media-base* *thumbnail-sizes*]]
    [datetime    [datetime]]
    [dateutil.relativedelta  [relativedelta]]
    [email.utils [parsedate]]
    [feeds       [render-feed-items]]
    [logging     [getLogger]]
    [models      [search get-links get-all get-closest-matches get-metadata get-latest]]
    [os          [environ]]
    [os.path     [join split]]
    [pytz        [*utc*]]
    [render      [render-page]]
    [store       [asset-exists? asset-path get-page]]
    [time        [mktime]]
    [transform   [apply-transforms inner-html]]
    [utils       [*gmt-format* base-url compact-hash compute-hmac get-thumbnail lru-cache ttl-cache report-processing-time trace-flow]])


(setv log (getLogger))


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
            (.set-header response (str "Content-Type") content-type)
            (if *debug-mode*
                (apply func args kwargs)
                (let [[pagename    (if page-key (get kwargs page-key) nil)]
                      [etag-seed   (if page-key *layout-hash* (. request url))] 
                      [metadata    (wrap-metadata pagename)]
                      [req-headers (. request headers)]]
                    (if metadata
                        (let [[pragma (if seconds "public" "no-cache, must-revalidate")]
                              [etag   (.format "W/\"{}\"" (compact-hash etag-seed content-type (get metadata "hash")))]]
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
                            (.set-header response (str "Pragma") pragma)))))
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
            {"base_url"         (base-url)
             "environ"          (dict environ)
             "headers"          {"title" "Environment dump"}
             "page_route_base"  *page-route-base*
             "site_description" *site-description*
             "site_name"        *site-name*}
            (abort (int 404) "Page Not Found"))))


; RSS feed
(with-decorator
    (handle-get "/rss")
    (report-processing-time)
    (http-caching nil "application/rss+xml" *feed-ttl*)
    (ttl-cache (/ *feed-ttl* 4))
    (render-view "rss")
    (defn serve-feed []
        {"base_url"         (base-url)
         "feed_ttl"         *feed-ttl*
         "items"            (render-feed-items)
         "page_route_base"  *page-route-base*
         "pubdate"          (.strftime (.localize *utc* (.now datetime)) *rss-date-format*)
         "site_copyright"   *site-copyright*
         "site_description" *site-description*
         "site_name"        *site-name*}))


; Sitemap
(with-decorator
    (handle-get "/sitemap.xml")
    (report-processing-time)
    (http-caching nil "text/xml" *feed-ttl*)
    (ttl-cache (/ *feed-ttl* 4))
    (render-view "sitemap")
    (defn serve-sitemap []
        (setv (. response content-type) "text/xml")
        {"base_url"         (base-url)
         "items"            (get-all)
         "page_route_base"  *page-route-base*}))


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
            {"base_url"         (base-url)
             "headers"          {}
             "page_route_base"  *page-route-base*
             "query"            (. request query q)
             "results"          (search (. request query q))
             "site_description" *site-description*
             "site_name"        *site-name*}
            {"base_url"         (base-url)
             "headers"          {}
             "page_route_base"  *page-route-base*
             "site_description" *site-description*
             "site_name"        *site-name*})))

            
; static files
(with-decorator 
    (handle-get "/static/<filename:path>")
    (defn static-files [filename]
        (apply static-file [filename] {"root" *static-path*})))

        
; page media
(with-decorator 
    (handle-get (+ *page-media-base* "/<hash>/<filename:path>"))
    (defn page-media [hash filename]
        (if (= hash (compute-hmac *layout-hash* *page-media-base* (+ "/" filename)))
            (apply static-file [filename] {"root" *store-path*})
            (redirect *placeholder-image*))))


; blog index
(with-decorator
    (handle-get *page-route-base*)
    (report-processing-time)
    (http-caching "route-base" "text/html" 3600)
    (ttl-cache 60)
    (render-view "blog")
    (defn blog-homepage []
        (try
            (let [[latest   (apply get-latest [] {"regexp" "^blog"})]
                  [pagename (get (.next latest) "name")]
                  [page     (get-page pagename)]]
                {"base_url"         (base-url)
                 "body"             (inner-html (apply-transforms (render-page page) pagename))            
                 "headers"          (:headers page)
                 "pagename"         pagename
                 "page_route_base"  *page-route-base*                 
                 "site_description" *site-description*
                 "site_name"        *site-name*})
            (except [e Exception]
                (abort (int 500) (+ "Internal Server Error" (str e))))))) 


; page content
(with-decorator 
    (handle-get (+ *page-route-base* "/<pagename:path>"))
    (report-processing-time)
    (http-caching "pagename" "text/html" 3600)
    (ttl-cache 30)
    (render-view "wiki")
    (defn wiki-page [pagename] 
        (try
            (let [[page (get-page pagename)]]
                {"base_url"         (base-url)
                 "body"             (inner-html (apply-transforms (render-page page) pagename))            
                 "headers"          (:headers page)
                 "pagename"         pagename
                 "page_route_base"  *page-route-base*                 
                 "seealso"          (list (get-links pagename))
                 "site_description" *site-description*
                 "site_name"        *site-name*})
            (except [e IOError]
                (try
                    (let [[matches (get-closest-matches pagename)]]
                        (for [match matches]
                            (if (!= (get match "name") pagename)
                                (redirect (+ *page-route-base* "/" (get match "name")))))
                        (abort (int 404) "Could not find alternate page"))
                    (except [e StopIteration]
                        (abort (int 404) "Page not found")))))))


; thumbnails
(with-decorator
    (handle-get (+ *thumb-media-base* "/<hash>/<x:int>,<y:int>/<filename:path>"))
    (report-processing-time)
    (http-caching nil "image/jpeg" 3600)
    (defn thumbnail-image [hash x y filename]
        (let [[size (, (long x) (long y))]
              [hmac (compute-hmac *layout-hash* *thumb-media-base* (+ (% "/%d,%d" (, x y)) "/" filename))]]
            (.debug log (, size hmac hash filename))
            (if (or (not (in size *thumbnail-sizes*))
                    (!= hash hmac))
                (abort (int 403) "Invalid Image Request")
                (let [[(, pagename asset) (split filename)]]
                    (if (asset-exists? pagename asset)
                        (let [[buffer (get-thumbnail x y (asset-path pagename asset))]
                              [length (len buffer)]]
                            (if length
                                (do
                                    (.set-header response (str "Content-Length") length)
                                    buffer)
                                (redirect "/static/img/placeholder.png")))
                        (redirect "/static/img/placeholder.png")))))))
