(import
    aliasing    [get-best-match]
    bottle      [abort get :as handle-get hook http-date parse-date request redirect response static-file view :as render-view]
    config      [*asset-hash* *banned-agents-page* *debug-mode* *exclude-from-feeds* *feed-css* *feed-ttl* *instrumentation-key* *page-media-base* *page-route-base* *placeholder-image* *site-copyright* *site-description* *site-name* *static-path* *links-page* *stats-address* *stats-port* *store-path* *scaled-media-base* *thumbnail-sizes* *timezone* *root-junk* *redirect-page*]
    datetime    [datetime]
    dateutil.relativedelta  [relativedelta]
    feeds       [render-feed-items]
    json        [dumps]
    logging     [getLogger]
    models      [search get-links get-all get-page-metadata get-latest get-last-update-time get-table-stats]
    os          [environ]
    os.path     [join split]
    pytz        [*utc*]
    render      [render-page]
    store       [asset-exists? asset-path get-page]
    socket      [socket *af-inet* *sock-dgram*]
    time        [gmtime time]
    transform   [apply-transforms inner-html get-link-groups get-mappings get-plaintext-lines]
    utils       [base-url compact-hash compute-hmac get-thumbnail lru-cache ttl-cache report-processing-time trace-flow utc-date])

(setv log (getLogger __name__))

(setv sock (socket *af-inet* *sock-dgram*))

(setv *redirects* (get-mappings *redirect-page*))

(setv *banned-agents* (get-plaintext-lines *banned-agents-page*))

(setv *footer-links* (get-link-groups *links-page*))

; enable trace capture with AppInsights
(if *instrumentation-key* (enable *instrumentation-key*))

; redirect if trailing slashes
; ban some user agents
(with-decorator
    (hook "before_request")
    (defn before-request []
        (let [[path (get (. request environ) "PATH_INFO")]
              [ua   (.get (. request headers) "User-Agent" "")]]
            (if (in ua *banned-agents*)
                (abort (int 401) "Banned."))
            (if (and (!= path "/") (= "/" (slice path -1)))
                (redirect (slice path 0 -1) (int 301))))))


; grab page metadata or generate a minimal shim based on the last update
(with-decorator
    (ttl-cache 30)
    (defn get-minimal-metadata [pagename]
        (try
            (if pagename
                (get-page-metadata pagename)
                (let [[last (get-last-update-time)]]
                    {"hash"  (str last)
                     "mtime" last}))
            (except [e Exception]
                (.error log e)))))


(defn instrumented-processing-time [event]
    ; timing decorator with AppInsights reporting
    (setv client 
        (if *instrumentation-key*
            (TelemetryClient *instrumentation-key*)
            nil))
    (defn inner [func]
        (defn timed-fn [&rest args &kwargs kwargs]
            (let [[start (time)]
                  [result (apply func args kwargs)]
                  [elapsed (int (* 1000 (- (time) start)))]
                  [ua (.get (. request headers) "User-Agent" "")]
                  [ff (.get (. request headers) "X-Forwarded-For" "")]]
                (if client
                    (do
                         (.track_metric client "Processing Time" elapsed)
                         (.track_event client 
                             event {"Url" request.url
                                     "User-Agent" ua
                                     "X-Forwarded-For" ff} 
                                   {"Processing Time" elapsed})
                         (.flush client)))
                (.set-header response (str "Processing-Time") (+ (str elapsed) "ms"))
                result))
        timed-fn)
    inner)

 
; HTTP enrichment decorator - note that bottle automatically maps HEAD to GET, so no special handling is required for that.
(defn http-caching [page-key content-type seconds]
    (defn inner [func]
        (defn wrap-fn [&rest args &kwargs kwargs]
            (.set-header response (str "Content-Type") content-type)
            (if *debug-mode*
                (apply func args kwargs)
                (let [[pagename    (if page-key (.get kwargs page-key nil) nil)]
                      [etag-seed   (if page-key *asset-hash* (. request url))]
                      [metadata    (get-minimal-metadata pagename)]
                      [req-headers (. request headers)]
                      [none-match  (.get req-headers "If-None-Match" nil)]
                      [mod-since   (parse-date (.get req-headers "If-Modified-Since" ""))]]
                    (if metadata
                        (let [[pragma (if seconds "public" "no-cache, must-revalidate")]
                              [etag   (.format "W/\"{}\"" (compact-hash etag-seed content-type (get metadata "hash")))]]
                            (if (and mod-since (<= (get metadata "mtime") (.fromtimestamp datetime mod-since)))
                                (abort (int 304) "Not modified"))
                            (if (= etag none-match)
                                (abort (int 304) "Not modified"))
                            (.set-header response (str "Date") (http-date (gmtime)))
                            (.set-header response (str "X-sushy-http-caching") "True")
                            (.set-header response (str "ETag") etag)
                            (.set-header response (str "Last-Modified") (http-date (get metadata "mtime")))
                            (.set-header response (str "Expires") (http-date (+ (.now datetime) (apply relativedelta [] {"seconds" seconds}))))
                            (.set-header response (str "Cache-Control") (.format "{}, max-age={}, s-maxage={}" pragma seconds (* 2 seconds)))
                            (.set-header response (str "Pragma") pragma)))
                    (apply func args kwargs))))
        wrap-fn)
    inner)


; root to /space
(with-decorator 
    (handle-get "/")
    (defn home-page []
        (redirect *page-route-base* (int 301))))


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


; database stats
(with-decorator
    (handle-get "/stats")
    (report-processing-time)
    (http-caching nil "text/html" 0)
    (render-view "debug")
    (defn debug-dump []
        (if *debug-mode*
            {"base_url"         (base-url)
             "environ"          (get-table-stats)
             "headers"          {"title" "Database Statistics"}
             "page_route_base"  *page-route-base*
             "site_description" *site-description*
             "site_name"        *site-name*}
            (abort (int 404) "Page Not Found"))))


; RSS/atom feed
(with-decorator
    (handle-get "/atom")
    (handle-get "/feed")
    (handle-get "/rss")
    (instrumented-processing-time "feed")
    (http-caching nil "application/atom+xml" *feed-ttl*)
    (ttl-cache (/ *feed-ttl* 4))
    (render-view "atom")
    (defn serve-feed []
        (.set-header response (str "Content-Type") "application/atom+xml")
        {"base_url"         (base-url)
         "feed_ttl"         *feed-ttl*
         "items"            (render-feed-items (base-url))
         "page_route_base"  *page-route-base*
         "pubdate"          (utc-date (get-last-update-time))
         "site_copyright"   *site-copyright*
         "site_description" *site-description*
         "site_name"        *site-name*}))


; Sitemap
(with-decorator
    (handle-get "/sitemap.xml")
    (instrumented-processing-time "sitemap")
    (http-caching nil "text/xml" *feed-ttl*)
    (ttl-cache *feed-ttl*)
    (render-view "sitemap")
    (defn serve-sitemap []
        (setv (. response content-type) "text/xml")
        {"base_url"         (base-url)
         "items"            (get-all)
         "page_route_base"  *page-route-base*}))


; junk that needs to be at root level
(with-decorator
    (handle-get (% "/<filename:re:(%s)>" *root-junk*))
    (defn static-root [filename]
        (apply static-file [filename] {"root" (join *static-path* "root")})))


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
    (instrumented-processing-time "search")
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
             "site_name"        *site-name*
             "footer_links"     *footer-links*}
            {"base_url"         (base-url)
             "headers"          {}
             "page_route_base"  *page-route-base*
             "site_description" *site-description*
             "site_name"        *site-name*
             "footer_links"     *footer-links*})))

            
; static files
(with-decorator 
    (handle-get "/static/<filename:path>")
    (defn static-files [filename]
        (apply static-file [filename] {"root" *static-path*})))

        
; page media
(with-decorator 
    (handle-get (+ *page-media-base* "/<hash>/<filename:path>"))
    (defn page-media [hash filename]
        (if (= hash (compute-hmac *asset-hash* *page-media-base* (+ "/" filename)))
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
                {"base_url"         (base-url)
                 "body"             ""
                 "headers"          {"title" "Home Page"}
                 "pagename"         *site-name*
                 "page_route_base"  *page-route-base*                 
                 "site_description" *site-description*
                 "site_name"        *site-name*
                 "footer_links"     *footer-links*})) 


; page content
(with-decorator 
    (handle-get (+ *page-route-base* "/<pagename:path>"))
    (report-processing-time)
    (http-caching "pagename" "text/html" 3600)
    (ttl-cache 30)
    (render-view "wiki")
    (defn wiki-page [pagename] 
        (if (in (.lower pagename) *redirects*)
            (let [[target (get *redirects* (.lower pagename))]]
                (if (or (= "/" (get target 0)) (in "http" target))
                    (redirect target (int 301))
                    (redirect (+ *page-route-base* "/" target) (int 301))))
            (try
                (let [[page  (get-page pagename)]
                      [event (dict (. request headers))]]
                    (assoc event "url" (. request url))
                    (if *stats-port*
                        (.sendto sock (dumps event) (, *stats-address* *stats-port*)))
                    {"base_url"         (base-url)
                        "body"             (inner-html (apply-transforms (render-page page) pagename))            
                        "headers"          (:headers page)
                        "pagename"         pagename
                        "page_route_base"  *page-route-base*                 
                        "seealso"          (list (get-links pagename))
                        "site_description" *site-description*
                        "site_name"        *site-name*
                        "footer_links"     *footer-links*})
                (except [e IOError]
                    (let [[match (get-best-match pagename)]]
                        (if (!= match pagename)
                            (redirect (+ *page-route-base* "/" match) (int 301))
                            (redirect (+ "/search?q=" pagename)))))))))

; thumbnails
(with-decorator
    (handle-get (+ *scaled-media-base* "/<hash>/<x:int>,<y:int><effect:re:(\,(blur|sharpen)|)>/<filename:path>"))
    (report-processing-time)
    (http-caching nil "image/jpeg" 3600)
    (defn thumbnail-image [hash x y effect filename]
        (let [[size (, (long x) (long y))]
              [eff  (if (len effect) (slice effect 1) "")]
              [hmac (compute-hmac *asset-hash* *scaled-media-base* (+ (% "/%d,%d%s" (, x y effect)) "/" filename))]]
            (.debug log (, size hmac hash effect eff filename))
            (if (!= hash hmac)
                (abort (int 403) "Invalid Image Request")
                (let [[(, pagename asset) (split filename)]]
                    (.debug log (, pagename asset))
                    (if (asset-exists? pagename asset)
                        (let [[buffer (get-thumbnail x y eff (asset-path pagename asset))]
                              [length (len buffer)]]
                            (if length
                                (do
                                    (.set-header response (str "Content-Length") length)
                                    buffer)
                                (redirect "/static/img/placeholder.png")))
                        (redirect "/static/img/placeholder.png")))))))
