(import [bottle    [request response route get :as handle-get]]
        [config    [*bind-address* *zmq-port*]]
        [json      [dumps]]
        [logging   [getLogger]]
        [utils     [sse-pack]]
        [zmq       [Context *sub* *subscribe*]])

(setv log (getLogger))

(defn set-response-headers [headers]
    ; convert dict k/v to plain strings, since gevent's WSGI is picky that way
    (let [[result {}]]
        (for [k headers]
            (assoc (. response headers) (str k) (str (get headers k))))
        (. response headers)))
        
        
; CORS handling
(with-decorator
    (apply route ["/events"] {"method" "OPTIONS"})
    (defn options []
        (set-response-headers {"Access-Control-Allow-Origin"  "*"
                               "Access-Control-Allow-Methods" "GET, OPTIONS"
                               "Access-Control-Allow-Headers" "X-REQUESTED-WITH, CACHE-CONTROL, LAST-EVENT-ID"
                               "Content-Type"                 "text/plain"})
        (.debug log "Got OPTIONS request")
        ""))


; event tap
(with-decorator
    (handle-get "/events")
    (defn server-events []
        (let [[event-id (.get (. request headers) "Last-Event-Id" 0)]
              [ctx      (Context)]
              [sock     (.socket ctx *sub*)]
              [msg      {"event" "init"
                         "data"  "{}"
                         "id"    event-id
                         "retry" 2000}]]
            (.connect sock (% "tcp://%s:%d" (, *bind-address* *zmq-port*)))
            (.setsockopt sock *subscribe* (str ""))
            (set-response-headers {"Content-Type"                "text/event-stream"
                                   "Access-Control-Allow-Origin" "*"})
            (.debug log (dict (. response headers)))
            (.debug log (sse-pack msg))
            (yield (sse-pack msg))
            (.debug log "Sent initial message")
            ; TODO: handle disconnects, which usually generate exceptions
            (while true
                (setv event-id (inc event-id))
                (setv data (.recv-multipart sock))
                (assoc msg "event" (get data 0)
                           "data"  (get data 1)
                           "id"    event-id)
                (.debug log (% "Sent %s" msg))
                (yield (sse-pack msg))))))
