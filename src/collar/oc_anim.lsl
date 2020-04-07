// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Garvin Twine, Cleo Collins,
// Master Starship, Satomi Ahn, Joy Stipe, Wendy Starfall, Medea Destiny,
// Sumi Perl, Romka Swallowtail, littlemousy, North Glenwalker et al.
// Licensed under the GPLv2.  See LICENSE for full details.
string g_sScriptVersion = "7.4";
integer LINK_CMD_DEBUG=1999;
DebugOutput(key kID, list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llInstantMessage(kID, llGetScriptName() +final);
}
integer g_iIsMoving=FALSE;
// Needs to handle anim requests from sister scripts as well
// This script as essentially two layers
// Lower layer: coordinate animation requests that come in on link messages.  keep a list of playing anims disable AO when needed
// Upper layer: use the link message anim api to provide a pose menu

list g_lAnims; // List of queued anims
list g_lPoseList; // List of standard poses to use in the menu
list g_lOtherAnims; // List of animations not in g_lPoseList to forward to requesting scripts
integer g_iNumberOfAnims; // We store this to avoid running createanimlist() every time inventory is changed...

//PoseMove tweak stuff
integer g_bTweakPoseAO = FALSE; // Disable/Enable AO for posed animations - set it to 1 to default PoseMove tweak to ON
string g_sPoseMoveWalk; // Variable to hold our current Walk animation
string g_sPoseMoveRun; // Variable to hold our run animation
string g_sWalkButtonPrefix = ""; // This can be changed to prefix walks in the PoseMove menu
list g_lPoseMoveAnimationPrefix = ["~walk_", "~run_"];

string g_sCurrentPose = "";
integer g_iLastRank = 0; // In this integer, save the rank of the person who posed the av, according to message map.  0 means unposed
integer g_iLastPostureRank = 504;
integer g_iLastPoselockRank = 504;
list g_lAnimButtons; // Initialized in state_entry for OpenSim compatibility (= ["Pose", "AO Menu", g_sGiveAO, "AO ON", "AO OFF"];)

integer g_bAnimLock = FALSE;
integer g_bPosture; // Posture lock on/off
list g_lHeightAdjustments;
integer g_bRLVaOn;
integer g_bHoverOn = TRUE;
float g_fHoverIncrement = 0.02;
float g_fStandHover = 0.0;
string g_sPose2Remove;

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;
integer CMD_NOACCESS = 599; // This is formerly CMD_EVERYONE. However.. CMD_EVERYONE was meant to be PUBLIC access... 

// EXTERNAL MESSAGE MAP
integer EXT_CMD_COLLAR = 499; // Added for collar or cuff commands to put ao to pause or standOff
integer ATTACHMENT_RESPONSE = 601;

integer NOTIFY = 1002;
integer LOADPIN = -1904;
integer REBOOT = -1000;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer RLV_CMD = 6000;
integer RLV_OFF = 6100;
//integer RLV_ON  = 6101;
integer RLVA_VERSION = 6004;
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

list g_lMenuIDs; // Three strided list of kAvatar, kDialogID, sMenuName
integer g_iMenuStride = 3;

/*
integer g_iProfiled;
Debug(string sStr) {
  // If you delete the first // from the preceeding and following  lines,
  // profiling is off, debug is off, and the compiler will remind you to
  // remove the debug calls from the code, we're back to production mode
  if (!g_iProfiled) {
    g_iProfiled = 1;
    llScriptProfiler(1);
  }
  llOwnerSay(llGetScriptName() + "(min free:" + (string)(llGetMemoryLimit() - llGetSPMaxMemory()) + ")[" + (string)llGetFreeMemory() + "] :\n" + sStr);
}
*/

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else {
        g_lMenuIDs += [kID, kMenuID, sName];  // We've not already given this user a menu. append to list
    }
    //Debug("Made " + sName + " menu.");
}
integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

AnimMenu(key kID, integer iAuth) {
    string sPrompt = "\n[Animations]\n\n%WEARERNAME%";
    list lButtons;

    if (g_bAnimLock) {
        sPrompt += " is forbidden to change or stop poses on their own";
    } else {
        sPrompt += " is allowed to change or stop poses on their own";
    }
    lButtons += [Checkbox(g_bAnimLock, "AnimLock")];

    if (llGetInventoryType("~stiff") == INVENTORY_ANIMATION) {
        lButtons += Checkbox(g_bPosture, "Posture");
        if (g_bPosture) {
            sPrompt += " and has their neck forced stiff.";
        } else {
            sPrompt += " and can relax their neck.";
        }
    } else {
        sPrompt += "\n* Posture unavailable because the ~stiff anim is not present";
    }

    lButtons += Checkbox(g_bTweakPoseAO, "AntiSlide");
    lButtons += ["AO Menu", "AO ON", "AO OFF", "Pose"];

    Dialog(kID, sPrompt, lButtons + g_lAnimButtons, ["BACK"], 0, iAuth, "Anim");
}

PoseMenu(key kID, integer iPage, integer iAuth) { // Create a list
    string sPrompt = "\n[Pose]\n\nCurrently playing: ";

    if (g_sCurrentPose == "") {
        sPrompt += "-\n";
    } else {
        string sActivePose = g_sCurrentPose;
        if (g_bRLVaOn && g_bHoverOn) {
            integer iIndex = llListFindList(g_lHeightAdjustments, [g_sCurrentPose]);
            if (~iIndex) {
                string sAdjustment = llList2String(g_lHeightAdjustments, iIndex + 1);

                if ((float)sAdjustment > 0.0) {
                    sAdjustment = " (+" + llGetSubString(sAdjustment, 0, 3) + ")";
                } else if ((float)sAdjustment < 0.0) {
                    sAdjustment = " (" + llGetSubString(sAdjustment, 0, 4) + ")";
                } else {
                    sAdjustment = "";
                }

                sActivePose = g_sCurrentPose + sAdjustment;
            }
        }
        sPrompt += sActivePose + "\n";
    }

    if (g_fStandHover != 0.0 && g_bRLVaOn && g_bHoverOn) {
        string sAdjustment;

        if (g_fStandHover > 0.0) {
            sAdjustment = "+" + llGetSubString((string)g_fStandHover, 0, 3);
        } else if (g_fStandHover < 0.0) {
            sAdjustment = llGetSubString((string)g_fStandHover, 0, 4);
        }

        sPrompt += "Default Hover = " + sAdjustment;
    }

    //sPrompt += "Current Height Adjustment: " + g_sHeightAdjustment + "\n";
    list lStaticButtons = ["STOP", "BACK"];
    if (g_bRLVaOn && g_bHoverOn) {
        lStaticButtons = ["↑", "↓"] + lStaticButtons;
    }

    Dialog(kID, sPrompt, g_lPoseList, lStaticButtons, iPage, iAuth, "Pose");
}

PoseMoveMenu(key kID, integer iAuth) {
    string sPrompt;
    list lButtons;

    if (g_bTweakPoseAO) {
        sPrompt += "\nThe AntiSlide tweak is enabled.";
        lButtons += ["OFF"];
    } else {
        sPrompt += "\nThe AntiSlide tweak is disabled.";
        lButtons += ["ON"];
    }

    if (g_sPoseMoveWalk != "") {
        if (g_bTweakPoseAO) {
            sPrompt += "\n\nSelected Walk: " + g_sPoseMoveWalk;
            if (llGetInventoryType(g_sPoseMoveRun) == INVENTORY_ANIMATION) {
                sPrompt += "\nSelected Run: " + g_sPoseMoveRun;
            } else {
                sPrompt += "\nSelected Run: ~run";
            }
        }

    } else {
        sPrompt += "\n\nAntiSlide is not overriding any walk animations.";
    }
    
    lButtons += Checkbox(bool((g_sPoseMoveWalk=="")),"none");

    integer i = 0;
    integer iAnims = llGetInventoryNumber(INVENTORY_ANIMATION) - 1;
    string sAnim;

    for (; i <= iAnims; ++i) {
        sAnim = llGetInventoryName(INVENTORY_ANIMATION, i);
        if (llSubStringIndex(sAnim, llList2String(g_lPoseMoveAnimationPrefix, 0)) == 0) {
            lButtons += Checkbox(sAnim == g_sPoseMoveWalk, g_sWalkButtonPrefix + llGetSubString(sAnim, llStringLength(llList2String(g_lPoseMoveAnimationPrefix, 0)), -1));
        }
    }

    Dialog(kID, sPrompt, lButtons, ["BACK"], 0, iAuth, "AntiSlide");
}

AOMenu(key kID, integer iAuth) { // Wrapper to send menu back to the AO's menu
    // com script needs to send this from root
    llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, "CollarCommand|" + (string)iAuth + "|ZHAO_MENU|" + (string)kID, g_kWearer);
    llRegionSayTo(g_kWearer, g_iAOChannel, "ZHAO_MENU|" + (string)kID);
}

integer SetPosture(integer bOn, key kCommander) {
  if (llGetInventoryType("~stiff") != INVENTORY_ANIMATION) {
    return FALSE;
  }

  if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) {
    if (bOn && !g_bPosture) {
      llStartAnimation("~stiff");
      if (kCommander) {
        llMessageLinked(LINK_SET, NOTIFY, "1" + "Posture override active.", kCommander);
      }
      llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "posture=1","");
    } else if (!bOn) {
      llStopAnimation("~stiff");
      llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "posture", "");
    }
    g_bPosture = bOn;
    return TRUE;
  } else {
    llMessageLinked(LINK_SET, NOTIFY, "0" + "Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.", g_kWearer);
    return FALSE;
  }
}

MessageAOs(string sONOFF, string sWhat) { // send string as "ON" / "OFF" saves 2 llToUpper
    llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, "CollarCommand|" + (string)EXT_CMD_COLLAR + "|ZHAO_" + sWhat + sONOFF, g_kWearer);
    llRegionSayTo(g_kWearer, g_iAOChannel, "ZHAO_" + sWhat + sONOFF);
    llRegionSayTo(g_kWearer, -8888, (string)g_kWearer + "boot" + llToLower(sONOFF)); // for Firestorm AO
}

RefreshAnim() { // g_lAnims can get lost on TP, so re-play g_lAnims[0] here, and call this function in "changed" event on TP
  if (g_lAnims) {
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
      if (g_bPosture) {
        llStartAnimation("~stiff");
      }

      if (g_bTweakPoseAO) {
        llResetAnimationOverride("ALL");
      }

      StartAnim(llList2String(g_lAnims, 0));
      // string sAnim = llList2String(g_lAnims, 0);
      // if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) StartAnim(sAnim);  //get and stop currently playing anim
    } else {
      llMessageLinked(LINK_SET, NOTIFY, "0" + "Error: Permission to animate lost. Try taking me off and re-attaching me.", g_kWearer);
    }
  }
}

StartAnim(string sAnim) { // Adds anim to queue, calls PlayAnim to play it, and calls AO as necessary
  if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
    if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) {
      if (llGetListLength(g_lAnims)) {
        UnPlayAnim(llList2String(g_lAnims, 0));
      }

      g_lAnims = [sAnim] + g_lAnims; // This way, g_lAnims[0] is always the currently playing anim
      PlayAnim(sAnim);
      MessageAOs("OFF", "STAND");
    }
  } else {
    llMessageLinked(LINK_SET, NOTIFY, "0" + "Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.", g_kWearer);
  }
}

PlayAnim(string sAnim) { // Plays anim and heightfix, depending on methods configured for each
  if (g_bTweakPoseAO) {
    if (g_sPoseMoveWalk) {
      llSetAnimationOverride("Walking", g_sPoseMoveWalk);
    }

    if (g_sPoseMoveRun) {
      if (llGetInventoryType(g_sPoseMoveRun) == INVENTORY_ANIMATION) {
        llSetAnimationOverride("Running", g_sPoseMoveRun);
      } else if (llGetInventoryKey("~run")) {
        llSetAnimationOverride("Running", "~run");
      }
    }
  }

  if (g_bRLVaOn && g_bHoverOn) {
    integer iIndex = llListFindList(g_lHeightAdjustments, [sAnim]);
    if (~iIndex) {
      llMessageLinked(LINK_SET, RLV_CMD, "adjustheight:1;0;" + llList2String(g_lHeightAdjustments, iIndex + 1) + "=force", g_kWearer);
    } else if (g_fStandHover) {
      llMessageLinked(LINK_SET, RLV_CMD, "adjustheight:1;0;" + (string)g_fStandHover + "=force", g_kWearer);
    }
  }

  llStartAnimation(sAnim);
}

StopAnim(string sAnim) { // Deals with removing anim from queue, calls UnPlayAnim to stop it, calls AO as nexessary
  if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION && llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
    if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION) {
      integer n;
      while(~(n = llListFindList(g_lAnims, [sAnim]))) {
        g_lAnims = llDeleteSubList(g_lAnims, n, n);
      }
      UnPlayAnim(sAnim);
      //play the new g_lAnims[0].  If anim list is empty, turn AO back on
      if (g_lAnims) {
        PlayAnim(llList2String(g_lAnims, 0));
      } else {
        MessageAOs("ON", "STAND");
      }
    }
  } else {
    llMessageLinked(LINK_SET, NOTIFY, "0" + "Error: Somehow I lost permission to animate you. Try taking me off and re-attaching me.", g_kWearer);
  }
}

UnPlayAnim(string sAnim) { // Stops anim and heightfix, depending on methods configured for each
  if (g_bTweakPoseAO && llGetAnimationOverride("Standing") != "") {
    llResetAnimationOverride("ALL");
  }

  if (g_bRLVaOn && g_bHoverOn) {
    llMessageLinked(LINK_SET, RLV_CMD, "adjustheight:1;0;" + (string)g_fStandHover + "=force", g_kWearer);
  }

  llStopAnimation(sAnim);
}

CreateAnimList() {
  g_lPoseList = [];
  g_lOtherAnims = [];
  g_iNumberOfAnims = llGetInventoryNumber(INVENTORY_ANIMATION);

  string sName;
  integer i;

  do {
    sName = llGetInventoryName(INVENTORY_ANIMATION, i);
    if (sName != "" && llSubStringIndex(sName, "~")) {
      if (!~llListFindList(["-1", "-2", "+1", "+2"], [llGetSubString(sName, -2, -1)])) {
        g_lPoseList += sName;
      }
    } else if (!llSubStringIndex(sName, "~")) {
      g_lOtherAnims += sName;
    }
  } while (g_iNumberOfAnims > ++i);

  llMessageLinked(LINK_SET, ANIM_LIST_RESPONSE, llDumpList2String(g_lPoseList + g_lOtherAnims, "|"), "");
}

UserCommand(integer iNum, string sStr, key kID) {
  if (iNum == CMD_NOACCESS) { // No command for people with no privilege in this plugin.
    return;
  }

  list lParams = llParseString2List(sStr, [" "], []);
  string sCommand = llToLower(llList2String(lParams, 0));
  string sValue = llToLower(llList2String(lParams, 1));

  if (sCommand == "menu") {
    if (sValue == "pose") {
      PoseMenu(kID, 0, iNum);
    } else if (sValue == "antislide") {
      PoseMoveMenu(kID, iNum);
    } else if (sValue == "ao") {
      AOMenu(kID, iNum);
    } else if (sValue == "animations") {
      AnimMenu(kID, iNum);
    }
  } else if (sStr == "release" || sStr == "stop") { // Only release if person giving command outranks person who posed us
    if (iNum <= g_iLastRank || !g_bAnimLock) {
      g_iLastRank = 0;
      StopAnim(g_sCurrentPose);
      g_sCurrentPose = "";
      llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "currentpose", "");
    }
  } else if (sStr == "animations") {
    AnimMenu(kID, iNum);
  } else if (sStr == "pose") {
    PoseMenu(kID, 0, iNum);
  } else if (sStr == "runaway" && (iNum == CMD_OWNER || iNum == CMD_WEARER)) {
    if (g_sCurrentPose != "") {
      StopAnim(g_sCurrentPose);
    }
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "currentpose", "");
  } else if (sCommand == "posture") {
    if (sValue == "on") {
      if (iNum <= CMD_EVERYONE) {
        g_iLastPostureRank=iNum;
        SetPosture(TRUE, kID);
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "PostureRank=" + (string)g_iLastPostureRank, "");
        llMessageLinked(LINK_SET, NOTIFY, "0" + "Your neck is locked in place.", g_kWearer);
        if (kID != g_kWearer) {
          llMessageLinked(LINK_SET, NOTIFY, "0" + "%WEARERNAME%'s neck is locked in place.", kID);
        }
      } else {
        llMessageLinked(LINK_SET, NOTIFY, "0" + "%NOACCESS% to change posture", kID);
      }
    } else if ( sValue=="off") {
      if (iNum <= g_iLastPostureRank) {
        g_iLastPostureRank = CMD_EVERYONE;
        SetPosture(FALSE, kID);
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "PostureRank", "");
        llMessageLinked(LINK_SET, NOTIFY, "0" + "You can move your neck again.", g_kWearer);
        if (kID != g_kWearer) {
          llMessageLinked(LINK_SET, NOTIFY, "0" + "%WEARERNAME% is free to move their neck.", kID);
        }
      } else {
        llMessageLinked(LINK_SET, NOTIFY, "0" + "%NOACCESS% to change posture", kID);
      }
    }
  } else if (sCommand == "rm" && sValue == "pose") {
    if (kID != g_kWearer || g_bAnimLock) {
      llMessageLinked(LINK_SET, NOTIFY, "0" + "%NOACCESS% to delete pose", kID);
      return;
    }

    g_sPose2Remove = llGetSubString(sStr, 8, -1);
    if (llGetInventoryType(g_sPose2Remove) == INVENTORY_ANIMATION) {
      string sPrompt = "\nATTENTION: The pose that you are about to delete is not copyable! It will be removed from the %DEVICETYPE% and sent to you. Please make sure to accept the inventory.\n\nDo you really want to remove the \"" + g_sPose2Remove + "\" pose?";
      if (llGetInventoryPermMask(g_sPose2Remove, MASK_OWNER) & PERM_COPY) {
        sPrompt = "\nDo you really want to remove the \"" + g_sPose2Remove + "\" pose?";
      }
      Dialog(g_kWearer, sPrompt, ["Yes", "No"], ["CANCEL"], 0, CMD_WEARER, "RmPose");
    } else {
      Dialog(g_kWearer, "\nWhich pose do you want to remove?\n", g_lPoseList, ["CANCEL"], 0, CMD_WEARER, "RmPoseSelect");
    }
  } else if (sCommand == "animlock") {
    if (sValue == "on") {
      if (iNum <= CMD_WEARER) {
        g_iLastPoselockRank = iNum;
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "PoselockRank=" + (string)g_iLastPoselockRank, "");
        g_bAnimLock = TRUE;
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "animlock=1", "");
        llMessageLinked(LINK_SET, NOTIFY, "0" + "Only owners can change or stop your poses now.", g_kWearer);
        if (kID != g_kWearer) {
          llMessageLinked(LINK_SET, NOTIFY, "0" + "%WEARERNAME% can have their poses changed or stopped only by owners.", kID);
        }
      } else {
        llMessageLinked(LINK_SET, NOTIFY, "0" + "%NOACCESS% to change animlock", kID);
      }
    } else if (sValue == "off") {
      if (iNum <= g_iLastPoselockRank) {
        g_bAnimLock = FALSE;
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "animlock", "");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "PoselockRank", "");
        llMessageLinked(LINK_SET, NOTIFY, "0" + "You are now free to change or stop poses on your own.", g_kWearer);
        if (kID != g_kWearer) {
          llMessageLinked(LINK_SET, NOTIFY, "0" + "%WEARERNAME% is free to change or stop poses on their own.", kID);
        }
      } else {
        llMessageLinked(LINK_SET, NOTIFY, "0" + "%NOACCESS% to change animlock", kID);
      }
    }
  } else if (sCommand == "ao") {
    if (sValue == "" || sValue == "menu") {
      AOMenu(kID, iNum);
    } else if (sValue == "off" || sValue == "on") {
      MessageAOs(llToUpper(sValue), "AO");
        AnimMenu(kID, iNum);
    } else {
      llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, "CollarCommand|" + (string)EXT_CMD_COLLAR + "|ZHAO_" + sStr + "|" + (string)kID, kID);
    }
  } else if (sCommand == "antislide") {
    if (iNum == CMD_OWNER || kID == g_kWearer) {
      string sValueNotLower = llList2String(lParams, 1);
      if (sValue == "on") {
        if (llGetAnimationOverride("Standing") != "") {
          g_bTweakPoseAO = TRUE;
          llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "TweakPoseAO=1" , "");
          RefreshAnim();
          llMessageLinked(LINK_SET, NOTIFY, "1" + "AntiSlide is now enabled.", kID);
        } else {
          llMessageLinked(LINK_SET, NOTIFY, "1" + "\n\nAntiSlide can't be used when a server-side AO is already running. If you are wearing the OpenCollar AO, it will take care of this functionality on its own and AntiSlide is not required.\n", kID);
        }
      } else if (sValue == "off") {
        g_bTweakPoseAO = FALSE;
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "TweakPoseAO", "");
        RefreshAnim();
        if (llList2String(lParams,2) == "") {
          llMessageLinked(LINK_SET, NOTIFY, "1" + "AntiSlide is now disabled.", kID);
        }
      } else if (sValue == "none") {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "PoseMoveWalk", "");
        g_sPoseMoveWalk = "";
        g_sPoseMoveRun = "";
        RefreshAnim();
        llMessageLinked(LINK_SET, NOTIFY, "1" + "AntiSlide animation is \"none\".", kID);
      } else if (llGetInventoryType(llList2String(g_lPoseMoveAnimationPrefix, 0) + sValueNotLower) == INVENTORY_ANIMATION) {
        g_sPoseMoveWalk = llList2String(g_lPoseMoveAnimationPrefix, 0) + sValueNotLower;
        g_sPoseMoveRun = llList2String(g_lPoseMoveAnimationPrefix, 1) + sValueNotLower;
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "PoseMoveWalk=" + g_sPoseMoveWalk, "");
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "PoseMoveRun=" + g_sPoseMoveRun, "");
        RefreshAnim();
        llMessageLinked(LINK_SET, NOTIFY, "1" + "AntiSlide animation is \"" + sValueNotLower + "\".", kID);
      } else if (sValue == "") {
        PoseMoveMenu(kID,iNum);
      } else {
        llMessageLinked(LINK_SET, NOTIFY, "0" + "Can't find animation " + llList2String(g_lPoseMoveAnimationPrefix, 0) + sValueNotLower, kID);
      }
    } else {
      llMessageLinked(LINK_SET, NOTIFY, "0" + "Only owners or the wearer can change antislide settings.", g_kWearer);
    }
  } else if (llGetInventoryType(sStr) == INVENTORY_ANIMATION) {
    if (iNum <= g_iLastRank || !g_bAnimLock || g_sCurrentPose == "") {
      StopAnim(g_sCurrentPose);
      g_sCurrentPose = sStr;
      g_iLastRank = iNum;
      StartAnim(g_sCurrentPose);
      llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "currentpose=" + g_sCurrentPose + "," + (string)g_iLastRank, "");
    } else {
      llMessageLinked(LINK_SET, NOTIFY, "0" + "%NOACCESS% to change pose", kID);
    }
  } 
}

ExtractPart(){
    g_sScriptPart = llList2String(llParseString2List(llGetScriptName(), ["_"],[]),1);
}

string g_sScriptPart; // oc_<part>
integer INDICATOR_THIS;
SearchIndicators(){
    ExtractPart();
    
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=0;i<end;i++){
        list Params = llParseStringKeepNulls(llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0), ["~"],[]);
        
        if(llListFindList(Params, ["indicator_"+g_sScriptPart])!=-1){
            INDICATOR_THIS = i;
            return;
        }
    }
    
    
}
/*
Indicator(integer iMode){
    if(INDICATOR_THIS==-1)return;
    if(iMode)
        llSetLinkPrimitiveParamsFast(INDICATOR_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
    else
        llSetLinkPrimitiveParamsFast(INDICATOR_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);
}*/


default {
    on_rez(integer iNum) {

        if (llGetOwner() != g_kWearer) {
            llResetScript();
        }

        g_bRLVaOn = FALSE;

        /*
        if (llGetAttached()) {
          llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS);
        }
        */
    }

    state_entry() {
        if (llGetStartParameter() != 0) {
            state inUpdate;
        }
        // llSetMemoryLimit(49152);  // 2015-05-06 (5490 bytes free)
        g_kWearer = llGetOwner();
        if (llGetAttached()) {
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS);
        }
        CreateAnimList();
        SearchIndicators();
        //Debug("Starting");
    }
    
    run_time_permissions(integer iPerm) {
        if (iPerm & PERMISSION_TRIGGER_ANIMATION) {
            if (g_bPosture) {
                llStartAnimation("~stiff");
            }
        }
    }

    attach(key kID) {
        if (kID == NULL_KEY) { // We were just detached.  clear the anim list and tell the ao to play stands again.
            //MessageAOs("ON","STAND");
            g_lAnims = [];
        } else {
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION | PERMISSION_OVERRIDE_ANIMATIONS);
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum <= CMD_EVERYONE && iNum >= CMD_OWNER) {
            UserCommand(iNum, sStr, kID);
        } else if (iNum == ANIM_START) {
            StartAnim(sStr);
        } else if (iNum == ANIM_STOP) {
            StopAnim(sStr);
        } else if (iNum == MENUNAME_REQUEST && sStr == "Main") {
            llMessageLinked(iSender, MENUNAME_RESPONSE, "Main|Animations", "");
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Animations", "");
        } else if (iNum == MENUNAME_RESPONSE) {
            if (llSubStringIndex(sStr, "Animations|") == 0) {
                string sChild = llList2String(llParseString2List(sStr, ["|"], []), 1);
                if (llListFindList(g_lAnimButtons, [sChild]) == -1) {
                    g_lAnimButtons += sChild;
                }
            }
        } else if (iNum == CMD_SAFEWORD) {
            if (llGetInventoryType(g_sCurrentPose) == INVENTORY_ANIMATION) {
                g_iLastRank = 0;
                StopAnim(g_sCurrentPose);
                g_bAnimLock = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "currentpose", "");
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "animlock", "");
                g_sCurrentPose = "";
            }
        } else if (iNum == ANIM_LIST_REQUEST) {
            CreateAnimList();
            llMessageLinked(iSender, ANIM_LIST_RESPONSE, llDumpList2String(g_lPoseList + g_lOtherAnims, "|"), "");
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "currentpose") {
                    list lAnimParams = llParseString2List(sValue, [","], []);
                    g_sCurrentPose = llList2String(lAnimParams, 0);
                    g_iLastRank = (integer)llList2String(lAnimParams, 1);
                    if(llGetListLength(g_lAnims)>0&&llList2String(g_lAnims,0)==g_sCurrentPose){}else
                        StartAnim(g_sCurrentPose);
                }
                else if (sToken == "animlock") g_bAnimLock = (integer)sValue;
                else if (sToken =="posture") SetPosture((integer)sValue, NULL_KEY);
                else if (sToken == "PoseMoveWalk") g_sPoseMoveWalk = sValue;
                else if (sToken == "PoseMoveRun") g_sPoseMoveRun = sValue;
                // else if (sToken == "TweakPoseAO") g_bTweakPoseAO = (integer)sValue;
                else if (sToken == "PostureRank") g_iLastPostureRank = (integer)sValue;
                else if (sToken == "PoselockRank") g_iLastPoselockRank = (integer)sValue;
                else if (sToken == "TweakPoseAO") {
                    if (llGetAnimationOverride("Standing") != "") {
                        g_bTweakPoseAO = (integer)sValue;
                    }
                }
            } else if (llGetSubString(sToken, 0, i) == "offset_") {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "AllowHover") {
                    g_bHoverOn = (integer)llGetSubString(sValue, 0, 0);
                    g_fHoverIncrement = (float)llGetSubString(sValue, 2, -1);
                    if (g_fHoverIncrement == 0.0) {
                        g_fHoverIncrement = 0.02;
                    }
                } else if (sToken == "hovers") {
                    g_lHeightAdjustments = llParseString2List(sValue, [","], []);
                } else if (sToken == "standhover") {
                    g_fStandHover = (float)sValue;
                }
            } else if(llToLower(llGetSubString(sToken,0,i)) == "global_"){
                sToken = llGetSubString(sToken, i+1,-1);
                if(sToken == "checkboxes"){
                    g_lCheckboxes = llCSV2List(sValue);
                }
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
                    //Debug("Got message " + sMessage);
                    if (sMessage == "BACK") {
                        llMessageLinked(LINK_SET, iAuth, "menu Main", kAv);
                        return;
                    } else if (sMessage == "Pose") {
                        PoseMenu(kAv, 0, iAuth);
                        return;
                    } else if (sMessage == Checkbox(g_bTweakPoseAO, "AntiSlide")){
                        PoseMoveMenu(kAv, iAuth);
                        return;
                    } else if (~llListFindList(g_lAnimButtons, [sMessage])) {
                        llMessageLinked(LINK_SET, iAuth, "menu " + sMessage, kAv);  // SA: can be child scripts menus, not handled in UserCommand()
                    } else if (sMessage == "AO Menu") {
                        llMessageLinked(LINK_SET, NOTIFY, "0" + "\n\nAttempting to trigger the AO menu. This will only work if %WEARERNAME% is using an OpenCollar AO or an AO Link script in their AO HUD.\n", kAv);
                        AOMenu(kAv, iAuth);
                        return;
                    } else {
                        integer stat = llListFindList(g_lCheckboxes, [llGetSubString(sMessage,0,0)]);
                        string cmd = llToLower(llGetSubString(sMessage,2,-1));
                        
                          
                        if(stat==-1){
                            UserCommand(iAuth,sMessage,kAv);
                            return;
                        }
                        if(stat) UserCommand(iAuth, cmd+" off",kAv);
                        else if(!stat) UserCommand(iAuth, cmd+" on",kAv);
                        AnimMenu(kAv, iAuth);
                          
                    }
                
                } else if (sMenuType == "Pose") {
                    if (sMessage == "BACK") {
                        AnimMenu(kAv, iAuth);
                    } else if (sMessage == "↑" || sMessage == "↓") {
                        float fNewHover = g_fHoverIncrement;
                        if (sMessage == "↓") fNewHover = -fNewHover;
                
                        if (g_sCurrentPose == "") {
                            g_fStandHover += fNewHover;
                            fNewHover = g_fStandHover;
                            if (g_fStandHover) {
                                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "offset_standhover=" + (string)g_fStandHover, "");
                            } else {
                                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "offset_standhover", "");
                            }
                        } else {
                            integer iIndex = llListFindList(g_lHeightAdjustments, [g_sCurrentPose]);
                            if (~iIndex) {
                                fNewHover = fNewHover + llList2Float(g_lHeightAdjustments, iIndex + 1);
                                if (fNewHover) {
                                    g_lHeightAdjustments = llListReplaceList(g_lHeightAdjustments, [fNewHover], iIndex + 1, iIndex + 1);
                                } else {
                                    g_lHeightAdjustments = llDeleteSubList(g_lHeightAdjustments, iIndex, iIndex + 1);
                                }
                            } else {
                                fNewHover += g_fStandHover;
                                g_lHeightAdjustments += [g_sCurrentPose, fNewHover];
                            }
                        }
            
                        llMessageLinked(LINK_SET, RLV_CMD, "adjustheight:1;0;" + (string)fNewHover + "=force", g_kWearer);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "offset_hovers=" + llDumpList2String(g_lHeightAdjustments, ","), "");
            
                        PoseMenu(kAv, iPage, iAuth);
                    } else {
                        if (sMessage == "STOP") {
                            UserCommand(iAuth, "release", kAv);
                        } else {
                            UserCommand(iAuth, sMessage, kAv);
                        }
            
                        PoseMenu(kAv, iPage, iAuth);
                    }
                } else if (sMenuType == "AntiSlide") {
                    if (sMessage == "BACK") {
                        AnimMenu(kAv, iAuth);
                    } else {
                        if (sMessage == "ON") {
                            UserCommand(iAuth, "antislide on", kAv);
                        } else if (sMessage == "OFF") {
                            UserCommand(iAuth, "antislide off", kAv);
                        } else if (llGetSubString(sMessage, 2, -1) == "none") {
                            UserCommand(iAuth, "antislide none", kAv);
                        } else if (llGetInventoryType(llList2String(g_lPoseMoveAnimationPrefix, 0) + llGetSubString(sMessage, 2 + llStringLength(g_sWalkButtonPrefix), -1)) == INVENTORY_ANIMATION) {
                            UserCommand(iAuth, "antislide " + llGetSubString(sMessage, 2 + llStringLength(g_sWalkButtonPrefix), -1), kAv);
                        }
                
                        PoseMoveMenu(kAv,iAuth);
                    }
                } else if (sMenuType == "RmPoseSelect") {
                    if (sMessage != "CANCEL") {                            
                        UserCommand(iAuth, "rm pose " + sMessage, kAv);
                    }
                } else if (sMenuType == "RmPose") {
                    if (sMessage == "Yes") {
                        if (llGetInventoryType(g_sPose2Remove) == INVENTORY_ANIMATION) {
                            if (llGetInventoryPermMask(g_sPose2Remove, MASK_OWNER) & PERM_COPY) {
                                llRemoveInventory(g_sPose2Remove);
                                llMessageLinked(LINK_SET,NOTIFY, "0" + "\n\nThe \"" + g_sPose2Remove + "\" pose has been removed from your %DEVICETYPE%.\n", g_kWearer);
                            } else {
                                llMessageLinked(LINK_SET,NOTIFY, "0" + "\n\nThe \"" + g_sPose2Remove + "\" pose has been removed from your %DEVICETYPE% and is now being delivered to you from an object called \"" + llGetObjectName() + "\". This particular pose is not copyable. If you want to keep it, please make sure to accept the inventory.\n", g_kWearer);
                                llGiveInventory(g_kWearer, g_sPose2Remove);
                            }
                        }
                        CreateAnimList();
                    }
                    g_sPose2Remove = "";
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex + 3); // Remove stride from g_lMenuIDs
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0) + 1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin + "@" + llGetScriptName(), llGetKey());
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        } else if (iNum == RLVA_VERSION) {
            g_bRLVaOn = TRUE;
        } else if (iNum == RLV_OFF) {
            g_bRLVaOn = FALSE;
        }else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            DebugOutput(kID, [" ANIM LOCK:", g_bAnimLock]);
            DebugOutput(kID, [" CURRENT POSE:", g_sCurrentPose]);
            DebugOutput(kID, [" POSE LIST:"]+g_lPoseList);
        
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_TELEPORT) RefreshAnim();
        
        if (iChange & CHANGED_INVENTORY) { // Start re-reading the ~heightscalars notecard
            if (g_iNumberOfAnims != llGetInventoryNumber(INVENTORY_ANIMATION)) {
                CreateAnimList();
            }
        }
    }

}
state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
        else if(iNum == 0){
            if(sMsg == "do_move" && !g_iIsMoving){
                
                if(llGetLinkNumber()==LINK_ROOT || llGetLinkNumber() == 0)return;
                
                list Parameters = llParseStringKeepNulls(llList2String(llGetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_DESC]),0), ["~"],[]);
                ExtractPart();
                Parameters += "indicator_"+g_sScriptPart;
                llSetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_DESC, llDumpList2String(Parameters,"~")]);
                
                g_iIsMoving=TRUE;
                llOwnerSay("Moving oc_anim!");
                integer i=0;
                integer end=llGetInventoryNumber(INVENTORY_ALL);
                for(i=0;i<end;i++){
                    string item = llGetInventoryName(INVENTORY_ALL,i);
                    if(llGetInventoryType(item)==INVENTORY_SCRIPT && item!=llGetScriptName()){
                        llRemoveInventory(item);
                    }else if(llGetInventoryType(item)!=INVENTORY_SCRIPT){
                        if (llGetInventoryPermMask( item, MASK_OWNER ) & PERM_COPY){
                            llGiveInventory(kID, item);
                            llRemoveInventory(item);
                            i=-1;
                            end=llGetInventoryNumber(INVENTORY_ALL);
                        } else {
                            llOwnerSay("Item '"+item+"' is no-copy and can not be moved! Please move it manually!");
                        }
                    }
                }
                
                llRemoveInventory(llGetScriptName());
            }
        }
    }
}
