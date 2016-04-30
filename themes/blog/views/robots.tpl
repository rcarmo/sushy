Sitemap: {{base_url}}/sitemap.xml

% for nuisance in ["MJ12bot", "Covario-IDS", "TopBlogsInfo", "spbot", "attributor", "psbot", "SiteSucker", "Scooter", "ZyBorg", "Slurp", "Pompos", "inetbot"]:
User-agent: {{nuisance}}
Disallow: /

% end

% for legit in ["Google", "ia_archiver"]:
User-agent: {{legit}}
Disallow: /js/
Disallow: /themes/
Disallow: /space/meta/

% end

User-agent: *
Disallow: /js/
Disallow: /img/
Disallow: /themes/
Disallow: /media/
Disallow: /thumbnail/
Disallow: /space/meta/
