/*
oc_outfits
This file is a part of OpenCollar.
Copyright ©2020

: Contributors :

Aria (Tashia Redrose)
    * Dec 2019      - Rewrote Capture & Reset Script Version to 1.0
    * Jan 2020      - Added BrowseCore, and added in chat commands for Outfits
    * Apr 2020      - Added chat commands, and a link message API to wear/remove
    * Dec 2020      - Fix up change commands to be more obvious
    * Jan 2021      - Fix browse core to have a remove button
Felkami (Caraway Ohmai)
    * Jan 2021      - #461, Made menu call case insensitive
Lillith (Lillith Xue)
    * Dec 2019      - Fixed bug: Outfits not working for non-wearer as menu user due to listen typo

et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


string g_sParentMenu = "Apps";
string g_sSubMenu = "Outfits";
string g_sAppVersion = "1.6";
//string g_sScriptVersion = "8.0";


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
string g_sLastOutfit;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer OUTFITS_ADD = -999901;
integer OUTFITS_REM = -999902;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["▢", "▣"];
string TickBox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

integer g_iLockCore = FALSE;
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Outfits App "+g_sAppVersion+"]\n\nChat Commands: \n-> wear <path>\n-> naked";
    list lButtons = [TickBox(g_iLockCore, "Lock Core"), "◌ Configure", "Browse", "BrowseCore", "Help" ];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}
string TrueOrFalse(integer iCheck){
    if(iCheck)return "True";
    else return "False";
}
integer Bool(integer iNumber){ // for one liners that need the integer to be a boolean
    if(iNumber)return TRUE;
    else return FALSE;
}
    
string g_sPath;
integer g_iListenHandle; // Will be unset if no actions for 30 seconds
integer g_iListenChannel; // Will also be unset if no actions for 30 seconds
integer g_iListenTimeout;
key g_kListenTo;
integer g_iListenToAuth;

DoBrowserPath(list Options, key kListenTo, integer iAuth){
    string sAppend;
    list lAppend = [];
    if(llSubStringIndex(g_sPath, GetFolderName(TRUE))!=-1){
        sAppend="\n\n* You are browsing "+GetFolderName(TRUE)+"! This will change which items in your core folder are actively worn. This will work similarly to #Folders, to remove other core items, you will need to go to that folder and select >Remove<, it will not be automatic here!";
        lAppend = [">REMOVE<"];
    }
    Dialog(kListenTo, "[Outfit Browser]\n \nLast outfit worn: "+g_sLastOutfit+"\n \n* You are currently browsing: "+g_sPath+"\n \n*Note: >Wear< will wear the current outfit, removing any other worn outfit, Naked will remove all worn outfits. Aside from .core", Options, [">Wear<", ">Naked<", UPMENU, "^"]+lAppend, 0, iAuth, "Browser");
}


TickBrowser(){
    g_iListenTimeout = llGetUnixTime()+90;
}
integer TimedOut(){
    if(llGetUnixTime()>g_iListenTimeout)return TRUE;
    else return FALSE;
}

FolderBrowser (key kID, integer iAuth){
    g_sPath = GetOutfitSystem(FALSE);
    g_kListenTo = kID;
    g_iListenToAuth=iAuth;
    g_iListenChannel = llRound(llFrand(99999999));
    if(g_iListenHandle>0)llListenRemove(g_iListenHandle);
    g_iListenHandle = llListen(g_iListenChannel, "", g_kWearer, "");
    TickBrowser();
    
    llOwnerSay("@getinv:"+g_sPath+"="+(string)g_iListenChannel);
    llSetTimerEvent(1);
}

CoreBrowser(key kID, integer iAuth){
    g_sPath = GetOutfitSystem(TRUE);
    g_kListenTo = kID;
    g_iListenToAuth = iAuth;
    g_iListenChannel = llRound(llFrand(9999999));
    if(g_iListenHandle>0) llListenRemove(g_iListenHandle);
    g_iListenHandle = llListen(g_iListenChannel, "", g_kWearer, "");
    TickBrowser();
    
    llOwnerSay("@getinv:"+g_sPath+"="+(string)g_iListenChannel);
    llSetTimerEvent(1);
}

ConfigMenu(key kID, integer iAuth){
    integer iTrusted = Bool((g_iAccessBitSet&1));
    integer iPublic = Bool((g_iAccessBitSet&2));
    integer iGroup = Bool((g_iAccessBitSet&4));
    integer iWearer = Bool((g_iAccessBitSet&8));
    integer iJail = Bool((g_iAccessBitSet&16));
    integer iStripAll = Bool((g_iAccessBitSet&32));
    string sTrusted = TrueOrFalse(iTrusted);
    string sPublic = TrueOrFalse(iPublic);
    string sGroup = TrueOrFalse(iGroup);
    string sWearer = TrueOrFalse(iWearer);
    string sJail = TrueOrFalse(iJail);
    string sStripAll = TrueOrFalse(iStripAll);
    
    Dialog(kID, "\n[Outfits App "+g_sAppVersion+"]\n \nConfigure Access\n * Owner: ALWAYS\n * Trusted: "+sTrusted+"\n * Public: "+sPublic+"\n * Group: "+sGroup+"\n * Wearer: "+sWearer+"\n * Jail: "+sJail+"\n * Strip All (even not in .outfits): "+sStripAll+"\n \n** WARNING: If you disable the jail, then outfits WILL be able to browse your entire #RLV folder, not just under #RLV/.outfits", [TickBox(iTrusted, "Trusted"), TickBox(iPublic, "Public") ,TickBox(iGroup, "Group"), TickBox(iWearer, "Wearer"), TickBox(iJail, "Jail"), TickBox(iStripAll, "Strip All")], [UPMENU], 0, iAuth, "Menu~Configure");
}


/*  Guard method. Tests if the user is authorized
    
    Return:
        FALSE == Allow access
        1 == Deny
        2 == Deny and notify
*/
integer AuthDenied(integer iNum) {
    integer deny = FALSE;
    
    if(iNum == 599) deny = 1;//No Access
    // Verify access rights now
    if(iNum > CMD_EVERYONE) deny = 1;
    if(iNum == CMD_TRUSTED && !Bool((g_iAccessBitSet&1))) deny = 2; 
    if(iNum == CMD_EVERYONE && !Bool((g_iAccessBitSet&2))) deny = 2; 
    if(iNum == CMD_GROUP && !Bool((g_iAccessBitSet&4))) deny = 2; 
    if(iNum == CMD_WEARER && !Bool((g_iAccessBitSet&8))) deny = 2; 
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) deny = 1;
    
    return deny;
}

UserCommand(integer iNum, string sStr, key kID) {

    integer deny = AuthDenied(iNum);
    if(deny == 2) {
        //We have to validate against known commands for Outfits, or else we'll pop denied errors every time a public user sneezes
        string sChangetype = llToLower(llList2String(llParseString2List(sStr, [" "], []),0));
        
        if(llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+ llToLower(g_sSubMenu) || sChangetype == "wear" || sChangetype == "naked")
            llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% to outifts", kID);
    }
    if(deny) return;
    
    //if (llSubStringIndex(sStr,llToLower(g_sSubMenu)) && sStr != "menu "+g_sSubMenu) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+ llToLower(g_sSubMenu)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0; 
        list Params=llParseString2List(sStr, [" "], []);
        
        string sChangetype = llToLower(llList2String(Params,0));
        string sChangevalue = llDumpList2String(llList2List(Params,1,-1)," ");
        //string sText;
        
        if(sChangetype == "wear" || sChangetype == "naked"){
            if(g_sPath!=sChangevalue){
                g_sPath=GetFolderName(FALSE)+"/"+sChangevalue;
                g_iListenTimeout=0;
            }
            
            if(!g_iLocked){
                llOwnerSay("@detach=n");
            }
                    
            ForceLockCore();
            TickBrowser();
            llSetTimerEvent(1);
            if(!Bool((g_iAccessBitSet&32))){
                if(llSubStringIndex(g_sPath, GetFolderName(TRUE))==-1)
                    llOwnerSay("@detachall:"+GetFolderName(FALSE)+"=force");
            }
            else{
                llOwnerSay("@detach=force");
                llOwnerSay("@remoutfit=force");
            }
            llSleep(2); // incase of lag
            string sAppend;
            if(g_iRLVa)sAppend=RLVA_APPEND;
            if (g_sPath == GetOutfitSystem(FALSE)+"/" || g_sPath == GetOutfitSystem(FALSE)+"/"+sAppend) g_sLastOutfit = "NONE";
            else g_sLastOutfit=g_sPath;
        
            RmCorelock();
            llSleep(1);
        }
        if(sChangetype == "wear"){ //This looks like dead code TODO: Verify for removal?
            if (g_sPath != "" && g_sPath != ".") llOwnerSay("@attachallover:"+g_sPath+"=force");
        }
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;
integer g_iAccessBitSet=25; // Default modes for outfits
integer g_iJail;
Commit(){
    if(g_iLockCore)
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "outfits_lockcore="+(string)g_iLockCore, "");
    else
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "outfits_lockcore","");

    if(g_iAccessBitSet>0)
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "outfits_accessflags="+(string)g_iAccessBitSet,"");
    else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "outfits_accessflags", "");
    
    
    Process();
}

Process(){
    g_iJail = Bool((g_iAccessBitSet&16));
    if(g_iLockCore){
        llOwnerSay("@detachallthis:"+GetOutfitSystem(TRUE)+"=n");
    }
    else{
        llOwnerSay("@detachallthis:"+GetOutfitSystem(TRUE)+"=y");
    }
}

ForceLockCore(){
    llOwnerSay("@detachallthis:"+GetOutfitSystem(TRUE)+"=y");
    llSleep(1);
    llOwnerSay("@detachallthis:"+GetOutfitSystem(TRUE)+"=n");
    llSleep(0.5);
}

RmCorelock(){
    llOwnerSay("@detachallthis:"+GetOutfitSystem(TRUE)+"=y");
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

integer g_iRLVa = 0;

string RLVA_APPEND=".";

string GetOutfitSystem(integer iCorePath){
    if(g_iRLVa){
        if(iCorePath)return ".outfits/.core";
        else return ".outfits";
    }else{
        if(iCorePath)return "outfits/core";
        else return "outfits";
    }
}

string GetFolderName(integer iCore){
    if(g_iRLVa){
        if(iCore)return ".core";
        else return ".outfits";
    }else{
        if(iCore)return "core";
        else return "outfits";
    }
}


default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
        llListen(999988, "", llGetOwner(), "");
        llOwnerSay("@version=999988");
    }
    listen(integer iChan, string sName, key kID, string sMsg)
    {
        if(llSubStringIndex(sMsg, "RLVa")==-1){
            g_iRLVa=FALSE;
        }else g_iRLVa=TRUE;
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
        if(llGetStartParameter()!=0)llResetScript();
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == -99999){
            if(sStr=="update_active")llResetScript();
        
        }else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
        else if(iNum == DIALOG_RESPONSE){
        
            list lMenuParams = llParseString2List(sStr, ["|"],[]);
            integer iAuth = llList2Integer(lMenuParams,3);
            
            if(AuthDenied(iAuth)) {
                //Test to see if this is a denied auth. If we're here and its denied, we respring. A CMD_* call is already sent out which will produce the NOTIFY
                if(llSubStringIndex(sStr, g_sSubMenu) != -1)
                    llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, llGetSubString(sStr, 0, 35));
            }
            
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                //list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                //integer iAuth = llList2Integer(lMenuParams,3);
                
                integer iRespring=TRUE;
                
                //llSay(0, sMenu);
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU) {
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if(sMsg == TickBox(g_iLockCore, "Lock Core")){
                        g_iLockCore=1-g_iLockCore;
                        llSetTimerEvent(120);
                        Commit();
                    }else if(sMsg == "◌ Configure"){
                        // Open the config menu to set access rights
                        if(iAuth == CMD_OWNER){
                            iRespring=FALSE;
                            ConfigMenu(kAv, iAuth);
                        }else{
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to configuration settings", kAv);
                        }
                        
                    } else if(sMsg == "Browse"){
                        FolderBrowser(kAv,iAuth);
                        iRespring=FALSE;
                    } else if(sMsg == "BrowseCore"){
                        CoreBrowser(kAv, iAuth);
                        iRespring=FALSE;
                    } else if(sMsg == "Help"){
                        llMessageLinked(LINK_SET,NOTIFY, "0 \n \n[Outfits Help]\n* This is the typical structure of a Outfits folder: \n#RLV\n-> "+GetFolderName(FALSE)+"\n---> "+GetFolderName(TRUE)+"\n-> My Outfit\n \nAnything placed in "+GetFolderName(TRUE)+" will never be removed during a outfit change using this script. If you enable 'Lock Core' then your core folder will stay locked for any changes made outside of this script, (for example:  your relay)", kAv);
                    }
                    if(iRespring)Menu(kAv,iAuth);
                } else if(sMenu == "Menu~Configure"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                    }else{
                        // Check mode first
                        list ButtonFlags = llParseString2List(sMsg,[" "],[]);
                        string ButtonLabel = llDumpList2String(llList2List(ButtonFlags,1,-1), " ");
                        integer Enabled = llListFindList(g_lCheckboxes, [llList2String(ButtonFlags,0)]);
                        
                        if(Enabled){
                            // Disable flag
                            if(ButtonLabel == "Trusted")g_iAccessBitSet -=1;
                            else if(ButtonLabel == "Public")g_iAccessBitSet-=2;
                            else if(ButtonLabel == "Group")g_iAccessBitSet-=4;
                            else if(ButtonLabel == "Wearer")g_iAccessBitSet-=8;
                            else if(ButtonLabel == "Jail")g_iAccessBitSet-=16;
                            else if(ButtonLabel == "Strip All")g_iAccessBitSet -= 32;
                        }else{
                            if(ButtonLabel == "Trusted")g_iAccessBitSet+=1;
                            else if(ButtonLabel == "Public")g_iAccessBitSet+=2;
                            else if(ButtonLabel == "Group")g_iAccessBitSet+=4;
                            else if(ButtonLabel == "Wearer") g_iAccessBitSet+=8;
                            else if(ButtonLabel == "Jail")g_iAccessBitSet+=16;
                            else if(ButtonLabel == "Strip All")g_iAccessBitSet+=32;
                        }
                        
                        
                        Commit();
                    }
                    if(iRespring)ConfigMenu(kAv,iAuth);
                } else if(sMenu == "Browser"){
                    // Process commands!
                    
                    ForceLockCore(); // unlocks/relocks - compatible with the Lock Core option. 
                    // The above is a workaround for a viewer bug where any newly added items to .core will not be protected.
                    if(!g_iLocked){
                        llOwnerSay("@detach=n");
                    }
                    
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                        g_iListenTimeout=0;
                        return;
                    } else if(sMsg == ">Wear<"){
                        // add recursive. Adds subfolder contents too
                        UserCommand(iAuth, "wear "+g_sPath, kAv);
                    } else if(sMsg == ">Naked<"){
                        UserCommand(iAuth, "naked", kAv);
                    } else if(sMsg == ">REMOVE<"){
                        llOwnerSay("@detachallthis:"+GetOutfitSystem(TRUE)+"=y");
                        llSleep(1);
                        llOwnerSay("@detachall:"+g_sPath+"=force");
                        ForceLockCore();
                    } else if(sMsg == "^"){
                        // go up a path
                        list edit = llParseString2List(g_sPath,["/"],[]);
                        string sEdit = llDumpList2String(llDeleteSubList(edit,-1,-1), "/");
                        if(llGetSubString(sEdit,-1,-1)=="/")sEdit = llGetSubString(sEdit,0,-2);
                        g_sPath=sEdit;
                        iRespring=FALSE;
                        if(g_iJail && g_sPath == "")g_sPath = GetFolderName(FALSE);
                        llOwnerSay("@getinv:"+g_sPath+"="+(string)g_iListenChannel);
                    } else {
                        g_sPath+="/"+sMsg;
                        iRespring=FALSE;
                        // attempt to enter folder: if empty will only display utility buttons. Which will still give the ability to add a folder
                        llOwnerSay("@getinv:"+g_sPath+"="+(string)g_iListenChannel);
                    }
                    TickBrowser();
                    if(iRespring)llOwnerSay("@getinv:"+g_sPath+"="+(string)g_iListenChannel);
                }
            }
        } else if(iNum == OUTFITS_ADD){
            UserCommand(CMD_OWNER, "wear "+sStr, kID);
        } else if(iNum == OUTFITS_REM){
            UserCommand(CMD_OWNER, "naked", kID);
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "checkboxes"){
                    g_lCheckboxes = llCSV2List(llList2String(lSettings,2));
                }
            } else if(llList2String(lSettings,0) == "outfits"){
                if(llList2String(lSettings,1) == "lockcore"){
                    g_iLockCore=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "accessflags"){
                    //llSay(0, "ACCESS FLAGS: "+llList2String(lSettings,2));
                    g_iAccessBitSet=llList2Integer(lSettings,2);
                }
                Process();
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="global")
                if(llList2String(lSettings,1) == "locked") g_iLocked=FALSE;
        } else if(iNum == REBOOT)llResetScript();
    }
    
    timer(){
        if(TimedOut() && g_iListenTimeout!=-1){
            llSetTimerEvent(0);
            if(g_iListenTimeout!=0)
                llMessageLinked(LINK_SET,NOTIFY, "0Timed out.", g_kListenTo);
            g_kListenTo="";
            llListenRemove(g_iListenHandle);
            if(!g_iLocked)llOwnerSay("@detach=y");
            g_iListenHandle=0;
            g_iListenChannel=0;
            g_iListenTimeout=-1;
            g_iListenToAuth=0;
            if(!g_iLockCore)llOwnerSay("@detachallthis:"+GetOutfitSystem(TRUE)+"=y");
            
            g_sPath = GetFolderName(FALSE);
            if(g_iLockCore)llSetTimerEvent(120);
            return;
        }
        
        if(g_iListenTimeout==-1){
            if(g_iLockCore){
                ForceLockCore();
            }else {
                llSetTimerEvent(0);
            }
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg){
        TickBrowser();
        if(iChannel == g_iListenChannel){
            // Viewer reply!
            // Delimiters : ,
            list Options = llParseString2List(sMsg,[","],[]);
            DoBrowserPath(llListSort(Options,0,TRUE), g_kListenTo, g_iListenToAuth);
            
        }
            
    }
            
}
