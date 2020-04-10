// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Cleo Collins, Master Starship, 
// Satomi Ahn, Garvin Twine, Joy Stipe, Alex Carpenter, Xenhat Liamano,  
// Wendy Starfall, Medea Destiny, Rebbie, Romka Swallowtail,        
// littlemousy et al.   
// Licensed under the GPLv2.  See LICENSE for full details. 


// Central storage for settings of other plugins in the device.
string g_sScriptVersion= "7.4";
string g_sCard = ".settings";
string g_sSplitLine; // to parse lines that were split due to lsl constraints
integer g_iLineNr = 0;
key g_kLineID;
key g_kCardID = NULL_KEY; //needed for change event check if no .settings card is in the inventory
list g_lExceptionTokens = ["texture","glow","shininess","color","intern"];
key g_kLoadFromWeb;
key g_kURLLoadRequest;
key g_kWearer;
integer g_iNoComma=FALSE; // default is false
string g_sURL;
key g_kConfirmLoadDialogID;
integer g_iInUpdate=FALSE;

integer LINK_CMD_DEBUG= 1999;
//string g_sSettingToken = "settings_";
//string g_sGlobalToken = "global_";

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
//integer CMD_BLOCKED = 520;

//integer POPUP_HELP = 1001;
integer NOTIFY=1002;
//integer SAY = 1004;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;
integer LM_SETTING_RELAY_CONTENT = 2100;
integer LM_SETTING_RELAY_LOAD = 2101; // used on 'Load' and on initial boot to read the .settings from root prim if applicable.

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer REBOOT = -1000;
integer LOADPIN = -1904;
integer g_iRebootConfirmed;
key g_kConfirmDialogID;
string g_sSampleURL = "https://goo.gl/SQLFnV";
//string g_sEmergencyURL = "https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/";
key g_kURLRequestID;
float g_fLastNewsStamp;
integer g_iCheckNews;

list g_lSettings;

integer g_iSayLimit = 1024; // lsl "say" string limit
integer g_iCardLimit = 255; // lsl card-line string limit
string g_sDelimiter = "\\";

// Get Group or Token, 0=Group, 1=Token
string SplitToken(string sIn, integer iSlot) {
    integer i = llSubStringIndex(sIn, "_");
    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
    return llGetSubString(sIn, i + 1, -1);
}
// To add new entries at the end of Groupings
integer GroupIndex(list lCache, string sToken) {
    string sGroup = SplitToken(sToken, 0);
    integer i = llGetListLength(lCache) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2) {
        if (SplitToken(llList2String(lCache, i - 1), 0) == sGroup) return i + 1;
    }
    return -1;
}
integer SettingExists(string sToken) {
    if (~llListFindList(g_lSettings, [sToken])) return TRUE;
    return FALSE;
}

list SetSetting(list lCache, string sToken, string sValue) {
    integer idx = llListFindList(lCache, [sToken]);
    if (~idx) return llListReplaceList(lCache, [sValue], idx + 1, idx + 1);
    idx = GroupIndex(lCache, sToken);
    if (~idx) return llListInsertList(lCache, [sToken, sValue], idx);
    return lCache + [sToken, sValue];
}

string GetSetting(string sToken) {
    integer i = llListFindList(g_lSettings, [sToken]);
    if(i == -1)return "NOT_FOUND";
    return llList2String(g_lSettings, i + 1);
}

DelSetting(string sToken) { // we'll only ever delete user settings
    integer i = llGetListLength(g_lSettings) - 1;
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

// run delimiters & add escape-characters for settings print
list Add2OutList(list lIn, string sDebug) {
    if (!llGetListLength(lIn)) return [];
    list lOut;// = ["#---My Settings---#"];
    string sBuffer;
    string sTemp;
    string sID;
    string sPre;
    string sGroup;
    string sToken;
    string sValue;
    integer i;

    for (i=0 ; i < llGetListLength(lIn); i += 2) {
        sToken = llList2String(lIn, i);
        sValue = llList2String(lIn, i + 1);
        //sGroup = SplitToken(sToken, 0);
        sGroup = llToUpper(SplitToken(sToken, 0));
        if (sDebug == "print" && ~llListFindList(g_lExceptionTokens,[llToLower(sGroup)])) jump next;
        sToken = SplitToken(sToken, 1);
        integer bIsSplit = FALSE ;
        integer iAddedLength = llStringLength(sBuffer) + llStringLength(sValue)
            + llStringLength(sID) +2; //+llStringLength(set);
        if (sGroup != sID || llStringLength(sBuffer) == 0 || iAddedLength >= g_iCardLimit ) { // new group
            // Starting a new group.. flush the buffer to the output.
            if ( llStringLength(sBuffer) ) lOut += [sBuffer] ;
            sID = sGroup;
           // pre = "\n" + set + sid + "=";
            sPre = "\n" + sID + "=";
        }
        else sPre = sBuffer + "~";
        sTemp = sPre + sToken + "~" + sValue;
        while (llStringLength(sTemp)) {
            sBuffer = sTemp;
            if (llStringLength(sTemp) > g_iCardLimit) {
                bIsSplit = TRUE ;
                sBuffer = llGetSubString(sTemp, 0, g_iCardLimit - 2) + g_sDelimiter;
                sTemp = "\n" + llDeleteSubString(sTemp, 0, g_iCardLimit - 2);
            } else sTemp = "";
            if ( bIsSplit ) {
                // if this is either a split buffer or one of it's continuation
                // line outputs,
                lOut += [sBuffer];
                sBuffer = "" ;
            }
        }
        @next;
    }
    // If there's anything left in the buffer, flush it to output.
    if ( llStringLength(sBuffer) ) lOut += [sBuffer] ;
    return lOut;
}

PrintSettings(key kID, string sDebug) {
    // compile everything into one list, so we can tell the user everything seamlessly
    list lOut;
    list lSay = ["/me Settings:\n"];
    if (sDebug == "debug")
        lSay = ["/me Settings Debug:\n"];
    lSay += Add2OutList(g_lSettings, sDebug);
    string sOld;
    string sNew;
    integer i;
    while (llGetListLength(lSay)) {
        sNew = llList2String(lSay, 0);
        i = llStringLength(sOld + sNew) + 2;
        if (i > g_iSayLimit) {
            lOut += [sOld];
            sOld = "";
        }
        sOld += sNew;
        lSay = llDeleteSubList(lSay, 0, 0);
    }
    lOut += [sOld];
    while (llGetListLength(lOut)) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+llList2String(lOut, 0), kID);
        //Notify(kID, llList2String(lOut, 0), TRUE);
        lOut = llDeleteSubList(lOut, 0, 0);
    }
}

LoadSetting(string sData, integer iLine) {
    string sID;
    string sToken;
    string sValue;
    integer i;
    if (iLine == 0 && g_sSplitLine != "" ) {
        sData = g_sSplitLine ;
        g_sSplitLine = "" ;
    }
    if (iLine) {
        // first we can filter out & skip blank lines & remarks
        sData = llStringTrim(sData, STRING_TRIM_HEAD);
        if (sData == "" || llGetSubString(sData, 0, 0) == "#") return;
        // check for "continued" line pieces
        if (llStringLength(g_sSplitLine)) {
            sData = g_sSplitLine + sData ;
            g_sSplitLine = "" ;
        }
        if (llGetSubString(sData,-1,-1) == g_sDelimiter) {
            g_sSplitLine = llDeleteSubString(sData,-1,-1) ;
            return;
        }
        i = llSubStringIndex(sData, "=");
        if(i!=-1){
            sID = llGetSubString(sData, 0, i - 1);
            sData = llGetSubString(sData, i + 1, -1);
            if (~llSubStringIndex(llToLower(sID), "_")) return;
            else if (~llListFindList(g_lExceptionTokens,[sID])) return;
            sID = llToLower(sID)+"_";
            list lData = llParseString2List(sData, ["~"], []);
            for (i = 0; i < llGetListLength(lData); i += 2) {
                sToken = llList2String(lData, i);
                sValue = llList2String(lData, i + 1);
                if (sValue != "") {
                    g_lSettings = SetSetting(g_lSettings, sID + sToken, sValue);
                    
                    if(llToLower(sID+sToken)=="settings_nocomma") g_iNoComma=(integer)sValue;
                }
            }
        } else {
            i=llSubStringIndex(sData,"+");
            sID = llGetSubString(sData,0,i-1);
            sData = llGetSubString(sData,i+1,-1);
            
            if(~llSubStringIndex(llToLower(sID),"_"))return;
            else if(~llListFindList(g_lExceptionTokens,[sID]))return;
            sID = llToLower(sID)+"_";
            list lData = llParseString2List(sData, ["~"],[]);
            for(i=0;i<llGetListLength(lData);i+=2){
                sToken= llList2String(lData,i);
                sValue = llList2String(lData,i+1);
                if(sValue!=""){
                    string sPreExistingValue = GetSetting(sID+sToken);
                    if(sPreExistingValue!="NOT_FOUND"){
                        if(llSubStringIndex(sPreExistingValue, sValue)==-1){
                            if(!g_iNoComma)
                                sPreExistingValue+=","+sValue;
                            else
                                sPreExistingValue+=sValue;
                        }
                    }
                    else{
                        sPreExistingValue=sValue;
                    }
                    g_lSettings = SetSetting(g_lSettings,sID+sToken,sPreExistingValue);
                }
            }
        }
            
        
    }
}

SendValues() {
    //Debug("Sending all settings");
    //loop through and send all the settings
    integer n;
    string sToken;
    list lOut;
    for (; n < llGetListLength(g_lSettings); n += 2) {
        sToken = llList2String(g_lSettings, n) + "=";
        sToken += llList2String(g_lSettings, n + 1);
        if (llListFindList(lOut, [sToken]) == -1) lOut += [sToken];
    }
    n = 0;
    for (; n < llGetListLength(lOut); n++)
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, llList2String(lOut, n), "");

    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "settings=sent", "");//tells scripts everything has be sentout
}


UserCommand(integer iAuth, string sStr, key kID) {
    string sStrLower = llToLower(sStr);
    if (sStrLower == "print settings" || sStrLower == "debug settings") PrintSettings(kID, llGetSubString(sStrLower,0,4));
    else if (!llSubStringIndex(sStrLower,"load")) {
        if (iAuth == CMD_OWNER) {
            if (llSubStringIndex(sStrLower,"load url") == 0 && iAuth == CMD_OWNER) {
                string sURL = llList2String(llParseString2List(sStr,[" "],[]),2);
                if (!llSubStringIndex(sURL,"http")) {
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Fetching settings from "+sURL,kID);
                    g_kURLLoadRequest = kID;
                    g_kConfirmLoadDialogID = llGenerateKey();
                    g_sURL = sURL;
                    llMessageLinked(LINK_SET, DIALOG, (string)llGetOwner()+"|Settings are about to be loaded from a URL and may revoke your access to the collar. Only allow this action if you trust the person. Read the settings first: "+sURL+"|0|Yes`No|Cancel|"+(string)iAuth,g_kConfirmLoadDialogID);
                    //g_kLoadFromWeb = llHTTPRequest(sURL,[HTTP_METHOD, "GET"],"");
                } else llMessageLinked(LINK_SET,NOTIFY,"0"+"Please enter a valid URL like: "+g_sSampleURL,kID);
            } else if (sStrLower == "load card" || sStrLower == "load") {
                llMessageLinked(LINK_SET, LM_SETTING_RELAY_LOAD, "", "");
                if (llGetInventoryKey(g_sCard)) {
                    llMessageLinked(LINK_SET,NOTIFY,"0"+ "\n\nLoading backup from "+g_sCard+" card. If you want to load settings from the web, please type: /%CHANNEL% %PREFIX% load url <url>\n",kID);
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                } else llMessageLinked(LINK_SET,NOTIFY,"0"+"No "+g_sCard+" to load found.",kID);
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to load",kID);
    } else if (sStrLower == "reboot" || sStrLower == "reboot --f") {
        if (g_iRebootConfirmed || sStrLower == "reboot --f") {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Rebooting your %DEVICETYPE% ....",kID);
            g_iRebootConfirmed = FALSE;
            llMessageLinked(LINK_SET, REBOOT,"reboot","");
            g_iCheckNews = TRUE;
            llSetTimerEvent(2.0);
        } else {
            g_kConfirmDialogID = llGenerateKey();
            llMessageLinked(LINK_SET,DIALOG,(string)kID+"|\nAre you sure you want to reboot the %DEVICETYPE%?|0|Yes`No|Cancel|"+(string)iAuth,g_kConfirmDialogID);
        }
    }
    else if (sStrLower == "runaway") llSetTimerEvent(2.0);
}



ExtractPart(){
    g_sScriptPart = llList2String(llParseString2List(llGetScriptName(), ["_"],[]),1);
}

string g_sScriptPart; // oc_<part>
integer INDICATOR_THIS;
SearchIndicators(){
    ExtractPart();
    
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=0;i<end;i++){
        list Params = llParseStringKeepNulls(llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0), ["~"],[]);
        
        if(llListFindList(Params, ["indicator_"+g_sScriptPart])!=-1){
            INDICATOR_THIS = i;
            return;
        }
    }
    
    
}
Indicator(integer iMode){
    if(INDICATOR_THIS==-1)return;
    if(iMode){
        llSetLinkPrimitiveParamsFast(INDICATOR_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
        llSetTimerEvent(1);
    }else
        llSetLinkPrimitiveParamsFast(INDICATOR_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);
}

default {
    state_entry() {
        // remove the intern_dist setting
        // Ensure that settings resets AFTER every other script, so that they don't reset after they get settings
        SearchIndicators();
        if(llGetStartParameter() != 0) g_iInUpdate=TRUE; // do NOT spam linked messages
        
        if(g_iInUpdate && llGetLinkNumber()!= LINK_ROOT && llGetLinkNumber() != 0){
            
            list Parameters = llParseStringKeepNulls(llList2String(llGetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_DESC]),0), ["~"],[]);
            ExtractPart();
            Parameters += "indicator_"+g_sScriptPart;
            llSetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_DESC, llDumpList2String(Parameters,"~")]);
                
        }
        
        if(g_iInUpdate && llGetLinkNumber()!=LINK_ROOT  &&  llGetLinkNumber() != 0){
            llOwnerSay("Moved oc_settings");
            if(llGetInventoryType(".settings")==INVENTORY_NOTECARD){
                key sendTo = llGetLinkKey(LINK_ROOT);
                llGiveInventory(sendTo, ".settings");
            }
            
            llSleep(1);
            llRemoveInventory(llGetScriptName());
            return;
        }
        
        
        llSleep(0.5);
        g_kWearer = llGetOwner();
        g_iLineNr = 0;
        if (!llGetStartParameter()) {
            llMessageLinked(LINK_SET, LM_SETTING_RELAY_LOAD, "", "");
            if (llGetInventoryKey(g_sCard)) {
                g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
             g_kCardID = llGetInventoryKey(g_sCard);
            } else if (g_lSettings) llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, llDumpList2String(g_lSettings, "="), "");
        }
        
        
       /// llSay(0, "debug: settings was reset");
    }

    on_rez(integer iParam) {
        if (g_kWearer == llGetOwner()) {
            g_iInUpdate=FALSE;
            llSetTimerEvent(10.0);
            //llSleep(0.5); // brief wait for others to reset
            //llMessageLinked(LINK_SET,LINK_UPDATE,"LINK_SET","");
            SendValues();
        } else llResetScript();
    }

    dataserver(key kID, string sData) {
        if (kID == g_kLineID) {
            if (sData != EOF) {
                LoadSetting(sData,++g_iLineNr);
                g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
            } else {
                g_iLineNr = 0;
                LoadSetting(sData,g_iLineNr);
                llSetTimerEvent(1.0);
                SendValues();
            }
        }
    }

    http_response(key kID, integer iStatus, list lMeta, string sBody) {
        if (kID ==  g_kLoadFromWeb) {
            if (iStatus == 200) {
                if (lMeta)
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Invalid URL. You need to provide a raw text file like this: "+g_sSampleURL,g_kURLLoadRequest);
                else {
                    list lLoadSettings = llParseString2List(sBody,["\n"],[]);
                    if (lLoadSettings) {
                        llMessageLinked(LINK_SET,NOTIFY,"1"+"Settings fetched.",g_kURLLoadRequest);
                        integer i;
                        string sSetting;
                        do {
                            sSetting = llList2String(lLoadSettings,0);
                            i = llGetListLength(lLoadSettings);
                            lLoadSettings = llDeleteSubList(lLoadSettings,0,0);
                            LoadSetting(sSetting,i);
                        } while (i);
                        SendValues();
                    } else llMessageLinked(LINK_SET,NOTIFY,"0"+"Empty site provided to load settings.",g_kURLLoadRequest);
                }
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"Invalid url provided to load settings.",g_kURLLoadRequest);
            g_kURLLoadRequest = "";
        } else if (iStatus == 200 && kID == g_kURLRequestID) {
            g_iCheckNews = FALSE;
            integer index = llSubStringIndex(sBody,"\n");
            float fNewsStamp = (float)llGetSubString(sBody,0,index-1);
            if (fNewsStamp > g_fLastNewsStamp) {
                sBody = llGetSubString(sBody,index,-1); //schneidet die erste zeile ab
                llMessageLinked(LINK_SET,NOTIFY,"0"+sBody,g_kWearer);
                g_fLastNewsStamp = fNewsStamp;
                g_lSettings = SetSetting(g_lSettings,"intern_news",(string)fNewsStamp);
            }
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_OWNER || iNum == CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_SAVE) {
            Indicator(TRUE);
            //save the token, value
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            g_lSettings = SetSetting(g_lSettings, sToken, sValue);
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sStr, "");
        
        }
        else if (iNum == LM_SETTING_REQUEST) {
             //check the cache for the token
             Indicator(TRUE);
            if (SettingExists(sStr)) llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, sStr + "=" + GetSetting(sStr), "");
            else if (sStr == "ALL") {
                g_iCheckNews = FALSE;
                llSetTimerEvent(2.0);
            } else llMessageLinked(LINK_SET, LM_SETTING_EMPTY, sStr, "");
        }
        else if (iNum == LM_SETTING_DELETE){
            //llMessageLinked(LINK_SET, LM_SETTING_DELETE,sStr,"");
            DelSetting(sStr);
            Indicator(TRUE);
        } else if(iNum == LM_SETTING_RELAY_CONTENT) LoadSetting(sStr, (integer)((string)kID));
        else if (iNum == DIALOG_RESPONSE && kID == g_kConfirmDialogID) {
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            kID = llList2Key(lMenuParams,0);
            if (llList2String(lMenuParams,1) == "Yes") {
                g_iRebootConfirmed = TRUE;
                UserCommand(llList2Integer(lMenuParams,3),"reboot",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"Reboot aborted.",kID);
        } else if(iNum == DIALOG_RESPONSE && kID == g_kConfirmLoadDialogID){
            list MenuParams = llParseString2List(sStr, ["|"],[]);
            if(llList2String(MenuParams,1) == "Yes"){
                g_kLoadFromWeb = llHTTPRequest(g_sURL,[HTTP_METHOD, "GET"],"");
            } else llMessageLinked(LINK_SET, NOTIFY, "0"+"Load aborted", kID);
            g_sURL="";
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            // The rest of this command can be access by <prefix> debug
            // This script does not have anything special to send. Only it's settings
            llInstantMessage(kID, llGetScriptName() +" FREE MEMORY: "+(string)llGetFreeMemory()+" bytes");
            llInstantMessage(kID, llGetScriptName() +" lSettings length: "+(string)llGetListLength(g_lSettings));

            PrintSettings(kID, "");
        } else if(iNum == -99999){
            if(sStr == "update_active"){
                g_iInUpdate=TRUE;
            }
        } else if(iNum == REBOOT){
            g_iInUpdate=FALSE;
        }
    }

    timer() {
        llSetTimerEvent(0.0);
        SendValues();
        Indicator(FALSE);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(g_sCard) != g_kCardID) {
                // the .settings card changed.  Re-read it.
                g_iLineNr = 0;
                if (llGetInventoryKey(g_sCard)) {
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    g_kCardID = llGetInventoryKey(g_sCard);
                }
            } else {
                llSetTimerEvent(1.0);   //pause, then send values if inventory changes, in case script was edited and needs its settings again
                if(!g_iInUpdate)
                    SendValues();
            }
        }
    }
}