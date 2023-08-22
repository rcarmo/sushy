(import
    bottle         [TEMPLATE_PATH :as *template-path* template]
    collections    [defaultdict]
    datetime       [timedelta]
    hashlib        [sha1]
    logging        [getLogger basicConfig DEBUG :as *debug* INFO :as *info*]
    logging.config [dictConfig]
    os             [environ]
    pytz           [timezone]
    re
    sys            [stdout]
    codecs         [getwriter]
    os.path        [join abspath])

(setv log (getLogger __name__))

; force stdout to use UTF-8
(setv stdout ((getwriter "utf-8") stdout))

; for running standalone
(setv *http-port* (.get environ "PORT" "8080"))

(setv *site-name* (.get environ "SITE_NAME" "Sushy"))

; core settings
(setv *bind-address* (.get environ "BIND_ADDRESS" "127.0.0.1"))

(setv *site-description* (.get environ "SITE_DESCRIPTION" "A Sushy-powered site"))

(setv *site-copyright* (.get environ "SITE_COPYRIGHT" "CC Attribution-NonCommercial-NoDerivs 3.0"))

(setv *store-path* (.get environ "CONTENT_PATH" "pages"))

(setv *theme-path* (.get environ "THEME_PATH" "themes/wiki"))

(setv *static-path* (join *theme-path* "static"))

(setv *view-path* (join *theme-path* "views"))

; prepend the theme template path to bottle's search list
(.insert *template-path* 0 (abspath *view-path*))

(setv *timezone* (timezone (.get environ "TIMEZONE" "UTC")))

; feed settings
(setv *feed-css* (.get environ "FEED_CSS" (+ *theme-path* "/static/css/rss.css")))

(setv *feed-ttl* 1800); in seconds

(setv *feed-time-window* (timedelta :weeks -4))

(setv *feed-item-window* 20)

(setv *exclude-from-feeds* (.compile re "^(meta)/.+$"))

; Azure App Insights
(setv *instrumentation-key* (.get environ "INSTRUMENTATION_KEY" None))

; UDP remote statistics
(setv *stats-address* (.get environ "STATS_ADDRESS" "127.0.0.1"))

(setv *stats-port* (int (.get environ "STATS_PORT" "0")))

; Base routes
(setv *page-route-base* "/space")

(setv *page-media-base* "/media")

(setv *blog-archive-base* "/archives")

(setv *scaled-media-base* "/thumb")

(setv *blog-entries* (.compile re "^(blog|links)/.+$"))

; files that are supposed to be hosted at the site root
(setv *root-junk* (.join "|" ["favicon.ico" "apple-touch-icon.png" "apple-touch-icon-precomposed.png" "keybase.txt"]))

; Image handling
(setv *lazyload-images* (= (.lower (.get environ "LAZY_LOADING" "false")) "true"))

; maximum non-retina image size
(setv *max-image-size* 1024)

(setv *min-image-size* 16)

(setv *thumbnail-sizes* [#(40 30) #(160 120) #(320 240) #(640 480) #(1280 720)])

(setv *placeholder-image* "/static/img/placeholder.png")

; HMAC asset signing
(setv *asset-key* (.get environ "ASSET_KEY" ""))

(setv *asset-hash* (.hexdigest (sha1 (.encode (+ *site-name* *site-description* *asset-key*) "utf-8"))))

(setv *signed-prefixes* [*page-media-base* *scaled-media-base*])

(setv *aliasing-chars* [" " "." "-" "_" "+"])

; meta pages we need to run
(setv *redirect-page* "meta/Redirects")

(setv *alias-page* "meta/Aliases")

(setv *banned-agents-page* "meta/BannedAgents")

(setv *interwiki-page* "meta/InterWikiMap")

(setv *links-page* "meta/Footer")

; markup file extensions
(setv *base-types*
    {".txt"      "text/x-textile"; TODO: this should be reverted to text/plain after legacy content is cleared out
     ".ipynb"    "application/x-ipynb+json"
     ".htm"      "text/html"
     ".html"     "text/html"
;     ".rst"      "text/x-rst"
     ".md"       "text/x-markdown"
     ".mkd"      "text/x-markdown"
     ".mkdn"     "text/x-markdown"
     ".markdown" "text/x-markdown"
     ".textile"  "text/x-textile"})
     
(setv *base-filenames*
    (lfor t (.keys *base-types*) f"index{t}"))

(setv *base-page* "From: %(author)s\nDate: %(date)s\nContent-Type: %(markup)s\nContent-Encoding: utf-8\nTitle: %(title)s\nKeywords: %(keywords)s\nCategories: %(categories)s\nTags: %(tags)s\n%(_headers)s\n\n%(content)s")

(setv *ignored-folders* ["CVS" ".hg" ".svn" ".git" ".AppleDouble" ".TemporaryItems"])

; debugging
(setv *debug-mode* (= (.lower (.get environ "DEBUG" "false")) "true"))

(setv *profiler* (= (.lower (.get environ "PROFILER" "false")) "true"))

(if *debug-mode*
    (dictConfig 
        {"version"    1
         "formatters" {"http"    {"format" "localhost - - [%(asctime)s] %(process)d %(levelname)s %(filename)s:%(funcName)s:%(lineno)d %(message)s"
                                  "datefmt" "%Y/%m/%d %H:%M:%S"}}
         "handlers"   {"console" {"class"     "logging.StreamHandler"
                                  "formatter" "http"
                                  "level"     "DEBUG"
                                  "stream"    "ext://sys.stdout"}
                       "ram"     {"class"     "logging.handlers.MemoryHandler"
                                  "formatter" "http"
                                  "level"     "WARNING"
                                  "capacity"  200}}
         "loggers"    {"peewee"       {"level"     "DEBUG"
                                       "handlers"  ["ram" "console"]}
                       "__init__"     {"level" "WARNING"}; for Markdown
                       "sushy.models" {"level" "WARNING"}
                       "sushy.store"  {"level" "WARNING"}}
         "root"       {"level"    "DEBUG" 
                       "handlers" ["console"]}})
    (apply basicConfig [] {"level" *info* "format" "%(asctime)s %(levelname)s:%(process)d:%(funcName)s %(message)s"}))
