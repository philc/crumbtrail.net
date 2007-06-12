/*
 * Supplements Mootools with some Prototype functions used by Plotr
 *
 *  (c) 2007 Phil Crosby <phil.crosby@gmail.com>
 */

Prototype={};
Class.create=function(){
	return new Class({});
};
Element.setStyle=function(){
	var e = $(arguments[0]);
	var a = arguments[1];
	// Prototype allows you to pass in many style declarations at once. Mootools 
	// has a separate API for this
	if (typeof a=="object")
		e.setStyles(a);
	else
		e.setStyle(a);
};

Array.prototype.flatten=function(){
    return this.inject([], function(array, value) {
      return array.concat(value && value.constructor == Array ?
        value.flatten() : [value]);
    });
};

Number.prototype.toColorPart= function() {
    var digits = this.toString(16);
    if (this < 16) return '0' + digits;
    return digits;
};