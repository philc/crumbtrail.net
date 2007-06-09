
/*
* Line graph drawing
*/
LineGraph=new Class({
	initialize: function(id,data, width, labels, style){
		this.element=$(id);    

		this.width=width;
		// console.log(this.element.toString());
		// console.log(this.element.getStyle.toString());
		// Could use mootools' getStyle('height') to get the computer style,
		// but safari doesn't support it on elements with display:none
		this.height=this.element.style['height'].toInt();
		
		this.max = data.max();
		this.min = data.min();
		this.labels=labels;
		this.style=style;

		// If min is 10% of the max, don't bother making a caret in the graph
		if (this.min / this.max < .1)
		this.min=0;    

		var reversed = data.reverse();

		// non-relative data
		this.originalData = reversed;
		this.data=LineGraph.relativize(reversed,this.height,this.max,this.min);
		// Pick a line color. Colors are defined in page.colors
		this.lineColor=(style==0 ? 1 : 0);

	},

	drawGraph: function(){  
		// Graph container
		var g=$(document.createElement("div"));
		g.addClass("linegraph");
		var imgs=[];
		var hwidth=this.width/(this.data.length-1);

		// Add the first "dot" on the graph
		if (this.data.length>0)

		// Append the first data point to the diagram
		g.appendChild(this.dataPointDot(this.originalData[0],0,this.height-this.data[0],1));

		// Only draw lines starting with the second point (i=1); the first point is our starting point
		// (the intersection with the Y axis)

		for (i=1;i<this.data.length; i++){
			var div=$(document.createElement("div"));
			div.addClass("color");
			div.style.backgroundColor=Page.colors[this.lineColor];
			div.id=i+"";
			var img=document.createElement("img");    

			// Height of the point before this one
			var prevHeight=this.data[i-1] ? this.data[i-1] : 0;
			// Whether the line is pointing up. Up=1, down=-1
			var u=prevHeight<=this.data[i] ? 1 : -1;     

			img.src=this.lineGraphImage(this.style,u);
			img.className="line";

			img.style.width=px(hwidth);
			div.style.width=px(hwidth);

			// difference in our heights
			var h=this.data[i]-prevHeight;



			// amount of space there is above the previous element
			var t=this.height-prevHeight;

			img.style.height=px(h*u);

			var ourTop = t-(u>0  ? h : 0);

			div.style.height=this.height-(h*u)-ourTop+"px";

			div.style.top=ourTop+(h*u)+"px";
			img.style.top=ourTop+"px";
			div.style.left=(i-1)*hwidth+ "px";
			img.style.left=(i-1)*hwidth+ "px";

			// Add a dot for the datapoint to a curve.
			g.appendChild(this.dataPointDot(this.originalData[i],i*hwidth,this.height-this.data[i],u==1));

			g.appendChild(img);
			g.appendChild(div);
		}    
		this.showLabels(g);
		this.element.appendChild(g);
	},  
	// if the line is pointing up, we need to move the dot upward somewhat
	dataPointDot: function(data,x,y, pointingUp){
		var dot=$(document.createElement("div"));
		dot.addClass("linegraph-dot");
		if (pointingUp)
		dot.addClass("linegraph-dot-up");
		//dot.className="linegraph-dot" + (pointingUp ? "" : " linegraph-dot-up");
		dot.style.left=px(x);

		dot.onmouseover=function(){$(this.firstChild).show();};
		dot.onmouseout=function(){$(this.firstChild).hide();};
		//dot.style.top=u==1 ? img.style.top : px(ourTop+(h*u)-7);

		//dot.style.bottom=px(this.data[i]);
		dot.style.top=px(y);

		text = $(document.createElement("div"));
		text.addClass("linegraph-dot-caption");
		text.style.display="none";

		text.innerHTML=DisplayHelper.comma(data+"");    

		dot.appendChild(text);
		return dot;
	},
	lineGraphImage: function(i,u){
		var d = (u==1 ? 0 : 1);
		return "/images/c/linegraph" + i + "" + d + ".png";
	},
	showLabels: function(graphContainer){
		if (this.min>0){
			var minLabel = this.yLabel(DisplayHelper.comma(this.min));
			minLabel.style.bottom=px(14);
			graphContainer.appendChild(minLabel);
		}

		// No need to show "0" as the max if there is are pageviews...
		if (this.max>0){
			var maxLabel = this.yLabel(DisplayHelper.comma(this.max));
			maxLabel.style.top=0;    
			graphContainer.appendChild(maxLabel);
		}

		if (this.labels){
			var hwidth=this.width/(this.data.length-1);
			for (var i = this.data.length-1;i>=0;i--){
				var t="";
				if (this.labels=="week")
				//t=DisplayHelper.showDay(i-Page.date.getHours()-1,false);
				//t=DisplayHelper.showDay(i);
				t=day=DisplayHelper.showDay((new Date()).getDay()+i+1);
				var l=this.xLabel(t.slice(0,2));
				l.style.left=px(hwidth*i);
				graphContainer.appendChild(l);
			}
		}

		//graphContainer.appendChild(this.graphLabel("number",0,0));
	},
	xLabel: function(text){
		var div=$(document.createElement("div"));
		div.addClass("line-x-label");
		div.innerHTML=text;
		//     div.style.top="100%";
		//     div.style.bottom=y;   
		return div;
	},
	yLabel: function(text){
		var div=$(document.createElement("div"));
		div.addClass("line-y-label");
		div.innerHTML=text;
		//     div.style.right="100%";
		//     div.style.bottom=y;   
		return div;
	}
});

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
};
Object.extend(LineGraph,LineGraph.Methods);


/*
* Pie chart graphing
*/

PieGraphDisplay = new Class({
	initialize: function(id,title,data,labels){
		this.element=$(id);
		this.size=150;
		this.qsize=this.size/2;
		this.data=[];
		this.percents=[];
		this.title=title;
		this.labels=labels;

		// relativize data
		var total=data.sum();
		
		// Make the data in percents, for the labels
		for (var i=0;i<data.length;i++)
			this.percents[i]=data[i]/total*100;

		// Make the data as degrees of a 360 circle, for the graph drawing
		for (var i=0;i<data.length;i++)
		this.data[i]=Math.floor((data[i]/total)*360);

	},

	drawChart: function (){   
		var placeholder=document.createElement("div");
		placeholder.style.position="absolute";
		placeholder.style.width=px(this.size);
		placeholder.style.height=px(this.size);

		for (var i=0;i<this.data.length-1;i++){
			this.graphQuadrant(i,this.data,placeholder);
		}
		placeholder.style.backgroundColor=Page.colors[this.data.length-1];

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

		// Add a div here. IE uses the div, while everyone else uses the img.
		var div=$(document.createElement("div"));
		var img=$(document.createElement("img"));
		img.addClass("chart-image ");
		div.addClass("chart-image chart-image-div");
		img.style.width=div.style.width=px(w);
		img.style.height=div.style.height=px(h);

		o1=(q==1||q==2) ? 0 : 1;
		o2=(q==2||q==3) ? 0 : 1;

		img.style.left=div.style.left=this.qsize-o1*w+"px";

		img.style.top=div.style.top=this.qsize-o2*h + "px";  


		img.src=Page.imageForQuadrant(i,q);    
		// for IE
		div.style.filter = "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='"
		+ Page.imageForQuadrant(i,q) + "', sizingMethod='scale')";

		img.style.zIndex=div.style.zIndex=data.length*2-i*2+"";    

		this.drawFillerBoxes(placeholder,Page.colors[i],q,this.data.length*2-i*2-1,w,h);



		placeholder.appendChild(div);
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

		var div=$(document.createElement("div"));
		div.style.backgroundColor=color;
		div.addClass("chart-filler");
		div.style.zIndex=level+"";

		// div dimentions
		var dw=dh=dt=dl=0;
		var qs=this.qsize;

		dw = ((q==1 || q==3) ? w : qs-w );

		if (q==0){
			dl=0; 
			dh=qs;
		}
		if (q==1){
			dl=qs;
			dh=qs-h;
		}
		if (q==2){
			dl=qs+w;
			dt=qs;        
			// If it's a 0 height, we should fill up the whole box.
			dh= (h==0 ? qs: h);
		}
		if (q==3){
			dh=qs-h;
			dt=qs+h;
		}

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
		var labelBox=$(document.createElement("div"));
		labelBox.addClass("label-box");
		labelBox.style.left=px(this.size);
		labelBox.innerHTML=db.span({cls:'title'},this.title);

		var ul = document.createElement("ul");
		for (var i=0; i<this.labels.length;i++){
			var div=$(document.createElement("li"));   
			var boxColor = Page.colors[i];
			
			// Draw a 1px border around the color box, using a darker version of the box's color
			var darkerColor = (new Color(boxColor)).setBrightness(65);
			var styleString = "background-color:" + boxColor + "; border:1px solid rgb(" + darkerColor + ")";
			
			div.innerHTML= 
			db.div( {cls:'color-box', style:styleString}) + 
			db.span(
				{cls:'caption'},
				this.labels[i],
				db.span({cls:'percent'}, DisplayHelper.formatPercent(this.percents[i]))
			);

			div.addClass("label");
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
});