; Perform HTML transforms
(import
    [config              [*interwiki-page* *page-media-base* *page-route-base*]]
    [logging             [getLogger]]
    [lxml.etree          [ElementTree HTML fromstring tostring]]
    [messages            [inline-message]]
    [os.path             [basename join]]
    [pygments            [highlight]]
    [pygments.lexers     [get-lexer-by-name]]
    [pygments.formatters [HtmlFormatter]]
    [re                  [*ignorecase* sub]]
    [store               [asset-exists? asset-path get-page open-asset]]
    [render              [render-page]]
    [utils               [memoize get-image-size]]
    [urlparse            [urlsplit]])

(setv log (getLogger))


(with-decorator (memoize)
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
        (let [[src    (get (. tag attrib) "src")]
              [schema (get (urlsplit src) 0)]]
            ; if this is a local image
            (if (= "" schema)
                ; and we can actually find it on disk
                (if (asset-exists? pagename src)
                    ; ...but nobody bothered to specify the size
                    (if (not (in "width" (. tag attrib)))
                        ; ...get it from the image file
                        (let [[size (get-image-size (asset-path pagename src))]]
                            (if size 
                                (do
                                    (assoc (. tag attrib) "width" (str (get size 0)))
                                    (assoc (. tag attrib) "height" (str (get size 1))))
                                (.replace (.getparent tag) tag
                                    (fromstring (inline-message "error" (% "Could not read size from '%s'" src)))))))
                    (.replace (.getparent tag) tag
                        (fromstring (inline-message "error" (% "Could not find image '%s'" src))))))
            (assoc (. tag attrib) "src" (join *page-media-base* pagename src))))
    doc) 


; TODO: include, interwiki links, alias replacements, all the "legacy" Yaki handling

(defn inner-html [doc]
    ; Returns the content of a doc without extraneous tags
    (let [[body (get (.xpath doc "//body") 0)]
          [children []]]
        (for [child (.iterchildren body)]
            (.append children (tostring child)))
        (.join "" children)))


(defn extract-plaintext [doc]
    ; Returns a compacted version of the plaintext without duplicate whitespace and with converted entities (lxml's default)
    (let [[body (get (.xpath doc "//body") 0)]
        [children []]]
        (for [child (.iterchildren body)]
            (.append children (apply tostring [child] {"method" "text" "encoding" "unicode"})))
        (.join " " (.split (.join "" children)))))


(defn extract-internal-links [doc]
    ; Returns a list of internal links
    (map 
        (fn [tag] 
            (slice (get tag.attrib "href") (+ 1 (len *page-route-base*))))
        (.xpath doc (+ "//a[starts-with(@href,'" *page-route-base* "')]"))))


(defn apply-transforms [html pagename]
    ; remember that Hy's threading macro manipulates the first argument slot
    (-> html 
        (HTML)
        (base-href pagename)
        (interwiki-links)
        (include-sources pagename)
        (syntax-highlight)
        (image-sources pagename)))