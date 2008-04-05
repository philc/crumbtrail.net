/*
 * Pie Graph drawing
 */

var PieGraph=new Class({
	initialize: function(data, labels, title, canvas_id, chart_id){
		this.data = data;
		this.canvas_id = canvas_id;
		this.chart = $(chart_id);
		this.title = title;
		this.labels = labels;
		this.percents=[];
	},

	//-------------------------------------------------------------------

	showPieGraph: function(){
		var dataset = { 'os': this.data };

		colorHash = {};
		for (var i=0; i<this.data.length; i++){
			colorHash[i] = Page.colors[i];
		}
		this.colorScheme = new Hash(colorHash);

		var options = {
			padding: {left: 0, right: 0, top: 0, bottom: 0},
			backgroundColor: '#ffffff',
			colorScheme: this.colorScheme,
			pieRadius: '0.45',
			xTicks: [ ],
			divPosition: 'absolute',
			strokeWidth:.5,
			strokeColor: "#999"
		};

    var pie = new Plotr.PieChart(this.canvas_id, options);
    pie.addDataset(dataset);
    pie.render();

    this.calculatePercents();
    this.drawTextLabels();
  },

  //-------------------------------------------------------------------
  
  calculatePercents: function(){
    var total = 0;

    for (var i=0; i<this.data.length; i++)
      total += this.data[i][1];

    for (var i=0; i<this.data.length; i++)
      this.percents[i] = this.data[i][1]/total*100;
  },

  //-------------------------------------------------------------------

  drawTextLabels: function(){
    var labelBox=$(document.createElement("div"));
		labelBox.addClass("label-box");
		labelBox.style.left=px(160);
		labelBox.innerHTML=db.span({cls:'title'},this.title);

		var ul = document.createElement("ul");
		for (var i=0; i<this.labels.length;i++){
			var div=$(document.createElement("li"));   
			var boxColor = Page.colors[i];
			
			// Draw a 1px border around the color box, using a darker version of the box's color
			var darkerColor = (new Color(	boxColor)).setBrightness(65);
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
		this.chart.appendChild(labelBox);
  }
});


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
		// Don't use the entire min value. We don't want the lowest point to be "0"
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
