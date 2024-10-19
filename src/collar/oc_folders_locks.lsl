/*
This file is a part of OpenCollar.
Copyright 2021

: Contributors :

Aria (Tashia Redrose)
    * Feb 2021      -           Create oc_folders_locks


et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/
list g_lFolderLocks;

integer RLV_OFF = 6100;
integer RLV_ON = 6101;

integer g_iInUpdate=FALSE;
integer REBOOT=-1000;

IssueLocks()
{
    integer i=0;
    integer end=llGetListLength(g_lFolderLocks);
    for(i=0;i<end;i+=2){
        llMessageLinked(LINK_SET, RLV_CMD, llList2String(g_lFolderLocks,i)+":"+llList2String(g_lFolderLocks,i+1)+"=n", "");
    }

    //llSay(0, "FOLDER LOCKS DEBUG RESTRICT\n\n"+llDumpList2String(g_lFolderLocks, " ~ "));
}

integer RLV_CMD = 6000;


integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer QUERY_FOLDER_LOCKS = -9100;
integer REPLY_FOLDER_LOCKS = -9101;
integer SET_FOLDER_LOCK = -9102;
integer CLEAR_FOLDER_LOCKS = -9103;

integer UPDATER = -99999;
default
{
    state_entry()
    {

    }

    link_message(integer iSender, integer iNum, string sMsg, key kID)
    {
        if(iNum==RLV_ON)
        {
            IssueLocks();
        } else if(iNum == QUERY_FOLDER_LOCKS){
            //llSay(0, "FOLDER LOCKS DEBUG (QUERY): PATH ("+sMsg+")");
            integer i=0;
            integer end = llGetListLength(g_lFolderLocks);
            integer iMask = 0;
            for(i=1; i<end;i+=2)
            {
                if(sMsg == llList2String(g_lFolderLocks,i)){
                    string sType = llList2String(g_lFolderLocks,i-1);
                    if(sType == "detachallthis")
                    {
                        iMask+=1;
                    } else if(sType == "attachallthis"){
                        iMask+=2;
                    } else if(sType == "detachthis"){
                        iMask+=4;
                    }else if(sType == "attachthis"){
                        iMask+=8;
                    }
                }
            }
            //llSay(0, "FOLDER LOCKS DEBUG (REPLY): PATH ("+sMsg+") = "+(string)iMask);
            llMessageLinked(LINK_SET, REPLY_FOLDER_LOCKS, sMsg, (string)iMask);
        } else if(iNum == SET_FOLDER_LOCK)
        {
            integer index=llListFindList(g_lFolderLocks, [sMsg,(string)kID]);
            if(index==-1){
                g_lFolderLocks += [sMsg, (string)kID];
            }else{
                llOwnerSay("@"+llList2String(g_lFolderLocks, index)+":"+llList2String(g_lFolderLocks,index+1)+"=y");
                g_lFolderLocks = llDeleteSubList(g_lFolderLocks, index,index+1);
            }
            //llSay(0, "FOLDER LOCKS DEBUG (SET LOCK)\n\nFMEM = "+(string)llGetFreeMemory()+"b\n\n"+llDumpList2String(g_lFolderLocks, " ~ "));
            IssueLocks();
        } else if(iNum == CLEAR_FOLDER_LOCKS)
        {
            //llSay(0, "FOLDER LOCKS DEBUG CLEAR");
            integer i=0;
            integer end = llGetListLength(g_lFolderLocks);
            for(i=0;i<end;i+=2)
            {
                llMessageLinked(LINK_SET, RLV_CMD, llList2String(g_lFolderLocks, i)+":"+llList2String(g_lFolderLocks,i+1)+"=y", "");
            }
            llResetScript();
        } else if(iNum == UPDATER)
        {
            if(sMsg == "update_active"){
                //llSay(0, "FOLDER LOCKS DEBUG UPDATE (ACTIVE)");
                // if msg = update_active, send the update shim the folder locks
                g_iInUpdate = TRUE;
                string serialized = llStringToBase64(llDumpList2String(g_lFolderLocks,"~!~"));
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, "folders_locks="+serialized, "");
                //llSay(0, "FOLDER LOCKS DEBUG BACKUP\nCOMPLETE = "+serialized);
            }
        } else if(iNum == LM_SETTING_RESPONSE && !g_iInUpdate){
            list lParam = llParseString2List(sMsg, ["_", "="], []);
            string sToken = llList2String(lParam,0);
            string sVar = llList2String(lParam,1);
            string sVal = llList2String(lParam,2);

            if(sToken == "folders"){
                if(sVar=="locks"){
                    llMessageLinked(LINK_SET,LM_SETTING_DELETE, "folders_locks","");
                    //llSay(0, "FOLDER LOCKS DEBUG RESTORE ("+sVal+")");
                    g_lFolderLocks = llParseString2List(llBase64ToString(sVal), ["~!~"],[]);
                }
            }
        } else if(iNum == REBOOT){
            //llSay(0, "FOLDER LOCKS DEBUG UPDATE (INACTIVE)");
            g_iInUpdate=FALSE;
        }
    }
}
