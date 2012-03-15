//OpenCollar - rlvmisc
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
string g_sParentMenu = "RLV";
string g_sSubMenu = "Misc";
string g_sDBToken = "rlvmisc";

list g_lSettings;//2-strided list in form of [option, param]

list g_lRLVcmds = [
    "shownames",
    "fly",
    "fartouch",
    "edit",
    "rez",
    "showinv",
    "viewnote",
    "viewscript",
    "viewtexture",
    "showhovertexthud",
    "showhovertextworld"
        ];

list g_lPrettyCmds = [ //showing menu-friendly command names for each item in g_lRLVcmds
    "Names",
    "Fly",
    "Touch",
    "Edit",
    "Rez",
    "Inventory",
    "Notecards",
    "Scripts",
    "Textures",
    "Hud",
    "World"
        ];

list g_lDescriptions = [ //showing descriptions for commands
    "See Avatar Names",
    "Ability to Fly",
    "Touch Objects 1.5M+ Away",
    "Edit Objects",
    "Rez Objects",
    "View Inventory",
    "View Notecards",
    "View Scripts",
    "View Textures",
    "See hover text from Hud objects",
    "See hover text from ojects in world"
        ];


string TURNON = "Allow";
string TURNOFF = "Forbid";

key kMenuID;

integer g_iRLVOn=FALSE; // make sure the rlv only gets activated 

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
//integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "^";
//string MORE = ">";

key g_kWearer;

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


Menu(key kID, integer iAuth)
{
    if (!g_iRLVOn)
    {
        Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
        llMessageLinked(LINK_SET, iAuth, "menu RLV", kID);
        return;
    }

    //build prompt showing current settings
    //make enable/disable buttons
    string sPrompt = "Pick an option";
    sPrompt += "\nCurrent Settings: ";
    list lButtons;


    integer n;
    integer iStop = llGetListLength(g_lRLVcmds);
    for (n = 0; n < iStop; n++)
    {
        //see if there's a setting for this in the settings list
        string sCmd = llList2String(g_lRLVcmds, n);
        string sPretty = llList2String(g_lPrettyCmds, n);
        string sDesc = llList2String(g_lDescriptions, n);
        integer iIndex = llListFindList(g_lSettings, [sCmd]);
        if (iIndex == -1)
        {
            //if this cmd not set, then give button to enable
            lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
            sPrompt += "\n" + sPretty + " = Enabled (" + sDesc + ")";
        }
        else
        {
            //else this cmd is set, then show in prompt, and make button do opposite
            //get value of setting
            string sValue = llList2String(g_lSettings, iIndex + 1);
            if (sValue == "y")
            {
                lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
                sPrompt += "\n" + sPretty + " = Enabled (" + sDesc + ")";
            }
            else if (sValue == "n")
            {
                lButtons += [TURNON + " " + llList2String(g_lPrettyCmds, n)];
                sPrompt += "\n" + sPretty + " = Disabled (" + sDesc + ")";
            }
        }
    }
    //give an Allow All button
    lButtons += [TURNON + " All"];
    lButtons += [TURNOFF + " All"];
    kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

UpdateSettings()
{
    //build one big string from the settings list
    //llOwnerSay("TP settings: " + llDumpList2String(settings, ","));
    integer iSettingsLength = llGetListLength(g_lSettings);
    if (iSettingsLength > 0)
    {
        list lTempSettings;
        string sTempRLVSetting;
        string sTempRLVValue;
        integer n;
        list lNewList;
        for (n = 0; n < iSettingsLength; n = n + 2)
        {
            sTempRLVSetting=llList2String(g_lSettings, n);
            sTempRLVValue=llList2String(g_lSettings, n + 1);
            lNewList += [ sTempRLVSetting+ "=" + sTempRLVValue];
            if (sTempRLVValue!="y")
            {
                lTempSettings+=[sTempRLVSetting,sTempRLVValue];
            }


        }
        //output that string to viewer
        llMessageLinked(LINK_SET, RLV_CMD, llDumpList2String(lNewList, ","), NULL_KEY);
        g_lSettings=lTempSettings;
    }
}

SaveSettings()
{
    //save to DB
    if (llGetListLength(g_lSettings)>0)
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + llDumpList2String(g_lSettings, ","), NULL_KEY);
    else
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
}

ClearSettings()
{
    //clear settings list
    g_lSettings = [];
    //remove tpsettings from DB
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
    //main RLV script will take care of sending @clear to viewer
}

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

integer UserCommand(integer iNum, string sStr, key kID)
{
/* //no more needed -- SA: really?
    else if ((sStr == "reset" || sStr == "runaway") && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
    {
        //clear db, reset script
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sExToken, NULL_KEY);
        llResetScript();
    }
*/
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    //added for chat command for direct menu acceess
    if (llToLower(sStr) == llToLower(g_sSubMenu) || sStr == "menu " + g_sSubMenu)
    {
        Menu(kID, iNum);
    }
    //do simple pass through for chat commands

    //since more than one RLV sCommand can come on the same line, loop through them
    list lItems = llParseString2List(sStr, [","], []);
    integer n;
    integer iStop = llGetListLength(lItems);
    integer iChange = FALSE;//set this to true if we see a setting that concerns us
    for (n = 0; n < iStop; n++)
    {
        //split off the parameters (anything after a : or =)
        //and see if the thing being set concerns us
        string sThisItem = llList2String(lItems, n);
        string sBehavior = llList2String(llParseString2List(sThisItem, ["=", ":"], []), 0);
        if (llListFindList(g_lRLVcmds, [sBehavior]) != -1)
        {
            //this is a behavior that we handle.

            //filter commands from wearer, if wearer is not owner
            if (iNum == COMMAND_WEARER)
            {
                Notify(g_kWearer,"Sorry, but RLV commands may only be given by owner, secowner, or group (if set).",FALSE);
                return TRUE;
            }

            string sOption = llList2String(llParseString2List(sThisItem, ["="], []), 0);
            string sParam = llList2String(llParseString2List(sThisItem, ["="], []), 1);
            integer iIndex = llListFindList(g_lSettings, [sOption]);
            if (iIndex == -1)
            {
                //we don't alread have this exact setting.  add it
                g_lSettings += [sOption, sParam];
            }
            else
            {
                //we already have a setting for this option.  update it.
                g_lSettings = llListReplaceList(g_lSettings, [sOption, sParam], iIndex, iIndex + 1);
            }

            iChange = TRUE;
        }
        else if (sBehavior == "clear" && iNum == COMMAND_OWNER)
        {
            ClearSettings();
        }
    }

    if (iChange)
    {
        UpdateSettings();
        SaveSettings();
    }
    return TRUE;
}

default
{
    on_rez(integer iParam)
    {
        llResetScript();
    }

    state_entry()
    {
        g_kWearer = llGetOwner();
        // llSleep(1.0);
        // llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sDBToken, NULL_KEY);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == LM_SETTING_RESPONSE)
        {
            //this is tricky since our db value contains equals signs
            //split string on both comma and equals sign
            //first see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            if (llList2String(lParams, 0) == g_sDBToken)
            {
                //throw away first element
                //everything else is real settings (should be even number)
                g_lSettings = llParseString2List(llList2String(lParams, 1), [","], []);
                UpdateSettings();
            }
            //llOwnerSay("TP DB settings: " + llDumpList2String(settings, ","));
        }
        else if (iNum == RLV_REFRESH)
        {
            //rlvmain just started up.  Tell it absOut our current restrictions
            g_iRLVOn = TRUE;
            UpdateSettings();
        }
        else if (iNum == RLV_CLEAR)
        {
            //clear db and local settings list
            ClearSettings();
        }
        // rlvoff -> we have to turn the menu off too
        else if (iNum == RLV_OFF) g_iRLVOn=FALSE;
        // rlvon -> we have to turn the menu on again
        else if (iNum == RLV_ON) g_iRLVOn=TRUE;
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == kMenuID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);                
                integer iAuth = (integer)llList2String(lMenuParams, 3);                
                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                }
                else
                {
                    list lParams = llParseString2List(sMessage, [" "], []);
                    string sSwitch = llList2String(lParams, 0);
                    string sCmd = llList2String(lParams, 1);
                    integer iIndex = llListFindList(g_lPrettyCmds, [sCmd]);
                    if (sCmd == "All")
                    {
                        //handle the "Allow All" and "Forbid All" sCommands
                        string ONOFF;
                        //decide whether we need to switch to "y" or "n"
                        if (sSwitch == TURNOFF)
                        {
                            //enable all functions (ie, remove all restrictions
                            ONOFF = "n";
                        }
                        else if (sSwitch == TURNON)
                        {
                            ONOFF = "y";
                        }
        
                        //loop through rlvcmds to create list
                        string sOut;
                        integer n;
                        integer iStop = llGetListLength(g_lRLVcmds);
                        for (n = 0; n < iStop; n++)
                        {
                            //prefix all but the first value with a comma, so we have a comma-separated list
                            if (n)
                            {
                                sOut += ",";
                            }
                            sOut += llList2String(g_lRLVcmds, n) + "=" + ONOFF;
                        }
                        UserCommand(iAuth, sOut, kAv);
                        Menu(kAv, iAuth);
                    }
                    else if (iIndex != -1)
                    {
                        string sOut = llList2String(g_lRLVcmds, iIndex);
                        sOut += "=";
                        if (llList2String(lParams, 0) == TURNON)
                        {
                            sOut += "y";
                        }
                        else if (llList2String(lParams, 0) == TURNOFF)
                        {
                            sOut += "n";
                        }
                        //send rlv command out through auth system as though it were a chat command, just to make sure person who said it has proper authority
                        UserCommand(iAuth, sOut, kAv);
                        Menu(kAv, iAuth);
                    }
                    else
                    {
                        //something went horribly wrong.  We got a command that we can't find in the list
                    }
                }
            }
        }
    }
}