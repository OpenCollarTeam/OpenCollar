/*
This file is a part of OpenCollar.
Copyright ©2020

: Contributors :

Aria (Tashia Redrose)
    *May 2020       -       Created new Integrated relay
    *July 2020      -       Finish integrated relay. Fix bug where the wearer could lock themselves out of the relay options
    
et al.

Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

string g_sParentMenu = "RLV";
string g_sSubMenu = "Relay";

key forcesitter;
key sitid;
integer RLV_RELAY_CHANNEL = -1812221819;
integer RELAY_LISTENER;
key Source;
list Restrictions;
integer g_iResit_status;


Release(){
        
    llRegionSayTo(Source, RLV_RELAY_CHANNEL, "release,"+(string)Source+",!release,ok");
        
    integer i=0;
    integer end=llGetListLength(Restrictions);
    for(i=0;i<end;i++){
        // Release restrictions!
        string stripped = "@clear="+llList2String(Restrictions,i);//llGetSubString(llList2String(Restrictions,i),0,llSubStringIndex(llList2String(Restrictions,i), "=")-1);
        llOwnerSay(stripped);
    }
    Source=NULL_KEY;
    Restrictions=[];
    g_lAllowedSources=[];
    g_kPendingSource=NULL_KEY;
    g_lPendingRLV=[];
    
    llMessageLinked(LINK_SET, DO_RLV_REFRESH, "", "");
}
        
//MESSAGE MAP
integer RLV_CLEAR=6002;
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 51200;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer AUTH_REQUEST = 600;
integer AUTH_REPLY=601;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer DO_RLV_REFRESH = 26001;//RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
string ALL = "ALL";
integer g_iMode = 0;

integer MODE_ASK=1;
integer MODE_AUTO = 2;

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["▢", "▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

integer g_iWearer=TRUE; // Lockout wearer option
integer g_iTrustOwners = FALSE;
integer g_iTrustTrusted = FALSE;
Menu(key kID, integer iAuth) {
    if(iAuth == CMD_OWNER && kID==g_kWearer && !g_iHasOwners){
        if(!g_iWearer){
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_wearer=1","");
        }
        g_iWearer=TRUE;
        HelplessChecks();
    }
    string sPrompt = "\n[Relay App]\n\nNote: Wearer checkbox will allow or disallow wearer changes to relay\n\n";
    list lButtons = [Checkbox(bool((g_iMode==0)), "OFF"), Checkbox(bool((g_iMode==MODE_ASK)),"Ask"), Checkbox(bool((g_iMode==MODE_AUTO)),"Auto"), Checkbox(g_iWearer, "Wearer")];
    if(Source){
        sPrompt += "Source: "+llKey2Name(Source);
        lButtons+=["REFUSE"];
        sPrompt+="\n\nREFUSE -> Will safeword the relay only";
    } else {
        sPrompt += "Source: NONE";
    }
    
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
        g_lOwner = g_lTrust = g_lBlock = [];
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_wearer=1","");
        return;
    }
    if (sStr==llToLower(g_sSubMenu) || sStr == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llToLower(llList2String(llParseString2List(sStr, [" "], []),1));
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),2);
        string sText;
        if(sChangetype == "refuse" && !g_iWearer && iNum==CMD_WEARER && !g_iHelplessMode){
            llMessageLinked(LINK_SET, CMD_RELAY_SAFEWORD, "","");
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
                if(g_kPendingSource==NULL_KEY){
                    llMessageLinked(LINK_SET, NOTIFY, "0No pending source", kID);
                    return;
                }else {
                    RepromptForSource(g_kPendingSource);
//                    PromptForSource(g_kPendingSource, g_sPendingRLV);
                }
            }
            else if(sChangetype == "refuse" ) llMessageLinked(LINK_SET,CMD_RELAY_SAFEWORD,"","");
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
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_helpless="+(string)g_iHelplessMode, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_wearer="+(string)g_iWearer, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_mode="+(string)g_iMode, "");
        }
    }
}
string tf(integer a){
    if(a)return "true";
    else return "false";
}
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;

integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

list g_lSettingsReqs = [];

list g_lAllowedSources=[];
list g_lDisallowedSources=[];
key g_kPendingSource;
list g_lPendingRLV;
key g_kObjectOwner;

PromptForSource(key kID, string sPendingCommand){
    g_lPendingRLV = [sPendingCommand];
    g_kObjectOwner = kID;
    Dialog(llGetOwner(), "[Relay]\n\nObject Name: "+llKey2Name(g_kPendingSource)+"\nObject ID: "+(string)g_kPendingSource+"\nObject Owner: secondlife:///app/agent/"+(string)kID+"/about\n\nIs requesting to use your RLV Relay, do you want to allow it?", ["Yes", "No"], [], 0, CMD_WEARER, "AskPrompt");
}
RepromptForSource(key kID){
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
        for (i=0; i<nc; ++i) {
            command = llList2String(commands,i);
            if (llGetSubString(command,0,0)=="@") {
                if(llSubStringIndex(command, "@version")!=-1){
                    jump overPromptChecks;
                }
                if(iWillPrompt)DoPrompt=TRUE;
                if(iWillPrompt)jump skipSection;
                @overPromptChecks;
                if(command == "@clear" || command == "@detach=y"){
                    Release();
                    return;
                }
                llOwnerSay(command);
                llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+","+command+",ok");
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                integer index = llListFindList(Restrictions, [behav]);
                string comtype = llList2String(subargs, 1);                
                if (index == -1 && (comtype == "n" || comtype == "add")) {
                    Restrictions += [behav];
                    llOwnerSay("@detach=n");
                    Source = id;
                    if (behav == "unsit" && llGetAgentInfo(g_kWearer) & AGENT_SITTING) {
                        sitid = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
                        forcesitter = id;
                    }
                }
                else if (index != -1 && (comtype=="y" || comtype == "rem")) {
                    Restrictions = llDeleteSubList(Restrictions, index, index);
                    if (Restrictions == []) {
                        Source = NULL_KEY;
                        llMessageLinked(LINK_SET, DO_RLV_REFRESH, "","");
                    }
                    if (behav == "unsit") sitid = NULL_KEY;
                }
                @skipSection;
            }
            else if (command=="!pong" && id == forcesitter && sitid != NULL_KEY) g_iResit_status = 1;
            else if (command=="!version") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!version,1100");
            else if (command=="!implversion") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!implversion,ORG=0003/Satomi's Damn Fast Relay v4:OPENCOLLAR");
            else if (command=="!x-orgversions") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!x-orgversions,ORG=0003");
            else if (command=="!release" && id == Source) Release();
            else llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+","+command+",ko");           
        }
        
        if(DoPrompt){
            // Calculate authorization first
            g_kPendingSource=id;
            llMessageLinked(LINK_SET, AUTH_REQUEST,  "relay`"+msg, llList2Key(llGetObjectDetails(id, [OBJECT_OWNER]),0));
            //PromptForSource(id,msg);
        }
}
integer g_iHelplessMode=FALSE;
HelplessChecks(){
    if(g_iWearer && g_iHelplessMode) {
        g_iHelplessMode=FALSE;
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_helpless=0", "");
    }
}

integer g_iHasOwners=FALSE;

DoPending(){
    g_lAllowedSources = [g_kPendingSource]+g_lAllowedSources;
    integer ii = 0;
    integer iEnd = llGetListLength(g_lPendingRLV);
    for(ii=0;ii<iEnd;ii++){
        Process(llList2String(g_lPendingRLV,ii), g_kPendingSource, FALSE);
    }
    g_lPendingRLV=[];
    g_kPendingSource=NULL_KEY;
}
default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
    }
    on_rez(integer i) {
        if(llGetOwner()!=g_kWearer) llResetScript();
        if (Source) {
            llOwnerSay("@detach=n"); // no escaping before we are sure the former source really is not active anymore
            g_iResit_status = 0;
            llSetTimerEvent(30);
            llRegionSayTo(Source, RLV_RELAY_CHANNEL, "ping,"+(string)Source+",ping,ping");
            
        }
    }
    
    timer() {
        if (g_iResit_status == 1) {
            g_iResit_status = 2;
            llSetTimerEvent(15);
            llOwnerSay("@sit:"+(string)sitid+"=force");
        } else if (g_iResit_status == 2) {
            llSetTimerEvent(0);
            llOwnerSay("@"+llDumpList2String(Restrictions, "=n,")+"=n");
        } else Release(); // The source is no longer active. Let's forget everything.
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
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
                    if(!(iAuth == CMD_OWNER || iAuth == CMD_WEARER)) {
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
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_mode="+(string)g_iMode, "");
                    } else if(sMsg == Checkbox(bool((g_iMode==MODE_ASK)),"Ask")){
                        if(g_iMode == MODE_ASK){
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is already set to ask", kAv);
                        } else {
                            g_iMode=MODE_ASK;
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay has been set to ask", kAv);
                        }
                        
                        g_lAllowedSources=[];
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_mode="+(string)g_iMode, "");
                    } else if(sMsg == Checkbox(bool((g_iMode==MODE_AUTO)), "Auto")){
                        if(g_iMode == MODE_AUTO){
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is already set to auto", kAv);
                        }else{
                            g_iMode=MODE_AUTO;
                            llMessageLinked(LINK_SET, NOTIFY, "0The relay is now set to auto", kAv);
                        }
                        
                        
                        g_lAllowedSources=[];
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_mode="+(string)g_iMode, "");
                    } else if(sMsg == Checkbox(g_iWearer, "Wearer")){
                        g_iWearer=1-g_iWearer;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_wearer="+(string)g_iWearer, "");
                        if(g_iWearer)llMessageLinked(LINK_SET, NOTIFY, "0Wearer access now allowed", kAv);
                        else llMessageLinked(LINK_SET, NOTIFY, "0Wearer access now denied", kAv);
                    } else if(sMsg == Checkbox(g_iHelplessMode, "Helpless")){
                        g_iHelplessMode = 1-g_iHelplessMode;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_helpless="+(string)g_iHelplessMode,"");
                    } else if(sMsg == Checkbox(g_iTrustOwners, "Trust Owners")){
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_trustowner="+(string)((g_iTrustOwners=1-g_iTrustOwners)), "");
                    } else if(sMsg == Checkbox(g_iTrustTrusted, "Trust Trusted")){
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_trusttrust="+(string)((g_iTrustTrusted=1-g_iTrustTrusted)),"");
                    }
                    @noaccess;
                    if(sMsg == "REFUSE" && (iAuth == CMD_OWNER || iAuth==CMD_WEARER) && !g_iHelplessMode){
                        llMessageLinked(LINK_SET, CMD_RELAY_SAFEWORD, "safeword", "");
                    }
                    
                    if(iRespring)llMessageLinked(LINK_SET, 0, "menu Relay", kAv);
                    if(g_iHelplessMode)
                        HelplessChecks();
                } else if(sMenu == "AskPrompt"){
                    if(sMsg == "No"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Ignoring this relay request!", g_kWearer);
                        g_lDisallowedSources=[g_kPendingSource]+g_lDisallowedSources;
                        g_lPendingRLV=[];
                        g_kPendingSource=NULL_KEY;
                    } else {
                        DoPending();
                    }
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
                            PromptForSource(kAv, kID);
                        }
                    }
                }
            }
        }else if(iNum == TIMEOUT_READY)
        {
            g_lSettingsReqs = ["global_locked", "relay_mode", "relay_wearer", "relay_helpless", "relay_trustowner", "relay_trusttrust", "auth_owner"];
            llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "2", "relay~settings");
        } else if(iNum == TIMEOUT_FIRED)
        {
            if(llGetListLength(g_lSettingsReqs)>0){
                llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "1", "relay~settings");
                llMessageLinked(LINK_SET, LM_SETTING_REQUEST, llList2String(g_lSettingsReqs,0),"");
            }
        
        }else if(iNum == LM_SETTING_EMPTY){
            
            integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if(iNum == LM_SETTING_DELETE){
            
            integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            
            
            integer ind = llListFindList(g_lSettingsReqs, [llList2String(lSettings,0)+"_"+llList2String(lSettings,1)]);
            if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                }
            } else if(llList2String(lSettings,0) == "relay"){
                if(llList2String(lSettings,1) == "mode"){
                    g_iMode=llList2Integer(lSettings,2);
                    
                    if(g_iMode==0){
                        llListenRemove(RELAY_LISTENER);
                        Release();
                    } else {
                        RELAY_LISTENER = llListen(RLV_RELAY_CHANNEL, "", NULL_KEY, "");
                    }
                } else if(llList2String(lSettings,1) == "wearer"){
                    g_iWearer=(integer)llList2String(lSettings,2);
                } else if(llList2String(lSettings,1) == "helpless"){
                    g_iHelplessMode = (integer)llList2String(lSettings,2);
                    // Perform sanity check on helpless mode
                    HelplessChecks();
                } else if(llList2String(lSettings,1) == "trustowner"){
                    g_iTrustOwners = (integer)llList2String(lSettings,2);
                } else if(llList2String(lSettings,1) == "trusttrust"){
                    g_iTrustTrusted=(integer)llList2String(lSettings,2);
                }
            } else if(llList2String(lSettings,0)=="auth"){
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
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1) == "locked") g_iLocked=FALSE;
            } else if(llList2String(lSettings,0)=="auth"){
                if(llList2String(lSettings,1)=="owner"){
                    if(!g_iWearer){
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "relay_wearer=1","");
                    }
                    g_iHasOwners=FALSE;
                }
            }
        } else if(iNum == CMD_SAFEWORD){
            // Process safeword
            llMessageLinked(LINK_SET, CMD_RELAY_SAFEWORD, "safeword", "");
        } else if(iNum == RLV_CLEAR){
            llMessageLinked(LINK_SET, CMD_RELAY_SAFEWORD, "","");
        } else if(iNum == CMD_RELAY_SAFEWORD){
            if(g_iHelplessMode)return;
            Release();
            integer iOldMode=g_iMode;
            g_iMode=0;
            if(!g_iLocked)llOwnerSay("@detach=y");
            llMessageLinked(LINK_SET, NOTIFY,"0Relay temporarily disabled due to safeword or clear all. The relay will reactivate in 30 seconds", g_kWearer);
            llSleep(30);
            g_iMode=iOldMode;
            llMessageLinked(LINK_SET,NOTIFY, "0Relay has been reactivated",g_kWearer);
        } else if(iNum == REBOOT){
            if(Source=="" || Source==NULL_KEY)
                llResetScript();
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
    
    listen(integer c, string w, key id, string msg) {
        if (Source) { if (Source != id) return; } // already grabbed by another device
        integer iWillPrompt=FALSE;
        if(g_iMode==MODE_ASK){
            if(g_kPendingSource == id){
                if(llGetListLength(g_lPendingRLV)<11)
                    g_lPendingRLV+=msg;
                return;
            }
            
            if(llListFindList(g_lAllowedSources, [id]) ==-1){
                iWillPrompt=TRUE;
            }
            
            
        }
        
        // Strip lists if too long
        if(llGetListLength(g_lAllowedSources)>5)g_lAllowedSources = llList2List(g_lAllowedSources,0,4);
        if(llGetListLength(g_lDisallowedSources)>5)g_lDisallowedSources = llList2List(g_lDisallowedSources,0,4);
        Process(msg,id, iWillPrompt); // Prompt is moved inside of PROCESS
    }
}
