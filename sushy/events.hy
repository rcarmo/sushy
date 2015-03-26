(import [bottle    [request response route get :as handle-get]]
        [config    [*bind-address* *update-socket*]]
        [gevent    [sleep]]
        [json      [dumps]]
        [logging   [getLogger]]
        [utils     [sse-pack zmq-unpack]]
        [zmq       [Context ZMQError *sub* *subscribe* *noblock* *eagain*]])

(setv log (getLogger --name--))

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
        (let [[event-id (int (.get (. request headers) "Last-Event-Id" 0))]
              [ctx      (Context)]
              [sock     (.socket ctx *sub*)]
              [msg      {"event" "init"
                         "data"  "{}"
                         "id"    event-id
                         "retry" 2000}]]
            (.connect sock *update-socket*)
            (.setsockopt sock *subscribe* (str ""))
            (set-response-headers {"Content-Type"                "text/event-stream"
                                   "Access-Control-Allow-Origin" "*"})
            (yield (sse-pack msg))
            (.debug log "Sent initial message")
            (while true
                (try
                    (do
                        (setv event-id (inc event-id))
                        (setv data (zmq-unpack sock *noblock*))
                        (assoc msg "event" (get data 0)
                                   "data"  (get data 1)
                                   "id"    event-id)
                        (.debug log (% "Sent %s" msg))
                        (yield (sse-pack msg)))
                    (catch [e ZMQError]
                        (sleep 1)))))))
