(import 
    [bottle [view :as render-template]]
    [config [*page-route-base*]])

(with-decorator (render-template "inline-message")
    (defn inline-message [level message]
        ; render a little error message
        {"level"   level
         "message" message}))
         
         
(with-decorator (render-template "inline-table")
    (defn inline-table [headers rows]
        ; render a table
        {"headers"   headers
         "rows"      rows
         "page_base" *page-route-base*}))
