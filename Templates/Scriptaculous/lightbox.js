/*
  Lightbox w/ Prototype
  Based upon Lokesh Dhakar's Lightbox JS (See http://huddletogether.com/projects/lightbox/)

  This script is released by 23 (http://www.23hq.com) under  the Creative Commons Attribution 2.5 License - http://creativecommons.org/licenses/by/2.5/
  (Steffen Tiedemann Christensen, steffen@23hq.com, http://blog.23hq.com)
  
  Usage:
  lightbox('/myurl/demo.html');
  lightbox('/myurl/demo.html', {height:300, width:500});
  lightbox('/myurl/demo.html', {params:'test=yes', left:10, top:10, height:300, width:500, callingObj:this, position:'relative'});
*/

// Config
var loadingImgSrc = '/scriptaculous/images/loading.gif'



//
// getPageScroll()
// Returns array with x,y page scroll values.
// Core code from - quirksmode.org
//
function getPageScroll(){
    var yScroll;

    if (self.pageYOffset) {
    yScroll = self.pageYOffset;
    } else if (document.documentElement && document.documentElement.scrollTop){     // Explorer 6 Strict
    yScroll = document.documentElement.scrollTop;
    } else if (document.body) {// all other Explorers
    yScroll = document.body.scrollTop;
    }
    
    arrayPageScroll = new Array('',yScroll) 
    return arrayPageScroll;
}



//
// getPageSize()
// Returns array with page width, height and window width, height
// Core code from - quirksmode.org
// Edit for Firefox by pHaez
//
function getPageSize(){
    var xScroll, yScroll;
    
    if (window.innerHeight && window.scrollMaxY) {    
    xScroll = document.body.scrollWidth;
    yScroll = window.innerHeight + window.scrollMaxY;
    } else if (document.body.scrollHeight > document.body.offsetHeight){ // all but Explorer Mac
    xScroll = document.body.scrollWidth;
    yScroll = document.body.scrollHeight;
    } else { // Explorer Mac...would also work in Explorer 6 Strict, Mozilla and Safari
    xScroll = document.body.offsetWidth;
    yScroll = document.body.offsetHeight;
    }
    
    var windowWidth, windowHeight;
    if (self.innerHeight) {    // all except Explorer
    windowWidth = self.innerWidth;
    windowHeight = self.innerHeight;
    } else if (document.documentElement && document.documentElement.clientHeight) { // Explorer 6 Strict Mode
    windowWidth = document.documentElement.clientWidth;
    windowHeight = document.documentElement.clientHeight;
    } else if (document.body) { // other Explorers
    windowWidth = document.body.clientWidth;
    windowHeight = document.body.clientHeight;
    }    
    
    // for small pages with total height less then height of the viewport
    if (yScroll < windowHeight){
    pageHeight = windowHeight;
    } else { 
    pageHeight = yScroll;
    }
    
    // for small pages with total width less then width of the viewport
    if (xScroll < windowWidth) {    
    pageWidth = windowWidth;
    } else {
    pageWidth = xScroll;
    }
    
    
    arrayPageSize = new Array(pageWidth,pageHeight,windowWidth,windowHeight) ;
    return arrayPageSize;
}


//
// getAbsoluteObjectX(obj)
//
function getAbsoluteObjectX(obj) {
    var x = obj.offsetLeft;
    while (obj.offsetParent) {
        obj = obj.offsetParent;
    x += obj.offsetLeft;
    }
    return(x);
}

//
// getAbsoluteObjectY(obj)
//
function getAbsoluteObjectY(obj) {
    var y = obj.offsetTop;
    while (obj.offsetParent) {
        obj = obj.offsetParent;
    y += obj.offsetTop;
    }
    return(y);
}


//
// getKey(key)
// Gets keycode. If 'x' is pressed then it hides the lightbox.
//

function getKey(e){
    if (e == null) { // ie
    keycode = event.keyCode;
    } else { // mozilla
    keycode = e.which;
    }
    key = String.fromCharCode(keycode).toLowerCase();
    
    if (key == 'x') hideLightbox();
}


//
// listenKey()
//
function listenKey () {    document.onkeypress = getKey; }

function showLightbox() {
    ////log(lbX + ", " + lbY + ", " + lbW + ", " + lbH);

    // prep objects
    var objOverlay = document.getElementById('overlay');
    var objLightbox = document.getElementById('lightbox');
    var objLoadingImage = document.getElementById('loadingImage');

    objLightbox.style.overflow = lbOverflow;
    objLoadingImage.style.display = 'none';

    var arrayPageSize = getPageSize();
    var arrayPageScroll = getPageScroll();

    if (lbH!=undefined) objLightbox.style.height = lbH + "px";
    if (lbW!=undefined) objLightbox.style.width = lbW + "px";
    ////log("H: " + objLightbox.style.height + ", W: " + objLightbox.style.width);

    if (lbY==undefined) {lbY=20;}
    objLightbox.style.top = lbY + "px";

    objLightbox.style.visibility = 'hidden';
    objLightbox.style.display = 'block';

    if (lbX==undefined) {lbX = ((arrayPageSize[0] - objLightbox.offsetWidth) / 2);}
    ////log(arrayPageSize[0] + ", " + objLightbox.offsetWidth + ", " + lbX);

    objLightbox.style.left = lbX + "px";

    objLightbox.style.visibility = 'visible';

    ////log(lbX + ", " + lbY + ", " + lbW + ", " + lbH);


    // After load, update the overlay height as the new content might have
    // increased the overall page height.
    arrayPageSize = getPageSize();
    objOverlay.style.height = (arrayPageSize[1] + 'px');

    log(7);
    
    // Check for 'x' keypress
    listenKey();
}


//
// lightbox()
//
var lbX, lbY, lbW, lbH, lbOverflow;
function lightbox(target, P) {
    if (target==undefined) return;
    if (P==undefined) {var P = new Object();}


    var params = P.params; var h = P.height; var w = P.width; var x = P.left; var y = P.top; var callingObj = P.callingObj; var position = P.position; var overflow = P.overflow;


    if (params==undefined) {params = '';}
    if (overflow==undefined) {overflow = 'auto';}
    if (position==undefined) {position = 'absolute';}

    var arrayPageSize = getPageSize();
    var arrayPageScroll = getPageScroll();

    if (position=="relative") {
    // Relative to obj
        if (!callingObj) {alert('Lightbox needs a callingObj when positioning relatively');}

        if (x==undefined) x=0;
        if (y==undefined) y=0;
        x += getAbsoluteObjectX(callingObj);
        y += getAbsoluteObjectY(callingObj);
    } else {
    // Absolute
        if (y==undefined) y=20;
        y += arrayPageScroll[1];
    }

    lbX = x;
    lbY = y;
    lbW = w;
    lbH = h;
    lbOverflow = overflow;

    initLightbox();

    // prep objects
    var objOverlay = document.getElementById('overlay');
    var objLightbox = document.getElementById('lightbox');
    var objLoadingImage = document.getElementById('loadingImage');

    var arrayPageSize = getPageSize();
    var arrayPageScroll = getPageScroll();
    
    objLoadingImage.style.top = (arrayPageScroll[1] + ((arrayPageSize[3] - 35 - objLoadingImage.height) / 2) + 'px');
    objLoadingImage.style.left = (((arrayPageSize[0] - 20 - objLoadingImage.width) / 2) + 'px');
    objLoadingImage.style.display = 'block';

    // set height of Overlay to take up whole page and show
    objOverlay.style.height = (arrayPageSize[1] + 'px');
    objOverlay.style.display = 'block';


    new Ajax.Updater('lightbox', target, {method: 'get', parameters: params, onComplete: showLightbox});
}



//
// hideLightbox()
//
function hideLightbox()
{
    // get objects
    var objOverlay = document.getElementById('overlay');
    var objLightbox = document.getElementById('lightbox');
    var objLoadingImage = document.getElementById('loadingImage');

    // hide lightbox and overlay
    objOverlay.style.display = 'none';
    objLightbox.style.display = 'none';
    objLoadingImage.style.display = 'none';

    // disable keypress listener
    document.onkeypress = '';
}




//
// initLightbox()
//
function initLightbox()
{
    var objBody = document.getElementsByTagName("body").item(0);
    var arrayPageSize = getPageSize();
    var arrayPageScroll = getPageScroll();

    
    if (!document.getElementById('overlay')) {
    // create overlay div and hardcode some functional styles (aesthetic styles are in CSS file)
    var objOverlay = document.createElement("div");
    objOverlay.setAttribute('id','overlay');
    objOverlay.onclick = function () {hideLightbox(); return false;}
    objOverlay.style.display = 'none';
    objOverlay.style.position = 'absolute';
    objOverlay.style.top = '0';
    objOverlay.style.left = '0';
    objOverlay.style.zIndex = '90';
     objOverlay.style.width = '100%';
    objBody.insertBefore(objOverlay, objBody.firstChild);
    }    

    if (!document.getElementById('lightbox')) {
    // create lightbox div, same note about styles as above
    var objLightbox = document.createElement("div");
    objLightbox.setAttribute('id','lightbox');
    objLightbox.style.display = 'none';
    objLightbox.style.position = 'absolute';
    objLightbox.style.zIndex = '100';    
    objBody.insertBefore(objLightbox, objOverlay.nextSibling);
    }

    if (!document.getElementById('loadingImage')) {
    var objLoadingImage = document.createElement("img");
    objLoadingImage.src = loadingImgSrc;
    objLoadingImage.setAttribute('id','loadingImage');
    objLoadingImage.style.position = 'absolute';
    objLoadingImage.style.zIndex = '150';
    objBody.insertBefore(objLoadingImage, objBody.firstChild);
    }
}

