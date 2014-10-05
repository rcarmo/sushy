From: Rui Carmo
Date: 2013-07-06 23:33:00
Title: Syntax Highlighting Tests
Index: no

## Inline [Markdown][m]

The standard [Markdown][m] triple-backquote form.

```clojure
; parallel consumption of perishable resources
(defn foo [bar drinks]
    (pmap (:patrons bar) (lazy-seq drinks)))
```

## PRE tag with `syntax` attribute

This is meant for non-[Markdown][m] content.

<pre syntax="python">
from bottle import view, request, abort

@view("rss")
def render_feed()
    if not items:
        abort("418", "I'm a teapot")
    else:
        return {"items": items}
</pre>

## From file via `src` attribute

This slurps the file into the document and highlights it:

<pre syntax="javascript" src="animate_svg.js"></pre>

## From missing file via `src` attribute

This should show a nice error message.

<pre syntax="javascript" src="no_file.txt"></pre>

[m]: Wikipedia:Markdown
