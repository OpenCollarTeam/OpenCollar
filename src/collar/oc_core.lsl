/*
This file is a part of OpenCollar.
Copyright ©2021
: Contributors :
Aria (Tashia Redrose)
    *June 2020       -       Created oc_core
      * This combines oc_com, oc_auth, and oc_sys
    * July 2020     -       Maintenance fixes, feature implementations
et al.
Medea (Medea Destiny)
    *June 2020  -  *Fix issue #562, #381, #495 allow owners to permit wearers to set trusted/block.
                -   added Wearer Trust option to Access Menu so that owners may allow or forbid
                    wearer from adding/removing to trusted and block lists
                -   Moved Limit Range to Settings menu to make room in Access menu for above,
                    as it seems logical to have this as a global setting. 
                -   Added explanatory text to settings menu prompt and access prompt,
                -   Added safeword to help/about prompt. 
                -   Fix issue #566, clear @setgroup when group unchecked properly.
                -   Extention to above, Disallow setting group access when no group active.  
                -   Fix issue #580 Limited printing settings to owner and wearer
                -   #579 Added 'Listen 0' button to Settings menu that allows toggling channel 0
                    command listener on and off.
    Sept 2021   -   Added sleep before notify for device name chage, issue #672 
                -   Added confirmation messages when group or public access is toggled and fixed a typo
                -   Efficiency pass, inlined majorminor(), docheckupdate() and docheckdevupdate().

                    Removed g_lTestReports, left over from alpha.
    Nov 2021    -   Auth check for hide didn't account for when wearer tries to use hide with AllowHiding
                     ticked but access is not CMD_WEARER (i.e. wearer set to trusted). (see #774)                         
    Jun 2022    -   Fixes for #774 (extension to above, allowing for wearer set to trusted). Using 
                    kID == g_kWearer instead of iNum==CMD_WEARER in UserCommad() for:
                    Safeword report, verbosity level, locking
                    And kAv == g_kWearer instead of iAuth == CMD_WEARER in meu dialog responses for:
                    + / - trusted / blacklist when wearer is permitted, displaying access list, print settings  
    Oct 2022    -   Fix for full version>beta version checking. Added menu text to clarify versioning for beta users.
    Oct 2023    -   Refactor of safeword function in usercommand. 'Safeword off' now no longer sets safeword to 'off'
                    before disabling, resulting in confusing "Safeword is now set to 'off'" message. Instead safeword
                    off is clearly notified. Wearer can now set their own safeword, but only owners can disable it still.
                    See issue # 986. Attempting to access safeword without permission now gives no access response. 
                -   Provide no access notification for device name, and allow non-owner wearer to name. Notify wearer
                    as well when another person changes device name. See issue # 987 
   Jul 2024     -   Further work on above safeword stuff, see PR #999 
                -   added delay after name change to ensure report is correct and added clarification text here
                    and in device name. Issue #1053
                            
Stormed Darkshade (StormedStormy)
    March 2022  -   Added a button for reboot to help/about menu.  

Yosty7B3
    Nov 2022    -   Removed Setor() and bool() functions for streamlining.
    Aug 2023    -   Combine all menu functions into the Dialog function to save memory.

Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

integer NOTIFY_OWNERS=1003;

//string g_sParentMenu = "";
string g_sSubMenu = "Main";
string COLLAR_VERSION = "8.3.0000"; // Provide enough room
// LEGEND: Major.Minor.Build RC Beta Alpha
integer UPDATE_AVAILABLE=FALSE;
string NEW_VERSION = "";
integer g_iAmNewer=FALSE;
integer g_iIsBeta;
integer g_iChannel=1;
string g_sPrefix;

integer g_iVerbosityLevel=1;

integer g_iNotifyInfo=FALSE;

string g_sSafeword="RED";
integer g_iSafewordDisable=0;
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_NOACCESS=599;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

integer AUTH_REQUEST = 600;
integer AUTH_REPLY=601;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

string g_sLockSound="dec9fb53-0fef-29ae-a21d-b3047525d312";
string g_sUnlockSound="82fa6d06-b494-f97c-2908-84009380c8d1";

integer g_iListenPublic=TRUE;

key g_kWeldBy;
list g_lMainMenu=["Apps", "Access", "Settings", "Help/About"];

Dialog(key kID, string sPrompt, list lButtons, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    if(sName == "Menu~Settings"){
        sPrompt = "OpenCollar\n\n[Settings]\n\n'Print' lists settings in chat, 'Load' reloads setting from notecard. Use 'Fix Menus' if menus are missing. 'EDITOR' allows manual editing of settings. 'Limit Range' to ignore clicks from distant users. 'Listen 0' controls whether the collar will hear commands in local chat.";
        lButtons = [Checkbox(g_iListenPublic,"Listen 0"),Checkbox(g_iLimitRange, "Limit Range"),"Print", "Load", "Fix Menus"];
        if (llGetInventoryType("oc_resizer") == INVENTORY_SCRIPT) lButtons += ["Resize"];
        else lButtons += ["-"];
        lButtons += [Checkbox(g_iHide, "Hide"), "EDITOR", Checkbox(g_iAllowHide, "AllowHiding"), "Addon.."];
        
        lUtilityButtons = [UPMENU];
        
    }else if(sName == "Menu~SAddons"){
        sPrompt = "OpenCollar\n\n[Addon Settings\n\nWearerAddons - Allow/Disallow use of wearer owned addons\nAddonLimited - Limit whether wearer owned addons can modify the owners list or weld state (default enabled)";
        lButtons = [Checkbox(g_iWearerAddons, "WearerAddons"), Checkbox(g_iWearerAddonLimited, "AddonLimited"), Checkbox(g_iAddons, "Addons")];

        lUtilityButtons = [UPMENU];
        
    }else if(sName == "Menu~Apps"){
        sPrompt = "\n[Apps]\nYou have "+(string)llGetListLength(g_lApps)+" apps installed";
        lButtons = g_lApps;
        
        lUtilityButtons = [UPMENU];
        
    }else if(sName == "Menu~Main"){
        sPrompt = "\nOpenCollar "+COLLAR_VERSION;
        lButtons = [Checkbox(g_iLocked, "Lock")];

        if(!g_iWelded)lButtons+=g_lMainMenu;
        else lButtons=g_lMainMenu;
        
        if(UPDATE_AVAILABLE ) sPrompt += "\n\nUPDATE AVAILABLE: Your version is: "+COLLAR_VERSION+", The current release version is: "+NEW_VERSION;
        if(g_iAmNewer)sPrompt+="\n\nYour collar version is newer than the public release. This may happen if you are using a beta or pre-release copy.\nNote: Pre-Releases may have bugs. Ensure you report any bugs to [https://github.com/OpenCollarTeam/OpenCollar Github]";
        if(g_iIsBeta)sPrompt+="\n(The last 3 digits indicate a pre-release version, which is superseded by 000 for a release version).";
    
        if(g_iWelded) sPrompt+="\n\n* The Collar is Welded by secondlife:///app/agent/"+(string)g_kWeldBy+"/about *";
        if(iAuth==CMD_OWNER && g_iLocked && !g_iWelded)lButtons+=["Weld"];
        
    }else if(sName == "Menu~Auth"){
        if(g_iCaptured){
            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to the access settings while capture is active!", kID);
            llMessageLinked(LINK_SET, 0, "menu", kID);
            return;
        }
        sPrompt = "\nOpenCollar Access Controls\n+/- buttons to control access lists.\nGroup allows access to current group, Public allows access to all. Wearer trust allows an owned wearer to add/remove from trusted list.\nRunaway removes all owners, access list prints out who has access.";
        lButtons = ["+ Owner", "+ Trust", "+ Block", "- Owner", "- Trust", "- Block", Checkbox(g_kGroup!="", "Group"), Checkbox(g_iPublic, "Public")];
    
        lButtons += [Checkbox(g_iAllowWearerSetTrusted, "Wearer Trust"), "Runaway", "Access List"];
        
        lUtilityButtons = [UPMENU];
        
    }else if(sName == "Menu~Help"){
        string EXTRA_VER_TXT;
        if(llGetSubString(COLLAR_VERSION,-1,-1)!="0") EXTRA_VER_TXT = " (ALPHA "+llGetSubString(COLLAR_VERSION,-1,-1)+") ";
        if(llGetSubString(COLLAR_VERSION,-2,-2)!="0") EXTRA_VER_TXT += " (BETA "+llGetSubString(COLLAR_VERSION,-2,-2)+") ";
        if(llGetSubString(COLLAR_VERSION,-3,-3)!="0") EXTRA_VER_TXT += " (RC " + llGetSubString(COLLAR_VERSION,-3,-3)+") ";
    
        sPrompt = "\nOpenCollar "+COLLAR_VERSION+" "+EXTRA_VER_TXT+"\nVersion: "+llList2String(["","(Newer than release)"],g_iAmNewer)+" "+llList2String(["(Most Current Version)","(Update Available)"],UPDATE_AVAILABLE);
        sPrompt += "\n\nDocumentation https://opencollar.cc";
        sPrompt += "\nPrefix: "+g_sPrefix+"\nChannel: "+(string)g_iChannel;
        sPrompt += "\nSafeword: "+g_sSafeword;
        if(g_iNotifyInfo){
            g_iNotifyInfo=FALSE;
            llMessageLinked(LINK_SET, NOTIFY, sPrompt, kID);
            return;
        }
        lButtons = ["Update", "Support", "License", "Reboot"];
        
        lUtilityButtons = [UPMENU];
    }
    
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|"+(string)iPage+"|" + llDumpList2String(lButtons, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, sName+"~"+llGetScriptName());
}
integer g_iHide=FALSE;
integer g_iAllowHide=TRUE;

integer g_iWelded=FALSE;
integer g_iWearerAddons=TRUE;
// The original idea in #356, was to make this as a app, but i fail to see why we must use an extra app just to create the weld, the extra app or possibly an addon could be made to unweld should the wearer desire it.
integer g_iAddons=TRUE;
list g_lApps;
key g_kGroup = "";
integer g_iLimitRange=TRUE;
integer g_iPublic=FALSE;
integer g_iCaptured = FALSE;
integer g_iAllowWearerSetTrusted=FALSE;

list g_lCheckboxes=["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, (iValue>0))+" "+sLabel;
}
integer g_iUpdatePin = 0;
//string g_sDeviceName;
//string g_sWearerName;


UserCommand(integer iNum, string sStr, key kID) {
    // Aria  -   Remove line that prevented anyone but owner, wearer or trusted from executing commands here. That made it so that even if public or group was enabled it would block functionality. Additionally - the link message block already checks auth level
    if (iNum == CMD_OWNER && sStr == "runaway") {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_owner","origin");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_trust","origin");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_block","origin");
        return;
    }
    if (sStr==g_sSubMenu || sStr == "menu "+g_sSubMenu || sStr == "menu") Dialog(kID,"",[],[],0,iNum,"Menu~Main");
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0;
        list lParameters = llParseString2List(sStr, [" "], []);
        string sChangetype = llList2String(lParameters,0);
        string sChangevalue = llList2String(lParameters,1);
        //string sText;

        if(sChangetype=="fix"){
            g_lMainMenu=["Apps", "Access", "Settings", "Help/About"];
            llMessageLinked(LINK_SET,NOTIFY, "0Fixed menus", kID);
            llMessageLinked(LINK_SET,0,"initialize","");
        } else if(sChangetype == "update"){
            if(iNum == CMD_OWNER || kID == g_kWearer){
                g_iUpdatePin = llRound(llFrand(0x7FFFFFFF))+1; // Maximum integer size
                llSetRemoteScriptAccessPin(g_iUpdatePin);

                //llAllowInventoryDrop(TRUE);
                // Now that a pin is set, scan for a updater and chainload
                g_iDiscoveredUpdaters=0;
                g_kUpdater=NULL_KEY;
                g_kUpdateUser=kID;
                llMessageLinked(LINK_SET, NOTIFY, "0Searching for a updater", kID);
                g_iUpdateAuth = iNum;
                llListenRemove(g_iUpdateListener);
                g_iUpdateListener = llListen(g_iUpdateChan, "", "", "");
                list lTmp = llParseString2List(COLLAR_VERSION,["."],[]);
                llWhisper(g_iUpdateChan, "UPDATE|"+llList2String(lTmp,0)+"."+llList2String(lTmp,1));
                g_iWaitUpdate = TRUE;
                llSetTimerEvent(5);
            } else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to update the collar", kID);
        } else if(sChangetype == "safeword") {
            if(iNum!=CMD_OWNER && kID!=g_kWearer) {
                llMessageLinked(LINK_SET,NOTIFY,"0No access to safeword!",kID);
                return;
            } if(llToLower(sChangevalue) == "off") {
                if(iNum==CMD_OWNER) {
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_safeworddisable=1", "");
                    llMessageLinked(LINK_SET,NOTIFY,"1Safeword Disabled.",kID);
                } else llMessageLinked(LINK_SET,NOTIFY,"0Only an owner can disable Safeword!",kID);
                return;
            } else if(sChangevalue!="") {
                if(g_iSafewordDisable==TRUE && iNum!=CMD_OWNER) {
                    llMessageLinked(LINK_SET,NOTIFY,"0Only Owners can set a safeword when disabled!",kID);
                    return;
                }
                if(sChangevalue == "RED") llMessageLinked(LINK_SET, LM_SETTING_DELETE, "global_safeword","");
                else llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_safeword="+sChangevalue,"");
                llMessageLinked(LINK_SET,NOTIFY,"1Safeword is now set to '"+sChangevalue+"'.",kID);
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "global_safeworddisable","");
                llMessageLinked(LINK_SET, CMD_OWNER, "safeword-enable","");
            } else {
                if(g_iSafewordDisable) llMessageLinked(LINK_SET, NOTIFY, "0The safeword is currently disabled.",kID);
                else llMessageLinked(LINK_SET, NOTIFY, "0The safeword is currently set to: '"+g_sSafeword+"'",kID);
            }
        } else if(sChangetype == "menu"){
            if(llToLower(sChangevalue) == "access"){
                Dialog(kID,"",[],[],0,iNum,"Menu~Auth");
            } else if(llToLower(sChangevalue) == "settings"){
                Dialog(kID,"",[],[],0,iNum,"Menu~Settings");
            } else if(llToLower(sChangevalue) == "apps"){
                Dialog(kID,"",[],[],0,iNum, "Menu~Apps");
            } else if(llToLower(sChangevalue) == "help/about"){
                Dialog(kID,"",[],[],0,iNum,"Menu~Help");
            }
        } else if(llToLower(sChangetype) == "weld"){
            if(iNum==CMD_OWNER){
                g_kWelder=kID;
                llMessageLinked(LINK_SET, NOTIFY, "1secondlife:///app/agent/"+(string)kID+"/about is attempting to weld the collar. Consent is required", kID);
                Dialog(g_kWearer, "[WELD CONSENT REQUIRED]\n\nsecondlife:///app/agent/"+(string)kID+"/about wants to weld your collar. If you agree, you may not be able to unweld it without the use of a plugin or a addon designed to break the weld. If you disagree with this action, press no.", ["Yes", "No"], [], 0, iNum, "weld~consent");
            } else llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to welding", kID);
        } else if(llToLower(sChangetype)=="verbosity"){
            if(iNum == CMD_WEARER || kID == g_kWearer)
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_verbosity="+sChangevalue, "");
            else
                llMessageLinked(LINK_SET, NOTIFY, "%NOACCESS% to changing verbosity levels", kID);
        } else if(llToLower(sChangetype) == "info"){
            if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE){
                g_iNotifyInfo = TRUE;
                Dialog(kID,"",[],[],0,iNum,"Menu~Help");
            } else llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS%",kID);
        } else if(llToLower(sChangetype) == "touchnotify"){
            if(g_iTouchNotify) llMessageLinked(LINK_SET,NOTIFY,"1The wearer will no longer be notified when someone touches their collar", kID);
            else llMessageLinked(LINK_SET, NOTIFY, "1The wearer will now be notified whenever someone touches their collar", kID);

            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_touchnotify="+(string)(!g_iTouchNotify), "");
        } else if(llToLower(sChangetype) == "name" && iNum==CMD_OWNER){
            // set wearer name
            sChangevalue = llDumpList2String(llList2List(lParameters,1,-1), " ");
            if(llGetListLength(lParameters)==1){
                // print current device name
                llMessageLinked(LINK_SET, NOTIFY, "0The wearer name is: %WEARERNAME%",kID);
                return;
            }
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_wearername="+sChangevalue, "");
            llSleep(0.5);
            llMessageLinked(LINK_SET, NOTIFY, "1The wearer's name is now set to %WEARERNAME% (if this is the old name, please type '/1 (prefix) name' to confirm the change went through, we may just have lagged)", kID);
        } else if(llToLower(sChangetype) == "device"){
            if(iNum!=CMD_OWNER && kID!=g_kWearer){
                llMessageLinked(LINK_THIS,NOTIFY,"No access to device name.",kID);
                return;
            }
            if(llToLower(sChangevalue) == "name"){
                sChangevalue = llDumpList2String(llList2List(lParameters,2,-1), " ");
                if(llGetListLength(lParameters) == 2){
                    // print current device name
                    llMessageLinked(LINK_SET, NOTIFY, "0The current device name is: %DEVICENAME%",kID);
                    return;
                }
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_devicename="+sChangevalue,"");
                llSleep(0.5); //To ensure the notify happens AFTER the new device name is in place.
                llMessageLinked(LINK_SET, NOTIFY, "1The device name is now set to: %DEVICENAME% (if this is the old name, please type '/1 (prefix) device name' to confirm the change went through, we may just have lagged)", kID);
            }
        } else if(llToLower(sChangetype) == "allowhide"){
            if(iNum == CMD_OWNER){
                if(g_iAllowHide)llMessageLinked(LINK_SET, NOTIFY, "0The wearer can no longer hide the collar", kID);
                else llMessageLinked(LINK_SET,NOTIFY, "0The wearer can hide the collar on their own", kID);
                g_iAllowHide=1-g_iAllowHide;
                if(sChangevalue=="remenu")Dialog(kID,"",[],[],0,iNum,"Menu~Settings");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_allowhide="+(string)g_iAllowHide, "");
            } else {
                llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to toggling Allow Hide", kID);
                if(sChangevalue == "remenu")Dialog(kID,"",[],[],0,iNum,"Menu~Settings");
            }
        } else if(llToLower(sChangetype)=="lock" && !g_iWelded && (iNum == CMD_OWNER || kID == g_kWearer)){
            // allow locking
            g_iLocked=TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_locked="+(string)g_iLocked,"");
            llMessageLinked(LINK_SET, NOTIFY, "1%WEARERNAME%'s collar has been locked", kID);
            llPlaySound(g_sLockSound,1);
        } else if(llToLower(sChangetype) == "unlock" && iNum == CMD_OWNER && !g_iWelded){
            g_iLocked=FALSE;
            llPlaySound(g_sUnlockSound,1);
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "global_locked","");
            llMessageLinked(LINK_SET, NOTIFY, "1%WEARERNAME%'s collar has been unlocked", kID);
        } else {
            if(sChangevalue!="")return;
            if(llToLower(sChangetype) == "access")Dialog(kID,"",[],[],0,iNum,"Menu~Auth");
            else if(llToLower(sChangetype) == "settings")Dialog(kID,"",[],[],0,iNum,"Menu~Settings");
            else if(llToLower(sChangetype) == "apps")Dialog(kID,"",[],[],0,iNum, "Menu~Apps");
            else if(llToLower(sChangetype) == "help/about") Dialog(kID,"",[],[],0,iNum,"Menu~Help");
        }
    }
}
integer g_iWearerAddonLimited=TRUE;
integer g_iUpdateListener;
key g_kUpdater;
integer g_iDiscoveredUpdaters;
key g_kUpdateUser;
integer g_iUpdateAuth;
integer g_iWaitUpdate;
integer g_iUpdateChan = -7483213;
key g_kWearer;
integer g_iLocked=FALSE;
Compare(string V1, string V2){
    V2=llStringTrim(V2,STRING_TRIM);
    NEW_VERSION=V2;
    if(llGetSubString(V1,-3,-1)!="000") g_iIsBeta=TRUE;
    if(V1==V2){
        UPDATE_AVAILABLE=FALSE;
        return;
    }
    V1 = llDumpList2String(llParseString2List(V1, ["."],[]),"");
    V2 = llDumpList2String(llParseString2List(V2, ["."],[]), "");
    integer iV1 = (integer)V1;
    integer iV2 = (integer)V2;

    if(iV1 < iV2){
        UPDATE_AVAILABLE=TRUE;
        g_iAmNewer=FALSE;
    } else if(iV1 == iV2) return;
    else if(iV1 > iV2){
        if(llGetSubString(V2,-3,-1)=="000" && llGetSubString(V1,0,-4)==llGetSubString(V2,0,-4)){
            UPDATE_AVAILABLE=TRUE;
            g_iAmNewer=FALSE;
            return;
        }
        UPDATE_AVAILABLE=FALSE;
        g_iAmNewer=TRUE;

       // llSetText("", <1,0,0>,1); //Not sure what this is for, but seems unnecessary? Commented out unless someone finds a reason for it.
    }
}

key g_kUpdateCheck = NULL_KEY;
key g_kCheckDev;

integer g_iDoTriggerUpdate=FALSE;
key g_kWelder = NULL_KEY;
StartUpdate(){
    llRegionSayTo(g_kUpdater, g_iUpdateChan, "ready|"+(string)g_iUpdatePin);
}

integer g_iInterfaceChannel;
integer g_iTouchNotify=FALSE;
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
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
            llOwnerSay("@detach=n");
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
        g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));

        llMessageLinked(LINK_SET, 0, "initialize", llGetKey());

    }
    attach(key kID){
        if(kID==NULL_KEY){
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=No");
        }
    }

    touch_start(integer iNum){
        if(g_iTouchNotify) llMessageLinked(LINK_SET, NOTIFY, "0secondlife:///app/agent/"+(string)llDetectedKey(0)+"/about has touched your collar!", g_kWearer);

        llMessageLinked(LINK_SET, 0, "menu", llDetectedKey(0)); // Temporary until API v8's implementation is done, use v7 in the meantime
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){

        if(g_iVerbosityLevel>=2){
            llOwnerSay("Link Message\n["+llDumpList2String(["iSender = "+(string)iSender, "iNum = "+(string)iNum, "sStr = "+sStr, "kID = "+(string)kID], ", ")+"]");
        }

        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_RESPONSE){
            list lPara = llParseString2List(sStr, ["|"],[]);
            string sName = llList2String(lPara,0);
            string sMenu = llList2String(lPara,1);
            if(sName == "Main"){
                if(llListFindList(g_lMainMenu, [sMenu])==-1){
                    g_lMainMenu = [sMenu] + g_lMainMenu;
                }
            } else if(sName == "Apps"){
                if(llListFindList(g_lApps,[sMenu])==-1)g_lApps= [sMenu]+g_lApps;
            }
        } else if(iNum == MENUNAME_REMOVE){
            // This is not really used much if at all in 7.x

            list lPara = llParseString2List(sStr, ["|"],[]);
            string sName = llList2String(lPara,0);
            string sMenu = llList2String(lPara,1);
            if(sName=="Main"){
                integer loc = llListFindList(g_lMainMenu, [sMenu]);
                if(loc!=-1){
                    g_lMainMenu = llDeleteSubList(g_lMainMenu, loc,loc);
                }
            } else if(sName == "Apps"){
                integer loc = llListFindList(g_lApps,[sMenu]);
                if(loc!=-1)g_lApps = llDeleteSubList(g_lApps, loc,loc);
            }

        }
        else if(iNum == DIALOG_RESPONSE){
            integer iPos = llSubStringIndex(kID, "~"+llGetScriptName());
            if(iPos>0){
                string sMenu = llGetSubString(kID, 0, iPos-1);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRespring=TRUE;
                if(sMenu == "Menu~Main"){
                    if(sMsg == Checkbox(g_iLocked,"Lock")){
                        if((iAuth==CMD_OWNER || iAuth == CMD_TRUSTED) && g_iLocked){
                            UserCommand(iAuth, "unlock", kAv);
                        } else if((iAuth == CMD_OWNER || iAuth == CMD_TRUSTED || iAuth == CMD_WEARER )  && !g_iLocked){
                            UserCommand(iAuth, "lock", kAv);
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to the lock", kAv);
                        }
                    } else if(sMsg == "Weld"){
                        UserCommand(iAuth, "weld", kAv);
                        iRespring=FALSE;
                    } else {
                        iRespring=FALSE;
                        // don't recaculate while developing
                        llMessageLinked(LINK_SET, iAuth,"menu "+ sMsg, kAv); // Recalculate
                    }
                } else if(sMenu == "weld~consent"){
                    if(sMsg == "No"){
                        llMessageLinked(LINK_SET, NOTIFY, "1%NOACCESS% to welding the collar.", g_kWelder);
                    } else {
                        // do weld
                        llMessageLinked(LINK_SET, NOTIFY, "1Please wait...", g_kWelder);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "intern_weld=1", g_kWelder);
                        g_iWelded=TRUE;
                    }
                    iRespring=FALSE;
                } else if(sMenu=="Menu~Auth"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Dialog(kAv,"",[],[],0,iAuth,"Menu~Main");
                    } else if(llGetSubString(sMsg,0,0) == "+"){
                        if(iAuth == CMD_OWNER || (kAv == g_kWearer && (sMsg=="+ Trust"||sMsg=="+ Block") && g_iAllowWearerSetTrusted==TRUE) ){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "add "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        }
                        else
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to adding a person", kAv);
                    } else if(llGetSubString(sMsg,0,0)=="-"){
                        if(iAuth == CMD_OWNER || (kAv == g_kWearer && (sMsg=="- Trust"||sMsg=="-Block") && g_iAllowWearerSetTrusted==TRUE) ){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "rem "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        } else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to removing a person", kAv);
                    } else if(sMsg == "Access List"){
                        if(iAuth == CMD_OWNER || kAv == g_kWearer ){
                        llMessageLinked(LINK_SET, iAuth, "print auth", kAv);}
                    } else if(sMsg == Checkbox((g_kGroup!=""), "Group")){
                        if(iAuth ==CMD_OWNER){
                            if(g_kGroup!=""){
                                g_kGroup="";
                                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_group", "origin");
                                llMessageLinked(LINK_SET,NOTIFY,"1Group Access has been turned off.",kAv); 
                            }else{
                                key t_kGroup = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]),0);
                                if(t_kGroup==NULL_KEY){
                                     llMessageLinked(LINK_SET, NOTIFY,"0Group access can't be set while no group is active.",kAv);
                                }
                                else{
                                    g_kGroup=t_kGroup;
                                     llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_group="+(string)g_kGroup, "origin");
                                     llMessageLinked(LINK_SET,NOTIFY,"1Group Access has been turned on.",kAv);   
                                }
                            }
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to changing group access", kAv);
                        }
                    } else if(sMsg == Checkbox(g_iPublic, "Public")){
                        if(iAuth ==CMD_OWNER){
                            g_iPublic=1-g_iPublic;
                            if(g_iPublic) {
                                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_public=1", "origin");
                                llMessageLinked(LINK_SET,NOTIFY,"1Public Access has been turned on.",kAv); 
                            } else {
                                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_public","origin");
                                llMessageLinked(LINK_SET,NOTIFY,"1Public Access has been turned off.",kAv); 
                            } 
                        } else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to changing public", kAv);
                    } else if(sMsg == "Runaway"){
                        llMessageLinked(LINK_SET,0,"menu runaway", kAv);
                        iRespring=FALSE;
                    }
                    else if(sMsg == Checkbox(g_iAllowWearerSetTrusted, "Wearer Trust")){
                        if(iAuth==CMD_OWNER){
                            g_iAllowWearerSetTrusted=!g_iAllowWearerSetTrusted;
                            if(g_iAllowWearerSetTrusted) llMessageLinked(LINK_SET, LM_SETTING_SAVE,"auth_wearertrust=1", "origin");
                            else llMessageLinked(LINK_SET, LM_SETTING_DELETE,"auth_wearertrust","origin");
                        }
                        else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to allowing wearer control of trusted/blocklist",kAv);
                    }
                } else if(sMenu == "Menu~Settings"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Dialog(kAv,"",[],[],0,iAuth,"Menu~Main");
                    }  else if(sMsg == Checkbox(g_iLimitRange, "Limit Range")){
                        if(iAuth >=CMD_OWNER && iAuth <= CMD_TRUSTED){
                            g_iLimitRange=1-g_iLimitRange;

                            if(!g_iLimitRange)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_limitrange=0","origin");
                            else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_limitrange", "origin");
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to changing range limit", kAv);
                        }
                    }else if (sMsg==Checkbox(g_iListenPublic,"Listen 0")){
                        if(iAuth ==CMD_OWNER){
                            g_iListenPublic=!g_iListenPublic;
                            llMessageLinked(LINK_SET,LM_SETTING_SAVE,"global_listen0="+(string)g_iListenPublic,"origin");
                            }else{
                                llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to changing policy on listening to local chat for collar commands.",kAv);}
                    } else if(sMsg == "Print"){
                         if(iAuth==CMD_OWNER || kAv == g_kWearer) llMessageLinked(LINK_SET, iAuth, "print settings", kAv);
                         else llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to reading settings.",kAv);
                    } else if(sMsg == "Fix Menus"){
                        llMessageLinked(LINK_SET, iAuth, "fix", kAv);
                        llMessageLinked(LINK_SET, NOTIFY, "0Menus have been fixed", kAv);
                    } else if(sMsg == Checkbox(g_iHide,"Hide")){
                        if((kAv == g_kWearer && g_iAllowHide==TRUE)||iAuth==CMD_OWNER){
                            g_iHide=1-g_iHide;
                            llMessageLinked(LINK_SET, iAuth, llList2String(["show","hide"],g_iHide), kAv);
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_hide="+(string)g_iHide, "");
                        }
                        else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to hiding the collar", kAv);
                            return;
                        }
                    } else if(sMsg == "Load"){
                        llMessageLinked(LINK_SET, iAuth, sMsg, kAv);
                    } else if(sMsg == "Resize"){
                        // Resizer!!
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu Size/Position", kAv);
                    } else if(sMsg == Checkbox(g_iAllowHide,"AllowHiding")){
                        llMessageLinked(LINK_SET, 0, "allowhide remenu", kAv);
                        iRespring=FALSE;
                    } else if(sMsg == "EDITOR"){
                        llMessageLinked(LINK_SET, 0, "settings edit", kAv);
                        iRespring=FALSE;
                    } else if(sMsg == "Addon.."){
                        iRespring=FALSE;
                        Dialog(kAv,"",[],[],0,iAuth,"Menu~SAddons");
                    }
                }else if(sMenu == "Menu~SAddons"){
                    if(sMsg == Checkbox(g_iWearerAddons, "WearerAddons")){
                        if(iAuth == CMD_OWNER || iAuth == CMD_TRUSTED){
                            g_iWearerAddons=1-g_iWearerAddons;
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_weareraddon="+(string)g_iWearerAddons,"");

                            if(!g_iWearerAddons){
                                llMessageLinked(LINK_SET, 500, "kick_all_wearer_addons", kAv);
                            }
                        }else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to toggling wearer addons", kAv);
                    } else if(sMsg == Checkbox(g_iWearerAddonLimited, "AddonLimited")){
                        if(iAuth == CMD_OWNER || iAuth == CMD_TRUSTED){
                            g_iWearerAddonLimited=1-g_iWearerAddonLimited;
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_addonlimit="+(string)g_iWearerAddonLimited,"");
                        }else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to toggling wearer addon limitations", kAv);
                    } else if(sMsg == Checkbox(g_iAddons, "Addons")){
                        if(iAuth == CMD_OWNER){
                            g_iAddons=1-g_iAddons;
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_addons="+(string)g_iAddons, "");
                        }else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to toggling all addons", kAv);
                    }else if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Dialog(kAv,"",[],[],0,iAuth,"Menu~Settings");
                    }
                } else if(sMenu == "Menu~Help"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Dialog(kAv,"",[],[],0,iAuth,"Menu~Main");
                    } else if(sMsg == "Reboot") {
                        llMessageLinked(LINK_SET, iAuth, "Reboot", kAv);
                    } else if(sMsg == "License"){
                        llGiveInventory(kAv, ".license");
                    } else if(sMsg == "Support"){
                        llMessageLinked(LINK_SET, NOTIFY, "0You can get support for OpenCollar in the following group: secondlife:///app/group/45d71cc1-17fc-8ee4-8799-7164ee264811/about or for scripting related questions or beta versions: secondlife:///app/group/c5e0525c-29a9-3b66-e302-34fe1bc1bd43/about", kAv);
                    } else if(sMsg == "Update"){
                        UserCommand(iAuth, "update", kAv);
                    }
                } else if(sMenu == "Menu~Apps"){
                    if(sMsg == UPMENU){
                        Dialog(kAv,"",[],[],0,iAuth,"Menu~Main");
                    }else{
                        llMessageLinked(LINK_SET, 0, "menu "+sMsg, kAv);
                    }
                    iRespring=FALSE;
                } else if(sMenu == "Update~Confirm")
                {
                    if(sMsg == "Yes"){

                        StartUpdate();

                    }
                    else{
                        g_iDoTriggerUpdate=FALSE;
                        g_kUpdater=NULL_KEY;
                    }
                    iRespring=FALSE;
                }
                if(iRespring)Dialog(kAv,"",[],[],0,iAuth,sMenu);
            }
        } else if(iNum == LM_SETTING_RESPONSE){
            list lPar = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            string sVal = llList2String(lPar,2);


            //integer ind = llListFindList(g_lSettingsReqs, [sToken+"_"+sVar]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);


            if(sToken=="global"){
                if(sVar=="locked"){
                    g_iLocked=(integer)sVal;

                    if(g_iLocked){
                        llOwnerSay("@detach=n");
                    }else{
                        llOwnerSay("@detach=y");
                    }
                } else if(sVar == "safeword"){
                    g_sSafeword = sVal;
                    
                } else if(sVar == "safeworddisable"){
                    g_iSafewordDisable=1;
                } else if(sVar == "prefix"){
                    g_sPrefix = sVal;
                } else if(sVar == "channel"){
                    g_iChannel = (integer)sVal;
                } else if(sVar == "touchnotify"){
                    g_iTouchNotify=(integer)sVal;
                } else if(sVar == "allowhide"){
                    g_iAllowHide = (integer)sVal;
                } else if(sVar == "checkboxes"){
                    g_lCheckboxes = llCSV2List(sVal);
                } else if(sVar == "hide"){
                    g_iHide=(integer)sVal;
                } else if(sVar == "weareraddon"){
                    g_iWearerAddons=(integer)sVal;
                } else if(sVar == "addonlimit"){
                    g_iWearerAddonLimited=(integer)sVal;
                } else if(sVar == "addons"){
                    g_iAddons = (integer)sVal;
                } else if(sVar=="verbosity"){
                    g_iVerbosityLevel=(integer)sVal;
                } else if (sVar=="listen0"){
                    g_iListenPublic=(integer)sVal;
                }
            } else if(sToken == "auth"){
                if(sVar == "group"){
                    if(sVal==(string)NULL_KEY)sVal="";
                    g_kGroup=(key)sVal;
                } else if(sVar == "public"){
                    g_iPublic = (integer)sVal;
                } else if(sVar == "limitrange"){
                    g_iLimitRange=(integer)sVal;
                } else if(sVar == "wearertrust"){
                    g_iAllowWearerSetTrusted=(integer)sVal;
                }
            } else if(sToken == "intern"){
                if(sVar == "weld"){
                    g_iWelded=(integer)sVal;

                    if(!g_iLocked)llMessageLinked(LINK_SET,LM_SETTING_SAVE, "global_locked=1","");
                } else if(sVar == "weldby"){
                    g_kWeldBy = (key)sVal;
                }
            } else if(sToken == "capture"){
                if(sVar == "status"){
                    integer iFlag = (integer)sVal;
                    if(iFlag&4){
                        g_iCaptured=TRUE;
                    }else{
                        g_iCaptured=FALSE;
                    }
                }
            }

            if(sStr == "settings=sent"){
                if(g_kGroup==(string)NULL_KEY)g_kGroup="";
            }
        } else if(iNum == LM_SETTING_DELETE){
            list lPar = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);

            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);

            if(sToken=="global"){
                if(sVar == "locked") {
                    g_iLocked=FALSE;
                    llOwnerSay("@detach=y");
                }
                else if(sVar == "safeworddisable"){
                    g_iSafewordDisable=0;
                } else if(sVar == "safeword"){
                    g_sSafeword = "RED";
                    llMessageLinked(LINK_SET, CMD_OWNER, "safeword-enable","");
                } else if(sVar == "prefix"){
                    // revert to default calculation
                    g_sPrefix = llGetSubString(llKey2Name(g_kWearer),0,1);
                } else if(sVar == "channel"){
                    g_iChannel = 1;
                } else if(sVar == "weareraddon"){
                    g_iWearerAddons=TRUE;
                } else if(sVar=="addonlimit"){
                    g_iWearerAddonLimited=TRUE;
                }
            } else if(sToken == "auth"){
                if(sVar == "group"){
                    g_kGroup="";
                }
                else if(sVar == "public")g_iPublic=FALSE;
                else if(sVar == "limitrange")g_iLimitRange=TRUE;
                else if(sVar == "wearertrust") g_iAllowWearerSetTrusted=FALSE;
            } else if(sToken == "intern"){
                if(sVar == "weld"){
                    g_iWelded=FALSE;
                    // Unwelded, reboot collar now
                    llMessageLinked(LINK_SET, REBOOT,"reboot","");
                }
            }
        } else if(iNum == TIMEOUT_FIRED){
            if(sStr == "check_weld") { //Wearer accepted weld. Now recheck auth for menu pop
                llMessageLinked(LINK_SET, AUTH_REQUEST , "welder_auth_check", g_kWeldBy);
            }
        } else if(iNum == AUTH_REPLY){
            if(kID == "welder_auth_check"){ //pop menu for welder
                list lParameters = llParseString2List(sStr, ["|"],[]);
                Dialog(g_kWeldBy,"",[],[],0,llList2Integer(lParameters,2),"Menu~Main");
                llMessageLinked(LINK_SET, NOTIFY_OWNERS, "%WEARERNAME%'s collar has been welded", g_kWelder);
                llMessageLinked(LINK_SET, NOTIFY, "1Weld completed", g_kWearer); //We shouldn't have to send this to the welder. Welder should always be an owner.
            }

        } else if(iNum == REBOOT){
            if(sStr=="reboot"){
                llResetScript();
            }

        } else if(iNum == 0){
            // Auth request!
            if(sStr=="initialize"){
                llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
                llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Apps", "");

                g_kUpdateCheck = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/version.txt",[],"");

                if(llGetAttached()){

                    g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
                    if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
                    if(g_iInterfaceChannel!=0)
                        llRegionSayTo(llGetOwner(), g_iInterfaceChannel, "OpenCollar=Yes");
                }
                llListenRemove(g_iUpdateListener);
            }
        } else if(iNum == RLV_REFRESH){
            if(g_iLocked){
                llOwnerSay("@detach=n");
            } else {
                llOwnerSay("@detach=y");
            }
        }else if(iNum == -99999){
            if(sStr == "update_active")llResetScript();
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
    http_response(key kRequest, integer iStatus, list lMeta, string sBody){
        if(kRequest == g_kUpdateCheck){
            if(iStatus==200){
                Compare(COLLAR_VERSION, sBody);
                if(g_iAmNewer)g_kCheckDev = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/dev_version.txt",[],"");
            }
            else
                llOwnerSay("Could not check for an update. The server returned a unknown status code");
        } else if(kRequest == g_kCheckDev){
            if(iStatus==200){
                Compare(COLLAR_VERSION, sBody);
                g_iAmNewer=TRUE;
            } else llOwnerSay("Could not check the latest development version. The file might not exist or github is not working");
        }
    }

    timer(){
        if(g_iWaitUpdate){
            g_iWaitUpdate=FALSE;
            llListenRemove(g_iUpdateListener);
            if(!g_iDiscoveredUpdaters){
                llMessageLinked(LINK_SET,NOTIFY, "0No updater found. Please ensure you are attempting to use a updater obtained from secondlife:///app/group/45d71cc1-17fc-8ee4-8799-7164ee264811/about", g_kWearer);
                llSetRemoteScriptAccessPin(0);
            }else if(g_iDiscoveredUpdaters > 1){
                llMessageLinked(LINK_SET, NOTIFY, "0Error. Too many updaters found nearby. Please ensure only 1 is rezzed out", g_kWearer);
                llSetRemoteScriptAccessPin(0);
            } else {
                // Trigger update
                StartUpdate();
            }


        }else {
            llSetTimerEvent(0);
        }
    }

    listen(integer iChan, string sName, key kID, string sMsg){
        if(iChan == g_iUpdateChan){
            // dont check object owner. But do check if it is using v8 protocol for updates
            list lTemp = llParseStringKeepNulls(sMsg, ["|"],[]);
            string Cmd = llList2String(lTemp,0);
            string sOpt = llList2String(lTemp,1);
            string sImpl = "";

            if(llGetListLength(lTemp)>=3){
                sImpl = llList2String(lTemp,2);
                if(llGetOwnerKey(kID)!=g_kWearer){
                    return;
                }
            }

            if(Cmd == "-.. ---" && sImpl == ""){ //Seriously why the fuck are we using morse code?
                // sOpt is strictly going to be the version string now
                Compare(COLLAR_VERSION, sOpt);
                if((UPDATE_AVAILABLE && !g_iAmNewer) || g_iDoTriggerUpdate){
                    // valid update
                    g_iDiscoveredUpdaters++;
                    g_kUpdater = kID;
                } else {
                    // this updater is older, dont install it
                    //llSay(0, "Current version is newer or the same as the updater. Trigger update a second time to confirm you want to actually do this");
                    g_iDoTriggerUpdate=TRUE;

                    g_iWaitUpdate=FALSE;
                    g_kUpdater=kID;
                    g_iDiscoveredUpdaters++;
                    Dialog(g_kUpdateUser, "Do you want to install the discovered version from object: "+llKey2Name(g_kUpdater)+"\n\nThis updater contains: "+sOpt, ["Yes", "No"], [], CMD_OWNER, 0, "Update~Confirm");

                }
            }
        }
    }
}
