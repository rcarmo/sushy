; Perform HTML transforms
(import
    [cgi                 [escape]]
    [config              [*alias-page* *interwiki-page* *layout-hash* *page-media-base* *page-route-base* *signed-prefixes*]]
    [logging             [getLogger]]
    [lxml.etree          [ElementTree HTML fromstring tostring]]
    [messages            [inline-message]]
    [os.path             [basename join normpath split]]
    [plugins             [plugin-tagged plugin-quicklook plugin-rating]]
    [pygments            [highlight]]
    [pygments.lexers     [get-lexer-by-name]]
    [pygments.formatters [HtmlFormatter]]
    [re                  [*ignorecase* sub]]
    [store               [asset-exists? asset-path get-page open-asset]]
    [render              [render-page]]
    [utils               [compute-hmac memoize get-image-size]]
    [urlparse            [urlsplit]])

(setv log (getLogger))


(with-decorator (memoize)
    (defn get-mappings
        ; searches for `pre` tags and builds key/value pairs
        [page]
        (let [[mappings {}]
            [doc (HTML (render-page (get-page page)))]]
            (for [tag (.xpath doc "//pre")]
                (let [[lines (.splitlines tag.text)]
                    [pairs (map (fn [x] (.split x)) lines)]]
                    (for [pair pairs]
                        (if (= 2  (len pair))
                            (assoc mappings (.lower (get pair 0)) (get pair 1))))))
            mappings)))


(defn base-href
    ; inserts the base path into hrefs
    [doc pagename]
    (for [a (.xpath doc "//a[@href]")]
        (let [[href (get a.attrib "href")]
              [schema (get (.split href ":" 1) 0)]]
            (if (= (get href 0) "#")
                (assoc a.attrib "href" (+ (join *page-route-base* pagename) href))
                (if (= href schema)
                    (assoc a.attrib "href" (join *page-route-base* href))))))
    doc)


(defn interwiki-links
    ; replaces interwiki hrefs
    [doc]
    (let [[interwiki-map (get-mappings *interwiki-page*)]]
        (for [a (.xpath doc "//a[@href]")]
            (let [[href   (get a.attrib "href")]
                  [parts  (.split href ":" 1)]
                  [schema (.lower (get parts 0))]]
                (if (and (in schema interwiki-map) (> (len parts) 1))
                    (if (in "%s" (get interwiki-map schema))
                        (assoc a.attrib "href" (% (get interwiki-map schema) (get parts 1)))
                        (assoc a.attrib "href" (sub (+ schema ":") (get interwiki-map schema) href 1 *ignorecase*)))))))
    doc)


(defn alias-links
    ; replaces aliases
    [doc]
    (let [[alias-map (get-mappings *alias-page*)]]
        (for [a (.xpath doc "//a[@href]")]
            (let [[href (.lower (get a.attrib "href"))]]
                (while (in href alias-map)
                    (setv href (get alias-map href))
                    (assoc a.attrib "href" href)))))
    doc)


(defn include-sources
    ; searches for `pre` tags with a `src` attribute
    [doc pagename]
    (for [tag (.xpath doc "//pre[@src]")]
        (let [[filename (get tag.attrib "src")]]
            (try
                (let [[buffer (.read (open-asset pagename filename))]]
                    (setv tag.text buffer))
                (catch [e Exception]
                    (.replace (.getparent tag) tag
                        (fromstring (inline-message "error" (% "Could not open file '%s'" (basename filename)))))))))
    doc)


(defn syntax-highlight
    ; searches for `pre` tags with a `syntax` attribute
    [doc]
    (for [tag (.xpath doc "//pre[@syntax]")]
        (let [[syntax (get tag.attrib "syntax")]
              [lexer  (apply get-lexer-by-name [syntax] {"stripall" true})]
              [formatter (apply HtmlFormatter [] {"cssclass" "highlight"})]]
            (if tag.text
                (.replace (.getparent tag) tag
                    (fromstring (highlight tag.text lexer formatter))))))
    doc)


(defn image-sources
    ; searches for `img` tags with a `src` attribute and gives them an absolute URL path
    [doc pagename]
    (for [tag (.xpath doc "//img[@src]")]
        (let [[src    (normpath (get (. tag attrib) "src"))]
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

(defn inner-html
    ; Returns the content of a doc without extraneous tags
    [doc]
    (let [[body (get (.xpath doc "//body") 0)]
          [children []]]
        (for [child (.iterchildren body)]
            (.append children (tostring child)))
        (.join "" children)))


(defn extract-plaintext
    ; Returns a compacted version of the plaintext without duplicate whitespace and with converted entities (lxml's default)
    [doc]
    (let [[body (get (.xpath doc "//body") 0)]
        [children []]]
        (for [child (.iterchildren body)]
            (.append children (apply tostring [child] {"method" "text" "encoding" "unicode"})))
        (escape (.join " " (.split (.join "" children))))))


(defn extract-internal-links
    ; Returns a list of internal links
    [doc]
    (list (set (map
        (fn [tag]
            (slice (get tag.attrib "href") (+ 1 (len *page-route-base*))))
        (.xpath doc (+ "//a[starts-with(@href,'" *page-route-base* "')]"))))))


(defn make-lead-paragraph
    ; sets the "lead" class on the first paragraph tag
    [doc]
    (for [tag (.xpath doc ".//p")]
        (if (len (.strip (apply tostring [tag] {"method" "text" "encoding" "unicode"})))
            (do
                (assoc (. tag attrib) "class" "lead")
                (break))))
    doc)


(defn extract-lead-paragraph
    ; returns the lead paragraph of a page
    [page]
    (let [[doc            (apply-transforms (render-page page))]
          [lead-paragraph (.xpath doc ".//pi[1]")]]
        (inner-html lead-paragraph)))


(defn fix-footnotes
    ; fix footnotes for iOS devices
    [buffer]
    (.replace buffer "&#8617;" "&#8617;&#xFE0E;"))


(defn sign-assets
    ; add an HMAC signature to asset pathnames
    [doc]
    (for [tag (.xpath doc "//img[@src]")]
        (try
            (let [[src             (get (. tag attrib) "src")]
                  [(, _ prefix path) (map (fn [p] (+ "/" p)) (.split src "/" 2))]]
                (if (in prefix *signed-prefixes*)
                    (assoc tag.attrib "src" (+ prefix "/" (compute-hmac *layout-hash* prefix path) path))))
            (except [e ValueError])))
    (for [tag (.xpath doc "//a[@href]")]
        (try
            (let [[href              (get (. tag attrib) "href")]
                  [(, _ prefix path) (map (fn [p] (+ "/" p)) (.split href "/" 2))]]
                (if (in prefix *signed-prefixes*)
                    (assoc tag.attrib "href" (+ prefix "/" (compute-hmac *layout-hash* prefix path) path))))
            (except [e ValueError])))
    doc)



(defn apply-transforms [html pagename]
    ; remember that Hy's threading macro manipulates the first argument slot
    (-> html
        (fix-footnotes)
        (HTML)
        (make-lead-paragraph)
        (alias-links)
        (interwiki-links)
        (base-href pagename)
        (include-sources pagename)
        (image-sources pagename)
        (syntax-highlight)
        (plugin-tagged)
        (plugin-rating)
        (plugin-quicklook pagename)
        (sign-assets)))
