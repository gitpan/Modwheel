// Polish Language File (UTF-8) 
// Translation provided by Marcin Kierdelewicz, marcin(dot)kierdelewicz(at)gmail(dot)com

// Buttons 
var lblSubmit          = "Prześlij"; // Button value for non-designMode() & non fullsceen RTE 
var lblModeRichText    = "Przełącz do trybu RichText"; // Label of the Show Design view link 
var lblModeHTML        = "Przełącz do trybu HTML"; // Label of the Show Code view link 
var lblPreview                 = "Podgląd";
var lblSave            = "Zapisz"; 
var lblPrint           = "Drukuj"; 
var lblSelectAll       = "Zaznacz/Odznacz wszystko"; 
var lblSpellCheck      = "Sprawdź pisownię"; 
var lblCut             = "Wytnij"; 
var lblCopy            = "Kopiuj"; 
var lblPaste           = "Wklej";
var lblPasteText       = "Wklej jako zwykły tekst";
var lblPasteWord       = "Wklej jako tekst z WORD'a"; 
var lblUndo            = "Cofnij"; 
var lblRedo            = "Powtórz"; 
var lblHR              = "Pozioma linia"; 
var lblInsertChar      = "Wstaw znaki specjalne"; 
var lblBold            = "Pogrubienie"; 
var lblItalic          = "Kursywa"; 
var lblUnderline       = "Podkreślenie"; 
var lblStrikeThrough   = "Rozstrzel tekst"; 
var lblSuperscript     = "Indeks górny"; 
var lblSubscript       = "Indeks dolny"; 
var lblAlgnLeft        = "Wyrównaj do lewej"; 
var lblAlgnCenter      = "Wyrównanie do środka"; 
var lblAlgnRight       = "Wyrównaj do prawej"; 
var lblJustifyFull     = "Wyjustuj"; 
var lblOL              = "Lista uporządkowana"; 
var lblUL              = "Lista nieuporządkowana"; 
var lblOutdent         = "Zmniejsz wcięcie"; 
var lblIndent          = "Zwiększ wcięcie"; 
var lblTextColor       = "Kolor tekstu"; 
var lblBgColor         = "Kolor tła"; 
var lblSearch          = "Wyszukaj i zamień"; 
var lblInsertLink      = "Wstaw odnośnik"; 
var lblUnLink             = "Remove link";
var lblAddImage        = "Dodaj rysunek"; 
var lblInsertTable     = "Wstaw tabelę"; 
var lblWordCount       = "Policz słowa";
var lblUnformat        = "Porzuć formatowanie";

// Dropdowns 
// Format Dropdown 
var lblFormat          =  "<option value=\"\" selected>Styl</option>"; 
lblFormat              += "<option value=\"<h1>\">Nagłówek 1</option>"; 
lblFormat              += "<option value=\"<h2>\">Nagłówek 2</option>"; 
lblFormat              += "<option value=\"<h3>\">Nagłówek 3</option>"; 
lblFormat              += "<option value=\"<h4>\">Nagłówek 4</option>"; 
lblFormat              += "<option value=\"<h5>\">Nagłówek 5</option>"; 
lblFormat              += "<option value=\"<h6>\">Nagłówek 6</option>"; 
lblFormat              += "<option value=\"<p>\">Akapit</option>"; 
lblFormat              += "<option value=\"<address>\">Adres</option>"; 
lblFormat              += "<option value=\"<pre>\">Preformatowany</option>"; 
// Font Dropdown 
var lblFont            =  "<option value=\"\" selected>Czcionka</option>"; 
lblFont                += "<option value=\"Arial, Helvetica, sans-serif\">Arial</option>"; 
lblFont                += "<option value=\"Courier New, Courier, mono\">Courier New</option>"; 
lblFont                += "<option value=\"Palatino Linotype\">Palatino Linotype</option>"; 
lblFont                += "<option value=\"Times New Roman, Times, serif\">Times New Roman</option>"; 
lblFont                += "<option value=\"Verdana, Arial, Helvetica, sans-serif\">Verdana</option>"; 
var lblFontApply = "Apply Font";
// Size Dropdown 
var lblSize            =  "<option value=\"\">Rozmiar</option>"; 
lblSize                += "<option value=\"1\">1</option>"; 
lblSize                += "<option value=\"2\">2</option>"; 
lblSize                += "<option value=\"3\">3</option>"; 
lblSize                += "<option value=\"4\">4</option>"; 
lblSize                += "<option value=\"5\">5</option>"; 
lblSize                += "<option value=\"6\">6</option>"; 
lblSize                += "<option value=\"7\">7</option>"; 

// Alerts 
var lblErrorPreload    = "Błąd ładowania treści."; 
var lblSearchConfirm   =  "Szukane wyrażenie [SF] występuje [RUNCOUNT] raz(y).\n\n"; // Leave in [SF], [RUNCOUNT] and [RW]
lblSearchConfirm       += "Czy jesteś pewny, że chcesz zamienić te dane na [RW] ?\n";
var lblSearchAbort     = "Operacja przerwana."; 
var lblSearchNotFound  = "nie został znaleziony."; 
var lblCountTotal         = "Wpisanych słów";
var lblCountChar         = "Dostępnych znaków";
var lblCountCharWarn   = "Uwaga! Treść jest za długa i może zostać zapisana nieprawidłowo.";

// Dialogs 
// Insert Link 
var lblLinkBlank            = "new window (_blank)";
var lblLinkSelf                = "same frame (_self)";
var lblLinkParent              = "parent frame (_parent)";
var lblLinkTop                  = "first frame (_top)";
var lblLinkType        = "Typ odnośnika"; 
var lblLinkOldA        = "istniejąca kotwica"; 
var lblLinkNewA        = "nowa kotwica"; 
var lblLinkNoA         = "Brak istniejących kotwic"; 
var lblLinkAnchors     = "Kotwice"; 
var lblLinkAddress     = "Adres"; 
var lblLinkText        = "Tekst odnośnika"; 
var lblLinkOpenIn      = "Otwórz odnośnik w"; 
var lblLinkVal0        = "Proszę wpisać url."; 
var lblLinkSubmit      = "Wstaw"; 
var lblLinkCancel      = "Anuluj"; 
// Insert Image 
var lblImageURL        = "URL obrazka"; 
var lblImageAltText    = "Opis rysunku"; 
var lblImageBorder     = "Tło"; 
var lblImageBorderPx   = "pikseli"; 
var lblImageAlign     = "Align"; 
var lblImageVal0       = "Proszę wypełnić pole \"URL obrazka\"."; 
var lblImageSubmit     = "Wstaw"; 
var lblImageCancel     = "Anuluj"; 
// Insert Table 
var lblTableRows       = "Wierszy"; 
var lblTableColumns    = "Kolumn"; 
var lblTableWidth      = "Szerokość tabeli"; 
var lblTablePx         = "pikseli"; 
var lblTablePercent    = "procent"; 
var lblTableBorder     = "Grubość ramki"; 
var lblTablePadding    = "Odległości na zewnątrz"; 
var lblTableSpacing    = "Odległości względem komórek"; 
var lblTableSubmit     = "Wstaw"; 
var lblTableCancel     = "Anuluj"; 
// Search and Replace 
var lblSearchFind      = "Znajdź"; 
var lblSearchReplace   = "Zamień na"; 
var lblSearchMatch     = "Uwzględniaj wielkość liter"; 
var lblSearchWholeWord = "Wyszukuj tylko całe wyrazy"; 
var lblSearchVal0      = "Musisz wypełnić pole \"Znajdź:\"."; 
var lblSearchSubmit    = "Zamień"; 
var lblSearchCancel    = "Anuluj"; 
// Paste As Plain Text
var lblPasteTextHint   = "Wskazówka: Aby wkleić tekst, możesz kliknąć prawym przyciskiem myszki i wybrać \"Paste\" lub użyć kombinacji klawiszy Ctrl-V.<br><br>";
var lblPasteTextVal0   = "Proszę wprowadzić tekst."
var lblPasteTextSubmit = "Zamień";
var lblPasteTextCancel = "Anuluj";
// Paste As Plain Text
var lblPasteWordHint   = "Wskazówka: Aby wkleić tekst, możesz kliknąć prawym przyciskiem myszki i wybrać \"Paste\" lub użyć kombinacji klawiszy Ctrl-V.<br><br>";
var lblPasteWordVal0   = "Proszę wprowadzić tekst."
var lblPasteWordSubmit = "Zamień";
var lblPasteWordCancel = "Anuluj";

// non-designMode 
var lblAutoBR          = "Użyj automatycznego łamania linii"; 
var lblRawHTML         = "Użyj tylko czystego HTML"; 
var lblnon_designMode  = 'Aby korzystać z edytora "Rich Text" wymagana jest przeglądarka <a href="http://www.mozilla.org/" target="_new">Mozilla 1.3+</a> (np., <a href="http://www.mozilla.org/products/firefox/" target=_new>Firefox</a>), Safari 1.3+, Opera 9+  lub <a href="http://www.microsoft.com/windows/ie/default.asp" target="_new">MS IE5+</a> (Windows). Przeglądarki IE5(Mac) w obecnej chwili nie są wspierane i tekst musi być od razu wpisywany w postaci HTML.'; 
