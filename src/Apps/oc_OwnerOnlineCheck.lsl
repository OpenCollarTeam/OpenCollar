/*
This file is a part of OpenCollar.
Copyright ©2021

: Contributors :

Aria (Tashia Redrose)
    *Jan 2021       -       Created optional app for notification on owner login
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

string g_sParentMenu = "Apps";
string g_sSubMenu = "Owner Online";


//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;

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

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

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

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Owner Online Checker App]\n\nSet Interval\t\t- Default (60); Current ("+(string)g_iInterval+")\nNotifChat\t\t- Notification in local chat (private)\nNotifDialog\t\t- Notification in a dialog box\n\n\n* Note: This app can be fully controlled by the collar wearer";
    list lButtons = [Checkbox(g_iEnable, "ON"), "Set Interval", Checkbox(g_iTypeLocal, "NotifChat"), Checkbox(g_iTypeDialog, "NotifDialog")];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llSubStringIndex(llToLower(sStr),llToLower(g_sSubMenu)) && llToLower(sStr) != "menu "+llToLower(g_sSubMenu)) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0; 
        //string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        //string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        //string sText;
        /// [prefix] g_sSubMenu sChangetype sChangevalue
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
integer g_iLocked=FALSE;
integer g_iInterval=60;
integer g_iEnable;
integer g_iTypeLocal=1;
integer g_iTypeDialog;

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

list g_lOwners; // uuid, online, inRegion

UpdateOwner(key ID, integer online)
{
    if(ID == "")return;
    integer index = llListFindList(g_lOwners, [ID]);
    if(index==-1) g_lOwners += [ID, online];
    else {
        integer lastState = (integer)llList2String(g_lOwners,index+1);
        
        //llSay(0, "UPDATE called ("+(string)lastState+", "+(string)lastRegion+") [secondlife:///app/agent/"+(string)ID+"/about] = ("+(string)online+", "+(string)inRegion+")");
        if(lastState==online){}
        else {
            if(online){
                if(g_iTypeLocal)llMessageLinked(LINK_SET, NOTIFY, "0[Owner Online Alert]  secondlife:///app/agent/"+(string)ID+"/about has logged in", g_kWearer);
                if(g_iTypeDialog)Dialog(g_kWearer, "[Owner Online Checker App]\n\n\nsecondlife:///app/agent/"+(string)ID+"/about has logged in", [],["-exit-"],0,CMD_NOACCESS, "StatusAlert");
            }else {
                if(g_iTypeLocal)llMessageLinked(LINK_SET, NOTIFY, "0[Owner Online Alert]  secondlife:///app/agent/"+(string)ID+"/about has logged out", g_kWearer);
                if(g_iTypeDialog)Dialog(g_kWearer, "[Owner Online Checker App]\n\n\nsecondlife:///app/agent/"+(string)ID+"/about has logged out", [],["-exit-"],0,CMD_NOACCESS, "StatusAlert");
            }
            g_lOwners = llListReplaceList(g_lOwners, [online], index+1, index+1);
        }
    }
    //llSay(0, "UPDATE final list contents: "+llDumpList2String(g_lPita, "~"));
}
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
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
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
    }
    
    timer(){
        if(g_iEnable){
            llSetTimerEvent(g_iInterval);
            UpdateDSRequest(NULL, llRequestAgentData(llList2Key(g_lOwners, 0),DATA_ONLINE), "get_online:0");
        }else{
            llSetTimerEvent(0);
            return;
        }
    }
    
    dataserver(key kID, string sData)
    {
        if(HasDSRequest(kID)!=-1){
            string meta = GetDSMeta(kID);
            list lTmp = llParseString2List(meta,[":"],[]);
            if(llList2String(lTmp,0)=="get_online"){
                DeleteDSReq(kID);
                integer curIndex = (integer)llList2String(lTmp,1);
                key curAv = llList2Key(g_lOwners,curIndex);
                UpdateOwner(curAv, (integer)sData);
                curIndex+=2;
                if(curIndex>=llGetListLength(g_lOwners)){
                    return;
                }
                UpdateDSRequest(NULL, llRequestAgentData(llList2Key(g_lOwners,curIndex),DATA_ONLINE), "get_online:"+(string)curIndex);
            }
        }
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
                    if(sMsg == UPMENU) {
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if(sMsg == Checkbox(g_iEnable, "ON")){
                        g_iEnable=1-g_iEnable;
                        llSetTimerEvent(g_iEnable);
                        llMessageLinked(LINK_SET,LM_SETTING_SAVE, "ownerchecks_enable="+(string)g_iEnable, "");
                    }else if(sMsg == "Set Interval"){
                        Dialog(kAv, "What interval do you want to use for the check timer?\n\nDefault: 60", [],[],0,iAuth, "Menu~Interval");
                        iRespring=FALSE;
                    } else if(sMsg == Checkbox(g_iTypeLocal, "NotifChat")){
                        g_iTypeLocal = 1-g_iTypeLocal;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "ownerchecks_typechat="+(string)g_iTypeLocal, "");
                    } else if(sMsg == Checkbox(g_iTypeDialog, "NotifDialog")){
                        g_iTypeDialog=1-g_iTypeDialog;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "ownerchecks_typedialog="+(string)g_iTypeDialog,"");
                    }
                    
                    if(iRespring)Menu(kAv,iAuth);
                        
                } else if(sMenu == "Menu~Interval"){
                    g_iInterval=(integer)sMsg;
                    llSetTimerEvent(g_iEnable);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "ownerchecks_interval="+(string)g_iInterval, "");
                    Menu(kAv,iAuth);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lSettings,0);
            string sVar = llList2String(lSettings,1);
            string sVal = llList2String(lSettings,2);
            
            if(sToken=="auth"){
                if(sVar=="owner"){
                    g_lOwners=[];
                    integer i=0;
                    list lTmpOwner = llParseString2List(sVal, [","],[]);
                    integer x = llGetListLength(lTmpOwner);
                    for(i=0;i<x;i++){
                        if(llList2String(lTmpOwner,i)!=g_kWearer)
                            UpdateOwner((key)llList2String(lTmpOwner, i), FALSE);
                    }
                }
            } else if(sToken == "ownerchecks"){
                if(sVar == "enable"){
                    g_iEnable=(integer)sVal;
                    llSetTimerEvent(g_iEnable);
                } else if(sVar == "interval"){
                    g_iInterval = (integer)sVal;
                } else if(sVar == "typechat"){
                    g_iTypeLocal=(integer)sVal;
                }else if(sVar == "typedialog"){
                    g_iTypeDialog=(integer)sVal;
                }
            } 
            
            if(sStr == "settings=sent")
            {
                llSetTimerEvent(g_iEnable);
            }
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}
