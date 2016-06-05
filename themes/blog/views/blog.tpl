<%
from sushy.utils import utc_date
from sushy.models import get_prev_next, get_latest
from sushy.config import BLOG_ENTRIES
from sushy.render import render_page
from sushy.store import get_page
from sushy.transform import apply_transforms, inner_html, extract_lead_paragraph
from logging import getLogger
from re import match
from hy import HyKeyword

def k(s):
    return unicode(HyKeyword(':' + s))
end

log = getLogger()

namespace = pagename.split("/")[0].lower()

latest = list(get_latest(regexp=BLOG_ENTRIES))

log.debug("Got %d entries" % len(latest))
%>
<div class="container latest-content">
    
    <section id="latest-content">
<%
tags = []
first = True
for post in latest:
    pagename = post['name']
    page = get_page(pagename)
    headers = page[k('headers')]
    namespace = pagename.split("/")[0].lower()
    if "blog" == namespace:
        if first:
            first = False
            body = inner_html(apply_transforms(render_page(page),pagename))
        else:
            body = extract_lead_paragraph(page, pagename) + """<p class="read-more"><a href="%(page_route_base)s/%(pagename)s">Read More...</a></p>""" % locals()
        end            
    else:
        body = inner_html(apply_transforms(render_page(page),pagename))
    end
    tags.extend(post['tags'].replace("tag:", "").strip().split(", "))
%>
    <div class="inner-container {{!namespace}}-content">
<%
include('metadata', **include('common'))
%>
    <section id="{{!pagename}}" class="{{!namespace}}-namespace">
    {{!body}}
    </section>
    </div>
<%
end
scripts=["zepto.min.js","unveil.js"]
headers = {
    "title": "Home Page",
    "tags": ", ".join(sorted(list(set(tags)))).lower().replace(",,", ",")
}

%>
    </section>
</div>
%rebase('layout', **dict(globals()))
