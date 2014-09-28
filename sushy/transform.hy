(import
    [logging [getLogger]]
    [config [*page-route-base*]]
    [urlparse [urlsplit]]
    [os.path [join]]
    [lxml.etree [HTML tostring]])

(setv log (getLogger))


(defn base-href [doc pagename]
  ; inserts the base path into hrefs
  (for [a (.xpath doc "//a")]
      (let [[href (get a.attrib "href")]
            [schema (get (urlsplit href) 0)]]
          (if (= (get href 0) "#")
              (assoc a.attrib "href" (+ (join *page-route-base* pagename) href))
              (if (= "" schema)
                  (assoc a.attrib "href" (join *page-route-base* href))))))
  doc)

; TODO: syntax highlighting, interwiki links, alias replacements, all the "legacy" Yaki handling

(defn inner-html [doc]
  ; Returns the content of a doc without extraneous tags
  (let [[body (get (.xpath doc "//body") 0)]
        [children []]]
    (for [child (.iterchildren body)]
         (.append children (tostring child)))
    (.join "" children)))


(defn compact-plaintext [doc]
  ; Returns a compacted version of the plaintext without duplicate whitespace
  (let [[body (get (.xpath doc "//body") 0)]
        [children []]]
    (for [child (.iterchildren body)]
         (.append children (apply tostring [child] {"method" "text" "encoding" "unicode"})))
    (.join " " (.split (.join "" children)))))


(defn apply-transforms [html pagename]
    ; remember that Hy's threading macro manipulates the first argument slot
    (-> html
        (HTML)
        (base-href pagename)
        (inner-html)))
