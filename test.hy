(import 
    [time [time]]
    [config [*store-path*]]
    [store [get-raw-page scan-pages]]
    [render [render-page]])

(print (get-raw-page "HomePage"))
    
;(print "get-all-pages")
;(for [x (range 10)]
;    (setv now (time))
;    (print (len (scan-pages *store-path*)))
;    (print (- (time) now)))

(print (render-page (get-raw-page "HomePage")))
