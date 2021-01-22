// This file is part of OpenCollar.
// Copyright (c) 2008 - 2016 Nandana Singh, Lulu Pink, Garvin Twine,    
// Joy Stipe, Cleo Collins, Satomi Ahn, Master Starship, Toy Wylie,    
// Kaori Gray, Sei Lisa, Wendy Starfall, littlemousy, Romka Swallowtail,  
// Sumi Perl, Karo Weirsider, Kurt Burleigh, Marissa Mistwallow et al.   
// Licensed under the GPLv2.  See LICENSE for full details. 
string g_sScriptVersion = "8.0";
integer LINK_CMD_DEBUG=1999;

// ------ TOKEN DEFINITIONS ------
// ---- Immutable ----
// - Should be constant across collars, so not prefixed
// --- db tokens ---
string TOK_LENGTH   = "leashlength";
string TOK_DEST     = "leashedto"; // format: uuid,rank
// --- channel tokens ---

//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;
 
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;
integer CMD_NOACCESS = 599;

integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;
integer NOTIFY                = 1002;
//integer SAY                   = 1004;
integer REBOOT                = -1000;
integer LM_SETTING_SAVE       = 2000;
integer LM_SETTING_REQUEST    = 2001;
integer LM_SETTING_RESPONSE   = 2002;
integer LM_SETTING_DELETE     = 2003;
integer LM_SETTING_EMPTY            = 2004;

// -- MENU/DIALOG
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
//integer MENUNAME_REMOVE     = 3003;

integer RLV_CMD = 6000;

integer RLV_OFF = 6100;
integer RLV_ON = 6101;

integer LEASH_START_MOVEMENT = 6200;
integer LEASH_END_MOVEMENT = 6201;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;
integer SENSORDIALOG = -9003;

integer CMD_PARTICLE     = 20000;
//integer CMD_LEASH_SENSOR = 20001;

// --- menu button tokens ---
string BUTTON_UPMENU       = "BACK";
string BUTTON_PARENTMENU   = "Main";
string BUTTON_SUBMENU      = "Leash";

// ---------------------------------------------
// ------ VARIABLE DEFINITIONS ------
// ----- menu -----
list     g_lMenuIDs;
integer g_iMenuStride = 3;
integer g_iPreviousAuth;
key g_kLeashCmderID;

list g_lButtons;
// ----- collar -----

key g_kWearer;
integer g_iJustMoved;
// ----- leash -----
integer g_iLength = 3;
integer g_iStay = FALSE;
integer g_iTargetHandle;
integer g_iLastRank;
integer g_iStayRank;
integer g_iStrictRank;
vector g_vPos = ZERO_VECTOR;
key g_kCmdGiver;
key g_kLeashedTo = NULL_KEY;
string g_sLeashedToName = "(none)";
integer g_bLeashedToAvi;
integer g_bFollowMode;
string g_sSettingToken = "leash_";
//string g_sGlobalToken = "global_";

integer g_iPassConfirmed;
integer g_iRezAuth;

string g_sCheck;

//realleash variables
integer g_iStrictModeOn=FALSE; //default is Real-Leash OFF
integer g_iTurnModeOn = FALSE;
integer g_iLeasherInRange=FALSE; //
integer g_iRLVOn=FALSE;     // To store if RLV was enabled in the collar
integer g_iAwayCounter=0;



string g_sLeashHolder="na"; // Leash holder item name
// ---------------------------------------------
// ------ FUNCTION DEFINITIONS ------

/*
integer g_iProfiled=TRUE;
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

string NameURI(key kID){
    if (llGetAgentSize(kID))
        return "secondlife:///app/agent/"+(string)kID+"/about";
    else
        return "secondlife:///app/objectim/"+(string)kID+"/?name="+llEscapeURL(llKey2Name(kID))+"&owner="+(string)llGetOwnerKey(kID);
}

Dialog(key kRCPT, string sPrompt, list lButtons, list lUtilityButtons, integer iPage, integer iAuth, string sMenuID) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lButtons, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuID], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuID];
}

SensorDialog(key kRCPT, string sPrompt, string sSearchName, integer iAuth, string sMenuID, integer iSensorType) {
    key kMenuID = llGenerateKey();
    if (sSearchName != "") sSearchName = "`"+sSearchName+"`1";
    llMessageLinked(LINK_SET, SENSORDIALOG, (string)kRCPT +"|"+sPrompt+"|0|``"+(string)iSensorType+"`10`"+(string)PI+sSearchName+"|"+BUTTON_UPMENU+"|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuID], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuID];
}

ConfirmDialog(key kAv, key kCmdGiver, string sType, integer iAuth) {
    if ((string)kAv == BUTTON_UPMENU) {
        UserCommand(iAuth, "leashmenu", kCmdGiver ,TRUE);
        return;
    }
    string sCmdGiverURI = NameURI(kCmdGiver);
    string sPrompt;
    string sMessage;
    if (kCmdGiver == g_kWearer) sPrompt = "\n%WEARERNAME% wants to ";
    else sPrompt = "\n"+sCmdGiverURI + " wants to ";
    if (sType == "LeashTarget") {
        sMessage = "Asking "+NameURI(kAv)+" to accept %WEARERNAME%'s leash.";
        if (kCmdGiver == g_kWearer) sPrompt += "pass you their leash.";
        else sPrompt += "pass you %WEARERNAME%'s leash.";
        sPrompt += "\n\nAre you OK with this?";
        
        Dialog(kAv,sPrompt,["Yes","No"],[],0,iAuth,"LeashTargetConfirm");
    } else {
        sMessage = "Asking "+NameURI(kAv)+" to accept %WEARERNAME% to follow them.";
        if (kCmdGiver == g_kWearer) sPrompt += "follow you.";
        else sPrompt += " command %WEARERNAME% to follow you.";
        sPrompt += "\n\nAre you OK with this?";
        Dialog(kAv,sPrompt,["Yes","No"],[],0,iAuth,"FollowTargetConfirm");
    }
    llMessageLinked(LINK_SET,NOTIFY,"0"+sMessage,kCmdGiver);
}

integer CheckCommandAuth(key kCmdGiver, integer iAuth) {
    // Check for invalid auth
    if (iAuth < CMD_OWNER || iAuth > CMD_EVERYONE) return FALSE;
    // If leashed, only move leash if Comm Giver outranks current leasher
    if (g_kLeashedTo != NULL_KEY && iAuth > g_iLastRank){
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to leash",kCmdGiver);
        return FALSE;
    }
    return TRUE;
}

SetLength(integer iIn) {
    g_iLength = iIn;
    // llTarget needs to be changed to the new length if leashed
    if (g_kLeashedTo) {
        llTargetRemove(g_iTargetHandle);
        g_iTargetHandle = llTarget(g_vPos, g_iLength);
    }
}

ApplyRestrictions() {
    //Debug("Applying Restrictions");
    if (g_iLeasherInRange) {
        if (g_iStrictModeOn) {
            if (g_kLeashedTo) {
                //Debug("Setting restrictions");
                //llSay(0, "RLV_CMD issue: no fly, notp");
                llMessageLinked(LINK_SET, RLV_CMD, "fly=n,tplm=n,tplure=n,tploc=n,tplure:" + (string) g_kLeashedTo + "=add,fartouch=n,sittp=n", "realleash");     //set all restrictions
                return;
                
            }
        //} else {
            //Debug("Strict is off");
        }
    //} else {
        //Debug("Leasher out of range");
    }
    //Debug("Releasing restrictions");
    llMessageLinked(LINK_SET, RLV_CMD, "clear", "realleash");     //release all restrictions
}
key g_kPassLeashFrom;
list g_lPasslPoints;
// Wrapper for DoLeash with notifications
integer LeashTo(key kTarget, key kCmdGiver, integer iAuth, list lPoints, integer iFollowMode, integer iPreviousAuthority ){
    // can't leash wearer to self.
    if (kTarget == g_kWearer) return FALSE;
    if (!g_iPassConfirmed) {
        g_kLeashCmderID = kCmdGiver;
        if (iFollowMode) {
            ConfirmDialog(kTarget, kCmdGiver, "FollowTarget", iAuth);
        } else {
            ConfirmDialog(kTarget, kCmdGiver, "LeashTarget", iAuth);
        }
        return FALSE;
    }
    if(iPreviousAuthority==0)iPreviousAuthority=iAuth;
    if (!CheckCommandAuth(kCmdGiver, iPreviousAuthority)) return FALSE; // If this is not a pass, it expects iAuth == iPreviousAuthority
    //if (g_kLeashedTo==kTarget) return TRUE;
    if (g_kLeashedTo) DoUnleash(TRUE);

    integer bCmdGiverIsAvi=llGetAgentSize(kCmdGiver) != ZERO_VECTOR;
    integer bTargetIsAvi=llGetAgentSize(kTarget) != ZERO_VECTOR;
    
    // Send notices to wearer, leasher, and target
    // Only send notices if Leasher is an AV, as objects normally handle their own messages for such things
    if (bCmdGiverIsAvi) {
        string sTarget = NameURI(kTarget);
        string sCmdGiver = NameURI(kCmdGiver);
        string sWearMess;
        if (kCmdGiver == g_kWearer) {// Wearer is Leasher
            if (iFollowMode){
                sWearMess = "You begin following " + sTarget + ".";
            } else {
                //sCmdMess = ""; // Only one message will need to be sent
                sWearMess = "You take your leash";
                if (bTargetIsAvi) // leashing self to someone else
                    sWearMess += ", and hand it to " + sTarget + ".";
                else // leashing self to an object
                    sWearMess += ", and tie it to " + sTarget + ".";
            }
        } else {// Leasher is not Wearer
            string sCmdMess;
            if (iFollowMode){
                if (kCmdGiver != kTarget) { // LeashTo someone else
                    llMessageLinked(LINK_SET,NOTIFY,"0"+sCmdGiver+" command %WEARERNAME% to follow you.",kTarget);
                    sCmdMess= "You command %WEARERNAME% to follow " + sTarget + ".";
                    sWearMess = sCmdGiver + " commands you to follow " + sTarget + ".";
                } else {
                    sCmdMess= "You command %WEARERNAME% to follow you.";
                    sWearMess = sCmdGiver + " commands you to follow them.";
                }
            } else {
                sCmdMess= "You grab %WEARERNAME%'s leash";
                sWearMess = sCmdGiver + " grabs your leash";
                if (kCmdGiver != kTarget) { // Leasher is not LeashTo
                    if (bTargetIsAvi) { // LeashTo someone else
                        sCmdMess += ", and hand it to " + sTarget + ".";
                        sWearMess += ", and hands it to " + sTarget + ".";
                        llMessageLinked(LINK_SET,NOTIFY,"0"+sCmdGiver+" hands you %WEARERNAME%'s leash.",kTarget);
                    } else {// LeashTo object
                        sCmdMess += ", and tie it to " + sTarget + ".";
                        sWearMess += ", and ties it to " + sTarget + ".";
                    }
                }
            }
            llMessageLinked(LINK_SET,NOTIFY,"0"+sCmdMess,kCmdGiver);
        }
        llMessageLinked(LINK_SET,NOTIFY,"0"+sWearMess,g_kWearer);
    }
    g_bFollowMode = iFollowMode; // leashing, or following
    if (bTargetIsAvi) g_bLeashedToAvi = TRUE;
    if (llGetOwnerKey(kCmdGiver)==g_kWearer) iAuth=CMD_WEARER;   //prevents owner-wearer with public access creating an unbreakable leash to an unwilling participant
    DoLeash(kTarget, iAuth, lPoints,TRUE);
    g_iPassConfirmed = FALSE;
    // Notify Target how to unleash, only if:
    // Avatar
    // Didn't send the command
    // Don't own the object that sent the command
    if (g_bLeashedToAvi && kCmdGiver != kTarget && llGetOwnerKey(kCmdGiver) != kTarget) {
        if (iFollowMode){
            llMessageLinked(LINK_SET,NOTIFY, "0"+"%WEARERNAME% has been commanded to follow you. Say \"/%CHANNEL% %PREFIX% unfollow\" to release them.", g_kLeashedTo);
        } else {
            llMessageLinked(LINK_SET,NOTIFY, "0"+"%WEARERNAME% has been leashed to you. Say \"/%CHANNEL% %PREFIX% unleash\" to unleash them.", g_kLeashedTo);
        }
    }
    return TRUE;
}

DoLeash(key kTarget, integer iAuth, list lPoints, integer bSave) {
    g_iLastRank = iAuth;
    g_kLeashedTo = kTarget;
    dtext("func: doleash\n"+llDumpList2String([kTarget,iAuth,bSave]+llDumpList2String(lPoints,", "),"\n"));
    if (g_bFollowMode)
        llMessageLinked(LINK_SET, CMD_PARTICLE, "unleash", g_kLeashedTo);
    else {
        integer iPointCount = llGetListLength(lPoints);
        g_sCheck = "";
        if (iPointCount) {//if more than one leashpoint, listen for all strings, else listen just for that point
            if (iPointCount == 1) g_sCheck = (string)llGetOwnerKey(kTarget) + llList2String(lPoints, 0) + " ok";
        }
        //Send link message to the particle script
        //Debug("leashing with "+g_sCheck);
        llMessageLinked(LINK_SET, CMD_PARTICLE, "leash" + g_sCheck + "|" + (string)g_bLeashedToAvi, g_kLeashedTo);
    }
    llSetTimerEvent(3.0);   //check for leasher out of range
    
    // change to llTarget events by Lulu Pink
    g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]), 0);
    //to prevent multiple target events and llMoveToTargets
    llTargetRemove(g_iTargetHandle);
    llStopMoveToTarget();
    g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
    if (g_vPos != ZERO_VECTOR) {
        llMoveToTarget(g_vPos, 0.7);
    }
    if(bSave){
        g_sLeashedToName = llList2String(llGetObjectDetails(kTarget, [OBJECT_NAME]),0);
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + TOK_DEST + "name=" + g_sLeashedToName , "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + TOK_DEST + "=" + (string)kTarget + "," + (string)iAuth + "," + (string)g_bLeashedToAvi + "," + (string)g_bFollowMode, "");
    }
    
    g_iLeasherInRange=TRUE;
    ApplyRestrictions();
}

// Wrapper for DoUnleash()
Unleash(key kCmdGiver) {
    string sTarget = g_sLeashedToName; // names were not showing if the person was off sim. Lets make this more reliable!
    if ( (key)g_kLeashedTo ) {
        string sCmdGiver = NameURI(kCmdGiver);
        string sWearMess;
        string sCmdMess;
        string sTargetMess;
        integer bCmdGiverIsAvi=llGetAgentSize(kCmdGiver) != ZERO_VECTOR;
        if (bCmdGiverIsAvi) {
            g_bLeashedToAvi = llGetAgentSize(g_kLeashedTo) != ZERO_VECTOR; //refresh to check if the leash target is in sim, no need to spam else
            if (kCmdGiver == g_kWearer) { // Wearer is Leasher
                if (g_bFollowMode) {
                    sWearMess = "You stop following " + sTarget + ".";
                    sTargetMess = "%WEARERNAME% stops following you.";
                } else {
                    sWearMess = "You unleash yourself from " + sTarget + "."; // sTarget might be an object
                    sTargetMess = "%WEARERNAME% unleashes from you.";
                }
                if (g_bLeashedToAvi) llMessageLinked(LINK_SET,NOTIFY,"0"+sTargetMess,g_kLeashedTo);
            } else { // Unleasher is not Wearer
                if (kCmdGiver == g_kLeashedTo) {
                    if (g_bFollowMode) {
                        sCmdMess= "You release %WEARERNAME% from following you.";
                        sWearMess = sCmdGiver + " releases you from following.";
                    } else {
                        sCmdMess= "You unleash %WEARERNAME%.";
                        sWearMess = sCmdGiver + " unleashes you.";
                    }
                } else {
                    if (g_bFollowMode) {
                        sCmdMess= "You release %WEARERNAME% from following " + sTarget + ".";
                        sWearMess = sCmdGiver + " releases you from following " + sTarget + ".";
                        sTargetMess = "%WEARERNAME% stops following you.";
                    } else {
                        sCmdMess= "You unleash %WEARERNAME% from " + sTarget + ".";
                        sWearMess = sCmdGiver + " unleashes you from " + sTarget + ".";
                        sTargetMess = sCmdGiver + " unleashes %WEARERNAME% from you.";
                    }
                    if (g_bLeashedToAvi) llMessageLinked(LINK_SET,NOTIFY,"0"+sTargetMess,g_kLeashedTo);
                }
                llMessageLinked(LINK_SET,NOTIFY,"0"+sCmdMess,kCmdGiver);
            }
            llMessageLinked(LINK_SET,NOTIFY,"0"+sWearMess,g_kWearer);
        }
        DoUnleash(TRUE);
    } //else
       // llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% is not leashed.",kCmdGiver);
}

DoUnleash(integer iDelSettings) {
    dtext("func : dounleash\n"+(string)iDelSettings);
    llTargetRemove(g_iTargetHandle);
    llStopMoveToTarget();
    llMessageLinked(LINK_SET, CMD_PARTICLE, "unleash", g_kLeashedTo);
    g_kLeashedTo = NULL_KEY;
    g_iLastRank = CMD_NOACCESS;
    if (iDelSettings){
        g_sLeashedToName = "(none)";
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + TOK_DEST+"name","");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + TOK_DEST, "");
    }
    llSetTimerEvent(0.0);   //stop checking for leasher out of range
    g_iLeasherInRange=FALSE;
    ApplyRestrictions();
}

YankTo(key kIn){
    llMoveToTarget(llList2Vector(llGetObjectDetails(kIn, [OBJECT_POS]), 0), 0.5);
    if (llGetAgentInfo(g_kWearer)&AGENT_SITTING) llMessageLinked(LINK_SET, RLV_CMD, "unsit=force", "");
    llSleep(2.0);
    llStopMoveToTarget();
}

UserCommand(integer iAuth, string sMessage, key kMessageID, integer bFromMenu) {
    //llSay(0, sMessage+" ["+(string)kMessageID+"]");
    //Debug("Got user comand:\niAuth: "+(string)iAuth+"\nsMessage: "+sMessage+"\nkMessageID: "+(string)kMessageID+"\nbFromMenu: "+(string)bFromMenu);
    if (iAuth == CMD_NOACCESS) {
        if (kMessageID == g_kLeashedTo) {
            sMessage = llToLower(sMessage);
            if (sMessage == "unleash" || sMessage == "unfollow" || (sMessage == "toggleleash" && NULL_KEY != g_kLeashedTo)) Unleash(kMessageID);
            else if (sMessage == "yank") YankTo(kMessageID);
        }
    } else { //(iAuth >= CMD_OWNER && iAuth <= CMD_EVERYONE ) ~ For reference.. the levels were messed up in oc_auth.. it assigned public to CMD_GROUP
        g_kCmdGiver = kMessageID;
        list lParam = llParseString2List(sMessage, [" "], []);
        string sComm = llToLower(llList2String(lParam, 0));
        string sVal = llToLower(llList2String(lParam, 1));

        sMessage = llToLower(sMessage);  //convert sMessage to lower case for caseless comparisson
        //debug(sMessage);
        if (sMessage=="leashmenu" || sMessage == "menu leash"){
            if(g_sLeashHolder=="na")LHSearch(); // Try to find the leash holder before showing the menu if leash holder was not found at init.
            list lButtons;
            if (kMessageID != g_kWearer) lButtons += "Grab";// Only if not the wearer.
            else lButtons += ["-"];
            if (g_kLeashedTo != NULL_KEY) {
                if (g_bFollowMode) lButtons += ["Unfollow"];
                else lButtons += ["Unleash"];
            }
            else lButtons += "-";
            if (kMessageID == g_kLeashedTo) lButtons += "Yank";//only if leash holder
            else lButtons += "-";
            lButtons += ["Follow"];
            lButtons += ["Anchor","Pass"];
            lButtons += ["Length"];
            if(g_sLeashHolder!="na")
                lButtons += ["Give Holder"];
            lButtons += g_lButtons;

            string sPrompt = "\n[Leash]\n";
            if (g_kLeashedTo) {
                if (g_bFollowMode) sPrompt += "\nFollowing: ";
                else sPrompt += "\nLeashed to: ";
                sPrompt += NameURI(g_kLeashedTo);
            } else if (!g_iStay) sPrompt += "\n%WEARERNAME% can move freely.";
            if (g_iStay) sPrompt += "\n%WEARERNAME% can't move on their own.";
            Dialog(kMessageID, sPrompt, lButtons, [BUTTON_UPMENU], 0, iAuth, "MainDialog");
        } else  if (sComm == "post") {
            if (sVal==llToLower(BUTTON_UPMENU)) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
        } else  if (sMessage == "grab" || sMessage == "leash" || (sMessage == "toggleleash" && NULL_KEY == g_kLeashedTo)) {
            g_iPassConfirmed = TRUE;
            LeashTo(kMessageID, kMessageID, iAuth, ["handle"], FALSE, 0);
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
        } else if(sComm == "follow" || sComm == "followtarget") {
            //Debug("Got a follow command:"+sMessage);
            if (!CheckCommandAuth(kMessageID, iAuth)) return;
            if (sVal==llToLower(BUTTON_UPMENU))
                UserCommand(iAuth, "leash", kMessageID ,bFromMenu);
            else if (sVal == "me") {
                g_iPassConfirmed = TRUE;
                g_kPassLeashFrom = kMessageID;
                g_lPasslPoints=[];
                g_iPreviousAuth=iAuth;
                llMessageLinked(LINK_SET,AUTH_REQUEST, "followPass", kMessageID);
                //LeashTo(kMessageID, kMessageID, iAuth, [], TRUE,0);
            } else if ((key)sVal) {
                g_iPassConfirmed = TRUE;
                g_kPassLeashFrom = kMessageID;
                g_lPasslPoints=[];
                g_iPreviousAuth=iAuth;
                llMessageLinked(LINK_SET,AUTH_REQUEST, "followPass", sVal);
                //LeashTo((key)sVal, kMessageID, iAuth, [], TRUE,0);
            } else
                SensorDialog(g_kCmdGiver, "\nWho shall be followed?\n", sVal,iAuth,"FollowTarget", AGENT);
        } else if (sMessage == "runaway" && iAuth == CMD_OWNER) {
            Unleash(kMessageID);
        } else if (sMessage == "unleash" || sMessage == "unfollow" || (sMessage == "toggleleash" && NULL_KEY != g_kLeashedTo)) {
            if (CheckCommandAuth(kMessageID, iAuth)) Unleash(kMessageID);
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
        } else if (sMessage == "yank" && kMessageID == g_kLeashedTo) {
            //Person holding the leash can yank.
            if(llGetAgentInfo(g_kWearer)&AGENT_SITTING) llMessageLinked(LINK_SET, RLV_CMD, "unsit=force", "realleash");
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            YankTo(kMessageID);
        } else if (sMessage == "beckon" && iAuth == CMD_OWNER) YankTo(kMessageID);
        else if (sMessage == "stay") {
            if (iAuth <= CMD_GROUP) {
                g_iStayRank = iAuth;
                g_iStay = TRUE;
                string sCmdGiver = NameURI(kMessageID);
                llRequestPermissions(g_kWearer, PERMISSION_TAKE_CONTROLS);
                llMessageLinked(LINK_SET,NOTIFY,"0"+sCmdGiver + " commands you to stay in place. You can't move on your own now!",g_kWearer);
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Yay! %WEARERNAME% can't move on their own now! Cast a leash to pull them along or type \"/%CHANNEL% %PREFIX% move\" if you change your mind.",kMessageID);
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            }
        } else if ((sMessage == "unstay" || sMessage == "move") && g_iStay) {
            if (iAuth <= g_iStayRank) {
                g_iStay = FALSE;
                llReleaseControls();
                llMessageLinked(LINK_SET,NOTIFY,"0"+"You are free to move again.",g_kWearer);
                llMessageLinked(LINK_SET,NOTIFY,"0"+"You allowed %WEARERNAME% to move freely again.",kMessageID);
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            }
        } else if (sMessage == "strict on") {
            if (g_iStrictModeOn) llMessageLinked(LINK_SET,NOTIFY,"0"+"Strict leashing is already enabled.",kMessageID);
            else {
                g_iStrictRank = iAuth;
                g_iStrictModeOn=TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "strict=1,"+ (string)iAuth, "");
                //llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "strict=1,"+ (string)iAuth, kMessageID);
                llMessageLinked(LINK_SET, LM_SETTING_REQUEST, TOK_DEST, "");  //query current leasher, the response will trigger ApplyRestrictions
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Strict leashing enabled.",kMessageID);
                ApplyRestrictions();
            }
        } else if (sMessage == "strict off") {
            if (iAuth <= g_iStrictRank) {
                g_iStrictModeOn=FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "strict", "");
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "strict=0,"+ (string)iAuth,kMessageID);
                ApplyRestrictions();
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Strict leashing disabled.",kMessageID);
            } else {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to strict leash",kMessageID);
            }
        } else if (sMessage == "turn on") {
            g_iTurnModeOn=TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "turn=1", "");
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "turn=1", "");
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Turning towards leasher enabled.",kMessageID);
        } else if (sMessage == "turn off") {
            g_iTurnModeOn=FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "turn", "");
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "turn=0,"+ (string)iAuth,kMessageID);
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Turning towards leasher disabled.",kMessageID);
        } else if (sComm == "pass") {
            if (!CheckCommandAuth(kMessageID, iAuth)) return;
            if (sVal==llToLower(BUTTON_UPMENU))
                UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            else if((key)sVal) {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                g_kPassLeashFrom = kMessageID;
                g_lPasslPoints = lPoints;
                g_iPreviousAuth=iAuth;
                //debug("leash target is key");//could be a post, or could be we specified an av key
                llMessageLinked(LINK_SET, AUTH_REQUEST, "passLeash", sVal); // All this does, is recalculate the authorization level of the leash so that the leash holder has proper permissions and could unleash it themselves if they wanted to.
//                LeashTo((key)sVal, kMessageID, iAuth, lPoints, FALSE);
            } else
                SensorDialog(g_kCmdGiver, "\nWho shall we pass the leash?\n", sVal,iAuth,"LeashTarget", AGENT);
        } else if (sComm == "length") {
            if(!CheckCommandAuth(kMessageID,iAuth)){
                return;
            }
            integer iNewLength = (integer)sVal;
            if (sVal==llToLower(BUTTON_UPMENU)){
                UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            } else if(iNewLength > 0 && iNewLength <= 60){
                //Person holding the leash can always set length.
                if (kMessageID == g_kLeashedTo || CheckCommandAuth(kMessageID, iAuth)) {
                    SetLength(iNewLength);
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Leash length set to " + (string)g_iLength+"m.",kMessageID);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + TOK_LENGTH + "=" + sVal, "");
                }
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            } else { //no value, or value out of bounds
                if (sVal != "")  //value out of range
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Oops! The leash can only reach 60 meters at most.",kMessageID);
                Dialog(kMessageID, "\nCurrently the leash reaches " + (string)g_iLength + "m.\nTo set a length up to 60 meters, use the length chat command.", ["1", "2", "3", "4", "5", "6", "8", "10", "12", "15", "20"], [BUTTON_UPMENU], 0, iAuth,"SetLength");
            }
        } else if (sComm == "anchor") {
            if (!CheckCommandAuth(kMessageID, iAuth)) {
                if (bFromMenu) UserCommand(iAuth, "post", kMessageID ,bFromMenu);
            }
            if (sVal==llToLower(BUTTON_UPMENU))  UserCommand(iAuth, "menu leash", kMessageID ,bFromMenu);
            else if((key)sVal) {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                //debug("leash target is key");//could be a post, or could be we specified an av key
                if (llGetAgentSize((key)sVal)) g_iPassConfirmed = FALSE;
                else g_iPassConfirmed = TRUE;
                LeashTo((key)sVal, kMessageID, iAuth, lPoints, FALSE,0);
            } else
                SensorDialog(g_kCmdGiver, "\n\nWhat's going to serve us as a post? If the desired object isn't on the list, please try moving closer.\n", "",iAuth,"PostTarget", PASSIVE|ACTIVE);
        }
        if(sMessage  == "give holder"){
            if(iAuth >=CMD_OWNER || iAuth <= CMD_EVERYONE){
                if(g_sLeashHolder == "na") {
                    llMessageLinked(LINK_SET,NOTIFY, "0This option is disabled because no leash holder is in the collar", kMessageID);
                    if(bFromMenu)UserCommand(iAuth, "leashmenu", kMessageID, bFromMenu);
                }else{
                    llMessageLinked(LINK_SET,NOTIFY, "0Sending Leash Holder...", kMessageID);
                    llGiveInventory(kMessageID, g_sLeashHolder);
                    if(bFromMenu)UserCommand(iAuth, "leashmenu", kMessageID, bFromMenu);
                }
            }
        }
    }
}
DebugOutput(key kID, list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llInstantMessage(kID, llGetScriptName() +final);
}
LHSearch(){
    integer iBegin=0;
    integer iEnd = llGetInventoryNumber(INVENTORY_OBJECT);
    if(iEnd == 0)g_sLeashHolder="na";
    else{
        for(iBegin=0;iBegin<iEnd;iBegin++){
            string sItem  = llGetInventoryName(INVENTORY_OBJECT,iBegin);
            if(llSubStringIndex(llToLower(sItem),"leashholder")!=-1){
                g_sLeashHolder=sItem;
                sItem="";
                iBegin=0;
                iEnd=0;
                return;
            }
        }
    }
}

dtext(string m){
   // llSetText(m+"\n \n \n \n \n \n \n",<0,1,1>,1);
}
integer g_iAlreadyMoving=FALSE;
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT){
            if(sStr == "reboot"){
                llResetScript();
            }
        } else if(iNum == READY){
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP){
            state active;
        }
    }
}
state active
{
    on_rez(integer start_param) {
        DoUnleash(FALSE);
        g_kLeashedTo = NULL_KEY;
        llResetScript();
    }

    state_entry() {
        g_kWearer = llGetOwner();
        llMinEventDelay(0.44);
        DoUnleash(FALSE);
        //Debug("Starting");
        LHSearch();
    }

    timer() {
        dtext("timer : ping");
        //inlined old isInSimOrJustOutside function
        if(g_bFollowMode){
            dtext("Mode is follow");
        }
        vector vLeashedToPos=llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
        integer iIsInSimOrJustOutside=TRUE;
        if(vLeashedToPos == ZERO_VECTOR || llVecDist(llGetPos(), vLeashedToPos)> 255) iIsInSimOrJustOutside=FALSE;
        
        if (iIsInSimOrJustOutside && llVecDist(llGetPos(),vLeashedToPos)<(60+g_iLength)) {   //if the leasher is now in range
            dtext("timer : iIsInSimOrJustOutside && VecDist < (60+(iLength=3))");
            if(!g_iLeasherInRange) { //and the leasher was previously not in range
                if (g_iAwayCounter) {
                    g_iAwayCounter = -1;
                    llSetTimerEvent(3.0);
                }
                //Debug("leashing with "+g_sCheck);
                
                if(!g_bFollowMode)
                    llMessageLinked(LINK_SET, CMD_PARTICLE, "leash" + g_sCheck + "|" + (string)g_bLeashedToAvi, g_kLeashedTo);
                g_iLeasherInRange = TRUE;

                llTargetRemove(g_iTargetHandle);
                dtext("Status: OK");
                g_vPos = vLeashedToPos;
                g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
                if (g_vPos != ZERO_VECTOR) llMoveToTarget(g_vPos, 0.8);
                ApplyRestrictions();
                
                if(!g_iAlreadyMoving) llMessageLinked(LINK_SET, LEASH_START_MOVEMENT,"","");
            } else {
                dtext("timer : LeasherInRange = TRUE");
            }
        } else {   //the leasher is not now in range
            dtext("timer : NotInSimOrOutside OR VecDist > (60+(iLength=3))");
            if(g_iLeasherInRange) {  //but was a short while ago
                if (g_iAwayCounter <= llGetUnixTime()) {
                    llTargetRemove(g_iTargetHandle);
                    llStopMoveToTarget();
                    if(!g_bFollowMode)
                        llMessageLinked(LINK_SET, CMD_PARTICLE, "unleash", g_kLeashedTo);
                    g_iLeasherInRange=FALSE;
                    ApplyRestrictions();
                    g_iAwayCounter=-1;
                    dtext("No leash holder in range\n* Stopping leash particles");
                    if(g_iAlreadyMoving)llMessageLinked(LINK_SET, LEASH_END_MOVEMENT,"","");
                } else if(g_iAwayCounter==-1){
                    g_iAwayCounter = llGetUnixTime()+15;
                    dtext("Leash holder was previously in range");
                }
            } else {
                // nothing else to do with the away counter
                // slow down the timer
                llSetTimerEvent(11);
                dtext("No leash holder in range");
            }
        }
    }
    link_message(integer iSender, integer iNum, string sMessage, key kMessageID){
        if (iNum >= CMD_OWNER && iNum <= CMD_NOACCESS) UserCommand(iNum, sMessage, kMessageID, FALSE);
        if (iNum == MENUNAME_REQUEST  && sMessage == BUTTON_PARENTMENU) {
            g_lButtons = [] ; // flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, BUTTON_PARENTMENU+"|"+BUTTON_SUBMENU, "");
            llMessageLinked(iSender, MENUNAME_REQUEST, BUTTON_SUBMENU, "");
        } else if (iNum == MENUNAME_RESPONSE) {
            list lParts = llParseString2List(sMessage, ["|"], []);
            if (llList2String(lParts, 0) == BUTTON_SUBMENU) {//someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1)
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
            }
        } else if (iNum == CMD_SAFEWORD) {
            g_iStay = FALSE;
            llReleaseControls();
            DoUnleash(TRUE);
        } else if (iNum == LM_SETTING_RESPONSE) {
            integer iInd = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, iInd -1);
            string sValue = llGetSubString(sMessage, iInd + 1, -1);
            integer i = llSubStringIndex(sToken, "_");
            
            
            //integer ind = llListFindList(g_lSettingsReqs, [sToken]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                //Debug("got Leash settings:"+sMessage);
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == TOK_DEST) {
                    //we got the last leasher's id and rank from the local settings
                    if(g_kLeashedTo==NULL_KEY){ // Try to avoid a yank loop from occuring. On_rez, it will set the LeashedTo var to null.
                        list lParam = llParseString2List(llGetSubString(sMessage, iInd + 1, -1), [","], []);
                        key kTarget = (key)llList2String(lParam, 0);
                        g_bLeashedToAvi = (integer)llList2String(lParam, 2);
                        g_bFollowMode = (integer)llList2String(lParam, 3);
                        list lPoints;
                        if (g_bLeashedToAvi) lPoints = ["collar", "handle"];
                        // if PostedTo object has vanished, clear out the leash settings
                        if (!llGetObjectPrimCount(kTarget) && !g_bLeashedToAvi) DoUnleash(TRUE);
                        else DoLeash(kTarget, (integer)llList2String(lParam, 1), lPoints,FALSE);
                    }
                } else if (sToken == TOK_LENGTH) SetLength((integer)sValue);
                else if (sToken=="strict"){
                    list lParam = llParseString2List(llGetSubString(sMessage, iInd + 1, -1), [","], []);
                    g_iStrictModeOn = (integer)sValue;
                    g_iStrictRank = (integer)llList2String(lParam, 1);
                    ApplyRestrictions();
                } else if (sToken == "turn") g_iTurnModeOn = (integer)sValue;
                else if(sToken == TOK_DEST+"name") g_sLeashedToName = sValue;
            }
        
        } else if(iNum == LM_SETTING_EMPTY){
            
            //integer ind = llListFindList(g_lSettingsReqs, [sMessage]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if(iNum == LM_SETTING_DELETE){
            
            //integer ind = llListFindList(g_lSettingsReqs, [sMessage]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if (iNum == RLV_ON) {
            g_iRLVOn = TRUE;
            ApplyRestrictions();
        } else if(iNum == LEASH_START_MOVEMENT) g_iAlreadyMoving=TRUE;
        else if(iNum == LEASH_END_MOVEMENT) g_iAlreadyMoving=FALSE;
        else if (iNum == RLV_OFF) {
            g_iRLVOn = FALSE;
            ApplyRestrictions();
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kMessageID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sMessage, ["|"], []);
                key kAV = (key)llList2String(lMenuParams, 0);
                string sButton = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu == "MainDialog"){
                    if (sButton == BUTTON_UPMENU)
                        llMessageLinked(LINK_SET, iAuth, "menu "+BUTTON_PARENTMENU, kAV);
                    else if (~llListFindList(g_lButtons, [sButton]))
                        llMessageLinked(LINK_SET, iAuth, "menu "+sButton, kAV);
                    else UserCommand(iAuth, llToLower(sButton), kAV, TRUE);
                }
                else if (sMenu == "PostTarget") UserCommand(iAuth, "anchor " + sButton, kAV, TRUE);
                else if (sMenu == "SetLength") UserCommand(iAuth, "length " + sButton, kAV, TRUE);
                // added for Confirmation Request 15-04-17 Otto
                else if (sMenu == "LeashTarget") {
                    g_kLeashCmderID = (key)sButton;
                    
                    g_iPassConfirmed = TRUE;
                    if (g_kLeashCmderID == g_kWearer) iAuth = CMD_WEARER;
                    //UserCommand(iAuth, "pass " + sButton, kAV, TRUE);
                    ConfirmDialog((key)sButton, kAV, "LeashTarget", iAuth);
                } else if (sMenu == "LeashTargetConfirm") {
                    if (sButton == "Yes") {
                        g_iPassConfirmed = TRUE;
                        if (g_kLeashCmderID == g_kWearer) iAuth = CMD_WEARER;
                        UserCommand(iAuth, "pass " + (string)kAV, g_kLeashCmderID, TRUE);
                    } else {
                        llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(kAV)+" did not accept %WEARERNAME%'s leash.",g_kLeashCmderID);
                        g_iPassConfirmed = FALSE;
                    }
                    g_kLeashCmderID = "";
                } else if (sMenu == "FollowTarget") {
                    if (kAV == (key)sButton){
                        UserCommand(iAuth, "follow " + (string)kAV, kAV, TRUE);
                    }
                    else {
                        g_kLeashCmderID = kAV;
                        ConfirmDialog((key)sButton, kAV, "FollowTarget", iAuth);
                    }
                } else if (sMenu == "FollowTargetConfirm") {
                    if (sButton == "Yes") {
                        g_iPassConfirmed = TRUE;
                        if (g_kLeashCmderID == g_kWearer) iAuth = CMD_WEARER;
                        UserCommand(iAuth, "follow " + (string)kAV, g_kLeashCmderID, TRUE);
                    } else {
                        llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(kAV)+" denied %WEARERNAME% to follow them.",g_kLeashCmderID);
                        g_iPassConfirmed = FALSE;
                    }
                    g_kLeashCmderID = "";
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kMessageID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == REBOOT && sMessage == "reboot") llResetScript();
        else if(iNum == AUTH_REPLY){
            list lParams = llParseString2List(sMessage, ["|"],[]);
            key kTarget = (key)llList2String(lParams,1);
            integer iNewAuth = (integer)llList2String(lParams,2);
            if(llList2String(lParams,0)=="AuthReply" && kMessageID == "passLeash"){
                LeashTo(kTarget, g_kPassLeashFrom, iNewAuth, g_lPasslPoints,FALSE, g_iPreviousAuth);
            } else if(llList2String(lParams,0) == "AuthReply" && kMessageID=="followPass"){
                LeashTo(kTarget, g_kPassLeashFrom, iNewAuth, g_lPasslPoints,TRUE, g_iPreviousAuth);
            }
        }else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sMessage == "ver")onlyver=1;
            llInstantMessage(kMessageID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            DebugOutput(kMessageID, [" LEASHED TO:", g_kLeashedTo, g_sLeashedToName]);
            DebugOutput(kMessageID, [" LENGTH:", g_iLength]);
            DebugOutput(kMessageID, [" STAY:", g_iStay]);
            DebugOutput(kMessageID, [" LEASHER IN RANGE:", g_iLeasherInRange]);
            DebugOutput(kMessageID, [" STRICT MODE:",g_iStrictModeOn]);
            DebugOutput(kMessageID, [" FOLLOW MODE:", g_bFollowMode]);
            DebugOutput(kMessageID, [" COMMAND GIVER:",g_kCmdGiver]);
            DebugOutput(kMessageID, [" LEASH COMMANDER ID:",g_kLeashCmderID]);
            DebugOutput(kMessageID, [" LEASHED TO AVI:",g_bLeashedToAvi]);
            DebugOutput(kMessageID, [" LEASH HOLDER:",g_sLeashHolder]);
        }
    }

    at_target(integer iNum, vector vTarget, vector vMe) {
        llStopMoveToTarget();
        
        llTargetRemove(g_iTargetHandle);
        g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
        g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
        if(g_iJustMoved) {
            vector pointTo = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0) - llGetPos();
            float  turnAngle = llAtan2(pointTo.x, pointTo.y);// - myAngle;
            if (g_iTurnModeOn) llMessageLinked(LINK_SET, RLV_CMD, "setrot:" + (string)(turnAngle) + "=force", NULL_KEY);   //transient command, doesn;t need our fakekey
            g_iJustMoved = 0;
        }
        
        if(g_iAlreadyMoving) llMessageLinked(LINK_SET, LEASH_END_MOVEMENT, "","");
    }

    not_at_target() {
        g_iJustMoved = 1;
        // i ran into a problem here which seems to be "speed" related, specially when using the menu to unleash this event gets triggered together or just after the CleanUp() function
        //to prevent to get stay in the target events i added a check on g_kLeashedTo is NULL_KEY
        if(g_kLeashedTo) {
            vector vNewPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
            if (g_vPos != vNewPos) {
                llTargetRemove(g_iTargetHandle);
                g_vPos = vNewPos;
                g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
            }
            if (g_vPos != ZERO_VECTOR){
                // The below code was causing users to fly if the z height of the person holding the leash was different.
                
                
                //vector currentPos = llGetPos();
                //g_vPos = <g_vPos.x, g_vPos.y, currentPos.z>;
                llMoveToTarget(g_vPos,1.0);
            }
            else{
                llStopMoveToTarget();
                llTargetRemove(g_iTargetHandle);
            }
            
            
            if(!g_iAlreadyMoving) llMessageLinked(LINK_SET, LEASH_START_MOVEMENT, "","");
        } else {
            llStopMoveToTarget();
            llTargetRemove(g_iTargetHandle);
            DoUnleash(TRUE);
        }
    }

    run_time_permissions(integer iPerm) {
        if (iPerm & PERMISSION_TAKE_CONTROLS) {
            //disbale all controls but left mouse button (for stay cmd)
            llTakeControls(CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_LBUTTON | CONTROL_ML_LBUTTON, FALSE, FALSE);
        }
    }
    object_rez(key id) {
        //g_iLength=3;
        // The above code overrides user preferences for leash length.
        DoLeash(id, g_iRezAuth, [],TRUE);
    }

    changed (integer iChange){
        if (iChange & CHANGED_OWNER){
            g_kWearer = llGetOwner();
        }
    }
}