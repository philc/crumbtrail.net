now=10;
data=[]

chartData=[12,22,10,26];
chartData=[.5,2,5,5];
chartData=[1,8,1];
// Dean Edwards/Matthias Miller/John Resig

function init() {

};
/* for Mozilla/Opera9 */
if (document.addEventListener)
    document.addEventListener("DOMContentLoaded", init, false);
/* for Internet Explorer */
/*@cc_on @*/
/*@if (@_win32)
    document.write("<script id=__ie_onload defer src=javascript:void(0)><\/script>");
    var script = document.getElementById("__ie_onload");
    script.onreadystatechange = function() {
        if (this.readyState == "complete") {
            init(); // call the onload handler
        }
    };
/*@end @*/
/* for Safari/konq */
if (/WebKit|KHTML/i.test(navigator.userAgent)) { // sniff
    var _timer = setInterval(function() {
        if (/loaded|complete/.test(document.readyState)) {
            init(); // call the onload handler
        }
    }, 10);
}
/* for other browsers */
window.onload = init;



/*
 * Controlling the UI
 */

function UITimer(){
  this.timer=null;
  this.timeout=2000;
}

var Preferences = Class.create();
Preferences.prototype = {
  initialize:function(){
    // "section" is for the main menu preference
    this.sections=["glance","hits","referers","pages","searches","details","section"];
    this.timers=new Array();    
    this.sections.each(function(e){
      this.timers[e]=new UITimer();
    }.bind(this));    
  },
  update: function(n,v){
    var timer=this.timers[n];
    clearTimeout(timer.timer);
    timer.timer=setTimeout(this.sendPreference(n,v),timer.timeout);
  },
  // Sends a view preference and a value asynchronously.
  // name/values can be are panel/panel that's active,
  // and section/section that's active
  sendPreference: function(n,v){
    var pars="p="+n+"&v="+v;
    return function(){new Ajax.Request('/project/setpref/',
      {asynchronous:true, parameters:pars
      });
    }
  }
}


var Page = Class.create();
Page.prototype = {
  initialize:function(){
    this.colors=["#a4d898","#fdde88","#d75b5c","#7285b7"];
    this.preferences=new Preferences();
    this.activeSection="glance";
    
  },
  // Switch section
  menuNav: function(e){
    var section=e.title;
    
    this.removeClassFromElements("active","menu");
    e.className+=" active";
    
    console.log(this.activeSection);
    Element.hide(this.activeSection);
    this.activeSection=section;        
    Element.show(section);
    
    this.preferences.update("section",section);
  },
  //panelNav: function(section,v,linkElement){
  panelNav: function(linkElement){
    var panel=linkElement.title;
    document.getElementsByClassName("panel",this.activeSection).each(
      function(e){Element.hide(e)});
    
    // Remove highlighting on the other link, highlight the new link    
    this.removeClassFromElements('panel_link_active',this.activeSection);
    linkElement.className += " panel_link_active";
    
    // Show e.g. "referers_current" panel
    Element.show(this.activeSection+"_"+panel);
    this.preferences.update(this.activeSection,panel);
  },
  removeClassFromElements: function(c,start){
    document.getElementsByClassName(c,start).each(
      function(e){e.className=e.className.replace(c,"");}) 
  }
  
}

page = new Page();

// Gets called when the page is done loading. Enables the structure with behavior
function init(){
  // quit if this function has already been called
  if (arguments.callee.done) return;
  // flag this function so we don't do the same thing twice
  arguments.callee.done = true;
  // kill the timer
  if (_timer) clearInterval(_timer);
  populate();
  // set menu links
  $A($('menu-links').getElementsByTagName("LI")).each(function(e){
    l=e.getElementsByTagName("A")[0];
    l.onclick=function(){ page.menuNav(this); return false;};
  });
  // set panel links
  $A(document.getElementsByClassName("panel_link","content")).each(function (e){
    e.onclick=function(){ page.panelNav(this); return false;};
  });  
}



for (i=0;i<24;i++)
{
  data[i*2]=i*3;
  data[i*2+1]=i*6;
}


function populate(){
  var tb=new TableDisplay("Hits today", ["","Hits","Unique"],data,2,hitsToday);
  $("hits_today").innerHTML=tb.buildTable();
  tb = new TableDisplay("Hits this week", ["","Hits","Unique"],hitsWeekData,1,hitsWeek);
  $("hits_week").innerHTML=tb.buildTable();
  
  tb=new TableDisplay("Total referrals", ["Referer","Total hits"],referersTotalData,2,referersTotal);
  $("referers_total").innerHTML=tb.buildTable();
  tb=new TableDisplay("Unqiue referrals", ["Referer","First visited"],referersUniqueData,2,referersWithDate);
  $("referers_unique").innerHTML=tb.buildTable();
  tb=new TableDisplay("Most recent referers",["Recent referer", "Visited"],referersRecentData,2,referersWithDate);
  $("referers_recent").innerHTML=tb.buildTable();

  pg = new PieGraphDisplay("chart",chartData);
  pg.drawChart();
  //drawChart("chart",chartData);
}


/*
 * Table display
 */
TableDisplay=Class.create();

TableDisplay.prototype={
  initialize: function(title, headerNames, data, step, cellFunc){
    this.title=title;    
    this.headerNames=headerNames;
    this.data=data;
    this.step=step;
    this.cellFunc=cellFunc;
  },
  buildTable: function(){
    var html="<table>"+this.tableHeader();
    for (i=0;i<this.data.length/this.step;i++)
    {
      html+=this.cellFunc(i,this.data);
    }
    html+="</table>" + '<div class="table-footer-cap"></div>';
    return this.dialog(this.title,html)
  },
  dialog: function(t,content){
    return '<div class="dialog"><div class="hd"><div class="c"></div></div><div class="bd">'+
      '<div class="c"><h1 class="title">' + t + '</h1>'+content + '</div></div><div class="ft">' + 
      '<div class="c"></div></div></div>';
  },
  tableHeader: function(){
    if (this.headerNames==null)
      return "" 
    var html='<tr class="header">'
    for (i=0;i<this.headerNames.length;i++)
      html += (i==0 ? "<th class='f'>" : "<th>") + this.headerNames[i] + "</th>";
    html+"</tr>"
    return html;
  },
}



DisplayHelper = Class.create();
DisplayHelper.Methods={
  timeAgo: function(date){
    var diff=(new Date())-date;
    var mins=Math.floor(diff/1000/60);
    var hrs=Math.floor(mins/60);
    var days=Math.floor(hrs/24);
    var weeks=Math.floor(days/7);
    var mos=Math.floor(days/30);
    if (mins<1)
      return "few&nbsp;secs&nbsp;ago";
    else if (hrs <1)
      return this.formatTimeAgo(mins,"min");
    else if (days < 1)
      return this.formatTimeAgo(hrs,"hr");
    else if (weeks < 1)
      return this.formatTimeAgo(days,"day");
    else if (mos<1)
      return this.formatTimeAgo(weeks,"week");
    else 
      return this.formatTimeAgo(mos,"month");
  },
  formatTimeAgo: function(n,word){
    return n + "&nbsp;" + (n>1 ? word+"s" : word) + "&nbsp;ago";
  },
  showHour: function(i){
    var t=i%24;
    return (t%12)+1 + ":00" + (t<12 ? "am" : "pm");
  },
  days:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],
  showDay: function(i){
    i=i%7;
    return this.days[i<0 ? 7+i : i];    
  }
}
Object.extend(DisplayHelper,DisplayHelper.Methods);



function hitsWeek(i,data){
  //var c=classString(i, function(i){(i+now+1 > 24 ? " old" : "")});
  return '<tr>' + DisplayHelper.showDay((new Date()).getDay()-i) +
   "</td><td>" + data[i] + "</td><td>" + "who knows.." + "</td></tr>";  
}
function hitsToday(i,data){
  var c=classString(i, function(i){(i+now+1 > 24 ? " old" : "")});
  return '<tr' + c + '>' + DisplayHelper.showHour(i+now) +
   "</td><td>" + i*120 + "</td><td>" + i*60 + "</td></tr>";  
}
function referersRecent(i,data){
  var url=unescape(data[i*2]);
  return '<tr' + classString(i) +'><td class="f">' + linkFor(url,url)+ "</td></tr>"
}
function referersWithDate(i,data){
  var url=unescape(data[i*2]);
//   var url=data[i*2];  
  return '<tr' + classString(i) +'><td class="f">' + 
    linkFor(url,url)+ "</td><td>" + DisplayHelper.timeAgo(data[i*2+1]) + "</td></tr>"
}

function referersTotal(i,data){
  var url=unescape(data[i*2]);
//   var url=data[i*2];
  var c=classString(i,  function(i){return (i+now+1 > 24 ? " old" : "")});
  
  return '<tr' + c+ '><td class="f">' + linkFor(url,url)+ "</td><td>" + data[i*2+1] + "</td></tr>"
}
function linkFor(url,caption){
  return '<a href="' + url + '">' + caption + '</a>';
}
function classString(i, func){
  var c=(i%2==0 ? "a" : "");
   if (func!=null)
     c+=func(i);
  return(c=="" ? "" : ' class="' + c +'"');
}






/*
 * Line graph drawing
 */

LineGraph=Class.create();
LineGraph.prototype={
  initialize: function(id,data){
    this.element=$(id);
    this.data=GraphDisplay.relativize(data);
  },
  drawGraph: function(){  
    // Graph container
    var g=document.createElement("div");
    g.className="graph";
    //size=120;
    size=200;
    //size=150;
    var imgs=[]
    var hwidth=size/(data.length-1);   
  
    for (i=1;i<data.length; i++){
      var div=document.createElement("div");
      div.className="color";
      div.id=i+"";
      var img=document.createElement("img");    
      
      // Height of the point before this one
      var prevHeight=data[i-1] ? data[i-1] : 0;
      
      // Whether the line is pointing up. Up=1, down=-1
      var u=prevHeight<data[i] ? 1 : -1;
      img.src= (u==1 ? "/images/line.gif" : "/images/lined.gif");    
      img.className="line";
      
      img.style.width=hwidth+"px";
      div.style.width=hwidth+"px";
      
      // difference in our heights
      var h=data[i]-prevHeight;
      //console.log(h);
      
      // amount of space there is above the previous element
      t=size-prevHeight;
      //console.log(t);
      
      img.style.height=h*u + "px";
      
      var ourTop = t-(u>0  ? h : 0)
      //div.style.height=1+"px";
      div.style.height=size-(h*u)-ourTop+"px";
      
      div.style.top=ourTop+(h*u)+"px";
      img.style.top=ourTop+"px";
      div.style.left=(i-1)*hwidth+ "px";
      img.style.left=(i-1)*hwidth+ "px";
      
      g.appendChild(img);
      g.appendChild(div);
    } 
    
    this.element.appendChild(g);
  }
}
  
  
/*
 * Pie chart graphing
 */

PieGraphDisplay = Class.create();
PieGraphDisplay.prototype={
  initialize: function(id,data){
    this.element=$(id);
    this.size=150;
    this.qsize=this.size/2;
    this.data=[];
    // relativize data
    for (var i=0;i<data.length;i++){ this.data[i]=Math.floor((data[i]/data.length)*360);}
    //this.data=data;
  },

  drawChart: function (){   
    var placeholder=document.createElement("div")
    placeholder.style.position="absolute";
    placeholder.style.width=px(this.size);
    placeholder.style.height=px(this.size);
    //placeholder.className="placeholder";
  
    /*var max=0;
    var total=0;
    data.each(function(e){ total+=e; if (e>max) max=e; });  */ 
    
    //console.log(data);
    
    for (var i=0;i<this.data.length-1;i++){
      this.graphQuadrant(i,this.data,placeholder);
    }
    placeholder.style.backgroundColor=page.colors[this.data.length-1];
    
  //   graphQuadrant(0,data, placeholder);
  //   graphQuadrant(1,data, placeholder);
  //   graphQuadrant(2,data, placeholder);
  //   graphQuadrant(3,data, placeholder);
    
    this.element.appendChild(placeholder);
  },

  graphQuadrant: function(i,data, placeholder){
    var v=data[i]+this.sumPrevious(i,data);
    //console.log("data:" + v);
    console.log("graphing " + i + " a" + v);
    // quadrant
    //console.log(v);
    //var q=cap(Math.floor(v/90),3);
    var q=Math.floor(v/90);
    
    // Multiplier
    var m=90*(q+1);
  
    // Find out how many degrees we are into this quadrant, ie.
    // 300 is 30 degrees into quad three
    var deg = (m-v)/90;    
    
    var w,h;
    qs=this.size;s=this.size;
    if (q==0){
      w=(v <=(45+q*90) ? qs : s*(deg));
      h=(v >=(45+q*90) ? qs : s*(1-deg));
    }else if (q==1){
      h=(v <=(45+q*90) ? qs : s*(deg));
      w=(v >=(45+q*90) ? qs : s*(1-deg));
    }else if (q==2){
      //a=(v <=(45+q*90) ? qsize : size*(1-v/m));
      w=(v <=(45+q*90) ? qs : s*(deg));
      h=(v >=(45+q*90) ? qs : s*(1-deg));  
    }else{
      h=(v <=(45+q*90) ? qs : s*(deg));
      //a=(v >=(45+q*90) ? qsize : size*(1-v/m));
      w=(v >=(45+q*90) ? qs : s*(1-deg));
    }
  
  
  
    var img=document.createElement("img");    
    img.className="chart_image";  
    img.style.width=w+"px";
    img.style.height=h+"px";
    img.style.zIndex="1";
    o1=(q==1||q==2) ? 0 : 1;
    o2=(q==2||q==3) ? 0 : 1;
    
    img.style.left=this.qsize-o1*w+"px";
    
    img.style.top=this.qsize-o2*h + "px";
  
    img.src=this.imageForQuadrant(i,q);
    
    img.style.zIndex=data.length*2-i*2+"";
    //console.log(data.length*2-i*2+"");
    
    this.drawFillerBoxes(placeholder,page.colors[i],q,this.data.length*2-i*2-1,w,h);
    
    placeholder.appendChild(img);
  },

  drawFillerBoxes: function(element,color,q,level,w,h){  
    for (i=0; i<q; i++)
    {
      element.appendChild(this.drawFillerBox(color, i, level,0,0));
    }
    // Make sure we should add the last element..
    
    if ( ((q==0 || q==2) && h<qsize) ||
      ((q==1 || q==3) && w<qsize) )
      return;
    
  //   console.log("appendling child." + q);
  //   console.log(h + qsize + "");
    d= this.drawFillerBox(color,q,level,w,h);
    if (d)
      element.appendChild(d);
    //element.appendChild(drawFillerBox(color,q,level,w,h));
  },
  // Puts a square in the given quadrant, next to the angle image that has a width & height of w & h
  drawFillerBox: function(color, q, level,w,h){  
    //return null;
    var div=document.createElement("div");
    div.style.backgroundColor=color;
    div.className="chart_panel";
    
  //   t = (q==2 || q==3) ? size/2 : 0;
  //   div.style.top=t + "px";
  //   l = (q==1 || q==2) ? size/2 : 0;
  //     //have to special case this one
  //   if (q==0){
  //      div.style.width=(qsize-w)+"px";
  //      //div.style.height=(qsize-h)+"px";     
  //   }
  //   div.style.left=l + "px";
    div.style.zIndex=level+"";
    
    // div dimentions
    var dw,dh,dt,dl;
    qs=this.qsize;
    
    dw = ((q==1 || q==3) ? w : qs-w );
    
    
    //console.log(px( ((q==1 || q==3) ? w : qsize-w )));
    if (q==0){
  //      div.style.width=px(qsize-w);
      dl=px(0); 
    }
    if (q==1){
  //     div.style.width=px(w);
      dl=qs;
      dh=qs-h;
    }
    if (q==2){
  //     div.style.width=px(qsize-w);
      dl=qs+w;
      dt=qs;  
      dh=qs-h;
    }
    if (q==3){
  //     div.style.width=px(w);
      dh=qs-h;
      dt=qs+h;
      //div.style.left=px(0);
    }
    
    div.style.left=px(dl);
    div.style.top=px(dt);
    if (dw==0) dw=qs;
    div.style.width=px(dw);
    div.style.height=px(dh);
  
    return div;
  },
  imageForQuadrant: function (i,q){
    return "/images/c/line" + i + "" + q + ".png"
  },
  // Returns the sum of all entries up to i in an array
  sumPrevious: function(i,array){
    return array.inject(0, function (a,v){return a+v;}) - array[i];
  }
}

function px(v) {  return v + "px";}


LineGraph.Methods={
// relativize
  relativize:function(data){
    var max=0;
    data.each(function(e){ if (e>max) max=e; });
    for (i=0;i<data.length;i++){ 
      data[i]=Math.floor((data[i]/max)*size); 
    }
  }
}
Object.extend(LineGraph,LineGraph.Methods);
  






