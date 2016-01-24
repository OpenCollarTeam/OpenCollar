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
//       AO Interface - 160124.1         .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Wendy Starfall, littlemousy, Garvin Twine, Romka Swallowtail et al.     //
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
//           github.com/OpenCollar/opencollar/tree/master/src/ao            //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

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
//integer COLLAR_INT_REQ = 610;
//integer COLLAR_INT_REP = 611;
integer g_iCollarIntegration;
key g_kWearer;
string g_sSeparator = "|";
integer g_iCounter;
key g_kCollarID;
string g_sPendingCmd;

integer g_iUpdateChannel = -7483220;

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
/*
integer GetOwnerChannel(key kOwner, integer iOffset) {
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan > 0) iChan=iChan*(-1);
    if (iChan > -10000) iChan -= 30000;
    return iChan;
}
*/
init() {
//we dont know what was changed in the collar so lets starts fresh with our cache
    g_kCollarID = NULL_KEY;
    g_iCollarIntegration = FALSE; // -- 3.381 to avoid double message on login
    llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar?");
    g_iCounter = 0;
    llSetTimerEvent(30.0);
}

StartUpdate(key kID) {
    integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(kID, -7483220, "ready|" + (string)pin );
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
        g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
        g_iObjectchannel = -llAbs((integer)("0x"+llGetSubString((string)llGetOwner(),-7,-1)));
        init();
    }
    
    on_rez(integer start) {
        if( g_kWearer != llGetOwner()) llResetScript();
        init();
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //debug("LinkMsg: " + str);
     /*   if (iNum == COLLAR_INT_REQ)  {
            if (g_kCollarID != NULL_KEY) {
                if (sStr == "CollarOn")
                    g_iCollarIntegration = TRUE;
                else if (sStr == "CollarOff")
                    g_iCollarIntegration = FALSE;
            } else if (sStr == "CollarOff")
                    g_iCollarIntegration = FALSE;
            //send back if we know the g_kCollarID (means if != NULL_KEY we are able to interact fully
            llMessageLinked(LINK_THIS, COLLAR_INT_REP, sStr, g_kCollarID);
        } else */
        if (iNum == CMD_TO_COLLAR) {
            llRegionSayTo(g_kWearer,g_iObjectchannel, sStr);
        } else if (iNum == CMD_ZERO) {
            if (g_iCollarIntegration) {
                llRegionSayTo(g_kWearer,g_iInterfaceChannel,"AuthRequest|"+(string)kID);
                g_sPendingCmd =  sStr;
            } else 
                llMessageLinked(LINK_THIS, CMD_OWNER, sStr, kID);
        } else if (iNum == CMD_AUTH && sStr == "ZHAO_RESET") {
            llSleep(2); // -- Don't reset immediately, ensure the Interface is ready for us
            llResetScript();
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage) {
        //debug("Listen: " + sMessage);        
        if (sMessage == "OpenCollar=No" && kID == g_kCollarID) { //Collar said it got detached
            g_iCollarIntegration = FALSE;
            g_kCollarID = NULL_KEY;
            //llListenRemove(g_iListenHandle);
            //g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
           // llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
            return;
        }        
        //do nothing if wearer isnt owner of the object
        if (llGetOwnerKey(kID) != g_kWearer) return;
        //Collar announces itself
        if (sMessage == "OpenCollar=Yes") {
            g_iCollarIntegration = TRUE;
            g_kCollarID = kID;
           // llListenRemove(g_iListenHandle);
           // g_iListenHandle = llListen(g_iInterfaceChannel, "", g_kCollarID, "");
            //llMessageLinked(LINK_THIS, COLLAR_INT, sMessage, "");
           // llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOn", "");
            return;
        } else if (llUnescapeURL(sMessage) == "SAFEWORD") {
            llMessageLinked(LINK_THIS, CMD_COLLAR, "safeword", "");
            //llSay(0,llUnescapeURL(sMessage));
            return;
        } else if (sMessage == "-.. --- / .- ---") {
            StartUpdate(kID);
            return;
        }
        //CollarCommand|iAuth|Command|UUID
        //AuthReply|UUID|iAuth
        list lParams = llParseString2List(sMessage,["|"],[]);
        string sMessageType = llList2String(lParams,0);
        integer iAuth;
        debug(sMessageType);
        if (sMessageType == "AuthReply") {
            iAuth = llList2Integer(lParams,2);
            if (g_sPendingCmd) {
                llMessageLinked(LINK_THIS, iAuth, g_sPendingCmd, llList2Key(lParams,1));
                g_sPendingCmd = "";
            }
        } else if (sMessageType == "CollarCommand") {
            iAuth = llList2Integer(lParams,1);
            if (iAuth)
                llMessageLinked(LINK_THIS, iAuth, llList2String(lParams,2), llList2Key(lParams,3));
        }
        debug(sMessage);
/*        //check if we get a auth request at all here
        index = llSubStringIndex(sMessage, g_sSeparator);
        iAuth = llList2Integer(lTemp,0);
        llOwnerSay(sMessage);
        if (iAuth)  {//auth has to be an integer > 0 else it cannot be a collar message
            sMessage = llList2String(lTemp,1);
            llMessageLinked(LINK_THIS,iAuth,sMessage,llList2Key(lTemp,2);
            index = llSubStringIndex(sMessage, g_sSeparator);
            string sCommand = llGetSubString(sMessage, 0, index - 1);
            //Collar tells me owners have changed reset my g_lAuthList
            if (iAuth == CMD_COLLAR) {
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
        }*/
    }
    
    timer() {
        if (g_kCollarID != NULL_KEY) {
            if (llKey2Name(g_kCollarID) == "") { //the collar is somehow gone...
            //check 2 times again if the collar is really gone, then switch to CollarRequest mode
                if (g_iCounter <= 2) {
                    g_iCounter++;
                    llSetTimerEvent(10.0);
                } else if (g_iCollarIntegration) {
                    g_iCollarIntegration = FALSE;
                    llSetTimerEvent(20.0);
                //    g_kCollarID = NULL_KEY;
                 //   llListenRemove(g_iListenHandle);
                  //  g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
                    g_iCounter = 0;
                    llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar?");
                   // llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
                }
            }
        } else { // Else, we need to ensure the rest of the hud knows the collar is missing and needs to be refound.
            if (g_iCollarIntegration) {// -- The collar is gone but we think it's still here
                g_iCollarIntegration = FALSE;
                llSetTimerEvent(20.0);
                g_kCollarID = NULL_KEY;
                // llListenRemove(g_iListenHandle);
                //  g_iListenHandle = llListen(g_iInterfaceChannel, "", "", "");
                llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar?");
                // llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
            } else  // -- We need to continue to ask if the collar is there
                llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar?");
        }
    }
}
