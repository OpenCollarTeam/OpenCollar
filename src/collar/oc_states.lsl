/*
This file is a part of OpenCollar.
Copyright ©2020
: Contributors :
Aria (Tashia Redrose)
    *August 2020        -       *Created oc_states
                                *Due to significant issues with original implementation, States has been turned into a anti-crash
                                script instead of a script state manager.
                                *Repurpose oc_states to be anti-crash and a interactive settings editor.
Medea (Medea Destiny)
    *July 2021          -       *See issue #587: Added warning when script resets folders script that user should consider cleaning
                                up their #RLV 
    Sept 2021           -       Tighten timings and number of passes on reboot process and reduced sleep padding.                               
                                            
Yosty7B3
    Mar 2023            -       Speed up boot time & Linkset Data integration
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_BLOCKED = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_NOACCESS=599;

integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

integer g_iVerbosityLevel = 1;

/*list StrideOfList(list src, integer stride, integer start, integer end)
{
    list l = [];
    integer ll = llGetListLength(src);
    if(start < 0)start += ll;
    if(end < 0)end += ll;
    if(end < start) return llList2List(src, start, start);
    while(start <= end)
    {
        l += llList2List(src, start, start);
        start += stride;
    }
    return l;
}*/
//integer NOTIFY_OWNERS=1003;

integer NOTIFY = 1002;
integer REBOOT = -1000;

//integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
//integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

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
//key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
//list g_lOwner;
//list g_lTrust;
key g_kMenuUser;
integer g_iLastAuth;
//list g_lBlock;
string g_sVariableView;
//integer g_iLocked=FALSE;
string g_sTokenView="";
integer g_iLastStride;

list g_lTimers; // signal, start_time, seconds_from


integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

string g_sSubmenu = "EDITOR";
integer g_iStartup; // keep track on where in the bootup sequence we are
            
SettingsMenu(integer stridePos, key kAv, integer iAuth)
{
    string sText = "OpenCollar - Interactive Settings editor";
    list lBtns = [];
    if(iAuth != CMD_OWNER){
        sText+="\n\nOnly owner may use this feature";
        Dialog(kAv, sText, [], [UPMENU], 0, iAuth, "Menu~Main");
        return;
    }
    if(stridePos == 0){
        list lKeys = llLinksetDataListKeys(0,-1);
        while(llGetListLength(lKeys)){
            string sToken = llList2String(llParseString2List(llList2String(lKeys,0), ["_"],[]),0);
            if(llListFindList(lBtns,[sToken])==-1)lBtns+=sToken;
            lKeys = llDeleteSubList(lKeys,0,0);
        }
        sText+="\nCurrently viewing Tokens";
    } else if(stridePos==1){
        lBtns =  llParseString2List((string)llLinksetDataFindKeys("^"+g_sTokenView+"_",0,-1), [g_sTokenView+"_"],[]);
        sText+="\nCurrently viewing Variables for token '"+g_sTokenView+"'";
    } else if(stridePos == 2){
        string sVal = llLinksetDataRead(g_sTokenView+"_"+g_sVariableView);
        if(sVal==""){
            // cannot do it
            lBtns=[];
            sText+="\nCurrently viewing the variable '"+g_sTokenView+"_"+g_sVariableView+"'\nNo data found";
        } else {
            lBtns = ["DELETE", "MODIFY"];
            sText = "\nCurrently viewing the variable '"+g_sTokenView+"_"+g_sVariableView+"'\nData contained in var: "+sVal;
        }
    } else if(stridePos==3){
        sText+="\n\nPlease enter a new value for: "+g_sTokenView+"_"+g_sVariableView+"\n\nCurrent value: "+llLinksetDataRead(g_sTokenView+"_"+g_sVariableView);
        lBtns =[];
    } else if(stridePos==8){
        sText+= "\n\nPlease enter the token name";
        lBtns=[];
    } else if(stridePos == 9){
        sText += "\n\nPlease enter the variable name for '"+g_sTokenView;
        lBtns=[];
    }
    
    g_iLastStride=stridePos;
    Dialog(kAv, sText,lBtns, llCSV2List(llList2String(["+ NEW,"+UPMENU,""],lBtns==[])), 0, iAuth, "settings~edit~"+(string)stridePos);
}

// oc_api and oc_core need to be ALIVE & oc_settings should be running
list g_lWaiting;  
integer Alive(string scriptName){
    integer iScript = llListFindList(g_lWaiting,[scriptName]);
    if(~iScript){
        g_lWaiting = llDeleteSubList(g_lWaiting, iScript, iScript);
    }
    if(llGetListLength(g_lWaiting)==0 && llGetScriptState("oc_settings")){
        return TRUE;
    }
    return FALSE;
}

integer AntiCrash(string scriptName){
    if(!~llGetInventoryType(scriptName)) return TRUE;
    
    if(llGetScriptState(scriptName)==FALSE){
        llResetOtherScript(scriptName);
        llSleep(0.5);
        llSetScriptState(scriptName,TRUE);
        llSleep(1);
        
        if(scriptName=="oc_folders") llOwnerSay("WARNING! Opencollar detected that your folder script stopped running, and has restarted it. Usually this is a stack heap error, which means the folder script ran out of memory trying to read your folders. This happens when you have too many subfolders in one place. To stop this happening, please consider reorganizing your #RLV so that no individual folder has too many subfolders inside it, and check for folders that begin with a ~ directly in your #RLV root folder that can be deleted -- normally these are temporary attachment folders and are no longer needed."); 
        if(g_iVerbosityLevel >=1)
            llMessageLinked(LINK_SET, NOTIFY, "0"+scriptName+" has been reset. If the script stack heaped, please file a bug report on our github.", llGetOwner());
        return TRUE;
    }    
    return FALSE;
}

Reboot(){
    integer i = llGetListLength(g_lWaiting);
    while(i--)            
        AntiCrash(llList2String(g_lWaiting,i));
        
    llMessageLinked(LINK_SET, REBOOT,"reboot", llGetScriptName());
    llResetTime();
    llSetTimerEvent(5);
}

Startup(string scriptName){
    llMessageLinked(LINK_SET, STARTUP, scriptName, "");
}
default
{
    state_entry()
    {
        if(llGetStartParameter() != 0) state inUpdate;
        g_lWaiting=["oc_api" ,"oc_core"];
        Reboot();

        if(g_iVerbosityLevel>=1)
            llOwnerSay("Collar is preparing to start up, please be patient.");
    }
    timer(){    
        llMessageLinked(LINK_SET, READY, "","");
        if(llGetTime()<15) return;
    
        if(g_iVerbosityLevel>=1)
            llOwnerSay("ALIVE check failed for "+llDumpList2String(g_lWaiting," & "));            
            
        g_iVerbosityLevel=0;    // quietly keep trying
        Reboot();   
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT && sStr == "reboot --f")llResetScript();

        if(iNum == ALIVE){
            string scriptName = llList2String(llParseString2List(sStr, ["="],[]),0);
            if(~llListFindList(g_lWaiting, [scriptName])) // go through every script in g_lWaiting
                if(Alive(scriptName)) state startup;    // pass if all gave the ALIVE signal                
        }
    }
}

state startup
{
    state_entry()
    {
        g_iStartup=0;
        Startup("ALL");
        llSetTimerEvent(60);
        
        if(g_iVerbosityLevel>=2)
            llOwnerSay("Waiting for settings to load.");
    }
    
    
    on_rez(integer iRez){
        llResetScript();
    }
    
    timer(){
        if(g_iVerbosityLevel>=1)
            llOwnerSay("Startup timeout on other scripts feedback. code:"+(string)g_iStartup);  
        state running; // move on anyway
    }     
    
    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            llResetScript();
        }
        
    }
        
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT && sStr == "reboot --f")llResetScript();
        if(iNum == 0 && sStr=="initialize"){
            g_iStartup=g_iStartup|1;
        }else if(iNum == LM_SETTING_REQUEST && sStr=="ALL"){
            g_iStartup=g_iStartup|2;
        }else if(iNum == LM_SETTING_RESPONSE && sStr == "settings=sent"){
            g_iStartup=g_iStartup|4;
        } else if(iNum == ALIVE){
            Startup(sStr);
        }
        if(g_iStartup>=7) state running;
    }          
}

state running
{
    state_entry()
    {
        llSetTimerEvent(5);
        llMessageLinked(LINK_SET, TIMEOUT_READY, "","");

        // check if any haven't started up yet
        llMessageLinked(LINK_SET, READY, "","");

        if(g_iVerbosityLevel>=2)
            llOwnerSay("Startup Complete.");
    }
    
    on_rez(integer iRez){
       llResetScript();
    }
    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            llSleep(4);
            llResetScript();
        }
    }
    
    timer(){
        if( llGetListLength(g_lTimers) == 0)
            llSetTimerEvent(15);
        // Check all script states, then check list of managed scripts
        integer i=0;
        integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
        integer iModified=FALSE;
        for(i=0;i<end;i++){
            iModified+=AntiCrash(llGetInventoryName(INVENTORY_SCRIPT, i));
        }
        
        if(iModified) llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL","");
        
        // proceed
        i=0;
        end = llGetListLength(g_lTimers);
        for(i=0;i<end;i+=3){
            integer now = llGetUnixTime();
            integer start = llList2Integer(g_lTimers, i+1);
            integer diff = llList2Integer(g_lTimers,i+2);
            if((now-start)>=diff){
                string signal = llList2String(g_lTimers,i);
                
                g_lTimers = llDeleteSubList(g_lTimers, i,i+2);
                i=0;
                end=llGetListLength(g_lTimers);
                llMessageLinked(LINK_SET, TIMEOUT_FIRED, signal, "");
                
            }
        }
        
        //llWhisper(0, "oc_states max used over time: "+(string)llGetSPMaxMemory());
    }
    
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT && sStr == "reboot --f")llResetScript();
        
        if(iNum>=CMD_OWNER && iNum <= CMD_EVERYONE){
            if(sStr == "fix"){
                llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
            }
            if(llToLower(sStr)=="settings edit" || sStr=="menu "+g_sSubmenu){
                SettingsMenu(0,kID,iNum);
            }
        } else if(iNum == TIMEOUT_REGISTER){
            g_lTimers += [(string)kID, llGetUnixTime(), (integer)sStr];
            llResetTime();
            llSetTimerEvent(1);
        } else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRemenu=FALSE;
                
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU){
                        iRemenu=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu Settings", kAv);
                    }
                } else if(sMenu == "settings~edit~0"){
                    if(sMsg == UPMENU){
                        llMessageLinked(LINK_SET, iAuth, "menu Settings", kAv);
                        return;
                    } else if(sMsg == "+ NEW"){
                        SettingsMenu(8, kAv, iAuth);
                        return;
                    }
                    if(sMsg == "intern" || sMsg == "auth"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Editing of the "+sMsg+" token is prohibited by the security policy", kAv);
                        SettingsMenu(0, kAv, iAuth);
                    } else {
                        g_sTokenView=sMsg;
                        SettingsMenu(1, kAv,iAuth);
                    }
                } else if(sMenu == "settings~edit~1"){
                    if(sMsg==UPMENU){
                        SettingsMenu(0,kAv,iAuth);
                        return;
                    }else if(sMsg == "+ NEW"){
                        SettingsMenu(9, kAv, iAuth);
                        return;
                    }
                    
                    g_sVariableView=sMsg;
                    SettingsMenu(2, kAv,iAuth);
                    
                } else if(sMenu == "settings~edit~2"){
                    if(sMsg == UPMENU){
                        SettingsMenu(1,kAv,iAuth);
                        return;
                    } else if(sMsg == "DELETE"){
                        if(llLinksetDataRead(g_sTokenView+"_"+g_sVariableView)==""){
                            SettingsMenu(2,kAv,iAuth);
                            return;
                        }
                        llLinksetDataDelete(g_sTokenView+"_"+g_sVariableView);
                        llMessageLinked(LINK_SET, RLV_REFRESH,"","");
                        llMessageLinked(LINK_SET, NOTIFY, "1"+g_sTokenView+"_"+g_sVariableView+" has been deleted from settings", kAv);
                        SettingsMenu(0,kAv,iAuth);
                        return;
                    } else if(sMsg == "MODIFY"){
                        SettingsMenu(3, kAv,iAuth);
                    }
                } else if(sMenu == "settings~edit~3"){
                    if(sMsg == UPMENU){
                        SettingsMenu(2,kAv,iAuth);
                    } else {
                        if(sMsg=="")SettingsMenu(2,kAv,iAuth);
                        else{
                            llLinksetDataWrite(g_sTokenView+"_"+g_sVariableView, sMsg);
                            llMessageLinked(LINK_SET, NOTIFY, "1Settings modified: "+g_sTokenView+"_"+g_sVariableView+"="+sMsg,kAv);
                            SettingsMenu(1,kAv,iAuth);
                            return;
                        }
                    }
                } else if(sMenu == "settings~edit~8"){
                    g_sTokenView=sMsg;
                    SettingsMenu(9, kAv,iAuth);
                } else if(sMenu == "settings~edit~9"){
                    g_sVariableView=sMsg;
                    SettingsMenu(3, kAv,iAuth);
                }
                        
            }
            
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if(iNum == 0){
            if(sStr == "initialize"){
                llMessageLinked(LINK_SET, TIMEOUT_READY, "","");
            }
        }else if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        } else if(iNum == ALIVE){
            Startup(sStr);
            llSleep(1);
            llMessageLinked(LINK_SET, 0, "initialize", llGetKey());
        } else if(iNum == MENUNAME_REQUEST && sStr == "Settings") {
            llMessageLinked(iSender, MENUNAME_RESPONSE, "Settings|"+g_sSubmenu,"");
        }
    }
}

state inUpdate
{
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT)llResetScript();
    }
    on_rez(integer iNum){
        llResetScript();
    }
}
