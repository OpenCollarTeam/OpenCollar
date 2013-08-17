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
string WIKI = "Website";
string UPMENU = "^";
key g_kMenuID;
key g_kWearer;
string g_sStoredLine;
string g_sLINE_CONTINUATION = "&&";

string defaultscard = "defaultsettings";
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


string WIKI_URL = "http://www.opencollar.at";
string DESIGN_ID;
list DESIGN_SETTINGS;
list USER_SETTINGS;
integer USER_PREF = FALSE; // user switch
integer SCRIPTCOUNT; // number of scripts, to resend if the count changes

Debug (string str)
{
    //llOwnerSay(llGetScriptName() + ": " + str);
}

integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan>0)
    {
        iChan=iChan*(-1);
    }
    if (iChan > -10000)
    {
        iChan -= 30000;
    }
    return iChan;
}
Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else if (llGetAgentSize(kID) != ZERO_VECTOR)
    {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
    else // remote request
    {
        llRegionSayTo(kID, GetOwnerChannel(g_kWearer, 1111), sMsg);
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
    sPrompt += "Click '" + WIKI + "' to get a link to the OpenCollar website.\n";
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

string GetScriptID()
{
    // strip away "OpenCollar - " leaving the script's individual name
    list parts = llParseString2List(llGetScriptName(), ["-"], []);
    return llStringTrim(llList2String(parts, 1), STRING_TRIM) + "_";
}
// Get Group or Token, 0=Group, 1=Token
string PeelToken(string in, integer slot)
{
    integer i = llSubStringIndex(in, "_");
    if (!slot) return llGetSubString(in, 0, i - 1);
    return llGetSubString(in, i + 1, -1);
}
// To add new entries at the end of Groupings
integer GroupIndex(list cache, string token)
{
    string group = PeelToken(token, 0);
    integer i = llGetListLength(cache) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2)
    {
        if (PeelToken(llList2String(cache, i - 1), 0) == group) return i + 1;
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

DelSetting(string token) // we'll only ever delete user settings
{
    integer i = llGetListLength(USER_SETTINGS) - 1;
    if (PeelToken(token, 1) == "all")
    {
        token = PeelToken(token, 0);
        string var;
        for (; ~i; i -= 2)
        {
            if (PeelToken(llList2String(USER_SETTINGS, i - 1), 0) == token)
                USER_SETTINGS = llDeleteSubList(USER_SETTINGS, i - 1, i);
        }
        return;
    }
    i = llListFindList(USER_SETTINGS, [token]);
    if (~i) USER_SETTINGS = llDeleteSubList(USER_SETTINGS, i, i + 1);
}

DumpCache()
{
    string out = "\nSettings (Designer defaults, followed by User Entries)\n";
    out += "The below can be copied and pasted to \"defaultsettings\" notecard\n";
    out += "Replacing old entries, but must include Designer defaults (if present):";
    llWhisper(0, out);
    out = "\n#---Designer Defaults---";// prepended with # so that it can be pasted to NC
    string add;
    string sid;
    string tok;
    string val;
    integer i = llGetListLength(DESIGN_SETTINGS);
    integer c;
    integer n = 0;
    if (i < 1)
    {
        out = "\n#---No Designer Defaults---";
        jump UserSets;
    }
    for (; n < i; n += 2)
    {
        tok = llList2String(DESIGN_SETTINGS, n);
        val = llList2String(DESIGN_SETTINGS, n + 1);
        if (PeelToken(tok, 0) != sid) // new Group
        {
            sid = PeelToken(tok, 0);
            add = "\n" + DESIGN_ID + sid + "=";
        }
        else add = "~";
        tok = PeelToken(tok, 1);
        add += tok + "~" + val;
        c = llStringLength(out) + llStringLength(add) + 2;
        if (c > 255) // 1024 string limit (but only 255 allowed to be read from a notecard)
        {
            WhisperLine(out);
            add = "";
            out = "\n" + DESIGN_ID + sid + "=" + tok + "~" + val;
        }
        else out += add;
    }
    add = sid = tok = val = "";
    @UserSets;
    i = llGetListLength(USER_SETTINGS);
    if (!i) out += "#---No Personal Settings---";
    else out += "\n#---My Settings---";
    for (n = 0; n < i; n += 2)
    {
        tok = llList2String(USER_SETTINGS, n);
        val = llList2String(USER_SETTINGS, n + 1);
        if (PeelToken(tok, 0) != sid) // new Group
        {
            sid = PeelToken(tok, 0);
            add = "\nUser_" + sid + "=";
        }
        else add = "~";
        tok = PeelToken(tok, 1);
        add += tok + "~" + val;
        c = llStringLength(out) + llStringLength(add) + 2;
        if (c >= 255) // 1024 string limit (but only 255 allowed to be read from a notecard)
        {
            WhisperLine( out);
            add = "";
            out = "\nUser_" + sid + "=" + tok + "~" + val;
        }
        else out += add;
    }
    WhisperLine( out);
}

WhisperLine( string out )
{
    while ( llStringLength( out ) > 250 )
    {
        llWhisper( 0, llGetSubString( out, 0, 249 ) + g_sLINE_CONTINUATION );
        out = "\n" + llDeleteSubString( out, 0, 249 ) ;
    }
    llWhisper(0, out);
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
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    if (sStr == "menu " + SUBMENU || llToLower(sStr) == llToLower(SUBMENU))
    {
        DoMenu(kID, iNum);
        return TRUE;
    }
    integer i = llSubStringIndex(sStr, " ");
    string sid = llToLower(llGetSubString(sStr, 0, i - 1)) + "_";
    if (sid != llToLower(GetScriptID())) return FALSE;
    string C = llToLower(llGetSubString(sStr, i + 1, -1));
    if (C == llToLower(PREFUSER))
    {
        USER_SETTINGS = SetSetting(USER_SETTINGS, GetScriptID() + "Pref", "User");
        USER_PREF = TRUE;
    }
    else if (C == llToLower(PREFDESI))
    {
        USER_SETTINGS = SetSetting(USER_SETTINGS, GetScriptID() + "Pref", "Designer");
        USER_PREF = FALSE;
    }
    else if (C == llToLower(DUMPCACHE))
    {
        DumpCache();
    }
    else return FALSE;
    return TRUE;
}

default
{
    state_entry()
    {
        // Ensure that settings resets AFTER every other script, so that they don't reset after tehy get settings
        llSleep(0.5);
        g_kWearer = llGetOwner();
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
            if (data == EOF && g_sStoredLine != "" )
            {
                data = g_sStoredLine ;
                g_sStoredLine = "" ;
                Debug( "Dataserver EOF, stored line used, data = " + data ) ;
            }
            if (data != EOF)
            {
                if ( g_sStoredLine != "" ) 
                {
                    data = g_sStoredLine + data ;
                    g_sStoredLine = "" ;
                    Debug( "Dataserver - Appending line - data = " + data ) ;
                }
                data = llStringTrim(data, STRING_TRIM_HEAD);
                if ( llGetSubString(data, -2, -1) == g_sLINE_CONTINUATION )
                {
                    g_sStoredLine = llDeleteSubString( data, -2, -1 ) ;
                    data = "" ;
                    Debug( "Dataserver - Continuation - stored line = " + g_sStoredLine );
                }
                // first we can filter out & skip blank lines & remarks
                if (data == "" || llGetSubString(data, 0, 0) == "#") jump nextline;
                Debug( "Dataserver - Processing line = " + data );
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
                    if (sid == GetScriptID()) // a setting for this script
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
                    llLoadURL(kAv, "Read the online documentation, see the release note, get tips and infos for designers or report bugs on our website.", WIKI_URL);
                    return;
                }
                if (iAuth < COMMAND_OWNER || iAuth > COMMAND_WEARER) return;
                if (sMessage == PREFDESI)
                {
                    USER_PREF = FALSE;
                    USER_SETTINGS = SetSetting(USER_SETTINGS, GetScriptID() + "Pref", "Designer");
                }
                else if (sMessage == PREFUSER)
                {
                    USER_PREF = TRUE;
                    USER_SETTINGS = SetSetting(USER_SETTINGS, GetScriptID() + "Pref", "User");
                }
                else if (sMessage == DUMPCACHE) DumpCache();
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