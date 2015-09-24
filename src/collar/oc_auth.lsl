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
//                          Authorizer - 150914.1                           //
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

list g_lOwner;//strided list in form key,name
list g_lTrust;//strided list in the form key,name
//list g_lSecOwners;
list g_lBlock;//list of blacklisted UUID
list g_lTempOwner;//list of temp owners UUID.  Temp owner is just like normal owner, but can't add new owners.

key g_kGroup = "";
string g_sGroupName;
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "Access";
integer g_iRunawayDisable=0;

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
integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;
string UPMENU = "BACK";

integer g_iOpenAccess; // 0: disabled, 1: openaccess
integer g_iLimitRange=1; // 0: disabled, 1: limited
integer g_iVanilla; // self-owned wearers

list g_lMenuIDs;
integer g_iMenuStride = 3;

key REQUEST_KEY;
integer g_iFirstRun;

integer g_iLEDLink;

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

string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [kID, kMenuID, sName];
    }
}

integer FindLED() {
    integer i = llGetNumberOfPrims();
    do { 
        if (~llSubStringIndex(llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0),"LED~auth"))
            return i;
    } while (i-- > 1);
    return llGetLinkNumber();
}

FetchAvi(integer iAuth, string sType, string sName, key kAv) {
    if (sName == "") sName = " ";
    string out = llDumpList2String(["getavi_", g_sSettingToken, kAv, iAuth, sType, sName], "|");
    integer i = 0;
    list src = g_lOwner;
    if (sType == "tempowner") src += g_lTempOwner;
    if (sType == "trust") src += g_lTrust;
    else if (sType == "block") src = g_lBlock;
    list exclude; // build list of existing-listed keys to exclude from name search
    for (; i < llGetListLength(src); i += 2) {
        exclude += [llList2String(src, i)];
    }
    if (llGetListLength(exclude))
        out += "|" + llDumpList2String(exclude, ",");
    llMessageLinked(LINK_DIALOG, FIND_AGENT, out, REQUEST_KEY = llGenerateKey());
}

AuthMenu(key kAv, integer iAuth) {
    string sPrompt = "\n[http://www.opencollar.at/access.html Access]\n";
    list lButtons = ["+ Owner", "+ Trust", "+ Block", "− Owner", "− Trust", "− Block"];

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
        for(;n<iNum;n=n+2) {
            string sName = llList2String(lPeople,n);
            if (sName) lButtons += [sName];
        }
        Dialog(kID, sPrompt, lButtons, ["Remove All",UPMENU], -1, iAuth, "remove"+sToken);
    } else {
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The list is empty",kID);
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
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You no longer own yourself.\n",kCmdr);
                    else
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%WEARERNAME% does no longer own themselves.\n",kCmdr);
                } else
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your access to %WEARERNAME%'s %DEVICETYPE% has been revoked.",kID);
            }
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(llList2Key(lPeople,iNumPeople*2))+" removed from " + sToken + " list.",kCmdr);
            lPeople = llDeleteSubList(lPeople, iNumPeople*2, iNumPeople*2+1);
            iFound=TRUE;
        }
    }
    if (iFound){
        // string sOldToken=sToken;
         //if (sToken == "secowner") sOldToken+="s";
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
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\""+sName + "\" is not in "+sToken+" list.",kCmdr);
}

AddUniquePerson(key kPerson, string sName, string sToken, key kAv) {
    list lPeople;
    //Debug(llKey2Name(kAv)+" is adding "+llKey2Name(kPerson)+" to list "+sToken);
    if (~llListFindList(g_lTempOwner,[(string)kAv]) && ! ~llListFindList(g_lOwner,[(string)kAv]) && sToken != "tempowner")
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kAv);
    else {
        if (sToken=="owner") {
            lPeople=g_lOwner;
            if (llGetListLength (lPeople) >=6) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\nThree people at a time can have this role.\n",kAv);
                return;
            }
        } else if (sToken=="trust") {
            lPeople=g_lTrust;
            if (llGetListLength (lPeople) >=30) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSorry, we reached a limit!\n\n15 people at a time can have this role.\n",kAv);
                return;
            } else if (~llListFindList(g_lOwner,[(string)kPerson])) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+sName+" is already Owner! You should really trust them.\n",kAv);
                return;
            }
        } else if (sToken=="tempowner") {
            lPeople=g_lTempOwner;
            if (llGetListLength (lPeople) >=2) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nSorry!\n\nYou can only be captured by one person at a time.\n",kAv);
                return;
            }
        } else if (sToken=="block") {
            lPeople=g_lBlock;
            if (llGetListLength (lPeople) >=18) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\nYour Blacklist is already full.\n",kAv);
                return;
            } else if (~llListFindList(g_lTrust,[(string)kPerson])) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\nYou trust "+sName+". If you really want to block "+sName+" then you should remove them as trusted first.\n",kAv);
                return;
            } else if (~llListFindList(g_lOwner,[(string)kPerson])) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nOops!\n\n"+sName+" is Owner! Remove them as owner before you block them.\n",kAv);
                return;
            }
        } else
            return;

        if (! ~llListFindList(lPeople, [(string)kPerson])) { //owner is not already in list.  add him/her
            lPeople += [(string)kPerson, sName];
            if (kPerson == g_kWearer) g_iVanilla = TRUE;
        } else {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+NameURI(kPerson)+" is already registered as "+sToken+".",kAv);
            return;
        }
        if (kPerson != g_kWearer) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Building relationship...",g_kWearer);
            if (sToken == "owner") {
                if (~llListFindList(g_lTrust,[(string)kPerson])) RemovePerson(sName, "trust", kAv);
                if (~llListFindList(g_lBlock,[(string)kPerson])) RemovePerson(sName, "block", kAv);
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You belong to "+NameURI(kPerson)+" now!",g_kWearer);
                llPlaySound("1ec0f327-df7f-9b02-26b2-8de6bae7f9d5",1.0);
            } else if (sToken == "trust") {
                if (~llListFindList(g_lBlock,[(string)kPerson])) RemovePerson(sName, "block", kAv);
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Looks like "+NameURI(kPerson)+" is someone you can trust!",g_kWearer);
                llPlaySound("def49973-5aa6-b79d-8c0e-2976d5b6d07a",1.0);
            }
        }
        if (sToken == "owner") {
            if (kPerson == g_kWearer) {
                if (kAv == g_kWearer)
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nCongratulations, you own yourself now.\n",g_kWearer);
                else
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% is thier own Owner now.\n",kAv);
            } else
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% belongs to you now.\n\nSee [http://www.opencollar.at/intro.html here] what that means!\n",kPerson);
        }
        if (sToken == "trust")
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\n%WEARERNAME% seems to trust you.\n\nSee [http://www.opencollar.at/intro.html here] what that means!\n",kPerson);
       // string sOldToken=sToken;
       // if (sToken == "secowner") sOldToken+="s";
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        if (sToken=="owner") {
            g_lOwner = lPeople;
            if (llGetListLength(g_lOwner)>2) SayOwners();
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
        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMsg,g_kWearer);
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
    else if (llGetListLength(g_lOwner+g_lTempOwner) == 0 && sID == (string)g_kWearer)
        //if no owners set, then wearer's cmds have owner auth
        iNum = CMD_OWNER;
    else if (~llListFindList(g_lBlock, [sID]))
        iNum = CMD_BLOCKED;
    else if (~llListFindList(g_lTrust, [sID]))
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
   // Debug ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    string sMessage = llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    if (sStr == "menu "+g_sSubMenu) AuthMenu(kID, iNum);
    else if (sStr == "list") {   //say owner, secowners, group
        if (iNum == CMD_OWNER || kID == g_kWearer) {
            //Do Owners list
            integer iLength = llGetListLength(g_lOwner);
            string sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lOwner, --iLength) + " (" + llList2String(g_lOwner,  --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Owners: "+sOutput,kID);
            else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Owners: none",kID);
            iLength = llGetListLength(g_lTempOwner);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lTempOwner, --iLength) + " (" + llList2String(g_lTempOwner,  --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Temporary Owner: "+sOutput,kID);
            iLength = llGetListLength(g_lTrust);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lTrust, --iLength) + " (" + llList2String(g_lTrust, --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Trusted: "+sOutput,kID);
            iLength = llGetListLength(g_lBlock);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lBlock, --iLength) + " (" + llList2String(g_lBlock, --iLength) + ")";
            if (sOutput) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Blocked: "+sOutput,kID);
            if (g_sGroupName) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group: "+g_sGroupName,kID);
            if (g_kGroup) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group Key: "+(string)g_kGroup,kID);
            sOutput="closed";
            if (g_iOpenAccess) sOutput="open";
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Public Access: "+ sOutput,kID);
        }
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, iNum);
    } else if (sCommand == "vanilla") {
        if (iNum == CMD_OWNER && !~llListFindList(g_lTempOwner,[(string)kID])) {
            if (sAction == "on") {
                g_iVanilla = TRUE;
                UserCommand(iNum, "add owner " + (string)g_kWearer, kID, FALSE);
            } else if (sAction == "off") {
                g_iVanilla = FALSE;
                UserCommand(iNum, "rm owner " + (string)g_kWearer, kID, FALSE);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%", kID);
         if (iRemenu) AuthMenu(kID, iNum);
    } else if (sMessage == "owners" || sMessage == "access") {   //give owner menu
        AuthMenu(kID, iNum);
    } else if (sCommand == "owner" && iRemenu==FALSE) { //request for access menu from chat
        AuthMenu(kID, iNum);
    } else if (sCommand == "add") { //add a person to a list
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,1), " "); //get full name
        if (iNum!=CMD_OWNER && !( sAction == "trust" && kID==g_kWearer )) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if ((key)sTmpName){
            g_lQueryId+=[llRequestAgentData( sTmpName, DATA_NAME ),sTmpName,sAction, kID, iRemenu];
            if (iRemenu) FetchAvi(Auth(kID,FALSE), sAction, sTmpName, kID);
        } else
            FetchAvi(iNum, sAction, sTmpName, kID);
    } else if (sCommand == "remove" || sCommand == "rm") { //remove person from a list
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,1), " "); //get full name
        if (iNum != CMD_OWNER && !( sAction == "trust" && kID == g_kWearer )) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if (sTmpName=="") RemPersonMenu(kID, sAction, iNum);
        else {
            RemovePerson(sTmpName, sAction, kID);
            if (iRemenu) RemPersonMenu(kID, sAction, Auth(kID,FALSE));
        }
     } else if (sCommand == "group") {
         if (iNum==CMD_OWNER){
             if (sAction == "on") {
                //if key provided use that, else read current group
                if ((key)(llList2String(lParams, -1))) g_kGroup = (key)llList2String(lParams, -1);
                else g_kGroup = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0); //record current group key
    
                if (g_kGroup != "") {
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "group=" + (string)g_kGroup, "");
                    g_iGroupEnabled = TRUE;
                    //get group name from world api
                    key kGroupHTTPID = llHTTPRequest("http://world.secondlife.com/group/" + (string)g_kGroup, [], "");
                    g_lQueryId+=[kGroupHTTPID,"","group", kID, FALSE];
                    llMessageLinked(LINK_RLV, RLV_CMD, "setgroup=n", "auth");
                }
            } else if (sAction == "off") {
                g_kGroup = "";
                g_sGroupName = "";
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "group", "");
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "groupname", "");
                g_iGroupEnabled = FALSE;
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group unset.",kID);
                llMessageLinked(LINK_RLV, RLV_CMD, "setgroup=y", "auth");
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "set" && sAction == "groupname") {
        if (iNum==CMD_OWNER){
            g_sGroupName = llDumpList2String(llList2List(lParams, 2, -1), " ");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "groupname=" + g_sGroupName, "");
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    } else if (sCommand == "public") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                g_iOpenAccess = TRUE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "public=" + (string) g_iOpenAccess, "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your %DEVICETYPE% is open to the public.",kID);
            } else if (sAction == "off") {
                g_iOpenAccess = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "public", "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your %DEVICETYPE% is closed to the public.",kID);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "limitrange") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                g_iLimitRange = TRUE;
                // as the default is range limit on, we do not need to store anything for this
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "limitrange", "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Public access range is limited.",kID);
            } else if (sAction == "off") {
                g_iLimitRange = FALSE;
                // save off state for limited range (default is on)
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "limitrange=" + (string) g_iLimitRange, "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Public access range is simwide.",kID);
            }
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sMessage == "runaway"){
        list lButtons=[];
        string message;//="\nOnly the wearer or an Owner can access this menu";
        if (kID == g_kWearer){  //wearer called for menu
            if (g_iRunawayDisable)
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            else
                Dialog(kID, "\nDo you really want to run away from all owners?", ["Yes", "No"], [UPMENU], 0, iNum, "runawayMenu");
        } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
    }
}

RunAway() {
    llMessageLinked(LINK_DIALOG,NOTIFY_OWNERS,"%WEARERNAME% ran away!","");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + "owner=", "");
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "owner", "");
    llMessageLinked(LINK_ALL_OTHERS, LM_SETTING_RESPONSE, g_sSettingToken + "tempowner=", "");    
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken + "tempowner", "");
    // moved reset request from settings to here to allow noticifation of owners.
    llMessageLinked(LINK_ALL_OTHERS, CMD_OWNER, "clear", g_kWearer);
    llMessageLinked(LINK_ALL_OTHERS, CMD_OWNER, "runaway", g_kWearer); // this is not a LM loop, since it is now really authed
    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway finished.",g_kWearer);
    llResetScript();
}


default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        if (llGetStartParameter()==825) llSetRemoteScriptAccessPin(0);
        else g_iFirstRun = TRUE;
      /*  if (g_iProfiled){
            llScriptProfiler(1);
           // Debug("profiling restarted");
        }*/
        //llSetMemoryLimit(65536);
        g_kWearer = llGetOwner();
        g_iLEDLink =  FindLED();
        //Debug("Auth starting: "+(string)llGetFreeMemory());
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_ZERO) { //authenticate messages on CMD_ZERO
            llSetLinkPrimitiveParamsFast(g_iLEDLink,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE]);
            llSetTimerEvent(0.22);
            integer iAuth = Auth(kID, FALSE);
            if ( kID == g_kWearer && sStr == "runaway") {   // note that this will work *even* if the wearer is blacklisted or locked out
                if (g_iRunawayDisable)
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Runaway is currently disabled.",g_kWearer);
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
                    if (~llSubStringIndex(sValue,(string)g_kWearer)) g_iVanilla = TRUE;
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
                else if (sToken == "groupname") g_sGroupName = sValue;
                else if (sToken == "public") g_iOpenAccess = (integer)sValue;
                else if (sToken == "limitrange") g_iLimitRange = (integer)sValue;
                else if (sToken == "norun") g_iRunawayDisable = (integer)sValue;
                else if (sToken == "trust") g_lTrust = llParseString2List(sValue, [","], [""]);
                else if (sToken == "block") g_lBlock = llParseString2List(sValue, [","], [""]);
            } else if (llToLower(sStr) == "settings=sent") {
                if (llGetListLength(g_lOwner) && g_iFirstRun) {
                    SayOwners();
                    g_iFirstRun = FALSE;
                }
            }
        } else if (iNum == AUTH_REQUEST) {//The reply is: "AuthReply|UUID|iAuth" we rerute this to com to have the same prim ID 
            llSetLinkPrimitiveParamsFast(g_iLEDLink,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE]);
            llSetTimerEvent(0.22);
            llMessageLinked(iSender,AUTH_REPLY, "AuthReply|"+(string)kID+"|"+(string)Auth(kID, TRUE), llGetSubString(sStr,0,35));
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                llSetLinkPrimitiveParamsFast(g_iLEDLink,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE]);
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
                            "Group ☒","group off",
                            "Public ☐","public on",
                            "Public ☒","public off",
                            "Vanilla ☐","vanilla on",
                            "Vanilla ☒","vanilla off",
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
                    if (sMessage == UPMENU)
                        AuthMenu(kAv, iAuth);
                    else  if (sMessage == "Yes") RunAway();
                }
            }
        } else if (iNum == FIND_AGENT) { //reply from add-by-name or add-from-menu (via FetchAvi dialog)
            if (kID == REQUEST_KEY) {
                llSetTimerEvent(0.11);
                //Debug ("FindAgent: "+ sStr);
                list params = llParseString2List(sStr, ["|"], []);
                if (llList2String(params, 0) == g_sSettingToken) {
                    string sRequestType = llList2String(params, 4);
                    key kAv = llList2Key(params, 2);
                    integer iAuth = llList2Integer(params, 3);
                    key kNewOwner = (key)llList2String(params, 5);
                    if ((key)kNewOwner)
                        AddUniquePerson(kNewOwner, llKey2Name(kNewOwner), sRequestType, kAv); //should be safe to uase key2name here, as we added from sensor dialog
                    else if (llList2String(params, 5) == "BACK")
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
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
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
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Group set to " + g_sGroupName + ".",g_kDialoger);
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "groupname=" + g_sGroupName, "");
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
    
    timer () {
        llSetLinkPrimitiveParamsFast(g_iLEDLink,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE]);
        llSetTimerEvent(0.0);
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
