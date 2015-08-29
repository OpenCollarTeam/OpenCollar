////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                        OpenCollarUpdater - BundleGiver                         //
//                                 version 3.928                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// this script receives DO_BUNDLE messages that contain the uuid of the collar being updated, 
// the name of a bundle notecard, the talkchannel on which the collar shim script is listening, and
// the script pin set by the shim.  This script then loops over the items listed in the notecard
// and chats with the shim about each one.  Items that are already present (as determined by uuid) 
// are skipped.  Items not present are given to the collar.  Items that are present but don't have the
// right uuid are deleted and replaced with the version in the updater.  Scripts are loaded with 
// llRemoteLoadScriptPin, and are set running immediately.

// once the end of the notecard is reached, this script sends a BUNDLE_DONE message that includes all the same 
// stuff it got in DO_BUNDLE (talkchannel, recipient, card, pin).

integer DO_BUNDLE = 98749;
integer BUNDLE_DONE = 98750;

integer g_iTalkChannel;
key g_kRCPT;
string g_sCard;
integer g_iPin;
string g_sMode;

integer g_iLine;
key g_kLineID;
integer g_iListener;

SetStatus(string sName) {
    // use card name, item type, and item name to set a nice 
    // text status message
    list lCardParts = llParseString2List(g_sCard, ["_"], []);
    string sBundle = llList2String(lCardParts, 2);
    string sMsg = llDumpList2String([
        "Doing Bundle: " + sBundle,
        "Doing Item: " + sName
    ], "\n");
    llSetText(sMsg, <1,1,1>, 1.0);
}

debug(string sMsg) {
   // llOwnerSay(llGetScriptName() + ": " + sMsg);
}

default
{   
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == DO_BUNDLE) {
            debug("doing bundle: " + sStr);
            // str will be in form talkchannel|uuid|bundle_card_name
            list lParts = llParseString2List(sStr, ["|"], []);
            g_iTalkChannel = (integer)llList2String(lParts, 0);
            g_kRCPT = (key)llList2String(lParts, 1);
            g_sCard = llList2String(lParts, 2);
            g_iPin = (integer)llList2String(lParts, 3);
            g_sMode = llList2String(lParts, 4); // either INSTALL or REMOVE
            g_iLine = 0;
            llListenRemove(g_iListener);
            g_iListener = llListen(g_iTalkChannel, "", g_kRCPT, "");
            if (~llSubStringIndex(g_sCard,"_DEPRECATED"))
                llSay(g_iTalkChannel,"Core5Done");
            // get the first line of the card
            g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
        }
    }
    
    dataserver(key kID, string sData) {
        if (kID == g_kLineID) {
            if (sData != EOF) {
                // process bundle line
                list lParts = llParseString2List(sData, ["|"], []);
                string sType = llList2String(lParts, 0);
                string sName = llList2String(lParts, 1);
                key kUUID;
                string sMsg;
                
                SetStatus(sName);
                
                kUUID = llGetInventoryKey(sName);
                sMsg = llDumpList2String([sType, sName, kUUID, g_sMode], "|");
                debug("querying: " + sMsg);             
                llRegionSayTo(g_kRCPT, g_iTalkChannel, sMsg);
            } else {
                debug("finished bundle: " + g_sCard);
                // all done reading the card. send link msg to main script saying we're done.
                llListenRemove(g_iListener);
                llSetText("", <1,1,1>, 1.0);
                llMessageLinked(LINK_SET, BUNDLE_DONE, llDumpList2String([g_iTalkChannel, g_kRCPT, g_sCard, g_iPin, g_sMode], "|"), "");
            }
        }
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg) {
        debug("heard: " + sMsg);
        // let's live on the edge and assume that we only ever listen with a uuid filter so we know it's safe
        // look for msgs in the form <type>|<name>|<cmd>
        list lParts = llParseString2List(sMsg, ["|"], []);
        if (llGetListLength(lParts) == 3) {
            string sType = llList2String(lParts, 0);
            string sItemName = llList2String(lParts, 1);
            string sCmd = llList2String(lParts, 2);            
            if (sCmd == "SKIP" || sCmd == "OK") {
                // move on to the next item by reading the next notecard line
                g_iLine++;
                g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
            } else if (sCmd == "GIVE") {
                // give the item, and then read the next notecard line.
                if (sType == "ITEM") {
                    llGiveInventory(kID, sItemName);
                } else if (sType == "SCRIPT") {
                    integer iStart = TRUE;
                    if (llSubStringIndex(g_sCard,"Core5") != -1) iStart = FALSE;
                    // get the full name, and load it via script pin.
                    llRemoteLoadScriptPin(kID, sItemName, g_iPin, iStart, 1);
                }
                g_iLine++;
                g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
            }
        }
    }
    
    on_rez(integer iStart) {
        llResetScript();
    }
    
    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            llResetScript();
        }
    }
}
