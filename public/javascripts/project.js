// Dean Edwards/Matthias Miller/John Resig

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

function px(v) {  return v + "px";}

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
};

var Page = Class.create();
Page.prototype = {
  initialize:function(){
    this.colors=["#a4d898","#fdde88","#ff9e61","#d75b5c","#7285b7","#98d5d8","#989cd8","#d8bb98"];
      
    var StringMethods={
      firstUpCase:function(){ return this[0].toUpperCase() + this.slice(1,this.length);}
    };
    Object.extend(String.prototype,StringMethods);
  
    var ArrayMethods={ 
      sum:function(){var s=0; for (var i=0; i<this.length; i++) s+=this[i]; return s; },
      max:function(){var m=0; for (var i=0; i<this.length; i++) if (this[i] > m) m=this[i]; return m},
      min:function(){var m=Number.MAX_VALUE; for (var i=0; i<this.length; i++) if (this[i] < m) m=this[i]; return m}
    };
    Object.extend(Array.prototype,ArrayMethods);
    
    this.preferences=new Preferences();  
        
    // Build the paginator objects
    this.totalReferersPager=new Pagination("totalReferers",20);
  },
  // Switch section
  menuNav: function(e){
    var section=e.title;
    
    this.removeClassFromElements("active","menu");
    e.className+=" active";
    
    Element.hide(this.activeSection);
    this.activeSection=section;        
    Element.show(section);
    //Effect.Appear(section,{duration:.25});  // this looks lilke trash in IE
    
    this.preferences.update("section",section);
    

  },
  // Navigate within a section
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
    //console.log("testing document", document.getElementsByClassName);
//     if ($)
//       console.log("$ exists");
//     if (document.getElementsByClassName){
//       //console.log(document.getElementsByClassName);
//       console.log("getElementsByClassName exists");
//     }else{
//       if (Element)
//         console.log("Element exists");
//       console.log("getElementsByClassName does not exist");
//       }
    var elements=document.getElementsByClassName(c,start);
    if (elements!=null){
      elements.each(
        function(e){e.className=e.className.replace(c,"");}) 
    }      
  },
  // Returns the image file used for a quadrant. i is the color (0-5ish)
  imageForQuadrant: function (i,q){
    return "/images/c/line" + i + "" + q + ".png"
  }
};



function init(){  

  // quit if this function has already been called  
  if (arguments.callee.done) return;
  
  // flag this function so we don't do the same thing twice
  arguments.callee.done = true;
  
  // kill the timer
  if (_timer) clearInterval(_timer);
  
 
  // delete this junk
  now=10; 
  
  populatePage();
  
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


chartData=[3,4,2,3,5,6,3];
chartData=[3,2,2,1];

function populatePage(){

  // hits section
  TableDisplay.showTable("hits_today",hitsDayData,TableDisplay.hitsToday,2,
    "Hits today", ["","Hits","Unique"]);
  TableDisplay.showTable("hits_week",hitsWeekData,TableDisplay.hitsWeek,2,
    "Hits this week", ["","Hits","Unique"]);
  TableDisplay.showTable("hits_month",hitsMonthData,TableDisplay.hitsMonth,2,
    "Hits this month", ["","Hits","Unique"]);
  
  // referer section
//   TableDisplay.showTable("referers_total",referersTotalData,TableDisplay.refererRow,3,
//     "Top referrals", ["Referer","Total hits"], true);
//   referersPager = new Pagination(0,0);
   page.totalReferersPager.displayProperties("referers_total",referersTotalData,TableDisplay.refererRow,3,"Top referrals", ["Referer","Total hits"]);
   page.totalReferersPager.showTable();
  
    
  TableDisplay.showTable("referers_unique",referersUniqueData,TableDisplay.refererRowWithDate,3,
    "Unique referrals", ["Referer","First visited"]);
    
  TableDisplay.showTable("referers_recent",referersRecentData,TableDisplay.refererRowWithDate,3,
    "Recent Referer", ["Referer","Visited"] );

  // pages section
  TableDisplay.showTable("pages_popular",pagesPopularData,TableDisplay.pagesRow,2,
    "Popular pages", ["","Hits"]);
  TableDisplay.showTable("pages_recent",pagesRecentData,TableDisplay.pagesRecentRow,3,
    "Recent pages", ["","Hits"]);
    
  // glance section
  TableDisplay.showTable("glance_referers_today",[],TableDisplay.refererRow,2,
    "", ["Top referers today","Hits"]);
  TableDisplay.showTable("glance_referers_week",[],TableDisplay.refererRow,2,
    "", ["Top referers this week","Hits"]);
  
  // don't graph uniques on the line graph
  var onlyHits = [];
  for (var i=0;i<hitsWeekData.length;i+=2) onlyHits[i/2]=hitsWeekData[i];
  lg=new LineGraph("hitsweek-linegraph",onlyHits, 200,110, "week",1);
  lg.drawGraph();  

  // visitor details graphs
  pg = new PieGraphDisplay("browser_details","Web browsers", browserData,browserLabels);
  pg.drawChart();  
  pg = new PieGraphDisplay("os_details","Operating systems", osData,
  osLabels);
  pg.drawChart();  
  
};



/*
 * Table display
 */
TableDisplay=Class.create();

TableDisplay.prototype={
  initialize: function(data, cellFunc, step, title,headerNames){  
    this.title=title;    
    this.headerNames=headerNames;
    this.data=data;
    this.step=step;
    this.cellFunc=cellFunc;
  },
  buildTable: function(){
    var html="<table>"+this.tableHeader();
    var dataMax=this.data.max();
    for (i=0;i<this.data.length/this.step;i++)
    {
      html+=this.cellFunc(i,this.data,dataMax);
    }
    html+="</table>" + '<div class="table-footer-cap"></div>';
//     return this.dialog(this.title,html)
    return html;
  },
  //   dialog: function(t,content){
//     return '<div class="dialog"><div class="hd"><div class="c"></div></div><div class="bd">'+
//       '<div class="c"><h1 class="title">' + t + '</h1>'+content + '</div></div><div class="ft">' + 
//       '<div class="c"></div></div></div>';
//   },
  tableHeader: function(){
    if (this.headerNames==null)
      return "" 
    var html='<tr class="header">'
    for (i=0;i<this.headerNames.length;i++)
      html += (i==0 ? "<th class='f'>" : "<th>") + this.headerNames[i] + "</th>";
    html+"</tr>"
    return html;
  },
  // Create a cell that has a graph in it
  graphCell: function(text, percent){
    var style="style=\"width:" + percent + "%\"";
    var cellData="<div ><div " + style + "></div>"+
    "</div><span>" + text + "</span>";
    return this.td(cellData,"graph-cell");
  },
  td: function(data, c, style){
    return "<td " + 
      (c ? 'class="' + c+'" ' : "") +
      (style ? 'style="' + style +'" ' : "") + 
      ">" + data + "</td>";
  },
  tr: function(data,c){
    return "<tr " + 
    (c ? 'class="' + c+'" ' : "") + ">" + data + "</tr>";
  },
  columnPercent: function(data, max){
    // 80 means only allow graphs in the background to grow to 80% of the td width
    return Math.round(data/max*80);   
  },
  classString: function(i, func){
    var c=(i%2==0 ? "a" : "");  // alt row
    if (func!=null)
      c+=func(i);
    return c;
  },
  hitsRow: function(i,data,dataMax, dateString, trClassString)
  {
    // data points
    var p1=data[i*2], p2=data[i*2+1]
    
    var percent=this.columnPercent(p1,dataMax);
    var percent2=this.columnPercent(p2,dataMax);
    
    var cell1 = this.graphCell(p1,percent);  
    var cell2 = this.graphCell(p2,percent2);  
    
    var classString = trClassString ? trClassString  : this.classString(i);
    return this.tr( this.td(dateString,"f") +cell1 + cell2, classString);  
  }

};

TableDisplay.Methods={
  refererRowWithDate: function(i,data,dataMax){
    f=TableDisplay.refererRow.bind(this);
    return f(i,data,dataMax,true);
  },
  // "isDate" displays the second column as "time ago"
  refererRow: function(i,data,dataMax,isDate){
    var url=data[i*3];
    var landedOn=data[i*3+1];
    var linkCaption = DisplayHelper.truncateRight(unescape(url),45);
    var landedOnCaption = DisplayHelper.truncateLeft(unescape(landedOn),60);
    var html = linkCaption.link("http://"+url) + '<span class="to">To&nbsp;'+landedOnCaption.link("http://"+landedOn)+'</a></span>';
    var cell1 = this.td(html, "f");
    var cell2 = this.td( isDate ? 
      // might be -1
      DisplayHelper.timeAgo(data[i*3+2]) : data[i*3+2]
     );
    return this.tr(cell1 + cell2, this.classString(i));
  },
  pagesRowWithDate: function(i,data,dataMax){
    f=TableDisplay.pagesRow.bind(this);
    return f(i,data,dataMax,true);
  },
  pagesRecentRow:function(i,data,dataMax){
    var url = data[i*3];
    var referer = data[i*3+1];
    var time = data[i*3+2];
    var refererCaption = DisplayHelper.truncateRight(unescape(referer),45);
    var linkCaption = DisplayHelper.truncateLeft(unescape(url),45);
    //var html = linkCaption.link("http://"+url);
    var tdHtml = linkCaption.link("http://"+url) + '<span class="to">From&nbsp;'+refererCaption.link("http://"+referer)+'</a></span>';
    var cell1=this.td(tdHtml,"f");
    var cell2 = this.td(DisplayHelper.timeAgo(time));
    
    return this.tr(cell1+cell2, this.classString(i));
  },
  pagesRow:function(i,data,dataMax, isDate){
    var url = data[i*2];
    var linkCaption = DisplayHelper.truncateLeft(unescape(url),45);
    //var html = linkCaption.link("http://"+url);
    var html = linkCaption.link("http://"+url);
    var cell1=this.td(html,"f");
    var cell2 = isDate ? DisplayHelper.timeAgo(data[i*2+1]) : data[i*2+1];
    cell2=this.td(cell2);
    return this.tr(cell1+cell2, this.classString(i));
  },
  showTable: function(htmlID, data, cellFunction, dataStep, title, headerNames){
      var display = new TableDisplay(data,cellFunction,dataStep,title,headerNames);
      $(htmlID).innerHTML=DisplayHelper.dialog(title,display.buildTable());
  },  
  hitsMonth:function (i,data,dataMax){
      var day=DisplayHelper.formatWeeksAgo(i);
      return this.hitsRow(i,data,dataMax,day);
  },
  hitsWeek: function(i,data, dataMax){
    var day=DisplayHelper.showDay((new Date()).getDay()-i);
    return this.hitsRow(i,data,dataMax,day);
  },
  hitsToday: function(i,data, dataMax){
    var classString=this.classString(i, function(i){return (page.date.getHours()-i < 0 ? " old" : "")});
    var day=DisplayHelper.showHour(page.date.getHours()-i);
    return this.hitsRow(i,data,dataMax,day,classString);
  }
};
Object.extend(TableDisplay,TableDisplay.Methods);

Pagination=Class.create();

Pagination.prototype={
  initialize: function(name, totalPages){
    this.name=name;
    this.total=0;  
    this.current=0;
    this.request=null;
  },
  displayProperties: function(htmlID,data,cellFunction,dataStep,title,headerNames){
    this.htmlID=htmlID;
    this.data=data;
    this.title=title;
    this.cellFunction=cellFunction;
    this.dataStep=dataStep;
    this.headerNames=headerNames;
  },
  showTable: function(){
    var display = new TableDisplay(this.data,this.cellFunction,this.dataStep,this.title,this.headerNames);    
    $(this.htmlID).innerHTML=DisplayHelper.dialog(this.title,display.buildTable() + this.buildNavMenu());
//     var navPanel = document.createElement("div");
//     navPanel.innerHTML=this.buildNavMenu();
//     $(this.htmlID).appendChild(navPanel);
    //$(htmlID).innerHTML=page.dialog(title,display.buildTable());
  },
  buildNavMenu:function (){
    html='<a href="" onclick="return page.' + this.name + 'Pager.next();"> > </a>';
    return html;
  },

  next:function(){
    new Ajax.Request('/project/data/'+this.name, 
    {asynchronous:true, evalScripts:true, 
      parameters:"p="+this.current+1,
      onComplete:this.show.bind(this)
    });
    return false;
  },
  show: function(request, page){
//   console.log(this.htmlID, $(this.htmlID));
    console.log(request.responseText);
    data=eval(request.responseText);    
    console.log(data);
    console.log($(this.htmlID));
    //this.current++;
     var display = new TableDisplay(data,this.cellFunction,this.dataStep,this.title,this.headerNames);    
     $(this.htmlID).innerHTML=DisplayHelper.dialog(this.title,display.buildTable() + this.buildNavMenu());

//     $(this.htmlID).innerHTML="hey hey";
    console.log("end of func");
    
  }
};
// pagination=new Pagination();
Pagination.Methods={
  
}
Object.extend(Pagination,Pagination.Methods);


/*
 * Generic display methods
 */
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
      return "just&nbsp;now";
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
  formatWeeksAgo: function(n,weeks){
    if (n==0) return "this&nbsp;week";
    if (n==1) return "last&nbsp;week";
    return n + "&nbsp;weeks&nbsp;ago";
  },
  showHour: function(i){
    var t=i%24;
    t=t<0 ? 24+t : t;
    h=(t)%12;
    return (h==0 ? 12 : h) + ":00" + ( (t<12) ? "am" : "pm");
  },
  days:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],
  showDay: function(i, showToday){
    i=i%7;
    i=i<0 ? 7+i : i;
    
    return i==0? (showToday ? "Today" : this.days[i]) : this.days[i];
  },
  // Will ellipsize from the left, e.g. philisoft.com/blog => ...isoft.com/blog.
  // Should we try and break on periods or slashes, if they're close?
  // Usually that's what we want
  truncateLeft: function(str,n){
    if (str.length<n) return str;
    var mod = str.slice(n,str.length);
    for (var i=0; i<5; i++){
      if (mod[i]=="." || mod[i]=="/")
        return ".."+mod.slice(i,mod.length);
    }
    return ".." + mod;
  },
  truncateRight: function(str,n){
    if (str.length<=n) return str;
    var mod = str.slice(0,n);
    for (var i=n; i>n-5; i--){
      if (mod[i]=="." || mod[i]=="/")
        return mod.slice(0,i)+"..";
    }
    return mod+"..";
  },
  dialog: function(title,content){
    return '<div class="dialog"><div class="hd"><div class="c"></div></div><div class="bd">'+
      '<div class="c"><h1 class="title">' + title + '</h1>'+content + '</div></div><div class="ft">' + 
      '<div class="c"></div></div></div>';
  }
}
Object.extend(DisplayHelper,DisplayHelper.Methods);


/*
 * Line graph drawing
 */

LineGraph=Class.create();
LineGraph.prototype={
  initialize: function(id,data, width, height, labels, style){
    this.element=$(id);    
    //this.size=120;
    this.width=width;
    this.height=height;
    this.max = data.max();
    this.min = data.min();
    this.labels=labels;
    this.style=style;
    
    // If min is 10% of the max, don't bother making a caret in the graph
    if (this.min / this.max < .1)
      this.min=0;    
    
    var reversed = data.reverse();
    
    // non-relative data
    this.originalData=reversed;
    this.data=LineGraph.relativize(reversed,this.height,this.max,this.min);
    //this.min=data.min();
    // Pick a line color. Colors are defined in page.colors
    this.lineColor=(style==0 ? 1 : 0);
    
  },
  
  drawGraph: function(){  
    // Graph container
    var g=document.createElement("div");
    g.className="linegraph";
    var imgs=[]
    var hwidth=this.width/(this.data.length-1);
  
    // Add the first "dot" on the graph
    if (this.data.length>0)
      
    // Append the first data point to the diagram
    g.appendChild(this.dataPointDot(this.originalData[0],0,this.height-this.data[0],1));

    // Only draw lines starting with the second point (i=1); the first point is our starting point
    // (the intersection with the Y axis)
    
    for (i=1;i<this.data.length; i++){
      var div=document.createElement("div");
      div.className="color";
      if (this.style<2)
        div.style.backgroundColor=page.colors[this.lineColor];
      div.id=i+"";
      var img=document.createElement("img");    
      
      // Height of the point before this one
      var prevHeight=this.data[i-1] ? this.data[i-1] : 0;
      // Whether the line is pointing up. Up=1, down=-1
      var u=prevHeight<=this.data[i] ? 1 : -1;     
      
      //img.src=(u==1 ? "/images/c/line13.png" : "/images/c/line10.png");    
      //img.src=(u==1 ? page.imageForQuadrant(this.lineColor,3) : page.imageForQuadrant(this.lineColor,0));
      
      img.src=this.lineGraphImage(this.style,u);
      img.className="line";
      
      img.style.width=px(hwidth);
      div.style.width=px(hwidth);
      
      // difference in our heights
      var h=this.data[i]-prevHeight;
      
      
      
      // amount of space there is above the previous element
      var t=this.height-prevHeight;
      
      //console.log(h,u);
      img.style.height=px(h*u);
      
      var ourTop = t-(u>0  ? h : 0)
      
      div.style.height=this.height-(h*u)-ourTop+"px";
      
      div.style.top=ourTop+(h*u)+"px";
      img.style.top=ourTop+"px";
      div.style.left=(i-1)*hwidth+ "px";
      img.style.left=(i-1)*hwidth+ "px";
      
      // Add a dot for the datapoint to a curve.
      //g.appendChild(this.dataPointDot(this.originalData[i],i*hwidth,this.height-this.data[i],u==1));
      g.appendChild(this.dataPointDot(this.originalData[i],i*hwidth,this.height-this.data[i],u==1));
      
      g.appendChild(img);
      g.appendChild(div);
    }    
    this.showLabels(g);
    this.element.appendChild(g);
  },  
  // if the line is pointing up, we need to move the dot upward somewhat
  dataPointDot: function(data,x,y, pointingUp){
    var dot=document.createElement("div");
    dot.className="linegraph-dot" + (pointingUp ? "" : " linegraph-dot-up");
    dot.style.left=px(x);

    dot.onmouseover=function(){Element.show(this.firstChild);};
    dot.onmouseout=function(){Element.hide(this.firstChild);};
    //dot.style.top=u==1 ? img.style.top : px(ourTop+(h*u)-7);
    
    //dot.style.bottom=px(this.data[i]);
    dot.style.top=px(y);
    
    text = document.createElement("div");
    text.className="linegraph-dot-caption";
    text.style.display="none";
  
    text.innerHTML=data+"";    
    
    dot.appendChild(text);
    return dot
  },
  lineGraphImage: function(i,u){
    var d = (u==1 ? 0 : 1);
    return "/images/c/linegraph" + i + "" + d + ".png"
  },
  showLabels: function(graphContainer){
    if (this.min>0){
//       var div=document.createElement("div");
//       div.className="line-x-axis";
//       div.innerHTML=this.min;
//       div.style.right="100%";
//       div.style.bottom=px(14);
      
//       graphContainer.appendChild(div);
      var minLabel = this.yLabel(this.min);
      minLabel.style.bottom=px(14);
      graphContainer.appendChild(minLabel);
    }
    var maxLabel = this.yLabel(this.max);
    maxLabel.style.top=0;
    graphContainer.appendChild(maxLabel);
    
    if (this.labels){
      var hwidth=this.width/(this.data.length-1);
      for (var i = this.data.length-1;i>=0;i--){
        var t="";
        if (this.labels=="week")
          //t=DisplayHelper.showDay(i-page.date.getHours()-1,false);
          //t=DisplayHelper.showDay(i);
          t=day=DisplayHelper.showDay((new Date()).getDay()+i+1)
        var l=this.xLabel(t.slice(0,2));
        l.style.left=px(hwidth*i);
        graphContainer.appendChild(l);
      }
    }
    
    //graphContainer.appendChild(this.graphLabel("number",0,0));
  },
  xLabel: function(text){
    var div=document.createElement("div");
    div.className="line-x-label";
    div.innerHTML=text;
//     div.style.top="100%";
//     div.style.bottom=y;   
    return div;
  },
  yLabel: function(text){
    var div=document.createElement("div");
    div.className="line-y-label";
    div.innerHTML=text;
//     div.style.right="100%";
//     div.style.bottom=y;   
    return div;
  }
};
LineGraph.Methods={
// relativize
  relativize:function(data, height, max, optionalMin){  
    relativeData=Array(data.length);
    // Don't use the entire min value. We don't want the lowest poitn to be "0"
    var min = optionalMin? Math.round(optionalMin*.8) : 0;
    
    max-=min;
    
    // Avoid divide by zero
    if (max==0) max=1;
    //data.each(function(e){ if (e>max) max=e; });
    for (i=0;i<data.length;i++){ 
      relativeData[i]=Math.floor(((data[i]-min)/max)*height); 

    }
    return relativeData;
  }
}
Object.extend(LineGraph,LineGraph.Methods);
  
  
/*
 * Pie chart graphing
 */

PieGraphDisplay = Class.create();
PieGraphDisplay.prototype={
  initialize: function(id,title,data,labels){
    this.element=$(id);
    this.size=150;
    this.qsize=this.size/2;
    this.data=[];
    this.title=title;
    this.labels=labels;
        
    // relativize data
    var total=data.sum();    
    for (var i=0;i<data.length;i++)
           this.data[i]=Math.floor((data[i]/total)*360);

  },

  drawChart: function (){   
    var placeholder=document.createElement("div")
    placeholder.style.position="absolute";
    placeholder.style.width=px(this.size);
    placeholder.style.height=px(this.size);
    
    for (var i=0;i<this.data.length-1;i++){
      this.graphQuadrant(i,this.data,placeholder);
    }
    placeholder.style.backgroundColor=page.colors[this.data.length-1];
    
    this.drawTextLabels(placeholder);
    this.element.appendChild(placeholder);
  },

  graphQuadrant: function(i,data, placeholder){
    var v=data[i]+this.sumPrevious(i,data);
    
    // quadrant this datum falls in
    var q=Math.floor(v/90);
    
    // Multiplier
    var m=90*(q+1);
  
    // Find out how many degrees we are into this quadrant, ie.
    // 300 is 30 degrees into quad three
    var deg = (m-v)/90;    
    
    var w,h;
    var s=this.size;
    var qs=this.qsize;
    //console.log("drawing image for ",i, q, "deg", v);
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
      h=(v >=(45+q*90) ? qs : s*(1-deg));  
    }else{
      h=(v <=(45+q*90) ? qs : s*(deg));      
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
  
    img.src=page.imageForQuadrant(i,q);
    
    img.style.zIndex=data.length*2-i*2+"";    
    
    this.drawFillerBoxes(placeholder,page.colors[i],q,this.data.length*2-i*2-1,w,h);
    
    placeholder.appendChild(img);
  },

  drawFillerBoxes: function(element,color,q,level,w,h){  
    for (var i=0; i<q; i++)
    {
      element.appendChild(this.drawFillerBox(color, i, level,0,0,true));
    }
    // Make sure we should add the last element..
    
    if ( ((q==0 || q==2) && h<this.qsize) ||
      ((q==1 || q==3) && w<this.qsize) )
      return;
    
  
    d= this.drawFillerBox(color,q,level,w,h);
    if (d)
      element.appendChild(d);
  },
  // Puts a square in the given quadrant, next to the angle image that has a width & height of w & h
  drawFillerBox: function(color, q, level,w,h,block){  
    
    var div=document.createElement("div");
    div.style.backgroundColor=color;
    div.className="chart_filler";
    div.style.zIndex=level+"";
    
    // div dimentions
    var dw=dh=dt=dl=0;
    var qs=this.qsize;
    
    dw = ((q==1 || q==3) ? w : qs-w );
    
    
    
    if (q==0){
  //      div.style.width=px(qsize-w);
      dl=0; 
      dh=qs;
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
      //console.log("drawing filler for q2. w",w,"qs",qs,"dl",dl, "dw",dw);
      //dh=qs-h;
      // If it's a 0 height, we should fill up the whole box.
      dh= (h==0 ? qs: h);
      //console.log("setting q2 height to ",dh, " h",h);
    }
    if (q==3){
  //     div.style.width=px(w);
      dh=qs-h;
      
      dt=qs+h;
      //div.style.left=px(0);
    }
    
    //console.log("q",q, " dh", dh , " h",+ h);
    
    div.style.left=px(dl);
    
    div.style.top=px(dt);
    if (block){
      dw=qs;
      dh=qs;
    }
    div.style.width=px(dw);
    div.style.height=px(dh);
  
    return div;
  },
  drawTextLabels: function(placeholder){
    var labelBox=document.createElement("div");
    labelBox.className="label_box";
    labelBox.style.left=px(this.size);
    labelBox.innerHTML="<span class='title'>"+this.title+"</a>"
    var ul = document.createElement("ul");
    ul;
    for (var i=0; i<this.labels.length;i++){
      var div=document.createElement("li"); 
      div.innerHTML="<div class='color_box' style='background-color:" + 
      page.colors[i] + "'></div>" + this.labels[i];
      div.className="label";      
      ul.appendChild(div);      
    }
    labelBox.appendChild(ul);
    placeholder.appendChild(labelBox);
  },
  // Returns the sum of all entries up to i in an array
  sumPrevious: function(i,array){
    var s=0;
    for (var j=0; j<i;j++)
      s+=array[j];
    return s;
  }
}


page = new Page();