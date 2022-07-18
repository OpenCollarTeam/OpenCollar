/*
THIS FILE IS HEREBY RELEASED UNDER THE Public Domain
This script is released public domain, unlike other OC scripts for a specific and limited reason, because we want to encourage third party plugin creators to create for OpenCollar and use whatever permissions on their own work they see fit.  No portion of OpenCollar derived code may be used excepting this script,  without the accompanying GPLv2 license.
-Authors Attribution-
Phidoux (taya.maruti) - (july 2022)
*/

string g_sVersion = "1.0";
string g_sParentMenu = "Apps";
string g_sSubMenu = "Debugger";

//MESSAGE MAP
integer CMD_OWNER = 500;
integer CMD_WEARER = 503;
integer REBOOT = -1000;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer LM_SETTING_SAVE     = 2000; //scripts send messages on this channel to have settings saved, <string> must be in form of "token=value"
integer LM_SETTING_REQUEST  = 2001; //when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; //the settings script sends responses on this channel
integer LM_SETTING_DELETE   = 2003; //delete token from settings
//integer LM_SETTING_EMPTY    = 2004; //sent when a token has no value

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer DEBUG=DEBUG_CHANNEL;

string UPMENU = "BACK";
list g_lCheckBoxes = ["☐","☑"];
list b_lCheckBoxes;
string b_sActive;
string d_sActive= "Active";
string outType = "Info";
string outChan = "OwnerSay";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n["+g_sSubMenu+"]\n\nOutput Type:"+outType+"\nOutput Channel:"+outChan;
    if( b_lCheckBoxes != [] ) {
        b_sActive = llList2String(b_lCheckBoxes,g_iDebug)+d_sActive;
    } else {
        b_sActive = llList2String(g_lCheckBoxes,g_iDebug)+d_sActive;
    }
    list lButtons = [b_sActive,"Error","Warn","Info","Public","Private"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) {
        return;
    }
    if (llSubStringIndex(llToLower(sStr),llToLower(g_sSubMenu)) && llToLower(sStr) != "menu "+llToLower(g_sSubMenu)) {
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)){
         Menu(kID, iNum);
    } else {
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
integer g_iDebug=TRUE;
integer g_iOutputType = 0;
integer g_iOutputForm = 1;
integer g_iTypeInfo = 0;
integer g_iTypeWarn = 1;
integer g_iTypeError = 2;
integer g_iFormPublic = 0;
integer g_iFormPrivate = 1;

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

integer first_run = TRUE;

debug(string msg,integer oType){
    if(oType == g_iFormPublic){
        llSay(DEBUG_CHANNEL,msg);
    } else if(oType == g_iFormPrivate){
        llOwnerSay(msg);
    }
}

default
{
    on_rez(integer iNum) {
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    state_entry() {
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(iNum == REBOOT) {
            if(sStr == "reboot") {
                llResetScript();
            }
        } else if(iNum == READY) {
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP) {
            state active;
        }
    }
}
state active {
    on_rez(integer t) {
        if(llGetOwner()!=g_kWearer) {
            //llResetScript();
            state default;
        }
    }
    state_entry() {
        if( first_run ){
            debug("Info: from "+g_sSubMenu+" this script is running for the first time since restart we need to create persitence setting for status!",g_iOutputForm);
            first_run = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE,"global_debugger="+(string)g_iDebug,"");
        }
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global","");
        g_kWearer = llGetOwner();
    }
    link_message(integer iSender,integer iNum,string sStr,key kID) {
        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sStr, kID);
        } else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) { 
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        } else if(iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1) {
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                if(sMenu == "Menu~Main") {
                    if(sMsg == UPMENU){
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    } else if(sMsg == b_sActive){
                        if(g_iDebug) {
                            g_iDebug = FALSE;
                        } else {
                            g_iDebug = TRUE;
                        }
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE,"global_debugger="+(string)g_iDebug,"");
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Error") {
                        outType = "Error";
                        g_iOutputType = g_iTypeError;
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Warn") {
                        outType = "Warning";
                        g_iOutputType = g_iTypeWarn;
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Info") {
                        outType = "Info";
                        g_iOutputType = g_iTypeInfo;
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Public") {
                        outChan = "DEBUG_CHANNEL";
                        g_iOutputForm = g_iFormPublic;
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Private") {
                        outChan = "OwnerSay";
                        g_iOutputForm = g_iFormPrivate;
                        Menu(kAv, iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }else if(iNum == DEBUG){
            /*
                input format from other scripts is as follows
                Types: ERR,WRN,INFO
                (type):(message)
                message can be any thing preferably descriptive of the issue.
            */
            list lSettings = llParseString2List(sStr, [":"],[]);
            string sToken = llList2String(lSettings,0);
            string sVal = llList2String(lSettings,1);
            if(sToken=="ERR"){
                if(g_iDebug && g_iOutputType >= g_iTypeError) {
                    debug("Error:"+sVal,g_iOutputForm);
                }
                debug("Error:"+sVal,2);
            } else if(sToken == "WRN" && g_iDebug && g_iOutputType >= g_iTypeWarn){
                debug("Warning:"+sVal,g_iOutputForm);
            } else if(sToken == "INFO" && g_iDebug && g_iOutputType >= g_iTypeInfo){
                debug("Info:"+sVal,g_iOutputForm);
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lPar     = llParseString2List(sStr, ["_","="], []);
            string sToken = llList2String(lPar, 0);
            string sVar   = llList2String(lPar, 1);
            string sVal   = llList2String(lPar, 2);
            if( sToken == "global") {
                if( sVar == "checkboxes") {
                    debug("Info: from "+g_sSubMenu+" Recived the checkboxes "+sVal,g_iOutputForm);
                    b_lCheckBoxes = llParseString2List(sVal,[","],[]);
                }
                if( sVar == "debugger"){
                    debug("Info: from "+g_sSubMenu+" Updating debugger status!",g_iOutputForm);
                    g_iDebug = (integer)sVal;
                }
            }
        } else if (iNum == LM_SETTING_DELETE) {
            // This is recieved back from settings when a setting is deleted
            list lPar     = llParseString2List(sStr, ["_","="], []);
            string sToken = llList2String(lPar, 0);
            string sVar   = llList2String(lPar, 1);
            if(sToken == "global"){
                if(sVar == "debugger"){
                    debug("Warn: from debugger Debugger status has been deleted from settings this could cause issues, attempting to reassert!",g_iOutputForm);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE,"global_debugger="+(string)g_iDebug,"");
                }
            }
        }
    }
}
