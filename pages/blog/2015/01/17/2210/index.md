From: Rui Carmo
Date: 2015-01-17 22:10:00
Title: Implemented See Also

After a few shenanigans, finally found the time to implement the "See Also"/related pages feature. 

In short, wiki pages can now display a list of other pages linking to them, in the grand tradition of wikis like [E2][e2].

That list doesn't include pages that the current page links _to_ (which is a departure from what I had earlier implemented in [Yaki][y]) but that is trivial to add later if necessary (and I intend to revisit this someday using `nltk` for my own uses).

The main challenge here was, as usual, making it look halfway decent on a browser -- I decided to stick to the usual gradient table, but went with `table-cell` and a little inline JavaScript to paint and resize the cells on the client side. The result is not _completely_ responsive, but seems to work well enough.

In preparation for the next set of features (which is going to include blog archives and so forth), I'm now adding development notes to the sample content.

[y]: https://github.com/rcarmo/Yaki
[e2]: http://everything2.com