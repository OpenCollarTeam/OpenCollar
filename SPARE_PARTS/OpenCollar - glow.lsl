////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - glow                                //
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

string g_sParentMenu = "Appearance";
string g_sSubMenu = "Glow";

string g_sIgnoreType = "noglow" ;  //  or "nocolor" or "noglow" if you want use alternate prims descriptions;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;

//integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

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

list g_lGlowButtons = ["0.00","+0.01","-0.01","0.05","+0.05","-0.05","0.10","+0.10","-0.10","0.20","0.50"];
string ALL = "All" ;

list g_lElements;

list g_lButtons;

list g_lMenuIDs;
key g_kTouchID;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "Appearance_Lock";

string g_sCurrentElement = "";
float g_fCurrentGlow ;

key g_kWearer;


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

GlowMenu(key kAv, integer iAuth)
{
    g_fCurrentGlow = GetElementGlow(g_sCurrentElement);
    
    string sPrompt = "Change Glow for visible element only.\n";
    sPrompt += "\nElement: " + g_sCurrentElement;
    sPrompt += "\nGlow: " + llGetSubString((string)g_fCurrentGlow,0,3);
        
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lGlowButtons, [UPMENU],0, iAuth)];
}

ElementMenu(key kAv, integer iAuth)
{
    string sPrompt = "Pick which part of the "+CTYPE+" you would like to change glow.\n\nChoose *Touch* if you want to select the part by directly clicking on the "+CTYPE+".";
    sPrompt += "\n\nOnly visible elements!";
    
    g_lButtons = [ALL] + llListSort(g_lElements, 1, TRUE) ;
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lButtons, ["*Touch*", UPMENU],0, iAuth)];
}

string ElementType(integer iLinkNumber)
{
    // check for invisible prim
    list params = llGetLinkPrimitiveParams(iLinkNumber, [PRIM_COLOR, ALL_SIDES]);
    if (llList2Float(params,1) == 0 ) return g_sIgnoreType; // prim is invisible
    
    //string sDesc = (string)llGetObjectDetails(llGetLinkKey(iLinkNumber), [OBJECT_DESC]);
    string sDesc = llList2String(llGetLinkPrimitiveParams(iLinkNumber, [PRIM_DESC]), 0);
    //each prim should have <elementname> in its description, plus "noshiny, if you want the prim to
    //not appear in the shiny menu
    list lParams = llParseString2List(sDesc, ["~"], []);
    if ((~(integer)llListFindList(lParams, [g_sIgnoreType])) || sDesc == "" || sDesc == " " || sDesc == "(No Description)")
        return g_sIgnoreType;
    else return llList2String(lParams, 0);
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

SetAllGlow(float fGlow)
{
    integer elements = llGetListLength(g_lElements) ;
    integer index = 0 ;
    do
    {
        string sElement = llList2String(g_lElements, index);
        SetElementGlow(sElement, fGlow);
        index++ ;
    }while (index < elements ) ;
}

SetElementGlow(string sElement, float fGlow)
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    for (n = 2; n <= iLinkCount; n++)
    {
        if (ElementType(n) == sElement) llSetLinkPrimitiveParamsFast(n, [PRIM_GLOW, ALL_SIDES, fGlow]);
    }
}

float GetElementGlow(string sElement)
{
    integer n = 1;
    integer iLinkCount = llGetNumberOfPrims();
    //root prim is 1, so start at 2
    do
    { 
        n++;
    } while (ElementType(n) != sElement && n < iLinkCount);
    
    list params = llGetLinkPrimitiveParams(n, [PRIM_GLOW, ALL_SIDES]);
    return llList2Float(params, 0) ;
}



// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum > COMMAND_WEARER || iNum < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);

    if (sStr == "menu "+ g_sSubMenu || sStr == "glow")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the glow.", FALSE);
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
    else if (sCommand == "setglow")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the glow.", FALSE);
        }
        else if (g_iAppLock)
        {
            Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
        }
        else
        {
            string sElement = llList2String(lParams, 1);
            float fGlow = (float)llList2String(lParams, 2);
            if (sElement == ALL || sElement == "all") SetAllGlow(fGlow);
            else SetElementGlow(sElement, fGlow);
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


default
{

    on_rez(integer iParam)
    {
        llResetScript();
    }

    state_entry()
    {
        g_kWearer = llGetOwner();
        BuildElementList();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == LM_SETTING_RESPONSE)
        {            
            list params = llParseString2List(sStr,["="],[]);            
            string sToken = llList2String(params, 0);
            string sValue = llList2String(params, 1);
            if (sToken == g_sAppLockToken) g_iAppLock = (integer)sValue;
            else if (sToken == "Global_CType") CTYPE = sValue;
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
                    GlowMenu(kAv, iAuth);
                }
                else if (~(integer)llListFindList(g_lGlowButtons, [sMessage]))
                {
                    if (sMessage == "0.00") g_fCurrentGlow = 0.0 ;
                    else if (sMessage == "0.05") g_fCurrentGlow = 0.05 ;
                    else if (sMessage == "0.10") g_fCurrentGlow = 0.10 ;
                    else if (sMessage == "0.20") g_fCurrentGlow = 0.20 ;
                    else if (sMessage == "0.50") g_fCurrentGlow = 0.50 ;
                    else if (sMessage == "+0.01") g_fCurrentGlow += 0.01 ;
                    else if (sMessage == "+0.05") g_fCurrentGlow += 0.05 ;
                    else if (sMessage == "+0.10") g_fCurrentGlow += 0.10 ;
                    else if (sMessage == "-0.01") g_fCurrentGlow -= 0.01 ;
                    else if (sMessage == "-0.05") g_fCurrentGlow -= 0.05 ;
                    else if (sMessage == "-0.10") g_fCurrentGlow -= 0.10 ;

                    if (g_fCurrentGlow < 0.0) g_fCurrentGlow = 0.0 ;
                    if (g_fCurrentGlow > 1.0) g_fCurrentGlow = 1.0 ;

                    if(g_sCurrentElement == ALL) SetAllGlow(g_fCurrentGlow);
                    else SetElementGlow(g_sCurrentElement, g_fCurrentGlow);
                    GlowMenu(kAv, iAuth);
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
                    GlowMenu(kAv, iAuth);
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
