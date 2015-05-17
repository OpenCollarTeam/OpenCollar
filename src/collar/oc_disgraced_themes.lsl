////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                          Virtual Disgrace - Themes                             //
//                                  version 2.5                                   //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
//               Copyright © 2008 - 2015: Individual Contributors,                //
//            OpenCollar - submission set free™ and Virtual Disgrace™             //
// ------------------------------------------------------------------------------ //
//                       github.com/VirtualDisgrace/Collar                        //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Based on a merge of all OpenCollar appearance plugins by littlemousy
// Virtual Disgrace - Paint is derivate of Virtual Disgrace - Customize
// OpenCollar - styles is derivative of Virtual Disgrace - Paint
// Compatible with OpenCollar API   3.9
// and/or minimum Disgraced Version 1.9.7

list g_lElements;  //list of element types, built on script start.  Changed event restarts script on link set change
list g_lElementFlags;
list g_lTextureDefaults;  //default textures for each element, actually the last textures sent out by the settings script, so not so much "default settings", closer to "what wa set when worn"
list g_lShinyDefaults;
list g_lHideDefaults;
list g_lColourDefaults;

string g_sDeviceType = "collar";

string g_sAuthError = "Access denied.";

list g_lTextures;  //stores names of all textures in collar and notecard
list g_lTextureShortNames;  //stores names of all textures in collar and notecard
list g_lTextureKeys;  //stores keys of notecard textures, and names of textures in collar, indexed by the names in g_lTextures
integer g_iTexturesNotecardLine;  //current number in notecard read
key g_kTextureCardUUID;  //UUID of textures notecard, used to determine when it changed so it can be re-read only when needed
string g_sTextureCard;  //stores name of current textures card.  Might be "textures" or ="textures_custom", set in BuildTexturesList()
key g_kTexturesNotecardRead;  //key of the dataserver request for notecard read

list g_lMenuIDs;  //menu information
integer g_iMenuStride=3;
key g_kTouchID;  //touch request handle

//integer g_iAppLock = FALSE;  //stores whether appearance has been locked, set by monitoring LM_SETTING_SAVE and LM_SETTING_DELETE

//MESSAGE MAP
integer COMMAND_OWNER       =   500;
integer COMMAND_WEARER      =   503;
integer COMMAND_EVERYONE    =   504;

integer LM_SETTING_SAVE     =  2000;  //scripts send messages on this channel to have settings saved to httpdb
integer LM_SETTING_RESPONSE =  2002;  //the httpdb script will send responses on this channel
integer LM_SETTING_DELETE   =  2003;  //delete token from DB

//integer MENUNAME_REQUEST    =  3000;
integer MENUNAME_RESPONSE   =  3001;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

integer TOUCH_REQUEST       = -9500;
//integer TOUCH_CANCEL        = -9501;
integer TOUCH_RESPONSE      = -9502;
//integer TOUCH_EXPIRE        = -9503;

key g_kWearer;

integer ELEMENT_NOTEXTURE   =  1;
integer ELEMENT_NOCOLOR     =  2;
integer ELEMENT_NOSHINY     =  4;
integer ELEMENT_NOGLOW      =  8;
//integer ELEMENT_NOHIDE      = 16;


list g_lColors = [
"Light Shade",<0.82745, 0.82745, 0.82745>,
"Gray Shade",<0.70588, 0.70588, 0.70588>,
"Dark Shade",<0.20784, 0.20784, 0.20784>,
"Brown Shade",<0.65490, 0.58431, 0.53333>,
"Red Shade",<0.66275, 0.52549, 0.52549>,
"Blue Shade",<0.64706, 0.66275, 0.71765>,
"Green Shade",<0.62353, 0.69412, 0.61569>,
"Pink Shade",<0.74510, 0.62745, 0.69020>,
"Gold Shade",<0.69020, 0.61569, 0.43529>,

"Magenta",<1.00000, 0.00000, 0.50196>,
"Pink",<1.00000, 0.14902, 0.50980>,
"Hot Pink",<1.00000, 0.05490, 0.72157>,
"Firefighter",<0.88627, 0.08627, 0.00392>,
"Sun",<1.00000, 1.00000, 0.18039>,
"Flame",<0.92941, 0.43529, 0.00000>,
"Matrix",<0.07843, 1.00000, 0.07843>,
"Electricity",<0.00000, 0.46667, 0.92941>,
"Violet Wand",<0.63922, 0.00000, 0.78824>,

"Baby Blue",<0.75686, 0.75686, 1.00000>,
"Baby Pink",<1.00000, 0.52157, 0.76078>,
"Rose",<0.93333, 0.64314, 0.72941>,
"Beige",<0.86667, 0.78039, 0.71765>,
"Earth",<0.39608, 0.27451, 0.18824>,
"Ocean",<0.25882, 0.33725, 0.52549>,
"Yolk",<0.98824, 0.73333, 0.29412>,
"Wasabi",<0.47059, 1.00000, 0.65098>,
"Lavender",<0.89020, 0.65882, 0.99608>,

"Black",<0.00000, 0.00000, 0.00000>,
"White",<1.00000, 1.00000, 1.00000>
];

list g_lShiny = ["none","low","medium","high"];
list g_lHide = ["Hide","Show"];
list g_lGlows;
list g_lGlow = ["none",0.0,"low",0.1,"medium",0.2,"high",0.4,"veryHigh",0.8];
//list g_lCurrentlyHidden;
integer g_iNumHideableElements;
integer g_iNumElements;
integer g_iCollarHidden;
//string g_sStylesCard="Styles";
string g_sStylesCard=".themes";
key g_kStylesNotecardRead;
key g_kStylesCardUUID;
integer g_iSetStyleAuth;
key g_kSetStyleUser;
string g_sStylesNotecardReadType;
list g_lStyles;
integer g_iStylesNotecardLine;

/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled) {
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];

    //Debug("Made "+sName+" menu.");
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

LooksMenu(key kID, integer iAuth) {
    Dialog(kID, "\nChoose which look you want to change for your "+g_sDeviceType+".", ["Color","Glow","Shiny","Texture"], ["Cancel"],0, iAuth, "LooksMenu~menu");
}

StyleMenu(key kID, integer iAuth) {
    Dialog(kID, "\nChoose a visual theme for your "+g_sDeviceType+".", g_lStyles, ["BACK"], 0, iAuth, "StyleMenu~styles");
}

HideMenu(key kID, integer iAuth, string sElement) {
    Dialog(kID, "\nSelect an action, Show or Hide.", g_lHide, ["BACK"], 0, iAuth, "HideMenu~"+sElement);
}

ShinyMenu(key kID, integer iAuth, string sElement) {
    string sShineElement = llList2String(llParseString2List(sElement,[" "],[]),-1);
    Dialog(kID, "\nSelect a degree of shine for "+sShineElement+".", g_lShiny, ["BACK"], 0, iAuth, "ShinyMenu~"+sElement);
}

GlowMenu(key kID, integer iAuth, string sElement) {
    string sGlowElement = llList2String(llParseString2List(sElement,[" "],[]),-1);
    list lButtons = llList2ListStrided(g_lGlow, 0, -1, 2);
    Dialog(kID, "\nSelect a degree of glow for "+sGlowElement+".", lButtons, ["BACK"], 0, iAuth, "ShinyMenu~"+sElement);
}

TextureMenu(key kID, integer iPage, integer iAuth, string sElement) {
    list lElementTextures;
    integer iCustomTextureFound;
    
    integer iNumTextures=llGetListLength(g_lTextures);
    while (iNumTextures--) {
        string sTextureName=llList2String(g_lTextures,iNumTextures);
        if (! ~llListFindList(lElementTextures,[sTextureName])) {  //we can ignore textures we already know about
            if (llSubStringIndex(sTextureName,sElement+"~")) {  //a texture starting with sElement~ is just for me.  Add it
                lElementTextures+=llList2String(g_lTextureShortNames,iNumTextures);
                if ((!iCustomTextureFound) && llGetListLength(lElementTextures) ) {  //this is the first custom texture we found, we don't want general textures.  Clear thelist and start again
                    iCustomTextureFound=1;
                    lElementTextures=[];
                    iNumTextures=llGetListLength(g_lTextures);
                }
            } else if (~llSubStringIndex(sTextureName,"~") && ! iCustomTextureFound) {  //a texture with no ~ in it is a general texture.  Add it unless we have custom textures
                lElementTextures+=llList2String(g_lTextureShortNames,iNumTextures);
            }
        }
    }
    string sTexElement = llList2String(llParseString2List(sElement,[" "],[]),-1);
    Dialog(kID, "\nSelect a texture to apply to "+sTexElement+".", lElementTextures, ["BACK"], iPage, iAuth, "TextureMenu~"+sElement);
}

/*
ColourCategoryMenu(key kID, integer iPage, integer iAuth, string sElement) {
    Dialog(kID, "\nSelect a color catagory.", g_lColourCategories, ["BACK"], iPage, iAuth, "ColourCategory~"+sElement);
}*/

ColourMenu(key kID, integer iPage, integer iAuth, string sBreadcrumbs) {
    //Debug("ColourMenu: "+sBreadcrumbs);
    string sCategory = llList2String(llParseString2List(sBreadcrumbs,[" "],[]),-1);
    sBreadcrumbs = llDumpList2String(llDeleteSubList(llParseString2List(sBreadcrumbs,[" "],[]),-1,-1)," ");  //remove category name from breadcrumbs, we don't need it once colour is selected
    list lButtons = llList2ListStrided(g_lColors,0,-1,2);
    Dialog(kID, "\nSelect a color for "+sCategory+".", lButtons, ["BACK"], iPage, iAuth, "ColourMenu~"+sBreadcrumbs);
}

ElementMenu(key _kAv, integer _iPage, integer _iAuth, string _sType) {
    integer iMask;
    string sType;
    _sType=llToLower(_sType);
    if (_sType == "texture") {
        iMask=ELEMENT_NOTEXTURE;
        sType = "Texture";
    } else if (_sType == "shiny") {
        iMask=ELEMENT_NOSHINY;
        sType = "Shininess";
    } else if (_sType == "glow") {
        iMask=ELEMENT_NOGLOW;
        sType = "Glow";        
    } else if (_sType == "color") {
        iMask=ELEMENT_NOCOLOR;
        sType = "Color";
    }/* else if (_sType == "hide" || _sType == "show" || _sType == "show/hide" ) {
        iMask=ELEMENT_NOHIDE;
        sType = "Stealth";
    }    */
    string sPrompt = "\nSelect an element of the " + g_sDeviceType + " who's "+sType+" should be changed.\n\nChoose *Touch* if you want to select the part by directly clicking on the " + g_sDeviceType + ".";

    list lButtons;
    integer numElements=g_iNumElements;
    while(numElements--) {
        if ( ~llList2Integer(g_lElementFlags,numElements) & iMask) {  //if the flags fit the mask
            string sElement=llList2String(g_lElements,numElements);
           /* if (sType == "Stealth") {
                if (~llListFindList(g_lCurrentlyHidden,[sElement])) lButtons += "☒ "+sElement;
                else lButtons += "☐ "+sElement;
            } else */lButtons += sElement;
        }
    }
    
   // list lExtraButtons = ["ALL"];
  /*  if (iMask==ELEMENT_NOHIDE) {
        /*do ALL button
        integer iNumCurrentlyHidden=llGetListLength(g_lCurrentlyHidden);
        if (iNumCurrentlyHidden == g_iNumHideableElements) lExtraButtons += "☒ ALL";
        else if (iNumCurrentlyHidden==0) lExtraButtons += "☐ ALL";
        else lExtraButtons += "◪ ALL";
        
        //do g_sDeviceType button
        if (!g_iCollarHidden) lExtraButtons += "☒ "+g_sDeviceType;
        else lExtraButtons += "☐ "+g_sDeviceType;
    } else {
        lExtraButtons += "ALL";
    }*/

    lButtons = llListSort(lButtons, 1, TRUE);
    //Dialog(_kAv, sPrompt, lButtons, lExtraButtons+["*Touch*", "Cancel"], _iPage, _iAuth, "ElementMenu~"+_sType);
    Dialog(_kAv, sPrompt, lButtons, ["ALL", "*Touch*", "BACK"], _iPage, _iAuth, "ElementMenu~"+_sType);
}

string LinkType(integer iLinkNum, string sSearchString) {
    string sDesc = llList2String(llGetLinkPrimitiveParams(iLinkNum, [PRIM_DESC]),0);
    //prim desc will be elementtype~notexture(maybe)
    list lParams = llParseString2List(llStringTrim(sDesc,STRING_TRIM), ["~"], []);
    
    if (~llListFindList(lParams,[sSearchString])) return "immutable";
    else if (sDesc == "" || sDesc == "(No Description)") return "";
    else return llList2String(lParams, 0);
}

BuildStylesList(){
    //Debug("Building styles list");
    if(llGetInventoryType(g_sStylesCard)==INVENTORY_NOTECARD) {
        g_kStylesCardUUID=llGetInventoryKey(g_sStylesCard);
        g_lStyles=[];
        g_iStylesNotecardLine=0;
        g_sStylesNotecardReadType="initialize";
        g_kStylesNotecardRead=llGetNotecardLine(g_sStylesCard,g_iStylesNotecardLine);
    //} else {
        //Debug("No styles card:"+g_sStylesCard);
    }
}

BuildTexturesList(){
    g_lTextures=[];
    g_lTextureKeys=[];
    g_lTextureShortNames=[];
    
    //first add textures in the collar
    integer numInventoryTextures=llGetInventoryNumber(INVENTORY_TEXTURE);
    while (numInventoryTextures--) {
        string sTextureName = llGetInventoryName(INVENTORY_TEXTURE, numInventoryTextures);
        string sShortName=llList2String(llParseString2List(sTextureName, ["~"], []), -1);
        if (!(llGetSubString(sTextureName, 0, 5) == "leash_" || sTextureName == "chain" || sTextureName == "rope")) {  // we want to ignore particle textures, and textures named in the notecard
            if(llStringLength(sShortName)>23) llOwnerSay("Texture name "+sTextureName+" in "+g_sDeviceType+" is too long, dropping.");
            else {
                g_lTextures += sTextureName;
                g_lTextureKeys += sTextureName;  //add name of texture inside collar as the key, to match notecard lists format
                g_lTextureShortNames+=sShortName;
            }
        }
    }

    //after inventory, start reading textures notecard
    g_sTextureCard=".textures";
    if(llGetInventoryType(g_sTextureCard)!=INVENTORY_NOTECARD) g_sTextureCard="textures";
    if(llGetInventoryType(g_sTextureCard)==INVENTORY_NOTECARD) {
        g_iTexturesNotecardLine=0;
        g_kTextureCardUUID=llGetInventoryKey(g_sTextureCard);
        g_kTexturesNotecardRead=llGetNotecardLine(g_sTextureCard,g_iTexturesNotecardLine);
    } else g_kTextureCardUUID=NULL_KEY;
}

BuildElementsList(){
    g_iNumHideableElements=0;
    g_iNumElements=0;
    
    //loop through non-root prims, build element list
    integer iLinkNum = llGetNumberOfPrims()+1;
    while (iLinkNum-- > 2) {  //root prim is 1, so stop at 2
        
        string sElement = llList2String(llGetLinkPrimitiveParams(iLinkNum, [PRIM_DESC]),0);
        if (~llSubStringIndex(llToLower(sElement),"floattext") || ~llSubStringIndex(llToLower(sElement),"leashpoint")) {
             } //do nothing, these are alwasys no-anything
        else if (sElement != "" && sElement != "(No Description)") {  //element has a description, so parse it
            //prim desc will be elementtype~notexture(maybe)
            list lParams = llParseString2List(llStringTrim(sElement,STRING_TRIM), ["~"], []);
            string sElementName=llList2String(lParams,0);
            integer iLinkFlags=0;  //bitmask. 1=notexture, 2=nocolour, 4=noshiny, 8=noglow
            if (~llListFindList(lParams,["notexture"])) iLinkFlags = iLinkFlags | 1;
            if (~llListFindList(lParams,["nocolor"])) iLinkFlags = iLinkFlags | 2;
            if (~llListFindList(lParams,["noshiny"])) iLinkFlags = iLinkFlags | 4;
            if (~llListFindList(lParams,["noglow"])) iLinkFlags = iLinkFlags | 8;
            if (~llListFindList(lParams,["nohide"])) iLinkFlags = iLinkFlags | 16;
            
            integer iElementIndex=llListFindList(g_lElements, [sElementName]);
            if (! ~iElementIndex ) {  //it's a new element, store it, and its flags, and a default texture
                g_lElements += sElementName;
                g_lElementFlags += iLinkFlags;
                if (! (iLinkFlags & 16)) {
                    g_iNumHideableElements++;
                }
                g_iNumElements++;
            } else {  //we already know this element, so "bitwise not" its flags with the new one.  if any element of a type is e.g. texturable, notextures bit should be 0 so it shows in textures menu
                integer iOldFlags=llList2Integer(g_lElementFlags,iElementIndex);
                iLinkFlags = iLinkFlags & iOldFlags;
                g_lElementFlags = llListReplaceList(g_lElementFlags,[iLinkFlags],iElementIndex, iElementIndex);
                if (iLinkFlags & 16 & ~iOldFlags) {
                    g_iNumHideableElements++;
                }
            }
        }
    }
}

UserCommand(integer iNum, string sStr, key kID, integer reMenu) {
    string sStrLower = llToLower(sStr);
    //Debug("UserCOmmandStr: "+sStr);
   // if ( llSubStringIndex(sStrLower,"styles")==0 || sStrLower == "menu styles" || llSubStringIndex(sStrLower,"themes")==0 || sStrLower == "menu themes" || llSubStringIndex(sStrLower,"hide")==0 || llSubStringIndex(sStrLower,"show")==0 || sStrLower == "menu show/hide" || sStrLower == "stealth" ||  llSubStringIndex(sStrLower,"color")==0 || sStrLower == "menu color" || llSubStringIndex(sStrLower,"texture")==0 || sStrLower == "menu texture" || llSubStringIndex(sStrLower,"shiny")==0 || sStrLower == "menu shiny" || llSubStringIndex(sStrLower,"glow")==0 || sStrLower == "menu glow" || sStrLower == "looks") {  //this is for us....
    if ( llSubStringIndex(sStrLower,"styles")==0 || sStrLower == "menu styles" || llSubStringIndex(sStrLower,"themes")==0 || sStrLower == "menu themes" || llSubStringIndex(sStrLower,"hide")==0 || llSubStringIndex(sStrLower,"show")==0 || llSubStringIndex(sStrLower,"stealth")==0 ||  llSubStringIndex(sStrLower,"color")==0 || sStrLower == "menu color" || llSubStringIndex(sStrLower,"texture")==0 || sStrLower == "menu texture" || llSubStringIndex(sStrLower,"shiny")==0 || sStrLower == "menu shiny" || llSubStringIndex(sStrLower,"glow")==0 || sStrLower == "menu glow" || sStrLower == "looks") {  //this is for us....
       /* if (g_iAppLock) {  //no one can do anything when appearrance is locked
            Notify(kID,g_sAuthError, FALSE);
            llMessageLinked(LINK_SET, iNum, "menu " + "Appearance", kID);
        } else */
        if (kID == g_kWearer || iNum == COMMAND_OWNER) {  //only allowed users can...
            list lParams = llParseString2List(sStr, [" "], []);
            string sCommand=llToLower(llList2String(lParams,0));
            //sStr=llGetSubString(llStringLength(sCommand),-1);
            
            string sElement=llList2String(lParams,1);
           /* if (sElement=="☒") {
                sCommand = "show";
                lParams=llDeleteSubList(lParams,1,1);
                sElement=llList2String(lParams,1);
            } else if (sElement=="☐") {
                sCommand = "hide";
                lParams=llDeleteSubList(lParams,1,1);
                sElement=llList2String(lParams,1);                
            }*/
            integer iElementIndex=llListFindList(g_lElements+"ALL"+g_sDeviceType,[sElement]);
            //Debug("Command: "+sCommand+"\nElement: "+sElement);

            //if (sCommand == "styles" || sStrLower == "menu styles") {
            if (sCommand == "themes" || sStrLower == "menu themes" || sCommand == "styles" || sStrLower == "menu styles") {
                if (~llListFindList(g_lStyles,[sElement])) {
                    g_sStylesNotecardReadType=sElement;
                    //Notify(kID,"Setting style:"+sElement,TRUE);
                    g_iStylesNotecardLine=0;
                    g_kSetStyleUser=kID;
                    g_iSetStyleAuth=iNum;
                    g_kStylesNotecardRead=llGetNotecardLine(g_sStylesCard,g_iStylesNotecardLine);
                } else if (g_kStylesCardUUID) {
                    StyleMenu(kID,iNum);
                } else {
                    llMessageLinked(LINK_SET, iNum, "options", kID);
                    Notify(kID,"Unable to find \".themes\" notecard in the " + g_sDeviceType + " contents.", FALSE);
                }
            } else if (sCommand == "looks") LooksMenu(kID,iNum);
            else if (sCommand == "menu") {
                ElementMenu(kID, 0, iNum, sElement);  //if its for us, and its a menu call, then the element parameter is the menu name, honest.
//            } else if (sElement=="" || (! ~iElementIndex) ) {  //no or invalid element name supplied, send element menu
            //} else if ((sElement=="" || (! ~iElementIndex) ) && sCommand != "show" && sCommand != "hide" && sCommand != "stealth" ) {  //no or invalid element name supplied, send element menu
             //  ElementMenu(kID, 0, iNum, sCommand);
            } //else if (sCommand == "hide" || sCommand == "show" || sCommand == "show/hide" || sCommand == "stealth" ) {
            else if (sCommand == "hide" || sCommand == "show" || sCommand == "stealth") {
                //get currently shown state
                integer iCurrentlyShown;
                if (sElement=="") sElement=g_sDeviceType;
                //track which elements are supposed to be hidden
/*                if (sElement=="ALL") {
                    integer iNumCurrentlyHidden=llGetListLength(g_lCurrentlyHidden);
                    if (iNumCurrentlyHidden == g_iNumHideableElements || sCommand=="show") {  //if all hideable elements are hidden
                        g_lCurrentlyHidden=[];  //unhide everything
                        iCurrentlyShown=1;  //not all shown, so show all by setting iCurrentlyShown=1
                    } else {
                        //iCurrentlyShown=0;  //all shown, so now hide by setting iCurrentlyShown=1
                    }
                } else*/ if (sElement == g_sDeviceType) {
                    if (sCommand=="show") {
                        g_iCollarHidden=1;
                    } else if (sCommand=="hide") {
                        g_iCollarHidden=0;
                    } else {
                        g_iCollarHidden = !g_iCollarHidden;  //toggle whole collar visibility
                    }
                    iCurrentlyShown=g_iCollarHidden;  //set visibility flag to match new collar visibility
                }/* else {
                    integer iCurrentlyHiddenIndex = llListFindList(g_lCurrentlyHidden, [sElement]);
                    if (sCommand=="show") {  //showing currently hidden element
                        g_lCurrentlyHidden = llDeleteSubList(g_lCurrentlyHidden,iCurrentlyHiddenIndex,iCurrentlyHiddenIndex);  //remove from shown list
                        iCurrentlyShown = 1;  //iCurrentlyShown now reflects state after this change
                    } else if (sCommand=="hide") {  //showing currently hidden element
                        g_lCurrentlyHidden += [sElement];  //add to shown list
                    } else if (~iCurrentlyHiddenIndex) {  //showing currently hidden element
                        g_lCurrentlyHidden = llDeleteSubList(g_lCurrentlyHidden,iCurrentlyHiddenIndex,iCurrentlyHiddenIndex);  //remove from shown list
                        iCurrentlyShown = 1;  //iCurrentlyShown now reflects state after this change
                    } else {  //hiding currently shown element
                        g_lCurrentlyHidden += [sElement];  //add to shown list
                    }
                }*/
               // llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "hide_" + sElement + "=" + (string)(!iCurrentlyShown), "");
                
                //do the actual hiding and re/de-glowing of elements
                integer iLinkCount = llGetNumberOfPrims()+1;
                while (iLinkCount-- > 1) {
                    string sLinkType=LinkType(iLinkCount, "no"+sCommand);
                   // if (sLinkType == sElement  || (sLinkType != "immutable" && sLinkType != "" && sElement=="ALL") || (sElement==g_sDeviceType) ) {
                    if (sLinkType == sElement || sElement==g_sDeviceType) {
                        if (!g_iCollarHidden || sElement == g_sDeviceType ) {  //don't change things if collar is set hidden, unless we're doing the hiding now
                            llSetLinkAlpha(iLinkCount,(float)(iCurrentlyShown),ALL_SIDES);
                            //update glow settings for this link
                            integer iGlowsIndex = llListFindList(g_lGlows,[iLinkCount]);
                            if (iCurrentlyShown){  //restore glow if it is now shown
                                if (~iGlowsIndex) {  //if it had a glow, restore it, otherwise don't
                                    float fGlow = (float)llList2String(g_lGlows, iGlowsIndex+1);
                                    llSetLinkPrimitiveParamsFast(iLinkCount, [PRIM_GLOW, ALL_SIDES, fGlow]);
                                } else {
                                    llDeleteSubList(g_lGlows,iGlowsIndex,iGlowsIndex);  //remove glow from list
                                }
                                    
                            } else {  //save glow and switch it off if it is now hidden
                                float fGlow = llList2Float(llGetLinkPrimitiveParams(iLinkCount,[PRIM_GLOW,0]),0) ;
                                if (fGlow > 0) {  //if it glows, store glow
                                    if (~iGlowsIndex) g_lGlows = llListReplaceList(g_lGlows,[fGlow],iGlowsIndex+1,iGlowsIndex+1) ;            
                                    else g_lGlows += [iLinkCount, fGlow];            
                                }
                                llSetLinkPrimitiveParamsFast(iLinkCount, [PRIM_GLOW, ALL_SIDES, 0.0]);  // set no glow;
                            }
                           // if (sElement=="ALL" && !iCurrentlyShown){
                            //    if (! ~llListFindList(g_lCurrentlyHidden, [sLinkType])) g_lCurrentlyHidden+=sLinkType;
                           // }
                        }
                    }
                }
            } else if (sCommand == "shiny") {
                string sShiny=llList2String(lParams,2);
                integer iShinyIndex=llListFindList(g_lShiny,[sShiny]);
                if (~iShinyIndex) sShiny=(string)iShinyIndex;  //if found, convert string to index and overwrite supplied string
                integer iShiny=(integer)sShiny;  //cast string to integer, we now have the index, or 0 for a bad value
                
                if (sShiny=="") {  //got no value for shiny, make shiny menu
                    ShinyMenu(kID, iNum, sStr);
                } else if (iShiny || sShiny=="0") {  //if we have a value, or if 0 was passed in as a string value
                    integer iLinkCount = llGetNumberOfPrims()+1;
                    while (iLinkCount-- > 2) {
                        string sLinkType=LinkType(iLinkCount, "no"+sCommand);
                        if (sLinkType == sElement || (sLinkType != "immutable" && sLinkType != "" && sElement=="ALL")) {
                            //Debug("Setting shiny for link "+(string)iLinkCount+" to "+(string)iShiny);
                            llSetLinkPrimitiveParamsFast(iLinkCount,[PRIM_BUMP_SHINY,ALL_SIDES,iShiny,0]);  //change "notexture" to "noshiny" if your g_sDeviceType supports it
                        }
                    }
                    //save to settings DB
                    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "shininess_" + sElement + "=" + (string)iShiny, "");
                    if (reMenu) ShinyMenu(kID, iNum, "shiny "+sElement);
                }
            }
            else if (sCommand == "glow") {
                string sGlow=llList2String(lParams,2);
                integer iGlowIndex=llListFindList(g_lGlow,[sGlow]);
                if (~iGlowIndex) sGlow=(string)llList2String(g_lGlow,iGlowIndex+1);  //if found, convert string to index and overwrite supplied string
                float fGlow = llList2Float(g_lGlow,iGlowIndex+1);   //cast string to float, we now have the index, or 0 for a bad value
                if (sGlow=="") {  //got no value for glow, make glow menu
                    GlowMenu(kID, iNum, sStr);
                } else if ((fGlow >= 0.0 && fGlow <= 1.0)|| sGlow=="0") {  //if we have a value, or if 0 was passed in as a string value
                    integer iLinkCount = llGetNumberOfPrims()+1;
                    while (iLinkCount-- > 2) {
                        string sLinkType=LinkType(iLinkCount, "no"+sCommand);
                        if (sLinkType == sElement || (sLinkType != "immutable" && sLinkType != "" && sElement=="ALL")) {
                           //Debug("Setting Glow for link "+(string)iLinkCount+" to "+(string)fGlow);
                            
                            llSetLinkPrimitiveParamsFast(iLinkCount,[PRIM_GLOW,ALL_SIDES,fGlow]);  //change "notexture" to "noGlow" if your g_sDeviceType supports it
                        }
                    }
                    //save to settings DB
                    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "glow_" + sElement + "=" + (string)fGlow, "");
                    if (reMenu) GlowMenu(kID, iNum, "glow "+sElement);
                }
            } else if (sCommand == "color") {
                //Debug("Colour command:"+sStr);
                string sColour=llDumpList2String(llDeleteSubList(lParams,0,1)," ");

                integer iColourIndex=llListFindList(llList2ListStrided(g_lColors,0,-1,2),[sColour]);
                vector vColourValue=(vector)sColour;
                if (~iColourIndex) vColourValue=llList2Vector(llList2ListStrided(llDeleteSubList(g_lColors,0,0),0,-1,2),iColourIndex);
                
               /*if (~llListFindList(g_lColourCategories,[sColour])) {  //got a category name.  Do menu for that category
                    ColourMenu(kID, 0, iNum, sStr);
                } else */
                if (vColourValue != ZERO_VECTOR || llToLower(sColour)=="black"){  //we have command, element and valid colour name
                    integer iLinkCount = llGetNumberOfPrims()+1;
                    while (iLinkCount-- > 2) {
                        string sLinkType=LinkType(iLinkCount, "nocolor");
                        if (sLinkType == sElement || (sLinkType != "immutable" && sLinkType != "" && sElement=="ALL")) {
                            llSetLinkColor(iLinkCount, vColourValue, ALL_SIDES);  //set link to new color
                        }
                    }
                    //save to settings
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "color_"+sElement+"="+(string)vColourValue, "");
                    if (reMenu) ColourMenu(kID, 0, iNum, sCommand+" "+sElement);
                } else if (! ~iColourIndex) {  //not category, not a colour either. Send category menu
                    ColourMenu(kID, 0, iNum, sCommand+" "+sElement);
                }
            } else if (sCommand=="texture") {
                //Debug("Texture command:"+sStr);
                //swap "Default" for the name of the default texture
                string sTextureShortName=llDumpList2String(llDeleteSubList(lParams,0,1)," ");
                if (sTextureShortName=="Default") {  //if we have one, set the default texture for this element type, else error and give texture menu
                    integer iDefaultTextureIndex = llListFindList(g_lTextureDefaults, [sElement]);
                    if (~iDefaultTextureIndex) sTextureShortName=llList2String(g_lTextureDefaults, iDefaultTextureIndex + 1);
                }
                    
                //get long name from short name
                integer iTextureIndex=llListFindList(g_lTextures,[sElement+"~"+sTextureShortName]);  //first try to get index of custom texture
                if ((key)sTextureShortName) iTextureIndex=0;  //we have been given a key, so pretend we found it in the list
                else if (! ~iTextureIndex) {
                    iTextureIndex=llListFindList(g_lTextures,[sTextureShortName]);  //else get index of regular texture
                }
                    
                if (sTextureShortName=="") {  //no texture name supplied, send texture menu for this element
                    TextureMenu(kID, 0, iNum, sStr);
                } else if (! ~iTextureIndex) {  //invalid texture name supplied, send texture menu for this element
                    Notify(kID,"No texture "+sTextureShortName+" found, please choose one from the menu.", FALSE);
                    TextureMenu(kID, 0, iNum, sCommand+" "+sElement);
                } else {  //valid element and texture names supplied, apply texture
                    //get key from long name
                    //Debug("Texture command is good:"+sStr);
                    
                    string sTextureKey;
                    if ((key)sTextureShortName) sTextureKey=sTextureShortName;
                    else sTextureKey=llList2String(g_lTextureKeys,iTextureIndex);
                    
                    //Debug("Key for "+sTextureShortName+" is "+sTextureKey);
                    //loop through prims and apply texture key
                    integer iLinkCount = llGetNumberOfPrims()+1;
                    while (iLinkCount-- > 2) {
                        string sLinkType=LinkType(iLinkCount, "notexture");
                        if (sLinkType == sElement || (sLinkType != "immutable" && sLinkType != "" && sElement=="ALL")) {
                            //Debug("Applying texture to element number "+(string)iLinkCount);
                            // update prim texture for each face with save texture repeats, offsets and rotations
                            integer iSides = llGetLinkNumberOfSides(iLinkCount);
                            integer iFace ;
                            for (iFace = 0; iFace < iSides; iFace++) {
                                list lParams = llGetLinkPrimitiveParams(iLinkCount, [PRIM_TEXTURE, iFace ]);
                                lParams = llDeleteSubList(lParams,0,0); // get texture params
                                llSetLinkPrimitiveParamsFast(iLinkCount, [PRIM_TEXTURE, iFace, sTextureKey]+lParams);
                            }
                        //} else {
                            //Debug("Not applying texture to element number "+(string)iLinkCount);
                        }
                    }

                    //save to settings
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "texture_" + sElement + "=" + sTextureShortName, "");
                    
                    if (reMenu) TextureMenu(kID, 0, iNum, sCommand+" "+sElement);
                }
            }
        } else {  //anyone else gets an error
            Notify(kID,g_sAuthError, FALSE);
            llMessageLinked(LINK_SET, iNum, "menu " + "options", kID);
        }
    }
}

default {
/*
    on_rez(integer arg){
        if (g_iProfiled) {
            llScriptProfiler(1);
            Debug("profiling restarted");
        }
    }
*/
      
    state_entry() {
        //llSetMemoryLimit(65536);  //2015-05-06 (10732 bytes free)
        g_kWearer = llGetOwner();
        BuildTexturesList();
        BuildElementsList();
        BuildStylesList();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_EVERYONE) UserCommand(iNum, sStr, kID, FALSE);
       /* else if (iNum == MENUNAME_REQUEST && sStr == "Appearance") {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Appearance|Texture", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Appearance|Color", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Appearance|Shiny", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Appearance|Show/Hide", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Appearance|Styles", "");
        } */
       // else if (iNum == LM_SETTING_SAVE && llSubStringIndex(sStr,"Appearance_Lock")==0) g_iAppLock=TRUE;
       // else if (iNum == LM_SETTING_DELETE && sStr=="Appearance_Lock") g_iAppLock=FALSE;
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sID = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sID, "_");
            string sCategory=llGetSubString(sID, 0, i);
            string sToken = llGetSubString(sID, i + 1, -1);
           // if (sID == "Appearance_Lock") g_iAppLock = (integer)sValue;
            //else 
            if (sID == "Global_DeviceType") g_sDeviceType = sValue;
            else if (sCategory == "texture_") {  //add any recieved textures as defaults. Default here means whatever was current last time settings spoke.
                i = llListFindList(g_lTextureDefaults, [sToken]);
                if (~i) g_lTextureDefaults = llListReplaceList(g_lTextureDefaults, [sValue], i + 1, i + 1);
                else g_lTextureDefaults += [sToken, sValue];
            }
            else if (sCategory == "shininess_") {  //add any recieved shiny as defaults. Default here means whatever was current last time settings spoke.
                i = llListFindList(g_lShinyDefaults, [sToken]);
                if (~i) g_lShinyDefaults = llListReplaceList(g_lShinyDefaults, [sValue], i + 1, i + 1);
                else g_lShinyDefaults += [sToken, sValue];
            }
            else if (sCategory == "hide_") {  //add any recieved hide as defaults. Default here means whatever was current last time settings spoke.
                i = llListFindList(g_lHideDefaults, [sToken]);
                if (~i) g_lHideDefaults = llListReplaceList(g_lHideDefaults, [sValue], i + 1, i + 1);
                else g_lHideDefaults += [sToken, sValue];
            }
            else if (sCategory == "color_") {  //add any received colour as defaults. Default here means whatever was current last time settings spoke.
                i = llListFindList(g_lColourDefaults, [sToken]);
                if (~i) g_lColourDefaults = llListReplaceList(g_lColourDefaults, [sValue], i + 1, i + 1);
                else g_lColourDefaults += [sToken, sValue];
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {  //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                if (sMessage == "Cancel") return;
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                 //remove stride from g_lMenuIDs.  We have to subtract from the index because the dialog id comes in the middle of the stride
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                list lMenuPath = llParseString2List(sMenu,[" "],[]);
                //Debug("Got response from menu: "+sMenu);
                
                if (llSubStringIndex(sMenu,"ElementMenu~")==0) {  //they just chose an element (or chose to touch to select one) , now choose a texture
                    if (sMessage == "BACK") LooksMenu(kAv, iAuth);//llMessageLinked(LINK_SET, iAuth, "options", kAv);//llMessageLinked(LINK_SET, iAuth, "menu Appearance", kAv);  //main menu
                    else {
                        string sMenuType=llList2String(llParseString2List(sMenu,["~"],[]),1);
                        if (sMessage == "*Touch*") {
                            Notify(kAv, "Please touch the part of the " + g_sDeviceType + " you want to change. Press ctr+alt+T to see invisible parts.", FALSE);
                            key kTouchID = llGenerateKey();
                            llMessageLinked(LINK_SET, TOUCH_REQUEST, (string)kAv + "|3|" + (string)iAuth, kTouchID);  //3 = touchStart and touchEnd
                            
                            integer iIndex = llListFindList(g_lMenuIDs, [kID]);
                            if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kTouchID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
                            else g_lMenuIDs += [kID, kTouchID, sMenuType];
                        } else {
                            //Debug("Doing usercommand:"+sMenuType+" "+sMessage);
                            UserCommand(iAuth, sMenuType+" "+sMessage, kAv, TRUE);
                        }
                    }
                } else {  //rest of menu responses are all pretty formulaic really, just pass the breadcrumbs in to UserCommand along with the next argument
                    string sBreadcrumbs=llList2String(llParseString2List(sMenu,["~"],[]),1);
                    string sBackMenu=llList2String(llParseString2List(sBreadcrumbs,[" "],[]),0);
                    //Debug(sBreadcrumbs+" "+sMessage);
                    if (sMessage == "BACK") {
                        if (~llSubStringIndex(sMenu,"StyleMenu~styles")) llMessageLinked(LINK_SET, iAuth, "options", kAv);
                        else  ElementMenu(kAv, 0, iAuth, sBackMenu);
                    }
                    //if (sMessage == "BACK")  llMessageLinked(LINK_SET, iAuth, "options", kAv);
                    else UserCommand(iAuth,sBreadcrumbs+" "+sMessage, kAv, TRUE);
                }
            }
        } else if (iNum == TOUCH_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);  //we hid the touch request in the menu details... naughty!!
            if (iMenuIndex != -1) {  //got a response meant for us.  pull out values
                list lParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lParams, 0);
                integer iAuth = (integer)llList2String(lParams, 1);
                integer iLinkNumber = (integer)llList2String(lParams, 3);

                 //remove stride from g_lMenuIDs.  We have to subtract from the index because the dialog id comes in the middle of the stride
                string sTouchType=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                
                string sElement = LinkType(iLinkNumber, "no"+sTouchType);
                
                if (sElement == "immutable") {
                    Notify(kAv, "You can't change the "+sTouchType+" of the part you selected. You can try again.", FALSE);
                    //Debug("calling usercommand with: "+sTouchType);
                    UserCommand(iAuth, sTouchType, kAv, TRUE);
                } else {
                    //Debug("calling usercommand with: "+sTouchType+" "+sElement);
                    UserCommand(iAuth, sTouchType+" "+sElement, kAv, TRUE);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
    }
    
    dataserver(key kID, string sData) {
        if (kID==g_kTexturesNotecardRead) {
            if(sData!=EOF) {
                if(llStringTrim(sData,STRING_TRIM)!="" && llGetSubString(sData,0,1)!="//") {
                    list lThisLine=llParseString2List(sData,[","],[]);
                    key kTextureKey=(key)llStringTrim(llList2String(lThisLine,1),STRING_TRIM);
                    string sTextureName=llStringTrim(llList2String(lThisLine,0),STRING_TRIM);
                    string sShortName=llList2String(llParseString2List(sTextureName, ["~"], []), -1);
                    if ( ~llListFindList(g_lTextures,[sTextureName])) llOwnerSay("Texture "+sTextureName+" is in the collar AND the notecard.  Collar texture takes priority.");
                    else if((key)kTextureKey) {  //if the notecard has valid key, and texture is not already in collar
                        if(llStringLength(sShortName)>23) llOwnerSay("Texture "+sTextureName+" in textures notecard too long, dropping.");
                        else {
                            g_lTextures+=sTextureName;
                            g_lTextureKeys+=kTextureKey;
                            g_lTextureShortNames+=sShortName;
                        }
                    } else llOwnerSay("Texture key for "+sTextureName+" in textures notecard not recognised, dropping.");
                }
                g_kTexturesNotecardRead=llGetNotecardLine(g_sTextureCard,++g_iTexturesNotecardLine);
            }
        } else if (kID==g_kStylesNotecardRead) {
            if(sData!=EOF) {
                sData=llStringTrim(sData,STRING_TRIM);
                if(sData!="" && llSubStringIndex(sData,"#") != 0) {
                    if( llGetSubString(sData,0,0) == "[" ){
                        //Debug("("+g_sStylesNotecardReadType+")[good line]:"+sData);
                        sData = llGetSubString(sData,llSubStringIndex(sData,"[")+1,llSubStringIndex(sData,"]")-1);
                        sData = llStringTrim(sData,STRING_TRIM);
                        if (g_sStylesNotecardReadType=="initialize") {  //reading notecard to determine style names
                            g_lStyles += sData;
                        } else if (sData==g_sStylesNotecardReadType) {  //we just found our section
                            g_sStylesNotecardReadType="processing";
                        } else if (g_sStylesNotecardReadType=="processing") {  //we just found the start of the next section, we're done
                            Notify(g_kSetStyleUser, "Theme applied!", FALSE);
                            UserCommand(g_iSetStyleAuth,"styles",g_kSetStyleUser,TRUE);
                            return;
                        }
                        g_kStylesNotecardRead=llGetNotecardLine(g_sStylesCard,++g_iStylesNotecardLine);
                    } else {
                        if (g_sStylesNotecardReadType=="processing"){
                            //Debug("[good line]:"+sData);
                            //do what the notecard says
                            list lParams = llParseStringKeepNulls(sData,["~"],[]);
                            string element = llStringTrim(llList2String(lParams,0),STRING_TRIM);
                            if (element != "")
                            {
                                sData = llStringTrim(llList2String(lParams,1),STRING_TRIM);
                                if (sData != "") UserCommand(g_iSetStyleAuth, "texture " + element+" "+sData, g_kSetStyleUser, FALSE);
                                sData = llStringTrim(llList2String(lParams,2),STRING_TRIM);
                                if (sData != "") UserCommand(g_iSetStyleAuth, "color " + element+" "+sData, g_kSetStyleUser, FALSE);
                                sData = llStringTrim(llList2String(lParams,3),STRING_TRIM);
                                if (sData != "") UserCommand(g_iSetStyleAuth, "shiny " + element+" "+sData, g_kSetStyleUser, FALSE);
                            }
                        }
                        g_kStylesNotecardRead=llGetNotecardLine(g_sStylesCard,++g_iStylesNotecardLine);
                    }
                } else g_kStylesNotecardRead=llGetNotecardLine(g_sStylesCard,++g_iStylesNotecardLine);
            } else {
                if (g_sStylesNotecardReadType=="processing") {  //we just found the end of file, we're done
                    Notify(g_kSetStyleUser, "Theme applied!", FALSE);
                    UserCommand(g_iSetStyleAuth,"styles",g_kSetStyleUser,TRUE);
                //} else {
                    //Debug(llDumpList2String(g_lStyles,","));
                }
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_LINK) BuildElementsList();
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryType(g_sTextureCard)==INVENTORY_NOTECARD && llGetInventoryKey(g_sTextureCard)!=g_kTextureCardUUID) BuildTexturesList();
            if (llGetInventoryType(g_sStylesCard)==INVENTORY_NOTECARD && llGetInventoryKey(g_sStylesCard)!=g_kStylesCardUUID) BuildStylesList();
        }
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
