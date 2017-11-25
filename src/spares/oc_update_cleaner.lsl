//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                        Update Cleaner - 141015.1                         //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2011 - 2015 Nandana Singh, Satomi Ahn, Wendy Starfall,    //
//  littlemousy et al.                                                      //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//       github.com/OpenCollarTeam/opencollar/tree/master/src/spares       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// This script exists to clean up some legacy cruft in old collars:
  // - delete the hovertext script that is in a child prim
  // - delete the mis-named "OpenCollar - remoteserver- 3.481" script (missing a space in the name pattern)

// The items we want to delete are identified by having these strings in their names
list garbage = [
    "hovertext@",
    "OpenCollar - remoteserver-"
];

// Allow this many seconds to hear back from child prims before
// removing self from root prim inventory
integer deathtimer = 3;

integer UPDATE = 10001;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

// Function that will look at all items in the prim and delete any
// whose names contain the pattern.
DelMatchingItems(string pattern) {
    integer n;
    // Loop from the top down so we don't screw up inventory numbers as we delete
    for (n = llGetInventoryNumber(INVENTORY_ALL); n >= 0; n--) {
        string name = llGetInventoryName(INVENTORY_ALL, n);
        // look for match but don't delete self.
        if (llSubStringIndex(name, pattern) != -1
            && name != llGetScriptName()) {
            // found the item we're looking for.  Remove!
            llRemoveInventory(name);
            //Debug("found " + name);
        }
    }
}

DelItems(list items) {
    integer n;
    integer stop = llGetListLength(items);
    for (n = 0; n < stop; n++) {
        string pattern = llList2String(items, n);
        DelMatchingItems(pattern);
    }
}

default {
    state_entry() {
        // Don't run cleanup if placed in an updater
        if (llSubStringIndex(llGetObjectName(), "Updater") != -1) {
            //Debug("In an updater.  Sleeping.");
            llSetScriptState(llGetScriptName(), FALSE);
        }

        key transKey="bd7d7770-39c2-d4c8-e371-0342ecf20921";
        integer primNumber=llGetNumberOfPrims()+1;
        while (primNumber--){
            integer numOfSides = llGetNumberOfSides();
            while (numOfSides--){
                key texture=llList2String(llGetLinkPrimitiveParams(primNumber,[PRIM_TEXTURE,numOfSides]),0);
                if (texture == transKey || texture == TEXTURE_PLYWOOD || texture=="!totallytransparent"){
                    llSetLinkPrimitiveParamsFast(primNumber,[PRIM_TEXTURE,numOfSides,TEXTURE_TRANSPARENT,<1,1,1>,<0,0,0>,0]);
                }
            }
        }

        DelItems(garbage);

        if (llGetLinkNumber() > 1) {
            // in a child prim.
            // Since we already cleaned up, we can just die now
            llRemoveInventory(llGetScriptName());
        } else {
            // If in root prim, then ping for scripts in child prims.
            llMessageLinked(LINK_SET, UPDATE, "prepare", "");

            // and set the death timer
            llSetTimerEvent(deathtimer);
        }
        //Debug("starting");
    }

    link_message(integer sender, integer num, string str, key id) {
        //Debug(llDumpList2String([sender, num, str, id], ", "));
        if (num == UPDATE) {
            // If a child script responds with a script pin, clone self there.
            list parts = llParseString2List(str, ["|"], []);
            if (llGetListLength(parts) > 1) {
                integer pin = (integer)llList2String(parts, 1);
                key prim = llGetLinkKey(sender);
                if (pin > 0) {
                    llRemoteLoadScriptPin(prim, llGetScriptName(), pin, TRUE, 1);
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
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/

}
