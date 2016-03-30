//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                         RLV System - 160330.1                            //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Satomi Ahn, Nandana Singh, Wendy Starfall,    //
//  Medea Destiny, littlemousy, Romka Swallowtail, Garvin Twine,            //
//  Sumi Perl et al.                                                        //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//         github.com/OpenCollar/opencollar/tree/master/src/collar          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

integer g_iRLVOn = TRUE;
integer g_iRLVOff = FALSE;
integer g_iViewerCheck = FALSE;
integer g_iRlvActive = FALSE;
integer g_iWaitRelay;

integer g_iListener;
float g_fVersionTimeOut = 30.0;
integer g_iRlvVersion;
integer g_iRlvaVersion;
integer g_iCheckCount;
integer g_iMaxViewerChecks = 3;
integer g_iCollarLocked = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "RLV";
list g_lMenu;
//key kMenuID;
list    g_lMenuIDs;
integer g_iMenuStride = 3;
integer RELAY_CHANNEL = -1812221819;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer REBOOT = -1000;
integer LOADPIN = -1904;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used RLV viewer version upon receiving this message..
integer RLVA_VERSION = 6004; //RLV Plugins can recieve the used RLVa viewer version upon receiving this message..

integer RLV_OFF = 6100;
integer RLV_ON = 6101;
integer RLV_QUERY = 6102;
integer RLV_RESPONSE = 6103;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string TURNON = "  ON";
string TURNOFF = " OFF";
string CLEAR = "CLEAR ALL";

key g_kWearer;

string g_sSettingToken = "rlvsys_";
string g_sGlobalToken = "global_";
string g_sRlvVersionString="(unknown)";
string g_sRlvaVersionString="(unknown)";

list g_lOwners;
list g_lRestrictions;  //2 strided list of sourceId, § separated list of restrictions strings
//list g_lExceptions;
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
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

DoMenu(key kID, integer iAuth){
    key kMenuID = llGenerateKey();
    string sPrompt = "\n[http://www.opencollar.at/rlv.html Remote Scripted Viewer Controls]\n";
    if (g_iRlvActive) {
        if (g_iRlvVersion) sPrompt += "\nRestrainedLove API: RLV v"+g_sRlvVersionString;
        if (g_iRlvaVersion) sPrompt += " / RLVa v"+g_sRlvaVersionString;
    } else if (g_iRLVOff) sPrompt += "\nRLV is turned off.";
    else {
        if (g_iRLVOn) sPrompt += "\nThe rlv script is still trying to handshake with the RL-viewer. Just wait another minute and try again.\n\n[ON] restarts the RLV handshake cycle with the viewer.";
        else sPrompt += "\nRLV appears to be disabled in the viewer's preferences.\n\n[ON] attempts another RLV handshake with the viewer.";
        sPrompt += "\n\n[OFF] will prevent the %DEVICETYPE% from attempting another \"@versionnew=293847\" handshake at the next login.\n\nNOTE: Turning RLV off here means that it has to be turned on manually once it is activated in the viewer.";
    }
    list lButtons;
    if (g_iRlvActive) {
        lButtons = llListSort(g_lMenu, 1, TRUE);
        integer iRelay = llListFindList(lButtons,["Relay"]);
        integer iTerminal = llListFindList(lButtons,["Terminal"]);
        if (~iRelay && ~iTerminal) { //check if there is a Relay registered and replace the Terminal button with it
            lButtons = llListReplaceList(lButtons,["Relay"],iTerminal,iTerminal);
            lButtons = llDeleteSubList(lButtons,iRelay,iRelay);
        }
        lButtons = [TURNOFF, CLEAR] + lButtons;
    } else if (g_iRLVOff) lButtons = [TURNON];
    else lButtons = [TURNON, TURNOFF];
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|0|" + llDumpList2String(lButtons, "`") + "|" + UPMENU + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, g_sSubMenu], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, g_sSubMenu];
    //Debug("Made menu.");
}

rebakeSourceRestrictions(key kSource){
    //Debug("rebakeSourceRestrictions "+(string)kSource);
    integer iSourceIndex=llListFindList(g_lRestrictions,[kSource]);
    if (~iSourceIndex) {
        list lRestr=llParseString2List(llList2String(g_lRestrictions,iSourceIndex+1),["§"],[]);
        while(llGetListLength(lRestr)){
            ApplyAdd(llList2String(lRestr,-1));
            lRestr=llDeleteSubList(lRestr,-1,-1);
        }
    }
}

DoLock(){
    integer numSources=llGetListLength(llList2ListStrided(g_lRestrictions,0,-2,2));
    while (numSources--){
        if ((key)llList2Key(llList2ListStrided(g_lRestrictions,0,-2,2),numSources)){
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
           // llMessageLinked(LINK_SET, RLV_ON, "", NULL_KEY);
            g_lMenu = [] ; // flush submenu buttons
            llMessageLinked(LINK_ALL_OTHERS, MENUNAME_REQUEST, g_sSubMenu, "");
            //tell rlv plugins to reinstate restrictions  (and wake up the relay listener... so that it can at least hear !pong's!
            llMessageLinked(LINK_ALL_OTHERS, RLV_REFRESH, "", NULL_KEY);
            g_iWaitRelay = 1;
            llSetTimerEvent(1.5);
        }
    } else if (g_iRlvActive) {  //Both were true, but not now. g_iViewerCheck must still be TRUE (as it was once true), so g_iRLVOn must have just been set FALSE
        //Debug("RLV went inactive");
        g_iRlvActive=FALSE;
        while (llGetListLength(g_lBaked)){
            llOwnerSay("@"+llList2String(g_lBaked,-1)+"=y"); //remove restriction
            g_lBaked=llDeleteSubList(g_lBaked,-1,-1);
        }
        llMessageLinked(LINK_ALL_OTHERS, RLV_OFF, "", NULL_KEY);
    } else if (g_iRLVOn){  //g_iViewerCheck must be FALSE (see above 2 cases), so g_iRLVOn must have just been set to TRUE, so do viewer check
        if (g_iListener) llListenRemove(g_iListener);
        g_iListener = llListen(293847, "", g_kWearer, "");
        llSetTimerEvent(g_fVersionTimeOut);
        g_iCheckCount=0;
        llOwnerSay("@versionnew=293847");
    } else   //else both are FALSE, its the only combination left, No need to do viewercheck if g_iRLVOn is FALSE
        llSetTimerEvent(0.0);
}

AddRestriction(key kID, string sBehav) {
    //add new sources to sources list
    integer iSource=llListFindList(g_lRestrictions,[kID]);
    if (! ~iSource ) {  //if this is a restriction from a new source
        g_lRestrictions += [kID,""];
        iSource=-2;
        if ((key)kID) llMessageLinked(LINK_ALL_OTHERS, CMD_ADDSRC,"",kID);  //tell relay script we have a new restriction source
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
        if (sBehav=="unsit") {
            g_kSitTarget = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
            g_kSitter=kID;
        }
    }
    DoLock(); //if there are sources with valid keys, collar should be locked.
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
    //Debug("RemRestriction ("+(string)kID+")"+sBehav);
    integer iSource=llListFindList(g_lRestrictions,[kID]); //find index of the source
    if (~iSource) { //if this source set any restrictions
        list lSrcRestr = llParseString2List(llList2String(g_lRestrictions,iSource+1),["§"],[]); //get a list of this source's restrictions
        integer iRestr=llListFindList(lSrcRestr,[sBehav]);  //get index of this restriction from that list
        if (~iRestr || sBehav=="ALL") {   //if the restriction is in the list
            if (llGetListLength(lSrcRestr)==1) {  //if it is the only restriction in the list
                g_lRestrictions=llDeleteSubList(g_lRestrictions,iSource, iSource+1);  //remove the restrictions list
                if ((key)kID) llMessageLinked(LINK_ALL_OTHERS, CMD_REMSRC,"",kID);    //tell the relay the source has no restrictions
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

ApplyRem(string sBehav) {
    //Debug("(rem) Baked restrictions:\n"+llDumpList2String(g_lBaked,"\n"));
    integer iRestr=llListFindList(g_lBaked, [sBehav]);  //look for this restriction in the baked list
    if (~iRestr) {  //if this restriction has been baked already
        integer i;
        for (i=0;i<=llGetListLength(g_lRestrictions);i++) {   //for each source
            list lSrcRestr=llParseString2List(llList2String(g_lRestrictions,i),["§"],[]); //get its restrictions list
            if (llListFindList(lSrcRestr, [sBehav])!=-1) return; //check it for this restriction
        }
        //also check the exceptions list, in case its an exception
        list lParts=llParseString2List(sBehav,[":"],[]);
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
        if (kSource != "main" && kSource != "rlvex" && llSubStringIndex(kSource,"utility_") != 0)
            llMessageLinked(LINK_THIS,RLV_CMD,"clear",kSource);
    }
    llMessageLinked(LINK_ALL_OTHERS,RLV_CLEAR,"","");
}
// End of book keeping functions

UserCommand(integer iNum, string sStr, key kID) {
    sStr = llToLower(sStr);
    if (sStr=="runaway" && kID==g_kWearer) { // some scripts reset on runaway, we want to resend RLV state.
        llSleep(2); //give some time for scripts to get ready.
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on="+(string)g_iRLVOn, "");
    } else if (sStr == "rlv" || sStr == "menu rlv" ){
        //someone clicked "RLV" on the main menu.  Give them our menu now
        DoMenu(kID, iNum);
    } else if (sStr == "rlv on") {
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Starting RLV...",g_kWearer);
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=1", "");
        g_iRLVOn = TRUE;
        g_iRLVOff = FALSE;
        setRlvState();
    } else if (sStr == "rlv off") {
        if (iNum == CMD_OWNER) {
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on=0", "");
            llSetTimerEvent(0.0); //in case handshakes still going on stop the timer
            g_iRLVOn = FALSE;
            g_iRLVOff = TRUE;
            setRlvState();
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"RLV disabled.",g_kWearer);
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    } else if (sStr == "clear") {
        if (iNum == CMD_OWNER) SafeWord();
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",g_kWearer);
    } else if (llGetSubString(sStr,0,13) == "rlv handshakes") {
        if (iNum != CMD_WEARER && iNum != CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",g_kWearer);
        else {
            if ((integer)llGetSubString(sStr,-2,-1)) {
                g_iMaxViewerChecks = (integer)llGetSubString(sStr,-2,-1);
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Next time RLV is turned on or the %DEVICETYPE% attached with RLV turned on, there will be "+(string)g_iMaxViewerChecks+" extra handshake attempts before disabling RLV.", kID);
                llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken + "handshakes="+(string)g_iMaxViewerChecks, "");
            } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nRLV handshakes means the set number of attempts to check for active RLV support in the viewer. Being on slow connections and/or having an unusually large inventory might mean having to check more often than the default of 3 times.\n\nCommand syntax: %PREFIX% rlv handshakes [number]\n", kID);
        }
    }  else if (sStr=="show restrictions") {
        string sOut="You are being restricted by the following objects";
        integer numRestrictions=llGetListLength(g_lRestrictions);
        if (!numRestrictions) sOut="You are not restricted.";
        while (numRestrictions){
            key kSource=(key)llList2String(g_lRestrictions,numRestrictions-2);
            if ((key)kSource)
                sOut+="\n"+llKey2Name((key)kSource)+" ("+(string)kSource+"): "+llList2String(g_lRestrictions,numRestrictions-1);
            else
                sOut+="\nThis %DEVICETYPE%("+(string)kSource+"): "+llList2String(g_lRestrictions,numRestrictions-1);
            numRestrictions -= 2;
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sOut,kID);
    }
}

default {
    on_rez(integer param) {
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
        llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_RLV","");
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        //llSetMemoryLimit(65536);  //2015-05-16 (script needs memory for processing)
        setRlvState();
        //llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on="+(string)g_iRLVOn, "");
        //llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_SAVE, g_sSettingToken + "on="+(string)g_iRLVOn, "");
        llOwnerSay("@clear");
        g_kWearer = llGetOwner();
        //Debug("Starting");
    }

    listen(integer iChan, string sName, key kID, string sMsg) {
    //RestrainedLove viewer v2.8.0 (RLVa 1.4.10) <-- @versionnew response structure v1.23 (implemented April 2010).
    //lines commented out are from @versionnum response string (implemented late 2009)
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        g_iCheckCount = 0;
        g_iViewerCheck = TRUE;

        //send the version to rlv plugins
        list lParam = llParseString2List(sMsg,[" "],[""]); //(0:RestrainedLove)(1:viewer)(2:v2.8.0)(3:(RLVa)(4:1.4.10))

        list lVersionSplit = llParseString2List(llGetSubString(llList2String(lParam,2), 1, -1),["."],[]);  //expects (208)0000 | derive from:(2:v2.8.0)
        g_iRlvVersion = llList2Integer(lVersionSplit,0) * 100 + llList2Integer(lVersionSplit,1);  //we should now have (integer)208
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
        //Debug("Starting");
    } //Firestorm - viewer response: RestrainedLove viewer v2.8.0 (RLVa 1.4.10)
      //Firestorm - rlvmain parsed result: g_iRlvVersion: 208 (same as before) g_sRlvVersionString: 2.8.0 (same as before) g_sRlvaVersionString: 1.4.10 (new) g_iRlvaVersion: 104 (new)
      //
      //Marine's RLV Viewer - viewer response: RestrainedLove viewer v2.09.01.0 (3.7.9.32089)
      //Marine's RLV Viewer - rlvmain parsed result: g_iRlvVersion: 209 (same as before) g_sRlvVersionString: 2.09.01.0 (same as before) g_sRlvaVersionString: NULL (new) g_iRlvaVersion: 0 (new)

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lMenu = [] ; // flush submenu buttons
            llMessageLinked(LINK_ALL_OTHERS, MENUNAME_REQUEST, g_sSubMenu, "");
        }
        else if (iNum <= CMD_WEARER && iNum >= CMD_OWNER) UserCommand(iNum, sStr, kID);
        else if (iNum == DIALOG_RESPONSE) {
            //Debug(sStr);
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
                llSensorRepeat("N0thin9","abc",ACTIVE,0.1,0.1,0.22);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                lMenuParams=[];
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu == g_sSubMenu) {
                    if (sMsg == TURNON) {
                        UserCommand(iAuth, "rlv on", kAv);
                    } else if (sMsg == TURNOFF) {
                        UserCommand(iAuth, "rlv off", kAv);
                        DoMenu(kAv, iAuth);
                    } else if (sMsg == CLEAR) {
                        UserCommand(iAuth, "clear", kAv);
                        DoMenu(kAv, iAuth);
                    } else if (sMsg == UPMENU) {
                        llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu "+g_sParentMenu, kAv);
                    } else if (~llListFindList(g_lMenu, [sMsg])) {  //if this is a valid request for a foreign menu
                        llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu " + sMsg, kAv);
                    }
                }
            }
        }  else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LM_SETTING_REQUEST && sStr == "ALL") { //inventory changed in root
            if (g_iRlvActive == TRUE) {
                llSleep(2);
                llMessageLinked(LINK_ALL_OTHERS, RLV_ON, "", NULL_KEY);
                if (g_iRlvaVersion) llMessageLinked(LINK_ALL_OTHERS, RLVA_VERSION, (string) g_iRlvaVersion, NULL_KEY);
            }
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            lParams=[];
            if (sToken == "auth_owner") g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken==g_sGlobalToken+"lock") g_iCollarLocked=(integer)sValue;
            else if (sToken==g_sSettingToken+"handshakes") g_iMaxViewerChecks=(integer)sValue;
            else if (sToken==g_sSettingToken+"on") {
                g_iRLVOn=(integer)sValue;
                g_iRLVOff = !g_iRLVOn;
                setRlvState();
            }
        } else if (iNum == CMD_SAFEWORD || iNum == CMD_RELAY_SAFEWORD) SafeWord();
        else if (iNum==RLV_QUERY) {
            if (g_iRlvActive) llMessageLinked(LINK_ALL_OTHERS, RLV_RESPONSE, "ON", "");
            else llMessageLinked(LINK_ALL_OTHERS, RLV_RESPONSE, "OFF", "");
        } else if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sThisParent = llList2String(lParams, 0);
            string sChild = llList2String(lParams, 1);
            lParams=[];
            if (sThisParent == g_sSubMenu) {
                if (! ~llListFindList(g_lMenu, [sChild])) {
                    g_lMenu += [sChild];
                }
            }
        } else if (iNum == MENUNAME_REMOVE) {
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
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript(); 
        else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") {
                LINK_SAVE = iSender;
                if (g_iRLVOn) llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "on="+(string)g_iRLVOn, "");
            } else if (sStr == "LINK_REQUEST") llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_RLV","");
        } else if (g_iRlvActive) {
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
            llSensorRepeat("N0thin9","abc",ACTIVE,0.1,0.1,0.22);
            if (iNum == RLV_CMD) {
                //Debug("Received RLV_CMD: "+sStr+" from "+(string)kID);
                list lCommands=llParseString2List(llToLower(sStr),[","],[]);
                while (llGetListLength(lCommands)) {
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

                            while (llGetListLength(lSrcRestr)) {//loop through all of this source's restrictions and store them in a new list
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
                        if (llSubStringIndex(sCom,"tpto")==0) {
                            if ( ~llListFindList(g_lBaked,["tploc"])  || ~llListFindList(g_lBaked,["unsit"]) ) {
                                if ((key)kID) llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Can't teleport due to RLV restrictions",kID);
                                return;
                            }
                        } else if (sStr=="unsit=force") {
                            if (~llListFindList(g_lBaked,["unsit"]) ) {
                                if ((key)kID) llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Can't force stand due to RLV restrictions",kID);
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
            } else if (iNum == CMD_RLV_RELAY) {
                if (llGetSubString(sStr,-43,-1)== ","+(string)g_kWearer+",!pong") { //if it is a pong aimed at wearer
                    //Debug("Received pong:"+sStr+" from "+(string)kID);
                    if (kID==g_kSitter) llOwnerSay("@"+"sit:"+(string)g_kSitTarget+"=force");  //if we stored a sitter, sit on it
                    rebakeSourceRestrictions(kID);
                }
            }
        }
    }
    
    no_sensor() {
        llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);
        llSensorRemove();
    }
    
    timer() {
        if (g_iWaitRelay) {
            if (g_iWaitRelay < 2) {
                g_iWaitRelay = 2;
                llMessageLinked(LINK_ALL_OTHERS, RLV_ON, "", NULL_KEY);
                llMessageLinked(LINK_ALL_OTHERS, RLV_VERSION, (string)g_iRlvVersion, "");
                if (g_iRlvaVersion)  //Respond on RLVa as well
                    llMessageLinked(LINK_ALL_OTHERS, RLVA_VERSION, (string)g_iRlvaVersion, "");
                DoLock();
                llSetTimerEvent(3.0);
            } else {
                llSetTimerEvent(0.0);
                g_iWaitRelay = FALSE;
                integer i;
                for (i=0;i<llGetListLength(g_lRestrictions)/2;i++) {
                    key kSource=(key)llList2String(llList2ListStrided(g_lRestrictions,0,-1,2),i);
                    if ((key)kSource) llShout(RELAY_CHANNEL,"ping,"+(string)kSource+",ping,ping");
                    else rebakeSourceRestrictions(kSource);  //reapply collar's restrictions here
                }
                if (!llGetStartParameter()) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"RLV ready!",g_kWearer);
            }
        } else {
            if (g_iCheckCount++ < g_iMaxViewerChecks) {
                llOwnerSay("@versionnew=293847");
               // if (g_iCheckCount==2) llMessageLinked(LINK_SET, NOTIFY, "0"+"\n\nIf your viewer doesn't support RLV, you can stop the \"@versionnew\" message by switching RLV off in your %DEVICETYPE%'s RLV menu or by typing: %PREFIX% rlv off\n", g_kWearer);
            } else {    //we've waited long enough, and are out of retries
                llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"\n\nRLV appears to be not currently activated in your viewer. There will be no further attempted handshakes \"@versionnew=293847\" until the next time you log in. To permanently turn RLV off, type \"/%CHANNEL%%PREFIX% rlv off\" but keep in mind that you will have to manually enable it if you wish to use it in the future.\n\nwww.opencollar.at/rlv\n", g_kWearer);
                llSetTimerEvent(0.0);
                llListenRemove(g_iListener);
                g_iCheckCount=0;
                g_iViewerCheck = FALSE;
                g_iRlvVersion = FALSE;
                g_iRlvaVersion = FALSE;
                //UserCommand(500, "rlv off", g_kWearer);
                g_iRLVOn = FALSE;
               // setRlvState();
            }
        }
    }
    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        //re make rlv restrictions after teleport or region change, because SL seems to be losing them
        if (iChange & CHANGED_TELEPORT || iChange & CHANGED_REGION) {   //if we teleported, or changed regions
            //re make rlv restrictions after teleport or region change, because SL seems to be losing them
            integer numBaked=llGetListLength(g_lBaked);
            while (numBaked--){
                llOwnerSay("@"+llList2String(g_lBaked,numBaked)+"=n");
                //Debug("resending @"+llList2String(g_lBaked,numBaked));
            }

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
}
