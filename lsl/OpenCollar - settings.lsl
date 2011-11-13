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
integer CHAT = 505;

integer POPUP_HELP = 1001;

// scripts send messages on this channel to have settings saved to httpdb
// str must be in form of "token=value"
integer HTTPDB_SAVE = 2000;

//when startup, scripts send requests for settings on this channel
integer HTTPDB_REQUEST = 2001;

//the httpdb script will send responses on this channel
integer HTTPDB_RESPONSE = 2002;
integer HTTPDB_DELETE = 2003;//delete token from DB
integer HTTPDB_EMPTY = 2004;//sent when a token has no value in the httpdb
integer HTTPDB_REQUEST_NOCACHE = 2005;

integer LOCALSETTING_SAVE = 2500;
integer LOCALSETTING_REQUEST = 2501;
integer LOCALSETTING_RESPONSE = 2502;
integer LOCALSETTING_DELETE = 2503;
integer LOCALSETTING_EMPTY = 2504;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer MENUNAME_REMOVE = 3003;

// separator to enable setting/deleting/retrieving multiple settings
// (name1=value1|name2=value2|...)
string SEPARATOR = "|";

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
        llMessageLinked(LINK_SET, HTTPDB_RESPONSE, token + "=" + value, NULL_KEY);
        llMessageLinked(LINK_SET, LOCALSETTING_RESPONSE, token + "=" + value, NULL_KEY);        
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
    string sOut = "Settings:";


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
        llMessageLinked(LINK_SET, HTTPDB_RESPONSE, token + "=" + value, NULL_KEY);
        
        // also send a local setting response, since we don't know which kind of setting they originally tried to do.
        // this is a legacy distinction from when we saved some settings to httpdb and kept some locally
        llMessageLinked(LINK_SET, LOCALSETTING_RESPONSE, token + "=" + value, NULL_KEY);        
    }

    llMessageLinked(LINK_SET, HTTPDB_RESPONSE, "settings=sent", NULL_KEY);//tells scripts everything has be sentout
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
                Refresh();
            }
        }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == HTTPDB_SAVE || num == LOCALSETTING_SAVE) {
            list nv_pairs = llParseString2List (str, [SEPARATOR], []);
            do {
                //save the token, value
                list params = llParseString2List
                    (llList2String (nv_pairs, 0), ["="], []);
                string token = llList2String(params, 0);
                string value = llList2String(params, 1);
                settings_pairs = SetSetting(settings_pairs, token, value);
            }
            while ((nv_pairs = llDeleteSubList (nv_pairs, 0, 0)) != []);

        } else if (num == HTTPDB_REQUEST
                   || num == HTTPDB_REQUEST_NOCACHE
                   || num == LOCALSETTING_REQUEST) {
            list names = llParseString2List (str, [SEPARATOR], []);
            string response = "";
            string notexist = "";
            do {
                // check the dbcache for the token
                // responses are sent both as HTTPDB and LOCALSETTING until all 
                // scripts can use just SETTING
                string name = llList2String (names, 0);
                if (SettingExists(settings_pairs, name)) {
                    response = response + name + "="
                        + GetSetting(settings_pairs, name) + SEPARATOR;
                } else {
                    notexist = notexist + name + SEPARATOR;
                }
            } while ((names = llDeleteSubList (names, 0, 0)) != []);

            if (llStringLength (response) != 0) {
                response = llGetSubString (response, 0, -2);
                llMessageLinked (LINK_SET, HTTPDB_RESPONSE, response, "");
                llMessageLinked
                    (LINK_SET, LOCALSETTING_RESPONSE, response, "");
            }
            if (llStringLength (notexist) != 0) {
                notexist = llGetSubString (notexist, 0, -2);
                llMessageLinked (LINK_SET, HTTPDB_EMPTY, notexist, "");
                llMessageLinked (LINK_SET, LOCALSETTING_EMPTY, notexist, "");
            }

        } else if (num == HTTPDB_DELETE || num == LOCALSETTING_DELETE) {
            list names = llParseString2List (str, [SEPARATOR], []);
            do {
                settings_pairs
                    = DelSetting(settings_pairs, llList2String (names, 0));
            } while ((names = llDeleteSubList (names, 0, 0)) != []);

        } else if ( (str == "wiki") 
                    && (num >= COMMAND_OWNER && num <= COMMAND_WEARER)) {
            // open the wiki page
            if  (remenu)
            {
                remenu=FALSE;
                llMessageLinked(LINK_SET, SUBMENU, parentmenu, id);
                llSleep(0.2);
            }
            llLoadURL(id, "Read the online documentation, see the release note, get tips and infos for designers or report bugs on our website.", WIKI_URL);
        } else if (num == COMMAND_OWNER || ((num > COMMAND_OWNER) && (num < 600) && (id == wearer))) {
            if (str == "cachedump") {
                DumpCache();
            }
            else if (str == "reset" || str == "runaway") {
                llResetScript();
            }
        } else if (num == SUBMENU) {
            if (str == DUMPCACHE) {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "cachedump", id);

                llMessageLinked(LINK_SET, SUBMENU, parentmenu, id);
            } else if (str == WIKI) {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "wiki", id);
                remenu = TRUE;
            }
        } else if (num == MENUNAME_REQUEST && str == parentmenu) {
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
