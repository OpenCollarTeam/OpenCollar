// This file is part of OpenCollar.
// Copyright (c) 2008 - 2016 Nandana Singh, Lulu Pink, Garvin Twine,
// Cleo Collins, Master Starship, Joy Stipe, Wendy Starfall, littlemousy,
// Romka Swallowtail et al.
// Licensed under the GPLv2.  See LICENSE for full details.


// Based on a split of OpenCollar - appearance by Romka Swallowtail
// Virtual Disgrace - Resizer is derivative of OpenCollar - adjustment

string g_sSubMenu = "Size/Position";
string g_sParentMenu = "Settings";

//string g_sDeviceType = "collar";

list g_lMenuIDs; // 3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

string POSMENU = "Position";
string ROTMENU = "Rotation";
string SIZEMENU = "Size";

float g_fSmallNudge = 0.0005;
float g_fMediumNudge = 0.005;
float g_fLargeNudge = 0.05;
float g_fNudge = 0.005; // g_fMediumNudge;
float g_fRotNudge;

// SizeScale

list SIZEMENU_BUTTONS = ["-1%", "-2%", "-5%", "-10%", "+1%", "+2%", "+5%", "+10%", "100%"]; // Buttons for menu
list g_lSizeFactors = [-1, -2, -5, -10, 1, 2, 5, 10, -1000]; // Actual size factors
list g_lPrimStartSizes; // Area for initial prim sizes (stored on rez)
integer g_iScaleFactor = 100; // The size on rez is always regarded as 100% to preven problem when scaling an item +10% and than - 10 %, which would actuall lead to 99% of the original size
integer g_bSizedByScript = FALSE; // Prevent reseting of the script when the item has been chnged by the script

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer REBOOT = -1000;

integer NOTIFY = 1002;
//integer SAY = 1004;

//integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
//integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer LINK_DIALOG = 3;
integer LINK_UPDATE = -10;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";

key g_kWearer;

//string g_sSettingToken = "resizer_";
//string g_sGlobalToken = "global_";

/*
integer g_bProfiled;
Debug(string sStr) {
    // If you delete the first // from the preceeding and following  lines,
    // profiling is off, debug is off, and the compiler will remind you to
    // remove the debug calls from the code, we're back to production mode
    if (!g_bProfiled) {
        g_bProfiled = TRUE;
        llScriptProfiler(TRUE);
    }
    llOwnerSay(llGetScriptName() + "(min free:" + (string)(llGetMemoryLimit() - llGetSPMaxMemory()) + ")[" + (string)llGetFreeMemory() + "] :\n" + sStr);
}
*/

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    //Debug("Made menu.");
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
    } else {
        g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
    }
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


StoreStartScaleLoop() {
    integer iPrimIndex;
    vector vPrimScale;
    vector vPrimPosit;
    list lPrimParams;

    g_lPrimStartSizes = [];

    if (llGetNumberOfPrims() < 2) {
        vPrimScale = llGetScale();
        g_lPrimStartSizes += vPrimScale.x;
    } else {
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++) {
            lPrimParams = llGetLinkPrimitiveParams(iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
            vPrimScale = llList2Vector(lPrimParams, 0);
            vPrimPosit = (llList2Vector(lPrimParams, 1) - llGetRootPosition()) / llGetRootRotation();
            g_lPrimStartSizes += [vPrimScale, vPrimPosit];
        }
    }

    g_iScaleFactor = 100;
}

ScalePrimLoop(integer iScale, integer bRezSize, key kAV) {
    integer iPrimIndex;
    float fScale = iScale / 100.0;
    list lPrimParams;
    vector vPrimScale;
    vector vPrimPos;
    vector vSize;

    if (llGetNumberOfPrims() < 2) {
        vSize = llList2Vector(g_lPrimStartSizes, 0);

        if (MinMaxUnscaled(llGetScale(), fScale) || !bRezSize) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The object cannot be scaled as you requested; prims are already at minimum or maximum size.", kAV);
            return;
        } else if (MinMaxScaled(fScale * vSize, fScale) || !bRezSize) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.", kAV);
            return;
        } else {
            llSetScale(fScale * vSize); // Not linked prim
        }
    } else {
        if  (!bRezSize) {
            // first some checking
            for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++) {
                lPrimParams = llGetLinkPrimitiveParams(iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
                vPrimScale = llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1) * 2);

                if (MinMaxUnscaled(llList2Vector(lPrimParams, 0), fScale)) {
                    llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The object cannot be scaled as you requested; prims are already at minimum or maximum size.", kAV);
                    return;
                } else if (MinMaxScaled(fScale * vPrimScale, fScale)) {
                    llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.", kAV);
                    return;
                }
            }
        }

        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Scaling started, please wait ...", kAV);

        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++) {
            vPrimScale = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1) * 2);
            vPrimPos = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1) * 2 + 1);
            if (iPrimIndex == 1) {
                llSetLinkPrimitiveParamsFast(iPrimIndex, [
                    PRIM_SIZE, vPrimScale
                ]);
            } else {
                llSetLinkPrimitiveParamsFast(iPrimIndex, [
                    PRIM_SIZE, vPrimScale,
                    PRIM_POSITION, vPrimPos
                ]);
            }
        }

        g_iScaleFactor = iScale;
        g_bSizedByScript = TRUE;
        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Scaling finished, the %DEVICETYPE% is now on " + (string)g_iScaleFactor + "% of the rez size.", kAV);
    }
}

ForceUpdate() {
    // Workaround for https://jira.secondlife.com/browse/VWR-1168
    llSetText(".", <1.0, 1.0, 1.0>, 1.0);
    llSetText("", <1.0, 1.0, 1.0>, 1.0);
}

vector ConvertPos(vector vPos) {
    integer iAttachPoint = llGetAttached();
    vector vOut = vPos;

    if (iAttachPoint == ATTACH_CHEST) {
        vOut.x = -vPos.y;
        vOut.y = vPos.z;
        vOut.z = vPos.x;
    } else if (iAttachPoint == ATTACH_BACK) {
        vOut.x = -vPos.y;
        vOut.y = -vPos.z;
        vOut.z = -vPos.x;
    } else if (iAttachPoint == ATTACH_NECK) {
        vOut.x = vPos.x;
        vOut.y = -vPos.y;
        vOut.z = vPos.z;
    } else if (iAttachPoint == ATTACH_LHAND || iAttachPoint == ATTACH_LUARM || iAttachPoint == ATTACH_LLARM) {
        vOut.x = vPos.x;
        vOut.y = -vPos.z;
        vOut.z = vPos.y;
    } else if (iAttachPoint == ATTACH_RHAND || iAttachPoint == ATTACH_RUARM || iAttachPoint == ATTACH_RLARM) {
        vOut.x = vPos.x;
        vOut.y = vPos.z;
        vOut.z = -vPos.y;
    }

    return vOut;
}

AdjustPos(vector vDelta) {
    if (llGetAttached()) {
        llSetPos(llGetLocalPos() + ConvertPos(vDelta));
    }

    ForceUpdate();
}

vector ConvertRot(vector vRot) {
    integer iAttachPoint = llGetAttached();
    vector vOut = vRot;

    if (iAttachPoint == ATTACH_CHEST) {
        vOut.x = -vRot.y;
        vOut.y = -vRot.z;
        vOut.z = -vRot.x;
    } else if (iAttachPoint == ATTACH_BACK) {
        vOut.x = -vRot.y;
        vOut.y = vRot.z;
        vOut.z = vRot.x;
    } else if (iAttachPoint == ATTACH_NECK) {
        vOut.x = -vRot.x;
        vOut.y = -vRot.y;
        vOut.z = -vRot.z;
    } else if (iAttachPoint == ATTACH_LHAND || iAttachPoint == ATTACH_LUARM || iAttachPoint == ATTACH_LLARM) {
        vOut.x = vRot.x;
        vOut.y = -vRot.z;
        vOut.z = vRot.y;
    } else if (iAttachPoint == ATTACH_RHAND || iAttachPoint == ATTACH_RUARM || iAttachPoint == ATTACH_RLARM) {
        vOut.x = vRot.x;
        vOut.y = vRot.z;
        vOut.z = -vRot.y;
    }

    return vOut;
}

AdjustRot(vector vDelta) {
    if (llGetAttached()) {
        llSetLocalRot(llGetLocalRot() * llEuler2Rot(ConvertRot(vDelta)));
    }

    ForceUpdate();
}

RotMenu(key kAv, integer iAuth) {
    string sPrompt = "\nHere you can tilt and rotate the %DEVICETYPE%.";
    list lButtons = [
        "Tilt up ↻", "Left ↶", "Tilt left ↙",
        "Tilt down ↺", "Right ↷", "Tilt right ↘"
    ]; // ria change
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, ROTMENU);
}

PosMenu(key kAv, integer iAuth) {
    string sPrompt = "\nHere you can nudge the %DEVICETYPE% in place.\n\nCurrent nudge strength is: ";
    list lButtons = [
        "Left ←", "Up ↑", "Forward ↳",
        "Right →", "Down ↓", "Backward ↲"
    ]; // ria iChange

    if (g_fNudge != g_fSmallNudge) lButtons += ["▁"];
    else sPrompt += "▁";

    if (g_fNudge != g_fMediumNudge) lButtons += ["▁ ▂"];
    else sPrompt += "▁ ▂";

    if (g_fNudge != g_fLargeNudge) lButtons += ["▁ ▂ ▃"];
    else sPrompt += "▁ ▂ ▃";

    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, POSMENU);
}

SizeMenu(key kAv, integer iAuth) {
    string sPrompt = "\nNumbers are based on the original size of the %DEVICETYPE%.\n\nCurrent size: " + (string)g_iScaleFactor + "%";
    Dialog(kAv, sPrompt, SIZEMENU_BUTTONS, [UPMENU], 0, iAuth, SIZEMENU);
}

DoMenu(key kAv, integer iAuth) {
    string sPrompt = "\nChange the position, rotation and size of your %DEVICETYPE%.";
    list lButtons = [POSMENU, ROTMENU, SIZEMENU];
    Dialog(kAv, sPrompt, lButtons, [UPMENU], 0, iAuth, g_sSubMenu);
}

UserCommand(integer iNum, string sStr, key kID) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    //string sValue = llToLower(llList2String(lParams, 1));
    if (sCommand == "menu" && llGetSubString(sStr, 5, -1) == g_sSubMenu) {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
            llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
        } else {
            DoMenu(kID, iNum);
        }
    } else if (sStr == "appearance") {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            DoMenu(kID, iNum);
        }
    } else if (sStr == "rotation") {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            RotMenu(kID, iNum);
        }
    } else if (sStr == "position") {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            PosMenu(kID, iNum);
        }
    } else if (sStr == "size") {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            SizeMenu(kID, iNum);
        }
    } else if (sStr == "rm resizer") {
        if (kID != g_kWearer && iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kID);
        } else {
            Dialog(kID, "\nDo you really want to remove the Resizer?", ["Yes", "No", "Cancel"], [], 0, iNum, "rmresizer");
        }
    }
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        //llSetMemoryLimit(40960); // 2015-05-16 (5612 bytes free)
        g_kWearer = llGetOwner();
        g_fRotNudge = PI / 32.0; // Have to do this here since we can't divide in a global var declaration
        StoreStartScaleLoop();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER)
            UserCommand( iNum, sStr, kID);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);

                // Remove stride from g_lMenuIDs
                // We have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == g_sSubMenu) {
                    if (sMessage == UPMENU) llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == POSMENU) PosMenu(kAv, iAuth);
                    else if (sMessage == ROTMENU) RotMenu(kAv, iAuth);
                    else if (sMessage == SIZEMENU) SizeMenu(kAv, iAuth);
                } else if (sMenuType == POSMENU) {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                        return;
                    } else if (llGetAttached()) {
                        if (sMessage == "Forward ↳") AdjustPos(<g_fNudge, 0.0, 0.0>);
                        else if (sMessage == "Left ←") AdjustPos(<0.0, g_fNudge, 0.0>);
                        else if (sMessage == "Up ↑") AdjustPos(<0.0, 0.0, g_fNudge>);
                        else if (sMessage == "Backward ↲") AdjustPos(<-g_fNudge, 0.0, 0.0>);
                        else if (sMessage == "Right →") AdjustPos(<0.0, -g_fNudge, 0.0>);
                        else if (sMessage == "Down ↓") AdjustPos(<0.0, 0.0, -g_fNudge>);
                        else if (sMessage == "▁") g_fNudge = g_fSmallNudge;
                        else if (sMessage == "▁ ▂") g_fNudge = g_fMediumNudge;
                        else if (sMessage == "▁ ▂ ▃") g_fNudge = g_fLargeNudge;
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Sorry, position can only be adjusted while worn", kID);
                    }

                    PosMenu(kAv, iAuth);
                } else if (sMenuType == ROTMENU) {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                        return;
                    } else if (llGetAttached()) {
                        if (sMessage == "Tilt right ↘") AdjustRot(<g_fRotNudge, 0.0, 0.0>);
                        else if (sMessage == "Tilt up ↻") AdjustRot(<0.0, g_fRotNudge, 0.0>);
                        else if (sMessage == "Left ↶") AdjustRot(<0.0, 0.0, g_fRotNudge>);
                        else if (sMessage == "Right ↷") AdjustRot(<0.0, 0.0, -g_fRotNudge>);
                        else if (sMessage == "Tilt left ↙") AdjustRot(<-g_fRotNudge, 0.0, 0.0>);
                        else if (sMessage == "Tilt down ↺") AdjustRot(<0.0, -g_fRotNudge, 0.0>);
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Sorry, position can only be adjusted while worn", kID);
                    }

                    RotMenu(kAv, iAuth);
                } else if (sMenuType == SIZEMENU) {
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                        return;
                    } else {
                        integer iMenuCommand = llListFindList(SIZEMENU_BUTTONS, [sMessage]);
                        if (iMenuCommand != -1) {
                            integer iSizeFactor = llList2Integer(g_lSizeFactors, iMenuCommand);
                            if (iSizeFactor == -1000) {
                                if (g_iScaleFactor == 100) {
                                    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Resizing canceled; the %DEVICETYPE% is already at original size.", kID);
                                } else {
                                    ScalePrimLoop(100, TRUE, kAv);
                                }
                            } else {
                                ScalePrimLoop(g_iScaleFactor + iSizeFactor, FALSE, kAv);
                            }
                        }

                        SizeMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "rmresizer") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Resizer has been removed.", kAv);

                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
                            llRemoveInventory(llGetScriptName());
                        }
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Resizer remains installed.", kAv);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                // Remove stride from g_lMenuIDs
                // We have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE && sStr == "LINK_DIALOG") {
            LINK_DIALOG = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        }
    }

    timer() {
        // The timer is needed as the changed_size even is triggered twice
        llSetTimerEvent(0);
        if (g_bSizedByScript) {
            g_bSizedByScript = FALSE;
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_SCALE) {
            if (g_bSizedByScript) {
                llSetTimerEvent(0.5);
            } else {
                StoreStartScaleLoop();
            }
        }

        if (iChange & (CHANGED_SHAPE | CHANGED_LINK)) {
            StoreStartScaleLoop();
        }
    }
}
