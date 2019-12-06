// This file is part of OpenCollar.
//  Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue                            
// Licensed under the GPLv2.  See LICENSE for full details. 

// Licensed under the GPLv2. See LICENSE for full details.

string g_sScriptVersion = "7.3";

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

integer NOTIFY = 1002;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
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

string g_sChecked = "☑";
string g_sUnChecked = "☐";

// Default Macros will look like the old oc_rlvsuite Buttons
list g_lMacros = ["Hear", 4, 0, "Talk" , 2, 0, "Touch", 0, 16384, "Stray", 29360128, 524288, "Rummage", 1342179328, 131168, "Dress", 0, 15, "IM", 384, 0, "Daze", 323584, 0, "Dazzle", 0, 16777216];
integer g_lMaxMacros = 10;  // Maximum number of Macros allowed

string g_sTmpMacroName = "";
string g_sTmpRestName = "";

list lCategory = ["Chat","Show/Hide","Teleport","Misc","Edit/Mod","Interact","Movement","Camera","Outfit"];

list lUtilityMain = ["[Individual]","[Manage]","BACK"];
list lUtilityNone = ["BACK"];


list lRLVList = [   // ButtonText, CategoryIndex, RLVCMD, bitmask1, bitmask2, Auth
    "Emote"         , 0 , "emote"                               , 1         , 0         , CMD_EVERYONE ,  // 1
    "Send Chat"     , 0 , "sendchat"                            , 2         , 0         , CMD_EVERYONE ,   // 2
    "See Chat"      , 0 , "recvchat"                            , 4         , 0         , CMD_EVERYONE ,   // 3
    "See Emote"     , 0 , "recvemote"                           , 8         , 0         , CMD_EVERYONE ,   // 4
    "Whisper"       , 0 , "chatwhisper"                         , 16        , 0         , CMD_EVERYONE ,   // 5
    "Normal"        , 0 , "chatnormal"                          , 32        , 0         , CMD_EVERYONE ,   // 6
    "Shout"         , 0 , "chatshout"                           , 64        , 0         , CMD_EVERYONE ,   // 7
    "Send IM"       , 0 , "sendim"                              , 128       , 0         , CMD_EVERYONE ,   // 8
    "See IM"        , 0 , "recvim"                              , 256       , 0         , CMD_EVERYONE ,   // 9
    "Start IM"      , 0 , "startim"                             , 512       , 0         , CMD_EVERYONE ,   // 10
    "Gesture"       , 0 , "sendgesture"                         , 1024      , 0         , CMD_EVERYONE ,   // 11
    "Inventory"     , 1 , "showinv"                             , 2048      , 0         , CMD_EVERYONE ,   // 12
    "Minimap"       , 1 , "showminimap"                         , 4096      , 0         , CMD_EVERYONE ,   // 13
    "Worldmap"      , 1 , "showworldmap"                        , 8192      , 0         , CMD_EVERYONE ,   // 14
    "Location"      , 1 , "showloc"                             , 16384     , 0         , CMD_EVERYONE ,   // 15
    "Names"         , 1 , "shownames"                           , 32768     , 0         , CMD_EVERYONE ,   // 16
    "Nametags"      , 1 , "shownametags"                        , 65536     , 0         , CMD_EVERYONE ,   // 17
    "Nearby"        , 1 , "shownearby"                          , 131072    , 0         , CMD_EVERYONE ,   // 18
    "Text"          , 1 , "showhovertext"                       , 262144    , 0         , CMD_EVERYONE ,   // 19
    "Text HUD"      , 1 , "showhovertexthud"                    , 524288    , 0         , CMD_EVERYONE ,   // 20
    "Text World"    , 1 , "showhovertextworld"                  , 1048576   , 0         , CMD_EVERYONE ,   // 21
    "Text All"      , 1 , "showhovertextall"                    , 2097152   , 0         , CMD_EVERYONE ,   // 22
    "Landmark"      , 2 , "tplm"                                , 4194304   , 0         , CMD_EVERYONE ,   // 23
    "TP Location"   , 2 , "tploc"                               , 8388608   , 0         , CMD_EVERYONE ,   // 24
    "Local"         , 2 , "tplocal"                             , 16777216  , 0         , CMD_EVERYONE ,   // 25
    "Accept"        , 2 , "tplure"                              , 33554432  , 0         , CMD_EVERYONE ,   // 26
    "Offer"         , 2 , "tprequest"                           , 67108864  , 0         , CMD_EVERYONE ,   // 27
    "Accept Perm"   , 3 , "acceptpermission"                    , 134217728 , 0         , CMD_EVERYONE ,   // 28
    "Edit"          , 4 , "edit"                                , 268435456 , 0         , CMD_EVERYONE ,   // 29
    "Edit Object"   , 4 , "editobj"                             , 536870912 , 0         , CMD_EVERYONE ,   // 30
    "Rez"           , 4 , "rez"                                 , 1073741824, 0         , CMD_EVERYONE ,   // 31
    "Add Attach"    , 8 , "addattach"                           , 0         , 1         , CMD_EVERYONE ,   // 32
    "Rem Attach"    , 8 , "remattach"                           , 0         , 2         , CMD_EVERYONE ,   // 33
    "Add Cloth"     , 8 , "addoutfit"                           , 0         , 4         , CMD_EVERYONE ,   // 34
    "Rem Cloth"     , 8 , "remoutfit"                           , 0         , 8         , CMD_EVERYONE ,   // 35
    "Notecard"      , 4 , "viewnote"                            , 0         , 16        , CMD_EVERYONE ,   // 36
    "Script"        , 4 , "viewscript"                          , 0         , 32        , CMD_EVERYONE ,   // 37
    "Texture"       , 4 , "viewtexture"                         , 0         , 64        , CMD_EVERYONE ,   // 38
    "Touch Far"     , 5 , "fartouch"                            , 0         , 128       , CMD_EVERYONE ,   // 39
    "Interact"      , 5 , "interact"                            , 0         , 256       , CMD_EVERYONE ,   // 40
    "Attachment"    , 5 , "touchattach"                         , 0         , 512       , CMD_EVERYONE ,   // 41
    "Own Attach"    , 5 , "touchattachself"                     , 0         , 1024      , CMD_EVERYONE ,   // 42
    "Other Attach"  , 5 , "touchattachother"                    , 0         , 2048      , CMD_EVERYONE ,   // 43
    "HUD"           , 5 , "touchhud"                            , 0         , 4096      , CMD_EVERYONE ,   // 44
    "World"         , 5 , "touchworld"                          , 0         , 8192      , CMD_EVERYONE ,   // 45
    "All"           , 5 , "touchall"                            , 0         , 16384     , CMD_EVERYONE ,   // 46
    "Fly"           , 6 , "fly"                                 , 0         , 32768     , CMD_EVERYONE ,   // 47
    "Jump"          , 6 , "jump"                                , 0         , 65536     , CMD_EVERYONE ,   // 48
    "Stand Up"      , 6 , "unsit"                               , 0         , 131072    , CMD_EVERYONE ,   // 49
    "Sit Down"      , 6 , "sit"                                 , 0         , 262144    , CMD_EVERYONE ,   // 50
    "Sit TP"        , 6 , "sittp"                               , 0         , 524288    , CMD_EVERYONE ,   // 51
    "Stand TP"      , 6 , "standtp"                             , 0         , 1048576   , CMD_EVERYONE ,   // 52
    "Always Run"    , 6 , "alwaysrun"                           , 0         , 2097152   , CMD_EVERYONE ,   // 53
    "Temp Run"      , 6 , "temprun"                             , 0         , 4194304   , CMD_EVERYONE ,   // 54
    "Unlock Cam"    , 7 , "camunlock"                           , 0         , 8388608   , CMD_OWNER    ,   // 55
    "Blur View"     , 7 , "setdebug_renderresolutiondivisor"    , 0         , 16777216  , CMD_EVERYONE ,   // 56
    "MaxDistance"   , 7 , "setcam_avdistmax"                    , 0         , 33554432  , CMD_EVERYONE ,   // 57
    "MinDistance"   , 7 , "setcam_avdistmin"                    , 0         , 67108864  , CMD_EVERYONE     // 58
//  "Idle"          , 3 , "allowidle"                           , 268435456 , 0         , CMD_EVERYONE ,   // 59  // Everything down here was ignored. There seem to be a Limit how
//  "Set Debug"     , 3 , "setdebug"                            , 536870912 , 0         , CMD_OWNER    ,   // 60  // big a lsl-list can go
//  "Environment"   , 3 , "setenv"                              , 1073741824, 0         , CMD_EVERYONE ,   // 61
//  "Mouselook"     , 7 , "camdistmax:0"                        , 0         , 67108864  , CMD_EVERYONE     // 62
];

integer g_iBlurAmount = 5;
float g_fMaxCamDist = 2.0;
float g_fMinCamDist = 1.0;
integer g_bForceMouselook = FALSE;


list g_lMenuIDs;
integer g_iMenuStride;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    
    list lButtons = [];
    integer i;
    for (i=0; i<llGetListLength(g_lMacros);i=i+3) lButtons += llList2String(g_lMacros,i);
    
    Dialog(kID, "\n[Macros]\n \nClick on a Macro to see more Options.", lButtons, lUtilityMain, 0, iAuth, "Restrictions~Main");
}

MenuRestrictions(key kID, integer iAuth, integer iSetAccess){
    string sPrompt = "\n[Restriction Categories]\n";
    if (iSetAccess) {
        sPrompt += "\nSelect a Category to change access permissions:";
        Dialog(kID, sPrompt, lCategory, lUtilityNone, 0, iAuth, "Restrictions~AccesCategory");
    } else {
        sPrompt += "\nSelect a Category to set restrictions:";
        Dialog(kID, sPrompt, lCategory, ["[Clear All]","[Set Access]"]+lUtilityNone, 0, iAuth, "Restrictions~Restrictions");
    }
}

MenuCategory(key kID, integer iAuth, string sCategory, integer iSetAccess)
{
    string sPrompt = "\n[Category "+sCategory+"]";
    if (iSetAccess) sPrompt += "\n \n Choose a restriction to change access permissions:";
    
    integer iCatIndex = llListFindList(lCategory,[sCategory]);
    
    list lMenu = [];
    integer i;
    for (i=1; i<llGetListLength(lRLVList);i=i+6) {
        if (llList2Integer(lRLVList,i) == iCatIndex) {
            if (iSetAccess) lMenu += [llList2String(lRLVList,i-1)];
            else if (llList2Integer(lRLVList,i+4) >= iAuth){
                if ((g_iRestrictions1 & llList2Integer(lRLVList,i+2)) || (g_iRestrictions2 & llList2Integer(lRLVList,i+3))) lMenu += [g_sChecked+llList2String(lRLVList,i-1)];
                else lMenu += [g_sUnChecked+llList2String(lRLVList,i-1)];
            }
        }
    }
    if (iSetAccess) Dialog(kID, sPrompt, lMenu, lUtilityNone, 0, iAuth, "Restrictions~Access");
    else Dialog(kID, sPrompt, lMenu, lUtilityNone, 0, iAuth, "Restrictions~Category");
}

MenuSetAccess(key kID, integer iAuth, string sCommand)
{
    list lButtons = [];
    integer iIndex = llListFindList(lRLVList,[sCommand]);
    if (iIndex > -1) {
        g_sTmpRestName = sCommand;
        integer iCurrentAuth = llList2Integer(lRLVList,iIndex+5);
        if (iCurrentAuth < CMD_TRUSTED) lButtons = [g_sChecked+"Owner",g_sUnChecked+"Trusted",g_sUnChecked+"Group",g_sUnChecked+"Everyone"];
        else if (iCurrentAuth < CMD_GROUP) lButtons = [g_sChecked+"Owner",g_sChecked+"Trusted",g_sUnChecked+"Group",g_sUnChecked+"Everyone"];
        else if (iCurrentAuth < CMD_WEARER) lButtons = [g_sChecked+"Owner",g_sChecked+"Trusted",g_sChecked+"Group",g_sUnChecked+"Everyone"];
        else if (iCurrentAuth <= CMD_EVERYONE) lButtons = [g_sChecked+"Owner",g_sChecked+"Trusted",g_sChecked+"Group",g_sChecked+"Everyone"];
    }
    Dialog(kID, "Set who will access to '"+sCommand+"'", lButtons, lUtilityNone, 0, iAuth, "Restrictions~SetPerm");
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
        Dialog(kID, "Select a Macro you want to delete:", lButtons, lUtilityNone, 0, iAuth, "Restrictions~Delete");
    } else {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Acces Denied!", kID);
        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kID);
    }
}

integer CheckPermissions(integer iMask1, integer iMask2, key kID, integer iAuth)
{
    list lDenied = [];
    integer iMax1 = 1073741824;
    integer iMax2 = 1073741824;
    while (iMax1 > 0) {
        integer iIndex = llListFindList(lRLVList, [iMax1,0])-1;
        if (iIndex > -1 && iMax1 & iMask1 && ((llList2Integer(lRLVList,iIndex+3) < iAuth) || iAuth == CMD_WEARER)) lDenied += [llList2String(lRLVList,iIndex-2)];
        iMax1 = iMax1 >> 1;
    }
    
    while (iMax2 > 0) {
        integer iIndex = llListFindList(lRLVList, [0,iMax2])-1;
        if (iIndex > -1 && iMax2 & iMask2 &&((llList2Integer(lRLVList,iIndex+3) < iAuth) || iAuth == CMD_WEARER)) lDenied += [llList2String(lRLVList,iIndex-2)];
        iMax2 = iMax2 >> 1;
    }
    
    if (llGetListLength(lDenied) > 0){
        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"NOACCESS% to change restrictions:\n "+llDumpList2String(lDenied,", "),kID);
        return FALSE;
    } else return TRUE;
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
    llMessageLinked(LINK_THIS, LINK_CMD_RESTRICTIONS,sCommand+"="+(string)bEnable+"=-1","");
    return sCommand+sMod;
}

list ApplyAll(integer iMask1, integer iMask2)
{
    list lResult = [];
    integer iMax1 = 1073741824;
    integer iMax2 = 1073741824;
    while (iMax1 > 0) {
        integer iIndex = llListFindList(lRLVList, [iMax1,0])-1;
        if (iIndex > -1) {
            lResult += [FormatCommand(llList2String(lRLVList,iIndex),(iMax1 & iMask1))];
        }
        iMax1 = iMax1 >> 1;
    }
    
    while (iMax2 > 0) {
        integer iIndex = llListFindList(lRLVList, [0,iMax2])-1;
        if (iIndex > -1) {
            lResult += [FormatCommand(llList2String(lRLVList,iIndex),(iMax2 & iMask2))];
        }
        iMax2 = iMax2 >> 1;
    }
    
    string sCommandList = llDumpList2String(lResult,",");

    llMessageLinked(LINK_RLV,RLV_CMD,sCommandList,"Macros");
    
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_mask1=" + (string)g_iRestrictions1, "");
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_mask2=" + (string)g_iRestrictions2, "");
    
    return lResult;
}

ApplyCommand(string sCommand, integer iAdd,key kID, integer iAuth)
{
    integer iMenuIndex = llListFindList(lRLVList,[sCommand]);
    if (iMenuIndex > -1) {
        if (llList2Integer(lRLVList,iMenuIndex+5) >= iAuth){
            if (!iAdd) {
                g_iRestrictions1 = g_iRestrictions1 ^ llList2Integer(lRLVList,iMenuIndex+3);
                g_iRestrictions2 = g_iRestrictions2 ^ llList2Integer(lRLVList,iMenuIndex+4);
                llMessageLinked(LINK_RLV,RLV_CMD,FormatCommand(llList2String(lRLVList,iMenuIndex+2),FALSE),"Macros");
                if (kID != NULL_KEY) llOwnerSay(llList2String(lCategory, llList2Integer(lRLVList,iMenuIndex+1))+" - "+llList2String(lRLVList,iMenuIndex)+" is not restricted anymore!");
            } else {
                g_iRestrictions1 = g_iRestrictions1 | llList2Integer(lRLVList,iMenuIndex+3);
                g_iRestrictions2 = g_iRestrictions2 | llList2Integer(lRLVList,iMenuIndex+4);
                llMessageLinked(LINK_RLV,RLV_CMD,FormatCommand(llList2String(lRLVList,iMenuIndex+2),TRUE),"Macros");
                if (kID != NULL_KEY) llOwnerSay(llList2String(lCategory, llList2Integer(lRLVList,iMenuIndex+1))+" - "+llList2String(lRLVList,iMenuIndex)+" is now restricted!");
            }
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_mask1=" + (string)g_iRestrictions1, "");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_mask2=" + (string)g_iRestrictions2, "");
        } else if (kID != NULL_KEY) llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS% to change '"+llList2String(lCategory, llList2Integer(lRLVList,iMenuIndex+1))+" - "+llList2String(lRLVList,iMenuIndex)+"'", kID);
    }
}

AuthSetting(list lAuthStrided, integer iRestore){
    
    list authVals = [];
    integer realPos=0;
    integer i=0;
    integer end = llGetListLength(lRLVList);
    for(i=5;i<end;i+=6){
        if(!iRestore)
            authVals+=llList2Integer(lRLVList, i);
        else
            lRLVList = llListReplaceList(lRLVList, [llList2Integer(lAuthStrided, realPos)], i,i);
        
        
        realPos++;
    }
    
    if(!iRestore)
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_auths="+llDumpList2String(authVals, "^"), "");
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
                        g_iRestrictions1 = g_iRestrictions1 | llList2Integer(g_lMacros,iIndex+1);
                        g_iRestrictions2 = g_iRestrictions2 | llList2Integer(g_lMacros,iIndex+2);
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Macro Added: '"+sChangevalue+"'", kID);
                        ApplyAll(g_iRestrictions1,g_iRestrictions2);
                        llOwnerSay("Macro '"+llList2String(g_lMacros,iIndex)+"' has been added!");
                    } else if (sChangekey == "replace") {
                        g_iRestrictions1 = llList2Integer(g_lMacros,iIndex+1);
                        g_iRestrictions2 = llList2Integer(g_lMacros,iIndex+2);
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Replaced restrictions with Macro '"+sChangevalue+"'", kID);
                        ApplyAll(g_iRestrictions1,g_iRestrictions2);
                        llOwnerSay("Macro '"+llList2String(g_lMacros,iIndex)+"' replaced your Restrictions!");
                    } else if (sChangekey == "clear") {
                        g_iRestrictions1 = g_iRestrictions1 ^ (g_iRestrictions1 & llList2Integer(g_lMacros,iIndex+1));
                        g_iRestrictions2 = g_iRestrictions2 ^ (g_iRestrictions2 & llList2Integer(g_lMacros,iIndex+2));
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Macro cleared '"+sChangevalue+"'", kID);
                        ApplyAll(g_iRestrictions1,g_iRestrictions2);
                        llOwnerSay("Macro '"+llList2String(g_lMacros,iIndex)+"' has been cleared!");
                    }
                } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Macro not applied!", kID);
            } else llInstantMessage(kID,"Macro '"+sChangevalue+"' does not exist!");
        } else if (sChangetype == "restriction") {
            if (sChangekey == "add") ApplyCommand(sChangevalue,TRUE, kID, iNum);
            else if (sChangekey == "rem" && iNum != CMD_WEARER) ApplyCommand(sChangevalue,FALSE, kID, iNum);
        } else if (sChangetype == "restrictions") Menu(kID,iNum);
    }
}


default
{
    state_entry()
    {
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST, "global_locked","");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST, "rlvsuite_mask1","");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST, "rlvsuite_mask2","");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST, "rlvsuite_macros","");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_REQUEST, "rlvsuite_auths","");
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
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
                    else if (sMsg == "[Manage]") Dialog(kAv, "Select an Option:\n \nSave As: Save current restrictions into a Macro\nDelete: Delete a Macro", ["Save As","Delete"], lUtilityNone, 0, iAuth, "Restrictions~Manage");
                    else if(sMsg == "[Individual]") {
                       MenuRestrictions(kAv,iAuth,FALSE);
                    } else {
                        integer iIndex = llListFindList(g_lMacros,[sMsg]);
                        if (iIndex > -1) {
                            g_sTmpMacroName = sMsg;
                            Dialog(kAv, "What do you want to do with that macro?", ["Add","Replace","Clear"], lUtilityNone, 0, iAuth, "Restrictions~Options");
                        }
                    }
                } else if (sMenu == "Restrictions~Manage"){
                    if (sMsg == "Save As") {
                        if (iAuth == CMD_WEARER || iAuth == CMD_OWNER) {
                            Dialog(kAv, "Enter the name of the new Macro:", [], [], 0, iAuth,"Restrictions~textbox");
                        } else {
                            llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kAv);
                            llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                        }
                    } else if (sMsg == "Delete") MenuDelete(kAv, iAuth);
                      else if (sMsg == "BACK") Menu(kAv, iAuth);
                } else if (sMenu == "Restrictions~Restrictions"){
                    if(sMsg == "BACK") Menu(kAv,iAuth);
                    else if (sMsg == "[Set Access]") {
                        if (iAuth == CMD_OWNER) MenuRestrictions(kAv, iAuth, TRUE);
                        else {
                            llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kAv);
                            MenuRestrictions(kAv, iAuth, FALSE);
                        }
                    } else if (sMsg == "[Clear All]") {
                        if (iAuth != CMD_WEARER && CheckPermissions(g_iRestrictions1,g_iRestrictions2,kAv,iAuth)) {
                            g_iRestrictions1 = 0;
                            g_iRestrictions2 = 0;
                            ApplyAll(0,0);
                            MenuRestrictions(kAv, iAuth, FALSE);
                        } else {
                            llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kAv);
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
                        sMsg = llGetSubString( sMsg, 1, -1);
                        integer iMenuIndex = llListFindList(lRLVList,[sMsg]);
                        if (iMenuIndex > -1) {
                            if (g_iRestrictions1 & llList2Integer(lRLVList,iMenuIndex+3) || g_iRestrictions2 & llList2Integer(lRLVList,iMenuIndex+4)) {
                                if (iAuth != CMD_WEARER) ApplyCommand(sMsg,FALSE,kAv, iAuth);
                                else llOwnerSay("Access Denied!");
                            } else {
                                ApplyCommand(sMsg,TRUE,kAv,iAuth);
                            }
                            MenuCategory(kAv, iAuth, llList2String(lCategory, llList2Integer(lRLVList,iMenuIndex+1)),FALSE);
                        }
                    }
                } else if (sMenu == "Restrictions~Access") {
                    if(sMsg == "BACK") MenuRestrictions(kAv,iAuth,TRUE);
                    else{
                        integer iMenuIndex = llListFindList(lRLVList,[sMsg]);
                        if (iMenuIndex > -1) MenuSetAccess(kAv, iAuth, sMsg);
                    }
                } else if (sMenu == "Restrictions~SetPerm") {
                    if (sMsg == "BACK") MenuRestrictions(kAv,iAuth,TRUE);
                    else {
                        integer iIndex = llListFindList(lRLVList,[g_sTmpRestName]);
                        if (iIndex > -1) {
                            sMsg = llGetSubString( sMsg, 1, -1);
                            if (sMsg == "Owner") lRLVList = llListReplaceList(lRLVList,[CMD_OWNER],iIndex+5,iIndex+5);
                            else if (sMsg == "Trusted") lRLVList = llListReplaceList(lRLVList,[CMD_TRUSTED],iIndex+5,iIndex+5);
                            else if (sMsg == "Group") lRLVList = llListReplaceList(lRLVList,[CMD_GROUP],iIndex+5,iIndex+5);
                            else if (sMsg == "Everyone") lRLVList = llListReplaceList(lRLVList,[CMD_EVERYONE],iIndex+5,iIndex+5);
                            llOwnerSay(g_sTmpRestName+"'s Access set to "+sMsg);
                            AuthSetting([],FALSE);
                        }
                        MenuSetAccess(kAv, iAuth, g_sTmpRestName);
                    }
                } else if (sMenu == "Restrictions~textbox") {
                
                    if (llListFindList(g_lMacros,[sMsg]) > -1) {
                        g_sTmpMacroName = sMsg;
                        Dialog(kAv, "A Macro named '"+sMsg+"' does already exist!\n \nDo you want to override it?", ["YES","NO"], lUtilityNone, 0, iAuth, "Restrictions~Override");
                    } else {
                        if (llGetListLength(g_lMacros)/3 >= g_lMaxMacros) Dialog(kAv, "You have already created the maximum amount of macros!", ["OK"], lUtilityNone, 0, iAuth, "Restrictions~MaxMacro");
                        else {
                            sMsg = llGetSubString(sMsg,0,11);
                            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, [" "], []), "_");
                            g_lMacros += [sMsg, g_iRestrictions1, g_iRestrictions2];
                            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                            Menu(kAv,iAuth);
                        }
                    }
                } else if (sMenu == "Restrictions~MaxMacro") Menu(kAv,iAuth);
                else if (sMenu == "Restrictions~Override"){
                    if (sMsg == "YES"){
                        integer iIndex = llListFindList(g_lMacros,[g_sTmpMacroName]);
                        g_lMacros = llListReplaceList(g_lMacros, [g_sTmpMacroName,g_iRestrictions1,g_iRestrictions2], iIndex, iIndex+2);
                        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                        Menu(kAv,iAuth);
                    } else Dialog(kAv, "Enter the name of the new Macro:", [], [], 0, iAuth,"Restrictions~textbox");
                } else if (sMenu == "Restrictions~Delete"){
                    if (iAuth <= CMD_TRUSTED){
                        integer iIndex = llListFindList(g_lMacros,[sMsg]);
                        if (iIndex > -1) {
                            g_lMacros = llDeleteSubList(g_lMacros,iIndex, iIndex+2);
                            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                            Menu(kAv,iAuth);
                        } else Menu(kAv,iAuth);
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kAv);
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                } else if (sMenu == "Restrictions~Options") {
                    integer iIndex = llListFindList(g_lMacros,[g_sTmpMacroName]);
                    if (iIndex > -1) UserCommand(iAuth, "macro "+llToLower(sMsg)+" "+g_sTmpMacroName, kAv);
                    Menu(kAv,iAuth);
                }
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (sToken == "rlvsuite_mask1") g_iRestrictions1 = (integer)sValue;
            else if (sToken == "rlvsuite_mask2") g_iRestrictions2 = (integer) sValue;
            else if (sToken == "rlvsuite_macros") g_lMacros = llParseStringKeepNulls(sValue, ["^"],[]);
            else if (sToken == "rlvsuite_auths") AuthSetting(llParseString2List(sValue, ["^"], []), TRUE);
        } else if(iNum == LINK_UPDATE){
            if(sStr == "LINK_DIALOG") LINK_DIALOG=iSender;
            if(sStr == "LINK_RLV") LINK_RLV=iSender;
            if(sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == CMD_SAFEWORD || iNum == RLV_CLEAR || iNum == RLV_OFF){
            g_iRestrictions1 = 0;
            g_iRestrictions2 = 0;
            ApplyAll(0,0);
        } else if (iNum == RLV_REFRESH || iNum == RLV_ON) {
            ApplyAll(g_iRestrictions1,g_iRestrictions2);
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
                integer bWasTrue = g_iRestrictions2 & 8388608;
                if (bWasTrue) ApplyCommand("Blur View",FALSE, NULL_KEY, 0);
                g_iBlurAmount = llList2Integer(lCMD,1);
                if (bWasTrue) ApplyCommand("Blur View",TRUE, NULL_KEY, 0);
            } else if (llList2String(lCMD,0) == "MaxCamDist") {
                integer bWasTrue = g_iRestrictions2 & 16777216;
                if (bWasTrue) ApplyCommand("MaxDistance",FALSE, NULL_KEY, 0);
                g_fMaxCamDist = llList2Float(lCMD,1);
                if (bWasTrue) ApplyCommand("MaxDistance",TRUE, NULL_KEY, 0);
            } else if (llList2String(lCMD,0) == "MinCamDist") { 
                integer bWasTrue = g_iRestrictions2 & 33554432;
                if (bWasTrue) ApplyCommand("MinDistance",FALSE, NULL_KEY, 0);
                g_fMinCamDist = llList2Float(lCMD,1);
                if (bWasTrue) ApplyCommand("MinDistance",TRUE, NULL_KEY, 0);
            }
        }
    }
    
}
