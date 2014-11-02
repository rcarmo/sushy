(import
    [logging [getLogger]]
    [bottle  [DEBUG default-app run route view template]]
    [config  [*debug-mode* *bind-address* *http-port*]]
    routes)

(setv DEBUG *debug-mode*)

(def app (default-app))

(apply run []
    {"app"   app
     "host"  *bind-address*
     "port"  *http-port*
     "debug" *debug-mode*})
