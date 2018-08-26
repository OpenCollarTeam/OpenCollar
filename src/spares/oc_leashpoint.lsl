/*
This code is a part of OpenCollar and is licensed under the GPLv2
Copyright 2018 tiff589 Resident
*/

default{
    state_entry(){
        llSetMemoryLimit(3600);
        llListen(0x89a, "", "", "");
    }
    on_rez(integer iT){
        llResetScript();
    }
    listen(integer iChn, string sName, key kID, string sBody){
        if(llGetOwnerKey(kID)!=llGetOwner()){
            llWhisper(0x89a, "Wrong owner id"); // debug purposes only
            return;
        }
        
        if(llJsonGetValue(sBody,["type"])=="leash"){
            string ObjectKey = llJsonGetValue(sBody, ["name"]);
            if(llGetLinkKey(1)==ObjectKey){
                llSay(0x89a, llList2Json(JSON_OBJECT, ["type", "confirm_leash", "key", llGetKey()]));
            }
        }
        
    }
}
