(import
    [logging [getLogger]]
    [lxml.etree [HTML tostring]])

(setv log (getLogger))


(defn base-href [doc]
    (for [a (.xpath doc "//a")]
        (print a))
    doc)


(defn apply-transforms [html]
    (-> html
        (HTML)
        (base-href)
        (tostring)))
