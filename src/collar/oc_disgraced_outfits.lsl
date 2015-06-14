//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//          Outfits - 150610.1           .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//  Copyright (C) 2008 - 2015:    Individual Contributors                   //
//                                OpenCollar - submission set free(TM)      //
//                                and Virtual Disgrace(TM)                  //
// ------------------------------------------------------------------------ //
//  Source Code Repository:       github.com/OpenCollar/OC                  //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// Based on the OpenCollar - outfits    3.980
// Compatible with OpenCollar API       3.9
// and/or minimum Disgraced Version     1.3.2

string  SUBMENU_BUTTON              = "Outfits";
string  COLLAR_PARENT_MENU          = "RLV";

key     g_kMenuID;                              // menu handler
key     g_kFolderMenuID;                        // folder menu
key     g_kRemAttachedMenuID;                   // attachment remove menu
key     g_kMultipleMatchMenuID;
key     g_kWearer;
key     g_kMenuClicker;

integer g_iListener;

//string  g_sSettingToken             ="outfits_";
//string  g_sGlobalToken              ="global_";

integer g_iFolderRLV = 98745923;
integer g_iFolderRLVSearch = 98745925;
integer g_iTimeOut = 30; //timeout on viewer response commands
integer g_iRlvOn = FALSE;
integer g_iRlvaOn = FALSE;
string g_sCurrentPath;
string g_sPathPrefix = ".outfits"; //we look for outfits in here


//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER                   = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER                  = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD                = 510; 
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY                     = 1002;

//integer LM_SETTING_SAVE            = 2000;
//integer LM_SETTING_REQUEST         = 2001;
//integer LM_SETTING_RESPONSE        = 2002;

integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;

integer RLV_ON                     = 6101;

integer RLVA_VERSION               = 6004;

integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;

string  UPMENU                     = "BACK";
string  BACKMENU                   = "⏎";
/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}
*/
key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DoMenu(key kID, integer iAuth) {
    g_kMenuClicker = kID; //on our listen response, we need to know who to pop a dialog for
    g_sCurrentPath = g_sPathPrefix + "/";
    llSetTimerEvent(g_iTimeOut);
    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
    llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
}

FolderMenu(key keyID, integer iAuth,string sFolders) {
    string sPrompt = "\n[http://www.virtualdisgrace.com/collar#outfits Virtual Disgrace - Outfits]";
    sPrompt += "\n\nCurrent Path = "+g_sCurrentPath;
    list lMyButtons;

    lMyButtons += llParseString2List(sFolders,[","],[""]);
    lMyButtons = llListSort(lMyButtons, 1, TRUE);
    // and dispay the menu
    if (g_sCurrentPath == g_sPathPrefix+"/") //If we're at root, don't bother with BACKMENU
        g_kFolderMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    else {
        if (sFolders == "") 
            g_kFolderMenuID = Dialog(keyID, sPrompt, lMyButtons, ["WEAR",UPMENU,BACKMENU], 0, iAuth);
        else 
            g_kFolderMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU,BACKMENU], 0, iAuth);
    }
}

RemAttached(key keyID, integer iAuth,string sFolders) {
    string sPrompt = "\n[http://www.virtualdisgrace.com/collar#outfits Virtual Disgrace - Outfits]";
    sPrompt += "\n\nRemove Attachment by Name";
    list lMyButtons;

    lMyButtons += llParseString2List(sFolders,[","],[""]);
    // and dispay the menu
    g_kRemAttachedMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    sStr=llToLower(sStr);
    if (sStr == "outfits" || sStr == "menu outfits") DoMenu(kID, iNum);
    else if (llSubStringIndex(sStr,"wear ") == 0) {
        sStr = llDeleteSubString(sStr,0,llStringLength("wear ")-1);
        if (sStr) { //we have a folder to try find...
            llSetTimerEvent(g_iTimeOut);
            g_iListener = llListen(g_iFolderRLVSearch, "", llGetOwner(), "");
            g_kMenuClicker = kID;
            if (g_iRlvaOn) {
                llOwnerSay("@findfolders:"+sStr+"="+(string)g_iFolderRLVSearch);
            }
            else {
                llOwnerSay("@findfolder:"+sStr+"="+(string)g_iFolderRLVSearch);
            }
        }
    }
    if (remenu) 
        DoMenu(kID, iNum);
}

string WearFolder (string sStr) { //function grabs g_sCurrentPath, and splits out the final directory path, attaching .core directories and passes RLV commands
    string sOutput;
    string sPrePath;
    list lTempSplit = llParseString2List(sStr,["/"],[]);
    lTempSplit = llList2List(lTempSplit,0,llGetListLength(lTempSplit) -2);
    sPrePath = llDumpList2String(lTempSplit,"/");
    if (g_sPathPrefix + "/" == sPrePath) { //
        sOutput = "@remoutfit=force,detach=force,attachallover:"+sStr+"=force,attachallover:"+g_sPathPrefix+"/.core/=force";
    }
    else {
        sOutput = "@remoutfit=force,detach=force,attachallover:"+sStr+"=force,attachallover:"+g_sPathPrefix+"/.core/=force,attachallover:"+sPrePath+"/.core/=force";
    }
   // llOwnerSay("rlv:"+sOutput);
    return sOutput;
}


default {

    state_entry() {
        llSetMemoryLimit(32768); //2015-05-06 (10952 bytes free)
        //g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
    }
    
    timer() {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
    }
    
    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer)  llResetScript();
    }
    
    listen(integer iChan, string sName, key kID, string sMsg) {
        //llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        //llOwnerSay((string)iChan+"|"+sName+"|"+(string)kID+"|"+sMsg);
        if (iChan == g_iFolderRLV) { //We got some folders to process
            FolderMenu(g_kMenuClicker,CMD_OWNER,sMsg); //we use g_kMenuClicker to respond to the person who asked for the menu
        }
        else if (iChan == g_iFolderRLVSearch) {
            if (sMsg == "") {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"That outfit couldn't be found in #RLV/"+g_sPathPrefix,kID);
                //Notify(kID,"That outfit couldn't be found in #RLV/"+g_sPathPrefix,FALSE);
            } else { // we got a match
                if (llSubStringIndex(sMsg,",") < 0) {
                    llOwnerSay(WearFolder(sMsg));
                    g_sCurrentPath = sMsg;
                    //llOwnerSay("@attachallover:"+g_sPathPrefix+"/.core/=force");
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Loading outfit #RLV/"+sMsg,kID);
                    //Notify(kID,"Loading outfit #RLV/"+sMsg,FALSE);
                } else {
                    string sPrompt = "\nPick one!";
                    list lFolderMatches = llParseString2List(sMsg,[","],[]);
                    g_kMultipleMatchMenuID = Dialog(g_kMenuClicker, sPrompt, lFolderMatches, [UPMENU], 0, CMD_OWNER);
                }
            }
        }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) { 
       // llOwnerSay(sStr+" | "+(string)iNum);
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) 
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        else if (iNum == RLV_ON) g_iRlvOn = TRUE;
        else if (iNum == RLVA_VERSION) g_iRlvaOn = TRUE;
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == DIALOG_RESPONSE) { 
            list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
            string sMessage = llList2String(lMenuParams, 1); // button label
            integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
            integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar

            if (kID == g_kFolderMenuID || kID == g_kMultipleMatchMenuID) {
                g_kMenuClicker = kAv;
                if (sMessage == UPMENU) 
                    llMessageLinked(LINK_THIS, iAuth, "menu "+COLLAR_PARENT_MENU, kAv);
                else if (sMessage == BACKMENU) {
                    list lTempSplit = llParseString2List(g_sCurrentPath,["/"],[]);
                    lTempSplit = llList2List(lTempSplit,0,llGetListLength(lTempSplit) -2);
                    g_sCurrentPath = llDumpList2String(lTempSplit,"/") + "/";
                    llSetTimerEvent(g_iTimeOut);
                    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
                    llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                } else if (sMessage == "WEAR")
                    llOwnerSay(WearFolder(g_sCurrentPath));
                else if (sMessage != "") {
                    g_sCurrentPath += sMessage + "/";
                    if (kID == g_kMultipleMatchMenuID) g_sCurrentPath = sMessage;
                    llSetTimerEvent(g_iTimeOut);
                    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
                    llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                }
            }
        }
    }
}
