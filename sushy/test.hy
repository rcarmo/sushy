(import 
    [logging [getLogger]]
    [time [time]]
    [config [*store-path*]]
    [store [get-raw-page scan-pages]]
    [render [render-page]]
    [transform [apply-transforms]])

(setv log getLogger)

;(print "get-all-pages")
;(for [x (range 10)]
;    (setv now (time))
;    (print (len (scan-pages *store-path*)))
;    (print (- (time) now)))

(print (apply-transforms (render-page (get-raw-page "blog/2014/06/02/2130"))))
