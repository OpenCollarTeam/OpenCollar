    
/*
This file is a part of OpenCollar.
Copyright ©2021


: Contributors :

Aria (Tashia Redrose)
    * February 2021       -       Created oc_cuffs
      
      
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

integer API_CHANNEL = 0x60b97b5e;
string NEW_VERSION;
integer UPDATE_AVAILABLE;
integer g_iAmNewer;

Compare(string V1, string V2){
    NEW_VERSION=V2;
    
    if(V1==V2){
        UPDATE_AVAILABLE=FALSE;
        return;
    }
    V1 = llDumpList2String(llParseString2List(V1, ["."],[]),"");
    V2 = llDumpList2String(llParseString2List(V2, ["."],[]), "");
    integer iV1 = (integer)V1;
    integer iV2 = (integer)V2;
    
    if(iV1 < iV2){
        UPDATE_AVAILABLE=TRUE;
        g_iAmNewer=FALSE;
    } else if(iV1 == iV2) return;
    else if(iV1 > iV2){
        UPDATE_AVAILABLE=FALSE;
        g_iAmNewer=TRUE;
        
        llSetText("", <1,0,0>,1);
    }
}
//list g_lCollars;
string g_sAddon = "OpenCollar Cuffs";

string g_sVersion = "1.0.0001";

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
list g_lPoseMap = [];

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
    string sPrompt = "\n[OpenCollar Cuffs]";
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
        packet_data+= [ "optin", llDumpList2String(g_lOptedLM, "~") ];
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


list g_lDSRequests;
key NULL=NULL_KEY;
UpdateDSRequest(key orig, key new, string meta){
    if(orig == NULL){
        g_lDSRequests += [new,meta];
    }else {
        integer index = HasDSRequest(orig);
        if(index==-1)return;
        else{
            g_lDSRequests = llListReplaceList(g_lDSRequests, [new,meta], index,index+1);
        }
    }
}

string GetDSMeta(key id){
    integer index=llListFindList(g_lDSRequests,[id]);
    if(index==-1){
        return "N/A";
    }else{
        return llList2String(g_lDSRequests,index+1);
    }
}

integer HasDSRequest(key ID){
    return llListFindList(g_lDSRequests, [ID]);
}

DeleteDSReq(key ID){
    if(HasDSRequest(ID)!=-1)
        g_lDSRequests = llDeleteSubList(g_lDSRequests, HasDSRequest(ID), HasDSRequest(ID)+1);
    else return;
}


string g_sPendingPose;
string g_sPendingAnim;
string g_sPendingChains;
string g_sPendingRLV;
string g_sPendingShow;

ClearAllParticles(){
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=LINK_ROOT;i<=end;i++){
        llLinkParticleSystem(i,[]);
    }
}
default
{
    state_entry(){
        if(llGetInventoryType("CuffConfig")==INVENTORY_NOTECARD)
            UpdateDSRequest(NULL, llGetNotecardLine("CuffConfig",0), "read_conf:0");
        else
        {
            llOwnerSay("ERROR: CuffConfig notecard is missing");
        }
    }
    
    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            g_lDSRequests=[];// Stop and cancel all dataserver queries, read notecard config
            UpdateDSRequest(NULL, llGetNotecardLine("CuffConfig",0), "read_conf:0");
        }
    }
    
    attach(key kID){
        if(kID != NULL_KEY)
        {
            // Process
            g_lDSRequests=[];
            UpdateDSRequest(NULL, llGetNotecardLine("CuffConfig",0), "read_conf:0");
        }
    }
    
    http_response(key kID, integer iStat, list lMeta, string sBody)
    {
        if(HasDSRequest(kID)!=-1)
        {
            string meta = GetDSMeta(kID);
            DeleteDSReq(kID);
            if(meta=="check_version"){
                Compare(g_sVersion, sBody);
                
                if(UPDATE_AVAILABLE)
                {
                    llWhisper(0, "An update is available");
                } else{
                    llWhisper(0, "I am up to date, there are no newer scripts");
                }
                
                llWhisper(0, "Begin connection to collar");
                //
                // Collar Connection Start
                //
                
                API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
                llListen(API_CHANNEL, "", "", "");
                Link("online", 0, "", llGetOwner());
                llResetTime();
                g_iLMLastSent=llGetUnixTime();
                g_iLMLastRecv=llGetUnixTime();
                llSetTimerEvent(60);
            }
        }
    }
    
    timer()
    {
        if(llGetUnixTime()>=(g_iLMLastSent+30) && g_kCollar != NULL_KEY)
        {
            g_iLMLastSent=llGetUnixTime();
            Link("ping", 0, "", g_kCollar);
        }
        if(llGetUnixTime()>(g_iLMLastRecv+(5*60)) && g_kCollar != NULL_KEY)
        {
            llWhisper(0, "Lost connection to collar - resetting");
            llResetScript();
            // This script is always-on. Reset and try again
        }
    }
    
    
    dataserver(key kID, string sData){
        if(HasDSRequest(kID)!=-1){
            list lMeta = llParseString2List(GetDSMeta(kID), [":"],[]);
            
            if(llList2String(lMeta,0)=="read_conf"){
                if(sData==EOF){
                    DeleteDSReq(kID);
                    llWhisper(0, "Cuff configuration finished reading : Cuff Name = "+g_sAddon);
                }else{
                    integer iLine=(integer)llList2String(lMeta,1);
                    iLine++;
                    
                    list lParam = llParseString2List(sData,[" = "],[]);
                    if(llList2String(lParam,0)=="Poses"){
                        g_lPoseMap = [];
                        UpdateDSRequest(NULL, llGetNotecardLine(llList2String(lParam,1),0), "read_poses:0:"+llList2String(lParam,1));
                    } else if(llList2String(lParam,0)=="CuffName"){
                        g_sAddon = llList2String(lParam,1);
                    }
                    
                    UpdateDSRequest(kID, llGetNotecardLine("CuffConfig",iLine), "read_conf:"+(string)iLine);
                }
            } else if(llList2String(lMeta,0)=="read_poses"){
                if(sData==EOF){
                    DeleteDSReq(kID);
                    
                    g_lPoseMap += [g_sPendingPose, g_sPendingAnim, g_sPendingChains, g_sPendingRLV, g_sPendingShow];
                    
                    
                    llWhisper(0, "Pose Configuration finished reading : Poses = "+llDumpList2String( llList2ListStrided(g_lPoseMap,0,-1,5), ", ") );

                    llWhisper(0, "Clearing all particle systems");
                    ClearAllParticles();
                    llWhisper(0, "Particles stopped.");
                    llWhisper(0, "Perform check for cuff script update");
                    UpdateDSRequest(NULL, llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/cuffs.txt",[],""), "check_version");
                } else{
                    integer iLine = (integer)llList2String(lMeta,1);
                    string sPoses = llList2String(lMeta,2);
                    iLine++;
                    list lPara = llParseString2List(sData,[":"],[]);
                    if(llList2String(lPara,0) == "PoseName"){
                        if(g_sPendingPose != ""){
                            g_lPoseMap += [g_sPendingPose, g_sPendingAnim, g_sPendingChains, g_sPendingRLV, g_sPendingShow];
                        }
                        
                        g_sPendingPose=llList2String(lPara,1);
                    } else if(llList2String(lPara,0) == "PoseAnim"){
                        g_sPendingAnim = llList2String(lPara,1);
                    } else if(llList2String(lPara,0) == "PoseChains"){
                        g_sPendingChains = llList2String(lPara,1);
                    } else if(llList2String(lPara,0) == "PoseRestrictions"){
                        g_sPendingRLV = llList2String(lPara,1);
                    } else if(llList2String(lPara,0) == "PoseShow"){
                        g_sPendingShow = llList2String(lPara,1);
                    }
                    
                    UpdateDSRequest(kID, llGetNotecardLine(sPoses, iLine), "read_poses:"+(string)iLine+":"+sPoses);
                }
            }
        }
    }
    
    listen(integer channel, string name, key id, string msg){
        string sPacketType = llJsonGetValue(msg, ["pkt_type"]);
        if (sPacketType == "approved" && g_kCollar == NULL_KEY)
        {
            // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
            g_kCollar = id;
            Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
        } else if(sPacketType == "denied" && g_kCollar == NULL_KEY)
        {
            llSay(0, "Collar connection refused by collar. Please enable wearer-owned addons to use this device.");
            llSetTimerEvent(0);
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
                            llSay(0, "owner values is: " + sVal);
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
                            else if (sMsg == "A Button")
                            {
                                llSay(0, "This is an example addon.");
                            }
                            else if (sMsg == "DISCONNECT")
                            {
                                Link("offline", 0, "", llGetOwnerKey(g_kCollar));
                                g_lMenuIDs = [];
                                g_kCollar = NULL_KEY;
                            }
                        }
                    }
                }
            }
        }
    }
}
