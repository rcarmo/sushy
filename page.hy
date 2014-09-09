(import [logging [getLogger]])

(setv log (getLogger))

(defn strip-seq [string-sequence]
    (map (fn [buffer] (.strip buffer)) string-sequence))
    
(defn split-header-line [string]
    (let [[parts (strip-seq (.split string ":" 1))]]
       [(.lower (get parts 0)) (get parts 1)]))
            
(defn parse-page [buffer]
    ; parse a page and return a header map and the raw markup
    (try 
        (let [[parts        (.split buffer "\n\n" 1)]
              [header-lines (.split (get parts 0) "\n")]
              [headers      (dict (map split-header-line header-lines))]
              [body         (get parts 1)]]
              (if (not (in "content-type" headers))
                (assoc headers "content-type" "text/plain"))
              {"headers" headers
               "body"    body})
        (catch [e Exception]
            (.exception log "Could not parse page")
            (throw (IOError "Invalid Page Format.")))))

