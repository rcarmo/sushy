(import
    [bottle         [*template-path* template]]
    [collections    [defaultdict]]
    [datetime       [timedelta]]
    [hashlib        [sha1]]
    [logging        [getLogger basicConfig *debug* *info*]]
    [logging.config [dictConfig]]
    [os             [environ]]
    [pytz           [timezone]]
    [re]
    [sys            [stdout]]
    [codecs         [getwriter]]
    [os.path        [join abspath]])

(setv log (getLogger --name--))

; force stdout to use UTF-8
(setv stdout ((getwriter "utf-8") stdout))

; for running standalone
(def *http-port* (.get environ "PORT" "8080"))

(def *site-name* (.get environ "SITE_NAME" "Sushy"))

; core settings
(def *bind-address* (.get environ "BIND_ADDRESS" "127.0.0.1"))

(def *site-description* (.get environ "SITE_DESCRIPTION" "A Sushy-powered site"))

(def *site-copyright* (.get environ "SITE_COPYRIGHT" "CC Attribution-NonCommercial-NoDerivs 3.0"))

(def *store-path* (.get environ "CONTENT_PATH" "pages"))

(def *theme-path* (.get environ "THEME_PATH" "themes/wiki"))

(def *static-path* (join *theme-path* "static"))

(def *view-path* (join *theme-path* "views"))

; prepend the theme template path to bottle's search list
(.insert *template-path* 0 (abspath *view-path*))

(def *timezone* (timezone (.get environ "TIMEZONE" "UTC")))

; feed settings
(def *feed-css* (.get environ "FEED_CSS" (+ *theme-path* "/static/css/rss.css")))

(def *feed-ttl* 1800); in seconds

(def *feed-time-window* (apply timedelta [] {"weeks" -4}))

(def *feed-item-window* 20)

(def *exclude-from-feeds* (.compile re "^(meta)/.+$"))

; Azure App Insights
(def *instrumentation-key* (.get environ "INSTRUMENTATION_KEY" nil))

; UDP remote statistics
(def *stats-address* (.get environ "STATS_ADDRESS" "127.0.0.1"))

(def *stats-port* (int (.get environ "STATS_PORT" "0")))

; Base routes
(def *page-route-base* "/space")

(def *page-media-base* "/media")

(def *blog-archive-base* "/archives")

(def *scaled-media-base* "/thumb")

(def *blog-entries* (.compile re "^(blog|links)/.+$"))

; files that are supposed to be hosted at the site root
(def *root-junk* (.join "|" ["favicon\.ico" "apple-touch-icon\.png" "apple-touch-icon-precomposed\.png" "keybase\.txt"]))

; Image handling
(def *lazyload-images* (= (.lower (.get environ "LAZY_LOADING" "false")) "true"))

; maximum non-retina image size
(def *max-image-size* 1024)

(def *min-image-size* 16)

(def *thumbnail-sizes* [(, 40 30) (, 160 120) (, 320 240) (, 640 480) (, 1280 720)])

(def *placeholder-image* "/static/img/placeholder.png")

; HMAC asset signing
(def *asset-key* (.get environ "ASSET_KEY" ""))

(def *asset-hash* (.hexdigest (sha1 (+ *site-name* *site-description* *asset-key*))))

(def *signed-prefixes* [*page-media-base* *scaled-media-base*])

(def *aliasing-chars* [" " "." "-" "_" "+"])

; meta pages we need to run
(def *redirect-page* "meta/Redirects")

(def *alias-page* "meta/Aliases")

(def *banned-agents-page* "meta/BannedAgents")

(def *interwiki-page* "meta/InterWikiMap")

(def *links-page* "meta/Footer")

; markup file extensions
(def *base-types*
    {".txt"      "text/x-textile"; TODO: this should be reverted to text/plain after legacy content is cleared out
     ".ipynb"    "application/x-ipynb+json"
     ".htm"      "text/html"
     ".html"     "text/html"
     ".rst"      "text/x-rst"
     ".md"       "text/x-markdown"
     ".mkd"      "text/x-markdown"
     ".mkdn"     "text/x-markdown"
     ".markdown" "text/x-markdown"
     ".textile"  "text/x-textile"})
     
(def *base-filenames*
    (list-comp (% "index%s" t) [t (.keys *base-types*)]))

(def *base-page* "From: %(author)s\nDate: %(date)s\nContent-Type: %(markup)s\nContent-Encoding: utf-8\nTitle: %(title)s\nKeywords: %(keywords)s\nCategories: %(categories)s\nTags: %(tags)s\n%(_headers)s\n\n%(content)s")

(def *ignored-folders* ["CVS" ".hg" ".svn" ".git" ".AppleDouble" ".TemporaryItems"])

; debugging
(def *debug-mode* (= (.lower (.get environ "DEBUG" "false")) "true"))

(def *profiler* (= (.lower (.get environ "PROFILER" "false")) "true"))

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