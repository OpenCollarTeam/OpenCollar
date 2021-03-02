
integer REBOOT = -1000;
integer g_iIsMoving = FALSE;


default
{
    state_entry()
    {
        if(llGetStartParameter()==0)llRemoveInventory(llGetScriptName()); // this was just a shim to nuke oc_auth in the linked prim
        else{
            state update;
        }
    }
    link_message(integer s,integer n,string m,key i){
        if(n==REBOOT)llResetScript();
    }
}


state update{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
        else if(iNum == 0){
            if(sMsg == "do_move" && !g_iIsMoving){

                if(llGetLinkNumber()==LINK_ROOT || llGetLinkNumber() == 0)return;

                g_iIsMoving=TRUE;
                llOwnerSay("Moving oc_auth!");
                integer i=0;
                integer end=llGetInventoryNumber(INVENTORY_ALL);
                for(i=0;i<end;i++){
                    string item = llGetInventoryName(INVENTORY_ALL,i);
                    if(llGetInventoryType(item)==INVENTORY_SCRIPT && item!=llGetScriptName()){
                        llRemoveInventory(item);
                    }else if(llGetInventoryType(item)!=INVENTORY_SCRIPT){
                        if (llGetInventoryPermMask( item, MASK_OWNER ) & PERM_COPY){
                            llGiveInventory(kID, item);
                            llRemoveInventory(item);
                            i=-1;
                            end=llGetInventoryNumber(INVENTORY_ALL);
                        } else {
                            llOwnerSay("Item '"+item+"' is no-copy and can not be moved! Please move it manually!");
                        }
                    }
                }

                llRemoveInventory(llGetScriptName());
            }
        }
    }
}
