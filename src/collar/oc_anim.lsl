////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - anim                                //
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

//needs to handle anim requests from sister scripts as well
//this script as essentially two layers
//lower layer: coordinate animation requests that come in on link messages.  keep a list of playing anims disable AO when needed
//upper layer: use the link message anim api to provide a pose menu

list g_lAnims;  //list of queued anims
list g_lPoseList;  //list of standard poses to use in the menu
integer g_iNumberOfAnims;  //we store this to avoid running createanimlist() every time inventory is changed...

//PoseMove tweak stuff
integer g_iTweakPoseAO = 0;  //Disable/Enable AO for posed animations - set it to 1 to default PoseMove tweak to ON
string g_sPoseMoveWalk;  //Variable to hold our current Walk animation
string g_sPoseMoveRun;  //Variable to hold our run animation
string g_sWalkButtonPrefix = "";  //This can be changed to prefix walks in the PoseMove menu
list g_lPoseMoveAnimationPrefix = ["~walk_","~run_"];

//for the height scaling feature
key g_kDataID;  //uuid of notecard read request
integer g_iLine = 0;  //records progress through notecard
list g_lAnimScalars;  //a 3-strided list in form animname,scalar,delay
integer g_iAdjustment = 0;  //heightfix on/off

string g_sCurrentPose = "";
integer g_iLastRank = 0;  //in this integer, save the rank of the person who posed the av, according to message map.  0 means unposed
integer g_iLastPostureRank = 504;
integer g_iLastPoselockRank = 504;
list g_lAnimButtons;  // initialized in state_entry for OpenSim compatibility (= ["Pose", "AO Menu", g_sGiveAO, "AO ON", "AO OFF"];)

integer g_iAnimLock = FALSE;  //animlock on/off
integer g_iPosture;  //posture lock on/off

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_SAFEWORD = 510;

//EXTERNAL MESSAGE MAP
integer EXT_COMMAND_COLLAR = 499;  //added for collar or cuff commands to put ao to pause or standOff

integer LM_SETTING_SAVE = 2000;  //scripts send messages on this channel to have settings saved to httpdb
integer LM_SETTING_RESPONSE = 2002;  //the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;  //delete token from DB

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer ANIM_START = 7000;
integer ANIM_STOP = 7001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer g_iAOChannel = -782690;
integer g_iInterfaceChannel = -12587429;

key g_kWearer;
string g_sWearerName;

list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

integer g_iHeightFix = TRUE;  //stores setting for should we use heightfix or not
list g_lHeightFixAnims;  //stores a list of all of the heighfix anims installed in the collar
integer g_iMaxHeightAdjust;  //largest height fix anim
integer g_iMinHeightAdjust;  //smallest height fix anim

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

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);  //we've alread given a menu to this user.  overwrite their entry
    else g_lMenuIDs += [kID, kMenuID, sName];  //we've not already given this user a menu. append to list
    //Debug("Made "+sName+" menu.");
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

AnimMenu(key kID, integer iAuth) {
    string sPrompt = g_sWearerName;
    list lButtons;
    
    if (g_iAnimLock) {
        sPrompt += " is forbidden to change or stop poses on their own";
        lButtons = ["☒ AnimLock"];
    } else {
        sPrompt += " is allowed to change or stop poses on their own";
        lButtons = ["☐ AnimLock"];
    }
    
    if (llGetInventoryType("~stiff")==INVENTORY_ANIMATION) {
        if (g_iPosture) {
            sPrompt +=" and has their neck forced stiff.";
            lButtons += ["☒ Posture"];
        } else {
            sPrompt +=" and can relax their neck.";
            lButtons += ["☐ Posture"];
        }
    }
    
    if (g_iTweakPoseAO) lButtons += ["☒ AntiSlide"];
    else lButtons += ["☐ AntiSlide"];

    lButtons += ["AO Menu", "AO ON", "AO OFF", "Pose"];

    sPrompt +="\n\nwww.opencollar.at/animations";

    Dialog(kID, sPrompt, lButtons+g_lAnimButtons, ["BACK"], 0, iAuth, "Anim");
}

PoseMenu(key kID, integer iPage, integer iAuth) {  //create a list
    string sPrompt = "\nChoose a pose to play.\n\nwww.opencollar.at/animations\n\nCurrent Pose is ";
    if (g_sCurrentPose == "")sPrompt += "None\n";
    else sPrompt += g_sCurrentPose +"\n";

    string sHeightFixButton= "☐ HeightFix";
    if (g_iHeightFix) sHeightFixButton = "☒ HeightFix";

    list lUtilityButtons=["STOP", "BACK"];
    if (g_iHeightFix) lUtilityButtons=["↑","↓"]+lUtilityButtons;

    Dialog(kID, sPrompt, [sHeightFixButton]+g_lPoseList, lUtilityButtons, iPage, iAuth, "Pose");
}

PoseMoveMenu(key kID, integer iPage, integer iAuth) {
    string sPrompt = "\nChoose a pose to play.\n\nwww.opencollar.at/animations\n\n";
    list lButtons;
    if (g_iTweakPoseAO) {
        sPrompt += "\nThe AntiSlide tweak is enabled.";
        lButtons += ["OFF"];
    } else {
        sPrompt += "\nThe AntiSlide tweak is disabled.";
        lButtons += ["ON"];
    }
    if (g_sPoseMoveWalk != "") {
       if (g_iTweakPoseAO) {
           sPrompt += "\n\nSelected Walk: "+g_sPoseMoveWalk;
           if (llGetInventoryKey(g_sPoseMoveRun)) sPrompt += "\nSelected Run: "+g_sPoseMoveRun;
           else sPrompt += "\nSelected Run: ~run";
       }
       lButtons += ["☐ none"];
    } else {
       sPrompt += "\n\nAntiSlide is not overriding any walk animations.";
       lButtons += ["☒ none"];
    }
    integer i = 0;
    integer iAnims = llGetInventoryNumber(INVENTORY_ANIMATION) - 1;
    string sAnim;
    for (i=0;i<=iAnims;++i) {
        sAnim = llGetInventoryName(INVENTORY_ANIMATION,i);
        if (llSubStringIndex(sAnim,llList2String(g_lPoseMoveAnimationPrefix,0)) == 0 ) {
            if (sAnim == g_sPoseMoveWalk) lButtons += ["☒ " + g_sWalkButtonPrefix+ llGetSubString(sAnim,llStringLength(llList2String(g_lPoseMoveAnimationPrefix,0)),-1)];
            else lButtons += ["☐ " +g_sWalkButtonPrefix+ llGetSubString(sAnim,llStringLength(llList2String(g_lPoseMoveAnimationPrefix,0)),-1)];
        }
    }

    Dialog(kID, sPrompt, lButtons, ["BACK"], 0, iAuth, "AntiSlide");
}

AOMenu(key kID, integer iAuth) {  // wrapper to send menu back to the AO's menu
    llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarCommand|" + (string)iAuth + "|ZHAO_MENU|" + (string)kID);
    llRegionSayTo(g_kWearer,g_iAOChannel, "ZHAO_MENU|" + (string)kID);
}

integer SetPosture(integer iOn, key kCommander) {
    if (llGetInventoryType("~stiff")!=INVENTORY_ANIMATION) return FALSE;
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
        if (iOn && !g_iPosture) {
            llStartAnimation("~stiff");
            if (kCommander) Notify(kCommander,"Posture override active.",TRUE);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "anim_posture=1","");
        } else if (!iOn) {
            llStopAnimation("~stiff");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_posture", "");
        }
        g_iPosture=iOn;
        return TRUE;
    } else {
        llOwnerSay("Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.");
        return FALSE;
    }
}

RefreshAnim() {  //g_lAnims can get lost on TP, so re-play g_lAnims[0] here, and call this function in "changed" event on TP
    if (llGetListLength(g_lAnims)) {
        if (g_iPosture) llStartAnimation("~stiff");
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
            llResetAnimationOverride("ALL");
            string sAnim = llList2String(g_lAnims, 0);
            if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) StartAnim(sAnim);  //get and stop currently playing anim
        } else llOwnerSay( "Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.");
    }
}

StartAnim(string sAnim) {  //adds anim to queue, calls PlayAnim to play it, and calls AO as necessary
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) {
            //stop currently playing anim
            if (llGetListLength(g_lAnims)) UnPlayAnim(llList2String(g_lAnims, 0));

            //add new anim to list
            g_lAnims = [sAnim] + g_lAnims;  //this way, g_lAnims[0] is always the currently playing anim
            
            //play new anim
            PlayAnim(sAnim);

            //switch off AO
            llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarComand|" + (string)EXT_COMMAND_COLLAR + "|ZHAO_STANDOFF");
            llRegionSayTo(g_kWearer,g_iAOChannel, "ZHAO_STANDOFF");
        }
    } else llOwnerSay( "Error: Somehow I lost permission to animate you.  Try taking me off and re-attaching me.");
}

PlayAnim(string sAnim){  //plays anim and heightfix, depending on methods configured for each
    //play anim
    if (g_iTweakPoseAO) {
        llSetAnimationOverride( "Standing", sAnim);
        if (g_sPoseMoveWalk) llSetAnimationOverride( "Walking", g_sPoseMoveWalk);
        if (g_sPoseMoveRun) {
            if (llGetInventoryKey(g_sPoseMoveRun)) llSetAnimationOverride( "Running", g_sPoseMoveRun);
            else if (llGetInventoryKey("~run")) llSetAnimationOverride( "Running", "~run");
        }
    } else llStartAnimation(sAnim);

    //play heightfix
    if (g_iHeightFix) {
        integer iIndex = llListFindList(g_lAnimScalars, [sAnim]);
        if (~iIndex) {  //we just started playing an anim in our g_lAnimScalars list
            llSleep((float)llList2String(g_lAnimScalars, iIndex + 2));  //pause to give certain anims time to ease in

            vector vAvScale = llGetAgentSize(g_kWearer);
            float fScalar = (float)llList2String(g_lAnimScalars, iIndex + 1);
            g_iAdjustment = llRound(vAvScale.z * fScalar);
            if (g_iAdjustment > g_iMaxHeightAdjust) g_iAdjustment = g_iMaxHeightAdjust;
            else if (g_iAdjustment < g_iMinHeightAdjust) g_iAdjustment = g_iMinHeightAdjust;

            llStartAnimation("~" + (string)g_iAdjustment);
        }
    }
    
}

StopAnim(string sAnim) {  //deals with removing anim from queue, calls UnPlayAnim to stop it, calls AO as nexessary
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) {
            //remove all instances of stopped anim from the queue
            while(~llListFindList(g_lAnims,[sAnim])){
                integer n=llListFindList(g_lAnims,[sAnim]);
                g_lAnims=llDeleteSubList(g_lAnims, n, n);
            }

            //stop the pose
            UnPlayAnim(sAnim);
            
            //play the new g_lAnims[0].  If anim list is empty, turn AO back on
            if (llGetListLength(g_lAnims)) PlayAnim(llList2String(g_lAnims, 0));
            else {
                llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarComand|" + (string)EXT_COMMAND_COLLAR + "|ZHAO_STANDON");
                llRegionSayTo(g_kWearer,g_iAOChannel, "ZHAO_STANDON");
            }
        }
    } else llOwnerSay( "Error: Somehow I lost permission to animate you.  Try taking me off and re-attaching me.");
}

UnPlayAnim(string sAnim){  //stops anim and heightfix, depending on methods configured for each
    //stop the pose
    if (g_iTweakPoseAO) llResetAnimationOverride("ALL");
    else llStopAnimation(sAnim);

    //stop any currently-playing height adjustment
    if (g_iAdjustment) {
        llStopAnimation("~" + (string)g_iAdjustment);
        g_iAdjustment = 0;
    }
}

CreateAnimList() {
    g_lPoseList=[];
    g_lHeightFixAnims=[];
    g_iNumberOfAnims=llGetInventoryNumber(INVENTORY_ANIMATION);

    integer iNumberOfAnims = g_iNumberOfAnims;
    while (iNumberOfAnims--) {
        string sName=llGetInventoryName(INVENTORY_ANIMATION, iNumberOfAnims);

        if (sName != "" && llGetSubString(sName, 0, 0) != "~") g_lPoseList+=[sName];  //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)

        if (llSubStringIndex(sName,"~")==0 && llStringLength(sName)==4) {
            sName=llGetSubString(sName,1,3);
            if ((integer)sName != 0) g_lHeightFixAnims += sName;
        }
    }

    g_lHeightFixAnims=llListSort(g_lHeightFixAnims,1,1);
    g_iMaxHeightAdjust=llList2Integer(g_lHeightFixAnims,0);
    g_iMinHeightAdjust=llList2Integer(g_lHeightFixAnims,-1);
}

AdjustOffset(integer direction) {
    if (llGetListLength(g_lAnims)>0) {  //first, check we're running an anim
        //get sleep time from list
        string sNewAnim = llList2String(g_lAnims, 0);
        integer iIndex = llListFindList(g_lAnimScalars, [sNewAnim]);
        string sleepTime="2.0";
        if (iIndex != -1) {
            sleepTime=llList2String(g_lAnimScalars, iIndex + 2);
            g_lAnimScalars=llDeleteSubList(g_lAnimScalars,iIndex,iIndex+2);  //we re-write it at the end
        }

        //stop last adjustment anim and play next one
        integer iOldAdjustment=g_iAdjustment;
        if (g_iAdjustment) {
            g_iAdjustment+=direction;
            while (g_iAdjustment > g_iMinHeightAdjust && g_iAdjustment < g_iMaxHeightAdjust && !~llListFindList(g_lHeightFixAnims,[(string)g_iAdjustment])) {
                //Debug("Re-adjust "+(string)g_iAdjustment);
                g_iAdjustment+=direction;
            }

            if (g_iAdjustment > g_iMaxHeightAdjust) {
                g_iAdjustment = 0;
                llOwnerSay(sNewAnim+" height fix cancelled");
            } else if (g_iAdjustment < g_iMinHeightAdjust) g_iAdjustment = g_iMinHeightAdjust;
        } else if (direction == -1) g_iAdjustment=g_iMaxHeightAdjust;

        if (g_iAdjustment != 0) {
            llStartAnimation("~" + (string)g_iAdjustment);

            //now calculate the new offset for notecard dump print
            vector avscale = llGetAgentSize(g_kWearer);
            float test = (float)g_iAdjustment/avscale.z;
            llOwnerSay(sNewAnim+"|"+(string)test+"|"+sleepTime);

            //and store it
            g_lAnimScalars+=[sNewAnim,test,sleepTime];
        }

        if (iOldAdjustment && iOldAdjustment != g_iAdjustment) {
            llStopAnimation("~" + (string)iOldAdjustment);
        }
    }
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum == COMMAND_EVERYONE) return;  // No command for people with no privilege in this plugin.

    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));
    if (sCommand == "menu") {
        string sSubmenu = llGetSubString(sStr, 5, -1);
        if (sSubmenu == "Pose") PoseMenu(kID, 0, iNum);
        else if (sSubmenu == "AntiSlide") PoseMoveMenu(kID,0,iNum);
        else if (sSubmenu == "AO") AOMenu(kID, iNum);
        else if (sSubmenu == "Animations") AnimMenu(kID, iNum);
    } else if (sStr == "release" || sStr == "stop") {  //only release if person giving command outranks person who posed us
        if (iNum <= g_iLastRank || !g_iAnimLock) {
            g_iLastRank = 0;
            llMessageLinked(LINK_SET, ANIM_STOP, g_sCurrentPose, "");
            g_sCurrentPose = "";
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_currentpose", "");
        }
    } else if (sStr == "animations") AnimMenu(kID, iNum);  //give menu
    else if (sStr == "pose") PoseMenu(kID, 0, iNum);  //pose menu
    else if (sStr == "runaway" && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER)) {  //stop pose on runaway
        if (g_sCurrentPose != "") StopAnim(g_sCurrentPose);
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_currentpose", "");
        llResetScript();
    } else if ( sCommand=="posture") {  //posture
        if ( sValue=="on") {  //posture
            if (iNum<=COMMAND_WEARER) {
                g_iLastPostureRank=iNum;
                SetPosture(TRUE,kID);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "anim_PostureRank="+(string)g_iLastPostureRank,"");
                llOwnerSay( "Your neck is locked in place.");
                if (kID != g_kWearer) Notify(kID, g_sWearerName + "'s neck is locked in place.", FALSE);
            } else Notify(kID,"Only owners can do that, sorry.",FALSE);
        } else if ( sValue=="off") {
            if (iNum<=g_iLastPostureRank) {
                g_iLastPostureRank=COMMAND_WEARER;
                SetPosture(FALSE,kID);
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_PostureRank", "");
                llOwnerSay( "You can move your neck again.");
                if (kID != g_kWearer) Notify(kID, g_sWearerName + " is free to move their neck.", FALSE);
            } else Notify(kID,"Someone more important locked "+g_sWearerName+"'s neck in this position",FALSE);
        }
    } else if ( sCommand=="animlock") {  //anim lock
        if ( sValue=="on") {  //anim lock
            if (iNum<=COMMAND_WEARER) {
                g_iLastPoselockRank=iNum;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "anim_PoselockRank="+(string)g_iLastPoselockRank,"");
                g_iAnimLock = TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "anim_animlock=1", "");
                llOwnerSay( "Only owners can change or stop your poses now.");
                if (kID != g_kWearer) Notify(kID, g_sWearerName + " can have their poses changed or stopped only by owners.", FALSE);
            } else Notify(kID,"You don't have permission to lock "+g_sWearerName+" in this position",FALSE);
        } else if ( sValue=="off") {
            if (iNum<=g_iLastPoselockRank) {
                g_iAnimLock = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_animlock", "");
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_PoselockRank", "");
                llOwnerSay( "You are now free to change or stop poses on your own.");
                if (kID != g_kWearer) Notify(kID, g_sWearerName + " is free to change or stop poses on their own.", FALSE);
            } else Notify(kID,"Someone more important locked "+g_sWearerName+" in this position",FALSE);
        }
    } else if ( sCommand=="heightfix") {  //heightfix
        if ((iNum == COMMAND_OWNER)||(kID == g_kWearer)) {
            if (sValue=="on"){
                g_iHeightFix = TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_HFix", "");
            } else if (sValue=="off"){
                g_iHeightFix = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "anim_HFix=0", "");
            }
            Notify(kID, "HeightFix override "+sValue+".", TRUE);
            
            if (g_sCurrentPose != "") {
                StopAnim(g_sCurrentPose);
                StartAnim(g_sCurrentPose);
            }
        } else Notify(kID,"Only owners or the wearer can change HeightFix settings.",FALSE);
    } else if (sCommand == "ao") {  //AO
        if (sValue == "" || sValue == "menu") AOMenu(kID, iNum);
        else if (sValue == "off") {
            llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOOFF|" + (string)kID);
            llRegionSayTo(g_kWearer,g_iAOChannel,"ZHAO_AOOFF");
        } else if (sValue == "on") {
            llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOON|" + (string)kID);
            llRegionSayTo(g_kWearer,g_iAOChannel,"ZHAO_AOON");
        } else if (sValue == "lock") llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_LOCK|" + (string)kID);
        else if (sValue == "unlock") llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_UNLOCK|" + (string)kID);
        else if (sValue == "hide") llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOHIDE|" + (string)kID);
        else if (sValue == "show") llRegionSayTo(g_kWearer,g_iInterfaceChannel, "CollarCommand|" + (string)iNum + "|ZHAO_AOSHOW|" + (string)kID);
    } else if (sCommand == "antislide") {  //check for text command of PoseMoveMenu's string
        if ((iNum == COMMAND_OWNER)||(kID == g_kWearer)) {
            string sValueNotLower = llList2String(lParams, 1);
            if (sValue == "on") {
                g_iTweakPoseAO = 1;
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "anim_TweakPoseAO=1" , "");
                RefreshAnim();
                Notify(kID, "AntiSlide is now enabled.", TRUE);
            } else if (sValue == "off") {
                g_iTweakPoseAO = 0;
                llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "anim_TweakPoseAO", "");
                RefreshAnim();
                Notify(kID, "AntiSlide is now disabled.", TRUE);
            } else if (sValue == "none") {
                llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "anim_PoseMoveWalk", "");
                g_sPoseMoveWalk = "";
                g_sPoseMoveRun = "";
                RefreshAnim();
                Notify(kID, "AntiSlide animation is \"none\".", TRUE);
            } else if (llGetInventoryType(llList2String(g_lPoseMoveAnimationPrefix,0)+sValueNotLower)==INVENTORY_ANIMATION) {
                g_sPoseMoveWalk = llList2String(g_lPoseMoveAnimationPrefix,0) + sValueNotLower;
                g_sPoseMoveRun  = llList2String(g_lPoseMoveAnimationPrefix,1) + sValueNotLower;
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "anim_PoseMoveWalk=" + g_sPoseMoveWalk, "");
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "anim_PoseMoveRun="  + g_sPoseMoveRun,  "");
                RefreshAnim();
                Notify(kID, "AntiSlide animation is \""+sValueNotLower+"\".", TRUE);
            } else if (sValue=="") PoseMoveMenu(kID,0,iNum);
            else Notify(kID,"Can't find animation "+llList2String(g_lPoseMoveAnimationPrefix,0)+sValueNotLower,FALSE);
        } else llOwnerSay( "Only owners or the wearer can change antislide settings.");
    } else if (llGetInventoryType(sStr) == INVENTORY_ANIMATION) {  //strike a pose...
        if (iNum <= g_iLastRank || !g_iAnimLock || g_sCurrentPose == "") {
            if (g_sCurrentPose != "") llMessageLinked(LINK_SET, ANIM_STOP, g_sCurrentPose, "");
            g_sCurrentPose = sStr;
            g_iLastRank = iNum;
            llMessageLinked(LINK_SET, ANIM_START, g_sCurrentPose, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "anim_currentpose=" + g_sCurrentPose + "," + (string)g_iLastRank, "");
        } else Notify(kID, "Someone more important has locked "+g_sWearerName+" in this position.",FALSE);
    }
}

default {
    on_rez(integer iNum) {
        if (llGetOwner() != g_kWearer) llResetScript();
        if (llGetAttached()) llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS );
    }

    state_entry() {
        g_kWearer = llGetOwner();
        g_sWearerName = llGetDisplayName(g_kWearer);
        if (g_sWearerName == "???" || g_sWearerName == "") g_sWearerName == llKey2Name(g_kWearer);

        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;

        if (llGetAttached()) llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS );
        CreateAnimList();
        if (llGetInventoryKey("~heightscalars")) g_kDataID = llGetNotecardLine("~heightscalars", g_iLine);  //start reading the ~heightscalars notecard
        //Debug("Starting");
    }

    dataserver(key kID, string sData) {
        if (kID == g_kDataID) {
            if (sData != EOF) {
                g_lAnimScalars += llParseString2List(sData, ["|"], []);
                g_kDataID = llGetNotecardLine("~heightscalars", ++g_iLine);
            }
            //else Debug("Notecard read complete");
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_TELEPORT) RefreshAnim();

        if (iChange & CHANGED_INVENTORY) {  //start re-reading the ~heightscalars notecard
            g_lAnimScalars = [];
            g_iLine = 0;
            if (llGetInventoryKey("~heightscalars")) g_kDataID = llGetNotecardLine("~heightscalars", g_iLine);
            if (g_iNumberOfAnims!=llGetInventoryNumber(INVENTORY_ANIMATION)) CreateAnimList();
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

    run_time_permissions(integer iPerm) {
        if (iPerm & PERMISSION_TRIGGER_ANIMATION) {
            if (g_iPosture) llStartAnimation("~stiff");
        }
    }

    attach(key kID) {
        if (kID == NULL_KEY) {  //we were just detached.  clear the anim list and tell the ao to play stands again.
            llRegionSayTo(g_kWearer,g_iInterfaceChannel, (string)EXT_COMMAND_COLLAR + "|ZHAO_STANDON");
            llRegionSayTo(g_kWearer,g_iAOChannel, "ZHAO_STANDON");
            g_lAnims = [];
        }
        else llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum <= COMMAND_EVERYONE && iNum >= COMMAND_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == ANIM_START) StartAnim(sStr);
        else if (iNum == ANIM_STOP) StopAnim(sStr);
        else if (iNum == MENUNAME_REQUEST && sStr == "Main") {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Main|Animations", "");  //no need for fixed main menu
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Animations", "");
        } else if (iNum == MENUNAME_RESPONSE) {
            if (llSubStringIndex(sStr, "Animations|")==0) {  //if sStr starts with "Animations|"
                string child = llList2String(llParseString2List(sStr, ["|"], []), 1);
                if (llListFindList(g_lAnimButtons, [child]) == -1) g_lAnimButtons += [child];
            }
        } else if (iNum == COMMAND_SAFEWORD) {  // saefword command recieved, release animation
            if (llGetInventoryType(g_sCurrentPose) == INVENTORY_ANIMATION) {
                g_iLastRank = 0;
                llMessageLinked(LINK_SET, ANIM_STOP, g_sCurrentPose, "");
                g_iAnimLock = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "anim_animlock", "");
                g_sCurrentPose = "";
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == "anim_") {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "currentpose") {
                    list lAnimParams = llParseString2List(sValue, [","], []);
                    g_sCurrentPose = llList2String(lAnimParams, 0);
                    g_iLastRank = (integer)llList2String(lAnimParams, 1);
                    llMessageLinked(LINK_SET, ANIM_START, g_sCurrentPose, "");
                } else if (sToken == "animlock") g_iAnimLock = (integer)sValue;
                else if (sToken =="posture") SetPosture((integer)sValue,NULL_KEY);
                else if (sToken == "PoseMoveWalk") g_sPoseMoveWalk = sValue;
                else if (sToken == "PoseMoveRun") g_sPoseMoveRun = sValue;
                else if (sToken == "TweakPoseAO") g_iTweakPoseAO = (integer)sValue;
                else if (sToken == "PostureRank") g_iLastPostureRank= (integer)sValue;
                else if (sToken == "PoselockRank") g_iLastPoselockRank= (integer)sValue;
                else if (sToken == "TweakPoseAO") g_iTweakPoseAO = (integer)sValue;
                else if (sToken == "HFix") g_iHeightFix = (integer)sValue;
            } else if (sToken == "Global_WearerName") g_sWearerName = sValue;
        } else if (iNum == LM_SETTING_DELETE) {
            if (llSubStringIndex(sStr, "Global_WearerName") == 0 ) {
                integer iInd = llSubStringIndex(sStr, "=");
                g_sWearerName = llGetDisplayName(g_kWearer);
                if (g_sWearerName == "???" || g_sWearerName == "") g_sWearerName == llKey2Name(g_kWearer);
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {  //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = llList2Integer(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);

                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == "Anim") {
                    //Debug("Got message "+sMessage);
                    if (sMessage == "BACK") llMessageLinked(LINK_SET, iAuth, "menu Main", kAv);
                    else if (sMessage == "Pose") PoseMenu(kAv, 0, iAuth);
                    else if (llGetSubString(sMessage, 2, -1) == "AntiSlide") PoseMoveMenu(kAv,iNum,iAuth);  //This is the Animation menu item, we need to call the PoseMoveMenu item from here...
                    else if (~llListFindList(g_lAnimButtons, [sMessage])) llMessageLinked(LINK_SET, iAuth, "menu " + sMessage, kAv);  // SA: can be child scripts menus, not handled in UserCommand()
                    else if (sMessage == "AO Menu") {
                        Notify(kAv, "Attempting to trigger the AO menu. This will only work if " + g_sWearerName + " is using a Submissive AO or an AO Link script in their normal AO.", FALSE);
                        AOMenu(kAv, iAuth);
                    } else {
                        if (sMessage== "☐ AnimLock") UserCommand(iAuth, "animlock on", kAv);
                        else if (sMessage== "☒ AnimLock") UserCommand(iAuth, "animlock off", kAv);
                        else if (sMessage== "☐ Posture") UserCommand(iAuth, "posture on", kAv);
                        else if (sMessage== "☒ Posture") UserCommand(iAuth, "posture off", kAv);
                        else UserCommand(iAuth, sMessage, kAv);
                        AnimMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "Pose") {
                    if (sMessage == "BACK") AnimMenu(kAv, iAuth);  //return on parent menu, so the animmenu below doesn't come up
                    else {
                        if (sMessage == "STOP") UserCommand(iAuth, "release", kAv);
                        else if (sMessage == "↑") AdjustOffset(1);
                        else if (sMessage == "↓") AdjustOffset(-1);
                        else if (sMessage == "☒ HeightFix") UserCommand(iAuth, "heightfix off", kAv);
                        else if (sMessage == "☐ HeightFix") UserCommand(iAuth, "heightfix on", kAv);
                        else UserCommand(iAuth, sMessage, kAv);  //got pose name
                        PoseMenu(kAv, iPage, iAuth);
                    }
                } else if (sMenuType == "AntiSlide") {
                    if (sMessage == "BACK") AnimMenu(kAv, iAuth);  //return on parent menu, so the animmenu below doesn't come up
                    else {
                        if (sMessage == "ON") UserCommand(iAuth, "antislide on", kAv);
                        else if (sMessage == "OFF") UserCommand(iAuth, "antislide off", kAv);
                        else if (llGetSubString(sMessage,2,-1) == "none" ) UserCommand(iAuth, "antislide none", kAv);
                        else if (llGetInventoryType(llList2String(g_lPoseMoveAnimationPrefix,0)+llGetSubString(sMessage,2+llStringLength(g_sWalkButtonPrefix),-1))==INVENTORY_ANIMATION) UserCommand(iAuth, "antislide "+llGetSubString(sMessage,2+llStringLength(g_sWalkButtonPrefix),-1), kAv);
                        PoseMoveMenu(kAv,iNum,iAuth);
                    }
                }
            }
        }
    }
}
