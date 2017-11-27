//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                          Badwords - 161029.1                             //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Lulu Pink, Nandana Singh, Garvin Twine,       //
//  Cleo Collins, Satomi Ahn, Joy Stipe, Wendy Starfall, Romka Swallowtail, //
//  littlemousy, Karo Weirsider, Nori Ovis, Ray Zopf et al.                 //
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
//       github.com/VirtualDisgrace/opencollar/tree/master/src/spares       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

string g_sAppVersion = "¹⋅³";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;
integer APPOVERRIDE = 777;
integer NOTIFY = 1002;
integer SAY = 1004;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
//integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_ANIM = 6;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

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

string g_sParentMenu = "Apps";
string g_sSubMenu = "Badwords";

string g_sNoSound = "silent" ;
string g_sBadWordSound;

string g_sBadWordAnim ;

list g_lBadWords;
list g_lAnims;
integer g_iDefaultAnim;
string g_sPenance = "I didn't do it!";
integer g_iListenerHandle;

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride=3;
integer g_iIsEnabled=0;

integer g_iHasSworn = FALSE;

string g_sSettingToken = "badwords_";
//string g_sGlobalToken = "global_";

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

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
    //Debug("Made "+sName+" menu.");
}


ListenControl() {
    if(g_iIsEnabled && llGetListLength(g_lBadWords)) g_iListenerHandle = llListen(0, "", g_kWearer, "");
    else llListenRemove(g_iListenerHandle);
}

string DePunctuate(string sStr) {
    string sLastChar = llGetSubString(sStr, -1, -1);
    if (sLastChar == "," || sLastChar == "." || sLastChar == "!" || sLastChar == "?") sStr = llGetSubString(sStr, 0, -2);
    return sStr;
}

string WordPrompt() {
    string sPrompt = "%WEARERNAME% is forbidden from saying ";
    integer iLength = llGetListLength(g_lBadWords);
    if (!iLength) sPrompt = "%WEARERNAME% is not forbidden from saying anything.";
    else if (iLength == 1) sPrompt += llList2String(g_lBadWords, 0);
    else if (iLength == 2) sPrompt += llList2String(g_lBadWords, 0) + " or " + llList2String(g_lBadWords, 1);
    else sPrompt += llDumpList2String(llDeleteSubList(g_lBadWords, -1, -1), ", ") + ", or " + llList2String(g_lBadWords, -1);

    sPrompt += "\nThe penance phrase to clear the punishment anim is '" + g_sPenance + "'.";
    return sPrompt;
}

MenuBadwords(key kID, integer iNum){
    list lButtons = ["Add", "Remove", "Clear", "Penance", "Animation", "Sound"];
    if (g_iIsEnabled) lButtons += "OFF";
    else lButtons += "ON";
    lButtons += "Stop";
    string sText= "\n[http://www.opencollar.at/badwords.html Legacy Badwords]\t"+g_sAppVersion+"\n";
    sText+= "\n" + llList2CSV(g_lBadWords) + "\n";
    sText+= "\nPenance: " + g_sPenance;
    Dialog(kID, sText, lButtons, ["BACK"],0, iNum, "BadwordsMenu");
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

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_badwords")
        llRemoveInventory(sName);
}

UserCommand(integer iNum, string sStr, key kID, integer remenu) { // here iNum: auth value, sStr: user command, kID: avatar id
    //Debug("Got command:"+sStr);
    sStr=llStringTrim(sStr,STRING_TRIM);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    if (llToLower(sStr) == "badwords" || llToLower(sStr) == "menu badwords") {
        MenuBadwords(kID, iNum);
    } else if (sStr == "rm badwords") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else Dialog(kID, "\nDo you really want to uninstall the "+g_sSubMenu+" App?", ["Yes","No", "Cancel"], [], 0, iNum,"rmbadwords");
    } else if (llToLower(sCommand)=="badwords"){
        if (iNum != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            return;
        }
        sCommand = llToLower(llList2String(lParams, 1));
        if (sCommand == "add") {  //support owner adding words
            list lNewBadWords = llDeleteSubList(lParams, 0, 1);
            if (llGetListLength(lNewBadWords)){
                while (llGetListLength(lNewBadWords)){
                    string sNewWord=llToLower(DePunctuate(llList2String(lNewBadWords,-1)));
                    if (remenu) {
                        string sCRLF= llUnescapeURL("%0A");
                        if (~llSubStringIndex(sNewWord, sCRLF)) {
                            list lTemp = llParseString2List(sNewWord, [sCRLF], []);
                            lNewBadWords = llDeleteSubList(lNewBadWords,-1,-1);
                            lNewBadWords = lTemp + lNewBadWords;
                            sNewWord=llToLower(DePunctuate(llList2String(lNewBadWords,-1)));
                        }
                    }
                    if (~llSubStringIndex(g_sPenance, sNewWord))
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\"" + sNewWord + "\" is part of the Penance phrase and cannot be a badword!", kID);
                    else if (llListFindList(g_lBadWords, [sNewWord]) == -1) g_lBadWords += [sNewWord];
                    lNewBadWords=llDeleteSubList(lNewBadWords,-1,-1);
                }
                if (llGetListLength(g_lBadWords)) {
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"words=" + llDumpList2String(g_lBadWords, ","), "");
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+WordPrompt(),kID);
                }
                if (remenu) MenuBadwords(kID,iNum);
            } else {
                string sText = "\n- Submit the new badword in the field below.\n- Submit a blank field to go back.";
                Dialog(kID, sText, [], [], 0, iNum, "BadwordsAdd");
            }
        } else if (sCommand == "animation") {  //Get all text after the command, strip spaces from start and end
            if (llGetListLength(lParams)>2){
                integer iPos=llSubStringIndex(llToLower(sStr),"on");
                string sName = llStringTrim(llGetSubString(sStr, iPos+2, -1),STRING_TRIM);
                if(sName == "Default") {
                    if (g_iDefaultAnim) sName = "~shock";
                    else sName = llList2String(g_lAnims,0);
                }
                if (~llListFindList(g_lAnims,[sName]) || g_iDefaultAnim) {
                    g_sBadWordAnim = sName;
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"animation=" + g_sBadWordAnim, "");
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Punishment animation for bad words is now '" + g_sBadWordAnim + "'.",kID);
                } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+" is not a valid animation name.",kID);
                if (remenu) MenuBadwords(kID,iNum);
            } else {
                list lPoseList = g_lAnims;
                if (g_iDefaultAnim) lPoseList = ["Default"] + lPoseList;
                string sText = "Current punishment animation is: "+g_sBadWordAnim+"\n\n";
                sText += "Select a new animation to use as a punishment.\n\n";
                Dialog(kID, sText, lPoseList, ["BACK"],0, iNum, "BadwordsAnimation");
            }
        } else if (sCommand == "sound") {  //Get all text after the command, strip spaces from start and end
            if (llGetListLength(lParams)>2){
                integer iPos=llSubStringIndex(llToLower(sStr),"nd");
                string sName = llStringTrim(llGetSubString(sStr, iPos+2, -1),STRING_TRIM);
                if (sName == "silent") llMessageLinked(LINK_DIALOG,NOTIFY,"0"+ "Punishment will be silent.",kID);
                else if (llGetInventoryType(sName) == INVENTORY_SOUND)
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You will hear the sound "+sName+" when %WEARERNAME% is punished.",kID);
                else {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Can't find sound "+sName+", using default.",kID);
                    sName = "Default" ;
                }
                g_sBadWordSound = sName;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"sound=" + g_sBadWordSound, "");
                if (remenu) MenuBadwords(kID,iNum);
            } else {
                list lSoundList = ["Default","silent"];
                integer iMax = llGetInventoryNumber(INVENTORY_SOUND);
                integer i;
                string sName;
                for (i=0;i<iMax;i++) {
                    sName=llGetInventoryName(INVENTORY_SOUND, i);
            //check here if the sound start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
                    if (sName != "" && llGetSubString(sName, 0, 0) != "~") lSoundList+=[sName];
                }
                string sText = "Current sound is: "+g_sBadWordSound+"\n\n";
                sText += "Select a new sound to use.\n\n";
                Dialog(kID, sText, lSoundList, ["BACK"],0, iNum, "BadwordsSound");
            }
        } else if (sCommand == "penance") {
            if (llGetListLength(lParams)>2){
                integer iPos=llSubStringIndex(llToLower(sStr),"ce");
                string sPenance = llStringTrim(llGetSubString(sStr, iPos+2, -1),STRING_TRIM);
                integer i;
                list lTemp;
                string sCheckWord;
                for (i=0;i<llGetListLength(g_lBadWords); i++) {
                    sCheckWord = llList2String(g_lBadWords,i);
                     if (~llSubStringIndex(sPenance,sCheckWord)) {
                         lTemp += [sCheckWord];
                    }
                }
                if (llGetListLength(lTemp)) {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You cannot have badwords in the Penance phrase, please try again without these word(s):\n"+llList2CSV(lTemp),kID);
                } else {
                    g_sPenance = sPenance;
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"penance=" + g_sPenance, "");
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+WordPrompt() ,kID);
                    if (remenu) MenuBadwords(kID,iNum);
                }
            } else {
                string sText = "\n- Submit the new penance in the field below.\n- Submit a blank field to go back.";
                sText += "\n\n- Current penance is: " + g_sPenance;
                Dialog(kID, sText, [], [],0, iNum, "BadwordsPenance");
            }
        } else if (sCommand == "remove") {
            list lNewBadWords = llDeleteSubList(lParams, 0, 1);
            if (llGetListLength(lNewBadWords)){
                while (llGetListLength(lNewBadWords)){
                    string sNewWord=llToLower(DePunctuate(llList2String(lNewBadWords,-1)));
                    integer iIndex=llListFindList(g_lBadWords, [sNewWord]);
                    if (~iIndex) g_lBadWords = llDeleteSubList(g_lBadWords,iIndex,iIndex);
                    lNewBadWords=llDeleteSubList(lNewBadWords,-1,-1);
                }
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"words=" + llDumpList2String(g_lBadWords, ","), "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+WordPrompt() ,kID);
                if (remenu) MenuBadwords(kID,iNum);
            } else {
                if (g_lBadWords) Dialog(kID, "Select a badword to remove or clear them all.", g_lBadWords, ["Clear", "BACK"],0, iNum, "BadwordsRemove");
                else {
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The list of badwords is currently empty.",kID);
                    MenuBadwords(kID,iNum);
                }
            }
        } else if (sCommand == "on") {
            g_iIsEnabled = 1;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"on=1", "");
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Use of bad words will now be punished.",kID);
            llMessageLinked(LINK_THIS, APPOVERRIDE, g_sSubMenu, "on");
            if (remenu) MenuBadwords(kID,iNum);
        } else if(sCommand == "off") {
            g_iIsEnabled = 0;
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"on","");
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Use of bad words will not be punished.",kID);
            llMessageLinked(LINK_THIS, APPOVERRIDE, g_sSubMenu, "off");
            if (remenu) MenuBadwords(kID,iNum);
        } else if(sCommand == "clear") {
            g_lBadWords = [];
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"words","");
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"The list of bad words has been cleared.",kID);
            if (remenu) MenuBadwords(kID,iNum);
        } else if (sCommand == "stop") {
            if (g_iHasSworn) {
                if(g_sBadWordSound != g_sNoSound) llStopSound();
                llMessageLinked(LINK_ANIM, ANIM_STOP, g_sBadWordAnim, "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Badword punishment stopped.",kID);
                g_iHasSworn = FALSE;
            }
            if (remenu) MenuBadwords(kID,iNum);
        }
        ListenControl();
    }
}


default {
    on_rez(integer iParam) {
        //ListenControl();
    }

    state_entry() {
        //llSetMemoryLimit(40960);
        g_kWearer = llGetOwner();
        FailSafe();
        g_sBadWordAnim = "~shock";
        g_sBadWordSound = "Default" ;
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //Debug("Got message:"+(string)iNum+" "+sStr);
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+g_sSubMenu, "");
            //llMessageLinked(LINK_ANIM, ANIM_LIST_REQUEST,"","");
        } else if (iNum == ANIM_LIST_RESPONSE) ParseAnimList(sStr);
        else if (iNum == CMD_SAFEWORD) {
            if(g_sBadWordSound != g_sNoSound) llStopSound();
            llMessageLinked(LINK_ANIM, ANIM_STOP, g_sBadWordAnim, "");
            g_iHasSworn = FALSE;
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "on") g_iIsEnabled = (integer)sValue;
                else if (sToken == "animation") g_sBadWordAnim = sValue;
                else if (sToken == "sound") g_sBadWordSound = sValue;
                else if (sToken == "words") g_lBadWords = llParseString2List(llToLower(sValue), [","], []);
                else if (sToken == "penance") g_sPenance = sValue;
            }
            if (sStr == "settings=sent") {
                ListenControl();
                llMessageLinked(LINK_ANIM, ANIM_LIST_REQUEST,"","");
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu=="BadwordsMenu") {
                    if (sMessage == "BACK") llMessageLinked(LINK_ROOT, iAuth, "menu apps", kAv);
                    else UserCommand(iAuth, "badwords "+sMessage, kAv, TRUE);
                } else if (sMenu=="BadwordsAdd") {
                    if (sMessage != " ") UserCommand(iAuth, "badwords add " + sMessage, kAv, TRUE);
                    else MenuBadwords(kAv,iAuth);
                } else if (sMenu=="BadwordsRemove") {
                    if (sMessage == "BACK") MenuBadwords(kAv,iAuth);
                    else if (sMessage == "Clear") UserCommand(iAuth, "badwords clear", kAv, TRUE);
                    else if (sMessage) UserCommand(iAuth, "badwords remove " + sMessage, kAv, TRUE);
                    else MenuBadwords(kAv,iAuth);
                } else if (sMenu=="BadwordsAnimation") {
                    if (sMessage == "BACK") MenuBadwords(kAv,iAuth);
                    else UserCommand(iAuth, "badwords animation " + sMessage, kAv, TRUE);
                } else if (sMenu=="BadwordsSound") {
                    if (sMessage == "BACK") MenuBadwords(kAv,iAuth);
                    else UserCommand(iAuth, "badwords sound " + sMessage, kAv, TRUE);
                } else if (sMenu=="BadwordsPenance") {
                    if (sMessage) UserCommand(iAuth, "badwords penance " + sMessage, kAv, TRUE);
                    else  MenuBadwords(kAv,iAuth);
                } else if (sMenu == "rmbadwords") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu+"|"+g_sSubMenu, "");
                        llMessageLinked(LINK_THIS, APPOVERRIDE, g_sSubMenu, "off");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
            else if (sStr == "LINK_ANIM") LINK_ANIM = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        //release anim if penance & play anim if swear
        if ((~(integer)llSubStringIndex(llToLower(sMessage), llToLower(g_sPenance))) && g_iHasSworn ) {   //stop sound
            if(g_sBadWordSound != g_sNoSound) llStopSound();
            //stop anim
            llMessageLinked(LINK_ANIM, ANIM_STOP, g_sBadWordAnim, "");
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Penance accepted.",g_kWearer);
            g_iHasSworn = FALSE;
        }
        else if (~llSubStringIndex(sMessage, "rembadword")) return; //subs could theoretically circumvent this feature by sticking "rembadowrd" in all chat, but it doesn't seem likely to happen often
        else { //check for swear
            sMessage = llToLower(sMessage);
            list lWords = llParseString2List(sMessage, [" "], []);
            while (llGetListLength(lWords)) {
                string sWord = llList2String(lWords, -1);
                sWord = DePunctuate(sWord);

                if (llListFindList(g_lBadWords, [sWord]) != -1) {
                    if(g_sBadWordSound != g_sNoSound) {
                        if(g_sBadWordSound == "Default") llLoopSound( "4546cdc8-8682-6763-7d52-2c1e67e8257d", 1.0 );
                        else llLoopSound( g_sBadWordSound, 1.0 );
                    }
                    llMessageLinked(LINK_ANIM, ANIM_START, g_sBadWordAnim, "");
                    llMessageLinked(LINK_DIALOG,SAY,"1"+"%WEARERNAME% has said a bad word and is being punished.","");
                    g_iHasSworn = TRUE;
                }
                lWords=llDeleteSubList(lWords,-1,-1);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) FailSafe();
        /*if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }
}
