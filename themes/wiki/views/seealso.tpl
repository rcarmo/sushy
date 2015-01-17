<div id="seealso">
    <ul>
%for p in seealso:
        <li>
            <a href="{{base_url + '/' + p['name']}}">{{p['title']}}</a>
        </li>
%end
    </ul>
</div>