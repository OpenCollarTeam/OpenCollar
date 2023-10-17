// This file is part of OpenCollar.
// Copyright (c) 2009 - 2016 Cleo Collins, Nandana Singh, Satomi Ahn,   
// Joy Stipe, Wendy Starfall, Medea Destiny, littlemousy,         
// Romka Swallowtail, Garvin Twine et al.  
// Licensed under the GPLv2.  See LICENSE for full details. 

// * This file is GPL because it is considered feature complete, and should work out of the box to integrate plugins as an addon.
// In discussions with Nirea originally, the template was determined to be public domain, because it was not feature complete, and required edits by the end user to create a product.

/*
-Authors Attribution-
Aria (Tashia Redrose) - (August 2020 - October 2023)
Lysea - (December 2020)
Taya'Phidoux' (taya.maruti) - (july 2021)
*/

integer API_CHANNEL = 0x60b97b5e;

//list g_lCollars;
string g_sAddon = "-notset-bridge-";

//integer CMD_ZERO            = 0;
integer CMD_OWNER           = 500;
//integer CMD_TRUSTED         = 501;
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

integer DIALOG          = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT  = -9002;

/*
 * Since Release Candidate 1, Addons will not receive all link messages without prior opt-in.
 * To opt in, add the needed link messages to g_lOptedLM = [], they'll be transmitted on
 * the initial registration and can be updated at any time by sending a packet of type `update`
 * Following LMs require opt-in:
 * [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG]
 */
list g_lOptedLM     = [];

list g_lMenuIDs;
integer g_iMenuStride;

string UPMENU = "BACK";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    
    llRegionSayTo(g_kCollar, API_CHANNEL, llList2Json(JSON_OBJECT, [ "pkt_type", "from_addon", "addon_name", g_sAddon, "iNum", DIALOG, "sMsg", (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, "kID", kMenuID ]));

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [ kID, kMenuID, sName ], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Menu App]";
    list lButtons  = ["A Button"];
    
    //llSay(0, "opening menu");
    Dialog(kID, sPrompt, lButtons, ["DISCONNECT", UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llSubStringIndex(llToLower(sStr), llToLower(g_sAddon)) && llToLower(sStr) != "menu " + llToLower(g_sAddon)) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        return;
    }

    if (llToLower(sStr) == llToLower(g_sAddon) || llToLower(sStr) == "menu "+llToLower(g_sAddon))
    {
        Menu(kID, iNum);
    } //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else
    {
        //integer iWSuccess   = 0; 
        //string sChangetype  = llList2String(llParseString2List(sStr, [" "], []),0);
        //string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        //string sText;
    }
}

Link(string packet, integer iNum, string sStr, key kID){
    list packet_data = [ "pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID ];

    if (packet == "online" || packet == "update") // only add optin if packet type is online or update
    {
        packet_data += [ "optin", llDumpList2String(g_lOptedLM, "~") ];
    }

    string pkt = llList2Json(JSON_OBJECT, packet_data);
    if (g_kCollar != "" && g_kCollar != NULL_KEY)
    {
        llRegionSayTo(g_kCollar, API_CHANNEL, pkt);
    }
    else
    {
        llRegionSay(API_CHANNEL, pkt);
    }
}

key g_kCollar=NULL_KEY;
integer g_iLMLastRecv;
integer g_iLMLastSent;

default
{
    state_entry()
    {
        if(llGetObjectDesc() == "(No Description)"){
            string sName = llGetObjectName();
            if(llStringLength(sName) > 12) sName = llGetSubString(sName, 0, 11);
            
            g_sAddon = sName;
        }else {

            string sDesc = llGetObjectDesc();
            if(llStringLength(sDesc) > 12) sDesc = llGetSubString(sDesc,0,11);
            g_sAddon = sDesc;

        }
        API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
        llListen(API_CHANNEL, "", "", "");
        Link("online", 0, "", llGetOwner()); // This is the signal to initiate communication between the addon and the collar
        g_iLMLastRecv = llGetUnixTime(); // Need to initialize this here in order to prevent resetting before we can receive our first pong
        llSetTimerEvent(60);
    }
    
    attach(key id)
    {
        // if attached make a connectin when detached disconnect.
        if(id)
        {
            Link("online", 0, "", llGetOwner());
            // do like state_entry to fix random resets on teleport or login.
            llSetTimerEvent(60);
            g_iLMLastRecv = llGetUnixTime();
        }
        else
        {
            Link("offline", 0, "", llGetOwnerKey(g_kCollar));
        }
    }

    
    timer()
    {
        if (llGetUnixTime() >= (g_iLMLastSent + 30))
        {
            g_iLMLastSent = llGetUnixTime();
            Link("ping", 0, "", g_kCollar);
        }

        if (llGetUnixTime() > (g_iLMLastRecv + (5 * 60)) && g_kCollar != NULL_KEY)
        {
            g_kCollar = NULL_KEY;
            llResetScript(); // perform our action on disconnect
        }
        
        if (g_kCollar == NULL_KEY) Link("online", 0, "", llGetOwner());
    }

    link_message(integer iSender, integer iNum, string sMsg, key kID)
    {
        Link("from_addon", iNum, sMsg, kID);
    }
    
    listen(integer channel, string name, key id, string msg){
        string sPacketType = llJsonGetValue(msg, ["pkt_type"]);
        if (sPacketType == "approved" && g_kCollar == NULL_KEY)
        {
            // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
            g_kCollar = id;
            g_iLMLastRecv = llGetUnixTime(); // Initial message should also count as a pong for timing reasons
            Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
        }
        else if (sPacketType == "dc" && g_kCollar == id)
        {
            g_kCollar = NULL_KEY;
            llResetScript(); // This addon is designed to always be connected because it is a test
        }
        else if (sPacketType == "pong" && g_kCollar == id)
        {
            g_iLMLastRecv = llGetUnixTime();
        }
        else if(sPacketType == "from_collar")
        {
            // process link message if in range of addon
            if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0)) <= 10.0)
            {
                integer iNum = (integer) llJsonGetValue(msg, ["iNum"]);
                string sStr  = llJsonGetValue(msg, ["sMsg"]);
                key kID      = (key) llJsonGetValue(msg, ["kID"]);

                llMessageLinked(LINK_SET, iNum, sStr, kID);
            }
        }
    }
}
