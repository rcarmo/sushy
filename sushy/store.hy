; Find, retrieve and parse raw page markup

(import 
    codecs   [open]
    .config  [BASE_FILENAMES BASE_TYPES IGNORED_FOLDERS STORE_PATH TIMEZONE]
    datetime [datetime]
    hyrule.collections [assoc]
    logging  [getLogger]
    os       [walk]
    os.path  [join exists splitext getmtime]
    .utils   [utc-date]
    re       [compile DOTALL]
    yaml     [safe-load]
    hyrule.collections [assoc])

(require hyrule.argmove [->])

(setv log (getLogger __name__))
(setv header-lines (compile r"^---\s*(.*?)\s*---|^(.*?)(?:\n\n|$)" DOTALL)); be tolerant of leading whitespace and missing markers

(defn strip-seq [string-sequence]
    ; strip whitespace from a sequence of strings
    (map (fn [buffer] (.strip buffer)) string-sequence))


(defn ensure-defaults [headers content-type]
    ; ensure that all required headers are present
  (let [defaults {"title" "Untitled"
                  "from" "Unknown Author"
                  "content-type" content-type}
        lheaders (dict (map (fn [i] [(.lower (get i 0)) (get i 1)]) (.items headers)))]
        {#** defaults #** lheaders}))


(defn parse-page [pagename buffer [content-type "text/plain"]]
    ; parse a page and return a header map and the raw markup
    (let [unix-buffer (.strip (.replace buffer "\r\n" "\n"))]
        (try
          (let [match        (.match header-lines unix-buffer)
                front-matter (if match
                               (if (.group match 1) (.group match 1) (.group match 2))
                               {})
                headers      (ensure-defaults (safe-load front-matter) content-type)
                body         (if match (cut unix-buffer (.end match) (len unix-buffer)) unix-buffer)]
            {"headers" headers
             "body"    body})
            (except [e Exception]
                (.error log f"Could not parse page {pagename}: {e}")
                (raise (RuntimeError f"Could not parse page {pagename}: {e}"))))))


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
            (parse-page pagename buffer content-type))
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
