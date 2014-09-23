(import [os [walk environ]]
        [os.path [dirname exists join getmtime]]
        [datetime [datetime]]
        [time [time]]
        [models [create-db add-entry]]
        [xml.etree [cElementTree]]
        [bs4 [BeautifulSoup]]
        [hashlib [sha1]]
        [PIL [Image]]
        [StringIO [StringIO]]
        [functools [partial]])

; this is an OPF indexer I've written previously and that needs some tweaking to be fully integrated. WIP!


(defmacro timeit [block]
    `(let [[t (time)]]
        ~block
        (print (- (time) t))))


(def thumbnail-size (, 128 128))


(defn get-thumbnail ([path]
    ; generate a smaller thumbnail from an image
     (if (exists) path
            (let [[im (.open Image path)]
                  [buffer (StringIO)]]
                (.thumbnail im thumbnail-size Image.ANTIALIAS)
                (apply .save [im buffer "JPEG"] {"quality"     (int 75)
                                                 "optimize"    true
                                                 "progressive" true})
                (.close im)
                (.getvalue buffer)))))


(defn add-one [fields]
    (apply add-entry [] fields)) 


(create-db)
(timeit
    (for [f (gen-metadata (join (get environ "HOME") "Dropbox/Calibre"))]
        (print f)
        (let [[fields (parse-one f)]]
            (add-one fields))))
