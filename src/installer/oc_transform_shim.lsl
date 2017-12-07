integer g_iUpdateChan = -7483213;

LegacyCleanup() {
    // clean up old scripts
    string sName;
    integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
    while (i) {
        sName = llGetInventoryName(INVENTORY_SCRIPT, --i);
        // old scripts all start with "OpenCollar - "
        if (llSubStringIndex(sName, "OpenCollar - ") == 0) {
            llRemoveInventory(sName);
        }
    }
    
    // clean up old animations.  Any copyable anim starting with a "~"
    i = llGetInventoryNumber(INVENTORY_ANIMATION);
    while (i) {
        sName = llGetInventoryName(INVENTORY_ANIMATION, --i);
        if ((llGetInventoryPermMask(sName, MASK_OWNER) & PERM_COPY) == PERM_COPY) {
            llRemoveInventory(sName);
        }
    }
}

default
{
    state_entry()
    {
        if (llGetStartParameter()) {
            llOwnerSay("I need permission to link a few new child prims to your collar.");
            llOwnerSay("I will first delete all old OpenCollar scripts and copyable animations.");
            llOwnerSay("If that's OK, click Yes.");
            llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
        }
    }
    
    run_time_permissions(integer perms) {
        if (perms & PERMISSION_CHANGE_LINKS) {
            LegacyCleanup();            
            llRezObject("ChildPrims", llGetPos(), ZERO_VECTOR, llGetRot(), 1);
        }
    }
    
    object_rez(key id) {
        llCreateLink(id, TRUE);
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
