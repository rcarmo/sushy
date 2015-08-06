<%
from sushy.utils import utc_date
from sushy.models import get_prev_next
from re import match

# Helper functions only used for formatting

def ordinal(num):
    if 10 <= num % 100 <= 20:
        suffix = 'th'
    else:
        suffix = {1: 'st', 2: 'nd', 3: 'rd'}.get(num % 10, 'th')
    end
    return str(num) + "<sup>" + suffix + "</sup>"
end

def fuzzy_time(date):
    intervals = {
        '00:00-00:59': 'late night',
        '01:00-04:59': 'in the wee hours',
        '05:00-06:59': 'at dawn',
        '07:00-08:59': 'at breakfast',
        '09:00-12:29': 'in the morning',
        '12:30-14:29': 'at lunchtime',
        '14:30-16:59': 'in the afternoon',
        '17:00-17:29': 'at teatime',
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

# Patterns for time-based navigation and namespace

pattern = "^(blog|links)/.+$"
namespace = pagename.split("/")[0].lower()

if "from" in headers:
    author = headers["from"]
else:
    author = "Unknown"
end

if "date" in headers:
    post_date = utc_date(headers["date"], "")

    if post_date != "":
         metadata = author + " - %s %s %d, %s" % (post_date.strftime("%B"), ordinal(post_date.day), post_date.year, fuzzy_time(post_date))
    end

    if not match(pattern, pagename) and "last-modified" in headers:
        post_date = utc_date(headers["last-modified"], "")
        if post_date != "":
            metadata = author + " - last updated on %s %s %d, %s" % (post_date.strftime("%B"), ordinal(post_date.day), post_date.year, fuzzy_time(post_date))
        end
    end
end
%>

<div class="container content">
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
