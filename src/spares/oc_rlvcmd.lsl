// This file is part of OpenCollar.
// Copyright (c) 2008 - 2015 Satomi Ahn, Nandana Singh, Joy Stipe,
// Wendy Starfall, Sumi Perl, littlemousy, Romka Swallowtail et al.
// Licensed under the GPLv2.  See LICENSE for full details.


//RLV Commands (from RLVa sourcecode - rlvhandler.h v1.4.10)
// @getstatus:[<option>][;<separator>] * Examples  : @getstatus=123 ; @getstatus:tp=123 ; @getstatus:tp;|=123 ; @getstatus:;|=123
//   - if we passed RlvObject::m_idObj for idObj somewhere and process a @clear then idObj points to invalid/cleared memory at the end


//****Actions****//
// @unsit=force             - Checked: 2010-03-18 (RLVa-1.2.0c) | Modified: RLVa-0.2.0g
// @remattach=force         - force detach all attachments points
// @detachme=force           <--pulls off collar   - Checked: 2010-09-04 (RLVa-1.2.1c) | Modified: RLVa-1.2.1c
//****Actions w/ textbox****//
// @setgroup:<uuid|name>=force          - Checked: 2011-03-28 (RLVa-1.4.1a) | Added: RLVa-1.3.0f
// @sit:<option>=force
// @tpto:<option>=force                 - Checked: 2011-03-28 (RLVa-1.3.0f) | Modified: RLVa-1.3.0f

//****Wearables****//
// @remattach:<attachpt>=force          - force detach single attachment point
// @detach:<attachpt>=n|y               - RLV_LOCK_ADD and RLV_LOCK_REMOVE locks an attachment *point*
// @detach[:<option>]=force             - Checked: 2010-08-30 (RLVa-1.2.1c) | Modified: RLVa-1.2.1c
// @remattach[:<option>]=force
// @remoutfit[:<option>]=force
//****Wearables w/ textbox****//
// @getattach[:<layer>]=<channel>
// @getattachnames[:<grp>]=<channel>
// @getaddattachnames[:<grp>]=<channel>
// @getremattachnames[:<grp>]=<channel>
// @getoutfit[:<layer>]=<channel>
// @getoutfitnames=<channel>
// @getaddoutfitnames=<channel>
// @getremoutfitnames=<channel>
// @findfolder:<criteria>=<channel>
// @findfolders:<criteria>=<channel>
// @getpath[:<option>]=<channel>
// @getpathnew[:<option>]=<channel>
// @getinv[:<path>]=<channel>
// @getinvworn[:<path>]=<channel>

//****Info Gather****//
// @getgroup=<channel>                  - Checked: 2011-03-28 (RLVa-1.4.1a) | Added: RLVa-1.3.0f
// @getsitid=<channel>                  - Checked: 2010-03-09 (RLVa-1.2.0a) | Modified: RLVa-1.2.0a
// @getstatus=<channel>                 - Checked: 2010-04-07 (RLVa-1.2.0d) | Modified: RLVa-1.1.0f
// @getstatusall=<channel>              - Checked: 2010-04-07 (RLVa-1.2.0d) | Modified: RLVa-1.1.0f
// @version=<channel>                   - Checked: 2010-03-27 (RLVa-1.4.0a)
// @versionnew=<channel>                - Checked: 2010-03-27 (RLVa-1.4.0a) | Added: RLVa-1.2.0b
// @versionnum=<channel>                - Checked: 2010-03-27 (RLVa-1.4.0a) | Added: RLVa-1.0.4b

//****Commandline Search****//
// @getcommand:<option>=<channel>       - Checked: 2010-12-11 (RLVa-1.2.2c) | Added: RLVa-1.2.2c



// @redirchat:<channel>=n|y
// @rediremote:<channel>=n|y
// @sendchannel[:<channel>]=n|y
// @notify:<params>=add|rem

//Deprecated -> @adjustheight:<options>=force

//END RLV Commands



//channel = 0 //force == 1 //option,force = 2 //option,channel = 3
//attachpt+option,n/y+force = 4 (detachme) //channel,n/y = 5 //params,add/rem = 6

list g_lEnablements = [ // These are y/n type answers
    "detach",
    "addattach",
    "attachthis",
    "detachthis",
    "attachtallhis",
    "detachallthis",
    "attachthisexcept",
    "detachthisexcept",
    "attachallthisexcept",
    "detachallthisexcept",
    "addoutfit",
    "remoutfit",
    "setenv",
    "sharedwear",
    "sharedunwear",
    "unsharedwear",
    "unsharedunwear",
    "showhovertext",
    "showloc",
    "shownames",
    "emote",
    "sendchat",
    "chatwhisper",
    "chatnormal",
    "chatshout",
    "permissive",
    "showinv",
    "showminimap",
    "showworldmap",
    "showhovertexthud",
    "showhovertextworld",
    "showhovertextall",
    "standtp",
    "tplm",
    "tploc",
    "viewnote",
    "viewscript",
    "viewtexture",
    "acceptpermission",
    "allowidle",
    "rez",
    "fartouch",
    "interact",
    "touchattachself",
    "touchattachother",
    "touchall",
    "touchme",
    "fly",
    "setgroup",
    "alwaysrun",
    "temprun",
    "unsit",
    "sit",
    "sittp",
    "setdebug",
    "recvchat",
    "recvemote",
    "sendim",
    "recvim",
    "startim",
    "tplure",
    "tprequest",
    "accepttp",
    "accepttprequest",
    "touchattach",
    "touchhud",
    "touchworld",
    "edit",
    "recvchatfrom",
    "recvemotefrom",
    "sendimto",
    "recvimfrom",
    "startimto",
    "editobj",
    "touchthis"
];

list g_lActions = [ //channel = 0 //force == 1 //option,force = 2 //option,channel = 3 //attachpt+option,n/y+force = 4 (detachme)
    "unsit", "1",
    "remattach", "1",
    "detachme", "1",
    "setgroup", 2,
    "sit", 2,
    "tpto", 2
];

list g_lWearables = [ //channel = 0 //force == 1 //option,force = 2 //option,channel = 3
    "remattach", 2,
    "detach", 4,
    "remattach", 2,
    "remoutfit", 2,
    "getattach", 3,
    "getattachnames", 3,
    "getaddattachnames", 3,
    "getremattachnames", 3,
    "getoutfit", 3,
    "getoutfitnames", 0,
    "getaddoutfitnames", 0,
    "getremoutfitnames", 0,
    "findfolder", 3,
    "findfolders", 3,
    "getpath", 3,
    "getpathnew", 3,
    "getinv", 3,
    "getinvworn", 3
];

list g_lGatherInfo = [ //channel = 0 //force == 1 //option,force = 2 //option,channel = 3 (4)
    "getgroup", 0,
    "getsitid", 0,
    "getstatus", 0,
    "getstatusall", 0,
    "version", 0,
    "versionnew", 0,
    "versionnum", 0
];

//****Commandline Search****//
// @getcommand:<option>=<channel>               - Checked: 2010-12-11 (RLVa-1.2.2c) | Added: RLVa-1.2.2c

list g_lChat = [
    "redirchat", 5,
    "rediremote", 5,
    "sendchannel", 5,
    "notify", 6
];
//channel = 0 //force == 1 //option,force = 2 //option,channel = 3
//attachpt+option,n/y+force = 4 (detachme) //channel,n/y = 5 //params,add/rem = 6 //y/n = 7



list g_lDisabled; // We will log our disabled here

string g_sSubMenu = "RLVcmd"; // Name of the submenu
string g_sParentMenu = "Apps"; // Name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore

key g_kMenuID; // Menu handler
key g_kMenuIDEnablements; // Menu handler
key g_kMenuIDOther;
key g_kWearer; // Key of the current wearer to reset only on owner changes
key g_kClicker; // Capture clicker IDs

integer g_bRLVOn = FALSE;
integer g_bRLVaOn = FALSE;
integer g_iListenerHandle;

list g_lListeners;
key g_kRLVCommand;

key g_kRLVTextboxCommand; // Textbox handler in case we need more information
list g_lStoredCommand = []; // and a list to queue stored commands (these expire)

list g_lRLVCommandHistory; // History of commands
integer g_iListenerChannel;

integer g_iExceptionsChannel = 98726392; // Channel to listen for exceptions

string TICKED = "☒ ";
string UNTICKED = "☐ ";

// OpenCollar MESSAGE MAP

// Messages for authenticating users

integer CMD_OWNER = 500;
//integer CMD_TRUST = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLACKLIST = 520;
// Added for timer so when the sub is locked out they can use postions
//integer CMD_WEARERLOCKEDOUT = 521;

//integer ATTACHMENT_REQUEST = 600;
//integer ATTACHMENT_RESPONSE = 601;
//integer ATTACHMENT_FORWARD = 610;

//integer WEARERLOCKOUT = 620; // Turns on and off wearer lockout

//integer SEND_IM = 1000; // Deprecated. Each script should send its own IMs now.
// This is to reduce even the tiny bit of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;

// Messages for storing and retrieving values from settings store
//integer LM_SETTING_SAVE = 2000; // Scripts send messages on this channel to have settings saved to settings store
// str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001; // When startup, scripts send requests for settings on this channel
//integer LM_SETTING_RESPONSE = 2002; // The settings script will send responses on this channel
//integer LM_SETTING_DELETE = 2003; // Delete token from settings store
//integer LM_SETTING_EMPTY = 2004; // Sent by settings script when a token has no value in the settings store
//integer LM_SETTING_REQUEST_NOCACHE = 2005;

// Messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

// Messages for RLV commands
integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002; // RLV plugins should clear their restriction lists upon receiving this message.
//integer RLV_VERSION = 6003; // RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer RLVA_VERSION = 6004;
integer RLV_OFF = 6100; // Send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // Send to inform plugins that RLV is enabled now, no message or key needed
//integer RLV_QUERY = 6102; // Query from a script asking if RLV is currently functioning
//integer RLV_RESPONSE = 6103; // Reply to RLV_QUERY, with "ON" or "OFF" as the message

// Messages for poses and couple anims
//integer ANIM_START = 7000; // Send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001; // Send this with the name of an anim in the string part of the message to stop the anim
//integer CPLANIM_PERMREQUEST = 7002; // id should be av's key, str should be cmd name "hug", "kiss", etc
//integer CPLANIM_PERMRESPONSE = 7003; // str should be "1" for got perms or "0" for not.  id should be av's key
//integer CPLANIM_START = 7004; // str should be valid anim name.  id should be av
//integer CPLANIM_STOP = 7005; // str should be valid anim name.  id should be av

// Messages to the dialog helper
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;

//integer FIND_AGENT = -9005; // To look for agent(s) in region with a (optional) search string
//key REQUEST_KEY;

//integer TIMER_EVENT = -10000; // str = "start" or "end". For start, either "online" or "realtime".

//integer UPDATE = 10001;  // for child prim scripts (currently none in 3.8, thanks to LSL new functions)

// For other things that want to manage showing/hiding keys.
//integer KEY_VISIBLE = -10100;
//integer KEY_INVISIBLE = -10100;

//integer CMD_PARTICLE = 20000;
//integer CMD_LEASH_SENSOR = 20001;

// Chain systems
//integer LOCKMEISTER = -8888;
//integer LOCKGUARD = -9119;

// RLV relay chan
//integer RLV_RELAY_CHANNEL = -1812221819;

// Menu option to go one step back in menustructure
string  UPMENU = "BACK"; // When your menu hears this, give the parent menu

integer NOTIFY = 1002;

integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

/*
Debug(string sMsg) {
    llOwnerSay(llGetScriptName() + " [DEBUG]: " + sMsg);
}
*/

Notify(key kID, string sMsg, integer bAlsoNotifyWearer) {
    llMessageLinked(LINK_DIALOG, NOTIFY, (string)bAlsoNotifyWearer + sMsg, kID);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

integer FindCommandType(string sCommand) { // This is really inefficient, need one function to do this
    integer iToken;
    if (llListFindList(g_lChat, [sCommand]) >= 0) {
        iToken = llListFindList(g_lChat, [sCommand]);
        iToken = llList2Integer(g_lChat, iToken + 1);
    } else if (llListFindList(g_lGatherInfo, [sCommand]) >= 0) {
        iToken = llListFindList(g_lGatherInfo, [sCommand]);
        iToken = llList2Integer(g_lGatherInfo, iToken + 1);
    } else if (llListFindList(g_lWearables, [sCommand]) >= 0) {
        iToken = llListFindList(g_lWearables, [sCommand]);
        iToken = llList2Integer(g_lWearables, iToken + 1);
    } else if (llListFindList(g_lActions, [sCommand]) >= 0) {
        iToken = llListFindList(g_lActions, [sCommand]);
        iToken = llList2Integer(g_lActions, iToken + 1);
    } else {
    } // TODO - Use GETCOMMAND to match partial string|tpto|

    return iToken;
}


DoMenu(key keyID, integer iAuth) {
    string sPrompt = "\n" + g_sSubMenu;
    list lButtons;
    if (g_bRLVOn) {
        sPrompt += " Enabled.  Press CMD to enter a command.  Press HELP for a list of commands\n\n[http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI RLVcmd Help Page]";
        lButtons += [
            "CMD", "History", "Enablements",
            "GatherInfo", "Wearables", "Actions"
        ];
    } else {
        lButtons = [];
        sPrompt = "RLV is Disabled.  Please enable RLV to use this plugin.";
    }
    g_kMenuID = Dialog(keyID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

DoMenuEnablements(key kAv, integer iAuth) {
    string sPrompt = "\nEnablements";
    integer i;
    integer iLength = llGetListLength(g_lEnablements);
    list lButtons;

    for(; i < iLength; ++i) {
        if (llListFindList(g_lDisabled, llList2List(g_lEnablements, i, i)) >= 0) {
            lButtons += TICKED + llList2String(g_lEnablements, i);
        } else {
            lButtons += UNTICKED + llList2String(g_lEnablements, i);
        }
    }

    g_kMenuIDEnablements = Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

// g_lEnablements,g_lChat,g_lGatherInfo,g_lWearables,g_lActions g_kMenuIDOther
DoMenuOther(key kAv, integer iAuth, string sType) {
    string sPrompt = sType + "\n[http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI RLVcmd Help]";
    list lButtons;

    if (sType == "Chat") {
        lButtons = llList2ListStrided(g_lChat, 0, -1, 2);
    } else if (sType == "GatherInfo") {
        lButtons = llList2ListStrided(g_lGatherInfo, 0, -1, 2);
    } else if (sType == "Wearables") {
        lButtons = llList2ListStrided(g_lWearables, 0, -1, 2);
    } else if (sType == "Actions") {
        lButtons = llList2ListStrided(g_lActions, 0, -1, 2);
    }

    g_kMenuIDOther = Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth);
}


integer IsInteger(string sInput) { // For validating location scheme
    return ((string)((integer)sInput) == sInput);
}

ProcessCommand(key kID, string sCommand, integer iCommandType, string sParam1, string sParam2) {
    string sHelp = "[http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI RLVcmd Help]";
    g_kClicker = kID;
    integer iRandom = (integer)llFrand(300000.0);
    if (iCommandType == 0) {
        RLVCmd("@" + sCommand + "=" + (string)iRandom); // We have all we need for type 0
    } else if (iCommandType == 1) {
        RLVCmd("@" + sCommand + "=force"); // We have all we need for type 1
    } else if (iCommandType == 2) {
        if (sParam1) { // If we have param1, we're good, if not, pop up textbox
            RLVCmd("@" + sCommand + ":" + sParam1 + "=force");
            return;
        }

        g_kRLVTextboxCommand = Dialog(kID, "\n@" + sCommand + ":[option]=force\n\n"+ sHelp, [], [], 0, CMD_OWNER);
        g_lStoredCommand += (string)kID + "~" + sCommand + "~" + (string)iCommandType + "~" + sParam1 + "~" + sParam2;
    } else if (iCommandType == 3) {
        if (sParam1) { // If we have param1, we're good, if not, pop up textbox
            RLVCmd("@" + sCommand + ":" + sParam1 + "=" + (string)iRandom);
            return;
        }

        g_kRLVTextboxCommand = Dialog(kID, "\n@" + sCommand + ":[option]=force\n\n" + sHelp, [], [], 0, CMD_OWNER);
        g_lStoredCommand += (string)kID + "~" + sCommand + "~" + (string)iCommandType + "~" + sParam1 + "~" + sParam2;
    } else if (iCommandType == 4) {
        if ((sParam1 != "") && (sParam2 != "")) { // If we have param1&2, we're good, if not, pop up textbox
            RLVCmd("@" + sCommand + ":" + sParam1 + "=" + sParam2);
            return;
        }

        g_kRLVTextboxCommand = Dialog(kID, "\n@" + sCommand + ":[attachpt/option]=[y/n]\n\n" + sHelp + "\n(please enter two words separated by space)", [], [], 0, CMD_OWNER);
        g_lStoredCommand += (string)kID + "~" + sCommand + "~" + (string)iCommandType + "~" + sParam1 + "~" + sParam2;
    } else if (iCommandType == 5) {
        if ((sParam1 != "") && (sParam2 != "")) { // If we have param1&2, we're good, if not, pop up textbox
            RLVCmd("@" + sCommand + ":" + sParam1 + "=" + sParam2);
            return;
        }

        g_kRLVTextboxCommand = Dialog(kID, "\n@" + sCommand + ":[channel]=[y/n]\n\n" + sHelp + "\n(please enter two words separated by space)", [], [], 0, CMD_OWNER);
    } else if (iCommandType == 6) {
        if ((sParam1 != "") && (sParam2 != "")) { // If we have param1&2, we're good, if not, pop up textbox
            RLVCmd("@" + sCommand + ":" + sParam1 + "=" + sParam2);
            return;
        }

        g_kRLVTextboxCommand = Dialog(kID, "\n@" + sCommand + ":[params]=[y/n]\n\n" + sHelp + "\n(please enter two words separated by space)", [], [], 0, CMD_OWNER);
    } else if (iCommandType == 7) {
        if (sParam1) { // If we have param1, we're good, if not, pop up textbox
            RLVCmd("@" + sCommand + ":" + sParam1 + "=force");
            return;
        }

        g_kRLVTextboxCommand = Dialog(kID, "\n@" + sCommand + "=[y/n]\n\n" + sHelp, [], [], 0, CMD_OWNER);
        g_lStoredCommand += (string)kID + "~" + sCommand + "~" + (string)iCommandType + "~" + sParam1 + "~" + sParam2;
    }
}

//channel = 0 //force == 1 //option,force = 2 //option,channel = 3
//attachpt+option,n/y+force = 4 (detachme) //channel,n/y = 5 //params,add/rem = 6 //y/n = 7

RLVCmd(string sStr) {
    integer iStart;
    integer iEnd;
    string sCommand = sStr;
    if (llSubStringIndex(sStr, "=") >= 0) {
        iStart = llSubStringIndex(sStr, "=") + 1;
        if (llSubStringIndex(sStr, ";") >= 0) {
            iEnd = llSubStringIndex(sStr, ";") - 1;
        } else {
            iEnd = llStringLength(sStr);
        }
    }

    sStr = llGetSubString(sStr, iStart, iEnd);
    iStart = 0;
    iEnd = llStringLength(sStr) - 1;
    for(; iStart <= iEnd; ++iStart) { // Run through this number list to make sure each character is numeric
        if (IsInteger(llGetSubString(sStr, iStart, iStart)) != 1) {
            OutCommand(sCommand);
            return;
        } // Something left in here isn't an integer, send the full command
    }

    llSetTimerEvent(20);
    g_iListenerChannel = (integer)sStr;
    g_iListenerHandle = llListen(g_iListenerChannel, "", llGetOwner(), "");
    OutCommand(sCommand);
    g_lListeners += g_iListenerHandle;
}

OutCommand (string sCommand) {
    sCommand = llGetSubString(sCommand, 1, -1); // Strip off @
    llMessageLinked(LINK_RLV, RLV_CMD, sCommand, g_kClicker);
}

UserCommand(integer iAuth, string sStr, key kID, integer bRemenu) {
    if (iAuth != CMD_OWNER) {
        return;
    }

    sStr = llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 1); // RLV command
    string sParam1 = llList2String(lParams, 2); // Param 1
    string sParam2 = llList2String(lParams, 3); // Param 2
    string sMainButton = llToLower(g_sSubMenu);

    lParams = []; // Clean

    if ((g_bRLVOn == FALSE) && (llSubStringIndex(sStr, sMainButton) == 0)) {
        Notify(kID, "RLV is off in %WEARERNAME%'s %DEVICETYPE%.  Please enable RLV before using this plugin", FALSE);
        return;
    } else if (sStr == sMainButton || sStr == "menu " + sMainButton) {
        // An authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iAuth);
    } else if (sStr == sMainButton + " reset") {
        llResetScript();
    } else if ((llSubStringIndex(sStr, sMainButton) == 0) && (llGetSubString(sCommand, 0, 0) == "@"))  {
        //sStr = llStringTrim(llDeleteSubString(sStr, 0, llStringLength(sMainButton)), STRING_TRIM);
        //if (llSubStringIndex(sStr, "@") == 0) { // RLV commands need to start with @
        Notify(kID, "Sending RLV command " + sCommand + " to %WEARERNAME%'s %DEVICETYPE%", FALSE);
        g_lRLVCommandHistory += sStr;
        g_kClicker = kID;
        RLVCmd(sStr);
        //}
    } else if (llSubStringIndex(sStr, sMainButton) == 0) {
        integer iToken;
        if (llListFindList(g_lEnablements, [sCommand]) >= 0) {
            iToken = llListFindList(g_lEnablements, [sCommand]);
            ProcessCommand(kID, llList2String(g_lEnablements, iToken), 7, sParam1, sParam2);
            return;
        } else if (llListFindList(g_lChat, [sCommand]) >= 0) {
            iToken = llListFindList(g_lChat, [sCommand]);
            ProcessCommand(kID, llList2String(g_lChat, iToken), llList2Integer(g_lChat, iToken + 1), sParam1, sParam2);
            return;
        } else if (llListFindList(g_lGatherInfo, [sCommand]) >= 0) {
            iToken = llListFindList(g_lGatherInfo, [sCommand]);
            ProcessCommand(kID, llList2String(g_lGatherInfo, iToken), llList2Integer(g_lGatherInfo, iToken + 1), sParam1, sParam2);
            return;
        } else if (llListFindList(g_lWearables, [sCommand]) >= 0) {
            iToken = llListFindList(g_lWearables, [sCommand]);
            ProcessCommand(kID, llList2String(g_lWearables, iToken), llList2Integer(g_lWearables, iToken + 1), sParam1, sParam2);
            return;
        } else if (llListFindList(g_lActions, [sCommand]) >= 0) {
            iToken = llListFindList(g_lActions, [sCommand]);
            ProcessCommand(kID, llList2String(g_lActions, iToken), llList2Integer(g_lActions, iToken + 1), sParam1, sParam2);
            return;
        } else {
            Notify(kID, "Invalid command", FALSE);
        } // TODO - Use GETCOMMAND to match partial string
    }

    if (bRemenu) {
        DoMenu(kID, iAuth);
    }
}

string StringHistorySnippet() {
    string sPrompt;
    integer i;
    integer iLength = llGetListLength(g_lRLVCommandHistory) - 1;
    sPrompt = "\n[http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI RLVcmd Help]";
    if (iLength >= 0) {
        sPrompt += "  History:\n";
        for(i = iLength - 3; i <= iLength; ++i) {
            if (i >= 0) {
                sPrompt += (string)(i + 1) + ")" + llList2String(g_lRLVCommandHistory, i) + "\n";
            }
        }
    }
    return sPrompt;
}

default {
    state_entry() {
        g_kWearer = llGetOwner();
    }

    on_rez(integer iParam) {
        if (llGetOwner() != g_kWearer) {
            llResetScript();
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg) {
        if (iChannel == g_iExceptionsChannel) {
            g_lDisabled = [];
            list lStatus = llParseString2List(sMsg, ["/"], []);
            integer i = 0;
            integer iLength = llGetListLength(lStatus);
            for(; i < iLength; ++i) {
                if (llSubStringIndex(llList2String(lStatus, i), ":") < 0) { // It's a global disable
                    g_lDisabled += llList2List(lStatus, i, i);
                }
            }
            lStatus = [];
            DoMenuEnablements(g_kClicker, CMD_OWNER);
        } else if (iChannel == g_iListenerChannel) {
            Notify(g_kClicker, sMsg, FALSE);
        }
    }

    timer() { // Close all timers/listeners we may have opened up
        integer i;
        integer iLength = llGetListLength(g_lListeners);
        for(; i < iLength; ++i) {
            llListenRemove(llList2Integer(g_lListeners, i));
        }
        g_lListeners = [];
        g_lStoredCommand = [];
        llSetTimerEvent(0.0);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sStr, kID, FALSE);
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            // Our parent menu requested to receive buttons, so send ours
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        } else if (iNum == RLV_ON) {
            g_bRLVOn = TRUE;
        } else if (iNum == RLV_OFF) {
            g_bRLVOn = FALSE;
        } else if (iNum == RLVA_VERSION) {
            g_bRLVaOn = TRUE;
        } else if (iNum == CMD_SAFEWORD) {
            // Safeword has been received, release any restricitions that should be released
        } else if (iNum == DIALOG_RESPONSE) {
            list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0); // Avatar using the menu
            string sMessage = llList2String(lMenuParams, 1); // Button label
            //integer iPage = (integer)llList2String(lMenuParams, 2); // Menu page
            integer iAuth = (integer)llList2String(lMenuParams, 3); // Auth level of avatar

            if (kID == g_kMenuID) {
                if (sMessage == UPMENU) {
                    // Give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentMenu, kAv);
                } else if (sMessage == "CMD") {
                    g_kClicker = kAv;
                    g_kRLVCommand = Dialog(kAv, StringHistorySnippet(), [], [], 0, iAuth);
                } else if (sMessage == "History") {
                    Notify(kAv, "RLVcmd History: " + llDumpList2String(g_lRLVCommandHistory, ";"), FALSE);
                    DoMenu(kAv, iAuth);
                } else if (sMessage == "Enablements") {
                    llSetTimerEvent(20);
                    g_iListenerHandle = llListen(g_iExceptionsChannel, "", llGetOwner(), "");
                    OutCommand("@getstatusall" + "=" + (string)g_iExceptionsChannel);
                    g_lListeners += g_iListenerHandle;
                    g_kClicker = kAv;
                } else if ((sMessage == "GatherInfo") || (sMessage == "Wearables") || (sMessage == "Actions")) {
                    g_kClicker = kAv;
                    DoMenuOther(kAv, iAuth, sMessage);
                }
            } else if (kID == g_kRLVCommand) {
                if (sMessage == "") {
                    DoMenu(kAv, iAuth);
                } else if (llSubStringIndex(sMessage, "@") == 0)  {
                    sMessage = llStringTrim(sMessage, STRING_TRIM);
                    g_lRLVCommandHistory += [sMessage];
                    Notify(kAv, "Sending RLV command " + sMessage + " to %WEARERNAME%'s %DEVICETYPE%", FALSE);
                    g_kClicker = kAv;
                    RLVCmd(sMessage);
                    g_kRLVCommand = Dialog(kAv, StringHistorySnippet(), [], [], 0, iAuth);
                } else {
                    g_kRLVCommand = Dialog(kAv, StringHistorySnippet(), [], [], 0, iAuth);
                    Notify(kAv, "Invalid RLV command: " + sMessage, FALSE);
                }
            } else if (kID == g_kMenuIDEnablements) {
                if (sMessage == UPMENU) {
                    DoMenu(kAv, iAuth);
                } else {
                    g_kClicker = kAv;
                    string sCmdStr;
                    if (llSubStringIndex(sMessage, UNTICKED) >= 0) {
                        sCmdStr = llGetSubString(sMessage, llStringLength(UNTICKED), llStringLength(sMessage)) + "=n";
                    } else if (llSubStringIndex(sMessage, TICKED) >= 0) {
                        sCmdStr = llGetSubString(sMessage, llStringLength(TICKED), llStringLength(sMessage)) + "=y";
                    }
                    RLVCmd("@" + sCmdStr);
                    llSetTimerEvent(20);
                    g_iListenerHandle = llListen(g_iExceptionsChannel, "", llGetOwner(), "");
                    OutCommand("@getstatusall" + "=" + (string)g_iExceptionsChannel);
                    g_lListeners += g_iListenerHandle;
                }
            } else if (kID == g_kRLVTextboxCommand) {
                if ((sMessage == UPMENU) || (llStringTrim(sMessage, STRING_TRIM) == "")) {
                    DoMenu(kAv, iAuth);
                } else if (sMessage == "") {
                    DoMenu(kAv, iAuth);
                } else {
                    list lParams = llParseString2List(sMessage, [" "], []);
                    integer iLength = llGetListLength(g_lStoredCommand) - 1;
                    for(; iLength >= 0; --iLength) {
                        if (llSubStringIndex(llList2String(g_lStoredCommand, iLength), (string)kAv) >= 0) {
                            list lPieces = llParseStringKeepNulls(llList2String(g_lStoredCommand, iLength), ["~"], []);
                            ProcessCommand( //ProcessCommand(key kID,string sCommand,integer iCommandType,string sParam1,string sParam2) {
                                    llList2Key(lPieces, 0),
                                    llList2String(lPieces, 1),
                                    llList2Integer(lPieces, 2),
                                    llList2String(lParams, 0), // From our message box
                                    llList2String(lParams, 1)
                                    ); //
                            }
                        }

                        DoMenu(kAv, iAuth);
                    }
                } else if (kID == g_kMenuIDOther) {
                    if ((sMessage == UPMENU) || (llStringTrim(sMessage, STRING_TRIM) == "")) {
                        DoMenu(kAv, iAuth);
                    } else {
                        ProcessCommand(kAv, sMessage, FindCommandType(sMessage), "", "");
                    }
                }
            } else if (iNum == LINK_UPDATE) {
                if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
                else if (sStr == "LINK_RLV") LINK_RLV = iSender;
                else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
            } else if (iNum == REBOOT && sStr == "reboot") {
                llResetScript();
            }
        }
    }
