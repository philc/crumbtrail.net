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


Object.extend({
	keys: function(object) {
		var keys = [];
		for (var property in object)
			keys.push(property);
		return keys;
	},

	values: function(object) {
		var values = [];
		for (var property in object)
			values.push(object[property]);
		return values;
	}
});

var Hash = function(obj) {
  Object.extend(this, obj || {});
};
function $H(object) {
  if (object && object.constructor == Hash) return object;
  return new Hash(object);
};
Object.extend(Hash.prototype, Enumerable);
Object.extend(Hash.prototype, {
  _each: function(iterator) {
    for (var key in this) {
      var value = this[key];
      if (value && value == Hash.prototype[key]) continue;

      var pair = [key, value];
      pair.key = key;
      pair.value = value;
      iterator(pair);
    }
  },

  keys: function() {
    return this.pluck('key');
  },

  values: function() {
    return this.pluck('value');
  },

  merge: function(hash) {
    return $H(hash).inject(this, function(mergedHash, pair) {
      mergedHash[pair.key] = pair.value;
      return mergedHash;
    });
  },

  remove: function() {
    var result;
    for(var i = 0, length = arguments.length; i < length; i++) {
      var value = this[arguments[i]];
      if (value !== undefined){
        if (result === undefined) result = value;
        else {
          if (result.constructor != Array) result = [result];
          result.push(value)
        }
      }
      delete this[arguments[i]];
    }
    return result;
  },

  toQueryString: function() {
    return Hash.toQueryString(this);
  },

  inspect: function() {
    return '#<Hash:{' + this.map(function(pair) {
      return pair.map(Object.inspect).join(': ');
    }).join(', ') + '}>';
  }
});


ObjectRange = Class.create();
Object.extend(ObjectRange.prototype, Enumerable);
Object.extend(ObjectRange.prototype, {
  initialize: function(start, end, exclusive) {
    this.start = start;
    this.end = end;
    this.exclusive = exclusive;
  },

  _each: function(iterator) {
    var value = this.start;
    while (this.include(value)) {
      iterator(value);
      value = value.succ();
    }
  },

  include: function(value) {
    if (value < this.start)
      return false;
    if (this.exclusive)
      return value < this.end;
    return value <= this.end;
  }
});