(import 
    [collections [OrderedDict]]
    [functools   [wraps]]
    [PIL         [Image]])


(defn memoize [func]
    (setv cache {})
    (defn memoized-fn [&rest args]
        (let [[result nil]]
            (if (in args cache)
                (.get cache args)
                (setv result (apply func args)))
        (.setdefault cache args result)))
    memoized-fn)


(defn lru-cache [&optional [limit 100]]
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


(with-decorator lru-cache
    (defn get-image-size [path]
        (try
            (let [[im   (.open Image path)]
                  [size (. im size)]]
                size)
        (catch [e Exception]
            nil))))


(defmacro timeit [block]
    `(let [[t (time)]]
        ~block
        (print (- (time) t))))
