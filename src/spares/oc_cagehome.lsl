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


//OpenCollar Plugin Template

string  g_sParentMenu = "Apps";
string  g_sSubMenu = "Cage Home";

// MESSAGE MAP
integer CMD_OWNER = 500;
//integer CMD_TRUST = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_OBJECT = 506;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;

integer NOTIFY      = 1002;
integer REBOOT      = -1000;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST  = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE   = 3003;

integer RLV_CMD     = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR   = 6002;
integer RLV_VERSION = 6003;
integer RLV_OFF     = 6100;
integer RLV_ON      = 6101;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TEXTBOX = "Text Input";

// default settings, will be loaded upon script start. leave landing point values blank!
string g_sDefaultSettings = "45|5|30|-1|arrived|released|@ will be summoned away in # seconds";

// State enumeration:
integer iDEFAULT  = 0;
integer iDISARMED = 1;
integer iARMED    = 2;
integer iWARNING  = 3;
integer iTELEPORT = 4;
integer iCAGED    = 5;
integer iRELEASED = 6;

// Dialog BUTtons:
string  sCAGEHERE = "Cage Here";
string  sARM      = "Arm";
string  sDISARM   = "Disarm";
string  sRELEASE  = "Release";
string  sSETTINGS = "Settings";
string  sCOMMANDS = "Commands";
string  sCLEAR    = "Clear";
string  sOPTIONS  = "Options";

string  sTIME     = "Cage Time";
string  sRADIUS   = "Cage Radius";
string  sWARNTIME = "Warning Time";
string  sCHANNEL  = "Channel";
string  sARRIVED  = "Arrived Msg";
string  sRELEASED = "Released Msg";
string  sWARNING  = "Warning Msg";

string  sBLANK     = " ";
string  sDEFAULT   = "DEFAULT";

string  g_sChatCmd = "ch";        // so the user can easily access it by type for instance *plugin
string  g_sPluginTitle = "Cage Home"; // to be used in various strings
string  CANT_DO = "Can not do - "; // used in various responses (to specify a negative response to an issued command)

list g_lMenuButtons = [
    sCAGEHERE, sARM, sDISARM, sRELEASE, sSETTINGS, sCOMMANDS,
    sTIME, sRADIUS, sWARNTIME, sCHANNEL,
    sARRIVED, sRELEASED, sWARNING
];

// available chat commands
list g_lChatCommands = [
  "here", "arm", "disarm", "release", "settings", "commands", // no-arg commands
  "cagetime", "radius", "warntime", "notifychannel",          // integer-arg commands
  "notifyarrive", "notifyrelease", "warnmessage"              // string-arg commands
];

integer CAGEHOME_NOTIFY = -11552; // internal link num to announce arrivals and releases on

integer g_iTimerOnLine  = 60;  // check every .. seconds for on-line  (timer/dataserver)
integer g_iTimerOffLine = 15;  // check every .. seconds for off-line (timer/dataserver)
integer g_iSensorTimer  = 3;   // check every .. seconds to see if cage owner is near (sensor)
integer g_iMaxTPtries   = 5;   // ...until exhausted tries

// plugin settings (dont change order as listed here, it's in 'protocol order'. see defaults below)
string  g_sCageRegion;      // landing point sim name
vector  g_vCagePos;         // landing point within region
vector  g_vRegionPos;       // regions global position.

vector  g_vLocalPos;        // used when caged

integer g_iCageTime;        // Time in minutes before the wearer is released, even if the owner is still online. Can be set to 0 for no auto release
integer g_iCageRadius;      // how far the wearer may wander from the cage point, and how close the owner must be to auto release = g_fCageRadius+1
integer g_iWarningTime;     // how much warning in seconds the wearer gets before being tped
integer g_iNotifyChannel;   // what channel to send captured and released messages on
string  g_sNotifyArrive;    // the message said on g_iNotifyChannel after the wearer has been TPed to the cage home
string  g_sNotifyRelease;   // the message said on g_iNotifyChannel after the wearer has been released from the cage home
string  g_sWarningMessage;  // the warning message, @ is replaced by the wearer full name, and # by g_iWarningTime

integer g_iState;        // keep track of current state
integer g_iCageAuth;
key     g_kCageOwnerKey;

integer g_iLoadState;

// global boolean setting
integer g_iRlvActive = TRUE; // we'll get updates from the rlv script(s)

// handles
list    g_lMenuIDs;
integer g_iMenuStride = 3;

key     g_kSimPosRequestHandle; // UUID of the dataserver request
key     g_kOwnerRequestHandle;

integer g_iTargetHandle;
integer g_iTpTries;      // keep track of the number of TP attempts
integer g_iTimer ;

key     g_kWearer;
list    g_lLocalButtons = []; // extra buttons that we get inserted "from above"


list lSTATES = ["UNSET","DISARMED","ARMED","WARNING","TELEPORT","CAGED","RELEASED"];


Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    llMessageLinked(LINK_THIS,NOTIFY,(string)iAlsoNotifyWearer+sMsg,kID);
}

Dialog(key kID, string sPrompt, list lChoices, list lUtility, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" +
    llDumpList2String(lChoices,"`") + "|" + llDumpList2String(lUtility,"`")+"|"+(string)iAuth,kMenuID);
    integer i = llListFindList(g_lMenuIDs, [kID]);
    if (~i) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], i, i + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

MenuMain(key kID, integer iAuth) {
    string sPrompt = "\n";
    list lButtons;
    list lUtility = [sSETTINGS,UPMENU];

    if (CheckAuth(iAuth)==TRUE && iAuth<CMD_WEARER) {
        if (g_sCageRegion=="") sPrompt +=
            "Have your sub auto teleport and caged the moment you log on again. The sub will be released if:" +
            "\n\tYou approach the cage\n\tYou summon the sub\n\tThe timer runs out\n";
        if (g_iState == iDEFAULT) lButtons = [sCAGEHERE,sBLANK,sBLANK];
        else if (g_iState == iDISARMED) {
            if (g_sCageRegion) lButtons = [sCAGEHERE,sARM,sCLEAR];
            else lButtons = [sCAGEHERE,sBLANK,sBLANK];
        }
        else if (g_iState == iCAGED) lButtons = [sBLANK,sRELEASE,sBLANK];
        else lButtons = [sBLANK,sDISARM,sBLANK];
        if (g_iState < iARMED) lUtility = [sOPTIONS]+lUtility;
    }
    string sSub;
    string sOwner;
    if (iAuth == CMD_WEARER) {sSub = "you"; sOwner = "your";}
    else {sSub = "the sub"; sOwner = "the";}
    sPrompt += "This feature will teleport " + sSub + " to a predefined location, set by " +
        sOwner + " owner, once " + sOwner + " owner logs on again.\n";

    sPrompt += "\nFeature currently: " + llList2String(lSTATES, g_iState) + " ";
    if (g_iState == iCAGED) {
        if (g_iCageTime > 0) sPrompt += " time is " + (string)g_iTimer + " min.";
        else sPrompt += "no timer release";
    }
    if (g_sCageRegion) sPrompt += "\nCage location: " + Map(g_sCageRegion, g_vCagePos);
    if (g_kCageOwnerKey) sPrompt += "\nCage owner: " + Name(g_kCageOwnerKey);

    Dialog(kID, sPrompt, lButtons+g_lLocalButtons, lUtility, 0, iAuth, "menu~main");
    sPrompt = "";
    lButtons = [];
}

MenuSettings(key kID, integer iAuth) {
    string sPrompt = "Cage settings:\nCage Time: ";
    if (g_iCageTime > 0) sPrompt += (string)g_iCageTime + " min";
    else sPrompt += "no timer release";
    sPrompt +=
        "\tCage Radius: " + (string)g_iCageRadius + " m" +
        "\nWarning Time: " + (string)g_iWarningTime + " sec" +
        "\tNotify Channel: " + (string)g_iNotifyChannel +
        "\nArrived Message: " + g_sNotifyArrive +
        "\nReleased Message: " + g_sNotifyRelease +
        "\nWarning Message: " + g_sWarningMessage;
    list lButtons = llList2List(g_lMenuButtons, 6, -1);  // use settings buttons only
    Dialog(kID, sPrompt, lButtons, [sDEFAULT,UPMENU], 0, iAuth, "menu~settings");
    sPrompt="";
    lButtons=[];
}

list g_lSetButtons =
["30 min","1 hour","1 day","+10 min","+1 hour","+1 day","-10 min","-1 hour","-1 day","0","1","5","10","+1","+5","+10","-1","-5","-10"];

list g_lNums = [30,60,1440,10,60,1440,10,60,1440,0,1,5,10,1,5,10,1,5,10];

MenuSet(key kID, integer iAuth, string sMenuButton) {
    list lButtons;
    string sPrompt = sMenuButton + ": ";
    integer i = llListFindList(g_lMenuButtons, [sMenuButton]);
    if (i == 6) sPrompt += (string)g_iCageTime+" min";
    else if (i == 7) sPrompt += (string)g_iCageRadius + " m";
    else if (i == 8) sPrompt += (string)g_iWarningTime + " sec";
    else if (i == 9) sPrompt += (string)g_iNotifyChannel;
    else if (i == 10) sPrompt += g_sNotifyArrive;
    else if (i == 11) sPrompt += g_sNotifyRelease;
    else if (i == 12) sPrompt += g_sWarningMessage;
    if (i == 6) lButtons = llList2List(g_lSetButtons,0,9);  // buttons for Cage ime
    else if (6 < i < 10) lButtons = llList2List(g_lSetButtons,10,-1); // buttons for others params
    if (i > 9) Dialog(kID,sPrompt,[],[],0,iAuth,"set~"+sMenuButton); // use textbox input directly
    else Dialog(kID,sPrompt,lButtons,[TEXTBOX,UPMENU],0,iAuth,"set~"+sMenuButton);
    sPrompt="";
    lButtons=[];
}

Set(key kID, integer iAuth, string sMenuButton, string sButton) {
    sButton = llStringTrim(sButton,STRING_TRIM);
    if (sButton==TEXTBOX) Dialog(kID,sMenuButton,[],[],0,iAuth,"set~"+sMenuButton);
    else {
        integer iMenu = llListFindList(g_lMenuButtons, [sMenuButton]);
        if (iMenu > 9) {
            //if (sButton)
            UserCommand(iAuth, g_sChatCmd +" "+ llList2String(g_lChatCommands,iMenu)+" "+sButton, kID);
            MenuSettings(kID, iAuth);
        } else if (iMenu < 10) {
            string sParam;
            integer iParam ;
            if (iMenu == 6) iParam = g_iCageTime;
            else if (iMenu == 7) iParam = g_iCageRadius;
            else if (iMenu == 8) iParam = g_iWarningTime;
            else if (iMenu == 9) iParam = g_iNotifyChannel;
            integer i = llListFindList(g_lSetButtons,[sButton]);
            if (~i) {
                integer iNum = llList2Integer(g_lNums,i);
                if (llGetSubString(sButton,0,0)=="-") {
                    iParam -= iNum;
                    if (iParam<0) iParam=0;
                } else if (llGetSubString(sButton,0,0)=="+") iParam += iNum;
                else iParam = iNum;
                sParam = (string)iParam;
            } else {
                if ((integer)sButton) sParam = sButton;
                else sParam = "";
            }
            if (iMenu > 6 && iMenu < 10 && sParam=="0") sParam = "";
            if (sParam) UserCommand(iAuth, g_sChatCmd+" "+llList2String(g_lChatCommands,iMenu)+" "+sParam, kID);
            MenuSet(kID, iAuth, sMenuButton);
        }
    }
}

// Stores all settings (using the settings or database script, or whatever)
SaveSettings() {
    string sSaveString = llDumpList2String([g_iCageTime, g_iCageRadius, g_iWarningTime, g_iNotifyChannel, g_sNotifyArrive, g_sNotifyRelease, g_sWarningMessage], "|");
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cagehome_settings="+sSaveString, "");
}

SaveRegion() {
    string sSaveString = llDumpList2String([g_sCageRegion, g_vCagePos, g_vRegionPos], "|");
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cagehome_region="+sSaveString, "");
}

SaveState() {
    string sSaveString = (string)g_iState+"|"+(string)g_iCageAuth+"|"+(string)g_kCageOwnerKey;
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cagehome_state="+sSaveString, "");
}

// Parses sValue, that we received from the settings or database script earlier,
// into our global settings variables.
ParseSettings(string sValue) {
    list lValues = llParseStringKeepNulls(sValue, ["|"], []);
    if (llGetListLength(lValues) == 7) {
        g_iCageTime       = (integer)llList2String(lValues, 0);
        g_iCageRadius     = (integer)llList2String(lValues, 1);
        g_iWarningTime    = (integer)llList2String(lValues, 2);
        g_iNotifyChannel  = (integer)llList2String(lValues, 3);
        g_sNotifyArrive   = llList2String(lValues, 4);
        g_sNotifyRelease  = llList2String(lValues, 5);
        g_sWarningMessage = llList2String(lValues, 6);
    }
    //else Debug("parse error");
}

ParseRegion(string sValue) {
    list lValues = llParseStringKeepNulls(sValue, ["|"], []);
    if (llGetListLength(lValues) == 3) {
        g_sCageRegion         = llList2String(lValues, 0);
        g_vCagePos    = (vector)llList2String(lValues, 1);
        g_vRegionPos  = (vector)llList2String(lValues, 2);
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

    if (g_sCageRegion) sMsg += Map(g_sCageRegion, g_vCagePos) ;
    else sMsg += " not set," ;
    sMsg += "\nCurrent state: " + llList2String(lSTATES,g_iState);
    if (g_kCageOwnerKey) sMsg += "\nCage Owner: " + Name(g_kCageOwnerKey);
    sMsg += "\nCage Wait: ";
    if (g_iCageTime > 0) sMsg += (string)g_iCageTime + " min";
    else sMsg += "no timer release";
    sMsg += "\nCage Radius: " + (string)g_iCageRadius + " m" +
        "\nWarning Time: " + (string)g_iWarningTime + " sec" +
        "\nCage Notify Channel: " + (string)g_iNotifyChannel +
        "\nArrived Message: " + g_sNotifyArrive +
        "\nReleased Message: " + g_sNotifyRelease +
        "\nWarning Message: " + g_sWarningMessage;
    // we're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    // and we know kAv is near
    llRegionSayTo(kAv, 0, sMsg);
}

ShowCommands(key kID) {
    // we're using the new llRegionSayTo() instead of llInstantMessage(), for it has no delay penalty
    llRegionSayTo(kID, 0, llDumpList2String([g_sPluginTitle + " Commands:"] + g_lChatCommands, "\n"));
}

SetRlvRestrictions() {
    SendRlvCommands(["tplm=n","tploc=n","tplure=n","tplure:"+(string)g_kCageOwnerKey+"=add", "sittp=n","rez=n"
        // ,"standtp=n"
    ]);
}

ClearRlvRestrictions() {
    SendRlvCommands(["tplm=y","tploc=y","tplure=y","sittp=y","rez=y"
        // ,"standtp=y"
    ]);
}

// Sends a list of RLV-commands to the collar script(s), one by one.
SendRlvCommands(list lRlvCommands) {
    integer i;
    for (i = 0; i < llGetListLength(lRlvCommands); i++) {
        llMessageLinked(LINK_THIS, RLV_CMD, llList2String(lRlvCommands, i), "cagehome");
    }
}

// Returns sSource with sReplace replaced for all occasions of sSearch
string StrReplace(string sSource, string sSearch, string sReplace) {
    return llDumpList2String(llParseStringKeepNulls((sSource = "") + sSource, [sSearch], []), sReplace);
}

string Name(key kID) {
    return "secondlife:///app/agent/"+(string)kID+"/inspect";
}
// Returns vector vVec in a string with form "x/y/z", where x, y and z are
// rounded down to the nearest integer.
string Vector2UrlCoordinates(vector vVec) {
    return llDumpList2String([(integer)vVec.x, (integer)vVec.y, (integer)vVec.z], "/");
}

string Map(string sRegion, vector vPos) {
    return "http://maps.secondlife.com/secondlife/" + llEscapeURL(sRegion) +"/"+ Vector2UrlCoordinates(vPos);
}

// Sends a message to kActor and the wearer about the captive change (armed, released, disarmed).
// A copy is sent to the wearer. If kActor is not the Cage Owner, the Cage Owner will receive a copy as well.
//
NotifyCaptiveChange(key kActor, integer iState) {
    string sActor = Name(kActor);
    string sMsg;
    if (iState == iARMED) sMsg = sActor+" armed "+g_sPluginTitle+" for %WEARERNAME%";
    else if (iState == iDISARMED) sMsg = sActor+" disarmed %WEARERNAME%'s "+g_sPluginTitle;
    else if (iState == iRELEASED) sMsg = sActor+" released %WEARERNAME% from "+g_sPluginTitle;
    Notify(kActor, sMsg, TRUE);
    if (kActor != g_kCageOwnerKey) Notify(g_kCageOwnerKey, sMsg, FALSE);
}

NotifyLocationSet(key kActor) {
    Notify(kActor, g_sPluginTitle+" Location set to "+Map(g_sCageRegion,g_vCagePos), TRUE);
}

CheckState() {
    if (g_iLoadState == iCAGED) {
        if (llGetRegionName()==g_sCageRegion && llVecDist(g_vCagePos,llGetPos()) < 10) SetState(iCAGED);
        else SetState(iTELEPORT);
    } else SetState(g_iLoadState);
}

CheckTeleport() {
    //DebugCurrentState("CheckTeleport");
    if (g_iState == iTELEPORT) {
        if (llGetRegionName()==g_sCageRegion && llVecDist(g_vCagePos,llGetPos()) < 10) {
            llSetTimerEvent(0);
            llResetTime();
            SetState(iCAGED);
            return;
        } else {
            //llSetTimerEvent(g_iTP_Timer); // try tp every ... seconds
            SendRlvCommands(["tploc=y","unsit=y"]);
            //llOwnerSay("@tpto:"+Vector2UrlCoordinates(g_vRegionPos+g_vCagePos)+"=force");
            SendRlvCommands(["tpto:"+Vector2UrlCoordinates(g_vRegionPos+g_vCagePos)+"=force"]);
        }
    } else if (g_iState == iCAGED) {
        if (llGetRegionName()!=g_sCageRegion || llVecDist(g_vCagePos,llGetPos())>10) {
            // TP has been blocked, expect for summons by cage owner
            //SetState(iRELEASED);
            SetState(iDISARMED);
            NotifyCaptiveChange(g_kCageOwnerKey, iRELEASED);
        }
    } else if (g_iState == iARMED) {
       // if (llGetRegionName()==g_sCageRegion && llVecDist(g_vCagePos,llGetPos())<10) {
           //SetState(iCAGED);
       // }
    }
}

SetState(integer iState) {
    @again;
    //DebugCurrentState("SetState");
    if (iState == g_iState) return;
    g_iState = iState;
    if (iState <= iDISARMED) {
        g_iCageAuth = CMD_EVERYONE;
        g_kCageOwnerKey = "";
        llSetTimerEvent(0);
        llSensorRemove();
        llTargetRemove(g_iTargetHandle);
        llStopMoveToTarget();
        ClearRlvRestrictions();
    } else if (iState == iARMED) {
        g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
    } else if (iState == iWARNING) {
        if (g_iWarningTime > 1) {
            string sMsg = StrReplace(g_sWarningMessage, "@", Name(g_kWearer));
            sMsg = StrReplace(sMsg, "#", (string)g_iWarningTime);
            string sObjectName = llGetObjectName();
            llSetObjectName(g_sPluginTitle);
            llSay(0, sMsg);
            llSetObjectName(sObjectName);
            llSetTimerEvent(g_iWarningTime);
        } else {
            iState = iTELEPORT;
            jump again;
        }
    } else if (iState == iTELEPORT) {
        if (!g_iRlvActive || llGetAttached() == 0) {
            string sMsg = g_sPluginTitle + " can not teleport %WEARERNAME% for ";
            if (!g_iRlvActive) sMsg += "RLV was not detected.";
            else sMsg += "%DEVICETYPE% seems not attached.";
            Notify(g_kCageOwnerKey, sMsg + " AddOn now disarming itself.", TRUE);
            iState = iDISARMED;
            jump again;
        } else {
            g_iTpTries = g_iMaxTPtries;
            llSetTimerEvent(5); // let the timer event do the TP thing
        }
    } else if (iState == iCAGED) {
        SetRlvRestrictions();
        if (llGetRegionName()==g_sCageRegion) g_vLocalPos = g_vCagePos;
        else g_vLocalPos = llGetPos();
        Notify(g_kCageOwnerKey, "Your sub %WEARERNAME% has just been teleported by the "+g_sPluginTitle+
            " feature and is now waiting for you at "+Map(llGetRegionName(),g_vLocalPos), FALSE);
        g_iTargetHandle = llTarget(g_vLocalPos, (float)g_iCageRadius);
        string sMsg = g_sPluginTitle + " now active ";
        if (g_iCageTime > 0) {
            g_iTimer = g_iCageTime;
            llSetTimerEvent(60);
            sMsg += "on a " + (string)g_iCageTime + " minutes timer";
        } else sMsg += "with no time limit";
        Notify(g_kWearer, sMsg, FALSE);
        llSensorRepeat("", g_kCageOwnerKey, AGENT, g_iCageRadius+1, PI, g_iSensorTimer);
        if (g_iNotifyChannel != 0) llSay(g_iNotifyChannel, g_sNotifyArrive);
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY, g_sNotifyArrive, "");
    } else if (iState == iRELEASED) {
        ClearRlvRestrictions();
        llSensorRemove();
        llStopMoveToTarget();
        llTargetRemove(g_iTargetHandle);
        if (g_iNotifyChannel != 0) llSay(g_iNotifyChannel, g_sNotifyRelease);
        llMessageLinked(LINK_THIS, CAGEHOME_NOTIFY, g_sNotifyRelease, "");
        llSetTimerEvent(g_iTimerOnLine);
    }
    //DebugCurrentStateFreeMemory();
    SaveState();
}

// return TRUE if Auth rank above Cage owner
integer CheckAuth(integer iAuth) {
    if ((iRELEASED>g_iState>iDISARMED) && (g_iCageAuth>0) && (iAuth>g_iCageAuth)) return FALSE;
    else return TRUE;
}

UserCommand(integer iAuth, string sStr, key kID) {
    if (iAuth < CMD_OWNER || iAuth > CMD_WEARER) return;

    if (sStr=="menu "+g_sSubMenu || sStr==g_sSubMenu || sStr==g_sChatCmd) MenuMain(kID,iAuth);
    else if (llToLower(sStr) == "rm cagehome") {
        if (kID!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_THIS,NOTIFY,"0"+"%NOACCESS%",kID);
        else Dialog(kID, "\nDo you really want to uninstall the "+g_sSubMenu+" App?", ["Yes","No","Cancel"], [], 0, iAuth,"rmcagehome");        
    } else if (sStr == "settings") { // collar's command to request settings of all modules
        string sMsg = g_sPluginTitle+": "+llList2String(lSTATES, g_iState);
        if (g_sCageRegion!="") sMsg += ", TP Location: "+Map(g_sCageRegion, g_vCagePos);
        llSleep(0.5);
        Notify(kID, sMsg, FALSE);
    } else {
        // PLUGIN CHAT g_lChatCommands
        if (llSubStringIndex(sStr, g_sChatCmd+" ") != 0) return;
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
        if (!~i) return;
        if (CheckAuth(iAuth)==FALSE) {
            Notify(kID, "%NOACCESS", FALSE);
            return;
        }
        if (i == 0) { // chhere
            if (g_iState <= iDISARMED) {
                g_vCagePos = llGetPos();
                g_sCageRegion = llGetRegionName();
                g_kSimPosRequestHandle = llRequestSimulatorData(g_sCageRegion, DATA_SIM_POS);
                // script sleep 1.0 seconds
                if (g_iState == iDEFAULT) SetState(iDISARMED);
                NotifyLocationSet(kID);
            } else Notify(kID, CANT_DO+"still armed, disarm first", FALSE);
        } else if (i == 1) { // charm
            if (g_iState <= iDISARMED) {
                g_kCageOwnerKey = kID;
                g_iCageAuth = iAuth;
                SetState(iARMED);
                NotifyCaptiveChange(kID, iARMED);
            } else if (g_iState >= iARMED) Notify(kID,CANT_DO+"already armed",FALSE);
            else if (g_iState < iDISARMED) Notify(kID,CANT_DO+g_sPluginTitle+" Location not set",FALSE);
        } else if (i == 2) { // chdisarm
            if (g_iState <= iDISARMED) Notify(kID,CANT_DO+"already disarmed",FALSE);
            else if ((g_iState > iDISARMED && g_iState < iCAGED) || g_iState == iRELEASED) {
                SetState(iDISARMED);
                NotifyCaptiveChange(kID, iDISARMED);
            } else if (g_iState == iCAGED) Notify(kID,CANT_DO+"release sub first",FALSE);
        } else if (i == 3) { // chrelease
            if (g_iState >= iTELEPORT && g_iState <= iCAGED) {
                SetState(iRELEASED);
                NotifyCaptiveChange(kID, iRELEASED);
            } else if (g_iState <= iWARNING) Notify(kID,CANT_DO+"sub not caged",FALSE);
        } else if (i == 4) ReportSettings(kID); // chsettings
        else if (i == 5) ShowCommands(kID); // chcommands
        // next commands need an argument. check first for its existance:
        else if (i > 5 && sValue == "") Notify(kID, "Command "+sCommand+" requires an argument", FALSE);
        else {
            // notify once, created with strings sDescr and sAppend:
            string sDescr = "";
            string sAppend = "";
            // within this else-block: things with an argument (and then save)
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
            if (sDescr != "") Notify(kID, sDescr+" set to "+sAppend, TRUE);
            SaveSettings();
        }
    }
}


default {

    on_rez(integer iParam) {
        g_iRlvActive = TRUE; // let the collar send new RLV-information upon rez
        g_iState = iDEFAULT;
    }

    state_entry() {
        g_iState = iDEFAULT;
        g_iCageAuth = CMD_EVERYONE;
        g_kWearer = llGetOwner();
        ParseSettings(g_sDefaultSettings); // default settings do not include the home location
        //DebugCurrentStateFreeMemory();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum,sStr,kID);
        else if (iNum == RLV_REFRESH && g_iState == iCAGED) SetRlvRestrictions();
        else if (iNum == RLV_VERSION) g_iRlvActive = TRUE;
        else if (iNum == RLV_CLEAR && g_iState == iCAGED) SetState(iRELEASED);
        else if (iNum == RLV_ON) g_iRlvActive = TRUE;
        else if (iNum == RLV_OFF) g_iRlvActive = FALSE;
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+g_sSubMenu, "");
            g_lLocalButtons = [] ; // flush submenu buttons
            llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubMenu, "");
        } else if (iNum == MENUNAME_RESPONSE) { // a button is sent to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) { // someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lLocalButtons,[button])==-1) g_lLocalButtons=llListSort(g_lLocalButtons+[button],1,TRUE);
            }
        } else if (iNum == MENUNAME_REMOVE) { // a button is sent to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu) {
                integer i = llListFindList(g_lLocalButtons,[llList2String(lParts, 1)]);
                if (~i) g_lLocalButtons=llDeleteSubList(g_lLocalButtons, i, i);
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "cagehome_settings") ParseSettings(sValue);
            else if (sToken == "cagehome_region") ParseRegion(sValue);
            else if (sToken == "cagehome_state") ParseState(sValue);
            else if (sStr == "settings=sent") CheckState();
        } else if (iNum == CMD_SAFEWORD && g_iState == iCAGED) {
            SetState(iRELEASED);
            NotifyCaptiveChange(g_kCageOwnerKey, iRELEASED);
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex == -1) return;
            string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
            // got a menu response meant for us, extract the sValues
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMsg = llList2String(lMenuParams, 1);
            //integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);
            if (sMenu == "menu~main") {
                // request to change to parent menu
                if (sMsg == UPMENU) llMessageLinked(LINK_THIS,iAuth,"menu "+g_sParentMenu,kAv);
                else if (~llListFindList(g_lLocalButtons,[sMsg])) llMessageLinked(LINK_THIS,iAuth,"menu "+sMsg,kAv);
                else if (sMsg == sOPTIONS) MenuSettings(kAv, iAuth);
                else {
                    integer i = llListFindList(g_lMenuButtons, [sMsg]);
                    if (~i) UserCommand(iAuth, g_sChatCmd+" "+llList2String(g_lChatCommands, i), kAv);
                    else if (sMsg == sCLEAR && g_iState == iDISARMED) {
                        g_iState = iDEFAULT;
                        g_iCageAuth = CMD_EVERYONE;
                        g_kCageOwnerKey = NULL_KEY;
                        g_sCageRegion = "";
                        g_vCagePos = ZERO_VECTOR;
                        g_vRegionPos = ZERO_VECTOR;
                        llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "cagehome_state", "");
                        llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "cagehome_region", "");
                    }
                    MenuMain(kAv, iAuth);
                }
            } else if (sMenu == "menu~settings") {
                if (sMsg == UPMENU) MenuMain(kAv, iAuth);
                else if (sMsg == sDEFAULT) {
                    ParseSettings(g_sDefaultSettings);
                    SaveSettings();
                    MenuSettings(kAv, iAuth);
                } else MenuSet(kAv, iAuth, sMsg);
            } else if (llSubStringIndex(sMenu,"set~") == 0) {
                string sMenuButton = llDeleteSubString(sMenu,0,llStringLength("set~")-1);
                if (sMsg == UPMENU) MenuSettings(kAv, iAuth);
                else Set(kAv, iAuth, sMenuButton, sMsg);
            } else if (sMenu == "rmcagehome") {
                if (sMsg == "Yes") {
                    llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                    llMessageLinked(LINK_THIS, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                } else llMessageLinked(LINK_THIS, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
            }         
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    dataserver(key kQueryid, string data) {
        if (kQueryid == g_kSimPosRequestHandle) {
            g_vRegionPos = (vector)data;
            SaveRegion();
        } else if (kQueryid == g_kOwnerRequestHandle) { // cage owner went offline
            if (data == "0") {
                llSetTimerEvent(g_iTimerOffLine);
                SetState(iARMED);
            }
            if (data == "1" && g_iState != iRELEASED) {
                llSetTimerEvent(g_iTimerOnLine);
                SetState(iWARNING);
            }
        }
    }

    timer() {
        if (g_iState == iARMED || g_iState == iRELEASED) {
            g_kOwnerRequestHandle = llRequestAgentData(g_kCageOwnerKey, DATA_ONLINE);
        } else if (g_iState == iWARNING) SetState(iTELEPORT);
        else if (g_iState == iTELEPORT) {
            if (g_iTpTries > 0) {
                g_iTpTries--;
                CheckTeleport();
            } else {
                Notify(g_kWearer, "Number of TP tries exhausted. Caging you here.", FALSE);
                SetState(iCAGED);
            }
        } else if (g_iState == iCAGED) {
            g_iTimer--;
            if (g_iTimer <= 0) {
                Notify(g_kCageOwnerKey, "Time's up! %WEARERNAME% released from "+g_sPluginTitle, TRUE);
                SetState(iRELEASED);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_TELEPORT) CheckTeleport();
    }

    sensor(integer iNum) {
        if (g_iState == iCAGED) {
            Notify(g_kCageOwnerKey, "%WEARERNAME% released from "+g_sPluginTitle, TRUE);
            SetState(iRELEASED);
        }
    }

    not_at_target() {
        if (g_iState == iCAGED) llMoveToTarget(g_vLocalPos, 0.5);
    }

    at_target(integer iNum, vector vTargetPos, vector vOurPos) {
        if (g_iState == iCAGED) llStopMoveToTarget();
    }
}
