<%
from sushy.utils import utc_date
from sushy.models import get_next_page, get_prev_page

def fuzzy_time(date):
    intervals = {
        '00:00-00:59': 'late night',
        '01:00-03:59': 'in the wee hours',
        '04:00-06:59': 'by dawn',
        '07:00-08:59': 'breakfast',
        '09:00-12:29': 'morning',
        '12:30-14:29': 'lunchtime',
        '14:30-16:59': 'afternoon',
        '17:00-17:29': 'tea-time',
        '17:30-18:59': 'late afternoon',
        '19:00-20:29': 'evening',
        '20:30-21:29': 'dinnertime',
        '21:30-22:29': 'night',
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
      metadata = metadata + " - %s (%s)" % (post_date.strftime("%B %d, %Y, %H:%M"), fuzzy_time(post_date))
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
<div class="container related">
<%
p, n = get_prev_page(pagename), get_next_page(pagename)

if p:
%>
<span class="left">
&laquo; <em>Previous:</em> <a href="{{base_url + page_route_base + "/" + p["name"]}}">{{!p["title"]}}</a>
</span>
<%
end

if n:
%>
<span class="right">
<em>Next:</em> <a href="{{base_url + page_route_base + "/" + n["name"]}}">{{!n["title"]}}</a> &raquo; 
</span>
<%
end
%>
</div>
<div class="container">
%include('seealso')
</div>
%rebase('layout', **dict(globals()))