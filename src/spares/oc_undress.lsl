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
//                          Undress - 161029.1                              //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Satomi Ahn, Nandana Singh, Joy Stipe,         //
//  Wendy Starfall, Master Starship, Medea Destiny, littlemousy,            //
//  Romka Swallowtail, Sumi Perl, Keiyra Aeon, Garvin Twine et al.          //
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
//       github.com/VirtualDisgrace/opencollar/tree/master/src/spares       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//gives menus for clothing and attachment, stripping and locking

string g_sAppVersion = "¹⋅³";

string g_sSubMenu = "Un/Dress";
string g_sParentMenu = "RLV";

//list g_lChildren = ["Rem. Clothing"]; //,"LockClothing","LockAttachment"];//,"LockClothing","UnlockClothing"];
list g_lSubMenus = [];
string SELECT_CURRENT = "*InFolder";
string SELECT_RECURS= "*Recursively";
list g_lRLVcmds = ["attach","detach","remoutfit", "addoutfit","remattach","addattach"];

integer g_iSmartStrip=FALSE; //use @detachallthis isntead of remove
//string SMARTHELP = "Help";
//string g_sSmartHelpCard = "OpenCollar Guide";
//string g_sSmartToken="smartstrip";
//key g_kSmartUser; //we store the last person to select if they are not wearer/owner, so that it can be switched on for current user without changing setting.

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
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;
//integer LOADPIN = -1904;
integer REBOOT  = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV    = 4;
integer LINK_SAVE   = 5;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
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

string UPMENU = "BACK";

string ALL = " ALL";
string TICKED = "☑ ";
string UNTICKED = "☐ ";

list g_lMenuIDs;
integer g_iMenuStride = 3;

integer g_iRLVTimeOut = 60;

integer g_iClothRLV = 78465;
integer g_iAttachRLV = 78466;
integer g_iListener;
key g_kMenuUser; // id of the avatar who will get the next menu after asynchronous response from RLV
integer g_iMenuAuth; // auth level of that user

integer g_iRLVOn = FALSE;

list g_lLockedItems; // list of locked clothes
list g_lLockedAttach; // list of locked attachmemts

key g_kWearer;
integer g_iAllLocked = 0;  //1=all clothes are locked on

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

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    llMessageLinked(LINK_DIALOG,NOTIFY,(string)iAlsoNotifyWearer+sMsg,kID);
}

MainMenu(key kID, integer iAuth)
{
    string sPrompt = "\n[http://www.opencollar.at/undress.html Legacy Un/dress]\t"+g_sAppVersion;
    if (g_iAllLocked) sPrompt += "\n\nAll clothes and attachments are currently locked.";
    list lButtons;
    if (!g_iAllLocked) lButtons += ["☐ Lock All","Lock Clothing","Lock Attach."];
    else lButtons += ["☑ Lock All"];
    if (g_iSmartStrip) lButtons += "☑ Smartstrip";
    else lButtons += "☐ Smartstrip";
    if (!g_iAllLocked) lButtons += ["Rem. Clothing","Rem. Attach."];

    Dialog(kID, sPrompt, lButtons+g_lSubMenus, [UPMENU], 0, iAuth, "Menu");
}

QueryClothing(key kAv, integer iAuth)
{    //open listener
    g_iListener = llListen(g_iClothRLV, "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_iRLVTimeOut);
    //send rlvcmd
    //llMessageLinked(LINK_RLV, RLV_CMD, "getoutfit=" + (string)g_iClothRLV, NULL_KEY);
    if (g_iRLVOn) llOwnerSay("@getoutfit=" + (string)g_iClothRLV);
    g_kMenuUser = kAv;
    g_iMenuAuth = iAuth;
}

ClothingMenu(key kID, string sStr, integer iAuth)
{
    //str looks like 0110100001111
    //loop through CLOTH_POINTS, look at chaClothingr of str for each
    //for each 1, add capitalized button
    string sPrompt = "\nSelect an article of clothing to remove.\n";
    list lButtons = [];
    integer iStop = llGetListLength(DETACH_CLOTH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        integer iWorn = (integer)llGetSubString(sStr, n, n);
        list item = [llList2String(DETACH_CLOTH_POINTS, n)];
        if (iWorn && llListFindList(g_lLockedItems,item) == -1)
        {
            if (llList2String(item,0)!="xx") lButtons += item;
        }
    }
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "strip");
}

LockClothMenu(key kID, integer iAuth)
{
    string sPrompt = "\nSelect an article of clothing to un/lock.\n";
    list lButtons;
    if (~llListFindList(g_lLockedItems,[ALL])) lButtons += [TICKED+ALL];
    else lButtons += [UNTICKED+ALL];

    integer iStop = llGetListLength(LOCK_CLOTH_POINTS);
    integer n;
    for (n = 0; n < iStop; n++)
    {
        string sCloth = llList2String(LOCK_CLOTH_POINTS, n);
        if (~llListFindList(g_lLockedItems,[sCloth])) lButtons += [TICKED+sCloth];
        else lButtons += [UNTICKED+sCloth];
    }
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "lockclothing");
}

QueryAttachments(key kAv, integer iAuth)
{    //open listener
    g_iListener = llListen(g_iAttachRLV, "", g_kWearer, "");
    //start timer
    llSetTimerEvent(g_iRLVTimeOut);
    //send rlvcmd
    //llMessageLinked(LINK_RLV, RLV_CMD, "getattach=" + (string)g_iAttachRLV, NULL_KEY);
    if (g_iRLVOn) llOwnerSay("@getattach=" + (string)g_iAttachRLV);
    g_kMenuUser = kAv;
    g_iMenuAuth = iAuth;
}

LockAttachmentMenu(key kID, integer iAuth)
{
    string sPrompt = "\nSelect an attachment to un/lock.\n";
    list lButtons;

    if (~llListFindList(g_lLockedAttach,[ALL])) lButtons += [TICKED+ALL];
    else lButtons += [UNTICKED+ALL];

    //put tick marks next to locked things
    integer iStop = llGetListLength(ATTACH_POINTS);
    integer n;
    for (n = 1; n < iStop; n++) //starting at 1 as "None" cannot be locked
    {
        string sAttach = llList2String(ATTACH_POINTS, n);
        if (~llListFindList(g_lLockedAttach,[sAttach])) lButtons += [TICKED+sAttach];
        else lButtons += [UNTICKED+sAttach];
    }
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "lockattachment");
}

DetachMenu(key kID, string sStr, integer iAuth)
{
    //remember not to add button for current object
    //str looks like 0110100001111
    //loop through CLOTH_POINTS, look at char of str for each
    //for each 1, add capitalized button
    string sPrompt = "\nSelect an attachment to remove.\n";

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
            if (iWorn) lButtons += [llList2String(ATTACH_POINTS, n)];
        }
    }
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "detach");
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
            if (llGetListLength(sOption)==1 && llList2String(sOption,0)=="remoutfit")
            {
                if (!~llListFindList(g_lLockedItems, [ALL])) g_lLockedItems += [ALL];
            }
            else if (llGetListLength(sOption)==2 && ~llSubStringIndex(llList2String(sOption, 0), "outfit"))
            {
                if (!~llListFindList(g_lLockedItems, [llList2String(sOption, 1)]))
                    g_lLockedItems += [llList2String(sOption,1)];
            }
            else if (llGetListLength(sOption)==2 && ~llSubStringIndex(llList2String(sOption, 0), "tach"))
            {
                if (!~llListFindList(g_lLockedAttach, [llList2String(sOption,1)]))
                    g_lLockedAttach += [llList2String(sOption,1)];
            }
        }
        //output that string to viewer
        //llMessageLinked(LINK_RLV, RLV_CMD, llDumpList2String(lNewList, ","), NULL_KEY);
        if (g_iRLVOn) llOwnerSay("@"+llDumpList2String(lNewList, ","));
        //Debug("Loaded locks: Cloth- " + llList2CSV(g_lLockedItems) + ": Attach- " + llList2CSV(g_lLockedAttach));
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
    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvundress_List", "");
    //main RLV script will take care of sending @clear to viewer
}

SaveLockAllFlag(integer iSetting)
{
    if (g_iAllLocked == iSetting) return;

    g_iAllLocked = iSetting;
    if (iSetting > 0) llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvundress_LockAll=1", "");
    else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvundress_LockAll", "");
}

DoLockAll()
{
    //llMessageLinked(LINK_RLV, RLV_CMD, "addattach=n,remattach=n,addoutfit=n,remoutfit=n", NULL_KEY);
    if (g_iRLVOn) llOwnerSay("@addattach=n,remattach=n,addoutfit=n,remoutfit=n");
}

DoUnlockAll()
{
    //llMessageLinked(LINK_RLV, RLV_CMD, "addattach=y,remattach=y,addoutfit=y,remoutfit=y", NULL_KEY);
    if (g_iRLVOn) llOwnerSay("@addattach=y,remattach=y,addoutfit=y,remoutfit=y");
}

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_undress")
        llRemoveInventory(sName);
}

UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum > CMD_WEARER || iNum < CMD_OWNER) return; // sanity check
    if (llToLower(sStr) == "rm undress" || llToLower(sStr) == "rm un/dress") {
        if (iNum == CMD_OWNER || kID == g_kWearer)
            Dialog(kID, "\nDo you really want to uninstall the "+g_sSubMenu+" App?", ["Yes","No","Cancel"], [], 0, iNum,"rmundress");
        else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        return;
    }
    if (!g_iRLVOn)
    {
        if (~llListFindList(["menu "+g_sSubMenu,"undress","lockall","unlockall"],[sStr]))
        {
            Notify(kID, "RLV features are now disabled in this %DEVICETYPE%. You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_RLV, iNum, "menu "+g_sParentMenu, kID);
        }
        return;
    }

    list lParams = llParseString2List(sStr, [":", "=", " "], []);
    string sCommand = llList2String(lParams, 0);
    //Debug(sStr + " ## " + sCommand);

    if (sStr == "menu " + g_sSubMenu) MainMenu(kID, iNum);
    else if (sStr == "undress") MainMenu(kID, iNum);
    else if (sStr == "lockall")
    {
        if (iNum == CMD_WEARER) Notify(kID, "Sorry you need owner privileges for locking attachments.", FALSE);
        else
        {
            DoLockAll(); //lock all clothes and attachment points
            SaveLockAllFlag(1);
            Notify(kID, "%WEARERNAME%'s clothing and attachments have been locked.", TRUE);
        }
    }
    else if (sStr == "unlockall")
    {
        if (iNum == CMD_WEARER) Notify(kID, "Sorry you need owner privileges for unlocking attachments.", FALSE);
        else
        {
            DoUnlockAll(); //unlock all clothes and attachment points
            SaveLockAllFlag(0);
            Notify(kID, "%WEARERNAME%'s clothing and attachments have been unlocked.", TRUE);
        }
    }
    else if (sCommand == "smartstrip")
    {
        if (iNum==CMD_OWNER || iNum == CMD_WEARER)
        {
            string sOpt=llList2String(lParams,1);
            if (sOpt == "on")
            {
                g_iSmartStrip = TRUE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvundress_smartstrip=1","");
            }
            else
            {
                g_iSmartStrip = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvundress_smartstrip","");
            }
        }
        else Notify(kID,"This requires a properly set-up outfit, only wearer or owner can turn it on.", FALSE);
    }
    else if (sCommand == "strip")
    {
        string sOpt=llList2String(lParams,1);
        if(sOpt=="all")
        {
           if(g_iSmartStrip==TRUE)
            {
                integer x=14; //let's not strip tattoos and physics layers;
                while(x)
                {
                    if(x==13) x=9; //skip hair,skin,shape,eyes
                    --x;
                    string sItem=llToLower(llList2String(DETACH_CLOTH_POINTS,x));
                    //llMessageLinked(LINK_RLV, RLV_CMD, "detachallthis:"+ sItem +"=force", NULL_KEY);
                    if (g_iRLVOn) llOwnerSay("@detachallthis:"+ sItem +"=force");
                 }
            }
           //llMessageLinked(LINK_RLV, RLV_CMD, "remoutfit=force", NULL_KEY);
           if (g_iRLVOn) llOwnerSay("@remoutfit=force");
           return ;
        }
        sOpt = llToLower(sOpt);
        string test=llToUpper(llGetSubString(sOpt,0,0))+llGetSubString(sOpt,1,-1);
        if(llListFindList(DETACH_CLOTH_POINTS,[test])==-1) return;

        //send the RLV command to remove it.
        //if (g_iSmartStrip==TRUE) llMessageLinked(LINK_RLV, RLV_CMD, "detachallthis:" + sOpt + "=force", NULL_KEY);
        //llMessageLinked(LINK_RLV, RLV_CMD, "remoutfit:" + sOpt + "=force", NULL_KEY); //yes, this isn't an else. We do it in case the item isn't in #RLV.
        if (g_iRLVOn)
        {
            if (g_iSmartStrip==TRUE) llOwnerSay("@detachallthis:" + sOpt + "=force");
            llOwnerSay("@remoutfit:" + sOpt + "=force");
        }
    }
    else if (llListFindList(g_lRLVcmds, [sCommand]) != -1)
    {
        if (iNum == CMD_WEARER) Notify(kID, "Sorry, but RLV commands may only be given by owner, secowner, or group (if set).", FALSE);
        else RLVCMD(sStr);
    }
    else if (llGetSubString(sStr, 0, 11) == "lockclothing")
    {
        string sMessage = llGetSubString(sStr, 13, -1);
        if (iNum == CMD_WEARER) Notify(kID, "Sorry you need owner privileges for locking clothes.", FALSE);
        else if (sMessage==ALL||sStr== "lockclothing")
        {
            g_lLockedItems += [ALL];
            Notify(kID, "%WEARERNAME%'s clothing has been locked.", TRUE);
            RLVCMD("remoutfit=n");
            RLVCMD("addoutfit=n");
        }
        else if (llListFindList(LOCK_CLOTH_POINTS,[sMessage])!=-1)
        {
            g_lLockedItems += sMessage;
            Notify(kID, "%WEARERNAME%'s "+sMessage+" has been locked.", TRUE);
            RLVCMD("remoutfit:" + sMessage + "=n");
            RLVCMD("addoutfit:" + sMessage + "=n");
        }
        else Notify(kID, "Sorry you must either specify a cloth name or not use a parameter (which locks all the clothing layers).", FALSE);
    }
    else if (llGetSubString(sStr, 0, 13) == "unlockclothing")
    {
        if (iNum == CMD_WEARER) Notify(kID, "Sorry you need owner privileges for unlocking clothes.", FALSE);
        else
        {
            string sPoint = llGetSubString(sStr, 15, -1);
            if (sPoint==ALL||sStr=="unlockclothing")
            {
                RLVCMD("remoutfit=y");
                RLVCMD("addoutfit=y");
                Notify(kID, "%WEARERNAME%'s clothing has been unlocked.", TRUE);
                integer iIndex = llListFindList(g_lLockedItems,[ALL]);
                if (iIndex!=-1) g_lLockedItems = llDeleteSubList(g_lLockedItems,iIndex,iIndex);
            }
            else
            {
                RLVCMD("remoutfit:" + sPoint + "=y");
                RLVCMD("addoutfit:" + sPoint + "=y");
                Notify(kID, "%WEARERNAME%'s "+sPoint+" has been unlocked.", TRUE);
                integer iIndex = llListFindList(g_lLockedItems,[sPoint]);
                if (iIndex!=-1) g_lLockedItems = llDeleteSubList(g_lLockedItems,iIndex,iIndex);
            }
        }
    }
    else if (llGetSubString(sStr, 0, 13) == "lockattachment")
    {
        string sPoint = llGetSubString(sStr, 15, -1);
        if (iNum == CMD_WEARER) Notify(kID, "Sorry you need owner privileges for locking attachments.", FALSE);
        else if (llListFindList(ATTACH_POINTS ,[sPoint])!=-1)
        {
            if (llListFindList(g_lLockedAttach, [sPoint]) == -1) g_lLockedAttach += [sPoint];
            RLVCMD("detach:" + sPoint + "=n");
            Notify(kID, "%WEARERNAME%'s "+sPoint+" attachment point is now locked.", TRUE);
        }
        else if (sPoint==ALL||sStr=="lockattachment")
        {
            if (llListFindList(g_lLockedAttach, [sPoint]) == -1) g_lLockedAttach += [ALL];
            RLVCMD("addattach=n");
            RLVCMD("remattach=n");
            Notify(kID, "%WEARERNAME%'s "+sPoint+" attachment point is now locked.", TRUE);
        }
        else Notify(kID, "Sorry you must either specify a attachment name.", FALSE);
    }
    else if (llGetSubString(sStr, 0, 15) == "unlockattachment")
    {
        string sPoint = llGetSubString(sStr, 17, -1);
        if (iNum == CMD_WEARER) Notify(kID, "Sorry you need owner privileges for unlocking attachments.", FALSE);
        else if (sPoint==ALL||sStr=="unlockattachment")
        {
            RLVCMD("addattach=y");
            RLVCMD("remattach=y");
            Notify(kID, "%WEARERNAME%'s "+sPoint+" attachment point is now locked.", TRUE);
            integer iIndex = llListFindList(g_lLockedAttach,[ALL]);
            if (iIndex!=-1) g_lLockedAttach = llDeleteSubList(g_lLockedAttach,iIndex,iIndex);
        }
        else if (llListFindList(ATTACH_POINTS ,[sPoint])!=-1)
        {
            RLVCMD("detach:" + sPoint + "=y");
            Notify(kID, "%WEARERNAME%'s "+sPoint+" has been unlocked.", TRUE);
            integer iIndex = llListFindList(g_lLockedAttach,[sPoint]);
            if (iIndex!=-1) g_lLockedAttach = llDeleteSubList(g_lLockedAttach,iIndex,iIndex);
        }
        else Notify(kID, "Sorry you must either specify a attachment name.", FALSE);
    }
}

RLVCMD(string sStr)
{    //we've received an RLV command that we control.  only execute if not sub

    //llMessageLinked(LINK_RLV, RLV_CMD, sStr, NULL_KEY);
    if (g_iRLVOn) llOwnerSay("@"+sStr);

    string sOption = llList2String(llParseString2List(sStr, ["="], []), 0);
    string sParam = llList2String(llParseString2List(sStr, ["="], []), 1);
    integer iIndex = llListFindList(g_lSettings, [sOption]);
    string opt1 = llList2String(llParseString2List(sOption, [":"], []), 0);
    string opt2 = llList2String(llParseString2List(sOption, [":"], []), 1);
    if (sParam == "n")
    {
        if (iIndex == -1) g_lSettings += [sOption, sParam];
        else g_lSettings = llListReplaceList(g_lSettings, [sOption, sParam], iIndex, iIndex + 1);
    }
    else if (sParam == "y")
    {
        if (iIndex != -1) g_lSettings = llDeleteSubList(g_lSettings, iIndex, iIndex + 1);
    }

    if (llGetListLength(g_lSettings)>0)
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "rlvundress_List=" + llDumpList2String(g_lSettings, ","), "");
    else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, "rlvundress_List", "");
}


default {
    on_rez(integer iParam)
    {
        llResetScript();
    }

    state_entry()
    {
        g_kWearer = llGetOwner();
        FailSafe();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == RLV_OFF) g_iRLVOn=FALSE;
        else if (iNum == RLV_ON) g_iRLVOn=TRUE;
        else if (iNum == RLV_REFRESH)
        {
            g_iRLVOn = TRUE;
            if (g_iAllLocked > 0) DoLockAll();
            UpdateSettings();
        }
        else if (iNum == RLV_CLEAR) ClearSettings();
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lSubMenus = []; //flush submenu buttons
            llMessageLinked(LINK_THIS, MENUNAME_REQUEST, g_sSubMenu, "");
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "rlvundress_LockAll")
            {
                g_iAllLocked = 1;
                DoLockAll();
            }
            else if (sToken == "rlvundress_List")
            {
                g_lSettings = llParseString2List(sValue, [","], []);
                UpdateSettings();
            }
            else if (sToken == "rlvundress_smartstrip") g_iSmartStrip=TRUE;
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams, 0)==g_sSubMenu)
            {
                string child = llList2String(lParams, 1);
                //only add submenu if not already present
                if (llListFindList(g_lSubMenus, [child]) == -1)
                {
                    g_lSubMenus += [child];
                    g_lSubMenus = llListSort(g_lSubMenus, 1, TRUE);
                }
            }
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams, 0)==g_sSubMenu)
            {
                integer iIndex = llListFindList(g_lSubMenus, [llList2String(lParams, 1)]);
                //only remove if it's there
                if (iIndex != -1) g_lSubMenus = llDeleteSubList(g_lSubMenus, iIndex, iIndex);
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex)
            {
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);

                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                if (sMenu == "Menu")
                {
                    if (sMessage == UPMENU) llMessageLinked(LINK_RLV, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == "Rem. Clothing") QueryClothing(kAv, iAuth);
                    else if (sMessage == "Rem. Attach.") QueryAttachments(kAv, iAuth);
                    else if (sMessage == "Lock Clothing") LockClothMenu(kAv, iAuth);
                    else if (sMessage == "Lock Attach.") LockAttachmentMenu(kAv, iAuth);
                    else if (sMessage == "☐ Lock All") { UserCommand(iAuth, "lockall", kAv); MainMenu(kAv, iAuth); }
                    else if (sMessage == "☑ Lock All") { UserCommand(iAuth, "unlockall", kAv); MainMenu(kAv, iAuth); }
                    else if (sMessage == "☐ Smartstrip") { UserCommand(iAuth, "smartstrip on",kAv); MainMenu(kAv, iAuth);}
                    else if (sMessage == "☑ Smartstrip") { UserCommand(iAuth, "smartstrip off",kAv); MainMenu(kAv, iAuth);}
                    else if (llListFindList(g_lSubMenus,[sMessage]) != -1) llMessageLinked(LINK_THIS, iAuth, "menu " + sMessage, kAv);
                }
                else if (sMenu == "strip")
                {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else
                    {
                        if (sMessage == ALL) sMessage = "all";
                        UserCommand(iAuth, "strip "+sMessage,kAv);
                        llSleep(0.5);
                        QueryClothing(kAv, iAuth);
                    }
                }
                else if (sMenu == "detach")
                {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else
                    {
                        sMessage = llToLower(sMessage);
                        //send the RLV command to remove it.
                        //llMessageLinked(LINK_RLV, RLV_CMD, "detach:" + sMessage + "=force", NULL_KEY);
                        if (g_iRLVOn) llOwnerSay("@detach:" + sMessage + "=force");
                        //sleep for a sec to let tihngs detach
                        llSleep(0.5);
                        //Return menu
                        g_kMenuUser = kAv;
                        QueryAttachments(kAv, iAuth);
                    }
                }
                else if (sMenu == "lockclothing" || sMenu == "lockattachment")
                {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else
                    {
                        string cstate = llGetSubString(sMessage,0,llStringLength(TICKED)-1);
                        sMessage = llGetSubString(sMessage,llStringLength(TICKED),-1);
                        if (cstate==UNTICKED) UserCommand(iAuth, sMenu+" "+sMessage, kAv);
                        else if (cstate==TICKED) UserCommand(iAuth, "un"+sMenu+" "+sMessage, kAv);

                        if (sMenu == "lockclothing") LockClothMenu(kAv, iAuth);
                        if (sMenu == "lockattachment") LockAttachmentMenu(kAv, iAuth);
                    }
                } else if (sMenu == "rmundress") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_RLV, MENUNAME_REMOVE , g_sParentMenu + "|"+g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
        }
        else if (iNum == LINK_UPDATE)
        {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        }
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    listen(integer iChan, string sName, key kID, string sMessage)
    {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        if (iChan == g_iClothRLV) ClothingMenu(g_kMenuUser, sMessage, g_iMenuAuth);
        else if (iChan == g_iAttachRLV) DetachMenu(g_kMenuUser, sMessage, g_iMenuAuth);
    }

    timer()
    {//stil needed for rlv listen timeouts, though not dialog timeouts anymore
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) FailSafe();
        /*if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }
}
