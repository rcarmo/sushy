(import 
    [time [time]]
    [logging [getLogger]]    
    [store [get-raw-page scan-pages]]
    [textile [textile]]
    [smartypants [smartyPants]]
    [markdown [Markdown]])
    
(setv log (getLogger))

(defn render-html [raw]
    raw)
    
(defn render-plaintext [raw]
    (% "<pre>\n%s</pre>" raw))
    
(defn render-markdown [raw]
    (.convert (apply Markdown [] {"extensions" ["extra" "toc" "smarty" "codehilite" "meta" "sane_lists"]
                                 "safe_mode" false})
                raw))
                
(defn render-textile [raw]
    (smartyPants (apply textile [raw] {"head_offset" 0
                                       "html_type"   "html"})))

(def render-map 
   {"text/plain"          render-plaintext
    "text/x-web-markdown" render-markdown
    "text/x-markdown"     render-markdown
    "text/markdown"       render-markdown
    "text/textile"        render-textile
    "text/x-textile"      render-textile
    "text/htm"            render-html})
    
    
(defn render-page [page]
    (apply (get render-map (get (:headers page) "content-type")) [(:body page)] {}))


(defn sanitize-title [title]
    (re.sub "[\W+]" "-" (.lower title)))
