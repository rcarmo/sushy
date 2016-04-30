(import 
    [bottle [view :as render-template]]
    [config [*page-route-base*]])

(with-decorator (render-template "inline-message") 
    (defn inline-message [level message]
        {"level"   level
         "message" message}))
         
         
(with-decorator (render-template "inline-table")
    (defn inline-table [headers rows]
        {"headers"   headers
         "rows"      rows
         "page_base" *page-route-base*}))
