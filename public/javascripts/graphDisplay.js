/*
 * Code for displaying rank graphs using plotr
 *
 * License:
 * Basically, if you use this code, you agree to leave all your inheritance to Mike Quinn.
 */

var LineGraphDisplay=new Class({
	initialize: function(canvas_id, data, labels){
		
		// We need to reverse the data and then
		// create an array of two value arrays eg: [[0, 24],[1,33],[2,29]....]
		data.reverse();
		this.data = new Array();
		for(var i=0; i<7; i++)
		{
			this.data[i] = [i,data[i]];
		}
		
		this.max = data.max();
		this.min = data.min();
		
		this.canvas_id = canvas_id;
		this.labels = labels;
	},
	
	showLineGraph: function(){
		var dataset = { 'dataset1': this.data };
		
		var options = {
			padding: {left: 5, right: 5, top: 0, bottom: 0},
			backgroundColor: '#ffffff',
			colorScheme: Page.colors[0],
			axisLabelFontSize: 12,
			shadow: false
		};
		
		if(this.labels == "week")
		{
			var xTicks = [];
			for(var i=0; i<7; i++)
			{
				var day = DisplayHelper.showDay((new Date()).getDay()+i+1);
				xTicks[i] = {v:i, label:day.slice(0,2)}
			}
			
			options['xTicks'] = xTicks;
			
			var yTicks = [];
			if(this.min > 0)
				yTicks.push({v:this.min});
			if(this.max > 0)
				yTicks.push({v:this.max});

			options['yTicks'] = yTicks;
		}
		
		var line = new Plotr.LineChart(this.canvas_id, options);
		line.addDataset(dataset);
		line.render();
	}
});

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
			// shouldStroke:true
			strokeWidth:.5,
			strokeColor: "#999"
			// shadow:false
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

var RankHistoryGraph=new Class({
  initialize: function(data, oldest_date, canvas_id, legend_id, ranktable_id, title_id){
    this.data = data;
    this.oldest_date = oldest_date;
    this.canvas_id = canvas_id;
    this.legend = $(legend_id);
    this.title = $(title_id);
    this.buildLegend();
    this.attachGraphFunctions(ranktable_id);
  },

  //-------------------------------------------------------------------

  updateQuery: function(ev){
    var tag = ev.target;

    this.showQueryGraph(tag.getText());
    ev.stop();
  },

  //-------------------------------------------------------------------

  attachGraphFunctions: function(ranktable_id){
    var rankTable = $(ranktable_id);
    var queryCells = $ES('td.query', rankTable);

    queryCells.each(function(cell) {
      var a = new Element('a', {'href': '#'});
      a.addEvent('click', this.updateQuery.bindWithEvent(this));
      a.appendText(cell.getText());
      cell.setHTML("");
      cell.adopt(a);
    }.bind(this));
  },

  //-------------------------------------------------------------------

  filterEngines: function(ev){
    var tag = ev.target;

    if (tag.hasClass('showsearch'))
      tag.removeClass('showsearch');
    else
      tag.addClass('showsearch');

    this.showQueryGraph(this.query);

    ev.stop();
  },

  //-------------------------------------------------------------------

  buildLegend: function(){
    var legend = $(this.legend_id);

    var contents="";
    contents+=db.ul(
      db.li(db.a({class: "search-filter showsearch google-legend", href: "#"}, "google")),
      db.li(db.a({class: "search-filter showsearch msn-legend", href: "#"}, "msn")),
      db.li(db.a({class: "search-filter showsearch yahoo-legend", href: "#"}, "yahoo"))
    );
    $(this.legend).setHTML(contents);

    $$('.search-filter',legend).each(function(tag){
      tag.addEvent('click', this.filterEngines.bindWithEvent(this));
    }.bind(this));
  },

  //-------------------------------------------------------------------

  showQueryGraph: function(query){
    this.query = query;
    this.title.setText(query);

    var engines = []
    $$('.search-filter', this.legend).each(function(el){
      if (el.hasClass('showsearch'))
        engines.push(el.getText());
    });
    
    var colorPool = {'google': '#1c4a7e',
                     'msn':    '#bb5b3d',
                     'yahoo':  '#3a8133'};

    var colors = new Array();
    var dataset = {};
    for (var i=0; i<engines.length; i++)
    {
      var engine = engines[i];
      colors[engine] = colorPool[engine];
      dataset[engine] = this.createDataCopy(this.data[query][engine]);
    }

    var offset = this.normalizeDataset(dataset);

    var options = {
      padding: {left: 30, right: 0, top: 10, bottom: 30},
      yTicks: this.buildYTicks(engines, dataset),
      xTicks: this.buildXTicks(engines, dataset, offset),
      backgroundColor: '#f2f2f2',
      colorScheme: colors,
      reverseYAxis: true,
      shouldFill: false
    };

    var line = new Plotr.LineChart(this.canvas_id, options);
    line.addDataset(dataset);
    line.render();
  },

  //-------------------------------------------------------------------

  buildYTicks: function(engines, dataset){
    // Find lowest and highest values
    var low = -1;
    var high = -1;
    for (var i=0; i<engines.length; i++)
    {
      var engine = engines[i];
      var data = dataset[engine];
      data.forEach(function(d){
        if (low == -1 || d[1] < low) low = d[1];
        if (high == -1 || d[1] > high) high = d[1];
      });
    }

    var scale = 100;
    if (high <= 15) scale = 1;
    else if (high <= 20) scale = 2;
    else if (high <= 100) scale = 5;
    else if (high <= 500) scale = 10;

    var yTicks = [];
    yTicks.push({v:1});
    for (var i=scale; i<high; i+=scale)
    {
      yTicks.push({v:i});
    }
    return yTicks;
  },

  //-------------------------------------------------------------------

  buildXTicks: function(engines, dataset, offset){
    var milisInDay = 1000 * 60 * 60 * 24;

    var today = new Date();
    var xTicks = [];
    var milis = today.getTime() - (this.oldest_date * milisInDay);
    var firstDate = new Date(milis + (offset * milisInDay));
    var i = 0;

    // Now move through the dates, and add significant ones as
    // xTicks
    for (now = firstDate; now < today; now.setTime(now.getTime()+milisInDay), i++)
    {
      if (now.getDate() == 1)
      {
        xTicks.push({v:i, label:this.getMonthString(now.getMonth())});
      }
    }

    return xTicks;
  },

  //-------------------------------------------------------------------

  normalizeDataset: function(dataset){

    // Find the earliest date we have in the data set
    var offset = -1;
    for (var i in dataset) {
      if (dataset[i][0][0] < offset || offset < 0)
        offset = dataset[i][0][0];
    }

    for (var i in dataset) {
      for (var d=0; d<dataset[i].length; d++)
        dataset[i][d][0] = dataset[i][d][0] - offset;
    }

/*
    for (var i=0; i<engines.length; i++)
    {
      var engine = engines[i];
      var engineData = this.data[query][engine];
      if (engineData[0][0] < earliest || earliest < 0)
        earliest = engineData[0][0];
    }
*/
    return offset;

  },

  //-------------------------------------------------------------------

  createDataCopy: function(engineData){
    var newArray = [];
    for (var i=0; i<engineData.length; i++)
      newArray.push(engineData[i].slice());
    
    return newArray;
  },

  //-------------------------------------------------------------------

  getMonthString: function(month){
		return DisplayHelper.months[month].substring(0,3);
  }
});
   
