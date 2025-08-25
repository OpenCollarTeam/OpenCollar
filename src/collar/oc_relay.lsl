/*
This file is a part of OpenCollar.
Copyright ©2021

: Contributors :

Aria (Tashia Redrose)
    *May 2020       -       Created new Integrated relay
    *July 2020      -       Finish integrated relay. Fix bug where the wearer could lock themselves out of the relay options

Felkami (Caraway Ohmai)
    *Dec 2020       -       Fixed #461, Modified runaway language to not assume relay on at runaway

Kristen Mynx,  Phidoux (taya Maruti)
    *May 2022  - Fixed bug: !release or @clear sent to the relay would clear all
    restrictions and exceptions from the collar.   Changed the relay to send all RLV 
    commands through RLV_CMD link messages instead of directly to the viewer.  oc_rlvsys
    will process them, and arbitrate between collar and relay restrictions and exceptions.
    Also removed DO_RLV_REFRESH which cleared all restrictions and exceptions.

   *July 2022  - Fixed bug: Ask mode only accepted one RLV command from the object.

Nikki Lacrima 
   *Nov 2023   - Remove extra CMD_SAFEWORD to CMD_RELAY_SAFEWORD processing
               - implemented Yosty7b3's menu streamlining, see pr#963 
Medea Destiny
   *Apr 2025   - Fixed a wearer no access when has trusted permission issue, bug
               found by Annie Zehetbauer in world.
Nikki Lacrima 
   *Jul 2025   - Multirelay functions that uses LSD to store restrictions and sit status
                 Fix CMD_RELAY_SAFEWORD definition
   *Aug 2025   - Handle "Refuse" internally in relay, CMD_RELAY_SAFEWORD shall not trigger full safeword handling in rlvsys
                 Do we even need CMD_RELAY_SAFEWORD??
                 Handle Trusted Owners dropped command
                 Stop relay listener when RLV_OFF
                 Multiple pending ask sources
                 Code cleanup

et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

string g_sScriptVersion = "8.3.1";

string g_sParentMenu = "RLV";
string g_sSubMenu = "Relay";

integer RLV_RELAY_CHANNEL = -1812221819;
integer RELAY_LISTENER;

//MESSAGE MAP
integer RLV_CLEAR=6002;
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer AUTH_REQUEST = 600;
integer AUTH_REPLY=601;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";

string  LSDPrefix="relay"; //All LSD used by this script has this prefix.
integer LSD_REQUEST=-500; //Sends LSDPrefix when received, for flushing no longer used LSD.
integer LSD_RESPONSE=-501; //Reply to above

string LSDRead(string token)
{
    return llLinksetDataRead(LSDPrefix+"_"+token);
}

LSDWrite(string token, string val)
{
    llLinksetDataWrite(LSDPrefix+"_"+token,val);
}

// Restriction data are stored in  LSD  relay_source_UUID = " § separated string of restrictions "
// Commands from pending ask sources are stored in  LSD  relay_ask_UUID = " || separated string of relay commands"
list g_lAllowedSources = [];      
list g_lDisallowedSources = [];
list g_lPendingSourceList = [];  // Sources waiting for ask appproval
list g_lPendingReapply;   // sourceId to wait for pong reply

key g_kForceSitter;       //  LSD relay_sitter = UUID
key g_kSitTarget;         //  LSD relay_sittarget=UUID
key g_kObjectOwner;
key g_kWearer;
integer g_iHasOwners=FALSE;

integer g_iMode = 0;      //  LSD relay_mode
integer g_iWearer=TRUE;    // LSD relay_wearer    Lockout wearer option 
integer g_iTrustOwners = FALSE;  //  LSD relay_trustowner
integer g_iTrustTrusted = FALSE; //  LSD relay_trusttrust
integer g_iHelplessMode=FALSE;   //  LSD relay_helpless

integer MODE_ASK=1;
integer MODE_AUTO = 2;

string tf(integer a){
    if(a)return "true";
    else return "false";
}

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}

list g_lCheckboxes=["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, sName+"~"+llGetScriptName());
}

Menu(key kID, integer iAuth) {
    if(iAuth == CMD_OWNER && kID==g_kWearer && !g_iHasOwners){
        g_iWearer=TRUE;
        llLinksetDataWrite("relay_wearer",(string)g_iWearer);
        HelplessChecks();
    }
    string sPrompt = "\n[Relay App]\n\nNote: Wearer checkbox will allow or disallow wearer changes to relay\n\n";
    list lButtons = [Checkbox(bool((g_iMode==0)), "OFF"), Checkbox(bool((g_iMode==MODE_ASK)),"Ask"), Checkbox(bool((g_iMode==MODE_AUTO)),"Auto"), Checkbox(g_iWearer, "Wearer")];
    list sources = llLinksetDataFindKeys(LSDPrefix+"_source_.*", 0, 1);
llScriptProfiler( PROFILE_SCRIPT_MEMORY );
    if (llGetListLength(sources)>0) {
        list data = llParseString2List(llList2String(sources,0),["_"],[""]);
        key kSourceID = llList2Key(data, 2);
        sPrompt += "Source: "+llKey2Name(kSourceID);
        lButtons+=["REFUSE"];
        sPrompt+="\nREFUSE -> Will safeword the relay only";
    } else {
        sPrompt += "Source: NONE";
    }
llScriptProfiler( PROFILE_NONE );
       // display memory usage...
    sPrompt +="\nMemory used: " + (string)llGetSPMaxMemory() + " bytes, total memory: " + (string)llGetMemoryLimit() + " bytes.";

    if(!g_iWearer){
        lButtons += [Checkbox(g_iHelplessMode, "Helpless")];
    }

    lButtons += [Checkbox(g_iTrustOwners, "Trust Owners"), Checkbox(g_iTrustTrusted, "Trust Trusted")];

    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    sStr=llToLower(sStr);
    if (llSubStringIndex(sStr,llToLower(g_sSubMenu)) && sStr != "menu "+llToLower(g_sSubMenu)) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_iWearer = TRUE;
        llLinksetDataWrite("relay_wearer",(string)g_iWearer);
//        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_wearer=1","");
        return;
    }
    if (sStr==llToLower(g_sSubMenu) || sStr == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    else {
        string sChangetype = llToLower(llList2String(llParseString2List(sStr, [" "], []),1));
        if(sChangetype == "refuse" && !g_iWearer && iNum==CMD_WEARER && !g_iHelplessMode){
            RelayClear();
            string sReply = "Relay ";
            if(sChangetype == "refuse")sReply +="safeworded!";
            llMessageLinked(LINK_SET, NOTIFY, "0"+sReply, kID);
            return;
        }
        if(kID==g_kWearer && !g_iWearer){
            llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% due to wearer lockout", kID);
            return;
        }

        if(iNum == CMD_OWNER || iNum == CMD_WEARER){
            if(sChangetype == "off")g_iMode=0;
            else if(sChangetype=="ask")g_iMode=MODE_ASK;
            else if(sChangetype == "auto")g_iMode=MODE_AUTO;
            else if(sChangetype == "helpless") g_iHelplessMode = 1-g_iHelplessMode;
            else if(sChangetype == "wearer") {
                g_iWearer=1-g_iWearer;
                if(!g_iWearer && !g_iHasOwners){
                    g_iWearer=TRUE;
                    llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to locking self out of relay options while unowned", kID);
                }
            }
            else if(sChangetype == "pending"){
//                if(g_kPendingSource==NULL_KEY){
                if(llGetListLength(g_lPendingSourceList)==0){
                    llMessageLinked(LINK_SET, NOTIFY, "0No pending source", kID);
                    return;
                }else {
//                    PromptForSource(g_kPendingSource);
                    PromptForSource(llList2Key(g_lPendingSourceList,0));
                }
            }
            else if(sChangetype == "refuse" ) RelayClear();
            else{
                llMessageLinked(LINK_SET, NOTIFY, "0Command unknown", kID);
                return;
            }
            string sReply = "Relay ";
            if(sChangetype == "refuse")sReply +="safeworded!";
            else if(sChangetype == "helpless")sReply += "helpless toggled to "+tf(g_iHelplessMode);
            else if(sChangetype == "wearer")sReply += "wearer access toggled to "+tf(g_iWearer);
            else sReply += "mode set to "+sChangetype;
            llMessageLinked(LINK_SET, NOTIFY, "0"+sReply, kID);

            // Save data
            llLinksetDataWrite("relay_helpless",(string)g_iHelplessMode);
            llLinksetDataWrite("relay_wearer",(string)g_iWearer);
            llLinksetDataWrite("relay_mode",(string)g_iMode);
        }
    }
}

RLV(string cmd, key kID)
{
    // send the rlv command to oc_rlvsys
    llMessageLinked(LINK_THIS, RLV_CMD,
        llGetSubString(cmd,1,999),  // knock off the "@"
        kID);
    // Use the source UUID, so oc_relay can then handle multiple relay objects
    // and let oc_rlvsys handle/abritrate/manage multiple sources.
}

GetPendingReapplyList(){
    g_lPendingReapply = [];
    // read list of previous sources for possible reapply
    integer i;
    list sources = llLinksetDataFindKeys(LSDPrefix+"_source_.*", 0, 10);
    for (i=0; i< llGetListLength(sources); i++) {
        list data = llParseString2List(llList2String(sources,i),["_"],[""]);
        key kID = llList2Key(data, 2);
        g_lPendingReapply += [kID];  
    }
}

Reapply(key kSourceId) {
    integer ix = llListFindList(g_lPendingReapply,[kSourceId]);
    // Only reapply sources in g_lPendingReapply list
    if (ix >= 0) {
        llOwnerSay("Pong and reapply: "+(string)kSourceId);
        // first try to resit
        if( kSourceId == g_kForceSitter && g_kSitTarget != NULL_KEY ) {
            RLV("@sit:"+(string)g_kSitTarget+"=force", kSourceId);
        }
        // read restictions from LSD and apply them
        list lRestr=llParseString2List(LSDRead("source_"+(string)kSourceId),["§"],[]);
        integer iRestr = 0;
        for (iRestr = 0;iRestr < llGetListLength(lRestr); iRestr++) {
             string sBehav = llList2String(lRestr,iRestr);
             RLV("@"+sBehav+"=add", kSourceId);
             AddRestriction(kSourceId, sBehav);
        }
        g_lPendingReapply = llDeleteSubList(g_lPendingReapply,ix,ix);
    }
    else {
        //llOwnerSay("Pong not found");    
    }
}

ReleaseAll(integer iClearLSD){
    integer i;
    list sources = llLinksetDataFindKeys(LSDPrefix+"_source_.*", 0, 10);
    g_lPendingReapply = [];
    for (i=0; i< llGetListLength(sources); i++) {
        list data = llParseString2List(llList2String(sources,i),["_"],[""]);
        key kID = llList2Key(data, 2);
        g_lPendingReapply = g_lPendingReapply + [kID];
        Release(kID, iClearLSD);  
    }
}

Release(key kID, integer iClearLSD){
    llRegionSayTo(kID, RLV_RELAY_CHANNEL, "release,"+(string)kID+",!release,ok");
    // rlvsys handles clearing by source.
    RLV("@clear", kID);
    // Clear from LSD relay source's
    if (iClearLSD) LSDWrite("source_"+(string)kID,"");
    // clear will remove pending status and commands
    integer ix = llListFindList(g_lPendingSourceList,[kID]);
    if (ix > -1) {
        g_lPendingSourceList=llDeleteSubList(g_lPendingSourceList,ix,ix);
        LSDWrite("ask_"+(string)kID,"");
    }
}

AddRestriction(key kID, string sBehav) {
    // read restrictions for this source, if any
    string sSrcRestr = LSDRead("source_"+(string)kID);
    //add new sources to sources list
    if (sSrcRestr == "") {  //if this is a restriction from a new source
        if (llGetListLength(llLinksetDataFindKeys(LSDPrefix+"_source_.*", 0, 10)) > 5) {
            llOwnerSay("Capping number of RLV sources, dropping: "+(string)kID);
            return;
        }
    }
    if (llSubStringIndex("§"+sSrcRestr+"§","§"+sBehav+"§") == -1) {
        //Debug("AddRestriction 2.2");
        sSrcRestr+="§"+sBehav;
        if (llSubStringIndex(sSrcRestr,"§")==0) sSrcRestr=llGetSubString(sSrcRestr,1,-1);
        if (sBehav=="unsit") {
            g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
            g_kForceSitter=kID;
            LSDWrite("sitter", (string)g_kForceSitter);
            LSDWrite("sittarget", (string)g_kSitTarget);                            
        }
    }
    LSDWrite("source_"+(string)kID,sSrcRestr);
}

RemRestriction(key kID, string sBehav) {
    // read restrictions for this source, if any
    string sSrcRestr = LSDRead("source_"+(string)kID);
    if (sSrcRestr) { //if this source set has any restrictions
        list lSrcRestr = llParseString2List(sSrcRestr,["§"],[]); //get a list of this source's restrictions
        integer iRestr=llListFindList(lSrcRestr,[sBehav]);  //get index of this restriction from that list
        if (~iRestr) {   //if the restriction is in the list
            lSrcRestr=llDeleteSubList(lSrcRestr,iRestr,iRestr); //delete the restriction from the list
            sSrcRestr=llDumpList2String(lSrcRestr,"§");//store the list in the sources restrictions list
            LSDWrite("source_"+(string)kID,sSrcRestr);
            if (sBehav=="unsit"&&g_kForceSitter==kID) {
                g_kForceSitter=NULL_KEY;
                g_kSitTarget=NULL_KEY;
                LSDWrite("sitter", (string)g_kForceSitter);
                LSDWrite("sittarget", (string)g_kSitTarget);                            
            }
        }
    }
}

RelayClear() {
    if(g_iHelplessMode)return;
    ReleaseAll(TRUE);
    g_lAllowedSources = [];
    integer iOldMode=g_iMode;
    g_iMode=0;
    llMessageLinked(LINK_SET, NOTIFY,"0Relay temporarily suppressed for 30 seconds due to safeword or clear all.", g_kWearer);
    llSleep(30);
    g_iMode=iOldMode;
    llMessageLinked(LINK_SET,NOTIFY, "0 Relay settings have been restored.",g_kWearer); 
}

PromptForSource(key kID){    
    Dialog(llGetOwner(), "[Relay]\n\nObject Name: "+llKey2Name(kID)+"\nObject ID: "+(string)kID+"\nObject Owner: secondlife:///app/agent/"+(string)g_kObjectOwner+"/about\n\nIs requesting to use your RLV Relay, do you want to allow it?", ["Yes", "No"], [], 0, CMD_WEARER, "AskPrompt");
}

///param id=source
///param msg=RLV command
Process(string msg, key id, integer iWillPrompt){
    integer DoPrompt=FALSE;
    list args = llParseStringKeepNulls(msg,[","],[]);
    if (llGetListLength(args)!=3) return;
    if (llList2Key(args,1)!=g_kWearer && llList2Key(args, 1)!=(key)"ffffffff-ffff-ffff-ffff-ffffffffffff") return;
    string ident = llList2String(args,0);
    list commands = llParseString2List(llList2String(args,2),["|"],[]);
    integer i;
    string command;
    integer nc = llGetListLength(commands);
    // Any command from a ping object will reapply restrictions
    if (llListFindList(g_lPendingReapply,[(string)id]) >= 0)  {
//        llOwnerSay("Command from pong source, set as allowed and reapply");
        g_lAllowedSources = [id] + g_lAllowedSources;
        Reapply(id);
        iWillPrompt = FALSE;
    };
//    llOwnerSay("relay:process "+msg);
    for (i=0; i<nc; ++i) {
        command = llList2String(commands,i);
        // rlv commands
        if (llGetSubString(command,0,0)=="@") {
            integer isVersionCheck = (llSubStringIndex(command, "@version")!=-1);
            // all @command except version checks are delayed while waiting for ask prompt
            if (!iWillPrompt || isVersionCheck) { 
                if(command == "@clear" || command == "@detach=y"){
                    Release(id, TRUE);
                    return;
                }
                RLV(command, id);
                llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+","+command+",ok");
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                string comtype = llList2String(subargs, 1);
                if (comtype == "n" || comtype == "add") AddRestriction(id, behav);
                if (comtype == "y" || comtype == "rem") RemRestriction(id, behav);
            }
            if (!isVersionCheck) {
                if (iWillPrompt) {
                    DoPrompt = iWillPrompt;
                } else {
                    if (llListFindList(g_lAllowedSources,[id]) == -1) g_lAllowedSources = [id] + g_lAllowedSources;
                }
            }
        }
        // relay meta commands
        else if (command=="!pong") { Reapply(id); }
        else if (command=="!version") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!version,1100");
        else if (command=="!implversion") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!implversion,ORG=805000/Satomi's Damn Fast Relay v4:OPENCOLLAR");
        else if (command=="!x-orgversions") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!x-orgversions,ORG=805000");
        else if (command=="!release") Release(id, TRUE);
        else llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+","+command+",ko");
    }

    if(DoPrompt){
        // New source pending for ask approval, do not prompt for disallowed sources
        if (llListFindList(g_lDisallowedSources,[id])==-1 && llListFindList(g_lPendingSourceList,[id])==-1) {
            g_lPendingSourceList=g_lPendingSourceList+[id];
            LSDWrite("ask_"+(string)id,msg);
            if (llGetListLength(g_lPendingSourceList)==1) {
                g_kObjectOwner = llList2Key(llGetObjectDetails(id, [OBJECT_OWNER]),0);
                llMessageLinked(LINK_SET, AUTH_REQUEST, "relay", g_kObjectOwner);
            }
//            llOwnerSay("new ask source: "+LSDRead("ask_"+(string)id));
        }
//        else llOwnerSay("Already in pending list, dropped!");
    }
}

HelplessChecks(){
    if(g_iWearer && g_iHelplessMode) {
        g_iHelplessMode=FALSE;
        llLinksetDataWrite("relay_helpless",(string)g_iHelplessMode);
    }
}

DoPending(){
    key kSource = llList2Key(g_lPendingSourceList,0);
    g_lPendingSourceList=llDeleteSubList(g_lPendingSourceList,0,0);
    g_lAllowedSources = [kSource]+g_lAllowedSources;
    string msg = LSDRead("ask_"+(string)kSource);
    LSDWrite("ask_"+(string)kSource,"");
    llOwnerSay("DoPending: "+msg);
    list messages = llParseString2List(msg,["||"],[]);
    integer ii = 0;
    integer iEnd = llGetListLength(messages);
    for(ii=0;ii<iEnd;ii++){
        Process(llList2String(messages,ii), kSource, FALSE);
    }
    // We have more pending ask sources
    if (llGetListLength(g_lPendingSourceList)>0) {
        kSource = llList2Key(g_lPendingSourceList,0);
        g_kObjectOwner = llList2Key(llGetObjectDetails(kSource, [OBJECT_OWNER]),0);
        llMessageLinked(LINK_SET, AUTH_REQUEST, "relay", g_kObjectOwner);
    }
}

DenyAskSource() {
    key kSource = llList2Key(g_lPendingSourceList,0);
    g_lPendingSourceList=llDeleteSubList(g_lPendingSourceList,0,0);
    g_lDisallowedSources=[kSource]+g_lDisallowedSources;
    LSDWrite("ask_"+(string)kSource,"");
    if (llGetListLength(g_lPendingSourceList)) PromptForSource(llList2Key(g_lPendingSourceList,0));
}

default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT){
            if(sStr == "reboot"){
                llResetScript();
            }
        } else if(iNum == READY){
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP){
            state active;
        }
    }
}
state active
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
        
        g_kForceSitter = (key)LSDRead("sitter");
        g_kSitTarget = (key)LSDRead("sittarget");
        g_iMode=(integer)llLinksetDataRead("relay_mode");
        g_iWearer=(integer)llLinksetDataRead("relay_wearer");                    
        g_iHelplessMode=(integer)llLinksetDataRead("relay_helpless");                    
        g_iTrustOwners=(integer)llLinksetDataRead("relay_trustowner");                    
        g_iTrustTrusted=(integer)llLinksetDataRead("relay_trusttrust");        
        HelplessChecks();

        RELAY_LISTENER = 0;

        integer i;
        list sources = llLinksetDataFindKeys(LSDPrefix+"_ask_.*", 0, 10);
        for (i=0; i< llGetListLength(sources); i++) {
            llLinksetDataWrite(llList2String(sources,i),"");
        }
        
    }

    on_rez(integer i) {
        llResetScript();
    }

    timer() {
        // non responding sources removed after 30s
        integer i = 0;
        for (i=0; i<llGetListLength(g_lPendingReapply); i++) {
//            llOwnerSay("no pong: "+LSDRead("source_"+llList2String(g_lPendingReapply,i))); 
            LSDWrite("source_"+llList2String(g_lPendingReapply,i),"");
        }
        g_lPendingReapply = [];
        llSetTimerEvent(0);
    }

    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if(iNum == CMD_EVERYONE && (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) ){
            //Test if this is a denied auth
            llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% to relay options", kID);
        }else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){

            //Test to see if this is a denied auth. If we're here and its denied, we respring. A CMD_* call is already sent out which will produce the NOTIFY
            //We're hard coding page 0 because new menu calls should always be page 0
            if(llSubStringIndex(sStr, g_sSubMenu + "|0|" + (string)CMD_EVERYONE) != -1) llMessageLinked(LINK_SET, CMD_ZERO, "menu "+g_sParentMenu, llGetSubString(sStr, 0, 35));

            integer iPos = llSubStringIndex(kID, "~"+llGetScriptName());
            if(iPos>0){
                string sMenu = llGetSubString(kID, 0, iPos-1);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRespring=TRUE;
                // do some sanity checks
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    if(kAv == g_kWearer && !g_iWearer){
                        llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% to relay options", kAv);
                        jump noaccess;
                    }
                    if(!(iAuth == CMD_OWNER || kAv == g_kWearer)) {
                        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to relay options", kAv);
                        jump noaccess;
                    }
                    if(sMsg == Checkbox(bool((g_iMode==0)), "OFF")){
                        if(g_iMode == 0){
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is already off", kAv);
                        }else{
                            g_iMode=0;
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay has been turned off", kAv);
                        }
                        g_lAllowedSources=[];
                        g_lDisallowedSources = [];
                        llLinksetDataWrite("relay_mode",(string)g_iMode);
                    } else if(sMsg == Checkbox(bool((g_iMode==MODE_ASK)),"Ask")){
                        if(g_iMode == MODE_ASK){
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is already set to ask", kAv);
                        } else {
                            g_iMode=MODE_ASK;
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay has been set to ask", kAv);
                        }
                        g_lAllowedSources=[];
                        g_lDisallowedSources=[];
                        llLinksetDataWrite("relay_mode",(string)g_iMode);
                    } else if(sMsg == Checkbox(bool((g_iMode==MODE_AUTO)), "Auto")){
                        if(g_iMode == MODE_AUTO){
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is already set to auto", kAv);
                        }else{
                            g_iMode=MODE_AUTO;
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is now set to auto", kAv);
                        }
                        g_lAllowedSources=[];
                        g_lDisallowedSources=[];
                        llLinksetDataWrite("relay_mode",(string)g_iMode);
                    } else if(sMsg == Checkbox(g_iWearer, "Wearer")){
                        g_iWearer=1-g_iWearer;
                        llLinksetDataWrite("relay_wearer",(string)g_iWearer);
                        if(g_iWearer)llMessageLinked(LINK_SET, NOTIFY, "0Wearer access now allowed", kAv);
                        else llMessageLinked(LINK_SET, NOTIFY, "0Wearer access now denied", kAv);
                    } else if(sMsg == Checkbox(g_iHelplessMode, "Helpless")){
                        g_iHelplessMode = 1-g_iHelplessMode;
                        llLinksetDataWrite("relay_helpless",(string)g_iHelplessMode);
                    } else if(sMsg == Checkbox(g_iTrustOwners, "Trust Owners")){
                        g_iTrustOwners=1-g_iTrustOwners;
                        llLinksetDataWrite("relay_trustowner",(string)g_iTrustOwners);
                    } else if(sMsg == Checkbox(g_iTrustTrusted, "Trust Trusted")){
                        g_iTrustTrusted=1-g_iTrustTrusted;
                        llLinksetDataWrite("relay_trusttrust",(string)g_iTrustTrusted);
                    }
                    @noaccess;
                    if(sMsg == "REFUSE" && (iAuth == CMD_OWNER || kAv == g_kWearer) && !g_iHelplessMode){
                        RelayClear();
                    }

                    if(iRespring)llMessageLinked(LINK_SET, 0, "menu Relay", kAv);
                    if(g_iHelplessMode)
                        HelplessChecks();
                } else if(sMenu == "AskPrompt"){
                    if(sMsg == "No"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Ignoring this relay request!", g_kWearer);
                        DenyAskSource();
                    } else {
                        DoPending();
                    }
                }
            }
        } else if(iNum == DIALOG_TIMEOUT){
            integer iPos = llSubStringIndex(kID, "~"+llGetScriptName());
            if(iPos>0){
                string sMenu = llGetSubString(kID, 0, iPos-1);
                if(sMenu == "AskPrompt"){
                    DenyAskSource();
                }
            }
        } else if(iNum == AUTH_REPLY){
            list lTmp = llParseString2List(sStr, ["|"],[]);
            key kAv = (key)llList2String(lTmp,1);
            integer iAuth=(integer)llList2String(lTmp,2);
            if(llList2String(lTmp,0) == "AuthReply"){
                // OK
                list lTmp2 = llParseString2List((string)kID, ["`"],[]);
                if(llList2String(lTmp2, 0)=="relay"){
                    if(g_iMode == MODE_ASK){
                        if((g_iTrustOwners && iAuth == CMD_OWNER) || (g_iTrustTrusted && iAuth==CMD_TRUSTED)){
                            DoPending();
                        } else {
                            //PromptForSource(kAv);
                            PromptForSource(llList2Key(g_lPendingSourceList,0));
                        }
                    }
                }
            }
        } else if (iNum == RLV_ON) {
            GetPendingReapplyList();
            // start listener for !pong
            integer i;
//            llOwnerSay("oc_relay:RLV ON start listener for ping/pong, mode is "+(string)g_iMode);
            if (g_iMode) {
                RELAY_LISTENER = llListen(RLV_RELAY_CHANNEL, "", NULL_KEY, "");
                for (i=0;i<llGetListLength(g_lPendingReapply);i++) {
                    // ping the sources
                    key kSource = llList2Key(g_lPendingReapply,i);
                    llRegionSayTo(kSource, RLV_RELAY_CHANNEL,"ping,"+(string)kSource+",ping,ping");
                    llOwnerSay("oc_relay:RLV ON ping,"+(string)kSource+",ping,ping");
                }
                // pong timer
                llSetTimerEvent(30);
            }
        } else if (iNum == RLV_OFF) {
            ReleaseAll(FALSE);
            llListenRemove(RELAY_LISTENER);
            RELAY_LISTENER = 0;
        } else if (iNum == RLV_REFRESH) {
//            llOwnerSay("oc_relay:RLV_REFRESH");
        } else if (iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            
            if(llList2String(lSettings,0)=="auth"){
                if(llList2String(lSettings,1)=="owner"){
                    g_iHasOwners=TRUE;
                    list lTmp = llParseString2List(llList2String(lSettings,2), [","],[]);
                    if(llGetListLength(lTmp)==1 && llList2Key(lTmp,0)==g_kWearer)g_iHasOwners=FALSE;
                    if(lTmp == [])g_iHasOwners=FALSE;
                }
            }
            if(sStr=="settings=sent"){
                if(!g_iWearer && !g_iHasOwners){
                    g_iWearer=TRUE;
                    llMessageLinked(LINK_SET,LM_SETTING_DELETE, "relay_wearer","");
                    llMessageLinked(LINK_SET, NOTIFY, "0Wearer access to relay enabled due to no owners or self owned and only owner is wearer", g_kWearer);
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="auth"){
                if(llList2String(lSettings,1)=="owner"){
                    if(!g_iWearer){
                        g_iWearer = 1;
                        llLinksetDataWrite("relay_wearer",(string)g_iWearer);
                    }
                    g_iHasOwners=FALSE;
                }
            }
        } else if(iNum == LSD_REQUEST){
            llMessageLinked(LINK_SET, LSD_RESPONSE, LSDPrefix,"");
        } else if(iNum == RLV_CLEAR){
            RelayClear();
        } else if(iNum == REBOOT){
            if(sStr=="reboot")
                llResetScript();
        }
    }

    listen(integer c, string w, key id, string msg) {
        integer iWillPrompt=FALSE;
        if(g_iMode==MODE_ASK){
            // Ignore disallowed sources
            if(llListFindList(g_lDisallowedSources, [id]) >= 0){
                return; 
            }
            // Command from an already pending ask source, save for later
            integer i = llListFindList(g_lPendingSourceList,[id]);
            if(i>-1){
                key kID = llList2Key(g_lPendingSourceList,i);
                LSDWrite("ask_"+(string)kID,LSDRead("source_"+(string)kID)+"||"+msg);
                return;
            }
            // Prompt if souce not allowed
            if(llListFindList(g_lAllowedSources, [id]) ==-1){
                iWillPrompt=TRUE;
            }
        }
        // Strip lists if too long
        if(llGetListLength(g_lAllowedSources)>10) g_lAllowedSources = llList2List(g_lAllowedSources,0,9);
        if(llGetListLength(g_lDisallowedSources)>10) g_lDisallowedSources = llList2List(g_lDisallowedSources,0,9);
        Process(msg, id, iWillPrompt); // Prompt is moved inside of PROCESS
    }
    
    linkset_data( integer action, string name, string value ){ 
//        llOwnerSay("LSD: "+name+"="+value); 
        if (name == "relay_mode") {
            g_iMode=(integer)value;
//            llOwnerSay("oc_relay:mode set "+(string)g_iMode);
            if(g_iMode==0){
                llListenRemove(RELAY_LISTENER);
                RELAY_LISTENER = 0;
            } else {
                if (RELAY_LISTENER == 0) RELAY_LISTENER = llListen(RLV_RELAY_CHANNEL, "", NULL_KEY, "");
            }
        }
    }
}
