// This file is part of OpenCollar.
// Copyright (c) 2016 - 2017 Garvin Twine, Nirea Resident
// Licensed under the GPLv2.  See LICENSE for full details. 


// oc remote - LeashPost rez script 160112.1
// leashpost sends out a anchor to me command to all ID transmitted by the hud
// Otto(garvin.twine) 2016

integer g_iListener;

integer RemoteChannel(string sID,integer iOffset) {
    integer iChan = -llAbs((integer)("0x"+llGetSubString(sID,-7,-1)) + iOffset);
    return iChan;
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}


default {
    on_rez(integer iStart) {
        llResetScript();
    }

    state_entry() {
        llSetMemoryLimit(16384);
        PermsCheck();
        g_iListener = llListen(RemoteChannel(llGetOwner(),1234),"","","");
        list lTemp = llParseString2List(llGetObjectDesc(),["@"],[]);
        vector vRot = (vector)("<"+llList2String(lTemp,1)+">");
        vector vPos = (vector)("<"+llList2String(lTemp,2)+">");
        llSetRot(llEuler2Rot(vRot * DEG_TO_RAD));
        llSetPos(llGetPos()+vPos);
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        llListenRemove(g_iListener);
        string sObjectID = (string)llGetKey();
        list lToLeash = llParseString2List(sMessage,[","],[]);
        integer i = llGetListLength(lToLeash);
        key kLeashToID;
        while (i) {
            kLeashToID = llList2Key(lToLeash,--i);
            llRegionSayTo(kLeashToID,RemoteChannel(kLeashToID,0),"anchor "+sObjectID);
        }
    }
    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) PermsCheck();
    }
}
