/*
THIS FILE IS HEREBY RELEASED UNDER THE Public Domain
This script is released public domain, unlike other OC scripts for a specific and limited reason, because we want to encourage third party plugin creators to create for OpenCollar and use whatever permissions on their own work they see fit.  No portion of OpenCollar derived code may be used excepting this script,  without the accompanying GPLv2 license.
-Authors Attribution-
Aria (tiff589) - (August 2020)
Lysea - (December 2020)
*/

integer API_CHANNEL = 0x60b97b5e;

//list g_lCollars;
string g_sAddon = "";

//integer CMD_ZERO            = 0;
integer CMD_OWNER           = 500;
integer CMD_TRUSTED         = 501;
//integer CMD_GROUP           = 502;
integer CMD_WEARER          = 503;
integer CMD_EVERYONE        = 504;
//integer CMD_BLOCKED         = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY       = 507;
//integer CMD_SAFEWORD        = 510;
//integer CMD_RELAY_SAFEWORD  = 511;
//integer CMD_NOACCESS        = 599;

//integer LM_SETTING_SAVE     = 2000; //scripts send messages on this channel to have settings saved, <string> must be in form of "token=value"
integer LM_SETTING_REQUEST  = 2001; //when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; //the settings script sends responses on this channel
//integer LM_SETTING_DELETE   = 2003; //delete token from settings
//integer LM_SETTING_EMPTY    = 2004; //sent when a token has no value

/*
 * Since Release Candidate 1, Addons will not receive all link messages without prior opt-in.
 * To opt in, add the needed link messages to g_lOptedLM = [], they'll be transmitted on
 * the initial registration and can be updated at any time by sending a packet of type `update`
 * Following LMs require opt-in:
 * [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG]
 */
list g_lOptedLM     = [];

UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum<CMD_OWNER || iNum>CMD_WEARER)
    {
        llInstantMessage(kID, "you are not authorized to access this person");
        return;
    }
    if (llSubStringIndex(llToLower(sStr), llToLower(g_sAddon)) && llToLower(sStr) != "menu " + llToLower(g_sAddon))
    {
        return;
    }
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway")
    {
        llLinksetDataReset();
        return;
    }
    if (llToLower(sStr) == llToLower(g_sAddon) || llToLower(sStr) == "menu "+llToLower(g_sAddon))
    {
        llMessageLinked(LINK_SET,iNum,"Menu",kID);
    }
    else
    {
        list lCommands = llParseString2List(sStr,[" "],[g_sAddon,llToLower(g_sAddon)]);
        string sToken = llToLower(llList2String(lCommands,1));
        string sVal = llList2String(lCommands,2);
        llLinksetDataWrite("menu_user",(string)kID);
        if (sToken == "reset")
        {
            Notify("Clearing Memory and restarting scripts!",kID);
            llLinksetDataReset();
        }
        else
        {
            llInstantMessage(kID,"Wrong comand or you are not authroized");
        }
    }
}

Link(string packet, integer iNum, string sStr, key kID)
{
    list packet_data = [ "pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID ];

    if (packet == "online" || packet == "update")
    {
        // only add optin if packet type is online or update
        packet_data += [ "optin", llDumpList2String(g_lOptedLM, "~") ];
    }

    string pkt = llList2Json(JSON_OBJECT, packet_data);
    if ((key)llLinksetDataRead("collar_uuid") != "" && (key)llLinksetDataRead("collar_uuid") != NULL_KEY)
    {
        llRegionSayTo((key)llLinksetDataRead("collar_uuid"), API_CHANNEL, pkt);
    }
    else
    {
        llRegionSay(API_CHANNEL, pkt);
    }

    // Sanitation to keep memory usage low.
    packet_data = [];
    pkt = "";
    packet = "";
    sStr = "";
}

goOnline()
{
    llLinksetDataWrite("collar_uuid",(string)NULL_KEY);
    if((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"))
    {
        llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
    }
    API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
    llLinksetDataWrite(llToLower(g_sAddon)+"_listen",(string)llListen(API_CHANNEL, "", "", ""));
    Link("online", 0, "", llGetOwner()); // This is the signal to initiate communication between the addon and the collar
    llSetTimerEvent(10);
    llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastRecv",(string)llGetUnixTime());
    llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastSent",(string)llGetUnixTime());
}

Notify(string sMsg,key kID)
{
    llInstantMessage(kID,sMsg);
    if(kID != llGetOwner())
    {
        llOwnerSay(sMsg);
    }
    sMsg ="";
    kID = "";
}

check_settings(string sToken, string sDefaulVal)
{
    if(!~llListFindList(llLinksetDataListKeys(0,0),[sToken])) // token/key doesn't exist in the list of keys
    {
        llLinksetDataWrite(sToken, sDefaulVal);
    }
    else if(llLinksetDataRead(sToken) == "")
    {
        llLinksetDataWrite(sToken, sDefaulVal);
    }
}

default
{
    state_entry()
    {
        llLinksetDataWrite("addon_name",g_sAddon);
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        check_settings("global_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        check_settings(llToLower(g_sAddon)+"_online",(string)TRUE);
        llOwnerSay("Initializing Please Wait!");
        if(llGetAttached())
        {
            if((integer)llLinksetDataRead(llToLower(g_sAddon)+"_online"))
            {
                llLinksetDataWrite(llToLower(g_sAddon)+"_addonrezzed",(string)TRUE);
                llSetTimerEvent(30);
                goOnline();
            }
            else
            {
                state offline;
            }
        }
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llLinksetDataWrite("addon_name",g_sAddon);
            llLinksetDataWrite("auth_wearer",(string)llGetOwner());
            check_settings("global_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llLinksetDataReset();
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if(llGetOwnerKey(kID) != llGetOwner())
        {
            // this check only works on addons owned by the collar wearer, like clothing or personal furnature.
           return;
        }
        string sPacketType = llJsonGetValue(sMsg, ["pkt_type"]);
        if (sPacketType == "approved")
        {
            // if we get responce disconnect then set ao to online mode.
            llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
            Link("offline", 0, "", llGetOwnerKey((key)llLinksetDataRead("collar_uuid")));
            llLinksetDataDelete("collar_uuid");
            llLinksetDataDelete("collar_name");
            llSetTimerEvent(0);
            sMsg = "";
            sName = "";
            iChannel = 0;
            state online;
        }
        sMsg = "";
        sName = "";
        iChannel = 0;
    }

    timer()
    {

        llSetTimerEvent(0);
        llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
        state offline;
    }

    linkset_data(integer iAction, string sName, string sValue)
    {
        if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }
}

state online
{
    state_entry()
    {
        if(g_sAddon == "")
        {
            // if there is no addon name provided take it from the object.
            g_sAddon = llGetSubString(llGetObjectName(),0,24);
        }
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        check_settings("global_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        goOnline();
        llSetTimerEvent(1);
        llOwnerSay(" Connected to collar satus online");
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llLinksetDataWrite("auth_wearer",(string)llGetOwner());
            check_settings("global_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_REGION)
        {
            Link("update", 0, "", (key)llLinksetDataRead("collar_uuid"));
        }
        else if(change & CHANGED_OWNER)
        {
            llLinksetDataReset();
        }
    }

    timer()
    {
        list g_lMenuIDs = llParseString2List(llLinksetDataRead(llToLower(g_sAddon)+"_menu"),[","],[]);
        if(llGetListLength(g_lMenuIDs))
        {
            if(llGetUnixTime() >= llList2Integer(g_lMenuIDs,3))
            {
                llListenRemove(llList2Integer(g_lMenuIDs,2));
                llLinksetDataDelete(llToLower(g_sAddon)+"_menu");
            }
        }
        g_lMenuIDs=[];
        if (llGetUnixTime() >= ((integer)llLinksetDataRead(llToLower(g_sAddon)+"_LMLastSent") + 30))
        {
            llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastSent",(string)llGetUnixTime());
            Link("ping", 0, "", (key)llLinksetDataRead("collar_uuid"));
        }
        if (llGetUnixTime() > ((integer)llLinksetDataRead(llToLower(g_sAddon)+"_LMLastRecv") + (5 * 60)) && llLinksetDataRead("collar_uuid") != NULL_KEY)
        {
            state default;
        }
        if ((key)llLinksetDataRead("collar_uuid") == NULL_KEY)
        {
            state default;
        }
        else
        {
            llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastSent",(string)llGetUnixTime());
            Link("ping",0,"",llLinksetDataRead("collar_uuid"));
        }
    }

    link_message(integer iLink, integer iNum,string sMsg, key kID)
    {
        if (iNum <= CMD_WEARER && iNum >= CMD_OWNER)
        {
            if(sMsg == "CollarMenu")
            {
                Link("from_addon", iNum, "menu Addons", kID);
            }
            else
            {
                UserCommand(iNum, sMsg, kID);
            }
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if(llLinksetDataRead("collar_name") == sName && llGetOwnerKey(kID) != llGetOwner())
        {
            // this check only works on addons owned by the collar wearer, like clothing or personal furnature.
            return;
        }
        string sPacketType = llJsonGetValue(sMsg, ["pkt_type"]);
        if ((key)llLinksetDataRead("collar_uuid") == NULL_KEY)
        {
            if (sPacketType == "approved")
            {
                // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
                if((integer)llLinksetDataRead(llToLower(g_sAddon)+"_addonrezzed"))
                {
                    llLinksetDataDelete(llToLower(g_sAddon)+"_addonrezzed");
                }
                llLinksetDataWrite("collar_uuid",(string)kID);
                llLinksetDataWrite("collar_name",(string)sName);
                llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
                llLinksetDataWrite(llToLower(g_sAddon)+"_listen",(string)llListen(API_CHANNEL, sName, kID, ""));
                llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastRecv",(string)llGetUnixTime());
                Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
                llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastSent",(string)llGetUnixTime());
                llSetTimerEvent(10);// move the timer here in order to wait for collar responce.
            }
        }
        else
        {
            if (sPacketType == "dc" && (key)llLinksetDataRead("collar_uuid") == kID )
            {
                sMsg = "";
                sName = "";
                iChannel = 0;
                state default;
            }
            else if (sPacketType == "pong" && (key)llLinksetDataRead("collar_uuid") == kID)
            {
                llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastRecv",(string)llGetUnixTime());
            }
            else if(sPacketType == "from_collar")
            {
                llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastRecv",(string)llGetUnixTime());
                // process link message if in range of addon
                if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) <= 10.0)
                {
                    integer iNum = (integer) llJsonGetValue(sMsg, ["iNum"]);
                    string sStr  = llJsonGetValue(sMsg, ["sMsg"]);
                    key kAv      = (key) llJsonGetValue(sMsg, ["kID"]);
                    if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
                    {
                        UserCommand(iNum, sStr, kAv);
                    }
                    else if (iNum == LM_SETTING_RESPONSE)
                    {
                        list lPar     = llParseString2List(sStr, ["_","="], []);
                        string sToken = llList2String(lPar, 0);
                        string sVar   = llList2String(lPar, 1);
                        string sVal   = llList2String(lPar, 2);
                        if(sToken == "auth")
                        {
                            if(sVar == "owner")
                            {
                                if(sVal != "" && sVal != llLinksetDataRead("auth_owner"))
                                {
                                    llLinksetDataWrite("auth_owner",sVal);
                                }
                            }
                            if(sVar == "trust")
                            {
                                if(sVal != "" && sVal != llLinksetDataRead("auth_trust"))
                                {
                                    llLinksetDataWrite("auth_trust",sVal);
                                }
                            }
                        }
                        else if( sToken == "global")
                        {
                            if(sVar == "lock" && (integer)llLinksetDataRead("collar_lock"))
                            {
                                llLinksetDataWrite(llToLower(g_sAddon)+"_lock",sVal);
                                llLinksetDataWrite(llToLower(g_sAddon)+"_lockauth",(string)CMD_WEARER);
                            }
                            if(sVar == "prefix")
                            {
                                llLinksetDataWrite("global_prefix",sVal);
                            }
                        }
                        lPar = [];
                        sToken = "";
                        sVar = "";
                        sVal = "";
                    }
                    else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
                    {
                        UserCommand(iNum, sStr, kAv);
                    }
                    sStr = "";
                }
            }
        }
        sPacketType = "";
        sMsg = "";
        sName = "";
        iChannel = 0;
    }
    touch_end(integer iDetected)
    {
        key kID = llDetectedKey(0);
        if(kID == llGetOwner())
        {
            UserCommand(CMD_WEARER, g_sAddon, kID);
        }
        else if(llListFindList(llParseString2List(llLinksetDataRead("auth_owner"),[","],[]),[(string)kID]) != -1)
        {
            UserCommand(CMD_OWNER, g_sAddon, kID);
        }
        else if(llListFindList(llParseString2List(llLinksetDataRead("auth_trust"),[","],[]),[(string)kID]) != -1)
        {
            UserCommand(CMD_TRUSTED, g_sAddon, kID);
        }
        else
        {
            llInstantMessage(kID,"Sorry you are not authorized to use this");
        }
    }
    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_RESET)
        {
            llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
            llResetScript();
        }
    }
}

state offline
{
    state_entry()
    {
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        check_settings("global_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        llLinksetDataWrite(llToLower(g_sAddon)+"_online",(string)FALSE);
        llSetTimerEvent(0);
        llOwnerSay(g_sAddon+" in offline mode, you can still use /1"+llLinksetDataRead("global_prefix")+llToLower(g_sAddon)+" commands");
        llLinksetDataWrite(llToLower(g_sAddon)+"_listen",(string)llListen(1,"",NULL_KEY,""));
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            if(kID != llGetOwner())
            {
                llLinksetDataReset();
            }
            else
            {
                llLinksetDataWrite("auth_wearer",(string)llGetOwner());
                check_settings("global_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
            }
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llLinksetDataReset();
        }
    }

    link_message(integer iLink, integer iNum,string sMsg, key kID)
    {
        if (iNum <= CMD_WEARER && iNum >= CMD_OWNER)
        {
            if(sMsg == "CollarMenu")
            {
                Link("from_addon", iNum, "menu Addons", kID);
            }
            else
            {
                UserCommand(iNum, sMsg, kID);
            }
        }
    }

    listen (integer iChannel, string sName, key kID,string sMsg)
    {
        if(~llSubStringIndex(llToLower(sMsg),llLinksetDataRead("global_prefix")))
        {
            //llOwnerSay(sMsg);
            sMsg = llDeleteSubString(sMsg,0,1);
            //llOwnerSay(sMsg);
            if(kID == llGetOwner())
            {
                UserCommand(CMD_WEARER, sMsg, kID);
            }
            else if(llListFindList(llParseString2List(llLinksetDataRead("auth_owner"),[","],[]),[(string)kID]) != -1)
            {
                UserCommand(CMD_OWNER, sMsg, kID);
            }
            else if(llListFindList(llParseString2List(llLinksetDataRead("auth_trust"),[","],[]),[(string)kID]) != -1)
            {
                UserCommand(CMD_TRUSTED, sMsg, kID);
            }
            else
            {
                llInstantMessage(kID,"Sorry you are not authorized to use this");
            }
        }
    }

    touch_start(integer iDetected)
    {
        key kID = llDetectedKey(0);
        if(kID == llGetOwner())
        {
            UserCommand(CMD_WEARER, g_sAddon, kID);
        }
        else if(llListFindList(llParseString2List(llLinksetDataRead("auth_owner"),[","],[]),[(string)kID]) != -1)
        {
            UserCommand(CMD_OWNER, g_sAddon, kID);
        }
        else if(llListFindList(llParseString2List(llLinksetDataRead("auth_trust"),[","],[]),[(string)kID]) != -1)
        {
            UserCommand(CMD_TRUSTED, g_sAddon, kID);
        }
        else
        {
            llInstantMessage(kID,"Sorry you are not authorized to use this");
        }
    }

    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_RESET)
        {
            llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
            llResetScript();
        }
    }
}
