////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - auth                                //
//                                 version 3.994                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

key g_kWearer;

list g_lOwners;//strided list in form key,name
list g_lSecOwners;//strided list in the form key,name
list g_lBlackList;//list of blacklisted UUID
list g_lTempOwners;//list of temp owners UUID.  Temp owner is just like normal owner, but can't add new owners.

key g_kGroup = "";
string g_sGroupName;
integer g_iGroupEnabled = FALSE;

string g_sParentMenu = "Main";
string g_sSubMenu = "Access";
integer g_iRunawayDisable=0;

string g_sPrefix;

list g_lQueryId; //5 strided list of dataserver/http request: key, uuid, requestType, kAv, remenu.  For AV name/group name  lookups
integer g_iQueryStride=5;

//added for attachment auth
integer g_iInterfaceChannel;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
//integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;  // new for safeword
integer COMMAND_BLACKLIST = 520;
// added so when the sub is locked out they can use postions
integer COMMAND_WEARERLOCKEDOUT = 521;

integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
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

//this can change
integer WEARERLOCKOUT=620;

string UPMENU = "BACK";

string CTYPE = "collar";

integer g_iOpenAccess; // 0: disabled, 1: openaccess
integer g_iLimitRange=1; // 0: disabled, 1: limited
integer g_iWearerlocksOut;

list g_lMenuIDs;
integer g_iMenuStride = 3;

key REQUEST_KEY;

string g_sScript;

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

    //Debug("Made "+sName+" menu.");
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

FetchAvi(integer iAuth, string type, string name, key kAv) {
    if (name == "") name = " ";
    string out = llDumpList2String(["getavi_", g_sScript, kAv, iAuth, type, name], "|");
    integer i = 0;
    list src = g_lOwners;
    if (type == "tempowner") src += g_lTempOwners;
    if (type == "secowner") src += g_lSecOwners;
    else if (type == "blacklist") src = g_lBlackList;
    list exclude; // build list of existing-listed keys to exclude from name search
    for (; i < llGetListLength(src); i += 2)
    {
        exclude += [llList2String(src, i)];
    }
    if (llGetListLength(exclude))
        out += "|" + llDumpList2String(exclude, ",");
    llMessageLinked(LINK_THIS, FIND_AGENT, out, REQUEST_KEY = llGenerateKey());
}

AuthMenu(key kAv, integer iAuth) {
    string sPrompt = "\nOpen the pod bay doors, "+CTYPE+".\n\nwww.opencollar.at/access";
    list lButtons = ["+ Owner", "+ Secowner", "+ Blacklisted", "− Owner", "− Secowner", "− Blacklisted"];

    if (g_kGroup=="") lButtons += ["Group ☐"];    //set group
    else lButtons += ["Group ☒"];    //unset group

    if (g_iOpenAccess) lButtons += ["Public ☒"];    //set open access
    else lButtons += ["Public ☐"];    //unset open access

    if (g_iLimitRange) lButtons += ["LimitRange ☒"];    //set ranged
    else lButtons += ["LimitRange ☐"];    //unset open ranged

    lButtons += ["Runaway","List Owners"];

    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Auth");
}

RemPersonMenu(key kID, string sToken, integer iAuth) {
    list lPeople;
    if (sToken=="owner") lPeople=g_lOwners;
    else if (sToken=="tempowner") lPeople=g_lTempOwners;
    else if (sToken=="secowner") lPeople=g_lSecOwners;
    else if (sToken=="blacklist") lPeople=g_lBlackList;
    else return;

    if (llGetListLength(lPeople)){
        string sPrompt = "\nChoose the person to remove:\n";
        list lButtons;
        
        integer iNum= llGetListLength(lPeople);
        integer n;
        for (n=1; n <= iNum/2; n = n + 1) {
            string sName = llList2String(lPeople, 2*n-1);
            if (sName != "") {
                sPrompt += "\n" + (string)(n) + " - " + sName;
                lButtons += [(string)(n)];
            }
        }
        lButtons += ["Remove All"];

        Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "rem"+sToken);
    } else {
        Notify(kID, "The list is empty", FALSE);
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
    else if (sToken=="secowner") lPeople=g_lSecOwners;
    else if (sToken=="blacklist") lPeople=g_lBlackList;
    else return;
    
    if (~llListFindList(g_lTempOwners,[(string)kCmdr]) && ! ~llListFindList(g_lOwners,[(string)kCmdr]) && sToken != "tempowner"){
        Notify(kCmdr,"Temporary owners can only change the temporary owners list",FALSE);
        return;
    }

    sName = llToLower(sName);
    integer iFound=FALSE;
    integer numPeople= llGetListLength(lPeople)/2;
    while (numPeople--) {
        string sThisName = llToLower(llList2String(lPeople, numPeople*2+1));
        //Debug("checking " + sThisName);
        if (sName == sThisName || sName == "remove all") {   //remove name and key
            
            if (sToken == "owner") {
                Notify(llList2String(lPeople,numPeople*2),"You have been removed as owner on the " + CTYPE + " of " + llKey2Name(g_kWearer) + ".",FALSE);
                llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
            } else if (sToken == "secowner") {
                Notify(llList2String(lPeople,numPeople*2),"You have been removed as secowner on the " + CTYPE + " of " + llKey2Name(g_kWearer) + ".",FALSE);
                llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
            }
            lPeople = llDeleteSubList(lPeople, numPeople*2, numPeople*2+1);

            Notify(kCmdr, sThisName + " removed from list.", TRUE);
            iFound=TRUE;
        }
    }

    if (iFound){
        //save to db
         string sOldToken=sToken;
         if (sToken == "secowner") sOldToken+="s";
            if (llGetListLength(lPeople)>0)
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + sOldToken + "=" + llDumpList2String(lPeople, ","), "");
            else
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + sOldToken, "");
        //store temp list
        if (sToken=="owner") g_lOwners = lPeople;
        else if (sToken=="tempowner") g_lTempOwners = lPeople;
        else if (sToken=="secowner") g_lSecOwners = lPeople;
        else if (sToken=="blacklist") g_lBlackList = lPeople;

    } else 
        Notify(kCmdr, "Error: '" + sName + "' not in list.",FALSE);
}

AddUniquePerson(key kPerson, string sName, string sToken, key kAv) {
    list lPeople;
    //Debug(llKey2Name(kAv)+" is adding "+llKey2Name(kPerson)+" to list "+sToken);
    if (~llListFindList(g_lTempOwners,[(string)kAv]) && ! ~llListFindList(g_lOwners,[(string)kAv]) && sToken != "tempowner"){
        Notify(kAv,"Temporary owners can only change the temporary owners list",FALSE);
    } else {
        if (sToken=="owner") {
            lPeople=g_lOwners;
        } else if (sToken=="secowner") {
            lPeople=g_lSecOwners;
            if (llGetListLength (lPeople) >=20) {
                Notify(kAv, "The maximum of 10 people allowed in this list.",FALSE);
                return;
            }
        } else if (sToken=="tempowner") {
            lPeople=g_lTempOwners;
            if (llGetListLength (lPeople) >=20) {
                Notify(kAv, "The maximum of 10 people allowed in this list.",FALSE);
                return;
            }
        } else if (sToken=="blacklist") {
            lPeople=g_lBlackList;
            if (llGetListLength (lPeople) >=20) {
                Notify(kAv, "The maximum of 10 people allowed in this list.",FALSE);
                return;
            }
        } else
            return;
        
        if (! ~llListFindList(lPeople, [(string)kPerson])) //owner is not already in list.  add him/her
            lPeople += [(string)kPerson, sName];

        if (kPerson != g_kWearer) {
            Notify(kAv, "Added " + sName + " to " + sToken + ".", FALSE);
            if (sToken == "owner") 
                llOwnerSay("Your owner can have a lot  power over you and you consent to that by adding " + sName + " as owner to your " + CTYPE + ". They can leash you, put you in poses and lock your " + CTYPE + ". If you are using RLV they can undress you, make you wear clothes, restrict your  chat, IMs and TPs as well as force TP you anywhere they like. Please read the [http://www.opencollar.at/manual.html manual on the web] for more info. If you do not consent, you can use the command \"" + g_sPrefix + "runaway\" to remove all owners from the " + CTYPE + ".");
        }

        if (sToken == "owner" || sToken == "secowner") {
            Notify(kPerson, "You have been added to the " + sToken + " list on " + llKey2Name(g_kWearer) + "'s " + CTYPE + ". For help concerning the " + CTYPE + " usage, please see the [http://www.opencollar.at/manual.html manual on the web] or type \"" + g_sPrefix + "menu\" in chat to explore the " + CTYPE + " and find links to dedicated manual pages in the menu headers.",FALSE);
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        }
        
        string sOldToken=sToken;
        if (sToken == "secowner") sOldToken+="s";
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + sOldToken + "=" + llDumpList2String(lPeople, ","), "");
        
        if (sToken=="owner") g_lOwners = lPeople;
        else if (sToken=="secowner") g_lSecOwners = lPeople;
        else if (sToken=="tempowner") g_lTempOwners = lPeople;
        else if (sToken=="blacklist") g_lBlackList = lPeople;
    }
}

SayOwners() {
    // Give a "you are owned by" message, nicely formatted.
    list ownernames = llList2ListStrided(llDeleteSubList(g_lOwners, 0, 0), 0, -1, 2);
    integer ownercount = llGetListLength(ownernames);
    if (ownercount) {
        string msg = "You are owned by ";
        if (ownercount == 1) {
            // if one person, then just name.
            msg += (string)ownernames;
        } else if (ownercount == 2) {
            // if two people, then A and B.
            msg += llDumpList2String(ownernames, " and ");
        } else {
            // if >2 people, then A, B, and C
            list init = llDeleteSubList(ownernames, -1, -1);
            list tail = llDeleteSubList(ownernames, 0, -2);
            msg += llDumpList2String(init, ", ");
            msg += ", and " + (string)tail;
        }
        // end with a period.
        msg += ".";
        Notify(llGetOwner(), msg, FALSE);
    }
}

SetPrefix(string sValue) {
    if (sValue != "auto") g_sPrefix = sValue;
    else {
        list name = llParseString2List(llKey2Name(g_kWearer), [" "], []);
        string init = llGetSubString(llList2String(name, 0), 0, 0);
        init += llGetSubString(llList2String(name, 1), 0, 0);
        g_sPrefix = llToLower(init);
    }
}

integer in_range(key kID) {
    if (g_iLimitRange) {
        if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) > 20) { //if the distance between my position and their position  > 20
            llDialog(kID, "\nNot in range...", [], 298479);
            return FALSE;
        }
    }
    return TRUE;
}

integer Auth(string kObjID, integer attachment) {
    string kID = (string)llGetOwnerKey(kObjID); // if kObjID is an avatar key, then kID is the same key
    integer iNum;
    if (~llListFindList(g_lOwners+g_lTempOwners, [kID]))
        iNum = COMMAND_OWNER;
    else if (g_iWearerlocksOut && kID == (string)g_kWearer && !attachment)
        iNum = COMMAND_WEARERLOCKEDOUT;
    else if (llGetListLength(g_lOwners+g_lTempOwners) == 0 && kID == (string)g_kWearer)
        //if no owners set, then wearer's cmds have owner auth
        iNum = COMMAND_OWNER;
    else if (~llListFindList(g_lBlackList, [kID]))
        iNum = COMMAND_BLACKLIST;
    else if (~llListFindList(g_lSecOwners, [kID]))
        iNum = COMMAND_SECOWNER;
    else if (kID == (string)g_kWearer)
        iNum = COMMAND_WEARER;
    else if (g_iOpenAccess)
        if (in_range((key)kID))
            iNum = COMMAND_GROUP;
        else
            iNum = COMMAND_EVERYONE;
    else if (g_iGroupEnabled && (string)llGetObjectDetails((key)kObjID, [OBJECT_GROUP]) == (string)g_kGroup && (key)kID != g_kWearer)  //meaning that the command came from an object set to our control group, and is not owned by the wearer
        iNum = COMMAND_GROUP;
    else if (llSameGroup(kID) && g_iGroupEnabled && kID != (string)g_kWearer)
        if (in_range((key)kID))
            iNum = COMMAND_GROUP;
        else
            iNum = COMMAND_EVERYONE;
    else
        iNum = COMMAND_EVERYONE;
    //Debug("Authed as "+(string)iNum);
    return iNum;
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID, integer remenu) { // here iNum: auth value, sStr: user command, kID: avatar id
    //Debug ("UserCommand("+(string)iNum+","+sStr+","+(string)kID+")");
    
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check
    string sMessage=llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    string sOwnerError="Sorry, only an owner can do that.";
    
    if (sStr == "menu "+g_sSubMenu) {
        AuthMenu(kID, iNum);
    } else if (sStr == "listowners") {   //say owner, secowners, group
        if (iNum == COMMAND_OWNER || kID == g_kWearer) {
            //Do Owners list
            integer iLength = llGetListLength(g_lOwners);
            string sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lOwners, --iLength) + " (" + llList2String(g_lOwners,  --iLength) + ")";
            if (sOutput) Notify(kID, "Owners: " + sOutput,FALSE);
            else Notify(kID, "Owners: None",FALSE);

            //Do TempOwners list
            iLength = llGetListLength(g_lTempOwners);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lTempOwners, --iLength) + " (" + llList2String(g_lTempOwners,  --iLength) + ")";
            if (sOutput) Notify(kID, "Temp Owners: " + sOutput,FALSE);

            //Do Secowners list
            iLength = llGetListLength(g_lSecOwners);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lSecOwners, --iLength) + " (" + llList2String(g_lSecOwners, --iLength) + ")";
            if (sOutput) Notify(kID, "Secowners: " + sOutput,FALSE);
            
            iLength = llGetListLength(g_lBlackList);
            sOutput="";
            while (iLength)
                sOutput += "\n" + llList2String(g_lBlackList, --iLength) + " (" + llList2String(g_lBlackList, --iLength) + ")";
            if (sOutput) Notify(kID, "Black List: " + sOutput,FALSE);
            
            if (g_sGroupName) Notify(kID, "Group: " + g_sGroupName,FALSE);
            if (g_kGroup) Notify(kID, "Group Key: " + (string)g_kGroup,FALSE);
            sOutput="false"; 
            if (g_iOpenAccess) sOutput="true"; 
            Notify(kID, "Open Access: "+ sOutput,FALSE);
            sOutput="false"; 
            if (g_iLimitRange) sOutput="true";
            Notify(kID, "LimitRange: "+ sOutput,FALSE);
        }
        else Notify(kID, "Only Owners & Wearer may access this command",FALSE);
        if (remenu) AuthMenu(kID, iNum);
    } else if (sStr == "owners" || sStr == "access") {   //give owner menu
        AuthMenu(kID, iNum);
//    } else if (sStr=="give hud" || sMessage == "give hud") {
//        if (kID == g_kWearer) llGiveInventory(kID,"Virtual Disgrace - Collar HUD");
//        else llGiveInventory(kID,"Virtual Disgrace - Owner HUD");
//        if (remenu) AuthMenu(kID, iNum);
        
    } else  if (sMessage == "owner" && remenu==FALSE) { //request for access menu from chat
        AuthMenu(kID, iNum);
    } else if (sCommand == "owner" || sCommand == "tempowner" || sCommand == "secowner" || sCommand == "blacklist") { //add a person to a list
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,0), " "); //get full name
        if (iNum!=COMMAND_OWNER) {
            Notify(kID, sOwnerError, FALSE);
            if (remenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if ((key)sTmpName){
            g_lQueryId+=[llRequestAgentData( sTmpName, DATA_NAME ),sTmpName,sCommand, kID, remenu];
            if (remenu) FetchAvi(Auth(kID,FALSE), sCommand, sTmpName, kID);
        } else
            FetchAvi(iNum, sCommand, sTmpName, kID);
    } else if (llSubStringIndex(sCommand,"rem")==0) { //remove person from a list
        if (sCommand=="remowners") sCommand="remowner";
        //Debug("got command "+sCommand);
        string sToken = llGetSubString(sCommand,3,-1);
        //Debug("got token "+sToken);
        string sTmpName = llDumpList2String(llDeleteSubList(lParams,0,0), " "); //get full name
        if (iNum!=COMMAND_OWNER){
            Notify(kID, sOwnerError, FALSE);
            if (remenu) AuthMenu(kID, Auth(kID,FALSE));
        } else if (sTmpName=="") 
            RemPersonMenu(kID, sToken, iNum);
        else {
            RemovePerson(sTmpName, sToken, kID);
            if (remenu) RemPersonMenu(kID, sToken, Auth(kID,FALSE));
        }
            
    } else if (sCommand == "setgroup") {
        if (iNum==COMMAND_OWNER){
            //if key provided use that, else read current group
            if ((key)(llList2String(lParams, -1))) g_kGroup = (key)llList2String(lParams, -1);
            else g_kGroup = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0); //record current group key

            if (g_kGroup != "") {
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "group=" + (string)g_kGroup, "");
                g_iGroupEnabled = TRUE;
             
                key kGroupHTTPID = llHTTPRequest("http://world.secondlife.com/group/" + (string)g_kGroup, [], "");   //get group name from world api
                g_lQueryId+=[kGroupHTTPID,"","group", kID, FALSE];
            }
        } else {
            Notify(kID, sOwnerError, FALSE);
        }
        if (remenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "setgroupname") {
        if (iNum==COMMAND_OWNER){
            g_sGroupName = llDumpList2String(llList2List(lParams, 1, -1), " ");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "groupname=" + g_sGroupName, "");
        } else {
            Notify(kID, sOwnerError, FALSE);
        }
    } else if (sCommand == "unsetgroup") {
        if (iNum==COMMAND_OWNER){
            g_kGroup = "";
            g_sGroupName = "";
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "group", "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "groupname", "");
            g_iGroupEnabled = FALSE;
            Notify(kID, "Group unset.", FALSE);
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        } else {
            Notify(kID, sOwnerError, FALSE);
        }
        if (remenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "setopenaccess") {
        if (iNum==COMMAND_OWNER){
            g_iOpenAccess = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "openaccess=" + (string) g_iOpenAccess, "");
            Notify(kID, "Your " + CTYPE + " is open to the public.", FALSE);
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        } else {
            Notify(kID, sOwnerError, FALSE);
        }
        if (remenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "unsetopenaccess") {
        if (iNum==COMMAND_OWNER){
            g_iOpenAccess = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "openaccess", "");
            Notify(kID, "Your " + CTYPE + " is closed to the public.", FALSE);
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "CollarCommand|499|OwnerChange"); //tell attachments owner changed
        } else {
            Notify(kID, sOwnerError, FALSE);
        }
        if (remenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "setlimitrange") {
        if (iNum==COMMAND_OWNER){
            g_iLimitRange = TRUE;
            // as the default is range limit on, we do not need to store anything for this
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "limitrange", "");
            Notify(kID, "Range is limited.", FALSE);
        } else {
            Notify(kID, sOwnerError, FALSE);
        }
        if (remenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "unsetlimitrange") {
        if (iNum==COMMAND_OWNER){
            g_iLimitRange = FALSE;
            // save off state for limited range (default is on)
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "limitrange=" + (string) g_iLimitRange, "");
            Notify(kID, "Range is simwide.", FALSE);
        } else {
            Notify(kID, sOwnerError, FALSE);
        }
        if (remenu) AuthMenu(kID, Auth(kID,FALSE));
    } else if (sCommand == "runaway"){
        list lButtons=[];
        string message="Only the wearer or an Owner can access this menu";
        if (iNum == COMMAND_OWNER && kID == g_kWearer) {  //wearer-owner called for menu
            if (g_iRunawayDisable){
                lButtons=["Stay","Enable"];
                message="\nYou chose to disable the runaway function.\n\nAs an owner you can restore this ability if desired.";
            } else {
                lButtons=["Runaway!", "Disable"];
                message="\nYou can run away from your owners or you can disable your ability to ever run from them.";
            }
        } else if (kID == g_kWearer){  //wearer called for menu
            if (g_iRunawayDisable){
                lButtons=["Stay","Cancel","Remain","Don't Run", "Stay Loyal"];
                message="\nACCESS DENIED:\n\nYou chose to disable the runaway function.\n\nOnly primary owners can restore this ability.";
            } else {
                lButtons=["Runaway!", "Disable"];
                message="\nYou can run away from your owners or you can disable your ability to ever run from them.";
            }
        } else if (iNum == COMMAND_OWNER ) {  //owner called for menu
            if (g_iRunawayDisable){
                lButtons=["Release", "Enable"];
                message="\nYou can release this sub of your service or you can return their ability to run away on their own.";
            } else {
                lButtons=["Release"];
                message="\nYou can release this sub of your service.";
            }
        }
        //Debug("runaway button");
        Dialog(kID, message, lButtons, [UPMENU], 0, iNum, "runawayMenu");
    }

    return TRUE;
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        g_sScript = "auth_";
        g_kWearer = llGetOwner();  //until set otherwise, wearer is owner
        SetPrefix("auto");
        //added for attachment auth
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
        //Debug("Auth starting: "+(string)llGetFreeMemory());
        // Request owner list.  Be careful about doing this in all scripts,
        // because we can easily flood the 64 event limit in LSL's event queue
        // if all the scripts send a ton of link messages at the same time on
        // startup.
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sScript + "owner", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sScript + "secowners", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sScript + "tempowners", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sScript + "blacklist", "");
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {  
        if (iNum == COMMAND_NOAUTH) { //authenticate messages on COMMAND_NOAUTH
            integer iAuth = Auth((string)kID, FALSE);
            if ( kID == g_kWearer && sStr == "runaway") {   // note that this will work *even* if the wearer is blacklisted or locked out
                if (g_iRunawayDisable){
                    llOwnerSay("Runaway is currently disabled.");
                } else {
                    llOwnerSay("Running away from all owners started, your owners will now be notified!");
                    integer n;
                    integer stop = llGetListLength(g_lOwners+g_lTempOwners);
                    for (n = 0; n < stop; n += 2) {
                        key kOwner = (key)llList2String(g_lOwners+g_lTempOwners, n);
                        if (kOwner != g_kWearer)
                        {
                            Notify(kOwner, llKey2Name(g_kWearer) + " has run away!",FALSE);
                        }
                    }
                    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + "owner=", "");
                    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + "secowners=", "");
                    llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sScript + "all", "");
                    llOwnerSay("Runaway finished, the " + CTYPE + " will now release locks!");
                    // moved reset request from settings to here to allow noticifation of owners.
                    llMessageLinked(LINK_SET, COMMAND_OWNER, "clear", kID); // clear RLV restrictions
                    llMessageLinked(LINK_SET, COMMAND_OWNER, "runaway", kID); // this is not a LM loop, since it is now really authed
                    llResetScript();
                }
            } 
            else if (kID != g_kWearer && iAuth == COMMAND_OWNER && sStr == "runaway") {  //owner requests the runaway menu
                //We trap here and pull up the UserCommand manually to avoid passing 'runaway' prematurely to linkmessage (this was unlocking/unleashing)
                UserCommand(iAuth, "runaway", kID, FALSE); 
            }
            else llMessageLinked(LINK_SET, iAuth, sStr, kID);

            //Debug("noauth: " + sStr + " from " + (string)kID + " who has auth " + (string)iAuth);
            return; // NOAUTH messages need go no further
        } else if (UserCommand(iNum, sStr, kID, FALSE)) return;
        else if (iNum == LM_SETTING_RESPONSE) {
            //Debug("Got setting response: "+sStr);
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "owner") {
                    // temporarily stash owner list so we can see if it's changing.
                    list tmpowners = g_lOwners;
                    g_lOwners = llParseString2List(sValue, [","], []);
                    // only say the owner list if it has changed (including on_rez)
                    if (llGetListLength(g_lOwners) && tmpowners != g_lOwners) SayOwners();
                } else if (sToken == "tempowner") {
                    // temporarily stash owner list so we can see if it's changing.
                    list tmpowners = g_lTempOwners;
                    g_lTempOwners = llParseString2List(sValue, [","], []);
                    //Debug("Tempowners: "+llDumpList2String(g_lTempOwners,","));
                    // only say the owner list if it has changed (including on_rez)
                    if (llGetListLength(g_lTempOwners) && tmpowners != g_lTempOwners) SayOwners();
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
                else if (sToken == "openaccess") g_iOpenAccess = (integer)sValue;
                else if (sToken == "limitrange") g_iLimitRange = (integer)sValue;
                else if (sToken == "runawayDisable") g_iRunawayDisable = (integer)sValue;
                else if (sToken == "secowners") g_lSecOwners = llParseString2List(sValue, [","], [""]);
                else if (sToken == "blacklist") g_lBlackList = llParseString2List(sValue, [","], [""]);
            }
            else if (sToken == "Global_prefix") SetPrefix(sValue);
            else if (sToken == "Global_CType") CTYPE = sValue;
        } else if (iNum == LM_SETTING_EMPTY) {
            //Debug("Got setting empty: "+sStr);
            integer i = llSubStringIndex(sStr, "_");
            if (llGetSubString(sStr, 0, i) == g_sScript) {
                sStr = llGetSubString(sStr, i + 1, -1);
                if (sStr == "owner") {
                    g_lOwners = [];
                    SayOwners();
                } else if (sStr == "tempowner") {
                    g_lTempOwners = [];
                    SayOwners();
                } else if (sStr == "group") {
                    g_kGroup = NULL_KEY;
                    g_iGroupEnabled = FALSE;
                }
                else if (sStr == "groupname") g_sGroupName = "";
                else if (sStr == "openaccess") g_iOpenAccess = FALSE;
                else if (sStr == "limitrange") g_iLimitRange = TRUE;
                else if (sStr == "runawayDisable") g_iRunawayDisable = FALSE;
                else if (sStr == "secowners") g_lSecOwners = [];
                else if (sStr == "blacklist") g_lBlackList = [];
            }
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "Global_prefix") SetPrefix(sValue);
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
        } else if (iNum == WEARERLOCKOUT) {
            if (sStr == "on") g_iWearerlocksOut=TRUE;
            else if (sStr == "off") g_iWearerlocksOut=FALSE;
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
//                            "+ Temp Owner","tempowner",
                            "+ Secowner","secowner",
                            "+ Blacklisted","blacklist",
                            "− Owner","remowner",
//                            "− Temp Owner","remtempowner",
                            "− Secowner","remsecowner",
                            "− Blacklisted","remblacklist",
                            "Group ☐","setgroup",
                            "Group ☒","unsetgroup",
                            "Public ☐","setopenaccess",
                            "Public ☒","unsetopenaccess",
                            "LimitRange ☐","setlimitrange",
                            "LimitRange ☒","unsetlimitrange",
                            //"Give Hud","givehud", 
                            "List Owners","listowners",
                            "Runaway","runaway"
                        ];
                        integer buttonIndex=llListFindList(lTranslation,[sMessage]);
                        if (~buttonIndex){
                            sMessage=llList2String(lTranslation,buttonIndex+1);
                        }
                        //Debug("Sending UserCommand "+sMessage);
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    }
                } else if (sMenu == "remowner" || sMenu == "remsecowner" || sMenu == "remblacklist" ) {
                    if (sMessage == UPMENU) {
                        AuthMenu(kAv, iAuth);
                    } else  if (sMessage == "Remove All") {
                        UserCommand(iAuth, sMenu + " Remove All", kAv,TRUE);
                    } else if (sMenu == "remowner") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lOwners, (integer)sMessage*2 - 1), kAv, TRUE);
                    } else if (sMenu == "remtempowner") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lTempOwners, (integer)sMessage*2 - 1), kAv, TRUE);
                    } else if(sMenu == "remsecowner") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lSecOwners, (integer)sMessage*2 - 1), kAv, TRUE);
                    } else if(sMenu == "remblacklist") {
                        UserCommand(iAuth, sMenu+" " + llList2String(g_lBlackList, (integer)sMessage*2 - 1), kAv, TRUE);
                    }
                } else if (sMenu == "runawayMenu" ) {   //no chat commands for this menu, by design, so handle it all here
                    if (sMessage == UPMENU) {
                        AuthMenu(kAv, iAuth);
                    } else  if (sMessage == "Runaway!") {
                        llMessageLinked(LINK_SET, COMMAND_NOAUTH, "runaway", kAv);
                    } else if (sMessage == "Enable") {
                        if (~llListFindList(g_lTempOwners,[(string)kAv]) && ! ~llListFindList(g_lOwners,[(string)kAv]) ){
                            Notify(kAv,"Temporary owners can't enable runaway.",FALSE);
                        } else {
                            g_iRunawayDisable=FALSE;
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"runawayDisable","");
                            Notify(kAv,"The ability to runaway has been restored.", TRUE);
                            UserCommand(iAuth, "runaway", kAv, TRUE);
                        }
                    } else if (sMessage == "Disable") {
                        g_iRunawayDisable=TRUE;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"runawayDisable=1","");
                        llOwnerSay("You have disabled your ability to runaway.");
                        UserCommand(iAuth, "runaway", kAv, TRUE);
                    } else if (sMessage == "Cancel") {
                        return;  //no remenu on canel
                    } else if (sMessage == "Release") {
                        integer iOwnerIndex=llListFindList(g_lOwners,[(string)kAv]);
                        if (~iOwnerIndex){
                            string name=llList2String(g_lOwners,iOwnerIndex+1);
                            UserCommand(iAuth, "remowner "+name, kAv, FALSE);  //no remenu, owner is done with this sub
                            //llMessageLinked(LINK_SET, COMMAND_OWNER, "runaway", kID); //let other scripts know we're running away
                        } else {
                            Notify(kAv, "You are not on the owners list.", TRUE);
                            UserCommand(iAuth,"runaway",kAv, TRUE); //remenu to runaway
                        }
                    } else {
                        UserCommand(iAuth,"runaway",kAv, TRUE); //remenu to runaway
                    }
                }
            }
        } else if (iNum == FIND_AGENT) { //reply from add-by-name or add-from-menu (via FetchAvi dialog)
            if (kID == REQUEST_KEY) {
                list params = llParseString2List(sStr, ["|"], []);
                if (llList2String(params, 0) == g_sScript) {
                    string sRequestType = llList2String(params, 4);
                    key kAv = llList2Key(params, 2);
                    integer iAuth= llList2Integer(params, 3);
                    key kNewOwner=(key)llList2String(params, 5);
                    if ((key)kNewOwner){
                        AddUniquePerson(kNewOwner, llKey2Name(kNewOwner), sRequestType, kAv); //should be safe to uase key2name here, as we added from sensor dialog
                        //FetchAvi(llList2Integer(params, 3), sRequestType, "", kAv);   //remenu
                        integer iNewAuth=Auth(kAv,FALSE);
                        if (iNewAuth == COMMAND_OWNER){
                            UserCommand(iNewAuth,sRequestType,kAv,TRUE);
                            //FetchAvi(COMMAND_OWNER, sRequestType, "", kAv);   //remenu
                        } else {
                            AuthMenu(kAv,iNewAuth);
                        }
                    } else if (llList2String(params, 5)=="BACK"){
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

            Notify(g_kDialoger, "Group set to " + g_sGroupName + ".", FALSE);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "groupname=" + g_sGroupName, "");
        }
    }
    
    dataserver(key kQueryId, string sData){ //response after an add-by-uuid
        integer listIndex=llListFindList(g_lQueryId,[kQueryId]);
        if (listIndex!= -1){
            key newOwner=llList2Key(g_lQueryId,listIndex+1);
            string sRequestType=llList2String(g_lQueryId,listIndex+2);
            key kAv =llList2Key(g_lQueryId,listIndex+3);
            integer remenu =llList2Integer(g_lQueryId,listIndex+4);
            
            g_lQueryId=llDeleteSubList(g_lQueryId,listIndex,listIndex+g_iQueryStride-1);
            
            AddUniquePerson(newOwner, sData, sRequestType, kAv);
            if (remenu){
                integer iNewAuth=Auth(kAv,FALSE);
                if (iNewAuth == COMMAND_OWNER){
                    UserCommand(iNewAuth,sRequestType,kAv,TRUE);
                    //FetchAvi(COMMAND_OWNER, sRequestType, "", kAv);   //remenu
                } else {
                    AuthMenu(kAv,iNewAuth);
                }
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
