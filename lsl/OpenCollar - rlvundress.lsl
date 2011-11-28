//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//give 3 menus:
//Clothing
//Attachment
//Folder

string g_sSubMenu = "Un/Dress";
string g_sParentMenu = "RLV";

list g_lChildren = ["Rem Clothing","Rem Attachment"]; //,"LockClothing","LockAttachment"];//,"LockClothing","UnlockClothing"];
list g_sSubMenus= [];
string SELECT_CURRENT = "*InFolder";
string SELECT_RECURS= "*Recursively";
list g_lRLVcmds = ["attach","detach","remoutfit", "addoutfit","remattach","addattach"];

list g_lSettings;//2-strided list in form of [option, param]


list LOCK_CLOTH_POINTS = [
    "Gloves",
    "Jacket",
    "Pants",
    "Shirt",
    "Shoes",
    "Skirt",
    "Socks",
    "Underpants",
    "Undershirt",
    "Skin",
    "Eyes",
    "Hair",
    "Shape",
    "Alpha",
    "Tattoo",
    "Physics"
        ];


list DETACH_CLOTH_POINTS = [
    "Gloves",
    "Jacket",
    "Pants",
    "Shirt",
    "Shoes",
    "Skirt",
    "Socks",
    "Underpants",
    "Undershirt",
    "xx", //"skin", those are not to be detached, so we ignore them later
    "xx", //"eyes", those are not to be detached, so we ignore them later
    "xx", //"hair", those are not to be detached, so we ignore them later
    "xx", //"shape", those are not to be detached, so we ignore them later
    "Alpha",
    "Tattoo",
    "Physics"
        ];

list ATTACH_POINTS = [//these are ordered so that their indices in the list correspond to the numbers returned by llGetAttached
    "None",
    "Chest",
    "Skull",
    "Left Shoulder",
    "Right Shoulder",
    "Left Hand",
    "Right Hand",
    "Left Foot",
    "Right Foot",
    "Spine",
    "Pelvis",
    "Mouth",
    "Chin",
    "Left Ear",
    "Right Ear",
    "Left Eyeball",
    "Right Eyeball",
    "Nose",
    "R Upper Arm",
    "R Forearm",
    "L Upper Arm",
    "L Forearm",
    "Right Hip",
    "R Upper Leg",
    "R Lower Leg",
    "Left Hip",
    "L Upper Leg",
    "L Lower Leg",
    "Stomach",
    "Left Pec",
    "Right Pec",
    "Center 2",
    "Top Right",
    "Top",
    "Top Left",
    "Center",
    "Bottom Left",
    "Bottom",
    "Bottom Right",
    "Neck",
    "Avatar Center"
        ];

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer CHAT = 505;

integer POPUP_HELP = 1001;

integer HTTPDB_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer HTTPDB_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer HTTPDB_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer HTTPDB_DELETE = 2003;//delete token from DB
integer HTTPDB_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed


integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;


string UPMENU = "^";

string ALL = "*All*";
string TICKED = "(*)";
string UNTICKED = "( )";

//variables for storing our various dialog ids
key g_kMainID;
key g_kClothID;
key g_kAttachID;
key g_kLockID;
key g_kLockAttachID;

integer g_iRLVTimeOut = 60;

integer g_iClothRLV = 78465;
integer g_iAttachRLV = 78466;
integer g_iListener;
key g_kMenuUser;

string g_sDBToken = "undress";
string g_sDBTokenLockAll = "DressAllLocked";
integer g_iRemenu = FALSE;

integer g_iRLVOn = FALSE;

list g_lLockedItems; // list of locked clothes
list g_lLockedAttach; // list of locked attachmemts

key g_kWearer;
string g_sWearerName;
integer g_iAllLocked = 0;  //1=all clothes are locked on

integer g_iLastAuth; //last auth level

Debug(string sMsg)
{
    //llOwnerSay(llGetScriptName() + ": " + sMsg);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

key ShortKey()
{//just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sChars = "0123456789abcdef";
    integer iLength = 16;
    string sOut;
    integer n;
    for (n = 0; n < 8; n++)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString(sChars, iIndex, iIndex);
    }

    return (key)(sOut + "-0000-0000-0000-000000000000");
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage)
{
    key kID = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    return kID;
}

MainMenu(key kID)
{
    string sPrompt = "Pick an option.";
    list lButtons = g_lChildren;

    if (g_iAllLocked)  //are all clothing and attachements locked?
    {
        sPrompt += "\n all clothes and attachments are currently locked.";
        //skip the LockClothing and the LockAttachment buttons
        lButtons += ["(*)Lock All"];
    }
    else
    {
        lButtons += ["Lock Clothing"];
        lButtons += ["Lock Attachment"];
        lButtons += ["( )Lock All"];
    }
    g_kMainID = Dialog(kID, sPrompt, lButtons+g_sSubMenus, [UPMENU], 0);
}

QueryClothing()
{    //open listener
    g_iListener = llListen(g_iClothRLV, "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_iRLVTimeOut);
    //send rlvcmd
    llMessageLinked(LINK_SET, RLV_CMD, "getoutfit=" + (string)g_iClothRLV, NULL_KEY);
}

ClothingMenu(key kID, string sStr)
{
    //str looks like 0110100001111
    //loop through CLOTH_POINTS, look at chaClothingr of str for each
    //for each 1, add capitalized button
    string sPrompt = "Select an article of clothing to remove.";
    list lButtons = [];
    integer iStop = llGetListLength(DETACH_CLOTH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        integer iWorn = (integer)llGetSubString(sStr, n, n);
        list item = [llList2String(DETACH_CLOTH_POINTS, n)];
        if (iWorn && llListFindList(g_lLockedItems,item) == -1)
        {
            if (llList2String(item,0)!="xx")
                lButtons += item;
        }
    }
    g_kClothID = Dialog(kID, sPrompt, lButtons, ["Attachments", UPMENU], 0);
}

LockMenu(key kID)
{
    g_iRemenu=FALSE;
    string sPrompt = "Select an article of clothing to un/lock.";
    list lButtons;
    if (llListFindList(g_lLockedItems,[ALL]) == -1)
        lButtons += [UNTICKED+ALL];
    else  lButtons += [TICKED+ALL];

    integer iStop = llGetListLength(LOCK_CLOTH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        string sCloth = llList2String(LOCK_CLOTH_POINTS, n);
        if (llListFindList(g_lLockedItems,[sCloth]) == -1)
            lButtons += [UNTICKED+sCloth];
        else  lButtons += [TICKED+sCloth];
    }
    g_kLockID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0);
}

QueryAttachments()
{    //open listener
    g_iListener = llListen(g_iAttachRLV, "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_iRLVTimeOut);
    //send rlvcmd
    llMessageLinked(LINK_SET, RLV_CMD, "getattach=" + (string)g_iAttachRLV, NULL_KEY);
}

QuerySingleAttachment(string sAttachmetn)
{    //open listener
    integer iChan=g_iAttachRLV + llListFindList(ATTACH_POINTS,[sAttachmetn]) +1;
    if (iChan == g_iAttachRLV) return;
    g_iListener = llListen((iChan), "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_iRLVTimeOut);
    //send rlvcmd
    llMessageLinked(LINK_SET, RLV_CMD, "getattach:"+sAttachmetn+"=" + (string)iChan, NULL_KEY);
}


LockAttachmentMenu(key kID)
{
    g_iRemenu=FALSE;
    string sPrompt = "Select an attachment to un/lock.";
    list lButtons;

    //put tick marks next to locked things
    integer iStop = llGetListLength(ATTACH_POINTS);
    integer n;
    for (n = 1; n < iStop; n++) //starting at 1 as "None" cannot be locked
    {
        string sAttach = llList2String(ATTACH_POINTS, n);
        if (llListFindList(g_lLockedAttach,[sAttach]) == -1)
            lButtons += [UNTICKED+sAttach];
        else  lButtons += [TICKED+sAttach];
    }
    g_kLockAttachID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0);
}

DetachMenu(key kID, string sStr)
{

    //remember not to add button for current object
    //str looks like 0110100001111
    //loop through CLOTH_POINTS, look at char of str for each
    //for each 1, add capitalized button
    string sPrompt = "Select an attachment to remove.";

    //prevent detaching the collar itself
    integer myattachpoint = llGetAttached();

    list lButtons;
    integer iStop = llGetListLength(ATTACH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        if (n != myattachpoint)
        {
            integer iWorn = (integer)llGetSubString(sStr, n, n);
            if (iWorn)
            {
                lButtons += [llList2String(ATTACH_POINTS, n)];
            }
        }
    }
    g_kAttachID = Dialog(kID, sPrompt, lButtons, ["Clothing", UPMENU], 0);
}

UpdateSettings()
{    //build one big string from the settings list
    //llOwnerSay("TP settings: " + llDumpList2String(g_lSettings, ","));
    integer iSettingsLength = llGetListLength(g_lSettings);
    if (iSettingsLength > 0)
    {
        g_lLockedItems=[];
        g_lLockedAttach=[];
        integer n;
        list lNewList;
        for (n = 0; n < iSettingsLength; n = n + 2)
        {
            list sOption=llParseString2List(llList2String(g_lSettings, n),[":"],[]);
            string sValue=llList2String(g_lSettings, n + 1);
            //Debug(llList2String(g_lSettings, n) + "=" + sValue);
            lNewList += [llList2String(g_lSettings, n) + "=" + llList2String(g_lSettings, n + 1)];
            if (llGetListLength(sOption)==2
                && (llList2String(sOption,0)=="addoutfit"
                    ||llList2String(sOption,0)=="remoutfit")
                && sValue=="n")
                g_lLockedItems += [llList2String(sOption,1)];
            if (llGetListLength(sOption)==1 && llList2String(sOption,0)=="remoutfit" && sValue=="n")
                g_lLockedItems += [ALL];

            if (llGetListLength(sOption)==2
                && (llList2String(sOption,0)=="addattach"
                    || llList2String(sOption,0)=="remattach"
                    || llList2String(sOption,0)=="detach")
                && sValue=="n")
                g_lLockedAttach += [llList2String(sOption,1)];
        }
        //output that string to viewer
        llMessageLinked(LINK_SET, RLV_CMD, llDumpList2String(lNewList, ","), NULL_KEY);
    }
}

ClearSettings()
{   //clear settings list
    g_lSettings = [];
    //clear the list of locked items
    g_lLockedItems = [];
    g_lLockedAttach=[];
    SaveLockAllFlag(0);
    //remove tpsettings from DB
    llMessageLinked(LINK_SET, HTTPDB_DELETE, g_sDBToken, NULL_KEY);
    //main RLV script will take care of sending @clear to viewer
}

SaveLockAllFlag(integer iSetting)
{
    if (g_iAllLocked == iSetting)
    {
        return;
    }
    g_iAllLocked = iSetting;
    if(iSetting > 0)
    {
        //save the flag to the database
        llMessageLinked(LINK_SET, HTTPDB_SAVE, g_sDBTokenLockAll+"=Y", NULL_KEY);
    }
    else
    {
        //delete the flag from the database
        llMessageLinked(LINK_SET, HTTPDB_DELETE, g_sDBTokenLockAll, NULL_KEY);
    }
}

DolockAll(string sCommand, key kID)
{
    if (sCommand == "lockall")      //lock all clothes and attachement points
    {
        //do the actual lockall
        llMessageLinked(LINK_SET, RLV_CMD, "addattach=n", kID);
        llMessageLinked(LINK_SET, RLV_CMD, "remattach=n", kID);
        llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit=n", kID);
        llMessageLinked(LINK_SET, RLV_CMD,  "addoutfit=n", kID);
    }
    else  if (sCommand == "unlockall") //lock all clothes and attachment points
    {
        //remove the lockall
        llMessageLinked(LINK_SET, RLV_CMD, "addattach=y", kID);
        llMessageLinked(LINK_SET, RLV_CMD, "remattach=y", kID);
        llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit=y", kID);
        llMessageLinked(LINK_SET, RLV_CMD,  "addoutfit=y", kID);
    }
}


default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        g_sWearerName = llKey2Name(g_kWearer);
        llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
        llSleep(1.0);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {   //the command was given by either owner, secowner, group member, or wearer
            list lParams = llParseString2List(sStr, [":", "="], []);
            string sCommand = llList2String(lParams, 0);
            //Debug(sStr + " ## " + sCommand);
            if (llListFindList(g_lRLVcmds, [sCommand]) != -1)
            {    //we've received an RLV command that we control.  only execute if not sub
                if (iNum == COMMAND_WEARER)
                {
                    llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                }
                else
                {
                    llMessageLinked(LINK_SET, RLV_CMD, sStr, kID);
                    string sOption = llList2String(llParseString2List(sStr, ["="], []), 0);
                    string sParam = llList2String(llParseString2List(sStr, ["="], []), 1);
                    integer iIndex = llListFindList(g_lSettings, [sOption]);
                    string opt1 = llList2String(llParseString2List(sOption, [":"], []), 0);
                    string opt2 = llList2String(llParseString2List(sOption, [":"], []), 1);
                    if (sParam == "n")
                    {
                        if (iIndex == -1)
                        {   //we don't alread have this exact setting.  add it
                            g_lSettings += [sOption, sParam];
                        }
                        else
                        {   //we already have a setting for this option.  update it.
                            g_lSettings = llListReplaceList(g_lSettings, [sOption, sParam], iIndex, iIndex + 1);
                        }
                        llMessageLinked(LINK_SET, HTTPDB_SAVE, g_sDBToken + "=" + llDumpList2String(g_lSettings, ","), NULL_KEY);
                    }
                    else if (sParam == "y")
                    {
                        if (iIndex != -1)
                        {   //we already have a setting for this option.  remove it.
                            g_lSettings = llDeleteSubList(g_lSettings, iIndex, iIndex + 1);
                        }
                        if (llGetListLength(g_lSettings)>0)
                            llMessageLinked(LINK_SET, HTTPDB_SAVE, g_sDBToken + "=" + llDumpList2String(g_lSettings, ","), NULL_KEY);
                        else
                            llMessageLinked(LINK_SET, HTTPDB_DELETE, g_sDBToken, NULL_KEY);
                    }
                    if (g_iRemenu)
                    {
                        g_iRemenu = FALSE;
                        MainMenu(kID);
                    }
                }
            }
            else if (sStr == "lockclothingmenu")
            {
                if (!g_iRLVOn)
                {
                    Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
                    llMessageLinked(LINK_SET, SUBMENU, "RLV", kID);
                    return;
                }
                g_kMenuUser = kID;
                LockMenu(kID);
            }
            else if (sStr == "lockattachmentmenu")
            {
                if (!g_iRLVOn)
                {
                    Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
                    llMessageLinked(LINK_SET, SUBMENU, "RLV", kID);
                    return;
                }
                g_kMenuUser = kID;
                LockAttachmentMenu(kID);
            }
            else  if (llGetSubString(sStr, 0, 11) == "lockclothing")            {
                string sMessage = llGetSubString(sStr, 13, -1);
                if (iNum == COMMAND_WEARER)
                {
                    Notify(kID, "Sorry you need owner privileges for locking clothes.", FALSE);
                }
                else if (sMessage==ALL||sStr== "lockclothing")
                {
                    g_lLockedItems += [ALL];
                    Notify(kID, g_sWearerName+"'s clothing has been locked.", TRUE);
                    llMessageLinked(LINK_SET, iNum,  "remoutfit=n", kID);
                    llMessageLinked(LINK_SET, iNum,  "addoutfit=n", kID);
                }
                else if (llListFindList(LOCK_CLOTH_POINTS,[sMessage])!=-1)
                {
                    g_lLockedItems += sMessage;
                    Notify(kID, g_sWearerName+"'s "+sMessage+" has been locked.", TRUE);
                    llMessageLinked(LINK_SET, iNum,  "remoutfit:" + sMessage + "=n", kID);
                    llMessageLinked(LINK_SET, iNum,  "addoutfit:" + sMessage + "=n", kID);
                }
                else Notify(kID, "Sorry you must either specify a cloth name or not use a parameter (which locks all the clothing layers).", FALSE);
                if (g_iRemenu) LockMenu(kID);
            }
            else if (llGetSubString(sStr, 0, 13) == "unlockclothing")
            {
                if (iNum == COMMAND_WEARER)
                {
                    Notify(kID, "Sorry you need owner privileges for unlocking clothes.", FALSE);
                }
                else
                {
                    string sMessage = llGetSubString(sStr, 15, -1);
                    if (sMessage==ALL||sStr=="unlockclothing")
                    {
                        llMessageLinked(LINK_SET, iNum,  "remoutfit=y", kID);
                        llMessageLinked(LINK_SET, iNum,  "addoutfit=y", kID);
                        Notify(kID, g_sWearerName+"'s clothing has been unlocked.", TRUE);
                        integer iIndex = llListFindList(g_lLockedItems,[ALL]);
                        if (iIndex!=-1) g_lLockedItems = llDeleteSubList(g_lLockedItems,iIndex,iIndex);
                    }
                    else
                    {
                        llMessageLinked(LINK_SET, iNum,  "remoutfit:" + sMessage + "=y", kID);
                        llMessageLinked(LINK_SET, iNum,  "addoutfit:" + sMessage + "=y", kID);
                        Notify(kID, g_sWearerName+"'s "+sMessage+" has been unlocked.", TRUE);
                        integer iIndex = llListFindList(g_lLockedItems,[sMessage]);
                        if (iIndex!=-1) g_lLockedItems = llDeleteSubList(g_lLockedItems,iIndex,iIndex);
                    }
                }
                if (g_iRemenu) LockMenu(kID);
            }
            else  if (llGetSubString(sStr, 0, 13) == "lockattachment")
            {
                string sMessage = llGetSubString(sStr, 15, -1);

                if (iNum == COMMAND_WEARER)
                {
                    Notify(kID, "Sorry you need owner privileges for locking attachments.", FALSE);
                    if (g_iRemenu) LockAttachmentMenu(kID);
                }
                else if (llListFindList(ATTACH_POINTS ,[sMessage])!=-1)
                {
                    g_iLastAuth = iNum;
                    QuerySingleAttachment(sMessage);
                }
                else
                {
                    Notify(kID, "Sorry you must either specify a attachment name.", FALSE);
                    if (g_iRemenu) LockAttachmentMenu(kID);
                }
            }
            else  if (sStr == "lockall")      //lock all clothes and attachement points
            {
                if (iNum == COMMAND_WEARER)
                {
                    Notify(kID, "Sorry you need owner privileges for locking attachments.", FALSE);
                }
                else
                {
                    DolockAll(sStr, kID);
                    SaveLockAllFlag(1);
                    Notify(kID, g_sWearerName+"'s clothing and attachements have been locked.", TRUE);
                }
                if (g_iRemenu) MainMenu(kID);   //redraw the menu if the lockall button was pressed
                g_iRemenu = FALSE;
            }
            else  if (sStr == "unlockall") //lock all clothes and attachment points
            {
                if (iNum == COMMAND_WEARER)
                {
                    Notify(kID, "Sorry you need owner privileges for unlocking attachments.", FALSE);
                }
                else
                {
                    DolockAll(sStr, kID);
                    SaveLockAllFlag(0);
                    Notify(kID, g_sWearerName+"'s clothing and attachements have been unlocked.", TRUE);
                }
                if (g_iRemenu) MainMenu(kID);   //redraw the menu if the unlockall button was pressed
                g_iRemenu = FALSE;

            }

            else if (llGetSubString(sStr, 0, 15) == "unlockattachment")
            {
                if (iNum == COMMAND_WEARER)
                {
                    Notify(kID, "Sorry you need owner privileges for unlocking attachments.", FALSE);
                }
                else
                {
                    string sMessage = llGetSubString(sStr, 17, -1);
                {
                    llMessageLinked(LINK_SET, iNum,  "addattach:" + sMessage + "=y", kID);
                    llMessageLinked(LINK_SET, iNum,  "remattach:" + sMessage + "=y", kID);
                    Notify(kID, g_sWearerName+"'s "+sMessage+" has been unlocked.", TRUE);
                    integer iIndex = llListFindList(g_lLockedAttach,[sMessage]);
                    if (iIndex!=-1) g_lLockedAttach = llDeleteSubList(g_lLockedAttach,iIndex,iIndex);
                }
                }
                if (g_iRemenu) LockAttachmentMenu(kID);
            }
            else if (sStr == "refreshmenu")
            {
                g_sSubMenus = [];
                llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, NULL_KEY);
            }
            else if (sStr == "undress")
            {
                if (!g_iRLVOn)
                {
                    Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
                    llMessageLinked(LINK_SET, SUBMENU, "RLV", kID);
                    return;
                }

                MainMenu(kID);
            }
            else if (sStr == "clothing")
            {
                if (!g_iRLVOn)
                {
                    Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
                    llMessageLinked(LINK_SET, SUBMENU, "RLV", kID);
                    return;
                }
                g_kMenuUser = kID;
                QueryClothing();
            }
            else if (sStr == "attachment")
            {
                if (!g_iRLVOn)
                {
                    Notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
                    llMessageLinked(LINK_SET, SUBMENU, "RLV", kID);
                    return;
                }
                g_kMenuUser = kID;
                QueryAttachments();
            }
        }
        // rlvoff -> we have to turn the menu off too
        else if (iNum>=COMMAND_OWNER && sStr=="rlvoff") g_iRLVOn=FALSE;

        // rlvoff -> we have to turn the menu off too
        else if (iNum == RLV_OFF) g_iRLVOn=FALSE;
        // rlvon -> we have to turn the menu on again
        else if (iNum == RLV_ON) g_iRLVOn=TRUE;

        else if (iNum == SUBMENU && sStr == g_sSubMenu)
        {//give this plugin's menu to kID
            MainMenu(kID);
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum == HTTPDB_RESPONSE)
        {   //this is tricky since our db value contains equals signs
            //split string on both comma and equals sign
            //first see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            if ( llList2String(lParams, 0)== g_sDBTokenLockAll)
            {
                //re-apply the lockall after a re-log
                g_iAllLocked = 1;
                DolockAll("lockall", kID);
            }

            if (llList2String(lParams, 0) == g_sDBToken)
            {
                //throw away first element
                //everything else is real settings (should be even number)
                g_lSettings = llParseString2List(llList2String(lParams, 1), [","], []);
                UpdateSettings();
            }
        }
        else if (iNum == RLV_REFRESH)
        {//rlvmain just started up.  Tell it about our current restrictions
            g_iRLVOn = TRUE;
            if(g_iAllLocked > 0)       //is everything locked?
                DolockAll("lockall", kID);  //lock everything on a RLV_REFRESH

            UpdateSettings();
        }
        else if (iNum == RLV_CLEAR)
        {   //clear db and local settings list
            ClearSettings();
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams, 0)==g_sSubMenu)
            {
                string child = llList2String(lParams, 1);
                //only add submenu if not already present
                if (llListFindList(g_sSubMenus, [child]) == -1)
                {
                    g_sSubMenus += [child];
                    g_sSubMenus = llListSort(g_sSubMenus, 1, TRUE);
                }
            }
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            string child = llList2String(lParams, 1);
            if (llList2String(lParams, 0)==g_sSubMenu)
            {
                integer iIndex = llListFindList(g_sSubMenus, [child]);
                //only remove if it's there
                if (iIndex != -1)
                {
                    g_sSubMenus = llDeleteSubList(g_sSubMenus, iIndex, iIndex);
                }
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (llListFindList([g_kMainID, g_kClothID, g_kAttachID, g_kLockID, g_kLockAttachID], [kID]) != -1)
            {//it's one of our menus
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                if (kID == g_kMainID)
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kAv);
                    }
                    else if (sMessage == "Rem Clothing")
                    {
                        g_kMenuUser = kAv;
                        QueryClothing();
                    }
                    else if (sMessage == "Rem Attachment")
                    {
                        g_kMenuUser = kAv;
                        QueryAttachments();
                    }
                    else if (sMessage == "Lock Clothing")
                    {
                        g_kMenuUser = kAv;
                        LockMenu(kAv);
                    }
                    else if (sMessage == "Lock Attachment")
                    {
                        g_kMenuUser = kAv;
                        LockAttachmentMenu(kAv);
                    }
                    else if (sMessage == "( )Lock All")
                    {
                        //forward this command to the other section - it came from the menu button
                        g_iRemenu = TRUE;
                        llMessageLinked(LINK_SET, COMMAND_NOAUTH, "lockall", kAv);
                    }
                    else if (sMessage == "(*)Lock All")
                    {
                        //forward this command to the other section - it came from the menu button
                        g_iRemenu = TRUE;
                        llMessageLinked(LINK_SET, COMMAND_NOAUTH, "unlockall", kAv);
                    }
                    else if (llListFindList(g_sSubMenus,[sMessage]) != -1)
                    {
                        llMessageLinked(LINK_SET, SUBMENU, sMessage, kAv);
                    }
                    else
                    {
                        //something went horribly wrong.  We got a command that we can't find in the list
                    }
                }
                else if (kID == g_kClothID)
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, SUBMENU, g_sSubMenu, kAv);
                    }
                    else if (sMessage == "Attachments") QueryAttachments();
                    else if (sMessage == ALL)
                    { //send the RLV command to remove it.
                        llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit=force", kAv);
                        //Return menu
                        //sleep fof a sec to let things detach
                        llSleep(0.5);
                        g_kMenuUser = kAv;
                        QueryClothing();
                    }
                    else
                    { //we got a cloth point.
                        sMessage = llToLower(sMessage);
                        //send the RLV command to remove it.
                        llMessageLinked(LINK_SET, RLV_CMD,  "remoutfit:" + sMessage + "=force", kAv);
                        //Return menu
                        //sleep fof a sec to let things detach
                        llSleep(0.5);
                        g_kMenuUser = kAv;
                        QueryClothing();
                    }
                }
                else if (kID == g_kAttachID)
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, SUBMENU, g_sSubMenu, kAv);
                    }
                    else if (sMessage == "Clothing") QueryClothing();
                    else
                    {    //we got an attach point.  send a message to detach
                        //we got a cloth point.
                        sMessage = llToLower(sMessage);
                        //send the RLV command to remove it.
                        llMessageLinked(LINK_SET, RLV_CMD,  "detach:" + sMessage + "=force", kAv);
                        //sleep for a sec to let tihngs detach
                        llSleep(0.5);
                        //Return menu
                        g_kMenuUser = kAv;
                        QueryAttachments();
                    }
                }
                else if (kID == g_kLockID)
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, SUBMENU, g_sSubMenu, kAv);
                    }
                    else
                    { //we got a cloth point.
                        string cstate = llGetSubString(sMessage,0,llStringLength(TICKED) - 1);
                        sMessage=llGetSubString(sMessage,llStringLength(TICKED),-1);
                        if (cstate==UNTICKED)
                        {
                            llMessageLinked(LINK_SET, COMMAND_NOAUTH, "lockclothing "+sMessage, kAv);
                        }
                        else if (cstate==TICKED)
                        {
                            llMessageLinked(LINK_SET, COMMAND_NOAUTH, "unlockclothing "+sMessage, kAv);
                        }
                        g_iRemenu = TRUE;
                    }
                }
                else if (kID == g_kLockAttachID)
                {
                    if (sMessage == UPMENU)
                    {
                        llMessageLinked(LINK_SET, SUBMENU, g_sSubMenu, kAv);
                    }
                    else
                    { //we got a cloth point.
                        string cstate = llGetSubString(sMessage,0,llStringLength(TICKED) - 1);
                        sMessage=llGetSubString(sMessage,llStringLength(TICKED),-1);
                        if (cstate==UNTICKED)
                        {
                            llMessageLinked(LINK_SET, COMMAND_NOAUTH, "lockattachment "+sMessage, kAv);
                        }
                        else if (cstate==TICKED)
                        {
                            llMessageLinked(LINK_SET, COMMAND_NOAUTH, "unlockattachment "+sMessage, kAv);
                        }
                        g_iRemenu = TRUE;
                    }
                }
            }
        }
    }

    listen(integer iChan, string sName, key kID, string sMessage)
    {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        if (iChan == g_iClothRLV)
        {   //llOwnerSay(sMessage);
            ClothingMenu(g_kMenuUser, sMessage);
        }
        else if (iChan == g_iAttachRLV)
        {
            DetachMenu(g_kMenuUser, sMessage);
        }
        else if (iChan > g_iAttachRLV && iChan <= g_iAttachRLV + llGetListLength(ATTACH_POINTS))
        {
            integer iIndex = iChan - g_iAttachRLV -1;
            string sPoint = llList2String(ATTACH_POINTS, iIndex);
            g_lLockedAttach += [sPoint];
            if ((integer) sMessage)
            {
                Notify(kID, g_sWearerName+"'s "+sPoint+" has been locked in place.", TRUE);
                llMessageLinked(LINK_SET, g_iLastAuth,  "remattach:" + sPoint + "=n", kID);
            }
            else
            {
                Notify(kID, g_sWearerName+"'s "+sPoint+" has been locked empty.", TRUE);
                llMessageLinked(LINK_SET, g_iLastAuth,  "addattach:" + sPoint + "=n", kID);
            }
            if (g_iRemenu) LockAttachmentMenu(g_kMenuUser);
        }
    }

    timer()
    {//stil needed for rlv listen timeouts, though not dialog timeouts anymore
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }

}
