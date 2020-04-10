// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Garvin Twine, Cleo Collins,  
// Satomi Ahn, Master Starship, Sei Lisa, Joy Stipe, Wendy Starfall,    
// Medea Destiny, littlemousy, Romka Swallowtail, Sumi Perl et al.     
// Licensed under the GPLv2. See LICENSE for full details. 
string g_sScriptVersion = "7.4";
integer LINK_CMD_DEBUG=1999;
DebugOutput(key kID, list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llInstantMessage(kID, llGetScriptName() +final);
}


string g_sWearerID;
list g_lOwner;
list g_lTrust;
list g_lBlock;//list of blacklisted UUID
list g_lTempOwner;//list of temp owners UUID.  Temp owner is just like normal owner, but can't add new owners.
integer g_iPeopleCap = 28; // we'll only store this many people across owner, trusted, blocked, and tempowner lists

key g_kGroup = "";
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "Access";
integer g_iRunawayDisable=0;

string g_sDrop = "f364b699-fb35-1640-d40b-ba59bdd5f7b7";

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_BLOCKED = 520;
integer CMD_NOACCESS = 599;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
integer LOADPIN = -1904;
integer REBOOT              = -1000;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

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

integer g_iCaptureIsActive=FALSE; // If this flag is set, then auth will deny access to it's menus
integer g_iOpenAccess; // 0: disabled, 1: openaccess
integer g_iLimitRange=1; // 0: disabled, 1: limited

list g_lMenuIDs;
integer g_iMenuStride = 3;
key g_kConfirmOwnSelfOffDialogID;
integer g_iGrantRemoval;
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

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

string NameURI(string sID){
    return "secondlife:///app/agent/"+sID+"/about";
}

Dialog(string sID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName, integer iSensor) {
    key kMenuID = llGenerateKey();
    if (iSensor)
        llMessageLinked(LINK_SET, SENSORDIALOG, sID +"|"+sPrompt+"|0|``"+(string)AGENT+"`10`"+(string)PI+"`"+llList2String(lChoices,0)+"|"+llDumpList2String(lUtilityButtons, "`")+"|" + (string)iAuth, kMenuID);
    else
        llMessageLinked(LINK_SET, DIALOG, sID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [sID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [sID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [sID, kMenuID, sName];
    }
}

AuthMenu(key kAv, integer iAuth) {
    if(g_iCaptureIsActive){
        llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% while capture is active",kAv);
        return;
    }
    string sPrompt = "\n[Access & Authorization]";
    list lButtons = ["+ Owner", "+ Trust", "+ Block", "− Owner", "− Trust", "− Block"];

    lButtons += Checkbox(bool((g_kGroup!="")), "Group");
    lButtons += Checkbox(g_iOpenAccess, "Public");

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
        llMessageLinked(LINK_SET,NOTIFY,"0"+"The list is empty",kID);
        AuthMenu(kID, iAuth);
    }
}

string g_sOwnSelfList;
RemovePerson(string sPersonID, string sToken, key kCmdr, integer iPromoted) {
    list lPeople;
    

    if (sToken=="owner") lPeople=g_lOwner;
    else if (sToken=="tempowner") lPeople=g_lTempOwner;
    else if (sToken=="trust") lPeople=g_lTrust;
    else if (sToken=="block") lPeople=g_lBlock;
    else return;
// ~ is bitwise NOT which is used for the llListFindList function to simply turn the result "-1" for "not found" into a 0 (FALSE)
    if (~llListFindList(g_lTempOwner,[(string)kCmdr]) && ! ~llListFindList(g_lOwner,[(string)kCmdr]) && sToken != "tempowner"){
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to changing tempowner",kCmdr);
        return;
    }
    integer iFound;
    if (llGetListLength(lPeople) == 0) {//nothing to do
    } else {
        integer index = llListFindList(lPeople,[sPersonID]);
        if (~index) {
            if ((sToken == "owner" || sToken == "trust")&& sPersonID == g_sWearerID && g_iGrantRemoval==FALSE){
                
                string msg;
                if((key)g_sWearerID==kCmdr)msg="Are you sure you no longer wish to own yourself?";
                else msg = llGetDisplayName(kCmdr)+" wants to remove you as owner do you agree?";
                g_kConfirmOwnSelfOffDialogID = llGenerateKey();
                g_sOwnSelfList = sToken;
                g_iGrantRemoval=FALSE;
                llMessageLinked(LINK_SET, DIALOG, (string)llGetOwner()+"|"+msg+"|0|Yes`No|Cancel|",g_kConfirmOwnSelfOffDialogID);
                iFound=TRUE;
            } else {
                //OwnSelfOff(kCmdr);
                lPeople = llDeleteSubList(lPeople,index,index);
                if (!iPromoted) llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(sPersonID)+" removed from " + sToken + " list.",kCmdr);
                iFound = TRUE;
                g_iGrantRemoval=FALSE;
            }
        } else if (llToLower(sPersonID) == "remove all" && g_iGrantRemoval==FALSE) {
           //llSay(0, "remove_all");
            
            if ((sToken == "owner" || sToken == "trust") && ~llListFindList(lPeople,[g_sWearerID])){
                string msg;
                if((key)g_sWearerID==kCmdr)msg="Are you sure you no longer wish to own yourself?";
                else msg = llGetDisplayName(kCmdr)+" wants to remove you as owner do you agree?";
                g_kConfirmOwnSelfOffDialogID = llGenerateKey();
                g_iGrantRemoval=FALSE;
                g_sOwnSelfList = sToken;
                llMessageLinked(LINK_SET, DIALOG, (string)llGetOwner()+"|"+msg+"|0|Yes`No|Cancel|",g_kConfirmOwnSelfOffDialogID);
                iFound=TRUE;
                lPeople=[g_sWearerID];
            } else {
                llMessageLinked(LINK_SET,NOTIFY,"1"+sToken+" list cleared.",kCmdr);
                lPeople = [];
                iFound = TRUE;
                
                
            }
        }
    }
    if (iFound){
        if (llGetListLength(lPeople)>0)
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        else
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + sToken, "");
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        //store temp list*/
        if (sToken=="owner") {
            g_lOwner = lPeople;
            if (llGetListLength(g_lOwner)) SayOwners();
        }
        else if (sToken=="tempowner") g_lTempOwner = lPeople;
        else if (sToken=="trust") g_lTrust = lPeople;
        else if (sToken=="block") g_lBlock = lPeople;
    } else
        llMessageLinked(LINK_SET,NOTIFY,"0"+"\""+NameURI(sPersonID) + "\" is not in "+sToken+" list.",kCmdr);
}

AddUniquePerson(string sPersonID, string sToken, key kID) {
    list lPeople;
    //Debug(llKey2Name(kAv)+" is adding "+llKey2Name(kPerson)+" to list "+sToken);
    if (~llListFindList(g_lTempOwner,[(string)kID]) && ! ~llListFindList(g_lOwner,[(string)kID]) && sToken != "tempowner")
        llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to adding new user",kID);
    else {
        // Put a cap on how many people we'll remember, to avoid running out of
        // memory.
        integer peopleStored = llGetListLength(g_lOwner) +
            llGetListLength(g_lTrust) + 
            llGetListLength(g_lTempOwner) +
            llGetListLength(g_lBlock);
        if (peopleStored >= g_iPeopleCap) {
            llMessageLinked(
                LINK_SET,
                NOTIFY,
                "0\n\nSorry, we reached a limit!\n\nYou have stored 28 people in the collar's lists. (owners+trusted+tempowners+blocked)\n",
                kID
            );
            return;
        }
        if (sToken=="owner") {
            lPeople=g_lOwner;
        } else if (sToken=="trust") {
            lPeople=g_lTrust;
            if (~llListFindList(g_lOwner,[sPersonID])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" is already Owner! You should really trust them.\n",kID);
                return;
            }/* else if (sPersonID==g_sWearerID) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" doesn't belong on this list as the wearer of the %DEVICETYPE%. Instead try: /%CHANNEL% %PREFIX% ownself on\n",kID);
                return;
            }*/
        } else if (sToken=="tempowner") {
            lPeople=g_lTempOwner;
        } else if (sToken=="block") {
            if(sPersonID == g_sWearerID){
                llMessageLinked(LINK_SET,NOTIFY, "0\n\n%WEARERNAME% cannot be blocked.",kID);
                return;
            }
            lPeople=g_lBlock;
            if (~llListFindList(g_lTrust,[sPersonID])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\nYou trust "+NameURI(sPersonID)+". If you really want to block "+NameURI(sPersonID)+" then you should remove them as trusted first.\n",kID);
                return;
            } else if (~llListFindList(g_lOwner,[sPersonID])) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nOops!\n\n"+NameURI(sPersonID)+" is Owner! Remove them as owner before you block them.\n",kID);
                return;
            }
        } else return;
        if (! ~llListFindList(lPeople, [sPersonID])) { //owner is not already in list.  add him/her
            lPeople += sPersonID;
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+NameURI(sPersonID)+" is already registered as "+sToken+".",kID);
            return;
        }
        if (sPersonID != g_sWearerID) llMessageLinked(LINK_SET,NOTIFY,"0"+"Building relationship...",g_sWearerID);
        if (sToken == "owner") {
            if (~llListFindList(g_lTrust,[sPersonID])) RemovePerson(sPersonID, "trust", kID, TRUE);
            if (~llListFindList(g_lBlock,[sPersonID])) RemovePerson(sPersonID, "block", kID, TRUE);
            llPlaySound(g_sDrop,1.0);
        } else if (sToken == "trust") {
            if (~llListFindList(g_lBlock,[sPersonID])) RemovePerson(sPersonID, "block", kID, TRUE);
            if (sPersonID != g_sWearerID) llMessageLinked(LINK_SET,NOTIFY,"0"+"Looks like "+NameURI(sPersonID)+" is someone you can trust!",g_sWearerID);
            llPlaySound(g_sDrop,1.0);
        }
        if (sToken == "owner") {
            if (sPersonID == g_sWearerID) {
                if (kID == g_sWearerID)
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\nCongratulations, you own yourself now.\n",g_sWearerID);
                else
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% is their own Owner now.\n",kID);
            } else
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% belongs to you now.\n\nSee [https://github.com/OpenCollarTeam/OpenCollar/wiki/Access here] what that means!\n",sPersonID);
        }
        if (sToken == "trust"){
            if(sPersonID == g_sWearerID){
                if(kID == g_sWearerID)
                    llMessageLinked(LINK_SET,NOTIFY, "0\n\nYou are now added as a trusted user to your own collar", g_sWearerID);
                else
                    llMessageLinked(LINK_SET,NOTIFY,"0\n\n%WEARERNAME% is now trusted",g_sWearerID);
            }else
                llMessageLinked(LINK_SET,NOTIFY,"0"+"\n\n%WEARERNAME% seems to trust you.\n\nSee [https://github.com/OpenCollarTeam/OpenCollar/wiki/Access here] what that means!\n",sPersonID);
        }
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken + sToken + "=" + llDumpList2String(lPeople, ","), "");
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
        llMessageLinked(LINK_SET,NOTIFY,"0"+sMsg,g_sWearerID);
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

integer Auth(string sObjID) {
    string sID = (string)llGetOwnerKey(sObjID); // if sObjID is an avatar key, then sID is the same key
    integer iNum;
    if (~llListFindList(g_lOwner, [sID]))
        iNum = CMD_OWNER;
    else if(~llListFindList(g_lTempOwner, [sID])) iNum = CMD_TRUSTED; // TODO: Evaluate whether we want to keep the temporary owner level as trusted, full owner auth level, or make a dedicated CMD_TEMPORARY for this role.
    else if (llGetListLength(g_lOwner) == 0 && sID == g_sWearerID)
        //if no owners set, then wearer's cmds have owner auth
        iNum = CMD_OWNER;
    else if (~llListFindList(g_lBlock, [sID]))
        iNum = CMD_BLOCKED;
    else if (~llListFindList(g_lTrust, [sID]))
        iNum = CMD_TRUSTED;
    else if (sID == g_sWearerID)
        iNum = CMD_WEARER;
    else if (g_iOpenAccess){
        if(in_range(sID))
            iNum = CMD_EVERYONE;
        else iNum = CMD_NOACCESS;
    }
    else if (g_iGroupEnabled && (string)llGetObjectDetails((key)sObjID, [OBJECT_GROUP]) == (string)g_kGroup && (key)sID != g_sWearerID)  //meaning that the command came from an object set to our control group, and is not owned by the wearer
    {
        if(in_range(sObjID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_NOACCESS;
    }
    else if (llSameGroup(sID) && g_iGroupEnabled && sID != g_sWearerID) {
        if(in_range(sID))
            iNum = CMD_GROUP;
        else
            iNum = CMD_NOACCESS;
    } else
        iNum = CMD_NOACCESS;
    //Debug("Authed as "+(string)iNum);
    return iNum;
}

UserCommand(integer iNum, string sStr, key kID, integer iRemenu) { // here iNum: auth value, sStr: user command, kID: avatar id
   // Debug ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    string sMessage = llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    if (sStr == "menu "+g_sSubMenu){
        
        if(g_iCaptureIsActive){
            llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% while capture is active",kID);
            return;
        }
        AuthMenu(kID, iNum);
    }
    else if (sStr == "list") {   //say owner, secowners, group
        if (iNum == CMD_OWNER || kID == g_sWearerID) {
            //Do Owners list
            integer iLength = llGetListLength(g_lOwner);
            string sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lOwner, --iLength));
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Owners: "+sOutput,kID);
            else llMessageLinked(LINK_SET,NOTIFY,"0"+"Owners: none",kID);
            iLength = llGetListLength(g_lTempOwner);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lTempOwner, --iLength));
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Temporary Owner: "+sOutput,kID);
            iLength = llGetListLength(g_lTrust);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lTrust, --iLength));
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Trusted: "+sOutput,kID);
            iLength = llGetListLength(g_lBlock);
            sOutput="";
            while (iLength)
                sOutput += "\n" + NameURI(llList2String(g_lBlock, --iLength));
            if (sOutput) llMessageLinked(LINK_SET,NOTIFY,"0"+"Blocked: "+sOutput,kID);
            //if (g_sGroupName) llMessageLinked(LINK_SET,NOTIFY,"0"+"Group: "+g_sGroupName,kID);
            if (g_kGroup) llMessageLinked(LINK_SET,NOTIFY,"0"+"Group: secondlife:///app/group/"+(string)g_kGroup+"/about",kID);
            sOutput="closed";
            if (g_iOpenAccess) sOutput="open";
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Public Access: "+ sOutput,kID);
        }
        else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to listing access",kID);
        if (iRemenu) AuthMenu(kID, iNum);
    } /*else if (sCommand == "ownself" || sCommand == llToLower(g_sFlavor)) {
        if (iNum == CMD_OWNER && !~llListFindList(g_lTempOwner,[(string)kID])) {
            if (sAction == "on") {
                //g_iOwnSelf = TRUE;
                UserCommand(iNum, "add owner " + g_sWearerID, kID, FALSE);
            } else if (sAction == "off") {
                g_kConfirmOwnSelfOffDialogID = llGenerateKey();
                string msg;
                if(g_sWearerID==kID)msg="Are you sure you no longer wish to own yourself?";
                else msg = llGetDisplayName(kID)+" wants to remove you as owner do you agree?";
                llMessageLinked(LINK_SET, DIALOG, (string)llGetOwner()+"|"+msg+"|0|Yes`No|Cancel|",g_kConfirmOwnSelfOffDialogID);
                //g_iOwnSelf = FALSE;
                iRemenu=FALSE;
                //UserCommand(iNum, "rm owner " + g_sWearerID, kID, FALSE);
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to ownself", kID);
         if (iRemenu) AuthMenu(kID, iNum);
    }*/ else if (sMessage == "owners" || sMessage == "access") {   //give owner menu
        AuthMenu(kID, iNum);
    } else if (sCommand == "owner" && iRemenu==FALSE) { //request for access menu from chat
        AuthMenu(kID, iNum);
    } else if (sCommand == "add") { //add a person to a list
        if (!~llListFindList(["owner","trust","block"],[sAction])) return; //not a valid command
        string sTmpID = llList2String(lParams,2); //get full name
        if (iNum!=CMD_OWNER && !( sAction == "trust" && kID==g_sWearerID )) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to adding new person",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID));
        } else if ((key)sTmpID){
            AddUniquePerson(sTmpID, sAction, kID);
            if (iRemenu) Dialog(kID, "\nChoose who to add to the "+sAction+" list:\n",[sTmpID],[UPMENU],0,Auth(kID),"AddAvi"+sAction, TRUE);
        } else {
            string sTmpID2 = llList2String(lParams,3);
            if(sTmpID2 != ""){
                g_lRequests = [llRequestUserKey(sTmpID+" "+sTmpID2), sCommand, sAction, kID];
                //llHTTPRequest("http://w-hat.com/name2key/"+sTmpID+"."+sTmpID2,[],""), sCommand, sAction, kID];
            } else
                Dialog(kID, "\nChoose who to add to the "+sAction+" list:\n",[sTmpID],[">Wearer<",UPMENU],0,iNum,"AddAvi"+sAction, TRUE);
        }
    } else if (sCommand == "remove" || sCommand == "rm") { //remove person from a list
        if (!~llListFindList(["owner","trust","block"],[sAction])) return; //not a valid command
        string sTmpID = llList2String(lParams,2); //get full name
        //llSay(0, "lParams 2: "+llList2String(lParams,2)+"; lParams 3: "+llList2String(lParams,3));
        if (iNum != CMD_OWNER && !( sAction == "trust" && kID == g_sWearerID )) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to removing user from list",kID);
            if (iRemenu) AuthMenu(kID, Auth(kID));
        } else if ((key)sTmpID) {
            if(sTmpID == g_sWearerID)iRemenu=FALSE;
            RemovePerson(sTmpID, sAction, kID, FALSE);
            if (iRemenu) RemPersonMenu(kID, sAction, Auth(kID));
        } else if (llToLower(sTmpID)+" "+llToLower(llList2String(lParams,3)) == "remove all") {
            RemovePerson(sTmpID+" "+llList2String(lParams,3), sAction, kID, FALSE);
            // Remenu in the RemovePerson function 
//            if (iRemenu) RemPersonMenu(kID, sAction, Auth(kID));
        } else {
            string sTmpID2 = llList2String(lParams,3);
            if(sTmpID2 != ""){
                g_lRequests = [llHTTPRequest("http://w-hat.com/name2key/"+sTmpID+"."+sTmpID2,[],""), sCommand, sAction, kID];
            } else {
                RemPersonMenu(kID, sAction, iNum);
            }
        }
     } else if (sCommand == "group") {
         if (iNum==CMD_OWNER){
             if (sAction == "on") {
                //if key provided use that, else read current group
                if ((key)(llList2String(lParams, -1))) g_kGroup = (key)llList2String(lParams, -1);
                else g_kGroup = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0); //record current group key
    
                if (g_kGroup != "") {
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "group=" + (string)g_kGroup, "");
                    g_iGroupEnabled = TRUE;
                    llMessageLinked(LINK_SET, RLV_CMD, "setgroup=n", "auth");
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Group set to secondlife:///app/group/" + (string)g_kGroup + "/about\n\nNOTE: If RLV is enabled, the group slot has been locked and group mode has to be disabled before %WEARERNAME% can switch to another group again.\n",kID);
                }
            } else if (sAction == "off") {
                g_kGroup = "";
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "group", "");
                g_iGroupEnabled = FALSE;
                llMessageLinked(LINK_SET,NOTIFY,"1"+"Group unset.",kID);
                llMessageLinked(LINK_SET, RLV_CMD, "setgroup=y", "auth");
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to toggling group",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } else if (sCommand == "public") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                g_iOpenAccess = TRUE;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "public=" + (string) g_iOpenAccess, "");
                llMessageLinked(LINK_SET,NOTIFY,"1"+"The %DEVICETYPE% is open to the public.",kID);
            } else if (sAction == "off") {
                g_iOpenAccess = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "public", "");
                llMessageLinked(LINK_SET,NOTIFY,"1"+"The %DEVICETYPE% is closed to the public.",kID);
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to toggling public access",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } else if (sCommand == "limitrange") {
        if (iNum==CMD_OWNER){
            if (sAction == "on") {
                g_iLimitRange = TRUE;
                // as the default is range limit on, we do not need to store anything for this
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "limitrange", "");
                llMessageLinked(LINK_SET,NOTIFY,"1"+"Public access range is limited.",kID);
            } else if (sAction == "off") {
                g_iLimitRange = FALSE;
                // save off state for limited range (default is on)
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "limitrange=" + (string) g_iLimitRange, "");
                llMessageLinked(LINK_SET,NOTIFY,"1"+"Public access range is simwide.",kID);
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to limit range",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } else if (sMessage == "runaway"){
       // list lButtons=[];
      // string message;//="\nOnly the wearer or an Owner can access this menu";
        if (kID == g_sWearerID){  //wearer called for menu
            if (g_iRunawayDisable)
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to runaway",kID);
            else {
                Dialog(kID, "\nDo you really want to run away from all owners?", ["Yes", "No"], [UPMENU], 0, iNum, "runawayMenu",FALSE);
                return;
            }
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"This feature is only for the wearer of the %DEVICETYPE%.",kID);
        if (iRemenu) AuthMenu(kID, Auth(kID));
    } 
}
DeleteAndResend(string sToken){
    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sSettingToken+sToken+"=",""); //// LEGACY OPTION. New scripts will hear LM_SETTING_DELETE
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+sToken,"");
}
RunAway() {
    llMessageLinked(LINK_SET,NOTIFY_OWNERS,"%WEARERNAME% ran away!","");
    list lOpts = ["owner","tempowner","trust","block", "group", "public"];
    integer i=0;
    integer end=llGetListLength(lOpts);
    for(i=0;i<end;i++){
        DeleteAndResend(llList2String(lOpts,i));
    }
    
    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "GLOBAL_locked=","");
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "GLOBAL_locked","");
    // moved reset request from settings to here to allow noticifation of owners.
    llMessageLinked(LINK_SET, CMD_OWNER, "clear", g_sWearerID);
    llMessageLinked(LINK_SET, CMD_OWNER, "runaway", g_sWearerID); // this is not a LM loop, since it is now really authed
    llMessageLinked(LINK_SET,NOTIFY,"0"+"Runaway finished.",g_sWearerID);
    llResetScript();
}
list g_lRequests;



ExtractPart(){
    g_sScriptPart = llList2String(llParseString2List(llGetScriptName(), ["_"],[]),1);
}

string g_sScriptPart; // oc_<part>
integer INDICATOR_THIS;
SearchIndicators(){
    ExtractPart();
    
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=0;i<end;i++){
        list Params = llParseStringKeepNulls(llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0), ["~"],[]);
        
        if(llListFindList(Params, ["indicator_"+g_sScriptPart])!=-1){
            INDICATOR_THIS = i;
            return;
        }
    }
    
    
}
Indicator(integer iMode){
    if(INDICATOR_THIS==-1)return;
    if(iMode)
        llSetLinkPrimitiveParamsFast(INDICATOR_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,TRUE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_NONE,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.4]);
    else
        llSetLinkPrimitiveParamsFast(INDICATOR_THIS,[PRIM_FULLBRIGHT,ALL_SIDES,FALSE,PRIM_BUMP_SHINY,ALL_SIDES,PRIM_SHINY_HIGH,PRIM_BUMP_NONE,PRIM_GLOW,ALL_SIDES,0.0]);
}


default {
    on_rez(integer iParam) {
        llResetScript();
    }

    timer(){
        Indicator(FALSE);
        llSetTimerEvent(0);
    }
    
    state_entry() {
        if (llGetStartParameter()!=0){
            state inUpdate;
        }else {
            g_iFirstRun=TRUE;
        }
      /*  if (g_iProfiled){
            llScriptProfiler(1);
           // Debug("profiling restarted");
        }*/
        //llSetMemoryLimit(65536);
        SearchIndicators();
        g_sWearerID = llGetOwner();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        
        if (iNum == CMD_ZERO) { //authenticate messages on CMD_ZERO
            Indicator(TRUE);
            llSetTimerEvent(0.22);
            integer iAuth = Auth(kID);
            if ( kID == g_sWearerID && sStr == "runaway") {   // note that this will work *even* if the wearer is blacklisted or locked out
                if (g_iRunawayDisable)
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Runaway is currently disabled.",g_sWearerID);
                else
                    UserCommand(iAuth,"runaway",kID, FALSE);
            } else if (iAuth == CMD_OWNER && sStr == "runaway")
                UserCommand(iAuth, "runaway", kID, FALSE);
            else llMessageLinked(LINK_SET, iAuth, sStr, kID);
            //Debug("noauth: " + sStr + " from " + (string)kID + " who has auth " + (string)iAuth);
            return; // NOAUTH messages need go no further
        } else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
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
            } else if (llToLower(sStr) == "settings=sent") {
                if (llGetListLength(g_lOwner) && g_iFirstRun) {
                    SayOwners();
                    g_iFirstRun = FALSE;
                }
            } else if(llGetSubString(sToken,0,i)=="capture_"){
                if(llGetSubString(sToken,i+1,-1)=="status"){
                    integer Flag = (integer)sValue;
                    if(Flag&4)
                        g_iCaptureIsActive=TRUE;
                }
            } else if(llToLower(llGetSubString(sToken,0,i)) == "global_"){
                if(llGetSubString(sToken,i+1,-1) == "checkboxes"){
                    g_lCheckboxes=llCSV2List(sValue);
                }
            }
        } else if (iNum == RLV_REFRESH || iNum == RLV_CLEAR){
            if (g_iGroupEnabled) llMessageLinked(LINK_SET, RLV_CMD, "setgroup=n", "auth"); // This restriction should be active as long as group access is active!
        } else if( iNum == LM_SETTING_DELETE){
            list lParams = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lParams,0);
            string sVariable = llList2String(lParams,1);
            if(sToken == "auth"){
                if(sVariable=="tempowner"){
                    g_iCaptureIsActive=FALSE; // Capture will have also been stopped
                    g_lTempOwner=[];
                }
            }
        } else if (iNum == AUTH_REQUEST) {//The reply is: "AuthReply|UUID|iAuth" we rerute this to com to have the same prim ID 
            Indicator(TRUE);
            llSetTimerEvent(0.22);
            llMessageLinked(iSender,AUTH_REPLY, "AuthReply|"+(string)kID+"|"+(string)Auth(kID), llGetSubString(sStr,0,35));
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                Indicator(TRUE);
                llSetTimerEvent(0.22);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                // integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                //Debug(sMessage);
                if (sMenu == "Auth") {
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else {
                        list lTranslation=[
                            "+ Owner","add owner",
                            "+ Trust","add trust",
                            "+ Block","add block",
                            "− Owner","rm owner",
                            "− Trust","rm trust",
                            "− Block","rm block",
                            Checkbox(FALSE,"Group"),"group on",
                            Checkbox(TRUE,"Group"),"group off",
                            Checkbox(FALSE,"Public"),"public on",
                            Checkbox(TRUE, "Public"),"public off",
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
                    else{
                        //llSay(0, "Remove User: "+(string)iAuth+"; "+sCmd+"; "+sMessage+"; "+(string)kAv);
                        UserCommand(iAuth, sCmd +sMessage, kAv, TRUE);
                    }
                } else if (sMenu == "runawayMenu" ) {   //no chat commands for this menu, by design, so handle it all here
                    if (sMessage == "Yes") RunAway();
                    else if (sMessage == UPMENU) AuthMenu(kAv, iAuth);
                    else if (sMessage == "No") llMessageLinked(LINK_SET,NOTIFY,"0"+"Runaway aborted.",kAv);
                } if (llSubStringIndex(sMenu,"AddAvi") == 0) {
                    if(sMessage == ">Wearer<")
                        AddUniquePerson( llGetOwner(), llGetSubString(sMenu,6,-1),kAv); // add the wearer
                    else if (sMessage == "BACK")
                        AuthMenu(kAv,iAuth);
                    else if ((key)sMessage)
                        AddUniquePerson(sMessage, llGetSubString(sMenu,6,-1), kAv); //should be safe to uase key2name here, as we added from sensor dialog
                    
                    
                }
            }
            
            if(kID == g_kConfirmOwnSelfOffDialogID){
                list  MenuParams = llParseString2List(sStr,["|"],[]);
                if(llList2String(MenuParams,1)=="Yes"){
                    // truly disable ownself now
                    g_iGrantRemoval=TRUE;
                    RemovePerson(g_sWearerID, g_sOwnSelfList, llGetKey(), TRUE);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        }
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            DebugOutput(kID, [" CAPTURE ACTIVE:",g_iCaptureIsActive]);
            DebugOutput(kID, [" LIMIT ACCESS:", g_iLimitRange]);
            DebugOutput(kID, [" OPEN ACCESS:",g_iOpenAccess]);
            DebugOutput(kID, [" FIRST RUN:",g_iFirstRun]);
            DebugOutput(kID, [" DISABLE RUNAWAY:", g_iRunawayDisable]);
            DebugOutput(kID, [" GROUP:", g_iGroupEnabled]);
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

    dataserver(key kReq, string sData){
        integer iPos = llListFindList(g_lRequests,[kReq]);
        if(iPos!=-1){
            if(llList2String(g_lRequests,iPos+1)=="add")
                AddUniquePerson((key)sData, llList2String(g_lRequests,iPos+2), (key)llList2String(g_lRequests,iPos+3));
            else
                RemovePerson((key)sData, llList2String(g_lRequests,iPos+2), (key)llList2String(g_lRequests,iPos+3), FALSE);
            
            g_lRequests=llDeleteSubList(g_lRequests, iPos,iPos+3);
        }
    }
}

state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
        else if(iNum == 0){
            if(sMsg == "do_move"){
                
                if(llGetLinkNumber()==LINK_ROOT || llGetLinkNumber() == 0)return;
                
                list Parameters = llParseStringKeepNulls(llList2String(llGetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_DESC]),0), ["~"],[]);
                ExtractPart();
                Parameters += "indicator_"+g_sScriptPart;
                llSetLinkPrimitiveParams(llGetLinkNumber(), [PRIM_DESC, llDumpList2String(Parameters,"~")]);
                
                llOwnerSay("Moving oc_auth!");
                integer i=0;
                integer end=llGetInventoryNumber(INVENTORY_ALL);
                for(i=0;i<end;i++){
                    string item = llGetInventoryName(INVENTORY_ALL,i);
                    if(llGetInventoryType(item)==INVENTORY_SCRIPT && item!=llGetScriptName()){
                        llRemoveInventory(item);
                    }else if(llGetInventoryType(item)!=INVENTORY_SCRIPT){
                        llGiveInventory(kID, item);
                        llRemoveInventory(item);
                        i=-1;
                        end=llGetInventoryNumber(INVENTORY_ALL);
                    }
                }
                
                llRemoveInventory(llGetScriptName());
            }
        }
    }
}