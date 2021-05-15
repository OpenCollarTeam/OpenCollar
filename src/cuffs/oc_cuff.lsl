
/*
This file is a part of OpenCollar.
Copyright ©2021
: Contributors :
Aria (Tashia Redrose)
    * February 2021       -       Created oc_cuff
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/
list StrideOfList(list src, integer stride, integer start, integer end)
{
    list l = [];
    integer ll = llGetListLength(src);
    if(start < 0)start += ll;
    if(end < 0)end += ll;
    if(end < start) return llList2List(src, start, start);
    while(start <= end)
    {
        l += llList2List(src, start, start);
        start += stride;
    }
    return l;
}

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


integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}
//list g_lCollars;
string g_sAddon = "OpenCollar Cuffs";

string g_sVersion = "1.0.0010";

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

integer LM_SETTING_SAVE     = 2000; //scripts send messages on this channel to have settings saved, <string> must be in form of "token=value"
integer LM_SETTING_REQUEST  = 2001; //when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; //the settings script sends responses on this channel
integer LM_SETTING_DELETE   = 2003; //delete token from settings
//integer LM_SETTING_EMPTY    = 2004; //sent when a token has no value

integer DIALOG          = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT  = -9002;

integer NOTIFY=-1002;


integer SUMMON_PARTICLES = -58931; // Used only for cuffs to summon particles from one NAMED leash point to another NAMED anchor point
// SUMMON_PARTICLES should follow this message format: <From Name>|<To Name>|<Age>|<Gravity>
integer QUERY_POINT_KEY = -58932;
// This query is automatically triggered and the REPLY signal immediately spawns in particles via the SetParticles function
// Replies to this query are posted on the REPLY_POINT_KEY
// Message format for QUERY is: <Name>       | kID identifier
integer REPLY_POINT_KEY = -58933;
// Reply format: <kID identifier>       |kID  <Key>
integer CLEAR_ALL_CHAINS = -58934;
integer STOP_CUFF_POSE = -58935; // <-- stops all active animations originating from this cuff
integer DESUMMON_PARTICLES = -58936; // Message only includes the From point name

integer g_iFirstInit=TRUE;

/*
 * Since Release Candidate 1, Addons will not receive all link messages without prior opt-in.
 * To opt in, add the needed link messages to g_lOptedLM = [], they'll be transmitted on
 * the initial registration and can be updated at any time by sending a packet of type `update`
 * Following LMs require opt-in:
 * [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG]
 */
list g_lOptedLM     = [];
list g_lPoses = [];


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
    string sPrompt = "\n[OpenCollar Cuffs]\nMemory: "+(string)llGetFreeMemory()+"b\nVersion: "+g_sVersion+"\n";
    sPrompt += "\nCuff Name: "+g_sAddon+"\n";

    if(UPDATE_AVAILABLE)sPrompt+="* An update is available!\n";
    if(g_iAmNewer)sPrompt+="** You are using a pre-release version. Some bugs may be encountered!";
    list lButtons  = [];//"TEST CHAINS"];

    if(g_iHasPoses && llGetInventoryType("oc_cuff_pose")==INVENTORY_SCRIPT){
        if(!g_iHidden)
            lButtons+=["Pose"];
        else sPrompt +="\nPoses not available while the cuffs are hidden";
    }

    if(iAuth == CMD_OWNER)
    {
        lButtons+=["ClearChains"];
    }

    if(!g_iSyncLock){
        lButtons += [Checkbox(g_iCuffLocked, "Lock")];
    }

    lButtons += [Checkbox(g_iSyncLock, "SyncLock")];




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

    if(!g_iHasPoses)packet_data += ["noMenu", 1];
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

///
/// FROM SL WIKI http://wiki.secondlife.com/wiki/Combined_Library#Replace
///
string str_replace(string str, string search, string replace) {
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}

integer g_iHasPoses=TRUE;

ClearAllParticles(){
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=LINK_ROOT;i<=end;i++){
        llLinkParticleSystem(i,[]);
    }
}

SetParticles(integer link, key kID,key kTexture, float fMaxAge, float fGravity){

    if(kTexture=="" || kTexture=="def")kTexture="4cde01ac-4279-2742-71e1-47ff81cc3529";
    if(fMaxAge==0)fMaxAge=7.3;
    if(llRound(fGravity) == -1) fGravity = -0.01;
    llLinkParticleSystem(link, [
PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_DROP,
PSYS_PART_START_ALPHA,1,
PSYS_PART_START_SCALE,<0.075, 0.075, 0>,
PSYS_PART_END_SCALE,<0.075,0.075,0>,
PSYS_PART_MAX_AGE,fMaxAge,
PSYS_SRC_BURST_PART_COUNT,1,
PSYS_SRC_ACCEL,<0, 0, -0.01>,
PSYS_SRC_TEXTURE,kTexture,
PSYS_SRC_TARGET_KEY,kID,
PSYS_PART_FLAGS,PSYS_PART_FOLLOW_SRC_MASK|
PSYS_PART_FOLLOW_VELOCITY_MASK|
PSYS_PART_INTERP_SCALE_MASK|
PSYS_PART_TARGET_POS_MASK
        ]);
}

list g_lMyPoints = [];
string g_sActivePose;
list GetKey(string LinkName)
{
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=LINK_ROOT;i<=end;i++){
        if(llGetLinkName(i)==LinkName){
            return [i, llGetLinkKey(i)];
        }
    }

    return [LINK_ROOT, llGetLinkKey(LINK_ROOT)];
}

integer g_iLMV2Listen=-1;

list g_lLMV2Map;
list g_lLGv2Map;

integer g_iLGV2Listen;
integer g_iTmpHide=0;

integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

integer g_iCuffLocked=FALSE;
integer g_iLocked;
integer g_iSyncLock;
string g_sCurrentPose="NONE";

PosesMenu (key kAv, integer iAuth, integer iPage)
{
    string sPrompt = "\n[OpenCollar Cuffs]\n> Poses selection\n\n* Current Pose: ";

    sPrompt += g_sCurrentPose;

    list lButtons = g_lPoses;

    Dialog(kAv, sPrompt, lButtons, ["*STOP*", "BACK"], iPage, iAuth, "Cuffs~Poses");
}


Desummon(list lPoints)
{
    integer ix=0;
    integer end = llGetListLength(lPoints);
    for(ix=0;ix<end;ix++){
        list tmp = llParseString2List(llList2String(lPoints,ix),["="],[]);
        Link("from_addon", DESUMMON_PARTICLES, llList2String(tmp,0), "");
    }
}

Summon(list opts, string age, string gravity)
{

    integer i=0;
    integer end = llGetListLength(opts);
    for(i=0;i<end;i++){
        // loop over and send out SUMMON_PARTICLES
        list tmp = llParseString2List(llList2String(opts,i), ["="],[]);
        Link("from_addon", SUMMON_PARTICLES, llList2String(tmp,0)+"|"+llList2String(tmp,1)+"|"+age+"|"+gravity, "");
    }
}

string g_sPoseName= "";
integer g_iHidden=FALSE;

ToggleLock(integer iLocked)
{
    if(g_iHidden)return;
    integer i=LINK_ROOT;
    integer end = llGetNumberOfPrims();
    for(i=LINK_ROOT;i<=end;i++){
        string desc = llList2String(llGetLinkPrimitiveParams(i, [PRIM_DESC]),0);
        list lElements = llParseStringKeepNulls(desc,["~"],[]);

        if(iLocked){
            if(llListFindList(lElements, ["ClosedLock"])!=-1){
                llSetLinkAlpha(i, TRUE, ALL_SIDES);
            }

            if(llListFindList(lElements, ["OpenLock"])!=-1){
                llSetLinkAlpha(i, FALSE, ALL_SIDES);
            }
        }else{
            if(llListFindList(lElements, ["ClosedLock"])!=-1){
                llSetLinkAlpha(i, FALSE, ALL_SIDES);
            }

            if(llListFindList(lElements, ["OpenLock"])!=-1){
                llSetLinkAlpha(i, TRUE, ALL_SIDES);
            }
        }
    }
}

ToggleAlpha(integer iHidden)
{
    if(iHidden)ClearAllParticles();
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=LINK_ROOT;i<=end;i++){
        // check if description says no hide
        list lData = llParseString2List(llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0),["~"],[]);

        integer iOverride=FALSE;
        if(llListFindList(lData,["ClosedLock"])!=-1)iOverride=1;
        if(llListFindList(lData,["OpenLock"])!=-1)iOverride=1;

        if(llListFindList(lData,["nohide"])==-1 || iOverride)llSetLinkAlpha(i, !iHidden, ALL_SIDES);
    }
}
default
{
    state_entry(){
        g_lMyPoints=[];
        llMessageLinked(LINK_SET,-1,"","");
        if(llGetInventoryType("CuffConfig")==INVENTORY_NOTECARD)
            UpdateDSRequest(NULL, llGetNotecardLine("CuffConfig",0), "read_conf:0");
        else
        {
            llOwnerSay("ERROR: CuffConfig notecard is missing");
        }
    }

    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            llResetScript();
        }
    }

    attach(key kID){
        if(kID != NULL_KEY)
        {
            // Process
            llResetScript();
        }
    }

    link_message(integer iSend,integer iNum, string sMsg, key kID)
    {
        if(iNum==2)
        {

            UpdateDSRequest(NULL, llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/cuffs.txt",[],""), "check_version");
            if(g_iLMV2Listen !=-1)llListenRemove(g_iLMV2Listen);
            g_iLMV2Listen = llListen(-8888, "", "", "");


            if(g_iLGV2Listen !=-1)llListenRemove(g_iLGV2Listen);
            g_iLGV2Listen = llListen(-9119, "", "", "");
        } else if(iNum == 0){
            ClearAllParticles();
        } else if(iNum == 401){
            Desummon(llParseString2List(sMsg,["~"],[]));
        } else if(iNum == 400)
        {
            list lTmp = llParseString2List(kID,["|"],[]);
            Summon(llParseString2List(sMsg, ["~"],[]), llList2String(lTmp,0), llList2String(lTmp,1));
        } else if(iNum == 10)
        {
            list lTmp = llParseString2List(kID, ["^"],[]);
            g_lPoses = llParseString2List(sMsg,["`"],[]);
            PosesMenu((key)llList2String(lTmp,0), (integer)llList2String(lTmp,1), 0);
        } else if(iNum == 999)
        {
            Link(llJsonGetValue(sMsg, ["pkt"]), (integer)llJsonGetValue(sMsg, ["iNum"]), llJsonGetValue(sMsg, ["sMsg"]), (key)llJsonGetValue(sMsg,["kID"]));
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
                    llOwnerSay("An update is available");
                } else{
                    //llOwnerSay("I am up to date, there are no newer scripts");
                }

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

                ToggleAlpha(FALSE);
                llOwnerSay(g_sAddon+" ready ("+(string)llGetFreeMemory()+"b)");
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
            llOwnerSay("Lost connection to collar - resetting");
            llResetScript();
            // This script is always-on. Reset and try again
        }

        if(llGetTime()>=10.0 && g_kCollar==NULL_KEY){
            llOwnerSay("Could not find the collar. Retrying");
            llResetScript();
        }
    }


    dataserver(key kID, string sData){
        if(HasDSRequest(kID)!=-1){
            list lMeta = llParseString2List(GetDSMeta(kID), [":"],[]);
            //llSay(0, "dataserver (sData: "+sData+")\nMeta: "+GetDSMeta(kID));
            if(llList2String(lMeta,0)=="read_conf"){
                if(sData==EOF){
                    DeleteDSReq(kID);
                    //llWhisper(0, "Cuff configuration finished reading : Cuff Name = "+g_sAddon);
                    //llWhisper(0, "My Points: "+llDumpList2String(g_lMyPoints,", "));
                    //llWhisper(0, "LMV2 Mapping: "+llDumpList2String(g_lLMV2Map, ">"));
                    //llWhisper(0, "LGv2 Mapping: "+llDumpList2String(g_lLGv2Map, ">"));
                }else{
                    integer iLine=(integer)llList2String(lMeta,1);
                    iLine++;

                    list lParam = llParseString2List(sData,[" = "],[]);
                    if(llList2String(lParam,0)=="Poses"){
                        g_sPoseName = llList2String(lParam,1);
                        g_sPoseName = llToLower(str_replace(g_sPoseName, " ", ""));
                        g_sPoseName = llToLower(str_replace(g_sPoseName, "_", ""));
                        g_sPoseName = llToLower(str_replace(g_sPoseName, "=", ""));
                        g_sPoseName = llToLower(str_replace(g_sPoseName, "~", ""));
                        llMessageLinked(LINK_SET, 1, llList2String(lParam,1), "read_poses");
                    } else if(llList2String(lParam,0)=="CuffName"){
                        g_sAddon = llList2String(lParam,1);
                        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
                    } else if(llList2String(lParam,0) == "MyPoint"){
                        g_lMyPoints += [llList2String(lParam,1)]+ GetKey(llList2String(lParam,1));
                    }else if(llList2String(lParam,0)=="LMV2Map"){
                        g_lLMV2Map = llParseString2List(llList2String(lParam,1), [" > "],[]);
                    }else if(llList2String(lParam,0)=="LGv2Map"){
                        g_lLGv2Map = llParseString2List(llList2String(lParam,1), [" > "],[]);
                    } else if(llList2String(lParam,0)=="NoPoses"){
                        ClearAllParticles();
                        UpdateDSRequest(NULL, llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/cuffs.txt",[],""), "check_version");
                        if(g_iLMV2Listen !=-1)llListenRemove(g_iLMV2Listen);
                        g_iLMV2Listen = llListen(-8888, "", "", "");


                        if(g_iLGV2Listen !=-1)llListenRemove(g_iLGV2Listen);
                        g_iLGV2Listen = llListen(-9119, "", "", "");
                        g_iHasPoses=FALSE;
                    } else if(llList2String(lParam,0)=="CollarPoses"){
                        llMessageLinked(LINK_SET,1,llList2String(lParam,1), "read_collar");
                    }

                    UpdateDSRequest(kID, llGetNotecardLine("CuffConfig",iLine), "read_conf:"+(string)iLine);
                }
            }
        }
    }

    touch_start(integer t){
        Link("from_addon", 0, "menu "+g_sAddon, llDetectedKey(0));
    }

    listen(integer channel, string name, key id, string msg){
        if(channel==API_CHANNEL){
            string sPacketType = llJsonGetValue(msg, ["pkt_type"]);
            if (sPacketType == "approved" && g_kCollar == NULL_KEY)
            {
                // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
                g_kCollar = id;
                Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
            } else if(sPacketType == "denied" && g_kCollar == NULL_KEY)
            {
                //llSay(0, "Collar connection refused by collar. Please enable wearer-owned addons to use this device.");
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



                        //llSay(0, "SAVE "+sToken+"_"+sVar+"="+sVal);

                        if (sToken == "occuffs")
                        {
                            if (sVar == "synclock")
                            {
                                g_iSyncLock=(integer)sVal;
                            } else if(sVar == "locked"){
                                g_iCuffLocked=(integer)sVal;
                                if(!g_iSyncLock)
                                {
                                    if(g_iCuffLocked)
                                    {
                                    llOwnerSay("@detach=n");
                                    ToggleLock(TRUE);
                                    }
                                    else
                                    {
                                    llOwnerSay("@detach=y");
                                    ToggleLock(FALSE);
                                    }
                                }
                            } else if(sVar == g_sPoseName+"pose")
                            {
                                // check pose map for this pose then perform start animation process
                                g_sCurrentPose=sVal;
                                if(!g_iHidden)
                                    llMessageLinked(LINK_SET, 500, sVal, "0");
                            }

                        }else if(sToken == "global"){
                            if(sVar=="locked"){
                                g_iLocked=(integer)sVal;
                                if(g_iSyncLock){
                                    if(g_iLocked)llOwnerSay("@detach=n");
                                    else llOwnerSay("@detach=y");
                                }
                            } else if(sVar=="checkboxes"){
                                g_lCheckboxes=llParseString2List(sVal,[","],[]);
                            } else if(sVar == "hide"){
                                if(g_iHidden!= (integer)sVal){
                                    if((integer)sVal){
                                        llMessageLinked(LINK_SET, 509, "", "");
                                        ClearAllParticles();
                                    }else {
                                        if(g_iHasPoses) // We only need to be requesting settings from cuffs that have poses, otherwise we are spamming the link message system
                                            Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
                                    }
                                }

                                g_iHidden=(integer)sVal;
                            }
                        } else if(sToken == "anim")
                        {
                            if(sVar=="pose")
                            {
                                g_sActivePose=sVal;
                                if(!g_iHidden)
                                    llMessageLinked(LINK_SET, 300, sVal,"");
                            }
                        }


                        if(sStr=="settings=sent"){
                            if(g_iSyncLock){
                                g_iCuffLocked=g_iLocked;
                                if(g_iLocked){
                                    llOwnerSay("@detach=n");
                                    ToggleLock(TRUE);
                                }
                                else {
                                    ToggleLock(FALSE);
                                    llOwnerSay("@detach=y");
                                }
                            }else{
                                if(g_iCuffLocked){
                                    ToggleLock(TRUE);
                                    llOwnerSay("@detach=n");
                                }
                                else {
                                    ToggleLock(FALSE);
                                    llOwnerSay("@detach=y");
                                }
                            }
                            if(g_sCurrentPose!="NONE")llMessageLinked(LINK_SET,500, g_sCurrentPose, "0");
                            if(g_sActivePose!="")llMessageLinked(LINK_SET,300, g_sActivePose, "");

                            if(!g_iHidden && g_iFirstInit){
                                g_iFirstInit=FALSE;

                                ToggleAlpha(FALSE);
                            }
                        }
                    }else if(iNum == LM_SETTING_DELETE)
                    {

                        list lPar     = llParseString2List(sStr, ["_"], []);
                        string sToken = llList2String(lPar, 0);
                        string sVar   = llList2String(lPar, 1);


                        //llSay(0, "DELETE "+sToken+"_"+sVar);
                        if(sToken == "global"){
                            if(sVar == "locked"){
                                if(g_iSyncLock)llOwnerSay("@detach=y");
                            }
                        } else if(sToken == "occuffs"){
                            if(sVar == "synclock"){
                                g_iSyncLock=FALSE;
                                if(!g_iCuffLocked)llOwnerSay("@detach=y");
                            }
                            else if(sVar == "locked"){
                                g_iCuffLocked=FALSE;
                                if(!g_iSyncLock)llOwnerSay("@detach=y");
                            } else if(sVar==g_sPoseName+"pose"){
                                g_sCurrentPose="NONE";
                            }
                        } else if(sToken == "anim")
                        {
                            if(sVar == "pose")
                            {
                                if(g_sActivePose != ""){
                                    if(!g_iHidden)
                                        llMessageLinked(LINK_SET,301, "", "");
                                }
                                g_sActivePose="";
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
                            integer iPage = (integer)llList2String(lMenuParams,2);
                            integer iAuth = llList2Integer(lMenuParams, 3);


                            integer iRespring=TRUE;
                            if (sMenu == "Menu~Main")
                            {
                                if (sMsg == UPMENU)
                                {
                                    iRespring=FALSE;
                                    Link("from_addon", iAuth, "menu Addons", kAv);
                                }
                                else if (sMsg == "Pose")
                                {
                                    iRespring=FALSE;
                                    llMessageLinked(LINK_SET,9, (string)kAv, (string)iAuth); // Retrieve the pose menu button names
                                    //PosesMenu(kAv,iAuth,0);
                                    //llSay(0, "This is an example addon.");
                                } else if(sMsg == "TEST CHAINS"){
                                    llSay(0, "Chain Test Program");
                                    llSay(0, "Chaining frlac > fllac | bllac > brlac");
                                    llSay(0, "Activate pose | nadu");

                                    Link("from_addon", SUMMON_PARTICLES, "frlac|fllac|2", "");
                                    Link("from_addon", SUMMON_PARTICLES, "bllac|brlac|2", "");
                                    Link("from_addon", CMD_OWNER, "nadu", "");
                                }else if(sMsg == "ClearChains"){
                                    if(iAuth==CMD_OWNER)
                                        Link("from_addon", CLEAR_ALL_CHAINS, "", "");
                                } else if(sMsg == Checkbox(g_iSyncLock, "SyncLock")){
                                    if(iAuth == CMD_OWNER){
                                        g_iSyncLock=1-g_iSyncLock;
                                        // sync lock save
                                        Link("from_addon", LM_SETTING_SAVE, "occuffs_synclock="+(string)g_iSyncLock, "");
                                    }else Link("from_addon", NOTIFY, "0%NOACCESS% to toggling lock sync!", kAv);
                                } else if(sMsg == Checkbox(g_iCuffLocked, "Lock")){
                                    if(iAuth==CMD_OWNER){
                                        g_iCuffLocked=1-g_iCuffLocked;
                                        Link("from_addon", LM_SETTING_SAVE, "occuffs_locked="+(string)g_iCuffLocked, "");
                                    }else Link("from_addon", NOTIFY, "0%NOACCESS% to toggling cuffs lock", kAv);

                                }
                                else if (sMsg == "DISCONNECT")
                                {
                                    Link("offline", 0, "", llGetOwnerKey(g_kCollar));
                                    iRespring=FALSE;
                                    g_lMenuIDs = [];
                                    g_kCollar = NULL_KEY;
                                }

                                if(iRespring)Menu(kAv,iAuth);

                            } else if(sMenu=="Cuffs~Poses")
                            {
                                if(sMsg == "*STOP*"){
                                    // send this command to all cuffs, this way we can ensure the animation fully stops, then clear all chains that were associated with this pose
                                    Link("from_addon", STOP_CUFF_POSE, g_sCurrentPose, g_sPoseName);
                                    g_sCurrentPose="NONE";
                                    Link("from_addon", LM_SETTING_DELETE, "occuffs_"+g_sPoseName+"pose","");
                                    //Link("from_addon", CLEAR_ALL_CHAINS, "", "");
                                    iRespring=FALSE;
                                    Link("from_addon", TIMEOUT_REGISTER, "2", "respring_poses:"+(string)iAuth+":"+(string)kAv+":"+(string)iPage+":"+(string)llGetKey());
                                }else if(sMsg == "BACK"){
                                    iRespring=FALSE;
                                    Menu(kAv,iAuth);
                                }else{
                                    // activate pose
                                    //Link("from_addon", CLEAR_ALL_CHAINS, "", "");
                                    g_sCurrentPose=sMsg;
                                    if(!g_iHidden)
                                        llMessageLinked(LINK_SET, 501, sMsg, "");
                                }

                                if(iRespring)PosesMenu(kAv,iAuth,iPage);

                            }
                        }
                    } else if(iNum == QUERY_POINT_KEY)
                    {
                        if(llListFindList(g_lMyPoints, [sStr])!=-1)
                        {
                            Link("from_addon", REPLY_POINT_KEY, kID, llList2String(g_lMyPoints, llListFindList(g_lMyPoints,[sStr])+2));
                        }
                    } else if(iNum == REPLY_POINT_KEY)
                    {
                        if(HasDSRequest((key)sStr)!=-1){
                            string meta = GetDSMeta((key)sStr);
                            DeleteDSReq((key)sStr);
                            list lTmp = llParseString2List(meta, ["|"],[]);
                            list mine = GetKey(llList2String(lTmp,0));
                            SetParticles((integer)llList2String(mine,0), kID, (key)llList2String(lTmp,1), (float)llList2String(lTmp,2), (float)llList2String(lTmp,4));
                            if(llStringLength(llList2String(lTmp,3))>0)
                                llOwnerSay("@"+llList2String(lTmp,3));
                        }
                    } else if(iNum == SUMMON_PARTICLES)
                    {
                        list lTmp = llParseString2List(sStr, ["|"],[]);
                        if(llListFindList(g_lMyPoints, [llList2String(lTmp,0)])!=-1)
                        {
                            key ident = llGenerateKey();
                            UpdateDSRequest(NULL, ident, llList2String(lTmp,0)+"|def|"+llList2String(lTmp,2)+"|"+llList2String(lTmp,3));

                            Link("from_addon", QUERY_POINT_KEY, llList2String(lTmp,1), ident);
                            Link("from_addon", TIMEOUT_REGISTER, "5", "cuff_link_expire:"+(string)ident);
                        }
                    } else if(iNum == TIMEOUT_FIRED){
                        //llSay(0, "timer fired: "+sStr);
                        list lTmp = llParseString2List(sStr, [":"],[]);
                        if(llList2String(lTmp,0) == "cuff_link_expire")
                        {
                            key ident = (key)llList2String(lTmp,1);
                            if(HasDSRequest(ident)!=-1){
                                DeleteDSReq(ident);
                            }
                        } else if(llList2String(lTmp,0) == g_sPoseName+"playback"){
                            list lMap = llParseStringKeepNulls(llBase64ToString(llList2String(lTmp,1)), ["~~~"],[]);
                            g_sCurrentPose=llList2String(lMap,0);

                            //llSay(0, "callback (playback) : "+sStr);
                            //llSay(0, llDumpList2String(lMap, " ~ "));

                            //StartCuffPose(lMap,TRUE);
                            llMessageLinked(LINK_SET, 500, g_sCurrentPose, "1");
                        } else if(llList2String(lTmp,0)=="respring_poses"){
                            if(llGetKey() == (key)llList2String(lTmp,4))
                                PosesMenu((key)llList2String(lTmp,2), (integer)llList2String(lTmp,1), (integer)llList2String(lTmp,3));
                        }
                    } else if(iNum == CLEAR_ALL_CHAINS)
                    {
                        ClearAllParticles();
                        if(!g_iCuffLocked)llOwnerSay("@clear");
                        else {
                            llOwnerSay("@clear");
                            llSleep(0.5);
                            llOwnerSay("@detach=n");
                        }
                    } else if(iNum == STOP_CUFF_POSE && kID == g_sPoseName){
                        if(sStr!="NONE"){
                            llMessageLinked(LINK_SET, 505, sStr, "");
                        }
                    } else if(iNum == DESUMMON_PARTICLES)
                    {
                        integer index = llListFindList(g_lMyPoints, [sStr]);
                        if(index!=-1){
                            list opts = GetKey(sStr);
                            llLinkParticleSystem((integer)llList2String(opts,0), []);
                        }
                    }
                }
            }
        } else if(channel==-8888)
        {
            // LockMeister v2
            //llSay(0, "Command on LockMeister channel: "+msg);

        } else if(channel == -9119)
        {
            //llSay(0, "Command on LockGuard Channel: "+msg);
            list lCmds = llParseString2List(msg, [" "],[]);
            integer ix=0;
            integer end = llGetListLength(lCmds);
            string sLinkTo;
            key kTarget = NULL_KEY;
            key kTexture="";
            float fMaxAge=0;
            if(llList2String(lCmds,0)=="lockguard"){
                if(llList2String(lCmds,1) != (string)llGetOwner())
                {
                    return; // immediately cease processing
                }
            }

            integer index=llListFindList(g_lLGv2Map,[llList2String(lCmds,2)]);
            if(index!=-1)
            {
                // This is my remapping, grab point name, then lookup and immediately begin configuring the particle system
                sLinkTo = llList2String(g_lLGv2Map,index+1);
                ix--; // Stride of two, but the provided command uses only 1 command, the link name
                //llSay(0, "debug: Valid point found");
            }else{
                //llSay(0, "Debug: no valid points found for "+llList2String(lCmds,2));
                return;
            }
            ix=2;
            while(ix!=end)
            {

                if(llList2String(lCmds,ix) == "link"){
                    kTarget = (key)llList2String(lCmds,ix+1);
                    ix++;
                } else if(llList2String(lCmds,ix)=="unlink"){
                    list Links = GetKey(sLinkTo);
                    //llSay(0, "Clear particles for parameters: "+(string)Links);
                    llLinkParticleSystem(llList2Integer(Links,0), []);
                    return;
                } else if(llList2String(lCmds,ix) == "texture"){
                    if(llStringLength(llList2String(lCmds, ix+1))>=32){
                        kTexture=(key)llList2String(lCmds,ix+1);
                        ix++;
                    }
                } else if(llList2String(lCmds,ix)=="life")
                {
                    float val = (float)llList2String(lCmds,ix+1);
                    if(val!=0)
                    {
                        fMaxAge=2+val;
                        ix++;
                    }
                }
                ix++;
            }


            list Links = GetKey(sLinkTo);
            SetParticles(llList2Integer(Links,0), kTarget, kTexture, fMaxAge, -1.111);
        }
    }
}
