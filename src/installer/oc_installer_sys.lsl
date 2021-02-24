// This file is part of OpenCollar.
// Copyright (c) 2011 - 2016 Nandana Singh, Satomi Ahn, DrakeSystem,
// Wendy Starfall, littlemousy, Romka Swallowtail, Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.

// Medea added fancy new rainbow particles!

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


key g_kNameID;
integer g_initChannel = -7483213;
integer g_iLegacyChannel = -7483214;
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

string g_sShim = "oc_update_shim";

integer DO_BUNDLE = 98749;
integer BUNDLE_DONE = 98750;
integer INSTALLATION_DONE = 98751;

integer g_iDone;

string g_sInfoCard = ".info";
string g_sInfoText;
string g_sInfoURL;
key g_kInfoID;
integer g_iLine;

string g_sName;
string g_sObjectType;
string g_sObjectName;

key g_kParticleTarget;
integer g_iRainbowCycle;
list l_ParticleColours=[<1,0,0>,<1.0,0.5,0>,<1,1,0>,<0,1,0>,<0,0.25,1>,<0.25,0,1>,<0.5,0,1>,<1,0,0>];
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

ReadName() {
    // try to keep object's name in sync with ".name" notecard.
    if (llGetInventoryType(".name") == INVENTORY_NOTECARD) {
        g_kNameID = llGetNotecardLine(".name", 0);
    }
}

SetFloatText() {
    llSetText(g_sObjectType+"\n\n "+g_sName/*+"\nBuild Version: "+g_sBuildVersion*/, <1,1,1>, 1.0);
}

Particles(key kTarget) {
    g_kParticleTarget=kTarget;
    vector a=llList2Vector(l_ParticleColours,g_iRainbowCycle);
    vector b=llList2Vector(l_ParticleColours,g_iRainbowCycle+1);
    g_iRainbowCycle++;
    if(g_iRainbowCycle>6) g_iRainbowCycle=0;
    llParticleSystem([
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
            PSYS_SRC_BURST_RADIUS,0,
            PSYS_SRC_ANGLE_BEGIN,0.1,
            PSYS_SRC_ANGLE_END,-0.1,
            PSYS_SRC_TARGET_KEY,g_kParticleTarget,
            PSYS_PART_START_COLOR,a,
            PSYS_PART_END_COLOR,b,
            PSYS_PART_START_ALPHA,1,
            PSYS_PART_END_ALPHA,1,
            PSYS_PART_START_GLOW,0,
            PSYS_PART_END_GLOW,0,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<0.500000,0.500000,0.000000>,
            PSYS_PART_END_SCALE,<0.231000,0.231000,0.000000>,
            PSYS_SRC_TEXTURE,"50f9fb96-f1b5-6357-02b4-5585bc4cc55b",
            PSYS_SRC_MAX_AGE,0,
            PSYS_PART_MAX_AGE,2.9,
            PSYS_SRC_BURST_RATE,0.1,
            PSYS_SRC_BURST_PART_COUNT,5,
            PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.1,
            PSYS_SRC_BURST_SPEED_MAX,0.9,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_EMISSIVE_MASK |
                PSYS_PART_INTERP_COLOR_MASK |
                PSYS_PART_INTERP_SCALE_MASK |
                PSYS_PART_TARGET_POS_MASK
        ]);
        llSensorRepeat("*&^","6b4092ce-5e5a-ff2e-42e0-3d4c1a069b2f",AGENT,0.1,0.1,0.6);
}

InitiateInstallation() {
    integer iChan = -llAbs((integer)("0x"+llGetSubString((string)llGetOwner(),-7,-1)));
    llPlaySound("6b4092ce-5e5a-ff2e-42e0-3d4c1a069b2f",1.0);
    //llPlaySound("3409e593-20ab-fd34-82b3-6ecfdefc0207",1.0); //ao
    //llPlaySound("95d3f6c5-6a27-da1c-d75c-a57cb29c883b",1.0); //remote hud
    llWhisper(iChan,(string)llGetOwner()+":.- ... -.-|"+g_sBuildVersion+"|"+(string)llGetKey());
    //llWhisper(iChan,"-.. --- / .- ---"); AO command
    //llWhisper(iChan,"-.. --- / .... ..- -.."); Remote HUD command
}

PermsCheck() {
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;

        // check permissions on all oc_* scripts
        integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
        while (i) {
            string sScript = llGetInventoryName(INVENTORY_SCRIPT, --i);
            if (llSubStringIndex(sScript, "oc_") == 0) {
                if (!((llGetInventoryPermMask(sScript,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
                        llOwnerSay("The " + sScript + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
                }

                if (!((llGetInventoryPermMask(sScript,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
                        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sScript + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
                }
            }
        }
}

default {
    state_entry() {
        // llPreloadSound("6b4092ce-5e5a-ff2e-42e0-3d4c1a069b2f");
        // llPreloadSound("d023339f-9a9d-75cf-4232-93957c6f620c");
        //llPreloadSound("3409e593-20ab-fd34-82b3-6ecfdefc0207"); // ao
        // llPreloadSound("95d3f6c5-6a27-da1c-d75c-a57cb29c883b"); //remote hud
        llSetTimerEvent(1200.0);
        PermsCheck();
        ReadName();
        g_sObjectName = llGetObjectName();
        llListen(g_initChannel, "", "", "");
        llListen(g_iLegacyChannel, "", "", "");
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
        if (llGetInventoryType(g_sInfoCard) == INVENTORY_NOTECARD)
            g_kInfoID = llGetNotecardLine(g_sInfoCard,0);
    }

    touch_start(integer iNumber) {
        llWhisper(0, "Touching the updater to trigger an update is currently unsupported for 8.0! This will come back in a future update. In the meantime, please use the collar update command or the menu button inside Help/About to initiate update!");
        return;
        if (llDetectedKey(0) != llGetOwner()) return;
        if (g_iDone) {
            g_iDone = FALSE;
            llSetTimerEvent(30.0);
        }
        InitiateInstallation();
    }

    listen(integer iChannel, string sName, key kID, string sMsg) {

        if (llGetOwnerKey(kID) != llGetOwner()) return;
        if (iChannel == g_iLegacyChannel) {
            list lParts = llParseStringKeepNulls(sMsg, ["|"], []);
            string sCmd = llList2String(lParts, 0);
            if (sCmd == "UPDATE") {
                llRegionSayTo(kID, g_iLegacyChannel, "get ready");
                llRegionSayTo(kID, g_iLegacyChannel, "items"); // 3.2 and earlier
            } else if (sCmd == "ready") {
                integer iPin = llList2Integer(lParts, 1);
                llGiveInventory(kID, "leashpoint");
                llRemoteLoadScriptPin(kID, "oc_transform_shim", iPin, TRUE, 1);
            }

        } else if (iChannel == g_initChannel) {
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
                llPlaySound("d023339f-9a9d-75cf-4232-93957c6f620c",1.0);
                if(sParam == "8.0")llWhisper(g_initChannel,"-.. ---|"+g_sBuildVersion); //tell collar we are here and to send the pin
                else llWhisper(g_initChannel, "-.. ---|AppInstall"); // fix for the deprecated message in previous versions
            } else if (sCmd == "ready") {
                // person clicked "Yes I want to update" on the collar menu.
                // the script pin will be in the param
                g_iPin = (integer)sParam;
                g_kCollarKey = kID;
                g_iSecureChannel = (integer)llFrand(-2000000000) - 1;
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
                llSetTimerEvent(0);
                llParticleSystem([]);
                llSensorRemove();
                g_iDone = TRUE;
                llMessageLinked(LINK_SET,INSTALLATION_DONE,"","");
                llSleep(1);
                llLoadURL(llGetOwner(),"\nVisit our website for manual pages and release notes!\n",g_sInfoURL);
                Say(g_sInfoText);
                llSetTimerEvent(15.0);
            }
        }
    }
    timer() {
        if (g_iDone) {
            llResetScript();
        }
        llSetTimerEvent(300);
        if (llVecDist(llGetPos(),llList2Vector(llGetObjectDetails(llGetOwner(),[OBJECT_POS]),0)) > 30) llDie();
    }

    on_rez(integer iStartParam) {
        string sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()),0,1));
        llSay(0, "Thank you for rezzing me.  Next:  In the Collar menu, go to Help/About and press Update. Or, use the chat command '"+sPrefix+" update'.");
        llResetScript();
    }
    no_sensor()
    {
        Particles(g_kParticleTarget);
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
            if (g_sBuildVersion == "" && g_sBuildVersion != "AppInstall") {
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
