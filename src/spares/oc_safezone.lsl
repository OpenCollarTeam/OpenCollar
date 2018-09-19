// This file is part of OpenCollar.
// Copyright (c) 2014 - 2015 Sumi Perl et. al
// Licensed under the GPLv2.  See LICENSE for full details.

string SUBMENU_BUTTON = "SafeZone"; // Name of the submenu
string COLLAR_PARENT_MENU = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string g_sAppName = "safezone"; // Used to change the name of the app itself (and setting prefixes)
key g_kMenuID; // Menu handler
key g_kMenuRemoveID; // Remove menu handler
key g_kWearer; // Key of the current wearer to reset only on owner changes
string  g_sScript = "SafeZone_"; // Part of script name used for settings

integer g_bSafeZoneOn = FALSE;
integer g_bAllowList = FALSE;
integer g_bDenyList = FALSE; // Default behavior
integer g_bStealth = FALSE; // Hide/show collar when inactive

list g_lRegions;

string g_sCType = "collar"; // designer can set in notecard to appropriate word for their item        
string g_sWearerName;

string TICKED = "☒ ";
string UNTICKED = "☐ ";

integer CMD_OWNER = 500;
//integer CMD_SECOWNER = 501;
integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLACKLIST = 520;


integer LINK_AUTH = 2;
integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer LINK_ANIM = 6;
integer LINK_UPDATE = -10;

// Messages for storing and retrieving values from settings store
integer LM_SETTING_SAVE = 2000; // Scripts send messages on this channel to have settings saved to settings store
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002; // The settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003; // Delete token from settings store
//integer LM_SETTING_EMPTY = 2004;

// Messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

// Messages to the dialog helper
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;


// Menu option to go one step back in menustructure
string UPMENU = "BACK"; // when your menu hears this, give the parent menu


/*
Debug(string sMsg) {
    llOwnerSay(llGetScriptName() + " [DEBUG]: " + sMsg);
}
*/

Notify(key kID, string sMsg, integer bAlsoNotifyWearer) {
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    } else {
        if (llGetAgentSize(kID)) {
            llRegionSayTo(kID, 0, sMsg);
        } else {
            llInstantMessage(kID, sMsg);
        }

        if (bAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

CheckRegion() {
    string sRegion = llGetRegionName();
    if (g_bSafeZoneOn) {
        integer iIndex = llListFindList(g_lRegions, [sRegion]);
        if (g_bAllowList) { // We allow public modes here //g_bStealth
            if (iIndex < 0) {
                llMessageLinked(LINK_AUTH, CMD_OWNER, "public off", g_kWearer);
                if (g_bStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "hide", g_kWearer);
            } else {
                llMessageLinked(LINK_AUTH, CMD_OWNER, "public on", g_kWearer);
                if (g_bStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "show", g_kWearer);
            }
        } else if (g_bDenyList) { // We deny public modes here
            if (iIndex < 0) {
                llMessageLinked(LINK_AUTH, CMD_OWNER, "public on", g_kWearer);
                if (g_bStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "show", g_kWearer);
            } else {
                llMessageLinked(LINK_AUTH, CMD_OWNER, "public off", g_kWearer);
                if (g_bStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "hide", g_kWearer);
            }
        }
    }
}

DoMenu(key keyID, integer iAuth) {
    string sPrompt = "\n"+SUBMENU_BUTTON;
    list lButtons;

    if (g_bSafeZoneOn == TRUE){
        sPrompt += " is ON";
        lButtons += "OFF";
    } else {
        lButtons += "ON";
        sPrompt += " is OFF";
    }

    if (g_bAllowList) {
        lButtons += TICKED + "Allow";
        sPrompt += "\nAllow ON (allow public modes in listed regions) ";
    } else {
        lButtons += UNTICKED + "Allow";
        sPrompt += "\nDeny ON (public modes disabled in listed regions) ";
    }

    if (g_bDenyList) {
        lButtons += TICKED+"Deny";
    } else {
        lButtons += UNTICKED+"Deny";
    }

    if (g_bStealth) {
        lButtons += TICKED+"Stealth";
    } else {
        lButtons += UNTICKED+"Stealth";
    }

    lButtons += ["SAVE", "REMOVE"];

    g_kMenuID = Dialog(keyID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

DoMenuRemove(key keyID, integer iAuth) {
    string sPrompt = "\n" + SUBMENU_BUTTON + " remove";
    g_kMenuRemoveID = Dialog(keyID, sPrompt, g_lRegions, [UPMENU], 0, iAuth);
}


integer UserCommand(integer iNum, string sStr, key kID, integer bRemenu) {
    list lParams = llParseString2List(sStr,[" "],[]);
    string sParam0 = llList2String(lParams,0);
    string sParam1 = llList2String(lParams,1);
    string sParam2;

    if (llGetListLength(lParams) > 2) {
        sParam2 = llDumpList2String(llList2List(lParams, 2, -1), " ");
    }

    sStr = llToLower(sStr);

    if (!(iNum >= CMD_OWNER && iNum <= CMD_GROUP)) {
        return FALSE;
    } else if (sStr == g_sAppName || sStr == "menu " + g_sAppName) {
        // An authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    } else if (sStr == g_sAppName + " off")  {
        Notify(kID, SUBMENU_BUTTON + " plugin OFF!", TRUE);
        g_bSafeZoneOn = FALSE;
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sScript + g_sAppName, "");
        llMessageLinked(LINK_AUTH, CMD_OWNER, "public off", g_kWearer);
    } else if (sStr == g_sAppName + " on")  {
        Notify(kID, SUBMENU_BUTTON + " plugin ON!", TRUE);
        g_bSafeZoneOn = TRUE;
        CheckRegion();
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE,g_sScript + g_sAppName + "=1", "");
    } else if (sStr == g_sAppName + " stealth on")  {
        Notify(kID, SUBMENU_BUTTON + " Stealth mode active!",TRUE);
        g_bStealth = TRUE;
        CheckRegion();
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE,g_sScript + "stealth=1", "");
    } else if (sStr == g_sAppName + " stealth off")  {
        Notify(kID, SUBMENU_BUTTON + " Stealth mode deactivated!", TRUE);
        llMessageLinked(LINK_THIS, CMD_OWNER, "show", g_kWearer);
        g_bStealth = FALSE;
        CheckRegion();
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sScript + "stealth", "");
    } else if (sStr == g_sAppName + " allow")  {
        Notify(kID, SUBMENU_BUTTON + " is set to allow public modes in it's list of regions!", TRUE);
        g_bAllowList = TRUE;
        g_bDenyList = FALSE;
        CheckRegion();
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sScript + "allow=1", "");
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sScript + "deny", "");
    } else if (sStr == g_sAppName + " deny")  {
        Notify(kID, SUBMENU_BUTTON + " is set to deny public modes in it's list of regions!", TRUE);
        g_bAllowList = FALSE;
        g_bDenyList = TRUE;
        CheckRegion();
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sScript + "deny=1", "");
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sScript + "allow", "");
    } else if ((sParam0 == g_sAppName) && (sParam1 == "add")) {
        string sRegion;
        if (sParam2 == "") {
            sRegion = llGetRegionName();
        } else {
            sRegion = sParam2;
        }

        integer iIndex = llListFindList(g_lRegions,[sRegion]);
        if (iIndex < 0) { // We don't track this region.  Let's add it
            g_lRegions += sRegion;
            Notify(kID, SUBMENU_BUTTON + " added " + sRegion + " to the list of regions", TRUE);
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sScript + sRegion + "=1", "");
            CheckRegion();
        } else {
            Notify(kID, SUBMENU_BUTTON + " we already have " + sParam2 + " in the current list of regions.", FALSE);
        }
    } else if ((sParam0 == g_sAppName) && (sParam1 == "remove")) {
        string sRegion;
        if (sParam2 == "") {
            sRegion =  llGetRegionName();
        } else {
            sRegion = sParam2;
        }
        integer iIndex = llListFindList(g_lRegions, [sRegion]);
        if (iIndex >= 0) { // We already have this region, so we can delete it
            g_lRegions = llDeleteSubList(g_lRegions, iIndex, iIndex);
            Notify(kID, SUBMENU_BUTTON + " removed " + sRegion + " to the list of regions", TRUE);
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sScript + sRegion, "");
            CheckRegion();
        } else {
            Notify(kID, SUBMENU_BUTTON + " can't find " + sParam2 + " in the current list of regions.", FALSE);
        }
    }

    if (bRemenu) {
        DoMenu(kID, iNum);
    }

    return TRUE;
}



default {
    state_entry() {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();

        g_sWearerName = llGetDisplayName(g_kWearer);
        if (g_sWearerName == "???" || g_sWearerName == "") {
            g_sWearerName = llKey2Name(g_kWearer); // Sanity check, fallback if necessary
        }

        CheckRegion();
    }

    on_rez(integer iParam) {
        if (llGetOwner() != g_kWearer) {
            llResetScript();
        }

        CheckRegion();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //llOwnerSay(sStr + " | " + (string)iNum + "|" + (string)kID);
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // Our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        }
        /*
        else if ((iNum == LM_SETTING_DELETE) || (iNum == LM_SETTING_SAVE) || (iNum == LM_SETTING_RESPONSE)) { //listen for changes to auth_openaccess and takeme_takeme
            if (llSubStringIndex(sStr, "auth_openaccess") == 0) {
                if (iNum == LM_SETTING_DELETE) {
                    g_iOpenAccess = FALSE;
                } else {
                    if (g_iOpenAccess == FALSE) {
                        g_iOpenAccess = TRUE;
                    }
                    CheckRegion();
                } else if (llSubStringIndex(sStr, "takeme_takeme") == 0) {
                    if (iNum == LM_SETTING_DELETE) {
                        g_iTakeMe = FALSE;
                    } else {
                        if (g_iTakeMe == FALSE) {
                            g_iTakeMe = TRUE;
                        }
                        CheckRegion();
                    }
                }
            }
        }
        */
        else if ((iNum == LM_SETTING_RESPONSE || iNum == LM_SETTING_DELETE) && llSubStringIndex(sStr, "Global_WearerName") == 0 ) {
             integer iInd = llSubStringIndex(sStr, "=");
             string sValue = llGetSubString(sStr, iInd + 1, -1);
             // We have a broadcasted change to g_sWearerName to work with
             if (iNum == LM_SETTING_RESPONSE) {
                g_sWearerName = sValue;
             } else {
                 g_kWearer = llGetOwner();
                 g_sWearerName = llGetDisplayName(g_kWearer);
                 if (g_sWearerName == "???" || g_sWearerName == "") {
                    g_sWearerName == llKey2Name(g_kWearer);
                }
             }
         } else if (iNum == LM_SETTING_RESPONSE) {
             // Response from setting store have been received, parse the answer
             list lParams = llParseString2List(sStr, ["="], []);
             string sToken = llList2String(lParams, 0);
             string sValue = llList2String(lParams, 1);
             integer i = llSubStringIndex(sToken, "_");
             // And check if any values for use are received

             if (sToken == g_sScript+g_sAppName) g_bSafeZoneOn = TRUE;
             else if (sToken == g_sScript+"allow") g_bAllowList = TRUE;
             else if (sToken == g_sScript+"deny") g_bDenyList = TRUE;
             else if (sToken == g_sScript+"stealth") g_bStealth = TRUE;
             else if (sToken == "Global_CType") g_sCType = sValue;
             else if (llGetSubString(sToken, 0, i) == g_sScript) { // Hack up the token to pull the region name from "script_regionname=1"
                 string sTmpRegion = llGetSubString(sToken, llSubStringIndex(sToken, "_") + 1, llSubStringIndex(sToken, "="));
                 if(llListFindList(g_lRegions, [sTmpRegion]) < 0) { // Make sure we don't have this yet in our list
                     g_lRegions += sTmpRegion;
                 }
             }
         } else if (iNum == LINK_UPDATE) {
             if (sStr == "LINK_AUTH") LINK_AUTH = iSender;
             else if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
             else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
         } else if (iNum == CMD_SAFEWORD) {
             // Safeword has been received, release any restricitions that should be released
             // We're not really doing something that would warrant steps here
         } else if (UserCommand(iNum, sStr, kID, FALSE)) {
             // do nothing more if TRUE
         } else if (iNum == DIALOG_RESPONSE) {
             if (kID == g_kMenuID) {
                 // Got a menu response meant for us, extract the values
                 list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                 key kAv = (key)llList2String(lMenuParams, 0); // Avatar using the menu
                 string sMessage = llList2String(lMenuParams, 1); // Button label
                 //integer iPage = (integer)llList2String(lMenuParams, 2); // Menu page
                 integer iAuth = (integer)llList2String(lMenuParams, 3); // Auth level of avatar
                 // Request to switch to parent menu
                 if (sMessage == UPMENU) {
                     // Give av the parent menu
                     llMessageLinked(LINK_THIS, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
                 } else if (sMessage == "OFF") {
                     UserCommand(iAuth, g_sAppName + " off", kAv, TRUE);
                 } else if (sMessage == "ON") {
                     UserCommand(iAuth, g_sAppName + " on", kAv, TRUE);
                 } else if (sMessage == UNTICKED + "Allow") {
                     UserCommand(iAuth, g_sAppName + " allow", kAv, TRUE);
                 } else if (sMessage == UNTICKED + "Deny") {
                     UserCommand(iAuth, g_sAppName + " deny", kAv, TRUE);
                 } else if (sMessage == UNTICKED + "Stealth") {
                     UserCommand(iAuth, g_sAppName + " stealth on", kAv, TRUE);
                 } else if (sMessage == TICKED + "Stealth") {
                     UserCommand(iAuth, g_sAppName + " stealth off", kAv, TRUE);
                 } else if (sMessage == "SAVE") {
                     UserCommand(iAuth, g_sAppName + " add", kAv, TRUE);
                 } else if (sMessage == "REMOVE") {
                     DoMenuRemove(kAv, iAuth);
                 }
             }

             if (kID == g_kMenuRemoveID) {
                 // Got a menu response meant for us, extract the values
                 list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                 key kAv = (key)llList2String(lMenuParams, 0); // Avatar using the menu
                 string sMessage = llList2String(lMenuParams, 1); // Button label
                 //integer iPage = (integer)llList2String(lMenuParams, 2); // Menu page
                 integer iAuth = (integer)llList2String(lMenuParams, 3); // Auth level of avatar
                 // Request to switch to parent menu
                 if (sMessage == UPMENU) {
                     //give av the parent menu
                     llMessageLinked(LINK_THIS, iAuth, "menu " + SUBMENU_BUTTON, kAv);
                 } else if (~llListFindList(g_lRegions, [sMessage])) {
                     UserCommand(iAuth, g_sAppName + " remove " + sMessage, kAv, FALSE);
                     DoMenuRemove(kAv, iAuth);
                 }
             }
         }
    }

    changed(integer change) {
        if (change & CHANGED_REGION) {
            CheckRegion();
        }
    }
}
