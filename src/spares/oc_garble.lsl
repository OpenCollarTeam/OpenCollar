// This file is part of OpenCollar.
// Copyright (c) 2008 - 2015 Satomi Ahn, Nandana Singh, Joy Stipe,
// Wendy Starfall, Sumi Perl, littlemousy, Romka Swallowtail et al.
// Licensed under the GPLv2.  See LICENSE for full details.


// Original by Joy Stipe

//MESSAGE MAP
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_SAFEWORD = 510;

integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

// Messages for storing and retrieving values in the settings script
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

// Messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

// Messages for RLV commands
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002; // RLV plugins should clear their restriction lists upon receiving this message.

string g_sParentMenu = "Apps";
string GARBLE = "☐ Garble";
string UNGARBLE = "☒ Garble";

key g_kWearer;

integer g_iGarbleChan;
integer g_iGarbleListen;

string g_sSafeWord = "RED";
string g_sPrefix ;

integer bOn;

integer g_iBinder;
key g_kBinder;

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

Notify(key kID, string sMsg, integer bAlsoNotifyWearer) {
    llMessageLinked(LINK_DIALOG, NOTIFY, (string)bAlsoNotifyWearer + sMsg, kID);
}

string Name(key kId) {
    return "secondlife:///app/agent/" + (string)kId + "/inspect";
}

string Garble(string sIn) {
    // Return punctuations unharmed
    if (sIn == "." || sIn == "," || sIn == ";" || sIn == ":" || sIn == "?" || sIn == "!" || sIn == " " || sIn == "(" || sIn == ")") {
        return sIn;
    }

    // Phonetically garble letters that have a rather consistent sound through a gag
    if (sIn == "a" || sIn == "e" || sIn == "i" || sIn == "o" || sIn == "u" || sIn == "y") {
        return "eh";
    }

    if (sIn == "c" || sIn == "k" || sIn == "q") {
        return "k";
    }

    if (sIn == "m") {
        return "w";
    }

    if (sIn == "s" || sIn == "z") {
        return "shh";
    }

    if (sIn == "b" || sIn == "p" || sIn == "v") {
        return "f";
    }

    if (sIn == "x") {
        return "ek";
    }

    // Randomly garble everythsIng else
    if (llFloor(llFrand(10.0)) < 1) {
        return sIn;
    }

    return "nh";
}

Bind() {
    if (bOn) {
        return;
    }

    bOn = TRUE;
    llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + UNGARBLE, "");
    llMessageLinked(LINK_THIS, MENUNAME_REMOVE, g_sParentMenu + "|" + GARBLE, "");

    g_iGarbleListen = llListen(g_iGarbleChan, "", g_kWearer, "");
    llMessageLinked(LINK_RLV, RLV_CMD, "redirchat:" + (string)g_iGarbleChan + "=add,chatshout=n,sendim=n", NULL_KEY);
}

Release() {
    if (!bOn) {
        return;
    }

    bOn = FALSE;
    g_iBinder = CMD_EVERYONE;
    g_kBinder = NULL_KEY;
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "garble_Binder", "");
    llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + GARBLE, "");
    llMessageLinked(LINK_THIS, MENUNAME_REMOVE, g_sParentMenu + "|" + UNGARBLE, "");
    llMessageLinked(LINK_RLV, RLV_CMD, "chatshout=y,sendim=y,redirchat:" + (string)g_iGarbleChan + "=rem", NULL_KEY);
    llListenRemove(g_iGarbleListen);
}

UserCommand(integer iAuth, string sStr, key kID, integer bRemenu) {
    if (iAuth < CMD_OWNER || iAuth > CMD_WEARER) {
        return;
    } else if (llToLower(sStr) == "settings") {
        if (bOn) {
            Notify(kID, "Garbled.", FALSE);
        } else {
            Notify(kID, "Not Garbled.", FALSE);
        }
    } else if (sStr == "menu " + GARBLE || llToLower(sStr) == "garble on") {
        if (bOn && g_kBinder == kID) {
            Notify(kID, "I can't garble 'er any more, Jim! She's only a subbie!", FALSE);
        } else {
            g_iBinder = iAuth;
            g_kBinder = kID;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "garble_Binder=" + (string)kID + "," + (string)iAuth, "");
            Bind();
            if (kID != g_kWearer) {
                llOwnerSay(Name(kID) + " ordered you to be quiet");
            }
            Notify(kID, "%WEARERNAME%'s speech is now garbled", FALSE);
        }
    } else if (sStr == "menu " + UNGARBLE || llToLower(sStr) == "garble off") {
        if (iAuth <= g_iBinder) {
            Release();
            if (kID != g_kWearer) {
                llOwnerSay("You are free to speak again");
            }
            Notify(kID, "%WEARERNAME% is allowed to talk again", FALSE);
        } else {
            Notify(kID, "Sorry, the garbler can only be released by someone with an equal or higher rank than the person who set it.", FALSE);
        }
    }

    if (bRemenu) {
        llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kID);
    }
}

default {
    on_rez(integer iNum) {
        if (llGetOwner() != g_kWearer) {
            llResetScript();
        }
    }

    state_entry() {
        g_kWearer = llGetOwner();
        g_sPrefix = llGetSubString(llKey2Name(g_kWearer), 0, 1);
        Release();
        g_iGarbleChan = llRound(llFrand(499) + 100);
        //llMessageLinked(LINK_SAVE, LM_SETTING_REQUEST, "listener_safeword", "");
        //llMessageLinked(LINK_SAVE, LM_SETTING_REQUEST, "garble_Binder", "");
        //Debug("Starting");
    }

    link_message(integer iLink, integer iNum, string sMsg, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sMsg, kID, FALSE);
        } else if (iNum == MENUNAME_REQUEST && sMsg == g_sParentMenu) {
            if (bOn) {
                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + UNGARBLE, "");
            } else {
                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + GARBLE, "");
            }
        } else if (iNum == RLV_REFRESH) {
            if (bOn) {
                Bind();
            } else {
                Release();
            }
        } else if (iNum == RLV_CLEAR) {
            Release();
        } else if (iNum == CMD_SAFEWORD) {
            Release();
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParam = llParseString2List(sMsg, ["="], []);
            string sToken = llList2String(lParam, 0);
            if (sToken == "garble_Binder") {
                list lValue = llParseString2List(llList2String(lParam,1), [","], []);
                g_kBinder = (key)llList2String(lValue, 0);
                g_iBinder = (integer)llList2String(lValue, 1);
                Bind();
            } else if (sToken == "global_safeword") {
                g_sSafeWord = llList2String(lParam, 1);
            } else if (sToken == "global_prefix") {
                g_sPrefix = llList2String(lParam, 1);
            }
        } else if (iNum == LM_SETTING_EMPTY && sMsg == "garble_Binder") {
            Release();
        } else if (iNum == LINK_UPDATE) {
            if (sMsg == "LINK_DIALOG") LINK_DIALOG = iLink;
            else if (sMsg == "LINK_RLV") LINK_RLV = iLink;
            else if (sMsg == "LINK_SAVE") LINK_SAVE = iLink;
        } else if (iNum == REBOOT && sMsg == "reboot") {
            llResetScript();
        }
    }

    listen(integer iChan, string sName, key kID, string sMsg) {
        if (iChan == g_iGarbleChan && kID == g_kWearer) {
            string sSw = sMsg;

            if (llGetSubString(sSw, 0, 3) == "/me ") {
                sSw = llGetSubString(sSw, 4, -1);
            }

            if (llGetSubString(sSw, 0, 1) == "((" && llGetSubString(sSw, -2, -1) == "))") {
                sSw = llGetSubString(sSw, 2, -3);
            }

            if (llSubStringIndex(sSw, g_sPrefix) == 0) {
                sSw = llGetSubString(sSw, llStringLength(g_sPrefix), -1);
            }

            if (sSw == g_sSafeWord) {
                llMessageLinked(LINK_SET, CMD_SAFEWORD, "", "");
                llOwnerSay("You used your safeword, your owner will be notified you did.");
                llMessageLinked(LINK_DIALOG, NOTIFY_OWNERS, "Your sub %WEARERNAME% has used the safeword. Please check on their well-being in case further care is required.", "");
            } else {
                string sOut;
                integer i;
                for (i = 0; i < llStringLength(sMsg); i++) {
                    sOut += Garble(llToLower(llGetSubString(sMsg, i, i)));
                }

                string sMe = llGetObjectName();
                llSetObjectName("");
                llWhisper(0, "/me " + Name(g_kWearer) + " mumbles: " + sOut);
                llSetObjectName(sMe);
            }
        }
    }

    /*
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(TRUE);
                Debug("profiling restarted");
            }
        }
    }
    */
}
