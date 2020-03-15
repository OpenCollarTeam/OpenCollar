// This file is part of OpenCollar.
//  Copyright (c) 2014 - 2015 Romka Swallowtail                             
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sAppVersion = "¹⁶¹⁰¹³⋅¹";

string g_sSubMenu = "Shocker";
string g_sParentMenu = "Apps";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_SAFEWORD = 510;  // new for safeword

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;
integer SAY = 1004;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer ANIM_START = 7000;
integer ANIM_STOP = 7001;
integer ANIM_LIST_REQUEST = 7002;
integer ANIM_LIST_RESPONSE = 7003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

// menu buttons
string UPMENU = "BACK";
string HELP = "Quick Help";
string DEFAULT = "Default" ;

list g_lButtons = ["1 sec.","3 sec.","5 sec.","10 sec.","15 sec.","30 sec.","1 min.","Stop"];
list g_lTime = [1,3,5,10,15,30,60,0];

string g_sSetAnim = "Set Anim";
string g_sSetSound = "Set Sound";

string g_sDefaultAnim = "~shock";
//string g_sDefaultSound = "011ef7f4-40e8-28fe-4ea5-f2fda0883707";
string g_sDefaultSound = "4546cdc8-8682-6763-7d52-2c1e67e8257d";
string g_sNoSound = "silent" ;

string g_sShockAnim ;
string g_sShockSound;

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride=3;

integer g_iShock = FALSE ;

list g_lAnims ;
integer g_iDefaultAnim = FALSE;

/*
integer g_iProfiled;
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

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
    //Debug("Made "+sName+" menu.");
}

DialogShocker(key kID, integer iAuth) {
    string sText = "\nShocker!\t"+g_sAppVersion+"\n\nYour pet is naughty? Just punish him/her.\n";
    sText += "- Chose time to start punishment.\n" ;
    sText += "- 'Quick Help' will give you a brief help how to use shocker.\n";
    Dialog(kID, sText, g_lButtons, [HELP,g_sSetAnim, g_sSetSound,UPMENU],0,iAuth,"shocker");
}

DialogSelectAnim(key kID, integer iAuth) {
    list lAnims ;
    if (g_iDefaultAnim) lAnims = [DEFAULT];
    lAnims += g_lAnims;
    string sText = "\nCurrent punishment animation is: "+g_sShockAnim+"\n\n";
    sText += "Chose new animation to use as a punishment:\n";
    Dialog(kID, sText, lAnims, [UPMENU],0, iAuth,"anim");
}

DialogSelectSound(key kID, integer iAuth) {
    list lSoundList = [DEFAULT];
    integer iMax = llGetInventoryNumber(INVENTORY_SOUND);
    integer i;
    string sName;
    for (i = 0; i < iMax; i++) {
        sName = llGetInventoryName(INVENTORY_SOUND, i);
        //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
        if (sName != "" && llGetSubString(sName, 0, 0) != "~") lSoundList += [sName];
    }
    lSoundList+=[g_sNoSound];
    string sText = "\nCurrent sound is: "+g_sShockSound+"\n\n";
    sText += "Chose new sound to use:\n";
    Dialog(kID, sText, lSoundList, [UPMENU],0, iAuth,"sound");
}

DialogHelp(key kID) {
    string sMsg = "Shocker chat commands:\n\n";
    sMsg += "%PREFIX% shocker <seconds>\n     where <seconds> is time in seconds to punish you pet.\n\n";
    sMsg += "%PREFIX% shocker 0/stop/off\n     is stop to punish you pet immediately.\n\n";
    sMsg += "%PREFIX% shocker animation <anim name> \n    make sure the animation is inside the %DEVICETYPE%.\n\n";
    sMsg += "%PREFIX% shocker sound <sound name>\n    make sure the sound is inside the %DEVICETYPE%.\n";

    //Dialog(kID, sMsg, ["Ok"], [], 0, iAuth,"help");
    llMessageLinked(LINK_THIS, NOTIFY, "0"+sMsg, kID);
}

Shock(integer time) {
    if (time > 0) {
        //llMessageLinked(LINK_THIS, NOTIFY, "1"+"%WEARERNAME% now shocked for "+(string)time+" seconds.", kID);
        llMessageLinked(LINK_THIS, SAY, "1"+"%WEARERNAME% now shocked for "+(string)time+" seconds.","");
        if (g_sShockSound != g_sNoSound) {
            if (g_sShockSound == DEFAULT) llLoopSound( g_sDefaultSound, 1.0 );
            else llLoopSound(g_sShockSound, 1.0);
        }
        g_iShock = TRUE ;
        if (g_sShockAnim == DEFAULT) llMessageLinked(LINK_THIS, ANIM_START, g_sDefaultAnim, "");
        else llMessageLinked(LINK_THIS, ANIM_START, g_sShockAnim, "");
        llResetTime();
        llSetTimerEvent(time);
    } else if (g_iShock == TRUE) {
        //llMessageLinked(LINK_THIS, NOTIFY, "1"+"shocker off.", kID);
        llMessageLinked(LINK_THIS, SAY, "1"+"shocker off.", "");
        llSetTimerEvent(0);
        Stop();
    }
}

Stop() {
    if (g_iShock) {
        if (g_sShockSound != g_sNoSound) llStopSound();
        if (g_sShockAnim == DEFAULT) llMessageLinked(LINK_THIS, ANIM_STOP, g_sDefaultAnim, "");
        else llMessageLinked(LINK_THIS, ANIM_STOP, g_sShockAnim, "");
        g_iShock = FALSE ;
    }
}


UserCommand(integer iAuth, string sStr, key kID, integer remenu) {
    if (iAuth > CMD_WEARER || iAuth < CMD_OWNER) return; // sanity check

    if (llToLower(sStr) == "rm shocker") {
        if (kID!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_THIS,NOTIFY,"0"+"%NOACCESS%",kID);
        else  Dialog(kID,"\nAre you sure you want to delete the "+g_sSubMenu+" App?\n", ["Yes","No","Cancel"], [], 0, iAuth,"rmshocker");
        return;
    }

    if (sStr == "menu "+g_sSubMenu || sStr == "shocker") {
        if (iAuth == CMD_OWNER) DialogShocker(kID, iAuth);
        else llMessageLinked(LINK_THIS, NOTIFY, "0"+"Sorry, only the Owner can punish pet.", kID);
    } else if (iAuth == CMD_OWNER) {
        list lParams = llParseString2List(sStr, [" "], []);
        if (llList2String(lParams,0) != "shocker") return;
        if (llGetListLength(lParams) < 2) return;

        string sCommand = llList2String(lParams, 1);
        string sValue = llList2String(lParams, 2);

        if (sCommand == "help") DialogHelp(kID);
        else if (sCommand == "animation") {
            Stop();
            string sAnim = llStringTrim(sValue, STRING_TRIM);
            if (sAnim) {
                if (~llListFindList(g_lAnims,[sAnim])) g_sShockAnim = sAnim;
                else {
                    llMessageLinked(LINK_THIS, NOTIFY,"0"+sAnim+" is not a valid animation name.",kID);
                    g_sShockAnim = DEFAULT;
                }
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "shocker_anim=" + g_sShockAnim, "");
                llMessageLinked(LINK_THIS, NOTIFY,"0"+"Punishment anim for shocker is now '"+g_sShockAnim+"'.",kID);
            } else DialogSelectAnim(kID, iAuth);
        } else if (sCommand == "sound") {
            string sSound = llStringTrim(sValue, STRING_TRIM);
            if (sSound) {
                if (sSound == g_sNoSound) llMessageLinked(LINK_THIS,NOTIFY,"0"+"Punishment will be silently.",kID);
                else if (llGetInventoryType(sSound) != INVENTORY_SOUND) {
                    llMessageLinked(LINK_THIS,NOTIFY,"0"+sSound+" is not a valid sound name.",kID);
                    sSound = DEFAULT ;
                }
                g_sShockSound = sSound;
                llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"shocker_sound="+g_sShockSound, "");
                llMessageLinked(LINK_THIS,NOTIFY,"0"+"Punishment sound for shocker is now '"+g_sShockSound+"'.",kID);
            } else DialogSelectSound(kID, iAuth);
        } else Shock((integer)sCommand);
    }
    if (remenu) DialogShocker(kID, iAuth);
}

ParseAnimList(string sStr) {
    g_lAnims = llParseString2List(sStr, ["|"],[]);
    integer i = llGetListLength(g_lAnims);
    string sTest;
    do { i--;
        sTest = llList2String(g_lAnims,i);
        if (!llSubStringIndex(sTest,"~")) {
            g_lAnims = llDeleteSubList(g_lAnims,i,i);
            if (sTest == "~shock") g_iDefaultAnim = TRUE;
        }
    } while (i>0);
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        g_kWearer = llGetOwner();
        g_sShockAnim = DEFAULT;
        g_sShockSound = DEFAULT ;
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "shocker_anim") g_sShockAnim = sValue;
            if (sToken == "shocker_sound") g_sShockSound = sValue;
        } else if (iNum == CMD_SAFEWORD) Shock(0);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            llMessageLinked(LINK_THIS, ANIM_LIST_REQUEST,"","");
        } else if (iNum == ANIM_LIST_RESPONSE) ParseAnimList(sStr);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                //remove stride from g_lMenuIDs
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenu == "shocker") {
                    if (sMsg == UPMENU) llMessageLinked(LINK_THIS, iAuth, "menu "+g_sParentMenu, kAv);
                    else if (sMsg == g_sSetAnim) DialogSelectAnim(kAv,iAuth);
                    else if (sMsg == g_sSetSound) DialogSelectSound(kAv,iAuth);
                    else if (sMsg == HELP) UserCommand(iAuth,"shocker help", kAv, TRUE);
                    else {
                        integer index = llListFindList(g_lButtons, [sMsg]);
                        if (index != -1) UserCommand(iAuth,"shocker "+(string)llList2Integer(g_lTime,index), kAv, TRUE);
                    }
                } else if (sMenu == "anim") {
                    if (sMsg != UPMENU) UserCommand(iAuth,"shocker animation " + sMsg, kAv, TRUE);
                    else UserCommand(iAuth,"shocker", kAv, FALSE);
                } else if (sMenu == "sound") {
                    if (sMsg != UPMENU) UserCommand(iAuth,"shocker sound " + sMsg, kAv, TRUE);
                    else UserCommand(iAuth,"shocker", kAv, FALSE);
                } else if (sMenu == "rmshocker") {
                    if (sMsg == "Yes") {
                        llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "shocker_anim", "");
                        llMessageLinked(LINK_THIS, LM_SETTING_DELETE, "shocker_sound", "");
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_THIS, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_THIS, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
                //else if (sMenu == "help" && sMsg == "Ok") UserCommand(iAuth,"shocker", kAv, FALSE);
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            if (~iMenuIndex) g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    timer() {
        llSetTimerEvent(0);
        Stop();
    }
}
