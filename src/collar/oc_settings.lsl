//OpenCollar - settings
// This script stores settings for other scripts in the collar.  In bygone days
// it was responsible for storing them to an online database too.  It doesn't
// do that anymore.  But so long as plugin scripts are still using central
// storage like this, it's always possible we could bring back an online DB or
// someone could offer a third party one.
//
//  Standardized format for settings - this will facilitate concordant AddOn integrations
//      ID_Group=Token~Value~Token~Value (etc) in notecard (hard storage)
//      Group_Token=Value (Setting storage & script usage)
//  where:
//      ID_ = collar description's 3rd entry (after the 2nd tilde)
//              or "User_" for user customizations
//      Group = what script/AddOn these settings are for
//      Token = Setting to affect
//      Value = set Token to this value
//  EX: oc_texture=Base~steel~Ring~stripes (notecard line)
//      texture_Base=steel,texture_Ring=stripes (in the scripts)

string PARENT_MENU = "Help/Debug";
string SUBMENU = "Setting"; // "settings" in chat will call a mini dump .. this is to prevent double-up

string DUMPCACHE = "Dump Cache";
string PREFUSER = "Pref User";
string PREFDESI = "Pref Desig"; // yes, I hate cutoff buttons
string WIKI = "Online Guide";
string UPMENU = "^";
key g_kMenuID;
key g_kWearer;
string g_sScript;

string defaultscard = "defaultsettings";
string split_line; // to parse lines that were split due to lsl constraints
integer defaultsline = 0;
key defaultslineid;
key card_key;

// Message Map
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the store
integer LM_SETTING_REQUEST_NOCACHE = 2005;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer INTERFACE_CHANNEL;

string WIKI_URL = "http://www.opencollar.at/user-guide.html";
string DESIGN_ID;
list DESIGN_SETTINGS;
list USER_SETTINGS;
integer USER_PREF = FALSE; // user switch
integer SCRIPTCOUNT; // number of scripts, to resend if the count changes

integer SAY_LIMIT = 1024; // lsl "say" string limit
integer CARD_LIMIT = 255; // lsl card-line string limit
string ESCAPE_CHAR = "\\"; // end of card line, more value left for token

Debug (string str)
{
    //llOwnerSay(llGetScriptName() + ": " + str);
}
Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}
key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}
DoMenu(key keyID, integer iAuth)
{
    string sPrompt = "Pick an option.\nClick '" + DUMPCACHE + "' to dump all current settings to chat";
    sPrompt += "\n(You can then copy + paste them, overwriting your defaultsettings notecard)\n";
    sPrompt += "Click '" + WIKI + "' to get a link to the OpenCollar online user guide\n";
    list lButtons = [DUMPCACHE, WIKI];
    if (USER_PREF)
    {
        sPrompt += "Click '" + PREFDESI + "' to give Designer settings priority\n";
        lButtons += [PREFDESI];
    }
    else
    {
        sPrompt += "Click '" + PREFUSER + "' to give your personal settings priority\n";
        lButtons += [PREFUSER];
    }
    g_kMenuID = Dialog(keyID, sPrompt, lButtons, [UPMENU], 0, iAuth);
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
    if (~llListFindList(USER_SETTINGS, [token])) return TRUE;
    if (~llListFindList(DESIGN_SETTINGS, [token])) return TRUE;
    return FALSE;
}
list SetSetting(list cache, string token, string value)
{
    integer idx = llListFindList(cache, [token]);
    if (~idx) return llListReplaceList(cache, [value], idx + 1, idx + 1);
    idx = GroupIndex(cache, token);
    if (~idx) return llListInsertList(cache, [token, value], idx);
    return cache + [token, value];
}

// like SetSetting, but only sets the value if there's not one already there.
list AddSetting(list cache, string token, string value)
{
    integer i = llListFindList(cache, [token]);
    if (~i) return cache;
    i = GroupIndex(cache, token);
    if (~i) return llListInsertList(cache, [token, value], i);
    return cache + [token, value];
}

string GetSetting(string token)
{
    integer i = llListFindList(USER_SETTINGS, [token]);
    if (USER_PREF && ~i) return llList2String(USER_SETTINGS, i + 1);
    integer d = llListFindList(DESIGN_SETTINGS, [token]);
    if (~d) return llList2String(DESIGN_SETTINGS, d + 1);
    return llList2String(USER_SETTINGS, i + 1);
}
// per = number of entries to put in each bracket
list ListCombineEntries(list in, string add, integer per)
{
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

DumpGroupSettings(string group, key id)
{
    list sets;
    list out;
    string tok;
    string val;
    integer i;
    integer x;
    if (!USER_PREF) jump user;
    @designer;
    for (i = 0; i < llGetListLength(DESIGN_SETTINGS); i += 2)
    {
        tok = llList2String(DESIGN_SETTINGS, i);
        if (SplitToken(tok, 0) == group)
        {
            tok = SplitToken(tok, 1);
            val = llList2String(DESIGN_SETTINGS, i + 1);
            if (~x=llListFindList(out, [tok])) out = llListReplaceList(out, [val], x + 1, x + 1);
            else out += [tok, val];
        }
    }
    if (!USER_PREF) jump done;
    @user;
    for (i = 0; i < llGetListLength(USER_SETTINGS); i += 2)
    {
        tok = llList2String(USER_SETTINGS, i);
        if (SplitToken(tok, 0) == group)
        {
            tok = SplitToken(tok, 1);
            val = llList2String(USER_SETTINGS, i + 1);
            if (~x=llListFindList(out, [tok])) out = llListReplaceList(out, [val], x + 1, x + 1);
            else out += [tok, val];
        }
    }
    if (!USER_PREF) jump designer;
    @done;
    out = ListCombineEntries(out, "=", 2);
    tok = (string)id + "\\" + group+ " settings\\";
    while (llGetListLength(out))
    {
        val = llList2String(out, 0);
        if (llStringLength(tok + val) + 2 > SAY_LIMIT)
        {
            llRegionSayTo(id, 0, tok);
            tok = (string)id + "\\" + group + " settings\\" + val;
        }
        else tok += ";" + val;
        out = llDeleteSubList(out, 0, 0);
    }
    llRegionSayTo(id, INTERFACE_CHANNEL, tok);
}

DelSetting(string token) // we'll only ever delete user settings
{
    integer i = llGetListLength(USER_SETTINGS) - 1;
    if (SplitToken(token, 1) == "all")
    {
        token = SplitToken(token, 0);
        string var;
        for (; ~i; i -= 2)
        {
            if (SplitToken(llList2String(USER_SETTINGS, i - 1), 0) == token)
                USER_SETTINGS = llDeleteSubList(USER_SETTINGS, i - 1, i);
        }
        return;
    }
    i = llListFindList(USER_SETTINGS, [token]);
    if (~i) USER_SETTINGS = llDeleteSubList(USER_SETTINGS, i, i + 1);
}

// run delimiters & add escape-characters for DumpCache
list Add2OutList(list in)
{
    if (!llGetListLength(in)) return [];
    string set = DESIGN_ID;
    list out = ["#---Designer Defaults---#"];
    if (in == USER_SETTINGS)
    {
        set = "User_";
        out = ["#---My Settings---#"];
    }
    string new;
    string temp;
    string sid;
    string pre;
    string group;
    string tok;
    string val;
    integer i;
    for (; i < llGetListLength(in); i += 2)
    {
        tok = llList2String(in, i);
        val = llList2String(in, i + 1);
        group = SplitToken(tok, 0);
        tok = SplitToken(tok, 1);
        if (group != sid) // new group
        {
            sid = group;
            pre = "\n" + set + sid + "=";
        }
        else pre = "~";
        temp = pre + tok + "~" + val;
        while (llStringLength(temp))
        {
            new = temp;
            if (llStringLength(temp) > CARD_LIMIT)
            {
                new = llGetSubString(temp, 0, CARD_LIMIT - 2) + ESCAPE_CHAR;
                temp = llDeleteSubString(temp, 0, CARD_LIMIT - 2);
            }
            else temp = "";
            out += [new];
        }
    }
    out = llListReplaceList(out, [llList2String(out, -1)], -1, -1);
    return out;
}

DumpCache(key id)
{
    // compile everything into one list, so we can tell the user everything seamlessly
    list out;
    list say = ["Settings (Designer defaults, followed by User Entries)\n"];
    say += ["The below can be copied and pasted to \"defaultsettings\" notecard\n"];
    say += ["Replacing old entries, but must include Designer defaults (if present):\n"];
    say += Add2OutList(DESIGN_SETTINGS) + ["\n"];
    say += Add2OutList(USER_SETTINGS);
    string old;
    string new;
    integer c;
    while (llGetListLength(say))
    {
        new = llList2String(say, 0);
        c = llStringLength(old + new) + 2;
        if (c > SAY_LIMIT)
        {
            out += [old];
            old = "";
        }
        old += new;
        say = llDeleteSubList(say, 0, 0);
    }
    out += [old];
    while (llGetListLength(out))
    {
        Notify(id, llList2String(out, 0), TRUE);
        out = llDeleteSubList(out, 0, 0);
    }
}

SendValues()
{
    //loop through and send all the settings
    integer n = 0;
    string tok;
    list out;
    if (USER_PREF) jump DesignSet;
    @UserSet;
    for (; n < llGetListLength(USER_SETTINGS); n += 2)
    {
        tok = llList2String(USER_SETTINGS, n) + "=";
        tok += llList2String(USER_SETTINGS, n + 1);
        if (llListFindList(out, [tok]) == -1) out += [tok];
    }
    n = 0;
    if (USER_PREF) jump done;
    @DesignSet;
    for (; n < llGetListLength(DESIGN_SETTINGS); n += 2)
    {
        tok = llList2String(DESIGN_SETTINGS, n) + "=";
        tok += llList2String(DESIGN_SETTINGS, n + 1);
        if (llListFindList(out, [tok]) == -1) out += [tok];
    }
    n = 0;
    if (USER_PREF) jump UserSet;
    @done;
    for (; n < llGetListLength(out); n++)
    {
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, llList2String(out, n), NULL_KEY);
    }
    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "settings=sent", NULL_KEY);//tells scripts everything has be sentout
}

Refresh()
{
    llMessageLinked(LINK_THIS, MENUNAME_REQUEST, SUBMENU, NULL_KEY);
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + SUBMENU, NULL_KEY);
    SendValues();
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum != COMMAND_OWNER && iNum != COMMAND_WEARER) return FALSE;
    if (sStr == "menu " + SUBMENU || llToLower(sStr) == llToLower(SUBMENU))
    {
        DoMenu(kID, iNum);
        return TRUE;
    }
    if (llToLower(llGetSubString(sStr, 0, 4)) == "dump_")
    {
        sStr = llToLower(llGetSubString(sStr, 5, -1));
        if (sStr == "cache") DumpCache(kID);
        else DumpGroupSettings(sStr, kID);
        return TRUE;
    }
    integer i = llSubStringIndex(sStr, " ");
    string sid = llToLower(llGetSubString(sStr, 0, i - 1)) + "_";
    if (sid != llToLower(g_sScript)) return TRUE;
    string C = llToLower(llGetSubString(sStr, i + 1, -1));
    if (C == llToLower(PREFUSER))
    {
        USER_SETTINGS = SetSetting(USER_SETTINGS, g_sScript + "Pref", "User");
        USER_PREF = TRUE;
    }
    else if (C == llToLower(PREFDESI))
    {
        USER_SETTINGS = SetSetting(USER_SETTINGS, g_sScript + "Pref", "Designer");
        USER_PREF = FALSE;
    }
    else if (C == llToLower(DUMPCACHE))
    {
        DumpCache(kID);
    }
    else return FALSE;
    return TRUE;
}

default
{
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        // Ensure that settings resets AFTER every other script, so that they don't reset after they get settings
        llSleep(0.5);
        g_kWearer = llGetOwner();
        INTERFACE_CHANNEL = (integer)("0x"+llGetSubString((string)g_kWearer,2,7)) + 1111;
        if (INTERFACE_CHANNEL > 0) INTERFACE_CHANNEL *= -1;
        if (INTERFACE_CHANNEL > -10000) INTERFACE_CHANNEL -= 30000;
        defaultsline = 0;
        defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
        SCRIPTCOUNT=llGetInventoryNumber(INVENTORY_SCRIPT);
        card_key = llGetInventoryKey(defaultscard);
        DESIGN_ID = llGetObjectDesc();
        integer i = llSubStringIndex(DESIGN_ID, "~");
        DESIGN_ID = llGetSubString(DESIGN_ID, i + 1, -1);
        i = llSubStringIndex(DESIGN_ID, "~");
        DESIGN_ID = llGetSubString(DESIGN_ID, i + 1, -1);
    }

    on_rez(integer iParam)
    {
        // resend settings to plugins, if owner hasn't changed, in which case
        // reset the whole lot.
        if (g_kWearer == llGetOwner())
        {
            llSleep(0.5); // brief wait for others to reset
            Refresh();        
        }
        else llResetScript();
    }

    dataserver(key id, string data)
    {
        if (id == defaultslineid)
        {
            string sid;
            string tok;
            string val;
            integer i;
            if (data != EOF)
            {
                data = llStringTrim(data, STRING_TRIM_HEAD);
                // first we can filter out & skip blank lines & remarks
                if (data == "" || llGetSubString(data, 0, 0) == "#") jump nextline;
                // check for "continued" line pieces
                i = llSubStringIndex(data, ESCAPE_CHAR);
                if (~i || llStringLength(split_line))
                {
                    split_line += data; // append string
                    // if there is an escape character, lop it off and go to next line
                    if (~i)
                    {
                        split_line = llGetSubString(split_line, 0, -2);
                        jump nextline;
                    }
                    // if not, clear the temp string & process this data
                    data = split_line;
                    split_line = "";
                }
                // Next we wish to peel the special settings for this collar
                // unique collar id is followed by Script (that settings are for) + "=tok~val~tok~val"
                i = llSubStringIndex(data, "_");
                string id = llGetSubString(data, 0, i);
                if (id != DESIGN_ID && id != "User_") jump nextline;
                data = llGetSubString(data, i + 1, -1); // shave id off
                i = llSubStringIndex(data, "=");
                sid = (llGetSubString(data, 0, i - 1)) + "_";
                data = llGetSubString(data, i + 1, -1);
                list lData = llParseString2List(data, ["~"], []);
                for (i = 0; i < llGetListLength(lData); i += 2)
                {
                    tok = llList2String(lData, i);
                    val = llList2String(lData, i + 1);
                    if (sid == g_sScript) // a setting for this script
                    {
                        if (tok == "Pref" && val == "User") USER_PREF = TRUE;
                    }
                    if (id == DESIGN_ID) DESIGN_SETTINGS = SetSetting(DESIGN_SETTINGS, sid + tok, val);
                    else USER_SETTINGS = SetSetting(USER_SETTINGS, sid + tok, val);
                }
                @nextline;
                defaultsline++;
                defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
            }
            else
            {
                // wait a sec before sending settings, in case other scripts are
                // still resetting.
                llSleep(2.0);
                Refresh();
            }
        }
    }

    link_message(integer sender, integer iNum, string sStr, key id)
    {
        if (UserCommand(iNum, sStr, id)) return;
        if (iNum == LM_SETTING_SAVE)
        {
            //save the token, value
            list params = llParseString2List(sStr, ["="], []);
            string token = llList2String(params, 0);
            string value = llList2String(params, 1);
            // if it's a revert to a designer setting, wipe it from user list
            // otherwise, set it to user list
            if (~llListFindList(DESIGN_SETTINGS, [token, value])) DelSetting(token);
            else USER_SETTINGS = SetSetting(USER_SETTINGS, token, value);
        }
        else if (iNum == LM_SETTING_REQUEST)
        {
            //check the cache for the token
            if (SettingExists(sStr))
            {
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sStr + "=" + GetSetting(sStr), NULL_KEY);
            } 
            else
            {
                llMessageLinked(LINK_SET, LM_SETTING_EMPTY, sStr, NULL_KEY);
            }
        }
        else if (iNum == LM_SETTING_DELETE)
        {
            DelSetting(sStr);
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (id == g_kMenuID)
            {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                // request to switch to parent menu
                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_THIS, iAuth, "menu "+ PARENT_MENU, kAv);
                    return;
                }
                if (sMessage == WIKI)
                {
                    llSleep(0.2);
                    llLoadURL(kAv, "Read the online guide, check release notes and learn how to get involved on our website.", WIKI_URL);
                    return;
                }
                if (iAuth < COMMAND_OWNER || iAuth > COMMAND_WEARER) return;
                if (sMessage == PREFDESI)
                {
                    USER_PREF = FALSE;
                    USER_SETTINGS = SetSetting(USER_SETTINGS, g_sScript + "Pref", "Designer");
                }
                else if (sMessage == PREFUSER)
                {
                    USER_PREF = TRUE;
                    USER_SETTINGS = SetSetting(USER_SETTINGS, g_sScript + "Pref", "User");
                }
                else if (sMessage == DUMPCACHE)
                {
                    if (iAuth == COMMAND_OWNER || iAuth == COMMAND_WEARER) DumpCache(kAv);
                    else Notify(kAv, "Only Owners & Wearer may access this feature", FALSE);
                }
                DoMenu(kAv, iAuth);
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == PARENT_MENU)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + SUBMENU, NULL_KEY);
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            // timeout from menu system, you do not have to react on this, but you can
            if (id == g_kMenuID)
            {
                Debug("The user was to slow or lazy, we got a timeout!");
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER) llResetScript();
        if (change & CHANGED_INVENTORY)
        {
            if (SCRIPTCOUNT != llGetInventoryNumber(INVENTORY_SCRIPT))
            {
                // number of scripts changed
                // resend values and store new number
                SendValues();
                SCRIPTCOUNT=llGetInventoryNumber(INVENTORY_SCRIPT);
            }
            if (llGetInventoryKey(defaultscard) != card_key)
            {
                // the defaultsettings card changed.  Re-read it.
                defaultsline = 0;
                defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
                card_key = llGetInventoryKey(defaultscard);
            }
        }
    }
}
