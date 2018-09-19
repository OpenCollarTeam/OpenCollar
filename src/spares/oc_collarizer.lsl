// This file is part of OpenCollar.
// Copyright (c) 2017 nirea Resident.
// Licensed under the GPLv2.  See LICENSE for full details.

// This script can be used in combination with an OpenCollar Updater (7.0 or
// later) to turn any unscripted object into a fully functioning OpenCollar
// device.

// Instructions:
// 1. Make sure your unscripted object allows the "Modify" permission for the next owner.
// 2. (Optional) If you want your object to support OpenCollar's hover text
//    titler feature, make a prim with the word "FloatText" in its "Description"
//    field.  Link it to your unscripted object, near the center, as a child
//    prim.
// 3. Rez an OpenCollar Updater (7.0 or later) near your unscripted object.
// 4. Drop this script into the root prim of your unscripted object.  When asked
//    for permission to link objects, click Yes.
//
// Several new child prims will be rezzed and linked to your object.  Then a
// regular OpenCollar update process will be performed.  At the end, you may
// wish to reposition the newly-rezzed child prims, particularly the leashpoint
// one.

integer g_iUpdateChan = -7483214;

default {
    state_entry() {
        llListen(g_iUpdateChan, "", "", "get ready");
        llWhisper(g_iUpdateChan, "UPDATE");
        llSetTimerEvent(30);
    }

    listen(integer iChannel, string sName, key kId, string sMsg) {
        if (llGetOwnerKey(kId) != llGetOwner()) {
            return;
        }

        llOwnerSay("Commencing collarization!");
        integer iPin = (integer)llFrand(99999998.0) + 1; // Set a random pin
        llSetRemoteScriptAccessPin(iPin);
        llRegionSayTo(kId, g_iUpdateChan, "ready|" + (string)iPin);
        llRemoveInventory(llGetScriptName());
    }

    timer() {
        // If we haven't gotten started by now, clean ourself up
        llRemoveInventory(llGetScriptName());
    }
}
