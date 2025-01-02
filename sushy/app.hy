(import
  .config                         [DEBUG_MODE BIND_ADDRESS HTTP_PORT]
  base64                          [urlsafe_b64_decode]
  cryptography.fernet             [Fernet]
  aiohttp.web                     [Application run_app]
  aiohttp_session                 [setup get_sesion session_middleware]
  aiohttp_session.cookie_storage  [EncryptedCookieStorage]
  logging                         [getLogger]
  sushy.routes                    [app])

(require hyrule [defmain])

(setv app (Application))

(defmain [args]
  (let [fernet_key (.generate_key Fernet)
        secret_key (urlsafe_b64_decode fernet_key)]
    (setup app (EncryptedCookieStorage secret_key))
    ; setup routes
    (run_app app
         :host  BIND_ADDRESS
         :port  HTTP_PORT
         :debug DEBUG_MODE)))
