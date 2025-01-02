(import
    .aliasing   [get-best-match]
    .config     [ASSET_HASH BANNED_AGENTS_PAGE DEBUG_MODE EXCLUDE_FROM_FEEDS FEED_CSS FEED_TTL PAGE_MEDIA_BASE PAGE_ROUTE_BASE PLACEHOLDER_IMAGE SITE_COPYRIGHT SITE_DESCRIPTION SITE_NAME STATIC_PATH LINKS_PAGE STATS_ADDRESS STATS_PORT STORE_PATH SCALED_MEDIA_BASE THUMBNAIL_SIZES TIMEZONE ROOT_JUNK REDIRECT_PAGE]
    .feeds      [render-feed-items]
    .models     [search get-links get-all get-page-metadata get-latest get-last-update-time get-table-stats]
    .render     [render-page]
    .store      [asset-exists? asset-path get-page]
    .transform  [apply-transforms inner-html get-link-groups get-mappings get-plaintext-lines]
    .utils      [base-url compact-hash compute-hmac get-thumbnail ttl-cache report-processing-time trace-flow utc-date]
    aiohttp.web [RouteTableDef HTTPFound HTTPNotFound HTTPUnauthorized]
    aiohttp_jinja2 [template]
    datetime    [datetime]
    dateutil.relativedelta  [relativedelta]
    functools   [lru-cache]
    json        [dumps]
    logging     [getLogger]
    os          [environ]
    os.path     [join split]
    pytz        [UTC]
    socket      [socket AF_INET SOCK_DGRAM]
    time        [gmtime time])

(setv log (getLogger __name__))

(setv sock (socket AF_INET SOCK_DGRAM))

(setv REDIRECTS (get-mappings REDIRECT_PAGE))

(setv BANNED_AGENTS (get-plaintext-lines BANNED_AGENTS_PAGE))

(setv FOOTER_LINKS (get-link-groups LINKS_PAGE))

(setv routes (RouteTableDef))

; redirect if trailing slashes
; ban some user agents
(defn :async before-request [request response]
    (let [path (. request path)
          ua   (.get (. request headers) "User-Agent" "")]
        (when (in ua BANNED_AGENTS)
            (raise (HTTPUnauthorized "Banned.")))
        (when (and (!= path "/") (= "/" (slice path -1)))
            (raise (HTTPFound :location (slice path 0 -1))))
        response))


; grab page metadata or generate a minimal shim based on the last update
(defn [(ttl-cache 30)] get-minimal-metadata [pagename]
    (try
        (if pagename
            (get-page-metadata pagename)
            (let [last (get-last-update-time)]
                {"hash"  (str last)
                 "mtime" last}))
        (except [e Exception]
            (.error log e))))


(defn instrumented-processing-time [event]
    ; timing decorator
    (defn inner [func]
        (defn timed-fn [#* args #** kwargs]
            ; TODO: extended tracking
            (let [start   (time)
                  result  (func #* args #** kwargs)
                  elapsed (int (* 1000 (- (time) start)))
                  ua      (.get (. request headers) "User-Agent" "")
                  ff      (.get (. request headers) "X-Forwarded-For" "")]
                (.set-header response (str "Processing-Time") (+ (str elapsed) "ms"))
                result))
        timed-fn)
    inner)

 
; HTTP enrichment decorator - note that bottle automatically maps HEAD to GET, so no special handling is required for that.
(defn http-caching [page-key content-type seconds]
    (defn inner [func]
        (defn wrap-fn [#* args #** kwargs]
            (.set-header response (str "Content-Type") content-type)
            (if DEBUG_MODE
                (func #* args #** kwargs)
                (let [pagename    (if page-key (.get kwargs page-key None) None)
                      etag-seed   (if page-key ASSET_HASH (. request url))
                      metadata    (get-minimal-metadata pagename)
                      req-headers (. request headers)
                      none-match  (.get req-headers "If-None-Match" None)
                      mod-since   (parse-date (.get req-headers "If-Modified-Since" ""))]
                    (when metadata
                        (let [pragma (if seconds "public" "no-cache, must-revalidate")
                              etag   (.format "W/\"{}\"" (compact-hash etag-seed content-type (get metadata "hash")))]
                            (when (and mod-since (<= (get metadata "mtime") (.fromtimestamp datetime mod-since)))
                                (abort 304 "Not modified"))
                            (when (= etag none-match)
                                (abort 304 "Not modified"))
                            (.set-header response "Date" (http-date (gmtime)))
                            (.set-header response "X-sushy-http-caching" "True")
                            (.set-header response "ETag" etag)
                            (.set-header response "Last-Modified" (http-date (get metadata "mtime")))
                            (.set-header response "Expires" (http-date (+ (.now datetime) (relativedelta :seconds seconds))))
                            (.set-header response "Cache-Control" (.format "{}, max-age={}, s-maxage={}" pragma seconds (* 2 seconds)))
                            (.set-header response "Pragma" pragma)))
                    (func #* args #** kwargs))))
        wrap-fn)
    inner)


;aiohttp_jinja2.setup(
;    app, enable_async=True,
;    loader=jinja2.FileSystemLoader('/path/to/templates/folder'))


; root to /space
(defn :async [(.get routes "/")] home-page []
    (raise (HTTPFound :location (PAGE_ROUTE_BASE))))


(defn :async [(.get routes "/env")
              (report-processing-time)
              (http-caching None "text/html" 0)
              (template "debug")]
  env-dump [request]
    ; environment dump
    (if DEBUG_MODE
      {"base_url"         (base-url)
       "environ"          (dict environ)
       "headers"          {"title" "Environment dump"}
       "page_route_base"  PAGE_ROUTE_BASE
       "site_description" SITE_DESCRIPTION
       "site_name"        SITE_NAME}
      (raise HTTPNotFound "Page Not Found")))


(defn :async [(.get routes "/stats")
              (report-processing-time)
              (http-caching None "text/html" 0)
              (template "debug")]
  debug-dump []
    ; database stats
    (if DEBUG_MODE
      {"base_url"         (base-url)
       "environ"          (get-table-stats)
       "headers"          {"title" "Database Statistics"}
       "page_route_base"  PAGE_ROUTE_BASE
       "site_description" SITE_DESCRIPTION
       "site_name"        SITE_NAME}
      (raise HTTPNotFound "Page Not Found")))


(defn :async [(.get routes "/atom.xml")
              (instrumented-processing-time "feed")
              (http-caching None "application/atom+xml" FEED_TTL)
              (ttl-cache (/ FEED_TTL 4))
              (template "atom")]
  serve-feed [request]
    ; RSS/atom feed
    {"base_url"         (base-url)
     "feed_ttl"         FEED_TTL
     "items"            (render-feed-items (base-url))
     "page_route_base"  PAGE_ROUTE_BASE
     "pubdate"          (utc-date (get-last-update-time))
     "site_copyright"   SITE_COPYRIGHT
     "site_description" SITE_DESCRIPTION
     "site_name"        SITE_NAME})


(defn :async [(.get routes "/sitemap.xml")
              (instrumented-processing-time "sitemap")
              (http-caching None "text/xml" FEED_TTL)
              (ttl-cache FEED_TTL)
              (template "sitemap")]
  serve-sitemap []
    ; Sitemap
    {"base_url"         (base-url)
     "items"            (get-all)
     "page_route_base"  PAGE_ROUTE_BASE})


; junk that needs to be at root level
(defn [(handle-get (% "/<filename:re:(%s)>" ROOT_JUNK))]
     static-root [filename]
        (static-file filename :root (join STATIC_PATH "root")))


; robots.txt
(defn [(handle-get "/robots.txt")
       (report-processing-time)
       (http-caching None "text/plain" 3600)
       (ttl-cache 3600)
       (render-view "robots")]
    serve-robots []
        {"base_url"         (base-url)
         "page_route_base"  PAGE_ROUTE_BASE})


; OpenSearch metadata
(defn [(handle-get "/opensearch.xml")
       (report-processing-time)
       (http-caching None "text/xml" 3600)
       (ttl-cache 3600)
       (render-view "opensearch")]
    handle-opensearch []
        {"base_url"         (base-url)
         "site_description" SITE_DESCRIPTION
         "site_name"        SITE_NAME})

         
; search
(defn [(handle-get "/search")
       (instrumented-processing-time "search")
       (http-caching None "text/html" 30)
       (ttl-cache 30 "q")
       (render-view "search")]
    handle-search []
        (if (in "q" (.keys (. request query)))
            {"base_url"         (base-url)
             "headers"          {}
             "page_route_base"  PAGE_ROUTE_BASE
             "query"            (. request query q)
             "results"          (search (. request query q))
             "site_description" SITE_DESCRIPTION
             "site_name"        SITE_NAME
             "footer_links"     FOOTER_LINKS}
            {"base_url"         (base-url)
             "headers"          {}
             "page_route_base"  PAGE_ROUTE_BASE
             "site_description" SITE_DESCRIPTION
             "site_name"        SITE_NAME
             "footer_links"     FOOTER_LINKS}))

            
; static files
(defn [(handle-get "/static/<filename:path>")]
    static-files [filename]
        (static-file filename :root STATIC_PATH))

        
; page media
(defn [(handle-get (+ PAGE_MEDIA_BASE "/<hash>/<filename:path>"))]
    page-media [hash filename]
        (if (= hash (compute-hmac ASSET_HASH PAGE_MEDIA_BASE (+ "/" filename)))
            (static-file filename :root STORE_PATH)
            (redirect PLACEHOLDER_IMAGE)))


; blog index
(defn [(handle-get PAGE_ROUTE_BASE)
       (report-processing-time)
       (http-caching "route-base" "text/html" 3600)
       (ttl-cache 60)
       (render-view "blog")]
    blog-homepage []
       {"base_url"         (base-url)
        "body"             ""
        "headers"          {"title" "Home Page"}
        "pagename"         SITE_NAME
        "page_route_base"  PAGE_ROUTE_BASE                 
        "site_description" SITE_DESCRIPTION
        "site_name"        SITE_NAME
        "footer_links"     FOOTER_LINKS}) 


; page content
(defn [(handle-get (+ PAGE_ROUTE_BASE "/<pagename:path>"))
       (report-processing-time)
       (http-caching "pagename" "text/html" 3600)
       (ttl-cache 30)
       (render-view "wiki")]
    wiki-page [pagename] 
        (if (in (.lower pagename) REDIRECTS)
            (let [target (get REDIRECTS (.lower pagename))]
                (if (or (= "/" (get target 0)) (in "http" target))
                    (redirect target 301)
                    (redirect f"{PAGE_ROUTE_BASE}/{target}" 301)))
            (try
                (let [page  (get-page pagename)
                      event (dict (. request headers))]
                    (setv (get event "url") (. request url))
                    (when STATS_PORT
                        (.sendto sock (dumps event) #(STATS_ADDRESS STATS_PORT)))
                    {"base_url"         (base-url)
                     "body"             (inner-html (apply-transforms (render-page page) pagename))            
                     "headers"          (:headers page)
                     "pagename"         pagename
                     "page_route_base"  PAGE_ROUTE_BASE                 
                     "seealso"          (list (get-links pagename))
                     "site_description" SITE_DESCRIPTION
                     "site_name"        SITE_NAME
                     "footer_links"     FOOTER_LINKS})
                (except [e IOError]
                    (let [match (get-best-match pagename)]
                        (if (!= match pagename)
                            (redirect f"{PAGE_ROUTE_BASE}/{match}" 301)
                            (redirect f"/search?q={pagename}")))))))

; thumbnails
(defn [(handle-get (+ SCALED_MEDIA_BASE "/<hash>/<x:int>,<y:int><effect:re:(\\,(blur|sharpen)|)>/<filename:path>"))
       (report-processing-time)
       (http-caching None "image/jpeg" 3600)]
    thumbnail-image [hash x y effect filename]
        (let [size #((long x) (long y))
              eff  (if (len effect) (slice effect 1) "")
              hmac (compute-hmac ASSET_HASH SCALED_MEDIA_BASE f"/{x},{y},{effect}/{filename}")]
            (.debug log f"{size} {hmac} {hash} {effect} {eff} {filename}")
            (if (!= hash hmac)
                (abort 403 "Invalid Image Request")
                (let [#(pagename asset) (split filename)]
                    (.debug log f"{pagename} {asset}")
                    (if (asset-exists? pagename asset)
                        (let [buffer (get-thumbnail x y eff (asset-path pagename asset))
                              length (len buffer)]
                            (when length
                                (do
                                    (.set-header response (str "Content-Length") length)
                                    buffer)
                                (redirect "/static/img/placeholder.png")))
                        (redirect "/static/img/placeholder.png"))))))
