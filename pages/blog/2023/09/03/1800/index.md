---
From: Rui Carmo
Date: 2023-09-03 18:00:00
Title: Hy 0.27 (aka 2023 edition)
Tags: development, hylang, refactoring
---

And so it came to pass that, almost nine years since I decided to try out [Hy] to manage my site and seven to eight years after I decided to move away from it into "vanilla" [Python], it struck my fancy to take the old codebase and refactor it to use "modern" [Hy], which I did piecemeal over a week or so by the beach.

I did it partially because I was doing some [Scheme], partially because I had a few other pieces of code I wanted to refactor, and partially because having the repository sitting there on GitHub, seemingly abandoned, was an itch I've been meaning to scratch for a while.

## Annoyances

First of all, it should be said that [Hy] has had breaking changes pretty much every release. A few of them have to deal with the decision to move some of the most useful things into a separate `hyrule` library, but others cut a little deeper 
(the removal of staples like `let` was a big reason why I moved off it a few years back, but it didn't stop there). The `->` threading macro and `assoc` (which greatly simplified a few things) were easy enough to recoup, but all the other little semantic changes took a while.

[Python] has also moved on, but even though the 1:1 correspondence between the original [Hy] code and my current site generator has eroded, the bits that matched were still quite similar, and I could reference them when some quirky bugs surfaced.

But if you're stepping into [Hy] now, let me give you a list of things I had to fix:

* For some unfathomable reason, `if` needs to have two expressions, so I had to change a bunch of them to `when` conditionals.
* `let` returned, but without delimiters between bindings: `(let [one 1 two 2] ...)` instead of `(let [[one 1] [two 2]] ...)`, which is arguably an improvement
* `import` (and `require`) also similarly changed structure
* `nil` and booleans had to be translated into their [Python] norms.
* `*earmuffs*` and associated symbol mapping changed, so I had to get rid of those too.
* `setv` replaced `def`. I nearly defined a `set!` macro to make it feel more natural, but decided against it and plowed on.
* [Python] tuples are now `#("like" "this")` instead of `(, "like" "that")` (also an improvement, but... annoying)
* `&rest` and optional argument syntax changed, as did referencing `#* args` and `#** kwargs`
* Keyword handling for `kwargs` became `:slightly "better"`, but, annoyingly, `dict` keys can't be used in the same way

Fortunately I wasn't writing [Clojure] or [Janet] at the same time (just [Scheme]), otherwise things would have been weirder (especially considering I did this mostly in the dead of night before dozing off).

So the code now _generally_ works and can serve a working site, although there are a few edge cases with `UTF-8` I'm squashing as I step through the test pages I (luckily) wrote almost a decade ago. Also, I've apparently broken a couple of `Pillow` calls (every other dependency just works, which is interesting).

This has been a fun thing to revisit, although I'm rather curious about what would have happened if I had used [Scheme] instead...

[Python]: dev/python
[Clojure]: dev/clojure
[Janet]: dev/janet
[Scheme]: dev/lisp
[Hy]: http://hylang.org
