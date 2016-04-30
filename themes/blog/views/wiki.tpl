<%
namespace = pagename.split("/")[0].lower()
%>
<div class="container content">
%include('metadata', **include('common'))
    <section id="main" class="{{!namespace}}-namespace">
    {{!body}}
    </section>
</div>
%include('prevnext')
<div class="container">
%include('seealso')
</div>
<%
scripts=["zepto.min.js"]
%>
%rebase('layout', **dict(globals()))