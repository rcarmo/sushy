(import
    [cssutils           [log :as *cssutils-log*]]
    [docutils.core      [publish-parts]]
    [inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter *error*]]    
    [lxml.etree         [Element tostring fromstring]]
    [markdown           [Markdown]]
    [smartypants        [smartypants]]
    [textile            [Textile]]
    [time               [time]])

(setv log (getLogger))

; disable logging for inlinestyler, since it is incredibly whiny
(.setLevel *cssutils-log* *error*)

; instantiate markdown renderer upon module load
(def markdown-renderer
     (apply Markdown [] {"extensions" ["markdown.extensions.extra" 
                                       "markdown.extensions.toc" 
                                       "markdown.extensions.smarty" 
                                       "markdown.extensions.codehilite" 
                                       "markdown.extensions.meta" 
                                       "markdown.extensions.sane_lists"]
                         "extension_configs" {"markdown.extensions.codehilite" {"css_class" "highlight"}}}))

(def textile-renderer
    (apply Textile [] {"html_type" "html5"}))


(defn render-html [raw]
    (let [[res (.strip raw)]]
        (if (len res)
            res 
            "<body></body>")))
    

(defn render-plaintext [raw]
    (% "<pre>\n%s</pre>" raw))

    
(defn render-restructured-text [raw]
    (get (apply publish-parts [raw] {"writer_name" "html"}) "html_body"))
    

(defn render-markdown [raw]
    (.reset markdown-renderer)
    (.convert markdown-renderer raw))
                

(defn render-textile [raw]
    (smartypants (apply textile-renderer.parse [raw] {"head_offset" 0})))


(def render-map 
   {"text/plain"          render-plaintext
    "text/rst"            render-restructured-text ; unofficial, but let's be lenient
    "text/x-rst"          render-restructured-text ; official
    "text/x-web-markdown" render-markdown
    "text/x-markdown"     render-markdown
    "text/markdown"       render-markdown
    "text/textile"        render-textile
    "text/x-textile"      render-textile
    "text/html"           render-html})
    
    
(defn render-page [page]
    (apply (get render-map (get (:headers page) "content-type")) [(:body page)] {}))


(defn sanitize-title [title]
    (re.sub "[\W+]" "-" (.lower title)))


(.setLevel *cssutils-log* *error*); disable logging, since it is incredibly whiny


(defn filtered-latest []
    (filter (fn [x] (not (.match *exclude-from-feeds* (.get x "name")))) (get-latest)))


(defn render-feed-items []
    (let [[items []]]
        (for [item (filtered-latest)]
            (let [[pagename (.get item "name")]
                  [page     (get-page pagename)]
                  [doc      (apply-transforms (render-page page) pagename)]]
                (.append doc (apply Element ["link"] {"rel"  "stylesheet"
                                                      "href" (+ "file://" (abspath *feed-css*)) }))
                (assoc item
                    "pagename"     pagename
                    "author"       (get (:headers page) "from")
                    "pubdate"     (.strftime (.localize *utc* (get item "pubtime")) *rss-date-format*)
                    "description"  (inner-html (fromstring (inline-css (tostring doc))))
                    "category"    (get (.split pagename "/") 0))
                (.append items item)))
        items))