////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - bookmarks                              //
//                                 version 3.980                                  //
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
string  PLUGIN_CHAT_COMMAND         = "bookmarks"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin
integer IN_DEBUG_MODE               = FALSE;    // set to TRUE to enable Debug messages
string  RLV_STRING                  = "rlvmain_on"; //ask for updated RLV status

string   g_sCard                         = "~bookmarks"; //Name of the notecards to store destinations. 

key webLookup;
key webRequester;

list   g_lDestinations                = []; //Destination list direct from static notecard
list   g_lDestinations_Slurls         = []; //Destination list direct from static notecard
list   g_lVolatile_Destinations       = []; //These are in memory preferences that are not yet saved into the notecard
list   g_lVolatile_Slurls             = []; //These are in memory preferences that are not yet saved into the notecard
key    g_kRequestHandle               = NULL_KEY; //Sim Request Handle to convert global coordinates 
vector g_vLocalPos                    = ZERO_VECTOR;
key    g_kRemoveMenu                  = NULL_KEY; //Use a separate key for the remove menu ID
integer g_iRLVOn                      = FALSE; //Assume RLV is off until we hear otherwise
string g_tempLoc                      = "";   //This holds a global temp location for manual entry from provided location but no favorite name - g_kTBoxIdLocationOnly

key g_kDataID;

integer g_iLine = 0;
key g_kTBoxIdSave = "null";
key g_kTBoxIdLocationOnly = "null";
//key g_kTBoxIdRemove = "null";

key     g_kMenuID;                              // menu handler
key     g_kWearer;                              // key of the current wearer to reset only on owner changes
string  g_sScript;                              // part of script name used for settings

string CTYPE                        = "collar";    // designer can set in notecard to appropriate word for their item        

 // any local, not changing buttons which will be used in this plugin, leave empty or add buttons as you like:
list    PLUGIN_BUTTONS              = ["Remove", "Print", "Save"];
list    g_lButtons;

integer COMMAND_OWNER              = 500;
integer COMMAND_SECOWNER           = 501;
integer COMMAND_GROUP              = 502;
integer COMMAND_WEARER             = 503;
integer COMMAND_EVERYONE           = 504;
// messages for storing and retrieving values from settings store
integer LM_SETTING_SAVE            = 2000; // scripts send messages on this channel to have settings saved to settings store
//                                            str must be in form of "token=value"
integer LM_SETTING_REQUEST         = 2001; // when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE        = 2002; // the settings script will send responses on this channel
integer LM_SETTING_DELETE          = 2003; // delete token from settings store
integer LM_SETTING_EMPTY           = 2004; // sent by settings script when a token has no value in the settings store

// messages for creating OC menu structure
integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
integer MENUNAME_REMOVE            = 3003;

// messages for RLV commands
integer RLV_CMD                    = 6000;
integer RLV_REFRESH                = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR                  = 6002; // RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION                = 6003; // RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer RLV_OFF                    = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON                     = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
integer RLV_QUERY                  = 6102; //query from a script asking if RLV is currently functioning
integer RLV_RESPONSE               = 6103; //reply to RLV_QUERY, with "ON" or "OFF" as the message


// messages to the dialog helper
integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;

//rlv relay chan
integer RLV_RELAY_CHANNEL          = -1812221819;

// menu option to go one step back in menustructure
string  UPMENU                     = "BACK"; // when your menu hears this, give the parent menu



//===============================================================================
//= parameters   :    string    sMsg    message string received
//=
//= return        :    none
//=
//= description  :    output debug messages
//=
//===============================================================================


Debug(string sMsg) {
    if (!IN_DEBUG_MODE) {
        return;
    }
    llOwnerSay(llGetScriptName() + " [DEBUG]: " + sMsg);
}

//===============================================================================
//= parameters   :    key       kID                key of the avatar that receives the message
//=                   string    sMsg               message to send
//=                   integer   iAlsoNotifyWearer  if TRUE, a copy of the message is sent to the wearer
//=
//= return        :    none
//=
//= description  :    notify targeted id and maybe the wearer
//=
//===============================================================================

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if ((integer)llStringLength(sMsg) > 1023) { //Line too long, gotta chop this up!
        integer i;
        integer x = 0;
        for(i = 1023; x <= i; --i) { 
            if (llGetSubString(sMsg,i,i) == "\n") { //got a breaking point
                Notify(kID,llGetSubString(sMsg,0,i),iAlsoNotifyWearer);
                Notify(kID,llGetSubString(sMsg,i,-1),iAlsoNotifyWearer);
                return;
            }
        } 
    } 
    
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    } 
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
} 

//===============================================================================
//= parameters   :    key   kRCPT  recipient of the dialog
//=                   string  sPrompt    dialog prompt
//=                   list  lChoices    true dialog buttons
//=                   list  lUtilityButtons  utility buttons (kept on every iPage)
//=                   integer   iPage    Page to be display
//=
//= return        :    key  handler of the dialog
//=
//= description  :    displays a dialog to the given recipient
//=
//===============================================================================

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

//===============================================================================
//= parameters   :    string    keyID   key of person requesting the menu
//=
//= return        :    none
//=
//= description  :    build menu and display to user
//=
//===============================================================================

DoMenu(key keyID, integer iAuth) {
    string sPrompt = "Pick an option.\n";
    list lMyButtons = PLUGIN_BUTTONS + g_lButtons + g_lDestinations + g_lVolatile_Destinations;

    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}



//===============================================================================
//= parameters   :    iNum: integer parameter of link message (avatar auth level)
//=                   sStr: string parameter of link message (command name)
//=                   kID: key parameter of link message (user key, usually)
//=
//= return        :   TRUE if the command was handled, FALSE otherwise
//=
//= description  :    handles user chat commands (also used as backend for menus)
//=
//===============================================================================

integer UserCommand(integer iNum, string sStr, key kID) {
    if (!(iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)) {
        return FALSE;
    }
    // a validated command from a owner, secowner, groupmember or the wearer has been received
    // can also be used to listen to chat commands
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));
        // So commands can accept a value
    if (sStr == "reset") {
        // it is a request for a reset
        if (iNum == COMMAND_WEARER || iNum == COMMAND_OWNER) {
            //only owner and wearer may reset
            llResetScript();
        }
    }
    
    else if (sStr == PLUGIN_CHAT_COMMAND || sStr == "menu " + SUBMENU_BUTTON) {
        // an authorized user requested the plugin menu by typing the menus chat command
        DoMenu(kID, iNum);
    }
    
    else if (llGetSubString(sStr,0,llStringLength(PLUGIN_CHAT_COMMAND + " save") - 1) == PLUGIN_CHAT_COMMAND + " save") { //grab partial string match to capture destination name
        if (llStringLength(sStr) > llStringLength(PLUGIN_CHAT_COMMAND + " save")) {
            string sAdd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_COMMAND + " save") + 1, -1),STRING_TRIM);
            if (llListFindList(g_lVolatile_Destinations,[sAdd]) >= 0 || llListFindList(g_lDestinations,[sAdd]) >= 0 ) {
                Notify(kID,"This destination name is already taken",FALSE);
            }
            else {
                string slurl = GetSLUrl();
                addDestination(sAdd,slurl,kID);
//                  convertSlurl(sAdd,kID,iNum);
            
            }
            
        }
        else {
            // Notify that they need to give a description of the saved destination ie. <prefix>bookmarks save description
            g_kTBoxIdSave = Dialog(kID,
"Enter a name for the destination below. Submit a blank field to cancel and return.             
You can enter: 
1) A friendly name to save your current location to your favorites
2) A new location or SLurl
                ", [], [], 0, iNum);
        }
    }
    
    else if (llGetSubString(sStr,0,llStringLength(PLUGIN_CHAT_COMMAND + " remove") - 1) == PLUGIN_CHAT_COMMAND + " remove") { //grab partial string match to capture destination name

        if (llStringLength(sStr) > llStringLength(PLUGIN_CHAT_COMMAND + " remove")) {

            string sDel = llStringTrim(llGetSubString(sStr, 16, -1),STRING_TRIM);
        
           if (llListFindList(g_lVolatile_Destinations,[sDel]) < 0) {
                Notify(kID,"Can't find bookmark "+(string)sDel+" to be deleted",FALSE);
            }
            else {
                integer iIndex;
                llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript + sDel, ""); 
                iIndex = llListFindList(g_lVolatile_Destinations,[sDel]);
                g_lVolatile_Destinations = llDeleteSubList(g_lVolatile_Destinations,iIndex,iIndex);
                g_lVolatile_Slurls = llDeleteSubList(g_lVolatile_Slurls,iIndex,iIndex);
                Notify(kID,"Removed destination "+sDel,FALSE);
            }
        }
        else {
            // Notify that they need to give a description of the saved destination ie. <prefix>bookmarks save description
          //  g_kTBoxIdRemove = Dialog(kID, "\n- Enter a name for the destination below.\n- Submit a blank field to cancel and return.", [], [], 0, iNum);
          g_kRemoveMenu = Dialog(kID, "Select a bookmark to be removed...", g_lVolatile_Destinations, [UPMENU], 0, iNum);
        }
    }
    
    else if (llGetSubString(sStr,0,14) == PLUGIN_CHAT_COMMAND + " print") { //grab partial string match to capture destination name

            PrintDestinations(kID);


    }
    else if (llGetSubString(sStr,0,14) == PLUGIN_CHAT_COMMAND + " reset") { //reset destinations

            ResetDestinations(kID);


    }
    else if (llGetSubString(sStr,0,llStringLength(PLUGIN_CHAT_COMMAND)-1) == PLUGIN_CHAT_COMMAND ) { //reset destinations

        string sCmd = llStringTrim(llGetSubString(sStr, llStringLength(PLUGIN_CHAT_COMMAND) + 1, -1),STRING_TRIM);
        if (llListFindList(g_lVolatile_Destinations,[sCmd]) >= 0) {
            integer iIndex = llListFindList(g_lVolatile_Destinations,[sCmd]);
            TeleportTo(llList2String(g_lVolatile_Slurls,iIndex));
        }
        else if (llListFindList(g_lDestinations,[sCmd]) >= 0) {
            integer iIndex = llListFindList(g_lDestinations,[sCmd]);
            TeleportTo(llList2String(g_lDestinations_Slurls,iIndex));
        }
        else {
            Notify(kID,"I didn't understand your command.",FALSE);
        }


    }

    
    return TRUE;
}

addDestination(string sMessage,string sLoc, key kID) {
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + sMessage + "=" + sLoc, "");
    g_lVolatile_Destinations += sMessage;
    g_lVolatile_Slurls += sLoc;
    Notify(kID,"Added destination "+sMessage+" with a location of: "+sLoc,FALSE);
}

string GetSLUrl() 
{ //not using slurls
 //   string globe = "http://maps.secondlife.com/secondlife";
    string region = llGetRegionName();
    vector pos = llGetPos();
    string posx = (string)llRound(pos.x);
    string posy = (string)llRound(pos.y);
    string posz = (string)llRound(pos.z);
    return (region +"(" + posx + "," + posy + "," + posz + ")");
}

string convertSlurl(string sStr,key kAv, integer iAuth) { //convert the slurl http strings to region (xxx,xxx,xxx)
    sStr = llStringTrim(llUnescapeURL(sStr),STRING_TRIM);
    string sIndex = "http:";
    list lPieces =  llParseStringKeepNulls(sStr,["/"],[]);
    integer iHttploc = 0;
    string sStringToKeep;
    integer iHttpInString = llSubStringIndex(llList2String(lPieces,0), sIndex );


    if (iHttpInString > 0) {
        sStringToKeep = llGetSubString( llList2String(lPieces,0),0, iHttpInString - 1);
    }

    if (llGetListLength(lPieces) == 8) {//
        string sRegion = llList2String(lPieces,iHttploc + 4);
        string sLocationx = llList2String(lPieces,iHttploc + 5);
        string sLocationy = llList2String(lPieces,iHttploc + 6);
        string sLocationz = llList2String(lPieces,iHttploc + 7);
        sStr = sStringToKeep + sRegion+"("+sLocationx+","+sLocationy+","+sLocationz+")";
        Debug("Converted slurl, sending for processing..." + sStr);
        return sStr; //successful conversion, send converted string assembly
     }
        
     
    Debug("No slurl detected, sending for processing anyways :" + sStr);
    return sStr; //failed conversion, send raw string assuming there's no Slurls

}


integer isInteger(string input) //for validating location scheme
{
    return ((string)((integer)input) == input);
}



integer validatePlace(string sStr,key kAv, integer iAuth) {
    Debug("validatePlaces working on: "+sStr);
    list lPieces; 
    integer MAX_CHAR_TYPE = 2; //we use +1 due since we're counting with a list split.  We can only accept 1 of each of the following: ()~
    string sAssembledLoc;
    string sRegionName;
    string sFriendlyName;
    
    sStr = llStringTrim(sStr,STRING_TRIM); //clean up whitespace
    lPieces = llParseStringKeepNulls(sStr,["~"],[]); // split location from friendly name
    
    if (llGetListLength(lPieces) == MAX_CHAR_TYPE) {  //We have a tilde, so make sure the friendly name is good
    
        if (llStringLength(llList2String(lPieces,0)) < 1) { return 2;} //make sure friendly name isn't empty

        sFriendlyName = llStringTrim(llList2String(lPieces,0),STRING_TRIM); //assign friendly name

        lPieces = llParseStringKeepNulls(llList2String(lPieces,1),["("],[]); // split location from friendly name
    } 
    else if (llGetListLength(lPieces) > MAX_CHAR_TYPE) return 1; //too many tildes, retreat
    else lPieces = llParseStringKeepNulls(llList2String(lPieces,0),["("],[]); // We don't have a friendly name, so let's ignore that for now and split at 0
    
    
    if (llGetListLength(lPieces) == MAX_CHAR_TYPE) {   //Check to see we don't have extra ('s - this might also mean there's no location coming...
        if (llStringLength(llList2String(lPieces,0)) < 1) { return 4;} //make sure region name isn't empty

        sRegionName = llStringTrim(llList2String(lPieces,0),STRING_TRIM); //trim off whitespace from region name
    }
    else if (llGetListLength(lPieces) > MAX_CHAR_TYPE) {return 3; } //this location looks wrong, retreat
    else  { //there's no location here, kick out new menu

        UserCommand(iAuth, "bookmarks save "+sStr, kAv);
        UserCommand(iAuth, "bookmarks", kAv);
        return 0;
    }


    //we're left with sFriendlyname,sRegionName,["blah","123,123)"] - so lets validate the last list item
    
    sAssembledLoc = llStringTrim("("+llList2String(lPieces,1),STRING_TRIM); //reattach the bracket we lost, clean up whitespace
    
    lPieces = llParseStringKeepNulls(sAssembledLoc,[","],[]); // split location from friendly name
    if (llGetListLength(lPieces) != 3) { return 5; } //Check to see we don't have extra ,'s

    if (llGetSubString(sAssembledLoc,0,0) != "(") { return 6; } //location doesn't start with (
    
    if (llGetSubString(sAssembledLoc,llStringLength(sAssembledLoc)-1,llStringLength(sAssembledLoc)-1) != ")") { return 7; } //location doesn't end with )

    lPieces = llParseStringKeepNulls(llGetSubString(sAssembledLoc,1,llStringLength(sAssembledLoc)-2),[","],[]); // lPieces should be a list of 3 sets of numbers
    
    
    integer i=0; 
    integer x=llGetListLength(lPieces) - 1;
    
    for (i=0;i<=x;++i) { //run through this number list to make sure each character is numeric
        integer y=0;
        integer z=llStringLength(llList2String(lPieces,i)) -1;
        for (y=0;y<=z;++y){

            if (isInteger(llGetSubString(llList2String(lPieces,i),y,y)) != 1 ) return 8; //something left in here isn't an integer
        }
    }
    
    if (sFriendlyName == "") { 
        g_tempLoc = sRegionName+sAssembledLoc; //assign a global for use in response menu
        g_kTBoxIdLocationOnly = Dialog(kAv, 
"\nEnter a name for the destination " + sRegionName + sAssembledLoc + " 
            below.\n- Submit a blank field to cancel and return.
        ", [], [], 0, iAuth);

    }
    else {
        addDestination(sFriendlyName,sRegionName,kAv);
        UserCommand(iAuth, "bookmarks", kAv);

    }
    
    return 0;

}

ReadDestinations() { // On inventory change, re-read our ~destinations notecard and pull from https://raw.githubusercontent.com/OpenCollar/OpenCollarUpdater/main/LSL/~bookmarks
        key kAv;
        webLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollar/OpenCollarUpdater/main/LSL/~bookmarks", [HTTP_METHOD, "GET"], "");

        g_lDestinations = [];
        g_lDestinations_Slurls = [];
        //start re-reading the notecards
        if (llGetInventoryKey(g_sCard) ) { 
            g_kDataID = llGetNotecardLine(g_sCard,0);
        }

}


TeleportTo(string sStr) { //take a string in region (x,y,z) format, and retrieve global coordinates.  The teleport takes place in the data server section
    string sRegion = llStringTrim( llGetSubString( sStr,0,llSubStringIndex( sStr, "(")-1),STRING_TRIM);
    string sCoords = llStringTrim( llGetSubString( sStr,llSubStringIndex( sStr, "(")+1 ,llStringLength(sStr)-2),STRING_TRIM);
    list tokens = llParseString2List (sCoords, [","], []);
    
      // Extract local X, Y and Z
      g_vLocalPos.x = llList2Float (tokens, 0);
      g_vLocalPos.y = llList2Float (tokens, 1);
      g_vLocalPos.z = llList2Float (tokens, 2);

      // Request info about the sim
      if (g_iRLVOn == FALSE) { //If we don't have RLV, we can just send to llMapDestination for a popup
          llMapDestination(sRegion,g_vLocalPos,ZERO_VECTOR);
      }
      else { //We've got RLV, let's use it
        g_kRequestHandle=llRequestSimulatorData(sRegion, DATA_SIM_POS);
      }
    
     
}

PrintDestinations(key kID) { // On inventory change, re-read our ~destinations notecard

        integer i;
        integer length = llGetListLength(g_lDestinations);  
        string sMsg;
        sMsg += "The below can be copied and pasted into the \"~destinations\" notecard. The format should follow: destination name~region name(123,123,123)\n";
        for (i = 0; i < length; i++)
        {
            sMsg += llList2String(g_lDestinations, i) + "~" + llList2String(g_lDestinations_Slurls, i) + "\n";
        }

        length = llGetListLength(g_lVolatile_Destinations);        
        for (i = 0; i < length; i++)
        {
            sMsg += llList2String(g_lVolatile_Destinations, i) + "~" + llList2String(g_lVolatile_Slurls, i) + "\n";
        }
        Notify(kID, sMsg, i);
}

ResetDestinations(key kID) { // This is for testing, and can probably be removed
        integer i;
        integer length = llGetListLength(g_lVolatile_Destinations);        
        for (i = 0; i < length; i++)
        {
           llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript +  llList2String(g_lVolatile_Destinations, i), "");
        }
        g_lVolatile_Slurls = [];
        g_lVolatile_Destinations = [];
        Notify(kID, "Removing personal bookmarks", i);
}


default {
    
   http_response(key id, integer status, list meta, string body){
        if (status == 200) { // be silent on failures.
  //      Debug(body);
            if (id == webLookup){
                list lResponse;
                lResponse = llParseString2List(body,["\n"],[""]);
                integer i = 0;
                integer x = 0;
                string sData;
                list split;
                x = llGetListLength(lResponse) - 1;
                for (i = 0; i <= x; ++i) {

                    sData = llStringTrim(llList2String(lResponse,i),STRING_TRIM);
                    split = llParseString2List(sData, ["~"], []); 
                    g_lDestinations = [ llStringTrim(llList2String(split,0),STRING_TRIM) ] + g_lDestinations;
                    g_lDestinations_Slurls = [ llStringTrim(llList2String(split,1),STRING_TRIM) ] + g_lDestinations_Slurls ;
                }

           //     Debug("Body: " + body);
            }
        }
    }
    
    dataserver(key kID, string sData) 
    {
        
        if (kID == g_kRequestHandle) {

        // Parse the dataserver response (it is a vector cast to a string)
        list tokens = llParseString2List (sData, ["<", ",", ">"], []);
        string pos_str;
        vector global_pos;
     
          // The coordinates given by the dataserver are the ones of the
          // South-West corner of this sim
          // => offset with the specified local coordinates
          global_pos.x = llList2Float (tokens, 0);
          global_pos.y = llList2Float (tokens, 1);
          global_pos.z = llList2Float (tokens, 2);
          global_pos += g_vLocalPos;
     
          // Build the command
          pos_str =      (string)((integer)global_pos.x)
                    +"/"+(string)((integer)global_pos.y)
                    +"/"+(string)((integer)global_pos.z);
          //Debug("Global position : "+(string)pos_str); // Debug purposes 
     
          // Pass command to main
          if (g_iRLVOn) {
              string sRlvCmd = "tpto:"+pos_str+"=force";
              llMessageLinked(LINK_SET, RLV_CMD, sRlvCmd, NULL_KEY);
          }
        }
        

        if (kID == g_kDataID)  //User notecard
        {
            list split;
            if (sData != EOF) {

               if (llGetSubString(sData,0,2) != "") { //Ignore blank lines
                     sData = llStringTrim(sData,STRING_TRIM);
                     split = llParseString2List(sData, ["~"], []);
                     g_lDestinations += [ llStringTrim(llList2String(split,0),STRING_TRIM) ];
                     g_lDestinations_Slurls += [ llStringTrim(llList2String(split,1),STRING_TRIM) ];

                }
                g_iLine++;
                g_kDataID = llGetNotecardLine(g_sCard, g_iLine);
                
            }
        }
        
    } 
     
    changed(integer iChange)
    {
 
        if (iChange & CHANGED_INVENTORY)
        { 
            ReadDestinations();
            
        }
        if (iChange & CHANGED_OWNER) llResetScript();
    }


    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        // store key of wearer
        g_kWearer = llGetOwner();
        // sleep a second to allow all scripts to be initialized

        ReadDestinations(); //Grab our presets
        // send request to main menu and ask other menus if they want to register with us
        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, SUBMENU_BUTTON, "");
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, RLV_STRING, "");
    }

    // Reset the script if wearer changes. By only reseting on owner change we can keep most of our
    // configuration in the script itself as global variables, so that we don't loose anything in case
    // the settings store isn't available, and also keep settings that were not sent to that store
    // in the first place.
    // Cleo: As per Nan this should be a reset on every rez, this has to be handled as needed, but be prepared that the user can reset your script anytime using the OC menus
    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer) {
            // Reset if wearer changed
            llResetScript();
        }
    }

    // listen for linked messages from OC scripts
    link_message(integer iSender, integer iNum, string sStr, key kID) {
   //     Debug((string)iSender + "|" + (string)iNum + "|" + sStr + "|" + (string)kID);
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
            g_lButtons = [] ;
            llMessageLinked(LINK_THIS, MENUNAME_REQUEST, SUBMENU_BUTTON, "");
        }

        
        else if (iNum == RLV_OFF)// rlvoff -> we have to turn the menu off too
        {
            g_iRLVOn=FALSE;
        }
        else if (iNum == RLV_ON)// rlvon -> we have to turn the menu on again
        {
            g_iRLVOn=TRUE;                
        }
        


        else if (iNum == MENUNAME_RESPONSE) {
            // a button is send to be added to a menu
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == SUBMENU_BUTTON) {
                // someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1) { 
                    // if the button isnt in our menu yet, than we add it
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        }

        else if (iNum == LM_SETTING_RESPONSE)
        {
            // response from setting store have been received
            // pares the answer
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            // and check if any values for use are received
            // replace "value1" by your own token
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                list lDestination = [llGetSubString(sToken, llSubStringIndex(sToken, "_")+1, llSubStringIndex(sToken, "="))];
                if (llListFindList(g_lVolatile_Destinations,lDestination) < 0) {
                    g_lVolatile_Destinations += lDestination;
                    g_lVolatile_Slurls += [sValue];
                }
            }
            // or check for specific values from the collar like "auth_owner" (for owners) "auth_secowner" (for secondary owners) etc
            else if (sToken == "auth_owner")
            {
                // work with the received values, in this case pare the vlaue into a strided list with the owners
                list lOwners = llParseString2List(sValue, [","], []);
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (UserCommand(iNum, sStr, kID)) {
            // do nothing more if TRUE
        }
        else if (iNum == DIALOG_RESPONSE) {
            // answer from menu system
            // careful, don't use the variable kID to identify the user, it is the UUID we generated when calling the dialog
            // you have to parse the answer from the dialog system and use the parsed variable kAv

            if (llListFindList([g_kMenuID, g_kTBoxIdSave, g_kRemoveMenu, g_kTBoxIdLocationOnly], [kID]) != -1) {
                //got a menu response meant for us, extract the values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0); // avatar using the menu
                string sMessage = llList2String(lMenuParams, 1); // button label
                integer iPage = (integer)llList2String(lMenuParams, 2); // menu page
                integer iAuth = (integer)llList2String(lMenuParams, 3); // auth level of avatar
                // request to switch to parent menu

                
                
                if (kID == g_kTBoxIdLocationOnly) {
                        list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                        key kAv = (key)llList2String(lMenuParams, 0);
                        string sMessage = llList2String(lMenuParams, 1);
                        integer iPage = (integer)llList2String(lMenuParams, 2);
                        integer iAuth = (integer)llList2String(lMenuParams, 3);      
        
                        list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
                        //got a menu response meant for us. pull out values
                        if(sMessage != "") {         
                            addDestination(sMessage,g_tempLoc,kID);
                        }
                        UserCommand(iAuth, "bookmarks", kAv);
                }
                
                else if (kID == g_kTBoxIdSave) {
                        list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                        key kAv = (key)llList2String(lMenuParams, 0);
                        string sMessage = llList2String(lMenuParams, 1);
                        integer iPage = (integer)llList2String(lMenuParams, 2);
                        integer iAuth = (integer)llList2String(lMenuParams, 3);      
        
                        list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
                        //got a menu response meant for us. pull out values
        //                if(sMessage != "") UserCommand(iAuth, "bookmarks save " + sMessage, kAv);
                        Debug("TBoxIDSave "+sMessage);
                        if(sMessage != "") validatePlace(convertSlurl(sMessage,kAv,iAuth),kAv,iAuth);
        //                UserCommand(iAuth, "bookmarks", kAv);
                }
        
                else if (kID == g_kRemoveMenu) {
                        list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                        key kAv = (key)llList2String(lMenuParams, 0);
                        string sMessage = llList2String(lMenuParams, 1);
                        integer iPage = (integer)llList2String(lMenuParams, 2);
                        integer iAuth = (integer)llList2String(lMenuParams, 3);
                 //       Debug("|"+sMessage+"|");
                        if (sMessage == UPMENU) {
                            UserCommand(iAuth, "bookmarks", kAv);
                            return;
                        }
                        if (sMessage != "") { 
                            list lParams =  llParseStringKeepNulls(sStr, ["|"], []);
                            //got a menu response meant for us. pull out values
                            UserCommand(iAuth, "bookmarks remove " + sMessage, kAv);
                            UserCommand(iAuth, "bookmarks remove", kAv);
                         }
                        else UserCommand(iAuth, "bookmarks", kAv);
                        
                }

                else if (sMessage == UPMENU) {

                    //give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu "+COLLAR_PARENT_MENU, kAv);
                }
                else if (~llListFindList(PLUGIN_BUTTONS, [sMessage])) {
                    //we got a response for something we handle locally
                    if (sMessage == "Save") {

                        UserCommand(iAuth, "bookmarks save", kAv);
 
                    }
                    else if (sMessage == "Remove") {
                        // do What has to be Done
                        UserCommand(iAuth, "bookmarks remove", kAv);
                        // and restart the menu if wanted/needed
                     //   DoMenu(kAv, iAuth);
                    }
                    else if (sMessage == "Print") {
                        // do What has to be Done

                        UserCommand(iAuth, "bookmarks print", kAv);
                        UserCommand(iAuth, "bookmarks", kAv);
                        // and restart the menu if wanted/needed
                     //   DoMenu(kAv, iAuth);
                    }

                }
                else if (~llListFindList(g_lDestinations + g_lVolatile_Destinations, [sMessage])) {

                    UserCommand(iAuth, "bookmarks " + sMessage, kAv);
                }
                else if (~llListFindList(g_lButtons, [sMessage])) {
                    //we got a button which another plugin put into into our menu
                    llMessageLinked(LINK_THIS, iAuth, "menu "+ sMessage, kAv);
                }
            }
        }
    }
}
