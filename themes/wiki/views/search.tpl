<%
from itertools import islice
if defined("query"):
    headers['title'] = "Search results for '%s'" % query
    items = list(islice(results,0,20))
    if len(items):
%>
    <table class="ink-table bordered hover alternating">
    <thead>
        <tr>
            <th>Score</th>
            <th>Page</th>
            <th>Content</th>
            <th>Modified</th>
        </tr>
    </thead>
    <tbody>
%for i in items:
    <tr>
        <td>{{!i["score"]}}</td>
        <td><a href="/space/{{!i["name"]}}">{{!i["title"]}}</td>
        <td>{{!i["content"]}}</td>
        <td>{{!i["mtime"]}}</td>
    </tr>
%end
    </tbody>
</table>
<%
    else:
    headers['title'] = "No results for '%s'" % query
        include('inline-message', level="info", message="No pages that matched your query were found.")
    end
else:
    headers['title'] = "Invalid search"
    include('inline-message', level="error", message="No valid query parameters specified.")
end
rebase('layout', headers=headers)
%>
