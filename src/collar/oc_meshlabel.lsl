// This file is part of OpenCollar.
// Copyright (c) 2006 - 2016 Xylor Baysklef, Kermitt Quirk,        
// Thraxis Epsilon, Gigs Taggart, Strife Onizuka, Huney Jewell,      
// Salahzar Stenvaag, Lulu Pink, Nandana Singh, Cleo Collins, Satomi Ahn, 
// Joy Stipe, Wendy Starfall, Romka Swallowtail, littlemousy,       
// Garvin Twine et al.   
// Licensed under the GPLv2.  See LICENSE for full details. 

// How to use:
// 
// - You need a Mesh-Strip with 6 Faces next to each other. Each Face should have 1 Material.
// - Link the Strips together next to each other. 
// - Name them like this: MeshLabel~number~line
//      number is the mesh-number from 0 to how many you linked horizontally   
//      line is the vertical number from 0 to how many lines you have
//
//  Example:
//          ***************** ***************** *****************
//          * MeshLabel~0~0 * * MeshLabel~1~0 * * MeshLabel~2~0 *
//          ***************** ***************** *****************
//
//          ***************** ***************** *****************
//          * MeshLabel~0~1 * * MeshLabel~1~1 * * MeshLabel~2~1 *
//          ***************** ***************** *****************

string g_sAppVersion = "1.1";
string g_sScriptVersion = "7.4";

string g_sParentMenu = "Apps";
string g_sSubMenu = "Label";
integer LINK_CMD_DEBUG = 1999;
key g_kWearer;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;
integer REBOOT              = -1000;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

list g_lCharLimit = [];

string UPMENU = "BACK";

string g_sTextMenu = "Set Line ";
string g_sFontMenu = "Font";
string g_sColorMenu = "Color";

list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

integer g_bHasError = FALSE;
string g_sErrorMsg = "";

string g_sCharmap = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſƒƠơƯưǰǺǻǼǽǾǿȘșʼˆˇˉ˘˙˚˛˜˝˳̣̀́̃̉̏΄΅Ά·ΈΉΊΌΎΏΐΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫάέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώϑϒϖЀЁЂЃЄЅІЇЈЉЊЋЌЍЎЏАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяѐёђѓєѕіїјљњћќѝўџѠѡѢѣѤѥѦѧѨѩѪѫѬѭѮѯѰѱѲѳѴѵѶѷѸѹѺѻѼѽѾѿҀҁ҂҃҄҅҆҈҉ҊҋҌҍҎҏҐґҒғҔҕҖҗҘҙҚқҜҝҞҟҠҡҢңҤҥҦҧҨҩҪҫҬҭҮүҰұҲҳҴҵҶҷҸҹҺһҼҽҾҿӀӁӂӃӄӅӆӇӈӉӊӋӌӍӎӏӐӑӒӓӔӕӖӗӘәӚӛӜӝӞӟӠӡӢӣӤӥӦӧӨөӪӫӬӭӮӯӰӱӲӳӴӵӶӷӸӹӺӻӼӽӾӿԀԁԂԃԄԅԆԇԈԉԊԋԌԍԎԏԐԑԒԓḀḁḾḿẀẁẂẃẄẅẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹὍ–—―‗‘’‚‛“”„†‡•…‰′″‹›‼⁄ⁿ₣₤₧₫€℅ℓ№™Ω℮⅛⅜⅝⅞∂∆∏∑−√∞∫≈≠≤≥◊ﬁﬂﬃﬄ￼ ";

list g_lFonts = [
    "Solid", "91b730bc-b763-52d4-d091-260eddda3198",
    "Outlined", "c1481c75-15ea-9d63-f6cf-9abb6db87039"
    ];

key g_kFontTexture = "91b730bc-b763-52d4-d091-260eddda3198";

integer x = 45;
integer y = 19;

integer faces = 6; // Default would be 6

float g_fScrollTime = 0.3 ;
list g_lScrollPos ;
list g_lScrollText;
list g_lLabelLinks;
list g_lLabelBaseElements;
list g_lGlows;

integer g_iScroll = FALSE;
integer g_iShow;
vector g_vColor = <1,1,1>;
integer g_iHide;

list g_lLabelText = [""];
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

RenderString(integer iPos, string sChar, integer iLineNum) {  // iPos - позиция символа на лейбле
    integer frame = GetIndex(sChar);  //номер символа в таблице
    integer i = iPos/faces;
    integer link = llList2Integer(llParseString2List(llList2String(g_lLabelLinks,iLineNum),["|"],[]),i);
    integer face = iPos - faces * i;
    integer frameY = frame / x;
    integer frameX = frame - x * frameY;
    float Uoffset = -0.5 + (Ureps/2 + Ureps*(frameX)) ;
    float Voffset = 0.5 - (Vreps/2 + Vreps*(frameY)) ;
    llSetLinkPrimitiveParamsFast(link, [PRIM_TEXTURE, face, g_kFontTexture, <Ureps, Vreps,0>, <Uoffset, Voffset, 0>, 0]);
}

SetColor() {

    integer iLine;
    for (iLine=0;iLine<llGetListLength(g_lLabelLinks);++iLine)
    {
        list lLinkList = llParseString2List(llList2String(g_lLabelLinks,iLine),["|"],[]);
        integer i=0;
        do {
            integer iLink = llList2Integer(lLinkList,i);
            float fAlpha = llList2Float(llGetLinkPrimitiveParams( iLink,[PRIM_COLOR,ALL_SIDES]),1);
            llSetLinkPrimitiveParamsFast(iLink, [PRIM_COLOR, ALL_SIDES, g_vColor, fAlpha]);
        } while (++i < llGetListLength(lLinkList));
    }
}
// find all 'Label' prims, count and store it's link numbers for fast work SetLabel() and timer
integer LabelsCount() {
    integer ok = TRUE ;
    integer bMultiLine = FALSE;
    list lSingleParamLinks = [];
    g_lLabelLinks = [] ;
    g_lLabelBaseElements = [];
    string sLabel;
    list lTmp;
    integer iLink;
    integer iLinkCount = llGetNumberOfPrims();
    //find all 'Label' prims and count it's
    for(iLink=2; iLink <= iLinkCount; iLink++) {
        lTmp = llParseString2List(llGetLinkName(iLink), ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if(sLabel == "MeshLabel") {
            integer iLine = 0;
            if (llGetListLength(lTmp)>2) {
                iLine = llList2Integer(lTmp,2);
                bMultiLine = TRUE;
            } else {
                iLine = 0;
                lSingleParamLinks += [iLink];
            }
            if (iLine > llGetListLength(g_lLabelLinks)-1) g_lLabelLinks += [""]; // Add new Line
            list lLineLinks = llParseString2List(llList2String(g_lLabelLinks,iLine),["|"],[]);
            lLineLinks += [0]; // Fill with Zero
            g_lLabelLinks = llListReplaceList(g_lLabelLinks,[llDumpList2String(lLineLinks,"|")],iLine,iLine);
            //change prim description
            llSetLinkPrimitiveParamsFast(iLink,[PRIM_DESC,"Label~notexture~nocolor~nohide~noshiny"]);
        } else if (sLabel == "LabelBase") g_lLabelBaseElements += iLink;
    }
    
    if (bMultiLine && llGetListLength(lSingleParamLinks) > 0) // if we have multible lines, check if all prims are correctly named
    {
        g_sErrorMsg += "Error! Some of your label prims don't have the line parameter in the name! (Should be: MeshLabel~num~line) \n";
        integer i;
        g_sErrorMsg += "Missing parameter in link numbers:";
        for (i=0; i<llGetListLength(lSingleParamLinks);++i)
        {
            g_sErrorMsg += " "+llList2String(lSingleParamLinks,i);
        }
        g_sErrorMsg += "\n";
        ok = FALSE;
    }
    
    if (ok) {
        integer i;
        for (i=0; i<llGetListLength(g_lLabelLinks);++i)
        {
            list lLineLinks = llParseString2List(llList2String(g_lLabelLinks,i),["|"],[]);
            g_lCharLimit = llListReplaceList(g_lCharLimit,[llGetListLength(lLineLinks) * faces],i,i);
        }
        //find all 'Label' prims and store it's links to list
        for(iLink=2; iLink <= iLinkCount; iLink++) {
            lTmp = llParseString2List(llGetLinkName(iLink), ["~"],[]);
            sLabel = llList2String(lTmp,0);
            if (sLabel == "MeshLabel") {
                integer iLabel = (integer)llList2String(lTmp,1);
                integer iLine = 0;
                if (llGetListLength(lTmp) > 2) iLine = llList2Integer(lTmp,2); // keep it compatible with old single-line version
                integer link = -1;
                
                list lLineList = llParseString2List(llList2String(g_lLabelLinks,iLine),["|"],[]);
                
                link = llList2Integer(lLineList,iLabel);
                if (link == 0) 
                {
                    if (iLabel > llGetListLength(lLineList) -1) {
                        g_sErrorMsg += "Error! First Parameter of the label prim with the link number "+(string)iLink+" exceeds the number of prims in line "+(string)iLine+" (Current="+(string)iLabel+" Max="+(string)(llGetListLength(lLineList) -1)+")\n";
                        ok = FALSE;
                    } else {
                        lLineList = llListReplaceList(lLineList, [iLink], iLabel, iLabel);
                        g_lLabelLinks = llListReplaceList(g_lLabelLinks, [llDumpList2String(lLineList,"|")], iLine, iLine);
                    }
                } else {
                    ok = FALSE;
                    g_sErrorMsg += "Error! Found duplicated label prims: "+sLabel+" with link numbers: "+(string)link+" and "+(string)iLink+"\n";
                }
            }
        }
    } 
    if (!ok) {
        if (~llSubStringIndex(llGetObjectName(),"Installer") && ~llSubStringIndex(llGetObjectName(),"Updater"))
            return 1;
        else {
            llOwnerSay(g_sErrorMsg);
            g_bHasError = TRUE;
        }
    }
    return ok;
}

SetLabelBaseAlpha() {
    if (g_iHide) return ;
    //loop through stored links, setting color if element type is bell
    integer n;
    integer iLinkElements = llGetListLength(g_lLabelBaseElements);
    for (n = 0; n < iLinkElements; n++) {
        llSetLinkAlpha(llList2Integer(g_lLabelBaseElements,n), (float)g_iShow, ALL_SIDES);
        UpdateGlow(llList2Integer(g_lLabelBaseElements,n), g_iShow);
    }
}

UpdateGlow(integer iLink, integer iAlpha) {
    integer i;
    if (iAlpha == 0) {
        float fGlow = llList2Float(llGetLinkPrimitiveParams(iLink,[PRIM_GLOW,0]),0);
        i = llListFindList(g_lGlows,[iLink]);
        if (i !=-1 && fGlow > 0) g_lGlows = llListReplaceList(g_lGlows,[fGlow],i+1,i+1);
        if (i !=-1 && fGlow == 0) g_lGlows = llDeleteSubList(g_lGlows,i,i+1);
        if (i == -1 && fGlow > 0) g_lGlows += [iLink, fGlow];
        llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, 0.0]);  // set no glow;
    } else {
        i = llListFindList(g_lGlows,[iLink]);
        if (i != -1) llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, llList2Float(g_lGlows, i+1)]);
    }
}   

SetLine(integer iNumber, string sText)
{
    string sPadding;
    if(g_iScroll==TRUE) {
        while(llStringLength(sPadding) < llList2Integer(g_lCharLimit,iNumber)) sPadding += " ";
        g_lScrollText = llListReplaceList(g_lScrollText,[sPadding + sText],iNumber,iNumber);
        llSetTimerEvent(g_fScrollTime);
    } else {
        g_lScrollText = [];
        llSetTimerEvent(0);
        //inlined single use CenterJustify function
        while(llStringLength(sPadding + sText + sPadding) < llList2Integer(g_lCharLimit,iNumber)) sPadding += " ";
        sText = sPadding + sText;
        integer iCharPosition;
        for(iCharPosition=0; iCharPosition < llList2Integer(g_lCharLimit,iNumber); iCharPosition++)
            RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition), iNumber);
    }
}

SetLabel() {
    if (llGetListLength(g_lLabelLinks) > 2) g_iScroll = FALSE; // No scrolling with more than 2 lines!
    if (g_iShow){
        integer i;
        for (i=0; i<llGetListLength(g_lLabelText);++i)
        {
            SetLine(i,llList2String(g_lLabelText,i));
        }
    } else {
        integer i;
        for (i=0; i<llGetListLength(g_lLabelLinks);++i)
        {
            SetLine(i," ");
        }
    }
}

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
}

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

MainMenu(key kID, integer iAuth) {
    list lButtons=[];
    integer i;
    for (i=0; i<llGetListLength(g_lLabelLinks); ++i)
    {
        lButtons += [g_sTextMenu+(string)(i+1)];
    }
    
    lButtons += [g_sColorMenu, g_sFontMenu, Checkbox(g_iShow, "Show")];
    
    if (llGetListLength(g_lLabelLinks) < 3)  // Too much work to scroll more than 2 lines.
    {
        lButtons+=Checkbox(g_iScroll, "Scroll");
    }

    string sPrompt = "\n[Label]\t"+g_sAppVersion+"\n\nCustomize the %DEVICETYPE%'s label!";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth,"main");
}

TextMenu(key kID, integer iAuth, integer iLineNum) {
    string sPrompt="\n- Submit the new label in the field below.\n- Submit a few spaces to clear the label.\n- Submit a blank field to go back to " + g_sSubMenu + ".";
    Dialog(kID, sPrompt, [], [], 0, iAuth,"textbox"+(string)iLineNum);
}

ColorMenu(key kID, integer iAuth) {
    string sPrompt = "\n\nSelect a color from the list";
    Dialog(kID, sPrompt, ["colormenu please"], [UPMENU], 0, iAuth,"color");
}

FontMenu(key kID, integer iAuth) {
    list lButtons=llList2ListStrided(g_lFonts,0,-1,2);
    string sPrompt = "\n[Label]\n\nSelect the font for the %DEVICETYPE%'s label.";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth,"font");
}

ConfirmDeleteMenu(key kAv, integer iAuth) {
    string sPrompt = "\nDo you really want to uninstall the "+g_sSubMenu+" App?";
    Dialog(kAv, sPrompt, ["Yes","No","Cancel"], [], 0, iAuth,"rmlabel");
}

UserCommand(integer iAuth, string sStr, key kAv) {
    //Debug("Command: "+sStr);
    string sLowerStr = llToLower(sStr);
     if (sStr == "rm label") {
        if (kAv!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kAv);
        else ConfirmDeleteMenu(kAv, iAuth);
    } else if (iAuth == CMD_OWNER) {
        if (sLowerStr == "menu label" || sLowerStr == "label") {
            MainMenu(kAv, iAuth);
            return;
        }
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llToLower(llList2String(lParams, 0));
        string sAction = llToLower(llList2String(lParams, 1));
        string sValue = llToLower(llList2String(lParams, 2));
        if (sCommand == "label" || llGetSubString(sCommand,0,-2) == "label") {
            if (sAction == "font") {
                string font = llDumpList2String(llDeleteSubList(lParams,0,1)," ");
                integer iIndex = llListFindList(g_lFonts, [font]);
                if (iIndex != -1) {
                    g_kFontTexture = (key)llList2String(g_lFonts, iIndex + 1);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "font=" + (string)g_kFontTexture, "");
                } else FontMenu(kAv, iAuth);
            } else if (sAction == "color") {
                string sColor= llDumpList2String(llDeleteSubList(lParams,0,1)," ");
                if (sColor != "") {
                    g_vColor=(vector)sColor;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"color="+(string)g_vColor, "");
                    SetColor();
                } else ColorMenu(kAv, iAuth);
            } else if (sAction == "on" && sValue == "") {
                g_iShow = TRUE;
                SetLabelBaseAlpha();
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"show="+(string)g_iShow, "");
            } else if (sAction == "off" && sValue == "") {
                g_iShow = FALSE;
                SetLabelBaseAlpha();
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"show="+(string)g_iShow, "");
            } else if (sAction == "scroll") {
                if (sValue == "on") g_iScroll = TRUE;
                else if (sValue == "off") g_iScroll = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"scroll="+(string)g_iScroll, "");
            } else {
                
                integer iLine;
                if (llGetSubString(sCommand,-1,-1) == "t") iLine = 0;
                else iLine = ((integer)llGetSubString(sCommand,-1,-1));
                string sNewText = llStringTrim(llDumpList2String(llDeleteSubList(lParams,0,0)," "),STRING_TRIM);
                g_lLabelText = llListReplaceList(g_lLabelText,[sNewText],iLine, iLine);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "text"+(string)iLine+"=" + sNewText, "");
                if (!g_iShow)
                    llMessageLinked(LINK_SET, NOTIFY, "0"+"The label is currently disabled, it will not show up until you enable it.", kAv);
                
                if (llStringLength(sNewText) > llList2Integer(g_lCharLimit,iLine)) {
                        string sDisplayText = llGetSubString(sNewText, 0, llList2Integer(g_lCharLimit,iLine)-1);
                        llMessageLinked(LINK_SET, NOTIFY, "0"+"Unless your set your label to scroll it will be truncted at "+sDisplayText+".", kAv);
                    }
            }
            SetLabel();
        }
    } else if (iAuth >= CMD_TRUSTED && iAuth <= CMD_WEARER) {
        string sCommand = llToLower(llList2String(llParseString2List(sStr, [" "], []), 0));
        if (sLowerStr == "menu label") {
            llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
        } else if (sCommand == "label")
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
    }
}

default
{
    state_entry() {
        g_sErrorMsg = "";
       // llSetMemoryLimit(45056);
        g_kWearer = llGetOwner();
        Ureps = (float)1 / x;
        Vreps = (float)1 / y;
        g_iShow = FALSE;
        if (LabelsCount()==TRUE) SetLabel();
        if (g_bHasError) {
            llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
    }

    on_rez(integer iNum) {
        if (g_kWearer != llGetOwner()) {
            g_lLabelText = [];
            SetLabel();
        }
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (llGetSubString(sToken,0,-2) == "text") g_lLabelText = llListReplaceList(g_lLabelText,[sValue],(integer)llGetSubString(sToken,-1,-1),(integer)llGetSubString(sToken,-1,-1));
                else if (sToken == "font") g_kFontTexture = (key)sValue;
                else if (sToken == "color") g_vColor = (vector)sValue;
                else if (sToken == "show") g_iShow = (integer)sValue;
                else if (sToken == "scroll") g_iScroll = (integer)sValue;
            } else if (sToken == "settings" && sValue == "sent") {
                SetColor();
                SetLabel();
            }else if(llGetSubString(sToken, 0, i) == "global_"){
                sToken = llGetSubString(sToken, i+1, -1);
                if(sToken == "checkboxes"){
                    g_lCheckboxes = llCSV2List(sValue);
                }
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            if (!g_bHasError) llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            else llOwnerSay(g_sErrorMsg);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMenuType=="main") {
                    //got a menu response meant for us.  pull out values
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (llGetSubString(sMessage,0,-2) == g_sTextMenu) TextMenu(kAv, iAuth, ((integer)llGetSubString(sMessage,-1,-1))-1);
                    else if (sMessage == g_sColorMenu) ColorMenu(kAv, iAuth);
                    else if (sMessage == g_sFontMenu) FontMenu(kAv, iAuth);
                    else if(sMessage == Checkbox(g_iShow, "Show")){
                        g_iShow=1-g_iShow;
                        string onoff="off";
                        if(g_iShow)onoff = "on";
                        UserCommand(iAuth, "label "+onoff, kAv);
                        MainMenu(kAv,iAuth);
                    } else if(sMessage == Checkbox(g_iScroll, "Scroll")){
                        g_iScroll=1-g_iScroll;
                        string onoff="off";
                        if(g_iScroll)onoff = "on";
                        UserCommand(iAuth, "label "+onoff, kAv);
                        UserCommand(iAuth, "label scroll "+onoff, kAv);
                        MainMenu(kAv,iAuth);
                    }
                } else if (sMenuType == "color") {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else {
                        UserCommand(iAuth, "label color "+sMessage, kAv);
                        ColorMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "font") {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else {
                        UserCommand(iAuth, "label font " + sMessage, kAv);
                        FontMenu(kAv, iAuth);
                    }
                } else if (llGetSubString(sMenuType,0,-2) == "textbox") { // TextBox response, extract values
                    if (sMessage != " ") UserCommand(iAuth, "label"+llGetSubString(sMenuType,-1,-1)+" " + sMessage, kAv);
                    UserCommand(iAuth, "menu " + g_sSubMenu, kAv);
                } else if (sMenuType == "rmlabel") {
                    if (sMessage == "Yes") {
                        if (llGetListLength(g_lScrollText) > 0) UserCommand(iAuth, "label scroll off", kAv);
                        llMessageLinked(LINK_SET, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_SET, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_SET, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
         else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            llInstantMessage(kID, llGetScriptName()+" APP VERSION: "+g_sAppVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            integer i;
            for (i=0; i<llGetListLength(g_lLabelText);++i)
            {
                llInstantMessage(kID, llGetScriptName()+" LABEL "+llList2String(g_lLabelText,i));
            }
        }
    }

    timer() {
    
        integer i;
        for (i=0; i<llGetListLength(g_lScrollText);++i)
        {
            integer iLineScroll = llList2Integer(g_lScrollPos,i);
            string sText = llGetSubString(llList2String(g_lScrollText,i), iLineScroll, -1);
            integer iCharPosition;
            for(iCharPosition=0; iCharPosition < llList2Integer(g_lCharLimit,i); iCharPosition++)
                RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition),i);
            g_lScrollPos = llListReplaceList(g_lScrollPos,[iLineScroll+1],i,i);
            
            if(llList2Integer(g_lScrollPos,i) > llStringLength(llList2String(g_lScrollText,i))) g_lScrollPos = llListReplaceList(g_lScrollPos,[0],i,i);
        }
    }

    changed(integer iChange) {
        if(iChange & CHANGED_LINK) // if links changed
            if (LabelsCount()==TRUE) SetLabel();
        if (iChange & CHANGED_COLOR) {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
            if (g_iHide != iNewHide){   //check there's a difference to avoid infinite loop
                g_iHide = iNewHide;
                SetLabelBaseAlpha(); // update hide elements
            }
        }
    }
}
