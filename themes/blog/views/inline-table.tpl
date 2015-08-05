    <table class="hover alternating">
        <thead>
            <tr>
%for i in headers[0::2]:
                <th>{{!i}}</th>
%end
            </tr>
        </thead>
        <tbody>
%for i in rows:
            <tr>
%for j in headers[1::2]:
    %if j == "name":
                <td><a href="{{page_base}}/{{!i[j]}}">{{!i["title"]}}</a></td>
    %else:
                <td>{{!i[j]}}</td>
    %end
%end
            </tr>
%end
        </tbody>
    </table>