(import
    [collections [OrderedDict]]
    [bottle      [request response]]
    [datetime    [datetime]]
    [functools   [wraps]]
    [logging     [getLogger]]
    [PIL         [Image]]
    [random      [sample]]
    [time        [time]])

(setv log (getLogger))

(def *datetime-format* "%Y%m%dT%H:%M:%S.%f")

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
                  [key (, args (tuple kwargs))]]
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
                  [key (, tag args (tuple kwargs))]]
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
                  [key      (, tag args (tuple kwargs))]
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
        (try
            (let [[im   (.open Image filename)]
                  [size (. im size)]]
                size)
        (catch [e Exception]
            (.warn log (% "Could not extract size from %s" filename))
            nil))))

           
(defn sse-pack [data]
    ; pack data in SSE format
    (+ (.join "" 
              (map (fn [k] 
                  (if (in k data)
                      (% "%s: %s\n" (, k (get data k)))
                      ""))
                  ["retry" "id" "event" "data"]))
        "\n"))


(defmacro timeit [block iterations]
    `(let [[t (time)]]
        (for [i (range ~iterations)]
            ~block)
        (print ~iterations (- (time) t))))
