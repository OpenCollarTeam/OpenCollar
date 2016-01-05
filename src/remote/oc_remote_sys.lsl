//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//       Remote System - 160101.1        .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, //
//  Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.   //
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
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//merged HUD-menu, HUD-leash and HUD-rezzer into here June 2015 Otto (garvin.twine)

string g_sVersion = "160101.1";
integer g_iUpdateAvailable;
key g_kWebLookup;
string version_check_url = "";

list g_lSubs = [];
list g_lNewSubIDs;

//  list of hud channel handles we are listening for, for building lists
list g_lListeners;

string g_sMainMenu = "Main";

//  Notecard reading bits
string  g_sCard = ".subs";
key     g_kCardID = NULL_KEY;
key     g_kLineID;
integer g_iLineNr;

integer g_iListener;
integer g_iCmdListener;
integer g_iChannel = 7;

key g_kUpdater;
integer g_iUpdateChan = -7483210;

//  save cmd here while we give the sub menu to decide who to send it to
string g_sPendingCmd;

//  MESSAGE MAP
integer CMD_TOUCH            = 100;

integer MENUNAME_REQUEST     = 3000;
integer MENUNAME_RESPONSE    = 3001;
integer SUBMENU              = 3002;

integer DIALOG               = -9000;
integer DIALOG_RESPONSE      = -9001;
integer DIALOG_TIMEOUT       = -9002;

//integer SEND_CMD_PICK_SUB    = -1002;
//integer SEND_CMD_ALL_SUBS    = -1003;
//integer SEND_CMD_SUB         = -1005;
//integer SEND_CMD_NEARBY_SUBS = -1006;

//integer LOCALCMD_REQUEST     = -2000;
//integer LOCALCMD_RESPONSE    = -2001;
//integer DIALOG_URL           = -2002;

integer CMD_UPDATE    = 10001;

string UPMENU          = "BACK";

string g_sListSubs  = "List Subs";
string g_sRemoveSub    = "Remove";
//string list   = "Reload Menu";
string g_sScanSubs     = "Add";
string g_sLoadCard     = "Load";
string g_sPrintSubs    = "Print";
string g_sAllSubs      = "ALL";

list g_lMainMenuButtons = ["MANAGE","Collar","Rezzers","Pose","RLV","Sit","Stand","Leash"];//,"HUD Style"];
list g_lMenus ;

key    g_kRemovedSubID;
key    g_kOwner;

//  three strided list of avkey, dialogid, and menuname
key    g_kMenuID;
string g_sMenuType;

integer g_iScanRange        = 20;
integer g_iRLVRelayChannel  = -1812221819;
integer g_iCageChannel      = -987654321;
list    g_lCageVictims;
key     g_kVictimID;
string  g_sRezObject;


/*integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

string NameURI(key kID) {
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

integer getPersonalChannel(key kID) {
    integer iChan = -llAbs((integer)("0x"+llGetSubString((string)kID,2,7)) + 1111);
    if (iChan > -10000) iChan -= 30000;
    return iChan;
}

SetCmdListener() {
    llListenRemove(g_iCmdListener);
    g_iCmdListener = llListen(g_iChannel,"",g_kOwner,"");
}

integer InSim(key kID) {
//  check if the AV is logged in and in Sim
    return (llGetAgentSize(kID) != ZERO_VECTOR);
}

SendCmd(key kID, string sCmd) {
    if (InSim(kID)) {
        llRegionSayTo(kID,getPersonalChannel(kID), (string)kID + ":" + sCmd);
    } else {
        llOwnerSay(NameURI(kID)+" is not in this region.");
        //PickSubMenu(sCmd);
    }
}

SendAllCmd(string sCmd) {
    integer i;
    for (; i < llGetListLength(g_lSubs); i++) {
        key kID = (key)llList2String(g_lSubs, i);
        if (kID != g_kOwner && InSim(kID)) //Don't expose out-of-sim subs
            SendCmd(kID, sCmd);
    }
}

AddSub(key kID) {
    if (~llListFindList(g_lSubs,[kID])) return;
    if (kID != NULL_KEY) {//don't register any unrecognised
        g_lSubs+=[kID];//Well we got here so lets add them to the list.
        llOwnerSay("\n\n"+NameURI(kID)+" has been registered.\n");//Tell the owner we made it.
    }
}

RemoveSub(key kID) {
    integer index = llListFindList(g_lSubs,[kID]);
    if (~index) {
        g_lSubs=llDeleteSubList(g_lSubs,index,index);
        if (InSim(kID)) {
            SendCmd(kID, "rm owner "+(string)g_kOwner); // 4.0 command
            SendCmd(kID, "rm trust "+(string)g_kOwner); // 4.0 command
        }
        llOwnerSay(NameURI(kID)+" has been removed from your Owner HUD.");
    }
}

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, string sMenuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET,DIALOG,(string)kRCPT+"|"+sPrompt+"|"+(string)iPage+"|"+llDumpList2String(lChoices,"`")+"|"+llDumpList2String(lUtilityButtons,"`"),kID);
    g_kMenuID = kID;
    g_sMenuType = sMenuType;
}

MainMenu(){
    string sPrompt = "\n\n[http://www.opencollar.at/ownerhud OpenCollar Remote 4.0]\t\t\tBuild: "+g_sVersion;
    if (g_iUpdateAvailable) sPrompt += "\n\nThere is an update available @ [http://maps.secondlife.com/secondlife/Boulevard/50/211/23 The Temple]";
    list lButtons = g_lMainMenuButtons + g_lMenus;
    Dialog(g_kOwner, sPrompt, lButtons, [], 0, g_sMainMenu);
}

ManageMenu() {
    string sPrompt = "\nClick \"Add\" to register collars!\n\nwww.opencollar.at/ownerhud";
    list lButtons = [g_sScanSubs,g_sListSubs,g_sRemoveSub,g_sLoadCard,g_sPrintSubs];
    Dialog(g_kOwner, sPrompt, lButtons, [UPMENU], 0, "ManageMenu");
}

RezzerMenu() {
    Dialog(g_kOwner, "\nChoose an Object to rez and force sit a sub on", BuildObjectList(),["BACK"],0,"RezzerMenu");
}

PickSubMenu(string sCmd) { // Multi-page menu
    string sPrompt = "\nWhich sub shall receive the \""+sCmd+"\" command?\nOnly subs in this sim are shown.\n";
    list lButtons;
    integer i;
    for (; i < llGetListLength(g_lSubs); i++) {
        if (InSim(llList2Key(g_lSubs,i))) //only show subs you can give commands to
            lButtons += [llList2String(g_lSubs, i)];
    }
    if (!llGetListLength(lButtons)) lButtons = ["-"];
    Dialog(g_kOwner, sPrompt, lButtons, [g_sAllSubs,UPMENU], -1,"PickSubMenu");
}

RemoveSubMenu() {
    Dialog(g_kOwner, "\nWho would you like to remove?\n\nNOTE: This will also remove you as their owner if the sub is in the same sim.", g_lSubs, [UPMENU], -1,"RemoveSubMenu");
}

/*QuickLeashMenu() {
    string sPrompt = "\n\nwww.opencollar.at/ownerhud\n\nLeash Quickmenu";
    list lButtons = ["Grab","Follow","STOP","Stay","Unstay"];
    Dialog(g_kOwner, sPrompt, lButtons, [], 0,"QuickLeash");
}*/

ConfirmSubRemove(key kID) {
    string sPrompt = "\nAre you sure you want to remove "+NameURI(kID)+"?\n\nNOTE: This will also remove you as their owner.";
    Dialog(g_kOwner, sPrompt, ["Yes", "No"], [UPMENU], 0,"RemoveSubMenu");
}

//NG lets send pings here and listen for pong replys
/*SendPingRequest(key kID) {
    if (llGetListLength(g_lListeners) >= 60)
        return;  // lets not cause "too many listen" error
    integer iChannel = getPersonalChannel(kID);
    g_lListeners += [ llListen(iChannel, "", "", "" )] ;
    llRegionSayTo(kID, iChannel, (string)kID+ ":ping");
    llSetTimerEvent(2.0);
}*/

PickSubCmd(string sCmd) {
    integer iLength = llGetListLength(g_lSubs);
    if (!iLength) {
        llOwnerSay("\n\nAdd someone first! I'm not currently managing anyone.\n\nwww.opencollar.at/ownerhud\n");
        return;
    }
    list lNearbySubs;
    integer i;
    while (i < iLength) {
        key kTemp = llList2Key(g_lSubs,i);
        if (InSim(kTemp))
            lNearbySubs += kTemp;
        i++;
    }
    iLength = llGetListLength(lNearbySubs);
    if (iLength > 1) {
        g_sPendingCmd = sCmd;
        PickSubMenu(sCmd);
    } else if (iLength == 1) {
        SendCmd(llList2Key(lNearbySubs,0), sCmd);
    } else
        llOwnerSay("\n\nNone of your managed subs is nearby.\n");
    lNearbySubs = [];
}

AddSubMenu() {
    string sPrompt = "\nChoose who you want to manage with your Owner HUD:";
    list lButtons;
    integer index;
    integer iSpaceIndex;
    string sName;
    do {
        lButtons += llList2Key(g_lNewSubIDs,index);
    } while (++index < llGetListLength(g_lNewSubIDs));
    Dialog(g_kOwner, sPrompt, lButtons, ["ALL",UPMENU], -1,"AddSubMenu");
}

RezMenu() {
    string sPrompt = "\nLet's rez something fun and capture someone! Yay!\n\nChoose one of the found RLV Relay activated people:";
//    list lButtons;
//    string sName;
//    integer index;
//    integer i;
//    do lButtons += llList2Key(g_lCageVictims,i);
//    while (i++ < llGetListLength(g_lCageVictims));
    Dialog(g_kOwner, sPrompt, g_lCageVictims, [UPMENU], -1,"RezMenu");
}

StartUpdate() {
    integer pin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(g_kUpdater, g_iUpdateChan, "ready|" + (string)pin );
}

list BuildObjectList() {
    list lRezObjects;
    integer i;
    do lRezObjects += llGetInventoryName(INVENTORY_OBJECT,i);
    while (++i < llGetInventoryNumber(INVENTORY_OBJECT));
    return lRezObjects;
}

default {
    state_entry() {
        g_kOwner = llGetOwner();
        g_kWebLookup = llHTTPRequest(version_check_url, [HTTP_METHOD, "GET"],"");
        llSleep(1.0);//giving time for others to reset before populating menu
        if (llGetInventoryKey(g_sCard)) {
            g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
            g_kCardID = llGetInventoryKey(g_sCard);
        }
        g_iListener=llListen(getPersonalChannel(g_kOwner),"",NULL_KEY,""); //lets listen here
        SetCmdListener();

        llMessageLinked(LINK_SET,MENUNAME_REQUEST, g_sMainMenu,"");
        //Debug("started.");
    }
    on_rez(integer iStart) {
        g_kWebLookup = llHTTPRequest(version_check_url, [HTTP_METHOD, "GET"],"");
    }
    
    touch_start(integer iNum) {
        key kID = llDetectedKey(0);
        if ((llGetAttached() == 0)&& (kID==g_kOwner)) {// Dont do anything if not attached to the HUD
            llMessageLinked(LINK_THIS, CMD_UPDATE, "Update", kID);
            return;
        }
        if (kID == g_kOwner) {
//          I made the root prim the "menu" prim, and the button action default to "menu."
            string sButton = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            if (sButton == "Bookmarks") PickSubCmd("bookmarks");
            else if (sButton == "Menu") MainMenu();
            else if (sButton == "Yank") PickSubCmd("yank");
            else if (sButton == "Couples") PickSubCmd("couples");
            else if (sButton == "Leash") PickSubCmd("leash"); //QuickLeashMenu();
            else if (llSubStringIndex(sButton,"remote")>=0)
                llMessageLinked(LINK_SET, CMD_TOUCH,"hide","");
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChannel) {
            list lParams = llParseString2List(sMessage, [" "], []);
            string sCmd = llList2String(lParams,0);
            if (sMessage == "menu")
                MainMenu();
            else if (sCmd == "channel") {
                integer iNewChannel = (integer)llList2String(lParams,1);
                if (iNewChannel) {
                    g_iChannel = iNewChannel;
                    SetCmdListener();
                    llOwnerSay("Your new HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
                } else llOwnerSay("Your HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
            }
            else if (llToLower(sMessage) == "help")
                llOwnerSay("\n\n\t[http://www.opencollar.at/ownerhud.html Owner HUD Manual]\n");
            else if (sMessage == "reset") llResetScript();
        } else if (iChannel == getPersonalChannel(g_kOwner) && llGetOwnerKey(kID) == g_kOwner) {
            if (sMessage == "-.. --- / .... ..- -..") {
                g_kUpdater = kID;
                Dialog(g_kOwner, "\nINSTALLATION REQUEST PENDING:\n\nAn update is requesting permission to continue. Installation progress can be observed above the installer box and it will also tell you when it's done.\n\nShall we continue and start with the installation?", ["Yes","No"], ["Cancel"], 0, "UpdateConfirmMenu");
            }
        } else if (llGetSubString(sMessage, 36, 40)==":pong") {
            if (!~llListFindList(g_lNewSubIDs, [llGetOwnerKey(kID)]) && !~llListFindList(g_lSubs, [llGetOwnerKey(kID)]))
                g_lNewSubIDs += [llGetOwnerKey(kID)];
        } else if (iChannel == g_iRLVRelayChannel && llGetSubString(sMessage,0,6) == "locator") {
            if (!~llListFindList(g_lCageVictims, [llGetOwnerKey(kID)])) //prevents double names of avis with more than 1 relay active
                g_lCageVictims += [llGetOwnerKey(kID)];
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams,0) == g_sMainMenu) {
                string sChild = llList2String(lParams,1);
                if (! ~llListFindList(g_lMenus, [sChild]))
                    g_lMenus = llListSort(g_lMenus+=[sChild], 1, TRUE);
            }
            lParams = [];
        } //else if (iNum == SEND_CMD_SUB) SendCmd(kID, sStr);
        //else if (iNum == SEND_CMD_ALL_SUBS) SendAllCmd(sStr);
        else if (iNum == SUBMENU && sStr == "Main") MainMenu();
        else if (iNum == DIALOG_RESPONSE && kID == g_kMenuID) {
            list    lParams = llParseString2List(sStr, ["|"], []);
            string  sMessage    = llList2String(lParams, 1);
            integer i;
            if (g_sMenuType == "ManageMenu") {
                if (sMessage == UPMENU) {
                    MainMenu();
                    return;
                } else if (sMessage == g_sListSubs) { //Lets List out subs
                    //list lTemp;
                    string sText ="\nI'm currently managing:\n";
                    integer iSubCount = llGetListLength(g_lSubs);
                    if (iSubCount) {
                        i=0;
                        do {
                            if (llStringLength(sText)>950) {
                                llOwnerSay(sText);
                                sText ="";
                            }
                            sText += NameURI(llList2Key(g_lSubs,i))+", " ;
                        } while (++i < iSubCount-1);
                        if (iSubCount>1)sText += " and "+NameURI(llList2Key(g_lSubs,i));
                        if (iSubCount == 1) sText = llGetSubString(sText,0,-3);
                    } else sText += "nobody";
                    llOwnerSay(sText);
                    ManageMenu(); //return to ManageMenu
                } else if (sMessage == g_sRemoveSub) RemoveSubMenu();
                else if (sMessage == g_sLoadCard) {
                    if (llGetInventoryType(g_sCard) != INVENTORY_NOTECARD) {
                        llOwnerSay("\n\nThe" + g_sCard +" card couldn't be found in my inventory.\n");
                        return;
                    }
                    g_iLineNr = 0;
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    ManageMenu();
                } else if (sMessage == g_sScanSubs) {
                     // Ping for auth OpenCollars in the parcel
                     list lAgents = llGetAgentList(AGENT_LIST_PARCEL, []); //scan for who is in the parcel
                     llOwnerSay("Scanning for collars where you have access to.");
                     integer iChannel;
                     for (i=0; i < llGetListLength(lAgents); ++i) {//build a list of who to scan
                        kID = llList2Key(lAgents,i);
                        if (kID != g_kOwner) {
                            if (llGetListLength(g_lListeners) < 60) { // lets not cause "too many listen" error
                                iChannel = getPersonalChannel(kID);
                                g_lListeners += [llListen(iChannel, "", "", "" )] ;
                                llRegionSayTo(kID, iChannel, (string)kID+":ping");
                            }
                        }
                    }
                    llSetTimerEvent(2.0);
                } else if (sMessage == g_sPrintSubs) {
                    if (llGetListLength(g_lSubs)) {
                        string sPrompt = "\n#copy and paste this into your Subs notecard.\n# You need to add the Key of each person you wish to add to the hud.\n";
                        sPrompt+= "# The subid is their Key which can be obtained from their profile";
                        sPrompt+= "\n# Empty lines and lines beginning with '#' are ignored";
                        llOwnerSay(sPrompt);
                        sPrompt = "\n";
                        for (i=0; i < llGetListLength(g_lSubs); i++) {
                            sPrompt+= "\nsubid = " + llList2String(g_lSubs, i);
                        }
                        llOwnerSay(sPrompt);
                    } else llOwnerSay("Nothing to print here, you need to add subs to the HUD first.");
                    ManageMenu();
                }
            } else if (g_sMenuType == "RemoveSubMenu") {
                integer index = llListFindList(g_lSubs, [(key)sMessage]);
                if (sMessage == UPMENU) ManageMenu();
                else if (sMessage == "Yes") {
                    RemoveSub(g_kRemovedSubID);
                    ManageMenu();
                } else if (sMessage == "No") ManageMenu();
                else if (~index) {
                    g_kRemovedSubID = (key)llList2String(g_lSubs, index);
                    ConfirmSubRemove(g_kRemovedSubID);
                }
            } else if (g_sMenuType == "PickSubMenu") {
                integer index = llListFindList(g_lSubs, [(key)sMessage]);
                if (sMessage == UPMENU) MainMenu();
                else if (sMessage == g_sAllSubs) SendAllCmd(g_sPendingCmd);
                else if (~index) SendCmd(llList2Key(g_lSubs, index), g_sPendingCmd);
            } else if (g_sMenuType == "Main") {
                if (sMessage == "MANAGE") ManageMenu();
                else if (sMessage == "Collar") PickSubCmd("menu");
                else if (sMessage == "Rezzers") RezzerMenu();
                else if (sMessage == "HUD Style") llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
                else if (sMessage == "Sit" || sMessage == "Stand") PickSubCmd(llToLower(sMessage)+"now");
                else if (sMessage == "Leash") PickSubCmd("leashmenu");
                else if (~llListFindList(g_lMenus,[sMessage])) llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
                else PickSubCmd(llToLower(sMessage));
            } else if (g_sMenuType == "UpdateConfirmMenu") {
                if (sMessage=="Yes") StartUpdate();
                else {
                    llOwnerSay("Installation cancelled.");
                    return;
                }
            }/* else if (g_sMenuType == "QuickLeash") {
                if (sMessage == "STOP") PickSubCmd("unleash");
                else if (sMessage == "Follow") PickSubCmd("follow me");
                else PickSubCmd(llToLower(sMessage));
            }*/ else if (g_sMenuType == "RezzerMenu") {
                    if (sMessage == UPMENU) MainMenu();
                    else { 
                        g_sRezObject = sMessage;
                        llOwnerSay("Scanning for possible \"victims\" within "+(string)g_iScanRange+"m with RLV-Relay to capture on your "+g_sRezObject);
                        llSensor("","",AGENT,g_iScanRange,PI);
                    }
                } else if (g_sMenuType == "RezMenu") {
                if (sMessage == UPMENU) {
                    MainMenu();
                    g_lCageVictims = [];
                    return;
                } else {
                    g_kVictimID = (key)sMessage;
                    if (llGetInventoryType(g_sRezObject) == INVENTORY_OBJECT)
                        llRezObject(g_sRezObject,llGetPos() + <3, 3, 1>, ZERO_VECTOR, llGetRot(), 0);
                    else llOwnerSay("You do not have an Object in your HUD's inventory, unable to perform action.");
                    g_lCageVictims = [];
                }
            } else if (g_sMenuType == "AddSubMenu") {
                if (sMessage == "ALL") {
                    i=0;
                    key kNewSubID;
                    do {
                        kNewSubID = llList2Key(g_lNewSubIDs,i);
                        if (kNewSubID) AddSub(kNewSubID);
                    } while (i++ < llGetListLength(g_lNewSubIDs));
                } else if ((key)sMessage)
                    AddSub(sMessage);
                g_lNewSubIDs = [];
                ManageMenu();
            }
        }
    }

    sensor(integer iNumber) {
        g_lCageVictims = [];
        g_lListeners += [llListen(g_iRLVRelayChannel,"","","")];
        integer i;
        do {
            llRegionSayTo(llDetectedKey(i),g_iRLVRelayChannel,"locator,"+(string)llDetectedKey(i)+",!version");
        } while (++i < iNumber);
        llSetTimerEvent(2.0);
    }
    no_sensor(){
        llOwnerSay("nobody found");
    }

//  clear things after ping
    timer() {
        //Debug ("timer expired" + (string)llGetListLength(g_lCageVictims));
        if (llGetListLength(g_lCageVictims)) RezMenu();
        else if (llGetListLength(g_lNewSubIDs)) AddSubMenu();
        else llOwnerSay("No one is not found");
        llSetTimerEvent(0);
        integer n = llGetListLength(g_lListeners);
        while (n--)
            llListenRemove(llList2Integer(g_lListeners,n));
        g_lListeners = [];
    }

    dataserver(key kRequestID, string sData) {
        if (kRequestID == g_kLineID) {
            if (sData == EOF) { //  notify the owner
                llOwnerSay(g_sCard+" card loaded.");
                return;
            } else if (sData != "") {//  if we are not working with a blank line
                if (llSubStringIndex(sData, "#")) {//  if the line does not begin with a comment
                    integer index = llSubStringIndex(sData, "=");//  find first equal sign
                    if (~index) {//  if line contains equal sign
                        string sName = llToLower(llStringTrim(llGetSubString(sData, 0, index - 1),STRING_TRIM));
                        string sValue = llStringTrim(llGetSubString(sData, index + 1, -1),STRING_TRIM);
                        if (sName == "subid") AddSub((key)sValue);
                    }
                }
            }
            g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);//  read the next line
        }
    }
    
    http_response(key kRequestID, integer iStatus, list lMeta, string sBody) {
        if (kRequestID == g_kWebLookup && iStatus == 200)  {
            if ((float)sBody > (float)g_sVersion) g_iUpdateAvailable = TRUE;
            else g_iUpdateAvailable = FALSE;
        }
    }
    
    object_rez(key kID) {
        llSleep(0.5); // make sure object is rezzed and listens
        llRegionSayTo(kID,g_iCageChannel,"fetch"+(string)g_kVictimID);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(g_sCard) != g_kCardID) {
                // the .subs card changed.  Re-read it.
                g_iLineNr = 0;
                if (llGetInventoryKey(g_sCard)) {
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    g_kCardID = llGetInventoryKey(g_sCard);
                }
            }
        }
        if (iChange & CHANGED_OWNER) llResetScript();
    }
}
