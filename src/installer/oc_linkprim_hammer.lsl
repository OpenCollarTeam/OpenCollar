/*
This file is a part of OpenCollar.
Copyright 2021

: Contributors :

Aria (Tashia Redrose)
    * March 2021         - Rewrote oc_linkprim_hammer

et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

default
{
    state_entry()
    {
        if(llGetLinkNumber()==0 || llGetLinkNumber()==1){
            return;
        }
        integer i=0;
        integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
        for(i=0;i<end;i++){
            string name = llGetInventoryName(INVENTORY_SCRIPT,i);
            if(name != llGetScriptName())
            {
                llOwnerSay("Update Hammer: Removed ("+name+")");
                llRemoveInventory(name);
                i=-1;
                end=llGetInventoryNumber(INVENTORY_SCRIPT);
            }
        }

        llRemoveInventory(llGetScriptName());
    }
}
