
function px(v) {  return Math.ceil(v) + "px";}

var Preferences = new Class({
	initialize:function(){    
		this.sections=["pageviews","referers","pages","searches", "section"];
		this.defaults=["today","recent","recent","recent","glance"];
		this.re=/breadcrumbs=([^;]+)/
	},
	defaultCookie:function(){
		var defaults = this.sections.map(function(e){return e + "=" + this.defaults[i];}.bind(this));		
		return defaults.join('&');
	},
	parseCookie:function(){
		var m = this.re.exec(document.cookie);

		if (m && m.length>0)
		cookie=m[1]
		else
		cookie=this.defaultCookie();
		// Make into an associative array
		return ("?"+cookie.replace(/,/g,'&')).toQueryParams();    
	},
	update: function(n,v){
		cookie=this.parseCookie();
		cookie[n]=v;
		// Rails can't parse the ampersands in the cookie... strange...
		this.setCookie("breadcrumbs",Object.toQueryString(cookie).replace(/&/g,','));    
	},
	setCookie: function(name,value){
		// 1 hour * 24 * days
		d=new Date(); d.setTime(d.getTime()+3600000*24*28);
		document.cookie=name+"="+value+'; expires=' + d.toGMTString() + ';'
	}
});

/*
 * Manages and executes keyboard shortcuts
 */
var KeyboardShortcuts={
	keypress:function(ev){
		// Don't listen to keystrokes for form fields
		if (ev.target.tagName && (ev.target.tagName=="INPUT" || ev.target.tagName=="TEXTAREA"))
			return;
			
		// Don't process anything with modifiers
		if (ev.ctrlKEY || ev.shiftKey || ev.altKey || ev.metaKey)
			return;
			
		var section=null,panel=null;
		
		var key = String.fromCharCode(ev.charCode).toLowerCase();
		switch(key){
			case "s":
			case "j":
				section = this.nextSection();
			break;
			case "w":
			case "k":
				section=this.previousSection();
			break;
			case "a":
			case "u":
				panel=this.getPanelLink('previous');
			break;
			case "d":
			case "i":
				panel=this.getPanelLink('next');
			break;
		}
		if (section)
			Page.menuNav(section);
		if (panel && panel.tagName=="A")		
			Page.panelNav(panel);
	},
	previousSection:function(){
		var section = Page.activeSection;
		var li = Page.getMenuLink(section).parentNode;
		// Grab the sibling list node's <a> element
		return li.getPrevious() ? li.getPrevious().getFirst().title : null;
	},
	nextSection:function(){
		var section = Page.activeSection;
		var li = Page.getMenuLink(section).parentNode;
		// Grab the sibling list node's <a> element
		return li.getNext() ? li.getNext().getFirst().title : null;
	},
	/* 
	Finds the next link on the current panel
	 	which parameter can be "next" or "previous" 
	*/
	getPanelLink:function(which){
		var section = $(Page.activeSection);
		var links = section.childrenOfClass('panel_links')[0];		
		if (!links)
			return;

		var active = links.childrenOfClass('panel_link_active')[0];
		return this.getBrother(active,which);
	},
	/* 
	 * Mootool's element.getNext() returns false when it hits a text node. This keeps on going. 
	 * 'what' can be next or previous.
	*/
	getBrother:function(node,what){
		var el = node[what+'Sibling'];
		while ($type(el) == 'whitespace' || $type(el)=='textnode') el = el[what+'Sibling'];
		if ($type($(el))=="element")
			return $(el);
	}
}


var Page = {
	setup:function(){
		this.colors=["#a4d898","#fdde88","#ff9e61","#d75b5c","#7285b7","#98d5d8","#989cd8","#d8bb98"];    

		this.preferences=new Preferences();        

		// Build the paginator objects
		this.totalReferersPager=new Pagination("totalReferers",20);

		this.populate();

		// set menu links
		$A($('menu-links').getElementsByTagName("LI")).each(function(e){
			l=e.getElementsByTagName("A")[0];
			l.onclick=function(){ Page.menuNav(this); return false;};
		});
		// set panel links
		$A(document.getElementsByClassName("panel_link","content")).each(function (e){
			e.onclick=function(){ Page.panelNav(this); return false;};
		});
		
		$(document).addEvent('keypress',KeyboardShortcuts.keypress.bindAsEventListener(KeyboardShortcuts));
		
		// referer options
			// set collapse links
			$$("#currently_condensing a").each(function(e){
				e.onclick=function(e){
						var input=$(this).getNext();
						input.value = (input.value=="on" ? "off" : "on");
						console.log(this);
						Page.syncRefererPreferenceLink(this);
						return false;
				}
			});
			
			/*.addEvent('click',function(e){
				input=this.getNext();
				input.value = input.value=="on" ? "off" : "on";
				Page.syncRefererPreferenceLink(this);
				return false;
			});*/
		/*	Event.addBehavior({
				'#currently_condensing a:click' : function(e){ 
					input=this.nextElement();
					input.value = input.value=="on" ? "off" : "on";
					page.syncRefererPreferenceLink(this);
					return false;
					}			
			})
			
			-	// Sync all the referer links to their hidden form elements
			-	$$("#currently_condensing a").each(function (e){page.syncRefererPreferenceLink(e);});
			
			*/
	},
	populate:function(){
		/*
		* At a glance
		*/
		var panel1 = TableDisplay.showTableWithoutDialog({
			htmlID:'glance_referers_today',
			title:'',
			step:3,
			rowDisplay:TableDisplay.refererRow,
			headers:["","Pageviews"]
		});
		var panel2 = TableDisplay.showTableWithoutDialog({
			htmlID:'glance_referers_week',
			title:'',
			step:3,
			rowDisplay:TableDisplay.refererRow,
			headers:["","Pageviews"]
		});

		$('glance_referers_today').innerHTML=DisplayHelper.dialog(
			panel1+'<br/>'+'<h2 class="title">Top referers this week</h2>'+panel2,
			{title:'Top referers today'}
		);
		
		var contents="";
		var alt=0;
		for (var key in data.glance_sources){
			contents+=db.tr(
				db.td({cls:"f"},key.firstUpCase()),
				db.td({cls:'s ' + (alt++%2 ? '':'a')},DisplayHelper.formatPercent(data.glance_sources[key]))
			);		
		}
		$('source_stats').innerHTML="<tbody>"+contents+"</tbody>";


		/*
		* Pageviews
		*/
		TableDisplay.showTable({
			htmlID:'pageviews_today',
			step:2,
			headers:["","Pageviews","Unique"],
			feedTitle:"Hourly pageviews RSS feed",
			feedUrl:"/pageviews"
		});

		TableDisplay.showTable({
			htmlID:'pageviews_week',
			title:'Pageviews this week',
			step:2,
			headers:["","Pageviews","Unique"]
		});

		TableDisplay.showTable({
			htmlID:'pageviews_month',
			title:'Pageviews this month',
			step:2,
			headers:["","Pageviews","Unique"]
		});

		TableDisplay.showTable({
			htmlID:'pageviews_year',
			title:'Pageviews this year',
			step:2,
			headers:["","Pageviews","Unique"]
		});

		/*
		* Referers
		*/
		Page.totalReferersPager.showTable({
			htmlID:'referers_total',
			title:'Popular referers',
			step:3,
			rowDisplay:TableDisplay.refererRow,
			headers:["","Total pageviews"]
		});

		TableDisplay.showTable({
			htmlID:'referers_unique',
			title:'Unique referrals',
			step:3,
			headers:["","First visited"],
			feedTitle:"Unique referrals RSS feed",
			rowDisplay:TableDisplay.refererRowWithDate,
			feedUrl:"/referers/unique"
		});

		TableDisplay.showTable({
			htmlID:'referers_recent',
			title:'Recent referrals',
			step:3,
			headers:["","Visited"],
			feedTitle:"Recent referrals RSS feed",
			rowDisplay:TableDisplay.refererRowWithDate,
			feedUrl:"/referers/recent"
		});

		/*
		* Pages
		*/
		TableDisplay.showTable({
			htmlID:'pages_recent',
			title:'Recent pages',
			step:3,
			headers:["","Accessed"]
		});
		TableDisplay.showTable({
			htmlID:'pages_popular',
			title:'Popular pages',
			step:2,
			rowDisplay:TableDisplay.pagesRow,
			headers:["","Pageviews"]
		});

		/*
		* Search
		*/
		TableDisplay.showTable({
			htmlID:'searches_recent',
			title:'Recent searches',
			step:4,
			rowDisplay:TableDisplay.searchesRowWithDate,
			headers:["Keywords","Visited"]
		});
		TableDisplay.showTable({
			htmlID:'searches_totals',
			title:'Popular searches',
			step:4,
			rowDisplay:TableDisplay.searchesRow,
			headers:["Keywords","Visited"]
		});
		/*
		* Details
		*/
		// don't graph uniques on the line graph
		var onlyHits = [];
		for (var i=0;i<data['pageviews_week'].length;i+=2) onlyHits[i/2]=data['pageviews_week'][i];
		lg=new LineGraph("pageviewsWeek-linegraph",onlyHits, 200, "week",1);
		lg.drawGraph();  

		// visitor details graphs
		pg = new PieGraphDisplay("browser_details","Web browsers", browserData,browserLabels);
		pg.drawChart();  
		pg = new PieGraphDisplay("os_details","Operating systems", osData,
		osLabels);
		pg.drawChart();  

	},

	// Gets the menu link for the given section, e.g. the <a> link for section "pageviews"
	getMenuLink:function(section){
		return $E('#menu a[title=' + section + ']');
	},
	// Switch section
	menuNav: function(arg){
		var section=$pick(arg.title,arg);
		
		$$('#menu .active').forEach(function(e){e.removeClass('active');});		
		
		var element = this.getMenuLink(section);
		element.addClass("active");

		if (this.activeSection)
		$(this.activeSection).hide();
		this.activeSection=section;

		$(section).show();		
		this.preferences.update("section",section);
	},
	// Navigate within a section
	panelNav: function(linkElement){
		// Not using the mootools CSS selector $$ here because it's slow as crap
		var panel=linkElement.title;	
		var section = $(this.activeSection);
		section.childrenOfClass('panel').forEach( function(e){e.hide();} );

		// Remove highlighting on the other link, highlight the new link    
		section.childrenOfClass('panel_links')[0].childrenOfClass('panel_link_active').forEach(
			function(e){e.removeClass('panel_link_active');}
		);
		$(linkElement).addClass("panel_link_active");
		// Show e.g. "referers_current" panel
		$(this.activeSection+"_"+panel).show();
		this.preferences.update(this.activeSection,panel);
	},
	// Returns the image file used for a quadrant. i is the color (0-5ish)
	imageForQuadrant: function (i,q){
		return "/images/c/line" + i + "" + q + ".png"
	},
	// Ensures that the link's caption matches the input field value.
	// They can get out of sync if you do a soft reload
	syncRefererPreferenceLink: function(link){
		input=$(link).getNext();
		link.firstChild.nodeValue = input.value=="on" ? "Stop condensing" : "Undo";
	}
};

/*
* Table display
*/
TableDisplay=new Class({
	initialize:function(options){
		BC.apply(this,options);

		this.data=$pick(options.data, data[options.htmlID]);

		// If no rowDisplay was supplied, assume it's named after htmlID. e.g. 'searches_recent'=>TableDisplay.searchesRecent
		this.rowDisplay=$pick(options.rowDisplay, TableDisplay[options.htmlID.toCamelCase()]);
		/*this.title=title;    
		this.headerNames=headerNames;
		this.data=data;
		this.step=step;
		this.cellFunc=cellFunc;*/
		//this.minRows=minRows ? minRows : data.length/step;
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
		if (this.headers==null)  return "" 

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
		var p1=data[i*2], p2=data[i*2+1]

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

		return TableDisplay.tableRow(
			terms.link("http://"+url) + db.span({cls:'to'},'To&nbsp;'+toCaption.link("http://"+to)),
			isDate ? DisplayHelper.timeAgo(data[i*4+3]) : DisplayHelper.comma(data[i*4+3])
		);

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
		var classString=this.classString(i, function(i){return (Page.date.getHours()-i < 0 ? " old" : "")});
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

/*
* Generic display methods
*/
DisplayHelper = new Class();
DisplayHelper.Methods={
	// Truncatation value for big and small text
	truncateBig:40,
	truncateSmall:45,

	/*
	 * Formats a floating point percentage into a string representation
	 */
	formatPercent:function(percent){
		// Show a decimal place only if it's < 1%
		return percent.toFixed( percent < 1 ? 1 : 0) + "%";				
	},
	timeAgo: function(date){
		var diff=(new Date())-date;
		var mins=Math.floor(diff/1000/60);
		var hrs=Math.floor(mins/60);
		var days=Math.floor(hrs/24);
		var weeks=Math.floor(days/7);
		var mos=Math.floor(days/30);
		if (mins<1) 		return "just&nbsp;now";
		else if (hrs <1)		return this.formatTimeAgo(mins,"min");
		else if (days < 1)		return this.formatTimeAgo(hrs,"hr");
		else if (weeks < 1)		return this.formatTimeAgo(days,"day");
		else if (mos<1)		return this.formatTimeAgo(weeks,"week");
		else		return this.formatTimeAgo(mos,"month");
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
	months:["January", "February","March","April","May","June",
	"July","August", "September","October","November","December"],
	showMonth:function(i){ 
		i=(i+12)%12;
		return this.months[i].substring(0,3);
	},
	showMonthAndYear:function(i){
		// date returns year since 1900
		var year = ''+(Page.date.getYear()-(i<0? 101 : 100));
		if (year.length==1)
		year='0'+year;
		return this.showMonth(i) + " '" + year;
	},
	// Will ellipsize from the left, e.g. philisoft.com/blog => ...isoft.com/blog.
	// Should we try and break on periods or slashes, if they're close?
	// Usually that's what we want
	truncateLeft: function(str,n){
		if (str.length<n) return str;
		var mod = str.slice(str.length-n,str.length);
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
	comma: function(number) {
		str = new String(number);
		var val = new String();
		var num = str.length % 3;
		if (num == 0) { num = 3; }
		while (str.length > 0) {
			val += str.substring (0, num) + ",";
			str = str.substring (num);
			num = 3;
		}
		return val.substring (0, val.length - 1);
	},
	dialog:function(contents, opt){
		var feed="";
		opt=opt || {};
		if (opt.feedTitle)
		feed=db.a(
			{
				cls:'feed',
				href:'/feed/' + Page.project +  opt.feedUrl + '?k=' + Page.key,
				title:opt.feedTitle
			},
			db.img({src:'/images/feed.gif'})
		);

		// If there's no title provided, change the htmlID into a title, e.g. pageviews_today => Pageviews today
		var title = $pick(opt.title, opt.htmlID ? opt.htmlID.toDisplayString() : "" );

		return '<b class="d"><b class="hd"><b class="c"></b></b><b class="bd">'+
		'<b class="c">' + feed + '<h2 class="title">' + title + '</h2>'+contents + '</b></b><b class="ft">' + 
		'<b class="c"></b></b></b>';
	}
}
Object.extend(DisplayHelper,DisplayHelper.Methods);


/*
* Line graph drawing
*/
LineGraph=new Class({
	initialize: function(id,data, width, labels, style){
		this.element=$(id);    
		this.width=width;
		this.height=parseInt(this.element.getStyle('height'));
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
		var imgs=[]
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

			var ourTop = t-(u>0  ? h : 0)

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
		return dot
	},
	lineGraphImage: function(i,u){
		var d = (u==1 ? 0 : 1);
		return "/images/c/linegraph" + i + "" + d + ".png"
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
				t=day=DisplayHelper.showDay((new Date()).getDay()+i+1)
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
}
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
		var placeholder=document.createElement("div")
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
		img.addClass("chart_image ");
		div.addClass("chart_image chart_image_div");
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
		div.addClass("chart_filler");
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
		labelBox.addClass("label_box");
		labelBox.style.left=px(this.size);
		labelBox.innerHTML=db.span({cls:'title'},this.title);

		var ul = document.createElement("ul");
		for (var i=0; i<this.labels.length;i++){
			var div=$(document.createElement("li"));   
			div.innerHTML= 
			db.div( {cls:'color_box', style:"background-color:" + Page.colors[i]}) + 
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

window.addEvent('domready',Page.setup.bind(Page));


