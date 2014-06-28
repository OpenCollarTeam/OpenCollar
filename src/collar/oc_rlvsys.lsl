////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - rlvmain                               //
//                                 version 3.963                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//201405302026

integer g_iRLVOn = FALSE;//set to TRUE if DB says user has turned RLV features on
integer g_iViewerCheck = FALSE;//set to TRUE if viewer is has responded to @versionnum message
integer g_iRlvActive = FALSE;

integer g_iRLVNotify = FALSE;//if TRUE, ownersay on each RLV restriction
integer g_iListener;
float g_fVersionTimeOut = 30.0; //MD- changed from 60. 2 minute wait before finding RLV is off is too long.
integer g_iVersionChan = 293847;
integer g_iRlvVersion;
integer g_iCheckCount;//increment this each time we say @versionnum.  check it each time timer goes off in default state. give up if it's >= 2
integer g_iMaxViewerChecks=4;
integer g_iCollarLocked=FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "RLV";
list g_lMenu;
key kMenuID;
integer RELAY_CHANNEL = -1812221819;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
//integer COMMAND_SECOWNER = 501;
//integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;
integer COMMAND_RELAY_SAFEWORD = 511;

//integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
//integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
integer RLV_QUERY = 6102; //query from a script asking if RLV is currently functioning
integer RLV_RESPONSE = 6103;  //reply to RLV_QUERY, with "ON" or "OFF" as the message

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TURNON = "  ON";
string TURNOFF = " OFF";
string CLEAR = "CLEAR ALL";
string CTYPE = "collar";
key g_kWearer;
string g_sScript="rlvmain_";
string g_sRlvVersionString="(unknown)";

list g_lOwners;
list g_lSources=[];
list g_lRestrictions=[];  //§ separated list of restrictions strings, keyed by g_lSources
list g_lBaked=[]; //list of restrictions currently in force
key g_kSitter=NULL_KEY;
key g_kSitTarget=NULL_KEY;

integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

//Debug(string sStr){llOwnerSay(llGetScriptName() + " DEBUG: " + sStr);}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

CheckVersion(){
    llOwnerSay( "Checking you out for hotness (and RLV), please wait a moment before use.");

    if (g_iListener){
        llListenRemove(g_iListener);
    }
    g_iListener = llListen(g_iVersionChan, "", g_kWearer, "");
    llSetTimerEvent(g_fVersionTimeOut);
    g_iCheckCount++;
    llOwnerSay("@versionnum=" + (string)g_iVersionChan);
}

DoMenu(key kID, integer iAuth){
    list lButtons;
    if (g_iRLVOn) lButtons += [TURNOFF, CLEAR] + llListSort(g_lMenu, 1, TRUE);
    else lButtons += [TURNON];

    string sPrompt = "\nRestrained Love Viewer Options\n";
    if (g_iRlvVersion) sPrompt += "Detected Version of RLV: "+g_sRlvVersionString+"\n\nwww.opencollar.at/rlv";
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|0|" + llDumpList2String(lButtons, "`") + "|" + UPMENU + "|" + (string)iAuth, kMenuID = llGenerateKey());
} 

rebakeSourceRestrictions(integer iSourceNum){
    if (~iSourceNum) {       // if its a known source, rebake its restrictions
        list iRestr=llParseString2List(llList2String(g_lRestrictions,iSourceNum),["§"],[]);
        integer numRestrictions=llGetListLength(iRestr);
        while (numRestrictions--) {
            string sBehav=llList2String(iRestr,numRestrictions);
            //Debug("Re-adding '"+sBehav+"' restriction");
            ApplyAdd(sBehav);
            //Debug("(re-add)Baked restrictions:\n"+llDumpList2String(g_lBaked,"\n"));
        }
    }
}

setRlvState(){
    if (g_iRLVOn && g_iViewerCheck){  //everyone says RLV on
        if (!g_iRlvActive) {  //its newly active
            //Debug("RLV went active");
            //Debug("Sources:"+llDumpList2String(g_lSources,";"));
            g_iRlvActive=TRUE;
            llMessageLinked(LINK_SET, RLV_ON, "", NULL_KEY);
            
            g_lMenu = [] ; // flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
            //tell rlv plugins to reinstate restrictions  (and wake up the relay listener... so that it can at least hear !pong's!
            llMessageLinked(LINK_SET, RLV_REFRESH, "", NULL_KEY);
            llSleep(5); //Make sure the relay is ready before pinging
            //ping inworld object so that they reinstate their restrictions
            integer i;
            for (i=0;i<llGetListLength(g_lSources);i++) {
                //Debug("Pinging "+(string)llList2String(g_lSources,i));
                if ((key)llList2String(g_lSources,i)) {
                    //Debug("Pinging key "+llList2String(g_lSources,i));
                    llShout(RELAY_CHANNEL,"ping,"+llList2String(g_lSources,i)+",ping,ping");
                } else {
                    //reapply collar's restrictions here
                    rebakeSourceRestrictions(i);
                }
            }
            llMessageLinked(LINK_SET, RLV_VERSION, (string) g_iRlvVersion, NULL_KEY);
            Notify(g_kWearer,"Restrained Love functions enabled. " + g_sRlvVersionString + " detected.",FALSE);
            
            //lock the collar if there are still restrictions from active traps.  Garbage collection will clear lock if they are stale.
            if (g_lSources != [] && g_lSources != [NULL_KEY]) ApplyAdd("detach");
        }
    } else {  //someone says RLV off
        if (g_iRlvActive) {  //its newly deactivated
            //Debug("RLV went inactive");
            g_iRlvActive=FALSE;
            //SafeWord(TRUE);
            integer numRestrictions = llGetListLength(g_lBaked);
            while (numRestrictions--){
                SendCommand(llList2String(g_lBaked,numRestrictions)+"=y"); //remove restriction
                g_lBaked=llDeleteSubList(g_lBaked,-1,-1);
            }
            llMessageLinked(LINK_SET, RLV_OFF, "", NULL_KEY);
        }
    }
}

// Book keeping functions
SendCommand(string sCmd){
    llOwnerSay("@"+sCmd);
    if (g_iRLVNotify) Notify(g_kWearer, "Sent RLV Command: " + sCmd, TRUE);
}

HandleCommand(key kID, string sCommand) {
    sCommand=llToLower(sCommand);
    list lArgs = llParseString2List(sCommand,["="],[]); //split the command on "="
    string sCom = llList2String(lArgs,0);               //store first part of command
    if (llGetSubString(sCom,-1,-1)==":") sCom=llGetSubString(sCom,0,-2);  //remove trailing :
    string sVal = llList2String(lArgs,1);               //store value
    
    if (sVal=="n"||sVal=="add") AddRestriction(kID,sCom); //add a restriction
    else if (sVal=="y"||sVal=="rem") RemRestriction(kID,sCom);  //remove a restriction
    else if (sCom=="clear") { //release some or all restrictions FOR THIS OBJECT ONLY
        //Debug("Got clear command:\nkey: "+(string)kID+"\ncommand: "+sCommand);
        integer iSource=llListFindList(g_lSources,[kID]);
        if (~iSource) {   //if this is a known source
            //Debug("Clearing restrictions:\nrestrictions: "+sVal+"\nfor key: "+(string)kID+"\nindex: "+(string)iSource);
            list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,iSource),["§"],[]); //get a list of this source's restrictions
            integer numRestrictions=llGetListLength(lSrcRestr);
            while (numRestrictions--) { //loop through all of this source's restrictions
                string  sBehav=llList2String(lSrcRestr,numRestrictions);  //get the name of the restriction from the list
                if (sVal=="" || llSubStringIndex(sBehav,sVal)!=-1) {  //if the restriction to remove matches the start of the behaviour in the list, or we need to remove all of them
                    //Debug("Clearing restriction "+sBehav+" for "+(string)kID);
                    RemRestriction(kID,sBehav); //remove the restriction from the list
                }
            }
        }
    } else {         //perform other command
        //Debug("Got other command:\nkey: "+(string)kID+"\ncommand: "+sCommand);
        SendCommand(sCommand);
        if (g_kSitter==NULL_KEY&&llGetSubString(sCommand,0,3)=="sit:") {
            g_kSitter=kID;
            //Debug("Sitter:"+(string)(g_kSitter));
            g_kSitTarget=(key)llGetSubString(sCom,4,-1);
            //Debug("Sittarget:"+(string)(g_kSitTarget));
        }
    }
}

AddRestriction(key kID, string sBehav) {
    integer iSource=llListFindList(g_lSources,[kID]);
    integer iRestr; //flag, -1 if this source has not already set this restriction

    //if (kID != NULL_KEY && (g_lSources == [] || g_lSources == [NULL_KEY])) ApplyAdd("detach"); //if source is collar, AND (sources list is either empty, or just the collar) then lock the collar
    
    //add new sources to sources list
    if (iSource==-1) {  //if this is a restriction from a new source
        g_lSources+=[kID];    //add it to the sources list
        g_lRestrictions+=[""]; //add empty restrictions list for new source
        if ((key)kID) llMessageLinked(LINK_SET, CMD_ADDSRC,"",kID);  //tell relay script we have a new restriction source
    }
    
    //add this restriction to the list for this source
    list lSrcRestr = llParseString2List(llList2String(g_lRestrictions,iSource),["§"],[]);
    iRestr=llListFindList(lSrcRestr, [sBehav]);
    if (iRestr==-1) {
        g_lRestrictions=llListReplaceList(g_lRestrictions,[llDumpList2String(lSrcRestr+[sBehav],"§")],iSource, iSource);
    }
    
    //if its a new restriction for this source, try to apply it
    if (iRestr==-1) {
        ApplyAdd(sBehav);
        if (sBehav=="unsit") {
            g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
            g_kSitter=kID;
        }
    }
    //Debug("Sources:"+llDumpList2String(g_lSources,";"));
    
    
    //if there are sources with valid keys, collar should be locked.
    integer numSources=llGetListLength(g_lSources);
    while (numSources--){
        if ((key)llList2Key(g_lSources,numSources)){
            //an active source has a valid key, so remain locked... return
            ApplyAdd("detach");
            return;
        }
    }
    ApplyRem("detach"); //we only get here if none of the active sources is a real source, so remove our lock
}

ApplyAdd (string sBehav) {
    if (! ~llListFindList(g_lBaked, [sBehav])) {  //if this restriction is not already baked
        g_lBaked+=[sBehav];
        SendCommand(sBehav+"=n");
        //Debug("'"+sBehav+"' added to the baked list");
    } else {
        //Debug(sBehav+" is already baked");
    }
}

RemRestriction(key kID, string sBehav) {
    integer iSource=llListFindList(g_lSources,[kID]); //find index of the source
    if (~iSource) { //if this source set any restrictions
        list lSrcRestr = llParseString2List(llList2String(g_lRestrictions,iSource),["§"],[]); //get a list of this source's restrictions
        integer iRestr=llListFindList(lSrcRestr,[sBehav]);  //get index of this restriction from that list
        if (~iRestr) {   //if the restriction is in the list
            if (llGetListLength(lSrcRestr)==1) {  //if it is the only restriction in the list
                g_lRestrictions=llDeleteSubList(g_lRestrictions,iSource, iSource);  //remove the restrictions list
                g_lSources=llDeleteSubList(g_lSources,iSource, iSource);            //remove the source
                if ((key)kID) llMessageLinked(LINK_SET, CMD_REMSRC,"",kID);    //tell the relay the source has no restrictions
            } else {                              //else, the source has other restrictions
                lSrcRestr=llDeleteSubList(lSrcRestr,iRestr,iRestr);                 //delete the restriction from the list
                g_lRestrictions=llListReplaceList(g_lRestrictions,[llDumpList2String(lSrcRestr,"§")] ,iSource,iSource);//store the list in the sources restrictions list
            }
            if (sBehav=="unsit"&&g_kSitter==kID) {
                g_kSitter=NULL_KEY;
                g_kSitTarget=NULL_KEY;
            }
            ApplyRem(sBehav);
        }
    }
    // unlock the collar for the last going relay restriction (change the test if we decide that collar restrictions should un/lock)
    //if (kID != NULL_KEY && (g_lSources == [] || g_lSources == [NULL_KEY])) ApplyRem("detach");
    
    //if there are sources with valid keys, collar should be locked.
    integer numSources=llGetListLength(g_lSources);
    while (numSources--){
        if ((key)llList2Key(g_lSources,numSources)){
            //an active source has a valid key, so remain locked... return
            ApplyAdd("detach");
            return;
        }
    }
    ApplyRem("detach"); //we only get here if none of the active sources is a real source, so remove our lock
}

ApplyRem(string sBehav) {
    //Debug("(rem) Baked restrictions:\n"+llDumpList2String(g_lBaked,"\n"));
    integer iRestr=llListFindList(g_lBaked, [sBehav]);  //look for this restriction in the baked list
    if (~iRestr) {  //if this restriction has been baked already
        integer i;
        for (i=0;i<=llGetListLength(g_lRestrictions);i++) {   //for each source
            list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,i),["§"],[]); //get its restrictions list
            if (llListFindList(lSrcRestr, [sBehav])!=-1) return; //check it for this restriction
        }
        
        g_lBaked=llDeleteSubList(g_lBaked,iRestr,iRestr); //delete it from the baked list
        SendCommand(sBehav+"=y"); //remove restriction
    } else {
        //Debug("Restriction '"+sBehav+"'not in baked list"); 
    }
    //Debug("(post rem) Baked restrictions:\n"+llDumpList2String(g_lBaked,"\n"));
}


SafeWord(integer iCollarToo) {
    //Debug("Safeword!!!");
    SendCommand("clear");
    g_lBaked=[];
    g_lSources=[];
    g_lRestrictions=[];
    integer i;
    if (!iCollarToo) {
        llMessageLinked(LINK_SET,RLV_REFRESH,"",NULL_KEY);
    }
}
// End of book keeping functions

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum == COMMAND_EVERYONE) {
        return TRUE;  // No command for people with no privilege in this plugin.
    } else if (sStr=="runaway") { // some scripts reset on runaway, we want to resend RLV state.
        llSleep(2); //give some time for scripts to get ready.
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on="+(string)g_iRLVOn, "");
    } else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) {
        return FALSE; // sanity check
    }
    
    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llList2String(lParams, 0);
    string sValue = llToLower(llList2String(lParams, 1));

    if (sStr == llToLower(g_sSubMenu) || (sCmd == "menu" && llToUpper(sValue) == g_sSubMenu)) {
        //someone clicked "RLV" on the main menu.  Give them our menu now
        DoMenu(kID, iNum);
    } else if (sStr == "rlvnotify on") {
        g_iRLVNotify = TRUE;
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "notify=1", "");
    } else if (sStr == "rlvnotify off") {
        g_iRLVNotify = FALSE;
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "notify=0", "");
    } else if (sStr == "rlvon") {
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on=1", "");
        g_iRLVOn = TRUE;
        setRlvState();
    } else if (sStr == "rlvoff") {
        if (iNum == COMMAND_OWNER) {
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on=0", "");
            g_iRLVOn = FALSE;
            setRlvState();
        } else Notify(kID, "Sorry, only owner may disable Restrained Love functions", FALSE);
    } else if (sStr == "clear") {
        if (iNum == COMMAND_WEARER) {
            Notify(g_kWearer,"Sorry, but the sub cannot clear RLV settings.",TRUE);
        } else {
            llMessageLinked(LINK_SET, RLV_CLEAR, "", NULL_KEY);
            SafeWord(TRUE);
        }
    } else if (sStr=="showrestrictions") {
        string sOut="You are being restricted by the following object";
        if (llGetListLength(g_lSources)==2) sOut+=":";
        else sOut+="s:";
        integer i;
        for (i=0;i<llGetListLength(g_lSources);i++)
            if ((key)llList2String(g_lSources,i)) 
                sOut+="\n"+llKey2Name((key)llList2String(g_lSources,i))+" ("+llList2String(g_lSources,i)+"): "+llList2String(g_lRestrictions,i);
            else 
                sOut+="\nThis " + CTYPE + ": "+llList2String(g_lRestrictions,i);
        Notify(kID,sOut,FALSE);
    }
    return TRUE;
}


default {
    listen(integer iChan, string sName, key kID, string sMsg) {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        g_iCheckCount = 0;
        g_iViewerCheck = TRUE;
        
        //send the version to rlv plugins
        g_iRlvVersion = (integer) llGetSubString(sMsg, 0, 2);
        integer i=(integer)sMsg;
        string s3=llGetSubString((string)(i/100),-2,-1);
        string s2=llGetSubString((string)(i/10000),-2,-1);
        string s1=llGetSubString((string)(i/1000000),-2,-1);
        g_sRlvVersionString = s1+"."+s2+"."+s3;
        
        setRlvState();
    }

    state_entry() {
        //Debug("init");
        g_kWearer = llGetOwner();
        CheckVersion();
    }

    on_rez(integer param){
        g_iViewerCheck=FALSE;
        g_iRLVOn=FALSE;
        if (g_iCheckCount==0){  //if checkCount > 0, there is already a check in progress
            CheckVersion();
        }
        //Debug("Sources: "+llDumpList2String("Soures on_rez:\n"+g_lSources,"\n"));
        //Debug("Baked restrictions on_rez:\n"+llDumpList2String(g_lBaked,"\n"));
        g_lBaked=[];    //just been rezzed, so should have no baked restrictions
    }
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lMenu = [] ; // flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
        } else if (iNum == COMMAND_NOAUTH) return; // SA: TODO remove later
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == DIALOG_RESPONSE) {
            //Debug(sStr);
            if (kID == kMenuID) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //Debug(sMsg);
                if (sMsg == TURNON) {
                    UserCommand(iAuth, "rlvon", kAv);
                } else if (sMsg == TURNOFF) {
                    UserCommand(iAuth, "rlvoff", kAv);
                    DoMenu(kAv, iAuth);
                } else if (sMsg == CLEAR) {
                    UserCommand(iAuth, "clear", kAv);
                    DoMenu(kAv, iAuth);
                } else if (sMsg == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                } else if (~llListFindList(g_lMenu, [sMsg])) {  //if this is a valid request for a foreign menu
                    llMessageLinked(LINK_SET, iAuth, "menu " + sMsg, kAv);
                }
            }
        } else if (iNum==RLV_QUERY) {
            if (g_iRlvActive) {
                llMessageLinked(LINK_SET, RLV_RESPONSE, "ON", "");
            } else {
                llMessageLinked(LINK_SET, RLV_RESPONSE, "OFF", "");
            }
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) {
                g_lOwners = llParseString2List(sValue, [","], []);
                //Debug("owners: " + sValue);
            } else if (sToken=="Global_lock") {
                g_iCollarLocked=(integer)sValue;
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) {
                g_lOwners = llParseString2List(sValue, [","], []);
                //Debug("owners: " + sValue);
            } else if (sToken=="Global_lock") {
                g_iCollarLocked=(integer)sValue;
            } else if (llGetSubString(sToken, 0, i) == g_sScript) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "notify") g_iRLVNotify = (integer)sValue;
                else if (sToken=="on") {
                    g_iRLVOn=(integer)sValue;
                    setRlvState();
                }
            }
        } else if (iNum == COMMAND_SAFEWORD) {      // safeWord used, clear rlv settings
            //Debug("Safeword");
            llMessageLinked(LINK_SET, RLV_CLEAR, "", NULL_KEY);
            SafeWord(TRUE);
        } else if (iNum==COMMAND_RELAY_SAFEWORD) {
            SafeWord(FALSE);
        } else if (iNum==RLV_QUERY){
            if (g_iRlvActive) llMessageLinked(LINK_SET, RLV_RESPONSE, "ON", "");
            else llMessageLinked(LINK_SET, RLV_RESPONSE, "OFF", "");
        } else if (iNum == MENUNAME_RESPONSE) {     //sStr will be in form of "parentmenu|menuname"
            list lParams = llParseString2List(sStr, ["|"], []);
            string sThisParent = llList2String(lParams, 0);
            string sChild = llList2String(lParams, 1);
            if (sThisParent == g_sSubMenu) {        //add this str to our menu buttons
                if (! ~llListFindList(g_lMenu, [sChild])) {
                    g_lMenu += [sChild];
                }
            }
        } else if (iNum == MENUNAME_REMOVE) {       //sStr will be in form of "parentmenu|menuname"
            list lParams = llParseString2List(sStr, ["|"], []);
            string sThisParent = llList2String(lParams, 0);
            string sChild = llList2String(lParams, 1);
            if (sThisParent == g_sSubMenu) {
                integer iIndex = llListFindList(g_lMenu, [sChild]);
                if (iIndex != -1) {
                    g_lMenu = llDeleteSubList(g_lMenu, iIndex, iIndex);
                }
            }
        }

        //these are things we only do if RLV is ready to go
        if (g_iRlvActive) {                         //if RLV is off, don't even respond to RLV submenu events
            if (iNum == RLV_CMD) {
                //Debug("Received RLV_CMD:"+sStr+" from "+(string)kID);
                list sCommands=llParseString2List(sStr,[","],[]);
                integer i;
                integer numCommands=llGetListLength(sCommands);
                for (i=0;i<numCommands;i++) 
                    HandleCommand(kID,llList2String(sCommands,i));
            } else if (iNum == COMMAND_RLV_RELAY) {
                if (llGetSubString(sStr,-43,-1)== ","+(string)g_kWearer+",!pong") { //if it is a pong aimed at wearer
                    //Debug("Received pong:"+sStr+" from "+(string)kID);
                    if (kID==g_kSitter) SendCommand("sit:"+(string)g_kSitTarget+"=force");  //if we stored a sitter, sit on it
                    integer iSourceNum=llListFindList(g_lSources, [kID]);   //find the source in the sources list
                    rebakeSourceRestrictions(iSourceNum);
                }
            }
        }
    }

    timer() {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        if (g_iCheckCount <= g_iMaxViewerChecks) {   //no response in timeout period, try again
            CheckVersion();
        } else {    //we've waited long enough, and are out of retries
            g_iCheckCount=0;
            llSetTimerEvent(0.0);
            
            g_iViewerCheck = FALSE;
            setRlvState();

            Notify(g_kWearer,"Could not detect Restrained Love Viewer.  Restrained Love functions disabled.",TRUE);
            if (llGetListLength(g_lRestrictions) > 0 && llGetListLength(g_lOwners) > 0) {
                string sMsg = llKey2Name(g_kWearer)+" appears to have logged in without using the Restrained Love Viewer.  Their Restrained Love functions have been disabled.";

                integer i_OwnerCount=llGetListLength(g_lOwners);
                integer i;
                for(i=0; i < i_OwnerCount; i+=2) {
                    Notify(llList2Key(g_lOwners,i), sMsg, FALSE);
                }
                
                if (i_OwnerCount == 2) Notify(g_kWearer,"Your owner has been notified.",FALSE);
                else Notify(g_kWearer,"Your owners have been notified.",FALSE);
            }
        }
    }
    changed(integer change) {
        if (change & CHANGED_OWNER) {
            llResetScript();
        }
        //re make rlv restrictions after teleport or region change, because SL seems to be losing them
        if (change & CHANGED_TELEPORT || change & CHANGED_REGION) {   //if we teleported, or changed regions
            //re make rlv restrictions after teleport or region change, because SL seems to be losing them
            integer numBaked=llGetListLength(g_lBaked);
            while (numBaked--){
                llOwnerSay("@"+llList2String(g_lBaked,numBaked));
                //Debug("resending @"+llList2String(g_lBaked,numBaked));
            }

        }
    }
}
