<table class="ink-table bordered hover alternating">
    <thead>
        <tr>
            <th>Variable</th>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
%if "NEW_RELIC_LICENSE_KEY" in environ:
%environ["NEW_RELIC_LICENSE_KEY"] = ":redacted:"
%end
%for e in sorted(environ):
    <tr>
        <td><code>{{!e}}</code></td>
        <td><code>{{!environ[e]}}</code></td>
    </tr>
%end
    </tbody>
</table>
%rebase('layout', headers=headers)
