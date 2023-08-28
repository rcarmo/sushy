(import
    collections        [OrderedDict]
    base64             [urlsafe-b64encode]
    bottle             [request response]
    calendar           [timegm]
    datetime           [datetime]
    dateutil.parser    [parse :as parse-date]
    functools          [wraps]
    hashlib            [sha1]
    hmac               [new :as new-hmac]
    io                 [StringIO]
    logging            [getLogger]
    PIL                [Image ImageFilter]
    pytz               [timezone]
    random             [sample]
    slugify            [slugify]
    time               [time]
    urllib.parse       [quote :as uquote urlsplit urlunparse])

(setv log (getLogger))

(setv *datetime-format* "%Y%m%dT%H:%M:%S.%f")

(setv *time-intervals*
    {"00:00-00:59" "late night"
     "01:00-04:59" "in the wee hours"
     "05:00-06:59" "at dawn"
     "07:00-08:59" "at breakfast"
     "09:00-12:29" "in the morning"
     "12:30-14:29" "at lunchtime"
     "14:30-16:59" "in the afternoon"
     "17:00-17:29" "at teatime"
     "17:30-18:59" "at late afternoon"
     "19:00-20:29" "in the evening"
     "20:30-21:29" "at dinnertime"
     "21:30-22:29" "at night"
     "22:30-23:59" "late night"})
     
(setv *readable-intervals* 
    {31556926 "year"
     2592000 "month"
     604800 "week"
     86400 "day"
     3600 "hour"
     60 "minute"})

(setv *utc* (timezone "UTC"))

(defn base-url []
    (let [#(scheme netloc path query fragment) (urlsplit (. request url))
          base                                 (urlunparse (, scheme netloc "" "" "" ""))]
        base))

; hashing and HMAC helpers
(defn compact-hash [#* args]
    (let [hash (sha1 (.encode (str args) "utf-8"))]
        (urlsafe-b64encode (.digest hash))))

        
(defn compute-hmac [key #* args]
    (let [buffer (.join "" (map str args))]
        (urlsafe-b64encode (.digest (new-hmac key buffer sha1)))))


(defn trace-flow []
    ; dump arguments and data to the debug log
    (defn inner [func]
        (defn trace-fn [#* args #** kwargs]
            (.debug log (, "trace ->" args kwargs))
            ; TODO: decide how to replace this apply
            (let [result (func args kwargs)]
                (. debug log (, "trace <-" result))
                result))
        trace-fn)
    inner)


(defn report-processing-time []
    ; timing decorator
    (defn inner [func]
        (defn timed-fn [#* args #** kwargs]
            (let [start (time)
                  ; TODO: decide how to replace this apply
                  result (func args kwargs)]
                (.set-header response (str "Processing-Time") (+ (str (int (* 1000 (- (time) start)))) "ms"))
                result))
        timed-fn)
    inner)


(defn memoize []
    ; memoization decorator
    (defn inner [func]
        (setv cache {})
        (defn memoized-fn [#* args #** kwargs]
            (let [result None
                  key (compact-hash args kwargs)]
                (if (in key cache)
                    (.get cache key)
                    (setv result (func args kwargs)))
                (.setdefault cache key result)))
       memoized-fn)
    inner)


(defn lru-cache [func [limit 64] [query-field None]]
    ; LRU cache memoization decorator
    (setv cache (OrderedDict))
    ((wraps func)
         (fn [#* args #** kwargs]
            (let [result None
                  tag (when query-field (get (. request query) query-field))
                  key (compact-hash tag args kwargs)]
                (try
                    (setv result (.pop cache key))
                    (except [e KeyError]
                        (setv result (func args kwargs))
                    (when (> (len cache) limit)
                         (.popitem cache 0))))
                (setv (get cache key) result)
                result))))


(defn ttl-cache [[ttl 30] [query-field None]]
    ; memoization decorator with time-to-live
    (defn inner [func]
        (setv cache {})
        (defn cached-fn [#* args #** kwargs]
            (let [now      (time)
                  tag      (when query-field (get (. request query) query-field))
                  key      (compact-hash tag args kwargs)
                  to-check (sample (.keys cache) (int (/ (len cache) 4)))]
                ; check current arguments and 25% of remaining keys 
                (.append to-check key)

                (for [k to-check]
                    (let [#(good-until value) (get cache k #(now None))]
                        (when (< good-until now)
                            (del (get cache k)))))

                (if (in key cache)
                    (let [#(good-until value) (get cache key)]
                        value)
                    (let [value (func args kwargs)]
                        (assoc cache key (, (+ now ttl) value))
                        value))))
        cached-fn)
    inner)
    

(defn [lru-cache] get-image-size [filename]
    ; extract image size information from a given filename
    (let [im None]
        (try
            (do
                (setv im (.open Image filename))
                (let [size (. im size)]
                    (.close im)
                    size))
            (except [e Exception]
                (.warn log (, e filename))
                None)
            (finally (when im (.close im))))))


(defn get-thumbnail [x y effect filename]
    (let [im (.open Image filename)
          io (StringIO)]
        (try
            (do
                (.thumbnail im (, x y) (. Image *bicubic*))
                (when (= effect "blur") 
                    (setv im (.filter im (. ImageFilter GaussianBlur))))
                (when (= effect "sharpen") 
                    (setv im (.filter im (. ImageFilter UnsharpMask))))
                (apply .save [im io] {"format" "JPEG" "progressive" true "optimize" true "quality" (int 80)})
                (.getvalue io))
            (except [e Exception]
                (.warn log (, e x y filename))
                "")
            (finally (.close io)))))


(defn slug [text]
    ; create a URL slug from arbitrary text
    (slugify text))
    

(defn sse-pack [data]
    ; pack data in SSE format
    (+ (.join "" 
              (map (fn [k] 
                    (if (in k data)
                        (% "%s: %s\n" (, k (get data k)))
                        ""))
                  ["retry" "id" "event" "data"]))
       "\n"))


(defn utc-date [date [tz *utc*]]
    ; convert naive (or not) dates into UTC
    (if (. date tzinfo)
        (.astimezone date *utc*)
        (.astimezone (.localize tz date) *utc*)))


(defn strip-timezone [date]
    (.replace date :tzinfo None))


(defn parse-naive-date [string fallback [tz *utc*]]
    ; parse a date string and return a UTC date
    (if string
        (let [date (try
                       (parse-date string)
                       (except [e Exception]
                           (.warning log (% "Could not parse %s" string))
                           fallback))]
            (utc-date date tz))
        fallback))


(defn ordinal [num]
    (+ (str num) "<sup>"
        (if (<= 10 (% num 100) 20)
            "th"
            (.get {1 "st" 2 "nd" 3 "rd"} (% num 10) "th"))
        "</sup>"))


(defn fuzzy-time [date]
    ; describes a date as a time of day
    (let [when (.strftime date "%H:%M")]
        (.get
            *time-intervals* 
            (.next (filter (fn [x] (let [#(l u) (.split x "-")] (and (<= l when) (<= when u)))) 
                    (sorted (.keys *time-intervals*))))
            "sometime")))

            
(defn time-chunks [begin-interval [end-interval None]]
    ; breaks down a time interval into a sequence of time chunks 
    (let [chunks   (sorted (.keys *readable-intervals*) :reverse True)
          the-end  (if end-interval end-interval (datetime.now))
          interval (- (timegm (.timetuple the-end)) (timegm (.timetuple begin-interval)))
          values []]
        (for [i chunks]
            (setv #(d r) (divmod interval i))
            (.append values (, (int d) (.get *readable-intervals* i)))
            (setv interval r))
        (filter (fn [x] (pos? (get x 0))) values)))


(defn string-plurals [chunk]
    (let [#(v s) chunk]
        (.join " " (map str (, v (if (> v 1) (+ s "s") s))))))


(defn time-since [begin-interval [end-interval None]]
    (let [chunks (list (map string-plurals (time-chunks begin-interval end-interval)))]
        (if (not (len (list chunks)))
            "sometime"
            (.join ", " (take 2 chunks)))))
        

(defmacro timeit [block iterations]
    `(let [t (time)]
        (for [i (range ~iterations)]
            ~block)
        (print ~iterations (- (time) t))))
