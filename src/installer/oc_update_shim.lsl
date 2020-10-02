// This file is part of OpenCollar.
// Copyright (c) 2011 - 2017 Nandana Singh, Satomi Ahn, Wendy Starfall,  
// littlemousy, Sumi Perl, Garvin Twine et al.               
// Licensed under the GPLv2.  See LICENSE for full details. 

// This script is like a kamikaze missile.  It sits dormant in the updater
// until an update process starts.  Once the initial handshake is done, it's
// then inserted into the object being updated, where it chats with the bundle
// giver script inside the updater to let it know what to send over.  When the
// update is finished, this script does a little final cleanup and then deletes
// itself.

integer g_iStartParam;
integer LOADPIN = -1904;
integer LINK_UPDATE = -10;

integer REBOOT = -1000;
// a strided list of all scripts in inventory, with their names,versions,uuids
// built on startup
list g_lScripts;

list g_lCore5Scripts = ["oc_auth","oc_dialog","oc_rlvsys","oc_settings","oc_anim","oc_couples"];

// list where we'll record all the settings and local settings we're sent, for replay later.
// they're stored as strings, in form "<cmd>|<data>", where cmd is either LM_SETTING_SAVE
list g_lSettings;
integer g_iIgnoreSent=FALSE;
integer g_iIsUpdate;

// list of deprecated tokens to remove from previous collar scripts
list g_lDeprecatedSettingTokens = ["collarversion","global_integrity","intern_hovers","intern_standhover","leashpoint","auth_groupname",
"rlvsuite_mask1", "rlvsuite_mask2",
 "rlvsuite_auths", "auth_norun" //< - Auths was a token in 7.4 betas which allowed setting access to specific restrictions, but it proved to push us over the memory limit. This may be readded in the future under a different script, and different token name.
 
 ];

integer CMD_OWNER = 500;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the settings store

string gp(integer perm)
{
    integer fullPerms = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    integer copyModPerms = PERM_COPY | PERM_MODIFY;
    integer copyTransPerms = PERM_COPY | PERM_TRANSFER;
    integer modTransPerms = PERM_MODIFY | PERM_TRANSFER;
 
    string output = "";
 
    if ((perm & fullPerms) == fullPerms)
        output += "full";
    else if ((perm & copyModPerms) == copyModPerms)
        output += "copy & modify";
    else if ((perm & copyTransPerms) == copyTransPerms)
        output += "copy & transfer";
    else if ((perm & modTransPerms) == modTransPerms)
        output += "modify & transfer";
    else if ((perm & PERM_COPY) == PERM_COPY)
        output += "copy";
    else if ((perm & PERM_TRANSFER) == PERM_TRANSFER)
        output += "transfer";
    else
        output += "none";
 
 
    return  output;
}
string getperm(string inv)
{
    integer perm = llGetInventoryPermMask(inv, MASK_OWNER);
    return gp(perm);
}
Check4Core5Script() {
    integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
    string sScriptName;
    do { i--;
        sScriptName = llGetInventoryName(INVENTORY_SCRIPT,i);
        integer index = llListFindList(g_lCore5Scripts,[sScriptName]);
        if (~index) {
            llMessageLinked(LINK_ALL_OTHERS,LOADPIN,sScriptName,"");
            g_lCore5Scripts = llDeleteSubList(g_lCore5Scripts,index,index);
            return;
        }
    } while (i);
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}


default {
    state_entry() {
        PermsCheck();
        
        g_iStartParam = llGetStartParameter();
        if (g_iStartParam < 0 ){
            g_iIsUpdate = TRUE;
        }
        
        llOwnerSay("Update will start shortly. Checking for existing settings");
        // build script list
        integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
        string sName;
        integer TotalScriptsFound=i;
        // listen on the start param channel
        llListen(g_iStartParam, "", "", "");
        // let mama know we're ready
        //llWhisper(g_iStartParam, "reallyready");
        if(TotalScriptsFound>2){
            llSleep(5); // settle for a moment: oc_settings will not be ready right away to handle our request
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
            llResetTime();
            llSetTimerEvent(1); // Timeout the settings request in 30 seconds
        }else{
            llOwnerSay("No existing settings found. Starting install");
            llWhisper(g_iStartParam,"reallyready");
        }
    }

    listen(integer iChannel, string sWho, key kID, string sMsg) {
        if (llGetOwnerKey(kID) != llGetOwner()) return;
        
        list lParts = llParseString2List(sMsg, ["|"], []);
        if (llGetListLength(lParts) == 4) {
            string sType = llList2String(lParts, 0);
            string sName = llList2String(lParts, 1);
            key kUUID = (key)llList2String(lParts, 2);
            string sMode = llList2String(lParts, 3);
            string sCmd;
            if (sMode == "INSTALL" || sMode == "REQUIRED") {
                if (sType == "SCRIPT" || sType == "STOPPEDSCRIPT") {
                    // see if we have that script in our list.
                    integer idx = llListFindList(g_lScripts, [sName]);
                    if (idx == -1) {
                        // script isn't in our list.
                        sCmd = "GIVE";
                    } else {
                        // it's in our list.  Check UUID.
                        if (llGetInventoryKey(sName) == kUUID  && kUUID != NULL_KEY && sName != "oc_sys") {
                            // already have script.  skip
                            sCmd = "SKIP";
                        } else {
                            // we have the script but it's the wrong version.  delete and get new one.
                            llRemoveInventory(sName);
                            sCmd = "GIVE";
                        }
                    }
                } else if (sType == "ITEM") {
                    if (llGetInventoryType(sName) != INVENTORY_NONE) {
                        // item exists.  check uuid.
                        if (llGetInventoryKey(sName) != kUUID || kUUID == NULL_KEY) {
                            // mismatch.  delete and report
                            llRemoveInventory(sName);
                            sCmd = "GIVE";
                        } else {
                            // matches. skip
                            sCmd = "SKIP";
                        }
                    } else {
                        // we don't have item. get it.
                        sCmd = "GIVE";
                    }
                }
            } else if (sMode == "REMOVE" || sMode == "DEPRECATED") {
                if (sType == "SCRIPT" || sType == "STOPPEDSCRIPT" || sType == "ITEM") {
                    if (llGetInventoryType(sName) != INVENTORY_NONE) {
                        llRemoveInventory(sName);
                    }
                } else if(sType == "LIKE"){
                    integer iV = 0;
                    integer iE = llGetInventoryNumber(INVENTORY_ALL);
                    for(iV=0;iV<iE;iV++){
                        string name = llGetInventoryName(INVENTORY_ALL,iV);
                        if(llSubStringIndex(name, sName)!=-1){
                            if(name != llGetScriptName()){
                                llRemoveInventory(name);
                                iV = -1;
                                iE = llGetInventoryNumber(INVENTORY_ALL);
                            }
                        }
                    }
                }
                sCmd = "OK";
            } else if  (sMode == "OPTIONAL") {
                // only update if present but outdated.  skip if absent.
                if (llGetInventoryType(sName) == INVENTORY_NONE) {
                    sCmd = "SKIP";
                } else {
                    if (llGetInventoryKey(sName) == kUUID && kUUID != NULL_KEY) {
                        sCmd = "SKIP";
                    } else {
                        // we have it but it's the wrong version.  delete and get new one.
                        llRemoveInventory(sName);
                        sCmd = "GIVE";
                    }
                }
            }
            //check if there is a core5 script to move to its destination prim
            Check4Core5Script();
            string sResponse = llDumpList2String([sType, sName, sCmd], "|");
            llRegionSayTo(kID, iChannel, sResponse);
        } else if (sMsg == "Core5Done") Check4Core5Script();
        else if (!llSubStringIndex(sMsg, "DONE")){
            llOwnerSay("Restoring settings");
            llSleep(15); // WAIT A FEW SECONDS TO ALLOW EVERYTHING TO SETTLE DOWN
            llMessageLinked(LINK_SET, REBOOT, "reboot", "");
            llSleep(15);
            //restore settings
            if (g_iIsUpdate) {
                llMessageLinked(LINK_SET, LINK_UPDATE, "LINK_REQUEST","");
                integer n;
                integer iStop = llGetListLength(g_lSettings);
                for (n = 0; n < iStop; n++) {
                    string sSetting = llList2String(g_lSettings, n);
                    //Look through deprecated settings to see if we should ignore any...
                    // Settings look like rlvmain_on=1, we want to deprecate the token ie. rlvmain_on <--store
                    list lTest = llParseString2List(sSetting,["="],[]);
                    string sToken = llList2String(lTest,0);
                    if (llListFindList(g_lDeprecatedSettingTokens,[sToken]) == -1) { //If it doesn't exist in our list
                        if (~llListFindList(["auth_block","auth_trust","auth_owner"],[sToken])) {
                            lTest = llParseString2List(llGetSubString(sSetting,llSubStringIndex(sSetting,"=")+1,-1),[","],[]);
                            integer i;
                            for (;i<llGetListLength(lTest);++i) {
                                string sValue = llList2String(lTest,i);
                                if ((key)sValue) {}
                                else lTest = llDeleteSubList(lTest,i,i);
                            }
                            sSetting = sToken+"="+llDumpList2String(lTest,",");
                        }
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, sSetting, "");
                    } else {
                        //Debug("SP - Deleting :"+ llList2String(sDeprecatedSplitSettingTokenForTest,0));
                         //remove it if it's somehow persistent still
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, sToken, "");
                    }
                }
            }
            // remove the script pin
            llSetRemoteScriptAccessPin(0);
            // celebrate
            llOwnerSay("Installation is finishing!");
            llSleep(5);
            integer iDuplicateRemove=0;
            integer iInvEnd = llGetInventoryNumber(INVENTORY_ANIMATION);
            for(iDuplicateRemove=0;iDuplicateRemove<iInvEnd;iDuplicateRemove++){
                string name = llGetInventoryName(INVENTORY_ANIMATION,iDuplicateRemove);
                if(llGetSubString(name, -2,-1)==" 1"){
                    string permMask = getperm(name);
                    if(permMask == "modify & transfer" || permMask == "transfer" || permMask == "none"){}else{
                        
                        llRemoveInventory(name);
                        iDuplicateRemove=-1;
                        iInvEnd=llGetInventoryNumber(INVENTORY_ANIMATION);
                    }
                }
            }
            if (g_iIsUpdate) {
                //reboot scripts
                llSleep(0.5);
                llMessageLinked(LINK_SET,CMD_OWNER,"reboot --f",llGetOwner());
            }
            
            llSleep(15); // oc_sys sleeps for 10 seconds
            llOwnerSay("Fixing menus ...");
            llMessageLinked(LINK_SET, CMD_OWNER, "fix", llGetOwner());
            llSleep(5);
            llOwnerSay("Installation Completed!");
            // delete shim script
            llRemoveInventory(llGetScriptName());
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        // The settings script will dump all its settings when an inventory change happens, so listen for that and remember them
        // so they can be restored when we're done.
        if (iNum == LM_SETTING_RESPONSE) {
            if (sStr != "settings=sent") {
                if (llListFindList(g_lSettings, [sStr]) == -1) {
                    g_lSettings += [sStr];
                }
            }else{
                if(g_iIgnoreSent)return;
                g_iIgnoreSent=TRUE;
                llOwnerSay("Got Settings! Starting Update");
                llSetTimerEvent(0);
                llWhisper(g_iStartParam, "reallyready");
                llMessageLinked(LINK_SET, -99999, "update_active", "");
            }
        }
        if (iNum == LOADPIN) {
            integer iPin =  (integer)llGetSubString(sStr,0,llSubStringIndex(sStr,"@")-1);
            string sScriptName = llGetSubString(sStr,llSubStringIndex(sStr,"@")+1,-1);
            if (llGetInventoryType(sScriptName) == INVENTORY_SCRIPT) {
                llRemoteLoadScriptPin(kID, sScriptName, iPin, TRUE, 825);
                //llRemoveInventory(sScriptName);
                //llWhisper(0, "Moving script: "+sScriptName+" back to main prim");
                
            }
            
            llSleep(5);
            llMessageLinked(LINK_ALL_OTHERS, 0, "do_move", llGetLinkKey(llGetLinkNumber()));
        }
    }

    timer(){
        if(llGetTime()>30){
            llSetTimerEvent(0);
            llMessageLinked(LINK_SET, -99999, "update_active", "");
            llOwnerSay("Starting Update");
            g_iIgnoreSent=TRUE;
            llWhisper(g_iStartParam,"reallyready");
        } else if(llGetTime()>5 && llGetTime()<6.9){
            llOwnerSay("* oc_settings has not yet sent us settings! Retry (Count:1)");
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
        } else if(llGetTime()>15 && llGetTime()<16.9){
            llOwnerSay("* oc_settings has not yet sent us settings! Retry (Count:2)");
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
        } else if(llGetTime()>25 && llGetTime()<26.9){
            llOwnerSay("* last try to get oc_settings memory!");
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
        }
    }

    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
        if (iChange & CHANGED_INVENTORY) PermsCheck();
    }
}