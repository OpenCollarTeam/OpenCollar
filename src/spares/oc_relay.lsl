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
//                           Relay - 160413.1                               //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Satomi Ahn, Nandana Singh, Joy Stipe,         //
//  Wendy Starfall, Sumi Perl, littlemousy, Romka Swallowtail et al.        //
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
//         github.com/OpenCollar/opencollar/tree/master/src/spares          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

integer g_iSmartStrip = FALSE; // Convert @remoutfit to @detachallthis.

string g_sParentMenu = "Apps";
string g_sSubMenu = "Relay";

string g_sAppVersion = "²⋅⁰";

integer RELAY_CHANNEL = -1812221819;
integer SAFETY_CHANNEL = -201818;
integer g_iRlvListener;
integer g_iSafetyListener;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
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
integer g_iListener=0;
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
integer g_iMinBaseMode = 0;
integer g_iMinSafeMode = 1;
integer g_iMinLandMode = 0;
integer g_iMinPlayMode = 0;
integer g_iBaseMode = 2;
integer g_iSafeMode = 1;
integer g_iLandMode = 1;
integer g_iPlayMode = 0;

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
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}


// Sanitizes a key coming from the outside, so that only valid
// keys are returned, and invalid ones are mapped to NULL_KEY
key SanitizeKey(string uuid)
{
    if ((key)uuid) return llToLower(uuid);
    return NULL_KEY;
}

string Mode2String(integer iMin)
{
    string sOut;
    if (iMin)
    {
        if (!g_iMinBaseMode) sOut+="off";
        else if (g_iMinBaseMode==1) sOut+="restricted";
        else if (g_iMinBaseMode==2) sOut+="ask";
        else if (g_iMinBaseMode==3) sOut+="auto";
        if (!g_iMinSafeMode) sOut+=", without safeword";
        else sOut+=", with safeword";
        if (g_iMinPlayMode) sOut+=", playful";
        else sOut+=", not playful";
        if (g_iMinLandMode) sOut+=", landowner trusted.";
        else sOut+=", landowner not trusted.";
    }
    else
    {
        if (!g_iBaseMode) sOut+="off";
        else if (g_iBaseMode==1) sOut+="restricted";
        else if (g_iBaseMode==2) sOut+="ask";
        else if (g_iBaseMode==3) sOut+="auto";
        if (!g_iSafeMode) sOut+=", without safeword";
        else sOut+=", with safeword";
        if (g_iPlayMode) sOut+=", playful";
        else sOut+=", not playful";
        if (g_iLandMode) sOut+=", landowner trusted.";
        else sOut+=", landowner not trusted.";
    }
    return sOut;
}

/*
SaveTrustObj()
{
    if (llGetListLength(g_lTrustObj) > 0)
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvrelay_trustobj=" + llDumpList2String(g_lTrustObj,","), "");
    else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvrelay_trustobj", "");
}

SaveBlockObj()
{
    if (llGetListLength(g_lBlockObj) > 0)
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvrelay_blockobj=" + llDumpList2String(g_lBlockObj,","), "");
    else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvrelay_blockobj", "");
}
*/
SaveTrustAv()
{
    if (llGetListLength(g_lTrustAv) > 0)
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvrelay_trustav=" + llDumpList2String(g_lTrustAv,","), "");
    else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvrelay_trustav", "");
}

SaveBlockAv()
{
    if (llGetListLength(g_lBlockAv) > 0)
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvrelay_blockav="+llDumpList2String(g_lBlockAv,",") , "");
    else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvrelay_blockav", "");
}

UpdateMode(integer iMode)
{
    g_iBaseMode = iMode        & 3;
    g_iSafeMode = (iMode >> 2) & 1;
    g_iLandMode = (iMode >> 3) & 1;
    g_iPlayMode = (iMode >> 4) & 1;
    g_iMinBaseMode = (iMode >> 5) & 3;
    g_iMinSafeMode = (iMode >> 7) & 1;
    g_iMinLandMode = (iMode >> 8) & 1;
    g_iMinPlayMode = (iMode >> 9) & 1;
    g_iSmartStrip  = (iMode >> 10) & 1;
}

SaveMode()
{
    string sMode = (string)(1024 * g_iSmartStrip + 512 * g_iMinPlayMode + 256 * g_iMinLandMode + 128 * g_iMinSafeMode
         + 32 * g_iMinBaseMode + 16 * g_iPlayMode + 8 * g_iLandMode + 4 * g_iSafeMode + g_iBaseMode);
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvrelay_mode=" + sMode, "");
}

integer Auth(key object, key user)
{
    integer iAuth=1;
    key kOwner = llGetOwnerKey(object);
    //object auth
    integer iSourceIndex=llListFindList(g_lSources,[object]);
    if (~iSourceIndex) {}
    else if (~llListFindList(g_lTempBlockObj+g_lBlockObj,[object])) return -1;
    else if (~llListFindList(g_lBlockAv,[(string)kOwner])) return -1;
    else if (~llListFindList(g_lBlock,[(string)kOwner])) return -1;
    else if (g_iBaseMode==3) {}
    else if (g_iLandMode && llGetOwnerKey(object)==llGetLandOwnerAt(llGetPos())) {}
    else if (~llListFindList(g_lTempTrustObj+g_lTrustObj,[object])) {}
    else if (~llListFindList(g_lTrustAv,[(string)kOwner])) {}
    else if (~llListFindList(g_lOwner+g_lTrust+g_lTempOwner,[(string)kOwner])) {}
//    else if (g_iBaseMode==1) return -1; we should not block playful in restricted mode
    else iAuth=0;
    //user auth
    if (user)
    {
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

string Name(key id)
{
    return "secondlife:///app/agent/"+(string)id+"/inspect";
}

Dequeue()
{
    string sCommand;
    string sCurIdent;
    key kCurID;
    while (sCommand=="")
    {
        if (g_lQueue==[])
        {
            llSetTimerEvent(g_iGarbageRate);
            return;
        }
        sCurIdent=llList2String(g_lQueue,0);
        kCurID=(key)llList2String(g_lQueue,1);
        sCommand=HandleCommand(sCurIdent,kCurID,llList2String(g_lQueue,2),FALSE);
        g_lQueue = llDeleteSubList(g_lQueue, 0, QSTRIDES-1);
    }
    g_lQueue=[sCurIdent,kCurID,sCommand]+g_lQueue;
    list lButtons=["Yes","No","Trust Object","Block Object","Trust Owner","Block Owner"];
    string sOwner=Name(llGetOwnerKey(kCurID)) ;
    string sPrompt=llKey2Name(kCurID)+", owned by "+sOwner+" wants to control your viewer.";
    if (llGetSubString(sCommand,0,6)=="!x-who/")
    {
        key kUser = SanitizeKey(llGetSubString(sCommand,7,42));
        lButtons+=["Trust User","Block User"];
        sPrompt+="\n" + Name(kUser) + " is currently using this device.";
    }
    sPrompt+="\n\nDo you want to allow this?";
    g_iAuthPending = TRUE;

    Dialog(g_kWearer, sPrompt, lButtons, [], 0, CMD_WEARER, "AuthMenu");
}


string HandleCommand(string sIdent, key kID, string sCom, integer iAuthed)
{
    list lCommands=llParseString2List(sCom,["|"],[]);
    sCom = llList2String(lCommands, 0);
    integer iGotWho = FALSE; // has the user been specified up to now?
    key kWho;
    integer i;
    for (i=0;i<(lCommands!=[]);++i)
    {
        sCom = llList2String(lCommands,i);
        list lSubArgs = llParseString2List(sCom,["="],[]);
        string sVal = llList2String(lSubArgs,1);
        string sAck = "ok";
        if (sCom == "!release" || sCom == "@clear") llMessageLinked(LINK_RLV,RLV_CMD,"clear",kID);
        else if (sCom == "!version") sAck = "1100";
        else if (sCom == "!implversion") sAck = "OpenCollar Relay 151218.1";
        else if (sCom == "!x-orgversions") sAck = "ORG=0003/who=001";
        else if (llGetSubString(sCom,0,6)=="!x-who/") {kWho = SanitizeKey(llGetSubString(sCom,7,42)); iGotWho=TRUE;}
        else if (llGetSubString(sCom,0,0) == "!") sAck = "ko"; // ko unknown meta-commands
        else if (llGetSubString(sCom,0,0) != "@")
        {
            llOwnerSay("Bad RLV relay command from "+llKey2Name(kID)+". \nCommand: "+sIdent+","+(string)g_kWearer+","+llDumpList2String(lCommands,"|")+"\nFaulty subcommand: "+sCom+"\nPlease report to the maker of this device."); //added this after issue 984
            //if (iIsWho) return llList2String(lCommands,0)+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            //else return llDumpList2String(llList2List(lCommands,i,-1),"|");
            //better try to execute the rest of the command, right?
            sAck=""; //not ko'ing as some old bug in chorazin cages would make them go wrong. Otherwise "ko" looks closer in spirit to the relay spec. (issue 514)
        }//probably an ill-formed command, not answering
        else if ((!llSubStringIndex(sCom,"@version"))||(!llSubStringIndex(sCom,"@get"))||(!llSubStringIndex(sCom,"@findfolder"))) //(IsChannelCmd(sCom))
        {
            if ((integer)sVal) llMessageLinked(LINK_RLV,RLV_CMD, llGetSubString(sCom,1,-1), kID); //now with RLV 1.23, negative channels can also be used
            else sAck="ko";
        }
        else if (g_iPlayMode&&llGetSubString(sCom,0,0)=="@"&&sVal!="n"&&sVal!="add")
            llMessageLinked(LINK_RLV,RLV_CMD, llGetSubString(sCom,1,-1), kID);
        else if (!iAuthed)
        {
            if (iGotWho) return "!x-who/"+(string)kWho+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            else return llDumpList2String(llList2List(lCommands,i,-1),"|");
        }
        else if ((lSubArgs!=[])==2)
        {
            string sBehav=llGetSubString(llList2String(lSubArgs,0),1,-1);
            list lTemp=llParseString2List(sBehav,[":"],[]);
            if (g_iSmartStrip && llList2String(lTemp,0) == "remoutfit" && sVal == "force")
                sBehav = "detachallthis:" + llList2String(lTemp,1);
            if (sVal=="force"||sVal=="n"||sVal=="add"||sVal=="y"||sVal=="rem"||sBehav=="clear")
                llMessageLinked(LINK_RLV,RLV_CMD,sBehav+"="+sVal,kID);
            else sAck="ko";
        }
        else
        {
            llOwnerSay("Bad RLV relay command from "+llKey2Name(kID)+". \nCommand: "+sIdent+","+(string)g_kWearer+","+llDumpList2String(lCommands,"|")+"\nFaulty subcommand: "+sCom+"\nPlease report to the maker of this device."); //added this after issue 984
            //if (iIsWho) return llList2String(lCommands,0)+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            //else return llDumpList2String(llList2List(lCommands,i,-1),"|");
            //better try to execute the rest of the command, right?
            sAck=""; //not ko'ing as some old bug in chorazin cages would make them go wrong. Otherwise "ko" looks closer in spirit to the relay spec. (issue 514)
        }//probably an ill-formed command, not answering
        if (sAck) sendrlvr(sIdent, kID, sCom, sAck);
    }
    return "";
}

sendrlvr(string sIdent, key kID, string sCom, string sAck)
{
    llRegionSayTo(kID, RELAY_CHANNEL, sIdent+","+(string)kID+","+sCom+","+sAck);
    if (g_kDebugRcpt == g_kWearer) llOwnerSay("From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);
    else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt, DEBUG_CHANNEL, "From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);
}

SafeWord()
{
    if (g_iSafeMode)
    {
        llMessageLinked(LINK_RLV, CMD_RELAY_SAFEWORD, "","");
        llOwnerSay("You have safeworded");
        g_lTempBlockObj=[];
        g_lTempTrustObj=[];
        g_lTempBlockUser=[];
        g_lTempTrustUser=[];
        integer i;
        for (i=0;i<(g_lSources!=[]);++i)
        {
            sendrlvr("release", llList2Key(g_lSources, i), "!release", "ok");
        }
        g_lSources=[];
        g_iRecentSafeword = TRUE;
        refreshRlvListener();
        llSetTimerEvent(30.);
    }
    else llOwnerSay("Sorry, safewording is disabled now!");

}

//----Menu functions section---//
Menu(key kID, integer iAuth, string sMode)
{
    string sPrompt = "\n[http://www.opencollar.at/relay-plugin.html Legacy Relay]\t"+g_sAppVersion;
    list lButtons ;
    
    if (sMode == "Main")
    {    
        sPrompt += "\n\nCurrent mode is: " + Mode2String(FALSE);
        lButtons = llDeleteSubList(["Off", "Restricted", "Ask", "Auto"],g_iBaseMode,g_iBaseMode);
        if (g_lSources != []) lButtons = llDeleteSubList(lButtons,0,0);
        if (g_iPlayMode) lButtons+=["☒ Playful"];
        else lButtons+=["☐ Playful"];
        if (g_iLandMode) lButtons+=["☒ Land"];
        else lButtons+=["☐ Land"];
        if (g_iSmartStrip) lButtons+=["☒ SmartStrip"];
        else lButtons+=["☐ SmartStrip"];
        if (g_lSources!=[])
        {
            sPrompt+="\n\nCurrently grabbed by "+(string)(g_lSources!=[])+" object";
            if (g_lSources==[1]) sPrompt+="."; // Note: only list LENGTH is compared here
            else sPrompt+="s.";
            lButtons+=["Grabbed by"];
            if (g_iSafeMode) lButtons+=["Safeword"];
        }
        else if (kID == g_kWearer)
        {
            if (g_iSafeMode) lButtons+=["☒ Safeword"];
            else lButtons+=["☐ Safeword"];
        }
        if (g_lQueue!=[])
        {
            sPrompt+="\n\nYou have pending requests.";
            lButtons+=["Pending"];
        }
        lButtons+=["Access Lists", "MinMode"];
        sPrompt+="\n\nMake a choice:";
    }
    else if (sMode == "MinMode")
    {
        sPrompt += "\n\nCurrent minimal authorized relay mode is: " + Mode2String(TRUE);    
        lButtons = llDeleteSubList(["Off", "Restricted", "Ask", "Auto"],g_iMinBaseMode,g_iMinBaseMode);
    
        if (g_iMinPlayMode) lButtons+=["☒ Playful"];
        else lButtons+=["☐ Playful"];
        if (g_iMinLandMode) lButtons+=["☒ Land"];
        else lButtons+=["☐ Land"];
        if (g_iMinSafeMode) lButtons+=["☒ Safeword"];
        else lButtons+=["☐ Safeword"];
        sPrompt+="\n\nChoose a new minimal mode the wearer won't be allowed to go under.\n(owner only)";
    }
    else return;
    
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~"+sMode);
}

AccessList(key kID, integer iAuth)
{
    list lButtons=[];
    string sPrompt = "\nAccess Lists: ";

    if (llGetListLength(g_lTrustObj) > 0) lButtons+=["Trust Objects"];
    if (llGetListLength(g_lBlockObj) > 0) lButtons+=["Block Objects"];

    if (llGetListLength(g_lTrustAv) > 0) lButtons+=["Trust Avatars"];
    if (llGetListLength(g_lBlockAv) > 0) lButtons+=["Block Avatars"];

    if (lButtons == []) sPrompt += "all empty.";
    else sPrompt += "\n\nWhat list do you want to remove items from?\n\nMake a choice:";

    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Access~List");
}

ListsMenu(key kID, string sMsg, integer iAuth)
{
    list lButtons;
    string sPrompt;
    if (sMsg == "Trust Objects")
    {
        lButtons = llList2ListStrided(llDeleteSubList(g_lTrustObj,0,0), 0, -1, 2);
        sPrompt = "\n\nWhat object do you want to stop trusting?";
    }
    else if (sMsg == "Block Objects")
    {
        lButtons = llList2ListStrided(llDeleteSubList(g_lBlockObj,0,0), 0, -1, 2);
        sPrompt = "\n\nWhat object do you want not to block anymore?";
    }
    else if (sMsg == "Trust Avatars")
    {
        lButtons = g_lTrustAv;
        sPrompt = "\n\nWhat avatar do you want to stop trusting?";
    }
    else if (sMsg == "Block Avatars")
    {
        lButtons = g_lBlockAv;
        sPrompt = "\n\nWhat avatar do you want not to block anymore?";
    }
    else return;

    sPrompt += "\n\nMake a choice:";

    Dialog(kID, sPrompt, [ALL]+lButtons, [UPMENU], -1, iAuth, "Remove~"+sMsg);
}

RemoveList(string sMsg, integer iAuth, string sListType)
{
    integer i;
    if (sListType == "Block Avatars")
    {
        if (sMsg == ALL) g_lBlockAv = [];
        else
        {
            i = llListFindList(g_lBlockAv,[sMsg]);
            if (i!=-1) g_lBlockAv = llDeleteSubList(g_lBlockAv,i,i);
        }
        SaveBlockAv();
    }
    else if (sListType == "Block Objects")
    {
        if (sMsg == ALL) g_lBlockObj = [];
        else
        {
            i = llListFindList(g_lBlockObj,[sMsg]);
            if (i!=-1) g_lBlockObj = llDeleteSubList(g_lBlockObj,i-1,i);
        }
        //SaveBlockObj();
    }
    else if (iAuth==CMD_WEARER && g_iMinBaseMode > 0)
    {
        llOwnerSay("Sorry, your owner does not allow you to remove trusted sources.");
        return;
    }
    else if (sListType == "Trust Objects")
    {
        if (sMsg == ALL) g_lTrustObj = [];
        else
        {
            i = llListFindList(g_lTrustObj,[sMsg]);
            if (i!=-1) g_lTrustObj = llDeleteSubList(g_lTrustObj,i-1,i);
        }
        //SaveTrustObj();
    }
    else if (sListType == "Trust Avatars")
    {
        if (sMsg == ALL) g_lTrustAv = [];
        else
        {
            i = llListFindList(g_lTrustAv,[sMsg]);
            if (i!=-1) g_lTrustAv = llDeleteSubList(g_lTrustAv,i,i);
        }
        SaveTrustAv();
    }
}

refreshRlvListener()
{
    llListenRemove(g_iRlvListener);
    llListenRemove(g_iSafetyListener);
    if (g_iRLV && g_iBaseMode && !g_iRecentSafeword) {
        g_iRlvListener = llListen(RELAY_CHANNEL, "", NULL_KEY, "");
        g_iSafetyListener = llListen(SAFETY_CHANNEL, "","","Safety!");
        llRegionSayTo(g_kWearer,SAFETY_CHANNEL,"SafetyDenied!"); 
    }
}


CleanQueue()
{
    //clean newly iNumed events, while preserving the order of arrival for every device
    list lOnHold=[];
    integer i=0;
    while (i<(g_lQueue!=[])/QSTRIDES)  //GetQLength()
    {
        string sIdent = llList2String(g_lQueue,0); //GetQident(0)
        key kObj = llList2String(g_lQueue,1); //GetQObj(0);
        string sCommand = llList2String(g_lQueue,2); //GetQCom(0);
        key kUser = NULL_KEY;
        integer iGotWho = llGetSubString(sCommand,0,6)=="!x-who/";
        if (iGotWho) kUser=SanitizeKey(llGetSubString(sCommand,7,42));
        integer iAuth=Auth(kObj,kUser);
        if(~llListFindList(lOnHold,[kObj])) ++i;
        else if(iAuth==1 && (kUser!=NULL_KEY || !iGotWho)) // !x-who/NULL_KEY means unknown user
        {
            g_lQueue = llDeleteSubList(g_lQueue,i,i+QSTRIDES-1); //DeleteQItem(i);
            HandleCommand(sIdent,kObj,sCommand,TRUE);
        }
        else if(iAuth==-1)
        {
            g_lQueue = llDeleteSubList(g_lQueue,i,i+QSTRIDES-1); //DeleteQItem(i);
            list lCommands = llParseString2List(sCommand,["|"],[]);
            integer j;
            for (j=0;j<(lCommands!=[]);++j)
                sendrlvr(sIdent,kObj,llList2String(lCommands,j),"ko");
        }
        else
        {
            ++i;
            lOnHold+=[kObj];
        }
    }
    //end of cleaning, now check if there is still events in queue and act accordingly
    Dequeue();
}

UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llToLower(sStr) == "rm relay") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else  Dialog(kID,"\nAre you sure you want to delete the "+g_sSubMenu+" App?\n", ["Yes","No","Cancel"], [], 0, iNum,"rmrelay");
        return;
    }
    if (llSubStringIndex(sStr,"relay") && sStr != "menu "+g_sSubMenu) return;
    if (iNum == CMD_OWNER && sStr == "runaway")
    {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (!g_iRLV)
    {
        llMessageLinked(LINK_DIALOG, NOTIFY, "0RLV features are now disabled in this %DEVICETYPE%. You can enable those in RLV submenu. Opening it now.", kID);
        llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
    }
    else if (sStr=="relay" || sStr == "menu "+g_sSubMenu) Menu(kID, iNum, "Main");
    else if ((sStr=llGetSubString(sStr,6,-1))=="minmode") Menu(kID, iNum, "MinMode");
    else if (iNum!=CMD_OWNER&&kID!=g_kWearer) llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%",kID);
    else if (sStr=="safeword") SafeWord();
    else if (sStr=="getdebug")
    {
        g_kDebugRcpt = kID;
        llMessageLinked(LINK_DIALOG, NOTIFY, "1Relay messages will be forwarded to "+Name(kID)+".", kID);
        return;
    }
    else if (sStr=="stopdebug")
    {
        g_kDebugRcpt = NULL_KEY;
        llMessageLinked(LINK_DIALOG, NOTIFY, "1Relay messages will not forwarded anymore.", kID);
        return;
    }
    else if (sStr=="pending")
    {
        if (g_lQueue != []) Dequeue();
        else llOwnerSay("No pending relay request for now.");
    }
    else if (sStr=="access") AccessList(kID, iNum);
    else if (sStr=="smartstrip on")
    {
        g_iSmartStrip = TRUE;
        SaveMode();
    }
    else if (sStr=="smartstrip off") 
    {
        g_iSmartStrip = FALSE;
        SaveMode();
    }
    else if (iNum == CMD_OWNER && !llSubStringIndex(sStr,"minmode"))
    {
        sStr=llGetSubString(sStr,8,-1);
        integer iOSuccess = 0;
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        if (sChangetype=="safeword")
        {
            if (sChangevalue == "on") g_iMinSafeMode = TRUE;
            else if (sChangevalue == "off")
            {
                g_iMinSafeMode = FALSE;
                g_iSafeMode = FALSE;
            }
            else iOSuccess = 3;
        }
        else if (sChangetype=="land")
        {
            if (sChangevalue == "off") g_iMinLandMode = FALSE;
            else if (sChangevalue == "on")
            {
                g_iMinLandMode = TRUE;
                g_iLandMode = TRUE;
            }
            else iOSuccess = 3;
        }
        else if (sChangetype=="playful")
        {
            if (sChangevalue == "off") g_iMinPlayMode = FALSE;
            else if (sChangevalue == "on")
            {
                g_iMinPlayMode = TRUE;
                g_iPlayMode = TRUE;
            }
            else iOSuccess = 3;
        }
        else
        {
            integer modetype = llListFindList(["off", "restricted", "ask", "auto"], [sChangetype]);
            if (~modetype)
            {
                g_iMinBaseMode = modetype;
                if (modetype > g_iBaseMode) g_iBaseMode = modetype;
            }
            else  iOSuccess = 3;
        }
        if (!iOSuccess)
        {
            llMessageLinked(LINK_DIALOG, NOTIFY, "1%WEARERNAME%'s relay minimal authorized mode is successfully set to: "+Mode2String(TRUE), kID);
            SaveMode();
            refreshRlvListener();
        }
        else llMessageLinked(LINK_DIALOG, NOTIFY,"0Unknown relay mode.", kID);

    }
    else
    {
        integer iWSuccess = 0; //0: successful, 1: forbidden because of minmode, 2: forbidden because grabbed, 3: unrecognized commad
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        if (sChangetype=="safeword")
        {
            if (sChangevalue == "on")
            {
                if (g_iMinSafeMode == FALSE) iWSuccess = 1;
                else if (g_lSources!=[]) iWSuccess = 2;
                else g_iSafeMode = TRUE;
            }
            else if (sChangevalue == "off") g_iSafeMode = FALSE;
            else iWSuccess = 3;
        }
        else if (sChangetype=="land")
        {
            if (sChangevalue == "off")
            {
                if (g_iMinLandMode == TRUE) iWSuccess = 1;
                else g_iLandMode = FALSE;
            }
            else if (sChangevalue == "on") g_iLandMode = TRUE;
            else iWSuccess = 3;
        }
        else if (sChangetype=="playful")
        {
            if (sChangevalue == "off")
            {
                if (g_iMinPlayMode == TRUE) iWSuccess = 1;
                else g_iPlayMode = FALSE;
            }
            else if (sChangevalue == "on") g_iPlayMode = TRUE;
            else iWSuccess = 3;
        }
        else
        {
            integer modetype = llListFindList(["off", "restricted", "ask", "auto"], [sChangetype]);
            if (~modetype)
            {
                if (modetype >= g_iMinBaseMode) g_iBaseMode = modetype;
                else iWSuccess = 1;
            }
            else iWSuccess = 3;
        }
        if (!iWSuccess) llMessageLinked(LINK_DIALOG, NOTIFY, "1Your relay mode is successfully set to: "+Mode2String(FALSE), kID);

        else if (iWSuccess == 1)  llMessageLinked(LINK_DIALOG, NOTIFY, "1Minimal mode previously set by owner does not allow this setting. Change it or have it changed first.", kID);
        else if (iWSuccess == 2)  llMessageLinked(LINK_DIALOG, NOTIFY, "1Your relay is being locked by at least one object, you cannot disable it or enable safewording now.", kID);
        else if (iWSuccess == 3)  llMessageLinked(LINK_DIALOG, NOTIFY, "0Invalid command, please read the manual.", kID);
        SaveMode();
        refreshRlvListener();
    }
}

default {
    on_rez(integer iNum) {
        if (llGetOwner() != g_kWearer) llResetScript();
    }

    state_entry() {

        g_kWearer = llGetOwner();
        g_lSources=[];
        llSetTimerEvent(g_iGarbageRate); //start garbage collection timer
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID )
    {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum==CMD_ADDSRC)
        {
            g_lSources+=[kID];
        }
        else if (iNum==CMD_REMSRC)
        {
            integer i= llListFindList(g_lSources,[kID]);
            if (~i) g_lSources=llDeleteSubList(g_lSources,i,i);
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "rlvrelay_mode") UpdateMode((integer)sValue);
            else if (sToken=="rlvrelay_trustav") g_lTrustAv = llParseString2List(sValue, [","], []);
            else if (sToken=="rlvrelay_blockav") g_lBlockAv = llParseString2List(sValue, [","], []);
           // else if (sToken=="rlvrelay_trustobj") g_lTrustObj = llParseString2List(sValue, [","], []);
           // else if (sToken=="rlvrelay_blockobj") g_lBlockObj = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_owner") g_lOwner = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_tempowner") g_lTempOwner = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_trust") g_lTrust = llParseString2List(sValue, [","], []);
            else if (sToken == "auth_block") g_lBlock = llParseString2List(sValue, [","], []);
        }
        else if (iNum == RLV_OFF)
        {
            g_iRLV=FALSE;
            refreshRlvListener();
        }
        else if (iNum == RLV_ON)
        {
            g_iRLV=TRUE;
            refreshRlvListener();
        }
        else if (iNum==RLV_REFRESH)
        {
            g_iRLV=TRUE;
            refreshRlvListener();
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex)
            {
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);

                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = llList2Key(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = llList2Integer(lMenuParams, 2);
                integer iAuth = llList2Integer(lMenuParams, 3);

                llSetTimerEvent(g_iGarbageRate);
                    
                if (llSubStringIndex(sMenu,"Menu~")==0)
                {
                    string sMenuType=llList2String(llParseString2List(sMenu,["~"],[]),1);

                    if (sMsg==UPMENU)
                    {
                        if (sMenuType=="Main") llMessageLinked(LINK_SET,iAuth,"menu "+g_sParentMenu,kAv);
                        else Menu(kAv, iAuth, "Main");
                    }
                    else if (sMsg=="Pending") UserCommand(iAuth, "relay pending", kAv);
                    else if (sMsg=="Access Lists") UserCommand(iAuth, "relay access", kAv);
                    else if (sMsg=="MinMode") Menu(kAv, iAuth, "MinMode");
                    else if (sMsg=="Grabbed by")
                    {
                        llMessageLinked(LINK_RLV, iAuth,"show restrictions", kAv);
                        Menu(kAv, iAuth, "Main");
                    }
                    else
                    {
                        sMsg = llToLower(sMsg);
                        if (llSubStringIndex(sMsg,"☐ ")==0) sMsg = llDeleteSubString(sMsg,0,1) + " on";
                        if (llSubStringIndex(sMsg,"☒ ")==0) sMsg = llDeleteSubString(sMsg,0,1) + " off";
                        if (sMenuType == "MinMode") sMsg = "relay minmode " + sMsg;
                        else sMsg = "relay " + sMsg;
                        UserCommand(iAuth, sMsg, kAv);
                        Menu(kAv, iAuth, sMenuType);
                    }                    
                }
                else if (sMenu=="Access~List")
                {
                    if (sMsg==UPMENU) Menu(kAv, iAuth, "Main");
                    else ListsMenu(kAv,sMsg, iAuth);
                }
                else if (llSubStringIndex(sMenu,"Remove~")==0)
                {
                    if (sMsg==UPMENU) AccessList(kAv, iAuth);
                    else
                    {
                        string sMenuType=llList2String(llParseString2List(sMenu,["~"],[]),1);
                        RemoveList(sMsg, iAuth, sMenuType);
                        AccessList(kAv, iAuth);
                    }
                }
                else if (sMenu=="AuthMenu")
                {
                    g_iAuthPending = FALSE;
                    key kCurID=llList2String(g_lQueue,1); //GetQObj(0);
                    string sCom = llList2String(g_lQueue,2);  //GetQCom(0));
                    key kUser = NULL_KEY;
                    key kOwner = llGetOwnerKey(kCurID);
                    if (llGetSubString(sCom,0,6)=="!x-who/") kUser = SanitizeKey(llGetSubString(sCom,7,42));
                    if (sMsg=="Yes")
                    {
                        g_lTempTrustObj+=[kCurID];
                        if (kUser) g_lTempTrustUser+=[(string)kUser];
                    }
                    else if (sMsg=="No")
                    {
                        g_lTempBlockObj+=[kCurID];
                        if (kUser) g_lTempBlockUser+=[(string)kUser];
                    }
                    else if (sMsg=="Trust Object")
                    {
                        if (!~llListFindList(g_lTrustObj, [kCurID]))
                        {
                            g_lTrustObj+=[kCurID,llKey2Name(kCurID)];
                            //SaveTrustObj();
                        }
                    }
                    else if (sMsg=="Block Object")
                    {
                        if (!~llListFindList(g_lBlockObj, [kCurID]))
                        {
                            g_lBlockObj+=[kCurID,llKey2Name(kCurID)];
                            //SaveBlockObj();
                        }
                    }
                    else if (sMsg=="Trust Owner")
                    {
                        if (!~llListFindList(g_lTrustAv, [(string)kOwner]))
                        {
                            g_lTrustAv+=[(string)kOwner];
                            SaveTrustAv();
                        }
                    }
                    else if (sMsg=="Block Owner")
                    {
                        if (!~llListFindList(g_lBlockAv, [(string)kOwner]))
                        {
                            g_lBlockAv+=[(string)kOwner];
                            SaveBlockAv();
                        }
                    }
                    else if (sMsg=="Trust User")
                    {
                        if (!~llListFindList(g_lTrustAv, [(string)kUser]))
                        {
                            g_lTrustAv+=[(string)kUser];
                            SaveTrustAv();
                        }
                    }
                    else if (sMsg=="Block User")
                    {
                        if (!~llListFindList(g_lBlockAv, [(string)kUser]))
                        {
                            g_lBlockAv+=[(string)kUser];
                            SaveBlockAv();
                        }
                    }
                    CleanQueue();
                } else if (sMenu == "rmrelay") {
                    if (sMsg == "Yes") {
                        integer i;
                        for (i=0;i<(g_lSources!=[]);++i)
                            sendrlvr("release", llList2Key(g_lSources, i), "!release", "ok");
                        UserCommand(500, "relay off", kAv);
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex)
            {
                if (llList2String(g_lMenuIDs, iMenuIndex+1) == "AuthMenu")
                {
                    g_iAuthPending = FALSE;
                    llOwnerSay("Relay authorization dialog expired. You can make it appear again with command \"<prefix>relay pending\".");
                }
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    listen(integer iChan, string who, key kID, string sMsg)
    {
        if (iChan == SAFETY_CHANNEL) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0\n\n⚠ "+who+" detected ⚠\n\nTo prevent conflicts this relay is being detached now! If you wish to use "+who+" anyway, type \"/%CHANNEL% %PREFIX% relay off\" to temporarily disable or type \"/%CHANNEL% %PREFIX% rm relay\" to permanently uninstall the internal OpenCollar relay plugin.\n",g_kWearer);
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
        list lArgs=llParseString2List(sMsg,[","],[]);
        sMsg = "";  // free up memory in case of large messages
        if ((lArgs!=[])!=3) return;
        if (llList2Key(lArgs,1)!=g_kWearer && llList2String(lArgs,1)!="ffffffff-ffff-ffff-ffff-ffffffffffff") return; // allow FFF...F wildcard
        string sIdent=llList2String(lArgs,0);
        sMsg=llToLower(llList2String(lArgs,2));
        if (g_kDebugRcpt == g_kWearer) llOwnerSay("To relay: "+sIdent+","+sMsg);
        else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt, DEBUG_CHANNEL, "To relay: "+sIdent+","+sMsg);
        if (sMsg == "!pong")
        {//sloppy matching; the protocol document is stricter, but some in-world devices do not respect it
            llMessageLinked(LINK_SET, CMD_RLV_RELAY, "ping,"+(string)g_kWearer+",!pong", kID);
            return;
        }
        lArgs = [];  // free up memory in case of large messages

        key kUser = NULL_KEY;
        if (llGetSubString(sMsg,0,6)=="!x-who/") kUser=SanitizeKey(llGetSubString(sMsg,7,42));
        integer iAuth=Auth(kID,kUser);
        if (iAuth==-1) return;
        else if (iAuth==1) {HandleCommand(sIdent,kID,sMsg,TRUE); llSetTimerEvent(g_iGarbageRate);}
        else if (g_iBaseMode == 2)
        {
//            llOwnerSay("Free memory before queueing: "+(string)(llGetMemoryLimit() - llGetUsedMemory()));
//            if (llGetMemoryLimit() - llGetUsedMemory()> 5000) //keeps margin for this event + next arriving chat message
//            {
            g_lQueue += [sIdent, kID, sMsg];
            sMsg = ""; sIdent="";
//            llOwnerSay("Used memory after queueing: "+(string)(llGetMemoryLimit() -llGetUsedMemory()));
//            }
//            else
            if (llGetMemoryLimit() - llGetUsedMemory()< 3927) //keeps margin for this event + next arriving chat message
            {
                sMsg = ""; sIdent="";
                key kOldestId = llList2Key(g_lQueue, 1);  // It's actually more likely we want to drop the old request we completely forgot about rather than the newest one that will be forgotten because of some obscure memory limit.
//                key kOldUser = NULL_KEY;
//                if (llGetSubString(sMsg,0,6)=="!x-who/") kOldUser=SanitizeKey(llGetSubString(llList2String(g_lQueue, 2),7,42));
                llOwnerSay("Relay queue saturated. Dropping all requests from oldest source ("+ llKey2Name(kOldestId) +").");
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
        }
        else if (g_iPlayMode) {HandleCommand(sIdent,kID,sMsg,FALSE); llSetTimerEvent(g_iGarbageRate);}
    }

    timer()
    {
        if (g_iRecentSafeword)
        {
            g_iRecentSafeword = FALSE;
            refreshRlvListener();
        }
        //garbage collection
        vector vMyPos = llGetRootPosition();
        integer i;
        for (i=0;i<(g_lSources!=[]);++i)
        {
            key kID = llList2Key(g_lSources,i);
            vector vObjPos = llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]),0);
            if (vObjPos == <0, 0, 0> || llVecDist(vObjPos, vMyPos) > 100) // 100: max shout distance
                llMessageLinked(LINK_RLV,RLV_CMD,"clear",kID);
        }
        llSetTimerEvent(g_iGarbageRate);
        g_lTempBlockObj=[];
        g_lTempTrustObj=[];
        if (g_lSources == [])
        { //dont clear already authorized users before done with current session
            g_lTempBlockUser=[];
            g_lTempTrustUser=[];
        }
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
