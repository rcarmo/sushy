---
from: Rui Carmo
date: 2024-09-05 23:22:00
title: Hy 0.29.0
tags: hylang, breakage, dependencies, updates
---

And _of course_ `hy` 0.29.0 had to come out and subtly break every single piece of recent code I wrote in it _yet again_, which kind of makes keeping this codebase updated a pointless exercise. I really wish they'd stop messing with the syntax, especially for `async` stuff.

Still, thankfully I hadn't really converted this to `aiohttp` yet, so most of the stuff on GitHub wasn't broken. But I still needed to upgrade the dependencies and try to modernize a few other things--like looking at GitHub-flavored Markdown as a default format.
