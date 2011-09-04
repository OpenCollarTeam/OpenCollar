//OpenCollar - remoteserver - 3.529
string g_sBROADCAST_URL = "http://web.mycollar.org/lookup/";
string g_sWEBINTERFACE_URL = "http://web.mycollar.org/";
string g_sWEBINTERFACE_PUBLIC_URL = "http://web.mycollar.org/publichttp/?key=";

key g_kNewUrlRequest;
key g_kBroadcastRequest;
key g_kBroadcastRequestDel;
string g_sCurrentUrl = "";
string g_sOwnPass = "";
string g_sSecPass = "";
string g_sPubPass = "";
integer g_iErrPass = 0;

key g_kWearer;

integer g_iEnabled = 1; // httpin is enabled
integer g_iPubEnabled = 0;//anyone can control in SL
integer g_iWebMap = 0; // The user allows to publishlocations on the web interface, defaults to off!

list g_lCallBacks;

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
integer RLV_CMD = 6000;

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

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string g_sSubMenu = "Remote";
string g_sParentMenu = "Main";
key g_kDialogID;

string g_sMenu_HTTP_Enabled = "(*)Remote/Web";
string g_sMenu_HTTP_Disabled = "( )Remote/Web";
string g_sMenu_WebMap_Enabled = "(*)WebMap";
string g_sMenu_WebMap_Disabled = "( )WebMap";
string g_sMenu_PublicHTTP_Enabled = "(*)Public Web Access";
string g_sMenu_PublicHTTP_Disabled = "( )Public Web Access";
string g_sMenu_WebInterFace = "Web Interface";
string g_sMenu_PublicWebInterFace = "Public Web";



list g_lButtons;

integer g_iRemenu=FALSE;


string UPMENU = "^";//when your menu hears this, give the parent menu

Debug(string sStr)
{
    //llOwnerSay(sStr);
}

key ShortKey()
{//just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sChars = "0123456789abcdef";
    integer iLength = 16;
    string sOut;
    integer n;
    for (n = 0; n < 8; n++)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString(sChars, iIndex, iIndex);
    }

    return (key)(sOut + "-0000-0000-0000-000000000000");
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage)
{
    key kID = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    return kID;
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

//===============================================================================
//= parameters   :   key kID   ID of talking person
//=
//= return        :    none
//=
//= description  :    generate the menu for the HTTPIN settings
//=
//===============================================================================

DoMenu(key kID)
{
    string sPrompt = "For remote purposes HTTPin is used to communicate with the Owner HUD and the Web Interface. The wearer of the collar can enable additionaly WebMap to show their location on the Web Interface.\n\nIf you enable Public Web Access than anyone can control the sub from the web interface.\nClick \"" + g_sMenu_WebInterFace + "\" to got to the webpage";
    if (g_iPubEnabled)
    {
        sPrompt += " or \"" + g_sMenu_PublicWebInterFace + "\" to go to the PUBLIC page";
    }
    sPrompt += ".\n\n";
    
    // sPrompt += "(Menu will time out in " + (string)g_iTimeOut + " seconds.)\n";
    list lMyButtons;


    //fill in your button list here

    if (g_iEnabled == 0)
    {
        lMyButtons += g_sMenu_HTTP_Disabled;
        sPrompt += "Remote access is disabled. IF you enable it more options will become available.";
    }
    else
    {
        lMyButtons += g_sMenu_HTTP_Enabled;
        sPrompt += "Remote access is enabled, public access from the web page is ";
        if (g_iPubEnabled)
        {
            lMyButtons += g_sMenu_PublicHTTP_Enabled;
            sPrompt += "enabled, ";
        }
        else
        {
            lMyButtons += g_sMenu_PublicHTTP_Disabled;
            sPrompt += "disabled, ";
        }
        if (g_iWebMap)
        {
            lMyButtons += g_sMenu_WebMap_Enabled;
            sPrompt += "the sub can be tracked via the Web Interface.\n";
        }
        else
        {
            lMyButtons += g_sMenu_WebMap_Disabled;
            sPrompt += "the sub can NOT be tracked via the Web Interface.\n";
        }

    }

    lMyButtons += g_sMenu_WebInterFace;
    if (g_iPubEnabled)
    {
        lMyButtons += g_sMenu_PublicWebInterFace;
    }


    g_kDialogID=Dialog(kID, sPrompt, lMyButtons + g_lButtons, [UPMENU], 0);
}

NewURL()
{
    if(llGetFreeURLs() == 0)
    {
        Debug("Unable to generate new url because there are not enough free urls");
        return;
    }
    if(g_iEnabled == 0)
    {
        Debug("Unable to generate new url because the system is disabled");
        return;
    }
    Debug("Requesting new url. Remaining urls: " + (string)llGetFreeURLs());
    g_kNewUrlRequest = llRequestURL();
    g_iErrPass = 0;
    g_sOwnPass = RandomPass();
    g_sSecPass = RandomPass();
    if (g_iPubEnabled)
    {
        g_sPubPass = RandomPass();
    }
    else
    {
        g_sPubPass = "disabled";
    }
}

string RandomPass()
{//just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sChars = "0123456789abcdef";
    integer iLength = 16;
    string sOut;
    integer n;
    for (n = 0; n < 4; n++)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString(sChars, iIndex, iIndex);
    }

    return sOut;
}

ClearURL()
{
    if(g_sCurrentUrl == "")
    {
        Debug("Released access url");
        llReleaseURL(g_sCurrentUrl);
    }
    Debug("Deleting access url");
    g_sCurrentUrl = "";
    // do we need to react here on g_iWebMap?
    g_kBroadcastRequestDel = llHTTPRequest(g_sBROADCAST_URL, [HTTP_METHOD, "DELETE"], "");
    //g_kBroadcastRequestDel = llHTTPRequest(g_sBROADCAST_URL+"d=True", [HTTP_METHOD, "POST"], "");
}
//moded from wiki
string StrReplace(string sStr, string sSearch, string sReplace) {
    return llDumpList2String(llParseStringKeepNulls((sStr = "") + sStr, [sSearch], []), sReplace);
}
//***********************************************************replace with new vars
// Convert a strided list to json format
string Strided2JSON(list lInput)
{
    integer iInputLen = llGetListLength(lInput);
    integer c;
    list lOutput;

    for(c = 0; c < iInputLen; c+=2)
    {
        string sCurrVal = llList2String(lInput,c+1);
        if( llGetListEntryType(lInput,c+1) > 2 ) {
            sCurrVal = "'" + Sanitize(sCurrVal) + "'";
        }
        lOutput += [llList2String(lInput,c) + ": " + sCurrVal];
    }
    return "{" + llDumpList2String(lOutput, ",") + "}";
}

// Escape embedded single quotes
string Sanitize(string sInput) {
    string sOutput = (sInput);
    integer iInputLen = llStringLength(sOutput);
    integer iCurrPos = 0;
    while( iCurrPos < iInputLen ) {
        if( llGetSubString(sOutput,iCurrPos,iCurrPos) == "'" ) {
            if( iCurrPos > 0 )
                sOutput = llGetSubString(sOutput,0,iCurrPos-1) + "\\" + llGetSubString(sOutput,iCurrPos,-1);
            else
                sOutput = "\\" + sOutput;
            iCurrPos++;
            iInputLen++;
        }
        iCurrPos++;
    }
    return sOutput;
}

// wrap a jsonified object in a callback
string JSONCallback(string sData, string sCB)
{
    return sCB + "(" + sData + ");";
}

// Deserialize a string to a list with correct typing
list Deserialize(string sInput) {
    if( llStringLength(sInput) < 7 )
        return [];
    list lParsed;
    list lIndicators;
    integer c = 0;
    while( c < 7 ) {
        lIndicators = lIndicators + [llGetSubString(sInput,c,c++)];
    }
    sInput = llGetSubString(sInput,6,-1);
    while( 0 < llStringLength(sInput) ) {
        integer lPos = 0;
        integer iType = llListFindList(lIndicators, [llGetSubString(sInput,0,0)]);
        integer iMaxLen = llStringLength(sInput);
        while( 0 > llListFindList(lIndicators,[llGetSubString(sInput,lPos + 1,lPos + 1)]) && lPos < iMaxLen )
            lPos++;
        string sCurrent = llGetSubString(sInput,1,lPos);
        sInput = llDeleteSubString(sInput, 0, lPos);
        if( 1 == iType )
            lParsed = lParsed + [(integer)sCurrent];
        else if( 2 == iType )
            lParsed = lParsed + [(float)sCurrent];
        else if( 3 == iType )
            lParsed = lParsed + [sCurrent];
        else if( 4 == iType )
            lParsed = lParsed + [(key)sCurrent];
        else if( 5 == iType )
            lParsed = lParsed + [(vector)sCurrent];
        else if( 6 == iType )
            lParsed = lParsed + [(rotation)sCurrent];
        else
            lParsed = lParsed + [""];
    }
    return lParsed;
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
//********************************************************end


SaveHTTP()
{
    integer iHTTPInValue = g_iEnabled + (g_iWebMap * 2) + (g_iPubEnabled * 4);
    // we need to save 0, as HTTPin is default on
    llMessageLinked(LINK_SET, HTTPDB_SAVE, "httpon=" + (string) iHTTPInValue, NULL_KEY);
}

InformWearer()
{
    if (g_iEnabled)
    {
        string sOutput = "Http Remote Server is online";
        if (g_iWebMap)
        {
            sOutput += ", WebMapping enabled";
        }
        else
        {
            sOutput += ", WebMapping disabled";
        }
        if (g_iPubEnabled)
        {
            sOutput += ", Public HTTP access on";
        }
        else
        {
            sOutput += ", Public HTTP access off";
        }
        llOwnerSay(sOutput+".");
    }
}

default
{
    state_entry()
    {
        Debug("State Entry!");
        NewURL();
        g_kWearer=llGetOwner();
        g_sWEBINTERFACE_PUBLIC_URL = "http://web.mycollar.org/publichttp/?key=" + (string)g_kWearer;
        llSleep(1.0);

        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);

    }

    on_rez(integer n)
    {
        Debug("On Rez!");
        NewURL();

    }

    changed(integer c)
    {
        if (c & (CHANGED_REGION | CHANGED_REGION_START | CHANGED_TELEPORT) )
        {
            Debug("Changed Event!");
            NewURL();
        }
    }

    http_request(key kID, string sMethod, string sBody)
    {  //llOwnerSay("key:"+(string)kID+" method:"+sMethod+" body:"+sBody+" path:"+llGetHTTPHeader(kID, "x-path-info")+" query:"+llGetHTTPHeader(kID, "x-query-string"));
        if ((sMethod == URL_REQUEST_GRANTED) && (kID == g_kNewUrlRequest) )
        {
            g_sCurrentUrl = sBody;
            g_kNewUrlRequest = NULL_KEY;
            Debug("Obtained URL: " + g_sCurrentUrl);
            // react on g_iWebMap, maybe use post and put? as the url is now a "directory" i dont think i can simpyl add a "?Map=0", or can i?
            g_kBroadcastRequest = llHTTPRequest(g_sBROADCAST_URL, [HTTP_METHOD, "PUT"], g_sCurrentUrl+"|"+g_sOwnPass+"|"+g_sSecPass+"|"+g_sPubPass+"|"+(string)g_iWebMap);
            //g_kBroadcastRequest = llHTTPRequest(g_sBROADCAST_URL+"?p=True", [HTTP_METHOD, "POST"], g_sCurrentUrl+"|"+g_sOwnPass+"|"+g_sSecPass+"|"+g_sPubPass+"|"+(string)g_iWebMap);
        }
        else if ((sMethod == URL_REQUEST_DENIED) && (kID == g_kNewUrlRequest))
        {
            Debug("There was a problem, and an URL was not assigned: " + sBody);
            g_kNewUrlRequest = NULL_KEY;
        }
        else if (g_sCurrentUrl == "")
        {
            Debug("Got Command While Offline: " + sBody);
            llHTTPResponse(kID,403,"Forbidden");
        }
        else if (sMethod == "POST")
        {
            Debug("Got Command: " + sBody);
            Debug("Sending Response: Command Recieved");
            list lPathInfo = llParseStringKeepNulls(llGetHTTPHeader(kID, "x-path-info"), ["/"], []);
            integer iAuth;
            if (llList2String(lPathInfo, 1) == g_sOwnPass)
            {
                iAuth = COMMAND_OWNER;
            }
            else if (llList2String(lPathInfo, 1) == g_sSecPass)
            {
                iAuth = COMMAND_SECOWNER;
            }
            else if (llList2String(lPathInfo, 1) == g_sPubPass)
            {
                return;
            }
            else
            {
                if (5 < ++g_iErrPass)
                {
                    Notify(g_kWearer, "There seems to be someone is tring to hack into your collar. If you keep getting this please file a bug at http://bugs.mycollar.org/", TRUE);
                    NewURL();
                }
                return;
            }
            llHTTPResponse(kID,200,"Command Recieved");
            if(llGetSubString(sBody, 0, 5) == "rlvcmd")
            {
                llMessageLinked(LINK_SET, RLV_CMD, llGetSubString(sBody, 6, -1), NULL_KEY);
            }
            else
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER, sBody, llList2Key(lPathInfo, 2));
            }
        }
        else if (sMethod == "GET")
        {
            string sCmd = llUnescapeURL(llGetHTTPHeader(kID, "x-query-string"));
            string response = "";
            Debug("Got Get Info: " + sBody);
            list lPathInfo = llParseStringKeepNulls(llGetHTTPHeader(kID, "x-path-info"), ["/"], []);
            integer iAuth;
            if (llList2String(lPathInfo, 1) == g_sOwnPass)
            {
                iAuth = COMMAND_OWNER;
            }
            else if (llList2String(lPathInfo, 1) == g_sSecPass)
            {
                iAuth = COMMAND_SECOWNER;
            }
            else if (llList2String(lPathInfo, 1) == g_sPubPass)
            {
                iAuth = COMMAND_GROUP;
            }
            else
            {
                if (5 < ++g_iErrPass)
                {
                    Notify(g_kWearer, "There seems to be someone is tring to hack into your collar. If you keep getting this please file a bug at http://bugs.mycollar.org/", TRUE);
                    NewURL();
                }
                return;
            }
            if(sCmd == "ping")
            {
                response = "'pong'";
                Debug("Sending Response: " + response);
                llHTTPResponse(kID,200,JSONCallback(response, llList2String(lPathInfo, 3)));
            }
            if (llGetSubString(sCmd, 0, 4) == "JSON:")
            {
                string sJSON = llGetSubString(sCmd, 5, -1);
                g_lCallBacks += [kID, llList2String(lPathInfo, 3), llGetUnixTime()];//write callback
                llMessageLinked(LINK_SET, JSON_REQUEST, (string)iAuth + "|" + llList2String(lPathInfo, 2) + "|" + sJSON, kID);
                llSetTimerEvent(2);
            }
            else
            {
                llHTTPResponse(kID,200,JSONCallback("'"+StrReplace(sCmd, "'", "\\'")+"'", llList2String(lPathInfo, 3)));//need to escape the slash it self locally too.
                if(llGetSubString(sBody, 0, 5) == "rlvcmd")
                {
                    llMessageLinked(LINK_SET, RLV_CMD, llGetSubString(sCmd, 6, -1), NULL_KEY);
                }
                else
                {
                    llMessageLinked(LINK_SET, iAuth, sCmd, llList2Key(lPathInfo, 2));
                }
            }

        }
        else
        {
            Debug("Got Invaild Command: " + sBody);
            llHTTPResponse(kID,405,"Unsupported Method");
        }
    }
    http_response(key kRquestID, integer iStatus, list lMetadata, string sBody)
    {
        if(kRquestID == g_kBroadcastRequest)
        {
            if(iStatus != 200 && sBody != "Added")
                ClearURL();
            Debug("Got response from add lookup: (" + (string)iStatus + ") " + sBody);
        }
        else if(kRquestID == g_kBroadcastRequestDel)
        {
            Debug("Got response from del lookup: (" + (string)iStatus + ") " + sBody);
        }
        else
        {
            Debug("Got unknown response: (" + (string)iStatus + ") " + sBody);
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == SUBMENU && sStr == g_sSubMenu)
        {
            //someone asked for our menu
            //give this plugin's menu to kID
            DoMenu(kID);
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            // the menu sStructure is to be build again, so make sure we get recognized
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu)
            {//someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1)
                {
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            if(sStr == "http")
            {
                DoMenu(kID);
            }
            else if(sStr == "httpon")
            {
                llSetTimerEvent(0); // Disable the timer, which gets set on reset, as we are informing the user ourselves here
                if ((iNum == COMMAND_OWNER) || (iNum == COMMAND_WEARER))
                {
                    g_iEnabled = 1;
                    NewURL();
                    SaveHTTP();
                    Notify(kID, "HTTP Remote Server is now online.", TRUE);
                }
                else
                {
                    Notify(kID, "Only the owner or the wearer can turn on the HTTP Remote Server.", FALSE);
                }
            }
            else if(sStr == "httpoff")
            {
                if (iNum == COMMAND_OWNER)
                {
                    g_iEnabled = 0;
                    g_iPubEnabled = 0;
                    g_iWebMap = 0;
                    ClearURL();
                    SaveHTTP();
                    Notify(kID, "HTTP Remote Server is now offline.", TRUE);
                }
                else
                {
                    Notify(kID, "Only the owner can turn off the HTTP Remote Server.", FALSE);
                }
            }
            else if(sStr == "publichttpon")
            {
                if (iNum == COMMAND_OWNER)
                {
                    if (g_iEnabled == 1)
                    {
                        g_iPubEnabled = 1;
                        NewURL();
                        SaveHTTP();
                        Notify(kID, "Public HTTP access is on.", TRUE);
                    }
                    else
                    {
                        llOwnerSay("You need to enable the HTTP Server before you can enable the Public HTTP access.");
                    }
                }
                else
                {
                    Notify(kID, "Only the owner can turn on public Public HTTP access.", FALSE);
                }
            }
            else if(sStr == "publichttpoff")
            {
                if (iNum == COMMAND_OWNER)
                {
                    if (g_iEnabled == 1)
                    {
                        g_iPubEnabled = 0;
                        if (g_iEnabled)
                        {
                            NewURL();
                        }
                        SaveHTTP();
                        Notify(kID, "Public HTTP access is off.", TRUE);
                    }
                    else
                    {
                        llOwnerSay("You need to enable the HTTP Server before you can disable the Public HTTP access.");
                    }
                }
                else
                {
                    Notify(kID, "Only the owner can turn off public HTTP.", FALSE);
                }
            }
            else if(sStr == "webmapon")
            {
                if (kID == g_kWearer)
                {
                    if (g_iEnabled == 1)
                    {
                        g_iWebMap = 1;
                        SaveHTTP();
                        NewURL();
                        llOwnerSay("The web interface will show now your locations in SL.");
                    }
                    else
                    {
                        llOwnerSay("You need to enable the HTTP Server before you can enable the WebMap.");
                    }
                }
                else
                {
                    Notify(kID, "Only the wearer can allow to display their position in the Web Interface.", FALSE);
                }
            }
            else if(sStr == "webmapoff")
            {
                if (kID == g_kWearer)
                {
                    if (g_iEnabled == 1)
                    {
                        g_iWebMap = 0;
                        SaveHTTP();
                        NewURL();
                        llOwnerSay("The web interface will NOT show your locations in SL anymore.");
                    }
                    else
                    {
                        llOwnerSay("You need to enable the HTTP Server before you can disable the WebMap.");
                    }
                }
                else
                {
                    Notify(kID, "Only the wearer can disable to display their position in the Web Interface.", FALSE);
                }
            }
            else if(llGetSubString(sStr, 0, 5) == "rlvcmd")
            {
                if(iNum != COMMAND_WEARER)
                {
                    llMessageLinked(LINK_SET, RLV_CMD, llGetSubString(sStr, 6, -1), NULL_KEY);
                }
            }
            else if(llGetSubString(sStr, 0, 5) == "tosub:")
            {
                llOwnerSay(llGetSubString(sStr, 6, -1));
            }

            if (g_iRemenu)
            {
                g_iRemenu = FALSE;
                DoMenu(kID);
            }
        }
        else if (iNum == HTTPDB_RESPONSE)
        {
            if (llGetSubString(sStr,0,5) == "httpon")
            {
                integer iValue = (integer)llGetSubString(sStr,7,-1);
                if (iValue == 0)
                {
                    g_iEnabled = 0;
                    g_iWebMap = 0;
                    g_iPubEnabled = 0;
                }
                else
                {
                    if (iValue & 1)
                    {
                        g_iEnabled = 1;
                        NewURL();
                    }
                    else
                    {
                        g_iEnabled = 0;
                    }
                    if (iValue & 2)
                    {
                        g_iWebMap = 1;
                    }
                    else
                    {
                        g_iWebMap = 0;
                    }
                    if (iValue & 4)
                    {
                        g_iPubEnabled = 1;
                    }
                    else
                    {
                        g_iPubEnabled = 0;
                    }
                }
                if (g_iEnabled)
                {
                    NewURL();
                }
                else
                {
                    ClearURL();
                }
            }
            else if (llGetSubString(sStr,0,7) == "queueurl")
            {
                string sValue = llGetSubString(sStr,9,-1);
                g_sBROADCAST_URL = sValue + "lookup/";
                g_sWEBINTERFACE_URL = sValue;
                g_sWEBINTERFACE_PUBLIC_URL = sValue + "publichttp/?key=" + (string)g_kWearer;

            }

        }
        else if (iNum == JSON_RESPONSE)
        {//llOwnerSay("Got JSON resposne:"+sStr);
            integer iIndex = llListFindList(g_lCallBacks, [kID]);
            if (iIndex != -1)
            {
                llHTTPResponse(kID, 200, JSONCallback(Strided2JSON(Deserialize(sStr)), llList2String(g_lCallBacks, iIndex+1)));
                g_lCallBacks = llDeleteSubList(g_lCallBacks, iIndex, iIndex + 2);
            }
        }
        else if (iNum==DIALOG_RESPONSE)
        {
            //sStr will be a 2-element, pipe-delimited list in form iPageiNum|response
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAV = llList2String(lMenuParams, 0);
            string sMessage = llList2String(lMenuParams, 1);
            integer iPage = (integer)llList2String(lMenuParams, 2);

            if (kID == g_kDialogID)
            {
                if (sMessage == UPMENU)
                {
                    //give kID the parent menu
                    llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kAV);
                }
                else if (sMessage == g_sMenu_HTTP_Disabled)
                {
                    g_iRemenu = TRUE;
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, "httpon", kAV);
                }
                else if (sMessage == g_sMenu_HTTP_Enabled)
                {
                    g_iRemenu = TRUE;
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, "httpoff", kAV);
                }
                else if (sMessage == g_sMenu_PublicHTTP_Disabled)
                {
                    g_iRemenu = TRUE;
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, "publichttpon", kAV);
                }
                else if (sMessage == g_sMenu_PublicHTTP_Enabled)
                {
                    g_iRemenu = TRUE;
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, "publichttpoff", kAV);
                }
                else if (sMessage == g_sMenu_WebMap_Disabled)
                {
                    g_iRemenu = TRUE;
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, "webmapon", kAV);
                }
                else if (sMessage == g_sMenu_WebMap_Enabled)
                {
                    g_iRemenu = TRUE;
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, "webmapoff", kAV);
                }
                else if (sMessage == g_sMenu_WebInterFace)
                    // show url for web interface,no authorization needed
                {
                    g_iRemenu = TRUE;
                    llLoadURL(kAV, "Please use this link to access the web interface, which gives you access to all subs your own.", g_sWEBINTERFACE_URL);
                }
                else if (sMessage == g_sMenu_PublicWebInterFace)
                    // show url for web interface,no authorization needed
                {
                    g_iRemenu = TRUE;
                    llLoadURL(kAV, "Please use this link to access the PUBLIC web interface, which gives EVERYONE access to this subs collar.", g_sWEBINTERFACE_PUBLIC_URL);
                }
                else if (~llListFindList(g_lButtons, [sMessage]))
                {
                    //we got a g_sSubMenu selection
                    llMessageLinked(LINK_SET, SUBMENU, sMessage, kAV);
                }
            }
        }
    }
}
