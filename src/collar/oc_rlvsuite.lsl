// This file is part of OpenCollar.
//  Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue                            
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sScriptVersion = "7.4";

string g_sParentMenu = "RLV";
string g_sSubMenu = "Restrictions";



//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;


list g_lMaskData = ["Owner", 1, "Trusted", 2, "Group", 4, "Everyone", 8]; //<- todo: add CMD_OWNER, etc to this to allow the isAuthed function to use a one liner to return true or false.

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
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

string g_sSettingToken = "rlvsuite_";

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;

integer g_iRestrictions1 = 0;
integer g_iRestrictions2 = 0;

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}


// Default Macros will look like the old oc_rlvsuite Buttons
list g_lMacros = ["Hear", 4, 0, "Talk" , 2, 0, "Touch", 0, 16384, "Stray", 29360128, 524288, "Rummage", 1342179328, 131168, "Dress", 0, 15, "IM", 384, 0, "Daze", 323584, 0, "Dazzle", 0, 16777216];
integer g_lMaxMacros = 10;  // Maximum number of Macros allowed

string g_sTmpMacroName = "";
string g_sTmpRestName = "";

list g_lCategory = ["Chat","Show/Hide","Teleport","Misc","Edit/Mod","Interact","Movement","Camera","Outfit"];

list g_lUtilityMain = ["[Individual]","[Manage]","BACK"];
list g_lUtilityNone = ["BACK"];


list g_lRLVList = [   // ButtonText, CategoryIndex, RLVCMD, Auth
    "EmoteTrunc"    , 0 , "emote"                               , 15 ,   // 1
    "Send Chat"     , 0 , "sendchat"                            , 15 ,   // 2
    "See Chat"      , 0 , "recvchat"                            , 15 ,   // 3
    "See Emote"     , 0 , "recvemote"                           , 15 ,   // 4
    "Whisper"       , 0 , "chatwhisper"                         , 15 ,   // 5
    "Normal"        , 0 , "chatnormal"                          , 15 ,   // 6
    "Shout"         , 0 , "chatshout"                           , 15 ,   // 7
    "Send IM"       , 0 , "sendim"                              , 15 ,   // 8
    "See IM"        , 0 , "recvim"                              , 15 ,   // 9
    "Start IM"      , 0 , "startim"                             , 15 ,   // 10
    "Gesture"       , 0 , "sendgesture"                         , 15 ,   // 11
    "Inventory"     , 1 , "showinv"                             , 15 ,   // 12
    "Minimap"       , 1 , "showminimap"                         , 15 ,   // 13
    "Worldmap"      , 1 , "showworldmap"                        , 15 ,   // 14
    "Location"      , 1 , "showloc"                             , 15 ,   // 15
    "Names"         , 1 , "shownames"                           , 15 ,   // 16
    "Nametags"      , 1 , "shownametags"                        , 15 ,   // 17
    "Nearby"        , 1 , "shownearby"                          , 15 ,   // 18
    "Text"          , 1 , "showhovertext"                       , 15 ,   // 19
    "Text HUD"      , 1 , "showhovertexthud"                    , 15 ,   // 20
    "Text World"    , 1 , "showhovertextworld"                  , 15 ,   // 21
    "Text All"      , 1 , "showhovertextall"                    , 15 ,   // 22
    "Landmark"      , 2 , "tplm"                                , 15 ,   // 23
    "TP Location"   , 2 , "tploc"                               , 15 ,   // 24
    "Local"         , 2 , "tplocal"                             , 15 ,   // 25
    "Accept"        , 2 , "tplure"                              , 15 ,   // 26
    "Offer"         , 2 , "tprequest"                           , 15 ,   // 27
    "Accept Perm"   , 3 , "acceptpermission"                    , 15 ,   // 28
    "Edit"          , 4 , "edit"                                , 15 ,   // 29
    "Edit Object"   , 4 , "editobj"                             , 15 ,   // 30
    "Rez"           , 4 , "rez"                                 , 15 ,   // 31
    "Add Attach"    , 8 , "addattach"                           , 15 ,   // 32
    "Rem Attach"    , 8 , "remattach"                           , 15 ,   // 33
    "Add Cloth"     , 8 , "addoutfit"                           , 15 ,   // 34
    "Rem Cloth"     , 8 , "remoutfit"                           , 15 ,   // 35
    "Notecard"      , 4 , "viewnote"                            , 15 ,   // 36
    "Script"        , 4 , "viewscript"                          , 15 ,   // 37
    "Texture"       , 4 , "viewtexture"                         , 15 ,   // 38
    "Touch Far"     , 5 , "fartouch"                            , 15 ,   // 39
    "Interact"      , 5 , "interact"                            , 15 ,   // 40
    "Attachment"    , 5 , "touchattach"                         , 15 ,   // 41
    "Own Attach"    , 5 , "touchattachself"                     , 15 ,   // 42
    "Other Attach"  , 5 , "touchattachother"                    , 15 ,   // 43
    "HUD"           , 5 , "touchhud"                            , 15 ,   // 44
    "World"         , 5 , "touchworld"                          , 15 ,   // 45
    "All"           , 5 , "touchall"                            , 15 ,   // 46
    "Fly"           , 6 , "fly"                                 , 15 ,   // 47
    "Jump"          , 6 , "jump"                                , 15 ,   // 48
    "Stand Up"      , 6 , "unsit"                               , 15 ,   // 49
    "Sit Down"      , 6 , "sit"                                 , 15 ,   // 50
    "Sit TP"        , 6 , "sittp"                               , 15 ,   // 51
    "Stand TP"      , 6 , "standtp"                             , 15 ,   // 52
    "Always Run"    , 6 , "alwaysrun"                           , 15 ,   // 53
    "Temp Run"      , 6 , "temprun"                             , 15 ,   // 54
    "Unlock Cam"    , 7 , "camunlock"                           , 15 ,   // 55
    "Blur View"     , 7 , "setdebug_renderresolutiondivisor"    , 15 ,   // 56
    "MaxDistance"   , 7 , "setcam_avdistmax"                    , 15 ,   // 57
    "MinDistance"   , 7 , "setcam_avdistmin"                    , 15     // 58
//  "Idle"          , 3 , "allowidle"                           , 268435456 , 0         , CMD_EVERYONE ,   // 59  // Everything down here was ignored. There seem to be a Limit how
//  "Set Debug"     , 3 , "setdebug"                            , 536870912 , 0         , CMD_OWNER    ,   // 60  // big a lsl-list can go
//  "Environment"   , 3 , "setenv"                              , 1073741824, 0         , CMD_EVERYONE ,   // 61
//  "Mouselook"     , 7 , "camdistmax:0"                        , 0         , 67108864  , CMD_EVERYONE     // 62
];

integer g_iBlurAmount = 5;
float g_fMaxCamDist = 2.0;
float g_fMinCamDist = 1.0;
integer g_bForceMouselook = FALSE;

integer g_iRLV = FALSE;

list g_lMenuIDs;
integer g_iMenuStride;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    
    list lButtons = [];
    integer i;
    for (i=0; i<llGetListLength(g_lMacros);i=i+3) lButtons += llList2String(g_lMacros,i);
    
    Dialog(kID, "\n[Macros]\n \nClick on a Macro to see more Options.", lButtons, g_lUtilityMain, 0, iAuth, "Restrictions~Main");
}

MenuRestrictions(key kID, integer iAuth, integer iSetAccess){
    string sPrompt = "\n[Restriction Categories]\n";
    if (iSetAccess) {
        sPrompt += "\nSelect a Category to change access permissions:";
        Dialog(kID, sPrompt, g_lCategory, g_lUtilityNone, 0, iAuth, "Restrictions~AccesCategory");
    } else {
        sPrompt += "\nSelect a Category to set restrictions:";
        Dialog(kID, sPrompt, g_lCategory, ["[Clear All]","[Set Access]"]+g_lUtilityNone, 0, iAuth, "Restrictions~Restrictions");
    }
}

MenuCategory(key kID, integer iAuth, string sCategory, integer iSetAccess)
{
    string sPrompt = "\n[Category "+sCategory+"]";
    if (iSetAccess) sPrompt += "\n \n Choose a restriction to change access permissions:";
    
    integer iCatIndex = llListFindList(g_lCategory,[sCategory]);
    
    list lMenu = [];
    integer i;
    
    for(i=0; i<llGetListLength(g_lRLVList); i+= 4){
        if(llList2Integer(g_lRLVList,i+1) == iCatIndex){
            
            if(iSetAccess) lMenu+= [llList2String(g_lRLVList,i)];
            else {
                integer Flag1 = llRound(llPow(2,(i/4)));
                integer Flag2 = 0;
                if((i/4)>=31){
                    Flag1=0;
                    Flag2 = llRound(llPow(2, (i/4)-30));
                }
                if(isAuthed(llList2Integer(g_lRLVList,i+3), iAuth)){
                    if((g_iRestrictions1 & Flag1) || (g_iRestrictions2 & Flag2)) lMenu+= [Checkbox(TRUE, llList2String(g_lRLVList, i))];
                    else lMenu += [Checkbox(FALSE, llList2String(g_lRLVList,i))];
                }else {
                }
            }
        }
    }
    if (iSetAccess) Dialog(kID, sPrompt, lMenu, g_lUtilityNone, 0, iAuth, "Restrictions~Access");
    else Dialog(kID, sPrompt, lMenu, g_lUtilityNone, 0, iAuth, "Restrictions~Category");
}

MenuSetAccess(key kID, integer iAuth, string sCommand)
{
    list lButtons = [];
    integer iIndex = llListFindList(g_lRLVList,[sCommand]);
    if (iIndex > -1) {
        g_sTmpRestName = sCommand;
        integer iCurrentAuth = llList2Integer(g_lRLVList,iIndex+3);
        
        lButtons = [Checkbox(bool((iCurrentAuth&2)), "Trusted"), Checkbox(bool((iCurrentAuth&4)), "Group"), Checkbox(bool((iCurrentAuth&8)), "Everyone")];
    }
    Dialog(kID, "Set who will have access to '"+sCommand+"'", lButtons, g_lUtilityNone, 0, iAuth, "Restrictions~SetPerm");
}

MenuDelete(key kID, integer iAuth)
{
    if (iAuth == CMD_OWNER || iAuth == CMD_WEARER){
        list lButtons = [];
        integer i;
        for (i=0; i<llGetListLength(g_lMacros);i=i+3)
        {
            lButtons += llList2String(g_lMacros,i);
        }
        Dialog(kID, "Select a Macro you want to delete:", lButtons, g_lUtilityNone, 0, iAuth, "Restrictions~Delete");
    } else {
        llMessageLinked(LINK_SET, NOTIFY, "0"+"Acces Denied!", kID);
        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kID);
    }
}
/*
integer CheckPermissions(integer iMask1, integer iMask2, key kID, integer iAuth)
{
    list lDenied = [];
    integer iMax1 = 1073741824;
    integer iMax2 = 1073741824;
    while (iMax1 > 0) {
        integer iIndex = llListFindList(g_lRLVList, [iMax1,0])-1;
        if (iIndex > -1 && iMax1 & iMask1 && ((llList2Integer(g_lRLVList,iIndex+3) < iAuth) || iAuth == CMD_WEARER)) lDenied += [llList2String(g_lRLVList,iIndex-2)];
        iMax1 = iMax1 >> 1;
    }
    
    while (iMax2 > 0) {
        integer iIndex = llListFindList(g_lRLVList, [0,iMax2])-1;
        if (iIndex > -1 && iMax2 & iMask2 &&((llList2Integer(g_lRLVList,iIndex+3) < iAuth) || iAuth == CMD_WEARER)) lDenied += [llList2String(g_lRLVList,iIndex-2)];
        iMax2 = iMax2 >> 1;
    }
    
    if (llGetListLength(lDenied) > 0){
        llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS% to change restrictions:\n "+llDumpList2String(lDenied,", "),kID);
        return FALSE;
    } else return TRUE;
}
*/
list bitpos (integer flag1,integer flag2){
    list ret=[0,0];
    
    if(flag1>0){
        ret=llListReplaceList(ret,[llRound(llLog10(flag1)/llLog10(2))],0,0);
    }
    
    if(flag2>0){
        ret = llListReplaceList(ret,[llRound(llLog10(flag2)/llLog10(2))],1,1);
    }
    
    
    return ret;
}
integer isAuthed(integer Flag, integer iAuth){   ///// TODO: Modify the MaskData to include the iAuth value to make this easier on memory with a one liner
    
    if(Flag&1 && iAuth==CMD_OWNER)return TRUE;
    if(Flag&2 && iAuth==CMD_TRUSTED)return TRUE;
    if(Flag&4 && iAuth == CMD_GROUP)return TRUE;
    if(Flag&8 && iAuth == CMD_EVERYONE)return TRUE;
    
    return FALSE;
}

integer CheckPermissions(integer iMask1, integer iMask2, key kID, integer iAuth){
    list lDenied=[];
    integer iMax1 = 1073741824;
    integer iMax2 = iMax1;
    //integer iIndex2 = (llList2Integer(lIndex,1)*4)+30;
    
    while(iMax1>0){
        
        list lIndex = bitpos(iMax1,0);
    
        integer iIndex = llList2Integer(lIndex,0)*4;
        if(iIndex>-1 && iMax1 & iMask1 && (!isAuthed(llList2Integer(g_lRLVList, iIndex+3), iAuth) || iAuth==CMD_WEARER))lDenied+= llList2String(g_lRLVList,iIndex);
        iMax1=iMax1>>1;
    }
    
    while(iMax2 >0){
        list lIndex=bitpos(0,iMax2);
        integer iIndex = (llList2Integer(lIndex,1)+30)*4;
        if(iIndex>-1 && iMax2 & iMask2 && (!isAuthed(llList2Integer(g_lRLVList, iIndex+3), iAuth) || iAuth == CMD_WEARER))lDenied+= llList2String(g_lRLVList,iIndex);
        iMax2=iMax2>>1;
    }
    
    if(llGetListLength(lDenied)>0){
        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to change the following:\n \n"+llList2CSV(lDenied), kID);
        return FALSE;
    }
    return TRUE;
}
        
        
string FormatCommand(string sCommand,integer bEnable)
{
    string sMod;
    if (bEnable) sMod = "=n";
    else sMod = "=y";
    
    if (sCommand == "setdebug_renderresolutiondivisor") {
        if (bEnable) sMod = ":"+(string)g_iBlurAmount+"=force";
        else sMod = ":1=force";
    } else if (sCommand == "setcam_avdistmax" && !g_bForceMouselook) {
        sCommand += ":"+(string)g_fMaxCamDist;
    } else if (sCommand == "setcam_avdistmin" && !g_bForceMouselook) {
        sCommand += ":"+(string)g_fMinCamDist;
    } else if ((sCommand == "setcam_avdistmax" || sCommand == "setcam_avdistmin") && g_bForceMouselook) {
        sCommand = "camdistmax:0";
    } else if (sCommand == "camdistmax:0"){
        if (bEnable) g_bForceMouselook = TRUE;
        else g_bForceMouselook = FALSE;
    }
       
    //llOwnerSay("Restriction '"+sCommand+"' has changed, sending message");
    llMessageLinked(LINK_SET, LINK_CMD_RESTRICTIONS,sCommand+"="+(string)bEnable+"=-1","");
    
    return sCommand+sMod;
}

ApplyAll(integer iMask1, integer iMask2, integer iBoot)
{
    list lResult = [];
    integer iMax1 = 1073741824;
    integer iMax2 = 1073741824;
    while (iMax1 > 0) {
        list pos = bitpos(iMax1, 0);
        integer iIndex = (llList2Integer(pos,0)*4)+2;
        
        
        if (iIndex > -1 && bool(iMax1 & iMask1) != bool(iMax1 & g_iRestrictions1)) {
            lResult += [FormatCommand(llList2String(g_lRLVList,iIndex), bool(iMax1 & iMask1))];
           // llSay(0, "lRLVListPart1.\npos: "+(string)pos+"\niIndex: "+(string)iIndex+"\nlResult[-1]: "+llList2String(lResult,-1));
        }
        iMax1 = iMax1 >> 1;
    }
    
    while (iMax2 > 0) {
        list pos = bitpos(0,iMax2);
        integer iIndex = ((llList2Integer(pos,1)+30)*4)+2;
        if (iIndex > -1 && bool(iMax2 & iMask2) != bool(iMax2 & g_iRestrictions2)) {
            lResult += [FormatCommand(llList2String(g_lRLVList,iIndex),bool(iMax2 & iMask2))];
          //  llSay(0, "lRLVListPart2.\npos: "+(string)pos+"\niIndex: "+(string)iIndex+"\nlResult[-1]: "+llList2String(lResult,-1));
        }
        iMax2 = iMax2 >> 1;
        
        
    }
    
    
    string sCommandList = llDumpList2String(lResult,",");
    lResult=[];

    llMessageLinked(LINK_SET,RLV_CMD,sCommandList,"Macros");
    g_iRestrictions1 = iMask1;
    g_iRestrictions2 = iMask2;
    
    if(!iBoot){
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_masks=" + (string)g_iRestrictions1+","+(string)g_iRestrictions2, "");
    }
}

ApplyCommand(string sCommand, integer iAdd,key kID, integer iAuth)
{
    //llSay(0, "Apply CMD");
    integer iMenuIndex = llListFindList(g_lRLVList,[sCommand]);
    integer iActualIndex=iMenuIndex;
    integer iMenuIndex2;
    if(iMenuIndex/4>=31){
        iMenuIndex2 =(integer) llPow(2, (iMenuIndex/4)-30);
        iMenuIndex=0;
    }else {
        iMenuIndex2=0;
        iMenuIndex = (integer)llPow(2, iMenuIndex/4);
    }
    
    if (iActualIndex > -1) {
        integer authbit = llList2Integer(g_lRLVList, iActualIndex+3);
        integer allow=FALSE;
        if(isAuthed(authbit,iAuth))allow=TRUE;
        
        if (allow){
            if (!iAdd) {
                if(iMenuIndex==0){
                    if(!(g_iRestrictions2 & iMenuIndex2)){
                        // STOP
                        //llSay(0, "BIT NOT SET. REFUSE TO LIFT NON_EXISTING RESTRICTION");
                        return;
                    }
                } else if(iMenuIndex2 ==0){
                    if(!(g_iRestrictions1 & iMenuIndex)){
                        //STOP
                        //llSay(0, "BIT NOT SET. REFUSE TO LIFT NON_EXISTING RESTRICTION");
                        return;
                    }
                }
                g_iRestrictions1 -= iMenuIndex;
                g_iRestrictions2 -= iMenuIndex2;
                
                llMessageLinked(LINK_SET,RLV_CMD,FormatCommand(llList2String(g_lRLVList,iActualIndex+2),FALSE),"Macros");
                if (kID != NULL_KEY) llOwnerSay(llList2String(g_lCategory, llList2Integer(g_lRLVList,iActualIndex+1))+" - "+llList2String(g_lRLVList,iActualIndex)+" is not restricted anymore!");
            } else {
                
                if(iMenuIndex==0){
                    if((g_iRestrictions2 & iMenuIndex2)){
                        // STOP
                        //llSay(0, "BIT SET. REFUSE EXISTING RESTRICTION");
                        return;
                    }
                } else if(iMenuIndex2 ==0){
                    if((g_iRestrictions1 & iMenuIndex)){
                        //STOP
                        //llSay(0, "BIT SET. REFUSE EXISTING RESTRICTION");
                        return;
                    }
                }
                g_iRestrictions1 += iMenuIndex;
                g_iRestrictions2 += iMenuIndex2;
                
                llMessageLinked(LINK_SET,RLV_CMD,FormatCommand(llList2String(g_lRLVList,iActualIndex+2),TRUE),"Macros");
                if (kID != NULL_KEY) llOwnerSay(llList2String(g_lCategory, llList2Integer(g_lRLVList,iActualIndex+1))+" - "+llList2String(g_lRLVList,iActualIndex)+" is now restricted!");
            }
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_masks=" + (string)g_iRestrictions1+","+(string)g_iRestrictions2, "");
        } else if (kID != NULL_KEY) llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS% to change '"+llList2String(g_lCategory, llList2Integer(g_lRLVList,iActualIndex+1))+" - "+llList2String(g_lRLVList,iActualIndex)+"'", kID);
    }
}


AuthSetting(string sAuthSetting){
    
    if (sAuthSetting == ""){ // Save last numbers of restriction auth
        integer i;
        list lAuthSetting;
        for (i=3; i<llGetListLength(g_lRLVList);i+=4){
            lAuthSetting += (string)(llList2Integer(g_lRLVList,i));
        }
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_auths="+llDumpList2String(lAuthSetting, "/"), "");
    } else { // restore restriction auths from string
        integer i;
        integer num = 0;
        list lAuthSetting = llParseStringKeepNulls(sAuthSetting, ["/"],[]);
        for (i=3; i<llGetListLength(g_lRLVList);i+=4){
            integer iNewAuth = ((integer)llList2String(lAuthSetting,num));
            g_lRLVList = llListReplaceList(g_lRLVList, [iNewAuth], i,i);
            ++num;
        }
    }
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
    if (llSubStringIndex(sStr,"macro") && llSubStringIndex(sStr,"restriction") && llSubStringIndex(sStr,"restrictions") && llSubStringIndex(sStr,"sit") && sStr != "menu "+g_sSubMenu && sStr != "menu ") return;
    if (sStr=="macro" || sStr == "menu "+g_sSubMenu) Menu(kID, iNum);
    else { 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangekey = llList2String(llParseString2List(sStr, [" "], []),1);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),2);
        
        if (sChangetype == "macro") {
            integer iIndex = llListFindList(g_lMacros,[sChangevalue]);
            if (iIndex > -1) {
                if (CheckPermissions(llList2Integer(g_lMacros,iIndex+1),llList2Integer(g_lMacros,iIndex+2),kID,iNum)){
                    if (sChangekey == "add") {
                        llMessageLinked(LINK_SET, NOTIFY, "0"+"Macro Added: '"+sChangevalue+"'", kID);
                        ApplyAll(g_iRestrictions1 | llList2Integer(g_lMacros,iIndex+1),g_iRestrictions2 | llList2Integer(g_lMacros,iIndex+2),FALSE);
                        llOwnerSay("Macro '"+llList2String(g_lMacros,iIndex)+"' has been added!");
                    } else if (sChangekey == "replace") {
                        llMessageLinked(LINK_SET, NOTIFY, "0"+"Replaced restrictions with Macro '"+sChangevalue+"'", kID);
                        ApplyAll(llList2Integer(g_lMacros,iIndex+1),llList2Integer(g_lMacros,iIndex+2),FALSE);
                        llOwnerSay("Macro '"+llList2String(g_lMacros,iIndex)+"' replaced your Restrictions!");
                    } else if (sChangekey == "clear") {
                        llMessageLinked(LINK_SET, NOTIFY, "0"+"Macro cleared '"+sChangevalue+"'", kID);
                        ApplyAll(g_iRestrictions1 ^ (g_iRestrictions1 & llList2Integer(g_lMacros,iIndex+1)),g_iRestrictions2 ^ (g_iRestrictions2 & llList2Integer(g_lMacros,iIndex+2)),FALSE);
                        llOwnerSay("Macro '"+llList2String(g_lMacros,iIndex)+"' has been cleared!");
                    }
                } else llMessageLinked(LINK_SET, NOTIFY, "0"+"Macro not applied!", kID);
            } else llInstantMessage(kID,"Macro '"+sChangevalue+"' does not exist!");
        } else if (sChangetype == "restriction" || sChangetype == "rlv") {
            if (sChangekey == "add") ApplyCommand(sChangevalue,TRUE, kID, iNum);
            else if (sChangekey == "rem" && iNum != CMD_WEARER) ApplyCommand(sChangevalue,FALSE, kID, iNum);
        } else if (sChangetype == "restrictions") Menu(kID,iNum);
    }
}


default
{
    state_entry()
    {
//        llScriptProfiler(TRUE);
        if(llGetStartParameter()!=0)state inUpdate;
        g_iRLV = FALSE;
//        llSetTimerEvent(1);
    }
    
    on_rez(integer iRez){
        // Restrictions are likely not applied at the moment, reinit the variables
        llResetTime();
        llSetTimerEvent(1);
    }
    
    timer(){
        if(llGetTime()>=20){
            g_iRestrictions1=0;
            g_iRestrictions2=0;
            llSetTimerEvent(0);
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
        }
    }
        
    link_message(integer iSender,integer iNum,string sStr,key kID){
       // llOwnerSay(llDumpList2String([iSender, iNum, llGetSPMaxMemory(), llGetFreeMemory()], " ^ "));
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");  // Register menu "Restrictions"
        } else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                //llOwnerSay("Memory Free: "+(string)llGetFreeMemory());
                //llOwnerSay("Memory Used: "+(string)llGetUsedMemory());
                
                
                if(sMenu == "Restrictions~Main"){ 
                    if(sMsg == "BACK") llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else if (sMsg == "[Manage]") Dialog(kAv, "Select an Option:\n \nSave As: Save current restrictions into a Macro\nDelete: Delete a Macro", ["Save As","Delete"], g_lUtilityNone, 0, iAuth, "Restrictions~Manage");
                    else if(sMsg == "[Individual]") {
                       MenuRestrictions(kAv,iAuth,FALSE);
                    } else {
                        integer iIndex = llListFindList(g_lMacros,[sMsg]);
                        if (iIndex > -1) {
                            g_sTmpMacroName = sMsg;
                            Dialog(kAv, "What do you want to do with that macro?", ["Add","Replace","Clear"], g_lUtilityNone, 0, iAuth, "Restrictions~Options");
                        }
                    }
                } else if (sMenu == "Restrictions~Manage"){
                    if (sMsg == "Save As") {
                        if (iAuth == CMD_WEARER || iAuth == CMD_OWNER) {
                            Dialog(kAv, "Enter the name of the new Macro:", [], [], 0, iAuth,"Restrictions~textbox");
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                            llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                        }
                    } else if (sMsg == "Delete") MenuDelete(kAv, iAuth);
                      else if (sMsg == "BACK") Menu(kAv, iAuth);
                } else if (sMenu == "Restrictions~Restrictions"){
                    if(sMsg == "BACK") Menu(kAv,iAuth);
                    else if (sMsg == "[Set Access]") {
                        if (iAuth == CMD_OWNER) MenuRestrictions(kAv, iAuth, TRUE);
                        else {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                            MenuRestrictions(kAv, iAuth, FALSE);
                        }
                    } else if (sMsg == "[Clear All]") {
                        if (iAuth != CMD_WEARER && CheckPermissions(g_iRestrictions1,g_iRestrictions2,kAv,iAuth)) {
                            ApplyAll(0,0, FALSE);
                            MenuRestrictions(kAv, iAuth, FALSE);
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                            MenuRestrictions(kAv, iAuth, FALSE);
                        }
                    }
                    else MenuCategory(kAv, iAuth, sMsg, FALSE);
                } else if (sMenu == "Restrictions~AccesCategory") {
                    if (sMsg == "BACK") MenuRestrictions(kAv, iAuth, FALSE);
                    else MenuCategory(kAv, iAuth, sMsg, TRUE);
                } else if (sMenu == "Restrictions~Category"){
                    if(sMsg == "BACK") MenuRestrictions(kAv,iAuth,FALSE);
                    else {
                        sMsg = llGetSubString( sMsg, 2, -1);
                        integer iMenuIndex = llListFindList(g_lRLVList,[sMsg]);
                        integer iMenuIndex2=0;
                        if(iMenuIndex/4 >=31){
                            iMenuIndex2 = (iMenuIndex/4)-30;
                            iMenuIndex=0;
                        } else {
                            iMenuIndex /= 4;
                        }
                        
                        if (iMenuIndex > -1) {
                            if (g_iRestrictions1 & (integer)llPow(2,iMenuIndex) || g_iRestrictions2 & (integer)llPow(2,iMenuIndex2)) {
                                if (iAuth != CMD_WEARER) ApplyCommand(sMsg,FALSE,kAv, iAuth);
                                else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS%", kAv);
                            } else {
                                ApplyCommand(sMsg,TRUE,kAv,iAuth);
                            }
                            MenuCategory(kAv, iAuth, llList2String(g_lCategory, llList2Integer(g_lRLVList,llListFindList(g_lRLVList,[sMsg])+1)),FALSE);
                        }
                    }
                } else if (sMenu == "Restrictions~Access") {
                    if(sMsg == "BACK") MenuRestrictions(kAv,iAuth,TRUE);
                    else{
                        integer iMenuIndex = llListFindList(g_lRLVList,[sMsg]);
                        if (iMenuIndex > -1) MenuSetAccess(kAv, iAuth, sMsg);
                    }
                } else if (sMenu == "Restrictions~SetPerm") {
                    if (sMsg == "BACK") MenuRestrictions(kAv,iAuth,TRUE);
                    else {
                        integer iIndex = llListFindList(g_lRLVList,[g_sTmpRestName]);
                        if (iIndex > -1) {
                            string sLabel = llGetSubString( sMsg, 2, -1);
                            integer mask = llList2Integer(g_lRLVList, iIndex+3);
                            integer ipos= llListFindList(g_lMaskData, [sLabel]);
                            integer maskData = llList2Integer(g_lMaskData, ipos+1);
                            
                            if(llGetSubString(sMsg,0,0) == llList2String(g_lCheckboxes,TRUE)){
                                mask -= maskData;
                            }else{
                                mask += maskData;
                            }
                            
                            if(mask<0)mask=15;
                            if(!(mask&1))mask+=1;
                            g_lRLVList = llListReplaceList(g_lRLVList, [mask], iIndex+3, iIndex+3);
                            
                            AuthSetting("");
                        }
                        MenuSetAccess(kAv, iAuth, g_sTmpRestName);
                    }
                } else if (sMenu == "Restrictions~textbox") {
                
                    if (llListFindList(g_lMacros,[sMsg]) > -1) {
                        g_sTmpMacroName = sMsg;
                        Dialog(kAv, "A Macro named '"+sMsg+"' does already exist!\n \nDo you want to override it?", ["YES","NO"], g_lUtilityNone, 0, iAuth, "Restrictions~Override");
                    } else {
                        if (llGetListLength(g_lMacros)/3 >= g_lMaxMacros) Dialog(kAv, "You have already created the maximum amount of macros!", ["OK"], g_lUtilityNone, 0, iAuth, "Restrictions~MaxMacro");
                        else {
                            sMsg = llGetSubString(sMsg,0,11);
                            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, [" "], []), "_");
                            g_lMacros += [sMsg, g_iRestrictions1, g_iRestrictions2];
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                            Menu(kAv,iAuth);
                        }
                    }
                } else if (sMenu == "Restrictions~MaxMacro") Menu(kAv,iAuth);
                else if (sMenu == "Restrictions~Override"){
                    if (sMsg == "YES"){
                        integer iIndex = llListFindList(g_lMacros,[g_sTmpMacroName]);
                        g_lMacros = llListReplaceList(g_lMacros, [g_sTmpMacroName,g_iRestrictions1,g_iRestrictions2], iIndex, iIndex+2);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                        Menu(kAv,iAuth);
                    } else Dialog(kAv, "Enter the name of the new Macro:", [], [], 0, iAuth,"Restrictions~textbox");
                } else if (sMenu == "Restrictions~Delete"){
                    if (iAuth <= CMD_TRUSTED){
                        integer iIndex = llListFindList(g_lMacros,[sMsg]);
                        if (iIndex > -1) {
                            g_lMacros = llDeleteSubList(g_lMacros,iIndex, iIndex+2);
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                            Menu(kAv,iAuth);
                        } else Menu(kAv,iAuth);
                    } else {
                        llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                } else if (sMenu == "Restrictions~Options") {
                    integer iIndex = llListFindList(g_lMacros,[g_sTmpMacroName]);
                    if (iIndex > -1) UserCommand(iAuth, "macro "+llToLower(sMsg)+" "+g_sTmpMacroName, kAv);
                    Menu(kAv,iAuth);
                }
            }
        } else if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            if (llList2String(lParams, 0) == "rlvsuite_masks") {
                list lMasks = llParseString2List(llList2String(lParams, 1),[","],[]);
                if (g_iRLV) { // bad timing, RLV_ON was already called
                    integer iMask1 =  (integer)llList2String(lMasks, 0);
                    integer iMask2 = (integer)llList2String(lMasks, 1);
                    g_iRestrictions1 = 0;
                    g_iRestrictions2 = 0;
                    ApplyAll(iMask1,iMask2,TRUE);
                } else { // Just save the masks, they will be applied when RLV_ON or RLV_REFRESH is received
                    g_iRestrictions1 = llList2Integer(lMasks, 0);
                    g_iRestrictions2 = llList2Integer(lMasks, 1);
                }
            } else if (llList2String(lParams, 0) == "rlvsuite_macros") g_lMacros = llParseStringKeepNulls(llList2String(lParams, 1), ["^"],[]);
            else if (llList2String(lParams, 0) == "rlvsuite_auths") AuthSetting(llList2String(lParams, 1));
            else if(llList2String(lParams,0) == "global_checkboxes") g_lCheckboxes = llCSV2List(llList2String(lParams,1));
        } else if (iNum == CMD_SAFEWORD || iNum == RLV_CLEAR || iNum == RLV_OFF){
            g_iRLV = FALSE;
            ApplyAll(0,0,FALSE);
        } else if (iNum == RLV_REFRESH || iNum == RLV_ON) {
            g_iRLV = TRUE;
            integer iMask1 = g_iRestrictions1;
            integer iMask2 = g_iRestrictions2;
            g_iRestrictions1 = 0;
            g_iRestrictions2 = 0;
            ApplyAll(iMask1,iMask2,TRUE);
        } else if (iNum == REBOOT && sStr == "reboot") {
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
            if (llList2Integer(lCMD,2) > -1) ApplyCommand(llList2String(lCMD,0),llList2Integer(lCMD,1),kID,llList2Integer(lCMD,2));
        } else if (iNum == LINK_CMD_RESTDATA) {
            list lCMD = llParseString2List(sStr, ["="], []);
            if (llList2String(lCMD,0) == "BlurAmount") {
                integer bWasTrue = g_iRestrictions2 & 16777216;
                if (bWasTrue) ApplyCommand("Blur View",FALSE, NULL_KEY, 0);
                g_iBlurAmount = llList2Integer(lCMD,1);
                if (bWasTrue) ApplyCommand("Blur View",TRUE, NULL_KEY, 0);
            } else if (llList2String(lCMD,0) == "MaxCamDist") {
                integer bWasTrue = g_iRestrictions2 & 33554432;
                if (bWasTrue) ApplyCommand("MaxDistance",FALSE, NULL_KEY, 0);
                g_fMaxCamDist = llList2Float(lCMD,1);
                if (bWasTrue) ApplyCommand("MaxDistance",TRUE, NULL_KEY, 0);
            } else if (llList2String(lCMD,0) == "MinCamDist") { 
                integer bWasTrue = g_iRestrictions2 & 67108864;
                if (bWasTrue) ApplyCommand("MinDistance",FALSE, NULL_KEY, 0);
                g_fMinCamDist = llList2Float(lCMD,1);
                if (bWasTrue) ApplyCommand("MinDistance",TRUE, NULL_KEY, 0);
            }
        }
    }
    
}
state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
    }
}
