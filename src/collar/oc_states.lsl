  
/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :

Aria (Tashia Redrose)
    *August 2020       -       Created oc_states
                    -           Due to significant issues with original implementation, States has been turned into a anti-crash script instead of a script state manager.
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/


integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value


integer REBOOT = -1000;

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
default
{
    state_entry()
    {
        llSetTimerEvent(1);
    }
    
    
    on_rez(integer iRez){
        llResetScript();
    }
    
    
    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            llResetScript();
        }
    }
    
    timer(){
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
                
                llMessageLinked(LINK_SET, NOTIFY, "0"+scriptName+" has been reset. If the script stack heaped, please file a bug report on our github.", llGetOwner());
            }
        }
        
        if(iModified) llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL","");
        
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(sStr == "fix" || iNum == REBOOT){
            llResetScript();
        }
    }
}
