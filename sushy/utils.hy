(import 
    [collections [OrderedDict]]
    [functools   [wraps]]
    [PIL         [Image]])

(defn memoize [func]
    (setv cache {})

    (defn memoized-fn [*args]
        (if (in *args cache)
            (.get cache *args)
            (.setdefault cache *args (func *args))))
    memoized-fn)


(defn lru-cache [func &optional [limit 100]]
    (setv cache (OrderedDict))

    (defn cached-fn [*args]
        (let [[result nil]]
            (try 
                (setv result (.pop cache *args))
            (catch [e KeyError]
                (setv result (func *args))
                (if (> (len cache) limit)
                    (.popitem cache 0))))
            (setv (get cache *args) result)
            result))
    cached-fn)


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
