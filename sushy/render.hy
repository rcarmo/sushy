(import
    ; docutils.core       [publish-parts]
    .models             [get-latest]
    .store              [get-page]
    json                [loads]
    logging             [getLogger]
    lxml.etree          [Element tostring fromstring]
    markdown            [Markdown]
    cmarkgfm            [github-flavored-markdown-to-html]
    cmarkgfm._cmark.lib [CMARK_OPT_UNSAFE CMARK_OPT_SMART CMARK_OPT_NORMALIZE CMARK_OPT_FOOTNOTES CMARK_OPT_VALIDATE_UTF8 CMARK_OPT_GITHUB_PRE_LANG CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES]
    re                  [sub]
    smartypants         [smartypants]
    textile             [Textile]
    time                [time])

(setv log (getLogger))

; instantiate markdown renderer upon module load
(setv markdown-renderer
     (Markdown :extensions ["markdown.extensions.extra" 
                            "markdown.extensions.toc" 
                            "markdown.extensions.smarty" 
                            "markdown.extensions.codehilite" 
                            "markdown.extensions.meta" 
                            "markdown.extensions.sane_lists"]
               :extension_configs {"markdown.extensions.codehilite" {"css_class" "highlight"}}))

(setv textile-renderer
    (Textile :html_type "html5"))


(defn render-html [raw]
    (let [res (.strip raw)]
        (if (len res)
            res 
            "<body></body>")))
    

(defn render-plaintext [raw]
    f"<pre>\n{raw}</pre>")

    
;(defn render-restructured-text [raw]
;    (get (apply publish-parts [raw] {"writer_name" "html"}) "html_body"))
    

(defn render-markdown [raw]
    (.reset markdown-renderer)
    (.convert markdown-renderer raw))
                
(defn render-gfm [raw]
    (github-flavored-markdown-to-html raw
       :options (| CMARK_OPT_UNSAFE
                   CMARK_OPT_SMART
                   CMARK_OPT_NORMALIZE 
                   CMARK_OPT_FOOTNOTES
                   CMARK_OPT_VALIDATE_UTF8
                   CMARK_OPT_GITHUB_PRE_LANG 
                   CMARK_OPT_TABLE_PREFER_STYLE_ATTRIBUTES)))

(defn render-textile [raw]
    (smartypants (textile-renderer.parse raw))) 


(setv render-map 
    {"text/plain"               render-plaintext
     "text/x-web-markdown"      render-gfm
     "text/x-markdown"          render-gfm
     "text/markdown"            render-gfm
     "text/textile"             render-textile
     "text/x-textile"           render-textile
     "text/html"                render-html})
    
    
(defn render-page [page]
    (.debug log (:headers page))
    ((get render-map (get (:headers page) "content-type")) (:body page)))


(defn sanitize-title [title]
    (sub "[\\W+]" "-" (.lower title)))
