(import 
    [bottle             [view :as render-template]]
    [config             [*exclude-from-feeds* *feed-css* *feed-ttl* *site-name* *site-copyright* *site-description*]]
    [datetime           [datetime]]
    [inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter]]
    [lxml.etree         [Element tostring fromstring]]
    [models             [*kvs* get-latest]]
    [os.path            [abspath]]
    [pytz               [*utc*]]
    [render             [render-page]]
    [store              [get-page]]
    [transform          [apply-transforms inner-html]])

(setv log (getLogger --name--))

(def *rss-date-format* "%a, %d %b %Y %H:%M:%S %z")

(def filtered-latest
    (genexpr x [x (get-latest)] (not (.match *exclude-from-feeds* (.get x "name")))))

(defn gather-items []
    (let [[items []]]
        (for [item filtered-latest]
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
                (.debug log item)
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
         "base_url"         base_url}))


(defmain [&rest args]
    (.info log "Updating feed")
    (print (render-feed "http://localhost")))
