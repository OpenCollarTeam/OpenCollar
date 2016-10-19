/*
    _____________________________.
   |;;|                      |;;||     Copyright (c) 2016:
   |[]|----------------------|[]||
   |;;|      AO  Loader      |;;||     Garvin Twine
   |;;|       161019.1       |;;||
   |;;|----------------------|;;||
   |;;|   www.opencollar.at  |;;||
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

github.com/VirtualDisgrace/opencollar/blob/master/src/spares/.aoloader.lsl

*/

string g_sPreInstalledAnimations;
key g_kOwner;
key g_kAOID;
integer g_iListener;
list g_lSettingCards;
string g_sSettingCard;
integer g_iLine;
key g_kCardRequestID;
string g_sObjectName;
integer g_iTimeOut;

Say(string sStr) {
    llSetObjectName(llGetScriptName());
    llOwnerSay(sStr);
    llSetObjectName(g_sObjectName);
}

Menu(){
    string sPrompt = "\nPlease choose which set to install into your OpenCollar AO:";
    g_lSettingCards = [];
    list lButtons;
    integer iEnd = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer i;
    string sName;
    while (i < iEnd) {
        sName = llGetInventoryName(INVENTORY_NOTECARD,i++);
        if (!llSubStringIndex(sName,"SET")) {
            if (~llSubStringIndex(sName,"125") && !~llListFindList(lButtons,["125cm"])) {
                lButtons += "125cm";
                g_lSettingCards += ["125cm",sName];
            } else if (~llSubStringIndex(sName,"155") && !~llListFindList(lButtons,["155cm"])) {
                lButtons += "155cm";
                g_lSettingCards += ["155cm",sName];
            } else if (~llSubStringIndex(sName,"185") && !~llListFindList(lButtons,["185cm"])) {
                lButtons += "185cm";
                g_lSettingCards += ["185cm",sName];
            } else if (~llSubStringIndex(sName,"215") && !~llListFindList(lButtons,["215cm"])) {
                lButtons += "215cm";
                g_lSettingCards += ["215cm",sName];
            }
        }
    }
    i = (integer)llFrand(9999999.0) + 1234567;
    g_iListener = llListen(i,"","","");
    g_iTimeOut = TRUE;
    list lCancel;
    if (llGetListLength(lButtons) % 3 != 0) lCancel = ["Cancel"];
    llSetTimerEvent(90);
    llDialog(g_kOwner,sPrompt,SortButtons(lButtons,lCancel),i);
}

list SortButtons(list lButtons, list lStaticButtons) {
    list lSpacers;
    list lAllButtons = lButtons + lStaticButtons;
    while (llGetListLength(lAllButtons)>12) {
        lButtons = llDeleteSubList(lButtons,0,0);
        lAllButtons = lButtons + lStaticButtons;
    }
    while (llGetListLength(lAllButtons) % 3 != 0 && llGetListLength(lAllButtons) < 12) {
        lSpacers += "-";
        lAllButtons = lButtons + lSpacers + lStaticButtons;
    }
    integer i = llListFindList(lAllButtons, ["BACK"]);
    if (~i) lAllButtons = llDeleteSubList(lAllButtons, i, i);
    list lOut = llList2List(lAllButtons, 9, 11);
    lOut += llList2List(lAllButtons, 6, 8);
    lOut += llList2List(lAllButtons, 3, 5);
    lOut += llList2List(lAllButtons, 0, 2);
    if (~i) lOut = llListInsertList(lOut, ["BACK"], 2);
    return lOut;
}

Particles(key kTarget) {
    llParticleSystem([ 
        PSYS_PART_FLAGS, 
            PSYS_PART_INTERP_COLOR_MASK |
            PSYS_PART_INTERP_SCALE_MASK |
            PSYS_PART_TARGET_POS_MASK |
            PSYS_PART_EMISSIVE_MASK,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_EXPLODE,
        PSYS_SRC_TEXTURE, "930c3304-e899-9266-2ab5-ab9ec3aec2b6",
        PSYS_SRC_TARGET_KEY, kTarget,
        PSYS_PART_START_COLOR, <0.529, 0.416, 0.212>,
        PSYS_PART_END_COLOR, <0.733, 0.592, 0.345>,
        PSYS_PART_START_SCALE, <0.68, 0.64, 0>,
        PSYS_PART_END_SCALE, <0.04, 0.04, 0>,
        PSYS_PART_START_ALPHA, 0.1,
        PSYS_PART_END_ALPHA, 1,
        PSYS_SRC_BURST_PART_COUNT, 4,
        PSYS_PART_MAX_AGE, 2,
        PSYS_SRC_BURST_SPEED_MIN, 0.2,
        PSYS_SRC_BURST_SPEED_MAX, 1
    ]);
}

RemoveMe() {
    llRemoveInventory(llGetScriptName());
}

default {
    state_entry() {
        llParticleSystem([]);
        g_kOwner = llGetOwner();
        g_sObjectName = llGetObjectName();
        integer i = llGetInventoryNumber(INVENTORY_NOTECARD);
        integer iIsOracul;
        while(i) {
            if (!llSubStringIndex(llGetInventoryName(INVENTORY_NOTECARD,--i),"SET")) {
                iIsOracul = TRUE;
                i = 0;
            }
        }
        if (iIsOracul) {
            if (llGetInventoryType("oracul.sys") != INVENTORY_SCRIPT)
                iIsOracul = FALSE;
        }
        if (!iIsOracul) {
            Say("\n\n"+g_sObjectName+" does not appear to be a supported AO\nRemoving myself...\n");
            RemoveMe();
        }
        if (llGetAttached()) {
            Say("\n\nI only work when the AO is rezzed to the ground... \nRemoving myself...\n");
            RemoveMe();
        }
        integer iChannel = -llAbs((integer)("0x" + llGetSubString(g_kOwner,30,-1)));
        llListen(iChannel,"","","");
        llWhisper(iChannel,"AO set installation");
        Say("\n\nSearching for OpenCollar AO version 6.2.0 or higher, please make sure there is only one and it is rezzed and not attached!\n");
        llSetTimerEvent(5);
    }
    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (llGetOwnerKey(kID) != llGetOwner()) return;
        if (kID == g_kOwner) {
            llListenRemove(g_iListener);
            integer index = llListFindList(g_lSettingCards,[sMessage]);
            if (~index) {
                g_sSettingCard = llList2String(g_lSettingCards,index+1);
                g_kCardRequestID = llGetNotecardLine(g_sSettingCard,g_iLine);
                Say("\n\nInstalling \""+g_sSettingCard+"\" from \""+g_sObjectName+"\" into your OpenCollar AO as new Wildcard.\nPlease stand by...\n");
                Particles(g_kAOID);
            }
        } else {
            if (g_kAOID == "") {
                llSetTimerEvent(0);
                g_kAOID = kID;
            }
            if (g_kAOID != kID) return;
            else if (sMessage == "@END") Menu();
            else g_sPreInstalledAnimations += sMessage;
        }
    }
    dataserver(key kRequestID, string sData) {
        if (kRequestID != g_kCardRequestID) return;
        if (sData != EOF) {
            if (!llSubStringIndex(sData,"[Stand") || !llSubStringIndex(sData,"[Sit") 
            || !llSubStringIndex(sData,"[Walk") || !llSubStringIndex(sData,"[Turn") 
            || !llSubStringIndex(sData,"[Run") || !llSubStringIndex(sData,"[Crouch")
            || !llSubStringIndex(sData,"[Jump") || !llSubStringIndex(sData,"[Fly") 
            || !llSubStringIndex(sData,"[Hover") || !llSubStringIndex(sData,"[Fall") 
            || !llSubStringIndex(sData,"[Jump")) {
                list temp = llParseString2List(sData,[",","]"],[]);
                integer i = llGetListLength(temp);
                string sAnim;
                while (--i) {
                    sAnim = llList2String(temp,i);
                    if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION && !~llSubStringIndex(g_sPreInstalledAnimations,sAnim) )
                        llGiveInventory(g_kAOID,sAnim);
                }
            }
            g_kCardRequestID = llGetNotecardLine(g_sSettingCard,++g_iLine);
        } else {
            llGiveInventory(g_kAOID,g_sSettingCard);
            Say("\n\nInstallation of \""+g_sSettingCard+"\" from \""+g_sObjectName+"\" into your OpenCollar AO finished. Pick your AO up and wear it, then choose a Wildcard animation set.\nRemoving myself...\n");
            llParticleSystem([]);
            RemoveMe();
        }
    }
    timer() {
        if (g_iTimeOut)
            Say("\n\nYou did not answer the menu in a timely fashion.\nRemoving myself...");
        else
            Say("\n\nNo OpenCollar AO 6.2.0 or higher found.\nRemoving myself......\nRez an OpenCollar AO version 6.2.0 or higher and insert me into the Oracal AO again.\n");
        llParticleSystem([]);
        RemoveMe();
    }
}
