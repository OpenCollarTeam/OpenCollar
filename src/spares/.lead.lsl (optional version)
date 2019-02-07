// This file is part of OpenCollar.
// Copyright (c) 2008-2016 Ilse Mannonen, Garvin Twine, Wendy Starfall, Mailani19 Resident.
// Licensed under the GPLv2.  See LICENSE for full details. 
// This optional variant of the lead script prevents the leash going to the leash holder's collar if the leash holder 
// also wears a collar.

integer g_iMychannel = -8888;
string g_sResponse;
string g_sWearerID;

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


default
{
    state_entry()
    {
        g_sWearerID = (string)llGetOwner();
        PermsCheck();
        g_sResponse = g_sWearerID + "handle ok";
        llSetTimerEvent(5.0);
    }   
    attach(key kAttached)
    {
        if (kAttached == NULL_KEY)
        llSay(g_iMychannel, g_sWearerID+"handle detached");
    }
    timer()
        {
        llSay(g_iMychannel, g_sResponse);
        }
    on_rez(integer param)
        {
           llResetScript();
        }
}
