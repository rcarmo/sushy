(import 
    .models      [list-blobs put-blob get-blob]
    io           [BytesIO]
    PIL          [Image]
    requests     [Session ConnectTimeout]
    logging      [getLogger]
    urllib.parse [urlsplit urljoin]
    lxml.html    [fromstring]
    functools    [lru-cache cache])

(setv log (getLogger))
(setv fetcher (Session))
(setv fetcher.headers {"User-Agent" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4.1 Safari/605.1.15"})

(defn [cache] download-favicon [url]
    ; try to obtain a favicon from a (base) URL
    (let [hostname (get (urlsplit url) 1)
          existing (list (list-blobs))]
        (when (not (in f"favicon:{hostname}" existing))
            (try
                (let [res (.get fetcher (urljoin url "favicon.ico") :allow-redirects True :timeout 2)]
                    (if (= 200 res.status_code)
                        (save-favicon hostname res.content)
                        (let [href (parse-favicon url)]
                            (when href 
                              (let [res (.get fetcher href :allow-redirects True :timeout 2)]
                                  (when (= 200 res.status_code)
                                      (save-favicon hostname res.content)))))))
                (except [e Exception]
                    (.warn log f"{e} {url}"))))))

(defn parse-favicon [url]
    ; get first usable icon candidate (or none) from HTML page
    (let [res (.get fetcher url :allow-redirects True :timeout 2)]
        (when (= 200 res.status_code)
           (let [doc (fromstring res.content) 
                 href ""]
               (for [rel ["shortcut icon" "icon" "apple-touch-icon" "apple-touch-icon-precomposed"]]
                  (for [tag (.xpath doc f"//link[@rel='{rel}']")]
                      (setv href (get (. tag attrib) "href"))
                      (when href (break)))
                  (when href (break)))
               (when href
                  (if (get (urlsplit href) 0)
                      href
                      (urljoin url href)))))))

(defn save-favicon [hostname data]
    ; try to resize and save the favicon (we don't care about SVGs, so this always assumes we got bitmap data of some sort)
    (try
        (let [im (.open Image (BytesIO data))
              buffer (BytesIO)
              _ (.save (.resize im #(48 48)) buffer :format "PNG")]
            (put-blob :name f"favicon:{hostname}" :mimetype "image/png" :data (.getvalue buffer)))
        (except [e Exception]
            (.warn log f"{e} {hostname}"))))

(defn [(lru-cache 20)] get-favicon [hostname]
    ; retrieve a stored favicon. We assume they're always tiny PNGs
    (get (get-blob f"favicon:{hostname}") "data"))
