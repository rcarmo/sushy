(import 
    .config    [ALIASING_CHARS ALIAS_PAGE]
    .models    [get-all]
    .transform [get-mappings]
    os.path    [basename]
    re         [compile match]
    slugify    [slugify]
    functools  [lru-cache cache])

(setv DIGITS_ONLY (compile "^([0-9]+)$"))

(defn [cache]
    get-alias-map []
        ; build an alias -> page map for all possible aliases
        (let [alias-map (dict (get-mappings ALIAS_PAGE))
              pages     (get-all)]
            (for [p pages]
                (let [page  (.get p "name" "/")
                      base  (.lower (basename page))
                      title (.get p "title" "Untitled")
                      slug  (slugify title)]
                    (when (not (.match DIGITS_ONLY base))
                        (do 
                            (assoc alias-map base page)
                            (for [char ALIASING_CHARS]
                                (assoc alias-map
                                    (.replace base " " char) page
                                    (.replace page " " char) page))
                            (for [char ALIASING_CHARS]
                                (assoc alias-map
                                    (.replace slug "-" char) page
                                    (.replace title " " char) page))))))
            alias-map))


(defn [(lru-cache)]
    get-best-match [name]
        ; return the best possible match for a page name
        ; - fallback to a custom database search if not found
        (let [alias (.strip (.lower name))
              base (basename alias)
              alias-map (get-alias-map)]
            (if (in alias alias-map)
                (get alias-map alias)
                (if (in base alias-map)
                    (get alias-map base)
                    name))))
