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
//          Resizer2 - 170820.1          .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Nandana Singh, Lulu Pink, Garvin Twine,       //
//  Cleo Collins, Master Starship, Joy Stipe, Wendy Starfall, littlemousy,  //
//  Romka Swallowtail et al.                                                //
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
//       github.com/VirtualDisgrace/opencollar/tree/master/src/collar       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// Based on a split of OpenCollar - appearance by Romka Swallowtail
// Virtual Disgrace - Resizer is derivative of OpenCollar - adjustment

string g_sSubMenu = "Size/Position";
string g_sParentMenu = "Apps";
//string g_sParentMenu = "Settings";

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

string RESTORE = "Restore";
string SAVE = "Save";
string DEL = "Delete";
string NEW = "New";

string POSMENU = "Position";
string ROTMENU = "Rotation";
string SIZEMENU = "Size";

float g_fSmallNudge=0.0005;
float g_fMediumNudge=0.005;
float g_fLargeNudge=0.05;
float g_fNudge=0.005; // g_fMediumNudge;
float g_fRotNudge;

// SizeScale

list SIZEMENU_BUTTONS = [ "-1%", "-2%", "-5%", "-10%", "+1%", "+2%", "+5%", "+10%", "100%" ]; // buttons for menu
list g_lSizeFactors = [-1, -2, -5, -10, 1, 2, 5, 10, -1000]; // actual size factors
list g_lPrimStartSizes; // area for initial prim sizes (stored on rez)
integer g_iScaleFactor = 100; // the size on rez is always regarded as 100% to preven problem when scaling an item +10% and than - 10 %, which would actuall lead to 99% of the original size
integer g_iSizedByScript = FALSE; // prevent reseting of the script when the item has been chnged by the script

//MESSAGE MAP
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

integer NOTIFY = 1002;
//integer SAY = 1004;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;
integer REBOOT              = -1000;
integer LINK_DIALOG         = 3;
integer LINK_SAVE           = 5;
integer LINK_UPDATE = -10;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";

key g_kWearer;

string g_sSettingToken = "resizer";
//string g_sGlobalToken = "global_";

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


Store_StartScaleLoop() {
    g_lPrimStartSizes = [];
    integer iPrimIndex;
    vector vPrimScale;
    vector vPrimPosit;
    list lPrimParams;
    if (llGetNumberOfPrims()<2) {
        vPrimScale = llGetScale();
        g_lPrimStartSizes += vPrimScale.x;
    } else {
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ ) {
            lPrimParams = llGetLinkPrimitiveParams( iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
            vPrimScale=llList2Vector(lPrimParams,0);
            vPrimPosit=(llList2Vector(lPrimParams,1)-llGetRootPosition())/llGetRootRotation();
            g_lPrimStartSizes += [vPrimScale,vPrimPosit];
        }
    }
    g_iScaleFactor = 100;
}

ScalePrimLoop(integer iScale, integer iRezSize, key kAV) {
    integer iPrimIndex;
    float fScale = iScale / 100.0;
    list lPrimParams;
    vector vPrimScale;
    vector vPrimPos;
    vector vSize;
    if (llGetNumberOfPrims()<2) {
        vSize = llList2Vector(g_lPrimStartSizes,0);
        if (MinMaxUnscaled(llGetScale(), fScale) || !iRezSize) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The object cannot be scaled as you requested; prims are already at minimum or maximum size.",kAV);
            return;
        } else if (MinMaxScaled(fScale * vSize, fScale) || !iRezSize) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The object cannot be scaled as you requested; prims would surpass minimum or maximum size.",kAV);
            return;
        } else llSetScale(fScale * vSize); // not linked prim
    } else {
        if  (!iRezSize) {
            // first some checking
            for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ ) {
                lPrimParams = llGetLinkPrimitiveParams( iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
                vPrimScale = llList2Vector(g_lPrimStartSizes, (iPrimIndex  - 1)*2);

                if (MinMaxUnscaled(llList2Vector(lPrimParams,0), fScale)) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"The object cannot be scaled as you requested; prims are already at minimum or maximum size.",kAV);
                    return;
                } else if (MinMaxScaled(fScale * vPrimScale, fScale)) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+ "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.",kAV);
                    return;
                }
            }
        }
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Scaling started, please wait ...",kAV);
        g_iSizedByScript = TRUE;
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ ) {
            vPrimScale = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1)*2);
            vPrimPos = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1)*2+1);
            if (iPrimIndex == 1)
                llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale]);
            else
                llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale, PRIM_POSITION, vPrimPos]);
        }
        g_iScaleFactor = iScale;
        g_iSizedByScript = TRUE;
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Scaling finished, the %DEVICETYPE% is now on "+ (string)g_iScaleFactor +"% of the rez size.",kAV);
    }
}

ForceUpdate() {
     //workaround for https://jira.secondlife.com/browse/VWR-1168
    llSetText(".", <1,1,1>, 1.0);
    llSetText("", <1,1,1>, 1.0);
}

vector ConvertPos(vector pos) {
    integer ATTACH = llGetAttached();
    vector out ;
    if (ATTACH == 1) { out.x = -pos.y; out.y = pos.z; out.z = pos.x; }
    else if (ATTACH == 9) { out.x = -pos.y; out.y = -pos.z; out.z = -pos.x; }
    else if (ATTACH == 39) { out.x = pos.x; out.y = -pos.y; out.z = pos.z; }
    else if (ATTACH == 5 || ATTACH == 20 || ATTACH == 21 ) { out.x = pos.x; out.y = -pos.z; out.z = pos.y ; }
    else if (ATTACH == 6 || ATTACH == 18 || ATTACH == 19 ) { out.x = pos.x; out.y = pos.z; out.z = -pos.y; }
    else out = pos ;
    return out ;
}

AdjustPos(vector vDelta) {
    if (llGetAttached()) llSetPos(llGetLocalPos() + ConvertPos(vDelta));
    ForceUpdate();
}

vector ConvertRot(vector rot) {
    integer ATTACH = llGetAttached();
    vector out ;
    if (ATTACH == 1) { out.x = -rot.y; out.y = -rot.z; out.z = -rot.x; }
    else if (ATTACH == 9) { out.x = -rot.y; out.y = rot.z; out.z = rot.x; }
    else if (ATTACH == 39) { out.x = -rot.x; out.y = -rot.y; out.z = -rot.z; }
    else if (ATTACH == 5 || ATTACH == 20 || ATTACH == 21) { out.x = rot.x; out.y = -rot.z; out.z = rot.y; }
    else if (ATTACH == 6 || ATTACH == 18 || ATTACH == 19) { out.x = rot.x; out.y = rot.z; out.z = -rot.y; }
    else out = rot ;
    return out ;
}

AdjustRot(vector vDelta) {
    if (llGetAttached()) llSetLocalRot(llGetLocalRot() * llEuler2Rot(ConvertRot(vDelta)));
    ForceUpdate();
}

RotMenu(key kAv, integer iAuth) {
    string sPrompt = "\nHere you can tilt and rotate the %DEVICETYPE%.";
    list lMyButtons = ["tilt up ↻", "left ↶", "tilt left ↙", "tilt down ↺", "right ↷", "tilt right ↘"];// ria change
    Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth,ROTMENU);
}

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_resizer2")
        llRemoveInventory(sName);
}

PosMenu(key kAv, integer iAuth) {
    string sPrompt = "\nHere you can nudge the %DEVICETYPE% in place.\n\nCurrent nudge strength is: ";
    list lMyButtons = ["left ←", "up ↑", "forward ↳", "right →", "down ↓", "backward ↲"];// ria iChange
    if (g_fNudge!=g_fSmallNudge) lMyButtons+=["▁"];
    else sPrompt += "▁";
    if (g_fNudge!=g_fMediumNudge) lMyButtons+=["▁ ▂"];
    else sPrompt += "▁ ▂";
    if (g_fNudge!=g_fLargeNudge) lMyButtons+=["▁ ▂ ▃"];
    else sPrompt += "▁ ▂ ▃";
    Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth,POSMENU);
}

SizeMenu(key kAv, integer iAuth) {
    string sPrompt = "\nNumbers are based on the original size of the %DEVICETYPE%.\n\nCurrent size: " + (string)g_iScaleFactor + "%";
    Dialog(kAv, sPrompt, SIZEMENU_BUTTONS, [UPMENU], 0, iAuth, SIZEMENU);
}

DoMenu(key kAv, integer iAuth) {
    list lMyButtons ;
    string sPrompt;
    sPrompt = "\nChange the position, rotation and size of your %DEVICETYPE%.\n\nwww.opencollar.at/appearance";
    lMyButtons = [POSMENU, ROTMENU, SIZEMENU];
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
        integer iDif = llRound((vDestSize.x / vCurSize.x) * 100);
        if (iDif != 100) {
            ScalePrimLoop(iDif, FALSE, kAv);
            Store_StartScaleLoop();
        }
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
    } else if (sStr == "appearance") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else DoMenu(kID, iNum);
    } else if (sStr == "rotation") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else RotMenu(kID, iNum);
    } else if (sStr == "position") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else PosMenu(kID, iNum);
    } else if (sStr == "size") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else SizeMenu(kID, iNum);
    } else if (sStr == "rm resizer") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else Dialog(kID, "\nDo you really want to remove the Resizer?", ["Yes","No","Cancel"], [], 0, iNum,"rmresizer");
    } else if (sCommand == "restore") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else Restore(sValue,kID);
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
        g_fRotNudge = PI / 32.0;//have to do this here since we can't divide in a global var declaration
        Store_StartScaleLoop();
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
        }
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
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
                    else if (sMessage == POSMENU) PosMenu(kAv, iAuth);
                    else if (sMessage == ROTMENU) RotMenu(kAv, iAuth);
                    else if (sMessage == SIZEMENU) SizeMenu(kAv, iAuth);
                    else if (sMessage == RESTORE) PresetMenu(kAv, iAuth, RESTORE);
                    else if (sMessage == SAVE) PresetMenu(kAv, iAuth, SAVE);
                    else if (sMessage == DEL) PresetMenu(kAv, iAuth, DEL);
                } else if (sMenuType == POSMENU) {
                    if (sMessage == UPMENU) {
                        DoMenu(kAv, iAuth);
                        return;
                    } else if (llGetAttached()) {
                        if (sMessage == "forward ↳") AdjustPos(<g_fNudge, 0, 0>);
                        else if (sMessage == "left ←") AdjustPos(<0, g_fNudge, 0>);
                        else if (sMessage == "up ↑") AdjustPos(<0, 0, g_fNudge>);
                        else if (sMessage == "backward ↲") AdjustPos(<-g_fNudge, 0, 0>);
                        else if (sMessage == "right →") AdjustPos(<0, -g_fNudge, 0>);
                        else if (sMessage == "down ↓") AdjustPos(<0, 0, -g_fNudge>);
                        else if (sMessage == "▁") g_fNudge=g_fSmallNudge;
                        else if (sMessage == "▁ ▂") g_fNudge=g_fMediumNudge;
                        else if (sMessage == "▁ ▂ ▃") g_fNudge=g_fLargeNudge;
                    } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Sorry, position can only be adjusted while worn",kID);
                    PosMenu(kAv, iAuth);
                } else if (sMenuType == ROTMENU) {
                    if (sMessage == UPMENU) {
                        DoMenu(kAv, iAuth);
                        return;
                    } else if (llGetAttached()) {
                        if (sMessage == "tilt right ↘") AdjustRot(<g_fRotNudge, 0, 0>);
                        else if (sMessage == "tilt up ↻") AdjustRot(<0, g_fRotNudge, 0>);
                        else if (sMessage == "left ↶") AdjustRot(<0, 0, g_fRotNudge>);
                        else if (sMessage == "right ↷") AdjustRot(<0, 0, -g_fRotNudge>);
                        else if (sMessage == "tilt left ↙") AdjustRot(<-g_fRotNudge, 0, 0>);
                        else if (sMessage == "tilt down ↺") AdjustRot(<0, -g_fRotNudge, 0>);
                    } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Sorry, position can only be adjusted while worn",kID);
                    RotMenu(kAv, iAuth);
                } else if (sMenuType == SIZEMENU) {
                    if (sMessage == UPMENU) {
                        DoMenu(kAv, iAuth);
                        return;
                    } else {
                        integer iMenuCommand = llListFindList(SIZEMENU_BUTTONS, [sMessage]);
                        if (iMenuCommand != -1) {
                            integer iSizeFactor = llList2Integer(g_lSizeFactors, iMenuCommand);
                            if (iSizeFactor == -1000) {
                                if (g_iScaleFactor == 100)
                                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Resizing canceled; the %DEVICETYPE% is already at original size.",kID);
                                else ScalePrimLoop(100, TRUE, kAv);
                            }
                            else ScalePrimLoop(g_iScaleFactor + iSizeFactor, FALSE, kAv);
                        }
                        SizeMenu(kAv, iAuth);
                    }
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
                } else if (sMenuType == "rmresizer") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken, "");
                        llMessageLinked(LINK_DIALOG,NOTIFY, "1"+"Resizer has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG,NOTIFY, "0"+"Resizer remains installed.", kAv);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        }
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    timer() {
        // the timer is needed as the changed_size even is triggered twice
        llSetTimerEvent(0);
        if (g_iSizedByScript) g_iSizedByScript = FALSE;
    }

    changed(integer iChange) {
        if (iChange & (CHANGED_SCALE)) {
            if (g_iSizedByScript) llSetTimerEvent(0.5);
            else Store_StartScaleLoop();
        }
        if (iChange & (CHANGED_SHAPE | CHANGED_LINK)) Store_StartScaleLoop();
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
