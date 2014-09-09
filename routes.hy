(import 
    [logging [getLogger]]
    [bottle  [route view template request redirect]]
    [config  [*home-page* *page-path*]])

(setv log (getLogger))

(route "/" ["GET"]
    (fn []
        (redirect *home-page*)))

(route (+ *page-path* "/<page>") ["GET"]
    (fn [page] 
        {}))