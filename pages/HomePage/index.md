From: Rui Carmo
Title: Welcome to Sushy
Date: Sun Feb 18 16:15:00 2007
Last-Modified: 2014-11-02 22:30:00
X-Index: no
X-Cache-Control: max-age=600

## What is this?

Sushy is a wiki engine that runs off static files, rendering them on the fly to enriched HTML.

## Principles of Operation

* All your Textile, Markdown or ReStructured Text content lives in a filesystem tree, with a folder per page (if you use [Jekyll][j], you should be able to drop in your current content with minimal tweaks)
* Sushy grabs and renders those on demand with fine-tuned HTTP headers (assuming you do the sane thing and put Varnish or CloudFlare in front for caching)
* It also maintains a SQLite database with a full-text index of all your content (because I need this for private wikis).

## [Documentation](docs)

Sushy is (naturally) [self-documenting](docs).

## Demo Content

There is a set of [formatting tests](tests) you can look at to get a feel for the way things work.

[j]: http://jekyllrb.com