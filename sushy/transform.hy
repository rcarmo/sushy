; Perform HTML transforms
(import
    [re                  [sub *ignorecase*]]
    [logging             [getLogger]]
    [config              [*page-route-base* *page-media-base* *interwiki-page*]]
    [urlparse            [urlsplit]]
    [os.path             [join basename]]
    [store               [open-asset]]
    [utils               [get-mappings]]
    [messages            [inline-message]]
    [pygments            [highlight]]
    [pygments.lexers     [get-lexer-by-name]]
    [pygments.formatters [HtmlFormatter]]
    [lxml.etree          [ElementTree HTML tostring fromstring]])

(setv log (getLogger))


(defn base-href [doc pagename]
  ; inserts the base path into hrefs
  (for [a (.xpath doc "//a[@href]")]
      (let [[href (get a.attrib "href")]
            [schema (get (urlsplit href) 0)]]
          (if (= (get href 0) "#")
              (assoc a.attrib "href" (+ (join *page-route-base* pagename) href))
              (if (= "" schema)
                  (assoc a.attrib "href" (join *page-route-base* href))))))
  doc)


(defn interwiki-links [doc]
    ; replaces interwiki hrefs
    (let [[interwiki-map (get-mappings *interwiki-page*)]]
        (for [a (.xpath doc "//a[@href]")]
            (let [[href (get a.attrib "href")]
                  [schema (get (urlsplit href) 0)]]
                (if (in schema interwiki-map)
                    (assoc a.attrib "href" (sub (+ schema ":") (get interwiki-map schema) href 1 *ignorecase*))))))
    doc)


(defn include-sources [doc pagename]
  ; searches for `pre` tags with a `src` attribute
  (for [tag (.xpath doc "//pre[@src]")]
    (let [[filename (get tag.attrib "src")]]
        (try 
            (let [[buffer (.read (open-asset pagename filename))]]
                (setv tag.text buffer))
            (catch [e Exception]
                (.replace (.getparent tag) tag
                     (fromstring (inline-message "error" (% "Could not open file '%s'" (basename filename)))))))))
   doc)


(defn syntax-highlight [doc]
  ; searches for `pre` tags with a `syntax` attribute
  (for [tag (.xpath doc "//pre[@syntax]")]
      (let [[syntax (get tag.attrib "syntax")]
            [lexer  (apply get-lexer-by-name [syntax] {"stripall" true})]
            [formatter (apply HtmlFormatter [] {"cssclass" "highlight"})]]
          (if tag.text
              (.replace (.getparent tag) tag
                  (fromstring (highlight tag.text lexer formatter))))))
  doc)


(defn image-sources [doc pagename]
  ; searches for `img` tags with a `src` attribute and gives them an absolute URL path
  (for [tag (.xpath doc "//img[@src]")]
    (let [[src    (get tag.attrib "src")]
          [schema (get (urlsplit src) 0)]]
        (if (= "" schema)
            (assoc tag.attrib "src" (join *page-media-base* pagename src)))))
   doc) 


; TODO: include, interwiki links, alias replacements, all the "legacy" Yaki handling

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
        (interwiki-links)
        (include-sources pagename)
        (syntax-highlight)
        (image-sources pagename)
        (inner-html)))


(defn extract-plaintext [html pagename]
    ; remember that Hy's threading macro manipulates the first argument slot
    (-> html 
        (HTML)
        (compact-plaintext)))
