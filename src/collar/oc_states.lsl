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



integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
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



list g_lTimers; // signal, start_time, seconds_from

integer g_iExpectAlive=0;
list g_lAlive;
integer g_iPasses=0;

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    state_entry()
    {
        if(llGetStartParameter() != 0) state inUpdate;
        
        g_lAlive=[];
        g_iPasses=-1;
        g_iExpectAlive=1;
        llSetTimerEvent(1);
        //llScriptProfiler(TRUE);
        if(g_iVerbosityLevel>=1)
            llOwnerSay("Preparing to startup, please be patient.");
    }
    
    
    on_rez(integer iRez){
        llResetScript();
    }
    
    timer(){
        
        if(g_iExpectAlive){
            if(llGetTime()>=3 && g_iPasses<2){ //>=5
                llMessageLinked(LINK_SET,READY, "","");
                llResetTime();
                //llSay(0, "PASS COUNT: "+(string)g_iPasses);
                g_iPasses++;
            } else if(llGetTime()>=2 && g_iPasses>=2){ //>=7.5
                if(g_iVerbosityLevel>=2)
                    llOwnerSay("Scripts ready: "+(string)llGetListLength(g_lAlive));
                llMessageLinked(LINK_SET,STARTUP,llDumpList2String(g_lAlive,","),"");
                g_iExpectAlive=0;
                g_lAlive=[];
                g_iPasses=0;
                llSleep(1); //10
                
                if(g_iVerbosityLevel >=1)
                    llMessageLinked(LINK_SET,NOTIFY,"0Startup in progress... be patient", llGetOwner());
                //llMessageLinked(LINK_SET,LM_SETTING_REQUEST,"ALL","");
                llMessageLinked(LINK_SET,0,"initialize","");
            }
            
            return;
        }
        
        if(llGetListLength(g_lTimers) == 0)
            llSetTimerEvent(15);
        // Check all script states, then check list of managed scripts
        integer i=0;
        integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
        integer iModified=FALSE;
        for(i=0;i<end;i++){
            string scriptName = llGetInventoryName(INVENTORY_SCRIPT, i);
            // regular anti-crash
            if(llGetScriptState(scriptName)==FALSE){
                llResetOtherScript(scriptName);
                llSleep(0.5);
                llSetScriptState(scriptName,TRUE);
                llSleep(1);
                iModified=TRUE;
                if(scriptName=="oc_folders") llOwnerSay("WARNING! Opencollar detected that your folder script stopped running, and has restarted it. Usually this is a stack heap error, which means the folder script ran out of memory trying to read your folders. This happens when you have too many subfolders in one place. To stop this happening, please consider reorganizing your #RLV so that no individual folder has too many subfolders inside it, and check for folders that begin with a ~ directly in your #RLV root folder that can be deleted -- normally these are temporary attachment folders and are no longer needed."); 
                if(g_iVerbosityLevel >=1)
                    llMessageLinked(LINK_SET, NOTIFY, "0"+scriptName+" has been reset. If the script stack heaped, please file a bug report on our github.", llGetOwner());
            }
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
                g_iExpectAlive=1;
                llResetTime();
                g_iPasses=0;
                g_lAlive=[];
            }
        } else if(iNum == TIMEOUT_REGISTER){
            g_lTimers += [(string)kID, llGetUnixTime(), (integer)sStr];
            llResetTime();
            llSetTimerEvent(1);
        }else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lSettings,0);
            string sVar = llList2String(lSettings,1);
            string sVal = llList2String(lSettings, 2);
            if(sToken == "global"){
                if(sVar == "verbosity"){
                    g_iVerbosityLevel = (integer)sVal;
                }
            }
        } else if(iNum == 0){
            if(sStr == "initialize"){
                llMessageLinked(LINK_SET, TIMEOUT_READY, "","");
            }
        }else if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        } else if(iNum == ALIVE){
            g_iExpectAlive=1;
            if(llListFindList(g_lAlive,[sStr])==-1){
                g_iPasses=0;
                g_lAlive+=[sStr];
            }else return;
            llResetTime();
            llSetTimerEvent(1);            
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
