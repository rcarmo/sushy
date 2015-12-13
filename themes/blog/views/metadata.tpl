% if "x-link" in headers:
    <h1 class="post-title"><a href="{{!headers["x-link"]}}" title="external link to {{!headers["x-link"]}}">{{!headers["title"]}}</a>&nbsp;<a class="permalink-marker" href="{{base_url + page_route_base + "/" + pagename}}" title="permanent link to {{!headers["title"]}}">&#8251;</a></h1>
% else:
    <h1 class="post-title"><a href="{{base_url + page_route_base + "/" + pagename}}" title="permanent link to {{!headers["title"]}}">{{!headers["title"]}}</a> </h1>
% end
    <span class="post-date"> By {{!metadata}}</span>
    <hr>
