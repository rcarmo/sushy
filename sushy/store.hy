; Find, retrieve and parse raw page markup
(import 
    [codecs  [open]]
    [config  [*base-filenames* *base-types* *ignored-folders* *store-path*]]
    [logging [getLogger]]
    [os      [walk stat]]
    [os.path [join exists splitext]]
    [stat    [ST_MTIME]])

(setv log (getLogger --name--))


(defn strip-seq [string-sequence]
    ; strip whitespace from a sequence of strings
    (map (fn [buffer] (.strip buffer)) string-sequence))
    

(defn split-header-line [string]
    ; parse a header line from front matter
    (if (.startswith "---" string) ; handle Jekyll-style front matter delimiters
       ["jekyll" "true"]
       (let [[parts (list (strip-seq (.split string ":" 1)))]]
          [(.lower (get parts 0)) (get parts 1)])))
            

(defn parse-page [buffer &optional [content-type "text/plain"]]
    ; parse a page and return a header map and the raw markup
    (try 
        (let [[parts        (.split buffer "\n\n" 1)]
              [header-lines (.splitlines (get parts 0))]
              [headers      (dict (map split-header-line header-lines))]
              [body         (.strip (get parts 1))]]
              (if (not (in "content-type" headers))
                (assoc headers "content-type" content-type))
              {:headers headers
               :body    body})
        (catch [e Exception]
            (.exception log "Could not parse page")
            (throw (IOError "Invalid Page Format.")))))


(defn asset-path [pagename asset]
    (join *store-path* pagename asset))


(defn asset-exists? [pagename asset]
    (exists (asset-path pagename asset)))


(defn open-asset [pagename asset]
    ; open a page asset/attachment
    (let [[filename (asset-path pagename asset)]]
        (open filename "rb")))


(defn is-page? [path]
    ; test if a given path contains an index filename
    (if (len (list (filter (fn [item] (exists (join path item))) *base-filenames*)))
        true
        false))


(defn get-page [pagename]
    ; return the raw data for a page 
    (.debug log (join *store-path* pagename))
    (let [[path         (join *store-path* pagename)]
          [page         (.next (filter (fn [item] (exists (join path item))) *base-filenames*))]
          [filename     (join *store-path* pagename page)]
          [content-type (get *base-types* (get (splitext page) 1))]]
        (parse-page
          (.read
            (apply open [filename] {"mode" "r" "encoding" "utf-8"})) content-type)))


(defn filtered-names [folder-list]
    ; remove ignored folders from a list
    (filter (fn [folder-name] (not (in folder-name *ignored-folders*))) folder-list))


(defn scan-pages [root-path]
    ; gather all existing pages
    (let [[pages {}]]
        (reduce
            (fn [item]
                (assoc pages (:path item) item))
            (gen-pages root-path))
        pages))


(defn walk-folders [root-path]
    ; generate a sequence of folder data
    (for [(, folder subfolders files) (walk root-path)]
        ; setting this helps guide os.path.walk()
        (setv subfolders (filtered-names subfolders))
        (yield {:path folder
                :files files})))


(defn with-index [folder-seq root-path]
    ; takes a sequence of folders and returns page info
    (for [folder folder-seq]
        (for [base *base-filenames*]
            (if (in base (:files folder))
                (yield
                    {:path     (slice (:path folder) (+ 1 (len root-path)))
                     :filename base
                     :mtime    (get (stat (join (:path folder) base)) ST_MTIME)})))))


(defn gen-pages [root-path]
    ; generate a lazy sequence of pages
    (-> root-path
        (walk-folders)
        (with-index root-path)))
