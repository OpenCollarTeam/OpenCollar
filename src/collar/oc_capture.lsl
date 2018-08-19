// This file is part of OpenCollar.
// Copyright (c) 2014 - 2016 littlemousy, Sumi Perl, Wendy Starfall,
// Garvin Twine
// Licensed under the GPLv2.  See LICENSE for full details.


// Based on OpenCollar - takeme 3.980

key g_kWearer;

list g_lMenuIDs; // Menu information, 4 strided list, userKey, menuKey, menuName, captorKey

// MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY =  1002;
integer SAY =  1004;
integer REBOOT = -1000;

integer LINK_AUTH =  2;
integer LINK_DIALOG =  3;
integer LINK_RLV =  4;
integer LINK_SAVE =  5;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE =  2000;
// integer LM_SETTING_REQUEST =  2001;
integer LM_SETTING_RESPONSE =  2002;
integer LM_SETTING_DELETE =  2003;
// integer LM_SETTING_EMPTY =  2004;

integer MENUNAME_REQUEST =  3000;
integer MENUNAME_RESPONSE =  3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string g_sTempOwnerID;
integer g_bRiskyOn = FALSE; // true means captor confirms, false means wearer confirms
integer g_bCaptureOn = FALSE; // on/off toggle for the app.  Switching off clears tempowner list
integer g_bCaptureInfo = TRUE;
string g_sSettingToken = "capture_";
//string  g_sGlobalToken = "global_";

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

string NameURI(string sID) {
  return "secondlife:///app/agent/" + sID + "/about";
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenu, key kCaptor) {
  key kMenuID = llGenerateKey();
  llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

  integer iIndex = llListFindList(g_lMenuIDs, [kID]);
  if (~iIndex) {
    g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sMenu, kCaptor], iIndex, iIndex + 3);
  } else {
    g_lMenuIDs += [kID, kMenuID, sMenu, kCaptor];
  }
  //Debug("Menu:" + sName);
}

CaptureMenu(key kId, integer iAuth) {
  string sPrompt = "\n[Capture]\n";
  list lButtons;

  if (g_sTempOwnerID) {
    lButtons += "Release";
  } else {
    if (g_bCaptureOn) lButtons += "OFF";
    else lButtons += "ON";

    if (g_bRiskyOn) lButtons += "☑ Risky";
    else lButtons += "☐ Risky";
  }

  if (g_sTempOwnerID) {
    sPrompt += "\n\nCaptured by: " + NameURI(g_sTempOwnerID);
  }

  Dialog(kId, sPrompt, lMyButtons, ["BACK"], 0, iAuth, "CaptureMenu", "");
}

SaveTempOwners() {
  if (g_sTempOwnerID) {
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "auth_tempowner=" + g_sTempOwnerID, "");
    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "auth_tempowner=" + g_sTempOwnerID, "");
  } else {
    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "auth_tempowner=", "");
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "auth_tempowner", "");
  }
}

DoCapture(string sCaptorID, integer bIsConfirmed) {
  if (g_sTempOwnerID) {
    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%WEARERNAME% is already captured, try another time.", sCaptorID);
    return;
  }

  if (llVecDist(llList2Vector(llGetObjectDetails(sCaptorID, [OBJECT_POS]), 0), llGetPos()) > 10) {
    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "You could capture %WEARERNAME% if you get a bit closer.", sCaptorID);
    return;
  }

  if (!bIsConfirmed) {
    Dialog(g_kWearer, "\n" + NameURI(sCaptorID) + " wants to capture you...", ["Allow", "Reject"], ["BACK"], 0, CMD_WEARER, "AllowCaptureMenu", sCaptorID);
  } else {
    //llMessageLinked(LINK_SET, CMD_OWNER, "follow " + sCaptorID, sCaptorID);
    llMessageLinked(LINK_SET, CMD_OWNER, "beckon", sCaptorID);
    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "You are at " + NameURI(sCaptorID) + "'s whim.", g_kWearer);
    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "\n\n%WEARERNAME% is at your mercy.\n\nNOTE: During capture RP %WEARERNAME% cannot refuse your teleport offers and you will keep full control. Type \"/%CHANNEL% %PREFIX% grab\" to attach a leash or \"/%CHANNEL% %PREFIX% capture release\" to relinquish capture access to %WEARERNAME%'s %DEVICETYPE%.\n\nHave fun! For basic instructions click [here].\n", sCaptorID);
    g_sTempOwnerID = sCaptorID;
    SaveTempOwners();
    llSetTimerEvent(0.0);
  }
}

UserCommand(integer iNum, string sStr, key kID, integer bRemenu) {
  string sStrLower = llToLower(sStr);

  if (llSubStringIndex(sStr, "capture TempOwner") == 0) {
    string sCaptorID = llGetSubString(sStr, llSubStringIndex(sStr, "~") + 1, -1);
    if (iNum == CMD_OWNER || iNum == CMD_TRUSTED || iNum == CMD_GROUP) { // Do nothing, owners get their own menu but cannot capture
    } else {
      Dialog(kID, "\nYou can try to capture %WEARERNAME%.\n\nReady for that?", ["Yes","No"], [], 0, iNum, "ConfirmCaptureMenu", sCaptorID);
    }
  } else if (sStrLower == "capture" || sStrLower == "menu capture") {
    if  (iNum != CMD_OWNER && iNum != CMD_WEARER) {
      if (g_bCaptureOn) {
        Dialog(kID, "\nYou can try to capture %WEARERNAME%.\n\nReady for that?", ["Yes", "No"], [], 0, iNum, "ConfirmCaptureMenu", kID);
      } else {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID); // Notify(kID, g_sAuthError, FALSE);
      }
    } else {
      CaptureMenu(kID, iNum); // An authorized user requested the plugin menu by typing the menus chat command
    }
  }
  else if (iNum != CMD_OWNER && iNum != CMD_WEARER) {
    // Silent fail, no need to do anything more in this case
  } else if (llSubStringIndex(sStrLower, "capture") == 0) {
    if (g_sTempOwnerID != "" && kID == g_kWearer) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", g_kWearer);
      return;
    } else if (sStrLower == "capture on") {
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Capture Mode activated", kID);
      if (g_bRiskyOn && g_bCaptureInfo) {
        llMessageLinked(LINK_DIALOG, SAY, "1" + "%WEARERNAME%: You can capture me if you touch my %DEVICETYPE%...", "");
        llSetTimerEvent(900.0);
      }

      g_bCaptureOn = TRUE;
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "capture=1", "");
    } else if (sStrLower == "capture off") {
      if(g_bCaptureOn) {
        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Capture Mode deactivated", kID);
      }

      g_bCaptureOn = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "capture", "");

      g_sTempOwnerID = "";
      SaveTempOwners();
      llSetTimerEvent(0.0);
    } else if (sStrLower == "capture release") {
      llMessageLinked(LINK_SET, CMD_OWNER, "unleash", kID);
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + NameURI(kID) + " has released you.", g_kWearer);
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "You have released %WEARERNAME%.", kID);

      g_sTempOwnerID = "";
      SaveTempOwners();
      llSetTimerEvent(0.0);
      return; // No remenu in case of release
    } else if (sStrLower == "capture risky on") {
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "risky=1", "");
      g_bRiskyOn = TRUE;
      //llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "You are vulnerable now...", g_kWearer);
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Capturing won't require %WEARERNAME%'s consent. \"/%CHANNEL% %PREFIX% capture info off\" will deactivate \"capture me\" announcements.", kID);

      if (g_bCaptureOn && g_bCaptureInfo) {
        llSetTimerEvent(900.0);
        llMessageLinked(LINK_DIALOG, SAY, "1" + "%WEARERNAME%: You can capture me if you touch my %DEVICETYPE%...", "");
      }
    } else if (sStrLower == "capture risky off") {
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "risky", "");
      g_bRiskyOn = FALSE;

      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Capturing will require %WEARERNAME%'s consent first.", kID);
      llSetTimerEvent(0.0);
    } else if (sStrLower == "capture info on") {
      g_bCaptureInfo = TRUE;
      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "\"Capture me\" announcements during risky mode are now enabled.", kID);
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "info", "");

      if (g_bRiskyOn && g_bCaptureOn) {
        llSetTimerEvent(900.0);
        llMessageLinked(LINK_DIALOG, SAY, "1" + "%WEARERNAME%: You can capture me if you touch my %DEVICETYPE%...", "");
      }
    } else if (sStrLower == "capture info off") {
      g_bCaptureInfo = FALSE;
      if (g_bRiskyOn && g_bCaptureOn) {
        llSetTimerEvent(0);
      }

      llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "\"Capture me\" announcements during risky mode are now disabled.", kID);
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "info=0", "");
    }

    if (bRemenu) {
      CaptureMenu(kID, iNum);
    }
  }
}

default{
  state_entry() {
    //llSetMemoryLimit(32768); // 2016-01-24 (6034 bytes free)
    g_kWearer = llGetOwner();
    //Debug("Starting");
  }

  on_rez(integer iParam) {
    if (llGetOwner() != g_kWearer) {
      llResetScript();
    }
  }

  touch_start(integer iNumDetected) {
    key kToucher = llDetectedKey(0);

    if (kToucher == g_kWearer) return; // Wearer can't capture
    if (g_sTempOwnerID == kToucher) return; // Temp owners can't capture
    if (g_sTempOwnerID) return; // No one can capture if already captured
    if (!g_bCaptureOn) return; // No one can capture if disabled

    if (llVecDist(llDetectedPos(0), llGetPos()) > 10) {
      llMessageLinked(LINK_SET, NOTIFY, "0" + "You could capture %WEARERNAME% if you get a bit closer.", kToucher);
    } else {
      llMessageLinked(LINK_AUTH, CMD_ZERO, "capture TempOwner~" + (string)kToucher, kToucher);
    }
  }

  link_message(integer iSender, integer iNum, string sStr, key kID) {
    if (iNum == MENUNAME_REQUEST && sStr == "Main") {
      llMessageLinked(iSender, MENUNAME_RESPONSE, "Main|Capture", "");
    } else if (iNum == CMD_SAFEWORD || (sStr == "runaway" && iNum == CMD_OWNER)) {
      if (iNum == CMD_SAFEWORD && g_bCaptureOn) {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Capture Mode deactivated.", g_kWearer);
      }

      if (llGetAgentSize(g_sTempOwnerID)) {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Your capture role play with %WEARERNAME% is over.", g_sTempOwnerID);
      }

      g_bCaptureOn = FALSE;
      g_bRiskyOn = FALSE;
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "capture", "");
      llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "risky", "");

      g_sTempOwnerID = "";
      SaveTempOwners();
      llSetTimerEvent(0.0);
    } else if (iNum == LM_SETTING_RESPONSE) {
      list lParams = llParseString2List(sStr, ["="], []);
      string sToken = llList2String(lParams, 0);
      string sValue = llList2String(lParams, 1);

      if (sToken == g_sSettingToken + "capture") g_bCaptureOn = (integer)sValue; // Check if any values for use are received
      else if (sToken == g_sSettingToken + "risky") g_bRiskyOn = (integer)sValue;
      else if (sToken == "auth_tempowner") g_sTempOwnerID = sValue; // Store tempowner
      else if (sToken == g_sSettingToken + "info") g_bCaptureInfo = (integer)sValue;
    } else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) {
      UserCommand(iNum, sStr, kID, FALSE);
    } else if (iNum == DIALOG_RESPONSE) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      if (~iMenuIndex) {
        list lMenuParams = llParseString2List(sStr, ["|"], []);
        key kAv = (key)llList2String(lMenuParams, 0);
        string sMessage = llList2String(lMenuParams, 1);
        // integer iPage = llList2Integer(lMenuParams, 2);
        integer iAuth = (integer)llList2String(lMenuParams, 3);
        string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
        key kCaptor = llList2Key(g_lMenuIDs, iMenuIndex + 2);

        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex + 2); // Remove stride from g_lMenuIDs

        if (sMenu == "CaptureMenu") {
          if (sMessage == "BACK") llMessageLinked(LINK_ROOT, iAuth, "menu Main", kAv);
          else if (sMessage == "☑ Risky") UserCommand(iAuth, "capture risky off", kAv, TRUE);
          else if (sMessage == "☐ Risky") UserCommand(iAuth, "capture risky on", kAv, TRUE);
          else {
            UserCommand(iAuth, "capture " + sMessage, kAv, TRUE);
          }
        } else if (sMenu == "AllowCaptureMenu") { // Wearer must confirm when forced is off
          if (sMessage == "BACK") {
            UserCommand(iNum, "menu capture", kID, FALSE); //llMessageLinked(LINK_THIS, iAuth, "menu capture", kAv);
          } else if (sMessage == "Allow") {
            DoCapture(kCaptor, TRUE);
          } else if (sMessage == "Reject") {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + NameURI(kCaptor) + " didn't pass your face control. Sucks for them!", kAv);
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Looks like %WEARERNAME% didn't want to be captured after all. C'est la vie!", kCaptor);
          }
        } else if (sMenu == "ConfirmCaptureMenu") { // Captor must confirm when forced is on
          if (sMessage == "BACK") {
            UserCommand(iNum, "menu capture", kID, FALSE); //llMessageLinked(LINK_SET, iAuth, "menu capture", kAv);
          } else if (g_bCaptureOn) { // In case app was switched off in the mean time
            if (sMessage == "Yes") {
              DoCapture(kCaptor, g_bRiskyOn);
            } else if (sMessage == "No") {
              llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "You let %WEARERNAME% be.", kAv);
            }
          } else {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%WEARERNAME% can no longer be captured", kAv);
          }
        }
      }
    } else if (iNum == DIALOG_TIMEOUT) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex + 2); // Remove stride from g_lMenuIDs
    } else if (iNum == LINK_UPDATE) {
      if (sStr == "LINK_AUTH") LINK_AUTH = iSender;
      else if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
      else if (sStr == "LINK_RLV") LINK_RLV = iSender;
      else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
    } else if (iNum == REBOOT && sStr == "reboot") {
      llResetScript();
    }
  }

  timer() {
    if (g_bCaptureInfo) {
      llMessageLinked(LINK_DIALOG, SAY, "1" + "%WEARERNAME%: You can capture me if you touch my %DEVICETYPE%...", "");
    }
  }

  changed(integer iChange) {
    if (iChange & CHANGED_OWNER) llResetScript();

    if (iChange & CHANGED_TELEPORT) {
      if (g_sTempOwnerID == "") {
        if (g_bRiskyOn && g_bCaptureOn && g_bCaptureInfo) {
          llMessageLinked(LINK_DIALOG, SAY, "1" + "%WEARERNAME%: You can capture me if you touch my %DEVICETYPE%...", "");
          llSetTimerEvent(900.0);
        }
      }
    }

    /*
    if (iChange & CHANGED_REGION) {
      if (g_bProfiled) {
        llScriptProfiler(TRUE);
        Debug("profiling restarted");
      }
    }
    */
  }
}
