//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//on attach and on state_entry, http request for update

// First generation updater for the SubAO and Owner Hud.  
// Plans for this script: (3.5) -> Merge with collar updates from issue 760

key wearer;

integer UPDATE = 10001;

string dbtoken = "updatemethod";//valid values are "replace" and "inplace"
string updatemethod = "inplace";

integer updatehandle;

string baseurl = "http://update.mycollar.org/updater/check?";

key httprequest;

integer checked = FALSE;//set this to true after checking version

key updater; // key of avi who asked for the update
integer updatersNearby = -1;
integer willingUpdaters = -1;

string g_szCurrentVersion; // version of the collar
string g_szBetaUpdater=" Dev/Beta/RC";
key g_keyBetaHTTPrequest;

debug(string message)
{
    //llOwnerSay("DEBUG " + llGetScriptName() + ": " + message);
}

integer updateChannel;
DoChannelSetup()
{   
    list params = llParseString2List(llGetObjectDesc(), ["~"], []);
    string updateName = llList2String(params, 0);
     
    if (llSubStringIndex(updateName,"OpenCollar Sub AO") == 0)
        updateChannel = -7483211;
    else if (llSubStringIndex(updateName,"OpenCollar Owner Hud") == 0)
        updateChannel = -7483212;
    else if (llSubStringIndex(updateName,"OpenCollar") == 0)
        updateChannel = -7483210; 
}

Notify(key id, string msg, integer alsoNotifyWearer) {
    if (id == wearer) {
        llOwnerSay(msg);
    } else {
            llInstantMessage(id,msg);
        if (alsoNotifyWearer) {
            llOwnerSay(msg);
        }
    }
}

CheckForUpdate()
{
    list params = llParseString2List(llGetObjectDesc(), ["~"], []);
    string name = llList2String(params, 0);
    g_szCurrentVersion = llList2String(params, 1);

    // dont check updates if rezzed inworld;
    if (llGetAttached()==0) return;

    //handle in-place updates.
    if (updatemethod == "inplace")
    {    
        if (llSubStringIndex(name,"OpenCollar Owner Hud") == 0)
            name = "OC Owner Hud Updater";
        else if (llSubStringIndex(name,"OpenCollar Sub AO") == 0)
            name = "OC Sub AO Updater";
        else if (llSubStringIndex(name,"OpenCollar") == 0)
            name = "OpenCollar Updater";
    }

    g_szBetaUpdater = name + g_szBetaUpdater;

    if (name == "" || g_szCurrentVersion == "")
    {
        llOwnerSay("You have changed my description.  Automatic updates are disabled.");
    }
    else if ((float)g_szCurrentVersion)
    {
        string url = baseurl;
        url += "object=" + llEscapeURL(name);
        url += "&version=" + llEscapeURL(g_szCurrentVersion);
        httprequest = llHTTPRequest(url, [HTTP_METHOD, "GET"], "");
    }
}
ReadyToUpdate(integer del)
{
    integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
    llSetRemoteScriptAccessPin(pin);
    llWhisper(updateChannel, "ready|" + (string)pin ); //give the ok to send update sripts etc...
}

default
{
    state_entry()
    {
        DoChannelSetup();
        wearer = llGetOwner();
        llSetTimerEvent(10.0);
    }
    on_rez(integer param)
    {
        llResetScript();
    }

    http_response(key request_id, integer status, list metadata, string body)
    {
        if (request_id == httprequest)
        {
            if (llGetListLength(llParseString2List(body, ["|"], [])) == 2)
            {
                llOwnerSay("There is a new version of me available.  An update should be delivered in 30 seconds or less.");
                //client side is done now.  server has queued the delivery,
                //and in-world giver will send us our object when it next
                //pings the server
            }
            else if (body=="current")
            {
                // the version is current, check if the collar isda beta (betas have a subversion higher than x.x20
                float v=((float)g_szCurrentVersion)*10;
                v=v-llFloor(v);
                if (v>=0.20)
                {
                    // it is a beta, so check if there is a newer beta                {
                    string url = baseurl;
                    url += "object=" + llEscapeURL(g_szBetaUpdater);
                    url += "&version=" + llEscapeURL(g_szCurrentVersion);
                    g_keyBetaHTTPrequest = llHTTPRequest(url, [HTTP_METHOD, "GET"], "");
                }
            }

        }
        else if (request_id == g_keyBetaHTTPrequest)
        {
            if (llGetListLength(llParseString2List(body, ["|"], [])) == 2)
            {
                llOwnerSay("There is a new Beta version of me available.  An update should be delivered in 30 seconds or less.");
                //client side is done now.  server has queued the delivery,
                //and in-world giver will send us our object when it next
                //pings the server
            }
        }
    }

    link_message(integer sender, integer auth, string str, key id)
    {
        if (auth == UPDATE && str == "Update")
        {
            if (llGetAttached())
            {
                Notify(id, "Sorry, the AO cannot be updated while attached.  Rez it on the ground and try again.",FALSE);
            }
            else
            {
                string version = llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 1);
                updatersNearby = 0;
                willingUpdaters = 0;
                updater = id;
                Notify(id,"Searching for nearby updater",FALSE);
                updatehandle = llListen(updateChannel, "", "", "");
                llWhisper(updateChannel, "UPDATE|" + version);
                llSetTimerEvent(5.0); //set a timer to close the listener if no response
            }
        }
    }
    listen(integer channel, string name, key id, string message)
    {   //collar and updater have to have the same Owner else do nothing!
        debug(message);
        if (llGetOwnerKey(id) == wearer)
        {
            list temp = llParseString2List(message, [","],[]);
            string command = llList2String(temp, 0);
            if(message == "nothing to update")
            {
                updatersNearby++;
            }
            else if( message == "get ready")
            {
                updatersNearby++;
                willingUpdaters++;
            }
        }
    }
    timer()
    {
        llSetTimerEvent(0.0);
        llListenRemove(updatehandle);
        if (updatersNearby > -1) {
            if (!updatersNearby) {
                Notify(updater,"No updaters found.  Please rez an updater within 10m and try again",FALSE);
            } else if (willingUpdaters > 1) {
                    Notify(updater,"Multiple updaters were found within 10m.  Please remove all but one and try again",FALSE);
            } else if (willingUpdaters) {
                    integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
                llSetRemoteScriptAccessPin(pin);
                llWhisper(updateChannel, "ready|" + (string)pin ); //give the ok to send update sripts etc...
            }
            updatersNearby = -1;
            willingUpdaters = -1;
        }
        if (!checked)
        {
            //there can be only one update script in the prim.  make it so
            //ThereCanBeOnlyOne();
            //check version after
            CheckForUpdate();
            checked = TRUE;
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            wearer = llGetOwner();
        }
    }
}
