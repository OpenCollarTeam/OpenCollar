//OpenCollar - timer

// LVs 0.001
//      Hacks to make it play nice with others.
//      1) Does not give lockout error unless timers are actually running.
//      2) TIMER_EVENT for timers ending and starting.
//      3) LINK_WHAT = LINK_SET (or LINK_THIS, whatever turns you on.)
//      4) g_sToyName... because we are not always included in a collar.
//      5) DoMenu whatever changed to return on NULL_KEY, in case of internal calls.
//      6) TimerStart() factored out of the state for cleaness. (I had originally planned to have another way to call it, but decided just calling it with COMMAND_OWNER was cleaner.)
//      7) Added a = version of the time setting, so you can set a time exactly from another script.
//      8) MENUNAME_REMOVE support.
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


integer LINK_WHAT = LINK_SET;
string g_sToyName = "collar";

//key g_kWearer; why is this in here twice.
integer g_iInterfaceChannel;
// end time keeper

// Template for creating a OpenCOllar Plugin - OpenCollar Version 3.0xx

//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//Collar Cuff Menu

string g_sSubMenu = "Timer"; // Name of the submenu
string g_sParentMenu = "AddOns"; // mname of the menu, where the menu plugs in

key g_kMenuID;
key g_kOnMenuID;
key g_kRealMenuID;

key g_kWearer; // key of the current wearer to reset only on owner changes

list g_lLocalButtons = ["realtime","online"]; // any local, not changing buttons which will be used in this plugin, leave emty or add buttons as you like
list g_lTimeButtons = ["clear","+00:01","+00:05","+00:30","+03:00","+24:00","-00:01","-00:05","-00:30","-03:00","-24:00"];

integer g_iOnRunning;
integer g_iOnSetTime;
integer g_iOnTimeUpAt;
integer g_iLastOnTime;
integer g_iClockTimeAtLastOnTime;
integer g_iRealRunning;
integer g_iRealSetTime;
integer g_iRealTimeUpAt;
integer g_iLastRealTime;
integer g_iClockTimeAtLastRealTime;

integer g_iUnlockCollar;
integer g_iCollarLocked;
integer g_iClearRLVRestions;
integer g_iUnleash;
integer g_iBoth;
integer g_iWhoCanChangeTime;
integer g_iWhoCanChangeLeash;
integer g_iWhoCanOtherSettings;


integer g_iClockTime;
integer g_iTimeChange;
integer g_iOnUpdate;
integer g_iRealUpdated;

integer g_iWhichMenu;
key g_kMenuWho;

list lButtons;

//OpenCollae MESSAGE MAP
// messages for authenticating users
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;
// added so when the sub is locked out they can use postions
integer COMMAND_WEARERLOCKEDOUT = 521;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

// messages for storing and retrieving values from http db
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db


// messages for creating OC menu structure
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

// messages for RLV commands
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

// messages for poses and couple anims
integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

// Added by WhiteFire
integer TIMER_EVENT = -10000; // str = "start" or "end". For start, either "online" or "realtime".

integer WEARERLOCKOUT=620;


// menu option to go one step back in menustructure
string UPMENU = "^";
string MORE = ">";

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
//= parameters   :    string    sMsg    message string received
//=
//= return        :    none
//=
//= description  :    output debug messages
//=
//===============================================================================


Debug(string sMsg)
{
    //llOwnerSay(llGetScriptName() + ": " + sMsg);
}

//===============================================================================
//= parameters   :    string    sMsg    message string received
//=
//= return        :    integer TRUE/FALSE
//=
//= description  :    checks if a string begin with another string
//=
//===============================================================================

integer StartsWith(string sHaystack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return (llDeleteSubString(sHaystack, llStringLength(sNeedle), -1) == sNeedle);
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

//===============================================================================
//= parameters   :    string    keyID   key of person requesting the menu
//=
//= return        :    none
//=
//= description  :    build menu and display to user
//=
//===============================================================================

DoMenu(key keyID, integer iAuth)
{
    if (keyID)
    {
        // not needed we jsut want theh false
    }
    else
    {
        return;
    }

    Debug("timeremaning:"+(string)(g_iOnTimeUpAt-g_iOnTime));
    string sPrompt = "Pick an option.";
    list lMyButtons = g_lLocalButtons + lButtons;

    //fill in your button list and additional prompt here
    sPrompt += "\n Online timer - "+Int2Time(g_iOnSetTime);
    if (g_iOnRunning==1)
    {
        sPrompt += "\n Online timer - "+Int2Time(g_iOnTimeUpAt-g_iOnTime)+" left";
        //lMyButtons += ["stop online"];
    }
    else
    {
        sPrompt += "\n Online timer - not running";
        //lMyButtons += ["start online"];
    }
    sPrompt += "\n Realtime timer - "+Int2Time(g_iRealSetTime);
    if (g_iRealRunning==1)
    {
        sPrompt += "\n Realtime timer - "+Int2Time(g_iRealTimeUpAt-g_iCurrentTime)+" left";
        //lMyButtons += ["stop realtime"];
    }
    else
    {
        sPrompt += "\n Realtime timer - not running";
        //lMyButtons += ["start realtime"];
    }
    if (g_iBoth)
    {
        sPrompt += "\n When BOTH the online and realtime timer go off:";
        lMyButtons += ["(*)bothtime"];
    }
    else
    {
        sPrompt += "\n When EITHER the online or realtime timer go off:";
        lMyButtons += ["()bothtime"];
    }
    if (g_iRealRunning || g_iOnRunning)
    {
        lMyButtons += ["stop"];
    }
    else if (g_iRealSetTime || g_iOnSetTime)
    {
        lMyButtons += ["start"];    
    }
    if (g_iUnlockCollar)
    {
        sPrompt += "\n\t the " + g_sToyName + " WILL be unlocked";
        lMyButtons += ["(*)unlock"];
    }
    else
    {
        sPrompt += "\n\t the " + g_sToyName + " will NOT be unlocked";
        lMyButtons += ["()unlock"];
    }
    if (g_iUnleash)
    {
        sPrompt += "\n\t the " + g_sToyName + " WILL be unleashed";
        lMyButtons += ["(*)unleash"];
    }
    else
    {
        sPrompt += "\n\t the " + g_sToyName + " will NOT be unleashed";
        lMyButtons += ["()unleash"];
    }
    if (g_iClearRLVRestions)
    {
        sPrompt += "\n\t the RLV restions WILL be cleared";
        lMyButtons += ["(*)clearRLV"];
    }
    else
    {
        sPrompt += "\n\t the RLV restions will NOT be cleared";
        lMyButtons += ["()clearRLV"];
    }

    llListSort(g_lLocalButtons, 1, TRUE); // resort menu buttons alphabetical

    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

DoOnMenu(key keyID, integer iAuth)
{
    if (keyID == NULL_KEY) return;
    
    string sPrompt = "Pick an option.";
    sPrompt += "\n Online timer - "+Int2Time(g_iOnSetTime);
    if (g_iOnRunning)
    {
        sPrompt += "\n Online timer - "+Int2Time(g_iOnTimeUpAt-g_iOnTime)+" left";
    }
    else
    {
        sPrompt += "\n Online timer - not running";
    }
    g_kOnMenuID = Dialog(keyID, sPrompt, g_lTimeButtons, [UPMENU], 0, iAuth);
}

DoRealMenu(key keyID, integer iAuth)
{
    if (keyID == NULL_KEY) return;

    string sPrompt = "Pick an option.";
    //fill in your button list and additional prompt here
    sPrompt += "\n Realtime timer - " + Int2Time(g_iRealSetTime);
    if (g_iRealRunning)
    {
        sPrompt += "\n Realtime timer - "+Int2Time(g_iRealTimeUpAt-g_iCurrentTime)+" left";
    }
    else
    {
        sPrompt += "\n Realtime timer - not running";
    }
    g_kRealMenuID = Dialog(keyID, sPrompt, g_lTimeButtons, [UPMENU], 0, iAuth);
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

TimerWhentOff()
{
    if(g_iBoth && (g_iOnRunning == 1 || g_iRealRunning == 1))
    {
        return;
    }
    llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "off", "");
    g_iOnSetTime=g_iRealSetTime=0;
    g_iOnRunning=g_iRealRunning=0;
    g_iOnTimeUpAt=g_iRealTimeUpAt=0;
    g_iWhoCanChangeTime=504;
    if(g_iUnlockCollar)
    {
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "unlock", g_kWearer);
    }
    if(g_iClearRLVRestions)
    {
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "clear", g_kWearer);
        if(!g_iUnlockCollar && g_iCollarLocked)
        {
            llSleep(2);
            llMessageLinked(LINK_WHAT, COMMAND_OWNER, "lock", g_kWearer);
        }
    }
    if(g_iUnleash)
    {
        llMessageLinked(LINK_WHAT, COMMAND_OWNER, "unleash", "");
    }
    g_iUnlockCollar=g_iClearRLVRestions=g_iUnleash=0;
    Notify(g_kWearer, "The timer has expired", TRUE);
    
    llMessageLinked(LINK_WHAT, TIMER_EVENT, "end", "");
}

TimerStart(integer perm)
{
    // do What has to be Done
    g_iWhoCanChangeTime = perm;
    if(g_iRealSetTime)
    {
        g_iRealTimeUpAt=g_iCurrentTime+g_iRealSetTime;
        llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "on", "");
        llMessageLinked(LINK_WHAT, TIMER_EVENT, "start", "realtime");
        g_iRealRunning=1;
    }
    else
    {
        g_iRealRunning=3;
    }
    if(g_iOnSetTime)
    {
        g_iOnTimeUpAt=g_iOnTime+g_iOnSetTime;
        llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "on", "");
        llMessageLinked(LINK_WHAT, TIMER_EVENT, "start", "online");
        
        g_iOnRunning=1;
    }
    else
    {
        g_iOnRunning=3;
    }
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check
    //someone asked for our menu
    //give this plugin's menu to kID
    if (llToLower(sStr) == "timer" || sStr == "menu "+g_sSubMenu) DoMenu(kID, iNum);
    else if(llGetSubString(sStr, 0, 5) == "timer ")
    {
        Debug(sStr);
        string sMsg=llGetSubString(sStr, 6, -1);
        //we got a response for something we handle locally
        if (sMsg == "realtime") DoRealMenu(kID, iNum);
        else if (sMsg == "online") DoOnMenu(kID, iNum);
        else if (sMsg == "start")
        {
            TimerStart(iNum);            
            if(kID != g_kWearer) DoMenu(kID, iNum);
        }
        else if (sMsg == "stop")
        {
            TimerWhentOff();
            DoMenu(kID, iNum);
        }
        else if (sMsg == "(*)bothtime")
        {
            g_iBoth = FALSE;
            DoMenu(kID, iNum);
        }
        else if (sMsg == "()bothtime")
        {
            g_iBoth = TRUE;
            DoMenu(kID, iNum);
        }
        else if(sMsg=="(*)unlock")
        {
            if (iNum == COMMAND_OWNER) g_iUnlockCollar=0;
            else
            {
                Notify(kID,"Only the owner can change if the " + g_sToyName + " unlocks when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
        }
        else if(sMsg=="()unlock")
        {
            if(iNum == COMMAND_OWNER) g_iUnlockCollar=1;
            else
            {
                Notify(kID,"Only the owner can change if the " + g_sToyName + " unlocks when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
         }
        else if(sMsg=="(*)clearRLV")
        {
            if(iNum == COMMAND_WEARER)
            {
                Notify(kID,"You cannot change if the RLV settings are cleared",FALSE);
            }
            else g_iClearRLVRestions=0;
            DoMenu(kID, iNum);
        }
        else if(sMsg=="()clearRLV")
        {
            if(iNum == COMMAND_WEARER)
            {
                Notify(kID,"You cannot change if the RLV settings are cleared",FALSE);
            }
            else g_iClearRLVRestions=1;
            DoMenu(kID, iNum);
        }
        else if(sMsg=="(*)unleash")
        {
            if(iNum <= g_iWhoCanChangeLeash) g_iUnleash=0;
            else
            {
                Notify(kID,"Only the someone who can leash the sub can change if the " + g_sToyName + " unleashes when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
        }
        else if(sMsg=="()unleash")
        {
            if(iNum <= g_iWhoCanChangeLeash) g_iUnleash=1;
            else
            {
                Notify(kID,"Only the someone who can leash the sub can change if the " + g_sToyName + " unleashes when the timer runs out.",FALSE);
            }
            DoMenu(kID, iNum);
        }
        else if(llGetSubString(sMsg, 0, 5) == "online")
        {
            sMsg="on" + llStringTrim(llGetSubString(sMsg, 6, -1), STRING_TRIM_HEAD);                    
        }
        if(llGetSubString(sMsg, 0, 1) == "on")
        {
            sMsg=llStringTrim(llGetSubString(sMsg, 2, -1), STRING_TRIM_HEAD);
            if (iNum <= g_iWhoCanChangeTime)
            {
                list lTimes = llParseString2List(llGetSubString(sMsg, 1, -1), [":"], []);
                if (sMsg == "clear")
                {
                    g_iOnSetTime=g_iOnTimeUpAt=0;
                    if(g_iOnRunning == 1)
                    {
                        //unlock
                        g_iOnRunning=0;
                        TimerWhentOff();
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
                            TimerWhentOff();
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
        else if(llGetSubString(sMsg, 0, 7) == "realtime")
        {
            sMsg="real" + llStringTrim(llGetSubString(sMsg, 6, -1), STRING_TRIM_HEAD);
        }
        if(llGetSubString(sMsg, 0, 3) == "real")
        {
            sMsg=llStringTrim(llGetSubString(sMsg, 4, -1), STRING_TRIM_HEAD);
            list lTimes = llParseString2List(llGetSubString(sMsg, 1, -1), [":"], []);
            if (iNum <= g_iWhoCanChangeTime)
            {
                if (sMsg == "clear")
                {
                    g_iRealSetTime=g_iRealTimeUpAt=0;
                    if(g_iRealRunning == 1)
                    {
                        //unlock
                        g_iRealRunning=0;
                        TimerWhentOff();
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
                            TimerWhentOff();
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


default
{
    state_entry()
    {
        g_iLastTime=llGetUnixTime();
        llSetTimerEvent(1);
        g_kWearer = llGetOwner();
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0)
        {
              g_iInterfaceChannel = -g_iInterfaceChannel;
        }
        g_iFirstOnTime=MAX_TIME;
        g_iFirstRealTime=MAX_TIME;
        llWhisper(g_iInterfaceChannel, "timer|sendtimers");

        //end of timekeeper
        //g_kWearer=llGetOwner();

        // sleep a sceond to allow all scripts to be initialized
        llSleep(1.0);
        // send reequest to main menu and ask other menus if the wnt to register with us
        llMessageLinked(LINK_WHAT, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
        llMessageLinked(LINK_WHAT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        
        //set settings
        g_iUnlockCollar=0;
        g_iClearRLVRestions=0;
        g_iUnleash=0;
        g_iBoth=0;
        g_iWhoCanChangeTime=504;
        g_iWhoCanChangeLeash=504;
        g_iWhoCanOtherSettings=504;

    }
    on_rez(integer iParam)
    {
        g_iLastTime=g_iLastRez=llGetUnixTime();
        llWhisper(g_iInterfaceChannel, "timer|sendtimers");
        if (g_iRealRunning == 1 || g_iOnRunning == 1)
        {
            llMessageLinked(LINK_WHAT, WEARERLOCKOUT, "on", "");
            Debug("timer is running real:"+(string)g_iRealRunning+" on:"+(string)g_iOnRunning);
        }
    }

    // listen for likend messages fromOC scripts
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        list info  = llParseString2List (sStr, ["|"], []);
        if(iNum==ATTACHMENT_FORWARD && llList2String(info, 0)=="timer")//request for us
        {
            Debug(sStr);
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
                llWhisper(g_iInterfaceChannel, g_sMessage);//need to wispear
            }
        }
        else if(iNum == COMMAND_WEARERLOCKEDOUT && sStr == "menu")
        {
            if (g_iRealRunning || g_iRealRunning)
                Notify(kID , "You are locked out of the " + g_sToyName + " until the timer expires", FALSE);
        }
        else if (iNum == LM_SETTING_DELETE )
        {
            if (sStr == "leashedto")
            {
                g_iWhoCanChangeLeash=504;
            }
        }
        else if (iNum == LM_SETTING_DELETE)
        {
            if (sStr == "locked")
            {
                g_iCollarLocked=0;
            }
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            if (llGetSubString(sStr, 0, 8) == "leashedto")
            {
                integer temp = llList2Integer( llParseString2List( sStr , [","] , [] ) , 1 );
                if (temp < g_iWhoCanChangeLeash)
                {
                    g_iWhoCanChangeLeash=temp;
                    g_iUnleash=0;
                }
            }
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            if (sStr == "locked=1")
            {
                g_iCollarLocked=1;
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "locked")
            {
                g_iCollarLocked=(integer)sValue;
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            // our parent menu requested to receive buttons, so send ours
        {

            llMessageLinked(LINK_WHAT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum == MENUNAME_RESPONSE)
            // a button is sned ot be added to a plugin
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
            // a button is sned ot be added to a plugin
        {
            integer iIndex;
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu)
            {//someone wants to stick something in our menu
                string sButton = llList2String(lParts, 1);
                iIndex = llListFindList(lButtons, [sButton]);
                if (iIndex != -1)
                    // if the button is in the menu, remove it
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
                    
                    // request to change to parrent menu
                    if (sMsg == UPMENU)
                    {
                        //give kAv the parent menu
                        llMessageLinked(LINK_WHAT, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if (llListFindList(lButtons, [sMsg]))
                    {
                        UserCommand(iAuth, "timer " + sMsg, kAv);
                    }
                    else if (~llListFindList(lButtons, [sMsg]))
                    {
                        //we got a command which another command pluged into our menu
                        llMessageLinked(LINK_WHAT, iAuth, "menu "+sMsg, kAv);
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
            llWhisper(g_iInterfaceChannel, g_sMessage);
            
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
            llWhisper(g_iInterfaceChannel, g_sMessage);
            
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
            TimerWhentOff();
        }
        if(g_iRealRunning == 1 && g_iRealTimeUpAt<=g_iCurrentTime)
        {
            g_iRealRunning = 0;
            TimerWhentOff();
        }
        g_iLastTime=g_iCurrentTime;
    }

}