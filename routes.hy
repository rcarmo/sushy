(import 
    [logging [getLogger]]
    [bottle  [route view template request redirect]]
    [config  [*home-page* *page-route-base*]])

(setv log (getLogger))

(route "/" ["GET"]
    (fn []
        (redirect *home-page*)))

(route (+ *page-route-base* "/<page>") ["GET"]
    (fn [page] 
        {}))
