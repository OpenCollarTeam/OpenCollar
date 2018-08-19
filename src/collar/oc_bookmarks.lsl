// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Satomi Ahn, Nandana Singh, Wendy Starfall,
// Sumi Perl, Master Starship, littlemousy, mewtwo064, ml132,
// Romka Swallowtail, Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.


string g_sAppVersion = "1.3";

string g_sSubMenu = "Bookmarks"; // Name of the submenu
string g_sParentMenu = "Apps"; // Name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string PLUGIN_CHAT_CMD = "tp"; // Every menu should have a chat command, so the user can easily access it by type for instance *plugin
string PLUGIN_CHAT_CMD_ALT = "bookmarks"; // Taking control over some map/tp commands from rlvtp
string g_sCard = ".bookmarks"; // Name of the notecards to store destinations.

key g_kWebLookup;
string g_sWeb = "https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/";

list g_lDestinations = []; //Destination list direct from static notecard
list g_lDestinationSLUrls = []; //Destination list direct from static notecard
list g_lVolatileDestinations = []; //These are in memory preferences that are not yet saved into the notecard
list g_lVolatileSLUrls = []; //These are in memory preferences that are not yet saved into the notecard
key g_kRequestHandle = NULL_KEY; //Sim Request Handle to convert global coordinates
vector g_vLocalPos = ZERO_VECTOR;
//key g_kRemoveMenu = NULL_KEY; // Use a separate key for the remove menu ID
integer g_iRLVOn = FALSE; // Assume RLV is off until we hear otherwise
string g_sTempLoc = "";   // This holds a global temp location for manual entry from provided location but no favorite name - g_kTBoxIdLocationOnly

list g_lMenuIDs; // 3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

key g_kWearer;

string g_sSettingToken = "bookmarks_";
//string g_sGlobalToken = "global_";
key g_kDataID;
integer g_iLine = 0;
string UPMENU = "BACK";
key g_kCommander;

list PLUGIN_BUTTONS = ["SAVE", "PRINT", "REMOVE"];

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;
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
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_OFF = 6100;
integer RLV_ON = 6101;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

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

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
  key kMenuID = llGenerateKey();
  llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

  integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
  if (~iIndex) {
    g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
  } else {
    g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
  }
}

DoMenu(key keyID, integer iAuth) {
  string sPrompt = "\n[Bookmarks]\t" + g_sAppVersion;
  list lMyButtons = PLUGIN_BUTTONS + g_lDestinations + g_lVolatileDestinations;
  Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "bookmarks");
}

PermsCheck() {
  string sName = llGetScriptName();
  if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
    llOwnerSay("You have been given a no-modify OpenCollar object. This could break future updates.  Please ask the provider to make the object modifiable.");
  }

  if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
    llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify. This could break future updates. Please leave your OpenCollar objects modifiable.");
  }

  integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
  if (!((llGetInventoryPermMask(sName, MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
    llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
  }

  if (!((llGetInventoryPermMask(sName, MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
    llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
  }
}

UserCommand(integer iNum, string sStr, key kID) {
  // So commands can accept a value
  if (iNum == CMD_GROUP) { // Do not permit Group Access (Public Access)
    llMessageLinked(LINK_DIALOG,NOTIFY, "0" + "%NOACCESS%", kID);
    return;
  }

  if (sStr == "reset") {
    // It is a request for a reset
    if (iNum == CMD_WEARER || iNum == CMD_OWNER) {
      // Only owner and wearer may reset
      llResetScript();
    }
  } else if (sStr == "rm bookmarks") {
    if (kID != g_kWearer && iNum != CMD_OWNER) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
    } else {
      Dialog(kID, "\nDo you really want to uninstall the " + g_sSubMenu + " App?", ["Yes", "No", "Cancel"], [], 0, iNum, "rmbookmarks");
    }
  } else if (sStr == PLUGIN_CHAT_CMD || llToLower(sStr) == "menu " + PLUGIN_CHAT_CMD_ALT || llToLower(sStr) == PLUGIN_CHAT_CMD_ALT) {
    // An authorized user requested the plugin menu by typing the menus chat command
    DoMenu(kID, iNum);
  } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " save") - 1) == PLUGIN_CHAT_CMD + " save") {
    // Grab partial string match to capture destination name
    if (llStringLength(sStr) > llStringLength(PLUGIN_CHAT_CMD + " save")) {
      string sAdd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_CMD + " save") + 1, -1), STRING_TRIM);
      if (llListFindList(g_lVolatileDestinations, [sAdd]) >= 0 || llListFindList(g_lDestinations, [sAdd]) >= 0) {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "This destination name is already taken", kID);
      } else {
        string sSLUrl = FormatRegionName();
        AddDestination(sAdd, sSLUrl, kID);
      }
    } else {
      // Notify that they need to give a description of the saved destination ie. <prefix>bookmarks save description
      Dialog(kID, "Enter a name for the destination below. Submit a blank field to cancel and return.
        You can enter:
        1) A friendly name to save your current location to your favorites
        2) A new location or SLurl", [], [], 0, iNum, "TextBoxIdSave");
    }
  } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " remove") - 1) == PLUGIN_CHAT_CMD + " remove") { // Grab partial string match to capture destination name
    if (llStringLength(sStr) > llStringLength(PLUGIN_CHAT_CMD + " remove")) {
      string sDel = llStringTrim(llGetSubString(sStr,  llStringLength(PLUGIN_CHAT_CMD + " remove"), -1), STRING_TRIM);
      if (llListFindList(g_lVolatileDestinations, [sDel]) < 0) {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Can't find bookmark " + (string)sDel + " to be deleted.", kID);
      } else {
        integer iIndex;
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + sDel, "");
        iIndex = llListFindList(g_lVolatileDestinations, [sDel]);
        g_lVolatileDestinations = llDeleteSubList(g_lVolatileDestinations, iIndex, iIndex);
        g_lVolatileSLUrls = llDeleteSubList(g_lVolatileSLUrls, iIndex, iIndex);
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Removed destination " + sDel, kID);
      }
    } else {
      Dialog(kID, "Select a bookmark to be removed...", g_lVolatileDestinations, [UPMENU], 0, iNum, "RemoveMenu");
    }
  } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " print") - 1) == PLUGIN_CHAT_CMD + " print") { // Grab partial string match to capture destination name
    PrintDestinations(kID);
  } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD) - 1) == PLUGIN_CHAT_CMD) {
    string sCmd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_CMD) + 1, -1), STRING_TRIM);
    g_kCommander = kID;
    if (llListFindList(g_lVolatileDestinations, [sCmd]) >= 0) {
      integer iIndex = llListFindList(g_lVolatileDestinations, [sCmd]);
      TeleportTo(llList2String(g_lVolatileSLUrls, iIndex));
    } else if (llListFindList(g_lDestinations, [sCmd]) >= 0) { // Found exact match, TP over
      integer iIndex = llListFindList(g_lDestinations, [sCmd]);
      TeleportTo(llList2String(g_lDestinationSLUrls, iIndex));
    } else if (llStringLength(sCmd) > 0) { // We didn't get a case sensitive match, so lets loop through what we know and try find what we need
      integer i;
      string sDestination;
      integer iFound = 0;
      list lMatchedBookmarks;

      integer iEnd = llGetListLength(g_lDestinations);
      for (; i < iEnd; i++) { //First check OC locations
        sDestination = llList2String(g_lDestinations, i);
        if (llSubStringIndex(llToLower(sDestination), llToLower(sCmd)) >= 0) {
          //store it, if we only find one, we'll go there
          iFound += 1;
          lMatchedBookmarks += sDestination;
        }
      }

      iEnd = llGetListLength(g_lVolatileDestinations);
      for (i = 0; i < iEnd; i++) { // Then check volatile destinations
        sDestination = llList2String(g_lVolatileDestinations, i);
        if (llSubStringIndex(llToLower(sDestination), llToLower(sCmd)) >= 0) {
          // Store it, if we only find one, we'll go there
          iFound += 1;
          matchedBookmarks += sDestination;
        }
      }

      if (iFound == 0) {
        // Old HUD command compatibility: 'o:176382.800000/261210.900000/3503.276000=force'
        /*
        if (llSubStringIndex(sCmd, "o:") == 0) {
          llMessageLinked(LINK_SET, RLV_CMD, "tpt" + sCmd, kID); // (enable this to support HUD forcetp. disabled now since rlvtp still does this
        } else {
        */
        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "The bookmark '" + sCmd + "' has not been found in the %DEVICETYPE% of %WEARERNAME%.", kID);
        //}
      } else if (iFound > 1) {
        Dialog(kID, "More than one matching bookmark was found in the %DEVICETYPE% of %WEARERNAME%.\nChoose a bookmark to teleport to.", matchedBookmarks, [UPMENU], 0, iNum, "choose bookmark");
      } else { // Exactly one matching LM found, so use it
        UserCommand(iNum, PLUGIN_CHAT_CMD + " " + llList2String(matchedBookmarks, 0), g_kCommander); // Push matched result to command
      }
    } else { //Can't find in list, lets try find substring matches
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "I didn't understand your command.", kID);
    }
  }
}

AddDestination(string sMessage, string sLoc, key kID) {
  if (llGetListLength(g_lVolatileDestinations) + llGetListLength(g_lDestinations) >= 45) {
    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "The maximum number 45 bookmars is already reached.", kID);
    return;
  }

  llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + sMessage + "=" + sLoc, "");
  g_lVolatileDestinations += sMessage;
  g_lVolatileSLUrls += sLoc;
  llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Added destination " + sMessage + " with a location of: " + sLoc, kID);
}

string FormatRegionName() {
  // Formatting to regionname(x,x,x)
  string sRegion = llGetRegionName();
  vector vPos = llGetPos();
  string sPosX = (string)llRound(pos.x);
  string sPosY = (string)llRound(pos.y);
  string sPosZ = (string)llRound(pos.z);
  return (sRegion + "(" + sPosX + "," + sPosY + "," + sPosZ + ")");
}

string ConvertSLUrl(string sStr) { // convert the slurl http strings to region (xxx,xxx,xxx)
  sStr = llStringTrim(llUnescapeURL(sStr), STRING_TRIM);
  string sIndex = "http:";
  list lPieces = llParseStringKeepNulls(sStr, ["/"], []);
  integer iHTTPloc = 0;
  string sStringToKeep;
  integer iHTTPInString = llSubStringIndex(llList2String(lPieces, 0), sIndex);
  if (iHTTPInString > 0) {
    sStringToKeep = llGetSubString(llList2String(lPieces, 0), 0, iHTTPInString - 1);
  }

  if (llGetListLength(lPieces) == 8) {
    string sRegion = llList2String(lPieces, iHTTPloc + 4);
    string sLocationX = llList2String(lPieces, iHTTPloc + 5);
    string sLocationY = llList2String(lPieces, iHTTPloc + 6);
    string sLocationZ = llList2String(lPieces, iHTTPloc + 7);
    sStr = sStringToKeep + sRegion + "(" + sLocationX + "," + sLocationY + "," + sLocationZ + ")";
    //Debug("Converted slurl, sending for processing..." + sStr);
    return sStr; // Successful conversion, send converted string assembly
  }

  //Debug("No slurl detected, sending for processing anyways :" + sStr);
  return sStr; // Failed conversion, send raw string assuming there's no SLUrls
}

integer IsInteger(string sInput) { // For validating location scheme
  return ((string)((integer)sInput) == sInput);
}

integer ValidatePlace(string sStr, key kAv, integer iAuth) {
  //Debug("ValidatePlaces working on: " + sStr);
  list lPieces;
  integer MAX_CHAR_TYPE = 2; // We use +1 due since we're counting with a list split.  We can only accept 1 of each of the following: ()~
  string sAssembledLoc;
  string sRegionName;
  string sFriendlyName;

  sStr = llStringTrim(sStr, STRING_TRIM);
  lPieces = llParseStringKeepNulls(sStr, ["~"], []); // Split location from friendly name

  if (llGetListLength(lPieces) == MAX_CHAR_TYPE) { // We have a tilde, so make sure the friendly name is good
    if (llStringLength(llList2String(lPieces, 0)) < 1) { // Make sure friendly name isn't empty
      return 2;
    }

    sFriendlyName = llStringTrim(llList2String(lPieces, 0), STRING_TRIM); // Assign friendly name
    lPieces = llParseStringKeepNulls(llList2String(lPieces, 1), ["("], []); // Split location from friendly name
  } else if (llGetListLength(lPieces) > MAX_CHAR_TYPE) { // Too many tildes, retreat
    return 1;
  } else { // We don't have a friendly name, so let's ignore that for now and split at 0
    lPieces = llParseStringKeepNulls(llList2String(lPieces, 0), ["("], []);
  }

  if (llGetListLength(lPieces) == MAX_CHAR_TYPE) { // Check to see we don't have extra ('s - this might also mean there's no location coming...
    if (llStringLength(llList2String(lPieces, 0)) < 1) { // Make sure region name isn't empty
      return 4;
    }

    sRegionName = llStringTrim(llList2String(lPieces, 0), STRING_TRIM); // Trim off whitespace from region name
  } else if (llGetListLength(lPieces) > MAX_CHAR_TYPE) { // This location looks wrong, retreat
    return 3;
  } else  { // There's no location here, kick out new menu
    UserCommand(iAuth, PLUGIN_CHAT_CMD + " save " + sStr, kAv);
    UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
    return 0;
  }

  // We're left with sFriendlyname, sRegionName, ["blah", "123,123)"] - so lets validate the last list item
  sAssembledLoc = llStringTrim("(" + llList2String(lPieces, 1), STRING_TRIM); // Reattach the bracket we lost, clean up whitespace
  lPieces = llParseStringKeepNulls(sAssembledLoc, [","], []); // Split location from friendly name

  if (llGetListLength(lPieces) != 3) { // Check to see we don't have extra ,'s
    return 5;
  }

  if (llGetSubString(sAssembledLoc, 0, 0) != "(") { // Location doesn't start with (
    return 6;
  }

  if (llGetSubString(sAssembledLoc, -1, -1) != ")") { // Location doesn't end with )
    return 7;
  }

  lPieces = llParseStringKeepNulls(llGetSubString(sAssembledLoc, 1, llStringLength(sAssembledLoc) - 2), [","], []); // lPieces should be a list of 3 sets of numbers
  integer i;
  for (; i <= llGetListLength(lPieces)-1; ++i) { // Run through this number list to make sure each character is numeric
    integer iY = 0;
    integer iZ = llStringLength(llList2String(lPieces, i)) - 1;
    for (iY = 0; iY <= iZ; ++iY) {
      if (!IsInteger(llGetSubString(llList2String(lPieces, i), iY, iY))) { // Something left in here isn't an integer
        return 8;
      }
    }
  }

  if (sFriendlyName == "") {
    g_sTempLoc = sRegionName + sAssembledLoc; // Assign a global for use in response menu
    Dialog(kAv, "\nEnter a name for the destination " + sRegionName + sAssembledLoc + " below.\n- Submit a blank field to cancel and return.", [], [], 0, iAuth, "TextBoxIdLocation");
  } else {
    AddDestination(sFriendlyName, sRegionName, kAv);
    UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
  }

  return 0;
}

ReadDestinations() { // On inventory change, re-read our ~destinations notecard and pull from web
  g_lDestinations = [];
  g_lDestinationSLUrls = [];
  g_kWebLookup = llHTTPRequest(g_sWeb + "bookmarks.txt", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
  // Start re-reading the notecards
  g_iLine = 0;
  if (llGetInventoryKey(g_sCard)) {
    g_kDataID = llGetNotecardLine(g_sCard, 0);
  }
}

TeleportTo(string sStr) { // Take a string in region (x,y,z) format, and retrieve global coordinates. The teleport takes place in the data server section
  string sRegion = llStringTrim(llGetSubString(sStr, 0, llSubStringIndex(sStr, "(") - 1), STRING_TRIM);
  string sCoords = llStringTrim(llGetSubString(sStr, llSubStringIndex(sStr, "(") + 1 , llStringLength(sStr) - 2), STRING_TRIM);
  list lTokens = llParseString2List(sCoords, [","], []);
  // Extract local X, Y and Z
  g_vLocalPos.x = llList2Float(lTokens, 0);
  g_vLocalPos.y = llList2Float(lTokens, 1);
  g_vLocalPos.z = llList2Float(lTokens, 2);
  // Request info about the sim
  if (!g_iRLVOn) { // If we don't have RLV, we can just send to llMapDestination for a popup
    llMapDestination(sRegion, g_vLocalPos, ZERO_VECTOR);
  } else { // We've got RLV, let's use it
    g_kRequestHandle = llRequestSimulatorData(sRegion, DATA_SIM_POS);
  }
}

PrintDestinations(key kID) { // On inventory change, re-read our ~destinations notecard
  integer i;
  integer iLength = llGetListLength(g_lDestinations);
  string sMsg;
  sMsg += "\n\nThe below can be copied and pasted into the " + g_sCard + " notecard. The format should follow:\n\ndestination name~region name(123,123,123)\n\n";
  for (; i < iLength; i++) {
    sMsg += llList2String(g_lDestinations, i) + "~" + llList2String(g_lDestinationSLUrls, i) + "\n";
    if (llStringLength(sMsg) > 1000) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + sMsg, kID);
      sMsg = "";
    }
  }

  iLength = llGetListLength(g_lVolatileDestinations);
  for (i = 0; i < iLength; i++) {
    sMsg += llList2String(g_lVolatileDestinations, i) + "~" + llList2String(g_lVolatileSLUrls, i) + "\n";
    if (llStringLength(sMsg) > 1000) {
      llMessageLinked(LINK_DIALOG, NOTIFY, "0" + sMsg, kID);
      sMsg = "";
    }
  }

  llMessageLinked(LINK_DIALOG, NOTIFY, "0" + sMsg, kID);
}

default {
  on_rez(integer iStart) {
    ReadDestinations();
  }

  state_entry() {
    g_kWearer = llGetOwner(); // Store key of wearer
    PermsCheck();
    ReadDestinations(); // Grab our presets
    //Debug("Starting");
  }

  http_response(key kId, integer iStatus, list lMeta, string sBody) {
    if (iStatus == 200) {  // Be silent on failures.
      //Debug(body);
      if (kId == g_kWebLookup) {
        list lResponse;
        lResponse = llParseString2List(sBody, ["\n"], [""]);
        string sData;
        list split;
        integer i;
        integer iX = llGetListLength(lResponse) - 1;
        for (; i <= iX; ++i) {
          sData = llStringTrim(llList2String(lResponse, i), STRING_TRIM);
          lSplit = llParseString2List(sData, ["~"], []);
          g_lDestinations = [llStringTrim(llList2String(lSplit, 0), STRING_TRIM)] + g_lDestinations;
          g_lDestinationSLUrls = [llStringTrim(llList2String(lSplit, 1), STRING_TRIM)] + g_lDestinationSLUrls;
        }
        //Debug("Body: " + body);
      }
    }
  }

  dataserver(key kID, string sData) {
    if (kID == g_kRequestHandle) {
      // Parse the dataserver response (it is a vector cast to a string)
      list lTokens = llParseString2List(sData, ["<", ",", ">"], []);
      vector vGlobalPos;
      // The coordinates given by the dataserver are the ones of the
      // South-West corner of this sim
      // => offset with the specified local coordinates
      gGlobalPos.x = llList2Float(lTtokens, 0);
      gGlobalPos.y = llList2Float(lTokens, 1);
      gGlobalPos.z = llList2Float(lTokens, 2);
      gGlobalPos += g_vLocalPos;
      // Build the command
      string sPosStr = (string)((integer)gGlobalPos.x) + "/" + (string)((integer)gGlobalPos.y) + "/" + (string)((integer)gGlobalPos.z);
      //Debug("Global position : " + (string)sPosStr);
      // Pass command to main
      if (g_iRLVOn) {
        string sRLVCmd = "tpto:" + sPosStr + "=force";
        llMessageLinked(LINK_RLV, RLV_CMD, sRLVCmd, g_kCommander);
      }
    } else if (kID == g_kDataID) {
      if (sData != EOF) {
        if (llGetSubString(sData, 0, 2) != "") {
          sData = llStringTrim(sData, STRING_TRIM);
          list lSplit = llParseString2List(sData, ["~"], []);
          if (!~llListFindList(g_lDestinations, [llStringTrim(llList2String(lSplit, 0), STRING_TRIM)])) {
            g_lDestinations += llStringTrim(llList2String(lSplit, 0), STRING_TRIM);
            g_lDestinationSLUrls += llStringTrim(llList2String(lSplit, 1), STRING_TRIM);

            if (llGetListLength(g_lDestinations) == 30) {
              return;
            }
          }
        }

        g_iLine++;
        g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
      }
    }
  }

  link_message(integer iSender, integer iNum, string sStr, key kID) {
    //Debug((string)iSender + "|" + (string)iNum + "|" + sStr + "|" + (string)kID);
    if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
      llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
    } else if (iNum == RLV_OFF) {
      g_iRLVOn = FALSE;
    } else if (iNum == RLV_ON) {
      g_iRLVOn = TRUE;
    } else if (iNum == LM_SETTING_RESPONSE) {
      list lParams = llParseString2List(sStr, ["="], []);
      string sToken = llList2String(lParams, 0);
      string sValue = llList2String(lParams, 1);
      integer i = llSubStringIndex(sToken, "_");
      if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
        list lDestination = [llGetSubString(sToken, llSubStringIndex(sToken, "_") + 1, llSubStringIndex(sToken, "="))];
        if (llListFindList(g_lVolatileDestinations, lDestination) < 0) {
          g_lVolatileDestinations += lDestination;
          g_lVolatileSLUrls += sValue;
        }
      }
    } else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
      UserCommand(iNum, sStr, kID);
    } else if (iNum == DIALOG_RESPONSE) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      if (iMenuIndex != -1) {
        list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
        key kAv = (key)llList2String(lMenuParams, 0); // Avatar using the menu
        string sMessage = llList2String(lMenuParams, 1); // Button label
        // integer iPage = (integer)llList2String(lMenuParams, 2); // Menu page
        integer iAuth = (integer)llList2String(lMenuParams, 3); // Auth level of avatar
        string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);

        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

        if (sMenuType == "TextBoxIdLocation") {
          if (sMessage != " ") {
            AddDestination(sMessage, g_sTempLoc, kID);
          }

          UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
        } else if (sMenuType == "TextBoxIdSave") {
          //Debug("TBoxIDSave " + sMessage);
          if (sMessage != " ") {
            ValidatePlace(ConvertSLUrl(sMessage), kAv, iAuth);
          } else {
            UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
          }
        } else if (sMenuType == "RemoveMenu") {
          //Debug("|" + sMessage + "|");
          if (sMessage == UPMENU) {
            UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
            return;
          }

          if (sMessage != "") {
            // Got a menu response meant for us. pull out values
            UserCommand(iAuth, PLUGIN_CHAT_CMD + " remove " + sMessage, kAv);
            UserCommand(iAuth, PLUGIN_CHAT_CMD + " remove", kAv);
          } else {
            UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
          }
        } else if (sMessage == UPMENU) {
          llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
        } else if (sMenuType == "rmbookmarks") {
          if (sMessage == "Yes") {
            llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
            llMessageLinked(LINK_DIALOG, NOTIFY, "1" + g_sSubMenu + " App has been removed.", kAv);

            if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
              llRemoveInventory(llGetScriptName());
            }
          } else {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + g_sSubMenu + " App remains installed.", kAv);
          }
        } else if (~llListFindList(PLUGIN_BUTTONS, [sMessage])) {
          if (sMessage == "SAVE") {
            UserCommand(iAuth, PLUGIN_CHAT_CMD + " save", kAv);
          } else if (sMessage == "REMOVE") {
            UserCommand(iAuth, PLUGIN_CHAT_CMD + " remove", kAv);
          } else if (sMessage == "PRINT") {
            UserCommand(iAuth, PLUGIN_CHAT_CMD + " print", kAv);
            UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
          }
        } else if (~llListFindList(g_lDestinations + g_lVolatileDestinations, [sMessage])) {
          UserCommand(iAuth, PLUGIN_CHAT_CMD + " " + sMessage, kAv);
        }
      }
    } else if (iNum == LINK_UPDATE) {
      if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
      else if (sStr == "LINK_RLV") LINK_RLV = iSender;
      else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
    } else if (iNum == DIALOG_TIMEOUT) {
      integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
      g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex + 3); // Remove stride from g_lMenuIDs
    } else if (iNum == REBOOT && sStr == "reboot") {
      llResetScript();
    }
  }

  changed(integer iChange) {
    if (iChange & CHANGED_INVENTORY) {
      PermsCheck();
      ReadDestinations();
    }

    if (iChange & CHANGED_OWNER) {
      llResetScript();
    }
  }
}
