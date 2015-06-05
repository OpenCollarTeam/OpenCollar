////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollarHUD - hudmain                             //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//merged HUD-menu, HUD-leash and HUD-rezzer into here June 2015 Otto (garvin.twine)

string g_sDialogUrl;

//  strided list in the form key,name
list g_lSubs = [];
list g_lNewSubIDs;

//  list of hud channel handles we are listening for, for building lists
list g_lListeners;

string g_sMainMenu   = "Main";   //  where we return to
string g_sManageMenu = "MANAGE";   //  which menu are we
key    g_kSubID      = NULL_KEY; //  clear the sub uuid
string g_sSubName;               //  what is the name of the sub
list   g_lAgents;                //  list of AV's to ping

//  Notecard reading bits

string  g_sCard = ".subs";
key     g_kLineID;
integer g_iLineNr;

integer g_iListener;
integer g_iCmdListener;
integer g_iChannel = 7;

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

integer SEND_CMD_PICK_SUB    = -1002;
integer SEND_CMD_ALL_SUBS    = -1003;
integer SEND_CMD_SUB         = -1005;
integer SEND_CMD_NEARBY_SUBS = -1006;

integer LOCALCMD_REQUEST     = -2000;
integer LOCALCMD_RESPONSE    = -2001;
integer DIALOG_URL           = -2002;

integer CMD_UPDATE    = 10001;

string UPMENU          = "BACK";

string g_sListSubs  = "List Subs";
string g_sRemoveSub    = "Remove";
//string list   = "Reload Menu";
string g_sScanSubs     = "Add";
string g_sLoadCard     = "Load";
string g_sPrintSubs    = "Print";
string g_sAllSubs      = " ALL";

list g_lMainMenuButtons = [g_sManageMenu,"Collar","Cage","Pose","RLV","Sit","Stand","Leash"];//,"HUD Style"];

string g_sWearerName;
key    g_kRemovedSubID;
key    g_kWearer;

//  three strided list of avkey, dialogid, and menuname
list    g_lMenuIDs;
integer g_iMenuStride = 3;

//  Use these to keep track of your current menu
//  Use any variable name you desire

string MAINMENU   = "SubMenu";
string PICKMENU   = "PickSub";
string REMOVEMENU = "RemoveSub";

float   g_fScanRange        = 25.0;
integer g_iRLVRelayChannel  = -1812221819;
integer g_iCageChannel      = -987654321;
list    g_lCageVictims;
key     g_kVictimID;


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

integer getPersonalChannel(key kOwner, integer iOffset) {
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (0 < iChan)
        iChan = iChan*(-1);
    if (iChan > -10000)
        iChan -= 30000;
    return iChan;
}

SetCmdListener() {
    llListenRemove(g_iCmdListener);
    g_iCmdListener = llListen(g_iChannel,"",g_kWearer,"");
}

integer InSim(key kID) {
//  check if the AV is logged in and in Sim
    return (llGetAgentSize(kID) != ZERO_VECTOR);
}

SendCmd(key kID, string sCmd) {
    if (InSim(kID)) {
        llRegionSayTo(kID,getPersonalChannel(kID,1111), (string)kID + ":" + sCmd);
    } else {
        g_sSubName = "secondlife:///app//agent/"+(string)kID+"/about"; //llList2String(g_lSubs, (llListFindList(g_lSubs, [(string)kID])) + 1);
        llOwnerSay("\n\nSorry!\n\nI can't find "+g_sSubName+" in this region.\n");
        PickSubMenu(g_kWearer, 0);
    }
}

SendNearbyCmd(string sCmd) {
   /* integer i;
    integer iStop = llGetListLength(g_lSubs);
    for (; i < iStop; i+=4) {
        key kID = (key)llList2String(g_lSubs, i);
        if (kID != g_kWearer && InSim(kID)) //Don't expose out-of-sim subs
            SendCmd(kID, sCmd);
    }*/
    SendAllCmd(sCmd);
}

SendAllCmd(string sCmd) { 
    integer i;
    integer iStop = llGetListLength(g_lSubs);
    for (; i < iStop; i+=2) {
        key kID = (key)llList2String(g_lSubs, i);
        if (kID != g_kWearer && InSim(kID)) //Don't expose out-of-sim subs
            SendCmd(kID, sCmd);
    }
}

AddSub(key kID, string sName) {
    if (~llListFindList(g_lSubs,[kID]))
        return;
    if ( llStringLength(sName) >= 24)
        sName=llStringTrim(llGetSubString(sName, 0, 23),STRING_TRIM);//only store first 24 char$ of subs name
    if (sName!="" && kID!="") {//don't register any unrecognised names
        g_lSubs+=[kID,sName];//Well we got here so lets add them to the list.
        llOwnerSay("\n\nsecondlife:///app/agent/"+(string)kID+"/about has been registered as "+sName+".\n");//Tell the owner we made it.
    }
}

RemoveSub(key kSub) {
    integer index = llListFindList(g_lSubs,[kSub]);
    if (~index) {
        g_lSubs=llDeleteSubList(g_lSubs,index, index+3);
        SendCmd(kSub, "remowners "+g_sWearerName);
        SendCmd(kSub, "remsecowner "+g_sWearerName);
    }
}


key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET,DIALOG,(string)kRCPT+"|"+sPrompt+"|"+(string)iPage+"|"+llDumpList2String(lChoices,"`")+"|"+llDumpList2String(lUtilityButtons,"`"),kID);
    return kID;
}

SubMenu(key kID) {// Single page menu
    string sPrompt = "\nClick \"Add\" to register collars!\n\nwww.opencollar.at/ownerhud";
    list lButtons = [g_sScanSubs,g_sListSubs,g_sRemoveSub,g_sLoadCard,g_sPrintSubs];
    if (llStringLength(sPrompt) > 511) {// Check text length so we can warn for it being too long before hand.
         llOwnerSay("**** Too many Collars registered, not all names may appear. ****");
         sPrompt = llGetSubString(sPrompt,0,510);
     }
    key kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0);
    // UUID , Menu ID, Menu
    list lNewStride = [kID, kMenuID, "SubMenu"];
    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(g_lMenuIDs, [kID]);
//  this person is already in the dialog list.  replace their entry
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

PickSubMenu(key kID, integer iPage) { // Multi-page menu
    string sPrompt = "\nWho will receive this command?";
    list lButtons = [g_sAllSubs];
    integer i;
    for (; i < llGetListLength(g_lSubs); i+= 2)
        lButtons += [llList2String(g_lSubs, i + 1)];
    
    key kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
    // UUID , Menu ID, Menu
    list lNewStride = [kID, kMenuID, PICKMENU];
    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(g_lMenuIDs, [kID]);
//  this person is already in the dialog list.  replace their entry
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

RemoveSubMenu(key kID, integer iPage) // Multi-page menu
{
    string sPrompt = "\nWho would you like to remove?\n\nNOTE: This will also remove you as their owner.";
    list lButtons;
    integer i;
    for (; i < llGetListLength(g_lSubs); i+= 2)
        lButtons += [llList2String(g_lSubs, i + 1)];
    key kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
    list lNewStride = [kID, kMenuID, REMOVEMENU];
    integer index = llListFindList(g_lMenuIDs, [kID]);
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

MainMenu(key kID){
    string sPrompt = "\n\nwww.opencollar.at/ownerhud";
    list lButtons = g_lMainMenuButtons;[g_sManageMenu,"Collar","Cage","Pose","RLV","Sit","Stand","Leash","HUD Style"];
    key kMenuID = Dialog(kID, sPrompt, lButtons, [], 0);
    list lNewStride = [kID, kMenuID, g_sMainMenu];
    integer index = llListFindList(g_lMenuIDs, [kID]);
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

QuickLeashMenu(key kID) {
    string sPrompt = "\n\nwww.opencollar.at/ownerhud\n\nLeash Quickmenu";
    list lButtons = ["Grab","Follow","STOP","Stay","Unstay"];
    key kMenuID = Dialog(kID, sPrompt, lButtons, [], 0);
    list lNewStride = [kID, kMenuID, "QuickLeash"];
    integer index = llListFindList(g_lMenuIDs, [kID]);
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

ConfirmSubRemove(key kID) { 
    string sPrompt = "\nAre you sure you want to remove " + g_sSubName + "?\n\nNOTE: This will also remove you as their owner.";
    key kMenuID = Dialog(kID, sPrompt, ["Yes", "No"], [UPMENU], 0);
    list lNewStride = [kID, kMenuID, REMOVEMENU];
    integer index = llListFindList(g_lMenuIDs, [kID]);
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

//NG lets send pings here and listen for pong replys
SendCommand(key kID) {
    if (llGetListLength(g_lListeners) >= 60)
        return;  // lets not cause "too many listen" error
    integer iChannel = getPersonalChannel(kID, 1111);
    g_lListeners += [ llListen(iChannel, "", "", "" )] ;
    llRegionSayTo(kID, iChannel, (string)kID+ ":ping");
    llSetTimerEvent(2.0);
}

PickSubCmd(string sCmd) {
    integer iLength = llGetListLength(g_lSubs);
    if (iLength > 6) {
        g_sPendingCmd = sCmd;
        PickSubMenu(g_kWearer,0);
    } else if (iLength == 4) {
        key kSubID = (key)llList2String(g_lSubs, 0);
        SendCmd(kSubID, sCmd);
    } else
        llOwnerSay("\n\nAdd someone first! I'm not currently managing anyone.\n\nwww.opencollar.at/ownerhud\n");
}

AddSubMenu() {
    string sPrompt = "\nChoose who you want to manage with your Owner HUD:";
    list lButtons;
    integer index;
    integer iSpaceIndex;
    string sName;
    do {
        sName = llKey2Name(llList2Key(g_lNewSubIDs,index));
        iSpaceIndex = llSubStringIndex(sName," ");
        if (llGetSubString(sName,iSpaceIndex+1,-1) == "Resident")
            sName = llGetSubString(sName,0,iSpaceIndex-1);
        lButtons += [sName];
    } while (index++ < llGetListLength(g_lNewSubIDs));
    key kMenuID = Dialog(g_kWearer, sPrompt, lButtons, ["ALL",UPMENU], 0);
    list lNewStride = [g_kWearer, kMenuID, "AddSubMenu"];
    index = llListFindList(g_lMenuIDs, [g_kWearer]);
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;    
}

CageMenu() {
    string sPrompt = "\nLet's drop a cage on someone! Yay!\n\nChoose one of the found RLV Relay activated people:";
    list lButtons;
    string sName;
    integer index;
    integer i;
    do {
        sName = llList2String(g_lCageVictims,i);
        index = llSubStringIndex(sName," ");
        if (llGetSubString(sName,index+1,-1) == "Resident")
            sName = llGetSubString(sName,0,index-1);
        lButtons += [sName];
        i+=2;
    } while (i < llGetListLength(g_lCageVictims));
    key kMenuID = Dialog(g_kWearer, sPrompt, lButtons, [UPMENU], 0);
    list lNewStride = [g_kWearer, kMenuID, "CageMenu"];
    index = llListFindList(g_lMenuIDs, [g_kWearer]);
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

default
{
    state_entry() {
        g_kWearer = llGetOwner();  //Who are we
        g_sWearerName = llKey2Name(g_kWearer);  
        g_iListener=llListen(getPersonalChannel(g_kWearer,1111),"",NULL_KEY,""); //lets listen here
        SetCmdListener();
        llSleep(1.0);//giving time for others to reset before populating menu
        llMessageLinked(LINK_SET,MENUNAME_REQUEST, g_sMainMenu,"");
        //Debug("started.");
    }

    on_rez(integer iStart) {
        llSleep(2.0);
        //llOwnerSay("Type these commands on channel 7:\n\t/7help for a HUD Guide\n\t/7update for an update Guide\n\t/7owner for an owners menu Setup Guide");
    }
    
    touch_start(integer iNum)
    {
        key kID = llDetectedKey(0);
        if ((llGetAttached() == 0)&& (kID==g_kWearer)) {// Dont do anything if not attached to the HUD
            llMessageLinked(LINK_THIS, CMD_UPDATE, "Update", kID);
            return;
        }
        if (kID == g_kWearer) {
//          I made the root prim the "menu" prim, and the button action default to "menu."
            string sButton = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            if (sButton == "Bookmarks")
                PickSubCmd("bookmarks");
            else if (sButton == "Menu")
                MainMenu(kID);
            else if (sButton == "Beckon")
                PickSubCmd("beckon");
            else if (sButton == "Couples")
                PickSubCmd("couples");
            else if (sButton == "Leash")
                QuickLeashMenu(kID);
            else if (llSubStringIndex(sButton,"Owner")>=0) 
                llMessageLinked(LINK_SET, CMD_TOUCH,"hide","");
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChannel) {
            list lParams = llParseString2List(sMessage, [" "], []);
            string sCmd = llList2String(lParams,0);
            if (sMessage == "menu")
                MainMenu(kID);
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
        } else if (llGetSubString(sMessage, 36, 40)==":pong") {
            if (! ~llListFindList(g_lNewSubIDs, [llGetOwnerKey(kID)]) && ! ~llListFindList(g_lSubs, [llGetOwnerKey(kID)]))
                g_lNewSubIDs += [llGetOwnerKey(kID)];
        } else if (iChannel == g_iRLVRelayChannel && llGetSubString(sMessage,0,6) == "locator")
            g_lCageVictims += [llKey2Name(llGetOwnerKey(kID)), llGetOwnerKey(kID)];
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
    
        if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams,0) == g_sMainMenu)
                g_lMainMenuButtons += llList2List(lParams,1,1);
        } else if (iNum == SEND_CMD_SUB)
            SendCmd(kID, sStr);
        else if (iNum == SEND_CMD_ALL_SUBS)
            SendAllCmd(sStr);
        else if (iNum == SEND_CMD_NEARBY_SUBS)
            SendNearbyCmd(sStr);
        else if (iNum == SUBMENU && sStr == "Main")
            MainMenu(kID);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
          //  if (~iMenuIndex) {
//              got a menu response meant for us.  pull out values
            list    lParams = llParseString2List(sStr, ["|"], []);
                    kID         = (key)llList2String(lParams, 0);
            string  sMessage    = llList2String(lParams, 1);
            integer iPage       = (integer)llList2String(lParams, 2);
            string  sMenuType   = llList2String(g_lMenuIDs, iMenuIndex + 1);
            integer i;
//              remove stride from menuids
//              we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            if (sMenuType == MAINMENU) {
                if (sMessage == UPMENU) {
                    MainMenu(kID);
                    return;
                } else if (sMessage == g_sListSubs) { //Lets List out subs
                    //list lTemp;
                    string sText ="\nI'm currently managing:\n";
                    for (i=0; i < llGetListLength(g_lSubs); i += 2) {
                        if (llStringLength(sText)>950) {
                            llOwnerSay(sText);
                            sText ="";
                        }
                        sText += "secondlife:///app/agent/"+llList2String(g_lSubs,i)+"/about as \""+llList2String(g_lSubs,i+1)+"\"\n";
                    }
                    llOwnerSay(sText);
                    SubMenu(kID); //return to SubMenu
                } else if (sMessage == g_sRemoveSub) 
                    RemoveSubMenu(kID,iPage);
                else if (sMessage == g_sLoadCard) {
                    if (llGetInventoryType(g_sCard) != INVENTORY_NOTECARD) {
                        llOwnerSay("\n\nThe" + g_sCard +" card couldn't be found in my inventory.\n");
                        return;
                    }
                    g_iLineNr = 0;
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    SubMenu(kID); 
                } else if (sMessage == g_sScanSubs) {
                     // Ping for auth OpenCollars in the parcel
                     g_lAgents = llGetAgentList(AGENT_LIST_PARCEL, []); //scan for who is in the parcel
                     llOwnerSay("Scanning for collars where you have access to.");
                     for (i=0; i < llGetListLength(g_lAgents); i++) {//build a list of who to scan
                        // Lets not ping oursevles
                        // when ping reply listeners are added, then removed, our personal channel is removed
                        if (llList2Key(g_lAgents,i) != g_kWearer)
                            SendCommand(llList2Key(g_lAgents, i)); //kick off "sendCommand" for each uuid
                     }
                     //SubMenu(kID); 
                } else if (sMessage == g_sPrintSubs) {
                    string sPrompt = "\n#copy and paste this into your Subs notecard.\n# You need to add the name and Key of each person you wish to add to the hud.\n";
                    sPrompt+= "# The subname can be shortened to a name you like\n# The subid is their Key which can be obtained from their profile";
                    sPrompt+= "\n# This only adds the names to your hud, it does not mean you have access to their collar\n# Empty lines and lines beginning with '#' are ignored";
                    llOwnerSay(sPrompt);
                    sPrompt = "\n";
                    list lTemp;
                    for (i=0; i < llGetListLength(g_lSubs); i += 2) {
                        lTemp = llList2List(g_lSubs, i + 1, i + 1);
                        sPrompt+="\nsubname =  " + llDumpList2String(lTemp,"");
                        lTemp = llList2List(g_lSubs, i, i);
                        sPrompt+= "\nsubid = " + llDumpList2String(lTemp,"");
                    }
                    llOwnerSay(sPrompt);
                }
            } else if (sMenuType == REMOVEMENU) {
                integer index = llListFindList(g_lSubs, [sMessage]);
                if (sMessage == UPMENU)
                    SubMenu(g_kWearer);
                else if (sMessage == "Yes")
                    RemoveSub(g_kRemovedSubID);
                else if (sMessage == "No")
                    return;
                else if (~index) {
                    g_kRemovedSubID = (key)llList2String(g_lSubs, index - 1);
                    g_sSubName = llList2String(g_lSubs, index);
                    ConfirmSubRemove(kID);
                }
            } else if (sMenuType == PICKMENU) {
                integer index = llListFindList(g_lSubs, [sMessage]);
                if (sMessage == UPMENU)
                    SubMenu(g_kWearer);
                else if (sMessage == g_sAllSubs)
                    SendAllCmd(g_sPendingCmd);
                else if (~index) {
                    g_sSubName = sMessage;
                    key sub = (key)llList2String(g_lSubs, index - 1);
                    SendCmd(sub, g_sPendingCmd);
                }
            } else if (sMenuType == "Main") {
                if (sMessage == g_sManageMenu)
                    SubMenu(kID);
                else if (sMessage == "Collar") 
                    PickSubCmd("menu");
                else if (sMessage == "Cage") {
                    llOwnerSay("Scanning for possible cagees within "+(string)llRound(g_fScanRange)+"m with RLV-Relay...");
                    llSensor("","",AGENT,g_fScanRange,PI);
                } else if (sMessage == "HUD Style")
                    llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
                else if (sMessage == "Sit" || sMessage == "Stand")
                    PickSubCmd(llToLower(sMessage)+"now");
                else if (sMessage == "Leash")
                    PickSubCmd("leashmenu");
                else
                    PickSubCmd(llToLower(sMessage));
            } else if (sMenuType == "QuickLeash") {
                if (sMessage == "STOP") {
                    PickSubCmd("unleash");
                } else if (sMessage == "Follow")
                    PickSubCmd("follow me");
                else 
                    PickSubCmd(llToLower(sMessage));
            } else if (sMenuType == "CageMenu") {
                if (sMessage == UPMENU) {
                    MainMenu(kID);
                    g_lCageVictims = [];
                    return;
                } else if (! ~llSubStringIndex(sMessage, " ")) sMessage += " Resident";
                g_kVictimID = llList2Key(g_lCageVictims,llListFindList(g_lCageVictims,[sMessage])+1);
                if (llGetInventoryType("Cage") == INVENTORY_OBJECT)
                    llRezObject("Cage",llGetPos() + <3, 3, 1>, ZERO_VECTOR, llGetRot(), 0);
                else
                    llOwnerSay("You do not have a Cage in your HUD's inventory, unable to perform caging.");
                g_lCageVictims = [];
            } else if (sMenuType == "AddSubMenu") {
                if (sMessage == UPMENU) {
                    SubMenu(kID);
                    g_lNewSubIDs = [];
                    return;
                } else if (sMessage == "ALL") {
                    i=0;
                    key kNewSubID;
                    do {
                        kNewSubID = llList2Key(g_lNewSubIDs,i);
                        if (kNewSubID) 
                            AddSub(kNewSubID,llKey2Name(kNewSubID));
                    } while (i++ < llGetListLength(g_lNewSubIDs));
                    g_lNewSubIDs = [];
                    SubMenu(kID);
                } else {
                    i=0;
                    key kNewSubID;
                    if (! ~llSubStringIndex(sMessage, " ")) sMessage += " Resident";
                    do {
                        kNewSubID = llList2Key(g_lNewSubIDs,i);
                        if (llKey2Name(kNewSubID) == sMessage) {
                            AddSub(kNewSubID,llKey2Name(kNewSubID));
                            g_lNewSubIDs = [];
                            SubMenu(kID);
                            return;
                        }
                    } while (i++ < llGetListLength(g_lNewSubIDs));
                    g_lNewSubIDs = [];
                    SubMenu(kID);
                }
            }    
        }
        else if (iNum == DIALOG_URL)
            g_sDialogUrl = sStr;
    }

    sensor(integer iNumber)
    {
        g_lCageVictims = [];
        g_lListeners += [llListen(g_iRLVRelayChannel,"","","")];
        integer i;
        do {
            llRegionSayTo(llDetectedKey(i),g_iRLVRelayChannel,"locator,"+(string)llDetectedKey(i)+",!version");
        } while (i++ < iNumber);
        llSetTimerEvent(2.0);
    }
    no_sensor(){
        llOwnerSay("nobody found");
    }
            
//  clear things after ping
    timer() {
        //Debug ("timer expired" + (string)llGetListLength(g_lCageVictims));
        if (llGetListLength(g_lCageVictims)) {
            CageMenu();
        }
        if (llGetListLength(g_lNewSubIDs)) AddSubMenu();
        llSetTimerEvent(0);
        g_lAgents = [];
        integer n = llGetListLength(g_lListeners) - 1;
        for (; n >= 0; n--)
            llListenRemove(llList2Integer(g_lListeners,n));
        g_lListeners = [];
    }

    dataserver(key kRequestID, string sData) {
        if (kRequestID == g_kLineID) {
            if (sData == EOF) { //  notify the owner
                llOwnerSay(g_sCard+" card loaded.");
                return;
            } else if (sData != "") {//  if we are not working with a blank line
                if (llSubStringIndex(sData, "#") != 0) {//  if the line does not begin with a comment
                    integer index = llSubStringIndex(sData, "=");//  find first equal sign
                    if (~index) {//  if line contains equal sign
                        string sName = llToLower(llStringTrim(llGetSubString(sData, 0, index - 1),STRING_TRIM));
                        string sValue = llStringTrim(llGetSubString(sData, index + 1, -1),STRING_TRIM);
                        if (sName == "subname") g_sSubName = sValue;
                        else if (sName == "subid") g_kSubID = sValue;
                    } 
                }
                if (g_sSubName!="" && g_kSubID!="")
                    AddSub(g_kSubID,g_sSubName);
                }
            g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);//  read the next line
        }
    }
    object_rez(key kID) {
        llSleep(0.5); // make sure object is rezzed and listens
        llRegionSayTo(kID,g_iCageChannel,"fetch"+(string)g_kVictimID);
    }
    
    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            //llOwnerSay("\n\nReloading the "+g_sCard+" card\n!");
            g_iLineNr = 0;
            g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
        }
        if (iChange & CHANGED_OWNER)
            llResetScript();
    }
}