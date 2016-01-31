(import
    [docutils.core       [publish-parts]]
    [json                [loads]]
    [logging             [getLogger]]    
    [lxml.etree          [Element tostring fromstring]]
    [markdown            [Markdown]]
    [models              [get-latest]]
    [nbformat            [reads]]
    [nbconvert           [HTMLExporter]]
    [smartypants         [smartypants]]
    [store               [get-page]]
    [textile             [Textile]]
    [time                [time]])

(setv log (getLogger))

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


(defn render-ipynb [raw]
    (let [[exporter (HTMLExporter)]]
        (setv (. exporter template-file) "basic")
        (get (.from-notebook-node exporter (reads raw 4)) 0)))


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
    {"text/plain"               render-plaintext
     "text/rst"                 render-restructured-text ; unofficial, but let's be lenient
     "text/x-rst"               render-restructured-text ; official
     "application/x-ipynb+json" render-ipynb
     "text/x-web-markdown"      render-markdown
     "text/x-markdown"          render-markdown
     "text/markdown"            render-markdown
     "text/textile"             render-textile
     "text/x-textile"           render-textile
     "text/html"                render-html})
    
    
(defn render-page [page]
    (apply (get render-map (get (:headers page) "content-type")) [(:body page)] {}))


(defn sanitize-title [title]
    (re.sub "[\W+]" "-" (.lower title)))
