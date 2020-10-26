// This file is part of OpenCollar.
//  Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue                            
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sScriptVersion = "8.0";

string g_sParentMenu = "RLV";
string g_sSubMenu = "Macros";


integer g_iJustRezzed=FALSE;
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;



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

//string g_sSettingToken = "rlvsuite_";

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

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
//string g_sTmpRestName = "";
list g_lCategory = ["Chat",
                    "Show/Hide",
                    "Teleport",
                    "Misc",
                    "Edit/Mod",
                    "Interact",
                    "Movement",
                    "Camera",
                    "Outfit"
                ];

list g_lUtilityMain = ["[Manage]","BACK"];
list g_lUtilityNone = ["BACK"];


list g_lRLVList = [   // ButtonText, CategoryIndex, RLVCMD
    "EmoteTrunc"    , 0 , "emote"                               ,    // 1
    "Send Chat"     , 0 , "sendchat"                            ,    // 2
    "See Chat"      , 0 , "recvchat"                            ,    // 3
    "See Emote"     , 0 , "recvemote"                           ,    // 4
    "Whisper"       , 0 , "chatwhisper"                         ,    // 5
    "Normal"        , 0 , "chatnormal"                          ,    // 6
    "Shout"         , 0 , "chatshout"                           ,    // 7
    "Send IM"       , 0 , "sendim"                              ,    // 8
    "See IM"        , 0 , "recvim"                              ,    // 9
    "Start IM"      , 0 , "startim"                             ,    // 10
    "Gesture"       , 0 , "sendgesture"                         ,    // 11
    "Inventory"     , 1 , "showinv"                             ,    // 12
    "Minimap"       , 1 , "showminimap"                         ,    // 13
    "Worldmap"      , 1 , "showworldmap"                        ,    // 14
    "Location"      , 1 , "showloc"                             ,    // 15
    "Names"         , 1 , "shownames"                           ,    // 16
    "Nametags"      , 1 , "shownametags"                        ,    // 17
    "Nearby"        , 1 , "shownearby"                          ,    // 18
    "Text"          , 1 , "showhovertext"                       ,    // 19
    "Text HUD"      , 1 , "showhovertexthud"                    ,    // 20
    "Text World"    , 1 , "showhovertextworld"                  ,    // 21
    "Text All"      , 1 , "showhovertextall"                    ,    // 22
    "Landmark"      , 2 , "tplm"                                ,    // 23
    "TP Location"   , 2 , "tploc"                               ,    // 24
    "Local"         , 2 , "tplocal"                             ,    // 25
    "Accept"        , 2 , "tplure"                              ,    // 26
    "Offer"         , 2 , "tprequest"                           ,    // 27
    "Permissions"   , 3 , "acceptpermission"                    ,    // 28
    "Edit"          , 4 , "edit"                                ,    // 29
    "Edit Object"   , 4 , "editobj"                             ,    // 30
    "Rez"           , 4 , "rez"                                 ,    // 31
    "Add Attach"    , 8 , "addattach"                           ,    // 32
    "Rem Attach"    , 8 , "remattach"                           ,    // 33
    "Add Cloth"     , 8 , "addoutfit"                           ,    // 34
    "Rem Cloth"     , 8 , "remoutfit"                           ,    // 35
    "Notecard"      , 4 , "viewnote"                            ,    // 36
    "Script"        , 4 , "viewscript"                          ,    // 37
    "Texture"       , 4 , "viewtexture"                         ,    // 38
    "Touch Far"     , 5 , "fartouch"                            ,    // 39
    "Interact"      , 5 , "interact"                            ,    // 40
    "Attachment"    , 5 , "touchattach"                         ,    // 41
    "Own Attach"    , 5 , "touchattachself"                     ,    // 42
    "Other Attach"  , 5 , "touchattachother"                    ,    // 43
    "HUD"           , 5 , "touchhud"                            ,    // 44
    "World"         , 5 , "touchworld"                          ,    // 45
    "All"           , 5 , "touchall"                            ,    // 46
    "Fly"           , 6 , "fly"                                 ,    // 47
    "Jump"          , 6 , "jump"                                ,    // 48
    "Stand Up"      , 6 , "unsit"                               ,    // 49
    "Sit Down"      , 6 , "sit"                                 ,    // 50
    "Sit TP"        , 6 , "sittp"                               ,    // 51
    "Stand TP"      , 6 , "standtp"                             ,    // 52
    "Always Run"    , 6 , "alwaysrun"                           ,    // 53
    "Temp Run"      , 6 , "temprun"                             ,    // 54
    "Unlock Cam"    , 7 , "camunlock"                           ,    // 55
    "Blur View"     , 7 , "setdebug_renderresolutiondivisor"    ,    // 56
    "MaxDistance"   , 7 , "setcam_avdistmax"                    ,    // 57
    "MinDistance"   , 7 , "setcam_avdistmin"                         // 58
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
    
    list lButtons =[];
    integer i;
    for(i=0;i<llGetListLength(g_lMacros);i+=3){
        // calculate checkbox
        integer b1 = llList2Integer(g_lMacros,i+1);
        integer b2 = llList2Integer(g_lMacros, i+2);
        
        lButtons+=[Checkbox(bool((g_iRestrictions1 & b1 ) || ( g_iRestrictions2 & b2)), llList2String(g_lMacros,i))];
    }
    //for (i=0; i<llGetListLength(g_lMacros);i=i+3) lButtons += llList2String(g_lMacros,i);
    
    Dialog(kID, "\n[Macros]\n \nClick on a Macro to toggle it.", lButtons, g_lUtilityMain, 0, iAuth, "Restrictions~Main");
}

MenuRestrictions(key kID, integer iAuth){
    string sPrompt = "\n[Restriction Categories]\n";
    sPrompt += "\nSelect a Category to set restrictions:";
    Dialog(kID, sPrompt, g_lCategory, ["[Clear All]"]+g_lUtilityNone, 0, iAuth, "Restrictions~Restrictions");
    
}

MenuCategory(key kID, integer iAuth, string sCategory)
{
    string sPrompt = "\n[Category "+sCategory+"]";
    
    integer iCatIndex = llListFindList(g_lCategory,[sCategory]);
    
    list lMenu = [];
    integer i;
    
    for(i=0; i<llGetListLength(g_lRLVList); i+= 3){
        if(llList2Integer(g_lRLVList,i+1) == iCatIndex){
            
            integer Flag1 = llRound(llPow(2,(i/3)));
            integer Flag2 = 0;
            if((i/3)>=31){
                Flag1=0;
                Flag2 = llRound(llPow(2, (i/3)-30));
            }
            if(iAuth==CMD_OWNER || iAuth==CMD_TRUSTED){
                if((g_iRestrictions1 & Flag1) || (g_iRestrictions2 & Flag2)) lMenu+= [Checkbox(TRUE, llList2String(g_lRLVList, i))];
                else lMenu += [Checkbox(FALSE, llList2String(g_lRLVList,i))];
            }
            
        }
    }
    Dialog(kID, sPrompt, lMenu, g_lUtilityNone, 0, iAuth, "Restrictions~Category");
}

MenuDelete(key kID, integer iAuth)
{
    if (iAuth == CMD_OWNER){
        list lButtons = [];
        integer i;
        for (i=0; i<llGetListLength(g_lMacros);i=i+3)
        {
            lButtons += llList2String(g_lMacros,i);
        }
        Dialog(kID, "Select a Macro you want to delete:", lButtons, g_lUtilityNone, 0, iAuth, "Restrictions~Delete");
    } else {
        llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS% to delete a macro", kID);
        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kID);
    }
}

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
    llMessageLinked(LINK_SET, LINK_CMD_RESTRICTIONS, sCommand+"="+(string)bEnable+"=-1","");
    
    return sCommand+sMod;
}

ApplyAll(integer iMask1, integer iMask2, integer iBoot)
{
    list lResult = [];
    integer iMax1 = 1073741824;
    integer iMax2 = 1073741824;
    while (iMax1 > 0) {
        list pos = bitpos(iMax1, 0);
        integer iIndex = (llList2Integer(pos,0)*3)+2;
        
        
        if (iIndex > -1 && bool(iMax1 & iMask1) != bool(iMax1 & g_iRestrictions1)) {
            lResult += [FormatCommand(llList2String(g_lRLVList,iIndex), bool(iMax1 & iMask1))];
           // llSay(0, "lRLVListPart1.\npos: "+(string)pos+"\niIndex: "+(string)iIndex+"\nlResult[-1]: "+llList2String(lResult,-1));
        }
        iMax1 = iMax1 >> 1;
    }
    
    while (iMax2 > 0) {
        list pos = bitpos(0,iMax2);
        integer iIndex = ((llList2Integer(pos,1)+30)*3)+2;
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
    if(iMenuIndex/3>=31){
        iMenuIndex2 =(integer) llPow(2, (iMenuIndex/3)-30);
        iMenuIndex=0;
    }else {
        iMenuIndex2=0;
        iMenuIndex = (integer)llPow(2, iMenuIndex/3);
    }
    
    if (iActualIndex > -1) {
        integer allow=FALSE;
        if(iAuth==CMD_OWNER||iAuth==CMD_TRUSTED)allow=TRUE;
        
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


UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
    if (llSubStringIndex(sStr,"macro") && llSubStringIndex(sStr,"restriction") && llSubStringIndex(sStr,"restrictions") && llSubStringIndex(sStr,"sit") && sStr != "menu "+g_sSubMenu && sStr != "menu Restrictions") return;
    if (llToLower(sStr)=="macro" || sStr == "menu "+g_sSubMenu) Menu(kID, iNum);
    if(llToLower(sStr)=="restrictions" || sStr == "menu Restrictions")MenuRestrictions(kID, iNum);
    else { 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangekey = llList2String(llParseString2List(sStr, [" "], []),1);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),2);
        
        if (sChangetype == "macro") {
            integer iIndex = llListFindList(g_lMacros,[sChangevalue]);
            if (iIndex > -1) {
                if (iNum == CMD_OWNER){
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

integer CheckboxState(string CheckboxLabel){
    list lTmp = llParseString2List(CheckboxLabel,[" "],[]);
    integer iPos = llListFindList(g_lCheckboxes, [llList2String(lTmp,0)]);
    if(iPos==-1){
        return FALSE;
    }else {
        return iPos;
    }
}

string CheckboxText(string CheckboxLabel){
    list lTmp = llParseString2List(CheckboxLabel, [" "],[]);
    return llList2String(lTmp,1);
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
    state_entry()
    {
        //llScriptProfiler(TRUE);
        if(llGetStartParameter()!=0)llResetScript();
        g_iRLV = FALSE;
        //llSetTimerEvent(1);
        
    }
    
    on_rez(integer iRez){
        //g_iJustRezzed=TRUE;
        // Restrictions are likely not applied at the moment, reinit the variables
        //llResetTime();
        llResetScript();
        //llSetTimerEvent(1);
    }
    
    timer(){
        if(llGetTime()>=20 && g_iJustRezzed){
            llMessageLinked(LINK_SET, RLV_REFRESH, "",""); // refreshes rlvsuite restrictions
        }
        
        //llSetText("rlvsuite\n\n=> Free Memory: "+(string)llGetFreeMemory()+"\nProfiler Max used: "+(string)llGetSPMaxMemory()+"\nUsed Memory: "+(string)llGetUsedMemory()+"\nTotal Mem: "+(string)llGetMemoryLimit()+"\n \n \n \n \n \n \n \n \n", <0,1,0>,1);
    }
        
    link_message(integer iSender,integer iNum,string sStr,key kID){
       // llOwnerSay(llDumpList2String([iSender, iNum, llGetSPMaxMemory(), llGetFreeMemory()], " ^ "));
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST) {
            if(sStr == g_sParentMenu){
                
                
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");  // Register menu "Restrictions"
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu+"|Restrictions", "");
            }
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
                    else {
                        integer iChkbxState = CheckboxState(sMsg);
                        string sChkbxLbl = CheckboxText(sMsg);
                        
                        if(!iChkbxState){
                            // toggle the macro
                            UserCommand(iAuth, "macro add "+sChkbxLbl, kAv);
                        } else {
                            UserCommand(iAuth, "macro clear "+sChkbxLbl,kAv);
                        }
                        Menu(kAv,iAuth);
                    }
                } else if (sMenu == "Restrictions~Manage"){
                    if (sMsg == "Save As") {
                        if (iAuth == CMD_OWNER) {
                            Dialog(kAv, "Enter the name of the new Macro:", [], [], 0, iAuth,"Restrictions~textbox");
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                            llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                        }
                    } else if (sMsg == "Delete") MenuDelete(kAv, iAuth);
                      else if (sMsg == "BACK") Menu(kAv, iAuth);
                } else if (sMenu == "Restrictions~Restrictions"){
                    if(sMsg == "BACK") llMessageLinked(LINK_SET,0,"menu "+g_sParentMenu,kAv);
                    else if (sMsg == "[Clear All]") {
                        if (iAuth != CMD_WEARER && (iAuth == CMD_OWNER||iAuth==CMD_TRUSTED)) {
                            ApplyAll(0,0, FALSE);
                            MenuRestrictions(kAv, iAuth);
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                            MenuRestrictions(kAv, iAuth);
                        }
                    }
                    else MenuCategory(kAv, iAuth, sMsg);
                
                } else if (sMenu == "Restrictions~Category"){
                    if(sMsg == "BACK") MenuRestrictions(kAv,iAuth);
                    else {
                        sMsg = llGetSubString( sMsg, llStringLength(llList2String(g_lCheckboxes,0))+1, -1);
                        integer iMenuIndex1 = llListFindList(g_lRLVList,[sMsg]);
                        integer iMenuIndex2=0;
                        if(iMenuIndex1/3 >=31){
                            iMenuIndex2 = (iMenuIndex1/3)-30;
                            iMenuIndex1=0;
                        } else {
                            iMenuIndex1 /= 3;
                        }
                        
                        if (iMenuIndex1 > -1) {
                            if (g_iRestrictions1 & (integer)llPow(2,iMenuIndex1) || g_iRestrictions2 & (integer)llPow(2,iMenuIndex2)) {
                                if (iAuth != CMD_WEARER) ApplyCommand(sMsg,FALSE,kAv, iAuth);
                                else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS%", kAv);
                            } else {
                                ApplyCommand(sMsg,TRUE,kAv,iAuth);
                            }
                            MenuCategory(kAv, iAuth, llList2String(g_lCategory, llList2Integer(g_lRLVList,llListFindList(g_lRLVList,[sMsg])+1)));
                        }
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
                }
            }
        } else if(iNum == -99999){
            if(sStr == "update_active")llResetScript();
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            
            //integer ind = llListFindList(g_lSettingsReqs, [llList2String(lParams,0)]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            
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
        
        }else if(iNum == LM_SETTING_EMPTY){
            
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if(iNum == LM_SETTING_DELETE){
            
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
        }
    }
    
}