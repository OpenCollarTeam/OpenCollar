// This file is part of OpenCollar.
// Copyright (c) 2011 - 2017 Nandana Singh, Wendy Starfall, Garvin Twine  
// and Romka Swallowtail  
// Licensed under the GPLv2.  See LICENSE for full details. 


// this script receives DO_BUNDLE messages that contain the uuid of the collar
// being updated, the name of a bundle notecard, the talkchannel on which the
// collar shim script is listening, and the script pin set by the shim.  This
// script then loops over the items listed in the notecard and chats with the
// shim about each one.  Items that are already present (as determined by uuid)
// are skipped.  Items not present are given to the collar.  Items that are
// present but don't have the right uuid are deleted and replaced with the
// version in the updater.  Scripts are loaded with llRemoteLoadScriptPin, and
// are set running immediately.

// once the end of the notecard is reached, this script sends a BUNDLE_DONE
// message that includes all the same stuff it got in DO_BUNDLE (talkchannel,
// recipient, card, pin).

integer DO_BUNDLE = 98749;
integer BUNDLE_DONE = 98750;
integer INSTALLATION_DONE = 98751;

integer g_iTalkChannel;
key g_kRCPT;
string g_sCard;
integer g_iPin;
string g_sMode;

integer g_iLine;
key g_kLineID;
integer g_iListener;

float g_iItemCounter;
float g_iTotalItems;


StatusBar(float fCount) {
    fCount = 100*(fCount/g_iTotalItems);
    if (fCount > 100) fCount = 100;
    string sCount = ((string)((integer)fCount))+"%";
    if (fCount < 10) sCount = "░░"+sCount;
    else if (fCount < 45) sCount = "░"+sCount;
    else if (fCount < 100) sCount = "█"+sCount;
    string sStatusBar = "░░░░░░░░░░░░░░░░░░░░";
    integer i = (integer)(fCount/5);
    do { i--;
        sStatusBar = "█"+llGetSubString(sStatusBar,0,-2);
    } while (i>0);
    llSetLinkPrimitiveParamsFast(2,[PRIM_TEXT,llGetSubString(sStatusBar,0,7)+sCount+llGetSubString(sStatusBar,12,-1), <1,1,0>, 1.0]);
    //return llGetSubString(sStatusBar,0,7)+sCount+llGetSubString(sStatusBar,12,-1);
}

SetStatus() {
    // use card name, item type, and item name to set a nice
    // text status message
    g_iItemCounter++;
    string sMsg = "Installation in progress...\n \n \n";
    llSetText(sMsg, <1,1,1>, 1.0);
    if (g_iTotalItems < 2) StatusBar(0.5);
    else StatusBar(g_iItemCounter);
    //if (g_iItemCounter == g_iTotalItems) g_iTotalItems= 0;
}


list g_lChannels;
list g_lListeners;
list g_lItems;
list g_lTypes;
default
{
    state_entry() {
        llSetLinkPrimitiveParamsFast(2,[PRIM_TEXT,"", <1,1,1>, 1.0]);
        g_iTotalItems = llGetInventoryNumber(INVENTORY_ALL) - llGetInventoryNumber(INVENTORY_NOTECARD) - 3;
    }
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == DO_BUNDLE) {
            // str will be in form talkchannel|uuid|bundle_card_name
            list lParts = llParseString2List(sStr, ["|"], []);
            g_iTalkChannel = (integer)llList2String(lParts, 0);
            g_kRCPT = (key)llList2String(lParts, 1);
            g_sCard = llList2String(lParts, 2);
            g_iPin = (integer)llList2String(lParts, 3);
            g_sMode = llList2String(lParts, 4); // either REQUIRED or DEPRECATED
            g_iLine = 0;
            llListenRemove(g_iListener);
            g_iListener = llListen(g_iTalkChannel, "", g_kRCPT, "");
            if (~llSubStringIndex(g_sCard,"_DEPRECATED"))
                llSay(g_iTalkChannel,"Core5Done");
            // get the first line of the card
            g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
        }
        if (iNum == INSTALLATION_DONE) llResetScript();
    }

    dataserver(key kID, string sData) {
        if (kID == g_kLineID) {
            if (sData != EOF) {
                // process bundle line
                sData = llStringTrim(sData, STRING_TRIM);
                if (sData == "") { //skip blank line
                    g_iLine++ ;
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
                }
                else {
                    list lParts = llParseString2List(sData, ["|"], []);
                    string sType = llStringTrim(llList2String(lParts, 0), STRING_TRIM);
                    string sName = llStringTrim(llList2String(lParts, 1), STRING_TRIM);
                    key kUUID;
                    string sMsg;
                    SetStatus();
                    kUUID = llGetInventoryKey(sName);
                    sMsg = llDumpList2String([sType, sName, kUUID, g_sMode], "|");
                    llRegionSayTo(g_kRCPT, g_iTalkChannel, sMsg);
                }
            } else {
                // all done reading the card. send link msg to main script saying we're done.

                llListenRemove(g_iListener);

                llMessageLinked(LINK_SET, BUNDLE_DONE, llDumpList2String([g_iTalkChannel, g_kRCPT, g_sCard, g_iPin, g_sMode], "|"), "");
            }
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg) {
        integer iIndexChannels = llListFindList(g_lChannels, [iChannel]);
        if(iIndexChannels != -1){
            // -> //
            integer iLstn = llList2Integer(g_lListeners,iIndexChannels);
            string sItem = llList2String(g_lItems, iIndexChannels);
            string sType = llList2String(g_lTypes, iIndexChannels);
            g_lChannels = llDeleteSubList(g_lChannels, iIndexChannels, iIndexChannels);
            g_lListeners = llDeleteSubList(g_lListeners, iIndexChannels, iIndexChannels);
            g_lItems = llDeleteSubList(g_lItems, iIndexChannels, iIndexChannels);
            g_lTypes = llDeleteSubList(g_lTypes, iIndexChannels, iIndexChannels);
            
            llListenRemove(iLstn);
            if(sMsg == "Skip"){
                g_iLine++;
                g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
            } else if(sMsg == "Install"){
                if (sType == "ITEM") {
                    llGiveInventory(g_kRCPT, sItem);
                } else if (sType == "SCRIPT") {
                    llRemoteLoadScriptPin(g_kRCPT, sItem, g_iPin, TRUE, 1);
                } else if (sType == "STOPPEDSCRIPT") {
                    llRemoteLoadScriptPin(g_kRCPT, sItem, g_iPin, FALSE, 1);
                }
                g_iLine++;
                g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
            } else if(sMsg == "Remove"){
                llRegionSayTo(g_kRCPT, g_iTalkChannel, sType+"|"+sItem+"|"+(string)NULL_KEY+"|DEPRECATED");
            }
            
            return;
        }
            
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
                    llRemoteLoadScriptPin(kID, sItemName, g_iPin, TRUE, 1);
                } else if (sType == "STOPPEDSCRIPT") {
                    llRemoteLoadScriptPin(kID, sItemName, g_iPin, FALSE, 1);
                }
                g_iLine++;
                g_kLineID = llGetNotecardLine(g_sCard, g_iLine);
            } else if(sCmd == "PROMPT_INSTALL"){
                //Do prompt
                g_lChannels += [llRound(llFrand(5437845))];
                g_lListeners += [llListen(llList2Integer(g_lChannels, -1), "", llGetOwner(), "")];
                g_lItems += [sItemName];
                g_lTypes += [sType];
                
                
                llDialog(llGetOwner(), "[OpenCollar Installer]\nCurrent Item: "+sItemName+"\n\n* Install\t\t- This optional item is not installed. If you wish to install, select this item\n* Skip\t\t- Skip and do not install this optional item", ["Install", "Skip"], llList2Integer(g_lChannels, -1));
            } else if(sCmd == "PROMPT_REMOVE"){
                
                g_lChannels += [llRound(llFrand(5437845))];
                g_lListeners += [llListen(llList2Integer(g_lChannels, -1), "", llGetOwner(), "")];
                g_lItems += [sItemName];
                g_lTypes += [sType];
                
                
                llDialog(llGetOwner(), "[OpenCollar Installer]\nCurrent Item: "+sItemName+"\n\n* Remove\t\t- This optional item is currently installed. If you wish to uninstall, select this option\n* Skip\t\t- Skip and do not change this optional item", ["Remove", "Skip"], llList2Integer(g_lChannels, -1));
            }
        }
    }

    on_rez(integer iStart) {
        llResetScript();
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) llResetScript();
    }
}
