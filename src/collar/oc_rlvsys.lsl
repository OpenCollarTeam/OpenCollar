// This file is part of OpenCollar.
// Copyright (c) 2008 - 2016 Satomi Ahn, Nandana Singh, Wendy Starfall,
// Medea Destiny, littlemousy, Romka Swallowtail, Garvin Twine,
// Sumi Perl et al.
// Licensed under the GPLv2.  See LICENSE for full details.


integer g_bRLVOn = TRUE;
integer g_bRLVOff = FALSE;
integer g_bViewerCheck = FALSE;
integer g_bRLVActive = FALSE;
integer g_iWaitRelay;

integer g_iListener;
float g_fVersionTimeOut = 30.0;
integer g_iRLVVersion;
integer g_iRLVaVersion;
integer g_iCheckCount;
integer g_iMaxViewerChecks = 3;
integer g_bCollarLocked = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "RLV";
list g_lMenu;
//key kMenuID;
list g_lMenuIDs;
integer g_iMenuStride = 3;
integer RELAY_CHANNEL = -1812221819;

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;

integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

integer REBOOT = -1000;
integer LOADPIN = -1904;

integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002; // RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; // RLV Plugins can recieve the used RLV viewer version upon receiving this message..
integer RLVA_VERSION = 6004; // RLV Plugins can recieve the used RLVa viewer version upon receiving this message..

integer RLV_OFF = 6100;
integer RLV_ON = 6101;
integer RLV_QUERY = 6102;
integer RLV_RESPONSE = 6103;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TURNON = "  ON";
string TURNOFF = " OFF";
string CLEAR = "CLEAR ALL";

key g_kWearer;

string g_sSettingToken = "rlvsys_";
string g_sGlobalToken = "global_";
string g_sRLVVersionString = "(unknown)";
string g_sRLVaVersionString = "(unknown)";

list g_lOwners;
list g_lRestrictions; // 2 strided list of sourceId, § separated list of restrictions strings
//list g_lExceptions;
list g_lBaked = []; // List of restrictions currently in force
key g_kSitter = NULL_KEY;
key g_kSitTarget = NULL_KEY;

integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

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

DoMenu(key kID, integer iAuth) {
  key kMenuID = llGenerateKey();
  string sPrompt = "\n[Remote Scripted Viewer Controls]\n";

  if (g_bRLVActive) {
    if (g_iRLVVersion) {
      sPrompt += "\nRestrainedLove API: RLV v" + g_sRLVVersionString;
    }
    if (g_iRLVaVersion) {
      sPrompt += " / RLVa v" + g_sRLVaVersionString;
    }
  } else if (g_bRLVOff) {
    sPrompt += "\nRLV is turned off.";
  } else {
    if (g_bRLVOn) {
      sPrompt += "\nThe rlv script is still trying to handshake with the RL-viewer. Just wait another minute and try again.\n\n[ON] restarts the RLV handshake cycle with the viewer.";
    } else {
      sPrompt += "\nRLV appears to be disabled in the viewer's preferences.\n\n[ON] attempts another RLV handshake with the viewer.";
    }
    sPrompt += "\n\n[OFF] will prevent the %DEVICETYPE% from attempting another \"@versionnew=293847\" handshake at the next login.\n\nNOTE: Turning RLV off here means that it has to be turned on manually once it is activated in the viewer.";
  }

  list lButtons;
  if (g_bRLVActive) {
    lButtons = llListSort(g_lMenu, 1, TRUE);
    lButtons = [TURNOFF, CLEAR] + lButtons;
  } else if (g_bRLVOff) {
    lButtons = [TURNON];
  } else {
    lButtons = [TURNON, TURNOFF];
  }

  llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|0|" + llDumpList2String(lButtons, "`") + "|" + UPMENU + "|" + (string)iAuth, kMenuID);

  integer iIndex = llListFindList(g_lMenuIDs, [kID]);
  if (~iIndex) {
    g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, g_sSubMenu], iIndex, iIndex + g_iMenuStride - 1);
  } else {
    g_lMenuIDs += [kID, kMenuID, g_sSubMenu];
  }
  //Debug("Made menu.");
}

RebakeSourceRestrictions(key kSource) {
  //Debug("RebakeSourceRestrictions " + (string)kSource);
  integer iSourceIndex = llListFindList(g_lRestrictions, [kSource]);
  if (~iSourceIndex) {
    list lRestr = llParseString2List(llList2String(g_lRestrictions, iSourceIndex + 1), ["§"], []);
    while(llGetListLength(lRestr)) {
      ApplyAdd(llList2String(lRestr, -1));
      lRestr = llDeleteSubList(lRestr, -1, -1);
    }
  }
}

DoLock() {
  integer iNumSources = llGetListLength(llList2ListStrided(g_lRestrictions, 0, -2, 2));
  while (iNumSources--){
    if ((key)llList2Key(llList2ListStrided(g_lRestrictions, 0, -2, 2), iNumSources)) {
      ApplyAdd("detach");
      return;
    }
  }
  ApplyRem("detach"); // We only get here if none of the active sources is a real source, so remove our lock
}

SetRLVState(){
  if (g_bRLVOn && g_bViewerCheck) { // Everyone says RLV on
    if (!g_bRLVActive) { // Its newly active
      //Debug("RLV went active");
      //Debug("Sources:" + llDumpList2String(g_lSources, ";"));
      g_bRLVActive = TRUE;
      //llMessageLinked(LINK_SET, RLV_ON, "", NULL_KEY);
      g_lMenu = []; // Flush submenu buttons
      llMessageLinked(LINK_ALL_OTHERS, MENUNAME_REQUEST, g_sSubMenu, "");
      // Tell rlv plugins to reinstate restrictions  (and wake up the relay listener... so that it can at least hear !pong's!
      llMessageLinked(LINK_ALL_OTHERS, RLV_REFRESH, "", NULL_KEY);
      g_iWaitRelay = 1;
      llSetTimerEvent(1.5);
    }
  } else if (g_bRLVActive) { // Both were true, but not now. g_bViewerCheck must still be TRUE (as it was once true), so g_bRLVOn must have just been set FALSE
    //Debug("RLV went inactive");
    g_bRLVActive = FALSE;
    while (llGetListLength(g_lBaked)) {
      llOwnerSay("@"+llList2String(g_lBaked, -1) + "=y"); // Remove restriction
      g_lBaked = llDeleteSubList(g_lBaked, -1, -1);
    }
    llMessageLinked(LINK_ALL_OTHERS, RLV_OFF, "", NULL_KEY);
  } else if (g_bRLVOn) { // g_bViewerCheck must be FALSE (see above 2 cases), so g_bRLVOn must have just been set to TRUE, so do viewer check
    if (g_iListener) {
      llListenRemove(g_iListener);
    }
    g_iListener = llListen(293847, "", g_kWearer, "");
    llSetTimerEvent(g_fVersionTimeOut);
    g_iCheckCount=0;
    llOwnerSay("@versionnew=293847");
  } else { // Else both are FALSE, its the only combination left, No need to do viewercheck if g_bRLVOn is FALSE
    llSetTimerEvent(0.0);
  }
}

AddRestriction(key kID, string sBehav) {
  // Add new sources to sources list
  integer iSource = llListFindList(g_lRestrictions, [kID]);
  if (!~iSource) { // If this is a restriction from a new source
    g_lRestrictions += [kID, ""];
    iSource = -2;
    if ((key)kID) {
      llMessageLinked(LINK_ALL_OTHERS, CMD_ADDSRC, "", kID); // Tell relay script we have a new restriction source
    }
  }

  string sSrcRestr = llList2String(g_lRestrictions, iSource + 1);
  //Debug("AddRestriction 2.1");
  //if (!(sSrcRestr == sBehav || ~llSubStringIndex(sSrcRestr, "§" + sBehav) || ~llSubStringIndex(sSrcRestr, sBehav + "§"))) {
  if (!~llSubStringIndex("§" + sSrcRestr + "§", "§" + sBehav + "§")) {
    //Debug("AddRestriction 2.2");
    sSrcRestr += "§" + sBehav;
    if (llSubStringIndex(sSrcRestr, "§")==0) {
      sSrcRestr = llGetSubString(sSrcRestr, 1, -1);
    }

    g_lRestrictions = llListReplaceList(g_lRestrictions, [sSrcRestr], iSource + 1, iSource + 1);
    //Debug("apply restriction (" + (string)kID + ")" + sBehav);
    ApplyAdd(sBehav);
    if (sBehav == "unsit") {
      g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
      g_kSitter = kID;
    }
  }

  DoLock(); // If there are sources with valid keys, collar should be locked.
}

ApplyAdd (string sBehav) {
  if (!~llListFindList(g_lBaked, [sBehav])) { // If this restriction is not already baked
    g_lBaked += [sBehav];
    llOwnerSay("@" + sBehav + "=n");
    //Debug("'" + sBehav + "' added to the baked list");
  //} else {
  //  Debug(sBehav + " is already baked");
  }
}

RemRestriction(key kID, string sBehav) {
  //Debug("RemRestriction(" + (string)kID + ")" + sBehav);
  integer iSource = llListFindList(g_lRestrictions, [kID]); // Find index of the source
  if (~iSource) { // If this source set any restrictions
    list lSrcRestr = llParseString2List(llList2String(g_lRestrictions, iSource + 1), ["§"], []); // Get a list of this source's restrictions
    integer iRestr = llListFindList(lSrcRestr, [sBehav]); // Get index of this restriction from that list
    if (~iRestr || sBehav == "ALL") { // If the restriction is in the list
      if (llGetListLength(lSrcRestr) == 1) { // If it is the only restriction in the list
        g_lRestrictions = llDeleteSubList(g_lRestrictions, iSource, iSource + 1); // Remove the restrictions list
        if ((key)kID) {
          llMessageLinked(LINK_ALL_OTHERS, CMD_REMSRC, "", kID); // Tell the relay the source has no restrictions
        }
      } else { // Else, the source has other restrictions
        lSrcRestr = llDeleteSubList(lSrcRestr, iRestr, iRestr); // Delete the restriction from the list
        g_lRestrictions = llListReplaceList(g_lRestrictions, [llDumpList2String(lSrcRestr, "§")], iSource + 1,iSource + 1); // Store the list in the sources restrictions list
      }

      if (sBehav == "unsit" && g_kSitter == kID) {
        g_kSitter = NULL_KEY;
        g_kSitTarget = NULL_KEY;
      }

      lSrcRestr = [];
      ApplyRem(sBehav);
    }
  }

  DoLock();
}

ApplyRem(string sBehav) {
  integer iRestr = llListFindList(g_lBaked, [sBehav]); // Look for this restriction in the baked list
  if (~iRestr) { // If this restriction has been baked already
    integer i;
    for (; i <= llGetListLength(g_lRestrictions); i++) { // For each source
      list lSrcRestr = llParseString2List(llList2String(g_lRestrictions, i), ["§"], []); // Get its restrictions list
      if (llListFindList(lSrcRestr, [sBehav]) != -1) {
        return; // Check it for this restriction
      }
    }
    // Also check the exceptions list, in case its an exception
    g_lBaked = llDeleteSubList(g_lBaked, iRestr, iRestr); // Delete it from the baked list
    llOwnerSay("@" + sBehav + "=y"); // Remove restriction
  }
}

SafeWord(key kID) {
  // Leave lock and exceptions intact, clear everything else
  integer iNumRestrictions = llGetListLength(g_lRestrictions);
  while (iNumRestrictions) {
    iNumRestrictions -= 2;
    string kSource = llList2String(g_lRestrictions, iNumRestrictions);
    if (kSource != "main" && kSource != "rlvex" && llSubStringIndex(kSource, "utility_") != 0) {
      llMessageLinked(LINK_THIS, RLV_CMD, "clear", kSource);
    }
  }

  llMessageLinked(LINK_THIS, RLV_CMD, "unsit=force", "");
  llMessageLinked(LINK_ALL_OTHERS, RLV_CLEAR, "", "");

  if (kID) {
    llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "RLV restrictions cleared.", kID);
  }
}
// End of book keeping functions

UserCommand(integer iNum, string sStr, key kID) {
  sStr = llToLower(sStr);
  if (sStr == "runaway" && kID == g_kWearer) { // Some scripts reset on runaway, we want to resend RLV state.
    llSleep(2); // Give some time for scripts to get ready.
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=" + (string)g_bRLVOn, "");
  } else if (sStr == "rlv" || sStr == "menu rlv") {
    // Someone clicked "RLV" on the main menu. Give them our menu now
    DoMenu(kID, iNum);
  } else if (sStr == "rlv on") {
    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Starting RLV...", g_kWearer);
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=1", "");
    g_bRLVOn = TRUE;
    g_bRLVOff = FALSE;
    SetRLVState();
  } else if (sStr == "rlv off") {
    if (iNum == CMD_OWNER) {
      llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=0", "");
      llSetTimerEvent(0.0); // In case handshakes still going on stop the timer
      g_bRLVOn = FALSE;
      g_bRLVOff = TRUE;
      SetRLVState();
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "RLV disabled.", g_kWearer);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    }
  } else if (sStr == "clear") {
    if (iNum == CMD_OWNER) {
      SafeWord(kID);
    } else {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", g_kWearer);
    }
  } else if (llGetSubString(sStr, 0, 13) == "rlv handshakes") {
    if (iNum != CMD_WEARER && iNum != CMD_OWNER) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", g_kWearer);
    } else {
      if ((integer)llGetSubString(sStr, -2, -1)) {
        g_iMaxViewerChecks = (integer)llGetSubString(sStr, -2, -1);
        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Next time RLV is turned on or the %DEVICETYPE% attached with RLV turned on, there will be "+(string)g_iMaxViewerChecks+" extra handshake attempts before disabling RLV.", kID);
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "handshakes=" + (string)g_iMaxViewerChecks, "");
      } else {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "\n\nRLV handshakes means the set number of attempts to check for active RLV support in the viewer. Being on slow connections and/or having an unusually large inventory might mean having to check more often than the default of 3 times.\n\nCommand syntax: %PREFIX% rlv handshakes [number]\n", kID);
      }
    }
  } else if (sStr == "show restrictions") {
    string sOut = "\n\n%WEARERNAME% is restricted by the following sources:\n";
    integer iNumRestrictions = llGetListLength(g_lRestrictions);
    if (!iNumRestrictions) {
      sOut = "There are no restrictions right now.";
    }

    while (iNumRestrictions){
      key kSource = (key)llList2String(g_lRestrictions, iNumRestrictions - 2);
      if ((key)kSource) {
        sOut += "\n" + llKey2Name((key)kSource) + " (" + (string)kSource + "): " + llList2String(g_lRestrictions, iNumRestrictions - 1) + "\n";
      } else {
        sOut += "\nThis %DEVICETYPE% (" + (string)kSource + "): " + llList2String(g_lRestrictions, iNumRestrictions - 1) + "\n";
      }
      iNumRestrictions -= 2;
    }

    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + sOut, kID);
  }
}

default {
  on_rez(integer iParam) {
    /*
    if (g_bProfiled) {
      llScriptProfiler(TRUE);
      Debug("profiling restarted");
    }
    */

    g_bRLVActive = FALSE;
    g_bViewerCheck = FALSE;
    g_bRLVOn = FALSE;
    g_lBaked = []; // Just been rezzed, so should have no baked restrictions

    llMessageLinked(LINK_ALL_OTHERS, LINK_UPDATE, "LINK_RLV", "");
  }

  state_entry() {
    if (llGetStartParameter() == 825) {
      llSetRemoteScriptAccessPin(0);
    }

    //llSetMemoryLimit(65536); // 2015-05-16 (script needs memory for processing)
    SetRLVState();
    //llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=" + (string)g_bRLVOn, "");
    //llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_SAVE, g_sSettingToken + "on=" + (string)g_bRLVOn, "");
    llOwnerSay("@clear");
    g_kWearer = llGetOwner();
    //Debug("Starting");
  }

  listen(integer iChan, string sName, key kID, string sMsg) {
    // RestrainedLove viewer v2.8.0 (RLVa 1.4.10) <-- @versionnew response structure v1.23 (implemented April 2010).
    // lines commented out are from @versionnum response string (implemented late 2009)
    llListenRemove(g_iListener);
    llSetTimerEvent(0.0);
    g_iCheckCount = 0;
    g_bViewerCheck = TRUE;

    // Send the version to rlv plugins
    list lParam = llParseString2List(sMsg, [" "], [""]); // (0:RestrainedLove)(1:viewer)(2:v2.8.0)(3:(RLVa)(4:1.4.10))

    list lVersionSplit = llParseString2List(llGetSubString(llList2String(lParam, 2), 1, -1), ["."], []); // Expects (208)0000 | derive from:(2:v2.8.0)
    g_iRLVVersion = llList2Integer(lVersionSplit, 0) * 100 + llList2Integer(lVersionSplit, 1); // We should now have (integer)208
    string sRLVResponseString = llList2String(lParam, 2); // (2:v2.8.0) RLV segmented response from viewer
    g_sRLVVersionString = llGetSubString(sRLVResponseString, llSubStringIndex(sRLVResponseString, "v") + 1, llSubStringIndex(sRLVResponseString, ")"));
    string sRLVaResponseString = llList2String(lParam, 4);  // (4:1.4.10)) RLVa segmented response from viewer
    g_sRLVaVersionString = llGetSubString(sRLVaResponseString, 0, llSubStringIndex(sRLVaResponseString, ")") - 1);

    lVersionSplit = llParseString2List(g_sRLVaVersionString, ["."], []); // Split up RLVa version string (1.4.10)
    g_iRLVaVersion = llList2Integer(lVersionSplit, 0) * 100 + llList2Integer(lVersionSplit, 1); // We should now have (integer)104

    // We should now have: ["2.8.0" in g_sRLVVersionString] and ["1.4.10" in g_sRLVaVersionString]
    //Debug("g_iRLVVersion: "+(string)g_iRLVVersion+" g_sRLVVersionString: "+g_sRLVVersionString+ " g_sRLVaVersionString: "+g_sRLVaVersionString+ " g_iRLVaVersion: "+(string)g_iRLVaVersion);
    //Debug("|"+sMsg+"|");
    SetRLVState();
    //Debug("Starting");
  }
  // Firestorm - viewer response: RestrainedLove viewer v2.8.0 (RLVa 1.4.10)
  // Firestorm - rlvmain parsed result: g_iRLVVersion: 208 (same as before) g_sRLVVersionString: 2.8.0 (same as before) g_sRLVaVersionString: 1.4.10 (new) g_iRLVaVersion: 104 (new)
  //
  // Marine's RLV Viewer - viewer response: RestrainedLove viewer v2.09.01.0 (3.7.9.32089)
  // Marine's RLV Viewer - rlvmain parsed result: g_iRLVVersion: 209 (same as before) g_sRLVVersionString: 2.09.01.0 (same as before) g_sRLVaVersionString: NULL (new) g_iRLVaVersion: 0 (new)

  link_message(integer iSender, integer iNum, string sStr, key kID) {
    if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
      llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
      g_lMenu = []; // Flush submenu buttons
      llMessageLinked(LINK_ALL_OTHERS, MENUNAME_REQUEST, g_sSubMenu, "");
    } else if (iNum <= CMD_WEARER && iNum >= CMD_OWNER) {
      UserCommand(iNum, sStr, kID);
    } else if (iNum == DIALOG_RESPONSE) {
      //Debug(sStr);
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      if (~iMenuIndex) {
        llSetLinkPrimitiveParamsFast(LINK_THIS, [
          PRIM_FULLBRIGHT, ALL_SIDES, TRUE,
          PRIM_BUMP_SHINY, ALL_SIDES, PRIM_SHINY_NONE, PRIM_BUMP_NONE,
          PRIM_GLOW, ALL_SIDES, 0.4
        ]);
        llSensorRepeat("N0thin9", "abc", ACTIVE, 0.1, 0.1, 0.22);

        list lMenuParams = llParseString2List(sStr, ["|"], []);
        key kAv = (key)llList2String(lMenuParams, 0);
        string sMsg = llList2String(lMenuParams, 1);
        //integer iPage = (integer)llList2String(lMenuParams, 2);
        integer iAuth = (integer)llList2String(lMenuParams, 3);
        string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);

        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

        if (sMenu == g_sSubMenu) {
          if (sMsg == TURNON) {
            UserCommand(iAuth, "rlv on", kAv);
          } else if (sMsg == TURNOFF) {
            UserCommand(iAuth, "rlv off", kAv);
            DoMenu(kAv, iAuth);
          } else if (sMsg == CLEAR) {
            UserCommand(iAuth, "clear", kAv);
            DoMenu(kAv, iAuth);
          } else if (sMsg == UPMENU) {
            llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu " + g_sParentMenu, kAv);
          } else if (~llListFindList(g_lMenu, [sMsg])) { // If this is a valid request for a foreign menu
            llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu " + sMsg, kAv);
          }
        }
      }
    }  else if (iNum == DIALOG_TIMEOUT) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
    } else if (iNum == LM_SETTING_REQUEST && sStr == "ALL") { // Inventory changed in root
      if (g_bRLVActive == TRUE) {
        llSleep(2);
        llMessageLinked(LINK_ALL_OTHERS, RLV_ON, "", NULL_KEY);
        if (g_iRLVaVersion) {
          llMessageLinked(LINK_ALL_OTHERS, RLVA_VERSION, (string) g_iRLVaVersion, NULL_KEY);
        }
      }
    } else if (iNum == LM_SETTING_RESPONSE) {
      list lParams = llParseString2List(sStr, ["="], []);
      string sToken = llList2String(lParams, 0);
      string sValue = llList2String(lParams, 1);

      if (sToken == "auth_owner") g_lOwners = llParseString2List(sValue, [","], []);
      else if (sToken == g_sGlobalToken + "lock") g_bCollarLocked = (integer)sValue;
      else if (sToken == g_sSettingToken + "handshakes") g_iMaxViewerChecks = (integer)sValue;
      else if (sToken == g_sSettingToken + "on") {
        g_bRLVOn = (integer)sValue;
        g_bRLVOff = !g_bRLVOn;
        SetRLVState();
      }
    } else if (iNum == CMD_SAFEWORD || iNum == CMD_RELAY_SAFEWORD) {
      SafeWord("");
    } else if (iNum == RLV_QUERY) {
      if (g_bRLVActive) {
        llMessageLinked(LINK_ALL_OTHERS, RLV_RESPONSE, "ON", "");
      } else {
        llMessageLinked(LINK_ALL_OTHERS, RLV_RESPONSE, "OFF", "");
      }
    } else if (iNum == MENUNAME_RESPONSE) {
      list lParams = llParseString2List(sStr, ["|"], []);
      string sThisParent = llList2String(lParams, 0);
      string sChild = llList2String(lParams, 1);

      if (sThisParent == g_sSubMenu) {
        if (!~llListFindList(g_lMenu, [sChild])) {
          g_lMenu += [sChild];
        }
      }
    } else if (iNum == MENUNAME_REMOVE) {
      list lParams = llParseString2List(sStr, ["|"], []);
      string sThisParent = llList2String(lParams, 0);
      string sChild = llList2String(lParams, 1);

      if (sThisParent == g_sSubMenu) {
        integer iIndex = llListFindList(g_lMenu, [sChild]);
        if (iIndex != -1) {
          g_lMenu = llDeleteSubList(g_lMenu, iIndex, iIndex);
        }
      }
    } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
      integer iPin = (integer)llFrand(99999.0) + 1;
      llSetRemoteScriptAccessPin(iPin);
      llMessageLinked(iSender, LOADPIN, (string)iPin + "@" + llGetScriptName(), llGetKey());
    } else if (iNum == REBOOT && sStr == "reboot") {
      llResetScript();
    } else if (iNum == LINK_UPDATE) {
      if (sStr == "LINK_DIALOG") {
        LINK_DIALOG = iSender;
      } else if (sStr == "LINK_SAVE") {
        LINK_SAVE = iSender;
        if (g_bRLVOn) {
          llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=" + (string)g_bRLVOn, "");
        }
      } else if (sStr == "LINK_REQUEST") {
        llMessageLinked(LINK_ALL_OTHERS, LINK_UPDATE, "LINK_RLV", "");
      }
    } else if (g_bRLVActive) {
      llSetLinkPrimitiveParamsFast(LINK_THIS, [
        PRIM_FULLBRIGHT, ALL_SIDES, TRUE,
        PRIM_BUMP_SHINY, ALL_SIDES, PRIM_SHINY_NONE, PRIM_BUMP_NONE,
        PRIM_GLOW, ALL_SIDES, 0.4
      ]);
      llSensorRepeat("N0thin9", "abc", ACTIVE, 0.1, 0.1, 0.22);

      if (iNum == RLV_CMD) {
        //Debug("Received RLV_CMD: " + sStr + " from " + (string)kID);
        list lCommands = llParseString2List(llToLower(sStr), [","], []);
        while (llGetListLength(lCommands)) {
          string sCommand = llToLower(llList2String(lCommands, 0));
          list lArgs = llParseString2List(sCommand, ["="], []); // Split the command on "="
          string sCom = llList2String(lArgs, 0); // Store first part of command
          if (llGetSubString(sCom, -1, -1) == ":") {
            sCom = llGetSubString(sCom, 0, -2); // Remove trailing :
          }
          string sVal = llList2String(lArgs, 1); // Store value

          if (sVal == "n" || sVal == "add") {
            AddRestriction(kID, sCom); // Add a restriction
          } else if (sVal == "y" || sVal == "rem") {
            RemRestriction(kID, sCom);  // Remove a restriction
          } else if (sCom == "clear") { // Release some or all restrictions FOR THIS OBJECT ONLY
            //Debug("Got clear command:\nkey: " + (string)kID + "\ncommand: " + sCommand);
            integer iSource = llListFindList(g_lRestrictions, [kID]);
            if (kID == "rlvex") {
              RemRestriction(kID, sVal);
            } else if (~iSource) { // If this is a known source
              //Debug("Clearing restrictions:\nrestrictions: " + sVal + "\nfor key: " + (string)kID + "\nindex: " + (string)iSource);
              list lSrcRestr = llParseString2List(llList2String(g_lRestrictions, iSource + 1), ["§"], []); // Get a list of this source's restrictions
              list lRestrictionsToRemove;

              while (llGetListLength(lSrcRestr)) { // Loop through all of this source's restrictions and store them in a new list
                string sBehav = llList2String(lSrcRestr, -1); // Get the name of the restriction from the list
                if (sVal=="" || llSubStringIndex(sBehav, sVal) != -1) { // Ff the restriction to remove matches the start of the behaviour in the list, or we need to remove all of them
                  //Debug("Clearing restriction " + sBehav + " for " + (string)kID);
                  lRestrictionsToRemove += sBehav;
                  //RemRestriction(kID, sBehav); // Remove the restriction from the list
                }
                lSrcRestr = llDeleteSubList(lSrcRestr, -1, -1);
              }

              lSrcRestr = []; // Delete the list to free memory
              //Debug("removing restrictions:" + llDumpList2String(lRestrictionsToRemove, "|") + " for " + (string)kID);
              while (llGetListLength(lRestrictionsToRemove)) {
                RemRestriction(kID, llList2String(lRestrictionsToRemove, -1)); // Remove the restriction from the list
                lRestrictionsToRemove = llDeleteSubList(lRestrictionsToRemove, -1, -1);
              }
            }
          } else { // Perform other command
            //Debug("Got other command:\nkey: " + (string)kID + "\ncommand: " + sCommand);
            if (llSubStringIndex(sCom, "tpto") == 0) {
              if (~llListFindList(g_lBaked, ["tploc"]) || ~llListFindList(g_lBaked, ["unsit"])) {
                if ((key)kID) {
                  llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Can't teleport due to RLV restrictions", kID);
                }
                return;
              }
            } else if (sStr == "unsit=force") {
              if (~llListFindList(g_lBaked, ["unsit"])) {
                if ((key)kID) {
                  llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Can't force stand due to RLV restrictions", kID);
                }
                return;
              }
            }

            llOwnerSay("@" + sCommand);
            if (g_kSitter == NULL_KEY && llGetSubString(sCommand, 0, 3) == "sit:") {
              g_kSitter = kID;
              //Debug("Sitter:" + (string)g_kSitter);
              g_kSitTarget = (key)llGetSubString(sCom, 4, -1);
              //Debug("Sittarget:" + (string)g_kSitTarget);
            }
          }

          lCommands = llDeleteSubList(lCommands, 0, 0);
          //Debug("Command list now " + llDumpList2String(lCommands, "|"));
        }
      } else if (iNum == CMD_RLV_RELAY) {
        if (llGetSubString(sStr, -43, -1) == "," + (string)g_kWearer + ",!pong") { // If it is a pong aimed at wearer
          //Debug("Received pong:" + sStr + " from " + (string)kID);
          if (kID == g_kSitter) {
            llOwnerSay("@" + "sit:" + (string)g_kSitTarget + "=force");  // If we stored a sitter, sit on it
          }
          RebakeSourceRestrictions(kID);
        }
      }
    }
  }

  no_sensor() {
    llSetLinkPrimitiveParamsFast(LINK_THIS, [
      PRIM_FULLBRIGHT, ALL_SIDES, FALSE,
      PRIM_BUMP_SHINY, ALL_SIDES, PRIM_SHINY_HIGH, PRIM_BUMP_NONE,
      PRIM_GLOW, ALL_SIDES, 0.0
    ]);
    llSensorRemove();
  }

  timer() {
    if (g_iWaitRelay) {
      if (g_iWaitRelay < 2) {
        g_iWaitRelay = 2;
        llMessageLinked(LINK_ALL_OTHERS, RLV_ON, "", NULL_KEY);
        llMessageLinked(LINK_ALL_OTHERS, RLV_VERSION, (string)g_iRLVVersion, "");
        if (g_iRLVaVersion) { // Respond on RLVa as well
          llMessageLinked(LINK_ALL_OTHERS, RLVA_VERSION, (string)g_iRLVaVersion, "");
        }
        DoLock();
        llSetTimerEvent(3.0);
      } else {
        llSetTimerEvent(0.0);
        g_iWaitRelay = FALSE;
        integer i;
        for (; i < llGetListLength(g_lRestrictions) / 2; i++) {
          key kSource = (key)llList2String(llList2ListStrided(g_lRestrictions, 0, -1, 2), i);
          if ((key)kSource) {
            llShout(RELAY_CHANNEL, "ping," + (string)kSource + ",ping,ping");
          } else {
            RebakeSourceRestrictions(kSource); // Reapply collar's restrictions here
          }
        }

        if (!llGetStartParameter()) {
          llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "RLV ready!", g_kWearer);
        }
      }
    } else {
      if (g_iCheckCount++ < g_iMaxViewerChecks) {
        llOwnerSay("@versionnew=293847");
        /*
        if (g_iCheckCount == 2) {
          llMessageLinked(LINK_SET, NOTIFY, "0" + "\n\nIf your viewer doesn't support RLV, you can stop the \"@versionnew\" message by switching RLV off in your %DEVICETYPE%'s RLV menu or by typing: %PREFIX% rlv off\n", g_kWearer);
        }
        */
      } else { // We've waited long enough, and are out of retries
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "\n\nRLV appears to be not currently activated in your viewer. There will be no further attempted handshakes \"@versionnew=293847\" until the next time you log in. To permanently turn RLV off, type \"/%CHANNEL% %PREFIX% rlv off\" but keep in mind that you will have to manually enable it if you wish to use it in the future.\n", g_kWearer);
        llSetTimerEvent(0.0);
        llListenRemove(g_iListener);
        g_iCheckCount = 0;
        g_bViewerCheck = FALSE;
        g_iRLVVersion = FALSE;
        g_iRLVaVersion = FALSE;
        //UserCommand(500, "rlv off", g_kWearer);
        g_bRLVOn = FALSE;
        // SetRLVState();
      }
    }
  }

  changed(integer iChange) {
    if (iChange & CHANGED_OWNER) llResetScript();

    // Re-make RLV restrictions after teleport or region change, because SL seems to be losing them
    if (iChange & CHANGED_TELEPORT || iChange & CHANGED_REGION) { // If we teleported, or changed regions
      // Re-make rlv restrictions after teleport or region change, because SL seems to be losing them
      integer iNumBaked = llGetListLength(g_lBaked);
      while (iNumBaked--){
        llOwnerSay("@" + llList2String(g_lBaked, iNumBaked) + "=n");
        //Debug("resending @" + llList2String(g_lBaked, iNumBaked));
      }
    }
  }
}
