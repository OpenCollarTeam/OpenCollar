/*
This file is a part of OpenCollar.
Copyright ©2023
: Contributors :
Aria (Tashia Redrose)
    *October 2023       -       Fixed and updated to work on latest addons
    *January 2021       -       Created oc_addons_bridge
    
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

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

integer CMD_ZERO            = 0;
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
integer REBOOT = -1000;
integer STARTUP = -57;


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer MENUNAME_REMOVE = 3003;


/*
 * Since Release Candidate 1, Addons will not receive all link messages without prior opt-in.
 * To opt in, add the needed link messages to g_lOptedLM = [], they'll be transmitted on
 * the initial registration and can be updated at any time by sending a packet of type `update`
 * Following LMs require opt-in:
 * [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG]
 */
list g_lOptedLM     = [CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE];

list g_lMenuIDs;
integer g_iMenuStride;
list g_lApps;

string UPMENU = "BACK";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    
    llRegionSayTo(g_kCollar, API_CHANNEL, llList2Json(JSON_OBJECT, [ "pkt_type", "from_addon", "addon_name", g_sAddon, "iNum", DIALOG, "sMsg", (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, "kID", kMenuID ]));

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [ kID, kMenuID, sName ], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Bridge Addon]";
    list lButtons  = [];
    
    //llSay(0, "opening menu");
    Dialog(kID, sPrompt, lButtons, ["DISCONNECT", UPMENU], 0, iAuth, "Menu~addon~bridge");
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
        list lTemp = llParseString2List(sStr, [" "], []);
        if(llToLower(llList2String(lTemp,0)) == g_sAddon)
        {
            llMessageLinked(LINK_ROOT, iNum, llDumpList2String(llList2List(lTemp,1,-1), " "), kID);
        }
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

DCApps()
{

    integer i = 0;
    for(i = 0; i< llGetListLength(g_lApps); i++)
    {
        Link("from_addon", MENUNAME_REMOVE, "Apps|" + llList2String(g_lApps,i), "");
    }
}

default
{
    state_entry()
    {
        ///
        /*
        The following section is for a safety check in the event of a single prim object.
        */
        integer iFail = 0;
        if(llGetNumberOfPrims() == 1)
        {
            iFail=1;
        }
        ///
        if(llGetObjectDesc() == "(No Description)" || llGetObjectDesc() == ""){
            string sName = llGetObjectName();
            if(llStringLength(sName) > 12) sName = llGetSubString(sName, 0, 11);
            
            g_sAddon = sName;
        }else {

            string sDesc = llGetObjectDesc();
            if(llStringLength(sDesc) > 12) sDesc = llGetSubString(sDesc,0,11);
            g_sAddon = sDesc;

        }
        if(llGetLinkNumber() == LINK_ROOT || iFail)
        {
            // Refuse to function!!
            llOwnerSay("I am set up incorrectly.\n \nTo set me up, place this script into a linked prim.\nPlace plugins into the root prim");

            llRemoveInventory(llGetScriptName());
        }
        llMessageLinked(LINK_ROOT, REBOOT, "reboot", ""); // Reboot any plugins


        API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
        llListen(API_CHANNEL, "", "", "");
        Link("online", 0, "", llGetOwner()); // This is the signal to initiate communication between the addon and the collar
        g_iLMLastRecv = llGetUnixTime(); // Need to initialize this here in order to prevent resetting before we can receive our first pong
        llSetTimerEvent(60);
    }

    changed(integer iChange)
    {
        if(iChange & CHANGED_INVENTORY)
        {
            if(g_kCollar == NULL_KEY) return;

            DCApps();

            llSleep(2); // Give SL time for possible lag...
            Link("offline", 0, "", llGetOwnerKey(g_kCollar));
            g_lMenuIDs = [];
            g_kCollar = NULL_KEY;


        }
    }

    touch_start(integer iNum)
    {
        if(g_kCollar == NULL_KEY)
        {
            llResetScript();
        }
    }

    on_rez(integer iNum)
    {
        llResetScript();
    }
    
    attach(key id)
    {
        // if attached make a connectin when detached disconnect.
        if(id)
        {
            llResetScript(); // Fix for bridge specifically.
        }
        else
        {
            DCApps();
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


        llMessageLinked(LINK_ROOT, READY, "", ""); // Watch for any newly added plugins just incase SL doesn't alert with changed()
    }

    link_message(integer iSender, integer iNum, string sMsg, key kID)
    {
        if(iNum == MENUNAME_RESPONSE)
        {
            list lReply = llParseString2List(sMsg, ["|"],[]);
            string sName = llList2String(lReply,0);
            string sMenu = llList2String(lReply,1);

            if(sName == "Apps")
            {
                g_lApps += [sMenu]; // <-- Store the menu for later. We'll use this to deregister the app when disconnecting.
            }
        } else if(iNum == ALIVE)
        {
            if(g_kCollar != NULL_KEY)
            {
                llOwnerSay("New script added: " + sMsg+". I need to restart now.");
                DCApps();
                llSleep(2);
                Link("offline", 0, "", llGetOwnerKey(g_kCollar));
                llSleep(0.5);
                llResetScript();
            }
        }
        Link("from_addon", iNum, sMsg, kID);
    }
    
    listen(integer channel, string name, key id, string msg){
        string sPacketType = llJsonGetValue(msg, ["pkt_type"]);
        if (sPacketType == "approved" && g_kCollar == NULL_KEY)
        {
            /*
            Send a few other extra messages to try to catch any edge-cases where plugins have a state machine waiting for specific signals
            */
            llMessageLinked(LINK_ROOT, STARTUP, "", ""); // Send the startup signal to any plugins.
            llSleep (2);
            // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
            g_kCollar = id;
            g_iLMLastRecv = llGetUnixTime(); // Initial message should also count as a pong for timing reasons
            llMessageLinked(LINK_ROOT, MENUNAME_REQUEST, "Apps", "");
            Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
        }
        else if (sPacketType == "dc" && g_kCollar == id)
        {
            g_kCollar = NULL_KEY;
            // We're not currently connected.
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


                if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
                {
                    UserCommand(iNum, sStr, kID);
                    
                }
                else if (iNum == DIALOG_TIMEOUT)
                {
                    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
                    g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex + 3);  //remove stride from g_lMenuIDs
                }
                else if (iNum == DIALOG_RESPONSE)
                {
                    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
                    if (iMenuIndex != -1)
                    {
                        string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
                        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                        list lMenuParams = llParseString2List(sStr, ["|"], []);
                        key kAv = llList2Key(lMenuParams, 0);
                        string sMsg = llList2String(lMenuParams, 1);
                        integer iAuth = llList2Integer(lMenuParams, 3);
                        
                        if (sMenu == "Menu~addon~bridge")
                        {
                            if (sMsg == UPMENU)
                            {
                                Link("from_addon", iAuth, "menu Addons", kAv);
                            }
                            else if (sMsg == "DISCONNECT")
                            {
                                DCApps();

                                llSleep(2); // Give SL time for possible lag...
                                Link("offline", 0, "", llGetOwnerKey(g_kCollar));
                                g_lMenuIDs = [];
                                g_kCollar = NULL_KEY;
                            }

                            return;
                        }
                    }
                }


                llMessageLinked(LINK_ROOT, iNum, sStr, kID);
            }
        }
    }
}
