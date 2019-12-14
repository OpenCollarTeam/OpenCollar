// This file is part of OpenCollar.
// Copyright (c) 2014 - 2016 Romka Swallowtail et al.           
// Licensed under the GPLv2.  See LICENSE for full details. 



string g_sParentMenu = "Apps";
string g_sSubMenu = "Customizer";

//MESSAGE MAP
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;

integer NOTIFY = 1002;

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

integer g_iTexture = FALSE;
integer g_iColor = FALSE;
integer g_iHide = FALSE;
integer g_iShine = FALSE;
integer g_iGlow = FALSE;

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
    llMessageLinked(LINK_THIS, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iMenuIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    list lAddMe = [kRCPT, kMenuID, sMenuType];
    if (iMenuIndex == -1) g_lMenuIDs += lAddMe;
    else g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
}

ElementMenu(key kAv, integer iPage, integer iAuth)
{
    BuildElementsList();
    string sPrompt = "\nChange the Elements descriptions, %DEVICETYPE%.\nSelect an element from the list";
    list lButtons = llListSort(g_lElementsList, 1, TRUE);
    Dialog(kAv, sPrompt, lButtons, [REMOVE,RESET,UPMENU], iPage, iAuth, "ElementMenu");
}

CustomMenu(key kAv, integer iPage, integer iAuth)
{
    string sPrompt = "\nSelect an option for element '"+g_sCurrentElement+"':";
    sPrompt += "\n" + llDumpList2String(g_lCurrentParam, "~");
    list lButtons;
    if (g_iTexture) lButtons += ["▣ texture"];
    else lButtons += ["☐ texture"];
    if (g_iColor) lButtons += ["▣ color"];
    else lButtons += ["☐ color"];
    if (g_iHide) lButtons += ["▣ hide"];
    else lButtons += ["☐ hide"];
    if (g_iShine) lButtons += ["▣ shine"];
    else lButtons +=  ["☐ shine"];
    if (g_iGlow) lButtons += ["▣ glow"];
    else lButtons += ["☐ glow"];
    Dialog(kAv, sPrompt, lButtons, [SAVE, UPMENU], iPage, iAuth, "CustomMenu");
}

GetParam(list params)
{
    if ( ~llListFindList(params,["notexture"]) ) g_iTexture = FALSE;
    else g_iTexture = TRUE;
    if ( ~llListFindList(params,["nocolor"]) ) g_iColor = FALSE;
    else g_iColor = TRUE;
    if ( ~llListFindList(params,["noshine"]) ) g_iShine = FALSE;
    else g_iShine = TRUE;
    if ( ~llListFindList(params,["noglow"]) ) g_iGlow = FALSE;
    else g_iGlow = TRUE;
    if ( ~llListFindList(params,["nohide"]) ) g_iHide = FALSE;
    else g_iHide = TRUE;
}

string ChangeParam(list params)
{
    integer i;
    i = llListFindList(params,["notexture"]);
    if (g_iTexture && i!=-1) params = llDeleteSubList(params,i,i);
    else if (!g_iTexture && i==-1) params += ["notexture"];

    i = llListFindList(params,["nocolor"]);
    if (g_iColor && i!=-1) params = llDeleteSubList(params,i,i);
    else if (!g_iColor && i==-1) params += ["nocolor"];

    i = llListFindList(params,["noshine"]);
    if (g_iShine && i!=-1) params = llDeleteSubList(params,i,i);
    else if (!g_iShine && i==-1) params += ["noshine"];

    i = llListFindList(params,["noglow"]);
    if (g_iGlow && i!=-1) params = llDeleteSubList(params,i,i);
    else if (!g_iGlow && i==-1) params += ["noglow"];

    i = llListFindList(params,["nohide"]);
    if (g_iHide && i!=-1) params = llDeleteSubList(params,i,i);
    else if (!g_iHide && i==-1) params += ["nohide"];

    return llDumpList2String(params,"~");
}

SaveCurrentParam(string sElement)
{
    integer i = llGetNumberOfPrims();
    do
    {
        string description = llStringTrim(llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0),STRING_TRIM);
        list lParts = llParseStringKeepNulls(description,["~"],[]);
        if (llList2String(lParts,0)==sElement) llSetLinkPrimitiveParamsFast(i,[PRIM_DESC,ChangeParam(lParts)]);
    } while (i-- > 2) ;
}

ResetScripts()
{
    if (llGetInventoryType("oc_themes") == INVENTORY_SCRIPT) llResetOtherScript("oc_themes");
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

UserCommand(integer iAuth, string sStr, key kID )
{
    if (iAuth > CMD_WEARER || iAuth < CMD_OWNER) return ; // sanity check

    if (sStr == "menu " + g_sSubMenu)
    {
        //someone asked for our menu
        //give this plugin's menu to id
        if (kID!=g_kWearer && iAuth!=CMD_OWNER)
        {
        llMessageLinked(LINK_THIS, NOTIFY, "0%NOACCESS%.", kID);
            llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kID);
        }
        else ElementMenu(kID, 0, iAuth);
    } else if (llToLower(sStr) == "rm customizer") {
        if (kID!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_THIS,NOTIFY,"0"+"%NOACCESS%",kID);
        else Dialog(kID, "\nDo you really want to uninstall the "+g_sSubMenu+" App?", ["Yes","No","Cancel"], [], 0, iAuth,"rm"+g_sSubMenu);
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
        if (iNum <= CMD_WEARER && iNum >= CMD_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
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

                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);

                if (sMenuType == "ElementMenu")
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);
                    }
                    else if (sMessage == RESET)
                    {
                        ResetScripts();
                        llMessageLinked(LINK_THIS, iAuth, "load", kAv);
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iPage, iAuth);
                    }
                    else if (sMessage == REMOVE)
                    {
                        ResetScripts();
                        llMessageLinked(LINK_THIS, iAuth, "load", kAv);
                        llMessageLinked(LINK_THIS, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);
                        llRemoveInventory(llGetScriptName());
                    }
                    else if (~llListFindList(g_lElementsList, [sMessage]))
                    {
                        g_sCurrentElement = sMessage;
                        integer i = llListFindList(g_lElementsList,[g_sCurrentElement]);
                        g_lCurrentParam = llParseStringKeepNulls(llList2String(g_lParams ,i),["~"],[]);
                        GetParam(g_lCurrentParam);
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
                        SaveCurrentParam(g_sCurrentElement);
                        g_sCurrentElement = "";
                        g_lCurrentParam = [];
                        ElementMenu(kAv, iPage, iAuth);
                    }
                    else
                    {
                        if (sMessage == "☐ texture") g_iTexture = TRUE;
                        else if (sMessage == "▣ texture") g_iTexture = FALSE;
                        else if (sMessage == "☐ color") g_iColor = TRUE;
                        else if (sMessage == "▣ color") g_iColor = FALSE;
                        else if (sMessage == "☐ hide") g_iHide = TRUE;
                        else if (sMessage == "▣ hide") g_iHide = FALSE;
                        else if (sMessage == "☐ shine") g_iShine = TRUE;
                        else if (sMessage == "▣ shine") g_iShine = FALSE;
                        else if (sMessage == "☐ glow") g_iGlow = TRUE;
                        else if (sMessage == "▣ glow") g_iGlow = FALSE;
                        CustomMenu(kAv, iPage, iAuth);
                    }
                } else if (sMenuType == "rm"+g_sSubMenu) {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_THIS, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_THIS, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
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
