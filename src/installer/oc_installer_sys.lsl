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
//                       Installer System - 161029.1                        //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2011 - 2016 Nandana Singh, Satomi Ahn, DrakeSystem,       //
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
//      github.com/OpenCollarTeam/opencollar/tree/master/src/installer     //
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
// name always matches the contents of the ".name" card.


integer g_iInstallOnRez = FALSE; // TRUE initiates right away on rez

key g_kNameID;
integer g_initChannel = -7483213;
//integer g_initChannel = -7483220; channel for AO SIX
//integer g_initChannel = -7483210; channel for Remote HUD SIX
integer g_iSecureChannel;
string g_sBuildVersion;


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
integer INSTALLION_DONE = 98751;

integer g_iDone;
integer g_iIsUpdate;

string g_sInfoCard = ".info";
string g_sInfoText;
string g_sInfoURL;
key g_kInfoID;
integer g_iLine;

string g_sName;
string g_sObjectType;
string g_sObjectName;

// A wrapper around llSetScriptState to avoid the problem where it says it can't
// find scripts that are already not running.
DisableScript(string sName) {
    if (llGetInventoryType(sName) == INVENTORY_SCRIPT) {
        if (llGetScriptState(sName))
            llSetScriptState(sName, FALSE);
    }
}

Say(string sStr) {
    llSetObjectName("Installer");
    llOwnerSay(sStr);
    llSetObjectName(g_sObjectName);
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

ReadName() {
    // try to keep object's name in sync with ".name" notecard.
    if (llGetInventoryType(".name") == INVENTORY_NOTECARD) {
        g_kNameID = llGetNotecardLine(".name", 0);
    }
}

SetFloatText() {
    llSetText(g_sObjectType+"\n\n "+g_sName, <1,1,1>, 1.0);
}

Particles(key kTarget) {
    integer i = llGetNumberOfPrims();
    vector vParticleColor;
    do {
        if (llGetLinkName(i) == "<3") {
            vParticleColor = llList2Vector(llGetLinkPrimitiveParams(i,[PRIM_COLOR,ALL_SIDES]),0);
            i = 1;
        }
    } while (--i > 1);
    llParticleSystem([
        PSYS_PART_FLAGS,
            PSYS_PART_INTERP_COLOR_MASK |
            PSYS_PART_INTERP_SCALE_MASK |
            PSYS_PART_TARGET_POS_MASK |
            PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_SRC_TEXTURE, "930c3304-e899-9266-2ab5-ab9ec3aec2b6",
        PSYS_SRC_TARGET_KEY, kTarget,
        PSYS_PART_START_COLOR, vParticleColor,
        PSYS_PART_END_COLOR, vParticleColor,
       // PSYS_PART_START_COLOR, <0.529, 0.416, 0.212>,
       // PSYS_PART_END_COLOR, <0.733, 0.592, 0.345>,
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

InitiateInstallation() {
    integer iChan = -llAbs((integer)("0x"+llGetSubString((string)llGetOwner(),-7,-1)));
    llPlaySound("6b4092ce-5e5a-ff2e-42e0-3d4c1a069b2f",1.0);
    //llPlaySound("3409e593-20ab-fd34-82b3-6ecfdefc0207",1.0); //ao
    //llPlaySound("95d3f6c5-6a27-da1c-d75c-a57cb29c883b",1.0); //remote hud
    Debug("Playing sound");
    llWhisper(iChan,(string)llGetOwner()+":.- ... -.-|"+g_sBuildVersion+"|"+(string)llGetKey());
    //llWhisper(iChan,"-.. --- / .- ---"); AO command
    //llWhisper(iChan,"-.. --- / .... ..- -.."); Remote HUD command
}

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_installer_sys")
        llRemoveInventory(sName);
}

default {
    state_entry() {
       // llPreloadSound("6b4092ce-5e5a-ff2e-42e0-3d4c1a069b2f");
       // llPreloadSound("d023339f-9a9d-75cf-4232-93957c6f620c");
        //llPreloadSound("3409e593-20ab-fd34-82b3-6ecfdefc0207"); // ao
       // llPreloadSound("95d3f6c5-6a27-da1c-d75c-a57cb29c883b"); //remote hud
        llSetTimerEvent(300.0);
        FailSafe();
        ReadName();
        g_sObjectName = llGetObjectName();
        llListen(g_initChannel, "", "", "");
        // set all scripts except self to not running
        // also build list of all bundles
        list lBundleNumbers;
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
                    lBundleNumbers += llList2List(lParts,1,1);
                }
            }
        } while (i);
        if (~llListFindList(lBundleNumbers,["23"]) || ~llListFindList(lBundleNumbers,["42"])
            || ~llListFindList(lBundleNumbers,["00"])) g_iIsUpdate = TRUE;
        g_lBundles = llListSort(g_lBundles,2,TRUE);
        SetFloatText();
        llParticleSystem([]);
        if (llGetInventoryType(g_sInfoCard) == INVENTORY_NOTECARD)
            g_kInfoID = llGetNotecardLine(g_sInfoCard,0);
    }

    touch_start(integer iNumber) {
        if (llDetectedKey(0) != llGetOwner()) return;
        if (g_iDone) {
            g_iDone = FALSE;
            llSetTimerEvent(30.0);
        }
        InitiateInstallation();
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
            if (sCmd == "UPDATE") {
                // someone just clicked the upgrade button on their collar.
                if (g_iDone) {
                    g_iDone = FALSE;
                    //llSetTimerEvent(30.0);
                }
                Debug("sound");
                llPlaySound("d023339f-9a9d-75cf-4232-93957c6f620c",1.0);
                llWhisper(g_initChannel,"-.. ---|"+g_sBuildVersion); //tell collar we are here and to send the pin
            } else if (sCmd == "ready") {
                // person clicked "Yes I want to update" on the collar menu.
                // the script pin will be in the param
                g_iPin = (integer)sParam;
                g_kCollarKey = kID;
                g_iSecureChannel = (integer)llFrand(-2000000000 + 1);
                if(g_iSecureChannel == 0) g_iSecureChannel = -1234567;
                if (!g_iIsUpdate) g_iSecureChannel = -g_iSecureChannel;
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
                // tell the shim to restore settings, set name,
                // remove the script pin, and delete himself.
                string sMyName = llList2String(llParseString2List(llGetObjectName(), [" - "], []), 1);
                llRegionSayTo(g_kCollarKey, g_iSecureChannel, "DONE|" + sMyName);
                llSetText("DONE!\n \n████████100%████████", <0,1,0>, 1.0);
                llParticleSystem([]);
                g_iDone = TRUE;
                llMessageLinked(LINK_SET,INSTALLION_DONE,"","");
                llSleep(1);
                llLoadURL(llGetOwner(),"\nVisit our website for manual pages and release notes!\n",g_sInfoURL);
                Say(g_sInfoText);
                llSetTimerEvent(15.0);
            }
        }
    }
    timer() {
        if (g_iDone) {
            if (g_iInstallOnRez) SetFloatText();
            else llResetScript();
        }
        llSetTimerEvent(300);
        if (llVecDist(llGetPos(),llList2Vector(llGetObjectDetails(llGetOwner(),[OBJECT_POS]),0)) > 30) llDie();
    }

    on_rez(integer iStartParam) {
        llResetScript();
    }

    changed(integer iChange) {
    // Resetting on inventory change ensures that the bundle list is
    // kept current, and that the .name card is re-read if it changes.
        if (iChange & CHANGED_INVENTORY) llResetScript();
    }

    dataserver(key kID, string sData) {
        if (kID == g_kNameID) {
            // make sure that object name matches this card.
            integer index = llSubStringIndex(sData,"&");
            g_sBuildVersion = llStringTrim(llGetSubString(sData,index+1,-1),STRING_TRIM);
            if ((float)g_sBuildVersion == 0.0 && g_sBuildVersion != "AppInstall") {
                llOwnerSay("Invalid .name notecard, please fix!");
                return;
            }
            sData = llStringTrim(llGetSubString(sData,0, index-1),STRING_TRIM);
            list lNameParts = llParseString2List(sData, [" - "], []);
            g_sObjectName = sData;
            llSetObjectName(sData);
            g_sName = llList2String(lNameParts,1);
            g_sObjectType = llList2String(lNameParts,0);
            SetFloatText();
            if (g_iInstallOnRez) InitiateInstallation();
        }
        if (kID == g_kInfoID) {
            if (sData != EOF) {
                g_iLine++;
                if (g_iLine == 1) g_sInfoURL = sData;
                else g_sInfoText += "\n"+sData;
                g_kInfoID = llGetNotecardLine(g_sInfoCard,g_iLine);
            } else g_iLine = 0;
        }

    }
}
