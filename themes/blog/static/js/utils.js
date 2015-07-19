gradient = {	
	hex2rgb : function(hex){
	    hex = hex.replace('#', '');
	    if(hex.length !== 3 && hex.length !== 6){
	        return [255,255,255];
	    }
	    if(hex.length == 3){
	        hex = hex[0]+hex[0]+hex[1]+hex[1]+hex[2]+hex[2];
	    }
	    return [parseInt(hex.substr(0,2),16),
	    		parseInt(hex.substr(2,2),16),
	    		parseInt(hex.substr(4,2),16)];
	},
	
	rgb2hex : function(rgb){
 		return "#" +
  			("0" + Math.round(rgb[0]).toString(16)).slice(-2) +
  			("0" + Math.round(rgb[1]).toString(16)).slice(-2) +
  			("0" + Math.round(rgb[2]).toString(16)).slice(-2);
	},

	generate : function(start, finish, steps){
		var result = [];
		
		start = this.hex2rgb(start);
		finish = this.hex2rgb(finish); 
		steps -= 1;
		ri = (finish[0] - start[0]) / steps;
		gi = (finish[1] - start[1]) / steps;
		bi = (finish[2] - start[2]) / steps;
	
		result.push(this.rgb2hex(start));
		
		var rv = start[0],
			gv = start[1],
			bv = start[2];
	
		for (var i = 0; i < (steps-1); i++) {
			rv += ri;
			gv += gi;
			bv += bi;
			result.push(this.rgb2hex([rv, gv, bv]));
		};
		
		result.push(this.rgb2hex(finish));
		return result;
	}
}