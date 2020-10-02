// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Satomi Ahn, Nandana Singh, Wendy Starfall,  
// Sumi Perl, Master Starship, littlemousy, mewtwo064, ml132,       
// Romka Swallowtail, Garvin Twine et al.                 
// Licensed under the GPLv2.  See LICENSE for full details. 
string g_sScriptVersion = "8.0";
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

string g_sAppVersion = "1.3";

string  g_sSubMenu              = "Bookmarks"; // Name of the submenu
string  g_sParentMenu          = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string  PLUGIN_CHAT_CMD             = "tp"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin
string  PLUGIN_CHAT_CMD_ALT         = "bookmarks"; //taking control over some map/tp commands from rlvtp
string  g_sCard                     = ".bookmarks"; //Name of the notecards to store destinations.

key webLookup;
string g_sWeb = "https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/";

list   g_lDestinations                = []; //Destination list direct from static notecard
list   g_lDestinations_Slurls         = []; //Destination list direct from static notecard
list   g_lVolatile_Destinations       = []; //These are in memory preferences that are not yet saved into the notecard
list   g_lVolatile_Slurls             = []; //These are in memory preferences that are not yet saved into the notecard
key    g_kRequestHandle               = NULL_KEY; //Sim Request Handle to convert global coordinates
vector g_vLocalPos                    = ZERO_VECTOR;
//key    g_kRemoveMenu                  = NULL_KEY; //Use a separate key for the remove menu ID
integer g_iRLVOn                      = FALSE; //Assume RLV is off until we hear otherwise
string g_tempLoc                      = "";   //This holds a global temp location for manual entry from provided location but no favorite name - g_kTBoxIdLocationOnly

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

key     g_kWearer;

string  g_sSettingToken             = "bookmarks_";
//string g_sGlobalToken             = "global_";
key     g_kDataID;
integer g_iLine = 0;
string  UPMENU                      = "BACK";
key     g_kCommander;

list    PLUGIN_BUTTONS              = ["SAVE", "PRINT", "REMOVE"];

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

list g_lSettingsReqs = [];

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
}

DoMenu(key keyID, integer iAuth) {
    string sPrompt = "\n[Bookmarks]\t"+g_sAppVersion;
    list lMyButtons = PLUGIN_BUTTONS + g_lDestinations + g_lVolatile_Destinations;
    Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "bookmarks");
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}


UserCommand(integer iNum, string sStr, key kID) {
    // So commands can accept a value
    if (sStr == "reset") {
        // it is a request for a reset
        if(iNum == CMD_WEARER || iNum == CMD_OWNER)
            //only owner and wearer may reset
            llResetScript();
    } else if (sStr == "rm bookmarks") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to uninstall bookmarks",kID);
        else Dialog(kID,"\nDo you really want to uninstall the "+g_sSubMenu+" App?", ["Yes","No","Cancel"], [], 0, iNum,"rmbookmarks");
    } else if(sStr == PLUGIN_CHAT_CMD || llToLower(sStr) == "menu " + PLUGIN_CHAT_CMD_ALT || llToLower(sStr) == PLUGIN_CHAT_CMD_ALT) {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    } else if(llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " save") - 1) == PLUGIN_CHAT_CMD + " save") {
        //grab partial string match to capture destination name
        if(llStringLength(sStr) > llStringLength(PLUGIN_CHAT_CMD + " save")) {
            string sAdd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_CMD + " save") + 1, -1), STRING_TRIM);
            if(llListFindList(g_lVolatile_Destinations, [sAdd]) >= 0 || llListFindList(g_lDestinations, [sAdd]) >= 0)
                llMessageLinked(LINK_SET,NOTIFY,"0"+"This destination name is already taken",kID);
            else {
                string slurl = FormatRegionName();
                addDestination(sAdd, slurl, kID);
            }
        } else {
            // Notify that they need to give a description of the saved destination ie. <prefix>bookmarks save description
            Dialog(kID,
"Enter a name for the destination below. Submit a blank field to cancel and return.
You can enter:
1) A friendly name to save your current location to your favorites
2) A new location or SLurl", [], [], 0, iNum,"TextBoxIdSave");

        }
    } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " remove") - 1) == PLUGIN_CHAT_CMD + " remove") { //grab partial string match to capture destination name
        if (llStringLength(sStr) > llStringLength(PLUGIN_CHAT_CMD + " remove")) {
            string sDel = llStringTrim(llGetSubString(sStr,  llStringLength(PLUGIN_CHAT_CMD + " remove"), -1), STRING_TRIM);
            if (llListFindList(g_lVolatile_Destinations, [sDel]) < 0) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Can't find bookmark " + (string)sDel + " to be deleted.",kID);
            } else {
                integer iIndex;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + sDel, "");
                iIndex = llListFindList(g_lVolatile_Destinations, [sDel]);
                g_lVolatile_Destinations = llDeleteSubList(g_lVolatile_Destinations, iIndex, iIndex);
                g_lVolatile_Slurls = llDeleteSubList(g_lVolatile_Slurls, iIndex, iIndex);
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Removed destination " + sDel,kID);
            }
        } else
            Dialog(kID, "Select a bookmark to be removed...", g_lVolatile_Destinations, [UPMENU], 0, iNum,"RemoveMenu");
    } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " print") - 1) == PLUGIN_CHAT_CMD + " print") { //grab partial string match to capture destination name
        PrintDestinations(kID);
    } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD) - 1) == PLUGIN_CHAT_CMD) {
        string sCmd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_CMD) + 1, -1), STRING_TRIM);
        g_kCommander = kID;
        if (llListFindList(g_lVolatile_Destinations, [sCmd]) >= 0) {
            integer iIndex = llListFindList(g_lVolatile_Destinations, [sCmd]);
            TeleportTo(llList2String(g_lVolatile_Slurls, iIndex));
        } else if (llListFindList(g_lDestinations, [sCmd]) >= 0) { //Found exact match, TP over
            integer iIndex = llListFindList(g_lDestinations, [sCmd]);
            TeleportTo(llList2String(g_lDestinations_Slurls, iIndex));
        } else if (llStringLength(sCmd) > 0) { // We didn't get a case sensitive match, so lets loop through what we know and try find what we need
            integer i;
            integer iEnd = llGetListLength(g_lDestinations);
            string sDestination;
            integer found = 0;
            list matchedBookmarks;
            for (; i < iEnd; i++) { //First check OC locations
                sDestination = llList2String(g_lDestinations, i);
                if(llSubStringIndex(llToLower(sDestination), llToLower(sCmd)) >= 0) {
                    //store it, if we only find one, we'll go there
                    found += 1;
                    matchedBookmarks += sDestination;
                }
            }
            i = 0;
            iEnd = llGetListLength(g_lVolatile_Destinations);
            for(i = 0; i < iEnd; i++) { //Then check volatile destinations
                sDestination = llList2String(g_lVolatile_Destinations, i);
                if(llSubStringIndex(llToLower(sDestination), llToLower(sCmd)) >= 0) {
                    //store it, if we only find one, we'll go there
                    found += 1;
                    matchedBookmarks += sDestination;
                }
            }
            if(found == 0) {
                //old hud command compatibility: 'o:176382.800000/261210.900000/3503.276000=force'
                //if (llSubStringIndex(sCmd,"o:") == 0) llMessageLinked(LINK_SET, RLV_CMD, "tpt"+sCmd, kID);// (enable this to support hud forcetp.  disabled now since rlvtp still does this
                //else
                llMessageLinked(LINK_SET,NOTIFY,"0"+"The bookmark '" + sCmd + "' has not been found in the %DEVICETYPE% of %WEARERNAME%.",kID);
            } else if(found > 1)
                Dialog(kID, "More than one matching bookmark was found in the %DEVICETYPE% of %WEARERNAME%.\nChoose a bookmark to teleport to.", matchedBookmarks, [UPMENU], 0, iNum,"choose bookmark");
            else  //exactly one matching LM found, so use it
                UserCommand(iNum, PLUGIN_CHAT_CMD + " " + llList2String(matchedBookmarks, 0), g_kCommander); //Push matched result to command
        }
        //Can't find in list, lets try find substring matches
        else
            llMessageLinked(LINK_SET,NOTIFY,"0"+"I didn't understand your command.",kID);
    }
}

addDestination(string sMessage, string sLoc, key kID) {
    if (llGetListLength(g_lVolatile_Destinations)+llGetListLength(g_lDestinations) >= 45 ) {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"The maximum number 45 bookmars is already reached.",kID);
        return;
    }
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sMessage + "=" + sLoc, "");
    g_lVolatile_Destinations += sMessage;
    g_lVolatile_Slurls += sLoc;
    llMessageLinked(LINK_SET,NOTIFY,"0"+"Added destination " + sMessage + " with a location of: " + sLoc,kID);
}

string FormatRegionName() {
    //Formatting to regionname(x,x,x)
    string region = llGetRegionName();
    vector pos = llGetPos();
    string posx = (string)llRound(pos.x);
    string posy = (string)llRound(pos.y);
    string posz = (string)llRound(pos.z);
    return (region + "(" + posx + "," + posy + "," + posz + ")");
}

string convertSlurl(string sStr) {  //convert the slurl http strings to region (xxx,xxx,xxx)
    sStr = llStringTrim(llUnescapeURL(sStr), STRING_TRIM);
    string sIndex = "http:";
    list lPieces =  llParseStringKeepNulls(sStr, ["/"], []);
    integer iHttploc = 0;
    string sStringToKeep;
    integer iHttpInString = llSubStringIndex(llList2String(lPieces, 0), sIndex);
    if(iHttpInString > 0)
        sStringToKeep = llGetSubString(llList2String(lPieces, 0), 0, iHttpInString - 1);
    if(llGetListLength(lPieces) == 8) {
        string sRegion = llList2String(lPieces, iHttploc + 4);
        string sLocationx = llList2String(lPieces, iHttploc + 5);
        string sLocationy = llList2String(lPieces, iHttploc + 6);
        string sLocationz = llList2String(lPieces, iHttploc + 7);
        sStr = sStringToKeep + sRegion + "(" + sLocationx + "," + sLocationy + "," + sLocationz + ")";
        //Debug("Converted slurl, sending for processing..." + sStr);
        return sStr; //successful conversion, send converted string assembly
    }
    //Debug("No slurl detected, sending for processing anyways :" + sStr);
    return sStr; //failed conversion, send raw string assuming there's no Slurls
}

integer isInteger(string input) { //for validating location scheme
    return ((string)((integer)input) == input);
}

integer validatePlace(string sStr, key kAv, integer iAuth) {
    //Debug("validatePlaces working on: "+sStr);
    list lPieces;
    integer MAX_CHAR_TYPE = 2; //we use +1 due since we're counting with a list split.  We can only accept 1 of each of the following: ()~
    string sAssembledLoc;
    string sRegionName;
    string sFriendlyName;
    sStr = llStringTrim(sStr, STRING_TRIM);
    lPieces = llParseStringKeepNulls(sStr, ["~"], []); // split location from friendly name
    if(llGetListLength(lPieces) == MAX_CHAR_TYPE) {   //We have a tilde, so make sure the friendly name is good
        if(llStringLength(llList2String(lPieces, 0)) < 1) { return 2;} //make sure friendly name isn't empty
        sFriendlyName = llStringTrim(llList2String(lPieces, 0), STRING_TRIM); //assign friendly name
        lPieces = llParseStringKeepNulls(llList2String(lPieces, 1), ["("], []); // split location from friendly name
    } else if(llGetListLength(lPieces) > MAX_CHAR_TYPE) { return 1; } //too many tildes, retreat
    else { lPieces = llParseStringKeepNulls(llList2String(lPieces, 0), ["("], []); } // We don't have a friendly name, so let's ignore that for now and split at 0
    if(llGetListLength(lPieces) == MAX_CHAR_TYPE) {    //Check to see we don't have extra ('s - this might also mean there's no location coming...
        if(llStringLength(llList2String(lPieces, 0)) < 1) { return 4;} //make sure region name isn't empty
        sRegionName = llStringTrim(llList2String(lPieces, 0), STRING_TRIM); //trim off whitespace from region name
    } else if(llGetListLength(lPieces) > MAX_CHAR_TYPE) {return 3; } //this location looks wrong, retreat
    else  { //there's no location here, kick out new menu
        UserCommand(iAuth, PLUGIN_CHAT_CMD + " save " + sStr, kAv);
        UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
        return 0;
    }
    //we're left with sFriendlyname,sRegionName,["blah","123,123)"] - so lets validate the last list item
    sAssembledLoc = llStringTrim("(" + llList2String(lPieces, 1), STRING_TRIM); //reattach the bracket we lost, clean up whitespace
    lPieces = llParseStringKeepNulls(sAssembledLoc, [","], []); // split location from friendly name
    if(llGetListLength(lPieces) != 3) { return 5; }  //Check to see we don't have extra ,'s
    if(llGetSubString(sAssembledLoc, 0, 0) != "(") { return 6; } //location doesn't start with (
    if(llGetSubString(sAssembledLoc, llStringLength(sAssembledLoc) - 1, llStringLength(sAssembledLoc) - 1) != ")") { return 7; } //location doesn't end with )
    lPieces = llParseStringKeepNulls(llGetSubString(sAssembledLoc, 1, llStringLength(sAssembledLoc) - 2), [","], []); // lPieces should be a list of 3 sets of numbers
    integer i;
    for(; i <= llGetListLength(lPieces)-1; ++i) { //run through this number list to make sure each character is numeric
        integer y = 0;
        integer z = llStringLength(llList2String(lPieces, i)) - 1;
        for(y = 0; y <= z; ++y) {
            if(isInteger(llGetSubString(llList2String(lPieces, i), y, y)) != 1) { return 8; } //something left in here isn't an integer
        }
    }
    if(sFriendlyName == "") {
        g_tempLoc = sRegionName + sAssembledLoc; //assign a global for use in response menu
        Dialog(kAv,
"\nEnter a name for the destination " + sRegionName + sAssembledLoc + "
below.\n- Submit a blank field to cancel and return.", [], [], 0, iAuth,"TextBoxIdLocation");

    } else {
        addDestination(sFriendlyName, sRegionName, kAv);
        UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
    }
    return 0;
}

ReadDestinations() {  // On inventory change, re-read our ~destinations notecard and pull from web
    g_lDestinations = [];
    g_lDestinations_Slurls = [];
    webLookup = llHTTPRequest(g_sWeb+"bookmarks.txt",[HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
    //start re-reading the notecards
    g_iLine = 0;
    if(llGetInventoryKey(g_sCard))
        g_kDataID = llGetNotecardLine(g_sCard, 0);
}

TeleportTo(string sStr) {  //take a string in region (x,y,z) format, and retrieve global coordinates.  The teleport takes place in the data server section
    string sRegion = llStringTrim(llGetSubString(sStr, 0, llSubStringIndex(sStr, "(") - 1), STRING_TRIM);
    string sCoords = llStringTrim(llGetSubString(sStr, llSubStringIndex(sStr, "(") + 1 , llStringLength(sStr) - 2), STRING_TRIM);
    list tokens = llParseString2List(sCoords, [","], []);
    // Extract local X, Y and Z
    g_vLocalPos.x = llList2Float(tokens, 0);
    g_vLocalPos.y = llList2Float(tokens, 1);
    g_vLocalPos.z = llList2Float(tokens, 2);
    // Request info about the sim
    if(g_iRLVOn == FALSE)   //If we don't have RLV, we can just send to llMapDestination for a popup
        llMapDestination(sRegion, g_vLocalPos, ZERO_VECTOR);
    else  //We've got RLV, let's use it
        g_kRequestHandle = llRequestSimulatorData(sRegion, DATA_SIM_POS);
}

PrintDestinations(key kID) {  // On inventory change, re-read our ~destinations notecard
    integer i;
    integer iLength = llGetListLength(g_lDestinations);
    string sMsg;
    sMsg += "\n\nThe below can be copied and pasted into the " + g_sCard + " notecard. The format should follow:\n\ndestination name~region name(123,123,123)\n\n";
    for(; i < iLength; i++) {
        sMsg += llList2String(g_lDestinations, i) + "~" + llList2String(g_lDestinations_Slurls, i) + "\n";
        if (llStringLength(sMsg) >1000) {
             llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg,kID);
             sMsg = "";
        }
    }
    iLength = llGetListLength(g_lVolatile_Destinations);
    for(i = 0; i < iLength; i++) {
        sMsg += llList2String(g_lVolatile_Destinations, i) + "~" + llList2String(g_lVolatile_Slurls, i) + "\n";
        if (llStringLength(sMsg) >1000) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg,kID);
            sMsg = "";
        }
    }
    llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg,kID);
}

default {
    on_rez(integer iStart) {
        ReadDestinations();
    }

    state_entry() {
        g_kWearer = llGetOwner();  // store key of wearer
        PermsCheck();
        ReadDestinations(); //Grab our presets
        //Debug("Starting");
    }

    http_response(key id, integer status, list meta, string body) {
        if(status == 200) {  // be silent on failures.
            //      Debug(body);
            if(id == webLookup) {
                list lResponse;
                lResponse = llParseString2List(body, ["\n"], [""]);
                integer i = 0;
                integer x = 0;
                string sData;
                list split;
                x = llGetListLength(lResponse) - 1;
                for(i = 0; i <= x; ++i) {
                    sData = llStringTrim(llList2String(lResponse, i), STRING_TRIM);
                    split = llParseString2List(sData, ["~"], []);
                    g_lDestinations = [ llStringTrim(llList2String(split, 0), STRING_TRIM) ] + g_lDestinations;
                    g_lDestinations_Slurls = [ llStringTrim(llList2String(split, 1), STRING_TRIM) ] + g_lDestinations_Slurls ;
                }
                //     Debug("Body: " + body);
            }
        }
    }

    dataserver(key kID, string sData) {
        if(kID == g_kRequestHandle) {
            // Parse the dataserver response (it is a vector cast to a string)
            list tokens = llParseString2List(sData, ["<", ",", ">"], []);
            string pos_str;
            vector global_pos;
            // The coordinates given by the dataserver are the ones of the
            // South-West corner of this sim
            // => offset with the specified local coordinates
            global_pos.x = llList2Float(tokens, 0);
            global_pos.y = llList2Float(tokens, 1);
            global_pos.z = llList2Float(tokens, 2);
            global_pos += g_vLocalPos;
            // Build the command
            pos_str = (string)((integer)global_pos.x)
                      + "/" + (string)((integer)global_pos.y)
                      + "/" + (string)((integer)global_pos.z);
            //Debug("Global position : "+(string)pos_str);
            // Pass command to main
            if(g_iRLVOn) {
                string sRlvCmd = "tpto:" + pos_str + "=force";
                llMessageLinked(LINK_SET, RLV_CMD, sRlvCmd, g_kCommander);
            }
        }
        if(kID == g_kDataID) {
            list split;
            if(sData != EOF) {
                if(llGetSubString(sData, 0, 2) != "") {
                    sData = llStringTrim(sData, STRING_TRIM);
                    split = llParseString2List(sData, ["~"], []);
                    if(! ~llListFindList(g_lDestinations, [llStringTrim(llList2String(split, 0), STRING_TRIM)])){
                        g_lDestinations += [ llStringTrim(llList2String(split, 0), STRING_TRIM) ];
                        g_lDestinations_Slurls += [ llStringTrim(llList2String(split, 1), STRING_TRIM) ];
                        if (llGetListLength(g_lDestinations) == 30) return;
                    }
                }
                g_iLine++;
                g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
            }
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //     Debug((string)iSender + "|" + (string)iNum + "|" + sStr + "|" + (string)kID);
        if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if(iNum == RLV_OFF)
            g_iRLVOn = FALSE;
        else if(iNum == RLV_ON)
            g_iRLVOn = TRUE;
        else if(iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            
            integer ind = llListFindList(g_lSettingsReqs, [sToken]);
            if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if(llGetSubString(sToken, 0, i) == g_sSettingToken) {
                list lDestination = [llGetSubString(sToken, llSubStringIndex(sToken, "_") + 1, llSubStringIndex(sToken, "="))];
                if(llListFindList(g_lVolatile_Destinations, lDestination) < 0) {
                    g_lVolatile_Destinations += lDestination;
                    g_lVolatile_Slurls += [sValue];
                }
            }
        } else if(iNum == LM_SETTING_EMPTY){
            
            integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if(iNum == LM_SETTING_DELETE){
            
            integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER && iNum != CMD_GROUP) UserCommand(iNum, sStr, kID); // This is intentionally not available to public access.
        else if(iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                // integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if(sMenuType == "TextBoxIdLocation") {
                    if(sMessage != " ")
                        addDestination(sMessage, g_tempLoc, kID);
                    UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
                } else if(sMenuType == "TextBoxIdSave") {
                    //Debug("TBoxIDSave " + sMessage);
                    if(sMessage != " ")
                        validatePlace(convertSlurl(sMessage), kAv, iAuth);
                    else
                        UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
                } else if(sMenuType == "RemoveMenu") {
                    //       Debug("|"+sMessage+"|");
                    if(sMessage == UPMENU) {
                        UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
                        return;
                    }
                    if(sMessage != "") {
                        //got a menu response meant for us. pull out values
                        UserCommand(iAuth, PLUGIN_CHAT_CMD + " remove " + sMessage, kAv);
                        UserCommand(iAuth, PLUGIN_CHAT_CMD + " remove", kAv);
                    } else { UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv); }
                } else if(sMessage == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                } else if (sMenuType == "rmbookmarks") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_SET, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_SET, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_SET, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                } else if(~llListFindList(PLUGIN_BUTTONS, [sMessage])) {
                    if(sMessage == "SAVE")
                        UserCommand(iAuth, PLUGIN_CHAT_CMD + " save", kAv);
                    else if(sMessage == "REMOVE")
                        UserCommand(iAuth, PLUGIN_CHAT_CMD + " remove", kAv);
                    else if(sMessage == "PRINT") {
                        UserCommand(iAuth, PLUGIN_CHAT_CMD + " print", kAv);
                        UserCommand(iAuth, PLUGIN_CHAT_CMD, kAv);
                    }
                } else if(~llListFindList(g_lDestinations + g_lVolatile_Destinations, [sMessage]))
                    UserCommand(iAuth, PLUGIN_CHAT_CMD + " " + sMessage, kAv);
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            DebugOutput(kID, [" DESTINATIONS:"]+g_lDestinations);
            DebugOutput(kID, [" TEMPORARY DESTINATIONS:"]+g_lVolatile_Destinations);
        } // TODO: Add timer callback - this script must be rewritten to comply with new coding standards for OpenCollar. It does not save a predictable token, therefore cannot be reasonably requested or deleted.
    }

    changed(integer iChange) {
        if(iChange & CHANGED_INVENTORY) {
            PermsCheck();
            ReadDestinations();
        }
        if(iChange & CHANGED_OWNER)  llResetScript();
    }
}
