////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - cagehome                              //
//                                 version 0.300                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Version       : 0.3
// Date          : 2013/03/20
// Last Edited by: Tuco Solo
//
// Original version and idea by Kaly Shinn


/*

 -Purpose-

 The purpose of the plugin is to give the dom all the benefits of keeping a sub in
 a cage for long terms without causing the sub extreme boredom and frustration, as
 often occurs if the dom is away from SL for a couple of days.


 -Description-

 When the owner of the sub logs on, or the sub logs on and the owner is already on,
 the sub is teleported to an owner set location called the Cage Home, and kept there
 until:
   - The owner comes near
   - The owner TPs the sub
   - A timer expires
   - Any primary owner manually releases the sub


 -Quick Installation-

   1. Put the script in the unlocked OC collar.
   2. Re-attach collar or relog
   3. The sub must stand where the "Cage Home" should be
   4. The owner selects "Cage Here" from the menu or chat command
   5. The owner now arms the plugin. This owner becomes cage owner.


 -Settings-

 Below is a complete list of available commands, of which you should prefix with the
 sub's initials, of course. Chat commands are only available to primary owners.
  
 chhere
   Makes sub's current position the Cage Home Location.
   Valid when not caged.
   
 charm
   Arms the Cage Home plugin. The primary that issues this command will become
   Cage Owner, to distinguish them from other primary owners. The on/offline state
   of the Cage Owner will be monitored.
   Valid when a Home Location has been set and not already armed.
   
 chdisarm
   Disarms the Cage Home plugin. Any primary owner may disarm.
   Valid when armed, but not caged.
   
 chrelease
   Release the sub from the Cage Home. Any primary owner may release. If the
   primary owner that releases the sub is not the Cage Owner, the Cage Owner will
   also be notified about this release.
   
 chsettings
   Shows current settings. There is also a menu button for this action.
   
 chcommands
   Shows available chat commands. This list is unprefixed. There is also a menu
   button for this action.
   
 chwarntime <seconds>
   Specifies the duration, in seconds, between a warning is issued and the actual
   capturing (teleport). If this value is 0 or lower, no warning will be issued.
   
 chradius <meters>
   Specifies the radius of the Cage Home, in meters.
   
 chcagetime <minutes>
   Specifies the duration of the timer, after which the sub will be auto released,
   if not released manually earlier. If this value is 0 or less, no timer will be
   activated (use with care!).
   
 chnotifychannel <channel number>
   Specifies the channel number on which capturing (arrival) and releasing must
   be announced. If this value is 0 (public chat), no announcements will be made.
   
 chnotifyarrive <arrive string>
   Specifies the word or phrase that will be said upon capture (teleport
   arrival) of the sub.
   
 chnotifyrelease <release string>
   Specifies the word or phrase that will be said upon release of the sub.
   
 chwarnmessage <warning message>
   Specifies the word or phrase that will be said in public chat, that will
   announce the sub being summoned. The following tokens may be used:
   @  will be replaced with the sub's username
   #  will be replaced with the number of seconds

*/




/*

 script state-flow, with corresponding state names:
 --------------------------------------------------


                         script install                                             default
                           or reset
                              |
                              | 1. primary owner sets cage home location, or
                              | 2. retrieve saved settings
                              v
                       cage home pos set  <----------------------------------       disarmed
                              |                                              |
                              | owner arms plugin (and becomes cage owner)   |
                              v                                              |
 -------------------->   plugin armed ------------------->                   |      armed_idle
|                             |                           |                  |
|                             | cage owner goes offline   |                  |
|                             v                           |                  |
|                        plugin armed -------------------> ----------------->       armed_alert
|                             |                           |   (any primary)
|                             | cage owner comes online   |   owner disarms
|                             v                           |
|                     sub receives warning -------------->                          armed_warning
|                             |
|                             | wait time
|                             v
|                       teleport sub                                                armed_teleport
|                             |
|                             v
|                       sub forcely TPed,
|                    -- restricted radius                                           armed_caged
|    (any primary)  |         |
|    owner releases |         | 1. cage owner approaches, or
|                   |         | 2. cage owner summons (tp), or
|                   |         | 3. timer runs out
|                   |         v
|                    ----> released                                                 armed_released
|                             |
 ----------------------------- 

Notes:
  - Can only set location while not armed

*/

// State enumeration:

integer STATE_DEFAULT        = 0;
integer STATE_DISARMED       = 1;
integer STATE_ARMED_IDLE     = 2;
integer STATE_ARMED_ALERT    = 3;
integer STATE_ARMED_WARNING  = 4;
integer STATE_ARMED_TELEPORT = 5;
integer STATE_ARMED_CAGED    = 6;
integer STATE_ARMED_RELEASED = 7;

integer g_iCurrentState; // keep track of current state, set within every state_entry()


//OpenCollar Plugin Template
integer IN_DEBUG_MODE           = FALSE;       // set to TRUE to enable Debug messages, if any
string  SUBMENU_BUTTON          = "Cage Home"; // Name of the g_sSubMenu
string  COLLAR_PARENT_MENU      = "Apps";    // Name of the menu

string  PLUGIN_CHAT_COMMAND     = "ch";        // so the user can easily access it by type for instance *plugin
string  PLUGIN_TITLE            = "Cage Home"; // to be used in various strings
string  CANT_DO                 = "Can not do - "; // used in various responses (to specify a negative response to an issued command)
string  LM_SETTING_TOKEN        = "cagehome";

key     g_kWearer;                             // key of the current wearer to reset only on owner iChanges
string  g_sWearer;                             // name of the current wearer (username without "Resident", if any)


// Dialog BUTtons:

string  BUT_CAGE_HERE           = "Cage Here";
string  BUT_ARM                 = "Arm";
string  BUT_DISARM              = "Disarm";
string  BUT_RELEASE             = "Release";
string  BUT_SETTINGS            = "Shw Settings";
string  BUT_COMMANDS            = "Shw Cmds";
string  BUT_BLANK               = "  ";

list    g_lButtons              = [];  // extra buttons that we get inserted "from above"


// OpenCollar MESSAGE MAP (Cage Home plugin: unused message types commented out)

// messages for iNumenticating users
//integer COMMAND_NOAUTH          = 0;
integer COMMAND_OWNER           = 500;
//integer COMMAND_SECOWNER        = 501;
//integer COMMAND_GROUP           = 502;
integer COMMAND_WEARER          = 503;
//integer COMMAND_EVERYONE        = 504;
//integer COMMAND_OBJECT          = 506;
//integer COMMAND_RLV_RELAY       = 507;
integer COMMAND_SAFEWORD        = 510;
//integer COMMAND_BLACKLIST       = 520;
//integer COMMAND_WEARERLOCKEDOUT = 521;

integer POPUP_HELP              = 1001;

integer LM_SETTING_SAVE         = 2000; // scripts send messages on this channel to have settings saved
                                        // str must be in form of "token=value"
integer LM_SETTING_REQUEST      = 2001; // when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE     = 2002; // the httpdb script will send responses on this channel
//integer LM_SETTING_DELETE       = 2003; // delete token from DB

// messages for creating OC menu sStructure
integer MENUNAME_REQUEST        = 3000;
integer MENUNAME_RESPONSE       = 3001;
integer SUBMENU                 = 3002;
//integer MENUNAME_REMOVE         = 3003;

// messages to the dialog helper
integer DIALOG                  = -9000;
integer DIALOG_RESPONSE         = -9001;
//integer DIALOG_TIMEOUT          = -9002;

// messages for RLV sCommands
integer RLV_CMD                 = 6000;
integer RLV_REFRESH             = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR               = 6002; // RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION             = 6003; // RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer RLV_OFF                 = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON                  = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

// messages for poses and couple sAnims
//integer ANIM_START              = 7000;
//integer ANIM_STOP               = 7001;
//integer CPLANIM_PERMREQUEST     = 7002;
//integer CPLANIM_PERMRESPONSE    = 7003;
//integer CPLANIM_START           = 7004; // sStr should be valkID sAnim sName. kID should be kAv
//integer CPLANIM_STOP            = 7005; // sStr should be valkID sAnim sName. kID should be kAv

// menu option to go one step back in menusStructure
string  BUT_UPMENU              = "^"; // when your menu hears this, give the parent menu

list    lChatCommands;                 // available chat commands, initialized in default state (memory issue)

integer CAGEHOME_NOTIFY_NUM     = -11552; // internal link num to announce arrivals and releases on

integer DELAY_CHECK_OWNER_ONLINE= 15;  // check every .. seconds for on- or offline  (timer/dataserver)
integer DELAY_CHECK_OWNER_NEAR  = 3;   // check every .. seconds to see if cage owner is near (sensor)

integer TP_RETRY_DELAY          = 30;  // try tp every .. seconds
integer MAX_TP_TRIES            = 5;   // ...until exhausted tries
integer g_iTpTries;                    // keep track of the number of TP attempts

// plugin settings (dont change order as listed here, it's in 'protocol order'. see defaults below)
string  g_sCageRegion;          // landing point sim name
vector  g_vCagePos;             // landing point within region
string  g_sCageHomeRlv;         // the string representing the cage home point, to be fed to the rlv tp command
integer g_iCageRadius;          // how far the wearer may wander from the cage point, and how close the owner must be to auto release = g_fCageRadius+1
integer g_iWarningTime;         // how much warning in seconds the wearer gets before being tped
integer g_iCageWait;            // Time in minutes before the wearer is released, even if the owner is still online. Can be set to 0 for no auto release
integer g_iCageNotifyChannel;   // what channel to send captured and released messages on
string  g_sCageNotifyArrive;    // the message said on g_iCageNotifyChannel after the wearer has been TPed to the cage home
string  g_sCageNotifyRelease;   // the message said on g_iCageNotifyChannel after the wearer has been released from the cage home
string  g_sCageWarningMessage;  // the warning message, @ is replaced by the wearer full name, and # by g_iWarningTime

// default settings, will be loaded upon script start. leave landing point values blank!
string  DEFAULT_SETTINGS        = "|||5|30|45|-1|arrived|released|@ will be summoned away in # seconds";

// global boolean settings
integer g_bRlvActive            = FALSE; // we'll get updates from the rlv script(s)

// globals
vector  g_vLocalPos;                     // used when caged
key     g_kCageOwnerKey;
string  g_sCageOwnerName;
string  g_sCagePosSlashed;               // visual representation of vCagePos ("x/y/z" instead of <x,y,z>), to use in output
string  g_sArmedState           = "Disarmed";

// handles
key     g_kMenuID;                       // menu handle
key     g_kSimPosRequestHandle;          // UUID of the dataserver request
key     g_kOwnerRequestHandle;
integer g_iTargetHandle;





// UTILITY FUNCTIONS


// Returns sSource with sReplace replaced for all occasions of sSearch
//
string StrReplace(string sSource, string sSearch, string sReplace) {
    return llDumpList2String(llParseStringKeepNulls((sSource = "") + sSource, [sSearch], []), sReplace);
}


// Returns " Resident" stripped from sName, if any
//
string StripResident(string sName) {
    string sSearch = " Resident";
    integer iIndex = llSubStringIndex(sName, sSearch);
    if (-1 < iIndex) {
        return llDeleteSubString(sName, iIndex, -1);
    }
    return sName;
}


// Returns vector vVec in a string with form "x/y/z", where x, y and z are
// rounded down to the nearest integer.
//
string Vector2UrlCoordinates(vector vVec) {
    return llDumpList2String([(integer)vVec.x, (integer)vVec.y, (integer)vVec.z], "/");
}


// END UTILITY FUNCTIONS




// OC HELPER FUNCTIONS


// Sends a list of RLV-commands to the collar script(s), one by one.
//
SendRlvCommands(list lRlvCommands) {
    integer i;
    for (i = 0; i < llGetListLength(lRlvCommands); ++i) {
        llMessageLinked(LINK_THIS, RLV_CMD, llList2String(lRlvCommands, i), NULL_KEY);
    }
}


RegisterSubMenu(integer iTarget) {
    llMessageLinked(iTarget, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, NULL_KEY);
}


// END OC HELPER FUNCTIONS



// OC FUNCTIONS

Debug(string sMsg) {
    if (IN_DEBUG_MODE) {
        llOwnerSay(llGetScriptName() + " [DEBUG]: " + sMsg);
    }
}


Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    }
    else {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
}



//===============================================================================
//= parameters : string keyID key of person requesting the menu
//=
//= return : none
//=
//= description : build menu and display to user
//=
//===============================================================================
//
//
// The wearer of the collar will get a different prompt and different buttons.
//
DoMenu(key kID, integer iAuth) {
    // Debug("DoMenu|" + (string)kID + "|" + (string)iAuth);
    integer bLocationSet = ("" != g_sCageRegion);
    integer bIsArmed = (STATE_ARMED_IDLE <= g_iCurrentState);
    string sPrompt = "\n";
    list lMyButtons = [];
    
    if (COMMAND_OWNER == iAuth) {
        sPrompt += 
            "Have your sub auto teleport and caged the moment you log on again. The sub will be released if:" +
            "\n\tYou approach the cage" +
            "\n\tYou summon the sub" +
            "\n\tThe timer runs out" +
            "\n" +
            "\nUse chat commands to tweak settings.";
  
        if (g_iCurrentState <= STATE_DISARMED) {
            lMyButtons += [BUT_CAGE_HERE];
        }
        else {
            lMyButtons += [BUT_BLANK];
        }
        if (!bLocationSet) {
            lMyButtons += [BUT_BLANK];
        }
        else if (STATE_DISARMED == g_iCurrentState) {
            lMyButtons += [BUT_ARM];
        }
        else if (STATE_ARMED_CAGED <= g_iCurrentState) {
            lMyButtons += [BUT_RELEASE];
        }
        else {
            lMyButtons += [BUT_DISARM];
        }
        
        lMyButtons += [BUT_BLANK, BUT_SETTINGS, BUT_COMMANDS];
    }
    else {
        string sSub;
        string sOwner;
        if (COMMAND_WEARER == iAuth) {
            sSub = "you";
            sOwner = "your";
        }
        else {
            sSub = "the sub";
            sOwner = "the";
        }
        sPrompt += 
            "This feature will teleport " + sSub + " to a predefined location, set by " + 
            sOwner + " owner, once " + sOwner + " owner logs on again." +
            "\n\nThis AddOn is controlled by " + sOwner + " owner.";
    }
    sPrompt +=
        "\n" +
        "\nFeature currently: " + g_sArmedState +
        "\nCage location: ";
    if (bLocationSet) {
        sPrompt += g_sCageRegion + "/" + g_sCagePosSlashed;
    }
    else {
        sPrompt += "not set yet";
    }
    sPrompt += 
        "\n" +
        "\n";

    g_kMenuID = llGenerateKey();

    llMessageLinked(LINK_THIS, DIALOG, 
        (string)kID + 
        "|" + sPrompt + 
        "|" + (string)0 +  // iPage
        "|" + llDumpList2String(lMyButtons + g_lButtons, "`") + 
        "|" + llDumpList2String([BUT_UPMENU], "`") +
        "|" + (string)iAuth, g_kMenuID);
}


// END OC FUNCTIONS




// PLUGIN FUNCTIONS




// Stores all settings (using the settings or database script, or whatever)
//
SaveSettings() {
    string sSaveString = LM_SETTING_TOKEN + "=" +
        llDumpList2String([
            g_sCageRegion,
            g_vCagePos,        
            g_sCageHomeRlv,
            g_iCageRadius,
            g_iWarningTime,
            g_iCageWait,
            g_iCageNotifyChannel,
            g_sCageNotifyArrive,
            g_sCageNotifyRelease,
            g_sCageWarningMessage
        ], "|");
    
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, sSaveString, NULL_KEY);
}


// Parses sValue, that we received from the settings or database script earlier,
// into our global settings variables.
//
ParseSettings(string sValue) {
    list lValues = llParseStringKeepNulls(sValue, ["|"], []);
    if (10 <= llGetListLength(lValues)) {
        g_sCageRegion         = llList2String(lValues, 0);
        g_vCagePos            = (vector)llList2String(lValues, 1);
        g_sCageHomeRlv        = llList2String(lValues, 2);
        g_iCageRadius         = (integer)llList2String(lValues, 3);
        g_iWarningTime        = (integer)llList2String(lValues, 4);
        g_iCageWait           = (integer)llList2String(lValues, 5);
        g_iCageNotifyChannel  = (integer)llList2String(lValues, 6);
        g_sCageNotifyArrive   = llList2String(lValues, 7);
        g_sCageNotifyRelease  = llList2String(lValues, 8);
        g_sCageWarningMessage = llList2String(lValues, 9);
        
        g_sCagePosSlashed = Vector2UrlCoordinates(g_vCagePos);
    }
    else {
        Debug("parse error");
    }
}


// Reports current settings to kAv.
//
ReportSettings(key kAv) {
    string sMsg = PLUGIN_TITLE + " Settings:" +
        "\n" + PLUGIN_TITLE + " Location: " + g_sCageRegion + "/" + g_sCagePosSlashed +
        "\nCurrent state: " + g_sArmedState;
    if ("" != g_sCageOwnerName) {
        sMsg += "\nCage Owner: " + g_sCageOwnerName;
    }
    sMsg +=
        "\nCage Radius: " + (string)g_iCageRadius + " m" +
        "\nWarning Time: " + (string)g_iWarningTime + " sec" +
        "\nCage Wait: ";
    if (0 < g_iCageWait) {
        sMsg += (string)g_iCageWait + " min";
    }
    else {
        sMsg += "no timer release";
    }
    sMsg +=
        "\nCage Notify Channel: " + (string)g_iCageNotifyChannel +
        "\nArrived Message: " + g_sCageNotifyArrive +
        "\nReleased Message: " + g_sCageNotifyRelease +
        "\nWarning Message: " + g_sCageWarningMessage;
    // we're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    // and we know kAv is near
    llRegionSayTo(kAv, PUBLIC_CHANNEL, sMsg);
}


ShowCommands(key kID) {
    // we're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    llRegionSayTo(kID, PUBLIC_CHANNEL, llDumpList2String([PLUGIN_TITLE + " Commands:"] + lChatCommands, "\n"));
}


// Records current location of the wearer to be the Cage Home Coordinates, first gets the region
// name, then stores the global coordinates using the dataserver event
RecordCageHome() {
    g_vCagePos = llGetPos();
    g_sCagePosSlashed = Vector2UrlCoordinates(g_vCagePos);
    g_sCageRegion = llGetRegionName();
    g_kSimPosRequestHandle = llRequestSimulatorData(g_sCageRegion, DATA_SIM_POS); // script sleep 1.0 seconds
}


SetRlvRestrictions() {
    SendRlvCommands([
        "tplm=n",
        "tploc=n",
        "tplure=n",
        "tplure:" + (string)g_kCageOwnerKey + "=add",
        "sittp=n",
        "rez=n"
        // ,"standtp=n"
    ]);
}


ClearRlvRestrictions() {
    SendRlvCommands([
        "tplm=y", 
        "tploc=y", 
        "tplure=y", 
        "sittp=y", 
        "rez=y"
        // ,"standtp=y"
    ]);
}


// Sets Cage Owner to kID. We also set their name. We assume kID is in the same region as
// the sub for this to work (llKey2Name()).
//
SetCageOwner(key kID) {
    g_kCageOwnerKey = kID;
    g_sCageOwnerName = StripResident(llKey2Name(g_kCageOwnerKey));
}


// Sends a message to kActor and the wearer about the captive change (armed, released, disarmed).
// A copy is sent to the wearer. If kActor is not the Cage Owner, the Cage Owner will receive a copy
// as well.
//
NotifyCaptiveChange(key kActor, integer iNextState) {
    string sActor = StripResident(llKey2Name(kActor)); // assume kActor is near, llKey2Name() works
    string sMsg;
    if (iNextState == STATE_ARMED_IDLE) {
        sMsg = sActor + " armed " + PLUGIN_TITLE + " for " + g_sWearer;
    }
    else if (iNextState == STATE_DISARMED) {
        sMsg = sActor + " disarmed " + g_sWearer + "'s " + PLUGIN_TITLE;
    }
    else if (iNextState == STATE_ARMED_RELEASED) {
        sMsg = sActor + " released " + g_sWearer + " from " + PLUGIN_TITLE;
    }
    Notify(kActor, sMsg, TRUE);
    if (kActor != g_kCageOwnerKey) {
        // also send a copy to cage owner, in case some other primary owner released or disarmed:
        Notify(g_kCageOwnerKey, sMsg, FALSE);
    }
}


NotifyLocationSet(key kActor) {
    Notify(kActor, PLUGIN_TITLE + " Location set to " + g_sCageRegion + "/" + g_sCagePosSlashed, TRUE);
}


// END PLUGIN FUNCTIONS




// EVENT HELPERS (functions that represent events, to be used within multiple states)


Event_on_rez(integer iParam) {
    g_bRlvActive = FALSE; // let the collar send new RLV-information upon rez
}


// Returns TRUE if this function processed the change(s) of iChange succesfully.
// (At this point this won't be the case, but this is our 'contract' description.)
//
integer Event_changed(integer iChange) {
    if (iChange & CHANGED_OWNER) {
        llOwnerSay(llGetScriptName() + ": new owner detected. Resetting...");
        llResetScript();
    }
    return FALSE;
}


// Processes the link_message event
// - state aware (using g_iCurrentState)
// - returns the new desired state (on which the caling event should react, for we
//   are not allowed to switch states within a function)
//
integer Event_link_message(integer iSender, integer iNum, string sStr, key kID) {
    integer iLinkResult = g_iCurrentState; // default result
    
    if (iNum == RLV_REFRESH) {
        if (STATE_ARMED_CAGED == g_iCurrentState) {
            SetRlvRestrictions();
        }
    }
    else if (iNum == RLV_VERSION) {
        g_bRlvActive = TRUE;
    }
    else if (iNum == RLV_CLEAR) {
        if (STATE_ARMED_CAGED == iLinkResult) {
            iLinkResult = STATE_ARMED_RELEASED; // released by a higher power, complying silently
        }
    }
    else if (iNum == RLV_ON || iNum == RLV_OFF) { // valid as of API v3.8
        g_bRlvActive = iNum == RLV_ON;
    }
    else if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
        // our parent menu requested to receive entry buttons (from all plugins), so send back ours
        RegisterSubMenu(iSender);
        g_lButtons = [] ; // flush submenu buttons
        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, SUBMENU_BUTTON, NULL_KEY);
    }
    else if (iNum == MENUNAME_RESPONSE) { // a button is sent to be added to a menu
        list lParts = llParseString2List(sStr, ["|"], []);
        if (llList2String(lParts, 0) == SUBMENU_BUTTON) { // someone wants to stick something in our menu
            string button = llList2String(lParts, 1);
            if (llListFindList(g_lButtons, [button]) < 0) { // if the button isnt in our menu yet, add it
                g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
            }
        }
    }
    else if (iNum == LM_SETTING_RESPONSE) {
        list lParams = llParseString2List(sStr, ["="], []);
        string sToken = llList2String(lParams, 0);
        if (LM_SETTING_TOKEN == sToken) {
            // receiving settings
            ParseSettings(llList2String(lParams, 1));
        }
    }
    else if (COMMAND_OWNER <= iNum && iNum <= COMMAND_WEARER) {
        if (sStr == "reset") { // it is a request for a reset
            if (iNum == COMMAND_WEARER || iNum == COMMAND_OWNER) {
                // only wearer and owner(s) may reset
                llResetScript();
            }
        }
        else if (sStr == "menu " + SUBMENU_BUTTON || sStr == SUBMENU_BUTTON) { // API 3.8 and API 3.7
            DoMenu(kID, iNum);
        }
        else if (sStr == PLUGIN_CHAT_COMMAND) {
            // an iNumorized user requested the plugin menu by typing the chat command for this plugin
            DoMenu(kID, iNum);
        }
        else if (sStr == "settings") { // collar's command to request settings of all modules
            string sMsg = PLUGIN_TITLE + ": " + g_sArmedState;
            if ("" != g_sCageRegion) {
                sMsg += ", TP Location: " + g_sCageRegion + "/" + g_sCagePosSlashed;
            }
            llSleep(0.5);
            Notify(kID, sMsg, FALSE);
        }
        else if (COMMAND_OWNER == iNum) {
            // PLUGIN CHAT lChatCommands
            string sCommand = sStr;
            string sValue = "";
            integer iIndex = llSubStringIndex(sStr, " ");
            if (-1 < iIndex) {
                sCommand = llDeleteSubString(sStr, iIndex, -1);
                sValue = llDeleteSubString(sStr, 0, iIndex);
            }
            
            iIndex = llListFindList(lChatCommands, [sCommand]); // re-use variable iIndex
            if (-1 < iIndex) {
                if (iIndex < 1) { // chhere
                    if (iLinkResult <= STATE_DISARMED) {
                        RecordCageHome();
                        NotifyLocationSet(kID);
                        SaveSettings();
                    }
                    else {
                        Notify(kID, CANT_DO + "still armed, disarm first", FALSE);
                    }
                }
                else if (iIndex < 2) { // charm
                    if (STATE_DISARMED == iLinkResult) {
                        SetCageOwner(kID);
                        iLinkResult = STATE_ARMED_IDLE;
                        NotifyCaptiveChange(kID, iLinkResult);
                    }
                    else if (STATE_ARMED_IDLE <= iLinkResult) {
                        Notify(kID, CANT_DO + "already armed", FALSE);
                    }
                    else if (iLinkResult < STATE_DISARMED) {
                        Notify(kID, CANT_DO + PLUGIN_TITLE + " Location not set", FALSE);
                    }
                }
                else if (iIndex < 3) { // chdisarm
                    if (STATE_ARMED_IDLE <= iLinkResult && iLinkResult <= STATE_ARMED_WARNING) {
                        iLinkResult = STATE_DISARMED;
                        NotifyCaptiveChange(kID, iLinkResult);
                    }
                    else if (iLinkResult <= STATE_DISARMED) {
                        Notify(kID, CANT_DO + "already disarmed", FALSE);
                    }
                    else if (STATE_ARMED_TELEPORT <= iLinkResult) {
                        Notify(kID, CANT_DO + "release sub first", FALSE);
                    }
                }
                else if (iIndex < 4) { // chrelease
                    if (STATE_ARMED_TELEPORT <= iLinkResult && iLinkResult <= STATE_ARMED_CAGED) {
                        iLinkResult = STATE_ARMED_RELEASED;
                        NotifyCaptiveChange(kID, iLinkResult);
                    }
                    else if (iLinkResult <= STATE_ARMED_WARNING) {
                        Notify(kID, CANT_DO + "sub not caged", FALSE);
                    }
                }
                else if (iIndex < 5) { // chsettings
                    ReportSettings(kID);
                }
                else if (iIndex < 6) { // chcommands
                    ShowCommands(kID);
                }
                // next commands need an argument. check first for its existance:
                else if ("" == sValue) {
                    Notify(kID, "Command " + sCommand + " requires an argument", FALSE);
                }
                else {
                    // notify once, created with strings sDescr and sAppend:
                    string sDescr = "";
                    string sAppend = "";
            
                    // within this else-block: things with an argument (and then save)
                    if (iIndex < 7) { // chwarntime
                        g_iWarningTime = (integer)sValue;
                        sDescr = "Warning Time";
                        sAppend = sValue + " sec";
                    }
                    else if (iIndex < 8) { // chradius
                        g_iCageRadius = (integer)sValue;
                        sDescr = "Cage Radius";
                        sAppend = sValue + " m";
                    }
                    else if (iIndex < 9) { // chwait
                        g_iCageWait = (integer)sValue;
                        sDescr = "Cage Wait";
                        sAppend = sValue + " min";
                    }
                    else if (iIndex < 10) { // chnotifychannel
                        g_iCageNotifyChannel = (integer)sValue;
                        sDescr = "Cage Notify Channel";
                        sAppend = sValue;
                    }
                    else {
                        // within this else-block: settings that may be enclosed within single quotes
                
                        string sArg = llList2String(llParseString2List(sValue, ["'"], []), 1);
                        if (iIndex < 11) { // cagenotifyarrive
                            g_sCageNotifyArrive = sArg;
                            sDescr = "Cage Notify Arrive";
                        }
                        else if (iIndex < 12) { // cagenotifyrelease
                            g_sCageNotifyRelease = sArg;
                            sDescr = "Cage Notify Release";
                        }
                        else if (iIndex < 13) { // cagewarningmessage
                            g_sCageWarningMessage = sArg;
                            sDescr = "Cage Warning Message";
                        }
                        sAppend = "'" + sArg + "'";
                    }
        
                    if ("" != sDescr) {
                        Notify(kID, sDescr + " set to " + sAppend, TRUE);
                    }
                    SaveSettings();
                }
            }
            
        } // else: iNum equals COMMAND_WEARER  // we accept no chat commands from the wearer, so ignore
    }
    else if (COMMAND_SAFEWORD == iNum) {
        if (STATE_ARMED_CAGED == iLinkResult) {
            iLinkResult = STATE_ARMED_RELEASED;
            NotifyCaptiveChange(g_kCageOwnerKey, STATE_ARMED_RELEASED);
        }
    }
    
    // answer from menu system
    // careful, don't use the variable kID to identify the user.
    // you have to parse the answer from the dialog system and use the parsed variable kAv
    else if (iNum == DIALOG_RESPONSE) {
        if (kID == g_kMenuID) {
            // got a menu response meant for us, extract the sValues
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMessage = llList2String(lMenuParams, 1);
            integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);
            // request to change to parent menu
            if (sMessage == BUT_UPMENU) {
                // give kAv the parent menu
                llMessageLinked(LINK_THIS, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
            }
            else {
                integer iIndex = llListFindList([BUT_CAGE_HERE, BUT_ARM, BUT_DISARM, BUT_RELEASE, BUT_SETTINGS, BUT_COMMANDS, BUT_BLANK], [sMessage]);
                if (-1 < iIndex) {
                    if (iIndex < 1) { // "Cage Here"
                        RecordCageHome();
                        NotifyLocationSet(kAv);
                        DoMenu(kAv, iAuth);
                    }
                    else if (iIndex < 2) { // "Arm"
                        SetCageOwner(kAv);
                        iLinkResult = STATE_ARMED_IDLE;
                    }
                    else if (iIndex < 3) { // "Disarm"
                        iLinkResult = STATE_DISARMED;
                    }
                    else if (iIndex < 4) { // "Release"
                        iLinkResult = STATE_ARMED_RELEASED;
                    }
                    else if (iIndex < 5) { // "Settings"
                        ReportSettings(kAv);
                        DoMenu(kAv, iAuth);
                    }
                    else if (iIndex < 6) { // "Commands"
                        ShowCommands(kAv);
                        DoMenu(kAv, iAuth);
                    }
                    if (0 < iIndex && iIndex < 4) { // notify on "Arm", "Disarm" or "Release
                        NotifyCaptiveChange(kAv, iLinkResult);
                    }
                    // else: blank button (do nothing)
                }
                else if (~llListFindList(g_lButtons, [sMessage])) {
                    // we got a sCommand which another sCommand pluged into our menu
                    // llMessageLinked(LINK_THIS, SUBMENU, sMessage, kAv);
                    llMessageLinked(LINK_THIS, iAuth, "menu " + sMessage, kAv);
                }
            }
        }
    }

    // ignoring DIALOG_TIMEOUT msg
        
    return iLinkResult;
}


// END EVENT HELPERS



DebugCurrentStateFreeMemory() {
    if (IN_DEBUG_MODE) {
        Debug((string)g_iCurrentState + "|" + (string)llGetFreeMemory());
    }
}



// default state:
// initialize things,
// (auto) retrieve settings externally (including cage home location), or
// (primary) owner sets cage home location
//
default {
    
    state_entry() {
        g_iCurrentState = STATE_DEFAULT;
        
        lChatCommands = [
            "chhere", "charm", "chdisarm", "chrelease", "chsettings", "chcommands", // no-arg commands
            "chwarntime", "chradius", "chcagetime", "chnotifychannel",              // integer-arg commands
            "chnotifyarrive", "chnotifyrelease", "chwarnmessage"                    // string-arg commands
        ];
        
        g_kWearer = llGetOwner();
        g_sWearer = StripResident(llKey2Name(g_kWearer));
        
        ParseSettings(DEFAULT_SETTINGS); // default settings do not include the home location
        
        // sleep a second to allow other scripts to be initialized
        llSleep(1);
        
        // send request to main menu and ask other menus if they want to register with us
        //llMessageLinked(LINK_THIS, MENUNAME_REQUEST, SUBMENU_BUTTON, NULL_KEY);
        //RegisterSubMenu(LINK_THIS);

        llMessageLinked(LINK_THIS, LM_SETTING_REQUEST, LM_SETTING_TOKEN, NULL_KEY);
        
        DebugCurrentStateFreeMemory();
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        Event_link_message(iSender, iNum, sStr, kID);
        if ("" != g_sCageHomeRlv) {
            state disarmed;
        }
    }
    
    dataserver(key kQueryid, string data) {
        if (kQueryid == g_kSimPosRequestHandle) {
            g_sCageHomeRlv = Vector2UrlCoordinates((vector)data + g_vCagePos);
            SaveSettings();
            state disarmed;
        }
    }

    changed(integer iChange) {
        Event_changed(iChange);
    }
    
}


// state disarmed:
// how we got here: cage home location is set, or plugin was disarmed
// purpose: wait for (primary) owner to arm the plugin. this primary owner becomes "cage owner"
//
state disarmed {
    
    state_entry() {
        g_iCurrentState = STATE_DISARMED;
        g_sArmedState = "Disarmed";
        DebugCurrentStateFreeMemory();
    }
    
    on_rez(integer iParam) {
        Event_on_rez(iParam);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (STATE_ARMED_IDLE == Event_link_message(iSender, iNum, sStr, kID)) {
            state armed_idle;
        }
    }

    dataserver(key kQueryid, string data) {
        if (kQueryid == g_kSimPosRequestHandle) {
            g_sCageHomeRlv = Vector2UrlCoordinates((vector)data + g_vCagePos);
            SaveSettings();
        }
    }

    changed(integer iChange) {
        Event_changed(iChange);
    }
    
}



// state armed_idle:
// how we got here: (cage) owner armed the plugin
// purpose: wait for cage owner to go offline
//
state armed_idle {
    
    state_entry() {
        g_iCurrentState = STATE_ARMED_IDLE;
        g_sArmedState = "Armed";
        llSetTimerEvent(DELAY_CHECK_OWNER_ONLINE);
        DebugCurrentStateFreeMemory();
    }
    
    on_rez(integer iParam) {
        Event_on_rez(iParam);
        // if user comes online while owner already is, cage the sub. by switching
        // to armed_alert state we make this behaviour true.
        state armed_alert;
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (Event_link_message(iSender, iNum, sStr, kID) == STATE_DISARMED) {
            state disarmed;
        }
    }

    timer() {
        g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
    }
    
    dataserver(key kQueryid, string data) {
        if (kQueryid == g_kOwnerRequestHandle) {
            if (FALSE == (integer)data) {
                // cage owner went offline
                state armed_alert;
            }
        }
    }
    
    changed(integer iChange) {
        Event_changed(iChange);
    }
    
    state_exit() {
        llSetTimerEvent(0);
    }

}


// state armed_alert:
// how we got here: cage owner went offline
// purpose: wait for cage owner to come online again
// 
state armed_alert {
    
    state_entry() {
        g_iCurrentState = STATE_ARMED_WARNING;
        llSetTimerEvent(DELAY_CHECK_OWNER_ONLINE);
        DebugCurrentStateFreeMemory();
    }
    
    on_rez(integer iParam) {
        Event_on_rez(iParam);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (Event_link_message(iSender, iNum, sStr, kID) == STATE_DISARMED) {
            state disarmed;
        }
    }
    
    timer() {
        g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
    }
    
    dataserver(key kQueryid, string data) {
        if (kQueryid == g_kOwnerRequestHandle) {
            if (TRUE == (integer)data) {
                // cage owner came back online
                state armed_issue_warning;
            }
        }
    }
    
    changed(integer iChange) {
        Event_changed(iChange);
    }
    
    state_exit() {
        llSetTimerEvent(0);
    }
}



// state armed_issue_warning:
// how we got here: cage owner just came online
// purpose: warn sub about being teleported soon (and wait for designated period)
//
state armed_issue_warning {
    
    state_entry() {
        g_iCurrentState = STATE_ARMED_WARNING;
        DebugCurrentStateFreeMemory();
        if (g_iWarningTime < 1) {
            // no warning (time), teleport now
            state armed_teleport;
        }
        else {
            llSetTimerEvent(g_iWarningTime);
        }
        
        string sMsg = StrReplace(g_sCageWarningMessage, "@", g_sWearer);
        sMsg = StrReplace(sMsg, "#", (string)g_iWarningTime);
        
        string sObjectName = llGetObjectName();
        llSetObjectName(PLUGIN_TITLE);
        llSay(0, sMsg);
        llSetObjectName(sObjectName);
    }
    
    on_rez(integer iParam) {
        Event_on_rez(iParam);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (Event_link_message(iSender, iNum, sStr, kID) == STATE_DISARMED) {
            state disarmed;
        }
    }

    timer() {
        state armed_teleport;
    }
    
    changed(integer iChange) {
        Event_changed(iChange);
    }
    
    state_exit() {
        llSetTimerEvent(0);
    }
}


// state armed_teleport:
// how we got here: timer of issuing warning ran out
// purpose: teleport sub to cage home location
//
state armed_teleport {
    
    state_entry() {
        g_iCurrentState = STATE_ARMED_TELEPORT;
        DebugCurrentStateFreeMemory();

        if (!g_bRlvActive || 0 == llGetAttached()) {
            string sMsg = PLUGIN_TITLE + " can not teleport " + g_sWearer + " for ";
            if (!g_bRlvActive) {
                sMsg += "RLV was not detected.";
            }
            else {
                sMsg += "collar seems not attached.";
            }
            Notify(g_kCageOwnerKey, sMsg + " AddOn now disarming itself.", TRUE);
            state disarmed;
        }

        if (llGetRegionName() == g_sCageRegion && llVecDist(g_vCagePos, llGetPos()) < 10) {
            // already at or near cage position, skip tp
            state armed_caged;
        }
        else {        
            g_iTpTries = 0;
            llSetTimerEvent(0.2); // let the timer event do the TP thing
        }
    }
    
    on_rez(integer iParam) {
        Event_on_rez(iParam);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        integer iLinkResult = Event_link_message(iSender, iNum, sStr, kID);
        if (iLinkResult == STATE_DISARMED) {
            state disarmed;
        }
        else if (iLinkResult == STATE_ARMED_RELEASED) {
            state armed_released;
        }
    }

    timer() {
        g_iTpTries++;
        if (MAX_TP_TRIES < g_iTpTries) {
            Notify(g_kWearer, "Number of TP tries exhausted. Caging you here.", FALSE);
            state armed_caged;
        }
        llSetTimerEvent(TP_RETRY_DELAY); // try tp every ... seconds
        
        SendRlvCommands(["tploc=y", "unsit=y"]);
        llOwnerSay("@tpto:" + g_sCageHomeRlv + "=force");
    }
    
    changed(integer iChange) {
        if (!Event_changed(iChange)) {
            if (iChange & CHANGED_TELEPORT) {
                state armed_caged;
            }
        }
    }
    
    state_exit() {
        llSetTimerEvent(0);
    }
}


// state armed_caged
// how we got here: sub just teleported to cage home location
// purpose: wait for sub to be released
//
state armed_caged {
    
    state_entry() {
        g_iCurrentState = STATE_ARMED_CAGED;
        DebugCurrentStateFreeMemory();
        SetRlvRestrictions();
        Notify(g_kCageOwnerKey, "Your sub " + g_sWearer + " has just been teleported by the " + PLUGIN_TITLE + 
            " feature and is now waiting for you at http://maps.secondlife.com/secondlife/" +
            llEscapeURL(llGetRegionName()) + "/" + Vector2UrlCoordinates(llGetPos()), FALSE);
            
        llSensorRepeat("", g_kCageOwnerKey, AGENT_BY_LEGACY_NAME, g_iCageRadius + 1, PI, DELAY_CHECK_OWNER_NEAR);
        
        if (g_iCageNotifyChannel != PUBLIC_CHANNEL) {        
            llSay(g_iCageNotifyChannel, g_sCageNotifyArrive);
        }
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY_NUM, g_sCageNotifyArrive, NULL_KEY);

        g_vLocalPos = llGetPos();
        g_iTargetHandle = llTarget(g_vLocalPos, (float)g_iCageRadius);
        
        string sMsg = PLUGIN_TITLE + " now active ";
        if (0 < g_iCageWait) {
            llSetTimerEvent(g_iCageWait * 60); // g_iCageWait is in minutes now
            sMsg += "on a " + (string)g_iCageWait + " minutes timer";
        }
        else {
            sMsg += "with no time limit";
        }
        Notify(g_kWearer, sMsg, FALSE);
    }

    on_rez(integer iParam) {
        Event_on_rez(iParam);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        integer iLinkMsgResult = Event_link_message(iSender, iNum, sStr, kID);
        if (STATE_ARMED_RELEASED == iLinkMsgResult) {
            state armed_released;
        }
    }

    sensor(integer iNum) {     
        Notify(g_kCageOwnerKey, g_sWearer + " released from " + PLUGIN_TITLE, TRUE);
        state armed_released;
    }
    
    not_at_target() {
        llMoveToTarget(g_vLocalPos, 0.5);
    }
    
    at_target(integer iNum, vector vTargetPos, vector vOurPos) {
        llStopMoveToTarget();    
    }
    
    timer() {
        Notify(g_kCageOwnerKey, "Time's up! " + g_sWearer + " released from " + PLUGIN_TITLE, TRUE);
        state armed_released;
    }
    
    changed(integer iChange) {
        Event_changed(iChange);
        if (iChange & CHANGED_TELEPORT) {
            // TP has been blocked, expect for summons by cage owner
            NotifyCaptiveChange(g_kCageOwnerKey, STATE_ARMED_RELEASED);
            state armed_released;
        }
    }
    
    state_exit() {
        llSensorRemove();
        llTargetRemove(g_iTargetHandle);
        llStopMoveToTarget();
        llSetTimerEvent(0);
    }
}



// state armed_released (transition state):
// how we got here: the sub was (auto) released
// purpose: remove restrictions and change to armed_idle
//
state armed_released {
    
    state_entry() {
        g_iCurrentState = STATE_ARMED_RELEASED;
        DebugCurrentStateFreeMemory();
        ClearRlvRestrictions();

        if (g_iCageNotifyChannel != PUBLIC_CHANNEL) {        
            llSay(g_iCageNotifyChannel, g_sCageNotifyRelease);
        }
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY_NUM, g_sCageNotifyRelease, NULL_KEY);
        
        state armed_idle;
    }
    
    on_rez(integer iParam) {
        Event_on_rez(iParam);
    }
    
    changed(integer iChange) {
        Event_changed(iChange);
    }
    
}
