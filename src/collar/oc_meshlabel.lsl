////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - meshlabel                              //
//                                 version 3.995                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string g_sParentMenu = "Apps";
string g_sSubMenu = "Label";

key g_kWearer;


//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510; 
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;


integer NOTIFY=1002;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer g_iCharLimit = -1;

string UPMENU = "BACK";

string g_sTextMenu = "Set Label";
string g_sFontMenu = "Font";
string g_sColorMenu = "Color";

key g_kDialogID;
key g_kTBoxID;
key g_kFontID;
key g_kColorID;

string g_sCharmap = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſƒƠơƯưǰǺǻǼǽǾǿȘșʼˆˇˉ˘˙˚˛˜˝˳̣̀́̃̉̏΄΅Ά·ΈΉΊΌΎΏΐΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫάέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώϑϒϖЀЁЂЃЄЅІЇЈЉЊЋЌЍЎЏАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяѐёђѓєѕіїјљњћќѝўџѠѡѢѣѤѥѦѧѨѩѪѫѬѭѮѯѰѱѲѳѴѵѶѷѸѹѺѻѼѽѾѿҀҁ҂҃҄҅҆҈҉ҊҋҌҍҎҏҐґҒғҔҕҖҗҘҙҚқҜҝҞҟҠҡҢңҤҥҦҧҨҩҪҫҬҭҮүҰұҲҳҴҵҶҷҸҹҺһҼҽҾҿӀӁӂӃӄӅӆӇӈӉӊӋӌӍӎӏӐӑӒӓӔӕӖӗӘәӚӛӜӝӞӟӠӡӢӣӤӥӦӧӨөӪӫӬӭӮӯӰӱӲӳӴӵӶӷӸӹӺӻӼӽӾӿԀԁԂԃԄԅԆԇԈԉԊԋԌԍԎԏԐԑԒԓḀḁḾḿẀẁẂẃẄẅẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹὍ–—―‗‘’‚‛“”„†‡•…‰′″‹›‼⁄ⁿ₣₤₧₫€℅ℓ№™Ω℮⅛⅜⅝⅞∂∆∏∑−√∞∫≈≠≤≥◊ﬁﬂﬃﬄ￼ ";

list g_lFonts = [
    "Solid", "91b730bc-b763-52d4-d091-260eddda3198", 
    "Outlined", "d7b5b96c-7ff8-405f-f970-fd97f489caae"
    ];

key g_kFontTexture = "d7b5b96c-7ff8-405f-f970-fd97f489caae";

integer x = 45;
integer y = 19;

integer faces = 6;

float g_fScrollTime = 0.3 ;
integer g_iSctollPos ;
string g_sScrollText;
list g_lLabelLinks ;

integer g_iScroll = FALSE;
integer g_iShow = TRUE;
vector g_vColor = <1,1,1>;

string g_sLabelText = "";
string g_sSettingToken = "label_";
//string g_sGlobalToken = "global_";

float Ureps;
float Vreps;

/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")|"+(string)llGetFreeMemory()+") :\n" + sStr);
}
*/

integer GetIndex(string sChar) {
    integer i;
    if (sChar == "") return 854;
    else i = llSubStringIndex(g_sCharmap, sChar);
    if (i>=0) return i;
    else return 854;
}

RenderString(integer iPos, string sChar) {  // iPos - позиция символа на лейбле
    integer frame = GetIndex(sChar);  //номер символа в таблице
    integer i = iPos/faces;
    integer link = llList2Integer(g_lLabelLinks,i);    
    integer face = iPos - faces * i;        
    integer frameY = frame / x;
    integer frameX = frame - x * frameY;
    float Uoffset = -0.5 + (Ureps/2 + Ureps*(frameX)) ;
    float Voffset = 0.5 - (Vreps/2 + Vreps*(frameY)) ;            
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, face, g_kFontTexture, <Ureps, Vreps,0>, <Uoffset, Voffset, 0>, 0]);
}

SetColor() {
    integer i=0;
    do {
        integer link = llList2Integer(g_lLabelLinks,i);
        float alpha = llList2Float(llGetLinkPrimitiveParams( link,[PRIM_COLOR,ALL_SIDES]),1);  
        llSetLinkPrimitiveParamsFast(link, [PRIM_COLOR, ALL_SIDES, g_vColor, alpha]);    
    } while (i++ < llGetListLength(g_lLabelLinks));
}

// find all 'Label' prims, count and store it's link numbers for fast work SetLabel() and timer
integer LabelsCount() {
    integer ok = TRUE ;
    g_lLabelLinks = [] ;

    string sLabel;
    list lTmp;
    integer iLink;
    integer iLinkCount = llGetNumberOfPrims();
    //find all 'Label' prims and count it's
    for(iLink=2; iLink <= iLinkCount; iLink++) {
        lTmp = llParseString2List(llList2String(llGetLinkPrimitiveParams(iLink,[PRIM_NAME]),0), ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if(sLabel == "MeshLabel") {
            g_lLabelLinks += [0]; // fill list witn nulls
            //change prim description
            llSetLinkPrimitiveParamsFast(iLink,[PRIM_DESC,"Label~notexture~nocolor~nohide"]);
        }
    }
    g_iCharLimit = llGetListLength(g_lLabelLinks) * 6;
    //find all 'Label' prims and store it's links to list
    for(iLink=2; iLink <= iLinkCount; iLink++) {
        lTmp = llParseString2List(llList2String(llGetLinkPrimitiveParams(iLink,[PRIM_NAME]),0), ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if (sLabel == "MeshLabel") {
            integer iLabel = (integer)llList2String(lTmp,1);
            integer link = llList2Integer(g_lLabelLinks,iLabel);
            if (link == 0)
                g_lLabelLinks = llListReplaceList(g_lLabelLinks,[iLink],iLabel,iLabel);
            else {
                ok = FALSE;
                llOwnerSay("Warning! Found duplicated label prims: "+sLabel+" with link numbers: "+(string)link+" and "+(string)iLink);
            }
        }
    }
    return ok;
}

SetLabel() {
    string sText ;
    if (g_iShow) sText = g_sLabelText;
    
    string sPadding;
    if(g_iScroll==TRUE) {
        while(llStringLength(sPadding) < g_iCharLimit) sPadding += " ";
        g_sScrollText = sPadding + sText;
        llSetTimerEvent(g_fScrollTime);
    } else {
        g_sScrollText = "";
        llSetTimerEvent(0);
        //inlined single use CenterJustify function
        while(llStringLength(sPadding + sText + sPadding) < g_iCharLimit) sPadding += " ";
        string sText = sPadding + sText;
        integer iCharPosition;
        for(iCharPosition=0; iCharPosition < g_iCharLimit; iCharPosition++)
            RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition));
    }
    //Debug("Label Set");
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

MainMenu(key kID, integer iAuth) {
    list lButtons= [g_sTextMenu, g_sColorMenu, g_sFontMenu];
    if (g_iShow) lButtons += ["☒ Show"];
    else lButtons += ["☐ Show"];
    
    if (g_iScroll) lButtons += ["☒ Scroll"];
    else lButtons += ["☐ Scroll"];    
        
    string sPrompt = "\nCustomize the %DEVICETYPE%'s label!\n\nwww.opencollar.at/label";
    g_kDialogID=Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

TextMenu(key kID, integer iAuth) {
    string sPrompt="\n- Submit the new label in the field below.\n- Submit a few spaces to clear the label.\n- Submit a blank field to go back to " + g_sSubMenu + ".\n\nwww.opencollar.at/label";
    g_kTBoxID = Dialog(kID, sPrompt, [], [], 0, iAuth);
}

ColorMenu(key kID, integer iAuth) {
    string sPrompt = "\n\nSelect a color from the list";
    g_kColorID=Dialog(kID, sPrompt, ["colormenu please"], [UPMENU], 0, iAuth);
}

FontMenu(key kID, integer iAuth) {
    list lButtons=llList2ListStrided(g_lFonts,0,-1,2);
    string sPrompt = "\nSelect the font for the %DEVICETYPE%'s label.\n\nNOTE: This feature requires a design with label prims. If the worn design doesn't have any of those, it is recommended to uninstall Label with the updater.\n\nwww.opencollar.at/label";

    g_kFontID=Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}


UserCommand(integer iAuth, string sStr, key kAv) {
    //Debug("Command: "+sStr);
    if (iAuth == CMD_OWNER) {
        if (sStr == "menu " + g_sSubMenu || llToLower(sStr)=="label") {
            MainMenu(kAv, iAuth);
            return;
        }        
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llToLower(llList2String(lParams, 0));
        if (sCommand == "labeltext") {
            lParams = llDeleteSubList(lParams, 0, 0);
            g_sLabelText = llStringTrim(llDumpList2String(lParams, " "),STRING_TRIM);            
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "text=" + g_sLabelText, "");
            if (llStringLength(g_sLabelText) > g_iCharLimit) {
                string sDisplayText = llGetSubString(g_sLabelText, 0, g_iCharLimit-1);
                llMessageLinked(LINK_SET, NOTIFY, "0"+"Unless your set your label to scroll it will be truncted at "+sDisplayText+".", kAv);
            }
            SetLabel();          
        } else if (sCommand == "labelfont") {
            lParams = llDeleteSubList(lParams, 0, 0);
            string font = llDumpList2String(lParams, " ");
            integer iIndex = llListFindList(g_lFonts, [font]);
            if (iIndex != -1) {                
                g_kFontTexture = (key)llList2String(g_lFonts, iIndex + 1);
                SetLabel();
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "font=" + (string)g_kFontTexture, "");
            } else FontMenu(kAv, iAuth);            
        } else if (sCommand == "labelcolor") {
            string sColor= llDumpList2String(llDeleteSubList(lParams,0,0)," ");
            if (sColor != "") {
                g_vColor=(vector)sColor;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"color="+(string)g_vColor, "");
                SetColor();
            } 
        } else if (sCommand == "labelshow") {
            g_iShow = llList2Integer(lParams, 1);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"show="+(string)g_iShow, "");
            SetLabel();            
        } else if (sCommand == "labelscroll") {
            g_iScroll = llList2Integer(lParams, 1);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"scroll="+(string)g_iScroll, "");
            SetLabel();            
        }        
    } else if (iAuth >= CMD_TRUSTED && iAuth <= CMD_WEARER) {
        string sCommand = llToLower(llList2String(llParseString2List(sStr, [" "], []), 0));        
        if (sStr=="menu "+g_sSubMenu) {
            llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
        } else if (sCommand=="labeltext" || sCommand == "labelfont" || sCommand == "labelcolor" || sCommand == "labelshow")
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
    }
}

default
{
    state_entry() {
        llSetMemoryLimit(45056);
        g_kWearer = llGetOwner();
        Ureps = (float)1 / x;
        Vreps = (float)1 / y;
        LabelsCount();
        if (g_iCharLimit <= 0) {
            llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
            llRemoveInventory(llGetScriptName());
        }
        g_sLabelText = llList2String(llParseString2List(llKey2Name(llGetOwner()), [" "], []), 0);
        //SetLabel();
    }

    on_rez(integer iNum) {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "text") g_sLabelText = sValue;
                else if (sToken == "font") g_kFontTexture = (key)sValue;
                else if (sToken == "color") g_vColor = (vector)sValue;
                else if (sToken == "show") g_iShow = (integer)sValue;
                else if (sToken == "scroll") g_iScroll = (integer)sValue;                
            } else if (sToken == "settings" && sValue == "sent") {
                SetColor();
                SetLabel();
            }                
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == DIALOG_RESPONSE) {
            if (kID==g_kDialogID) {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                else if (sMessage == g_sTextMenu) TextMenu(kAv, iAuth);
                else if (sMessage == g_sColorMenu) ColorMenu(kAv, iAuth);
                else if (sMessage == g_sFontMenu) FontMenu(kAv, iAuth);
                else if (sMessage == "☐ Show") {
                    UserCommand(iAuth, "labelshow 1", kAv);
                    MainMenu(kAv, iAuth);
                } else if (sMessage == "☒ Show") {
                    UserCommand(iAuth, "labelshow 0", kAv);
                    MainMenu(kAv, iAuth);
                } else if (sMessage == "☐ Scroll") {
                    UserCommand(iAuth, "labelscroll 1", kAv);
                    MainMenu(kAv, iAuth);
                } else if (sMessage == "☒ Scroll") {
                    UserCommand(iAuth, "labelscroll 0", kAv);
                    MainMenu(kAv, iAuth);
                }
            } else if (kID == g_kColorID) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                else {
                    UserCommand(iAuth, "labelcolor "+sMessage, kAv);
                    ColorMenu(kAv, iAuth);
                }
            } else if (kID == g_kFontID) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                else {
                    UserCommand(iAuth, "labelfont " + sMessage, kAv);
                    FontMenu(kAv, iAuth);
                }
            } else if (kID == g_kTBoxID) { // TextBox response, extract values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage != "") UserCommand(iAuth, "labeltext " + sMessage, kAv);
                llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sSubMenu, kAv);
            }
        }
    }

    timer() {
        string sText = llGetSubString(g_sScrollText, g_iSctollPos, -1);
        integer iCharPosition;
        for(iCharPosition=0; iCharPosition < g_iCharLimit; iCharPosition++)
            RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition));
        g_iSctollPos++;
        if(g_iSctollPos > llStringLength(g_sScrollText)) g_iSctollPos = 0 ;
    }

    changed(integer iChange) {
        if(iChange & CHANGED_LINK) // if links changed
            if (LabelsCount()==TRUE) SetLabel();
/*        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }
}
