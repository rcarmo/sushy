(import 
    .config [*page-route-base*]
    bottle  [view :as render-template])

(defn [(render-template "inline-message")] inline-message [level message]
    ; render a little error message
    {"level"   level
      "message" message})
         
         
(defn [(render-template "inline-table")] inline-table [headers rows]
    ; render a table
    {"headers"   headers
      "rows"      rows
      "page_base" *page-route-base*})
