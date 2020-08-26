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

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}


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
integer CMD_BLOCKED = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer CMD_SAFEWORD = 510;
integer CMD_NOACCESS = 599; // Required for when public is disabled

integer AUTH_REQUEST = 600;
integer AUTH_REPLY=601;


integer g_iEnabled=FALSE ; // DEFAULT
integer g_iRisky=FALSE;
integer g_iAutoRelease=FALSE;


integer NOTIFY = 1002;
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

integer g_iReleaseTime = 0;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Capture]";
    list lButtons = [Checkbox(g_iEnabled,"Enabled"), Checkbox(g_iRisky, "Risky"), Checkbox(g_iAutoRelease, "AutoRelease")];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

WearerConsent(string SLURL){
    string sPrompt = "\n[Capture]\n \n"+SLURL+" is attempting to capture you. Do you agree?";
    Dialog(g_kWearer, sPrompt, ["YES", "NO"], [], 0, CMD_WEARER, "ConsentPrompt");
}

StartCapture(key kID, integer iAuth) // This is a dialog prompt on the cmd no access
{
    if(!g_iEnabled)return;
    if(iAuth == CMD_NOACCESS)return;
    
    Dialog(kID,  "\n[Capture]\n \nDo you want to capture secondlife:///app/agent/"+(string)g_kWearer+"/about?", ["YES", "NO"], [], 0, iAuth, "StartPrompt");
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
        else if (kID == g_kCaptor) StopCapture(kID, iNum); // if we are the Captor ask if we want to stop capture instead.
        else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to capture settings", kID);
    }
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        //llSay(0, sChangetype+": [changetype]");
        //llSay(0, sChangevalue+": [changevalue]");
        //llSay(0, (string)iNum+": [iAuth]");
        
        
        if(sChangetype == "capture"){
            if(sChangevalue == "dump"){
                if(iNum != CMD_OWNER && iNum != CMD_WEARER)return;
                llSay(0,(string)g_iFlagAtLoad+" [InitialBootFlags]");
                llSay(0, (string)g_kCaptor+" [TempOwner]");
                llSay(0, (string)iNum+" [AuthLevel]");
            }else if(sChangevalue=="on"){
                if(g_iEnabled){
                    llMessageLinked(LINK_SET,NOTIFY, "0Capture mode already enabled.", g_kWearer);
                }else{
                    llMessageLinked(LINK_SET,NOTIFY, "0Capture mode enabled.", g_kWearer);
                    g_iEnabled=TRUE;
                    Commit();
                }
            }else if(sChangevalue=="off"){
                if(!g_iEnabled){
                    llMessageLinked(LINK_SET,NOTIFY, "0Capture mode already disabled.", g_kWearer);
                }else{
                    llMessageLinked(LINK_SET,NOTIFY, "0Capture mode disabled.", g_kWearer);
                    g_iEnabled=FALSE;
                    Commit();
                }
            }else if(sChangevalue==""){
                // Attempt to capture
                if(!g_iEnabled)return;
                if(g_iCaptured){
                    // Check if ID is captor, as they may be trying to release
                    if(kID == g_kCaptor){
                        // Initiate release now
                        llMessageLinked(LINK_SET, NOTIFY, "0Capture has ended", g_kCaptor);
                        llMessageLinked(LINK_SET, NOTIFY, "0You are no longer captured by secondlife:///app/agent/"+(string)g_kCaptor+"/about !", g_kWearer);
                        g_iCaptured=FALSE;
                        g_kCaptor=NULL_KEY;
                        Commit();
                    }else if(kID == g_kWearer){
                        llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% you can not free yourself!", kID);
                    }else{
                        llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% while already captured", kID);
                        return;
                    }
                }else {
                    if(kID == g_kWearer){
                        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to capture yourself", g_kWearer);
                        return;
                    }
                    integer RetryCount=0;
                    @Retry;
                    if(g_kCaptor == NULL_KEY || g_kCaptor == ""){
                        // Check risky status
                        if(g_iRisky){
                            // Instant capture
                            g_kCaptor=kID;
                            llMessageLinked(LINK_SET, NOTIFY, "0Successfuly captured secondlife:///app/agent/"+(string)g_kWearer+"/about", g_kCaptor);
                            g_iCaptured=TRUE;
                            llMessageLinked(LINK_SET, NOTIFY, "0You have been captured by secondlife:///app/agent/"+(string)g_kCaptor+"/about ! If you need to free yourself, you can always use your safeword '"+g_sSafeword+"'. Also by saying your prefix capture", g_kWearer);
                            Commit();
                        } else {
                            // Ask the wearer for consent to allow capture
                            g_kCaptor=kID;
                            if (!g_iCaptured) llSetTimerEvent(1);
                            g_kExpireFor=g_kWearer;
                            g_iExpireMode=1;
                            g_iExpire=llGetUnixTime()+30;
                            
                            llMessageLinked(LINK_SET, AUTH_REQUEST, "capture", kID);
//                            WearerConsent("secondlife:///app/agent/"+(string)kID+"/about");
//                            llSay(0, "=> Ask for consent from wearer <=\n* Not yet implemented");
                        }
                    } else {
                        if(g_kCaptor == kID){
                            llMessageLinked(LINK_SET, NOTIFY, "0Your request is already pending. Try again later!", g_kCaptor);
                            return;
                        }
                        llMessageLinked(LINK_SET, NOTIFY, "0 Error in capture settings: g_kCaptor; Line 193\n* Attempting repairs", g_kWearer);
                        g_kCaptor=NULL_KEY;
                        g_iCaptured=FALSE;
                        Commit();
                        RetryCount++;
                        if(RetryCount > 3){
                            llMessageLinked(LINK_SET,NOTIFY, "0Exceeded maximum retries. Please report this error to OpenCollar!\n"+(string)g_iFlagAtLoad+";"+(string)g_kCaptor,g_kWearer);
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
integer g_iFlagAtLoad = 8;
string g_sSafeword="RED";

Commit(){
    integer StatusFlags;
    if(g_iEnabled)StatusFlags+=1;
    if(g_iRisky)StatusFlags+=2;
    if(g_iCaptured)StatusFlags+=4; // Used in oc_auth mainly to set the captureIsActive flag
    if(g_iAutoRelease)StatusFlags+=8;
    g_iFlagAtLoad=StatusFlags;
    
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "capture_status="+(string)StatusFlags,"");
    if(g_iCaptured){
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_tempowner="+(string)g_kCaptor,"");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "capture_isActive=1", ""); // <--- REMOVE AFTER NEXT RELEASE. This is here only for 7.3 compatibility
        if (g_iAutoRelease) {
            g_iReleaseTime = 0;
            llSetTimerEvent(1);
        }
    }else{
        if (g_kExpireFor == NULL_KEY) llSetTimerEvent(0);
        llMessageLinked(LINK_SET, CMD_OWNER, "unleash", g_kCaptor);
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_tempowner", "");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "capture_isActive", ""); // <------ REMOVE AFTER NEXT RELEASE
    }
}


default
{
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        llSetMemoryLimit(40000);
        if(llGetStartParameter()!=0)state inUpdate;
        g_kWearer = llGetOwner();
        llSleep(2);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "capture_status", ""); // Needed to get the EMPTY reply
    }
    
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum == CMD_NOACCESS && sStr == "menu" && g_iEnabled && !g_iCaptured) StartCapture(kID, iNum); // When the collar is touched by someone without permission and capture is enabled show the Capture dialog.
        if(iNum >= CMD_OWNER && iNum <= CMD_NOACCESS) UserCommand(iNum, sStr, kID);
        if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        
        } else if(iNum == AUTH_REPLY){
            list lTmp = llParseString2List(sStr, ["|"],[]);
            if(llList2String(lTmp,0)=="AuthReply"){
                if(kID == "capture"){
                    // check auth
                    integer iAuth = (integer)llList2String(lTmp,2);
                    key kAv = (key)llList2String(lTmp,1);
                    
                    if(iAuth == CMD_BLOCKED){
                        g_kExpireFor="";
                        g_iExpireMode=0;
                        g_kCaptor=NULL_KEY;
                        g_iExpire=0;
                        
                        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to capture because you have been blocked on this collar", kAv);
                        return;
                    }
                    // auth should be ok, check if enabled
                    if(!g_iEnabled)return;
                    // process the capture system, perform wearer consent
                    WearerConsent("secondlife:///app/agent/"+(string)kAv+"/about");
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
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
                    
                    if(sMsg == Checkbox(g_iEnabled, "Enabled")){
                        g_iEnabled=1-g_iEnabled;
                    }
                    
                    if(sMsg == Checkbox(g_iRisky, "Risky")){
                        g_iRisky=1-g_iRisky;
                    }
                    
                    if (sMsg == Checkbox(g_iAutoRelease,"AutoRelease")){
                        g_iAutoRelease=1-g_iAutoRelease;
                    }
                    
                    Commit();
                    
                    if(iRespring) Menu(kAv, iAuth);
                } else if(sMenu == "ConsentPrompt"){
                    if(sMsg == "NO"){
                        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% by wearer", g_kCaptor);
                        g_kCaptor=NULL_KEY;
                        Commit();
                    } else if(sMsg == "YES"){
                        g_iCaptured=TRUE;
                        llMessageLinked(LINK_SET, NOTIFY, "0Success", g_kCaptor);
                        Commit();
                    }
                    g_iExpire=0;
                    g_kExpireFor=NULL_KEY;
                    if (!g_iCaptured) llSetTimerEvent(0);
                    g_iExpireMode=0;
                } else if(sMenu == "StartPrompt"){
                    if (sMsg == "YES") UserCommand(iAuth,"capture",kAv);
                } else if(sMenu == "EndPrompt"){
                    if(sMsg == "NO"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Confirmed. Not Ending Capture", g_kExpireFor);
                    }else if(sMsg == "YES"){
                        llMessageLinked(LINK_SET, NOTIFY, "1Capture has ended", g_kCaptor);
                        g_iCaptured=FALSE;
                        g_kCaptor=NULL_KEY;
                        Commit();
                    }
                    
                    g_iExpire=0;
                    g_kExpireFor=NULL_KEY;
                    if (!g_iCaptured) llSetTimerEvent(0);
                    g_iExpireMode=0;
                }
            }
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "safeword"){
                    g_sSafeword = llList2String(lSettings,2);
                } else if(llList2String(lSettings,1) == "checkboxes"){
                    g_lCheckboxes = llCSV2List(llList2String(lSettings,2));
                }
            } else if(llList2String(lSettings,0) == "capture"){
                if(llList2String(lSettings,1) == "status"){
                    integer Flag = (integer)llList2String(lSettings,2);
                    if(Flag&1)g_iEnabled=TRUE;
                    if(Flag&2)g_iRisky=TRUE;
                    if(Flag&4)g_iCaptured=TRUE;
                    if(Flag&8)g_iAutoRelease=TRUE;
                    
                    
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
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1) == "locked") g_iLocked=FALSE;
            }
        } else if(iNum == LM_SETTING_EMPTY){
            if(sStr == "capture_status"){
                g_iAutoRelease=TRUE;
                Commit();
            }
        } else if(iNum == CMD_SAFEWORD){
            if(g_iCaptured)llMessageLinked(LINK_SET,NOTIFY, "0Safeword used, capture has been stopped", g_kCaptor);
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
        if(g_iExpire <=llGetUnixTime() && g_kExpireFor != ""){
            if (!g_iCaptured) llSetTimerEvent(0);
            llMessageLinked(LINK_SET,NOTIFY, "0Timed Out.",g_kExpireFor);
            g_iExpire=0;
            g_kExpireFor="";
            if(g_iExpireMode==1){
                g_kCaptor=NULL_KEY;
                g_iExpireMode=0;
            }
        }
        
        if (g_iCaptured && g_iAutoRelease && llGetAgentSize(g_kCaptor) == ZERO_VECTOR){
            if (g_iReleaseTime == 0) {
                g_iReleaseTime = llGetUnixTime() + 600;
                llSleep(1); // Otherwise the Message will happen at the same time as the Teleport, and the Message will not show to the captor!
                llMessageLinked(LINK_SET,NOTIFY, "0You are out of range! Capture of secondlife:///app/agent/"+(string)g_kWearer+"/about will end in 10 minutes unless you come back!", g_kCaptor);
                llMessageLinked(LINK_SET,NOTIFY, "0Seems your captor has left you alone. You will be released in 10 minutes.", g_kWearer);
            } else if (g_iReleaseTime <= llGetUnixTime()) {
                g_iReleaseTime = 0;
                UserCommand(CMD_OWNER,"capture",g_kCaptor);
            }
        } else if (g_iCaptured && g_iAutoRelease) {
            if (g_iReleaseTime != 0){
                llMessageLinked(LINK_SET,NOTIFY, "0Timer reset. Welcome Back!", g_kCaptor);
                llMessageLinked(LINK_SET,NOTIFY, "0Your captor is back! Reseted and Stopped the timer.", g_kWearer);
            }
            g_iReleaseTime = 0;
        }
    }
    
            
}

state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
    }
}
