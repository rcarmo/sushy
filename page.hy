(import 
    [os [walk stat]]
    [os.path [join exists]]
    [stat [ST_MTIME]]
    [logging [getLogger]]
    [config [*ignored-folders* *base-filenames* *store-path*]])

(setv log (getLogger))

(defn strip-seq [string-sequence]
    (map (fn [buffer] (.strip buffer)) string-sequence))
    
(defn split-header-line [string]
    (let [[parts (strip-seq (.split string ":" 1))]]
        [(.lower (get parts 0)) (get parts 1)]))
            
(defn parse-page [buffer]
    ; parse a page and return a header map and the raw markup
    (try 
        (let [[parts        (.split buffer "\n\n" 1)]
              [header-lines (.split (get parts 0) "\n")]
              [headers      (dict (map split-header-line header-lines))]
              [body         (get parts 1)]]
              (if (not (in "content-type" headers))
                (assoc headers "content-type" "text/plain"))
              {"headers" headers
               "body"    body})
        (catch [e Exception]
            (.exception log "Could not parse page")
            (throw (IOError "Invalid Page Format.")))))


(defn get-page [name]
    (let [[path (join *store-path* name)]
          [page (.next (filter (fn [item] (exists (join path item))) *base-filenames*))]]
        (parse-page (.read (open (join *store-path* name page) "r")))))


(defn filtered-names [folder-list]
    (filter (fn [folder-name] (not (in folder-name *ignored-folders*))) folder-list))

(defn get-all-pages [root-path]
    (let [[pages {}]]
        (for [elements (walk root-path)]
            (let [[folder     (get elements 0)]
                  [subfolders (get elements 1)]
                  [files      (get elements 2)]]
                ; setting this helps guide os.path.walk()
                (setv subfolders (filtered-names subfolders))
                (for [base *base-filenames*]
                     (if (in base files)
                         (assoc pages
                             (slice folder (+ 1 (len root-path)))
                             (get (stat (join folder base)) ST_MTIME))))))
        pages))

