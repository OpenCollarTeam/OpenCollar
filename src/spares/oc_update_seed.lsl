// This file is part of OpenCollar.
// Copyright (c) 2017 nirea Resident.
// Licensed under the GPLv2.  See LICENSE for full details.

// This script can be used to upgrade a 6.6/6.7 collar to the official release from the OpenCollar group.
// To use, do the following:
// 1. Rez the OpenCollar Updater nearby.
// 2. Wear your 6.6/6.7 collar.
// 3. Edit your 6.6/6.7 collar and drop this script inside it.
// The update will begin immediately.

integer g_iUpdateChan = -7483213;

default {
    state_entry() {
        llOwnerSay("Initializing update.");
        llListen(g_iUpdateChan, "", "", "");
        llWhisper(g_iUpdateChan, "UPDATE|6.0");
        llSetTimerEvent(30);
    }

    listen(integer iChannel, string sName, key kId, string sMsg) {
        if (llGetOwnerKey(kId) != llGetOwner()) {
            return;
        }

        if (llSubStringIndex(sMsg, "-.. ---|") == 0) { // Why morse code? sigh. Let's keep things readable, people.
            llOwnerSay("Updater found.  Beginning update!");
            integer iPin = (integer)llFrand(99999998.0) + 1; // Set a random pin
            llSetRemoteScriptAccessPin(iPin);
            llRegionSayTo(kId, g_iUpdateChan, "ready|" + (string)iPin);
            llRemoveInventory(llGetScriptName());
        }
    }

    timer() {
        // If we haven't gotten started by now, clean ourself up
        llRemoveInventory(llGetScriptName());
    }
}
