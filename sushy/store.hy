; Find, retrieve and parse raw page markup

(import 
    codecs   [open]
    .config  [BASE_FILENAMES BASE_TYPES IGNORED_FOLDERS STORE_PATH TIMEZONE]
    datetime [datetime]
    logging  [getLogger]
    os       [walk]
    os.path  [join exists splitext getmtime]
    .utils   [utc-date])

(require hyrule.argmove [->])
(require hyrule.collections [assoc])

(setv log (getLogger __name__))


(defn strip-seq [string-sequence]
    ; strip whitespace from a sequence of strings
    (map (fn [buffer] (.strip buffer)) string-sequence))
    

(defn split-header-line [string]
    ; parse a header line from front matter
    (if (.startswith "---" string) ; handle Jekyll-style front matter delimiters
       ["jekyll" "true"]
       (let [parts (list (strip-seq (.split string ":" 1)))]
          [(.lower (get parts 0)) (get parts 1)])))
            

(defn parse-page [buffer [content-type "text/plain"]]
    ; parse a page and return a header map and the raw markup
    (.debug log buffer)
    (if (= content-type "application/x-ipynb+json")
        {"headers" {"from" "Unknown Author"
                   "title" "Untitled Notebook"
                   "content-type" content-type}
         "body"   buffer}
        (let [unix-buffer (.replace buffer "\r\n" "\n")]
            (try 
                (let [delimiter    "\n\n"
                      parts        (.split unix-buffer delimiter 1)
                      header-lines (.splitlines (get parts 0))
                      headers      (dict (map split-header-line header-lines))
                      body         (.strip (get parts 1))]
                    (when (not (in "from" headers))
                        (assoc headers "from" "Unknown Author"))
                    (when (not (in "content-type" headers))
                        (assoc headers "content-type" content-type))
                    {"headers" headers
                     "body"    body})
                (except [e Exception]
                    (.error log (, e "Could not parse page"))
                    (raise (RuntimeError "Could not parse page")))))))


(defn asset-path [pagename asset]
    (join STORE_PATH pagename asset))


(defn asset-exists? [pagename asset]
    (exists (asset-path pagename asset)))


(defn open-asset [pagename asset]
    ; open a page asset/attachment
    (let [filename (asset-path pagename asset)]
        (open filename "rb")))


(defn page-exists? [pagename]
    (is-page? (join STORE_PATH pagename)))


(defn is-page? [path]
    ; test if a given path contains an index filename
    (if (len (list (filter (fn [item] (exists (join path item))) BASE_FILENAMES)))
        True
        False))


(defn get-page [pagename]
    ; return the raw data for a page 
    (.debug log (join STORE_PATH pagename))
    (try
        (let [path         (join STORE_PATH pagename)
              page         (next (filter (fn [item] (exists (join path item))) BASE_FILENAMES))
              filename     (join STORE_PATH pagename page)
              content-type (get BASE_TYPES (get (splitext page) 1))
              handle       (open filename :mode "r" :encoding "utf-8")
              buffer       (.read handle)]
            (.close handle)
            (parse-page buffer content-type))
        (except [e StopIteration]
            (raise (IOError f"page not found {pagename}")))))


(defn filtered-names [folder-list]
    ; remove ignored folders from a list
    (filter (fn [folder-name] (not (in folder-name IGNORED_FOLDERS))) folder-list))


(defn scan-pages [root-path]
    ; gather all existing pages
    (let [pages {}]
        (reduce
            (fn [item]
                (assoc pages (:path item) item))
            (gen-pages root-path))
        pages))


(defn walk-folders [root-path]
    ; generate a sequence of folder data
    (for [#(folder subfolders files) (walk root-path)]
        ; setting this helps guide os.walk()
        (setv subfolders (filtered-names subfolders))        
        (yield {"path" folder
                "files" files})))


(defn with-index [folder-seq root-path]
    ; takes a sequence of folders and returns page info
    (for [folder folder-seq]
        (for [base BASE_FILENAMES]
            (when (in base (:files folder))
                (yield
                    {"path"     (get (:path folder) (slice (+ 1 (len root-path)) None))
                     "filename" base
                     "mtime"    (int (getmtime (join (:path folder) base)))})))))


(defn gen-pages [root-path]
    ; generate a lazy sequence of pages
    (-> root-path
        (walk-folders)
        (with-index root-path)))
