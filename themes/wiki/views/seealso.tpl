%if len(seealso):
<hr/>
<div id="seealso">
	<h4>See Also:</h4>
    <div class="holder small align-center">
%links = ['<a class="tiny-100 small-50 medium-30 large-25 xlarge-15 align-left" href="' + base_url + '/' + p['name'] + '">' + p['title'] + '</a>' for p in seealso]
{{!''.join(links)}}
    </div>
</div>
%end