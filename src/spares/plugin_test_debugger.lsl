/*
THIS FILE IS HEREBY RELEASED UNDER THE Public Domain
This script is released public domain, unlike other OC scripts for a specific and limited reason, because we want to encourage third party plugin creators to create for OpenCollar and use whatever permissions on their own work they see fit.  No portion of OpenCollar derived code may be used excepting this script,  without the accompanying GPLv2 license.
-Authors Attribution-
Phidoux (taya.maruti) - (july 2022)
*/


string g_sParentMenu = "Apps";
string g_sSubMenu = "dbgTest";


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

//integer NOTIFY = 1002;
integer REBOOT = -1000;

//integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Menu App]\n this menu allows you to test the debug plugin!.";
    list lButtons = ["Error","Warn","Info"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER){
        return;
    }
    if (llSubStringIndex(llToLower(sStr),llToLower(g_sSubMenu)) && llToLower(sStr) != "menu "+llToLower(g_sSubMenu)){
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)){
        Menu(kID, iNum);
    }
    else {
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;

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
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER){
            UserCommand(iNum, sStr, kID);
        } else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        } else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU){
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    } else if(sMsg == "Error"){
                        llMessageLinked(LINK_SET,DEBUG_CHANNEL,"ERR: this is an example error message!",kAv);
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Warn"){
                        llMessageLinked(LINK_SET,DEBUG_CHANNEL,"WRN: this is an example warning message!",kAv);
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Info"){
                        llMessageLinked(LINK_SET,DEBUG_CHANNEL,"INFO: this is an example informatinal message!",kAv);
                        Menu(kAv, iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
    }
}
