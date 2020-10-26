// This file is part of OpenCollar.
//  Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue                            
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sScriptVersion = "8.0";

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
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

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
integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;
list g_lSettingsReqs = [];
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
    Dialog(kID, sPrompt, ["Owner","Trusted","Custom"], [UPMENU], 0, iAuth, "Exceptions~Main");
}
list g_lCustomExceptions = []; // Exception name, Exception UUID, integer bitmask

MenuCustomExceptionsSelect(key kID,integer iAuth){
    string sPrompt = "\n[Exceptions]\n\nHere are your custom exceptions that are set\n\nNOTE: For groups, there are obviously some exceptions which will do nothing as there is no support for them viewer-side. We have no way to hide options that are irrelevant.";
    Dialog(kID, sPrompt, llList2ListStrided(g_lCustomExceptions, 0,-1,3),["+ ADD", "- REM", UPMENU], 0, iAuth, "Exceptions~Custom");
}

MenuCustomExceptionsRem(key kID, integer iAuth){
    string sPrompt = "\n[Exceptions]\n\nWhich custom exception do you want to remove?";
    Dialog(kID, sPrompt, llList2ListStrided(g_lCustomExceptions, 0, -1, 3), [UPMENU], 0, iAuth, "Exceptions~CustomRem");
}

string g_sTmpExceptionName;
MenuAddCustomExceptionName(key kID, integer iAuth){
    Dialog(kID,"What should we call this custom exception?", [],[],0,iAuth,"Exceptions~AddCustomName");
}

key g_kTmpExceptionID;
MenuAddCustomExceptionID(key kID, integer iAuth){
    Dialog(kID, "What UUID does this exception affect?", [],[],0,iAuth,"Exceptions~AddCustomID");
}

MenuSetExceptions(key kID, integer iAuth, string sTarget){
    list lButtons = [];
    integer iExMask;
    g_sExTarget = sTarget;
    
    if (sTarget == "Owner") iExMask = g_iOwnerEx;
    else if (sTarget == "Trusted") iExMask = g_iTrustedEx;
    else if(sTarget == "Custom"){
        iExMask = llList2Integer(g_lCustomExceptions, llListFindList(g_lCustomExceptions, [g_sTmpExceptionName])+2);
    }
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
            if(llGetListLength(g_lCustomExceptions)>2){
                for(i=2;i<llGetListLength(g_lCustomExceptions);i+=3){
                    
                    if ((llList2Integer(lRLVEx,iExIndex+1) & llList2Integer(g_lCustomExceptions,i)) && !bClearAll) llOwnerSay("@"+llList2String(lRLVEx,iExIndex)+":"+llList2String(g_lCustomExceptions,i-1)+"=add");
                    else llOwnerSay("@"+llList2String(lRLVEx,iExIndex)+":"+llList2String(g_lCustomExceptions,i-1)+"=rem");
                }
            }
        }
    }
    Save(iBoot);
}

Save(integer iBoot){
    if (!iBoot) {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_mincamdist="+(string)g_fMinCamDist, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_maxcamdist="+(string)g_fMaxCamDist, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_bluramount="+(string)g_iBlurAmount, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_muffle="+(string)g_bMuffle, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_owner="+(string)g_iOwnerEx, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_trusted="+(string)g_iTrustedEx, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_custom="+llDumpList2String(g_lCustomExceptions, "^"),"");
    }
}

integer g_iLastSitAuth = 599;
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
        string sChangetype = llToLower(llList2String(llParseString2List(sStr, [" "], []),0));
        string sChangekey = llToLower(llList2String(llParseString2List(sStr, [" "], []),1));
//        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),2);
        if (sChangetype == "sit") {
            if ((sChangekey == "[unsit]" || sChangekey == "unsit") && iNum <= g_iLastSitAuth ) {
                if(g_iStrictSit){
                    llMessageLinked(LINK_SET, LINK_CMD_RESTRICTIONS, "Stand Up=0="+(string)iNum, kID);
                }
                llSleep(1.5);
                llMessageLinked(LINK_SET,RLV_CMD,"unsit=force","Macros");
                g_iLastSitAuth = 599;
            } else {
                if(iNum > g_iLastSitAuth){
                    llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to sit.", kID);
                    return;
                }
                g_iLastSitAuth = iNum;
                if(g_iStrictSit){
                    llMessageLinked(LINK_SET, LINK_CMD_RESTRICTIONS, "Stand Up=1="+(string)iNum,kID);
                }
                llMessageLinked(LINK_SET,RLV_CMD,"sit:"+sChangekey+"=force","Macros");
            }
        } else if(sChangetype == "unsit"){
            UserCommand(iNum, "sit unsit", kID);
        } else if(sChangetype == "rlvex" && iNum == CMD_OWNER){
            if(sChangekey == "modify"){
                string sChangeArg1 = llToLower(llList2String(llParseString2List(sStr, [" "],[]), 2));
                string sChangeArg2 = llToLower(llList2String(llParseString2List(sStr,[" "],[]), 3));
                if(sChangeArg1 == "owner"){
                    g_iOwnerEx = (integer)sChangeArg2;
                    llMessageLinked(LINK_SET, NOTIFY, "0Owner exceptions modified", kID);
                } else if(sChangeArg1 == "trust"){
                    g_iTrustedEx = (integer)sChangeArg2;
                    llMessageLinked(LINK_SET, NOTIFY, "0Trusted exceptions modified", kID);
                } else {
                    // modify custom exception. arg1 = name, arg2 = uuid, arg3 = bitmask. remove old if exists, replace with new. including updating the exception uuid
                    string sChangeArg3 = llToLower(llList2String(llParseString2List(sStr,[" "],[]),4));
                    if(sChangeArg1==""||sChangeArg2==""||sChangeArg3==""){
                        llMessageLinked(LINK_SET, NOTIFY, "0Invalid amount of arguments for modifying a custom exception", kID);
                        return;
                    }
                    integer iPosx=llListFindList(g_lCustomExceptions, [sChangeArg1]);
                    if(iPosx!=-1){
                        // process
                        g_lCustomExceptions = llDeleteSubList(g_lCustomExceptions, iPosx, iPosx+2);
                    }
                    
                    
                    llMessageLinked(LINK_SET, NOTIFY, "0Custom exceptions modified  ("+sChangeArg1+"): "+sChangeArg2+" = "+sChangeArg3, kID);
                    g_lCustomExceptions += [sChangeArg1, sChangeArg2, (integer)sChangeArg3];
                }
                
                Save(FALSE);
            } else if(sChangekey == "listmasks"){
                integer ix=0;
                string sExceptionMasks;
                integer end = llGetListLength(lRLVEx);
                for(ix=0;ix<end;ix+=3){
                    sExceptionMasks += llList2String(lRLVEx,ix)+" = "+llList2String(lRLVEx,ix+2)+", ";
                }
                // list all possible bitmasks
                llMessageLinked(LINK_SET, NOTIFY, "0The exceptions all use a bitmask. The following are acceptable bitmask values: "+sExceptionMasks+". To calculate a bitmask, add the values into one larger integer for only the options you want. 127 is the max possible bitmask for exceptions", kID);
            } else if(sChangekey == "help"){
                llMessageLinked(LINK_SET, NOTIFY, "0Valid commands: listmasks, modify, listcustom\n\nmodify takes a range of 2-3 arguments.\nmodify owner [newBitmask]\nmodify trust [newMask]\nmodify [customExceptionName(no spaces)] [customExceptionUUID] [bitmask]", kID);
            } else if(sChangekey == "listcustom"){
                integer ix=0;
                string sCustom;
                integer end = llGetListLength(g_lCustomExceptions);
                for(ix=0;ix<end;ix+=3){
                    sCustom  += llList2String(g_lCustomExceptions,ix)+": "+llList2String(g_lCustomExceptions, ix+1)+" = "+llList2String(g_lCustomExceptions,ix+2)+"\n";
                }
                
                llMessageLinked(LINK_SET, NOTIFY, "0Custom Exceptions:\n\n"+sCustom,kID);
            }
        }
    }
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
    on_rez(integer iNum){
        llResetScript();
    }
    
    state_entry()
    {
        if(llGetStartParameter()!= 0)llResetScript();
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
                    else if(sMsg == "Custom")MenuCustomExceptionsSelect(kAv,iAuth);
                    else MenuSetExceptions(kAv,iAuth,sMsg);
                } else if(sMenu == "Exceptions~Custom"){
                    if(sMsg == UPMENU) MenuExceptions(kAv,iAuth);
                    else if(sMsg == "+ ADD"){
                        MenuAddCustomExceptionName(kAv,iAuth);
                    } else if(sMsg == "- REM"){
                        MenuCustomExceptionsRem(kAv, iAuth);
                    } else {
                        // view this exception's data and permit editting
                        g_sTmpExceptionName = sMsg;
                        MenuSetExceptions(kAv, iAuth, "Custom");
                    }
                } else if(sMenu == "Exceptions~CustomRem"){
                    if(sMsg == UPMENU) MenuCustomExceptionsSelect(kAv, iAuth);
                    else{
                        // remove it
                        integer iPos = llListFindList(g_lCustomExceptions, [sMsg]);
                        
                        ApplyAllExceptions(TRUE,TRUE);
                        llSleep(0.5);
                        
                        g_lCustomExceptions = llDeleteSubList(g_lCustomExceptions, iPos,iPos+2);
                        MenuCustomExceptionsSelect(kAv,iAuth);
                        
                        ApplyAllExceptions(FALSE,FALSE);
                    }
                } else if(sMenu == "Exceptions~AddCustomName"){
                    g_sTmpExceptionName=sMsg;
                    MenuAddCustomExceptionID(kAv,iAuth);
                } else if(sMenu == "Exceptions~AddCustomID"){
                    g_kTmpExceptionID = (key)sMsg;
                    llMessageLinked(LINK_SET,NOTIFY,"0Adding exception..", kAv);
                    g_lCustomExceptions += [g_sTmpExceptionName,g_kTmpExceptionID,0];
                    
                    Save(FALSE);
                    MenuSetExceptions(kAv, iAuth, "Custom");
                } else if (sMenu == "Exceptions~Set") {
                    if (sMsg == UPMENU) MenuExceptions(kAv,iAuth);
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
                            } else if(g_sExTarget == "Custom"){
                                integer iPos=llListFindList(g_lCustomExceptions, [g_sTmpExceptionName])+2;
                                integer iTmpBits = llList2Integer(g_lCustomExceptions, iPos);
                                // do stuff
                                if(iTmpBits & llList2Integer(lRLVEx,iIndex+2)) iTmpBits = iTmpBits ^ llList2Integer(lRLVEx,iIndex+2);
                                else iTmpBits = iTmpBits | llList2Integer(lRLVEx,iIndex+2);
                                
                                g_lCustomExceptions = llListReplaceList(g_lCustomExceptions, [iTmpBits], iPos, iPos);
                            }
                            ApplyAllExceptions(FALSE,FALSE);
                        }
                        MenuSetExceptions(kAv, iAuth, g_sExTarget);
                    }
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
        }else if(iNum == LM_SETTING_EMPTY){
            
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if(iNum == LM_SETTING_RESPONSE){
        // Detect here the Settings
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            
            
            //integer ind = llListFindList(g_lSettingsReqs, [sToken]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            
            if (sToken == "rlvext_mincamdist") {
                g_fMinCamDist = (float)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MinCamDist="+(string)g_fMinCamDist,kID);
            } else if(sToken == "rlvext_strict"){
                g_iStrictSit=(integer)sValue;
            } else if (sToken == "rlvext_maxcamdist") {
                g_fMaxCamDist = (float)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MaxCamDist="+(string)g_fMaxCamDist,kID);
            } else if (sToken == "rlvext_bluramount") {
                g_iBlurAmount = (integer)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"BlurAmount="+(string)g_iBlurAmount,kID);
            } else if (sToken == "rlvext_muffle") { 
                g_bMuffle = (integer)sValue;
                SetMuffle(g_bMuffle);
            } else if (sToken == "rlvext_owner") {
                if(g_iOwnerEx == (integer)sValue)return;
                g_iOwnerEx = (integer) sValue;
                
                if(g_iRLV)ApplyAllExceptions(TRUE,FALSE);
            } else if (sToken == "rlvext_trusted") {
                if(g_iTrustedEx==(integer)sValue)return;
                g_iTrustedEx = (integer) sValue;
                
                if(g_iRLV)ApplyAllExceptions(TRUE,FALSE);
                
            } else if(sToken == "rlvext_custom"){
                list lCustomExceptions = llParseString2List(sValue,["^"],[]);
                if(g_lCustomExceptions == lCustomExceptions)return;
                else g_lCustomExceptions = lCustomExceptions;
                
                if(g_iRLV)ApplyAllExceptions(TRUE,FALSE);
            }else if (llGetSubString(sToken, 0, i) == "auth_") {
                if (sToken == "auth_owner") {
                    list lOwners = llParseString2List(sValue, [","], []);
                    if(lOwners==g_lOwners)return;
                    else g_lOwners=lOwners;
                    if (g_iRLV) ApplyAllExceptions(TRUE,FALSE); // Only reapply when RLV is on.
                } else if (sToken == "auth_trust") {
                    list lSecOwners = llParseString2List(sValue, [","], []);
                    if(lSecOwners==g_lSecOwners)return;
                    else g_lSecOwners=lSecOwners;
                    if (g_iRLV) ApplyAllExceptions(TRUE,FALSE); // Only reapply when RLV is on.
                } else if (sToken == "auth_tempowner") {
                    list lTempOwners = llParseString2List(sValue, [","], []);
                    if(g_lTempOwners==lTempOwners)return;
                    else g_lTempOwners=lTempOwners;
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
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            
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
            if(sStr == "update_active")llResetScript();
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
            llResetScript();
        } else if(iNum == LINK_CMD_DEBUG){
            /// This will be changed to handle information differently..
            // TODO
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