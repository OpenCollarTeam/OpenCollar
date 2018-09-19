// This file is part of OpenCollar.
// Copyright (c) 2008 - 2016 Satomi Ahn, Nandana Singh, Joy Stipe,     
// Wendy Starfall, Sumi Perl, littlemousy, Romka Swallowtail et al.    
// Licensed under the GPLv2.  See LICENSE for full details. 


// Based on original version and idea by Kaly Shinn & Tuco Solo

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

 ch here
   Makes sub's current position the Cage Home Location.
   Valid when not caged.

 ch arm
   Arms the Cage Home plugin. The primary that issues this command will become
   Cage Owner, to distinguish them from other primary owners. The on/offline state
   of the Cage Owner will be monitored.
   Valid when a Home Location has been set and not already armed.

 ch disarm
   Disarms the Cage Home plugin. Any primary owner may disarm.
   Valid when armed, but not caged.

 ch release
   Release the sub from the Cage Home. Any primary owner may release. If the
   primary owner that releases the sub is not the Cage Owner, the Cage Owner will
   also be notified about this release.

 ch settings
   Shows current settings. There is also a menu button for this action.

 ch commands
   Shows available chat commands. This list is unprefixed. There is also a menu
   button for this action.

 ch warntime <seconds>
   Specifies the duration, in seconds, between a warning is issued and the actual
   capturing (teleport). If this value is 0 or lower, no warning will be issued.

 ch radius <meters>
   Specifies the radius of the Cage Home, in meters.

 ch cagetime <minutes>
   Specifies the duration of the timer, after which the sub will be auto released,
   if not released manually earlier. If this value is 0 or less, no timer will be
   activated (use with care!).

 ch notifychannel <channel number>
   Specifies the channel number on which capturing (arrival) and releasing must
   be announced. If this value is 0 (public chat), no announcements will be made.

 ch notifyarrive <arrive string>
   Specifies the word or phrase that will be said upon capture (teleport
   arrival) of the sub.

 ch notifyrelease <release string>
   Specifies the word or phrase that will be said upon release of the sub.

 ch warnmessage <warning message>
   Specifies the word or phrase that will be said in public chat, that will
   announce the sub being summoned. The following tokens may be used:
   @  will be replaced with the sub's username
   #  will be replaced with the number of seconds




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

string g_sParentMenu = "Apps";
string g_sSubMenu = "Cage Home";

// MESSAGE MAP
integer CMD_OWNER = 500;
//integer CMD_TRUST = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_OBJECT = 506;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;

integer NOTIFY = 1002;

integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR = 6002;
integer RLV_VERSION = 6003;
integer RLV_OFF = 6100;
integer RLV_ON = 6101;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TEXTBOX = "Text Input";

// Default settings, will be loaded upon script start. leave landing point values blank!
string g_sDefaultSettings = "45|5|30|-1|arrived|released|@ will be summoned away in # seconds";

// State enumeration:
integer STATE_DEFAULT = 0;
integer STATE_DISARMED = 1;
integer STATE_ARMED = 2;
integer STATE_WARNING = 3;
integer STATE_TELEPORT = 4;
integer STATE_CAGED = 5;
integer STATE_RELEASED = 6;

// Dialog BUTtons:
string BTN_CAGEHERE = "Cage Here";
string BTN_ARM = "Arm";
string BTN_DISARM = "Disarm";
string BTN_RELEASE = "Release";
string BTN_SETTINGS = "Settings";
string BTN_COMMANDS = "Commands";
string BTN_CLEAR = "Clear";
string BTN_OPTIONS = "Options";

string BTN_TIME = "Cage Time";
string BTN_RADIUS = "Cage Radius";
string BTN_WARNTIME = "Warning Time";
string BTN_CHANNEL = "Channel";
string BTN_ARRIVED = "Arrived Msg";
string BTN_RELEASED = "Released Msg";
string BTN_WARNING = "Warning Msg";

string BTN_BLANK = " ";
string BTN_DEFAULT = "DEFAULT";

string g_sChatCmd = "ch"; // So the user can easily access it by type for instance *plugin
string g_sPluginTitle = "Cage Home"; // To be used in various strings
string CANT_DO = "Can not do - "; // Used in various responses (to specify a negative response to an issued command)

list g_lMenuButtons = [
    BTN_CAGEHERE, BTN_ARM, BTN_DISARM, BTN_RELEASE, BTN_SETTINGS, BTN_COMMANDS,
    BTN_TIME, BTN_RADIUS, BTN_WARNTIME, BTN_CHANNEL,
    BTN_ARRIVED, BTN_RELEASED, BTN_WARNING
];

// Available chat commands
list g_lChatCommands = [
  "here", "arm", "disarm", "release", "settings", "commands", // no-arg commands
  "cagetime", "radius", "warntime", "notifychannel", // integer-arg commands
  "notifyarrive", "notifyrelease", "warnmessage" // string-arg commands
];

integer CAGEHOME_NOTIFY = -11552; // Internal link num to announce arrivals and releases on

integer g_iTimerOnLine = 60;  // Check every .. seconds for on-line  (timer/dataserver)
integer g_iTimerOffLine = 15;  // Check every .. seconds for off-line (timer/dataserver)
integer g_iSensorTimer = 3;   // Check every .. seconds to see if cage owner is near (sensor)
integer g_iMaxTPtries = 5;   // ...until exhausted tries

// Plugin settings (dont change order as listed here, it's in 'protocol order'. see defaults below)
string g_sCageRegion; // Landing point sim name
vector g_vCagePos; // Landing point within region
vector g_vRegionPos; // Regions global position.

vector  g_vLocalPos; // Used when caged

integer g_iCageTime; // Time in minutes before the wearer is released, even if the owner is still online. Can be set to 0 for no auto release
integer g_iCageRadius; // How far the wearer may wander from the cage point, and how close the owner must be to auto release = g_fCageRadius+1
integer g_iWarningTime; // How much warning in seconds the wearer gets before being tped
integer g_iNotifyChannel; // What channel to send captured and released messages on
string g_sNotifyArrive; // The message said on g_iNotifyChannel after the wearer has been TPed to the cage home
string g_sNotifyRelease; // The message said on g_iNotifyChannel after the wearer has been released from the cage home
string g_sWarningMessage; // The warning message, @ is replaced by the wearer full name, and # by g_iWarningTime

integer g_iState; // Keep track of current state
integer g_iCageAuth;
key g_kCageOwnerKey;

integer g_iLoadState;

// Global boolean setting
integer g_bRLVActive = TRUE; // We'll get updates from the RLV script(s)

// Handles
list g_lMenuIDs;
integer g_iMenuStride = 3;

key g_kSimPosRequestHandle; // UUID of the dataserver request
key g_kOwnerRequestHandle;

integer g_iTargetHandle;
integer g_iTpTries; // Keep track of the number of TP attempts
integer g_iTimer ;

key g_kWearer;
list g_lLocalButtons = []; // Extra buttons that we get inserted "from above"

list STATES = ["UNSET", "DISARMED", "ARMED", "WARNING", "TELEPORT", "CAGED", "RELEASED"];

list g_lSetButtons = [
    "30 min", "1 hour", "1 day",
    "+10 min", "+1 hour", "+1 day",
    "-10 min", "-1 hour", "-1 day",
    "0", "1", "5",
    "10", "+1", "+5",
    "+10", "-1", "-5",
    "-10"
];

list g_lNums = [
    30, 60, 1440,
    10, 60, 1440,
    10, 60, 1440,
    0, 1, 5,
    10, 1, 5,
    10, 1, 5,
    10
];

Notify(key kID, string sMsg, integer bAlsoNotifyWearer) {
    llMessageLinked(LINK_DIALOG, NOTIFY, (string)bAlsoNotifyWearer + sMsg, kID);
}

Dialog(key kID, string sPrompt, list lChoices, list lUtility, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices,"`") + "|" + llDumpList2String(lUtility,"`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else {
        g_lMenuIDs += [kID, kMenuID, sName];
    }
}

MenuMain(key kID, integer iAuth) {
    string sPrompt = "\n";
    list lButtons;
    list lUtility = [BTN_SETTINGS, UPMENU];

    if (CheckAuth(iAuth) == TRUE && iAuth < CMD_WEARER) {
        if (g_sCageRegion == "") {
            sPrompt += "Have your sub auto teleport and caged the moment you log on again. The sub will be released if:\n\tYou approach the cage\n\tYou summon the sub\n\tThe timer runs out\n";
        }

        if (g_iState == STATE_DEFAULT) {
            lButtons = [BTN_CAGEHERE, BTN_BLANK, BTN_BLANK];
        } else if (g_iState == STATE_DISARMED) {
            if (g_sCageRegion) {
                lButtons = [BTN_CAGEHERE, BTN_ARM, BTN_CLEAR];
            } else {
                lButtons = [BTN_CAGEHERE, BTN_BLANK, BTN_BLANK];
            }
        } else if (g_iState == STATE_CAGED) {
            lButtons = [BTN_BLANK, BTN_RELEASE, BTN_BLANK];
        } else {
            lButtons = [BTN_BLANK, BTN_DISARM, BTN_BLANK];
        }

        if (g_iState < STATE_ARMED) {
            lUtility = [BTN_OPTIONS] + lUtility;
        }
    }

    string sSub;
    string sOwner;

    if (iAuth == CMD_WEARER) {
        sSub = "you";
        sOwner = "your";
    } else {
        sSub = "the sub";
        sOwner = "the";
    }

    sPrompt += "This feature will teleport " + sSub + " to a predefined location, set by " + sOwner + " owner, once " + sOwner + " owner logs on again.\n";
    sPrompt += "\nFeature currently: " + llList2String(STATES, g_iState) + " ";

    if (g_iState == STATE_CAGED) {
        if (g_iCageTime > 0) {
            sPrompt += " time is " + (string)g_iTimer + " min.";
        } else {
            sPrompt += "no timer release";
        }
    }

    if (g_sCageRegion) {
        sPrompt += "\nCage location: " + Map(g_sCageRegion, g_vCagePos);
    }

    if (g_kCageOwnerKey) {
        sPrompt += "\nCage owner: " + Name(g_kCageOwnerKey);
    }

    Dialog(kID, sPrompt, lButtons + g_lLocalButtons, lUtility, 0, iAuth, "menu~main");

    sPrompt = "";
    lButtons = [];
}

MenuSettings(key kID, integer iAuth) {
    string sPrompt = "Cage settings:\nCage Time: ";
    if (g_iCageTime > 0) {
        sPrompt += (string)g_iCageTime + " min";
    } else {
        sPrompt += "no timer release";
    }

    sPrompt +=
        "\tCage Radius: " + (string)g_iCageRadius + " m" +
        "\nWarning Time: " + (string)g_iWarningTime + " sec" +
        "\tNotify Channel: " + (string)g_iNotifyChannel +
        "\nArrived Message: " + g_sNotifyArrive +
        "\nReleased Message: " + g_sNotifyRelease +
        "\nWarning Message: " + g_sWarningMessage;

    list lButtons = llList2List(g_lMenuButtons, 6, -1); // Use settings buttons only
    Dialog(kID, sPrompt, lButtons, [BTN_DEFAULT, UPMENU], 0, iAuth, "menu~settings");

    sPrompt = "";
    lButtons = [];
}

MenuSet(key kID, integer iAuth, string sMenuButton) {
    list lButtons;
    string sPrompt = sMenuButton + ": ";
    integer i = llListFindList(g_lMenuButtons, [sMenuButton]);

    if (i == 6) sPrompt += (string)g_iCageTime + " min";
    else if (i == 7) sPrompt += (string)g_iCageRadius + " m";
    else if (i == 8) sPrompt += (string)g_iWarningTime + " sec";
    else if (i == 9) sPrompt += (string)g_iNotifyChannel;
    else if (i == 10) sPrompt += g_sNotifyArrive;
    else if (i == 11) sPrompt += g_sNotifyRelease;
    else if (i == 12) sPrompt += g_sWarningMessage;

    if (i == 6) {
        lButtons = llList2List(g_lSetButtons, 0, 9);  // Buttons for Cage ime
    } else if (6 < i < 10) {
        lButtons = llList2List(g_lSetButtons, 10, -1); // Buttons for others params
    }

    if (i > 9) {
        Dialog(kID, sPrompt, [], [], 0, iAuth, "set~" + sMenuButton); // Use textbox input directly
    } else {
        Dialog(kID, sPrompt, lButtons, [TEXTBOX, UPMENU], 0, iAuth, "set~" + sMenuButton);
    }

    sPrompt = "";
    lButtons = [];
}

Set(key kID, integer iAuth, string sMenuButton, string sButton) {
    sButton = llStringTrim(sButton, STRING_TRIM);
    if (sButton == TEXTBOX) {
        Dialog(kID, sMenuButton, [], [], 0, iAuth, "set~" + sMenuButton);
    } else {
        integer iMenu = llListFindList(g_lMenuButtons, [sMenuButton]);
        if (iMenu > 9) {
            //if (sButton)
            UserCommand(iAuth, g_sChatCmd + " " + llList2String(g_lChatCommands, iMenu) + " " + sButton, kID);
            MenuSettings(kID, iAuth);
        } else if (iMenu < 10) {
            string sParam;
            integer iParam;

            if (iMenu == 6) iParam = g_iCageTime;
            else if (iMenu == 7) iParam = g_iCageRadius;
            else if (iMenu == 8) iParam = g_iWarningTime;
            else if (iMenu == 9) iParam = g_iNotifyChannel;

            integer i = llListFindList(g_lSetButtons, [sButton]);
            if (~i) {
                integer iNum = llList2Integer(g_lNums, i);
                if (llGetSubString(sButton, 0, 0) == "-") {
                    iParam -= iNum;
                    if (iParam < 0) {
                        iParam = 0;
                    }
                } else if (llGetSubString(sButton, 0, 0)=="+") {
                    iParam += iNum;
                } else {
                    iParam = iNum;
                }

                sParam = (string)iParam;
            } else {
                if ((integer)sButton) {
                    sParam = sButton;
                } else {
                    sParam = "";
                }
            }

            if (iMenu > 6 && iMenu < 10 && sParam == "0") {
                sParam = "";
            }

            if (sParam) {
                UserCommand(iAuth, g_sChatCmd + " " + llList2String(g_lChatCommands, iMenu) + " " + sParam, kID);
            }

            MenuSet(kID, iAuth, sMenuButton);
        }
    }
}

// Stores all settings (using the settings or database script, or whatever)
SaveSettings() {
    string sSaveString = llDumpList2String([g_iCageTime, g_iCageRadius, g_iWarningTime, g_iNotifyChannel, g_sNotifyArrive, g_sNotifyRelease, g_sWarningMessage], "|");
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "cagehome_settings=" + sSaveString, "");
}

SaveRegion() {
    string sSaveString = llDumpList2String([g_sCageRegion, g_vCagePos, g_vRegionPos], "|");
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "cagehome_region=" + sSaveString, "");
}

SaveState() {
    string sSaveString = (string)g_iState + "|" + (string)g_iCageAuth + "|" + (string)g_kCageOwnerKey;
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "cagehome_state=" + sSaveString, "");
}

// Parses sValue, that we received from the settings or database script earlier,
// into our global settings variables.
ParseSettings(string sValue) {
    list lValues = llParseStringKeepNulls(sValue, ["|"], []);
    if (llGetListLength(lValues) == 7) {
        g_iCageTime = (integer)llList2String(lValues, 0);
        g_iCageRadius = (integer)llList2String(lValues, 1);
        g_iWarningTime = (integer)llList2String(lValues, 2);
        g_iNotifyChannel = (integer)llList2String(lValues, 3);
        g_sNotifyArrive = llList2String(lValues, 4);
        g_sNotifyRelease = llList2String(lValues, 5);
        g_sWarningMessage = llList2String(lValues, 6);
    }
    //else Debug("parse error");
}

ParseRegion(string sValue) {
    list lValues = llParseStringKeepNulls(sValue, ["|"], []);
    if (llGetListLength(lValues) == 3) {
        g_sCageRegion = llList2String(lValues, 0);
        g_vCagePos = (vector)llList2String(lValues, 1);
        g_vRegionPos = (vector)llList2String(lValues, 2);
    }
}

ParseState(string sValue) {
    list lValues = llParseString2List(sValue, ["|"], []);
    //g_iState = (integer)llList2String(lValues, 0);
    g_iLoadState = (integer)llList2String(lValues, 0);
    g_iCageAuth = (integer)llList2String(lValues, 1);
    g_kCageOwnerKey = (key)llList2String(lValues, 2);
}

// Reports current settings to kAv.
ReportSettings(key kAv) {
    string sMsg = g_sPluginTitle + " Settings:\nLocation: ";

    if (g_sCageRegion) {
        sMsg += Map(g_sCageRegion, g_vCagePos);
    } else {
        sMsg += " not set,";
    }

    sMsg += "\nCurrent state: " + llList2String(STATES, g_iState);

    if (g_kCageOwnerKey) {
        sMsg += "\nCage Owner: " + Name(g_kCageOwnerKey);
    }

    sMsg += "\nCage Wait: ";
    if (g_iCageTime > 0) {
        sMsg += (string)g_iCageTime + " min";
    } else {
        sMsg += "no timer release";
    }

    sMsg += "\nCage Radius: " + (string)g_iCageRadius + " m" +
        "\nWarning Time: " + (string)g_iWarningTime + " sec" +
        "\nCage Notify Channel: " + (string)g_iNotifyChannel +
        "\nArrived Message: " + g_sNotifyArrive +
        "\nReleased Message: " + g_sNotifyRelease +
        "\nWarning Message: " + g_sWarningMessage;

    // We're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    // and we know kAv is near
    llRegionSayTo(kAv, 0, sMsg);
}

ShowCommands(key kID) {
    // We're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    llRegionSayTo(kID, 0, llDumpList2String([g_sPluginTitle + " Commands:"] + g_lChatCommands, "\n"));
}

SetRLVRestrictions() {
    SendRLVCommands([
        "tplm=n",
        "tploc=n",
        "tplure=n",
        "tplure:" + (string)g_kCageOwnerKey + "=add",
        "sittp=n",
        "rez=n"
        //, "standtp=n"
    ]);
}

ClearRLVRestrictions() {
    SendRLVCommands([
        "tplm=y",
        "tploc=y",
        "tplure=y",
        "sittp=y",
        "rez=y"
        //, "standtp=y"
    ]);
}

// Sends a list of RLV-commands to the collar script(s), one by one.
SendRLVCommands(list lRLVCommands) {
    integer i;
    for (i = 0; i < llGetListLength(lRLVCommands); i++) {
        llMessageLinked(LINK_RLV, RLV_CMD, llList2String(lRLVCommands, i), "cagehome");
    }
}

// Returns sSource with sReplace replaced for all occasions of sSearch
string StrReplace(string sSource, string sSearch, string sReplace) {
    return llDumpList2String(llParseStringKeepNulls((sSource = "") + sSource, [sSearch], []), sReplace);
}

string Name(key kID) {
    return "secondlife:///app/agent/" + (string)kID + "/inspect";
}

// Returns vector vVec in a string with form "x/y/z", where x, y and z are
// rounded down to the nearest integer.
string Vector2UrlCoordinates(vector vVec) {
    return llDumpList2String([(integer)vVec.x, (integer)vVec.y, (integer)vVec.z], "/");
}

string Map(string sRegion, vector vPos) {
    return "http://maps.secondlife.com/secondlife/" + llEscapeURL(sRegion) + "/" + Vector2UrlCoordinates(vPos);
}

// Sends a message to kActor and the wearer about the captive change (armed, released, disarmed).
// A copy is sent to the wearer. If kActor is not the Cage Owner, the Cage Owner will receive a copy as well.
NotifyCaptiveChange(key kActor, integer iState) {
    string sActor = Name(kActor);
    string sMsg;

    if (iState == STATE_ARMED) {
        sMsg = sActor + " armed " + g_sPluginTitle + " for %WEARERNAME%";
    } else if (iState == STATE_DISARMED) {
        sMsg = sActor +" disarmed %WEARERNAME%'s " + g_sPluginTitle;
    } else if (iState == STATE_RELEASED) {
        sMsg = sActor + " released %WEARERNAME% from " + g_sPluginTitle;
    }

    Notify(kActor, sMsg, TRUE);

    if (kActor != g_kCageOwnerKey) {
        Notify(g_kCageOwnerKey, sMsg, FALSE);
    }
}

NotifyLocationSet(key kActor) {
    Notify(kActor, g_sPluginTitle + " Location set to " + Map(g_sCageRegion, g_vCagePos), TRUE);
}

CheckState() {
    if (g_iLoadState == STATE_CAGED) {
        if (llGetRegionName() == g_sCageRegion && llVecDist(g_vCagePos, llGetPos()) < 10) {
            SetState(STATE_CAGED);
        } else {
            SetState(STATE_TELEPORT);
        }
    } else {
        SetState(g_iLoadState);
    }
}

CheckTeleport() {
    //DebugCurrentState("CheckTeleport");
    if (g_iState == STATE_TELEPORT) {
        if (llGetRegionName() == g_sCageRegion && llVecDist(g_vCagePos,llGetPos()) < 10) {
            llSetTimerEvent(0);
            llResetTime();
            SetState(STATE_CAGED);
            return;
        } else {
            //llSetTimerEvent(g_iTP_Timer); // Try tp every ... seconds
            SendRLVCommands(["tploc=y", "unsit=y"]);
            //llOwnerSay("@tpto:" + Vector2UrlCoordinates(g_vRegionPos + g_vCagePos) + "=force");
            SendRLVCommands(["tpto:" + Vector2UrlCoordinates(g_vRegionPos + g_vCagePos) + "=force"]);
        }
    } else if (g_iState == STATE_CAGED) {
        if (llGetRegionName() != g_sCageRegion || llVecDist(g_vCagePos, llGetPos()) > 10) {
            // TP has been blocked, expect for summons by cage owner
            //SetState(STATE_RELEASED);
            SetState(STATE_DISARMED);
            NotifyCaptiveChange(g_kCageOwnerKey, STATE_RELEASED);
        }
    } else if (g_iState == STATE_ARMED) {
        /*
        if (llGetRegionName() == g_sCageRegion && llVecDist(g_vCagePos, llGetPos()) < 10) {
            SetState(STATE_CAGED);
        }
        */
    }
}

SetState(integer iState) {
    @again;
    //DebugCurrentState("SetState");

    if (iState == g_iState) {
        return;
    }

    g_iState = iState;
    if (iState <= STATE_DISARMED) {
        g_iCageAuth = CMD_EVERYONE;
        g_kCageOwnerKey = "";
        llSetTimerEvent(0);
        llSensorRemove();
        llTargetRemove(g_iTargetHandle);
        llStopMoveToTarget();
        ClearRLVRestrictions();
    } else if (iState == STATE_ARMED) {
        g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
    } else if (iState == STATE_WARNING) {
        if (g_iWarningTime > 1) {
            string sMsg = StrReplace(g_sWarningMessage, "@", Name(g_kWearer));
            sMsg = StrReplace(sMsg, "#", (string)g_iWarningTime);
            string sObjectName = llGetObjectName();
            llSetObjectName(g_sPluginTitle);
            llSay(0, sMsg);
            llSetObjectName(sObjectName);
            llSetTimerEvent(g_iWarningTime);
        } else {
            iState = STATE_TELEPORT;
            jump again;
        }
    } else if (iState == STATE_TELEPORT) {
        if (!g_bRLVActive || llGetAttached() == 0) {
            string sMsg = g_sPluginTitle + " can not teleport %WEARERNAME% for ";
            if (!g_bRLVActive) {
                sMsg += "RLV was not detected.";
            } else {
                sMsg += "%DEVICETYPE% seems not attached.";
            }
            Notify(g_kCageOwnerKey, sMsg + " AddOn now disarming itself.", TRUE);
            iState = STATE_DISARMED;
            jump again;
        } else {
            g_iTpTries = g_iMaxTPtries;
            llSetTimerEvent(5); // Let the timer event do the TP thing
        }
    } else if (iState == STATE_CAGED) {
        SetRLVRestrictions();
        if (llGetRegionName() == g_sCageRegion) {
            g_vLocalPos = g_vCagePos;
        } else {
            g_vLocalPos = llGetPos();
        }
        Notify(g_kCageOwnerKey, "Your sub %WEARERNAME% has just been teleported by the " + g_sPluginTitle + " feature and is now waiting for you at " + Map(llGetRegionName(), g_vLocalPos), FALSE);

        g_iTargetHandle = llTarget(g_vLocalPos, (float)g_iCageRadius);

        string sMsg = g_sPluginTitle + " now active ";
        if (g_iCageTime > 0) {
            g_iTimer = g_iCageTime;
            llSetTimerEvent(60);
            sMsg += "on a " + (string)g_iCageTime + " minutes timer";
        } else {
            sMsg += "with no time limit";
        }
        Notify(g_kWearer, sMsg, FALSE);

        llSensorRepeat("", g_kCageOwnerKey, AGENT, g_iCageRadius + 1, PI, g_iSensorTimer);
        if (g_iNotifyChannel != 0) {
            llSay(g_iNotifyChannel, g_sNotifyArrive);
        }
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY, g_sNotifyArrive, "");
    } else if (iState == STATE_RELEASED) {
        ClearRLVRestrictions();
        llSensorRemove();
        llStopMoveToTarget();
        llTargetRemove(g_iTargetHandle);
        if (g_iNotifyChannel != 0) {
            llSay(g_iNotifyChannel, g_sNotifyRelease);
        }
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY, g_sNotifyRelease, "");
        llSetTimerEvent(g_iTimerOnLine);
    }
    //DebugCurrentStateFreeMemory();
    SaveState();
}

// Return TRUE if Auth rank above Cage owner
integer CheckAuth(integer iAuth) {
    if ((STATE_RELEASED > g_iState > STATE_DISARMED) && (g_iCageAuth > 0) && (iAuth > g_iCageAuth)) {
        return FALSE;
    } else {
        return TRUE;
    }
}

UserCommand(integer iAuth, string sStr, key kID) {
    if (iAuth < CMD_OWNER || iAuth > CMD_WEARER) {
        return;
    }

    if (sStr == "menu " + g_sSubMenu || sStr == g_sSubMenu || sStr == g_sChatCmd) {
        MenuMain(kID, iAuth);
    } else if (llToLower(sStr) == "rm cagehome") {
        if (kID != g_kWearer && iAuth != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            Dialog(kID, "\nDo you really want to uninstall the " + g_sSubMenu + " App?", ["Yes", "No", "Cancel"], [], 0, iAuth, "rmcagehome");
        }
    } else if (sStr == "settings") { // Collar's command to request settings of all modules
        string sMsg = g_sPluginTitle + ": " + llList2String(STATES, g_iState);
        if (g_sCageRegion != "") {
            sMsg += ", TP Location: " + Map(g_sCageRegion, g_vCagePos);
        }
        llSleep(0.5);
        Notify(kID, sMsg, FALSE);
    } else {
        // PLUGIN CHAT g_lChatCommands
        if (llSubStringIndex(sStr, g_sChatCmd + " ") != 0) {
            return;
        }
        sStr = llDeleteSubString(sStr, 0, llStringLength(g_sChatCmd));
        string sCommand = sStr;
        string sValue = "";
        integer i = llSubStringIndex(sStr, " ");
        if (i != -1) {
            sCommand = llDeleteSubString(sStr, i, -1);
            sValue = llDeleteSubString(sStr, 0, i);
        }

        sStr = "";
        i = llListFindList(g_lChatCommands, [sCommand]); // re-use variable i
        if (!~i) {
            return;
        }

        if (CheckAuth(iAuth) == FALSE) {
            Notify(kID, "%NOACCESS", FALSE);
            return;
        }

        if (i == 0) { // chhere
            if (g_iState <= STATE_DISARMED) {
                g_vCagePos = llGetPos();
                g_sCageRegion = llGetRegionName();
                g_kSimPosRequestHandle = llRequestSimulatorData(g_sCageRegion, DATA_SIM_POS);
                // Script sleep 1.0 seconds
                if (g_iState == STATE_DEFAULT) {
                    SetState(STATE_DISARMED);
                }
                NotifyLocationSet(kID);
            } else {
                Notify(kID, CANT_DO + "still armed, disarm first", FALSE);
            }
        } else if (i == 1) { // charm
            if (g_iState <= STATE_DISARMED) {
                g_kCageOwnerKey = kID;
                g_iCageAuth = iAuth;
                SetState(STATE_ARMED);
                NotifyCaptiveChange(kID, STATE_ARMED);
            } else if (g_iState >= STATE_ARMED) {
                Notify(kID, CANT_DO + "already armed", FALSE);
            } else if (g_iState < STATE_DISARMED) {
                Notify(kID, CANT_DO + g_sPluginTitle + " Location not set", FALSE);
            }
        } else if (i == 2) { // chdisarm
            if (g_iState <= STATE_DISARMED) {
                Notify(kID, CANT_DO + "already disarmed", FALSE);
            } else if ((g_iState > STATE_DISARMED && g_iState < STATE_CAGED) || g_iState == STATE_RELEASED) {
                SetState(STATE_DISARMED);
                NotifyCaptiveChange(kID, STATE_DISARMED);
            } else if (g_iState == STATE_CAGED) {
                Notify(kID, CANT_DO + "release sub first", FALSE);
            }
        } else if (i == 3) { // chrelease
            if (g_iState >= STATE_TELEPORT && g_iState <= STATE_CAGED) {
                SetState(STATE_RELEASED);
                NotifyCaptiveChange(kID, STATE_RELEASED);
            } else if (g_iState <= STATE_WARNING) {
                Notify(kID, CANT_DO + "sub not caged", FALSE);
            }
        } else if (i == 4) {
            ReportSettings(kID); // chsettings
        } else if (i == 5) {
            ShowCommands(kID); // chcommands
        } else if (i > 5 && sValue == "") {
            // Next commands need an argument. check first for its existance:
            Notify(kID, "Command " + sCommand + " requires an argument", FALSE);
        } else {
            // Notify once, created with strings sDescr and sAppend:
            string sDescr = "";
            string sAppend = "";
            // Within this else-block: things with an argument (and then save)
            if (i == 6) { // chcagetime
                g_iCageTime = (integer)sValue;
                sDescr = "Cage Wait";
                sAppend = sValue + " min";
            } else if (i == 7) { // chradius
                g_iCageRadius = (integer)sValue;
                sDescr = "Cage Radius";
                sAppend = sValue + " m";
            } else if (i == 8) { // chwarntime
                g_iWarningTime = (integer)sValue;
                sDescr = "Warning Time";
                sAppend = sValue + " sec";
            } else if (i == 9) { // chnotifychannel
                g_iNotifyChannel = (integer)sValue;
                sDescr = "Cage Notify Channel";
                sAppend = sValue;
            } else {
                if (i == 10) { // cagenotifyarrive
                    g_sNotifyArrive = sValue;
                    sDescr = "Cage Notify Arrive";
                } else if (i == 11) { // cagenotifyrelease
                    g_sNotifyRelease = sValue;
                    sDescr = "Cage Notify Release";
                } else if (i == 12) { // cagewarningmessage
                    g_sWarningMessage = sValue;
                    sDescr = "Cage Warning Message";
                }

                sAppend = "'" + sValue + "'";
            }

            if (sDescr != "") {
                Notify(kID, sDescr + " set to " + sAppend, TRUE);
            }

            SaveSettings();
        }
    }
}


default {
    on_rez(integer iParam) {
        g_bRLVActive = TRUE; // Let the collar send new RLV-information upon rez
        g_iState = STATE_DEFAULT;
    }

    state_entry() {
        g_iState = STATE_DEFAULT;
        g_iCageAuth = CMD_EVERYONE;
        g_kWearer = llGetOwner();
        ParseSettings(g_sDefaultSettings); // Default settings do not include the home location
        //DebugCurrentStateFreeMemory();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum,sStr,kID);
        } else if (iNum == RLV_REFRESH && g_iState == STATE_CAGED) {
            SetRLVRestrictions();
        } else if (iNum == RLV_VERSION) {
            g_bRLVActive = TRUE;
        } else if (iNum == RLV_CLEAR && g_iState == STATE_CAGED) {
            SetState(STATE_RELEASED);
        } else if (iNum == RLV_ON) {
            g_bRLVActive = TRUE;
        } else if (iNum == RLV_OFF) {
            g_bRLVActive = FALSE;
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lLocalButtons = []; // Flush submenu buttons
            llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubMenu, "");
        } else if (iNum == MENUNAME_RESPONSE) { // A button is sent to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) { // Someone wants to stick something in our menu
                string sButton = llList2String(lParts, 1);
                if (llListFindList(g_lLocalButtons, [sButton]) == -1) {
                    g_lLocalButtons = llListSort(g_lLocalButtons + [sButton], 1, TRUE);
                }
            }
        } else if (iNum == MENUNAME_REMOVE) { // A button is sent to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) {
                integer iIndex = llListFindList(g_lLocalButtons, [llList2String(lParts, 1)]);
                if (~iIndex) {
                    g_lLocalButtons = llDeleteSubList(g_lLocalButtons, iIndex, iIndex);
                }
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "cagehome_settings") ParseSettings(sValue);
            else if (sToken == "cagehome_region") ParseRegion(sValue);
            else if (sToken == "cagehome_state") ParseState(sValue);
            else if (sStr == "settings=sent") CheckState();
        } else if (iNum == CMD_SAFEWORD && g_iState == STATE_CAGED) {
            SetState(STATE_RELEASED);
            NotifyCaptiveChange(g_kCageOwnerKey, STATE_RELEASED);
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex == -1) {
                return;
            }

            string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
            // Got a menu response meant for us, extract the sValues
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMsg = llList2String(lMenuParams, 1);
            //integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);

            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

            if (sMenu == "menu~main") {
                // Request to change to parent menu
                if (sMsg == UPMENU) {
                    llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);
                } else if (~llListFindList(g_lLocalButtons, [sMsg])) {
                    llMessageLinked(LINK_THIS, iAuth, "menu " + sMsg, kAv);
                } else if (sMsg == BTN_OPTIONS) {
                    MenuSettings(kAv, iAuth);
                } else {
                    integer i = llListFindList(g_lMenuButtons, [sMsg]);
                    if (~i) {
                        UserCommand(iAuth, g_sChatCmd + " " + llList2String(g_lChatCommands, i), kAv);
                    } else if (sMsg == BTN_CLEAR && g_iState == STATE_DISARMED) {
                        g_iState = STATE_DEFAULT;
                        g_iCageAuth = CMD_EVERYONE;
                        g_kCageOwnerKey = NULL_KEY;
                        g_sCageRegion = "";
                        g_vCagePos = ZERO_VECTOR;
                        g_vRegionPos = ZERO_VECTOR;
                        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "cagehome_state", "");
                        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "cagehome_region", "");
                    }

                    MenuMain(kAv, iAuth);
                }
            } else if (sMenu == "menu~settings") {
                if (sMsg == UPMENU) {
                    MenuMain(kAv, iAuth);
                } else if (sMsg == BTN_DEFAULT) {
                    ParseSettings(g_sDefaultSettings);
                    SaveSettings();
                    MenuSettings(kAv, iAuth);
                } else {
                    MenuSet(kAv, iAuth, sMsg);
                }
            } else if (llSubStringIndex(sMenu, "set~") == 0) {
                string sMenuButton = llDeleteSubString(sMenu, 0, llStringLength("set~") - 1);
                if (sMsg == UPMENU) {
                    MenuSettings(kAv, iAuth);
                } else {
                    Set(kAv, iAuth, sMenuButton, sMsg);
                }
            } else if (sMenu == "rmcagehome") {
                if (sMsg == "Yes") {
                    llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                    llMessageLinked(LINK_DIALOG, NOTIFY, "1" + g_sSubMenu + " App has been removed.", kAv);

                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
                        llRemoveInventory(llGetScriptName());
                    }
                } else {
                    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + g_sSubMenu + " App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        }
    }

    dataserver(key kQueryid, string data) {
        if (kQueryid == g_kSimPosRequestHandle) {
            g_vRegionPos = (vector)data;
            SaveRegion();
        } else if (kQueryid == g_kOwnerRequestHandle) { // Cage owner went offline
            if (data == "0") {
                llSetTimerEvent(g_iTimerOffLine);
                SetState(STATE_ARMED);
            }
            if (data == "1" && g_iState != STATE_RELEASED) {
                llSetTimerEvent(g_iTimerOnLine);
                SetState(STATE_WARNING);
            }
        }
    }

    timer() {
        if (g_iState == STATE_ARMED || g_iState == STATE_RELEASED) {
            g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
        } else if (g_iState == STATE_WARNING) {
            SetState(STATE_TELEPORT);
        } else if (g_iState == STATE_TELEPORT) {
            if (g_iTpTries > 0) {
                g_iTpTries--;
                CheckTeleport();
            } else {
                Notify(g_kWearer, "Number of TP tries exhausted. Caging you here.", FALSE);
                SetState(STATE_CAGED);
            }
        } else if (g_iState == STATE_CAGED) {
            g_iTimer--;
            if (g_iTimer <= 0) {
                Notify(g_kCageOwnerKey, "Time's up! %WEARERNAME% released from " + g_sPluginTitle, TRUE);
                SetState(STATE_RELEASED);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) {
            llResetScript();
        }

        if (iChange & CHANGED_TELEPORT) {
            CheckTeleport();
        }
    }

    sensor(integer iNum) {
        if (g_iState == STATE_CAGED) {
            Notify(g_kCageOwnerKey, "%WEARERNAME% released from " + g_sPluginTitle, TRUE);
            SetState(STATE_RELEASED);
        }
    }

    not_at_target() {
        if (g_iState == STATE_CAGED) {
            llMoveToTarget(g_vLocalPos, 0.5);
        }
    }

    at_target(integer iNum, vector vTargetPos, vector vOurPos) {
        if (g_iState == STATE_CAGED) {
            llStopMoveToTarget();
        }
    }
}
