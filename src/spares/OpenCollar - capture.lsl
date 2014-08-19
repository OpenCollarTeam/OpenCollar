//tempowner demo app

string  SUBMENU_BUTTON              = "Capture"; // Name of the submenu
string  COLLAR_PARENT_MENU          = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore

key     g_kMenuID;                              // menu handler
key     g_kWearer;                              // key of the current wearer to reset only on owner changes
string  g_sScript="capture_";                              // part of script name used for settings
string CTYPE                        = "collar";    // designer can set in notecard to appropriate word for their item        
list g_lTempOwners;
integer g_iCaptureOn=FALSE;
// OpenCollar MESSAGE MAP

// messages for authenticating users
// integer COMMAND_NOAUTH = 0; // for reference, but should usually not be in use inside plugins
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
    string sPrompt = "\nCapture";
    list lMyButtons = ["Reset"];

    //fill in your button list and additional prompt here
    if (g_iCaptureOn){
        lMyButtons += "OFF";
    } else {
        lMyButtons += "ON";
    }

    // and dispay the menu
    g_kMenuID = Dialog(keyID, "\n\nCapture\n", lMyButtons, [UPMENU], 0, iAuth);
}

integer UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    sStr=llToLower(sStr);
    //Debug("Got user command "+sStr);
    if (!(iNum >= COMMAND_OWNER && iNum <= COMMAND_EVERYONE)) {
        return FALSE;
    } else if (sStr == "capture" || sStr == "menu capture") {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    } else if (sStr == "capture you" && g_iCaptureOn) {
        //add kID to the temp owner list, if they're not already there
        if (g_kWearer != llGetOwnerKey(kID) && iNum != COMMAND_OWNER ) {  //owners, tempowners and wearer can't be tempowner
            Notify(kID,llKey2Name(g_kWearer)+" has been captured by "+llKey2Name(kID),TRUE);
            g_lTempOwners+=[kID,llKey2Name(kID)];
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "auth_tempowner="+llDumpList2String(g_lTempOwners,","), "");
        } else {
            Notify(kID,llKey2Name(g_kWearer)+" cannot be captured by "+llKey2Name(kID),TRUE);
        }
    } else if (sStr == "capture reset" && iNum==COMMAND_OWNER ) {
        Notify(kID,"Temp owners list has been purged.",TRUE);
        g_lTempOwners=[];
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_tempowner", "");
        llMessageLinked(LINK_SET, LM_SETTING_EMPTY, "auth_tempowner", "");
    } else if (sStr == "capture on" && iNum==COMMAND_OWNER && ! g_iCaptureOn)  {
        Notify(kID,"Capture game is ON!",TRUE);
        g_iCaptureOn=TRUE;
        llWhisper(0,"You can own "+llKey2Name(g_kWearer)+" for a while by sending the command 'capture you' to their collar, if you know their prefix");
    } else if (sStr == "capture off" && iNum==COMMAND_OWNER && g_iCaptureOn)  {
        Notify(kID,"Capture game is OFF!",TRUE);
        g_iCaptureOn=FALSE;
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
    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer)  llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        } else if (iNum == LM_SETTING_RESPONSE) {
            // response from setting store have been received, parse the answer
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            // and check if any values for use are received
            
            if (sToken == "auth_tempowner") {
                list lTempOwners = llParseString2List(sValue, [","], []); //store tempowners list
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (UserCommand(iNum, sStr, kID, FALSE)) {
            // do nothing more if TRUE
        }
        else if (iNum == COMMAND_SAFEWORD) {
            // Safeword has been received, release any restricitions that should be released
            Notify(g_kWearer,"Capture game is OFF!",TRUE);
            g_iCaptureOn=FALSE;
            Notify(g_kWearer,"Temp owners list has been purged.",TRUE);
            g_lTempOwners=[];
            llMessageLinked(LINK_SET, LM_SETTING_EMPTY, "auth_tempowner", "");
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
                } else {
                    UserCommand(iAuth, "capture "+sMessage, kAv, TRUE);
                }
            }
        }
    }
}
