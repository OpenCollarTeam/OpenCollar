////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                          OpenCollarAttch - Interface                           //
//                                 version 3.900                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

integer g_iInterfaceChannel = -12587429;
integer g_iObjectchannel = -1812221819;//only send on this channel, not listen
integer g_iListenHandle;
integer CMD_ZERO = 0;
integer CMD_AUTH = 42;
integer CMD_TO_COLLAR = 498; // -- Added to send commands TO the collar.
integer CMD_COLLAR = 499;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer COLLAR_INT_REQ = 610;
integer COLLAR_INT_REP = 611;
integer g_iCollarIntegration;
key g_kWearer;
key g_kObjectID;
string g_sSeparator = "|";
list g_lAuthList; //strided list [uuid, auth]
integer g_iCounter;
key g_kCollarID;
string g_sMessageType; // how the collar sends a Message" "RequestReply", "CollarCommand"

debug(string sMessage)
{
    //llOwnerSay(llGetScriptName() + " DEBUG: " + sMessage);
}

//===============================================================================
//= parameters   :    key owner            key of the person to send the message to
//=                   integer nOffset      Offset to make sure we use really a unique channel
//=
//= description  : Function which calculates a unique channel number based on the owner key, to reduce lag
//=
//= returns      : Channel number to be used
//===============================================================================
integer GetOwnerChannel(key kOwner, integer iOffset) {
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan > 0) iChan=iChan*(-1);
    if (iChan > -10000) iChan -= 30000;
    return iChan;
}

init() {
    g_kObjectID = llGetKey();
    g_iObjectchannel = GetOwnerChannel(g_kWearer,1111);
    //listen first to the full interfaceChannel and start to ping every 10 secs for a collar
    llListenRemove(g_iListenHandle);
    g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
    //we dont know what was changed in the collar so lets starts fresh with our cache
    g_lAuthList = [];
    g_kCollarID = NULL_KEY;
    g_iCollarIntegration = FALSE; // -- 3.381 to avoid double message on login
    llWhisper(g_iInterfaceChannel, "OpenCollar?");
    g_iCounter = 0;
    llSetTimerEvent(30.0);
}

default
{
    changed(integer iChange) {
        if(iChange & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
    
    state_entry() {
        g_kWearer = llGetOwner();
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
        init();
    }
    
    on_rez(integer start) {
        if( g_kWearer != llGetOwner()) llResetScript();
        init();
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //debug("LinkMsg: " + str);
        if (iNum == COLLAR_INT_REQ)  {
            if (g_kCollarID != NULL_KEY) {
                if (sStr == "CollarOn") {
                    g_iCollarIntegration = TRUE;
                    g_lAuthList = [];
                } else if (sStr == "CollarOff") {
                    g_iCollarIntegration = FALSE;
                    g_lAuthList = [];
                }
            } else if (g_kCollarID == NULL_KEY) {
                if (sStr == "CollarOff") {
                    g_iCollarIntegration = FALSE;
                    g_lAuthList = [];
                }
            }
            //send back if we know the g_kCollarID (means if != NULL_KEY we are able to interact fully
            llMessageLinked(LINK_THIS, COLLAR_INT_REP, sStr, g_kCollarID);
        } else if (iNum == CMD_TO_COLLAR) {
            llRegionSayTo(g_kWearer,g_iObjectchannel, sStr);
        } else if (iNum == CMD_ZERO) {
            if (g_iCollarIntegration) {
                integer index = llListFindList(g_lAuthList, [(string)kID]);
                if ( index == -1) {
                    llRegionSayTo(g_kWearer,g_iInterfaceChannel, "0|" + sStr + g_sSeparator + (string)kID + g_sSeparator + (string)g_kObjectID);
                } else {
                    string auth = llList2String(g_lAuthList, index + 1);
                    llMessageLinked(LINK_THIS, (integer)auth, sStr, kID);
                }
            } else {
                llMessageLinked(LINK_THIS, CMD_OWNER, sStr, kID);
            }
        } else if (iNum == CMD_AUTH && sStr == "ZHAO_RESET") {
            llSleep(2); // -- Don't reset immediately, ensure the Interface is ready for us
            llResetScript();
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage) {
        //debug("Listen: " + sMessage);
        //do nothing if wearer isnt owner of the object
        if (llGetOwnerKey(kID) != g_kWearer) return;
        //Collar announces itself
        if (sMessage == "OpenCollar=Yes") {
            g_kCollarID = kID;
            llListenRemove(g_iListenHandle);
            g_iListenHandle = llListen(g_iInterfaceChannel, "", g_kCollarID, "");
            //llMessageLinked(LINK_THIS, COLLAR_INT, sMessage, "");
            llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOn", "");
            return;
        } else if (sMessage == "OpenCollar=No") { //Collar said it got detached
            g_kCollarID = NULL_KEY;
            g_lAuthList = [];
            llListenRemove(g_iListenHandle);
            g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
            llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
            return;
        }
        //g_sMessageType + SEPARATOR + (string)num + SEPARATOR + msg + SEPARATOR + (string)id SEPARATOR + g_kObjectID
        integer index = llSubStringIndex(sMessage, g_sSeparator);
        g_sMessageType = llGetSubString(sMessage, 0, index - 1);
        debug(g_sMessageType);
        if (g_sMessageType == "RequestReply") {
            key checkID = (key)llGetSubString(sMessage, llStringLength(sMessage) - 36, -1);
            debug("IDcheck= " + (string)checkID);
            if (checkID != g_kObjectID) {//if this isnt my id then the message was not for me
                return;
            }
            //cut off my own id, no more needed
            sMessage = llGetSubString(sMessage, 0, llStringLength(sMessage) - 38);
        }
        //cut off the message type
        sMessage = llGetSubString(sMessage, index + 1, -1);
        debug(sMessage);
        //check if we get a auth request at all here
        index = llSubStringIndex(sMessage, g_sSeparator);
        integer iAuth = (integer)llGetSubString(sMessage, 0, index - 1);
        if (iAuth)  {//auth has to be an integer > 0 else it cannot be a collar message
            sMessage = llGetSubString(sMessage, index + 1, -1);
            index = llSubStringIndex(sMessage, g_sSeparator);
            string sCommand = llGetSubString(sMessage, 0, index - 1);
            //Collar tells me owners have changed reset my g_lAuthList
            if (iAuth == CMD_COLLAR) {
                if (sCommand == "OwnerChange")
                    g_lAuthList = [];
                else if (sCommand == "safeword")
                    llMessageLinked(LINK_THIS, iAuth, sMessage, "");
                else
                    llMessageLinked(LINK_THIS, iAuth, sMessage, "");
            } else {
                list parts = llParseStringKeepNulls(sMessage, ["|"], []);
                key kUUID = "";
                if (llGetListLength(parts) > 1) {
                    sCommand = llDumpList2String(llListReplaceList(parts, [], -1, -1), "|");
                    kUUID = (key)llList2String(parts, -1);
                }
                g_lAuthList += [kUUID, (string)iAuth];
                llMessageLinked(LINK_THIS, iAuth, sCommand, kUUID);
            }
        }
    }
    
    timer() {
        if (g_kCollarID != NULL_KEY) {
            if (llKey2Name(g_kCollarID) == "") { //the collar is somehow gone...
            //check 2 times again if the collar is really gone, then switch to CollarRequest mode
                if (g_iCounter <= 2) {
                    g_iCounter++;
                    llSetTimerEvent(10.0);
                } else if (g_iCollarIntegration) {
                    llSetTimerEvent(20.0);
                    g_kCollarID = NULL_KEY;
                    llListenRemove(g_iListenHandle);
                    g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
                    g_iCounter = 0;
                    llWhisper(g_iInterfaceChannel, "OpenCollar?");
                    llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
                }
            }
        } else { // Else, we need to ensure the rest of the hud knows the collar is missing and needs to be refound.
            if (g_iCollarIntegration) {// -- The collar is gone but we think it's still here
                    llSetTimerEvent(20.0);
                    g_kCollarID = NULL_KEY;
                    llListenRemove(g_iListenHandle);
                    g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
                    llWhisper(g_iInterfaceChannel, "OpenCollar?");
                    llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
            } else  // -- We need to continue to ask if the collar is there
                llWhisper(g_iInterfaceChannel, "OpenCollar?");
        }
    }
}
