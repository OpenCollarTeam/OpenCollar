// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Garvin Twine, Cleo Collins,  
// Satomi Ahn, Joy Stipe, Wendy Starfall, littlemousy, Romka Swallowtail, 
// Sumi Perl et al.   
// Licensed under the GPLv2.  See LICENSE for full details. 


//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message

string g_sDevStage="Beta 5";
string g_sCollarVersion="7.4";

integer g_iCaptureIsActive=FALSE; // this is a fix for ensuring proper permissions with capture
integer g_iLatestVersion=TRUE;
float g_fBuildVersion = 0.5;

key g_kWearer;
// Entries for the .settings relay
// Relay will read .settings from root prim and send to oc_settings for storage.
key g_kSettingsReader;
integer g_iSettingsReader; 
key g_kExistingSettings; // To prevent excess linked messages if the settings notecard is not modified, or load is not requested, cache the settings UUID
// End .settings relay

list g_lMenuIDs;//3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
integer g_iMenuStride = 3;

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
//integer SAY = 1004;
integer LINK_CMD_DEBUG = 1999;
integer REBOOT = -1000;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

// .settings Relay related message IDs!
integer LM_SETTING_RELAY_CONTENT = 2100;
integer LM_SETTING_RELAY_LOAD = 2101;
// .settings Relay message end

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";

string GIVECARD = "Help";
string HELPCARD = "OpenCollar_Help";
string CONTACT = "Contact";
string LICENSE = "License";

list OC_SCRIPTS = [
    "oc_anim",
    "oc_auth",
    "oc_bell",
    "oc_bookmarks",
    "oc_com",
    "oc_couples",
    "oc_dialog",
    "oc_exceptions",
    "oc_folders",
    "oc_label",
    "oc_leash",
    "oc_meshlabel",
    "oc_meshthemes",
    "oc_particle",
    "oc_relay",
    "oc_resizer",
    "oc_rlvsuite",
    "oc_rlvsys",
    "oc_settings",
    "oc_sys",
    "oc_themes",
    "oc_titler"
];

key g_kWebLookup;
key g_kCurrentUser;

list g_lAppsButtons;
list g_lResizeButtons;
integer MVANIM_ANNOUNCE = 13001;

integer g_iLocked = FALSE;
integer g_bDetached = FALSE;
integer g_iHide ; // global hide
integer g_iNews=TRUE;

string g_sLockPrimName="Lock"; // Description for lock elements to recognize them //EB //SA: to be removed eventually (kept for compatibility)
string g_sOpenLockPrimName="OpenLock"; // Prim description of elements that should be shown when unlocked
string g_sClosedLockPrimName="ClosedLock"; // Prim description of elements that should be shown when locked
list g_lClosedLockElements; //to store the locks prim to hide or show //EB
list g_lOpenLockElements; //to store the locks prim to hide or show //EB
list g_lClosedLockGlows;
list g_lOpenLockGlows;
string g_sDefaultLockSound="dec9fb53-0fef-29ae-a21d-b3047525d312";
string g_sDefaultUnlockSound="82fa6d06-b494-f97c-2908-84009380c8d1";
string g_sLockSound="dec9fb53-0fef-29ae-a21d-b3047525d312";
string g_sUnlockSound="82fa6d06-b494-f97c-2908-84009380c8d1";

integer g_iAnimsMenu=FALSE;
integer g_iRlvMenu=FALSE;
integer g_iLooks;

integer g_iUpdateChan = -7483213;
integer g_iUpdateHandle;
key g_kUpdaterOrb;
integer g_iUpdateFromMenu;

key github_version_request;
string g_sOtherDist;
key news_request;
string g_sLastNewsTime = "0";

string g_sWeb = "https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/";

integer g_iUpdateAuth;
integer g_iWillingUpdaters = 0;

string g_sSafeWord="RED";

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

//Option Menu variables
string DUMPSETTINGS = "Print";
string STEALTH = "Stealth";
string LOADCARD = "Load";
string REFRESH_MENU = "Fix";

string g_sGlobalToken = "global_";

integer g_iWaitUpdate;
integer g_iWaitRebuild;

integer compareVersions(string v1, string v2) { //compares two symantic version strings, true if v1 >= v2
    // For a collar running a non-release build (one with g_sDevStage set to not null) return TRUE 
    if(g_sDevStage!= ""){
        if(v1 == v2) {
            // likely that the new version has been released. Return true!
            return TRUE;
        } else return FALSE;
    } // all other cases, perform this function as normal!
    integer v1Index=llSubStringIndex(v1,".");
    integer v2Index=llSubStringIndex(v2,".");
    integer v1a=(integer)llGetSubString(v1,0,v1Index);
    integer v2a=(integer)llGetSubString(v2,0,v2Index);
    if (v1a == v2a) {
        if (~v1Index || ~v2Index) {
            string v1b;
            if (v1Index == -1 || v1Index==llStringLength(v1)) v1b="0";
            else v1b=llGetSubString(v1,v1Index+1,-1);
            string v2b;
            if (v2Index == -1 || v2Index==llStringLength(v2)) v2b="0";
            else v2b=llGetSubString(v2,v2Index+1,-1);
            return compareVersions(v1b,v2b);
        } else return FALSE;
    }
    return v1a > v2a;
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else //we've not already given this user a menu. append to list
        g_lMenuIDs += [kID, kMenuID, sName];
}

SettingsMenu(key kID, integer iAuth) {
    string sPrompt = "\n[Settings]";
    list lButtons = [DUMPSETTINGS,LOADCARD,REFRESH_MENU];
    lButtons += g_lResizeButtons+[Checkbox(g_iHide,STEALTH)];
    
    
    if (g_iLooks) lButtons += "Looks";
    else lButtons += "Themes";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Settings");
}

AppsMenu(key kID, integer iAuth) {
    string sPrompt="\n[Apps]\n\nBrowse apps, extras and custom features.";
    //Debug("max memory used: "+(string)llGetSPMaxMemory());
    Dialog(kID, sPrompt, g_lAppsButtons, [UPMENU], 0, iAuth, "Apps");
}

UpdateConfirmMenu() {
    Dialog(g_kWearer, "\nINSTALLATION REQUEST PENDING:\n\nAn update or app installer is requesting permission to continue. Installation progress can be observed above the installer box and it will also tell you when it's done.\n\nShall we continue and start with the installation?", ["Yes","No"], ["Cancel"], 0, CMD_WEARER, "UpdateConfirmMenu");
}

HelpMenu(key kID, integer iAuth) {
    string sPrompt="\nOpenCollar Version: "+g_sCollarVersion+g_sDevStage;
    sPrompt+="\n\nPrefix: %PREFIX%\nChannel: %CHANNEL%\nSafeword: "+g_sSafeWord;
    sPrompt+="\n\nDocumentation: https://opencollar.cc/";
    if(!g_iLatestVersion) sPrompt+="\n\n[Update available!]";
    //Debug("max memory used: "+(string)llGetSPMaxMemory());
    list lUtility = [UPMENU];
    list lStaticButtons=[GIVECARD,CONTACT,LICENSE,"Update"];
    Dialog(kID, sPrompt, lStaticButtons, lUtility, 0, iAuth, "Help/About");
}

MainMenu(key kID, integer iAuth) {
    string sPrompt = "\nOpenCollar\t\t"+g_sCollarVersion;
    sPrompt += "\n\n[secondlife:///app/group/45d71cc1-17fc-8ee4-8799-7164ee264811/about Join the official OpenCollar group to become part of our community.]";
    if(!g_iLatestVersion) sPrompt+="\n\nUPDATE AVAILABLE: A new version has been released. You can obtain an updater from the OpenCollar group.";
    //Debug("max memory used: "+(string)llGetSPMaxMemory());
    list lStaticButtons=["Apps"];
    if (g_iAnimsMenu) lStaticButtons+="Animations";
    else lStaticButtons+="-";
    lStaticButtons+="-";
    lStaticButtons+=["Leash"];
    if (g_iRlvMenu) lStaticButtons+="RLV";
    else lStaticButtons+="-";
    lStaticButtons+=["Access","Settings","Help/About"];
    if (g_iLocked) Dialog(kID, sPrompt, "UNLOCK"+lStaticButtons, [], 0, iAuth, "Main");
    else Dialog(kID, sPrompt, "LOCK"+lStaticButtons, [], 0, iAuth, "Main");
}

UserCommand(integer iNum, string sStr, key kID, integer fromMenu) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llToLower(llList2String(lParams, 0));
    if (sCmd == "menu") {
        string sSubmenu = llToLower(llList2String(lParams, 1));
        if (sSubmenu == "main" || sSubmenu == "") MainMenu(kID, iNum);
        else if (sSubmenu == "apps" || sSubmenu=="addons") AppsMenu(kID, iNum);
        else if (sSubmenu == "help/about") HelpMenu(kID, iNum);
        else if (sSubmenu == "settings") {
            if (iNum != CMD_OWNER && iNum != CMD_WEARER) {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to settings",kID);
                MainMenu(kID, iNum);
            } else SettingsMenu(kID, iNum);
        }
    } else if (sStr == "info") {
        string sMessage = "\n\nModel: "+llGetObjectName();
        sMessage += "\nOpenCollar Version: "+g_sCollarVersion+g_sDevStage+" ("+(string)g_fBuildVersion+")";
        sMessage += "\nUser: "+llGetUsername(g_kWearer);
        sMessage += "\nPrefix: %PREFIX%\nChannel: %CHANNEL%\nSafeword: "+g_sSafeWord;
        llMessageLinked(LINK_SET,NOTIFY,"1"+sMessage,kID);
    }
     else if (sStr == "license") {
        if(llGetInventoryType(".license")==INVENTORY_NOTECARD) llGiveInventory(kID,".license");
        else llMessageLinked(LINK_SET,NOTIFY,"0"+"The license card has been removed from this %DEVICETYPE%. Please find the recent revision [https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/LICENSE here].",kID);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr == "help") {
        llGiveInventory(kID, HELPCARD);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr =="about" || sStr=="help/about") HelpMenu(kID,iNum);
    else if (sStr == "addons" || sStr=="apps") AppsMenu(kID, iNum);
    else if (sStr == "settings") {
        if (iNum == CMD_OWNER || iNum == CMD_WEARER) SettingsMenu(kID, iNum);
    } else if (sStr == "contact") {
        g_kWebLookup = llHTTPRequest(g_sWeb+"~contact", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
        g_kCurrentUser = kID;
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sCmd == "menuto") {
        key kAv = (key)llList2String(lParams, 1);
        if (llGetAgentSize(kAv) != ZERO_VECTOR) {//if kAv is an avatar in this region
            if(llGetOwnerKey(kID)==kAv) MainMenu(kID, iNum);    //if the request was sent by something owned by that agent, send a menu
            else  llMessageLinked(LINK_SET, CMD_ZERO, "menu", kAv);   //else send an auth request for the menu
        }
    } else if (sCmd == "lock" || (!g_iLocked && sStr == "togglelock")) { // the remote uses togglelock
        if(g_iCaptureIsActive){
            llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to toggle lock while capture is active",kID);
            return;
        }
        //Debug("User command:"+sCmd);
        if (iNum == CMD_OWNER || kID == g_kWearer ) {   //primary owners and wearer can lock and unlock. no one else
            //inlined old "Lock()" function
            g_iLocked = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sGlobalToken+"locked=1", "");
            llOwnerSay("@detach=n");
            llMessageLinked(LINK_SET, RLV_CMD, "detach=n", "main");
            llPlaySound(g_sLockSound, 1.0);
            SetLockElementAlpha();//EB
            llMessageLinked(LINK_SET,NOTIFY,"1"+"%WEARERNAME%'s %DEVICETYPE% has been locked.",kID);
        }
        else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to lock",kID);;
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sStr == "runaway" || sCmd == "unlock" || (g_iLocked && sStr == "togglelock")) {
        if(g_iCaptureIsActive){
            llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% while capture is active",kID);
            return;
        }
        if (iNum == CMD_OWNER)  {
            g_iLocked = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sGlobalToken+"locked", "");
            llOwnerSay("@detach=y");
            llMessageLinked(LINK_SET, RLV_CMD, "detach=y", "main");
            llPlaySound(g_sUnlockSound, 1.0);
            SetLockElementAlpha(); //EB
            llMessageLinked(LINK_SET,NOTIFY,"1"+"%WEARERNAME%'s %DEVICETYPE% has been unlocked.",kID);
        }
        else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to unlock",kID);
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sCmd == "fix") {
        if (kID == g_kWearer || iNum == CMD_OWNER){
            RebuildMenu(fromMenu, kID, iNum);
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Menus have been fixed!",kID);
            
        } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to fixing menus",kID);
    } else if (sCmd == "news"){
        llMessageLinked(LINK_SET,NOTIFY, "0News is deprecated in this version", kID);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sCmd == "update") {
        if (kID == g_kWearer) {
            g_iWillingUpdaters = 0;
            g_kCurrentUser = kID;
            g_iUpdateAuth = iNum;
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Searching for nearby updater",kID);
            g_iUpdateHandle = llListen(g_iUpdateChan, "", "", "");
            g_iUpdateFromMenu=fromMenu;
            llWhisper(g_iUpdateChan, "UPDATE|" + g_sCollarVersion);
            g_iWaitUpdate = TRUE;
            llSetTimerEvent(5.0); //set a timer to wait for responses from updaters
        } else {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Only the wearer can update the %DEVICETYPE%.",kID);
            if (fromMenu) HelpMenu(kID, iNum);
        }
    } else if (!llSubStringIndex(sStr,".- ... -.-")) {
        if (kID == g_kWearer) {
            list lTemp = llParseString2List(sStr,["|"],[]);
            if (llList2Float(lTemp,1) < g_fBuildVersion && llList2String(lTemp,1) != "AppInstall") {
                llMessageLinked(LINK_SET, NOTIFY, "0"+"Installation aborted. The version you are trying to install is deprecated. ",g_kWearer);
            } else {
                g_kUpdaterOrb = (key)llGetSubString(sStr,-36,-1);
                UpdateConfirmMenu();
            }
        }
    } else if (sCmd == "version") {
        string sVersion = "\n\nOpenCollar Version: "+g_sCollarVersion+g_sDevStage+" ("+(string)g_fBuildVersion+")";
        if(!g_iLatestVersion) sVersion+="\nUPDATE AVAILABLE: A new version is available! You can find it in the OpenCollar group notices, or at any partner location. See the [https://opencollar.cc OpenCollar] Website for more information!\n";
        llMessageLinked(LINK_SET,NOTIFY,"0"+sVersion,kID);
    }/* else if (sCmd == "objectversion") {
        // ping from an object, we answer to it on the object channel
        // inlined single use GetOwnerChannel(key kOwner, integer iOffset) function
        integer iChan = (integer)("0x"+llGetSubString((string)g_kWearer,2,7)) + 1111;
        if (iChan>0) iChan=iChan*(-1);
        if (iChan > -10000) iChan -= 30000;
        llSay(iChan,(string)g_kWearer+"\\version="+g_sCollarVersion);
    } else if (sCmd == "attachmentversion") {
        // Reply to version request from "garvin style" attachment
        integer iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (iInterfaceChannel > 0) iInterfaceChannel = -iInterfaceChannel;
        llRegionSayTo(g_kWearer, iInterfaceChannel, "version="+g_sCollarVersion);
    }*/
}

string GetTimestamp() { // Return a string of the date and time
    string out;
    string DateUTC = llGetDate();
    if (llGetGMTclock() < 28800) { // that's 28800 seconds, a.k.a. 8 hours.
        list DateList = llParseString2List(DateUTC, ["-", "-"], []);
        integer year = llList2Integer(DateList, 0);
        integer month = llList2Integer(DateList, 1);
        integer day = llList2Integer(DateList, 2);
       if(day==1) {
           if(month==1) return (string)(year-1) + "-01-31";
           else {
                --month;
                if(month==2) day = 28+(year%4==FALSE); //To do: fix before 28th feb 2100.
                else day = 30+ (!~llListFindList([4,6,9,11],[month])); //31 days hath == TRUE
            }
        }
        else --day;
        out=(string)year + "-" + (string)month + "-" + (string)day;
    } else out=llGetDate();
    integer t = (integer)llGetWallclock(); // seconds since midnight
    out += " " + (string)(t / 3600) + ":";
    integer mins=(t % 3600) / 60;
    if (mins <10) out += "0";
    out += (string)mins+":";
    integer secs=t % 60;
    if (secs < 10) out += "0";
    out += (string)secs;
    return out;
}


BuildLockElementList() {//EB
    list lParams;
    // clear list just in case
    g_lOpenLockElements = [];
    g_lClosedLockElements = [];
    //root prim is 1, so start at 2
    integer n=2;
    for (; n <= llGetNumberOfPrims(); n++) {
        // read description
        lParams=llParseString2List(llGetLinkName(n), ["~"], []);
        // check inf name is lock name
        if (llList2String(lParams, 0)==g_sLockPrimName || llList2String(lParams, 0)==g_sClosedLockPrimName)
            // if so store the number of the prim
            g_lClosedLockElements += [n];
        else if (llList2String(lParams, 0)==g_sOpenLockPrimName)
            // if so store the number of the prim
            g_lOpenLockElements += [n];
    }
}

PermsCheck() {
    if(!g_iFirstInit)return;
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;

    // check permissions on all OC_SCRIPTS 
    integer i = llGetListLength(OC_SCRIPTS);
    while (i) {
        string sScript = llList2String(OC_SCRIPTS, --i);
        if (llGetInventoryType(sScript) == INVENTORY_SCRIPT) {
            if (!((llGetInventoryPermMask(sScript,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
                    llOwnerSay("The " + sScript + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
            }

            if (!((llGetInventoryPermMask(sScript,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
                    llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sScript + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
            }
        }
    }
    
    g_iFirstInit=FALSE;
}


SetLockElementAlpha() { //EB
    if (g_iHide) return ; // ***** if collar is hide, don't do anything
    //loop through stored links, setting alpha if element type is lock
    integer n;
    integer iLinkElements = llGetListLength(g_lOpenLockElements);
    for (; n < iLinkElements; n++) {
        llSetLinkAlpha(llList2Integer(g_lOpenLockElements,n), !g_iLocked, ALL_SIDES);
        UpdateGlow(llList2Integer(g_lOpenLockElements,n), !g_iLocked);
    }
    iLinkElements = llGetListLength(g_lClosedLockElements);
    for (n=0; n < iLinkElements; n++) {
        llSetLinkAlpha(llList2Integer(g_lClosedLockElements,n), g_iLocked, ALL_SIDES);
        UpdateGlow(llList2Integer(g_lClosedLockElements,n), g_iLocked);
    }
}

UpdateGlow(integer iLink, integer iAlpha) {
    list lGlows;
    integer i;
    if (iAlpha == 0) {
        float fGlow = llList2Float(llGetLinkPrimitiveParams(iLink,[PRIM_GLOW,0]),0);
        lGlows = g_lClosedLockGlows;
        if (g_iLocked) lGlows = g_lOpenLockGlows;
        i = llListFindList(lGlows,[iLink]);
        if (i !=-1 && fGlow > 0) lGlows = llListReplaceList(lGlows,[fGlow],i+1,i+1);
        if (i !=-1 && fGlow == 0) lGlows = llDeleteSubList(lGlows,i,i+1);
        if (i == -1 && fGlow > 0) lGlows += [iLink, fGlow];
        if (g_iLocked) g_lOpenLockGlows = lGlows;
        else g_lClosedLockGlows = lGlows;
        llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, 0.0]);
    } else {
        lGlows = g_lOpenLockGlows;
        if (g_iLocked) lGlows = g_lClosedLockGlows;
        i = llListFindList(lGlows,[iLink]);
        if (i != -1) llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, llList2Float(lGlows, i+1)]);
    }
}

RebuildMenu(integer iRemenu, key kLastUser, integer iLastAuth) {
    //Debug("Rebuild Menu");
    g_iAnimsMenu=FALSE;
    g_iRlvMenu=FALSE;
    g_lResizeButtons = [];
    g_lAppsButtons = [] ;
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Main", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Apps", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "AddOns", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Settings", "");
    
    if(iRemenu)
        SettingsMenu(kLastUser, iLastAuth); // test fix
}

init (){
    github_version_request = llHTTPRequest(g_sWeb+"~version", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
    g_iWaitRebuild = TRUE;
    PermsCheck();
    llSetTimerEvent(1.0);
}

StartUpdate(){
    integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(g_kUpdaterOrb, g_iUpdateChan, "ready|" + (string)pin );
}
integer g_iFirstInit=FALSE;
default {
    state_entry() {
        if(llGetStartParameter()!=0)state inUpdate;
        
        g_kWearer = llGetOwner();
        BuildLockElementList();
        g_iFirstInit=TRUE;
        llSleep(10.0);
        init();
        //Debug("Starting, max memory used: "+(string)llGetSPMaxMemory());
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if(sStr == "debug")llMessageLinked(LINK_SET,LINK_CMD_DEBUG,"",kID);
        if(sStr == "versions")llMessageLinked(LINK_SET,LINK_CMD_DEBUG,"ver",kID);
        if (iNum == MENUNAME_RESPONSE) {
            //sStr will be in form of "parent|menuname"
            list lParams = llParseString2List(sStr, ["|"], []);
            string sName = llList2String(lParams, 0);
            string sSubMenu = llList2String(lParams, 1);
            if (sName=="AddOns" || sName=="Apps"){  //we only accept buttons for apps nemu
                //Debug("we handle " + sName);
                if (llListFindList(g_lAppsButtons, [sSubMenu]) == -1) {
                    g_lAppsButtons += [sSubMenu];
                    g_lAppsButtons = llListSort(g_lAppsButtons, 1, TRUE);
                }
            } else if (sStr=="Main|Animations") g_iAnimsMenu=TRUE;
            else if (sStr=="Main|RLV") g_iRlvMenu=TRUE;
            else if (sStr=="Settings|Size/Position") g_lResizeButtons = ["Position","Rotation","Size"];
        } else if (iNum == MENUNAME_REMOVE) {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            string parent = llList2String(lParams, 0);
            string child = llList2String(lParams, 1);
            if (parent=="Apps" || parent=="AddOns") {
                integer gutiIndex = llListFindList(g_lAppsButtons, [child]);
                //only remove if it's there
                if (gutiIndex != -1) g_lAppsButtons = llDeleteSubList(g_lAppsButtons, gutiIndex, gutiIndex);
            } else if (child == "Size/Position") g_lResizeButtons = [];
        } else if (iNum == DIALOG_RESPONSE) {
            //Debug("Menu response");
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                //process response
                if (sMenu=="Main"){
                    //Debug("Main menu response: '"+sMessage+"'");
                    if (sMessage == "LOCK" || sMessage== "UNLOCK"){
                        
                        if(g_iCaptureIsActive){
                            llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% while capture is active",kAv);
                            return;
                        }
                        //Debug("doing usercommand for lock/unlock");
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    }
                    else if (sMessage == "Help/About") HelpMenu(kAv, iAuth);
                    else if (sMessage == "Apps")  AppsMenu(kAv, iAuth);
                    else llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                } else if (sMenu=="Apps"){
                    //Debug("Apps menu response:"+sMessage);
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                } else if (sMenu=="Help/About") {
                    //Debug("Help menu response");
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else if (sMessage == GIVECARD) UserCommand(iAuth,"help",kAv, TRUE);
                    else if (sMessage == LICENSE) UserCommand(iAuth,"license",kAv, TRUE);
                    else if (sMessage == CONTACT) UserCommand(iAuth,"contact",kAv, TRUE);
                    else if (sMessage == "Update") UserCommand(iAuth,"update",kAv,TRUE);
                } else if (sMenu == "UpdateConfirmMenu"){
                    if (sMessage=="Yes") StartUpdate();
                    else {
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"Installation cancelled.",kAv);
                        return;
                    }
                } else if (sMenu == "Settings") {
                     if (sMessage == DUMPSETTINGS) llMessageLinked(LINK_SET, iAuth,"print settings",kAv);
                     else if (sMessage == LOADCARD) llMessageLinked(LINK_SET, iAuth,sMessage,kAv);
                     else if (sMessage == REFRESH_MENU) {
                         UserCommand(iAuth, sMessage, kAv, TRUE);
                         return;
                    } else if(sMessage == Checkbox(g_iHide, STEALTH)){
                        g_iHide=1-g_iHide;
                        if(g_iHide)llMessageLinked(LINK_SET,iAuth,"hide",kAv);
                        else llMessageLinked(LINK_SET, iAuth, "show", kAv);
                    } else if (sMessage == "Themes") {
                        llMessageLinked(LINK_SET, iAuth, "menu Themes", kAv);
                        return;
                    } else if (sMessage == "Looks") {
                        llMessageLinked(LINK_SET, iAuth, "looks",kAv);
                        return;
                    } else if (sMessage == UPMENU) {
                        MainMenu(kAv, iAuth);
                        return;
                    } else if (sMessage == "Position" || sMessage == "Rotation" || sMessage == "Size") {
                        llMessageLinked(LINK_SET, iAuth, llToLower(sMessage), kAv);
                        return;
                    }
                    SettingsMenu(kAv,iAuth);
                }
            }
        } else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID, FALSE); 
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sGlobalToken+"locked") {
                g_iLocked = (integer)sValue;
                if (g_iLocked) llOwnerSay("@detach=n");
                SetLockElementAlpha();
            } else if(sToken == g_sGlobalToken + "checkboxes"){
                g_lCheckboxes = llCSV2List(sValue);
            } else if (sToken == "intern_looks") g_iLooks = (integer)sValue;
            else if (sToken == "intern_news") g_iNews = (integer)sValue;
            else if(sToken =="lock_locksound") {
                if(sValue=="default") g_sLockSound=g_sDefaultLockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sLockSound=sValue;
            } else if(sToken =="lock_unlocksound") {
                if (sValue=="default") g_sUnlockSound=g_sDefaultUnlockSound;
                else if ((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sUnlockSound=sValue;
            } else if (sToken == g_sGlobalToken+"safeword") g_sSafeWord = sValue;
            else if (sToken == "intern_dist") g_sOtherDist = sValue;
            else if (sStr == "settings=sent") {
            } else if(sToken == "capture_isActive"){
                g_iCaptureIsActive=TRUE;
            }
        } else if(iNum == LM_SETTING_DELETE){
            if(sStr == "capture_isActive") g_iCaptureIsActive=FALSE;
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == RLV_REFRESH || iNum == RLV_CLEAR) {
            if (g_iLocked) llMessageLinked(LINK_SET, RLV_CMD, "detach=n", "main");
            else llMessageLinked(LINK_SET, RLV_CMD, "detach=y", "main");
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LM_SETTING_RELAY_LOAD){
            g_iSettingsReader=0;
            if(llGetInventoryType(".settings") == INVENTORY_NOTECARD){
                g_kSettingsReader = llGetNotecardLine(".settings", 0);
            }
        } else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sCollarVersion+" "+g_sDevStage);
            if(onlyver)return; // basically this command was: <prefix> versions
            // The rest of this command can be access by <prefix> debug
            llInstantMessage(kID, llGetScriptName() +" FREE MEMORY: "+(string)llGetFreeMemory()+" bytes");
            llInstantMessage(kID, llGetScriptName()+" LOCKED: "+(string)g_iLocked);
            llInstantMessage(kID, llGetScriptName()+" HIDDEN: "+(string)g_iHide);
            llInstantMessage(kID, llGetScriptName()+" DETACHED WHILE LOCKED: "+(string)g_bDetached);
        } else if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        }
    }

    on_rez(integer iParam) {
        g_iHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
        llSleep(7.0);
        init();
    }

    changed(integer iChange) {
        if ((iChange & CHANGED_INVENTORY) && !llGetStartParameter()) {
            g_iWaitRebuild = TRUE;
            PermsCheck();
            llSetTimerEvent(1.0);
            /*if(llGetInventoryType(".settings") == INVENTORY_NOTECARD){
                if(llGetInventoryKey(".settings") != g_kExistingSettings){
                    g_iSettingsReader=0;
                    g_kSettingsReader = llGetNotecardLine(".settings", g_iSettingsReader);
                    g_kExistingSettings = llGetInventoryKey(".settings");
                }
            } else */
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST,"ALL","");
        }
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_COLOR) {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
            if (g_iHide != iNewHide){   //check there's a difference to avoid infinite loop
                g_iHide = iNewHide;
                SetLockElementAlpha(); // update hide elements
            }
        }
        if (iChange & CHANGED_LINK) {
            BuildLockElementList(); // need rebuils lockelements list
        }
     /*  if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }
    
    dataserver(key kID, string sData){
        if(kID==g_kSettingsReader){
            if(sData ==EOF)llMessageLinked(LINK_SET,LM_SETTING_REQUEST,"ALL","");
            else{
                g_iSettingsReader++;
                llMessageLinked(LINK_SET, LM_SETTING_RELAY_CONTENT, sData, (string)g_iSettingsReader);
                g_kSettingsReader=llGetNotecardLine(".settings", g_iSettingsReader);
            }
        }
    }

    attach(key kID) {
        if (g_iLocked) {
            if(kID == NULL_KEY) {
                g_bDetached = TRUE;
                llMessageLinked(LINK_SET,NOTIFY_OWNERS, "%WEARERNAME% has attached me while locked at "+GetTimestamp()+"!",kID);
            } else if (g_bDetached) {
                llMessageLinked(LINK_SET,NOTIFY_OWNERS, "%WEARERNAME% has re-attached me at "+GetTimestamp()+"!",kID);
                g_bDetached = FALSE;
            }
        }
    }

    http_response(key id, integer status, list meta, string body) {
        if (status == 200) { // be silent on failures.
            if (id == g_kWebLookup){
                llMessageLinked(LINK_SET,NOTIFY,"0"+body,g_kCurrentUser);
            } else if (id == github_version_request) {  // strip the newline off the end of the text
                if (compareVersions(llStringTrim(body, STRING_TRIM),g_sCollarVersion)) g_iLatestVersion=FALSE;
                else g_iLatestVersion=TRUE;
            } 
        }
    }

    listen(integer channel, string name, key id, string message) {
        if (llGetOwnerKey(id) == g_kWearer) {   //collar and updater have to have the same Owner else do nothing!
            list lTemp = llParseString2List(message, ["|"],[]);
            string sCommand = llList2String(lTemp, 0);
            string sOption = llList2String(lTemp, 1);
            if(sCommand == "-.. ---") {
                if (sOption == "AppInstall" || (float)sOption >= g_fBuildVersion) {
                    g_iWillingUpdaters++;
                    g_kUpdaterOrb = id;
                } else {
                    llMessageLinked(LINK_SET, NOTIFY, "0"+"Installation aborted. The version you are trying to install is deprecated. ",g_kWearer);
                    llSetTimerEvent(0);
                    g_iWaitUpdate = FALSE;
                    llListenRemove(g_iUpdateHandle);
                }
            }
        }
    }

    timer() {
        if (g_iWaitUpdate) {
            g_iWaitUpdate = FALSE;
            llListenRemove(g_iUpdateHandle);
            if (!g_iWillingUpdaters) {   //if no updaters responded, get upgrader info from web and remenu
                g_kWebLookup = llHTTPRequest(g_sWeb+"~update", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
                if (g_iUpdateFromMenu) HelpMenu(g_kCurrentUser,g_iUpdateAuth);
            } else if (g_iWillingUpdaters > 1) {    //if too many updaters, PANIC!
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Multiple updaters were found nearby. Please remove all but one and try again.",g_kCurrentUser);
            } else StartUpdate();  //update
           // else UpdateConfirmMenu();  //perform update
        }
        if (g_iWaitRebuild) {
            g_iWaitRebuild = FALSE;
            RebuildMenu(FALSE, "",0);
        }
        if (!g_iWaitUpdate && !g_iWaitRebuild) llSetTimerEvent(0.0);
    }
}
state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
    }
}
