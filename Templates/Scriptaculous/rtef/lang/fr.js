// French Language File
// Translation provided by Christian Dispagne
// Revised by François Talbot

// Buttons
var lblSubmit          = "Soumettre"; // Button value for non-designMode() & non fullsceen RTE
var lblModeRichText      = "Passer en mode editeur"; // Label of the Show Design view link
var lblModeHTML      = "Voir le code HTML"; // Label of the Show Code view link
var lblPreview         = "Visualiser";
var lblSave          = "Sauvegarder";
var lblPrint         = "Imprimer";
var lblSelectAll     = "Sélectionner/Désélectionner Tout";
var lblSpellCheck     = "Vérifier l\'orthographe";
var lblCut         = "Couper";
var lblCopy         = "Copier";
var lblPaste         = "Coller";
var lblPasteText = "Coller en texte standard";
var lblPasteWord = "Coller à partir de Word";
var lblUndo         = "Annuler";
var lblRedo         = "Répéter";
var lblHR         = "Ligne horizontale";
var lblInsertChar     = "Insérer un caractère spécial";
var lblBold         = "Gras";
var lblItalic         = "Italique";
var lblUnderline     = "Souligné";
var lblStrikeThrough = "Frapper Par";
var lblSuperscript     = "Exposant";
var lblSubscript     = "Indice inférieur";
var lblAlgnLeft         = "Aligner à gauche";
var lblAlgnCenter     = "Centrer";
var lblAlgnRight     = "Aligner à droite";
var lblJustifyFull     = "Justifié";
var lblOL         = "Liste ordonnée";
var lblUL         = "Liste non-ordonnée";
var lblOutdent         = "Diminuer le retrait";
var lblIndent         = "Augmenter le retrait";
var lblTextColor     = "Couleur du texte";
var lblBgColor         = "Couleur de fond";
var lblSearch         = "Chercher et remplacer";
var lblInsertLink     = "Insérer un lien";
var lblUnLink             = "Remove link";
var lblAddImage         = "Ajouter une image";
var lblInsertSmiley     = "Insérer un smiley";
var lblInsertTable     = "Insérer un tableau";
var lblWordCount = "Nombre de mots";
var lblUnformat = "Enlever le formatage";

// Dropdowns
// Format Dropdown
var lblFormat          = "<option value=\"\" selected>Format</option>";
lblFormat         += "<option value=\"<h1>\">Titre 1</option>";
lblFormat         += "<option value=\"<h2>\">Titre 2</option>";
lblFormat         += "<option value=\"<h3>\">Titre 3</option>";
lblFormat         += "<option value=\"<h4>\">Titre 4</option>";
lblFormat         += "<option value=\"<h5>\">Titre 5</option>";
lblFormat         += "<option value=\"<h6>\">Titre 6</option>";
lblFormat         += "<option value=\"<p>\">Paragraphe</option>";
lblFormat         += "<option value=\"<address>\">Adresse</option>";
lblFormat         += "<option value=\"<pre>\">Préformatté</option>";
// Font Dropdown
var lblFont     = "<option value=\"\" selected>Police</option>";
lblFont         += "<option value=\"Arial, Helvetica, sans-serif\">Arial</option>";
lblFont         += "<option value=\"Courier New, Courier, mono\">Courier New</option>";
lblFont         += "<option value=\"Palatino Linotype\">Palatino Linotype</option>";
lblFont         += "<option value=\"Times New Roman, Times, serif\">Times New Roman</option>";
lblFont         += "<option value=\"Verdana, Arial, Helvetica, sans-serif\">Verdana</option>";
var lblFontApply = "Apply Font";
// Size Dropdown
var lblSize     = "<option value=\"\" selected>Taille</option>";
lblSize         += "<option value=\"1\">1</option>";
lblSize         += "<option value=\"2\">2</option>";
lblSize         += "<option value=\"3\">3</option>";
lblSize         += "<option value=\"4\">4</option>";
lblSize         += "<option value=\"5\">5</option>";
lblSize         += "<option value=\"6\">6</option>";
lblSize         += "<option value=\"7\">7</option>";

// Alerts
var lblErrorPreload      = "Erreur lors du chargement du contenu.";
var lblSearchConfirm      = "L'expression [SF] a été trouvée [RUNCOUNT] fois.\n\n"; // Leave in [SF], [RUNCOUNT] and [RW]
lblSearchConfirm     += "Êtes-vous sûr de vouloir remplacer ces entrées avec [RW] ?\n";
var lblSearchAbort      = "Operation abandonnée.";
var lblSearchNotFound     = " : l'expression n\'a pas été trouvée.";
var lblCountTotal     = "Nombre de mots";
var lblCountChar     = "Caractères disponibles";
var lblCountCharWarn     = "Attention! Votre contenu est trop long et pourrait ne pas être sauvegardé correctement.";

// Dialogs
// Insert Link
var lblLinkBlank            = "new window (_blank)";
var lblLinkSelf                = "same frame (_self)";
var lblLinkParent              = "parent frame (_parent)";
var lblLinkTop                  = "first frame (_top)";
var lblLinkType        = "Type de lien";
var lblLinkOldA        = "Ancre Existante";
var lblLinkNewA     = "Nouvelle Ancre";
var lblLinkNoA     = "Aucune ancre existante";
var lblLinkAnchors     = "Ancres";
var lblLinkAddress    = "Adresse";
var lblLinkText        = "Texte du lien";
var lblLinkOpenIn    = "Ouvrir le lien dans";
var lblLinkVal0 = "S'il vous plaît, entrez une URL.";
var lblLinkSubmit     = "Valider";
var lblLinkCancel    = "Annuler";
// Insert Image
var lblImageURL        = "URL de l'image";
var lblImageAltText    = "Texte alternatif";
var lblImageBorder     = "Bord";
var lblImageBorderPx     = "Pixels";
var lblImageAlign     = "Align"; 
var lblImageVal0     = "S'il vous plaît, indiquez \"URL de l'image\".";
var lblImageSubmit     = "OK";
var lblImageCancel    = "Annuler";
// Insert Table
var lblTableRows    = "Lignes";
var lblTableColumns    = "Colonnes";
var lblTableWidth     = "Largeur";
var lblTablePx     = "pixels";
var lblTablePercent     = "pourcents";
var lblTableBorder    = "Épaisseur du bord";
var lblTablePadding    = "Espacement interne à la cellule";
var lblTableSpacing    = "Espacement entre cellules";
var lblTableSubmit     = "OK";
var lblTableCancel    = "Annuler";
// Search and Replace
var lblSearchFind    = "Chercher quoi";
var lblSearchReplace     = "Remplacer avec";
var lblSearchMatch = "Respecter la casse";
var lblSearchWholeWord = "Trouver des mots entiers uniquement";
var lblSearchVal0    = "Vous devez entrer quelque chose dans \"Trouver quoi:\".";
var lblSearchSubmit    = "OK";
var lblSearchCancel    = "Annuler";
// Paste As Plain Text
var lblPasteTextHint = "Conseil: Pour coller, vous pouvez soit cliquer sur le bouton droit de la souris et sélectionner \"Coller\" ou utiliser la combinaison de touches Ctrl-V.<br><br>";
var lblPasteTextVal0 = "Veuillez s'il vous plaît entrer votre texte."
var lblPasteTextSubmit = "OK";
var lblPasteTextCancel = "Annuler";
// Paste As Plain Text
var lblPasteWordHint = "Conseil: Pour coller, vous pouvez soit cliquer sur le bouton droit de la souris et sélectionner \"Coller\" ou utiliser la combinaison de touches Ctrl-V.<br><br>";
var lblPasteWordVal0 = "Veuillez s'il vous plaît entrer votre texte."
var lblPasteWordSubmit = "OK";
var lblPasteWordCancel = "Annuler";

// non-designMode
var lblAutoBR    = "Utiliser le retour à la ligne automatique";
var lblRawHTML    = "N\'utiliser que du HTML";
var lblnon_designMode = 'Pour utiliser le Rich Text Editor, un browser tel que <a href="http://www.mozilla.org/" target="_new">Mozilla 1.3+</a> (ex : <a href="http://www.mozilla.org/products/firefox/" target=_new>Firefox</a>), Safari 1.3+, Opera 9+  ou <a href="http://www.microsoft.com/windows/ie/default.asp" target="_new">MS IE5+</a> (Windows) est nécessaire. Les browsers IE5(Mac) ne sont pas supportés pour l\instant et tout le texte doit être en HTML.';
