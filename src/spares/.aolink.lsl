// This file is part of OpenCollar.
// Copyright (c) 2014 - 2016 Medea Destiny, XenHat Liamano, Wendy Starfall, Sumi Perl, Ansariel Hiller,
// Garvin Twine, stawberri et al.
// Licensed under the GPLv2.  See LICENSE for full details. 

/*
Right-click and edit your AO HUD, then navigate to the Contents tab of
the Build Menu. Once the contents finish loading, drag and drop this
script from your Inventory into the Contents tab of your AO HUD. If the
AO Link is compatible with your AO HUD, it will indicate so in the Chat.

NOTE: Please be aware that some shops sell modified GPL licensed ZHAOII
scripts in their AOs with closed permissions and without publishing the
source code anywhere. If your AO reports having successfully linked but
goes haywire chances are that this is such a case. This is very sad and
the only thing you can do then is to remove the link with: /88 rm aolink

*/

string g_sVersion = "4.7"; // keep this simple
key g_kWearer;
integer g_iAOType;
string g_sMyName;
string g_sObjectName;

//integer map for g_iAOType
integer ORACUL      = 1;
integer ZHAO        = 2;
integer VISTA       = 3;
integer AKEYO       = 4;
integer GAELINE     = 5;
integer HUDDLES     = 6;
integer AKEYO_NITRO = 7;

//integer g_iAOType = i; // enabling this will try to force compatibility with the AO type of the corresponding integer instead of letting the script automatically detect it

//just a ordered list to use for notifies
string g_sKnownAOs = "AKEYO, Gaeline, Huddles, Oracul, Vista and ZHAO";

// OC channel listener for comms from collar
integer g_iAOChannel = -782690;
integer g_iAOListenHandle;
integer g_iHUDChannel;

//Lockmeister protocol support for couple animations and furnitures

integer g_iLMChannel = -8888;
integer g_iLMListenHandle;
integer g_iCommandChannel = 88;

integer g_iDebugMode;

string g_sOraculstring; //configuration string for Oracul power on/off, 0 prepended for off, 1 prepended for on

//We use these two so that we can return the AO to its previous state. If the AO was already off when the OC tries to switch it off, we shouldn't switch it back on again.
integer g_iAOSwitch = TRUE; //monitor on/off from the AO's own state.
integer g_iOCSwitch = TRUE; //monitor on/off due to collar pauses (FALSE=paused, TRUE=unpaused)
integer g_iSitOverride = TRUE; //monitor AO sit override

Say(string sStr) {
    llSetObjectName("AO Link v"+g_sVersion);
    if (g_iDebugMode) llSay(0,sStr);
    else llOwnerSay(sStr);
    llSetObjectName(g_sObjectName);
}

determineAOType() { //function to determine AO type.
    llListenRemove(g_iAOListenHandle);
    string sNotifyBegin = "\n\nCongratulations! Your ";
    string sNotifyEnd = " has been successfully linked with OpenCollar™. Your AO will now pause itself when you play a pose or couples animation with your collar. To make things work smoothly, please push the power button on your AO HUD off/on once.\n\nFor a list of commands type: /88 help\n";
    g_iAOType = 0;
    if (~llSubStringIndex(llGetObjectName(),"AKEYO")) { //AKEYO is not a string in their script name, it is in animations but think the object name is a better test for this AO - Sumi Perl
        if (~llSubStringIndex(llGetObjectName(),"NitroAO")) { // Nitro has different messages.
            g_iAOType = AKEYO_NITRO;
            Say(sNotifyBegin+"AKEYO NITRO AO"+sNotifyEnd);
        } else {
            g_iAOType = AKEYO;
            Say(sNotifyBegin+"AKEYO AO"+sNotifyEnd);
        }
    } else if (~llSubStringIndex(llGetObjectName(),"HUDDLES")) {
        g_iAOType = HUDDLES;
        Say(sNotifyBegin+"Huddles AO"+sNotifyEnd);
    }
    if (g_iAOType) jump next ; // no need to check any further if we already have the type identified
    integer x = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(x) {
        --x;
        string sScriptName = llToLower(llGetInventoryName(INVENTORY_SCRIPT,x));
        if(~llSubStringIndex(sScriptName,"vista")) {//if we find a script with "zhao" in the name.
            g_iAOType = VISTA;
            x = 0;
            Say(sNotifyBegin+"Vista AO"+sNotifyEnd);
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
        } else if ( ~llSubStringIndex(sScriptName,"huddles")) { //double check if the name wasnt found in the object name already
            g_iAOType = HUDDLES;
            x = 0;
            Say(sNotifyBegin+"Huddles AO"+sNotifyEnd);
        } else if (~llSubStringIndex(sScriptName,"z_ao")) {//if we find a script with "z_ao" in the name.
            g_iAOType = GAELINE;
            x = 0;
            Say(sNotifyBegin+"Gaeline AO"+sNotifyEnd);
            llMessageLinked(LINK_SET, 103, "", "");
        } else if(~llSubStringIndex(sScriptName,"oracul")) {//if we find a script with "oracul" in the name.
            g_iAOType = ORACUL;
            x = 0;
            Say(sNotifyBegin+"Oracul AO"+sNotifyEnd);
        } else if(~llSubStringIndex(sScriptName,"zhao")) {//if we find a script with "zhao" in the name.
            g_iAOType = ZHAO;
            x = 0;
            Say(sNotifyBegin+"ZHAO AO"+sNotifyEnd);
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
        }
    }
    @next;
    if(!g_iAOType) Say("\n\nOops! Either I landed in something that's not an AO or I'm not yet familiar with this type of AO. At version "+g_sVersion+" I know how to link with "+g_sKnownAOs+" AOs. Maybe there is a newer version of me available if you copy and paste my [https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/src/spares/.aolink.lsl recent source] in a new script!\n");
    else {
        g_iAOListenHandle = llListen(g_iAOChannel,"","",""); //We identified type, start script listening!
        g_iLMListenHandle = llListen(g_iLMChannel,"","","");
        llRegionSayTo(g_kWearer,g_iHUDChannel,(string)g_kWearer+":antislide off ao");
    }
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



AOPause() {
    if(g_iAOSwitch) {
        if (g_iAOType == ORACUL && g_sOraculstring != "") llMessageLinked(LINK_SET,0,"0"+g_sOraculstring,"ocpause");
        else if (g_iAOType == AKEYO) llMessageLinked(LINK_ROOT, 0, "PAO_AOOFF", "ocpause");
        else if (g_iAOType == AKEYO_NITRO) llMessageLinked(LINK_ROOT, 0, "NITRO_AOOFF", "ocpause");
        else if (g_iAOType == GAELINE) llMessageLinked(LINK_THIS, 102, "", "ocpause");
        else if (g_iAOType == HUDDLES) llMessageLinked(LINK_THIS, 4900, "AO_OFF", "ocpause");
        //Note: for ZHAO use LINK_THIS in pause functions, LINK_SET elsewhere. This is because ZHAOs which switch power on buttons by a script in the button reading the link messages are quite common. This avoids toggling the power switch when AO is only paused in those cases.
        else if(g_iAOType > 1) llMessageLinked(LINK_THIS, 0, "ZHAO_AOOFF", "ocpause");//we use "ocpause" as a dummy key to identify our own linked messages so we can tell when an on or off comes from the AO rather than from the collar standoff, to sync usage.
        llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS); // we assume that the AO is turned on and take controls to be able overriding walks when pushing arrow or WASD buttons
    }
    g_iOCSwitch = FALSE;
}

AOUnPause() {
    if(g_iAOSwitch) {
        if (g_iAOType == ORACUL && g_sOraculstring != "") llMessageLinked(LINK_SET,0,"1"+g_sOraculstring,"ocpause");
        else if(g_iAOType == AKEYO) llMessageLinked(LINK_ROOT, 0, "PAO_AOON", "ocpause");
        else if(g_iAOType == AKEYO_NITRO) llMessageLinked(LINK_ROOT, 0, "NITRO_AOON", "ocpause");
        else if(g_iAOType == GAELINE) llMessageLinked(LINK_THIS, 103, "", "ocpause");
        else if (g_iAOType == HUDDLES) llMessageLinked(LINK_THIS, 4900, "AO_ON", "ocpause");
        else if(g_iAOType > 1) llMessageLinked(LINK_THIS, 0, "ZHAO_AOON", "ocpause");
        if(llGetPermissionsKey()) llReleaseControls(); // release now if we gave perms to take control
    }
    g_iOCSwitch = TRUE;
}

default {
    state_entry() {
        g_sMyName = llGetScriptName();
        g_sObjectName = llGetObjectName();
        PermsCheck();
        if (llGetInventoryType("oc_sys") == INVENTORY_SCRIPT) {
            Say("\n\nPlease drop me into an AO, I don't belong into a collar! Cleaning myself up here.\n");
            llRemoveInventory(g_sMyName);
        } else if (llGetInventoryType("oc_ao") == INVENTORY_SCRIPT || llGetInventoryType("oc_ao_interface") == INVENTORY_SCRIPT) {
            Say("\n\nPlease don't drop me into the OpenCollar AO, I'm not needed in there as it already works just fine. Just drop me into any other AO to make it OpenCollar compatible if you want. Cleaning myself up here.\n");
            llRemoveInventory(g_sMyName);
        } else if (llGetInventoryType("OpenCollarAttch - Interface") == INVENTORY_SCRIPT) {
            Say("\n\nPlease don't drop me into the OpenCollar Sub AO, I'm not needed in there. Just drop me into any other AO to make it OpenCollar compatible if you want. If you are trying to update a very old Sub AO, please find a cost-free replacement at any official OpenCollar location or network vendor. Cleaning myself up here.\n");
            llRemoveInventory(g_sMyName);
        }
        g_kWearer = llGetOwner();
        llListen(g_iCommandChannel,"",g_kWearer,"");
        llSetTimerEvent(1.0);
        llMessageLinked(LINK_SET,161014,"aolink:"+g_sVersion,g_sMyName);
        g_iHUDChannel = -llAbs((integer)("0x"+llGetSubString((string)g_kWearer,-7,-1)));
        determineAOType();
    }

    timer() {
        llSetTimerEvent(0);
        integer i = llGetInventoryNumber(INVENTORY_SCRIPT);
        string sName;
        while (i) {
            sName = llToLower(llGetInventoryName(INVENTORY_SCRIPT,--i));
            if ((~llSubStringIndex(sName,"aolink") || ~llSubStringIndex(sName,"ao link"))
                && sName != g_sMyName) llRemoveInventory(sName);
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg) {
        if (iChannel == g_iCommandChannel) {
            if (sMsg == "lm on") {
                Say("\n\nLockMeister protocol support for couple animators and furniture has been enabled.\n");
                llListenRemove(g_iLMListenHandle);
                g_iLMListenHandle = llListen(g_iLMChannel,"","","");
            } else if (sMsg == "lm off") {
                llListenRemove(g_iLMListenHandle);
                Say("\n\nLockMeister protocol support for couple animators and furniture has been disabled.\n");
            } else if (sMsg == "version") Say("I'm version "+g_sVersion);
            else if (sMsg == "rm aolink") {
                Say("\n\nRemoving AO Link v"+g_sVersion+". If you want to link this AO with OpenCollar again, please copy and paste the [https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/src/spares/.aolink.lsl recent source] of the AO Link in a new script or ask the community for an already compiled variation.\n");
                llRemoveInventory(g_sMyName);
            } else if (sMsg == "debug on") {
                g_iDebugMode = TRUE;
                Say("Let's debug!");
            } else if (sMsg == "debug off") {
                Say("I'm done debugging.");
                g_iDebugMode = FALSE;
            } else if (sMsg == "help") Say("\n\n/88 lm on|off ... lockmeister support on/off\n/88 debug on|off ... debug mode on/off\n/88 version ... print the version\n/88 rm aolink ... remove the script\n"); //why can't chat be monospaced >:(
        } else if (iChannel == g_iLMChannel) {
            if (llGetSubString(sMsg,0,35) == g_kWearer) {
                sMsg = llGetSubString(sMsg,36,-1);
                if (sMsg == "booton") AOUnPause();
                else if (sMsg == "bootoff") AOPause();
            } else return;
        } else if(llGetOwnerKey(kID) != g_kWearer) return;
        else if (iChannel == g_iAOChannel) {
            if(sMsg == "ZHAO_STANDON" || sMsg == "ZHAO_AOON") AOUnPause();
            else if (sMsg == "ZHAO_STANDOFF" || sMsg == "ZHAO_AOOFF") AOPause();
            else if (!llSubStringIndex(sMsg,"ZHAO_MENU") && llGetOwnerKey(kID) == g_kWearer) {
                if(g_iAOType == ORACUL)
                    llMessageLinked(LINK_SET,4,"",llGetSubString(sMsg,10,-1));
            }
        }
    }

    link_message(integer iPrim, integer iNum, string sMsg, key kID) {
        if (g_iDebugMode) Say("Debug:\niNum = "+(string)iNum+"\nMessage = "+sMsg);
        if (iNum == 161014 && kID != g_sMyName) {
            llSetTimerEvent(0);
            if (!llSubStringIndex(sMsg,"aolink:")) {
                float fVersion = (float)llGetSubString(sMsg,llSubStringIndex(sMsg,":")+1,-1);
                if (fVersion > (float)g_sVersion)
                    llRemoveInventory(g_sMyName);
                else if (fVersion == (float)g_sVersion) {
                    if ((integer)llGetSubString(g_sMyName,-1,-1))
                        llRemoveInventory(g_sMyName);
                    else llRemoveInventory((string)kID);
                } else
                    llMessageLinked(LINK_SET,161014,"aolink:"+g_sVersion,g_sMyName);
            }
            return;
        }
        if (g_iAOType == ORACUL && iNum == 0 && kID != "ocpause") {//oracul power command
                g_sOraculstring = llGetSubString(sMsg,1,-1); //store the config string for Oracul AO.
                g_iAOSwitch = (integer)llGetSubString(sMsg,0,1); //store the AO power state.
                if(!g_iAOSwitch && llGetPermissions()) llReleaseControls(); // no need for input controls
                if (g_iAOSwitch) llRegionSayTo(g_kWearer,g_iHUDChannel,(string)g_kWearer+":antislide off ao");
        } else if(g_iAOType > 1) {
            if (sMsg == "ZHAO_SITON") g_iSitOverride = TRUE;
            else if (sMsg == "ZHAO_SITOFF") g_iSitOverride = FALSE;
            else if(kID != "ocpause") {
            //ignore pause commands sent by this script, we want to know what the "correct" state is.
                if(sMsg == "ZHAO_AOON") g_iAOSwitch = TRUE;
                else if(sMsg == "ZHAO_AOOFF")
                    g_iAOSwitch = FALSE;
                    if(llGetPermissions()) llReleaseControls(); // no need for input controls
            }
            if (g_iAOSwitch) llRegionSayTo(g_kWearer,g_iHUDChannel,(string)g_kWearer+":antislide off ao");
        }
    }

    run_time_permissions(integer iPerms) {
    //when the AO is turned on yet "paused" because we also play a collar pose, we want perms to know pushing arrow or WASD keys to override the walk anyway (without AntiSlide)
        if(iPerms & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD|CONTROL_LEFT|CONTROL_BACK|CONTROL_RIGHT,TRUE,TRUE);
    }

    control(key id, integer level, integer edge) {
        if(!g_iAOSwitch || g_iOCSwitch) {
            llReleaseControls();
            return;
        //the AO is turned off and we aren't playing any collar poses so let's get out of here
        }
        if(level & edge) {// we are pushing arrows or WASD
            if(g_iAOType > 1) llMessageLinked(LINK_THIS, 0, "ZHAO_AOON", "ocpause");
            else if (g_iAOType == ORACUL && g_sOraculstring != "") llMessageLinked(LINK_THIS,0,"1"+g_sOraculstring,"ocpause");
        } else if (!level & edge) {// we don't push any movement related keys, or released a pushed key
            if(g_iAOType > 1) llMessageLinked(LINK_THIS, 0, "ZHAO_AOOFF", "ocpause");
            else if (g_iAOType == ORACUL && g_sOraculstring != "") llMessageLinked(LINK_THIS,0,"0"+g_sOraculstring,"ocpause");
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) PermsCheck();

    }
}
