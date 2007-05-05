
/*
* Generic display methods
*/
DisplayHelper = new Class();
DisplayHelper.Methods={
	// Truncatation value for big and small text
	truncateBig:40,
	truncateSmall:45,
	/* 
	 * This is pretty amazing. All browsers except IE can parse
	 * ruby's Time.to_s. IE accepts a different version, which works on Mozilla
	* but not on safari. So parse the string; if the date is NaN, then mod the string a bit and try again.
	*/
	jsDate:function(dateString){
		var d = new Date(dateString);
		// Most browsers show "Invalid Date" for bad dates; IE shows "NaN"
		if (d.toString()=="NaN")
			{
				var tokens = dateString.split(' ');
				var n = tokens.slice(0,4);
				n.push(tokens[6]);
				n.push(tokens[5]);
				
				// Switch the last two tokens in the date string
				d = new Date(n.join(' '));
			}
		return d;
	},
	/*
	 * Formats a floating point percentage into a string representation
	 */
	formatPercent:function(percent){
		// Show a decimal place only if it's < 1%
		if (percent==0)
			return percent+"%";
		return percent.toFixed( percent < 1 ? 1 : 0) + "%";				
	},
	timeAgo: function(date){
		var diff=(new Date())-date;
		var mins=Math.floor(diff/1000/60);
		var hrs=Math.floor(mins/60);
		var days=Math.floor(hrs/24);
		var weeks=Math.floor(days/7);
		var mos=Math.floor(days/30);

		if (mins<1) return "just&nbsp;now";
		else if (hrs <1) return this.formatTimeAgo(mins,"min");
		else if (days < 1)	return this.formatTimeAgo(hrs,"hr");
		else if (weeks < 1)	return this.formatTimeAgo(days,"day");
		else if (mos<1)	return this.formatTimeAgo(weeks,"week");
		else return this.formatTimeAgo(mos,"month");
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
};

Object.extend(DisplayHelper,DisplayHelper.Methods);
// shortcuts
dh=DisplayHelper;





