// This file is part of OpenCollar.
// Copyright (c) 2008 - 2021 Nandana Singh, Lulu Pink, Garvin Twine,
// Cleo Collins, Master Starship, Joy Stipe, Wendy Starfall, littlemousy,
// Romka Swallowtail et al.
// Licensed under the GPLv2.  See LICENSE for full details.


// Based on a split of OpenCollar - appearance by Romka Swallowtail
// Resizer is derivative of OpenCollar - adjustment

// Ping (Pingout Duffield) Jan 2023 Fix behavior of BACK button in Position, Rotation, and Size menus

string g_sScriptVersion = "8.1.0000";

integer LINK_CMD_DEBUG=1999;
string g_sSubMenu = "Size/Position";
string g_sParentMenu = "Settings";

//string g_sDeviceType = "collar";

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

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
vector g_vStartScale;
integer g_iScaleFactor = 100; // the size on rez is always regarded as 100% to preven problem when scaling an item +10% and than - 10 %, which would actuall lead to 99% of the original size
integer g_iSizedByScript = FALSE; // prevent reseting of the script when the item has been chnged by the script

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;
//integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
//integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;
integer REBOOT              = -1000;
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
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first /g_sDeviceType/ from the preceeding and following  lines,
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
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    //Debug("Made menu.");
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuType];
}


Store_StartScale() {
    g_vStartScale = llGetScale();
    g_iScaleFactor = 100;
}

Scale(integer iScale, integer iRezSize, key kAV) {
    vector vSize = llGetScale();
    vector vDestSize = g_vStartScale * (iScale*0.01);
    if (iRezSize) vDestSize = g_vStartScale;
    float fScale = vDestSize.x / vSize.x ;
    g_iSizedByScript = TRUE;
    // use new scale function integer llScaleByFactor( float scaling_factor );
    // http://wiki.secondlife.com/wiki/LlScaleByFactor
    if (llScaleByFactor(fScale)==TRUE) {
        g_iScaleFactor = iScale;
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Scaling finished, the %DEVICETYPE% is now on "+ (string)g_iScaleFactor +"% of the rez size.",kAV);
    } else llMessageLinked(LINK_SET,NOTIFY,"1"+ "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.",kAV);
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
    Dialog(kAv, sPrompt, SIZEMENU_BUTTONS, [UPMENU], 0, iAuth,SIZEMENU);
}

DoMenu(key kAv, integer iAuth) {
    list lMyButtons ;
    string sPrompt;
    sPrompt = "\nChange the position, rotation and size of your %DEVICETYPE%.";
    lMyButtons = [POSMENU, ROTMENU, SIZEMENU];
    Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth,g_sSubMenu);
}

UserCommand(integer iNum, string sStr, key kID) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    // string sValue = llToLower(llList2String(lParams, 1));
    if (sCommand == "menu" && llGetSubString(sStr, 5, -1) == g_sSubMenu) {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) {
            llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to resizer",kID);
            llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
        } else DoMenu(kID, iNum);
    } else if (sStr == "appearance") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to appearance",kID);
        else DoMenu(kID, iNum);
    } else if (sStr == "rotation") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to rotation",kID);
        else RotMenu(kID, iNum);
    } else if (sStr == "position") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to position",kID);
        else PosMenu(kID, iNum);
    } else if (sStr == "size") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to size",kID);
        else SizeMenu(kID, iNum);
    } else if (sStr == "rm resizer") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to uninstall resizer",kID);
        else Dialog(kID, "\nDo you really want to remove the Resizer?", ["Yes","No","Cancel"], [], 0, iNum,"rmresizer");
    }
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT){
            if(sStr == "reboot"){
                llResetScript();
            }
        } else if(iNum == READY){
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP){
            state active;
        }
    }
}
state active
{
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        //llSetMemoryLimit(40960);  //2015-05-16 (5612 bytes free)
        g_kWearer = llGetOwner();
        g_fRotNudge = PI / 32.0;//have to do this here since we can't divide in a global var declaration
        Store_StartScale();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
            UserCommand( iNum, sStr, kID);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                // integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenuType == g_sSubMenu) {
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == POSMENU) PosMenu(kAv, iAuth);
                    else if (sMessage == ROTMENU) RotMenu(kAv, iAuth);
                    else if (sMessage == SIZEMENU) SizeMenu(kAv, iAuth);
                } else if (sMenuType == POSMENU) {
                    if (sMessage == UPMENU) {
                        DoMenu(kAv, iAuth); //llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
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
                    } else llMessageLinked(LINK_SET,NOTIFY,"0"+"Sorry, position can only be adjusted while worn",kID);
                    PosMenu(kAv, iAuth);
                } else if (sMenuType == ROTMENU) {
                    if (sMessage == UPMENU) {
                        DoMenu(kAv, iAuth); //llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                        return;
                    } else if (llGetAttached()) {
                        if (sMessage == "tilt right ↘") AdjustRot(<g_fRotNudge, 0, 0>);
                        else if (sMessage == "tilt up ↻") AdjustRot(<0, g_fRotNudge, 0>);
                        else if (sMessage == "left ↶") AdjustRot(<0, 0, g_fRotNudge>);
                        else if (sMessage == "right ↷") AdjustRot(<0, 0, -g_fRotNudge>);
                        else if (sMessage == "tilt left ↙") AdjustRot(<-g_fRotNudge, 0, 0>);
                        else if (sMessage == "tilt down ↺") AdjustRot(<0, -g_fRotNudge, 0>);
                    } else llMessageLinked(LINK_SET,NOTIFY,"0"+"Sorry, position can only be adjusted while worn",kID);
                    RotMenu(kAv, iAuth);
                } else if (sMenuType == SIZEMENU) {
                    if (sMessage == UPMENU) {
                        DoMenu(kAv, iAuth); //llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                        return;
                    } else {
                        integer iMenuCommand = llListFindList(SIZEMENU_BUTTONS, [sMessage]);
                        if (iMenuCommand != -1) {
                            integer iSizeFactor = llList2Integer(g_lSizeFactors, iMenuCommand);
                            if (iSizeFactor == -1000) {
                                if (g_iScaleFactor == 100)
                                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Resizing canceled; the %DEVICETYPE% is already at original size.",kID);
                                else Scale(100, TRUE, kAv);
                            }
                            else Scale(g_iScaleFactor + iSizeFactor, FALSE, kAv);
                        }
                        SizeMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "rmresizer") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_SET, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_SET,NOTIFY, "1"+"Resizer has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_SET,NOTIFY, "0"+"Resizer remains installed.", kAv);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
            }
        }
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
         else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            // The rest of this command can be access by <prefix> debug
            llInstantMessage(kID, llGetScriptName()+" SIZED BY SCRIPT: "+(string)g_iSizedByScript);
            llInstantMessage(kID, llGetScriptName()+" SIZE FACTOR: "+(string)g_iScaleFactor);
        }
    }

    timer() {
        // the timer is needed as the changed_size even is triggered twice
        llSetTimerEvent(0);
        if (g_iSizedByScript) g_iSizedByScript = FALSE;
    }

    changed(integer iChange) {
        if (iChange & (CHANGED_SCALE)) {
            if (g_iSizedByScript) llSetTimerEvent(0.5);
            else Store_StartScale();
        }
        if (iChange & (CHANGED_SHAPE | CHANGED_LINK)) Store_StartScale();
    }
}
