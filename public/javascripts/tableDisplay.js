/*
 * Code for the displaying tabular data
 * Some general gotchas:
 * - (IE) If you want to add trs to a table using inner HTML, do it all with innerHTML, e.g. myNode.innerHTML="<table><tr>...</tr></table>"
 *  
 */

RankDataDisplay=new Class({
  initialize: function(options){
    BC.apply(this, options)
  },
  createTable: function(){
    var thead   = db.thead(
      db.tr(
        {cls: "header"},
        db.th({scope:"col", id:"ranking_query"},  "Query"),
        this.createHeader("google", "Google"),
        this.createHeader("yahoo", "Yahoo"),
        this.createHeader("msn", "MSN")
      )
    );
    var rows='';
    for (var i=0; i<this.data.length; i++)
      rows += this.createRow(i);

    var tbody   = db.tbody(rows);
    return db.table({cls: "d", id: "rankings_table"}, thead, tbody);
  },
  createHeader: function(cls, engine){
    return db.th({scope:"col"},
      db.div(
        db.span({cls: "engine-icon " + cls}, engine)
      )
    );
  },
  createRow: function(row){
    var tds = db.td({cls: "query f"}, this.data[row][0]);
    for (var i=1; i<7; i+=2)
    {
      var rank      = this.data[row][i];
      var delta     = this.data[row][i+1];
      
      var newdiv;
      if (this.tabletype == "ranks")
      {
        newdiv = db.div(
          {cls: (this.getDataCellClass(delta) + " rank")},
          (rank == null ? "-" : rank)
        );
      }
      else
      {
        newdiv = db.div(
          {cls: (this.getDataCellClass(delta) + " delta")},
          db.span(),
          (delta == null ? "-" : delta)
        );
      }
      
      tds += db.td(newdiv);
    }

    return db.tr({cls: (row%2 == 0 ? 'a' : '')}, tds);
  },
  getDataCellClass: function(value){
    var classStr = '';
    if (value > 0)
      classStr = "up";
    else if (value < 0)
      classStr = "down";
    else if (value == null)
      classStr = "empty";

    return "data " + classStr;
  }
});
RankDataDisplay.Methods={
  switchVisible: function(view){
    var dataCells = $$("#rankings_table" + " .data");
    
    for (var i=0; i<dataCells.length; i++)
    {
      var cell = dataCells[i];
      if (cell.hasClass(view))
        cell.show();
      else
        cell.hide();        
    }
  },
  showTable: function(options, htmlID){
    var dataDisplay = new RankDataDisplay(options);
    var titleStr = (options["tabletype"] == "ranks" ? 
                    "Current Rank" : "Most Recent Change");

    $(htmlID).innerHTML = DisplayHelper.dialog(dataDisplay.createTable(), 
                                               {title: titleStr});
  },
  showQueryManager: function(htmlID){
    var dataDisplay = new RankDataDisplay();
    $(htmlID).innerHTML = dataDisplay.createQueryManager();
  }
};
Object.extend(RankDataDisplay, RankDataDisplay.Methods);

QueryManager=new Class({
  initialize: function(options){
  }
});
QueryManager.Methods={
  addQuery: function(){
    var pid = Page.project;
    var query = document.query_form.query.value;
    var a=new Ajax('/project/queries/add?project='+pid+'&query='+query,
    {
      method:'get',
      onComplete:function(r){this.handleResponse(r);}.bind(this)
    });
    a.request();
    return false;
  },
  handleResponse:function(response){
    var results = eval(response);
    if (results[0] == true)
    {
      data.rankings = results[2];
      RankDataDisplay.showTable({data: data.rankings, tabletype: "ranks"}, "rankings_ranks");
      RankDataDisplay.showTable({data: data.rankings, tabletype: "deltas"}, "rankings_deltas");
    }
  }
};
Object.extend(QueryManager, QueryManager.Methods);
/*
* Table display
*/
TableDisplay=new Class({
	initialize:function(options){
		BC.apply(this,options);

		this.data=$pick(options.data, data[options.htmlID]);

		// If no rowDisplay was supplied, assume it's named after htmlID. e.g. 'searches_recent'=>TableDisplay.searchesRecent
		this.rowDisplay=$pick(options.rowDisplay, TableDisplay[options.htmlID.toCamelCase()]);

		this.rows=this.data.length/this.step;
	},
	buildTable: function(){
		var dataMax=this.data.max();

		var rows='';
		for (i=0;i<this.rows;i++)
		rows+=this.rowDisplay(i,this.data,dataMax);

		return db.table(this.tableHeader(),rows) + db.div({cls:'table-footer-cap'});
	},
	tableHeader: function(){
		if (this.headers==null)  return "";

		var html='';
		for (i=0;i<this.headers.length;i++)
		html += (i==0 ? "<th class='f'>" : "<th>") + this.headers[i] + "</th>";

		return db.tr({cls:'header'}, html);
	},
	// Create a cell that has a graph in it
	graphCell: function(text, percent){	
		return db.td(
			{cls:'graph-cell'},
			db.div(
				db.div({style: 'width:'+percent+'%'})
			),
			db.span(text)
		);
	},

	columnPercent: function(data, max){
		if (max==0) return 0;
		// 80 means only allow graphs in the background to grow to 80% of the td width
		return Math.round(data/max*80);   
	},
	classString: function(i, func){
		var c=(i%2==0 ? "a" : "");  // alt row
		if (func!=null)
		c+=func(i);
		return c;
	},
	pageviewsRow: function(i,data,dataMax, dateString, trClassString)
	{
		// data points
		var p1=data[i*2], p2=data[i*2+1];

		var percent=this.columnPercent(p1,dataMax);
		var percent2=this.columnPercent(p2,dataMax);

		var classString = trClassString ? trClassString  : this.classString(i);

		return db.tr(
			{cls:classString},
			db.td({cls:'f'}, dateString),
			this.graphCell(DisplayHelper.comma(p1),percent),
			this.graphCell(DisplayHelper.comma(p2),percent2)
		);
	}
});



TableDisplay.Methods={
	refererRowWithDate: function(i,data,dataMax){
		f=TableDisplay.refererRow.bind(this);
		return f(i,data,dataMax,true);
	},
	// "isDate" displays the second column as "time ago"
	refererRow: function(i,data,dataMax,isDate){
		var url=unescape(data[i*3]);
		var landedOn=unescape(data[i*3+1]);
		var linkCaption = DisplayHelper.truncateRight(url,DisplayHelper.truncateBig);
		var landedOnCaption = DisplayHelper.truncateLeft(landedOn,DisplayHelper.truncateSmall);
		
		return TableDisplay.tableRow(
			linkCaption.link("http://"+url) + db.span({cls:'to'},'To&nbsp;'+landedOnCaption.link("http://"+landedOn)),
			isDate ? DisplayHelper.timeAgo(data[i*3+2]) : DisplayHelper.comma(data[i*3+2])
		);	
	},
	pagesRecent:function(i,data,dataMax){
		var url = unescape(data[i*3]);
		var referer = unescape(data[i*3+1]);
		var time = data[i*3+2];
		var refererCaption = DisplayHelper.truncateRight(referer,DisplayHelper.truncateSmall);
		var linkCaption = DisplayHelper.truncateLeft(url,DisplayHelper.truncateBig);

		return TableDisplay.tableRow(
			linkCaption.link("http://"+url) +  db.span({cls:'to'},'From&nbsp;'+(referer != "null" ? refererCaption.link("http://"+referer) : "Direct")),
			DisplayHelper.timeAgo(time)
		);
	},
	/* Shortcut to build a two-celled tr */
	tableRow:function(cell1,cell2){
		return	db.tr(
			{cls:this.classString(i)},
			db.td({cls:'f'}, cell1),
			db.td(cell2)		
		);
	},
	classString: function(i, func){
		var c=(i%2==0 ? "a" : "");  // alt row
		if (func!=null)
		c+=func(i);
		return c;
	},
	searchesRowWithDate:function(i,data,dataMax,isDate){
		f=TableDisplay.searchesRow.bind(this);
		return f(i,data,dataMax,true);
	},
	searchesRow:function(i,data,dataMax,isDate){
		var terms = DisplayHelper.truncateLeft(data[i*4],DisplayHelper.truncateBig);
		var url = unescape(data[i*4+1]);
		var to = unescape(data[i*4+2]);
		var toCaption = DisplayHelper.truncateRight(to,DisplayHelper.truncateSmall);
		var faviconClass=TableDisplay.searchProvider(url);
		return TableDisplay.tableRow(
			(db.span({cls:"search-icon "+faviconClass}) + terms).link("http://"+url) + db.span({cls:'to'},'To&nbsp;'+toCaption.link("http://"+to)),
			isDate ? DisplayHelper.timeAgo(data[i*4+3]) : DisplayHelper.comma(data[i*4+3])
		);
	},
	yahoo:/.*yahoo\..*/,
	google:/.*google\..*/,
	msn:/.*(live|msn)\..*/,
	// Determines whether a url comes from a known search provider
	// returns google, yahoo, msn, or null
	searchProvider:function(url){
		if (url.test(TableDisplay.google))
			return "google";
		else if (url.test(TableDisplay.yahoo))
			return "yahoo";
		else if (url.test(TableDisplay.msn))
			return "msn";
		return null;
	},
	pagesRow:function(i,data,dataMax, isDate){
		var url = unescape(data[i*2]);
		var linkCaption = DisplayHelper.truncateLeft(url,DisplayHelper.truncateBig);

		return TableDisplay.tableRow(
			linkCaption.link("http://"+url),
			isDate ? DisplayHelper.timeAgo(data[i*2+1]) : DisplayHelper.comma(data[i*2+1])
		);	

		var html = linkCaption.link("http://"+url);
		var cell1=this.td(html,"f");
		var cell2 = isDate ? DisplayHelper.timeAgo(data[i*2+1]) : DisplayHelper.comma(data[i*2+1]);
		cell2=this.td(cell2);
		return this.tr(cell1+cell2, this.classString(i));
	},
  engineRankingsRow:function(i,data,dataMax){
    var query = data[i*3];
    var rank  = data[i*3+1];
    var delta = data[i*3+2];

    return db.tr(
      {cls:this.classString(i)},
      db.td({cls:'f'},query),
      db.td(rank),
      db.td(delta)
    );
  },
	// Shows a table, but doesn't wrap it in a dialog
	showTableWithoutDialog:function(options){
		var display = new TableDisplay(options);
		return display.buildTable();		
	},
	showTable:function(options){
		var html = this.showTableWithoutDialog(options);
		$(options.htmlID).innerHTML=DisplayHelper.dialog(html,options);
	},  

	feedLink: function(feedTitle, feedUrl)
	{
		return db.a(
			{cls:'feed', href:'/feed/' + Page.project + feedUrl, title:feedTitle},
			db.img({src:'/images/feed.gif'})
		);
	},
	pageviewsYear:function(i,data,dataMax){
		var month = DisplayHelper.showMonthAndYear((new Date()).getMonth()-i);
		return this.pageviewsRow(i,data,dataMax,month);
	},
	pageviewsMonth:function(i,data,dataMax){
		var week=DisplayHelper.formatWeeksAgo(i);
		return this.pageviewsRow(i,data,dataMax,week);
	},
	pageviewsWeek: function(i,data, dataMax){
		var day=DisplayHelper.showDay((new Date()).getDay()-i);
		return this.pageviewsRow(i,data,dataMax,day);
	},
	pageviewsToday: function(i,data, dataMax){
		var classString=this.classString(i, 
			function(i){
				return (Page.date.getHours()-i < 0 ? " old" : "");
			}
		);
		var day=DisplayHelper.showHour(Page.date.getHours()-i);
		return this.pageviewsRow(i,data,dataMax,day,classString);
	}
};
Object.extend(TableDisplay,TableDisplay.Methods);

Pagination=new Class({
	initialize: function(name, totalPages){
		this.name=name;
		this.total=0;  
		this.current=0;
		this.request=null;
	},

	showTable: function(options){
		BC.apply(this,options);
		
		this.data=$pick(options.data,data[this.htmlID]);

		var page=this.data[0];
		this.current=page;
		var more=this.data[1];

		// Only the later part of the array is the actual display data		
		options.data=this.data[2];
		
		var display = new TableDisplay(options);
		$(this.htmlID).innerHTML=DisplayHelper.dialog(display.buildTable() + this.buildNavMenu(more),options);
	},
	// prev and next are whether these links should be enabled
	buildNavMenu:function(enableNext){
		// Want the complete thing to be "return page.refererPager.next();" etc.
		var onclick = "return Page." + this.name + "Pager.";
		var html = this.buildLink("&#171",this.current>0,"","button",onclick+"first();");
		html+= this.buildLink("&#139",this.current>0,"","button", onclick+"prev();");
		html+= this.buildLink("&#155;",enableNext,"","button", onclick+"next();");
		html+= this.buildLink("&#187",enableNext,"","button",onclick+"last();");
		html+='<div id="pagination_progress" style="display:none"></div>';

		var page = db.span({cls:'page'},"Page " + (this.current+1));

		return db.div(
			{cls:'pagination_links'},
			page,
			db.span({cls:'buttons'},html)
		);
	},
	first:function(){
		return this.makeRequest(0);
	},
	last:function(){
		//return this.makeRequest(this.current+1);
		return this.makeRequest(-1);
	},
	next:function(){
		return this.makeRequest(this.current+1);
	},
	prev:function(){
		return this.makeRequest(this.current-1);
	},
	makeRequest:function(p){
		var a=new Ajax('/project/pagedata/'+this.name + "?p="+p + "&project="+Page.project,
		{
			method:'get',
			onStart:function(){$("pagination_progress").show();},
			onComplete:function(r){$("pagination_progress").hide();this.handleResponse(r);}.bind(this)
		});
		a.request();
		return false;
	},
	handleResponse:function(response){
		var results = eval(response);
	
		this.showTable({
			data:results,
			htmlID:this.htmlID,
			step:this.step,
			rowDisplay:this.rowDisplay,
			headers:this.headers,
			title:this.title
		});
	},

	/* shows a link that can be enabled or disabled. Disabled links get rendered as a span */
	buildLink: function(caption, enabled,href,cls,onclickFunc){
		if (!enabled) return db.span({cls:cls},caption);
		return db.a({href:href,onclick:onclickFunc,cls:cls},caption);
	}
});
