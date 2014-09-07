////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - outfits                               //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string  SUBMENU_BUTTON              = "Outfits"; // Name of the submenu
string  COLLAR_PARENT_MENU          = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore

key     g_kMenuID;                              // menu handler
key     g_kFolderMenuID;                        // folder menu
key     g_kRemAttachedMenuID;                   // attachment remove menu
key     g_kMultipleMatchMenuID;
key     g_kWearer;
key     g_kMenuClicker;

integer g_iListener;                       // key of the current wearer to reset only on owner changes
string  g_sScript="Outfits_";                              // part of script name used for settings
string CTYPE                        = "collar";    // designer can set in notecard to appropriate word for their item        
integer g_iFolderRLV = 98745923;
integer g_iFolderRLVSearch = 98745925;
integer g_iTimeOut = 30; //timeout on viewer response commands
integer g_iRlvOn = FALSE;
integer g_iRlvaOn = FALSE;
string g_sCurrentPath;
string g_sPathPrefix = ".outfits"; //we look for outfits in here

// OpenCollar MESSAGE MAP

// messages for authenticating users
// integer COMMAND_NOAUTH = 0; // for reference, but should usually not be in use inside plugins
//integer COMMAND_NOAUTH             = 0;
integer COMMAND_OWNER              = 500;
integer COMMAND_SECOWNER           = 501;
integer COMMAND_GROUP              = 502;
integer COMMAND_WEARER             = 503;
integer COMMAND_EVERYONE           = 504;
integer COMMAND_RLV_RELAY          = 507;
integer COMMAND_SAFEWORD           = 510;
integer COMMAND_RELAY_SAFEWORD     = 511;
integer COMMAND_BLACKLIST          = 520;

integer WEARERLOCKOUT              = 620; // turns on and off wearer lockout

// messages for storing and retrieving values from settings store
integer LM_SETTING_SAVE            = 2000; // scripts send messages on this channel to have settings saved to settings store
//                                            str must be in form of "token=value"
integer LM_SETTING_REQUEST         = 2001; // when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE        = 2002; // the settings script will send responses on this channel
integer LM_SETTING_DELETE          = 2003; // delete token from settings store
integer LM_SETTING_EMPTY           = 2004; // sent by settings script when a token has no value in the settings store
integer LM_SETTING_REQUEST_NOCACHE = 2005;

// messages for creating OC menu structure
integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
integer MENUNAME_REMOVE            = 3003;

// messages for RLV commands
integer RLV_CMD                    = 6000;
integer RLV_REFRESH                = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR                  = 6002; // RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION                = 6003; // RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer RLV_OFF                    = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON                     = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
integer RLV_QUERY                  = 6102; //query from a script asking if RLV is currently functioning
integer RLV_RESPONSE               = 6103; //reply to RLV_QUERY, with "ON" or "OFF" as the message
integer RLVA_VERSION               = 6004;

// messages to the dialog helper
integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;

integer FIND_AGENT                   = -9005; // to look for agent(s) in region with a (optional) search string
key REQUEST_KEY;

integer TIMER_EVENT                = -10000; // str = "start" or "end". For start, either "online" or "realtime".

integer UPDATE                     = 10001;  // for child prim scripts (currently none in 3.8, thanks to LSL new functions)

// For other things that want to manage showing/hiding keys.
integer KEY_VISIBLE                = -10100;
integer KEY_INVISIBLE              = -10100;

integer COMMAND_PARTICLE           = 20000;
integer COMMAND_LEASH_SENSOR       = 20001;

//chain systems
integer LOCKMEISTER                = -8888;
integer LOCKGUARD                  = -9119;

//rlv relay chan
integer RLV_RELAY_CHANNEL          = -1812221819;

// menu option to go one step back in menustructure
string  UPMENU                     = "BACK"; // when your menu hears this, give the parent menu
string  BACKMENU                   = "⏎";



//Debug(string sMsg) { llOwnerSay(llGetScriptName() + " [DEBUG]: " + sMsg);}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DoMenu(key keyID, integer iAuth) {
    list lMyButtons;
    string sPrompt = "\nOutfits ";
    if (!g_iRlvOn) {
        sPrompt += "\nYou need to enable RLV to use this plugin";
    }
    else {
        
        lMyButtons += ["Browse"];
    }
    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

FolderMenu(key keyID, integer iAuth,string sFolders) {
    string sPrompt = "\nOutfits ";
    sPrompt = "\n\nCurrent Path = "+g_sCurrentPath;
    list lMyButtons;

    lMyButtons += llParseString2List(sFolders,[","],[""]);
    // and dispay the menu
    if (g_sCurrentPath == g_sPathPrefix+"/") { //If we're at root, don't bother with BACKMENU
        g_kFolderMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    } else {
        if (sFolders == "") {
            g_kFolderMenuID = Dialog(keyID, sPrompt, lMyButtons, ["WEAR",UPMENU,BACKMENU], 0, iAuth);
        } else {
            g_kFolderMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU,BACKMENU], 0, iAuth);
        }
    }
}

RemAttached(key keyID, integer iAuth,string sFolders) {
    string sPrompt = "\nOutfits ";
    sPrompt = "\n\nRemove Attachment by Name";
    list lMyButtons;

    lMyButtons += llParseString2List(sFolders,[","],[""]);
    // and dispay the menu
    g_kRemAttachedMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

integer UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    sStr=llToLower(sStr);
    if (!(iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)) {
        return FALSE;
    } else if (sStr == "outfits" || sStr == "menu outfits") {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    } else if (llSubStringIndex(sStr,"outfits ") == 0) {
        sStr = llDeleteSubString(sStr,0,llStringLength("outfits ")-1);
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
    if (remenu) {
        DoMenu(kID, iNum);
    }
    return TRUE;
}

string WearFolder (string sStr) { //function grabs g_sCurrentPath, and splits out the final directory path, attaching .alwaysadd directories and passes RLV commands
    string sOutput;
    string sPrePath;
    list lTempSplit = llParseString2List(sStr,["/"],[]);
    lTempSplit = llList2List(lTempSplit,0,llGetListLength(lTempSplit) -2);
    sPrePath = llDumpList2String(lTempSplit,"/");
    if (g_sPathPrefix + "/" == sPrePath) { //
        sOutput = "@remoutfit=force,detach=force,attachallover:"+sStr+"=force,attachallover:"+g_sPathPrefix+"/.alwaysadd/=force";
    }
    else {
        sOutput = "@remoutfit=force,detach=force,attachallover:"+sStr+"=force,attachallover:"+g_sPathPrefix+"/.alwaysadd/=force,attachallover:"+sPrePath+"/.alwaysadd/=force";
    }
   // llOwnerSay("rlv:"+sOutput);
    return sOutput;
}


default {

    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
    }
    timer()
    {
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
            FolderMenu(g_kMenuClicker,COMMAND_OWNER,sMsg); //we use g_kMenuClicker to respond to the person who asked for the menu
        }
        else if (iChan == g_iFolderRLVSearch) {
            if (sMsg == "") {
                Notify(kID,"That outfit cannot be found in #RLV/"+g_sPathPrefix,FALSE);
            } else { // we got a match
                if (llSubStringIndex(sMsg,",") < 0) {
                    llOwnerSay(WearFolder(sMsg));
                    g_sCurrentPath = sMsg;
                    //llOwnerSay("@attachallover:"+g_sPathPrefix+"/.alwaysadd/=force");
                    Notify(kID,"Loading outfit #RLV/"+sMsg,FALSE);
                } else {
                    string sPrompt = "Multiple folders found.  Please select from the following list...";
                    list lFolderMatches = llParseString2List(sMsg,[","],[]);
                    g_kMultipleMatchMenuID = Dialog(g_kMenuClicker, sPrompt, lFolderMatches, [UPMENU], 0, COMMAND_OWNER);
                }
            }
        }
    }
    link_message(integer iSender, integer iNum, string sStr, key kID) { 
       // llOwnerSay(sStr+" | "+(string)iNum);
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        }
/*         else if (iNum == LM_SETTING_RESPONSE) {
            // response from setting store have been received, parse the answer
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            
            // and check if any values for use are received
          //  if (sToken == "test") {
          //      if (sValue == (string)1) { g_iCaptureOn = TRUE; }
          //  }
            if (sToken == "Global_CType") CTYPE = sValue;
        }
*/
        else if (iNum == RLV_ON) {
            g_iRlvOn = TRUE;
        }
        else if (iNum == RLVA_VERSION) { 
            g_iRlvaOn = TRUE;
         }
        else if (iNum == COMMAND_SAFEWORD) { 
            // Safeword has been received, release any restricitions that should be released
         }
        else if (UserCommand(iNum, sStr, kID, FALSE)) {
                    // do nothing more if TRUE
        }
        else if (iNum == DIALOG_RESPONSE) { 

            list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
            string sMessage = llList2String(lMenuParams, 1); // button label
            integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
            integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar

            if (kID == g_kMenuID) {
                //got a menu response meant for us, extract the values
                // request to switch to parent menu
                if (sMessage == UPMENU) {
                    //give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu "+COLLAR_PARENT_MENU, kAv);
                } 
                else if (sMessage == "Browse") {
                    g_kMenuClicker = kAv; //on our listen response, we need to know who to pop a dialog for
                    g_sCurrentPath = g_sPathPrefix + "/";
                    llSetTimerEvent(g_iTimeOut);
                    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
                    llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                   
                }

            }
            if (kID == g_kFolderMenuID || kID == g_kMultipleMatchMenuID) {
                  g_kMenuClicker = kAv;
                  if (sMessage == UPMENU) {
                      //give av the parent menu
                      llMessageLinked(LINK_THIS, iAuth, "menu "+SUBMENU_BUTTON, kAv);
                  }
                  else if (sMessage == BACKMENU) {
                    list lTempSplit = llParseString2List(g_sCurrentPath,["/"],[]);
                    lTempSplit = llList2List(lTempSplit,0,llGetListLength(lTempSplit) -2);
                    g_sCurrentPath = llDumpList2String(lTempSplit,"/") + "/";
                    llSetTimerEvent(g_iTimeOut);
                    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
                    llOwnerSay("@getinv:"+g_sCurrentPath+"="+(string)g_iFolderRLV);
                  }
                  else if (sMessage == "WEAR") {
                    llOwnerSay(WearFolder(g_sCurrentPath));
                    //llOwnerSay("@attachallover:"+g_sPathPrefix+"/.alwaysadd/=force");
                  }
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
