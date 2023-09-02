(import
    .config      [DEBUG_MODE BIND_ADDRESS HTTP_PORT]
    bottle       [DEBUG default-app run route view template]
    logging      [getLogger]
    sushy.routes)

(require hyrule [defmain])

(setv DEBUG DEBUG_MODE)
(setv app (default-app))

(defmain [args]
    (run :app   app
         :host  BIND_ADDRESS
         :port  HTTP_PORT
         :debug DEBUG_MODE))
