
/*
This file is a part of OpenCollar.
Copyright ©2021


: Contributors :

Aria (Tashia Redrose)
    *June 2020       -       Created oc_core
      * This combines oc_com, oc_auth, and oc_sys
    * July 2020     -       Maintenance fixes, feature implementations


et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

integer NOTIFY_OWNERS=1003;

//string g_sParentMenu = "";
string g_sSubMenu = "Main";
string COLLAR_VERSION = "8.0.4000"; // Provide enough room
// LEGEND: Major.Minor.Build RC Beta Alpha
integer UPDATE_AVAILABLE=FALSE;
string NEW_VERSION = "";
integer g_iAmNewer=FALSE;
integer g_iChannel=1;
string g_sPrefix;

integer g_iVerbosityLevel=1;

integer g_iNotifyInfo=FALSE;

string MajorMinor(){
    list lTmp = llParseString2List(COLLAR_VERSION,["."],[]);
    return llList2String(lTmp,0)+"."+llList2String(lTmp,1);
}

string g_sSafeword="RED";
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

key g_kWeldBy;
list g_lMainMenu=["Apps", "Access", "Settings", "Help/About"];

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}
integer g_iHide=FALSE;
integer g_iAllowHide=TRUE;
Settings(key kID, integer iAuth){
    string sPrompt = "OpenCollar\n\n[Settings]\n\nEditor - Interactive Settings Editor";
    list lButtons = ["Print", "Load", "Fix Menus"];
    if (llGetInventoryType("oc_resizer") == INVENTORY_SCRIPT) lButtons += ["Resize"];
    else lButtons += ["-"];
    lButtons += [Checkbox(g_iHide, "Hide"), "EDITOR", Checkbox(g_iAllowHide, "AllowHiding"), "Addon.."];
    Dialog(kID, sPrompt, lButtons, [UPMENU],0,iAuth, "Menu~Settings");
}

AddonSettings(key kID, integer iAuth)
{
    string sPrompt = "OpenCollar\n\n[Addon Settings\n\nWearerAddons - Allow/Disallow use of wearer owned addons\nAddonLimited - Limit whether wearer owned addons can modify the owners list or weld state (default enabled)";
    list lButtons = [Checkbox(g_iWearerAddons, "WearerAddons"), Checkbox(g_iWearerAddonLimited, "AddonLimited"), Checkbox(g_iAddons, "Addons")];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~SAddons");
}

integer g_iWelded=FALSE;
integer g_iWearerAddons=TRUE;
// The original idea in #356, was to make this as a app, but i fail to see why we must use an extra app just to create the weld, the extra app or possibly an addon could be made to unweld should the wearer desire it.
integer g_iAddons=TRUE;
list g_lApps;
AppsMenu(key kID, integer iAuth){
    string sPrompt = "\n[Apps]\nYou have "+(string)llGetListLength(g_lApps)+" apps installed";
    Dialog(kID, sPrompt, g_lApps, [UPMENU],0,iAuth, "Menu~Apps");
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\nOpenCollar "+COLLAR_VERSION;
    list lButtons = [Checkbox(g_iLocked, "Lock")];

    if(!g_iWelded)lButtons+=g_lMainMenu;
    else lButtons=g_lMainMenu;

    if(UPDATE_AVAILABLE ) sPrompt += "\n\nUPDATE AVAILABLE: Your version is: "+COLLAR_VERSION+", The current release version is: "+NEW_VERSION;
    if(g_iAmNewer)sPrompt+="\n\nYour collar version is newer than the public release. This may happen if you are using a beta or pre-release copy.\nNote: Pre-Releases may have bugs. Ensure you report any bugs to [https://github.com/OpenCollarTeam/OpenCollar Github]";

    if(g_iWelded)sPrompt+="\n\n* The Collar is Welded by secondlife:///app/agent/"+(string)g_kWeldBy+"/about *";
    if(iAuth==CMD_OWNER && g_iLocked && !g_iWelded)lButtons+=["Weld"];


    list lUtility;
    //if(g_iAmNewer)lUtility += ["FEEDBACK", "BUG"];

    Dialog(kID, sPrompt, lButtons, lUtility, 0, iAuth, "Menu~Main");
}
key g_kGroup = "";
integer g_iLimitRange=TRUE;
integer g_iPublic=FALSE;
integer g_iCaptured = FALSE;
AccessMenu(key kID, integer iAuth){
    if(g_iCaptured){
        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to the access settings while capture is active!", kID);
        llMessageLinked(LINK_SET, 0, "menu", kID);
        return;
    }
    string sPrompt = "\nOpenCollar Access Controls";
    list lButtons = ["+ Owner", "+ Trust", "+ Block", "- Owner", "- Trust", "- Block", Checkbox(bool((g_kGroup!="")), "Group"), Checkbox(g_iPublic, "Public")];

    lButtons += [Checkbox(g_iLimitRange, "Limit Range"), "Runaway", "Access List"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Auth");
}

HelpMenu(key kID, integer iAuth){
    string EXTRA_VER_TXT = setor(bool((llGetSubString(COLLAR_VERSION,-1,-1)=="0")), "", " (ALPHA "+llGetSubString(COLLAR_VERSION,-1,-1)+") ");
    EXTRA_VER_TXT += setor(bool((llGetSubString(COLLAR_VERSION,-2,-2)=="0")), "", " (BETA "+llGetSubString(COLLAR_VERSION,-2,-2)+") ");
    EXTRA_VER_TXT += setor(bool((llGetSubString(COLLAR_VERSION,-3,-3) == "0")), "", " (RC "+llGetSubString(COLLAR_VERSION,-3,-3)+") ");

    string sPrompt = "\nOpenCollar "+COLLAR_VERSION+" "+EXTRA_VER_TXT+"\nVersion: "+setor(g_iAmNewer, "(Newer than release)", "")+" "+setor(UPDATE_AVAILABLE, "(Update Available)", "(Most Current Version)");
    sPrompt += "\n\nDocumentation https://opencollar.cc";
    sPrompt += "\nPrefix: "+g_sPrefix+"\nChannel: "+(string)g_iChannel;

    if(g_iNotifyInfo){
        g_iNotifyInfo=FALSE;
        llMessageLinked(LINK_SET, NOTIFY, sPrompt, kID);
        return;
    }
    list lButtons = ["Update", "Support", "License"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Help");
}

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["▢", "▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}
integer g_iUpdatePin = 0;
//string g_sDeviceName;
//string g_sWearerName;


UserCommand(integer iNum, string sStr, key kID) {
    // Serenity  -   Remove line that prevented anyone but owner, wearer or trusted from executing commands here. That made it so that even if public or group was enabled it would block functionality. Additionally - the link message block already checks auth level
    if (iNum == CMD_OWNER && sStr == "runaway") {
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_owner","origin");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_trust","origin");
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_block","origin");
        return;
    }
    if (sStr==g_sSubMenu || sStr == "menu "+g_sSubMenu || sStr == "menu") Menu(kID, iNum);
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
            if(iNum == CMD_OWNER || iNum == CMD_WEARER){
                g_iUpdatePin = llRound(llFrand(0x7FFFFFFF))+1; // Maximum integer size
                llSetRemoteScriptAccessPin(g_iUpdatePin);

                // Now that a pin is set, scan for a updater and chainload
                g_iDiscoveredUpdaters=0;
                g_kUpdater=NULL_KEY;
                g_kUpdateUser=kID;
                llMessageLinked(LINK_SET, NOTIFY, "0Searching for a updater", kID);
                g_iUpdateAuth = iNum;
                llListenRemove(g_iUpdateListener);
                g_iUpdateListener = llListen(g_iUpdateChan, "", "", "");
                llWhisper(g_iUpdateChan, "UPDATE|"+MajorMinor());
                g_iWaitUpdate = TRUE;
                llSetTimerEvent(5);
            } else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to update the collar", kID);
        } else if(sChangetype == "safeword"){
            if(sChangevalue!=""){
                if(iNum == CMD_OWNER){
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_safeword="+sChangevalue, "");
                    llMessageLinked(LINK_SET,NOTIFY,"1Safeword is now set to '"+sChangevalue,kID);

                    if(sChangevalue == "RED"){
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "global_safeword","");
                    }

                    if(llToLower(sChangevalue) == "off"){
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_safeworddisable=1", "");
                    } else {
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "global_safeworddisable","");
                    }
                }
            } else {
                if(iNum == CMD_OWNER || iNum == CMD_WEARER){
                    llMessageLinked(LINK_SET, NOTIFY, "0The safeword is current set to: '"+g_sSafeword+"'",kID);
                }
            }
        } else if(sChangetype == "menu"){
            if(llToLower(sChangevalue) == "access"){
                AccessMenu(kID,iNum);
            } else if(llToLower(sChangevalue) == "settings"){
                Settings(kID,iNum);
            } else if(llToLower(sChangevalue) == "apps"){
                AppsMenu(kID,iNum);
            } else if(llToLower(sChangevalue) == "help/about"){
                HelpMenu(kID,iNum);
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
                HelpMenu(kID,iNum);
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
            llMessageLinked(LINK_SET, NOTIFY, "0The wearer's name is now set to %WEARERNAME%", kID);
        } else if(llToLower(sChangetype) == "device" && iNum == CMD_OWNER){
            if(llToLower(sChangevalue) == "name"){
                sChangevalue = llDumpList2String(llList2List(lParameters,2,-1), " ");
                if(llGetListLength(lParameters) == 2){
                    // print current device name
                    llMessageLinked(LINK_SET, NOTIFY, "0The current device name is: %DEVICENAME%",kID);
                    return;
                }
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_devicename="+sChangevalue,"");
                llMessageLinked(LINK_SET, NOTIFY, "0The device name is now set to: %DEVICENAME%", kID);
            }
        } else if(llToLower(sChangetype) == "allowhide"){
            if(iNum == CMD_OWNER){
                if(g_iAllowHide)llMessageLinked(LINK_SET, NOTIFY, "0The wearer can no longer hide the collar", kID);
                else llMessageLinked(LINK_SET,NOTIFY, "0The wearer can hide the collar on their own", kID);
                g_iAllowHide=1-g_iAllowHide;
                if(sChangevalue=="remenu")Settings(kID,iNum);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_allowhide="+(string)g_iAllowHide, "");
            } else {
                llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to toggling Allow Hide", kID);
                if(sChangevalue == "remenu")Settings(kID,iNum);
            }
        } else if(llToLower(sChangetype)=="lock" && !g_iWelded && (iNum == CMD_OWNER || iNum == CMD_WEARER)){
            // allow locking
            g_iLocked=TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_locked="+(string)g_iLocked,"");
            llMessageLinked(LINK_SET, NOTIFY, "1%WEARERNAME%'s collar has been locked", kID);
            llPlaySound(g_sLockSound,1);
        } else if(llToLower(sChangetype) == "unlock" && (iNum == CMD_OWNER || iNum == CMD_TRUSTED) && !g_iWelded){
            g_iLocked=FALSE;
            llPlaySound(g_sUnlockSound,1);
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "global_locked","");
            llMessageLinked(LINK_SET, NOTIFY, "1%WEARERNAME%'s collar has been unlocked", kID);
        } else {
            if(sChangevalue!="")return;
            if(llToLower(sChangetype) == "access")AccessMenu(kID,iNum);
            else if(llToLower(sChangetype) == "settings")Settings(kID,iNum);
            else if(llToLower(sChangetype) == "apps")AppsMenu(kID,iNum);
            else if(llToLower(sChangetype) == "help/about") HelpMenu(kID,iNum);
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
list g_lMenuIDs;
integer g_iMenuStride;
integer g_iLocked=FALSE;
Compare(string V1, string V2){
    NEW_VERSION=V2;

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
        UPDATE_AVAILABLE=FALSE;
        g_iAmNewer=TRUE;

        llSetText("", <1,0,0>,1);
    }
}

key g_kUpdateCheck = NULL_KEY;
DoCheckUpdate(){
    g_kUpdateCheck = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/version.txt",[],"");
}

key g_kCheckDev;

DoCheckDevUpdate()
{
    g_kCheckDev = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/dev_version.txt",[],"");
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

list g_lTestReports = ["5556d037-3990-4204-a949-73e56cd3cb06", "1a828b4e-6345-4bb3-8d41-f93e6621ba25"]; // Aria and Roan
// Any other team members please add yourself if you want feedback/bug reports. Or ask to be added if you do not have commit access
// These IDs will only be in here during the testing period to allow for the experimental feedback/bug report system to do its thing
// As most do not post to github, i am experimenting to see if a menu option in the collar of a Alpha/Beta might encourage feedback or bugs to be sent even if it has to be sent through a llInstantMessage

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
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
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
                    } else if(sMsg == "FEEDBACK"){
                        Dialog(kAv, "Please submit your feedback for this alpha/beta/rc", [],[],0,iAuth,"Main~Feedback");
                        iRespring=FALSE;
                    } else if(sMsg == "BUG"){
                        Dialog(kAv, "Please type your bug report, including any reproduction steps. If it is easier, please contact the secondlife:///app/group/c5e0525c-29a9-3b66-e302-34fe1bc1bd43/about group, or submit your bug report on [https://github.com/OpenCollarTeam/OpenCollar GitHub] - or both!", [],[],0,iAuth, "Main~Bug");
                        iRespring=FALSE;
                    }  else {
                        iRespring=FALSE;
                        // don't recaculate while developing
                        llMessageLinked(LINK_SET, iAuth,"menu "+ sMsg, kAv); // Recalculate
                    }


                    if(iRespring)Menu(kAv,iAuth);
                } else if(sMenu == "weld~consent"){
                    if(sMsg == "No"){
                        llMessageLinked(LINK_SET, NOTIFY, "1%NOACCESS% to welding the collar.", g_kWelder);
                    } else {
                        // do weld
                        llMessageLinked(LINK_SET, NOTIFY, "1Please wait...", g_kWelder);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "intern_weld=1", g_kWelder);
                        g_iWelded=TRUE;
                    }
                } else if(sMenu=="Menu~Auth"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else if(llGetSubString(sMsg,0,0) == "+"){
                        if(iAuth == CMD_OWNER){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "add "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        }
                        else
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to adding a person", kAv);
                    } else if(llGetSubString(sMsg,0,0)=="-"){
                        if(iAuth == CMD_OWNER){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "rem "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        } else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to removing a person", kAv);
                    } else if(sMsg == "Access List"){
                        llMessageLinked(LINK_SET, iAuth, "print auth", kAv);
                    } else if(sMsg == Checkbox(bool((g_kGroup!="")), "Group")){
                        if(iAuth >=CMD_OWNER && iAuth <= CMD_TRUSTED){
                            if(g_kGroup!=""){
                                g_kGroup="";
                                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_group", "origin");
                            }else{
                                g_kGroup = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]),0);
                                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_group="+(string)g_kGroup, "origin");
                            }
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to changing group access", kAv);
                        }
                    } else if(sMsg == Checkbox(g_iPublic, "Public")){
                        if(iAuth >=CMD_OWNER && iAuth <= CMD_TRUSTED){

                            g_iPublic=1-g_iPublic;

                            if(g_iPublic)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_public=1", "origin");
                            else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_public","origin");

                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to changing public", kAv);
                        }
                    } else if(sMsg == Checkbox(g_iLimitRange, "Limit Range")){
                        if(iAuth >=CMD_OWNER && iAuth <= CMD_TRUSTED){
                            g_iLimitRange=1-g_iLimitRange;

                            if(!g_iLimitRange)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_limitrange=0","origin");
                            else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_limitrange", "origin");
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to changing range limit", kAv);
                        }
                    } else if(sMsg == "Runaway"){
                        llMessageLinked(LINK_SET,0,"menu runaway", kAv);
                        iRespring=FALSE;
                    }


                    if(iRespring)AccessMenu(kAv,iAuth);
                } else if(sMenu == "Menu~Settings"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Print"){
                        llMessageLinked(LINK_SET, iAuth, "print settings", kAv);
                    } else if(sMsg == "Fix Menus"){
                        llMessageLinked(LINK_SET, iAuth, "fix", kAv);
                        llMessageLinked(LINK_SET, NOTIFY, "0Menus have been fixed", kAv);
                    } else if(sMsg == Checkbox(g_iHide,"Hide")){

                        if(!g_iAllowHide && iAuth == CMD_WEARER){
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to hiding the collar", kAv);
                            return;
                        }
                        if(iAuth != CMD_OWNER && iAuth!= CMD_WEARER){
                            llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% to hiding the collar", kAv);
                            return;
                        }

                        g_iHide=1-g_iHide;
                        llMessageLinked(LINK_SET, iAuth, setor(g_iHide, "hide", "show"), kAv);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_hide="+(string)g_iHide, "");
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
                        AddonSettings(kAv,iAuth);
                    }

                    if(iRespring)Settings(kAv,iAuth);
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
                        Settings(kAv,iAuth);
                    }



                    if(iRespring)AddonSettings(kAv,iAuth);
                } else if(sMenu == "Menu~Help"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else if(sMsg == "License"){
                        llGiveInventory(kAv, ".license");
                    } else if(sMsg == "Support"){
                        llMessageLinked(LINK_SET, NOTIFY, "0You can get support for OpenCollar in the following group: secondlife:///app/group/45d71cc1-17fc-8ee4-8799-7164ee264811/about or for scripting related questions or beta versions: secondlife:///app/group/c5e0525c-29a9-3b66-e302-34fe1bc1bd43/about", kAv);
                    } else if(sMsg == "Update"){
                        UserCommand(iAuth, "update", kAv);
                    }

                    if(iRespring)HelpMenu(kAv,iAuth);
                } else if(sMenu == "Menu~Apps"){
                    if(sMsg == UPMENU){
                        Menu(kAv, iAuth);
                    }else{
                        llMessageLinked(LINK_SET, 0, "menu "+sMsg, kAv);
                    }
                } else if(sMenu == "Main~Feedback" || sMenu == "Main~Bug"){
                    integer iStart=0;
                    integer iEnd = llGetListLength(g_lTestReports);
                    if(!g_iAmNewer){
                        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% due to: Testing period has ended for this version", kAv);
                        return;
                    }
                    for(iStart=0;iStart<iEnd;iStart++){
                        llInstantMessage((key)llList2String(g_lTestReports, iStart), "T:"+sMenu+":"+COLLAR_VERSION+"\nFROM: "+llKey2Name(kAv)+"\nAUTH LEVEL: "+(string)iAuth+"\nBODY: "+sMsg);
                    }

                    llMessageLinked(LINK_SET, NOTIFY, "0Thank you. Your report has been sent. Please do not abuse this tool, it is intended to send feedback or bug reports during a testing period", kAv);
                    Menu(kAv,iAuth);
                }
            }
        }else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
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
                }
            } else if(sToken == "auth"){
                if(sVar == "group"){
                    if(sVal==(string)NULL_KEY)sVal="";
                    g_kGroup=(key)sVal;
                } else if(sVar == "public"){
                    g_iPublic = (integer)sVal;
                } else if(sVar == "limitrange"){
                    g_iLimitRange=(integer)sVal;
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
                else if(sVar == "safeword"){
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
                Menu(g_kWeldBy,llList2Integer(lParameters,2));
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

                DoCheckUpdate();

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
                if(g_iAmNewer)DoCheckDevUpdate();
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
                if(sImpl=="8000"){ // v8.0.00
                    // Nothing to do here. Continue
                } else {
                    // Not v8 or above
                    // Require object owner is wearer
                    if(llGetOwnerKey(kID)!=g_kWearer){
                        return;
                    }
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
                    llMessageLinked(LINK_SET, NOTIFY, "0The version you are trying to install is older than the currently installed scripts, or it is the same version. To install anyway, trigger the install a second time", g_kUpdateUser);
                    //llSay(0, "Current version is newer or the same as the updater. Trigger update a second time to confirm you want to actually do this");
                    g_iDoTriggerUpdate=TRUE;
                }
            }
        }
    }
}
