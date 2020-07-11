/*
This file is a part of OpenCollar.
Copyright ©2020

: Contributors :

Aria (Tashia Redrose)
    *May 2020       -       Created new Integrated relay
    *July 2020      -       Finish integrated relay
    
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
}
        
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

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

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

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
list g_lCheckboxes=["⬜","⬛"];
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

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Relay App]\n\n";
    if(Source){
        sPrompt += "Source: "+llKey2Name(Source);
    } else {
        sPrompt += "Source: NONE";
    }
    list lButtons = [Checkbox(bool((g_iMode==0)), "OFF"), Checkbox(bool((g_iMode==MODE_ASK)),"Ask"), Checkbox(bool((g_iMode==MODE_AUTO)),"Auto"), "Safeword"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llSubStringIndex(sStr,llToLower(g_sSubMenu)) && sStr != "menu "+g_sSubMenu) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (sStr==g_sSubMenu || sStr == "menu "+g_sSubMenu) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;

list g_lAllowedSources=[];
list g_lDisallowedSources=[];
key g_kPendingSource;
string g_sPendingRLV;

PromptForSource(key kID, string sPendingCommand){
    g_kPendingSource=kID;
    g_sPendingRLV = sPendingCommand;
    Dialog(llGetOwner(), "[Relay]\n\nObject Name: "+llKey2Name(kID)+"\nObject ID: "+(string)kID+"\n\nIs requesting to use your RLV Relay, do you want to allow it?", ["Yes", "No"], [], 0, CMD_WEARER, "AskPrompt");
}

///param id=source
///param msg=RLV command
Process(string msg, key id){
    
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
                    llOwnerSay("@detach=add");
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
                        llOwnerSay("@detach=rem");
                    }
                    if (behav == "unsit") sitid = NULL_KEY;
                }
            }
            else if (command=="!pong" && id == forcesitter && sitid != NULL_KEY) g_iResit_status = 1;
            else if (command=="!version") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!version,1100");
            else if (command=="!implversion") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!implversion,ORG=0003/Satomi's Damn Fast Relay v4:OPENCOLLAR");
            else if (command=="!x-orgversions") llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+",!x-orgversions,ORG=0003");
            else if (command=="!release") Release();
            else llRegionSayTo(id, RLV_RELAY_CHANNEL, ident+","+(string)id+","+command+",ko");            
        }
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
                
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if(sMsg == Checkbox(bool((g_iMode==0)), "OFF")){
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
                    } else if(sMsg == "Safeword"){
                        llMessageLinked(LINK_SET, CMD_RELAY_SAFEWORD, "safeword", "");
                    }
                    
                    if(iRespring)Menu(kAv,iAuth);
                    
                } else if(sMenu == "AskPrompt"){
                    if(sMsg == "No"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Ignoring this relay request!", g_kWearer);
                        g_lDisallowedSources=[g_kPendingSource]+g_lDisallowedSources;
                    } else {
                        g_lAllowedSources = [g_kPendingSource]+g_lAllowedSources;
                        Process(g_sPendingRLV, g_kPendingSource);
                        g_sPendingRLV="";
                    }
                }
            }
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
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
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="global")
                if(llList2String(lSettings,1) == "locked") g_iLocked=FALSE;
        } else if(iNum == CMD_SAFEWORD){
            // Process safeword
            llMessageLinked(LINK_SET, CMD_RELAY_SAFEWORD, "safeword", "");
        } else if(iNum == CMD_RELAY_SAFEWORD){
            Release();
            integer iOldMode=g_iMode;
            g_iMode=0;
            llMessageLinked(LINK_SET, NOTIFY,"0Relay temporarily disabled due to safeword. The relay will reactivate in 30 seconds", g_kWearer);
            llSleep(30);
            g_iMode=iOldMode;
            llMessageLinked(LINK_SET,NOTIFY, "0Relay has been reactivated",g_kWearer);
        } else if(iNum == REBOOT){
            llResetScript();
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
    
    listen(integer c, string w, key id, string msg) {
        if (Source) { if (Source != id) return; } // already grabbed by another device
        if(g_iMode==MODE_ASK){
            if(llListFindList(g_lDisallowedSources, [id])!=-1)return;
            
            if(llListFindList(g_lAllowedSources, [id]) ==-1){
                PromptForSource(id,msg);
                return;
            }
            
            
        }

        Process(msg,id);
    }
}
