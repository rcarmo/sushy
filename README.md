## Sushy

A wiki engine that runs off static files.


## Status

Currently putting together the basics of content storage and rendering. No nice templating yet.

## Why?

I've been running a classical, OO-based Python Wiki (called [Yaki][y]) for the better part of a decade. It works, but it is comparatively big and has become unwieldy and cumbersome to tweak. So I decided to [rewrite it][tng]. [Again][gae]. And [again][clj].

## Why [Hy][hy]?

Essentially because I've been doing a lot of Clojure lately for my other personal projects, and both the LISP syntax and functional programming style feel quite natural to me.

I thought long and hard about doing this in Clojure instead (and in fact have been poking at an [implementation][clj] for almost a year now), but the Java libraries for Markdown and Textile have a bunch of irritating little corner cases and I wanted to make sure all my content would render fine the first time, plus Python has an absolutely fantastic ecosystem that I am deeply into.

Then [Hy][hy] came along, and I realized I could have my cake and eat it too.

## Can this do static sites?

Although it's not the way I use it, there's no reason why it can't be easily modified to do so.

## Requirements

Thanks to [Hy][hy], this should run just as well under Python 2 and Python 3. My target environment is 2.7.8/PyPy, though, so your mileage may vary.

## Principle of Operation

* All your Textile or Markdown content lives in a filesystem tree, with a folder per page
* Sushy grabs and renders those on demand with fine-tuned HTTP headers (assuming you do the sane thing and put Varnish or CloudFlare in front for caching)
* It also (optionally) maintains a SQLite database with a full-text index of all your content (because I need this for private wikis).

## Configuration

In accordance with the [12 Factor][12] approach, runtime configuration will be taken from environment variables:

* `CONTENT_PATH` - the folder your documents live in

(more to come)

## Trying it out

```
make serve
```


[12]: http://12factor.net/
[hy]: http://hylang.org
[y]: https://github.com/rcarmo/Yaki
[tng]: https://github.com/rcarmo/yaki-tng
[gae]: https://github.com/rcarmo/yaki-gae
[clj]: https://github.com/rcarmo/yaki-clj
