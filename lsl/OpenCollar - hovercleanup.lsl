// This script exists to delete the hovertext script that is in a child prim in most opencollars.  

//Since we now have LSL functions that can be called in the root prim and set text on a child prim, we no longer need to have a hover text script in a child prim.  We can do it all from the root where things are easier to update.

// The script we want to delete is identified by having this string at the start of its name
string target = "hovertext@";

// If we don't hear from child prim in this much time, just kill self.
integer deathtimer = 10;

integer UPDATE = 10001;

Debug(string str) {
    //llOwnerSay(llGetScriptName() + ": " + str);
}

default
{
    state_entry()
    {
        Debug("starting");
        if (llGetStartParameter() == 1) {
            // we're on a mission
            state cleanup;
        } else {
            // must be we haven't gotten where we need to be yet.
            // ask the hover text script to set his pin.
            llMessageLinked(LINK_SET, UPDATE, "prepare", "");
            
            // and set the death timer
            llSetTimerEvent(deathtimer);            
        }
    }
    
    link_message(integer sender, integer num, string str, key id) {
        Debug(llDumpList2String([sender, num, str, id], ", "));
        if (num == UPDATE) {
            if (llSubStringIndex(str, target) == 0) {
                // we heard from the script that we're trying to kill.
                list parts = llParseString2List(str, ["|"], []);
                integer pin = (integer)llList2String(parts, 1);
                llRemoteLoadScriptPin(id, llGetScriptName(), pin, TRUE, 1);
                // now that we're loaded there, die here
                Debug("Sent child.  Dying!");
                llRemoveInventory(llGetScriptName());
            }
        }
    }
    
    timer() {
        Debug("timer");
        llRemoveInventory(llGetScriptName());
    }
}

state cleanup {
    state_entry() {
        integer n;
        // Loop from the top down so we don't screw up inventory numbers as we delete
        for (n = llGetInventoryNumber(INVENTORY_SCRIPT); n >= 0; n--) {
            string name = llGetInventoryName(INVENTORY_SCRIPT, n);
            if (llSubStringIndex(name, target) != -1) {
                // found the script we're looking for.  Remove!
                llRemoveInventory(name);
                Debug("found " + name);
            }
        }        
        Debug("Done!");        
        llRemoveInventory(llGetScriptName());
    }
}
