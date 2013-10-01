////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - real leash                             //
//                                 version 0.200                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Real Leash Add-On - OpenCollar Version 3.7+
// Created by: Toy Wylie
// Version: 0.2
// Date: 03-Dec-2011
// Last edited by: Satomi Ahn

string VERSION="V0.2";
string HELP_NOTECARD="OpenCollar - Real Leash - User's Guide";

string g_sSubmenu = "Real Leash"; // Name of the submenu
string g_sParentmenu = "AddOns"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string g_sChatCommand = "realleash"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin
key g_kMenuID;  // menu handler
integer g_iDebugMode=FALSE; // set to TRUE to enable Debug messages

key g_kWearer; // key of the current wearer to reset only on owner changes

list g_lLocalbuttons = ["Help"]; // any local, not changing buttons which will be used in this plugin, leave empty or add buttons as you like

list g_lButtons;

string g_sRealLeashOn="*Switch On*";
string g_sRealLeashOff="*Switch Off*";
string g_sRealLeashSaveToken="realleash";

list g_lRestrictionList=
[
    "Touch","fartouch",
    "Sit","sittp",
    "LM","tplm",
    "Lure","tplure",
    "Loc","tploc"
];
list g_lRestrictions=[];
string g_sAllowAll;

string g_sAll="All";
string g_sForbid="Forbid";
string g_sAllow="Allow";

integer g_iRealLeashOn=FALSE;
integer g_iRLVOn=FALSE;     // To store if RLV was enabled in the collar
integer g_iLeashed=FALSE;   // To store if the wearer is leashed

key g_kLeashHolder=NULL_KEY;    // for teleport exception
key g_kOwner=NULL_KEY;          // for teleport exception

// for leashto command and target picked by menu
string TOK_DEST = "leashedto"; // format: uuid,rank

//OpenCollar MESSAGE MAP
// messages for authenticating users
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
//integer COMMAND_EVERYONE = 504;
//integer CHAT = 505;//deprecated
//integer COMMAND_OBJECT = 506;
//integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;
//integer COMMAND_BLACKLIST = 520;
// added for timer so when the sub is locked out they can use postions
//integer COMMAND_WEARERLOCKEDOUT = 521;
integer COMMAND_PARTICLE     = 20000;


//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bit of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;

// messages for storing and retrieving values from http db
integer HTTPDB_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer HTTPDB_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer HTTPDB_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer HTTPDB_DELETE = 2003;//delete token from DB
//integer HTTPDB_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

// same as HTTPDB_*, but for storing settings locally in the settings script
integer LOCALSETTING_SAVE = 2500;
integer LOCALSETTING_REQUEST = 2501;
integer LOCALSETTING_RESPONSE = 2502;
integer LOCALSETTING_DELETE = 2503;
//integer LOCALSETTING_EMPTY = 2504;


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
integer RLV_ON = 6101; // sent to inform plugins that RLV is enabled now, no sMessage or key needed
integer RLV_OFF = 6100; // sent to inform plugins that RLV is disabled now, no sMessage or key needed

// messages for poses and couple anims
//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
//integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
//integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
//integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
//integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av


// menu option to go one step back in menustructure
string UPMENU = "^";//when your menu hears this, give the parent menu

//===============================================================================
//= parameters   :    string    sMsg    message string received
//=
//= return        :    none
//=
//= description  :    output debug messages
//=
//===============================================================================


Debug(string sMsg)
{
    if (!g_iDebugMode) return;
    llOwnerSay(llGetScriptName() + ": " + sMsg);
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
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

//===============================================================================
//= parameters   :    none
//=
//= return        :    key random uuid
//=
//= description  :    random key generator, not complety unique, but enough for use in dialogs
//=
//===============================================================================


key ShortKey()
{//just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sChars = "0123456789abcdef";
    integer iLength = 16;
    string sOut;
    integer n;
    for (n = 0; n < 8; n++)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString(sChars, iIndex, iIndex);
    }

    return (key)(sOut + "-0000-0000-0000-000000000000");
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
    key kID = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`")+"|"+(string) iAuth, kID);
    return kID;
}

//===============================================================================
//= parameters   :    string    sMsg    message string received
//=
//= return        :    integer TRUE/FALSE
//=
//= description  :    checks if a string begin with another string
//=
//===============================================================================

integer nStartsWith(string sHaystack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return (llDeleteSubString(sHaystack, llStringLength(sNeedle), -1) == sNeedle);
}

//===============================================================================
//= parameters   :    string    keyID   key of person requesting the menu
//=
//= return        :    none
//=
//= description  :    build menu and display to user
//=
//===============================================================================

DoMenu(key kAv, integer iAuth)
{
    string sPrompt = "Real Leash Version "+VERSION+".\n\n";
    list lMyButtons = g_lLocalbuttons + g_lButtons;

    //fill in your button list and additional prompt here

    // Show the button for switching the Real Leash on and off
    if (g_iRealLeashOn==TRUE)
    {
        lMyButtons = g_sRealLeashOff + lMyButtons;
        sPrompt += "Real Leash is active";
    }
    else
    {
        lMyButtons = g_sRealLeashOn + lMyButtons;
        sPrompt += "Real Leash is NOT active";
    }

    // Add restriction list if the add-on is enabled and the wearer unleashed
    if((g_iRealLeashOn && !g_iLeashed) || kAv!=g_kWearer)
    {
        integer pos;
        string name;
        integer index;
        for(index=0;index<(llGetListLength(g_lRestrictionList));index+=2)
        {
            name=llList2String(g_lRestrictionList,index);
            pos=llListFindList(g_lRestrictions,[llList2String(g_lRestrictionList,index+1)]);
            if(pos==-1)
                name=g_sForbid+" "+name;
            else
                name=g_sAllow+" "+name;
            lMyButtons+=[name];
        }
        lMyButtons+=[g_sForbid+" "+g_sAll,g_sAllow+" "+g_sAll];
    }

    sPrompt += "\n";

    if(g_iRLVOn==FALSE)
    {
        sPrompt+="RLV support is OFF, so Real Leash will not work properly.\n";
    }

    // and dispay the menu
    g_kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

ForbidAll()
{
    g_lRestrictions = [];
    integer index;
    for (index=0; index < llGetListLength(g_lRestrictionList); index += 2)
    {
        g_lRestrictions += llList2String(g_lRestrictionList, index + 1);
    }
}

CheckMenuButton(string sMessage, key kAv, integer iAuth)
{
    Debug("Checking for " + sMessage);

    if (sMessage == g_sForbid + " " + g_sAll)
    {
        ForbidAll();
    }
    else if(sMessage == g_sAllow + " " + g_sAll)
    {
        g_lRestrictions = [];
    }
    else
    {
        integer pos = llSubStringIndex(sMessage," ");
        if (pos == -1)
            return;

        string action = llGetSubString(sMessage, 0, pos - 1);
        string name = llGetSubString(sMessage, pos + 1, -1);

        pos = llListFindList(g_lRestrictionList, [name]);
        if (pos == -1)
            return;
        string behav = llList2String(g_lRestrictionList, pos + 1);

        if (action == g_sAllow)
        {
            pos = llListFindList(g_lRestrictions, [behav]);
            if (pos != -1 )
                g_lRestrictions = llDeleteSubList(g_lRestrictions, pos, pos);
        }
        else if (action == g_sForbid)
        {
            pos = llListFindList(g_lRestrictions, [behav]);
            if (pos == -1 )
                g_lRestrictions += [behav];
        }
    }
    // save the new settings
    SaveRealLeashSettings();
 
    // update restrictions
    DoRLV(g_sAllowAll);
    ApplyRestrictions(g_iLeashed);

    // and restart the menu
    DoMenu(kAv, iAuth);
    Debug(llDumpList2String(g_lRestrictions, ","));
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

DoRLV(string commands)
{
    Debug("RLV: " + commands);
    llMessageLinked(LINK_SET, RLV_CMD, commands, NULL_KEY);
}

SetOwner(key k)
{
    // don't do anything if the owner hasn't changed
    if (k == g_kOwner)
        return;

    Debug("Owner is now: " + (string) k);

    // only remove the @tplure exception if the former owner is
    // not the leash holder
    if (g_kOwner != g_kLeashHolder)
        DoRLV("tplure:" + (string) g_kOwner + "=rem");

    if (k != NULL_KEY)
        DoRLV("tplure:" + (string) k + "=add");

    g_kOwner = k;
}


SetLeashHolder(key k)
{
    // don't do anything if the leash holder hasn't changed
    if (k == g_kLeashHolder)
        return;

    Debug("Leash holder is now: " + (string) k);

    DoRLV("tplure:" + (string) g_kLeashHolder + "=rem");

    if (llGetAgentSize(k) != ZERO_VECTOR && k != NULL_KEY)
    {
        DoRLV("tplure:" + (string) k + "=add");
        // make sure that the owner can always use @tplure
        if (g_kOwner != NULL_KEY)
            DoRLV("tplure:" + (string) g_kOwner + "=add");
    }

    g_kLeashHolder = k;
}

ApplyRestrictions(integer yes)
{
    // don't spam the user if RLV is not used or Real Leash is off
    if (!g_iRLVOn || !g_iRealLeashOn)
        return;

    // do nothing if we have an empty restriction list
    if (g_lRestrictions == [])
        return;

    string commands;
    if(yes)
        commands = llDumpList2String(g_lRestrictions,"=n,") + "=n";
    else
    {
        commands = llDumpList2String(g_lRestrictions,"=y,") + "=y";
        SetLeashHolder(NULL_KEY);
    }

    DoRLV(commands);
}

SetRLV(integer yes)
{
    g_iRLVOn = yes;

    // if Real Leash is off, don't bother with restrictions
    if (!g_iRealLeashOn)
        return;

    // update restrictions
    ApplyRestrictions(g_iLeashed);
}

// save settings for the Real Leash on HTTP
SaveRealLeashSettings()
{
    llMessageLinked(LINK_THIS, HTTPDB_SAVE, g_sRealLeashSaveToken+"="+(string) g_iRealLeashOn + "|" + llDumpList2String(g_lRestrictions, ","), NULL_KEY);
}

// restore settings for the Real Leash from HTTP
RestoreRealLeashSettings(string values)
{
    list params = llParseString2List(values, ["|"], []);
    g_iRealLeashOn = (integer) llList2String(params, 0);
    string restrictions = llList2String(params, 1);
    g_lRestrictions = llParseString2List(restrictions, [","], []);

    if(g_iRealLeashOn)
        Notify(g_kWearer,"Real Leash add-on enabled.",FALSE);
    else
        Notify(g_kWearer,"Real Leash add-on disabled.",FALSE);
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));

    Debug("Command received: "+sCommand+": "+sValue);

    // So commands can accept a value
    if (sStr == "reset")
        // it is a request for a reset
    {
        if (iNum == COMMAND_WEARER || iNum == COMMAND_OWNER)
        {   //only owner and wearer may reset
            llResetScript();
        }
    }
    else if (sStr == g_sChatCommand || sStr == "menu " + g_sSubmenu)
        // an authorized user requested the plugin menu by typing the menu's chat command
    {
        DoMenu(kID, iNum);
    }
    else if (sCommand == "realleash")
    {
        if (sValue != "on" && sValue != "off")
        {
            Notify(kID,"Unknown option: '"+sValue+"'. The realleash command only understands the following options: on, off",FALSE);
            return TRUE;
        }

        if (sValue == "on")
        {
            g_iRealLeashOn=TRUE;
            if(g_iLeashed)
            {
                ApplyRestrictions(TRUE);
                // re-query leash holder
                llMessageLinked(LINK_SET, LOCALSETTING_REQUEST, "leashedto", NULL_KEY);
            }
            Notify(kID,"Real Leash enabled.",FALSE);
        }
        else
        {
            if (g_iLeashed)
            {
                if (iNum == COMMAND_WEARER)
                {
                    Notify(kID, "You can't disable Real Leash while leashed.",FALSE);
                    return TRUE;
                }
                ApplyRestrictions(FALSE);
            }
            g_iRealLeashOn=FALSE;
            Notify(kID,"Real Leash disabled.",FALSE);
        }

        // save status to central settings
        SaveRealLeashSettings();
    }
    return TRUE;
}

default
{
    state_entry()
    {
        // store key of wearer
        g_kWearer = llGetOwner();

        // Default is to apply all restrictions
        ForbidAll();

        // Create a static "Allow All" RLV string
        integer index;
        for (index=0; index < llGetListLength(g_lRestrictionList); index += 2)
        {
            if (g_sAllowAll != "")
                g_sAllowAll += ",";
            g_sAllowAll += llList2String(g_lRestrictionList, index + 1) + "=y";
        }

        // update sTokens for httpdb_skAving
        string s=GetDBPrefix();
        g_sRealLeashSaveToken = s + g_sRealLeashSaveToken;

        // sleep a second to allow all scripts to be initialized
        llSleep(1.0);
        // send request to main menu and ask other menus if they want to register with us
        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubmenu, NULL_KEY);
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentmenu + "|" + g_sSubmenu, NULL_KEY);
        llMessageLinked(LINK_SET, HTTPDB_REQUEST, g_sRealLeashSaveToken, NULL_KEY);
        // NOTE: shouldn't we ask for the DB-Prefixed value?
        llMessageLinked(LINK_SET, HTTPDB_REQUEST, "rlvon", NULL_KEY);
        llMessageLinked(LINK_SET, HTTPDB_REQUEST, "owner", NULL_KEY);
        llMessageLinked(LINK_SET, LOCALSETTING_REQUEST, "leashedto", NULL_KEY);
    }

    // reset the script if wearer changes. By only reseting on owner change we can keep most of our
    // configuration in the script itself as global variables, so that we don't loose anything in case
    // the httpdb server isn't available
    // Cleo: As per Nan this should be a reset on every rez, this has to be handled as needed, but be prepared that the user can reset your script anytime using the OC menus
    on_rez(integer iParam)
    {
        if (llGetOwner()!=g_kWearer)
        {
            // Reset if wearer changed
            llResetScript();
        }
    }


    // listen for linked messages from OC scripts
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentmenu)
            // our parent menu requested to receive buttons, so send ours
        {

            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentmenu + "|" + g_sSubmenu, NULL_KEY);
        }
        else if (iNum == MENUNAME_RESPONSE)
            // a button is sent to be added to a menu
        {
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubmenu)
            {//someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1)
                    // if the button isn't in our menu yet, then we add it
                {
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == COMMAND_SAFEWORD)
            // Safeword has been received, release any restricitions that should be released
        {
            ApplyRestrictions(FALSE);
        }
        else if (iNum == DIALOG_RESPONSE)
            // answer from menu system
            // careful, don't use the variable kID to identify the user, it is the UUID we generated when calling the dialog
            // you have to parse the answer from the dialog system and use the parsed variable kAv
        {
            if (kID == g_kMenuID)
            {
                //got a menu response meant for us, extract the values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                // request to switch to parent menu
                if (sMessage == UPMENU)
                {
                    //give av the parent menu
                    llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentmenu, kAv);
                }
                else if (~llListFindList(g_lLocalbuttons, [sMessage]))
                {
                    //we got a response for something we handle locally
                    if (sMessage == "Help")
                    {
                        // Deliver Help Notecard
                        if (llGetInventoryType(HELP_NOTECARD) == INVENTORY_NOTECARD)
                        {
                            llGiveInventory(kAv, HELP_NOTECARD);
                        }
                        else
                        {
                            // no notecard found, so give a short help text
                            Notify(kAv,"(Missing Notecard: '"+HELP_NOTECARD+"') Real Leash is an OpenCollar add-on that automatically sets a number of restrictions on your collar when you are leashed. This makes the experience more real, because you won't be able to teleport, sit on far away objects or touch anything that's not close to you. This add-oon requires RLV to work properly.",FALSE);
                            // and restart the menu
                            DoMenu(kAv, iAuth);
                        }
                    }
                }
                else if (~llListFindList(g_lButtons, [sMessage]))
                {
                    //we got a button which another plugin put into into our menu
                    llMessageLinked(LINK_THIS, iAuth, "menu " + sMessage, kAv);
                }
                else
                {
                    // handle everything else
                    if (sMessage == g_sRealLeashOn)
                    {
                        UserCommand(iAuth, "realleash on", kAv);
                        DoMenu(kID, iNum);

                    }
                    else if (sMessage == g_sRealLeashOff)
                    {
                        UserCommand(iAuth, "realleash off", kAv);
                        DoMenu(kID, iNum);
                    }
                    else
                    {
                        // check restriction buttons in the menu
                        CheckMenuButton(sMessage, kAv, iAuth);
                    }
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
            // timeout from menu system, you do not have to react on this, but you can
        {
            if (kID == g_kMenuID)
                // if you react, make sure the timeout is from your menu by checking the g_kMenuID variable
            {
                Debug("The user was to slow or lazy, we got a timeout!");
            }
        }
        // local setting changed
        else if (iNum == LOCALSETTING_RESPONSE || iNum == HTTPDB_RESPONSE)
        {
            // parse the answer
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            Debug("Local Setting or HTTPDB received: "+sToken+": "+sValue);

            if (sToken == "leashedto")
            {
                g_iLeashed = TRUE;
                ApplyRestrictions(TRUE);
                // uuid,rank
                SetLeashHolder((key) llGetSubString(sValue,0,35));
            }
            else if (sToken == g_sRealLeashSaveToken )
            {
                // restore settings
                RestoreRealLeashSettings(sValue);
            }
            // or check for specific values from the collar like "owner" (for owners) "secowners" (or secondary owners) etc
            else if (sToken == "rlvon")
            {
                // remember if RLV was enabled or disabled
                SetRLV((integer) sValue);
            }
            else if (sToken == "owner")
            {
                // remember if RLV was enabled or disabled
                SetOwner(llGetSubString(sValue,0,35));
            }
        }
        // A leash target picked by menu won't trigger a message,
        // so we have this workaround further here. But really,
        // it should trigger the message, so this needs to be
        // fixed in the leash script. We can simplify this code
        // when that's done.
        else if (iNum == LOCALSETTING_SAVE || iNum == HTTPDB_SAVE)
        {
            Debug("LOCALSETTING/HTTPDB_SAVE: "+sStr);
            // format: leashedto=uuid,rank
            list params=llParseString2List(sStr,["=",","],[]);
            string command=llList2String(params,0);
            if (command=="owner")
            {
                key k=(key) llList2String(params,1);
                SetOwner(k);
            }
            else if (command == TOK_DEST)
            {
                key k=(key) llList2String(params,1);

                Debug("leashto target found");
                // leash was tied to a person
                g_iLeashed=TRUE;
                ApplyRestrictions(TRUE);
                // check if we are leashed to a person
                SetLeashHolder(k);
            }
        }
        else if (iNum == LOCALSETTING_DELETE || iNum == HTTPDB_DELETE)
        {
            Debug("HTTPDB_DELETE: "+sStr);
            // format: command=uuid,param
            if (sStr=="owner")
            {
                SetOwner(NULL_KEY);
            }
            else if (sStr == TOK_DEST)
            {
                // leash was removed
                g_iLeashed=FALSE;
                ApplyRestrictions(FALSE);                
            }
        }
        else if (iNum == RLV_OFF)
        {
            // remember that RLV is not active
            SetRLV(FALSE);
        }
        else if (iNum == RLV_ON)
        {
            // remember that RLV is active
            SetRLV(TRUE);
        }
    }
}