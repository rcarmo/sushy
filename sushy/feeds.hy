(import
    [config             [*exclude-from-feeds* *feed-css* *rss-date-format*]]
    [cssutils           [log :as *cssutils-log*]]
    [inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter *error*]]    
    [lxml.etree         [Element HTML fromstring tostring]]    
    [models             [get-latest]]
    [os.path            [abspath]]
    [pytz               [*utc*]]
    [render             [render-page]]
    [store              [get-page]]
    [transform          [apply-transforms inner-html prepend-asset-sources]]
    [utils              [utc-date]])

(setv log (getLogger --name--))

; disable logging for cssutils, since it is incredibly whiny
(.setLevel *cssutils-log* *error*)

(setv *inline-css* (.read (open (abspath *feed-css*) "r")))


(defn filtered-latest []
    (filter (fn [x] (not (.match *exclude-from-feeds* (.get x "name")))) (get-latest)))


(defn render-feed-items [&optional [prefix ""]]
    (let [[items []]]
        (for [item (filtered-latest)]
            (let [[pagename (.get item "name")]
                  [page     (get-page pagename)]
                  [doc      (prepend-asset-sources (apply-transforms (render-page page) pagename) prefix)]
                  [head     (apply Element ["head"] {})]
                  [style    (apply Element ["style"] {})]]
                (setv style.text *inline-css*)
                (.append head style)
                (.append doc head)
                (assoc item
                    "pagename"    pagename
                    "author"      (get (:headers page) "from")
                    "mtime"       (utc-date (get item "mtime"))
                    "pubdate"     (utc-date (get item "pubtime"))
                    "description" (inner-html (HTML (inline-css (apply tostring [doc] {"method" "html"}))))
                    "category"    (get (.split pagename "/") 0))
                (.append items item)))
        items))


(defmain [&rest args]
    (.info log (render-feed-items)))
