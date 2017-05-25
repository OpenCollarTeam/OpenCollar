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
//                          Authorizer - 170523.1                           //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2017 Nandana Singh, Garvin Twine, Cleo Collins,    //
//  Satomi Ahn, Master Starship, Sei Lisa, Joy Stipe, Wendy Starfall,       //
//  Medea Destiny, littlemousy, Romka Swallowtail, Sumi Perl et al.         //
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


string g_sWearerID;
list g_lOwner;
list g_lTrust;
list g_lBlock;//list of blacklisted UUID
list g_lTempOwner;//list of temp owners UUID.  Temp owner is just like normal owner, but can't add new owners.

key g_kGroup = "";
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "Access";
integer g_iRunawayDisable=0;

string g_sDrop = "f364b699-fb35-1640-d40b-ba59bdd5f7b7";

list g_lQueryId; //5 strided list of dataserver/http request: key, uuid, requestType, kAv, remenu.  For AV name/group name  lookups
integer g_iQueryStride=5;

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_BLOCKED = 520;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
integer LOADPIN = -1904;
integer REBOOT              = -1000;
integer LINK_DIALOG         = 3;
integer LINK_RLV            = 4;
integer LINK_SAVE           = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;
//integer FIND_AGENT = -9005;

//added for attachment auth (garvin)
integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;
string UPMENU = "BACK";

integer g_iOpenAccess; // 0: disabled, 1: openaccess
integer g_iLimitRange=1; // 0: disabled, 1: limited
integer g_iVanilla; // self-owned wearers
string g_sFlavor = "Vanilla";

list g_lMenuIDs;
integer g_iMenuStride = 3;

//key REQUEST_KEY;
integer g_iFirstRun;

string g_sSettingToken = "auth_";
//string g_sGlobalToken = "global_";

/*integer g_iProfiled=1;
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

string NameURI(string sID){
    return "secondlife:///app/agent/"+sID+"/about";
}

Dialog(string sID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName, integer iSensor) {
    key kMenuID = llGenerateKey();
    if (iSensor)
        llMessageLinked(LINK_DIALOG, SENSORDIALOG, sID +"|"+sPrompt+"|0|``"+(string)AGENT+"`10`"+(string)PI+"`"+llList2String(lChoices,0)+"|"+llDumpList2String(lUtilityButtons, "`")+"|" + (string)iAuth, kMenuID);
    else
        llMessageLinked(LINK_DIALOG, DIALOG, sID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [sID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [sID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [sID, kMenuID, sName];
    }
}

AuthMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[http://www.opencollar.at/access.html Access & Authorization]";
    list lButtons = ["+ Owner", "+ Trust", "+ Block", "− Owner", "− Trust", "− Block"];

    if (g_kGroup=="") lButtons += ["Group ☐"];    //set group
    else lButtons += ["Group ☑"];    //unset group
    if (g_iOpenAccess) lButtons += ["Public ☑"];    //set open access
    else lButtons += ["Public ☐"];    //unset open access
    if (g_iVanilla) lButtons += g_sFlavor+" ☑";    //add wearer as owner
    else lButtons += g_sFlavor+" ☐";    //remove wearer as owner

    lButtons += ["Runaway","Access List"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Auth",FALSE);
}

RemPersonMenu(key kID, string sToken, integer iAuth) {
    list lPeople;
    if (sToken=="owner") lPeople=g_lOwner;
    else if (sToken=="tempowner") lPeople=g_lTempOwner;
    else if (sToken=="trust") lPeople=g_lTrust;
    else if (sToken=="block") lPeople=g_lBlock;
    else return;
    if (llGetListLength(lPeople)){
        string sPrompt = "\nChoose the person to remove:\n";
        list lButtons;
        integer iNum= llGetListLength(lPeople);
        integer n;
        for(;n<iNum;n=n+1) {
            string sName = llList2String(lPeople,n);
            if (sName) lButtons += [sName];
        }
        Dialog(kID, sPrompt, lButtons, ["Remove All",UPMENU], -1, iAuth, "remove"+sToken, FALSE);
    } else {
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The list is empty",kID);
        AuthMenu(kID, iAuth);
    }
}

VanillaOff(key kID) {
    g_iVanilla = FALSE;
    if (kID == g_sWearerID)
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nYou no longer own yourself.\n",kID);
    else
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% does no longer own themselves.\n",kID);
}

RemovePerson(string sPersonID, string sToken, key kCmdr, integer iPromoted) {
    list lPeople;
    if (sToken=="owner") lPeople=g_lOwner;
    else if (sToken=="tempowner") lPeople=g_lTempOwner;
    else if (sToken=="trust") lPeople=g_lTrust;
    else if (sToken=="block") lPeople=g_lBlock;
    else return;
// ~ is bitwise NOT which is used for the llListFindList function to simply turn the result "-1" for "not found" into a 0 (FALSE)
    if (~llListFindList(g_lTempOwner,[(string)kCmdr]) && ! ~llListFindList(g_lOwner,[(string)kCmdr]) && sToken != "tempowner"){
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kCmdr);
        return;
    }
    integer iFound;
    if (llGetListLength(lPeople) == 0) {//nothing to do
    } else {
        integer index = llListFindList(lPeople,[sPersonID]);
        if (~index) {
            if (sToken == "owner" && sPersonID == g_sWearerID) VanillaOff(kCmdr);
            lPeople = llDeleteSubList(lPeople,index,index);
            if (!iPromoted) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(sPersonID)+" removed from " + sToken + " list.",kCmdr);
            iFound = TRUE;
        } else if (llToLower(sPersonID) == "remove all") {
            if (sToken == "owner" && ~llListFindList(lPeople,[g_sWearerID])) VanillaOff(kCmdr);
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+sToken+" list cleared.",kCmdr);
            lPeople = [];
            iFound = TRUE;
        }
    }
    if (iFound){
        if (llGetListLength(lPeople)>0)
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        else
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + sToken, "");
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        //store temp list*/
        if (sToken=="owner") {
            g_lOwner = lPeople;
            if (llGetListLength(g_lOwner)) SayOwners();
        }
        else if (sToken=="tempowner") g_lTempOwner = lPeople;
        else if (sToken=="trust") g_lTrust = lPeople;
        else if (sToken=="block") g_lBlock = lPeople;
    } else
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\""+NameURI(sPersonID) + "\" is not in "+sToken+" list.",kCmdr);
}

AddUniquePerson(string sPersonID, string sToken, key kID) {
    list lPeople;
    //Debug(llKey2Name(kAv)+" is adding "+llKey2Name(kPerson)+" to list "+sToken);
    if (~llListFindList(g_lTempOwner,[(string)kID]) && ! ~llListFindList(g_lOwner,[(string)kID]) && sToken != "tempowner")
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    else {
        if (sToken=="owner") {
            lPeople=g_lOwner;
            if (llGetListLength (lPeople) >=3) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\nThree people at a time can have this role.\n",kID);
                return;
            }
        } else if (sToken=="trust") {
            lPeople=g_lTrust;
            if (llGetListLength (lPeople) >=15) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\n15 people at a time can have this role.\n",kID);
                return;
            } else if (~llListFindList(g_lOwner,[sPersonID])) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" is already Owner! You should really trust them.\n",kID);
                return;
            } else if (sPersonID==g_sWearerID) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" doesn't belong on this list as the wearer of the %DEVICETYPE%. Instead try: /%CHANNEL% %PREFIX% vanilla on\n",kID);
                return;
            }
        } else if (sToken=="tempowner") {
            lPeople=g_lTempOwner;
            if (llGetListLength (lPeople) >=1) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSorry!\n\nYou can only be captured by one person at a time.\n",kID);
                return;
            }
        } else if (sToken=="block") {
            lPeople=g_lBlock;
            if (llGetListLength (lPeople) >=9) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\nYour Blocklist is already full.\n",kID);
                return;
            } else if (~llListFindList(g_lTrust,[sPersonID])) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\nYou trust "+NameURI(sPersonID)+". If you really want to block "+NameURI(sPersonID)+" then you should remove them as trusted first.\n",kID);
                return;
            } else if (~llListFindList(g_lOwner,[sPersonID])) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" is Owner! Remove them as owner before you block them.\n",kID);
                return;
            }
        } else return;
        if (! ~llListFindList(lPeople, [sPersonID])) { //owner is not already in list.  add him/her
            lPeople += sPersonID;
            if (sPersonID == g_sWearerID && sToken == "owner") g_iVanilla = TRUE;
        } else {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(sPersonID)+" is already registered as "+sToken+".",kID);
            return;
        }
        if (sPersonID != g_sWearerID) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Building relationship...",g_sWearerID);
        if (sToken == "owner") {
            if (~llListFindList(g_lTrust,[sPersonID])) RemovePerson(sPersonID, "trust", kID, TRUE);
            if (~llListFindList(g_lBlock,[sPersonID])) RemovePerson(sPersonID, "block", kID, TRUE);
            llPlaySound(g_sDrop,1.0);
        } else if (sToken == "trust") {
            if (~llListFindList(g_lBlock,[sPersonID])) RemovePerson(sPersonID, "block", kID, TRUE);
            if (sPersonID != g_sWearerID) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Looks like "+NameURI(sPersonID)+" is someone you can trust!",g_sWearerID);
            llPlaySound(g_sDrop,1.0);
        }
        if (sToken == "owner") {
            if (sPersonID == g_sWearerID) {
                if (kID == g_sWearerID)
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nCongratulations, you own yourself now.\n",g_sWearerID);
                else
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% is their own Owner now.\n",kID);
            } else
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% belongs to you now.\n\nSee [http://www.opencollar.at/congratulations.html here] what that means!\n",sPersonID);
        }
        if (sToken == "trust")
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% seems to trust you.\n\nSee [http://www.opencollar.at/congratulations.html here] what that means!\n",sPersonID);
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        if (sToken=="owner") {
            g_lOwner = lPeople;
            if (llGetListLength(g_lOwner)>1 || sPersonID != g_sWearerID) SayOwners();
        }
        else if (sToken=="trust") g_lTrust = lPeople;
        else if (sToken=="tempowner") g_lTempOwner = lPeople;
        else if (sToken=="block") g_lBlock = lPeople;
    }
}

SayOwners() {  // Give a "you are owned by" message, nicely formatted.
    integer iCount = llGetListLength(g_lOwner);
    if (iCount) {
        list lTemp = g_lOwner;
        integer index = llListFindList(lTemp, [g_sWearerID]);
        //if wearer is also owner, move the key to the end of the list.
        if (~index) lTemp = llDeleteSubList(lTemp,index,index) + [g_sWearerID];
        string sMsg = "You belong to ";
        if (iCount == 1) {
            if (llList2Key(lTemp,0)==g_sWearerID)
                sMsg += "yourself.";
            else
                sMsg += NameURI(llList2String(lTemp,0))+".";
        } else if (iCount == 2) {
            sMsg +=  NameURI(llList2String(lTemp,0))+" and ";
            if (llList2String(lTemp,1)==g_sWearerID)
                sMsg += "yourself.";
            else
                sMsg += NameURI(llList2Key(lTemp,1))+".";
        } else {
            index=0;
            do {
                sMsg += NameURI(llList2String(lTemp,index))+", ";
                index+=1;
            } while (index<iCount-1);
            if (llList2String(lTemp,index) == g_sWearerID)
                sMsg += "and yourself.";
            else
                sMsg += "and "+NameURI(llList2String(lTemp,index))+".";
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMsg,g_sWearerID);
 //       Debug("Lists Loaded!");
    }
}

integer in_range(key kID) {
    if (g_iLimitRange) {
        if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) > 20) //if the distance between my position and their position  > 20
            return FALSE;
    }
    return TRUE;
}

integer Auth(string sObjID, integer iAttachment) {
    string sID = (string)llGetOwnerKey(sObjID); // if sObjID is an avatar key, then sID is the same key
    integer iNum;
    if (~llListFindList(g_lOwner+g_lTempOwner, [sID]))
        iNum = CMD_OWNER;
    else if (llGetListLength(g_lOwner+g_lTempOwner) == 0 && sID == g_sWearerID)
        //if no owners set, then wearer's cmds have owner auth
        iNum = CMD_OWNER;
    else if (~llListFindList(g_lBlock, [sID]))
        iNum = CMD_BLOCKED;
    else if (~llListFindList(g_lTrust, [sID]))
        iNum = CMD_TRUSTED;
    else if (sID == g_sWearerID)
        iNum = CMD_WEARER;
    else if (g_iOpenAccess)
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    else if (g_iGroupEnabled && (string)llGetObjectDetails((key)sObjID, [OBJECT_GROUP]) == (string)g_kGroup && (key)sID != g_sWearerID)  //meaning that the command came from an object set to our control group, and is not owned by the wearer
        iNum = CMD_GROUP;
    else if (llSameGroup(sID) && g_iGroupEnabled && sID != g_sWearerID) {
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    } else
        iNum = CMD_EVERYONE;
    //Debug("Authed as "+(string)iNum);
    return iNum;
}

FailSafe(integer iSec) {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000) 
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000) 
    || sName != "oc_auth" || iSec)
        llRemoveInventory(sName);
}

UserCommand(integer iNum, string sStr, key kID, integer iRemenu) { // here iNum: auth value, sStr: user command, kID: avatar id
   // Debug ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    string sMessage = llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    if (sStr == "menu "+g_sSubMenu) AuthMenu(kID, iNum);
    else if (sStr == "list") {   //say owner, secowners, group
        if (iNum == CMD_OWNER || kID == g_sWearerID) {
            //Do Owners list
            integer iLength = llGetListLength(g_lOwner);
            string sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lOwner, --iLength));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Owners: "+sOutput,kID);
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Owners: none",kID);
            iLength = llGetListLength(g_lTempOwner);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lTempOwner, --iLength));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Temporary Owner: "+sOutput,kID);
            iLength = llGetListLength(g_lTrust);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lTrust, --iLength));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Trusted: "+sOutput,kID);
            iLength = llGetListLength(g_lBlock);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lBlock, --iLength));
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Blocked: "+sOutput,kID);
            //if (g_sGroupName) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group: "+g_sGroupName,kID);
            if (g_kGroup) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group: secondlife:///app/group/"+(string)g_kGroup+"/about",kID);
            sOutput="closed";
            if (g_iOpenAccess) sOutput="open";
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Public Access: "+ sOutput,kID);
        }
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, iNum);
    } else if (sCommand == "vanilla" || sCommand == llToLower(g_sFlavor)) {
        if (iNum == CMD_OWNER && !~llListFindList(g_lTempOwner,[(string)kID])) {
            if (sAction == "on") {
                //g_iVanilla = TRUE;
                UserCommand(iNum, "add owner " + g_sWearerID, kID, FALSE);
            } else if (sAction == "off") {
                g_iVanilla = FALSE;
                UserCommand(iNum, "rm owner " + g_sWearerID, kID, FALSE);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%", kID);
         if (iRemenu) AuthMenu(kID, iNum);
    } else if (sMessage == "owners" || sMessage == "access") {   //give owner menu
        AuthMenu(kID, iNum);
    } else if (sCommand == "owner" && iRemenu==FALSE) { //request for access menu from chat
        AuthMenu(kID, iNum);
    } else if (sCommand == "add") { //add a person to a list
        if (!~llListFindList(["owner","trust","block"],[sAction])) return; //not a valid command
        string sTmpID = llList2String(lParams,2); //get full name
        if (iNum!=CMD_OWNER && !( sAction == "trust" && kID==g_sWearerID )) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if ((key)sTmpID){
            AddUniquePerson(sTmpID, sAction, kID);
            if (iRemenu) Dialog(kID, "\nChoose who to add to the "+sAction+" list:\n",[sTmpID],[UPMENU],0,Auth(kID,FALSE),"AddAvi"+sAction, TRUE);
        } else
            Dialog(kID, "\nChoose who to add to the "+sAction+" list:\n",[sTmpID],[UPMENU],0,iNum,"AddAvi"+sAction, TRUE);
    } else if (sCommand == "remove" || sCommand == "rm") { //remove person from a list
        if (!~llListFindList(["owner","trust","block"],[sAction])) return; //not a valid command
        string sTmpID = llDumpList2String(llDeleteSubList(lParams,0,1), " "); //get full name
        if (iNum != CMD_OWNER && !( sAction == "trust" && kID == g_sWearerID )) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if ((key)sTmpID) {
            RemovePerson(sTmpID, sAction, kID, FALSE);
            if (iRemenu) RemPersonMenu(kID, sAction, Auth(kID,FALSE));
        } else if (llToLower(sTmpID) == "remove all") {
            RemovePerson(sTmpID, sAction, kID, FALSE);
            if (iRemenu) RemPersonMenu(kID, sAction, Auth(kID,FALSE));
        } else RemPersonMenu(kID, sAction, iNum);
     } else if (sCommand == "group") {
         if (iNum==CMD_OWNER){
             if (sAction == "on") {
                //if key provided use that, else read current group
                if ((key)(llList2String(lParams, -1))) g_kGroup = (key)llList2String(lParams, -1);
                else g_kGroup = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0); //record current group key
    
                if (g_kGroup != "") {
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "group=" + (string)g_kGroup, "");
                    g_iGroupEnabled = TRUE;
                    llMessageLinked(LINK_RLV, RLV_CMD, "setgroup=n", "auth");
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Group set to secondlife:///app/group/" + (string)g_kGroup + "/about\n\nNOTE: If RLV is enabled, the group slot has been locked and group mode has to be disabled before %WEARERNAME% can switch to another group again.\n",kID);
                }
            } else if (sAction == "off") {
                g_kGroup = "";
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "group", "");
                g_iGroupEnabled = FALSE;
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Group unset.",kID);
                llMessageLinked(LINK_RLV, RLV_CMD, "setgroup=y", "auth");
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "public") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                g_iOpenAccess = TRUE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "public=" + (string) g_iOpenAccess, "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The %DEVICETYPE% is open to the public.",kID);
            } else if (sAction == "off") {
                g_iOpenAccess = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "public", "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The %DEVICETYPE% is closed to the public.",kID);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "limitrange") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                g_iLimitRange = TRUE;
                // as the default is range limit on, we do not need to store anything for this
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "limitrange", "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Public access range is limited.",kID);
            } else if (sAction == "off") {
                g_iLimitRange = FALSE;
                // save off state for limited range (default is on)
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "limitrange=" + (string) g_iLimitRange, "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Public access range is simwide.",kID);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sMessage == "runaway"){
       // list lButtons=[];
      // string message;//="\nOnly the wearer or an Owner can access this menu";
        if (kID == g_sWearerID){  //wearer called for menu
            if (g_iRunawayDisable)
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            else {
                Dialog(kID, "\nDo you really want to run away from all owners?", ["Yes", "No"], [UPMENU], 0, iNum, "runawayMenu",FALSE);
                return;
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"This feature is only for the wearer of the %DEVICETYPE%.",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "flavor") {
        if (kID != g_sWearerID) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else if (sAction) {
            g_sFlavor = llGetSubString(sStr,7,15);
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nYour new flavor is \""+g_sFlavor+"\".\n",kID);
            llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sSettingToken+"flavor="+g_sFlavor,"");
        } else 
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nYour current flavor is \""+g_sFlavor+"\".\n\nTo set a new flavor type \"/%CHANNEL% %PREFIX% flavor MyFlavor\". Flavors must be single names and can only be a maximum of 9 characters.\n",kID);
    }
}

RunAway() {
    llMessageLinked(LINK_DIALOG,NOTIFY_OWNERS,"%WEARERNAME% ran away!","");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + "owner=", "");
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "owner", "");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + "tempowner=", "");    
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "tempowner", "");
    // moved reset request from settings to here to allow noticifation of owners.
    llMessageLinked(LINK_ALL_OTHERS, CMD_OWNER, "clear", g_sWearerID);
    llMessageLinked(LINK_ALL_OTHERS, CMD_OWNER, "runaway", g_sWearerID); // this is not a LM loop, since it is now really authed
    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway finished.",g_sWearerID);
    llResetScript();
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        else g_iFirstRun = TRUE;
        FailSafe(0);
      /*  if (g_iProfiled){
            llScriptProfiler(1);
           // Debug("profiling restarted");
        }*/
        //llSetMemoryLimit(65536);
        g_sWearerID = llGetOwner();
        llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_REQUEST","");
        //Debug("Auth starting: "+(string)llGetFreeMemory());
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_ZERO) { //authenticate messages on CMD_ZERO
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
            llSetTimerEvent(0.22);
            integer iAuth = Auth(kID, FALSE);
            if ( kID == g_sWearerID && sStr == "runaway") {   // note that this will work *even* if the wearer is blacklisted or locked out
                if (g_iRunawayDisable)
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway is currently disabled.",g_sWearerID);
                else
                    UserCommand(iAuth,"runaway",kID, FALSE);
            } else if (iAuth == CMD_OWNER && sStr == "runaway")
                UserCommand(iAuth, "runaway", kID, FALSE);
            else llMessageLinked(LINK_SET, iAuth, sStr, kID);
            //Debug("noauth: " + sStr + " from " + (string)kID + " who has auth " + (string)iAuth);
            return; // NOAUTH messages need go no further
        } else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
            UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_RESPONSE) {
            //Debug("Got setting response: "+sStr);
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "owner") {
                    g_lOwner = llParseString2List(sValue, [","], []);
                    if (~llSubStringIndex(sValue,g_sWearerID)) g_iVanilla = TRUE;
                    else g_iVanilla = FALSE;
                } else if (sToken == "tempowner")
                    g_lTempOwner = llParseString2List(sValue, [","], []);
                    //Debug("Tempowners: "+llDumpList2String(g_lTempOwner,","));
                else if (sToken == "group") {
                    g_kGroup = (key)sValue;
                    //check to see if the object's group is set properly
                    if (g_kGroup != "") {
                        if ((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == g_kGroup) g_iGroupEnabled = TRUE;
                        else g_iGroupEnabled = FALSE;
                    } else g_iGroupEnabled = FALSE;
                }
                else if (sToken == "public") g_iOpenAccess = (integer)sValue;
                else if (sToken == "limitrange") g_iLimitRange = (integer)sValue;
                else if (sToken == "norun") g_iRunawayDisable = (integer)sValue;
                else if (sToken == "trust") g_lTrust = llParseString2List(sValue, [","], [""]);
                else if (sToken == "block") g_lBlock = llParseString2List(sValue, [","], [""]);
                else if (sToken == "flavor") g_sFlavor = sValue;
            } else if (llToLower(sStr) == "settings=sent") {
                if (llGetListLength(g_lOwner) && g_iFirstRun) {
                    SayOwners();
                    g_iFirstRun = FALSE;
                }
            }
        } else if (iNum == AUTH_REQUEST) {//The reply is: "AuthReply|UUID|iAuth" we rerute this to com to have the same prim ID 
            llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
            llSetTimerEvent(0.22);
            llMessageLinked(iSender,AUTH_REPLY, "AuthReply|"+(string)kID+"|"+(string)Auth(kID, TRUE), llGetSubString(sStr,0,35));
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
                llSetTimerEvent(0.22);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                //Debug(sMessage);
                if (sMenu == "Auth") {
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_ALL_OTHERS, iAuth, "menu " + g_sParentMenu, kAv);
                    else {
                        list lTranslation=[
                            "+ Owner","add owner",
                            "+ Trust","add trust",
                            "+ Block","add block",
                            "− Owner","rm owner",
                            "− Trust","rm trust",
                            "− Block","rm block",
                            "Group ☐","group on",
                            "Group ☑","group off",
                            "Public ☐","public on",
                            "Public ☑","public off",
                            g_sFlavor+" ☐","vanilla on",
                            g_sFlavor+" ☑","vanilla off",
                            "Access List","list",
                            "Runaway","runaway"
                          ];
                        integer buttonIndex=llListFindList(lTranslation,[sMessage]);
                        if (~buttonIndex)
                            sMessage=llList2String(lTranslation,buttonIndex+1);
                        //Debug("Sending UserCommand "+sMessage);
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    }
                } else if (sMenu == "removeowner" || sMenu == "removetrust" || sMenu == "removeblock" ) {
                    string sCmd = "rm "+llGetSubString(sMenu,6,-1)+" ";
                    if (sMessage == UPMENU)
                        AuthMenu(kAv, iAuth);
                    else UserCommand(iAuth, sCmd +sMessage, kAv, TRUE);
                } else if (sMenu == "runawayMenu" ) {   //no chat commands for this menu, by design, so handle it all here
                    if (sMessage == "Yes") RunAway();
                    else if (sMessage == UPMENU) AuthMenu(kAv, iAuth);
                    else if (sMessage == "No") llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway aborted.",kAv);
                } if (llSubStringIndex(sMenu,"AddAvi") == 0) {
                    if ((key)sMessage)
                        AddUniquePerson(sMessage, llGetSubString(sMenu,6,-1), kAv); //should be safe to uase key2name here, as we added from sensor dialog
                    else if (sMessage == "BACK")
                        AuthMenu(kAv,iAuth);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
            else if (sStr == "LINK_REQUEST") llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_AUTH","");
        } else if (iNum == 451 && kID == "sec") FailSafe(1);
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }
    
    timer () {
        llSetLinkPrimitiveParamsFast(LINK_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);
        llSetTimerEvent(0.0);
    }
    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) FailSafe(0);
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
