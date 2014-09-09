(import
    [logging [getLogger DEBUG INFO]])

(setv log (getLogger))

(def *page-path* "/space")

(def *home-page* (+ *page-path* "/HomePage"))

(def *debug-mode* true)

(def *ignored-folders* [".hg" ".git"])

(def *aliasing-chars* [" " "." "-" "_"])

(def *base-types*
    {"txt"      "text/plain"
     "html"     "text/html"
     "htm"      "text/html"
     "md"       "text/x-markdown"
     "mkd"      "text/x-markdown"
     "mkdn"     "text/x-markdown"
     "markdown" "text/x-markdown"
     "textile"  "text/x-textile"})
     
(def *base-filenames*
    (list-comp (% "index.%s" t) [t (.keys *base-types*)]))

(def *base-page* "From: %(author)s\nDate: %(date)s\nContent-Type: %(markup)s\nContent-Encoding: utf-8\nTitle: %(title)s\nKeywords: %(keywords)s\nCategories: %(categories)s\nTags: %(tags)s\n%(_headers)s\n\n%(content)s")

(def *ignored-folders* ["CVS" ".hg" ".svn" ".git" ".AppleDouble"])

(if *debug-mode*
    (.setLevel log DEBUG)
    (.setLevel log INFO))
    
