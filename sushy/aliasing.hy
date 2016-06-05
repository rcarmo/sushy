(import 
    [config    [*aliasing-chars* *alias-page*]]
    [models    [get-all]]
    [os.path   [basename]]
    [transform [get-mappings]]
    [re        [compile match]]
    [slugify   [slugify]]
    [utils     [lru-cache memoize]])

(def *digits-only* (compile "^([0-9]+)$"))

(with-decorator (memoize)
    (defn get-alias-map []
        ; build an alias -> page map for all possible aliases
        (let [[alias-map (dict (get-mappings *alias-page*))]
              [pages     (get-all)]]
            (for [p pages]
                (let [[page  (.get p "name" "/")]
                      [base  (.lower (basename page))]
                      [title (.get p "title" "Untitled")]
                      [slug  (slugify title)]]
                    (if (not (.match *digits-only* base))
                        (do 
                            (assoc alias-map base page)
                            (for [char *aliasing-chars*]
                                (assoc alias-map
                                    (.replace base " " char) page
                                    (.replace page " " char) page))
                            (for [char *aliasing-chars*]
                                (assoc alias-map
                                    (.replace slug "-" char) page
                                    (.replace title " " char) page))))))
            alias-map)))


(with-decorator (lru-cache)
    (defn get-best-match [name]
        ; return the best possible match for a page name
        ; - fallback to a custom database search if not found
        (let [[alias (.strip (.lower name))]
              [base (basename alias)]
              [alias-map (get-alias-map)]]
            (if (in alias alias-map)
                (get alias-map alias)
                (if (in base alias-map)
                    (get alias-map base)
                    name)))))