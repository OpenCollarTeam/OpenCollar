/*
    _____________________________. 
   |;;|                      |;;||     Copyright (c) 2014 - 2016:
   |[]|----------------------|[]||
   |;;|       AO  Link       |;;||     Medea Destiny, XenHat Liamano,
   |;;|       161015.4       |;;||     Wendy Starfall, Sumi Perl,
   |;;|----------------------|;;||     Ansariel Hiller, Garvin Twine,
   |;;|   www.opencollar.at  |;;||     stawberri et al.
   |;;|----------------------|;;||
   |;;|______________________|;;||
   |;;;;;;;;;;;;;;;;;;;;;;;;;;;;||     This script is free software:
   |;;;;;;;_______________ ;;;;;||
   |;;;;;;|  ___          |;;;;;||     You can redistribute it and/or
   |;;;;;;| |;;;|         |;;;;;||     modify it under the terms of the 
   |;;;;;;| |;;;|         |;;;;;||     GNU General Public License as
   |;;;;;;| |;;;|         |;;;;;||     published by the Free Software
   |;;;;;;| |___|         |;;;;;||     Foundation, version 2.
   \______|_______________|_____||
    ~~~~~~^^^^^^^^^^^^^^^^^^~~~~~~     www.gnu.org/licenses/gpl-2.0

github.com/VirtualDisgrace/opencollar/blob/master/src/spares/.aolink.lsl

*/

string g_sVersion = "4.7"; // keep this simple
key g_kWearer;
integer g_iAOType;
string g_sMyName;
string g_sObjectName;

//If left like this, script will try to determine AO type automatically.
//To force compatibility for a particular type of AO, change to:
// integer g_iAOType=1; //for Oracul type AOs
// integer g_iAOType=2; // for ZHAO-II type AOs
// integer g_iAOType=3; // for Vista type AOs
// integer g_iAOType=4; // for AKEYO type AOs
// integer g_iAOType=5; // for Gaeline type AOs
// integer g_iAOType=7; // for AKEYO NITRO type AOs

//Integer map for above
integer ORACUL  = 1;
integer ZHAO    = 2;
integer VISTA   = 3;
integer AKEYO   = 4;
integer GAELINE = 5;
integer HUDDLES = 6;
integer AKEYO_NITRO = 7;
//just a ordered list to use for notifies
string g_sKnownAOs = "AKEYO, AKEYO_NITRO, GAELINE, HUDDLES, ORACUL, VISTA, ZHAO";

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
    llSetObjectName(g_sMyName);
    if (g_iDebugMode) llSay(0,sStr);
    else llOwnerSay(sStr);
    llSetObjectName(g_sObjectName);
}

determineAOType() { //function to determine AO type.
    llListenRemove(g_iAOListenHandle);
    g_iAOType = 0;
    if (~llSubStringIndex(llGetObjectName(),"AKEYO")) { //AKEYO is not a string in their script name, it is in animations but think the object name is a better test for this AO - Sumi Perl
        if (~llSubStringIndex(llGetObjectName(),"NitroAO")) { // Nitro has different messages.
            g_iAOType = AKEYO_NITRO;
            Say("OC compatibility script configured for AKEYO NITRO AO.  This support is experimental.  Please let us know if you notice any problems.");
        } else {
            g_iAOType = AKEYO;
            Say("OC compatibility script configured for AKEYO AO.  This support is experimental.  Please let us know if you notice any problems.");
        }
    } else if (~llSubStringIndex(llGetObjectName(),"HUDDLES")) {
        g_iAOType = HUDDLES;
        Say("OC compatibility script configured for HUDDLES AO.  This support is experimental.  Please let us know if you notice any problems.");
    }
    if (g_iAOType) jump next ; // no need to check any further if we already have the type identified
    integer x = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(x) {
        --x;
        string sScriptName = llToLower(llGetInventoryName(INVENTORY_SCRIPT,x));
        if(~llSubStringIndex(sScriptName,"vista")) {//if we find a script with "zhao" in the name.
            g_iAOType = VISTA;
            x = 0;
            Say("OC compatibility script configured for VISTA AO. Support is very experimental since it is unknown how much was changed from ZHAO.");
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
        } else if ( ~llSubStringIndex(sScriptName,"huddles")) { //double check if the name wasnt found in the object name already
            g_iAOType = HUDDLES;
            x = 0;
            Say("OC compatibility script configured for HUDDLES AO.  This support is experimental.  Please let us know if you notice any problems.");
        } else if (~llSubStringIndex(sScriptName,"z_ao")) {//if we find a script with "z_ao" in the name.
            g_iAOType = GAELINE;
            x = 0;
            Say("OC compatibility script configured for Gaeline AO. Support is very experimental since it is unknown how much was changed from ZHAO.");
            llMessageLinked(LINK_SET, 103, "", "");
        } else if(~llSubStringIndex(sScriptName,"oracul")) {//if we find a script with "oracul" in the name.
            g_iAOType = ORACUL;
            x = 0;
            Say("OC compatibility script configured for Oracul AO. IMPORTANT: for proper functioning, you must now switch your AO on (switching it off first if necessary!)");
        } else if(~llSubStringIndex(sScriptName,"zhao")) {//if we find a script with "zhao" in the name.
            g_iAOType = ZHAO;
            x = 0;
            Say("OC compatibility script configured for Zhao AO. Depending on your AO model, you may sometimes see your AO buttons get out of sync when the AO is accessed via the collar, just toggle a setting to restore it. NOTE! Toggling sit override now is highly recommended, but if you don't know what that means or don't have one, don't worry.");
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
        }
    }
    @next;
    if(!g_iAOType) Say("Cannot identify AO type after trying to to identify one of the following AOs:\n"+g_sKnownAOs);
    else {
        g_iAOListenHandle = llListen(g_iAOChannel,"","",""); //We identified type, start script listening!
        g_iLMListenHandle = llListen(g_iLMChannel,"","","");
        llRegionSayTo(g_kWearer,g_iHUDChannel,(string)g_kWearer+":antislide off ao");
        Say("Lockmeister protocol support to interact with couple animators and furnitures is enabled, to disable it type:\n/88 LM off\nto enable again\n/88 LM on");
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
        if (llGetInventoryType("oc_sys") == INVENTORY_SCRIPT) {
            Say("I do not belong into a collar... bye.");
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
            if (sMsg == "LM on") {
                Say("Lockmeister support enabled, you can disable it by typing:\n/88 LM off");
                llListenRemove(g_iLMListenHandle);
                g_iLMListenHandle = llListen(g_iLMChannel,"","","");
            } else if (sMsg == "LM off") {
                llListenRemove(g_iLMListenHandle);
                Say("Lockmeister support disabled, you can enable it by typing:\n/88 LM on");
            } else if (sMsg == "version") Say("Version: "+g_sVersion);
            else if (sMsg == "rm aolink") {
                Say("\nRemoving myself, bye!");
                llRemoveInventory(g_sMyName);
            } else if (sMsg == "debug on") {
                g_iDebugMode = TRUE;
                Say("Debug mode is turned on. Remember to turn it off again: \"/88 debug off\"");
            } else if (sMsg == "debug off") {
                Say("Debug mode is off.");
                g_iDebugMode = FALSE;
            }
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
    
    changed(integer change) {
        if(change & CHANGED_OWNER) llResetScript();
    }
}
