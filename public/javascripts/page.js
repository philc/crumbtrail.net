/*
 * View preferences, for which panel is active, and which section is active within that panel
 */
var Preferences = new Class({
	initialize:function(){    
		this.sections=["pageviews","referers","pages","searches", "section"];
		this.defaults=["today","recent","recent","recent","glance"];
	},
	defaultCookie:function(){
		var defaults = this.sections.map(function(e){return e + "=" + this.defaults[i];}.bind(this));		
		return defaults.join('&');
	},
	parseCookie:function(){
		var cookie = Cookie.get("breadcrumbs") || this.defaultCookie();
	
		// Make into an associative array
		return ("?"+cookie.replace(/,/g,'&')).toQueryParams();    
	},
	update: function(n,v){
		var cookie=this.parseCookie();
		cookie[n]=v;
		// Rails can't parse the ampersands in the cookie... strange...
		Cookie.set('breadcrumbs', Object.toQueryString(cookie).replace(/&/g,','), {duration:90,path:"/"});
	}
});

/*
 * Manages and executes keyboard shortcuts
 */
var KeyboardShortcuts={
	keypress:function(ev){
		// TODO: rewrite this using mootools's event obj
		// target in moz, "srcElement" in ie
		var sender = $pick(ev.target,ev.srcElement);
		
		// Don't listen to keystrokes for form fields
		if (sender.tagName && (sender.tagName=="INPUT" || sender.tagName=="TEXTAREA"))
			return;
		
		// Don't process anything with modifiers
		if (ev.ctrlKey || ev.shiftKey || ev.altKey || ev.metaKey)
			return;
			
		var section=null,panel=null;
		
		// Mozilla has something like charCode=105, keyCode=0 on the event, 
		// while IE doesn't have a charCode property at all, but would have keyCode=105.
		var c=$pick(ev.charCode,ev.keyCode);
		
		// Opera uses the "a" key to highlight the next link in the page, so in opera
		// random text starts getting selected. no big deal, and can workaround by using the
		// other hotkeys		
		var key = String.fromCharCode(c).toLowerCase();
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
		// Cancel event propagation for both MS and w3c. Not sure if this is needed, but can't hurt...
		if (ev.stopPropagation)
			ev.stopPropagation();
		ev.cancelBubble=true;

	},
	previousSection:function(){
		var section = Page.activeSection;
		var li = Page.getMenuLink(section).getParent();
		// Grab the sibling list node's <a> element
		return li.getPrevious() ? li.getPrevious().getFirst().title : null;
	},
	nextSection:function(){
		var section = Page.activeSection;
		var li = Page.getMenuLink(section).getParent();
		// Grab the sibling list node's <a> element
		return li.getNext() ? li.getNext().getFirst().title : null;
	},
	/* 
	* Finds the next link on the current panel
	* 	which: "next" or "previous" 
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
	 * which:  "next" or "previous"
	*/
	getBrother:function(node,what){
		var el = node[what+'Sibling'];
		while ($type(el) == 'whitespace' || $type(el)=='textnode') el = el[what+'Sibling'];
		if ($type($(el))=="element")
			return $(el);
	}
};


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
		$ES(".panel_link","content").each(function(e){
			e.onclick=function(){ Page.panelNav(this); return false;};
		});


		$(document).addEvent('keypress',KeyboardShortcuts.keypress.bindAsEventListener(KeyboardShortcuts));

		// set collapse links
		$$("#currently_condensing a").each(function(e){
			e.onclick=function(e){
				var input=$(this).getNext();
				input.value = (input.value=="on" ? "off" : "on");
				Page.syncRefererPreferenceLink(this);
				return false;
			};
		});
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
		$('source_stats').innerHTML="<table>"+contents+"</table>";


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
		var nonUniques = [];
		for (var i=0;i<data['pageviews_week'].length;i+=2) nonUniques[i/2]=data['pageviews_week'][i];

		lg=new LineGraph("pageviewsWeek-linegraph",nonUniques, 200, "week",1);
		lg.drawGraph();  

		// visitor details graphs
		pg = new PieGraphDisplay("browser_details","Web browsers", browserData,browserLabels);
		pg.drawChart();  
		pg = new PieGraphDisplay("os_details","Operating systems", osData,
		osLabels);
		pg.drawChart();  

    /*
    * Rankings
    */
    RankDataDisplay.showTable({data: data.rankings}, "rankings_table_div");
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
		return "/images/c/line" + i + "" + q + ".png";
	},
	// Ensures that the link's caption matches the input field value.
	// They can get out of sync if you do a soft reload
	syncRefererPreferenceLink: function(link){
		input=$(link).getNext();
		link.firstChild.nodeValue = input.value=="on" ? "Stop condensing" : "Undo";
	}
};

window.addEvent('domready',Page.setup.bind(Page));
