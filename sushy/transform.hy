(import
    [logging [getLogger]]
    [config [*page-route-base*]]
    [urlparse [urlsplit]]
    [os.path [join]]
    [lxml.etree [HTML tostring]])

(setv log (getLogger))


(defn base-href [doc pagename]
    (for [a (.xpath doc "//a")]
       (let [[href (get a.attrib "href")]
             [schema (get (urlsplit href) 0)]]
             (if (= (get href 0) "#")
                (assoc a.attrib "href" (join *page-route-base* pagename href))
                (if (= "" schema)
                   (assoc a.attrib "href" (join *page-route-base* href))))))
    doc)



(defn apply-transforms [pagename html]
    ; remember that Hy's threading macro manipulates the first argument slot
    (-> html
        (HTML)
        (base-href pagename)
        (tostring)))
