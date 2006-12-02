
function populate(){
  populate_table("hits_today", today_inner, 12);
  populate_table("hits_week", week_inner, 7);
  populate_table("hits_month", month_inner, 30);
}
function today_inner(i){
  return "<tr><td class='f'>" + (i+1) + ":00 AM</td><td>" + i*120 + "</td><td>" + i*60 + "</td></tr>";
}
function week_inner(i){
  return "<tr><td class='f'>" + (i+1) + "</td><td>" + i*400 + "</td><td>" + i*190 + "</td></tr>";
}
function month_inner(i){
  return "<tr><td class='f'>" + (i+1) + "th</td><td>" + i*1120 + "</td><td>" + i*260 + "</td></tr>";
}
function populate_table(id, f, n){
  html="<table><tr><td>hour</td><td>total</td><td>unique</td></tr>";
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

function show_graph(id, data){
  p=$(id);
  g=document.createElement("div");
  g.className="graph";
  size=120;
  imgs=[]
  hwidth=size/(data.length-1);
 
  // relativize
  max=0;
  data.each(function(e){ if (e>max) max=e; });  
  for (i=0;i<data.length;i++){ data[i]=Math.floor((data[i]/max)*size); }
  //numbers.each(function(e){ if (e>max) max=e; });
  //console.log(numbers);
  for (i=1;i<data.length; i++){
    div=document.createElement("div");
    div.className="color";
    div.id=i+"";
    img=document.createElement("img");    
    
    // Height of the point before this one
    prevHeight=data[i-1] ? data[i-1] : 0;
    
    // Whether the line is pointing up. Up=1, down=-1
    u=prevHeight<data[i] ? 1 : -1;
    img.src= (u==1 ? "/images/line.gif" : "/images/lined.gif");    
    //console.log(prevHeight);
    img.className="line";
    
    img.style.width=hwidth+"px";
    div.style.width=hwidth+"px";
    
    // difference in our heights
    h=data[i]-prevHeight;
    console.log(h);
    
    // amount of space there is above the previous element
    t=size-prevHeight;
    console.log(t);
    
    img.style.height=h*u + "px";
    
    ourTop = t-(u>0  ? h : 0)
    
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