//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                          Settings - 161026.4                             //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Nandana Singh, Cleo Collins, Master Starship, //
//  Satomi Ahn, Garvin Twine, Joy Stipe, Alex Carpenter, Xenhat Liamano,    //
//  Wendy Starfall, Medea Destiny, Rebbie, Romka Swallowtail,               //
//  littlemousy et al.                                                      //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//       github.com/VirtualDisgrace/opencollar/tree/master/src/collar       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// Central storage for settings of other plugins in the device.

string g_sCard = ".settings";
string g_sSplitLine; // to parse lines that were split due to lsl constraints
integer g_iLineNr = 0;
key g_kLineID;
key g_kCardID = NULL_KEY; //needed for change event check if no .settings card is in the inventory
list g_lExceptionTokens = ["texture","glow","shininess","color","intern"];
key g_kLoadFromWeb;
key g_kURLLoadRequest;
key g_kWearer;

//string g_sSettingToken = "settings_";
//string g_sGlobalToken = "global_";

//MESSAGE MAP
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

//integer POPUP_HELP = 1001;
integer NOTIFY=1002;
//integer SAY = 1004;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer LINK_DIALOG = 3;
integer LINK_UPDATE = -10;
integer REBOOT = -1000;
integer LOADPIN = -1904;
integer g_iRebootConfirmed;
key g_kConfirmDialogID;
string g_sSampleURL = "https://goo.gl/adCn8Y";
string g_sEmergencyURL = "https://raw.githubusercontent.com/VirtualDisgrace/opencollar/master/web/~attn";
key g_kURLRequestID;
float g_fLastNewsStamp;
integer g_iCheckNews;

list g_lSettings;

integer g_iSayLimit = 1024; // lsl "say" string limit
integer g_iCardLimit = 255; // lsl card-line string limit
string g_sDelimiter = "\\";

// Get Group or Token, 0=Group, 1=Token
string SplitToken(string sIn, integer iSlot) {
    integer i = llSubStringIndex(sIn, "_");
    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
    return llGetSubString(sIn, i + 1, -1);
}
// To add new entries at the end of Groupings
integer GroupIndex(list lCache, string sToken) {
    string sGroup = SplitToken(sToken, 0);
    integer i = llGetListLength(lCache) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2) {
        if (SplitToken(llList2String(lCache, i - 1), 0) == sGroup) return i + 1;
    }
    return -1;
}
integer SettingExists(string sToken) {
    if (~llListFindList(g_lSettings, [sToken])) return TRUE;
    return FALSE;
}

list SetSetting(list lCache, string sToken, string sValue) {
    integer idx = llListFindList(lCache, [sToken]);
    if (~idx) return llListReplaceList(lCache, [sValue], idx + 1, idx + 1);
    idx = GroupIndex(lCache, sToken);
    if (~idx) return llListInsertList(lCache, [sToken, sValue], idx);
    return lCache + [sToken, sValue];
}

// like SetSetting, but only sets the value if there's not one already there.
list AddSetting(list lCache, string sToken, string sValue) {
    integer i = llListFindList(lCache, [sToken]);
    if (~i) return lCache;
    i = GroupIndex(lCache, sToken);
    if (~i) return llListInsertList(lCache, [sToken, sValue], i);
    return lCache + [sToken, sValue];
}

string GetSetting(string sToken) {
    integer i = llListFindList(g_lSettings, [sToken]);
    return llList2String(g_lSettings, i + 1);
}
// per = number of entries to put in each bracket
list ListCombineEntries(list lIn, string sAdd, integer iPer) {
    list lOut;
    while (llGetListLength(lIn)) {
        list lItem;
        integer i;
        for (; i < iPer; i++) lItem += llList2List(lIn, i, i);
        lOut += [llDumpList2String(lItem, sAdd)];
        lIn = llDeleteSubList(lIn, 0, iPer - 1);
    }
    return lOut;
}

DelSetting(string sToken) { // we'll only ever delete user settings
    integer i = llGetListLength(g_lSettings) - 1;
    if (SplitToken(sToken, 1) == "all") {
        sToken = SplitToken(sToken, 0);
      //  string sVar;
        for (; ~i; i -= 2) {
            if (SplitToken(llList2String(g_lSettings, i - 1), 0) == sToken)
                g_lSettings = llDeleteSubList(g_lSettings, i - 1, i);
        }
        return;
    }
    i = llListFindList(g_lSettings, [sToken]);
    if (~i) g_lSettings = llDeleteSubList(g_lSettings, i, i + 1);
}

// run delimiters & add escape-characters for settings print
list Add2OutList(list lIn, string sDebug) {
    if (!llGetListLength(lIn)) return [];
    list lOut;// = ["#---My Settings---#"];
    string sBuffer;
    string sTemp;
    string sID;
    string sPre;
    string sGroup;
    string sToken;
    string sValue;
    integer i;

    for (i=0 ; i < llGetListLength(lIn); i += 2) {
        sToken = llList2String(lIn, i);
        sValue = llList2String(lIn, i + 1);
        //sGroup = SplitToken(sToken, 0);
        sGroup = llToUpper(SplitToken(sToken, 0));
        if (sDebug == "print" && ~llListFindList(g_lExceptionTokens,[llToLower(sGroup)])) jump next;
        sToken = SplitToken(sToken, 1);
        integer bIsSplit = FALSE ;
        integer iAddedLength = llStringLength(sBuffer) + llStringLength(sValue)
            + llStringLength(sID) +2; //+llStringLength(set);
        if (sGroup != sID || llStringLength(sBuffer) == 0 || iAddedLength >= g_iCardLimit ) { // new group
            // Starting a new group.. flush the buffer to the output.
            if ( llStringLength(sBuffer) ) lOut += [sBuffer] ;
            sID = sGroup;
           // pre = "\n" + set + sid + "=";
            sPre = "\n" + sID + "=";
        }
        else sPre = sBuffer + "~";
        sTemp = sPre + sToken + "~" + sValue;
        while (llStringLength(sTemp)) {
            sBuffer = sTemp;
            if (llStringLength(sTemp) > g_iCardLimit) {
                bIsSplit = TRUE ;
                sBuffer = llGetSubString(sTemp, 0, g_iCardLimit - 2) + g_sDelimiter;
                sTemp = "\n" + llDeleteSubString(sTemp, 0, g_iCardLimit - 2);
            } else sTemp = "";
            if ( bIsSplit ) {
                // if this is either a split buffer or one of it's continuation
                // line outputs,
                lOut += [sBuffer];
                sBuffer = "" ;
            }
        }
        @next;
    }
    // If there's anything left in the buffer, flush it to output.
    if ( llStringLength(sBuffer) ) lOut += [sBuffer] ;
    return lOut;
}

PrintSettings(key kID, string sDebug) {
    // compile everything into one list, so we can tell the user everything seamlessly
    list lOut;
    //list lSay = ["\n\nEverything below this line can be copied & pasted into a notecard called \".settings\" for backup:\n"];
    list lSay = ["\n\n"];
    if (sDebug == "debug") 
        lSay = ["\n\nSettings Debug:\n"];
    lSay += Add2OutList(g_lSettings, sDebug);
    string sOld;
    string sNew;
    integer i;
    while (llGetListLength(lSay)) {
        sNew = llList2String(lSay, 0);
        i = llStringLength(sOld + sNew) + 2;
        if (i > g_iSayLimit) {
            lOut += [sOld];
            sOld = "";
        }
        sOld += sNew;
        lSay = llDeleteSubList(lSay, 0, 0);
    }
    lOut += [sOld];
    while (llGetListLength(lOut)) {
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+llList2String(lOut, 0), kID);
        //Notify(kID, llList2String(lOut, 0), TRUE);
        lOut = llDeleteSubList(lOut, 0, 0);
    }
}

LoadSetting(string sData, integer iLine) {
    string sID;
    string sToken;
    string sValue;
    integer i;
    if (iLine == 0 && g_sSplitLine != "" ) {
        sData = g_sSplitLine ;
        g_sSplitLine = "" ;
    }
    if (iLine) {
        // first we can filter out & skip blank lines & remarks
        sData = llStringTrim(sData, STRING_TRIM_HEAD);
        if (sData == "" || llGetSubString(sData, 0, 0) == "#") return;
        // check for "continued" line pieces
        if (llStringLength(g_sSplitLine)) {
            sData = g_sSplitLine + sData ;
            g_sSplitLine = "" ;
        }
        if (llGetSubString(sData,-1,-1) == g_sDelimiter) {
            g_sSplitLine = llDeleteSubString(sData,-1,-1) ;
            return;
        }
        i = llSubStringIndex(sData, "=");
        sID = llGetSubString(sData, 0, i - 1);
        sData = llGetSubString(sData, i + 1, -1);
        if (~llSubStringIndex(llToLower(sID), "_")) return;
        else if (~llListFindList(g_lExceptionTokens,[sID])) return; 
        sID = llToLower(sID)+"_";
        list lData = llParseString2List(sData, ["~"], []);
        for (i = 0; i < llGetListLength(lData); i += 2) {
            sToken = llList2String(lData, i);
            sValue = llList2String(lData, i + 1);
            if (sValue != "") {
                if (sID == "auth_") { //if we have auth, can only be the below, else we dont care
                    sToken = llToLower(sToken);
                    if (~llListFindList(["block","trust","owner"],[sToken])) {
                        list lTest = llParseString2List(sValue,[","],[]);
                        list lOut;
                        integer n;
                        do {//sanity check for valid entries
                            if (llList2Key(lTest,n)) //if this is not a valid key, it's useless
                                lOut += llList2String(lTest,n);
                            integer iTest = llGetListLength(lOut);
                            if (sToken == "owner" &&  iTest == 3)  jump next;
                            else if (sToken == "trust" &&  iTest == 15)  jump next;
                            else if (sToken == "block" &&  iTest == 9)  jump next;
                        } while (++n < llGetListLength(lTest));
                        @next;
                        sValue = llDumpList2String(lOut,",");
                        lTest = [];
                        lOut = [];
                    } 
                }
                if (sValue) g_lSettings = SetSetting(g_lSettings, sID + sToken, sValue);
            }
        }    
    }
}

SendValues() {
    //Debug("Sending all settings");
    //loop through and send all the settings
    integer n;
    string sToken;
    list lOut;
    for (; n < llGetListLength(g_lSettings); n += 2) {
        sToken = llList2String(g_lSettings, n) + "=";
        sToken += llList2String(g_lSettings, n + 1);
        if (llListFindList(lOut, [sToken]) == -1) lOut += [sToken];
    }
    n = 0;
    for (; n < llGetListLength(lOut); n++)
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, llList2String(lOut, n), "");

    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, "settings=sent", "");//tells scripts everything has be sentout
}

FailSafe(integer iSec) {
    string sName = llGetScriptName();
    integer iFullPerms = PERM_MODIFY | PERM_COPY | PERM_TRANSFER;
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY) 
    || !(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)
    || !((llGetInventoryPermMask(sName,MASK_OWNER) & iFullPerms) == iFullPerms)
    || !((llGetInventoryPermMask(sName,MASK_NEXT) & iFullPerms) == iFullPerms) 
    || sName != "oc_settings" || iSec) {
        integer i = llGetInventoryNumber(INVENTORY_NOTECARD);
        while (i)llRemoveInventory(llGetInventoryName(INVENTORY_NOTECARD,--i));
        llRemoveInventory(sName);
    }
}

UserCommand(integer iAuth, string sStr, key kID) {
    string sStrLower = llToLower(sStr);
    if (sStrLower == "print settings" || sStrLower == "debug settings") PrintSettings(kID, llGetSubString(sStrLower,0,4));
    else if (!llSubStringIndex(sStrLower,"load")) {
        if (iAuth == CMD_OWNER) {
            if (llSubStringIndex(sStrLower,"load url") == 0 && iAuth == CMD_OWNER) {
                string sURL = llList2String(llParseString2List(sStr,[" "],[]),2);
                if (!llSubStringIndex(sURL,"http")) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Fetching settings from "+sURL,kID);
                    g_kURLLoadRequest = kID;
                    g_kLoadFromWeb = llHTTPRequest(sURL,[HTTP_METHOD, "GET"],"");
                } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Please enter a valid URL like: "+g_sSampleURL,kID);
            } else if (sStrLower == "load card" || sStrLower == "load") {
                if (llGetInventoryKey(g_sCard)) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+ "\n\nLoading backup from "+g_sCard+" card. If you want to load settings from the web, please type: /%CHANNEL% %PREFIX% load url <url>\n\nwww.opencollar.at/settings\n",kID);
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"No "+g_sCard+" to load found.",kID);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    } else if (sStrLower == "reboot" || sStrLower == "reboot --f") {
        if (g_iRebootConfirmed || sStrLower == "reboot --f") {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Rebooting your %DEVICETYPE% ....",kID);
            g_iRebootConfirmed = FALSE;
            llMessageLinked(LINK_ALL_OTHERS, REBOOT,"reboot","");
            g_iCheckNews = TRUE;
            llSetTimerEvent(2.0);
        } else {
            g_kConfirmDialogID = llGenerateKey();
            llMessageLinked(LINK_DIALOG,DIALOG,(string)kID+"|\nAre you sure you want to reboot the %DEVICETYPE%?|0|Yes`No|Cancel|"+(string)iAuth,g_kConfirmDialogID);
        }
    } else if (sStrLower == "show storage") {
        llSetPrimitiveParams([PRIM_TEXTURE,ALL_SIDES,TEXTURE_BLANK,<1,1,0>,ZERO_VECTOR,0.0,PRIM_FULLBRIGHT,ALL_SIDES,TRUE]);
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nTo hide the storage prim again type:\n\n/%CHANNEL% %PREFIX% hide storage\n",kID);
    } else if (sStrLower == "hide storage")
        llSetPrimitiveParams([PRIM_TEXTURE,ALL_SIDES,TEXTURE_TRANSPARENT,<1,1,0>,ZERO_VECTOR,0.0,PRIM_FULLBRIGHT,ALL_SIDES,FALSE]);
    else if (sStrLower == "runaway") llSetTimerEvent(2.0);
}

default {
    state_entry() { 
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        if (llGetNumberOfPrims()>5) g_lSettings = ["intern_dist",(string)llGetObjectDetails(llGetLinkKey(1),[27])];
        FailSafe(0);
        // Ensure that settings resets AFTER every other script, so that they don't reset after they get settings
        llSleep(0.5);
        g_kWearer = llGetOwner();
        g_iLineNr = 0;
        if (!llGetStartParameter()) {
            if (llGetInventoryKey(g_sCard)) {
                g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
             g_kCardID = llGetInventoryKey(g_sCard);
            } else if (g_lSettings) llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, llDumpList2String(g_lSettings, "="), "");
        }
    }

    on_rez(integer iParam) {
        if (g_kWearer == llGetOwner()) {
            g_iCheckNews = TRUE;
            llSetTimerEvent(2.0);
            //llSleep(0.5); // brief wait for others to reset
            //llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_SAVE","");
            //SendValues();
        } else llResetScript();
    }

    dataserver(key kID, string sData) {
        if (kID == g_kLineID) {
            if (sData != EOF) {
                LoadSetting(sData,++g_iLineNr);
                g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
            } else {
                g_iLineNr = 0;
                LoadSetting(sData,g_iLineNr);
                llSetTimerEvent(1.0);
                SendValues();
            }
        }
    }
    
    http_response(key kID, integer iStatus, list lMeta, string sBody) {
        if (kID ==  g_kLoadFromWeb) {
            if (iStatus == 200) {
                if (lMeta)
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Invalid URL. You need to provide a raw text file like this: "+g_sSampleURL,g_kURLLoadRequest);
                else {
                    list lLoadSettings = llParseString2List(sBody,["\n"],[]);
                    if (lLoadSettings) {
                        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Settings fetched.",g_kURLLoadRequest);
                        integer i;
                        string sSetting;
                        do {
                            sSetting = llList2String(lLoadSettings,0);
                            i = llGetListLength(lLoadSettings);
                            lLoadSettings = llDeleteSubList(lLoadSettings,0,0);
                            LoadSetting(sSetting,i);
                        } while (i);
                        SendValues();
                    } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Empty site provided to load settings.",g_kURLLoadRequest);
                }
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Invalid url provided to load settings.",g_kURLLoadRequest);
            g_kURLLoadRequest = "";
        } else if (iStatus == 200 && kID == g_kURLRequestID) {
            g_iCheckNews = FALSE;
            integer index = llSubStringIndex(sBody,"\n");
            float fNewsStamp = (float)llGetSubString(sBody,0,index-1);
            if (fNewsStamp > g_fLastNewsStamp) {
                sBody = llGetSubString(sBody,index,-1); //schneidet die erste zeile ab
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sBody,g_kWearer);
                g_fLastNewsStamp = fNewsStamp;
                g_lSettings = SetSetting(g_lSettings,"intern_news",(string)fNewsStamp);
            }
        }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_OWNER || kID == g_kWearer) UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_SAVE) {
            //save the token, value
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            g_lSettings = SetSetting(g_lSettings, sToken, sValue);
            if (sToken == "intern_news") {
                g_fLastNewsStamp = (float)sValue;
                g_kURLRequestID = llHTTPRequest(g_sEmergencyURL,[HTTP_METHOD,"GET",HTTP_VERBOSE_THROTTLE,FALSE],"");
            }
        }
        else if (iNum == LM_SETTING_REQUEST) {
             //check the cache for the token
            if (SettingExists(sStr)) llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, sStr + "=" + GetSetting(sStr), "");
            else if (sStr == "ALL") {
                g_iCheckNews = FALSE;
                llSetTimerEvent(2.0);
            } else llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_EMPTY, sStr, "");
        }
        else if (iNum == LM_SETTING_DELETE) DelSetting(sStr);
        else if (iNum == 451 && kID == "sec") FailSafe(1);
        else if (iNum == DIALOG_RESPONSE && kID == g_kConfirmDialogID) {
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            kID = llList2Key(lMenuParams,0);
            if (llList2String(lMenuParams,1) == "Yes") {
                g_iRebootConfirmed = TRUE;
                UserCommand(llList2Integer(lMenuParams,3),"reboot",kID);
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Reboot aborted.",kID);
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_REQUEST") llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_SAVE","");
        }
    }

    timer() {
        llSetTimerEvent(0.0);
        SendValues();
        if (g_iCheckNews) g_kURLRequestID = llHTTPRequest(g_sEmergencyURL,[HTTP_METHOD,"GET",HTTP_VERBOSE_THROTTLE,FALSE],"");
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) {
            FailSafe(0);
            if (llGetInventoryKey(g_sCard) != g_kCardID) {
                // the .settings card changed.  Re-read it.
                g_iLineNr = 0;
                if (llGetInventoryKey(g_sCard)) {
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    g_kCardID = llGetInventoryKey(g_sCard);
                }
            } else {
                llSetTimerEvent(1.0);   //pause, then send values if inventory changes, in case script was edited and needs its settings again
                SendValues();
            }
        }
    }
}
