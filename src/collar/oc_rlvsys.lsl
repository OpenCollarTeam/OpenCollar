////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - rlvmain                               //
//                                 version 3.956                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//3.934: Something situation could cause the viewer check to get stuck. Not clear what, but I've thrown in a few robustness measures that hopefully should sort that out.
//new viewer checking method, as of 2.73
//on rez, restart script
//on script start, query db for rlvon setting
//on rlvon response, if rlvon=0 then just switch to checked state.  if rlvon=1 or rlvon=unset then open listener, do @versionnum, start 30 second timer
//on listen, we got version, so stop timer, close listen, turn on rlv flag, and switch to checked state
//on timer, we haven't heard from viewer yet.  Either user is not running RLV, or else they're logging in and viewer could not respond yet when we asked.
//so do @versionnum one more time, and wait another 30 seconds.
//on next timer, give up. User is not running RLV.  Stop timer, close listener, set rlv flag to FALSE, save to db, and switch to checked state.

integer g_iRLVOn = FALSE;//set to TRUE if DB says user has turned RLV features on
integer g_iViewerCheck = FALSE;//set to TRUE if viewer is has responded to @versionnum message
integer g_iRLVNotify = FALSE;//if TRUE, ownersay on each RLV restriction
integer g_iListener;
float g_fVersionTimeOut = 30.0; //MD- changed from 60. 2 minute wait before finding RLV is off is too long.
integer g_iVersionChan = 293847;
integer g_iRlvVersion;
integer g_iCheckCount;//increment this each time we say @versionnum.  check it each time timer goes off in default state. give up if it's >= 2
string g_sRLVString = "RestrainedLife viewer v1.20";

//"checked" state - HANDLING RLV SUBMENUS AND COMMANDS
//on start, request RLV submenus
//on rlv submenu response, add to list
//on main submenu "RLV", bring up this menu

string g_sParentMenu = "Main";
string g_sSubMenu = "RLV";
list g_lMenu;
key kMenuID;
integer RELAY_CHANNEL = -1812221819;
integer g_iVerbose;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;
integer COMMAND_RELAY_SAFEWORD = 511;

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
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TURNON = "  ON";
string TURNOFF = " OFF";
string CLEAR = "CLEAR ALL";
string CTYPE = "collar";
key g_kWearer;
string g_sScript;

string g_sRlvVersionString="(unknown)";

//re make rlv restrictions after teleport or region change, because SL seems to be losing them
integer g_iTimestamp;  //stores time of the last request for RLV to refresh

integer g_iLastDetach; //unix time of the last detach: used for checking if the detached time was small enough for not triggering the ping mechanism


Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

CheckVersion(integer iSecond)
{
    if (g_iCheckCount && !iSecond) {
        return; //ongoing try
    }
    if (g_iVerbose)
    {
        //Notify(g_kWearer, "Attempting to enable Restrained Love Viewer functions.  " + g_sRLVString+ " or higher is required for all features to work.", TRUE);
        llOwnerSay( "Checking you out for hotness (and RLV), please wait a moment before use.");
    }
    //open listener
    g_iListener = llListen(g_iVersionChan, "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_fVersionTimeOut);
    //do ownersay
    g_iCheckCount = !iSecond;
    llOwnerSay("@versionnum=" + (string)g_iVersionChan);
}

DoMenu(key kID, integer iAuth)
{
    list lButtons;
    if (g_iRLVOn)
    {
        lButtons += [TURNOFF, CLEAR] + llListSort(g_lMenu, 1, TRUE);
    }
    else
    {
        lButtons += [TURNON];
    }

    string sPrompt = "\n\n- Restrained Love Viewer Options -\n";
    if (g_iRlvVersion) sPrompt += "\n- Detected version of RLV API: "+g_sRlvVersionString;
    kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}
string PrettyVersion(string iVersion)
{
    integer i=(integer)iVersion;
    string s3=llGetSubString((string)(i/100),-2,-1);
    string s2=llGetSubString((string)(i/10000),-2,-1);
    string s1=llGetSubString((string)(i/1000000),-2,-1);
    return s1+"."+s2+"."+s3;
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

// http://wiki.secondlife.com/wiki/llSubStringIndex
integer StartsWith(string sHayStack, string sNeedle) {
    return llDeleteSubString(sHayStack, llStringLength(sNeedle), -1) == sNeedle;
}


// Book keeping functions

list g_lOwners;

list g_lSources=[];
list g_lRestrictions=[];
list g_lOldRestrictions;
list g_lOldSources;

list g_lBaked=[];

key g_kSitter=NULL_KEY;
key g_kSitTarget=NULL_KEY;


integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

SendCommand(string sCmd)
{
    llOwnerSay("@"+sCmd);
    if (g_iRLVNotify)
    {
        Notify(g_kWearer, "Sent RLV Command: " + sCmd, TRUE);
    }

}

HandleCommand(key kID, string sCommand)
{
    string sStr=llToLower(sCommand);
    list lArgs = llParseString2List(sStr,["="],[]);
    string sCom = llList2String(lArgs,0);
    if (llGetSubString(sCom,-1,-1)==":") sCom=llGetSubString(sCom,0,-2);
    string sVal = llList2String(lArgs,1);
    if (sVal=="n"||sVal=="add") AddRestriction(kID,sCom);
    else if (sVal=="y"||sVal=="rem") RemRestriction(kID,sCom);
    else if (sCom=="clear") Release(kID,sVal);
    else
    {
        SendCommand(sStr);
        if (g_kSitter==NULL_KEY&&llGetSubString(sStr,0,3)=="sit:")
        {
            g_kSitter=kID;
            //Debug("Sitter:"+(string)(g_kSitter));
            g_kSitTarget=(key)llGetSubString(sCom,4,-1);
            //Debug("Sittarget:"+(string)(g_kSitTarget));
        }
    }
}

AddRestriction(key kID, string sBehav)
{
    integer iSource=llListFindList(g_lSources,[kID]);
    integer iRestr;
    // lock the collar for the first coming relay restriction  (change the test if we decide that collar restrictions should un/lock)
    if (kID != NULL_KEY && (g_lSources == [] || g_lSources == [NULL_KEY])) ApplyAdd("detach");
    if (iSource==-1)
    {
        g_lSources+=[kID];
        g_lRestrictions+=[sBehav];
        iRestr=-1;
        if (kID!=NULL_KEY) llMessageLinked(LINK_SET, CMD_ADDSRC,"",kID);
    }
    else
    {
        list lSrcRestr = llParseString2List(llList2String(g_lRestrictions,iSource),["§"],[]);
        iRestr=llListFindList(lSrcRestr, [sBehav]);
        if (iRestr==-1)
        {
            g_lRestrictions=llListReplaceList(g_lRestrictions,[llDumpList2String(lSrcRestr+[sBehav],"§")],iSource, iSource);
        }
    }
    if (iRestr==-1)
    {
        ApplyAdd(sBehav);
        if (sBehav=="unsit")
        {
            g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
            g_kSitter=kID;
        }
    }
}

ApplyAdd (string sBehav)
{
    integer iRestr=llListFindList(g_lBaked, [sBehav]);
    if (iRestr==-1)
    {
        //if (g_lBaked==[]) SendCommand("detach=n");  removed this as locking is owner privilege
        g_lBaked+=[sBehav];
        SendCommand(sBehav+"=n");
        //Debug(sBehav);
    }
}

RemRestriction(key kID, string sBehav)
{
    integer iSource=llListFindList(g_lSources,[kID]);
    integer iRestr;
    if (iSource!=-1)
    {
        list lSrcRestr = llParseString2List(llList2String(g_lRestrictions,iSource),["§"],[]);
        iRestr=llListFindList(lSrcRestr,[sBehav]);
        if (iRestr!=-1)
        {
            if (llGetListLength(lSrcRestr)==1)
            {
                g_lRestrictions=llDeleteSubList(g_lRestrictions,iSource, iSource);
                g_lSources=llDeleteSubList(g_lSources,iSource, iSource);
                if (kID!=NULL_KEY) llMessageLinked(LINK_SET, CMD_REMSRC,"",kID);
            }
            else
            {
                lSrcRestr=llDeleteSubList(lSrcRestr,iRestr,iRestr);
                g_lRestrictions=llListReplaceList(g_lRestrictions,[llDumpList2String(lSrcRestr,"§")] ,iSource,iSource);
            }
            if (sBehav=="unsit"&&g_kSitter==kID)
            {
                g_kSitter=NULL_KEY;
                g_kSitTarget=NULL_KEY;

            }
            ApplyRem(sBehav);
        }
    }
    // unlock the collar for the last going relay restriction (change the test if we decide that collar restrictions should un/lock)
    if (kID != NULL_KEY && (g_lSources == [] || g_lSources == [NULL_KEY])) ApplyRem("detach");
}

ApplyRem(string sBehav)
{
    integer iRestr=llListFindList(g_lBaked, [sBehav]);
    if (iRestr!=-1)
    {
        integer i;
        integer iFound=FALSE;
        for (i=0;i<=llGetListLength(g_lRestrictions);i++)
        {
            list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,i),["§"],[]);
            if (llListFindList(lSrcRestr, [sBehav])!=-1) iFound=TRUE;
        }
        if (!iFound)
        {
            g_lBaked=llDeleteSubList(g_lBaked,iRestr,iRestr);
            //if (sBehav!="no_hax")  removed:Â issue 1040
            SendCommand(sBehav+"=y");
        }
    }
    //    if (g_lBaked==[]) SendCommand("detach=y");
}

Release(key kID, string sPattern)
{
    integer iSource=llListFindList(g_lSources,[kID]);
    if (iSource!=-1) {
        list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,iSource),["§"],[]);
        integer i;
        if (sPattern!="") {
            for (i=0;i<=llGetListLength(lSrcRestr);i++) {
                string  sBehav=llList2String(lSrcRestr,i);
                if (llSubStringIndex(sBehav,sPattern)!=-1) {
                    RemRestriction(kID,sBehav);
                }
            }
        } else {
            g_lRestrictions=llDeleteSubList(g_lRestrictions,iSource, iSource);
            g_lSources=llDeleteSubList(g_lSources,iSource, iSource);
            llMessageLinked(LINK_SET, CMD_REMSRC,"",kID);
            for (i=0;i<=llGetListLength(lSrcRestr);i++) {
                string  sBehav=llList2String(lSrcRestr,i);
                ApplyRem(sBehav);
                if (sBehav=="unsit"&&g_kSitter==kID) {
                    g_kSitter=NULL_KEY;
                    g_kSitTarget=NULL_KEY;

                }
            }
            //should fix issue 927 (there was nothing to remove detach if the furniture did not explicitly set the restriction)
            if (g_lSources == [] || g_lSources == [NULL_KEY]) {
                ApplyRem("detach"); 
            }
        }
    }
}


SafeWord(integer iCollarToo) {
    SendCommand("clear");
    g_lBaked=[];
    g_lSources=[];
    g_lRestrictions=[];
    integer i;
    if (!iCollarToo) {
        llMessageLinked(LINK_SET,RLV_REFRESH,"","");
    }
}
// End of book keeping functions

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    if(sStr=="runaway") // some scripts reset on runaway, we want to resend RLV state.
    {
        llSleep(2); //give some time for scripts to get ready.
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on="+(string)g_iRLVOn, "");
    }
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check
    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llList2String(lParams, 0);
    string sValue = llToLower(llList2String(lParams, 1));

    Debug("cmd: " + sStr);

    if (sStr == llToLower(g_sSubMenu) || (sCmd == "menu" && llToUpper(sValue) == g_sSubMenu))
    {
        //someone clicked "RLV" on the main menu.  Give them our menu now
        DoMenu(kID, iNum);
    }
    else if (sStr == "rlvon")
    {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on=1", "");
        g_iRLVOn = TRUE;
        g_iVerbose = TRUE;
        if (TRUE) state default;
    }
    else if (StartsWith(sStr, "rlvnotify"))
    {
        string sOnOff = llList2String(llParseString2List(sStr, [" "], []), 1);
        if (sOnOff == "on")
        {
            g_iRLVNotify = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "notify=1", "");
        }
        else if (sOnOff == "off")
        {
            g_iRLVNotify = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "notify=0", "");
        }
    }
    else if (!g_iRLVOn || !g_iViewerCheck) return TRUE;
    // commands after this should only work when RLV is enabled and verified
    if (sStr == "clear")
    {
        if (iNum == COMMAND_WEARER)
        {
            Notify(g_kWearer,"Sorry, but the sub cannot clear RLV settings.",TRUE);
        }
        else
        {
            llMessageLinked(LINK_SET, RLV_CLEAR, "", "");
            SafeWord(TRUE);
        }
    }
    else if (sStr == "rlvon")
    {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on=1", "");
        g_iRLVOn = TRUE;
        g_iVerbose = TRUE;
        if (TRUE) state default;
    }
    else if (sStr == "rlvoff")
    {
        if (iNum == COMMAND_OWNER)
        {
            g_iRLVOn = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on=0", "");
            SafeWord(TRUE);
            llMessageLinked(LINK_SET, RLV_OFF, "", "");
        }
        else Notify(kID, "Sorry, only owner may disable Restrained Love functions", FALSE);
    }
    else if (sStr=="showrestrictions")
    {
        string sOut="You are being restricted by the following object";
        if (llGetListLength(g_lSources)==2) sOut+=":";
        else sOut+="s:";
        integer i;
        for (i=0;i<llGetListLength(g_lSources);i++)
            if (llList2String(g_lSources,i)!=NULL_KEY) sOut+="\n"+llKey2Name((key)llList2String(g_lSources,i))+" ("+llList2String(g_lSources,i)+"): "+llList2String(g_lRestrictions,i);
        else sOut+="\nThis " + CTYPE + ": "+llList2String(g_lRestrictions,i);
        Notify(kID,sOut,FALSE);
    }
    return TRUE;
}


default{
    state_entry()
    {
        llSetTimerEvent(0);
        g_iCheckCount = 0; 
        // Above just in case we somehow get dumped to checked mid versioncheck and then come back. Not sure this is necessary, but should stop eternal loops in  CheckVersion() if things get odd. 
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        //request setting from DB
        llSleep(1.0);
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sScript + "on", "");
        // Ensure that menu script knows we're here.
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {

        if (iNum == LM_SETTING_SAVE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "auth_owner" && llStringLength(sValue) > 0)
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
            integer i = llSubStringIndex(sToken, "_");
            if(sToken == "auth_owner" && llStringLength(sValue) > 0)
            {
                g_lOwners = llParseString2List(sValue, [","], []);
                Debug("owners: " + sValue);
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "on")
                {
                    if (sValue == "unset") CheckVersion(FALSE);
                    else if (!(integer)sValue)
                    {
                        //RLV is turned off in DB.  just switch to checked state without checking viewer
                        //llOwnerSay("rlvdb false");
                        g_iViewerCheck = FALSE;
                        g_iRLVOn = FALSE; //force values, just in case.
                        llMessageLinked(LINK_SET, RLV_OFF, "", "");
                        state checked;
                    }
                    else
                    {
                        //DB says we were running RLV last time it looked.  do @versionnum to check.
                        //llOwnerSay("rlvdb true");
                        g_iRLVOn = TRUE;
                        //check viewer version
                        CheckVersion(FALSE);
                    }
                }
                else if (sToken == "notify") g_iRLVNotify = (integer)sValue;
            }
        }
        else if ((iNum == LM_SETTING_EMPTY && sStr == g_sScript + "on"))
        {
            CheckVersion(FALSE);
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER && sStr == "menu "+g_sSubMenu)
        {   //someone clicked "RLV" on the main menu.  Tell them we're not ready yet.
            Notify(kID, "Still querying for viewer version.  Please try again in a minute.", FALSE);
           // llResetScript();//Nan: why do we reset here?! SA: maybe so we retry querying RLV? MD: I'm removing this, cos it means that if someone attempts to get the RLV menu while querying, restrictions list will be cleared, and hence owner will not be notified. Also protection from people menu mashing out of confusion. 1 minute (2 before I changed it!) is enough for querying, surely?
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sScript + "on", ""); //MD: Why? In case we've got a timing screwup on an update/reset. This should resolve the llResetScript() question above.
        }
    }

    listen(integer iChan, string sName, key kID, string sMsg)
    {
        if (iChan == g_iVersionChan)
        {
            //llOwnerSay("heard " + sMsg);
            llListenRemove(g_iListener);
            llSetTimerEvent(0.0);
            g_iCheckCount = 0;
            //send the version to rlv plugins
            g_iRlvVersion = (integer) llGetSubString(sMsg, 0, 2);
            g_sRlvVersionString=PrettyVersion(sMsg);
            llMessageLinked(LINK_SET, RLV_VERSION, (string) g_iRlvVersion, "");
            //this is already TRUE if rlvon=1 in the DB, but not if rlvon was unset.  set it to true here regardless, since we're setting rlvon=1 in the DB
            g_iRLVOn = TRUE;

            //someone thought it would be a good idea to use a whisper instead of a ownersay here
            //for both privacy and spamminess reasons, I've reverted back to an ownersay. --Nan
            if (g_iRLVNotify)
            {
                llOwnerSay("Restrained Love functions enabled. " + sMsg + " detected.");//turned off for issue 896
            }
            g_iViewerCheck = TRUE;

            llMessageLinked(LINK_SET, RLV_ON, "", "");

            state checked;
        }
    }

    timer() {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        if (g_iCheckCount) {   
            // the viewer hasn't responded after 30 seconds, but maybe it
            // was still logging in when we did @versionnum give it one more
            // chance
            CheckVersion(TRUE);
        }
        else {   
            //we've given the viewer a full 60 seconds
            g_iViewerCheck = FALSE;
            g_iRLVOn = FALSE;
            llMessageLinked(LINK_SET, RLV_OFF, "", "");

            Notify(g_kWearer,"Could not detect Restrained Love Viewer.  Restrained Love functions disabled.",TRUE);
            if (llGetListLength(g_lRestrictions) > 0 && llGetListLength(g_lOwners) > 0) {
                string sMsg = llKey2Name(g_kWearer)+" appears to have logged in without using the Restrained Love Viewer.  Their Restrained Love functions have been disabled.";
                integer i_OwnerCount=llGetListLength(g_lOwners);
                if (i_OwnerCount == 2) {
                    // only 1 owner
                    Notify(g_kWearer,"Your owner has been notified.",FALSE);
                    Notify(llList2Key(g_lOwners,0), sMsg, FALSE);
                } else {
                        Notify(g_kWearer,"Your owners have been notified.",FALSE);
                    integer i;
                    for(i=0; i < i_OwnerCount; i+=2) {
                        Notify(llList2Key(g_lOwners,i), sMsg, FALSE);
                    }
                }
            }

            state checked;
        }
    }

    changed(integer change) {
        if (change & CHANGED_OWNER) {
            llResetScript();
        }
    }
}

state checked {
    on_rez(integer iParam) {
        //reset only if the detach delay was long enough (it could be an
        //automatic reattach)
        if (llGetUnixTime()-g_iLastDetach > 15) {
            state default;
        } else {
            integer i;
            for (i = 0; i < llGetListLength(g_lBaked); i++)
            {
                SendCommand(llList2String(g_lBaked,i)+"=n");
            }
            llSleep(2);
            // wake up other plugins anyway (tell them that RLV is still
            // active, as it is likely they did reset themselves

            llMessageLinked(LINK_SET, RLV_REFRESH, "", "");         
        }
    }


    attach(key kID)
    {
        if (kID == NULL_KEY) g_iLastDetach = llGetUnixTime(); //remember when the collar was detached last
    }

    state_entry()
    {
        
        g_lMenu = [];//clear this list now in case there are old entries in it
        //we only need to request submenus if rlv is turned on and running
        if (g_iRLVOn && g_iViewerCheck)
        {   //ask RLV plugins to tell us about their rlv submenus
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
            //tell rlv plugins to reinstate restrictions  (and wake up the relay listener... so that it can at least hear !pong's!
            llMessageLinked(LINK_SET, RLV_REFRESH, "", "");
            llSleep(5); //Make sure the relay is ready before pinging
            //ping inworld object so that they reinstate their restrictions
            integer i;
            for (i=0;i<llGetListLength(g_lSources);i++) {
                if ((key)llList2String(g_lSources,i)) {
                    llShout(RELAY_CHANNEL,"ping,"+llList2String(g_lSources,i)+",ping,ping");
                }
            }
            g_lOldRestrictions=g_lRestrictions;
            g_lOldSources=g_lSources;
            g_lRestrictions=[];
            g_lSources=[];
            g_lBaked=[];
            llSetTimerEvent(2);
        }
        // Ensure that menu script knows we're here.
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == COMMAND_NOAUTH) return; // SA: TODO remove later
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == DIALOG_RESPONSE)
        {
            Debug(sStr);
            if (kID == kMenuID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                Debug(sMsg);
                if (sMsg == TURNON)
                {
                    UserCommand(iAuth, "rlvon", kAv);
                }
                else if (sMsg == TURNOFF)
                {
                    UserCommand(iAuth, "rlvoff", kAv);
                    DoMenu(kAv, iAuth);
                }
                else if (sMsg == CLEAR)
                {
                    UserCommand(iAuth, "clear", kAv);
                    DoMenu(kAv, iAuth);
                }
                else if (sMsg == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                }
                else if (llListFindList(g_lMenu, [sMsg]) != -1 && g_iRLVOn)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + sMsg, kAv);
                }
            }
        }

        //these are things we only do if RLV is ready to go
        if (g_iRLVOn && g_iViewerCheck)
        {   //if RLV is off, don't even respond to RLV submenu events
            if (iNum == MENUNAME_RESPONSE)
            {    //sStr will be in form of "parentmenu|menuname"
                list lParams = llParseString2List(sStr, ["|"], []);
                string sThisParent = llList2String(lParams, 0);
                string sChild = llList2String(lParams, 1);
                if (sThisParent == g_sSubMenu)
                {     //add this str to our menu buttons
                    if (llListFindList(g_lMenu, [sChild]) == -1)
                    {
                        g_lMenu += [sChild];
                    }
                }
            }
            else if (iNum == MENUNAME_REMOVE)
            {    //sStr will be in form of "parentmenu|menuname"
                list lParams = llParseString2List(sStr, ["|"], []);
                string sThisParent = llList2String(lParams, 0);
                string sChild = llList2String(lParams, 1);
                if (sThisParent == g_sSubMenu)
                {
                    integer iIndex = llListFindList(g_lMenu, [sChild]);
                    if (iIndex != -1)
                    {
                        g_lMenu = llDeleteSubList(g_lMenu, iIndex, iIndex);
                    }
                }
            }
            else if (iNum == RLV_CMD)
            {
                //re make rlv restrictions after teleport or region change, because SL seems to be losing them
                if (llGetUnixTime()-g_iTimestamp >= 30){   //if we asked for refresh less than 30 seconds ago
                    llOwnerSay("@"+sStr);               //refresh the restriction
                }
                
                list sCommands=llParseString2List(sStr,[","],[]);
                integer i;
                for (i=0;i<llGetListLength(sCommands);i++) HandleCommand(kID,llList2String(sCommands,i));
            }
            else if (iNum == COMMAND_RLV_RELAY)
            {
                if (llGetSubString(sStr,-43,-1)!=","+(string)g_kWearer+",!pong") return;
                if (kID==g_kSitter)
                {
                    SendCommand("sit:"+(string)g_kSitTarget+"=force");
                }
                integer iSourceNum=llListFindList(g_lOldSources, [kID]);
                if (iSourceNum == -1) return; // Unknown source decided to answer to this ping while uninvited. Better ignore it.
                integer j;
                list iRestr=llParseString2List(llList2String(g_lOldRestrictions,iSourceNum),["§"],[]);
                for (j=0;j<llGetListLength(iRestr);j++) AddRestriction(kID,llList2String(iRestr,j));
            }
            else if (iNum == COMMAND_SAFEWORD)
            {// safeWord used, clear rlv settings
                llMessageLinked(LINK_SET, RLV_CLEAR, "", "");
                SafeWord(TRUE);
            }
            else if (iNum == LM_SETTING_SAVE)
            {
                list lParams = llParseString2List(sStr, ["="], []);
                string sToken = llList2String(lParams, 0);
                string sValue = llList2String(lParams, 1);
                if(sToken == "auth_owner" && llStringLength(sValue) > 0)
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
                integer i = llSubStringIndex(sToken, "_");
                if(sToken == "auth_owner" && llStringLength(sValue) > 0)
                {
                    g_lOwners = llParseString2List(sValue, [","], []);
                    Debug("owners: " + sValue);
                }
                else if (llGetSubString(sToken, 0, i) == g_sScript)
                {
                    sToken = llGetSubString(sToken, i + 1, -1);
                    if (sToken == "notify") g_iRLVNotify = (integer)sValue;
                }
            }
            else if (iNum==COMMAND_RELAY_SAFEWORD)
            {
                SafeWord(FALSE);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        g_lOldSources=[];
        g_lOldRestrictions=[];
    }
    
    changed(integer change) {
        if (change & CHANGED_OWNER) {
            llResetScript();
        }
        //re make rlv restrictions after teleport or region change, because SL seems to be losing them
        if (change & CHANGED_TELEPORT || change & CHANGED_REGION) {   //if we teleported, or changed regions
            llMessageLinked(LINK_SET, RLV_REFRESH, "", "");              //request refresh
            g_iTimestamp==llGetUnixTime();                              //remember when we requested it
        }
    }
}
