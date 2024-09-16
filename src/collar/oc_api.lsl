
/*
This file is a part of OpenCollar.
Copyright ©2021
: Contributors :
Aria (Tashia Redrose)
    *June 2020       -       Created oc_api
      * This implements some auth features, and acts as a API Bridge for addons and plugins
Felkami (Caraway Ohmai)
    *Dec 2020   -   Fix: 457Switched optin from searching by string to list
Medea (Medea Destiny)
    *June 2021  -   Fix issue #566  setgroup not clearing properly, 
                -   Fix issue #562, #381, #495 allow owners to permit wearers to set trusted/block
                -   Fix issue #579 Add interface channel to DoListeners() function so Highlander works again
                -   Issue #579 Restored menuto function to interface channel for backwards compatibility
                -   Issue #579 Added control of channel 0 listening via settings menu
                -   Fix issue 585 give wearer accept/deny dialog to confirm runaway disable setting
    *Aug 2022   -   Issue #843 & #774 fixes to check g_kOwner rather than CMD_WEARER. This fixes runaway
                    menu for wearers set as trusted (fix typo in menu too). Also wearer adding to trusted/
                    blacklist when permitted when also trusted (issue #849)
                -   Fixed instance where interface channel is 0, also streamlined function, fix issue #819 
                -   Prefix reset now works, and notifications sent when changing prefix.
   *Nov 2023    -   Reformatted chat command handling for efficiency. Chat commands no longer sent as 
                    CMD_ZERO for authing as this script handles
                    auth so we can auth locally to save a link_message round trip on every chat command. 
                -   Restored object command handling as per v7.x and previous, using interface channel
                    rather than HUDchannel as there seems no reason to duplicate and hudchannel stuff hasn't
                    worked for a few years anyway. Added remote auth function -
                    llSay(g_iInterfaceChannel,"checkauth 1111"); will return "AuthReply|(wearerkey)|(auth level)"
                    on channel 1111, reporting the auth level of the object owner. Commands can be prefixed with
                    "authas:(userkey)=", which will use the LOWER auth level between object owner and userkey. 
                    Commmand format is targetkey:chat command. Examples: 
                    "authas:(userkey)=(targetkey):kneel" - will issue kneel command if (userkey) and object owner
                    both have valid auth
                    "(targetkey):sit (sittarget key)" - sit wearer on (sittarget key) if object owner has valid
                     auth
                -   menuto cleanup requires menuto target to be in sim AND be the owner of the issuing command
                -   Set g_iStartup to TRUE in active state on_rez event to restore "owned by" message #906  
     *May 2024   -  Implemented wearerlockout for timer app and future rework of capture app, as well
                    as future options for self-bondage, excluding wearer from all collar access etc. This uses
                    Linkset data, the token being 'auth_WearerLockout". Any script that initiates a lockout
                    should add its script name (excluding the "oc_" part to a comma-separated list, and remove
                    itself from that list when removing, so that multiple scripts can apply this without interfering
                    with each other. 
                    When llLinksetDataRead("auth_WearerLocout") does not return an empty string,
                    the only thing the wearer can do is safeword, which will deactivate it.
                    Any attempt to trigger a menu/command will send the AUTH_WEARERLOCKOUT
                    Link message. Any script setting a wearer lockout should respond to this with a status
                    update.  
     *Sept 2024  -  Added rejection of interface channel commands from temp-attached objects
                           
Yosty7b3        
    *Oct 2021   -   Remove unused StrideOfList() function.

    *Feb 2022   -   Only reset when needed (part of boot speedup project).    
    
Nikki Lacrima
    *Aug 2023   -  Clear group on runaway issue #935  
    *Nov 2023   -   Only wearer can initiate and confirm runaway, add link message "runaway_confirmed" and 
                    remove the g_iRunawayMode. 
                -   Add "#" prefix wildcard, issue #897
                -   implemented Yosty7b3's menu streamlining, see pr#963 


et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/
list g_lOwner;
list g_lTrust;
list g_lBlock;

key g_kTempOwner;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;
integer g_iMode;
string g_sSafeword = "RED";
integer g_iSafewordDisable=FALSE;
integer ACTION_ADD = 1;
integer ACTION_REM = 2;
integer ACTION_SCANNER = 4;
integer ACTION_OWNER = 8;
integer ACTION_TRUST = 16;
integer ACTION_BLOCK = 32;

//integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

//integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
//MESSAGE MAP
integer AUTH_REQUEST = 600;
integer AUTH_REPLY=601;
integer AUTH_WEARERLOCKOUT=602;

integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_BLOCKED = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;

string Auth2Str(integer iAuth){
    if(iAuth == CMD_OWNER)return "Owner";
    else if(iAuth == CMD_TRUSTED)return "Trusted";
    else if(iAuth == CMD_GROUP)return "Group";
    else if(iAuth == CMD_WEARER)return "Wearer";
    else if(iAuth == CMD_EVERYONE)return "Public";
    else if(iAuth == CMD_BLOCKED)return "Blocked";
    else if(iAuth == CMD_NOACCESS)return "No Access";
    else return "Unknown = "+(string)iAuth;
}

integer REBOOT = -1000;
string UPMENU = "BACK";
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, sName+"~"+llGetScriptName() );
}
string SLURL(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}
key g_kGroup=NULL_KEY;
key g_kWearer;
key g_kTry;
integer g_iCurrentAuth;
key g_kMenuUser;


integer CalcAuth(key kID) {
    if(llLinksetDataRead("auth_WearerLockout")!="" && kID==g_kWearer) return CMD_NOACCESS;       
    string sID = (string)kID;
    // First check
    if(llGetListLength(g_lOwner) == 0 && kID==g_kWearer && llListFindList(g_lBlock,[sID])==-1)
        return CMD_OWNER;
    else{
        if(llListFindList(g_lBlock,[sID])!=-1)return CMD_BLOCKED;
        if(llListFindList(g_lOwner, [sID])!=-1)return CMD_OWNER;
        if(llListFindList(g_lTrust,[sID])!=-1)return CMD_TRUSTED;
        if(g_kTempOwner == kID) return CMD_TRUSTED;
        if(kID==g_kWearer)return CMD_WEARER;

        // group access and public access only apply to nearby avs/objects.
        if(in_range(kID)){
            if(g_kGroup!=NULL_KEY) {
                if(llSameGroup(kID))return CMD_GROUP;
            }
        
            if(g_iPublic) {
              return CMD_EVERYONE;
            }
        }
    }
    
    return CMD_NOACCESS;
}

integer NOTIFY = 1002;
integer NOTIFY_OWNERS=1003;
integer g_iPublic;
string g_sPrefix;
integer g_iChannel=1;
integer g_iListenPublic=TRUE;

PrintAccess(key kID){
    string sFinal = "\n \nAccess List:\nOwners:";
    integer i=0;
    integer end = llGetListLength(g_lOwner);
    for(i=0;i<end;i++){
        sFinal += "\n   "+SLURL(llList2String(g_lOwner,i));
    }
    end=llGetListLength(g_lTrust);
    sFinal+="\nTrusted:";
    for(i=0;i<end;i++){
        sFinal+="\n   "+SLURL(llList2String(g_lTrust,i));
    }
    end = llGetListLength(g_lBlock);
    sFinal += "\nBlock:";
    for(i=0;i<end;i++){
        sFinal += "\n   "+SLURL(llList2String(g_lBlock,i));
    }
    sFinal+="\n";
    if(llGetListLength(g_lOwner)==0 || llListFindList(g_lOwner, [(string)g_kWearer])!=-1)sFinal+="\n* Wearer is unowned or owns themselves.\nThe wearer has owner access";
    
    sFinal += "\nPublic: "+tf(g_iPublic);
    if(g_kGroup != NULL_KEY) sFinal+="\nGroup: secondlife:///app/group/"+(string)g_kGroup+"/about";
    
    if(!g_iRunaway)sFinal += "\n\n* RUNAWAY IS DISABLED *";
    llMessageLinked(LINK_SET,NOTIFY, "0"+sFinal,kID);
    //llSay(0, sFinal);
}

integer g_iListener;
integer g_iChatListener;

DoListeners(){
    if (g_iListener) llListenRemove(g_iListener);
    if (g_iChatListener) llListenRemove(g_iChatListener);
    g_iListener = llListen(g_iChannel, "","","");
    if (g_iListenPublic) g_iChatListener = llListen(0,"","","");
}

integer g_iRunaway=TRUE;
key g_kDenyRunawayRequester;

RunawayMenu(key kID, integer iAuth){
    if(iAuth == CMD_OWNER || ( (kID == g_kWearer) && g_iRunaway ) ){
        string sPrompt;
        list lButtons = [];

        if (kID == g_kWearer){
            sPrompt += "[Runaway]\n\nAre you sure you want to runaway from all owners?\n\n* This action will reset your owners list, trusted list, and your blocked avatars list.";
            lButtons += ["Yes", "No"];
        }
        if(iAuth == CMD_OWNER){
            sPrompt+="\n\nAs the owner you have the ability to disable or enable runaway.";
            if(g_iRunaway)lButtons += ["Disable"];
            else lButtons += ["Enable"];
        }
        else if (kID == g_kWearer) {
            sPrompt += "\n\nAs the wearer, you can choose to disable your ability to runaway, this action cannot be reversed by you";
            lButtons += ["Disable"];
        }
        Dialog(kID, sPrompt, lButtons, [], 0, iAuth, "RunawayMenu");
    } else {
        llMessageLinked(LINK_SET,NOTIFY,"0%NOACCESS% to runaway, or the runaway settings menu", kID);
    }
}

WearerConfirmListUpdate(key kID, string sReason)
{
    //key g_kAdder = g_kMenuUser;
    //g_kMenuUser=kID;
    // This should only be triggered if the wearer is being affected by a sensitive action
    Dialog(g_kWearer, "\n[Access]\n\nsecondlife:///app/agent/"+(string)kID+"/about wants change your access level.\n\nChange that will occur: "+sReason+"\n\nYou may grant or deny this action.", [], ["Allow", "Disallow"], 0, CMD_WEARER, "WearerConfirmation");
}
integer g_iAllowWearerSetTrusted=FALSE;
integer g_iGrantedConsent=FALSE;
UpdateLists(key kID, key kIssuer){
    //llOwnerSay(llDumpList2String([kID, kIssuer, g_kMenuUser, g_iMode, g_iGrantedConsent], ", "));
    integer iMode = g_iMode;
    if(iMode&ACTION_ADD){
        if(iMode&ACTION_OWNER){
            if(llListFindList(g_lOwner, [(string)kID])==-1){
                g_lOwner+=kID;
                llMessageLinked(LINK_SET, NOTIFY, "1"+SLURL(kID)+" has been added as owner", kIssuer);
                llMessageLinked(LINK_SET, NOTIFY, "0You are now a owner on this collar", kID);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_owner="+llDumpList2String(g_lOwner,","), "origin");
                g_iMode = ACTION_REM | ACTION_TRUST | ACTION_BLOCK;
                UpdateLists(kID, kIssuer);
            }
        }
        if(iMode & ACTION_TRUST){
            if(llListFindList(g_lTrust, [(string)kID])==-1){
                g_lTrust+=kID;
                llMessageLinked(LINK_SET, NOTIFY, "1"+SLURL(kID)+" has been added to the trusted user list", kIssuer);
                llMessageLinked(LINK_SET, NOTIFY, "0You are now a trusted user on this collar", kID);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_trust="+llDumpList2String(g_lTrust, ","), "origin");
                g_iMode = ACTION_REM | ACTION_OWNER | ACTION_BLOCK;
                UpdateLists(kID, kIssuer);
            }
        }
        if(iMode & ACTION_BLOCK){
            if(llListFindList(g_lBlock, [(string)kID])==-1){
                if(kID != g_kWearer || g_iGrantedConsent || kIssuer==g_kWearer){
                    g_lBlock+=kID;
                    llMessageLinked(LINK_SET, NOTIFY, "1"+SLURL(kID)+" has been blocked", kIssuer);
                    llMessageLinked(LINK_SET, NOTIFY, "0Your access to this collar is now blocked", kID);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_block="+llDumpList2String(g_lBlock,","),"origin");
                    g_iMode=ACTION_REM|ACTION_OWNER|ACTION_TRUST;
                    UpdateLists(kID, kIssuer);
                    g_iGrantedConsent=FALSE;
                } else if(kID==g_kWearer && !g_iGrantedConsent){
                    WearerConfirmListUpdate(kIssuer, "Block access entirely");
                }
            }
        }
    } else if(iMode&ACTION_REM){
        if(iMode&ACTION_OWNER){
            if(llListFindList(g_lOwner, [(string)kID])!=-1){
                if(kID!=g_kWearer || g_iGrantedConsent || kIssuer==g_kWearer){
                    integer iPos = llListFindList(g_lOwner, [(string)kID]);
                    g_lOwner = llDeleteSubList(g_lOwner, iPos, iPos);
                    llMessageLinked(LINK_SET, NOTIFY, "1"+SLURL(kID)+" has been removed from the owner role", kIssuer);
                    llMessageLinked(LINK_SET, NOTIFY, "0You have been removed from %WEARERNAME%'s collar", kID);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_owner="+llDumpList2String(g_lOwner,","), "origin");
                    g_iGrantedConsent=FALSE;
                } else if(kID == g_kWearer && !g_iGrantedConsent){
                    WearerConfirmListUpdate(kIssuer, "Removal of self ownership");
                }
            }
        } 
        if(iMode&ACTION_TRUST){
            if(llListFindList(g_lTrust, [(string)kID])!=-1){
                if(kID != g_kWearer || g_iGrantedConsent || kIssuer==g_kWearer){
                    integer iPos = llListFindList(g_lTrust, [(string)kID]);
                    g_lTrust = llDeleteSubList(g_lTrust, iPos, iPos);
                    llMessageLinked(LINK_SET, NOTIFY, "1"+SLURL(kID)+" has been removed from the trusted role", kIssuer);
                    llMessageLinked(LINK_SET, NOTIFY, "0You have been removed from %WEARERNAME%'s collar", kID);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_trust="+llDumpList2String(g_lTrust, ","),"origin");
                    g_iGrantedConsent=FALSE;
                } else if(kID == g_kWearer && !g_iGrantedConsent){
                    WearerConfirmListUpdate(kIssuer, "Removal from Trusted List");
                }
            }
        }
        if(iMode & ACTION_BLOCK){ // no need to do a confirmation to the wearer if they become unblocked
            if(llListFindList(g_lBlock, [(string)kID])!=-1){
                integer iPos = llListFindList(g_lBlock, [(string)kID]);
                g_lBlock = llDeleteSubList(g_lBlock, iPos, iPos);
                llMessageLinked(LINK_SET, NOTIFY, "1"+SLURL(kID)+" has been removed from the blocked list", kIssuer);
                llMessageLinked(LINK_SET, NOTIFY, "0You have been removed from %WEARERNAME%'s collar blacklist", kID);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_block="+llDumpList2String(g_lBlock,","),"origin");
            }
        }
    }
}
integer g_iLimitRange=TRUE;
integer in_range(key kID){
    if(!g_iLimitRange)return TRUE;
    if(kID == g_kWearer)return TRUE;
    else{
        vector pos = llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]),0);
        return llVecDist(llGetPos(),pos) <= 20.0;
    }
}

UserCommand(integer iAuth, string sCmd, key kID){
    if(sCmd == "getauth"){
        llMessageLinked(LINK_SET, NOTIFY, "0Your access level is: "+Auth2Str(iAuth)+" ("+(string)iAuth+")", kID);
        return;
    } else if(sCmd == "debug" || sCmd == "versions"){
        // here's where the debug or versions commands will ask consent, then trigger
    } else if(sCmd == "help"){
        if(iAuth >= CMD_OWNER && iAuth <= CMD_EVERYONE){
            llGiveInventory(kID, "OpenCollar_Help");
            llSleep(2);
            llLoadURL(kID, "Want to open our website for further help?", "https://opencollar.cc");
        }
    }
    if((llToLower(sCmd) == "menu runaway") || (llToLower(sCmd) == "runaway")){
        RunawayMenu(kID,iAuth);
    }
    
    if(iAuth == CMD_OWNER || (kID==g_kWearer && g_iAllowWearerSetTrusted==TRUE) ){
          
        list lCmd = llParseString2List(sCmd, [" "],[]);
        string sCmdx = llToLower(llList2String(lCmd,0));
        if(sCmdx == "add" || sCmdx == "rem" ) {
            string sType = llToLower(llList2String(lCmd,1));
            string sID;
            if(llGetListLength(lCmd)==3) sID = llList2String(lCmd,2);      
            g_kMenuUser=kID;
            g_iCurrentAuth = iAuth;
            if(sCmdx=="add")
                g_iMode = ACTION_ADD;
            else g_iMode=ACTION_REM;
            if(sType == "owner" && iAuth==CMD_OWNER)g_iMode = g_iMode|ACTION_OWNER;
            else if(sType == "trust")g_iMode = g_iMode|ACTION_TRUST;
            else if(sType == "block")g_iMode=g_iMode|ACTION_BLOCK;
            else return; // Invalid, don't continue
                    
            if(sID == ""){
                // Open Scanner Menu to add
                if(g_iMode&ACTION_ADD){
                    g_iMode = g_iMode|ACTION_SCANNER;
                    llSensor("", "", AGENT, 20, PI);
                } else {
                    list lOpts;
                    if(sType == "owner")lOpts=g_lOwner;
                    else if(sType == "trust")lOpts=g_lTrust;
                    else if(sType == "block")lOpts=g_lBlock;
                    
                    Dialog(kID, "OpenCollar\n\nRemove "+sType, lOpts, [UPMENU],0,iAuth,"removeUser");
                }
            }else {
                UpdateLists((key)sID, kID);
            }
        }
        else if(iAuth==CMD_OWNER) {
            if(sCmd == "safeword-disable")g_iSafewordDisable=TRUE;
            else if(sCmd == "safeword-enable")g_iSafewordDisable=FALSE;        
            if(sCmdx == "channel"){
                g_iChannel = (integer)llList2String(lCmd,1);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_channel="+(string)g_iChannel, kID);
        
            } else if(sCmdx == "prefix"){
                if(llList2String(lCmd,1)==""){
                    llMessageLinked(LINK_SET,NOTIFY,"0The prefix is currently set to: "+g_sPrefix+". If you wish to change it, supply the new prefix to this same command", kID);
                    return;
                }
                g_sPrefix = llList2String(lCmd,1);
                if(llToLower(g_sPrefix)=="reset") g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_prefix="+g_sPrefix,kID);
                llMessageLinked(LINK_SET,NOTIFY,"1Prefix has been set to "+g_sPrefix+".",kID);
            } 
        } 
    }
    if (iAuth <CMD_OWNER || iAuth>CMD_EVERYONE) return;
    
    if(sCmd == "print auth"){
         if(iAuth == CMD_OWNER || iAuth == CMD_TRUSTED || iAuth == CMD_WEARER)
            PrintAccess(kID);
        else
            llMessageLinked(LINK_SET,NOTIFY, "0%NOACCESS% to printing access lists!", kID);
    }
}

SW(){
    llMessageLinked(LINK_SET, NOTIFY,"0You used the safeword, your owners have been notified", g_kWearer);
    llMessageLinked(LINK_SET, NOTIFY_OWNERS, "%WEARERNAME% had to use the safeword. Please check on %WEARERNAME%.","");
}
//integer g_iInterfaceChannel;
//integer g_iLMCounter=0;
string tf(integer a){
    if(a)return "true";
    return "false";
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

integer SENSORDIALOG = -9003;
integer SAY = 1004;
integer g_iInterfaceChannel;

integer g_iStartup=TRUE;
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
                llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
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
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
        g_iStartup=TRUE;
    }
    changed(integer change){
        if (change & CHANGED_OWNER) llResetScript();
    }
    state_entry(){
        if(llGetStartParameter()!=0)llResetScript();
        g_kWearer = llGetOwner();
        g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
        // make the API Channel be per user
        if (g_iInterfaceChannel==0) g_iInterfaceChannel = -llAbs((integer)("0x" + llGetSubString(g_kWearer,30,-1)));
        if (g_iInterfaceChannel==0) g_iInterfaceChannel = -9876; //I mean it COULD happen. should have an offset value here, but it's too late now so just assigning a random chan.
        llListen(g_iInterfaceChannel, "","","");
        llSleep(0.5);
        llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=Yes");
        DoListeners();
        
        llSetTimerEvent(15);
        
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL","");
        
            
        
    }
    
    timer(){
        if(llGetInventoryType("oc_states")==INVENTORY_NONE)llSetTimerEvent(0); // The state manager is not installed.
        if(llGetScriptState("oc_states")==FALSE){
            llResetOtherScript("oc_states");
            llSleep(0.5);
            llSetScriptState("oc_states",TRUE);
        }
    }
    
    run_time_permissions(integer iPerm) {
        if (iPerm & PERMISSION_ATTACH) {
            llOwnerSay("@detach=yes");
            llDetachFromAvatar();
        }
    }
    
    listen(integer c,string n,key i,string m){
         if(c == g_iInterfaceChannel) {
             if (llGetOwnerKey(i)==g_kWearer){
                //play ping pong with the Sub AO only if object is owned by wearer
                if (m == "OpenCollar?") llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=Yes");
                else if (m == "OpenCollar=Yes") {
                    llOwnerSay("\n\nATTENTION: You are attempting to wear more than one OpenCollar core. This causes errors with other compatible accessories and your RLV relay. For a smooth experience, and to avoid wearing unnecessary script duplicates, please consider to take off \""+n+"\" manually if it doesn't detach automatically.\n");
                    llRegionSayTo(i,g_iInterfaceChannel,"There can be only one!");
                } else if (m == "There can be only one!" ) {
                    llOwnerSay("/me has been detached.");
                    llRequestPermissions(g_kWearer,PERMISSION_ATTACH);
                }
            }
            if(llToLower(llGetSubString(m,0,5))=="menuto")    {
                m=llStringTrim(llGetSubString(m,6,-1),STRING_TRIM);
                if(llGetAgentSize((key)m)!=ZERO_VECTOR && llGetOwnerKey(i)==(key)m) llMessageLinked(LINK_SET,0,"menu",m);
                return;
            }
            else {
                if(llList2Integer(llGetObjectDetails(i,[OBJECT_TEMP_ATTACHED]),0)==1) return;
                key kAuthKey=llGetOwnerKey(i);
                integer iAuth=CalcAuth(kAuthKey);
                if(llGetSubString(m,0,6)=="authas:"){ //messages prefixed authas:(key)=(cmd) will use the auth level of key if LOWER than object owner auth.
                    kAuthKey=llGetSubString(m,7,42);
                    m=llGetSubString(m,44,-1);
                    if(llGetAgentSize(kAuthKey)){
                        integer iAKAuth=CalcAuth(kAuthKey);
                        if(iAKAuth>iAuth) iAuth=iAKAuth;
                    }
                    else return;
                }
                if(llToLower(llGetSubString(m,0,8))=="checkauth" && CalcAuth(kAuthKey)>=CMD_OWNER && CalcAuth(kAuthKey)<=CMD_EVERYONE) {
                    integer iReplyChan=(integer)llGetSubString(m,10,-1);
                    if(iReplyChan) llRegionSayTo(i,iReplyChan,"authreply|"+(string)g_kWearer+"|"+(string)CalcAuth(kAuthKey)+"|"+(string)kAuthKey);
                } else if (!llSubStringIndex(m,(string)g_kWearer + ":")){
                    m = llGetSubString(m, 37, -1);
                    if(llGetAgentSize(kAuthKey)) llMessageLinked(LINK_SET, iAuth , m , llGetOwnerKey(i));
                }
            }
            return;
        }
        string CMD;
        if(llSubStringIndex(llToLower(m),llToLower(g_sPrefix))==0) {
            CMD=llGetSubString(m,llStringLength(g_sPrefix),-1);
        } else if(llGetSubString(m,0,0) == "*" || (llGetSubString(m,0,0)=="#" && i!=g_kWearer)) {
            CMD = llGetSubString(m,1,-1);
        } 
        CMD=llStringTrim(CMD,STRING_TRIM);
        if(i==g_kWearer) {
            list lTmp = llParseString2List(m,[" ","(",")"],[]);
            string sDump = llToLower(llDumpList2String(lTmp, ""));
            if(sDump == llToLower(g_sSafeword) && !g_iSafewordDisable) {
                llMessageLinked(LINK_SET, CMD_SAFEWORD, "","");
                llLinksetDataDelete("auth_WearerLockout");
                SW();
                return;
            }
            else if(llLinksetDataRead("auth_WearerLockout")!="" && CMD!="runaway" && CMD!="")
            {
                llMessageLinked(LINK_SET,AUTH_WEARERLOCKOUT,"","");
                return;
            }
        }

        if(CMD!="" && CMD!="initialize" && CMD!="runaway_confirmed") {
            llMessageLinked(LINK_SET, CalcAuth(llGetOwnerKey(i)),llStringTrim(CMD,STRING_TRIM_HEAD),llGetOwnerKey(i));
        }

    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        
        //if(iNum>=CMD_OWNER && iNum <= CMD_NOACCESS) llOwnerSay(llDumpList2String([iSender, iNum, sStr, kID], " ^ "));
        if(iNum == CMD_ZERO){
            if(sStr == "initialize")return;
            integer iAuth = CalcAuth(kID);
            //llOwnerSay( "{API} Calculate auth for "+(string)kID+"="+(string)iAuth+";"+sStr);
            if(llLinksetDataRead("auth_WearerLockout")!="" && kID==g_kWearer && iAuth==CMD_NOACCESS ) {
                llMessageLinked(LINK_SET,AUTH_WEARERLOCKOUT,"","");
                return;
        } else   llMessageLinked(LINK_SET, iAuth, sStr, kID);
        } else if(iNum == AUTH_REQUEST){
            integer iAuth = CalcAuth(kID);
            //llOwnerSay("{API} Calculate auth for "+(string)kID+"="+(string)iAuth+";"+sStr);
            llMessageLinked(LINK_SET, AUTH_REPLY, "AuthReply|"+(string)kID+"|"+(string)iAuth,sStr);
        } else if(iNum >= CMD_OWNER && iNum <= CMD_NOACCESS) UserCommand(iNum, sStr, kID);
        else if(iNum == LM_SETTING_RESPONSE){
            list lPar = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            string sVal = llList2String(lPar,2);
            
            //integer ind = llListFindList(g_lSettingsReqs, [sToken+"_"+sVar]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            if(sToken == "auth"){
                if(sVar == "owner"){
                    g_lOwner=llParseString2List(sVal, [","],[]);
                } else if(sVar == "trust"){
                    g_lTrust = llParseString2List(sVal,[","],[]);
                } else if(sVar == "block"){
                    g_lBlock = llParseString2List(sVal,[","],[]);
                } else if(sVar == "public"){
                    g_iPublic=(integer)sVal;
                } else if(sVar == "group"){
                    if(sVal == (string)NULL_KEY)sVal="";
                    g_kGroup = (key)sVal;
                    
                    if(g_kGroup!="")
                        llOwnerSay("@setgroup:"+(string)g_kGroup+"=force,setgroup=n");
                    else llOwnerSay("@setgroup=y");
                } else if(sVar == "limitrange"){
                    g_iLimitRange = (integer)sVal;
                } else if(sVar == "tempowner"){
                    g_kTempOwner = (key)sVal;
                } else if(sVar == "runaway"){
                    g_iRunaway=(integer)sVal;
                } else if(sVar == "wearertrust"){
                    g_iAllowWearerSetTrusted=(integer)sVal;
                }
            } else if(sToken == "global"){
                if(sVar == "channel"){
                    g_iChannel = (integer)sVal;
                    DoListeners();
                } else if(sVar == "prefix"){
                    g_sPrefix = sVal;
                } else if(sVar == "safeword"){
                    g_sSafeword = sVal;
                } else if(sVar == "safeworddisable"){
                    g_iSafewordDisable=1;
                } else if(sVar=="listen0"){
                    g_iListenPublic = (integer)sVal;
                    DoListeners();
                }
            }
            
            if(sStr=="settings=sent"){
                if(g_iStartup){
                    g_iStartup=0;
                    if(llGetListLength(g_lOwner)>0){
                        integer x=0;
                        integer x_end = llGetListLength(g_lOwner);
                        list lMsg = [];
                        for(x=0;x<x_end;x++){
                            key owner = (key)llList2String(g_lOwner,x);
                            if(owner==g_kWearer)lMsg += "Yourself";
                            else lMsg += ["secondlife:///app/agent/"+(string)owner+"/about"];
                        }
                        
                        llMessageLinked(LINK_SET, NOTIFY, "0You are owned by: "+llDumpList2String(lMsg,", "), g_kWearer);
                    }
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            
            list lPar = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            
            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            if(sToken == "auth"){
                if(sVar == "owner"){
                    g_lOwner=[];
                } else if(sVar == "trust"){
                    g_lTrust = [];
                } else if(sVar == "block"){
                    g_lBlock = [];
                } else if(sVar == "public"){
                    g_iPublic=FALSE;
                } else if(sVar == "group"){
                    g_kGroup = NULL_KEY;
                    llOwnerSay("@setgroup=y");
                } else if(sVar == "limitrange"){
                    g_iLimitRange = TRUE;
                } else if(sVar == "tempowner"){
                    g_kTempOwner = "";
                } else if(sVar == "runaway"){
                    g_iRunaway=TRUE;
                } else if(sVar == "wearertrust"){
                    g_iAllowWearerSetTrusted=FALSE; 
                }
            } else if(sToken == "global"){
                if(sVar == "channel"){
                    g_iChannel = 1;
                    DoListeners();
                } else if(sVar == "prefix"){
                    g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
                } else if(sVar == "safeword"){
                    g_sSafeword = "RED";
                }
            }
        } else if(iNum == REBOOT){
            if(sStr=="reboot"){
                llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
            }
        } else if(iNum == STARTUP && sStr=="ALL"){
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL","");
        } else if(iNum == DIALOG_RESPONSE){
            integer iPos = llSubStringIndex(kID, "~"+llGetScriptName());
            if(iPos>0){
                string sMenu = llGetSubString(kID, 0, iPos-1);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                //integer iRespring=TRUE;
                
                if(sMenu == "scan~add"){
                    if(sMsg == UPMENU){
                        llMessageLinked(LINK_SET, iAuth, "menu Access", kAv);
                        return;
                    } else if(sMsg == ">Wearer<"){
                        UpdateLists(llGetOwner(), g_kMenuUser);
                        // Not enough time to update the lists via settings. Handle via timer callback.
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "5", "spring_access:"+(string)kAv);
                    }else {
                        //UpdateLists((key)sMsg);
                        g_kTry = (key)sMsg;
                        if(!(g_iMode&ACTION_BLOCK))
                            Dialog(g_kTry, "OpenCollar\n\n"+SLURL(kAv)+" is trying to add you to an access list, do you agree?", ["Yes", "No"], [], 0, CMD_NOACCESS, "scan~confirm");
                        else UpdateLists((key)sMsg, g_kMenuUser);
                    }
                } else if(sMenu == "WearerConfirmation"){
                    if(sMsg == "Allow"){
                        // process
                        g_iGrantedConsent=TRUE;
                        UpdateLists(g_kWearer, g_kMenuUser);
                        // Not enough time to update the lists via settings. Handle via timer callback.
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "5", "spring_access:"+(string)g_kMenuUser);
                    } else if(sMsg == "Disallow"){
                        llMessageLinked(LINK_SET, NOTIFY, "0The wearer did not give consent for this action", g_kMenuUser);
                        g_iMode=0;
                        // Not enough time to update the lists via settings. Handle via timer callback.
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "5", "spring_access:"+(string)g_kMenuUser);
                    }
                } else if(sMenu == "scan~confirm"){
                    if(sMsg == "No"){
                        g_iMode = 0;
                        llMessageLinked(LINK_SET, 0, "menu Access", kAv);
                        llMessageLinked(LINK_SET, NOTIFY,  "1" + SLURL(kAv) + " declined being added to the access list.", g_kWearer);
                    } else if(sMsg == "Yes"){
                        UpdateLists(g_kTry, g_kMenuUser);
                        // Not enough time to update the lists via settings. Handle via timer callback.
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "5", "spring_access:"+(string)kAv);
                    }
                } else if(sMenu == "removeUser"){
                    if(sMsg == UPMENU){
                        // Not enough time to update the lists via settings. Handle via timer callback.
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "2", "spring_access:"+(string)kAv);
                    }else{
                        UpdateLists(sMsg, g_kMenuUser);
                    }
                } else if(sMenu == "RunawayMenu"){
                    if(sMsg == "Enable" && iAuth == CMD_OWNER){
                        g_iRunaway=TRUE;
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "AUTH_runaway","origin");
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "5", "spring_access:"+(string)kAv);
                    } else if(sMsg == "Disable"){
                        g_kDenyRunawayRequester=kAv;
                        Dialog(g_kWearer, "\nsecondlife:///app/agent/"+(string)kAv+"/about wants to disable your ability to 'Runaway'. This can only be reversed by an owner. \n\nYou may accept or deny this action.", [], ["Accept", "Deny"], 0, CMD_WEARER, "confirmdenyrunaway");
                    } else if(sMsg == "No"){
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "2", "spring_access:"+(string)kAv);
                        return;
                    } else if(sMsg == "Yes"){
                        if((kAv == g_kWearer || iAuth == CMD_OWNER ) && g_iRunaway){
                            // trigger runaway sequence if approval was given
                            llMessageLinked(LINK_SET, NOTIFY_OWNERS, "%WEARERNAME% has runaway.", "");
                            llMessageLinked(LINK_SET, CMD_OWNER, "runaway_confirmed", g_kWearer);
                            llMessageLinked(LINK_SET, CMD_SAFEWORD, "safeword", "");
                            llSleep(0.5); // Wait for notifications before clearing owners
                            llLinksetDataDelete("auth_WearerLockout");
                            llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "5", "spring_access:"+(string)kAv);
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_owner","origin");
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_trust","origin");
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_block","origin");
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_group","origin");
                            llMessageLinked(LINK_SET, NOTIFY, "0Runaway complete", g_kWearer);
                        }
                    }
                } else if(sMenu=="confirmdenyrunaway") {
                    if(sMsg=="Accept"){
                        g_iRunaway=FALSE;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "AUTH_runaway=0", "origin"); 
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "2", "spring_access:"+(string)g_kDenyRunawayRequester);
                    } else if (sMsg=="Deny"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Wearer has DENIED switching off runaway.",g_kDenyRunawayRequester);
                        llMessageLinked(LINK_SET, TIMEOUT_REGISTER, "2", "spring_access:"+(string)g_kDenyRunawayRequester);
                    }             
                }
            }
        } else if(iNum == RLV_REFRESH){
            if(g_kGroup==NULL_KEY)llOwnerSay("@setgroup=y");
            else llOwnerSay("@setgroup:"+(string)g_kGroup+"=force;setgroup=n");
        } else if(iNum == -99999){
            if(sStr == "update_active")llResetScript();
        } else if(iNum == TIMEOUT_FIRED)
        {
            list lTmp = llParseString2List(sStr, [":"],[]);
            if(llList2String(lTmp,0)=="spring_access"){
                llMessageLinked(LINK_SET,0,"menu Access", (key)llList2String(lTmp,1));
            }
        }
    }
    sensor(integer iNum){
        if(!(g_iMode&ACTION_SCANNER))return;
        list lPeople = [];
        integer i=0;
        for(i=0;i<iNum;i++){
            if(llGetListLength(lPeople)<10){
                //llSay(0, "scan: "+(string)i+";"+(string)llGetListLength(lPeople)+";"+(string)g_iMode);
                if(llDetectedKey(i)!=llGetOwner())
                    lPeople += llDetectedKey(i);
                
            } else {
                //llSay(0, "scan: invalid list length: "+(string)llGetListLength(lPeople)+";"+(string)g_iMode);
            }
        }
        
        Dialog(g_kMenuUser, "OpenCollar\nAdd Menu", lPeople, [">Wearer<",UPMENU], 0, g_iCurrentAuth, "scan~add");
    }
    
    no_sensor(){
        if(!(g_iMode&ACTION_SCANNER))return;
        
        Dialog(g_kMenuUser, "OpenCollar\nAdd Menu", [], [">Wearer<", UPMENU], 0, g_iCurrentAuth, "scan~add");
    }
}
