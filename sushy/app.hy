(import
    [bottle       [*debug* default-app run route view template]]
    [sushy.config [*debug-mode* *bind-address* *http-port*]]
    ;[gevent       [monkey]]
    [logging      [getLogger]]
    sushy.routes)

(setv *debug* *debug-mode*)

;(.patch-all monkey)

(def app (default-app))

(defmain [&rest args]
    (apply run []
        {"app"      app
         "host"     *bind-address*
         "port"     *http-port*
         ;"server"  "gevent"
         "debug"    *debug-mode*}))
