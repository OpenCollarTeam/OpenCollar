//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                           Leash - 151001.1                               //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Nandana Singh, Lulu Pink, Garvin Twine,       //
//  Joy Stipe, Cleo Collins, Satomi Ahn, Master Starship, Toy Wylie,        //
//  Kaori Gray, Sei Lisa, Wendy Starfall, littlemousy, Romka Swallowtail,   //
//  Sumi Perl, Karo Weirsider, Kurt Burleigh, Marissa Mistwallow et al.     //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//         github.com/OpenCollar/opencollar/tree/master/src/collar          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// ------ TOKEN DEFINITIONS ------
// ---- Immutable ----
// - Should be constant across collars, so not prefixed
// --- db tokens ---
string TOK_LENGTH   = "leashlength";
string TOK_DEST     = "leashedto"; // format: uuid,rank
// --- channel tokens ---

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

integer NOTIFY                = 1002;
//integer SAY                   = 1004;
integer REBOOT                = -1000;
integer LINK_DIALOG           = 3;
integer LINK_RLV              = 4;
integer LINK_SAVE             = 5;
integer LM_SETTING_SAVE       = 2000;
integer LM_SETTING_REQUEST    = 2001;
integer LM_SETTING_RESPONSE   = 2002;
integer LM_SETTING_DELETE     = 2003;
//integer LM_SETTING_EMPTY            = 2004;
// -- MENU/DIALOG
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
integer MENUNAME_REMOVE     = 3003;

integer RLV_CMD = 6000;

integer RLV_OFF = 6100;
integer RLV_ON = 6101;

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
string g_sTmpName;
key g_kCmdGiver;
key g_kLeashedTo = NULL_KEY;
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

list g_lRestrictionNames= ["fly","tplm","tplure","tploc"];
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
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lButtons, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuID], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuID];
}

SensorDialog(key kRCPT, string sPrompt, string sSearchName, integer iAuth, string sMenuID, integer iSensorType) {
    key kMenuID = llGenerateKey();
    if (sSearchName != "") sSearchName = "`"+sSearchName+"`1";
    llMessageLinked(LINK_DIALOG, SENSORDIALOG, (string)kRCPT +"|"+sPrompt+"|0|``"+(string)iSensorType+"`10`"+(string)PI+sSearchName+"|"+BUTTON_UPMENU+"|" + (string)iAuth, kMenuID);
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
    if (kCmdGiver == g_kWearer) sPrompt = "%WEARERNAME% wants to ";
    else sPrompt = sCmdGiverURI + " wants to ";
    if (sType == "LeashTarget") {
        sMessage = "Asking "+NameURI(kAv)+" to accept %WEARERNAME%'s leash.";
        if (kCmdGiver == g_kWearer) sPrompt += "pass you their leash.";
        else sPrompt += "pass you %WEARERNAME%'s leash.";
        sPrompt += "\nAre you OK with this?";
        Dialog(kAv,sPrompt,["Yes","No"],[],0,iAuth,"LeashTargetConfirm");
    } else {
        sMessage = "Asking "+NameURI(kAv)+" to accept %WEARERNAME% to follow them.";
        if (kCmdGiver == g_kWearer) sPrompt += "follow you.";
        else sPrompt += " command %WEARERNAME% to follow you.";
        sPrompt += "\nAre you OK with this?";
        Dialog(kAv,sPrompt,["Yes","No"],[],0,iAuth,"FollowTargetConfirm");
    }
    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMessage,kCmdGiver);
}

integer CheckCommandAuth(key kCmdGiver, integer iAuth) {
    // Check for invalid auth
    if (iAuth < CMD_OWNER || iAuth > CMD_WEARER) return FALSE;
    // If leashed, only move leash if Comm Giver outranks current leasher
    if (g_kLeashedTo != NULL_KEY && iAuth > g_iLastRank){
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kCmdGiver);
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
                if (! g_bFollowMode) {
                //Debug("Setting restrictions");
                llMessageLinked(LINK_RLV, RLV_CMD, "fly=n,tplm=n,tplure=n,tploc=n,tplure:" + (string) g_kLeashedTo + "=add", "realleash");     //set all restrictions
                return;
                }
            }
        //} else {
            //Debug("Strict is off");
        }
    //} else {
        //Debug("Leasher out of range");
    }
    //Debug("Releasing restrictions");
    llMessageLinked(LINK_RLV, RLV_CMD, "clear", "realleash");     //release all restrictions
}

// Wrapper for DoLeash with notifications
integer LeashTo(key kTarget, key kCmdGiver, integer iAuth, list lPoints, integer iFollowMode ){
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
    if (!CheckCommandAuth(kCmdGiver, iAuth)) return FALSE;
    //if (g_kLeashedTo==kTarget) return TRUE; 
    if (g_kLeashedTo) DoUnleash();

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
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sCmdGiver+" command %WEARERNAME% to follow you.",kTarget);
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
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sCmdGiver+" hands you %WEARERNAME%'s leash.",kTarget);
                    } else {// LeashTo object
                        sCmdMess += ", and tie it to " + sTarget + ".";
                        sWearMess += ", and ties it to " + sTarget + ".";
                    }
                }
            }
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sCmdMess,kCmdGiver);
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sWearMess,g_kWearer);
    }
    g_bFollowMode = iFollowMode; // leashing, or following
    if (bTargetIsAvi) g_bLeashedToAvi = TRUE;
    if (llGetOwnerKey(kCmdGiver)==g_kWearer) iAuth=CMD_WEARER;   //prevents owner-wearer with public access creating an unbreakable leash to an unwilling participant
    DoLeash(kTarget, iAuth, lPoints);
    g_iPassConfirmed = FALSE;
    // Notify Target how to unleash, only if:
    // Avatar
    // Didn't send the command
    // Don't own the object that sent the command
    if (g_bLeashedToAvi && kCmdGiver != kTarget && llGetOwnerKey(kCmdGiver) != kTarget) {
        if (iFollowMode){
            llMessageLinked(LINK_DIALOG,NOTIFY, "0"+"%WEARERNAME% has been commanded to follow you.  Say \"%PREFIX%unfollow\" to relase them.", g_kLeashedTo);
        } else {
            llMessageLinked(LINK_DIALOG,NOTIFY, "0"+"%WEARERNAME% has been leashed to you.  Say \"%PREFIX%unleash\" to unleash them.", g_kLeashedTo);
        }
    }
    return TRUE;
}

DoLeash(key kTarget, integer iAuth, list lPoints) {
    g_iLastRank = iAuth;
    g_kLeashedTo = kTarget;
    if (g_bFollowMode)
        llMessageLinked(LINK_THIS, CMD_PARTICLE, "unleash", g_kLeashedTo);
    else {
        integer iPointCount = llGetListLength(lPoints);
        g_sCheck = "";
        if (iPointCount) {//if more than one leashpoint, listen for all strings, else listen just for that point
            if (iPointCount == 1) g_sCheck = (string)llGetOwnerKey(kTarget) + llList2String(lPoints, 0) + " ok";
        }
        //Send link message to the particle script
        //Debug("leashing with "+g_sCheck);
        llMessageLinked(LINK_THIS, CMD_PARTICLE, "leash" + g_sCheck + "|" + (string)g_bLeashedToAvi, g_kLeashedTo);
        llSetTimerEvent(3.0);   //check for leasher out of range
    }
    // change to llTarget events by Lulu Pink
    g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]), 0);
    //to prevent multiple target events and llMoveToTargets
    llTargetRemove(g_iTargetHandle);
    llStopMoveToTarget();
    g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
    if (g_vPos != ZERO_VECTOR) {
        llMoveToTarget(g_vPos, 0.7);
    }
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + TOK_DEST + "=" + (string)kTarget + "," + (string)iAuth + "," + (string)g_bLeashedToAvi + "," + (string)g_bFollowMode, "");
    g_iLeasherInRange=TRUE;
    ApplyRestrictions();
}

// Wrapper for DoUnleash()
Unleash(key kCmdGiver) {
    string sTarget = NameURI(g_kLeashedTo);
    if ( (key)g_kLeashedTo ) {
        string sCmdGiver = NameURI(kCmdGiver);
        string sWearMess;
        string sCmdMess;
        string sTargetMess;
        integer bCmdGiverIsAvi=llGetAgentSize(kCmdGiver) != ZERO_VECTOR;
        if (bCmdGiverIsAvi) {
            if (kCmdGiver == g_kWearer) { // Wearer is Leasher
                if (g_bFollowMode) {
                    sWearMess = "You stop following " + sTarget + ".";
                    sTargetMess = "%WEARERNAME% stops following you.";
                } else {
                    sWearMess = "You unleash yourself from " + sTarget + "."; // sTarget might be an object
                    sTargetMess = "%WEARERNAME% unleashes from you.";
                }
                if (g_bLeashedToAvi) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sTargetMess,g_kLeashedTo);
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
                        sCmdMess= "You unleash  %WEARERNAME% from " + sTarget + ".";
                        sWearMess = sCmdGiver + " unleashes you from " + sTarget + ".";
                        sTargetMess = sCmdGiver + " unleashes %WEARERNAME% from you.";
                    }
                    if (g_bLeashedToAvi) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sTargetMess,g_kLeashedTo);
                }
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sCmdMess,kCmdGiver);
            }
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sWearMess,g_kWearer);
        }
        DoUnleash();
    } else
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%WEARERNAME% is not leashed.",kCmdGiver);
}

DoUnleash(){
    llTargetRemove(g_iTargetHandle);
    llStopMoveToTarget();
    llMessageLinked(LINK_THIS, CMD_PARTICLE, "unleash", g_kLeashedTo);
    g_kLeashedTo = NULL_KEY;
    g_iLastRank = CMD_EVERYONE;
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + TOK_DEST, "");
    llSetTimerEvent(0.0);   //stop checking for leasher out of range
    g_iLeasherInRange=FALSE;
    ApplyRestrictions();
}

YankTo(key kIn){
    llMoveToTarget(llList2Vector(llGetObjectDetails(kIn, [OBJECT_POS]), 0), 0.5);
    if (llGetAgentInfo(g_kWearer)&AGENT_SITTING) llMessageLinked(LINK_RLV, RLV_CMD, "unsit=force", "");
    llSleep(2.0);
    llStopMoveToTarget();
}

UserCommand(integer iAuth, string sMessage, key kMessageID, integer bFromMenu) {
    //Debug("Got user comand:\niAuth: "+(string)iAuth+"\nsMessage: "+sMessage+"\nkMessageID: "+(string)kMessageID+"\nbFromMenu: "+(string)bFromMenu);
    if (iAuth == CMD_EVERYONE) {
        if (kMessageID == g_kLeashedTo) {
            sMessage = llToLower(sMessage);
            if (sMessage == "unleash" || sMessage == "unfollow" || (sMessage == "toggleleash" && NULL_KEY != g_kLeashedTo)) Unleash(kMessageID);
           // else if (sMessage == "giveholder") llGiveInventory(kMessageID, "Leash Holder");
            else if (sMessage == "yank") YankTo(kMessageID);
        }
    } else { //(iAuth >= CMD_OWNER && iAuth <= CMD_WEARER)
        g_kCmdGiver = kMessageID;
        list lParam = llParseString2List(sMessage, [" "], []);
        string sComm = llToLower(llList2String(lParam, 0));
        string sVal = llToLower(llList2String(lParam, 1));
        string sVal2= llList2String(lParam, 2);

        sMessage = llToLower(sMessage);  //convert sMessage to lower case for caseless comparisson
        //debug(sMessage);
        if (sMessage=="leashmenu" || sMessage == "menu leash"){
            list lButtons;
            if (kMessageID != g_kWearer) lButtons += "Grab";// Only if not the wearer.
            else lButtons += [" "];
            if (g_kLeashedTo != NULL_KEY) {
                if (g_bFollowMode) lButtons += ["Unfollow"];
                else lButtons += ["Unleash"];
            }
            else lButtons += " ";
            if (kMessageID == g_kLeashedTo) lButtons += "Yank";//only if leash holder
            else lButtons += " ";
            lButtons += ["Follow"];
            lButtons += ["Anchor","Pass"];
            lButtons += ["Length"];
            lButtons += g_lButtons;

            string sPrompt = "\n[http://www.opencollar.at/leash.html Leash]\n\nLet's go walkies!";
            Dialog(kMessageID, sPrompt, lButtons, [BUTTON_UPMENU], 0, iAuth, "MainDialog");
        } else  if (sComm == "post") {
          //  if (sComm == "post" && !bFromMenu) UserCommand(iAuth, "find"+sMessage, kMessageID ,bFromMenu);
            if (sVal==llToLower(BUTTON_UPMENU)) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
           // else if (sMessage == "post give post")   UserCommand(iAuth, "givepost", kMessageID ,bFromMenu);
           // else if (sMessage == "post park")        UserCommand(iAuth, "rezpost", kMessageID ,bFromMenu);
           // else if (sMessage == "post anchor")      UserCommand(iAuth, "findpost", kMessageID ,bFromMenu);
           // else  Dialog(kMessageID, "\nAnchor the leash to something nearby\nor use instant parking mode!", ["Anchor", "Park"], [BUTTON_UPMENU], 0, iAuth,"PostMenu");
        } else  if (sMessage == "grab" || sMessage == "leash" || (sMessage == "toggleleash" && NULL_KEY == g_kLeashedTo)) {
            g_iPassConfirmed = TRUE;
            LeashTo(kMessageID, kMessageID, iAuth, ["handle"], FALSE);
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
        } else if(sComm == "follow" || sComm == "followtarget") {
            //Debug("Got a follow command:"+sMessage);
            if (!CheckCommandAuth(kMessageID, iAuth)) return;
            if (sVal==llToLower(BUTTON_UPMENU))
                UserCommand(iAuth, "leash", kMessageID ,bFromMenu);
            else if (sVal == "me") {
                g_iPassConfirmed = TRUE;
                LeashTo(kMessageID, kMessageID, iAuth, [], TRUE);
            } else if ((key)sVal) {
                g_iPassConfirmed = TRUE;
                LeashTo((key)sVal, kMessageID, iAuth, [], TRUE);
            } else
                SensorDialog(g_kCmdGiver, "\nWho shall be followed?\n", sVal,iAuth,"FollowTarget", AGENT);
        } else if (sMessage == "runaway" && iAuth == CMD_OWNER) {
            Unleash(kMessageID);
        } else if (sMessage == "unleash" || sMessage == "unfollow" || (sMessage == "toggleleash" && NULL_KEY != g_kLeashedTo)) {
            if (CheckCommandAuth(kMessageID, iAuth)) Unleash(kMessageID);
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
        } /*else if (sMessage == "giveholder" || sMessage == "give holder") {
            if (llGetInventoryType("Leash Holder") == INVENTORY_OBJECT)
                llGiveInventory(kMessageID, "Leash Holder");
            else
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Sorry, there is no leash holder in this %DEVICETYPE%.",kMessageID);
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
        } else if (sMessage == "givepost" || sMessage == "give post") {
            if (llGetInventoryType("Leash Post") == INVENTORY_OBJECT)
                llGiveInventory(kMessageID, "Leash Post");
            else
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Sorry, there is no leash post in this %DEVICETYPE%.",kMessageID);
            if (bFromMenu) UserCommand(iAuth, "post", kMessageID ,bFromMenu);
        }*/ //else if (sMessage == "rezpost" || sMessage == "rez post" || sMessage == "park") {
            else if (sMessage == "park") {
            if (llGetInventoryType("Pretty Balloon") == INVENTORY_OBJECT) {
                g_iRezAuth=iAuth;
                llRezObject("Pretty Balloon", llGetPos() + (<0.2, 0.0, 1.2> * llGetRot()), ZERO_VECTOR, llEuler2Rot(<0, 0, 0> * DEG_TO_RAD), 0);
            }
           /* else if (llGetInventoryType("Leash Post") == INVENTORY_OBJECT)
                llRezObject("Leash Post", llGetPos() + (<0.1, 0.0, 0.37> * llGetRot()), ZERO_VECTOR, llEuler2Rot(<0, 90, 270> * DEG_TO_RAD), 0);
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Sorry, there is no leash post in this %DEVICETYPE%.",kMessageID);
            if (bFromMenu) UserCommand(iAuth, "post", kMessageID ,bFromMenu);*/
        } else if (sMessage == "yank" && kMessageID == g_kLeashedTo) {
            //Person holding the leash can yank.
            if(llGetAgentInfo(g_kWearer)&AGENT_SITTING) llMessageLinked(LINK_RLV, RLV_CMD, "unsit=force", "realleash");
            YankTo(kMessageID);
        } else if (sMessage == "beckon" && iAuth == CMD_OWNER) YankTo(kMessageID);
        else if (sMessage == "stay") {
            if (iAuth <= CMD_GROUP) {
                g_iStayRank = iAuth;
                g_iStay = TRUE;
                string sCmdGiver = NameURI(kMessageID);
                llRequestPermissions(g_kWearer, PERMISSION_TAKE_CONTROLS);
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sCmdGiver + " commanded you to stay in place, you cannot move until the command is revoked again.",g_kWearer);
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You commanded %WEARERNAME% to stay in place. Either leash the slave with the grab command or use \"unstay\" to enable movement again.",kMessageID);
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            }
        } else if ((sMessage == "unstay" || sMessage == "move") && g_iStay) {
            if (iAuth <= g_iStayRank) {
                g_iStay = FALSE;
                llReleaseControls();
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You are free to move again.",g_kWearer);
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You allowed %WEARERNAME% to move freely again.",kMessageID);
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            }
        } else if (sMessage == "strict on") {
            if (g_iStrictModeOn) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Strict leashing is already enabled.",kMessageID);
            else {
                g_iStrictRank = iAuth;
                g_iStrictModeOn=TRUE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "strict=1,"+ (string)iAuth, "");
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "strict=1,"+ (string)iAuth, kMessageID);
                llMessageLinked(LINK_SAVE, LM_SETTING_REQUEST, TOK_DEST, "");  //query current leasher, the response will trigger ApplyRestrictions
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Strict leashing enabled.",kMessageID);
                ApplyRestrictions();
            }
        } else if (sMessage == "strict off") {
            if (iAuth <= g_iStrictRank) {
                g_iStrictModeOn=FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "strict", "");
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "strict=0,"+ (string)iAuth,kMessageID);
                ApplyRestrictions();
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Strict leashing disabled.",kMessageID);
            } else {
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE,"strictAuthError="+(string)iAuth,kMessageID);
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kMessageID);
            }
        } else if (sMessage == "turn on") {
            g_iTurnModeOn=TRUE;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "turn=1", "");
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "turn=1", "");
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Turning towards leasher enabled.",kMessageID);
        } else if (sMessage == "turn off") {
            g_iTurnModeOn=FALSE;
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "turn", "");
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + "turn=0,"+ (string)iAuth,kMessageID);
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Turning towards leasher disabled.",kMessageID);
        } else if (sComm == "leashto" || sComm == "pass") {
            if (!CheckCommandAuth(kMessageID, iAuth)) return;
            if (sVal==llToLower(BUTTON_UPMENU))
                UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            else if((key)sVal) {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                //debug("leash target is key");//could be a post, or could be we specified an av key
                //g_kLeashTargetDialogID = "";
                LeashTo((key)sVal, kMessageID, iAuth, lPoints, FALSE);
            } else 
                SensorDialog(g_kCmdGiver, "\nWho shall we pass the leash?\n", sVal,iAuth,"LeashTarget", AGENT);
        } else if (sComm == "length") {
            integer iNewLength = (integer)sVal;
            if (sVal==llToLower(BUTTON_UPMENU)){
                UserCommand(iAuth, "leash", kMessageID ,bFromMenu);
            } else if(iNewLength > 0 && iNewLength <= 20){
                //Person holding the leash can always set length.
                if (kMessageID == g_kLeashedTo || CheckCommandAuth(kMessageID, iAuth)) {
                    SetLength(iNewLength);
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Leash length set to " + (string)g_iLength+"m.",kMessageID);
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + TOK_LENGTH + "=" + sVal, "");
                }
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            } else { //no value, or value out of bounds
                if (sVal != "")  //value out of range
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Oops! The leash can only reach 20 meters at most.",kMessageID);
                Dialog(kMessageID, "\nCurrently the leash reaches " + (string)g_iLength + "m.", ["1", "2", "3", "4", "5", "6", "8", "10", "12", "15", "20"], [BUTTON_UPMENU], 0, iAuth,"SetLength");
            }
        } else if (sComm == "findpost" || sMessage == "find post" || sComm == "anchor") {
            if (!CheckCommandAuth(kMessageID, iAuth)) {
                if (bFromMenu) UserCommand(iAuth, "post", kMessageID ,bFromMenu);
            }
            if (sVal==llToLower(BUTTON_UPMENU))  UserCommand(iAuth, "menu leash", kMessageID ,bFromMenu);
            else if((key)sVal) {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                //debug("leash target is key");//could be a post, or could be we specified an av key
                //if (bFromMenu) UserCommand(iAuth, "findpost", kMessageID ,bFromMenu);
                if (llGetAgentSize((key)sVal)) g_iPassConfirmed = FALSE;
                else g_iPassConfirmed = TRUE;
                LeashTo((key)sVal, kMessageID, iAuth, lPoints, FALSE);
            } else 
                SensorDialog(g_kCmdGiver, "\n\nWhat's going to serve us as a post? If the desired object isn't on the list, please try moving closer.\n", "",iAuth,"PostTarget", PASSIVE|ACTIVE);
        }
    }
}

default {
    on_rez(integer start_param) {
        DoUnleash();
    }

    state_entry() {
        g_kWearer = llGetOwner();
        llMinEventDelay(0.44);
        DoUnleash();
        //Debug("Starting");
    }

    timer() {
        //inlined old isInSimOrJustOutside function
        vector vLeashedToPos=llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
        integer iIsInSimOrJustOutside=TRUE;
        if(vLeashedToPos == ZERO_VECTOR || vLeashedToPos.x < -25 || vLeashedToPos.x > 280 || vLeashedToPos.y < -25 || vLeashedToPos.y > 280) iIsInSimOrJustOutside=FALSE;

        if (iIsInSimOrJustOutside && llVecDist(llGetPos(),vLeashedToPos)<60) {   //if the leasher is now in range
            if(!g_iLeasherInRange) { //and the leasher was previously not in range
                if (g_iAwayCounter) {
                    g_iAwayCounter = 0;
                    llSetTimerEvent(3.0);
                }
                //Debug("leashing with "+g_sCheck);
                llMessageLinked(LINK_THIS, CMD_PARTICLE, "leash" + g_sCheck + "|" + (string)g_bLeashedToAvi, g_kLeashedTo);
                g_iLeasherInRange = TRUE;

                llTargetRemove(g_iTargetHandle);
                g_vPos = vLeashedToPos;
                g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
                if (g_vPos != ZERO_VECTOR) llMoveToTarget(g_vPos, 0.8);
                ApplyRestrictions();
            }
        } else {   //the leasher is not now in range
            if(g_iLeasherInRange) {  //but was a short while ago
                if (g_iAwayCounter > 3) {
                    llTargetRemove(g_iTargetHandle);
                    llStopMoveToTarget();
                    llMessageLinked(LINK_THIS, CMD_PARTICLE, "unleash", g_kLeashedTo);
                    g_iLeasherInRange=FALSE;
                    ApplyRestrictions();
                }
            }
            g_iAwayCounter++; //+1 every 3 secs
            if (g_iAwayCounter > 200) {//3mins 20 secs
            //slow down the sensor:
                g_iAwayCounter = 1;
                llSetTimerEvent(11.0);
            }
        }
    }
    link_message(integer iSender, integer iNum, string sMessage, key kMessageID){
        if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sMessage, kMessageID, FALSE);
        else if (iNum == MENUNAME_REQUEST  && sMessage == BUTTON_PARENTMENU) {
            g_lButtons = [] ; // flush submenu buttons
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
            DoUnleash();
        } else if (iNum == LM_SETTING_RESPONSE) {
            integer iInd = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, iInd -1);
            string sValue = llGetSubString(sMessage, iInd + 1, -1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                //Debug("got Leash settings:"+sMessage);
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == TOK_DEST) {
                    //we got the last leasher's id and rank from the local settings
                    list lParam = llParseString2List(llGetSubString(sMessage, iInd + 1, -1), [","], []);
                    key kTarget = (key)llList2String(lParam, 0);
                    g_bLeashedToAvi = (integer)llList2String(lParam, 2);
                    g_bFollowMode = (integer)llList2String(lParam, 3);
                    list lPoints;
                    if (g_bLeashedToAvi) lPoints = ["collar", "handle"];
                    // if PostedTo object has vanished, clear out the leash settings
                    if (!llGetObjectPrimCount(kTarget) && !g_bLeashedToAvi) DoUnleash();
                    else DoLeash(kTarget, (integer)llList2String(lParam, 1), lPoints);
                } else if (sToken == TOK_LENGTH) SetLength((integer)sValue);
                else if (sToken=="strict"){
                    list lParam = llParseString2List(llGetSubString(sMessage, iInd + 1, -1), [","], []);
                    g_iStrictModeOn = (integer)sValue;
                    g_iStrictRank = (integer)llList2String(lParam, 1);
                    ApplyRestrictions();
                } else if (sToken == "turn") g_iTurnModeOn = (integer)sValue;
            } 
        } else if (iNum == RLV_ON) {
            g_iRLVOn = TRUE;
            ApplyRestrictions();
        } else if (iNum == RLV_OFF) {
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
                        llMessageLinked(LINK_ROOT, iAuth, "menu "+BUTTON_PARENTMENU, kAV);
                    else if (~llListFindList(g_lButtons, [sButton]))
                        llMessageLinked(LINK_ROOT, iAuth, "menu "+sButton, kAV);
                    else UserCommand(iAuth, llToLower(sButton), kAV, TRUE);
                }
                else if (sMenu == "PostTarget") UserCommand(iAuth, "findpost " + sButton, kAV, TRUE);
                else if (sMenu == "SetLength") UserCommand(iAuth, "length " + sButton, kAV, TRUE);
               // else if (sMenu == "PostMenu") UserCommand(iAuth, "post " + sButton, kAV, TRUE);
                // added for Confirmation Request 15-04-17 Otto
                else if (sMenu == "LeashTarget") {
                    g_kLeashCmderID = kAV;
                    ConfirmDialog((key)sButton, kAV, "LeashTarget", iAuth);
                } else if (sMenu == "LeashTargetConfirm") {
                    if (sButton == "Yes") {
                        g_iPassConfirmed = TRUE;
                        if (g_kLeashCmderID == g_kWearer) iAuth = CMD_WEARER;
                        UserCommand(iAuth, "leashto " + (string)kAV, g_kLeashCmderID, TRUE);
                    } else {
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(kAV)+" did not accept %WEARERNAME%'s leash.",g_kLeashCmderID);
                        g_iPassConfirmed = FALSE;
                    }
                    g_kLeashCmderID = "";
                } else if (sMenu == "FollowTarget") {
                    if (kAV == (key)sButton) UserCommand(iAuth, "follow " + (string)kAV, kAV, TRUE);
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
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(kAV)+" denied %WEARERNAME% to follow them.",g_kLeashCmderID);
                    g_iPassConfirmed = FALSE;
                    }
                    g_kLeashCmderID = "";
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kMessageID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        } else if (iNum == REBOOT && sMessage == "reboot") llResetScript();
    }

    at_target(integer iNum, vector vTarget, vector vMe) {
        llStopMoveToTarget();
        llTargetRemove(g_iTargetHandle);
        g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
        g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
        if(g_iJustMoved) {
            vector pointTo = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0) - llGetPos();
            float  turnAngle = llAtan2(pointTo.x, pointTo.y);// - myAngle;
            if (g_iTurnModeOn) llMessageLinked(LINK_RLV, RLV_CMD, "setrot:" + (string)(turnAngle) + "=force", NULL_KEY);   //transient command, doesn;t need our fakekey
            g_iJustMoved = 0;
        }
    }

    not_at_target() {
        g_iJustMoved = 1;
        // i ran into a problem here which seems to be "speed" related, specially when using the menu to unleash this event gets triggered together or just after the CleanUp() function
        //to prevent to get stay in the target events i added a check on g_kLeashedTo is NULL_KEY
        if(g_kLeashedTo) {
            if (g_iStrictModeOn && llGetAgentInfo(g_kWearer)&AGENT_SITTING) llMessageLinked(LINK_RLV, RLV_CMD, "unsit=force", "");
            vector vNewPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
            //llStopMoveToTarget();
            if (g_vPos != vNewPos) {
                llTargetRemove(g_iTargetHandle);
                g_vPos = vNewPos;
                g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
            }
            if (g_vPos != ZERO_VECTOR) llMoveToTarget(g_vPos,1.0);
            else llStopMoveToTarget();
        } else {
            DoUnleash();
        }
    }

    run_time_permissions(integer iPerm) {
        if (iPerm & PERMISSION_TAKE_CONTROLS) {
            //disbale all controls but left mouse button (for stay cmd)
            llTakeControls(CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_LBUTTON | CONTROL_ML_LBUTTON, FALSE, FALSE);
        }
    }
    object_rez(key id) {
        g_iLength=3;
        DoLeash(id, g_iRezAuth, []);
    }

    changed (integer iChange){
        if (iChange & CHANGED_OWNER){
            g_kWearer = llGetOwner();
        }
/*        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
