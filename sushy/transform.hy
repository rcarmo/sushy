; Perform HTML transforms
(import
    .config             [ALIAS_PAGE ASSET_HASH INTERWIKI_PAGE LAZYLOAD_IMAGES MAX_IMAGE_SIZE MIN_IMAGE_SIZE PAGE_MEDIA_BASE PAGE_ROUTE_BASE SCALED_MEDIA_BASE SIGNED_PREFIXES]
    .favicons           [download-favicon]
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
    re                  [IGNORECASE sub]
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


(setv INTERWIKI_MAP (get-mappings INTERWIKI_PAGE))
(setv ALIAS_MAP (get-mappings ALIAS_PAGE))


(defn expand-link-group [items]
    (let [group []]
        (for [item items]
            (when (len item)
                (let [url (.strip (get item 0))
                      schema (.lower (get (.split url ":" 1) 0))
                      label (.join " " (slice item 1))]
                    (when (not (len schema))
                        (when (!= (get url 0) "/")
                            (setv url (join PAGE_ROUTE_BASE url))))
                    (when (in schema INTERWIKI_MAP)
                        (if (in "%s" (get INTERWIKI_MAP schema))
                            (setv url (% (get INTERWIKI_MAP schema) url))
                            (setv url (sub (+ schema ":") (get INTERWIKI_MAP schema) url 1 IGNORECASE))))
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
                (setv (get a.attrib "href") (+ (join PAGE_ROUTE_BASE pagename) href))
                (if (= href schema)
                    (setv (get a.attrib "href") (join PAGE_ROUTE_BASE href))
                    (when (= "cid" schema)
                        (setv (get a.attrib "href") (join PAGE_MEDIA_BASE pagename (.replace href (+ schema ":") ""))))))))
    doc)


(defn interwiki-links
    ; replaces interwiki hrefs
    [doc]
    (for [a (.xpath doc "//a[@href]")]
        (let [href   (get a.attrib "href")
              parts  (.split href ":" 1)
              schema (.lower (get parts 0))]
            (when (and (in schema INTERWIKI_MAP) (> (len parts) 1))
                (if (in "%s" (get INTERWIKI_MAP schema))
                    (setv (get a.attrib "href") (% (get INTERWIKI_MAP schema) (get parts 1)))
                    (setv (get a.attrib "href") (sub (+ schema ":") (get INTERWIKI_MAP schema) href 1 IGNORECASE))))))
    doc)    


(defn alias-links
    ; replaces aliases
    [doc]
    (for [a (.xpath doc "//a[@href]")]
         (let [href (.lower (get a.attrib "href"))]
             (while (in href ALIAS_MAP)
                 (setv href (get ALIAS_MAP href))
                 (setv (get a.attrib "href") href))))
    doc)


(defn capture-favicons
    ; ensures we preload favicons from external sites. We purposely ignore port numbers and the like
    [doc]
    (for [a (.xpath doc "//a[starts-with(@href,'http')]")]
        (let [href (get a.attrib "href")
              parts (urlsplit href)
              schema (get parts 0)
              netloc (get parts 1)]
         (download-favicon f"{schema}://{netloc}")))
    doc)


(defn include-sources
    ; searches for `pre` tags with a `src` attribute
    [doc pagename]
    (for [tag (.xpath doc "//pre[@src]")]
        (let [filename (get tag.attrib "src")]
            (try
                (let [buffer (.read (open-asset pagename filename))]
                    (setv tag.text buffer))
                (except [e Exception]
                    (.replace (.getparent tag) tag
                        (fromstring (inline-message "error" (% "Could not open file '%s'" (basename filename)))))))))
    doc)


(defn syntax-highlight
    ; searches for `pre` tags with a `syntax` attribute
    [doc]
    (for [tag (.xpath doc "//pre[@syntax]")]
        (let [syntax (get tag.attrib "syntax")
              lexer  (get-lexer-by-name syntax :stripall True)
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
                                    (setv (get (. tag attrib) "width") (str (get size 0)))
                                    (setv (get (. tag attrib) "height") (str (get size 1))))
                                (.replace (.getparent tag) tag
                                    (fromstring (inline-message "error" (% "Could not read size from '%s'" src)))))))
                    (.replace (.getparent tag) tag
                        (fromstring (inline-message "error" (% "Could not find image '%s'" src))))))
            (when (not (= "data" schema)) 
                (setv (get (. tag attrib) "src") (join PAGE_MEDIA_BASE pagename src)))))
    doc)


(defn image-lazyload
    ; goes through image tags and decides whether to generate lazy-loading and retina downsampling
    [doc]
    (when LAZYLOAD_IMAGES
        (for [tag (.xpath doc "//img[@src]")]
            (let [src      (get (. tag attrib) "src")
                  base-src (sub (+ "^" PAGE_MEDIA_BASE) "" src)
                  width    (int (.get (. tag attrib) "width" 0))
                  height   (int (.get (. tag attrib) "height" 0))
                  cls      (get (. tag attrib) "class" "")
                  retina   (get (. tag attrib) "data-src-retina" nil)
                  schema   (get (urlsplit src) 0)]
                ; if it's a local image of known size
                (when (and width height (= "" schema) (!= "data" schema))
                    (if (and (> height MAX_IMAGE_SIZE) (> width MAX_IMAGE_SIZE))
                        (let [new-width       MAX_IMAGE_SIZE
                              new-height      (int (/ (* height MAX_IMAGE_SIZE) width))
                              min-width       (max MIN_IMAGE_SIZE (/ new-width 4))
                              min-height      (max MIN_IMAGE_SIZE (/ new-height 4))
                              new-cls         (if-not (in "lazyload" cls) (+ cls " lazyload") cls)
                              new-src         f"{SCALED_MEDIA_BASE}/{min-width},{min-height},blur{base-src}"
                              data-src        f"{SCALED_MEDIA_BASE}/{new-width},{new-height}{base-src}"
                              data-src-retina (if-not retina src retina)]
                            (setv (get (. tag attrib) "height") (str new-height))
                            (setv (get (. tag attrib) "width") (str new-width))
                            (setv (get (. tag attrib) "class") new-cls)
                            (setv (get (. tag attrib) "src") new-src)
                            (setv (get (. tag attrib) "data-src") data-src)
                            (setv (get (. tag attrib) "data-src-retina") data-src-retina))
                        (let [min-width       (max MIN_IMAGE_SIZE (/ width 4))
                              min-height      (max MIN_IMAGE_SIZE (/ height 4))
                              new-cls         (if-not (in "lazyload" cls) (+ cls " lazyload") cls)
                              new-src         f"{SCALED_MEDIA_BASE}/{min-width},{min-height},blur{base-src}"
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
            (.append children (tostring child :encoding "unicode")))
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
                    (get (get tag.attrib "href") (slice (+ 1 (len PAGE_ROUTE_BASE)) None)))
                (.xpath doc (+ "//a[starts-with(@href,'" PAGE_ROUTE_BASE "')]"))))))


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
        (tostring lead-paragraph :encoding "unicode")))


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
                        (when (in prefix SIGNED_PREFIXES)
                            (setv (get tag.attrib attrib-name) (+ prefix "/" (compute-hmac ASSET_HASH prefix path) path)))))
                (except [e ValueError]))))
    (for [tag (.xpath doc "//a[@href]")]
        (try
            (let [href             (get (. tag attrib) "href")
                  #(_ prefix path) (map (fn [p] (+ "/" p)) (.split href "/" 2))]
                (when (in prefix SIGNED_PREFIXES)
                    (setv (get tag.attrib "href") (+ prefix "/" (compute-hmac ASSET_HASH prefix path) path))))
            (except [e ValueError])))
    doc)


(defn blockquote-alerts
  ; placeholder for [!NOTE|TIP|IMPORTANT|WARNING|CAUTION] handling
  [doc]
  ; TODO: handle first paragraph inside a blockquote
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
        (blockquote-alerts)
        (capture-favicons)
        (sign-assets)))
