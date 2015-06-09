////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           Virtual Disgrace - Kidnap                            //
//                                  version 2.6                                   //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
//               Copyright © 2008 - 2015: Individual Contributors,                //
//            OpenCollar - submission set free™ and Virtual Disgrace™             //
// ------------------------------------------------------------------------------ //
//                       github.com/VirtualDisgrace/Collar                        //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Based on OpenCollar - takeme 3.980
// Compatible with OpenCollar API   3.9
// and/or minimum Disgraced Version 1.3.2

key     g_kWearer;                       // key of the current wearer to reset only on owner changes
//string  g_sWearerName;
list    g_lMenuIDs;                      //menu information, 5 strided list, userKey, menuKey, menuName, kidnapperKey, kidnapperName
//string  g_sAuthError        = "Access denied.";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510; 
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

//integer POPUP_HELP          =  1001;
integer NOTIFY              =  1002;
integer SAY                 =  1004;

integer LM_SETTING_SAVE     =  2000;
integer LM_SETTING_REQUEST  =  2001;
integer LM_SETTING_RESPONSE =  2002;
integer LM_SETTING_DELETE   =  2003;
integer LM_SETTING_EMPTY    =  2004;

integer MENUNAME_REQUEST    =  3000;
integer MENUNAME_RESPONSE   =  3001;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

list    g_lTempOwners;                   // locally stored list of temp owners
integer g_iVulnerableOn     = FALSE;     // true means kidnapper confirms, false means wearer confirms
integer g_iCaptureOn        = FALSE;     // on/off toggle for the app.  Switching off clears tempowner list
string  g_sSettingToken     = "kidnap_";
//string  g_sGlobalToken      = "global_";

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

string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName, key kKidnapper, string sKidnapper) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName, kKidnapper, sKidnapper], iIndex, iIndex + 4);
    else g_lMenuIDs += [kID, kMenuID, sName, kKidnapper, sKidnapper];
    //Debug("Menu:"+sName);
}

KidnapMenu(key kId, integer iAuth) {
    string sPrompt = "\n[http://www.virtualdisgrace.com/collar#kidnap Virtual Disgrace - Kidnap]";
    list lMyButtons;
    if (llGetListLength(g_lTempOwners)) lMyButtons += "Release";
    else {
        if (g_iCaptureOn) lMyButtons += "OFF";
        else lMyButtons += "ON";

        if (g_iVulnerableOn) lMyButtons += "☒ vulnerable";
        else lMyButtons += "☐ vulnerable";
    }
    if (llGetListLength(g_lTempOwners) > 0) {
        sPrompt += "\n\nKidnapped by: "+NameURI(llList2Key(g_lTempOwners,0));
    }
    Dialog(kId, sPrompt, lMyButtons, ["BACK"], 0, iAuth, "KidnapMenu", "", "");
}

saveTempOwners() {
    if (llGetListLength(g_lTempOwners)) {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
    } else {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_tempowner", "");
        llMessageLinked(LINK_SET, LM_SETTING_EMPTY, "auth_tempowner", "");
    }
}

doCapture(key kKidnapper, string sKidnapper, integer iIsConfirmed) {
    if (llGetListLength(g_lTempOwners)) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% is already kidnapped, try another time.",kKidnapper);//Notify(kKidnapper, g_sWearerName + " is already kidnapped, try another time.", FALSE);
        return;
    }
    if (!iIsConfirmed) {
        Dialog(g_kWearer, "\nsecondlife:///app/agent/"+(string)kKidnapper+"/about wants to kidnap you...", ["Allow","Reject"], ["BACK"], 0, CMD_WEARER, "AllowKidnapMenu", kKidnapper, sKidnapper);
    }
    else {
        //added a follow and yank
        llMessageLinked(LINK_SET, CMD_OWNER, "follow " + (string)kKidnapper, kKidnapper);
        llMessageLinked(LINK_SET, CMD_OWNER, "yank", kKidnapper);
        llMessageLinked(LINK_SET, NOTIFY, "0"+"You are at "+NameURI(kKidnapper)+"'s whim.",g_kWearer);
        llMessageLinked(LINK_SET, NOTIFY, "0"+"%WEARERNAME% is at your mercy.\n\n/%CHANNEL%%PREFIX%menu\n/%CHANNEL%%PREFIX%pose\n/%CHANNEL%%PREFIX_restrictions\n/%CHANNEL%%PREFIX_sit\n/%CHANNEL%%PREFIX%help\n\nNOTE: During kidnap RP %WEARERNAME% cannot refuse your teleport offers and you will keep full control. To end the kidnapping, please type: /%CHANNEL%%PREFIX%kidnap release\n\nHave fun! www.virtualdisgrace.com\n", kKidnapper);
        g_lTempOwners+=[kKidnapper,sKidnapper];
        saveTempOwners();
        llSetTimerEvent(0.0);
    }
}

UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    string sStrLower=llToLower(sStr);
    if (llSubStringIndex(sStr,"kidnap TempOwner") == 0){
        list lSplit = llParseString2List(sStr, ["~"], []);
        key kKidnapper=(key)llList2String(lSplit,2);
        string sKidnapper=llList2String(lSplit,1);
        if (iNum==CMD_OWNER || iNum==CMD_TRUSTED || iNum==CMD_GROUP) { //do nothing, owners get their own menu but cannot kidnap
        } 
        else Dialog(kID, "\nYou can try to kidnap %WEARERNAME%.\n\nReady for that?", ["Yes","No"], [], 0, iNum, "ConfirmKidnapMenu", kKidnapper, sKidnapper);
    } 
    else if (sStrLower == "kidnap" || sStrLower == "menu kidnap") {
        if  (iNum!=CMD_OWNER && iNum != CMD_WEARER) {
            if (g_iCaptureOn) Dialog(kID, "\nYou can try to kidnap %WEARERNAME%.\n\nReady for that?", ["Yes","No"], [], 0, iNum, "ConfirmKidnapMenu", kID, llKey2Name(kID));
            else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        } else KidnapMenu(kID, iNum); // an authorized user requested the plugin menu by typing the menus chat command
    }
    else if (iNum!=CMD_OWNER && iNum != CMD_WEARER){
        //silent fail, no need to do anything more in this case
    } 
    else if (llSubStringIndex(sStrLower,"kidnap")==0) {
        if (llGetListLength(g_lTempOwners)>0 && kID==g_kWearer) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",g_kWearer);
            return;
        } else if (sStrLower == "kidnap on") {
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Kidnap Mode activated",kID);
            if (g_iVulnerableOn) {
                llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can kidnap me if you touch my neck...","");
                llSetTimerEvent(900.0);
            }
            g_iCaptureOn=TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE,g_sSettingToken+"kidnap=1", "");
        } else if (sStrLower == "kidnap off") {
            if(g_iCaptureOn) llMessageLinked(LINK_SET,NOTIFY,"1"+"Kidnap Mode deactivated",kID);
            g_iCaptureOn=FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE,g_sSettingToken+"kidnap", "");
            g_lTempOwners=[];
            saveTempOwners();
            llSetTimerEvent(0.0);
        } else if (sStrLower == "kidnap release") {
            llMessageLinked(LINK_SET, CMD_OWNER, "unfollow", kID);
            llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(kID)+" has released you.",g_kWearer);
            llMessageLinked(LINK_SET,NOTIFY,"0"+"You have released %WEARERNAME%.",kID);
            g_lTempOwners=[];
            saveTempOwners();
            llSetTimerEvent(0.0);
            return;  //no remenuin case of release
        } else if (sStrLower == "kidnap vulnerable on") {
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"vulnerable=1", "");
            g_iVulnerableOn = TRUE;
            llMessageLinked(LINK_SET,NOTIFY,"0"+"You are vulnerable now...",g_kWearer);
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% is vulnerable now...",kID);
            if (g_iCaptureOn){
                 llSetTimerEvent(900.0);
                 llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can kidnap me if you touch my neck...","");
                }
        } else if (sStrLower == "kidnap vulnerable off") {
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"vulnerable", "");
            g_iVulnerableOn = FALSE;
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Kidnappings will require consent first.",kID);
            llSetTimerEvent(0.0);
        }
        if (remenu) KidnapMenu(kID, iNum);
    }
}

default{
    
    state_entry() {
        llSetMemoryLimit(32768); //2015-05-06 (4840 bytes free)
        g_kWearer = llGetOwner();
        //Debug("Starting");
    }
    
    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer)  llResetScript();
    }
    
    touch_start(integer num_detected) {
        key kToucher = llDetectedKey(0);
        if (kToucher == g_kWearer) return;  //wearer can't capture
        if (~llListFindList(g_lTempOwners,[(string)kToucher])) return;  //temp owners can't capture
        if (llGetListLength(g_lTempOwners)) return;  //no one can capture if already captured
        if (!g_iCaptureOn) return;  //no one can capture if disabled
        if (llVecDist(llDetectedPos(0),llGetPos()) > 10 ) llMessageLinked(LINK_SET,NOTIFY,"0"+"You could kidnap %WEARERNAME% if you get a bit closer.",kToucher);//Notify(kToucher,"You could kidnap "+g_sWearerName+" if you get a bit closer.",FALSE);
        else llMessageLinked(LINK_SET,0,"kidnap TempOwner~"+llDetectedName(0)+"~"+(string)kToucher,kToucher);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == "Main") llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|Kidnap", "");
        else if (iNum == CMD_SAFEWORD || (sStr == "runaway" && iNum == CMD_OWNER)) {
            if (iNum == CMD_SAFEWORD) llMessageLinked(LINK_SET,NOTIFY,"0"+"Kidnap Mode deactivated.", g_kWearer);//Notify(g_kWearer,"Kidnap Mode deactivated.",TRUE);
            g_iCaptureOn=FALSE;
            g_iVulnerableOn = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE,g_sSettingToken+"kidnap", "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE,g_sSettingToken+"vulnerable", "");
            g_lTempOwners=[];
            saveTempOwners();
            llSetTimerEvent(0.0);
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sSettingToken+"kidnap") g_iCaptureOn = (integer)sValue;  // check if any values for use are received
            else if (sToken == g_sSettingToken+"vulnerable") g_iVulnerableOn = (integer)sValue;
            else if (sToken == "auth_tempowner") g_lTempOwners = llParseString2List(sValue, [","], []); //store tempowners list
        } else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = llList2Integer(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex+1);
                key kKidnapper=llList2Key(g_lMenuIDs, iMenuIndex + 2);
                string sKidnapper=llList2String(g_lMenuIDs, iMenuIndex + 3);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
                if (sMenu=="KidnapMenu") {
                    if (sMessage == "BACK") llMessageLinked(LINK_THIS, iAuth, "menu Main", kAv);
                    else if (sMessage == "☒ vulnerable") UserCommand(iAuth,"kidnap vulnerable off",kAv,TRUE);
                    else if (sMessage == "☐ vulnerable") UserCommand(iAuth,"kidnap vulnerable on",kAv,TRUE);
                    else UserCommand(iAuth,"kidnap "+sMessage,kAv,TRUE);
                } else if (sMenu=="AllowKidnapMenu") {  //wearer must confirm when forced is off
                    if (sMessage == "BACK") llMessageLinked(LINK_THIS, iAuth, "menu kidnap", kAv);
                    else if (sMessage == "Allow") doCapture(kKidnapper, sKidnapper, TRUE);
                    else if (sMessage == "Reject") { 
                        llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(kKidnapper)+" didn't pass your face control. Sucks for them!",kAv);
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"Looks like %WEARERNAME% didn't want to be kidnapped after all. C'est la vie!",kKidnapper);
                    }
                } else if (sMenu=="ConfirmKidnapMenu") {  //kidnapper must confirm when forced is on
                    if (sMessage == "BACK") llMessageLinked(LINK_THIS, iAuth, "menu kidnap", kAv);
                    else if (g_iCaptureOn) {  //in case app was switched off in the mean time
                        if (sMessage == "Yes") doCapture(kKidnapper, sKidnapper, g_iVulnerableOn);
                        else if (sMessage == "No") llMessageLinked(LINK_SET,NOTIFY,"0"+"You let %WEARERNAME% be.",kAv);
                    } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% can no longer be kidnapped",kAv); 
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
    }
    
    timer() {
       //WhisperVulnerable();
        llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can kidnap me if you touch my neck...","");
    }
    
    changed(integer iChange) {
        if (iChange & CHANGED_TELEPORT) {
            if (llGetListLength(g_lTempOwners) == 0) {
                if (g_iVulnerableOn && g_iCaptureOn) {
                    //WhisperVulnerable();
                    llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME%: You can kidnap me if you touch my neck...","");
                    llSetTimerEvent(900.0);
                }
            }
        }
        /*if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    } 
}