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

//  no gridwide TP, probably because of llRegionSayTo in SendCmd()
//  to enhance: check if command is a forced tp - then use llInstantMessage if sub is not in same SIM - but this is probably slow, laggy and error prone
//  and do not forget to check if avi is online, before sending out a gridwide tp...

string g_sDialogUrl;

//  strided list in the form key,name
list g_lSubs = [];

//  these will be told to the listener on LOCALCMD_REQUEST, so it knows not to pass them through the remote
string g_sLocalCmds = "reset,help";

//  list of hud channel handles we are listening for, for building lists
list g_lListeners;

string g_sParentMenu = "Main";   //  where we return to
string g_sSubMenu    = "   MANAGE";   //  which menu are we
key    g_kSubID      = NULL_KEY; //  clear the sub uuid
string g_sSubName;               //  what is the name of the sub
list   g_lAgents;                //  list of AV's to ping

//  Notecard reading bits

string  g_sCard = ".subs";
key     g_kLineID;
integer g_iLineNr;

integer g_iListener;

//  save cmd here while we give the sub menu to decide who to send it to
string g_sPendingCmd;

//  MESSAGE MAP
integer CMD_OWNER            = 500;
integer POPUP_HELP           = 1001;

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

string UPMENU          = "BACK";

string g_sListCollars  = "List";
string g_sRemoveSub    = "Remove";
//string list   = "Reload Menu";
string g_sScanSubs     = "Add";
string g_sLoadCard     = "Load";
string g_sPrintSubs    = "Print";
string g_sAllSubs      = " ALL";

string g_sWearerName;
key    g_kRemovedSubID;
key    g_kWearer;

//  three strided list of avkey, dialogid, and menuname
list g_lMenuIDs;
integer g_iMenuStride = 3;

//  Use these to keep track of your current menu
//  Use any variable name you desire

string MAINMENU   = "SubMenu";
string PICKMENU   = "PickSub";
string REMOVEMENU = "RemoveSub";

// Yay for Cleo and Jessenia – Personal Object Channel!
integer getPersonalChannel(key kOwner, integer iOffset) {
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (0 < iChan)
        iChan = iChan*(-1);
    if (iChan > -10000)
        iChan -= 30000;
    return iChan;
}

integer InSim(key kID) {
//  check if the AV is logged in and in Sim
    return (llGetAgentSize(kID) != ZERO_VECTOR);
}

SendCmd(key kID, string sCmd) {
    g_sSubName = llList2String(g_lSubs, (llListFindList(g_lSubs, [(string)kID])) + 1);
    if (InSim(kID)) {
        llRegionSayTo(kID,getPersonalChannel(kID,1111), (string)kID + ":" + sCmd);
    } else {
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
    for (; i < iStop; i+=4) {
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
    if (sName!="????")//don't register any unrecognised names
    {
        if (kID) {//Don't register any invalid ID's
            g_lSubs+=[kID,sName,"***","***"];//Well we got here so lets add them to the list.
            llOwnerSay("\n\n"+sName+" has been registered.\n");//Tell the owner we made it.
        }
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
    //add sub
    list lButtons = [g_sScanSubs,g_sListCollars,g_sRemoveSub,g_sLoadCard,g_sPrintSubs];
    
    if (llStringLength(sPrompt) > 511) {// Check text length so we can warn for it being too long before hand.
         llOwnerSay("**** Too many Collars registered, not all names may appear. ****");
         sPrompt = llGetSubString(sPrompt,0,510);
     }
    key kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0);
    // UUID , Menu ID, Menu
    list lNewStride = [kID, kMenuID, MAINMENU];
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
    //add subs
    integer i;
    for (; i < llGetListLength(g_lSubs); i+= 4)
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
    //add subs
    list lButtons;
    integer i;
    for (; i < llGetListLength(g_lSubs); i+= 4)
        lButtons += [llList2String(g_lSubs, i + 1)];
    
    key kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
    // UUID , Menu ID, Menu
    list lNewStride = [kID, kMenuID, REMOVEMENU];
    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(g_lMenuIDs, [kID]);
//  this person is already in the dialog list.  replace their entry
    if (~index)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lNewStride, index, index - 1 + g_iMenuStride);
    else
        g_lMenuIDs += lNewStride;
}

ConfirmSubRemove(key kID) { // Single page menu
    string sPrompt = "\nAre you sure you want to remove " + g_sSubName + "?\n\nNOTE: This will also remove you as their owner.";
    key kMenuID = Dialog(kID, sPrompt, ["Yes", "No"], [UPMENU], 0);
//  UUID , Menu ID, Menu
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
    llRegionSayTo(kID, iChannel, (string)kID+ ":ping");
    g_lListeners += [ llListen(iChannel, "", "", "" )] ;// if we have a reply on the channel lets see what it is.
    llSetTimerEvent(5);// no reply by now, lets kick off the timer
}
processConfiguration(string sData)
{
//  if we are at the end of the file
    if (sData == EOF)
    {
    //  notify the owner
        llOwnerSay(g_sCard+" card parsed");
        return;
    }
    if (sData != "") {//  if we are not working with a blank line
        if (llSubStringIndex(sData, "#") != 0) {//  if the line does not begin with a comment
            integer index = llSubStringIndex(sData, "=");//  find first equal sign
            if (~index) {//  if line contains equal sign
                string sName = llGetSubString(sData, 0, index - 1);//  get name of name/value pair
                string sValue = llGetSubString(sData, index + 1, -1);//  get value of name/value pair
                list lTemp = llParseString2List(sName, [" "], []);
                sName = llDumpList2String(lTemp, " ");//  trim name
                sName = llToLower(sName);//  make name lowercase (case insensitive)
                lTemp = llParseString2List(sValue, [" "], []);
                sValue = llDumpList2String(lTemp, " ");//  trim value
                if (sName == "subname")//  subname
                    g_sSubName = sValue;
                else if (sName == "subid")//  subid
                    g_kSubID = sValue;
                else//  unknown name
                    llOwnerSay("\n\nUnknown configuration value: " + sName + " on line " + (string)g_iLineNr);
            } else//  line does not contain equal sign
                llOwnerSay("\n\nConfiguration could not be read on line " + (string)g_iLineNr);
        }
    }
    if (g_sSubName=="")
        g_sSubName="????";
    if (g_kSubID=="")
        g_kSubID=NULL_KEY;
    AddSub(g_kSubID,g_sSubName);
    g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);//  read the next line
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();  //Who are we
        g_sWearerName = llKey2Name(g_kWearer);  //thats our real name
        g_iListener=llListen(getPersonalChannel(g_kWearer,1111),"",NULL_KEY,""); //lets listen here

        llSleep(1.0);//giving time for others to reset before populating menu
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        //llOwnerSay("Type /7help for a HUD Guide, /7update for a update Guild, or /7owner for an Owners menu Setup Guide");
    }

    changed(integer iChange) {
//      reload on notcard changes should happen automaticly
        if (iChange & CHANGED_INVENTORY) {
            //llOwnerSay("\n\nReloading the "+g_sCard+" card\n!");
            g_iLineNr = 0;
            g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
        }
        if (iChange & CHANGED_OWNER)
            llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        //authenticate messages on COMMAND_NOAUTH
        if (iNum == CMD_OWNER) {
            //only owner may do these things
            if (sStr == "help")
                llOwnerSay("\n\n\t[http://www.opencollar.at/ownerhud.html Owner HUD Manual]\n");
            else if (sStr =="reset"){
                g_lSubs = [];
                llResetScript();
            }
        }
//          give the Owner menu here.  should let the dialog do whatever the chat commands do
        else if (iNum == SUBMENU && sStr == g_sSubMenu)
            SubMenu(kID);
        else if (iNum == SEND_CMD_SUB)
            SendCmd(kID, sStr);
        else if (iNum == SEND_CMD_PICK_SUB) {
//          give a sub menu and send cmd to the sub picked
            integer length = llGetListLength(g_lSubs);
            if (length > 6) {
                g_sPendingCmd = sStr;
                PickSubMenu(g_kWearer,0);
            } else if (length == 4) {
                key sub = (key)llList2String(g_lSubs, 0);
                SendCmd(sub, sStr);
            } else {
//              you have 0 subs in list (empty)
                llMessageLinked(LINK_THIS, POPUP_HELP, "\n\nAdd someone first! I'm not currently managing anyone.\n\nwww.opencollar.at/ownerhud\n", g_kWearer);
            }
        }
        else if (iNum == SEND_CMD_ALL_SUBS)
            SendAllCmd(sStr);
        else if (iNum == SEND_CMD_NEARBY_SUBS)
            SendNearbyCmd(sStr);
        else if (iNum == LOCALCMD_REQUEST)
            llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, g_sLocalCmds, "");
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
//              got a menu response meant for us.  pull out values

                list    lParams = llParseString2List(sStr, ["|"], []);
                        kID         = (key)llList2String(lParams, 0);
                string  sMessage    = llList2String(lParams, 1);
                integer iPage       = (integer)llList2String(lParams, 2);
                string  sMenuType   = llList2String(g_lMenuIDs, iMenuIndex + 1);

//              remove stride from menuids
//              we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenuType == MAINMENU) {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_THIS, SUBMENU, g_sParentMenu, kID);
                        return;
                    } else if (sMessage == g_sListCollars) { //Lets List out subs
                        list lTemp;
                        integer i;
                        for (; i < llGetListLength(g_lSubs); i += 4)
                            lTemp += llList2List(g_lSubs, i + 1, i + 1);
                        llOwnerSay("\n\nI'm currently managing:\n\n" + llList2CSV(lTemp));
                        SubMenu(kID); //return to SubMenu
                    } else if (sMessage == g_sRemoveSub)  // Ok lets remove the sub from the Hud
                        RemoveSubMenu(kID,iPage);
                    else if (sMessage == g_sLoadCard) { // Ok lets load the subs from the notecard
                        if (llGetInventoryType(g_sCard) != INVENTORY_NOTECARD) {
                            //  notify owner of missing file
                            llOwnerSay("\n\nThe" + g_sCard +" card couldn't be found in my inventory.\n");
                            return;
                        }
                        g_iLineNr = 0;
                        g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                        SubMenu(kID); //return to SubMenu
                    } else if (sMessage == g_sScanSubs) {//lets add new subbies
                         // Ping for auth OpenCollars in the region
                         //llOwnerSay("Starting to scan for collars");
                         g_lAgents = llGetAgentList(AGENT_LIST_REGION, []); //scan for who is in the region.
                         integer i;
                         for (; i < llGetListLength(g_lAgents); i++) {//build a list of who to scan
                            // Lets not ping oursevles
                            // when ping reply listeners are added, then removed, our personal channel is removed
                            if (llList2Key(g_lAgents,i) != g_kWearer)
                                SendCommand(llList2Key(g_lAgents, i)); //kick off "sendCommand" for each uuid
                         }
                         SubMenu(kID); //return to SubMenu
                    } else if (sMessage == g_sPrintSubs) {//lets do a dump for adding to the Subs Notecard
                        string sPrompt = "\n#copy and paste this into your Subs notecard.\n# You need to add the name and Key of each person you wish to add to the hud.\n";
                        sPrompt+= "# The subname can be shortened to a name you like\n# The subid is their Key which can be obtained from their profile";
                        sPrompt+= "\n# This only adds the names to your hud, it does not mean you have access to their collar\n# Empty lines and lines beginning with '#' are ignored";
                        //lets pull the keys and names from the subs list
                        list lTemp;
                        integer i;
                        for (i = -1; i < llGetListLength(g_lSubs); i += 4) {
                            lTemp = llList2List(g_lSubs, i + 2, i + 2);
                            sPrompt+="\nsubname =  " + llDumpList2String(lTemp,"");
                            lTemp = llList2List(g_lSubs, i + 1, i + 1);
                            sPrompt+= "\nsubid = " + llDumpList2String(lTemp,"");
                        }
                        llOwnerSay(sPrompt);
                    }
                } else if (sMenuType == REMOVEMENU) {// OK we want to remove a sub from the Hud
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
                }
            }
        }
        else if (iNum == DIALOG_URL)
            g_sDialogUrl = sStr;
    }

//  Now we have recieved something back from a ping lets break it down and see if it's for us.
    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (llGetSubString(sMessage, 36, 40)==":pong") {
            key    kSubID   = llGetOwnerKey(kID);
            string sSubName = llKey2Name(kSubID);
            if (sSubName == "")
                sSubName="????";
            //llOwnerSay(subName+" has been detected.");
            AddSub(kSubID,sSubName);
        }
    }

    on_rez(integer iStart) {
        llSleep(2.0);
        //llOwnerSay("Type these commands on channel 7:\n\t/7help for a HUD Guide\n\t/7update for an update Guide\n\t/7owner for an owners menu Setup Guide");
    }

//  clear things after ping
    timer() {
        llSetTimerEvent(0);
        g_lAgents = [];
        integer n = llGetListLength(g_lListeners) - 1;
        for (; n >= 0; n--)
            llListenRemove(llList2Integer(g_lListeners,n));
        g_lListeners = [];
    }

    dataserver(key kRequestID, string sData) {
        if (kRequestID == g_kLineID)
            processConfiguration(sData);
    }
}