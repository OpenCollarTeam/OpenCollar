// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Satomi Ahn, Nandana Singh, Joy Stipe,
// Wendy Starfall, Master Starship, Medea Destiny, littlemousy,
// Romka Swallowtail, Sumi Perl, Keiyra Aeon, Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.

string g_sAppVersion = "¹⋅⁴";

string g_sSubMenu = "Timer";
string g_sParentMenu = "Apps";

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

//integer ATTACHMENT_COMMAND = 602;
integer ATTACHMENT_FORWARD = 610;

//integer WEARERLOCKOUT = 620;

integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;

integer REBOOT  = -1000;

integer LINK_AUTH = 2;
integer LINK_DIALOG = 3;
integer LINK_RLV    = 4;
integer LINK_SAVE   = 5;
integer LINK_UPDATE = -10;

// integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_RESPONSE = 2002;
// integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

// Added by WhiteFire
integer TIMER_EVENT = -10000; // str = "start" or "end". For start, either "online" or "realtime".

string UPMENU = "BACK";
list g_lTimeButtons = [
    "RESET", "+00:01", "+00:05",
    "+00:30", "+03:00", "+24:00",
    "-00:01", "-00:05", "-00:30",
    "-03:00", "-24:00"
];

integer MAX_TIME = 0x7FFFFFFF;

list g_lTimes;
integer g_iTimesLength;
integer g_iCurrentTime;
integer g_iOnTime;
integer g_iLastTime;
integer g_iFirstOnTime;
integer g_iFirstRealTime;
integer g_iLastRez;
integer n; // For loops
string g_sMessage;

// These can change
integer REAL_TIME = 1;
integer REAL_TIME_EXACT = 5;
integer ON_TIME = 3;
integer ON_TIME_EXACT = 7;

integer g_iInterfaceChannel;
// End time keeper

integer g_iOnRunning;
integer g_iOnSetTime;
integer g_iOnTimeUpAt;
integer g_iRealRunning;
integer g_iRealSetTime;
integer g_iRealTimeUpAt;

integer g_bCollarLocked;
integer g_bUnlockCollar = FALSE;
integer g_bClearRLVRestrictions = FALSE;
integer g_bUnleash = FALSE;
integer g_bBoth = FALSE;
integer g_iWhoCanChangeTime = 504;
integer g_iWhoCanChangeLeash = 504;

integer g_iTimeChange;

list g_lLocalMenu;

key g_kWearer;

// Hhandles
list g_lMenuIDs;
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

Dialog(key kID, string sPrompt, list lChoices, list lUtility, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtility, "`") + "|" + (string)iAuth, kMenuID);

    integer i = llListFindList(g_lMenuIDs, [kID]);
    if (~i) {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], i, i + g_iMenuStride - 1);
    } else {
        g_lMenuIDs += [kID, kMenuID, sName];
    }
}

string Checkbox(integer iValue, string sLabel) {
    if (iValue) return "☑ " + sLabel;
    else return "☐ " + sLabel;
}

DoMenu(key keyID, integer iAuth) {
    //Debug("timeremaning:" + (string)(g_iOnTimeUpAt - g_iOnTime));
    string sPrompt = "\n[Legacy Timer]\t" + g_sAppVersion + "\n\nA frozen pizza takes ~12 min to bake.\n";

    sPrompt += "\n Online Timer: " + Int2Time(g_iOnSetTime);
    if (g_iOnRunning == 1) {
        sPrompt += "\n Online Timer: " + Int2Time(g_iOnTimeUpAt - g_iOnTime) + " left\n";
    } else {
        sPrompt += "\n Online Timer: not running\n";
    }

    sPrompt += "\n RL Timer: " + Int2Time(g_iRealSetTime);
    if (g_iRealRunning == 1) {
        sPrompt += "\n RL Timer: " + Int2Time(g_iRealTimeUpAt - g_iCurrentTime) + " left";
    } else {
        sPrompt += "\n RL Timer: not running";
    }

    list lButtons = [
        "Real Timer",
        "Online Timer",
        Checkbox(g_bBoth, "combined"),

        Checkbox(g_bUnlockCollar, "unlock"),
        Checkbox(g_bUnleash, "unleash"),
        Checkbox(g_bClearRLVRestrictions, "clear RLV")
    ];

    if (g_iRealRunning || g_iOnRunning) {
        lButtons += ["STOP", "RESET"];
    } else if (g_iRealSetTime || g_iOnSetTime) {
        lButtons += ["START", "RESET"];
    }

    Dialog(keyID, sPrompt, lButtons + g_lLocalMenu, [UPMENU], 0, iAuth, "menu");
}

DoOnMenu(key keyID, integer iAuth) {
    string sPrompt = "\n Online Time Settings\n";
    sPrompt += "\n Online Timer: " + Int2Time(g_iOnSetTime);

    if (g_iOnRunning) {
        sPrompt += "\n Online Timer: " + Int2Time(g_iOnTimeUpAt - g_iOnTime) + " left";
    } else {
        sPrompt += "\n Online Timer: not running";
    }

    Dialog(keyID, sPrompt, g_lTimeButtons, [UPMENU], 0, iAuth, "online");
}

DoRealMenu(key keyID, integer iAuth) {
    string sPrompt = "\n RL Time Settings\n";
    sPrompt += "\n RL timer: " + Int2Time(g_iRealSetTime);

    if (g_iRealRunning) {
        sPrompt += "\n RL Timer: " + Int2Time(g_iRealTimeUpAt - g_iCurrentTime) + " left";
    } else {
        sPrompt += "\n RL Timer: not running";
    }

    Dialog(keyID, sPrompt, g_lTimeButtons, [UPMENU], 0, iAuth, "real");
}

string Int2Time(integer iTime) {
    if (iTime < 0) {
        iTime = 0;
    }

    integer iSecs = iTime % 60;
    iTime = (iTime - iSecs) / 60;

    integer iMins = iTime % 60;
    iTime = (iTime - iMins) / 60;

    integer iHours = iTime % 24;

    integer iDays = (iTime - iHours) / 24;

    // This is the onley line that needs changing...
    return ((string)iDays + " days " +
            llGetSubString("0" + (string)iHours, -2, -1) + ":"+
            llGetSubString("0" + (string)iMins, -2, -1) + ":"+
            llGetSubString("0" + (string)iSecs, -2, -1)
    );
    //return (string)iDays + ":" + (string)iHours + ":" + (string)iMins + ":" + (string)iSecs;
}

TimerFinish() {
    if (g_bBoth && (g_iOnRunning == 1 || g_iRealRunning == 1)) {
        return;
    }

    //llMessageLinked(LINK_SET, WEARERLOCKOUT, "off", "");
    if (g_bUnlockCollar) {
        llMessageLinked(LINK_SET, CMD_OWNER, "unlock", g_kWearer);
    }

    if (g_bClearRLVRestrictions) {
        llMessageLinked(LINK_SET, CMD_OWNER, "clear", g_kWearer);
        if (!g_bUnlockCollar && g_bCollarLocked) {
            llSleep(2);
            llMessageLinked(LINK_SET, CMD_OWNER, "lock", g_kWearer);
        }
    }

    if (g_bUnleash && g_iWhoCanChangeTime <= g_iWhoCanChangeLeash) {
        llMessageLinked(LINK_SET, CMD_OWNER, "unleash", g_kWearer);
    }

    g_bUnlockCollar = FALSE;
    g_bClearRLVRestrictions = FALSE;
    g_bUnleash = FALSE;
    g_iOnSetTime = 0;
    g_iRealSetTime = 0;
    g_iOnRunning = 0;
    g_iRealRunning = 0;
    g_iOnTimeUpAt = 0;
    g_iRealTimeUpAt = 0;
    g_iWhoCanChangeTime = 504;

    llMessageLinked(LINK_AUTH, CMD_OWNER, "lockout false", "");
    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Yay! Timer expired!", g_kWearer);
    llMessageLinked(LINK_SET, TIMER_EVENT, "end", "");
}

TimerStart(integer iPerm) {
    // Do What has to be Done
    g_iWhoCanChangeTime = iPerm;

    if (g_iRealSetTime) {
        g_iRealTimeUpAt = g_iCurrentTime + g_iRealSetTime;

        //llMessageLinked(LINK_SET, WEARERLOCKOUT, "on", "");
        llMessageLinked(LINK_AUTH, CMD_OWNER, "lockout true", "");
        llMessageLinked(LINK_SET, TIMER_EVENT, "START", "RL");
        g_iRealRunning = 1;
    } else {
        g_iRealRunning = 3;
    }

    if (g_iOnSetTime) {
        g_iOnTimeUpAt = g_iOnTime + g_iOnSetTime;

        //llMessageLinked(LINK_SET, WEARERLOCKOUT, "on", "");
        llMessageLinked(LINK_AUTH, CMD_OWNER, "lockout true", "");
        llMessageLinked(LINK_SET, TIMER_EVENT, "START", "Online Timer");
        g_iOnRunning = 1;
    } else {
        g_iOnRunning = 3;
    }
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
    if (!((llGetInventoryPermMask(sName, MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName, MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}


UserCommand(integer iAuth, string sStr, key kID, integer bRemenu) {
    if ((g_iOnRunning || g_iRealRunning) && kID == g_kWearer) {
        if (!llSubStringIndex(llToLower(sStr), "timer")) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "You can't access here until the timer went off.", kID);
            return;
        }
    }

    if (llToLower(sStr) == "rm timer" && (iAuth == CMD_OWNER || kID ==  g_kWearer)) {
        Dialog(kID, "\nDo you really want to uninstall the " + g_sSubMenu + " App?", ["Yes","No","Cancel"], [], 0, iAuth, "rmtimer");
    }

    if (llToLower(sStr) == "timer" || sStr == "menu " + g_sSubMenu) {
        DoMenu(kID, iAuth);
    } else if (llGetSubString(sStr, 0, 5) == "timer ") {
        //Debug(sStr);
        string sMsg = llGetSubString(sStr, 6, -1);
        // We got a response for something we handle locally
        if (sMsg == "START") {
            TimerStart(iAuth);
            if (kID == g_kWearer) {
                bRemenu = FALSE;
            }
        } else if (sMsg == "STOP") {
            TimerFinish();
        } else if (sMsg == "RESET") {
            g_iRealSetTime = 0;
            g_iRealTimeUpAt = 0;
            g_iOnSetTime = 0;
            g_iOnTimeUpAt = 0;

            if (g_iRealRunning == 1 || g_iOnRunning == 1) {
                g_iRealRunning = 0;
                g_iOnRunning = 0;
                TimerFinish();
            }
        } else if (sMsg == "☒ combined") {
            g_bBoth = FALSE;
        } else if (sMsg == "☐ combined") {
            g_bBoth = TRUE;
        } else if (sMsg == "☑ unlock") {
            if (iAuth == CMD_OWNER) {
                g_bUnlockCollar = FALSE;
            } else {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            }
        } else if (sMsg == "☐ unlock") {
            if (iAuth == CMD_OWNER) {
                g_bUnlockCollar = TRUE;
            } else {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            }
        } else if (sMsg == "☑ clear RLV") {
            if (iAuth == CMD_WEARER) {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            } else {
                g_bClearRLVRestrictions = FALSE;
            }
        } else if (sMsg == "☐ clear RLV") {
            if (iAuth == CMD_WEARER) {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            } else {
                g_bClearRLVRestrictions = TRUE;
            }
        } else if (sMsg == "☑ unleash") {
            if (iAuth <= g_iWhoCanChangeLeash) {
                g_bUnleash = FALSE;
            } else {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            }
        } else if (sMsg == "☐ unleash") {
            if (iAuth <= g_iWhoCanChangeLeash) {
                g_bUnleash = TRUE;
            } else {
                llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            }
        } else if (llGetSubString(sMsg, 0, 11) == "Online Timer") {
            sMsg = "online" + llStringTrim(llGetSubString(sMsg, 12, -1), STRING_TRIM_HEAD);
        } else if (llGetSubString(sMsg, 0, 9) == "Real Timer") {
            sMsg = "real" + llStringTrim(llGetSubString(sMsg, 10, -1), STRING_TRIM_HEAD);
        }

        if (llGetSubString(sMsg, 0, 5) == "online") {
            sMsg = llStringTrim(llGetSubString(sMsg, 6, -1), STRING_TRIM_HEAD);
            if (iAuth <= g_iWhoCanChangeTime) {
                list lTimes = llParseString2List(llGetSubString(sMsg, 1, -1), [":"], []);
                if (sMsg == "RESET") {
                    g_iOnSetTime = 0;
                    g_iOnTimeUpAt = 0;
                    if (g_iOnRunning == 1) { // Unlock
                        g_iOnRunning = 0;

                        TimerFinish();
                    }
                } else if (llGetSubString(sMsg, 0, 0) == "+") {
                    g_iTimeChange = llList2Integer(lTimes, 0) * 60 * 60 + llList2Integer(lTimes, 1) * 60;
                    g_iOnSetTime += g_iTimeChange;

                    if (g_iOnRunning == 1) {
                        g_iOnTimeUpAt += g_iTimeChange;
                    } else if (g_iOnRunning == 3) {
                        g_iOnTimeUpAt = g_iOnTime + g_iOnSetTime;
                        g_iOnRunning = 1;
                    }
                } else if (llGetSubString(sMsg, 0, 0) == "-") {
                    g_iTimeChange = -(llList2Integer(lTimes, 0) * 60 * 60 + llList2Integer(lTimes, 1) * 60);
                    g_iOnSetTime += g_iTimeChange;

                    if (g_iOnSetTime < 0) {
                        g_iOnSetTime = 0;
                    }

                    if (g_iOnRunning == 1) {
                        g_iOnTimeUpAt += g_iTimeChange;
                        if (g_iOnTimeUpAt <= g_iOnTime) {
                            // Unlock
                            g_iOnRunning = 0;
                            g_iOnSetTime = 0;
                            g_iOnTimeUpAt = 0;

                            TimerFinish();
                        }
                    }
                } else if (llGetSubString(sMsg, 0, 0) == "=") {
                    g_iTimeChange = llList2Integer(lTimes, 0) * 60 * 60 + llList2Integer(lTimes, 1) * 60;
                    if (g_iTimeChange <= 0) {
                        return; // Use clear.
                    }

                    g_iOnSetTime = g_iTimeChange;

                    if (g_iOnRunning == 1) {
                        g_iOnTimeUpAt = g_iOnTime + g_iTimeChange;
                    } else if (g_iOnRunning == 3) {
                        g_iOnTimeUpAt = g_iOnTime + g_iTimeChange;
                        g_iOnRunning = 1;
                    }
                } else {
                    return;
                }
            }

            if (bRemenu) {
                DoOnMenu(kID, iAuth);
            }

            return;
        } else if (llGetSubString(sMsg, 0, 3) == "real") {
            sMsg = llStringTrim(llGetSubString(sMsg, 4, -1), STRING_TRIM_HEAD);
            list lTimes = llParseString2List(llGetSubString(sMsg, 1, -1), [":"], []);
            if (iAuth <= g_iWhoCanChangeTime) {
                if (sMsg == "RESET") {
                    g_iRealSetTime = 0;
                    g_iRealTimeUpAt = 0;

                    if (g_iRealRunning == 1) { // Unlock
                        g_iRealRunning = 0;

                        TimerFinish();
                    }
                } else if (llGetSubString(sMsg, 0, 0) == "+") {
                    g_iTimeChange = llList2Integer(lTimes, 0) * 60 * 60 + llList2Integer(lTimes, 1) * 60;
                    g_iRealSetTime += g_iTimeChange;

                    if (g_iRealRunning == 1) {
                        g_iRealTimeUpAt += g_iTimeChange;
                    } else if (g_iRealRunning == 3) {
                        g_iRealTimeUpAt = g_iCurrentTime + g_iRealSetTime;
                        g_iRealRunning = 1;
                    }
                } else if (llGetSubString(sMsg, 0, 0) == "-") {
                    g_iTimeChange = -(llList2Integer(lTimes, 0) * 60 * 60 + llList2Integer(lTimes, 1) * 60);
                    g_iRealSetTime += g_iTimeChange;

                    if (g_iRealSetTime < 0) {
                        g_iRealSetTime = 0;
                    }

                    if (g_iRealRunning == 1) {
                        g_iRealTimeUpAt += g_iTimeChange;
                        if (g_iRealTimeUpAt <= g_iCurrentTime) { // Unlock
                            g_iRealRunning = 0;
                            g_iRealSetTime = 0;
                            g_iRealTimeUpAt = 0;

                            TimerFinish();
                        }
                    }
                } else if (llGetSubString(sMsg, 0, 0) == "=") {
                    g_iTimeChange = llList2Integer(lTimes, 0) * 60 * 60 + llList2Integer(lTimes, 1) * 60;
                    if (g_iTimeChange <= 0) {
                        return; // Not handled.
                    }

                    g_iRealSetTime = g_iTimeChange;

                    if (g_iRealRunning == 1) {
                        g_iRealTimeUpAt = g_iCurrentTime + g_iRealSetTime;
                    } else if (g_iRealRunning == 3) {
                        g_iRealTimeUpAt = g_iCurrentTime + g_iRealSetTime;
                        g_iRealRunning = 1;
                    }
                } else {
                    return;
                }
            }

            if (bRemenu) {
                DoRealMenu(kID, iAuth);
            }

            return;
        }

        if (bRemenu) {
            DoMenu(kID, iAuth);
        }
    }
}


default {
    on_rez(integer iParam) {
        g_iLastTime = llGetUnixTime();
        g_iLastRez = g_iLastTime;
        llRegionSayTo(g_kWearer, g_iInterfaceChannel, "timer|sendtimers");

        /*
        if (g_iRealRunning == 1 || g_iOnRunning == 1) {
            llMessageLinked(LINK_SET, WEARERLOCKOUT, "on", "");
        }
        */
    }

    state_entry() {
        //llSetMemoryLimit(40960); // 2015-05-06 (4238 bytes free)
        PermsCheck();
        g_iLastTime = llGetUnixTime();
        llSetTimerEvent(1);
        g_kWearer = llGetOwner();
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer, 30, -1));
        if (g_iInterfaceChannel > 0) {
            g_iInterfaceChannel = -g_iInterfaceChannel;
        }
        g_iFirstOnTime = MAX_TIME;
        g_iFirstRealTime = MAX_TIME;
        llRegionSayTo(g_kWearer, g_iInterfaceChannel, "timer|sendtimers");
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sStr, kID, FALSE);
        } else if (iNum == ATTACHMENT_FORWARD) {
            list lInfo = llParseString2List (sStr, ["|"], []);
            if (llList2String(lInfo, 0) != "timer") {
                return;
            }
            //Debug(sStr);
            string sCommand = llList2String(lInfo, 1);
            integer iType = llList2Integer(lInfo, 2);
            if (sCommand == "settimer") {
                // Should check values but I am not yet.
                if (iType == REAL_TIME) {
                    integer iNewTime = llList2Integer(lInfo, 3) + g_iCurrentTime;
                    g_lTimes += [REAL_TIME, iNewTime];
                    if (g_iFirstRealTime > iNewTime) {
                        g_iFirstRealTime = iNewTime;
                    }
                    g_sMessage = "timer|timeis|" + (string)REAL_TIME + "|" + (string)g_iCurrentTime;
                } else if (iType == REAL_TIME_EXACT) {
                    integer iNewTime = llList2Integer(lInfo, 3);
                    g_lTimes += [REAL_TIME, iNewTime];
                    if (g_iFirstRealTime > iNewTime) {
                        g_iFirstRealTime = iNewTime;
                    }
                } else if (iType == ON_TIME) {
                    integer iNewTime = llList2Integer(lInfo, 3) + g_iOnTime;
                    g_lTimes += [ON_TIME, iNewTime];
                    if (g_iFirstOnTime > iNewTime) {
                        g_iFirstOnTime = iNewTime;
                    }
                    g_sMessage = "timer|timeis|" + (string)ON_TIME + "|" + (string)g_iOnTime;
                } else if (iType == ON_TIME_EXACT) {
                    integer iNewTime = llList2Integer(lInfo, 3) + g_iOnTime;
                    g_lTimes += [ON_TIME, iNewTime];
                    if (g_iFirstOnTime > iNewTime) {
                        g_iFirstOnTime = iNewTime;
                    }
                }
            } else if (sCommand == "gettime") {
                if (iType == REAL_TIME) {
                    g_sMessage = "timer|timeis|" + (string)REAL_TIME + "|" + (string)g_iCurrentTime;
                } else if (iType == ON_TIME) {
                    g_sMessage = "timer|timeis|" + (string)ON_TIME + "|" + (string)g_iOnTime;
                }
            } else {
                return;
            }

            llRegionSayTo(g_kWearer, g_iInterfaceChannel, g_sMessage);
        } else if (iNum == LM_SETTING_EMPTY) {
            if (sStr == "leash_leashedto") {
                g_iWhoCanChangeLeash = 504;
            }

            if (sStr == "global_locked") {
                g_bCollarLocked = 0;
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            if (sToken == "global_locked") {
                g_bCollarLocked = (integer)sValue;
            } else if (sToken == "leash_leashedto") {
                g_iWhoCanChangeLeash = (integer)llList2String(llParseString2List(sValue, [","], []), 1);
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            // Our parent menu requested to receive buttons, so send ours
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lLocalMenu = []; // Flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
        } else if (iNum == MENUNAME_RESPONSE) {
            // A button is sned ot be added to a plugin
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) {
                // Someone wants to stick something in our menu
                string sButton = llList2String(lParts, 1);
                if (llListFindList(g_lLocalMenu, [sButton]) == -1) {
                    g_lLocalMenu = llListSort(g_lLocalMenu + [sButton], 1, TRUE);
                }
            }
        } else if (iNum == MENUNAME_REMOVE) {
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) {
                string sButton = llList2String(lParts, 1);
                integer iIndex = llListFindList(g_lLocalMenu, [sButton]);
                if (~iIndex) {
                    g_lLocalMenu = llDeleteSubList(g_lLocalMenu, iIndex, iIndex);
                }
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex == -1) {
                return;
            }

            // This is one of our menus
            string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMsg = llList2String(lMenuParams, 1);
            //integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);

            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

            if (sMenu == "menu") {
                if (sMsg == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                } else if (sMsg == "Real Timer") {
                    DoRealMenu(kAv, iAuth);
                } else if (sMsg == "Online Timer") {
                    DoOnMenu(kAv, iAuth);
                } else if (~llListFindList(g_lLocalMenu, [sMsg])) {
                    llMessageLinked(LINK_SET, iAuth, "menu " + sMsg, kAv);
                } else {
                    UserCommand(iAuth, "timer " + sMsg, kAv, TRUE);
                }
            } else if (sMenu == "real") {
                if (sMsg == UPMENU) {
                    DoMenu(kAv, iAuth);
                } else {
                    UserCommand(iAuth, "timer real" + sMsg, kAv, TRUE);
                }
            } else if (sMenu == "online") {
                if (sMsg == UPMENU) {
                    DoMenu(kAv, iAuth);
                } else {
                    UserCommand(iAuth, "timer online" + sMsg, kAv, TRUE);
                }
            } else if (sMenu == "rmtimer") {
                if (sMsg == "Yes") {
                    llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                    llMessageLinked(LINK_DIALOG, NOTIFY, "1" + g_sSubMenu + " App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
                        llRemoveInventory(llGetScriptName());
                    }
                } else {
                    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + g_sSubMenu + " App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_AUTH") LINK_AUTH = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        }
    }

    timer() {
        g_iCurrentTime = llGetUnixTime();

        if (g_iCurrentTime < g_iLastRez + 60) {
            return;
        }

        if (g_iCurrentTime - g_iLastTime < 60) {
            g_iOnTime += g_iCurrentTime - g_iLastTime;
        }

        if (g_iOnTime >= g_iFirstOnTime) {
            // Could store which is need but if both are trigered it will have to send both anyway I prefer not to check for that.
            g_sMessage = "timer|timeis|" + (string)ON_TIME + "|" + (string)g_iOnTime;
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, g_sMessage);
            g_iFirstOnTime = MAX_TIME;
            g_iTimesLength = llGetListLength(g_lTimes);
            for (n = 0; n < g_iTimesLength; n += 2) {
                // Send notice and find the next time.
                if (llList2Integer(g_lTimes, n) == ON_TIME) {
                    while (llList2Integer(g_lTimes, n + 1) <= g_iOnTime && llList2Integer(g_lTimes, n) == ON_TIME && g_lTimes != []) {
                        g_lTimes = llDeleteSubList(g_lTimes, n, n + 1);
                        g_iTimesLength = llGetListLength(g_lTimes);
                    }

                    if (llList2Integer(g_lTimes, n) == ON_TIME && llList2Integer(g_lTimes, n + 1) < g_iFirstOnTime) {
                        g_iFirstOnTime = llList2Integer(g_lTimes, n + 1);
                    }
                }
            }
        }

        if (g_iCurrentTime >= g_iFirstRealTime) {
            // Could store which is need but if both are trigered it will have to send both anyway I prefer not to check for that.
            g_sMessage = "timer|timeis|" + (string)REAL_TIME + "|" + (string)g_iCurrentTime;
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, g_sMessage);
            g_iFirstRealTime = MAX_TIME;
            g_iTimesLength = llGetListLength(g_lTimes);
            for (n = 0; n < g_iTimesLength; n += 2) {
                // Send notice and find the next time.
                if (llList2Integer(g_lTimes, n) == REAL_TIME) {
                    while (llList2Integer(g_lTimes, n + 1) <= g_iCurrentTime && llList2Integer(g_lTimes, n) == REAL_TIME) {
                        g_lTimes = llDeleteSubList(g_lTimes, n, n + 1);
                        g_iTimesLength = llGetListLength(g_lTimes);
                    }

                    if (llList2Integer(g_lTimes, n) == REAL_TIME && llList2Integer(g_lTimes, n + 1) < g_iFirstRealTime) {
                        g_iFirstRealTime = llList2Integer(g_lTimes, n + 1);
                    }
                }
            }
        }

        if (g_iOnRunning == 1 && g_iOnTimeUpAt <= g_iOnTime) {
            g_iOnRunning = 0;
            TimerFinish();
        }

        if (g_iRealRunning == 1 && g_iRealTimeUpAt <= g_iCurrentTime) {
            g_iRealRunning = 0;
            TimerFinish();
        }

        g_iLastTime = g_iCurrentTime;
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            PermsCheck();
        }

        if (iChange & CHANGED_OWNER) {
            llResetScript();
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
