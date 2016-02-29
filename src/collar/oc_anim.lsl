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
//                          Animator - 160229.1                             //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Nandana Singh, Garvin Twine, Cleo Collins,    //
//  Master Starship, Satomi Ahn, Joy Stipe, Wendy Starfall, Medea Destiny,  //
//  Sumi Perl, Romka Swallowtail, littlemousy, North Glenwalker et al.      //
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

//needs to handle anim requests from sister scripts as well
//this script as essentially two layers
//lower layer: coordinate animation requests that come in on link messages.  keep a list of playing anims disable AO when needed
//upper layer: use the link message anim api to provide a pose menu

list g_lAnims;  //list of queued anims
list g_lPoseList;  //list of standard poses to use in the menu
list g_lOtherAnims; //list of animations not in g_lPoseList to forward to requesting scripts
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

string g_sCurrentPose = "";
integer g_iLastRank = 0;  //in this integer, save the rank of the person who posed the av, according to message map.  0 means unposed
integer g_iLastPostureRank = 504;
integer g_iLastPoselockRank = 504;
list g_lAnimButtons;  // initialized in state_entry for OpenSim compatibility (= ["Pose", "AO Menu", g_sGiveAO, "AO ON", "AO OFF"];)

integer g_iAnimLock = FALSE;
integer g_iPosture;  //posture lock on/off
string g_sHeightAdjustment = "none"; // none, -1, -2 for lower and +1, +2 for higher
integer g_iHasAdjustment;
list g_lHeightAdjustments = ["-1","-2","+1","+2"];
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;

//EXTERNAL MESSAGE MAP
integer EXT_CMD_COLLAR = 499;  //added for collar or cuff commands to put ao to pause or standOff
integer ATTACHMENT_RESPONSE = 601;

integer NOTIFY = 1002;
integer LOADPIN = -1904;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer ANIM_START = 7000;
integer ANIM_STOP = 7001;
integer ANIM_LIST_REQUEST = 7002;
integer ANIM_LIST_RESPONSE =7003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer g_iAOChannel = -782690;

string g_sSettingToken = "anim_";
//string g_sGlobalToken = "global_";
key g_kWearer;

list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;
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
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];  //we've not already given this user a menu. append to list
    //Debug("Made "+sName+" menu.");
}

AnimMenu(key kID, integer iAuth) {
    string sPrompt = "\n[http://www.opencollar.at/animations.html Animations]\n\n%WEARERNAME%";
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

    Dialog(kID, sPrompt, lButtons+g_lAnimButtons, ["BACK"], 0, iAuth, "Anim");
}

PoseMenu(key kID, integer iPage, integer iAuth) {  //create a list
    string sPrompt = "\n[http://www.opencollar.at/animations.html Pose]\n\nCurrently playing: ";
    if (g_sCurrentPose == "")sPrompt += "-\n";
    string sActivePose = g_sCurrentPose;
    if (~llListFindList(g_lHeightAdjustments,[llGetSubString(sActivePose,-2,-1)]))
        sActivePose = llGetSubString(sActivePose,0,-3)+" ("+llGetSubString(sActivePose,-2,-1)+")";
    sPrompt += sActivePose +"\n";
    //sPrompt += "Current Height Adjustment: "+ g_sHeightAdjustment + "\n";
    list lStaticButtons = ["STOP", "BACK"];
    if (g_iHasAdjustment) lStaticButtons = ["↑", "↓"] + lStaticButtons;
    Dialog(kID, sPrompt, g_lPoseList, lStaticButtons, iPage, iAuth, "Pose");
}

PoseMoveMenu(key kID, integer iPage, integer iAuth) {
    string sPrompt;
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
   // com script needs to send this from root
    llMessageLinked(LINK_ROOT, ATTACHMENT_RESPONSE,"CollarCommand|"+(string)iAuth+"|ZHAO_MENU|"+(string)kID, g_kWearer);
    llRegionSayTo(g_kWearer,g_iAOChannel, "ZHAO_MENU|" + (string)kID);
}

integer SetPosture(integer iOn, key kCommander) {
    if (llGetInventoryType("~stiff")!=INVENTORY_ANIMATION) return FALSE;
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
        if (iOn && !g_iPosture) {
            llStartAnimation("~stiff");
            if (kCommander) llMessageLinked(LINK_DIALOG, NOTIFY, "1"+"Posture override active.", kCommander);
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"posture=1","");
        } else if (!iOn) {
            llStopAnimation("~stiff");
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"posture", "");
        }
        g_iPosture=iOn;
        return TRUE;
    } else {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.",g_kWearer);
        return FALSE;
    }
}

MessageAOs(string sONOFF, string sWhat){ //send string as "ON"  / "OFF" saves 2 llToUpper
    llMessageLinked(LINK_ROOT, ATTACHMENT_RESPONSE,"CollarCommand|" + (string)EXT_CMD_COLLAR + "|ZHAO_"+sWhat+sONOFF, g_kWearer);
    llRegionSayTo(g_kWearer,g_iAOChannel, "ZHAO_"+sWhat+sONOFF);
    llRegionSayTo(g_kWearer,-8888,(string)g_kWearer+"boot"+llToLower(sONOFF)); //for Firestorm AO
}

RefreshAnim() {  //g_lAnims can get lost on TP, so re-play g_lAnims[0] here, and call this function in "changed" event on TP
    if (llGetListLength(g_lAnims)) {
        if (g_iPosture) llStartAnimation("~stiff");
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
            llResetAnimationOverride("ALL");
            string sAnim = llList2String(g_lAnims, 0);
            if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) StartAnim(sAnim);  //get and stop currently playing anim
        } else  llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Error: Permission to animate lost. Try taking me off and re-attaching me.",g_kWearer);
    }
}

StartAnim(string sAnim) {  //adds anim to queue, calls PlayAnim to play it, and calls AO as necessary
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) {
            if (llGetListLength(g_lAnims)) UnPlayAnim(llList2String(g_lAnims, 0));
            g_lAnims = [sAnim] + g_lAnims;  //this way, g_lAnims[0] is always the currently playing anim
            PlayAnim(sAnim);
            MessageAOs("OFF","STAND");
        }
    } else  llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.",g_kWearer);
}

PlayAnim(string sAnim){  //plays anim and heightfix, depending on methods configured for each
    if (g_iTweakPoseAO) {
        llSetAnimationOverride( "Standing", sAnim);
        if (g_sPoseMoveWalk) llSetAnimationOverride( "Walking", g_sPoseMoveWalk);
        if (g_sPoseMoveRun) {
            if (llGetInventoryKey(g_sPoseMoveRun)) llSetAnimationOverride( "Running", g_sPoseMoveRun);
            else if (llGetInventoryKey("~run")) llSetAnimationOverride( "Running", "~run");
        }
    } else llStartAnimation(sAnim);
}

StopAnim(string sAnim) {  //deals with removing anim from queue, calls UnPlayAnim to stop it, calls AO as nexessary
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) {
            while(~llListFindList(g_lAnims,[sAnim])){
                integer n=llListFindList(g_lAnims,[sAnim]);
                g_lAnims=llDeleteSubList(g_lAnims, n, n);
            }
            UnPlayAnim(sAnim);
            //play the new g_lAnims[0].  If anim list is empty, turn AO back on
            if (llGetListLength(g_lAnims)) PlayAnim(llList2String(g_lAnims, 0));
            else MessageAOs("ON","STAND");
        }
    } else  llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.",g_kWearer);
}

UnPlayAnim(string sAnim){  //stops anim and heightfix, depending on methods configured for each
    if (g_iTweakPoseAO) llResetAnimationOverride("ALL");
    else llStopAnimation(sAnim);
}

CreateAnimList() {
    g_lPoseList=[];
    g_lOtherAnims =[];
    g_iNumberOfAnims = llGetInventoryNumber(INVENTORY_ANIMATION);
    g_iHasAdjustment = FALSE;
    string sName;
    integer i;
    do { sName = llGetInventoryName(INVENTORY_ANIMATION, i);
        if (sName != "" && llSubStringIndex(sName,"~")) {
            if (!~llListFindList(g_lHeightAdjustments,[llGetSubString(sName,-2,-1)]))
                g_lPoseList+=[sName];
            else if (llGetSubString(sName,-2,-1) == "+1") g_iHasAdjustment = TRUE;
        } else if (!llSubStringIndex(sName,"~")) g_lOtherAnims+=sName;
    } while (g_iNumberOfAnims > ++i);
    llMessageLinked(LINK_SET,ANIM_LIST_RESPONSE,llDumpList2String(g_lPoseList+g_lOtherAnims,"|"),"");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum == CMD_EVERYONE) return;  // No command for people with no privilege in this plugin.

    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));
    if (sCommand == "menu") {
        if (sValue == "pose") PoseMenu(kID, 0, iNum);
        else if (sValue == "antislide") PoseMoveMenu(kID,0,iNum);
        else if (sValue == "ao") AOMenu(kID, iNum);
        else if (sValue == "animations") AnimMenu(kID, iNum);
    } else if (sStr == "release" || sStr == "stop") {  //only release if person giving command outranks person who posed us
        if (iNum <= g_iLastRank || !g_iAnimLock) {
            g_iLastRank = 0;
            llMessageLinked(LINK_THIS, ANIM_STOP, g_sCurrentPose, "");
            g_sCurrentPose = "";
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"currentpose", "");
        }
    } else if (sStr == "animations") AnimMenu(kID, iNum);
    else if (sStr == "pose") PoseMenu(kID, 0, iNum);
    else if (sStr == "runaway" && (iNum == CMD_OWNER || iNum == CMD_WEARER)) {
        if (g_sCurrentPose != "") StopAnim(g_sCurrentPose);
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"currentpose", "");
        //llResetScript();
    } else if (sCommand=="posture") {
        if ( sValue=="on") {
            if (iNum<=CMD_WEARER) {
                g_iLastPostureRank=iNum;
                SetPosture(TRUE,kID);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"PostureRank="+(string)g_iLastPostureRank,"");
                llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Your neck is locked in place.",g_kWearer);
                if (kID != g_kWearer) llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%WEARERNAME%'s neck is locked in place.", kID);
            } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kID);
        } else if ( sValue=="off") {
            if (iNum<=g_iLastPostureRank) {
                g_iLastPostureRank=CMD_WEARER;
                SetPosture(FALSE,kID);
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"PostureRank", "");
                llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"You can move your neck again.",g_kWearer);
                if (kID != g_kWearer) llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%WEARERNAME% is free to move their neck.", kID);
            }
                else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%",kID);
        }
    } else if (sCommand=="animlock") {
        if (sValue=="on") {
            if (iNum<=CMD_WEARER) {
                g_iLastPoselockRank=iNum;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"PoselockRank="+(string)g_iLastPoselockRank,"");
                g_iAnimLock = TRUE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"animlock=1", "");
                llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Only owners can change or stop your poses now.",g_kWearer);
                if (kID != g_kWearer) llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%WEARERNAME% can have their poses changed or stopped only by owners.", kID);
            } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kID);
        } else if (sValue=="off") {
            if (iNum<=g_iLastPoselockRank) {
                g_iAnimLock = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"animlock", "");
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"PoselockRank", "");
                llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"You are now free to change or stop poses on your own.",g_kWearer);
                if (kID != g_kWearer) llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%WEARERNAME% is free to change or stop poses on their own.", kID);
            } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kID);
        }
    } else if (sCommand == "ao") {
        if (sValue == "" || sValue == "menu") AOMenu(kID, iNum);
        else if (sValue == "off" || sValue == "on")
            MessageAOs(llToUpper(sValue),"AO");
        //else if (sValue == "on") MessageAOs("ON");
        //doesnt work as it should, needs adjustment in AO
        /*} else if (sValue == "lock") llMessageLinked(LINK_DIALOG, ATTACHMENT_RESPONSE,"CollarCommand|"+(string)iNum+"|ZHAO_LOCK|"+(string)kID, g_kWearer);
        else if (sValue == "unlock") llMessageLinked(LINK_DIALOG, ATTACHMENT_RESPONSE,"CollarCommand|"+(string)iNum+"|ZHAO_UNLOCK|"+(string)kID, g_kWearer);
        else if (sValue == "hide") llMessageLinked(LINK_DIALOG, ATTACHMENT_RESPONSE,"CollarCommand|"+(string)iNum+"|ZHAO_HIDE|"+(string)kID, g_kWearer);
        else if (sValue == "show") llMessageLinked(LINK_DIALOG, ATTACHMENT_RESPONSE,"CollarCommand|"+(string)iNum+"|ZHAO_SHOW|"+(string)kID, g_kWearer);*/
    } else if (sCommand == "antislide") {
        if ((iNum == CMD_OWNER)||(kID == g_kWearer)) {
            string sValueNotLower = llList2String(lParams, 1);
            if (sValue == "on") {
                g_iTweakPoseAO = 1;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"TweakPoseAO=1" , "");
                RefreshAnim();
                llMessageLinked(LINK_DIALOG, NOTIFY, "1"+"AntiSlide is now enabled.", kID);
            } else if (sValue == "off") {
                g_iTweakPoseAO = 0;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"TweakPoseAO", "");
                RefreshAnim();
                llMessageLinked(LINK_DIALOG, NOTIFY, "1"+"AntiSlide is now disabled.", kID);
            } else if (sValue == "none") {
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"PoseMoveWalk", "");
                g_sPoseMoveWalk = "";
                g_sPoseMoveRun = "";
                RefreshAnim();
                llMessageLinked(LINK_DIALOG, NOTIFY, "1"+"AntiSlide animation is \"none\".", kID);
            } else if (llGetInventoryType(llList2String(g_lPoseMoveAnimationPrefix,0)+sValueNotLower)==INVENTORY_ANIMATION) {
                g_sPoseMoveWalk = llList2String(g_lPoseMoveAnimationPrefix,0) + sValueNotLower;
                g_sPoseMoveRun  = llList2String(g_lPoseMoveAnimationPrefix,1) + sValueNotLower;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"PoseMoveWalk=" + g_sPoseMoveWalk, "");
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"PoseMoveRun="  + g_sPoseMoveRun,  "");
                RefreshAnim();
                llMessageLinked(LINK_DIALOG, NOTIFY, "1"+"AntiSlide animation is \""+sValueNotLower+"\".", kID);
            } else if (sValue=="") PoseMoveMenu(kID,0,iNum);
            else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Can't find animation "+llList2String(g_lPoseMoveAnimationPrefix,0)+sValueNotLower, kID);
        } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Only owners or the wearer can change antislide settings.",g_kWearer);
    } else if (llGetInventoryType(sStr) == INVENTORY_ANIMATION) {
        if (iNum <= g_iLastRank || !g_iAnimLock || g_sCurrentPose == "") {
            llMessageLinked(LINK_THIS, ANIM_STOP, g_sCurrentPose, "");
            if (g_sHeightAdjustment == "none" && ~llListFindList(g_lHeightAdjustments,[llGetSubString(sStr,-2,-1)]))
                sStr = llGetSubString(sStr,0,-3);
            else if (g_sHeightAdjustment != "none" && !~llListFindList(g_lHeightAdjustments,[llGetSubString(sStr,-2,-1)])) {
                if (llGetInventoryType(sStr + g_sHeightAdjustment) == INVENTORY_ANIMATION)
                    sStr = sStr + g_sHeightAdjustment;
            } else if (g_sHeightAdjustment != "none" && llGetSubString(sStr,-2,-1) != g_sHeightAdjustment) 
                sStr = llGetSubString(sStr,0,-3) + g_sHeightAdjustment;
            g_sCurrentPose = sStr;
            g_iLastRank = iNum;
            llMessageLinked(LINK_THIS, ANIM_START, g_sCurrentPose, "");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"currentpose=" + g_sCurrentPose + "," + (string)g_iLastRank, "");
        } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kID);
    } else if ((sStr == "show animator")&&(iNum == CMD_OWNER || kID == g_kWearer)){
        llSetPrimitiveParams([PRIM_TEXTURE,ALL_SIDES,TEXTURE_BLANK,<1,1,0>,ZERO_VECTOR,0.0,PRIM_FULLBRIGHT,ALL_SIDES,TRUE]);
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nTo hide the animator prim again type:\n\n/%CHANNEL%%PREFIX% hide animator\n",kID);
    } else if ((sStr == "hide animator")&&(iNum == CMD_OWNER || kID == g_kWearer))
        llSetPrimitiveParams([PRIM_TEXTURE,ALL_SIDES,TEXTURE_TRANSPARENT,<1,1,0>,ZERO_VECTOR,0.0,PRIM_FULLBRIGHT,ALL_SIDES,FALSE]);
}

default {
    on_rez(integer iNum) {
        if (iNum == 825) llSetRemoteScriptAccessPin(0);
        if (llGetOwner() != g_kWearer) llResetScript();
       //if (llGetAttached()) llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS );
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
       // llSetMemoryLimit(49152);  //2015-05-06 (5490 bytes free)
        g_kWearer = llGetOwner();
        if (llGetAttached()) llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS );
        CreateAnimList();
        if (llGetInventoryKey("~heightscalars")) g_kDataID = llGetNotecardLine("~heightscalars", g_iLine);
        llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_ANIM","");
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

    run_time_permissions(integer iPerm) {
        if (iPerm & PERMISSION_TRIGGER_ANIMATION) {
            if (g_iPosture) llStartAnimation("~stiff");
        }
    }

    attach(key kID) {
        if (kID == NULL_KEY) {  //we were just detached.  clear the anim list and tell the ao to play stands again.
            MessageAOs("ON","STAND");
            g_lAnims = [];
        }
        else llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum <= CMD_EVERYONE && iNum >= CMD_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == ANIM_START) StartAnim(sStr);
        else if (iNum == ANIM_STOP) StopAnim(sStr);
        else if (iNum == MENUNAME_REQUEST && sStr == "Main") {
            llMessageLinked(iSender, MENUNAME_RESPONSE, "Main|Animations", "");
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Animations", "");
        } else if (iNum == MENUNAME_RESPONSE) {
            if (llSubStringIndex(sStr, "Animations|")==0) {
                string child = llList2String(llParseString2List(sStr, ["|"], []), 1);
                if (llListFindList(g_lAnimButtons, [child]) == -1) g_lAnimButtons += [child];
            }
        } else if (iNum == CMD_SAFEWORD) {
            if (llGetInventoryType(g_sCurrentPose) == INVENTORY_ANIMATION) {
                g_iLastRank = 0;
                llMessageLinked(LINK_THIS, ANIM_STOP, g_sCurrentPose, "");
                g_iAnimLock = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"currentpose", "");
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"animlock", "");
                g_sCurrentPose = "";
            }
        } else if (iNum == ANIM_LIST_REQUEST)
            llMessageLinked(iSender,ANIM_LIST_RESPONSE,llDumpList2String(g_lPoseList+g_lOtherAnims,"|"),"");
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken+"") {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "currentpose") {
                    list lAnimParams = llParseString2List(sValue, [","], []);
                    g_sCurrentPose = llList2String(lAnimParams, 0);
                    g_iLastRank = (integer)llList2String(lAnimParams, 1);
                    llMessageLinked(LINK_THIS, ANIM_START, g_sCurrentPose, "");
                } else if (sToken == "animlock") g_iAnimLock = (integer)sValue;
                else if (sToken == "heightadjustment") g_sHeightAdjustment  = sValue;
                else if (sToken =="posture") SetPosture((integer)sValue,NULL_KEY);
                else if (sToken == "PoseMoveWalk") g_sPoseMoveWalk = sValue;
                else if (sToken == "PoseMoveRun") g_sPoseMoveRun = sValue;
                else if (sToken == "TweakPoseAO") g_iTweakPoseAO = (integer)sValue;
                else if (sToken == "PostureRank") g_iLastPostureRank= (integer)sValue;
                else if (sToken == "PoselockRank") g_iLastPoselockRank= (integer)sValue;
                else if (sToken == "TweakPoseAO") g_iTweakPoseAO = (integer)sValue;
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
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
                    else if (llGetSubString(sMessage, 2, -1) == "AntiSlide") PoseMoveMenu(kAv,iNum,iAuth);
                    else if (~llListFindList(g_lAnimButtons, [sMessage])) llMessageLinked(LINK_SET, iAuth, "menu " + sMessage, kAv);  // SA: can be child scripts menus, not handled in UserCommand()
                    else if (sMessage == "AO Menu") {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Attempting to trigger the AO menu. This will only work if %WEARERNAME% is using an OpenCollar AO or an AO Link script in their normal AO.", kAv);
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
                    if (sMessage == "BACK") AnimMenu(kAv, iAuth);
                    else if (sMessage == "↑") {
                        if (~llListFindList(g_lHeightAdjustments,[llGetSubString(g_sCurrentPose,-2,-1)]) || llGetInventoryType(g_sCurrentPose+"+1") == INVENTORY_ANIMATION && g_sCurrentPose != "") {
                            if (g_sHeightAdjustment == "+2") 
                                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"This is the maximum up.", kAv);
                            else {//if (g_sCurrentPose != "") {
                                g_sHeightAdjustment = (string)((integer)g_sHeightAdjustment + 1);
                                if ((integer)g_sHeightAdjustment > 0) g_sHeightAdjustment = "+"+g_sHeightAdjustment;
                                else if ((integer)g_sHeightAdjustment == 0) g_sHeightAdjustment = "none";
                                llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken+"heightadjustment="+g_sHeightAdjustment,"");
                                UserCommand(iAuth, g_sCurrentPose, kAv);
                            } 
                        } else if (g_sCurrentPose != "") 
                            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"There are no height adjustment poses for "+g_sCurrentPose+" in this %DEVICETYPE%.",kAv);
                        PoseMenu(kAv, iPage, iAuth);
                    } else if (sMessage == "↓") {
                        if (~llListFindList(g_lHeightAdjustments,[llGetSubString(g_sCurrentPose,-2,-1)]) || llGetInventoryType(g_sCurrentPose+"+1") == INVENTORY_ANIMATION && g_sCurrentPose != "") {
                            if (g_sHeightAdjustment == "-2") 
                                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"This is the maximum down.", kAv);
                            else {//if (g_sCurrentPose != "") {
                                g_sHeightAdjustment = (string)((integer)g_sHeightAdjustment - 1);
                                if ((integer)g_sHeightAdjustment > 0) g_sHeightAdjustment = "+"+g_sHeightAdjustment;
                                else if ((integer)g_sHeightAdjustment == 0) g_sHeightAdjustment = "none";
                                llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken+"heightadjustment="+g_sHeightAdjustment,"");
                                UserCommand(iAuth, g_sCurrentPose, kAv);
                            } 
                        } else if (g_sCurrentPose != "") 
                            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"There are no height adjustment poses for "+g_sCurrentPose+" in this %DEVICETYPE%.",kAv);
                        PoseMenu(kAv, iPage, iAuth);                        
                    } else {
                        if (sMessage == "STOP") UserCommand(iAuth, "release", kAv);
                        else UserCommand(iAuth, sMessage, kAv);
                        PoseMenu(kAv, iPage, iAuth);
                    }
                } else if (sMenuType == "AntiSlide") {
                    if (sMessage == "BACK") AnimMenu(kAv, iAuth);
                    else {
                        if (sMessage == "ON") UserCommand(iAuth, "antislide on", kAv);
                        else if (sMessage == "OFF") UserCommand(iAuth, "antislide off", kAv);
                        else if (llGetSubString(sMessage,2,-1) == "none" ) UserCommand(iAuth, "antislide none", kAv);
                        else if (llGetInventoryType(llList2String(g_lPoseMoveAnimationPrefix,0)+llGetSubString(sMessage,2+llStringLength(g_sWalkButtonPrefix),-1))==INVENTORY_ANIMATION) UserCommand(iAuth, "antislide "+llGetSubString(sMessage,2+llStringLength(g_sWalkButtonPrefix),-1), kAv);
                        PoseMoveMenu(kAv,iNum,iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
            else if (sStr == "LINK_REQUEST") llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_ANIM","");
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
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
}
