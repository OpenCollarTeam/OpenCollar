//OpenCollar - rlvfolders
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

integer g_iRLVVer = 115; //temporary hack until we can parse the version string in a sensible way
//string g_sSubMenu = "#RLV Folder";
string g_sParentMenu = "Un/Dress";

list g_lChildren = ["Browse #RLV","Save","Restore"];

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer CHAT = 505;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "^";
string MORE = ">";
//string ALL = "*All*";
//string SELECT_CURRENT = "*This*";
string ATTACH_ALL = "(+) *All*";
string DETACH_ALL = "(-) *All*";
string ATTACH_THIS = "(+) *This*";
string DETACH_THIS = "(-) *This*";
string TICKED = "(*)";  //checked
string STICKED = "(.)";   //partchecked
string UNTICKED = "( )";
string FOLDER = " / ";

integer g_iTimeOut = 60;

integer g_iFolderRLV = 78467;

key g_kFolderID;
integer g_iPage = 0;//Having a global is nice, if you redisplay the menu after an action on a folder.

integer g_iListener;//Nan:do we still need this? -- SA: of course. It's where the viewer talks.

// Asynchronous menu request. Alas still needed since some menus are triggered after an answer from the viewer.
key g_kAsyncMenuUser;
integer g_iAsyncMenuAuth;
integer g_iAsyncMenuRequested = FALSE;

string sPrompt;//Nan: why is this global?
string g_sFolderType; //what to do with those folders
string g_sCurrentFolder;

string g_sDBToken = "folders";

list g_lOutfit; //saved folder list
list g_lToCheck; //stack of folders to check, used for subfolder tree search

list g_lSearchList; //list of folders to search

list g_lLongFolders; //full names of the subfolders in current folder 
list g_lShortFolders; //shortened names of the subfolders in s_Current folder 

key g_kWearer;


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

QueryFolders(string sType)
{
    g_sFolderType = sType;
    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
    llSetTimerEvent(g_iTimeOut);
    llMessageLinked(LINK_SET, RLV_CMD, "getinvworn"+g_sCurrentFolder+"=" + (string)g_iFolderRLV, NULL_KEY);                     
}

// Browsing menu, called asynchronously only (after querying folder state). Queries user and auth from globals.
FolderMenu(string sStr)
{
    g_iAsyncMenuRequested = FALSE;
    sPrompt = "";
//    if (g_iRLVVer>=115) sPrompt += "\nOnly folders with items you can "+g_sFolderType+" are shown.";
    sPrompt+="\n"+UNTICKED+": nothing worn. Make the sub wear it.";
    sPrompt+="\n"+STICKED+": some items worn. Make the sub remove them.";
    sPrompt+="\n"+TICKED+": all items worn. Make the sub remove them.";
    sPrompt+="\n"+FOLDER+": this folder has subfolders. Browse it.";
    //sStr will be in form of folder1,folder2,etc   <- RLV 1.15: not anymore:  |xx,folder1|xx,folder2|xx,etc
    //build menu of folders.
    //    list lButtons = llParseString2List(sStr, [","], []);
    list sData = llParseStringKeepNulls(sStr, [","], []);
    string sFirst = llList2String(sData, 0);
    sData = llListSort(llList2List(sData, 1, -1), 1, 1);
    integer i;
    list lItem;
    integer iWorn;
    g_lShortFolders = [];
    g_lLongFolders = [];
//    if (g_iRLVVer<115) lButtons= sData;
//    else {
        for (i=0;i<llGetListLength(sData);i++) {
            lItem=llParseString2List(llList2String(sData,i),["|"],[]);
            string sFolder = llList2String(lItem,0);
            iWorn=llList2Integer(lItem,1);
            if  (iWorn%10>=1)
            {
                g_lLongFolders += sFolder;
                g_lShortFolders += [llGetSubString(FOLDER+sFolder,0,20)];
            }
            else if  (iWorn==10)
            {
                g_lLongFolders += sFolder;
                g_lShortFolders += [llGetSubString(UNTICKED+sFolder,0,20)];
            }
            else if  (iWorn==20)
            {
                g_lLongFolders += sFolder;
                g_lShortFolders += [llGetSubString(STICKED+sFolder,0,20)];
            }
            else if  (iWorn==30)
            {
                g_lLongFolders += sFolder;
                g_lShortFolders += [llGetSubString(TICKED+sFolder,0,20)];
            }
        }
//    }
//    lButtons = llListSort(buttons, 1, TRUE);    
/*    if (buttoncount < 1 && g_sCurrentFolder!="") {
        if (g_sFolderType == "wear")
            llMessageLinked(LINK_SET, RLV_CMD,  "attach" + g_sCurrentFolder + "=force", NULL_KEY);
        else if (g_sFolderType == "remove")
            llMessageLinked(LINK_SET, RLV_CMD,  "detach" + g_sCurrentFolder + "=force", NULL_KEY);
        ParentFolder();
        g_sMenuUser = kID;                
        QueryFolders();
    }
    else
    {
        if (g_iRLVVer>=115) {
*/
            // now add the button for wearing all recursively when it makes sense
            if (g_sCurrentFolder!="") {
                lItem=llParseString2List(sFirst,["|"],[]);
                iWorn=llList2Integer(lItem,0);
                if  (iWorn%10==1)  {g_lShortFolders+= [ATTACH_ALL]; g_lLongFolders+=[];}
                else if  (iWorn%10==2)  {g_lShortFolders+= [ATTACH_ALL, DETACH_ALL]; g_lLongFolders+=[];}
                else if  (iWorn%10==3)  {g_lShortFolders+= [DETACH_ALL]; g_lLongFolders+=[];}
                // and only then add the button for current foldder... if it makes also sense
                if  (iWorn/10==1)  {g_lShortFolders+= [ATTACH_THIS]; g_lLongFolders+=[];}
                else if  (iWorn/10==2)  {g_lShortFolders+= [ATTACH_THIS, DETACH_THIS]; g_lLongFolders+=[];}
                else if  (iWorn/10==3)  {g_lShortFolders+= [DETACH_THIS]; g_lLongFolders+=[];}
            }
//        }
//        if ((g_iRLVVer>=115&&llGetListLength(sData)<=1)||llGetListLength(sData)<=0) sPrompt = "\n\nEither your #RLV folder is empty, or you did not set up your shared folders.\nCheck Real Restraint blog for more information.";
//        else
        if (g_lShortFolders==[]) sPrompt = "\n\nThere is no item to "+g_sFolderType+" in the current folder.";
        else g_kFolderID = Dialog(g_kAsyncMenuUser, sPrompt, g_lShortFolders, [UPMENU], g_iPage, g_iAsyncMenuAuth);

}

SaveFolder(string sStr)
{
    list sData = llParseString2List(sStr, [","], []);
    integer i;
    list lItem;
    integer iWorn;
    if (g_sCurrentFolder=="") g_sCurrentFolder=":"; else g_sCurrentFolder+="/";
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
    string sSearchStr;
    g_lSearchList=llDeleteSubList(g_lSearchList,0,0);
    if (llGetSubString(sItem,0,1)=="++")
    {
        g_sFolderType = "searchattachall";
        sSearchStr = llToLower(llGetSubString(sItem,2,-1));
    }
    else if (llGetSubString(sItem,0,0)=="+")
    {
        g_sFolderType = "searchattach";
        sSearchStr = llToLower(llGetSubString(sItem,1,-1));
    }
    else if (llGetSubString(sItem,0,1)=="--")
    {
        g_sFolderType = "searchdetachall";
        sSearchStr = llToLower(llGetSubString(sItem,2,-1));
    }
    else if (llGetSubString(sItem,0,0)=="-")
    {
        g_sFolderType = "searchdetach";
        sSearchStr = llToLower(llGetSubString(sItem,1,-1));
    }
    //open listener
    g_iListener = llListen(g_iFolderRLV, "", llGetOwner(), "");
    //start timer
    llSetTimerEvent(g_iTimeOut);
    llMessageLinked(LINK_SET, RLV_CMD,  "findfolder:"+sSearchStr+"="+(string)g_iFolderRLV, NULL_KEY);       
}

// set a dialog to be requested after the next viewer answer
SetAsyncMenu(key kAv, integer iAuth)
{
    g_iAsyncMenuRequested = TRUE;
    g_kAsyncMenuUser = kAv;
    g_iAsyncMenuAuth = iAuth;
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();         
        g_iFolderRLV = 9999 + llRound(llFrand(9999999.0));
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            integer i;
            for (i=0;i < llGetListLength(g_lChildren);i++)              
            {
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + llList2String(g_lChildren,i), NULL_KEY);
            }
        }
        else if (iNum == RLV_VERSION)
        {   //get rlv version
            g_iRLVVer=(integer) sStr;
        }  
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            list lParams = llParseString2List(sStr, [" "], []);
            string sCommand = llToLower(llList2String(lParams, 0));
            string sValue = llToLower(llList2String(lParams, 1));
            if (llToLower(sStr) == "#rlv" || sStr == "menu Browse #RLV")
            {
                
                g_sCurrentFolder = "";
                QueryFolders("browse"); 
                if (sCommand == "menu") SetAsyncMenu(kID, iNum);
            }
            else if (sStr=="save" || sStr=="menu Save")
            {
                g_sCurrentFolder = "";
                g_lOutfit=[];
                g_lToCheck=[];
                QueryFolders("save");
                if (sCommand == "menu") SetAsyncMenu(kID, iNum);
                else g_kAsyncMenuUser = kID; // needed for notifying
            }
            else if (sStr=="restore"|| sStr=="menu Restore")
            {
                integer i;
                for (i=0; i<=llGetListLength(g_lOutfit);i++)
                    llMessageLinked(LINK_SET, RLV_CMD,  "attach" + llList2String(g_lOutfit,i) + "=force", NULL_KEY);
                Notify(kID, "Saved outfit has been restored.", TRUE );
                if (sCommand == "menu") llMessageLinked(LINK_SET, iNum, "menu "  + g_sParentMenu, kID);;
            }
            else if (llGetSubString(sStr,0,0)=="+"||llGetSubString(sStr,0,0)=="-")
            {
                g_kAsyncMenuUser = kID;
                g_lSearchList=llParseString2List(sStr,[","],[]);
                handleMultiSearch();
            }
        }  
        else if (iNum == DIALOG_RESPONSE)
        {            
            if (kID == g_kFolderID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                g_iPage = (integer)llList2String(lMenuParams, 2);                
                integer iAuth = (integer)llList2String(lMenuParams, 3);                
                if (sMessage == UPMENU)
                {
                    if (g_sCurrentFolder=="")
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    }
                    else 
                    {
                        ParentFolder();
                        SetAsyncMenu(kAv, iAuth);                
                        QueryFolders("browse");
                    }
                }
                else
                { //we got a folder.  send the RLV command to remove/attach it.
                    integer iIndex = llListFindList(g_lShortFolders,[sMessage]);
                    string oldfolder = g_sCurrentFolder;
                    if (sMessage == ATTACH_THIS)
                    {
                        llMessageLinked(LINK_SET, RLV_CMD,  "attach" + g_sCurrentFolder + "=force", NULL_KEY);
                        Notify(kAv, "Now attaching "+g_sCurrentFolder, TRUE);
                    }
                    else if (sMessage == DETACH_THIS)
                    {
                        llMessageLinked(LINK_SET, RLV_CMD,  "detach" + g_sCurrentFolder + "=force", NULL_KEY);
                        Notify(kAv, "Now detaching "+g_sCurrentFolder, TRUE);
                    }
                    else if (sMessage == ATTACH_ALL)
                    {
                        llMessageLinked(LINK_SET, RLV_CMD,  "attachall" + g_sCurrentFolder + "=force", NULL_KEY);
                        Notify(kAv, "Now attaching everything in "+g_sCurrentFolder, TRUE);
                    }
                    else if (sMessage == DETACH_ALL)
                    {
                        llMessageLinked(LINK_SET, RLV_CMD,  "detachall" + g_sCurrentFolder + "=force", NULL_KEY);
                        Notify(kAv, "Now detaching everything in "+g_sCurrentFolder, TRUE);
                    }
                    else if (iIndex != -1)
                    {
                        string cstate = llGetSubString(sMessage,0,llStringLength(TICKED) - 1);
                        string newfolder;
                        string folder = llList2String(g_lLongFolders,iIndex);
                        if (g_sCurrentFolder=="") newfolder=":"+folder;
                        else newfolder = g_sCurrentFolder + "/" + folder;
                        if (cstate==FOLDER || cstate==STICKED) {g_sCurrentFolder=newfolder; g_iPage = 0;}
                        else if (cstate==TICKED)
                        {
                            llMessageLinked(LINK_SET, RLV_CMD,  "detach" + newfolder + "=force", NULL_KEY);
                            Notify(kAv, "Now detaching "+newfolder, TRUE);
                        }
                        else if (cstate==UNTICKED)
                        {
                            llMessageLinked(LINK_SET, RLV_CMD,  "attach" + newfolder + "=force", NULL_KEY);
                            Notify(kAv ,"Now attaching "+newfolder, TRUE);
                        }
                    }
                    if (oldfolder==g_sCurrentFolder)
                    {
                        llSleep(1.0); //time for command to take effect so that we see the result in menu
                    }
                    //Return menu
                    SetAsyncMenu(kAv, iAuth);                
                    QueryFolders("browse");
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
            if (g_sFolderType=="browse") FolderMenu(sMsg);
            else if (g_sFolderType=="save") SaveFolder(sMsg);
            else if (llGetSubString(g_sFolderType,0,5)=="search")
            {
                if (sMsg=="") Notify(kID,sMsg+"No matching folder found", FALSE);
                else
                {
                    llMessageLinked(LINK_SET, RLV_CMD,  llGetSubString(g_sFolderType,6,-1)+":"+sMsg+"=force", NULL_KEY);
                    Notify(g_kAsyncMenuUser, "Now "+llGetSubString(g_sFolderType,6,11)+"ing "+sMsg, TRUE);
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
