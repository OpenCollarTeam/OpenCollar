//OpenCollar - settings - 3.521
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
string g_sSyncFromDB = "Sync<-DB";
//string synctodb = "Sync<-DB"; //we still lack the subsystem for requesting settings from all scripts
string DUMPCACHE = "Dump Cache";
string g_sOnLineButton; // will be initialized after

string g_sOnLineON = "(*)Online";
string g_sOnLineOFF = "( )Online";

integer g_iRemoteOn = FALSE;
float g_iTimeOut = 30.0; //changing to a integer to be constant with other script we will mostlike remove this latter.
string sQueueUrl = "http://web.mycollar.org/";
key g_kQueueID;

list g_lDefaults;
list g_lRequestQueue;//requests are stuck here until we're done reading the notecard and web settings
string g_sCard = "defaultsettings";
integer g_iLine = 0;
key g_kDataID;
list g_lDeleteIDs;//so we do not throw 404 errors on them


list g_lDBCache;
list g_lLocalCache;//stores settings that we dont' want to save to DB because they change so frequently
key g_kAllID;
string ALLTOKEN = "_all";

//MESSAGE MAP
integer JSON_REQUEST = 201;
integer JSON_RESPONSE = 202;

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

string g_sHTTPDB = "http://data.mycollar.org/"; //db url no longer a constant
key    g_kReqIDLoad;                          // request id

//string dbprefix = "oc_";  //deprecated.  only appearance-related tokens should be prefixed now
//on a per-plugin basis

list g_sTokenIDs;//strided list of token names and their corresponding request ids, so that token names can be returned in link messages

integer g_iOnLine=TRUE; //are we syncing with http or not?

integer g_iRemenu=FALSE; // should the menu appear after the link message is handled?

list g_lKeep_on_Cleanup=["owner","secowners","openaccess","group","groupname","rlvon","locked","prefix","channel"]; // values to be restored when a database cleanup is performed

integer g_iScriptCount; // number of script to resend if the coutn changes

Debug (string sStr)
{
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

integer CacheValExists(list cache, string sToken)
{
    integer iIndex = llListFindList(cache, [sToken]);
    if (iIndex == -1)
    {
        return FALSE;
    }
    else
    {
        return TRUE;
    }
}

list SetCacheVal(list cache, string sToken, string sValue)
{
    integer iIndex = llListFindList(cache, [sToken]);
    if (iIndex == -1)
    {
        cache += [sToken, sValue];
    }
    else
    {
        cache = llListReplaceList(cache, [sValue], iIndex + 1, iIndex + 1);
    }
    return cache;
}

string GetCacheVal(list cache, string sToken)
{
    integer iIndex = llListFindList(cache, [sToken]);
    return llList2String(cache, iIndex + 1);
}

list DelCacheVal(list cache, string sToken)
{
    integer iIndex = llListFindList(cache, [sToken]);
    if (iIndex != -1)
    {
        cache = llDeleteSubList(cache, iIndex, iIndex + 1);
    }
    return cache;
}

// Save a value to httpdb with the specified name.
HTTPDBSave( string sName, string sValue )
{
    llHTTPRequest( g_sHTTPDB + "db/" + sName, [HTTP_METHOD, "PUT"], sValue );
    //llHTTPRequest( g_sHTTPDB + "db/" + sName+"?p=TRUE", [HTTP_METHOD, "POST"], sValue );//work aorund google error
    llSleep(1.0);//sleep added to prevent hitting the sim's http throttle limit
}

// Load named data from httpdb.
HTTPDBLoad( string sName )
{
    g_sTokenIDs += [sName, llHTTPRequest( g_sHTTPDB + "db/" + sName, [HTTP_METHOD, "GET"], "" )];
    llSleep(1.0);//sleep added to prevent hitting the sim's http throttle limit
}

HTTPDBDelete(string sName) {
    //httpdb_request( HTTPDB_DELETE, "DELETE", sName, "" );
    g_lDeleteIDs += llHTTPRequest(g_sHTTPDB + "db/" + sName, [HTTP_METHOD, "DELETE"], "");
    //llHTTPRequest(g_sHTTPDB + "db/" + sName+"?d=TRUE", [HTTP_METHOD, "POST"], "");//work aorund google error
    llSleep(1.0);//sleep added to prevent hitting the sim's http throttle limit
}

CheckQueue()
{
    Debug("querying queue");
    g_kQueueID = llHTTPRequest(sQueueUrl, [HTTP_METHOD, "GET"], "");
}

DumpCache(string sWichCache)
{
    list lCache;
    string sOut;
    if (sWichCache == "local")
    {
        lCache=g_lLocalCache;
        sOut = "Local Settings Cache:";
    }
    else
    {
        lCache=g_lDBCache;
        sOut = "DB Settings Cache:";
    }


    integer n;
    integer iStop = llGetListLength(lCache);

    for (n = 0; n < iStop; n = n + 2)
    {
        //handle strlength > 1024
        string sAdd = llList2String(lCache, n) + "=" + llList2String(lCache, n + 1) + "\n";
        if (llStringLength(sOut + sAdd) > 1024)
        {
            //spew and clear
            llWhisper(0, "\n" + sOut);
            sOut = sAdd;
        }
        else
        {
            //keep adding
            sOut += sAdd;
        }
    }
    llWhisper(0, "\n" + sOut);
}

string JSONSettings()
{
    list lCache;
    lCache=g_lLocalCache + g_lDBCache;

    return Serialize(lCache, "");
}

init()
{
    if (g_kWearer == NULL_KEY)
    {//if we just started, save owner key
        g_kWearer = llGetOwner();
    }
    else if (g_kWearer != llGetOwner())
    {//we've changed hands.  reset script
        llResetScript();
    }

    if (!g_iOnLine) // don't lose settings in memory in offline mode
    {
        llOwnerSay("Running in offline mode. Using cached values only.");
        state ready;
        return;
    }
    g_lDefaults = [];//in case we just switched from the ready state, clean this now to avoid duplicates.
    if (llGetInventoryType(g_sCard) == INVENTORY_NOTECARD)
    {
        g_iLine = 0;
        g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
    }
    else
    {
        //default settings card not found, prepare for 'ready' state
        if (g_iOnLine) g_kAllID = llHTTPRequest(g_sHTTPDB + "db/" + ALLTOKEN, [HTTP_METHOD, "GET"], "");
    }
}

SendValues()
{
    //loop through all the settings and defaults we've got
    //settings first
    integer n;
    integer iStop = llGetListLength(g_lDBCache);
    for (n = 0; n < iStop; n = n + 2)
    {
        string sToken = llList2String(g_lDBCache, n);
        string sValue = llList2String(g_lDBCache, n + 1);
        llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sToken + "=" + sValue, NULL_KEY);
    }

    //now loop through g_lDefaults, sending only if there's not a corresponding token in g_lDBCache
    iStop = llGetListLength(g_lDefaults);
    for (n = 0; n < iStop; n = n + 2)
    {
        string sToken = llList2String(g_lDefaults, n);
        string sValue = llList2String(g_lDefaults, n + 1);
        if (!CacheValExists(g_lDBCache, sToken))
        {
            llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sToken + "=" + sValue, NULL_KEY);
        }
    }

    //and now loop through g_lLocalCache
    iStop = llGetListLength(g_lLocalCache);
    for (n = 0; n < iStop; n = n + 2)
    {
        string sToken = llList2String(g_lLocalCache, n);
        string sValue = llList2String(g_lLocalCache, n + 1);
        llMessageLinked(LINK_SET, LOCALSETTING_RESPONSE, sToken + "=" + sValue, NULL_KEY);
        Debug("sent local: " + sToken + "=" + sValue);
    }
    llMessageLinked(LINK_SET, HTTPDB_RESPONSE, "settings=sent", NULL_KEY);//tells scripts everything has be sentout
}

// Serialize a list into a string that can later be deserialized
// with correct type for each field
string Serialize(list lInput, string sIndicators) {
    sIndicators += "|/?!@#$%^&*()_=:;~`'<>{}[],.\n\" aeiouAEIOU\\";
    string sOutput = (string)(lInput);
    integer iPos;
    string sRealIndicators;
    while( iPos < 6 ) {
        if( 0 > llSubStringIndex(sOutput,llGetSubString(sIndicators,0,0)) ) {
            iPos++;
            sRealIndicators += llGetSubString(sIndicators,0,0);
        }
        sIndicators = llDeleteSubString(sIndicators,0,0);
    }
    sOutput = sRealIndicators;
    iPos = 0;
    while(llGetListLength(lInput) > iPos) {
        integer type = llGetListEntryType(lInput, iPos);
        sOutput += llGetSubString(sRealIndicators,type,type) + llList2String(lInput,iPos++);
    }
    return sOutput;
}


default
{
    state_entry()
    {
        init();
    }

    on_rez(integer iParam)
    {
        init();
    }

    dataserver(key kID, string sData)
    {
        if (kID == g_kDataID)
        {
            if (sData != EOF)
            {
                sData = llStringTrim(sData, STRING_TRIM_HEAD);
                if (llGetSubString(sData, 0, 0) != "#")
                {
                    integer iIndex = llSubStringIndex(sData, "=");
                    string sToken = llGetSubString(sData, 0, iIndex - 1);
                    string sValue = llGetSubString(sData, iIndex + 1, -1);
                    if (sToken=="online")
                    {
                        g_iOnLine = (integer) sValue;
                    }
                    else if (sToken=="HTTPDB")
                    {
                        g_sHTTPDB = sValue;
                    }
                    else if (sToken=="queueurl")
                    {
                        sQueueUrl = sValue;
                    }
                    g_lDefaults += [sToken, sValue];
                }
                g_iLine++;
                g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
            }
            else
            {
                //done reading notecard, switch to ready state
                if (g_iOnLine) g_kAllID = llHTTPRequest(g_sHTTPDB + "db/" + ALLTOKEN, [HTTP_METHOD, "GET"], "");
                else
                {
                    llOwnerSay("Running in offline mode. Using defaults and dbcached values.");
                    state ready;
                }
            }
        }
    }

    http_response(key kID, integer iStatus, list lMeta, string sBody)
    {
        string sOwners;
        if (kID == g_kAllID)
        {
            if (iStatus == 200)
            {
                //got all settings page, parse it
                g_lDBCache = [];
                list g_iLines = llParseString2List(sBody, ["\n"], []);
                integer iStop = llGetListLength(g_iLines);
                integer n;
                for (n = 0; n < iStop; n++)
                {
                    list lParams = llParseString2List(llList2String(g_iLines, n), ["="], []);
                    string sToken = llList2String(lParams, 0);
                    string sValue = llList2String(lParams, 1);
                    g_lDBCache = SetCacheVal(g_lDBCache, sToken, sValue);
                    if (sToken == "owner")
                    {
                        sOwners = sValue;
                    }
                }
                if (llStringLength(sBody)>=2040)
                {
                    string sPrefix;
                    if (CacheValExists(g_lDBCache, "prefix"))
                    {
                        sPrefix=GetCacheVal(g_lDBCache, "prefix");
                    }
                    else
                    {
                        string s=llKey2Name(g_kWearer);
                        integer i=llSubStringIndex(s," ")+1;

                        sPrefix=llToLower(llGetSubString(s,0,0)+llGetSubString(s,i,i));
                    }
                    llOwnerSay("ATTENTION: Settings loaded from web database, but the answer was so long that SL probably truncated it. This means, that your settings are probably not correctly saved anymore. This usually happens when you tested a lot of different collars. To fix this, you can type \""+sPrefix+"cleanup\" in open chat, this will clear ALL your saved values but the owners, lock and RLV. Sorry for inconvenience.");
                }
                else
                {
                    if (sOwners == "")
                    {
                        llOwnerSay("Collar ready. You are unowned.");
                    }
                    else
                    {
                        llOwnerSay("Collar ready. You are owned by: " + llList2CSV(llList2ListStrided(llParseString2List("dummy," + sOwners,[","],[]),1,-1,2)) + ".");
                    }
                }
            }
            else
            {
                llOwnerSay("Unable to contact web database.  Using defaults and dbcached values.");
                Notify(g_kWearer, BASE_ERROR_MESSAGE+"Start ERROR:"+(string)iStatus+" b:"+sBody, TRUE);
            }
            sOwners = "";
            state ready;
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == HTTPDB_REQUEST || iNum == HTTPDB_SAVE || iNum == HTTPDB_DELETE)
        {
            //we don't want to process these yet so queue them til done reading the notecard
            g_lRequestQueue += [iNum, sStr, kID];
        }
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
}

state ready
{
    state_entry()
    {
        llSleep(1.0);

        // send the values stored in the cache
        SendValues();

        // and store the number of scripts
        g_iScriptCount=llGetInventoryNumber(INVENTORY_SCRIPT);

        //tell the world about our menu button
        //        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + synctodb, NULL_KEY);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSyncFromDB, NULL_KEY);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + DUMPCACHE, NULL_KEY);
        if (g_iOnLine) g_sOnLineButton=g_sOnLineON;
        else g_sOnLineButton=g_sOnLineOFF;
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sOnLineButton, NULL_KEY);

        // allow to link to the wiki
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + WIKI, NULL_KEY);

        CheckQueue();
        //llSetTimerEvent(g_iTimeOut);

        //resend any requests that came while we weren't looking
        integer n;
        integer iStop = llGetListLength(g_lRequestQueue);
        for (n = 0; n < iStop; n = n + 3)
        {
            llMessageLinked(LINK_SET, (integer)llList2String(g_lRequestQueue, n), llList2String(g_lRequestQueue, n + 1), (key)llList2String(g_lRequestQueue, n + 2));
        }
        g_lRequestQueue = [];

    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {

        //HandleRequest(iNum, sStr, kID);
        //Debug("Link Message: iNum=" + (string)iNum + ", sStr=" + sStr + ", kID=" + (string)kID);
        if (iNum == HTTPDB_SAVE)
        {
            //save the token, value
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (g_iOnLine) HTTPDBSave(sToken, sValue);
            g_lDBCache = SetCacheVal(g_lDBCache, sToken, sValue);
        }
        else if (iNum == HTTPDB_REQUEST)
        {
            //check the dbcache for the token
            if (CacheValExists(g_lDBCache, sStr))
            {
                llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sStr + "=" + GetCacheVal(g_lDBCache, sStr), NULL_KEY);
            }
            else if (CacheValExists(g_lDefaults, sStr))
            {
                llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sStr + "=" + GetCacheVal(g_lDefaults, sStr), NULL_KEY);
            }
            else
            {
                llMessageLinked(LINK_SET, HTTPDB_EMPTY, sStr, NULL_KEY);
            }
        }
        else if (iNum == HTTPDB_REQUEST_NOCACHE)
        {
            //request the token
            if (g_iOnLine) HTTPDBLoad(sStr);
        }
        else if (iNum == HTTPDB_DELETE)
        {
            g_lDBCache = DelCacheVal(g_lDBCache, sStr);
            if (g_iOnLine) HTTPDBDelete(sStr);
        }
        else if (iNum == HTTPDB_RESPONSE && sStr == "remoteon=1")
        {
            g_iRemoteOn = TRUE;
            CheckQueue();
            llSetTimerEvent(g_iTimeOut);
        }
        else if (iNum == HTTPDB_RESPONSE && sStr == "remoteon=0")
        {
            g_iRemoteOn = FALSE;
            llSetTimerEvent(0.0);
        }
        else if (iNum == LOCALSETTING_SAVE)
        {// add/set a setting in the local cache
            Debug("localsave: " + sStr);
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            g_lLocalCache = SetCacheVal(g_lLocalCache, sToken, sValue);
        }
        else if (iNum == LOCALSETTING_REQUEST)
        {//return a setting from the local cache
            if (CacheValExists(g_lLocalCache, sStr))
            {//return value
                llMessageLinked(LINK_SET, LOCALSETTING_RESPONSE, sStr + "=" + GetCacheVal(g_lLocalCache, sStr), "");
            }
            else
            {//return empty
                llMessageLinked(LINK_SET, LOCALSETTING_EMPTY, sStr, "");
            }
        }
        else if (iNum == LOCALSETTING_DELETE)
        {//remove a setting from the local cache
            g_lLocalCache = DelCacheVal(g_lLocalCache, sStr);
        }
        else if ( (sStr == "wiki") && (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER))
            // open the wiki page
        {
            if  (g_iRemenu)
            {
                g_iRemenu=FALSE;
                llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
                llSleep(0.2);
            }
            llLoadURL(kID, "Read the online documentation, see the release note, get tips and infos for designers or report bugs on our website.", WIKI_URL);
        }
        else if (iNum == COMMAND_OWNER || ((iNum > COMMAND_OWNER) && (iNum < 600) && (kID == g_kWearer)))
        {
            if (sStr == "cachedump")
            {
                DumpCache("db");
                DumpCache("local");
            }
            else if (sStr == "reset" || sStr == "runaway")
            {
                g_lDBCache = [];
                g_lLocalCache = [];
                if (g_iOnLine)
                {
                    llHTTPRequest( g_sHTTPDB + "db/" + ALLTOKEN+"?d=TRUE", [HTTP_METHOD, "POST"], "");
                    llSleep(2.0);
                    //save that we got a reset command:
                    llMessageLinked(LINK_SET, HTTPDB_SAVE, "lastReset=" + (string)llGetUnixTime(), "");
                }
                // moved to Auth to allow owner notification on runaway
                // llSleep(1.0);
                // llMessageLinked(LINK_SET, COMMAND_OWNER, "resetscripts", kID);
                //no more self resets
                //llResetScript();
            }
            else if (sStr == "remoteon")
            {
                if (g_iOnLine)
                {
                    g_iRemoteOn = TRUE;
                    //do http request for cmd list
                    CheckQueue();
                    //set timer to do same
                    llSetTimerEvent(g_iTimeOut);
                    Notify(kID, "Remote On.",TRUE);
                    llMessageLinked(LINK_SET, HTTPDB_SAVE, "remoteon=1", NULL_KEY);
                }
                else Notify(kID, "Sorry, remote control only works in online mode.", FALSE);
            }
            else if (sStr == "remoteoff")
            {
                //wearer can't turn remote off
                if (iNum != COMMAND_OWNER)
                {
                    Notify(kID, "Sorry, only the primary owner can turn off the remote.",FALSE);
                }
                else
                {
                    g_iRemoteOn = FALSE;
                    llSetTimerEvent(0.0);
                    Notify(kID, "Remote Off.", TRUE);
                    llMessageLinked(LINK_SET, HTTPDB_SAVE, "remoteon=0", NULL_KEY);
                }
            }
            else if (sStr == "online")
            {
                //wearer can't change online mode
                if (iNum != COMMAND_OWNER || kID != g_kWearer)
                {
                    Notify(kID, "Sorry, only a self-owned wearer can enable online mode.", FALSE);
                }
                else
                {
                    g_iOnLine = TRUE;
                    llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sOnLineButton, NULL_KEY);
                    // sned online notification to other scripts using a variable "online"
                    llMessageLinked(LINK_SET, HTTPDB_RESPONSE,"online=1",NULL_KEY);
                    Notify(kID, "Online mode enabled. Restoring settings from database.", TRUE);
                    state default;
                }
                if (g_iRemenu) {g_iRemenu=FALSE; llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);}
            }
            else if (sStr == "offline")
            {
                //wearer can't change online mode
                if (iNum != COMMAND_OWNER || kID != g_kWearer)
                {
                    Notify(kID, "Sorry, only a self-owned wearer can enable offline mode.", FALSE);
                }
                else
                {
                    g_iOnLine = FALSE;
                    llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sOnLineButton, NULL_KEY);
                    g_sOnLineButton = g_sOnLineOFF;
                    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sOnLineButton, NULL_KEY);
                    // sned online notification to other scripts using a variable "online"
                    llMessageLinked(LINK_SET, HTTPDB_RESPONSE,"online=0",NULL_KEY);
                    Notify(kID, "Online mode disabled.", TRUE);

                }
                if (g_iRemenu) {g_iRemenu=FALSE; llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);}
            }
            else if (sStr == "cleanup")
                // delete vaues stored in the DB and restores thr most important setting
            {
                if (!g_iOnLine)
                    // if we are offline, we dont do anything
                {
                    llOwnerSay("Your collar is offline mode, so you cannot perform a cleanup of the HTTP database.");
                }
                else
                {
                    // we are online, so we inform the user
                    llOwnerSay("The settings from the database will now be deleted. After that the settings for the following values will restored, but you might need to restore settings for badword, colors, textures etc.: "+llList2CSV(g_lKeep_on_Cleanup)+".\nThe cleanup may take about 1 minute.");
                    // delete the values fromt he db and take a nap
                    llHTTPRequest( g_sHTTPDB + "db/" + ALLTOKEN+"?d=TRUE", [HTTP_METHOD, "POST"], "");
                    llSleep(3.0);
                    // before we dbcache the settings to be restored
                    integer m=llGetListLength(g_lKeep_on_Cleanup);
                    integer i;
                    string t;
                    string v;
                    list tempg_lDBCache;
                    for (i=0;i<m;i++)
                    {
                        t=llList2String(g_lKeep_on_Cleanup,i);
                        if (CacheValExists(g_lDBCache, t))
                        {
                            tempg_lDBCache+=[t,GetCacheVal(g_lDBCache, t)];
                        }
                    }
                    // now we can clean the dbcache
                    g_lDBCache=[];
                    // and restore the values we
                    m=llGetListLength(tempg_lDBCache);
                    for (i=0;i<m;i=i+2)
                    {
                        t=llList2String(tempg_lDBCache,i);
                        v=llList2String(tempg_lDBCache,i+1);
                        HTTPDBSave(t, v);
                        g_lDBCache = SetCacheVal(g_lDBCache, t, v);
                    }
                    llOwnerSay("The cleanup has been performed. You can use the collar normaly again, but some of your previous settings may need to be redone. Resetting now.");
                    llMessageLinked(LINK_SET, HTTPDB_SAVE, "lastReset=" + (string)llGetUnixTime(), "");

                    llSleep(1.0);

                    llMessageLinked(LINK_SET, COMMAND_OWNER, "resetscripts", kID);
                }

            }
        }
        else if (iNum == SUBMENU)
        {
            if (sStr == g_sSyncFromDB)
            {
                //notify that we're refreshing
                Notify(kID, "Refreshing settings from web database.", TRUE);
                //return parent menu
                llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
                //refetch settings
                state default;
            }
            else if (sStr == DUMPCACHE)
            {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "cachedump", kID);

                llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
            }
            else if (sStr == g_sOnLineButton)
            {
                if (g_iOnLine) llMessageLinked(LINK_SET, COMMAND_NOAUTH, "offline", kID);
                else llMessageLinked(LINK_SET, COMMAND_NOAUTH, "online", kID);
                g_iRemenu = TRUE;
            }
            else if (sStr == WIKI)
            {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "wiki", kID);
                g_iRemenu = TRUE;
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            //            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + synctodb, NULL_KEY);
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSyncFromDB, NULL_KEY);
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + DUMPCACHE, NULL_KEY);
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sOnLineButton, NULL_KEY);
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + WIKI, NULL_KEY);
        }
        else if (iNum == JSON_REQUEST)
        {
            list lTmp = llParseStringKeepNulls(sStr, ["|"], []);
            string sQuery = llList2String(lTmp, 2);
            if (sQuery == "settings")
            {
                llMessageLinked(LINK_SET,JSON_RESPONSE, JSONSettings(), kID);
            }
        }
    }

    http_response( key kID, integer iStatus, list lMeta, string sBody )
    {
        integer iIndex = llListFindList(g_sTokenIDs, [kID]);
        if ( iIndex != -1 )
        {
            string sToken = llList2String(g_sTokenIDs, iIndex - 1);
            if (iStatus == 200)
            {
                string sOut = sToken + "=" + sBody;
                llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sOut, NULL_KEY);
                g_lDBCache = SetCacheVal(g_lDBCache, sToken, sBody);
            }
            else if (iStatus == 404)
            {
                //check g_lDefaults, send if present, else send HTTPDB_EMPTY
                //integer iIndex = llListFindList(g_lDefaults, [sToken]);
                iIndex = llListFindList(g_lDefaults, [sToken]);
                if (iIndex == -1)
                {
                    llMessageLinked(LINK_SET, HTTPDB_EMPTY, sToken, NULL_KEY);
                }
                else
                {
                    llMessageLinked(LINK_SET, HTTPDB_RESPONSE, sToken + "=" + llList2String(g_lDefaults, iIndex + 1), NULL_KEY);
                }
            }
            else
            {
                Notify(g_kWearer, BASE_ERROR_MESSAGE+"Token ERROR:"+(string)iStatus+" b:"+sBody, TRUE);
            }
            //remove token, id from list
            g_sTokenIDs = llDeleteSubList(g_sTokenIDs, iIndex - 1, iIndex);
        }
        else if (kID == g_kQueueID)//got a queued remote command
        {
            if (iStatus == 200)
            {
                //parse page, send cmds
                list g_iLines = llParseString2List(sBody, ["\n"], []);
                integer n;
                integer iStop = llGetListLength(g_iLines);
                for (n = 0; n < iStop; n++)
                {
                    //each line is pipe-delimited
                    list g_iLine = llParseString2List(llList2String(g_iLines, n), ["|"], []);
                    string sStr = llList2String(g_iLine, 0);
                    key iSender = (key)llList2String(g_iLine, 1);
                    Debug("got queued cmd: " + sStr + " from " + (string)iSender);
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, sStr, iSender);
                }
            }
            else if (iStatus > 299)
            {
                Notify(g_kWearer, BASE_ERROR_MESSAGE+"Queue ERROR:"+(string)iStatus+" b:"+sBody, TRUE);
            }
        }
        else if (iStatus < 300 )
        {
            //nothing
            iIndex = llListFindList(g_lDeleteIDs, [kID]);
            if (iIndex != -1)
            {
                g_lDeleteIDs = llDeleteSubList(g_lDeleteIDs, iIndex, iIndex);
            }
        }
        else
        {
            iIndex = llListFindList(g_lDeleteIDs, [kID]);
            if (iIndex != -1)
            {
                g_lDeleteIDs = llDeleteSubList(g_lDeleteIDs, iIndex, iIndex);
                if (iStatus == 404)
                {
                    Debug("404 on delete");
                    return;//this is not an error
                }
            }
            Notify(g_kWearer, BASE_ERROR_MESSAGE+"ERROR:"+(string)iStatus+" b:"+sBody, TRUE);
        }
    }

    on_rez(integer iParam)
    {
        state default;
    }

    timer()
    {
        //if (g_iRemoteOn)//now using httpin
        //{
        //CheckQueue();
        //}
        //else
        //{
        //technically we should never get here, but if we do we should shut down the timer.
        llSetTimerEvent(0.0);
        //}
    }

    changed(integer iChange)
    {
        if ((iChange==CHANGED_INVENTORY)&&(g_iScriptCount!=llGetInventoryNumber(INVENTORY_SCRIPT)))
            // number of scripts changed
        {
            // resend values and store new number
            SendValues();
            g_iScriptCount=llGetInventoryNumber(INVENTORY_SCRIPT);
        }
    }
}

