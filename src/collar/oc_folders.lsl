////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - rlvfolders                             //
//                                 version 3.989                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string g_sParentMenu = "Un/Dress";

list g_lChildren = ["Browse #RLV", "#RLV History"];

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//sStr must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer RLVA_VERSION = 6004; //RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string PARENT = "⏎";
string ACTIONS_CURRENT = "Actions";
string ROOT_ACTIONS = "Global Actions";

string UPMENU = "BACK";
//string MORE = ">";

// Folder actions
//string ALL = "*All*";
//string SELECT_CURRENT = "*This*";
string REPLACE_ALL = "Replace all";
string ADD_ALL = "Add all";
string DETACH_ALL = "Detach all";
string REPLACE = "Replace this";
string ADD = "Add this";
string DETACH = "Detach this";
string LOCK_ATTACH_ALL = "Lock att. all";
string LOCK_DETACH_ALL = "Lock det. all";
string LOCK_ATTACH = "Lock att. this";
string LOCK_DETACH = "Lock det. this";

integer g_iUnsharedLocks = 0; // 2 bits bitfield: first (strong) one for unsharedwear, second (weak) one for unsharedunwear
list g_lFolderLocks; // strided list: folder path, lock type (4 bits field)

integer g_iTimeOut = 60;

integer g_iFolderRLV = 78467;
integer g_iRLVaOn = FALSE; //Assume we don't have RLVa, until we hear that we do

key g_kBrowseID;
key g_kActionsID;
key g_kRootActionsID;
key g_kHistoryMenuID;
key g_kMultipleFoldersOnSearchMenuID;
integer g_iPage = 0;//Having a global is nice, if you redisplay the menu after an action on a folder.

integer g_iListener;//Nan:do we still need this? -- SA: of course. It's where the viewer talks.

// Asynchronous menu request. Alas still needed since some menus are triggered after an answer from the viewer.
key g_kAsyncMenuUser;
integer g_iAsyncMenuAuth;
integer g_iAsyncMenuRequested = FALSE;

string sPrompt;//Nan: why is this global?
string g_sFolderType; //what to do with those folders
string g_sCurrentFolder;

list g_lOutfit; //saved folder list
list g_lToCheck; //stack of folders to check, used for subfolder tree search

list g_lSearchList; //list of folders to search

integer g_iLastFolderState;

key g_kWearer;
string g_sScript;

list g_lHistory;

Debug(string sMsg)
{
    //llOwnerSay(llGetScriptName() + ": " + sMsg);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

addToHistory(string folder)
{
    if (!(~llListFindList(g_lHistory, [folder]))) g_lHistory+=[folder];
    g_lHistory = llList2List(g_lHistory, -10, -1);
}

ParentFolder() {
    list lFolders = llParseString2List(g_sCurrentFolder,["/"],[]);
    g_iPage = 0; // changing the folder also means going back to first page
    if (llGetListLength(lFolders)>1) {
        g_sCurrentFolder=llList2String(lFolders,0);
        integer i;
        for (i=1;i<llGetListLength(lFolders)-1;i++) g_sCurrentFolder+="/"+llList2String(lFolders,i);
    }
    else g_sCurrentFolder="";
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
        + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

QueryFolders(string sType)
{
    g_sFolderType = sType;
    g_iFolderRLV = 9999 + llRound(llFrand(9999999.0));
    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
    llSetTimerEvent(g_iTimeOut);
    llMessageLinked(LINK_SET, RLV_CMD, "getinvworn:"+g_sCurrentFolder+"=" + (string)g_iFolderRLV, NULL_KEY);
}

string lockFolderButton(integer iLockState, integer iLockNum, integer iAuth)
{
    string sOut;
    if ((iLockState >> (4 + iLockNum)) & 0x1) sOut = "☔";
    else if ((iLockState >> iLockNum) & 0x1) sOut = "✔";
    else sOut = "✘";
    if (iLockNum == 0) sOut += LOCK_ATTACH;
    else if (iLockNum == 1) sOut += LOCK_DETACH;
    else if (iLockNum == 2) sOut += LOCK_ATTACH_ALL;
    else if (iLockNum == 3) sOut += LOCK_DETACH_ALL;
    if (iAuth > COMMAND_GROUP) sOut = "("+sOut+")";
    return sOut;
}

string lockUnsharedButton(integer iLockNum, integer iAuth)
{
    string sOut;
    if ((g_iUnsharedLocks >> iLockNum) & 0x1) sOut = "✔";
    else sOut = "✘";
    if (iLockNum == 1) sOut += "Lk Unsh Wear";
    else if  (iLockNum == 0) sOut += "Lk Unsh Remove";
    if (iAuth > COMMAND_GROUP) sOut = "("+sOut+")";
    return sOut;
}

HistoryMenu(key kAv, integer iAuth)
{
    g_kHistoryMenuID = Dialog(kAv, "\nRecently worn #RLV folders:", g_lHistory, [UPMENU], 0, iAuth);
}


RootActionsMenu(key kAv, integer iAuth)
{
    list lActions = [lockUnsharedButton(0, iAuth), lockUnsharedButton(1, iAuth), "Save", "Restore"];
    string sPrompt = "\nwww.opencollar.at/folders\n\nYou are at the #RLV shared root.\n\nFrom here, you can restrict wearing or removing not shared items, you can also save the list of worn shared folders or make the currently saved list be worn again.\n\nWhat do you want to do?";
    g_kRootActionsID = Dialog(kAv, sPrompt, lActions, [UPMENU], 0, iAuth);
}


FolderActionsMenu(integer iState, key kAv, integer iAuth)
{
    integer iStateThis = iState / 10;
    integer iStateSub = iState % 10;
    list lActions;
    if (g_sFolderType == "history") lActions += "Browse";
    g_sFolderType += "_actions";
    if (!iStateSub) g_sFolderType += "_sub";

    if (g_sCurrentFolder != "")
    {
        integer iIndex = llListFindList(g_lFolderLocks, [g_sCurrentFolder]);
        integer iLock;
        if (~iIndex)
        {
            iLock = llList2Integer(g_lFolderLocks, iIndex+1);
        }

        if ( iStateThis == 1 || iStateThis == 2) // there are items that can be added in current folder
            lActions += [REPLACE, ADD, lockFolderButton(iLock, 0, iAuth)];
        if ( iStateThis == 2 || iStateThis == 3) // there are items that can be removed
            lActions += [DETACH,  lockFolderButton(iLock, 1, iAuth)];
        if ( iStateSub == 1 || iStateSub == 2) // there are items that can be added in descendant folder
            lActions += [REPLACE_ALL, ADD_ALL,  lockFolderButton(iLock, 2, iAuth)];
        if ( iStateSub == 2 || iStateSub == 3) // there are items that can be removed from descendant folders
            lActions += [DETACH_ALL,  lockFolderButton(iLock, 3, iAuth)];
    }
    string sPrompt = "\nwww.opencollar.at/folders\n\nCurrent folder is ";
    if (g_sCurrentFolder == "") sPrompt += "root";
    else sPrompt += g_sCurrentFolder;
    sPrompt += ".\n";
    sPrompt += "\nWhat do you want to do?";

    g_kActionsID = Dialog(kAv, sPrompt, lActions, [UPMENU], 0, iAuth);
}

string folderIcon(integer iState)
{
    string sOut = "";
    integer iStateThis = iState / 10;
    integer iStateSub = iState % 10;
    if  (iStateThis==0) sOut += "⬚"; //▪";
    else if (iStateThis==1) sOut += "◻";
    else if (iStateThis==2) sOut += "◩";
    else if (iStateThis==3) sOut += "◼";
    else sOut += " ";
    //    sOut += "/";
    if (iStateSub==0) sOut += "⬚"; //▪";
    else if (iStateSub==1) sOut += "◻";
    else if (iStateSub==2) sOut += "◩";
    else if (iStateSub==3) sOut += "◼";
    else sOut += " ";
    return sOut;
}

integer StateFromButton(string sButton)
{
    string sIconThis = llGetSubString(sButton, 0, 0);
    string sIconSub = llGetSubString(sButton, 1, 1);
    integer iState;
    if (sIconThis=="◻") iState = 1;
    else if (sIconThis=="◩") iState = 2;
    else if (sIconThis=="◼") iState = 3;
    iState *= 10;
    if (sIconSub=="◻") iState +=1;
    else if (sIconSub=="◩") iState +=2;
    else if (sIconSub=="◼") iState += 3;
    return iState;
}

string FolderFromButton(string sButton)
{
    return llToLower(llGetSubString(sButton, 2, -1));
}

updateFolderLocks(string sFolder, integer iAdd, integer iRem)
{ // adds and removes locks for sFolder, which implies saving to central settings and triggering a RLV command (dolockFolder)
    integer iLock;
    integer iIndex = llListFindList(g_lFolderLocks, [sFolder]);
    if (~iIndex)
    {
        iLock = ((llList2Integer(g_lFolderLocks, iIndex+1) | iAdd) & ~iRem);
        if (iLock)
        {
            g_lFolderLocks = llListReplaceList(g_lFolderLocks, [iLock], iIndex+1, iIndex+1);
            doLockFolder(iIndex);
        }
        else
        {
            g_lFolderLocks = llDeleteSubList(g_lFolderLocks, iIndex, iIndex+1);
            llMessageLinked(LINK_SET, RLV_CMD,  "attachthis_except:"+sFolder+"=y,detachthis_except:"+sFolder+"=y,attachallthis_except:"+sFolder+"=y,detachallthis_except:"+sFolder+"=y,"+ "attachthis:"+sFolder+"=y,detachthis:"+sFolder+"=y,attachallthis:"+sFolder+"=y,detachallthis:"+sFolder+"=y", NULL_KEY);
        }
    }
    else
    {
        iLock = iAdd & ~iRem;
        g_lFolderLocks += [sFolder, iLock];
        iIndex = llGetListLength(g_lFolderLocks)-2;
        doLockFolder(iIndex);
    }
    if ([] != g_lFolderLocks) llMessageLinked(LINK_SET, LM_SETTING_SAVE,  g_sScript + "Locks=" + llDumpList2String(g_lFolderLocks, ","), "");
    else llMessageLinked(LINK_SET, LM_SETTING_DELETE,  g_sScript + "Locks", "");
}

doLockFolder(integer iIndex)
{ // sends command to the viewer to update all locks concerning folder #iIndex
    string sFolder = llList2String(g_lFolderLocks, iIndex);
    integer iLock = llList2Integer(g_lFolderLocks, iIndex + 1);
    string sRlvCom = "attachthis:"+sFolder+"=";
    if ((iLock >> 0) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",detachthis:"+sFolder+"=";
    if ((iLock >> 1) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",attachallthis:"+sFolder+"=";
    if ((iLock >> 2) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",detachallthis:"+sFolder+"=";
    if ((iLock >> 3) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",attachthis_except:"+sFolder+"=";
    if ((iLock >> 4) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",detachthis_except:"+sFolder+"=";
    if ((iLock >> 5) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",attachallthis_except:"+sFolder+"=";
    if ((iLock >> 6) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",detachallthis_except:"+sFolder+"=";
    if ((iLock >> 7) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    //    llOwnerSay(sRlvCom);
    llMessageLinked(LINK_SET, RLV_CMD,  sRlvCom, NULL_KEY);
}


updateUnsharedLocks(integer iAdd, integer iRem)
{ // adds and removes locks for unshared items, which implies saving to central settings and triggering a RLV command (dolockUnshared)
    g_iUnsharedLocks = ((g_iUnsharedLocks | iAdd) & ~iRem);
    doLockUnshared();
    if (g_iUnsharedLocks) llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "Unshared=" + (string) g_iUnsharedLocks, "");
    else llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "Unshared", "");
}

doLockUnshared()
{ // sends command to the viewer to update all locks concerning unshared items
    string sRlvCom = "unsharedunwear=";
    if ((g_iUnsharedLocks >> 0) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    sRlvCom += ",unsharedwear=";
    if ((g_iUnsharedLocks >> 1) & 1)  sRlvCom += "n"; else sRlvCom += "y";
    llMessageLinked(LINK_SET, RLV_CMD,  sRlvCom, NULL_KEY);
}

// Browsing menu, called asynchronously only (after querying folder state). Queries user and auth from globals.
FolderBrowseMenu(string sStr)
{
    g_iAsyncMenuRequested = FALSE;
    list lUtilityButtons = [UPMENU];
    string sPrompt = "\nwww.opencollar.at/folders\n\nCurrent folder is ";
    if (g_sCurrentFolder == "")
    {
        sPrompt += "root";
    }
    else sPrompt += g_sCurrentFolder;
    sPrompt += ".\n";
    list sData = llParseStringKeepNulls(sStr, [","], []);
    string sFirst = llList2String(sData, 0);
    sData = llListSort(llList2List(sData, 1, -1), 1, 1);
    integer i;
    list lItem;
    integer iWorn;
    list lFolders = [];

    // now add the button for wearing all recursively when it makes sense
    if (g_sCurrentFolder!="") {
        lItem=llParseString2List(sFirst,["|"],[]);
        iWorn=llList2Integer(lItem,0);
        g_iLastFolderState=iWorn;
        if (iWorn / 10 == 1 ) sPrompt += "It has wearable items";
        else if (iWorn / 10 == 2 ) sPrompt += "It has wearable and removable items";
        else if (iWorn / 10 == 3 ) sPrompt += "It has removable items";
        else if (iWorn / 10 == 0 ) sPrompt += "It does not directly have any wearable or removable item";
        sPrompt += ".\n";
        lUtilityButtons += [ACTIONS_CURRENT];
    }
    else lUtilityButtons += [ROOT_ACTIONS];
    for (i=0;i<llGetListLength(sData);i++) {
        lItem=llParseString2List(llList2String(sData,i),["|"],[]);
        string sFolder = llList2String(lItem,0);
        iWorn=llList2Integer(lItem,1);
        if (iWorn != 0)
        {
            lFolders += [folderIcon(iWorn) + sFolder];
        }
    }
    sPrompt += "\n- Click "+ACTIONS_CURRENT+" to manage this folder content.\n- Click one of the subfolders to browse it.\n";
    if (g_sCurrentFolder!="") {sPrompt += "- Click "+PARENT+" to browse parent folder.\n"; lUtilityButtons += [PARENT];}
    sPrompt += "- Click "+UPMENU+" to go back to "+g_sParentMenu+".\n";
    g_kBrowseID = Dialog(g_kAsyncMenuUser, sPrompt, lFolders, lUtilityButtons, g_iPage, g_iAsyncMenuAuth);
}

SaveFolder(string sStr)
{
    list sData = llParseString2List(sStr, [","], []);
    integer i;
    list lItem;
    integer iWorn;
    if (g_sCurrentFolder!="") g_sCurrentFolder+="/";
    for (i=1;i<llGetListLength(sData);i++) {
        lItem=llParseString2List(llList2String(sData,i),["|"],[]);
        iWorn=llList2Integer(lItem,1);
        if (iWorn>=30) g_lOutfit+=[g_sCurrentFolder+llList2String(lItem,0)];
        else if (iWorn>=20) g_lOutfit=[g_sCurrentFolder+llList2String(lItem,0)]+g_lOutfit;
        if (iWorn%10>=2) g_lToCheck+=[g_sCurrentFolder+llList2String(lItem,0)];
    }
    if (llGetListLength(g_lToCheck)>0)
    {
        g_sCurrentFolder=llList2String(g_lToCheck,-1);
        g_lToCheck=llDeleteSubList(g_lToCheck,-1,-1);
        QueryFolders("save");
    }
    else
    {
        Notify(g_kAsyncMenuUser,"Current outfit has been saved.", TRUE);
        g_sCurrentFolder="";
        if (g_iAsyncMenuRequested)
        {
            g_iAsyncMenuRequested=FALSE;
            llMessageLinked(LINK_SET, g_iAsyncMenuAuth, "menu "+g_sParentMenu, g_kAsyncMenuUser);
        }
    }
}

handleMultiSearch()
{
    string sItem=llList2String(g_lSearchList,0);
    string pref1 = llGetSubString(sItem, 0, 0);
    string pref2 = llGetSubString(sItem, 0, 1);
    g_lSearchList=llDeleteSubList(g_lSearchList,0,0);

    if (pref1 == "+" || pref1 == "&") g_sFolderType = "searchattach";
    else if (pref1 == "-") g_sFolderType = "searchdetach";
    else jump next;  // operator was omitted, then repeat last action

    if (pref2 == "++" || pref2 == "--" || pref2 == "&&")
    {
        g_sFolderType += "all";
        sItem = llToLower(llGetSubString(sItem,2,-1));
    }
    else sItem = llToLower(llGetSubString(sItem,1,-1));

    if (pref1 == "&") g_sFolderType += "over";

    @next;
    
    searchSingle(sItem);
}

string g_sFirstsearch;
string g_sNextsearch;
string g_sBuildpath;

searchSingle(string sItem)
{
    //open listener
    g_iFolderRLV = 9999 + llRound(llFrand(9999999.0));
    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
    //start timer
    g_sFirstsearch="";
    g_sNextsearch="";
    g_sBuildpath="";
    if(~llSubStringIndex(sItem,"/"))
    {
        //we're doing a two-level search.
        list tlist=llParseString2List(sItem,["/"],[]);
        g_sFirstsearch=llList2String(tlist,0);
        g_sNextsearch=llList2String(tlist,1);
        sItem=g_sFirstsearch;
    }
    llSetTimerEvent(g_iTimeOut);
    //llMessageLinked(LINK_SET, RLV_CMD,  "findfolder:"+sItem+"="+(string)g_iFolderRLV, NULL_KEY);
    if ((g_iRLVaOn) && (g_sNextsearch == "")) { //use multiple folder matching from RLVa if we have it
        llOwnerSay("@findfolders:"+sItem+"="+(string)g_iFolderRLV); //Unstored one-shot commands are better performed locally to save the linked message.
    }
    else llOwnerSay("@findfolder:"+sItem+"="+(string)g_iFolderRLV); //Unstored one-shot commands are better performed locally to save the linked message.

}

// set a dialog to be requested after the next viewer answer
SetAsyncMenu(key kAv, integer iAuth)
{
    g_iAsyncMenuRequested = TRUE;
    g_kAsyncMenuUser = kAv;
    g_iAsyncMenuAuth = iAuth;
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));
    if (llToLower(sStr) == "#rlv" || sStr == "menu Browse #RLV")
    {
        g_sCurrentFolder = "";
        QueryFolders("browse");
        SetAsyncMenu(kID, iNum);
    }
    else if (llToLower(sStr) == "history" || sStr == "menu #RLV History")
    {
        HistoryMenu(kID, iNum);
    }
    else if (llToLower(llGetSubString(sStr, 0, 4)) == "#rlv ")
    {
        SetAsyncMenu(kID, iNum);
        g_sFolderType = "searchbrowse";
        string sPattern = llDeleteSubString(sStr,0, 4);
        llOwnerSay("Searching folder containing string \"" + sPattern + "\" for browsing.");
        searchSingle(sPattern);
    }
    else if (sStr=="save" /*|| sStr=="menu Save"*/)
    {
        g_sCurrentFolder = "";
        g_lOutfit=[];
        g_lToCheck=[];
        QueryFolders("save");
        //if (sCommand == "menu") SetAsyncMenu(kID, iNum);
        g_kAsyncMenuUser = kID; // needed for notifying
    }
    else if (sStr=="restore"/*|| sStr=="menu Restore"*/)
    {
        integer i = 0; integer n = llGetListLength(g_lOutfit);
        for (; i < n; ++i)
            llMessageLinked(LINK_SET, RLV_CMD,  "attachover:" + llList2String(g_lOutfit,i) + "=force", NULL_KEY);
        Notify(kID, "Saved outfit has been restored.", TRUE );
        //if (sCommand == "menu") llMessageLinked(LINK_SET, iNum, "menu "  + g_sParentMenu, kID);;
    }
    else if (llGetSubString(sStr,0,0)=="+"||llGetSubString(sStr,0,0)=="-"||llGetSubString(sStr,0,0)=="&")
    {
        g_kAsyncMenuUser = kID;
        g_lSearchList=llParseString2List(sStr,[","],[]);
        handleMultiSearch();
    }
    else if (iNum <= COMMAND_GROUP)
    {
        list lArgs = llParseStringKeepNulls(sStr, ["="], []);
        integer val;
        if (llList2String(lArgs,0)=="unsharedwear") val = 0x2;
        else if (llList2String(lArgs,0)=="unsharedunwear") val = 0x1;
        else return TRUE;
        if (llList2String(lArgs,1)=="y") updateUnsharedLocks(0, val);
        else if (llList2String(lArgs,1)=="n") updateUnsharedLocks(val, 0);
        else return TRUE;
    }
    return TRUE;
}

default
{
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        //integer i;
        //for (i=0;i < llGetListLength(g_lChildren);i++)
        //{
        //    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + llList2String(g_lChildren,i), "");
        //}
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            integer i;
            for (i=0;i < llGetListLength(g_lChildren);i++)
            {
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + llList2String(g_lChildren,i), "");
            }
        }
        else if (iNum == RLV_CLEAR) //this triggers for safeword as well
        {
            g_lFolderLocks = [];
            llMessageLinked(LINK_SET, LM_SETTING_DELETE,  g_sScript + "Locks", NULL_KEY);
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == RLVA_VERSION) g_iRLVaOn = TRUE;
        else if (iNum == DIALOG_RESPONSE)
        {
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMessage = llList2String(lMenuParams, 1);
            g_iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);
            if (kID == g_kHistoryMenuID)
            {

                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    return;
                }
                else
                {
                    g_sCurrentFolder = sMessage;
                    g_iPage = 0;
                    SetAsyncMenu(kAv, iAuth);
                    QueryFolders("history");                    
                }
            }
            else if (kID == g_kMultipleFoldersOnSearchMenuID) {
                if (sMessage == UPMENU) {
                        g_sCurrentFolder = "";
                        QueryFolders("browse");
                        return;
                }
                llMessageLinked(LINK_SET, RLV_CMD, llGetSubString(g_sFolderType,6,-1)+":"+sMessage+"=force", NULL_KEY);
                addToHistory(sMessage);
                Notify(kAv, "Now "+llGetSubString(g_sFolderType,6,11)+"ing "+sMessage, TRUE);            
            }
            else if (kID == g_kRootActionsID)
            {
                if (sMessage == UPMENU)
                {
                    SetAsyncMenu(kAv, iAuth); QueryFolders("browse");
                }
                else if (sMessage == "Save") UserCommand(iAuth, "save", kAv);
                else if (sMessage == "Restore") UserCommand(iAuth, "restore", kAv);
                else if (sMessage == lockUnsharedButton(0, 0))
                {
                    if (g_iUnsharedLocks & 0x1) {
                        updateUnsharedLocks(0x0, 0x1);
                        Notify(kAv, "Now removing unshared items is no longer forbidden.", TRUE);
                    }
                    else {
                        updateUnsharedLocks(0x1, 0x0);
                        Notify(kAv, "Now removing unshared items is forbidden.", TRUE);
                    }
                }
                else if (sMessage == lockUnsharedButton(1, 0))
                {
                    if (g_iUnsharedLocks & 0x2) {
                        updateUnsharedLocks(0x0, 0x2);
                        Notify(kAv, "Now wearing unshared items is no longer forbidden.", TRUE);
                    }
                    else {
                        updateUnsharedLocks(0x2, 0x0);
                        Notify(kAv, "Now wearing unshared items is forbidden.", TRUE);
                    }
                }
                RootActionsMenu(kAv, iAuth);
            }
            else if (kID == g_kBrowseID)
            {

                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    return;
                }
                else if (sMessage == ROOT_ACTIONS)
                {
                    RootActionsMenu(kAv, iAuth);
                    return;
                }
                else if (sMessage == ACTIONS_CURRENT)
                {
                    FolderActionsMenu(g_iLastFolderState, kAv, iAuth);
                    return;
                }
                else if (sMessage == PARENT)
                {
                    ParentFolder();
                }
                else
                { //we got a folder.  send the RLV command to remove/attach it.
                    integer iState = StateFromButton(sMessage);
                    string folder = FolderFromButton(sMessage);
                    if (g_sCurrentFolder == "") g_sCurrentFolder = folder;
                    else g_sCurrentFolder  += "/" + folder;
                    if ((iState % 10) == 0)
                    { // open actions menu if requested folder does not have subfolders
                        FolderActionsMenu(iState, kAv, iAuth);
                        return;
                    }
                }
                g_iPage = 0;
                SetAsyncMenu(kAv, iAuth);
                QueryFolders("browse");
            }

            else if (kID == g_kActionsID)
            {

                if (sMessage == ADD)
                {
                    llMessageLinked(LINK_SET, RLV_CMD, "attachover:" + g_sCurrentFolder + "=force", NULL_KEY);
                    Notify(kAv, "Now adding "+g_sCurrentFolder, TRUE);
                }
                else if (sMessage == REPLACE)
                {
                    llMessageLinked(LINK_SET, RLV_CMD, "attach:" + g_sCurrentFolder + "=force", NULL_KEY);
                    addToHistory(g_sCurrentFolder);
                    Notify(kAv, "Now attaching "+g_sCurrentFolder, TRUE);
                }
                else if (sMessage == DETACH)
                {
                    llMessageLinked(LINK_SET, RLV_CMD, "detach:" + g_sCurrentFolder + "=force", NULL_KEY);
                    Notify(kAv, "Now detaching "+g_sCurrentFolder, TRUE);
                }
                else if (sMessage == ADD_ALL)
                {
                    llMessageLinked(LINK_SET, RLV_CMD, "attachallover:" + g_sCurrentFolder + "=force", NULL_KEY);
                    Notify(kAv, "Now adding everything in "+g_sCurrentFolder, TRUE);
                }
                else if (sMessage == REPLACE_ALL)
                {
                    llMessageLinked(LINK_SET, RLV_CMD, "attachall:" + g_sCurrentFolder  + "=force", NULL_KEY);
                    Notify(kAv, "Now attaching everything in "+g_sCurrentFolder, TRUE);
                }
                else if (sMessage == DETACH_ALL)
                {
                    llMessageLinked(LINK_SET, RLV_CMD, "detachall:" + g_sCurrentFolder  + "=force", NULL_KEY);
                    Notify(kAv, "Now detaching everything in "+g_sCurrentFolder, TRUE);
                }
                else if (sMessage == lockFolderButton(0x00, 0, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x01, 0x10);
                    Notify(kAv, "Now wearing "+g_sCurrentFolder+ " is forbidden (this overrides parent exceptions).", TRUE);
                }
                else if (sMessage == lockFolderButton(0x00,1, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x02, 0x20);
                    Notify(kAv, "Now removing "+g_sCurrentFolder+ " is forbidden (this overrides parent exceptions).", TRUE);
                }
                else if (sMessage == lockFolderButton(0x00, 2, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x04, 0x40);
                    Notify(kAv, "Now wearing "+g_sCurrentFolder+ " or its subfolders is forbidden (this overrides parent exceptions).", TRUE);
                }
                else if (sMessage == lockFolderButton(0x00, 3, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x08, 0x80);
                    Notify(kAv, "Now removing "+g_sCurrentFolder+ " or its subfolders is forbidden (this overrides parent exceptions).", TRUE);
                }
                else if (sMessage == lockFolderButton(0x0F, 0, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x10, 0x01);
                    Notify(kAv, "Now wearing "+g_sCurrentFolder+ " is exceptionally allowed (this overrides parent locks).", TRUE);
                }
                else if (sMessage == lockFolderButton(0x0F, 1, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x20, 0x02);
                    Notify(kAv, "Now removing "+g_sCurrentFolder+ " is exceptionally allowed (this overrides parent locks).", TRUE);
                }
                else if (sMessage == lockFolderButton(0x0F,2, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x40, 0x04);
                    Notify(kAv, "Now wearing "+g_sCurrentFolder+ " or its subfolders is exceptionally allowed (this overrides parent locks).", TRUE);
                }
                else if (sMessage == lockFolderButton(0x0F,3, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0x80, 0x08);
                    Notify(kAv, "Now removing "+g_sCurrentFolder+ " or its subfolders is exceptionally allowed (this overrides parent locks).", TRUE);
                }
                else if (sMessage == lockFolderButton(0xFFFF,0, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0, 0x11);
                    Notify(kAv, "Now there is no restriction or exception on wearing "+g_sCurrentFolder+ ".", TRUE);
                }
                else if (sMessage == lockFolderButton(0xFFFF,1, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0, 0x22);
                    Notify(kAv, "Now there is no restriction or exception on removing "+g_sCurrentFolder+ ".", TRUE);
                }
                else if (sMessage == lockFolderButton(0xFFFF,2, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0, 0x44);
                    Notify(kAv, "Now there is no restriction or exception on wearing "+g_sCurrentFolder+ " and its subfolders.", TRUE);
                }
                else if (sMessage == lockFolderButton(0xFFFF,3, 0))
                {
                    updateFolderLocks(g_sCurrentFolder, 0, 0x88);
                    Notify(kAv, "Now there is no restriction or exception on removing "+g_sCurrentFolder+ " and its subfolders.", TRUE);
                }
                else if (llGetSubString(sMessage, 0, 0) == "(") Notify(kAv, "This action is forbidden at your authentification level.", FALSE);
                if (sMessage != UPMENU) { addToHistory(g_sCurrentFolder); llSleep(1.0);} //time for command to take effect so that we see the result in menu
                //Return to browse menu
                if (llGetSubString(g_sFolderType, 0, 14) == "history_actions" && sMessage != "Browse") {HistoryMenu(kAv, iAuth); return;}
                if (llGetSubString(g_sFolderType, -4, -1) == "_sub") ParentFolder();
                SetAsyncMenu(kAv, iAuth);
                QueryFolders("browse");
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "Locks")
                {
                    g_lFolderLocks = llParseString2List(sValue, [","], []);
                    integer iN = llGetListLength(g_lFolderLocks);
                    integer i;
                    for (i = 0; i < iN; i += 2) doLockFolder(i);
                }
                else if (sToken == "Unshared")
                {
                    g_iUnsharedLocks = (integer) sValue;
                    doLockUnshared();
                }
            }
        }
    }

    listen(integer iChan, string sName, key kID, string sMsg)
    {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
        if (iChan == g_iFolderRLV)
        {   //we got a list of folders
            if (g_sFolderType=="browse")
            {
                if (sMsg == "")
                { // try again if the folder name was wrong (may happen if the inventory changed)
                    g_sCurrentFolder = "";
                    g_iPage = 0;
                    QueryFolders("browse");
                }
                else FolderBrowseMenu(sMsg);
            }
            else if (g_sFolderType=="history")
            {
                list sData = llParseStringKeepNulls(sMsg, [",", "|"], []);
                integer iState = llList2Integer(sData, 1);
                FolderActionsMenu(iState, g_kAsyncMenuUser, g_iAsyncMenuAuth);
            }
            else if (g_sFolderType=="save") SaveFolder(sMsg);
            else if (llGetSubString(g_sFolderType,0,5)=="search")
            {
                if (sMsg=="") Notify(g_kAsyncMenuUser,sMsg+"No folder found", FALSE);
                else if (llGetSubString(g_sFolderType,6,-1)=="browse")                
                {
                    g_sCurrentFolder = sMsg;
                    QueryFolders("browse");
                }
                else
                {
                    if(g_sFirstsearch!="")
                    {
                        integer idx=llSubStringIndex(llToLower(sMsg),llToLower(g_sFirstsearch));
                        g_sBuildpath=llGetSubString(sMsg,0,idx);
                        sMsg=llDeleteSubString(sMsg,0,idx);
                        idx=llSubStringIndex(sMsg,"/");
                        g_sBuildpath+=llGetSubString(sMsg,0,idx);
                        g_sFirstsearch="";
                        g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
                        llSetTimerEvent(g_iTimeOut);
                        llOwnerSay("@getinv:"+g_sBuildpath+"="+(string)g_iFolderRLV); 
                    }
                    else
                    {
                        if(g_sNextsearch!="")
                        {
                            list tlist=llParseString2List(sMsg,[","],[]);
                            integer i=llGetListLength(tlist);
                            string found;
                            string test;
                            while(i)
                            {
                                --i;
                                test=llList2String(tlist,i);
                                if(~llSubStringIndex(llToLower(test),llToLower(g_sNextsearch)))
                                {
                                    i=0;
                                    found=test;
                                }
                            }
                            if(found=="")
                            {
                                 Notify(g_kAsyncMenuUser,g_sNextsearch+" subfolder not found", FALSE);
                                 return;
                            }
                            else sMsg=g_sBuildpath+"/"+found;
                            g_sNextsearch="";
                            g_sBuildpath="";
                        }
                        if ((llSubStringIndex(sMsg,",") >=0) && (g_iRLVaOn)) { //we have multiple results, bring up a menu
                            list lMultiFolders = llParseString2List(sMsg,[","],[]);
                            string sPrompt = "Multiple results found.  Please select an item\n";
                            sPrompt += "Current action is "+g_sFolderType+"\n";
                            g_kMultipleFoldersOnSearchMenuID = Dialog(g_kAsyncMenuUser, sPrompt, lMultiFolders, [UPMENU], 0, iChan);
                            return;
                        }
                        llMessageLinked(LINK_SET, RLV_CMD, llGetSubString(g_sFolderType,6,-1)+":"+sMsg+"=force", NULL_KEY);
                        addToHistory(sMsg);
                        Notify(g_kAsyncMenuUser, "Now "+llGetSubString(g_sFolderType,6,11)+"ing "+sMsg, TRUE);
                      }
                }
                if (g_lSearchList!=[]) handleMultiSearch();
            }
        }
    }

    timer()
    {
        llListenRemove(g_iListener);
        llSetTimerEvent(0.0);
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
}
