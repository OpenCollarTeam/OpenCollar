////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - main                                //
//                                 version 3.990                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message

string g_sCollarVersion="20150518.3";
integer g_iLatestVersion=TRUE;

list g_lOwners;
key g_kWearer;
//string g_sOldRegionName;
//list g_lMenuPrompts;
    

list g_lMenuIDs;//3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
integer g_iMenuStride = 3;

integer g_iScriptCount;//when the scriptcount changes, rebuild menus

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
//integer COMMAND_SECOWNER = 501;
//integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
                            //str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

//5000 block is reserved for IM slaves

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
string g_sDeviceType="collar";
string g_sWearerName;

string GIVECARD = "Help";
string HELPCARD = ".help";
string CONTACT = "Contact";
string LICENSE="License";
key g_kWebLookup;
key g_kCurrentUser;

list g_lAppsButtons;

integer g_iLocked = FALSE;
integer g_bDetached = FALSE;
integer g_iHide ; // global hide
integer g_iNews=TRUE;

string g_sLockPrimName="Lock"; // Description for lock elements to recognize them //EB //SA: to be removed eventually (kept for compatibility)
string g_sOpenLockPrimName="OpenLock"; // Prim description of elements that should be shown when unlocked
string g_sClosedLockPrimName="ClosedLock"; // Prim description of elements that should be shown when locked
list g_lClosedLockElements; //to store the locks prim to hide or show //EB
list g_lOpenLockElements; //to store the locks prim to hide or show //EB

string g_sDefaultLockSound="2f0943ac-4981-0bb0-0b23-8f429b72cf8e";
string g_sDefaultUnlockSound="e6482ba6-eae1-4d1b-049e-4de13bbd0f5b";
string g_sLockSound="2f0943ac-4981-0bb0-0b23-8f429b72cf8e";
string g_sUnlockSound="e6482ba6-eae1-4d1b-049e-4de13bbd0f5b";

integer g_iAnimsMenu=FALSE;
integer g_iRlvMenu=FALSE;
integer g_iKidnapMenu=FALSE;
integer g_iResizer=FALSE;

integer g_iUpdateChan = -7483214;
integer g_iUpdateHandle;

key g_kUpdaterOrb;
integer g_iUpdateFromMenu;

string version_check_url = "https://raw.githubusercontent.com/VirtualDisgrace/Collar/whisper/LSL/~version";
key github_version_request;

string news_url = "https://raw.githubusercontent.com/VirtualDisgrace/Collar/whisper/LSL/~news";
key news_request;
string g_sLastNewsTime = "0";

integer g_iUpdateAuth;
integer g_iWillingUpdaters = 0;
integer g_iWillingVDUpdaters = 0;

integer g_iListenChan=1;
string g_sSafeWord="RED";
string g_sPrefix;
string g_sAuthError = "Access denied.";

//Option Menu variables
string DUMPCACHE = "Print";
//string PREFUSER = "☐ Personal";
//string PREFDESI = "☒ Personal"; // yes, I hate cutoff buttons
string STEALTH_OFF = "☐ Stealth"; // show the whole device
string STEALTH_ON = "☒ Stealth"; // hide the whole device
string LOADCARD="Load";
string REFRESH_MENU = "Fix";

string g_sScript;
integer STEALTH;

/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}*/

string AutoPrefix()
{
    return llToLower(llGetSubString(llKey2Name(llGetOwner()), 0,1));
}

integer compareVersions(string v1, string v2){ //compares two symantic version strings, true if v1 >= v2
    //Debug("compare "+v1+" with "+v2);
        
    integer v1Index=llSubStringIndex(v1,".");
    integer v2Index=llSubStringIndex(v2,".");
    
    //Debug("v1Index: "+(string)v1Index);
    //Debug("v2Index: "+(string)v2Index);
    
    integer v1a=(integer)llGetSubString(v1,0,v1Index);
    integer v2a=(integer)llGetSubString(v2,0,v2Index);
    
    if (v1a == v2a) {
        //Debug((string)v1a+" == "+(string)v2a);
        if (~v1Index || ~v2Index){
            string v1b;
            if (v1Index == -1 || v1Index==llStringLength(v1)) {
                //Debug("v1b empty");
                v1b="0";
            } else {
                v1b=llGetSubString(v1,v1Index+1,-1);
            }

            string v2b;
            if (v2Index == -1 || v2Index==llStringLength(v2)) {
                //Debug("v2b empty");
                v2b="0";
            } else {
                v2b=llGetSubString(v2,v2Index+1,-1);
            }

            return compareVersions(v1b,v2b);
        } else {
            //Debug("0 as nothing to compare");
            return FALSE;
        }
    }
    //Debug((string)(v1a > v2a));
    return v1a > v2a;
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) { //we've alread given a menu to this user.  overwrite their entry
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    } else { //we've not already given this user a menu. append to list
        g_lMenuIDs += [kID, kMenuID, sName];
    }
} 

/*Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}*/

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    string sDeviceName = llGetObjectName();
    llSetObjectName("");
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
    llSetObjectName(sDeviceName);
}

OptionsMenu(key kID, integer iAuth)
{
    string sPrompt = "\n\"" + DUMPCACHE + "\" current settings to chat.";
    sPrompt += "\n\"" +LOADCARD+"\" settings from backup card.";
    sPrompt += "\n\"Fix\" menus if buttons went missing.\n";
    sPrompt += "\nSelect Themes to customize looks.";
    list lButtons = [DUMPCACHE,LOADCARD,REFRESH_MENU,"Position","Rotation","Size"];
    if (STEALTH) {
        sPrompt +="\nUncheck " + STEALTH_ON + " to reveal your collar.";
        lButtons += [STEALTH_ON];
    } else {
        sPrompt +="\nCheck " + STEALTH_OFF + " to hide your collar.";
        lButtons += [STEALTH_OFF];
    }
    Dialog(kID, sPrompt, lButtons, [UPMENU, "Themes"], 0, iAuth, "Options");
}


AppsMenu(key kID, integer iAuth) {
    string sPrompt="\nBrowse apps, extras and custom features.";
    //Debug("max memory used: "+(string)llGetSPMaxMemory());
    Dialog(kID, sPrompt, g_lAppsButtons, [UPMENU], 0, iAuth, "Apps");
}

UpdateConfirmMenu() {
    Dialog(g_kWearer, "\n\nWARNING: You are using a stock OpenCollar Updater!\n\nThis will override your "+g_sDeviceType+" and migrate it to the public OpenCollar update channel. This process is irreversible.\n\nNote: Some App Installers use a similar mechanism to install plugins. In that case, please ignore this warning.\n\nDo you really want to continue?", ["Yes","Cancel"], ["BACK"], 0, COMMAND_WEARER, "UpdateConfirmMenu");
}

HelpMenu(key kID, integer iAuth) {
    string sPrompt="\nOpenCollar API: 3.9\n";
    sPrompt+="Disgraced Version "+g_sCollarVersion;
    sPrompt+="\n\nPrefix: "+g_sPrefix+"\nChannel: "+(string)g_iListenChan+"\nSafeword: "+g_sSafeWord;
    if(!g_iLatestVersion) sPrompt+="\n\nℹ: Update available!";
    //sPrompt+="\n\nwww.virtualdisgrace.com/collar";

    //Debug("max memory used: "+(string)llGetSPMaxMemory());
    list lUtility = [UPMENU];
    
    string sNewsButton="☐ News";
    if (g_iNews){
        sNewsButton="☒ News";
    }
    list lStaticButtons=[GIVECARD,CONTACT,LICENSE,sNewsButton,"Update"];
    Dialog(kID, sPrompt, lStaticButtons, lUtility, 0, iAuth, "Help/About");
}

MainMenu(key kID, integer iAuth) {
    //string sPrompt="\nOpenCollar Version "+g_sCollarVersion;
    //if(!g_iLatestVersion) sPrompt+="\nUpdate available!";
    string sPrompt = "\n Welcome to the main menu!\n Touch the heart for help:  [http://www.virtualdisgrace.com/collar ❤]";
    //Debug("max memory used: "+(string)llGetSPMaxMemory());
    list lStaticButtons=["Apps"];
    if (g_iAnimsMenu){
        lStaticButtons+="Animations";
    } else {
        lStaticButtons+=" ";
    }
    if (g_iKidnapMenu){
        lStaticButtons+="Kidnap";
    } else {
        lStaticButtons+=" ";
    }
    lStaticButtons+=["Leash"];
    if (g_iRlvMenu){
        lStaticButtons+="RLV";
    } else {
        lStaticButtons+=" ";
    }
    lStaticButtons+=["Access","Options","Help/About"];
    
    if (g_iLocked) Dialog(kID, sPrompt, "UNLOCK"+lStaticButtons, [], 0, iAuth, "Main");
    else Dialog(kID, sPrompt, "LOCK"+lStaticButtons, [], 0, iAuth, "Main");
}

integer UserCommand(integer iNum, string sStr, key kID, integer fromMenu) {
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llToLower(llList2String(lParams, 0));

    if (sCmd == "menu") {
        string sSubmenu = llToLower(llList2String(lParams, 1));
        if (sSubmenu == "main" || sSubmenu == "") MainMenu(kID, iNum);
        else if (sSubmenu == "apps" || sSubmenu=="addons") AppsMenu(kID, iNum);
        else if (sSubmenu == "help/about") HelpMenu(kID, iNum);
        else if (sSubmenu == "options") {
            if (iNum != COMMAND_OWNER && iNum != COMMAND_WEARER) {
                Notify(kID, g_sAuthError, FALSE);
                MainMenu(kID, iNum);
            } else OptionsMenu(kID, iNum);
        }
    } else if (sStr == "license") {
        if(llGetInventoryType(".license")==INVENTORY_NOTECARD) llGiveInventory(kID,".license");
        else Notify(kID,"License notecard missing from collar, sorry.", FALSE); 
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr == "help") {
        llGiveInventory(kID, HELPCARD);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sStr =="about" || sStr=="help/about") HelpMenu(kID,iNum);               
    else if (sStr == "addons" || sStr=="apps") AppsMenu(kID, iNum);
    else if (sStr == "options") {
        if (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER) OptionsMenu(kID, iNum);
        return TRUE;
    } else if (sCmd == "menuto") {
        key kAv = (key)llList2String(lParams, 1);
        if (llGetAgentSize(kAv) != ZERO_VECTOR) //if kAv is an avatar in this region
        {
            if(llGetOwnerKey(kID)==kAv) MainMenu(kID, iNum);    //if the request was sent by something owned by that agent, send a menu
            else  llMessageLinked(LINK_SET, COMMAND_NOAUTH, "menu", kAv);   //else send an auth request for the menu
        }
    } else if (sCmd == "lock" || (!g_iLocked && sStr == "togglelock")) {    //does anything use togglelock?  If not, it'd be nice to get rid of it
        //Debug("User command:"+sCmd);

        if (iNum == COMMAND_OWNER || kID == g_kWearer ) {   //primary owners and wearer can lock and unlock. no one else
            //inlined old "Lock()" function        
            g_iLocked = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "Global_locked=1", "");
            llMessageLinked(LINK_SET, RLV_CMD, "detach=n", "main");
            llPlaySound(g_sLockSound, 1.0);
            SetLockElementAlpha();//EB

            Notify(kID,g_sWearerName+"'s "+ g_sDeviceType + " has been locked.",TRUE);
        }
        else Notify(kID, g_sAuthError, FALSE);
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sStr == "runaway" || sCmd == "unlock" || (g_iLocked && sStr == "togglelock")) {
        if (iNum == COMMAND_OWNER)  {  //primary owners can lock and unlock. no one else
            //inlined old "Unlock()" function
            g_iLocked = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "Global_locked", "");
            llMessageLinked(LINK_SET, RLV_CMD, "detach=y", "main");
            llPlaySound(g_sUnlockSound, 1.0);
            SetLockElementAlpha(); //EB

            Notify(kID,g_sWearerName+"'s "+ g_sDeviceType + " has been unlocked.",TRUE);
        }
        else Notify(kID, g_sAuthError, FALSE);
        if (fromMenu) MainMenu(kID, iNum);
    } else if (sCmd == "fix") {
        if (kID == g_kWearer){
            RebuildMenu();
            Notify(kID, "Menus fixed!", FALSE);
        } else Notify(kID, g_sAuthError, FALSE);
    } else if (sCmd == "jailbreak") {
        if (kID == g_kWearer){
            if (llGetInventoryType(".tamago")==INVENTORY_NONE) {
                llOwnerSay("\n\nThe jailbreak sequence has already been performed on this collar.\n");
            } else if (llGetInventoryType(".tamago")==INVENTORY_OBJECT) {
                if (llGetAttached() == 0){
                    llRezObject(".tamago", llGetPos() + (<0.1, 0.0, -0.73> * llGetRot()), ZERO_VECTOR, llEuler2Rot(<0, 0, 270> * DEG_TO_RAD), 0);
                    llOwnerSay("\n\nYour collar is now jailbroken.\n");
                } else {
                    llOwnerSay("\n\nFor this to work you have to rez your collar on the ground.\n");
                }
            }
        }
    } else if (sCmd == "news"){
        if (kID == g_kWearer || iNum==COMMAND_OWNER){
            if (sStr=="news off"){
                g_iNews=FALSE;
                //notify news off
                Notify(kID,"\n\nOk! No more news from now on.\n\n*pout*\n",TRUE);
            } else if (sStr=="news on"){
                g_iNews=TRUE;
                //notify news on
                Notify(kID,"\n\nThanks!\n\nWe won't spam you, promise! <3\n",TRUE);
                g_sLastNewsTime="0";
                news_request = llHTTPRequest(news_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            } else {
                g_sLastNewsTime="0";
                news_request = llHTTPRequest(news_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            }
        } else Notify(kID,g_sAuthError,FALSE);
        if (fromMenu) HelpMenu(kID, iNum);
    } else if (sCmd == "update") {
//        if (llGetOwnerKey(kID) == g_kWearer) {
        if (kID == g_kWearer) {
            string sVersion = llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 1);
            g_iWillingUpdaters = 0;
            g_iWillingVDUpdaters = 0;
            g_kCurrentUser = kID;
            g_iUpdateAuth = iNum;
            Notify(kID,"Searching for nearby updater",FALSE);
            g_iUpdateHandle = llListen(g_iUpdateChan, "", "", "");
            g_iUpdateFromMenu=fromMenu;
            llWhisper(g_iUpdateChan, "UPDATE|" + sVersion);
            llSetTimerEvent(5.0); //set a timer to wait for responses from updaters
        } else {
            Notify(kID,"Only the wearer can update the " + g_sDeviceType + ".",FALSE);
            if (fromMenu) HelpMenu(kID, iNum);
        }
    } else if (sCmd == "version") {
        Notify(kID, "\n\nOpenCollar API: 3.9\nDisgraced Version " + g_sCollarVersion + "\n", FALSE);
    } else if (sCmd == "objectversion") {
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
    }    
    return TRUE;
}

NotifyOwners(string sMsg) {
    integer n;
    integer stop = llGetListLength(g_lOwners);
    for (n = 0; n < stop; n += 2) {
        Notify((key)llList2String(g_lOwners, n), sMsg, FALSE);
    }
}

string GetTimestamp() { // Return a string of the date and time
    string out;
    string DateUTC = llGetDate();
    if (llGetGMTclock() < 28800) { // that's 28800 seconds, a.k.a. 8 hours.
        list DateList = llParseString2List(DateUTC, ["-", "-"], []);
        integer year = llList2Integer(DateList, 0);
        integer month = llList2Integer(DateList, 1);
        integer day = llList2Integer(DateList, 2);
       // day = day - 1; //Remember, remember, the 0th of November!
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
    if (mins <10){
        out += "0";
    }
    out += (string)mins+":";

    integer secs=t % 60;
    if (secs < 10){
        out += "0";
    }
    out += (string)secs;
    
    return out;
}

BuildLockElementList()//EB
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    list lParams;

    // clear list just in case
    g_lOpenLockElements = [];
    g_lClosedLockElements = [];

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        // read description
        lParams=llParseString2List((string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_DESC]), ["~"], []);
        // check inf name is lock name
        if (llList2String(lParams, 0)==g_sLockPrimName || llList2String(lParams, 0)==g_sClosedLockPrimName)
        {
            // if so store the number of the prim
            g_lClosedLockElements += [n];
        }
        else if (llList2String(lParams, 0)==g_sOpenLockPrimName) 
        {
            // if so store the number of the prim
            g_lOpenLockElements += [n];
        }
    }
}

SetLockElementAlpha() //EB
{
    if (g_iHide) return ; // ***** if collar is hide, don't do anything 
    //loop through stored links, setting alpha if element type is lock
    integer n;
    //float fAlpha;
    //if (g_iLocked) fAlpha = 1.0; else fAlpha = 0.0; //Let's just use g_iLocked!
    integer iLinkElements = llGetListLength(g_lOpenLockElements);
    for (n = 0; n < iLinkElements; n++)
    {
        llSetLinkAlpha(llList2Integer(g_lOpenLockElements,n), !g_iLocked, ALL_SIDES);
    }
    iLinkElements = llGetListLength(g_lClosedLockElements);
    for (n = 0; n < iLinkElements; n++)
    {
        llSetLinkAlpha(llList2Integer(g_lClosedLockElements,n), g_iLocked, ALL_SIDES);
    }
}

RebuildMenu()
{
    //Debug("Rebuild Menu");
    g_iAnimsMenu=FALSE;
    g_iRlvMenu=FALSE;
    g_iKidnapMenu=FALSE;
    g_iResizer=FALSE;
    g_lAppsButtons = [] ;
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Main", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "AddOns", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Apps", "");
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Options", "");
}

init (){
    github_version_request = llHTTPRequest(version_check_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
    
    llSleep(1.0);//delay menu rebuild until other scripts are ready
    RebuildMenu();
}

StartUpdate(){
    integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(g_kUpdaterOrb, g_iUpdateChan, "ready|" + (string)pin );
}
default
{
    state_entry() {
        //llSetMemoryLimit(65539);  //2015-05-06 (12830 bytes free)
        g_kWearer = llGetOwner(); //updates in change event prompting script restart
        g_sWearerName = "secondlife:///app/agent/"+(string)g_kWearer+"/about";
        BuildLockElementList(); //updates in change event, doesn;t need a reset every time
        g_iScriptCount = llGetInventoryNumber(INVENTORY_SCRIPT);  //updates on change event;
        
       // llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "Global_locked", ""); //settings will send these on_rez, so no need to ask every rez
       // llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "auth_owner", ""); //settings will send these on_rez, so no need to ask every rez
        
        init(); //do stuf needed on_rez AND on script start
        
        g_sPrefix=AutoPrefix();
        
        //llScriptProfiler(PROFILE_SCRIPT_MEMORY);
        //Debug("Starting, max memory used: "+(string)llGetSPMaxMemory());
        //Debug("Starting");
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        // SA: delete this after transition is finished
        if (iNum == COMMAND_NOAUTH) return;
        // /SA
        else if (iNum == MENUNAME_RESPONSE) {
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
            else if (sStr=="Main|Kidnap") g_iKidnapMenu=TRUE;
            else if (sStr=="Options|Size/Position") g_iResizer=TRUE;
        } else if (iNum == MENUNAME_REMOVE) {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            string parent = llList2String(lParams, 0);
            string child = llList2String(lParams, 1);

            if (parent=="Apps" || parent=="AddOns") {
                integer gutiIndex = llListFindList(g_lAppsButtons, [child]);
                //only remove if it's there
                if (gutiIndex != -1) g_lAppsButtons = llDeleteSubList(g_lAppsButtons, gutiIndex, gutiIndex);
            }
        } else if (iNum == DIALOG_RESPONSE) {
            //Debug("Menu response");
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);               
                //process response
                if (sMenu=="Main"){
                    //Debug("Main menu response: '"+sMessage+"'");
                    if (sMessage == "LOCK" || sMessage== "UNLOCK"){
                        //Debug("doing usercommand for lock/unlock");
                        UserCommand(iAuth, sMessage, kAv, TRUE);
                    } else if (sMessage == "Help/About"){
                        HelpMenu(kAv, iAuth);
                    } else if (sMessage == "Apps"){
                        AppsMenu(kAv, iAuth);
                    } else {
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                } else if (sMenu=="Apps"){
                    //Debug("Apps menu response:"+sMessage);
                    if (sMessage == UPMENU) {
                        MainMenu(kAv, iAuth);
                    } else {
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                } else if (sMenu=="Help/About"){
                    //Debug("Help menu response");
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else if (sMessage == "Settings") {
                        llMessageLinked(LINK_SET, iAuth, "menu settings", kAv);
                    } else if (sMessage == GIVECARD) {
                        UserCommand(iAuth,"help",kAv, TRUE);
                    } else if (sMessage == LICENSE) {
                        UserCommand(iAuth,"license",kAv, TRUE);
                    } else if (sMessage == CONTACT) {
                        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/whisper/LSL/~contact", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
                        g_kCurrentUser = kAv;
                        HelpMenu(kAv, iAuth);
                    } else if (sMessage=="☐ News") {
                        //Debug("News on button");    
                        UserCommand(iAuth, "news on", kAv, TRUE);
                    } else if (sMessage=="☒ News") {
                        //Debug("News off button");    
                        UserCommand(iAuth, "news off", kAv, TRUE);
                    } else if (sMessage == "Update") UserCommand(iAuth,"update",kAv,TRUE);
                } else if (sMenu == "UpdateConfirmMenu"){
                        if (sMessage=="Cancel"){
                        Notify(kAv,"Override cancelled.",FALSE);
                        return;
                    } else if (sMessage=="Yes") StartUpdate();
                    else if (sMessage=="BACK"){
                        HelpMenu(kAv,iAuth);
                    }
                } else if (sMenu == "Options") {
                     if (sMessage == DUMPCACHE) llMessageLinked(LINK_SET, iAuth,"dump_cache",kAv);
                     else if (sMessage == LOADCARD) llMessageLinked(LINK_SET, iAuth,sMessage,kAv);
                     else if (sMessage == REFRESH_MENU) llMessageLinked(LINK_SET, iAuth,sMessage,kAv);
                     else if (sMessage == STEALTH_OFF) {
                         llMessageLinked(LINK_SET, iAuth,"hide",kAv);
                         STEALTH = TRUE;
                    } else if (sMessage == STEALTH_ON) {
                        llMessageLinked(LINK_SET, iAuth,"show",kAv);
                        STEALTH = FALSE;
                    } else if (sMessage == "Themes") {
                        llMessageLinked(LINK_THIS, iAuth, "menu Themes", kAv);
                        return;
                    } else if (sMessage == UPMENU) {
                        MainMenu(kAv, iAuth);
                        return;
                    } else if (sMessage == "Position" || sMessage == "Rotation" || sMessage == "Size") {
                        if (g_iResizer) llMessageLinked(LINK_THIS, iAuth, llToLower(sMessage), kAv);
                        else {
                            Notify(kAv,"You do not have the Resizer in your "+g_sDeviceType+" installed, please use an Updater to install it. If you think the script is already there, hit the \"Fix\" Button.", FALSE);
                            OptionsMenu(kAv,iAuth);
                        }
                        return;
                    }
                    OptionsMenu(kAv,iAuth);
                }
            }
        }
        else if (UserCommand(iNum, sStr, kID, FALSE)) return;
        else if ((iNum == LM_SETTING_RESPONSE || iNum == LM_SETTING_DELETE) 
                && llSubStringIndex(sStr, "Global_WearerName") == 0 ) {
            integer iInd = llSubStringIndex(sStr, "=");
            string sValue = llGetSubString(sStr, iInd + 1, -1);
            //We have a broadcasted change to g_sWearerName to work with
            if (iNum == LM_SETTING_RESPONSE) g_sWearerName = sValue;
            else {
                g_kWearer = llGetOwner();
                g_sWearerName = "secondlife:///app/agent/"+(string)g_kWearer+"/about";
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "Global_locked") {
                g_iLocked = (integer)sValue;
                SetLockElementAlpha(); //EB
            } else if (sToken == "Global_DeviceType") g_sDeviceType = sValue;
            else if (sToken == "Global_WearerName") g_sWearerName = sValue;
            else if (sToken == "auth_owner")
            {
                g_lOwners = llParseString2List(sValue, [","], []);
            }
            else if(sToken =="lock_locksound")
            {
                if(sValue=="default") g_sLockSound=g_sDefaultLockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sLockSound=sValue;
            }
            else if(sToken =="lock_unlocksound")
            {
                if(sValue=="default") g_sUnlockSound=g_sDefaultUnlockSound;
                else if((key)sValue!=NULL_KEY || llGetInventoryType(sValue)==INVENTORY_SOUND) g_sUnlockSound=sValue;
            }
            else if (sToken == "listener_channel") g_iListenChan = llList2Integer(llParseString2List(sValue,[","],[]),0);
            else if (sToken == "listener_safeword") g_sSafeWord = sValue;
            else if (sToken == "Global_prefix") g_sPrefix = sValue;
            else if (sToken == "Global_news") g_iNews = (integer)sValue;
            else if (sStr == "settings=sent") {
                if (g_iNews) news_request = llHTTPRequest(news_url, [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
        else if (iNum == LM_SETTING_SAVE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "auth_owner") g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken == "listener_channel") g_iListenChan = llList2Integer(llParseString2List(sValue,[","],[]),0);
            else if (sToken == "listener_safeword") g_sSafeWord = sValue;
            else if (sToken == "Global_prefix") g_sPrefix = sValue;
        }
        else if (iNum == RLV_REFRESH || iNum == RLV_CLEAR)
        {
            if (g_iLocked) llMessageLinked(LINK_SET, RLV_CMD, "detach=n", "main");
            else llMessageLinked(LINK_SET, RLV_CMD, "detach=y", "main");
        }
    }

    on_rez(integer iParam)
    {
        init();
    }
    
    changed(integer iChange)
    {
        if (iChange & CHANGED_INVENTORY)
        {
            if (llGetInventoryNumber(INVENTORY_SCRIPT) != g_iScriptCount) { //a script has been added or removed.  Reset to rebuild menu
                llSleep(0.5); //wait for new scripts to start up
                RebuildMenu(); //llResetScript();
            }
            g_iScriptCount=llGetInventoryNumber(INVENTORY_SCRIPT);
        }
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_COLOR) // ********************* 
        {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
            if (g_iHide != iNewHide){   //check there's a difference to avoid infinite loop
                g_iHide = iNewHide;
                SetLockElementAlpha(); // update hide elements 
            }
        }
        if (iChange & CHANGED_LINK) BuildLockElementList(); // need rebuils lockelements list
       /*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
       */
    }
    attach(key kID)
    {
        if (g_iLocked)
        {
            if(kID == NULL_KEY)
            {
                g_bDetached = TRUE;
                NotifyOwners(g_sWearerName + " has detached me while locked at " + GetTimestamp() + "!");
            }
            else if(g_bDetached)
            {
                NotifyOwners(g_sWearerName + " has re-atached me at " + GetTimestamp() + "!");
                g_bDetached = FALSE;
            }
        }
    }
    http_response(key id, integer status, list meta, string body){
        if (status == 200) { // be silent on failures.
            if (id == g_kWebLookup){
                Notify(g_kCurrentUser,body,FALSE);
            } else if (id == github_version_request) {  // strip the newline off the end of the text
                if (compareVersions(llStringTrim(body, STRING_TRIM),g_sCollarVersion)) g_iLatestVersion=FALSE;
                else g_iLatestVersion=TRUE;
            } else if (id == news_request) {  // We got a response back from the news page on Github.  See if it's new enough to report to the user.
                // The first line of a news item should be space delimited list with timestamp in format yyyymmdd.n as the last field, where n is the number of messages on this day
                string firstline = llList2String(llParseString2List(body, ["\n"], []), 0);
                list firstline_parts = llParseString2List(firstline, [" "], []);
                string this_news_time = llList2String(firstline_parts, -1);

                if (compareVersions(this_news_time,g_sLastNewsTime)) {
                    string news = "Beep: " + body;
                    Notify(llGetOwner(), news, FALSE);
                    g_sLastNewsTime = this_news_time;
                } 
            }
        }
    }
    
    listen(integer channel, string name, key id, string message) {
        if (llGetOwnerKey(id) == g_kWearer) {   //collar and updater have to have the same Owner else do nothing!
            list lTemp = llParseString2List(message, [","],[]);
            string sCommand = llList2String(lTemp, 0);
            if( message == "get ready" && g_iWillingVDUpdaters==0) {
                g_iWillingUpdaters++;
                g_kUpdaterOrb = id;
            } else if( message == "rosebud") {
                g_iWillingVDUpdaters++;
                g_kUpdaterOrb = id;
            } 
        }
    }

    timer() {
        llSetTimerEvent(0.0);
        llListenRemove(g_iUpdateHandle);

        if (!g_iWillingVDUpdaters && !g_iWillingUpdaters ) {   //if no updaters responded, get upgrader info from web and remenu
            g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/whisper/LSL/~update", [HTTP_METHOD, "GET", HTTP_VERBOSE_THROTTLE, FALSE], "");
            if (g_iUpdateFromMenu) HelpMenu(g_kCurrentUser,g_iUpdateAuth);
        } else if (g_iWillingVDUpdaters > 1  || (!g_iWillingVDUpdaters && g_iWillingUpdaters>1)) {    //if too many updaters, PANIC!
            Notify(g_kCurrentUser,"Multiple updaters were found nearby. Please remove all but one and try again.",FALSE);
        } else if (g_iWillingVDUpdaters) StartUpdate();  //update without warning, it's a friendly updater
        else UpdateConfirmMenu();  //perform update
    }
}