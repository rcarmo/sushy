(import
    [logging [getLogger]]
    [config [*page-route-base*]]
    [urlparse [urlsplit]]
    [os.path [join]]
    [store [open-asset]]
    [pygments [highlight]]
    [pygments.lexers [get-lexer-by-name]]
    [pygments.formatters [HtmlFormatter]]
    [lxml.etree [ElementTree HTML tostring fromstring]]
)

(setv log (getLogger))


(defn base-href [doc pagename]
  ; inserts the base path into hrefs
  (.debug log doc)
  (.debug log pagename)
  (for [a (.xpath doc "//a[@href]")]
      (let [[href (get a.attrib "href")]
            [schema (get (urlsplit href) 0)]]
          (if (= (get href 0) "#")
              (assoc a.attrib "href" (+ (join *page-route-base* pagename) href))
              (if (= "" schema)
                  (assoc a.attrib "href" (join *page-route-base* href))))))
  doc)


(defn include-sources [doc pagename]
  ; searches for `pre` tags with a `src` attribute
  (for [tag (.xpath doc "//pre[@src]")]
      (.debug log pagename)
      (.debug log (tostring tag))
      (.debug log (get tag.attrib "src"))
      (try 
        (let [[filename (get tag.attrib "src")]
                [buffer (.read (open-asset pagename filename))]]
            (setv tag.text buffer))
        (catch [e Exception])))
   doc)


(defn syntax-highlight [doc]
  ; searches for `pre` tags with a `syntax` attribute
  (for [tag (.xpath doc "//pre[@syntax]")]
      (let [[syntax (get tag.attrib "syntax")]
            [lexer  (apply get-lexer-by-name [syntax] {"stripall" true})]
            [formatter (apply HtmlFormatter [] {"cssclass" "codehilite"})]]
          (if tag.text
            (.replace (.getparent tag) tag (fromstring (highlight tag.text lexer formatter))))))
  doc)

; TODO: pre src=file, include, interwiki links, alias replacements, all the "legacy" Yaki handling

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


(defn apply-transforms [page pagename]
    ; remember that Hy's threading macro manipulates the first argument slot
    (.debug log page)
    (-> page
        (HTML)
        (base-href pagename)
        (include-sources pagename)
        (syntax-highlight)
        (inner-html)))
