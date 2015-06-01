////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - settings                              //
//                                 version 3.990                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// This script stores settings for other scripts in the collar.  In bygone days
// it was responsible for storing them to an online database too.  It doesn't
// do that anymore.  But so long as plugin scripts are still using central
// storage like this, it's always possible we could bring back an online DB or
// someone could offer a third party one.



string g_sDefaultscard = ".settings";
string g_sSplit_line; // to parse lines that were split due to lsl constraints
integer g_iDefaultsline = 0;
key g_kDefaultslineID;
key g_kCardKey;
key g_kWearer;

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
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the store
//integer LM_SETTING_REQUEST_NOCACHE = 2005;

//integer INTERFACE_CHANNEL;

//string WIKI_URL = "http://www.opencollar.at/user-guide.html";
list g_lSettings;

integer SAY_LIMIT = 1024; // lsl "say" string limit
integer CARD_LIMIT = 255; // lsl card-line string limit
string ESCAPE_CHAR = "\\"; // end of card line, more value left for token

/*
Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if ((key)kID){
        string sObjectName = llGetObjectName();
        if (g_sDeviceName != sObjectName) {
            llSetObjectName(g_sDeviceName);
        }
        if (kID == g_kWearer) llOwnerSay(sMsg);
        else {
            if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
            else llInstantMessage(kID, sMsg);
            if (iAlsoNotifyWearer) llOwnerSay(sMsg);
        }
        if (llGetObjectName() != sObjectName) llSetObjectName(sObjectName);
    }
}*/

// Get Group or Token, 0=Group, 1=Token
string SplitToken(string sIn, integer iSlot)
{
    integer i = llSubStringIndex(sIn, "_");
    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
    return llGetSubString(sIn, i + 1, -1);
}
// To add new entries at the end of Groupings
integer GroupIndex(list lCache, string sToken)
{
    string sGroup = SplitToken(sToken, 0);
    integer i = llGetListLength(lCache) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2)
    {
        if (SplitToken(llList2String(lCache, i - 1), 0) == sGroup) return i + 1;
    }
    return -1;
}
integer SettingExists(string sToken)
{
    if (~llListFindList(g_lSettings, [sToken])) return TRUE;
    return FALSE;
}

list SetSetting(list lCache, string sToken, string sValue) {
    integer idx = llListFindList(lCache, [sToken]);
    if (! ~llListFindList(["AUTH_block","AUTH_trust","AUTH_owner"],[llToLower(sToken)])) {
        if (~llListFindList(lCache, [sValue])) return lCache;
    } //we check the above to avoid same IDs in different auth lists
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
    while (llGetListLength(lIn))
    {
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
    if (SplitToken(sToken, 1) == "all")
    {
        sToken = SplitToken(sToken, 0);
      //  string sVar;
        for (; ~i; i -= 2)
        {
            if (SplitToken(llList2String(g_lSettings, i - 1), 0) == sToken)
                g_lSettings = llDeleteSubList(g_lSettings, i - 1, i);
        }
        return;
    }
    i = llListFindList(g_lSettings, [sToken]);
    if (~i) g_lSettings = llDeleteSubList(g_lSettings, i, i + 1);
}

// run delimiters & add escape-characters for DumpCache
list Add2OutList(list lIn) {
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
        sGroup = SplitToken(sToken, 0);
        sToken = SplitToken(sToken, 1);
        integer bIsSplit = FALSE ;
        integer iAddedLength = llStringLength(sBuffer) + llStringLength(sValue) 
            + llStringLength(sID) +2; //+llStringLength(set);
        if (sGroup != sID || llStringLength(sBuffer) == 0 || iAddedLength >= CARD_LIMIT ) // new group
        {
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
            if (llStringLength(sTemp) > CARD_LIMIT)
            {
                bIsSplit = TRUE ;
                sBuffer = llGetSubString(sTemp, 0, CARD_LIMIT - 2) + ESCAPE_CHAR;
                sTemp = "\n" + llDeleteSubString(sTemp, 0, CARD_LIMIT - 2);
            }
            else sTemp = "";
            if ( bIsSplit ) 
            {
                // if this is either a split buffer or one of it's continuation
                // line outputs, 
                lOut += [sBuffer];
                sBuffer = "" ;
            }
        }
    }
    // If there's anything left in the buffer, flush it to output.
    if ( llStringLength(sBuffer) ) lOut += [sBuffer] ;
    // Possibly this line was supposed to reallocate the list to keep it from taking too
    // much space. Logically, this is a 'do nothing' line - replacing the last item in 
    // the 'out' list with the last item in the out list, with no changes.
//////    out = llListReplaceList(out, [llList2String(out, -1)], -1, -1);
    return lOut;
}

DumpCache(key kID) {
    // compile everything into one list, so we can tell the user everything seamlessly
    list lOut;
    list lSay = ["\n\nEverything below this line can be copied & pasted into a notecard called \".settings\" for backup:\n"];
    lSay += Add2OutList(g_lSettings);
    string sOld;
    string sNew;
    integer i;
    while (llGetListLength(lSay)) {
        sNew = llList2String(lSay, 0);
        i = llStringLength(sOld + sNew) + 2;
        if (i > SAY_LIMIT) {
            lOut += [sOld];
            sOld = "";
        }
        sOld += sNew;
        lSay = llDeleteSubList(lSay, 0, 0);
    }
    lOut += [sOld];
    while (llGetListLength(lOut)) {
        llMessageLinked(LINK_SET, NOTIFY, "0"+llList2String(lOut, 0), kID);
        //Notify(kID, llList2String(lOut, 0), TRUE);
        lOut = llDeleteSubList(lOut, 0, 0);
    }
}

SendValues() {
    //Debug("Sending all settings");
    //loop through and send all the settings
    integer n = 0;
    string sToken;
    list lOut;
    for (; n < llGetListLength(g_lSettings); n += 2)
    {
        sToken = llList2String(g_lSettings, n) + "=";
        sToken += llList2String(g_lSettings, n + 1);
        if (llListFindList(lOut, [sToken]) == -1) lOut += [sToken];
    }
    n = 0;
    for (; n < llGetListLength(lOut); n++)
    {
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, llList2String(lOut, n), "");
    }
    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "settings=sent", "");//tells scripts everything has be sentout
}
 
integer UserCommand(integer iAuth, string sStr, key kID) {
    if (iAuth != CMD_OWNER && iAuth != CMD_WEARER) return FALSE;
    sStr = llToLower(sStr);
    if (sStr == "settings") DumpCache(kID);
    else if (sStr == "load") {
        g_iDefaultsline = 0;
        if (llGetInventoryKey(g_sDefaultscard)) g_kDefaultslineID = llGetNotecardLine(g_sDefaultscard, g_iDefaultsline);
    }
    else return FALSE;
    return TRUE;
}

default {
    state_entry() {
        // Ensure that settings resets AFTER every other script, so that they don't reset after they get settings
        llSleep(0.5);
        g_kWearer = llGetOwner();
        g_iDefaultsline = 0;
        if (llGetInventoryKey(g_sDefaultscard)) {
            g_kDefaultslineID = llGetNotecardLine(g_sDefaultscard, g_iDefaultsline);
            g_kCardKey = llGetInventoryKey(g_sDefaultscard);
        }
    }

    on_rez(integer iParam) {
        // resend settings to plugins, if owner hasn't changed, in which case
        // reset the whole lot.
        if (g_kWearer == llGetOwner()) {
            llSleep(0.5); // brief wait for others to reset
            SendValues();    
        }
        else llResetScript();
    }

    dataserver(key id, string data) {
        if (id == g_kDefaultslineID) {
            string sID;
            string sToken;
            string sValue;
            integer i;
            if (data == EOF && g_sSplit_line != "" ) {
                data = g_sSplit_line ;
                g_sSplit_line = "" ;
            }
            if (data != EOF) {
                // first we can filter out & skip blank lines & remarks
                data = llStringTrim(data, STRING_TRIM_HEAD);
                if (data == "" || llGetSubString(data, 0, 0) == "#") jump nextline;
                // check for "continued" line pieces
                if ( llStringLength(g_sSplit_line) ) { 
                    data = g_sSplit_line + data ;
                    g_sSplit_line = "" ;
                }
                if ( llGetSubString( data, -1, -1) == ESCAPE_CHAR ) {
                    g_sSplit_line = llDeleteSubString( data, -1, -1) ;
                    jump nextline ;
                }
                i = llSubStringIndex(data, "=");
                sID = (llToUpper(llGetSubString(data, 0, i - 1))) + "_";
                data = llGetSubString(data, i + 1, -1);
                list lData = llParseString2List(data, ["~"], []);
                for (i = 0; i < llGetListLength(lData); i += 2) {
                    sToken = llList2String(lData, i);
                    sValue = llList2String(lData, i + 1);
                    if (sValue != "") { //if no value, nothing to do
                        if (sID == "AUTH_") { //if we have auth, can only be the below, else we dont care
                            if (! ~llListFindList(["block","trust","owner"],[llToLower(sToken)])) jump nextline ;
                            list lTest = llParseString2List(sValue,[","],[]);
                            list lOut;
                            integer n;
                            for(;n<llGetListLength(lTest);n = n+2) {
                                if (llList2Key(lTest,n)) //if this is not a valid key, it's useless we dont save that
                                    lOut += llList2List(lTest,n,n+1);
                            }
                            sValue = llList2CSV(lOut);
                        }
                        g_lSettings = SetSetting(g_lSettings, sID + sToken, sValue);
                    }
                }
                @nextline;
                g_iDefaultsline++;
                g_kDefaultslineID = llGetNotecardLine(g_sDefaultscard, g_iDefaultsline);
            } else {
                // wait a sec before sending settings, in case other scripts are
                // still resetting.
                llSleep(2.0);
                SendValues();
            }
        }
    }

    link_message(integer sender, integer iNum, string sStr, key kID) {
        if (UserCommand(iNum, sStr, kID)) return;
        if (iNum == LM_SETTING_SAVE) {
            //save the token, value
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            g_lSettings = SetSetting(g_lSettings, sToken, sValue);
        }
        else if (iNum == LM_SETTING_REQUEST) {  
             //check the cache for the token 
            if (SettingExists(sStr)) llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sStr + "=" + GetSetting(sStr), "");
            else llMessageLinked(LINK_SET, LM_SETTING_EMPTY, sStr, "");
        }
        else if (iNum == LM_SETTING_DELETE) DelSetting(sStr);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(g_sDefaultscard) != g_kCardKey) {
                // the .settings card changed.  Re-read it.
                g_iDefaultsline = 0;
                if (llGetInventoryKey(g_sDefaultscard)) {
                    g_kDefaultslineID = llGetNotecardLine(g_sDefaultscard, g_iDefaultsline);
                    g_kCardKey = llGetInventoryKey(g_sDefaultscard);
                }
            }
            llSleep(1.0);   //pause, then send values if inventory changes, in case script was edited and needs its settings again
            SendValues();
        }
    }
}
