(import
    [config             [*exclude-from-feeds* *feed-css* *rss-date-format*]]
    [cssutils           [log :as *cssutils-log*]]
    [inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter *error*]]    
    [lxml.etree         [Element fromstring tostring]]    
    [models             [get-latest]]
    [os.path            [abspath]]
    [pytz               [*utc*]]
    [render             [render-page]]
    [store              [get-page]]
    [transform          [apply-transforms inner-html]])

(setv log (getLogger --name--))

; disable logging for cssutils, since it is incredibly whiny
(.setLevel *cssutils-log* *error*)


(defn filtered-latest []
    (filter (fn [x] (not (.match *exclude-from-feeds* (.get x "name")))) (get-latest)))


(defn render-feed-items []
    (let [[items []]]
        (for [item (filtered-latest)]
            (let [[pagename (.get item "name")]
                  [page     (get-page pagename)]
                  [doc      (apply-transforms (render-page page) pagename)]]
                (.append doc (apply Element ["link"] {"rel"  "stylesheet"
                                                      "href" (+ "file://" (abspath *feed-css*))}))
                (assoc item
                    "pagename"    pagename
                    "author"      (get (:headers page) "from")
                    "pubdate"     (.strftime (.localize *utc* (get item "pubtime")) *rss-date-format*)
                    "description" (inner-html (fromstring (inline-css (tostring doc))))
                    "category"    (get (.split pagename "/") 0))
                (.append items item)))
        items))


(defmain [&rest args]
    (.info log (render-feed-items)))