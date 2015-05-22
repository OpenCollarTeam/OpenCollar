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



string defaultscard = ".settings";
string split_line; // to parse lines that were split due to lsl constraints
integer defaultsline = 0;
key defaultslineid;
key card_key;
key g_kWearer;

// Message Map
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
//integer COMMAND_SECOWNER = 501;
//integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
//integer COMMAND_EVERYONE = 504;

//integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the store
integer LM_SETTING_REQUEST_NOCACHE = 2005;

//integer INTERFACE_CHANNEL;

//string WIKI_URL = "http://www.opencollar.at/user-guide.html";
list SETTINGS;
list g_lScriptNames;

integer SAY_LIMIT = 1024; // lsl "say" string limit
integer CARD_LIMIT = 255; // lsl card-line string limit
string ESCAPE_CHAR = "\\"; // end of card line, more value left for token

/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled) {
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

// Get Group or Token, 0=Group, 1=Token
string SplitToken(string in, integer slot)
{
    integer i = llSubStringIndex(in, "_");
    if (!slot) return llGetSubString(in, 0, i - 1);
    return llGetSubString(in, i + 1, -1);
}
// To add new entries at the end of Groupings
integer GroupIndex(list cache, string token)
{
    string group = SplitToken(token, 0);
    integer i = llGetListLength(cache) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2)
    {
        if (SplitToken(llList2String(cache, i - 1), 0) == group) return i + 1;
    }
    return -1;
}
integer SettingExists(string token)
{
    if (~llListFindList(SETTINGS, [token])) return TRUE;
    return FALSE;
}

list SetSetting(list cache, string token, string value) {
    integer idx = llListFindList(cache, [token]);
    if (~idx) return llListReplaceList(cache, [value], idx + 1, idx + 1);
    idx = GroupIndex(cache, token);
    if (~idx) return llListInsertList(cache, [token, value], idx);
    return cache + [token, value];
}

// like SetSetting, but only sets the value if there's not one already there.
list AddSetting(list cache, string token, string value) {
    integer i = llListFindList(cache, [token]);
    if (~i) return cache;
    i = GroupIndex(cache, token);
    if (~i) return llListInsertList(cache, [token, value], i);
    return cache + [token, value];
}

string GetSetting(string token) {
    integer i = llListFindList(SETTINGS, [token]);
    return llList2String(SETTINGS, i + 1);
}
// per = number of entries to put in each bracket
list ListCombineEntries(list in, string add, integer per) {
    list out;
    while (llGetListLength(in))
    {
        list item;
        integer i;
        for (; i < per; i++) item += llList2List(in, i, i);
        out += [llDumpList2String(item, add)];
        in = llDeleteSubList(in, 0, per - 1);
    }
    return out;
}

DelSetting(string token) { // we'll only ever delete user settings
    integer i = llGetListLength(SETTINGS) - 1;
    if (SplitToken(token, 1) == "all")
    {
        token = SplitToken(token, 0);
        string var;
        for (; ~i; i -= 2)
        {
            if (SplitToken(llList2String(SETTINGS, i - 1), 0) == token)
                SETTINGS = llDeleteSubList(SETTINGS, i - 1, i);
        }
        return;
    }
    i = llListFindList(SETTINGS, [token]);
    if (~i) SETTINGS = llDeleteSubList(SETTINGS, i, i + 1);
}

// run delimiters & add escape-characters for DumpCache
list Add2OutList(list in) {
    if (!llGetListLength(in)) return [];
    list out = ["#---My Settings---#"];
    string buffer;
    string temp;
    string sid;
    string pre;
    string group;
    string tok;
    string val;
    integer i;
    
    for (i=0 ; i < llGetListLength(in); i += 2) {
        tok = llList2String(in, i);
        val = llList2String(in, i + 1);
        group = SplitToken(tok, 0);
        tok = SplitToken(tok, 1);
        integer bIsSplit = FALSE ;
        integer iAddedLength = llStringLength(buffer) + llStringLength(val) 
            + llStringLength(sid) +2; //+llStringLength(set);
        if (group != sid || llStringLength(buffer) == 0 || iAddedLength >= CARD_LIMIT ) // new group
        {
            // Starting a new group.. flush the buffer to the output.
            if ( llStringLength(buffer) ) out += [buffer] ;
            sid = group;
           // pre = "\n" + set + sid + "=";
            pre = "\n" + sid + "=";
        }
        else pre = buffer + "~";
        temp = pre + tok + "~" + val;
        while (llStringLength(temp)) {
            buffer = temp;
            if (llStringLength(temp) > CARD_LIMIT)
            {
                bIsSplit = TRUE ;
                buffer = llGetSubString(temp, 0, CARD_LIMIT - 2) + ESCAPE_CHAR;
                temp = "\n" + llDeleteSubString(temp, 0, CARD_LIMIT - 2);
            }
            else temp = "";
            if ( bIsSplit ) 
            {
                // if this is either a split buffer or one of it's continuation
                // line outputs, 
                out += [buffer];
                buffer = "" ;
            }
        }
    }
    // If there's anything left in the buffer, flush it to output.
    if ( llStringLength(buffer) ) out += [buffer] ;
    // Possibly this line was supposed to reallocate the list to keep it from taking too
    // much space. Logically, this is a 'do nothing' line - replacing the last item in 
    // the 'out' list with the last item in the out list, with no changes.
//////    out = llListReplaceList(out, [llList2String(out, -1)], -1, -1);
    return out;
}

DumpCache(key id) {
    // compile everything into one list, so we can tell the user everything seamlessly
    list out;
    list say = ["\n\nEverything below this line can be copied & pasted into a notecard called \".settings\" for backup:\n"];
    say += Add2OutList(SETTINGS);
    string old;
    string new;
    integer c;
    while (llGetListLength(say)) {
        new = llList2String(say, 0);
        c = llStringLength(old + new) + 2;
        if (c > SAY_LIMIT) {
            out += [old];
            old = "";
        }
        old += new;
        say = llDeleteSubList(say, 0, 0);
    }
    out += [old];
    while (llGetListLength(out)) {
        Notify(id, llList2String(out, 0), TRUE);
        out = llDeleteSubList(out, 0, 0);
    }
}

SendValues() {
    //Debug("Sending all settings");
    //loop through and send all the settings
    integer n = 0;
    string tok;
    list out;
    for (; n < llGetListLength(SETTINGS); n += 2)
    {
        tok = llList2String(SETTINGS, n) + "=";
        tok += llList2String(SETTINGS, n + 1);
        if (llListFindList(out, [tok]) == -1) out += [tok];
    }
    n = 0;
    for (; n < llGetListLength(out); n++)
    {
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, llList2String(out, n), "");
    }
    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "settings=sent", "");//tells scripts everything has be sentout
}
 
integer UserCommand(integer iAuth, string sStr, key kID) {
    if (iAuth != COMMAND_OWNER && iAuth != COMMAND_WEARER) return FALSE;
    sStr = llToLower(sStr);
    if (sStr == "settings") DumpCache(kID);
    else if (sStr == "load") {
        defaultsline = 0;
        if (llGetInventoryKey(defaultscard)) defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
    }
    else return FALSE;
    return TRUE;
}

GetPossibleSettings() {
    g_lScriptNames = [];
    integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(i) {
        i--;
        string sScriptName = llGetInventoryName(INVENTORY_SCRIPT,i);
        integer index = llSubStringIndex(sScriptName, "- ");
        g_lScriptNames += [llToLower(llGetSubString(sScriptName, index + 2, -1))];
    }
}


default {
    state_entry() {
        GetPossibleSettings();
        // Ensure that settings resets AFTER every other script, so that they don't reset after they get settings
        llSleep(0.5);
        llSetMemoryLimit(49152);  //2015-05-06 (33192 bytes free at 64kb)
        g_kWearer = llGetOwner();
/*        INTERFACE_CHANNEL = (integer)("0x"+llGetSubString((string)g_kWearer,2,7)) + 1111;
        if (INTERFACE_CHANNEL > 0) INTERFACE_CHANNEL *= -1;
        if (INTERFACE_CHANNEL > -10000) INTERFACE_CHANNEL -= 30000;*/
        defaultsline = 0;
        if (llGetInventoryKey(defaultscard)) {
            defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
            card_key = llGetInventoryKey(defaultscard);
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
        if (id == defaultslineid) {
            string sid;
            string tok;
            string val;
            integer i;
            if (data == EOF && split_line != "" ) {
                data = split_line ;
                split_line = "" ;
            }
            if (data != EOF) {
                // first we can filter out & skip blank lines & remarks
                data = llStringTrim(data, STRING_TRIM_HEAD);
                if (data == "" || llGetSubString(data, 0, 0) == "#") jump nextline;
                // check for "continued" line pieces
                if ( llStringLength(split_line) ) { 
                    data = split_line + data ;
                    split_line = "" ;
                }
                if ( llGetSubString( data, -1, -1) == ESCAPE_CHAR ) {
                    split_line = llDeleteSubString( data, -1, -1) ;
                    jump nextline ;
                }
                // Next we wish to peel the special settings for this collar
                // unique collar id is followed by Script (that settings are for) + "=tok~val~tok~val"
                i = llSubStringIndex(data, "=");
                sid = (llGetSubString(data, 0, i - 1));
                if (~llListFindList(g_lScriptNames, [sid])) sid += "_";
                else  jump nextline ;
                data = llGetSubString(data, i + 1, -1);
                list lData = llParseString2List(data, ["~"], []);
                for (i = 0; i < llGetListLength(lData); i += 2) {
                    tok = llList2String(lData, i);
                    val = llList2String(lData, i + 1);
                    SETTINGS = SetSetting(SETTINGS, sid + tok, val);
                }
                @nextline;
                defaultsline++;
                defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
            } else {
                // wait a sec before sending settings, in case other scripts are
                // still resetting.
                llSleep(2.0);
                SendValues();
            }
        }
    }

    link_message(integer sender, integer iNum, string sStr, key id) {
        if (UserCommand(iNum, sStr, id)) return;
        if (iNum == LM_SETTING_SAVE) {
            //save the token, value
            list params = llParseString2List(sStr, ["="], []);
            string token = llList2String(params, 0);
            string value = llList2String(params, 1);
            SETTINGS = SetSetting(SETTINGS, token, value);
        }
        else if (iNum == LM_SETTING_REQUEST) {  
             //check the cache for the token 
            if (SettingExists(sStr)) llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sStr + "=" + GetSetting(sStr), "");
            else llMessageLinked(LINK_SET, LM_SETTING_EMPTY, sStr, "");
        }
        else if (iNum == LM_SETTING_DELETE) DelSetting(sStr);
    }

    changed(integer change) {
        if (change & CHANGED_OWNER) llResetScript();
        if (change & CHANGED_INVENTORY) {
            if (llGetInventoryKey(defaultscard) != card_key) {
                GetPossibleSettings();
                // the .settings card changed.  Re-read it.
                defaultsline = 0;
                if (llGetInventoryKey(defaultscard)) {
                    defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
                    card_key = llGetInventoryKey(defaultscard);
                }
            }
            llSleep(1.0);   //pause, then send values if inventory changes, in case script was edited and needs its settings again
            SendValues();
        }
/*        
        if (change & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
