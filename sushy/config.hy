(import
    [bottle         [*template-path*]]
    [logging        [getLogger basicConfig *debug* *info*]]
    [logging.config [dictConfig]]
    [os             [environ]]
    [re]
    [sys            [stdout]]
    [codecs         [getwriter]]
    [os.path        [join abspath]])

(setv log (getLogger --name--))

(setv stdout ((getwriter "utf-8") stdout))

(def *store-path* (.get environ "CONTENT_PATH" "pages"))

(def *theme-path* (.get environ "THEME_PATH" "themes/wiki"))

(def *feed-css* (.get environ "FEED_CSS" "themes/wiki/static/css/rss.css"))

(def *feed-ttl* 30)

(def *rss-date-format* "%a, %d %b %Y %H:%M:%S %z")

(def *site-name* (.get environ "SITE_NAME" "Sushy"))

(def *site-description* (.get environ "SITE_DESCRIPTION" "A Sushy-powered site"))

(def *site-copyright* (.get environ "SITE_COPYRIGHT" "CC Attribution-NonCommercial-NoDerivs 3.0"))

(def *static-path* (join *theme-path* "static"))

(def *view-path* (join *theme-path* "views"))

(def *bind-address* (.get environ "BIND_ADDRESS" "127.0.0.1"))

(def *http-port* (.get environ "PORT" "8080"))

; TODO: rename sockets for consistency

(def *update-socket* (.get environ "UPDATE_SOCKET" "ipc:///tmp/sushy-updates"))

(def *indexer-fanout* (.get environ "INDEXER_FANOUT_SOCKET" "ipc:///tmp/sushy-indexer"))

(def *indexer-control* (.get environ "INDEXER_CONTROL_SOCKET" "ipc:///tmp/sushy-control"))

(def *indexer-count* (.get environ "INDEXER_COUNT_SOCKET" "ipc:///tmp/sushy-count"))

(def *database-sink* (.get environ "DATABASE_SINK" "ipc:///tmp/sushy-writer"))

(def *page-route-base* "/space")

(def *page-media-base* "/media")

(def *home-page* (+ *page-route-base* "/HomePage"))

(def *debug-mode* (= (.lower (.get environ "DEBUG" "false")) "true"))

(def *profiler* (= (.lower (.get environ "PROFILER" "false")) "true"))

(def *aliasing-chars* [" " "." "-" "_"])

(def *alias-page* "meta/Aliases")

(def *interwiki-page* "meta/InterWikiMap")

(def *exclude-from-feeds* (.compile re "^meta.*"))

(def *base-types*
    {".txt"      "text/x-textile"; TODO: this should be reverted to text/plain later in the testing cycle
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
         "loggers"    {"peewee"       {"level"     "WARNING"
                                       "handlers"  ["ram" "console"]}
                       "__init__"     {"level" "WARNING"}; for Markdown
                       "sushy.models" {"level" "WARNING"}
                       "sushy.store"  {"level" "WARNING"}}
         "root"       {"level"    "DEBUG" 
                       "handlers" ["console"]}})
    (apply basicConfig [] {"level" *info* "format" "%(asctime)s %(levelname)s:%(process)d:%(funcName)s %(message)s"}))

; prepend the theme template path to bottle's search list
(.insert *template-path* 0 (abspath *view-path*))
