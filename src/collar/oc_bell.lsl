// This file is part of OpenCollar.
// Copyright (c) 2009 - 2016 Cleo Collins, Nandana Singh, Satomi Ahn,
// Joy Stipe, Wendy Starfall, Medea Destiny, littlemousy,
// Romka Swallowtail, Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.


// Scans for sounds starting with: bell_
// Show/hide for elements named: Bell
// 2009-01-30 Cleo Collins - 1. draft

string g_sAppVersion = "¹⋅¹";

string g_sSubMenu = "Bell";
string g_sParentMenu = "Apps";
list g_lMenuIDs; // Three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

float g_fVolume = 0.5; // Volume of the bell
float g_fVolumeStep = 0.1; // Stepping for volume

float g_fNextRing;

integer g_bBellOn = 0; // Are we ringing. Off is 0, On = Auth of person which enabled
string g_sBellOn = "ON"; // Menu text of bell on
string g_sBellOff = "OFF"; // Menu text of bell off

integer g_bBellShow = FALSE; // Is the bell visible?
string g_sBellShow = "SHOW"; // Menu text of bell visible
string g_sBellHide = "HIDE"; // Menu text of bell hidden

//list g_listBellSounds = ["7b04c2ee-90d9-99b8-fd70-8e212a72f90d", "b442e334-cb8a-c30e-bcd0-5923f2cb175a", "1acaf624-1d91-a5d5-5eca-17a44945f8b0", "5ef4a0e7-345f-d9d1-ae7f-70b316e73742", "da186b64-db0a-bba6-8852-75805cb10008", "d4110266-f923-596f-5885-aaf4d73ec8c0","5c6dd6bc-1675-c57e-0847-5144e5611ef9","1dc1e689-3fd8-13c5-b57f-3fedd06b827a"]; // List with legacy bell sounds

list g_listBellSounds = [ // List with 4.0 bell sounds
    "ae3a836f-4d69-2b74-1d52-9c78a9106206",
    "503d2360-99f8-7a4a-8b89-43c5122927bd",
    "a3ff9ca6-8289-0007-5b6b-d4c993580a6b",
    "843adc44-1189-2d67-6f3a-72a80b3a9ed4",
    "4c84b9b7-b363-b501-c019-8eef5fb4d3c2",
    "3b95831e-8da5-597f-3b4d-713a03945cb6",
    "285b317c-23d1-de51-84bc-938eb3df9e46",
    "074b9b37-f6a3-a0a3-f40e-14bc57502435"
];
key g_kCurrentBellSound; // Current bell sound key
integer g_iCurrentBellSound; // Current bell sound sumber
integer g_iBellSoundCount; // Number of available bell sounds

key g_kLastToucher; // Store toucher key
float g_fNextTouch;  // Store time for the next touch

list g_lBellElements; // List with number of prims related to the bell
list g_lGlows; // 2-strided list [integer link_num, float glow]

key g_kWearer; // Key of the current wearer to reset only on owner changes

integer g_bHasControl = FALSE; // Do we have control over the keyboard?
integer g_bHidden; // Global hide

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;
integer SAY = 1004;

integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

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

string UPMENU = "BACK";
string g_sSettingToken = "bell_";
integer g_bHasBellPrims;
//string g_sGlobalToken = "global_";

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

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    } else {
        g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
    }
}

BellMenu(key kID, integer iAuth) {
    string sPrompt = "\n[Bell]\t" + g_sAppVersion + "\n\n";
    list lButtons;

    if (g_bBellOn > 0) {
        lButtons += g_sBellOff;
        sPrompt += "Bell is ringing";
    } else {
        lButtons+= g_sBellOn;
        sPrompt += "Bell is silent";
    }

    if (g_bBellShow) {
        lButtons += g_sBellHide;
        sPrompt += " and shown.\n\n";
    } else {
        lButtons += g_sBellShow;
        sPrompt += " and hidden.\n\n";
    }
    sPrompt += "Bell Volume:  \t" + (string)((integer)(g_fVolume * 10)) + "/10\n";
    sPrompt += "Active Sound:\t" + (string)(g_iCurrentBellSound + 1) + "/" + (string)g_iBellSoundCount + "\n";

    lButtons += ["Next Sound", "Vol +", "Vol -"];

    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "BellMenu");
}

SetBellElementAlpha() {
    if (g_bHidden) {
        return;
    }

    // Loop through stored links, setting color if element type is bell
    integer i;
    integer iLink;
    integer iLinksCount = llGetListLength(g_lBellElements);
    for (; i < iLinksCount; i++) {
        iLink = llList2Integer(g_lBellElements, i);
        llSetLinkAlpha(iLink, (float)g_bBellShow, ALL_SIDES);
        UpdateGlow(iLink, g_bBellShow);
    }
}

UpdateGlow(integer iLink, integer bShow) {
    if (bShow) {
        RestorePrimGlow(iLink);
    } else {
        SavePrimGlow(iLink);
        llSetLinkPrimitiveParamsFast(iLink, [
            PRIM_GLOW, ALL_SIDES, 0.0
        ]); // Set no glow;
    }
}

SavePrimGlow(integer iLink) {
    float fGlow = llList2Float(llGetLinkPrimitiveParams(iLink, [PRIM_GLOW, 0]), 0);
    integer iIndex = llListFindList(g_lGlows, [iLink]);
    if (~iIndex) {
        if (fGlow > 0) {
            g_lGlows = llListReplaceList(g_lGlows, [fGlow], iIndex + 1, iIndex + 1);
        } else {
            g_lGlows = llDeleteSubList(g_lGlows, iIndex, iIndex + 1);
        }
    } else {
        g_lGlows += [iLink, fGlow];
    }
}

RestorePrimGlow(integer iLink) {
    integer iIndex = llListFindList(g_lGlows, [iLink]);
    if (~iIndex) {
        llSetLinkPrimitiveParamsFast(iLink, [
            PRIM_GLOW, ALL_SIDES, llList2Float(g_lGlows, iIndex + 1)
        ]);
    }
}

BuildBellElementList() {
    list lParams;
    g_lBellElements = [];
    // Root prim is 1, so start at 2
    integer i = 2;
    for (; i <= llGetNumberOfPrims(); i++) {
        lParams = llParseString2List((string)llGetObjectDetails(llGetLinkKey(i), [OBJECT_DESC]), ["~"], []);
        if (llList2String(lParams, 0) == "Bell") {
            g_lBellElements += [i];
            //Debug("added " + (string)n + " to elements");
        }
    }

    // Remove my menu and myself if no bell elements are found
    if (llGetListLength(g_lBellElements)) {
        g_bHasBellPrims = TRUE;
        /*
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE,g_sSettingToken + "all","");
        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
        llRemoveInventory(llGetScriptName());
        */
    }
}

PrepareSounds() {
    integer i;
    string sSoundName;
    for (; i < llGetInventoryNumber(INVENTORY_SOUND); i++) {
        sSoundName = llGetInventoryName(INVENTORY_SOUND, i);
        if (llSubStringIndex(sSoundName,"bell_") == 0) {
            g_listBellSounds += llGetInventoryKey(sSoundName);
        }
    }
    g_iBellSoundCount = llGetListLength(g_listBellSounds);
    g_iCurrentBellSound = 0;
    g_kCurrentBellSound = llList2Key(g_listBellSounds, g_iCurrentBellSound);
}

UserCommand(integer iNum, string sStr, key kID) { // here iNum: auth value, sStr: user command, kID: avatar id
    // Debug("command: " + sStr);
    sStr = llToLower(sStr);
    if (sStr == "menu bell" || sStr == "bell" || sStr == g_sSubMenu) {
        BellMenu(kID, iNum);
    } else if (llSubStringIndex(sStr, "bell") == 0) {
        list lParams = llParseString2List(sStr, [" "], []);
        string sToken = llList2String(lParams, 1);
        string sValue = llList2String(lParams, 2);

        if (sToken == "volume") {
            integer n = (integer)sValue;
            if (n < 1) n = 1;
            if (n > 10) n = 10;
            g_fVolume = (float)n / 10;

            llPlaySound(g_kCurrentBellSound, g_fVolume);
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "vol=" + (string)llFloor(g_fVolume * 10), "");
            llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Bell volume set to " + (string)n, kID);
        } else if (sToken == "show" || sToken == "hide") {
            if (sToken == "show") {
                g_bBellShow = TRUE;
                llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The bell is now visible.", kID);
            } else  {
                g_bBellShow = FALSE;
                llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The bell is now invisible.", kID);
            }
            SetBellElementAlpha();
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "show=" + (string)g_bBellShow, "");
        } else if (sToken == "on") {
            if (iNum != CMD_GROUP) {
                if (!g_bBellOn) {
                    g_bBellOn = iNum;
                    if (!g_bHasControl) {
                        llRequestPermissions(g_kWearer, PERMISSION_TAKE_CONTROLS);
                    }
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=" + (string)g_bBellOn, "");
                    llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The bell rings now.", kID);
                }
            } else {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            }
        } else if (sToken == "off") {
            if (g_bBellOn && iNum != CMD_GROUP) {
                g_bBellOn = FALSE;
                if (g_bHasControl) {
                    llReleaseControls();
                    g_bHasControl = FALSE;
                }
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=" + (string)g_bBellOn, "");
                llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The bell is now quiet.", kID);
            } else {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            }
        } else if (sToken == "nextsound") {
            g_iCurrentBellSound = (g_iCurrentBellSound + 1) % g_iBellSoundCount;
            g_kCurrentBellSound = llList2Key(g_listBellSounds, g_iCurrentBellSound);
            llPlaySound(g_kCurrentBellSound, g_fVolume);
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "sound=" + (string)g_iCurrentBellSound, "");
            llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Bell sound changed, now using " + (string)(g_iCurrentBellSound + 1) + " of " + (string)g_iBellSoundCount + ".", kID);
        } else if (sToken == "ring") {
            g_fNextRing = llGetTime() + 1.0;
            llPlaySound(g_kCurrentBellSound, g_fVolume);
        }
    } else if (sStr == "rm bell") {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            Dialog(kID, "\nDo you really want to uninstall the " + g_sSubMenu + " App?", ["Yes", "No", "Cancel"], [], 0, iNum, "rmbell");
        }
    }
    //Debug("command executed");
}

default {
    on_rez(integer param) {
        g_kWearer = llGetOwner();
        if (g_bBellOn) {
            llRequestPermissions(g_kWearer, PERMISSION_TAKE_CONTROLS);
        }
    }

    state_entry() {
        //llSetMemoryLimit(36864);
        g_kWearer = llGetOwner();
        llResetTime(); // Reset script time used for ringing the bell in intervalls
        BuildBellElementList();
        PrepareSounds();
        SetBellElementAlpha();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        } else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sStr, kID);
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAV = llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMessage == UPMENU) {
                    llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAV);
                    return;
                } else if (sMessage == "Vol +") {
                    g_fVolume += g_fVolumeStep;
                    if (g_fVolume > 1.0) {
                        g_fVolume = 1.0;
                    }
                    llPlaySound(g_kCurrentBellSound, g_fVolume);
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "vol=" + (string)llFloor(g_fVolume * 10), "");
                } else if (sMessage == "Vol -") {
                    g_fVolume -= g_fVolumeStep;
                    if (g_fVolume < 0.1) {
                        g_fVolume = 0.1;
                    }
                    llPlaySound(g_kCurrentBellSound, g_fVolume);
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "vol=" + (string)llFloor(g_fVolume * 10), "");
                } else if (sMessage == "Next Sound") {
                    g_iCurrentBellSound = (g_iCurrentBellSound + 1) % g_iBellSoundCount;
                    g_kCurrentBellSound = llList2Key(g_listBellSounds, g_iCurrentBellSound);
                    llPlaySound(g_kCurrentBellSound, g_fVolume);
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "sound=" + (string)g_iCurrentBellSound, "");
                } else if (sMessage == g_sBellOff || sMessage == g_sBellOn) {
                    UserCommand(iAuth,"bell " + llToLower(sMessage), kAV);
                } else if (sMessage == g_sBellShow || sMessage == g_sBellHide) {
                    if (g_bHasBellPrims) {
                        g_bBellShow = !g_bBellShow;
                        SetBellElementAlpha();
                        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "show=" + (string)g_bBellShow, "");
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "This %DEVICETYPE% has no visual bell element.", kAV);
                    }
                } else if (sMenuType == "rmbell") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + g_sSubMenu + " App has been removed.", kAV);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
                            llRemoveInventory(llGetScriptName());
                        }
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + g_sSubMenu + " App remains installed.", kAV);
                    }
                    return;
                }

                BellMenu(kAV, iAuth);
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex + 3); // Remove stride from g_lMenuIDs
        } else if (iNum == LM_SETTING_RESPONSE) {
            integer i = llSubStringIndex(sStr, "=");
            string sToken = llGetSubString(sStr, 0, i - 1);
            string sValue = llGetSubString(sStr, i + 1, -1);
            i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "on") {
                    g_bBellOn = (integer)sValue;

                    if (g_bBellOn && !g_bHasControl) {
                        llRequestPermissions(g_kWearer, PERMISSION_TAKE_CONTROLS);
                    } else if (!g_bBellOn && g_bHasControl) {
                        llReleaseControls();
                        g_bHasControl = FALSE;
                    }
                } else if (sToken == "show") {
                    g_bBellShow = (integer)sValue;
                    SetBellElementAlpha();
                } else if (sToken == "sound") {
                    g_iCurrentBellSound = (integer)sValue;
                    g_kCurrentBellSound = llList2Key(g_listBellSounds, g_iCurrentBellSound);
                } else if (sToken == "vol") {
                    g_fVolume = (float)sValue / 10;
                }
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == CMD_OWNER && sStr == "runaway") {
            llSleep(4);
            SetBellElementAlpha();
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        }
    }

    control(key kID, integer iLevel, integer iEdge) {
        if (!g_bBellOn) {
            return;
        }

        // The user is pressing a movement key
        if (iEdge & (CONTROL_LEFT | CONTROL_RIGHT | CONTROL_DOWN | CONTROL_UP | CONTROL_FWD | CONTROL_BACK)) {
            llPlaySound(g_kCurrentBellSound, g_fVolume);
        }

        // The user is holding down a movement key and is running
        if ((iLevel & (CONTROL_FWD | CONTROL_BACK)) && (llGetAgentInfo(g_kWearer) & AGENT_ALWAYS_RUN)) {
            if (llGetTime() > g_fNextRing) {
                g_fNextRing = llGetTime() + 1.0;
                llPlaySound(g_kCurrentBellSound, g_fVolume);
            }
        }
    }

    collision_start(integer iNum) {
        if (g_bBellOn) {
            llPlaySound(g_kCurrentBellSound, g_fVolume);
        }
    }

    run_time_permissions(integer iPermissions) {
        if (iPermissions & PERMISSION_TAKE_CONTROLS) {
            //Debug("Bing");
            llTakeControls(CONTROL_DOWN | CONTROL_UP | CONTROL_FWD | CONTROL_BACK | CONTROL_LEFT | CONTROL_RIGHT | CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT, TRUE, TRUE);
            g_bHasControl = TRUE;
        }
    }

    touch_start(integer iNumDetected) {
        if (g_bBellShow && !g_bHidden && ~llListFindList(g_lBellElements, [llDetectedLinkNumber(0)])) {
            key kToucher = llDetectedKey(0);
            if (kToucher != g_kLastToucher || llGetTime() > g_fNextTouch) {
                // One touch every 10 secounds is enough dude
                g_fNextTouch = llGetTime() + 10.0;
                g_kLastToucher = kToucher;
                llPlaySound(g_kCurrentBellSound, g_fVolume);
                llMessageLinked(LINK_DIALOG, SAY, "1" + "secondlife:///app/agent/" + (string)kToucher + "/about plays with the trinket on %WEARERNAME%'s %DEVICETYPE%.", "");
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) {
            llResetScript();
        }

        if (iChange & CHANGED_LINK) {
            BuildBellElementList();
        }

        if (iChange & CHANGED_INVENTORY) {
            PrepareSounds();
        }

        if (iChange & CHANGED_COLOR) {
            integer bNewHide = !(integer)llGetAlpha(ALL_SIDES) ; // Check alpha
            if (g_bHidden != bNewHide) { // Check there's a difference to avoid infinite loop
                g_bHidden = bNewHide;
                SetBellElementAlpha(); // Update hide elements
            }
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
