; Handle legacy Yaki plugin tags
(import
    [config     [*layout-hash* *thumb-media-base*]]
    [models     [search]]
    [logging    [getLogger]]
    [lxml.etree [fromstring tostring]]
    [messages   [inline-message inline-table]]
    [utils      [compute-hmac memoize get-image-size]])

(setv log (getLogger))

(defn plugin-tagged
    ; searches for `plugin` tags named `tagged`
    [doc]
    (for [tag (.xpath doc "//plugin[contains(@name,'tagged')]")]
        (let [[tagname (get tag.attrib "src")]]
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
        (let [[value (int (get tag.attrib "value"))]]
            (.replace (.getparent tag) tag
                (fromstring (% "<span itemprop=\"ratingValue\" class=\"rating\">%s</span>" (* "&#9733;" value))))))
    doc)
    

(defn plugin-quicklook
    ; searches for `plugin` tags named `quicklook`
    [doc pagename &optional [x 320] [y 240]]
    (for [tag (.xpath doc "//plugin[contains(@name,'quicklook')]")]
        (let [[src  (get tag.attrib "src")]
              [path (.join "/" [pagename src])]]
            (.replace (.getparent tag) tag
                (fromstring (% "<img class=\"quicklook\" width=\"%d\" height=\"%d\" src=\"%s/%d,%d/%s\"/>" (, x y *thumb-media-base* x y path))))))
    doc)