// update Seb 2011.  Remove http data storage (it's too expensive with app engine price change).


//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//DEFAULT STATE

//on state entry, get db prefix from desc
//look for default settings notecard.  if there, start reading
//if not there, move straight to ready state

//on httpdb link message, stick command on queue

//READY STATE
//on state_entry, send new link message for each item on queue
//before sending HTTPDB_EMPTY on things, check default settings list.  send default if present

key g_kWearer = NULL_KEY;

string g_sParentMenu = "Help/Debug";
string DUMPCACHE = "Dump Settings";

float g_iTimeOut = 30.0; //changing to a integer to be constant with other script we will mostlike remove this latter.

list g_lDefaults;
string g_sCard = "defaultsettings";
integer g_iLine = 0;
key g_kDataID;

list g_lSettings;// stores all settings

//MESSAGE MAP

integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer CHAT = 505;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer HTTPDB_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer HTTPDB_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer HTTPDB_RESPONSE = 2002;//the httpdb script will send responses on this channel
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


string WIKI ="Online Guide";
string WIKI_URL = "http://wiki.mycollar.org/UserDocumentation";

string BASE_ERROR_MESSAGE = "An error has occurred. To find out more about this error go to http://code.google.com/p/opencollar/wiki/ErrorMessages If you get this a lot, please open a ticket at http://bugs.mycollar.org \n";

integer g_iRemenu=FALSE; // should the menu appear after the link message is handled?

integer g_iScriptCount; // number of script to resend if the coutn changes

Debug (string sStr) {
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    } else {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
}

integer SettingExists(list cache, string sToken) {
    integer iIndex = llListFindList(cache, [sToken]);
    if (iIndex == -1) {
        return FALSE;
    } else {
        return TRUE;
    }
}

list SetCacheVal(list cache, string sToken, string sValue) {
    integer iIndex = llListFindList(cache, [sToken]);
    if (iIndex == -1) {
        cache += [sToken, sValue];
    } else {
        cache = llListReplaceList(cache, [sValue], iIndex + 1, iIndex + 1);
    }
    return cache;
}

string GetSetting(list cache, string sToken) {
    integer iIndex = llListFindList(cache, [sToken]);
    return llList2String(cache, iIndex + 1);
}

list DelSetting(list cache, string sToken) {
    integer iIndex = llListFindList(cache, [sToken]);
    if (iIndex != -1) {
        cache = llDeleteSubList(cache, iIndex, iIndex + 1);
    }
    return cache;
}

DumpCache() {
    string sOut = "Settings:";


    integer n;
    integer iStop = llGetListLength(g_lSettings);

    for (n = 0; n < iStop; n = n + 2) {
        //handle strlength > 1024
        string sAdd = llList2String(g_lSettings, n) + "=" + llList2String(g_lSettings, n + 1) + "\n";
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
    //loop through and send all the settings and defaults we've got
    
    //settings first
    integer n;
    integer iStop = llGetListLength(g_lSettings);
    for (n = 0; n < iStop; n = n + 2) {
        string sToken = llList2String(g_lSettings, n);
        string sValue = llList2String(g_lSettings, n + 1);
        llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sToken + "=" + sValue, NULL_KEY);
        
        // also send a local setting response, since we don't know which kind of setting they originally tried to do.
        // this is a legacy distinction from when we saved some settings to httpdb and kept some locally
        llMessageLinked(LINK_SET, LOCALSETTING_RESPONSE, sToken + "=" + sValue, NULL_KEY);        
    }

    //now loop through g_lDefaults, sending only if there's not a corresponding token in g_lSettings
    iStop = llGetListLength(g_lDefaults);
    for (n = 0; n < iStop; n = n + 2) {
        string sToken = llList2String(g_lDefaults, n);
        string sValue = llList2String(g_lDefaults, n + 1);
        if (!SettingExists(g_lSettings, sToken)) {
            llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sToken + "=" + sValue, NULL_KEY);
        }
    }
    llMessageLinked(LINK_SET, HTTPDB_RESPONSE, "settings=sent", NULL_KEY);//tells scripts everything has be sentout
}

Refresh() {
    // register menus
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + DUMPCACHE, NULL_KEY);
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + WIKI, NULL_KEY);
    SendValues();
}

default {
    state_entry() {

        // if we're just starting up, save owner and read defaults
        if (g_kWearer == NULL_KEY) {
            //if we just started, save owner key
            g_kWearer = llGetOwner();
            // and read default settings
            g_iLine = 0;
            g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
        }
        
        // Remember how many scripts are in the prim so we can resend settings when new ones are added
        g_iScriptCount=llGetInventoryNumber(INVENTORY_SCRIPT);
    }

    on_rez(integer iParam) {
        // resend settings to plugins, if owner hasn't changed.
        if (g_kWearer == llGetOwner()) {
            Refresh();        
        } else {
            llResetScript();
        }
    }

    dataserver(key kID, string sData) {
        if (kID == g_kDataID) {
            if (sData != EOF) {
                sData = llStringTrim(sData, STRING_TRIM_HEAD);
                if (llGetSubString(sData, 0, 0) != "#") {
                    integer iIndex = llSubStringIndex(sData, "=");
                    string sToken = llGetSubString(sData, 0, iIndex - 1);
                    string sValue = llGetSubString(sData, iIndex + 1, -1);
                    g_lDefaults += [sToken, sValue];
                }
                g_iLine++;
                g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
            }
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == HTTPDB_SAVE || iNum == LOCALSETTING_SAVE) {
            //save the token, value
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            g_lSettings = SetCacheVal(g_lSettings, sToken, sValue);
        } else if (iNum == HTTPDB_REQUEST || iNum == HTTPDB_REQUEST_NOCACHE || iNum == LOCALSETTING_REQUEST) {
            //check the dbcache for the token
            // responses are sent both as HTTPDB and LOCALSETTING until all scripts can use just SETTING
            if (SettingExists(g_lSettings, sStr)) {
                llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sStr + "=" + GetSetting(g_lSettings, sStr), NULL_KEY);
                llMessageLinked(LINK_SET, LOCALSETTING_RESPONSE, sStr + "=" + GetSetting(g_lSettings, sStr), NULL_KEY);
            } else if (SettingExists(g_lDefaults, sStr)) {
                llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sStr + "=" + GetSetting(g_lDefaults, sStr), NULL_KEY);
                llMessageLinked(LINK_SET, LOCALSETTING_RESPONSE, sStr + "=" + GetSetting(g_lDefaults, sStr), NULL_KEY);
            } else {
                llMessageLinked(LINK_SET, HTTPDB_EMPTY, sStr, NULL_KEY);
                llMessageLinked(LINK_SET, LOCALSETTING_EMPTY, sStr, "");                
            }
        } else if (iNum == HTTPDB_DELETE || iNum == LOCALSETTING_DELETE) {
            g_lSettings = DelSetting(g_lSettings, sStr);
        } else if ( (sStr == "wiki") && (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)) {
            // open the wiki page
            if  (g_iRemenu)
            {
                g_iRemenu=FALSE;
                llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
                llSleep(0.2);
            }
            llLoadURL(kID, "Read the online documentation, see the release note, get tips and infos for designers or report bugs on our website.", WIKI_URL);
        } else if (iNum == COMMAND_OWNER || ((iNum > COMMAND_OWNER) && (iNum < 600) && (kID == g_kWearer))) {
            if (sStr == "cachedump") {
                DumpCache();
            }
            else if (sStr == "reset" || sStr == "runaway") {
                g_lSettings = [];
            }
        } else if (iNum == SUBMENU) {
            if (sStr == DUMPCACHE) {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "cachedump", kID);

                llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
            } else if (sStr == WIKI) {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "wiki", kID);
                g_iRemenu = TRUE;
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + DUMPCACHE, NULL_KEY);
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + WIKI, NULL_KEY);
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) {
            llResetScript();
        }

        if ((iChange==CHANGED_INVENTORY)&&(g_iScriptCount!=llGetInventoryNumber(INVENTORY_SCRIPT))) {
            // number of scripts changed
            // resend values and store new number
            SendValues();
            g_iScriptCount=llGetInventoryNumber(INVENTORY_SCRIPT);
        }
    }
}
