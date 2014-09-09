////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - rlvcmd                                //
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


string  SUBMENU_BUTTON              = "RLVcmd"; // Name of the submenu
string  COLLAR_PARENT_MENU          = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore

key     g_kMenuID;                              // menu handler
key     g_kWearer;                              // key of the current wearer to reset only on owner changes
key     g_kClicker;                             //capture clicker IDs
string  g_sScript                   ="RLVcmd_";                              // part of script name used for settings
string CTYPE                        = "collar";    // designer can set in notecard to appropriate word for their item        
integer g_iRlvOn = FALSE;
integer g_iRlvaOn = FALSE;
integer g_iListenerHandle;
list g_lListeners;
key g_kRlvCommand;
list g_lRlvCommandHistory; //history of commands
integer g_iListenerChannel;
string WEARERNAME;

string TICKED = "☒ ";
string UNTICKED = "☐ ";

// OpenCollar MESSAGE MAP

// messages for authenticating users
// integer COMMAND_NOAUTH = 0; // for reference, but should usually not be in use inside plugins
//integer COMMAND_NOAUTH             = 0;
integer COMMAND_OWNER              = 500;
integer COMMAND_SECOWNER           = 501;
//integer COMMAND_GROUP              = 502;
integer COMMAND_WEARER             = 503;
integer COMMAND_EVERYONE           = 504;
//integer COMMAND_RLV_RELAY          = 507;
integer COMMAND_SAFEWORD           = 510;
//integer COMMAND_RELAY_SAFEWORD     = 511;
//integer COMMAND_BLACKLIST          = 520;
// added for timer so when the sub is locked out they can use postions
//integer COMMAND_WEARERLOCKEDOUT    = 521;

//integer ATTACHMENT_REQUEST         = 600;
//integer ATTACHMENT_RESPONSE        = 601;
//integer ATTACHMENT_FORWARD         = 610;

//integer WEARERLOCKOUT              = 620; // turns on and off wearer lockout

// integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.
// This is to reduce even the tiny bit of lag caused by having IM slave scripts
//integer POPUP_HELP                 = 1001;

// messages for storing and retrieving values from settings store
//integer LM_SETTING_SAVE            = 2000; // scripts send messages on this channel to have settings saved to settings store
//                                            str must be in form of "token=value"
//integer LM_SETTING_REQUEST         = 2001; // when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE        = 2002; // the settings script will send responses on this channel
integer LM_SETTING_DELETE          = 2003; // delete token from settings store
//integer LM_SETTING_EMPTY           = 2004; // sent by settings script when a token has no value in the settings store
//integer LM_SETTING_REQUEST_NOCACHE = 2005;

// messages for creating OC menu structure
integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
integer MENUNAME_REMOVE            = 3003;

// messages for RLV commands
integer RLV_CMD                    = 6000;
integer RLV_REFRESH                = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR                  = 6002; // RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION                = 6003; // RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer RLVA_VERSION               = 6004;
integer RLV_OFF                    = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON                     = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
integer RLV_QUERY                  = 6102; //query from a script asking if RLV is currently functioning
integer RLV_RESPONSE               = 6103; //reply to RLV_QUERY, with "ON" or "OFF" as the message

// messages for poses and couple anims
//integer ANIM_START                 = 7000; // send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP                  = 7001; // send this with the name of an anim in the string part of the message to stop the anim
//integer CPLANIM_PERMREQUEST        = 7002; // id should be av's key, str should be cmd name "hug", "kiss", etc
//integer CPLANIM_PERMRESPONSE       = 7003; // str should be "1" for got perms or "0" for not.  id should be av's key
//integer CPLANIM_START              = 7004; // str should be valid anim name.  id should be av
//integer CPLANIM_STOP               = 7005; // str should be valid anim name.  id should be av

// messages to the dialog helper
integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;

//integer FIND_AGENT                   = -9005; // to look for agent(s) in region with a (optional) search string
//key REQUEST_KEY;

//integer TIMER_EVENT                = -10000; // str = "start" or "end". For start, either "online" or "realtime".

//integer UPDATE                     = 10001;  // for child prim scripts (currently none in 3.8, thanks to LSL new functions)

// For other things that want to manage showing/hiding keys.
//integer KEY_VISIBLE                = -10100;
//integer KEY_INVISIBLE              = -10100;

//integer COMMAND_PARTICLE           = 20000;
//integer COMMAND_LEASH_SENSOR       = 20001;

//chain systems
//integer LOCKMEISTER                = -8888;
//integer LOCKGUARD                  = -9119;

//rlv relay chan
//integer RLV_RELAY_CHANNEL          = -1812221819;

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
    string sPrompt = "\n"+SUBMENU_BUTTON;
    list lMyButtons;
    if (g_iRlvOn){
        sPrompt += " Enabled.  Press CMD to enter a command.  Press HELP for a list of commands\n\n"+
                "[http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI RLVcmd Help Page]";
        lMyButtons += ["CMD","History"];
    } else {
        lMyButtons = [];
        sPrompt = "RLV is Disabled.  Please enable RLV to use this plugin.";
    }
    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

integer isInteger(string input) //for validating location scheme
{
    return ((string)((integer)input) == input);
}

RlvCmd(string sStr) {
    integer start;
    integer end;
    string sCommand = sStr;
    if (llSubStringIndex(sStr,"=") >= 0) {
        start = llSubStringIndex(sStr,"=")+ 1;
        if (llSubStringIndex(sStr,";") >= 0) {
            end = llSubStringIndex(sStr,";") -1;
        }
        else end = llStringLength(sStr);
    }
    sStr = llGetSubString(sStr,start,end);
    start = 0;
    end = llStringLength(sStr) -1;
    
    for(start; start <= end; ++start) { //run through this number list to make sure each character is numeric
        if(isInteger(llGetSubString(sStr, start, start)) != 1) { llOwnerSay(sCommand); return; } //something left in here isn't an integer, send the full command
    }
    llSetTimerEvent(20);
    llOwnerSay(sCommand);
    g_iListenerChannel=(integer)sStr;
    g_iListenerHandle = llListen(g_iListenerChannel, "", llGetOwner(), "");
    g_lListeners+= [g_iListenerHandle];
    
}

integer UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    sStr=llToLower(sStr);
    string sMainButton = llToLower(SUBMENU_BUTTON);
    if (!(iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)) {
        return FALSE;
    } else if ((g_iRlvOn == FALSE) && (llSubStringIndex(sStr,sMainButton) == 0)) { 
        Notify(kID,"RLV is off in "+WEARERNAME+"'s "+CTYPE+".  Please enable RLV before using this plugin",FALSE);
        return FALSE;
    } else if (sStr == sMainButton || sStr == "menu "+sMainButton) {
        //an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    }  else if (sStr == sMainButton+" reset" ) {
        llResetScript();
    }  else if (llSubStringIndex(sStr,sMainButton) == 0)  {
        sStr = llStringTrim(llDeleteSubString(sStr,0,llStringLength(sMainButton)),STRING_TRIM);
        if (llSubStringIndex(sStr,"@") == 0) { //rlv commands need to start with @
            Notify(kID,"Sending RLV command "+sStr+" to "+WEARERNAME+"'s "+CTYPE,FALSE);
            g_lRlvCommandHistory += [sStr];
            g_kClicker = kID;
            RlvCmd(sStr);
        } else {
            Notify(kID,"Invalid command",FALSE);
        }
    }

    if (remenu) {
        DoMenu(kID, iNum);
    }
    return TRUE;
}

string StringHistorySnippet() {
    string sPrompt;
    integer i;
    integer x = llGetListLength(g_lRlvCommandHistory) -1;
    sPrompt = "\n[http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI RLVcmd Help]";
    if (x >= 0) {
        sPrompt += "  History:\n";
        for (i=x-3;i<=x;++i) {
            if (i>=0) sPrompt += (string)(i+1) +")" + llList2String(g_lRlvCommandHistory,i)+"\n";
        }
    }
    return sPrompt;
}

default {

    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        WEARERNAME = llGetDisplayName(g_kWearer);
        if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME = llKey2Name(g_kWearer); //sanity check, fallback if necessary
    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer)  llResetScript();
    }
    
    listen(integer iChan, string sName, key kID, string sMsg) {
        if (iChan == g_iListenerChannel) { //We got some folders to process
            Notify(g_kClicker,sMsg,FALSE);
        }
    }

    timer() //close all timers/listeners we may have opened up
    {
        integer i;
        integer x = llGetListLength(g_lListeners) -1;
        for (i=0;i<=x;++i) {
            llListenRemove(llList2Integer(g_lListeners,i));
        }
        g_lListeners = [];
        llSetTimerEvent(0.0);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) { 
       // llOwnerSay(sStr+" | "+(string)iNum+ "|"+(string)kID);
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        } 
        else if (iNum == RLV_ON) {
            g_iRlvOn = TRUE;
        }
        else if (iNum == RLV_OFF) {
            g_iRlvOn = FALSE;
        }
        else if (iNum == RLVA_VERSION) { 
            g_iRlvaOn = TRUE;
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
        else if (iNum == COMMAND_SAFEWORD) { 
            // Safeword has been received, release any restricitions that should be released
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
                integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                // request to switch to parent menu
                if (sMessage == UPMENU) {
                    //give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu "+COLLAR_PARENT_MENU, kAv);
                } 

                else if (sMessage == "CMD") {
                    g_kRlvCommand = Dialog(kAv,StringHistorySnippet(), [], [], 0, iAuth);

                }
                else if (sMessage == "History") {
                    Notify(kAv,"RLVcmd History: "+llDumpList2String(g_lRlvCommandHistory,";"),FALSE);
                    DoMenu(kAv,iAuth);
                }
            }
       
       else if (kID == g_kRlvCommand) {
            list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
            string sMessage = llList2String(lMenuParams, 1); // button label
            integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
            integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
            if (sMessage == "") {
                DoMenu(kAv,iAuth);
            }
           else if (llSubStringIndex(sMessage,"@") == 0)  {
               sMessage = llStringTrim(sMessage,STRING_TRIM);
               g_lRlvCommandHistory += [sMessage];
               Notify(kAv,"Sending RLV command "+sMessage+" to "+WEARERNAME+"'s "+CTYPE,FALSE);
               g_kClicker = kAv;
               RlvCmd(sMessage);
               g_kRlvCommand = Dialog(kAv,StringHistorySnippet(), [], [], 0, iAuth);           
           }
           else {
               g_kRlvCommand = Dialog(kAv,StringHistorySnippet(), [], [], 0, iAuth);
               Notify(kAv,"Invalid RLV command: "+sMessage,FALSE);
           }
       }
    }
   }
}
