<%
from sushy.utils import utc_date, fuzzy_time, ordinal
from sushy.config import BLOG_ENTRIES
from re import match
if "from" in headers:
    author = headers["from"]
else:
    author = "Unknown"
end

metadata = author

if "date" in headers:
    post_date = utc_date(headers["date"], "")

    if post_date != "":
         metadata = author + " - %s %s %d, %s" % (post_date.strftime("%B"), ordinal(post_date.day), post_date.year, fuzzy_time(post_date))
    end

    if not BLOG_ENTRIES.match(pagename) and "last-modified" in headers:
        post_date = utc_date(headers["last-modified"], "")
        if post_date != "":
            metadata = author + " - last updated on %s %s %d, %s" % (post_date.strftime("%B"), ordinal(post_date.day), post_date.year, fuzzy_time(post_date))
        end
    end
end
%>
