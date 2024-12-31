; Handle legacy Yaki plugin tags
(import
    .config    [SCALED_MEDIA_BASE]
    .messages  [inline-message inline-table]
    .models    [search]
    .utils     [compute-hmac memoize get-image-size]
    logging    [getLogger]
    lxml.etree [fromstring tostring])

(setv log (getLogger __name__))

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
    [doc pagename [x 320] [y 240]]
    (for [tag (.xpath doc "//plugin[contains(@name,'quicklook')]")]
        (let [src  (get tag.attrib "src")
              path (.join "/" [pagename src])]
            (.replace (.getparent tag) tag
                (fromstring f"<img class=\"quicklook lazyload\" width=\"{x}\" height=\"{y}\" src=\"{SCALED_MEDIA_BASE}/40,30,blur/{path}\" data-src=\"{SCALED_MEDIA_BASE}/{x},{y}/{path}\" data-src-retina=\"{SCALED_MEDIA_BASE}/{(* 2 x)},{(* 2 y)}/{path}\"/>"))))
    doc)
