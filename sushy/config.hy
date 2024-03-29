(import
    bottle         [TEMPLATE_PATH template]
    collections    [defaultdict]
    datetime       [timedelta]
    hashlib        [sha1]
    logging        [getLogger basicConfig DEBUG INFO]
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

; core settings
(setv HTTP_PORT (.get environ "PORT" "8080"))
(setv BIND_ADDRESS     (.get environ "BIND_ADDRESS" "127.0.0.1"))
(setv SITE_NAME (.get environ "SITE_NAME" "Sushy"))
(setv SITE_DESCRIPTION (.get environ "SITE_DESCRIPTION" "A Sushy-powered site"))
(setv SITE_COPYRIGHT   (.get environ "SITE_COPYRIGHT" "CC Attribution-NonCommercial-NoDerivs 3.0"))
(setv STORE_PATH       (.get environ "CONTENT_PATH" "pages"))
(setv THEME_PATH       (.get environ "THEME_PATH" "themes/wiki"))
(setv STATIC_PATH      (join THEME_PATH "static"))
(setv VIEW_PATH        (join THEME_PATH "views"))

; prepend the theme template path to bottle's search list
(.insert TEMPLATE_PATH 0 (abspath VIEW_PATH))

(setv TIMEZONE (timezone (.get environ "TIMEZONE" "Europe/Lisbon")))

; feed settings
(setv FEED_CSS (.get environ "FEED_CSS" (+ THEME_PATH "/static/css/rss.css")))
(setv FEED_TTL 1800); in seconds
(setv FEED_TIME_WINDOW (timedelta :weeks -4))
(setv FEED_ITEM_WINDOW 20)
(setv EXCLUDE_FROM_FEEDS (.compile re "^(meta)/.+$"))

; Homepage items
(setv BLOG_ENTRIES (.compile re "^(blog|links|notes)/.+$"))

; UDP remote statistics
(setv STATS_ADDRESS (.get environ "STATS_ADDRESS" "127.0.0.1"))
(setv STATS_PORT (int (.get environ "STATS_PORT" "0")))

; Base routes
(setv PAGE_ROUTE_BASE "/space")
(setv PAGE_MEDIA_BASE "/media")
(setv BLOG_ARCHIVE_BASE "/archives")
(setv SCALED_MEDIA_BASE "/thumb")

; files that are supposed to be hosted at the site root
(setv ROOT_JUNK (.join "|" ["favicon.ico" "apple-touch-icon.png" "apple-touch-icon-precomposed.png" "keybase.txt"]))

; Image handling
(setv LAZYLOAD_IMAGES (= (.lower (.get environ "LAZY_LOADING" "false")) "true"))

; maximum non-retina image size
(setv MAX_IMAGE_SIZE    1024)
(setv MIN_IMAGE_SIZE    16)
(setv THUMBNAIL_SIZES   [#(40 30) #(160 120) #(320 240) #(640 480) #(1280 720)])
(setv PLACEHOLDER_IMAGE "/static/img/placeholder.png")

; HMAC asset signing
(setv ASSET_KEY       (.get environ "ASSET_KEY" ""))
(setv ASSET_HASH      (.hexdigest (sha1 (.encode (+ SITE_NAME SITE_DESCRIPTION ASSET_KEY) "utf-8"))))
(setv SIGNED_PREFIXES [PAGE_MEDIA_BASE SCALED_MEDIA_BASE])
(setv ALIASING_CHARS  [" " "." "-" "_" "+"])

; meta pages we need to run
(setv REDIRECT_PAGE      "meta/redirects")
(setv ALIAS_PAGE         "meta/aliases")
(setv BANNED_AGENTS_PAGE "meta/bannedagents")
(setv INTERWIKI_PAGE     "meta/interwikimap")
(setv LINKS_PAGE         "meta/footer")

; markup file extensions
(setv BASE_TYPES
    {".txt"      "text/x-textile"; TODO: this should be reverted to text/plain after legacy content is cleared out
     ".htm"      "text/html"
     ".html"     "text/html"
     ".md"       "text/x-markdown"
     ".mkd"      "text/x-markdown"
     ".mkdn"     "text/x-markdown"
     ".markdown" "text/x-markdown"
     ".textile"  "text/x-textile"})
     
(setv BASE_FILENAMES
    (lfor t (.keys BASE_TYPES) f"index{t}"))

(setv BASE_PAGE "From: %(author)s\nDate: %(date)s\nContent-Type: %(markup)s\nContent-Encoding: utf-8\nTitle: %(title)s\nKeywords: %(keywords)s\nCategories: %(categories)s\nTags: %(tags)s\n%(_headers)s\n\n%(content)s")

(setv IGNORED_FOLDERS ["CVS" ".hg" ".svn" ".git" ".AppleDouble" ".TemporaryItems"])

; debugging
(setv DEBUG_MODE (= (.lower (.get environ "DEBUG" "false")) "true"))
(setv PROFILER (= (.lower (.get environ "PROFILER" "false")) "true"))

(if DEBUG_MODE
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
    (basicConfig :level INFO :format "%(asctime)s %(levelname)s:%(process)d:%(funcName)s %(message)s"))
