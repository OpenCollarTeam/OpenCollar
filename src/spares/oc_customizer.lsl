// This file is part of OpenCollar.
// Copyright (c) 2014 - 2016 Romka Swallowtail et al.
// Licensed under the GPLv2.  See LICENSE for full details.



string g_sParentMenu = "Apps";
string g_sSubMenu = "Customizer";

// MESSAGE MAP
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;

integer NOTIFY = 1002;

integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

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

integer g_bTexture = FALSE;
integer g_bColor = FALSE;
integer g_bHide = FALSE;
integer g_bShine = FALSE;
integer g_bGlow = FALSE;

list g_lElementsList;
list g_lParams;

string g_sCurrentElement;
list g_lCurrentParam;

list g_lMenuIDs; // 3-strided list of kAv, dialogid, menuname
integer g_iMenuStride = 3;


/*
integer g_bProfiled;
Debug(string sStr) {
    // If you delete the first // from the preceeding and following  lines,
    // profiling is off, debug is off, and the compiler will remind you to
    // remove the debug calls from the code, we're back to production mode
    if (!g_bProfiled) {
        g_bProfiled = TRUE;
        llScriptProfiler(TRUE);
    }
    llOwnerSay(llGetScriptName() + "(min free:" + (string)(llGetMemoryLimit() - llGetSPMaxMemory()) + ")[" + (string)llGetFreeMemory() + "] :\n" + sStr);
}
*/

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iMenuIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    list lAddMe = [kRCPT, kMenuID, sMenuType];
    if (iMenuIndex == -1) {
        g_lMenuIDs += lAddMe;
    } else {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
    }
}

string Checkbox(integer iValue, string sLabel) {
    if (iValue) return "☑ " + sLabel;
    else return "☐ " + sLabel;
}

ElementMenu(key kAv, integer iPage, integer iAuth) {
    BuildElementsList();
    string sPrompt = "\nChange the Elements descriptions, %DEVICETYPE%.\nSelect an element from the list";
    list lButtons = llListSort(g_lElementsList, 1, TRUE);
    Dialog(kAv, sPrompt, lButtons, [REMOVE, RESET, UPMENU], iPage, iAuth, "ElementMenu");
}

CustomMenu(key kAv, integer iPage, integer iAuth) {
    string sPrompt = "\nSelect an option for element '" + g_sCurrentElement + "':";
    sPrompt += "\n" + llDumpList2String(g_lCurrentParam, "~");

    list lButtons = [
        Checkbox(g_bTexture, "texture"),
        Checkbox(g_bColor, "color"),
        Checkbox(g_bHide, "hide"),

        Checkbox(g_bShine, "shine"),
        Checkbox(g_bGlow, "glow")
    ];

    Dialog(kAv, sPrompt, lButtons, [SAVE, UPMENU], iPage, iAuth, "CustomMenu");
}

GetParam(list lParams) {
    if (~llListFindList(lParams, ["notexture"])) {
        g_bTexture = FALSE;
    } else {
        g_bTexture = TRUE;
    }

    if (~llListFindList(lParams, ["nocolor"])) {
        g_bColor = FALSE;
    } else {
        g_bColor = TRUE;
    }

    if (~llListFindList(lParams, ["noshine"])) {
        g_bShine = FALSE;
    } else {
        g_bShine = TRUE;
    }

    if (~llListFindList(lParams, ["noglow"])) {
        g_bGlow = FALSE;
    } else {
        g_bGlow = TRUE;
    }

    if (~llListFindList(lParams, ["nohide"])) {
        g_bHide = FALSE;
    } else {
        g_bHide = TRUE;
    }
}

string ChangeParam(list lParams) {
    integer i;
    i = llListFindList(lParams, ["notexture"]);
    if (g_bTexture && i !=- 1) {
        lParams = llDeleteSubList(lParams, i, i);
    } else if (!g_bTexture && i == -1) {
        lParams += "notexture";
    }

    i = llListFindList(lParams, ["nocolor"]);
    if (g_bColor && i != -1) {
        lParams = llDeleteSubList(lParams, i, i);
    } else if (!g_bColor && i == -1) {
        lParams += "nocolor";
    }

    i = llListFindList(lParams, ["noshine"]);
    if (g_bShine && i != -1) {
        lParams = llDeleteSubList(lParams, i, i);
    } else if (!g_bShine && i == -1) {
        lParams += "noshine";
    }

    i = llListFindList(lParams, ["noglow"]);
    if (g_bGlow && i != -1) {
        lParams = llDeleteSubList(lParams, i, i);
    } else if (!g_bGlow && i == -1) {
        lParams += "noglow";
    }

    i = llListFindList(lParams, ["nohide"]);
    if (g_bHide && i != -1) {
        lParams = llDeleteSubList(lParams, i, i);
    } else if (!g_bHide && i == -1) {
        lParams += "nohide";
    }

    return llDumpList2String(lParams, "~");
}

SaveCurrentParam(string sElement) {
    integer i = llGetNumberOfPrims();
    do
    {
        string sDescription = llStringTrim(llList2String(llGetLinkPrimitiveParams(i, [PRIM_DESC]), 0), STRING_TRIM);
        list lParts = llParseStringKeepNulls(sDescription, ["~"], []);
        if (llList2String(lParts, 0) == sElement) {
            llSetLinkPrimitiveParamsFast(i, [
                PRIM_DESC, ChangeParam(lParts)
            ]);
        }
    } while (i-- > 2);
}

ResetScripts() {
    if (llGetInventoryType("oc_themes") == INVENTORY_SCRIPT) {
        llResetOtherScript("oc_themes");
    }
}

BuildElementsList() {
    g_lElementsList = [];
    g_lParams = [];
    integer iCount = llGetNumberOfPrims();
    do
    {
        string sDescription = llStringTrim(llList2String(llGetLinkPrimitiveParams(iCount, [PRIM_DESC]), 0), STRING_TRIM);
        list lParts = llParseStringKeepNulls(sDescription, ["~"], []);
        string sElement = llList2String(lParts, 0);
        if (sDescription != "" && sDescription != "(No Description)") {
            if (!~llListFindList(g_lElementsList, [sElement])) {
                g_lElementsList += sElement;
                g_lParams += llDumpList2String(llDeleteSubList(lParts, 0, 0), "~");
            }
        }
    } while (iCount-- > 2);
}

UserCommand(integer iAuth, string sStr, key kID) {
    if (iAuth > CMD_WEARER || iAuth < CMD_OWNER) {
        return; // Sanity check
    }

    if (sStr == "menu " + g_sSubMenu) {
        // Someone asked for our menu
        // Give this plugin's menu to id
        if (kID != g_kWearer && iAuth != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0%NOACCESS%.", kID);
            llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kID);
        } else {
            ElementMenu(kID, 0, iAuth);
        }
    } else if (llToLower(sStr) == "rm customizer") {
        if (kID != g_kWearer && iAuth != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            Dialog(kID, "\nDo you really want to uninstall the " + g_sSubMenu + " App?", ["Yes", "No", "Cancel"], [], 0, iAuth, "rm" + g_sSubMenu);
        }
    }
}

default {
    state_entry() {
        g_kWearer = llGetOwner();
        BuildElementsList();
        //Debug("FreeMem: " + (string)llGetFreeMemory());
    }

    on_rez(integer iParam) {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum <= CMD_WEARER && iNum >= CMD_OWNER) {
            UserCommand(iNum, sStr, kID);
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                // Got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);

                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == "ElementMenu") {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);
                    } else if (sMessage == RESET) {
                        ResetScripts();
                        llMessageLinked(LINK_SAVE, iAuth, "load", kAv);
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iPage, iAuth);
                    } else if (sMessage == REMOVE) {
                        ResetScripts();
                        llMessageLinked(LINK_SAVE, iAuth, "load", kAv);
                        llMessageLinked(LINK_THIS, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);
                        llRemoveInventory(llGetScriptName());
                    } else if (~llListFindList(g_lElementsList, [sMessage])) {
                        g_sCurrentElement = sMessage;
                        integer i = llListFindList(g_lElementsList,[g_sCurrentElement]);
                        g_lCurrentParam = llParseStringKeepNulls(llList2String(g_lParams, i), ["~"], []);
                        GetParam(g_lCurrentParam);
                        CustomMenu(kAv, iPage, iAuth);
                    } else {
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iPage, iAuth);
                    }
                } else if (sMenuType == "CustomMenu") {
                    if (sMessage == UPMENU) {
                        ElementMenu(kAv, iPage, iAuth);
                    } else if (sMessage == SAVE) {
                        SaveCurrentParam(g_sCurrentElement);
                        g_sCurrentElement = "";
                        g_lCurrentParam = [];
                        ElementMenu(kAv, iPage, iAuth);
                    } else {
                        if (sMessage == "☐ texture") g_bTexture = TRUE;
                        else if (sMessage == "▣ texture") g_bTexture = FALSE;
                        else if (sMessage == "☐ color") g_bColor = TRUE;
                        else if (sMessage == "▣ color") g_bColor = FALSE;
                        else if (sMessage == "☐ hide") g_bHide = TRUE;
                        else if (sMessage == "▣ hide") g_bHide = FALSE;
                        else if (sMessage == "☐ shine") g_bShine = TRUE;
                        else if (sMessage == "▣ shine") g_bShine = FALSE;
                        else if (sMessage == "☐ glow") g_bGlow = TRUE;
                        else if (sMessage == "▣ glow") g_bGlow = FALSE;

                        CustomMenu(kAv, iPage, iAuth);
                    }
                } else if (sMenuType == "rm" + g_sSubMenu) {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + g_sSubMenu + " App has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
                            llRemoveInventory(llGetScriptName());
                        }
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + g_sSubMenu + " App remains installed.", kAv);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) {
            llResetScript();
        }

        if (iChange & CHANGED_LINK) {
            BuildElementsList();
        }

        /*
        if (iChange & CHANGED_REGION) {
            if (g_bProfiled) {
                llScriptProfiler(TRUE);
                Debug("profiling restarted");
            }
         }
         */
    }
}
