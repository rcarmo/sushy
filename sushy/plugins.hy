; Handle legacy Yaki plugin tags
(import
    .config    [*scaled-media-base*]
    .messages  [inline-message inline-table]
    .models    [search]
    .utils     [compute-hmac memoize get-image-size]
    logging    [getLogger]
    lxml.etree [fromstring tostring])

(setv log (getLogger))

(defn plugin-tagged
    ; searches for `plugin` tags named `tagged`
    [doc]
    (for [tag (.xpath doc "//plugin[contains(@name,'tagged')]")]
        (let [tagname (get tag.attrib "src")]
            (try
                (.replace (.getparent tag) tag
                    (fromstring (inline-table ["Page" "name" "Modified" "mtime"]
                                              (search (+ "tag:" tagname) -1))))
                (catch [e Exception]
                    (.replace (.getparent tag) tag
                        (fromstring (inline-message "error" (% "Could not list pages tagged with '%s'" tagname))))))))
    doc)
    

(defn plugin-rating
    ; searches for `plugin` tags named `rating`
    [doc]
    (for [tag (.xpath doc "//plugin[contains(@name,'rating')]")]
        (let [value (int (get tag.attrib "value"))]
            (.replace (.getparent tag) tag
                (fromstring (% "<span itemprop=\"ratingValue\" class=\"rating\">%s</span>" (* "&#9733;" value))))))
    doc)
    

(defn plugin-quicklook
    ; searches for `plugin` tags named `quicklook` and generates a rendering request for a 2x image
    [doc pagename &optional [x 320] [y 240]]
    (for [tag (.xpath doc "//plugin[contains(@name,'quicklook')]")]
        (let [src  (get tag.attrib "src")
              path (.join "/" [pagename src])]
            (.replace (.getparent tag) tag
                (fromstring (% "<img class=\"quicklook lazyload\" width=\"%d\" height=\"%d\" src=\"%s/40,30,blur/%s\" data-src=\"%s/%d,%d/%s\" data-src-retina=\"%s/%d,%d/%s\"/>" (, x y *scaled-media-base* path *scaled-media-base* x y path *scaled-media-base* (* 2 x) (* 2 y) path))))))
    doc)
