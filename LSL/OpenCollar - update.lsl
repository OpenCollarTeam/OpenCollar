//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//on attach and on state_entry, http request for update

// First generation updater for the SubAO and Owner Hud.

integer willingUpdaters = -1;
key wearer;
integer updatersNearby = -1;
key updater;
string updatemethod = "inplace";
integer updatehandle;
integer updateChannel;
key httprequest;
string g_szCurrentVersion;
string g_szBetaUpdater=" Dev/Beta/RC";
key g_keyBetaHTTPrequest;
integer checked = FALSE;
string baseurl = "http://collardata.appspot.com/updater/check?";
integer UPDATE = 10001;


debug(string message)
{
    
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


CheckForUpdate()
{
    list params = llParseString2List(llGetObjectDesc(), ["~"], []);
    string name = llList2String(params, 0);
    g_szCurrentVersion = llList2String(params, 1);

    
    if (llGetAttached()==0) return;

    
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
                
                
                
            }
            else if (body=="current")
            {
                
                float v=((float)g_szCurrentVersion)*10;
                v=v-llFloor(v);
                if (v>=0.20)
                {
                    
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
                llSetTimerEvent(5.0); 
            }
        }
    }
    listen(integer channel, string name, key id, string message)
    {   
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
                    integer pin = (integer)llFrand(99999998.0) + 1; 
                llSetRemoteScriptAccessPin(pin);
                llWhisper(updateChannel, "ready|" + (string)pin ); 
            }
            updatersNearby = -1;
            willingUpdaters = -1;
        }
        if (!checked)
        {
            
            
            
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
