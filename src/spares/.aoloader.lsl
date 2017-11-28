// This file is part of OpenCollar.
// Copyright (c) 2016 Garvin Twine, Wendy Starfall.
// Licensed under the GPLv2.  See LICENSE for full details. 

/*
This utility requires both the OpenCollar AO of version 6.2.0 or greater
and another AO HUD rezzed next to each other on the ground. The script
has to be dropped into the other AO HUD which will open a dialog with a
selection of SET cards of this AO. Once a SET has been chosen, it will
attempt to install it on the OpenCollar AO where it will then be available
as a "Wildcard" until the user chooses to manually rename the notecard in
the OpenCollar AO's contents.
*/

string g_sVersion = "1.0";
string g_sSupportedAOs = "Oracul, AX and SP";

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
string g_sMyName;

string g_sManPage = "https://github.com/OpenCollarTeam/OpenCollar/wiki/AO-Loader";

Say(string sStr) {
    llSetObjectName("AO Loader v"+g_sVersion);
    llOwnerSay(sStr);
    llSetObjectName(g_sObjectName);
}

Menu(){
    string sPrompt = "\nWhich set do you want to install on your OpenCollar AO?\n\n"+g_sManPage;
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
        PSYS_SRC_TEXTURE, "a09ec8d2-45de-25f7-1662-ffffb8fe4a74",
        PSYS_SRC_TARGET_KEY, kTarget,
        /*PSYS_PART_START_COLOR, <0.529, 0.416, 0.212>,
        PSYS_PART_END_COLOR, <0.733, 0.592, 0.345>,*/
        PSYS_PART_START_SCALE, <0.01, 0.01, 0>,
        PSYS_PART_END_SCALE, <0.04, 0.04, 0>,
        PSYS_PART_START_ALPHA, 0.1,
        PSYS_PART_END_ALPHA, 1,
        PSYS_SRC_BURST_PART_COUNT, 4,
        PSYS_PART_MAX_AGE, 2,
        PSYS_SRC_BURST_SPEED_MIN, 0.2,
        PSYS_SRC_BURST_SPEED_MAX, 1
    ]);
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}


RemoveMe() {
    llRemoveInventory(llGetScriptName());
}

default {
    state_entry() {
        llParticleSystem([]);
        g_kOwner = llGetOwner();
        g_sMyName = llGetScriptName();
        g_sObjectName = llGetObjectName();
        PermsCheck();
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
            Say("\n\nSorry! I'm not compatible with \""+g_sObjectName+"\" at this time. My version is "+g_sVersion+" and so far I can load sets from "+g_sSupportedAOs+" AOs. Maybe there is a newer version of me available if you copy and paste my [https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/src/spares/.aoloader.lsl recent source] in a new script!\n\n"+g_sManPage+"\n");
            RemoveMe();
        }
        if (llGetAttached()) {
            Say("\n\nI only work when the AO is rezzed to the ground...\n\nCleaning myself up...\n\n"+g_sManPage+"\n");
            RemoveMe();
        }
        integer iChannel = -llAbs((integer)("0x" + llGetSubString(g_kOwner,30,-1)));
        llListen(iChannel,"","","");
        llWhisper(iChannel,"AO set installation");
        Say("\n\nSearching for an OpenCollar AO 6.2.0 or greater...\n\nPlease make sure there is only one OpenCollar AO and that it is rezzed on the ground, not attached to your avatar!\n\n"+g_sManPage+"\n");
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
                Say("\n\nInstalling \""+g_sSettingCard+"\" from \""+g_sObjectName+"\" into your OpenCollar AO.\n\nPlease stand by...\n");
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
            Say("\n\nThe installation was a success!\n\nThe new animation set will now be available as a Wildcard from your OpenCollar AO's Load menu.\n\n"+g_sManPage+"\n");
            llParticleSystem([]);
            RemoveMe();
        }
    }
    timer() {
        if (g_iTimeOut)
            Say("\n\nEither you missed my menu or you forgot about me!\n\nCleaning myself up...\n\n"+g_sManPage+"\n");
        else
            Say("\n\nI couldn't find a compatible OpenCollar AO nearby!\n\nPlease rez an OpenCollar AO version 6.2.0 or greater on the ground and insert me into the other AO HUD again.\n\n"+g_sManPage+"\n");
        llParticleSystem([]);
        RemoveMe();
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) PermsCheck();

    }
}
