// OpenCollar - keyholder plugin
// 
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//
// OC3.7xx by Satomi Ahn
// - New authed dialogs system.
// - Removed OCCD stuff.
//
// OC3.526.2 by WhiteFire Sondergaard
// - Safeword Support. DURP.
//
// OC3.526.1 by WhiteFire Sondergaard
// - ~OpenKey ~ClosedKey support.
//
// WS0.824 by Satomi Ahn
// - FIXED: A few typos
//
// OC3.526
// - This is now an OpenCollar script.
//
// WS0.823 by WhiteFire Sondergaard
// - Updated to handle new timer module's "timer on+24:00" format. ** This REQUIRES version 3.525 or better to work now, but no longer requires a hacked timer module. **
// - FIXED: Do not display Main Menu *Take Key* when module is off.
// - Main Menu *Take Key* not enabled by default.
// - FIXED: bug preventing the *Take Key* in the main menu and ()Return Key in the timer menu from working at all. Also merged two different submenu clauses so this mistake won't happen again.
//
// WS0.822 by WhiteFire Sondergaard
// - Save and restore data.
//
// WS0.820 by WhiteFire Sondergaard
// - Merged 0.803 with 0.810
// - Made Config menu optional
//
// WS0.810 by WhiteFire Sondergaard
// - Broadcast KEY_VISIBLE, KEY_INVISIBLE for things that handle keys differently. Namely the LV muzzle line.
//
// WS0.803 by Kadah Coba
// - Moved config menu to Config and Key Holder to Addons.
// note: May want to move Lockout to Main (with confirm/warning dialog) and always have Take/Return Key on Main.
//
// WS0.801 by Kadah Coba
// - Added update to key/lock element list on link change.
//
// WS0.800 by WhiteFire Sondergaard
// - Global Key: let them take keys to more than one toy at once. 
// - Fixed the *Take Key* on reset when displayed on the main menu
//
// WS0.700 by WhiteFire Sondergaard
// - Change to timer support to make it not assume this script exists.
// - Auto-key return on timer, using "on=00:01" calls and new TIMER_EVENT.
// - MENUNAME_REMOVE support.
// - LINK_WHAT to make it easy to change what we message.
//
// WS0.605 by WhiteFire Sondergaard
// - OOCD support
//
// WS0.604 by Kadah Coba
// - Added element hide/show by list instead of scanning names every time.
// - Added g_iHideLockWhenOff to control hidding lock when module is off and collar is locked.
//
// WS0.603 by WhiteFire Sondergaard
// - Fixed bug where WEARERLOCKOUT would not be unset. Oops.
// - Fixed bug where menu would be given on taking the LOCKOUT option.
//
// WS0.601 by WhiteFire Sondergaard
// - Fixed bug where wearer lockout was lost when someone reconnected.
// - Fixed bug where lock graphics were not updated when someone reconnected.
//
// WS0.600 by WhiteFire Sondergaard
// - Added cuff support mode that fires off key visibility messages to slave cuffs.
//
// WS0.501 by WhiteFire Sondergaard
// - After some comments, made public key access default to off. >.>
//
// WS0.500 by WhiteFire Sondergaard
// - Changes to add a unlocked lock and key. It now tries to show/hide "locked key", "unlocked key", "locked lock" and "unlocked lock".
// - Fixes to the lockout option.
//
// WS0.400 by WhiteFire Sondergaard
// - Added "g_sToyName" to make it easier to use this for things other than collars.
// - Initial lockout option.
// - Key / lock visibility code
//
// WS0.300 by WhiteFire Sondergaard
// - Made the exposed key when not open access configurable.
// - Made an option to put a button in the main menu.
// - Support for a Key prim(s). Prims should be named "key". (Also probably good to have the desc be "key" too).
// - Lockout: once locked, lockout mode is enabled. So you can lock yourself up and need help getting out.
//
// Updates/changes by Kadah Coba
// - Main menu support
// - Changes to make compatible with a modified timer that returns the key.
// - Other stuff I forgot (ws)
//
// First Version by WhiteFire Sondergaard
// Adapted from a templet by Cleo Collins

//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

// Please remove any unneeded code sections to save memory and sim time

// Timer Cheat Sheet
// timer on=00:01 or timer real=00:01 set time in MM:SS
// timer start - Starts the timer.
// timer stop - stops the timer.

// TODO
//
// change menu in addons to be the owner confige only since take key is on main.

// -- Toy Configureation ----------------------------------------
string g_szChatCommand = "kh"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin
integer g_iHideLockWhenOff=TRUE; // set to FALSE to not hide the lock when the module is off and the collar is unlocked. :kc
string g_sToyName = "collar";

// Are we in cuff mode?
integer g_iOpenCuffMode = FALSE;

// Who do we send messages to?
integer LINK_WHAT = LINK_SET;

// -- Menu Configureation ----------------------------------------
string g_szSubmenu = "Key Holder"; // Name of the submenu
string g_szParentmenu = "AddOns"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore ( AddOns or Main is recomended depending on the toy. )

string g_szKeyConfigMenu = "Key Holder Config";
string g_szConfigMenu = "Config";

// Timer menu access...
string g_szTimerMenu = "Timer";

// menu option to go one step back in menustructure
string UPMENU = "^";//when your menu hears this, give the parent menu

// -- State Information ----------------------------------------
key kh_key = NULL_KEY; // id key of the person that has the key
string kh_name; // name of the person that has the key
integer kh_type; // Access type keyholder originally had.
integer kh_saved_openaccess; // saved so it can be restored.
integer kh_saved_locked; // saved so it can be restored.
integer kh_lockout = FALSE; // User is locked out until key return.
// integer kh_failed_time = 0; // When they last failed a check.  Ka: What is this for?  ws: Presnece stuff. Future feature.
// Collar state
integer oc_locked = FALSE;
integer oc_openaccess = FALSE;
// OOCD stuff
integer g_iDeviceShown=TRUE; // True unless told otherwise.

// -- Settings ----------------------------------------
integer kh_on = FALSE; // Is this feature turned on?
float kh_range = 10.0; // In meters. 0 = In sim.
integer kh_disable_openaccess = TRUE; // Disable open access when key is taken?
integer kh_lock_collar = TRUE; // Lock the toy when the key is taken?
integer kh_public_key = FALSE; // Can the key be taken when not open access?
integer kh_main_menu = FALSE; // Display in main menu?
integer kh_return_on_timer = FALSE; // Return key on timer expire?
integer kh_auto_return_timer = FALSE; // Start a timer for key return?
integer kh_auto_return_time = 120; // default 1 hour.
integer g_iGlobalKey = TRUE; // are we on the global key.
// integer kh_present = FALSE; // Requires the keyholder be present or the key is returned. TODO

// -- Constants ------------------------------------------
string TAKEKEY = "*Take Key*";
string RETURNKEY = "*Return Key*";

// Various variables needed by cuffs.
integer g_nCmdChannel    = -190890;
integer g_nCmdChannelOffset = 0xCC0CC;       // offset to be used to make sure we do not interfere with other items using the same technique for

// Backchannel for global key stuff.
integer g_iKeyHolderChannel = -0x3FFF0502;
// Protocol:
// key;take;UUID;auth
// key;return;reason

// ------ TOKEN DEFINITIONS ------
string TOK_STORE = "keyholder"; // Stuff that gets stored in the settings store

// State stuff
key g_keyWearer; // key of the current wearer to reset only on owner changes
string g_szPrefix; // sub prefix for databse actions

// Menu Stuff
list localbuttons = [ ]; // any local, not changing buttons which will be used in this plugin, leave emty or add buttons as you like
list externalbuttons = []; // External buttons

// menu handlers
key g_keyMenuID; // For saving the key of the last dialog we sent
key g_keyConfigMenuID;
key g_keyConfigAutoReturnMenuID;

// lock/key prims :kc
list g_lElementsLockedKey; // "locked key" :kc
list g_lElementsUnlockedKey; // "unlocked key" :kc
list g_lElementsLockedLock; // "locked lock" :kc
list g_lElementsUnlockedLock; // "unlocked lock" :kc

//===============================================================================
// OpenCollar MESSAGE MAP
//===============================================================================
// messages for authenticating users
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;
integer COMMAND_BLACKLIST = 520;
// added for timer so when the sub is locked out they can use postions
integer COMMAND_WEARERLOCKEDOUT = 521;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bit of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

// messages for storing and retrieving values from settings store
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to store
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent by settings script when a token has no value in the store

// messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

// messages to the dialog helper
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

// messages for RLV commands
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

// messages for poses and couple anims
integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av

integer WEARERLOCKOUT=620;

integer TIMER_EVENT = -10000; // str = "start" or "end". For start, either "online" or "realtime".

// For other things that want to manage showing/hiding keys.
integer KEY_VISIBLE = -10100;
integer KEY_INVISIBLE = -10100;

//===============================================================================
// Misc utility functions.
//===============================================================================

//===============================================================================
//= parameters   :  integer nOffset        Offset to make sure we use really a unique channel
//=
//= description  : Function which calculates a unique channel number based on the owner key, to reduce lag
//=
//= returns      : Channel number to be used
//===============================================================================
integer nGetOwnerChannel(integer nOffset)
{
    integer chan = (integer)("0x"+llGetSubString((string)llGetOwner(),3,8)) + g_nCmdChannelOffset;
    if (chan>0)
    {
        chan=chan*(-1);
    }
    if (chan > -10000)
    {
        chan -= 30000;
    }
    return chan;
}

//===============================================================================

BuildLockElementList() // EB :kc was here
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    // list lParams;
    string sPrimName;
    list lParams;
    
    // clear list just in case
    g_lElementsLockedKey = [];
    g_lElementsUnlockedKey = [];
    g_lElementsLockedLock = [];
    g_lElementsUnlockedLock = [];

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        // read description
        lParams=llParseString2List((string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_DESC]), ["~"], []);
        sPrimName=llGetLinkName(n);
        
        // check inf name is lock name
        if (sPrimName=="locked key" || 
            (llListFindList(lParams, [ "ClosedKey" ]) != -1))
        {
            g_lElementsLockedKey += [n];
        } else if (sPrimName=="unlocked key" || 
            (llListFindList(lParams, [ "OpenKey" ]) != -1))
        {
            g_lElementsUnlockedKey += [n];
        } else if (sPrimName=="locked lock") {
            g_lElementsLockedLock += [n];
        } else if (sPrimName=="unlocked lock") {
            g_lElementsUnlockedLock += [n];
        }
    }
}

SetElementAlpha(float fAlpha, list lList) // EB :kc was here
{
    // loop through stored links, setting alpha if element type is lock
    integer n;
    integer iLinkElements = llGetListLength(lList);
    for (n = 0; n < iLinkElements; n++) llSetLinkAlpha(llList2Integer(lList,n), fAlpha, ALL_SIDES);
}

string strReplace(string str, string search, string replace) {
    return llDumpList2String(llParseStringKeepNulls((str = "") + str, [search], []), replace);
}

// Returns true if it matches with or with out the DB prefix
integer CompareDBPrefix(string str, string value)
{
    return ((str == value) || (str == (g_szPrefix + value)));
}

//===============================================================================
//= parameters   :    string    szMsg   message string received
//= return        :    none
//= description  :    output debug messages
//===============================================================================
Debug(string szMsg)
{
// uncomment to enable debug mode
//    llOwnerSay(llGetScriptName() + ": " + szMsg);
}

//===============================================================================
//= parameters   :    key       kID                 key of the avatar that receives the message
//=                   string    msg                message to send
//=                   integer   alsoNotifyWearer   if TRUE, a copy of the message is sent to the wearer
//= return        :    none
//= description  :    notify targeted id and maybe the wearer
//===============================================================================
Notify(key kID, string msg, integer alsoNotifyWearer)
{
    if (kID == g_keyWearer)
    {
        llOwnerSay(msg);
    }
    else
    {
        llInstantMessage(kID,msg);
        if (alsoNotifyWearer)
        {
            llOwnerSay(msg);
        }
    }
}

//===============================================================================
//= parameters   :    key   kRCPT      recipient of the dialog
//=                   string  sPrompt    dialog prompt
//=                   list  lChoices    true dialog buttons
//=                   list  lUtilitybuttons  utility buttons (kept on every page)
//=                   integer  iPage    page to display
//=                   integer  iAuth    authentification level of recipient
//=
//= return        :    key  handler of the dialog
//=
//= description  :    displays a dialog to the given recipient
//=
//===============================================================================
key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    //key generation
    //just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sOut;
    integer n;
    for (n = 0; n < 8; ++n)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString( "0123456789abcdef", iIndex, iIndex);
    }
    key kID = (sOut + "-0000-0000-0000-000000000000");
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
        + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

string CheckBox(string name, integer value)
{
    if (value) return "(*)" + name;
    else return "()" + name;
}

//===============================================================================
//= parameters   :    string    szMsg   message string received
//=
//= return        :    integer TRUE/FALSE
//=
//= description  :    checks if a string begin with another string
//=
//===============================================================================

integer nStartsWith(string szHaystack, string szNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return (llDeleteSubString(szHaystack, llStringLength(szNeedle), -1) == szNeedle);
}

//===============================================================================
//= parameters   :    string    keyID   key of person requesting the menu
//=
//= return        :    none
//=
//= description  :    build menu and display to user
//=
//===============================================================================

DoMenuSpecial(key keyID, integer page, integer special, integer iAuth)
{
    string prompt;
    list mybuttons = localbuttons + externalbuttons;
    list utility_buttons;

    //fill in your button list and additional prompt here
    if (!kh_on)
    {
        prompt = "This module is turned off. An Owner can turn it on from the Configure menu.";
    }
    else if (keyID == kh_key)
    {
        prompt = "You hold the key! You may return it to the lock if you wish.";
        mybuttons = [ "Return Key" ] + mybuttons;
    }
    else if (kh_key == NULL_KEY)
    {
        prompt = "The key is available for the taking!";        
        mybuttons = [ "Take Key" ] + mybuttons;
    }
    else
    {
        prompt = "The key is held by " + kh_name + "\n\nOwners can force a key return.";
        mybuttons = [ "Force Return" ] + mybuttons;
    }
    
    if (!special)
    {
        prompt += "\n\nLockout - Lock wearer out IMMEDIATLY. Unset on key return.";
        if (!kh_lockout)
            mybuttons += "Lockout";

        mybuttons += [ "Configure" ];
    }
    
    // Optional
    llListSort(localbuttons, 1, TRUE); // resort menu buttons alphabetical

    // Utility buttons are shown on every page
    if (!special)
        utility_buttons += [UPMENU]; //make sure there's a button to return to the parent menu

    // and dispay the menu
    g_keyMenuID = Dialog(keyID, prompt, mybuttons, utility_buttons, 0, iAuth);
}

DoMenu(key keyID, integer page, integer iAuth)
{
    DoMenuSpecial(keyID, page, FALSE, iAuth);
}

string Int2Time(integer sTime)
{
    if (sTime<0) sTime=0;
    integer iSecs=sTime%60;
    sTime = (sTime-iSecs)/60;
    integer iMins=sTime%60;
    sTime = (sTime-iMins)/60;
    integer iHours=sTime%24;
    integer iDays = (sTime-iHours)/24;
    
    return ( (string)iDays+", "+
        llGetSubString("0"+(string)iHours,-2,-1) + ":"+
        llGetSubString("0"+(string)iMins,-2,-1) + ":"+
        llGetSubString("0"+(string)iSecs,-2,-1) );
}

DoMenuAutoReturnConfig(key keyID, integer page, integer iAuth)
{
    string prompt;
    list mybuttons = localbuttons;
//[23:45:29]  Kadah Coba: 1h, 3h, 6h, 1d, 2d, 3d?, 1w
    list times = [ 1*60*60, 3*60*60, 6*60*60, 1*24*60*60, 2*24*60*60, 4*24*60*60, 7*24*60*60 ];
    integer i;
    integer max_times = llGetListLength(times);
    
    prompt = 
"Key Auto Return Configuration

Turn this feature off, or pick a time to return the key in automatically.

Times in: Days, Hours:Minutes:Seconds.

Only the owner may change these.
";
    //fill in your button list and additional prompt here
    mybuttons += CheckBox("Auto Off", !kh_auto_return_timer);

    for (i = 0; i < max_times; i++)
    {
        mybuttons += CheckBox(Int2Time(llList2Integer(times, i)), llList2Integer(times, i) == kh_auto_return_time && kh_auto_return_timer);
    }

    llListSort(localbuttons, 1, TRUE); // resort menu buttons alphabetical
    
    // and dispay the menu
    g_keyConfigAutoReturnMenuID = Dialog(keyID, prompt, mybuttons, [UPMENU], 0, iAuth);
}

DoMenuConfigure(key keyID, integer page, integer iAuth)
{
    string prompt;
    list mybuttons = localbuttons;

    prompt = 
"Key Holder Configuration

Lock - Does the " + g_sToyName + " lock when someone takes the key?
No Open - Does the " + g_sToyName + " disable open access when someone takes the key?
On - Is the keyholder module turned on?
Pub. Key - Is the key public even when Open Access is turned off?
Main Menu - Is the main menu changed for ease of access.
Global - Is this on the global key system?

Only the owner may change these.
";
    //fill in your button list and additional prompt here
    mybuttons += CheckBox("On", kh_on);
    mybuttons += CheckBox("Lock", kh_lock_collar);
    mybuttons += CheckBox("No Open", kh_disable_openaccess);
    mybuttons += CheckBox("Pub. Key", kh_public_key);
    mybuttons += CheckBox("Main Menu", kh_main_menu);
    mybuttons += CheckBox("Global", g_iGlobalKey);
//    mybuttons += CheckBox("Lockout", kh_lockout);
    mybuttons += [ "Auto Return" ];
    
    // Optional
    llListSort(localbuttons, 1, TRUE); // resort menu buttons alphabetical

    // and dispay the menu
    g_keyConfigMenuID = Dialog(keyID, prompt, mybuttons, [UPMENU], 0, iAuth);
}




//===============================================================================
TakeKey(key avatar, integer auth, integer remote)
{
    if (!kh_on)
    {
        llInstantMessage(avatar, "This module is turned off by an Owner.");
        return;
    }
    
    if (!remote && kh_range > 0.0 && llVecDist(llList2Vector(llGetObjectDetails(avatar, [OBJECT_POS]),0),llGetPos()) > kh_range)
    {
        llInstantMessage(avatar, "You are too far away to take " + llKey2Name(llGetOwner()) + "'s key, you will have to move closer.");
        return;
    }

    kh_key = avatar;
    kh_name = llKey2Name(avatar);
    kh_type = auth;
    
    kh_saved_openaccess = oc_openaccess;
    kh_saved_locked = oc_locked;
    
    setMainMenu();
    
    if (kh_disable_openaccess && oc_openaccess)
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "unsetopenaccess", avatar);
    
    if (kh_lock_collar && !oc_locked)
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "lock", avatar);
    
    llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "on", "");
    
    if (kh_auto_return_timer && kh_auto_return_time)
    {
        integer minutes = (kh_auto_return_time / 60) % 60;
        integer hours = kh_auto_return_time / 60 / 60;
        
        // Set the timer. Real timer for now. Make it an option later.
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, 
            "timer real=" + (string)hours + ":" + (string)minutes,
            NULL_KEY);
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "timer start", NULL_KEY);
    }
    
    llInstantMessage(avatar, "You take " + llKey2Name(llGetOwner()) + "'s key!");
    Notify(g_keyWearer, "Your key has been taken by " + llKey2Name(avatar) + "!", TRUE);

    if (!remote && g_iGlobalKey)
        llWhisper(g_iKeyHolderChannel, llDumpList2String([
            "key", "take", (string)avatar, (string)auth
            ], ";") );

    updateVisible();
    
    saveSettings();
}

ReturnKey(string reason, integer remote)
{
    key avatar = kh_key;
    
    if (kh_key == NULL_KEY) return;
    
    kh_key = NULL_KEY;
    kh_name = "";
    kh_type = 0;
    
    setMainMenu();

    if (kh_disable_openaccess && kh_saved_openaccess && !oc_openaccess)
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "setopenaccess", avatar); 
    
    if (kh_lock_collar && !kh_saved_locked && oc_locked)
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "unlock", avatar);
    
    // Need to check if someone else is doing this too... but really that should be handled by 
    // the auth module somehow.
    llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "off", "");
    
    // Lockout canceled on key return
    kh_lockout = FALSE;
    
    if (kh_auto_return_timer && kh_auto_return_time)
    {
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "timer stop", NULL_KEY);
    }
            
    llInstantMessage(avatar, llKey2Name(llGetOwner()) + "'s key is returned. " + reason);
    Notify(g_keyWearer, "Your key has been returned. " + reason, TRUE);
    
    if (!remote && g_iGlobalKey)
        llWhisper(g_iKeyHolderChannel, llDumpList2String([
            "key", "return", (string)reason
            ], ";") );
    
    updateVisible();
    
    saveSettings();
}

//===============================================================================
//
//===============================================================================
setMainMenu()
{
    llMessageLinked(LINK_WHAT, MENUNAME_REMOVE, "Main" + "|" + RETURNKEY, NULL_KEY);
    llMessageLinked(LINK_WHAT, MENUNAME_REMOVE, "Main" + "|" + TAKEKEY, NULL_KEY);
    
    if (kh_on && kh_main_menu)
    {
        if (kh_key != NULL_KEY)
            llMessageLinked(LINK_WHAT, MENUNAME_RESPONSE, "Main" + "|" + RETURNKEY, NULL_KEY);
        else
            llMessageLinked(LINK_WHAT, MENUNAME_RESPONSE, "Main" + "|" + TAKEKEY, NULL_KEY);
    }
}

//===============================================================================
//
//===============================================================================
setTimerMenu()
{
    llMessageLinked(LINK_WHAT, MENUNAME_RESPONSE, g_szTimerMenu + "|" + CheckBox("Return Key", kh_return_on_timer), NULL_KEY);
    llMessageLinked(LINK_WHAT, MENUNAME_REMOVE, g_szTimerMenu + "|" + CheckBox("Return Key", !kh_return_on_timer), NULL_KEY);
}

//===============================================================================
//
//===============================================================================
updateVisible()
{
    integer show_key = FALSE;
    
    if (g_iDeviceShown == FALSE)
    {
        SetElementAlpha(0.0, g_lElementsLockedKey);
        SetElementAlpha(0.0, g_lElementsUnlockedKey);
        SetElementAlpha(0.0, g_lElementsUnlockedLock);
        SetElementAlpha(0.0, g_lElementsLockedLock);
    }
    else if (oc_locked)
    {
        if (kh_key == NULL_KEY && kh_on)
        {
            SetElementAlpha(1.0, g_lElementsLockedKey);
            SetElementAlpha(0.0, g_lElementsUnlockedKey);
            show_key = TRUE;
        }
        else
        {
            SetElementAlpha(0.0, g_lElementsLockedKey);
            SetElementAlpha(0.0, g_lElementsUnlockedKey);
        }
        
        SetElementAlpha(0.0, g_lElementsUnlockedLock);
        SetElementAlpha(1.0, g_lElementsLockedLock);
    }
    else
    {
        if (kh_key == NULL_KEY && kh_on)
        {
            SetElementAlpha(0.0, g_lElementsLockedKey);
            SetElementAlpha(1.0, g_lElementsUnlockedKey);
            show_key = TRUE;
        }
        else
        {
            SetElementAlpha(0.0, g_lElementsLockedKey);
            SetElementAlpha(0.0, g_lElementsUnlockedKey);
        }
        
        if (!kh_on && g_iHideLockWhenOff) // just hide the thing entirely in this case.
            SetElementAlpha(0.0, g_lElementsUnlockedLock);
        else
            SetElementAlpha(1.0, g_lElementsUnlockedLock);
        SetElementAlpha(0.0, g_lElementsLockedLock);
    }
    
    // Let other people know in case they are handling it and not us.
    if (show_key)
        llMessageLinked(LINK_WHAT, KEY_VISIBLE, "", "");
    else
        llMessageLinked(LINK_WHAT, KEY_INVISIBLE, "", "");

    
    // Handle cuffs, if we are in Cuff mode.
    if (g_iOpenCuffMode)
    {
        llRegionSay(g_nCmdChannel+1,"rlac|*|khShowKey=" + (string)show_key + "|" + (string)llGetOwner());
    }
}

//===============================================================================
// State Saving
//===============================================================================
saveSettings()
{
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, 
        g_szPrefix + TOK_STORE + "=" +
        llDumpList2String([
                kh_on,
                kh_range,
                kh_disable_openaccess,
                kh_lock_collar,
                kh_public_key,
                kh_main_menu,
                kh_return_on_timer,
                kh_auto_return_timer,
                kh_auto_return_time,
                g_iGlobalKey
            ], ","), NULL_KEY);
}

loadDBSettings(string sSettings)
{
    list lValues = llParseStringKeepNulls(sSettings, [ "," ], []);
    
    kh_on = (integer)llList2String(lValues, 0);
    kh_range = (float)llList2String(lValues, 1);
    kh_disable_openaccess = (integer)llList2String(lValues, 2);
    kh_lock_collar = (integer)llList2String(lValues, 3);
    kh_public_key = (integer)llList2String(lValues, 4);
    kh_main_menu = (integer)llList2String(lValues, 5);
    kh_return_on_timer = (integer)llList2String(lValues, 6);
    kh_auto_return_timer = (integer)llList2String(lValues, 7);
    kh_auto_return_time = (integer)llList2String(lValues, 8);
    g_iGlobalKey = (integer)llList2String(lValues, 9);
    
    setMainMenu();
}

loadLocalSettings(string sSettings)
{
    list lValues = llParseStringKeepNulls(sSettings, [ "," ], []);
    
    if (kh_key != NULL_KEY) return; // Already have a keyholder, do not overwrite.
    
    kh_key = llList2Key(lValues, 0);
    kh_type = (integer)llList2String(lValues, 1);
    kh_name = llList2String(lValues, 2);
    kh_saved_openaccess = (integer)llList2String(lValues, 3);
    kh_saved_locked = (integer)llList2String(lValues, 4);
    
    updateVisible();
    setMainMenu();
}

//===============================================================================
//= parameters   :    none
//=
//= return        :   string     DB prefix from the description of the collar
//=
//= description  :    prefix from the description of the collar
//=
//===============================================================================

string GetDBPrefix()
{//get db prefix from list in object desc
    return llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 2);
}


//===============================================================================


// Check whether the avatar has owner privileges. Notify if not.
integer OwnerCheck(key kAv, integer iAuth)
{
    if (iAuth == COMMAND_OWNER) return TRUE;
    else
    {
        Notify(kAv, "That command can only be accessed by an Owner.", FALSE);
        return FALSE;
    }
}

// Check whether the avatar holds the key. Notify if not.
integer KeyholderCheck(key kAv)
{
    if (kAv == kh_key) return TRUE;
    else
    {
        Notify(kAv, "You are not the keyholder.", FALSE);
        return FALSE;
    }
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer num, string str, key id) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (num > COMMAND_EVERYONE || num < COMMAND_OWNER) return FALSE; // sanity check
    // Main Menu
    if (str == "menu " + g_szSubmenu)
    {
        DoMenu(id, 0, num);
    }
    // Config Menu
    else if (str == "menu " + g_szKeyConfigMenu)
    {
        DoMenuConfigure(id, 0, num);
    }
    // This is out of the timer module...
    else if (str == "menu (*)Return Key")
    {
        UserCommand(num, "khunsettimerreturnkey", id);
        llMessageLinked(LINK_WHAT, num, "menu "+ g_szTimerMenu, id);                
    }
    else if (str == "menu ()Return Key")
    {
        UserCommand(num, "khsettimerreturnkey", id);
        llMessageLinked(LINK_WHAT, num, "menu "+ g_szTimerMenu, id);                
    }
    // Take / Return key from the main menu
    else if (str == "menu " + TAKEKEY)
    {
        UserCommand(num, "khtakekey", id);
        llMessageLinked(LINK_WHAT, num, "menu Main", id);
    }
    else if (str == "menu " + RETURNKEY)
    {
        if (KeyholderCheck(id)) ReturnKey("", FALSE);
        llMessageLinked(LINK_WHAT, num, "menu Main", id);
    }      
    else if (str == "khreturnkey") {if (KeyholderCheck(id)) ReturnKey("", FALSE);}
    else if (kh_public_key && str == "khtakekey")
    {
        if (id == g_keyWearer) Notify(id, "Taking your own key does not make any sense.", FALSE);
        else if (kh_key != NULL_KEY) Notify(id, "The key is not in the lock.", FALSE);
        else TakeKey(id, num, FALSE);
    }
    else if ((id == g_keyWearer || num == COMMAND_OWNER) && str == "resetscripts")
    {
        llResetScript();
    }
    // after here, only primary owner commands
    else if (llGetSubString(str, 0, 4) == "khset" 
            && (llGetSubString(str, 5, 6) == "0," || (integer)llGetSubString(str, 5, 5) > 0) )
    {
        if (!OwnerCheck(id, num)) return TRUE;
        list times = llParseString2List(str, [ "khset", ",", ":" ], []);
        kh_auto_return_time = 
            ( (integer)llList2String(times, 0) * 24 * 60 * 60 ) + // days
            ( (integer)llList2String(times, 1) * 60 * 60 ) + // Hours
            ( (integer)llList2String(times, 2) * 60 ) + // Minutes
            ( (integer)llList2String(times, 3)  ) ; // Seconds
        kh_auto_return_timer = TRUE;
        DoMenuAutoReturnConfig(id, 0, num);
        saveSettings();
    }
    else if (str == "khsetautooff")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        kh_auto_return_timer = FALSE; 
        DoMenuAutoReturnConfig(id, 0, num);
        saveSettings();
    }
    else if (str == "khforcereturn")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        if (kh_key == NULL_KEY)
            llInstantMessage(id, "The key is already in the lock.");
        else
        {
            ReturnKey(llKey2Name(id) + " forced the return.", FALSE);
            llInstantMessage(id, "You force-return the key to the lock.");
        }
        DoMenu(id, 0, num);
    }
    else if (str == "khtimerreturn")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        if (kh_key != NULL_KEY)
        {
            ReturnKey("Key returned by timer.", FALSE);
        }
    }
    else if (str == "khsetlock" || str == "khunsetlock")
    { 
        if (!OwnerCheck(id, num)) return TRUE;
        kh_lock_collar = ( str == "khsetlock" );
        DoMenuConfigure(id, 0, num);
        saveSettings();
    }
    else if (str == "khsetnoopen" || str == "khunsetnoopen")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        kh_disable_openaccess = ( str == "khsetnonoopen" );
        DoMenuConfigure(id, 0, num);
        saveSettings();
    }
    else if (str == "khsetpub.key" || str == "khunsetpub.key")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        kh_public_key = ( str == "khsetpub.key" );
        DoMenuConfigure(id, 0, num);
        saveSettings();
    }
    else if (str == "khlockout")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        if (kh_lockout)
            return TRUE;
        kh_lockout = TRUE;
        Notify(g_keyWearer, "You are now locked out until your key is taken and returned.", TRUE);
        llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "on", "");
        if (id != llGetOwner())
            DoMenuConfigure(id, 0, num);
    }
    else if (str == "khsetmainmenu" || str == "khunsetmainmenu")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        kh_main_menu = ( str == "khsetmainmenu" );
        setMainMenu();
        DoMenuConfigure(id, 0, num);
        saveSettings();
    }
    else if (str == "khsetglobal" || str == "khunsetglobal")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        g_iGlobalKey = ( str == "khsetglobal" );
        DoMenuConfigure(id, 0, num);
        saveSettings();
    }
    else if (str == "khseton" || str == "khunseton")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        kh_on = ( str == "khseton" );                
        if (kh_key != NULL_KEY)
            ReturnKey("Key Holder plugin turned off by " + llKey2Name(id), FALSE);
        DoMenuConfigure(id, 0, num);
        
        updateVisible();
        saveSettings();
    }
    else if (str == "khunsettimerreturnkey" || str == "khsettimerreturnkey")
    {
        if (!OwnerCheck(id, num)) return TRUE;
        kh_return_on_timer = ( str == "khsettimerreturnkey");
        setTimerMenu();
        llMessageLinked(LINK_WHAT, num, "menu " + g_szTimerMenu, id);
        saveSettings();
    }
    return TRUE;
}

default
{
    state_entry()
    {
        // sleep a second to allow all scripts to be initialized
        llSleep(1.0);
        // send request to main menu and ask other menus if they want to register with us
        llMessageLinked(LINK_WHAT, MENUNAME_REQUEST, g_szSubmenu, NULL_KEY);
        llMessageLinked(LINK_WHAT, MENUNAME_RESPONSE, g_szParentmenu + "|" + g_szSubmenu, NULL_KEY);
        // get dbprefix from object desc, so that it doesn't need to be hard coded, and scripts between differently-primmed collars can be identical
        g_szPrefix = GetDBPrefix();
        g_keyWearer=llGetOwner();
        updateVisible();
        
        if (g_iOpenCuffMode) 
            g_nCmdChannel = nGetOwnerChannel(g_nCmdChannelOffset); // get the owner defined channel
        
        BuildLockElementList(); // kc
        
        // Global Key
        llListen(g_iKeyHolderChannel, "", "", "");
        
        // Get us up to date.
        setMainMenu();
        setTimerMenu();
    }

    // reset the script if wearer changes. By only reseting on owner change we can keep most of our
    // configuration in the script itself as global variables, so that we don't loose anything in case
    // the httpdb server isn't available
    on_rez(integer param)
    {
        if (llGetOwner()!=g_keyWearer)
        {
            // Reset if wearer changed
            llResetScript();
        }
        if ( kh_lockout || kh_key != NULL_KEY )
            llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "on", "");
        updateVisible();
    }


    // listen for likend messages from OC scripts
    link_message(integer sender, integer num, string str, key id)
    {
        if (num == MENUNAME_REQUEST)
            // our parent menu requested to receive buttons, so send ours
        {
            if (str == g_szParentmenu)
                llMessageLinked(LINK_WHAT, MENUNAME_RESPONSE, g_szParentmenu + "|" + g_szSubmenu, NULL_KEY);

            if (str == "Main") setMainMenu();
            else if (str == g_szTimerMenu) setTimerMenu();
        }
        else if (num == MENUNAME_RESPONSE)
            // a button is send to be added to a menu
        {
            list parts = llParseString2List(str, ["|"], []);
            if (llList2String(parts, 0) == g_szSubmenu)
            {//someone wants to stick something in our menu
                string button = llList2String(parts, 1);
                if (llListFindList(externalbuttons, [button]) == -1)
                    // if the button isnt in our menu yet, than we add it
                {
                    externalbuttons = llListSort(externalbuttons + [button], 1, TRUE);
                }
            }
        }
        else if (num == MENUNAME_REMOVE)
            // a button is send to be removed from a menu
        {
            list parts = llParseString2List(str, ["|"], []);
            if (llList2String(parts, 0) == g_szSubmenu)
            {//someone wants to stick something in our menu
                string button = llList2String(parts, 1);
                integer iIndex = llListFindList(externalbuttons, [button]);
                if (iIndex != -1)
                {
                    externalbuttons = llDeleteSubList(externalbuttons, iIndex, iIndex);
                }
            }
        }
        else if(num == COMMAND_WEARERLOCKEDOUT)
        {
            // Do nothing, they are not allowed.
            if (str == "menu" && ( kh_key != NULL_KEY || kh_lockout ) )
            {
                if ( kh_key == NULL_KEY )
                    Notify(g_keyWearer, "You are locked out of the " + g_sToyName + " until someone takes and returns your key.", TRUE);
                else Notify(g_keyWearer, "You are locked out of the " + g_sToyName + " until your key is returned.", TRUE);
            }
        }
        else if (num == COMMAND_EVERYONE)
        {
            if (kh_public_key && str == "khtakekey")
            {
                if (kh_key != NULL_KEY) Notify(id, "The key is not in the lock.", FALSE);
                else TakeKey(id, num, FALSE);
            }
            else if (id == kh_key)
            {
                llMessageLinked(LINK_WHAT, COMMAND_GROUP, str, id);
            }
            else if (kh_key == NULL_KEY && str == "menu" && !oc_openaccess && kh_public_key)
            {
                DoMenuSpecial(id, 0, TRUE, num);
            }
        }
        else if (UserCommand(num, str, id)) return;  // from COMMAND_OWNER to COMMAND_WEARER
        else if (num == DIALOG_RESPONSE)
            // answer from menu system
            // careful, don't use the variable id to identify the user.
            // you have to parse the answer from the dialog system and use the parsed variable av
        {
            // One of our menus?
            if (id == g_keyMenuID || id == g_keyConfigMenuID || id == g_keyConfigAutoReturnMenuID)
            {
                // Extract the values...
                list menuparams = llParseString2List(str, ["|"], []);
                key av = (key)llList2String(menuparams, 0);
                string message = llList2String(menuparams, 1);
                integer page = (integer)llList2String(menuparams, 2);
                integer iAuth = (integer)llList2String(menuparams, 3);
                
                // request to change to parent menu
                if (message == UPMENU)
                {
                    if (id == g_keyMenuID)
                        llMessageLinked(LINK_WHAT, iAuth, "menu "+g_szParentmenu, av);
                    else if (id == g_keyConfigMenuID)
                    {
                        DoMenu(av, 0, iAuth);
                    }
                    else if (id == g_keyConfigAutoReturnMenuID)
                        DoMenuConfigure(av, 0, iAuth);
                }
                else if (message == "Configure")
                {
                    DoMenuConfigure(av, 0, iAuth);
                }
                else if (message == "Auto Return")
                {
                    DoMenuAutoReturnConfig(av, 0, iAuth);
                }
                else
                {
                    // Handle checkboxes.
                    string cmd = g_szChatCommand;             
                    if (llGetSubString(message, 0, 1) == "()")
                    {
                        cmd += "set"+llGetSubString(message, 2, -1);
                    }
                    else if (llGetSubString(message, 0, 2) == "(*)")
                    {
                        cmd += "unset" + llGetSubString(message, 3, -1);
                    }
                    // Remove spaces, lowercase
                    cmd = strReplace(cmd, " ", "");
                    cmd = llToLower(cmd);
                    // Handle the command
                    UserCommand(iAuth, cmd, av);
                }
                
                if (id == g_keyMenuID)
                    g_keyMenuID = NULL_KEY;
                if (id == g_keyConfigMenuID)
                    g_keyConfigMenuID = NULL_KEY;
            }
        }
        else if (num == DIALOG_TIMEOUT)
        {
            if (id == g_keyMenuID)
                g_keyMenuID = NULL_KEY;
            if (id == g_keyConfigMenuID)
                g_keyConfigMenuID = NULL_KEY;
        }
        else if (num == LM_SETTING_RESPONSE || num == LM_SETTING_SAVE)
        {
            list params = llParseString2List(str, ["="], []);
            string token = llList2String(params, 0);
            string value = llList2String(params, 1);
            
            if ( CompareDBPrefix(token, "locked") )
            {
                oc_locked = (integer)value;
                updateVisible();
            }
            else if ( CompareDBPrefix(token, "openaccess") )
            {
                oc_openaccess = (integer)value;
            }
            else if ( CompareDBPrefix(token, TOK_STORE) )
            {
                loadDBSettings(value);
            }
        }
        else if (num == LM_SETTING_DELETE)
        {
            // Saddly it's deleted to indicate FALSE rather than set to 0...
            if ( CompareDBPrefix(str, "locked") )
            {
                oc_locked = FALSE;
                updateVisible();
            }
            else if ( CompareDBPrefix(str, "openaccess") ) oc_openaccess = FALSE;
        }
        else if (num == COMMAND_SAFEWORD)
        {
            ReturnKey(llKey2Name(id) + " has safeworded, key auto-returned.", FALSE);
        }
        else if (num == TIMER_EVENT)
        {
            if (str == "end")
            {
                if (kh_auto_return_timer)
                    ReturnKey("The automatic timer has expired.", FALSE);
                else if (kh_return_on_timer)
                    ReturnKey("The timer has expired.", FALSE);
            }
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == g_iKeyHolderChannel)
        {
            if (!g_iGlobalKey) return; // don't care.
            if (llGetOwner() != llGetOwnerKey(id)) return; // Not for us.
            
            list lArgs = llParseString2List(message, [";"], []);
            
            if (llList2String(lArgs, 0) != "key") return; // channel overlap?
            
            if (llList2String(lArgs, 1) == "take")
            {
                TakeKey(llList2Key(lArgs, 2), (integer)llList2String(lArgs, 3), TRUE);
            }
            else if (llList2String(lArgs, 1) == "return")
            {
                ReturnKey(llList2String(lArgs, 2), TRUE);
            }
        }
    }
    
    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER) llResetScript();
        else if (iChange & CHANGED_LINK) BuildLockElementList();
    }
}