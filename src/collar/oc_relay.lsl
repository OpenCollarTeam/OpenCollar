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
   *Oct 2025   - init() function for rez state, factory clean on CHANGE_OWNER
                 reducing memory use to handle large relay messages
                 only default state, remove RLV function (just a wrapper to linkmessage RLV_CMD)

et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

string g_sScriptVersion = "8.4";

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

//integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

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

key g_kForceSitSource;       //  LSD relay_sitter = UUID
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

list g_lCheckboxes=["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    if (iValue) return llList2String(g_lCheckboxes, 1)+" "+sLabel;
    else return llList2String(g_lCheckboxes, 0)+" "+sLabel;
}

HelplessChecks(){
    if(g_iWearer && g_iHelplessMode) {
        g_iHelplessMode=FALSE;
        llLinksetDataWrite("relay_helpless",(string)g_iHelplessMode);
    }
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
    list lButtons = [Checkbox((g_iMode==0), "OFF"), Checkbox((g_iMode==MODE_ASK),"Ask"), Checkbox((g_iMode==MODE_AUTO),"Auto"), Checkbox(g_iWearer, "Wearer")];
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
            else if(sChangetype == "helpless")sReply += "helpless toggled to "+llList2String(["off","on"],g_iHelplessMode);
            else if(sChangetype == "wearer")sReply += "wearer access toggled to "+llList2String(["off","on"],g_iWearer);
            else if(sChangetype == "pending")sReply += "pending ask source dialog reopened";
            else sReply += "mode set to "+sChangetype;
            llMessageLinked(LINK_SET, NOTIFY, "0"+sReply, kID);

            // Save data
            llLinksetDataWrite("relay_helpless",(string)g_iHelplessMode);
            llLinksetDataWrite("relay_wearer",(string)g_iWearer);
            llLinksetDataWrite("relay_mode",(string)g_iMode);
        }
    }
}

/*
RLV(string cmd, key kID)
{
    // send the rlv command to oc_rlvsys
    llMessageLinked(LINK_THIS, RLV_CMD,
        llGetSubString(cmd,1,999),  // knock off the "@"
        kID);
    // Use the source UUID, so oc_relay can then handle multiple relay objects
    // and let oc_rlvsys handle/abritrate/manage multiple sources.
}
*/

Reapply(key kSourceId) {
    integer ix = llListFindList(g_lPendingReapply,[kSourceId]);
    // Only reapply sources in g_lPendingReapply list
    if (ix >= 0) {
//        llOwnerSay("Pong and reapply: "+(string)kSourceId);
        // read restictions from LSD and apply them
        list lRestr=llParseString2List(LSDRead("source_"+(string)kSourceId),["§"],[]);
        integer iRestr = 0;
        for (iRestr = 0;iRestr < llGetListLength(lRestr); iRestr++) {
            string sBehav = llList2String(lRestr,iRestr);
            // resit if unsit is restricted
            if( sBehav == "unsit" && g_kSitTarget != NULL_KEY ) {
                g_kForceSitSource = kSourceId;
                llMessageLinked(LINK_THIS, RLV_CMD,"sit:"+(string)g_kSitTarget+"=force",kSourceId);
//                RLV("@sit:"+(string)g_kSitTarget+"=force", kSourceId);
                llMessageLinked(LINK_SET,TIMEOUT_REGISTER, "15", "force_resit:"+(string)g_kSitTarget);
//                llOwnerSay("TIMEOUT_REGISTERED");
            }
            llMessageLinked(LINK_THIS, RLV_CMD, sBehav+"=add",kSourceId);
//            RLV("@"+sBehav+"=add", kSourceId);
//            AddRestriction(kSourceId, sBehav);
        }
        g_lPendingReapply = llDeleteSubList(g_lPendingReapply,ix,ix);
    }
    else {
        //llOwnerSay("Pong not found");    
    }
}

ReleaseAll(integer iClearLSD){
    integer i;
    list sources = llLinksetDataFindKeys(LSDPrefix+"_source_.*", 0, 20);
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
    llMessageLinked(LINK_THIS, RLV_CMD, "clear",kID);
//    RLV("@clear", kID);
    /* Check sit stautus after clearing unsit */
    if (llSubStringIndex(LSDRead("source_"+(string)kID),"unsit")>-1) llMessageLinked(LINK_SET,TIMEOUT_REGISTER, "5", "check_sit");
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
        if (llGetListLength(llLinksetDataFindKeys(LSDPrefix+"_source_.*", 0, 20)) > 14) {
            llOwnerSay("Capping number of RLV sources, dropping: "+(string)kID);
            return;
        }
        else {
            sSrcRestr = "§";
        }
    }
    if (llSubStringIndex(sSrcRestr,"§"+sBehav+"§") == -1) {
        //Debug("AddRestriction 2.2");
        sSrcRestr+=sBehav+"§";
        if (sBehav=="unsit") {
            llMessageLinked(LINK_SET,TIMEOUT_REGISTER, "5", "check_sit");
        }
    }
    LSDWrite("source_"+(string)kID,sSrcRestr);
}

RemRestriction(key kID, string sBehav) {
    // read restrictions for this source, if any
    string sSrcRestr = LSDRead("source_"+(string)kID);
    if (sSrcRestr) { //if this source set has any restrictions
        sSrcRestr = llReplaceSubString(sSrcRestr,"§"+sBehav+"§","§",1);
        LSDWrite("source_"+(string)kID,sSrcRestr);
    
        if (sBehav=="unsit") {
                  llMessageLinked(LINK_SET,TIMEOUT_REGISTER, "5", "check_sit");
        }
    }
}

RelayClear() {
    if(g_iHelplessMode)return;
    ReleaseAll(TRUE);
    g_lAllowedSources = [];
//    integer iOldMode=g_iMode; Changing mode while sleep is meaningless 
//    g_iMode=0;
    llMessageLinked(LINK_SET, NOTIFY,"0Relay temporarily suppressed for 30 seconds due to safeword or clear all.", g_kWearer);
    llSleep(30);
//    g_iMode=iOldMode;
    llMessageLinked(LINK_SET,NOTIFY, "0 Relay settings have been restored.",g_kWearer); 
}

///param id=source
///param msg=RLV command
Process(string msg, key id, integer iWillPrompt){
    integer DoPrompt=FALSE;
    // we know from listen that message has 3 comma sparated parts
    list commands = llParseStringKeepNulls(msg,[",","|"],[]);
    string identid = llList2String(commands,0)+","+(string)id;
    integer i;
    string command;
    integer nc = llGetListLength(commands);
//    llOwnerSay("relay:process "+(string)llList2List(commands,0,2));
    for (i=2; i<nc; ++i) {
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
                llMessageLinked(LINK_THIS, RLV_CMD, llGetSubString(command,1,-1),id);
//                RLV(command, id);
                llRegionSayTo(id, RLV_RELAY_CHANNEL, identid+","+command+",ok");
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                string comtype = llList2String(subargs, 1);
                if (comtype == "n" || comtype == "add") AddRestriction(id, behav);
                if (comtype == "y" || comtype == "rem") RemRestriction(id, behav);
                /* force sit:UUID or unsit, register check if seated after 5 seconds */
                if (comtype == "force" && (llGetSubString(behav,0,3) == "sit:" || llGetSubString(behav,0,4) == "unsit" )) {
                    llMessageLinked(LINK_SET,TIMEOUT_REGISTER, "5", "check_sit");
                }
            } 
            else DoPrompt = TRUE; // We just skipped a rlv @command, dopromt before returning !
        }
        // relay meta commands
        else if (command=="!pong") { Reapply(id); }
        else if (command=="!version") llRegionSayTo(id, RLV_RELAY_CHANNEL, identid+",!version,1100");
        else if (command=="!implversion") llRegionSayTo(id, RLV_RELAY_CHANNEL, identid+",!implversion,ORG=805000/Satomi's Damn Fast Relay v4:OPENCOLLAR");
        else if (command=="!x-orgversions") llRegionSayTo(id, RLV_RELAY_CHANNEL, identid+",!x-orgversions,ORG=805000");
        else if (command=="!release") Release(id, TRUE);
        else llRegionSayTo(id, RLV_RELAY_CHANNEL, identid+","+command+",ko");
    }

    if(DoPrompt){
        // New source pending for ask approval, do not prompt for disallowed sources or sources already pending approval
/*   Already checked in listen handler
        if (llListFindList(g_lDisallowedSources,[id])>-1) {
            llOwnerSay("Trying to ask add a disallowed source - Shouldnt happen");
            return;
        }

        if (llListFindList(g_lPendingSourceList,[id])>-1) {
            llOwnerSay("Trying to ask add an already pending source - Shouldnt happen");
            return;        
        }
*/
        g_lPendingSourceList=g_lPendingSourceList+[id];
        LSDWrite("ask_"+(string)id,msg);
        /* Start the ask sorce checking if this is first source */
        if (llGetListLength(g_lPendingSourceList)==1) {
            CheckAskSource();
        }
    }
}

// Check if we have more pending ask sources
CheckAskSource(){
    if (llGetListLength(g_lPendingSourceList) == 0) return;    
    key kSource = llList2Key(g_lPendingSourceList,0);
    if (g_iTrustOwners || g_iTrustTrusted) {
        g_kObjectOwner = llList2Key(llGetObjectDetails(kSource, [OBJECT_OWNER]),0);
        llMessageLinked(LINK_SET, AUTH_REQUEST, "relay", g_kObjectOwner);
    } else {
        PromptForSource(kSource);
    }
}

PromptForSource(key kID){    
    Dialog(llGetOwner(), "[Relay]\n\nObject Name: "+llKey2Name(kID)+"\nObject ID: "+(string)kID+"\nObject Owner: secondlife:///app/agent/"+(string)g_kObjectOwner+"/about\n\nIs requesting to use your RLV Relay, do you want to allow it?", ["Yes", "No"], [], 0, CMD_WEARER, "AskPrompt");
    llSetTimerEvent(60);
}

/* Process the stored commands from the first pending ask source, and set it to allowed */
DoPending(){
    key kSource = llList2Key(g_lPendingSourceList,0);
    g_lPendingSourceList=llDeleteSubList(g_lPendingSourceList,0,0);
    g_lAllowedSources = [kSource]+g_lAllowedSources;
    string msg = LSDRead("ask_"+(string)kSource);
    LSDWrite("ask_"+(string)kSource,"");
    integer ii = llSubStringIndex(msg,"||");
    while (ii>-1) {
        Process(llGetSubString(msg, 0, ii-1), kSource, FALSE);
        msg = llGetSubString(msg, ii+2, -1);
        ii = llSubStringIndex(msg,"||");
    }
    Process(msg, kSource, FALSE);
    
    // Check if we have more pending ask sources
    CheckAskSource();
}

DenyAskSource(integer verbose) {
    key kSource = llList2Key(g_lPendingSourceList,0);
    g_lPendingSourceList=llDeleteSubList(g_lPendingSourceList,0,0);
    g_lDisallowedSources=[kSource]+g_lDisallowedSources;
    LSDWrite("ask_"+(string)kSource,"");
    if (verbose) llMessageLinked(LINK_SET, NOTIFY, "0Denying this relay source: "+llKey2Name(kSource), g_kWearer);
    // Check we have more pending ask sources
    CheckAskSource();
}

/* Check if wearer is sitting and save to LSD */
CheckSitTarget() {
    g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
    if (g_kSitTarget == g_kWearer) g_kSitTarget = NULL_KEY; 
    LSDWrite("sittarget", (string)g_kSitTarget);                            
}

// Starup code, called instead of reset on rez
// Normal behavor on rez is to simply call init()
// pending sources are cleared, allowed and disallowed lists are kept

init() {
    g_kWearer = llGetOwner();
    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
        
    g_kSitTarget = (key)LSDRead("sittarget");
    g_iMode=(integer)llLinksetDataRead("relay_mode");
    g_iWearer=(integer)llLinksetDataRead("relay_wearer");                    
    g_iHelplessMode=(integer)llLinksetDataRead("relay_helpless");                    
    g_iTrustOwners=(integer)llLinksetDataRead("relay_trustowner");                    
    g_iTrustTrusted=(integer)llLinksetDataRead("relay_trusttrust");        
    HelplessChecks();

    // simulate a state change/reset
    llListenRemove(RELAY_LISTENER);
    llSetTimerEvent(0);
    RELAY_LISTENER = 0;

    g_lPendingSourceList = [];
    llLinksetDataDeleteFound("^relay_ask_",""); 
}

/*
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

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llLinksetDataDeleteFound("^relay_",""); 
            llResetScript();
        }
    }

}


state active
*/

default
{
    state_entry()
    {
        init();
    }

    on_rez(integer i) {
        init();
    }

    timer() {
        // non responding sources removed after 30s
        if (llGetListLength(g_lPendingReapply)>0) {
            integer i = 0;
            for (i=0; i<llGetListLength(g_lPendingReapply); i++) {
//            llOwnerSay("no pong: "+LSDRead("source_"+llList2String(g_lPendingReapply,i))); 
                LSDWrite("source_"+llList2String(g_lPendingReapply,i),"");
            }
            g_lPendingReapply = [];
            return;
        }
        else if (llGetListLength(g_lPendingSourceList)>0) {
//            llOwnerSay("Timeout waiting for source approval");
            DenyAskSource(1);
            return;
        }
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
                    if(sMsg == Checkbox((g_iMode==0), "OFF")){
                        if(g_iMode == 0){
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is already off", kAv);
                        }else{
                            g_iMode=0;
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay has been turned off", kAv);
                        }
                        g_lAllowedSources=[];
                        g_lDisallowedSources = [];
                        llLinksetDataWrite("relay_mode",(string)g_iMode);
                    } else if(sMsg == Checkbox((g_iMode==MODE_ASK),"Ask")){
                        if(g_iMode == MODE_ASK){
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is already set to ask", kAv);
                        } else {
                            g_iMode=MODE_ASK;
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay has been set to ask", kAv);
                        }
                        g_lAllowedSources=[];
                        g_lDisallowedSources=[];
                        llLinksetDataWrite("relay_mode",(string)g_iMode);
                    } else if(sMsg == Checkbox((g_iMode==MODE_AUTO), "Auto")){
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
                        DenyAskSource(1);
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
                    DenyAskSource(1);
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
            // read list of previous sources to ping for reapply
            g_lPendingReapply = [];
            integer i;
            list sources = llLinksetDataFindKeys(LSDPrefix+"_source_.*", 0, 20);
            for (i=0; i< llGetListLength(sources); i++) {
                list data = llParseString2List(llList2String(sources,i),["_"],[""]);
                key kID = llList2Key(data, 2);
                g_lPendingReapply += [kID];  
            }
            // start listener for !pong
//            llOwnerSay("oc_relay:RLV ON start listener for ping/pong, mode is "+(string)g_iMode);
            if (g_iMode) {
                RELAY_LISTENER = llListen(RLV_RELAY_CHANNEL, "", NULL_KEY, "");
                for (i=0;i<llGetListLength(g_lPendingReapply);i++) {
                    // ping the sources
                    key kSource = llList2Key(g_lPendingReapply,i);
                    llRegionSayTo(kSource, RLV_RELAY_CHANNEL,"ping,"+(string)kSource+",ping,ping");
//                    llOwnerSay("oc_relay:RLV ON ping,"+(string)kSource+",ping,ping");
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
            string sToken = llList2String(lSettings, 0);
            string sVar = llList2String(lSettings,1);
            string sValue = llList2String(lSettings, 2);

            // Transfer relay settings to LSD
            if(sToken == "relay"){
                if(sVar == "mode") {
                    g_iMode=(integer)sValue;
                    llLinksetDataWrite("relay_mode",sValue);
                    llMessageLinked(LINK_SET,LM_SETTING_DELETE, "relay_mode","");
                } else if(sVar == "wearer"){
                    g_iWearer=(integer)sValue;
                    llLinksetDataWrite("relay_wearer",sValue);
                    llMessageLinked(LINK_SET,LM_SETTING_DELETE, "relay_wearer","");
                } else if(sVar == "helpless"){
                    g_iHelplessMode = (integer)sValue;
                    llLinksetDataWrite("relay_helpless",sValue);
                    llMessageLinked(LINK_SET,LM_SETTING_DELETE, "relay_helpless","");
                } else if(sVar == "trustowner"){
                    g_iTrustOwners = (integer)sValue;
                    llLinksetDataWrite("relay_trustowner",sValue);
                    llMessageLinked(LINK_SET,LM_SETTING_DELETE, "relay_trustowner","");
                } else if(sVar == "trusttrust"){
                    g_iTrustTrusted=(integer)sValue;
                    llLinksetDataWrite("relay_trustrust",sValue);
                    llMessageLinked(LINK_SET,LM_SETTING_DELETE, "relay_trusttrust","");
                }
            }          
            else if(sToken=="auth"){
                if(sVar=="owner"){
                    g_iHasOwners=TRUE;
                    list lTmp = llParseString2List(sValue, [","],[]);
                    if(llGetListLength(lTmp)==1 && llList2Key(lTmp,0)==g_kWearer)g_iHasOwners=FALSE;
                    if(lTmp == [])g_iHasOwners=FALSE;
                }
            }
            if(sStr=="settings=sent"){
                if(!g_iWearer && !g_iHasOwners){
                    g_iWearer=TRUE;
                    llLinksetDataWrite("relay_wearer","1");
                    llMessageLinked(LINK_SET, NOTIFY, "0Wearer access to relay enabled due to no owners or self owned and only owner is wearer", g_kWearer);
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="auth"){
                if(llList2String(lSettings,1)=="owner"){
                    g_iWearer = 1;
                    g_iHasOwners=FALSE;
                    llLinksetDataWrite("relay_wearer",(string)g_iWearer);
                }
            }
        } else if(iNum == TIMEOUT_FIRED){
            list lTmp = llParseString2List(sStr, [":"],[]);
//            llOwnerSay("TIMEOUT_FIRED");
            if(llList2String(lTmp,0) == "force_resit") {
                /* Check if not sitting */
                if (llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0) == g_kWearer) {
                    key ident = (key)llList2String(lTmp,1);
                    if (ident == g_kSitTarget ) llMessageLinked(LINK_THIS, RLV_CMD,"sit:"+(string)g_kSitTarget+"=force", g_kForceSitSource);
//RLV("@sit:"+(string)g_kSitTarget+"=force", g_kForceSitSource);
                }
            }
            else if(llList2String(lTmp,0) == "check_sit") {
                /* Check if sitting and set g_kSitTarget */
                CheckSitTarget();
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

        /* Check msg format and recipient */
        list args = llParseStringKeepNulls(msg,[","],[]);
        if (llGetListLength(args)!=3) return;
        if (llList2Key(args,1)!=g_kWearer && llList2Key(args, 1)!=(key)"ffffffff-ffff-ffff-ffff-ffffffffffff") return;
        args = [];
        // Any command from a ping object will reapply restrictions
        if (llListFindList(g_lPendingReapply,[id]) >= 0)  {
//        llOwnerSay("Command from pong source, set as allowed and reapply");
            g_lAllowedSources = [id] + g_lAllowedSources;
            Reapply(id);
        };
        /* Ask mode */
        if(g_iMode==MODE_ASK){
            // Ignore disallowed sources
            if(llListFindList(g_lDisallowedSources, [id]) >= 0){
                return; 
            }
            // Command from an already pending ask source, save for later
            integer i = llListFindList(g_lPendingSourceList,[id]);
            if(i>-1){
                key kID = llList2Key(g_lPendingSourceList,i);
                // Silently drop overlong ask requests
                if (llStringLength(LSDRead("ask_"+(string)kID))+llStringLength(msg) < 1000) {
                    LSDWrite("ask_"+(string)kID,LSDRead("ask_"+(string)kID)+"||"+msg);
                }
                return;
            }
            // Prompt if souce not allowed
            if(llListFindList(g_lAllowedSources, [id]) ==-1){
                iWillPrompt=TRUE;
            }
        }

        // Strip lists if too long
        if(llGetListLength(g_lAllowedSources)>15) g_lAllowedSources = llList2List(g_lAllowedSources,0,14);
        if(llGetListLength(g_lDisallowedSources)>15) g_lDisallowedSources = llList2List(g_lDisallowedSources,0,14);
//llScriptProfiler( PROFILE_SCRIPT_MEMORY );
        Process(msg, id, iWillPrompt); // Prompt is moved inside of PROCESS
//llScriptProfiler( PROFILE_NONE );
       // display memory usage...
//llOwnerSay("\nMemory used: " + (string)llGetSPMaxMemory() + " bytes, total memory: " + (string)llGetMemoryLimit() + " bytes." +(string)llStringLength(msg));
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

    changed(integer change)
    {
        if(change & CHANGED_OWNER)
        {
            llLinksetDataDeleteFound("^relay_",""); 
            llResetScript();
        }
    }

}
