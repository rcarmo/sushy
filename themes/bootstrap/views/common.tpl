<%
from sushy.utils import utc_date, fuzzy_time, time_since, ordinal
from sushy.config import BLOG_ENTRIES
from sushy.models import get_page_metadata
from datetime import datetime, timedelta
from re import match
if "from" in headers:
    author = headers["from"]
else:
    author = "Unknown"
end

def format_date(when, relative=False):
    now = datetime.utcnow()
    delta = when - now
    if relative and (delta > timedelta(weeks=-12)):
        return "%s ago, %s" % (time_since(when, now).split(',')[0], fuzzy_time(when)) 
    else:
        return "%s %s %d, %s" % (when.strftime("%B"), ordinal(when.day), when.year, fuzzy_time(when))
    end
end

page_metadata = get_page_metadata(pagename)
published = modified = readtime = ""
metadata = author

if page_metadata:
    published = format_date(page_metadata["pubtime"])
    modified = format_date(page_metadata["mtime"])
    if "readtime" in page_metadata:
        readtime = "&middot; %d min read" % (max(int(round(page_metadata["readtime"] / 60.0)), 1))
    end

    metadata = "%s<br/>%s %s" % (author, published, readtime) 

    if not BLOG_ENTRIES.match(pagename) and "last-modified" in headers and len(modified):
        metadata = "%s<br/>updated %s %s" % (author, modified, readtime) 
    end
end

default_author_image = "/static/img/avatars/unknown36x36.png"
default_author_image = "/apple-touch-icon.png"
author_image = "/static/img/avatars/%s36x36.png" % author.replace(" ","").lower()
author_image_retina = "/static/img/avatars/%s80x80.png" % author.replace(" ","").lower()
%>
