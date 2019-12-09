integer g_iUpdateChan = -7483213;


// be explicit about what we delete
list deletables = [
    "!totallytransparent",
    "!fadestripe",
    "!whiteleather",
    "5fadestripes",
    "blank",
    "blkgraindot",
    "brushedmetal-hshaded",
    "brushedmetal-hshaded-contrasty",
    "brushedmetal-roundshaded",
    "brushedmetal-vshaded",
    "Celtic",
    "diamond",
    "I-Beam",
    "metal-h",
    "metal-h-contrast",
    "metal-round",
    "metal-v",
    "opaque gradient circle",
    "Rusty Metal Chest",
    "Rusty Panel",
    "seamless foil",
    "seamless gold foil",
    "Silver Filligree",
    "beautystand",
    "belly",
    "bendover",
    "bracelets",
    "chain",
    "coupleanims",
    "cutie",
    "defaultsettings",
    "display",
    "doggie",
    "kneel",
    "Leash Holder",
    "nadu",
    "naduw",
    "OC_Leash_Post",
    "open",
    "OpenCollar Guide",
    "OpenCollar License",
    "plead",
    "rope",
    "shock",
    "sleep",
    "squirm",
    "submit",
    "subsit",
    "Temple",
    "tower",
    "underground",
    "~-30",
    "~-31",
    "~-32",
    "~-33",
    "~-34",
    "~-35",
    "~-36",
    "~-37",
    "~-38",
    "~-39",
    "~-39",
    "~-40",
    "~-41",
    "~-42",
    "~-43",
    "~-44",
    "~-45",
    "~-46",
    "~-47",
    "~-48",
    "~-49",
    "~-50",
    "~bootlick",
    "~extendfoot",
    "~footextend",
    "~footkiss",
    "~heightscalars",
    "~hug",
    "~hug-feminine",
    "~jumphold",
    "~jumphug",
    "~kiss",
    "~kiss-feminine",
    "~kneelhug",
    "~kneelhug-dom",
    "~master",
    "~pet_the_pet",
    "~sub-hug",
    "~sub-pet",
    "Tranquility",
    "~version",
    "Grabby Post",
    "OpenCollar RLV Relay Help",
    "OpenCollar - rlvrelay - Help"
];

SafeDelete(string item) {
    if (llGetInventoryType(item) == INVENTORY_NONE) return;
    if (llGetInventoryPermMask(item, MASK_OWNER) & PERM_COPY != PERM_COPY) return;
    llRemoveInventory(item);
}

LegacyCleanup() {
    // clean up junk.

    // delete the transparent texture but keep the prim transparent, if applicable
    if (llGetTexture(ALL_SIDES) == "!totallytransparent") {
        key tex = llGetInventoryKey("!totallytransparent");
        llRemoveInventory("!totallytransparent");
        llSetTexture(tex, ALL_SIDES);
    }

    // clean up old scripts
    string sName;
    integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
    while (i) {
        sName = llGetInventoryName(INVENTORY_SCRIPT, --i);
        // old scripts all start with "OpenCollar - " or "OpenCuffs - "
        if ((llSubStringIndex(sName, "OpenCollar - ") == 0) || (llSubStringIndex(sName, "OpenCuffs - ") == 0)) {
            llRemoveInventory(sName);
        }
    }
    
    // clean up other old things.
    i = llGetInventoryNumber(INVENTORY_ALL);
    integer stop = llGetListLength(deletables);
    for (i = 0; i < stop; i++) {
        SafeDelete(llList2String(deletables, i));
    }
}

default
{
    state_entry()
    {
        if (llGetAttached()) {
            string additional = "You currently have: "+(string)llGetNumberOfPrims()+"\n";
            if(llGetNumberOfPrims()==1)additional += "* The leash will not appear to be coming directly from a ring, and may appear from the center of the collar object. If you wish to resolve this, please create a small invisible linked prim at the desired location of the chain and name it 'leashpoint' without the quotes.\n \nAlternatively you can just re-run collarizer while the collar is rezzed to add the default leashpoint linkset to your collar. This will still require adjustment of the prim position.";
            llDialog(llGetOwner(), "OpenCollar\n \n[WARNING]\nStarting update! \n"+additional, ["DISMISS"], -99);
            state update;
        }// Else perform linking steps, using the old leashpoint linkset will be fine for this as the automated upgrade will move the scripts to root.

        if (llGetStartParameter()) {
            llOwnerSay("I need permission to link a few new child prims to your collar.");
            llOwnerSay("I will first delete all old OpenCollar contents.");
            llOwnerSay("If that's OK, click Yes.");
            llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
        }
    }
    
    run_time_permissions(integer perms) {
        if (perms & PERMISSION_CHANGE_LINKS) {
            LegacyCleanup();            
            llRezAtRoot("leashpoint", llGetPos(), ZERO_VECTOR, llEuler2Rot(<0,0,-90 * DEG_TO_RAD>) * llGetRot(), 1);
        }
    }
    
    object_rez(key id) {
        llCreateLink(id, TRUE);
        llRemoveInventory("leashpoint");
    }
    
    changed(integer change) {
        if (change & CHANGED_LINK) {
            llOwnerSay("Child prims linked.  Starting update.");
            state update;
        }
    }
}

state update {
    state_entry() {
        llOwnerSay("Initializing update.");
        llListen(g_iUpdateChan, "", "", "");
        llWhisper(g_iUpdateChan, "UPDATE|6.0");
        llSetTimerEvent(30);
    }

    listen(integer channel, string name, key id, string msg) {
        if (llGetOwnerKey(id) != llGetOwner()) return;
        if (llSubStringIndex(msg, "-.. ---|") == 0) { // why morse code? sigh.  Let's keep things readable, people.
            llOwnerSay("Updater found.  Beginning update!  When it's finished, you might want to reposition the new invisible child prims.");
            // if there's a "SomeCollar - x.xxx" version number in the name, remove it
            list nameParts = llParseString2List(llGetObjectName(), [" - "], []);
            if (llList2Float(nameParts, 1)) {
                llSetObjectName(llList2String(nameParts, 0));
                llSetObjectDesc(llList2String(nameParts, 0));
            }
            integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
            llSetRemoteScriptAccessPin(pin);
            llRegionSayTo(id, g_iUpdateChan, "ready|" + (string)pin );    
            llRemoveInventory(llGetScriptName());    
        }
    }
    
    timer() {
        // if we haven't gotten started by now, clean ourself up
        llRemoveInventory(llGetScriptName());
    }
}
