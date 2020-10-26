  
/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :
All contributors of previous revision of oc_settings
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

string g_sParentMenu = "Apps";

integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;


string GetSetting(string sToken) {
    integer i = llListFindList(g_lSettings, [llToLower(sToken)]);
    if(i == -1)return "NOT_FOUND";
    return llList2String(g_lSettings, i + 1);
}

DelSetting(string sToken) { // we'll only ever delete user settings
    sToken = llToLower(sToken);
    integer i = llGetListLength(g_lSettings) - 1;
    if(sToken == "intern_weld")DeleteWeldFlag();
    if (SplitToken(sToken, 1) == "all") {
        sToken = SplitToken(sToken, 0);
      //  string sVar;
        for (; ~i; i -= 2) {
            if (SplitToken(llList2String(g_lSettings, i - 1), 0) == sToken)
                g_lSettings = llDeleteSubList(g_lSettings, i - 1, i);
        }
        return;
    }
    i = llListFindList(g_lSettings, [sToken]);
    if (~i) g_lSettings = llDeleteSubList(g_lSettings, i, i + 1);
}


// Get Group or Token, 0=Group, 1=Token
string SplitToken(string sIn, integer iSlot) {
    integer i = llSubStringIndex(sIn, "_");
    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
    return llGetSubString(sIn, i + 1, -1);
}

// To add new entries at the end of Groupings
integer GroupIndex(string sToken) {
    sToken = llToLower(sToken);
    string sGroup = SplitToken(sToken, 0);
    integer i = llGetListLength(g_lSettings) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2) {
        if (SplitToken(llList2String(g_lSettings, i - 1), 0) == sGroup) return i + 1;
    }
    return -1;
}

integer SettingExists(string sToken) {
    sToken = llToLower(sToken);
    if (~llListFindList(g_lSettings, [sToken])) return TRUE;
    return FALSE;
}

list SetSetting(string sToken, string sValue) {
    sToken = llToLower(sToken);
    integer idx = llListFindList(g_lSettings, [sToken]);
    if (~idx) return llListReplaceList(g_lSettings, [sValue], idx + 1, idx + 1);
    idx = GroupIndex(sToken);
    if (~idx) return llListInsertList(g_lSettings, [sToken, sValue], idx);
    return g_lSettings + [sToken, sValue];
}

list g_lSettings;
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
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

/*//--                       Anti-License Text                         --//*/
/*//     Contributed Freely to the Public Domain without limitation.     //*/
/*//   2009 (CC0) [ http://creativecommons.org/publicdomain/zero/1.0 ]   //*/
/*//  Void Singer [ https://wiki.secondlife.com/wiki/User:Void_Singer ]  //*/
/*//--                                                                 --//*/
// Returns a integer that is the positive index of the last vStrTst within vStrSrc
integer uSubStringLastIndex(string vStrSrc,string vStrTst) {
    integer vIdxFnd =
        llStringLength( vStrSrc ) -
        llStringLength( vStrTst ) -
        llStringLength(
            llList2String(
                llParseStringKeepNulls( vStrSrc, (list)vStrTst, [] ),
                0xFFFFFFFF ) //-- (-1)
        );
    return (vIdxFnd | (vIdxFnd >> 31));
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}


PrintAll(key kID, string sExtra){
    integer i=0;
    integer end = llGetListLength(g_lSettings);
    llMessageLinked(LINK_SET, NOTIFY, "0OpenCollar Settings: ",kID);
    llMessageLinked(LINK_SET, NOTIFY, "0settings=nocomma~1", kID);
    for(i=0;i<end;i+=2){
        list lTmp = llParseStringKeepNulls(llList2String(g_lSettings,i),["_"],[]);
        string sTok = llList2String(lTmp,0);
        string sVar = llDumpList2String(llList2List(lTmp,1,-1), "_");
        integer iProcess=TRUE;
        if(llToLower(sTok)=="settings" && llToLower(sVar) == "nocomma") iProcess=FALSE;
        if(llToLower(sExtra) != "debug" && llToLower(sTok) == "intern"){
            iProcess=FALSE;
        }
        
        if(iProcess){
            integer iStart=TRUE;
            // Start calculating output
            string sVal = GetSetting(sTok+"_"+sVar);
            
            while(sVal!="" && sVal != "NOT_FOUND"){
                llSleep(0.25);
                if(llStringLength(sTok+"="+sVar+"~"+sVal)>254){
                    //begin to auto split strings
                    // first calculate how much we need to cut
                    integer iPadding = llStringLength(sTok+"="+sVar+"~");
                    string sDat = llGetSubString(sVal,0, (254-iPadding));
                    sVal = llGetSubString(sVal, (254-iPadding)+1,-1);
                    string sSym;
                    if(iStart){
                        iStart=FALSE;
                        sSym="=";
                    } else sSym="+";
                    llMessageLinked(LINK_SET, NOTIFY, "0"+sTok+sSym+sVar+"~"+sDat, kID);
                } else {
                    if(iStart)
                        llMessageLinked(LINK_SET, NOTIFY, "0"+sTok+"="+sVar+"~"+sVal, kID);
                    else
                        llMessageLinked(LINK_SET, NOTIFY, "0"+sTok+"+"+sVar+"~"+sVal,kID);
                    iStart=FALSE;
                    sVal="";
                }
            }
                    
        }
    }
}

integer g_iCurrentIndex =0;
integer SendAValue(){
    // a non-blocking send setting method
    if(g_iCurrentIndex>=llGetListLength(g_lSettings)){
        g_iCurrentIndex=0;
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "settings=sent", "");
        return FALSE;
    } else {
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, llList2String(g_lSettings,g_iCurrentIndex),"");
        g_iCurrentIndex+=2;
        return TRUE;
    }
}
integer AuthCheck(integer iMask){
    if(iMask == CMD_OWNER || iMask==CMD_WEARER)return TRUE;
    else return FALSE;
}
Error(key kID, string sCmd){
    llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to command: "+sCmd, kID);
}
UserCommand(integer iNum, string sStr, key kID) {
    string sLower=  llToLower(sStr);
    if(sLower == "print settings" || sLower == "debug settings"){
        if(AuthCheck(iNum))PrintAll(kID, llGetSubString(sLower,0,4));
        else Error(kID, sStr);
    }
    else if(llGetSubString(sLower,0,5) == "reboot")
    {
        if(AuthCheck(iNum)){
            if(g_iRebootConfirmed || sLower == "reboot --f"){
                llMessageLinked(LINK_SET, NOTIFY, "0Rebooting your %DEVICETYPE%...", kID);
                g_iRebootConfirmed=FALSE;
                llMessageLinked(LINK_SET, REBOOT, "reboot", "");
                llSetTimerEvent(2.0);
            } else {
                Dialog(kID, "\n[Settings]\n\nAre you sure you want to reboot the scripts?", ["Yes", "No"], [], 0, iNum, "Reboot");
            }
        } else Error(kID,sStr);
    } else if(sLower == "runaway") {
        if(AuthCheck(iNum)){
            g_iCurrentIndex=0;
            llSetTimerEvent(10.0); // schedule refresh
        }
    }
    else if(sLower == "load"){
        if(AuthCheck(iNum)){
            // reload settings - assume there is a .settings notecard
            llMessageLinked(LINK_SET, NOTIFY, "0Loading from notecard...", kID);
            g_iSettingsRead=0;
            g_kSettingsRead = llGetNotecardLine(g_sSettings, g_iSettingsRead);
        } else Error(kID,sStr);
    } else if(llSubStringIndex(sLower, "load url")!=-1){
        // prompt to load from a URL
        // TODO: not yet implemented?
        if(AuthCheck(iNum)){
            // load stuff
        } else Error(kID,sStr);
    } else if(sLower == "fix"){
        if(AuthCheck(iNum)){
            g_iCurrentIndex=0;
            llSetTimerEvent(10);
        }
    }
}
integer g_iRebootConfirmed=FALSE;
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
integer g_iLocked=FALSE;

key g_kSettingsRead;
integer g_iSettingsRead;

key g_kSettingsCard=NULL_KEY;
string g_sSettings = ".settings";
integer g_iNoComma=FALSE;

integer iSetor(integer test,integer a,integer b){
    if(test)return a;
    else return b;
}

ProcessSettingLine(string sLine)
{
    // # = comments, at front of line or at end
    // = = sets a setting
    // + = appends a setting (if nocomma = 1, then dont append comma
    if(llGetSubString(sLine,0,0)=="#")return;
    
    list lTmp = llParseString2List(
            llGetSubString(sLine, 0, 
                    iSetor(
                        (uSubStringLastIndex(sLine,"#")
                        >uSubStringLastIndex(sLine,"\"")
                        ), 
                    uSubStringLastIndex(sLine,"#"), -1)
                )
            ,[],["=","+"]);
    list l2 = llParseString2List(llDumpList2String(llList2List(lTmp,2,-1),""), ["~"],[]);
    integer iAppendMode = iSetor((llList2String(lTmp,1)=="+"),TRUE,FALSE);
    
    integer iWeldSetting=FALSE;
    if(~llSubStringIndex(sLine, "weld"))iWeldSetting=TRUE;
    if(!iAppendMode){
        // start setting!
        integer i=0;
        integer end = llGetListLength(l2);
        
        for(i=0;i<end;i+=2){ // start on first index because l2 is initialized off of the 0 element
            //llOwnerSay(llList2String(lTmp,0)+"_"+llList2String(l2,i)+"="+llList2String(l2,i+1));
            if(llList2String(lTmp,0)=="settings" && llList2String(l2,i)=="nocomma"){
                g_iNoComma=(integer)llList2String(l2,i+1);
            }
            g_lSettings = SetSetting(llList2String(lTmp,0)+"_"+llList2String(l2,i), llList2String(l2,i+1));
        }
    } else {
        // append!!
        integer i=0;
        integer end = llGetListLength(l2);
        for(i=0; i<end;i+=2){
            string sToken = llList2String(lTmp,0)+"_"+llList2String(l2,i);
            string sValCur = GetSetting(sToken);
            if(sValCur == "NOT_FOUND")sValCur="";
            if(g_iNoComma)sValCur+= llList2String(l2,i+1);
            else sValCur+=","+llList2String(l2,i+1);
            
            //llOwnerSay(llList2String(lTmp,0)+"+"+llList2String(l2,i)+"="+llList2String(l2,i+1));
            g_lSettings = SetSetting(sToken,sValCur);
        }
        
    }
    if(iWeldSetting) llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "5", "check_weld");
}
integer g_iWeldStorage = -99;
FindLeashpointOrLock()
{
    g_iWeldStorage=-99;
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=0;i<end;i++){
        if(llToLower(llGetLinkName(i))=="lock"){
            g_iWeldStorage = i;
            return;
        }else if(llToLower(llGetLinkName(i)) == "leashpoint"){
            g_iWeldStorage = i; // keep going incase we find the lock prim
        }
    }
    if(g_iWeldStorage!=-99)return;
    g_iWeldStorage=-99;
}

CheckForAndSaveWeld(){
    FindLeashpointOrLock();
    if(g_iWeldStorage==-99)return;
    if(g_iWeldStorage == LINK_ROOT)return;
    if(SettingExists("intern_weld") || SettingExists("intern_weldby")){
        integer Welded = (integer)GetSetting("intern_weld");
        
        // begin
        string sDesc = llList2String(llGetLinkPrimitiveParams(g_iWeldStorage, [PRIM_DESC]),0);
        
        
        list lPara = llParseString2List(sDesc, ["~"],[]);
        
        //llSay(0, "Parameters: "+llList2CSV(lPara));
        if(llListFindList(lPara, ["weld"])==-1){
            if(Welded){
                if(GetSetting("intern_weldby")=="NOT_FOUND")g_lSettings = SetSetting("intern_weldby", (string)NULL_KEY);
                lPara+=["weld",GetSetting("intern_weldby")];
            }
        }else {
            if(!Welded){
                integer index = llListFindList(lPara, ["weld"]);
                lPara=llDeleteSubList(lPara,index,index+1);
            }else {
                // update the weld flag for weldby
                integer index = llListFindList(lPara,["weld"]);
                lPara=llListReplaceList(lPara,[GetSetting("intern_weldby")],index+1,index+1);
            }
        }
        
        llSetLinkPrimitiveParams(g_iWeldStorage, [PRIM_DESC, llDumpList2String(lPara,"~")]);
        //llSay(0, "saved weld state as: "+llDumpList2String(lPara,"~") + "("+(string)llStringLength(llDumpList2String(lPara,"~"))+") to prim "+(string)g_iWeldStorage + "("+llGetLinkName(g_iWeldStorage)+")");
        
    }
}

RestoreWeldState(){
    FindLeashpointOrLock();
    if(g_iWeldStorage==-99)return;
    if(g_iWeldStorage == LINK_ROOT)return;
    
    
    // get welded
    list lPara = llParseString2List(llList2String(llGetLinkPrimitiveParams(g_iWeldStorage,[PRIM_DESC]),0),["~"],[]);
    if(llListFindList(lPara,["weld"])!=-1){
        integer index = llListFindList(lPara,["weld"]);
        g_lSettings = SetSetting("intern_weldby", llList2String(lPara, index+1));
        g_lSettings = SetSetting("intern_weld","1");
        
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "intern_weld","");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "intern_weldby","");
    }
}

DeleteWeldFlag()
{
    FindLeashpointOrLock();
    if(g_iWeldStorage == -99)return;
    if(g_iWeldStorage == LINK_ROOT)return;
    
    list lPara = llParseString2List(llList2String(llGetLinkPrimitiveParams(g_iWeldStorage, [PRIM_DESC]) , 0), ["~"], []);
    integer iIndex = llListFindList(lPara,["weld"]);
    

    if(iIndex==-1)return;
    
    lPara = llDeleteSubList(lPara,iIndex,iIndex+1);
    
    llSetLinkPrimitiveParams(g_iWeldStorage, [PRIM_DESC, llDumpList2String(lPara,"~")]);
}

default
{
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
        g_iCurrentIndex=0;
        llSetTimerEvent(10);
    }
    state_entry()
    {

        g_kWearer = llGetOwner();
        
        FindLeashpointOrLock();
        RestoreWeldState();
        
        if (!SettingExists("global_checkboxes")) g_lSettings = SetSetting("global_checkboxes", "▢,▣");
        
        if(llGetInventoryType(g_sSettings)!=INVENTORY_NONE){
            g_iSettingsRead=0;
            g_kSettingsCard = llGetInventoryKey(g_sSettings);
            g_kSettingsRead = llGetNotecardLine(g_sSettings, 0);
        }
    }
    
    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            if(llGetInventoryType(g_sSettings)!=INVENTORY_NONE){
                if(llGetInventoryKey(g_sSettings)!=g_kSettingsCard){
                    g_iSettingsRead=0;
                    g_kSettingsRead = llGetNotecardLine(g_sSettings,0);
                    g_kSettingsCard = llGetInventoryKey(g_sSettings);
                }
            }
        }
    }
    
    dataserver(key kID, string sData){
        if(kID == g_kSettingsRead){
            if(sData==EOF){
                g_iCurrentIndex=0;
                llSetTimerEvent(2);
                llMessageLinked(LINK_SET, NOTIFY, "0Settings notecard loaded successfully", g_kWearer);
            } else {
                ProcessSettingLine(sData);
            
                g_iSettingsRead++;
                g_kSettingsRead = llGetNotecardLine(g_sSettings,g_iSettingsRead);
            }
        }
    }
    
    timer(){
        if(!SendAValue()){
            llSetTimerEvent(0);
        }else llSetTimerEvent(0.25); // send 1 setting per quarter second
    }
    
    
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        //else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        //    llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
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
                
                if(sMenu == "Reboot"){
                    if(sMsg=="No")return;
                    else if(sMsg=="Yes"){
                        g_iRebootConfirmed=TRUE;
                        llMessageLinked(LINK_SET, iAuth, "reboot", kAv);
                    }
                }
                
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if(iNum == TIMEOUT_FIRED){
            if(sStr == "check_weld")CheckForAndSaveWeld();
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            DelSetting(sStr);
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, sStr,""); // trigger the empty signal to be dispatched
        } else if(iNum == LM_SETTING_RESPONSE){
            list lTmp = llParseString2List(sStr,["_","="],[]);
            string sTok = llList2String(lTmp,0);
            string sVar = llList2String(lTmp,1);
            string sVal = llList2String(lTmp,2);
            
            if(sTok == "settings"){
                if(sVar=="nocomma"){
                    g_iNoComma = (integer)sVal;
                }
            }
        } else if(iNum == LM_SETTING_SAVE){
            list lTmp = llParseString2List(sStr,["="],[]);
            string sTok = llList2String(lTmp,0);
            string sVal = llList2String(lTmp,1);
            
            if(sTok == "intern_weld" || sTok == "intern_weldby") llMessageLinked(LINK_SET,TIMEOUT_REGISTER, "10", "check_weld");
            
            g_lSettings = SetSetting(sTok,sVal);
            
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sStr, "");
        } else if(iNum == LM_SETTING_REQUEST)
        {
            if(SettingExists(sStr)) llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sStr+"="+GetSetting(sStr), "");
            else if(sStr == "ALL"){
                g_iCurrentIndex=0;
                llSetTimerEvent(2);
            } else llMessageLinked(LINK_SET, LM_SETTING_EMPTY, sStr, ""); // Unfortunately. The only time you ever get the empty signal is when you explicitly request the setting.
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}
