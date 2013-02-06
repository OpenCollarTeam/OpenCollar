//OpenCollar - rlvsit
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
string g_sParentMenu = "RLV";
string g_sSubMenu = "Sit";
string g_sDBToken = "rlvsit";


list g_lSettings;//2-strided list in form of [option, param]


list g_lRLVcmds = [
    "unsit",//may stand, if seated
    "sittp"//may sit 1.5M+ away
        ];

list g_lPrettyCmds = [ //showing menu-friendly command names for each item in g_lRLVcmds
    "Stand",
    "Sit"
        ];

list g_lDescriptions = [ //showing descriptions for commands
    "Ability to Stand If Seated",
    "Ability to Sit On Objects 1.5M+ Away"
        ];

//two of these commands take effect immediately and are not stored: force sit and force stand
//this list breaks tradition and is 3-strided, in form of cmd,prettyname,desc
list g_lIdmtCmds = [
    "sit","SitNow","Force Sit",
    "forceunsit","StandNow","Force Stand"
        ];


string TURNON = "Allow";
string TURNOFF = "Forbid";

key kMenuID;
key g_kSitID;

float g_fScanRange = 20.0;//range we'll scan for scripted objects when doing a force-sit
key g_kMenuUser;//used to remember who to give the menu to after scanning
integer g_iMenuAuth;//used to remember the auth level of that person

// Variables used for sit memory function
string  g_sSitTarget = "";
integer g_iSitMode;
integer g_iSitChan = 324590;    // Now randomized in state_entry
integer g_iSitListener;
float   g_fRestoreDelay = 1.0;
integer g_iRestoreCount = 0;
float   g_fPollDelay = 10.0;

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;

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

key g_kWearer;

integer g_iRLVOn=FALSE;

integer RandomChannel()
{
    return llRound(llFrand(10000000)) + 100000;
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

integer IsUnsitEnabled()
{
    integer iIndex = llListFindList(g_lSettings, ["unsit"]);
    string  sValue = llList2String(g_lSettings, iIndex + 1);

    if (sValue == "n")
        return 0;

    return 1;
}

ClearSitMemory()
{
    if (g_sSitTarget != "")
    {
        g_sSitTarget = "";
        //llOwnerSay("Sit memory cleared.");
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
        string desc = llList2String(g_lDescriptions, n);
        integer iIndex = llListFindList(g_lSettings, [sCmd]);

        if (iIndex == -1)
        {
            //if this cmd not set, then give button to enable
            lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
            sPrompt += "\n" + sPretty + " = Enabled (" + desc + ")";
        }
        else
        {
            //else this cmd is set, then show in prompt, and make button do opposite
            //get value of setting
            string sValue = llList2String(g_lSettings, iIndex + 1);
            if (sValue == "y")
            {
                lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
                sPrompt += "\n" + sPretty + " = Enabled (" + desc + ")";
            }
            else if (sValue == "n")
            {
                lButtons += [TURNON + " " + llList2String(g_lPrettyCmds, n)];
                sPrompt += "\n" + sPretty + " = Disabled (" + desc + ")";
            }
        }
    }

    //add immediate commands
    integer m;
    integer iImdtLength = llGetListLength(g_lIdmtCmds);
    for (m = 0; m < iImdtLength; m = m + 3)
    {
        lButtons += [llList2String(g_lIdmtCmds, m + 1)];
        sPrompt += "\n" + llList2String(g_lIdmtCmds, m + 1) + " = " + llList2String(g_lIdmtCmds, m + 2);
    }

    //give an Allow All button
    lButtons += [TURNON + " All"];
    lButtons += [TURNOFF + " All"];
    kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
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

list RestackMenu(list in)
{ //adds empty buttons until the list length is multiple of 3, to max of 12
    while (llGetListLength(in) % 3 != 0 && llGetListLength(in) < 12)
    {
        in += [" "];
    }
    //look for ^ and > in the menu
    integer u = llListFindList(in, [UPMENU]);
    if (u != -1)
    {
        in = llDeleteSubList(in, u, u);
    }
    //re-orders a list so dialog buttons start in the top row
    list sOut = llList2List(in, 9, 11);
    sOut += llList2List(in, 6, 8);
    sOut += llList2List(in, 3, 5);
    sOut += llList2List(in, 0, 2);
    //make sure we move ^ and > to position 1 and 2
    if (u != -1)
    {
        sOut = llListInsertList(sOut, [UPMENU], 1);
    }
    return sOut;
}

        
    
integer UserCommand(integer iNum, string sStr, key kID)
{
/* //no more needed -- SA: really? don't we need it back now? (3.7)
    else if ((sStr == "reset" || sStr == "runaway") && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
    {
        //clear db, reset script
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
        llResetScript();
    }
*/
    if (iNum < COMMAND_OWNER | iNum > COMMAND_WEARER) return FALSE;
    if (llToLower(sStr) == "sitmenu" || sStr == "menu " + g_sSubMenu) {Menu(kID, iNum); return TRUE;}
    else if (llToLower(sStr) == "sitnow")
    {
        if (!g_iRLVOn)
        {
            Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
            return TRUE;
        }
        //give menu of nearby objects that have scripts in them
        //this assumes that all the objects you may want to force your sub to sit on
        //have scripts in them
        g_kMenuUser = kID;
        g_iMenuAuth = iNum;
        llSensor("", NULL_KEY, SCRIPTED, g_fScanRange, PI);
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
        string sBehavior = llList2String(llParseString2List(sThisItem, ["=", ":"], []), 0);
        if (sStr == "unsit=force")
        {
            //this one's just weird
            //llOwnerSay("forcing stand");
            if (iNum == COMMAND_WEARER)
            {
                Notify(g_kWearer, "Sorry, but RLV commands may only be given by owner, secowner, or group (if set).", FALSE);
            }
            else
            {
                integer iIndex = llListFindList(g_lSettings, ["unsit"]); // Check for ability to unsit
                if (iIndex>=0)
                    if (llList2String(g_lSettings, iIndex + 1)!="n")
                        iIndex=-1;

                if (iIndex!=-1) // If standing is disabled
                    sStr="unsit=y,"+sStr+",unsit=n";

                llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
            }
        }
        else if (llListFindList(g_lRLVcmds, [sBehavior]) != -1)
        {
            //this is a behavior that we handle.
            //filter commands from wearer, if wearer is not owner
            if (iNum == COMMAND_WEARER)
            {
                Notify(g_kWearer, "Sorry, but RLV commands may only be given by owner, secowner, or group (if set).", FALSE);
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
        else if (llListFindList(g_lIdmtCmds, [sBehavior]) != -1)
        {
            //this is an immediate command that we handle
            //filter commands from wearer, if wearer is not owner
            if (iNum == COMMAND_WEARER)
            {
                Notify(g_kWearer, "Sorry, but RLV commands may only be given by owner, secowner, or group (if set).", FALSE);
                return TRUE;
            }
            llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
        }
        else if (sBehavior == "clear" && iNum == COMMAND_OWNER) ClearSettings();
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
        llSetTimerEvent(0.0);

        g_kWearer = llGetOwner();
        
        // Randomize the channel used to poll the client
        g_iSitChan = RandomChannel();
        
        g_iSitListener = llListen(g_iSitChan, "", "", "");
    }
    
    on_rez(integer iParam)
    {
        llSetTimerEvent(0.0);
    }

    timer()
    {
        // Nothing to do if RLV isn't enabled
        if (!g_iRLVOn)
            return;
        
        // If we are in memory mode...
        if (!g_iSitMode)
        {
            // ... we poll only if unsit is disabled and the avatar is sitting
            integer Sitting = llGetAgentInfo(g_kWearer) & AGENT_SITTING;
            
            if (IsUnsitEnabled() || (!Sitting))
            {
                ClearSitMemory();
                return;
            }
        }

        // No need for all the plugins etc to see this command so we send it directly
        llOwnerSay("@getsitid=" + (string)g_iSitChan);
    }

    listen(integer channel, string name, key id, string message)
    {
        // Restore mode
        if (g_iSitMode)
        {
            integer iIndex;
            string  sSittpValue;

            // Do we really have something to do ?
            if (g_sSitTarget == "")
            {
                g_iSitMode = 0;
                llSetTimerEvent(g_fPollDelay);
                return;
            }

            // Did we successfully resit the sub ?
            if (message == g_sSitTarget)
            {
                llOwnerSay("Sit Memory: Restored Forcesit on " + llKey2Name((key)g_sSitTarget));
                g_iSitMode = 0;
                llSetTimerEvent(g_fPollDelay);
                return;
            }

            // Count down retries...
            if (g_iRestoreCount > 0)
                g_iRestoreCount--;
            else
            {
                llOwnerSay("Sit Memory: Lucky day! All attempts at restoring forcesit failed, giving up.");
                g_iSitMode = 0;
                llSetTimerEvent(g_fPollDelay);
                return;
            }

            // Save the value of sittp as we need to temporarily enable it for forcesit
            iIndex = llListFindList(g_lSettings, ["sittp"]);
            sSittpValue = llList2String(g_lSettings, iIndex + 1);

            llMessageLinked(LINK_THIS, RLV_CMD, "sittp=y,sit:" + g_sSitTarget + "=force,sittp=" + sSittpValue, NULL_KEY);
        }
        else // Memory mode
        {
            if (message != g_sSitTarget)
            {
                key kSitKey = (key)message;

                if (kSitKey == NULL_KEY)
                    ClearSitMemory();
                else
                {
                    g_sSitTarget = message;
                    //llOwnerSay("Object " + llKey2Name(kSitKey) + " stored in sit memory, sitting will be restored after relogging.");
                }
            }
        }
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
            integer iChange = FALSE;
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
            // If we had something stored in memory, engage restore mode
            if ((!IsUnsitEnabled()) && (g_sSitTarget != ""))
            {
                llSetTimerEvent(g_fRestoreDelay);
                g_iRestoreCount = 20;
                g_iSitMode = 1;
            }
            else
            {
                llSetTimerEvent(g_fPollDelay);
                g_iSitMode = 0;
            }
        }
        else if (iNum == RLV_CLEAR)
        {
            //clear db and local settings list
            ClearSettings();
        }
        else if (iNum == RLV_OFF)        // rlvoff -> we have to turn the menu off too
        {
            g_iRLVOn=FALSE;
        }
        else if (iNum == RLV_ON)        // rlvon -> we have to turn the menu on again
        {
            g_iRLVOn=TRUE;
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (llListFindList([kMenuID, g_kSitID], [kID]) != -1)
            {//it's one of our menus
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);                
                integer iAuth = (integer)llList2String(lMenuParams, 3);                
                if (kID == kMenuID)
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    }
                    else
                    {
                        //if str == an immediate command, send cmd
                        //else if str == a stored command, do that
        
                        if (sMessage == "SitNow")
                        {
                            //give menu of nearby objects that have scripts in them
                            //this assumes that all the objects you may want to force your sub to sit on
                            //have scripts in them
                            g_kMenuUser = kAv;
                            g_iMenuAuth = iAuth;
                            llSensor("", NULL_KEY, SCRIPTED, g_fScanRange, PI);
                        }
                        else if (sMessage == "StandNow")
                        {
        
                            UserCommand(iAuth, "unsit=force", kAv);
                            Menu(kAv, iAuth);
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
                else if (kID == g_kSitID)
                {
                    if (sMessage==UPMENU)
                    {
                        Menu(kAv, iAuth);
                    }
                    else if ((key) sMessage)
                    {
                        UserCommand(iAuth, "sit:" + sMessage + "=force", kAv);
                        Menu(kAv, iAuth);
                    }                            
                }                 
            }
        }
    }

    sensor(integer iNum)
    {
        list lSitButtons = [];
        string sSitPrompt = "Pick the object on which you want the sub to sit.  If it's not in the list, have the sub move closer and try again.\n";
        //give g_kMenuUser a list of things to choose from
        integer n;
        for (n = 0; n < iNum; n ++)
        {
            //don't add things named "Object"
            if (llDetectedName(n) != "Object")
            {
                lSitButtons += [llDetectedKey(n)];
            }
        }

        g_kSitID = Dialog(g_kMenuUser, sSitPrompt, lSitButtons, [UPMENU], 0, g_iMenuAuth);
    }

    no_sensor()
    {
        //nothing close by to sit on, tell g_kMenuUser
        Notify(g_kMenuUser, "Unable to find sit targets.", FALSE);
    }
}