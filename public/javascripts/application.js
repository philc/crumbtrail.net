/* 
 * utility extensions
 */
String.prototype.firstUpCase = Array.prototype.firstUpCase || function(){ return this.charAt(0).toUpperCase() + this.slice(1,this.length);};

String.prototype.toDisplayString = Array.prototype.toDisplayString || function(){ return this.firstUpCase().replace(/_/g,' '); };

/* This is different than the mootools camcelcase function. This changes hits_week => hitsWeek */
String.prototype.toCamelCase = Array.prototype.toCamelCase || function(){ 
	var n=[];
	for (var i=0;i<this.length;i++){
		if (this.charAt(i)=='_'){
			n.push(this.charAt(i+1).toUpperCase());
			i++;
		}else
			n.push(this.charAt(i));
	}
	return n.join('');
};

Array.prototype.sum=Array.prototype.sum ||  function(){var s=0; for (var i=0; i<this.length; i++) s+=this[i]; return s; };
Array.prototype.max=Array.prototype.max || 	function(){var m=0; for (var i=0; i<this.length; i++) if (this[i] > m) m=this[i]; return m;};
Array.prototype.min=Array.prototype.min || 
	function(){var m=Number.MAX_VALUE; for (var i=0; i<this.length; i++) if (this[i] < m) m=this[i]; return m;};

/*
 * Breadcrumbs master object
 */
BC={};
/* makes each key in the associative array options a member of obj */
BC.apply=function(obj,options){
	for (var key in options)
		obj[key]=options[key];
};



/* 
 * extensions to mootools
 */
Element.extend({
	hide:function(){this.setStyle('display','none');},
	show:function(){this.setStyle('display','');},
	toggle:function(){
		if (this.getStyle('display')=='none') this.show();
		else this.hide();}
});
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


/*
 * Custom DOM Builder that returns big blocks of innerHTML
 * 
 * Written by Phil Crosby. Derived from Dan Webb's DOM builder:
 * http://www.vivabit.com/bollocks/2006/04/06/introducing-dom-builder 
 * 
 * use like this:
	dh.a(
		{
			title:'link title',
			cls:'css class',
			href:'href'
		},
		captionText
	);
	
*/
DomBuilder=new function(){
	this.initialize=function(){
		// Add methods to this DomBuilder, one for each possible HTML tag name
		var els = (
	      "p|div|span|strong|em|img|table|tr|td|th|thead|tbody|tfoot|pre|code|" + 
	      "h1|h2|h3|h4|h5|h6|ul|ol|li|form|input|textarea|legend|fieldset|" + 
	      "select|option|blockquote|cite|br|hr|dd|dl|dt|address|a|button|abbr|acronym|" +
	      "script|link|style|bdo|ins|del|object|param|col|colgroup|optgroup|caption|" + 
	      "label|dfn|kbd|samp|var").split("|");
		var el,i=0;
		while (el=els[i++]) this[el]=this.createFunc(el);			
		
	};
	this.createFunc=function(tag){
		return function(){
			return this.create(tag,arguments);
		};
	};
	this.create=function(tag,args){
		//var args=arguments;
		//var tag = 'div'
		var e =  '<'+tag;
		var att="";
		var contents="";
		for (var i=0;i<args.length;i++)
		{
			var arg=args[i];
			if (typeof arg == 'string' || typeof arg=='number')
				contents+=arg;
			else
				att=this.keyValues(arg);
		}
		return '<'+tag+att+'>'+contents+'</'+tag+'>';		
	};
	this.keyValues=function(args){
		var str=[];
		/*for (var k in args)
			str+=k + '="' + args[k] + '" ';*/
		// If the key is "cls" translate it into "class"
		for (var k in args)
			str.push((k=='cls' ? 'class' : k) + '="' + args[k] + '"');
		return str.length==0 ? "" : ' ' + str.join(' ');
	};
	this.initialize();
};
// shortcut
db=DomBuilder;


function toggleAppear(element){
	element=$(element);
	if (element.style && element.style.display=="none")
		Effect.Appear(element);
	else
		Effect.Fade(element);		
	return false;
}
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



