(import 
    [bottle             [view :as render-template]]
    [config             [*exclude-from-feeds* *feed-css* *feed-ttl* *site-name* *site-copyright* *site-description*]]
    [inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter]]
    [lxml.etree         [Element tostring fromstring]]
    [models             [*kvs* get-latest]]
    [os.path            [abspath]]
    [render             [render-page]]
    [store              [get-page]]
    [transform          [apply-transforms]])

(setv log (getLogger --name--))

(def *rss-date-format* "%a, %d %b %Y %H:%M:%S %z")

(def filtered-latest
    (genexpr x [x (get-latest)] (not (.match *exclude-from-feeds* (.get x "name")))))

(defn gather-items []
    (for [item filtered-latest]
        (let [[pagename (.get item "name")]
              [page     (get-page pagename)]
              [doc      (apply-transforms (render-page page) pagename)]]
            (.append doc (apply Element ["link"] {"rel"  "stylesheet"
                                                "href" (+ "file://" (abspath *feed-css*)) }))
            (assoc item
                "pubdate"     (.strftime (get item "pubtime") *rss-date-format*)
                "description" (fromstring (inline-css (tostring doc)))
                "category"    (get (.split pagename "/") 0))
            (.debug log item))))  


(with-decorator (render-template "rss")
    (defn render-feed [base_url]
        {"items"            (gather-items)
         "feed_ttl"         *feed-ttl*
         "site_name"        *site-name*
         "site_description" *site-description*
         "site_copyright"   *site-copyright*
         "base_url"         base_url}))


(defmain [&rest args]
    (.info log "Updating feed")
    (print (render-feed "http://localhost")))
