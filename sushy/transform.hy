; Perform HTML transforms
(import
    .config             [*alias-page* *asset-hash* *interwiki-page* *lazyload-images* *max-image-size* *min-image-size* *page-media-base* *page-route-base* *scaled-media-base* *signed-prefixes*]
    .messages           [inline-message]
    .plugins            [plugin-tagged plugin-quicklook plugin-rating]
    .store              [asset-exists? asset-path get-page page-exists? open-asset]
    .render             [render-page]
    .utils              [compute-hmac memoize get-image-size]
    html                [escape]
    logging             [getLogger]
    lxml.etree          [ElementTree HTML fromstring tostring]
    os.path             [basename join normpath split]
    pygments            [highlight]
    pygments.lexers     [get-lexer-by-name]
    pygments.formatters [HtmlFormatter]
    re                  [IGNORECASE :as *ignorecase* sub]
    urllib.parse        [urlsplit])

(require hyrule.argmove [->])

(setv log (getLogger))

(defn get-mappings
    ; searches for `pre` tags and builds key/value pairs
    [page]
    (if (not (page-exists? page))
        {}
        (let [mappings {}
              doc (HTML (render-page (get-page page)))]
            (for [tag (.xpath doc "//pre")]
                (let [lines (.splitlines tag.text)
                      pairs (map (fn [x] (.split x)) lines)]
                    (for [pair pairs]
                        (when (= 2 (len pair))
                            (setv (get mappings (.lower (get pair 0))) (get pair 1))))))
            mappings)))


(defn get-plaintext-lines [page]
    (if (not (page-exists? page))
        []
        (let [result []
              doc (HTML (render-page (get-page page)))]
            (for [tag (.xpath doc "//pre")]
                (let [lines (list (map (fn [x] (.strip x)) (.splitlines tag.text)))]
                    (.extend result lines)))
            result)))


(setv *interwiki-map* (get-mappings *interwiki-page*))
(setv *alias-map* (get-mappings *alias-page*))


(defn expand-link-group [items]
    (let [group []]
        (for [item items]
            (when (len item)
                (let [url (.strip (get item 0))
                      schema (.lower (get (.split url ":" 1) 0))
                      label (.join " " (slice item 1))]
                    (when (not (len schema))
                        (when (!= (get url 0) "/")
                            (setv url (join *page-route-base* url))))
                    (when (in schema *interwiki-map*)
                        (if (in "%s" (get *interwiki-map* schema))
                            (setv url (% (get *interwiki-map* schema) url))
                            (setv url (sub (+ schema ":") (get *interwiki-map* schema) url 1 *ignorecase*))))
                    (.append group #(url label)))))
     group))
     



(defn get-link-groups
    ; searches for `pre` tags and builds sets of ordered pairs
    [page]
    (if (not (page-exists? page))
        {}
        (let [mappings {}
              doc (HTML (render-page (get-page page)))]
            (for [tag (.xpath doc "//pre")]
                (let [key (.get tag.attrib "id" "_")
                      lines (.splitlines tag.text)
                      items (map (fn [x] (.split x)) lines)]
                    (setv (get mappings key) (expand-link-group items))))                                
         mappings)))


(defn base-href
    ; inserts the base path into hrefs
    ; TODO: deprecate cid on direct links to existing assets
    [doc pagename]
    (for [a (.xpath doc "//a[@href]")]
        (let [href (get a.attrib "href")
              schema (get (.split href ":" 1) 0)]
            (when (= (get href 0) "#")
                (setv (get a.attrib "href") (+ (join *page-route-base* pagename) href))
                (if (= href schema)
                    (setv (get a.attrib "href") (join *page-route-base* href))
                    (when (= "cid" schema)
                        (setv (get a.attrib "href") (join *page-media-base* pagename (.replace href (+ schema ":") ""))))))))
    doc)


(defn interwiki-links
    ; replaces interwiki hrefs
    [doc]
    (for [a (.xpath doc "//a[@href]")]
        (let [href   (get a.attrib "href")
              parts  (.split href ":" 1)
              schema (.lower (get parts 0))]
            (when (and (in schema *interwiki-map*) (> (len parts) 1))
                (if (in "%s" (get *interwiki-map* schema))
                    (setv (get a.attrib "href") (% (get *interwiki-map* schema) (get parts 1)))
                    (setv (get a.attrib "href") (sub (+ schema ":") (get *interwiki-map* schema) href 1 *ignorecase*))))))
    doc)    


(defn alias-links
    ; replaces aliases
    [doc]
    (for [a (.xpath doc "//a[@href]")]
         (let [href (.lower (get a.attrib "href"))]
             (while (in href *alias-map*)
                 (setv href (get *alias-map* href))
                 (setv (get a.attrib "href") href))))
    doc)


(defn include-sources
    ; searches for `pre` tags with a `src` attribute
    [doc pagename]
    (for [tag (.xpath doc "//pre[@src]")]
        (let [filename (get tag.attrib "src")]
            (try
                (let [buffer (.read (open-asset pagename filename))]
                    (setv tag.text buffer))
                (catch [e Exception]
                    (.replace (.getparent tag) tag
                        (fromstring (inline-message "error" (% "Could not open file '%s'" (basename filename)))))))))
    doc)


(defn syntax-highlight
    ; searches for `pre` tags with a `syntax` attribute
    [doc]
    (for [tag (.xpath doc "//pre[@syntax]")]
        (let [syntax (get tag.attrib "syntax")
              lexer  (apply get-lexer-by-name [syntax] {"stripall" true})
              formatter (HtmlFormatter :cssclass "highlight")]
            (when tag.text
                (.replace (.getparent tag) tag
                    (fromstring (highlight tag.text lexer formatter))))))
    doc)


(defn count-images
    ; counts image and picture tags
    [doc]
    (+ (len (list (.xpath doc "//img[@src]"))) (len (list (.xpath doc "//figure")))))


(defn prepend-asset-sources
    ; prepend a prefix to image 'src' attributes, for feed generation
    [doc prefix]
    (for [tag (.xpath doc "//img[@src]")]
        (setv (get (. tag attrib) "src") (+ prefix (get (. tag attrib) "src"))))
    doc)


(defn remove-preloads
    ; Serve best possible preloaded assets to feed readers
    [doc]
    (for [tag (.xpath doc "//img[@data-src]")]
        (setv (get (. tag attrib) "src") (get (. tag attrib) "data-src")))
    (for [tag (.xpath doc "//img[@data-src-retina]")]
        (setv (get (. tag attrib) "src") (get (. tag attrib) "data-src-retina")))
    doc)


(defn image-sources
    ; searches for `img` tags with a `src` attribute and gives them an absolute URL path
    [doc pagename]
    (for [tag (.xpath doc "//img[@src]")]
        (let [src    (normpath (get (. tag attrib) "src"))
              schema (get (urlsplit src) 0)]
            ; if this is a local image
            (when (= "" schema)
                ; and we can actually find it on disk
                (if (asset-exists? pagename src)
                    ; ...but nobody bothered to specify the size
                    (when (not (in "width" (. tag attrib)))
                        ; ...get it from the image file
                        (let [size (get-image-size (asset-path pagename src))
                              accessor (. tag attrib)]
                            (if size
                                (do
                                    (.warn log size)
                                    (.warn log accessor)
                                    (setv (get (. tag attrib) "width") (str (get size 0)))
                                    (setv (get (. tag attrib) "height") (str (get size 1))))
                                (.replace (.getparent tag) tag
                                    (fromstring (inline-message "error" (% "Could not read size from '%s'" src)))))))
                    (.replace (.getparent tag) tag
                        (fromstring (inline-message "error" (% "Could not find image '%s'" src))))))
            (when (not (= "data" schema)) 
                (setv (get (. tag attrib) "src") (join *page-media-base* pagename src)))))
    doc)


(defn image-lazyload
    ; goes through image tags and decides whether to generate lazy-loading and retina downsampling
    [doc]
    (when *lazyload-images*
        (for [tag (.xpath doc "//img[@src]")]
            (let [src      (get (. tag attrib) "src")
                  base-src (sub (+ "^" *page-media-base*) "" src)
                  width    (int (.get (. tag attrib) "width" 0))
                  height   (int (.get (. tag attrib) "height" 0))
                  cls      (get (. tag attrib) "class" "")
                  retina   (get (. tag attrib) "data-src-retina" nil)
                  schema   (get (urlsplit src) 0)]
                ; if it's a local image of known size
                (when (and width height (= "" schema) (!= "data" schema))
                    (if (and (> height *max-image-size*) (> width *max-image-size*))
                        (let [new-width       *max-image-size*
                              new-height      (int (/ (* height *max-image-size*) width))
                              min-width       (max *min-image-size* (/ new-width 4))
                              min-height      (max *min-image-size* (/ new-height 4))
                              new-cls         (if-not (in "lazyload" cls) (+ cls " lazyload") cls)
                              new-src         (% "%s/%d,%d,blur%s" (, *scaled-media-base* min-width min-height base-src))
                              data-src        (% "%s/%d,%d%s" (, *scaled-media-base* new-width new-height base-src))
                              data-src-retina (if-not retina src retina)]
                            (setv (get (. tag attrib) "height") (str new-height))
                            (setv (get (. tag attrib) "width") (str new-width))
                            (setv (get (. tag attrib) "class") new-cls)
                            (setv (get (. tag attrib) "src") new-src)
                            (setv (get (. tag attrib) "data-src") data-src)
                            (setv (get (. tag attrib) "data-src-retina") data-src-retina))
                        (let [min-width       (max *min-image-size* (/ width 4))
                              min-height      (max *min-image-size* (/ height 4))
                              new-cls         (if-not (in "lazyload" cls) (+ cls " lazyload") cls)
                              new-src         (% "%s/%d,%d,blur%s" (, *scaled-media-base* min-width min-height base-src))
                              data-src        src]
                            (setv (get (. tag attrib) "class") new-cls)
                            (setv (get (. tag attrib) "src") new-src)
                            (setv (get (. tag attrib) "data-src") data-src)))))))
    doc)


; TODO: include, interwiki links, all the "legacy" Yaki handling

(defn inner-html
    ; Returns the content of a doc without extraneous tags
    [doc]
    (let [body (get (.xpath doc "//body") 0)
          children []]
        (for [child (.iterchildren body)]
            (.append children (tostring child)))
        (.join "" children)))


(defn extract-plaintext
    ; Returns a compacted version of the plaintext without duplicate whitespace and with converted entities (lxml's default)
    [doc]
    (let [body (get (.xpath doc "//body") 0)
          children []]
        (for [child (.iterchildren body)]
            (.append children (tostring child :method "text" :encoding "unicode")))
        (escape (.join " " (.split (.join "" children))))))


(defn extract-internal-links
    ; Returns a list of internal links
    [doc]
    (list (set (map
                (fn [tag]
                    (get (get tag.attrib "href") (slice (+ 1 (len *page-route-base*)) None)))
                (.xpath doc (+ "//a[starts-with(@href,'" *page-route-base* "')]"))))))


(defn mark-lead-paragraph
    ; sets the "lead" class on the first non-empty paragraph tag
    [doc]
    (for [tag (.xpath doc ".//p")]
        (when (len (.strip (tostring tag :method "text" :encoding "unicode")))
            (do
                (setv (get (. tag attrib) "class") "lead")
                (break))))
    doc)


(defn extract-lead-paragraph
    ; returns the lead paragraph of a page
    [page pagename]
    (let [doc            (apply-transforms (render-page page) pagename)
          lead-paragraph (get (.xpath doc ".//p[@class='lead']") 0)]
        (tostring lead-paragraph)))


(defn fix-footnotes
    ; fix footnotes for iOS devices
    [buffer]
    (.replace buffer "&#8617;" "&#8617;&#xFE0E;"))


(defn sign-assets
    ; add an HMAC signature to asset pathnames
    [doc]
    (for [attrib-name ["src" "data-src" "data-src-retina"]]
        (for [tag (.xpath doc (% "//img[@%s]" attrib-name))]
            (try
                (let [src              (get (. tag attrib) attrib-name)
                      #(_ prefix path) (map (fn [p] (+ "/" p)) (.split src "/" 2))
                      schema           (get (urlsplit src) 0)]
                    (when (not (= "data" schema))
                        (when (in prefix *signed-prefixes*)
                            (setv (get tag.attrib attrib-name) (+ prefix "/" (compute-hmac *asset-hash* prefix path) path)))))
                (except [e ValueError]))))
    (for [tag (.xpath doc "//a[@href]")]
        (try
            (let [href             (get (. tag attrib) "href")
                  #(_ prefix path) (map (fn [p] (+ "/" p)) (.split href "/" 2))]
                (when (in prefix *signed-prefixes*)
                    (setv (get tag.attrib "href") (+ prefix "/" (compute-hmac *asset-hash* prefix path) path))))
            (except [e ValueError])))
    doc)



(defn apply-transforms [html pagename]
    ; remember that Hy's threading macro manipulates the first argument slot
    (-> html
        (fix-footnotes)
        (HTML)
        (mark-lead-paragraph)
        (alias-links)
        (interwiki-links)
        (base-href pagename)
        (include-sources pagename)
        (image-sources pagename)
        (image-lazyload)
        (syntax-highlight)
        (plugin-tagged)
        (plugin-rating)
        (plugin-quicklook pagename)
        (sign-assets)))
