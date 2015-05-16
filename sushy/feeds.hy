(import 
    [config             [*store-path* *exclude-from-feeds*]]
	[inlinestyler.utils [inline-css]]
    [logging            [getLogger Formatter]]
	[models 			[*kvs* get-latest]])

(setv log (getLogger --name--))

(def filtered-latest
    (genexpr x [x (get-latest)] (not (.match *exclude-from-feeds* (.get x "name")))))

(defn update-rss []
   (for [page filtered-latest]
       (.debug log page)))


(defmain [&rest args]
    (.info log "Updating feed")
    (update-rss))
