/*
    _____________________________.
   |;;|                      |;;||     Copyright (c) 2008 - 2016:
   |[]|----------------------|[]||
   |;;|     Collar Lead      |;;||     Ilse Mannonen
   |;;|       161024.1       |;;||     Wendy Starfall
   |;;|----------------------|;;||     Garvin Twine
   |;;|   www.opencollar.at  |;;||
   |;;|----------------------|;;||
   |;;|______________________|;;||
   |;;;;;;;;;;;;;;;;;;;;;;;;;;;;||     This script is free software:
   |;;;;;;;_______________ ;;;;;||
   |;;;;;;|  ___          |;;;;;||     You can redistribute it and/or
   |;;;;;;| |;;;|         |;;;;;||     modify it under the terms of the
   |;;;;;;| |;;;|         |;;;;;||     GNU General Public License as
   |;;;;;;| |;;;|         |;;;;;||     published by the Free Software
   |;;;;;;| |___|         |;;;;;||     Foundation, version 2.
   \______|_______________|_____||
    ~~~~~~^^^^^^^^^^^^^^^^^^~~~~~~     www.gnu.org/licenses/gpl-2.0

github.com/VirtualDisgrace/opencollar/blob/master/src/spares/.lead.lsl

*/

integer g_iMychannel = -8888;
string g_sListenfor;
string g_sResponse;
string g_sWearerID;
integer g_i;

FailSafe() {
    string sName = llGetScriptName();
    integer iFullPerms = PERM_MODIFY | PERM_COPY | PERM_TRANSFER;
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY) 
    || !(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)
    || !((llGetInventoryPermMask(sName,MASK_OWNER) & iFullPerms) == iFullPerms)
    || !((llGetInventoryPermMask(sName,MASK_NEXT) & iFullPerms) == iFullPerms)) 
        llRemoveInventory(sName);
}

default {
    state_entry() {
        llSetMemoryLimit(10240);
        g_sWearerID = (string)llGetOwner();
        FailSafe();
        g_sListenfor = g_sWearerID + "handle";
        g_sResponse = g_sWearerID + "handle ok";
        llListen(g_iMychannel, "", NULL_KEY, g_sListenfor);
        llSay(g_iMychannel, g_sResponse);
        llSetTimerEvent(2.0);         
    }
    
    listen(integer channel, string name, key id, string message) {
        llSay(g_iMychannel, g_sResponse);
        llSetTimerEvent(2.0);
    }
    attach(key kAttached) {
        if (kAttached == NULL_KEY)
            llSay(g_iMychannel, g_sWearerID+"handle detached");
    }
    changed(integer change) {
        if (change & CHANGED_INVENTORY) FailSafe();
        if (change & CHANGED_TELEPORT) {
            llSay(g_iMychannel, g_sResponse);
            llSetTimerEvent(2.0);
        }
    }
    timer() {
        if (g_i) {
            g_i = FALSE;
            llSetTimerEvent(0.0);
            llSay(g_iMychannel, g_sResponse);
        } else {
            g_i = TRUE;
            llSay(g_iMychannel, g_sResponse);
        }
    }
    on_rez(integer param) {
        llResetScript();
    }
}
