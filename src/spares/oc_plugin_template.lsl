/*
THIS FILE IS HEREBY RELEASED UNDER THE Public Domain
This script is released public domain, unlike other OC scripts for a specific and limited reason, because we want to encourage third party plugin creators to create for OpenCollar and use whatever permissions on their own work they see fit.  No portion of OpenCollar derived code may be used excepting this script,  without the accompanying GPLv2 license.
-Authors Attribution-
Aria (tiff589) - (July 2018-September 2018)
roan (Silkie Sabra) - (September 2018)
*/


string g_sParentMenu = "Apps";
string g_sSubMenu = "AMenu";


// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000; // Scripts send messages on this channel to have settings saved to httpdb
// str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001; // When startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; // The httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003; // Delete token from DB
integer LM_SETTING_EMPTY = 2004; // Sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001; //RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // Send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // Send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string ALL = "ALL";


key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride = 3;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_bLocked = FALSE;


Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else {
        g_lMenuIDs += [kID, kMenuID, sName];
    }
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Menu App]";
    list lButtons = ["A Button"];

    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum < CMD_OWNER || iNum > CMD_WEARER) {
        return;
    }

    if (llSubStringIndex(sStr, "amenu") && sStr != "menu " + g_sSubMenu) {
        return;
    }

    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }

    if (sStr == "AMenu" || sStr == "menu " + g_sSubMenu) {
        Menu(kID, iNum);

    /*
    } else if (iNum != CMD_OWNER && iNum != CMD_TRUSTED && kID != g_kWearer) {
         RelayNotify(kID, "Access denied!", 0);
    }
    */
    } else {
        integer iWSuccess = 0;
        list lParams = llParseString2List(sStr, [" "], []);
        string sChangeType = llList2String(lParams, 0);
        string sChangeValue = llList2String(lParams, 1);
        string sText;
    }
}

default {
    on_rez(integer iStartParam) {
        if (llGetOwner() != g_kWearer) {
            llResetScript();
        }
    }

    state_entry() {
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST, "global_locked", "");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID){
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sStr, kID);
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = llList2Key(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iAuth = llList2Integer(lMenuParams, 3);

                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenu == "Menu~Main") {
                    if (sMsg == UPMENU) {
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    } else if (sMsg == "A Button") {
                        llSay(0, "This is a example plugin.");
                    }
                }
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            if (sStr == "LINK_RLV") LINK_RLV = iSender;
            if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == LM_SETTING_RESPONSE) {
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_", "="], []);
            string sGroup = llList2String(lSettings, 0);
            string sName = llList2String(lSettings, 1);
            string sValue = llList2String(lSettings, 2);

            if (sGroup == "global") {
                if (sName == "locked") {
                    g_bLocked = (integer)sValue;
                }
            }
        } else if (iNum == LM_SETTING_DELETE) {
            // This is recieved back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"], []);
            string sGroup = llList2String(lSettings, 0);
            string sName = llList2String(lSettings, 1);

            if (sGroup == "global") {
                if (sName == "locked") {
                    g_bLocked = FALSE;
                }
            }
        }

        llOwnerSay(llDumpList2String([iSender, iNum, sStr, kID], "^"));
    }
}
