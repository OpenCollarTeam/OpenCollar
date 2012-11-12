//OpenCollar - rlvtp
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

//3.004 - adding "accepttp" support.  No button, just automatically turned on for owner.
//3.524+ - moving accepttp to the exception script.

key g_kLMID;//store the request id here when we look up  a LM

key kMenuID;
key lmkMenuID;

list g_lOwners;

string g_sParentMenu = "RLV";
string g_sSubMenu = "Map/TP";
string g_sDBToken = "rlvtp";

string g_sLatestRLVersionSupport = "1.15.1"; //the version which brings the latest used feature to check against
string g_sDetectedRLVersion;
list g_lSettings;//2-strided list in form of [option, param]

list g_lRLVcmds = [
    "tplm",
    "tploc",
    "tplure",
    "showworldmap",
    "showminimap",
    "showloc"
        ];

list g_lPrettyCmds = [ //showing menu-friendly command names for each item in g_lRLVcmds
    "LM",
    "Loc",
    "Lure",
    "Map",
    "Minimap",
    "ShowLoc"
        ];

list g_lDescriptions = [ //showing descriptions for commands
    "Teleport to Landmark",
    "Teleport to Location",
    "Teleport by Friend",
    "World Map",
    "Mini Map",
    "Current Location"
        ];

string TURNON = "Allow";
string TURNOFF = "Forbid";
string DESTINATIONS = "Destinations";

integer g_iRLVOn=TRUE;

key g_kWearer;

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
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "^";
//string MORE = ">";

Debug(string sMsg)
{
    //llOwnerSay(llGetScriptName() + ": " + sMsg);
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
    //    string sPrompt = "Pick an option";
    //    sPrompt += " (Menu will expire in " + (string)g_iTimeOut + " seconds.)";
    string sPrompt = "Current Settings: ";
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
        Debug((string)iIndex);
        if (iIndex == -1)
        {   //if this cmd not set, then give button to enable
            lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
            sPrompt += "\n" + sPretty + " = Enabled (" + sDesc + ")";
        }
        else
        {   //else this cmd is set, then show in prompt, and make button do opposite
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

    lButtons += [DESTINATIONS];

    //give an Allow All button
    lButtons += [TURNON + " All"];
    lButtons += [TURNOFF + " All"];
    Debug(sPrompt);
    Debug((string)llStringLength(sPrompt));
    //    lButtons += [UPMENU];
    //    lButtons = RestackMenu(lbuttons);
    //    menuchannel = -llRound(llFrand(9999999.0)) -99999;
    //    g_iListener = llListen(menuchannel, "", kID, "");
    //    llSetTimerEvent(g_iTimeOut);
    //    llDialog(kID, sPrompt, lButtons, menuchannel);
    kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

LandmarkMenu(key kAv, integer iAuth)
{
    list lButtons;
    //put all LMs button list, unless their sNames are >23 chars long, in which case complain
    integer n;
    integer iStop = llGetInventoryNumber(INVENTORY_LANDMARK);
    for (n = 0; n < iStop; n++)
    {
        string sName = llGetInventoryName(INVENTORY_LANDMARK, n);
        lButtons += [sName];
    }

    lmkMenuID = Dialog(kAv, "Pick a landmark to teleport to.", lButtons, [UPMENU], 0, iAuth);
}

integer AtLeastVersion(string sCutOff, string sCheckMe)
{//returns TRUE if sCheckMe is >= sCutOff, else FALSE.  Loops through major.minor.reallyminor versions ad nauseum to do compare
    //sCutOff and sCheckMe strings must have only numbers and dots.  No letters. ("1.15.5" is ok, "1.15c" is not)
    list lsCutOff = llParseString2List(sCutOff, ["."], []);
    list lsCheckMe = llParseString2List(sCheckMe, ["."], []);
    integer n;
    integer iStop = llGetListLength(lsCutOff);
    for (n = 0; n < iStop; n++)
    {
        integer iCheckPart = (integer)llList2String(lsCheckMe, n);
        integer iCutOffPart = (integer)llList2String(lsCutOff, n);
        if (iCheckPart < iCutOffPart)
        {
            return FALSE;
        }
        else if (iCheckPart > iCutOffPart)
        {
            return TRUE;
        }
    }
    return TRUE;
}

UpdateSettings()
{
    //build one big string from the settings list
    //llOwnerSay("TP settings: " + llDumpList2String(g_lSettings, ","));
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
    {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + llDumpList2String(g_lSettings, ","), NULL_KEY);
    }
    else
    {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
    }
}

ClearSettings()
{
    //clear settings list
    g_lSettings = [];
    //remove tpsettings from DB... now done by httpdb itself
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
    //main RLV script will take care of sending @clear to viewer
    //avoid race conditions
    llSleep(1.0);
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    if ((sStr == "reset" || sStr == "runaway") && (kID == g_kWearer || iNum == COMMAND_WEARER))
    {   //clear db, reset script
        //llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
        //llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sExToken, NULL_KEY);
        llResetScript();
    }
    if (sStr == "menu " + g_sSubMenu || llToLower(sStr) == "tp")
    {
        Menu(kID, iNum);
    }
    else if (llSubStringIndex(sStr, "tp ") == 0)
    {
        //we got a "tp" command with an argument after it.  See if it corresponds to a LM in inventory.
        list lParams = llParseString2List(sStr, [" "], []);
        string sDest = llToLower(llList2String(lParams, 1));
        integer i=0;
        integer m=llGetInventoryNumber(INVENTORY_LANDMARK);
        string s;
        integer found=FALSE;
        for (i=0;i<m;i++)
        {
            s=llGetInventoryName(INVENTORY_LANDMARK,i);
            if (sDest==llToLower(s))
            {
                //tp there
                //llOwnerSay("got a 'tp <landmark>'");
                g_kLMID = llRequestInventoryData(s);
                found=TRUE;
                }
        }
        if (!found)
        {
            Notify(kID,"The landmark '"+llList2String(lParams, 1)+"' has not been found in the collar of "+llKey2Name(g_kWearer)+".",FALSE);
        }
    }
    else
    {
        //do simple pass through for chat commands

        //since more than one RLV command can come on the same line, loop through them
        list items = llParseString2List(sStr, [","], []);
        integer n;
        integer iStop = llGetListLength(items);
        integer iChange = FALSE;//set this to true if we see a setting that concerns us
        for (n = 0; n < iStop; n++)
        {   //split off the parameters (anything after a : or =)
            //and see if the thing being set concerns us
            string sThisItem = llList2String(items, n);
            string sBehavior = llList2String(llParseString2List(sThisItem, ["=", ":"], []), 0);
            if (sBehavior == "tpto")
            {
                //if (iNum == COMMAND_WEARER)
                //{
                //    llInstantMessage(llGetOwner(), "Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                //    return;
                //}
                llMessageLinked(LINK_SET, RLV_CMD, sThisItem, NULL_KEY);
            }
            else if (llListFindList(g_lRLVcmds, [sBehavior]) != -1)
            {   //this is a behavior that we handle.
                //filter commands from wearer, if wearer is not owner
                if (iNum == COMMAND_WEARER)
                {
                    llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                    return TRUE;
                }

                string sOption = llList2String(llParseString2List(sThisItem, ["="], []), 0);
                if (sOption != sBehavior)
                {
                    return TRUE; //this keeps exceptions for tplure from getting set here if they are it is no problem just more data i nthe DB
                }
                string sParam = llList2String(llParseString2List(sThisItem, ["="], []), 1);
                integer iIndex = llListFindList(g_lSettings, [sOption]);
                if (iIndex == -1)
                {   //we don't alread have this exact setting.  add it
                    g_lSettings += [sOption, sParam];
                }
                else
                {   //we already have a setting for this option.  update it.
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

        //llSleep(1.0);
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sDBToken, NULL_KEY);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        //llOwnerSay("LinkMessage--iNum: " + (string)iNum + "sStr: " + sStr);
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
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sDBToken)
            {
                //throw away first element
                //everything else is real settings (should be even number)
                g_lSettings = llParseString2List(sValue, [","], []);
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
        else if (iNum == RLV_VERSION)
        {
            g_sDetectedRLVersion = sStr;
        }
        else if (iNum == RLV_OFF)         // rlvoff -> we have to turn the menu off too
        {
            g_iRLVOn=FALSE;
        }
        else if (iNum == RLV_ON)
        {
            g_iRLVOn=TRUE;
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == kMenuID)
            {
                Debug("dialog response: " + sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //if we got *Back*, then request submenu RLV
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

                        //loop through rlvcmds to create list
                        string sOut;
                        integer n;
                        integer iStop = llGetListLength(g_lRLVcmds);
                        for (n = 0; n < iStop; n++)
                        {
                            string cmd1 = llList2String(g_lRLVcmds, n);
                            //prefix all but the first sValue with a comma, so we have a comma-separated list
                            if (n)
                            {
                                sOut += ",";
                            }
                            sOut +=  cmd1 + "=" + ONOFF;
                        }
                        UserCommand(iAuth, sOut, kAv);
                        Menu(kAv, iAuth);
                    }
                    else if (sMessage == DESTINATIONS)
                    {
                        //give menu of LMs
                        LandmarkMenu(kAv, iAuth);
                    }
                    else if (iIndex != -1)
                    {
                        string sOut = llList2String(g_lRLVcmds, iIndex);
                        sOut += "=";
                        if (sSwitch == TURNON)
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
            else if (kID == lmkMenuID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //got a response to the LM menu.
                if (sMessage == UPMENU)
                {
                    Menu(kAv, iAuth);
                }
                else if (llGetInventoryType(sMessage) == INVENTORY_LANDMARK)
                {
                    UserCommand(iAuth, "tp " + sMessage, kAv);
                    LandmarkMenu(kAv, iAuth);
                }
            }
        }
    }

    dataserver(key kID, string sData)
    {
        if (kID == g_kLMID)
        {
            //we just got back LM data from a "tp " command.  now do a rlv "tpto" there
            vector vGoTo = (vector)sData + llGetRegionCorner();
            string sCmd = "tpto:";
            sCmd += llDumpList2String([vGoTo.x, vGoTo.y, vGoTo.z], "/");//format the destination in form x/y/z, as rlv requires
            sCmd += "=force";
            llMessageLinked(LINK_SET, RLV_CMD, sCmd, NULL_KEY);
        }
    }
}