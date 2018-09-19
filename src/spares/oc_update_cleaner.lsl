// This file is part of OpenCollar.
// Copyright (c) 2011 - 2015 Nandana Singh, Satomi Ahn, Wendy Starfall,
// littlemousy et al.
// Licensed under the GPLv2.  See LICENSE for full details.

// This script exists to clean up some legacy cruft in old collars:
// - delete the hovertext script that is in a child prim
// - delete the mis-named "OpenCollar - remoteserver- 3.481" script (missing a space in the name pattern)

// The items we want to delete are identified by having these strings in their names

list g_lGarbage = [
    "hovertext@",
    "OpenCollar - remoteserver-"
];

// Allow this many seconds to hear back from child prims before
// removing self from root prim inventory
integer g_iDeathTimer = 3;

integer UPDATE = 10001;

/*
integer g_bProfiled;
Debug(string sStr) {
    // If you delete the first // from the preceeding and following  lines,
    // profiling is off, debug is off, and the compiler will remind you to
    // remove the debug calls from the code, we're back to production mode
    if (!g_bProfiled) {
        g_bProfiled = TRUE;
        llScriptProfiler(TRUE);
    }
    llOwnerSay(llGetScriptName() + "(min free:" + (string)(llGetMemoryLimit() - llGetSPMaxMemory()) + ")[" + (string)llGetFreeMemory() + "] :\n" + sStr);
}
*/

// Function that will look at all items in the prim and delete any
// whose names contain the pattern.
DelMatchingItems(string sPattern) {
    integer n;
    // Loop from the top down so we don't screw up inventory numbers as we delete
    for (n = llGetInventoryNumber(INVENTORY_ALL); n >= 0; n--) {
        string sName = llGetInventoryName(INVENTORY_ALL, n);
        // Look for match but don't delete self.
        if (llSubStringIndex(sName, sPattern) != -1 && sName != llGetScriptName()) {
            // Found the item we're looking for. Remove!
            llRemoveInventory(sName);
            //Debug("found " + sName);
        }
    }
}

DelItems(list lItems) {
    integer n;
    integer iStop = llGetListLength(lItems);
    for (n = 0; n < iStop; n++) {
        string sPattern = llList2String(lItems, n);
        DelMatchingItems(sPattern);
    }
}

default {
    state_entry() {
        // Don't run cleanup if placed in an updater
        if (llSubStringIndex(llGetObjectName(), "Updater") != -1) {
            //Debug("In an updater.  Sleeping.");
            llSetScriptState(llGetScriptName(), FALSE);
        }

        key kTransKey = "bd7d7770-39c2-d4c8-e371-0342ecf20921";
        integer iPrimNumber = llGetNumberOfPrims() + 1;
        while (iPrimNumber--) {
            integer iNumOfSides = llGetNumberOfSides();
            while (iNumOfSides--) {
                key kTexture = llList2String(llGetLinkPrimitiveParams(iPrimNumber, [PRIM_TEXTURE, iNumOfSides]), 0);
                if (kTexture == kTransKey || kTexture == TEXTURE_PLYWOOD || kTexture == "!totallytransparent") {
                    llSetLinkPrimitiveParamsFast(iPrimNumber, [
                        PRIM_TEXTURE, iNumOfSides, TEXTURE_TRANSPARENT, <1.0, 1.0, 1.0>, <0.0, 0.0, 0.0>, 0
                    ]);
                }
            }
        }

        DelItems(g_lGarbage);

        if (llGetLinkNumber() > 1) {
            // In a child prim.
            // Since we already cleaned up, we can just die now
            llRemoveInventory(llGetScriptName());
        } else {
            // If in root prim, then ping for scripts in child prims.
            llMessageLinked(LINK_SET, UPDATE, "prepare", "");

            // And set the death timer
            llSetTimerEvent(g_iDeathTimer);
        }
        //Debug("starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kId) {
        //Debug(llDumpList2String([sender, num, str, id], ", "));
        if (iNum == UPDATE) {
            // If a child script responds with a script pin, clone self there.
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llGetListLength(lParts) > 1) {
                integer iPin = (integer)llList2String(lParts, 1);
                key kPrim = llGetLinkKey(iSender);
                if (iPin > 0) {
                    llRemoteLoadScriptPin(kPrim, llGetScriptName(), iPin, TRUE, 1);
                }
            }
        }
    }

    timer() {
        //Debug("timer");
        llRemoveInventory(llGetScriptName());
    }

    /*
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_bProfiled) {
                llScriptProfiler(TRUE);
                Debug("profiling restarted");
            }
        }
    }
    */
}
