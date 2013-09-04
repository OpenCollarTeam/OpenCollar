//OpenCollar - leash
//leash script for the Open Collar Project (c)
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

// -------------------------------
// Original leash scripting & ongoing updates
// Author: Nandana Singh
// Date: Oct. 18, 2008
// -------------------------------
// Rewrite & various updates
// Author: Lulu Pink
// -------------------------------
// Various updates
// Author: Garvin Twine
// -------------------------------
// Edited & Added integration for particle-system to OC Settings & Dialog Subsystems (3.421)
// Author: Joy Stipe
// -------------------------------
//April 2010 splitting of the particle part into its own script April 2010
// Author: Garvin Twine
// -------------------------------

// ------ TOKEN DEFINITIONS ------
// ---- Immutable ----
// - Should be constant across collars, so not prefixed
// --- db tokens ---
string TOK_LENGTH   = "leashlength";
string TOK_ROT      = "leashrot";
string TOK_DEST     = "leashedto"; // format: uuid,rank
// --- channel tokens ---
// - MESSAGE MAP
//integer COMMAND_NOAUTH      = 0;
integer COMMAND_OWNER       = 500;
integer COMMAND_SECOWNER    = 501;
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
integer DIALOG_TIMEOUT      = -9002;

integer COMMAND_PARTICLE     = 20000;
integer COMMAND_LEASH_SENSOR = 20001;

// --- menu button tokens ---
string BUTTON_UPMENU       = "^";
string BUTTON_PARENTMENU   = "Main";
string BUTTON_SUBMENU      = "Leash";
string BUTTON_LEASH        = "Grab";
string BUTTON_LEASH_TO     = "LeashTo";
string BUTTON_FOLLOW       = "Follow Me";
string BUTTON_FOLLOW_MENU  = "FollowTarget";
string BUTTON_UNLEASH      = "Unleash";
string BUTTON_UNFOLLOW     = "Unfollow";
string BUTTON_STAY         = "Stay";
string BUTTON_UNSTAY       = "UnStay";
string BUTTON_ROT          = "Rotate";
string BUTTON_UNROT        = "Don't Rotate";
string BUTTON_LENGTH       = "Length";
string BUTTON_GIVE_HOLDER  = "give Holder";
string BUTTON_GIVE_POST    = "give Post";
string BUTTON_REZ_POST     = "Rez Post";
string BUTTON_POST         = "Post";
string BUTTON_YANK         = "Yank";

// --- tokens for g_iSensorMode ---
// - to remember what the sensor is tracking
// sensors for chat
integer SENSORMODE_FIND_TARGET_FOR_LEASH_CHAT   = 1;
integer SENSORMODE_FIND_TARGET_FOR_FOLLOW_CHAT  = 2;
integer SENSORMODE_FIND_TARGET_FOR_POST_CHAT    = 3;
// sensors for menus
integer SENSORMODE_FIND_TARGET_FOR_LEASH_MENU   = 100;
integer SENSORMODE_FIND_TARGET_FOR_FOLLOW_MENU  = 101;
integer SENSORMODE_FIND_TARGET_FOR_POST_MENU    = 102;

// ---------------------------------------------
// ------ VARIABLE DEFINITIONS ------
// ----- menu -----
integer g_iReturnMenu; // asynchronous menu callback after sensor
key g_kMenuUser;
key g_kMainDialogID;
key g_kSetLengthDialogID;
key g_kLeashTargetDialogID;
key g_kFollowTargetDialogID;
key g_kPostTargetDialogID;
list g_lButtons;
// ----- collar -----
string g_sWearer;
key g_kWearer;
integer g_iJustMoved;
// ----- leash -----
float g_fLength = 3.0;
float g_fScanRange = 10.0;
integer g_iStay = FALSE;
integer g_iRot = TRUE;
integer g_iTargetHandle;
integer g_iLastRank;
integer g_iStayRank;
vector g_vPos = ZERO_VECTOR;
integer g_iSensorMode;
string g_sTmpName;
key g_kCmdGiver;
key g_kLeashedTo = NULL_KEY;
integer g_bLeashedToAvi;
integer g_bFollowMode;
string g_sScript;
string CTYPE = "collar";

list g_lLengths = ["1", "2", "3", "4", "5", "8","10" , "15", "20", "25", "30"];
//list g_lPartPoints; // DoLeash function- priority given to last item in list. so if list is ["collar", "handle"], and we've heard from the handle and particles are going there, we'll ignore any responses from "collar"
// integer iLoop;//testing how it works with it a golable
// ---------------------------------------------
// ------ FUNCTION DEFINITIONS ------
// Debug Messages - commenting all debug out saves over 3K mem on this script
debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

integer g_iUnixTime;

// RLV-Force avatar to face the leasher by Tapple Gao
turnToTarget(vector target)
{
    if (g_iRot)
    {
        // do not need this as we are only doint at target
        //float MAX_TURN_ANGLE = 70 * DEG_TO_RAD;
        vector pointTo = target - llGetPos();
        //vector myEuler = llRot2Euler(llGetRot());
        //float  myAngle = PI_BY_TWO - myEuler.z;
        float  turnAngle = llAtan2(pointTo.x, pointTo.y);// - myAngle;
        //while (turnAngle < -PI) turnAngle += TWO_PI;
        //while (turnAngle >  PI) turnAngle -= TWO_PI;
        //if (turnAngle < -MAX_TURN_ANGLE) turnAngle = -MAX_TURN_ANGLE;
        //if (turnAngle >  MAX_TURN_ANGLE) turnAngle =  MAX_TURN_ANGLE;
        llMessageLinked(LINK_SET, RLV_CMD, "setrot:" + (string)(turnAngle) + "=force", NULL_KEY);
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

string Float2String(float in)
{
    string out = (string)in;
    integer i = llSubStringIndex(out, ".");
    while (~i && llStringLength(llGetSubString(out, i + 2, -1)) && llGetSubString(out, -1, -1) == "0")
    {
        out = llGetSubString(out, 0, -2);
    }
    return out;
}

integer CheckCommandAuth(key kCmdGiver, integer iAuth)
{
    // Check for invalid auth
    if (iAuth < COMMAND_OWNER && iAuth > COMMAND_WEARER)
        return FALSE;
    
    // If leashed, only move leash if Comm Giver outranks current leasher
    if (g_kLeashedTo != NULL_KEY && iAuth > g_iLastRank)
    {
        string sFirstName = GetFirstName(g_sWearer);
        Notify(kCmdGiver, "Sorry, someone who outranks you on " + g_sWearer +"'s " + CTYPE + " leashed " + sFirstName + " already.", FALSE);

        return FALSE;
    }

    return TRUE;
}

LeashMenu(key kIn, integer iAuth)
{
    g_iReturnMenu = FALSE;
    list lButtons = g_lButtons;
    if (kIn != g_kWearer)
        lButtons += [BUTTON_LEASH, BUTTON_FOLLOW, BUTTON_YANK]; // Only if not the wearer.
        
    lButtons += [BUTTON_LENGTH, BUTTON_LEASH_TO, BUTTON_FOLLOW_MENU, BUTTON_GIVE_HOLDER, BUTTON_POST, BUTTON_REZ_POST, BUTTON_GIVE_POST];
    
    if (g_kLeashedTo != NULL_KEY)
    {
        if (g_bFollowMode)
            lButtons += [BUTTON_UNFOLLOW];
        else
            lButtons += [BUTTON_UNLEASH];
    }
    
    if (g_iStay)
        lButtons += [BUTTON_UNSTAY];
    else
        lButtons += [BUTTON_STAY];
    
    if (kIn == g_kWearer) // Only for wearer.
    {
        if (g_iRot)
            lButtons += [BUTTON_UNROT];
        else
            lButtons += [BUTTON_ROT];
    }

        
    string sPrompt = "Leash Options";
    g_kMainDialogID = Dialog(kIn, sPrompt, lButtons, [BUTTON_UPMENU], 0, iAuth);
}

LengthMenu(key kIn, integer iAuth)
{
    string sPrompt = "Set a leash length in meter:\nCurrent length is: " + (string)g_fLength + "m";
    g_kSetLengthDialogID = Dialog(kIn, sPrompt, g_lLengths, [BUTTON_UPMENU], 0, iAuth);
}

SetLength(float fIn)
{
    g_fLength = fIn;
    // llTarget needs to be changed to the new length if leashed
    if(g_kLeashedTo != NULL_KEY)
    {
        llTargetRemove(g_iTargetHandle);
        g_iTargetHandle = llTarget(g_vPos, g_fLength);
    }
}

// Wrapper for DoLeash with notifications
LeashTo(key kTarget, key kCmdGiver, integer iAuth, list lPoints)
{
    // can't leash wearer to self.
    if (kTarget == g_kWearer) return;

    // Send notices to wearer, leasher, and target
    // Only send notices if Leasher is an AV, as objects normally handle their own messages for such things
    if (KeyIsAv(kCmdGiver)) 
    {
        string sTarget = llKey2Name(kTarget);
        string sWearMess;
        if (kCmdGiver == g_kWearer) // Wearer is Leasher
        {
            //sCmdMess = ""; // Only one message will need to be sent
            sWearMess = "You take your leash";
            if (kTarget == g_kWearer) // self bondage - shouldn't ever happen, but just in case
            {
                //sWearMess += ""; // We could put in some sort of self-deprecating humor here ;)
            }
            else if (KeyIsAv(kTarget)) // leashing self to someone else
            {
                sWearMess += ", and hand it to " + sTarget + ".";
            }
            else // leashing self to an object
            {
                sWearMess += ", and tie it to " + sTarget + ".";
            }
        }
        else // Leasher is not Wearer
        {
            string sPsv = "'s"; // Possessive, will vary if name ends in "s"
            if (endswith(g_sWearer, "s")) sPsv = "'";
            string sCmdMess= "You grab " + g_sWearer + sPsv + " leash";
            sWearMess = llKey2Name(kCmdGiver) + " grabs your leash";
            if (kCmdGiver != kTarget) // Leasher is not LeashTo
            {
                if (kTarget == g_kWearer) // LeashTo is Wearer
                {
                    sCmdMess += ", and hand it to " + GetFirstName(g_sWearer) + ".";
                    sWearMess += ", and hands it to you.";
                }
                else if (KeyIsAv(kTarget)) // LeashTo someone else
                {
                    sCmdMess += ", and hand it to " + sTarget + ".";
                    sWearMess += ", and hands it to " + sTarget + ".";
                    Notify(kTarget, llKey2Name(kCmdGiver) + " hands you " + g_sWearer + sPsv + " leash.", FALSE);
                }
                else // LeashTo object
                {
                    sCmdMess += ", and tie it to " + sTarget + ".";
                    sWearMess += ", and ties it to " + sTarget + ".";
                }
            }
            Notify(kCmdGiver, sCmdMess, FALSE);
        }
        Notify(g_kWearer, sWearMess, FALSE);
    }

    g_bFollowMode = FALSE; // leashing, not following
    if (!g_bLeashedToAvi)
    {
        if (KeyIsAv(kTarget))
        {
            g_bLeashedToAvi = TRUE;
        }
    }
    DoLeash(kTarget, iAuth, lPoints, g_bFollowMode);
    
    // Notify Target how to unleash, only if:
    // Avatar
    // Didn't send the command
    // Don't own the object that sent the command
    if (KeyIsAv(kTarget) && kCmdGiver != kTarget && llGetOwnerKey(kCmdGiver) != kTarget)
    {
        LeashToHelp(g_kLeashedTo);
    }                              
}

// Wrapper for DoLeash with notifications
Follow(key kTarget, key kCmdGiver, integer iAuth)
{
    debug("Follow target=" + llList2CSV([kTarget, kCmdGiver, iAuth]));
    // can't leash wearer to self.
    if (kTarget == g_kWearer) return;

    // Send notices to wearer, leasher, and target
    // Only send notices if Leasher is an AV, as objects normally handle their own messages for such things
    if (KeyIsAv(kCmdGiver)) 
    {
        string sTarget = llKey2Name(kTarget);
        string sWearMess;
        if (kCmdGiver == g_kWearer) // Wearer is Leasher
        {
            //sCmdMess = ""; // Only one message will need to be sent
            sWearMess = "You begin following " + sTarget + ".";
        }
        else // Leasher is not Wearer
        {
            string sCmdMess= "You command " + g_sWearer + " to follow " + sTarget + ".";
            sWearMess = llKey2Name(kCmdGiver) + " commands you to follow " + sTarget + ".";
            if (KeyIsAv(kTarget)) // LeashTo someone else
                Notify(kTarget, llKey2Name(kCmdGiver) + " commands " + g_sWearer + " to follow you.", FALSE);
            
            Notify(kCmdGiver, sCmdMess, FALSE);
        }
        Notify(g_kWearer, sWearMess, FALSE);
    }

    g_bFollowMode = TRUE; // following, not leashing
    if (!g_bLeashedToAvi)
    {
        if (KeyIsAv(kTarget))
        {
            g_bLeashedToAvi = TRUE;
        }
    }
    DoLeash(kTarget, iAuth, [], g_bFollowMode); // sending empty list [] for lPoints

    // Notify Target how to unleash, only if:
    // Avatar
    // Didn't send the command
    // Don't own the object that sent the command
    if (KeyIsAv(kTarget) && kCmdGiver != kTarget && llGetOwnerKey(kCmdGiver) != kTarget)
    {
        FollowHelp(g_kLeashedTo);
    }                              
}

DoLeash(key kTarget, integer iAuth, list lPoints, integer bFollowMode)
{
    g_iLastRank = iAuth;
    g_kLeashedTo = kTarget;

    if (bFollowMode)
    {
        llMessageLinked(LINK_THIS, COMMAND_PARTICLE, "unleash", g_kLeashedTo);
    }
    else
    {
      integer iPointCount = llGetListLength(lPoints);
      string sCheck = "";  
      if (iPointCount)
      {//if more than one leashpoint, listen for all strings, else listen just for that point
      if (iPointCount == 1) sCheck = (string)llGetOwnerKey(kTarget) + llList2String(lPoints, 0) + " ok";
      }
      //Send link message to the particle script
      llMessageLinked(LINK_THIS, COMMAND_PARTICLE, "leash" + sCheck + "|" + (string)g_bLeashedToAvi, g_kLeashedTo);
    }

    // change to llTarget events by Lulu Pink 
    g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo, [OBJECT_POS]), 0);
    //to prevent multiple target events and llMoveToTargets
    llTargetRemove(g_iTargetHandle);
    llStopMoveToTarget();
    g_iTargetHandle = llTarget(g_vPos, g_fLength);
    if (g_vPos != ZERO_VECTOR)
    {
        //turnToTarget(g_vPos);// only at target
        llMoveToTarget(g_vPos, 0.7);
    }
    g_iUnixTime = llGetUnixTime();
    debug("DoLeash: " + g_sScript + TOK_DEST + "=" + (string)kTarget + "," + (string)iAuth + "," + (string)g_bLeashedToAvi + "," + (string)g_bFollowMode);
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + TOK_DEST + "=" + (string)kTarget + "," + (string)iAuth + "," + (string)g_bLeashedToAvi + "," + (string)g_bFollowMode, NULL_KEY);
}

// sets up a sensor callback which will leash / follow / post on chatted target.
ActOnChatTarget(string sChattedTarget, key kCmdGiver, integer iAuth, integer iSensorMode)
{
    if (llStringLength(sChattedTarget) == 0)
        return;
    
    // Locate chatted target with llSensor()
    g_iSensorMode = iSensorMode;
    g_kMenuUser = kCmdGiver;
    g_iLastRank = iAuth;
    g_sTmpName = sChattedTarget;
    if (iSensorMode == SENSORMODE_FIND_TARGET_FOR_POST_CHAT)
        llSensor("", NULL_KEY, PASSIVE | ACTIVE, g_fScanRange, PI);
    else
        llSensor("", "", AGENT, g_fScanRange, PI);
}

// sets up a sensor callback which locates potential targets to display menu for leash / follow / post
DisplayTargetMenu(key kCmdGiver, integer iAuth, integer iSensorMode)
{
    g_iSensorMode = iSensorMode;
    g_kMenuUser = kCmdGiver;
    g_iLastRank = iAuth;
    if (iSensorMode == SENSORMODE_FIND_TARGET_FOR_POST_MENU)
        llSensor("", NULL_KEY, PASSIVE | ACTIVE, g_fScanRange, PI);
    else
        llSensor("", "", AGENT, g_fScanRange, PI);
}

StayPut(key kIn, integer iAuth)
{
    g_iStayRank = iAuth;
    g_iStay = TRUE;
    llRequestPermissions(g_kWearer, PERMISSION_TAKE_CONTROLS);
    llOwnerSay(llKey2Name(kIn) + " commanded you to stay in place, you cannot move until the command is revoked again.");
    Notify(kIn, "You commanded " + g_sWearer + " to stay in place. Either leash the slave with the grab command or use \"unstay\" to enable movement again.", FALSE);
}

CleanUp()
{
    llTargetRemove(g_iTargetHandle);
    llStopMoveToTarget();
}

// Wrapper for DoUnleash()
Unleash(key kCmdGiver)
{
    string sTarget = llKey2Name(g_kLeashedTo);
    string sCmdGiver = llKey2Name(kCmdGiver);
    string sWearMess;
    string sCmdMess;
    string sTargetMess;
    
    if (KeyIsAv(kCmdGiver)) 
    {
        if (kCmdGiver == g_kWearer) // Wearer is Leasher
        {
            if (g_bFollowMode)
            {
                sWearMess = "You stop following " + sTarget + ".";
                sTargetMess = GetFirstName(g_sWearer) + " stops following you.";
            }
            else
            {
                sWearMess = "You unleash yourself from " + sTarget + "."; // sTarget might be an object
                sTargetMess = GetFirstName(g_sWearer) + " unleashes from you.";
            }
            if (KeyIsAv(g_kLeashedTo))
                Notify(g_kLeashedTo, sTargetMess, FALSE);
        }
        else // Unleasher is not Wearer
        {
            if (kCmdGiver == g_kLeashedTo)
            {
                if (g_bFollowMode)
                {
                    sCmdMess= "You release " + GetFirstName(g_sWearer) + " from following you.";
                    sWearMess = sCmdGiver + " releases you from following.";
                }
                else
                {
                    sCmdMess= "You unleash  " + g_sWearer + ".";
                    sWearMess = sCmdGiver + " unleashes you.";
                }
            }
            else
            {
                if (g_bFollowMode)
                {
                    sCmdMess= "You release " + GetFirstName(g_sWearer) + " from following " + sTarget + ".";
                    sWearMess = sCmdGiver + " releases you from following " + sTarget + ".";
                    sTargetMess = g_sWearer + " stops following you.";
                }
                else
                {
                    sCmdMess= "You unleash  " + GetFirstName(g_sWearer) + " from " + sTarget + ".";
                    sWearMess = sCmdGiver + " unleashes you from " + sTarget + ".";
                    sTargetMess = sCmdGiver + " unleashes " + GetFirstName(g_sWearer) + " from you.";
                }
                if (KeyIsAv(g_kLeashedTo))
                    Notify(g_kLeashedTo, sTargetMess, FALSE);
            }
            Notify(kCmdGiver, sCmdMess, FALSE);
        }
        Notify(g_kWearer, sWearMess, FALSE);
    }
    DoUnleash();
}

DoUnleash()
{
    CleanUp();
    llMessageLinked(LINK_THIS, COMMAND_PARTICLE, "unleash", g_kLeashedTo);
    g_kLeashedTo = NULL_KEY;
    g_iLastRank = COMMAND_EVERYONE;
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + TOK_DEST, "");
}

integer KeyIsAv(key id)
{
    return llGetAgentSize(id) != ZERO_VECTOR;
}
// Returns sName's first name
string GetFirstName(string sName)
{
    return llGetSubString(sName, 0, llSubStringIndex(sName, " ") - 1);
}

integer startswith(string haystack, string needle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
// SA: does not work in recent SL servers, as llDeleteSubString now returns an empty string whenever
// an index is out of bounds (previously, it would return the full string)
//    return llDeleteSubString(haystack, llStringLength(needle), -1) == needle;
    return llDeleteSubString(haystack + " ", llStringLength(needle), -1) == needle;
}

integer endswith(string haystack, string needle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return llDeleteSubString(" " + haystack, 0, ~llStringLength(needle)) == needle;
}

LeashToHelp(key kIn)
{
    llMessageLinked(LINK_SET, POPUP_HELP, g_sWearer + " has been leashed to you.  Say \"_PREFIX_unleash\" to unleash them.  Say \"_PREFIX_giveholder\" to get a leash holder.", kIn);
}

FollowHelp(key kIn)
{
    llMessageLinked(LINK_SET, POPUP_HELP, g_sWearer + " has been commanded to follow you.  Say \"_PREFIX_unfollow\" to relase them.", kIn);
}

YankTo(key kIn)
{
    llMoveToTarget(llList2Vector(llGetObjectDetails(kIn, [OBJECT_POS]), 0), 0.5);
    llSleep(2.0);
    llStopMoveToTarget();    
}

integer UserCommand(integer iAuth, string sMessage, key kMessageID)
{
    if (iAuth >= COMMAND_OWNER && iAuth <= COMMAND_WEARER)
    {
        string sMesL = llToLower(sMessage);
        g_kCmdGiver = kMessageID;
        list lParam = llParseString2List(sMessage, [" "], []);
        string sComm = llToLower(llList2String(lParam, 0));
        string sVal = llToLower(llList2String(lParam, 1));
        if (sMesL == "grab" || sMesL == "leash" || (sMesL == "toggleleash" && NULL_KEY == g_kLeashedTo))
        {
            if (CheckCommandAuth(kMessageID, iAuth)) LeashTo(kMessageID, kMessageID, iAuth, ["handle"]);
        }
        else if(sComm == "follow")
        {
            debug("Got a follow command");
            if (CheckCommandAuth(kMessageID, iAuth))
            {
                if (sVal == "" || sVal == "me")
                {
                    Follow(kMessageID, kMessageID, iAuth);
                }       
                else if ((key)sVal)
                {
                    Follow((key)sVal, kMessageID, iAuth);
                } 
                else
                {
                    ActOnChatTarget(sVal, kMessageID, iAuth, SENSORMODE_FIND_TARGET_FOR_FOLLOW_CHAT);
                }
            }
        }
        else if (sMesL == "runaway" && iAuth == COMMAND_OWNER) Unleash(kMessageID);
        else if (sMesL == "unleash" || sMesL == "unfollow" || (sMesL == "toggleleash" && NULL_KEY != g_kLeashedTo))
        {
            if (CheckCommandAuth(kMessageID, iAuth)) Unleash(kMessageID);
        }
        else if (sMesL == "giveholder")
        {
            llGiveInventory(kMessageID, "Leash Holder");
        }
        else if (sMesL == "givepost")
        {
            llGiveInventory(kMessageID, "Grabby Post");
        }
        else if (sMesL == "rezpost")
        {
            llRezObject("Grabby Post", llGetPos() + (<1.0, 0, 0.395> * llGetRot()), ZERO_VECTOR, llEuler2Rot(<0, 0, 0> * DEG_TO_RAD), 0);
        }
        else if (sMesL == "yank" && kMessageID == g_kLeashedTo)
        {
            //Person holding the leash can yank.
            YankTo(kMessageID);
        }
        else if (sMesL == "beckon" && iAuth == COMMAND_OWNER)
        {
            //Owner can beckon
            YankTo(kMessageID);
        }
        else if (sMesL == "stay")
        {
            if (iAuth <= COMMAND_GROUP)
            {
                StayPut(kMessageID, iAuth);
            }
        }
        else if ((sMesL == "unstay" || sMesL == "move") && g_iStay)
        {
            if (iAuth <= g_iStayRank)
            {
                g_iStay = FALSE;
                llReleaseControls();
                llOwnerSay("You are free to move again.");
                Notify(kMessageID,"You allowed " + g_sWearer + " to move freely again.", FALSE);
            }
        }
        else if(sMesL == "don't rotate" && g_iRot)
        {
            if (g_kWearer == kMessageID)
            {
                g_iRot = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + TOK_ROT + "=0", "");
            }
            else
            {
                Notify(kMessageID,"Only the wearer can change the rotate setting", FALSE);
            }
        }
        else if(sMesL == "rotate" && !g_iRot)
        {
            if (g_kWearer == kMessageID)
            {
                g_iRot = TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + TOK_ROT, "");
            }
            else
            {
                Notify(kMessageID,"Only the wearer can change the rotate setting", FALSE);
            }
        }
        else if(sMesL == "leashmenu" || sMessage == "menu " + BUTTON_SUBMENU)
        {
            if (CheckCommandAuth(kMessageID, iAuth)) LeashMenu(kMessageID, iAuth);
            else if (sMesL == "menu " + BUTTON_SUBMENU) {llMessageLinked(LINK_SET, iAuth, "menu " + BUTTON_PARENTMENU, kMessageID); return TRUE;}
        }
        else if (sComm == "leashto")
        {
            if (!CheckCommandAuth(kMessageID, iAuth)) return TRUE;
            if (sVal == "") // no parameters were passed
            {
                DisplayTargetMenu(kMessageID, iAuth, SENSORMODE_FIND_TARGET_FOR_LEASH_MENU);
            }       
            else if((key)sVal)
            {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                //debug("leash target is key");//could be a post, or could be we specified an av key
                LeashTo((key)sVal, kMessageID, iAuth, lPoints);
            }
            else
            {
                ActOnChatTarget(sVal, kMessageID, iAuth, SENSORMODE_FIND_TARGET_FOR_LEASH_CHAT);
            }
        }
        else if(sComm == "followtarget")
        {
            if (!CheckCommandAuth(kMessageID, iAuth)) return TRUE;
            DisplayTargetMenu(kMessageID, iAuth, SENSORMODE_FIND_TARGET_FOR_FOLLOW_MENU);
        }
        else if (sComm == "length")
        {
            float fNewLength = (float)sVal;
            sVal = Float2String(fNewLength);
            if(fNewLength > 0.0)
            {
                //Person holding the leash can always set length.
                if (kMessageID == g_kLeashedTo || CheckCommandAuth(kMessageID, iAuth)) 
                {
                    SetLength(fNewLength);
                    //tell wearer  
                    Notify(kMessageID, "Leash length set to " + sVal, TRUE);        
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + TOK_LENGTH + "=" + sVal, "");
                }
            }
            else Notify(kMessageID, "The current leash length is " + Float2String(g_fLength) + "m.", TRUE);
        }
        else if (sComm == "post")
        {
            if (!CheckCommandAuth(kMessageID, iAuth)) return TRUE;

            else if (sVal == "") // no parameters were passed
            {
                DisplayTargetMenu(kMessageID, iAuth, SENSORMODE_FIND_TARGET_FOR_POST_MENU);
            }       
            else if((key)sVal)
            {
                list lPoints;
                if (llGetListLength(lParam) > 2) lPoints = llList2List(lParam, 2, -1);
                //debug("leash target is key");//could be a post, or could be we specified an av key
                LeashTo((key)sVal, kMessageID, iAuth, lPoints);
            }
            else
            {
                ActOnChatTarget(sVal, kMessageID, iAuth, SENSORMODE_FIND_TARGET_FOR_POST_CHAT);
            }
        }
    }
    else if (iAuth == COMMAND_LEASH_SENSOR)
    {
        if (sMessage == "Leasher out of range")
        {// particle script sensor lost the leasher... stop to follow
            CleanUp();
        }
        else if (sMessage == "Leasher in range")
        {// particle script sensor found the leasher again, restart to follow
            llTargetRemove(g_iTargetHandle);
            g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
            g_iTargetHandle = llTarget(g_vPos, g_fLength);
            if (g_vPos != ZERO_VECTOR) llMoveToTarget(g_vPos, 0.7);
        }
    }
    else if (iAuth == COMMAND_EVERYONE)
    {
        if (kMessageID == g_kLeashedTo)
        {
            string sMesL = llToLower(sMessage);
            if (sMesL == "unleash" || sMesL == "unfollow" || (sMesL == "toggleleash" && NULL_KEY != g_kLeashedTo))
            {
                Unleash(kMessageID);
            }
            else if (sMesL == "giveholder")
            {
                llGiveInventory(kMessageID, "Leash Holder");
            }
            else if (sMesL == "yank")
            {
                YankTo(kMessageID);
            }
        }
    }
    else return FALSE;
    if (g_iReturnMenu) LeashMenu(kMessageID, iAuth);
    return TRUE;
}
// ---------------------------------------------
// ------ IMPLEMENTATION ------
default
{
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        //debug("statentry:"+(string)llGetFreeMemory( ));
        g_kWearer = llGetOwner();
        g_sWearer = llKey2Name(g_kWearer);
        llMinEventDelay(0.3);
        //g_sMyID =  llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 2);
        DoUnleash();
        //llOwnerSay("stateentryend:"+(string)llGetFreeMemory());
    }
    
    on_rez(integer start_param)
    {
        llResetScript();
    }
    
    link_message(integer iPrim, integer iNum, string sMessage, key kMessageID)
    {
        //only respond to owner, secowner, group, wearer, and "everyone" for unleashing themselves
        if (UserCommand(iNum, sMessage, kMessageID)) return;
        else if (iNum == MENUNAME_REQUEST)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, BUTTON_PARENTMENU + "|" + BUTTON_SUBMENU, NULL_KEY);
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            list lParts = llParseString2List(sMessage, ["|"], []);
            if (llList2String(lParts, 0) == BUTTON_SUBMENU)
            {//someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1)
                {
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        }
        else if (iNum == COMMAND_SAFEWORD)
        {
            if(g_iStay)
            {
                g_iStay = FALSE;
                llReleaseControls();
            }
            DoUnleash();
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            integer iInd = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, iInd -1);
            string sValue = llGetSubString(sMessage, iInd + 1, -1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == TOK_DEST)
                {
                    //we got the last leasher's id and rank from the local settings
                    list lParam = llParseString2List(llGetSubString(sMessage, iInd + 1, -1), [","], []);
                    key kTarget = (key)llList2String(lParam, 0);
                    g_bLeashedToAvi = (integer)llList2String(lParam, 2);
                    g_bFollowMode = (integer)llList2String(lParam, 3);
                    list lPoints;
                    if (g_bLeashedToAvi)
                    {
                        lPoints = ["collar", "handle"];
                    }
                    // if PostedTo object has vanished, clear out the leash settings
                    if (!llGetObjectPrimCount(kTarget) && !g_bLeashedToAvi) DoUnleash();
                    else DoLeash(kTarget, (integer)llList2String(lParam, 1), lPoints, g_bFollowMode);
                }
                else if (sToken == TOK_LENGTH) SetLength((float)sValue);
                else if (sToken == TOK_ROT) g_iRot = (integer)sValue;
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kMessageID != g_kMainDialogID 
                && kMessageID != g_kSetLengthDialogID
                && kMessageID != g_kLeashTargetDialogID
                && kMessageID != g_kFollowTargetDialogID
                && kMessageID != g_kPostTargetDialogID) return;  // it's not for us
            list lMenuParams = llParseString2List(sMessage, ["|"], []);
            key kAV = (key)llList2String(lMenuParams, 0);          
            string sButton = llList2String(lMenuParams, 1);
            integer iAuth = (integer) llList2String(lMenuParams, 3);
            if (kMessageID == g_kMainDialogID)
            {
                if (sButton == BUTTON_UPMENU) { llMessageLinked(LINK_SET, iAuth, "menu "+BUTTON_PARENTMENU, kAV); return; }
                else if(sButton == BUTTON_LENGTH) { LengthMenu(kAV, iAuth); return; } // no re-leash menu
                else if (sButton == BUTTON_GIVE_HOLDER) UserCommand(iAuth, "giveholder", kAV);
                else if (sButton == BUTTON_GIVE_POST) UserCommand(iAuth, "givepost", kAV);
                else if (sButton == BUTTON_REZ_POST) UserCommand(iAuth, "rezpost", kAV);
                else if (~llListFindList(g_lButtons, [sButton]))
                { // child menu buttons
                    llMessageLinked(LINK_SET, iAuth, "menu "+sButton, kAV);
                    return; // no re-leash menu
                }
                else
                { // catch all
                    g_iReturnMenu = TRUE; //return menu if asynchronous command
                    UserCommand(iAuth, llToLower(sButton), kAV);
                    return; // and thus, no menu back yet
                }
            }
            else if (kMessageID == g_kLeashTargetDialogID)
            {   
                if ((key)sButton)
                {
                    g_kLeashedTo = (key)sButton;
                    if (CheckCommandAuth(g_kCmdGiver, g_iLastRank))
                        LeashTo(g_kLeashedTo, g_kCmdGiver, g_iLastRank, ["collar", "handle"]);
                }
                if (!g_iReturnMenu) return;
            }
            else if (kMessageID == g_kFollowTargetDialogID)
            {
                debug("Follow from menu=" + sButton);
                if ((key)sButton)
                {
                    g_kLeashedTo = (key)sButton;
                    Follow(g_kLeashedTo, g_kCmdGiver, g_iLastRank);
                }
                if (!g_iReturnMenu) return;
            }
            else if (kMessageID == g_kPostTargetDialogID)
            {
                if ((key)sButton) UserCommand(iAuth, "post " + sButton, kAV);
                if (!g_iReturnMenu) return;
            }
            else if (kMessageID == g_kSetLengthDialogID)
            {
                if(llListFindList(g_lLengths,[sButton]) != -1)
                {
                    UserCommand(iAuth, "length " + sButton, kAV);
                    LengthMenu(kAV, iAuth);
                    return; // no re-main leash menu
                }
            }
            LeashMenu(kAV, iAuth); // remenu
        }
    }

    sensor(integer iSense)
    {
        //debug((string)llGetFreeMemory( ));
        integer iLoop;
        if (g_iSensorMode == SENSORMODE_FIND_TARGET_FOR_LEASH_MENU)
        {
            list lAVs; // just used for menu building
            for (iLoop = 0; iLoop < iSense; iLoop++)
            {
                lAVs += [llDetectedKey(iLoop)];
            }
            string sPrompt = "Pick someone/thing to leash to.";
            g_kLeashTargetDialogID = Dialog(g_kMenuUser, sPrompt, lAVs, [BUTTON_UPMENU], 0, g_iLastRank);
        }
        else if (g_iSensorMode == SENSORMODE_FIND_TARGET_FOR_FOLLOW_MENU)
        {
            list lAVs; // just used for menu building
            for (iLoop = 0; iLoop < iSense; iLoop++)
            {
                lAVs += [llDetectedKey(iLoop)];
            }
            string sPrompt = "Pick someone/thing to follow.";
            g_kFollowTargetDialogID = Dialog(g_kMenuUser, sPrompt, lAVs, [BUTTON_UPMENU], 0, g_iLastRank);
        }
        else if (g_iSensorMode == SENSORMODE_FIND_TARGET_FOR_LEASH_CHAT)
        {
            // Loop through detected avs, seeing if one matches tmpname
            for (iLoop = 0; iLoop < iSense; iLoop++)
            {
                string sName = llDetectedName(iLoop);
                if (startswith(llToLower(sName), llToLower(g_sTmpName)))
                {
                    g_kLeashedTo = llDetectedKey(iLoop);
                    if (CheckCommandAuth(g_kCmdGiver, g_iLastRank))
                        LeashTo(g_kLeashedTo, g_kCmdGiver, g_iLastRank, ["collar", "handle"]);
                    return;
                }
            }
            // No match found -
            Notify(g_kCmdGiver, "Could not find '" + g_sTmpName + "' to follow.", FALSE);
        } 
        else if (g_iSensorMode == SENSORMODE_FIND_TARGET_FOR_FOLLOW_CHAT)
        {
            // Loop through detected avs, seeing if one matches tmpname
            for (iLoop = 0; iLoop < iSense; iLoop++)
            {
                string sName = llDetectedName(iLoop);
                if (startswith(llToLower(sName), llToLower(g_sTmpName)))
                {
                    g_kLeashedTo = llDetectedKey(iLoop);
                    Follow(g_kLeashedTo, g_kCmdGiver, g_iLastRank);
                    return;
                }
            }
            // No match found -
            Notify(g_kCmdGiver, "Could not find '" + g_sTmpName + "' to leash to.", FALSE);
        } 
        else if(g_iSensorMode == SENSORMODE_FIND_TARGET_FOR_POST_MENU)
        {
            list lButtons = [];
            string sPrompt = "Pick the object that you would like the sub to be leashed to.  If it's not in the list, have the sub move closer and try again.\n";
            for (iLoop = 0; iLoop < iSense; iLoop ++)
            {
                if(llDetectedName(iLoop) != "Object") lButtons += [llDetectedKey(iLoop)];
            }
            g_kPostTargetDialogID = Dialog(g_kMenuUser, sPrompt, lButtons, [BUTTON_UPMENU], 0, g_iLastRank);
        }
        else if (g_iSensorMode == SENSORMODE_FIND_TARGET_FOR_POST_CHAT)
        {
            // Loop through detected objects, seeing if one matches tmpname
            for (iLoop = 0; iLoop < iSense; iLoop++)
            {
                if (startswith(llToLower(llDetectedName(iLoop)), llToLower(g_sTmpName)))
                {
                    g_kLeashedTo = llDetectedKey(iLoop);
                    if (CheckCommandAuth(g_kCmdGiver, g_iLastRank))
                        LeashTo(g_kLeashedTo, g_kCmdGiver, g_iLastRank, ["collar", "post"]);
                    return;
                }
            }
            Notify(g_kMenuUser, "Could not find '" + g_sTmpName + "' to leash to.", FALSE);
        }
    }
    
    no_sensor()
    {
        // Nothing found close enough to leash onto, tell menuuser
        Notify(g_kMenuUser, "Unable to find any nearby targets.", FALSE);
        if (g_iSensorMode >= SENSORMODE_FIND_TARGET_FOR_LEASH_MENU && g_iReturnMenu)
            LeashMenu(g_kMenuUser, g_iLastRank);
    }        
    
    at_target(integer iNum, vector vTarget, vector vMe)
    {
        g_iUnixTime = llGetUnixTime();
        llStopMoveToTarget();
        llTargetRemove(g_iTargetHandle);
        g_vPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
        g_iTargetHandle = llTarget(g_vPos, g_fLength);
        if(g_iJustMoved)
        {
            turnToTarget( llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0));
            g_iJustMoved = 0;
        }   
    }
    
    not_at_target()
    {
        g_iJustMoved = 1;
        g_iUnixTime = llGetUnixTime();
        // i ran into a problem here which seems to be "speed" related, specially when using the menu to unleash this event gets triggered together or just after the CleanUp() function
        //to prevent to get stay in the target events i added a check on g_kLeashedTo is NULL_KEY
        if(g_kLeashedTo)
        {
            vector vNewPos = llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0);
            //llStopMoveToTarget();
            if (g_vPos != vNewPos)
            {
                llTargetRemove(g_iTargetHandle);
                g_vPos = vNewPos;
                g_iTargetHandle = llTarget(g_vPos, g_fLength);
            }
            if (g_vPos != ZERO_VECTOR)
            {
                //only at target
               /* if (!(llGetAgentInfo(g_kWearer) & AGENT_SITTING))
                {
                    if ((g_iUnixTime + 2) >= llGetUnixTime())
                    {
                        turnToTarget(g_vPos);
                    }
                }*/
                llMoveToTarget(g_vPos,0.7);
            }
            else
            {
                llStopMoveToTarget();
            }
        }
        else
        {
            DoUnleash();
        }
    }
  
    run_time_permissions(integer iPerm)
    {
        if (iPerm & PERMISSION_TAKE_CONTROLS)
        {
            //disbale all controls but left mouse button (for stay cmd)
            llTakeControls(CONTROL_ROT_LEFT | CONTROL_ROT_RIGHT | CONTROL_LBUTTON | CONTROL_ML_LBUTTON, FALSE, FALSE);
        }
    }
}
