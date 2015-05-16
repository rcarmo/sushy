<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
<title>{site_name}</title>
<link>{base_url}</link>
<description>{site_description}</description>
<copyright>{site_copyright}</copyright>
<ttl>{feed_ttl}</ttl>
<pubDate>{pubdate}</pubDate>
<lastBuildDate>{pubdate}</lastBuildDate>
<docs>http://blogs.law.harvard.edu/tech/rss</docs>
<generator>sushy</generator>
%for item in items:
<item>
<title>{item["title"]}</title>
<link>http://taoofmac.com/space/links/2015/05/14/1743</link>
<description>{item["body"]}</description>
<pubDate>{item["pubdate"]}</pubDate>
<author>{item["author"]}</author>
<source url="{base_url}">{site_name}</source>
<guid isPermaLink="false">{base_url}/{item["pagename"]}</guid>
<category>{item["category"]}</category>
</item>
%end
</channel>
</rss>
