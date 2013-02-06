//OpenCollar - auth
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

key g_kWearer;
list g_lOwners;//strided list in form key,name
key g_kGroup = "";
string g_sGroupName;
integer g_iGroupEnabled = FALSE;
list g_lSecOwners;//strided list in the form key,name
list g_lBlackList;//list of blacklisted UUID
string g_sTmpName; //used temporarily to store new owner or secowner name while retrieving key

string  g_sWikiURL = "http://code.google.com/p/opencollar/wiki/UserDocumentation";
string g_sParentMenu = "Main";
string g_sSubMenu = "Owners";

string g_sRequestType; //may be "owner" or "secowner" or "remsecowner"
key g_kHTTPID;
key g_kGroupHTTPID;

string g_sOwnersToken = "owner";
string g_sSecOwnersToken = "secowners";
string g_sBlackListToken = "blacklist";

string g_sPrefix;

//dialog handlers
key g_kAuthMenuID;
key g_kSensorMenuID;

//added for attachment auth
integer g_iInterfaceChannel = -12587429;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;  // new for safeword
integer COMMAND_BLACKLIST = 520;
// added so when the sub is locked out they can use postions
integer COMMAND_WEARERLOCKEDOUT = 521;
//added for attachment auth (garvin)
integer ATTACHMENT_REQUEST = 600;
integer ATTACHMENT_RESPONSE = 601;

integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//this can change
integer WEARERLOCKOUT=620;

//EXTERNAL MESSAGE MAP
integer EXT_COMMAND_COLLAR = 499;

string UPMENU = "^";

string g_sSetOwner = "Add Owner";
string g_sSetSecOwner = "Add Secowner";
string g_sSetBlackList = "Add Blacklisted";
string g_sSetGroup = "Set Group";
string g_sReset = "Reset All";
string g_sRemOwner = "Rem Owner";
string g_sRemSecOwner = "Rem Secowner";
string g_sRemBlackList = "Rem Blacklisted";
string g_sUnsetGroup = "Unset Group";
string g_sListOwners = "List Owners";
string g_sSetOpenAccess = "SetOpenAccess";
string g_sUnsetOpenAccess = "UnsetOpenAccess";
string g_sSetLimitRange = "LimitRange";
string g_sUnsetLimitRange = "UnLimitRange";

//request types
string g_sOwnerScan = "ownerscan";
string g_sSecOwnerScan = "secownerscan";
string g_sBlackListScan = "blacklistscan";

integer g_iOpenAccess; // 0: disabled, 1: openaccess
integer g_iLimitRange=1; // 0: disabled, 1: limited
integer g_iWearerlocksOut;

integer g_iRemenu = FALSE;

key g_kDialoger;//the person using the dialog.  needed in the sensor event when scanning for new owners to add
integer g_iDialogerAuth; //auth of the person using the dialog

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    } else {
            llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
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

sendToAttachmentInterface(string sMsg)
{
    llWhisper(g_iInterfaceChannel, "CollarCommand|" + (string) EXT_COMMAND_COLLAR + "|" + sMsg);
}

list AddUniquePerson(list lContainer, key kID, string sName, string sType)
{
    integer iIndex = llListFindList(lContainer, [(string)kID]);
    if (iIndex == -1)
    {   //owner is not already in list.  add him/her
        lContainer += [(string)kID, sName];
    }
    else
    {   //owner is already in list.  just replace the name
        lContainer = llListReplaceList(lContainer, [sName], iIndex + 1, iIndex + 1);
    }

    if (kID != g_kWearer)
    {
        Notify(g_kWearer, "Added " + sName + " to " + sType + ".", FALSE);
        if (sType == "owner")
        {
            Notify(g_kWearer, "Your owner can have a lot  power over you and you consent to that by making them your owner on your collar. They can leash you, put you in poses, lock your collar, see your location and what you say in local chat.  If you are using RLV they can  undress you, make you wear clothes, restrict your  chat, IMs and TPs as well as force TP you anywhere they like. Please read the help for more info. If you do not consent, you can use the command \"" + g_sPrefix + "runaway\" to remove all owners from the collar.", FALSE);
        }
    }

    if (sType == "owner" || sType == "secowner") Notify(kID, "You have been added to the " + sType + " list on " + llKey2Name(g_kWearer) + "'s collar.\nFor help concerning the collar usage either say \"" + g_sPrefix + "help\" in chat or go to " + g_sWikiURL + " .",FALSE);
    return lContainer;
}

NewPerson(key kID, string sName, string sType)
{//adds new owner, secowner, or blacklisted, as determined by type.
    if (sType == "owner")
    {
        g_lOwners = AddUniquePerson(g_lOwners, kID, sName, g_sRequestType);
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sOwnersToken + "=" + llDumpList2String(g_lOwners, ","), "");
        //added for attachment interface to announce owners have changed
	sendToAttachmentInterface("OwnerChange");
    }
    else if (sType == "secowner")
    {
        g_lSecOwners = AddUniquePerson(g_lSecOwners, kID, sName, g_sRequestType);
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSecOwnersToken + "=" + llDumpList2String(g_lSecOwners, ","), "");
        //added for attachment interface to announce owners have changed
	sendToAttachmentInterface("OwnerChange");
    }
    else if (sType == "blacklist")
    {
        g_lBlackList = AddUniquePerson(g_lBlackList, kID, sName, g_sRequestType);
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sBlackListToken + "=" + llDumpList2String(g_lBlackList, ","), "");
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    //key generation
    //just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sOut;
    integer n;
    for (n = 0; n < 8; ++n)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString( "0123456789abcdef", iIndex, iIndex);
    }
    key kID = (sOut + "-0000-0000-0000-000000000000");
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
        + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

Name2Key(string sFormattedName)
{   //formatted name is firstname+lastname
    g_kHTTPID = llHTTPRequest("http://w-hat.com/name2key?terse=1&name=" + sFormattedName, [HTTP_METHOD, "GET"], "");
}

AuthMenu(key kAv, integer iAuth)
{
    string sPrompt = "Pick an option.";
    list lButtons = [g_sSetOwner, g_sSetSecOwner, g_sSetBlackList, g_sRemOwner, g_sRemSecOwner, g_sRemBlackList];

    if (g_kGroup=="") lButtons += [g_sSetGroup];    //set group
    else lButtons += [g_sUnsetGroup];    //unset group

    if (g_iOpenAccess) lButtons += [g_sUnsetOpenAccess];    //set open access
    else lButtons += [g_sSetOpenAccess];    //unset open access

    if (g_iLimitRange) lButtons += [g_sUnsetLimitRange];    //set ranged
    else lButtons += [g_sSetLimitRange];    //unset open ranged

    lButtons += [g_sReset];

    //list owners
    lButtons += [g_sListOwners];

    g_kAuthMenuID = Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

RemPersonMenu(key kID, list lPeople, string sType, integer iAuth)
{
    g_sRequestType = sType;
    string sPrompt = "Choose the person to remove.";
    list lButtons;
    //build a button list with the dances, and "More"
    //get number of secowners
    integer iNum= llGetListLength(lPeople);
    integer n;
    for (n=1; n <= iNum/2; n = n + 1)
    {
        string sName = llList2String(lPeople, 2*n-1);
        if (sName != "")
        {
            sPrompt += "\n" + (string)(n) + " - " + sName;
            lButtons += [(string)(n)];
        }
    }
    lButtons += ["Remove All"];

    g_kSensorMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

integer in_range(key kID) {
    if (g_iLimitRange) {
        integer range = 20;
        vector kAvpos = llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0);
        if (llVecDist(llGetPos(), kAvpos) > range) {
            //llOwnerSay(llKey2Name(kID) + " is not in range...");
            llDialog(kID, "\n\nNot in range...", [], 298479);
            return FALSE;
        }
        else {
            //llOwnerSay(llKey2Name(kID) + " In range...");
            return TRUE;
        }
    }
    else {
        return TRUE;
    }
}

integer Auth(string kObjID, integer attachment)
{
    string kID = (string)llGetOwnerKey(kObjID); // if kObjID is an avatar key, then kID is the same key
    integer iNum;
    if (g_iWearerlocksOut && kID == (string)g_kWearer && !attachment)
    {
        iNum = COMMAND_WEARERLOCKEDOUT;
    }
    else if (~llListFindList(g_lOwners, [(string)kID]))
    {
        iNum = COMMAND_OWNER;
    }
    else if (llGetListLength(g_lOwners) == 0 && kID == (string)g_kWearer)
    {
        //if no owners set, then wearer's cmds have owner auth
        iNum = COMMAND_OWNER;
    }
    else if (~llListFindList(g_lBlackList, [(string)kID]))
    {
        iNum = COMMAND_BLACKLIST;
    }
    else if (~llListFindList(g_lSecOwners, [(string)kID]))
    {
        iNum = COMMAND_SECOWNER;
    }
    else if (kID == (string)g_kWearer)
    {
        iNum = COMMAND_WEARER;
    }
    else if (g_iOpenAccess)
    {
        if (in_range((key)kID))
            iNum = COMMAND_GROUP;
        else
            iNum = COMMAND_EVERYONE;
    }
    else if (g_iGroupEnabled && (string)llGetObjectDetails((key)kObjID, [OBJECT_GROUP]) == (string)g_kGroup && (key)kID != g_kWearer)
    {//meaning that the command came from an object set to our control group, and is not owned by the wearer
        iNum = COMMAND_GROUP;
    }
    else if (llSameGroup(kID) && g_iGroupEnabled && kID != (string)g_kWearer)
    {
        if (in_range((key)kID))
            iNum = COMMAND_GROUP;
        else
            iNum = COMMAND_EVERYONE;

    }
    else
    {
        iNum = COMMAND_EVERYONE;
    }
    return iNum;
}

list RemovePerson(list lPeople, string sName, string sToken, key kCmdr)
{
    //where "lPeople" is a 2-strided list in form key,name
    //looks for strides identified by "name", removes them if found, and returns the list
    //also handles notifications so as to reduce code duplication in the link message event
    Debug("removing: " + sName);
    //all our comparisons will be cast to lower case first
    sName = llToLower(sName);
    integer iChange = FALSE;
    integer n;
    key kRemovedPerson;
    //loop from the top and work down, so we don't skip when we remove things
    for (n = llGetListLength(lPeople) - 1; n >= 0; n = n - 2)
    {
        string sThisName = llToLower(llList2String(lPeople, n));
        Debug("checking " + sThisName);
        if (sName == sThisName)
        {   //remove name and key
            kRemovedPerson=llList2String(lPeople,n - 1);
            lPeople = llDeleteSubList(lPeople, n - 1, n);
            iChange = TRUE;
        }
    }

    if (iChange)
    {
        if (sToken == g_sOwnersToken || sToken == g_sSecOwnersToken)
        {// is it about owners?
            if (kRemovedPerson!=g_kWearer)
                // if it isnt the wearer, we are nice and notify them
            {
                if (sToken == g_sOwnersToken)
                {
                    Notify(kRemovedPerson,"You have been removed as owner on the collar of " + llKey2Name(g_kWearer) + ".",FALSE);
                }
                else
                {
                    Notify(kRemovedPerson,"You have been removed as secowner on the collar of " + llKey2Name(g_kWearer) + ".",FALSE);
                }
            }
            //whisper to attachments about owner and secowner changes
	    sendToAttachmentInterface("OwnerChange");
        }
        //save to db
        if (llGetListLength(lPeople)>0)
        {
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, sToken + "=" + llDumpList2String(lPeople, ","), "");
        }
        else
        {
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, sToken, "");
        }
        Notify(kCmdr, sName + " removed from list.", TRUE);
    }
    else
    {
        Notify(kCmdr, "Error: '" + sName + "' not in list.",FALSE);
    }
    return lPeople;
}

integer isKey(string sIn) {
    if ((key)sIn) return TRUE;
    return FALSE;
}

integer OwnerCheck(key kID)
{//checks whether id has owner auth.  returns TRUE if so, else notifies person that they don't have that power
    //used in menu processing for when a non owner clicks an owner-only button
    if (Auth((string)kID, FALSE) == COMMAND_OWNER)
    {
        return TRUE;
    }
    else
    {
        Notify(kID, "Sorry, only an owner can do that.", FALSE);
        return FALSE;
    }
}

NotifyInList(list lStrideList, string sOwnerType)
{
    integer i;
    integer l=llGetListLength(lStrideList);
    key k;
    string sSubName = llKey2Name(g_kWearer);
    for (i = 0; i < l; i = i +2)
    {
        k = (key)llList2String(lStrideList,i);
        if (k != g_kWearer)
        {
            Notify(k,"You have been removed as " + sOwnerType + " on the collar of " + sSubName + ".",FALSE);
        }
    }
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check
    if (sStr == "menu "+g_sSubMenu)
    {
        AuthMenu(kID, iNum);
    }
    else if (sStr == "settings" || sStr == "listowners")
    {   //say owner, secowners, group
        if (iNum == COMMAND_OWNER || kID == g_kWearer)
        {
            //Do Owners list
            integer n;
            integer iLength = llGetListLength(g_lOwners);
            string sOwners;
            for (n = 0; n < iLength; n = n + 2)
            {
                sOwners += "\n" + llList2String(g_lOwners, n + 1) + " (" + llList2String(g_lOwners, n) + ")";
            }
            Notify(kID, "Owners: " + sOwners,FALSE);

            //Do Secowners list
            iLength = llGetListLength(g_lSecOwners);
            string sSecOwners;
            for (n = 0; n < iLength; n = n + 2)
            {
                sSecOwners += "\n" + llList2String(g_lSecOwners, n + 1) + " (" + llList2String(g_lSecOwners, n) + ")";
            }
            Notify(kID, "Secowners: " + sSecOwners,FALSE);
            iLength = llGetListLength(g_lBlackList);
            string sBlackList;
            for (n = 0; n < iLength; n = n + 2)
            {
                sBlackList += "\n" + llList2String(g_lBlackList, n + 1) + " (" + llList2String(g_lBlackList, n) + ")";
            }
            Notify(kID, "Black List: " + sBlackList,FALSE);
            Notify(kID, "Group: " + g_sGroupName,FALSE);
            Notify(kID, "Group Key: " + (string)g_kGroup,FALSE);
            string sVal; if (g_iOpenAccess) sVal="true"; else sVal="false";
            Notify(kID, "Open Access: "+ sVal,FALSE);
            string sValr; if (g_iLimitRange) sValr="true"; else sValr="false";
            Notify(kID, "LimitRange: "+ sValr,FALSE);
        }
        else if (sStr == "listowners")
        {
            Notify(kID, "Sorry, you are not allowed to see the owner list.",FALSE);
        }
    }
    else if (sStr == "owners")
    {   //give owner menu
        AuthMenu(kID, iNum);
    }
    else if (iNum == COMMAND_OWNER)
    { //respond to messages to set or unset owner, group, or secowners.  only owner may do these things
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llList2String(lParams, 0);
        if (sCommand == "owner")
        { //set a new owner.  use w-hat sName2key service.  benefits: not case sensitive, and owner need not be present
            //if no owner at all specified:
            if (llList2String(lParams, 1) == "")
            {
                AuthMenu(kID, iNum);
                return TRUE;
            }
            g_sRequestType = "owner";
            //pop the command off the param list, leaving only first and last name
            lParams = llDeleteSubList(lParams, 0, 0);
            //record owner name
            g_sTmpName = llDumpList2String(lParams, " ");
            //sensor for the owner name to get the key or set the owner directly if it is the wearer
            if(llToLower(g_sTmpName) == llToLower(llKey2Name(g_kWearer)))
            {
                NewPerson(g_kWearer, g_sTmpName, "owner");
            }
            else
            {
                g_kDialoger = kID;
                g_iDialogerAuth = iNum;
                llSensor("","", AGENT, 20.0, PI);
            }
        }
        else if (sCommand == "remowners")
        { //remove secowner, if in the list
            g_sRequestType = "";//Nan: this used to be set to "remowners" but that NEVER gets filtered on elsewhere in the script.  Just clearing it now in case later filtering relies on it being cleared.  I hate this g_sRequestType variable with a passion
            //pop the command off the param list, leaving only first and last name
            lParams = llDeleteSubList(lParams, 0, 0);
            //name of person concerned
            g_sTmpName = llDumpList2String(lParams, " ");
            if (g_sTmpName=="")
            {
                RemPersonMenu(kID, g_lOwners, "remowners", iNum);
            }
            else if(llToLower(g_sTmpName) == "remove all")
            {
                Notify(kID, "Removing of all owners started!",TRUE);

                NotifyInList(g_lOwners, g_sOwnersToken);

                g_lOwners = [];
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sOwnersToken, "");
                Notify(kID, "Everybody was removed from the owner list!",TRUE);
            }
            else
            {
                g_lOwners = RemovePerson(g_lOwners, g_sTmpName, g_sOwnersToken, kID);
            }
        }
        else if (sCommand == "secowner")
        { //set a new secowner
            g_sRequestType = "secowner";
            //pop the command off the param list, leaving only first and last name
            lParams = llDeleteSubList(lParams, 0, 0);
            //record owner name
            g_sTmpName = llDumpList2String(lParams, " ");
            if (g_sTmpName=="")
            {
                g_sRequestType = g_sSecOwnerScan;
                g_kDialoger = kID;
                g_iDialogerAuth = iNum;
                llSensor("", "", AGENT, 10.0, PI);
            }
            else if (llGetListLength(g_lSecOwners) == 20)
            {
                Notify(kID, "The maximum of 10 secowners is reached, please clean up or use SetGroup",FALSE);
            }
            else
            {//sensor for the owner name to get the key or set the owner directly if it is the wearer
                if(llToLower(g_sTmpName) == llToLower(llKey2Name(g_kWearer)))
                {
                    NewPerson(g_kWearer, g_sTmpName, "secowner");
                }
                else
                {
                    g_kDialoger = kID;
                    g_iDialogerAuth = iNum;
                    llSensor("","", AGENT, 20.0, PI);
                }
            }
        }
        else if (sCommand == "remsecowner")
        { //remove secowner, if in the list
            g_sRequestType = "";
            //g_sRequestType = "remsecowner";//Nan: we never parse on g_sRequestType == g_sRemSecOwner, so this makes little sense
            //pop the command off the param list, leaving only first and last name
            lParams = llDeleteSubList(lParams, 0, 0);
            //name of person concerned
            g_sTmpName = llDumpList2String(lParams, " ");
            if (g_sTmpName=="")
            {
                RemPersonMenu(kID, g_lSecOwners, "remsecowner", iNum);
            }
            else if(llToLower(g_sTmpName) == "remove all")
            {
                Notify(kID, "Removing of all secowners started!",TRUE);

                NotifyInList(g_lSecOwners, g_sSecOwnersToken);

                g_lSecOwners = [];
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "secowners", "");
                Notify(kID, "Everybody was removed from the secondary owner list!",TRUE);
            }
            else
            {
                g_lSecOwners = RemovePerson(g_lSecOwners, g_sTmpName, g_sSecOwnersToken, kID);
            }
        }
        else if (sCommand == "blacklist")
        { //blackList an avatar
            g_sRequestType = "blacklist";
            //pop the command off the param list, leaving only first and last name
            lParams = llDeleteSubList(lParams, 0, 0);
            //record blacklisted name
            g_sTmpName = llDumpList2String(lParams, " ");
            if (g_sTmpName=="")
            {
                g_sRequestType = g_sBlackListScan;
                g_kDialoger = kID;
                g_iDialogerAuth = iNum;
                llSensor("", "", AGENT, 10.0, PI);
            }
            else if (llGetListLength(g_lBlackList) == 20)
            {
                Notify(kID, "The maximum of 10 blacklisted is reached, please clean up.",FALSE);
            }
            else
            {   //sensor for the blacklisted name to get the key
                g_kDialoger = kID;
                g_iDialogerAuth = iNum;
                llSensor("","", AGENT, 20.0, PI);
            }
        }
        else if (sCommand == "remblacklist")
        { //remove blacklisted, if in the list
            g_sRequestType = "";
            //g_sRequestType = "remblacklist";//Nan: we never filter on g_sRequestType == "remblacklist", so this makes no sense.
            //pop the command off the param list, leaving only first and last name
            lParams = llDeleteSubList(lParams, 0, 0);
            //name of person concerned
            g_sTmpName = llDumpList2String(lParams, " ");
            if (g_sTmpName=="")
            {
                RemPersonMenu(kID, g_lBlackList, "remblacklist", iNum);
            }
            else if(llToLower(g_sTmpName) == "remove all")
            {
                g_lBlackList = [];
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sBlackListToken, "");
                Notify(kID, "Everybody was removed from black list!", TRUE);
            }
            else
            {
                g_lBlackList = RemovePerson(g_lBlackList, g_sTmpName, g_sBlackListToken, kID);
            }
        }
        else if (sCommand == "setgroup")
        {
            g_sRequestType = "group";
            //if no arguments given, use current group, else use key provided
            if (isKey(llList2String(lParams, 1)))
            {
                g_kGroup = (key)llList2String(lParams, 1);
            }
            else
            {
                //record current group key
                g_kGroup = (key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0);
            }

            if (g_kGroup != "")
            {
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "group=" + (string)g_kGroup, "");
                g_iGroupEnabled = TRUE;
                g_kDialoger = kID;
                g_iDialogerAuth = iNum;
                //get group name from
                g_kGroupHTTPID = llHTTPRequest("http://world.secondlife.com/group/" + (string)g_kGroup, [], "");
            }
            if(g_iRemenu)
            {
                g_iRemenu = FALSE;
                AuthMenu(kID, iNum);
            }
        }
        else if (sCommand == "setgroupname")
        {
            g_sGroupName = llDumpList2String(llList2List(lParams, 1, -1), " ");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "groupname=" + g_sGroupName, "");
        }
        else if (sCommand == "unsetgroup")
        {
            g_kGroup = "";
            g_sGroupName = "";
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "group", "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "groupname", "");
            g_iGroupEnabled = FALSE;
            Notify(kID, "Group unset.", FALSE);
            if(g_iRemenu)
            {
                g_iRemenu = FALSE;
                AuthMenu(kID, iNum);
            }
            //added for attachment interface to announce owners have changed
	    sendToAttachmentInterface("OwnerChange");
        }
        else if (sCommand == "setopenaccess")
        {
            g_iOpenAccess = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "openaccess=" + (string) g_iOpenAccess, "");
            Notify(kID, "Open access set.", FALSE);
            if(g_iRemenu)
            {
                g_iRemenu = FALSE;
                AuthMenu(kID, iNum);
            }
	    sendToAttachmentInterface("OwnerChange");
        }
        else if (sCommand == "unsetopenaccess")
        {
            g_iOpenAccess = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "openaccess", "");
            Notify(kID, "Open access unset.", FALSE);
            if(g_iRemenu)
            {
                g_iRemenu = FALSE;
                AuthMenu(kID, iNum);
            }
            //added for attachment interface to announce owners have changed
	    sendToAttachmentInterface("OwnerChange");
        }
        else if (sCommand == "setlimitrange")
        {
            g_iLimitRange = TRUE;
            // as the default is range limit on, we do not need to store anything for this
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "limitrange", "");
            Notify(kID, "Range limited set.", FALSE);
            if(g_iRemenu)
            {
                g_iRemenu = FALSE;
                AuthMenu(kID, iNum);
            }
        }
        else if (sCommand == "unsetlimitrange")
        {
            g_iLimitRange = FALSE;
            // save off state for limited range (default is on)
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "limitrange=" + (string) g_iLimitRange, "");
            Notify(kID, "Range limited unset.", FALSE);
            if(g_iRemenu)
            {
                g_iRemenu = FALSE;
                AuthMenu(kID, iNum);
            }
        }
        else if (sCommand == "reset")
        {
            llResetScript();
        }
    }
    return TRUE;
}

default
{
    state_entry()
    {   //until set otherwise, wearer is owner
        Debug((string)llGetFreeMemory());
        g_kWearer = llGetOwner();
        list sName = llParseString2List(llKey2Name(g_kWearer), [" "], []);
        g_sPrefix = llToLower(llGetSubString(llList2String(sName, 0), 0, 0)) + llToLower(llGetSubString(llList2String(sName, 1), 0, 0));
        //added for attachment auth
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;

        // Request owner list.  Be careful about doing this in all scripts,
        // because we can easily flood the 64 event limit in LSL's event queue
        // if all the scripts send a ton of link messages at the same time on
        // startup.
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sOwnersToken, "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sSecOwnersToken, "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, g_sBlackListToken, "");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {  //authenticate messages on COMMAND_NOAUTH
        if (iNum == COMMAND_NOAUTH)
        {
            integer iAuth = Auth((string)kID, FALSE);
            if ((iNum == COMMAND_OWNER || kID == g_kWearer) && (sStr=="reset"))
            {
                Notify(kID, "The command 'reset' is deprecated. Please use 'runaway' to leave the owner and clear all settings or 'resetscripts' to only reset the script in the collar.", FALSE);
            }
            else if ((iAuth == COMMAND_OWNER || kID == g_kWearer) && sStr == "runaway")
            {   // note that this will work *even* if the wearer is blacklisted or locked out
                // otherwise forbid anybody who is not the wearer or primary owner
                Notify(g_kWearer, "Running away from all owners started, your owners will now be notified!",FALSE);
                integer n;
                integer stop = llGetListLength(g_lOwners);
                for (n = 0; n < stop; n += 2)
                {
                    key kOwner = (key)llList2String(g_lOwners, n);
                    if (kOwner != g_kWearer)
                    {
                        Notify(kOwner, llKey2Name(g_kWearer) + " has run away!",FALSE);
                    }
                }
                Notify(g_kWearer, "Runaway finished, the collar will now reset!",FALSE);
                // moved reset request from settings to here to allow noticifation of owners.
                llMessageLinked(LINK_SET, COMMAND_OWNER, "runaway", kID); // this is not a LM loop, since it is now really authed
                llMessageLinked(LINK_SET, COMMAND_OWNER, "resetscripts", kID);
                // notice the order is important: first "runaway" -> clears settings, then only other scripts are reset and may query their settings
                llResetScript();
            }
            else
            {
                llMessageLinked(LINK_SET, iAuth, sStr, kID);
            }

            Debug("noauth: " + sStr + " from " + (string)kID + " who has auth " + (string)iAuth);
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sOwnersToken)
            {
                // temporarily stash owner list so we can see if it's changing.
                list tmpowners = g_lOwners;
                g_lOwners = llParseString2List(sValue, [","], []);

                // only say the owner list if it has changed.  This includes on
                // rez, since we reset (and therefore blank the owner list) on
                // rez.
                if (llGetListLength(g_lOwners) && tmpowners != g_lOwners) {
                    SayOwners();
                }
            }
            else if (sToken == "group")
            {
                g_kGroup = (key)sValue;
                //check to see if the object's group is set properly
                if (g_kGroup != "")
                {
                    if ((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]), 0) == g_kGroup)
                    {
                        g_iGroupEnabled = TRUE;
                    }
                    else
                    {
                        g_iGroupEnabled = FALSE;
                    }
                }
                else
                {
                    g_iGroupEnabled = FALSE;
                }
            }
            else if (sToken == "groupname")
            {
                g_sGroupName = sValue;
            }
            else if (sToken == "openaccess")
            {
                g_iOpenAccess = (integer)sValue;
            }
            else if (sToken == "limitrange")
            {
                g_iLimitRange = (integer)sValue;
            }
            else if (sToken == "secowners")
            {
                g_lSecOwners = llParseString2List(sValue, [","], [""]);
            }
            else if (sToken == "blacklist")
            {
                g_lBlackList = llParseString2List(sValue, [","], [""]);
            }
            else if (sToken == "prefix")
            {
                g_sPrefix = sValue;
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == COMMAND_SAFEWORD)
        {
            string sSubName = llKey2Name(g_kWearer);
            string sSubFirstName = llList2String(llParseString2List(sSubName, [" "], []), 0);
            integer n;
            integer iStop = llGetListLength(g_lOwners);
            for (n = 0; n < iStop; n += 2)
            {
                key kOwner = (key)llList2String(g_lOwners, n);
                Notify(kOwner, "Your sub " + sSubName + " has used the safeword. Please check on " + sSubFirstName +"'s well-being and if further care is required.",FALSE);
            }
            //added for attachment interface (Garvin)
	    sendToAttachmentInterface("safeword");
        }
        //added for attachment auth (Garvin)
        else if (iNum == ATTACHMENT_REQUEST)
        {
            integer iAuth = Auth((string)kID, TRUE);
            llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, (string)iAuth, kID);
        }
        else if (iNum == WEARERLOCKOUT)
        {
            if (sStr == "on")
            {
                g_iWearerlocksOut=TRUE;
                Debug("locksOuton");
            }
            else if (sStr == "off")
            {
                g_iWearerlocksOut=FALSE;
                Debug("lockoutoff");
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (llListFindList([g_kAuthMenuID, g_kSensorMenuID], [kID]) != -1)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (kID == g_kAuthMenuID)
                {
                    //g_kAuthMenuID responds to setowner, setsecowner, setblacklist, remowner, remsecowner, remblacklist
                    //setgroup, unsetgroup, setopenaccess, unsetopenaccess
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                        return;
                    }
                    else if (sMessage == g_sSetOwner)
                    {
                        if (OwnerCheck(kAv))
                        {
                            g_sRequestType = g_sOwnerScan;
                            g_kDialoger = kAv;
                            g_iDialogerAuth = iAuth;
                            llSensor("", "", AGENT, 10.0, PI);
                            return;
                        }
                    }
                    else if (sMessage == g_sSetSecOwner)
                    {
                        if (OwnerCheck(kAv))
                        {
                            g_sRequestType = g_sSecOwnerScan;
                            g_kDialoger = kAv;
                            g_iDialogerAuth = iAuth;
                            llSensor("", "", AGENT, 10.0, PI);
                            return;
                        }
                    }
                    else if (sMessage == g_sSetBlackList)
                    {
                        if (OwnerCheck(kAv))
                        {
                            g_sRequestType = g_sBlackListScan;
                            g_kDialoger = kAv;
                            g_iDialogerAuth = iAuth;
                            llSensor("", "", AGENT, 10.0, PI);
                            return;
                        }
                    }
                    else if (sMessage == g_sRemOwner)
                    {
                        if (OwnerCheck(kAv))
                        {
                            RemPersonMenu(kAv, g_lOwners, "remowners", iAuth);
                            return;
                        }
                    }
                    else if (sMessage == g_sRemSecOwner)
                    {   //popup list of secowner if owner clicked
                        if (OwnerCheck(kAv))
                        {
                            RemPersonMenu(kAv, g_lSecOwners, "remsecowner", iAuth);
                            return;
                        }
                    }
                    else if (sMessage == g_sRemBlackList)
                    {   //popup list of secowner if owner clicked
                        if (OwnerCheck(kAv))
                        {
                            RemPersonMenu(kAv, g_lBlackList, "remblacklist", iAuth);
                            return;
                        }
                    }
                    else if (sMessage == g_sSetGroup)
                        UserCommand(iAuth, "setgroup", kAv);
                    else if (sMessage == g_sUnsetGroup)
                        UserCommand(iAuth, "unsetgroup", kAv);
                    else if (sMessage == g_sSetOpenAccess)
                        UserCommand(iAuth, "setopenaccess", kAv);
                    else if (sMessage == g_sUnsetOpenAccess)
                        UserCommand(iAuth, "unsetopenaccess", kAv);
                    else if (sMessage == g_sSetLimitRange)
                        UserCommand(iAuth, "setlimitrange", kAv);
                    else if (sMessage == g_sUnsetLimitRange)
                        UserCommand(iAuth, "unsetlimitrange", kAv);
                    else if (sMessage == g_sListOwners)
                        UserCommand(iAuth, "listowners", kAv);
                    else if (sMessage == g_sReset)
                    { // separate routine
                        llMessageLinked(LINK_SET, COMMAND_NOAUTH, "runaway", kAv);
                    }
                    AuthMenu(kAv, iAuth);
                }
                else if (kID == g_kSensorMenuID)
                {
                    if (sMessage != UPMENU)
                    {
                        if (sMessage == "Remove All")
                        {
                            if (OwnerCheck(kAv))
                            {
                                //g_sRequestType should be g_sRemOwner, g_sRemSecOwner, or g_sRemBlackList
                                UserCommand(iAuth, g_sRequestType + " Remove All", kAv);
                            }
                        }
                        else if (llGetSubString(g_sRequestType,0,2) == "rem")
                        {
                            if (OwnerCheck(kAv))
                            {
                                //build a chat command to send to remove the person
                                string sCmd = g_sRequestType;
                                //convert the menu button number to a name
                                if (g_sRequestType == "remowners")
                                {
                                    sCmd += " " + llList2String(g_lOwners, (integer)sMessage*2 - 1);
                                }
                                else if(g_sRequestType == "remsecowner")
                                {
                                    sCmd += " " + llList2String(g_lSecOwners, (integer)sMessage*2 - 1);
                                }
                                else if(g_sRequestType == "remblacklist")
                                {
                                    sCmd += " " + llList2String(g_lBlackList, (integer)sMessage*2 - 1);
                                }
                                UserCommand(iAuth, sCmd, kAv);
                            }
                        }
                        else if(g_sRequestType == g_sOwnerScan)
                        {
                            UserCommand(iAuth, "owner " + sMessage, kAv);
                        }
                        else if(g_sRequestType == g_sSecOwnerScan)
                        {
                            UserCommand(iAuth, "secowner " + sMessage, kAv);
                        }
                        else if(g_sRequestType == g_sBlackListScan)
                        {
                            UserCommand(iAuth, "blacklist " + sMessage, kAv);
                        }
                    }
                    AuthMenu(kAv, iAuth);
                }
            }

        }
    }

    sensor(integer iNum_detected)
    {
        if(g_sRequestType == "owner" || g_sRequestType == "secowner" || g_sRequestType == "blacklist")
        {
            integer i;
            integer iFoundAvi = FALSE;
            for (i = 0; i < iNum_detected; i++)
            {//see if sensor picked up person with name we were given in chat command (g_sTmpName).  case insensitive
                if(llToLower(g_sTmpName) == llToLower(llDetectedName(i)))
                {
                    iFoundAvi = TRUE;
                    NewPerson(llDetectedKey(i), llDetectedName(i), g_sRequestType);
                    i = iNum_detected;//a clever way to jump out of the loop.  perhaps too clever?
                }
            }
            if(!iFoundAvi)
            {
                if(g_sTmpName == llKey2Name(g_kWearer))
                {
                    NewPerson(g_kWearer, llKey2Name(g_kWearer), g_sRequestType);
                }
                else
                {
                    list lTemp = llParseString2List(g_sTmpName, [" "], []);
                    Name2Key(llDumpList2String(lTemp, "+"));
                }
            }
        }
        else if(g_sRequestType == g_sOwnerScan || g_sRequestType == g_sSecOwnerScan || g_sRequestType == g_sBlackListScan)
        {
            list lButtons;
            string sName;
            integer i;

            for(i = 0; i < iNum_detected; i++)
            {
                sName = llDetectedName(i);
		//actual label length is taken care of by dialog helper
                lButtons += [sName];
            }
            //add wearer if not already in button list
            sName = llKey2Name(g_kWearer);
            if (llListFindList(lButtons, [sName]) == -1)
            {
                lButtons = [sName] + lButtons;
            }
            if (llGetListLength(lButtons) > 0)
            {
                string sText = "Select who you would like to add.\nIf the one you want to add does not show, move closer and repeat or use the chat command.";
                g_kSensorMenuID = Dialog(g_kDialoger, sText, lButtons, [UPMENU], 0, g_iDialogerAuth);
            }
        }
    }

    no_sensor()
    {
        if(g_sRequestType == "owner" || g_sRequestType == "secowner" || g_sRequestType == "blacklist")
        {
            //reformat name with + in place of spaces
            Name2Key(llDumpList2String(llParseString2List(g_sTmpName, [" "], []), "+"));
        }
        else if(g_sRequestType == g_sOwnerScan || g_sRequestType == g_sSecOwnerScan || g_sRequestType == g_sBlackListScan)
        {
            Notify(g_kDialoger, "Nobody is in 10m range to be shown, either move closer or use the chat command to add someone who is not with you at this moment or offline.",FALSE);
        }
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    http_response(key kID, integer iStatus, list lMeta, string sBody)
    {
        if (kID == g_kHTTPID)
        {   //here's where we add owners or secowners, after getting their keys
            if (iStatus == 200)
            {
                Debug(sBody);
                if (isKey(sBody))
                {
                    NewPerson((key)sBody, g_sTmpName, g_sRequestType);//g_sRequestType will be owner, secowner, or blacklist
                }
                else
                {
                    Notify(g_kDialoger, "Error: unable to retrieve key for '" + g_sTmpName + "'.", FALSE);
                }
            }
        }
        else if (kID == g_kGroupHTTPID)
        {
            g_sGroupName = "X";
            if (iStatus == 200)
            {
                integer iPos = llSubStringIndex(sBody, "<title>");
                integer iPos2 = llSubStringIndex(sBody, "</title>");
                if ((~iPos) // Found
                    && iPos2 > iPos // Has to be after it
                    && iPos2 <= iPos + 43 // 36 characters max (that's 7+36 because <title> has 7)
                    && !~llSubStringIndex(sBody, "AccessDenied") // Check as per groupname.py (?)
                   )
                {
                    g_sGroupName = llGetSubString(sBody, iPos + 7, iPos2 - 1);
                }
            }

            if (g_sGroupName == "X")
            {
                Notify(g_kDialoger, "Group set to (group name hidden).", FALSE);
            }
            else
            {
                Notify(g_kDialoger, "Group set to " + g_sGroupName, FALSE);
            }
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "groupname=" + g_sGroupName, "");
        }
    }
}