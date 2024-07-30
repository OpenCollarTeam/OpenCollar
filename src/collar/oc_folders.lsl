/*
This file is a part of OpenCollar.
Copyright 2020
: Contributors :
Aria (Tashia Redrose)
    * Aug 2020      -           Rewrote oc_folders for 8.0 Alpha 5
Medea (Medea Destiny)
    * June 2021     -   *Fix issue #570, Allow hiding folders starting with ~ via HideTilde option, defaults to ON. 
                        *Fix issue  #581, filtering input to UserCommand to only folder-auth check actual folder
                        commands rather than folder-authing and processing EVERYTHING THE COLLAR DOES BY ANY USER 
    * May 2022      -   *Fix issue #775, changed string handling to ensure command is not issued as part of search
                        term, added sanity checking for chat commands to ensure we don't try to search for nothing,
                        and no longer operate on empty search results. Issuer of chat command now stored as 
                        g_kChatUser so they can be notified if findfolder fails.

Neil2Ball & Sue Cripter - Fix for OpenSim, replacing invalid return r(); with {r(); return}
                         
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


string g_sParentMenu = "RLV";
string g_sSubMenu = "# Folders";


//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
//integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer QUERY_FOLDER_LOCKS = -9100;
integer REPLY_FOLDER_LOCKS = -9101;
integer SET_FOLDER_LOCK = -9102;
integer CLEAR_FOLDER_LOCKS = -9103;


integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}


integer g_iHideTilde=TRUE;

integer g_iTmpLstnChn;
integer g_iTmpLstn;
string CONFIG = "◌ Configure";
Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Folders]";
    list lButtons = ["Browse", CONFIG, "Clear Locks"];

    Dialog(kID,sPrompt,lButtons, [UPMENU], 0, iAuth, "Menu~Folders");
    //Browser(kID, iAuth, "");
}

integer g_iAccessBitSet=11;

string TrueOrFalse(integer iTest){
    if(iTest)return "true";
    else return "false";
}

/// LSL bools can be larger than 1 but will always return TRUE if not 0, slam it to a 1 or a 0 for simplicity, and to save on memory.
integer Bool(integer iTest){
    if(iTest)return TRUE;
    else return FALSE;
}

ConfigureMenu(key kID, integer iAuth){
    if(iAuth == CMD_OWNER){
        // allow configuration of access levels only to owner
        string sPrompt = "\n[Folders Configuration]\n\n";

        integer iTrusted = Bool((g_iAccessBitSet&1));
        integer iPublic = Bool((g_iAccessBitSet&2));
        integer iGroup = Bool((g_iAccessBitSet&4));
        integer iWearer = Bool((g_iAccessBitSet&8));
        string sTrusted = TrueOrFalse(iTrusted);
        string sPublic = TrueOrFalse(iPublic);
        string sGroup = TrueOrFalse(iGroup);
        string sWearer = TrueOrFalse(iWearer);
        Dialog(kID, sPrompt+"\n * Hide folders that start with '~': "+TrueOrFalse(g_iHideTilde)+"\n * Owner: ALWAYS\n * Trusted: "+sTrusted+"\n * Public: "+sPublic+"\n * Group: "+sGroup+"\n * Wearer: "+sWearer+"\n", [Checkbox(g_iHideTilde,"Hide ~"),Checkbox(iTrusted, "Trusted"), Checkbox(iPublic, "Public") ,Checkbox(iGroup, "Group"), Checkbox(iWearer, "Wearer")], [UPMENU], 0, iAuth, "Folders~Configure");


    }else {
        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to folders configuration", kID);
        Menu(kID,iAuth);
    }
}



string GoBackOneFolder(string sPath){
    list lTmp = llParseStringKeepNulls(sPath, ["/"],[]);
    lTmp=llDeleteSubList(lTmp,-1,-1);
    return llDumpList2String(lTmp,"/");
}

string MakePath(string sCurrent, string sNext){
    list lTmp = llParseStringKeepNulls(sCurrent, ["/"],[]);
    lTmp += sNext;
    return llDumpList2String(lTmp,"/");
}


key g_kMenuUser;
integer g_iMenuUser;
string g_sPath;

R(){
    llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to browsing #RLV folders", g_kMenuUser);
    Menu(g_kMenuUser, g_iMenuUser);
}
Browser(key kID, integer iAuth, string sPath){

    // Check auth real fast, then give menu, or kick back to main menu

    g_kMenuUser=kID;
    g_iMenuUser=iAuth;
    g_sPath = sPath;

    if(iAuth == CMD_TRUSTED && !Bool((g_iAccessBitSet&1))){ R(); return; }
    if(iAuth == CMD_EVERYONE && !Bool((g_iAccessBitSet&2))){ R(); return; }
    if(iAuth == CMD_GROUP && !Bool((g_iAccessBitSet&4))){ R(); return; }
    if(iAuth == CMD_WEARER && !Bool((g_iAccessBitSet&8))){ R(); return; }
    if (iAuth<CMD_OWNER || iAuth>CMD_EVERYONE) { R(); return; }



    llListenRemove(g_iTmpLstn);
    g_iTmpLstnChn = llRound(llFrand(438888));
    g_iTmpLstn = llListen(g_iTmpLstnChn, "", g_kWearer, "");

    llOwnerSay("@getinvworn:"+g_sPath+"="+(string)g_iTmpLstnChn);

    llResetTime();
    llSetTimerEvent(1);
}
integer g_iFindChn;
integer g_iFindLstn = -1;
integer g_iCmdMode = 0;
integer F_REMOVE = 1;
integer F_RECURSIVE = 2;
integer F_ADD = 4;
integer F_WEAR = 8;
key g_kChatUser; // user of a chat command, to notify if nothing found.

UserCommand(integer iNum, string sStr, key kID) {



    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        g_lOwner=[];
        g_lTrust=[];
        g_lBlock=[];
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    else if(llToLower(sStr) == "folders" || llToLower(sStr) == "menu folders")Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0;
        string sChangetype = llGetSubString(sStr,0,0);
        if(llListFindList(["&","-","+"],[sChangetype])==-1) return;
        sChangetype = llGetSubString(sStr, 0, 1);
        string sChangevalue = llStringTrim(llDeleteSubString(sStr, 0, 1), STRING_TRIM);
        //string sText;
        if(sChangevalue==""){ // don't search for empty strings.
             llMessageLinked(LINK_SET, NOTIFY, "0You have to supply a string to search for to use add/remove/wear commands.", kID);
             return; 
        } 
        g_kChatUser=kID;
        if(iNum == CMD_TRUSTED && !Bool((g_iAccessBitSet&1))){ R(); return; }
        if(iNum == CMD_EVERYONE && !Bool((g_iAccessBitSet&2))){ R(); return; }
        if(iNum == CMD_GROUP && !Bool((g_iAccessBitSet&4))){ R(); return; }
        if(iNum == CMD_WEARER && !Bool((g_iAccessBitSet&8))){ R(); return; }
        if(g_iFindLstn != -1)llListenRemove(g_iFindLstn);

        g_iFindChn = llRound(llFrand(99999999));
        g_iFindLstn =llListen(g_iFindChn, "", llGetOwner(), "");

        if(sChangetype == "--"){
            //llOwnerSay("@detachall:"+sChangevalue+"=force");
            g_iCmdMode=F_REMOVE | F_RECURSIVE;
            llOwnerSay("@findfolder:"+sChangevalue+"="+(string)g_iFindChn);
            return;
        } else if(sChangetype == "&&"){
            g_iCmdMode = F_ADD | F_RECURSIVE;
            //llOwnerSay("@attachallover:"+sChangevalue+"=force");
            llOwnerSay("@findfolder:"+sChangevalue+"="+(string)g_iFindChn);
            return;
        } else if(sChangetype == "++"){
            g_iCmdMode = F_ADD;
            //llOwnerSay("@attachall:"+sChangevalue+"=force");
            llOwnerSay("@findfolder:"+sChangevalue+"="+(string)g_iFindChn);
            return;
        }

        sChangetype = llGetSubString(sStr,0,0);
        sChangevalue = llStringTrim(llDeleteSubString(sStr, 0, 0), STRING_TRIM);
        if(sChangevalue==""){ // don't search for empty strings.
             llMessageLinked(LINK_SET, NOTIFY, "0You have to supply a string to search for to use add/remove/wear commands.", kID);
             return; 
        }
        if(sChangetype == "&"){
            // add folder path
            //llOwnerSay("@attachover:"+sChangevalue+"=force");
            g_iCmdMode = F_ADD;
            llOwnerSay("@findfolder:"+sChangevalue+"="+(string)g_iFindChn);
            return;
        } else if(sChangetype == "-"){
            //llOwnerSay("@detach:"+sChangevalue+"=force");
            g_iCmdMode = F_REMOVE;
            llOwnerSay("@findfolder:"+sChangevalue+"="+(string)g_iFindChn);
            return;
        } else if(sChangetype == "+"){
            //llOwnerSay("@attach:"+sChangevalue+"=force");
            g_iCmdMode=F_WEAR;
            llOwnerSay("@findfolder:"+sChangevalue+"="+(string)g_iFindChn);
            return;
        }
        llListenRemove(g_iFindLstn);
        g_iFindLstn = -1;
    }
}

//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;


key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;


list g_lFolderCheckboxes = ["▢", "▣", "◑"];
string Checkbox(integer iChecked, string sLabel){
    if(iChecked>3 || iChecked<0)iChecked=0;
    return llList2String(g_lFolderCheckboxes, iChecked)+" "+sLabel;
}


///The setor method is derived from a similar PHP proposed function, though it was denied,
///https://wiki.php.net/rfc/ifsetor
///The concept is roughly the same though we're not dealing with lists in this method, so is just modified
///The ifsetor proposal would give a function which would be more like
///ifsetor(list[index], sTrue, sFalse)
///LSL can't check if a list item is set without a stack heap if it is out of range, this is significantly easier for us to just check for a integer boolean
string setor(integer iTest, string sTrue, string sFalse){
    if(iTest)return sTrue;
    else return sFalse;
}



integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

integer g_iMenuAuth;

LocksMenu(key kAv, integer iAuth, integer iMask)
{
    string sPrompt = "[Folders]\n> Locks\n\nPath: "+g_sPath+"\n\n* The subfolder options will lock (check) / unlock (uncheck) this folder and all subfolders contained. It only affects your current path. To unlock every folder and clear all locks, see the main menu";
    list lButtons = [];
    if(iMask & 1)lButtons += [Checkbox(TRUE, "det. subfolder")];
    else lButtons += Checkbox(FALSE, "det. subfolder");
    if(iMask & 2)lButtons += [Checkbox(TRUE, "att. subfolder")];
    else lButtons += Checkbox(FALSE, "att. subfolder");
    if(iMask & 4)lButtons += [Checkbox(TRUE, "det. this")];
    else lButtons += [Checkbox(FALSE, "det. this")];
    if(iMask & 8)lButtons += [Checkbox(TRUE, "att. this")];
    else lButtons += [Checkbox(FALSE, "att. this")];

    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, "Folders~Locks");
}
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT){
            if(sStr == "reboot"){
                llResetScript();
            }
        } else if(iNum == READY){
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP){
            state active;
        }
    }
}
state active
{
    on_rez(integer t){
        llResetScript();
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
    }
    timer(){
        if(llGetTime()>=60.0){
            //llSay(0, "menu has timed out");
            llListenRemove(g_iTmpLstn);
            llSetTimerEvent(0);
        }
    }
    listen(integer iChan, string sName, key kID, string sMsg){
        if(iChan == g_iTmpLstnChn){
            /*
        0 : No item is present in that folder
        1 : Some items are present in that folder, but none of them is worn
        2 : Some items are present in that folder, and some of them are worn
        3 : Some items are present in that folder, and all of them are worn
            */

            list lFolders = llParseString2List(sMsg, [","],[]);
            list lButtons = [];

            list lTmp1 = llParseStringKeepNulls(llList2String(lFolders,0),["|"],[]);
            integer iSub1 = (integer)llGetSubString(llList2String(lTmp1,1),0,0);
            integer iSub2 = (integer)llGetSubString(llList2String(lTmp1,1),1,1);
            integer iState;
            if(iSub1 == 3 || iSub2 == 3) iState=1;
            else if(iSub1 == 2 || iSub2 == 2)iState = 2;
            else if(iSub1 == 1 || iSub2 == 1)iState=0;
            // Build menu prompt
            string sPrompt = "\n[Folder Browser]\n\nLegend:\n";
            sPrompt += llList2String(g_lFolderCheckboxes,0) + " = Nothing in the folder is worn, or any subfolders\n";
            sPrompt += llList2String(g_lFolderCheckboxes,1) + " = All items in either this folder or its subfolder are worn\n";
            sPrompt += llList2String(g_lFolderCheckboxes,2) + " = Some items are worn in this folder, or its subfolders\n";
            // show current folder with state indicator
            sPrompt += "\nCurrently browsing path: "+Checkbox(iState, setor(g_sPath == "", "#RLV", g_sPath))+"\n";
            // buttons for other folders
            integer i;
            integer len = llGetListLength(lFolders);
            for(i=1;i<len;++i){
                lTmp1 = llParseStringKeepNulls(llList2String(lFolders,i),["|"],[]);
                iSub1 = (integer)llGetSubString(llList2String(lTmp1,1),0,0);
                iSub2 = (integer)llGetSubString(llList2String(lTmp1,1),1,1);

                if(iSub1 == 3 || iSub2 == 3) iState=1;
                else if(iSub1 == 2 || iSub2 == 2)iState = 2;
                else if(iSub1 == 1 || iSub2 == 1)iState=0;
                if(g_iHideTilde==FALSE ||llGetSubString(llList2String(lTmp1,0),0,0)!="~")
                    lButtons += [Checkbox(iState, llList2String(lTmp1,0))];
            }
            list lLockOption=[];
            if(llGetInventoryType("oc_folders_locks")==INVENTORY_SCRIPT)lLockOption += ["Locks.."];
            Dialog(g_kMenuUser, sPrompt, lButtons, ["+ Add Items", "- Rem Items", setor((g_sPath == ""), UPMENU, "^ UP")]+lLockOption, 0, g_iMenuUser, "FolderBrowser~");
        } else if(iChan == g_iFindChn)
        {
            if(llStringTrim(sMsg,STRING_TRIM)==""){
                 llMessageLinked(LINK_SET, NOTIFY, "0Nothing matching that term was found in #RLV!", g_kChatUser);
                 return; // don't do anything if 
            } if(g_iCmdMode & F_RECURSIVE){
                if(g_iCmdMode & F_ADD){
                    llOwnerSay("@attachallover:"+sMsg+"=force");
                } else if(g_iCmdMode & F_WEAR){
                    llOwnerSay("@attachall:"+sMsg+"=force");
                }else if(g_iCmdMode & F_REMOVE){
                    llOwnerSay("@detachall:"+sMsg+"=force");
                }
            } else {
                if(g_iCmdMode & F_ADD){
                    llOwnerSay("@attachover:"+sMsg+"=force");
                }else if(g_iCmdMode & F_WEAR){
                    llOwnerSay("@attach:"+sMsg+"=force");
                }else if(g_iCmdMode & F_REMOVE){
                    llOwnerSay("@detach:"+sMsg+"=force");
                }
            }

            llListenRemove(g_iFindLstn);
            g_iFindLstn=-1;
        }
    }


    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRespring=TRUE;


                if(sMenu == "FolderBrowser~"){
                    if(sMsg == UPMENU) {
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else if(sMsg == "+ Add Items"){
                        llOwnerSay("@attachallover:"+g_sPath+"=force");
                        llSleep(2.0);
                    } else if(sMsg == "- Rem Items"){
                        llOwnerSay("@detachall:"+g_sPath+"=force");
                        llSleep(2.0);
                    } else if(sMsg == "Locks..")
                    {
                        iRespring=FALSE;
                        //LocksMenu(kAv, iAuth);
                        g_kMenuUser=kAv;
                        g_iMenuAuth = iAuth;
                        llMessageLinked(LINK_SET, QUERY_FOLDER_LOCKS, g_sPath, "");
                    } else if(sMsg == "^ UP"){
                        iRespring=FALSE;
                        Browser(kAv,iAuth, GoBackOneFolder(g_sPath));
                    } else {
                        list lTmpBtn = llParseString2List(sMsg, [" "], []);
                        string TheButton = llDumpList2String(llList2List(lTmpBtn,1,-1), " ");
                        Browser(kAv,iAuth, MakePath(g_sPath,TheButton));
                        iRespring=FALSE;
                    }


                    if(iRespring)Browser(kAv,iAuth, g_sPath);
                } else if(sMenu == "Folders~Locks"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Browser(kAv,iAuth, g_sPath);
                    }else if(sMsg == Checkbox(TRUE, "det. this") || sMsg==Checkbox(FALSE, "det. this")){
                        llMessageLinked(LINK_SET, SET_FOLDER_LOCK, "detachthis", g_sPath);
                    } else if(sMsg == Checkbox(TRUE, "att. this") || sMsg == Checkbox(FALSE, "att. this"))
                    {
                        llMessageLinked(LINK_SET, SET_FOLDER_LOCK, "attachthis", g_sPath);
                    } else if(sMsg == Checkbox(TRUE, "det. subfolder") || sMsg == Checkbox(FALSE, "det. subfolder")){
                        llMessageLinked(LINK_SET, SET_FOLDER_LOCK, "detachallthis", g_sPath);
                    } else if(sMsg == Checkbox(TRUE, "att. subfolder") || sMsg == Checkbox(FALSE, "att. subfolder")){
                        llMessageLinked(LINK_SET, SET_FOLDER_LOCK, "attachallthis", g_sPath);
                    }

                    if(iRespring)llMessageLinked(LINK_SET, QUERY_FOLDER_LOCKS, g_sPath, "");
                } else if(sMenu == "Menu~Folders"){
                    if(sMsg == "Browse"){
                        Browser(kAv,iAuth,"");
                        iRespring=FALSE;
                    } else if(sMsg == CONFIG){
                        ConfigureMenu(kAv,iAuth);
                        iRespring=FALSE;
                    } else if(sMsg == "Clear Locks"){
                        llMessageLinked(LINK_SET, CLEAR_FOLDER_LOCKS, "", "");
                    } else if(sMsg == UPMENU){
                        iRespring=FALSE;

                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }


                    if(iRespring)Menu(kAv,iAuth);
                } else if(sMenu == "Folders~Configure"){

                    // configuration menu
                    if(sMsg==UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else {

                        list ButtonFlags = llParseString2List(sMsg,[" "],[]);
                        string ButtonLabel = llDumpList2String(llList2List(ButtonFlags,1,-1), " ");
                        integer Enabled = llListFindList(g_lFolderCheckboxes, [llList2String(ButtonFlags,0)]);
                        if(ButtonLabel=="Hide ~")
                        {
                            g_iHideTilde=!g_iHideTilde;
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "folders_hidetilde="+(string)g_iHideTilde,"");
                        }
                        else if(Enabled){
                            // Disable flag
                            if(ButtonLabel == "Trusted")g_iAccessBitSet -=1;
                            else if(ButtonLabel == "Public")g_iAccessBitSet-=2;
                            else if(ButtonLabel == "Group")g_iAccessBitSet-=4;
                            else if(ButtonLabel == "Wearer")g_iAccessBitSet-=8;
                        }else{
                            if(ButtonLabel == "Trusted")g_iAccessBitSet+=1;
                            else if(ButtonLabel == "Public")g_iAccessBitSet+=2;
                            else if(ButtonLabel == "Group")g_iAccessBitSet+=4;
                            else if(ButtonLabel == "Wearer") g_iAccessBitSet+=8;
                        }

                        // save
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "folders_accessflags="+(string)g_iAccessBitSet, "");
                    }

                    if(iRespring) ConfigureMenu(kAv,iAuth);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);

            //integer ind = llListFindList(g_lSettingsReqs, [llList2String(lSettings,0)+"_"+llList2String(lSettings,1)]);
           // if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);


            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "checkboxes"){
                    g_lFolderCheckboxes = llParseString2List(llList2String(lSettings,2),[","],[])+["◑"];
                }
            } else if(llList2String(lSettings,0)=="folders"){
                if(llList2String(lSettings,1) == "accessflags"){
                    g_iAccessBitSet=(integer)llList2String(lSettings,2);
                } else if(llList2String(lSettings,1) =="hidetilde"){
                    g_iHideTilde=(integer)llList2String(lSettings,2);
                }
                
            }
        } else if(iNum == REPLY_FOLDER_LOCKS)
        {
            integer iMask = (integer)((string)kID);
            LocksMenu(g_kMenuUser, g_iMenuAuth, iMask);
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}
