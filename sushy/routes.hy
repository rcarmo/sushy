(import 
    [logging   [getLogger]]
    [bottle    [route view template request redirect]]
    [config    [*home-page* *page-route-base*]]
    [store     [get-raw-page]]
    [render    [render-page]]
    [transform [apply-transforms]])


(setv log (getLogger))

(route "/" ["GET"]
    (fn []
        (redirect *home-page*)))

(route (+ *page-route-base* "/<page:path>") ["GET"]
    (fn [page] 
        (-> page
            (get-raw-page)
            (render-page)
            (apply-transforms page))))
