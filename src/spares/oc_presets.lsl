 /*

 Copyright (c) 2017 virtualdisgrace.com

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. 
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
*/

// Based on Virtual Disgrace - Resizer

string g_sSubMenu = "SizePresets";
string g_sParentMenu = "Apps";

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

string RESTORE = "Restore";
string SAVE = "Save";
string DEL = "Delete";
string NEW = "New";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;

integer NOTIFY = 1002;
//integer SAY = 1004;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;
integer REBOOT      = -1000;
integer LINK_DIALOG = 3;
integer LINK_SAVE   = 5;
integer LINK_UPDATE = -10;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";

key g_kWearer;

string g_sSettingToken = "presets"; // or "resizer" for oc_resizer2 settings compatible ?

list g_lPresets = [] ;  // [sName, "vScale/vPos/vRot"]

/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    //Debug("Made menu.");
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
}

integer MinMaxUnscaled(vector vSize, float fScale) {
    if (fScale < 1.0) {
        if (vSize.x <= 0.01) return TRUE;
        if (vSize.y <= 0.01) return TRUE;
        if (vSize.z <= 0.01) return TRUE;
    } else {
        if (vSize.x >= 10.0) return TRUE;
        if (vSize.y >= 10.0) return TRUE;
        if (vSize.z >= 10.0) return TRUE;
    }
    return FALSE;
}

integer MinMaxScaled(vector vSize, float fScale) {
    if (fScale < 1.0) {
        if (vSize.x < 0.01) return TRUE;
        if (vSize.y < 0.01) return TRUE;
        if (vSize.z < 0.01) return TRUE;
    } else {
        if (vSize.x > 10.0) return TRUE;
        if (vSize.y > 10.0) return TRUE;
        if (vSize.z > 10.0) return TRUE;
    }
    return FALSE;
}

ScalePrimLoop(integer iScale, key kAV) {
    integer iPrimIndex;
    float fScale = iScale / 100.0;
    list lPrimParams;
    vector vPrimScale;
    vector vPrimPos;
    vector vSize;
    if (llGetNumberOfPrims()<2) {
        vSize = llGetScale();
        if (MinMaxUnscaled(vSize, fScale)) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The object cannot be scaled as you requested; prims are already at minimum or maximum size.",kAV);
            return;
        } else if (MinMaxScaled(fScale * vSize, fScale)) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The object cannot be scaled as you requested; prims would surpass minimum or maximum size.",kAV);
            return;
        } else llSetScale(fScale * vSize); // not linked prim
    } else {
        // first some checking
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ ) {
            lPrimParams = llGetLinkPrimitiveParams(iPrimIndex, [PRIM_SIZE]);
            vPrimScale = llList2Vector(lPrimParams,0);

            if (MinMaxUnscaled(vPrimScale, fScale)) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The object cannot be scaled as you requested; prims are already at minimum or maximum size.",kAV);
                return;
            } else if (MinMaxScaled(fScale * vPrimScale, fScale)) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+ "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.",kAV);
                return;
            }
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Scaling started, please wait ...",kAV);
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ ) {
            lPrimParams = llGetLinkPrimitiveParams(iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
            vPrimScale = fScale * llList2Vector(lPrimParams,0);
            vPrimPos = fScale * ( (llList2Vector(lPrimParams,1)-llGetRootPosition())/llGetRootRotation() );
            if (iPrimIndex == 1) llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale]);
            else llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale, PRIM_POSITION, vPrimPos]);
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Scaling finished.",kAV);
    }
}

ForceUpdate() {
     //workaround for https://jira.secondlife.com/browse/VWR-1168
    llSetText(".", <1,1,1>, 1.0);
    llSetText("", <1,1,1>, 1.0);
}

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_presets")
        llRemoveInventory(sName);
}

DoMenu(key kAv, integer iAuth) {
    list lMyButtons ;
    string sPrompt;
    sPrompt = "\nYou can save/restore size, position and rotation of %DEVICETYPE%.";

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
    }
    else if (sType == DEL) sPrompt = "\nSelect preset or create new to delete size/position/rotation";
    if (sType == NEW) {
        sPrompt = "\nType new preset name";
        lMyButtons = [];
        lUtils = [];
    }
    Dialog(kAv, sPrompt, lMyButtons, lUtils, 0, iAuth, sType);
}

Restore(string sName, key kAv) {
    if (!llGetAttached()) return;
    integer i = llListFindList(g_lPresets,[sName]);
    if (~i) {
        list lSettings = llParseString2List(llList2String(g_lPresets, i+1),["/"],[]);
        vector vCurSize = llGetScale();
        vector vDestSize = (vector)llList2String(lSettings,0);
        integer iScale = llRound((vDestSize.x / vCurSize.x) * 100);
        if (iScale != 100) ScalePrimLoop(iScale, kAv);
        llSetPos((vector)llList2String(lSettings,1));
        llSetLocalRot((rotation)llList2String(lSettings,2));
        ForceUpdate();

        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%DEVICETYPE% size/position/rotation restored from "+sName+" preset.",kAv);
    }
}

Save(string sName, key kAv) {
    string sSettings = (string)llGetScale()+"/"+(string)llGetLocalPos()+"/"+(string)llGetLocalRot();
    integer i = llListFindList(g_lPresets,[sName]);
    if (~i) g_lPresets = llListReplaceList(g_lPresets, [sSettings], i+1, i+1);
    else g_lPresets += [sName, sSettings];
    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"="+llDumpList2String(g_lPresets,"~"), "");

    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%DEVICETYPE% size/position/rotation saved to "+sName+" preset.",kAv);
}

Delete(string sName, key kAv) {
    integer i = llListFindList(g_lPresets,[sName]);
    if (~i) {
        g_lPresets = llDeleteSubList(g_lPresets, i, i+1);
        if (g_lPresets != []) llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"="+llDumpList2String(g_lPresets,"~"), "");
        else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken, "");

        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%DEVICETYPE% size/position/rotation preset "+sName+" is deleted.",kAv);
    }
}

UserCommand(integer iNum, string sStr, key kID) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llList2String(lParams, 1);
    if (sCommand == "menu" && sValue == g_sSubMenu) {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
        } else DoMenu(kID, iNum);
    } else if (sCommand == "restore") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else Restore(sValue,kID);
    } else if (sStr == "rm presets") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else Dialog(kID, "\nDo you really want to remove the "+g_sSubMenu+"?", ["Yes","No","Cancel"], [], 0, iNum,"rmscript");
    }
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        //llSetMemoryLimit(40960);  //2015-05-16 (5612 bytes free)
        g_kWearer = llGetOwner();
        FailSafe();
        //Debug("Starting");
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
            if (sID == g_sSettingToken) g_lPresets = llParseString2List(sValue, ["~"], []);
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
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
                        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken, "");
                        llMessageLinked(LINK_DIALOG,NOTIFY, "1"+"Resizer has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG,NOTIFY, "0"+"Resizer remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) FailSafe();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
 }
