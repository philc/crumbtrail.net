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
		// If the key is "cls" translate it into "class"
		for (var k in args)
			str.push((k=='cls' ? 'class' : k) + '="' + args[k] + '"');
		return str.length==0 ? "" : ' ' + str.join(' ');
	};
	this.initialize();
};
// shortcut
db=DomBuilder;