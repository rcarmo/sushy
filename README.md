# Sushy

A wiki/blogging engine with a static file back-end. 

Demo site: <a href="http://sushy.no-bolso.com">http://sushy.no-bolso.com</a>.

## Status

Currently working out-of-the box, with full-text indexing and markup support already in place. Deployable to [Dokku][dokku]/[Heroku][heroku].

Coming up next are my trademark HTTP tweaks and a number of navigation features:

### Roadmap

* HTTP caching (`Etag`, `Last-Modified`, `HEAD` support, etc.)
* Internal link tracking (`SeeAlso` functionality, as seen on [Yaki][y])
* Blog homepage/excerpts/archive navigation
* RSS feeds
* Image thumbnailing
* Site thumbnailing (for taking screenshots of external links)
* Docker deployment (currently using [fig][fig] for development and deploying on [Dokku][dokku], so this will be merely another iteration.

### Done

* Deployable under [uWSGI][uwsgi]
* Full-text indexing and search
* Syntax highlighting for inline code samples
* [Ink][ink]-based site layout and templates
* Baseline markup rendering (Textile, Markdown and ReST)

### Stuff that will never happen:

* Web-based UI for editing pages (you're supposed to do this off-band)
* Revision history (you're supposed to manage your content with [Dropbox][db] or `git`)
* Commenting

## FAQ

### Why?

I've been running a classical, OO-based Python Wiki (called [Yaki][y]) for the better part of a decade. It works, but it is comparatively big and has become unwieldy and cumbersome to tweak. So I decided to [rewrite it][tng]. [Again][gae]. And [again][clj].

### Why [Hy][hy]?

Because I've been doing a lot of Clojure lately for my other personal projects, and both the LISP syntax and functional programming style feel quite natural to me.

I thought long and hard about doing this in Clojure instead (and in fact have been poking at an [implementation][clj] for almost a year now), but the Java libraries for Markdown and Textile have a bunch of irritating little corner cases and I wanted to make sure all my content would render fine the first time, plus Python has an absolutely fantastic ecosystem that I am deeply into.

Then [Hy][hy] came along, and I realized I could have my cake and eat it too. Also, it helps make the codebase exceedingly compact and easy to maintain.

### Can this do static sites?

I've used a fair amount of static site generators, and they all come up short on a number of things (namely trivially easy updates that don't involve re-generating hundreds of tiny files and trashing the filesystem) -- which, incidentally, is one of the reasons why Sushy relies on a single SQLite file for temporary data.

But there's no reason why this can't be easily modified to pre-render and save the HTML content after indexing runs -- pull requests to do that are welcome.

## Requirements

Thanks to [Hy][hy], this should run just as well under Python 2 and Python 3. My target environment is 2.7.8/PyPy, though, so your mileage may vary.

## Usage

### Principles of Operation

* All your Textile, Markdown or ReStructured Text content lives in a filesystem tree, with a folder per page
* Sushy grabs and renders those on demand with fine-tuned HTTP headers (this is independently of whether or not you put Varnish or CloudFlare in front for caching)
* It also maintains a SQLite database with a full-text index of all your content (because I need this for private wikis), updated live upon file changes.

### Configuration

In accordance with the [12 Factor][12] approach, runtime configuration will be taken from environment variables:

* `CONTENT_PATH` - the folder your documents live in
* `STATIC_PATH`  - static asset path (JS/CSS/etc.)
* `BIND_ADDRESS` - IP address to bind the development server to
* `HTTP_PORT`    - TCP port to bind the develoment server to

(more to come)

### Trying it out

```
# install dependencies
make deps
# run the indexing daemon (updates upon file changes)
make index-watch &
# run the standalone server (or uwsgi)
make serve
```

### Markup Support

Sushy supports plaintext, HTML and Textile for legacy reasons, and Markdown as its preferred format. ReStructured Text is also supported, but since I don't use it for anything (and find it rather a pain to read, let alone write), I can't make any guarantees as to its reliability.

All markup formats MUST be preceded by "front matter" handled like RFC2822 headers (see the `pages` folder for examples and test cases). Sushy uses the file extension to determine a suitable renderer, but that can be overriden if you specify a `Content-Type` header (see `config.hy` for the mappings).

[heroku]: https://www.heroku.com/
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
