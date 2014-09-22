# Why?

I've been running a classical, OO-based Python CMS for the better part of a decade. It worked, but it was comparatively big, unwieldy and cumbersome to tweak.

## Why Hy?

I've been doing a lot of Clojure lately for my other personal projects. I thought long and hard about doing this in Clojure instead (and in fact have been poking at an implementation for almost a year now), but the Java libraries for Markdown and Textile had a bunch of little irritating corner cases and there was little to be gained in terms of performance for something like this.

# Can this do static sites?

Although it's not the way I use it, I tried to make sure it could be easily modified to do so.


# Configuration

* `CONTENT_ROOT`
* `BASE_PREFIX`

