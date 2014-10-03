(import [bottle [view :as render-template]])

(with-decorator (render-template "inline-message") 
    (defn inline-message [level message]
        {"level"   level
         "message" message}))
