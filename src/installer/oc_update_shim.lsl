////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - UpdateShim                             //
//                                 version 3.985                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// This script is like a kamikaze missile.  It sits dormant in the updater
// until an update process starts.  Once the initial handshake is done, it's
// then inserted into the object being updated, where it chats with the bundle
// giver script inside the updater to let it know what to send over.  When the
// update is finished, this script does a little final cleanup and then deletes
// itself.

integer iStartParam;

// a strided list of all scripts in inventory, with their names,versions,uuids
// built on startup
list lScripts;

// list where we'll record all the settings and local settings we're sent, for replay later.
// they're stored as strings, in form "<cmd>|<data>", where cmd is either LM_SETTING_SAVE
list lSettings;

// list of deprecated tokens to remove from previous collar scripts
list lDeprecatedSettingTokens = [
    "collarversion"
];


// Return the name and version of an item as a list.  If item has no version, return empty string for that part.
list GetNameParts(string name) {
    list nameparts = llParseString2List(name, [" - "], []);
    string shortname = llDumpList2String(llList2List(nameparts, 0, 1), " - ");
    string version;
    if (llGetListLength(nameparts) > 2) {
        version = llList2String(nameparts, -1);
    } else {
        version = "";
    }
    return [shortname, version];
}

// Given the name (but not version) of a script, look it up in our list and return the key
// returns "" if not found.
key GetScriptFullname(string name) {
    integer idx = llListFindList(lScripts, [name]);
    if (idx == -1) {
        return (key)"";
    }
    
    string version = llList2String(lScripts, idx + 1);
    if (version == "") {
        return name;
    } else {
        return llDumpList2String([name, version], " - ");
    }
}

integer COMMAND_NOAUTH = 0;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the settings store

debug(string msg) {
    //llOwnerSay(llGetScriptName() + ": " + msg);
}

// Some versions of the collar have a hover text script in them that breaks
// updates because it set a script pin that overwrites the one set by this shim
// script.  So before starting, delete any script that starts with "OpenCollar
// - hovertext".  
// In general, removal of old cruft should be done with the cleanup script or
// a "DEPRECATED" bundle, but this has to be done here because it breaks the updater
// before bundles get going.
RemoveHoverTextScript() {
    string kill = "OpenCollar - hovertext";
    integer n;
    // loop from the top down to avoid shifting indices
    for (n = llGetInventoryNumber(INVENTORY_SCRIPT) - 1; n >= 0; n--) {
        string name = llGetInventoryName(INVENTORY_SCRIPT, n);
        if (llSubStringIndex(name, kill) == 0) {
            llRemoveInventory(name);
        }
    }
}

default
{
    state_entry()
    {
        iStartParam = llGetStartParameter();

        RemoveHoverTextScript();
        
        // build script list
        integer n;
        integer stop = llGetInventoryNumber(INVENTORY_SCRIPT);
        for (n = 0; n < stop; n++) {
            string name = llGetInventoryName(INVENTORY_SCRIPT, n);
            // add to script list
            lScripts += GetNameParts(name);
        }
        
        debug(llDumpList2String(lScripts, "|"));
        
        // listen on the start param channel
        llListen(iStartParam, "", "", "");
        
        // let mama know we're ready
        llWhisper(iStartParam, "reallyready");

    }
    
    listen(integer channel, string name, key id, string msg) {
        //debug("heard: " + msg);
        if (llGetOwnerKey(id) == llGetOwner()) {
            list parts = llParseString2List(msg, ["|"], []);
            if (llGetListLength(parts) == 4) {
                string type = llList2String(parts, 0);
                string name = llList2String(parts, 1);
                key uuid = (key)llList2String(parts, 2);
                string mode = llList2String(parts, 3);
                string cmd;
                if (mode == "INSTALL" || mode == "REQUIRED") {
                    if (type == "SCRIPT") {
                        // see if we have that script in our list.
                        integer idx = llListFindList(lScripts, [name]);
                        if (idx == -1) {
                            // script isn't in our list.
                            cmd = "GIVE";
                        } else {
                            // it's in our list.  Check UUID.
                            string script_name = GetScriptFullname(name);
                            key script_id = llGetInventoryKey(script_name);
                            if (script_id == uuid) {
                                // already have script.  skip
                                cmd = "SKIP";
                            } else {
                                // we have the script but it's the wrong version.  delete and get new one.
                                llRemoveInventory(script_name);
                                cmd = "GIVE";
                            }
                        }
                    } else if (type == "ITEM") {
                        if (llGetInventoryType(name) != INVENTORY_NONE) {
                            // item exists.  check uuid.
                            if (llGetInventoryKey(name) != uuid) {
                                // mismatch.  delete and report
                                llRemoveInventory(name);
                                cmd = "GIVE";
                            } else {
                                // match.  Skip
                                cmd = "SKIP";
                            }
                        } else {
                            // we don't have item. get it.
                            cmd = "GIVE";
                        }
                    }                
                } else if (mode == "REMOVE" || mode == "DEPRECATED") {
                    debug("remove: " + msg);
                    if (type == "SCRIPT") {
                        string script_name = GetScriptFullname(name);
                        debug("script name: " + script_name);
                        if (llGetInventoryType(script_name) != INVENTORY_NONE) {
                            llRemoveInventory(script_name);
                        }
                    } else if (type == "ITEM") {
                        if (llGetInventoryType(name) != INVENTORY_NONE) {
                            llRemoveInventory(name);
                        }
                    }
                    cmd = "OK";
                }
                string response = llDumpList2String([type, name, cmd], "|");
                //debug("responding: " + response);
                llRegionSayTo(id, channel, response);                                                                
            } else {
                if (llSubStringIndex(msg, "CLEANUP") == 0) {
                    // Prior to 3.706, collars would store version number in
                    // both the object name and description.  This has
                    // problems: 1) It prevents running updates while worn,
                    // since llSetObjectName doesn't reliably persist for
                    // attachments, 2) it's needless repetition and creates
                    // unnecessary complexity, and 3) version numbers are ugly.
                    // So now we store version number in just one place, inside
                    // the "~version" notecard, which is automatically kept up
                    // to date when the core bundle is installed.  The lines
                    // below here exist to clean up version numbers in old
                    // collars.

                    list msgparts = llParseString2List(msg, ["|"], []);
                    // look for a version in the name and remove if present
                    list nameparts = llParseString2List(llGetObjectName(), [" - "], []);
                    if (llGetListLength(nameparts) == 2 && (integer)llList2String(nameparts, 1)) {
                        // looks like there's a version in the name.  Remove
                        // it!  
                        string just_name = llList2String(nameparts, 0);
                        llSetObjectName(just_name);
                    }
                    
                    // We used to set the version in the desc too.  Now we just
                    // leave it alone in this script.  The in-collar update
                    // script now uses that part of the desc to remember the
                    // timestamp of the last news item that it reported.
                    
                    //restore settings 
                    integer n;
                    integer stop = llGetListLength(lSettings); 
                    list sDeprecatedSplitSettingTokenForTest;
                    for (n = 0; n < stop; n++) {
                        string setting = llList2String(lSettings, n);
                        //Look through deprecated settings to see if we should ignore any...
                        // Settings look like rlvmain_on=1, we want to deprecate the token ie. rlvmain_on <--store
                        sDeprecatedSplitSettingTokenForTest = llList2List(llParseString2List(setting,["="],[]),0,0);
    
                        if (llListFindList(lDeprecatedSettingTokens,sDeprecatedSplitSettingTokenForTest) < 0) { //If it doesn't exist in our list
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, setting, "");
                            //Debug("SP - Saving :"+setting);
                        }
                        else {
                            //Debug("SP - Deleting :"+ llList2String(sDeprecatedSplitSettingTokenForTest,0));
                             //remove it if it's somehow persistent still
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, llList2String(sDeprecatedSplitSettingTokenForTest,0), "");
                        }
                    }
                    
                    // tell scripts to rebuild menus (in case plugins have been removed)
                    llMessageLinked(LINK_SET, COMMAND_NOAUTH, "fixmenus", llGetOwner());
                    
                    // remove the script pin
                    llSetRemoteScriptAccessPin(0);
                    
                    // celebrate
                    llOwnerSay("Update complete!");
                    
                    // delete shim script
                    llRemoveInventory(llGetScriptName());
                }
            }
        }
    }
    
    link_message(integer sender, integer num, string str, key id) {
        // The settings script will dump all its settings when an inventory change happens, so listen for that and remember them 
        // so they can be restored when we're done.
        if (num == LM_SETTING_RESPONSE) {
            if (str != "settings=sent") {
                if (llListFindList(lSettings, [str]) == -1) {
                    lSettings += [str];
                }
            }
        }
    }
}
