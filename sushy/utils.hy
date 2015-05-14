(import 
    [collections [OrderedDict]]
    [datetime    [datetime]]
    [functools   [wraps]]
    [logging     [getLogger]]
    [PIL         [Image]]
    [random      [sample]]
    [time        [time]])

(setv log (getLogger))

(def *datetime-format* "%Y%m%dT%H:%M:%S.%f")

(defn memoize []
    ; memoization decorator
    (defn inner [func]
        (setv cache {})
        (defn memoized-fn [&rest args]
            (let [[result nil]]
                (if (in args cache)
                    (.get cache args)
                    (setv result (apply func args)))
            (.setdefault cache args result)))
       memoized-fn)
    inner)


(defn lru-cache [&optional [limit 100]]
    ; LRU cache memoization decorator
    (defn inner [func]
        (setv cache (OrderedDict))
        (defn cached-fn [&rest args]
            (let [[result nil]]
                (try
                    (setv result (.pop cache args))
                    (catch [e KeyError]
                        (setv result (apply func args))
                (if (> (len cache) limit)
                    (.popitem cache 0))))
                (setv (get cache args) result)
                result))
        cached-fn)
    inner)


(defn ttl-cache [&optional [ttl 30]]
    ; memoization decorator with time-to-live
    (defn inner [func]
        (setv cache {})
        (defn cached-fn [&rest args]
            (let [[now      (time)]
                  [to-check (sample (.keys cache) (int (/ (len cache) 4)))]]
                ; check current arguments and 25% of remaining keys 
                (.append to-check args)

                (for [k to-check]
                    (let [[(, good-until value) (.get cache k (, now nil))]]
                        (if (< good-until now)
                            (del (get cache k)))))

                (if (in args cache)
                    (let [[(, good-until value) (get cache args)]]
                        value)
                    (let [[value (apply func args)]]
                        (assoc cache args (, (+ now ttl) value))
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
