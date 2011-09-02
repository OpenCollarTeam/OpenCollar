// this script receives DO_BUNDLE messages that contain the uuid of the collar being updated, 
// the name of a bundle notecard, the talkchannel on which the collar shim script is listening, and
// the script pin set by the shim.  This script then loops over the items listed in the notecard
// and chats with the shim about each one.  Items that are already present (as determined by uuid) 
// are skipped.  Items not present are given to the collar.  Items that are present but don't have the
// right uuid are deleted and replaced with the version in the updater.  Scripts are loaded with 
// llRemoteLoadScriptPin, and are set running immediately.

// once the end of the notecard is reached, this script sends a BUNDLE_DONE message that includes all the same 
// stuff it got in DO_BUNDLE (talkchannel, recipient, card, pin).

integer DO_BUNDLE = 98749;
integer BUNDLE_DONE = 98750;

integer talkchannel;
key rcpt;
string card;
integer pin;
string mode;

integer line;
key lineid;
integer listener;

list g_lScripts;

// Return the name and version of an item as a list.
list GetNameParts(string name) {
    list nameparts = llParseString2List(name, [" - "], []);
    string shortname = llDumpList2String(llDeleteSubList(nameparts, -1, -1), " - ");
    string version;
    if (llGetListLength(nameparts) > 1) {
        version = llList2String(nameparts, -1);
    } else {
        version = "";
    }
    return [shortname, version];
}

string GetScriptFullname(string name) {
    integer idx = llListFindList(g_lScripts, [name]);
    if (idx == -1) {
        llSay(DEBUG_CHANNEL, "Script " + name + " not found.");
        return (key)"";
    }
    
    string version = llList2String(g_lScripts, idx + 1);
    return llDumpList2String([name, version], " - ");    
}

// Given the name (but not version) of a script, look it up in our list and return the key
// returns "" if not found.
key GetScriptKey(string name) {

    return llGetInventoryKey(GetScriptFullname(name));
}

SetStatus(string name) {
    // use card name, item type, and item name to set a nice 
    // text status message
    list cardparts = llParseString2List(card, [":"], []);
    string bundle = llList2String(cardparts, 2);
    string msg = llDumpList2String([
        "Doing Bundle: " + bundle,
        "Doing Item: " + name
    ], "\n");
    llSetText(msg, <1,1,1>, 1.0);
}

default
{
    state_entry() {
        // build script list
        integer n;
        integer stop = llGetInventoryNumber(INVENTORY_SCRIPT);
        for (n = 0; n < stop; n++) {
            string name = llGetInventoryName(INVENTORY_SCRIPT, n);
            // add to script list
            g_lScripts += GetNameParts(name);
        }        
    }
    
    link_message(integer sender, integer num, string str, key id) {
        if (num == DO_BUNDLE) {
            // str will be in form talkchannel|uuid|bundle_card_name
            list parts = llParseString2List(str, ["|"], []);
            talkchannel = (integer)llList2String(parts, 0);
            rcpt = (key)llList2String(parts, 1);
            card = llList2String(parts, 2);
            pin = (integer)llList2String(parts, 3);
            mode = llList2String(parts, 4); // either INSTALL or REMOVE
            line = 0;
            llListenRemove(listener);
            listener = llListen(talkchannel, "", rcpt, "");
            
            // get the first line of the card
            lineid = llGetNotecardLine(card, line);
        }
    }
    
    dataserver(key id, string data) {
        if (id == lineid) {
            if (data != EOF) {
                // process bundle line
                list parts = llParseString2List(data, ["|"], []);
                string type = llList2String(parts, 0);
                string name = llList2String(parts, 1);
                key uuid;
                string msg;
                
                SetStatus(name);
                
                if (type == "SCRIPT") {
                    // special handling because scripts have version numbers that we want to ignore.
                    uuid = GetScriptKey(name);
                } else if (type == "ITEM") {
                    uuid = llGetInventoryKey(name);
                }
                msg = llDumpList2String([type, name, uuid, mode], "|");                
                llRegionSayTo(rcpt, talkchannel, msg);
            } else {
                // all done reading the card. send link msg to main script saying we're done.
                llListenRemove(listener);
                llSetText("", <1,1,1>, 1.0);
                llMessageLinked(LINK_SET, BUNDLE_DONE, llDumpList2String([talkchannel, rcpt, card, pin, mode], "|"), "");
            }
        }
    }
    
    listen(integer channel, string name, key id, string msg) {
        // let's live on the edge and assume that we only ever listen with a uuid filter so we know it's safe
        // look for msgs in the form <type>|<name>|<cmd>
        list parts = llParseString2List(msg, ["|"], []);
        if (llGetListLength(parts) == 3) {
            string type = llList2String(parts, 0);
            string name = llList2String(parts, 1);
            string cmd = llList2String(parts, 2);            
            if (cmd == "SKIP" || cmd == "OK") {
                // move on to the next item by reading the next notecard line
                line++;
                lineid = llGetNotecardLine(card, line);
            } else if (cmd == "GIVE") {
                // give the item, and then read the next notecard line.
                if (type == "ITEM") {
                    llGiveInventory(id, name);
                } else if (type == "SCRIPT") {
                    // get the full name, and load it via script pin.
                    string script_name = GetScriptFullname(name);
                    llRemoteLoadScriptPin(id, script_name, pin, TRUE, 0);
                }
                line++;
                lineid = llGetNotecardLine(card, line);
            }
        }
    }
    
    on_rez(integer num) {
        llResetScript();
    }
    
    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}

