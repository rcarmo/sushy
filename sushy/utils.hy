(import
    [collections        [OrderedDict]]
    [base64             [urlsafe-b64encode]]
    [bottle             [request response]]
    [datetime           [datetime]]
    [dateutil.parser    [parse :as parse-date]]
    [functools          [wraps]]
    [hashlib            [sha1]]
    [hmac               [new :as new-hmac]]
    [logging            [getLogger]]
    [PIL                [Image  ]]
    [pytz               [timezone]]
    [random             [sample]]
    [StringIO           [StringIO]]
    [time               [time]]
    [urllib             [quote :as uquote]]
    [urlparse           [urlunparse]])

(setv log (getLogger))

(def *datetime-format* "%Y%m%dT%H:%M:%S.%f")

(def *gmt-format* "%a, %d %b %Y %H:%M:%S GMT")

(setv *utc* (timezone "UTC"))

(defn base-url []
    (slice (. request url) 0 (- (len (uquote (. request path))))))

; hashing and HMAC helpers
(defn compact-hash [&rest args]
    (let [[hash (sha1 (str args))]]
        (urlsafe-b64encode (.digest hash))))

        
(defn compute-hmac [key &rest args]
    (let [[buffer (.join "" (map str args))]]
        (urlsafe-b64encode (.digest (new-hmac key buffer sha1)))))


(defn report-processing-time []
    ; timing decorator
    (defn inner [func]
        (defn timed-fn [&rest args &kwargs kwargs]
            (let [[start (time)]
                  [result (apply func args kwargs)]]
                (.set-header response (str "Processing-Time") (+ (str (int (* 1000 (- (time) start)))) "ms"))
                result))
        timed-fn)
    inner)


(defn memoize []
    ; memoization decorator
    (defn inner [func]
        (setv cache {})
        (defn memoized-fn [&rest args &kwargs kwargs]
            (let [[result nil]
                  [key (compact-hash args kwargs)]]
                (if (in key cache)
                    (.get cache key)
                    (setv result (apply func args kwargs)))
                (.setdefault cache key result)))
       memoized-fn)
    inner)


(defn lru-cache [&optional [limit 100] [query-field nil]]
    ; LRU cache memoization decorator
    (defn inner [func]
        (setv cache (OrderedDict))
        (defn cached-fn [&rest args &kwargs kwargs]
            (let [[result nil]
                  [tag (if query-field (get (. request query) query-field))]
                  [key (compact-hash tag args kwargs)]]
                (try
                    (setv result (.pop cache key))
                    (catch [e KeyError]
                        (setv result (apply func args kwargs))
                (if (> (len cache) limit)
                    (.popitem cache 0))))
                (setv (get cache key) result)
                result))
        cached-fn)
    inner)


(defn ttl-cache [&optional [ttl 30] [query-field nil]]
    ; memoization decorator with time-to-live
    (defn inner [func]
        (setv cache {})
        (defn cached-fn [&rest args &kwargs kwargs]
            (let [[now      (time)]
                  [tag      (if query-field (get (. request query) query-field))]
                  [key      (compact-hash tag args kwargs)]
                  [to-check (sample (.keys cache) (int (/ (len cache) 4)))]]
                ; check current arguments and 25% of remaining keys 
                (.append to-check key)

                (for [k to-check]
                    (let [[(, good-until value) (.get cache k (, now nil))]]
                        (if (< good-until now)
                            (del (get cache k)))))

                (if (in key cache)
                    (let [[(, good-until value) (get cache key)]]
                        value)
                    (let [[value (apply func args kwargs)]]
                        (assoc cache key (, (+ now ttl) value))
                        value))))
        cached-fn)
    inner)
    

(with-decorator (lru-cache)
    (defn get-image-size [filename]
        ; extract image size information from a given filename
        (let [[im nil]]
            (try
                (do
                    (setv im (.open Image filename))
                    (let [[size (. im size)]]
                        (.close im)
                        size))
                (catch [e Exception]
                    (.warn log (, e filename))
                    nil)
                (finally (if im (.close im)))))))


(defn get-thumbnail [x y filename]
    (let [[im (.open Image filename)]
          [io (StringIO)]]
        (try
            (do
                (.thumbnail im (, x y) (. Image *antialias*))
                (apply .save [im io] {"format" "JPEG" "progressive" true "optimize" true "quality" (int 75)})
                (.getvalue io))
            (catch [e Exception]
                (.warn log (, e x y filename))
                "")
            (finally (.close io)))))


(defn sse-pack [data]
    ; pack data in SSE format
    (+ (.join "" 
              (map (fn [k] 
                  (if (in k data)
                      (% "%s: %s\n" (, k (get data k)))
                      ""))
                  ["retry" "id" "event" "data"]))
        "\n"))


(defn utc-date [string fallback]
    (let [[date (try
                    (parse-date string)
                    (catch [e Exception]
                        fallback))]]
        (if (. date tzinfo)
            (.astimezone date *utc*)
            date)))


(defmacro timeit [block iterations]
    `(let [[t (time)]]
        (for [i (range ~iterations)]
            ~block)
        (print ~iterations (- (time) t))))
