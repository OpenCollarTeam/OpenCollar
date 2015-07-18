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
//                          Authorizer - 150717.1                           //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Nandana Singh, Garvin Twine, Cleo Collins,    //
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
//         github.com/OpenCollar/opencollar/tree/master/src/collar          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

key g_kWearer;

list g_lOwners;//strided list in form key,name
list g_lTrusted;//strided list in the form key,name
//list g_lSecOwners;
list g_lBlockList;//list of blacklisted UUID
list g_lTempOwners;//list of temp owners UUID.  Temp owner is just like normal owner, but can't add new owners.

key g_kGroup = "";
string g_sGroupName;
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "Access";
integer g_iRunawayDisable=0;

list g_lQueryId; //5 strided list of dataserver/http request: key, uuid, requestType, kAv, remenu.  For AV name/group name  lookups
integer g_iQueryStride=5;

//added for attachment auth, for now taken out as we do not support attachment auth
//integer g_iInterfaceChannel;

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

integer FIND_AGENT = -9005;

//added for attachment auth (garvin)
integer ATTACHMENT_REQUEST = 600;
integer ATTACHMENT_RESPONSE = 601;
//new evolution style to handle attachment auth
integer INTERFACE_REQUEST  = -9006;
integer INTERFACE_RESPONSE = -9007;

string UPMENU = "BACK";

integer g_iOpenAccess; // 0: disabled, 1: openaccess
integer g_iLimitRange=1; // 0: disabled, 1: limited
integer g_iVanilla; // self-owned wearers

list g_lMenuIDs;
integer g_iMenuStride = 3;

key REQUEST_KEY;

string g_sSettingToken = "auth_";
//string g_sGlobalToken = "global_";

integer g_iProfiled=1;
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


string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [kID, kMenuID, sName];
    }
}

FetchAvi(integer iAuth, string sType, string sName, key kAv) {
    if (sName == "") sName = " ";
    string out = llDumpList2String(["getavi_", g_sSettingToken, kAv, iAuth, sType, sName], "|");
    integer i = 0;
    list src = g_lOwners;
    if (sType == "tempowner") src += g_lTempOwners;
    if (sType == "trust") src += g_lTrusted;
    else if (sType == "block") src = g_lBlockList;
    list exclude; // build list of existing-listed keys to exclude from name search
    for (; i < llGetListLength(src); i += 2) {
        exclude += [llList2String(src, i)];
    }
    if (llGetListLength(exclude))
        out += "|" + llDumpList2String(exclude, ",");
    llMessageLinked(LINK_THIS, FIND_AGENT, out, REQUEST_KEY = llGenerateKey());
}

AuthMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[http://www.opencollar.at/access.html Access]\n";
    list lButtons = ["+ Owner", "+ Trusted", "+ Blocked", "− Owner", "− Trusted", "− Blocked"];

    if (g_kGroup=="") lButtons += ["Group ☐"];    //set group
    else lButtons += ["Group ☒"];    //unset group
    if (g_iOpenAccess) lButtons += ["Public ☒"];    //set open access
    else lButtons += ["Public ☐"];    //unset open access
    if (g_iVanilla) lButtons += ["Vanilla ☒"];    //add wearer as owner
    else lButtons +=["Vanilla ☐"];    //remove wearer as owner

    lButtons += ["Runaway","Access List"];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Auth");
}

RemPersonMenu(key kID, string sToken, integer iAuth) {
    list lPeople;
    if (sToken=="owner") lPeople=g_lOwners;
    else if (sToken=="tempowner") lPeople=g_lTempOwners;
    else if (sToken=="trust") lPeople=g_lTrusted;
    else if (sToken=="block") lPeople=g_lBlockList;
    else return;
    if (llGetListLength(lPeople)){
        string sPrompt = "\nChoose the person to remove:\n";
        list lButtons;
        integer iNum= llGetListLength(lPeople);
        integer n;
        for(;n<iNum;n=n+2) {
            string sName = llList2String(lPeople,n);
            if (sName) {
                lButtons += [sName];
            }
        }
        Dialog(kID, sPrompt, lButtons, ["Remove All",UPMENU], -1, iAuth, "remove"+sToken);
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0"+"The list is empty",kID);
        AuthMenu(kID, iAuth);
    }
}

RemovePerson(string sName, string sToken, key kCmdr) {
    //where "lPeople" is a 2-strided list in form key,name
    //looks for strides identified by "name", removes them if found, and returns the list
    //also handles notifications so as to reduce code duplication in the link message event
    //Debug("removing: " + sName);
    //all our comparisons will be cast to lower case first
    list lPeople;
    if (sToken=="owner") lPeople=g_lOwners;
    else if (sToken=="tempowner") lPeople=g_lTempOwners;
    else if (sToken=="trust") lPeople=g_lTrusted;
    else if (sToken=="block") lPeople=g_lBlockList;
    else return;
// ~ is bitwise NOT which is used for the llListFindList function to simply turn the result "-1" for "not found" into a 0 (FALSE)
    if (~llListFindList(g_lTempOwners,[(string)kCmdr]) && ! ~llListFindList(g_lOwners,[(string)kCmdr]) && sToken != "tempowner"){
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kCmdr);
        return;
    }
    //simple conversion from ID to Name when ID instead of a name is recieved
    if((key)sName) sName = llList2String(lPeople,llListFindList(lPeople,[(string)sName])+1);
    sName = llToLower(sName);
    integer iFound=FALSE;
    integer iNumPeople= llGetListLength(lPeople)/2;
    while (iNumPeople--) {
        string sThisName = llToLower(llList2String(lPeople, iNumPeople*2+1));
        //Debug("checking " + sThisName);
        if (sName == sThisName || sName == "remove all") {   //remove name and key
            if (sToken == "owner" || sToken == "trust") {
                key kID = llList2Key(lPeople,iNumPeople*2);
                if (sToken == "owner" && kID == g_kWearer) {
                    g_iVanilla = FALSE;
                    if (kCmdr == g_kWearer)
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"You no longer own yourself.",kCmdr);
                    else
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% does no longer own themselves.",kCmdr);
                } else
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Your access to %WEARERNAME%'s %DEVICETYPE% has been revoked.",kID);
            }
            llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(llList2Key(lPeople,iNumPeople*2))+" removed from " + sToken + " list.",kCmdr);
            lPeople = llDeleteSubList(lPeople, iNumPeople*2, iNumPeople*2+1);
            iFound=TRUE;
        }
    }
    if (iFound){
         string sOldToken=sToken;
         if (sToken == "secowner") sOldToken+="s";
            if (llGetListLength(lPeople)>0)
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sOldToken + "=" + llDumpList2String(lPeople, ","), "");
            else
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + sOldToken, "");
        //store temp list
        if (sToken=="owner") {
            g_lOwners = lPeople;
            if (llGetListLength(g_lOwners)) SayOwners();
        }
        else if (sToken=="tempowner") g_lTempOwners = lPeople;
        else if (sToken=="trust") g_lTrusted = lPeople;
        else if (sToken=="block") g_lBlockList = lPeople;
    } else
        llMessageLinked(LINK_SET,NOTIFY,"0"+"\""+sName + "\" is not in "+sToken+" list.",kCmdr);
}

AddUniquePerson(key kPerson, string sName, string sToken, key kAv) {
    list lPeople;
    //Debug(llKey2Name(kAv)+" is adding "+llKey2Name(kPerson)+" to list "+sToken);
    if (~llListFindList(g_lTempOwners,[(string)kAv]) && ! ~llListFindList(g_lOwners,[(string)kAv]) && sToken != "tempowner")
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kAv);
    else {
        if (sToken=="owner") {
            lPeople=g_lOwners;
            if (llGetListLength (lPeople) >=6) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\nThree people at a time can have this role.\n",kAv);
                return;
            }
        } else if (sToken=="trust") {
            lPeople=g_lTrusted;
            if (llGetListLength (lPeople) >=30) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\n15 people at a time can have this role.\n",kAv);
                return;
            } else if (~llListFindList(g_lOwners,[(string)kPerson])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\n"+sName+" is already Owner! You should really trust them.\n",kAv);
                return;
            }
        } else if (sToken=="tempowner") {
            lPeople=g_lTempOwners;
            if (llGetListLength (lPeople) >=2) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nSorry!\n\nYou can only be captured by one person at a time.\n",kAv);
                return;
            }
        } else if (sToken=="block") {
            lPeople=g_lBlockList;
            if (llGetListLength (lPeople) >=18) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\nYour Blacklist is already full.\n",kAv);
                return;
            } else if (~llListFindList(g_lTrusted,[(string)kPerson])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\nYou trust "+sName+". If you really want to block "+sName+" then you should remove them as trusted first.\n",kAv);
                return;
            } else if (~llListFindList(g_lOwners,[(string)kPerson])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\n"+sName+" is Owner! Remove them as owner before you block them.\n",kAv);
                return;
            }
        } else
            return;

        if (! ~llListFindList(lPeople, [(string)kPerson])) { //owner is not already in list.  add him/her
            lPeople += [(string)kPerson, sName];
            if (kPerson == g_kWearer) g_iVanilla = TRUE;
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(kPerson)+" is already registered as "+sToken+".",kAv);
            return;
        }
        if (kPerson != g_kWearer) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Building relationship...",g_kWearer);
            if (sToken == "owner") {
                if (~llListFindList(g_lTrusted,[(string)kPerson])) RemovePerson(sName, "trust", kAv);
                if (~llListFindList(g_lBlockList,[(string)kPerson])) RemovePerson(sName, "block", kAv);
                llMessageLinked(LINK_SET,NOTIFY,"0"+"You belong to "+NameURI(kPerson)+" now!",g_kWearer);
                llPlaySound("1ec0f327-df7f-9b02-26b2-8de6bae7f9d5",1.0);
            } else if (sToken == "trust") {
                if (~llListFindList(g_lBlockList,[(string)kPerson])) RemovePerson(sName, "block", kAv);
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Looks like "+NameURI(kPerson)+" is someone you can trust!",g_kWearer);
                llPlaySound("def49973-5aa6-b79d-8c0e-2976d5b6d07a",1.0);
            }
        }
        if (sToken == "owner") {
            if (kPerson == g_kWearer) {
                if (kAv == g_kWearer)
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nCongratulations, you own yourself now.\n",g_kWearer);
                else
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% is thier own Owner now.\n",kAv);
            } else
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% belongs to you now.\n\nSee [http://www.opencollar.at/intro.html here] what that means!\n",kPerson);
        }
        if (sToken == "trust")
            llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% seems to trust you.\n\nSee [http://www.opencollar.at/intro.html here] what that means!\n",kPerson);
        string sOldToken=sToken;
        if (sToken == "secowner") sOldToken+="s";
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sOldToken + "=" + llDumpList2String(lPeople, ","), "");

        if (sToken=="owner") {
            g_lOwners = lPeople;
            if (llGetListLength(g_lOwners)>2) SayOwners();
        }
        else if (sToken=="trust") g_lTrusted = lPeople;
        else if (sToken=="tempowner") g_lTempOwners = lPeople;
        else if (sToken=="block") g_lBlockList = lPeople;
    }
}

SayOwners() {  // Give a "you are owned by" message, nicely formatted.
    integer iCount = llGetListLength(g_lOwners);
    if (iCount) {
        list lTemp = g_lOwners;
        integer index = llListFindList(lTemp, [(string)g_kWearer]);
        //if wearer is also owner, move the key to the end of the list.
        if (~index) lTemp = llDeleteSubList(lTemp,index,index+1) + [g_kWearer];
        string sMsg = "You belong to ";
        if (iCount == 2) {
            if (llList2Key(lTemp,0)==g_kWearer)
                sMsg += "yourself.";
            else
                sMsg += NameURI(llList2Key(lTemp,0))+".";
        } else if (iCount == 4) {
            sMsg +=  NameURI(llList2String(lTemp,0))+" and ";
            if (llList2Key(lTemp,2)==g_kWearer)
                sMsg += "yourself.";
            else
                sMsg += NameURI(llList2Key(lTemp,2))+".";
        } else {
            index=0;
            do {
                sMsg += NameURI(llList2Key(lTemp,index))+", ";
                index+=2;
            } while (index<iCount-2);
            if (llList2Key(lTemp,index) == g_kWearer)
                sMsg += "and yourself.";
            else
                sMsg += "and "+NameURI(llList2Key(lTemp,index))+".";
        }
        llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg,g_kWearer);
 //       Debug("Lists Loaded!");
    }
}

integer in_range(key kID) {
    if (g_iLimitRange) {
        if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) > 20) { //if the distance between my position and their position  > 20
            return FALSE;
        }
    }
    return TRUE;
}

integer Auth(string sObjID, integer iAttachment) {
    string sID = (string)llGetOwnerKey(sObjID); // if sObjID is an avatar key, then sID is the same key
    integer iNum;
    if (~llListFindList(g_lOwners+g_lTempOwners, [sID]))
        iNum = CMD_OWNER;
    else if (llGetListLength(g_lOwners+g_lTempOwners) == 0 && sID == (string)g_kWearer)
        //if no owners set, then wearer's cmds have owner auth
        iNum = CMD_OWNER;
    else if (~llListFindList(g_lBlockList, [sID]))
        iNum = CMD_BLOCKED;
    else if (~llListFindList(g_lTrusted, [sID]))
        iNum = CMD_TRUSTED;
    else if (sID == (string)g_kWearer)
        iNum = CMD_WEARER;
    else if (g_iOpenAccess)
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    else if (g_iGroupEnabled && (string)llGetObjectDetails((key)sObjID, [OBJECT_GROUP]) == (string)g_kGroup && (key)sID != g_kWearer)  //meaning that the command came from an object set to our control group, and is not owned by the wearer
        iNum = CMD_GROUP;
    else if (llSameGroup(sID) && g_iGroupEnabled && sID != (string)g_kWearer) {
        if (in_range((key)sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_EVERYONE;
    } else
        iNum = CMD_EVERYONE;
    //Debug("Authed as "+(string)iNum);
    return iNum;
}

UserCommand(integer iNum, string sStr, key kID, integer iRemenu) { // here iNum: auth value, sStr: user command, kID: avatar id
    //Debug ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    string sMessage=llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    //string sCommand = llList2String(lParams, 0);
    string sAction = llList2String(lParams, 0);
    string sCommand = llList2String(lParams, 1);
    if (sMessage == "menu access") AuthMenu(kID, iNum);
    else if (sStr == "list") {   //say owner, secowners, group
        if (iNum == CMD_OWNER || kID == g_kWearer) {
            //Do Owners list
            integer iLength = llGetListLength(g_lOwners);
            string sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lOwners, --iLength) + " (" + llList2String(g_lOwners,  --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Owners: "+sOutput,kID);
            else llMessageLinked(LINK_SET,NOTIFY,"0"+"Owners: none",kID);
            iLength = llGetListLength(g_lTempOwners);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lTempOwners, --iLength) + " (" + llList2String(g_lTempOwners,  --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Temporary Owner: "+sOutput,kID);
            iLength = llGetListLength(g_lTrusted);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lTrusted, --iLength) + " (" + llList2String(g_lTrusted, --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Trusted: "+sOutput,kID);
            iLength = llGetListLength(g_lBlockList);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lBlockList, --iLength) + " (" + llList2String(g_lBlockList, --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Blocked: "+sOutput,kID);
            if (g_sGroupName) llMessageLinked(LINK_SET,NOTIFY,"0"+"Group: "+g_sGroupName,kID);
            if (g_kGroup) llMessageLinked(LINK_SET,NOTIFY,"0"+"Group Key: "+(string)g_kGroup,kID);
            sOutput="closed";
            if (g_iOpenAccess) sOutput="open";
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Public Access: "+ sOutput,kID);
        }
        else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, iNum);
    } else if (sCommand == "vanilla") {
        if (iNum != CMD_OWNER) {
            llMessageLinked(LINK_THIS,NOTIFY,"0"+"%NOACCESS%", kID);
            if (iRemenu) AuthMenu(kID, iNum);
        } else {
            if (sAction == "enable") {
                g_iVanilla = TRUE;
                UserCommand(iNum, "owner " + (string)g_kWearer, kID, FALSE);
            } else if (sAction == "disable") {
                g_iVanilla = FALSE;
                UserCommand(iNum, "removeowner " + (string)g_kWearer, kID, FALSE);
            }
            if (iRemenu) AuthMenu(kID, iNum);
            else llMessageLinked(LINK_SET,NOTIFY,"1"+"Vanilla "+sAction+"d.", kID);
        }
    } else if (sMessage == "owners" || sMessage == "access") {   //give owner menu
        AuthMenu(kID, iNum);
    } else if (sMessage == "owner" && iRemenu==FALSE) { //request for access menu from chat
        AuthMenu(kID, iNum);
    } else if (sAction == "add") { //add a person to a list
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,1), " "); //get full name
        if (iNum!=CMD_OWNER && !( sCommand == "trust" && kID==g_kWearer )) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if ((key)sTmpName){
            g_lQueryId+=[llRequestAgentData( sTmpName, DATA_NAME ),sTmpName,sCommand, kID, iRemenu];
            if (iRemenu) FetchAvi(Auth(kID,FALSE), sCommand, sTmpName, kID);
        } else
            FetchAvi(iNum, sCommand, sTmpName, kID);
    } else if (sAction == "remove" || sAction == "rm") { //remove person from a list
        Debug("got Action "+sAction);
       // string sToken = llGetSubString(sCommand,6,-1);
        Debug("got command "+sCommand);
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,1), " "); //get full name
        if (iNum!=CMD_OWNER && !( sCommand == "trust" && kID==g_kWearer )) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if (sTmpName=="") RemPersonMenu(kID, sCommand, iNum);
        else {
            RemovePerson(sTmpName, sCommand, kID);
            if (iRemenu) RemPersonMenu(kID, sCommand, Auth(kID,FALSE));
        }
     } else if (sCommand == "group") {
        if (iNum==CMD_OWNER){
            //if key provided use that, else read current group
            if (sAction == "enable") {
                if ((key)(llList2String(lParams, -1))) g_kGroup = (key)llList2String(lParams, -1);
                else g_kGroup = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0); //record current group key
    
                if (g_kGroup != "") {
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "group=" + (string)g_kGroup, "");
                    g_iGroupEnabled = TRUE;
                    //get group name from world api
                    key kGroupHTTPID = llHTTPRequest("http://world.secondlife.com/group/" + (string)g_kGroup, [], "");
                    g_lQueryId+=[kGroupHTTPID,"","group", kID, FALSE];
                    llMessageLinked(LINK_SET, RLV_CMD, "setgroup=n", "auth");
                }
            } else if (sAction == "disable") {
                g_kGroup = "";
                g_sGroupName = "";
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "group", "");
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "groupname", "");
                g_iGroupEnabled = FALSE;
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Group unset.",kID);
                llMessageLinked(LINK_SET, RLV_CMD, "setgroup=y", "auth");
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "groupname" && sAction == "set") {
        if (iNum==CMD_OWNER){
            g_sGroupName = llDumpList2String(llList2List(lParams, 2, -1), " ");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "groupname=" + g_sGroupName, "");
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
    } else if (sCommand == "public") {
        if (iNum==CMD_OWNER){
            if (sAction == "enable") {
                g_iOpenAccess = TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "public=" + (string) g_iOpenAccess, "");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Your %DEVICETYPE% is open to the public.",kID);
            } else if (sAction == "disable") {
                g_iOpenAccess = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "public", "");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Your %DEVICETYPE% is closed to the public.",kID);
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "limitrange") {
        if (sAction == "enable") {
            if (iNum==CMD_OWNER){
                g_iLimitRange = TRUE;
                // as the default is range limit on, we do not need to store anything for this
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "limitrange", "");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Public access range is limited.",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if (sAction == "disable") {
            if (iNum==CMD_OWNER){
                g_iLimitRange = FALSE;
                // save off state for limited range (default is on)
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "limitrange=" + (string) g_iLimitRange, "");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Public access range is simwide.",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        }
    } else if (sStr == "runaway") {
        list lButtons=[];
        string message="Only the wearer or an Owner can access this menu";
        if (kID == g_kWearer){  //wearer called for menu
            if (g_iRunawayDisable){
                lButtons=["Stay","Cancel","Remain","Don't Run", "Stay Loyal"];
                message="\nACCESS DENIED:\n\nYou chose to disable the runaway function.\n\nOnly primary owners can restore this ability.";
            } else {
                lButtons=["Runaway!", "Stay"];
                message="\nYou can run away from your owners or you can stay with them.";
            }
        } else if (iNum == CMD_OWNER ) {  //owner called for menu
            lButtons=["Release"];
            message="\nYou can release this sub of your service.";

        }
        //Debug("runaway button");
        Dialog(kID, message, lButtons, [UPMENU], 0, iNum, "runawayMenu");
    } else if (sCommand == "runaway") {
        if (sAction == "enable") {
            if (iNum == CMD_OWNER) {
                g_iRunawayDisable = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"norun","");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"The ability to runaway is enabled.",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        } else if (sAction == "disable") {
            if (iNum == CMD_OWNER || iNum == CMD_WEARER) {
                g_iRunawayDisable = TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"norun=1","");
                llMessageLinked(LINK_SET,NOTIFY,"0"+"The ability to runaway is disabled.",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        }
    }
}

RunAway() {
    integer n;
    integer stop = llGetListLength(g_lOwners+g_lTempOwners);
    llMessageLinked(LINK_SET,NOTIFY_OWNERS,"%WEARERNAME% ran away!","");

    llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sSettingToken + "owner", "");
    llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sSettingToken + "tempowner", "");
    //llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sSettingToken + "trust=", "");
    //llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sSettingToken + "all", "");
    // moved reset request from settings to here to allow noticifation of owners.
    llMessageLinked(LINK_SET, CMD_OWNER, "clear", g_kWearer);
    llMessageLinked(LINK_SET, CMD_OWNER, "runaway", g_kWearer); // this is not a LM loop, since it is now really authed
    llMessageLinked(LINK_SET,NOTIFY,"0"+"Runaway finished.",g_kWearer);
    llResetScript();
}


default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
      /*  if (g_iProfiled){
            llScriptProfiler(1);
           // Debug("profiling restarted");
        }*/
        //llSetMemoryLimit(65536);
        g_kWearer = llGetOwner();
        //Debug("Auth starting: "+(string)llGetFreeMemory());
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_ZERO) { //authenticate messages on CMD_ZERO
            integer iAuth = Auth((string)kID, FALSE);
            if ( kID == g_kWearer && sStr == "runaway") {   // note that this will work *even* if the wearer is blacklisted or locked out
                if (g_iRunawayDisable)
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Runaway is currently disabled.",g_kWearer);
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
                    g_lOwners = llParseString2List(sValue, [","], []);
                    if (~llSubStringIndex(sValue,(string)g_kWearer)) g_iVanilla = TRUE;
                } else if (sToken == "tempowner") {
                    g_lTempOwners = llParseString2List(sValue, [","], []);
                    //Debug("Tempowners: "+llDumpList2String(g_lTempOwners,","));
                } else if (sToken == "group") {
                    g_kGroup = (key)sValue;
                    //check to see if the object's group is set properly
                    if (g_kGroup != "") {
                        if ((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == g_kGroup) g_iGroupEnabled = TRUE;
                        else g_iGroupEnabled = FALSE;
                    }
                    else g_iGroupEnabled = FALSE;
                }
                else if (sToken == "groupname") g_sGroupName = sValue;
                else if (sToken == "public") g_iOpenAccess = (integer)sValue;
                else if (sToken == "limitrange") g_iLimitRange = (integer)sValue;
                else if (sToken == "norun") g_iRunawayDisable = (integer)sValue;
                else if (sToken == "trust") g_lTrusted = llParseString2List(sValue, [","], [""]);
                else if (sToken == "block") g_lBlockList = llParseString2List(sValue, [","], [""]);
            } else if (llToLower(sStr) == "settings=sent") {
                if (llGetListLength(g_lOwners)) SayOwners();
            }
        }
    // JS: For backwards compatibility until all attachments/etc are rolled over to new interface
        //added for attachment auth (Garvin)
        else if (iNum == ATTACHMENT_REQUEST) {
          integer iAuth = Auth((string)kID, TRUE);
          llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, (string)iAuth+"|"+sStr, kID);
        }
    // JS: Remove ATTACHMENT_REQUEST & RESPONSE after all attachments have been updated properly
        else if (iNum == INTERFACE_REQUEST) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sTarget = llList2String(lParams, 0);
            string sCommand = llList2String(lParams, 1);
            if (sTarget == "auth_") {
                if (sCommand == "level") {
                    string sAuth = (string)Auth((string)kID, TRUE);
                    lParams = llListReplaceList(lParams, ["level=" + sAuth], 1, 1);
                }
                else return; // do not send response if the message was erroneous
                llMessageLinked(LINK_SET, INTERFACE_RESPONSE, llDumpList2String(lParams, "|"), kID);
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                //remove stride from g_lMenuIDs
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenu == "Auth") {
                    //g_kAuthMenuID responds to setowner, setsecowner, setblacklist, remowner, remsecowner, remblacklist, setgroup, unsetgroup, setopenaccess, unsetopenaccess
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else {
                        list lTranslation=[
                            "+ Owner","owner",
                            //"+ Temp Owner","tempowner",
                            "+ Trusted","trust",
                            "+ Blocked","block",
                            "− Owner","remove owner",
                            //"− Temp Owner","remtempowner",
                            "− Trusted","remove trust",
                            "− Blocked","remove block",
                            "Group ☐","enable group",
                            "Group ☒","disable group",
                            "Public ☐","enable public",
                            "Public ☒","disable public",
                            "Vanilla ☐","enable vanilla",
                            "Vanilla ☒","disable vanilla",
                            "Access List","list",
                            "Runaway","runaway"
                          ];
                        integer buttonIndex=llListFindList(lTranslation,[sMessage]);
                        if (~buttonIndex){
                            sMessage=llList2String(lTranslation,buttonIndex+1);
                        }
                        //Debug("Sending UserCommand "+sMessage);
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    }
                } else if (sMenu == "removeowner" || sMenu == "removetrust" || sMenu == "removeblock" ) {
                    if (sMessage == UPMENU) {
                        AuthMenu(kAv, iAuth);
                    } else  if (sMessage == "Remove All") {
                        UserCommand(iAuth, sMenu + " Remove All", kAv,TRUE);
                    } else UserCommand(iAuth, sMenu+" " +sMessage, kAv, TRUE);
                } else if (sMenu == "runawayMenu" ) {   //no chat commands for this menu, by design, so handle it all here
                    if (sMessage == UPMENU) {
                        AuthMenu(kAv, iAuth);
                    } else  if (sMessage == "Runaway!") {
                        RunAway();
                    } else if (sMessage == "Cancel" || sMessage == "Stay") {
                        return;  //no remenu on canel
                    } else if (sMessage == "Release") {
                        integer iOwnerIndex=llListFindList(g_lOwners,[(string)kAv]);
                        if (~iOwnerIndex){
                            string name=llList2String(g_lOwners,iOwnerIndex+1);
                            UserCommand(iAuth, "removeowner "+name, kAv, FALSE);  //no remenu, owner is done with this sub
                        } else {
                            llMessageLinked(LINK_SET,NOTIFY,"1"+"You are not on the access list.",kAv);
                            UserCommand(iAuth,"runaway",kAv, TRUE); //remenu to runaway
                        }
                    } else {
                        AuthMenu(kAv, iAuth);
                    }
                }
            }
        } else if (iNum == FIND_AGENT) { //reply from add-by-name or add-from-menu (via FetchAvi dialog)
            if (kID == REQUEST_KEY) {
                list params = llParseString2List(sStr, ["|"], []);
                if (llList2String(params, 0) == g_sSettingToken) {
                    string sRequestType = llList2String(params, 4);
                    key kAv = llList2Key(params, 2);
                    integer iAuth = llList2Integer(params, 3);
                    key kNewOwner = (key)llList2String(params, 5);
                    if ((key)kNewOwner){
                        AddUniquePerson(kNewOwner, llKey2Name(kNewOwner), sRequestType, kAv); //should be safe to uase key2name here, as we added from sensor dialog
                        integer iNewAuth=Auth(kAv,FALSE);
                        if (iNewAuth == CMD_OWNER){
                            UserCommand(iNewAuth,sRequestType,kAv,TRUE);
                        } else {
                            AuthMenu(kAv,iNewAuth);
                        }
                    } else if (llList2String(params, 5) == "BACK"){
                        AuthMenu(kAv,iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        }
    }

    http_response(key kQueryId, integer iStatus, list lMeta, string sBody) { //response to a group name lookup
        integer listIndex=llListFindList(g_lQueryId,[kQueryId]);
        if (listIndex!= -1){
            key g_kDialoger=llList2Key(g_lQueryId,listIndex+3);
            g_lQueryId=llDeleteSubList(g_lQueryId,listIndex,listIndex+g_iQueryStride-1);

            g_sGroupName = "(group name hidden)";
            if (iStatus == 200) {
                integer iPos = llSubStringIndex(sBody, "<title>");
                integer iPos2 = llSubStringIndex(sBody, "</title>");
                if ((~iPos) // Found
                    && iPos2 > iPos // Has to be after it
                    && iPos2 <= iPos + 43 // 36 characters max (that's 7+36 because <title> has 7)
                    && !~llSubStringIndex(sBody, "AccessDenied") // Check as per groupname.py (?)
                ) {
                    g_sGroupName = llGetSubString(sBody, iPos + 7, iPos2 - 1);
                }
            }
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Group set to " + g_sGroupName + ".",g_kDialoger);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "groupname=" + g_sGroupName, "");
        }
    }

    dataserver(key kQueryId, string sData){ //response after an add-by-uuid
        integer listIndex = llListFindList(g_lQueryId,[kQueryId]);
        if (listIndex!= -1){
            key newOwner = llList2Key(g_lQueryId,listIndex+1);
            string sRequestType = llList2String(g_lQueryId,listIndex+2);
            key kAv  =llList2Key(g_lQueryId,listIndex+3);
            integer iRemenu = llList2Integer(g_lQueryId,listIndex+4);

            g_lQueryId=llDeleteSubList(g_lQueryId,listIndex,listIndex+g_iQueryStride-1);

            AddUniquePerson(newOwner, sData, sRequestType, kAv);
            if (iRemenu){
                integer iNewAuth = Auth(kAv,FALSE);
                if (iNewAuth == CMD_OWNER)
                    UserCommand(iNewAuth,sRequestType,kAv,TRUE);
                else
                    AuthMenu(kAv,iNewAuth);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
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
