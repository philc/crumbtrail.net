/*
 * General utility stuff. This is only the most common stuff that I (philc) share across projects.
 * More specialized stuff gets put in dom.xx.js files
 */

util={
	// Avoid having to provide a radix parameter for jslint to validate
	escapeHTML:function(html){
		return html.replace(/</g,"&lt;").replace(/>/g,'&gt;');
	},
	unescapeHTML:function(text){
		return text.replace(/&lt;/g,"<").replace(/&gt;/g,">");
	}
};


/*
* Logging utility
* what we want to do here is disable logging entirely in production.
* in development, if it's firebug, log to that. If not (e.g. we're deving
* in IE or safari) use our custom logger
*/
if(typeof console=="undefined")
	console = {log: function(){}};
log=function(){	console.log.apply(console,arguments); };



/*
 * String functions
 */

extendIfAbsent(String.prototype,{
	startsWith: function(word){ 
		return this.indexOf(word) == 0;	
	},
	endsWith: function(word){
		var i = this.indexOf(word);
		return (i>=0 && i>=this.length-word.length);
	},
	truncate: function(n){
		if (this.length<=n) return this.toString();
		return this.toString().substring(0,n-1) + "..";
	},
	firstUpCase: function(){
		return this.charAt(0).toUpperCase() + this.slice(1,this.length);
	}
});

/*
 * Array methods
 */
extendIfAbsent(Array.prototype,{
	sum: function(){
		var s=0; 
		for (var i=0; i<this.length; i++) 
			s+=this[i]; 
		return s; 
	},
	max: function(){
		var m=0; 
		for (var i=0; i<this.length; i++) 
			if (this[i] > m) 
				m=this[i]; 
		return m;
	},
	min: function(){
		var m=Number.MAX_VALUE;
		for (var i=0; i<this.length; i++) 
			if (this[i] < m)
			 	m=this[i]; 
		return m;
	}
});

	
/*
 * browser detection
 */
if (navigator.appVersion.indexOf("Win")!=-1) window.OS="Windows";
else if (navigator.appVersion.indexOf("Mac")!=-1) window.OS="MacOS";
else window.OS="Linux";


/*
 * Escapes a user-provided regex.
 * http://simonwillison.net/2006/Jan/20/escape/
*/
RegExp.escape = function(text) {
	if (!arguments.callee.sRE) {
		var specials = [
		'/', '.', '*', '+', '?', '|',
		'(', ')', '[', ']', '{', '}', '\\'
		];
		arguments.callee.sRE = new RegExp(
			'(\\' + specials.join('|\\') + ')', 'g'
		);
	}
	return text.replace(arguments.callee.sRE, '\\$1');
};

/* 
* extensions to mootools
*/
Element.extend({
	hide:function(){this.setStyle('display','none');},
	show:function(){this.setStyle('display','');},
	toggle:function(){
		if (this.getStyle('display')=='none') 
			this.show();
		else 
			this.hide();
	},
	/*
	* Focuses the first input field contained within this element
	*/	
	focusFirstInput:function(){
		var f = this.getElementsByTagName("INPUT")[0];
		if (f)
			f.focus();
	}
});



/*
 * Will add the methods to the given object if it doesn't already exist
 * methods should be in the form of: {methodName:function(){... }}
 */
function extendIfAbsent(cls, methods){
	for (m in methods)
	{
		if (!cls[m])
			cls[m]=methods[m];
	}
};