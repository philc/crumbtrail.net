//@from(http://www.vivabit.com/bollocks/2006/04/06/introducing-dom-builder)
/*
Copyright (c) 2006 Dan Webb

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial 
portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED 
TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS 
IN THE SOFTWARE.
*/

/*
var html = DomBuilder.apply();

var form = html.FORM(
  html.DIV(
    html.INPUT({type : 'text', name : 'email'}),
    html.INPUT({type : 'text', name : 'password'}),
    html.INPUT({type : 'submit'}),
  )
);

document.body.appendChild(form);
*/
var DomBuilder = {
  IE_TRANSLATIONS : {
    "class" : "className",
    "for" : "htmlFor"
  },
  ieAttrSet : function(a, i, el) {
    var trans;
    if (trans = this.IE_TRANSLATIONS[i]) el[trans] = a[i];
    else if (i == "style") el.style.cssText = a[i];
    else if (i.match(/^on/)) el[i] = new Function(a[i]);
    else {
      if (i == "value" && /input|textarea/i.test(el.nodeName))
        el.defaultValue = a[i];
      el.setAttribute(i, a[i]);
    }
  },
  apply : function(o, lowerCase) { 
    var els = (
      "p|div|span|strong|em|img|table|tr|td|th|thead|tbody|tfoot|pre|code|" + 
      "h1|h2|h3|h4|h5|h6|ul|ol|li|form|input|textarea|legend|fieldset|" + 
      "select|option|blockquote|cite|br|hr|dd|dl|dt|address|a|button|abbr|acronym|" +
      "script|link|style|bdo|ins|del|object|param|col|colgroup|optgroup|caption|" + 
      "label|dfn|kbd|samp|var").split("|");
    var el, i=0;if (!o || o == null) o = {};
    var caseType = lowerCase === true ? "toLowerCase" : "toUpperCase";
    while (el = els[i++]) o[el[caseType]()] = DomBuilder.tagFunc(el);
    return o;
  },
  tagFunc : function(tag) {
    return function() {
      var a = arguments, at, ch; a.slice = [].slice; if (a.length) { 
      if (a[0].nodeName || typeof a[0] == "string") ch = a; 
      else { at = a[0]; ch = a.slice(1); } }
      return DomBuilder.elem(tag, at, ch);
    }
  },
  elem : function(e, a, c) {
    a = a || {}; c = c || [];
    var isIE = navigator.userAgent.match(/MSIE/);
    if (isIE) {
      e = "<"+ e;
      if (a.name) e += " name='"+ a.name +"'";
      if (a.type && /input/i.test(e)) e += " type='"+ a.type +"'";
      e += ">";
    }
    var el = document.createElement(e);
    for (var i=0; i<c.length; i++) {
      if (typeof c[i] == "string") c[i] = document.createTextNode(c[i]);
      el.appendChild(c[i]);
    }
    for (var i in a) {
      if (typeof a[i] != "function") {
        if (isIE) this.ieAttrSet(a, i, el);
        else el.setAttribute(i, a[i]);
      }
    }
    return el;
  }
}