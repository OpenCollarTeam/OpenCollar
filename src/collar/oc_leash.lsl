////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - leash                                //
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

// Oct. 18, 2008
// Nandana Singh, Lulu Pink, Garvin Twine, Joy Stipe

// ------ TOKEN DEFINITIONS ------
// ---- Immutable ----
// - Should be constant across collars, so not prefixed
// --- db tokens ---
string TOK_LENGTH   = "leashlength";
string TOK_DEST     = "leashedto"; // format: uuid,rank
// --- channel tokens ---
// - MESSAGE MAP
//integer COMMAND_NOAUTH      = 0;
integer COMMAND_OWNER       = 500;
//integer COMMAND_SECOWNER    = 501;
integer COMMAND_GROUP       = 502;
integer COMMAND_WEARER      = 503;
integer COMMAND_EVERYONE    = 504;
integer COMMAND_SAFEWORD    = 510;
integer POPUP_HELP          = 1001;
// -- SETTINGS (whatever the actual backend)
// - Setting strings must be in the format: "token=value"
integer LM_SETTING_SAVE             = 2000; // to have settings saved to httpdb
integer LM_SETTING_REQUEST          = 2001; // send requests for settings on this channel
integer LM_SETTING_RESPONSE         = 2002; // responses received on this channel
integer LM_SETTING_DELETE           = 2003; // delete token from DB
integer LM_SETTING_EMPTY            = 2004; // returned when a token has no value in the httpdb
// -- MENU/DIALOG
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
integer MENUNAME_REMOVE     = 3003;

integer RLV_CMD = 6000;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
//integer DIALOG_TIMEOUT      = -9002;
integer SENSORDIALOG = -9003;

integer COMMAND_PARTICLE     = 20000;
integer COMMAND_LEASH_SENSOR = 20001;

// --- menu button tokens ---
string BUTTON_UPMENU       = "BACK";
string BUTTON_PARENTMENU   = "Main";
string BUTTON_SUBMENU      = "Leash";
//string BUTTON_LEASH        = "Grab";
//string BUTTON_LEASH_TO     = "LeashTo";
//string BUTTON_FOLLOW       = "Follow Me";
//string BUTTON_FOLLOW_MENU  = "FollowTarget";
//string BUTTON_UNLEASH      = "Unleash";
//string BUTTON_UNFOLLOW     = "Unfollow";
//string BUTTON_STAY         = "Stay";
//string BUTTON_UNSTAY       = "UnStay";
//string BUTTON_ROT          = "Rotate";
//string BUTTON_UNROT        = "Don't Rotate";
//string BUTTON_LENGTH       = "Length";
//string BUTTON_GIVE_HOLDER  = "give Holder";
//string BUTTON_GIVE_POST    = "give Post";
//string BUTTON_REZ_POST     = "Rez Post";
//string BUTTON_POST         = "Post";
//string BUTTON_YANK         = "Yank";


// ---------------------------------------------
// ------ VARIABLE DEFINITIONS ------
// ----- menu -----
key g_kMenuUser;
key g_kMainDialogID;
key g_kSetLengthDialogID;
key g_kLeashTargetDialogID;
key g_kFollowTargetDialogID;
key g_kPostTargetDialogID;
key g_kPostMenuDialogID;

list g_lDialogs;    //tracks dialogs generated.  2 strided, key, type
list g_lButtons;    //buttons added by other scripts
// ----- collar -----

key g_kWearer;
integer g_iJustMoved;
// ----- leash -----
integer g_iLength = 3;
integer g_iStay = FALSE;
integer g_iTargetHandle;
integer g_iLastRank;
integer g_iStayRank;
vector g_vPos = ZERO_VECTOR;
string g_sTmpName;
key g_kCmdGiver;
key g_kLeashedTo = NULL_KEY;
integer g_bLeashedToAvi;
integer g_bFollowMode;
string g_sScript="leash_";
string CTYPE = "collar";
string WEARERNAME;

string g_sCheck;

//realleash variables
integer g_iStrictModeOn=FALSE; //default is Real-Leash OFF
integer g_iLeasherInRange=FALSE; //
integer g_iRLVOn=FALSE;     // To store if RLV was enabled in the collar
integer g_iAwayCounter=0;

list g_lRestrictionNames= ["fartouch","sittp","tplm","tplure","tploc"];
string RLV_STRING = "rlvmain_on";
string OWNER_STRING = "auth_owner";
// ---------------------------------------------
// ------ FUNCTION DEFINITIONS ------


/*
integer g_iProfiled;
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

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth){
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    //Debug("Made menu.");
    return kID;
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else{
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

integer CheckCommandAuth(key kCmdGiver, integer iAuth){
    // Check for invalid auth
    if (iAuth < COMMAND_OWNER && iAuth > COMMAND_WEARER) return FALSE;
    
    // If leashed, only move leash if Comm Giver outranks current leasher
    if (g_kLeashedTo != NULL_KEY && iAuth > g_iLastRank){
        Notify(kCmdGiver, "Sorry, someone who outranks you on " + WEARERNAME +"'s " + CTYPE + " leashed " + WEARERNAME + " already.", FALSE);

        return FALSE;
    }
    return TRUE;
}

SetLength(integer iIn){
    g_iLength = iIn;
    // llTarget needs to be changed to the new length if leashed
    if(g_kLeashedTo){
        llTargetRemove(g_iTargetHandle);
        g_iTargetHandle = llTarget(g_vPos, g_iLength);
    }
}

ApplyRestrictions(){
    //Debug("Applying Restrictions");
    if (g_iLeasherInRange){
        if (g_iStrictModeOn){
            if (g_kLeashedTo){
                //Debug("Setting restrictions");
                llMessageLinked(LINK_SET, RLV_CMD, "fartouch=n,sittp=n,tplm=n,tplure=n,tploc=n,tplure:" + (string) g_kLeashedTo + "=add", "realleash");     //set all restrictions
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

// Wrapper for DoLeash with notifications
integer LeashTo(key kTarget, key kCmdGiver, integer iAuth, list lPoints, integer iFollowMode){
    // can't leash wearer to self.
    if (kTarget == g_kWearer) return FALSE;
    
    if (!CheckCommandAuth(kCmdGiver, g_iLastRank)){
        return FALSE;
    }
    
    if (g_kLeashedTo==kTarget) return TRUE;
    
    if (g_kLeashedTo){
        DoUnleash();
    }
    integer bCmdGiverIsAvi=llGetAgentSize(kCmdGiver) != ZERO_VECTOR;
    integer bTargetIsAvi=llGetAgentSize(kTarget) != ZERO_VECTOR;

    // Send notices to wearer, leasher, and target
    // Only send notices if Leasher is an AV, as objects normally handle their own messages for such things
    if (bCmdGiverIsAvi) {
        string sTarget = llGetDisplayName(kTarget);
        if (sTarget == "???" || sTarget == "") sTarget = llKey2Name(kTarget);
        string sCmdGiver = llGetDisplayName(kCmdGiver);
        if (sCmdGiver == "???" || sCmdGiver == "") sCmdGiver = llKey2Name(kCmdGiver);
        string sWearMess;
        if (kCmdGiver == g_kWearer) {// Wearer is Leasher
            if (iFollowMode){
                sWearMess = "You begin following " + sTarget + ".";
            } else {
                //sCmdMess = ""; // Only one message will need to be sent
                sWearMess = "You take your leash";
                if (bTargetIsAvi) { // leashing self to someone else
                    sWearMess += ", and hand it to " + sTarget + ".";
                } else { // leashing self to an object
                    sWearMess += ", and tie it to " + sTarget + ".";
                }
            }
        } else {// Leasher is not Wearer
            string sCmdMess;
            if (iFollowMode){
                if (kCmdGiver != kTarget) { // LeashTo someone else
                    Notify(kTarget, sCmdGiver + " commands " + WEARERNAME + " to follow you.", FALSE);
                    sCmdMess= "You command " + WEARERNAME + " to follow " + sTarget + ".";
                    sWearMess = sCmdGiver + " commands you to follow " + sTarget + ".";
                } else {
                    sCmdMess= "You command " + WEARERNAME + " to follow you.";
                    sWearMess = sCmdGiver + " commands you to follow them.";
                }
            } else {
                string sPsv = "'s"; // Possessive, will vary if name ends in "s"
                if (llGetSubString(WEARERNAME, -1,-1)=="s") sPsv = "'";
                sCmdMess= "You grab " + WEARERNAME + sPsv + " leash";
                sWearMess = sCmdGiver + " grabs your leash";
                if (kCmdGiver != kTarget) { // Leasher is not LeashTo
                    if (bTargetIsAvi) { // LeashTo someone else
                        sCmdMess += ", and hand it to " + sTarget + ".";
                        sWearMess += ", and hands it to " + sTarget + ".";
                        Notify(kTarget, sCmdGiver + " hands you " + WEARERNAME + sPsv + " leash.", FALSE);
                    } else {// LeashTo object
                        sCmdMess += ", and tie it to " + sTarget + ".";
                        sWearMess += ", and ties it to " + sTarget + ".";
                    }
                }
            }
            Notify(kCmdGiver, sCmdMess, FALSE);
        }
        llOwnerSay(sWearMess);
    }

    g_bFollowMode = iFollowMode; // leashing, or following
    if (bTargetIsAvi) g_bLeashedToAvi = TRUE;
    if (llGetOwnerKey(kCmdGiver)==g_kWearer) iAuth=COMMAND_WEARER;   //prevents owner-wearer with public access creating an unbreakable leash to an unwilling participant
    DoLeash(kTarget, iAuth, lPoints);
    
    // Notify Target how to unleash, only if:
    // Avatar
    // Didn't send the command
    // Don't own the object that sent the command
    if (g_bLeashedToAvi && kCmdGiver != kTarget && llGetOwnerKey(kCmdGiver) != kTarget) {
        if (iFollowMode){
            llMessageLinked(LINK_SET, POPUP_HELP, WEARERNAME + " has been commanded to follow you.  Say \"_PREFIX_unfollow\" to relase them.", g_kLeashedTo);
        } else {
            llMessageLinked(LINK_SET, POPUP_HELP, WEARERNAME + " has been leashed to you.  Say \"_PREFIX_unleash\" to unleash them.  Say \"_PREFIX_giveholder\" to get a leash holder.", g_kLeashedTo);
        }
    }
    return TRUE;
}

DoLeash(key kTarget, integer iAuth, list lPoints){
    g_iLastRank = iAuth;
    g_kLeashedTo = kTarget;

    if (g_bFollowMode) {
        llMessageLinked(LINK_THIS, COMMAND_PARTICLE, "unleash", g_kLeashedTo);
    } else {
        integer iPointCount = llGetListLength(lPoints);
        g_sCheck = "";  
        if (iPointCount) {//if more than one leashpoint, listen for all strings, else listen just for that point
            if (iPointCount == 1) g_sCheck = (string)llGetOwnerKey(kTarget) + llList2String(lPoints, 0) + " ok";
        }
        //Send link message to the particle script
        //Debug("leashing with "+g_sCheck);
        llMessageLinked(LINK_THIS, COMMAND_PARTICLE, "leash" + g_sCheck + "|" + (string)g_bLeashedToAvi, g_kLeashedTo);
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
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + TOK_DEST + "=" + (string)kTarget + "," + (string)iAuth + "," + (string)g_bLeashedToAvi + "," + (string)g_bFollowMode, "");
    

    g_iLeasherInRange=TRUE;
    ApplyRestrictions();
}

// Wrapper for DoUnleash()
Unleash(key kCmdGiver)
{
    string sTarget = llGetDisplayName(g_kLeashedTo);
    if (sTarget == "???" || sTarget == "") sTarget = llKey2Name(g_kLeashedTo);
    if ( (key)g_kLeashedTo ){
        string sCmdGiver = llGetDisplayName(kCmdGiver);
        if (sCmdGiver == "???" || sCmdGiver == "") sCmdGiver = llKey2Name(kCmdGiver);
        string sWearMess;
        string sCmdMess;
        string sTargetMess;
        
        integer bCmdGiverIsAvi=llGetAgentSize(kCmdGiver) != ZERO_VECTOR;
    
        if (bCmdGiverIsAvi) {
            if (kCmdGiver == g_kWearer) // Wearer is Leasher
            {
                if (g_bFollowMode) {
                    sWearMess = "You stop following " + sTarget + ".";
                    sTargetMess = WEARERNAME + " stops following you.";
                } else {
                    sWearMess = "You unleash yourself from " + sTarget + "."; // sTarget might be an object
                    sTargetMess = WEARERNAME + " unleashes from you.";
                }
                if (g_bLeashedToAvi) Notify(g_kLeashedTo, sTargetMess, FALSE);
            } else { // Unleasher is not Wearer
                if (kCmdGiver == g_kLeashedTo) {
                    if (g_bFollowMode) {
                        sCmdMess= "You release " + WEARERNAME + " from following you.";
                        sWearMess = sCmdGiver + " releases you from following.";
                    } else {
                        sCmdMess= "You unleash " + WEARERNAME + ".";
                        sWearMess = sCmdGiver + " unleashes you.";
                    }
                } else {
                    if (g_bFollowMode) {
                        sCmdMess= "You release " + WEARERNAME + " from following " + sTarget + ".";
                        sWearMess = sCmdGiver + " releases you from following " + sTarget + ".";
                        sTargetMess = WEARERNAME + " stops following you.";
                    } else {
                        sCmdMess= "You unleash  " + WEARERNAME + " from " + sTarget + ".";
                        sWearMess = sCmdGiver + " unleashes you from " + sTarget + ".";
                        sTargetMess = sCmdGiver + " unleashes " + WEARERNAME + " from you.";
                    }
                    if (g_bLeashedToAvi) Notify(g_kLeashedTo, sTargetMess, FALSE);
                }
                Notify(kCmdGiver, sCmdMess, FALSE);
            }
            llOwnerSay(sWearMess);
        }
        DoUnleash();
    } else {
        Notify(kCmdGiver, WEARERNAME+" is not leashed", FALSE);
    }
}

DoUnleash(){
    llTargetRemove(g_iTargetHandle);
    llStopMoveToTarget();
    llMessageLinked(LINK_SET, COMMAND_PARTICLE, "unleash", g_kLeashedTo);
    g_kLeashedTo = NULL_KEY;
    g_iLastRank = COMMAND_EVERYONE;
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + TOK_DEST, "");
    llSetTimerEvent(0.0);   //stop checking for leasher out of range
    g_iLeasherInRange=FALSE;

    ApplyRestrictions();
}

YankTo(key kIn){
    llMoveToTarget(llList2Vector(llGetObjectDetails(kIn, [OBJECT_POS]), 0), 0.5);
    llSleep(2.0);
    llStopMoveToTarget();    
}

integer UserCommand(integer iAuth, string sMessage, key kMessageID, integer bFromMenu){
    //Debug("Got user comand:\niAuth: "+(string)iAuth+"\nsMessage: "+sMessage+"\nkMessageID: "+(string)kMessageID+"\nbFromMenu: "+(string)bFromMenu);
    if (iAuth >= COMMAND_OWNER && iAuth <= COMMAND_WEARER) {
        g_kCmdGiver = kMessageID;
        list lParam = llParseString2List(sMessage, [" "], []);
        string sComm = llToLower(llList2String(lParam, 0));
        string sVal = llToLower(llList2String(lParam, 1));
        string sVal2= llList2String(lParam, 2);
        
        sMessage = llToLower(sMessage);  //convert sMessage to lower case for caseless comparisson
        //debug(sMessage);
        if (sMessage=="leashmenu" || sMessage == "menu leash"){
            list lButtons;
            if (g_iStrictModeOn==TRUE) {
                lButtons += "Strict ☒";
            } else {
                lButtons += "Strict ☐";
            }
             
            if (kMessageID != g_kWearer) lButtons += "Grab";// Only if not the wearer.
            else lButtons += [" "];

            if (g_kLeashedTo != NULL_KEY) {
                if (g_bFollowMode) lButtons += ["Unfollow"];
                else lButtons += ["Unleash"];
            }
            else lButtons += " ";

            lButtons += ["LeashTo","Post"];
            //lButtons += ["give Post"];

            if (kMessageID == g_kLeashedTo) lButtons += "Yank";//only if leash holder 
            else lButtons += " ";
            
            lButtons += ["FollowTarget"];

            if (g_iStay) lButtons += ["UnStay"];
            else lButtons += ["Stay"];

            lButtons += ["give Holder"];

            lButtons += ["Length"];

            
            lButtons += g_lButtons;
            
            string sPrompt = "\nLet's go walkies!\n\nwww.opencollar.at/leash";
            g_kMainDialogID = Dialog(kMessageID, sPrompt, lButtons, [BUTTON_UPMENU], 0, iAuth);
            
        
            
        } else  if (sComm == "post") {
            if (sComm == "post" && !bFromMenu) UserCommand(iAuth, "find"+sMessage, kMessageID ,bFromMenu);   //hack to keep old chat comand behaviour
            else if (sVal==llToLower(BUTTON_UPMENU)){
                UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            } else if (sMessage == "post give post") {
                UserCommand(iAuth, "givepost", kMessageID ,bFromMenu);
            } else if (sMessage == "post rez post") {
                UserCommand(iAuth, "rezpost", kMessageID ,bFromMenu);
            } else if (sMessage == "post find post") {
                UserCommand(iAuth, "findpost", kMessageID ,bFromMenu);
            } else {
                g_kPostMenuDialogID = Dialog(kMessageID, "\n\nPost Options:", ["Find Post", "Rez Post", "give Post"], [BUTTON_UPMENU], 0, iAuth);
            }
        } else  if (sMessage == "grab" || sMessage == "leash" || (sMessage == "toggleleash" && NULL_KEY == g_kLeashedTo)) {
            LeashTo(kMessageID, kMessageID, iAuth, ["handle"], FALSE);
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            
        } else if(sComm == "follow" || sComm == "followtarget") {
            //Debug("Got a follow command:"+sMessage);
            if (!CheckCommandAuth(kMessageID, iAuth)) return TRUE;
            if (sVal==llToLower(BUTTON_UPMENU)){
                UserCommand(iAuth, "leash", kMessageID ,bFromMenu);
            } else if (sVal == ""){
                g_kFollowTargetDialogID=llGenerateKey();
                llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|Who shall be followed?|0|``"+(string)AGENT+"`10`"+(string)PI + "|BACK|" + (string)iAuth, g_kFollowTargetDialogID);
            } else if (sVal == "me") {
                LeashTo(kMessageID, kMessageID, iAuth, [], TRUE);
            }   else if ((key)sVal) {
                LeashTo((key)sVal, kMessageID, iAuth, [], TRUE);
                //no remenu to leash menu
                //if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            } else {
                g_kFollowTargetDialogID=llGenerateKey();
                llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|Who shall be followed?|0|``"+(string)AGENT+"`10`"+(string)PI +"`"+sVal+"`1|BACK|" + (string)iAuth, g_kFollowTargetDialogID);
            }
            
        } else if (sMessage == "runaway" && iAuth == COMMAND_OWNER) Unleash(kMessageID);
        
        else if (sMessage == "unleash" || sMessage == "unfollow" || (sMessage == "toggleleash" && NULL_KEY != g_kLeashedTo)) {
            if (CheckCommandAuth(kMessageID, iAuth)) Unleash(kMessageID);
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            
        } else if (sMessage == "giveholder" || sMessage == "give holder") {
            llGiveInventory(kMessageID, "Leash Holder");
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            
        } else if (sMessage == "givepost" || sMessage == "give post") {
            llGiveInventory(kMessageID, "Grabby Post");
            if (bFromMenu) UserCommand(iAuth, "post", kMessageID ,bFromMenu);
            
        } else if (sMessage == "rezpost" || sMessage == "rez post") {
            llRezObject("Grabby Post", llGetPos() + (<0.1, 0.0, 0.37> * llGetRot()), ZERO_VECTOR, llEuler2Rot(<0, 90, 270> * DEG_TO_RAD), 0);
            if (bFromMenu) UserCommand(iAuth, "post", kMessageID ,bFromMenu);
            
        } else if (sMessage == "yank" && kMessageID == g_kLeashedTo) {
            //Person holding the leash can yank.
            if(llGetAgentInfo(g_kWearer)&AGENT_SITTING) llMessageLinked(LINK_SET, RLV_CMD, "unsit=force", "realleash");
            YankTo(kMessageID);
            
        } else if (sMessage == "beckon" && iAuth == COMMAND_OWNER) {
            //Owner can beckon
            YankTo(kMessageID);
            
        } else if (sMessage == "stay") {
            if (iAuth <= COMMAND_GROUP) {
                g_iStayRank = iAuth;
                g_iStay = TRUE;
                string sCmdGiver = llGetDisplayName(kMessageID);
                if (sCmdGiver == "???" | sCmdGiver == "") sCmdGiver = llKey2Name(kMessageID);
                llRequestPermissions(g_kWearer, PERMISSION_TAKE_CONTROLS);
                llOwnerSay(sCmdGiver + " commanded you to stay in place, you cannot move until the command is revoked again.");
                Notify(kMessageID, "You commanded " + WEARERNAME + " to stay in place. Either leash the slave with the grab command or use \"unstay\" to enable movement again.", FALSE);
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            }
            
        } else if ((sMessage == "unstay" || sMessage == "move") && g_iStay) {
            if (iAuth <= g_iStayRank) {
                g_iStay = FALSE;
                llReleaseControls();
                llOwnerSay("You are free to move again.");
                Notify(kMessageID,"You allowed " + WEARERNAME + " to move freely again.", FALSE);
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            }

        } else if (sMessage == "strict on" || sMessage == "strict ☐") {
            g_iStrictModeOn=TRUE;
            llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + "strict=1", "");
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, TOK_DEST, "");  //query current leasher, the response will trigger ApplyRestrictions
            Notify(kMessageID,"Strict leashing enabled.",TRUE);
            ApplyRestrictions();
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            
        } else if (sMessage == "strict off" || sMessage == "strict ☒") {
            if (g_kLeashedTo) {
                Notify(kMessageID, "You can't disable Strict Mode while leashed.",FALSE);
            } else {
                g_iStrictModeOn=FALSE;
                llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript + "strict", "");
                ApplyRestrictions();
                Notify(kMessageID,"Strict leashing disabled.",FALSE);
            }
            if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            
        } else if (sComm == "leashto") {
            if (!CheckCommandAuth(kMessageID, iAuth)) return TRUE;
            if (sVal==llToLower(BUTTON_UPMENU)){
                UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            } else if (sVal == "") {
                g_kLeashTargetDialogID=llGenerateKey();
                llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|Who shall we leash to?|0|``"+(string)AGENT+"`10`"+(string)PI + "|BACK|" + (string)iAuth, g_kLeashTargetDialogID);
            } else if((key)sVal) {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                //debug("leash target is key");//could be a post, or could be we specified an av key
                LeashTo((key)sVal, kMessageID, iAuth, lPoints, FALSE);
                //remenu to sensor dialog
                //if (bFromMenu) UserCommand(iAuth, "leashto", kMessageID ,bFromMenu);
            } else {
                g_kLeashTargetDialogID=llGenerateKey();
                llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|Who shall we leash to?|0|``"+(string)AGENT+"`10`"+(string)PI +"`"+sVal+"`1|BACK|" + (string)iAuth, g_kLeashTargetDialogID);
            }
            
        } else if (sComm == "length") {
            integer iNewLength = (integer)sVal;
            if (sVal==llToLower(BUTTON_UPMENU)){
                UserCommand(iAuth, "leash", kMessageID ,bFromMenu);
            } else if(iNewLength > 0 && iNewLength <= 30){
                //Person holding the leash can always set length.
                if (kMessageID == g_kLeashedTo || CheckCommandAuth(kMessageID, iAuth)) 
                {
                    SetLength(iNewLength);
                    //tell wearer  
                    Notify(kMessageID, "Leash length set to " + (string)g_iLength+"m.", TRUE);        
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + TOK_LENGTH + "=" + sVal, "");
                }
                if (bFromMenu) UserCommand(iAuth, "leashmenu", kMessageID ,bFromMenu);
            }
            else { //no value given, or value out of range, must be from chat, give menu
                Notify(kMessageID, "The current leash length is " + (string)g_iLength + "m.", TRUE);
                //LengthMenu(kMessageID,iAuth);
                g_kSetLengthDialogID = Dialog(kMessageID, "\n\nSet a leash length in meter:\nCurrent length is: " + (string)g_iLength + "m", ["1", "2", "3", "4", "5", "8","10" , "15", "20", "25", "30"], [BUTTON_UPMENU], 0, iAuth);
            }
            
        } else if (sComm == "findpost" || sMessage == "find post") {
            if (!CheckCommandAuth(kMessageID, iAuth)) {
                if (bFromMenu) UserCommand(iAuth, "post", kMessageID ,bFromMenu);
                return TRUE;
            }
            if (sVal==llToLower(BUTTON_UPMENU)){
                UserCommand(iAuth, "post", kMessageID ,bFromMenu);
            } else if (sVal == ""){// no parameters were passed
                g_kPostTargetDialogID=llGenerateKey();
                llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|\n\nWhat's going to serve us as a post? If the desired object isn't on the list, please try moving closer.\n|0|``"+(string)(PASSIVE | ACTIVE)+"`10`"+(string)PI + "|BACK|" + (string)iAuth, g_kPostTargetDialogID);
            } else if((key)sVal) {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                //debug("leash target is key");//could be a post, or could be we specified an av key
                if (bFromMenu) UserCommand(iAuth, "findpost", kMessageID ,bFromMenu);
                LeashTo((key)sVal, kMessageID, iAuth, lPoints, FALSE);
            } else {
                g_kPostTargetDialogID=llGenerateKey();
                llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|chatmode|0|``"+(string)(PASSIVE | ACTIVE)+"`10`"+(string)PI +"`"+sVal+"`1|BACK|" + (string)iAuth, g_kPostTargetDialogID);
            }
            
        }
    } else if (iAuth == COMMAND_EVERYONE) {
        if (kMessageID == g_kLeashedTo) {
            sMessage = llToLower(sMessage);
            if (sMessage == "unleash" || sMessage == "unfollow" || (sMessage == "toggleleash" && NULL_KEY != g_kLeashedTo)) Unleash(kMessageID);
            else if (sMessage == "giveholder") llGiveInventory(kMessageID, "Leash Holder");
            else if (sMessage == "yank") YankTo(kMessageID);
        }
    } else return FALSE;
    return TRUE;
}

default {
    on_rez(integer start_param) {
        DoUnleash();
    }
    
    state_entry() {
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        g_kWearer = llGetOwner();
        WEARERNAME = llKey2Name(g_kWearer);  //quick and dirty default, will get replaced by value from settings
        llMinEventDelay(0.3);
        
        DoUnleash();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, RLV_STRING, "");
        //Debug("Starting");
    }
    
    timer() {
        
        //inlined old isInSimOrJustOutside function
        vector vLeashedToPos=llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
        integer iIsInSimOrJustOutside=TRUE;
        if(vLeashedToPos == ZERO_VECTOR || vLeashedToPos.x < -25 || vLeashedToPos.x > 280 || vLeashedToPos.y < -25 || vLeashedToPos.y > 280) iIsInSimOrJustOutside=FALSE;
        
        
        if (iIsInSimOrJustOutside && llVecDist(llGetPos(),vLeashedToPos)<60)    //if the leasher is now in range
        {
            if(!g_iLeasherInRange)  //and the leasher was previously not in range
            {
                if (g_iAwayCounter)
                {
                    g_iAwayCounter = 0;
                    llSetTimerEvent(3.0);
                }
                //Debug("leashing with "+g_sCheck);
                llMessageLinked(LINK_THIS, COMMAND_PARTICLE, "leash" + g_sCheck + "|" + (string)g_bLeashedToAvi, g_kLeashedTo);
                g_iLeasherInRange = TRUE;
                
                llTargetRemove(g_iTargetHandle);
                g_vPos = vLeashedToPos;
                g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
                if (g_vPos != ZERO_VECTOR) llMoveToTarget(g_vPos, 0.7);
                ApplyRestrictions();
            }
        }
        else    //the leasher is not now in range
        {
            if(g_iLeasherInRange)   //but was a short while ago
            {
                if (g_iAwayCounter > 3)
                {
                    llTargetRemove(g_iTargetHandle);
                    llStopMoveToTarget();
                    llMessageLinked(LINK_THIS, COMMAND_PARTICLE, "unleash", g_kLeashedTo);
                    g_iLeasherInRange=FALSE;
                    ApplyRestrictions();
                }
            }
            
            g_iAwayCounter++; //+1 every 3 secs
            if (g_iAwayCounter > 200) //3mins 20 secs
            {//slow down the sensor:
                g_iAwayCounter = 1;
                llSetTimerEvent(11.0);
            }
        }
    }
    link_message(integer iPrim, integer iNum, string sMessage, key kMessageID){
        if (UserCommand(iNum, sMessage, kMessageID, FALSE)) return;
        else if (iNum == MENUNAME_REQUEST  && sMessage == BUTTON_PARENTMENU) {
            //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, BUTTON_PARENTMENU + "|" + BUTTON_SUBMENU, "");
            g_lButtons = [] ; // flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, BUTTON_SUBMENU, "");
        } else if (iNum == MENUNAME_RESPONSE) {
            list lParts = llParseString2List(sMessage, ["|"], []);
            if (llList2String(lParts, 0) == BUTTON_SUBMENU) {//someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1) {
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        } else if (iNum == COMMAND_SAFEWORD) {
            g_iStay = FALSE;
            llReleaseControls();
            DoUnleash();
        } else if (iNum == LM_SETTING_RESPONSE) {
            integer iInd = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, iInd -1);
            string sValue = llGetSubString(sMessage, iInd + 1, -1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript) {
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
               }
                else if (sToken == TOK_LENGTH) SetLength((integer)sValue);
                if (sToken=="strict"){
                    g_iStrictModeOn = (integer)sValue;
                    ApplyRestrictions();
                }
            } else if (sToken == RLV_STRING) { // something enabled or disabled RLV.  Remember which
                //Debug("SetRLV:"+sValue);
                g_iRLVOn = (integer)sValue;
                ApplyRestrictions();
            } else if (sToken == "Global_CType") CTYPE = sValue;
             else if (sToken=="Global_WearerName") WEARERNAME=sValue;
            //else //Debug("setting response:"+sToken);
        } else if (iNum == DIALOG_RESPONSE) {
            list lMenuParams = llParseString2List(sMessage, ["|"], []);
            key kAV = (key)llList2String(lMenuParams, 0);          
            string sButton = llList2String(lMenuParams, 1);
            integer iAuth = (integer) llList2String(lMenuParams, 3);
            if (kMessageID == g_kMainDialogID){
                if (sButton == BUTTON_UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu "+BUTTON_PARENTMENU, kAV); 
                } else if (~llListFindList(g_lButtons, [sButton])){    //process buttons other scripts added
                    llMessageLinked(LINK_SET, iAuth, "menu "+sButton, kAV);
                } else { // catch all
                    UserCommand(iAuth, llToLower(sButton), kAV, TRUE);
                }
            }
            else if (kMessageID == g_kLeashTargetDialogID) UserCommand(iAuth, "leashto " + sButton, kAV, TRUE);
            else if (kMessageID == g_kFollowTargetDialogID) UserCommand(iAuth, "follow " + sButton, kAV, TRUE);
            else if (kMessageID == g_kPostTargetDialogID) UserCommand(iAuth, "findpost " + sButton, kAV, TRUE);
            else if (kMessageID == g_kSetLengthDialogID) UserCommand(iAuth, "length " + sButton, kAV, TRUE);
            else if (kMessageID == g_kPostMenuDialogID) UserCommand(iAuth, "post " + sButton, kAV, TRUE);
        }
    }

    at_target(integer iNum, vector vTarget, vector vMe){
        llStopMoveToTarget();
        llTargetRemove(g_iTargetHandle);
        g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
        g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
        if(g_iJustMoved) {
            vector pointTo = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0) - llGetPos();
            float  turnAngle = llAtan2(pointTo.x, pointTo.y);// - myAngle;
            llMessageLinked(LINK_SET, RLV_CMD, "setrot:" + (string)(turnAngle) + "=force", NULL_KEY);   //transient command, doesn;t need our fakekey
            g_iJustMoved = 0;
        }   
    }
    
    not_at_target() {
        g_iJustMoved = 1;
        // i ran into a problem here which seems to be "speed" related, specially when using the menu to unleash this event gets triggered together or just after the CleanUp() function
        //to prevent to get stay in the target events i added a check on g_kLeashedTo is NULL_KEY
        if(g_kLeashedTo) {
            vector vNewPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
            //llStopMoveToTarget();
            if (g_vPos != vNewPos) {
                llTargetRemove(g_iTargetHandle);
                g_vPos = vNewPos;
                g_iTargetHandle = llTarget(g_vPos, (float)g_iLength);
            }
            if (g_vPos != ZERO_VECTOR) llMoveToTarget(g_vPos,0.7);
            else llStopMoveToTarget();
        } else {
            DoUnleash();
        }
    }
  
    run_time_permissions(integer iPerm)
    {
        if (iPerm & PERMISSION_TAKE_CONTROLS) {
            //disbale all controls but left mouse button (for stay cmd)
            llTakeControls(CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_LBUTTON | CONTROL_ML_LBUTTON, FALSE, FALSE);
        }
    }
    
    changed (integer change){
        if (change & CHANGED_OWNER){
            g_kWearer = llGetOwner();
        }
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
