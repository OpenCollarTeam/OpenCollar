//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//     Remote Bookmarks - 160121.2       .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Satomi Ahn, Nandana Singh, Wendy Starfall,    //
//  Sumi Perl, Master Starship, littlemousy, mewtwo064, ml132,              //
//  Romka Swallowtail, Garvin Twine et al.                                  //
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
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

string g_sAppVersion = "¹⁶⁰¹²⁰⋅²";

string  PLUGIN_CHAT_CMD             = "tp"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin
string  PLUGIN_CHAT_CMD_ALT         = "bookmarks"; //taking control over some map/tp commands from rlvtp
integer IN_DEBUG_MODE               = FALSE;    // set to TRUE to enable Debug messages
string  g_sCard                     = ".bookmarks"; //Name of the notecards to store destinations.
key webLookup;

list   g_lDestinations                = []; //Destination list direct from static notecard
list   g_lDestinations_Slurls         = []; //Destination list direct from static notecard
list   g_lVolatile_Destinations       = []; //These are in memory preferences that are not yet saved into the notecard
list   g_lVolatile_Slurls             = []; //These are in memory preferences that are not yet saved into the notecard
key    g_kRequestHandle               = NULL_KEY; //Sim Request Handle to convert global coordinates
vector g_vLocalPos                    = ZERO_VECTOR;
string g_sRegion;

string g_tempLoc                      = "";   //This holds a global temp location for manual entry from provided location but no favorite name - g_kTBoxIdLocationOnly

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

key     g_kOwner;
key     g_kDataID;
integer g_iLine = 0;
string  UPMENU                      = "BACK";
key     g_kCommander;

list    PLUGIN_BUTTONS              = ["SAVE", "PRINT", "REMOVE"];

//MESSAGE MAP
integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;

integer CMD_REMOTE                 = 10000;
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
Dialog(string sPrompt, list lChoices, list lUtilityButtons, integer iPage, string sMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)g_kOwner + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|", kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [g_kOwner]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [g_kOwner, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [g_kOwner, kMenuID, sMenuType];
}

DoMenu() {
    string sPrompt = "\n[http://www.opencollar.at/bookmarks.html Remote Bookmarks]\t"+g_sAppVersion;
    list lMyButtons = PLUGIN_BUTTONS + g_lDestinations + g_lVolatile_Destinations;
    string sCancel;
    if (llGetListLength(lMyButtons) % 3) sCancel = "Cancel";
    Dialog(sPrompt, lMyButtons, [sCancel], 0, "bookmarks");
}

UserCommand(string sStr) {
    list lParams = llParseString2List(sStr, [" "], []);
    // So commands can accept a value
    if (sStr == "reset") {
         llResetScript();
    } else if(sStr == PLUGIN_CHAT_CMD || llToLower(sStr) == "menu " + PLUGIN_CHAT_CMD_ALT || llToLower(sStr) == PLUGIN_CHAT_CMD_ALT)
        DoMenu();
    else if(llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " save") - 1) == PLUGIN_CHAT_CMD + " save") {           
//grab partial string match to capture destination name
        if(llStringLength(sStr) > llStringLength(PLUGIN_CHAT_CMD + " save")) {
            string sAdd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_CMD + " save") + 1, -1), STRING_TRIM);
            if(llListFindList(g_lVolatile_Destinations, [sAdd]) >= 0 || llListFindList(g_lDestinations, [sAdd]) >= 0)
                llOwnerSay("This destination name is already taken");
            else {
                string slurl = FormatRegionName();
                addDestination(sAdd, slurl);
            }
        } else {
            // Notify that they need to give a description of the saved destination ie. <prefix>bookmarks save description
            Dialog(
"Enter a name for the destination below. Submit a blank field to cancel and return.
You can enter:
1) A friendly name to save your current location to your favorites
2) A new location or SLurl", [], [], 0,"TextBoxIdSave");

        }
    } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " remove") - 1) == PLUGIN_CHAT_CMD + " remove") { //grab partial string match to capture destination name
        if (llStringLength(sStr) > llStringLength(PLUGIN_CHAT_CMD + " remove")) {
            string sDel = llStringTrim(llGetSubString(sStr,  llStringLength(PLUGIN_CHAT_CMD + " remove"), -1), STRING_TRIM);
            if (llListFindList(g_lVolatile_Destinations, [sDel]) < 0) {
                llOwnerSay("Can't find bookmark " + (string)sDel + " to be deleted.");
            } else {
                integer iIndex;
                iIndex = llListFindList(g_lVolatile_Destinations, [sDel]);
                g_lVolatile_Destinations = llDeleteSubList(g_lVolatile_Destinations, iIndex, iIndex);
                g_lVolatile_Slurls = llDeleteSubList(g_lVolatile_Slurls, iIndex, iIndex);
                llOwnerSay("Removed destination " + sDel);
            }
        } else
            Dialog("\nSelect a bookmark to be removed...", g_lVolatile_Destinations, [UPMENU], 0,"RemoveMenu");
    } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD + " print") - 1) == PLUGIN_CHAT_CMD + " print") { //grab partial string match to capture destination name
        PrintDestinations();
    } else if (llGetSubString(sStr, 0, llStringLength(PLUGIN_CHAT_CMD) - 1) == PLUGIN_CHAT_CMD) {
        string sCmd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_CMD) + 1, -1), STRING_TRIM);
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
                llOwnerSay("The bookmark '" + sCmd + "' has not been found in the %DEVICETYPE% of %WEARERNAME%.");
            } else if(found > 1)
                Dialog("More than one matching bookmark was found in the %DEVICETYPE% of %WEARERNAME%.\nChoose a bookmark to teleport to.", matchedBookmarks, [UPMENU], 0,"choose bookmark");
            else  //exactly one matching LM found, so use it
                UserCommand(PLUGIN_CHAT_CMD + " " + llList2String(matchedBookmarks, 0)); //Push matched result to command
        }
        //Can't find in list, lets try find substring matches
        else
            llOwnerSay("I didn't understand your command.");
    }
}

addDestination(string sMessage, string sLoc) {
    if (llGetListLength(g_lVolatile_Destinations)+llGetListLength(g_lDestinations) >= 45 ) {
        llOwnerSay("The maximum number 45 bookmars is already reached.");
        return;
    }
    g_lVolatile_Destinations += sMessage;
    g_lVolatile_Slurls += sLoc;
    llOwnerSay("Added destination " + sMessage + " with a location of: " + sLoc);
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

integer validatePlace(string sStr) {
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
        UserCommand(PLUGIN_CHAT_CMD + " save " + sStr);
        UserCommand(PLUGIN_CHAT_CMD);
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
        Dialog("\nEnter a name for the destination " + sRegionName + sAssembledLoc + "
below.\n- Submit a blank field to cancel and return.", [], [], 0, "TextBoxIdLocation");

    } else {
        addDestination(sFriendlyName, sRegionName);
        UserCommand(PLUGIN_CHAT_CMD);
    }
    return 0;
}

ReadDestinations() {     
    g_lDestinations = [];
    g_lDestinations_Slurls = [];
    webLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~bookmarks",[HTTP_METHOD, "GET"], "");
    //start re-reading the notecards
    if(llGetInventoryKey(g_sCard))
        g_kDataID = llGetNotecardLine(g_sCard, 0);
}

TeleportTo(string sStr) {  //take a string in region (x,y,z) format, and retrieve global coordinates.  The teleport takes place in the data server section
    g_sRegion = llStringTrim(llGetSubString(sStr, 0, llSubStringIndex(sStr, "(") - 1), STRING_TRIM);
    string sCoords = llStringTrim(llGetSubString(sStr, llSubStringIndex(sStr, "(") + 1 , llStringLength(sStr) - 2), STRING_TRIM);
    list tokens = llParseString2List(sCoords, [","], []);
    // Extract local X, Y and Z
    g_vLocalPos.x = llList2Float(tokens, 0);
    g_vLocalPos.y = llList2Float(tokens, 1);
    g_vLocalPos.z = llList2Float(tokens, 2);
    g_kRequestHandle = llRequestSimulatorData(g_sRegion, DATA_SIM_POS);
}

PrintDestinations() {  // On inventory change, re-read our ~destinations notecard
    integer i;
    integer iLength = llGetListLength(g_lDestinations);
    string sMsg;
    sMsg += "\n\nEverything below this line can be copied & pasted into a notecard called \""+g_sCard+"\" for backup:\n\n";
    for(; i < iLength; i++) {
        sMsg += llList2String(g_lDestinations, i) + "~" + llList2String(g_lDestinations_Slurls, i) + "\n";
        if (llStringLength(sMsg) >1000) {
             llOwnerSay(sMsg);
             sMsg = "";
        }
    }
    iLength = llGetListLength(g_lVolatile_Destinations);
    for(i = 0; i < iLength; i++) {
        sMsg += llList2String(g_lVolatile_Destinations, i) + "~" + llList2String(g_lVolatile_Slurls, i) + "\n";
        if (llStringLength(sMsg) >1000) {
            llOwnerSay(sMsg);
            sMsg = "";
        }
    }
    llOwnerSay(sMsg);
}

default {
    on_rez(integer iStart) {
        ReadDestinations();
    }
    
    state_entry() {
        g_kOwner = llGetOwner();  // store key of wearer
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
            string sPos = "/"+(string)((integer)g_vLocalPos.x)
                        + "/"+(string)((integer)g_vLocalPos.y)
                        + "/"+(string)((integer)g_vLocalPos.z);
            llMessageLinked(LINK_THIS,CMD_REMOTE, "hudtpto:" + pos_str + "=force","");
            llOwnerSay("Follow your Partner(s) right way by clicking here: secondlife:///app/teleport/"+g_sRegion+sPos);
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
        if (iNum == 0 && sStr == "bookmarks menu") DoMenu();
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if(sMenuType == "TextBoxIdLocation") {
                    if(sMessage != " ")
                        addDestination(sMessage, g_tempLoc);
                    UserCommand(PLUGIN_CHAT_CMD);
                } else if(sMenuType == "TextBoxIdSave") {
                    //Debug("TBoxIDSave " + sMessage);
                    if(sMessage != " ")
                        validatePlace(convertSlurl(sMessage));
                    else
                        UserCommand(PLUGIN_CHAT_CMD);
                } else if(sMenuType == "RemoveMenu") {
                    //       Debug("|"+sMessage+"|");
                    if(sMessage == UPMENU) {
                        UserCommand(PLUGIN_CHAT_CMD);
                        return;
                    }
                    if(sMessage != "") {
                        //got a menu response meant for us. pull out values
                        UserCommand(PLUGIN_CHAT_CMD + " remove " + sMessage);
                        UserCommand(PLUGIN_CHAT_CMD + " remove");
                    } else UserCommand(PLUGIN_CHAT_CMD);
                } else if(~llListFindList(PLUGIN_BUTTONS, [sMessage])) {
                    if(sMessage == "SAVE")
                        UserCommand( PLUGIN_CHAT_CMD + " save");
                    else if(sMessage == "REMOVE")
                        UserCommand(PLUGIN_CHAT_CMD + " remove");
                    else if(sMessage == "PRINT") {
                        UserCommand(PLUGIN_CHAT_CMD + " print");
                        UserCommand(PLUGIN_CHAT_CMD);
                    }
                } else if(~llListFindList(g_lDestinations + g_lVolatile_Destinations, [sMessage]))
                    UserCommand(PLUGIN_CHAT_CMD + " " + sMessage);
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else UserCommand(sStr);
    }

    changed(integer iChange) {
        if(iChange & CHANGED_INVENTORY) ReadDestinations();
        if(iChange & CHANGED_OWNER)  llResetScript();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
