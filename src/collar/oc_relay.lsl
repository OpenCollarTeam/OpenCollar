// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Satomi Ahn, Nandana Singh, Wendy Starfall,  
// Sumi Perl, littlemousy, Romka Swallowtail, Garvin Twine et al.     
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sScriptVersion = "7.4";

integer LINK_CMD_DEBUG=1999;
string g_sParentMenu = "RLV";
string g_sSubMenu = "Relay";

integer RELAY_CHANNEL = -1812221819;
integer SAFETY_CHANNEL = -201818;
integer g_iRlvListener;
integer g_iSafetyListener;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507; // now will be used from rlvrelay to rlvmain, for ping only
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string ALL = "ALL";

key g_kWearer;
string g_sSettingsToken = "relay_";

list g_lMenuIDs;
integer g_iMenuStride = 3;

integer g_iGarbageRate = 60; //garbage collection rate

list g_lSources;

list g_lTempTrustObj;
list g_lTempBlockObj;
list g_lTempTrustUser;
list g_lTempBlockUser;
list g_lTrustObj; // 2-strided list uuid,name
list g_lBlockObj; // 2-strided list uuid,name
list g_lTrustAv; // keys stored as string since strings is what you get when restoring settings
list g_lBlockAv; // same here (this fixes issue 1253)

integer g_iRLV=FALSE;
list g_lQueue=[];
integer QSTRIDES=3;
integer g_iAuthPending = FALSE;
integer g_iRecentSafeword;

//relay specific message map
integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

//collar Owners, TempOwners, Trusts and Blocks caching
list g_lOwner;
list g_lTempOwner;
list g_lTrust;
list g_lBlock;

//settings
integer g_iMinBaseMode = FALSE;
integer g_iMinHelplessMode = FALSE;
integer g_iMinLandMode = FALSE;
integer g_iMinLiteMode = FALSE;
integer g_iBaseMode = 2;
integer g_iHelpless = 0;
integer g_iLandMode = 0;
integer g_iLiteMode = 0;

integer g_iSmartStrip = TRUE; // Convert @remoutfit to @detachallthis.

key g_kDebugRcpt = NULL_KEY; // recipient key for relay chat debugging (useful since you cannot eavesdrop llRegionSayTo)

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
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}
// Sanitizes a key coming from the outside, so that only valid
// keys are returned, and invalid ones are mapped to NULL_KEY
key SanitizeKey(string uuid) {
    if ((key)uuid) return llToLower(uuid);
    return NULL_KEY;
}

RelayNotify(key kID, string sMessage, integer iNofityWearer) {
    string sObjectName = llGetObjectName();
    llSetObjectName("Relay");
    if (kID == g_kWearer) llOwnerSay(sMessage);
    else {
        llRegionSayTo(kID,0,sMessage);
        if (iNofityWearer) llOwnerSay(sMessage);
    }
    llSetObjectName(sObjectName);
}
/*
SaveTrustObj()
{
    if (llGetListLength(g_lTrustObj) > 0)
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingsToken+"trustobj=" + llDumpList2String(g_lTrustObj,","), "");
    else llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingsToken+"trustobj", "");
}

SaveBlockObj()
{
    if (llGetListLength(g_lBlockObj) > 0)
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingsToken+"blockobj=" + llDumpList2String(g_lBlockObj,","), "");
    else llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingsToken+"blockobj", "");
}
*/
SaveTrustAv() {
    if (llGetListLength(g_lTrustAv) > 0)
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingsToken+"trustav=" + llDumpList2String(g_lTrustAv,","), "");
    else llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingsToken+"trustav", "");
}

SaveBlockAv() {
    if (llGetListLength(g_lBlockAv) > 0)
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingsToken+"blockav="+llDumpList2String(g_lBlockAv,",") , "");
    else llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingsToken+"blockav", "");
}

UpdateMode(integer iMode) {
    g_iBaseMode = iMode        & 3;
    g_iHelpless = (iMode >> 2) & 1;
    g_iLandMode = (iMode >> 3) & 1;
    g_iLiteMode = (iMode >> 4) & 1;
    g_iMinBaseMode = (iMode >> 5) & 3;
    g_iMinHelplessMode = (iMode >> 7) & 1;
    g_iMinLandMode = (iMode >> 8) & 1;
    g_iMinLiteMode = (iMode >> 9) & 1;
    g_iSmartStrip = (iMode >> 10) & 1;
}

SaveMode() {
    string sMode = (string)(1024 * g_iSmartStrip + 512 * g_iMinLiteMode + 256 * g_iMinLandMode + 128 * g_iMinHelplessMode + 32 * g_iMinBaseMode
        + 16 * g_iLiteMode + 8 * g_iLandMode + 4 * g_iHelpless + g_iBaseMode);
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingsToken+"mode=" + sMode, "");
}

integer Auth(key object, key user) {
    integer iAuth=1;
    key kOwner = llGetOwnerKey(object);
    //object auth
    integer iSourceIndex=llListFindList(g_lSources,[object]);
    if (~iSourceIndex) {}
    else if (~llListFindList(g_lTempBlockObj+g_lBlockObj,[object])) return -1;
    else if (~llListFindList(g_lBlockAv,[(string)kOwner])) return -1;
    else if (~llListFindList(g_lBlock,[(string)kOwner])) return -1;
    else if (g_iBaseMode==3) {}
    else if (g_iLandMode && llGetOwnerKey(object)==llGetLandOwnerAt(llGetPos())) {
        if(kOwner==g_kWearer)iAuth=0;
        // incase landmode is set and landowner is wearer, revert to ask
    }
    else if (~llListFindList(g_lTempTrustObj+g_lTrustObj,[object])) {}
    else if (~llListFindList(g_lTrustAv,[(string)kOwner])) {}
    else if (~llListFindList(g_lOwner+g_lTrust+g_lTempOwner,[(string)kOwner])) {
        if(kOwner!=object && (kOwner == g_kWearer || llGetAgentSize(kOwner)==ZERO_VECTOR)) iAuth=0;
        //We only rely on owner list permissions if the object owner is not the wearer, and the object owner is present in the sim.
    }
//    else if (g_iBaseMode==1) return -1; we should not block playful in trusted mode
    else iAuth=0;
    //user auth
    if (user) {
//        if (~iSource_iIndex&&user==(key)llList2String(users,iSource_iIndex)) {}
//        else if (user==g_kLastUser) {}
//        else
        if (~llListFindList(g_lBlockAv+g_lTempBlockUser,[user])) return -1;
        else if (~llListFindList(g_lBlock,[(string)user])) return -1;
        else if (g_iBaseMode == 3) {}
        else if (~llListFindList(g_lTrustAv+g_lTempTrustUser,[user])) {}
        else if (~llListFindList(g_lOwner+g_lTrust+g_lTempOwner,[(string)user])) {}
//        else if (g_iBaseMode==1) return -1;
        else return 0;
    }
    return iAuth;
}

string NameURI(string sID) {
    return "secondlife:///app/agent/"+sID+"/inspect";
}

Dequeue() {
    string sCommand;
    string sCurIdent;
    key kCurID;
    while (sCommand=="") {
        if (g_lQueue==[]) {
            llSetTimerEvent(g_iGarbageRate);
            return;
        }
        sCurIdent=llList2String(g_lQueue,0);
        kCurID=(key)llList2String(g_lQueue,1);
        sCommand=HandleCommand(sCurIdent,kCurID,llList2String(g_lQueue,2),FALSE);
        g_lQueue = llDeleteSubList(g_lQueue, 0, QSTRIDES-1);
    }
    g_lQueue=[sCurIdent,kCurID,sCommand]+g_lQueue;
    list lButtons=["Yes","Trust Owner","Trust Object","No","Block Owner","Block Object"];
    string sOwner=NameURI(llList2Key(llGetObjectDetails(kCurID, [OBJECT_OWNER]),0)) ;
    string sPrompt="\n"+llList2String(llGetObjectDetails(kCurID, [OBJECT_NAME]),0)+", owned by "+sOwner+" wants to control your viewer.";
    if (llGetSubString(sCommand,0,6)=="!x-who/") {
        lButtons+=["Trust User","Block User"];
    }
    sPrompt+="\n\nDo you want to allow this?";
    g_iAuthPending = TRUE;
    Dialog(g_kWearer, sPrompt, lButtons, [], 0, CMD_WEARER, "AuthMenu");
}

string HandleCommand(string sIdent, key kID, string sCom, integer iAuthed) {
    
    if(llGetUnixTime()<g_iWaitTarget && g_iWaitTarget!=-1)return "";
    else if(llGetUnixTime()>g_iWaitTarget && g_iWaitTarget!=-1){
        g_iWaitTarget =-1;
    }
    list lCommands=llParseString2List(sCom,["|"],[]);
    sCom = llList2String(lCommands, 0);
    integer iGotWho = FALSE; // has the user been specified up to now?
    key kWho;
    integer i;
    for (i=0;i<(lCommands!=[]);++i) {
        sCom = llList2String(lCommands,i);
        list lSubArgs = llParseString2List(sCom,["="],[]);
        string sVal = llList2String(lSubArgs,1);
        string sAck = "ok";
        if (sCom == "!release" || sCom == "@clear") llMessageLinked(LINK_SET,RLV_CMD,"clear",kID);
        else if (sCom == "!version") sAck = "1100";
        else if (sCom == "!implversion") sAck = "OpenCollar Relay 6.2.0";
        else if (sCom == "!x-orgversions") sAck = "ORG=0003/who=001";
        else if (llGetSubString(sCom,0,6)=="!x-who/") {kWho = SanitizeKey(llGetSubString(sCom,7,42)); iGotWho=TRUE;}
        else if (llGetSubString(sCom,0,0) == "!") sAck = "ko"; // ko unknown meta-commands
        else if (llGetSubString(sCom,0,0) != "@") {
             RelayNotify(g_kWearer,"\n\nBad command from "+llKey2Name(kID)+".\n\nCommand: "+sIdent+","+(string)g_kWearer+"\n\nFaulty subcommand: "+sCom+"\n\nPlease report to the maker of this device.\n",0);
            //if (iIsWho) return llList2String(lCommands,0)+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            //else return llDumpList2String(llList2List(lCommands,i,-1),"|");
            //better try to execute the rest of the command, right?
            sAck=""; //not ko'ing as some old bug in chorazin cages would make them go wrong. Otherwise "ko" looks closer in spirit to the relay spec. (issue 514)
        }//probably an ill-formed command, not answering
        else if ((!llSubStringIndex(sCom,"@version"))||(!llSubStringIndex(sCom,"@get"))||(!llSubStringIndex(sCom,"@findfolder"))) {//(IsChannelCmd(sCom))
            if ((integer)sVal) llMessageLinked(LINK_SET,RLV_CMD, llGetSubString(sCom,1,-1), kID); //now with RLV 1.23, negative channels can also be used
            else sAck="ko";
        } else if (g_iLiteMode&&llGetSubString(sCom,0,0)=="@"&&sVal!="n"&&sVal!="add")
            llMessageLinked(LINK_SET,RLV_CMD, llGetSubString(sCom,1,-1), kID);
        else if (!iAuthed) {
            if (iGotWho) return "!x-who/"+(string)kWho+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            else return llDumpList2String(llList2List(lCommands,i,-1),"|");
        } else if ((lSubArgs!=[])==2) {
            string sBehav=llGetSubString(llList2String(lSubArgs,0),1,-1);
            list lTemp=llParseString2List(sBehav,[":"],[]);
            if (g_iSmartStrip && llList2String(lTemp,0) == "remoutfit" && sVal == "force") {
                if (llList2String(lTemp,1) != "") llMessageLinked(LINK_SET,RLV_CMD,"detachallthis:"+llList2String(lTemp,1)+"="+sVal,kID);
                else {  // only if  'remoutfit=force'
                    list parts=["jacket","pants","shirt","shoes","skirt","socks","underpants","undershirt"]; //"gloves","alpha","tattoo","physics"];
                    integer n;
                    for (n=0; n<llGetListLength(parts); ++n)
                        llMessageLinked(LINK_SET,RLV_CMD,"detachallthis:"+llList2String(parts,n)+"="+sVal,kID);
                }
            }
            if (sVal=="force"||sVal=="n"||sVal=="add"||sVal=="y"||sVal=="rem"||sBehav=="clear")
                llMessageLinked(LINK_SET,RLV_CMD,sBehav+"="+sVal,kID);
            else sAck="ko";
        } else {
             RelayNotify(g_kWearer,"\n\nBad command from "+llKey2Name(kID)+".\n\nCommand: "+sIdent+","+(string)g_kWearer+"\n\nFaulty subcommand: "+sCom+"\n\nPlease report to the maker of this device.\n",0);
            //if (iIsWho) return llList2String(lCommands,0)+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            //else return llDumpList2String(llList2List(lCommands,i,-1),"|");
            //better try to execute the rest of the command, right?
            sAck=""; //not ko'ing as some old bug in chorazin cages would make them go wrong. Otherwise "ko" looks closer in spirit to the relay spec. (issue 514)
        }//probably an ill-formed command, not answering
        if (sAck) sendrlvr(sIdent, kID, sCom, sAck);
    }
    return "";
}

sendrlvr(string sIdent, key kID, string sCom, string sAck) {
    llRegionSayTo(kID, RELAY_CHANNEL, sIdent+","+(string)kID+","+sCom+","+sAck);
    if (g_kDebugRcpt == g_kWearer) llOwnerSay("From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);
    else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt, DEBUG_CHANNEL, "From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);
}
integer g_iWaitTarget=-1; // Default is -1, if this value is anything but -1, wait until unix time is greater than the target and reset it to -1, during wait time, no restrictions should be accepted. Infact the relay should be on pause mode, and not acknowledge any requests to it.
SafeWord() {
    if (!g_iHelpless) {
        // Fix for issue #146, add 30 (revised it to be 20) seconds to the current unix time, and make the relay wait to act upon any new restrictions until time is greater than expected unix target.
        g_iWaitTarget=(llGetUnixTime()+20);
        llMessageLinked(LINK_SET, CMD_RELAY_SAFEWORD, "", "");
        RelayNotify(g_kWearer,"Restrictions lifted. Relay is now paused for 30 seconds",0);
        g_lTempBlockObj=[];
        g_lTempTrustObj=[];
        g_lTempBlockUser=[];
        g_lTempTrustUser=[];
        integer i;
        for (i=0;i<(g_lSources!=[]);++i)
            sendrlvr("release", llList2Key(g_lSources, i), "!release", "ok");
        g_lSources=[];
        g_iRecentSafeword = TRUE;
        refreshRlvListener();
        llSetTimerEvent(30.);
    } else RelayNotify(g_kWearer,"Access denied!",0);

}

//----Menu functions section---//
Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Relay]";
    list lButtons = ["☐ Trusted","☐ Ask","☐ Auto"];
    if (g_iBaseMode == 1){
        lButtons = ["☒ Trusted","☐ Ask","☐ Auto"];
        sPrompt += " is set to trusted mode.";
    }
    else if (g_iBaseMode == 2){
        lButtons = ["☐ Trusted","☒ Ask","☐ Auto"];
        sPrompt += " is set to ask mode.";
    }
    else if (g_iBaseMode == 3){
        lButtons = ["☐ Trusted","☐ Ask","☒ Auto"];
        sPrompt += " is set to auto mode.";
    }
    else sPrompt += " is offline.";
    if (g_iLiteMode) lButtons+=["☑ Lite"];
    else lButtons+=["☐ Lite"];
    if (g_iSmartStrip) lButtons+=["☑ Smart"];
    else lButtons+=["☐ Smart"];
    if (g_iLandMode) lButtons+=["☑ Land"];
    else lButtons+=["☐ Land"];
    lButtons+=["Pending","Sources","Access Lists"];
    if (g_iHelpless) lButtons+=["☑ Helpless"];
    else lButtons+=["☐ Helpless"];
    if (!g_iHelpless) lButtons+=["SAFEWORD"];
    if (g_lSources!=[]) {
        sPrompt+="\n\nCurrently grabbed by "+(string)(g_lSources!=[])+" source";
        if (g_lSources==[1]) sPrompt+="."; // Note: only list LENGTH is compared here
        else sPrompt+="s.";
    }
    if (g_lQueue!=[]) sPrompt+="\n\nYou have a pending request.";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

AccessList(key kID, integer iAuth) {
    list lButtons=[];
    string sPrompt = "\nAccess Lists: ";
    if (llGetListLength(g_lTrustObj) > 0) lButtons+=["Trust Objects"];
    if (llGetListLength(g_lBlockObj) > 0) lButtons+=["Block Objects"];
    if (llGetListLength(g_lTrustAv) > 0) lButtons+=["Trust Avatars"];
    if (llGetListLength(g_lBlockAv) > 0) lButtons+=["Block Avatars"];
    if (lButtons == []) sPrompt += "all empty.";
    else sPrompt += "\nWhat list do you want to remove items from?";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Access~List");
}

ListsMenu(key kID, string sMsg, integer iAuth) {
    list lButtons;
    string sPrompt;
    if (sMsg == "Trust Objects") {
        lButtons = llList2ListStrided(llDeleteSubList(g_lTrustObj,0,0), 0, -1, 2);
        sPrompt = "\nWhat object do you want to stop trusting?";
    } else if (sMsg == "Block Objects") {
        lButtons = llList2ListStrided(llDeleteSubList(g_lBlockObj,0,0), 0, -1, 2);
        sPrompt = "\nWhat object do you want not to block anymore?";
    } else if (sMsg == "Trust Avatars") {
        lButtons = g_lTrustAv;
        sPrompt = "\nWhat avatar do you want to stop trusting?";
    } else if (sMsg == "Block Avatars") {
        lButtons = g_lBlockAv;
        sPrompt = "\nWhat avatar do you want not to block anymore?";
    } else return;
    Dialog(kID, sPrompt, [ALL]+lButtons, [UPMENU], -1, iAuth, "Remove~"+sMsg);
}

RemoveList(string sMsg, integer iAuth, string sListType) {
    integer i;
    if (sListType == "Block Avatars") {
        if (sMsg == ALL) g_lBlockAv = [];
        else {
            i = llListFindList(g_lBlockAv,[sMsg]);
            if (i!=-1) g_lBlockAv = llDeleteSubList(g_lBlockAv,i,i);
        }
        SaveBlockAv();
    } else if (sListType == "Block Objects") {
        if (sMsg == ALL) g_lBlockObj = [];
        else {
            i = llListFindList(g_lBlockObj,[sMsg]);
            if (i!=-1) g_lBlockObj = llDeleteSubList(g_lBlockObj,i-1,i);
        }
        //SaveBlockObj();
    } else if (iAuth==CMD_WEARER && g_iMinBaseMode > 0) {
        RelayNotify(g_kWearer,"Access denied!",0);
        return;
    } else if (sListType == "Trust Objects") {
        if (sMsg == ALL) g_lTrustObj = [];
        else {
            i = llListFindList(g_lTrustObj,[sMsg]);
            if (i!=-1) g_lTrustObj = llDeleteSubList(g_lTrustObj,i-1,i);
        }
        //SaveTrustObj();
    } else if (sListType == "Trust Avatars") {
        if (sMsg == ALL) g_lTrustAv = [];
        else {
            i = llListFindList(g_lTrustAv,[sMsg]);
            if (i!=-1) g_lTrustAv = llDeleteSubList(g_lTrustAv,i,i);
        }
        SaveTrustAv();
    }
}

refreshRlvListener() {
    llListenRemove(g_iRlvListener);
    llListenRemove(g_iSafetyListener);
    if (g_iRLV && g_iBaseMode && !g_iRecentSafeword) {
        g_iRlvListener = llListen(RELAY_CHANNEL, "", NULL_KEY, "");
        g_iSafetyListener = llListen(SAFETY_CHANNEL, "","","Safety!");
        llRegionSayTo(g_kWearer,SAFETY_CHANNEL,"SafetyDenied!");
    }
}

CleanQueue() {
    //clean newly iNumed events, while preserving the order of arrival for every device
    list lOnHold=[];
    integer i=0;
    while (i<(g_lQueue!=[])/QSTRIDES) { //GetQLength()
        string sIdent = llList2String(g_lQueue,0); //GetQident(0)
        key kObj = llList2String(g_lQueue,1); //GetQObj(0);
        string sCommand = llList2String(g_lQueue,2); //GetQCom(0);
        key kUser = NULL_KEY;
        integer iGotWho = llGetSubString(sCommand,0,6)=="!x-who/";
        if (iGotWho) kUser=SanitizeKey(llGetSubString(sCommand,7,42));
        integer iAuth=Auth(kObj,kUser);
        if(~llListFindList(lOnHold,[kObj])) ++i;
        else if(iAuth==1 && (kUser!=NULL_KEY || !iGotWho)) {// !x-who/NULL_KEY means unknown user
            g_lQueue = llDeleteSubList(g_lQueue,i,i+QSTRIDES-1); //DeleteQItem(i);
            HandleCommand(sIdent,kObj,sCommand,TRUE);
        } else if(iAuth==-1) {
            g_lQueue = llDeleteSubList(g_lQueue,i,i+QSTRIDES-1); //DeleteQItem(i);
            list lCommands = llParseString2List(sCommand,["|"],[]);
            integer j;
            for (j=0;j<(lCommands!=[]);++j)
                sendrlvr(sIdent,kObj,llList2String(lCommands,j),"ko");
        } else {
            ++i;
            lOnHold+=[kObj];
        }
    }
    //end of cleaning, now check if there is still events in queue and act accordingly
    Dequeue();
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER || iNum==CMD_EVERYONE) return;
    if (llToLower(sStr) == "rm relay") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) RelayNotify(kID,"Access denied!",0);
        else  Dialog(kID,"\nAre you sure you want to delete the relay plugin?\n", ["Yes","No","Cancel"], [], 0, iNum,"rmrelay");
        return;
    }
    if (llSubStringIndex(sStr,"relay") && sStr != "menu "+g_sSubMenu) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (!g_iRLV) {
        llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
        llMessageLinked(LINK_SET,NOTIFY,"0\n\n\The relay requires RLV to be running in the %DEVICETYPE% but it currently is not. To make things work, click \"ON\" in the RLV menu that just popped up!\n",kID);
    } else if (sStr=="relay" || sStr == "menu "+g_sSubMenu) Menu(kID, iNum);
    else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else if ((sStr=llGetSubString(sStr,6,-1))=="safeword") SafeWord(); // cut "relay " off sStr
    else if (sStr=="getdebug") {
        g_kDebugRcpt = kID;
        RelayNotify(kID,"/me messages will be forwarded to "+NameURI(kID)+".",1);
        return;
    } else if (sStr=="stopdebug") {
        g_kDebugRcpt = NULL_KEY;
        RelayNotify(kID,"/me messages won't forwarded anymore.",1);
        return;
    } else if (sStr=="pending") {
        if (g_lQueue != []) Dequeue();
        else {
            RelayNotify(kID,"There are no pending requests.",0);
            Menu(kID, iNum);
        }
    } else if (sStr=="access") AccessList(kID, iNum);
    else {
        integer iWSuccess = 0; //0: successful, 1: forbidden because of minmode, 2: forbidden because grabbed, 3: unrecognized commad
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        if (sChangetype=="helpless") {
            if (g_lSources!=[]) iWSuccess = 2;
            else if (sChangevalue == "on") {
                if (iNum == CMD_OWNER) g_iMinHelplessMode = TRUE;
                sText = "Helplessness imposed.\n\nRestrictions from outside sources can't be cleard with the dedicated relay safeword command.\n";
                g_iHelpless = TRUE;
            } else if (sChangevalue == "off") {
                if (iNum == CMD_OWNER) g_iMinHelplessMode = FALSE;
                if (g_iMinHelplessMode == TRUE) iWSuccess = 1;
                else {
                    if (iNum == CMD_OWNER) g_iMinHelplessMode = FALSE;
                    g_iHelpless = FALSE;
                    sText = "Helplessness lifted.\n\nSafewording will clear restrictions from outside sources.\n";
                }
            } //else iWSuccess = 3;
        } else if (llGetSubString(sChangetype,0,4) == "smart") {
            if (sChangevalue == "off") {
                g_iSmartStrip = FALSE;
                sText = "Smartstrip turned off.\n\nAttachments and clothing, also if layers are somewhere inside #RLV folder directories, will be stripped normally.\n";
            } else if (sChangevalue == "on") {
                sText = "Smartstrip turned on.\n\nAll smartstrip ready folders in the #RLV directory will be removed as a whole when corresponding clothing layers are stripped.\n";
                g_iSmartStrip = TRUE;
            }
        } else if (sChangetype=="land") {
            if (sChangevalue == "off") {
                if (iNum == CMD_OWNER) g_iMinLandMode = FALSE;
                if (g_iMinLandMode == TRUE) iWSuccess = 1;
                else {
                    sText = "Landowner is not trusted.\n\nRLV commands from their objects will require confirmation on Ask mode as well.\n";
                    g_iLandMode = FALSE;
                }
            } else if (sChangevalue == "on") {
                if (iNum == CMD_OWNER) g_iMinLandMode = TRUE;
                sText = "Landowner is trusted.\n\nRLV commands from their objects will be processed without confirmation even on Ask mode.\n";
                g_iLandMode = TRUE;
            } //else iWSuccess = 3;
        } else if (sChangetype=="lite") {
            if (sChangevalue == "off") {
                if (iNum == CMD_OWNER) g_iMinLiteMode = FALSE;
                if (g_iMinLiteMode == TRUE) iWSuccess = 1;
                else {
                    sText = "Lite option deactivated.\n\nUnless on Ask mode, stripping and restrictive requests will be processed without confirmation.\n";
                    g_iLiteMode = FALSE;
                }
            } else if (sChangevalue == "on") {
                if (iNum == CMD_OWNER) g_iMinLiteMode = TRUE;
                sText = "Lite option activated.\n\nOnly stripping will happen instantly now. All restrictive requests will require prior confirmation.\n";
                g_iLiteMode = TRUE;
            } //else iWSuccess = 3;
        } else {
            list lModes = ["off", "trusted", "ask", "auto"];
            integer iModeType = llListFindList(lModes, [sChangetype]);
            if (sChangevalue == "off") iModeType = 0;
            if (iNum == CMD_OWNER) g_iMinBaseMode = iModeType;
            if (~iModeType) {
                if (iModeType >= g_iMinBaseMode) {
                    if (iModeType) sText = "/me is set to "+llList2String(lModes,iModeType)+" mode.";
                    else sText = "/me is offline.";
                    g_iBaseMode = iModeType;
                } else iWSuccess = 1;
            } //else iWSuccess = 3;
        }
        if (!iWSuccess) RelayNotify(kID,sText,1);
        else if (iWSuccess == 1)  RelayNotify(kID,"Access denied!",0);
        else if (iWSuccess == 2)  RelayNotify(kID,"/me is currently in use by one or more sources.\n\nHelplessness can't be toggled at this moment.\n",1);
        //else if (iWSuccess == 3)  RelayNotify(kID,"Invalid command, please read the manual.",0);
        SaveMode();
        refreshRlvListener();
    }
}

DebugOutput(key kID, list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llInstantMessage(kID, llGetScriptName() +final);
}

default {
    on_rez(integer iNum) {
        
        g_iRLV=FALSE; // turn off RLV until we get a signal from oc_rlvsys
        g_lSources=[];

        g_lTempTrustObj=[];
        g_lTempBlockObj=[];
        g_lTempTrustUser=[];
        g_lTempBlockUser;
        g_lTrustObj; // 2-strided list uuid,name
        g_lBlockObj; // 2-strided list uuid,name
        g_lTrustAv; // keys stored as string since strings is what you get when restoring settings
        g_lBlockAv; // same here (this fixes issue 1253)

        g_lQueue=[];
        QSTRIDES=3;
    }
    
    changed(integer iChange){
        if(iChange&CHANGED_OWNER){
            llResetScript();
        }
    }

    state_entry() {
        g_kWearer = llGetOwner();
        g_lSources=[];
        llSetTimerEvent(g_iGarbageRate); //start garbage collection timer
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum==CMD_ADDSRC)
            g_lSources+=[kID];
        else if (iNum==CMD_REMSRC) {
            integer i= llListFindList(g_lSources,[kID]);
            if (~i) g_lSources=llDeleteSubList(g_lSources,i,i);
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sSettingsToken+"mode") UpdateMode((integer)sValue);
            else if (sToken==g_sSettingsToken+"trustav") g_lTrustAv = llParseString2List(sValue, [","], []);
            else if (sToken==g_sSettingsToken+"blockav") g_lBlockAv = llParseString2List(sValue, [","], []);
           // else if (sToken==g_sSettingsToken+"trustobj") g_lTrustObj = llParseString2List(sValue, [","], []);
           // else if (sToken==g_sSettingsToken+"blockobj") g_lBlockObj = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_owner") g_lOwner = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_tempowner") g_lTempOwner = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_trust") g_lTrust = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_block") g_lBlock = llParseString2List(sValue, [","], []);
        } else if (iNum == RLV_OFF) {
            g_iRLV=FALSE;
            refreshRlvListener();
        } else if (iNum == RLV_ON) {
            g_iRLV=TRUE;
            refreshRlvListener();
        } else if (iNum==RLV_REFRESH) {
            g_iRLV=TRUE;
            refreshRlvListener();
        } else if( iNum == CMD_SAFEWORD)SafeWord();
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = llList2Key(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                //integer iPage = llList2Integer(lMenuParams, 2);
                integer iAuth = llList2Integer(lMenuParams, 3);
                llSetTimerEvent(g_iGarbageRate);
                if (sMenu == "Menu~Main") {
                    if (sMsg==UPMENU) llMessageLinked(LINK_SET,iAuth,"menu "+g_sParentMenu,kAv);
                    else if (sMsg=="Pending") UserCommand(iAuth, "relay pending", kAv);
                    else if (sMsg=="Access Lists") UserCommand(iAuth, "relay access", kAv);
                    else if (sMsg=="SAFEWORD") UserCommand(iAuth, "relay safeword", kAv);
                    else if (sMsg=="Sources") {
                        llMessageLinked(LINK_SET, iAuth,"show restrictions", kAv);
                        Menu(kAv, iAuth);
                    } else {
                        sMsg = llToLower(sMsg);
                        if (llSubStringIndex(sMsg,"☐ ")==0)
                            sMsg = llDeleteSubString(sMsg,0,1)+" on";
                        else if (llSubStringIndex(sMsg,"☒ ")==0||llSubStringIndex(sMsg,"☑ ")==0)
                            sMsg = llDeleteSubString(sMsg,0,1)+" off";
                        sMsg ="relay "+sMsg;
                        UserCommand(iAuth, sMsg, kAv);
                        Menu(kAv, iAuth);
                    }
                } else if (sMenu=="Access~List") {
                    if (sMsg==UPMENU) Menu(kAv, iAuth);
                    else ListsMenu(kAv,sMsg, iAuth);
                } else if (llSubStringIndex(sMenu,"Remove~")==0) {
                    if (sMsg==UPMENU) AccessList(kAv, iAuth);
                    else {
                        string sMenuType=llList2String(llParseString2List(sMenu,["~"],[]),1);
                        RemoveList(sMsg, iAuth, sMenuType);
                        AccessList(kAv, iAuth);
                    }
                } else if (sMenu=="AuthMenu") {
                    g_iAuthPending = FALSE;
                    key kCurID=llList2String(g_lQueue,1); //GetQObj(0);
                    string sCom = llList2String(g_lQueue,2);  //GetQCom(0));
                    key kUser = NULL_KEY;
                    key kOwner = llGetOwnerKey(kCurID);
                    if (llGetSubString(sCom,0,6)=="!x-who/") kUser = SanitizeKey(llGetSubString(sCom,7,42));
                    if (sMsg=="Yes") {
                        g_lTempTrustObj+=[kCurID];
                        if (kUser) g_lTempTrustUser+=[(string)kUser];
                    } else if (sMsg=="No") {
                        g_lTempBlockObj+=[kCurID];
                        if (kUser) g_lTempBlockUser+=[(string)kUser];
                    } else if (sMsg=="Trust Object") {
                        if (!~llListFindList(g_lTrustObj, [kCurID]))
                            g_lTrustObj+=[kCurID,llKey2Name(kCurID)];
                            //SaveTrustObj();
                    } else if (sMsg=="Block Object") {
                        if (!~llListFindList(g_lBlockObj, [kCurID]))
                            g_lBlockObj+=[kCurID,llKey2Name(kCurID)];
                            //SaveBlockObj();
                    } else if (sMsg=="Trust Owner") {
                        if (!~llListFindList(g_lTrustAv, [(string)kOwner])) {
                            g_lTrustAv+=[(string)kOwner];
                            SaveTrustAv();
                        }
                    } else if (sMsg=="Block Owner") {
                        if (!~llListFindList(g_lBlockAv, [(string)kOwner])) {
                            g_lBlockAv+=[(string)kOwner];
                            SaveBlockAv();
                        }
                    } else if (sMsg=="Trust User") {
                        if (!~llListFindList(g_lTrustAv, [(string)kUser])) {
                            g_lTrustAv+=[(string)kUser];
                            SaveTrustAv();
                        }
                    } else if (sMsg=="Block User") {
                        if (!~llListFindList(g_lBlockAv, [(string)kUser])) {
                            g_lBlockAv+=[(string)kUser];
                            SaveBlockAv();
                        }
                    }
                    g_iAuthPending=FALSE;
                    CleanQueue();
                    Dequeue();
                } else if (sMenu == "rmrelay") {
                    if (sMsg == "Yes") {
                        integer i;
                        for (i=0;i<(g_lSources!=[]);++i)
                            sendrlvr("release", llList2Key(g_lSources, i), "!release", "ok");
                        UserCommand(500, "relay off", kAv);
                        llMessageLinked(LINK_SET, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        RelayNotify(kAv,"/me has been removed.",1);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else RelayNotify(kAv,"/me remains installed.",0);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                if (llList2String(g_lMenuIDs, iMenuIndex+1) == "AuthMenu") {
                    g_iAuthPending = FALSE;
                    RelayNotify(g_kWearer,"/me confirmation dialog expired.\n\nClicking the \"Pending\" button in the Relay menu will make this dialog appear again.\n",0);
                }
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
            }
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            
            DebugOutput(kID, [" SOURCES:"]+g_lSources);
            DebugOutput(kID, [" AUTH PENDING:", g_iAuthPending]);
            
            
        }
    }

    listen(integer iChan, string who, key kID, string sMsg) {
        if (iChan == SAFETY_CHANNEL) {
            llMessageLinked(LINK_SET,NOTIFY,"0\n\n⚠ "+who+" detected ⚠\n\nTo prevent conflicts this relay is being detached now! If you wish to use "+who+" anyway, type \"/%CHANNEL% %PREFIX% relay off\" to temporarily disable or type \"/%CHANNEL% %PREFIX% rm relay\" to permanently uninstall the relay plugin.\n",g_kWearer);
            llRegionSayTo(g_kWearer,SAFETY_CHANNEL,"SafetyDenied!");
        }
/*
        if (llGetSubString(sMsg,-43,-1)==","+(string)g_kWearer+",!pong")
        {   //sloppy matching; the protocol document is stricter, but some in-world devices do not respect it
            llOwnerSay("Forwarding "+sMsg+" to rlvmain");
            llMessageLinked(LINK_SET, CMD_RLV_RELAY, sMsg, kID);
            // send the ping to rlvmain to manage restrictions of this old source
        }
        else if (llStringLength(sMsg)> 700)
        {   //too long command, will make the relay crash in ask mode
            sMsg="";
            llOwnerSay("Dropping a too long command from " + llKey2Name(kID)+". Maybe a malicious device?. Relay frozen for the next 20s.");
            g_iRecentSafeword=TRUE;
            refreshRlvListener();
            llSetTimerEvent(30.);
            return;
        }
        else
        { //in other cases we analyze the command here
*/
        if(llGetUnixTime()<g_iWaitTarget && g_iWaitTarget!=-1){
            return;
        }
        else if(llGetUnixTime()>g_iWaitTarget && g_iWaitTarget!=-1){
            g_iWaitTarget =-1;
        }
        list lArgs=llParseString2List(sMsg,[","],[]);
        sMsg = "";  // free up memory in case of large messages
        if ((lArgs!=[])!=3) return;
        if (llList2Key(lArgs,1)!=g_kWearer && llList2String(lArgs,1)!="ffffffff-ffff-ffff-ffff-ffffffffffff") return; // allow FFF...F wildcard
        string sIdent=llList2String(lArgs,0);
        sMsg=llToLower(llList2String(lArgs,2));
        if (g_kDebugRcpt == g_kWearer) llOwnerSay("To relay: "+sIdent+","+sMsg);
        else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt, DEBUG_CHANNEL, "To relay: "+sIdent+","+sMsg);
        if (sMsg == "!pong") {
        //sloppy matching; the protocol document is stricter, but some in-world devices do not respect it
            llMessageLinked(LINK_SET, CMD_RLV_RELAY, "ping,"+(string)g_kWearer+",!pong", kID);
            return;
        }
        lArgs = [];  // free up memory in case of large messages
        key kUser = NULL_KEY;
        if (llGetSubString(sMsg,0,6)=="!x-who/") kUser=SanitizeKey(llGetSubString(sMsg,7,42));
        integer iAuth=Auth(kID,kUser);
        if (iAuth==-1) return;
        else if (iAuth==1) {HandleCommand(sIdent,kID,sMsg,TRUE); llSetTimerEvent(g_iGarbageRate);}
        else if (g_iBaseMode == 2) {
//            llOwnerSay("Free memory before queueing: "+(string)(llGetMemoryLimit() - llGetUsedMemory()));
//            if (llGetMemoryLimit() - llGetUsedMemory()> 5000) //keeps margin for this event + next arriving chat message
//            {
            g_lQueue += [sIdent, kID, sMsg];
            sMsg = ""; sIdent="";
//            llOwnerSay("Used memory after queueing: "+(string)(llGetMemoryLimit() -llGetUsedMemory()));
//            }
//            else
            if (llGetMemoryLimit() - llGetUsedMemory()< 3927) {//keeps margin for this event + next arriving chat message
                sMsg = ""; sIdent="";
                key kOldestId = llList2Key(g_lQueue, 1);  // It's actually more likely we want to drop the old request we completely forgot about rather than the newest one that will be forgotten because of some obscure memory limit.
//                key kOldUser = NULL_KEY;
//                if (llGetSubString(sMsg,0,6)=="!x-who/") kOldUser=SanitizeKey(llGetSubString(llList2String(g_lQueue, 2),7,42));
                RelayNotify(g_kWearer,"/me queue saturated.\n\nDropping all requests from oldest source ("+ llKey2Name(kOldestId) +").\n",0);
                g_lTempBlockObj+=[kOldestId];
//                if (kUser) g_lTempBlockUser+=[kUser];
                CleanQueue();
//                llOwnerSay("Used memory after cleaning queue: "+(string)(llGetMemoryLimit() -llGetUsedMemory()));
//                g_iRecentSafeword = TRUE;
//                refreshRlvListener();
//                llSetTimerEvent(30.);
// SA: maybe some of the above should be re-added to "punish" spammers more aggressively.
            }
            if (!g_iAuthPending) Dequeue();
        } else if (g_iLiteMode) {HandleCommand(sIdent,kID,sMsg,FALSE); llSetTimerEvent(g_iGarbageRate);}
    }

    timer() {
        if (g_iRecentSafeword) {
            g_iRecentSafeword = FALSE;
            refreshRlvListener();
        }
        //garbage collection
        vector vMyPos = llGetRootPosition();
        integer i;
        for (i=0;i<(g_lSources!=[]);++i) {
            key kID = llList2Key(g_lSources,i);
            vector vObjPos = llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]),0);
            if (vObjPos == <0, 0, 0> || llVecDist(vObjPos, vMyPos) > 100) // 100: max shout distance
                llMessageLinked(LINK_SET,RLV_CMD,"clear",kID);
        }
        llSetTimerEvent(g_iGarbageRate);
        //g_iAuthPending = FALSE;
        g_lTempBlockObj=[];
        g_lTempTrustObj=[];
        if (g_lSources == []) {
        //dont clear already authorized users before done with current session
            g_lTempBlockUser=[];
            g_lTempTrustUser=[];
        }
    }
}
