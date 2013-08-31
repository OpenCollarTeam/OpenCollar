// OpenCollar - interface
// Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

// Message format for remotes = Toucher_UUID:Command[:AuthLow:AuthHigh]
// Command will be authed for Toucher, if falls between Low & High.
//  - Low >= 500 (OWNER), High <= 504 (EVERYONE).
//  - optional, but if used, BOTH values must be present
//  - [:500:500] would check for owner only auth
// Returned message (where applicable) will be Toucher_UUID:Response:Auth
//  - where Auth = auth level of the toucher.
//  - Keep in mind that most commands will not trigger a response message
// Ping-Pong. UUID:ping  will be responded to with UUID:pong:iAuth
//  - IF iAuth falls above 504 or below 500, there will be no response

//OpenCollar MESSAGE MAP
// messages for authenticating users
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

integer INTERFACE_REQUEST  = -9006;
integer INTERFACE_RESPONSE = -9007;

integer INTERFACE_CHANNEL;
list NONO = ["setopenaccess"]; // security
key g_kWearer;

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

MessageRemote(key kID, string sMsg, key kTouch)
{
    llRegionSayTo(kID, INTERFACE_CHANNEL, (string)kTouch + "\\" + sMsg);
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

default
{
    on_rez(integer r)
    {
        if (llGetOwner() != g_kWearer) llResetScript();
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        INTERFACE_CHANNEL = GetOwnerChannel(g_kWearer, 1111);
        llListen(INTERFACE_CHANNEL, "", "", "");
    }
    listen (integer iChan, string sName, key kID, string sMsg)
    {
        if (iChan != INTERFACE_CHANNEL) return;
        list lParams = llParseString2List(sMsg, ["\\"], []);
        integer i = llGetListLength(lParams);
        key kTouch = llGetOwnerKey(kID);
        sMsg = llList2String(lParams, 0);
        if (llListFindList(NONO, [sMsg])) return; // security
        if (i > 1) 
        {
            string sAuthLow = llList2String(lParams, 1);
            string sAuthHigh = sAuthLow;
            if (i > 2) sAuthHigh = llList2String(lParams, 2);
            sMsg += "|" + sAuthLow + "|" + sAuthHigh;
        }
        if (kTouch)
        {
            string out = llDumpList2String(["auth_", "level", sMsg, kID], "|");
            llMessageLinked(LINK_THIS, INTERFACE_REQUEST, out, kTouch);
        }
        else
        {
            Notify(kID, "Syntax Error! Request must be <uuid>\\<command>", FALSE);
        }
    }
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum != INTERFACE_RESPONSE) return;
        else if (sStr == "safeword")
        {
            llRegionSay(INTERFACE_CHANNEL, "safeword");
            llSleep(0.1);
            llResetScript();
        }
        list lParams = llParseString2List(sStr, ["|"], []);
        string sFrom = llList2String(lParams, 0);
        string sCommand = llList2String(lParams, 1);
        string sRemReq = llList2String(lParams, 2);
        key    kRemote = (key)llList2String(lParams, -1);
        integer iAuth = (integer)sFrom;
        integer iAuthLow = COMMAND_OWNER;
        integer iAuthHigh = COMMAND_EVERYONE;
        if (llGetListLength(lParams) > 4)
        {
            iAuthLow = (integer)llList2String(lParams, 3);
            iAuthHigh = (integer)llList2String(lParams, 4);
        }    
        if (sFrom == "auth_" && llGetSubString(sCommand, 0, 5) == "level=")
        {
            iAuth = (integer)llGetSubString(sCommand, 6, -1);
            if (iAuthHigh < iAuth || iAuth < iAuthLow) return; 
            if (sRemReq == "ping") MessageRemote(kRemote, "pong\\" + (string)iAuth, kID);
            else llMessageLinked(LINK_THIS, iAuth, sRemReq, kID);
            return;
        }
    }
}