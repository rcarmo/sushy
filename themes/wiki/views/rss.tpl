<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
<channel>
<title>{{site_name}}</title>
<link>{{base_url}}</link>
<description>{{site_description}}</description>
<copyright>{{site_copyright}}</copyright>
<ttl>{{feed_ttl}}</ttl>
<pubDate>{{pubdate}}</pubDate>
<lastBuildDate>{{pubdate}}</lastBuildDate>
<generator>sushy</generator>
%for item in items:
<item>
<title>{{item["title"]}}</title>
<link>{{base_url}}{{page_route_base}}/{{item["pagename"]}}</link>
<description>{{item["description"]}}</description>
<pubDate>{{item["pubdate"]}}</pubDate>
<author>{{item["author"]}}</author>
<source url="{{base_url}}">{{site_name}}</source>
<guid isPermaLink="false">{{base_url}}{{page_route_base}}/{{item["pagename"]}}</guid>
<category>{{item["category"]}}</category>
</item>
%end
</channel>
</rss>
