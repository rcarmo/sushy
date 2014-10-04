(import
    [os [environ]]
    [os.path [join]]
    [logging [getLogger basicConfig DEBUG INFO]])

(setv log (getLogger))

(def *store-path* (get environ "CONTENT_PATH"))

(def *static-path* (get environ "STATIC_PATH"))

(def *page-route-base* "/space")

(def *page-media-base* "/media")

(def *home-page* (+ *page-route-base* "/HomePage"))

(def *debug-mode* true)

(def *aliasing-chars* [" " "." "-" "_"])

(def *aliasing-page* "meta/Aliases")

(def *base-types*
    {".txt"      "text/plain"
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
    (apply basicConfig [] {"level" DEBUG})
    (apply basicConfig [] {"level" INFO}))
