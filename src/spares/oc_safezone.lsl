// This file is part of OpenCollar.
// Copyright (c) 2014 - 2015 Sumi Perl et. al               
// Licensed under the GPLv2.  See LICENSE for full details. 

string SUBMENU_BUTTON = "SafeZone"; // Name of the submenu
string COLLAR_PARENT_MENU = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string g_sAppName = "safezone";     //used to change the name of the app itself (and setting prefixes)
key g_kMenuID;                      // menu handler
key g_kMenuRemoveID;                // remove menu handler
key g_kWearer;                      // key of the current wearer to reset only on owner changes
string  g_sScript = "SafeZone_";    // part of script name used for settings

integer g_iSafeZoneOn = FALSE;
integer g_iAllowList = FALSE;
integer g_iDenyList = FALSE;        //default behavior
integer g_iStealth = FALSE;         //hide/show collar when inactive

list g_lRegions;

string CTYPE = "collar";            // designer can set in notecard to appropriate word for their item        
string WEARERNAME;

string TICKED = "☒ ";
string UNTICKED = "☐ ";

integer CMD_OWNER = 500;
//integer CMD_SECOWNER = 501;
integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLACKLIST = 520;

// messages for storing and retrieving values from settings store
integer LM_SETTING_SAVE = 2000;     // scripts send messages on this channel to have settings saved to settings store
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002; // the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;   // delete token from settings store
//integer LM_SETTING_EMPTY = 2004; 

// messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

// messages to the dialog helper
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;


// menu option to go one step back in menustructure
string  UPMENU = "BACK";            // when your menu hears this, give the parent menu


//Debug(string sMsg) { llOwnerSay(llGetScriptName() + " [DEBUG]: " + sMsg);}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

CheckRegion() {
    string sRegion = llGetRegionName();
    if (g_iSafeZoneOn) {
        integer iIndex = llListFindList(g_lRegions,[sRegion]);
        if (g_iAllowList) { //we allow public modes here //g_iStealth
            if (iIndex < 0) {
                llMessageLinked(LINK_THIS, CMD_OWNER, "public off", g_kWearer);
                if (g_iStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "hide", g_kWearer);
            }
            else {
                llMessageLinked(LINK_THIS, CMD_OWNER, "public on", g_kWearer);
                if (g_iStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "show", g_kWearer);
            }
        }
        else if (g_iDenyList) { //we deny public modes here
            if (iIndex < 0) {
                llMessageLinked(LINK_THIS, CMD_OWNER, "public on", g_kWearer);
                if (g_iStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "show", g_kWearer);
            }
            else {
                llMessageLinked(LINK_THIS, CMD_OWNER, "public off", g_kWearer); 
                if (g_iStealth) llMessageLinked(LINK_THIS, CMD_OWNER, "hide", g_kWearer);
            }
        }
    }
}

DoMenu(key keyID, integer iAuth) {
    string sPrompt = "\n"+SUBMENU_BUTTON;
    list lMyButtons;
    if (g_iSafeZoneOn == TRUE){
        sPrompt += " is ON";
        lMyButtons += "OFF";
    } else {
        lMyButtons += "ON";
        sPrompt += " is OFF";
    }
    if (g_iAllowList) {
        lMyButtons += TICKED+"Allow";
        sPrompt += "\nAllow ON (allow public modes in listed regions) ";
    } else {
        lMyButtons += UNTICKED+"Allow";
        sPrompt += "\nDeny ON (public modes disabled in listed regions) ";
    }
    if (g_iDenyList) {
        lMyButtons += TICKED+"Deny";
    } else {
        lMyButtons += UNTICKED+"Deny";
    }
    if (g_iStealth) {
        lMyButtons += TICKED+"Stealth";
    } else {
        lMyButtons += UNTICKED+"Stealth";
    }
    lMyButtons += ["SAVE","REMOVE"];
    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

DoMenuRemove(key keyID, integer iAuth) {
    string sPrompt = "\n"+SUBMENU_BUTTON+" remove";
    g_kMenuRemoveID = Dialog(keyID, sPrompt, g_lRegions, [UPMENU], 0, iAuth);
}


integer UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    list lParams = llParseString2List(sStr,[" "],[]);
    string sParam0 = llList2String(lParams,0);
    string sParam1 = llList2String(lParams,1);
    string sParam2;
    if (llGetListLength(lParams) > 2) sParam2 = llDumpList2String(llList2List(lParams,2,-1)," ");
    sStr=llToLower(sStr);
    if (!(iNum >= CMD_OWNER && iNum <= CMD_GROUP)) { 
        return FALSE;
    } else if (sStr == g_sAppName || sStr == "menu "+g_sAppName) {
        // an authorized user requested the plugin menu by typing the menus chat command 
        DoMenu(kID, iNum);
    } else if (sStr == g_sAppName+" off")  {
        Notify(kID,SUBMENU_BUTTON+" plugin OFF!",TRUE);
        g_iSafeZoneOn=FALSE;
        llMessageLinked(LINK_THIS, LM_SETTING_DELETE,g_sScript+ g_sAppName, "");
        llMessageLinked(LINK_THIS, CMD_OWNER, "public off", g_kWearer);
    } else if (sStr == g_sAppName+" on")  {
        Notify(kID,SUBMENU_BUTTON+" plugin ON!",TRUE);
        g_iSafeZoneOn=TRUE;
        CheckRegion();
        llMessageLinked(LINK_THIS, LM_SETTING_SAVE,g_sScript+ g_sAppName+"=1", "");
    } else if (sStr == g_sAppName+" stealth on")  {
        Notify(kID,SUBMENU_BUTTON+" Stealth mode active!",TRUE);
        g_iStealth=TRUE;
        CheckRegion();
        llMessageLinked(LINK_THIS, LM_SETTING_SAVE,g_sScript+ "stealth=1", "");
    } else if (sStr == g_sAppName+" stealth off")  {
        Notify(kID,SUBMENU_BUTTON+" Stealth mode deactivated!",TRUE);
        llMessageLinked(LINK_THIS, CMD_OWNER, "show", g_kWearer);
        g_iStealth=FALSE;
        CheckRegion();
        llMessageLinked(LINK_THIS, LM_SETTING_DELETE,g_sScript+ "stealth", "");
    } else if (sStr == g_sAppName+" allow")  {
        Notify(kID,SUBMENU_BUTTON+" is set to allow public modes in it's list of regions!",TRUE);
        g_iAllowList=TRUE;
        g_iDenyList=FALSE;
        CheckRegion();
        llMessageLinked(LINK_THIS, LM_SETTING_SAVE,g_sScript+ "allow=1", "");
        llMessageLinked(LINK_THIS, LM_SETTING_DELETE,g_sScript+ "deny", "");
    } else if (sStr == g_sAppName+" deny")  {
        Notify(kID,SUBMENU_BUTTON+" is set to deny public modes in it's list of regions!",TRUE);
        g_iAllowList=FALSE;
        g_iDenyList=TRUE;
        CheckRegion();
        llMessageLinked(LINK_THIS, LM_SETTING_SAVE,g_sScript+ "deny=1", "");
        llMessageLinked(LINK_THIS, LM_SETTING_DELETE,g_sScript+ "allow", "");
    } else if ((sParam0 == g_sAppName) && (sParam1 == "add")) {
        string sRegion;
        if ( sParam2 == "") {
            sRegion =  llGetRegionName();
        } else {
            sRegion = sParam2;
        }
        integer iIndex = llListFindList(g_lRegions,[sRegion]);
        if (iIndex < 0) { //we don't track this region.  Let's add it
            g_lRegions += [sRegion];
            Notify(kID,SUBMENU_BUTTON+" added "+sRegion+" to the list of regions",TRUE);
            llMessageLinked(LINK_THIS, LM_SETTING_SAVE,g_sScript + sRegion+"=1", "");
            CheckRegion();
        }
        else Notify(kID,SUBMENU_BUTTON+" we already have "+sParam2+" in the current list of regions.",FALSE);
    } else if ((sParam0 == g_sAppName) && (sParam1 == "remove")) {
        string sRegion;
        if ( sParam2 == "") {
            sRegion =  llGetRegionName();
        } else {
            sRegion = sParam2;
        }
        integer iIndex = llListFindList(g_lRegions,[sRegion]);
        if (iIndex >= 0) { //we already have this region, so we can delete it
            g_lRegions = llDeleteSubList(g_lRegions,iIndex,iIndex);
            Notify(kID,SUBMENU_BUTTON+" removed "+sRegion+" to the list of regions",TRUE);
            llMessageLinked(LINK_THIS, LM_SETTING_DELETE,g_sScript + sRegion, "");
            CheckRegion();
        }
        else Notify(kID,SUBMENU_BUTTON+" can't find "+sParam2+" in the current list of regions.",FALSE);
    }

    if (remenu) {
        DoMenu(kID, iNum);
    }
    return TRUE;
}



default {

    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        WEARERNAME = llGetDisplayName(g_kWearer);
        if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME = llKey2Name(g_kWearer); //sanity check, fallback if necessary
        CheckRegion();
    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer)  llResetScript();
        CheckRegion();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) { 
       // llOwnerSay(sStr+" | "+(string)iNum+ "|"+(string)kID);
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        } /* 
        else if ((iNum == LM_SETTING_DELETE) || (iNum == LM_SETTING_SAVE) || (iNum == LM_SETTING_RESPONSE)) { //listen for changes to auth_openaccess and takeme_takeme
            if (llSubStringIndex(sStr, "auth_openaccess") == 0) {
                if (iNum == LM_SETTING_DELETE) g_iOpenAccess = FALSE;
                else { if (g_iOpenAccess == FALSE) g_iOpenAccess = TRUE; CheckRegion(); }
            }
            else if (llSubStringIndex(sStr, "takeme_takeme") == 0) {
                if (iNum == LM_SETTING_DELETE) g_iTakeMe = FALSE;
                else { if (g_iTakeMe == FALSE) g_iTakeMe = TRUE; CheckRegion(); }
            }
        } */
        else if ((iNum == LM_SETTING_RESPONSE || iNum == LM_SETTING_DELETE) 
                && llSubStringIndex(sStr, "Global_WearerName") == 0 ) {
            integer iInd = llSubStringIndex(sStr, "=");
            string sValue = llGetSubString(sStr, iInd + 1, -1);
            //We have a broadcasted change to WEARERNAME to work with
            if (iNum == LM_SETTING_RESPONSE) WEARERNAME = sValue;
            else {
                g_kWearer = llGetOwner();
                WEARERNAME = llGetDisplayName(g_kWearer);
                if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME == llKey2Name(g_kWearer);
            }
        }        
        else if (iNum == LM_SETTING_RESPONSE) {
            // response from setting store have been received, parse the answer
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            // and check if any values for use are received
            if (sToken == g_sScript+g_sAppName) g_iSafeZoneOn = TRUE; 
            else if (sToken == g_sScript+"allow") g_iAllowList = TRUE;
            else if (sToken == g_sScript+"deny") g_iDenyList = TRUE; 
            else if (sToken == g_sScript+"stealth") g_iStealth = TRUE;
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (llGetSubString(sToken, 0, i) == g_sScript) { //hack up the token to pull the region name from "script_regionname=1"
                string sTmpRegion = llGetSubString(sToken, llSubStringIndex(sToken, "_") + 1, llSubStringIndex(sToken, "="));
                if(llListFindList(g_lRegions, [sTmpRegion]) < 0) { //make sure we don't have this yet in our list
                    g_lRegions += sTmpRegion; 
                }
            }
        }
        else if (iNum == CMD_SAFEWORD) { 
            // Safeword has been received, release any restricitions that should be released
            // We're not really doing something that would warrant steps here
        }
        else if (UserCommand(iNum, sStr, kID, FALSE)) {
                    // do nothing more if TRUE
        }

        else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kMenuID) {
                //got a menu response meant for us, extract the values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                // integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                // request to switch to parent menu
                if (sMessage == UPMENU) {
                    //give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu "+COLLAR_PARENT_MENU, kAv);
                } 

                else if (sMessage == "OFF") {
                    UserCommand(iAuth,g_sAppName+" off",kAv,TRUE);
                }
                else if (sMessage == "ON") {
                    UserCommand(iAuth,g_sAppName+" on",kAv,TRUE);
               }
               else if (sMessage == UNTICKED+"Allow") {
                   UserCommand(iAuth,g_sAppName+" allow",kAv,TRUE);
               }
               else if (sMessage == UNTICKED+"Deny") {
                   UserCommand(iAuth,g_sAppName+" deny",kAv,TRUE);
               }
               else if (sMessage == UNTICKED+"Stealth") {
                   UserCommand(iAuth,g_sAppName+" stealth on",kAv,TRUE);
               }
               else if (sMessage == TICKED+"Stealth") {
                   UserCommand(iAuth,g_sAppName+" stealth off",kAv,TRUE);
               }
               else if (sMessage == "SAVE") {
                   UserCommand(iAuth,g_sAppName+" add",kAv,TRUE);
               }
               else if (sMessage == "REMOVE") {
                   DoMenuRemove(kAv,iAuth);
               }
            }
            if (kID == g_kMenuRemoveID) {
                //got a menu response meant for us, extract the values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                // integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                // request to switch to parent menu
                if (sMessage == UPMENU) {
                    //give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu "+SUBMENU_BUTTON, kAv);
                } 
                 else if(~llListFindList(g_lRegions, [sMessage])) {
                    UserCommand(iAuth, g_sAppName + " remove " + sMessage, kAv,FALSE);
                    DoMenuRemove(kAv,iAuth);
                }

            }
       }
   }
    changed(integer change)
    {
        if (change & CHANGED_REGION) 
        {
            CheckRegion();
        }
    }
}
