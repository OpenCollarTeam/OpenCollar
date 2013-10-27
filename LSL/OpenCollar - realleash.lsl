////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - realleash                              //
//                                 version 3.934                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Real Leash Add-On - OpenCollar Version 3.7+/3.9+
// Created by: Toy Wylie
// Date: 03-Dec-2011
// Last edited by: Satomi Ahn

//modified by: Zopf Resident - Ray Zopf (Raz)
//Additions: cosmetic+indent changes, changes on save settings, reflect changes in rlvmain_on and leash_leashto, etc.
//08. Okt 2013 v0.351
//
//Files:
//OpenCollar - realleash.lsl
//
//Prequisites: OC, RLV enabled
//Notecard format: ---
//basic help:

//bug: ???
//bug: does not get message that leash is enabled, check if fixed
//bug: restrictions get applied at reallesh "on" ... check... maybe restrictions only struck by unknown reason - caue: renaming script while restrictions were still applied?

//todo: check ApplyRestrictions() (yes, rlvcommand=n)
//todo: RLV support is OFF, so Real Leash will not work properly. ?!!!!; rlvmain=on~1;   else if (sToken == "rlvmain_on") //double check if that is correct now!!!!!
//todo: check if settings are stored correctly / defaultsettings NC
//todo: check RLV: tplure:00000000-0000-0000-0000-000000000000=rem
//todo: check applyrestrictions () - dorvl(allowall), as this is only done once
//todo: check real leash -x: settings delete: garble_Binder; saves everyting on 2002?!
///////////////////////////////////////////////////////////////////////////////////////////////////



//===============================================
//FIRESTORM SPECIFIC DEBUG STUFF
//===============================================

//#define FSDEBUG
//#include "fs_debug.lsl"


//===============================================
//GLOBAL VARIABLES
//===============================================

//debug variables
//-----------------------------------------------

integer g_iDebugMode=FALSE; // set to TRUE to enable Debug messages


//user changeable variables
//-----------------------------------------------


//internal variables
//-----------------------------------------------

//ADDON SETUP
string VERSION="V0.352";
string HELP_NOTECARD="OpenCollar - Real Leash - User's Guide";

//menu labels
string g_sSubmenu = "RealLeash"; // Name of the submenu
string g_sParentmenu = "AddOns"; // name of the menu, where the menu plugs in, should be usually Addons. Please do not use the mainmenu anymore
string g_sChatCommand = "realleash"; // every menu should have a chat command, so the user can easily access it by type for instance *plugin
key g_kMenuID;  // menu handler

list g_lLocalbuttons = ["Help"]; // any local, not changing buttons which will be used in this plugin, leave empty or add buttons as you like
list g_lButtons;

string g_sRealLeashOn="*Switch On*";
string g_sRealLeashOff="*Switch Off*";
string g_sScript;


//rlv settings
//list of possible restrictions
list g_lRestrictionList= 
    [
    "Touch","fartouch",
    "Sit","sittp",
    "LM","tplm",
    "Lure","tplure",
    "Loc","tploc"
        ];
list g_lRestrictions=[];
string g_sAllowAll="fartouch=y,sittp=y,tplm=y,tplure=y,tploc=y";
list g_lForbidAll=["fartouch","sittp","tplm","tplure","tploc"];
string g_sAll="All";
string g_sForbid="Forbid";
string g_sAllow="Allow";

integer g_iRealLeashOn=FALSE; //default is Real-Leash OFF
integer g_iRLVOn=FALSE;     // To store if RLV was enabled in the collar
integer g_iLeashed=FALSE;   // To store if the wearer is leashed

key g_kWearer; // key of the current wearer to reset only on owner changes
key g_kLeashHolder=NULL_KEY;    //needed for teleport exception for Owner/LeashHolder
key g_kOwner=NULL_KEY;          //needed for teleport exception

// for leashto command and target picked by menu, strings from other oc scripts
string TOK_DEST = "leash_leashedto"; // format: uuid,rank
string RLV_STRING = "rlvmain_on";
string OWNER_STRING = "auth_owner";


//OC MESSAGE MAP
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

//replacement for HTTDB_ and LOCALSETTINGS_ constants
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the store
integer LM_SETTING_REQUEST_NOCACHE = 2005;

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
string UPMENU = "BACK";//when your menu hears this, give the parent menu
//string UPMENU = "^";//old; when your menu hears this, give the parent menu


//===============================================
//PREDEFINED FUNCTIONS
//===============================================


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
    Notify(g_kWearer,llGetScriptName() + ": " + sMsg,TRUE);
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
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
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
    for (n = 0; n < 8; n++) {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString(sChars, iIndex, iIndex);
    } 
    Debug("ShortKey generation");
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
//= parameters   :    string    keyID   key of person requesting the menu
//=
//= return        :    none
//=
//= description  :    build menu and display to user
//=
//===============================================================================

DoMenu(key kAv, integer iAuth)
{
    Debug("DoMenu...");
    string sPrompt = "Real Leash Version "+VERSION+".\n\n";
    list lMyButtons = g_lLocalbuttons + g_lButtons;

    //fill in your button list and additional prompt here
    
    // Show the button for switching the Real Leash on and off
    if (g_iRealLeashOn==TRUE) {
        lMyButtons = g_sRealLeashOff + lMyButtons;
        sPrompt += "Real Leash is active";
    } else {
        lMyButtons = g_sRealLeashOn + lMyButtons;
        sPrompt += "Real Leash is NOT active";
    }

    // Add restriction list if the add-on is enabled and the wearer unleashed
    if((g_iRealLeashOn && !g_iLeashed) || kAv!=g_kWearer) {
        integer pos;
        string name;
        integer index;
        for(index=0;index<(llGetListLength(g_lRestrictionList));index+=2) {
            name=llList2String(g_lRestrictionList,index);
            pos=llListFindList(g_lRestrictions,[llList2String(g_lRestrictionList,index+1)]);
            if(pos==-1) name=g_sForbid+" "+name;
                else    name=g_sAllow+" "+name;
            lMyButtons+=[name];
        }
        lMyButtons+=[g_sForbid+" "+g_sAll,g_sAllow+" "+g_sAll];
    }
    sPrompt += "\n";
    if(g_iRLVOn==FALSE) {
        sPrompt+="RLV support is OFF, so Real Leash will not work properly.\n";
    }

    // and dispay the menu
    g_kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}


CheckMenuButton(string sMessage, key kAv, integer iAuth)
{
    Debug("Checking for " + sMessage);
    if (g_sForbid + " " + g_sAll == sMessage) g_lRestrictions = g_lForbidAll;
        else if(g_sAllow + " " + g_sAll == sMessage) g_lRestrictions = [];
            else {
                integer pos = llSubStringIndex(sMessage," ");
                if (pos == -1) return;

                string action = llGetSubString(sMessage, 0, pos - 1);
                string name = llGetSubString(sMessage, pos + 1, -1);

                pos = llListFindList(g_lRestrictionList, [name]);
                if (pos == -1) return;
                string behav = llList2String(g_lRestrictionList, pos + 1);

                if (action == g_sAllow) {
                    pos = llListFindList(g_lRestrictions, [behav]);
                    if (pos != -1 ) g_lRestrictions = llDeleteSubList(g_lRestrictions, pos, pos);
                } else if (action == g_sForbid) {
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


//most important functions
//-----------------------------------------------

DoRLV(string commands)
{
    Debug("RLV commands: " + commands);
    llMessageLinked(LINK_SET, RLV_CMD, commands, NULL_KEY);
}


SetOwner(key k)
{
    // don't do anything if the owner hasn't changed
    if (k == g_kOwner) return;

    Debug("Owner is now: " + (string) k +" - check RLV tplure exception");
    // only remove the @tplure exception if the former owner is
    // not the leash holder
    if (g_kOwner != g_kLeashHolder)    DoRLV("tplure:" + (string) g_kOwner + "=rem");
    if (k != NULL_KEY) DoRLV("tplure:" + (string) k + "=add");
    g_kOwner = k;
}


SetLeashHolder(key k)
{
    // don't do anything if the leash holder hasn't changed
    if (k == g_kLeashHolder) return;

    Debug("Leash holder is now: " + (string) k +" - check RLV tplure exception");
    DoRLV("tplure:" + (string) g_kLeashHolder + "=rem");
    if (llGetAgentSize(k) != ZERO_VECTOR && k != NULL_KEY) {
        DoRLV("tplure:" + (string) k + "=add");
        // make sure that the owner can always use @tplure
        if (g_kOwner != NULL_KEY) DoRLV("tplure:" + (string) g_kOwner + "=add");
    }
    g_kLeashHolder = k;
}


ApplyRestrictions(integer yesno)
{
    // don't spam the user if RLV is not used or Real Leash is off
    if (!g_iRLVOn || !g_iRealLeashOn) return;
    // do nothing if we have an empty restriction list
    if (g_lRestrictions == []) return;
    
    Debug("apply RLV?: "+ (string)yesno);
    list lNewList;
    string sTempRLVValue;
    if(yesno) {
        Debug("RLV-commands =n");
        sTempRLVValue = "=n";
    } else {
        Debug("RLV-commands =y");
        sTempRLVValue = "=y";
        SetLeashHolder(NULL_KEY);
    }
    integer i;
    integer number = llGetListLength(g_lRestrictions);
    for (i=1; i<=number; ++i) {
        lNewList+=[llList2String(g_lRestrictions, i-1)+sTempRLVValue];
    }
    string commands = llDumpList2String(lNewList, ",");
    Debug("commands aus ApplyRestrictions: "+commands);
    DoRLV(commands);
}


SetRLV(integer yes)
{
    g_iRLVOn = yes;
    // if Real Leash is off, don't bother with restrictions
    if (!g_iRealLeashOn) return;
    // update restrictions
    ApplyRestrictions(g_iLeashed);
}


// save settings for the Real Leash
SaveRealLeashSettings()
{
    Debug("Save settings");
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + "on=" + (string)g_iRealLeashOn, NULL_KEY);
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + "restrictions=" + llDumpList2String(g_lRestrictions, ","), NULL_KEY);
}


// restore settings for the Real Leash
RestoreRealLeashSettings(string token, string values, integer index)
{
    Debug("Restore settings -- check/debug delimeter: "+token+" - "+values);
    token = llGetSubString(token, index + 1, -1);
    Debug("token to restore: "+token);
    if ("on" == token) {
        if ("1" == values) {
            g_iRealLeashOn = TRUE;
            Notify(g_kWearer,"Real Leash add-on enabled.",FALSE);
        } else {
            g_iRealLeashOn = FALSE;
            Notify(g_kWearer,"Real Leash add-on disabled.",FALSE);
        }
    } else if ("restrictions" == token) g_lRestrictions = llParseString2List(llToLower(values), [","], []);
}


integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));

    Debug("Command received: "+sCommand+", value: "+sValue);

    // So commands can accept a value
//    if ("reset" == sStr)
        // it is a request for a reset
    if ("reset" == sStr && (iNum == COMMAND_WEARER || iNum == COMMAND_OWNER)) llResetScript();
    //only owner and wearer may reset
        else if (sStr == g_sChatCommand || "menu " + g_sSubmenu == sStr) DoMenu(kID, iNum);
        // an authorized user requested the plugin menu by typing the menu's chat command
            else if (sCommand == "realleash") {
                if (sValue != "on" && sValue != "off") {
                    Notify(kID,"Unknown option: '"+sValue+"'. The realleash command only understands the following options: on, off",FALSE);
                    return TRUE;
                }
                if (sValue == "on") {
                    Debug("debug: realleash turned on, leashed? "+(string)g_iLeashed);
                    g_iRealLeashOn=TRUE;
                    ApplyRestrictions(FALSE); //really needed?
                    if(g_iLeashed) {
                        // re-query leash holder
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, TOK_DEST, NULL_KEY);
                        Debug("chat-enabled realleash, wearer is leashed, apply restrictions");
                        ApplyRestrictions(TRUE);
                    }
                    Notify(kID,"Real Leash enabled.",FALSE);
                } else {
                    if (g_iLeashed) {
                        if (iNum == COMMAND_WEARER) {
                            Notify(kID, "You can't disable Real Leash while leashed.",FALSE);
                            return TRUE;
                        }
                    }
                    ApplyRestrictions(FALSE);
                    g_iRealLeashOn=FALSE;
                    Notify(kID,"Real Leash disabled.",FALSE);
                }
            // save status to central settings
            SaveRealLeashSettings();
            }
            Debug("End of UserCommand, settings saved");
    return TRUE;
}


//===============================================
//===============================================
//MAIN
//===============================================
//===============================================

default
{
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        // store key of wearer
        g_kWearer = llGetOwner();

        // Default is to use all restrictions
        g_lRestrictions = g_lForbidAll;
        
        // sleep a second to allow all scripts to be initialized
        llSleep(1.0);
        // send request to main menu and ask other menus if they want to register with us
        llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubmenu, NULL_KEY);
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentmenu + "|" + g_sSubmenu, NULL_KEY);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sScript, NULL_KEY);
        // NOTE: shouldn't we ask for the DB-Prefixed value?
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, RLV_STRING, NULL_KEY);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, OWNER_STRING, NULL_KEY);
        //debug !!!!
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, TOK_DEST, NULL_KEY);
    }

    // reset the script if wearer changes. By only reseting on owner change we can keep most of our
    // configuration in the script itself as global variables, so that we don't loose anything in case
    // the httpdb server isn't available
    // Cleo: As per Nan this should be a reset on every rez, this has to be handled as needed, but be prepared that the user can reset your script anytime using the OC menus
    on_rez(integer iParam)
    {
        if (llGetOwner()!=g_kWearer) llResetScript(); // Reset if wearer changed
    }

    //listen for linked messages from OC scripts
    //-----------------------------------------------

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        Debug("link_message: Sender = "+ (string)iSender + ", Num = "+ (string)iNum + ", string = " + (string)sStr +", ID = " + (string)kID);

        if (iNum == MENUNAME_REQUEST && sStr == g_sParentmenu) llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentmenu + "|" + g_sSubmenu, NULL_KEY);
        // our parent menu requested to receive buttons, so send ours
            else if (iNum == MENUNAME_RESPONSE) {
            // a button is sent to be added to a menu
                list lParts = llParseString2List(sStr, ["|"], []);
                if (llList2String(lParts, 0) == g_sSubmenu) { //someone wants to stick something in our menu
                    string button = llList2String(lParts, 1);
                    if (llListFindList(g_lButtons, [button]) == -1) g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                    // if the button isn't in our menu yet, then we add it
                }
            } else if (UserCommand(iNum, sStr, kID)) return;
                else if (iNum == COMMAND_SAFEWORD) ApplyRestrictions(FALSE);
                // Safeword has been received, release any restricitions that should be released
                    else if (iNum == DIALOG_RESPONSE) {
                    // answer from menu system
                    // careful, don't use the variable kID to identify the user, it is the UUID we generated when calling the dialog
                    // you have to parse the answer from the dialog system and use the parsed variable kAv
                        if (kID == g_kMenuID) {
                        //got a menu response meant for us, extract the values
                            list lMenuParams = llParseString2List(sStr, ["|"], []);
                            key kAv = (key)llList2String(lMenuParams, 0);
                            string sMessage = llList2String(lMenuParams, 1);
                            integer iPage = (integer)llList2String(lMenuParams, 2);
                            integer iAuth = (integer)llList2String(lMenuParams, 3);
                            // request to switch to parent menu
                            if (sMessage == UPMENU) llMessageLinked(LINK_THIS, iAuth, "menu " + g_sParentmenu, kAv);
                            //give av the parent menu
                                else if (~llListFindList(g_lLocalbuttons, [sMessage])) {
                                //we got a response for something we handle locally
                                    if (sMessage == "Help") {
                                    // Deliver Help Notecard
                                        if (llGetInventoryType(HELP_NOTECARD) == INVENTORY_NOTECARD) llGiveInventory(kAv, HELP_NOTECARD);
                                            else {
                                            // no notecard found, so give a short help text
                                                Notify(kAv,"(Missing Notecard: '"+HELP_NOTECARD+"') Real Leash is an OpenCollar add-on that automatically sets a number of restrictions on your collar when you are leashed. This makes the experience more real, because you won't be able to teleport, sit on far away objects or touch anything that's not close to you. This add-on requires RLV to work properly.",FALSE);
                                            // and restart the menu
                                                DoMenu(kAv, iAuth);
                                            }
                                    }
                                } else if (~llListFindList(g_lButtons, [sMessage])) llMessageLinked(LINK_THIS, iAuth, "menu " + sMessage, kAv);
                                //we got a button which another plugin put into into our menu
                                    else {
                                    // handle everything else
                                        if (sMessage == g_sRealLeashOn) {
                                            Debug("Realleash on pressed");
                                            UserCommand(iAuth, "realleash on", kAv);
                                            DoMenu(kAv, iAuth);
                                        } else if (sMessage == g_sRealLeashOff) {
                                            Debug("Realleash off pressed");
                                            UserCommand(iAuth, "realleash off", kAv);
                                            DoMenu(kAv, iAuth);
                                        } else CheckMenuButton(sMessage, kAv, iAuth);
                                        // check restriction buttons in the menu
                                    }
                        }
                    }
            else if (iNum == DIALOG_TIMEOUT) {
            // timeout from menu system, you do not have to react on this, but you can
                if (kID == g_kMenuID) {
                // if you react, make sure the timeout is from your menu by checking the g_kMenuID variable
                    Debug("The user was to slow or lazy, we got a timeout!");
                }
            } else if (iNum == LM_SETTING_RESPONSE) {
            // local setting changed
            //debug !!!
            // parse the answer
                list lParams = llParseString2List(sStr, ["="], []);
                string sToken = llList2String(lParams, 0);
                string sValue = llList2String(lParams, 1);
                integer i = llSubStringIndex(sToken, "_");

                Debug("parse settings: "+sToken+": "+sValue);

                if (sToken == TOK_DEST) {
                    SetLeashHolder((key) llGetSubString(sValue,0,35));
                    Debug("realleash now getting active");
                    g_iLeashed = TRUE;
                    ApplyRestrictions(TRUE);
                    // uuid,rank
                } else if (llGetSubString(sToken, 0, i) == g_sScript) {
                    //if (sToken == g_sScript) {
                    Debug("local settings changed, restore");
                    RestoreRealLeashSettings(sToken, sValue, i);
                    // restore settings
                    // or check for specific values from the collar like "owner" (for owners) "secowners" (or secondary owners) etc
                } else if (sToken == RLV_STRING) //double check if that is correct now!!!!!
                        // remember if RLV was enabled or disabled
                        SetRLV((integer) sValue);
                        else if (sToken == OWNER_STRING) SetOwner(llGetSubString(sValue,0,35));
                        // remember if RLV was enabled or disabled
            }

            // A leash target picked by menu won't trigger a message,
            // so we have this workaround further here. But really,
            // it should trigger the message, so this needs to be
            // fixed in the leash script. We can simplify this code
            // when that's done.

            //main leash detection code?

            else if (iNum == LM_SETTING_SAVE) {
                Debug("settings save: "+sStr);
                // format: leashedto=uuid,rank
                list params=llParseString2List(sStr,["=",","],[]);
                string command=llList2String(params,0);
                if (command==OWNER_STRING) {
                    key k=(key) llList2String(params,1);
                    SetOwner(k);
                } else if (command == TOK_DEST) {
                    key k=(key) llList2String(params,1);

                    Debug("leashto target found");
                    // leash was tied to a person
                    g_iLeashed=TRUE;

                    //debug here !!!
                    ApplyRestrictions(TRUE);
                    // check if we are leashed to a person
                    SetLeashHolder(k);
                }
            } else if (iNum == LM_SETTING_DELETE) {
                Debug("jump into settings delete: "+ (string)iNum+" - " +sStr);
                // format: command=uuid,param
                if (OWNER_STRING==sStr) SetOwner(NULL_KEY);
                    else if (sStr == TOK_DEST) {
                        // leash was removed
                        g_iLeashed=FALSE;
                        ApplyRestrictions(FALSE);
                    }
            } else if (iNum == RLV_OFF) SetRLV(FALSE);
            // remember that RLV is not active
                else if (iNum == RLV_ON) SetRLV(TRUE);
                // remember that RLV is active
    }
}