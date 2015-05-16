(import 
    [config             [*store-path* *exclude-from-feeds* *feed-css*]]
	[inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter]]
    [lxml.etree         [Element tostring]]
	[models 			[*kvs* get-latest]]
    [os.path            [abspath]]
    [render             [render-page]]
    [store              [get-page]]
    [transform          [apply-transforms]])

(setv log (getLogger --name--))

(def filtered-latest
    (genexpr x [x (get-latest)] (not (.match *exclude-from-feeds* (.get x "name")))))


(defn update-rss []
   (for [item filtered-latest]
        (let [[pagename (.get item "name")]
              [page     (get-page pagename)]
              [doc      (apply-transforms (render-page page) pagename)]]
            (.append doc (apply Element ["link"] {"rel" "stylesheet" "href" (+ "file://" (abspath *feed-css*)) }))
            (assoc item "body" (inline-css (tostring doc)))
            (.debug log item)))) 

(defmain [&rest args]
    (.info log "Updating feed")
    (update-rss))
