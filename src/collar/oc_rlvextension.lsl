// This file is part of OpenCollar.
//  Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue                            
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sScriptVersion = "7.4";

string g_sParentMenu = "RLV";
string g_sSubMenu1 = "Force Sit";
string g_sSubMenu3 = "RLV Settings";
integer g_iStrictSit=FALSE; // Default - do not use strict mode

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;

integer REBOOT = -1000;
integer LINK_CMD_DEBUG=1999;
integer LINK_CMD_RESTRICTIONS = -2576;
integer LINK_CMD_RESTDATA = -2577;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;
integer DIALOG_SENSOR = -9003;
string UPMENU = "BACK";
//string ALL = "ALL";

integer g_bCanStand = TRUE;
integer g_bCanChat = FALSE;
integer g_bMuffle = FALSE;
integer g_iBlurAmount = 5;
float g_fMaxCamDist = 2.0;
float g_fMinCamDist = 1.0;

integer g_iRLV = FALSE;

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

list lRLVEx = [
    "IM"            , "sendim"      , 1     ,
    "RcvIM"         , "recvim"      , 2     ,
    "RcvChat"       , "recvchat"    , 4     ,
    "RcvEmote"      , "recvemote"   , 8     ,
    "Lure"          , "tplure"      , 16    ,
    "refuseTP"      , "accepttp"    , 32    ,
    "Start IM"      , "startim"     , 64    
];

string g_sExTarget = "";

list g_lOwners = [];
list g_lSecOwners = [];
list g_lTempOwners = [];

integer g_iOwnerEx = 127;
integer g_iTrustedEx = 95;

list g_lMenuIDs;
integer g_iMenuStride;
integer g_iLocked=FALSE;

//list g_lStrangerEx = [];

list g_lMuffleReplace = [
    "p" , "h",
    "t" , "k",
    "m" , "n",
    "o" , "e",
    "u" , "o",
    "w" , "o",
    "b" , "h"
];

integer g_iMuffleListener;

string strReplace(string str, string search, string replace) 
{
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}

string MuffleText(string sText)
{
    integer i;
    for (i=0; i<llGetListLength(g_lMuffleReplace);i+=2)
    {
        sText = strReplace(sText, llList2String(g_lMuffleReplace,i),llList2String(g_lMuffleReplace,i+1));
    }
    return sText;
}

SetMuffle(integer bEnable)
{
    if (bEnable && g_bCanChat) {
        llMessageLinked(LINK_SET,RLV_CMD,"redirchat:3728192=add","Muffle");
        //llOwnerSay("@redirchat:3728192=add");
        g_iMuffleListener = llListen(3728192, "", llGetOwner(),"");
    } else {
        llMessageLinked(LINK_SET,RLV_CMD,"redirchat:3728192=rem","Muffle");
        //llOwnerSay("@redirchat:3728192=rem");
        llListenRemove(g_iMuffleListener);
    }
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    if (sName == "Restrictions~sensor" || sName == "find")
    llMessageLinked(LINK_SET, DIALOG_SENSOR, (string)kID +"|"+sPrompt+"|0|``"+(string)(SCRIPTED|PASSIVE)+"`20`"+(string)PI+"`"+llDumpList2String(lUtilityButtons,"`")+"|"+llDumpList2String(lChoices,"`")+"|" + (string)iAuth, kMenuID);
    else llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

MenuExceptions(key kID, integer iAuth) {
    string sPrompt = "\n[Exceptions]\n \nSet exceptions to the restrictions for RLV commands.";
    Dialog(kID, sPrompt, ["Owner","Trusted"], [UPMENU], 0, iAuth, "Exceptions~Main");
}

MenuSetExceptions(key kID, integer iAuth, string sTarget){
    list lButtons = [];
    integer iExMask;
    g_sExTarget = sTarget;
    
    if (sTarget == "Owner") iExMask = g_iOwnerEx;
    else if (sTarget == "Trusted") iExMask = g_iTrustedEx;
    integer i;
    for (i=0; i<llGetListLength(lRLVEx);i=i+3) {
        lButtons += Checkbox((iExMask&llList2Integer(lRLVEx,i+2)), llList2String(lRLVEx,i));
    }
    Dialog(kID, "Select Exceptions:", lButtons, [UPMENU], 0, iAuth, "Exceptions~Set");
}

MenuForceSit(key kID, integer iAuth) {
    
    Dialog(kID, "Select a Place to sit:", [Checkbox(g_iStrictSit, "Strict Sit"), UPMENU, "[UNSIT]"], [], 0, iAuth, "Restrictions~sensor");
}

MenuSettings(key kID, integer iAuth){
    Dialog(kID, "Select Settings:", ["Exceptions","Camera", "Chat"], [UPMENU], 0, iAuth, "Settings~Main");
}

MenuCamera(key kID, integer iAuth){
    Dialog(kID, "Camera Values", ["Min Dist", "Max Dist","Blur Amount"], [UPMENU], 0, iAuth, "Settings~Camera");
}

MenuChat(key kID, integer iAuth){
    string sBtn;
    sBtn = Checkbox(g_bMuffle, "Muffle");
    
    Dialog(kID, "Chat Values", [sBtn], [UPMENU], 0, iAuth, "Settings~Chat");
}

MenuSetValue(key kID, integer iAuth, string sValueName) {
    string sValue;
    
    if (sValueName == "MinCamDist") sValue = (string)g_fMinCamDist;
    else if (sValueName == "MaxCamDist") sValue = (string)g_fMaxCamDist;
    else if (sValueName == "BlurAmount") sValue = (string)g_iBlurAmount;
    
    Dialog(kID, "Set "+sValueName+"\n \n"+sValueName+"="+sValue, ["+1.0", "+0.5","+0.1","-1.0","-0.5","-0.1"], [UPMENU], 0, iAuth, "Settings~"+sValueName);
}

ApplyAllExceptions(integer iBoot, integer bClearAll){
    if (g_iRLV){
        integer iExIndex;
        for (iExIndex=1; iExIndex<llGetListLength(lRLVEx);iExIndex=iExIndex + 3){
            list lTargetList = g_lOwners+g_lTempOwners;
            integer i;
            for (i=0; i<llGetListLength(lTargetList);++i) {
                if (llList2String(lTargetList,i) != llGetOwner()){
                    if ((llList2Integer(lRLVEx,iExIndex+1) & g_iOwnerEx) && !bClearAll) llOwnerSay("@"+llList2String(lRLVEx,iExIndex)+":"+llList2String(lTargetList,i)+"=add");
                    else llOwnerSay("@"+llList2String(lRLVEx,iExIndex)+":"+llList2String(lTargetList,i)+"=rem");
                }
            }
            lTargetList = g_lSecOwners;
            for (i=0; i<llGetListLength(lTargetList);++i){
                if (llList2String(lTargetList,i) != llGetOwner()){
                    if ((llList2Integer(lRLVEx,iExIndex+1) & g_iTrustedEx) && !bClearAll) llOwnerSay("@"+llList2String(lRLVEx,iExIndex)+":"+llList2String(lTargetList,i)+"=add");
                    else llOwnerSay("@"+llList2String(lRLVEx,iExIndex)+":"+llList2String(lTargetList,i)+"=rem");
                }
            }
        }
    }
    Save(iBoot);
}

Save(integer iBoot){
    if (!iBoot) {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_MinCamDist="+(string)g_fMinCamDist, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_MaxCamDist="+(string)g_fMaxCamDist, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_BlurAmount="+(string)g_iBlurAmount, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_Muffle="+(string)g_bMuffle, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_Owner="+(string)g_iOwnerEx, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_Trusted="+(string)g_iTrustedEx, "");
    }
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
   // if ((llSubStringIndex(sStr,"exceptions") && sStr != "menu "+g_sSubMenu1) || (llSubStringIndex(sStr,"exceptions") && sStr != "menu "+g_sSubMenu2)) return;
    if (sStr=="sit" || sStr == "menu "+g_sSubMenu1) MenuForceSit(kID, iNum);
    else if (sStr=="rlvsettings" || sStr == "menu "+g_sSubMenu3) {
        if (iNum < CMD_EVERYONE) MenuSettings(kID,iNum);
        else {
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kID);
            llMessageLinked(LINK_SET, iNum, "menu "+g_sParentMenu, kID);
        }
    } else { 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangekey = llList2String(llParseString2List(sStr, [" "], []),1);
//        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),2);
        if (sChangetype == "sit") {
            if ((sChangekey == "[UNSIT]" || sChangekey == "unsit") && iNum != CMD_WEARER ) {
                if(g_iStrictSit){
                    llMessageLinked(LINK_SET, LINK_CMD_RESTRICTIONS, "Stand Up=0="+(string)iNum, kID);
                }
                llSleep(1.5);
                llMessageLinked(LINK_SET,RLV_CMD,"unsit=force","Macros");
            } else {
                if(g_iStrictSit){
                    llMessageLinked(LINK_SET, LINK_CMD_RESTRICTIONS, "Stand Up=1="+(string)iNum,kID);
                }
                llMessageLinked(LINK_SET,RLV_CMD,"sit:"+sChangekey+"=force","Macros");
            }
        } else if(sChangetype == "unsit"){
            UserCommand(iNum, "sit unsit", kID);
        }
    }
}

default
{
    state_entry()
    {
        if(llGetStartParameter()!= 0) state inUpdate;
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu1,""); // Register menu "Force Sit"
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu3,""); // Register Settings Menu
        } else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                if(sMenu == "Exceptions~Main"){
                    if(sMsg == UPMENU) MenuSettings(kAv,iAuth);
                    else MenuSetExceptions(kAv,iAuth,sMsg);
                } else if (sMenu == "Exceptions~Set") {
                    if (sMsg == UPMENU) Dialog(kAv, "\n[Exceptions]\n \nSet exceptions to the restrictions for RLV commands.", ["Owner","Trusted"], [UPMENU], 0, iAuth, "Exceptions~Main");
                    else {
                        sMsg = llGetSubString( sMsg, llStringLength(llList2String(g_lCheckboxes,0))+1, -1);
                        integer iIndex = llListFindList(lRLVEx,[sMsg]);
                        if (iIndex > -1) {
                            if (g_sExTarget == "Owner") {
                                if (g_iOwnerEx & llList2Integer(lRLVEx,iIndex+2)) g_iOwnerEx = g_iOwnerEx ^ llList2Integer(lRLVEx,iIndex+2);
                                else g_iOwnerEx = g_iOwnerEx | llList2Integer(lRLVEx,iIndex+2);
                            } else if (g_sExTarget == "Trusted") {
                                if (g_iTrustedEx & llList2Integer(lRLVEx,iIndex+2)) g_iTrustedEx = g_iTrustedEx ^ llList2Integer(lRLVEx,iIndex+2);
                                else g_iTrustedEx = g_iTrustedEx | llList2Integer(lRLVEx,iIndex+2);
                            }
                            ApplyAllExceptions(FALSE,FALSE);
                        }
                        MenuSetExceptions(kAv, iAuth, g_sExTarget);
                    }
                } else if (sMenu == "Exceptions~Main") {
                if (iAuth == CMD_OWNER) {
                    if (sMsg == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else MenuSetExceptions(kAv, iAuth, sMsg);
                    } else llMessageLinked(LINK_SET, NOTIFY, "0"+"Acces Denied!", kAv);
                } else if (sMenu == "Force Sit") MenuForceSit(kAv,iAuth);
                else if (sMenu == "Restrictions~sensor") {
                    if(sMsg == Checkbox(g_iStrictSit,"Strict Sit") && iAuth == CMD_OWNER){
                        g_iStrictSit=1-g_iStrictSit;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_strict="+(string)g_iStrictSit, "");
                        MenuForceSit(kAv,iAuth);
                        return;
                    }
                    
                    if (sMsg == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else{
                        UserCommand(iAuth,"sit "+sMsg,kAv);
                        
                        MenuForceSit(kAv, iAuth);
                    }
                } else if (sMenu == "Settings~Main") {
                    if (sMsg == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else if (sMsg == "Exceptions"){
                        if (iAuth <= CMD_OWNER) MenuExceptions(kAv, iAuth);
                        else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS%!", kAv);
                    } else if (sMsg == "Camera") MenuCamera(kAv, iAuth);
                    else if (sMsg == "Chat") MenuChat(kAv, iAuth);
                } else if (sMenu == "Settings~Camera") {
                    if (sMsg == UPMENU) MenuSettings(kAv,iAuth);
                    else if (sMsg == "Min Dist") MenuSetValue(kAv, iAuth, "MinCamDist");
                    else if (sMsg == "Max Dist") MenuSetValue(kAv, iAuth, "MaxCamDist");
                    else if (sMsg == "Blur Amount") MenuSetValue(kAv, iAuth, "BlurAmount"); 
                } else if (sMenu == "Settings~Chat") {
                    if (sMsg == UPMENU) MenuSettings(kAv,iAuth);
                    else {
                        sMsg = llGetSubString(sMsg,2,-1);
                        if (sMsg == "Muffle") {
                            g_bMuffle = !g_bMuffle;
                            SetMuffle(g_bMuffle);
                            Save(FALSE);
                        }
                        MenuChat(kAv,iAuth);
                    }
                } else {
                    list lMenu = llParseString2List(sMenu, ["~"],[]);
                    if (llList2String(lMenu,0) == "Settings") {
                        if (sMsg == UPMENU) MenuCamera(kAv, iAuth);
                        else {
                            if (llList2String(lMenu,1) == "MinCamDist") {
                                if (sMsg == "+1.0") g_fMinCamDist += 1.0;
                                else if (sMsg == "+0.5") g_fMinCamDist += 0.5;
                                else if (sMsg == "+0.1") g_fMinCamDist += 0.1;
                                else if (sMsg == "-1.0") g_fMinCamDist -= 1.0;
                                else if (sMsg == "-0.5") g_fMinCamDist -= 0.5;
                                else if (sMsg == "-0.1") g_fMinCamDist -= 0.1;
                                if (g_fMinCamDist < 0.1) g_fMinCamDist = 0.1;
                                else if (g_fMinCamDist > g_fMaxCamDist) g_fMinCamDist = g_fMaxCamDist;
                                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,llList2String(lMenu,1)+"="+(string)g_fMinCamDist,kAv);
                            } else if (llList2String(lMenu,1) == "MaxCamDist") {
                                if (sMsg == "+1.0") g_fMaxCamDist += 1.0;
                                else if (sMsg == "+0.5") g_fMaxCamDist += 0.5;
                                else if (sMsg == "+0.1") g_fMaxCamDist += 0.1;
                                else if (sMsg == "-1.0") g_fMaxCamDist -= 1.0;
                                else if (sMsg == "-0.5") g_fMaxCamDist -= 0.5;
                                else if (sMsg == "-0.1") g_fMaxCamDist -= 0.1;
                                if (g_fMaxCamDist < g_fMinCamDist) g_fMaxCamDist = g_fMinCamDist;
                                else if (g_fMaxCamDist > 20.0) g_fMaxCamDist = 20.0;
                                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,llList2String(lMenu,1)+"="+(string)g_fMaxCamDist,kAv);
                            } else if (llList2String(lMenu,1) == "BlurAmount") {
                                if (sMsg == "+1.0") g_iBlurAmount += 1;
                                else if (sMsg == "+0.5") g_iBlurAmount += 1;
                                else if (sMsg == "+0.1") g_iBlurAmount += 1;
                                else if (sMsg == "-1.0") g_iBlurAmount -= 1;
                                else if (sMsg == "-0.5") g_iBlurAmount -= 1;
                                else if (sMsg == "-0.1") g_iBlurAmount -= 1;
                                if (g_iBlurAmount < 2) g_iBlurAmount = 2;
                                else if (g_iBlurAmount > 30) g_iBlurAmount = 30;
                                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,llList2String(lMenu,1)+"="+(string)g_iBlurAmount,kAv);
                            }
                            Save(FALSE);
                            MenuSetValue(kAv,iAuth,llList2String(lMenu,1));
                        }
                    }
                }
            }
        } else if(iNum == LM_SETTING_RESPONSE){
        // Detect here the Settings
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
             integer i = llSubStringIndex(sToken, "_");
            if (sToken == "rlvext_MinCamDist") {
                g_fMinCamDist = (float)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MinCamDist="+(string)g_fMinCamDist,kID);
            } else if(sToken == "rlvext_strict"){
                g_iStrictSit=(integer)sValue;
            } else if (sToken == "rlvext_MaxCamDist") {
                g_fMaxCamDist = (float)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MaxCamDist="+(string)g_fMaxCamDist,kID);
            } else if (sToken == "rlvext_BlurAmount") {
                g_iBlurAmount = (integer)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"BlurAmount="+(string)g_iBlurAmount,kID);
            } else if (sToken == "rlvext_Muffle") { 
                g_bMuffle = (integer)sValue;
                SetMuffle(g_bMuffle);
            } else if (sToken == "rlvext_Owner") {
                g_iOwnerEx = (integer) sValue;
            } else if (sToken == "rlvext_Trusted") {
                g_iTrustedEx = (integer) sValue;
            }else if (llGetSubString(sToken, 0, i) == "auth_") {
                if (sToken == "auth_owner") {
                    g_lOwners = llParseString2List(sValue, [","], []);
                    if (g_iRLV) ApplyAllExceptions(TRUE,FALSE); // Only reapply when RLV is on.
                } else if (sToken == "auth_trust") {
                    g_lSecOwners = llParseString2List(sValue, [","], []);
                    if (g_iRLV) ApplyAllExceptions(TRUE,FALSE); // Only reapply when RLV is on.
                } else if (sToken == "auth_tempowner") {
                    g_lTempOwners = llParseString2List(sValue, [","], []);
                    if (g_iRLV) ApplyAllExceptions(TRUE,FALSE); // Only reapply when RLV is on.
                }
            } else if (sToken == "settings" && sValue == "send" && g_iRLV) ApplyAllExceptions(TRUE,FALSE);
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "checkboxes"){
                    g_lCheckboxes = llCSV2List(llList2String(lSettings,2));
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            if(sStr == "global_locked") g_iLocked=FALSE;
            else if (sStr == "auth_owner") {
                ApplyAllExceptions(TRUE,TRUE);
                g_lOwners = []; 
                ApplyAllExceptions(TRUE,FALSE);
            } else if (sStr == "auth_trust") {
                ApplyAllExceptions(TRUE,TRUE);
                g_lSecOwners = []; 
                ApplyAllExceptions(TRUE,FALSE);
            } else if (sStr == "auth_tempowner") {
                ApplyAllExceptions(TRUE,TRUE);
                g_lTempOwners = []; 
                ApplyAllExceptions(TRUE,FALSE);
            }
        } else if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        }else if (iNum == RLV_OFF){
            ApplyAllExceptions(TRUE,TRUE);
            g_iRLV = FALSE;
        } else if (iNum == RLV_REFRESH || iNum == RLV_ON) {
            g_iRLV = TRUE;
            ApplyAllExceptions(TRUE,FALSE);
            SetMuffle(g_bMuffle);
            llSleep(1);
            llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MinCamDist="+(string)g_fMinCamDist,kID);
            llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MaxCamDist="+(string)g_fMaxCamDist,kID);
            llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"BlurAmount="+(string)g_iBlurAmount,kID);
        } else if (iNum == REBOOT && sStr == "reboot") {
            llOwnerSay("Rebooting RLV Extension");
            llResetScript();
        } else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            
            llInstantMessage(kID, llGetScriptName() +" MEMORY USED: "+(string)llGetUsedMemory());
            llInstantMessage(kID, llGetScriptName() +" MEMORY FREE: "+(string)llGetFreeMemory());
        } else if (iNum == LINK_CMD_RESTRICTIONS) {
            list lCMD = llParseString2List(sStr,["="],[]);
            if (llList2String(lCMD,0) == "unsit" && llList2Integer(lCMD,2) < 0) g_bCanStand = llList2Integer(lCMD,1);
            if (llList2String(lCMD,0) == "sendchat" && llList2Integer(lCMD,2) < 0) {
                g_bCanChat = llList2Integer(lCMD,1);
                SetMuffle(g_bMuffle);
            }
        }
    }
    
    listen(integer iChan, string sName, key kID, string sMsg)
    {
        if (iChan == 3728192 && kID == llGetOwner()){
            string sObjectName = llGetObjectName();
            llSetObjectName(llKey2Name(llGetOwner()));
            llSay(0,MuffleText(sMsg));
            llSetObjectName(sObjectName);
        }
    }
}
state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
    }
}
