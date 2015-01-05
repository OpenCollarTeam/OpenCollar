////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - customizer                             //
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
string g_sSubMenu = "Customizer";

string CTYPE = "collar";

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string SAVE = "SAVE";
string REMOVE = "REMOVE";
string RESET = "RESET";

key g_kWearer;

list g_lElementsList;
list g_lParams;

string g_sCurrentElement ;
list g_lCurrentParam ;

list g_lMenuIDs;//3-strided list of kAv, dialogid, menuname
integer g_iMenuStride = 3;

/*
integer g_iProfiled=TRUE;
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


Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType)
{
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iMenuIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    list lAddMe = [kRCPT, kMenuID, sMenuType];
    if (iMenuIndex == -1) g_lMenuIDs += lAddMe;
    else g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
}

Notify(key kAv, string sMsg, integer iAlsoNotifyWearer)
{
    if (kAv == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kAv) != ZERO_VECTOR) llRegionSayTo(kAv,0,sMsg);
        else llInstantMessage(kAv, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

ElementMenu(key kAv, integer iPage, integer iAuth)
{
    BuildElementsList();
    string sPrompt = "\nChange the Elements descriptions, "+CTYPE+".\nSelect an element from the list";
    
    list lButtons = llListSort(g_lElementsList, 1, TRUE);
    
    Dialog(kAv, sPrompt, lButtons, [REMOVE,RESET,UPMENU], iPage, iAuth, "ElementMenu");
}

CustomMenu(key kAv, integer iPage, integer iAuth)
{
    string sPrompt = "\nSelect an option for element '"+g_sCurrentElement+"':";
    
    sPrompt += "\n" +g_sCurrentElement + "~" + llDumpList2String( g_lCurrentParam, "~") ;
    
    list lButtons;

    if ( ~llListFindList(g_lCurrentParam,["notexture"]) ) lButtons += ["☐ texture"];
    else lButtons += ["☒ texture"];

    if ( ~llListFindList(g_lCurrentParam,["nocolor"]) ) lButtons += ["☐ color"];
    else lButtons += ["☒ color"];

    if ( ~llListFindList(g_lCurrentParam,["nohide"]) ) lButtons += ["☐ hide"];
    else lButtons += ["☒ hide"];

    if ( ~llListFindList(g_lCurrentParam,["noshine"]) ) lButtons += ["☐ shine"];
    else lButtons += ["☒ shine"];

    if ( ~llListFindList(g_lCurrentParam,["noglow"]) ) lButtons += ["☐ glow"];
    else lButtons += ["☒ glow"];

    Dialog(kAv, sPrompt, lButtons, [SAVE, UPMENU], iPage, iAuth, "CustomMenu");
}

ChangeCurrentParam(string str)
{
    
    CurrentParam("noshiny", TRUE); // fix for my old 
    
    if (str == "☐ texture") CurrentParam("notexture", TRUE);
    else if (str == "☒ texture") CurrentParam("notexture", FALSE);
    
    else if (str == "☐ color") CurrentParam("nocolor", TRUE);
    else if (str == "☒ color") CurrentParam("nocolor", FALSE);
    
    else if (str == "☐ hide") CurrentParam("nohide", TRUE);
    else if (str == "☒ hide") CurrentParam("nohide", FALSE);

    else if (str== "☐ shine") CurrentParam("noshine", TRUE);
    else if (str == "☒ shine") CurrentParam("noshine", FALSE);

    else if (str == "☐ glow") CurrentParam("noglow", TRUE);
    else if (str == "☒ glow") CurrentParam("noglow", FALSE);    
}

CurrentParam(string type, integer set)
{
    integer i ;
    if (set)
    {
        i = llListFindList(g_lCurrentParam,[type]);
        if (i != -1) g_lCurrentParam = llDeleteSubList(g_lCurrentParam, i, i);
    }
    else
    {
        i = llListFindList(g_lCurrentParam,[type]);
        if (i == -1) g_lCurrentParam += [type];
    }
}

SaveCurrentParam()
{
    string params = llDumpList2String(g_lCurrentParam, "~") ;
    string newdescr = g_sCurrentElement + "~" + params ;
    
    integer i = llListFindList(g_lElementsList,[g_sCurrentElement]);    
    g_lParams = llListReplaceList(g_lParams, [params], i,i);    
    
    integer count = llGetNumberOfPrims();
    do
    {
        string description = llStringTrim(llList2String(llGetLinkPrimitiveParams(count,[PRIM_DESC]),0),STRING_TRIM);
        list lParts = llParseStringKeepNulls(description,["~"],[]);
        string element = llList2String(lParts,0);        
        if (element == g_sCurrentElement) llSetLinkPrimitiveParamsFast(count, [PRIM_DESC, newdescr]);
    } while (count-- > 2) ;
}

ResetScripts()
{
    if (llGetInventoryType("OpenCollar - hide") == INVENTORY_SCRIPT) llResetOtherScript("OpenCollar - hide");    
    if (llGetInventoryType("OpenCollar - texture") == INVENTORY_SCRIPT) llResetOtherScript("OpenCollar - texture");
    if (llGetInventoryType("OpenCollar - color") == INVENTORY_SCRIPT) llResetOtherScript("OpenCollar - color");  
    if (llGetInventoryType("OpenCollar - shininess") == INVENTORY_SCRIPT) llResetOtherScript("OpenCollar - shininess");
    if (llGetInventoryType("OpenCollar - glow") == INVENTORY_SCRIPT) llResetOtherScript("OpenCollar - glow");    
}

BuildElementsList()
{
    g_lElementsList=[];
    g_lParams=[];
    integer count = llGetNumberOfPrims();
    do
    {
        string description = llStringTrim(llList2String(llGetLinkPrimitiveParams(count,[PRIM_DESC]),0),STRING_TRIM);
        list lParts = llParseStringKeepNulls(description,["~"],[]);
        string element = llList2String(lParts,0);
        if (description != "" && description != "(No Description)")
        {
            if (!~llListFindList(g_lElementsList,[element]))
            {
                g_lElementsList += [element];
                g_lParams += llDumpList2String(llDeleteSubList(lParts,0,0), "~");
            }
        }
    } while (count-- > 2) ;
}


UserCommand(integer iAuth, string sStr, key kAv )
{
    if (iAuth > COMMAND_WEARER || iAuth < COMMAND_OWNER) return ; // sanity check

    if (sStr == "menu " + g_sSubMenu)
    {
        //someone asked for our menu
        //give this plugin's menu to id
        if (kAv!=g_kWearer && iAuth!=COMMAND_OWNER)
        {
            Notify(kAv,"You are not allowed to change the "+CTYPE+"'s appearance.", FALSE);
            llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
        }
        else ElementMenu(kAv, 0, iAuth);
    }
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        BuildElementsList();
        //Debug("FreeMem: " + (string)llGetFreeMemory());
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum <= COMMAND_WEARER && iNum >= COMMAND_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == "ElementMenu")
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    }
                    else if (sMessage == RESET)
                    {
                        ResetScripts();
                        llMessageLinked(LINK_THIS, iAuth, "Load Defaults", kID); 
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iPage, iAuth);
                    }
                    else if (sMessage == REMOVE)
                    {
                        ResetScripts();
                        llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                        llRemoveInventory(llGetScriptName());
                    }
                    else if (~llListFindList(g_lElementsList, [sMessage]))
                    {
                        g_sCurrentElement = sMessage;
                        
                        integer i = llListFindList(g_lElementsList,[g_sCurrentElement]);
                        g_lCurrentParam = llParseStringKeepNulls( llList2String(g_lParams ,i),["~"],[]);
    
                        CustomMenu(kAv, iPage, iAuth);
                    }
                    else
                    {
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iPage, iAuth);
                    }
                }
                else if (sMenuType == "CustomMenu")
                {
                    if (sMessage == UPMENU) ElementMenu(kAv, iPage, iAuth);
                    else if (sMessage == SAVE)
                    {
                        SaveCurrentParam();
                        g_sCurrentElement = "";
                        g_lCurrentParam = [];
                        ElementMenu(kAv, iPage, iAuth);
                    }
                    else
                    {
                        ChangeCurrentParam(sMessage);
                        CustomMenu(kAv, iPage, iAuth);
                    }
                }

            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        }
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_LINK) BuildElementsList();
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
