/*
This file is a part of OpenCollar.
Copyright 2019

: Contributors :

Aria (Tashia Redrose)
    * Dec 2019      - Rewrote Capture & Reset Script Version to 1.0

et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


string g_sParentMenu = "Apps";
string g_sSubMenu = "Capture";

string CHECKBOX = "☐☑";

string g_sScriptVersion = "7.4";
string g_sAppVersion = "1.0";

DebugOutput(key kDest, list lParams){
    llInstantMessage(kDest, llGetScriptName()+": "+llDumpList2String(lParams," "));
}
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer CMD_SAFEWORD = 510;
integer CMD_NOACCESS = 599; // Required for when public is disabled

integer g_iEnabled=FALSE ; // DEFAULT
integer g_iRisky=FALSE;

integer NOTIFY = 1002;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LINK_CMD_DEBUG=1999;
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

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

string TickBox(integer iTick, string sLabel){
    return llGetSubString(CHECKBOX, iTick, iTick)+" "+sLabel;
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Capture]";
    list lButtons = [TickBox(g_iEnabled,"Enabled"), TickBox(g_iRisky, "Risky")];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

WearerConsent(string SLURL){
    string sPrompt = "\n[Capture]\n \n"+SLURL+" is attempting to capture you. Do you agree?";
    Dialog(g_kWearer, sPrompt, ["YES", "NO"], [], 0, CMD_WEARER, "ConsentPrompt");
}

StopCapture(key kID, integer iAuth){
    Dialog(kID,  "\n[Capture]\n \nAre you sure you want to end capture?", ["YES", "NO"], [], 0, iAuth, "EndPrompt");
}
integer g_iExpire; // Handle for the expire timestamp for the prompts
key g_kExpireFor;
integer g_iExpireMode=0;

UserCommand(integer iNum, string sStr, key kID) {
    if (llSubStringIndex(sStr,llToLower(g_sSubMenu)) && sStr != "menu "+g_sSubMenu) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (sStr==g_sSubMenu || sStr == "menu "+g_sSubMenu) {
        if(iNum == CMD_OWNER)
            Menu(kID, iNum);
        else llMessageLinked(LINK_DIALOG, NOTIFY, "0%NOACCESS% to capture settings", kID);
    }
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        //llSay(0, sChangetype+": [changetype]");
        //llSay(0, sChangevalue+": [changevalue]");
        
        if(sChangetype == "capture"){
            if(sChangevalue == "dump"){
                if(iNum != CMD_OWNER || iNum != CMD_WEARER)return;
                llSay(0,(string)g_iFlagAtLoad+" [InitialBootFlags]");
                llSay(0, (string)g_kCaptor+" [TempOwner]");
                llSay(0, (string)iNum+" [AuthLevel]");
            }else if(sChangevalue==""){
                // Attempt to capture
                if(g_iCaptured){
                    // Check if ID is captor, as they may be trying to release
                    if(kID == g_kCaptor){
                        // Initiate release now
                        StopCapture(kID, iNum);
                        g_iExpire = llGetUnixTime()+30;
                        g_kExpireFor = kID;
                        llSetTimerEvent(1);
                    }else if(kID == g_kWearer){
                        // Prompt wearer, ask if they want to end capture
                        StopCapture(kID, iNum);
                        g_kExpireFor=kID;
                        g_iExpire = llGetUnixTime()+30;
                        llSetTimerEvent(1);
                    }else{
                        llMessageLinked(LINK_DIALOG,NOTIFY, "0%NOACCESS% while already captured", kID);
                        return;
                    }
                }else {
                    if(kID == g_kWearer){
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0%NOACCESS% to capture yourself", g_kWearer);
                        return;
                    }
                    integer RetryCount=0;
                    @Retry;
                    if(g_kCaptor == NULL_KEY || g_kCaptor == ""){
                        // Check risky status
                        if(g_iRisky){
                            // Instant capture
                            g_kCaptor=kID;
                            llMessageLinked(LINK_DIALOG, NOTIFY, "0Success", g_kCaptor);
                            g_iCaptured=TRUE;
                            llMessageLinked(LINK_DIALOG, NOTIFY, "0You have been captured by secondlife:///app/agent/"+(string)g_kCaptor+"/about ! If you need to free yourself, you can always use your safeword '"+g_sSafeword+"'. Also by saying your prefix capture", g_kWearer);
                            Commit();
                        }
                        else {
                            // Ask the wearer for consent to allow capture
                            g_kCaptor=kID;
                            llSetTimerEvent(1);
                            g_kExpireFor=g_kWearer;
                            g_iExpireMode=1;
                            g_iExpire=llGetUnixTime()+30;
                            WearerConsent("secondlife:///app/agent/"+(string)kID+"/about");
//                            llSay(0, "=> Ask for consent from wearer <=\n* Not yet implemented");
                        }
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0 Error in capture settings: g_kCaptor; Line 123\n* Attempting repairs", g_kWearer);
                        g_kCaptor=NULL_KEY;
                        g_iCaptured=FALSE;
                        Commit();
                        RetryCount++;
                        if(RetryCount > 3){
                            llMessageLinked(LINK_DIALOG,NOTIFY, "0Exceeded maximum retries. Please report this error to OpenCollar!\n"+(string)g_iFlagAtLoad+";"+(string)g_kCaptor,g_kWearer);
                            return;
                        }
                        jump Retry;
                    }
                }
                            
            }
        }
        
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;

key g_kCaptor;
integer g_iCaptured;
integer g_iFlagAtLoad = 0;
string g_sSafeword="RED";

Commit(){
    integer StatusFlags;
    if(g_iEnabled)StatusFlags+=1;
    if(g_iRisky)StatusFlags+=2;
    if(g_iCaptured)StatusFlags+=4; // Used in oc_auth mainly to set the captureIsActive flag
    g_iFlagAtLoad=StatusFlags;
    
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "capture_status="+(string)StatusFlags,"");
    if(g_iCaptured){
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "auth_tempowner="+(string)g_kCaptor,"");
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "capture_isActive=1", ""); // <--- REMOVE AFTER NEXT RELEASE. This is here only for 7.3 compatibility
    }else{
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "auth_tempowner", "");
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "capture_isActive", ""); // <------ REMOVE AFTER NEXT RELEASE
    }
}


default
{
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        if(llGetStartParameter()!=0)state inUpdate;
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST, "global_locked","");
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_NOACCESS) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == -99999) if(sStr == "update_active")state inUpdate;
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
                    
                    if(sMsg == TickBox(g_iEnabled, "Enabled")){
                        g_iEnabled=1-g_iEnabled;
                    }
                    
                    if(sMsg == TickBox(g_iRisky, "Risky")){
                        g_iRisky=1-g_iRisky;
                    }
                    
                    Commit();
                    
                    if(iRespring) Menu(kAv, iAuth);
                } else if(sMenu == "ConsentPrompt"){
                    if(sMsg == "NO"){
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0%NOACCESS% by wearer", g_kCaptor);
                        g_kCaptor=NULL_KEY;
                        Commit();
                    } else if(sMsg == "YES"){
                        g_iCaptured=TRUE;
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0Success", g_kCaptor);
                        Commit();
                    }
                    g_iExpire=0;
                    g_kExpireFor=NULL_KEY;
                    llSetTimerEvent(0);
                    g_iExpireMode=0;
                } else if(sMenu == "EndPrompt"){
                    if(sMsg == "NO"){
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0Confirmed. Not Ending Capture", g_kExpireFor);
                    }else if(sMsg == "YES"){
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1Capture has ended", g_kCaptor);
                        g_iCaptured=FALSE;
                        g_kCaptor=NULL_KEY;
                        Commit();
                    }
                    
                    g_iExpire=0;
                    g_kExpireFor=NULL_KEY;
                    llSetTimerEvent(0);
                    g_iExpireMode=0;
                }
            }
        } else if(iNum == LINK_UPDATE){
            if(sStr == "LINK_DIALOG") LINK_DIALOG=iSender;
            if(sStr == "LINK_RLV") LINK_RLV=iSender;
            if(sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "safeword"){
                    g_sSafeword = llList2String(lSettings,2);
                }
            } else if(llList2String(lSettings,0) == "capture"){
                if(llList2String(lSettings,1) == "status"){
                    integer Flag = (integer)llList2String(lSettings,2);
                    if(Flag&1)g_iEnabled=TRUE;
                    if(Flag&2)g_iRisky=TRUE;
                    if(Flag&4)g_iCaptured=TRUE;
                    g_iFlagAtLoad=Flag;
                }
            } else if(llList2String(lSettings,0) == "auth"){
                if(llList2String(lSettings,1) == "tempowner"){
                    g_kCaptor = (key)llList2String(lSettings,2);
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="global")
                if(llList2String(lSettings,1) == "locked") g_iLocked=FALSE;
        } else if(iNum == CMD_SAFEWORD){
            if(g_iCaptured)llMessageLinked(LINK_DIALOG,NOTIFY, "0Safeword used, capture has been stopped", g_kCaptor);
            g_iCaptured=FALSE;
            g_kCaptor=NULL_KEY;
            Commit();
        } else if(iNum == LINK_CMD_DEBUG){
            integer onlyver =0;
            if(sStr == "ver")onlyver=1;
            DebugOutput(kID, ["MAJOR VERSION", g_sScriptVersion, "APP", g_sAppVersion]);
            if(onlyver)return;
            DebugOutput(kID, ["FLAGS", g_iFlagAtLoad]);
            DebugOutput(kID, ["CAPTOR", g_kCaptor]);
            DebugOutput(kID, ["MISC", g_iEnabled, g_iRisky, g_iCaptured, g_iExpire, g_kExpireFor, g_iExpireMode]);
        }
            
       // llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
    timer(){
        if(g_iExpire <=llGetUnixTime()){
            llSetTimerEvent(0);
            llMessageLinked(LINK_DIALOG,NOTIFY, "0Timed Out.",g_kExpireFor);
            g_iExpire=0;
            g_kExpireFor="";
            if(g_iExpireMode==1){
                g_kCaptor=NULL_KEY;
                g_iExpireMode=0;
            }
        }
    }
            
}

state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
    }
}
