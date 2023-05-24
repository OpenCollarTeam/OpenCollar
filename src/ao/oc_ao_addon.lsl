/*
    A minimal re write of the AO System to use Linkset Data
    this script is intended to be a stand alone ao managed from linkset storage
    which would allow it to be populated by any interface script.
    Created: Febuary 5 2023
    By: Phidoux (taya.Maruti)
    ------------------------------------
    | Contributers  and updates below  |
    ------------------------------------
    | Name | Date | comment            |
    ------------------------------------
*/
integer API_CHANNEL = 0x60b97b5e;

//list g_lCollars;
string g_sAddon = "ao";

//integer CMD_ZERO            = 0;
integer CMD_OWNER           = 500;
integer CMD_TRUSTED         = 501;
//integer CMD_GROUP           = 502;
integer CMD_WEARER          = 503;
//integer CMD_EVERYONE        = 504;
//integer CMD_BLOCKED         = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY       = 507;
//integer CMD_SAFEWORD        = 510;
//integer CMD_RELAY_SAFEWORD  = 511;
//integer CMD_NOACCESS        = 599;

//integer LINK_CMD_RESTRICTIONS = -2576;
//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
//integer RLV_VERSION = 6003; //RLV Plugins can recieve the used RLV viewer version upon receiving this message..
//integer RLVA_VERSION = 6004; //RLV Plugins can recieve the used RLVa viewer version upon receiving this message..
//integer RLV_CMD_OVERRIDE=6010; //RLV Plugins can send one-shot (force) commands with a list of restrictions to temporarily lift if required to ensure that the one-shot commands can be executed
//integer AUTH_REQUEST = 600;
//integer AUTH_REPLY = 601;

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer LM_SETTING_SAVE     = 2000; //scripts send messages on this channel to have settings saved, <string> must be in form of "token=value"
integer LM_SETTING_REQUEST  = 2001; //when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; //the settings script sends responses on this channel
//integer LM_SETTING_DELETE   = 2003; //delete token from settings
//integer LM_SETTING_EMPTY    = 2004; //sent when a token has no value

//integer DIALOG          = -9000;
//integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT  = -9002;

/*
 * Since Release Candidate 1, Addons will not receive all link messages without prior opt-in.
 * To opt in, add the needed link messages to g_lOptedLM = [], they'll be transmitted on
 * the initial registration and can be updated at any time by sending a packet of type `update`
 * Following LMs require opt-in:
 * [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG]
 */
list g_lOptedLM     = [];


string g_sVersion = "3.0.0";
//integer g_iStandTime = 120; // Default Stand timer.
// State related Animation List.
string g_sCard = "Default";
//

recordMemory()
{
    llLinksetDataWrite("memory_"+llGetScriptName(),(string)llGetUsedMemory());
}

UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum<CMD_OWNER || iNum>CMD_WEARER)
    {
        return;
    }
    if (llSubStringIndex(llToLower(sStr), llToLower(g_sAddon)) && llToLower(sStr) != "menu " + llToLower(g_sAddon))
    {
        return;
    }
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway")
    {
        return;
    }
    if (llToLower(sStr) == llToLower(g_sAddon) || llToLower(sStr) == "menu "+llToLower(g_sAddon))
    {
        //Menu(kID, iNum);
        llMessageLinked(LINK_SET,iNum,"Menu",kID);
    }
    else
    {
        list lCommands = llParseString2List(sStr,[" "],[g_sAddon,llToLower(g_sAddon)]);
        string sToken = llToLower(llList2String(lCommands,1));
        string sVal = llList2String(lCommands,2);
        if ( sToken == "power")
        {
            if(llLinksetDataRead(llToLower(g_sAddon)+"_card") == "")
            {
                //g_iDefault = TRUE;
                UserCommand(iNum,g_sAddon+" load "+g_sCard, kID);
            }
            else
            {
                llLinksetDataWrite(llToLower(g_sAddon)+"_power",(string)(!(integer)llLinksetDataRead(llToLower(g_sAddon)+"_power")));
            }
        }
        else if ( sToken == "on")
        {
            if(llLinksetDataRead(llToLower(g_sAddon)+"_card") == "")
            {
                //g_iDefault = TRUE;
                UserCommand(iNum,g_sAddon+" load "+g_sCard, kID);
            }
            else
            {
                llLinksetDataWrite(llToLower(g_sAddon)+"_power",(string)TRUE);
            }
        }
        else if ( sToken == "off")
        {
            llLinksetDataWrite(llToLower(g_sAddon)+"_power",(string)FALSE);
        }
        else if ( sToken == "load")
        {
            if(llLinksetDataRead(llToLower(g_sAddon)+"_card") != sVal)
            {
                if(llGetInventoryType(sVal) == INVENTORY_NOTECARD)
                {
                    llLinksetDataWrite(llToLower(g_sAddon)+"_loaded",(string)FALSE);
                    llLinksetDataWrite(llToLower(g_sAddon)+"_card",sVal);
                }
                else if (kID != "" && kID != NULL_KEY)
                {
                    llInstantMessage(kID,"that card does not seem to exist!");
                    //MenuLoad(kID,g_iPage,iNum);
                    llMessageLinked(LINK_SET,iNum,"MenuLoad",kID);
                }
            }
            else if (kID != "" && kID != NULL_KEY)
            {
                llInstantMessage(kID,"Card is already loaded try a different one or clear memory");
                //MenuLoad(kID,g_iPage,iNum);
                llMessageLinked(LINK_SET,iNum,"MenuLoad",kID);
            }
        }
        else if( sToken == "memory")
        {
            llLinksetDataWrite("memory_print",(string)kID);
        }
        else if( sToken == "connect")
        {
            llLinksetDataWrite(llToLower(g_sAddon)+"_online",(string)TRUE);
        }
        else if( sToken == "disconnect")
        {
            llLinksetDataWrite(llToLower(g_sAddon)+"_online",(string)FALSE);
        }
        lCommands = [];
        sToken = "";
        sVal = "";
    }
    sStr = "";
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
        llLinksetDataWrite(llToLower(g_sAddon)+"_ver",g_sVersion);
        llLinksetDataWrite("addon_name",g_sAddon);
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        check_settings(llToLower(g_sAddon)+"_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        check_settings(llToLower(g_sAddon)+"_online",(string)TRUE);
        llOwnerSay("Initializing Please Wait!");
        if(llGetAttached())
        {
            recordMemory();
            if((integer)llLinksetDataRead(llToLower(g_sAddon)+"_online"))
            {
                llLinksetDataWrite(llToLower(g_sAddon)+"_rezzed",(string)TRUE);
                //g_iJustRezzed = TRUE;
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
            if(kID != llGetOwner())
            {
                llLinksetDataReset();
            }
            else
            {
                llLinksetDataWrite("auth_wearer",(string)llGetOwner());
                check_settings(llToLower(g_sAddon)+"_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
            }
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
        recordMemory();
        llSetTimerEvent(0);
        llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
        state offline;
    }

    linkset_data(integer iAction, string sName, string sValue)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }
}

state online
{
    state_entry()
    {
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        llLinksetDataWrite("addon_name",g_sAddon);
        check_settings(llToLower(g_sAddon)+"_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        goOnline();
        llSetTimerEvent(1);
        llOwnerSay(" Connected to collar satus online");
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llLinksetDataWrite("auth_wearer",(string)llGetOwner());
            check_settings(llToLower(g_sAddon)+"_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
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
        if (llGetUnixTime() >= ((integer)llLinksetDataRead(llToLower(g_sAddon)+"_LMLastSent") + 30))
        {
            llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastSent",(string)llGetUnixTime());
            Link("ping", 0, "", (key)llLinksetDataRead("collar_uuid"));
            Link("from_addon", LM_SETTING_REQUEST, "ao_card", "");
        }
        if (llGetUnixTime() > ((integer)llLinksetDataRead(llToLower(g_sAddon)+"_LMLastRecv") + (5 * 60)) && llLinksetDataRead("collar_uuid") != NULL_KEY)
        {
            state default;
        }
        if ((key)llLinksetDataRead("collar_uuid") == NULL_KEY)
        {
            state default;
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
                if((integer)llLinksetDataRead(llToLower(g_sAddon)+"_rezzed"))
                {
                    llLinksetDataDelete(llToLower(g_sAddon)+"_rezzed");
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
                if(llGetUnixTime() > ((integer)llLinksetDataRead(llToLower(g_sAddon)+"_LMLastRecv")+30))
                {
                    llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastRecv",(string)llGetUnixTime());
                }
            }
            else if(sPacketType == "from_collar")
            {
                if(llGetUnixTime() > ((integer)llLinksetDataRead(llToLower(g_sAddon)+"_LMLastRecv")+30))
                {
                    llLinksetDataWrite(llToLower(g_sAddon)+"_LMLastRecv",(string)llGetUnixTime());
                }
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
                        if( sToken == "ao")
                        {
                            if( sVar == "card" && sVal != llLinksetDataRead(llToLower(g_sAddon)+"_card"))
                            {
                                if(llGetInventoryType(sVal) == INVENTORY_NOTECARD)
                                {
                                    llLinksetDataWrite(llToLower(g_sAddon)+"_loaded",(string)FALSE);
                                    llLinksetDataWrite(llToLower(g_sAddon)+"_card",sVal);
                                }
                                else if (kID != "" && kID != NULL_KEY)
                                {
                                    llInstantMessage(llGetOwner(),"the card loaded from collar does not seem to exist!");
                                }
                            }
                        }
                        else if(sToken == "auth")
                        {
                            if(sVar == "owner")
                            {
                                if(sVal != "" && sVal != llLinksetDataRead("auth_owner"))
                                {
                                    llLinksetDataWrite("auth_owner",sVal);
                                }
                            }
                            else if(sVar == "trust")
                            {
                                if(sVal != "" && sVal != llLinksetDataRead("auth_trust"))
                                {
                                    llLinksetDataWrite("auth_trust",sVal);
                                }
                            }
                        }
                        else if( sToken == "global")
                        {
                            if(sVar == "prefix")
                            {
                                llLinksetDataWrite(llToLower(g_sAddon)+"_prefix",sVal);
                            }
                        }
                        lPar = [];
                        sToken = "";
                        sVar = "";
                        sVal = "";
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

    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
            else if(sName == llToLower(g_sAddon)+"_online")
            {
                state default;
            }
            else if(sName == llToLower(g_sAddon)+"_card")
            {
                Link("from_addon", LM_SETTING_SAVE, "ao_card="+sValue, "");
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }
}

state offline
{
    state_entry()
    {
        llLinksetDataWrite("auth_wearer",(string)llGetOwner());
        llLinksetDataWrite("addon_name",g_sAddon);
        check_settings(llToLower(g_sAddon)+"_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
        llLinksetDataWrite(llToLower(g_sAddon)+"_online",(string)FALSE);
        llSetTimerEvent(0);
        llOwnerSay("ao in offline mode, you can still use /1"+llLinksetDataRead(llToLower(g_sAddon)+"_prefix")+"ao commands");
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
                check_settings(llToLower(g_sAddon)+"_prefix",llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1)));
            }
        }
    }
    listen (integer iChan, string sName, key kID,string sMsg)
    {
        if(~llSubStringIndex(llToLower(sMsg),llLinksetDataRead(llToLower(g_sAddon)+"_prefix")))
        {
            sMsg = llDeleteSubString(sMsg,0,1);
            if(kID == llGetOwner())
            {
                UserCommand(CMD_WEARER, sMsg, kID);
            }
            else if(llListFindList(llParseString2List(llLinksetDataRead("auth_owners"),[","],[]),[(string)kID]) != -1)
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

    linkset_data(integer iAction,string sName,string sVal)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
            else if(sName == llToLower(g_sAddon)+"_online")
            {
                llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
                state default;
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llListenRemove((integer)llLinksetDataRead(llToLower(g_sAddon)+"_listen"));
            llResetScript();
        }
    }
}
