/*
THIS FILE IS HEREBY RELEASED UNDER THE Public Domain
This script is released public domain, unlike other OC scripts for a specific and limited reason, because we want to encourage third party plugin creators to create for OpenCollar and use whatever permissions on their own work they see fit.  No portion of OpenCollar derived code may be used excepting this script,  without the accompanying GPLv2 license.
-Authors Attribution-
Aria (tiff589) - (August 2020)
Lysea - (December 2020)
*/

integer API_CHANNEL = 0x60b97b5e;

//list g_lCollars;
string g_sAddon = "Addon Name Here";

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
integer iLockAuth = 503;

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
    list lButtons  = [bLock];
    //llSay(0, "opening menu");
    Dialog(kID, sPrompt, lButtons, ["DISCONNECT", UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llSubStringIndex(llToLower(sStr), llToLower(g_sAddon)) && llToLower(sStr) != "menu " + llToLower(g_sAddon)) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        lock = FALSE;
        check_settings();
        return;
    }

    if (llToLower(sStr) == llToLower(g_sAddon) || llToLower(sStr) == "menu "+llToLower(g_sAddon))
    {
        if(lock){
            if(iNum < CMD_WEARER && iNum >= CMD_OWNER){
                Menu(kID, iNum);
            }
            else{
                llInstantMessage(kID,"Sorry you are not authorized");
            }
        }
        else{
            Menu(kID, iNum);
        }
    } //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else
    {
        list lCommands = llParseString2List(llToLower(sStr),[" "],[llToLower(g_sAddon)]);
        string sCommand = llList2String(lCommands,1);
        string sVar = llList2String(lCommands,2);
        string sVal = llList2String(lCommands,3);
        if( iNum == CMD_WEARER  && lock) {
            /* we lock out the wearer from access even if they are the one who locked it.
               This Section can be commented out for it to be possible for the wearer to
               unlock them self if they lock it.
            */
            llInstantMessage(kID,"Sorry the lock is engaged you have no access!");
            return;
        }
        if (sCommand == "unlock" && iNum <= iLockAuth){
            lock = FALSE;
            iLockAuth = CMD_WEARER;
            llInstantMessage(kID,"/me makes a soft click as the lock is disabled");
            llPlaySound("82fa6d06-b494-f97c-2908-84009380c8d1", 1.0);
            check_settings();
        }
        else if (sCommand == "lock" && iNum <= iLockAuth){
            lock = TRUE;
            iLockAuth = iNum;
            llInstantMessage(kID,"/me makes a soft click as the lock is enabled");
            llPlaySound("dec9fb53-0fef-29ae-a21d-b3047525d312", 1.0);
            check_settings();
        } else llInstantMessage(kID,"Sorry you are not authorized to unlock this device");
    }
}

Link(string packet, integer iNum, string sStr, key kID){
    list packet_data = [ "pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID ];

    if (packet == "online" || packet == "update") // only add optin if packet type is online or update
    {
        llListInsertList(packet_data, [ "optin", llDumpList2String(g_lOptedLM, "~") ], -1);
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
key g_kWearer;

initialize(){
    g_kWearer = llGetOwner();
    API_CHANNEL = ((integer)("0x" + llGetSubString((string)g_kWearer, 0, 8))) + 0xf6eb - 0xd2;
    llListen(API_CHANNEL, "", "", "");
    Link("online", 0, "", g_kWearer); // This is the signal to initiate communication between the addon and the collar
    llSetTimerEvent(10);
    g_iLMLastSent = llGetUnixTime();
    check_settings();
}

softreset(){
    g_kCollar = NULL_KEY;
    initialize();
}

shutdown(){
    lock=FALSE;
    llOwnerSay("@detach=y");
    g_lMenuIDs = [];
    g_kCollar = NULL_KEY;
    Link("offline", 0, "", llGetOwnerKey(g_kCollar));
}

integer l_Authorized = 503;
integer lock = FALSE;
string bLock;
string baLock = "☒Lock";
string biLock = "☐Lock";

check_settings()
{
    if (lock ){
        bLock=baLock;
        llOwnerSay("@detach=n");
    }
    else {
        bLock=biLock;
        llOwnerSay("@detach=y");
    }
}

default
{
    state_entry()
    {
        initialize();
    }    
    
    on_rez(integer start_pram){
        softreset();
    }
    attach(key kID) {
        if (kID == NULL_KEY) llResetScript();
        else if(kID != g_kWearer){
            llResetScript();
        } else {
            softreset();
        }
    }
    changed(integer change){
        if(change & CHANGED_REGION){
            softreset();
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
            //shutdown();
            softreset();
        }

        if (g_kCollar == NULL_KEY) Link("online", 0, "", g_kWearer);
    }

    listen(integer channel, string name, key id, string msg){
        string sPacketType = llJsonGetValue(msg, ["pkt_type"]);
        if (sPacketType == "approved" && g_kCollar == NULL_KEY)
        {
            // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
            g_kCollar = id;
            Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
            g_iLMLastRecv = llGetUnixTime();
        }
        else if (sPacketType == "dc" && g_kCollar == id)
        {
            //shutdown();
            softreset();
            //llResetScript(); // This addon is designed to always be connected because it is a test
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

                if (iNum == LM_SETTING_RESPONSE)
                {
                    list lPar     = llParseString2List(sStr, ["_","="], []);
                    string sToken = llList2String(lPar, 0);
                    string sVar   = llList2String(lPar, 1);
                    string sVal   = llList2String(lPar, 2);

                    if (sToken == "auth")
                    {
                        if (sVar == "owner")
                        {
                            //llSay(0, "owner values is: " + sVal);
                        }
                    }
                }
                else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
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

                        if (sMenu == "Menu~Main")
                        {
                            if (sMsg == UPMENU)
                            {
                                Link("from_addon", iAuth, "menu Addons", kAv);
                            }
                            if (sMsg == baLock )
                            {
                                UserCommand(iAuth,g_sAddon+"unlock",kAv);
                            }
                            if (sMsg == biLock )
                            {
                                UserCommand(iAuth,g_sAddon+"lock",kAv);
                            }
                            else if (sMsg == "DISCONNECT")
                            {
                                shutdown();
                            }
                        }
                    }
                }
            }
        }
    }
}
