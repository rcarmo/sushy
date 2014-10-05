(import
    [logging [getLogger]]
    [bottle  [DEBUG default-app run route view template]]
    [config  [*debug-mode*]]
    routes)

(setv DEBUG *debug-mode*)

(def app (default-app))

(apply run []
    {"app" app
     "debug" *debug-mode*})
