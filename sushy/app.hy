(import
    [bottle  [DEBUG default-app run route view template]]
    [config  [*debug-mode* *bind-address* *http-port*]]
    [logging [getLogger]]
    routes)

(setv DEBUG *debug-mode*)

(def app (default-app))

(defmain [&rest args]
    (apply run []
        {"app"   app
         "host"  *bind-address*
         "port"  *http-port*
         "debug" *debug-mode*}))
