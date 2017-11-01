//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//             Relay - 171017.1          .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2017 Satomi Ahn, Nandana Singh, Wendy Starfall,    //
//  Sumi Perl, littlemousy, Romka Swallowtail, Garvin Twine et al.          //
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
//       github.com/VirtualDisgrace/opencollar/tree/master/src/collar       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

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
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507; // now will be used from rlvrelay to rlvmain, for ping only
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
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

//list g_lSources;
string g_sSourceID;

string g_sTempTrustObj;
string g_sTempTrustUser;

list g_lBlockObj; // 2-strided list uuid,timestamp in unixtime
list g_lBlockAv;

integer g_iRLV = FALSE;
list g_lQueue;
integer g_iListener=0;
integer g_iRecentSafeword;

//relay specific message map
integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

//collar Owners, TempOwners, Trusts and Blocks caching
list g_lOwner;
string g_sTempOwner;
list g_lTrust;
list g_lBlock;

//settings
integer g_iMinBaseMode = FALSE;
integer g_iMinHelplessMode = FALSE;
//integer g_iMinLandMode = FALSE;
//integer g_iMinLiteMode = FALSE;
integer g_iBaseMode = 2; //0=off, 1=trust (not used, needed to load old settings), 2=ask, 3=auto
integer g_iHelpless = 0;

key g_kDebugRcpt = NULL_KEY; // recipient key for relay chat debugging (useful since you cannot eavesdrop llRegionSayTo)
/*integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

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

UpdateMode(integer iMode) {
    g_iBaseMode = iMode        & 3; //1
    if (g_iBaseMode == 1) g_iBaseMode = 2; //needed when old relays were set to Trusted
    g_iHelpless = (iMode >> 2) & 1; //4
//    g_iLandMode = (iMode >> 3) & 1; //8
//    g_iLiteMode = (iMode >> 4) & 1; //16
    g_iMinBaseMode = (iMode >> 5) & 3; //32
    if (g_iMinBaseMode == 1) g_iMinBaseMode = 2; //needed when old relays were set to Trusted
    g_iMinHelplessMode = (iMode >> 7) & 1; //128
}

SaveMode() {
    //keeping the old bits else we fail to read the old ones, too
    string sMode = (string)(128*g_iMinHelplessMode + 32*g_iMinBaseMode + 4*g_iHelpless + g_iBaseMode);
    llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingsToken+"mode="+sMode,"");
}

integer Auth(string sObjectID, string sUserID) {
    integer iAuth = 1;
    string sOwner = llGetOwnerKey(sObjectID);
    //object auth
    if (sObjectID == g_sSourceID) {}
    else if (~llListFindList(g_lBlockObj,[sObjectID])) return -1;
    else if (~llListFindList(g_lBlockAv+g_lBlock,[sOwner])) return -1;
    else if (g_iBaseMode == 3) {}
    else if (g_sTempTrustObj == sObjectID) {}
    else if (~llListFindList(g_lOwner+g_lTrust+[g_sTempOwner],[sOwner])) {}
    else iAuth = 0;
    //user auth
    if ((key)sUserID) {
        if (~llListFindList(g_lBlock+g_lBlockAv,[sUserID])) return -1;
        else if (g_iBaseMode == 3) {}
        else if (g_sTempTrustUser == sUserID) {}
        else if (~llListFindList(g_lOwner+g_lTrust+[g_sTempOwner],[sUserID])) {}
        else return 0;
    }
    return iAuth;
}

string NameURI(string sID) {
    return "secondlife:///app/agent/"+sID+"/inspect";
}

string ObjectURI(string sID) {
    vector vPos = llGetPos();
    string surl = llEscapeURL(llGetRegionName())+"/"+(string)((integer)(vPos.x))+"/"+"/"+(string)((integer)(vPos.y))+"/"+(string)((integer)(vPos.z));
    return "secondlife:///app/objectim/"+sID+"?name="+llEscapeURL(llKey2Name(sID))+"&owner="+(string)llGetOwnerKey(sID)+"&slurl="+surl;    
}

string HandleCommand(string sIdent, key kID, string sCom, integer iAuthed) {
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
        if (sCom == "!release" || sCom == "@clear") {
            llMessageLinked(LINK_RLV,RLV_CMD,"clear",kID);
            g_sSourceID = g_sTempTrustObj =  g_sTempTrustUser = "";
        } else if (sCom == "!version") sAck = "1100";
        else if (sCom == "!implversion") sAck = "OpenCollar Relay 6.2.0";
        else if (sCom == "!x-orgversions") sAck = "ORG=0003/who=001";
        else if (llGetSubString(sCom,0,6)=="!x-who/") {kWho = SanitizeKey(llGetSubString(sCom,7,42)); iGotWho=TRUE;}
        else if (llGetSubString(sCom,0,0) == "!") sAck = "ko"; // ko unknown meta-commands
        else if (llGetSubString(sCom,0,0) != "@") {
             RelayNotify(g_kWearer,"\n\nBad command from "+llKey2Name(kID)+".\n\nCommand: "+sIdent+","+(string)g_kWearer+"\n\nFaulty subcommand: "+sCom+"\n\nPlease report to the maker of this device.\n",0);
            sAck=""; 
        } else if ((!llSubStringIndex(sCom,"@version"))||(!llSubStringIndex(sCom,"@get"))||(!llSubStringIndex(sCom,"@findfolder"))) {
            if ((integer)sVal) llMessageLinked(LINK_RLV,RLV_CMD,llGetSubString(sCom,1,-1),kID);
            else sAck="ko";
        } else if (!iAuthed) {
            if (iGotWho) return "!x-who/"+(string)kWho+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            else return llDumpList2String(llList2List(lCommands,i,-1),"|");
        } else if ((lSubArgs!=[])==2) {
            string sBehav=llGetSubString(llList2String(lSubArgs,0),1,-1);
            list lTemp=llParseString2List(sBehav,[":"],[]);
            if (sVal=="force"||sVal=="n"||sVal=="add"||sVal=="y"||sVal=="rem"||sBehav=="clear") {
                if (kID != g_sSourceID) llMessageLinked(LINK_RLV,RLV_CMD,"clear",g_sSourceID);
                llMessageLinked(LINK_RLV,RLV_CMD,sBehav+"="+sVal,kID);
            } else sAck="ko";
        } else {
             RelayNotify(g_kWearer,"\n\nBad command from "+llKey2Name(kID)+".\n\nCommand: "+sIdent+","+(string)g_kWearer+"\n\nFaulty subcommand: "+sCom+"\n\nPlease report to the maker of this device.\n",0);
            sAck="";
        }
        if (sAck) sendrlvr(sIdent, kID, sCom, sAck);
    }
    return "";
}

sendrlvr(string sIdent, key kID, string sCom, string sAck) {
    llRegionSayTo(kID, RELAY_CHANNEL, sIdent+","+(string)kID+","+sCom+","+sAck);
    if (g_kDebugRcpt == g_kWearer) llOwnerSay("From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);
    else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt, DEBUG_CHANNEL, "From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);
}

SafeWord() {
    if (!g_iHelpless) {
        llMessageLinked(LINK_RLV,CMD_RELAY_SAFEWORD,"","");
        RelayNotify(g_kWearer,"Restrictions lifted by safeword. You have 10 seconds to get to safety.",0);
        g_sTempTrustObj = "";
        g_sTempTrustUser = "";
        sendrlvr("release",g_sSourceID,"!release","ok");
        g_sSourceID = "";
        g_lQueue = [];
        g_iRecentSafeword = TRUE;
        refreshRlvListener();
        llSetTimerEvent(10.);
    } else RelayNotify(g_kWearer,"Access denied!",0);

}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[http://www.opencollar.at/relay.html Relay]";
    list lButtons = ["☐ Ask","☐ Auto"];
    if (g_iBaseMode == 2){
        lButtons = ["☒ Ask","☐ Auto"];
        sPrompt += " is set to ask mode.";
    } else if (g_iBaseMode == 3){
        lButtons = ["☐ Ask","☒ Auto"];
        sPrompt += " is set to auto mode.";
    } else sPrompt += " is offline.";
    lButtons += ["Reset"];
    if (g_iHelpless) lButtons+=["☑ Helpless"];
    else lButtons+=["☐ Helpless"];
    if (!g_iHelpless) lButtons+=["SAFEWORD"];
    if (g_sSourceID != "")
        sPrompt+="\n\nCurrently grabbed by "+ObjectURI(g_sSourceID);
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
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

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_relay")
        llRemoveInventory(sName);
}

UserCommand(integer iAuth, string sStr, key kID) {
    if (iAuth<CMD_OWNER || iAuth>CMD_WEARER) return;
    if (llToLower(sStr) == "rm relay") {
        if (kID!=g_kWearer && iAuth!=CMD_OWNER) RelayNotify(kID,"Access denied!",0);
        else  Dialog(kID,"\nAre you sure you want to delete the relay plugin?\n", ["Yes","No","Cancel"], [], 0, iAuth,"rmrelay");
        return;
    }
    if (llSubStringIndex(sStr,"relay") && sStr != "menu "+g_sSubMenu) return;
    if (iAuth == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (!g_iRLV) {
        llMessageLinked(LINK_RLV, iAuth, "menu RLV", kID);
        llMessageLinked(LINK_DIALOG,NOTIFY,"0\n\n\The relay requires RLV to be running in the %DEVICETYPE% but it currently is not. To make things work, click \"ON\" in the RLV menu that just popped up!\n",kID);
    } else if (sStr=="relay" || sStr == "menu "+g_sSubMenu) Menu(kID, iAuth);
    else if (iAuth!=CMD_OWNER && iAuth!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else if ((sStr=llGetSubString(sStr,6,-1))=="safeword") SafeWord(); // cut "relay " off sStr
    else if (sStr == "getdebug") {
        g_kDebugRcpt = kID;
        RelayNotify(kID,"/me messages will be forwarded to "+NameURI(kID)+".",1);
        return;
    } else if (sStr == "stopdebug") {
        g_kDebugRcpt = NULL_KEY;
        RelayNotify(kID,"/me messages won't forwarded anymore.",1);
        return;
    } else if (sStr == "reset") {
        if (g_sSourceID ) 
            RelayNotify(kID,"Sorry but the relay cannot be reset while in use!",1);
        else {
            integer i = g_iMinBaseMode;
            if (!i || iAuth == CMD_OWNER) i = 2;
            Dialog(kID,"\nYou are about to set the relay to "+llList2String([0,1,"ask","auto"],i)+" mode and lift all the blocks that you set on object and avatar sources.\n\nClick [Yes] to proceed with resetting the RLV relay.",["Yes","No"],["Cancel"],0,iAuth,"reset");
        }
    } else {
        integer iWSuccess = 0; //0: successful, 1: forbidden because of minmode, 2: forbidden because grabbed, 3: unrecognized commad
        integer index = llSubStringIndex(sStr," ");
        string sChangetype = llGetSubString(sStr,0,index-1);
        string sChangevalue = llGetSubString(sStr,index+1,-1);
        string sText;
        if (sChangetype == "helpless") {
            if (g_sSourceID !=  "") iWSuccess = 2;
            else if (sChangevalue == "on") {
                if (iAuth == CMD_OWNER) g_iMinHelplessMode = TRUE;
                sText = "Helplessness imposed.\n\nRestrictions from outside sources can't be cleard with the dedicated relay safeword command.\n";
                g_iHelpless = TRUE;
            } else if (sChangevalue == "off") {
                if (iAuth == CMD_OWNER) g_iMinHelplessMode = FALSE;
                if (g_iMinHelplessMode == TRUE) iWSuccess = 1;
                else {
                    if (iAuth == CMD_OWNER) g_iMinHelplessMode = FALSE;
                    g_iHelpless = FALSE;
                    sText = "Helplessness lifted.\n\nSafewording will clear restrictions from outside sources.\n";
                }
            } //else iWSuccess = 3;
        } else {
            list lModes = ["off","trust","ask","auto"];
            //trust is just a placeholder to stay compatible with old settings
            integer iModeType = llListFindList(lModes,[sChangetype]);
            if (sChangevalue == "off") iModeType = 0;
            if (iAuth == CMD_OWNER) g_iMinBaseMode = iModeType;
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
        else if (iWSuccess == 2)  RelayNotify(kID,"/me is currently in use by "+ObjectURI(g_sSourceID)+" sources.\n\nHelplessness can't be toggled at this moment.\n",1);
        //else if (iWSuccess == 3)  RelayNotify(kID,"Invalid command, please read the manual.",0);
        SaveMode();
        refreshRlvListener();
    }
}

default {
    on_rez(integer iStart) {
        if (llGetOwner() != g_kWearer) llResetScript();
        g_lBlockObj = [];
    }

    state_entry() {
        g_kWearer = llGetOwner();
        FailSafe();
        llSetTimerEvent(g_iGarbageRate); //start garbage collection timer
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == CMD_ADDSRC)
            g_sSourceID = kID;
        else if (iNum == CMD_REMSRC) {
            if (g_sSourceID == (string)kID) g_sSourceID = "";
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams,0);
            string sValue = llList2String(lParams,1);
            if (sToken == g_sSettingsToken+"mode") UpdateMode((integer)sValue);
            else if (sToken == g_sSettingsToken+"blockav") g_lBlockAv = llParseString2List(sValue,[","],[]);
            else if (sToken == "auth_owner") g_lOwner = llParseString2List(sValue,[","],[]);
            else if (sToken == "auth_tempowner") g_sTempOwner = sValue;
            else if (sToken == "auth_trust") g_lTrust = llParseString2List(sValue,[","],[]);
            else if (sToken == "auth_block") g_lBlock = llParseString2List(sValue,[","],[]);
        } else if (iNum == RLV_OFF) {
            g_iRLV = FALSE;
            refreshRlvListener();
        } else if (iNum == RLV_ON) {
            g_iRLV = TRUE;
            refreshRlvListener();
        } else if (iNum == RLV_REFRESH) {
            g_iRLV = TRUE;
            refreshRlvListener();
        } else if (iNum == CMD_SAFEWORD && kID == g_kWearer) {
            g_iRecentSafeword = TRUE;
            refreshRlvListener();
            llSetTimerEvent(10.);
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = llList2Key(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = llList2Integer(lMenuParams, 2);
                integer iAuth = llList2Integer(lMenuParams, 3);
                llSetTimerEvent(g_iGarbageRate);
                if (sMenu == "Menu~Main") {
                    if (sMsg==UPMENU) llMessageLinked(LINK_SET,iAuth,"menu "+g_sParentMenu,kAv);
                    else if (sMsg == "SAFEWORD") UserCommand(iAuth,"relay safeword",kAv);
                    else if (sMsg == "Reset") UserCommand(iAuth,"relay reset",kAv);
                    else {
                        sMsg = llToLower(sMsg);
                        if (!llSubStringIndex(sMsg,"☐ "))
                            sMsg = llDeleteSubString(sMsg,0,1)+" on";
                        else if (!llSubStringIndex(sMsg,"☒ ") || !llSubStringIndex(sMsg,"☑ "))
                            sMsg = llDeleteSubString(sMsg,0,1)+" off";
                        sMsg ="relay "+sMsg;
                        UserCommand(iAuth,sMsg,kAv);
                        Menu(kAv,iAuth);
                    }
                } else if (sMenu=="AuthMenu") {
                    string sCurID = llList2String(g_lQueue,1);
                    string sCom = llList2String(g_lQueue,2);
                    key kUser = NULL_KEY;
                    key kOwner = llGetOwnerKey(sCurID);
                    integer iFreeMemory = llGetFreeMemory();
                    if (llGetSubString(sCom,0,6) == "!x-who/") kUser = SanitizeKey(llGetSubString(sCom,7,42));
                    if (sMsg == "Yes") {
                        g_sTempTrustObj = sCurID;
                        if (kUser) g_sTempTrustUser = kUser;
                    } else if (sMsg == "No"); //nothing happens
                    else if (sMsg == "Block") {
                        if (iFreeMemory < 4096) {
                            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your block list is full. Unable to add more to them. To clean them click [Reset] in the menu or use the command: / %CHANNEL% %PREFIX% relay reset",kAv);
                            return;
                        } else if (iFreeMemory < 4608)
                            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your block list is getting quite full. Unless you don't plan on blocking anymore sources, now would be a good time to reset the list. Click [Reset] in the menu or use the command: / %CHANNEL% %PREFIX% relay reset",kAv);
                        if (kUser) {
                            if (!~llListFindList(g_lBlockAv,[(string)kUser])) {
                                g_lBlockAv += (string)kUser;
                                llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingsToken+"blockav="+llDumpList2String(g_lBlockAv,",") ,"");
                                RelayNotify(kAv,NameURI(kUser)+" has been added to the relay blocklist.",0);
                            } else
                                RelayNotify(kAv,NameURI(kUser)+" is already on the relay blocklist.",0);
                        } else {
                            if (!~llListFindList(g_lBlockObj,[sCurID])) {
                                g_lBlockObj += [sCurID,llGetUnixTime()+900];
                                RelayNotify(kAv,"Requests from "+ObjectURI(sCurID)+" are blocked for the next 15 minutes.",0);
                            } else
                                RelayNotify(kAv,ObjectURI(sCurID)+" is already blocked.",0);
                        }
                    }
                    string sIdent = llList2String(g_lQueue,0);
                    iAuth = Auth(sCurID,kUser);
                    if (iAuth == 1) HandleCommand(sIdent,sCurID,sCom,TRUE);
                    else if (iAuth == -1) {
                        list lCommands = llParseString2List(sCom,["|"],[]);
                        integer j;
                        for (;j < (lCommands!=[]); ++j)
                            sendrlvr(sIdent,sCurID,llList2String(lCommands,j),"ko");
                    }
                    g_lQueue = [];
                } else if (sMenu == "rmrelay") {
                    if (sMsg == "Yes") {
                        sendrlvr("release",g_sSourceID,"!release","ok");
                        UserCommand(500, "relay off", kAv);
                        llMessageLinked(LINK_RLV, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        RelayNotify(kAv,"/me has been removed.",1);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else RelayNotify(kAv,"/me remains installed.",0);
                } else if (sMenu == "reset") {
                    if (sMsg == "Yes") {
                        g_lBlockAv = g_lBlockObj = [];
                        llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,g_sSettingsToken+"blockav","");
                        g_sTempTrustUser = "";
                        g_sTempTrustObj = "";
                        if (iAuth == CMD_OWNER) {
                            g_iMinBaseMode = FALSE;
                            g_iMinHelplessMode = FALSE;
                            g_iBaseMode = 2;
                            g_iHelpless = 0;
                        } else {
                            if (g_iMinBaseMode)
                                g_iBaseMode = g_iMinBaseMode;
                            else g_iBaseMode = 2;
                            g_iHelpless = g_iMinHelplessMode;
                        }
                        SaveMode();
                        RelayNotify(kID,"/me has been reset to "+llList2String([0,1,"ask","auto"],g_iBaseMode)+" mode. All previous blocks on object and avatar sources have been lifted.",1);
                    } else RelayNotify(kID,"Reset canceled.",0);
                    Menu(kAv,iAuth);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                if (llList2String(g_lMenuIDs, iMenuIndex+1) == "AuthMenu") {
                    g_lQueue = [];
                    g_sSourceID = "";
                }
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    listen(integer iChan, string who, key kID, string sMsg) {
        if (iChan == SAFETY_CHANNEL) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0\n\n⚠ "+who+" detected ⚠\n\nTo prevent conflicts this relay is being detached now! If you wish to use "+who+" anyway, type \"/%CHANNEL% %PREFIX% relay off\" to temporarily disable or type \"/%CHANNEL% %PREFIX% rm relay\" to permanently uninstall the relay plugin.\n",g_kWearer);
            llRegionSayTo(g_kWearer,SAFETY_CHANNEL,"SafetyDenied!");
        }
        list lArgs = llParseString2List(sMsg,[","],[]);
        sMsg = "";  // free up memory in case of large messages
        if ((lArgs!=[])!=3) return;
        if (llList2Key(lArgs,1) != g_kWearer && llList2String(lArgs,1) != "ffffffff-ffff-ffff-ffff-ffffffffffff") return; // allow FFF...F wildcard
        string sIdent = llList2String(lArgs,0);
        sMsg = llToLower(llList2String(lArgs,2));
        if (g_kDebugRcpt == g_kWearer) llOwnerSay("To relay: "+sIdent+","+sMsg);
        else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt,DEBUG_CHANNEL,"To relay: "+sIdent+","+sMsg);
        if (sMsg == "!pong") {
        //sloppy matching; the protocol document is stricter, but some in-world devices do not respect it
            llMessageLinked(LINK_SET, CMD_RLV_RELAY, "ping,"+(string)g_kWearer+",!pong", kID);
            return;
        }
        lArgs = [];  // free up memory in case of large messages
        //Debug(who+": "+sMsg);
        if (g_sSourceID != kID && g_sSourceID != "") {
            if ((llGetAgentInfo(g_kWearer) & AGENT_ON_OBJECT) == AGENT_ON_OBJECT) return;
        }
        key kUser = NULL_KEY;
        if (llGetSubString(sMsg,0,6) == "!x-who/") kUser = SanitizeKey(llGetSubString(sMsg,7,42));
        integer iAuth = Auth(kID,kUser);
        if (iAuth == -1) return;
        else if (iAuth == 1) HandleCommand(sIdent,kID,sMsg,TRUE);
        else if (g_iBaseMode == 2) {
            HandleCommand(sIdent,kID,sMsg,FALSE);
            if (!llSubStringIndex(sMsg,"@version")) return;
            g_lQueue = [sIdent,kID,sMsg];
            list lButtons = ["Yes","No","Block"];
            string sPrompt = "\n"+ObjectURI(kID)+" wants to control your viewer.";
            if (kUser) sPrompt+="\n" + NameURI(kUser) + " is currently using this device.";
            sPrompt += "\n\nDo you want to allow this?";
            integer iAuthMenuIndex = llListFindList(g_lMenuIDs,["AuthMenu"]);
            if (~iAuthMenuIndex)
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs,iAuthMenuIndex-2,iAuthMenuIndex-3+g_iMenuStride);
            Dialog(g_kWearer,sPrompt,lButtons,[],0,CMD_WEARER,"AuthMenu");
            sMsg = "";
            sIdent="";
        }
        llSetTimerEvent(g_iGarbageRate);
    }

    timer() {
        if (g_iRecentSafeword) {
            g_iRecentSafeword = FALSE;
            refreshRlvListener();
            llSetTimerEvent(g_iGarbageRate);
        }
        //garbage collection
        vector vMyPos = llGetRootPosition();
        if (g_sSourceID) {
            vector vObjPos = llList2Vector(llGetObjectDetails(g_sSourceID,[OBJECT_POS]),0);
            if (vObjPos == <0, 0, 0> || llVecDist(vObjPos, vMyPos) > 100) {
                llMessageLinked(LINK_RLV,RLV_CMD,"clear",g_sSourceID);
                //g_sSourceID = "";
            }
        }
        g_lQueue = [];
        g_sTempTrustObj = "";
        if (g_sSourceID == "") {
        //dont clear already authorized users before done with current session
            g_sTempTrustUser = "";
        }
        integer iTime = llGetUnixTime();
        integer i = ~llGetListLength(g_lBlockObj) + 1;
        while (i < 0) {
            if (llList2Integer(g_lBlockObj,i+1) <= iTime)
                g_lBlockObj = llDeleteSubList(g_lBlockObj,i,i+1);
            i += 2;
        }
        integer iAuthMenuIndex;
        while (~(iAuthMenuIndex = llListFindList(g_lMenuIDs,["AuthMenu"])))
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs,iAuthMenuIndex-2,iAuthMenuIndex-3+g_iMenuStride);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) FailSafe();
    }
    /*    if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }*/
}
