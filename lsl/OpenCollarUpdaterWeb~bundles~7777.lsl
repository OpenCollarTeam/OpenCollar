// This is the master updater script.  It complies with the update handshake
// protocol that OC has been using for quite some time, and should therefore be
// compatible with current OC collars.  the internals of this script, and the
// the other parts of the new updater, have been completely re-written.  Don't
// expect this to work like the old updater.  Because we load an update shim
// script right after handshaking, we're free to rewrite everything that comes
// after the handshake.

// In addition to the handshake and shim installation, this script decides
// which bundles should be installed into (or removed from) the collar.  It
// loops over each bundle in inventory, telling the BundleGiver script to
// install or remove each.

// This script also does a little bit of magic to ensure that the updater's
// version number always matches the contents of the "~version" card.
integer GIVE_LINK = -349857;

key version_line_id;

integer initChannel = -7483214;
integer iSecureChannel;

// a few things needed for the json interface
integer mychannel;
integer HTTP_RESPONSE = -85432;
string NAMESEP = "~";


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

integer DO_BUNDLE = 98749;
integer BUNDLE_DONE = 98750;

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
        
string PrettyCardName(string ugly) {
    list parts = llParseString2List(ugly, ["_"], []);
    return llList2String(parts, 2);        
}

Debug(string str) {
     //llOwnerSay(llGetScriptName() + ": " + str);
}

ReadVersionLine() {
    // try to keep object's version in sync with "~version" notecard.
    if (llGetInventoryType("~version") == INVENTORY_NOTECARD) {
        version_line_id = llGetNotecardLine("~version", 0);
    }
}

SetInstructionsText() {
    llSetText("1 - Rez your collar next to me.\n" +
              "2 - Touch the collar.\n" + 
              "3 - In the menu, select Help/Debug > Update."
               , <1,1,1>, 1.0);
}

Particles(key target) {
    llParticleSystem([ 
        PSYS_PART_FLAGS, 
            PSYS_PART_INTERP_COLOR_MASK |
            PSYS_PART_INTERP_SCALE_MASK |
            PSYS_PART_TARGET_POS_MASK |
            PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_SRC_TEXTURE, "aa383f73-8be2-c693-acf0-9b8be8b4a155",
        PSYS_SRC_TARGET_KEY, target,
        PSYS_PART_START_SCALE, <0.68, 0.64, 0>,
        PSYS_PART_END_SCALE, <0.04, 0.04, 0>,
        PSYS_PART_START_ALPHA, 0.1,
        PSYS_PART_END_ALPHA, 1,
        PSYS_SRC_BURST_PART_COUNT, 4,
        PSYS_PART_MAX_AGE, 2,
        PSYS_SRC_BURST_SPEED_MIN, 0.2,
        PSYS_SRC_BURST_SPEED_MAX, 1
    ]);
}

string Strided2JSON(list strided)
{//takes a 2-strided list and returns a JSON-formatted string representing the list as an object
    list outlist;
    integer n;
    integer stop = llGetListLength(strided);
    for (n = 0; n < stop; n += 2)
    {
        string token = llList2String(strided, n);
        string value = llList2String(strided, n + 1);
        integer type = llGetListEntryType(strided, n + 1);
        if (type != TYPE_INTEGER && type != TYPE_FLOAT)
        {//JSON needs quotes around everything but integers and floats
            value = "\"" + value + "\"";
        }
        token = "\"" + token + "\"";
        
        outlist += [token + ": " + value];
    }
    return "{" + llDumpList2String(outlist, ", ") + "}";
}

string GetCallback(string qstring) {
    list qparams = llParseString2List(qstring, ["&", "="], []);
    return GetParam(qparams, "callback");
}

string WrapCallback(string resp, string callback) {
    return callback + "(" + resp + ")";
}

string GetParam(list things, string tok) {
    //return "-1" if not found
    integer index = llListFindList(things, [tok]);
    if (index == -1) {
        return "-1";
    } else {
        return llList2String(things, index + 1);
    }
}

string List2JS(list things) {
    string inner = llDumpList2String(things, ",");
    return "[" + inner + "]";
}    
    
string GetBundlesJSON(string status) {
    list bundlestrings = [];
    integer n;
    integer stop = llGetListLength(lBundles);
    for (n = 0; n < stop; n += 2) {
        string card = llList2String(lBundles, n);
        bundlestrings += Strided2JSON([
            "card", card,
            "status", llList2String(lBundles, n + 1),
            "name", PrettyCardName(card)
        ]);
    }
    return "{\"bundles\":" + List2JS(bundlestrings)
            + ", \"updatestatus\":" + "\"" + status + "\""
            + ", \"name\":" + "\"" + llGetObjectName() + "\""            
         + "}";
    
}
    
StartUpdate() {
    // so let's load the shim.
    string shim = "OpenCollar - UpdateShim";
    iSecureChannel = (integer)llFrand(-2000000000 + 1);
    llListen(iSecureChannel, "", kCollarKey, "");
    llRemoteLoadScriptPin(kCollarKey, shim, iPin, TRUE, iSecureChannel);                                            
}

default {
    state_entry() {
        ReadVersionLine();
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
        SetInstructionsText();
        llParticleSystem([]);
        
        // init the web stuff
        //set my channel from my script name
        string myname = llGetScriptName();
        list parts = llParseString2List(myname, [NAMESEP], []);
        mychannel = (integer)llList2String(parts, -1);          
    }

    listen(integer channel, string name, key id, string msg) {
        if (llGetOwnerKey(id) == llGetOwner()) {
            Debug(llDumpList2String([name, msg], ", "));
            if (channel == initChannel) {
                // everything heard on the init channel is stuff that has to
                // comply with the existing update kickoff protocol.  New stuff
                // will be heard on the random secure channel instead.
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
                    //BundleMenu(0);
                    //GiveMethodMenu();
                    // TODO: provide a way for a non-owner (like the sub's dom) to get the IM
                    // and run the update.
                    llMessageLinked(LINK_SET, GIVE_LINK, "", llGetOwner());
                }                
            } else if (channel == iSecureChannel) {
                if (msg == "reallyready") {
                    Particles(id);
                    iBundleIdx = 0;
                    DoBundle();       
                }
            }
        }
    }

    // when we get a BUNDLE_DONE message, move to the next bundle
    link_message(integer sender, integer num, string str, key id) {
        if (num == BUNDLE_DONE) {
            // see if there's another bundle
            integer count = llGetListLength(lBundles);
            iBundleIdx += 2;
            if (iBundleIdx < count) {
                DoBundle();
            } else {
                // tell the shim to restore settings, set version, 
                // remove the script pin, and delete himself.
                string myversion = llList2String(llParseString2List(llGetObjectName(), [" - "], []), 1);
                llRegionSayTo(kCollarKey, iSecureChannel, "CLEANUP|" + myversion);
                SetInstructionsText();
                llParticleSystem([]);
            }
        }
        else if (num == mychannel) {
            list qparams = llParseString2List(str, ["&", "="], []);                
            // handle enabling bundles
            string enable = GetParam(qparams, "enable");
            if (enable != "-1") {
                // The list of plugins to enable should be delimited by tildes.  
                // They sould be the human friendly names as seen in the former dialog ui
                // (not the full notecard names)
                list to_enable = llParseString2List(llUnescapeURL(enable), ["~"], []);
                integer n;
                integer stop = llGetListLength(to_enable);
                for (n = 0; n < stop; n++) {
                    string bundle = llList2String(to_enable, n);
                    SetBundleStatus(bundle, "INSTALL");
                }
            }
            
            // handle disabling bundles
            string disable = GetParam(qparams, "disable");                    
            if (disable != "-1") {
                list to_disable = llParseString2List(llUnescapeURL(disable), ["~"], []);
                integer n;
                integer stop = llGetListLength(to_disable);
                for (n = 0; n < stop; n++) {
                    string bundle = llList2String(to_disable, n);
                    SetBundleStatus(bundle, "REMOVE");
                }                
            }
            string status = "waiting";
            string start = GetParam(qparams, "start");
            if (start != "-1") {
                StartUpdate();
                status = "started";
            }
                    
            string json = GetBundlesJSON(status);
            string callback = GetCallback(str);
            llMessageLinked(LINK_SET, HTTP_RESPONSE, WrapCallback(json, callback), id);            
        }                
    }

    on_rez(integer param) {
        llResetScript();
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            // Resetting on inventory change ensures that the bundle list is
            // kept current, and that the ~version card is re-read if it
            // changes.
            llResetScript();
        }
    }

    dataserver(key id, string data) {
        if (id == version_line_id) {
            // make sure that object version matches this card.
            list nameparts = llParseString2List(llGetObjectName(), [" - "], []);
            integer length = llGetListLength(nameparts);
            if (length == 2) {
                nameparts = llListReplaceList(nameparts, [data], 1, 1);
            } else if (length == 1) {
                nameparts += [data];
            }
            llSetObjectName(llDumpList2String(nameparts, " - "));
        }
    }
}
