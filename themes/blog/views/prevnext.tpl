<%
from sushy.models import get_prev_next
pattern = "^(blog|links)/.+$"
if not ('tags' in headers and 'meta' not in headers['tags']):
%>
<div class="pagination">
<%
p, n = get_prev_next(pagename, pattern)
if p:
%>
<span class="pagination-item older">
&#8592;&nbsp;<a href="{{base_url + page_route_base + "/" + p["name"]}}">{{!p["title"]}}</a>
</span>
<%
end
if n:
%>
<span class="pagination-item newer">
<a href="{{base_url + page_route_base + "/" + n["name"]}}">{{!n["title"]}}</a>&nbsp;&#8594;
</span>
<%
end
%>
</div>
<%
end
%>