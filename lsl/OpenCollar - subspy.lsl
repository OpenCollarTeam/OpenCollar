//OpenCollar - subspy
//put all reporting on an interval of 30 or 60 secs.  That way we won't get behind with IM delays.
//use sensorrepeat as a second timer to do the reporting (since regular timer is already used by menu system
//if radar is turned off, just don't report avs when the sensor or no_sensor event goes off


// Spy script for the OpenCollar Project (c)
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.


list g_lAvBuffer;//if this changes between report intervals then tell owners (if radar enabled)
list g_lChatBuffer;//if this has anything in it at end of interval, then tell owners (if listen enabled)
list g_lTPBuffer;//if this has anything in it at end of interval, then tell owners (if trace enabled)

string g_sOldAVBuffer; // AVs previously found, only send radar if this has changed
integer g_iOldAVBufferCount = -1; // number of AVs previously found, only send radar if this has changed, setting to -1 at startup

list g_lCmds = ["trace on","trace off", "radar on", "radar off", "listen on", "listen off"];
integer g_iListenCap = 1500;//throw away old chat lines once we reach this many chars, to prevent stack/heap collisions
integer g_iListener;

string g_sLoc;
integer g_iFirstReport = TRUE;//if this is true when spy settings come in, then record current position in g_lTPBuffer and set to false
integer g_iSensorRange = 8;
integer g_iSensorRepeat = 120;

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_SAFEWORD = 510;  // new for safeword

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string g_sDBToken = "spy";

string UPMENU = "^";
string g_sParentMenu = "AddOns";
string g_sSubMenu = "Spy";

list g_lOwners;
string g_sSubName;
list g_lSetttings;

key g_kDialogSpyID;
key g_kDialogRadarSettingsID;

key g_kWearer;

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

DoReports()
{
    Debug("doing reports");
    //build a report containing:
    //who is nearby (as listed in g_lAvBuffer)
    //where the sub has TPed (s stored in g_lTPBuffer)
    //what the sub has sakID (as stored in g_lChatBuffer)
    string sReport;

    if (Enabled("radar"))
    {
        //Debug("Old: "+(string)g_iOldAVBufferCount+";"+g_sOldAVBuffer);
        integer kAvcount = llGetListLength(g_lAvBuffer);
        //Debug("New: "+(string)kAvcount+";"+llDumpList2String(llListSort(g_lAvBuffer, 1, TRUE), ", "));
        if (kAvcount != g_iOldAVBufferCount)
        {
            if (kAvcount)
            {
                g_sOldAVBuffer = llDumpList2String(llListSort(g_lAvBuffer, 1, TRUE), ", ");
                sReport += "\nNearby avatars: " + g_sOldAVBuffer + ".";

            }
            else
            {
                sReport += "\nNo nearby avatars.";
                g_sOldAVBuffer = "";
            }
            g_iOldAVBufferCount = kAvcount;
        }
        else
        {
            string sCurrentAVs = llDumpList2String(llListSort(g_lAvBuffer, 1, TRUE), ", ");
            if (sCurrentAVs != g_sOldAVBuffer)
            {
                g_sOldAVBuffer = sCurrentAVs;
                if (kAvcount)
                {
                    sReport += "\nNearby avatars: " + g_sOldAVBuffer + ".";
                }
            }
        }
    }

    if (Enabled("trace"))
    {
        integer iLength = llGetListLength(g_lTPBuffer);
        if (iLength)
        {
            sReport += "\n" + llDumpList2String(["Login/TP info:"] + g_lTPBuffer, "\n--");
        }
    }

    if (Enabled("listen"))
    {
        integer iLength = llGetListLength(g_lChatBuffer);
        if (iLength)
        {
            sReport += "\n" + llDumpList2String(["Chat:"] + g_lChatBuffer, "\n--");
        }
    }

    if (llStringLength(sReport))
    {
        sReport = "Activity report for " + g_sSubName + " at " + GetTimestamp() + sReport;
        Debug("report: " + sReport);
        NotifyOwners(sReport);
    }

    //flush buffers
    g_lAvBuffer = [];
    g_lChatBuffer = [];
    g_lTPBuffer = [];
}

UpdateSensor()
{
    llSensorRemove();
    //since we use the repeating sensor as a timer, turn it on if any of the spy reports are turned on, not just radar
    //also, only start the sensor/timer if we're attached so there's no spam from collars left lying around
    if (llGetAttached() && Enabled("trace") || Enabled("radar") || Enabled("listen"))
    {
        Debug("enabling sensor");
        llSensorRepeat("" ,"" , AGENT, g_iSensorRange, PI, g_iSensorRepeat);
    }
}

UpdateListener()
{
    Debug("updatelistener");
    if (llGetAttached())
    {
        if (Enabled("listen"))
        {
            //turn on listener if not already on
            if (!g_iListener)
            {
                Debug("turning listener on");
                g_iListener = llListen(0, "", g_kWearer, "");
            }
        }
        else
        {
            //turn off listener if on
            if (g_iListener)
            {
                Debug("turning listener off");
                llListenRemove(g_iListener);
                g_iListener = 0;
            }
        }
    }
    else
    {
        //we're not attached.  close listener
        Debug("turning listener off");
        llListenRemove(g_iListener);
        g_iListener = 0;
    }
}

integer Enabled(string sToken)
{
    integer iIndex = llListFindList(g_lSetttings, [sToken]);
    if(iIndex == -1)
    {
        return FALSE;
    }
    else
    {
        if(llList2String(g_lSetttings, iIndex + 1) == "on")
        {
            return TRUE;
        }
        return FALSE;
    }
}

string GetTimestamp() // Return a string of the date and time
{
    integer t = (integer)llGetWallclock(); // seconds since midnight

    return GetPSTDate() + " " + (string)(t / 3600) + ":" + PadNum((t % 3600) / 60) + ":" + PadNum(t % 60);
}

string PadNum(integer sValue)
{
    if(sValue < 10)
    {
        return "0" + (string)sValue;
    }
    return (string)sValue;
}

string GetPSTDate()
{ //Convert the date from UTC to PST if GMT time is less than 8 hours after midnight (and therefore tomorow's date).
    string sDateUTC = llGetDate();
    if (llGetGMTclock() < 28800) // that's 28800 seconds, a.k.a. 8 hours.
    {
        list lDateList = llParseString2List(sDateUTC, ["-", "-"], []);
        integer iYear = llList2Integer(lDateList, 0);
        integer iMonth = llList2Integer(lDateList, 1);
        integer iDay = llList2Integer(lDateList, 2);
        iDay = iDay - 1;
        return (string)iYear + "-" + (string)iMonth + "-" + (string)iDay;
    }
    return llGetDate();
}

string GetLocation() {
    vector g_vPos = llGetPos();
    return llList2String(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]),0) + " (" + llGetRegionName() + " <" +
        (string)((integer)g_vPos.x)+","+(string)((integer)g_vPos.y)+","+(string)((integer)g_vPos.z)+">)";
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

DialogSpy(key kID, integer iAuth)
{
    string sPrompt;
    if (iAuth != COMMAND_OWNER)
    {
        sPrompt = "Only an Owner can set and see spy options.";
        g_kDialogSpyID = Dialog(kID, sPrompt, [], [UPMENU], 0, iAuth);
        return;
    }
    list lButtons ;
    sPrompt = "These are ONLY Primary Owner options:\n";
    sPrompt += "Trace turns on/off notices if the sub teleports.\n";
    sPrompt += "Radar turns on/off a report every "+ (string)((integer)g_iSensorRepeat/60) + " of who joined  or left " + g_sSubName + " in a range of " + (string)((integer)g_iSensorRange) + "m.\n";
    sPrompt += "Listen turns on/off if you get directly said what " + g_sSubName + " says in public chat.";

    if(Enabled("trace"))
    {
        lButtons += ["Trace Off"];
    }
    else
    {
        lButtons += ["Trace On"];
    }
    if(Enabled("radar"))
    {
        lButtons += ["Radar Off"];
    }
    else
    {
        lButtons += ["Radar On"];
    }
    if(Enabled("listen"))
    {
        lButtons += ["Listen Off"];
    }
    else
    {
        lButtons += ["Listen On"];
    }
    lButtons += ["RadarSettings"];
    g_kDialogSpyID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

DialogRadarSettings(key kID, integer iAuth)
{
    list lButtons;
    string sPromt = "Choose the radar repeat and sensor range:\n";
    sPromt += "Current Radar Range is: " + (string)((integer)g_iSensorRange) + " meter.\n";
    sPromt += "Current Radar Frequenz is: " + (string)((integer)g_iSensorRepeat/60) + " minutes.\n";
    lButtons += ["5 meter", "8 meter", "10 meter", "15 meter"];
    lButtons += ["2 minutes", "5 minutes", "8 minutes", "10 minutes"];
    g_kDialogRadarSettingsID = Dialog(kID, sPromt, lButtons, [UPMENU], 0, iAuth);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    Debug("notify " + (string)kID + " " + sMsg);
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    } else {
            llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

BigNotify(key kID, string sMsg)
{//if sMsg iLength > 1024, split into bite sized pieces and IM each individually
    Debug("bignotify");
    list g_iLines = llParseString2List(sMsg, ["\n"], []);
    while (llGetListLength(g_iLines))
    {
        Debug("looping through lines");
        //build a string with length up to the IM limit, with a little wiggle room
        list lTmp;
        while (llStringLength(llDumpList2String(lTmp, "\n")) < 800 && llGetListLength(g_iLines))
        {
            Debug("building a line");
            lTmp += llList2List(g_iLines, 0, 0);
            g_iLines = llDeleteSubList(g_iLines, 0, 0);
        }
        Notify(kID, llDumpList2String(lTmp, "\n"), FALSE);
    }
}

NotifyOwners(string sMsg)
{
    Debug("notifyowners");
    integer n;
    integer iStop = llGetListLength(g_lOwners);
    for (n = 0; n < iStop; n += 2)
    {
        key kAv = (key)llList2String(g_lOwners, n);
        //we don't want to bother the owner if he/she is right there, so check distance
        vector vOwnerPos = (vector)llList2String(llGetObjectDetails(kAv, [OBJECT_POS]), 0);
        if (vOwnerPos == ZERO_VECTOR || llVecDist(vOwnerPos, llGetPos()) > 20.0)//vOwnerPos will be ZERO_VECTOR if not in sim
        {
            Debug("notifying " + (string)kAv);
            BigNotify(kAv, sMsg);
        }
        else
        {
            Debug((string)kAv + " is right next to you! not notifying.");
        }
    }
}

SaveSetting(string sStr)
{
    list lTemp = llParseString2List(sStr, [" "], []);
    string sOption = llList2String(lTemp, 0);
    string sValue = llList2String(lTemp, 1);
    integer iIndex = llListFindList(g_lSetttings, [sOption]);
    if(iIndex == -1)
    {
        g_lSetttings += lTemp;
    }
    else
    {
        g_lSetttings = llListReplaceList(g_lSetttings, [sValue], iIndex + 1, iIndex + 1);
    }
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + llDumpList2String(g_lSetttings, ","), NULL_KEY);
}

EnforceSettings()
{
    integer i;
    integer iListLength = llGetListLength(g_lSetttings);
    for(i = 1; i < iListLength; i += 2)
    {
        string sOption = llList2String(g_lSetttings, i);
        string sValue = llList2String(g_lSetttings, i + 1);
        if(sOption == "meter")
        {
            g_iSensorRange = (integer)sValue;
        }
        else if(sOption == "minutes")
        {
            g_iSensorRepeat = (integer)sValue;
        }
    }
    UpdateSensor();
    UpdateListener();
}

TurnAllOff()
{ // set all values to off and remove sensor and listener
    llSensorRemove();
    llListenRemove(g_iListener);
    list lTemp = ["radar", "listen", "trace"];
    integer i;
    for (i=0; i < llGetListLength(lTemp); i++)
    {
        string sOption = llList2String(lTemp, i);
        integer iIndex = llListFindList(g_lSetttings, [sOption]);
        if(iIndex != -1)
        {
            g_lSetttings = llListReplaceList(g_lSetttings, ["off"], iIndex + 1, iIndex + 1);
        }
    }
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + llDumpList2String(g_lSetttings, ","), NULL_KEY);
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    //only a primary owner can use this !!
    sStr = llToLower(sStr);
    if (sStr == "spy" || sStr == "menu " + llToLower(g_sSubMenu)) DialogSpy(kID, iNum);
    else if (iNum != COMMAND_OWNER)
    { 
        if(~llListFindList(g_lCmds, [sStr]))
            Notify(kID, "Sorry, only an owner can set spy settings.", FALSE);
    }
    else // COMMAND_OWNER
    {
        if (sStr == "radarsettings")//request for the radar settings menu
        {
            DialogRadarSettings(kID, iNum);
        }
        else if (~llListFindList(g_lCmds, [sStr]))//received an actual spy command
        {
            if(sStr == "trace on")
            {
                SaveSetting(sStr);
                EnforceSettings();
                Notify(kID, "Teleport tracing is now turned on.", TRUE);
                g_sLoc=llGetRegionName();
            }
            else if(sStr == "trace off")
            {
                SaveSetting(sStr);
                EnforceSettings();
                Notify(kID, "Teleport tracing is now turned off.", TRUE);
            }
            else if(sStr == "radar on")
            {
                g_sOldAVBuffer = "";
                g_iOldAVBufferCount = -1;

                SaveSetting(sStr);
                EnforceSettings();
                Notify(kID, "Avatar radar with range of " + (string)((integer)g_iSensorRange) + "m for " + g_sSubName + " is now turned ON.", TRUE);
            }
            else if(sStr == "radar off")
            {
                SaveSetting(sStr);
                EnforceSettings();
                Notify(kID, "Avatar radar with range of " + (string)((integer)g_iSensorRange) + "m for " + g_sSubName + " is now turned OFF.", TRUE);
            }
            else if(sStr == "listen on")
            {
                SaveSetting(sStr);
                EnforceSettings();
                Notify(kID, "Chat listener enabled.", TRUE);
            }
            else if(sStr == "listen off")
            {
                SaveSetting(sStr);
                EnforceSettings();
                Notify(kID, "Chat listener disabled.", TRUE);
            }
        }
    }
    return TRUE;
}

default
{
    on_rez(integer iNum)
    {
        llResetScript();
    }

    state_entry()
    {
        g_kWearer = llGetOwner();
        g_sSubName = llKey2Name(g_kWearer);
        g_sLoc=llGetRegionName();
        g_lOwners = [g_kWearer, g_sSubName];  // initially self-owned until we hear a db message otherwise
    }

    listen(integer channel, string sName, key kID, string sMessage)
    {
        if(kID == g_kWearer && channel == 0)
        {
            Debug("g_kWearer: " + sMessage);
            if(llGetSubString(sMessage, 0, 3) == "/me ")
            {
                g_lChatBuffer += [g_sSubName + llGetSubString(sMessage, 3, -1)];
            }
            else
            {
                g_lChatBuffer += [g_sSubName + ": " + sMessage];
            }

            //do the listencap to avoid running out of memory
            while (llStringLength(llDumpList2String(g_lChatBuffer, "\n")) > g_iListenCap)
            {
                Debug("discarding line to stay under listencap");
                g_lChatBuffer = llDeleteSubList(g_lChatBuffer, 0, 0);
            }
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == LM_SETTING_SAVE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "owner" && llStringLength(sValue) > 0)
            {
                g_lOwners = llParseString2List(sValue, [","], []);
                Debug("owners: " + sValue);
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "owner" && llStringLength(sValue) > 0)
            {
                g_lOwners = llParseString2List(sValue, [","], []);
                Debug("owners: " + sValue);
            }
            else if (sToken == g_sDBToken)
            { //llOwnerSay("Loading Spy Settings: " + sValue + " from Database.");
                Debug("got settings from db: " + sValue);
                g_lSetttings = llParseString2List(sValue, [","], []);
                EnforceSettings();

                if (g_iFirstReport)
                {
                    //record initial position if trace enabled
                    if (Enabled("trace"))
                    {
                        g_lTPBuffer += ["Rezzed at " + GetLocation()];
                    }
                    g_iFirstReport = FALSE;
                }

            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if(iNum == COMMAND_SAFEWORD)
        {//we recieved a safeword sCommand, turn all off
            TurnAllOff();
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == g_kDialogSpyID || kID == g_kDialogRadarSettingsID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (kID == g_kDialogSpyID)
                {
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == "RadarSettings") DialogRadarSettings(kAv, iAuth);
                    else
                    {
                        UserCommand(iAuth, llToLower(sMessage), kAv);
                        DialogSpy(kAv, iAuth);
                    }
                }
                else if (kID == g_kDialogRadarSettingsID)
                {
                    if (sMessage == UPMENU) DialogSpy(kAv, iAuth);
                    else
                    {
                        list lTemp = llParseString2List(sMessage, [" "], []);
                        integer sValue = (integer)llList2String(lTemp,0);
                        string sOption = llList2String(lTemp,1);
                        if(sOption == "meter")
                        {
                            g_iSensorRange = sValue;
                            SaveSetting(sOption + " " + (string)sValue);
                            Notify(kAv, "Radar range changed to " + (string)((integer)sValue) + " meters.", TRUE);
                        }
                        else if(sOption == "minutes")
                        {
                            g_iSensorRepeat = sValue * 60;
                            SaveSetting(sOption + " " + (string)g_iSensorRepeat);
                            Notify(kAv, "Radar frequency changed to " + (string)((integer)sValue) + " minutes.", TRUE);
                        }
                        if(Enabled("radar"))
                        {
                            UpdateSensor();
                        }
                        DialogRadarSettings(kAv, iAuth);
                    }
                }
            }
        }
    }

    sensor(integer iNum)
    {
        if (Enabled("radar"))
        {
            //put nearby avs in list
            integer n;
            for (n = 0; n < iNum; n++)
            {
                g_lAvBuffer += [llDetectedName(n)];
            }
        }
        else
        {
            g_lAvBuffer = [];
        }

        DoReports();
    }

    no_sensor()
    {
        g_lAvBuffer = [];
        DoReports();
    }

    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            g_sLoc = llGetRegionName();
        }
    }

    changed(integer iChange)
    {
        if((iChange & CHANGED_TELEPORT) || (iChange & CHANGED_REGION))
        {
            g_iOldAVBufferCount = -1;
            if(Enabled("trace"))
            {
                g_lTPBuffer += ["Teleport from " + g_sLoc + " to " +  GetLocation()+ " at " + GetTimestamp() + "."];
            }
            g_sLoc = llGetRegionName();
        }

        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
}