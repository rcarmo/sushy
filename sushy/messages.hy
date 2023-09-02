(import 
    .config [PAGE_ROUTE_BASE]
    bottle  [view])

; render a little error message
(defn [(view "inline-message")]
    inline-message [level message]
        {"level"   level
         "message" message})
         
; render a table
(defn [(view "inline-table")]
     inline-table [headers rows]
        {"headers"   headers
         "rows"      rows
         "page_base" PAGE_ROUTE_BASE})
