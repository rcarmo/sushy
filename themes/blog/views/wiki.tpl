<%
from sushy.utils import utc_date
from sushy.models import *
from re import match

def fuzzy_time(date):
    intervals = {
        '00:00-00:59': 'late night',
        '01:00-03:59': 'in the wee hours',
        '04:00-06:59': 'at dawn',
        '07:00-08:59': 'during breakfast',
        '09:00-12:29': 'in the morning',
        '12:30-14:29': 'at lunchtime',
        '14:30-16:59': 'in the afternoon',
        '17:00-17:29': 'at tea-time',
        '17:30-18:59': 'at late afternoon',
        '19:00-20:29': 'in the evening',
        '20:30-21:29': 'at dinnertime',
        '21:30-22:29': 'at night',
        '22:30-23:59': 'late night'
    }
    when = date.strftime("%H:%M")
    for i in intervals.keys():
        (l,u) = i.split('-')
        if l <= when and when <= u:
            return intervals[i]
        end
    end
    return "sometime"
end

if "from" in headers:
    metadata = headers["from"]
else:
    metadata = "Unknown"
end

if "date" in headers:
    post_date = utc_date(headers["date"], "")
    if post_date != "":
      metadata = metadata + " - %s, %s" % (post_date.strftime("%B %d, %Y"), fuzzy_time(post_date))
    end
end
%>

<div class="container content">
    <h1 class="post-title">{{!headers["title"]}}</h1>
    <span class="post-date"> By {{!metadata}}</span>
    <hr>
    <section id="main">
    {{!body}}
    </section>
</div>
<div class="pagination">
<%

pattern = "^(blog|links)/.+$"
if match(pattern, pagename):
    p, n = get_prev_by_date(pagename, pattern), get_next_by_date(pagename, pattern)
else:
    p, n = get_prev_by_name(pagename), get_next_by_name(pagename)
end

if p:
%>
<span class="pagination-item older">
&laquo; <em>Previous:</em> <a href="{{base_url + page_route_base + "/" + p["name"]}}">{{!p["title"]}}</a>
</span>
<%
end

if n:
%>
<span class="pagination-item newer">
<em>Next:</em> <a href="{{base_url + page_route_base + "/" + n["name"]}}">{{!n["title"]}}</a> &raquo; 
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