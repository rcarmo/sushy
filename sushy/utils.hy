(import 
    [lxml.etree [ElementTree HTML fromstring tostring]] 
    [render     [render-page]]
    [store      [get-page]])


(defn memoize [func]
    (setv cache {})

    (defn memoized_fn [*args]
        (if (in *args cache)
            (.get cache *args)
            (.setdefault cache *args (func *args))))
    memoized_fn)


(with-decorator memoize
    (defn get-mappings [page]
        ; searches for `pre` tags and builds key/value pairs
        (let [[mappings {}]
            [doc (HTML (render-page (get-page page)))]]
            (for [tag (.xpath doc "//pre")]
                (let [[lines (.splitlines tag.text)]
                    [pairs (map (fn [x] (.split x)) lines)]]
                    (for [pair pairs]
                        (if (= 2  (len pair))
                            (assoc mappings (.lower (get pair 0)) (get pair 1))))))
            mappings)))


(defmacro timeit [block]
    `(let [[t (time)]]
        ~block
        (print (- (time) t))))
