Sitemap: {{base_url}}/sitemap.xml

% for nuisance in ["AhrefsBot", "BLEXBot", "MJ12bot", "Covario-IDS", "TopBlogsInfo", "spbot", "attributor", "psbot", "SemrushBot", "SemrushBot-SA", "SiteSucker", "Scooter", "ZyBorg", "Slurp", "Pompos", "inetbot", "Domain Re-Animator Bot"]:
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
