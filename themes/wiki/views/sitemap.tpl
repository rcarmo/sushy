<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
% for item in items:
<url>
<loc>{{base_url}}{{page_route_base}}/{{item["name"]}}</loc>
<lastmod>{{item["mtime"].isoformat()}}+00:00</lastmod>
</url>
% end
</urlset>
