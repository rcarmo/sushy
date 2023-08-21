(import
    bottle       [DEBUG :as *debug* default-app run route view template]
    sushy.config [*debug-mode* *bind-address* *http-port*]
    logging      [getLogger]
    sushy.routes)

(setv *debug* *debug-mode*)

(def app (default-app))

(defmain [&rest args]
    (apply run []
        {"app"      app
         "host"     *bind-address*
         "port"     *http-port*
         "debug"    *debug-mode*}))
