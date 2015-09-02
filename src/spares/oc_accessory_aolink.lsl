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
//                          AO Link - 150902.1                              //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Medea Destiny, XenHat Liamano, Silkie Sabra,  //
//  Wendy Starfall, Sumi Perl, Ansariel Hiller and Garvin Twine             //
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
//         github.com/OpenCollar/opencollar/tree/master/src/spares          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// Based on Medea Destiny's AO interface script for OpenCollar.

// HOW TO: This script is intended to be dropped into ZHAO-2, Vista and Oracul
// AOs that are not already compatible with OpenCollar's AO interface. Just rez
// your existing AO Hud, right-click to open it and drop this script inside!

// This is not a complete replacement of the Sub AO as it cannot allow as complete
// access to the AO as that does, but it should provide most of the functionality
// while being very easy to add to your pre-existing AOs.

// The lite variation of this script is complementary to AntiSlide technology.

integer iType; 
//If left like this, script will try to determine AO type automatically.
//To force compatibility for a particular type of AO, change to:
// integer iType=1; //for Oracul type AOs
// integer iType=2; // for ZHAO-II type AOs
// integer iType=3; // for Vista type AOs
// integer iType=4; // for AKEYO type AOs
// integer iType=5; // for Gaeline type AOs
//----------------------------------------------------------------------
//Integer map for above
integer ORACUL  = 1; 
integer ZHAO    = 2;
integer VISTA   = 3;
integer AKEYO   = 4;
integer GAELINE = 5;
integer HUDDLES = 6;

// OC channel listener for comms from collar
integer g_iAOChannel = -782690;
integer g_iAOListenHandle;

//Lockmeister protocol support for couple animations and furnitures

integer g_iLMChannel = -8888;
integer g_iLMListenHandle;
integer g_iCommandChannel = 88;
integer g_iCommandHandle;

//Menu handler for script's own ZHAO menu
integer g_iMenuHandle; 
integer g_iMenuChannel = -23423456; //dummy channel, changed to unique on attach
list g_lMenuUsers; //list of menu users to allow for multiple users of menu 
integer g_iMenuTimeout = 60;

string g_sOraculstring; //configuration string for Oracul power on/off, 0 prepended for off, 1 prepended for on

//We use these two so that we can return the AO to its previous state. If the AO was already off when the OC tries to switch it off, we shouldn't switch it back on again.
integer g_iAOSwitch = TRUE; //monitor on/off from the AO's own state.
integer g_iOCSwitch = TRUE; //monitor on/off due to collar pauses (FALSE=paused, TRUE=unpaused)

integer g_iSitOverride = TRUE; //monitor AO sit override

key g_kWearer;

determineType() { //function to determine AO type.
    llListenRemove(g_iAOListenHandle);
    iType = 0;
    if (llSubStringIndex(llGetObjectName(),"AKEYO") >= 0) { //AKEYO is not a string in their script name, it is in animations but think the object name is a better test for this AO - Sumi Perl
        iType = AKEYO;
        llOwnerSay("OC compatibility script configured for AKEYO AO.  This support is experimental.  Please let us know if you notice any problems.");
    } else if (llSubStringIndex(llGetObjectName(),"HUDDLES") >= 0) { 
        iType = HUDDLES;
        llOwnerSay("OC compatibility script configured for HUDDLES AO.  This support is experimental.  Please let us know if you notice any problems.");
    }
    if (iType) jump next ; // no need to check any further if we already have the type identified
    integer x = llGetInventoryNumber(INVENTORY_SCRIPT);
    while(x) {
        --x;
        string sScriptName = llToLower(llGetInventoryName(INVENTORY_SCRIPT,x));
        if(~llSubStringIndex(sScriptName,"vista")) {//if we find a script with "zhao" in the name.
            iType=VISTA;
            x=0;
            llOwnerSay("OC compatibility script configured for VISTA AO. Support is very experimental since it is unknown how much was changed from ZHAO.");
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
        } else if ( ~llSubStringIndex(sScriptName,"huddles")) { //double check if the name wasnt found in the object name already
            iType = HUDDLES;
            x=0;
            llOwnerSay("OC compatibility script configured for HUDDLES AO.  This support is experimental.  Please let us know if you notice any problems.");
        } else if (~llSubStringIndex(sScriptName,"z_ao")) {//if we find a script with "z_ao" in the name.
            iType=GAELINE;
            x=0;
            llOwnerSay("OC compatibility script configured for Gaeline AO. Support is very experimental since it is unknown how much was changed from ZHAO.");
            llMessageLinked(LINK_SET, 103, "", "");
        } else if(~llSubStringIndex(sScriptName,"oracul")) {//if we find a script with "oracul" in the name.
            iType=ORACUL;
            x=0;
            llOwnerSay("OC compatibility script configured for Oracul AO. IMPORTANT: for proper functioning, you must now switch your AO on (switching it off first if necessary!)");
        } else if(~llSubStringIndex(sScriptName,"zhao")) {//if we find a script with "zhao" in the name.
            iType=ZHAO;
            x=0;
            llOwnerSay("OC compatibility script configured for Zhao AO. Depending on your AO model, you may sometimes see your AO buttons get out of sync when the AO is accessed via the collar, just toggle a setting to restore it. NOTE! Toggling sit override now is highly recommended, but if you don't know what that means or don't have one, don't worry.");
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
        }
    }
    @next;
    if(iType == 0) llOwnerSay("Cannot identify AO type. The script:"+llGetScriptName()+" is intended to be dropped into a Zhao2 or Oracul AO hud.");
    else {
        g_iAOListenHandle = llListen(g_iAOChannel,"","",""); //We identified type, start script listening!
        g_iLMListenHandle = llListen(g_iLMChannel,"","","");
        g_iCommandHandle = llListen(g_iCommandChannel,"",g_kWearer,"");
        llOwnerSay("Lockmeister protocol support to interact with couple animators and furnitures is enabled, to disable it type:\n/88 LM off\nto enable again\n/88 LM on");
    }
}


AOPause() {
    if(g_iAOSwitch) {
        if (iType == ORACUL && g_sOraculstring != "") llMessageLinked(LINK_SET,0,"0"+g_sOraculstring,"ocpause");
        else if (iType == AKEYO) llMessageLinked(LINK_ROOT, 0, "PAO_AOOFF", "ocpause");
        else if(iType == GAELINE) llMessageLinked(LINK_THIS, 102, "", "ocpause");
        else if (iType == HUDDLES) llMessageLinked(LINK_THIS, 4900, "AO_OFF", "ocpause");
        //Note: for ZHAO use LINK_THIS in pause functions, LINK_SET elsewhere. This is because ZHAOs which switch power on buttons by a script in the button reading the link messages are quite common. This avoids toggling the power switch when AO is only paused in those cases.
        else if(iType > 1) llMessageLinked(LINK_THIS, 0, "ZHAO_AOOFF", "ocpause");//we use "ocpause" as a dummy key to identify our own linked messages so we can tell when an on or off comes from the AO rather than from the collar standoff, to sync usage.

    }
    g_iOCSwitch=FALSE;
}

AOUnPause() {
    if(g_iAOSwitch) {
        if (iType == ORACUL && g_sOraculstring != "") llMessageLinked(LINK_SET,0,"1"+g_sOraculstring,"ocpause");
        else if(iType == AKEYO ) llMessageLinked(LINK_ROOT, 0, "PAO_AOON", "ocpause"); 
        else if(iType == GAELINE) llMessageLinked(LINK_THIS, 103, "", "ocpause");
        else if (iType == HUDDLES) llMessageLinked(LINK_THIS, 4900, "AO_ON", "ocpause");
        else if(iType>1 ) llMessageLinked(LINK_THIS, 0, "ZHAO_AOON", "ocpause"); 
    }
    g_iOCSwitch=TRUE;
}

zhaoMenu(key kMenuTo) {
    //script's own menu for some ZHAO features. 
    //Open listener if no menu users are registered in g_lMenuUsers already, and add 
    //menu user to list if not already present.
    if(!llGetListLength(g_lMenuUsers)) g_iMenuHandle=llListen(g_iMenuChannel,"","","");
    if(llListFindList(g_lMenuUsers,[kMenuTo])==-1) g_lMenuUsers+=kMenuTo;
    string sSit = "AO Sits ON";
    if(g_iSitOverride) sSit = "AO Sits OFF";
    list lButtons=[sSit,"Load Notecard","Done","AO on","AO off","Next Stand"];
    llSetTimerEvent(g_iMenuTimeout);
    llDialog(kMenuTo,"AO options. Depending on model of AO, some may not work. Use OC Sub AO for more comprehensive control!",lButtons,g_iMenuChannel);   
}

MenuCommand(string sMsg, key kID) {
    if(sMsg == "Done" || sMsg == "Cancel") {
        integer i = llListFindList(g_lMenuUsers,[kID]);
        if(i > -1) g_lMenuUsers=llDeleteSubList(g_lMenuUsers,i,i); //remove user from menu users list.
        if(!llGetListLength(g_lMenuUsers)) {//remove listener if no menu users left
            llListenRemove(g_iMenuHandle);
            llSetTimerEvent(0);
        }
        return; // we're done here!
    } else if(sMsg == "Load Notecard") {//scan for notecards and provide a dialog to user
        list lButtons;
        integer x = llGetInventoryNumber(INVENTORY_NOTECARD);
        while(x) {
            x--;
           string sCardName = llGetInventoryName(INVENTORY_NOTECARD,x);
           if(llSubStringIndex(llToLower(sCardName),"read me") == -1 && llSubStringIndex(llToLower(sCardName),"help") == -1 && llStringLength(sCardName) < 23) lButtons += sCardName; //we only take notecards without "help" or "read me" in the title and with short enough names to fit on a button.
        }
        if(llGetListLength(lButtons) > 11) {
            llRegionSayTo(kID,0,"Too many notecards found, displaying the first 11"); //ZHAO doesn't bother multi pages, so we won't.
            lButtons = llDeleteSubList(lButtons,11,-1);
        }
        llSetTimerEvent(g_iMenuTimeout);
        llDialog(kID,"Pick an AO settings notecard to load, or click Cancel",lButtons+["Cancel"],g_iMenuChannel);
        
    } else if(sMsg == "AO Sits ON") {
        g_iSitOverride = TRUE; //this will get set by the link message anyway, but set here just in case remenu happens before link message is read.
        llMessageLinked(LINK_SET,0,"ZHAO_SITON","");
    } else if(sMsg == "AO Sits OFF") {
        g_iSitOverride = FALSE;
        llMessageLinked(LINK_SET,0,"ZHAO_SITOFF","");
    } else if(sMsg == "AO on") {
        if(g_iOCSwitch) llMessageLinked(LINK_SET,0,"ZHAO_AOON",""); // don't switch on AO if we are paused
        g_iAOSwitch = TRUE;
    }
    else if(sMsg == "AO off")
        llMessageLinked(LINK_SET,0,"ZHAO_AOOFF","");
    else if(sMsg=="Next Stand") {
        if(iType == 2) // ZHAO-II
            llMessageLinked(LINK_SET,0,"ZHAO_NEXTSTAND","");
        else // VISTA                
            llMessageLinked(LINK_SET,0,"ZHAO_NEXTPOSE","");
    //check if sMsg is a notecard picked from Load Notecard menu, and send load command if so.
    } else  if(llGetInventoryType(sMsg) == INVENTORY_NOTECARD) llMessageLinked(LINK_THIS,0,"ZHAO_LOAD|"+sMsg,"");
    //resend the menu where it makes sense.
    if(sMsg!="Done" && sMsg!="Cancel" && sMsg!="Load Notecard") zhaoMenu(kID);
}
                                   
default {
    state_entry() {
        g_kWearer = llGetOwner();
        if(iType == 0) determineType();
        g_iMenuChannel = -(integer)llFrand(999999)-10000; //randomise menu channel
    }
    
    attach(key kAvatar) {
        if(kAvatar) {//on attach
            if(iType == 0) determineType();
            g_iMenuChannel = -(integer)llFrand(999999)-10000; //randomise menu channel 
        }  
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg) {
        if(iChannel == g_iMenuChannel) {// this is for our own limited ZHAO menu.
            MenuCommand(sMsg,kID);
            return;
        } else if (iChannel == g_iCommandChannel) {
            if (sMsg == "LM on") {
                llOwnerSay("Lockmeister support enabled, you can disable it by typing:\n/88 LM off");
                llListenRemove(g_iLMListenHandle);
                g_iLMListenHandle = llListen(g_iLMChannel,"","","");
            } else if (sMsg == "LM off") {
                llListenRemove(g_iLMListenHandle);
                llOwnerSay("Lockmeister support disabled, you can enable it by typing:\n/88 LM on");
            }
            return;
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
            else if ((llGetSubString(sMsg,0,8) == "ZHAO_MENU") && (llGetOwnerKey(kID) == g_kWearer)) {
                key kMenuTo = (key)llGetSubString(sMsg,10,-1);
                if(iType == ORACUL) llMessageLinked(LINK_SET,4,"",kMenuTo);
                else if (iType > 1) zhaoMenu(kMenuTo);
            }
        }
    }
    
    link_message(integer iPrim, integer iNum, string sMsg, key kID) {
        if (iType == ORACUL && iNum == 0 && kID != "ocpause") {//oracul power command
                g_sOraculstring = llGetSubString(sMsg,1,-1); //store the config string for Oracul AO.
                g_iAOSwitch = (integer)llGetSubString(sMsg,0,1); //store the AO power state.
        } else if(iType > 1) {
            if (sMsg == "ZHAO_SITON") g_iSitOverride=TRUE;
            else if (sMsg == "ZHAO_SITOFF") g_iSitOverride=FALSE;
            else if(kID != "ocpause") {//ignore pause commands sent by this script, we want to know what the "correct" state is.
                if(sMsg == "ZHAO_AOON") g_iAOSwitch=TRUE;
                else if(sMsg == "ZHAO_AOOFF")
                    g_iAOSwitch = FALSE;
            }          
        }
    }
        
    timer() {
        llSetTimerEvent(0);
        llListenRemove(g_iMenuHandle);
        g_lMenuUsers = []; //clear list
    }
    
    changed(integer change) {
        if(change & CHANGED_OWNER) llResetScript();
    }  
}
