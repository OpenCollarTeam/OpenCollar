//OpenCollar - settings
// This script stores settings for other scripts in the collar.  In bygone days
// it was responsible for storing them to an online database too.  It doesn't
// do that anymore.  But so long as plugin scripts are still using central
// storage like this, it's always possible we could bring back an online DB or
// someone could offer a third party one.

key wearer = NULL_KEY;

string parentmenu = "Help/Debug";
string DUMPCACHE = "Dump Settings";

string defaultscard = "defaultsettings";
integer defaultsline = 0;
key defaultslineid;
key card_key;

list settings_pairs;// stores all settings
list settings_default; // Default settings placeholder.

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


string WIKI ="Online Guide";
string WIKI_URL = "http://wiki.mycollar.org/UserDocumentation";

integer remenu=FALSE; // should the menu appear after the link message is handled?

integer scriptcount; // number of script to resend if the coutn changes

Debug (string str) {
    //llOwnerSay(llGetScriptName() + ": " + str);
}

Notify(key id, string sMsg, integer iAlsoNotifyWearer) {
    if (id == wearer) {
        llOwnerSay(sMsg);
    } else {
        llInstantMessage(id,sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
}

integer SettingExists(list cache, string token) {
    integer idx = llListFindList(cache, [token]);
    if (idx == -1) {
        return FALSE;
    } else {
        return TRUE;
    }
}

list SetSetting(list cache, string token, string value) {
    integer idx = llListFindList(cache, [token]);
    if (idx == -1) {
        cache += [token, value];
    } else {
        cache = llListReplaceList(cache, [value], idx + 1, idx + 1);
    }
    return cache;
}

// like SetSetting, but only sets the value if there's not one already there.
list SetDefault(list cache, string token, string value) {
    integer idx = llListFindList(cache, [token]);
    if (idx == -1) {
        cache += [token, value];
        // also let the plugins know about it
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, token + "=" + value, NULL_KEY);
    }
    return cache;
}

string GetSetting(list cache, string token) {
    integer idx = llListFindList(cache, [token]);
    return llList2String(cache, idx + 1);
}

list DelSetting(list cache, string token) {
    integer idx = llListFindList(cache, [token]);
    if (idx != -1) {
        cache = llDeleteSubList(cache, idx, idx + 1);
    }
    return cache;
}

DumpCache() {
    string sOut = "Settings: \n";


    integer n;
    integer iStop = llGetListLength(settings_pairs);

    for (n = 0; n < iStop; n = n + 2) {
        //handle strlength > 1024
        string sAdd = llList2String(settings_pairs, n) + "=" + llList2String(settings_pairs, n + 1) + "\n";
        if (llStringLength(sOut + sAdd) > 1024) {
            //spew and clear
            llWhisper(0, "\n" + sOut);
            sOut = sAdd;
        } else {
            //keep adding
            sOut += sAdd;
        }
    }
    llWhisper(0, "\n" + sOut);
}

SendValues() {
    //loop through and send all the settings
    integer n;
    integer iStop = llGetListLength(settings_pairs);
    for (n = 0; n < iStop; n = n + 2) {
        string token = llList2String(settings_pairs, n);
        string value = llList2String(settings_pairs, n + 1);
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, token + "=" + value, NULL_KEY);
    }

    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "settings=sent", NULL_KEY);//tells scripts everything has be sentout
}

Refresh() {
    // register menus
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + DUMPCACHE, NULL_KEY);
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + WIKI, NULL_KEY);
    SendValues();
}

default {
    state_entry() {
        //save wearer key
        wearer = llGetOwner();

        // and read default settings
        defaultsline = 0;
        defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
        
        // Remember how many scripts are in the prim so we can resend settings when new ones are added
        scriptcount=llGetInventoryNumber(INVENTORY_SCRIPT);

        // Remember the uuid of the 'defaultsettings' notecard so we can
        // re-read it if it changes.
        card_key = llGetInventoryKey(defaultscard);
    }

    on_rez(integer iParam) {
        // resend settings to plugins, if owner hasn't changed, in which case
        // reset the whole lot.
        if (wearer == llGetOwner()) {
            // wait a sec before sending settings, in case other scripts are
            // still resetting.
            llSleep(0.5);
            Refresh();        
        } else {
            llResetScript();
        }
    }

    dataserver(key id, string data) {
        if (id == defaultslineid) {
            if (data != EOF) {
                data = llStringTrim(data, STRING_TRIM_HEAD);
                if (llGetSubString(data, 0, 0) != "#") {
                    integer idx = llSubStringIndex(data, "=");
                    string token = llGetSubString(data, 0, idx - 1);
                    string value = llGetSubString(data, idx + 1, -1);
                    // Take multiple lines and puts them together,
                    //  workaround for llGetNotecardLine() limitation.
                    if (SettingExists(settings_default,token))
                    {
                        integer loc = llListFindList(settings_default, [token]) + 1;
                        string sep = ",";
                        if (token == "oc_colorsettings" ||
                            token == "aipcpc_colorsettings" ||
                            token == "oc_textures")
                        {
                            sep = "~";
                        }
                        value = llList2String(settings_default, loc) + sep + value;
                    }
                    settings_default = SetSetting(settings_default, token, value);
                }
                defaultsline++;
                defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
            }
            else
            {
                // Merge defaults with settings.
                string sToken;
                string sValue;
                integer count;
                for (count = 0; count < llGetListLength(settings_default); count += 2)
                {
                    sToken = llList2String(settings_default, count);
                    sValue = llList2String(settings_default, (count + 1));
                    settings_pairs = SetDefault(settings_pairs, sToken, sValue);
                }
                // wait a sec before sending settings, in case other scripts are
                // still resetting.
                llSleep(2.0);
                Refresh();
            }
        }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == LM_SETTING_SAVE)
        {
            //save the token, value
            list params = llParseString2List(str, ["="], []);
            string token = llList2String(params, 0);
            string value = llList2String(params, 1);
            settings_pairs = SetSetting(settings_pairs, token, value);
        }
        else if (num == LM_SETTING_REQUEST)
        {
            //check the cache for the token
            if (SettingExists(settings_pairs, str))
            {
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, str + "=" + GetSetting(settings_pairs, str), NULL_KEY);
            } 
            else
            {
                llMessageLinked(LINK_SET, LM_SETTING_EMPTY, str, NULL_KEY);
            }
        }
        else if (num == LM_SETTING_DELETE)
        {
            settings_pairs = DelSetting(settings_pairs, str);
        }
        else if (num >= COMMAND_OWNER && num <= COMMAND_WEARER)
        {
            integer loadurl = FALSE; integer remenu = FALSE;
            if (str == "wiki") loadurl = TRUE;
            else if (str == "menu "+WIKI) {loadurl = TRUE; remenu = TRUE;}
            else if (num == COMMAND_OWNER || id == wearer)
            {
                if (str == "cachedump") DumpCache();
                else if (str == "menu "+DUMPCACHE) { DumpCache(); remenu = TRUE; }
                else if (str == "reset" || str == "runaway") llResetScript();
                else return;
            }
            else return;
            if (remenu) llMessageLinked(LINK_SET, num, "menu " + parentmenu, id);
            if (loadurl)
            {
                llSleep(0.2);
                llLoadURL(id, "Read the online documentation, see the release note, get tips and infos for designers or report bugs on our website.", WIKI_URL);
            }
        }
        else if (num == MENUNAME_REQUEST && str == parentmenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + DUMPCACHE, NULL_KEY);
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + WIKI, NULL_KEY);
        }
    }

    changed(integer change) {
        if (change & CHANGED_OWNER) {
            llResetScript();
        }

        if (change & CHANGED_INVENTORY) {
            if (scriptcount!=llGetInventoryNumber(INVENTORY_SCRIPT)) {
                // number of scripts changed
                // resend values and store new number
                SendValues();
                scriptcount=llGetInventoryNumber(INVENTORY_SCRIPT);
            }

            if (llGetInventoryKey(defaultscard) != card_key) {
                // the defaultsettings card changed.  Re-read it.
                defaultsline = 0;
                defaultslineid = llGetNotecardLine(defaultscard, defaultsline);
                card_key = llGetInventoryKey(defaultscard);
            }
        }
    }
}