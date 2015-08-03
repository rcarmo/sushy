; Handle legacy Yaki plugin tags
(import
    [models     [search]]
    [logging    [getLogger]]
    [lxml.etree [fromstring tostring]]
    [messages   [inline-message inline-table]]
    [utils      [memoize get-image-size]])

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