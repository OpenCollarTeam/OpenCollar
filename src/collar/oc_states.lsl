  
/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :

Aria (Tashia Redrose)
    *August 2020       -       Created oc_states
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/
integer STATE_MANAGER = 7003;
integer STATE_MANAGER_REPLY = 7004;


integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

string g_sLastCmd;
integer g_iLastAuth;
key g_kLastID;
string g_sLastScript;

integer REBOOT = -1000;

list g_lManagedScripts = []; // script name, menu name, dependencies, lastAlive, baseCommands

/// This function will return the alive response code, but if the menu is not managed anywhere, it will return -2
integer GetLastAlive(string ScriptName){
    integer iPos = llListFindList(g_lManagedScripts,[ScriptName]);
    if(iPos == -1)return -2;
    else{
        return llList2Integer(g_lManagedScripts,iPos+3);
    }
}

SetLastAlive(string MenuName)
{
    if(GetLastAlive(MenuName)!=-2){
        integer iPos = llListFindList(g_lManagedScripts,[MenuName])+2;
        g_lManagedScripts = llListReplaceList(g_lManagedScripts, [llGetUnixTime()], iPos,iPos);
        //llOwnerSay("New managed list: "+llDumpList2String(g_lManagedScripts,"; "));
    }
}    

list StrideOfList(list src, integer stride, integer start, integer end)
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
}
integer NOTIFY = 1002;
integer NOTIFY_OWNERS=1003;
integer g_iInitialScan = TRUE;
integer g_iReboot=FALSE;
integer g_iRescan=TRUE;
StartAll(){
    g_lManagedScripts = [];
    llSetTimerEvent(1);
    g_iRescan=TRUE;
}
default
{
    state_entry()
    {
        llSetTimerEvent(1);
    }
    
    
    on_rez(integer iRez){
        StartAll();
        g_iReboot=TRUE;
    }
    
    
    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            StartAll();
            g_iRescan=TRUE;
        }
    }
    
    timer(){
        if(llGetTime()>=30 && g_iInitialScan){
            llResetTime();
            // perform state checks
            g_iInitialScan=FALSE;
        }
        llSetTimerEvent(15);
        // Check all script states, then check list of managed scripts
        integer i=0;
        integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
        integer iModified=FALSE;
        for(i=0;i<end;i++){
            string scriptName = llGetInventoryName(INVENTORY_SCRIPT, i);
            if(llListFindList(g_lManagedScripts, [scriptName]) == -1){
                // regular anti-crash
                if(llGetScriptState(scriptName)==FALSE){
                    llResetOtherScript(scriptName);
                    llSleep(0.5);
                    llSetScriptState(scriptName,TRUE);
                    llSleep(1);
                    iModified=TRUE;
                    
                    if(g_iReboot || g_iInitialScan){}else
                        llMessageLinked(LINK_SET, NOTIFY, "0"+scriptName+" has been reset. If the script stack heaped, please file a bug report on our github. If the script is supposed to be off, please ensure it is registering with State Manager", llGetOwner());
                }
            } else {
                //llWhisper(0, scriptName+" - is a managed script");
                integer iPos = llListFindList(g_lManagedScripts,[scriptName]);
                integer iLastAlive = GetLastAlive(scriptName);
                if(((iLastAlive+30) < llGetUnixTime()) && llGetScriptState(scriptName)){
                    if(llGetScriptState(scriptName)==TRUE){
                        //llOwnerSay("Turning off "+scriptName);
                        //llWhisper(0, "Turning off "+scriptName);
                        llSetScriptState(scriptName,FALSE);
                    }
                } else if(((iLastAlive+30) < llGetUnixTime()) && !llGetScriptState(scriptName)){
                }else {
                    // ensure the script stays alive
                    if(llGetScriptState(scriptName)==FALSE){
                        llResetOtherScript(scriptName);
                        llSleep(0.5);
                        llSetScriptState(scriptName,TRUE);
                        llSleep(1);
                        iModified=TRUE;
                        
                        if(scriptName==g_sLastScript)
                        {
                            llMessageLinked(LINK_SET, g_iLastAuth, g_sLastCmd, g_kLastID);
                            SetLastAlive(llList2String(g_lManagedScripts, llListFindList(g_lManagedScripts, [scriptName])+1));

                            g_sLastScript="";
                            g_iLastAuth=0;
                            g_kLastID="";
                            g_sLastCmd="";
                        }
                    } else {
                        // Send a ping
                        
                        if(scriptName==g_sLastScript)
                        {
                            g_sLastScript="";
                            g_iLastAuth=0;
                            g_kLastID="";
                            g_sLastCmd="";
                        }
                        llMessageLinked(LINK_SET, STATE_MANAGER, llList2Json(JSON_OBJECT, ["type","ping", "script", scriptName]), "");
                    }
                }
            }
        }
        
        if(iModified) llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL","");
        if(g_iReboot){
            llMessageLinked(LINK_SET, REBOOT,"reboot", "");
            llSleep(1);
            llResetScript();
        }
        
        if(g_iInitialScan||g_iRescan)llMessageLinked(LINK_SET,STATE_MANAGER, llList2Json(JSON_OBJECT, ["type","scan"]),"");
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(sStr == "fix" || iNum == REBOOT){
            if(iNum == REBOOT)g_iReboot=TRUE;
            StartAll();
            
        }
        if(iNum == STATE_MANAGER_REPLY){
            string sReplyType = llJsonGetValue(sStr, ["type"]);
            integer iPos = llListFindList(g_lManagedScripts,[llJsonGetValue(sStr,["script"])]);
            if(sReplyType == "no_manage"){
                
                if(iPos!=-1){
                    // remove from the manage list until re-subscribed
                    g_lManagedScripts = llDeleteSubList(g_lManagedScripts,iPos,iPos+4); // script name, menu label, dependent script list, lastAlive, baseCmds
                    //llOwnerSay("New managed list: "+llDumpList2String(g_lManagedScripts,"; "));
                }
            } else if(sReplyType == "pong"){
                // script is alive. prevent state manager from turning off the script
                SetLastAlive(llJsonGetValue(sStr,["menu"]));
            }
        } else if(iNum == STATE_MANAGER){
            string sReplyType = llJsonGetValue(sStr, ["type"]);
            integer iPos = llListFindList(g_lManagedScripts,[llJsonGetValue(sStr,["script"])]);
            if(sReplyType == "subscribe"){
                if(iPos==-1){
                    g_lManagedScripts += [llJsonGetValue(sStr,["script"]), llJsonGetValue(sStr, ["menu_label"]), llJsonGetValue(sStr,["dependencies"]),llGetUnixTime(), llJsonGetValue(sStr, ["baseCmds"])];

                    //llOwnerSay("New managed list: "+llDumpList2String(g_lManagedScripts,"; "));
                }
            } else if(sReplyType == "run"){
                // get datas
                integer iAuth = (integer)llJsonGetValue(sStr, ["authorization"]);
                string sCmd = llJsonGetValue(sStr, ["cmd"]);
                key kAv = llJsonGetValue(sStr, ["kID"]);
                // check menu command, then scan base commands and activate relevant scripts if necessary
                if(llGetSubString(sCmd,0,3)=="menu"){
                    // it's a menu call, grab the menu name if applicable, then trigger
                    if(llStringLength(sCmd)==4)llMessageLinked(LINK_SET, iAuth, sCmd, kAv);
                    else {
                        // it includes a menu name
                        list lTmp = StrideOfList(g_lManagedScripts,5,1,-1);
                        if(llListFindList(lTmp, [llGetSubString(sCmd,5,-1)])==-1){
                            //llOwnerSay("menu not found - forwarding");
                            llMessageLinked(LINK_SET, iAuth, sCmd, kAv);
                        } else {
                            // the script is managed
                            // get script name, ensure script is running, set last alive, forward command
                            string sScript = llList2String(g_lManagedScripts, llListFindList(g_lManagedScripts, [llGetSubString(sCmd,5,-1)])-1);



                            //llOwnerSay("Turning on "+sScript);
                            llSetScriptState(sScript,TRUE);
                            g_sLastCmd = sCmd;
                            g_iLastAuth = iAuth;
                            g_kLastID = kAv;
                            g_sLastScript = sScript;
                            
                            
                            SetLastAlive(llGetSubString(sCmd,5,-1));
                            
                            llSleep(1);
                            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "ALL","");
                            llSleep(2);
                            llMessageLinked(LINK_SET, iAuth, sCmd, kAv);
                            
                        }
                    }
                } else {
                    // check base commands
                    list lTmp = llParseString2List(llList2String(StrideOfList(g_lManagedScripts,5, 4,-1),0),["|"],[]);
                    integer ix=0;
                    integer iNotFound=TRUE;
                    integer iend=llGetListLength(lTmp);
                    for(ix=0;ix<iend;ix++){
                        // Check if contains each command
                        if(llSubStringIndex(llList2String(lTmp,ix), sCmd)!=-1){
                            iNotFound=FALSE;
                            // boot the script!
                            string sScript = llList2String(g_lManagedScripts, llListFindList(g_lManagedScripts, [llList2String(lTmp,ix)])-4);
                            //llOwnerSay("Turning on "+sScript);

                            llSetScriptState(sScript,TRUE);
                            g_sLastCmd = sCmd;
                            g_iLastAuth = iAuth;
                            g_kLastID = kAv;
                            g_sLastScript = sScript;
                            
                            
                            SetLastAlive(llList2String(g_lManagedScripts, llListFindList(g_lManagedScripts, [sScript])+1));
                            
                            llSleep(1);
                            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "ALL","");
                            llSleep(2);
                            llMessageLinked(LINK_SET, iAuth, sCmd, kAv);
                        }
                    }
                    
                    if(iNotFound){
                        //llOwnerSay( "command not found- forwarding");
                        llMessageLinked(LINK_SET, iAuth, sCmd,kAv);
                    }
                }
            }
        }
    }
}
