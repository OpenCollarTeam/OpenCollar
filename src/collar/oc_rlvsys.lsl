////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - rlvmain                               //
//                                 version 3.990                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//201410060330

integer g_iRLVOn = FALSE;//set to TRUE if DB says user has turned RLV features on
integer g_iViewerCheck = FALSE;//set to TRUE if viewer is has responded to @versionnum message
integer g_iRlvActive = FALSE;

//integer g_iRLVNotify = FALSE;//if TRUE, ownersay on each RLV restriction
integer g_iListener;
float g_fVersionTimeOut = 30.0; //MD- changed from 60. 2 minute wait before finding RLV is off is too long.
integer g_iRlvVersion;
integer g_iRlvaVersion;
integer g_iCheckCount;//increment this each time we say @versionnum.  check it each time timer goes off in default state. give up if it's >= 2
integer g_iMaxViewerChecks=10;
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
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used RLV viewer version upon receiving this message..
integer RLVA_VERSION = 6004; //RLV Plugins can recieve the used RLVa viewer version upon receiving this message..

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
string WEARERNAME;
key g_kWearer;
string g_sScript="rlvmain_";
string g_sRlvVersionString="(unknown)";
string g_sRlvaVersionString="(unknown)";

list g_lOwners;
list g_lRestrictions;  //2 strided list of sourceId, § separated list of restrictions strings
list g_lExceptions;
list g_lBaked=[]; //list of restrictions currently in force
key g_kSitter=NULL_KEY;
key g_kSitTarget=NULL_KEY;

integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    //llSleep(0.1);
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else{
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

DoMenu(key kID, integer iAuth){
    list lButtons;
    if (g_iRLVOn) lButtons += [TURNOFF, CLEAR] + llListSort(g_lMenu, 1, TRUE);
    else lButtons += [TURNON];

    string sPrompt = "\nRestrained Love Viewer Options\n";
    if (g_iRlvVersion) sPrompt += "Detected Version of RLV: "+g_sRlvVersionString;
    if (g_iRlvaVersion) sPrompt += " (RLVa: "+g_sRlvaVersionString+")";
    sPrompt +="\n\nwww.opencollar.at/rlv";
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|0|" + llDumpList2String(lButtons, "`") + "|" + UPMENU + "|" + (string)iAuth, kMenuID = llGenerateKey());
} 

rebakeSourceRestrictions(key kSource){
    //Debug("rebakeSourceRestrictions "+(string)kSource);
    integer iSourceIndex=llListFindList(g_lRestrictions,[kSource]);
    if (~iSourceIndex) {       // if its a known source, rebake its restrictions
        list lRestr=llParseString2List(llList2String(g_lRestrictions,iSourceIndex+1),["§"],[]);
        while(llGetListLength(lRestr)){
            ApplyAdd(llList2String(lRestr,-1));
            lRestr=llDeleteSubList(lRestr,-1,-1);
        }
    }
}

DoLock(){
    //lock the collar if there are still restrictions from active traps.  Garbage collection will clear lock if they are stale.
    integer numSources=llGetListLength(llList2ListStrided(g_lRestrictions,0,-2,2));
    while (numSources--){
        if ((key)llList2Key(llList2ListStrided(g_lRestrictions,0,-2,2),numSources)){
            //an active source has a valid key, so remain locked... return
            ApplyAdd("detach");
            return;
        }
    }
    ApplyRem("detach"); //we only get here if none of the active sources is a real source, so remove our lock
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
            for (i=0;i<llGetListLength(g_lRestrictions)/2;i++) {
                key kSource=(key)llList2String(llList2ListStrided(g_lRestrictions,0,-1,2),i);
                if ((key)kSource) llShout(RELAY_CHANNEL,"ping,"+(string)kSource+",ping,ping");
                else rebakeSourceRestrictions(kSource);  //reapply collar's restrictions here
            }
            
            //reinstate exceptions
            //Debug("adding exceptions:\n"+llDumpList2String(g_lExceptions,",\n"));
            for (i=0;i<llGetListLength(g_lExceptions);i+=2) {
                key kSource=(key)llList2String(g_lExceptions,i);
                list lBehaviours=llParseString2List(llList2String(g_lExceptions,i+1),["§"],[]);
                while (llGetListLength(lBehaviours)){
                    //Debug("re-adding exception "+llList2String(lBehaviours,-1)+" for "+(string)kSource);
                    ApplyAdd(llList2String(lBehaviours,-1)+":"+(string)kSource);
                    lBehaviours=llDeleteSubList(lBehaviours,-1,-1);
                }
            }
            llMessageLinked(LINK_SET, RLV_VERSION, (string) g_iRlvVersion, NULL_KEY);
            if (g_iRlvaVersion) { //Respond on RLVa as well
                 llMessageLinked(LINK_SET, RLVA_VERSION, (string) g_iRlvaVersion, NULL_KEY);
            }
            llOwnerSay("RLV ready! (v" + g_sRlvVersionString + ")");
            
            DoLock();
        }
    } else if (g_iRlvActive) {  //Both were true, but not now. g_iViewerCheck must still be TRUE (as it was once true), so g_iRLVOn must have just been set FALSE
        //Debug("RLV went inactive");
        g_iRlvActive=FALSE;
        //SafeWord(TRUE);
        while (llGetListLength(g_lBaked)){
            llOwnerSay("@"+llList2String(g_lBaked,-1)+"=y"); //remove restriction
            g_lBaked=llDeleteSubList(g_lBaked,-1,-1);
        }
        llMessageLinked(LINK_SET, RLV_OFF, "", NULL_KEY);
    } else if (g_iRLVOn){  //g_iViewerCheck must be FALSE (see above 2 cases), so g_iRLVOn must have just been set to TRUE, so do viewer check
        if (g_iListener) llListenRemove(g_iListener);
        g_iListener = llListen(293847, "", g_kWearer, "");
        llSetTimerEvent(g_fVersionTimeOut);
        g_iCheckCount=0;
        llOwnerSay("@versionnew=293847");
    } else {  //else both are FALSE, its the only combination left, No need to do viewercheck if g_iRLVOn is FALSE
        llSetTimerEvent(0.0);
    }
}

AddRestriction(key kID, string sBehav) {

    if (kID=="rlvex"){  //if its an exception, add it to the exceptions list
        list lParams = llParseString2List(sBehav, [":"], []);
        key kAv = (key)llList2String(lParams, 1);
        string sBehav = llList2String(lParams, 0);
        
        //Debug("apply exception ("+(string)kAv+")"+sBehav);
        if ((key)kAv){
            integer iSource=llListFindList(g_lExceptions,[kAv]);
            if (! ~iSource ) {  //if this is an exception for a new agent
                //Debug("Exception for new agent "+(string)kAv);
                g_lExceptions+=[kAv,""];    //add UUID and blank list to exceptions list
                iSource=-2;
            }
            //Debug("trying to apply exception ("+(string)kID+")"+sBehav);
            string sSrcRestr = llList2String(g_lExceptions,iSource+1);
            if (!(sSrcRestr==sBehav || ~llSubStringIndex(sSrcRestr,"§"+sBehav) || ~llSubStringIndex(sSrcRestr,sBehav+"§")) ) {
                //Debug("AddRestriction 2.2");
                sSrcRestr+="§"+sBehav;
                if (llSubStringIndex(sSrcRestr,"§")==0) sSrcRestr=llGetSubString(sSrcRestr,1,-1);

                g_lExceptions=llListReplaceList(g_lExceptions,[sSrcRestr],iSource+1, iSource+1);
                ApplyAdd(sBehav+":"+(string)kAv);
            //} else {
                //Debug("exception already active ("+(string)kID+")"+sBehav);
                //Debug(sSrcRestr);
            }
        } else {
            llOwnerSay("OC doesn't currently support global exceptions");
        }
    } else {      //add this restriction to the list for this source
        //add new sources to sources list
        integer iSource=llListFindList(g_lRestrictions,[kID]);
        if (! ~iSource ) {  //if this is a restriction from a new source
            g_lRestrictions += [kID,""];
            iSource=-2;
            if ((key)kID) llMessageLinked(LINK_SET, CMD_ADDSRC,"",kID);  //tell relay script we have a new restriction source
        }
    
        string sSrcRestr = llList2String(g_lRestrictions,iSource+1);
        //Debug("AddRestriction 2.1");
        if (!(sSrcRestr==sBehav || ~llSubStringIndex(sSrcRestr,"§"+sBehav) || ~llSubStringIndex(sSrcRestr,sBehav+"§")) ) {
            //Debug("AddRestriction 2.2");
            sSrcRestr+="§"+sBehav;
            if (llSubStringIndex(sSrcRestr,"§")==0) sSrcRestr=llGetSubString(sSrcRestr,1,-1);

            g_lRestrictions=llListReplaceList(g_lRestrictions,[sSrcRestr],iSource+1, iSource+1);
            //Debug("apply restriction ("+(string)kID+")"+sBehav);
            ApplyAdd(sBehav);
            //Debug("AddRestriction 2.3");
            if (sBehav=="unsit") {
                g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
                g_kSitter=kID;
            }
        }
        DoLock(); //if there are sources with valid keys, collar should be locked.
    }
}

ApplyAdd (string sBehav) {
    if (! ~llListFindList(g_lBaked, [sBehav])) {  //if this restriction is not already baked
        g_lBaked+=[sBehav];
        llOwnerSay("@"+sBehav+"=n");
        //Debug("'"+sBehav+"' added to the baked list");
    //} else {
        //Debug(sBehav+" is already baked");
    }
}

RemRestriction(key kID, string sBehav) {
    if ((string)kID=="rlvex"){
        //Debug("RemRestriction [rlvex] "+sBehav);
        list lParams = llParseString2List(sBehav, [":"], []);
        key kAv = (key)llList2String(lParams, 1);
        string sBehav = llList2String(lParams, 0);
        
        integer iSource=llGetListLength(g_lExceptions);
        while (iSource){
            iSource -= 2;
            key thisAgent=llList2Key(g_lExceptions,iSource);
            if (thisAgent==kAv || kAv==""){ //if we're clearing this one, or all
                //Debug("clearing "+(string)sBehav+" for "+(string)thisAgent);
                list lSrcRestr = llParseString2List(llList2String(g_lExceptions,iSource+1),["§"],[]); //get a list of this source's restrictions
                integer iRestr=llListFindList(lSrcRestr,[sBehav]);  //get index of this restriction from that list
                if (~iRestr) {   //if the restriction is in the list
                    if (llGetListLength(lSrcRestr)==1) {  //if it is the only restriction in the list
                        //Debug("removing last restriction");
                        g_lExceptions=llDeleteSubList(g_lExceptions,iSource, iSource+1);  //remove the restrictions list
                    } else {                              //else, the source has other restrictions
                        lSrcRestr=llDeleteSubList(lSrcRestr,iRestr,iRestr);                 //delete the restriction from the list
                        g_lExceptions=llListReplaceList(g_lExceptions,[llDumpList2String(lSrcRestr,"§")] ,iSource+1,iSource+1);//store the list in the sources restrictions list
                        //Debug("removed restriction, there are "+(string)llGetListLength(lSrcRestr)+" remaining "+llDumpList2String(lSrcRestr,"|"));
                    }
                    lSrcRestr=[];
                    ApplyRem(sBehav+":"+(string)thisAgent);
                //} else {
                    //Debug("restriction is not in the list");
                }
            }
        }
    } else {
        //Debug("RemRestriction ("+(string)kID+")"+sBehav);
        integer iSource=llListFindList(g_lRestrictions,[kID]); //find index of the source
        if (~iSource) { //if this source set any restrictions
            list lSrcRestr = llParseString2List(llList2String(g_lRestrictions,iSource+1),["§"],[]); //get a list of this source's restrictions
            integer iRestr=llListFindList(lSrcRestr,[sBehav]);  //get index of this restriction from that list
            if (~iRestr || sBehav=="ALL") {   //if the restriction is in the list
                if (llGetListLength(lSrcRestr)==1) {  //if it is the only restriction in the list
                    g_lRestrictions=llDeleteSubList(g_lRestrictions,iSource, iSource+1);  //remove the restrictions list
                    if ((key)kID) llMessageLinked(LINK_SET, CMD_REMSRC,"",kID);    //tell the relay the source has no restrictions
                } else {                              //else, the source has other restrictions
                    lSrcRestr=llDeleteSubList(lSrcRestr,iRestr,iRestr);                 //delete the restriction from the list
                    g_lRestrictions=llListReplaceList(g_lRestrictions,[llDumpList2String(lSrcRestr,"§")] ,iSource+1,iSource+1);//store the list in the sources restrictions list
                }
                if (sBehav=="unsit"&&g_kSitter==kID) {
                    g_kSitter=NULL_KEY;
                    g_kSitTarget=NULL_KEY;
                }
                lSrcRestr=[];
                ApplyRem(sBehav);
            }
        }
        DoLock();
    }
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
        llOwnerSay("@"+sBehav+"=y"); //remove restriction
    //} else {
        //Debug("Restriction '"+sBehav+"'not in baked list"); 
    }
    //Debug("(post rem) Baked restrictions:\n"+llDumpList2String(g_lBaked,"\n"));
}


SafeWord() {
    //leave lock and exceptions intact, clear everything else
    integer numRestrictions=llGetListLength(g_lRestrictions);
    while (numRestrictions){
        numRestrictions -= 2;
        string kSource=llList2String(g_lRestrictions,numRestrictions);
        if (kSource != "main" && kSource != "rlvex" && llSubStringIndex(kSource,"utility_") != 0){
            llMessageLinked(LINK_SET,RLV_CMD,"clear",kSource);
        }
    }
    llMessageLinked(LINK_SET,RLV_CLEAR,"","");
}
// End of book keeping functions

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum == COMMAND_EVERYONE) return;  // No command for people with no privilege in this plugin.
    
    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llList2String(lParams, 0);
    string sValue = llToLower(llList2String(lParams, 1));
    lParams=[];

    if (sStr=="runaway" && kID==g_kWearer) { // some scripts reset on runaway, we want to resend RLV state.
        llSleep(2); //give some time for scripts to get ready.
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on="+(string)g_iRLVOn, "");
    } else if (llToLower(sStr) == "rlv" || llToLower(sStr) == "menu rlv" ){
        //someone clicked "RLV" on the main menu.  Give them our menu now
        DoMenu(kID, iNum);
//    } else if (sStr == "rlvnotify on") {
//        g_iRLVNotify = TRUE;
//        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "notify=1", "");
//    } else if (sStr == "rlvnotify off") {
//        g_iRLVNotify = FALSE;
//        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "notify=0", "");
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
        if (iNum == COMMAND_WEARER) llOwnerSay("Sorry, but the sub cannot clear RLV settings.");
        else SafeWord();
    } else if (sStr=="showrestrictions") {
        string sOut="You are being restricted by the following objects";
        integer numRestrictions=llGetListLength(g_lRestrictions);
        while (numRestrictions){
            key kSource=(key)llList2String(g_lRestrictions,numRestrictions);
            if ((key)kSource) 
                sOut+="\n"+llKey2Name((key)kSource)+" ("+(string)kSource+"): "+llList2String(g_lRestrictions,numRestrictions+1);
            else 
                sOut+="\nThis " + CTYPE + "("+(string)kSource+"): "+llList2String(g_lRestrictions,numRestrictions+1);
            numRestrictions -= 2;
        }
        Notify(kID,sOut,FALSE);
    }
}


default {
    listen(integer iChan, string sName, key kID, string sMsg) {
    //RestrainedLove viewer v2.8.0 (RLVa 1.4.10) <-- @versionnew response structure v1.23 (implemented April 2010).
    //lines commented out are from @versionnum response string (implemented late 2009)
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        g_iCheckCount = 0;
        g_iViewerCheck = TRUE;
        
        //send the version to rlv plugins
        list lParam = llParseString2List(sMsg,[" "],[""]); //(0:RestrainedLove)(1:viewer)(2:v2.8.0)(3:(RLVa)(4:1.4.10))
        
        //g_iRlvVersion = (integer) llGetSubString(sMsg, 0, 2); //expects (208)0000 (old versionnum response)
        list lVersionSplit = llParseString2List(llGetSubString(llList2String(lParam,2), 1, -1),["."],[]);  //expects (208)0000 | derive from:(2:v2.8.0)
        g_iRlvVersion = llList2Integer(lVersionSplit,0) * 100 + llList2Integer(lVersionSplit,1);  //we should now have (integer)208
        //integer i=(integer)sMsg;
        //string s3=llGetSubString((string)(i/100),-2,-1);
        //string s2=llGetSubString((string)(i/10000),-2,-1);
        //string s1=llGetSubString((string)(i/1000000),-2,-1);
        //g_sRlvVersionString = s1+"."+s2+"."+s3;
        string sRlvResponseString = llList2String(lParam,2);  //(2:v2.8.0) RLV segmented response from viewer
        g_sRlvVersionString = llGetSubString(sRlvResponseString,llSubStringIndex(sRlvResponseString,"v")+1,llSubStringIndex(sRlvResponseString,")") );
        string sRlvaResponseString = llList2String(lParam,4);  //(4:1.4.10)) RLVa segmented response from viewer
        g_sRlvaVersionString = llGetSubString(sRlvaResponseString,0,llSubStringIndex(sRlvaResponseString,")") -1);
        
        lVersionSplit = llParseString2List(g_sRlvaVersionString,["."],[]); //split up RLVa version string (1.4.10)
        g_iRlvaVersion = llList2Integer(lVersionSplit,0) * 100 + llList2Integer(lVersionSplit,1); //we should now have (integer)104
        
        //We should now have: ["2.8.0" in g_sRlvVersionString] and ["1.4.10" in g_sRlvaVersionString]
        //Debug("g_iRlvVersion: "+(string)g_iRlvVersion+" g_sRlvVersionString: "+g_sRlvVersionString+ " g_sRlvaVersionString: "+g_sRlvaVersionString+ " g_iRlvaVersion: "+(string)g_iRlvaVersion);
        //Debug("|"+sMsg+"|");
        setRlvState();
    } //Firestorm - viewer response: RestrainedLove viewer v2.8.0 (RLVa 1.4.10)
      //Firestorm - rlvmain parsed result: g_iRlvVersion: 208 (same as before) g_sRlvVersionString: 2.8.0 (same as before) g_sRlvaVersionString: 1.4.10 (new) g_iRlvaVersion: 104 (new)
      //
      //Marine's RLV Viewer - viewer response: RestrainedLove viewer v2.09.01.0 (3.7.9.32089)
      //Marine's RLV Viewer - rlvmain parsed result: g_iRlvVersion: 209 (same as before) g_sRlvVersionString: 2.09.01.0 (same as before) g_sRlvaVersionString: NULL (new) g_iRlvaVersion: 0 (new)

    state_entry() {
        //Debug("Starting");
        llOwnerSay("@clear");
        g_kWearer = llGetOwner();
        WEARERNAME = llGetDisplayName(g_kWearer);
        if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME == llKey2Name(g_kWearer);
    }

    on_rez(integer param){
/*        
        if (g_iProfiled){
            llScriptProfiler(1);
            Debug("profiling restarted");
        }
*/        
        g_iRlvActive=FALSE;
        g_iViewerCheck=FALSE;
        g_iRLVOn=FALSE;
        g_lBaked=[];    //just been rezzed, so should have no baked restrictions
    }
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lMenu = [] ; // flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
        } 
        else if (iNum == COMMAND_NOAUTH) return; // SA: TODO remove later
        else if (iNum <= COMMAND_EVERYONE && iNum >= COMMAND_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == DIALOG_RESPONSE) {
            //Debug(sStr);
            if (kID == kMenuID) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                lMenuParams=[];
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
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            lParams=[];
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken=="Global_lock") g_iCollarLocked=(integer)sValue;
            else if (sToken=="Global_CType") CTYPE=sValue;
            else if (sToken=="Global_WearerName") WEARERNAME=sValue;
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            lParams=[];
            if (sToken == "auth_owner" && llStringLength(sValue) > 0) g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken=="Global_lock") g_iCollarLocked=(integer)sValue;
            else if (sToken=="Global_CType") CTYPE=sValue;
            else if (sToken=="Global_WearerName") WEARERNAME=sValue;
//            else if (sToken=="rlvmain_notify") g_iRLVNotify = (integer)sValue;
            else if (sToken=="rlvmain_on") {
                g_iRLVOn=(integer)sValue;
                setRlvState();
            }
        } else if (iNum == COMMAND_SAFEWORD) SafeWord();
        else if (iNum==COMMAND_RELAY_SAFEWORD) SafeWord();
        else if (iNum==RLV_QUERY){
            if (g_iRlvActive) llMessageLinked(LINK_SET, RLV_RESPONSE, "ON", "");
            else llMessageLinked(LINK_SET, RLV_RESPONSE, "OFF", "");
        } else if (iNum == MENUNAME_RESPONSE) {     //sStr will be in form of "parentmenu|menuname"
            list lParams = llParseString2List(sStr, ["|"], []);
            string sThisParent = llList2String(lParams, 0);
            string sChild = llList2String(lParams, 1);
            lParams=[];
            if (sThisParent == g_sSubMenu) {        //add this str to our menu buttons
                if (! ~llListFindList(g_lMenu, [sChild])) {
                    g_lMenu += [sChild];
                }
            }
        } else if (iNum == MENUNAME_REMOVE) {       //sStr will be in form of "parentmenu|menuname"
            list lParams = llParseString2List(sStr, ["|"], []);
            string sThisParent = llList2String(lParams, 0);
            string sChild = llList2String(lParams, 1);
            lParams=[];
            if (sThisParent == g_sSubMenu) {
                integer iIndex = llListFindList(g_lMenu, [sChild]);
                if (iIndex != -1) {
                    g_lMenu = llDeleteSubList(g_lMenu, iIndex, iIndex);
                }
            }
        }

        //these are things we only do if RLV is ready to go
        else if (g_iRlvActive) {                         //if RLV is off, don't even respond to RLV submenu events
            if (iNum == RLV_CMD) {
                //Debug("Received RLV_CMD: "+sStr+" from "+(string)kID);
                list lCommands=llParseString2List(llToLower(sStr),[","],[]);
                
                while (llGetListLength(lCommands)){
                    string sCommand=llToLower(llList2String(lCommands,0));
                    list lArgs = llParseString2List(sCommand,["="],[]); //split the command on "="
                    string sCom = llList2String(lArgs,0);               //store first part of command
                    if (llGetSubString(sCom,-1,-1)==":") sCom=llGetSubString(sCom,0,-2);  //remove trailing :
                    string sVal = llList2String(lArgs,1);               //store value
                    lArgs=[];
                    
                    if (sVal=="n"||sVal=="add") AddRestriction(kID,sCom); //add a restriction
                    else if (sVal=="y"||sVal=="rem") RemRestriction(kID,sCom);  //remove a restriction
                    else if (sCom=="clear") { //release some or all restrictions FOR THIS OBJECT ONLY
                        //Debug("Got clear command:\nkey: "+(string)kID+"\ncommand: "+sCommand);
                        integer iSource=llListFindList(g_lRestrictions,[kID]);
                        if (kID=="rlvex"){
                            RemRestriction(kID,sVal);
                        } else if (~iSource) {   //if this is a known source
                            //Debug("Clearing restrictions:\nrestrictions: "+sVal+"\nfor key: "+(string)kID+"\nindex: "+(string)iSource);
                            list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,iSource+1),["§"],[]); //get a list of this source's restrictions
                            integer numRestrictions=llGetListLength(lSrcRestr);
                            list lRestrictionsToRemove;
                            
                            while (llGetListLength(lSrcRestr)) {  //loop through all of this source's restrictions and store them in a new list
                                string  sBehav=llList2String(lSrcRestr,-1);  //get the name of the restriction from the list
                                if (sVal=="" || llSubStringIndex(sBehav,sVal)!=-1) {  //if the restriction to remove matches the start of the behaviour in the list, or we need to remove all of them
                                    //Debug("Clearing restriction "+sBehav+" for "+(string)kID);
                                    lRestrictionsToRemove+=sBehav;
                                    //RemRestriction(kID,sBehav); //remove the restriction from the list
                                }
                                lSrcRestr=llDeleteSubList(lSrcRestr,-1,-1);
                            }
                            lSrcRestr=[]; //delete the list to free memory
                            //Debug("removing restrictions:"+llDumpList2String(lRestrictionsToRemove,"|")+" for "+(string)kID);
                            while(llGetListLength(lRestrictionsToRemove)){
                                RemRestriction(kID,llList2String(lRestrictionsToRemove,-1)); //remove the restriction from the list
                                lRestrictionsToRemove=llDeleteSubList(lRestrictionsToRemove,-1,-1);
                            }
                        }
                    } else {         //perform other command
                        //Debug("Got other command:\nkey: "+(string)kID+"\ncommand: "+sCommand);
                        if (llSubStringIndex(sCom,"tpto")==0) {  //looks like a tpto command, lets check to see if we should honour it or not, and message back if we can if it fails
                            if ( ~llListFindList(g_lBaked,["tploc"])  || ~llListFindList(g_lBaked,["unsit"]) ) {
                                if ((key)kID) Notify(kID,"Can't teleport due to RLV restrictions",TRUE);
                                return;
                            }
                        } else if (sStr=="unsit=force") {
                            if (~llListFindList(g_lBaked,["unsit"]) ) {
                                if ((key)kID) Notify(kID,"Can't force stand due to RLV restrictions",TRUE);
                                return;
                            }
                        }
                        llOwnerSay("@"+sCommand);
                        if (g_kSitter==NULL_KEY&&llGetSubString(sCommand,0,3)=="sit:") {
                            g_kSitter=kID;
                            //Debug("Sitter:"+(string)(g_kSitter));
                            g_kSitTarget=(key)llGetSubString(sCom,4,-1);
                            //Debug("Sittarget:"+(string)(g_kSitTarget));
                        }
                    }
                
                    lCommands=llDeleteSubList(lCommands,0,0);
                    //Debug("Command list now "+llDumpList2String(lCommands,"|"));
                }
            } else if (iNum == COMMAND_RLV_RELAY) {
                if (llGetSubString(sStr,-43,-1)== ","+(string)g_kWearer+",!pong") { //if it is a pong aimed at wearer
                    //Debug("Received pong:"+sStr+" from "+(string)kID);
                    if (kID==g_kSitter) llOwnerSay("@"+"sit:"+(string)g_kSitTarget+"=force");  //if we stored a sitter, sit on it
                    rebakeSourceRestrictions(kID);
                }
            }
        }
    }

    timer() {
        if (g_iCheckCount++ <= g_iMaxViewerChecks) {   //no response in timeout period, try again
            llOwnerSay("@versionnew=293847");
            if (g_iCheckCount==3) llOwnerSay("If your viewer doesn't support RLV, you can stop the \"@versioncheck\" message by switching RLV off in your "+CTYPE+"'s RLV menu.");
        } else {    //we've waited long enough, and are out of retries
            llSetTimerEvent(0.0);
            llListenRemove(g_iListener);  
            g_iCheckCount=0;
            //llSetTimerEvent(0.0);
            
            g_iViewerCheck = FALSE;
            setRlvState();

            llOwnerSay("Could not detect Restrained Love Viewer.  Restrained Love functions disabled.");
            if (llGetListLength(g_lRestrictions) > 0 && llGetListLength(g_lOwners) > 0) {
                string sMsg = WEARERNAME+" appears to have logged in without using the Restrained Love Viewer.  Their Restrained Love functions have been disabled.";

                integer i_OwnerCount=llGetListLength(g_lOwners);
                integer i;
                for(i=0; i < i_OwnerCount; i+=2) {
                    Notify(llList2Key(g_lOwners,i), sMsg, FALSE);
                }
                
                if (i_OwnerCount == 2) llOwnerSay("Your owner has been notified.");
                else llOwnerSay("Your owners have been notified.");
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
                llOwnerSay("@"+llList2String(g_lBaked,numBaked)+"=n");
                //Debug("resending @"+llList2String(g_lBaked,numBaked));
            }

        }
/*        
        if (change & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/        
        if (change & CHANGED_INVENTORY) { //A script may have been recompiled or added, lets refresh the RLV state for other scripts
            if (g_iRlvActive==TRUE) {
                llSleep(2);
                llMessageLinked(LINK_SET, RLV_ON, "", NULL_KEY);
                if (g_iRlvaVersion) llMessageLinked(LINK_SET, RLVA_VERSION, (string) g_iRlvaVersion, NULL_KEY);
            }
        }
    }
}
