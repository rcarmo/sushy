From: Rui Carmo
Date: 2014-11-03 19:09:00
Last-Modified: 2014-12-29 11:15:00
Title: Internals

<img src="hy.png" style="float:left; width: 120px; height: auto;">
## Hy

Sushy is written in [Hy][hy], a [LISP][lisp] dialect that compiles to [Python][python] bytecode -- in effect, [Python][python] in fancy dress, chosen due to its conciseness and seamless integration with [Python][python] libraries.

The following is a short description of each module.

---

### `app`

This is a simple WSGI entry point, doing double duty as a [Bottle][b]-based develpment server.

### `config`

The `config` module is (predictably) where Sushy is configured. Most configurable options come from environment variables, but some conventions like URL routes, meta pages and ignored folders are set there.

### `indexer`

Like its name entails, the `indexer` module handles full-text and link indexing.

### `models`

This is the only "pure" [Python][python] module. Its main purpose is to encapsulate database setup and access (which use the `peewee` ORM) into a small set of functional primitives.

### `render`

This simply imports and abstracts away all markup processors, providing a single rendering function.

### `routes`

URL routes and HTTP request handling, again courtesy of [Bottle][b].

### `render`

The `render` module encapsulates all the markup renderers, providing a uniform API for them.

### `store`

The `store` module provides functions to find, retrieve and parse raw page markup and front matter.

### `transform`

This performs all the HTML transformations that turn the rendered markup into actual Wiki pages, reformatting links and other tags.

### `utils`

This is a small grab bag of utility functions (some of which are straight ports from my [utilities library][utils]).


[hy]: http://hylang.org
[lisp]: Wikipedia:LISP
[python]: http://python.org
[utils]: https://github.com/rcarmo/python-utils
[b]: http://bottlepy.org

