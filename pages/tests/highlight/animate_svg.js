var paths = Array.prototype.slice.call(document.querySelectorAll('.animated path'),0);

paths.map(function(path) {
   var bag = document.createAttribute("bag");
   bag.value = path.style.fill;
   path.setAttributeNode(bag);
   path.style.fill = "white";
})

paths.map(function(path){
    var length = path.getTotalLength();
    path.style.stroke="#000";
    path.style.strokeWidth="5";
    path.style.transition = path.style.WebkitTransition = 'none';
    path.style.strokeDasharray = length + ' ' + length;
    path.style.strokeDashoffset = length;
    path.getBoundingClientRect();
    path.style.transition = path.style.WebkitTransition = 'stroke-dashoffset 2s ease-in-out';
    path.style.strokeDashoffset = '0';
});


setTimeout(function(){
    paths.map(function(path){
        path.style.transition = path.style.WebkitTransition = 'fill 2s ease, stroke-width 2s ease';
        path.style.fill = path.getAttribute("bag");
        path.style.strokeWidth = "0";
    })
},3000)
