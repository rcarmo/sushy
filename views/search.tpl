<table class="ink-table bordered hover alternating">
    <thead>
        <tr>
            <th>Value</th>
        </tr>
    </thead>
    <tbody>
%for r in results:
    <tr>
        <td><code>{{!r}}</code></td>
    </tr>
%end
    </tbody>
</table>
%rebase('layout', headers=headers)
