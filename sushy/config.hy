(import
    [bottle         [*template-path* template]]
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

(setv stdout ((getwriter "utf-8") stdout))

(def *timezone* (timezone (.get environ "TIMEZONE" "UTC")))

(def *store-path* (.get environ "CONTENT_PATH" "pages"))

(def *theme-path* (.get environ "THEME_PATH" "themes/wiki"))

(def *feed-css* (.get environ "FEED_CSS" (+ *theme-path* "/static/css/rss.css")))

(def *feed-ttl* 1800); in seconds

(def *rss-date-format* "%a, %d %b %Y %H:%M:%S %z")

(def *site-name* (.get environ "SITE_NAME" "Sushy"))

(def *site-description* (.get environ "SITE_DESCRIPTION" "A Sushy-powered site"))

(def *site-copyright* (.get environ "SITE_COPYRIGHT" "CC Attribution-NonCommercial-NoDerivs 3.0"))

(def *static-path* (join *theme-path* "static"))

(def *view-path* (join *theme-path* "views"))

(def *bind-address* (.get environ "BIND_ADDRESS" "127.0.0.1"))

(def *http-port* (.get environ "PORT" "8080"))

(def *page-route-base* "/space")

(def *page-media-base* "/media")

(def *blog-archive-base* "/archives")

(def *blog-entries* (.compile re "^(blog|links)/.+$"))

(def *thumb-media-base* "/thumb")

(def *home-page* (+ *page-route-base* "/HomePage"))

(def *debug-mode* (= (.lower (.get environ "DEBUG" "false")) "true"))

(def *profiler* (= (.lower (.get environ "PROFILER" "false")) "true"))

(def *thumbnail-sizes* [(, 320 240) (, 640 320) (, 1280 720)])

(def *placeholder-image* "/static/img/placeholder.png")

(def *signed-prefixes* [*page-media-base* *thumb-media-base*])

(def *aliasing-chars* [" " "." "-" "_"])

(def *redirect-page* "meta/Redirects")

(def *alias-page* "meta/Aliases")

(def *interwiki-page* "meta/InterWikiMap")

(def *exclude-from-feeds* (.compile re "^meta.*"))

(def *root-junk* (.join "|" ["favicon\.ico" "apple-touch-icon\.png" "apple-touch-icon-precomposed\.png" "keybase\.txt"]))

(def *base-types*
    {".txt"      "text/x-textile"; TODO: this should be reverted to text/plain later in the testing cycle
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

; TODO: cleanup the logging dict

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

; prepend the theme template path to bottle's search list
(.insert *template-path* 0 (abspath *view-path*))

; compute a sha1 hash for the HTML layout, so that etag generation is related to HTTP payload
(def *layout-hash* (.hexdigest (sha1 (template "layout" {"base" "" "base_url" "" "headers" {"title" ""} "site_name" "" "site_description" "" "page_route_base" ""}))))
