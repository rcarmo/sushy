(import
    .config      [DEBUG_MODE BIND_ADDRESS HTTP_PORT]
    bottle       [DEBUG default-app run route view template]
    logging      [getLogger]
    sushy.routes)

(setv DEBUG DEBUG_MODE)

(def app (default-app))

(defmain [&rest args]
    (apply run []
        {"app"      app
         "host"     BIND_ADDRESS
         "port"     HTTP_PORT
         "debug"    DEBUG_MODE}))
