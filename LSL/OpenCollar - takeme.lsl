////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - takeme                                //
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


string  SUBMENU_BUTTON              = "TakeMe"; // Name of the submenu
string  COLLAR_PARENT_MENU          = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore

key     g_kMenuID;                              // menu handler
key     g_kWearer;                              // key of the current wearer to reset only on owner changes
key     g_kClicker;                             //capture clicker IDs
string  g_sScript                   ="TakeMe_";                              // part of script name used for settings
string CTYPE                        = "collar";    // designer can set in notecard to appropriate word for their item        
list g_lTempOwners;
integer g_iLimitDistance = 3;                     //meters away from the wearer before they can be captured
integer g_iTakeMeForce = FALSE;
integer g_iCaptureOn=FALSE;
list g_lRequests;                               //list of requests coming in
list g_lRequests_Names;                         //And their names
string WEARERNAME;

string TICKED = "☒ ";
string UNTICKED = "☐ ";

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
// added for timer so when the sub is locked out they can use postions
integer COMMAND_WEARERLOCKEDOUT    = 521;

integer ATTACHMENT_REQUEST         = 600;
integer ATTACHMENT_RESPONSE        = 601;
integer ATTACHMENT_FORWARD         = 610;

integer WEARERLOCKOUT              = 620; // turns on and off wearer lockout

// integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.
// This is to reduce even the tiny bit of lag caused by having IM slave scripts
integer POPUP_HELP                 = 1001;

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

// messages for poses and couple anims
integer ANIM_START                 = 7000; // send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP                  = 7001; // send this with the name of an anim in the string part of the message to stop the anim
integer CPLANIM_PERMREQUEST        = 7002; // id should be av's key, str should be cmd name "hug", "kiss", etc
integer CPLANIM_PERMRESPONSE       = 7003; // str should be "1" for got perms or "0" for not.  id should be av's key
integer CPLANIM_START              = 7004; // str should be valid anim name.  id should be av
integer CPLANIM_STOP               = 7005; // str should be valid anim name.  id should be av

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
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DoMenu(key keyID, integer iAuth) {
    string sPrompt = "\n"+SUBMENU_BUTTON;
    list lMyButtons;
    if (g_iCaptureOn){
        sPrompt += "ON";
        lMyButtons += "OFF";
    } else {
        lMyButtons += "ON";
        sPrompt += "OFF";
    }
    if (g_iLimitDistance) {
        lMyButtons += TICKED+"LimitDistance";
    } else {
        lMyButtons += UNTICKED+"LimitDistance";
    }
    if (g_iTakeMeForce) {
        lMyButtons += TICKED+"ForceTake";
    } else {
        lMyButtons += UNTICKED+"ForceTake";
    }
    if (llGetListLength(g_lRequests) > 0) {
        sPrompt += "\nThere are "+ (string)llGetListLength(g_lRequests) +" requests for capture...\n\n";
    }
    if (llGetListLength(g_lTempOwners) > 0) {
        sPrompt += "\nCurrent Temp Owners: ";
        integer i;
        integer x = llGetListLength(g_lTempOwners);
        for (i=1;i<=x;++i){
            sPrompt+=llList2String(g_lTempOwners,i) + ", ";
            ++i;
        }    
        lMyButtons += ["Reset"];
    }
    
    //fill in your button list and additional prompt here

    if (llGetListLength(g_lRequests) > 0) {
        sPrompt += "\n"+llList2String(g_lRequests_Names,0) +" wants to capture you...";
        lMyButtons += ["Allow","Reject"];
    }

    // and dispay the menu
    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

DoMenuAlt(key keyID, integer iAuth) { //This is for force (outsider) capture dialogs
    string sPrompt = "\n"+SUBMENU_BUTTON;
    sPrompt += "\nDo you want to capture "+WEARERNAME+"?";
    list lMyButtons;
    lMyButtons += ["Yes","No"];
    // and dispay the menu
    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [], 0, iAuth);
}

integer UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    sStr=llToLower(sStr);
    if (!(iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)) {
        return FALSE;
    } else if (sStr == "takeme" || sStr == "menu takeme") {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    }  else if (sStr == "takeme reset" ) {
        Notify(kID,"Temp owners list has been purged.",TRUE);
        g_lTempOwners=[];
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_tempowner", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "auth_tempowner", "");
    } else if (sStr == "takeme on")  {
        Notify(kID,"takeme game is ON!",TRUE);
        g_iCaptureOn=TRUE;
        llMessageLinked(LINK_SET, LM_SETTING_SAVE,g_sScript+ "takeme=1", "");
    } else if (sStr == "takeme off")  {
        Notify(kID,"takeme game is OFF!",TRUE);
        g_iCaptureOn=FALSE;
        llMessageLinked(LINK_SET, LM_SETTING_DELETE,g_sScript+ "takeme", "");
    } else if (sStr == "takeme limitdistance off") {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE,g_sScript+ "limitdistance", "");
        g_iLimitDistance = FALSE;
        Notify(kID,"TakeMe limit distance disabled!",TRUE);
    } else if (sStr == "takeme limitdistance on") {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE,g_sScript+ "limitdistance=3", "");
        g_iLimitDistance = 3;
        Notify(kID,"TakeMe limit distance now set to 3 meters!",TRUE);
    } else if (llSubStringIndex(sStr,"takeme limitdistance ") >= 0) {
        integer iTest = llList2Integer(llParseString2List(sStr,[" "],[]),2);
        if (iTest > 0) { //lets make sure we have a real number here (zero is not valid)
            Notify(kID,"TakeMe limit distance now set to "+(string)iTest+" meters!",TRUE);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE,g_sScript+ "limitdistance="+(string)iTest, "");
            g_iLimitDistance = iTest;
        } 
        else {
            Notify(kID,"<prefix>takeme limitdistance <distance in meters>",TRUE);
        }
    } else if (sStr == "takeme force on") {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE,g_sScript+ "force=1", "");
        g_iTakeMeForce = TRUE;
        Notify(kID,"TakeMe will allow you to be forcefully captured!",TRUE);
    } else if (sStr == "takeme force off") {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE,g_sScript+ "force", "");
        g_iTakeMeForce = FALSE;
        Notify(kID,"TakeMe will prompt you for all capture requests!",TRUE);
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
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "auth", "tempowner");
    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer)  llResetScript();
    }
    touch_start(integer num_detected)
    {
        key kToucher = llDetectedKey(0);
        if (kToucher == llGetOwner()) {return;}
        if (g_iLimitDistance) {
            float fDistance=llVecDist(llDetectedPos(0),llGetPos());
            if (fDistance > (float)g_iLimitDistance) {
                Notify(kToucher,"You are not close enough to "+WEARERNAME+" to take control of their "+CTYPE,FALSE);
                return;
            }
        }
        llMessageLinked(LINK_SET,0,"TempOwner~"+llDetectedName(0)+"~"+(string)kToucher,kToucher);
    }
    link_message(integer iSender, integer iNum, string sStr, key kID) { 
       // llOwnerSay(sStr+" | "+(string)iNum+ "|"+(string)kID);
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        } 
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
            
            // and check if any values for use are received
            if (sToken == g_sScript+"takeme") {
                if (sValue == (string)1) { g_iCaptureOn = TRUE; }
            }
            else if (sToken == g_sScript+"limitdistance") {
                g_iLimitDistance = (integer)sValue;
            }
            else if (sToken == g_sScript+"force") {
                g_iTakeMeForce = (integer)sValue;
            }
            else if (sToken == "auth_tempowner") {
                g_lTempOwners = llParseString2List(sValue, [","], []); //store tempowners list
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (iNum == COMMAND_SAFEWORD) { 
            // Safeword has been received, release any restricitions that should be released
            UserCommand(COMMAND_OWNER,"takeme reset",g_kWearer,FALSE);
            UserCommand(COMMAND_OWNER,"takeme off",g_kWearer,FALSE);
        }
        else if (UserCommand(iNum, sStr, kID, FALSE)) {
                    // do nothing more if TRUE
        }
        else if (iNum == COMMAND_EVERYONE && g_iCaptureOn) {
            if (llSubStringIndex(sStr,"TempOwner") == 0) {
                list lSplit = llParseString2List(sStr, ["~"], []);
                string sName = llList2String(lSplit,1);
                key kKey = llList2Key(lSplit,2);
//                llOwnerSay(sName + " " +(string)kKey);
                if (llListFindList(g_lRequests,llList2List(lSplit,2,2)) >=0) {
                        //do nothing
                } else {
                        g_lRequests += llList2List(lSplit,2,2);
                        g_lRequests_Names += llList2List(lSplit,1,1);
                        if (g_iTakeMeForce) {
                            DoMenuAlt(kID,COMMAND_EVERYONE);
                        }
                        else {
                            DoMenu(g_kWearer,COMMAND_WEARER);
                        }
                }
            }
        }
        else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kMenuID) {
                //got a menu response meant for us, extract the values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                // request to switch to parent menu
                if (sMessage == UPMENU) {
                    //give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu "+COLLAR_PARENT_MENU, kAv);
                } 

                else if (sMessage == "Allow" || sMessage == "Yes") {
                    if (g_iCaptureOn) {
                        if (g_iTakeMeForce) { //this is coming from a captor, so lets find them in our queue
                            integer iRequestIndex = llListFindList(g_lRequests,[(string)kAv]);
                            if (iRequestIndex < 0) return; //we failed somehow...
                            Notify(llList2Key(g_lRequests,iRequestIndex),llList2String(g_lRequests_Names,iRequestIndex)+" has captured "+WEARERNAME,TRUE);
                            g_lTempOwners+=[llList2Key(g_lRequests,iRequestIndex),llList2String(g_lRequests_Names,iRequestIndex)];
                            g_lRequests = llDeleteSubList(g_lRequests,iRequestIndex,iRequestIndex); //remove this from queue
                            g_lRequests_Names = llDeleteSubList(g_lRequests_Names,iRequestIndex,iRequestIndex); //remove from queue
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
                            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "auth_tempowner", "");
                        } else {
                            Notify(llList2Key(g_lRequests,0),llList2String(g_lRequests_Names,0)+" has captured "+WEARERNAME,TRUE);
                            g_lTempOwners+=[llList2Key(g_lRequests,0),llList2String(g_lRequests_Names,0)];
                            g_lRequests = llDeleteSubList(g_lRequests,0,0); //remove this from queue
                            g_lRequests_Names = llDeleteSubList(g_lRequests_Names,0,0); //remove from queue
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
                            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "auth_tempowner", "");
                            DoMenu(g_kWearer,iAuth);
                        }
                    }
                }
                else if (sMessage == "Reject" || sMessage == "No") {
                    if (g_iCaptureOn) {
                        if (g_iTakeMeForce) {
                            Notify(kAv,"You have decided to neglect the poor soul of "+WEARERNAME+".  Shame on you...",FALSE);
                            integer iRequestIndex = llListFindList(g_lRequests,[(string)kAv]);
                            g_lRequests = llDeleteSubList(g_lRequests,iRequestIndex,iRequestIndex); //remove this from queue
                            g_lRequests_Names = llDeleteSubList(g_lRequests_Names,iRequestIndex,iRequestIndex); //remove from queue
                            return;
                        }
                        Notify(kAv,"You have rejected temporary ownership by "+llList2String(g_lRequests_Names,0),FALSE);
                        g_lRequests = llDeleteSubList(g_lRequests,0,0); //remove this from queue
                        g_lRequests_Names = llDeleteSubList(g_lRequests_Names,0,0); //remove from queue
                        DoMenu(g_kWearer,iAuth);
                    }
                }
                else if (sMessage == "OFF") {
                    UserCommand(iAuth,"takeme reset",kAv,FALSE);
                    UserCommand(iAuth,"takeme off",kAv,TRUE);
                }
                else if (sMessage == "ON") {
                    UserCommand(iAuth,"takeme on",kAv,TRUE);
               }
                else if (sMessage == "Reset") {
                    UserCommand(iAuth,"takeme reset",kAv,TRUE);
               }
               else if (sMessage == TICKED+"LimitDistance") {
                   UserCommand(iAuth,"takeme limitdistance off",kAv,TRUE);
               }
               else if (sMessage == UNTICKED+"LimitDistance") {
                   UserCommand(iAuth,"takeme limitdistance on",kAv,TRUE);
               }
               else if (sMessage == TICKED+"ForceTake") {
                   UserCommand(iAuth,"takeme force off",kAv,TRUE);
               }
               else if (sMessage == UNTICKED+"ForceTake") {
                   UserCommand(iAuth,"takeme force on",kAv,TRUE);
               }                
            }
       }
   }
}
