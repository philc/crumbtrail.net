//size=200;
//active="referers";
colors=["#a4d898","#fdde88","#d75b5c","#7285b7"];
now=10;
data=[]
timers=Array()
sections=["glance","hits","referers","pages","searches","details"];
sections.each(function(e){timers[e]=new MenuTimer();});

chartData=[12,22,10,26];
chartData=[.5,2,5,5];


// chartData=[1,4,4,7];
//chartData=[2,4,4,6];

function MenuTimer(){
  this.timer=null;
  this.timeout=2000;
}
prefMenuTimer=new MenuTimer()

for (i=0;i<24;i++)
{
  data[i*2]=i*3;
  data[i*2+1]=i*6;
}


function populate(){
  $("hits_today").innerHTML=table("Hits today", ["Total","Hits","Unique"],data,2,todayInner);
  $("referers_total").innerHTML=table("Total referrals", 
    ["Referer","Total&nbsp;hits"],referersTotal,2,refererTotalInner);
  //$("referers_recent").innerHTML=table("Most recent referers",["Recent referer"],recentReferers,1,refererRecentInner);
  $("referers_unique").innerHTML=table("Newest unique referers",["Referer","First&nbsp;visited"],referersUnique,2,refererUniqueInner);  
  drawChart("chart",chartData);
}
function showHour(i){
  var t=i%24;
  return (t%12)+1 + ":00" + (t<12 ? "am" : "pm");
}
function refererRecentInner(i,data){
  var url=unescape(data[i*2]);
//   var url=data[i*2];  
  return '<tr' + classString(i) +'><td class="f">' + linkFor(url,url)+ "</td></tr>"
}
function refererUniqueInner(i,data){
  var url=unescape(data[i*2]);
//   var url=data[i*2];  
  return '<tr' + classString(i) +'><td class="f">' + linkFor(url,url)+ "</td><td>" + timeAgo(data[i*2+1]) + "</td></tr>"
}
function timeAgo(date){
  var diff=(new Date())-date;
  var mins=Math.floor(diff/1000/60);
  var hrs=Math.floor(mins/60);
  var days=Math.floor(hrs/24);
  var weeks=Math.floor(days/7);
  var mos=Math.floor(days/30);
  if (mins<1)
    return "few&nbsp;secs&nbsp;ago";
  else if (hrs <1)
    return formatTimeAgo(mins,"min");
  else if (days < 1)
    return formatTimeAgo(hrs,"hr");
  else if (weeks < 1)
    return formatTimeAgo(days,"day");
  else if (mos<1)
    return formatTimeAgo(weeks,"week");
  else 
    return formatTimeAgo(mos,"month");
}
function formatTimeAgo(n,word){
  return n + "&nbsp;" + (n>1 ? word+"s" : word) + "&nbsp;ago";
}
function todayInner(i,data){
  var c=classString(i, function(i){(i+now+1 > 24 ? " old" : "")});
  
//   tr=((i+now+1) > 24) ? '<tr class="old">' : '<tr>';
  return '<tr' + c + '>' + showHour(i+now) + "</td><td>" + i*120 + "</td><td>" + i*60 + "</td></tr>";  
}
function refererTotalInner(i,data){
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
function week_inner(i){
  return "<tr><td class='f'>" + (i+1) + "</td><td>" + i*400 + "</td><td>" + i*190 + "</td></tr>";
}
function month_inner(i){
  return "<tr><td class='f'>" + (i+1) + "th</td><td>" + i*1120 + "</td><td>" + i*260 + "</td></tr>";
}
function table(t,header, data, step, proc){
  var html="<table>"+tableHeader(header);
  for (i=0;i<data.length/step;i++)
  {
    html+=proc(i,data);
  }
  html+="</table>"
  return dialog(t,html)
}
function dialog(t,content){
  return '<div class="dialog"><div class="hd"><div class="c"></div></div><div class="bd">'+
      '<div class="c"><h1 class="title">' + t + '</h1>'+content + '</div></div><div class="ft">' + 
      '<div class="c"></div></div></div>';
}
function tableHeader(headers){
  if (headers==null)
    return "" 
  var html='<tr class="header">'
  //headers.each(function(e){html+="<th>"+e+"</th>";});
  for (i=0;i<headers.length;i++)
    html += (i==0 ? "<th class='f'>" : "<th>") + headers[i] + "</th>";
  html+"</tr>"
  return html    
}
function populate_table(id, f, n){
  var html="<table><tr><td>hour</td><td>total</td><td>unique</td></tr>";
  for (i=0; i<n; i++)
  {
    html+=f(i);
  }
  html+="</table>";
  $(id).innerHTML=html
}




function show_stat(period){
  if (period=="today"){
    Element.show("hits_today");
    Element.hide("hits_week");
    Element.hide("hits_month");  
  }
  else if (period=="week"){
    Element.hide("hits_today");
    Element.show("hits_week");
    Element.hide("hits_month");  
  }
  else if (period=="month"){
    Element.hide("hits_today");
    Element.hide("hits_week");
    Element.show("hits_month");  
  }
  return false;
}





function drawGraph(id, data){
  var p=$(id);
  var g=document.createElement("div");
  g.className="graph";
  //size=120;
  size=200;
  //size=150;
  var imgs=[]
  var hwidth=size/(data.length-1);
 
  // relativize
  var max=0;
  data.each(function(e){ if (e>max) max=e; });
  
  for (i=0;i<data.length;i++){ 
    data[i]=Math.floor((data[i]/max)*size); 
  }

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
  
  p.appendChild(g);
}


function previousValues(i,arr){
  var sum=0;
  for (var j=0;j<i;j++){
    sum+=arr[j];
  }
  return sum;
}


function drawChart(id, data){
  size=150;
  qsize=size/2;
  
  var placeholder=document.createElement("div")
  placeholder.style.position="absolute";
  placeholder.style.width=px(size);
  placeholder.style.height=px(size);
  //placeholder.className="placeholder";

  var max=0;
  var total=0;
  data.each(function(e){ total+=e; if (e>max) max=e; });  
  for (var i=0;i<data.length;i++){ data[i]=Math.floor((data[i]/total)*360);}
  
  //console.log(data);
  
  for (var i=0;i<data.length-1;i++){
    graphQuadrant(i,data,placeholder);
  }
  placeholder.style.backgroundColor=colors[data.length-1];
  
//   graphQuadrant(0,data, placeholder);
//   graphQuadrant(1,data, placeholder);
//   graphQuadrant(2,data, placeholder);
//   graphQuadrant(3,data, placeholder);
  
  $(id).appendChild(placeholder);
}

function graphQuadrant(i,data, placeholder){
  v=data[i]+previousValues(i,data);
  //console.log("data:" + v);
  console.log("graphing " + i + " a" + v);
  // quadrant
  //console.log(v);
  //var q=cap(Math.floor(v/90),3);
  var q=Math.floor(v/90);
  
  // Multiplier
  var m=90*(q+1);

  // Find out how many degrees we are into this quadrant, ie.
  // 300 is 30 degrees into quad one
  var deg = (m-v)/90;
  
  
  var w,h;
  if (q==0){
    w=(v <=(45+q*90) ? qsize : size*(deg));
    h=(v >=(45+q*90) ? qsize : size*(1-deg));
  }else if (q==1){
    h=(v <=(45+q*90) ? qsize : size*(deg));
    w=(v >=(45+q*90) ? qsize : size*(1-deg));
  }else if (q==2){
    //a=(v <=(45+q*90) ? qsize : size*(1-v/m));
    w=(v <=(45+q*90) ? qsize : size*(deg));
    h=(v >=(45+q*90) ? qsize : size*(1-deg));  
  }else{
    h=(v <=(45+q*90) ? qsize : size*(deg));
    //a=(v >=(45+q*90) ? qsize : size*(1-v/m));
    w=(v >=(45+q*90) ? qsize : size*(1-deg));
  }



  img=document.createElement("img");    
  img.className="chart_image";  
  img.style.width=w+"px";
  img.style.height=h+"px";
  img.style.zIndex="1";
  o1=(q==1||q==2) ? 0 : 1;
  o2=(q==2||q==3) ? 0 : 1;
  
  img.style.left=qsize-o1*w+"px";
  
  img.style.top=qsize-o2*h + "px";

  img.src=imageForQuadrant(i,q);
  
  img.style.zIndex=data.length*2-i*2+"";
  //console.log(data.length*2-i*2+"");
  
  drawFillerBoxes(placeholder,colors[i],q,data.length*2-i*2-1,w,h);
  
  placeholder.appendChild(img);
}

function drawFillerBoxes(element,color,q,level,w,h){

  for (i=0; i<q; i++)
  {
    element.appendChild(drawFillerBox(color, i, level,0,0));
  }
  // Make sure we should add the last element..
  
  if ( ((q==0 || q==2) && h<qsize) ||
    ((q==1 || q==3) && w<qsize) )
    return;
  
//   console.log("appendling child." + q);
//   console.log(h + qsize + "");
  d= drawFillerBox(color,q,level,w,h);
  if (d)
    element.appendChild(d);
  //element.appendChild(drawFillerBox(color,q,level,w,h));
}
// Puts a square in the given quadrant, next to the angle image that has a width & height of w & h
function drawFillerBox(color, q, level,w,h){  
  //return null;
  div=document.createElement("div");
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
  
  dw = ((q==1 || q==3) ? w : qsize-w );
  
  
  //console.log(px( ((q==1 || q==3) ? w : qsize-w )));
  if (q==0){
//      div.style.width=px(qsize-w);
     dl=px(0); 
  }
  if (q==1){
//     div.style.width=px(w);
    dl=qsize;
    dh=qsize-h;
  }
  if (q==2){
//     div.style.width=px(qsize-w);
    dl=qsize+w;
    dt=qsize;  
    dh=qsize-h;
  }
  if (q==3){
//     div.style.width=px(w);
    dh=qsize-h;
    dt=qsize+h;
    //div.style.left=px(0);
  }
  
  div.style.left=px(dl);
  div.style.top=px(dt);
  if (dw==0) dw=qsize;
  div.style.width=px(dw);
  div.style.height=px(dh);

   return div;

}
function px(v) {  return v + "px";}

function imageForQuadrant(i,q){
  base="/images/c/line";
  
  return base +  i +"" +q+".png"
}

// Switch section
function nav(e){
  hidePanel(active);
  //document.getElementsByClassName('active','menu').each(function(e){e.className="";})
  removeClassFromElements("active","menu");
  e.className="active";
  active=e.id;
  
  updatePreference("panel",e.id,prefMenuTimer);
  showPanel(e.id);
  return false;
}
function updatePreference(n,v,timer){
  if (timer!=null)
    clearTimeout(timer.timer);
  timer.timer=setTimeout(setPref(n,v),timer.timeout);
}
// Sends a view preference and a value asynchronously.
// name/values can be are panel/panel that's active,
// and section/section that's active
function setPref(n,v){
  var pars="p="+n+"&v="+v;
  return function(){new Ajax.Request('/project/setpref/',
    {asynchronous:true, parameters:pars
    });
  }
}
function showPanel(panel){
  $(panelID(panel)).style.display="block";
}
function hidePanel(panel){
  $(panelID(panel)).style.display="none";
}
function panelID(panel){
  return panel + "_panel";
}
function sectionNav(section,v,linkElement){
    //if (active!="")
  //hidePanel(active);
  document.getElementsByClassName(section,panelID(section)).each(function(e){Element.hide(e)});
  removeClassFromElements('navlink_active',panelID(section));
  linkElement.className+=" navlink_active";
  //e.className="active";
  //active=e.id;  
  //console.log(section);
  updatePreference(section,v,timers[section]);
  //showPanel(e.id);
  Element.show((section+"_"+v));
  
  return false;
}
function removeClassFromElements(c,start){
 document.getElementsByClassName(c,start).each(function(e){e.className=e.className.replace(c,"");}) 
}

chartData=[1,8,1];