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
//                         Update Shim - 160321.1                           //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2011 - 2016 Nandana Singh, Satomi Ahn, Wendy Starfall,    //
//  littlemousy, Sumi Perl, Garvin Twine et al.                             //
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
//        github.com/OpenCollar/opencollar/tree/master/src/installer        //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// This script is like a kamikaze missile.  It sits dormant in the updater
// until an update process starts.  Once the initial handshake is done, it's
// then inserted into the object being updated, where it chats with the bundle
// giver script inside the updater to let it know what to send over.  When the
// update is finished, this script does a little final cleanup and then deletes
// itself.

integer g_iStartParam;
integer LOADPIN = -1904;

// a strided list of all scripts in inventory, with their names,versions,uuids
// built on startup
list g_lScripts;

list g_lCore5Scripts = ["oc_auth","oc_dialog","oc_rlvsys","oc_settings","oc_anim","oc_couples"];

// list where we'll record all the settings and local settings we're sent, for replay later.
// they're stored as strings, in form "<cmd>|<data>", where cmd is either LM_SETTING_SAVE
list g_lSettings;

integer g_iIsUpdate;

// list of deprecated tokens to remove from previous collar scripts
list g_lDeprecatedSettingTokens = ["collarversion","global_integrity"];

integer CMD_OWNER = 500;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the settings store

debug(string msg) {
   // llOwnerSay(llGetScriptName() + ": " + msg);
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

default {
    state_entry() {
        g_iStartParam = llGetStartParameter();
        if (g_iStartParam < 0 ) g_iIsUpdate = TRUE;
        // build script list
        integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
        string sName;
        do { i--;
            sName = llGetInventoryName(INVENTORY_SCRIPT,i);
            if (~llListFindList(g_lCore5Scripts,[sName])) {
                if (llGetInventoryType(sName) == INVENTORY_SCRIPT)
                    llRemoveInventory(sName);
            } else g_lScripts += sName;
        } while (i);
        debug(llDumpList2String(g_lScripts, "|"));
        // listen on the start param channel
        llListen(g_iStartParam, "", "", "");
        // let mama know we're ready
        llWhisper(g_iStartParam, "reallyready");
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg) {
       // debug("heard: " + sMsg);
        if (llGetOwnerKey(kID) != llGetOwner()) return;
        list lParts = llParseString2List(sMsg, ["|"], []);
        if (llGetListLength(lParts) == 4) {
            string sType = llList2String(lParts, 0);
            string sName = llList2String(lParts, 1);
            key kUUID = (key)llList2String(lParts, 2);
            string sMode = llList2String(lParts, 3);
            string sCmd;
            if (sMode == "INSTALL" || sMode == "REQUIRED") {
                if (sType == "SCRIPT") {
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
                            // match.  Skip
                            sCmd = "SKIP";
                        }
                    } else {
                        // we don't have item. get it.
                        sCmd = "GIVE";
                    }
                }                
            } else if (sMode == "REMOVE" || sMode == "DEPRECATED") {
                debug("remove: " + sMsg);
                if (sType == "SCRIPT") {
                    if (llGetInventoryType(sName) != INVENTORY_NONE) {
                        llRemoveInventory(sName);
                    }
                } else if (sType == "ITEM") {
                    if (llGetInventoryType(sName) != INVENTORY_NONE) {
                        llRemoveInventory(sName);
                    }
                }
                sCmd = "OK";
            }
            //check if there is a core5 script to move to its destination prim
            Check4Core5Script();
            string sResponse = llDumpList2String([sType, sName, sCmd], "|");
            //debug("responding: " + response);
            llRegionSayTo(kID, iChannel, sResponse);     
        } else if (sMsg == "Core5Done") Check4Core5Script();
        else if (!llSubStringIndex(sMsg, "DONE")){
            //restore settings 
            if (g_iIsUpdate) {
                llMessageLinked(LINK_ALL_OTHERS, -10, "LINK_REQUEST","");
                integer n;
                integer iStop = llGetListLength(g_lSettings); 
                for (n = 0; n < iStop; n++) {
                    string sSetting = llList2String(g_lSettings, n);
                    //Look through deprecated settings to see if we should ignore any...
                    // Settings look like rlvmain_on=1, we want to deprecate the token ie. rlvmain_on <--store
                   // debug("Settings: "+sSetting);
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
                       // debug("SP - Saving :"+sSetting);
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
            llOwnerSay("Installation complete!");
            if (g_iIsUpdate) {
                //reboot scripts
                llSleep(0.5);
                llMessageLinked(LINK_ALL_OTHERS,CMD_OWNER,"reboot --f",llGetOwner());
            }
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
            }
        }
        if (iNum == LOADPIN) {
            integer iPin =  (integer)llGetSubString(sStr,0,llSubStringIndex(sStr,"@")-1);
            string sScriptName = llGetSubString(sStr,llSubStringIndex(sStr,"@")+1,-1);
           //debug("PrimNr:"+(string)iSender+" - "+sStr);
            if (llGetInventoryType(sScriptName) == INVENTORY_SCRIPT) {
                llRemoteLoadScriptPin(kID, sScriptName, iPin, TRUE, 825);
                llRemoveInventory(sScriptName);
            }
        }
    }
}
