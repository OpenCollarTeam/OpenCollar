////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - anim                                //
//                                 version 3.960                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//needs to handle anim requests from sister scripts as well
//this script as essentially two layers
//lower layer: coordinate animation requests that come in on link messages.  keep a list of playing anims disable AO when needed
//upper layer: use the link message anim api to provide a pose menu

list g_lAnims;
//integer g_iNumAnims;//the number of anims that don't start with "~"
//integer g_iPageSize = 8;//number of anims we can fit on one page of a multi-page menu
list g_lPoseList;

string g_sCurrentPose = "";
integer g_iLastRank = 0; //in this integer, save the rank of the person who posed the av, according to message map.  0 means unposed
string g_sRootMenu = "Main";
string g_sAnimMenu = "Animations";
string g_sPoseMenu = " Pose";
string g_sAOMenu = "AO";
string g_sGiveAO = "Give AO";
string g_sTriggerAO = "AO Menu";
list g_lAnimButtons; // initialized in state_entry for OpenSim compatibility (= ["Pose", g_sTriggerAO, g_sGiveAO, "AO ON", "AO OFF"];)
//added for sAnimlock
string TICKED = "☒ ";
string UNTICKED = "☐ ";
string ANIMLOCK = "AnimLock";
string RELEASE = "STOP";
integer g_iAnimLock = FALSE;
string g_sLockToken = "animlock";

//added for posture
string POSTURE="Posture";
integer g_iPosture;
string g_sPostureAnim="~PostureOverride";
string g_sPostureToken="posture";

string g_sAppEngine_Url = "http://data.mycollar.org/"; //defaul OC url, can be changed in defaultsettings notecard and wil be send by settings script if changed

string g_sAnimToken = "currentpose";
//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_SAFEWORD = 510;  // new for safeword
integer COMMAND_WEARERLOCKEDOUT = 521;

//EXTERNAL MESSAGE MAP
integer EXT_COMMAND_COLLAR = 499; //added for collar or cuff commands to put ao to pause or standOff

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;

integer ANIM_START = 7000;
integer ANIM_STOP = 7001;

//5000 block is reserved for IM slaves

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";

integer g_iAOChannel = -782690;
integer g_iInterfaceChannel = -12587429;
string AO_ON = "ZHAO_STANDON";
string AO_OFF = "ZHAO_STANDOFF";
string AO_MENU = "ZHAO_MENU";

integer g_iNumberOfAnims; //we store this to avoid running createanimlist() every time inventory is changed...

string CTYPE = "collar";

key g_kWearer;
string g_sScript;

list g_lMenuIDs;//three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

string ANIMMENU = "Anim";
string AOMENU = "AO";
string POSEMENU = " Pose";

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

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

AnimMenu(key kID, integer iAuth)
{
    string sPrompt = "\n\n";
    list lButtons;
    if(g_iAnimLock)
    {
        sPrompt += TICKED + ANIMLOCK + " is turned on:\n";
        sPrompt += "Only owners can change or stop poses now.\n";
        lButtons = [TICKED + ANIMLOCK];
    }
    else
    {
        sPrompt += UNTICKED + ANIMLOCK + " is turned off:\n";
        sPrompt += "The wearer is free to change or stop poses on their own.\n";
        lButtons = [UNTICKED + ANIMLOCK];
    }
    if(llGetInventoryType(g_sPostureAnim)==INVENTORY_ANIMATION)
    {
        if(g_iPosture)
        {
            sPrompt +="\n"+ TICKED + POSTURE + " is turned on.\n";
            lButtons += [TICKED + POSTURE];
        }
        else
        {
            sPrompt +="\n"+ UNTICKED + POSTURE + " is turned off.\n";
            lButtons += [UNTICKED + POSTURE];
        }
    }    
    sPrompt += "\nAO features require one of the following:\n\na) OpenCollar Sub AO\nb) Firestorm Bridge + Internal AO\nc) A drop'n'go script for ZHAOII based AOs";
    lButtons += llListSort(g_lAnimButtons, 1, TRUE);
    key kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
    list lNewStride = [kID, kMenuID, ANIMMENU];
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (iIndex == -1)
    {
        g_lMenuIDs += lNewStride;
    }
    else
    {//this person is already in the dialog list.  replace their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, iIndex, iIndex - 1 + g_iMenuStride);
    }
}

AOMenu(key kID, integer iAuth) // wrapper to send menu back to the AO's menu
{
    llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string)iAuth + "|" + AO_MENU + "|" + (string)kID);
    llWhisper(g_iAOChannel, AO_MENU + "|" + (string)kID);
}

PoseMenu(key kID, integer iPage, integer iAuth)
{ //create a list
    string sPrompt = "\n\nChoose a pose to play.\n\nSTOP: release the pose\n\n";
    key kMenuID = Dialog(kID, sPrompt, g_lPoseList, [RELEASE, UPMENU], iPage, iAuth);
    list lNewStride = [kID, kMenuID, POSEMENU];
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (iIndex == -1)
    {
        g_lMenuIDs += lNewStride;
    }
    else
    {//this person is already in the dialog list.  replace their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, iIndex, iIndex - 1 + g_iMenuStride);
    }
}

integer SetPosture(integer iOn, key kCommander)
{
    if(llGetInventoryType(g_sPostureAnim)!=INVENTORY_ANIMATION) return FALSE;
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    {
        if(iOn && !g_iPosture)
        {
            llStartAnimation(g_sPostureAnim);
            if(kCommander) Notify(kCommander,"Posture override active.",TRUE);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sPostureToken +"=1","");
        }
        else if (!iOn)
        {
            llStopAnimation(g_sPostureAnim);
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + g_sPostureToken, "");
        }
        g_iPosture=iOn;
        return TRUE;
    }
    else 
    {
        llOwnerSay("Error: Somehow I lost permission to animate you.  Try taking me off and re-attaching me.");
        return FALSE;
    }
}
        

RefreshAnim()
{ //g_lAnims can get lost on TP, so re-play g_lAnims[0] here, and call this function in "changed" event on TP
    if (llGetListLength(g_lAnims))
    {
        if(g_iPosture) llStartAnimation(g_sPostureAnim);
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
        {
            string sAnim = llList2String(g_lAnims, 0);
            if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
            { //get and stop currently playing anim
                StartAnim(sAnim);
                /*
                    if (llGetListLength(g_lAnims))
                    {
                        string s_Current = llList2String(g_lAnims, 0);
                        llStopAnimation(s_Current);
                    }
                //add anim to list
                g_lAnims = [sAnim] + g_lAnims;//this way, g_lAnims[0] is always the currently playing anim
                llStartAnimation(sAnim);
                llSay(g_iInterfaceChannel, AO_OFF);
                */
                }
            else
            {
                //Popup(g_kWearer, "Error: Couldn't find anim: " + sAnim);
            }
        }
        else
        {
            Notify(g_kWearer, "Error: Somehow I lost permission to animate you.  Try taking me off and re-attaching me.", FALSE);
        }
    }
}

StartAnim(string sAnim)
{
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    {
        if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
        {   //get and stop currently playing anim
            if (llGetListLength(g_lAnims))

            {
                string s_Current = llList2String(g_lAnims, 0);
                llStopAnimation(s_Current);
            }

            //add anim to list
            g_lAnims = [sAnim] + g_lAnims;//this way, g_lAnims[0] is always the currently playing anim
            llStartAnimation(sAnim);
            llWhisper(g_iInterfaceChannel, "CollarComand|" + (string)EXT_COMMAND_COLLAR + "|" + AO_OFF);
            llWhisper(g_iAOChannel, AO_OFF);
        }
        else
        {
            //Popup(g_kWearer, "Error: Couldn't find anim: " + sAnim);
        }
    }
    else
    {
        Notify(g_kWearer, "Error: Somehow I lost permission to animate you.  Try taking me off and re-attaching me.", FALSE);
    }
}

StopAnim(string sAnim)
{
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    {
        if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
        {   //remove all instances of anim from anims
            //loop from top to avoid skipping
            integer n;
            for (n = llGetListLength(g_lAnims) - 1; n >= 0; n--)
            {
                if (llList2String(g_lAnims, n) == sAnim)
                {
                    g_lAnims = llDeleteSubList(g_lAnims, n, n);
                }
            }
            llStopAnimation(sAnim);
            //play the new g_lAnims[0]
            //if anim list is empty, turn AO back on
            if (llGetListLength(g_lAnims))
            {
                string sNewAnim = llList2String(g_lAnims, 0);
                llStartAnimation(sNewAnim);
            }
            else
            {
                llWhisper(g_iInterfaceChannel, "CollarComand|" + (string)EXT_COMMAND_COLLAR + "|" + AO_ON);
                llWhisper(g_iAOChannel, AO_ON);
            }
        }
        else
        {
            //Popup(g_kWearer, "Error: Couldn't find anim: " + sAnim);
        }
    }
    else
    {
        Notify(g_kWearer, "Error: Somehow I lost permission to animate you.  Try taking me off and re-attaching me.", FALSE);
    }
}

DeliverAO(key kID)
{
    llLoadURL(kID,"Get an up to date Submissive AO for free here.","https://marketplace.secondlife.com/p/OpenCollar-Sub-AO/5493736"); 
}

integer StartsWith(string sHayStack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return llDeleteSubString(sHayStack, llStringLength(sNeedle), -1) == sNeedle;
}

RequestPerms()
{
    if (llGetAttached())
    {
        llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION);
    }
}


CreateAnimList()
{
    g_lPoseList=[];
    integer iMax = llGetInventoryNumber(INVENTORY_ANIMATION);
    g_iNumberOfAnims=iMax;
    //eehhh why writing this here?
    //g_iNumAnims;
    integer i;
    string sName;
    for (i=0;i<iMax;i++)
    {
        sName=llGetInventoryName(INVENTORY_ANIMATION, i);
        //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
        if (sName != "" && llGetSubString(sName, 0, 0) != "~")
        {
            g_lPoseList+=[sName];
        }
    }
    //    g_iNumAnims=llGetListLength(g_lPoseList);
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));
    if (sCommand == "menu")
    {
        string sSubmenu = llGetSubString(sStr, 5, -1);
        if (sSubmenu == g_sPoseMenu) PoseMenu(kID, 0, iNum);
        else if (sSubmenu == g_sAOMenu) AOMenu(kID, iNum);
        else if (sSubmenu == g_sAnimMenu) AnimMenu(kID, iNum);
    }
    else if (sStr == "release" || sStr == "stop")
    { //only release if person giving command outranks person who posed us
        if (iNum <= g_iLastRank || !g_iAnimLock)
        {
            g_iLastRank = 0;
            llMessageLinked(LINK_SET, ANIM_STOP, g_sCurrentPose, "");
            g_sCurrentPose = "";
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + g_sAnimToken, "");
        }
    }
    else if (sStr == "animations")
    {   //give menu
        AnimMenu(kID, iNum);
    }
    else if (sStr == "settings")
    {
        if (g_sCurrentPose != "" && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
        {
            Notify(kID, "Current Pose: " + g_sCurrentPose, FALSE);
        }
    }
    else if ((sStr == "runaway" || sStr == "reset") && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
    {   //stop pose
        if (g_sCurrentPose != "")
        {
            StopAnim(g_sCurrentPose);
        }
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + g_sAnimToken, "");
        llResetScript();
    }
    else if(sCommand==llToLower(POSTURE))
    {
        if(iNum==COMMAND_OWNER || iNum==COMMAND_WEARER)
        {
            if(sValue=="on")SetPosture(TRUE,kID);
            else SetPosture(FALSE,kID);
        }
        else Notify(kID,"Only wearers and owners can do that, sorry.",FALSE);
    }
    else if (sStr == "pose")
    {  //do multi page menu listing anims
        PoseMenu(kID, 0, iNum);
    }
    //added for anim lock
    else if((llGetSubString(sStr, llStringLength(TICKED), -1) == ANIMLOCK) && (iNum == COMMAND_OWNER))
    {
        integer iIndex = llListFindList(g_lAnimButtons, [sStr]);
        if(llGetSubString(sStr, 0, llStringLength(TICKED) - 1) == TICKED)
        {
            g_iAnimLock = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + g_sLockToken, "");
            // g_lAnimButtons = llListReplaceList(g_lAnimButtons, [UNTICKED + ANIMLOCK], iIndex, iIndex);
            Notify(g_kWearer, "You are now free to change or stop poses on your own.", FALSE);
            if(kID != g_kWearer)
            {
                Notify(kID, llKey2Name(g_kWearer) + " is free to change or stop poses on their own.", FALSE);
            }
        }
        else
        {
            g_iAnimLock = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sLockToken + "=1", "");
            // g_lAnimButtons = llListReplaceList(g_lAnimButtons, [TICKED + ANIMLOCK], iIndex, iIndex);
            Notify(g_kWearer, "Only owners can change or stop your poses now.", FALSE);
            if(kID != g_kWearer)
            {
                Notify(kID, llKey2Name(g_kWearer) + " can have their poses changed or stopped only by owners.", FALSE);
            }
        }
        //AnimMenu(kID, iNum);
    }
    else if((sCommand == llToLower(ANIMLOCK)) && (iNum == COMMAND_OWNER))
    {
        if(sValue == "on" && !g_iAnimLock)
        {
            integer iIndex = llListFindList(g_lAnimButtons, [UNTICKED + ANIMLOCK]);
            g_iAnimLock = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sLockToken + "=1", "");
            g_lAnimButtons = llListReplaceList(g_lAnimButtons, [TICKED + ANIMLOCK], iIndex, iIndex);
            Notify(g_kWearer, "You are now locked into poses set by others.", FALSE);
            if(kID != g_kWearer)
            {
                Notify(kID, llKey2Name(g_kWearer) + " is now locked into poses set by others and cannot change or stop them on their own.", FALSE);
            }
        }
        else if(sValue == "off" && g_iAnimLock)
        {
            integer iIndex = llListFindList(g_lAnimButtons, [TICKED + ANIMLOCK]);
            g_iAnimLock = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + g_sLockToken, "");
            g_lAnimButtons = llListReplaceList(g_lAnimButtons, [UNTICKED + ANIMLOCK], iIndex, iIndex);
            Notify(g_kWearer,"You are able to change and stop all poses on your own.", FALSE);
            if(kID != g_kWearer)
            {
                Notify(kID, llKey2Name(g_kWearer) + " is able to change and stop poses set by others.", FALSE);
            }
        }
    }
    else if(sCommand == "ao")
    {
        if(sValue == "" || sValue == "menu")
        {
            AOMenu(kID, iNum);
        }
        else if(sValue == "off")
        {
            llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOOFF" + "|" + (string)kID);
            llWhisper(g_iAOChannel,"ZHAO_AOOFF");
        }
        else if(sValue == "on")
        {
            llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOON" + "|" + (string)kID);
            llWhisper(g_iAOChannel,"ZHAO_AOON");
        }
        else if(sValue == "menu")
        {
            AOMenu(kID, iNum);
        }
        else if (sValue == "lock")
        {
            llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_LOCK"  + "|" + (string)kID);
        }
        else if (sValue == "unlock")
        {
            llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_UNLOCK"  + "|" + (string)kID);
        }
        else if(sValue == "hide")
        {
            llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOHIDE" + "|" + (string)kID);
        }
        else if(sValue == "show")
        {
            llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOSHOW" + "|" + (string)kID);
        }
    }
    else if (llGetInventoryType(sStr) == INVENTORY_ANIMATION)
    {
        if (g_sCurrentPose == "")
        {
            g_sCurrentPose = sStr;
            //not currently in a pose.  play one
            g_iLastRank = iNum;
            //StartAnim(sStr);
            llMessageLinked(LINK_SET, ANIM_START, g_sCurrentPose, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sAnimToken + "=" + g_sCurrentPose + "," + (string)g_iLastRank, "");
        }
        else
        {  //only change if command rank is same or higher (lower integer) than that of person who posed us
            if (iNum <= g_iLastRank || !g_iAnimLock)
            {
                g_iLastRank = iNum;
                llMessageLinked(LINK_SET, ANIM_STOP, g_sCurrentPose, "");
                g_sCurrentPose = sStr;
                llMessageLinked(LINK_SET, ANIM_START, g_sCurrentPose, "");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sAnimToken + "=" + g_sCurrentPose + "," + (string)g_iLastRank, "");
            }
        }
    }
    return TRUE;
}

default
{
    on_rez(integer iNum)
    {
        llResetScript();
    }
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_lAnimButtons = [" Pose", g_sTriggerAO, g_sGiveAO, "AO ON", "AO OFF"];
        g_kWearer = llGetOwner();
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
        RequestPerms();

        CreateAnimList();

        //llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sAnimMenu, "");
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sRootMenu + "|" + g_sAnimMenu, "");
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_TELEPORT)
        {
            RefreshAnim();
        }

        if (iChange & CHANGED_INVENTORY)
        {
            if (g_iNumberOfAnims!=llGetInventoryNumber(INVENTORY_ANIMATION)) CreateAnimList();
        }
        if (iChange & CHANGED_OWNER) llResetScript();
    }
    run_time_permissions(integer iPerm)
    {
        if(iPerm & PERMISSION_TRIGGER_ANIMATION)
        {
            if(g_iPosture) llStartAnimation(g_sPostureAnim);
        }
    }
    attach(key kID)
    {
        if (kID == NULL_KEY)
        {
            Debug("detached");
            //we were just detached.  clear the anim list and tell the ao to play stands again.
            llWhisper(g_iInterfaceChannel, (string)EXT_COMMAND_COLLAR + "|" + AO_ON);
            llWhisper(g_iAOChannel, AO_ON);
            g_lAnims = [];
        }
        else
        {
            llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
            //g_lAnimButtons = [" Pose", g_sTriggerAO, g_sGiveAO, "AO ON", "AO OFF"];
            //llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sAnimMenu, ""); //even necessary? Dunno, shoudln't be, but with this, now reproduces old behaviour of resetting on every rez, only without resetting on every rez. -MD
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        // SA: TODO delete this after transition is finished
        if (iNum == COMMAND_NOAUTH) return;
        // /SA
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == ANIM_START)
        {
            StartAnim(sStr);
        }
        else if (iNum == ANIM_STOP)
        {
            StopAnim(sStr);
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sRootMenu)
        {
            //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sRootMenu + "|" + g_sAnimMenu, ""); //no need for fixed main menu
            g_lAnimButtons = [" Pose", g_sTriggerAO, g_sGiveAO, "AO ON", "AO OFF"];
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sAnimMenu, "");
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            if (StartsWith(sStr, g_sAnimMenu + "|"))
            {
                string child = llList2String(llParseString2List(sStr, ["|"], []), 1);
                if (llListFindList(g_lAnimButtons, [child]) == -1)
                {
                    g_lAnimButtons += [child];
                }
            }
        }
        else if (iNum == COMMAND_SAFEWORD)
        { // saefword command recieved, release animation
            if(llGetInventoryType(g_sCurrentPose) == INVENTORY_ANIMATION)
            {
                g_iLastRank = 0;
                llMessageLinked(LINK_SET, ANIM_STOP, g_sCurrentPose, "");
                g_iAnimLock = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + g_sLockToken, "");
                g_sCurrentPose = "";
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == g_sAnimToken)
                {
                    list lAnimParams = llParseString2List(sValue, [","], []);
                    g_sCurrentPose = llList2String(lAnimParams, 0);
                    g_iLastRank = (integer)llList2String(lAnimParams, 1);
                    llMessageLinked(LINK_SET, ANIM_START, g_sCurrentPose, "");
                }
                else if (sToken == g_sLockToken)
                {
                    if(sValue == "1")
                    {
                        g_iAnimLock = TRUE;
                    }
                }
                else if (sToken ==g_sPostureToken)
                {
                    SetPosture((integer)sValue,NULL_KEY);
                }
                else if (sToken == "HTTPDB")
                {
                    g_sAppEngine_Url = sValue;
                }
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = llList2Integer(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == ANIMMENU)
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sRootMenu, kAv);
                    }
                    else if (sMessage == " Pose")
                    {
                        PoseMenu(kAv, 0, iAuth);
                    }
                    else if (sMessage == g_sTriggerAO)
                    {
                        Notify(kAv, "Attempting to trigger the AO menu.  This will only work if " + llKey2Name(g_kWearer) + " is meeting the a) or c) requirement for AO features.", FALSE);
                        AOMenu(kAv, iAuth);
                    }
                    else if (sMessage == g_sGiveAO)
                    {   
                        DeliverAO(kAv);
                    }
                    else if(sMessage == "AO ON")
                    {
                        UserCommand(iAuth, "ao on", kAv);
                        AnimMenu(kAv, iAuth);
                    }
                    else if(sMessage == "AO OFF" )
                    {
                        UserCommand(iAuth, "ao off", kAv);
                        AnimMenu(kAv, iAuth);
                    }
                    else if(llGetSubString(sMessage, llStringLength(TICKED), -1) == ANIMLOCK)
                    {
                        UserCommand(iAuth, sMessage, kAv);
                        AnimMenu(kAv, iAuth);
                    }
                    else if(llGetSubString(sMessage, llStringLength(TICKED), -1) == POSTURE)
                    {
                        string sCommand=POSTURE+" on";
                        if(~llSubStringIndex(sMessage,TICKED)) sCommand=POSTURE+" off";
                        UserCommand(iAuth, llToLower(sCommand), kAv);
                        AnimMenu(kAv, iAuth);
                    }
                    else if (~llListFindList(g_lAnimButtons, [sMessage]))
                    { // SA: can be child scripts menus, not handled in UserCommand()
                        llMessageLinked(LINK_SET, iAuth, "menu " + sMessage, kAv);
                    }
                }
                else if (sMenuType == POSEMENU)
                {
                    if (sMessage == UPMENU)
                    { //return on parent menu, so the animmenu below doesn't come up
                        AnimMenu(kAv, iAuth);
                        return;
                    }
                    else if (sMessage == RELEASE)
                    {
                        UserCommand(iAuth, "release", kAv);
                    }
                    else  //we got an animation name
                        //if ((integer)sMessage)
                    { //we don't know any more what the speaker's auth is, so pass the command back through the auth system.  then it will play only if authed
                        //string sAnimsName = llGetInventoryName(INVENTORY_ANIMATION, (integer)sMessage - 1);
                        UserCommand(iAuth, sMessage, kAv);
                    }
                    PoseMenu(kAv, iPage, iAuth);
                }
            }
        }
    }
}
