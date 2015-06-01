////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - timer                               //
//                                 version 3.993                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

list g_lTimes;
integer g_iTimesLength;
integer g_iCurrentTime;
integer g_iOnTime;
integer g_iLastTime;
integer g_iFirstOnTime;
integer g_iFirstRealTime;
integer g_iLastRez;
integer n;//for loops
string g_sMessage;
integer MAX_TIME=0x7FFFFFFF;

integer ATTACHMENT_COMMAND = 602;
integer ATTACHMENT_FORWARD = 610;
//these can change
integer REAL_TIME=1;
integer REAL_TIME_EXACT=5;
integer ON_TIME=3;
integer ON_TIME_EXACT=7;

//string CTYPE = "collar";

integer g_iInterfaceChannel;
// end time keeper

string g_sSubMenu = "Timer";
string g_sParentMenu = "Apps";

key g_kMenuID;
key g_kOnMenuID;
key g_kRealMenuID;

key g_kWearer;

list g_lLocalButtons = ["RL","Online"];
list g_lTimeButtons = ["RESET","+00:01","+00:05","+00:30","+03:00","+24:00","-00:01","-00:05","-00:30","-03:00","-24:00"];

integer g_iOnRunning;
integer g_iOnSetTime;
integer g_iOnTimeUpAt;
integer g_iRealRunning;
integer g_iRealSetTime;
integer g_iRealTimeUpAt;

integer g_iCollarLocked;
integer g_iUnlockCollar = 0;
integer g_iClearRLVRestions = 0;
integer g_iUnleash = 0;
integer g_iBoth = 0;
integer g_iWhoCanChangeTime = 504;
integer g_iWhoCanChangeLeash = 504;

integer g_iTimeChange;

list lButtons;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510; 
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;

integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;

// Added by WhiteFire
integer TIMER_EVENT = -10000; // str = "start" or "end". For start, either "online" or "realtime".

integer WEARERLOCKOUT = 620;

string UPMENU = "BACK";

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    //Debug("Made menu.");
    return kID;
} 
/*
Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}*/

DoMenu(key keyID, integer iAuth)
{
    if (keyID)
    {
        //fnord
    }
    else
    {
        return;
    }
    //Debug("timeremaning:"+(string)(g_iOnTimeUpAt-g_iOnTime));
    
    string sPrompt = "\n A frozen pizza takes ~12 min to bake.\n";
    list lMyButtons = g_lLocalButtons + lButtons;

    sPrompt += "\n Online Timer: "+Int2Time(g_iOnSetTime);
    if (g_iOnRunning==1)
    {
        sPrompt += "\n Online Timer: "+Int2Time(g_iOnTimeUpAt-g_iOnTime)+" left\n";
    }
    else
    {
        sPrompt += "\n Online Timer: not running\n";
    }
    sPrompt += "\n RL Timer: "+Int2Time(g_iRealSetTime);
    if (g_iRealRunning==1)
    {
        sPrompt += "\n RL Timer: "+Int2Time(g_iRealTimeUpAt-g_iCurrentTime)+" left";
    }
    else
    {
        sPrompt += "\n RL Timer: not running";
    }
    if (g_iBoth)
    {
        lMyButtons += ["☒ combined"];
    }
    else
    {
        lMyButtons += ["☐ combined"];
    }
    if (g_iUnlockCollar)
    {
        lMyButtons += ["☒ unlock"];
    }
    else
    {
        lMyButtons += ["☐ unlock"];
    }
    if (g_iUnleash)
    {
        lMyButtons += ["☒ unleash"];
    }
    else
    {
        lMyButtons += ["☐ unleash"];
    }
    if (g_iClearRLVRestions)
    {
        lMyButtons += ["☒ clear RLV"];
    }
    else
    {
        lMyButtons += ["☐ clear RLV"];
    }
    if (g_iRealRunning || g_iOnRunning)
    {
        lMyButtons += ["STOP"];
        lMyButtons += ["RESET"];
    }
    else if (g_iRealSetTime || g_iOnSetTime)
    {
        lMyButtons += ["START"];
        lMyButtons += ["RESET"];    
    }
        sPrompt+="\n\nwww.opencollar.at/timer";
        
    llListSort(g_lLocalButtons, 1, TRUE);

    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

DoOnMenu(key keyID, integer iAuth)
{
    if (keyID == NULL_KEY) return;
    
    string sPrompt = "\n Online Time Settings\n";
    sPrompt += "\n Online Timer: "+Int2Time(g_iOnSetTime);
    if (g_iOnRunning)
    {
        sPrompt += "\n Online Timer: "+Int2Time(g_iOnTimeUpAt-g_iOnTime)+" left";
    }
    else
    {
        sPrompt += "\n Online Timer: not running";
    }
    g_kOnMenuID = Dialog(keyID, sPrompt, g_lTimeButtons, [UPMENU], 0, iAuth);
}

DoRealMenu(key keyID, integer iAuth)
{
    if (keyID == NULL_KEY) return;

    string sPrompt = "\n RL Time Settings\n";
    sPrompt += "\n RL timer: " + Int2Time(g_iRealSetTime);
    if (g_iRealRunning)
    {
        sPrompt += "\n RL Timer: "+Int2Time(g_iRealTimeUpAt-g_iCurrentTime)+" left";
    }
    else
    {
        sPrompt += "\n RL Timer: not running";
    }
    g_kRealMenuID = Dialog(keyID, sPrompt, g_lTimeButtons, [UPMENU], 0, iAuth);
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
    
    //this is the onley line that needs changing...
    return ( (string)iDays+" days "+
        llGetSubString("0"+(string)iHours,-2,-1) + ":"+
        llGetSubString("0"+(string)iMins,-2,-1) + ":"+
        llGetSubString("0"+(string)iSecs,-2,-1) );
    //return (string)iDays+":"+(string)iHours+":"+(string)iMins+":"+(string)iSecs;
}

TimerFinish()
{
    if(g_iBoth && (g_iOnRunning == 1 || g_iRealRunning == 1))
    {
        return;
    }
    llMessageLinked(LINK_THIS, WEARERLOCKOUT, "off", "");
    if(g_iUnlockCollar)
    {
        llMessageLinked(LINK_THIS, CMD_OWNER, "unlock", g_kWearer);
    }
    if(g_iClearRLVRestions)
    {
        llMessageLinked(LINK_THIS, CMD_OWNER, "clear", g_kWearer);
        if(!g_iUnlockCollar && g_iCollarLocked)
        {
            llSleep(2);
            llMessageLinked(LINK_THIS, CMD_OWNER, "lock", g_kWearer);
        }
    }
    if(g_iUnleash && g_iWhoCanChangeTime <= g_iWhoCanChangeLeash)
    {
        llMessageLinked(LINK_THIS, CMD_OWNER, "unleash", g_kWearer);
    }
    g_iUnlockCollar=g_iClearRLVRestions=g_iUnleash=0;
    g_iOnSetTime=g_iRealSetTime=0;
    g_iOnRunning=g_iRealRunning=0;
    g_iOnTimeUpAt=g_iRealTimeUpAt=0;
    g_iWhoCanChangeTime=504;
    llMessageLinked(LINK_SET,NOTIFY,"0"+"Yay! Timer expired!",g_kWearer);
    //llOwnerSay("Yay! Timer expired!");
    
    llMessageLinked(LINK_THIS, TIMER_EVENT, "end", "");
}

TimerStart(integer perm)
{
    // do What has to be Done
    g_iWhoCanChangeTime = perm;
    if(g_iRealSetTime)
    {
        g_iRealTimeUpAt=g_iCurrentTime+g_iRealSetTime;
        llMessageLinked(LINK_THIS, WEARERLOCKOUT, "on", "");
        llMessageLinked(LINK_THIS, TIMER_EVENT, "START", "RL");
        g_iRealRunning=1;
    }
    else
    {
        g_iRealRunning=3;
    }
    if(g_iOnSetTime)
    {
        g_iOnTimeUpAt=g_iOnTime+g_iOnSetTime;
        llMessageLinked(LINK_THIS, WEARERLOCKOUT, "on", "");
        llMessageLinked(LINK_THIS, TIMER_EVENT, "START", "Online");
        
        g_iOnRunning=1;
    }
    else
    {
        g_iOnRunning=3;
    }
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum == CMD_EVERYONE) return TRUE;
    else if (iNum > CMD_EVERYONE || iNum < CMD_OWNER) return FALSE;
    if (llToLower(sStr) == "timer" || sStr == "menu "+g_sSubMenu) DoMenu(kID, iNum);
    else if(llGetSubString(sStr, 0, 5) == "timer ")
    {
        //Debug(sStr);
        string sMsg=llGetSubString(sStr, 6, -1);
        //we got a response for something we handle locally
        if (sMsg == "RL") DoRealMenu(kID, iNum);
        else if (sMsg == "Online") DoOnMenu(kID, iNum);
        else if (sMsg == "START")
        {
            TimerStart(iNum);            
            if(kID != g_kWearer) DoMenu(kID, iNum);
        }
        else if (sMsg == "STOP")
        {
            TimerFinish();
            DoMenu(kID, iNum);
        }
        else if (sMsg == "RESET")
        {
            g_iRealSetTime=g_iRealTimeUpAt=0;
            g_iOnSetTime=g_iOnTimeUpAt=0;
            if(g_iRealRunning == 1 || g_iOnRunning == 1){
                g_iRealRunning=0;
                g_iOnRunning=0;
                TimerFinish();
            }
            DoMenu(kID, iNum);
        }
        else if (sMsg =="☒ combined")
        {
            g_iBoth = FALSE;
            DoMenu(kID, iNum);
        }
        else if (sMsg == "☐ combined")
        {
            g_iBoth = TRUE;
            DoMenu(kID, iNum);
        }
        else if(sMsg=="☒ unlock")
        {
            if (iNum == CMD_OWNER) g_iUnlockCollar=0;
            else
            {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
                //Notify(kID,"Only the owner can change if the " + CTYPE + " unlocks when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
        }
        else if(sMsg=="☐ unlock")
        {
            if(iNum == CMD_OWNER) g_iUnlockCollar=1;
            else
            {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
                //Notify(kID,"Only the owner can change if the " + CTYPE + " unlocks when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
         }
        else if(sMsg=="☒ clear RLV")
        {
            if(iNum == CMD_WEARER)
            {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
                //Notify(kID,"You cannot change if the RLV settings are cleared",FALSE);
            }
            else g_iClearRLVRestions=0;
            DoMenu(kID, iNum);
        }
        else if(sMsg=="☐ clear RLV")
        {
            if(iNum == CMD_WEARER)
            {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
                //Notify(kID,"You cannot change if the RLV settings are cleared",FALSE);
            }
            else g_iClearRLVRestions=1;
            DoMenu(kID, iNum);
        }
        else if(sMsg=="☒ unleash")
        {
            if(iNum <= g_iWhoCanChangeLeash) g_iUnleash=0;
            else
            {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
                //Notify(kID,"Only the someone who can leash the sub can change if the " + CTYPE + " unleashes when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
        }
        else if(sMsg=="☐ unleash")
        {
            if(iNum <= g_iWhoCanChangeLeash) g_iUnleash=1;
            else
            {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
                //Notify(kID,"Only the someone who can leash the sub can change if the " + CTYPE + " unleashes when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
        }
        else if(llGetSubString(sMsg, 0, 5) == "Online")
        {
            sMsg="on" + llStringTrim(llGetSubString(sMsg, 6, -1), STRING_TRIM_HEAD);                    
        }
        if(llGetSubString(sMsg, 0, 1) == "on")
        {
            sMsg=llStringTrim(llGetSubString(sMsg, 2, -1), STRING_TRIM_HEAD);
            if (iNum <= g_iWhoCanChangeTime)
            {
                list lTimes = llParseString2List(llGetSubString(sMsg, 1, -1), [":"], []);
                if (sMsg == "RESET")
                {
                    g_iOnSetTime=g_iOnTimeUpAt=0;
                    if(g_iOnRunning == 1)
                    {
                        //unlock
                        g_iOnRunning=0;
                        TimerFinish();
                    }
                }
                else if (llGetSubString(sMsg, 0, 0) == "+")
                {
                    g_iTimeChange=llList2Integer(lTimes,0)*60*60+llList2Integer(lTimes,1)*60;
                    g_iOnSetTime += g_iTimeChange;
                    if (g_iOnRunning==1)
                    {
                        g_iOnTimeUpAt += g_iTimeChange;
                    }
                    else if(g_iOnRunning==3)
                    {
                        g_iOnTimeUpAt=g_iOnTime+g_iOnSetTime;
                        g_iOnRunning=1;
                    }
                }
                else if (llGetSubString(sMsg, 0, 0) == "-")
                {
                    g_iTimeChange=-(llList2Integer(lTimes,0)*60*60+llList2Integer(lTimes,1)*60);
                    g_iOnSetTime += g_iTimeChange;
                    if (g_iOnSetTime<0)
                    {
                        g_iOnSetTime=0;
                    }
                    if (g_iOnRunning==1)
                    {
                        g_iOnTimeUpAt += g_iTimeChange;
                        if (g_iOnTimeUpAt<=g_iOnTime)
                        {
                            //unlock
                            g_iOnRunning=g_iOnSetTime=g_iOnTimeUpAt=0;
                            TimerFinish();
                        }
                    }
                }
                else if (llGetSubString(sMsg, 0, 0) == "=")
                {
                    g_iTimeChange=llList2Integer(lTimes,0)*60*60+llList2Integer(lTimes,1)*60;
                    if (g_iTimeChange <= 0) return TRUE; // use clear.

                    g_iOnSetTime = g_iTimeChange;
                    if (g_iOnRunning==1)
                    {
                        g_iOnTimeUpAt = g_iOnTime + g_iTimeChange;
                    }
                    else if(g_iOnRunning==3)
                    {
                        g_iOnTimeUpAt=g_iOnTime + g_iTimeChange;
                        g_iOnRunning=1;
                    }
                }
                else
                {
                    return TRUE;
                }
            }
            DoOnMenu(kID, iNum);
        }
        else if(llGetSubString(sMsg, 0, 7) == "RL")
        {
            sMsg="real" + llStringTrim(llGetSubString(sMsg, 6, -1), STRING_TRIM_HEAD);
        }
        if(llGetSubString(sMsg, 0, 3) == "real")
        {
            sMsg=llStringTrim(llGetSubString(sMsg, 4, -1), STRING_TRIM_HEAD);
            list lTimes = llParseString2List(llGetSubString(sMsg, 1, -1), [":"], []);
            if (iNum <= g_iWhoCanChangeTime)
            {
                if (sMsg == "RESET")
                {
                    g_iRealSetTime=g_iRealTimeUpAt=0;
                    if(g_iRealRunning == 1)
                    {
                        //unlock
                        g_iRealRunning=0;
                        TimerFinish();
                    }
                }
                else if (llGetSubString(sMsg, 0, 0) == "+")
                {
                    g_iTimeChange=llList2Integer(lTimes,0)*60*60+llList2Integer(lTimes,1)*60;
                    g_iRealSetTime += g_iTimeChange;
                    if (g_iRealRunning==1) g_iRealTimeUpAt += g_iTimeChange;
                    else if(g_iRealRunning==3)
                    {
                        g_iRealTimeUpAt=g_iCurrentTime+g_iRealSetTime;
                        g_iRealRunning=1;
                    }
                }
                else if (llGetSubString(sMsg, 0, 0) == "-")
                {
                    g_iTimeChange=-(llList2Integer(lTimes,0)*60*60+llList2Integer(lTimes,1)*60);
                    g_iRealSetTime += g_iTimeChange;
                    if (g_iRealSetTime<0) g_iRealSetTime=0;
                    if (g_iRealRunning==1)
                    {
                        g_iRealTimeUpAt += g_iTimeChange;
                        if (g_iRealTimeUpAt<=g_iCurrentTime)
                        {
                            //unlock
                            g_iRealRunning=g_iRealSetTime=g_iRealTimeUpAt=0;
                            TimerFinish();
                        }
                    }
                }
                else if (llGetSubString(sMsg, 0, 0) == "=")
                {
                    g_iTimeChange=llList2Integer(lTimes,0)*60*60+llList2Integer(lTimes,1)*60;
                    if (g_iTimeChange <= 0) return TRUE; // Not handled.                    
                    g_iRealSetTime = g_iTimeChange;
                    if (g_iRealRunning==1) g_iRealTimeUpAt = g_iCurrentTime+g_iRealSetTime;
                    else if(g_iRealRunning==3)
                    {
                        g_iRealTimeUpAt=g_iCurrentTime+g_iRealSetTime;
                        g_iRealRunning=1;
                    }
                }
                else return TRUE;
            }
            DoRealMenu(kID, iNum);
        }
    }
    return TRUE;
}


default {
    on_rez(integer iParam) {
        g_iLastTime=g_iLastRez=llGetUnixTime();
        llRegionSayTo(g_kWearer, g_iInterfaceChannel, "timer|sendtimers");
        if (g_iRealRunning == 1 || g_iOnRunning == 1) {
            llMessageLinked(LINK_THIS, WEARERLOCKOUT, "on", "");
        }
    }
    state_entry() {
        llSetMemoryLimit(40960);  //2015-05-06 (4238 bytes free)
        g_iLastTime=llGetUnixTime();
        llSetTimerEvent(1);
        g_kWearer = llGetOwner();
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
        g_iFirstOnTime=MAX_TIME;
        g_iFirstRealTime=MAX_TIME;
        llRegionSayTo(g_kWearer, g_iInterfaceChannel, "timer|sendtimers");
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        list info  = llParseString2List (sStr, ["|"], []);
        if(iNum==ATTACHMENT_FORWARD && llList2String(info, 0)=="timer")//request for us
        {
            //Debug(sStr);
            string sCommand = llList2String(info, 1);
            integer type = llList2Integer(info, 2);
            if(sCommand=="settimer")
            {
                //should check values but I am not yet.
                if(type==REAL_TIME)
                {
                    integer newtime = llList2Integer(info, 3) +g_iCurrentTime;
                    g_lTimes=g_lTimes+[REAL_TIME,newtime];
                    if(g_iFirstRealTime>newtime)
                    {
                        g_iFirstRealTime=newtime;
                    }
                    g_sMessage="timer|timeis|"+(string)REAL_TIME+"|"+(string)g_iCurrentTime;
                }
                else if(type==REAL_TIME_EXACT)
                {
                    integer newtime = llList2Integer(info, 3);
                    g_lTimes=g_lTimes+[REAL_TIME,newtime];
                    if(g_iFirstRealTime>newtime)
                    {
                        g_iFirstRealTime=newtime;
                    }
                }
                else if(type==ON_TIME)
                {
                    integer newtime = llList2Integer(info, 3) +g_iOnTime;
                    g_lTimes=g_lTimes+[ON_TIME,newtime];
                    if(g_iFirstOnTime>newtime)
                    {
                        g_iFirstOnTime=newtime;
                    }
                    g_sMessage="timer|timeis|"+(string)ON_TIME+"|"+(string)g_iOnTime;
                }
                else if(type==ON_TIME_EXACT)
                {
                    integer newtime = llList2Integer(info, 3) +g_iOnTime;
                    g_lTimes=g_lTimes+[ON_TIME,newtime];
                    if(g_iFirstOnTime>newtime)
                    {
                        g_iFirstOnTime=newtime;
                    }
                }
            }
            else if(sCommand=="gettime")
            {
                if(type==REAL_TIME)
                {
                    g_sMessage="timer|timeis|"+(string)REAL_TIME+"|"+(string)g_iCurrentTime;
                }
                else if(type==ON_TIME)
                {
                    g_sMessage="timer|timeis|"+(string)ON_TIME+"|"+(string)g_iOnTime;
                }
            }
            else
            {
                return;
                //message got sent to us or something went wrong
            }
            if(iNum==ATTACHMENT_FORWARD)
            {
                llRegionSayTo(g_kWearer, g_iInterfaceChannel, g_sMessage);
            }
        }
        else if(iNum == CMD_WEARER && sStr == "menu")
        {
            if (g_iOnRunning || g_iRealRunning)
                llMessageLinked(LINK_SET,NOTIFY,"0"+ "You are locked out of the %DEVICETYPE% until the timer expires",kID);//Notify(kID , "You are locked out of the " + CTYPE + " until the timer expires", FALSE);
        }
        else if (iNum == LM_SETTING_DELETE)
        {
            if (sStr == "leash_leashedto") g_iWhoCanChangeLeash=504;
            else if (sStr == "Global_locked") g_iCollarLocked=0;
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string token = llList2String(lParams, 0);
            string value = llList2String(lParams, 1);
            if (token == "Global_locked" && (integer)value == 1) g_iCollarLocked = 1;
            else if (token == "leash_leashedto")
            {
                integer auth = (integer)llList2String(llParseString2List(value, [","], []), 1);
                if (auth < g_iWhoCanChangeLeash)
                {
                    g_iWhoCanChangeLeash = auth;
                }
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "Global_locked") g_iCollarLocked=(integer)sValue;
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)           
        { // our parent menu requested to receive buttons, so send ours
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            lButtons = [] ; // flush submenu buttons
            llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubMenu, "");
        }
        else if (iNum == MENUNAME_RESPONSE) // a button is sned ot be added to a plugin
        {
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu)
            {//someone wants to stick something in our menu
                string sButton = llList2String(lParts, 1);
                if (llListFindList(lButtons, [sButton]) == -1)
                    // if the button isnt in our benu yet, than we add it
                {
                    lButtons = llListSort(lButtons + [sButton], 1, TRUE);
                }
            }
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            integer iIndex;
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu)
            {
                string sButton = llList2String(lParts, 1);
                iIndex = llListFindList(lButtons, [sButton]);
                if (iIndex != -1)

                {
                    lButtons = llDeleteSubList(lButtons, iIndex, iIndex);
                }
            }
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == DIALOG_RESPONSE)
        {
            if (llListFindList([g_kMenuID, g_kOnMenuID, g_kRealMenuID], [kID]) != -1)
            {//this is one of our menus
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMsg = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);                 
                integer iAuth = (integer)llList2String(lMenuParams, 3);                 
                if (kID == g_kMenuID)
                {            
                    
                    if (sMsg == UPMENU)
                    {
                        llMessageLinked(LINK_THIS, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if (llListFindList(lButtons, [sMsg]))
                    {
                        UserCommand(iAuth, "timer " + sMsg, kAv);
                    }
                    else if (~llListFindList(lButtons, [sMsg]))
                    {

                        llMessageLinked(LINK_THIS, iAuth, "menu "+sMsg, kAv);
                    }
                }
                else if (kID == g_kOnMenuID)
                {
                    if (sMsg == UPMENU) DoMenu(kAv, iAuth);
                    else UserCommand(iAuth, "timer on"+sMsg, kAv);
                }
                else if (kID == g_kRealMenuID)
                {
                    if (sMsg == UPMENU) DoMenu(kAv, iAuth);
                    else UserCommand(iAuth, "timer real"+sMsg, kAv);
                }                  
            }          
        }
    }

    timer()
    {
        g_iCurrentTime=llGetUnixTime();
        if (g_iCurrentTime<(g_iLastRez+60))
        {
           return;
        }
        if ((g_iCurrentTime-g_iLastTime)<60)
        {
            g_iOnTime+=g_iCurrentTime-g_iLastTime;
        }
        if(g_iOnTime>=g_iFirstOnTime)
        {
            //could store which is need but if both are trigered it will have to send both anyway I prefer not to check for that.
            g_sMessage="timer|timeis|"+(string)ON_TIME+"|"+(string)g_iOnTime;
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, g_sMessage);
            
            g_iFirstOnTime=MAX_TIME;
            g_iTimesLength=llGetListLength(g_lTimes);
            for(n = 0; n < g_iTimesLength; n = n + 2)// send notice and find the next time.
            {
                if(llList2Integer(g_lTimes, n)==ON_TIME)
                {
                    while(llList2Integer(g_lTimes, n+1)<=g_iOnTime&&llList2Integer(g_lTimes, n)==ON_TIME&&g_lTimes!=[])
                    {
                        g_lTimes=llDeleteSubList(g_lTimes, n, n+1);
                        g_iTimesLength=llGetListLength(g_lTimes);
                    }
                    if(llList2Integer(g_lTimes, n)==ON_TIME&&llList2Integer(g_lTimes, n+1)<g_iFirstOnTime)
                    {
                        g_iFirstOnTime=llList2Integer(g_lTimes, n+1);
                    }
                }
            }
        }
        if(g_iCurrentTime>=g_iFirstRealTime)
        {
            //could store which is need but if both are trigered it will have to send both anyway I prefer not to check for that.
            g_sMessage="timer|timeis|"+(string)REAL_TIME+"|"+(string)g_iCurrentTime;
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, g_sMessage);
             
            g_iFirstRealTime=MAX_TIME;
            g_iTimesLength=llGetListLength(g_lTimes);
            for(n = 0; n < g_iTimesLength; n = n + 2)// send notice and find the next time.
            {
                if(llList2Integer(g_lTimes, n)==REAL_TIME)
                {
                    while(llList2Integer(g_lTimes, n+1)<=g_iCurrentTime&&llList2Integer(g_lTimes, n)==REAL_TIME)
                    {
                        g_lTimes=llDeleteSubList(g_lTimes, n, n+1);
                        g_iTimesLength=llGetListLength(g_lTimes);
                    }
                    if(llList2Integer(g_lTimes, n)==REAL_TIME&&llList2Integer(g_lTimes, n+1)<g_iFirstRealTime)
                    {
                        g_iFirstRealTime=llList2Integer(g_lTimes, n+1);
                    }
                }
            }
        }
        if(g_iOnRunning == 1 && g_iOnTimeUpAt<=g_iOnTime)
        {
            g_iOnRunning = 0;
            TimerFinish();
        }
        if(g_iRealRunning == 1 && g_iRealTimeUpAt<=g_iCurrentTime)
        {
            g_iRealRunning = 0;
            TimerFinish();
        }
        g_iLastTime=g_iCurrentTime;
    }
    
/*
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/
}
