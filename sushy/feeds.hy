(import
    [config             [*exclude-from-feeds* *feed-css* *feed-time-window* *feed-item-window*]]
    [cssutils           [log :as *cssutils-log*]]
    [datetime           [datetime]]
    [inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter *error*]]    
    [lxml.etree         [Element HTML fromstring tostring]]    
    [models             [get-latest]]
    [os.path            [abspath]]
    [pytz               [*utc*]]
    [render             [render-page]]
    [store              [get-page]]
    [transform          [apply-transforms inner-html prepend-asset-sources remove-preloads]]
    [utils              [utc-date strip-timezone]])

(setv log (getLogger --name--))

; disable logging for cssutils, since it is incredibly whiny
(.setLevel *cssutils-log* *error*)

(setv *inline-css* (.read (open (abspath *feed-css*) "r")))


(defn filtered-latest []
    ; get the latest (eligible) updates 
    (let [[time-window (strip-timezone (utc-date (+ (.now datetime) *feed-time-window*)))]]
        (filter (fn [x] (not (.match *exclude-from-feeds* (.get x "name")))) (apply get-latest [] {"since" time-window "limit" *feed-item-window*}))))


(defn render-feed-items [[prefix ""]]
    ; go through each item and replace inline styles
    (let [[items []]]
        (for [item (filtered-latest)]
            (let [[pagename (.get item "name")]
                  [page     (get-page pagename)]
                  ; serve only final image assets, not preload stubs
                  [doc      (prepend-asset-sources (remove-preloads (apply-transforms (render-page page) pagename)) prefix)]
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
                    "tags"        (list (filter len (map (fn [x] (.strip x)) (.split (get item "tags") ","))))
                    "description" (inner-html (HTML (inline-css (apply tostring [doc] {"method" "html"}))))
                    "category"    (get (.split pagename "/") 0))
                (.append items item)))
        items))
