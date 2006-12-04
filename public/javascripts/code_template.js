<script type="text/javascript">
function tracker(){

//var req = "http://123.super.com/demo/test";
var req = "http://192.168.0.30/inkforword.png";
e=document.createElement("script");

r=""+document.referrer;r=(r.length<=0)?"":'r='+escape(r)+'&';
e.setAttribute("src", req + '?'+r+'p=1050&c=' + (new Date()).getTime()%9000);
document.getElementsByTagName("head").item(0).appendChild(e);

// Create the cookie after the first request, so the first hit is logged as new
host="192.168.0.30"
// 1 hour later.
d=new Date(); d.setTime(d.getTime()+3600000);
d.toGMTString();

document.cookie='1050=1; expires=' + d.toGMTString() + '; domain='+host;

}
if (typeof window.onload!='function'){window.onload=tracker;}
else{ f1=window.onload;	window.onload=function(){f1();tracker();}}
</script>
