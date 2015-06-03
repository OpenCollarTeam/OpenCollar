////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - rlvex                                //
//                                 version 3.990                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

key g_kLMID;//store the request id here when we look up a LM
key g_kMenuID;
key g_kSensorMenuID;
key g_kPersonMenuID;
list g_lPersonMenu;
list g_lExMenus;
key lmkMenuID;
key g_kDialoger;
integer g_iDialogerAuth;
list g_lScan;
integer g_iRlvUnknown=TRUE;

list g_lOwners;
list g_lSecOwners;
list g_lTempOwners;

string g_sParentMenu = "RLV";
string g_sSubMenu = "Exceptions";

//statics to compare
integer OWNER_DEFAULT = 127;//1+2+4+8+16+32;//all on
integer TRUSTED_DEFAULT = 110;//all off


integer g_iOwnerDefault = 127;//1+2+4+8+16+32;//all on
integer g_iTrustedDefault = 110;//all off

string g_sLatestRLVersionSupport = "1.15.1"; //the version which brings the latest used feature to check against
string g_sDetectedRLVersion;
list g_lSettings;//2-strided list in form of [key, value]
//list g_lNames;


list g_lRLVcmds = [
    "sendim",  //1
    "recvim",  //2
    "recvchat", //4
    "recvemote", //8
    "tplure",   //16
    "accepttp",   //32
    "startim"   //64
        ];
        
list g_lBinCmds = [ //binary values for each item in g_lRLVcmds
    8,
    4,
    2,
    32,
    1,
    16,
    8
        ];

list g_lPrettyCmds = [ //showing menu-friendly command names for each item in g_lRLVcmds
    "IM",
    "RcvIM",
    "RcvChat",
    "RcvEmote",
    "Lure",
    "refuseTP"
        ];

list g_lDescriptionsOn = [ //showing descriptions for commands when exempted
    "Can send or start IMs even when blocked",
    "Can receive their IMs even when blocked",
    "Can see their Chat even when blocked",
    "Can see their Emotes even when blocked",
    "Can receive their Teleport offers even when blocked",
    "Wearer cannot refuse a tp offer from them"  //counter-intuitive, but other exceptions stop restrictions from working for subject, while this one adds its own restriction.
];
list g_lDescriptionsOff =[ //descriptions of commands when not exempted.
    "Sending and starting IMs to them can be blocked",
    "Receiving IMs from them can be blocked",
    "Seeing chat from them can be blocked",
    "Seeing emotes from them can be blocked",
    "Teleport offers from them can be blocked",
    "Wearer can refuse their tp offers"
        ];      

string TURNON = "☐";
string TURNOFF = "☒";
string DESTINATIONS = "Destinations";

integer g_iRLVOn=FALSE;
integer g_iAuth = 0;

key g_kWearer;
key g_kHTTPID = NULL_KEY;
key g_kTmpKey = NULL_KEY;
key g_kTestKey = NULL_KEY;
string g_sTmpName = "";
string g_sUserCommand = "";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510; 
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

//integer SEND_IM = 1000; deprecated. each script should send its own IMs now. This is to reduce even the tiny bt of lag caused by having IM slave descripts
//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//sStr must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
integer RLV_QUERY = 6102; //query from a script asking if RLV is currently functioning
integer RLV_RESPONSE = 6103;  //reply to RLV_QUERY, with "ON" or "OFF" as the message

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer FIND_AGENT = -9005;
string UPMENU = "BACK";

key REQUEST_KEY;
//string g_sScript;
string g_sSettingToken = "rlvex_";
//string g_sGlobalToken = "global_";

/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    //Debug("Made menu.");
    return kID;
}


Menu(key kID, string sWho, integer iAuth) {
    if (!g_iRLVOn) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"RLV features are now disabled in this %DEVICETYPE%. You can enable those in RLV submenu. Opening it now.",kID);
        llMessageLinked(LINK_SET, iAuth, "menu RLV", kID);
        return;
    }
    
    list lButtons = ["Owner", "Trusted"];
    string sPrompt = "\nSet exemptions to the restrictions for RLV commands. That means the people added here will not be blocked from talking to the wearer. Also the ability to make teleports happen instantly can be set here.\n\n(\"Force Teleports\" are already defaulted for owners.)";
    g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

ExMenu(key kID, string sWho, integer iAuth) {
    //Debug("ExMenu for :"+sWho);
    if (!g_iRLVOn) { 
        llMessageLinked(LINK_SET,NOTIFY,"0"+"RLV features are now disabled in this %DEVICETYPE%. You can enable those in RLV submenu. Opening it now.",kID);
        llMessageLinked(LINK_SET, iAuth, "menu RLV", kID);
        return;
    }
    integer iExSettings = 0;
    integer iInd;
    if (sWho == "owner" || ~llListFindList(g_lOwners, [sWho])) 
        iExSettings = g_iOwnerDefault;
    else if (sWho == "trusted" || ~llListFindList(g_lSecOwners, [sWho]))
        iExSettings = g_iTrustedDefault;
    if (~iInd = llListFindList(g_lSettings, [sWho])) // replace deefault with custom
        iExSettings = llList2Integer(g_lSettings, iInd + 1);

    string sPrompt = "\nCurrent Settings for "+sWho+": "+"\n";    
    list lButtons;
    integer n;
    integer iStop = llGetListLength(g_lPrettyCmds);
    for (n = 0; n < iStop; n++) {
        //see if there's a setting for this in the settings list
        string sPretty = llList2String(g_lPrettyCmds, n);
        if (iExSettings & llList2Integer(g_lBinCmds, n)) {
            lButtons += [TURNOFF + " " + sPretty];
            sPrompt += "\n" + llList2String(g_lDescriptionsOn,n)+".";
        } else {
            lButtons += [TURNON + " " + sPretty];
            sPrompt += "\n" + llList2String(g_lDescriptionsOff,n)+".";
        }
    }
    //give an Allow All button
    lButtons += ["All","None"];
    //Debug(sPrompt);
    //Debug((string)llStringLength(sPrompt));
    key kTmp = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
    g_lExMenus = [kTmp, sWho] + g_lExMenus;
}

UpdateSettings() {
    //for now just redirect
    SetAllExs("");
}

SaveDefaults() {
    // these are lists of rlv exceptions, not to be confused with auth_owner listings
    //save to DB
    if (OWNER_DEFAULT == g_iOwnerDefault && TRUSTED_DEFAULT == g_iTrustedDefault) {
        //Debug("Defaults");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "owner", "");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "trusted", "");
        return;
    }
    //Debug("ownerdef: " + (string)g_iOwnerDefault + "\nsecdef: " + (string)g_iTrustedDefault);
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "owner=" + (string)g_iOwnerDefault, "");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "trusted=" + (string)g_iTrustedDefault, "");
}
SaveSettings() {
    //save to local settings
    if (llGetListLength(g_lSettings))
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "List=" + llDumpList2String(g_lSettings, ","), "");
    else
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "List", "");
}

SetAllExs(string sVal) {
    if (!g_iRLVOn) return;

    integer iStop = llGetListLength(g_lRLVcmds);
    integer n;
    integer i;
    
    integer iLength = llGetListLength(g_lSecOwners);
    for (n = 0; n < iLength; n += 2) {
        list sCmd;
        string sTmpOwner = llList2String(g_lSecOwners, n);
        if (llListFindList(g_lSettings, [sTmpOwner]) == -1 && sTmpOwner!=g_kWearer) {
            for (i = 0; i<iStop; i++) {
                if (g_iTrustedDefault & llList2Integer(g_lBinCmds, i) ) sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=n"];
                else sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=y"];
            }
            string sStr = llDumpList2String(sCmd, ",");
            llMessageLinked(LINK_SET, RLV_CMD, sStr, "rlvex");
            // lets give rlvmain a break
            llSleep(0.2);
        }
    }
    
    iLength = llGetListLength(g_lOwners+g_lTempOwners);
    for (n = 0; n < iLength; n += 2) {
        list sCmd;
        string sTmpOwner = llList2String(g_lOwners+g_lTempOwners, n);
        if (llListFindList(g_lSettings, [sTmpOwner]) == -1 && sTmpOwner!=g_kWearer) {
            for (i = 0; i<iStop; i++) {
                if (g_iOwnerDefault & llList2Integer(g_lBinCmds, i) ) sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=n"];
                else sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=y"];
            }
            string sStr = llDumpList2String(sCmd, ",");
            llMessageLinked(LINK_SET, RLV_CMD, sStr, "rlvex");
            // lets give rlvmain a break
            llSleep(0.2);
        }
    }
        
    iLength = llGetListLength(g_lSettings);
    for (n = 0; n < iLength; n += 2) {
        list sCmd;
        string sTmpOwner = llList2String(g_lSettings, n);
        if(sTmpOwner!=g_kWearer) {
            integer iTmpOwner = llList2Integer(g_lSettings, n+1);
            for (i = 0; i<iStop; i++) {
                if (iTmpOwner & llList2Integer(g_lBinCmds, i) ) sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=n"];
                else sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=y"];
            }
            string sStr = llDumpList2String(sCmd, ",");
            llMessageLinked(LINK_SET, RLV_CMD, sStr, "rlvex");
        }
    }
}
ClearEx() {
    llMessageLinked(LINK_SET, RLV_CMD, "clear=startim:,clear=sendim:,clear=recvim:,clear=recvchat:,clear=recvemote:,clear=tplure:,clear=accepttp:", "rlvex");
}

integer UserCommand(integer iNum, string sStr, key kID) {
    if ((iNum >= CMD_OWNER) && (iNum <= CMD_EVERYONE)) {
        if (iNum != CMD_OWNER) {
            if (llToLower(sStr) == "ex" || llToLower(sStr) == "menu exceptions") {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
                llMessageLinked(LINK_SET, iNum, "menu rlv", kID);
            } return TRUE;
        }
    }
    if (iNum != CMD_OWNER) return FALSE; // Only Primary Owners
    if (sStr == "runaway") llResetScript();
    string sLower = llToLower(sStr);
    if (sLower == "ex" || sLower == "menu " + llToLower(g_sSubMenu)) {
        Menu(kID, "", iNum);
        jump UCDone;
    }
    list lParts = llParseString2List(sStr, [" "], []); // ex,add,first,last at most
    integer iInd = llGetListLength(lParts);
    if (iInd < 1 || iInd > 4 || llList2String(lParts, 0) != "ex") return FALSE;
    lParts = llDeleteSubList(lParts, 0, 0); // no longer need the "ex"
    iInd = llGetListLength(lParts);
    string sCom = llList2String(lParts, 0);
    if (iInd == 1) // handle requests 4 menus first
    {
        if (sCom == "owner") ExMenu(kID, "owner", iNum);
        else if (sCom == "trusted") ExMenu(kID, "trusted", iNum);
        if (!llSubStringIndex(sCom, ":")) jump UCDone;// not done if we received a 1-who 1-exception case
    }
    string sVal = llList2String(lParts, 1);
    // anything else should be <prefix>ex user:command=value & may be strided with commas
    // if user is unknown to us, we'll re-run undone commands after they are sucessfully added, to prevent errors
    lParts = llParseString2List(llList2String(lParts, 0), [":"], []);
    iInd = llGetListLength(lParts) - 1;
    list lCom;
    string sWho;
    integer bChange;
    integer iRLV;
    integer iBin;
    integer iSet;
    integer iN2K;
    integer iNames;
    integer iL = 0;
    integer iC = 0;
    for (; iL < iInd; iL += 2) { // cycle through users
        // Let's get a uuid to work with, if who is an avatar. This enables users to type in names OR keys for chat commands.
        sWho = llList2String(lParts, iL);
        string sWhoName;
        if ((key)sWho) sWhoName = "secondlife:///app/agent/"+sWho+"/about";
        else sWhoName = sWho;
        sLower = llToLower(sWho);
        // preventing from getting owners and trusted messed up in the "other" list
        if (~llListFindList(g_lOwners, [sWho])) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"You cannot set exceptions for "+sWhoName + " different from other Owners, unless you use terminal.",kID);
            jump nextwho;
        } else if (~llListFindList(g_lSecOwners, [sWho])) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"You cannot set exceptions for "+sWhoName + " different from other Trusted, unless you use terminal.",kID);
            jump nextwho;            
        }
        // okay, now we have a key for sWho (if avatar) & they are in g_lNames - this will deliver all settings to the right places
        g_sUserCommand = "";
        lCom = llParseString2List(llToLower(llList2String(lParts, iL + 1)), [","], []);
        sCom = llList2String(lCom, 0);
        if (llGetSubString(sCom, 0, 3) == "all=") {// should be the only entry for this Who if so
            lCom = []; // convert all rlvcmds to a strided list of "cmd1=x,cmd2=x" etc
            sVal = llGetSubString(sCom, 3, -1);
                lCom += [llList2String(g_lRLVcmds, iC) + sVal];
        }
        for (iC = 0; iC < llGetListLength(lCom); iC++) {// cycle through strided entries
            sCom = llList2String(lCom, iC);
            if (sCom == "clear") jump nextcom; // do we want anything here this is for excpetions
            if (~iNames = llSubStringIndex(sCom, "=")) {
                sVal = llGetSubString(sCom, iNames + 1, -1);
                sCom = llGetSubString(sCom, 0, iNames -1);
            }
            else sVal = "";
            if (sVal == "exempt" || sVal == "add") sVal = "n"; // conversions
            else if (sVal == "enforce" || sVal == "rem") sVal = "y";
            iRLV = llListFindList(g_lRLVcmds, [sCom]);
            if (iRLV == -1 && sCom != "defaults") jump nextcom; // invalid request
            iBin = llList2Integer(g_lBinCmds, iRLV);
            if (sWho == "owner") {
                if (sCom == "defaults") g_iOwnerDefault = OWNER_DEFAULT;
                else if (sVal == "n") g_iOwnerDefault = g_iOwnerDefault | iBin;
                else if (sVal == "y") g_iOwnerDefault = g_iOwnerDefault & ~iBin;
                bChange = bChange | 1;
                jump nextcom;
            }
            else if (sWho == "trusted") {
                if (sCom == "defaults") g_iTrustedDefault = TRUSTED_DEFAULT;
                else if (sVal == "n") g_iTrustedDefault = g_iTrustedDefault | iBin;
                else if (sVal == "y") g_iTrustedDefault = g_iTrustedDefault & ~iBin;
                bChange = bChange | 1;
                jump nextcom;
            }
            iNames = llListFindList(g_lSettings, [sWho]);
            if (sCom == "defaults") {
                if (~iNames) g_lSettings = llDeleteSubList(g_lSettings, iNames, iNames + 1);
                //if (~iNames = llListFindList(g_lNames, [sWho])) g_lNames = llDeleteSubList(g_lNames, iNames, iNames + 1);
                bChange = bChange | 2;
                jump nextcom;
            }
            if (~iNames) iSet = llList2Integer(g_lSettings, iNames + 1);
            else if (~llListFindList(g_lOwners, [sWho])) iSet = g_iOwnerDefault;
            else if (~llListFindList(g_lSecOwners, [sWho])) iSet = g_iTrustedDefault;
            else iSet = 0;
            if (sVal == "n") iSet = iSet | iBin;
            else if (sVal == "y") iSet = iSet & ~iBin;
            else jump nextcom; // invalid setting param
            if (~iNames) g_lSettings = llListReplaceList(g_lSettings, [iSet], iNames + 1, iNames + 1);
            else g_lSettings += [sWho, iSet];
            bChange = bChange | 2;
            @nextcom;
           // Debug("processed " + sWho + ":" + sCom + "=" + sVal);
        }
        @nextwho;
        if (bChange) {
            UpdateSettings();
            if(bChange & 1) SaveDefaults();
            if(bChange & 2) SaveSettings();
        }
    }
    @UCDone;
    return TRUE;
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        llSetMemoryLimit(49152); 
        //g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        g_kTmpKey = NULL_KEY;
        g_sTmpName = "";
        llMessageLinked(LINK_SET, RLV_QUERY, "", "");
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == LM_SETTING_RESPONSE) {
            //this is tricky since our stored value contains equals signs
            //split string on both comma and equals sign
            //first see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "owner") g_iOwnerDefault = (integer)sValue;
                else if (sToken == "trusted") g_iTrustedDefault = (integer)sValue;
            }
            else if (sToken == "auth_owner") g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_trust") g_lSecOwners = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_tempowner") g_lTempOwners = llParseString2List(sValue, [","], []);
            else if (sToken == "settings") {
                if (sValue == "sent") SetAllExs("");//sendcommands
            }
        } else if (iNum == LM_SETTING_DELETE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            if (sToken == "auth_owner") {
                g_lOwners = [];
                ClearEx();
                UpdateSettings();
            } else if (sToken == "auth_trust") {
                g_lSecOwners = [];
                //send accepttp command
                ClearEx();
                UpdateSettings();
            } else if (sToken == "auth_tempowner") {
                g_lTempOwners = [];
                //send accepttp command
                ClearEx();
                UpdateSettings();
            }
        } else if (iNum == LM_SETTING_SAVE) {
            //handle saving new owner here
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            //does soemthing here need to change?
            if (sToken == "auth_owner") {
                g_lOwners = llParseString2List(sValue, [","], []);
                ClearEx();
                UpdateSettings();
            } else if (sToken == "auth_trust") {
                g_lSecOwners = llParseString2List(sValue, [","], []);
                //send accepttp command
                ClearEx();
                UpdateSettings();
            } else if (sToken == "auth_tempowner") {
                g_lTempOwners = llParseString2List(sValue, [","], []);
                //send accepttp command
                ClearEx();
                UpdateSettings();
            }
        } else if (iNum == RLV_REFRESH) {
            //rlvmain just started up. Tell it about our current restrictions
            g_iRLVOn = TRUE;
            UpdateSettings();
        } else if (iNum == RLV_RESPONSE) {
            if (g_iRlvUnknown) {
                g_iRlvUnknown=FALSE;
                if (sStr=="ON") g_iRLVOn=TRUE;
                else if (sStr=="OFF") g_iRLVOn=FALSE;
            }
        } else if (iNum == RLV_CLEAR) {
            //clear db and local settings list
            //ClearSettings();
            //do we not want to reset it?
            llSleep(2.0);
            UpdateSettings();
        } else if (iNum == RLV_VERSION) {
            g_sDetectedRLVersion = sStr;
        } else if (iNum == RLV_OFF) { // rlvoff -> we have to turn the menu off too
            g_iRLVOn=FALSE;
        } else if (iNum == RLV_ON) {
            g_iRLVOn=TRUE;
            UpdateSettings();//send the settings as we did notbefore
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kMenuID) {
                //Debug("dialog response: " + sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //if we got *Back*, then request submenu RLV
                if (sMessage == UPMENU)
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                else if (sMessage == "Owner")
                    ExMenu(kAv, "owner", iAuth);  //give menu for owners defaults
                else if (sMessage == "Trusted")
                    ExMenu(kAv, "trusted", iAuth); //give menu for secowners defaults
            } else if (llListFindList(g_lExMenus, [kID]) != -1 ) {
                //Debug("dialog response: " + sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                integer iMenuIndex = llListFindList(g_lExMenus, [kID]);
                if (sMessage == UPMENU) Menu(kAv,"", iAuth);
                else {  // clear out Tmp settings
                    g_kTmpKey = NULL_KEY;
                    g_sTmpName = g_sUserCommand = "";
                    string sMenu = llList2String(g_lExMenus, iMenuIndex + 1);
                    //we got a command to enable or disable something, like "Enable LM"
                    //get the actual command same by looking up the pretty name from the message
                    list lParams = llParseString2List(sMessage, [" "], []);
                    string sSwitch = llList2String(lParams, 0);
                    string sCmd = llList2String(lParams, 1);
                    string sOut = "ex " + sMenu + ":";
                    integer iIndex = llListFindList(g_lPrettyCmds, [sCmd]);
                    if (sSwitch == "All") {
                        sOut += "all=n";
                        UserCommand(iAuth, sOut, kAv);
                        ExMenu(kAv, sMenu, iAuth);
                    } else if (sSwitch == "None") {
                        sOut += "all=y";
                        UserCommand(iAuth, sOut, kAv);
                        ExMenu(kAv, sMenu, iAuth);
                    } else if (~iIndex) {
                        sOut += llList2String(g_lRLVcmds, iIndex);
                        if (sSwitch == TURNOFF) sOut += "=y"; // exempt
                        else if (sSwitch == TURNON) sOut += "=n"; // enforce
                        //send rlv command out through auth system as though it were a chat command, just to make sure person who said it has proper authority
                        //Debug("ExMenu sending UC: " + sOut);
                        UserCommand(iAuth, sOut, kAv);
                        ExMenu(kAv, sMenu, iAuth);
                    } else if (sMessage == "Defaults") {
                        UserCommand(iAuth, sOut + "defaults", kAv);
                        ExMenu(kAv, sMenu, iAuth);
                    }// else
                        //something went horribly wrong. We got a command that we can't find in the list
                    llDeleteSubList(g_lExMenus, iMenuIndex, iMenuIndex + 1);
                }
            }
        }
    }
/*
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/
}
