(import 
        [models [create-db add-entry]]
        [store  [gen-pages]])


(setv log (getLogger))

(defn add-one [fields]
    (apply add-entry [] fields)) 


(create-db)
(timeit
    (for [f (gen-metadata (join (get environ "HOME") "Dropbox/Calibre"))]
        (print f)
        (let [[fields (parse-one f)]]
            (add-one fields))))
