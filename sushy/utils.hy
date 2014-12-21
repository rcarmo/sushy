(import 
    [functools [wraps]]
    [struct [unpack]]
    [collections [OrderedDict]])

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


(defmacro timeit [block]
    `(let [[t (time)]]
        ~block
        (print (- (time) t))))
