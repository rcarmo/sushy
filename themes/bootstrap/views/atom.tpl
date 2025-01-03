% from urllib import quote_plus
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
<title>{{site_name}}</title>
<subtitle>{{site_description}}</subtitle>
<link rel="alternate" type="text/xml" href="{{base_url}}"/>
<link rel="self" type="application/atom+xml" href="{{base_url}}/feed"/>
<id>{{base_url}}/feed</id>
<updated>{{pubdate.isoformat()}}</updated>
<rights>{{site_copyright}}</rights>
%for item in items:
% link = quote_plus(base_url + page_route_base + "/" + item["pagename"], safe="%/:=&?~#+!$,;'@()*[]")
% guid = link.replace("http://","")
<entry>
<title>{{item["title"]}}</title>
<id>{{link}}</id>
<published>{{item["pubdate"].isoformat()}}</published>
<updated>{{item["mtime"].isoformat()}}</updated>
<author>
<name>{{item["author"]}}</name>
<uri>{{base_url}}</uri>
</author>
<link rel="alternate" xml:base="{{base_url}}" type="text/html" href="{{link}}"/>
<content type="html"><![CDATA[
{{!item["description"]}}
]]></content>
%for tag in item['tags']:
% tag = tag.replace('tag:','')
<category term="{{tag}}" label="{{tag}}" />
%end
</entry>
%end
</feed>
