// Hebrew Language File
// Translation provided by Erel Segal

// Buttons
var lblSubmit                  = "שלח"; // Button value for non-designMode() & non fullsceen RTE
var lblModeRichText      = "טקסט מעוצב"; // Label of the Show Design view link
var lblModeHTML              = "קוד מקור"; // Label of the Show Code view link
var lblPreview                 = "תצוגה מקדימה";
var lblSave                       = "שמור";
var lblPrint                     = "הדפס";
var lblSelectAll             = "בחר הכל";
var lblSpellCheck             = "בדוק איות";
var lblCut                         = "גזור";
var lblCopy                         = "העתק";
var lblPaste                     = "הדבק";
var lblPasteText       = "הדבק כטקסט פשוט";
var lblPasteWord       = "הדבק מתוך וורד";
var lblUndo                         = "בטל פעולה אחרונה";
var lblRedo                         = "בצע שוב";
var lblHR                             = "קו מפריד";
var lblInsertChar             = "סימן מיוחד";
var lblBold                         = "הדגש";
var lblItalic                     = "הפוך לכתב נטוי";
var lblUnderline             = "מתח קו תחתי";
var lblStrikeThrough   = "מתח קו חוצה";
var lblSuperscript         = "כתב עילי";
var lblSubscript             = "כתב תחתי";
var lblAlgnLeft                 = "יישר שמאלה";
var lblAlgnCenter             = "יישר למרכז";
var lblAlgnRight             = "יישר ימינה";
var lblJustifyFull         = "יישר לצדדים";
var lblOL                             = "רשימה ממוספרת";
var lblUL                             = "רשימה לא ממוספרת";
var lblOutdent                 = "משוך פיסקה החוצה";
var lblIndent                     = "דחוף פיסקה פנימה";
var lblTextColor             = "צבע טקסט";
var lblBgColor                 = "צבע רקע";
var lblSearch                     = "חפש והחלף";
var lblInsertLink             = "קישור";
var lblUnLink             = "Remove link";
var lblAddImage                 = "ציור";
var lblInsertTable         = "טבלה";
var lblWordCount       = "ספור מילים";
var lblUnformat        = "בטל עיצוב";

// Dropdowns
// Format Dropdown
var lblFormat                  =  "<option value=\"\" selected>סגנון</option>";
lblFormat                          += "<option value=\"<h1>\">כותרת 1</option>";
lblFormat                          += "<option value=\"<h2>\">כותרת 2</option>";
lblFormat                          += "<option value=\"<h3>\">כותרת 3</option>";
lblFormat                          += "<option value=\"<h4>\">כותרת 4</option>";
lblFormat                          += "<option value=\"<h5>\">כותרת 5</option>";
lblFormat                          += "<option value=\"<h6>\">כותרת 6</option>";
lblFormat                          += "<option value=\"<p>\">ברירת מחדל של פיסקה</option>";
lblFormat                          += "<option value=\"<address>\">כתובת</option>";
lblFormat                          += "<option value=\"<pre>\">מעוצב מראש</option>";
// Font Dropdown
var lblFont                      =  "<option value=\"\" selected>גופן</option>";
lblFont                              += "<option value=\"Arial, Helvetica, sans-serif\">Arial</option>";
lblFont                              += "<option value=\"Courier New, Courier, mono\">Courier New</option>";
lblFont                              += "<option value=\"Palatino Linotype\">Palatino Linotype</option>";
lblFont                              += "<option value=\"Times New Roman, Times, serif\">Times New Roman</option>";
lblFont                              += "<option value=\"Verdana, Arial, Helvetica, sans-serif\">Verdana</option>";
var lblFontApply = "Apply Font";
// Size Dropdown
var lblSize                      =  "<option value=\"\">גודל</option>";
lblSize                              += "<option value=\"1\">1</option>";
lblSize                              += "<option value=\"2\">2</option>";
lblSize                              += "<option value=\"3\">3</option>";
lblSize                              += "<option value=\"4\">4</option>";
lblSize                              += "<option value=\"5\">5</option>";
lblSize                              += "<option value=\"6\">6</option>";
lblSize                              += "<option value=\"7\">7</option>";

// Alerts
var lblErrorPreload      = "שגיאה בטעינת תוכן.";
var lblSearchConfirm      =  "הביטוי [SF] נמצא [RUNCOUNT] פעמים.\n\n"; // Leave in [SF], [RUNCOUNT] and [RW]
lblSearchConfirm             += "האם ברצונך להחליף את כל המופעים של הביטוי ב-[RW] ?\n";
var lblSearchAbort          = "הפעולה בוטלה.";
var lblSearchNotFound     = "לא נמצא.";
var lblCountTotal         = "מספר המילים";
var lblCountChar         = "תוים שאפשר עוד להוסיף";
var lblCountCharWarn   = "זהירות! התוכן ארוך מדי וייתכן שלא יישמר כמו שצריך";

// Dialogs
// Insert Link
var lblLinkBlank            = "new window (_blank)";
var lblLinkSelf                = "same frame (_self)";
var lblLinkParent              = "parent frame (_parent)";
var lblLinkTop                  = "first frame (_top)";
var lblLinkType                  = "סוג הקישור";
var lblLinkOldA                 = "סימניה קיימת";
var lblLinkNewA               = "סימניה חדשה";
var lblLinkNoA              = "אין סימניות";
var lblLinkAnchors          = "סימניות";
var lblLinkAddress         = "כתובת";
var lblLinkText                  = "טקסט";
var lblLinkOpenIn             = "פתח קישור ב-";
var lblLinkVal0        = "אנא ציין את כתובת הקישור.";
var lblLinkSubmit          = "אישור";
var lblLinkCancel             = "ביטול";
// Insert Image
var lblImageURL                  = "כתובת ציור";
var lblImageAltText         = "טקסט חלופי";
var lblImageBorder           = "גבול";
var lblImageBorderPx      = "פיקסלים";
var lblImageAlign     = "Align"; 
var lblImageVal0          = "אנא ציין את  \"כתובת הציור\".";
var lblImageSubmit          = "אישור";
var lblImageCancel         = "ביטול";
// Insert Table
var lblTableRows             = "שורות";
var lblTableColumns         = "עמודות";
var lblTableWidth           = "רוחב הטבלה";
var lblTablePx              = "פיקסלים";
var lblTablePercent      = "אחוזים";
var lblTableBorder         = "עובי הגבול";
var lblTablePadding         = "רווח בתוך התאים";
var lblTableSpacing         = "רווח בין התאים";
var lblTableSubmit          = "אישור";
var lblTableCancel         = "ביטול";
// Search and Replace
var lblSearchFind             = "מה לחפש?";
var lblSearchReplace      = "במה להחליף?";
var lblSearchMatch     = "הבחן בין אותיות גדולות לקטנות?";
var lblSearchWholeWord = "מצא רק מילים שלמות?";
var lblSearchVal0             = "אנא הכנס ערך לחיפוש";
var lblSearchSubmit         = "אישור";
var lblSearchCancel         = "ביטול";
// Paste As Plain Text
var lblPasteTextHint   = "עצה: כדי להדביק, אפשר להקליק כפתור-ימני ולבחור  \"הדבק\" או להשתמש ב-  Ctrl-V.<br><br>";
var lblPasteTextVal0   = "אנא הכנס טקסט."
var lblPasteTextSubmit = "אישור";
var lblPasteTextCancel = "ביטול";
// Paste As Plain Text
var lblPasteWordHint   = "עצה: כדי להדביק, אפשר להקליק כפתור-ימני ולבחור  \"הדבק\" או להשתמש ב-  Ctrl-V.<br><br>";
var lblPasteWordVal0   = "אנא הכנס טקסט."
var lblPasteWordSubmit = "אישור";
var lblPasteWordCancel = "ביטול";


// non-designMode
var lblAutoBR                     = "הוסף סופי-שורה באופן אוטומטי";
var lblRawHTML                  = "השתמש רק בקוד html גולמי";
var lblnon_designMode  = 'כדי להשתמש בעורך טקסט מעוצב, דרוש דפדפן <a href="http://www.mozilla.org/" target="_new">Mozilla 1.3+</a> (לדוגמה, <a href="http://www.mozilla.org/products/firefox/" target=_new>Firefox</a>), Safari 1.3+, Opera 9+  או <a href="http://www.microsoft.com/windows/ie/default.asp" target="_new">MS IE5+</a> (חלונות). הדפדפנים IE5(Mac) עדיין לא נתמכים, וכל הטקסט חייב להיות בקוד  HTML.';

