// This file is part of OpenCollar.
// Copyright (c) 2008 - 2015 Satomi Ahn, Nandana Singh, Joy Stipe,     
// Wendy Starfall, Sumi Perl, littlemousy, Romka Swallowtail et al.    
// Licensed under the GPLv2.  See LICENSE for full details. 


//original by Joy Stipe

//MESSAGE MAP
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_SAFEWORD = 510;

integer NOTIFY = 1002;
integer NOTIFY_OWNERS=1003;
integer REBOOT = -1000;

// messages for storing and retrieving values in the settings script
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

// messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

// messages for RLV commands
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

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
integer g_iProfiled;
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

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    llMessageLinked(LINK_THIS,NOTIFY,(string)iAlsoNotifyWearer+sMsg,kID);
}

string Name(key id) {
    return "secondlife:///app/agent/"+(string)id+"/inspect";
}

string garble(string in) {
    // return punctuations unharmed
    if (in == "." || in == "," || in == ";" || in == ":" || in == "?") return in;
    if (in == "!" || in == " " || in == "(" || in == ")") return in;
    // phonetically garble letters that have a rather consistent sound through a gag
    if (in == "a" || in == "e" || in == "i" || in == "o" || in == "u" || in == "y") return "eh";
    if (in == "c" || in == "k" || in == "q") return "k";
    if (in == "m") return "w";
    if (in == "s" || in == "z") return "shh";
    if (in == "b" || in == "p" || in == "v") return "f";
    if (in == "x") return "ek";
    // randomly garble everything else
    if (llFloor(llFrand(10.0) < 1)) return in;
    return "nh";
}

bind() {
    if (bOn) return ;
    bOn = TRUE;
    llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu+"|"+UNGARBLE, "");
    llMessageLinked(LINK_THIS, MENUNAME_REMOVE, g_sParentMenu+"|"+GARBLE, "");

    g_iGarbleListen = llListen(g_iGarbleChan, "", g_kWearer, "");
    llMessageLinked(LINK_THIS, RLV_CMD, "redirchat:"+(string)g_iGarbleChan+"=add,chatshout=n,sendim=n", NULL_KEY);
}

release() {
    if (!bOn) return;
    bOn = FALSE;
    g_iBinder = CMD_EVERYONE;
    g_kBinder = NULL_KEY;
    llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "garble_Binder", "");
    llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + GARBLE, "");
    llMessageLinked(LINK_THIS, MENUNAME_REMOVE, g_sParentMenu + "|" + UNGARBLE, "");
    llMessageLinked(LINK_THIS, RLV_CMD, "chatshout=y,sendim=y,redirchat:"+(string)g_iGarbleChan+"=rem", NULL_KEY);
    llListenRemove(g_iGarbleListen);
}

UserCommand(integer iAuth, string sStr, key kID, integer iMenu) {
    if (iAuth < CMD_OWNER || iAuth > CMD_WEARER) return;
    else if (llToLower(sStr) == "settings") {
        if (bOn) Notify(kID, "Garbled.", FALSE);
        else Notify(kID, "Not Garbled.", FALSE);
    } else if (sStr == "menu "+GARBLE || llToLower(sStr) == "garble on") {
        if (bOn && g_kBinder == kID) Notify(kID, "I can't garble 'er any more, Jim! She's only a subbie!", FALSE);
        else {
            g_iBinder = iAuth;
            g_kBinder = kID;
            llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "garble_Binder="+(string)kID+","+(string)iAuth, "");
            bind();
            if (kID != g_kWearer) llOwnerSay(Name(kID)+" ordered you to be quiet");
            Notify(kID, "%WEARERNAME%'s speech is now garbled", FALSE);
        }
    } else if (sStr == "menu "+UNGARBLE || llToLower(sStr) == "garble off") {
        if (iAuth <= g_iBinder) {
            release();
            if (kID != g_kWearer) llOwnerSay("You are free to speak again");
            Notify(kID, "%WEARERNAME% is allowed to talk again", FALSE);
        } else Notify(kID, "Sorry, the garbler can only be released by someone with an equal or higher rank than the person who set it.", FALSE);
    }
    if (iMenu) llMessageLinked(LINK_THIS, iAuth, "menu "+g_sParentMenu, kID);
}

default {
    on_rez(integer num) {
        if (llGetOwner() != g_kWearer) llResetScript();
    }

    state_entry() {
        g_kWearer = llGetOwner();
        g_sPrefix = llGetSubString(llKey2Name(g_kWearer),0,1);
        release();
        g_iGarbleChan = llRound(llFrand(499) + 100);
        //llMessageLinked(LINK_THIS, LM_SETTING_REQUEST, "listener_safeword", "");
        //llMessageLinked(LINK_THIS, LM_SETTING_REQUEST, "garble_Binder", "");
        //Debug("Starting");
    }

    link_message(integer iLink, integer iNum, string sMsg, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sMsg, kID, FALSE);
        else if (iNum == MENUNAME_REQUEST && sMsg == g_sParentMenu) {
            if (bOn) llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu+"|"+UNGARBLE, "");
            else llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu+"|"+GARBLE, "");
        } else if (iNum == RLV_REFRESH) {
            if (bOn) bind();
            else release();
        } else if (iNum == RLV_CLEAR) release();
        else if (iNum == CMD_SAFEWORD) release();
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParam = llParseString2List(sMsg, ["="], []);
            string sToken = llList2String(lParam, 0);
            if (sToken == "garble_Binder") {
                list lValue = llParseString2List(llList2String(lParam,1), [","], []);
                g_kBinder = (key)llList2String(lValue, 0);
                g_iBinder = (integer)llList2String(lValue, 1);
                bind();
            }
            else if (sToken == "global_safeword") g_sSafeWord = llList2String(lParam, 1);
            else if (sToken == "global_prefix") g_sPrefix = llList2String(lParam, 1);

        }
        else if (iNum == LM_SETTING_EMPTY && sMsg == "garble_Binder") release();
        else if (iNum == REBOOT && sMsg == "reboot") llResetScript();
    }

    listen(integer iChan, string sName, key kID, string sMsg) {
        if (iChan == g_iGarbleChan && kID == g_kWearer) {
            string sw = sMsg;
            if (llGetSubString(sw, 0, 3) == "/me ") sw = llGetSubString(sw, 4, -1);
            if (llGetSubString(sw, 0, 1) == "((" && llGetSubString(sw, -2, -1) == "))") sw = llGetSubString(sw, 2, -3);
            if (llSubStringIndex(sw, g_sPrefix)==0) sw = llGetSubString(sw, llStringLength(g_sPrefix), -1);
            if (sw == g_sSafeWord)
            {
                llMessageLinked(LINK_SET, CMD_SAFEWORD, "", "");
                llOwnerSay("You used your safeword, your owner will be notified you did.");
                llMessageLinked(LINK_THIS,NOTIFY_OWNERS,"Your sub %WEARERNAME% has used the safeword. Please check on their well-being in case further care is required.","");
            }
            else
            {
                string sOut;
                integer i;
                for (i = 0; i < llStringLength(sMsg); i++)
                    sOut += garble(llToLower(llGetSubString(sMsg, i, i)));
                string sMe = llGetObjectName();
                llSetObjectName("");
                llWhisper(0, "/me "+Name(g_kWearer)+" mumbles: " + sOut);
                llSetObjectName(sMe);
            }
        }
    }

/*
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/
}
