// This file is part of OpenCollar.
// Copyright (c) 2014 - 2017 Wendy Starfall, littlemousy, Sumi Perl,
// Garvin Twine, Romka Swallowtail et al.
// Licensed under the GPLv2.  See LICENSE for full details.


// Menu setup
string RESTRICTION_BUTTON = "Restrictions"; // Name of the submenu
string RESTRICTIONS_CHAT_COMMAND = "restrictions";
string TERMINAL_BUTTON = "Terminal"; // RLV command terminal button for TextBox
string TERMINAL_CHAT_COMMAND = "terminal";
string OUTFITS_BUTTON = "Outfits";
string COLLAR_PARENT_MENU = "RLV";
string UPMENU = "BACK";
string BACKMENU = "⏎";

integer g_iMenuCommand;
key g_kMenuClicker;

list g_lMenuIDs;
integer g_iMenuStride = 3;

//string g_sSettingToken = "restrictions_";
//string g_sGlobalToken = "global_";

// Restriction vars
integer g_bSendRestricted;
integer g_bReadRestricted;
integer g_bHearRestricted;
integer g_bTalkRestricted;
integer g_bTouchRestricted;
integer g_bStrayRestricted;
integer g_bRummageRestricted;
integer g_bStandRestricted;
integer g_bDressRestricted;
integer g_bBlurredRestricted;
integer g_bDazedRestricted;

integer g_bSitting;

// Outfit vars
integer g_iListener;
integer g_iFolderRLV = 98745923;
integer g_iFolderRLVSearch = 98745925;
integer g_iTimeOut = 30; // Timeout on viewer response commands
integer g_bRLVOn = FALSE;
integer g_bRLVaOn = FALSE;
string g_sCurrentPath;
string g_sPathPrefix = ".outfits"; // We look for outfits in here

list g_lAttachments; // 2-strided list in form [name, uuid]
key g_kWearer;

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;
integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;
//integer LM_SETTING_REQUEST_NOCACHE = 2005;

// messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

// Messages for RLV commands
integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002; // RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_OFF = 6100;
integer RLV_ON = 6101;
integer RLVA_VERSION = 6004;

// Messages to the dialog helper
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;

integer g_iAuth;

key g_kLastForcedSeat;
string g_sLastForcedSeat;
string g_sTerminalText = "\n[RLV Command Terminal]\n\nType one command per line without \"@\" sign.";

/*
integer g_bProfiled;
Debug(string sStr) {
  // If you delete the first // from the preceeding and following  lines,
  // profiling is off, debug is off, and the compiler will remind you to
  // remove the debug calls from the code, we're back to production mode
  if (!g_bProfiled) {
    g_bProfiled = TRUE;
    llScriptProfiler(TRUE);
  }
  llOwnerSay(llGetScriptName() + "(min free:" + (string)(llGetMemoryLimit() - llGetSPMaxMemory()) + ")[" + (string)llGetFreeMemory() + "] :\n" + sStr);
}
*/

Dialog(key kRCPT, string sPrompt, list lButtons, list lUtilityButtons, integer iPage, integer iAuth, string sMenuID) {
  key kMenuID = llGenerateKey();
  if (sMenuID == "sensor" || sMenuID == "find") {
    llMessageLinked(LINK_DIALOG, SENSORDIALOG, (string)kRCPT + "|" + sPrompt + "|0|``" + (string)(SCRIPTED | PASSIVE) + "`20`" + (string)PI + "`" + llDumpList2String(lUtilityButtons, "`") + "|" + llDumpList2String(lButtons, "`") + "|" + (string)iAuth, kMenuID);
  } else {
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lButtons, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
  }

  integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
  if (~iIndex) {
    g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuID], iIndex, iIndex + g_iMenuStride - 1);
  } else {
    g_lMenuIDs += [kRCPT, kMenuID, sMenuID];
  }
}

integer CheckLastSit(key kSit) {
  vector vAvPos = llGetPos();
  list lLastSeatInfo = llGetObjectDetails(kSit, [OBJECT_POS]);
  vector vLastSeatPos = (vector)llList2String(lLastSeatInfo, 0);
  if (llVecDist(vAvPos, lLastSeatPos) < 20) {
    return TRUE;
  } else {
    return FALSE;
  }
}

string Checkbox(integer iValue, string sLabel) {
  if (iValue) return "☑ " + sLabel;
  else return "☐ " + sLabel;
}

SitMenu(key kID, integer iAuth) {
  integer bSitting = llGetAgentInfo(g_kWearer) & AGENT_SITTING;
  string sButton;
  string sSitPrompt = "\nAbility to Stand up is ";
  if (g_bStandRestricted) sSitPrompt += "restricted by ";
  else sSitPrompt += "un-restricted.\n";

  if (g_bStandRestricted == 500) sSitPrompt += "Owner.\n";
  else if (g_bStandRestricted == 501) sSitPrompt += "Trusted.\n";
  else if (g_bStandRestricted == 502) sSitPrompt += "Group.\n";

  if (g_bStandRestricted) sButton = "☑ Strict`";
  else sButton = "☐ Strict`";

  if (bSitting) {
    sButton += "[Get up]`BACK";
  } else {
    if (CheckLastSit(g_kLastForcedSeat)) {
      sButton += "[Sit back]`BACK";
      sSitPrompt = "\nLast forced to sit on " + g_sLastForcedSeat + "\n";
    } else {
      sButton += "BACK";
    }
  }

  Dialog(kID, sSitPrompt + "\nChoose a seat:\n", [sButton], [], 0, iAuth, "sensor");
}


RestrictionsMenu(key keyID, integer iAuth) {
  string sPrompt = "\n[Restrictions]";
  list lButtons = [
    Checkbox(g_bSendRestricted, "Send IMs"),
    Checkbox(g_bReadRestricted, "Read IMs"),
    Checkbox(g_bHearRestricted, "Hear"),

    Checkbox(g_bTalkRestricted, "Talk"),
    Checkbox(g_bTouchRestricted, "Touch"),
    Checkbox(g_bStrayRestricted, "Stray"),

    Checkbox(g_bRummageRestricted, "Rummage"),
    Checkbox(g_bDressRestricted, "Dress"),
    "RESET"
  ];

  if (g_bBlurredRestricted) lButtons += "Un-Dazzle";
  else lButtons += "Dazzle";

  if (g_bDazedRestricted) lButtons += "Un-Daze";
  else lButtons += "Daze";

  Dialog(keyID, sPrompt, lButtons, ["BACK"], 0, iAuth, "restrictions");
}

DoTerminalCommand(string sMessage, key kID) {
  string sCRLF = llUnescapeURL("%0A");
  list lCommands = llParseString2List(sMessage, [sCRLF], []);
  sMessage = llDumpList2String(lCommands, ",");

  llMessageLinked(LINK_RLV, RLV_CMD, sMessage, "vdTerminal");
  llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Your command(s) were sent to %WEARERNAME%'s RL-Viewer:\n" + sMessage, kID);
  llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "secondlife:///app/agent/" + (string)kID + "/about" + " has changed your RLV restrictions.", g_kWearer);
}

OutfitsMenu(key kID, integer iAuth) {
  g_kMenuClicker = kID; // On our listen response, we need to know who to pop a dialog for
  g_iAuth = iAuth;
  g_sCurrentPath = g_sPathPrefix + "/";
  llSetTimerEvent(g_iTimeOut);
  g_iListener = llListen(g_iFolderRLV, "", g_kWearer, "");
  llOwnerSay("@getinv:" + g_sCurrentPath + "=" + (string)g_iFolderRLV);
}

FolderMenu(key keyID, integer iAuth,string sFolders) {
  string sPrompt = "\n[Outfits]";
  sPrompt += "\n\nCurrent Path = " + g_sCurrentPath;
  list lButtons = llParseString2List(sFolders, [","], [""]);
  lButtons = llListSort(lMyButtons, 1, TRUE);
  // And dispay the menu
  list lStaticButtons;
  if (g_sCurrentPath == g_sPathPrefix + "/") { // If we're at root, don't bother with BACKMENU
    lStaticButtons = [UPMENU];
  } else {
    if (sFolders == "") {
      lStaticButtons = ["WEAR", UPMENU, BACKMENU];
    } else {
      lStaticButtons = [UPMENU, BACKMENU];
    }
  }
  Dialog(keyID, sPrompt, lMyButtons, lStaticButtons, 0, iAuth, "folder");
}

WearFolder(string sStr) { // Function grabs g_sCurrentPath, and splits out the final directory path, attaching .core directories and passes RLV commands
  string sAttach = "@attachallover:" + sStr + "=force,attachallover:" + g_sPathPrefix + "/.core/=force";
  string sPrePath;
  list lTempSplit = llParseString2List(sStr, ["/"], []);
  lTempSplit = llList2List(lTempSplit, 0, llGetListLength(lTempSplit) - 2);
  sPrePath = llDumpList2String(lTempSplit,"/");
  if (g_sPathPrefix + "/" != sPrePath) {
    sAttach += ",attachallover:" + sPrePath + "/.core/=force";
  }
  //Debug("rlv:" + sOutput);
  llOwnerSay("@remoutfit=force,detach=force");
  llSleep(1.5); // Delay for SSA
  llOwnerSay(sAttach);
}

DetachMenu(key kID, integer iAuth) {
  // Remember not to add button for current object
  // str looks like 0110100001111
  // Loop through CLOTH_POINTS, look at char of str for each
  // for each 1, add capitalized button
  string sPrompt = "\nSelect an attachment to remove.\n";
  g_lAttachments = [];

  list lAttachmentKeys = llGetAttachedList(llGetOwner());
  integer i;
  integer iLength = llGetListLength(lAttachmentKeys);
  for (; i < iLength; i++) {
    key kAttachment = llList2Key(lAttachmentKeys, i);
    if (kAttachment != llGetKey()) {
      g_lAttachments += [llKey2Name(i), i];
    }
  }

  list lButtons;
  iLength = llGetListLength(g_lAttachments);

  for (i = 0; i < iLength; i += 2) {
    lButtons += [llList2String(g_lAttachments, i)];
  }

  Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "detach");
}

string BoolToRLV(integer bValue, string sRestrictions) {
  list lRestrictions = llParseString2List(sRestrictions, [","], []);
  integer iLength = llGetListLength(lRestrictions);

  if (iLength == 1) {
    if (bValue) {
      return sRestrictions + "=n";
    } else {
      return sRestrictions + "=y";
    }
  }

  string sResult = "";
  integer i;
  for (; i < iLength; i++) {
    if (sResult != "") {
      sResult += ",";
    }
    sResult += llList2String(lRestrictions, i);
    if (bValue) {
      sResult += "=n";
    } else {
      sResult += "=y";
    }
  }
  return sResult;
}

DoRestrictions() {
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bSendRestricted, "sendim"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bReadRestricted, "recvim"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bHearRestricted, "recvchat"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bTalkRestricted, "sendchat"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bTouchRestricted, "touchall"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bStrayRestricted, "tplm,tploc,tplure,sittp"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bStandRestricted, "unsit"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bRummageRestricted, "showinv,viewscript,viewtexture,edit,rez"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bDressRestricted, "addattach,remattach,defaultwear,addoutfit,remoutfit"), "vdRestrict");
  llMessageLinked(LINK_RLV, RLV_CMD, BoolToRLV(g_bDazedRestricted, "shownames,showhovertextworld,showloc,showworldmap,showminimap"), "vdRestrict");

  if (g_bBlurredRestricted)  llMessageLinked(LINK_RLV,RLV_CMD,"setdebug_renderresolutiondivisor:16=force","vdRestrict");
  else llMessageLinked(LINK_RLV,RLV_CMD,"setdebug_renderresolutiondivisor:1=force","vdRestrict");
}

ReleaseRestrictions() {
  g_bSendRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_send", "");

  g_bReadRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_read", "");

  g_bHearRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_hear", "");

  g_bTalkRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_talk", "");

  g_bStrayRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_touch", "");

  g_bTouchRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_stray", "");

  g_bRummageRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_stand", "");

  g_bStandRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_rummage", "");

  g_bDressRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_dress", "");

  g_bBlurredRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_blurred", "");

  g_bDazedRestricted = FALSE;
  llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_dazed", "");

  DoRestrictions();
}

UserCommand(integer iNum, string sStr, key kID, integer bRemenu) {
  string sLowerStr = llToLower(sStr);
  //Debug(sStr);
  // Outfits command handling
  if (sLowerStr == "outfits" || sLowerStr == "menu outfits") {
    if (g_bRLVaOn) {
      OutfitsMenu(kID, iNum);
    } else {
      llMessageLinked(LINK_DIALOG,NOTIFY, "0" + "\n\nSorry! This feature can't work on RLV and will require a RLVa enabled viewer. The regular \"# Folders\" feature is a good alternative.\n", kID);
      llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
    }
    return;
  } else if (llSubStringIndex(sStr, "wear ") == 0) {
    if (!g_bRLVaOn) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "\n\nSorry! This feature can't work on RLV and will require a RLVa enabled viewer. The regular \"# Folders\" feature is a good alternative.\n", kID);
      if (bRemenu) {
        llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
      }
      return;
    } else if (g_bDressRestricted) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Oops! Outfits can't be worn while the ability to dress is restricted.", kID);
    } else {
      sLowerStr = llDeleteSubString(sStr, 0, llStringLength("wear ") - 1);
      if (sLowerStr) { // We have a folder to try find...
        llSetTimerEvent(g_iTimeOut);
        g_iListener = llListen(g_iFolderRLVSearch, "", g_kWearer, "");
        g_kMenuClicker = kID;
        if (g_bRLVaOn) {
          llOwnerSay("@findfolders:" + sLowerStr + "=" + (string)g_iFolderRLVSearch);
        } else {
          llOwnerSay("@findfolder:" + sLowerStr + "=" + (string)g_iFolderRLVSearch);
        }
      }
    }

    if (bRemenu) {
      OutfitsMenu(kID, iNum);
    }
    return;
  }
  // Restrictions command handling
  if (iNum == CMD_WEARER) {
    if (sStr == RESTRICTIONS_CHAT_COMMAND || sLowerStr == "sit" || sLowerStr == TERMINAL_CHAT_COMMAND) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "%NOACCESS%", kID);
    } else if (sLowerStr == "menu force sit" || sStr == "menu " + RESTRICTION_BUTTON || sStr == "menu " + TERMINAL_BUTTON) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "%NOACCESS%", kID);
      llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
    }
    return;
  } else if (sStr == RESTRICTIONS_CHAT_COMMAND || sStr == "menu " + RESTRICTION_BUTTON) {
    RestrictionsMenu(kID, iNum);
    return;
  } else if (sStr == TERMINAL_CHAT_COMMAND || sStr == "menu " + TERMINAL_BUTTON) {
    if (sStr == TERMINAL_CHAT_COMMAND) {
      g_iMenuCommand = FALSE;
    } else {
      g_iMenuCommand = TRUE;
    }
    Dialog(kID, g_sTerminalText, [], [], 0, iNum, "terminal");
    return;
  } else if (sLowerStr == "restrictions back") {
    llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
    return;
  } else if (sLowerStr == "restrictions reset" || sLowerStr == "allow all") {
    if (iNum == CMD_OWNER) {
      ReleaseRestrictions();
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ send ims" || sLowerStr == "allow sendim") {
    if (iNum <= g_bSendRestricted || !g_bSendRestricted) {
      g_bSendRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_send", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Send IMs is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ send ims" || sLowerStr == "forbid sendim") {
    if (iNum <= g_bSendRestricted || !g_bSendRestricted) {
      g_bSendRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_send=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Send IMs is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ read ims" || sLowerStr == "allow readim") {
    if (iNum <= g_bReadRestricted || !g_bReadRestricted) {
      g_bReadRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_read", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Read IMs is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ read ims" || sLowerStr == "forbid readim") {
    if (iNum <= g_bReadRestricted || !g_bReadRestricted) {
      g_bReadRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_read=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Read IMs is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ hear" || sLowerStr == "allow hear") {
    if (iNum <= g_bHearRestricted || !g_bHearRestricted) {
      g_bHearRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_hear", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Hear is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ hear" || sLowerStr == "forbid hear") {
    if (iNum <= g_bHearRestricted || !g_bHearRestricted) {
      g_bHearRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_hear=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Hear is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ touch" || sLowerStr == "allow touch") {
    if (iNum <= g_bTouchRestricted || !g_iTouchRestricted) {
      g_bTouchRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_touch", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Touch is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ touch" || sLowerStr == "forbid touch") {
    if (iNum <= g_bTouchRestricted || !g_iTouchRestricted) {
      g_bTouchRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_touch=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Touch restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ stray" || sLowerStr == "allow stray") {
    if (iNum <= g_bStrayRestricted || !g_bStrayRestricted) {
      g_bStrayRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_stray", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Stray is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ stray" || sLowerStr == "forbid stray") {
    if (iNum <= g_bStrayRestricted || !g_bStrayRestricted) {
      g_bStrayRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_stray=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Stray is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
    // 2015-04-10 added Otto
  } else if (sLowerStr == "restrictions ☐ stand" || sLowerStr == "allow stand") {
    if (iNum <= g_bStandRestricted || !g_bStandRestricted) {
      g_bStandRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_stand", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Stand up is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ stand" || sLowerStr == "forbid stand") {
    if (iNum <= g_bStandRestricted || !g_bStandRestricted) {
      g_bStandRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_stand=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Stand up is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ talk" || sLowerStr == "allow talk") {
    if (iNum <= g_bTalkRestricted || !g_bTalkRestricted) {
      g_bTalkRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_talk", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Talk is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ talk" || sLowerStr == "forbid talk") {
    if (iNum <= g_bTalkRestricted || !g_bTalkRestricted) {
      g_bTalkRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_talk=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Talk is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ rummage" || sLowerStr == "allow rummage") {
    if (iNum <= g_bRummageRestricted || !g_bRummageRestricted) {
      g_bRummageRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_rummage", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Rummage is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ rummage" || sLowerStr == "forbid rummage") {
    if (iNum <= g_bRummageRestricted || !g_bRummageRestricted) {
      g_bRummageRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_rummage=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Rummage is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☐ dress" || sLowerStr == "allow dress") {
    if (iNum <= g_bDressRestricted || !g_bDressRestricted) {
      g_bDressRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_dress", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Dress is un-restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions ☑ dress" || sLowerStr == "forbid dress") {
    if (iNum <= g_bDressRestricted || !g_bDressRestricted) {
      g_bDressRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_dress=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Ability to Dress is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions un-dazzle" || sLowerStr == "undazzle") {
    if (iNum <= g_bBlurredRestricted || !g_bBlurredRestricted) {
      g_bBlurredRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_blurred", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Vision is clear", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions dazzle" || sLowerStr == "dazzle") {
    if (iNum <= g_bBlurredRestricted || !g_bBlurredRestricted) {
      g_bBlurredRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_blurred=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Vision is restricted", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions un-daze" || sLowerStr == "undaze") {
    if (iNum <= g_bDazedRestricted || !g_bDazedRestricted) {
      g_bDazedRestricted = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "restrictions_dazed", "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Clarity is restored", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "restrictions daze" || sLowerStr == "daze") {
    if (iNum <= g_bDazedRestricted || !g_bDazedRestricted) {
      g_bDazedRestricted = iNum;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "restrictions_dazed=" + (string)iNum, "");
      DoRestrictions();
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Confusion is imposed", kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sLowerStr == "stand" || sLowerStr == "standnow") {
    if (iNum <= g_bStandRestricted || !g_bStandRestricted) {
      llMessageLinked(LINK_RLV, RLV_CMD, "unsit=y,unsit=force", "vdRestrict");
      g_bSitting = FALSE;
      //UserCommand(iNum, "allow stand", kID, FALSE);
      //llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "\n\n%WEARERNAME% is allowed to stand once again.\n", kID);
      llSleep(0.5);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }

    if (bRemenu) {
      SitMenu(kID, iNum);
    }
    return;
  } else if (sLowerStr == "menu force sit" || sLowerStr == "sit" || sLowerStr == "sitnow") {
    SitMenu(kID, iNum);

    /*
    if (iNum <= g_bStandRestricted || !g_bStandRestricted) {
      SitMenu(kID, iNum);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);

      if (bRemenu) {
        llMessageLinked(LINK_RLV, iNum, "menu " + COLLAR_PARENT_MENU, kID);
      }
    }
    */

    return;
  } else if (sLowerStr == "sit back") {
    if (iNum <= g_bStandRestricted || !g_bStandRestricted) {
      if (CheckLastSit(g_kLastForcedSeat) == FALSE) {
        return;
      }
      llMessageLinked(LINK_RLV, RLV_CMD, "unsit=y,unsit=force", "vdRestrict");
      llSleep(0.5);
      llMessageLinked(LINK_RLV, RLV_CMD, "sit:" + (string)g_kLastForcedSeat + "=force", "vdRestrict");
      if (g_bStandRestricted) {
        llMessageLinked(LINK_RLV, RLV_CMD, "unsit=n", "vdRestrict");
      }
      g_bSitting = TRUE;
      llSleep(0.5);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }

    if (bRemenu) {
      SitMenu(kID, iNum);
    }
    return;
  } else if (llSubStringIndex(sLowerStr, "sit ") == 0) {
    if (iNum <= g_bStandRestricted || !g_bStandRestricted) {
      sLowerStr = llDeleteSubString(sStr, 0, llStringLength("sit ") - 1);
      if ((key)sLowerStr) {
        llMessageLinked(LINK_RLV, RLV_CMD, "unsit=y,unsit=force", "vdRestrict");
        llSleep(0.5);
        g_kLastForcedSeat = (key)sLowerStr;
        g_sLastForcedSeat = llKey2Name(g_kLastForcedSeat);
        llMessageLinked(LINK_RLV, RLV_CMD, "sit:" + sLowerStr + "=force", "vdRestrict");
        if (g_bStandRestricted) {
          llMessageLinked(LINK_RLV, RLV_CMD, "unsit=n", "vdRestrict");
        }
        g_bSitting = TRUE;
        llSleep(0.5);
      } else {
        Dialog(kID, "", [""], [sLowerStr, "1"], 0, iNum, "find");
        return;
      }
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }

    if (bRemenu) {
      SitMenu(kID, iNum);
    }
    return;
  } else if (sLowerStr == "clear") {
    ReleaseRestrictions();
    return;
  } else if (!llSubStringIndex(sLowerStr, "hudtpto:") && (iNum == CMD_OWNER || iNum == CMD_TRUSTED)) {
    if (g_bRLVOn) {
      llMessageLinked(LINK_RLV, RLV_CMD, llGetSubString(sLowerStr, 3, -1), "");
    }
  } else if (sLowerStr == "menu detach" || sLowerStr == "detach") {
    DetachMenu(kID, iNum);
  }

  if (bRemenu) {
    RestrictionsMenu(kID,iNum);
  }
}

default {
  state_entry() {
    g_kWearer = llGetOwner();
    //Debug("Starting");
  }

  on_rez(integer iParam) {
    if (llGetOwner() != g_kWearer) {
      llResetScript();
    }

    g_bRLVOn = FALSE;
    g_bRLVaOn = FALSE;
  }

  link_message(integer iSender, integer iNum, string sStr, key kID) {
    if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
      llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + RESTRICTION_BUTTON, "");
      llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|Force Sit", "");
      llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + TERMINAL_BUTTON, "");
      llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + OUTFITS_BUTTON, "");
      llMessageLinked(iSender, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|Detach", "");
    } else if (iNum == LM_SETTING_EMPTY) {
      if (sStr == "restrictions_send") g_bSendRestricted = FALSE;
      else if (sStr == "restrictions_read") g_bReadRestricted = FALSE;
      else if (sStr == "restrictions_hear") g_bHearRestricted = FALSE;
      else if (sStr == "restrictions_talk") g_bTalkRestricted = FALSE;
      else if (sStr == "restrictions_touch") g_bTouchRestricted = FALSE;
      else if (sStr == "restrictions_stray") g_bStrayRestricted = FALSE;
      else if (sStr == "restrictions_stand") g_bStandRestricted = FALSE;
      else if (sStr == "restrictions_rummage") g_bRummageRestricted = FALSE;
      else if (sStr == "restrictions_blurred") g_bBlurredRestricted = FALSE;
      else if (sStr == "restrictions_dazed") g_bDazedRestricted = FALSE;
    } else if (iNum == LM_SETTING_RESPONSE) {
      list lParams = llParseString2List(sStr, ["="], []);
      string sToken = llList2String(lParams, 0);
      string sValue = llList2String(lParams, 1);

      if (~llSubStringIndex(sToken,"restrictions_")) {
        if (sToken == "restrictions_send") g_bSendRestricted = (integer)sValue;
        else if (sToken == "restrictions_read") g_bReadRestricted = (integer)sValue;
        else if (sToken == "restrictions_hear") g_bHearRestricted = (integer)sValue;
        else if (sToken == "restrictions_talk") g_bTalkRestricted = (integer)sValue;
        else if (sToken == "restrictions_touch") g_bTouchRestricted = (integer)sValue;
        else if (sToken == "restrictions_stray") g_bStrayRestricted = (integer)sValue;
        else if (sToken == "restrictions_stand") g_bStandRestricted = (integer)sValue;
        else if (sToken == "restrictions_rummage") g_bRummageRestricted = (integer)sValue;
        else if (sToken == "restrictions_blurred") g_bBlurredRestricted = (integer)sValue;
        else if (sToken == "restrictions_dazed") g_bDazedRestricted = (integer)sValue;
      }
    } else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
      UserCommand(iNum, sStr, kID, FALSE);
    } else if (iNum == RLV_ON) {
      g_bRLVOn = TRUE;
      DoRestrictions();
      if (g_bSitting && g_bStandRestricted) {
        if (CheckLastSit(g_kLastForcedSeat) == TRUE) {
          llMessageLinked(LINK_RLV, RLV_CMD, "sit:" + (string)g_kLastForcedSeat + "=force", "vdRestrict");
          if (g_bStandRestricted) {
            llMessageLinked(LINK_RLV, RLV_CMD, "unsit=n", "vdRestrict");
          }
        } else {
          llMessageLinked(LINK_RLV, RLV_CMD, "unsit=y", "vdRestrict");
        }
      }
    } else if (iNum == RLV_OFF) {
      g_bRLVOn = FALSE;
      ReleaseRestrictions();
    } else if (iNum == RLV_CLEAR) {
      ReleaseRestrictions();
    } else if (iNum == RLVA_VERSION) {
      g_bRLVaOn = TRUE;
    } else if (iNum == CMD_SAFEWORD || iNum == CMD_RELAY_SAFEWORD) {
      ReleaseRestrictions();
    } else if (iNum == DIALOG_RESPONSE) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      if (~iMenuIndex) {
        list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
        key kAv = (key)llList2String(lMenuParams, 0);
        string sMessage = llList2String(lMenuParams, 1);
        //integer iPage = (integer)llList2String(lMenuParams, 2);
        integer iAuth = (integer)llList2String(lMenuParams, 3);
        //Debug("Sending restrictions " + sMessage);
        string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);

        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

        if (sMenu == "restrictions") {
          UserCommand(iAuth, "restrictions " + sMessage, kAv, TRUE);
        } else if (sMenu == "sensor") {
          if (sMessage == "BACK") {
            llMessageLinked(LINK_RLV, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
            return;
          }
          else if (sMessage == "[Sit back]") UserCommand(iAuth, "sit back", kAv, FALSE);
          else if (sMessage == "[Get up]") UserCommand(iAuth, "stand", kAv, FALSE);
          else if (sMessage == "☑ Strict") UserCommand(iAuth, "allow stand", kAv, FALSE);
          else if (sMessage == "☐ Strict") UserCommand(iAuth, "forbid stand", kAv, FALSE);
          else {
            UserCommand(iAuth, "sit " + sMessage, kAv, FALSE);
          }

          UserCommand(iAuth, "menu force sit", kAv, TRUE);
        } else if (sMenu == "find") {
          UserCommand(iAuth, "sit " + sMessage, kAv, FALSE);
        } else if (sMenu == "terminal") {
          if (llStringLength(sMessage) > 4) {
            DoTerminalCommand(sMessage, kAv);
          }

          if (g_iMenuCommand) {
            llMessageLinked(LINK_RLV, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
          }
        } else if (sMenu == "folder" || sMenu == "multimatch") {
          g_kMenuClicker = kAv;
          if (sMessage == UPMENU) {
            llMessageLinked(LINK_RLV, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
          } else if (sMessage == BACKMENU) {
            list lTempSplit = llParseString2List(g_sCurrentPath, ["/"], []);
            lTempSplit = llList2List(lTempSplit, 0, llGetListLength(lTempSplit) - 2);
            g_sCurrentPath = llDumpList2String(lTempSplit, "/") + "/";
            llSetTimerEvent(g_iTimeOut);
            g_iAuth = iAuth;
            g_iListener = llListen(g_iFolderRLV, "", g_kWearer, "");
            llOwnerSay("@getinv:" + g_sCurrentPath + "=" + (string)g_iFolderRLV);
          } else if (sMessage == "WEAR") {
            WearFolder(g_sCurrentPath);
          } else if (sMessage != "") {
            g_sCurrentPath += sMessage + "/";
            if (sMenu == "multimatch") g_sCurrentPath = sMessage + "/";
            llSetTimerEvent(g_iTimeOut);
            g_iAuth = iAuth;
            g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
            llOwnerSay("@getinv:" + g_sCurrentPath + "=" + (string)g_iFolderRLV);
          }
        } else if (sMenu == "detach") {
          if (sMessage == UPMENU) {
            llMessageLinked(LINK_RLV, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
          } else {
            integer iIndex = llListFindList(g_lAttachments, [sMessage]);
            if (~iIndex) {
              string sAttachmentId = llList2String(g_lAttachments, iIndex + 1);
              // Send the RLV command to remove it.
              if (g_bRLVOn) {
                llOwnerSay("@remattach:" + sAttachmentId + "=force");
              }
              // Sleep for a sec to let things detach
              llSleep(0.5);
            }
            // Return menu
            DetachMenu(kAv, iAuth);
          }
        }
      }
    } else if (iNum == DIALOG_TIMEOUT) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
    } else if (iNum == LINK_UPDATE) {
      if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
      else if (sStr == "LINK_RLV") LINK_RLV = iSender;
      else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
    } else if (iNum == REBOOT && sStr == "reboot") {
      llResetScript();
    }
  }

  listen(integer iChan, string sName, key kID, string sMsg) {
    //llListenRemove(g_iListener);
    llSetTimerEvent(0.0);
    //Debug((string)iChan + "|" + sName + "|" + (string)kID + "|"+sMsg);
    if (iChan == g_iFolderRLV) { // We got some folders to process
      FolderMenu(g_kMenuClicker, g_iAuth, sMsg); // We use g_kMenuClicker to respond to the person who asked for the menu
      g_iAuth = CMD_EVERYONE;
    } else if (iChan == g_iFolderRLVSearch) {
      if (sMsg == "") {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "That outfit couldn't be found in #RLV/" + g_sPathPrefix, kID);
      } else { // We got a match
        if (llSubStringIndex(sMsg, ",") < 0) {
          g_sCurrentPath = sMsg;
          WearFolder(g_sCurrentPath);
          //llOwnerSay("@attachallover:" + g_sPathPrefix + "/.core/=force");
          llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Loading outfit #RLV/" + sMsg, kID);
        } else {
          string sPrompt = "\nPick one!";
          list lFolderMatches = llParseString2List(sMsg, [","], []);
          Dialog(g_kMenuClicker, sPrompt, lFolderMatches, [UPMENU], 0, g_iAuth, "multimatch");
          g_iAuth = CMD_EVERYONE;
        }
      }
    }
  }

  timer() {
    llListenRemove(g_iListener);
    llSetTimerEvent(0.0);
  }
}
