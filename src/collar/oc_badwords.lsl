////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - badwords                              //
//                                 version 3.990                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//MESSAGE MAP
integer COMMAND_OWNER = 500;
integer COMMAND_EVERYONE = 504;
integer COMMAND_SAFEWORD = 510;  // new for safeword

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer ANIM_START = 7000;
integer ANIM_STOP = 7001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//5000 block is reserved for IM slaves
string CTYPE = "collar";
string WEARERNAME;

string g_sNoSound = "silent" ;
string g_sBadWordSound;

string g_sBadWordAnim ;

list g_lBadWords;
string g_sPenance = "I didn't do it!";
integer g_iListenerHandle;

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride=3;
integer g_iIsEnabled=0;

integer g_iHasSworn = FALSE;

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
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
    
    //Debug("Made "+sName+" menu.");
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
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
    string sName = llKey2Name(g_kWearer);
    string sPrompt = sName + " is forbidden from saying ";
    integer iLength = llGetListLength(g_lBadWords);
    if (!iLength) sPrompt = sName + " is not forbidden from saying anything.";
    else if (iLength == 1) sPrompt += llList2String(g_lBadWords, 0);
    else if (iLength == 2) sPrompt += llList2String(g_lBadWords, 0) + " or " + llList2String(g_lBadWords, 1);
    else sPrompt += llDumpList2String(llDeleteSubList(g_lBadWords, -1, -1), ", ") + ", or " + llList2String(g_lBadWords, -1);

    sPrompt += "\nThe penance phrase to clear the punishment anim is '" + g_sPenance + "'.";
    return sPrompt;
}

MenuBadwords(key kID, integer iNum){
    list lButtons = ["Penance", "Add", "Remove", "Animation", "Sound", "Clear"];
    if (g_iIsEnabled) lButtons += ["OFF"];
    else lButtons += ["ON"];
    
    string sText="\n\nwww.opencollar.at/badwords\n\n";
    sText+="\nBad Words: " + llDumpList2String(g_lBadWords, ", ");
    sText+="\nBad Word Anim: " + g_sBadWordAnim;
    sText+="\nPenance: " + g_sPenance;
    sText+="\nBad Word Sound: " + g_sBadWordSound;
     
    Dialog(kID, sText, lButtons, ["BACK"],0, iNum, "BadwordsMenu");
}

// returns TRUE if eligible (AUTHED link message number)
UserCommand(integer iNum, string sStr, key kID, integer remenu) { // here iNum: auth value, sStr: user command, kID: avatar id 
    if (iNum != COMMAND_OWNER && kID != g_kWearer) return;
    //Debug("Got command:"+sStr);
    sStr=llStringTrim(sStr,STRING_TRIM);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    if (llToLower(sStr) == "badwords" || llToLower(sStr) == "menu badwords") {
        MenuBadwords(kID, iNum);
    } else if (llToLower(sCommand)=="badwords"){
        if (iNum != COMMAND_OWNER) return;
        sCommand = llToLower(llList2String(lParams, 1));
        if (sCommand == "add") {  //support owner adding words
            list lNewBadWords = llDeleteSubList(lParams, 0, 1);
            if (llGetListLength(lNewBadWords)){
                while (llGetListLength(lNewBadWords)){
                    string sNewWord=llToLower(DePunctuate(llList2String(lNewBadWords,-1)));
                    if (llListFindList(g_lBadWords, [sNewWord]) == -1) g_lBadWords += [sNewWord];
                    lNewBadWords=llDeleteSubList(lNewBadWords,-1,-1);
                }
                if (llGetListLength(g_lBadWords)) {
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "badwords_words=" + llDumpList2String(g_lBadWords, ","), "");
                    Notify(kID, WordPrompt(),TRUE);
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
                if(sName == "Default") sName = "~shock";
                if (llGetInventoryType(sName) == INVENTORY_ANIMATION) {
                    g_sBadWordAnim = sName;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "badwords_animation=" + g_sBadWordAnim, "");
                    Notify(kID, "Punishment animation for bad words is now '" + g_sBadWordAnim + "'.",FALSE);
                } else Notify(kID, sName + " is not a valid animation name.",FALSE);
                if (remenu) MenuBadwords(kID,iNum);
            } else {
                list lPoseList = ["Default"];
                integer iMax = llGetInventoryNumber(INVENTORY_ANIMATION);
                integer i;
                string sName;
                for (i=0;i<iMax;i++)
                {
                    sName=llGetInventoryName(INVENTORY_ANIMATION, i);
                    //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
                    if (sName != "" && llGetSubString(sName, 0, 0) != "~") lPoseList+=sName;
                }    
                string sText = "Current punishment animation is: "+g_sBadWordAnim+"\n\n";
                sText += "Select a new animation to use as a punishment.\n\n";
                Dialog(kID, sText, lPoseList, ["BACK"],0, iNum, "BadwordsAnimation");
            }
        } else if (sCommand == "sound") {  //Get all text after the command, strip spaces from start and end
            if (llGetListLength(lParams)>2){
                integer iPos=llSubStringIndex(llToLower(sStr),"nd");
                string sName = llStringTrim(llGetSubString(sStr, iPos+2, -1),STRING_TRIM);
                if (sName == "silent") Notify(kID, "Punishment will be silent.",FALSE);
                else if (llGetInventoryType(sName) == INVENTORY_SOUND) {
                    Notify(kID, "You will hear the sound "+sName+" when "+WEARERNAME+" is punished.",FALSE);
                } else {
                    Notify(kID, "Can't find sound "+sName+", using default.",FALSE);
                    sName = "Default" ;
                }
                g_sBadWordSound = sName;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "badwords_sound=" + g_sBadWordSound, "");
                if (remenu) MenuBadwords(kID,iNum);
            } else {
                list lSoundList = ["Default","silent"];
                integer iMax = llGetInventoryNumber(INVENTORY_SOUND);
                integer i;
                string sName;
                for (i=0;i<iMax;i++)
                {
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
                g_sPenance = llStringTrim(llGetSubString(sStr, iPos+2, -1),STRING_TRIM);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "badwords_penance=" + g_sPenance, "");
                Notify(kID, WordPrompt() ,TRUE);
                if (remenu) MenuBadwords(kID,iNum);
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
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "badwords_words=" + llDumpList2String(g_lBadWords, ","), "");
                Notify(kID, WordPrompt(),TRUE);
                if (remenu) MenuBadwords(kID,iNum);
            } else {
                if (g_lBadWords) Dialog(kID, "Select a badword to remove or clear them all.", g_lBadWords, ["Clear", "BACK"],0, iNum, "BadwordsRemove");
                else {
                    Notify(kID, "The list of badwords is currently empty.", FALSE);
                    MenuBadwords(kID,iNum);
                }
            }
        } else if (sCommand == "on") {
            g_iIsEnabled = 1;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "badwords_on=1", "");
            Notify(kID, "Use of bad words will now be punished.",FALSE);
            if (remenu) MenuBadwords(kID,iNum);
        } else if(sCommand == "off") {
            g_iIsEnabled = 0;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "badwords_on","");
            Notify(kID, "Use of bad words will not be punished.",FALSE);
            if (remenu) MenuBadwords(kID,iNum);
        } else if(sCommand == "clear") {
            g_lBadWords = [];
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "badwords_words","");
            Notify(kID, "The list of bad words has been cleared.",FALSE);
            if (remenu) MenuBadwords(kID,iNum);
        }
        
        ListenControl();
    }
}
 
 
default {
    on_rez(integer iParam) {
        ListenControl();
    }

    state_entry() {
        llSetMemoryLimit(36*1024);
        g_kWearer = llGetOwner();
        g_sBadWordAnim = "~shock" ;
        g_sBadWordSound = "Default" ;
        WEARERNAME = llKey2Name(g_kWearer);  //quick and dirty default, will get replaced by value from settings
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        //Debug("Got message:"+(string)iNum+" "+sStr);
        if (iNum <= COMMAND_EVERYONE && iNum >= COMMAND_OWNER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == MENUNAME_REQUEST && sStr == "Apps") llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Apps|Badwords", "");
        else if (iNum == COMMAND_SAFEWORD)
        {
            //stop sound and animation
            if(g_sBadWordSound != g_sNoSound) llStopSound();
            llMessageLinked(LINK_SET, ANIM_STOP, g_sBadWordAnim, "");
            g_iHasSworn = FALSE;
            //disable
            g_iIsEnabled = 0;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "badwords_on","");
            //clear badwords
            g_lBadWords = [];
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "badwords_words","");
        }
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == "badwords_") {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "on") g_iIsEnabled = (integer)sValue;
                else if (sToken == "animation") g_sBadWordAnim = sValue;
                else if (sToken == "sound") g_sBadWordSound = sValue;
                else if (sToken == "words") g_lBadWords = llParseString2List(llToLower(sValue), [","], []);
                else if (sToken == "penance") g_sPenance = sValue;
                ListenControl();
            } else if (sToken == "Global_CType") CTYPE = sValue;
            else if (sToken == "Global_WearerName") WEARERNAME = sValue;
        } 
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
               
                //remove stride from g_lMenuIDs
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                if (sMenu=="BadwordsMenu") {
                    if (sMessage == "BACK") llMessageLinked(LINK_SET, iAuth, "menu apps", kAv);
                    else UserCommand(iAuth, "badwords "+sMessage, kAv, TRUE);
                } else if (sMenu=="BadwordsAdd") {
                    if (sMessage) UserCommand(iAuth, "badwords add " + sMessage, kAv, TRUE);
                    else MenuBadwords(kID,iNum);
                } else if (sMenu=="BadwordsRemove") {
                    if (sMessage == "BACK") MenuBadwords(kID,iNum);
                    else if (sMessage == "Clear") UserCommand(iAuth, "badwords clear", kAv, TRUE);
                    else if (sMessage) UserCommand(iAuth, "badwords remove " + sMessage, kAv, TRUE);
                    else MenuBadwords(kID,iNum);
                } else if (sMenu=="BadwordsAnimation") {
                    if (sMessage == "BACK") MenuBadwords(kID,iNum);
                    else UserCommand(iAuth, "badwords animation " + sMessage, kAv, TRUE);
                } else if (sMenu=="BadwordsSound") {
                    if (sMessage == "BACK") MenuBadwords(kID,iNum);
                    else UserCommand(iAuth, "badwords sound " + sMessage, kAv, TRUE);
                } else if (sMenu=="BadwordsPenance") {
                    if (sMessage) UserCommand(iAuth, "badwords penance " + sMessage, kAv, TRUE);
                    else  MenuBadwords(kID,iNum);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        //release anim if penance & play anim if swear
        if ((~(integer)llSubStringIndex(llToLower(sMessage), llToLower(g_sPenance))) && g_iHasSworn ) {   //stop sound
            if(g_sBadWordSound != g_sNoSound) llStopSound();
            //stop anim
            llMessageLinked(LINK_SET, ANIM_STOP, g_sBadWordAnim, "");
            Notify(g_kWearer, "Penance accepted.",FALSE);
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
                    //start sound
                    if(g_sBadWordSound != g_sNoSound) {
                        if(g_sBadWordSound == "Default") llLoopSound( "4546cdc8-8682-6763-7d52-2c1e67e8257d", 1.0 );
                        else llLoopSound( g_sBadWordSound, 1.0 );
                    }
                    //start anim
                    llMessageLinked(LINK_SET, ANIM_START, g_sBadWordAnim, "");
                    llWhisper(0, WEARERNAME + " has said a bad word and is being punished.");
                    g_iHasSworn = TRUE;
                }
                lWords=llDeleteSubList(lWords,-1,-1);
            }
        }
    }
    
/*
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/

}
