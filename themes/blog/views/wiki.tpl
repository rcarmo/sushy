<%
from sushy.models import get_prev_next
# Patterns for time-based navigation and namespace

pattern = "^(blog|links)/.+$"
namespace = pagename.split("/")[0].lower()
%>
<div class="container content">
%include('metadata', **include('common'))
    <section id="main" class="{{!namespace}}-namespace">
    {{!body}}
    </section>
</div>
<div class="pagination">
<%
p, n = get_prev_next(pagename, pattern)
if p:
%>
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
