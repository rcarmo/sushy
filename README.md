# Sushy

A wiki/blogging engine with a static file back-end, full-text indexing and multiple markup support.

This was formerly the site engine for [`taoofmac.com`](https://taoofmac.com) [circa 2015](https://taoofmac.com/space/blog/2015/02/01/1930) until I decided to [switch back](https://taoofmac.com/space/blog/2018/07/08/1330) to pure Python for maintainability. 

## Status

Many years later, I've decided to at least clean up the legacy codebase and bring it up to date. Once done, it should again be deployable to [`piku`][piku]/[Dokku-alt][da]/[Dokku][dokku]/[Heroku][heroku].

The goal is to make it run on the <strike>2023</strike> 1.0.0 version of Hylang, which was finally released in September 22<sup>nd</sup> 2024.

### Roadmap

* [ ] Add a new layout and CSS (the current one is a bit dated)
* [ ] Switch as much as possible to `aiohttp` so we can leverage `uvloop` fully.
* [x] Fix all the various breaking syntax changes that the `Hy` project has gone through in the past few years (I keep resetting this one because they keep changing things)
* [ ] A little more documentation (there's never enough)
* [ ] Blog archive and partial feature parity with the current `taoofmac.com` site engine
* [ ] End-to-end syntax and linting checks
* [ ] Fix link and image handling, which require some tweaks
* [x] Working decorators and HTTP serving with the 2023 versions of `Hy`
* [x] Removed `*earmuffs*` in favor of standard Python constants, because `Hy` now handles those differently 
* [x] (Mostly) working indexing with the 2023 versions of `Hy`
* [x] Page aliasing (i.e., multiple URLs for a page)
* [x] Image thumbnailing
* [x] Friendlier search results
* [x] More CSS tweaks
* [x] Atom feeds
* [x] [`piku`][piku] deployment
* [x] Blog homepage/prev-next navigation
* [x] Preliminary support for rendering IPython notebooks
* [x] <strike>Closest-match URLs (i.e., fix typos)</strike> (removed for performance concerns on large sites)
* [x] HTTP caching (`Etag`, `Last-Modified`, `HEAD` support, etc.)
* [x] Sitemap
* [x] OpenSearch support (search directly from the omnibar on some browsers)
* [x] CSS inlining for Atom feeds
* [x] `multiprocessing`-based indexer (in `feature/multiprocessing`, disabled for ease of profiling)
* [x] SSE (Server-Sent Events) support (in `feature/server-events`) for notifying visitors a page has changed 
* [x] [New Relic][nr] Support
* [x] Internal link tracking (`SeeAlso` functionality, as seen on [Yaki][y])
* [x] Multiple theme support (only the one theme for now)
* [x] Automatic insertion of image sizes in `img` tags
* [x] Deployable under [Dokku-alt][da]
* [x] Run under [uWSGI][uwsgi] using `gevent` workers
* [x] Full-text indexing and search
* [x] Syntax highlighting for inline code samples
* [x] [Ink][ink]-based site layout and templates (replaced by a new layout in the `feature/blog` branch)
* [x] Baseline markup rendering (Textile, Markdown and ReST)

### Stuff that will never happen:

* <strike>Site thumbnailing (for taking screenshots of external links)</strike> - moved to a separate app
* <strike>Web-based UI for editing pages</strike> (you're supposed to do this out-of-band)
* <strike>Revision history</strike> (you're supposed to manage your content with [Dropbox][db] or `git`)
* <strike>Comment support</strike>

---

# Principles of Operation

* All your Textile, Markdown or ReStructured Text content lives in a filesystem tree, with a folder per page
* Sushy grabs and renders those on demand with fine-tuned HTTP headers (this is independently of whether or not you put Varnish or CloudFlare in front for caching)
* It also maintains a SQLite database with a full-text index of all your content - updated live as you add/edit content.

### Markup Support

Sushy supports plaintext, HTML and Textile for legacy reasons, and Markdown as its preferred format. <strike>ReStructured Text is also supported, but since I don't use it for anything (and find it rather a pain to read, let alone write), I can't make any guarantees as to its reliability. Work is ongoing for supporting Jupyter notebooks (which have no metadata/frontmatter conventions).</strike>

All markup formats MUST be preceded by "front matter" handled like RFC2822 headers (see the `pages` folder for examples and test cases). Sushy uses the file extension to determine a suitable renderer, but that can be overriden if you specify a `Content-Type` header (see `config.hy` for the mappings).

# FAQ

## Why?

I've been running a classical, object-oriented Python Wiki (called [Yaki][y]) for the better part of a decade. It works, but is comparatively big and has become unwieldy and cumbersome to tweak. So I decided to [rewrite it][tng]. [Again][gae]. And [again][clj].

And I eventually decided to make it _smaller_ -- my intention is for the core to stop at around 1000 lines of code excluding templates, so this is also an exercise in building tight, readable (and functional) code.

### Why [Hy][hy]?

Because I've been doing a lot of Clojure lately for my other personal projects, and both the LISP syntax and functional programming style are quite natural to me.

I thought long and hard about doing this in Clojure instead (and in fact have been poking at an [implementation][clj] for almost a year now), but the Java libraries for Markdown and Textile have a bunch of irritating little corner cases and I wanted to make sure all my content would render fine the first time, plus Python has an absolutely fantastic ecosystem that I am deeply into.

Then [Hy][hy] came along, and I realized I could have my cake and eat it too.

## Can this do static sites?

I've used a fair amount of static site generators, and they all come up short on a number of things (namely trivially easy updates that don't involve re-generating hundreds of tiny files and trashing the filesystem) -- which, incidentally, is one of the reasons why Sushy relies on a single SQLite file for temporary data.

But there's no reason why this can't be easily modified to pre-render and save the HTML content after indexing runs -- pull requests to do that are welcome.

## Requirements

Thanks to [Hy][hy], this should run just as well under Python 2 and Python 3. My target environment is 2.7.8/PyPy, though, so your mileage may vary. Check the `requirements.txt` file - I've taken pains to make sure dependencies are there _for a reason_ and not just because they're trendy.

---

# Deployment

This repository should be deployable on [piku][piku] (my featherweight version of [Heroku][heroku]), and also used to be deployable to [Dokku][dokku] -- this was removed in the 2023 refactoring since I don't use it anymore.

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

These are set in the `Makefile` (which I use for a variety of purposes).

---

## Trying it out

Make sure you have `libxml` and `libxslt` headers, as well as the JPEG library - the following is for Ubuntu 14.04:
```
sudo apt-get install libxml2-dev libxslt1-dev libjpeg-dev
# install dependencies
make deps
# run the indexing daemon (updates upon file changes)
make index-watch &
# run the standalone server (or uwsgi)
make serve
```
[piku]: https://github.com/rcarmo/piku
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
