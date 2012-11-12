//OpenCollar - rlvex
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

//********************
//stores owner info worng
//chekc default stornage
//fix names for people





///****************
//
/*
going to do a binary with exceptions default will be all on for owners
ability to change it for each owner
able to add other people.

will need a default settings for owners
list of people with settings
secowner settings

in the order of how they were added to the viewer
1.0:
tplure
1.01:
most chat

1.15:
accepttp

1,19:
recvemote

*/

key g_kLMID;//store the request id here when we look up  a LM

key g_kMenuID;
key g_kSensorMenuID;
key g_kPersonMenuID;
list g_lPersonMenu;
list g_lExMenus;
key lmkMenuID;
key g_kDialoger;
integer g_iDialogerAuth;
list g_lScan;

list g_lOwners;
list g_lSecOwners;

string g_sParentMenu = "RLV";
string g_sSubMenu = "Exceptions";
string g_sDBToken = "rlvex";
string g_sDBToken2 = "rlvexlist";

//statics to compare
integer OWNER_DEFUALT = 63;//1+2+4+8+16+32;//all on
integer SECOWNER_DEFUALT = 0;//all off


integer g_iOwnerDefault = 63;//1+2+4+8+16+32;//all on
integer g_iSecOwnerDefault = 0;//all off

string g_sLatestRLVersionSupport = "1.15.1"; //the version which brings the latest used feature to check against
string g_sDetectedRLVersion;
list g_lSettings;//2-strided list in form of [key, value]
list g_lNames;


list g_lRLVcmds = [
    "sendim",
    "recvim",
    "recvchat",
    "recvemote",
    "tplure",
    "accepttp"
        ];
        
list g_lBinCmds = [ //binary values for each item in g_lRLVcmds
    8,
    4,
    2,
    32,
    1,
    16
        ];

list g_lPrettyCmds = [ //showing menu-friendly command names for each item in g_lRLVcmds
    "IM",
    "RcvIM",
    "RcvChat",
    "RcvEmote",
    "Lure",
    "refuseTP"
        ];

list g_lDescriptions = [ //showing descriptions for commands
    "Restriction on Send IM",
    "Restriction on Receive IM",
    "Restriction on Receive Chat",
    "Restriction on Receive Emote",
    "Restriction on Teleport by Friend",
    "Sub able to refuse a tp offer"
        ];

string TURNON = "Exempt";
string TURNOFF = "Enforce";
string DESTINATIONS = "Destinations";

integer g_iRLVOn=FALSE;

key g_kWearer;

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave descripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//sStr must be in form of "token=value"
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

//string UPMENU = "?";
//string MORE = "?";
string UPMENU = "^";
//string MORE = ">";

Debug(string sMsg)
{
//    llOwnerSay(llGetScriptName() + ": " + sMsg);
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

Menu(key kID, string sWho, integer iAuth)
{
    if (!g_iRLVOn)
    {
        Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
        llMessageLinked(LINK_SET, iAuth, "menu RLV", kID);
        return;
    }
    
    list lButtons = ["Owner", "Secowners", "Other", "Add"];
    string sPrompt = "Set exceptions for the restrictions for RLV commands. Exceptions can be changed for owners, secowners and specific ones for other people. Add others with the \"Add\" button, use \"Other\" to set the specific restrictions for them later.";
    g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

PersonMenu(key kID, list lPeople, string sType, integer iAuth)
{
    if (iAuth != COMMAND_OWNER && kID != g_kWearer)
    {
        Menu(kID, "", iAuth);
        Notify(kID, "You are not allowed to see who is exempted.", FALSE);
        return;
    }
    //g_sRequestType = sType;
    string sPrompt = "Choose the person to change settings on.";
    list lButtons;
    //build a button list with the dances, and "More"
    //get number of secowners
    integer iNum= llGetListLength(lPeople);
    integer n;
    for (n=1; n <= iNum/2; n = n + 1)
    {
        string sName = llList2String(lPeople, 2*n-1);
        if (sName != "")
        {
            sPrompt += "\n" + (string)(n) + " - " + sName;
            lButtons += [(string)(n)];
        }
    }
    g_lPersonMenu = lPeople;
    g_kPersonMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

ExMenu(key kID, string sWho, integer iAuth)
{
    Debug("ExMenu for :"+sWho);
    if (!g_iRLVOn)
    {
        Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
        llMessageLinked(LINK_SET, iAuth, "menu RLV", kID);
        return;
    }
    integer iExSettings = 0;
    if (sWho == "owner")
    {
        iExSettings = g_iOwnerDefault;
    }
    else if (sWho == "secowners")
    {
        iExSettings = g_iSecOwnerDefault;
    }
    else if (llListFindList(g_lSettings, [sWho]) != -1)
    {
        iExSettings = llList2Integer(g_lSettings, llListFindList(g_lSettings, [sWho])+1);
    }
    else if (llListFindList(g_lOwners, [sWho]) != -1)
    {
        iExSettings = g_iOwnerDefault;
    }
    else if (llListFindList(g_lSecOwners, [sWho]) != -1)
    {
        iExSettings = g_iSecOwnerDefault;
    }
    
//    list lButtons = [];
//    string sPrompt = "This plug is in beta. Right now it set exceptions for all primary owners for all RLV cmds at all times. Later you will be  able to change them for owners, secowners and then set specific ones for other people.";
//    kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0);
// }

// /* use this later


    //build sPrompt showing s_Current settings
    //make enable/disable lButtons
    //    string sPrompt = "Pick an option";
    //    sPrompt += " (Menu will expire in " + (string)g_iTimeOut + " seconds.)";
    string sPrompt = "Defaults will remove all exceptions for this person if they are not an Owner or Secowner otherwise it will set them to the defaults.\nCurrent Settings: ";
    list lButtons;

    integer n;
    integer iStop = llGetListLength(g_lRLVcmds);
    for (n = 0; n < iStop; n++)
    {
        //see if there's a setting for this in the settings list
        string sCmd = llList2String(g_lRLVcmds, n);
        string sPretty = llList2String(g_lPrettyCmds, n);
        string sDesc = llList2String(g_lDescriptions, n);

        if (iExSettings & llList2Integer(g_lBinCmds, n))
        {
            lButtons += [TURNOFF + " " + llList2String(g_lPrettyCmds, n)];
            sPrompt += "\n" + sPretty + " = Exempted (" + sDesc + ")";
        }
        else
        {
            lButtons += [TURNON + " " + llList2String(g_lPrettyCmds, n)];
            sPrompt += "\n" + sPretty + " = Enforced (" + sDesc + ")";
        }
    }
    //give an Allow All button
    lButtons += [TURNON + " All"];
    lButtons += [TURNOFF + " All"];
    //add list button
    if (sWho == "owner")
    {
        lButtons += ["List"];
    }
    else if (sWho == "secowners")
    {
        lButtons += ["List"];
    }
    Debug(sPrompt);
    Debug((string)llStringLength(sPrompt));
    //    lButtons += [UPMENU];
    //    lButtons = RestackMenu(buttons);
    //    menuchannel = -llRound(llFrand(9999999.0)) -99999;
    //    g_iListener = llListen(menuchannel, "", kID, "");
    //    llSetTimerEvent(g_iTimeOut);
    //    llDialog(kID, sPrompt, lButtons, menuchannel);
    key kTmp = Dialog(kID, sPrompt, lButtons, ["Defaults", UPMENU], 0, iAuth);
    g_lExMenus = [kTmp, sWho] + g_lExMenus;
}
// */


UpdateSettings()
{
    //for now just redirect
    SetAllExs("");
}

SaveDefaults()
{
    //save to DB
    if (OWNER_DEFUALT == g_iOwnerDefault)
    {
        if (SECOWNER_DEFUALT == g_iSecOwnerDefault)
        {
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
            return;
        }
    }
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + llDumpList2String([g_iOwnerDefault, g_iSecOwnerDefault], ","), NULL_KEY);
}
SaveSettings()
{
    //save to local settings
    if (llGetListLength(g_lSettings)>0)
    {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken2 + "=" + llDumpList2String(g_lSettings, ","), NULL_KEY);
    }
    else
    {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken2, NULL_KEY);
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

MakeNamesList()
{
    g_lNames = [];
    integer iNum = llGetListLength(g_lSettings);
    integer n;
    for (n=0; n < iNum; n = n + 2)
    {
        string sKey = llList2String(g_lSettings, n);
        AddName(sKey);
    }
}
AddName(string sKey)
{
    integer iIndex = llListFindList(g_lOwners, [sKey]);
    if (iIndex != -1)
    {
        g_lNames += [sKey, llList2String(g_lOwners, iIndex+1)];
    }
    else
    {
        iIndex = llListFindList(g_lSecOwners, [sKey]);
        if (iIndex != -1)
        {
            g_lNames += [sKey, llList2String(g_lSecOwners, iIndex+1)];
        }
        else
        {
            //lookup and put the uuid for hte request in for now
            g_lNames += [sKey, (string)llRequestAgentData(sKey, DATA_NAME) ];
            llSleep(1);
        }
    }
}

SetOwnersExs(string sVal)
{
    if (!g_iRLVOn)
    {
        return;
    }
    integer iLength = llGetListLength(g_lOwners);
    if (iLength)
    {
        integer iStop = llGetListLength(g_lRLVcmds);
        integer n;
        integer i;
        list sCmd;
        for (n = 0; n < iLength; n += 2)
        {
            sCmd = [];
            string sTmpOwner = llList2String(g_lOwners, n);
            if (llListFindList(g_lSettings, [sTmpOwner]) != -1)
            { 
                for (i = 0; i<iStop; i++)
                {
                    if (g_iOwnerDefault & llList2Integer(g_lBinCmds, i) )
                    {
                        sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=n"];// +sVal];
                    }
                    else
                    {
                        sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=y"];// +sVal];
                    }
                }
                string sStr = llDumpList2String(sCmd, ",");
                //llOwnerSay("sending " + sStr);
                //llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
                llOwnerSay("@" + sStr);
            }
        }
    }
}

SetAllExs(string sVal)
{//llOwnerSay("allvars");
    if (!g_iRLVOn)
    {
        return;
    }
    integer iStop = llGetListLength(g_lRLVcmds);
    integer iLength = llGetListLength(g_lOwners);
    if (iLength)
    {
        integer n;
        integer i;
        list sCmd;
        for (n = 0; n < iLength; n += 2)
        {
            sCmd = [];
            string sTmpOwner = llList2String(g_lOwners, n);
            if (llListFindList(g_lSettings, [sTmpOwner]) == -1)
            { 
                for (i = 0; i<iStop; i++)
                {
                    if (g_iOwnerDefault & llList2Integer(g_lBinCmds, i) )
                    {
                        sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=n"];// +sVal];
                    }
                    else
                    {
                        sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=y"];// +sVal];
                    }
                }
                string sStr = llDumpList2String(sCmd, ",");
                //llOwnerSay("sending " + sStr);
                //llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
                llOwnerSay("@" + sStr);
            }
        }
    }
    iLength = llGetListLength(g_lSecOwners);
    if (iLength)
    {
        integer n;
        integer i;
        list sCmd;
        for (n = 0; n < iLength; n += 2)
        {
            sCmd = [];
            string sTmpOwner = llList2String(g_lSecOwners, n);
            if (llListFindList(g_lSettings, [sTmpOwner]) == -1)
            { 
                for (i = 0; i<iStop; i++)
                {
                    if (g_iSecOwnerDefault & llList2Integer(g_lBinCmds, i) )
                    {
                        sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=n"];// +sVal];
                    }
                    else
                    {
                        sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=y"];// +sVal];
                    }
                }
                string sStr = llDumpList2String(sCmd, ",");
                //llOwnerSay("sending " + sStr);
                //llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
                llOwnerSay("@" + sStr);
            }
        }
    }
    iLength = llGetListLength(g_lSettings);
    if (iLength)
    {
        integer n;
        integer i;
        list sCmd;
        for (n = 0; n < iLength; n += 2)
        {
            sCmd = [];
            string sTmpOwner = llList2String(g_lSettings, n);
            integer iTmpOwner = llList2Integer(g_lSettings, n+1);
            for (i = 0; i<iStop; i++)
            {
                if (iTmpOwner & llList2Integer(g_lBinCmds, i) )
                {
                    sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=n"];// +sVal];
                }
                else
                {
                    sCmd += [llList2String(g_lRLVcmds, i) + ":" + sTmpOwner + "=y"];// +sVal];
                }
            }
            string sStr = llDumpList2String(sCmd, ",");
            //llOwnerSay("sending " + sStr);
            //llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
            llOwnerSay("@" + sStr);
        }
    }
}
ClearEx()
{
    llOwnerSay("@clear=sendim:,clear=recvim:,clear=recvchat:,clear=recvemote:,clear=tplure:,clear=accepttp:");
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    if ((sStr == "reset" || sStr == "runaway") && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
    {   //clear db, reset script
        //llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
        //llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sExToken, NULL_KEY);
        //SetOwnersExs("rem"); // should not be needed
        llResetScript();
    }
    else if (llToLower(sStr) == "ex" || sStr == "menu " + g_sSubMenu) Menu(kID, "", iNum);
    else if (llToLower(sStr) == "ex " + "owner") ExMenu(kID, "owner", iNum);
    else if (llToLower(sStr) == "ex " + "secowners") ExMenu(kID, "secowners", iNum);
    else if (llToLower(sStr) == "ex " + "other") PersonMenu(kID, g_lNames, "", iNum);
    else
    {                //do simple pass through for chat commands

        //since more than one RLV command can come on the same line, loop through them
        list items = llParseString2List(sStr, [","], []);
        integer n;
        integer iStop = llGetListLength(items);
        integer iChange = FALSE;//set this to true if we see a setting that concerns us
        for (n = 0; n < iStop; n++)
        {   //split off the parameters (anything after a : or =)
            //and see if the thing being set concerns us
            string sThisItem = llList2String(items, n);
            list lParts = llParseString2List(sThisItem, ["=", ":"], []);
            string sBehavior = llList2String(lParts, 0);
            integer iRLVIndex = llListFindList(g_lRLVcmds, [sBehavior]);
            if (iRLVIndex != -1)
            {
                string sParam = llList2String(lParts, 2);
                if(sParam != "")
                {
                    //this is a behavior that we handle.
                    //filter commands from wearer, if wearer is not owner
                    if (iNum != COMMAND_OWNER)
                    {
                        llOwnerSay("Sorry, but RLV Exceptions commands may only be given by owner.");
                        return TRUE;
                    }
                    //chaing  for ex
                    string sWho = llList2String(lParts, 1);
                    integer iIndex = llListFindList(g_lSettings, [sWho]);
                    if (sParam == "n" || sParam == "add")
                    {
                        if (sWho == "owner")
                        {
                            g_iOwnerDefault = g_iOwnerDefault | llList2Integer(g_lBinCmds, iRLVIndex);
                            iChange = iChange | 1;
                        }
                        else if (sWho == "secowners")
                        {
                            g_iSecOwnerDefault = g_iSecOwnerDefault | llList2Integer(g_lBinCmds, iRLVIndex);
                            iChange = iChange | 1;
                        }
                        else if (iIndex == -1)
                        {   //we don't alread have this person with a setting so we can just set it equal to the value of the command
                            if((key)sWho)
                            {
                                g_lSettings = [sWho, llList2Integer(g_lBinCmds, iRLVIndex)] + g_lSettings;
                                AddName(sWho);//should add to name list
                                iChange = iChange | 2;
                            }
                        }
                        else
                        {   //we already have a setting for this option.  update it.
                            integer iTmp = llList2Integer(g_lSettings, iIndex + 1);
                            iTmp = iTmp | llList2Integer(g_lBinCmds, iRLVIndex);
                            g_lSettings = llListReplaceList(g_lSettings, [sWho, iTmp], iIndex, iIndex + 1);
                            iChange = iChange | 2;
                        }
                    }
                    else if (sParam == "y" || sParam == "rem")
                    {
                        if (sWho == "owner")
                        {
                            g_iOwnerDefault = g_iOwnerDefault & ~llList2Integer(g_lBinCmds, iRLVIndex);
                            iChange = iChange | 1;
                        }
                        else if (sWho == "secowners")
                        {
                            g_iSecOwnerDefault = g_iSecOwnerDefault & ~llList2Integer(g_lBinCmds, iRLVIndex);
                            iChange = iChange | 1;
                        }
                        else if (iIndex == -1)
                        {   //we don't alread have this person with a setting so we can just set it equal 0
                            //we will only get here if someone types it.
                            if((key)sWho)
                            {
                                integer iTmp = 0;
                                if (llListFindList(g_lOwners, [sWho]) == -1)
                                {
                                    iTmp = g_iOwnerDefault;
                                }
                                else if (llListFindList(g_lSecOwners, [sWho]) == -1)
                                {
                                    iTmp = g_iSecOwnerDefault;
                                }
                                iTmp = iTmp & ~llList2Integer(g_lBinCmds, iRLVIndex);
                                g_lSettings = [sWho, iTmp] + g_lSettings;
                                AddName(sWho);// add person to name list
                                iChange = iChange | 2;
                            }
                        }
                        else
                        {   //we already have a setting for this option.  update it.
                            integer iTmp = llList2Integer(g_lSettings, iIndex + 1);
                            iTmp = iTmp & ~llList2Integer(g_lBinCmds, iRLVIndex);
                            g_lSettings = llListReplaceList(g_lSettings, [sWho, iTmp], iIndex, iIndex + 1);
                            iChange = iChange | 2;
                        }
                    }
                    //iChange = TRUE;
                }
            }
            else if (sBehavior == "clear")
            {
                //ClearSettings();
                // do we wnat anything here this is for excpetions
            }
            else if (sBehavior == "defaults")
            {
                string sWho = llList2String(lParts, 1);
                if (sWho == "owner")
                {
                    g_iOwnerDefault = OWNER_DEFUALT;
                    iChange = iChange | 1;
                }
                else if (sWho == "secowners")
                {
                    g_iSecOwnerDefault = SECOWNER_DEFUALT;
                    iChange = iChange | 1;
                }
                else
                {
                    integer iIndex = llListFindList(g_lSettings, [sWho]);
                    Debug("SettingsIndex:"+(string)iIndex+" name:"+llList2String(g_lSettings, iIndex));
                    if (iIndex != -1)
                    {
                        g_lSettings = llDeleteSubList(g_lSettings, iIndex, iIndex + 1);
                        iIndex = llListFindList(g_lNames, [sWho]);
                        Debug("NamesIndex:"+(string)iIndex+" name:"+llList2String(g_lNames, iIndex));
                        g_lNames = llDeleteSubList(g_lNames, iIndex, iIndex + 1);//should remove the name from this list too
                        iChange = iChange | 2;
                    }
                }
            }
        }
        if (iChange)
        {
            UpdateSettings();
            if(iChange & 1) SaveDefaults();
            if(iChange & 2) SaveSettings();
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
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            //this is tricky since our stored value contains equals signs
            //split string on both comma and equals sign
            //first see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sDBToken)
            {
                list lTmp = llParseString2List(sValue, [","], []);
                g_iOwnerDefault = llList2Integer(lTmp, 0);
                g_iSecOwnerDefault = llList2Integer(lTmp, 1);
            }
            else if (sToken == g_sDBToken2)
            {
                //throw away first element
                //everything else is real settings (should be even number)
                g_lSettings = llParseString2List(sValue, [","], []);
                MakeNamesList();
                //UpdateSettings();
                //do it when all the settings are done
            }
            else if (sToken == "owner")
            {
                //SetOwnersExs("rem");
                g_lOwners = llParseString2List(sValue, [","], []);
                //send accepttp command
                //SetOwnersExs("add");
            }
            else if (sToken == "secowners")
            {
                //SetOwnersExs("rem");
                g_lSecOwners = llParseString2List(sValue, [","], []);
                //send accepttp command
                //SetOwnersExs("add");
            }
            else if (sToken == "settings")
            {
                if (sValue == "sent")
                {
                    SetAllExs("");//sendcommands
                }
            }
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            //handle saving new owner here
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            //does soemthing here need to change?
            if (sToken == "owner")
            {
                g_lOwners = llParseString2List(sValue, [","], []);
                ClearEx();
                UpdateSettings();
            }
            else if (sToken == "secowners")
            {
                g_lSecOwners = llParseString2List(sValue, [","], []);
                //send accepttp command
                ClearEx();
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
            //ClearSettings();
            //do we not want to reset it?
            llSleep(2.0);
            UpdateSettings();
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
            UpdateSettings();//send the settings as we did notbefore
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == g_kMenuID)
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
                else if (sMessage == "Owner")
                {
                    //give menu of for owners defaults
                    ExMenu(kAv, "owner", iAuth);
                }
                else if (sMessage == "Secowners")
                {
                    //give menu of for secowners defaults
                    ExMenu(kAv, "secowners", iAuth);
                }
                else if (sMessage == "Add")
                {
                    g_kDialoger = kAv;
                    g_iDialogerAuth = iAuth;
                    llSensor("", "", AGENT, 10.0, PI);
                }
                else if (sMessage == "Other") PersonMenu(kAv, g_lNames, "", iAuth);
            }
            else if (llListFindList(g_lExMenus, [kID]) != -1 )
            {
                Debug("dialog response: " + sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                integer iMenuIndex = llListFindList(g_lExMenus, [kID]);
                if (sMessage == UPMENU) Menu(kAv,"", iAuth);
                else
                {
                    string sMenu = llList2String(g_lExMenus, iMenuIndex + 1);
                    //we got a command to enable or disable something, like "Enable LM"
                    //get the actual command same by looking up the pretty name from the message
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
                            ONOFF = "y";
                        }
                        else if (sSwitch == TURNON)
                        {
                            ONOFF = "n";
                        }

                        //loop through g_lRLVcmds to create list
                        string sOut;
                        integer n;
                        integer iStop = llGetListLength(g_lRLVcmds);
                        for (n = 0; n < iStop; n++)
                        {
                            string cmd1 = llList2String(g_lRLVcmds, n);
                            //prefix all but the first value with a comma, so we have a comma-separated list
                            if (n)
                            {
                                sOut += ",";
                            }
                            sOut +=  cmd1 + ":" + sMenu + "=" + ONOFF;
                        }
                        // I a deabating how to do this but I think it is best to make sure they cna set them so setting back to the old way
                        /*
                        integer iOut = 0;
                        integer n;
                        integer iStop = llGetListLength(g_lRLVcmds);
                        if (ONOFF == "n")
                        {
                            for (n = 0; n < iStop; n++)
                            {
                                iOut = iOut | llList2Integer(g_lBinCmds, n);
                            }
                        }
                        if (sMenu == "owner")
                        {
                            g_iOwnerDefault = iOut;
                        }
                        else if (sMenu == "secowners")
                        {
                            g_iSecOwnerDefault = iOut;
                        }
                        //need to put new change commands here
                        SetAllExs("");
                        */
                        UserCommand(iAuth, sOut, kAv);
                        ExMenu(kAv, sMenu, iAuth);
                    }
                    else if (iIndex != -1)
                    {
                        string sOut = llList2String(g_lRLVcmds, iIndex);
                        sOut += ":" + sMenu + "=";
                        if (sSwitch == TURNOFF)
                        {
                            //enable all functions (ie, remove all restrictions
                            sOut += "y";
                        }
                        else if (sSwitch == TURNON)
                        {
                            sOut += "n";
                        }
                        //send rlv command out through auth system as though it were a chat command, just to make sure person who said it has proper authority
                        UserCommand(iAuth, sOut, kAv);
                        ExMenu(kAv, sMenu, iAuth);
                        /* thinking it is btter to switch back to the other way. It does mean more work for the script
                        integer iOut = 0;
                        if (sSwitch == TURNON)
                        {
                            iOut = llList2Integer(g_lBinCmds, iIndex);
                        }
                        else if (sSwitch == TURNOFF)
                        {
                            iOut = -llList2Integer(g_lBinCmds, iIndex);
                        }
                        if (sMenu == "owner")
                        {
                            g_iOwnerDefault = iOut + g_iOwnerDefault;
                        }
                        else if (sMenu == "secowners")
                        {
                            g_iSecOwnerDefault = iOut + g_iSecOwnerDefault;
                        }
                        // need a better way for this
                        // new way
                        SetAllExs("");
                        */
                        //send rlv command out through auth system as though it were a chat command, just to make sure person who said it has proper authority
                        //llMessageLinked(LINK_SET, COMMAND_NOAUTH, sOut, kAv);
                        //g_iReturnMenu = TRUE;
                    }
                    else if (sMessage == "Defaults")
                    {
                        UserCommand(iAuth, "defaults:" + sMenu + "=force", kAv);
                        ExMenu(kAv, sMenu, iAuth);
                    }
                    else if (sMessage == "List")
                    {
                        if (sMenu == "owner")
                        {
                            PersonMenu(kAv, g_lOwners, "", iAuth);
                        }
                        else if (sMenu == "secowners")
                        {
                            PersonMenu(kAv, g_lSecOwners, "", iAuth);
                        }
                    }
                    else
                    {
                        //something went horribly wrong.  We got a command that we can't find in the list
                    }
                    llDeleteSubList(g_lExMenus, iMenuIndex, iMenuIndex + 1);
                }
            }
            else if(kID == g_kPersonMenuID)
            {
                Debug("dialog response: " + sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) Menu(kAv, "", iAuth);
                else
                {
                    string sTmp = llList2String(g_lPersonMenu, (integer)sMessage*2-2); //g_lOwners + g_lSecOwners + g_lScan + g_lNames, llListFindList(g_lOwners + g_lSecOwners + g_lScan + g_lNames, [sMessage])-1);
                    ExMenu(kAv, sTmp, iAuth);
                    //g_lScan = [];
                }
            }
            else if(kID == g_kSensorMenuID)
            {
                Debug("dialog response: " + sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) Menu(kAv, "", iAuth);
                else
                {
                    string sTmp = llList2String(g_lOwners + g_lSecOwners + g_lScan + g_lNames, llListFindList(g_lOwners + g_lSecOwners + g_lScan + g_lNames, [sMessage])-1);
                    ExMenu(kAv, sTmp, iAuth);
                    g_lScan = [];
                }
            }
        }
    }
    dataserver(key kID, string sData)
    {
        integer iIndex = llListFindList(g_lNames, [(string)kID]);
        if (iIndex != -1)
        {
            g_lNames = llListReplaceList(g_lNames, [sData], iIndex, iIndex);
        }
    }            
    sensor(integer iNum_detected)
    {
        list lButtons;
        string sName;
        integer i;
        
        for(i = 0; i < iNum_detected; i++)
        {
            sName = llDetectedName(i);
            lButtons += [sName];
            g_lScan += [(string)llDetectedKey(i) ,sName];
        }
        //add wearer if not already in button list
        if (llGetListLength(lButtons) > 0)
        {
            string sText = "Select who you would like to add.\nIf the one you want to add does not show, move closer and repeat or use the chat command.";
            g_kSensorMenuID = Dialog(g_kDialoger, sText, lButtons, [UPMENU], 0, g_iDialogerAuth);
        }
        //llOwnerSay((string)llGetFreeMemory());
    }

    no_sensor()
    {
        Notify(g_kDialoger, "Nobody is in 10m range to be shown, either move closer or use the chat command to add someone who is not with you at this moment or offline.",FALSE);
  
    }
}