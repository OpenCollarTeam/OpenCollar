// This file is part of OpenCollar.
// Copyright (c) 2008 - 2016 Satomi Ahn, Nandana Singh, Joy Stipe,
// Wendy Starfall, Master Starship, littlemousy, Romka Swallowtail,
// Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.

string g_sAppVersion = "¹⋅¹";

string g_sParentMenu = "RLV";

list g_lSettings; // 3 strided list of prefix,option,value
list g_lChangedCategories; // List of categories that changed since last saved

integer g_lRLVCommandsStride = 4;
list g_lRLVCommands = [ //4 strided list of menuname,command,prettyname,description
    "rlvtp_", "tplm", "Landmark", "Teleport via Landmark",
    "rlvtp_", "tploc", "Slurl", "Teleport via Slurl/Map",
    "rlvtp_", "tplure", "Lure", "Teleport via offers",
    "rlvtp_", "showworldmap", "Map", "View World-map",
    "rlvtp_", "showminimap", "Mini-map", "View Mini-map",
    "rlvtp_", "showloc", "Location", "See current location",
    "rlvtalk_", "sendchat", "Chat", "Ability to Chat",
    "rlvtalk_", "chatshout", "Shout", "Ability to Shout",
    "rlvtalk_", "chatnormal", "Whisper", "Forced to Whisper",
    "rlvtalk_", "startim", "Start IMs", "Initiate IM Sessions",
    "rlvtalk_", "sendim", "Send IMs", "Respond to IMs",
    "rlvtalk_", "recvim", "Get IMs", "Receive IMs",
    "rlvtalk_", "recvchat", "See Chat", "Receive Chat",
    "rlvtalk_", "recvemote", "See Emote", "Receive Emotes",
    "rlvtalk_", "emote", "Emote", "Short Emotes if Chat blocked",
    "rlvtouch_", "fartouch", "Far", "Touch objects >1.5m away",
    "rlvtouch_", "touchworld", "World", "Touch in-world objects",
    "rlvtouch_", "touchattach", "Self", "Touch your attachments",
    "rlvtouch_", "touchattachother", "Others", "Touch others' attachments",
    "rlvmisc_", "shownames", "Names", "See Avatar Names",
    "rlvmisc_", "fly", "Fly", "Ability to Fly",
    "rlvmisc_", "edit", "Edit", "Edit Objects",
    "rlvmisc_", "rez", "Rez", "Rez Objects",
    "rlvmisc_", "showinv", "Inventory", "View Inventory",
    "rlvmisc_", "viewnote", "Notecards", "View Notecards",
    "rlvmisc_", "viewscript", "Scripts", "View Scripts",
    "rlvmisc_", "viewtexture", "Textures", "View Textures",
    "rlvmisc_", "showhovertextworld", "Hovertext", "See hovertext like titles",
    "rlvview_", "camdistmax:0", "Mouselook", "Leave Mouselook",
    "rlvview_", "camunlock", "Alt Zoom", "Alt zoom/pan around",
    "rlvview_", "camdrawalphamax:1", "See", "See anything at all"
];

list g_lMenuHelpMap = [
    "rlvstuff_", "Stuff",
    "rlvtp_", "Travel",
    "rlvtalk_", "Talk",
    "rlvtouch_", "Touch",
    "rlvmisc_", "Misc",
    "rlvview_", "View"
];

string TURNON = "✔";
string TURNOFF = "✘";

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;

//integer LOADPIN = -1904;
integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE = 2000; // Scripts send messages on this channel to have settings saved
// str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001; // When startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; // The httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003; // Delete token from DB
//integer LM_SETTING_EMPTY = 2004; // Sent by setting script when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001; //RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002; //RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // Send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // Send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";

key g_kWearer;

integer g_bRLVOn = FALSE;

list g_lMenuIDs; // 3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
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

Notify(key kID, string sMsg, integer bAlsoNotifyWearer) {
    llMessageLinked(LINK_DIALOG, NOTIFY, (string)bAlsoNotifyWearer + sMsg, kID);
}

StuffMenu(key kID, integer iAuth) {
    Dialog(kID, "\n[Legacy RLV Stuff]\t" + g_sAppVersion, ["Misc", "Touch", "Talk", "Travel", "View"], [UPMENU], 0, iAuth, "rlvstuff");
}

Menu(key kID, integer iAuth, string sMenuName) {
    //Debug("Making menu " + sMenuName);
    if (!g_bRLVOn) {
        Notify(kID, "RLV features are now disabled in this %DEVICETYPE%. You can enable those in RLV submenu. Opening it now.", FALSE);
        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kID);
        return;
    }

    // Build prompt showing current settings
    // Make enable/disable buttons
    integer n;
    string sPrompt;
    list lButtons;

    n = llListFindList(g_lMenuHelpMap,[sMenuName]);
    if (~n) {
        sPrompt = "\n[Legacy RLV " + llList2String(g_lMenuHelpMap, n + 1) + "]\n";
    }

    integer iStop = llGetListLength(g_lRLVCommands);
    for (n = 0; n < iStop; n += g_lRLVCommandsStride) {
        if (llList2String(g_lRLVCommands, n) == sMenuName) {
            // See if there's a setting for this in the settings list
            string sCmd = llList2String(g_lRLVCommands, n + 1);
            string sPretty = llList2String(g_lRLVCommands, n + 2);
            string sDesc = llList2String(g_lRLVCommands, n + 3);
            integer iIndex = llListFindList(g_lSettings, [sCmd]);

            if (~iIndex) {
                // If this cmd not set, then give button to enable
                lButtons += [TURNOFF + " " + sPretty];
                sPrompt += "\n" + sPretty + " = Enabled (" + sDesc + ")";
            } else {
                // Else this cmd is set, then show in prompt, and make button do opposite
                // Get value of setting
                string sValue = llList2String(g_lSettings, iIndex + 1);
                if (sValue == "y") {
                    lButtons += [TURNOFF + " " + sPretty];
                    sPrompt += "\n" + sPretty + " = Enabled (" + sDesc + ")";
                } else if (sValue == "n") {
                    lButtons += [TURNON + " " + sPretty];
                    sPrompt += "\n" + sPretty + " = Disabled (" + sDesc + ")";
                }
            }
        }
    }

    // Give an Allow All button
    lButtons += [TURNON + " All"];
    lButtons += [TURNOFF + " All"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, sMenuName);
}

SetSetting(string sCategory, string sOption, string sValue) {
    integer iIndex = llListFindList(g_lSettings, [sCategory, sOption]);
    if (~iIndex) {
        g_lSettings = llListReplaceList(g_lSettings, [sCategory, sOption, sValue], iIndex, iIndex + 2); // There is already a setting, change it
    } else {
        g_lSettings += [sCategory, sOption, sValue]; // No setting exists.. add one
    }

    if (!~llListFindList(g_lChangedCategories, [sCategory])) {
        g_lChangedCategories += sCategory; // If there are no previous changes for thi category, add the category to the list of changed ones
    }
}

UpdateSettings() { // Build one big string from the settings list, and send to to the viewer to reset rlv settings
    //llOwnerSay("TP settings: " + llDumpList2String(lSettings, ", "));
    integer iSettingsLength = llGetListLength(g_lSettings);
    //Debug("Applying " + (string)(iSettingsLength / 3) + " settings");
    if (iSettingsLength > 0) {
        list lTempSettings;
        string sTempRLVSetting;
        string sTempRLVValue;
        integer n;
        list lNewList;
        for (n = 0; n < iSettingsLength; n = n + 3) {
            sTempRLVSetting = llList2String(g_lSettings, n + 1);
            sTempRLVValue = llList2String(g_lSettings, n + 2);

            lNewList += sTempRLVSetting + "=" + sTempRLVValue;

            if (sTempRLVValue != "y") {
                lTempSettings += [sTempRLVSetting, sTempRLVValue];
            }
        }

        // Output that string to viewer
        llMessageLinked(LINK_RLV, RLV_CMD, llDumpList2String(lNewList, ", "), NULL_KEY);
    }
}

SaveSettings() {
    list lCategorySettings;
    while (llGetListLength(g_lChangedCategories)) {
        lCategorySettings = [];
        integer iNumSettings = llGetListLength(g_lSettings);
        while (iNumSettings) { // Go through the list of all settings, and pull out any belonging to this category, store in temp list.
            iNumSettings -= 3;
            string sCategory = llList2String(g_lSettings, iNumSettings);
            if (sCategory == llList2String(g_lChangedCategories, -1)) {
                lCategorySettings += [llList2String(g_lSettings, iNumSettings + 1), llList2String(g_lSettings, iNumSettings + 2)];
            }
        }

        if (llGetListLength(lCategorySettings) > 0) {
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, llList2String(g_lChangedCategories,-1) + "List=" + llDumpList2String(lCategorySettings, ", "), "");
        } else {
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, llList2String(g_lChangedCategories,-1) + "List", "");
        }

        g_lChangedCategories = llDeleteSubList(g_lChangedCategories, -1, -1);
    }
}

ClearSettings(string sCategory) { // Clear settings list
    integer iNumSettings = llGetListLength(g_lSettings);
    while (iNumSettings) {
        iNumSettings -= 3;
        string sCurrCategory = llList2String(g_lSettings, iNumSettings);
        if (sCurrCategory == sCategory || sCategory == "") {
            g_lSettings = llDeleteSubList(g_lSettings, iNumSettings, iNumSettings + 2);
            if (!~llListFindList(g_lChangedCategories, [sCurrCategory])) {
                g_lChangedCategories += sCurrCategory; // If there are no previous changes for thi category, add the category to the list of changed ones
            }
        }
    }

    SaveSettings();
    // Main RLV script will take care of sending @clear to viewer
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}


UserCommand(integer iNum, string sStr, key kID, string sFromMenu) {
    if (iNum > CMD_WEARER) {
        return; // Nothing for lower than wearer here
    }

    sStr = llStringTrim(sStr, STRING_TRIM);
    string sStrLower = llToLower(sStr);

    if (sStrLower == "rm rlvstuff") {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            Dialog(kID, "\nDo you really want to uninstall Legacy RLV Stuff?", ["Yes", "No", "Cancel"], [], 0, iNum, "rmrlvstuff");
        }
    } else if (sStrLower == "rlvtp" || sStrLower == "menu travel") Menu(kID, iNum, "rlvtp_");
    else if (sStrLower == "rlvtalk" || sStrLower == "menu talk") Menu(kID, iNum, "rlvtalk_");
    else if (sStrLower == "rlvtouch" || sStrLower == "menu touch") Menu(kID, iNum, "rlvtouch_");
    else if (sStrLower == "rlvmisc" || sStrLower == "menu misc") Menu(kID, iNum, "rlvmisc_");
    else if (sStrLower == "rlvview" || sStrLower == "menu view") Menu(kID, iNum, "rlvview_");
    else if (sStrLower == "rlvstuff" || sStrLower == "menu stuff") StuffMenu(kID, iNum);
    else {
        // Do simple pass through for chat commands
        // Since more than one RLV command can come on the same line, loop through them
        list lItems = llParseString2List(sStr, [", "], []);
        integer n;
        integer iStop = llGetListLength(lItems);
        for (n = 0; n < iStop; n++) {
            // Split off the parameters (anything after a : or =)
            // And see if the thing being set concerns us
            string sThisItem = llList2String(lItems, n);
            string sBehavior = llList2String(llParseString2List(sThisItem, ["="], []), 0);
            integer iBehaviourIndex = llListFindList(g_lRLVCommands, [sBehavior]);

            if (~iBehaviourIndex) {
                string sCategory = llList2String(g_lRLVCommands, iBehaviourIndex - 1);
                if (llGetSubString(sCategory, -1, -1) == "_") {
                    //Debug(sBehavior + " is a behavior that we handle, from the " + sCategory + " category.");
                    // Filter commands from wearer, if wearer is not owner
                    if (iNum == CMD_WEARER) {
                        llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                    } else {
                        string sOption = llList2String(llParseString2List(sThisItem, ["="], []), 0);
                        string sValue = llList2String(llParseString2List(sThisItem, ["="], []), 1);
                        SetSetting(sCategory, sOption, sValue);
                    }
                }
            } else if (sBehavior == "clear" && iNum == CMD_OWNER) {
                ClearSettings("");
            }
            //else Debug("We don't handle " + sBehavior);
        }

        if (llGetListLength(g_lChangedCategories)) {
            UpdateSettings();
            SaveSettings();
        }

        if (sFromMenu != "") {
            Menu(kID, iNum, sFromMenu);
        }
    }
}

default {
    on_rez(integer iParam) {
        llSetTimerEvent(0.0); // Timer will be called by recieved settings as necessary
    }

    state_entry() {
        g_kWearer = llGetOwner();
        PermsCheck();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|Stuff", "");
        } else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) {
            UserCommand(iNum, sStr, kID, "");
        } else if (iNum == LM_SETTING_RESPONSE) {
            // This is tricky since our db value contains equals signs
            // Split string on both comma and equals sign
            // First see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            string sCategory = llList2String(llParseString2List(sToken, ["_"], []), 0) + "_";
            if (~llListFindList(g_lMenuHelpMap, [sCategory])) {
                //Debug("got settings token: " + sCategory);
                sToken = llList2String(llParseString2List(sToken, ["_"], []), 1);
                if (sToken == "List") {
                    // Throw away first element
                    // Everything else is real settings (should be even number)
                    ClearSettings(sCategory);
                    list lNewSettings = llParseString2List(sValue, [", "], []);
                    while (llGetListLength(lNewSettings)) {
                        list lTempSettings = [sCategory, llList2String(lNewSettings, -2), llList2String(lNewSettings, -1)];
                        //Debug(llDumpList2String(lTempSettings, "  -  "));
                        g_lSettings += lTempSettings;
                        lNewSettings = llDeleteSubList(lNewSettings, -2, -1);
                    }
                    UpdateSettings();
                }
            }
            //else Debug("not my token: " + sCategory);
        } else if (iNum == RLV_REFRESH) { // rlvmain just started up.  Tell it about our current restrictions
            g_bRLVOn = TRUE;
            UpdateSettings();
        } else if (iNum == RLV_CLEAR) {
            ClearSettings(""); // Clear settings list
        } else if (iNum == RLV_OFF) {
            g_bRLVOn = FALSE; // rlvoff -> we have to turn the menu off too
        } else if (iNum == RLV_ON) {
            g_bRLVOn = TRUE; // rlvon -> we have to turn the menu on again
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) { // It's one of our menus
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);

                // Remove stride from g_lMenuIDs
                // We have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenu == "rmrlvstuff") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_RLV, MENUNAME_REMOVE, g_sParentMenu + "|Stuff", "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Legacy RLV Stuff has been removed.", kAv);
                        ClearSettings("");

                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
                            llRemoveInventory(llGetScriptName());
                        }
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Legacy RLV Stuff remains installed.", kAv);
                    }
                } else if (sMenu == "rlvstuff") {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_RLV, iAuth, "menu " + g_sParentMenu, kAv);
                    } else {
                        UserCommand(iAuth, "menu " + sMessage, kAv, "");
                    }
                } else if (sMessage == UPMENU) {
                    StuffMenu(kAv,iAuth);
                } else {
                    // We got a command to enable or disable something, like "Enable LM"
                    // Get the actual command name by looking up the pretty name from the message
                    list lParams = llParseString2List(sMessage, [" "], []);
                    string sSwitch = llList2String(lParams, 0);
                    string sCmd = llDumpList2String(llDeleteSubList(lParams, 0, 0), " ");
                    integer iIndex = llListFindList(g_lRLVCommands, [sCmd]);

                    if (sCmd == "All") {
                        // Handle the "Allow All" and "Forbid All" commands
                        string sOnOff;
                        // Decide whether we need to switch to "y" or "n"
                        if (sSwitch == TURNOFF) {
                            sOnOff = "n"; // Enable all functions (ie, remove all restrictions
                        } else if (sSwitch == TURNON) {
                            sOnOff = "y";
                        }
                        // Loop through rlvcmds to create list
                        string sOut;
                        integer n;
                        integer iStop = llGetListLength(g_lRLVCommands);
                        for (n = 0; n < iStop; n += g_lRLVCommandsStride) {
                            if (llList2String(g_lRLVCommands, n) == sMenu) {
                                if (sOut != "") {
                                    sOut += ", "; // Prefix all but the first value with a comma, so we have a comma-separated list
                                }

                                sOut += llList2String(g_lRLVCommands, n+1) + "=" + sOnOff;
                            }
                        }

                        UserCommand(iAuth, sOut, kAv, sMenu);
                    } else if (~iIndex && llList2String(g_lRLVCommands,iIndex - 2) == sMenu) {
                        string sOut = llList2String(g_lRLVCommands, iIndex - 1);
                        sOut += "=";
                        if (sSwitch == TURNON) {
                            sOut += "y";
                        } else if (sSwitch == TURNOFF) {
                            sOut += "n";
                        }

                        // Send rlv command out through auth system as though it were a chat command, just to make sure person who said it has proper authority
                        UserCommand(iAuth, sOut, kAv, sMenu);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            // Remove stride from g_lMenuIDs
            // We have to subtract from the index because the dialog id comes in the middle of the stride
            if (~iMenuIndex) {
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            PermsCheck();
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
