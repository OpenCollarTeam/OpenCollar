// This file is part of OpenCollar.
// Copyright (c) 2013 - 2015 Toy Wylie et. al
// Licensed under the GPLv2.  See LICENSE for full details.


// Needs OpenCollar 6.x or higher to work

// Sends a "<wearer_uuid>:ping" message on the collar command channel:
// Collar answers with "<wearer_uuid>:pong"
// Sends a anchor command on the collar command channel to grab them

// Constants
float RANGE = 20.0; // Scanning range
float TIMEOUT = 30.0; // Menu timeout
float WAIT_TIME = 2.0; // waiting time after the last confirmed collar
float LEASH_LENGTH = 2.5; // Leash length when grabbing

// menu system
integer g_iMenuListener = 0;
integer g_iMenuChannel = 0;
key g_kMenuUser = NULL_KEY;
integer g_bScanning = FALSE;

list g_lVictimNames = []; // List of victim names
list g_lVictimKeys = []; // Corresponding list of keys
list g_lListeners = []; // Collar pong listeners per victim

//===============================================================================
//= parameters   :    key owner            key of the person to send the sMessage to
//=                    integer nOffset        Offset to make sure we use really a unique channel
//=
//= description  : Function which calculates a unique channel iNumber based on the owner key, to reduce lag
//=
//= returns      : Channel iNumber to be used
//===============================================================================
integer PersonalChannel(string sID, integer iOffset) {
    return -llAbs((integer)("0x" + llGetSubString(sID, -7, -1)) + iOffset);
}

// Resets the menu dialog
ResetDialog() {
    // Clear out any remaining collar listeners
    integer iNum = llGetListLength(g_lListeners);
    integer iIndex;
    for (; iIndex < iNum; iIndex++) {
        llListenRemove(llList2Integer(g_lListeners, iIndex));
    }
    g_lListeners = [];

    // Clear out menu system data if needed
    if (g_iMenuListener) {
        llListenRemove(g_iMenuListener);
        g_iMenuListener = 0;
        g_kMenuUser = NULL_KEY;

        llSetTimerEvent(0.0);
        g_lVictimNames = [];
        g_lVictimKeys = [];
    }
}

// Send "No victims found" message to a person
NotFound(key kId) {
    llRegionSayTo(kId, 0, "No victims were found within " + (string)((integer)RANGE) + " m.");
}

// Leash a victim
Leash(key kId) {
    integer iChannel = PersonalChannel((string)kId, 0);
    llRegionSayTo(kId, iChannel, "length " + (string)LEASH_LENGTH);
    llRegionSayTo(kId, iChannel, "anchor " + (string)llGetKey());
}

default {
    state_entry() {
    }

    touch_start(integer iNum) {
        key kToucher = llDetectedKey(0);

        // Lock the menu to the current menu user
        if(g_iMenuListener != 0 && g_kMenuUser != kToucher) {
            llRegionSayTo(kToucher, 0, "This menu is currently in use. Plesase wait a moment before trying again.");
            return;
        }

        // Don't allow menu usage while scanning for collars
        if(g_bScanning) {
            llRegionSayTo(kToucher, 0, "There is already a scan in progress, please wait for it to finish.");
            return;
        }

        // Start with a fresh menu
        ResetDialog();

        // Remember menu user, get a new channel and set up listener
        g_kMenuUser = kToucher;
        g_iMenuChannel = -((integer)llFrand(1000000.0) + 100000);
        g_iMenuListener = llListen(g_iMenuChannel, "", g_kMenuUser, "");

        // Display the menu
        llDialog(g_kMenuUser, "Do you want to scan for nearby victims?\n\nScan radius is " + (string)((integer)RANGE) + " m", ["Scan", " ", "Cancel"], g_iMenuChannel);

        // Menu timeout
        llSetTimerEvent(TIMEOUT);
    }

    timer() {
        // If not scanning this was a menu timeout
        if(!g_bScanning) {
            ResetDialog();
            return;
        }

        // Reset scanning mode
        llSetTimerEvent(0.0);
        g_bScanning = FALSE;

        // Check if anyone was picked up at all
        if(g_lVictimNames == []) {
            NotFound(g_kMenuUser);
            ResetDialog();
            return;
        }

        // Cut button list so llDialog doesn't fail
        g_lVictimNames = llList2List(g_lVictimNames, 0, 9);
        g_lVictimKeys = llList2List(g_lVictimKeys, 0, 9);

        // List potential victims, watch 500 character limit on llDialog
        string sBody = llGetSubString("Select a target, or \"All\" to grab all those listed:\n\n" + llDumpList2String(g_lVictimNames, "\n"), 0, 500);

        // Show list of potential victims
        llDialog(g_kMenuUser, sBody, ["All", "Cancel"] + g_lVictimNames, g_iMenuChannel);

        // Menu timeout
        llSetTimerEvent(TIMEOUT);
    }

    listen(integer iChannel, string sName, key kId, string sMessage) {
        // Process menu button replies
        if (iChannel == g_iMenuChannel) {
            // Scan for victims
            if (sMessage == "Scan") {
                llRegionSayTo(g_kMenuUser, 0, "Scanning for OpenCollar compatible victims, please wait ...");
                llSensor("", NULL_KEY, AGENT, RANGE, PI);

                // Set up scanning mode
                g_bScanning = TRUE;
                return;
            } else if (sMessage == "All") { // Grab all victims
                integer iNum = llGetListLength(g_lVictimKeys);
                integer iIndex;
                for(; iIndex < iNum; iIndex++) {
                    Leash(llList2Key(g_lVictimKeys, iIndex));
                }
            } else if (sMessage != "Cancel") { // Clicked on a name or empty button
                // Grab selected victim, if available in the list
                integer iPos = llListFindList(g_lVictimNames, [sMessage]);
                if(~iPos) {
                    Leash(llList2Key(g_lVictimKeys, iPos));
                }
            }

            // Reset menu
            ResetDialog();
            return;
        }

        // Not a menu listener event, so this is a collar pong
        key kWearer = llGetOwnerKey(kId);

        // Check for proper "<key>:pong" message
        if (sMessage == ((string)kWearer + ":pong")) {
            // Get the collar wearer's name
            string sWearerName = llKey2Name(kWearer);

            // Cut to max. 24 characters and add to the list of names
            g_lVictimNames += llGetSubString(sWearerName, 0, 23);
            // Add to the list of keys
            g_lVictimKeys += kWearer;

            // Reset waiting time
            llSetTimerEvent(WAIT_TIME);
        }
    }

    no_sensor() {
        // Nobody in scanning range
        NotFound(g_kMenuUser);
        ResetDialog();
    }

    sensor(integer iNum) {
        key kId;
        integer iChannel;
        integer iIndex;

        // Go through the list of scanned avatars
        for(; iIndex < iNum; iIndex++) {
            kId = llDetectedKey(iIndex);

            // Do not include scanning user in the list
            if(kId != g_kMenuUser) {
                // Calculate collar channel per victim and add a listener
                iChannel = PersonalChannel((string)kId, 0);
                g_lListeners += llListen(iChannel, "", NULL_KEY, "");

                // Ping victim's collar
                llRegionSayTo(kId, iChannel, (string)kId + ":ping");
            }
        }

        // initial waiting time after sending collar pings
        llSetTimerEvent(WAIT_TIME);
    }

    collision_start(integer iNum) {
        // Grab bumping avatar
        Leash(llDetectedKey(0));
    }
}
