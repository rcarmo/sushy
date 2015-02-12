(import
    [bottle  [*template-path*]]
    [logging [getLogger basicConfig *debug* *info*]]
    [os      [environ]]
    [os.path [join abspath]])

(setv log (getLogger))

(def *store-path* (.get environ "CONTENT_PATH" "pages"))

(def *theme-path* (.get environ "THEME_PATH" "themes/wiki"))

(def *static-path* (join *theme-path* "static"))

(def *view-path* (join *theme-path* "views"))

(def *bind-address* (.get environ "BIND_ADDRESS" "127.0.0.1"))

(def *http-port* (.get environ "PORT" "8080"))

(def *zmq-port* (int (.get environ "ZMQ_PORT" "10000")))

(def *page-route-base* "/space")

(def *page-media-base* "/media")

(def *home-page* (+ *page-route-base* "/HomePage"))

(def *debug-mode* (= (.lower (.get environ "DEBUG" "false")) "true"))

(def *profiler* (= (.lower (.get environ "PROFILER" "false")) "true"))

(def *aliasing-chars* [" " "." "-" "_"])

(def *alias-page* "meta/Aliases")

(def *interwiki-page* "meta/InterWikiMap")

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

(if *debug-mode*
    (apply basicConfig [] {"level" *debug* "format" "%(asctime)s %(levelname)s %(process)d %(filename)s:%(funcName)s:%(lineno)d %(message)s"})
    (apply basicConfig [] {"level" *info* "format" "%(levelname)s:%(process)d:%(funcName)s %(message)s"}))

; prepend the theme template path to bottle's search list
(.insert *template-path* 0 (abspath *view-path*))
