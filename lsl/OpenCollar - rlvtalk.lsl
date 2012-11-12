//OpenCollar - rlvtalk
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
string g_sParentMenu = "RLV";
string g_sSubMenu = "Talk";
string g_sDBToken = "rlvtalk";

list g_lSettings;//2-strided list in form of [option, param]

list g_lRLVcmds = [
    "sendchat",
    "chatshout",
    "chatnormal",
    "startim",
    "sendim",
    "recvchat",
    "recvim",
    "emote",
    "recvemote"
        ];

list g_lPrettyCmds = [ //showing menu-friendly command names for each item in g_lRLVcmds
    "Chat",
    "Shouting",
    "Normal",
    "StartIM",
    "SendIM",
    "RcvChat",
    "RcvIM",
    "Emote",
    "RcvEmote"
        ];

list g_lDescriptions = [ //showing descriptions for commands
    "Ability to Send Chat",
    "Ability to Shout Chat",
    "Ability to Speak Without Whispering",
    "Ability to Start IM Sessions",
    "Ability to Send IM",
    "Ability to Receive Chat",
    "Ability to Receive IM",
    "Allowed length of Emotes",
    "Ability to Receive Emote"
        ];

string TURNON = "Allow";
string TURNOFF = "Forbid";

integer g_iRLVOn=FALSE;

key g_kWearer;
key g_kDialogID;

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

Debug(string sMsg)
{
    //llOwnerSay(llGetScriptName() + ": " + sMsg);
    //llInstantMessage(llGetOwner(), llGetScriptName() + ": " + sMsg);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    } else {
            llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
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
    //Debug(llDumpList2String(g_lSettings, ","));
    integer n;
    integer iStop = llGetListLength(g_lRLVcmds);

    //Default to hide emote, chatnormal(forced whisper) and chatshout(ability to shout).
    //If they are allowed, they will be set to TRUE in the following block
    integer iShowChatNormal  = FALSE;
    integer iShowChatShout   = FALSE;
    integer iShowEmote       = FALSE;
    if (llList2String(g_lSettings, (llListFindList(g_lSettings, ["sendchat"])+1)) == "n"){
        //Debug("hide chatshout and chatnormal");
        iShowEmote = TRUE;
    }
    else {
        //Debug("show chatnormal");
        iShowChatNormal = TRUE;

        if (llList2String(g_lSettings, (llListFindList(g_lSettings, ["chatnormal"])+1)) == "n"){
            //Debug("hide chatshout");
        }
        else {
            //Debug("show chatshout");
            iShowChatShout   = TRUE;
        }
    }
    //

    for (n = 0; n < iStop; n++)
    {
        //Check if current value should even be processed
        if (
             (llList2String(g_lRLVcmds, n) == "chatnormal" && !iShowChatNormal)
             ||
             (llList2String(g_lRLVcmds, n) == "chatshout" && !iShowChatShout)
             ||
             (llList2String(g_lRLVcmds, n) == "emote" && !iShowEmote)
           )
        {
            //Debug("skipping: "+llList2String(g_lRLVcmds, n));
        }
        else
        {
            //Process as usual....

            //see if there's a setting for this in the settings list
            string sCmd = llList2String(g_lRLVcmds, n);
            string sPretty = llList2String(g_lPrettyCmds, n);
            string sDesc = llList2String(g_lDescriptions, n);
            integer iIndex = llListFindList(g_lSettings, [sCmd]);

            if (iIndex == -1)
            {
                //if this cmd not set, then give button to enable
                if (sPretty=="Emote"){
                    //When sendchat='n' then emote defaults to short mode (rem), so you allow long emotes(add)......
                    sPrompt += "\n" + sPretty + " = Short (" + sDesc + ")";
                    lButtons += [TURNON + " " + llList2String(g_lPrettyCmds, n)];
                }
                else
                {
                    sPrompt += "\n" + sPretty + " = Enabled (" + sDesc + ")";
                    lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
                }
                
            }
            else
            {
                //else this cmd is set, then show in prompt, and make button do opposite
                //get value of setting
                string sValue1 = llList2String(g_lSettings, iIndex + 1);

                //For some odd reason, the emote command uses add (short;16 char max) and rem (no limit)
                if (sValue1 == "y" || (sPretty=="Emote" && sValue1 == "add"))
                {
                    {
                        if (sPretty=="Emote") {
                            sPrompt += "\n" + sPretty + " = Long (" + sDesc + ")";
                        }
                        else {
                            sPrompt += "\n" + sPretty + " = Enabled (" + sDesc + ")";
                        }
                        
                        lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
                    }
                }
                else if (sValue1 == "n" || (sPretty=="Emote" && sValue1 == "rem"))
                {
                    {
                        if (sPretty=="Emote") {
                            sPrompt += "\n" + sPretty + " = Short (" + sDesc + ")";
                        }
                        else {
                            sPrompt += "\n" + sPretty + " = Disabled (" + sDesc + ")";
                        }
                        
                        lButtons += [TURNON + " " + llList2String(g_lPrettyCmds, n)];
                    }
                }
            }
            //end process as usual
        }
    }
    //give an Allow All button
    lButtons += [TURNON + " All"];
    lButtons += [TURNOFF + " All"];
    g_kDialogID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

UpdateSettings()
{
    //build one big string from the settings list
    //llOwnerSay("TP g_lSettings: " + llDumpList2String(g_lSettings, ","));
    integer iSettingsLength = llGetListLength(g_lSettings);
    if (iSettingsLength > 0)
    {
        list lTempSettings;
        string sOut;
        integer n;
        list lNewList;
        for (n = 0; n < iSettingsLength; n = n + 2)
        {
            string sToken = llList2String(g_lSettings, n);
            string sValue = llList2String(g_lSettings, n + 1);

            if (sToken == "emote")
            {
                if (sValue == "y")
                {
                    sValue = "add";
                }
                else if (sValue == "n")
                {
                    sValue = "rem";
                }
            }

            lNewList += [sToken + "=" + sValue];
            if (sValue!="y")
            {
                lTempSettings+=[sToken,sValue];
            }
        }
        sOut = llDumpList2String(lNewList, ",");
        //output that string to viewer
        llMessageLinked(LINK_SET, RLV_CMD, sOut, NULL_KEY);
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

integer UserCommand(integer iNum, string sStr, key kID)
{
    /* //no more needed
        else if ((sStr == "reset" || sStr == "runaway") && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
        {
            //clear db, reset script
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sExToken, NULL_KEY);
            llResetScript();
        }
    */
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    if (sStr == "menu "+g_sSubMenu || llToLower(sStr) == "talk")
    {
        Menu(kID, iNum);
        return TRUE;
    }
    //do simple pass through for chat commands

    //since more than one RLV command can come on the same line, loop through them
    list lItems = llParseString2List(sStr, [","], []);
    integer n;
    integer iStop = llGetListLength(lItems);
    integer iChange = FALSE;//set this to true if we see a setting that concerns us
    for (n = 0; n < iStop; n++)
    {
        //split off the parameters (anything after a : or =)
        //and see if the thing being set concerns us
        string sThisItem = llList2String(lItems, n);
        string sBehavior = llList2String(llParseString2List(sThisItem, ["="], []), 0);//removed ":" as exceptions will pick it up now
        if (llListFindList(g_lRLVcmds, [sBehavior]) != -1)
        {
            //this is a behavior that we handle.

            //filter commands from wearer
            if (iNum == COMMAND_WEARER)
            {
                llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
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
    state_entry()
    {
        g_kWearer = llGetOwner();
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
        }
        else if (iNum == RLV_REFRESH)
        {
            //rlvmain just started up.  Tell it about our current restrictions
            g_iRLVOn = TRUE;
            UpdateSettings();
        }
        else if (iNum == RLV_CLEAR)
        {
            //clear db and local settings list
            ClearSettings();
        }
        else if (iNum == RLV_OFF)// rlvoff -> we have to turn the menu off too
        {
            g_iRLVOn=FALSE;
        }
        else if (iNum == RLV_ON)// rlvon -> we have to turn the menu on again
        {
            g_iRLVOn=TRUE;                
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == g_kDialogID)
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
                    //we got a command to enable or disable something, like "Enable LM"
                    //get the actual command name by looking up the pretty name from the message
                    list lParams = llParseString2List(sMessage, [" "], []);
                    string sSwitch = llList2String(lParams, 0);
                    string sCmd = llList2String(lParams, 1);
                    integer iIndex = llListFindList(g_lPrettyCmds, [sCmd]);
                    if (sCmd == "All")
                    {
                        //handle the "Allow All" and "Forbid All" commands
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
        
                        //loop through g_lRLVcmds to create list
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