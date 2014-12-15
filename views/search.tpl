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
%for r in results:
    <tr>
        <td>{{!r["score"]}}</td>
        <td><a href="/space/{{!r["id"]}}">{{!r["title"]}}</td>
        <td>{{r["content"]}}</td>
        <td>{{!r["mtime"]}}</td>
    </tr>
%end
    </tbody>
</table>
%rebase('layout', headers=headers)
