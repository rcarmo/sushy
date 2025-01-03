<%
import re
from sushy.models import get_prev_next
from sushy.config import BLOG_ENTRIES
if 'meta' not in headers.get('tags',''):
%>
<div class="pagination">
<%
p, n = get_prev_next(pagename, BLOG_ENTRIES)
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