[![Stories in Ready](https://badge.waffle.io/rcarmo/sushy.png?label=ready&title=Ready)](https://waffle.io/rcarmo/sushy)

# Sushy

A wiki/blogging engine with a static file back-end. 

Demo site: <a href="http://sushy.no-bolso.com">http://sushy.no-bolso.com</a>.

## Status

Currently working out-of-the box, with full-text indexing and markup support already in place. Deployable _now_ to [Dokku-alt][da]/[Dokku][dokku]/[Heroku][heroku].

### Roadmap

* Page aliasing (i.e., multiple URLs for a page)
* Closest-match URLs (i.e., fix typos)
* HTTP caching (`Etag`, `Last-Modified`, `HEAD` support, etc.)
* Blog homepage/excerpts/archive navigation
* RSS feeds
* CSS inlining for RSS feeds
* Sitemap
* Image thumbnailing
* Site thumbnailing (for taking screenshots of external links)
* Docker deployment (currently deploying on [Dokku-alt][da] using a `Procfile`, waiting for the dust to settle to build a proper reference container)

### Done

* `multiprocessing`-based indexer
* SSE (Server-Sent Events) support for notifying visitors a page has changed
* [New Relic][nr] Support
* Internal link tracking (`SeeAlso` functionality, as seen on [Yaki][y])
* Multiple theme support (only the one theme for now)
* Automatic insertion of image sizes in `img` tags
* Deployable under [Dokku-alt][da]
* Run under [uWSGI][uwsgi] using `gevent` workers
* Full-text indexing and search
* Syntax highlighting for inline code samples
* [Ink][ink]-based site layout and templates
* Baseline markup rendering (Textile, Markdown and ReST)

### Stuff that will never happen:

* Web-based UI for editing pages (you're supposed to do this out-of-band)
* Revision history (you're supposed to manage your content with [Dropbox][db] or `git`)
* Commenting

### Principles of Operation

* All your Textile, Markdown or ReStructured Text content lives in a filesystem tree, with a folder per page
* Sushy grabs and renders those on demand with fine-tuned HTTP headers (this is independently of whether or not you put Varnish or CloudFlare in front for caching)
* It also maintains a SQLite database with a full-text index of all your content - updated live as you add/edit content.

### Markup Support

Sushy supports plaintext, HTML and Textile for legacy reasons, and Markdown as its preferred format. ReStructured Text is also supported, but since I don't use it for anything (and find it rather a pain to read, let alone write), I can't make any guarantees as to its reliability.

All markup formats MUST be preceded by "front matter" handled like RFC2822 headers (see the `pages` folder for examples and test cases). Sushy uses the file extension to determine a suitable renderer, but that can be overriden if you specify a `Content-Type` header (see `config.hy` for the mappings).

# FAQ

## Why?

I've been running a classical, object-oriented Python Wiki (called [Yaki][y]) for the better part of a decade. It works, but is comparatively big and has become unwieldy and cumbersome to tweak. So I decided to [rewrite it][tng]. [Again][gae]. And [again][clj].

And I eventually decided to make it _smaller_ -- my intention is for the core to stop at around 1000 lines of code (as of this writing, it is a tad larger, mostly due to indexing optimizations) excluding templates, so this is also an exercise in building tight, readable (and functional) code.

### Why [Hy][hy]?

Because I've been doing a lot of Clojure lately for my other personal projects, and both the LISP syntax and functional programming style are quite natural to me.

I thought long and hard about doing this in Clojure instead (and in fact have been poking at an [implementation][clj] for almost a year now), but the Java libraries for Markdown and Textile have a bunch of irritating little corner cases and I wanted to make sure all my content would render fine the first time, plus Python has an absolutely fantastic ecosystem that I am deeply into.

Then [Hy][hy] came along, and I realized I could have my cake and eat it too.

## Can this do static sites?

I've used a fair amount of static site generators, and they all come up short on a number of things (namely trivially easy updates that don't involve re-generating hundreds of tiny files and trashing the filesystem) -- which, incidentally, is one of the reasons why Sushy relies on a single SQLite file for temporary data.

But there's no reason why this can't be easily modified to pre-render and save the HTML content after indexing runs -- pull requests to do that are welcome.

## Requirements

Thanks to [Hy][hy], this should run just as well under Python 2 and Python 3. My target environment is 2.7.8/PyPy, though, so your mileage may vary. Check the `requirements.txt` file - I've taken pains to make sure dependencies are there _for a reason_ and not just because they're trendy.

# Deployment

This repository is deployable as-is on [Dokku-alt][da], and will instantiate a production-ready [uWSGI][uwsgi] server (using `gevent`) and a background indexing worker. 

Vanilla [Dokku][dokku] may work as well with the `foreman` plugin, but I haven't tested it.

As is (for development) the content ships with the code repo. Changing things to work off a separate mount point (or a shared container volume) is trivial.

## Configuration

In accordance with the [12 Factor][12] approach, runtime configuration is taken from environment variables:

* `DEBUG`        - Enable debug logs
* `PROFILER`     - Enable `cProfile` statistics (will slow down things appreciatively)
* `CONTENT_PATH` - the folder your documents live in
* `THEME_PATH`   - path under which static assets (JS/CSS/etc.)
and templates/views are stored
* `BIND_ADDRESS` - IP address to bind the development server to
* `PORT` - TCP port to bind the server to
* `NEW_RELIC_LICENSE_KEY` - If set, the New Relic agent is enabled

These are set in the `Makefile` (which I use for a variety of purposes).

## Trying it out

```
# install dependencies
make deps
# run the indexing daemon (updates upon file changes)
make index-watch &
# run the standalone server (or uwsgi)
make serve
```

[heroku]: https://www.heroku.com/
[da]: http://dokku-alt.github.io
[dokku]: https://github.com/progrium/dokku
[fig]: http://www.fig.sh
[12]: http://12factor.net/
[hy]: http://hylang.org
[y]: https://github.com/rcarmo/Yaki
[tng]: https://github.com/rcarmo/yaki-tng
[gae]: https://github.com/rcarmo/yaki-gae
[clj]: https://github.com/rcarmo/yaki-clj
[ink]: http://ink.sapo.pt
[uwsgi]: https://github.com/unbit/uwsgi
[db]: http://www.dropbox.com
[nr]: http://www.newrelic.com
