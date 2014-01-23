////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - subspy                               //
//                                 version 3.942                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////


//modified by Littelmousy Resident, 22 Dec 2013
//improved handling of long strings
//updated settings storage to improve speed and memory use
//refactored link message handling
//modified by: Zopf Resident - Ray Zopf (Raz)
//Additions: changes on save settings, small bugfixes, added reset on runaway, warning on startup; better handling of para rp
//07. Nov 2013
//
///////////////////////////////////////////////////////////////////////////////////////////////////


//===============================================
//GLOBAL VARIABLES
//===============================================

//internal variables
//-----------------------------------------------

string g_sCurrentAVs;  //if this changes between report intervals then tell owners (if radar enabled)
string g_sOldAVBuffer; //AVs previously found, only send radar if this has changed
string g_sChatBuffer;  //if this has anything in it at end of interval, then tell owners (if listen enabled)
string g_sTPBuffer;    //if this has anything in it at end of interval, then tell owners (if trace enabled)
string g_sState="init";

list g_lCmds = ["trace on","trace off", "radar on", "radar off", "listen on", "listen off"];
integer g_iListenCap = 1000;//throw away old chat lines once we reach this many chars, to prevent stack/heap collisions
integer g_iListener;
string g_sOffMsg = "Spy add-on is now disabled";

string g_sLoc;

integer g_iTraceEnabled=FALSE;
integer g_iRadarEnabled=FALSE;
integer g_iListenEnabled=FALSE;
integer g_iSensorRange = 4;
integer g_iSensorRepeat = 900;

integer g_iGotSettingOwners=FALSE;
integer g_iGotSettingTrace=FALSE;
integer g_iGotSettingRadar=FALSE;
integer g_iGotSettingListen=FALSE;
integer g_iGotSettingMeters=FALSE;
integer g_iGotSettingMinutes=FALSE;

//OC MESSAGE MAP
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

string g_sScript;

string UPMENU = "BACK";
string g_sParentMenu = "AddOns";
string g_sSubMenu = "SubSpy";

list g_lOwners;
string g_sSubName;

key g_kDialogSpyID;
key g_kDialogRadarSettingsID;

key g_kWearer;


//===============================================
//PREDEFINED FUNCTIONS
//===============================================


//Debug(string sMsg){
//    llOwnerSay("["+llGetScriptName()+"]" + sMsg);
//}

string GetScriptID()
{
    // strip away "OpenCollar - " leaving the script's individual name
    list parts = llParseString2List(llGetScriptName(), ["-"], []);
    return llStringTrim(llList2String(parts, 1), STRING_TRIM) + "_";
}


string PeelToken(string in, integer slot)
{
    integer i = llSubStringIndex(in, "_");
    if (!slot) return llGetSubString(in, 0, i);
    return llGetSubString(in, i + 1, -1);
}


DoReports(integer iBufferFull)
{
    //Debug("doing reports, iBufferFull: "+(string)iBufferFull);
    string sReport;

    if (g_iRadarEnabled && !iBufferFull)
    { //don't report radar if triggered by full chat buffer
        if (g_sCurrentAVs != g_sOldAVBuffer) sReport += "Nearby avatars:\n" + g_sCurrentAVs + ".\n";  //if avis on radar are different from last time
    }

    if (g_iTraceEnabled && !iBufferFull)
    { //don't report trace if triggered by full chat buffer
        if (llStringLength(g_sTPBuffer)) {
            sReport += g_sTPBuffer;
            g_sTPBuffer = "";
        }
    }

    if (g_iListenEnabled)
    {
        if (llStringLength(g_sChatBuffer)>0){
            sReport += g_sChatBuffer;
            g_sChatBuffer = "";
        }
    }

    if (llStringLength(sReport))
    {
        //Debug("Sending activity report to owner");
        sReport = "Activity report for " + g_sSubName + " at " + GetTimestamp() + "\n" + sReport;
        NotifyOwners(sReport);
    }
}


UpdateSensor()
{
    llSensorRemove();
    //since we use the repeating sensor as a timer, turn it on if any of the spy reports are turned on, not just radar
    //also, only start the sensor/timer if we're attached so there's no spam from collars left lying around
    if (llGetAttached() && (g_iTraceEnabled || g_iRadarEnabled || g_iListenEnabled))
    {
        //Debug("Enabling sensor every "+(string)g_iSensorRepeat+" seconds");
        //Debug("range:"+(string)g_iSensorRange+" repeat: "+(string)g_iSensorRepeat);
        llSensorRepeat("" ,"" , AGENT, (float)g_iSensorRange, PI, (float)g_iSensorRepeat);
    }
}


UpdateListener()
{
    if (g_iListenEnabled && llGetAttached()){ //turn on listener if not already on
        if (!g_iListener){
            //Debug("Enabling listener");
            g_iListener = llListen(0, "", g_kWearer, "");
        }
    }
    else
    {  
        //turn off listener if on
        if (g_iListener)
        {
            //Debug("Disabling listener");
            llListenRemove(g_iListener);
            g_iListener = 0;
        }
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
    vector vPos = llGetPos();
    return llList2String(llGetParcelDetails(llGetPos(), [PARCEL_DETAILS_NAME]),0) + " (" + llGetRegionName() + " <" +
        (string)((integer)vPos.x)+","+(string)((integer)vPos.y)+","+(string)((integer)vPos.z)+">)";
}


key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}


DialogSpy(key kID, integer iAuth)
{
    string sPrompt;
    if (iAuth != COMMAND_OWNER)
    {
        sPrompt = "\n\nACCESS DENIED: Primary Owners Only";
        g_kDialogSpyID = Dialog(kID, sPrompt, [], [UPMENU], 0, iAuth);
        return;
    }
    string sTStatus;
    string sRStatus;
    string sLStatus;
    sTStatus = sRStatus = sLStatus = "off";
    list lButtons ;

    if(g_iTraceEnabled)
    {
        lButtons += ["☒ Trace"];
        sTStatus = "on";
    }
    else
    {
        lButtons += ["☐ Trace"];
    }
    if(g_iRadarEnabled)
    {
        lButtons += ["☒ Radar"];
        sRStatus = "on";
    }
    else
    {
        lButtons += ["☐ Radar"];
    }
    if(g_iListenEnabled)
    {
        lButtons += ["☒ Listen"];
        sLStatus = "on";
    }
    else
    {
        lButtons += ["☐ Listen"];
    }
    lButtons += ["RadarSettings"];
    sPrompt = "\n-Primary Owners Only Menu-\n";
    sPrompt += "\nTrace ("+sTStatus+") notifies if " + g_sSubName + " teleports.\n";
    sPrompt += "\nRadar ("+sRStatus+") and Listen ("+sLStatus+") sending reports every "+ (string)((integer)g_iSensorRepeat/60) + " minutes on who joined or left " + g_sSubName + " in a range of " + (string)((integer)g_iSensorRange) + " meters and on what " + g_sSubName + " wrote in Nearby Chat.\n";
    sPrompt += "\nListen transmits directly what " + g_sSubName + " says in Nearby Chat. Other nearby parties chat will NOT be transmitted!\n - Messages may get capped and not all text may get transmitted -";

    g_kDialogSpyID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}


list CheckboxButtons(list lValues, string sButtonText, string sControlValue){
    list lNewButtons=[];
    integer iNumButtons=llGetListLength(lValues);
    integer i;
    for (i=0;i<iNumButtons;i++){
        string sButtonValue=llList2String(lValues,i);
        llOwnerSay("processing button "+sButtonValue);
        if (sButtonValue==sControlValue){
            lNewButtons += "☒ "+sButtonValue+sButtonText;
        } else {
            lNewButtons += "☐ "+sButtonValue+sButtonText;
        }
    }
    return lNewButtons;
}

DialogRadarSettings(key kID, integer iAuth)
{
    list lButtons;
    string sPromt = "\n\nSetup for the Radar Repeats, Sensors and Report Frequency:\n";
    sPromt += "\nRadar Range is set to: " + (string)((integer)g_iSensorRange) + " meters.\n";
    sPromt += "\nRadar and Listen report frequency is set to: " + (string)((integer)g_iSensorRepeat/60) + " minutes.\n";
    //list newButtons=+= ["4 meters", "8 meters", "18 meters"];
    lButtons += CheckboxButtons(["4","8","18"]," meters",(string)g_iSensorRange);
    lButtons += CheckboxButtons(["5","9","15"]," minutes",(string)((integer)g_iSensorRepeat/60));

    g_kDialogRadarSettingsID = Dialog(kID, sPromt, lButtons, [UPMENU], 0, iAuth);
}


integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan>0)
    {
        iChan=iChan*(-1);
    }
    if (iChan > -10000)
    {
        iChan -= 30000;
    }
    return iChan;
}


Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    while (llStringLength(sMsg) > 0){    //split messages over 1024 chars long over multiple messages
        integer index=1023;
        if (llStringLength(sMsg)<1024){
            index =llStringLength(sMsg)-1;
        } else {
            while ((llGetSubString(sMsg,index,index) != "\n") && index){
                index--;
            }
        }
        //Debug("using index="+(string)index);
        if (kID == g_kWearer)
        {      //notify the wearer
            llOwnerSay( llGetSubString(sMsg,0,index));
        }
        else if (llGetAgentSize(kID) == ZERO_VECTOR)
        {     //notify avi not in same sim
            llInstantMessage(kID, llGetSubString(sMsg,0,index));
            if (iAlsoNotifyWearer)
            {
                llOwnerSay( llGetSubString(sMsg,0,index));
            }
        }
        else // remote request
        { // notify avi in same sim
            if (iAlsoNotifyWearer)
            {
                llOwnerSay( llGetSubString(sMsg,0,index));
            }
            llRegionSayTo(kID, GetOwnerChannel(g_kWearer, 1111), llGetSubString(sMsg,0,index));
        }
        if (index >=llStringLength(sMsg)-1 ) return;
        sMsg= llGetSubString(sMsg,index,-1);
    }
}


NotifyOwners(string sMsg)
{
    //Debug("notifyowners");
    integer n;
    integer iStop = llGetListLength(g_lOwners);
    for (n = 0; n < iStop; n += 2)
    {
        key kAv = (key)llList2String(g_lOwners, n);
        //we don't want to bother the owner if he/she is right there, so check distance
        vector vOwnerPos = (vector)llList2String(llGetObjectDetails(kAv, [OBJECT_POS]), 0);
        if (vOwnerPos == ZERO_VECTOR || llVecDist(vOwnerPos, llGetPos()) > 20.0)//vOwnerPos will be ZERO_VECTOR if not in sim
        {
            //Debug("notifying " + (string)kAv);
            Notify(kAv, sMsg,FALSE);
        }
        else
        {
            if (llSubStringIndex(sMsg, g_sOffMsg) != ERR_GENERIC && kAv != g_kWearer) Notify(kAv, sMsg, FALSE);
            //Debug((string)kAv + " is right next to you! not notifying.");
        }
    }
}


SaveSetting(string sOption, string sValue)
{
    //Debug("Saving setting: " + sOption + "=" + sValue);
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + sOption + "=" + sValue, NULL_KEY);   //send value to settings script
}


TurnAllOff(string command)
{ // set all values to off and remove sensor and listener
    //Debug("Turn all off: " + command);
    if ("runaway" == command) {
        g_iSensorRange = 4;
        SaveSetting("meters",(string)g_iSensorRange);
        g_iSensorRepeat = 900;
        SaveSetting("minutes",(string)g_iSensorRepeat);
    }
    g_iTraceEnabled = FALSE;
    SaveSetting("trace","off");
    g_iRadarEnabled = FALSE;
    SaveSetting("radar","off");
    g_iListenEnabled = FALSE;
    SaveSetting("listen","off");

    UpdateSensor();
    UpdateListener();

    if ("safeword" == command) NotifyOwners(g_sOffMsg+" on "+g_sSubName);
    Notify(g_kWearer,g_sOffMsg,FALSE);
}


performSpyCommand (string sStr, key kID)
{
    //Debug("Performing subspy command: "+sStr);

    if(sStr == "☐ trace")
    {
        g_sLoc=GetLocation();
        if (!g_iTraceEnabled) g_sTPBuffer += "Trace turned on at " + g_sLoc + " at " + GetTimestamp() + ".\n";
        g_iTraceEnabled=TRUE;
        SaveSetting("trace","on");
        Notify(kID, "Teleport tracing is now turned on.", TRUE);
    }
    else if(sStr == "☒ trace")
    {
        g_iTraceEnabled=FALSE;
        SaveSetting("trace","off");
        Notify(kID, "Teleport tracing is now turned off.", TRUE);
    }
    else if(sStr == "☐ radar")
    {
        //if (!g_iRadarEnabled) g_lAVBuffer += ["Radar turned on at " + GetTimestamp() + "."];
        g_sOldAVBuffer = "";
        g_iRadarEnabled=TRUE;
        SaveSetting("radar","on");
        UpdateSensor();
        Notify(kID, "Avatar radar with range of " + (string)((integer)g_iSensorRange) + "m around " + g_sSubName + " is now turned ON.", TRUE);
    }
    else if(sStr == "☒ radar")
    {
        g_iRadarEnabled=FALSE;
        SaveSetting("radar","off");
        UpdateSensor();
        Notify(kID, "Avatar radar with range of " + (string)((integer)g_iSensorRange) + "m around " + g_sSubName + " is now turned OFF.", TRUE);
    }
    else if(sStr == "☐ listen")
    {
        if (!g_iRadarEnabled) g_sChatBuffer += "Listener turned on at " + GetTimestamp() + ".\n";
        g_iListenEnabled=TRUE;
        SaveSetting("listen","on");
        UpdateListener();
        Notify(kID, "Chat listener enabled.", TRUE);
    }
    else if(sStr == "☒ listen")
    {
        g_iListenEnabled=FALSE;
        SaveSetting("listen","off");
        UpdateListener();
        Notify(kID, "Chat listener disabled.", TRUE);
    }
    else if(llSubStringIndex(sStr,"meters")==0)
    {
        //Debug("got meters command");
    } else if(llSubStringIndex(sStr,"minutes")==0) {
        //Debug("got minutes command");
    } else {
        //Debug("Got unhandled command: "+sStr);
    }
}


//===============================================
//===============================================
//MAIN
//===============================================
//===============================================

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
        g_sLoc=GetLocation();
        g_lOwners = [g_kWearer, g_sSubName];  // initially self-owned until we hear a db message otherwise

        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";

        llSetTimerEvent(4.0);   //wait for data before we do anything else... see timer event.
    }

    listen(integer channel, string sName, key kID, string sMessage)
    {
        if(kID == g_kWearer && channel == 0)
        {
            //process emotes, replace with sub name
            if(llGetSubString(sMessage, 0, 3) == "/me ") sMessage=g_sSubName + llGetSubString(sMessage, 3, -1);
            else sMessage=g_sSubName + ": " + sMessage;
            integer iMessageLength=llStringLength(sMessage);
            //Debug("New line is "+(string)iMessageLength+" characters");

            //if this line would overfloww the buffer, send a report before adding it
            if(iMessageLength + llStringLength(g_sChatBuffer) > g_iListenCap)
            {
                //Debug("This line would overflow the buffer... flushing buffer by running report now");
                DoReports(TRUE);
                //Debug("Report has been run, Currently "+(string)llStringLength(g_sChatBuffer)+" characters in the buffer");
            }
        
            //if this line alone would overflow the buffer, trim it, and send it now
            while (iMessageLength > g_iListenCap) {  //if message longer than allowed buffer length, trim it and replace the last few bytes with warning string
                string sFragment = llDeleteSubString(sMessage, 0, g_iListenCap);
                sMessage = llDeleteSubString(sMessage, g_iListenCap, -1);
                //Debug("was too much text: " + (string)llStringLength(sMessage));
                iMessageLength=llStringLength(sFragment);
                g_sChatBuffer += sFragment;
                //Debug("Running report, Currently "+(string)llStringLength(g_sChatBuffer)+" characters in the buffer");
                //Debug("Still "+(string)llStringLength(sMessage)+" characters to process");
                DoReports(TRUE);
                iMessageLength=llStringLength(sMessage);
            }

            g_sChatBuffer += sMessage+"\n";
            //Debug("Now "+(string)llStringLength(g_sChatBuffer)+" characters in the buffer");
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        //Debug("link_message: Sender = "+ (string)iSender + ", iNum = "+ (string)iNum + ", string = " + (string)sStr +", ID = " + (string)kID);

        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER){   //user command, post auth
            //Debug("UserCommand: "+sStr);
            sStr = llToLower(sStr);
            if (iNum != COMMAND_OWNER)
            {
                if(~llListFindList(g_lCmds, [sStr]))
                    Notify(kID, "Sorry, only a primary owner can set spy settings.", FALSE);  //reject commands from anyone except owner
            }
            else // COMMAND_OWNER
            {
                //Debug("UserCommand - COMMAND_OWNER");
                if (sStr == "subspy" || sStr == "menu " + llToLower(g_sSubMenu)) DialogSpy(kID, iNum);
                else if (sStr == "radarsettings")
                {
                    DialogRadarSettings(kID, iNum); //request for the radar settings menu
                } else if ("runaway" == sStr) TurnAllOff(sStr); //runaway command
                else if (~llListFindList(g_lCmds, [sStr]))performSpyCommand(sStr, kID); //received an actual spy command
                //else //Debug("Didn't recognise command");
            }
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "auth_owner" && llStringLength(sValue) > 0)
            {
                g_lOwners = llParseString2List(sValue, [","], []);
                //Debug("owners: " + sValue);
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");


            if(sToken == "auth_owner" && llStringLength(sValue) > 0)
            { //owners list
                g_lOwners = llParseString2List(sValue, [","], []);
                //Debug("owners: " + sValue);
                g_iGotSettingOwners=TRUE;
            }
            else if (llGetSubString(sToken, 0, i) == g_sScript)
            { //subspy data
                string sOption = llToLower(llGetSubString(sToken, i+1, -1));
                //Debug("recieved settings: "+sOption+"="+sValue);

                if (sOption == "trace") {
                    g_iGotSettingTrace=TRUE;
                    if (sValue=="on") g_iTraceEnabled=TRUE;
                    else g_iTraceEnabled=FALSE;
                } else if (sOption == "radar") {
                    g_iGotSettingRadar=TRUE;
                    if (sValue=="on") g_iRadarEnabled=TRUE;
                    else g_iRadarEnabled=FALSE;
                } else if (sOption == "listen") {
                    g_iGotSettingListen=TRUE;
                    if (sValue=="on") g_iListenEnabled=TRUE;
                    else g_iListenEnabled=FALSE;
                } else if (sOption == "meters") {
                    g_iGotSettingMeters=TRUE;
                    g_iSensorRange=(integer)sValue;
                } else if (sOption == "minutes") {
                    g_iGotSettingMinutes=TRUE;
                    g_iSensorRepeat=(integer)sValue;
                }

            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if(iNum == COMMAND_SAFEWORD)
        { //we recieved a safeword sCommand, turn all off
            TurnAllOff("safeword");
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == g_kDialogSpyID)
            { //settings change from main subspy
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);


                if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                else if (sMessage == "RadarSettings") DialogRadarSettings(kAv, iAuth);
                else
                {
                    performSpyCommand(llToLower(sMessage), kAv);
                    DialogSpy(kAv, iAuth);
                }
            }
            else if (kID == g_kDialogRadarSettingsID)
            { //settings change from subspy radar menu
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                if (sMessage == UPMENU) DialogSpy(kAv, iAuth);
                else
                {
                    sMessage = llGetSubString(sMessage,2,-1);
                    list lTemp = llParseString2List(sMessage, [" "], []);
                    integer sValue = (integer)llList2String(lTemp,0);
                    string sOption = llList2String(lTemp,1);
                    if(sOption == "meters")
                    {
                        g_iSensorRange = sValue;
                        SaveSetting(sOption,(string)g_iSensorRange);
                        Notify(kAv, "Radar range changed to " + (string)((integer)sValue) + " meters.", TRUE);
                    }
                    else if(sOption == "minutes")
                    {
                        g_iSensorRepeat = sValue * 60;
                        SaveSetting(sOption,(string)g_iSensorRepeat);
                        Notify(kAv, "Radar and Listen report frequency changed to " + (string)((integer)sValue) + " minutes.", TRUE);
                    }
                    UpdateSensor();
                    DialogRadarSettings(kAv, iAuth);
                }
            }
        }

    }

    timer (){
        if (g_sState=="init"){  //timeout during init.  We waited long enough for a random send of our data.  Ask for any that's missing
            if (! g_iGotSettingOwners) llMessageLinked(LINK_THIS,LM_SETTING_REQUEST,"auth_owner",NULL_KEY);
            if (! g_iGotSettingTrace) llMessageLinked(LINK_THIS,LM_SETTING_REQUEST,"subspy_trace",NULL_KEY);
            if (! g_iGotSettingRadar) llMessageLinked(LINK_THIS,LM_SETTING_REQUEST,"subspy_radar",NULL_KEY);
            if (! g_iGotSettingListen) llMessageLinked(LINK_THIS,LM_SETTING_REQUEST,"subspy_listen",NULL_KEY);
            if (! g_iGotSettingMeters) llMessageLinked(LINK_THIS,LM_SETTING_REQUEST,"subspy_meters",NULL_KEY);
            if (! g_iGotSettingMinutes) llMessageLinked(LINK_THIS,LM_SETTING_REQUEST,"subspy_minutes",NULL_KEY);
            g_sState="postInit";
            llSetTimerEvent(5.0);
        } else if (g_sState=="postInit") {  //postInit period complete, should have all of our data now
            Notify(g_kWearer,"\n\nATTENTION: This collar is running the Spy feature.\nYour primary owners will be able to track where you go, access your radar and read what you speak in the Nearby Chat. Only your own local chat will be relayed. IMs and the chat of 3rd parties cannot be spied on. Please use an updater to uninstall this feature if you do not consent to this kind of practice and remember that bondage, power exchange and S&M is of all things based on mutual trust.",FALSE);
            Notify(g_kWearer,"\nOpenCollar SPY add-on (trace, radar, listen) INSTALLED and AVAILABLE\n...checking for activated spy features...",FALSE);

            if (g_iTraceEnabled) g_sTPBuffer = "Rezzed at " + GetLocation();
            //Debug("Running sensor from postInit");
            g_sState="initialScan";
            llSensor("" ,"" , AGENT, g_iSensorRange, PI);

            llSetTimerEvent(0.0);

        }
    }

    sensor(integer iNum)
    {
        //Debug("Hit sensor event, "+(string)iNum);
        if (g_iRadarEnabled)
        {
            //put nearby avs in list
            list lAvBuffer;
            while (iNum) lAvBuffer += llDetectedName(--iNum);

            g_sOldAVBuffer = g_sCurrentAVs; //store last set of avis so we know if we need to include the list in the next report
            g_sCurrentAVs = llDumpList2String(llListSort(lAvBuffer, 1, TRUE), ", ");
            //Debug ("Complete avi list: "+g_sCurrentAVs);
        }
        DoReports(FALSE);
        if (g_sState=="initialScan"){
            UpdateSensor();
            UpdateListener();
            g_sState="running";
        }
    }

    no_sensor()
    {
        g_sOldAVBuffer = g_sCurrentAVs; //store last set of avis so we know if we need to include the list in the next report
        g_sCurrentAVs = "None";
        DoReports(FALSE);
    }

    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            g_sLoc = GetLocation();
        }
    }

    changed(integer iChange)
    {
        if((iChange & CHANGED_TELEPORT) || (iChange & CHANGED_REGION))
        {
            g_sOldAVBuffer="";
            if(g_iTraceEnabled)
            {
                g_sTPBuffer += "Teleport from " + g_sLoc + " to " +  GetLocation()+ " at " + GetTimestamp() + ".\n";
            }
            g_sLoc = GetLocation();
            UpdateSensor(); //if we don't update sensor here, we will not get any reports as the sensor runs the timer, and sensorRepeat stops on tp
        }

        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
}