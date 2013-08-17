// OpenCollar - keyholder plugin
//
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//

// -- Toy Configuration ----------------------------------------
integer g_iHideLockWhenOff=TRUE; // set to FALSE to not hide the lock when the module is off and the collar is unlocked. :kc
string g_sToyName = "collar";

// Are we in cuff mode?
integer g_iOpenCuffMode = FALSE;

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
integer g_iInterfaceChannel = -12587429; // OC attachments

// Backchannel for global key stuff.
integer g_iKeyHolderChannel = -0x3FFF0502;
// Protocol:
// key;take;UUID;auth
// key;return;reason

// State stuff
key g_kWearer; // key of the current wearer to reset only on owner changes

// menu handlers
key g_keyMenuID; // For saving the key of the last dialog we sent
key g_keyConfigMenuID;
key g_keyConfigAutoReturnMenuID;

// key prims :kc
list g_lElementsLockedKey; // "locked key" :kc
list g_lElementsUnlockedKey; // "unlocked key" :kc

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
string g_sScript;

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

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        // read description
        lParams=llParseString2List((string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_DESC]), ["~"], []);
        sPrimName=llGetLinkName(n);
        // check inf name is lock name
        if (llListFindList(lParams, [ "ClosedKey" ]) != -1)
            g_lElementsLockedKey += [n];
        else if (llListFindList(lParams, [ "OpenKey" ]) != -1)
            g_lElementsUnlockedKey += [n];
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

//===============================================================================
//= parameters   :    key       kID                 key of the avatar that receives the message
//=                   string    msg                message to send
//=                   integer   alsoNotifyWearer   if TRUE, a copy of the message is sent to the wearer
//= return        :    none
//= description  :    notify targeted id and maybe the wearer
//===============================================================================
Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
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
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

string Float2String(float in)
{
    string out = (string)in;
    integer i = llSubStringIndex(out, ".");
    while (~i && llStringLength(llGetSubString(out, i + 2, -1)) && llGetSubString(out, -1, -1) == "0")
    {
        out = llGetSubString(out, 0, -2);
    }
    return out;
}

string CheckBox(string name, integer value)
{
    if (value) return "(*)" + name;
    else return "( )" + name;
}

//===============================================================================
//= parameters   :    string    kID   key of person requesting the menu
//                    integer iPublicMenu: is this the public version of the menu?
//                    integer iAuth: auth level of menu user
//=
//= return        :    none
//=
//= description  :    build menu and display to user
//=
//===============================================================================

DoMenu(key kID, integer iPublicMenu, integer iAuth)
{
    string prompt;
    list mybuttons;
    list utility_buttons;

    //fill in your button list and additional prompt here
    if (!kh_on)
    {
        prompt = "This module is turned off. An Owner can turn it on from the Configure menu.";
    }
    else if (kID == kh_key)
    {
        prompt = "You hold the key! You may return it to the lock if you wish.";
        mybuttons = [ "Return Key" ] + mybuttons;
    }
    else if (kh_key == NULL_KEY)
    {
        prompt = "The key is available for the taking!";
        mybuttons = [ "Take Key" ] + mybuttons;
    }
    else if (iAuth == COMMAND_OWNER)
    {
        prompt = "The key is held by " + kh_name + "\n\nOwners can force a key return.";
        mybuttons = [ "Force Return" ] + mybuttons;
    }

    if (!iPublicMenu)
    {
        prompt += "\n\nLockout - Lock wearer out IMMEDIATLY. Unset on key return.";
        if (!kh_lockout) mybuttons += "Lock Out";
        if (iAuth == COMMAND_OWNER) mybuttons += ["Configure"];
        utility_buttons += [UPMENU];
    }
    g_keyMenuID = Dialog(kID, prompt, mybuttons, utility_buttons, 0, iAuth);
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

    return ( (string)iDays+"d "+
        llGetSubString("0"+(string)iHours,-2,-1) + ":"+
        llGetSubString("0"+(string)iMins,-2,-1) + ":"+
        llGetSubString("0"+(string)iSecs,-2,-1) );
}

DoMenuAutoReturnConfig(key keyID, integer iAuth)
{
    string prompt;
    list mybuttons;
    //[23:45:29]  Kadah Coba: 1h, 3h, 6h, 1d, 2d, 3d?, 1w
    list times = [ 1*60*60, 3*60*60, 6*60*60, 1*24*60*60, 2*24*60*60, 4*24*60*60, 7*24*60*60 ];
    integer i;
    integer max_times = llGetListLength(times);

    prompt = "Key Auto Return Configuration Turn this feature off, or pick a time to return the key in automatically. ";
    prompt += "Times in: Days, Hours:Minutes:Seconds. Only the owner may change these.";
    //fill in your button list and additional prompt here
    mybuttons += CheckBox("Auto Off", !kh_auto_return_timer);

    for (i = 0; i < max_times; i++)
    {
        mybuttons += CheckBox(Int2Time(llList2Integer(times, i)), llList2Integer(times, i) == kh_auto_return_time && kh_auto_return_timer);
    }

    g_keyConfigAutoReturnMenuID = Dialog(keyID, prompt, mybuttons, [UPMENU], 0, iAuth);
}

DoMenuConfigure(key keyID, integer iAuth)
{
    string prompt;
    list mybuttons;

    prompt = "Key Holder Configuration Lock - Does the " + g_sToyName + " lock when someone takes the key? ";
    prompt += "No Open - Does the " + g_sToyName + " disable open access when someone takes the key? ";
    prompt += "On - Is the keyholder module turned on? Pub. Key - Is the key public even when Open Access is turned off? ";
    prompt += "Main Menu - Is the main menu changed for ease of access. Global - Is this on the global key system? ";
    prompt += "Only the owner may change these.";
    //fill in your button list and additional prompt here
    mybuttons += CheckBox("On", kh_on);
    mybuttons += CheckBox("Lock", kh_lock_collar);
    mybuttons += CheckBox("No Open", kh_disable_openaccess);
    mybuttons += CheckBox("Pub. Key", kh_public_key);
    mybuttons += CheckBox("Main Menu", kh_main_menu);
    mybuttons += CheckBox("Global", g_iGlobalKey);
//    mybuttons += CheckBox("Lockout", kh_lockout);
    mybuttons += [ "Auto Return" ];

    g_keyConfigMenuID = Dialog(keyID, prompt, mybuttons, [UPMENU], 0, iAuth);
}




//===============================================================================
TakeKey(key avatar, integer auth, integer remote)
{
    if (!kh_on)
    {
        Notify(avatar, "This module is turned off by an Owner.", FALSE);
        return;
    }

    if (!remote && kh_range > 0.0 && llVecDist(llList2Vector(llGetObjectDetails(avatar, [OBJECT_POS]),0),llGetPos()) > kh_range)
    {
        Notify(avatar, "You are too far away to take " + llKey2Name(g_kWearer) + "'s key, you will have to move closer.", FALSE);
        return;
    }

    kh_key = avatar;
    kh_name = llKey2Name(avatar);
    kh_type = auth;

    kh_saved_openaccess = oc_openaccess;
    kh_saved_locked = oc_locked;

    setMainMenu();

    if (kh_disable_openaccess && oc_openaccess)
        llMessageLinked(LINK_THIS, COMMAND_OWNER, "unsetopenaccess", avatar);

    if (kh_lock_collar && !oc_locked)
        llMessageLinked(LINK_THIS, COMMAND_OWNER, "lock", avatar);

    if (avatar != g_kWearer) llMessageLinked(LINK_THIS, WEARERLOCKOUT, "on", "");

    if (kh_auto_return_timer && kh_auto_return_time)
    {
        integer minutes = (kh_auto_return_time / 60) % 60;
        integer hours = kh_auto_return_time / 60 / 60;

        // Set the timer. Real timer for now. Make it an option later.
        llMessageLinked(LINK_THIS, COMMAND_OWNER,
            "timer real=" + (string)hours + ":" + (string)minutes,
            NULL_KEY);
        llMessageLinked(LINK_THIS, COMMAND_OWNER, "timer start", NULL_KEY);
    }

    Notify(avatar, "You take " + llKey2Name(g_kWearer) + "'s key!", FALSE);
    Notify(g_kWearer, "Your key has been taken by " + llKey2Name(avatar) + "!", TRUE);

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
        llMessageLinked(LINK_THIS, COMMAND_OWNER, "setopenaccess", avatar);

    if (kh_lock_collar && !kh_saved_locked && oc_locked)
        llMessageLinked(LINK_THIS, COMMAND_OWNER, "unlock", avatar);

    // Need to check if someone else is doing this too... but really that should be handled by
    // the auth module somehow.
    llMessageLinked(LINK_THIS, WEARERLOCKOUT, "off", "");

    // Lockout canceled on key return
    kh_lockout = FALSE;

    if (kh_auto_return_timer && kh_auto_return_time)
    {
        llMessageLinked(LINK_THIS, COMMAND_OWNER, "timer stop", NULL_KEY);
    }

    Notify(avatar, llKey2Name(g_kWearer) + "'s key is returned. " + reason, FALSE);
    Notify(g_kWearer, "Your key has been returned. " + reason, TRUE);

    if (!remote && g_iGlobalKey)
        llWhisper(g_iKeyHolderChannel, llDumpList2String(["key", "return", (string)reason], ";") );

    updateVisible();

    saveSettings();
}

//===============================================================================
//
//===============================================================================
setMainMenu()
{
    llMessageLinked(LINK_THIS, MENUNAME_REMOVE, "Main" + "|" + RETURNKEY, NULL_KEY);
    llMessageLinked(LINK_THIS, MENUNAME_REMOVE, "Main" + "|" + TAKEKEY, NULL_KEY);

    if (kh_on && kh_main_menu)
    {
        if (kh_key != NULL_KEY)
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main" + "|" + RETURNKEY, NULL_KEY);
        else
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main" + "|" + TAKEKEY, NULL_KEY);
    }
}

//===============================================================================
//
//===============================================================================
setTimerMenu()
{
    llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_szTimerMenu + "|" + CheckBox("Return Key", kh_return_on_timer), NULL_KEY);
    llMessageLinked(LINK_THIS, MENUNAME_REMOVE, g_szTimerMenu + "|" + CheckBox("Return Key", !kh_return_on_timer), NULL_KEY);
}

//===============================================================================
//
//===============================================================================
updateVisible()
{
    integer show_key = FALSE;

    if (kh_key == NULL_KEY && kh_on)
    {
        if (oc_locked)
        {
            SetElementAlpha(1.0, g_lElementsLockedKey);
            SetElementAlpha(0.0, g_lElementsUnlockedKey);
            show_key = TRUE;
        }
        else
        {
            SetElementAlpha(0.0, g_lElementsLockedKey);
            SetElementAlpha(1.0, g_lElementsUnlockedKey);
            show_key = TRUE;
        }
    }
    else
    {
        SetElementAlpha(0.0, g_lElementsLockedKey);
        SetElementAlpha(0.0, g_lElementsUnlockedKey);
    }

    // Handle cuffs, if we are in Cuff mode.
    if (g_iOpenCuffMode)
    {
        llRegionSay(g_iInterfaceChannel,"rlac|*|khShowKey=" + (string)show_key + "|" + (string)g_kWearer);
    }
}

//===============================================================================
// State Saving
//===============================================================================
saveSettings()
{
    string out;
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + "list" + "=" +
        llDumpList2String([kh_on, Float2String(kh_range), kh_disable_openaccess, kh_lock_collar,
            kh_public_key, kh_main_menu, kh_return_on_timer, kh_auto_return_timer,
            kh_auto_return_time, g_iGlobalKey], ","), NULL_KEY);
}

loadSettings(string sSettings)
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
//= return        :   string     setting prefix from the description of the collar
//=
//= description  :    prefix from the description of the collar
//=
//===============================================================================


// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer num, string str, key id) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (num > COMMAND_EVERYONE || num < COMMAND_OWNER) return FALSE; // sanity check
    if (str == "menu " + g_szSubmenu) DoMenu(id, FALSE, num);
    else if ((id == g_kWearer || num == COMMAND_OWNER) && str == "resetscripts") llResetScript();
    else if (num == COMMAND_OWNER) // owner only stuff here
    {
        if (str == "menu " + g_szKeyConfigMenu) DoMenuConfigure(id, num);
        else if (llGetSubString(str, 0, 6) == "khtime " )
        {
            list times = llParseString2List(llDeleteSubString(str, 0,6), ["d", ":" ], []);
            kh_auto_return_time =
                ( (integer)llList2String(times, 0) * 24 * 60 * 60 ) + // days
                ( (integer)llList2String(times, 1) * 60 * 60 ) + // Hours
                ( (integer)llList2String(times, 2) * 60 ) + // Minutes
                ( (integer)llList2String(times, 3)  ) ; // Seconds
            kh_auto_return_timer = TRUE;
        }
        else if (str == "khsetautooff") kh_auto_return_timer = FALSE;
        else if (str == "khforcereturn")
        {
            if (kh_key == NULL_KEY) Notify(id, "The key is already in the lock.", FALSE);
            else
            {
                ReturnKey(llKey2Name(id) + " forced the return.", FALSE);
                Notify(id, "You force-return the key to the lock.", FALSE);
            }
        }
        else if (str == "khtimerreturn")
        {
            if (kh_key != NULL_KEY) ReturnKey("Key returned by timer.", FALSE);
        }
        else if (str == "khsetlock" || str == "khunsetlock")
        {
            kh_lock_collar = ( str == "khsetlock" );
        }
        else if (str == "khsetnoopen" || str == "khunsetnoopen")
        {
            kh_disable_openaccess = ( str == "khsetnoopen" );
        }
        else if (str == "khsetpub.key" || str == "khunsetpub.key")
        {
            kh_public_key = ( str == "khsetpub.key" );
        }
        else if (str == "khlockout")
        {
            if (kh_lockout) return TRUE;
            kh_lockout = TRUE;
            Notify(g_kWearer, "You are now locked out until your key is taken and returned.", TRUE);
            llMessageLinked(LINK_THIS, WEARERLOCKOUT, "on", "");
        }
        else if (str == "khsetmainmenu" || str == "khunsetmainmenu")
        {
            kh_main_menu = ( str == "khsetmainmenu" );
            setMainMenu();
        }
        else if (str == "khsetglobal" || str == "khunsetglobal")
        {
            g_iGlobalKey = ( str == "khsetglobal" );
        }
        else if (str == "khseton" || str == "khunseton")
        {
            kh_on = ( str == "khseton" );
            if (kh_key != NULL_KEY)
                ReturnKey("Key Holder plugin turned off by " + llKey2Name(id), FALSE);
            updateVisible();
        }
        else if (str == "khunsettimerreturnkey" || str == "khsettimerreturnkey")
        {
            kh_return_on_timer = ( str == "khsettimerreturnkey");
            setTimerMenu();
        }
    }
    // "Return Key" buttons from timer plugin.
    else if (str == "menu (*)Return Key")
    {
        UserCommand(num, "khunsettimerreturnkey", id);
        llMessageLinked(LINK_THIS, num, "menu "+ g_szTimerMenu, id);
    }
    else if (str == "menu ( )Return Key")
    {
        UserCommand(num, "khsettimerreturnkey", id);
        llMessageLinked(LINK_THIS, num, "menu "+ g_szTimerMenu, id);
    }
    // Take/Return key from the main menu
    else if (str == "menu " + TAKEKEY)
    {
        UserCommand(num, "khtakekey", id);
        llMessageLinked(LINK_THIS, num, "menu Main", id);
    }
    else if (str == "menu " + RETURNKEY)
    {
        UserCommand(num, "khreturnkey", id);
        llMessageLinked(LINK_THIS, num, "menu Main", id);
    }
    else if (str == "khreturnkey")
    {
        if (id == kh_key) ReturnKey("", FALSE);
        else Notify(id, "You are not the keyholder.", FALSE);
    }
    else if (str == "khtakekey")
    {
        if (kh_key != NULL_KEY) Notify(id, "The key is not in the lock.", FALSE);
        else TakeKey(id, num, FALSE);
    }
    // after here, only primary owner commands
    else if (llGetSubString(str, 0 ,1) != "kh") return FALSE;
    else return FALSE;
    saveSettings();
    return TRUE;
}

default
{
    state_entry()
    {
		g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        // sleep a second to allow all scripts to be initialized
        llSleep(1.0);
        // send request to main menu and ask other menus if they want to register with us
        //        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_szSubmenu, NULL_KEY);
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_szParentmenu + "|" + g_szSubmenu, NULL_KEY);
        g_kWearer=llGetOwner();
        updateVisible();

        BuildLockElementList(); // kc

        // Global Key
        llListen(g_iKeyHolderChannel, "", "", "");

        // Get us up to date.
        setMainMenu();
        setTimerMenu();
    }

    // reset the script if wearer changes. By only reseting on owner change only, we can keep our
    // configuration in the script itself as global variables without having to query cached settings.
    on_rez(integer param)
    {
        if (llGetOwner()!=g_kWearer)
            llResetScript();
        if ( kh_lockout || kh_key != NULL_KEY )
        {
            llSleep(5.); // wait for other scripts to reset
            llMessageLinked(LINK_THIS, WEARERLOCKOUT, "on", "");
        }
        updateVisible();
    }

    // listen for linked messages from OC scripts
    link_message(integer sender, integer num, string str, key id)
    {
        if (num == MENUNAME_REQUEST)
            // our parent menu requested to receive buttons, so send ours
        {
            if (str == g_szParentmenu)
                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_szParentmenu + "|" + g_szSubmenu, NULL_KEY);

            if (str == "Main") setMainMenu();
            else if (str == g_szTimerMenu) setTimerMenu();
        }
        else if(num == COMMAND_WEARERLOCKEDOUT)
        {
            // Do nothing, they are not allowed.
            if (str == "menu" && ( kh_key != NULL_KEY || kh_lockout ) )
            {
                if ( kh_key == NULL_KEY )
                    Notify(g_kWearer, "You are locked out of the " + g_sToyName + " until someone takes and returns your key.", TRUE);
                else Notify(g_kWearer, "You are locked out of the " + g_sToyName + " until your key is returned.", TRUE);
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
                llMessageLinked(LINK_THIS, COMMAND_GROUP, str, id);
            }
            else if (kh_key == NULL_KEY && str == "menu" && !oc_openaccess && kh_public_key)
            {
                DoMenu(id, TRUE, num);
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
                //integer page = (integer)llList2String(menuparams, 2);
                integer iAuth = (integer)llList2String(menuparams, 3);
                // request to change to parent menu
                if (message == UPMENU)
                {
                    if (id == g_keyMenuID)
                        llMessageLinked(LINK_THIS, iAuth, "menu "+g_szParentmenu, av);
                    else if (id == g_keyConfigMenuID)
                        DoMenu(av, FALSE, iAuth);
                    else if (id == g_keyConfigAutoReturnMenuID)
                        DoMenuConfigure(av, iAuth);
                }
                else if (message == "Configure")
                {
                    DoMenuConfigure(av, iAuth);
                }
                else if (message == "Auto Return")
                {
                    DoMenuAutoReturnConfig(av, iAuth);
                }
                else if (message == "Take Key")
                {
                    UserCommand(iAuth, "khtakekey", av);
                    DoMenu(av, FALSE, iAuth);
                }
                else if (message == "Lock Out")
                {
                    UserCommand(iAuth, "khlockout", av);
                    if (av != g_kWearer)
                        DoMenu(av, FALSE, iAuth);
                }
                else if (llGetListLength(llParseString2List(message, [":" ], [])) > 2)
                {
                    UserCommand(iAuth, "khtime "+llDeleteSubString(message,0,2), av);
                    DoMenuAutoReturnConfig(av, iAuth);
                }
                else
                {
                    // Handle checkboxes.
                    string cmd;
                    if (llGetSubString(message, 0, 2) == "( )")
                    {
                        cmd += "khset"+llGetSubString(message, 3, -1);
                    }
                    else if (llGetSubString(message, 0, 2) == "(*)")
                    {
                        cmd += "khunset" + llGetSubString(message, 3, -1);
                    }
                    // Remove spaces, lowercase
                    cmd = strReplace(cmd, " ", "");
                    cmd = llToLower(cmd);
                    // Handle the command
                    UserCommand(iAuth, cmd, av);
                    if (id == g_keyConfigMenuID) DoMenuConfigure(av, iAuth);
                    else if (id == g_keyConfigAutoReturnMenuID) DoMenuAutoReturnConfig(av, iAuth);
                }
            }
        }
        else if (num == LM_SETTING_RESPONSE || num == LM_SETTING_SAVE)
        {
            list params = llParseString2List(str, ["="], []);
            string token = llList2String(params, 0);
            string value = llList2String(params, 1);
            integer i = llSubStringIndex(token, "_");
            if (llGetSubString(token, 0, i) == g_sScript)
            {
                token = llGetSubString(token, i + 1, -1);
                if (token == "list") loadSettings(value);
            }
            else if (token == "auth_openaccess") oc_openaccess = (integer)value;
            else if (token == "Global_locked")
            {
                oc_locked = (integer)value;
                updateVisible();
            }
        }
        else if (num == LM_SETTING_DELETE)
        {
            if (str == "Global_locked")
            {
                oc_locked = FALSE;
                updateVisible();
            }
            else if (str == "auth_openaccess") oc_openaccess = FALSE;
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
            if (g_kWearer != llGetOwnerKey(id)) return; // Not for us.

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
