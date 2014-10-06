////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - shininess                              //
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

//based on OpenCollar - texture

string g_sParentMenu = "Appearance";
string g_sSubMenu = "Shininess";

string g_sIgnoreType = "notexture" ;  //  or "noshiny" if you want use alternate prims descriptions;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer TOUCH_REQUEST = -9500;
integer TOUCH_CANCEL = -9501;
integer TOUCH_RESPONSE = -9502;
integer TOUCH_EXPIRE = -9503;

string CTYPE = "collar";

string UPMENU = "BACK";

list g_lShiny = ["none","low","medium","high"];
string ALL = "All" ;

list g_lElements;
list g_lShinySettings;

list g_lButtons;

list g_lMenuIDs;
key g_kTouchID;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "Appearance_Lock";

string g_sCurrentElement = "";

key g_kWearer;

string g_sScript ;

string GetScriptID()
{
    // strip away "OpenCollar - " leaving the script's individual name
    list parts = llParseString2List(llGetScriptName(), ["-"], []);
    return llStringTrim(llList2String(parts, 1), STRING_TRIM) + "_";
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

key TouchRequest(key kRCPT,  integer iTouchStart, integer iTouchEnd, integer iAuth)
{
    key kID = llGenerateKey();
    integer iFlags = 0;
    if (iTouchStart) iFlags = iFlags | 0x01;
    if (iTouchEnd) iFlags = iFlags | 0x02;
    llMessageLinked(LINK_THIS, TOUCH_REQUEST, (string)kRCPT + "|" + (string)iFlags + "|" + (string)iAuth, kID);
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

ShinyMenu(key kAv, integer iAuth)
{
    string sPrompt = "Pick a Shiny.";
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lShiny, [UPMENU],0, iAuth)];
}

ElementMenu(key kAv, integer iAuth)
{
    string sPrompt = "Pick which part of the "+CTYPE+" you would like to change shiny.\n\nChoose *Touch* if you want to select the part by directly clicking on the "+CTYPE+".";
    g_lButtons = llListSort(g_lElements, 1, TRUE) + [ALL] ;
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lButtons, ["*Touch*", UPMENU],0, iAuth)];
}

string ElementType(integer iLinkNumber)
{
    //string sDesc = (string)llGetObjectDetails(llGetLinkKey(iLinkNumber), [OBJECT_DESC]);
    string sDesc = llList2String(llGetLinkPrimitiveParams(iLinkNumber, [PRIM_DESC]), 0); 
    //each prim should have <elementname> in its description, plus "noshiny, if you want the prim to
    //not appear in the shiny menu
    list lParams = llParseString2List(sDesc, ["~"], []);
    if ((~(integer)llListFindList(lParams, [g_sIgnoreType])) || sDesc == "" || sDesc == " " || sDesc == "(No Description)")
    {
        return g_sIgnoreType;
    }
    else
    {
        return llList2String(lParams, 0);
    }
}

BuildElementList()
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        string sElement = ElementType(n);
        if (!(~llListFindList(g_lElements, [sElement])) && sElement != g_sIgnoreType)
        {
            g_lElements += [sElement];
        }
    }
}

SetAllShiny(integer iShiny)
{
    integer elements = llGetListLength(g_lElements) ;
    integer index = 0 ;
    do
    {
        string sElement = llList2String(g_lElements, index);
        SetElementShiny(sElement, iShiny);
        index++ ;
    }while (index < elements ) ;
}

SetElementShiny(string sElement, integer iShiny)
{
    SetElement(sElement, iShiny);
    AddShinySettings(sElement, iShiny);
    //save to settings DB
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + sElement + "=" + (string)iShiny, "");
}

SetElement(string sElement, integer iShiny)
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    for (n = 2; n <= iLinkCount; n++)
    {
        if (ElementType(n) == sElement)
        {
            llSetLinkPrimitiveParamsFast(n,[PRIM_BUMP_SHINY,ALL_SIDES,iShiny,0]);
        }
    }
}

AddShinySettings(string sElement, integer iShiny)
{
    integer i = llListFindList(g_lShinySettings, [sElement]);
    if (i == -1)
    {
        g_lShinySettings += [sElement, iShiny];
    }
    else
    {
        g_lShinySettings = llListReplaceList(g_lShinySettings, [iShiny], i+1, i+1);
    }
}

UpdateElements()
{
    integer elements = llGetListLength(g_lShinySettings) ;
    integer i = 0 ;
    do
    {
        string sElement = llList2String(g_lShinySettings, i);
        integer iShiny =  llList2Integer(g_lShinySettings, i+1);        
        SetElement(sElement, iShiny);
        i+=2 ;
    }while (i < elements ) ;
}


// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum > COMMAND_WEARER || iNum < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);

    if (sStr == "menu "+ g_sSubMenu || sStr == "shiny")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the shiny.", FALSE);
            llMessageLinked(LINK_THIS, iNum, "menu "+g_sParentMenu, kID);
        }
        else if (g_iAppLock)
        {
            Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
            llMessageLinked(LINK_THIS, iNum, "menu "+g_sParentMenu, kID);
        }
        else
        {
            g_sCurrentElement = "";
            ElementMenu(kID, iNum);
        }
    }
    if (sCommand == "setshiny")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the shiny.", FALSE);
        }
        else if (g_iAppLock)
        {
            Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
        }
        else
        {
            string sElement = llList2String(lParams, 1);
            integer iShiny = (integer)(llList2String(lParams, 2));
            if (sElement == ALL || sElement == "all") SetAllShiny(iShiny);
            else SetElementShiny(sElement, iShiny);
        }
    }
    else if (sCommand == "lockappearance")
    {
        if (iNum == COMMAND_OWNER) g_iAppLock = llList2Integer(lParams, 1);
    }

    return TRUE;
}

// Get from Group_Token=Value , 0=Group, 1=Token, 2=Value
string SplitTokenValue(string in, integer slot)
{
    string out ;
    if (slot==0) out = llGetSubString(in, 0,  llSubStringIndex(in, "_") );
    else if (slot==1) out = llGetSubString(in, llSubStringIndex(in, "_")+1, llSubStringIndex(in, "=")-1);
    else if (slot==2) out = llGetSubString(in, llSubStringIndex(in, "=")+1, -1);
    return out ;
}

/*
RequestSettings()
{
    // restore settings from DB after reset script
    llMessageLinked(LINK_THIS, LM_SETTING_REQUEST, g_sAppLockToken, "");

    // request settings for all Elements
    integer n;
    integer iStop = llGetListLength(g_lElements);
    for (n = 0; n < iStop; n++)
    {
        string sElement = llList2String(g_lElements, n);
        llMessageLinked(LINK_THIS, LM_SETTING_REQUEST, g_sScript + sElement, "");
    }
}
*/


default
{
    
    on_rez(integer iParam)
    {
        llResetScript();
    }
    
    state_entry()
    {
        g_kWearer = llGetOwner();
        g_sScript = GetScriptID();
        BuildElementList();
        //RequestSettings(); // request settings from DB
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID)) {return;}
        else if (iNum == LM_SETTING_RESPONSE)
        {
            string sGroup = SplitTokenValue(sStr, 0);
            string sToken = SplitTokenValue(sStr, 1);
            string sValue = SplitTokenValue(sStr, 2);
            if (sGroup == g_sScript) AddShinySettings(sToken, (integer)sValue);            
            else if (sGroup+sToken == g_sAppLockToken) g_iAppLock = (integer)sValue;            
            else if (sGroup+sToken == "Global_CType") CTYPE = sValue;
            else if (sStr == "settings=sent") UpdateElements();
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                g_lMenuIDs=llDeleteSubList(g_lMenuIDs,iMenuIndex,iMenuIndex);
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU)
                {
                    if (g_sCurrentElement == "")
                    {
                        //main menu
                        llMessageLinked(LINK_THIS, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else
                    {
                        g_sCurrentElement = "" ;
                        ElementMenu(kAv, iAuth);
                    }
                }
                else if (sMessage == "*Touch*")
                {
                    Notify(kAv, "Please touch the part of the collar you want to shiny.", FALSE);
                    g_kTouchID = TouchRequest(kAv, TRUE, FALSE, iAuth);
                }
                else if (g_sCurrentElement == "")
                {
                    //we just got the element name
                    g_sCurrentElement = sMessage;
                    ShinyMenu(kAv, iAuth);
                }
                else if (~(integer)llListFindList(g_lShiny, [sMessage]))
                {
                    integer iShiny = llListFindList(g_lShiny, [sMessage]);
                    if(g_sCurrentElement == ALL) SetAllShiny(iShiny);
                    else SetElementShiny(g_sCurrentElement, iShiny);
                    ShinyMenu(kAv, iAuth);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                g_lMenuIDs=llDeleteSubList(g_lMenuIDs,iMenuIndex,iMenuIndex);
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
                if (sElement != g_sIgnoreType)
                {
                    g_sCurrentElement = sElement;
                    ShinyMenu(kAv, iAuth);
                    Notify(kAv, "You selected \""+sElement+"\".", FALSE);
                }
                else
                {
                    Notify(kAv, "You selected a prim which is not shiny. You can try again.", FALSE);
                    ElementMenu(kAv, iAuth);
                }
            }
        }
    }
}
