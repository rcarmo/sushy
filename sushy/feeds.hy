(import 
    [bottle             [view :as render-template]]
    [cssutils           [log :as *cssutils-log*]]
    [config             [*exclude-from-feeds* *feed-css* *feed-ttl* *page-route-base* *site-name* *site-copyright* *site-description*]]
    [datetime           [datetime]]
    [inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter *error*]]
    [lxml.etree         [Element tostring fromstring]]
    [models             [*kvs* get-all get-latest]]
    [os.path            [abspath]]
    [pytz               [*utc*]]
    [render             [render-page]]
    [store              [get-page]]
    [transform          [apply-transforms inner-html]])

(setv log (getLogger --name--))

(.setLevel *cssutils-log* *error*); disable logging, since it is incredibly whiny

(def *rss-date-format* "%a, %d %b %Y %H:%M:%S %z")

(defn filtered-latest []
    (filter (fn [x] (not (.match *exclude-from-feeds* (.get x "name")))) (get-latest)))

(defn gather-items []
    (let [[items []]]
        (for [item (filtered-latest)]
            (let [[pagename (.get item "name")]
                [page     (get-page pagename)]
                [doc      (apply-transforms (render-page page) pagename)]]
                (.append doc (apply Element ["link"] {"rel"  "stylesheet"
                                                      "href" (+ "file://" (abspath *feed-css*)) }))
                (assoc item
                    "pagename"     pagename
                    "author"       (get (:headers page) "from")
                    "pubdate"     (.strftime (.localize *utc* (get item "pubtime")) *rss-date-format*)
                    "description"  (inner-html (fromstring (inline-css (tostring doc))))
                    "category"    (get (.split pagename "/") 0))
                (.append items item)))
        items)) 


(with-decorator (render-template "rss")
    (defn render-feed [base_url]
        {"pubdate"          (.strftime (.localize *utc* (.now datetime)) *rss-date-format*)
         "items"            (gather-items)
         "feed_ttl"         *feed-ttl*
         "site_name"        *site-name*
         "site_description" *site-description*
         "site_copyright"   *site-copyright*
         "page_route_base"  *page-route-base*
         "base_url"         base_url}))


(with-decorator (render-template "sitemap")
    (defn render-sitemap [base_url]
        {"items"            (get-all)
         "page_route_base"  *page-route-base*
         "base_url"         base_url}))


(defmain [&rest args]
    (.info log "Updating feed")
    (print (render-feed "http://localhost")))
