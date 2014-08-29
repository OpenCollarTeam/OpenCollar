////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - anim                                //
//                                 version 3.980                                  //
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

//PoseMove tweak stuff
integer g_iTweakPoseAO = 0; //Disable/Enable AO for posed animations - set it to 1 to default PoseMove tweak to ON
key g_kMenuPoseMove;
string g_sPoseMoveWalk;  //Variable to hold our current Walk animation
string g_sPoseMoveRun;   //Variable to hold our run animation
string NOWALK = "none"; //This can be changed to reflect the PoseMove Menu 'no walk' selected button
//string NORUN = "no run";  //This can be changed to reflect the PoseMove Menu 'no run' selected button
string g_sWalkButtonPrefix = ""; //This can be changed to prefix walks in the PoseMove menu
//string g_sRunButtonPrefix = "Run "; //This can be changed to prefix runs in the PoseMove menu
list g_lPoseMoveAnimationPrefix = ["~walk_","~run_"];
string g_sPoseMoveRunDefaultAnimation = "~run";

string g_sPoseMoveWalkToken = "PoseMoveWalk"; //tokens for saving - these can be changed
string g_sPoseMoveRunToken = "PoseMoveRun";
string g_sTweakPoseAOToken = "TweakPoseAO";

//for the height scaling feature
key g_kDataID;
string card = "~heightscalars";
integer g_iLine = 0;
list g_lAnimScalars;//a 3-strided list in form animname,scalar,delay
integer g_iAdjustment = 0;

string g_sCurrentPose = "";
integer g_iLastRank = 0; //in this integer, save the rank of the person who posed the av, according to message map.  0 means unposed
string g_sRootMenu = "Main";
string g_sAnimMenu = "Animations";
string g_sPoseMenu = " Pose";
string g_sPoseMoveMenu = "AntiSlide";
string g_sAOMenu = "AO";
//string g_sGiveAO = "Give AO";
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
string g_sPostureAnim="~stiff";
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
string POSEMOVEMENU = "AntiSlide";

string HEIGHTFIX = "HeightFix";
string POSEAO = "AntiSlide";
string g_sHeightFixToken = "HFix";
integer g_iHeightFix = TRUE;
list g_lHeightFixAnims;
integer maxHeightAdjust;
integer minHeightAdjust;

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

//Debug(string sStr){llOwnerSay(llGetScriptName() + ": " + sStr);}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

AnimMenu(key kID, integer iAuth)
{
    string sPrompt = "\nThe wearer of this "+ CTYPE;
    list lButtons;
    if(g_iAnimLock)
    {
        sPrompt += " is forbidden to change or stop poses on their own";
        lButtons = [TICKED + ANIMLOCK];
    }
    else
    {
        //sPrompt += UNTICKED + ANIMLOCK + " is turned off:\n";
        sPrompt += " is allowed to change or stop poses on their own";
        lButtons = [UNTICKED + ANIMLOCK];
    }        
    if(llGetInventoryType(g_sPostureAnim)==INVENTORY_ANIMATION)
    {
        if(g_iPosture)
        {
            //sPrompt +="\n"+ TICKED + POSTURE + " is turned on.\n";
            sPrompt +=" and has their neck forced stiff.";
            lButtons += [TICKED + POSTURE];
        }
        else
        {
            //sPrompt +="\n"+ UNTICKED + POSTURE + " is turned off.\n";
            sPrompt +=" and can relax their neck.";
            lButtons += [UNTICKED + POSTURE];
        }
    }
    if(g_iTweakPoseAO)
    {
        //sPrompt += "\n"+g_sPoseMoveMenu+" is enabled.";
        lButtons += [TICKED + POSEAO];
    }
    else
   {
        //sPrompt += "\n"+g_sPoseMoveMenu+" is disabled.";
        lButtons += [UNTICKED + POSEAO];
   }

    sPrompt +="\n\nwww.opencollar.at/animations";    
    //sPrompt +="\n\nGet a free, unisex and upgradeable Submissive AO here:\nmarketplace.secondlife.com/p/OpenCollar-Sub-AO/5493736";

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
    string sPrompt = "\nChoose a pose to play.\n\nwww.opencollar.at/animations\n\n";
    if (g_sCurrentPose == "")sPrompt += "Current Pose is = None\n";
    else sPrompt += "Current Pose is = " + g_sCurrentPose +"\n";
    list lButtons;
    if(g_iHeightFix)
    {
        //sPrompt += "\n\nThe height of some poses will be adjusted now.";
        lButtons += [TICKED + HEIGHTFIX];
    }
    else
   {
        //sPrompt += "\n\nThe height of the poses will not be changed.";
        lButtons += [UNTICKED + HEIGHTFIX];
   }
    list lHeightFixButtons=[];
    if (g_iHeightFix){
        lHeightFixButtons=["↑","↓"];
    }
    key kMenuID = Dialog(kID, sPrompt, lButtons+g_lPoseList, lHeightFixButtons+[RELEASE, UPMENU], iPage, iAuth);
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
        llOwnerSay("Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.");
        return FALSE;
    }
}

PoseMoveMenu(key kID, integer iPage, integer iAuth) {
    string sPrompt;
    list lButtons;
    if(g_iTweakPoseAO)
    {
        sPrompt += "\nThe "+g_sPoseMoveMenu+" tweak is enabled.";
        lButtons += ["OFF"];
    }
    else
   {
        sPrompt += "\nThe "+g_sPoseMoveMenu+" tweak is disabled.";
        lButtons += ["ON"];
   }
   if (g_sPoseMoveWalk != "") {
       if (g_iTweakPoseAO) {
           sPrompt += "\n\nSelected Walk: "+g_sPoseMoveWalk;
           if (llGetInventoryKey(g_sPoseMoveRun)) sPrompt += "\nSelected Run: "+g_sPoseMoveRun;
           else sPrompt += "\nSelected Run: "+g_sPoseMoveRunDefaultAnimation;
       }
       lButtons += [UNTICKED+NOWALK];
   }
   else {
       sPrompt += "\n\n"+g_sPoseMoveMenu+" is not overriding any walk animations.";
       lButtons += [TICKED+NOWALK];
   }
   integer i = 0;
   integer iAnims = llGetInventoryNumber(INVENTORY_ANIMATION) - 1;
   string sAnim;
   for (i=0;i<=iAnims;++i)
    {
        sAnim = llGetInventoryName(INVENTORY_ANIMATION,i);
        if (llSubStringIndex(sAnim,llList2String(g_lPoseMoveAnimationPrefix,0)) == 0 ) { 
            //Debug("sAnim = "+sAnim+"\ng_sPoseMoveWalk = "+g_sPoseMoveWalk);
            if (sAnim == g_sPoseMoveWalk) {
                lButtons += [TICKED + g_sWalkButtonPrefix+ llGetSubString(sAnim,llStringLength(llList2String(g_lPoseMoveAnimationPrefix,0)),-1)];
            }
            else {
                lButtons += [UNTICKED +g_sWalkButtonPrefix+ llGetSubString(sAnim,llStringLength(llList2String(g_lPoseMoveAnimationPrefix,0)),-1)];
            }
        }
    }

    sPrompt +="\n\nwww.opencollar.at/animations";    

    g_kMenuPoseMove = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
    list lNewStride = [kID, g_kMenuPoseMove, POSEMOVEMENU];
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
        

RefreshAnim()
{ //g_lAnims can get lost on TP, so re-play g_lAnims[0] here, and call this function in "changed" event on TP
    if (llGetListLength(g_lAnims))
    {

        if(g_iPosture) llStartAnimation(g_sPostureAnim);
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS)
        {
            llResetAnimationOverride("ALL");            
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
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS)
    {
        if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
        {   //get and stop currently playing anim
            if (llGetListLength(g_lAnims))

            {
                string s_Current = llList2String(g_lAnims, 0);
                if (g_iTweakPoseAO) {
                    llResetAnimationOverride("ALL");
                }
                else {
                    llStopAnimation(s_Current);
                }
            }

            //stop any currently playing height adjustment
            if (g_iAdjustment)
            {
                llStopAnimation("~" + (string)g_iAdjustment);
                g_iAdjustment = 0;
            }

            //add anim to list
            g_lAnims = [sAnim] + g_lAnims;//this way, g_lAnims[0] is always the currently playing anim
            if (g_iTweakPoseAO) {

                 llSetAnimationOverride( "Standing", sAnim);
                 if (g_sPoseMoveWalk) {
                     llSetAnimationOverride( "Walking", g_sPoseMoveWalk);
                 }
                 if (g_sPoseMoveRun) {
                     if (llGetInventoryKey(g_sPoseMoveRun)) {
                        llSetAnimationOverride( "Running", g_sPoseMoveRun);
                    }
                    else if (llGetInventoryKey(g_sPoseMoveRunDefaultAnimation)) {
                        llSetAnimationOverride( "Running", g_sPoseMoveRunDefaultAnimation);
                    }
                 }

            }
            else {
               llStartAnimation(sAnim);
            }
            llWhisper(g_iInterfaceChannel, "CollarComand|" + (string)EXT_COMMAND_COLLAR + "|" + AO_OFF);
            llWhisper(g_iAOChannel, AO_OFF);
            
            if (g_iHeightFix)
            {
                //adjust height for anims in g_lAnimScalars
                integer iIndex = llListFindList(g_lAnimScalars, [sAnim]);
                if (iIndex != -1)
                {//we just started playing an anim in our g_iAdjustment list
                    //pause to give certain anims time to ease in
                    llSleep((float)llList2String(g_lAnimScalars, iIndex + 2));
                    vector vAvScale = llGetAgentSize(g_kWearer);
                    float fScalar = (float)llList2String(g_lAnimScalars, iIndex + 1);
                    g_iAdjustment = llRound(vAvScale.z * fScalar);
                    if (g_iAdjustment > maxHeightAdjust)
                    {
                        g_iAdjustment = maxHeightAdjust;
                    }
                    else if (g_iAdjustment < minHeightAdjust)
                    {
                        g_iAdjustment = minHeightAdjust;
                    }
                    llStartAnimation("~" + (string)g_iAdjustment);
                }
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

StopAnim(string sAnim)
{
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS)
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
//            if ( llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS ) llResetAnimationOverride("ALL");
            if (g_iTweakPoseAO) {
                llResetAnimationOverride("ALL");
            }
            else {
                llStopAnimation(sAnim);
            }
            
            //stop any currently-playing height adjustment
            if (g_iAdjustment)
            {
                llStopAnimation("~" + (string)g_iAdjustment);
                g_iAdjustment = 0;
            }
            //play the new g_lAnims[0]
            //if anim list is empty, turn AO back on
            if (llGetListLength(g_lAnims))
            {
                string sNewAnim = llList2String(g_lAnims, 0);
                llStartAnimation(sNewAnim);
                
                //adjust height for anims in g_lAnimScalars
                integer iIndex = llListFindList(g_lAnimScalars, [sNewAnim]);
                if (iIndex != -1)
                {//we just started playing an anim in our adjustment list
                    //pause to give certain anims time to ease in
                    llSleep((float)llList2String(g_lAnimScalars, iIndex + 2));
                    vector vAvScale = llGetAgentSize(g_kWearer);
                    float fScalar = (float)llList2String(g_lAnimScalars, iIndex + 1);
                    g_iAdjustment = llRound(vAvScale.z * fScalar);
                    if (g_iAdjustment > maxHeightAdjust)
                    {
                        g_iAdjustment = maxHeightAdjust;
                    }
                    else if (g_iAdjustment < minHeightAdjust)
                    {
                        g_iAdjustment = minHeightAdjust;
                    }
                    llStartAnimation("~" + (string)g_iAdjustment);
                }
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
        llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS );
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
    
    g_lHeightFixAnims=[];
    
    for (i=0;i<iMax;i++)
    {
        sName=llGetInventoryName(INVENTORY_ANIMATION, i);
        //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
        if (sName != "" && llGetSubString(sName, 0, 0) != "~")
        {
            g_lPoseList+=[sName];
        }
        
        if (llSubStringIndex(sName,"~")==0 && llStringLength(sName)==4){
            sName=llGetSubString(sName,1,3);
            if ((integer)sName != 0){
                g_lHeightFixAnims += sName;
            }
        }
    }
    //    g_iNumAnims=llGetListLength(g_lPoseList);
    
    
    g_lHeightFixAnims=llListSort(g_lHeightFixAnims,1,1);
    //Debug("Height fix:"+llDumpList2String(g_lHeightFixAnims,","));
    maxHeightAdjust=llList2Integer(g_lHeightFixAnims,0);
    minHeightAdjust=llList2Integer(g_lHeightFixAnims,-1);
    //Debug("max:"+(string)maxHeightAdjust+" min:"+(string)minHeightAdjust);
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
      //  else if (sSubmenu == g_sPoseMoveMenu) PoseMoveMenu(kID,0,iNum); we handle this as a catch-all else statement
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
    //pose menu
    else if (sStr == "pose"){
        PoseMenu(kID, 0, iNum);
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
    //posture
    else if ( sStr=="posture on" || sStr == UNTICKED+POSTURE) {
        if(iNum<COMMAND_WEARER) {
            SetPosture(TRUE,kID);
            Notify(g_kWearer, "Your neck is locked in place.", FALSE);
            if(kID != g_kWearer) Notify(kID, llKey2Name(g_kWearer) + "'s neck is locked in place.", FALSE);
        } else Notify(kID,"Only owners can do that, sorry.",FALSE);
    } else if ( sStr=="posture off" || sStr == UNTICKED+POSTURE) {
        if(iNum<COMMAND_WEARER) {
            SetPosture(FALSE,kID);
            Notify(g_kWearer, "You can move your neck again.", FALSE);
            if(kID != g_kWearer) Notify(kID, llKey2Name(g_kWearer) + " is free to move their neck.", FALSE);
        } else Notify(kID,"Only owners can do that, sorry.",FALSE);
    }
    //anim lock
    else if ( sStr=="animlock on" || sStr == UNTICKED+ANIMLOCK){
        if(iNum<COMMAND_WEARER) {
            g_iAnimLock = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sLockToken + "=1", "");
            Notify(g_kWearer, "Only owners can change or stop your poses now.", FALSE);
            if(kID != g_kWearer) Notify(kID, llKey2Name(g_kWearer) + " can have their poses changed or stopped only by owners.", FALSE);
        } else Notify(kID,"Only owners can do that, sorry.",FALSE);
    } else if ( sStr=="animlock off" || sStr == TICKED+ANIMLOCK){
        if(iNum<COMMAND_WEARER) {
            g_iAnimLock = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + g_sLockToken, "");
            Notify(g_kWearer, "You are now free to change or stop poses on your own.", FALSE);
            if(kID != g_kWearer) Notify(kID, llKey2Name(g_kWearer) + " is free to change or stop poses on their own.", FALSE);
        } else Notify(kID,"Only owners can do that, sorry.",FALSE);
    //heightfix
    } else if ( sStr=="heightfix on" || sStr == UNTICKED+HEIGHTFIX){
        if ((iNum == COMMAND_OWNER)||(kID == g_kWearer)){
            g_iHeightFix = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sHeightFixToken, NULL_KEY);
            Notify(g_kWearer, "HeightFix override activated.", TRUE);
            if (g_sCurrentPose != "") {
                string sTemp = g_sCurrentPose;
                StopAnim(sTemp);
                StartAnim(sTemp);
            }
            //AnimMenu(kID, iNum);
        }
        else Notify(kID,"Only owners or the wearer can use this option.",FALSE);
    } else if ( sStr=="heightfix off" || sStr == TICKED+HEIGHTFIX){
        if ((iNum == COMMAND_OWNER)||(kID == g_kWearer)){
            g_iHeightFix = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sHeightFixToken + "=0", NULL_KEY);
            Notify(g_kWearer, "HeightFix override deactivated.", TRUE);
            if (g_sCurrentPose != "") {
                string sTemp = g_sCurrentPose;
                StopAnim(sTemp);
                StartAnim(sTemp);
            }
            //AnimMenu(kID, iNum);
        }
        else Notify(kID,"Only owners or the wearer can use this option.",FALSE);
    //AO
    } else if(sCommand == "ao") {
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
    else if (sCommand == llToLower(g_sPoseMoveMenu)) { //check for text command of PoseMoveMenu's string
        if (iNum <= g_iLastRank || !g_iAnimLock) {
            if (sValue == "on") {
                g_iTweakPoseAO = 1;    
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + g_sTweakPoseAOToken + "=1" , "");
                RefreshAnim();
                Notify(kID, g_sPoseMoveMenu +" is now enabled.", FALSE);
            }
            else if (sValue == "off") {
                g_iTweakPoseAO = 0;
                llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript + g_sTweakPoseAOToken, "");
                RefreshAnim();
                Notify(kID, g_sPoseMoveMenu +" is now disabled.", FALSE);
            }
            else {                   
                PoseMoveMenu(kID,0,iNum);
            }
        }
        else {
            Notify(g_kWearer, "Only owners can change or stop your poses now.", FALSE);
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

AdjustOffset(integer direction){
    //first, check we're running an anim
    if (llGetListLength(g_lAnims)>0){
        //get sleep time from list    
        string sNewAnim = llList2String(g_lAnims, 0);
        integer iIndex = llListFindList(g_lAnimScalars, [sNewAnim]);
        string sleepTime="2.0";
        if (iIndex != -1){
            sleepTime=llList2String(g_lAnimScalars, iIndex + 2);
            g_lAnimScalars=llDeleteSubList(g_lAnimScalars,iIndex,iIndex+2);       //we re-write it at the end
        }
    
        //stop last adjustment anim and play next one
        integer iOldAdjustment=g_iAdjustment;
        if (g_iAdjustment){
            g_iAdjustment+=direction;
            while (g_iAdjustment > minHeightAdjust && g_iAdjustment < maxHeightAdjust && !~llListFindList(g_lHeightFixAnims,[(string)g_iAdjustment])){
                //Debug("Re-adjust "+(string)g_iAdjustment);
                g_iAdjustment+=direction;
            }
            
            if (g_iAdjustment > maxHeightAdjust){
                g_iAdjustment = 0;
                Notify(g_kWearer,sNewAnim+" height fix cancelled",FALSE);
            } else if (g_iAdjustment < minHeightAdjust){
                g_iAdjustment = minHeightAdjust;
            }
            
            
        } else if (direction == -1){
            g_iAdjustment=maxHeightAdjust;
        }
        if (g_iAdjustment != 0){
            llStartAnimation("~" + (string)g_iAdjustment);
            
            //now calculate the new offset for notecard dump print
            vector avscale = llGetAgentSize(llGetOwner());
            float test = (float)g_iAdjustment/avscale.z;
            Notify(g_kWearer,sNewAnim+"|"+(string)test+"|"+sleepTime,FALSE);
            
            //and store it
            g_lAnimScalars+=[sNewAnim,test,sleepTime];
        }
        if (iOldAdjustment && iOldAdjustment != g_iAdjustment){
            llStopAnimation("~" + (string)iOldAdjustment);
        }
    }
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
        //g_lAnimButtons = [" Pose", g_sTriggerAO, g_sGiveAO, "AO ON", "AO OFF"];
        g_lAnimButtons = [" Pose", g_sTriggerAO, "AO ON", "AO OFF"];
        g_kWearer = llGetOwner();
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
        RequestPerms();

        CreateAnimList();

        //llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sAnimMenu, "");
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sRootMenu + "|" + g_sAnimMenu, "");
    
         //start reading the ~heightscalars notecard
         if (llGetInventoryKey(card)) {
             g_kDataID = llGetNotecardLine(card, g_iLine);
        }
    }

    dataserver(key kID, string sData)
    {
        if (kID == g_kDataID)
        {
            if (sData != EOF)
            {
                g_lAnimScalars += llParseString2List(sData, ["|"], []);
                g_iLine++;
                g_kDataID = llGetNotecardLine(card, g_iLine);
            }
        }   
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_TELEPORT)
        {
            RefreshAnim();
        }

        if (iChange & CHANGED_INVENTORY)
        {
            g_lAnimScalars = [];
            //start re-reading the ~heightscalars notecard
            g_iLine = 0;
            if (llGetInventoryKey(card)) {
                g_kDataID = llGetNotecardLine(card, g_iLine);
            }
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
        if(iPerm & PERMISSION_OVERRIDE_ANIMATIONS )
        {
            //Do nothing - we can call default replacement walks/runs when a pose is triggered
        }
    } 
    attach(key kID)
    {
        if (kID == NULL_KEY)
        {
            //Debug("detached");
            //we were just detached.  clear the anim list and tell the ao to play stands again.
            llWhisper(g_iInterfaceChannel, (string)EXT_COMMAND_COLLAR + "|" + AO_ON);
            llWhisper(g_iAOChannel, AO_ON);
            g_lAnims = [];
        }
        else
        {
            llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS);
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
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sRootMenu + "|" + g_sAnimMenu, ""); //no need for fixed main menu
            //g_lAnimButtons = [" Pose", g_sTriggerAO, g_sGiveAO, "AO ON", "AO OFF"];
            g_lAnimButtons = [" Pose", g_sTriggerAO, "AO ON", "AO OFF"];
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
                else if (sToken == g_sPoseMoveWalkToken)
                {
                    g_sPoseMoveWalk = sValue;
                }
                else if (sToken == g_sPoseMoveRunToken)
                {
                    g_sPoseMoveRun = sValue;
                }
                else if (sToken == g_sTweakPoseAOToken)
                {
                    g_iTweakPoseAO = 1;
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
                        Notify(kAv, "Attempting to trigger the AO menu. This will only work if " + llKey2Name(g_kWearer) + " is using a Submissive AO or an AO Link script in their normal AO.", FALSE);
                        AOMenu(kAv, iAuth);
                    }
/*                    else if (sMessage == g_sGiveAO)
                    {   
                        DeliverAO(kAv);
                    }
*/
                    else if(sMessage == "☐ AO" || sMessage== "AO ON")
                    {
                        UserCommand(iAuth, "ao on", kAv);
                        AnimMenu(kAv, iAuth);
                    }
                    else if(sMessage == "☒ AO"  || sMessage== "AO OFF")
                    {
                        UserCommand(iAuth, "ao off", kAv);
                        AnimMenu(kAv, iAuth);
                    }
                    else if(llGetSubString(sMessage, llStringLength(TICKED), -1) == ANIMLOCK)
                    {
                        UserCommand(iAuth, sMessage, kAv);
                        AnimMenu(kAv, iAuth);
                    }
                    else if(llGetSubString(sMessage, llStringLength(TICKED), -1) == POSEAO)
                    {
                        //This is the Animation menu item, we need to call the PoseMoveMenu item from here...
                        PoseMoveMenu(kAv,iNum,iAuth);
                    }
                    else if(llGetSubString(sMessage, llStringLength(TICKED), -1) == HEIGHTFIX)
                    {
                        UserCommand(iAuth, sMessage, kAv);
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
                    else if (sMessage == "↑")
                    {
                        AdjustOffset(1);
                    }
                    else if (sMessage == "↓")
                    {
                        AdjustOffset(-1);
                    }
                    else  //we got an animation name
                        //if ((integer)sMessage)
                    { //we don't know any more what the speaker's auth is, so pass the command back through the auth system.  then it will play only if authed
                        //string sAnimsName = llGetInventoryName(INVENTORY_ANIMATION, (integer)sMessage - 1);
                        UserCommand(iAuth, sMessage, kAv);
                    }
                    PoseMenu(kAv, iPage, iAuth);
                }
                else if (sMenuType == POSEMOVEMENU) {
                    if (sMessage == UPMENU)
                        { //return on parent menu, so the animmenu below doesn't come up
                            AnimMenu(kAv, iAuth);
                            return;
                        }
                    if (iAuth <= g_iLastRank || !g_iAnimLock) {
                        if(sMessage == "OFF")
                        {
                                g_iTweakPoseAO = 0;
                                llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript + g_sTweakPoseAOToken, "");
                                PoseMoveMenu(kAv,iNum,iAuth);     
                        }
                        else if (sMessage == "ON") {
                                g_iTweakPoseAO = 1;
                                 llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + g_sTweakPoseAOToken + "=1" , "");
                                RefreshAnim();
                                PoseMoveMenu(kAv,iNum,iAuth);        
                        }
                        else if (sMessage == TICKED+NOWALK || sMessage == UNTICKED+NOWALK) {
                            llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript + g_sPoseMoveWalkToken, ""); 
                            g_sPoseMoveWalk = "";
                            g_sPoseMoveRun = "";
                            RefreshAnim();
                            PoseMoveMenu(kAv,iNum,iAuth);
                        } 
                        else if (sMessage != "") {
                            if (llSubStringIndex(sMessage,UNTICKED + g_sWalkButtonPrefix) == 0) {
                                g_sPoseMoveWalk = llList2String(g_lPoseMoveAnimationPrefix,0) + llGetSubString(sMessage,llStringLength(TICKED + g_sWalkButtonPrefix) ,-1);
                                g_sPoseMoveRun = llList2String(g_lPoseMoveAnimationPrefix,1) + llGetSubString(sMessage,llStringLength(TICKED) ,-1);
                                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + g_sPoseMoveWalkToken + "=" + g_sPoseMoveWalk, "");
                                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + g_sPoseMoveRunToken + "=" + g_sPoseMoveRun, "");
                            } /*
                            else if (llSubStringIndex(sMessage,UNTICKED + g_sRunButtonPrefix) == 0) {
                                g_sPoseMoveRun = llList2String(g_lPoseMoveAnimationPrefix,1) + llGetSubString(sMessage,llStringLength(TICKED + g_sRunButtonPrefix),-1);
                                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + g_sPoseMoveRunToken + "=" + g_sPoseMoveRun, "");
                            } */
                            RefreshAnim();
                            PoseMoveMenu(kAv,iNum,iAuth);
                        }
                    }
                    else {
                        Notify(g_kWearer, "Only owners can change or stop your poses now.", FALSE);
                    }
                }
            }
        }
    }
}
