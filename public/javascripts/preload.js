

// Preload some images so we don't have a noticable flicker when pages are loaded

var images=new Array(
  "c/circle.png",
  "c/dot.gif",
  "c/dotm.gif",
  "c/table-graph.png",
  "c/table-graph-fade.png"
  );

tmp=new Array(images.length);

for (var i=0;i<images.length;i++){
  tmp[i]=new Image(50,50);
  tmp[i].src="/images/"+images[i];
  //console.log("/images/"+images[i]);
}

var chartImages=new Array(7*4);
// Preload the chart images
for (var i=0;i<7;i++){
  for (var j=0;j<4;j++){
    chartImages[4*i+j]=new Image(50,50);
    chartImages[4*i+j].src="/images/c/line" + i + j + ".png";
//     console.log("/images/c/line" + i + j + ".png");
  }
}