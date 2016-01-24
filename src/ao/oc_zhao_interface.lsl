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
//                        ZHAO Interface - 160124.2                         //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2004 - 2016 Francis Chung, Dzonatas Sol, Fennec Wind,     //
//  Ziggy Puff, Nandana Singh, Wendy Starfall, Alex Carpenter,              //
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
//           github.com/OpenCollar/opencollar/tree/master/src/ao            //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// ZHAO-II-interface - Ziggy Puff, 06/07

////////////////////////////////////////////////////////////////////////
// Interface script - handles all the UI work, sends link
// messages to the ZHAO-II 'engine' script
//
// Interface definition: The following link_message commands are
// handled by the core script. All of these are sent in the string
// field. All other fields are ignored
//
// ZHAO_RESET                          Reset script
// ZHAO_LOAD|<notecardName>            Load specified notecard
// ZHAO_NEXTSTAND                      Switch to next stand
// ZHAO_STANDTIME|<time>               Time between stands. Specified
//                                     in seconds, expects an integer.
//                                     0 turns it off
// ZHAO_AOON                           AO On
// ZHAO_AOOFF                          AO Off
// ZHAO_SITON                          Sit On
// ZHAO_SITOFF                         Sit Off
// ZHAO_RANDOMSTANDS                   Stands cycle randomly
// ZHAO_SEQUENTIALSTANDS               Stands cycle sequentially
// ZHAO_SETTINGS                       Prints status
// ZHAO_SITS                           Select a sit
// ZHAO_GROUNDSITS                     Select a ground sit
// ZHAO_WALKS                          Select a walk
//
//
// ZHAO_SITANYWHERE_ON                 Sit Anywhere mod On 
// ZHAO_SITANYWHERE_OFF                Sit Anywhere mod Off 
//
// ZHAO_TYPE_ON                        Typing AO On 
// ZHAO_TYPE_OFF                       Typing AO Off 


// Added for OCCuffs:
// ZHAO_PAUSE                           Stops the AO temporary, AO gets reactivated on next rez if needed
// ZHAO_UNPAUSE                         Restart the AO if it was paused
// End of add OCCuffs




// So, to send a command to the ZHAO-II engine, send a linked message:
//
//   llMessageLinked(LINK_SET, 0, "ZHAO_AOON", NULL_KEY);
//
////////////////////////////////////////////////////////////////////////

// Ziggy, 07/16/07 - Single script to handle touches, position changes, etc., since idle scripts take up
//
// Ziggy, 06/07:
//          Single script to handle touches, position changes, etc., since idle scripts take up
//          scheduler time
//          Tokenize notecard reader, to simplify notecard setup
//          Remove scripted texture changes, to simplify customization by animation sellers

// Fennec Wind, January 18th, 2007:
//          Changed Walk/Sit/Ground Sit dialogs to show animation name (or partial name if too long)
//          and only show buttons for non-blank entries.
//          Fixed minor bug in the state_entry, ground sits were not being initialized.
//

// Dzonatas Sol, 09/06: Fixed forward walk override (same as previous backward walk fix).


// Based on Francis Chung's Franimation Overrider v1.8

// CONSTANTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// integer disabled = FALSE;//used to prevent manually turning AO on when collar has turned it off
// key disabler;//the key of th eobject that turned us off.  will be needed for a workaround later

string fancyVersion = "⁶⋅⁰⋅⁰ ⁽ᴹⱽᴾ⁾";
float g_fBuildVersion = 160124.3;
// How long before flipping stand animations
integer standTimeDefault = 30;

// Overall AO state
integer zhaoOn = TRUE;

vector onColor = <1.0, 1.0, 1.0>;
vector offColor = <0.5, 0.5, 0.5>;

//string AO_LOCKED = "773b306e-f344-ef87-b911-4d961bc8a38b"; //AO locked texture
//string AO_UNLOCKED = "7d57bca0-90ee-466a-cead-602d85754fb1"; //standard AO menu texture

// Interface script now keeps track of these states. The defaults
// match what the core script starts out with
integer sitOverride = TRUE;
integer sitAnywhere = FALSE;
integer StandAO = TRUE; // store state of standing ao
integer randomStands = FALSE;
integer typingOverrideOn = TRUE;            // Whether we're overriding typing or not
integer wasDetached;

//Left here for backwards compatiblity... to be removed sooner than later
integer collarchannel = -782690;

key g_kWearer;

integer isLocked = FALSE;
string UNLOCK = " UNLOCK";
string LOCK = " LOCK";
string AOOFF = "AO Off";
string AOON = "AO On";
string TYPINGOFF = "TypingOFF";
string TYPINGON = "TypingON";

string COLLAR_OFF = "NoCollar";
string COLLAR_ON = "CollarInt";
integer OPTIONS = 69; // Hud Options LM

//Added for the collar auth system:
integer COMMAND_NOAUTH = 0;
integer COMMAND_AUTH = 42; //used to send authenticated commands to be executed in the core script
integer COMMAND_TO_COLLAR = 498; // -- Added to send commands TO the collar.
integer COMMAND_COLLAR = 499; //added for collar or cuff commands to put ao to pause or standOff and SAFEWORD
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_UPDATE = 10001;

key lockerID;

// -- Added for Menu integration
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SUBMENU = 3002;

string UPMENU = "BACK";
list g_lMenuIDs;//three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;
// Use these to keep track of your current menu
// Use any variable name you desire
string MENU = "DoMenu";
string QUICKMENU = "FirstMenu";
integer g_iUpdateAvailable;
key g_kWebLookup;
key g_kCollarID;

// CODE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Dialog(key kRcpt, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, string sMenuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRcpt + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    list lNewstride = [kRcpt, kID, sMenuType];
    integer index = llListFindList(g_lMenuIDs, [kRcpt]);
    if (index == -1)
        g_lMenuIDs += lNewstride;
    else //this person is already in the dialog list.  replace their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewstride, index, index - 1 + g_iMenuStride);
}

string Checkbox(integer iValue){
    if (iValue) return "☒";
    return "☐";
}

DoMenu(key id, integer page) {
    list lButtons;
    string prompt;
    if(llGetAttached()) { // -- If we're attached... ANYWHERE, display the menu
        prompt = "\n[http://www.opencollar.at/ao.html OpenCollar AO]\t"+fancyVersion;
        if (g_iUpdateAvailable) prompt += "\n\nUPDATE AVAILABLE: A new patch has been released.\nPlease install at your earliest convenience. Thanks!\n\nwww.opencollar.at/updates";
        //new for locking feature 
        if (isLocked) lButtons += [UNLOCK];
        else lButtons += [LOCK];
        lButtons += ["Collar Menu","Load",
                    "Sits","Ground Sits","Walks",
                    "Sits "+Checkbox(sitOverride),"Typing "+Checkbox(typingOverrideOn),"Stand Time",
                    "Next Stand","Shuffle "+Checkbox(randomStands),"HUD Style"];
    } else { // Else, if we're not attached, we must be updating and therefore only display the update menu
        lButtons = ["Load"];
        prompt = "\nCustomization:\n\n1. Take a notecard set from the AO contents\n2. List your animations in the corresponding lines\n3. Give the notecard a new name\n4. Drop the notecard into the AO contents\n5. Also drop the animations you listed inside\n6. Click the Load button to select your new set\n7. Error? Check for typos or missing anims\n\nNote: Moving animations in bulk could cause some to go missing in the ether. Don't drop more than half a dozen at once, wait two seconds, then drop the next batch.\n\nwww.opencollar.at/ao";
    }
    Dialog(id, prompt, lButtons, [], page, MENU);
}

TurnOn() {
    zhaoOn = TRUE;
    llMessageLinked(LINK_SET, COMMAND_AUTH, "ZHAO_AOON", "");
    llMessageLinked(LINK_SET, OPTIONS, "ZHAO_AOON", "");
}

TurnOff() {
    if (sitAnywhere) ToggleSitAnywhere();
    zhaoOn = FALSE;
    llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_AOOFF", "");
    llMessageLinked(LINK_SET, OPTIONS, "ZHAO_AOOFF", "");
}

ToggleSitAnywhere() {
    if (!StandAO) {
        llOwnerSay("SitAnywhere is not possible while you are in a collar pose.");
        return; // only allow changed if StandAO is enabled
    }
    if (zhaoOn) {
        if (sitAnywhere) {
            llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITANYWHERE_OFF", NULL_KEY);
            llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_SITANYWHERE_OFF", NULL_KEY);
        } else {
            llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITANYWHERE_ON", NULL_KEY);
            llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_SITANYWHERE_ON", NULL_KEY);
        }
        sitAnywhere = !sitAnywhere;
    }
}

Notify(key kID, string sMsg, integer iNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        llRegionSayTo(kID,0,sMsg);
        if (iNotifyWearer) llOwnerSay(sMsg);
    }    
}

integer isAttachedToHUD() {
    if (llGetAttached() > 30)
        return TRUE;
    return FALSE;
}

// STATE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
debug(string str)
{
    llOwnerSay(llGetScriptName() + "-Debug: " + str);
}
*/

default {
    state_entry() {
        integer i;
        g_kWearer = llGetOwner();
        llListen(collarchannel, "", NULL_KEY, "");
        // DoPosition();
        // Sleep a little to let other script reset (in case this is a reset)
        llSleep(2.0);
        // We start out as AO ON
        TurnOn();
        //sit anywhere OFF by default
        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITANYWHERE_OFF", NULL_KEY);
        sitAnywhere = FALSE;
    }

    on_rez( integer iStart ) {
        if (g_kWearer != llGetOwner()) llResetScript();
        if (isLocked) llOwnerSay("@detach=n");
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~ao", [HTTP_METHOD, "GET"],"");
    }

    link_message(integer sender, integer num, string str, key id) {
        //debug("lnkMsg: " + str + " auth=" + (string)num + "id= " + (string)id);
        if (num >= COMMAND_OWNER && num <= COMMAND_WEARER) {
            if (isLocked && num == COMMAND_WEARER) {
                Notify(id, "You cannot change the AO while it is locked. You could use your safeword which will unlock the AO. Please ensure you have your collar on when doing this.", FALSE);
                return;
            }
            else if (str == "ZHAO_AOON")
                //make sure button is bright, on is TRUE
                TurnOn();
            else if (str == "ZHAO_AOOFF")
                TurnOff();
            else if (str == "ZHAO_MENU")
                //SetListener(id);
//llSay(0,"Missed this one, I bet that's it!");
                DoMenu(id, 0);
            else if (str == "OCAO_MENU")
                DoMenu(id, 0);
            else if (str == "ZHAO_LOCK") {
                if(num >= COMMAND_OWNER && num <= COMMAND_WEARER) {
                    isLocked = TRUE;
                    llOwnerSay("@detach=n");
                    lockerID = id;
                    Notify(id, "The AO has been locked.", TRUE);
                }
                else Notify(id, "Only the Owner can lock the AO.", FALSE);
            } else if (str == "ZHAO_UNLOCK") {
                if (num == COMMAND_OWNER) {
                    isLocked = FALSE;
                    llOwnerSay("@detach=y");
                    Notify(id, "The AO has been unlocked.", TRUE);
                } else Notify(id, "Only the Owner can unlock the AO.", FALSE);
            }
        } else if (num == COMMAND_COLLAR && str == "safeword") {
            if (isLocked) {
                isLocked = FALSE;
                llOwnerSay("@detach=y");
                llMessageLinked(LINK_THIS, OPTIONS, UNLOCK, id);
                Notify(lockerID, "The AO has been unlocked due to safeword usage.", TRUE);
            }
        } else if (num == DIALOG_RESPONSE) {
            integer menuindex = llListFindList(g_lMenuIDs, [id]);
            if (menuindex != -1) {
                //got a menu response meant for us.  pull out values
                list menuparams = llParseString2List(str, ["|"], []);
                key _id = (key)llList2String(menuparams, 0);          
                string _message = llList2String(menuparams, 1);                                         
                integer page = (integer)llList2String(menuparams, 2);
                string menutype = llList2String(g_lMenuIDs, menuindex + 1);
                //remove stride from lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, menuindex - 1, menuindex - 2 + g_iMenuStride);             
               // llSay(0,"got DIALOG_RESPONSE:"+str+ ".From secondlife:///app/agent/"+(string)_id +"/about");
                if (menutype == MENU) {
                    if (_message == AOON) {
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_AOON", _id);
                        zhaoOn=TRUE;
                        DoMenu(_id,page);
                    } else if (_message == AOOFF) {
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_AOOFF", _id);
                        zhaoOn=FALSE;
                        DoMenu(_id,page);
                    } else if ( _message == "Settings" ) {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SETTINGS", _id);
                        DoMenu(_id,page);
                    } else if ( _message == "Sit Any "+Checkbox(1) || _message == "Sit Any "+Checkbox(0) ) {
                        ToggleSitAnywhere();
                        DoMenu(_id,page);
                    } else if ( _message == "Sits "+Checkbox(1) ) {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITOFF", _id);
                        sitOverride = FALSE;
                        DoMenu(_id,page);
                    } else if ( _message == "Sits "+Checkbox(0) ) {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITON", _id);
                        sitOverride = TRUE;
                        DoMenu(_id,page);
                    } else if ( _message == "Typing "+Checkbox(1) ) {
                        llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_TYPEAO_OFF", NULL_KEY);
                        typingOverrideOn=FALSE;
                        DoMenu(_id,page);
                    } else if ( _message == "Typing "+Checkbox(0) ) {
                        llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_TYPEAO_ON", NULL_KEY);
                        typingOverrideOn = TRUE;
                        DoMenu(_id,page);
                    } else if ( _message == "Shuffle " +Checkbox(1) ) {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SEQUENTIALSTANDS", _id);
                        randomStands = FALSE;
                        DoMenu(_id,page);
                    } else if ( _message == "Shuffle " +Checkbox(0) ) {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_RANDOMSTANDS", _id);
                        randomStands = TRUE;
                        DoMenu(_id,page);
                    } else if ( _message == "Next Stand" )
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_NEXTSTAND", _id);
                    else if ( _message == "Sits" ) 
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITS", _id);
                    else if ( _message == "Walks" ) 
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_WALKS", _id);
                    else if ( _message == "Ground Sits" ) 
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_GROUNDSITS", _id);
                    else if ( _message == "Load" ) {
                        integer n = llGetInventoryNumber( INVENTORY_NOTECARD );
                        integer i;
                        list animSets = [];
                        // Build a list of notecard names and present them in a dialog box
                        for ( i = 0; i < n; i++ ) {
                            string notecardName = llGetInventoryName( INVENTORY_NOTECARD, i );
                            if (notecardName != ".license")
                            animSets += [ notecardName ];
                        }
                        string text = "\nSelect a set to load:";
                        Dialog(_id, text, animSets, [], 0, "SetsMenu");
                    } else if ( _message == "Stand Time" ) {
                        string text = "\nSelect stand cycle time (in seconds). \n\nSelect '0' to turn off stand auto-cycling.";
                        Dialog(_id, text, ["0", "5", "10", "20", "30", "40", "60", "90", "120", "180", "240"], [UPMENU], 0, "StandTimesMenu");
    
                    } else if ( _message == LOCK) {
                        // -- Tell the options menu if we're locked or unlocked
                        llMessageLinked(LINK_THIS, OPTIONS, _message, _id); 
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_LOCK", _id);
                        isLocked=TRUE;
                        DoMenu(_id,page);
                    } else if ( _message == UNLOCK) {
                        // -- Tell the options menu if we're locked or unlocked
                        llMessageLinked(LINK_THIS, OPTIONS, _message, _id); 
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_UNLOCK", _id);
                        isLocked=FALSE;
                        DoMenu(_id,page);
                    } else if (_message == "Collar Menu")
                        llMessageLinked(LINK_THIS, COMMAND_TO_COLLAR, "animations", _id);
                    else if (_message == "HUD Style") {
                        if (_id == g_kWearer)
                            llMessageLinked(LINK_THIS, SUBMENU, "Options", _id);
                        else {
                            Notify(_id,"Only the HUD Wearer can access this menu.",FALSE);
                            DoMenu(_id,page);
                        }
                    }
                } else if (menutype == "SetsMenu") {
                    if (_message == UPMENU)
                        DoMenu(_id,0);
                    llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_LOAD|" + _message, _id);
                    DoMenu(_id,page);
                } else if (menutype == "StandTimesMenu") {
                    if (_message == UPMENU) DoMenu(_id,0);
                    else llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_STANDTIME|" + _message, _id);
                    //DoMenu(_id,page);
                }
            }
        } else if(num == DIALOG_TIMEOUT) {
            integer menuindex = llListFindList(g_lMenuIDs, [id]);
            if (menuindex != -1)
               g_lMenuIDs = llDeleteSubList(g_lMenuIDs,menuindex-1,menuindex + g_iMenuStride - 2);
        }    
    }
    
    touch_start( integer _num ) {
        //ignore touches when attached not at the hud and touches by others but the wearer
        if( (llGetAttached() ) && ( llDetectedKey(0) == g_kWearer) ) {
            if (isLocked) {
                llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "OCAO_MENU", g_kWearer);
                return;
            }
            string button = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            string message = "";
            if (button == "Menu") 
                message = "OCAO_MENU";
            else if (button == "SitAny") {
                if (!isLocked)
                    ToggleSitAnywhere();
            } else if (llSubStringIndex(llToLower(button),"ao")>=0) {   // The Hide Button
                llMessageLinked(LINK_SET, COMMAND_OWNER,"hide",NULL_KEY);
                llSleep(1); 
            } else if (zhaoOn) 
                message = "ZHAO_AOOFF";
            else
                message = "ZHAO_AOON";
            if (isLocked) {
                if (message == "")
                    message == "SitAny";
                llMessageLinked(LINK_THIS, COMMAND_NOAUTH, message, g_kWearer);
            } else if (message != "")
                llMessageLinked(LINK_THIS, COMMAND_OWNER, message, g_kWearer);
        } else if (!llGetAttached() && llDetectedKey(0) == g_kWearer)
            llMessageLinked(LINK_THIS, COMMAND_OWNER, "ZHAO_MENU", g_kWearer);
    }

    listen( integer _channel, string _name, key _id, string _message) {
        if (_channel == collarchannel) {
            //only accept commands from owner's objects,
            //or from the object that disabled us
            //this is needed because the collar sends a ZHAO_STANDON message when it detaches
            //but because it's no longer rezzed, llgetownerkey doesn't work
            if (llGetOwnerKey(_id) == g_kWearer || _id == g_kCollarID) {
                list params = llParseString2List(_message, ["|"], []);
                string command = llList2String(params, 0);
                string userID = llList2String(params, 1);
                g_kCollarID = _id; // store collar id
                if (_message == "ZHAO_PAUSE")
                    llMessageLinked(LINK_THIS, COMMAND_COLLAR, _message, NULL_KEY);
                else if (_message == "ZHAO_UNPAUSE")
                    llMessageLinked(LINK_THIS, COMMAND_COLLAR, _message, NULL_KEY);
                else if (_message == "ZHAO_STANDOFF") {
                    if (sitAnywhere) ToggleSitAnywhere(); // SitAnyWhere is On, so disable it first
                    StandAO=FALSE; // and store that we are in off mode
                    llMessageLinked(LINK_SET, COMMAND_COLLAR, _message, NULL_KEY);
                } else if (_message == "ZHAO_STANDON") {
                    StandAO=TRUE; // set state of Stand AO to TRUE
                    llMessageLinked(LINK_THIS, COMMAND_COLLAR, _message, NULL_KEY);
                } else if (_message == "ZHAO_AOSHOW") {
                    if(!isAttachedToHUD())
                        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                } else if (command == "ZHAO_MENU")
                    llMessageLinked(LINK_THIS, COMMAND_OWNER, "ZHAO_MENU", _id);
                else if (_message == "ZHAO_AOHIDE") {
                    if(!isAttachedToHUD())
                        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                    else
                        llOwnerSay("You can only hide the AO when it is not attached to the HUD.");
                } else
                    llMessageLinked(LINK_SET, COMMAND_OWNER, command, (key)userID);
            }
        }
    }
    http_response(key kRequestID, integer iStatus, list lMeta, string sBody) {
        if (kRequestID == g_kWebLookup && iStatus == 200)  {
            if ((float)sBody > g_fBuildVersion) g_iUpdateAvailable = TRUE;
            else g_iUpdateAvailable = FALSE;
        }
    }
    attach( key _k ) {
        if ( _k != NULL_KEY ) {
            if( isAttachedToHUD() )
                llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
            else
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
            if (isLocked && wasDetached) {
                wasDetached = FALSE; // -- Already notified, set to false. If it happens again it will be set once more when detached.
                Notify(lockerID, llKey2Name(g_kWearer) + " has attached the AO again after it was detached while locked.", TRUE);
            }
        } else if (isLocked) {
            wasDetached = TRUE;
            Notify(lockerID, llKey2Name(g_kWearer) + " has detached the AO while it was locked.", TRUE);
        }
    }
}
