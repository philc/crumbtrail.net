<script type="text/javascript">
function tracker(){

p=1050;var req = "http://stats.crumbtrail.net/stats.js";
e=document.createElement("script");

r=""+document.referrer;r=(r.length<=0)?"":'r='+escape(r)+'&';
e.setAttribute("src", req + '?'+r+'p='+p+'&u='+(document.cookie.indexOf(p)>=0?0:1)+'&c=' +
 (new Date()).getTime()%9000);
document.getElementsByTagName("head").item(0).appendChild(e);

// Create the cookie after the first request, so the first hit is logged as new

// 1 hour later.
d=new Date(); d.setTime(d.getTime()+3600000);

document.cookie='1050=1; path=/; expires=' + d.toGMTString() + ';'
}
if (typeof window.onload!='function'){window.onload=tracker;}
else{ f1=window.onload; window.onload=function(){f1();tracker();}}
</script>
