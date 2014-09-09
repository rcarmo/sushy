(import
    [logging [getLogger DEBUG INFO]])

(setv log (getLogger))

(def *page-path* "/space")

(def *home-page* (+ *page-path* "/HomePage"))

(def *debug-mode* true)

(if *debug-mode*
    (.setLevel log DEBUG)
    (.setLevel log INFO))
    
