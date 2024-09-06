(import
    .config            [EXCLUDE_FROM_FEEDS FEED_CSS FEED_TIME_WINDOW FEED_ITEM_WINDOW]
    .models            [get-latest]
    .render            [render-page]
    .store             [get-page]
    .transform         [apply-transforms inner-html prepend-asset-sources remove-preloads]
    .utils             [utc-date strip-timezone]
    cssutils           [log :as cssutils-log]
    datetime           [datetime]
    hyrule.collections [assoc]
    inlinestyler.utils [inline-css]
    logging            [getLogger Formatter ERROR]
    lxml.etree         [Element HTML fromstring tostring]
    os.path            [abspath]
    pytz               [UTC])

(setv log (getLogger __name__))

; disable logging for cssutils, since it is incredibly whiny
(.setLevel cssutils-log ERROR)

(setv INLINE_CSS (.read (open (abspath FEED_CSS) "r")))


(defn filtered-latest []
    ; get the latest (eligible) updates 
    (let [time-window (strip-timezone (utc-date (+ (.now datetime) FEED_TIME_WINDOW)))]
        (filter (fn [x] (not (.match EXCLUDE_FROM_FEEDS (.get x "name")))) (get-latest :since time-window :limit FEED_ITEM_WINDOW))))


(defn render-feed-items [[prefix ""]]
    ; go through each item and replace inline styles
    (let [items []]
        (for [item (filtered-latest)]
            (let [pagename (.get item "name")
                  page     (get-page pagename)
                  ; serve only final image assets, not preload stubs
                  doc      (prepend-asset-sources (remove-preloads (apply-transforms (render-page page) pagename)) prefix)
                  head     (Element "head")
                  style    (Element "style")]
                (setv style.text INLINE_CSS)
                (.append head style)
                (.append doc head)
                (assoc item
                    "pagename"    pagename
                    "author"      (get (:headers page) "from")
                    "mtime"       (utc-date (get item "mtime"))
                    "pubdate"     (utc-date (get item "pubtime"))
                    "tags"        (list (filter len (map (fn [x] (.strip x)) (.split (get item "tags") ","))))
                    "description" (inner-html (HTML (inline-css (tostring doc :method "html"))))
                    "category"    (get (.split pagename "/") 0))
                (.append items item)))
        items))
