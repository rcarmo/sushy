---
Title: 2024 Edition
From: Rui Carmo
Date: 2024-03-24 21:35:00
Last-modified: 2024-03-29 20:18:00
Tags: development, testing, notes
---

Had a few minutes to check the current status quo. `hy` hasn't had a new release in almost a year and moving from Python 3.9 to 3.11 had minimal impact, so I guess it's time to do some more fixing and see if this can be turned back into a "production" Wiki engine.

I also fixed time references in search, removed `.ipynb` and `.rst` support (I had zero practical use for that over the years) and fixed a few uses of `apply` that are not required anymore, as well as hunting down some errant uses of the old `tuple` syntax.
