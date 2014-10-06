////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - bookmarks                              //
//                                 version 3.988                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string  SUBMENU_BUTTON              = "Bookmarks"; // Name of the submenu
string  COLLAR_PARENT_MENU          = "Apps"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string  PLUGIN_CHAT_COMMAND         = "tp"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin
string  PLUGIN_CHAT_COMMAND_ALT     = "bookmarks"; //taking control over some map/tp commands from rlvtp
integer IN_DEBUG_MODE               = FALSE;    // set to TRUE to enable Debug messages
string  g_sCard                     = ".bookmarks"; //Name of the notecards to store destinations.
key webLookup;

list   g_lDestinations                = []; //Destination list direct from static notecard
list   g_lDestinations_Slurls         = []; //Destination list direct from static notecard
list   g_lVolatile_Destinations       = []; //These are in memory preferences that are not yet saved into the notecard
list   g_lVolatile_Slurls             = []; //These are in memory preferences that are not yet saved into the notecard
key    g_kRequestHandle               = NULL_KEY; //Sim Request Handle to convert global coordinates
vector g_vLocalPos                    = ZERO_VECTOR;
key    g_kRemoveMenu                  = NULL_KEY; //Use a separate key for the remove menu ID
integer g_iRLVOn                      = FALSE; //Assume RLV is off until we hear otherwise
string g_tempLoc                      = "";   //This holds a global temp location for manual entry from provided location but no favorite name - g_kTBoxIdLocationOnly

key     g_kMenuID;                              // menu handler
key     g_kWearer;                              // key of the current wearer to reset only on owner changes
key     g_kTBoxIdSave = "null";
key     g_kTBoxIdLocationOnly = "null";
string  g_sScript;                              // part of script name used for settings
key     g_kDataID;
integer g_iLine = 0;
string  UPMENU                      = "BACK"; // when your menu hears this, give the parent menu
key     g_kCommander;

string CTYPE                        = "collar";    // designer can set in notecard to appropriate word for their item

list    PLUGIN_BUTTONS              = ["SAVE", "PRINT", "REMOVE"];
list    g_lButtons;

integer COMMAND_OWNER              = 500;
integer COMMAND_WEARER             = 503;
integer LM_SETTING_SAVE            = 2000; // scripts send messages on this channel to have settings saved to settings store
integer LM_SETTING_RESPONSE        = 2002; // the settings script will send responses on this channel
integer LM_SETTING_DELETE          = 2003; // delete token from settings store
integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
integer RLV_CMD                    = 6000;
integer RLV_OFF                    = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON                     = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;

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
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}
*/


Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if((integer)llStringLength(sMsg) > 1023) {  //Line too long, gotta chop this up!
        integer i;
        integer x = 0;
        for(i = 1023; x <= i; --i) {
            if(llGetSubString(sMsg, i, i) == "\n") { //got a breaking point
                Notify(kID, llGetSubString(sMsg, 0, i), iAlsoNotifyWearer);
                Notify(kID, llGetSubString(sMsg, i, -1), iAlsoNotifyWearer);
                return;
            }
        }
    }
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}


key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
                    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DoMenu(key keyID, integer iAuth)
{
    string sPrompt = "\nTake me away, gumby!\n\nwww.opencollar.at/bookmarks";
    list lMyButtons = PLUGIN_BUTTONS + g_lButtons + g_lDestinations + g_lVolatile_Destinations;
    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if(!(iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)) {
        return FALSE;
    }
    // a validated command from a owner, secowner, groupmember or the wearer has been received
    list lParams = llParseString2List(sStr, [" "], []);
    //string sCommand = llToLower(llList2String(lParams, 0));
    //string sValue = llToLower(llList2String(lParams, 1));
    // So commands can accept a value
    if(sStr == "reset") {
        // it is a request for a reset
        if(iNum == COMMAND_WEARER || iNum == COMMAND_OWNER) {
            //only owner and wearer may reset
            llResetScript();
        }
    } else if(sStr == PLUGIN_CHAT_COMMAND || sStr == "menu " + SUBMENU_BUTTON || sStr == PLUGIN_CHAT_COMMAND_ALT) {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    } else if(llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_COMMAND + " save") - 1) == PLUGIN_CHAT_COMMAND + " save") { //grab partial string match to capture destination name
        if(llStringLength(sStr) > llStringLength(PLUGIN_CHAT_COMMAND + " save")) {
            string sAdd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_COMMAND + " save") + 1, -1), STRING_TRIM);
            if(llListFindList(g_lVolatile_Destinations, [sAdd]) >= 0 || llListFindList(g_lDestinations, [sAdd]) >= 0) {
                Notify(kID, "This destination name is already taken", FALSE);
            } else {
                string slurl = FormatRegionName();
                addDestination(sAdd, slurl, kID);
            }
        } else {
            // Notify that they need to give a description of the saved destination ie. <prefix>bookmarks save description
            g_kTBoxIdSave = Dialog(kID,

"Enter a name for the destination below. Submit a blank field to cancel and return.
You can enter:
1) A friendly name to save your current location to your favorites
2) A new location or SLurl", [], [], 0, iNum);

        }
    } else if(llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_COMMAND + " remove") - 1) == PLUGIN_CHAT_COMMAND + " remove") { //grab partial string match to capture destination name
        if(llStringLength(sStr) > llStringLength(PLUGIN_CHAT_COMMAND + " remove")) {
            string sDel = llStringTrim(llGetSubString(sStr,  llStringLength(PLUGIN_CHAT_COMMAND + " remove"), -1), STRING_TRIM);
            if(llListFindList(g_lVolatile_Destinations, [sDel]) < 0) {
                Notify(kID, "Can't find bookmark " + (string)sDel + " to be deleted", FALSE);
            } else {
                integer iIndex;
                llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript + sDel, "");
                iIndex = llListFindList(g_lVolatile_Destinations, [sDel]);
                g_lVolatile_Destinations = llDeleteSubList(g_lVolatile_Destinations, iIndex, iIndex);
                g_lVolatile_Slurls = llDeleteSubList(g_lVolatile_Slurls, iIndex, iIndex);
                Notify(kID, "Removed destination " + sDel, FALSE);
            }
        } else {
            g_kRemoveMenu = Dialog(kID, "Select a bookmark to be removed...", g_lVolatile_Destinations, [UPMENU], 0, iNum);
        }
    } else if(llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_COMMAND + " print") - 1) == PLUGIN_CHAT_COMMAND + " print") { //grab partial string match to capture destination name
        PrintDestinations(kID);
    } else if(llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_COMMAND) - 1) == PLUGIN_CHAT_COMMAND) {
        string sCmd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_COMMAND) + 1, -1), STRING_TRIM);
        g_kCommander = kID;
        if(llListFindList(g_lVolatile_Destinations, [sCmd]) >= 0) {
            integer iIndex = llListFindList(g_lVolatile_Destinations, [sCmd]);
            TeleportTo(llList2String(g_lVolatile_Slurls, iIndex));
        } else if(llListFindList(g_lDestinations, [sCmd]) >= 0) { //Found exact match, TP over
            integer iIndex = llListFindList(g_lDestinations, [sCmd]);
            TeleportTo(llList2String(g_lDestinations_Slurls, iIndex));
        } else if(llStringLength(sCmd) > 0) { // We didn't get a case sensitive match, so lets loop through what we know and try find what we need
            integer i = 0;
            integer x = llGetListLength(g_lDestinations);
            string s;
            integer found = 0;
            list matchedBookmarks;
            for(i = 0; i < x; i++) { //First check OC locations
                s = llList2String(g_lDestinations, i);
                if(llSubStringIndex(llToLower(s), llToLower(sCmd)) >= 0) {
                    //store it, if we only find one, we'll go there
                    //Notify(kID,"Matched bookmark '"+s+"'",FALSE);
                    found += 1;
                    matchedBookmarks += s;
                }
            }
            i = 0;
            x = llGetListLength(g_lVolatile_Destinations);
            for(i = 0; i < x; i++) { //Then check volatile destinations
                s = llList2String(g_lVolatile_Destinations, i);
                if(llSubStringIndex(llToLower(s), llToLower(sCmd)) >= 0) {
                    //store it, if we only find one, we'll go there
                    //Notify(kID,"Matched bookmark '"+s+"'",FALSE);
                    found += 1;
                    matchedBookmarks += s;
                }
            }
            if(found == 0) {
                //old hud command compatibility: 'o:176382.800000/261210.900000/3503.276000=force'
                if (llSubStringIndex(sCmd,"o:") == 0) {}//llMessageLinked(LINK_SET, RLV_CMD, "tpt"+sCmd, kID); (enable this to support hud forcetp.  disabled now since rlvtp still does this
                else Notify(kID, "The bookmark '" + sCmd + "' has not been found in the " + CTYPE + " of " + llKey2Name(g_kWearer) + ".", FALSE);
            } else if(found > 1) {
                g_kMenuID = Dialog(kID, "More than one matching landmark was found in the " + CTYPE + " of " + llKey2Name(g_kWearer) + 
                    ".\nChoose a bookmark to teleport to.", matchedBookmarks, [UPMENU], 0, iNum);
            } else { //exactly one matching LM found, so use it
                UserCommand(iNum, PLUGIN_CHAT_COMMAND + " " + llList2String(matchedBookmarks, 0), g_kCommander); //Push matched result to command for processing
            }
        }
        //Can't find in list, lets try find substring matches
        else {
            Notify(kID, "I didn't understand your command.", FALSE);
        }
    }
    return TRUE;
}

addDestination(string sMessage, string sLoc, key kID)
{
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + sMessage + "=" + sLoc, "");
    g_lVolatile_Destinations += sMessage;
    g_lVolatile_Slurls += sLoc;
    Notify(kID, "Added destination " + sMessage + " with a location of: " + sLoc, FALSE);
}

string FormatRegionName()
{
    //Formatting to regionname(x,x,x)
    string region = llGetRegionName();
    vector pos = llGetPos();
    string posx = (string)llRound(pos.x);
    string posy = (string)llRound(pos.y);
    string posz = (string)llRound(pos.z);
    return (region + "(" + posx + "," + posy + "," + posz + ")");
}

string convertSlurl(string sStr, key kAv, integer iAuth)  //convert the slurl http strings to region (xxx,xxx,xxx)
{
    sStr = llStringTrim(llUnescapeURL(sStr), STRING_TRIM);
    string sIndex = "http:";
    list lPieces =  llParseStringKeepNulls(sStr, ["/"], []);
    integer iHttploc = 0;
    string sStringToKeep;
    integer iHttpInString = llSubStringIndex(llList2String(lPieces, 0), sIndex);
    if(iHttpInString > 0) {
        sStringToKeep = llGetSubString(llList2String(lPieces, 0), 0, iHttpInString - 1);
    }
    if(llGetListLength(lPieces) == 8) { //
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


integer isInteger(string input) //for validating location scheme
{
    return ((string)((integer)input) == input);
}

integer validatePlace(string sStr, key kAv, integer iAuth)
{
    //Debug("validatePlaces working on: "+sStr);
    list lPieces;
    integer MAX_CHAR_TYPE = 2; //we use +1 due since we're counting with a list split.  We can only accept 1 of each of the following: ()~
    string sAssembledLoc;
    string sRegionName;
    string sFriendlyName;
    sStr = llStringTrim(sStr, STRING_TRIM); //clean up whitespace
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
        UserCommand(iAuth, PLUGIN_CHAT_COMMAND + " save " + sStr, kAv);
        UserCommand(iAuth, PLUGIN_CHAT_COMMAND, kAv);
        return 0;
    }
    //we're left with sFriendlyname,sRegionName,["blah","123,123)"] - so lets validate the last list item
    sAssembledLoc = llStringTrim("(" + llList2String(lPieces, 1), STRING_TRIM); //reattach the bracket we lost, clean up whitespace
    lPieces = llParseStringKeepNulls(sAssembledLoc, [","], []); // split location from friendly name
    if(llGetListLength(lPieces) != 3) { return 5; }  //Check to see we don't have extra ,'s
    if(llGetSubString(sAssembledLoc, 0, 0) != "(") { return 6; } //location doesn't start with (
    if(llGetSubString(sAssembledLoc, llStringLength(sAssembledLoc) - 1, llStringLength(sAssembledLoc) - 1) != ")") { return 7; } //location doesn't end with )
    lPieces = llParseStringKeepNulls(llGetSubString(sAssembledLoc, 1, llStringLength(sAssembledLoc) - 2), [","], []); // lPieces should be a list of 3 sets of numbers
    integer i = 0;
    integer x = llGetListLength(lPieces) - 1;
    for(i = 0; i <= x; ++i) { //run through this number list to make sure each character is numeric
        integer y = 0;
        integer z = llStringLength(llList2String(lPieces, i)) - 1;
        for(y = 0; y <= z; ++y) {
            if(isInteger(llGetSubString(llList2String(lPieces, i), y, y)) != 1) { return 8; } //something left in here isn't an integer
        }
    }
    if(sFriendlyName == "") {
        g_tempLoc = sRegionName + sAssembledLoc; //assign a global for use in response menu
        g_kTBoxIdLocationOnly = Dialog(kAv,
"\nEnter a name for the destination " + sRegionName + sAssembledLoc + "
below.\n- Submit a blank field to cancel and return.", [], [], 0, iAuth);

    } else {
        addDestination(sFriendlyName, sRegionName, kAv);
        UserCommand(iAuth, PLUGIN_CHAT_COMMAND, kAv);
    }
    return 0;
}

ReadDestinations()   // On inventory change, re-read our ~destinations notecard and pull from https://raw.githubusercontent.com/OpenCollar/OpenCollarUpdater/main/LSL/~bookmarks
{
    key kAv;
    webLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollar/OpenCollarUpdater/main/LSL/~bookmarks", 
        [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
    g_lDestinations = [];
    g_lDestinations_Slurls = [];
    //start re-reading the notecards
    if(llGetInventoryKey(g_sCard)) {
        g_kDataID = llGetNotecardLine(g_sCard, 0);
    }
}

TeleportTo(string sStr)   //take a string in region (x,y,z) format, and retrieve global coordinates.  The teleport takes place in the data server section
{
    string sRegion = llStringTrim(llGetSubString(sStr, 0, llSubStringIndex(sStr, "(") - 1), STRING_TRIM);
    string sCoords = llStringTrim(llGetSubString(sStr, llSubStringIndex(sStr, "(") + 1 , llStringLength(sStr) - 2), STRING_TRIM);
    list tokens = llParseString2List(sCoords, [","], []);
    // Extract local X, Y and Z
    g_vLocalPos.x = llList2Float(tokens, 0);
    g_vLocalPos.y = llList2Float(tokens, 1);
    g_vLocalPos.z = llList2Float(tokens, 2);
    // Request info about the sim
    if(g_iRLVOn == FALSE) {  //If we don't have RLV, we can just send to llMapDestination for a popup
        llMapDestination(sRegion, g_vLocalPos, ZERO_VECTOR);
    } else { //We've got RLV, let's use it
        g_kRequestHandle = llRequestSimulatorData(sRegion, DATA_SIM_POS);
    }
}

PrintDestinations(key kID)   // On inventory change, re-read our ~destinations notecard
{
    integer i;
    integer length = llGetListLength(g_lDestinations);
    string sMsg;
    sMsg += "\n\nThe below can be copied and pasted into the " + g_sCard + " notecard. The format should follow:\n\ndestination name~region name(123,123,123)\n\n";
    for(i = 0; i < length; i++) {
        sMsg += llList2String(g_lDestinations, i) + "~" + llList2String(g_lDestinations_Slurls, i) + "\n";
    }
    length = llGetListLength(g_lVolatile_Destinations);
    for(i = 0; i < length; i++) {
        sMsg += llList2String(g_lVolatile_Destinations, i) + "~" + llList2String(g_lVolatile_Slurls, i) + "\n";
    }
    Notify(kID, sMsg, i);
}

default {

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
            //Debug("Global position : "+(string)pos_str); // Debug purposes
            // Pass command to main
            if(g_iRLVOn) {
                string sRlvCmd = "tpto:" + pos_str + "=force";
                llMessageLinked(LINK_SET, RLV_CMD, sRlvCmd, g_kCommander);
            }
        }
        if(kID == g_kDataID) { //User notecard
            list split;
            if(sData != EOF) {
                if(llGetSubString(sData, 0, 2) != "") { //Ignore blank lines
                    sData = llStringTrim(sData, STRING_TRIM);
                    split = llParseString2List(sData, ["~"], []);
                    g_lDestinations += [ llStringTrim(llList2String(split, 0), STRING_TRIM) ];
                    g_lDestinations_Slurls += [ llStringTrim(llList2String(split, 1), STRING_TRIM) ];
                }
                g_iLine++;
                g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
            }
        }
    }

    changed(integer iChange) {
        if(iChange & CHANGED_INVENTORY) {
            ReadDestinations();
        }
        if(iChange & CHANGED_OWNER) { llResetScript(); }
        /*
         if (iChange & CHANGED_REGION) {
             if (g_iProfiled){
                 llScriptProfiler(1);
                 Debug("profiling restarted");
              }
         }
         */
    }


    state_entry() {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        // store key of wearer
        g_kWearer = llGetOwner();
        // sleep a second to allow all scripts to be initialized
        ReadDestinations(); //Grab our presets
        // send request to main menu and ask other menus if they want to register with us
        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, SUBMENU_BUTTON, "");
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
    }

    on_rez(integer iParam) {
        if(llGetOwner() != g_kWearer) {
            // Reset if wearer changed
            llResetScript();
        }
    }

    // listen for linked messages from OC scripts
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //     Debug((string)iSender + "|" + (string)iNum + "|" + sStr + "|" + (string)kID);
        if(iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
            g_lButtons = [] ;
            llMessageLinked(LINK_THIS, MENUNAME_REQUEST, SUBMENU_BUTTON, "");
        } else if(iNum == RLV_OFF) { // rlvoff -> we have to turn the menu off too
            g_iRLVOn = FALSE;
        } else if(iNum == RLV_ON) { // rlvon -> we have to turn the menu on again
            g_iRLVOn = TRUE;
        } else if(iNum == MENUNAME_RESPONSE) {
            // a button is send to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if(llList2String(lParts, 0) == SUBMENU_BUTTON) {
                // someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if(llListFindList(g_lButtons, [button]) == -1) {
                    // if the button isnt in our menu yet, than we add it
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        } else if(iNum == LM_SETTING_RESPONSE) {
            // response from setting store have been received
            // pares the answer
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            // and check if any values for use are received
            // replace "value1" by your own token
            integer i = llSubStringIndex(sToken, "_");
            if(llGetSubString(sToken, 0, i) == g_sScript) {
                list lDestination = [llGetSubString(sToken, llSubStringIndex(sToken, "_") + 1, llSubStringIndex(sToken, "="))];
                if(llListFindList(g_lVolatile_Destinations, lDestination) < 0) {
                    g_lVolatile_Destinations += lDestination;
                    g_lVolatile_Slurls += [sValue];
                }
            } else if(sToken == "Global_CType") { CTYPE = sValue; }
        } else if(UserCommand(iNum, sStr, kID)) {
            // do nothing more if TRUE
        } else if(iNum == DIALOG_RESPONSE) {
            if(llListFindList([g_kMenuID, g_kTBoxIdSave, g_kRemoveMenu, g_kTBoxIdLocationOnly], [kID]) != -1) {
                //got a menu response meant for us, extract the values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
                if(kID == g_kTBoxIdLocationOnly) {
                    //got a menu response meant for us. pull out values
                    if(sMessage != "") {
                        addDestination(sMessage, g_tempLoc, kID);
                    }
                    UserCommand(iAuth, PLUGIN_CHAT_COMMAND, kAv);
                } else if(kID == g_kTBoxIdSave) {
                    //got a menu response meant for us. pull out values
                    //                if(sMessage != "") UserCommand(iAuth, "bookmarks save " + sMessage, kAv);
                    //Debug("TBoxIDSave " + sMessage);
                    if(sMessage != "") {
                        validatePlace(convertSlurl(sMessage, kAv, iAuth), kAv, iAuth);
                    } else {
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND, kAv);
                    }
                } else if(kID == g_kRemoveMenu) {
                    //       Debug("|"+sMessage+"|");
                    if(sMessage == UPMENU) {
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND, kAv);
                        return;
                    }
                    if(sMessage != "") {
                        //got a menu response meant for us. pull out values
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND + " remove " + sMessage, kAv);
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND + " remove", kAv);
                    } else { UserCommand(iAuth, PLUGIN_CHAT_COMMAND, kAv); }
                } else if(sMessage == UPMENU) {
                    llMessageLinked(LINK_THIS, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
                } else if(~llListFindList(PLUGIN_BUTTONS, [sMessage])) {
                    if(sMessage == "SAVE") {
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND + " save", kAv);
                    } else if(sMessage == "REMOVE") {
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND + " remove", kAv);
                    } else if(sMessage == "PRINT") {
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND + " print", kAv);
                        UserCommand(iAuth, PLUGIN_CHAT_COMMAND, kAv);
                    }
                } else if(~llListFindList(g_lDestinations + g_lVolatile_Destinations, [sMessage])) {
                    UserCommand(iAuth, PLUGIN_CHAT_COMMAND + " " + sMessage, kAv);
                } else if(~llListFindList(g_lButtons, [sMessage])) {
                    llMessageLinked(LINK_THIS, iAuth, "menu " + sMessage, kAv);
                }
            }
        }
    }
}
