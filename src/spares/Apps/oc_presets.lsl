// This file is part of OpenCollar.
// Copyright (c) 2019 Romka Swallowtail
// Licensed under the GPLv2.  See LICENSE for full details.

string g_sScriptVersion = "7.4"; // Used to validate that a script is up to date via versions/debug command.
integer LINK_CMD_DEBUG=1999;
DebugOutput(key kID, list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llInstantMessage(kID, llGetScriptName() +final);
}
string g_sSubMenu = "SizePresets";
string g_sParentMenu = "Apps";

string RESTORE = "RESTORE";
string SAVE = "SAVE";
string DEL = "DELETE";
string NEW = "NEW";
string UPMENU = "BACK";
string g_sToken = "presets";

//MESSAGE MAP
integer CMD_OWNER = 500;
integer CMD_WEARER = 503;

integer NOTIFY = 1002;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;
integer REBOOT      = -1000;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

key g_kWearer;

list g_lMenuIDs;
integer g_iMenuStride = 3;

list g_lPresets;  // [sName, "vScale/vPos/vRot"]

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
}

ForceUpdate() {
    //workaround for https://jira.secondlife.com/browse/VWR-1168
    llSetText(".", <1,1,1>, 1.0);
    llSetText("", <1,1,1>, 1.0);
}

DoMenu(key kAv, integer iAuth) {
    list lMyButtons ;
    string sPrompt = "\nYou can save/restore size, position and rotation of %DEVICETYPE%.";

    if (g_lPresets != []) lMyButtons += [RESTORE, SAVE, DEL];
    else lMyButtons += ["-", SAVE, "-"];
    Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth, g_sSubMenu);
}

PresetMenu(key kAv, integer iAuth, string sType) {
    string sPrompt;
    list lMyButtons = llList2ListStrided(g_lPresets,0,-1,2);
    list lUtils = [UPMENU];
    if (sType == RESTORE) sPrompt = "\nSelect preset to restore size/position/rotation";
    else if (sType == SAVE) {
        if (g_lPresets == []) sType = NEW;
        else {
            sPrompt = "\nSelect preset or create new to save size/position/rotation";
            lMyButtons += [NEW];
        }
    } else if (sType == DEL) sPrompt = "\nSelect preset or create new to delete size/position/rotation";
    if (sType == NEW) {
        sPrompt = "\nType new preset name";
        lMyButtons = [];
        lUtils = [];
    }
    Dialog(kAv, sPrompt, lMyButtons, lUtils, 0, iAuth, sType);
}

Restore(string sName, key kAv) {
    if (!llGetAttached()){
        llMessageLinked(LINK_THIS,NOTIFY, "0You must be wearing the %DEVICETYPE% in order to restore a preset", kAv);
        return;
    }
    integer i = llListFindList(g_lPresets,[sName]);
    if (~i) {
        list lSettings = llParseString2List(llList2String(g_lPresets, i+1),["/"],[]);
        vector vCurSize = llGetScale();
        vector vDestSize = (vector)llList2String(lSettings,0);
        float fScale = vDestSize.x / vCurSize.x;
        llScaleByFactor(fScale);
        llSetPos((vector)llList2String(lSettings,1));
        llSetLocalRot((rotation)llList2String(lSettings,2));
        ForceUpdate();
        llMessageLinked(LINK_THIS,NOTIFY,"0"+"%DEVICETYPE% size/position/rotation restored from '"+sName+"' preset.",kAv);
    }
}

Save(string sName, key kAv) {
    if(!llGetAttached()){
        llMessageLinked(LINK_THIS, NOTIFY, "0You cannot create or update a preset while the %DEVICETYPE% is rezzed", kAv);
        return;
    }
    string sSettings = (string)llGetScale()+"/"+(string)llGetLocalPos()+"/"+(string)llGetLocalRot();
    integer i = llListFindList(g_lPresets,[sName]);
    if (~i) g_lPresets = llListReplaceList(g_lPresets, [sSettings], i+1, i+1);
    else g_lPresets += [sName, sSettings];
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sToken+"="+llDumpList2String(g_lPresets,"~"), "");
    llMessageLinked(LINK_THIS,NOTIFY,"0"+"%DEVICETYPE% size/position/rotation saved to '"+sName+"' preset.",kAv);
}

Delete(string sName, key kAv) {
    integer i = llListFindList(g_lPresets,[sName]);
    if (~i) {
        g_lPresets = llDeleteSubList(g_lPresets, i, i+1);
        if (g_lPresets != []) llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sToken+"="+llDumpList2String(g_lPresets,"~"), "");
        else llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sToken, "");

        llMessageLinked(LINK_THIS,NOTIFY,"0"+"%DEVICETYPE% size/position/rotation preset '"+sName+"' is deleted.",kAv);
    }
}

UserCommand(integer iNum, string sStr, key kID) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llList2String(lParams, 1);
    if (sCommand == "menu" && sValue == g_sSubMenu) {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) {
            llMessageLinked(LINK_THIS,NOTIFY,"0"+"%NOACCESS%",kID);
            llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
        } else DoMenu(kID, iNum);
    } else if (sCommand == "restore") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_THIS,NOTIFY,"0"+"%NOACCESS%",kID);
        else Restore(sValue,kID);
    } else if (sStr == "rm presets") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_THIS,NOTIFY,"0"+"%NOACCESS%",kID);
        else Dialog(kID, "\nDo you really want to remove the "+g_sSubMenu+"?", ["Yes","No","Cancel"], [], 0, iNum,"rmscript");
    }
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        g_kWearer = llGetOwner();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
            UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sID = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sID == g_sToken) g_lPresets = llParseString2List(sValue, ["~"], []);
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenuType == g_sSubMenu) {
                    if (sMessage == UPMENU) llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    else PresetMenu(kAv, iAuth, sMessage);
                } else if (sMenuType == RESTORE) {
                    if (sMessage != UPMENU) Restore(sMessage, kAv);
                    DoMenu(kAv, iAuth);
                } else if (sMenuType == SAVE) {
                    if (sMessage == NEW) {
                        PresetMenu(kAv, iAuth, NEW);
                        return;
                    } else if (sMessage != UPMENU) Save(sMessage, kAv);
                    DoMenu(kAv, iAuth);
                } else if (sMenuType == NEW) {
                    sMessage = llStringTrim(sMessage,STRING_TRIM);
                    if (sMessage != "") Save(sMessage, kAv);
                    DoMenu(kAv, iAuth);
                } else if (sMenuType == DEL) {
                    if (sMessage != UPMENU) Delete(sMessage, kAv);
                    DoMenu(kAv, iAuth);
                } else if (sMenuType == "rmscript") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_THIS, LM_SETTING_DELETE, g_sToken, "");
                        llMessageLinked(LINK_THIS,NOTIFY, "1"+"Presets has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_THIS,NOTIFY, "0"+"Presets remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG){
            
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            llInstantMessage(kID, llGetScriptName() + " PRESETS: "+llDumpList2String(llList2ListStrided(g_lPresets, 0, -1, 2), " | "));
        }
            
    }
 }
