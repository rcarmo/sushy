From: Rui Carmo
Date: 2013-07-06 23:33:00
Title: Syntax Highlighting Tests
Index: no

## Inline Markdown 

```clojure
(defn foo [bar]
    baz)
```

## PRE tag with `syntax` attribute

<pre syntax="python">
import foo

def bar()
    pass
</pre>

## From file via `src` attribute

<pre syntax="javascript" src="test.txt"></pre>

## From missing file via `src` attribute

<pre syntax="javascript" src="no_file.txt"></pre>
