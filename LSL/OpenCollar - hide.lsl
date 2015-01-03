////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - hide                                //
//                                 version 3.988                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//on getting menu request, give element menu
//on getting element type, give Hide and Show buttons
//on hearing "hide" or "show", do that for the current element type

string g_sParentMenu = "Appearance";
string g_sSubMenu = "Hide/Show";

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer TOUCH_REQUEST = -9500;
integer TOUCH_CANCEL = -9501;
integer TOUCH_RESPONSE = -9502;
integer TOUCH_EXPIRE = -9503;

//5000 block is reserved for IM slaves
string CTYPE = "Collar";
string HIDE = "☒";
string SHOW = "☐";
string UPMENU = "BACK";

string g_sScript;

list g_lElements;
list g_lGlows; // 2-strided list [integer link_num, float glow]

key g_kWearer;

key g_kDialogID;
key g_kTouchID;

list g_lAlphaSettings;

string g_sIgnore = "nohide";
list g_lButtons;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "Appearance_Lock";

integer g_iAllAlpha = 1 ;

integer g_iHasElements = FALSE;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    //Debug("Made menu.");
    return kID;
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

string Float2String(float in)
{
    string out = (string)in;
    integer i = llSubStringIndex(out, ".");
    while (~i && llStringLength(llGetSubString(out, i + 2, -1)) && llGetSubString(out, -1, -1) == "0")
    {
        out = llGetSubString(out, 0, -2);
    }
    return out;
}

key TouchRequest(key kRCPT,  integer iTouchStart, integer iTouchEnd, integer iAuth)
{
    key kID = llGenerateKey();
    integer iFlags = 0;
    if (iTouchStart) iFlags = iFlags | 0x01;
    if (iTouchEnd) iFlags = iFlags | 0x02;
    llMessageLinked(LINK_SET, TOUCH_REQUEST, (string)kRCPT + "|" + (string)iFlags + "|" + (string)iAuth, kID);
    return kID;
} 

UpdateElementAlpha(string element_to_set, integer iAlpha)
{
    //loop through links, setting alpha if element type matches what we're changing
    //root prim is 1, so start at 2
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    for (n = 2; n <= iLinkCount; n++)
    {
        string sElement = ElementType(n);
        if (sElement == element_to_set)
        {
            llSetLinkAlpha(n, (float)iAlpha, ALL_SIDES);
            UpdateGlow(n,iAlpha);
        }
    }
}

SetAllElementsAlpha(integer iAlpha)
{
    if(g_iAllAlpha == iAlpha) return ;
    g_iAllAlpha = iAlpha ;
    if(iAlpha == 0) // then hide all
    {
        SaveAllGlows();  // save all prims glows before
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_GLOW, ALL_SIDES, 0.0]);  // set all no glow
    }
    llSetLinkAlpha(LINK_SET, (float)iAlpha, ALL_SIDES);
    if(iAlpha == 0) return ;
    RestoreAllGlows();
    //update alpha for all elements to fAlpha (either 1.0 or 0.0 here)
    integer n;
    integer iStop = llGetListLength(g_lElements);
    for (n = 0; n < iStop; n++)
    {
        string sElement = llList2String(g_lElements, n);
        integer iIndex = llListFindList(g_lAlphaSettings, [sElement]);
        if(iIndex !=-1)
        {
            integer iAlpha = llList2Integer(g_lAlphaSettings, iIndex+1);
            UpdateElementAlpha(sElement,iAlpha);
        }
    }
}

SetElementAlpha(string element_to_set, integer iAlpha)
{
    if(g_iAllAlpha == 1)
    {
        //loop through links, setting alpha if element type matches what we're changing
        //root prim is 1, so start at 2
        integer n;
        integer iLinkCount = llGetNumberOfPrims();
        for (n = 2; n <= iLinkCount; n++)
        {
            string sElement = ElementType(n);
            if (sElement == element_to_set)
            {
                llSetLinkAlpha(n, (float)iAlpha, ALL_SIDES);
                UpdateGlow(n,iAlpha);
            }
        }
    }
    //update element in list of settings
    integer i = llListFindList(g_lAlphaSettings, [element_to_set]);
    if (i == -1) g_lAlphaSettings += [element_to_set, (string)iAlpha];
    else g_lAlphaSettings = llListReplaceList(g_lAlphaSettings, [(string)iAlpha], i+1, i+1);
}

SaveElementAlpha(string element_to_set, integer iAlpha)
{
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+element_to_set + "=" + (string)iAlpha, "");
}

ElementMenu(key kAv, integer iAuth)
{
    string sPrompt = "\nWhich element of the " + CTYPE + " would you like to hide or show?\n\n☒: element is shown\n☐: element is hidden\n\nChoose *Touch* if you want to select the part by directly clicking on the " + CTYPE + ".";
    g_lButtons = [];

    if (g_iAllAlpha) g_lButtons += HIDE + " " + CTYPE ;
    else g_lButtons += SHOW + " " + CTYPE ;

    //loop through elements, show appropriate buttons and prompts if hidden or shown
    integer n;
    integer iStop = llGetListLength(g_lElements);
    for (n = 0; n < iStop; n++)
    {
        string sElement = llList2String(g_lElements, n);
        integer iIndex = llListFindList(g_lAlphaSettings, [sElement]);
        if (iIndex == -1)
        {
            g_lButtons += HIDE + " " + sElement;
        }
        else
        {
            integer iAlpha = llList2Integer(g_lAlphaSettings, iIndex + 1);
            if (iAlpha) g_lButtons += HIDE + " " + sElement;
            else  g_lButtons += SHOW + " " + sElement;
        }
    }

    g_kDialogID=Dialog(kAv, sPrompt, g_lButtons, ["*Touch*", UPMENU],0, iAuth);
}

string ElementType(integer link)
{
    string sDesc = llStringTrim(llList2String(llGetLinkPrimitiveParams(link,[PRIM_DESC]),0),STRING_TRIM);
    //each prim should have <elementname> in its description, plus "nohide", if you want the prim to
    //not appear in the hede menu
    if (sDesc == "" || sDesc == "(No Description)") return g_sIgnore ;
    list lParams = llParseString2List(sDesc, ["~"], []);
    if ( ~llListFindList(lParams,[g_sIgnore]) ) return g_sIgnore ;
    else return llList2String(lParams, 0);
}

BuildElementList()
{
    g_lElements = [];
    integer link;
    integer count = llGetNumberOfPrims();

    //root prim is 1, so start at 2
    for (link = 2; link <= count; link++)
    {
        string sElement = ElementType(link);
        if (llListFindList(g_lElements,[sElement])==-1 && sElement != g_sIgnore)
        {
            g_lElements += [sElement];
        }
    }
    g_lElements = llListSort(g_lElements, 1, TRUE);
    
    if (llGetListLength(g_lElements) > 0 ) g_iHasElements = TRUE;
    else g_iHasElements = FALSE;
}


UpdateGlow(integer link, integer alpha)
{
    if (alpha == 0)
    {
        SavePrimGlow(link);
        llSetLinkPrimitiveParamsFast(link, [PRIM_GLOW, ALL_SIDES, 0.0]);  // set no glow;
    }
    else RestorePrimGlow(link);
}

SavePrimGlow(integer link)
{
    float glow = llList2Float(llGetLinkPrimitiveParams(link,[PRIM_GLOW,0]),0) ;    
    integer i = llListFindList(g_lGlows,[link]);        
    if (i !=-1 && glow > 0) g_lGlows = llListReplaceList(g_lGlows,[glow],i+1,i+1) ;
    else if (i !=-1 && glow == 0) g_lGlows = llDeleteSubList(g_lGlows,i,i+1) ;
    else if (i == -1 && glow > 0) g_lGlows += [link, glow];    
}

RestorePrimGlow(integer link)
{
    integer i = llListFindList(g_lGlows,[link]);
    if (i != -1) 
    {
        float glow = (float)llList2String(g_lGlows, i+1);
        llSetLinkPrimitiveParamsFast(link, [PRIM_GLOW, ALL_SIDES, glow]);
    }
}

SaveAllGlows()
{
    integer link;
    integer count = llGetNumberOfPrims();
    //root prim is 1, so start at 2
    for (link = 1; link < count; link++)
    {
        SavePrimGlow(link);
    }
}

RestoreAllGlows()
{
    integer link;
    integer count = llGetNumberOfPrims();
    //root prim is 1, so start at 2
    for (link = 1; link < count; link++)
    {
        RestorePrimGlow(link);
    }
}

MakeOneButtonMenu()
{
    if (g_iAllAlpha)
    {
        llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu+"|"+HIDE+" Stealth", "");
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu+"|"+SHOW+" Stealth", "");
    }
    else
    {
        llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu+"|"+SHOW+" Stealth", "");
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu+"|"+HIDE+" Stealth", "");
    }
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum > COMMAND_WEARER || iNum < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llList2String(lParams, 1);

    if (!g_iAppLock || iNum == COMMAND_OWNER)  // if unlocked or Owner can do it
    {
        if (sStr == "menu " + g_sSubMenu || sStr == "hidemenu") ElementMenu(kID, iNum) ;
        else if (sCommand == "hide")
        {
            if(sValue == "" || sValue == CTYPE)
            {
                SetAllElementsAlpha(0);
                if (!g_iHasElements) MakeOneButtonMenu();
            }
            else
            {
                SetElementAlpha(sValue, 0);
                SaveElementAlpha(sValue, 0);
            }
        }
        else if (sCommand == "stealth")
        {
            if (g_iAllAlpha == 0) {
                SetAllElementsAlpha(1);
            }
            else {
                SetAllElementsAlpha(0);
            }
                
        }
        else if (sCommand == "show")
        {
            if(sValue == "" || sValue == CTYPE)
            {
                SetAllElementsAlpha(1);
                if (!g_iHasElements) MakeOneButtonMenu();
            }
            else
            {
                SetElementAlpha(sValue, 1);
                SaveElementAlpha(sValue, 1);
            }
        }
        else if (sStr == "menu "+HIDE+" Stealth")
        {
            SetAllElementsAlpha(1);
            if (!g_iHasElements) MakeOneButtonMenu();
            llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
        }
        else if (sStr == "menu "+SHOW+" Stealth")
        {
            SetAllElementsAlpha(0) ;
            if (!g_iHasElements) MakeOneButtonMenu();
            llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
        }
    }
    else
    {
        if (sStr  == "menu " + g_sSubMenu || sStr == "hidemenu" || sCommand == "hide" || sCommand == "show")
            Notify(kID,"The appearance of the " + CTYPE + " is locked. You cannot access this menu now!", FALSE);
    }

    if (iNum == COMMAND_OWNER && sCommand == "lockappearance")
    {
        if (sValue == "0") g_iAppLock = FALSE;
        else if (sValue == "1") g_iAppLock = TRUE;
    }
    else if (iNum == COMMAND_WEARER && sStr == "runaway")
    {
        SetAllElementsAlpha(1);
    }

    return TRUE ;
}


// Get Group or Token, 0=Group, 1=Token, 2=Value
string SplitTokenValue(string in, integer slot)
{
    string out ;
    if (slot==0) out = llGetSubString(in, 0,  llSubStringIndex(in, "_") );
    else if (slot==1) out = llGetSubString(in,  llSubStringIndex(in, "_")+1, llSubStringIndex(in, "=")-1);
    else if (slot==2) out = llGetSubString(in, llSubStringIndex(in, "=")+1, -1);
    return out ;
}

default {
    on_rez(integer iParam) {        
        g_iAllAlpha=0;
        if (llGetAlpha(ALL_SIDES)>0) g_iAllAlpha=1;
        if (!g_iHasElements) BuildElementList();
    }
    
    state_entry() {
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        BuildElementList();
        g_sScript = "hide_";
        g_kWearer = llGetOwner();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID)) return;

        else if (iNum == LM_SETTING_RESPONSE)
        {
            string sGroup = SplitTokenValue(sStr, 0);
            string sToken = SplitTokenValue(sStr, 1);
            string sValue = SplitTokenValue(sStr, 2);
            if (sGroup == g_sScript)
            {
                SetElementAlpha(sToken, (integer)sValue);
            }
            else if (sGroup+sToken == g_sAppLockToken)
            {
                g_iAppLock = (integer)sValue;
            }
            else if (sGroup+sToken == "Global_CType") CTYPE = sValue;
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            if (g_iHasElements) llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            else MakeOneButtonMenu() ;
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID==g_kDialogID)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                if (sMessage == UPMENU)
                {
                    //main menu
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                }
                else if (sMessage == "*Touch*")
                {
                    Notify(kAv, "Please touch the part of the " + CTYPE + " you want to hide or show. You can press ctr+alt+T to see invisible parts.", FALSE);
                    g_kTouchID = TouchRequest(kAv, TRUE, FALSE, iAuth);
                }
                else
                {
                    //get "Hide" or "Show" and element name
                    list lParams = llParseString2List(sMessage, [" "], []);
                    string sCmd = llList2String(lParams, 0);
                    string sElement = llList2String(lParams, 1);
                    if (sCmd == HIDE ) sCmd = "hide";
                    else if (sCmd == SHOW ) sCmd = "show";
                    UserCommand(iAuth, sCmd + " " + sElement, kAv);
                    ElementMenu(kAv, iAuth);
                }
            }
        }
        else if (iNum == TOUCH_RESPONSE)
        {
            if (kID == g_kTouchID)
            {
                list lParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lParams, 0);
                integer iAuth = (integer)llList2String(lParams, 1);
                integer iLinkNumber = (integer)llList2String(lParams, 3);

                string sElement = ElementType(iLinkNumber);
                if (sElement != g_sIgnore)
                {
                    integer iIndex = llListFindList(g_lAlphaSettings, [sElement]);
                    integer iAlpha;
                    if (iIndex == -1) iAlpha = 1; // assuming visible
                    else iAlpha =  llList2Integer(g_lAlphaSettings, iIndex + 1);
                    Notify(kAv, "You selected \"" + sElement+"\". Toggling its transparency.", FALSE);
                    SetElementAlpha(sElement, !iAlpha);
                    SaveElementAlpha(sElement, !iAlpha);
                }
                else
                {
                    Notify(kAv, "You selected a prim which is not hideable. You can try again.", FALSE);
                }
                ElementMenu(kAv, iAuth);
            }
        }
    }
    
    changed(integer change) {
        if (change & CHANGED_LINK) BuildElementList();
        if (change & CHANGED_OWNER) llResetScript();
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

