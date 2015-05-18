// Submissive AO 3.960
// Nandana Singh mod for OpenCollar compatibility.

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

// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA.

// CONSTANTS
//////////////////////////////////////////////////////////////////////////////////////////////////////////

// integer disabled = FALSE;//used to prevent manually turning AO on when collar has turned it off
// key disabler;//the key of th eobject that turned us off.  will be needed for a workaround later

// Help notecard
string helpNotecard = "OpenCollar AO Guide";
string license = "OpenCollar AO License";

// How long before flipping stand animations
integer standTimeDefault = 30;

// Listen channel for pop-up menu...
// should be different from channel used by ZHAO engine (-91234)
integer listenChannel = -91235;

integer listenHandle;                          // Listen handlers - only used for pop-up menu, then turned off
integer listenState = 0;                       // What pop-up menu we're handling now

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
integer oldCollarHandle;

key Owner = NULL_KEY;

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
integer COLLAR_INT_REQ = 610;
integer COLLAR_INT_REP = 611;
integer COMMAND_UPDATE = 10001;

//need to detect RLV for locking...
integer rlvChannel = 1904204;
integer rlvHandle;
integer rlvDetected;
key lockerID;

// -- Added for Menu integration
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SUBMENU = 3002;

string MORE = "►";
string PREV = "◄";
string UPMENU = "BACK";
list menuids;//three strided list of avkey, dialogid, and menuname
integer menustride = 3;
// Use these to keep track of your current menu
// Use any variable name you desire
string MENU = "DoMenu";
string QUICKMENU = "FirstMenu";


// CODE
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page, string menu)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page + "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);

    list newstride = [rcpt, id, menu];
    
    integer index = llListFindList(menuids, [id]);
    if (index == -1)
    {
        menuids += newstride;
    }
    else
    { //this person is already in the dialog list.  replace their entry
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    } 
}


// Initialize listeners, and reset some status variables
Initialize() {
    Owner = llGetOwner();
    //check for rlv
    rlvHandle = llListen(rlvChannel, "", Owner, "");
    llOwnerSay("@version=" + (string)rlvChannel);
    llSetTimerEvent(10.0);
    SetListener(Owner);
}

DoFirstMenu(key id, integer page)
{
//llSay(0,"Making quickmenu for: "+(string)id);
    list utility = [];
    list buttons = ["AO Menu","Collar Menu","Couples","Pose","Sits","Ground Sits","Reset","HUD Style","Help"];
    
    Dialog(id, "\nSubmissive AO Quickmenu", buttons, utility, page, QUICKMENU);
//llSay(0,"Done Making quickmenu for: "+(string)id); 
    
}

string Checkbox(integer iValue){
    if (iValue) return "☒";
    return "☐";
}

DoMenu(key id, integer page)
{
    list mainMenu;
    string prompt;
//llSay(0,"Making menu for: "+(string)id);
    if(llGetAttached())
    { // -- If we're attached... ANYWHERE, display the menu
        prompt = "Please select an option:\n";
        //new for locking feature 
        if (isLocked) mainMenu += [UNLOCK];
        else mainMenu += [LOCK];
            
        if (zhaoOn) mainMenu += [AOOFF];
        else mainMenu += [AOON];

        mainMenu += "Load";
        //mainMenu += ["Sits "+Checkbox(sitOverride),"Ground Sits","Walks"];
        mainMenu += ["Sits","Ground Sits","Walks"];
        //mainMenu += ["Sit Any "+Checkbox(sitAnywhere),"Typing "+Checkbox(typingOverrideOn),"Stand Time"];
        mainMenu += ["Sits "+Checkbox(sitOverride),"Typing "+Checkbox(typingOverrideOn),"Stand Time"];
        mainMenu += ["Next Stand","Shuffle "+Checkbox(randomStands)];
        if (id == Owner) mainMenu += ["MORE"];
        else mainMenu += ["Cancel"];
    }
    else
    { // Else, if we're not attached, we must be updating and therefore only display the update menu
        mainMenu = ["Load"];
        prompt = "\nCustomize me!\n\n1. Take a notecard set from the AO contents\n2. List your animations in the corresponding lines\n3. Give the notecard a new name\n4. Drop the notecard into the AO contents\n5. Also drop the animations you listed inside\n6. Click the Load button to select your new set\n7. Error? Check for typos or missing anims\n\nNote: Moving animations in bulk could cause hiccups for the SL asset server. Don't drop more than half a dozen at once, wait two seconds, then drop the next batch and you will be fine.";
    }
        
    listenState = 0;
    
    Dialog(id, prompt, mainMenu, [], page, MENU);
}

TurnOn()
{
    zhaoOn = TRUE;
    llMessageLinked(LINK_SET, COMMAND_AUTH, "ZHAO_AOON", "");
    llMessageLinked(LINK_SET, OPTIONS, "ZHAO_AOON", "");
    //llSetLinkColor(2, onColor, ALL_SIDES);
}

TurnOff()
{
    // llSetLinkColor(2, offColor, ALL_SIDES); // needed?
    if (sitAnywhere)
    {
        ToggleSitAnywhere();
    }
    zhaoOn = FALSE;
    //llSetLinkColor(2, offColor, ALL_SIDES);
    llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_AOOFF", "");
    llMessageLinked(LINK_SET, OPTIONS, "ZHAO_AOOFF", "");
}

ToggleSitAnywhere()
{
    if (!StandAO)
    {
        llOwnerSay("SitAnywhere is not possible while you are in a collar pose.");
        return; // only allow changed if StandAO is enabled
    }
    if (zhaoOn)
    {
        if (sitAnywhere == TRUE) 
        {
            //llSetLinkColor(3, offColor, ALL_SIDES);
            llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITANYWHERE_OFF", NULL_KEY);
            llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_SITANYWHERE_OFF", NULL_KEY);
        } 
        else 
        {
            //llSetLinkColor(3, onColor, ALL_SIDES);
            llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITANYWHERE_ON", NULL_KEY);
            llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_SITANYWHERE_ON", NULL_KEY);
        }
        sitAnywhere = !sitAnywhere;
    }
}

SetListener(key speaker)
{
    llListen(collarchannel, "", NULL_KEY, "");  //fixme:  should we be trapping the handle for this listener so we can remove it?
}

Notify(key id, string msg, integer alsoNotifyWearer) {
    if (id == Owner) {
        llOwnerSay(msg);
    } else {
        llInstantMessage(id,msg);
        if (alsoNotifyWearer) {
            llOwnerSay(msg);
        }
    }    
}

integer isAttachedToHUD()
{
    if (llGetAttached() > 30)
    {
        return TRUE;
    }
    else
    {
        return FALSE;
    }
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
        Initialize();
        // DoPosition();

        // Sleep a little to let other script reset (in case this is a reset)
        llSleep(2.0);

        // We start out as AO ON
        TurnOn();
        //sit anywhere OFF by default
        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITANYWHERE_OFF", NULL_KEY);
        sitAnywhere = FALSE;
    }

    on_rez( integer _code ) {
        Initialize();
        if (isLocked)
            {
                if (rlvDetected)
                {
                    llOwnerSay("@detach=n");
                }
            }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        //debug("lnkMsg: " + str + " auth=" + (string)num + "id= " + (string)id);
        if (num >= COMMAND_OWNER && num <= COMMAND_WEARER)
        {
            if (isLocked && num == COMMAND_WEARER)
            {
                Notify(id, "You cannot change the AO while it is locked. You could use your safeword which will unlock the AO. Please ensure you have your collar on when doing this.", FALSE);
                return;
            }
            else if (str == "ZHAO_AOON")
            {
                //make sure button is bright, on is TRUE
                TurnOn();
            }
            else if (str == "ZHAO_AOOFF")
            {
                TurnOff();
            }
            else if (str == "ZHAO_MENU")
            {
                //SetListener(id);
//llSay(0,"Missed this one, I bet that's it!");
                DoMenu(id, 0);
            }
            else if (str == "OCAO_MENU")
            {
                DoFirstMenu(id, 0);
            }
            else if (str == "ZHAO_LOCK")
            {
                if(num >= COMMAND_OWNER && num <= COMMAND_WEARER)
                {
                    isLocked = TRUE;
                    if (rlvDetected)
                    {
                        llOwnerSay("@detach=n");
                    }
                    lockerID = id;
                    Notify(id, "The AO has been locked.", TRUE);
                    //llSetLinkTexture(2, AO_LOCKED, ALL_SIDES);
                }
                else
                {
                    Notify(id, "Only the Owner can lock the AO.", FALSE);
                }
            }
            else if (str == "ZHAO_UNLOCK")
            {
                if (num == COMMAND_OWNER)
                {
                    isLocked = FALSE;
                    if (rlvDetected)
                    {
                        llOwnerSay("@detach=y");
                    }
                    Notify(id, "The AO has been unlocked.", TRUE);
                    //llSetLinkTexture(2, AO_UNLOCKED, ALL_SIDES);
                }
                else
                {
                    Notify(id, "Only the Owner can unlock the AO.", FALSE);
                }
            }
        }
        else if (num == COLLAR_INT_REP)
        {
            if (str == "CollarOn")
            {
                llOwnerSay("Collar found full Collar Integration on.");
            }
            else 
            {
                llOwnerSay("Compatible collar not found.  You may experience problems with this AO.");
            }
        }
        else if (num == COMMAND_COLLAR && str == "safeword")
        {
            if (isLocked)
            {
                isLocked = FALSE;
                if (rlvDetected)
                {
                    llOwnerSay("@detach=y");
                }
                llMessageLinked(LINK_THIS, OPTIONS, UNLOCK, id);
                Notify(lockerID, "The AO has been unlocked due to safeword usage.", TRUE);
                //llSetLinkTexture(2, AO_UNLOCKED, ALL_SIDES);
                
            }
        }
        else if (num == DIALOG_RESPONSE)
        {

            integer menuindex = llListFindList(menuids, [id]);
            if (menuindex != -1)
            {
                //got a menu response meant for us.  pull out values
                list menuparams = llParseString2List(str, ["|"], []);
                key _id = (key)llList2String(menuparams, 0);          
                string _message = llList2String(menuparams, 1);                                         
                integer page = (integer)llList2String(menuparams, 2);
                string menutype = llList2String(menuids, menuindex + 1);
                //remove stride from menuids
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                menuids = llDeleteSubList(menuids, menuindex - 1, menuindex - 2 + menustride);             
               // llSay(0,"got DIALOG_RESPONSE:"+str+ ".From secondlife:///app/agent/"+(string)_id +"/about");
                if (menutype == MENU)
                {
                    if (_message == AOON)
                    {
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_AOON", _id);
                        zhaoOn=TRUE;
                        DoMenu(_id,page);
                    }
                    else if (_message == AOOFF)
                    {
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_AOOFF", _id);
                        zhaoOn=FALSE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Settings" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SETTINGS", _id);
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Sit Any "+Checkbox(1) || _message == "Sit Any "+Checkbox(0) ) 
                    {
                        ToggleSitAnywhere();
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Sits "+Checkbox(1) ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITOFF", _id);
                        sitOverride = FALSE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Sits "+Checkbox(0) ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITON", _id);
                        sitOverride = TRUE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Typing "+Checkbox(1) ) 
                    {
                        llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_TYPEAO_OFF", NULL_KEY);
                        typingOverrideOn=FALSE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Typing "+Checkbox(0) ) 
                    {
                        llMessageLinked(LINK_THIS, OPTIONS, "ZHAO_TYPEAO_ON", NULL_KEY);
                        typingOverrideOn = TRUE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Shuffle " +Checkbox(1) )  
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SEQUENTIALSTANDS", _id);
                        randomStands = FALSE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Shuffle " +Checkbox(0) )  
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_RANDOMSTANDS", _id);
                        randomStands = TRUE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == "Next Stand" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_NEXTSTAND", _id);
                        //DoMenu(_id,page);
                    }
                    else if ( _message == "Sits" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITS", _id);
                    }
                    else if ( _message == "Walks" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_WALKS", _id);
                    }
                    else if ( _message == "Ground Sits" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_GROUNDSITS", _id);
                    }
                    else if ( _message == "Load" ) 
                    {
                        integer n = llGetInventoryNumber( INVENTORY_NOTECARD );
                        integer i;
                        list animSets = [];
                        // Build a list of notecard names and present them in a dialog box
                        for ( i = 0; i < n; i++ ) {
                            string notecardName = llGetInventoryName( INVENTORY_NOTECARD, i );
                            if ( notecardName != helpNotecard && notecardName != license)
                            animSets += [ notecardName ];
                        }
                        //llListenControl(listenHandle, TRUE);
                        string text = "Select the notecard to load:";
                        
                        Dialog(_id, text, animSets, [], 0, "SetsMenu");
                        listenState = 1;
                    }
                    else if ( _message == "Stand Time" ) 
                    {
                        // Pick stand times
                        listenState = 2;
                        string text = "Select stand cycle time (in seconds). \n\nSelect '0' to turn off stand auto-cycling.";
                        
                        Dialog(_id, text, ["0", "5", "10", "15", "20", "30", "40", "60", "90", "120", "180", "240"], [UPMENU], 0, "StandTimesMenu");
    
                    }
                    else if ( _message == LOCK)
                    {
                        // -- Tell the options menu if we're locked or unlocked
                        llMessageLinked(LINK_THIS, OPTIONS, _message, _id); 
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_LOCK", _id);
                        isLocked=TRUE;
                        DoMenu(_id,page);
                    }
                    else if ( _message == UNLOCK)
                    {
                        // -- Tell the options menu if we're locked or unlocked
                        llMessageLinked(LINK_THIS, OPTIONS, _message, _id); 
                        llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "ZHAO_UNLOCK", _id);
                        isLocked=FALSE;
                        DoMenu(_id,page);
                    }
                    else if (_message == ">")
                    {
                        DoMenu(_id,++page);
                    }
                    else if (_message == "<")
                    {
                        DoMenu(_id,--page);
                    }
                    else if (_message == "MORE")
                    {
                        if (_id==Owner){     //wearer's menu, go to quick menu
                            llMessageLinked(LINK_THIS, COMMAND_OWNER, "OCAO_MENU", _id);
                        }// else {                    //fixme:  must be owner's menu, send back to collar anim menu
                           // llMessageLinked(LINK_THIS, COMMAND_TO_COLLAR, "animations", _id);
                            //llMessageLinked(LINK_THIS, COMMAND_OWNER, "OCAO_MENU", _id);
                        //}
                    }
                }
                else if (menutype == "SetsMenu")
                {
                    if (_message == UPMENU)
                    {
                        DoMenu(_id,0);
                    }
                    llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_LOAD|" + _message, _id);
                    DoMenu(_id,page);
                }
                else if (menutype == "StandTimesMenu")
                {
                    if (_message == UPMENU) DoMenu(_id,0);
                    else llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_STANDTIME|" + _message, _id);
                    //DoMenu(_id,page);
                }
                else if (menutype == QUICKMENU)
                {
                    if (_message == "AO Menu")
                    {
                        llMessageLinked(LINK_THIS, COMMAND_OWNER, "ZHAO_MENU", Owner);
                    }
                    else if (_message == "Collar Menu")
                    {
                        llMessageLinked(LINK_THIS, COMMAND_TO_COLLAR, "menu", _id);                        
                    }
                    else if ( _message == "Sits" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_SITS", _id);
                    }
                    else if ( _message == "Walks" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_WALKS", _id);
                    }
                    else if ( _message == "Ground Sits" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_GROUNDSITS", _id);
                    }
                    else if (_message == "Couples")
                    {
                        llMessageLinked(LINK_THIS, COMMAND_TO_COLLAR, "couples", _id);
                    }
                    else if (_message == "HUD Style")
                    {
                        llMessageLinked(LINK_THIS, SUBMENU, "Options", _id);
                    }
                    else if (_message == "Pose")
                    {
                        string authRequest = "pose";
                        llMessageLinked(LINK_THIS, COMMAND_TO_COLLAR, authRequest, _id);
                    }
                    else if ( _message == "Help" ) 
                    {
                        if (llGetInventoryType(helpNotecard) == INVENTORY_NOTECARD)
                            llGiveInventory(_id, helpNotecard);
                    }
                    else if ( _message == "Reset" ) 
                    {
                        llMessageLinked(LINK_THIS, COMMAND_AUTH, "ZHAO_RESET", NULL_KEY);
                        llSleep(1.0);
                        llResetScript();
                    }
                }
            }
        }
        else if(num == DIALOG_TIMEOUT)
        {
            integer menuindex = llListFindList(menuids, [id]);
            
            // if it's greater than 0, we know it's for us (this script)
            if (menuindex != -1)
            {
                llInstantMessage(llGetOwner(),"SubAO Menu has timed out. Pressing a menu entry will not do anything.");
            }
        }    
    }
    
    touch_start( integer _num ) 
    { //ignore touches when attached not at the hud and touches by others but the wearer
        
        if( (llGetAttached() ) && ( llDetectedKey(0) == Owner) ) 
        {
            if (isLocked)
            {
                llMessageLinked(LINK_THIS, COMMAND_NOAUTH, "OCAO_MENU", Owner);
                return;
            }
            
            string button = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            
            string message = "";
            if (button == "Menu") 
            {   
                // -- message = "ZHAO_MENU";
                message = "OCAO_MENU";
            } 
            else if (button == "SitAny")
            {
                if (!isLocked)
                {
                    ToggleSitAnywhere();
                }
            }
            else if (llSubStringIndex(button,"Sub")>=0)
            {   // The Hide Button
                llMessageLinked(LINK_SET, COMMAND_OWNER,"hide",NULL_KEY);
                llSleep(1); 
            }
            
            else if (zhaoOn) 
            {
                message = "ZHAO_AOOFF";
            } 
            else
            {
                message = "ZHAO_AOON";
            }

            if (isLocked)
            {
                if (message == "")
                {
                    message == "SitAny";
                }
                llMessageLinked(LINK_THIS, COMMAND_NOAUTH, message, Owner);
            }
            else if (message != "")
            {
                llMessageLinked(LINK_THIS, COMMAND_OWNER, message, Owner);
            }
        }
        else if (!llGetAttached() && llDetectedKey(0) == Owner)
        {
            llMessageLinked(LINK_THIS, COMMAND_OWNER, "ZHAO_MENU", Owner);
        }
    }

    listen( integer _channel, string _name, key _id, string _message) {
        if (_channel == collarchannel)
        {
            //only accept commands from owner's objects,
            //or from the object that disabled us
            //this is needed because the collar sends a ZHAO_STANDON message when it detaches
            //but because it's no longer rezzed, llgetownerkey doesn't work
            if (llGetOwnerKey(_id) == Owner)
            {
                list params = llParseString2List(_message, ["|"], []);
                string command = llList2String(params, 0);
                string userID = llList2String(params, 1);
                // Added for OCCuffs
                //else 
                if (_message == "ZHAO_PAUSE")
                {
                    llMessageLinked(LINK_THIS, COMMAND_COLLAR, _message, NULL_KEY);
                }
                else if (_message == "ZHAO_UNPAUSE")
                {
                    llMessageLinked(LINK_THIS, COMMAND_COLLAR, _message, NULL_KEY);
                }
                // End of change
                else if (_message == "ZHAO_STANDOFF")
                {
                    if (sitAnywhere) ToggleSitAnywhere(); // SitAnyWhere is On, so disable it first
                    StandAO=FALSE; // and store that we are in off mode
                    llMessageLinked(LINK_SET, COMMAND_COLLAR, _message, NULL_KEY);
                }
                else if (_message == "ZHAO_STANDON")
                {
                    StandAO=TRUE; // set state of Stand AO to TRUE
                    llMessageLinked(LINK_THIS, COMMAND_COLLAR, _message, NULL_KEY);
                }
                else if (_message == "ZHAO_AOSHOW")
                {
                    if(!isAttachedToHUD())
                    {
                        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                    }
                }
                else if (command == "ZHAO_MENU")
                {
                    llMessageLinked(LINK_THIS, COMMAND_OWNER, "ZHAO_MENU", _id);
                }
                else if (_message == "ZHAO_AOHIDE")
                {
                    if(!isAttachedToHUD())
                    {
                        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                    }
                    else
                    {
                        llOwnerSay("You can only hide the AO when it is not attached to the HUD.");
                    }
                }
                else
                {
//llSay(0,"sending "+command+" to collar for "+(string)userID);
                    llMessageLinked(LINK_SET, COMMAND_OWNER, command, (key)userID);
                }
            }
        }
        else if (_channel == rlvChannel)
        {
            llListenRemove(rlvHandle);
            llSetTimerEvent(0.0);
            if (llGetSubString(_message, 0, 20)  == "RestrainedLife viewer")
            {
                rlvDetected = TRUE;
            }
        }
    }
    timer()
    {
        llListenRemove(rlvHandle);
        llSetTimerEvent(0.0);
    }
    
    attach( key _k ) {
        if ( _k != NULL_KEY )
        {
            if( isAttachedToHUD() )
            {
                llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                // DoPosition();
            }
            else
            {
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
            }
            if (isLocked && wasDetached)
            {
                wasDetached = FALSE; // -- Already notified, set to false. If it happens again it will be set once more when detached.
                Notify(lockerID, llKey2Name(Owner) + " has attached the AO again after it was detached while locked.", TRUE);
            }
            
        }
        else
        {
            if (isLocked)
            {
                wasDetached = TRUE;
                Notify(lockerID, llKey2Name(Owner) + " has detached the AO while it was locked.", TRUE);
            }
        }
    }
}
