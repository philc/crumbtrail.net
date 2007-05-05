/*
 * These are util methods that are very specific to Breadcrumbs
 */

function px(v) {  return Math.ceil(v) + "px";}

/*
 * Some string methods
*/
extendIfAbsent(String.prototype,{
	toDisplayString: function(){ return this.firstUpCase().replace(/_/g,' '); },
	/* This is different than the mootools camcelcase function. This changes hits_week => hitsWeek */
	toCamelCase: function(){ 
		var n=[];
		for (var i=0;i<this.length;i++){
			if (this.charAt(i)=='_'){
				n.push(this.charAt(i+1).toUpperCase());
				i++;
			}else
				n.push(this.charAt(i));
		}
		return n.join('');
	}	
});



BC={};
/* makes each key in the associative array options a member of obj */
BC.apply=function(obj,options){
	for (var key in options)
		obj[key]=options[key];
};



// This only searches an element's immediate children for a class
Element.extend({childrenOfClass:function(klass){
	var kids = this.getChildren();
	var results =[];
	for (var i=0;i<kids.length;i++){
		if (kids[i].hasClass(klass))
			results.push(kids[i]);
	}
	return results;
}});

// Stolen from prototype
String.prototype.toQueryParams =  function() {
    var pairs = this.match(/^\??(.*)$/)[1].split('&');
	var params={};
	pairs.forEach(function(pairString){
		var pair = pairString.split('=');
		params[pair[0]]=pair[1];
	});
	return params;
  };


function toggleAppear(element){
	element=$(element);
	if (element.style && element.getStyle('display')=='none'){
		element.style.opacity=0;
		element.style.display='';
		element.effect('opacity',{duration: 750}).start(0,1);
	}else{
		element.effect('opacity',{duration: 750}).start(1,0).chain(function(){element.style.display='none';});
		/*element.style.opacity=0;
		element.style.display='none';*/
	}
	return false;
}
