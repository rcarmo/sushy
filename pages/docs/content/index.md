From: Rui Carmo
Date: 2014-10-04 09:10:00
Title: Writing Content for Sushy

## Syntax Highlighting

Sushy supports highlighting source code blocks in two ways:

* Using triple-quoted Markdown blocks
* Using `pre` tags with a `syntax` attribute (available to all markup languages)

You can also optionally set a `src` attribute on your `pre` tags to reference an additional file, which makes it a lot easier to maintain complex articles:

```html
<pre src="foo.js" syntax="javascript"/>
```
