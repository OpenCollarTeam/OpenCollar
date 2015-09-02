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
//                       Installer System - 150901.1                        //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2011 - 2015 Nandana Singh, Satomi Ahn, DrakeSystem,       //
//  Wendy Starfall, littlemousy, Romka Swallowtail, Garvin Twine et al.     //
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

// This is the master updater script.  It complies with the update handshake
// protocol that OC has been using for quite some time, and should therefore be
// compatible with current OC collars.  the internals of this script, and the
// the other parts of the new updater, have been completely re-written.  Don't
// expect this to work like the old updater.  Because we load an update shim
// script right after handshaking, we're free to rewrite everything that comes
// after the handshake.

// In addition to the handshake and shim installation, this script decides
// which bundles should be installed into (or removed from) the collar.  It
// loops over each bundle in inventory, telling the BundleGiver script to
// install or remove each.

// This script also does a little bit of magic to ensure that the updater's
// version number always matches the contents of the ".version" card.


key g_kVersionID;

integer g_initChannel = -7483214;
integer g_iSecureChannel;

// store the script pin here when we get it from the collar.
integer g_iPin;

// the collar's key
key g_kCollarKey;

// strided list of bundles in the prim and whether they are supposed to be 
// installed.
list g_lBundles;

// here we remember the index of the bundle that's currently being installed/removed
// by the bundlegiver.
integer g_iBundleIndex;

// handle for our dialogs
key g_kDialogID;

string g_sShim = "oc_update_shim";

integer DO_BUNDLE = 98749;
integer BUNDLE_DONE = 98750;

string g_sVersion;
// A wrapper around llSetScriptState to avoid the problem where it says it can't
// find scripts that are already not running.
DisableScript(string sName) {
    if (llGetInventoryType(sName) == INVENTORY_SCRIPT) {
        if (llGetScriptState(sName))
            llSetScriptState(sName, FALSE);
    }
}

DoBundle() {
    // tell bundle slave to load the bundle.
    string card = llList2String(g_lBundles, g_iBundleIndex);
    string mode = llList2String(g_lBundles, g_iBundleIndex + 1);
    string bundlemsg = llDumpList2String([g_iSecureChannel, g_kCollarKey, card, g_iPin, mode], "|");
    llMessageLinked(LINK_SET, DO_BUNDLE, bundlemsg, "");    
}

Debug(string str) {
    // llOwnerSay(llGetScriptName() + ": " + str);
}

ReadVersionLine() {
    // try to keep object's version in sync with ".version" notecard.
    if (llGetInventoryType(".version") == INVENTORY_NOTECARD) {
        g_kVersionID = llGetNotecardLine(".version", 0);
    }
}

SetFloatText() {
    llSetText("Developer's Exclusive\nVersion "+g_sVersion, <1,1,1>, 1.0);
}

Particles(key kTarget) {
    llParticleSystem([ 
        PSYS_PART_FLAGS, 
            PSYS_PART_INTERP_COLOR_MASK |
            PSYS_PART_INTERP_SCALE_MASK |
            PSYS_PART_TARGET_POS_MASK |
            PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_SRC_TEXTURE, "930c3304-e899-9266-2ab5-ab9ec3aec2b6",
        PSYS_SRC_TARGET_KEY, kTarget,
        PSYS_PART_START_COLOR, <0.529, 0.416, 0.212>,
        PSYS_PART_END_COLOR, <0.733, 0.592, 0.345>,
        PSYS_PART_START_SCALE, <0.68, 0.64, 0>,
        PSYS_PART_END_SCALE, <0.04, 0.04, 0>,
        PSYS_PART_START_ALPHA, 0.1,
        PSYS_PART_END_ALPHA, 1,
        PSYS_SRC_BURST_PART_COUNT, 4,
        PSYS_PART_MAX_AGE, 2,
        PSYS_SRC_BURST_SPEED_MIN, 0.2,
        PSYS_SRC_BURST_SPEED_MAX, 1
    ]);
}

default {
    state_entry() {
        ReadVersionLine();
        llListen(g_initChannel, "", "", "");
        // set all scripts except self to not running
        // also build list of all bundles
        integer i = llGetInventoryNumber(INVENTORY_ALL);
        do { i--;
            string sName = llGetInventoryName(INVENTORY_ALL, i);
            integer sType = llGetInventoryType(sName);
            if (sType == INVENTORY_SCRIPT) {
                // ignore updater scripts.  set others to not running.
                if (llSubStringIndex(sName, "oc_installer"))
                    DisableScript(sName);
            } else if (sType == INVENTORY_NOTECARD) {
                // add card to bundle list if it's a bundle
                if (!llSubStringIndex(sName, "BUNDLE_")) {
                    list lParts = llParseString2List(sName, ["_"], []);
                    g_lBundles += [sName, llList2String(lParts, -1)];
                }
            }
        } while (i);
        g_lBundles = llListSort(g_lBundles,2,TRUE);
        SetFloatText();
        llParticleSystem([]);
    }
    touch(integer iNumber) {
        if (llDetectedKey(0) != llGetOwner()) return;
        integer iChan = -llAbs((integer)("0x"+llGetSubString((string)llGetOwner(),2,7)) + 1111);
        if (iChan > -10000) iChan -= 30000;
        llWhisper(iChan,(string)llGetOwner()+":.- ... -.-"+(string)llGetKey());
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg) {
        if (llGetOwnerKey(kID) != llGetOwner()) return;
        Debug(llDumpList2String([sName, sMsg], ", "));
        if (iChannel == g_initChannel) {
            // everything heard on the init channel is stuff that has to
            // comply with the existing update kickoff protocol.  New stuff
            // will be heard on the random secure channel instead.
            list lParts = llParseString2List(sMsg, ["|"], []);
            string sCmd = llList2String(lParts, 0);
            string sParam = llList2String(lParts, 1);
            if (sCmd == "UPDATE")
                // someone just clicked the upgrade button on their collar.
                llWhisper(g_initChannel,"-.. ---"); //tell collar we are here and to send the pin 
            else if (sCmd == "ready") {
                // person clicked "Yes I want to update" on the collar menu.
                // the script pin will be in the param
                g_iPin = (integer)sParam;     
                g_kCollarKey = kID;
                g_iSecureChannel = (integer)llFrand(-2000000000 + 1);
                llListen(g_iSecureChannel, "", g_kCollarKey, "");
                llRemoteLoadScriptPin(g_kCollarKey, g_sShim, g_iPin, TRUE, g_iSecureChannel);  
            }                
        } else if (iChannel == g_iSecureChannel) {
            if (sMsg == "reallyready") {
                Particles(kID);
                g_iBundleIndex = 0;
                DoBundle();       
            }
        }
    }
    // when we get a BUNDLE_DONE message, move to the next bundle
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == BUNDLE_DONE) {
            // see if there's another bundle
            integer iCount = llGetListLength(g_lBundles);
            g_iBundleIndex += 2;
            if (g_iBundleIndex < iCount) DoBundle();
            else {
                // tell the shim to restore settings, set version, 
                // remove the script pin, and delete himself.
                string sMyVersion = llList2String(llParseString2List(llGetObjectName(), [" - "], []), 1);
                llRegionSayTo(g_kCollarKey, g_iSecureChannel, "DONE|" + sMyVersion);
                SetFloatText();
                llParticleSystem([]);
                llSetTimerEvent(2.0);
            }
        }
    }
    timer() {
        llSetTimerEvent(0);
        llSay(0,"Installation finshed, I am not needed anymore...\nBye bye");
       // llDie();
    }
    
    on_rez(integer iStartParam) {
        llResetScript();
    }

    changed(integer iChange) {
    // Resetting on inventory change ensures that the bundle list is
    // kept current, and that the .version card is re-read if it changes.
        if (iChange & CHANGED_INVENTORY)  llResetScript();
    }

    dataserver(key kID, string sData) {
        if (kID == g_kVersionID) {
            // make sure that object version matches this card.
            g_sVersion = sData;
            SetFloatText();
            list lNameParts = llParseString2List(llGetObjectName(), [" - "], []);
            integer iLength = llGetListLength(lNameParts);
            if (iLength == 2)
                lNameParts = llListReplaceList(lNameParts, [sData], 1, 1);
            else if (iLength == 1)
                lNameParts += [sData];
            llSetObjectName(llDumpList2String(lNameParts, " - "));
        }
    }
}
