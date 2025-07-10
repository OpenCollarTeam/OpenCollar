/*
 oc_rlvextension
This file is part of OpenCollar.
Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue, Medea Destiny, Nirea Mercury et al.                           
Licensed under the GPLv2.  See LICENSE for full details. 

Medea Destiny -
    Sep 2021    -   Moved Exceptions menu into RLV as a main directory, and folded Menu Settings into
                    RLVSuite menu customize
                -   Refactored Exceptions setting with new functions to allow Exceptions to be applied
                    individually (setUserExceptions() function), replaced ApplyAllExceptions() function
                    with SetAllExes() that allows individual lists to be updated separately, and added
                    list updating. Result is much cleaner setting of exceptions, where exceptions that
                    have previously not been set don't get unset, and changing a single person on a 
                    list doesn't require the entire list to be cleared and reset. One line of correct
                    exceptions issued per user rather than one per exception per user, refreshed whenever
                    anything needs updating. Result at bootup with a test collar with 8 people on
                    owner/trusted list was 8 lines of RLV commands issued to viewer rather than up to 150
                    depending on timing of settings received. 
                -   Added list compare function that works.
                -   Changed setting save function to allow individual settings to be saved rather than 
                    all settings being saved when any are changed. 
                -   Changed MenuSetValue() function so that the correct values were given for the blur
                    function rather than sharing values with camdist settings, which gave incorrect user
                    feedback. Reformatted handling of dialog response to cast returned string rather 
                    than using list of conditionals.
                -   Added remenu timer for force sit menu when unsit used, to delay scan so that object
                    user is unsat from will show up in list rather than being ignored by scan if timing
                    is such that it's still considered the object sat on by sensor.
                -   Strict Sit changes: now adds own restriction to RLVsys baked set, which is removed
                    when unsat. This avoids collisions between strict sit and other unsit restrictions.
                    Restriction is now added immediately if user is sat on last force-sit object when
                    setting is added, so that sit followed by strict sit will in fact stop the user
                    standing.
                -   UNSIT now uses the RLV_CMD_OVERRIDE function if the commanding user has owner auth.
                    This means that a forced UNSIT by the owner is not stopped by a restriction to the
                    wearer. Owners shouldn't be restricted by restrictions, wearers should. Previously
                    The user would click unsit, be told it didn't work, have to navigate to
                    restrictions, remove the restriction, navigate back to UNSIT, unsit the collar
                    wearer, then navigate back to restrictions and reset it. This does that 
                    automatically for owners. 
                -   Added explanatory text to exceptions and force sit menus
                -   Renamed Refuse TP to Force TP to reflect what the button actually does.                  
    Dec 2021    -   Fixed filtering of unsit - > sit unsit for chat command and remote (issue #703 )
                -   Fix to disengaging strict sit when disabled via menu when already sitting.
    Feb 2022    -   SetAllExes triggered on RLV_REFRESH / RLV_ON was saving values, causing exception
                    settings to be restored to defaults if trigged before settings are received.
                    (fixes #740, #720, #719)
    Aug 2022    -   Fix auth filtering for changing exceptions. Issue #844 & #848
    Nov 2023    -   Added EXC_REFRESH link message capability to request all exceptions are refreshed.
                    This to fix real leash temporary exception removing permanent exception, but likely to
                    find other uses. This is less optimal than having a way to refresh individual exceptions,
                    or even better having this script handle multiple source exceptions the way rlv_sys handles
                    restrictions. However that's something to consider for 9.x where linkset data can reduce 
                    memory load, this one's already very tight. Issue #1008
                -   folded bool() function into checkbox() function with (iValue&1) and strReplace() into
                    MuffleText() to save memory

Krysten Minx -
    May 2022    -   Added check for valid UUID when setting custom exception

chew -
    Jun 2025    -   Reduced memory footprint: Refactor MuffleText, refactor Dialog, reduce redundant
                    list calls in MenuSetValue, shorten some language strings
*/
string g_sParentMenu = "RLV";
string g_sSubMenu1 = "Force Sit";
string g_sSubMenu2 = "Exceptions";
integer g_iStrictSit=FALSE; // Default - do not use strict mode

// MESSAGE MAP
// Authorization constants: a smaller value means a higher privilege
// level. Owner is 500, trusted would be 501, and so on. "Everyone" is
// the lowest built‑in rank at 504.
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;

// Link message constants used for communication with other scripts.
integer REBOOT = -1000;
integer LINK_CMD_DEBUG=1999;
integer LINK_CMD_RESTRICTIONS = -2576;
integer LINK_CMD_RESTDATA = -2577;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
integer RLV_CMD_OVERRIDE=6010; // one-shot (=force) command that will override restrictions. Only use if Auth is owner level
integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
integer EXC_REFRESH=6109; // send to request exceptions are refreshed.


// Dialog related link message channels
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;
integer DIALOG_SENSOR = -9003;
string UPMENU = "BACK";
//string ALL = "ALL";

integer g_bCanStand = TRUE;
integer g_bCanChat = FALSE;
integer g_bMuffle = FALSE;
integer g_iBlurAmount = 5; // default blur effect strength
float g_fMaxCamDist = 2.0; // default maximum camera distance
float g_fMinCamDist = 1.0; // default minimum camera distance

integer g_iRLV = FALSE;

key g_kWearer;

string g_sCameraBackMenu="menu manage"; //for allowing the camera settings menu to be in 2 places.


list g_lCheckboxes= ["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, (iValue>0))+" "+sLabel;
}

// lRLVEx is arranged as [Button Label, RLV command, bitmask]
// The bitmask values are powers of two so they can be OR'ed together to
// represent multiple exceptions in a single integer.
list lRLVEx = [
    "IM"            , "sendim"      , 1     ,
    "RcvIM"         , "recvim"      , 2     ,
    "RcvChat"       , "recvchat"    , 4     ,
    "RcvEmote"      , "recvemote"   , 8     ,
    "Lure"          , "tplure"      , 16    ,
    "Force TP"      , "accepttp"    , 32    ,
    "Start IM"      , "startim"     , 64
];

string g_sExTarget = "";

list g_lOwners = [];
list g_lTrusted = [];
list g_lTempOwners = [];

// Default exception masks for owners and trusted users. 127 grants all
// available exceptions (bits 0-6 set), while 95 excludes the "Force TP"
// bit so trusted users cannot auto-teleport the wearer by default.
integer g_iOwnerEx = 127;
integer g_iTrustedEx = 95;

//integer TIMEOUT_READY = 30497;
// TIMEOUT_REGISTER and TIMEOUT_FIRED are used with the helper timer
// script. 30498 registers a new timer and 30499 is sent back when the
// timer fires.
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;
//list g_lSettingsReqs = [];
integer g_iLocked=FALSE;

//list g_lStrangerEx = [];

// Returns TRUE if a and b contain the same items regardless of order.
integer samelist(list a, list b)
{
    if(a!=b) return FALSE;
    if(a==[]) return TRUE;
    return !llListFindList(llListSort(a,1,1),llListSort(b,1,1));
}

integer g_iMuffleListener; // Listen ID for muffle chat

// Pairs of characters used by MuffleText() to replace letters and garble
// speech. Each even index is replaced with the following character.
string g_sMuffleReplace =
    "phPHtkTKmnMNoeOEuoUOwoWObhBH";

string MuffleText(string sText)
{
    integer len = llStringLength(g_sMuffleReplace);
    integer i;
    for (i = 0; i < len; i += 2)
    {
        string from = llGetSubString(g_sMuffleReplace, i, i);
        string to = llGetSubString(g_sMuffleReplace, i+1, i+1);
        sText = llReplaceSubString( sText, from, to, 0 );
    }
    return sText;
}

SetMuffle(integer bEnable)
{
    if (bEnable && g_bCanChat) {
        // 3728192 is an arbitrary high chat channel used to redirect the
        // wearer's chat while muffled. It should not collide with normal chat.
        llMessageLinked(LINK_SET,RLV_CMD,"redirchat:3728192=add","Muffle");
        //llOwnerSay("@redirchat:3728192=add");
        g_iMuffleListener = llListen(3728192, "", llGetOwner(),"");
    } else {
        llMessageLinked(LINK_SET,RLV_CMD,"redirchat:3728192=rem","Muffle");
        //llOwnerSay("@redirchat:3728192=rem");
        llListenRemove(g_iMuffleListener);
    }
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    string kMenuID = sName + "~" + llGetScriptName();
    if (sName == "Restrictions~sensor" || sName == "find")
        // The sensor dialog expects range and arc. 20 meters and PI radians
        // match the typical llSensor parameters used elsewhere in OpenCollar.
        llMessageLinked(LINK_SET, DIALOG_SENSOR, (string)kID +"|"+sPrompt+"|0|``"+(string)(SCRIPTED|PASSIVE)+"`20`"+(string)PI+"`"+llDumpList2String(lUtilityButtons,"`")+"|"+llDumpList2String(lChoices,"`")+"|" + (string)iAuth, (key)kMenuID);
    else llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, (key)kMenuID);
}

MenuExceptions(key kID, integer iAuth) {
    string sPrompt = "\n[Exceptions]\n \nSet exceptions to the restrictions for RLV commands.\nOWNER and TRUSTED menus set the exceptions for all people with that authorization level, CUSTOM allows you to set different exceptions for specific people.";
    Dialog(kID, sPrompt, ["Owner","Trusted","Custom"], [UPMENU], 0, iAuth, "Exceptions~Main");
}
list g_lCustomExceptions = []; // Exception name, Exception UUID, integer bitmask

MenuCustomExceptionsSelect(key kID,integer iAuth){
    string sPrompt = "\n[Exceptions]\n\nSet custom exceptions here\n\nNOTE: Group exceptions can be set, but not all are meaningful applied to a group.";
    Dialog(kID, sPrompt, llList2ListStrided(g_lCustomExceptions, 0,-1,3),["+ ADD", "- REM", UPMENU], 0, iAuth, "Exceptions~Custom");
}

MenuCustomExceptionsRem(key kID, integer iAuth){
    string sPrompt = "\n[Exceptions]\n\nWhich custom exception should be removed?";
    Dialog(kID, sPrompt, llList2ListStrided(g_lCustomExceptions, 0, -1, 3), [UPMENU], 0, iAuth, "Exceptions~CustomRem");
}

string g_sTmpExceptionName;
MenuAddCustomExceptionName(key kID, integer iAuth){
    Dialog(kID,"Custom exception name?", [],[],0,iAuth,"Exceptions~AddCustomName");
}

key g_kTmpExceptionID;
MenuAddCustomExceptionID(key kID, integer iAuth){
    Dialog(kID, "Which UUID should this affect?", [],[],0,iAuth,"Exceptions~AddCustomID");
}

MenuSetExceptions(key kID, integer iAuth, string sTarget){
    list lButtons = [];
    integer iExMask;
    g_sExTarget = sTarget;
    
    if (sTarget == "Owner") iExMask = g_iOwnerEx;
    else if (sTarget == "Trusted") iExMask = g_iTrustedEx;
    else if(sTarget == "Custom"){
        iExMask = llList2Integer(g_lCustomExceptions, llListFindList(g_lCustomExceptions, [g_sTmpExceptionName])+2);
    }
    integer i;
    for (i=0; i<llGetListLength(lRLVEx);i=i+3) {
        lButtons += Checkbox((iExMask&llList2Integer(lRLVEx,i+2)), llList2String(lRLVEx,i));
    }
    string menutext="  --EXCEPTIONS--\nThese exclude ";
    if(sTarget=="Owner") menutext+="OWNERS";
    else if(sTarget=="Trusted") menutext+="TRUSTED PEOPLE";
    else menutext+="'"+g_sTmpExceptionName+"'";
    menutext+=" from being impacted by restrictions. Wearer can always:\n *IM - send them IMs\n *RcvIM - Receive their IMs\n *RcvChat - Hear their chat\n *RcvEmote - See their emotes\n *Lure - Receive their TP offers\n *StartIM - Start IM conversations with them\n *Force TP - When on, auto-accept their TP offers";
    
    Dialog(kID, menutext, lButtons, [UPMENU], 0, iAuth, "Exceptions~Set");
}

MenuForceSit(key kID, integer iAuth) {
    
    Dialog(kID, "\nSelect a place to force sit. Use [UNSIT] to stand up. \nSTRICT SIT prevents wearer from standing from a forced sit except via [UNSIT].\n", [Checkbox(g_iStrictSit, "Strict Sit"), UPMENU, "[UNSIT]"], [], 0, iAuth, "Restrictions~sensor");
}

MenuCamera(key kID, integer iAuth){
    Dialog(kID, "Camera Values", ["Min Dist", "Max Dist","Blur Amount"], [UPMENU], 0, iAuth, "Settings~Camera");
}

MenuChat(key kID, integer iAuth){
    string sBtn;
    sBtn = Checkbox(g_bMuffle, "Muffle");
    
    Dialog(kID, "MUFFLE garbles speech instead of blocking it when TALK restrictions are on.", [sBtn], [UPMENU], 0, iAuth, "Settings~Chat");
}

MenuSetValue(key kID, integer iAuth, string sValueName) {
    string sValue;
    list lLocalButtons=["+1.0", "+0.5","+0.1","-1.0","-0.5","-0.1"];
    if (sValueName == "MinCamDist") sValue = (string)g_fMinCamDist;
    else if (sValueName == "MaxCamDist") sValue = (string)g_fMaxCamDist;
    else if (sValueName == "BlurAmount")    {
        sValue = (string)g_iBlurAmount;
        lLocalButtons=["+blur","-blur"];
    }
    

    Dialog(kID, "Set "+sValueName+"\n \n"+sValueName+"="+sValue, lLocalButtons, [UPMENU], 0, iAuth, "Settings~"+sValueName);
}


integer g_iLastOwnerEx;
integer g_iLastTrustedEx;

integer EX_TYPE_OWNER=1;
integer EX_TYPE_TRUSTED=2;
integer EX_TYPE_CUSTOM=4;
// Synchronize the stored owner or trusted list with a new list of agents.
// Any IDs removed from the list have their exceptions cleared and any
// new IDs have the current mask applied.
UpdateList(list newlist, integer type) // type 1=owner, 2=trusted;
{
    list oldlist=g_lOwners;
    integer mask=g_iOwnerEx;
    if(type==EX_TYPE_TRUSTED) {
        oldlist=g_lTrusted;
        mask=g_iTrustedEx;
    }
    // Remove exceptions for avatars no longer on the list.
    integer i=llGetListLength(oldlist);
    while(i)    {
        --i;
        if(llListFindList(newlist,llList2List(oldlist,i,i))==-1)
            SetUserExes(llList2Key(oldlist,i),0,mask);
    }
    // Apply exceptions to any newly added avatars.
    i=llGetListLength(newlist);
    while(i)
    {
        --i;
        if(llListFindList(oldlist,llList2List(newlist,i,i))==-1)
            SetUserExes(llList2Key(newlist,i),mask,0);
    }
    if(type==EX_TYPE_OWNER)g_lOwners=newlist;
    else if(type==EX_TYPE_TRUSTED) g_lTrusted=newlist;
}
        
// Apply or remove individual exception bits for a specific avatar. The
// function compares the desired mask with the last applied mask and
// emits only the necessary @commands to update the viewer.
SetUserExes(key id, integer mask, integer lastmask)
{
    if(id==g_kWearer) return;
    list lExcepts=["sendim","recvim","recvchat","recvemote","tplure","accepttp","startim"];
    integer i;
    integer maskval;
    list out;
    // Cycle through the seven possible exception bits (0-6)
    while(i<7)
    {
        // Equivalent of (1 << i) to test each bit individually
        maskval=(integer)llPow(2,i);
        if((mask&maskval)==maskval && (lastmask&maskval)!=maskval) out+=llList2String(lExcepts,i)+":"+(string)id+"=add";
        else if((mask&maskval)!=maskval && (lastmask&maskval)==maskval) out+=llList2String(lExcepts,i)+":"+(string)id+"=rem";
        ++i;
    }
    if(out!=[]) llOwnerSay("@"+llDumpList2String(out,","));
}
       
// Apply or clear exceptions for every user in the specified lists. The
// 'type' parameter is a bitmask: 1 = owners, 2 = trusted, 4 = custom.
// When 'clearall' is TRUE all exceptions are removed, otherwise the
// current masks are pushed to the viewer. When 'send' is TRUE the new
// mask values are persisted to settings.
SetAllExes(integer clearall, integer type, integer send)
{
    integer i;
    integer end;
    string sAgent;
    if(type&EX_TYPE_OWNER) //Owners
    {
        if(send) Save(SAVE_OWNER);
        list lTemp=g_lOwners+g_lTempOwners;
        end=llGetListLength(lTemp);
        if(end==0) return;
        i=0;
        // Update every owner and temporary owner on record
        while(i<end)
        {
            if(clearall) SetUserExes(llList2Key(lTemp,i),0,g_iLastOwnerEx);
            else SetUserExes(llList2Key(lTemp,i),g_iOwnerEx,g_iLastOwnerEx);
            ++i;
        }
        if(clearall) g_iLastOwnerEx=0;
        else g_iLastOwnerEx=g_iOwnerEx;
    }
    if(type&EX_TYPE_TRUSTED) //trusted
    {
        if(send) Save(SAVE_TRUSTED);
        end=llGetListLength(g_lTrusted);
        if(end==0) return;
        i=0;
        // Process each trusted user in the list
        while(i<end)
        {
            if(clearall) SetUserExes(llList2Key(g_lTrusted,i),0,g_iLastTrustedEx);
            else SetUserExes(llList2Key(g_lTrusted,i),g_iTrustedEx,g_iLastTrustedEx);
            ++i;
        }
        if(clearall) g_iLastTrustedEx=0;
        else g_iLastTrustedEx=g_iTrustedEx;
    }
    if(type&EX_TYPE_CUSTOM)
    {
        if(send) Save(SAVE_CUSTOM);
        end=llGetListLength(g_lCustomExceptions);
        i=1;
        // Custom exceptions are stored as triplets [name, id, mask]
        while(i<end)
        {
            // Clear any previously applied exceptions. 127 represents all
            // possible bits so the whole mask is removed first.
            SetUserExes(llList2Key(g_lCustomExceptions,i),0,127);
            if(!clearall) SetUserExes(llList2Key(g_lCustomExceptions,i),llList2Integer(g_lCustomExceptions,i+1),0);
            i=i+3;
        }
    }
}

// Bitmask values used when persisting settings to the storage script.
integer SAVE_MINCAM=1;
integer SAVE_MAXCAM=2;
integer SAVE_BLURAMOUNT=4;
integer SAVE_MUFFLE=8;
integer SAVE_OWNER=16;
integer SAVE_TRUSTED=32;
integer SAVE_CUSTOM=64;
integer SAVE_ALL=127;

Save(integer iVal){ //iVal is bitmask of settings to save. 127 to save all.
    
   if(iVal&SAVE_MINCAM) llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_mincamdist="+(string)g_fMinCamDist, "");
   if(iVal&SAVE_MAXCAM) llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_maxcamdist="+(string)g_fMaxCamDist, "");
   if(iVal&SAVE_BLURAMOUNT) llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_bluramount="+(string)g_iBlurAmount, "");
   if(iVal&SAVE_MUFFLE) llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_muffle="+(string)g_bMuffle, "");
   if(iVal&SAVE_OWNER) llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_owner="+(string)g_iOwnerEx, "");
   if(iVal&SAVE_TRUSTED) llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_trusted="+(string)g_iTrustedEx, "");
   if(iVal&SAVE_CUSTOM) llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_custom="+llDumpList2String(g_lCustomExceptions, "^"),"");

}

// Tracks which auth level initiated the current force sit. The default
// value of 599 is higher than any real auth level so the first sit will
// always be accepted.
integer g_iLastSitAuth = 599;
UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
    sStr=llToLower(sStr);
    if(sStr=="unsit") sStr="sit unsit";
   // if ((llSubStringIndex(sStr,"exceptions") && sStr != "menu "+g_sSubMenu1) || (llSubStringIndex(sStr,"exceptions") && sStr != "menu "+g_sSubMenu2)) return;
    if (sStr=="sit" || sStr == "menu "+llToLower(g_sSubMenu1))
        MenuForceSit(kID, iNum);
    else if (sStr=="exceptions" || sStr == "menu "+llToLower(g_sSubMenu2))
        MenuExceptions(kID,iNum);
    else if (sStr=="menu managecamera" || sStr=="menu managecamera2") {
        g_sCameraBackMenu="menu customize";
        if(sStr=="menu managecamera2") g_sCameraBackMenu="menu category Camera";
        if (iNum < CMD_EVERYONE) MenuCamera(kID,iNum);
        else {
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS% to change camera settings", kID);
            llMessageLinked(LINK_SET, iNum,g_sCameraBackMenu, kID);
        }
    } else if( sStr=="menu managechat") {
        if (iNum < CMD_EVERYONE) MenuChat(kID,iNum);
        else {
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS% to change muffle settings", kID);
            llMessageLinked(LINK_SET, iNum, "menu [Manage]", kID);
        }
    }
    // Ignore stray commands that combine "sit" and "rlvex" keywords.
    else if(llSubStringIndex(sStr,"sit") && llSubStringIndex(sStr,"rlvex")) return;
    else {
        // Parse commands of the form "<type> <argument>" such as
        // "sit <uuid>" or "rlvex modify".
        list lCmd = llParseString2List(sStr, [" "], []);
        string sChangetype = llList2String(lCmd,0);
        string sChangekey = llList2String(lCmd,1);
        if (sChangetype == "sit") { // manual sit/unsit commands
            if ((sChangekey == "[unsit]" || sChangekey == "unsit")) {
                if(iNum> g_iLastSitAuth ) {
                    llMessageLinked(LINK_SET,NOTIFY,"0Cannot unsit from a sit forced by a higher auth level.",kID);
                    return;
                }
                if(g_iStrictSit){
                   llMessageLinked(LINK_SET,RLV_CMD,"unsit=y","strictsit");
                }
                // Pause briefly so the viewer registers the unsit before we
                // apply further commands.
                llSleep(1.5);
                if(iNum==CMD_OWNER) llMessageLinked(LINK_SET,RLV_CMD_OVERRIDE,"unsit~unsit",kID);
                else llMessageLinked(LINK_SET,RLV_CMD,"unsit=force","Macros");
                g_iLastSitAuth = 599;
            } else {
                if(iNum > g_iLastSitAuth){
                    llMessageLinked(LINK_SET, NOTIFY, "0Cannot override sit forced by a higher auth level.", kID);
                    return;
                }
                g_iLastSitAuth = iNum;
                if(g_iStrictSit){
                    llMessageLinked(LINK_SET,RLV_CMD,"unsit=n","strictsit");
                }
                llMessageLinked(LINK_SET,RLV_CMD,"sit:"+sChangekey+"=force","Macros");
            }
        } else if(sChangetype == "rlvex" && iNum == CMD_OWNER){
            // Owner-only console commands to modify exception masks
            if(sChangekey == "modify"){
                string sChangeArg1 = llToLower(llList2String(lCmd, 2));
                string sChangeArg2 = llToLower(llList2String(lCmd, 3));
                if(sChangeArg1 == "owner"){
                    g_iOwnerEx = (integer)sChangeArg2;
                    llMessageLinked(LINK_SET, NOTIFY, "0Owner exceptions updated", kID);
                    SetAllExes(FALSE,EX_TYPE_OWNER,TRUE);
                } else if(llGetSubString(sChangeArg1,0,4) == "trust"){
                    g_iTrustedEx = (integer)sChangeArg2;
                    llMessageLinked(LINK_SET, NOTIFY, "0Trusted exceptions updated", kID);
                    SetAllExes(FALSE,EX_TYPE_TRUSTED,TRUE);
                } else {
                    // modify custom exception. arg1 = name, arg2 = uuid, arg3 = bitmask. remove old if exists, replace with new. including updating the exception uuid
                    string sChangeArg3 = llToLower(llList2String(lCmd,4));
                    if(sChangeArg1==""||sChangeArg2==""||sChangeArg3==""){
                        llMessageLinked(LINK_SET, NOTIFY, "0Invalid argument count for custom exception", kID);
                        return;
                    }
                    integer iPosx=llListFindList(g_lCustomExceptions, [sChangeArg1]);
                    if(iPosx!=-1){
                        // process
                        g_lCustomExceptions = llDeleteSubList(g_lCustomExceptions, iPosx, iPosx+2);
                    }
                    llMessageLinked(LINK_SET, NOTIFY, "0Custom exceptions updated  ("+sChangeArg1+"): "+sChangeArg2+" = "+sChangeArg3, kID);
                    g_lCustomExceptions += [sChangeArg1, sChangeArg2, (integer)sChangeArg3];
                    SetAllExes(FALSE,EX_TYPE_CUSTOM,TRUE);
                }
            } else if(sChangekey == "listmasks"){
                // Output the numeric values of each exception bit
                integer ix=0;
                string sExceptionMasks;
                integer end = llGetListLength(lRLVEx);
                for(ix=0;ix<end;ix+=3){
                    sExceptionMasks += llList2String(lRLVEx,ix)+" = "+llList2String(lRLVEx,ix+2)+", ";
                }
                // list all possible bitmasks
                llMessageLinked(LINK_SET, NOTIFY, "0Exceptions use a bitmask. Allowed values: "+sExceptionMasks+". Add selected values together for the bitmask value. Max bitmask is 127.", kID);
            } else if(sChangekey == "help"){
                // Provide a short usage summary for the console command
                llMessageLinked(LINK_SET, NOTIFY, "0Commands: listmasks, modify, listcustom\n\nmodify takes 2-3 arguments.\nmodify owner [newBitmask]\nmodify trust [newMask]\nmodify [customExceptionName(no spaces)] [customExceptionUUID] [bitmask]", kID);
            } else if(sChangekey == "listcustom"){
                // Dump all currently defined custom exceptions
                integer ix=0;
                string sCustom;
                integer end = llGetListLength(g_lCustomExceptions);
                for(ix=0;ix<end;ix+=3){
                    sCustom  += llList2String(g_lCustomExceptions,ix)+": "+llList2String(g_lCustomExceptions, ix+1)+" = "+llList2String(g_lCustomExceptions,ix+2)+"\n";
                }
                
                llMessageLinked(LINK_SET, NOTIFY, "0Custom Exceptions:\n\n"+sCustom,kID);
            }
        }
    }
}

// Script management handshake values used during boot.
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        //llOwnerSay((string)llGetFreeMemory()+"/"+(string)llGetUsedMemory());
        // Inform the controller that this script is running
        // so menus can be registered.
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
    on_rez(integer iNum){
        llResetScript();
    }
    
    state_entry()
    {
        if(llGetStartParameter()!= 0)llResetScript();
        g_kWearer=llGetOwner();
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        // Primary event router handling commands, menu registrations and
        // dialog responses.
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu1,""); // Register menu "Force Sit"
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu2,""); // Register Exceptions Menu
        } else if(iNum == DIALOG_RESPONSE){
            // Response from a menu dialog. The menu name is stored in the
            // command UUID before the '~' character.
            integer iDelim = llSubStringIndex(kID, "~"+llGetScriptName());
            if(iDelim>0){
                string sMenu = llGetSubString(kID,0,iDelim-1);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                if(sMenu == "Exceptions~Main"){
                    if(sMsg == UPMENU)  llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else if (iAuth!=CMD_OWNER)
                    {
                        llMessageLinked(LINK_SET,NOTIFY,"0No access to change exceptions", kAv);
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                        return;
                    }
                    else if(sMsg == "Custom")MenuCustomExceptionsSelect(kAv,iAuth);
                    else MenuSetExceptions(kAv,iAuth,sMsg);
                } else if(sMenu == "Exceptions~Custom"){
                    if(sMsg == UPMENU) MenuExceptions(kAv,iAuth);
                    else if(sMsg == "+ ADD"){
                        MenuAddCustomExceptionName(kAv,iAuth);
                    } else if(sMsg == "- REM"){
                        MenuCustomExceptionsRem(kAv, iAuth);
                    } else {
                        // view this exception's data and permit editting
                        g_sTmpExceptionName = sMsg;
                        MenuSetExceptions(kAv, iAuth, "Custom");
                    }
                } else if(sMenu == "Exceptions~CustomRem"){
                    if(sMsg == UPMENU) MenuCustomExceptionsSelect(kAv, iAuth);
                    else{
                        // remove it
                        integer iPos = llListFindList(g_lCustomExceptions, [sMsg]);
                        SetAllExes(TRUE,EX_TYPE_CUSTOM,FALSE);
                        llSleep(0.5);
                        
                        g_lCustomExceptions = llDeleteSubList(g_lCustomExceptions, iPos,iPos+2);
                        MenuCustomExceptionsSelect(kAv,iAuth);
                        SetAllExes(FALSE,EX_TYPE_CUSTOM,TRUE);
                    }
                } else if(sMenu == "Exceptions~AddCustomName"){
                    g_sTmpExceptionName=sMsg;
                    MenuAddCustomExceptionID(kAv,iAuth);
                } else if(sMenu == "Exceptions~AddCustomID"){
                    if ((key)sMsg) { // true if valid UUID, false if not
                         g_kTmpExceptionID = (key)sMsg;
                         llMessageLinked(LINK_SET,NOTIFY,"0Adding exception..", kAv);
                         g_lCustomExceptions += [g_sTmpExceptionName,g_kTmpExceptionID,0];
                         Save(SAVE_CUSTOM);
                         MenuSetExceptions(kAv, iAuth, "Custom");
                    } else {
                         llMessageLinked(LINK_SET,NOTIFY,"0Invalid UUID "+sMsg, kAv);
                    }
                } else if (sMenu == "Exceptions~Set") {
                    if (sMsg == UPMENU) MenuExceptions(kAv,iAuth);
                    else {
                        sMsg = llGetSubString( sMsg, llStringLength(llList2String(g_lCheckboxes,0))+1, -1);
                        integer iIndex = llListFindList(lRLVEx,[sMsg]);
                        if (iIndex > -1) {
                            integer iTarget;
                            if (g_sExTarget == "Owner") {
                                iTarget=EX_TYPE_OWNER;
                                if (g_iOwnerEx & llList2Integer(lRLVEx,iIndex+2)) g_iOwnerEx = g_iOwnerEx ^ llList2Integer(lRLVEx,iIndex+2);
                                else g_iOwnerEx = g_iOwnerEx | llList2Integer(lRLVEx,iIndex+2);
                            } else if (g_sExTarget == "Trusted") {
                                iTarget=EX_TYPE_TRUSTED;
                                if (g_iTrustedEx & llList2Integer(lRLVEx,iIndex+2)) g_iTrustedEx = g_iTrustedEx ^ llList2Integer(lRLVEx,iIndex+2);
                                else g_iTrustedEx = g_iTrustedEx | llList2Integer(lRLVEx,iIndex+2);
                            } else if(g_sExTarget == "Custom"){
                                iTarget=EX_TYPE_CUSTOM;
                                integer iPos=llListFindList(g_lCustomExceptions, [g_sTmpExceptionName])+2;
                                integer iTmpBits = llList2Integer(g_lCustomExceptions, iPos);
                                // do stuff
                                if(iTmpBits & llList2Integer(lRLVEx,iIndex+2)) iTmpBits = iTmpBits ^ llList2Integer(lRLVEx,iIndex+2);
                                else iTmpBits = iTmpBits | llList2Integer(lRLVEx,iIndex+2);
                                
                                g_lCustomExceptions = llListReplaceList(g_lCustomExceptions, [iTmpBits], iPos, iPos);
                            }
                            SetAllExes(FALSE,iTarget,TRUE);
                        }
                        MenuSetExceptions(kAv, iAuth, g_sExTarget);
                    }
                } else if (sMenu == "Force Sit") MenuForceSit(kAv,iAuth);
                else if (sMenu == "Restrictions~sensor") {
                    if(sMsg == Checkbox(g_iStrictSit,"Strict Sit")){
                        if(iAuth != CMD_OWNER) {
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to change Strict Sit", kAv);
                            MenuForceSit(kAv,iAuth);
                        } else{
                            g_iStrictSit=1-g_iStrictSit;
                            if(!g_iStrictSit) llMessageLinked(LINK_SET,RLV_CMD,"unsit=y","strictsit");
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvext_strict="+(string)g_iStrictSit, "");
                            MenuForceSit(kAv,iAuth);
                        }
                        return;
                    }
                    
                    if (sMsg == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else{
                        UserCommand(iAuth,"sit "+sMsg,kAv);
                        
                        // Time-delayed remenu because the sensor misses the object immediately
                        // after an unsit. Reopen the menu after 3 seconds so the sensor has
                        // time to detect the newly stood object.
                        llMessageLinked(LINK_SET,TIMEOUT_REGISTER,"3","remenu_forcesit:"+(string)kAv+":"+(string)iAuth);
                    }
                } else if (sMenu == "Settings~Camera") {
                    if (sMsg == UPMENU)llMessageLinked(LINK_SET, iAuth,g_sCameraBackMenu, kAv);
                    else if (sMsg == "Min Dist") MenuSetValue(kAv, iAuth, "MinCamDist");
                    else if (sMsg == "Max Dist") MenuSetValue(kAv, iAuth, "MaxCamDist");
                    else if (sMsg == "Blur Amount") MenuSetValue(kAv, iAuth, "BlurAmount"); 
                } else if (sMenu == "Settings~Chat") {
                    if (sMsg == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu customize", kAv);
                    else {
                        sMsg = llGetSubString(sMsg,2,-1);
                        if (sMsg == "Muffle") {
                            g_bMuffle = !g_bMuffle;
                            SetMuffle(g_bMuffle);
                            Save(SAVE_MUFFLE);
                        }
                        MenuChat(kAv,iAuth);
                    }
                } else {
                    // Generic Settings~<option> menus all share the same handler
                    list lMenu = llParseString2List(sMenu, ["~"],[]);
                    if (llList2String(lMenu,0) == "Settings") {
                        if (sMsg == UPMENU) MenuCamera(kAv, iAuth);
                        else {
                            if (llList2String(lMenu,1) == "MinCamDist") {
                                g_fMinCamDist+=(float)sMsg;/*
                                if (sMsg == "+1.0") g_fMinCamDist += 1.0;
                                else if (sMsg == "+0.5") g_fMinCamDist += 0.5;
                                else if (sMsg == "+0.1") g_fMinCamDist += 0.1;
                                else if (sMsg == "-1.0") g_fMinCamDist -= 1.0;
                                else if (sMsg == "-0.5") g_fMinCamDist -= 0.5;
                                else if (sMsg == "-0.1") g_fMinCamDist -= 0.1;*/
                                // Prevent values that break the camera. The
                                // viewer refuses anything below 0.1 meters.
                                if (g_fMinCamDist < 0.1) g_fMinCamDist = 0.1;
                                else if (g_fMinCamDist > g_fMaxCamDist) g_fMinCamDist = g_fMaxCamDist;
                                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,llList2String(lMenu,1)+"="+(string)g_fMinCamDist,kAv);
                                Save(SAVE_MINCAM);
                            } else if (llList2String(lMenu,1) == "MaxCamDist") {
                                g_fMaxCamDist+=(float)sMsg;/*
                                if (sMsg == "+1.0") g_fMaxCamDist += 1.0;
                                else if (sMsg == "+0.5") g_fMaxCamDist += 0.5;
                                else if (sMsg == "+0.1") g_fMaxCamDist += 0.1;
                                else if (sMsg == "-1.0") g_fMaxCamDist -= 1.0;
                                else if (sMsg == "-0.5") g_fMaxCamDist -= 0.5;
                                else if (sMsg == "-0.1") g_fMaxCamDist -= 0.1;*/
                                if (g_fMaxCamDist < g_fMinCamDist) g_fMaxCamDist = g_fMinCamDist;
                                // Cap maximum distance to 20m which matches
                                // the viewer's hard limit.
                                else if (g_fMaxCamDist > 20.0) g_fMaxCamDist = 20.0;
                                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,llList2String(lMenu,1)+"="+(string)g_fMaxCamDist,kAv);
                                Save(SAVE_MAXCAM);
                            } else if (llList2String(lMenu,1) == "BlurAmount") {
                                if (sMsg == "+blur") g_iBlurAmount += 1;
                                else if (sMsg == "-blur") g_iBlurAmount -= 1;
                                // Blur amount is constrained to a reasonable
                                // range for hardware performance.
                                if (g_iBlurAmount < 2) g_iBlurAmount = 2;
                                else if (g_iBlurAmount > 30) g_iBlurAmount = 30;
                                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,llList2String(lMenu,1)+"="+(string)g_iBlurAmount,kAv);
                                Save(SAVE_BLURAMOUNT);
                            }
                            MenuSetValue(kAv,iAuth,llList2String(lMenu,1));
                        }
                    }
                }
            }
        }else if(iNum == LM_SETTING_EMPTY){
            
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
        } else if(iNum == LM_SETTING_RESPONSE){
        // Detect here the Settings
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            
            
            //integer ind = llListFindList(g_lSettingsReqs, [sToken]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            
            if (sToken == "rlvext_mincamdist") {
                g_fMinCamDist = (float)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MinCamDist="+(string)g_fMinCamDist,kID);
            } else if(sToken == "rlvext_strict"){
                g_iStrictSit=(integer)sValue;
            } else if (sToken == "rlvext_maxcamdist") {
                g_fMaxCamDist = (float)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MaxCamDist="+(string)g_fMaxCamDist,kID);
            } else if (sToken == "rlvext_bluramount") {
                g_iBlurAmount = (integer)sValue;
                llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"BlurAmount="+(string)g_iBlurAmount,kID);
            } else if (sToken == "rlvext_muffle") { 
                g_bMuffle = (integer)sValue;
                SetMuffle(g_bMuffle);
            } else if (sToken == "rlvext_owner") {
                if(g_iOwnerEx == (integer)sValue)return;
                g_iOwnerEx = (integer) sValue;
                
                if(g_iRLV==TRUE && g_lOwners!=[])
                {
                    SetAllExes(FALSE,EX_TYPE_OWNER,FALSE);
                }
            } else if (sToken == "rlvext_trusted") {
                if(g_iTrustedEx==(integer)sValue)return;
                g_iTrustedEx = (integer) sValue;
                
                if(g_iRLV==TRUE && g_lTrusted!=[])
                {
                    SetAllExes(FALSE,EX_TYPE_TRUSTED,FALSE);
                   
                    } 
                
            } else if(sToken == "rlvext_custom"){
                list lCustomExceptions = llParseString2List(sValue,["^"],[]);
                if(samelist(g_lCustomExceptions,lCustomExceptions)) return;
                if(g_iRLV){
                    if(g_lCustomExceptions!=[]) SetAllExes(TRUE,EX_TYPE_CUSTOM,FALSE);
                    g_lCustomExceptions = lCustomExceptions;
                    SetAllExes(FALSE,EX_TYPE_CUSTOM,FALSE);
                    }
                    else g_lCustomExceptions = lCustomExceptions;
            }else if (llGetSubString(sToken, 0, i) == "auth_") {
                if (sToken == "auth_owner") {
                    list lOwners = llParseString2List(sValue, [","], []);
                    if(samelist(lOwners,g_lOwners))return;
                    if (g_iRLV==TRUE && g_iOwnerEx!=0){
                        if(g_lOwners!=[]) UpdateList(lOwners,EX_TYPE_OWNER);
                        else {
                            g_lOwners=lOwners;
                            SetAllExes(FALSE,EX_TYPE_OWNER,FALSE);
                        }
                    }
                    else { 
                        g_lOwners=lOwners;
                    }
                } else if (sToken == "auth_trust") {
                    list lTrusted = llParseString2List(sValue, [","], []);
                    if(samelist(lTrusted,g_lTrusted))return;
                    if (g_iRLV==TRUE && g_iTrustedEx!=0){
                        if(g_lTrusted!=[])UpdateList(lTrusted,EX_TYPE_TRUSTED);
                        else {
                            g_lTrusted=lTrusted;
                            SetAllExes(FALSE,EX_TYPE_TRUSTED,FALSE);
                        }
                    }
                    else {
                        g_lTrusted=lTrusted;
                    }
                } else if (sToken == "auth_tempowner") {
                    list lTempOwners = llParseString2List(sValue, [","], []);
                    if(samelist(g_lTempOwners,lTempOwners))return;
                    if (g_iRLV==TRUE &&g_iOwnerEx!=0){
                        SetAllExes(TRUE,EX_TYPE_OWNER,FALSE);
                        g_lTempOwners=lTempOwners;
                        SetAllExes(FALSE,EX_TYPE_OWNER,FALSE);
                        }
                    else g_lTempOwners=lTempOwners;
                }
            } else if (sToken == "settings" && sValue == "send") Save(SAVE_ALL);
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "checkboxes"){
                    g_lCheckboxes = llCSV2List(llList2String(lSettings,2));
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);

            if(sStr == "global_locked") g_iLocked=FALSE;
            else if (sStr == "auth_owner") {
                SetAllExes(TRUE,EX_TYPE_OWNER,FALSE);
                g_lOwners = []; 
            } else if (sStr == "auth_trust") {
                SetAllExes(TRUE,EX_TYPE_TRUSTED,FALSE);
                g_lTrusted = []; 
            } else if (sStr == "auth_tempowner") {
                SetAllExes(TRUE,EX_TYPE_OWNER,FALSE);
                g_lTempOwners = []; 
            }
        } else if(iNum == -99999){
            if(sStr == "update_active")llResetScript();
        }else if (iNum == RLV_OFF){
            //ApplyAllExceptions(TRUE,TRUE,7,TRUE);
            SetAllExes(TRUE,EX_TYPE_OWNER|EX_TYPE_TRUSTED|EX_TYPE_CUSTOM,FALSE);
            g_iRLV = FALSE;
        } else if(iNum==EXC_REFRESH) {
            SetAllExes(TRUE,EX_TYPE_OWNER|EX_TYPE_TRUSTED|EX_TYPE_CUSTOM,FALSE);
            llSleep(1);
            SetAllExes(FALSE,EX_TYPE_OWNER|EX_TYPE_TRUSTED|EX_TYPE_CUSTOM,FALSE);
        } else if (iNum == RLV_REFRESH || iNum == RLV_ON) {
            g_iRLV = TRUE;
            SetAllExes(FALSE,EX_TYPE_OWNER|EX_TYPE_TRUSTED|EX_TYPE_CUSTOM,FALSE);
            SetMuffle(g_bMuffle);
            llSleep(1);
            llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MinCamDist="+(string)g_fMinCamDist,kID);
            llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"MaxCamDist="+(string)g_fMaxCamDist,kID);
            llMessageLinked(LINK_SET,LINK_CMD_RESTDATA,"BlurAmount="+(string)g_iBlurAmount,kID);
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        } else if(iNum == LINK_CMD_DEBUG){
            /// This will be changed to handle information differently..
            // TODO
        } else if (iNum == LINK_CMD_RESTRICTIONS) {
            list lCMD = llParseString2List(sStr,["="],[]);
            if (llList2String(lCMD,0) == "unsit" && llList2Integer(lCMD,2) < 0) g_bCanStand = llList2Integer(lCMD,1);
            if (llList2String(lCMD,0) == "sendchat" && llList2Integer(lCMD,2) < 0) {
                g_bCanChat = llList2Integer(lCMD,1);
                SetMuffle(g_bMuffle);
            }
        } else if (iNum == TIMEOUT_FIRED) {
            // Timer events from the helper script. Currently used to
            // re-open the force sit menu after an unsit.
            list to=llParseString2List(sStr,[":"],[]);
            if(llList2String(to,0)=="remenu_forcesit"){
                MenuForceSit((key)llList2String(to,1), (integer)llList2String(to,2));
            }
        }
    }
    
    listen(integer iChan, string sName, key kID, string sMsg)
    {
        // Listen on the redirected chat channel to output muffled speech.
        // The object temporarily takes the wearer's name so the chat
        // appears to originate from them.
        if (iChan == 3728192 && kID == llGetOwner()){
            string sObjectName = llGetObjectName();
            llSetObjectName(llKey2Name(llGetOwner()));
            llSay(0,MuffleText(sMsg));
            llSetObjectName(sObjectName);
        }
    }

}
