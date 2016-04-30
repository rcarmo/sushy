%if defined("seealso") and len(seealso):
<hr/>
<div id="seealso">
	<h4>See Also:</h4>
    <div class="reference">
        {{!''.join(['<a class="seelink" href="' + base_url + page_route_base + '/' + p['name'] + '">' + p['title'] + '</a>' for p in seealso[:10]])}}
    </div>
</div>
%end
