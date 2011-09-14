// This is the master updater script.  It complies with the update handshake protocol that OC
// has been using for quite some time, and should therefore be compatible with current OC collars.
// the internals of this script, and the the other parts of the new updater, have been completely re-written.
// Don't expect this to work like the old updater.  Because we load an update shim script right after handshaking, 
// we're free to rewrite everything that comes after the handshake.

// In addition to the handshake and shim installation, this script decides which bundles should be installed into 
// (or removed from) the collar.  It loops over each bundle in inventory, telling the BundleGiver script to install
// or remove each.

integer initChannel = -7483214;
integer iSecureChannel;

// store the script pin here when we get it from the collar.
integer iPin;

// the collar's key
key kCollarKey;

// strided list of bundles in the prim and whether they are supposed to be 
// installed.
list lBundles;

// here we remember the index of the bundle that's currently being installed/removed
// by the bundlegiver.
integer iBundleIdx;

// handle for our dialogs
key kDialogID;

integer DO_BUNDLE = 98749;
integer BUNDLE_DONE = 98750;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

// A wrapper around llSetScriptState to avoid the problem where it says it can't
// find scripts that are already not running.
DisableScript(string name) {
    if (llGetInventoryType(name) == INVENTORY_SCRIPT) {
        if (llGetScriptState(name) != FALSE) {
            llSetScriptState(name, FALSE);
        }
    }
}

DoBundle() {
    // tell bundle slave to load the bundle.
    string card = llList2String(lBundles, iBundleIdx);
    string mode = llList2String(lBundles, iBundleIdx + 1);
    string bundlemsg = llDumpList2String([iSecureChannel, kCollarKey, card, iPin, mode], "|");
    llMessageLinked(LINK_SET, DO_BUNDLE, bundlemsg, "");    
}

key ShortKey()
{//just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sChars = "0123456789abcdef";
    integer iLength = 16;
    string sOut;
    integer n;
    for (n = 0; n < 8; n++)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString(sChars, iIndex, iIndex);
    }
     
    return (key)(sOut + "-0000-0000-0000-000000000000");
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage)
{
    key kID = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    return kID;
}

SetBundleStatus(string bundlename, string status) {
    // find the bundle in the list
    integer n;
    integer stop = llGetListLength(lBundles);
    for (n = 0; n < stop; n += 2) {
        string card = llList2String(lBundles, n);
        list parts = llParseString2List(card, ["_"], []);
        string name = llList2String(parts, 2);
        if (name == bundlename) {
            lBundles = llListReplaceList(lBundles, [status], n + 1, n + 1);
            return;
        }
    }
}

BundleMenu(integer page) {
    // Give the plugin selection/start menu.
    
    string prompt = "Add/remove plugins by clicking the buttons below.";
    prompt += "\nClick START when you're ready to update.";
    prompt += "\nCurrent: ";
    
    
    // build list of buttons from list of bundles
    integer n;
    integer stop = llGetListLength(lBundles);
    list choices;
    for (n = 0; n < stop; n += 2) {
        string card = llList2String(lBundles, n);
        string status = llList2String(lBundles, n + 1);
        list parts = llParseString2List(card, ["_"], []);
        string name = llList2String(parts, 2);
        
        prompt += "\n" + name + ":" + status;
        if (status == "INSTALL") {
            choices += ["- " + name];
        } else if (status == "REQUIRED") {
            choices += ["* " + name];                            
        } else if (status == "REMOVE") {
            choices += ["+ " + name];                            
        }
    }
    kDialogID = Dialog(llGetOwner(), prompt + "\n", choices, ["START"], page);
}

Debug(string str) {
     //llOwnerSay(llGetScriptName() + ": " + str);
}

default {
    state_entry() {
        llListen(initChannel, "", "", "");
        
        // set all scripts except self to not running
        // also build list of all bundles
        integer n;
        integer stop = llGetInventoryNumber(INVENTORY_ALL);
        for (n = 0; n < stop; n++) {
            string name = llGetInventoryName(INVENTORY_ALL, n);
            integer type = llGetInventoryType(name);
            if (type == INVENTORY_SCRIPT) {
                // ignore updater scripts.  set others to not running.
                if (llSubStringIndex(name, "OpenCollarUpdater") != 0) {
                    DisableScript(name);
                }                
            } else if (type == INVENTORY_NOTECARD) {
                // add card to bundle list if it's a bundle
                if (llSubStringIndex(name, "BUNDLE_") == 0) {
                    list parts = llParseString2List(name, ["_"], []);
                    lBundles += [name, llList2String(parts, -1)];
                }
            }
        }
        
        llSetText("1 - Rez your collar next to me.\n" +
                  "2 - Touch the collar.\n" + 
                  "3 - In the menu, select Help/Debug > Update."
                   , <1,1,1>, 1.0);
    }
    
    listen(integer channel, string name, key id, string msg) {
        if (llGetOwnerKey(id) == llGetOwner()) {
            Debug(llDumpList2String([name, msg], ", "));
            if (channel == initChannel) {
                // everything heard on the init channel is stuff that has to comply with the existing update
                // kickoff protocol.  New stuff will be heard on the random secure channel instead.
                list parts = llParseString2List(msg, ["|"], []);
                string cmd = llList2String(parts, 0);
                string param = llList2String(parts, 1);
                if (cmd == "UPDATE") {
                    // someone just clicked the upgrade button on their collar.
                    llWhisper(initChannel, "get ready");
                } else if (cmd == "ready") {
                    // person clicked "Yes I want to update" on the collar menu.
                    // the script pin will be in the param
                    iPin = (integer)param;     
                    kCollarKey = id;                                   
                    BundleMenu(0);                    
                }                
            } else if (channel == iSecureChannel) {
                //llOwnerSay("SECURE: " + msg);
                if (msg == "reallyready") {
                    iBundleIdx = 0;
                    DoBundle();       
                }
            }
        }
    }
    
    // when we get a BUNDLE_DONE message, move to the next bundle
    link_message(integer sender, integer num, string str, key id) {
        if (num == DIALOG_RESPONSE) {
            if (id == kDialogID) {
                list parts = llParseString2List(str, ["|"], []);
                key av = (key)llList2String(parts, 0);
                string button = llList2String(parts, 1);
                integer page = (integer)llList2String(parts, 2);
                if (button == "START") {
                    // so let's load the shim.
                    string shim = "OpenCollar - UpdateShim";
                    iSecureChannel = (integer)llFrand(-2000000000 + 1);
                    llListen(iSecureChannel, "", kCollarKey, "");
                    llRemoteLoadScriptPin(kCollarKey, shim, iPin, TRUE, iSecureChannel);                                        
                } else {
                    // switch the bundle if appropriate
                    list buttonparts = llParseString2List(button, [" "], []);
                    string status = llList2String(buttonparts, 0);
                    string bundlename = llDumpList2String(llDeleteSubList(buttonparts, 0, 0), " ");
                    if (status == "*") {
                        llOwnerSay("The " + bundlename + " bundle is required and cannot be removed.");
                    } else if (status == "-") {
                        // if the button said +, that means we need to switch it to -
                        // find the bundle in the list, and set to REMOVE
                        SetBundleStatus(bundlename, "REMOVE");
                        llOwnerSay(bundlename + " will be removed.");
                    } else if (status == "+") {
                        SetBundleStatus(bundlename, "INSTALL");
                        llOwnerSay(bundlename + " will be installed.");
                    }
                    BundleMenu(page);
                }
            }
        } else if (num == BUNDLE_DONE) {
            // see if there's another bundle
            integer count = llGetListLength(lBundles);
            iBundleIdx += 2;
            if (iBundleIdx < count) {
                DoBundle();
            } else {
                // tell the shim to restore settings, set version, 
                // remove the script pin, and delete himself.
                string myversion = llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 1);
                llRegionSayTo(kCollarKey, iSecureChannel, "CLEANUP|" + myversion);
            }
        }
    }
    
    on_rez(integer param) {
        llResetScript();
    }
    
    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}
