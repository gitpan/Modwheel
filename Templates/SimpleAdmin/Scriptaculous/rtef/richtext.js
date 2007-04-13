////////////////////////////////////////////////////////////////////////////////
//
// Richtext Editor: Fork (RTEF) VERSION: 0.004
// Released: 9/07/2006
// For the latest release visit http://rtef.info
// For support visit http://rtef.info/deluxebb
//
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
// The MIT License
//
// Copyright (c) 2006 Timothy Bell
//
// Permission is hereby granted, free of charge, to any person obtaining a copy 
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights 
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell 
// copies of the Software, and to permit persons to whom the Software is 
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in 
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR 
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE 
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER 
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE 
// SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////

// Constants
var minWidth = 640;                    // minumum width
var wrapWidth = 1268;                // width at which all icons will appear on one bar
var maxchar = 64000;                // maximum number of characters per save
var lang = "en";                    // xhtml language
var lang_direction = "ltr";            // language direction:ltr=left-to-right,rtl=right-to-left 
var encoding = "utf-8";                // xhtml encoding
var zeroBorder = "#c0c0c0";            // guideline color - see showGuidelines()
var btnText = "submit";                // Button value for non-designMode() & fullsceen rte
var resize_fullsrcreen = true;
// (resize_fullsrcreen) limited in that: 1)won't auto wrap icons. 2)won't
// shrink to less than (wrapWidth)px if screen was initized over (wrapWidth)px;

var keep_absolute = true;            // !!!Disabled - see line 565 for details!!!!!  
// By default IE will try to convery all hyperlinks to absolute paths. By
// setting this value to "false" it will retain the relative path.

// Pointers
var InsertChar;
var InsertTable;
var InsertLink;
var InsertImg;
var dlgReplace;
var dlgPasteText;
var dlgPasteWord;

//Init Variables & Attributes
var ua = navigator.userAgent.toLowerCase();
var isIE = ((ua.indexOf("msie") != -1) && (ua.indexOf("opera") == -1) && (ua.indexOf("webtv") == -1))? true:false;
var isIE7 = (isIE && (ua.indexOf("msie 7") !=-1));
var isIE5 = (isIE && (ua.indexOf("msie 5.0") !=-1));
var    isOpera = (ua.indexOf("opera") != -1)? true:false;
var OperaVersion = parseFloat(ua.substring(ua.lastIndexOf("Opera/") + 7));
var    isGecko = (ua.indexOf("gecko") != -1)? true:false;
var    isSafari = (ua.indexOf("safari") != -1)? true:false;
var SafariVersion = parseFloat(ua.substring(ua.lastIndexOf("safari/") + 7));
var    isKonqueror = (ua.indexOf("konqueror") != -1)? true:false;
var rng;
var currentRTE;
var allRTEs = "";
var obj_width;
var obj_height;
var imagesPath;
var includesPath;
var cssFile;
var generateXHTML = true;
var isRichText = false;
//check to see if designMode mode is available
if(document.getElementById && document.designMode) {
    isRichText = true;
}
//for testing standard textarea, uncomment the following line
//isRichText = false;

var replacements = new Array (
new RegExp(String.fromCharCode(145),'g'), "'",
new RegExp(String.fromCharCode(146),'g'), "'",
new RegExp("'"), "&#39;",
//convert all types of double quotes
new RegExp(String.fromCharCode(147),'g'), "\"",
new RegExp(String.fromCharCode(148),'g'), "\"",
//new RegExp("\""), "&#34;",
//replace carriage returns & line feeds
new RegExp("[\r\n]",'g'), " ");

function rteSafe(html) {
    html = trim(html);
    for (i=0; i<replacements.length; i = i+2) {
        html = html.replace(replacements[i], replacements[i+1]);
    }
    return html;
}

function initRTE(imgPath, incPath, css, genXHTML) {
    // CM 05/04/05 check args for compatibility with old RTE implementations
    if (arguments.length == 3) {
        genXHTML = generateXHTML;
    }
    //set paths vars
    imagesPath = imgPath;
    includesPath = incPath;
    cssFile = css;
    generateXHTML = genXHTML;
    if(isRichText) {
        document.writeln('<style type="text/css">@import "' + includesPath + 'rte.css";</style>');
    }
    if(!isIE) {
        minWidth = minWidth-50;
        wrapWidth = wrapWidth-106;
    } else if(isIE7) {
        minWidth = minWidth+2;
        wrapWidth = wrapWidth+4;
    }
}

function writeRichText(rte, html, css, width, height, buttons, readOnly, fullscreen) {
    currentRTE = rte;
    if(allRTEs.length > 0) {
        allRTEs += ";";
    }
    allRTEs += rte;
    // CM 06/04/05 stops single quotes from messing everything up
    html=replaceIt(html,'\'','&apos;');
    // CM 05/04/05 a bit of juggling for compatibility with old RTE implementations
    if (arguments.length == 6) {
        fullscreen = false;
        readOnly = buttons;
        buttons = height;
        height = width;
        width = css;
        css = "";
    }
    var iconWrapWidth = wrapWidth;
    var tablewidth;
    if(readOnly) {
        buttons = false;
    }
    if(fullscreen) {
        readOnly = false; // fullscreen is not readOnly and must show buttons
        buttons = true;
        // resize rte on resize if the option resize_fullsrcreen = true.
        if(isRichText && resize_fullsrcreen) {
            window.onresize = resizeRTE;
        }
        document.body.style.margin = "0px";
        document.body.style.overflow = "hidden";
        //adjust maximum table widths
        findSize("");
        width = obj_width;
        if(width < iconWrapWidth) {
            height = (obj_height - 83);
        } else {
            height = (obj_height - 55);
        }
        if (width < minWidth) {
            document.body.style.overflow = "auto";
            if(isIE) {
                height = obj_height-22;
            } else {
                height = obj_height-24;
            }
            width = minWidth;
        }
        tablewidth = width;
    } else {
        fullscreen = false;
        iconWrapWidth = iconWrapWidth-25;
        //adjust minimum table widths
        if(buttons && (width < minWidth)) {
            width = minWidth;
        }
        if(isIE) {
            tablewidth = width;
        } else {
            tablewidth = width + 4;
        }
    }
    if(isRichText) {
        var rte_css = "";
        if(css.length > 0) {
            rte_css = css;
        } else {
            rte_css = cssFile;
        }
        //preload of the design icon
        document.writeln('<img src="'+imagesPath+'design.gif" style="display:none"><span class="rteDiv">');
        if(buttons) {
            document.writeln('<table class="rteBk" cellpadding=0 cellspacing=0 id="Buttons1_'+rte+'" width="' + tablewidth + '">');
            document.writeln('<tbody><tr>');
            insertBar();
            if(fullscreen) {
                document.writeln('<td><input type=image class="rteImg" src="'+imagesPath+'save.gif" alt="'+lblSave+'" title="'+lblSave+'" onmouseover="this.className=\'rteImgUp\'" onmouseout="this.className=\'rteImg\'" onmousedown="this.className=\'rteImgDn\'" onmouseup="this.className=\'rteImgUp\'"></td>');
            }
            insertImg(lblPrint,"print.gif","rtePrint('"+rte+"')");
            if(!isSafari && !isKonqueror) {
                insertSep();
                insertImg(lblSelectAll,"selectall.gif","toggleSelection('"+rte+"')");
                insertImg(lblUnformat,"unformat.gif","rteCommand('"+rte+"','removeformat')");
                if(!isOpera)insertSep();
            }
            if(isSafari || isKonqueror)insertImg(lblUnformat,"unformat.gif","insertHTML(getText('"+rte+"'))");
            if(isIE || isSafari || isKonqueror) {
                insertImg(lblCut,"cut.gif","rteCommand('"+rte+"','cut')");
                insertImg(lblCopy,"copy.gif","rteCommand('"+rte+"','copy')");
            }
            if(isIE) insertImg(lblPaste,"paste.gif","rteCommand('"+rte+"','paste')");
            if(!isOpera) {
                insertImg(lblPasteText,"pastetext.gif","dlgLaunch('"+rte+"','text')");
                insertImg(lblPasteWord,"pasteword.gif","dlgLaunch('"+rte+"','word')");
            }
            insertSep();
            insertImg(lblUndo,"undo.gif","rteCommand('"+rte+"','undo')");
            insertImg(lblRedo,"redo.gif","rteCommand('"+rte+"','redo')");
            insertSep();
            if(!isSafari && !isKonqueror) {
                document.writeln('<td>');
                document.writeln('<select id="formatblock_'+rte+'" onchange="selectFont(\''+rte+'\', this.id)" style="font-size:14px;width:105px;height:20px;margin:1px;">');
                document.writeln(lblFormat);
                document.writeln('</select></td>');
            }
            document.writeln('<td>');
            document.writeln('<select id="fontname_'+rte+'" onchange="selectFont(\''+rte+'\', this.id)" style="font-size:14px;width:125px;height:20px;margin:1px;">');
            document.writeln(lblFont);
            document.writeln('</select></td>');
            if(isSafari || isKonqueror) insertImg(lblFontApply,"apply.png","selectFont('"+rte+"', 'fontname_"+rte+"')");
            if(!isSafari && !isKonqueror) {
                document.writeln('<td>');
                document.writeln('<select unselectable="on" id="fontsize_'+rte+'" onchange="selectFont(\''+rte+'\', this.id);return false" style="font-size:14px;width:75px;height:20px;margin:1px;">');
                document.writeln(lblSize);
                document.writeln('</select></td>');
            }
            if(tablewidth < iconWrapWidth) {
                document.writeln('<td width="100%"></td></tr></tbody></table>');
                document.writeln('<table class="rteBk" cellpadding="0" cellspacing="0" id="Buttons2_'+rte+'" width="' + tablewidth + '">');
                document.writeln('<tbody><tr>');
                insertBar();
            } else {
                insertSep();
            }
            insertImg(lblBold,"bold.gif","rteCommand('"+rte+"','bold')");
            insertImg(lblItalic,"italic.gif","rteCommand('"+rte+"','italic')");
            insertImg(lblUnderline,"underline.gif","rteCommand('"+rte+"','underline')");
            //if(!isSafari && !isKonqueror) insertImg(lblStrikeThrough,"strikethrough.gif","rteCommand('"+rte+"','strikethrough')");
            //else insertImg(lblStrikeThrough,"strikethrough.gif","insertHTML('<strike>'+getText('"+rte+"')+'</strike>')");
      insertSep();
            //insertImg(lblSuperscript,"superscript.gif","rteCommand('"+rte+"','superscript')");
            //insertImg(lblSubscript,"subscript.gif","rteCommand('"+rte+"','subscript')");
            //insertSep();
            insertImg(lblAlgnLeft,"left_just.gif","rteCommand('"+rte+"','justifyleft')");
            insertImg(lblAlgnCenter,"centre.gif","rteCommand('"+rte+"','justifycenter')");
            insertImg(lblAlgnRight,"right_just.gif","rteCommand('"+rte+"','justifyright')");
            insertImg(lblJustifyFull,"justifyfull.gif","rteCommand('"+rte+"','justifyfull')");
            insertSep();
            if(!isSafari && !isKonqueror) {
                insertImg(lblOL,"numbered_list.gif","rteCommand('"+rte+"','insertorderedlist')");
                insertImg(lblUL,"list.gif","rteCommand('"+rte+"','insertunorderedlist')");
                insertImg(lblOutdent,"outdent.gif","rteCommand('"+rte+"','outdent')");
                insertImg(lblIndent,"indent.gif","rteCommand('"+rte+"','indent')");
                insertSep();
            }
            insertImg(lblTextColor,"textcolor.gif","dlgColorPalette('"+rte+"','forecolor')","forecolor_"+rte);
            insertImg(lblBgColor,"bgcolor.gif","dlgColorPalette('"+rte+"','hilitecolor')","hilitecolor_"+rte);
            insertSep();
            if(isSafari)insertImg(lblHR,"hr.gif","insertHTML('<hr /><br>')");
            if(!isSafari)insertImg(lblHR,"hr.gif","rteCommand('"+rte+"','inserthorizontalrule')");
            insertSep();
            if(!isOpera)insertImg(lblInsertChar,"special_char.gif","dlgLaunch('"+rte+"','char')");
            insertImg(lblInsertLink,"hyperlink.gif","dlgLaunch('"+rte+"','link')");
            if(!isSafari && !isKonqueror)insertImg(lblUnLink,"unlink.gif","rteCommand('"+rte+"','Unlink')");
            insertImg(lblAddImage,"image.gif","dlgLaunch('"+rte+"','image')");
            if(!isOpera)insertImg(lblInsertTable,"insert_table.gif","dlgLaunch('"+rte+"','table')");
            insertSep();
            if(!isIE5)insertImg(lblSearch,"replace.gif","dlgLaunch('"+rte+"','replace')");
            insertImg(lblWordCount,"word_count.gif","countWords('"+rte+"')");
            if(isIE) insertImg(lblSpellCheck,"spellcheck.gif","checkspell()");
            document.writeln('<td width="100%"></td></tr></tbody></table>');
        }
        document.writeln('<iframe id="'+rte+'" width="' + (tablewidth - 2) + 'px" height="' + height + 'px" frameborder=0 style="border: 1px solid #d2d2d2" src="' + includesPath + 'blank.htm" onfocus="dlgCleanUp();"></iframe>');
        if(!readOnly) {
            document.writeln('<table id="vs'+rte+'" name="vs'+rte+'" class="rteBk" cellpadding=0 cellspacing=0 border=0 width="' + tablewidth + '"><tr>');
            document.writeln('<td onclick="toggleHTMLSrc(\''+rte+'\', ' + buttons + ');" nowrap><img class="rteBar" src="'+imagesPath+'bar.gif" alt="" align=absmiddle><span id="imgSrc'+rte+'"><img src="'+imagesPath+'code.gif" alt="" title="" style="margin:1px;" align=absmiddle></span><span id="_xtSrc'+rte+'" style="font-family:tahoma,sans-serif;font-size:12px;color:#0000ff;CURSOR: default;">'+lblModeHTML+'</span></td>');
            document.writeln('<td width="100%" nowrap>&nbsp;</td></tr></table>');
        }
        document.writeln('<iframe width="142" height="98" id="cp'+rte+'" src="' + includesPath + 'palette.htm" scrolling="no" frameborder=0 style="margin:0;border:0;visibility:hidden;position:absolute;border:1px solid #cdcdcd;top:-1000px;left:-1000px"></iframe>');
        document.writeln('<input type="hidden" id="hdn'+rte+'" name="'+rte+'" value="" style="position: absolute;left:-1000px;top:-1000px;">');
        if(!fullscreen) {
            document.writeln('<input type="hidden" id="size'+rte+'" name="size'+rte+'" value="'+height+'" style="position: absolute;left:-1000px;top:-1000px;">');
        }
        document.writeln('</span>');
        document.getElementById('hdn'+rte).value = html;
        enableDesignMode(rte, html, rte_css, readOnly);
    } else {
        buttons = false;
        if(fullscreen && height > 90) {
            height = (height - 75);
            tablewidth=tablewidth-30;
        }
        // CM non-designMode() UI
        html = parseBreaks(html);
        document.writeln('<div style="font:12px Verdana, Arial, Helvetica, sans-serif;width: ' + tablewidth + 'px;padding:15px;">');
        if(!readOnly) {
            document.writeln('<div style="color:gray">'+lblnon_designMode+'</div><br>');
            document.writeln('<input type="radio" name="' + rte + '_autobr" value="1" checked="checked" onclick="autoBRon(\'' + rte + '\');" /> '+lblAutoBR+'<input type="radio" name="' + rte + '_autobr" value="0" onclick="autoBRoff(\'' + rte + '\');" />'+lblRawHTML+'<br>');
            document.writeln('<textarea name="'+rte+'" id="'+rte+'" style="width: ' + tablewidth + 'px; height: ' + height + 'px;">' + html + '</textarea>');
        } else {
            document.writeln('<textarea name="'+rte+'" id="'+rte+'" style="width: ' + tablewidth + 'px; height: ' + height + 'px;" readonly=readonly>' + html + '</textarea>');
        }
        if(fullscreen) document.writeln('<br><input type="submit" value="'+btnText+'" />');
        document.writeln('</div>');
    }
}

function insertBar() {
    document.writeln('<td><img class="rteBar" src="'+imagesPath+'bar.gif" alt=""></td>');
}

function insertSep() {
    document.writeln('<td><img class="rteSep" src="'+imagesPath+'blackdot.gif" alt=""></td>');
}

function insertImg(name, image, command, id) {
    var td = "<td>";
    if(id!=null) {
        td = "<td id='"+id+"'>";
    }
    document.writeln(td+'<img class="rteImg" onmousemove="return false" src="'+imagesPath+image+'" alt="'+name+'" title="'+name+'" onMouseDown="'+command+';return false" onmouseover="this.className=\'rteImgUp\'" onmouseout="this.className=\'rteImg\'" onmousedown="this.className=\'rteImgDn\'" onmouseup="this.className=\'rteImgUp\'"></td>');
}

function enableDesignMode(rte, html, css, readOnly) {
    var frameHtml = "<html dir='" + lang_direction + "' lang='" + lang + "' id='" + rte + "'>\n<head>\n";
    frameHtml += "<meta http-equiv='Content-Type' content='text/html; charset=" + encoding + "'>\n";
    frameHtml += "<meta http-equiv='Content-Language' content='" + lang + "'>\n";
    //to reference your stylesheet, set href property below to your stylesheet path and uncomment
    if(css.length > 0) {
        frameHtml += "<link media=\"all\" type=\"text/css\" href=\"" + css + "\" rel=\"stylesheet\">\n";
    } else {
        frameHtml += "<style>@charset \"utf-8\"; body {background:#FFFFFF;margin:8px;padding:0px;}</style>\n";
    }
    frameHtml += "</head><body>\n"+html+"\n</body></html>";
    if(!isSafari && !isKonqueror) var oRTE = returnRTE(rte).document;
    if (document.all) {
        if(isSafari || isKonqueror) var oRTE = frames[rte].document;
        oRTE.open("text/html","replace");
        oRTE.write(frameHtml);
        oRTE.close();
        if (!readOnly) {
            oRTE.designMode = "On";
        }
    } else {
        try {
            if(!readOnly && !isKonqueror && !isSafari) {
                addLoadEvent(function() { document.getElementById(rte).contentDocument.designMode = "on"; });
            } else if(!readOnly) {
                //Safari doen't like the abouve command so we use this instad - Anders Jenbo.
                if (!readOnly) document.getElementById(rte).contentDocument.designMode = "on";
            }
            try {
                if(isSafari || isKonqueror) var oRTE = document.getElementById(rte).contentWindow.document;
                oRTE.open("text/html","replace");
                oRTE.write(frameHtml);
                oRTE.close();
                if(isGecko && !readOnly) {
                    //attach a keyboard handler for gecko browsers to make keyboard shortcuts work
                    oRTE.addEventListener("keypress", geckoKeyPress, true);
                    oRTE.addEventListener("focus", function () {dlgCleanUp(); }, false);
                }
            }
            catch(e) {
                alert(lblErrorPreload);
            }
        }
        catch(e) {
            //gecko may take some time to enable design mode.
            //Keep looping until able to set.
            if(isGecko) {
                setTimeout("enableDesignMode('"+rte+"', '"+html+"', '"+css+"', "+readOnly+");", 200);
            } else {
                return false;
            }
        }
    }
    setTimeout('showGuidelines("'+rte+'")',300);
}

function addLoadEvent(func) {
    var oldonload = window.onload;
    if (typeof window.onload != 'function') {
        window.onload = func;
    } else {
        window.onload = function() {
            oldonload();
            func();
        };
    }
}

function returnRTE(rte) {
    var rtn;
    if(document.all) {
        rtn = frames[rte];
    } else {
        rtn = document.getElementById(rte).contentWindow;
    }
    return rtn;
}

function updateRTE(rte) {
    if(isRichText) {
        dlgCleanUp();            // Closes Pop-ups
        stripGuidelines(rte);    // Removes Table Guidelines
    }
    parseRTE(rte);
}

function updateRTEs() {
    var vRTEs = allRTEs.split(";");
    for(var i=0; i<vRTEs.length; i++) {
        updateRTE(vRTEs[i]);
    }
}

function parseRTE(rte) {
    if (!isRichText) {
        autoBRoff(rte); // sorts out autoBR
        return false;
    }
    //check for readOnly mode
    var readOnly = false;
    var oRTE = returnRTE(rte);
    if(document.all) {
        if(oRTE.document.designMode != "On") {
            readOnly = true;
        }
    } else {
        if(oRTE.document.designMode != "on") {
            readOnly = true;
        }
    }
    if(isRichText && !readOnly) {
        //if viewing source, switch back to design view
        if(document.getElementById("_xtSrc"+rte).innerHTML == lblModeRichText) {
            if(document.getElementById("Buttons1_"+rte)) {
                toggleHTMLSrc(rte, true);
            } else {
                toggleHTMLSrc(rte, false);
            }
            stripGuidelines(rte);
        }
        setHiddenVal(rte);
    }
}

function setHiddenVal(rte) {
    //set hidden form field value for current rte
    var oHdnField = document.getElementById('hdn'+rte);
    //convert html output to xhtml (thanks Timothy Bell and Vyacheslav Smolin!)
    if(oHdnField.value==null) {
        oHdnField.value = "";
    }
    var sRTE = returnRTE(rte).document.body;
    if(generateXHTML) {
        try {
            oHdnField.value = getXHTML(sRTE.innerHTML);
        }
        catch(e) {
            oHdnField.value = sRTE.innerHTML;
        }
    } else {
        oHdnField.value = sRTE.innerHTML;
    }
    // fix to replace special characters added here: 
    oHdnField.value = replaceSpecialChars(oHdnField.value);
    //if there is no content (other than formatting) set value to nothing
    if(stripHTML(oHdnField.value.replace("&nbsp;", " ")) == "" &&
    oHdnField.value.toLowerCase().search("<hr") == -1 &&
    oHdnField.value.toLowerCase().search("<img") == -1) {
        oHdnField.value = "";
    }
}

function rteCommand(rte, command, option) {
    dlgCleanUp();
  //function to perform command
    var oRTE = returnRTE(rte);
    try {
        oRTE.focus();
        oRTE.document.execCommand(command, false, option);
        oRTE.focus();
    } catch(e) {
//        alert(e);
//        setTimeout("rteCommand('" + rte + "', '" + command + "', '" + option + "');", 10);
    }
}

function toggleHTMLSrc(rte, buttons) {
    dlgCleanUp();
    // contributed by Bob Hutzel (thanks Bob!)
    var cRTE = document.getElementById(rte);
    var hRTE = document.getElementById('hdn'+rte);
    var sRTE = document.getElementById("size"+rte);
    var tRTE = document.getElementById("_xtSrc"+rte);
    var iRTE = document.getElementById("imgSrc"+rte);
    var oRTE = returnRTE(rte).document;
    var htmlSrc;
    if(sRTE) {
        obj_height = parseInt(sRTE.value);
    } else {
        findSize(rte);
    }
    if(tRTE.innerHTML == lblModeHTML) {
        // we are checking the box
        tRTE.innerHTML = lblModeRichText;
        stripGuidelines(rte);
        if(buttons) {
            showHideElement("Buttons1_" + rte, "hide", true);
            if(document.getElementById("Buttons2_"+rte)) {
                showHideElement("Buttons2_" + rte, "hide", true);
                cRTE.style.height = obj_height+56;
            } else {
                cRTE.style.height = obj_height+28;
            }
        }
        setHiddenVal(rte);
        if(document.all) {
            oRTE.body.innerText = hRTE.value;
        } else {
            htmlSrc = oRTE.createTextNode(hRTE.value);
            oRTE.body.innerHTML = "";
            oRTE.body.appendChild(htmlSrc);
        }
        iRTE.innerHTML = '<img src="'+imagesPath+'design.gif" alt="Switch Mode" style="margin:1px;" align=absmiddle>';
    } else {
        // we are unchecking the box
        obj_height = parseInt(cRTE.style.height);
        tRTE.innerHTML = lblModeHTML;
        if(buttons) {
            showHideElement("Buttons1_" + rte, "show", true);
            if(document.getElementById("Buttons2_"+rte)) {
                showHideElement("Buttons2_" + rte, "show", true);
                cRTE.style.height = obj_height-56;
            } else {
                cRTE.style.height = obj_height-28;
            }
        }
        if(document.all) {
            // fix for IE
            var output = escape(oRTE.body.innerText);
            output = output.replace("%3CP%3E%0D%0A%3CHR%3E", "%3CHR%3E");
            output = output.replace("%3CHR%3E%0D%0A%3C/P%3E", "%3CHR%3E");
            oRTE.body.innerHTML = unescape(output);
            // Disabled due to flaw in the regular expressions, this fix 
            // does not work with the revamped's enhanced insert link dialog window.

            // Prevent links from changing to absolute paths
            if(!keep_absolute) {
                var tagfix = unescape(output).match(/<a[^>]*href=(['"])([^\1>]*)\1[^>]*>/ig);
                var coll = oRTE.body.all.tags('A');
                for(i=0; i<coll.length; i++) {
                    // the 2 alerts below show when we hinder the links from becoming absolute            
                    // alert(tagfix[i]); 
                    coll[i].href = tagfix[i].replace(/.*href=(['"])([^\1]*)\1.*/i,"$2");
                    // alert(RegExp.$1 + " " + RegExp.$2 + " " + RegExp.$3); 
                }
                var imgfix = unescape(output).match(/<img[^>]*src=['"][^'"]*['"][^>]*>/ig);
                var coll2 = oRTE.body.all.tags('IMG');
                for(i=0; i<coll2.length; i++) {
                    coll2[i].src = imgfix[i].replace(/.*src=['"]([^'"]*)['"].*/i,"$1");
                }
            }
          // end path fix            
        } else {
            htmlSrc = oRTE.body.ownerDocument.createRange();
            htmlSrc.selectNodeContents(oRTE.body);
            oRTE.body.innerHTML = htmlSrc.toString();
        }
        oRTE.body.innerHTML = replaceSpecialChars(oRTE.body.innerHTML);
        showGuidelines(rte);
        // (IE Only)This prevents an undo operation from displaying a pervious HTML mode
        // This resets the undo/redo buffer.
        if(document.all) {
            parseRTE(rte);
        }
        iRTE.innerHTML = '<img src="'+imagesPath+'code.gif" alt="Switch Mode" style="margin:1px;" align=absmiddle>';
    }
}

function toggleSelection(rte) {
    var rng = setRange(rte);
    var oRTE = returnRTE(rte).document;
    var length1;
    var length2;
    if(document.all) {
        length1 = rng.text.length;
        var output = escape(oRTE.body.innerText);
        output = output.replace("%3CP%3E%0D%0A%3CHR%3E", "%3CHR%3E");
        output = output.replace("%3CHR%3E%0D%0A%3C/P%3E", "%3CHR%3E");
        length2 = unescape(output).length;
    } else {
        length1 = rng.toString().length;
        var htmlSrc = oRTE.body.ownerDocument.createRange();
        htmlSrc.selectNodeContents(oRTE.body);
        length2 = htmlSrc.toString().length;
    }
    if(length1 < length2) {
        rteCommand(rte,'selectall','');
    } else {
        if(!document.all) {
            oRTE.designMode = "off";
            oRTE.designMode = "on";
        } else {
            rteCommand(rte,'unselect','');
        }
    }
}

function dlgColorPalette(rte, command) {
    // function to display or hide color palettes
    if(!isSafari && !isKonqueror)setRange(rte);
    // get dialog position
    var oDialog = document.getElementById('cp' + rte);
    var buttonElement = document.getElementById(command+"_"+rte);
    var iLeftPos = buttonElement.offsetLeft+5;
    var iTopPos = buttonElement.offsetTop+53;
    if (!document.getElementById('Buttons2_'+rte)) {
        iTopPos = iTopPos-28;
    }
    oDialog.style.left = iLeftPos + "px";
    oDialog.style.top = iTopPos + "px";
    if((command == parent.command)&&(rte == currentRTE)) {
        // if current command dialog is currently open, close it
        if(oDialog.style.visibility == "hidden") {
            showHideElement(oDialog, 'show', false);
        } else {
            showHideElement(oDialog, 'hide', false);
        }
    } else {
        // if opening a new dialog, close all others
        var vRTEs = allRTEs.split(";");
        for(var i = 0; i<vRTEs.length; i++) {
            showHideElement('cp' + vRTEs[i], 'hide', false);
        }
        showHideElement(oDialog, 'show', false);
    }
    // save current values
    currentRTE = rte;
    parent.command = command;
}

function dlgLaunch(rte, command) {
    var selectedText = '';
    // save current values
    parent.command = command;
    currentRTE = rte;
    switch(command) {
        case "char":
            InsertChar = popUpWin(includesPath+'insert_char.htm', 'InsertChar', 50, 50, 'status=yes,');
        break;
        case "table":
            InsertTable = popUpWin(includesPath + 'insert_table.htm', 'InsertTable', 50, 50, 'status=yes,');
        break;
        case "image":
            if(!isSafari && !isKonqueror)setRange(rte);
            parseRTE(rte);
            // sending rte and isOpera starte for Opera
            InsertImg = popUpWin(includesPath + 'insert_img.htm?rte='+ rte + '&isOpera=' + isOpera,'AddImage', 50, 50, 'status=yes,');
        break;
        case "link":
            if(!isOpera)selectedText = getText(rte);
            // sending rte and isOpera starte for Opera
            InsertLink = popUpWin(includesPath + 'insert_link.htm?rte='+ rte + '&isOpera=' + isOpera, 'InsertLink', 50, 50, 'status=yes,');
            if(!isOpera)setFormText("0", selectedText);
        break;
        case "replace":
            if(!isOpera)selectedText = getText(rte);
            dlgReplace = popUpWin(includesPath + 'replace.htm', 'dlgReplace', 50, 50, 'status=yes,');
            if(!isOpera)setFormText("1", selectedText);
        break;
        case "text":
            dlgPasteText = popUpWin(includesPath + 'paste_text.htm', 'dlgPasteText', 50, 50, 'status=yes,');
        break;
        case "word":
            dlgPasteWord = popUpWin(includesPath + 'paste_word.htm', 'dlgPasteWord', 50, 50, 'status=yes,');
        break;
    }
}

function getText(rte) {
    // get currently highlighted text and set link text value
    if(isSafari) {
        var oRTE = returnRTE(rte);
        var rtn = oRTE.getSelection();
        //This makes it a text string, i dont know any other ways and it seams quick
        rtn = "" + rtn;
        return rtn; 
    } else {
        setRange(rte);
        var rtn = '';
        if (isIE) {
            rtn = stripHTML(rng.htmlText);
        } else {
            rtn = stripHTML(rng.toString());
        }
        parseRTE(rte);
        if(document.all) {
            rtn = rtn.replace("'","\\\\\\'");
        } else {
            rtn = rtn.replace("'","\\'");
        }
        return rtn;
    }
}

function setFormText(popup, content) {
    // set link text value in dialog windows
    if(content != "undefined") {
        try {
            switch(popup) {
                case "0": InsertLink.document.getElementById("linkText").value = content; break;
                case "1": dlgReplace.document.getElementById("searchText").value = content; break;
            }
        }
        catch(e) {
              // may take some time to create dialog window.
              // Keep looping until able to set.
            setTimeout("setFormText('"+popup+"','" + content + "');", 10);
        }
    }
}

function dlgCleanUp() {
    var vRTEs = allRTEs.split(";");
    for(var i = 0; i < vRTEs.length; i++) {
        showHideElement('cp' + vRTEs[i], 'hide', false);
    }
    if(!isSafari && !isKonqueror && !isOpera && !isIE5) {
        if(InsertChar != null) {
            InsertChar.close();
            InsertChar=null;
        }
        if(InsertTable != null) {
            InsertTable.close();
            InsertTable=null;
        }
        if(InsertLink != null) {
            InsertLink.close();
            InsertLink=null;
        }
        if(InsertImg != null) {
            InsertImg.close();
            InsertImg=null;
        }
        if(dlgReplace != null) {
            dlgReplace.close();
            dlgReplace=null;
        }
        if(dlgPasteText != null) {
            dlgPasteText.close();
            dlgPasteText=null;
        }
        if(dlgPasteWord != null) {
            dlgPasteWord.close();
            dlgPasteWord=null;
        }
    }
}

function popUpWin (url, win, width, height, options) {
    dlgCleanUp();
    var leftPos = (screen.availWidth - width) / 2;
    var topPos = (screen.availHeight - height) / 2;
    options += 'width=' + width + ',height=' + height + ',left=' + leftPos + ',top=' + topPos;
    return window.open(url, win, options);
}

function setColor(color) {
    // function to set color
    var rte = currentRTE;
    var parentCommand = parent.command;

    if(document.all || isSafari || isKonqueror) {
        if(parentCommand == "hilitecolor") {
            parentCommand = "backcolor";
        }
        // retrieve selected range
        if(!isSafari && !isKonqueror)rng.select();
    }

    rteCommand(rte, parentCommand, color);
    showHideElement('cp'+rte, "hide", false);
}

function addImage(rte) {
    dlgCleanUp();
    // function to add image
    imagePath = prompt('Enter Image URL:', 'http://');
    if((imagePath != null)&&(imagePath != "")) {
        rteCommand(rte, 'InsertImage', imagePath);
    }
}

function rtePrint(rte) {
    dlgCleanUp();
    if(isIE) {
        document.getElementById(rte).contentWindow.document.execCommand('Print');
    } else {
        document.getElementById(rte).contentWindow.print();
    }
}

function selectFont(rte, selectname) {
    // function to handle font changes
    var idx = document.getElementById(selectname).selectedIndex;
    // First one is always a label
    if(idx != 0) {
        var selected = document.getElementById(selectname).options[idx].value;
        var cmd = selectname.replace('_'+rte, '');
        rteCommand(rte, cmd, selected);
        if(!isSafari && !isKonqueror)document.getElementById(selectname).selectedIndex = 0;
    }
}

function insertHTML(html) {
    if(!isSafari && !isKonqueror) {
        //function to add HTML -- thanks dannyuk1982
        var rte = currentRTE;
        var oRTE = returnRTE(rte);
        oRTE.focus();
        if(document.all) {
            var oRng = oRTE.document.selection.createRange();
            oRng.pasteHTML(html);
            oRng.collapse(false);
            oRng.select();
        } else {
            oRTE.document.execCommand('insertHTML', false, html);
        }
    } else {
        var searchFor = 'SafariHTMLReplaceString';
        var rte = currentRTE;
        rteCommand(rte,'InsertText', searchFor);
        var oRTE = returnRTE(rte);
        var tmpContent = oRTE.document.body.innerHTML.replace("'", "\'").replace('"', '\"');
        var strRegex = "/(?!<[^>]*)(" + searchFor + ")(?![^<]*>)/g";
        var cmpRegex=eval(strRegex);
        var runCount = 0;
        var tmpNext = tmpContent;
        var intFound = tmpNext.search(cmpRegex);
        while(intFound > -1) {
            runCount = runCount+1;
            tmpNext = tmpNext.substr(intFound + searchFor.length);
            intFound = tmpNext.search(cmpRegex);
        }
        if (runCount > 0) {
            tmpContent=tmpContent.replace(cmpRegex,html);
            oRTE.document.body.innerHTML = tmpContent.replace("\'", "'").replace('\"', '"');
            updateRTEs();
        }
    }
}

function replaceHTML(tmpContent, searchFor, replaceWith) {
    var runCount = 0;
    var intBefore = 0;
    var intAfter = 0;
    var tmpOutput = "";
    while(tmpContent.toUpperCase().indexOf(searchFor.toUpperCase()) > -1) {
        runCount = runCount+1;
        // Get all content before the match
        intBefore = tmpContent.toUpperCase().indexOf(searchFor.toUpperCase());
        tmpBefore = tmpContent.substring(0, intBefore);
        tmpOutput = tmpOutput + tmpBefore;
        // Get the string to replace
        tmpOutput = tmpOutput + replaceWith;
        // Get the rest of the content after the match until
        // the next match or the end of the content
        intAfter = tmpContent.length - searchFor.length + 1;
        tmpContent = tmpContent.substring(intBefore + searchFor.length);
    }
    return runCount+"|^|"+tmpOutput+tmpContent;
}

function replaceSpecialChars(html) {
    var specials = new Array("&cent;","&euro;","&pound;","&curren;","&yen;","&copy;","&reg;","&trade;","&divide;","&times;","&plusmn;","&frac14;","&frac12;","&frac34;","&deg;","&sup1;","&sup2;","&sup3;","&micro;","&laquo;","&raquo;","&lsquo;","&rsquo;","&lsaquo;","&rsaquo;","&sbquo;","&bdquo;","&ldquo;","&rdquo;","&iexcl;","&brvbar;","&sect;","&not;","&macr;","&para;","&middot;","&cedil;","&iquest;","&fnof;","&mdash;","&ndash;","&bull;","&hellip;","&permil;","&ordf;","&ordm;","&szlig;","&dagger;","&Dagger;","&eth;","&ETH;","&oslash;","&Oslash;","&thorn;","&THORN;","&oelig;","&OElig;","&scaron;","&Scaron;","&acute;","&circ;","&tilde;","&uml;","&agrave;","&aacute;","&acirc;","&atilde;","&auml;","&aring;","&aelig;","&Agrave;","&Aacute;","&Acirc;","&Atilde;","&Auml;","&Aring;","&AElig;","&ccedil;","&Ccedil;","&egrave;","&eacute;","&ecirc;","&euml;","&Egrave;","&Eacute;","&Ecirc;","&Euml;","&igrave;","&iacute;","&icirc;","&iuml;","&Igrave;","&Iacute;","&Icirc;","&Iuml;","&ntilde;","&Ntilde;","&ograve;","&oacute;","&ocirc;","&otilde;","&ouml;","&Ograve;","&Oacute;","&Ocirc;","&Otilde;","&Ouml;","&ugrave;","&uacute;","&ucirc;","&uuml;","&Ugrave;","&Uacute;","&Ucirc;","&Uuml;","&yacute;","&yuml;","&Yacute;","&Yuml;");
    var unicodes = new Array("\u00a2","\u20ac","\u00a3","\u00a4","\u00a5","\u00a9","\u00ae","\u2122","\u00f7","\u00d7","\u00b1","\u00bc","\u00bd","\u00be","\u00b0","\u00b9","\u00b2","\u00b3","\u00b5","\u00ab","\u00bb","\u2018","\u2019","\u2039","\u203a","\u201a","\u201e","\u201c","\u201d","\u00a1","\u00a6","\u00a7","\u00ac","\u00af","\u00b6","\u00b7","\u00b8","\u00bf","\u0192","\u2014","\u2013","\u2022","\u2026","\u2030","\u00aa","\u00ba","\u00df","\u2020","\u2021","\u00f0","\u00d0","\u00f8","\u00d8","\u00fe","\u00de","\u0153","\u0152","\u0161","\u0160","\u00b4","\u02c6","\u02dc","\u00a8","\u00e0","\u00e1","\u00e2","\u00e3","\u00e4","\u00e5","\u00e6","\u00c0","\u00c1","\u00c2","\u00c3","\u00c4","\u00c5","\u00c6","\u00e7","\u00c7","\u00e8","\u00e9","\u00ea","\u00eb","\u00c8","\u00c9","\u00ca","\u00cb","\u00ec","\u00ed","\u00ee","\u00ef","\u00cc","\u00cd","\u00ce","\u00cf","\u00f1","\u00d1","\u00f2","\u00f3","\u00f4","\u00f5","\u00f6","\u00d2","\u00d3","\u00d4","\u00d5","\u00d6","\u00f9","\u00fa","\u00fb","\u00fc","\u00d9","\u00da","\u00db","\u00dc","\u00fd","\u00ff","\u00dd","\u0178");
    for(var i=0; i<specials.length; i++) {
        html = replaceIt(html,unicodes[i],specials[i]);
    }
    return html;
}

function SearchAndReplace(searchFor, replaceWith, matchCase, wholeWord) {
    var cfrmMsg = lblSearchConfirm.replace("SF",searchFor).replace("RW",replaceWith);
    var rte = currentRTE;
    stripGuidelines(rte);
    var oRTE = returnRTE(rte);
    var tmpContent = oRTE.document.body.innerHTML.replace("'", "\'").replace('"', '\"');
    var strRegex;
    if (matchCase && wholeWord) {
        strRegex = "/(?!<[^>]*)(\\b(" + searchFor + ")\\b)(?![^<]*>)/g";
    } else if (matchCase) {
        strRegex = "/(?!<[^>]*)(" + searchFor + ")(?![^<]*>)/g";
    } else if (wholeWord) {
        strRegex = "/(?!<[^>]*)(\\b(" + searchFor + ")\\b)(?![^<]*>)/gi";
    } else {
        strRegex = "/(?!<[^>]*)(" + searchFor + ")(?![^<]*>)/gi";
    }
    var cmpRegex=eval(strRegex);
    var runCount = 0;
    var tmpNext = tmpContent;
    var intFound = tmpNext.search(cmpRegex);
    while(intFound > -1) {
        runCount = runCount+1;
        tmpNext = tmpNext.substr(intFound + searchFor.length);
        intFound = tmpNext.search(cmpRegex);
    }
    if (runCount > 0) {
        cfrmMsg = cfrmMsg.replace("[RUNCOUNT]",runCount);
        if(confirm(cfrmMsg)) {
            tmpContent=tmpContent.replace(cmpRegex,replaceWith);
            oRTE.document.body.innerHTML = tmpContent.replace("\'", "'").replace('\"', '"');
        } else {
            alert(lblSearchAbort);
        }
        showGuidelines(rte);
    } else {
        showGuidelines(rte);
        alert("["+searchFor+"] "+lblSearchNotFound);
    }
    if(isSafari || isKonqueror)updateRTEs();
}

function showHideElement(element, showHide, rePosition) {
    // function to show or hide elements
    // element variable can be string or object
    if(document.getElementById(element)) {
        element = document.getElementById(element);
    }
    if(showHide == "show") {
        element.style.visibility = "visible";
        if(rePosition) {
            element.style.position = "relative";
            element.style.left = "auto";
            element.style.top = "auto";
        }
    } else if(showHide == "hide") {
        element.style.visibility = "hidden";
        if(rePosition) {
            element.style.position = "absolute";
            element.style.left = "-1000px";
            element.style.top = "-1000px";
        }
    }
}

function setRange(rte) {
    // function to store range of current selection
    var oRTE = returnRTE(rte);
    var selection;
    if(document.all) {
        selection = oRTE.document.selection;
        if(selection != null) {
            rng = selection.createRange();
        }
    } else {
        selection = oRTE.getSelection();
        rng = selection.getRangeAt(selection.rangeCount - 1).cloneRange();
    }
    return rng;
}

function stripHTML(strU) {
    // strip all html
    var strN = strU.replace(/(<([^>]+)>)/ig,"");
    // replace carriage returns and line feeds
    strN = strN.replace(/\r\n/g," ");
    strN = strN.replace(/\n/g," ");
    strN = strN.replace(/\r/g," ");
    strN = trim(strN);
    return strN;
}

function trim(inputString) {
    if (typeof inputString != "string") {
        return inputString;
    }
    inputString = inputString.replace(/^\s+|\s+$/g, "").replace(/\s{2,}/g, "");
    return inputString;
}

function showGuidelines(rte) {
    if(rte.length == 0) rte = currentRTE;
    var oRTE = returnRTE(rte);
    var tables = oRTE.document.getElementsByTagName("table");
    var sty = "dashed 1px "+zeroBorder;
    for(var i=0; i<tables.length; i++) {
        if(tables[i].getAttribute("border") == 0) {
            if(document.all) {
                var trs = tables[i].getElementsByTagName("tr");
                for(var j=0; j<trs.length; j++) {
                    var tds = trs[j].getElementsByTagName("td");
                    for(var k=0; k<tds.length; k++) {
                        if(j == 0 && k == 0) {
                            tds[k].style.border = sty;
                        } else if(j == 0 && k != 0) {
                            tds[k].style.borderBottom = sty;
                            tds[k].style.borderTop = sty;
                            tds[k].style.borderRight = sty;
                        } else if(j != 0 && k == 0) {
                            tds[k].style.borderBottom = sty;
                            tds[k].style.borderLeft = sty;
                            tds[k].style.borderRight = sty;
                        } else if(j != 0 && k != 0) {
                            tds[k].style.borderBottom = sty;
                            tds[k].style.borderRight = sty;
                        }
                    }
                }
            } else {
                tables[i].removeAttribute("border");
                tables[i].setAttribute("style","border: " + sty);
                tables[i].setAttribute("rules", "all");
            }
        }
    }
}

function stripGuidelines(rte) {
    var oRTE = returnRTE(rte);
    var tbls = oRTE.document.getElementsByTagName("table");
    for(var j=0; j<tbls.length; j++) {
        if(tbls[j].getAttribute("border") == 0 || tbls[j].getAttribute("border") == null) {
            if(document.all) {
                var tds = tbls[j].getElementsByTagName("td");
                for(var k=0; k<tds.length; k++) {
                    tds[k].removeAttribute("style");
                }
            } else {
                tbls[j].removeAttribute("style");
                tbls[j].removeAttribute("rules");
                tbls[j].setAttribute("border","0");
            }
        }
    }
}

function findSize(obj) {
    if(obj.length > 0 && document.all) {
        obj = frames[obj];
    } else if(obj.length > 0 && !document.all) {
        obj = document.getElementById(obj).contentWindow;
    } else {
        obj = this;
    }
    if ( typeof( obj.window.innerWidth ) == 'number' ) {
        // Non-IE
        obj_width = obj.window.innerWidth;
        obj_height = obj.window.innerHeight;
    } else if( obj.document.documentElement && ( obj.document.documentElement.clientWidth || obj.document.documentElement.clientHeight ) ) {
        // IE 6+ in 'standards compliant mode'
        obj_width = document.documentElement.clientWidth;
        obj_height = document.documentElement.clientHeight;
    } else if( obj.document.body && ( obj.document.body.clientWidth || obj.document.body.clientHeight ) ) {
        // IE 4 compatible
        obj_width = obj.document.body.clientWidth;
        obj_height = obj.document.body.clientHeight;
    }
}

function resizeRTE() {
    document.body.style.overflow = "hidden";
    var rte = currentRTE;
    var oRTE = document.getElementById(rte);
    var oBut1 = document.getElementById('Buttons1_'+rte);
    var oBut2;
    var oVS = document.getElementById('vs'+rte);
    findSize("");
    width = obj_width;
    if (width < minWidth) {
        document.body.style.overflow = "auto";
        width = minWidth;
    }
    var height = obj_height - 83;
    if (document.getElementById("_xtSrc"+rte).innerHTML == lblModeRichText) {
        height = obj_height-28;
        if (!document.getElementById('Buttons2_'+rte) && width < wrapWidth) {
            document.body.style.overflow = "auto";
            width = wrapWidth;
        }
        if (document.getElementById('Buttons2_'+rte)) {
            document.getElementById('Buttons2_'+rte).style.width = width;
        }
    } else {
        if (document.getElementById('Buttons2_'+rte)) {
            document.getElementById('Buttons2_'+rte).style.width = width;
        } else {
            height = obj_height - 55;
            if(width < wrapWidth) {
                document.body.style.overflow = "auto";
                width = wrapWidth;
            }
        }
    }
    if(document.body.style.overflow == "auto" && isIE) {
        height = height-18;
    }
    if(document.body.style.overflow == "auto" && !isIE) {
        height = height-24;
    }
    oBut1.style.width = width;
    oVS.style.width = width;
    oRTE.style.width = width-2;
    oRTE.style.height = height;
    if(!document.all) {
        oRTE.contentDocument.designMode = "on";
    }
}

function replaceIt(string,text,by) {
    // CM 19/10/04 custom replace function
    var strLength = string.length, _xtLength = text.length;
    if ((strLength == 0) || (_xtLength == 0)) {
        return string;
    }
    var i = string.indexOf(text);
    if ((!i) && (text != string.substring(0,_xtLength))) {
        return string;
    }
    if(i == -1) {
        return string;
    }
    var newstr = string.substring(0,i) + by;
    if(i+_xtLength < strLength) {
        newstr += replaceIt(string.substring(i+_xtLength,strLength),text,by);
    }
    return newstr;
}

function countWords(rte) {
    parseRTE(rte);
    var words = document.getElementById("hdn"+rte).value;
    var str = stripHTML(words);
    var chars = trim(words);
    chars = chars.length;
    chars = maxchar - chars;
    str = str+" a ";    // word added to avoid error
    str = trim(str.replace(/&nbsp;/gi,' ').replace(/([\n\r\t])/g,' ').replace(/&(.*);/g,' '));
    var count = 0;
    for(x=0;x<str.length;x++) {
        if(str.charAt(x)==" " && str.charAt(x-1)!=" ") {
            count++;
        }
    }
    if(str.charAt(str.length-1) != " ") {
        count++;
    }
    count = count - 1;    // extra word removed
    var alarm = "";
    if(chars<0) {
        alarm = "\n\n"+lblCountCharWarn;
    }
    alert(lblCountTotal+": "+count+ "\n\n"+lblCountChar+": "+chars+alarm);
}

//********************
// Non-designMode() Functions
//********************
function autoBRon(rte) {
    // CM 19/10/04 used for non RTE browsers to deal with auto <BR> (and clean up other muck)
    var oRTE = document.forms[0].elements[rte];
    oRTE.value=parseBreaks(oRTE.value);
    oRTE.value=replaceIt(oRTE.value,'&apos;','\'');
}

function autoBRoff(rte) {
    // CM 19/10/04 used for non RTE browsers to deal with auto <BR> (auto carried out when the form is submitted)
    var oRTE = document.forms[0].elements[rte];
    oRTE.value=replaceIt(oRTE.value,'\n','<br />');
    oRTE.value=replaceIt(oRTE.value,'\'','&apos;');
}

function parseBreaks(argIn) {
    // CM 19/10/04 used for non RTE browsers to deal with auto <BR> (and clean up other muck)
    argIn=replaceIt(argIn,'<br>','\n');
    argIn=replaceIt(argIn,'<BR>','\n');
    argIn=replaceIt(argIn,'<br/>','\n');
    argIn=replaceIt(argIn,'<br />','\n');
    argIn=replaceIt(argIn,'\t',' ');
    argIn=replaceIt(argIn,'\n ','\n');
    argIn=replaceIt(argIn,' <p>','<p>');
    argIn=replaceIt(argIn,'</p><p>','\n\n');
    argIn=replaceIt(argIn,'&apos;','\'');
    argIn = trim(argIn);
    return argIn;
}

//********************
//Gecko-Only Functions
//********************
function geckoKeyPress(evt) {
    // function to add bold, italic, and underline shortcut commands to gecko RTEs
    // contributed by Anti Veeranna (thanks Anti!)
    var rte = evt.target.id;
    if (evt.ctrlKey) {
        var key = String.fromCharCode(evt.charCode).toLowerCase();
        var cmd = '';
        switch (key) {
            case 'b': cmd = "bold"; break;
            case 'i': cmd = "italic"; break;
            case 'u': cmd = "underline"; break;
        }
        if (cmd) {
            rteCommand(rte, cmd, null);
            // stop the event bubble
            evt.preventDefault();
            evt.stopPropagation();
        }
    }
}

//*****************
//IE-Only Functions
//*****************
function checkspell() {
    dlgCleanUp();
    //function to perform spell check
    try {
        var tmpis = new ActiveXObject("ieSpell.ieSpellExtension");
        tmpis.CheckAllLinkedDocuments(document);
    }
    catch(exception) {
        if(exception.number==-2146827859) {
            if(confirm("ieSpell not detected. Click Ok to go to download page.")) {
                window.open("http://www.iespell.com/download.php","DownLoad");
            }
        } else {
            alert("Error Loading ieSpell: Exception " + exception.number);
        }
    }
}
