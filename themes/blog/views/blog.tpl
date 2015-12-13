<%
from sushy.utils import utc_date
from sushy.models import get_prev_next, get_latest
from re import match

pattern = "^(blog)/.+$"
namespace = pagename.split("/")[0].lower()

latest = get_latest(regexp=pattern)

if "from" in headers:
    author = headers["from"]
else:
    author = "Unknown"
end

metadata = author
%>

<div class="container content">
<%
for post in latest:
%>

% if "x-link" in headers:
    <h1 class="post-title"><a href="{{!headers["x-link"]}}" title="external link to {{!headers["x-link"]}}">{{!headers["title"]}}</a>&nbsp;<a class="permalink-marker" href="{{base_url + page_route_base + "/" + pagename}}" title="permanent link to {{!headers["title"]}}">&#8251;</a></h1>
% else:
    <h1 class="post-title"><a href="{{base_url + page_route_base + "/" + pagename}}" title="permanent link to {{!headers["title"]}}">{{!headers["title"]}}</a> </h1>
% end
    <span class="post-date"> By {{!metadata}}</span>
    <hr>
    <section id="main" class="{{!namespace}}-namespace">
    {{!body}}
    </section>
</div>
<div class="pagination">
<span class="pagination-item older">
&laquo;&nbsp;<em>Previous:</em> <a href="{{base_url + page_route_base + "/" + p["name"]}}">{{!p["title"]}}</a>
</span>
<%
end

if n:
%>
<span class="pagination-item newer">
<em>Next:</em> <a href="{{base_url + page_route_base + "/" + n["name"]}}">{{!n["title"]}}</a>&nbsp;&raquo;
</span>
<%
end
%>
</div>
<div class="container">
%include('seealso')
</div>
<%
scripts=["zepto.min.js"]
%>
%rebase('layout', **dict(globals()))
