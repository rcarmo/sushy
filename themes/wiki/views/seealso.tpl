%if len(seealso):
<hr/>
<div id="seealso" class="all-100">
	<h4>See Also:</h4>
    <div class="holder all-100 small align-center">
{{!''.join(['<a class="seelink tiny-100 small-50 medium-30 large-25 xlarge-15 align-left" href="' + base_url + '/' + p['name'] + '">' + p['title'] + '</a>' for p in seealso])}}
    </div>
</div>
<script>
	var links = Array.prototype.slice.call(document.getElementById("seealso").getElementsByTagName("a"));
    var colors = gradient.generate("#fff", "#8D7", links.length)
    var height = Math.max.apply(Math, Array.prototype.map.call(links, function(e) { 
        return e.clientHeight;
    }));
    links.forEach(function(e,i,a) {
      	e.style.height = height + "px";
      	e.style.backgroundColor = colors[i];
    })
</script>
%end