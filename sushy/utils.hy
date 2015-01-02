(import 
    [collections [OrderedDict]]
    [functools   [wraps]]
    [logging     [getLogger]]
    [PIL         [Image]]
    [time        [time]])

(setv log (getLogger))

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


(defn sticky-cache [&optional [ttl 30]]
    ; timed cache memoization decorator that will return the same value for repeated 
    ; invocations inside a specific time interval
    (defn inner [func]
        (setv cache {})
        (defn cached-fn [&rest args]
            (let [[now      (time)]
                  [result   (if (in args cache)
                                (let [[(, timestamp value) (.get cache args)]]
                                    (if (< timestamp now)
                                        (apply func args)
                                        value))
                                (apply func args))]]
                (assoc cache args (, (+ now ttl) result))
                result))
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


(defmacro timeit [block]
    `(let [[t (time)]]
        ~block
        (print (- (time) t))))
