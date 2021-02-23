// This file is part of OpenCollar.
// Copyright (c) 2004 - 2017 Francis Chung, Ilse Mannonen, Nandana Singh,
// Cleo Collins, Satomi Ahn, Joy Stipe, Wendy Starfall, Garvin Twine,
// littlemousy, Romka Swallowtail, Sumi Perl et al.
// Licensed under the GPLv2.  See LICENSE for full details.
string g_sScriptVersion="8.0";
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

string g_sParentMenu = "Animations";
string g_sSubMenu = " Couples";
string UPMENU = "BACK";
list     g_lMenuIDs;
integer g_iMenuStride = 3;

integer g_iAnimTimeout;
integer g_iPermissionTimeout;

key g_kWearer;

//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;

//list g_lSettingsReqs = [];
string STOP_COUPLES = "STOP";
string TIME_COUPLES = "TIME";

integer g_iLine1;
integer g_iLine2;
key g_kDataID1;
key g_kDataID2;
string CARD1 = ".couples";
string CARD2 = "!couples";
integer iCardComplete;

list g_lAnimCmds;//1-strided list of strings that will trigger
list g_lAnimSettings;//4-strided list of subAnim|domAnim|offset|text, running parallel to g_lAnimCmds,
//such that g_lAnimCmds[0] corresponds to g_lAnimSettings[0:3], and g_lAnimCmds[1] corresponds to g_lAnimSettings[4:7], etc

key g_kCardID1;//used to detect whether coupleanims card has changed
key g_kCardID2;
float g_fRange = 10.0;

float g_fWalkingDistance = 1.0;
float g_fWalkingTau = 1.5;
float g_fAlignTau = 0.05;
float g_fAlignDelay = 0.6;

key g_kCmdGiver;
integer g_iCmdAuth;
integer g_iCmdIndex;
key g_kPartner;
string g_sPartnerName;
float g_fTimeOut = 20.0;
string g_sDeviceName;

integer g_iTargetID;
string g_sSubAnim;
string g_sDomAnim;
integer g_iVerbose = TRUE;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
integer SAY = 1004;
integer LOADPIN = -1904;
integer REBOOT = -1000;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;

string g_sSettingToken = "coupleanim_";
string g_sGlobalToken = "global_";
string g_sStopString = "stop";
integer g_iStopChan = 99;
integer g_iLMChannel = -8888;
integer g_iListener;    //stop listener handle

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

Dialog(key kRCPT, string sPrompt, list lButtons, list lUtilityButtons, integer iPage, integer iAuth, string sMenuID) {
    key kMenuID = llGenerateKey();
    string sSearch;
    if (sMenuID == "sensor") {
        if (lButtons) sSearch = "`"+llList2String(lButtons,0)+"`1";
        llMessageLinked(LINK_SET, SENSORDIALOG, (string)kRCPT +"|"+sPrompt+"|0|``"+(string)AGENT+"`"+(string)g_fRange+"`"+(string)PI+sSearch+"|"+llDumpList2String(lUtilityButtons, "`")+"|" + (string)iAuth, kMenuID);
    } else
        llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lButtons, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, sMenuID], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, sMenuID];
}

refreshTimer(){
    integer timeNow = llGetUnixTime();
    if (g_iAnimTimeout <= timeNow && g_iAnimTimeout > 0){
        //Debug("Anim timeout="+(string)g_iAnimTimeout+"\ntime now="+(string)timeNow);
        g_iAnimTimeout=0;
        StopAnims();
    } else if (g_iPermissionTimeout <= timeNow && g_iPermissionTimeout > 0){
        //Debug("Perm timeout="+(string)g_iPermissionTimeout+"\ntime now="+(string)timeNow);
        g_iPermissionTimeout=0;
        llListenRemove(g_iListener);
        g_kPartner = NULL_KEY;
    }
    integer nextTimeout=g_iAnimTimeout;
    if (g_iPermissionTimeout < g_iAnimTimeout && g_iPermissionTimeout > 0)
        nextTimeout = g_iPermissionTimeout;
    llSetTimerEvent(nextTimeout-timeNow);
}

CoupleAnimMenu(key kID, integer iAuth) {
    string sPrompt = "\n[Couples]\n\nChoose an animation to play.\n\nAnimations will play ";
    if(g_fTimeOut == 0) sPrompt += "ENDLESS.\n\nNOTE: The non-looped \"pet\" sequence is an exception to this rule and can only play for 20 seconds at a time." ;
    else sPrompt += "for "+(string)llCeil(g_fTimeOut)+" seconds.";
    list lButtons = g_lAnimCmds;
    lButtons += [TIME_COUPLES, STOP_COUPLES];
    Dialog(kID, sPrompt, lButtons, [UPMENU],0, iAuth,"couples");
}

string StrReplace(string sSrc, string sFrom, string sTo) {
//replaces all occurrences of 'from' with 'to' in 'sSrc'.
    integer iLength = (~-(llStringLength(sFrom)));
    if(~iLength)  {
        string  sBuffer = sSrc;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(sTo)));
        @loop;//instead of a while loop, saves 5 bytes (and run faster).
        integer to_pos = ~llSubStringIndex(sBuffer, sFrom);
        if(to_pos) {
            b_pos -= to_pos;
            sSrc = llInsertString(llDeleteSubString(sSrc, b_pos, b_pos + iLength), b_pos, sTo);
            b_pos += to_len;
            sBuffer = llGetSubString(sSrc, (-~(b_pos)), 0x8000);
            //buffer = llGetSubString(sSrc = llInsertString(llDeleteSubString(sSrc, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        }
    }
    return sSrc;
}

//added to stop eventual still going animations
StopAnims() {
    if (llGetInventoryType(g_sSubAnim) == INVENTORY_ANIMATION) llMessageLinked(LINK_SET, ANIM_STOP, g_sSubAnim, "");
    if (llGetInventoryType(g_sDomAnim) == INVENTORY_ANIMATION) {
        if (llKey2Name(g_kPartner) != "") {
            llStopAnimation(g_sDomAnim);
            llRegionSayTo(g_kPartner,g_iLMChannel,(string)g_kPartner+"booton");
        }
    }
    g_sSubAnim = "";
    g_sDomAnim = "";
}

// Calmly walk up to your partner and face them. Does not position the avatar precicely
MoveToPartner() {
    list partnerDetails = llGetObjectDetails(g_kPartner, [OBJECT_POS, OBJECT_ROT]);
    vector partnerPos = llList2Vector(partnerDetails, 0);
    rotation partnerRot = llList2Rot(partnerDetails, 1);
    vector partnerEuler = llRot2Euler(partnerRot);
    // turn to face the partner
    llMessageLinked(LINK_SET, RLV_CMD, "setrot:" + (string)(-PI_BY_TWO-partnerEuler.z) + "=force", NULL_KEY);

    g_iTargetID = llTarget(partnerPos, g_fWalkingDistance);
    llMoveToTarget(partnerPos, g_fWalkingTau);
}

GetPartnerPermission() {
    string sObjectName = llGetObjectName();
    llSetObjectName(g_sDeviceName);
    llRequestPermissions(g_kPartner, PERMISSION_TRIGGER_ANIMATION);
    llSetObjectName(sObjectName);
}

StartNotecards() {
        if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD) {  //card is present, start reading
                g_kCardID1 = llGetInventoryKey(CARD1);
                g_iLine1 = 0;
                g_lAnimCmds = [];
                g_lAnimSettings = [];
                g_kDataID1 = llGetNotecardLine(CARD1, g_iLine1);
        }
        if (llGetInventoryType(CARD2) == INVENTORY_NOTECARD) {  //card is present, start reading
                g_kCardID2 = llGetInventoryKey(CARD2);
                g_iLine2 = 0;
                g_kDataID2 = llGetNotecardLine(CARD2, g_iLine2);
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
    on_rez(integer iStart)
    {
        //added to stop anims after relog when you logged off while in an endless couple anim
        if (g_sSubAnim != "" && g_sDomAnim != "") {
             llSleep(1.0);  // wait a second to make sure the poses script reseted properly
             StopAnims();
        }
        llResetScript();
    }

    state_entry() {
        g_kWearer = llGetOwner();
                StartNotecards();
        g_sDeviceName = llList2String(llGetLinkPrimitiveParams(1,[PRIM_NAME]),0);
        //Debug("Starting");
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        //Debug("listen: " + sMessage + ", iChannel=" + (string)channel);
        llListenRemove(g_iListener);
        if (iChannel == g_iStopChan) StopAnims();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID){
        //if you don't care who gave the command, so long as they're one of the above, you can just do this instead:
        if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) {
            //the command was given by either owner, secowner, group member, wearer, or public user
            list lParams = llParseString2List(sStr, [" "], []);
            g_kCmdGiver = kID;
            g_iCmdAuth = iNum;
            string sCommand = llToLower(llList2String(lParams, 0));
            string sValue = llToLower(llList2String(lParams, 1));
            integer tmpiIndex = llListFindList(g_lAnimCmds, [sCommand]);
            if (tmpiIndex != -1) {   //if the couple anim exists
                g_iCmdIndex = tmpiIndex;
                //Debug(sCommand);
                //we got an anim command.
                if (llGetListLength(lParams) > 1) {//we've been given a name of someone to kiss.  scan for it
                    string sTmpName = llDumpList2String(llList2List(lParams, 1, -1), " ");//this makes it so we support even full names in the command
                    //g_kPart=llGenerateKey();
                    //llMessageLinked(LINK_SET, SENSORDIALOG, (string)g_kCmdGiver + "|\nChoose a partner:\n|0|``"+(string)AGENT+"`"+(string)g_fRange+"`"+(string)PI +"`"+sTmpName+"`1"+ "|BACK|" + (string)iNum, g_kPart);
                    Dialog(g_kCmdGiver, "\nChoose a partner:\n", [sTmpName], ["BACK"], 0, iNum, "sensor");
                } else {       //no name given.
                    if (kID == g_kWearer) {                   //if commander is not sub, then treat commander as partner
                        llMessageLinked(LINK_SET, NOTIFY,
                                                        "0"+"\n\nYou didn't give the name of the person you want to animate. To " + sCommand +
                                                        " Alice Mannonen, for example, you could say:\n\n /%CHANNEL% %PREFIX%" + sCommand + " ali\n", g_kWearer);
                    } else {               //else set partner to commander
                        g_kPartner = g_kCmdGiver;
                        g_sPartnerName = "secondlife:///app/agent/"+(string)g_kPartner+"/about";
                        //added to stop eventual still going animations
                        StopAnims();
                        GetPartnerPermission();
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"Offering to " + sCommand + " " + g_sPartnerName + ".",g_kWearer);
                    }
                }
            } else if (llToLower(sStr) == "stop couples") StopAnims();
            else if (llToLower(sStr) == "menu"+llToLower(g_sSubMenu) || llToLower(sStr) == "couples") CoupleAnimMenu(kID, iNum);
            else if (sCommand == "couples" && sValue == "verbose") {
                sValue = llToLower(llList2String(lParams, 2));
                if (sValue == "off"){
                    g_iVerbose = FALSE;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "verbose=" + (string)g_iVerbose, "");
                } else if (sValue == "on") {
                    g_iVerbose = TRUE;
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "verbose", "");
                }
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Verbose for couple animations is now turned "+sValue+".",kID);
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            //integer ind = llListFindList(g_lSettingsReqs, [sToken]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);

            if(sToken == g_sSettingToken + "timeout")
                g_fTimeOut = (float)sValue;
            else if (sToken == g_sSettingToken + "verbose")
                g_iVerbose = (integer)sValue;
            else if (sToken == g_sGlobalToken+"devicename")
                g_sDeviceName = sValue;
        } else if(iNum == LM_SETTING_EMPTY){

            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);

        } else if(iNum == LM_SETTING_DELETE){

            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);

        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                // integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu == "couples") {
                    if (sMessage == UPMENU)
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == STOP_COUPLES) {
                        StopAnims();
                        CoupleAnimMenu(kAv, iAuth);
                    } else if (sMessage == TIME_COUPLES) {
                        string sPrompt = "\nChoose the duration for couple animations.\n\nCurrent duration: ";
                        if(g_fTimeOut == 0) sPrompt += "ENDLESS.\n\nNOTE: The non-looped \"pet\" sequence is an exception to this rule and can only play for 20 seconds at a time." ;
                        else sPrompt += "for "+(string)llCeil(g_fTimeOut)+" seconds.";
                        Dialog(kAv, sPrompt, ["10","20","30","40","60","90","120", "ENDLESS"], [UPMENU],0, iAuth,"timer");
                    } else if (llGetSubString(sMessage,0,6) == "Verbose") {
                        if (llGetSubString(sMessage,8,-1) == "Off") {
                            g_iVerbose = FALSE;
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "verbose=" + (string)g_iVerbose, "");
                        } else {
                            g_iVerbose = TRUE;
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "verbose", "");
                        }
                        CoupleAnimMenu(kAv, iAuth);
                    } else {
                        integer iIndex = llListFindList(g_lAnimCmds, [sMessage]);
                        if (iIndex != -1) {
                            g_kCmdGiver = kAv;
                            g_iCmdAuth = iAuth;
                            g_iCmdIndex = iIndex;
                            //llSensor("", NULL_KEY, AGENT, g_fRange, PI);
                            Dialog(g_kCmdGiver, "\nChoose a partner:\n", [], ["BACK"], 0, iNum, "sensor");
                            //g_kPart=llGenerateKey();
                            //llMessageLinked(LINK_SET, SENSORDIALOG, (string)g_kCmdGiver + "|\nChoose a partner:\n|0|``"+(string)AGENT+"`"+(string)g_fRange+"`"+(string)PI + "|BACK|" + (string)iAuth, g_kPart);
                        }
                    }
                } else if (sMenu == "sensor") {
                    //Debug("Response from partner"+sStr);
                    if (sMessage == UPMENU) CoupleAnimMenu(kAv, iAuth);
                    else {
                        g_kPartner = (key)sMessage;
                        g_sPartnerName = "secondlife:///app/agent/"+(string)g_kPartner+"/about";
                        StopAnims();
                        GetPartnerPermission();
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"Inviting "+ g_sPartnerName + " to a couples animation.",g_kWearer);
                        llMessageLinked(LINK_SET,NOTIFY,"0"+"%WEARERNAME% invited you to a couples animation! Click [Yes] to accept.",g_kPartner);
                    }
                } else if (sMenu == "timer") {
                    //Debug("Response from timer menu"+sStr);
                    if (sMessage == UPMENU) CoupleAnimMenu(kAv, iAuth);
                    else if ((integer)sMessage > 0 && ((string)((integer)sMessage) == sMessage)) {
                        g_fTimeOut = (float)((integer)sMessage);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "timeout=" + (string)g_fTimeOut, "");
                        string sPet;
                        if (g_fTimeOut > 20.0)  sPet = "(except the \"pet\" sequence) ";
                        llMessageLinked(LINK_SET,NOTIFY,"1"+"Couple Anmiations "+sPet+"play now for " + (string)llRound(g_fTimeOut) + " seconds.",kAv);
                        CoupleAnimMenu(kAv, iAuth);
                    } else if (sMessage == "ENDLESS") {
                        g_fTimeOut = 0.0;
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + "timeout=0.0", "");
                        llMessageLinked(LINK_SET,NOTIFY,"1"+"Couple Anmiations (except the \"pet\" sequence) play now forever. Use the menu or type \"/%CHANNEL% %PREFIX% stop couples\" to stop them again.",kAv);
                        CoupleAnimMenu(kAv, iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == LOADPIN && sStr == llGetScriptName()) {
            integer iPin = (integer)llFrand(99999.0)+1;
            llSetRemoteScriptAccessPin(iPin);
            llMessageLinked(iSender, LOADPIN, (string)iPin+"@"+llGetScriptName(),llGetKey());
        }
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            DebugOutput(kID, [" PARTNER:", g_kPartner]);
        }
    }
    not_at_target() {
        llTargetRemove(g_iTargetID);
        MoveToPartner();
    }

    at_target(integer tiNum, vector targetpos, vector ourpos) {
        llTargetRemove(tiNum);
        llStopMoveToTarget();
        float offset = 10.0;
        if (g_iCmdIndex != -1) offset = (float)llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 2);
        list partnerDetails = llGetObjectDetails(g_kPartner, [OBJECT_POS, OBJECT_ROT]);
        vector partnerPos = llList2Vector(partnerDetails, 0);
        rotation partnerRot = llList2Rot(partnerDetails, 1);
        vector myPos = llList2Vector(llGetObjectDetails(llGetOwner(), [OBJECT_POS]), 0);

        vector target = partnerPos + (<1.0, 0.0, 0.0> * partnerRot * offset); // target is <offset> meters in front of the partner
        target.z = myPos.z; // ignore height differences
        llMoveToTarget(target, g_fAlignTau);
        llSleep(g_fAlignDelay);
        llStopMoveToTarget();
        g_sSubAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4);
        g_sDomAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 1);

        llMessageLinked(LINK_SET, ANIM_START, g_sSubAnim, "");
        llRegionSayTo(g_kPartner,g_iLMChannel,(string)g_kPartner+"bootoff");
        llStartAnimation(g_sDomAnim);
        g_iListener = llListen(g_iStopChan, "", g_kPartner, g_sStopString);
        llMessageLinked(LINK_SET,NOTIFY,"0"+"If you would like to stop the animation early, say /" + (string)g_iStopChan + g_sStopString + " to stop.",g_kPartner);

        string sText = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 3);
        if (sText != "" && g_iVerbose) {
            sText = StrReplace(sText,"_PARTNER_",g_sPartnerName);
            sText = StrReplace(sText,"_SELF_","%WEARERNAME%");
            llMessageLinked(LINK_SET,SAY,"0"+sText,"");
        }
        if (g_fTimeOut > 0.0) {
            g_iAnimTimeout=llGetUnixTime()+(integer)g_fTimeOut;
            if (g_sSubAnim == "~good" && g_fTimeOut > 20.0) g_iAnimTimeout = llGetUnixTime()+20;
        } else if (g_sSubAnim == "~good") g_iAnimTimeout = llGetUnixTime()+20;
        else g_iAnimTimeout=0;
        refreshTimer();
    }
    timer() {
        refreshTimer();
    }
    dataserver(key kID, string sData) {
        if (sData == EOF) iCardComplete++;
        else {
            list lParams = llParseString2List(sData, ["|"], []);
            integer iLength = llGetListLength(lParams);
            if (iLength == 4 || iLength == 5) {
                if (!llGetInventoryType(llList2String(lParams, 1)) == INVENTORY_ANIMATION){
                    llMessageLinked(LINK_SET,NOTIFY,"0"+CARD1 + " line " + (string)g_iLine1 + ": animation '" + llList2String(lParams, 1) + "' is not present.  Skipping.",g_kWearer);
                } else if (!llGetInventoryType(llList2String(lParams, 2)) == INVENTORY_ANIMATION){
                    llMessageLinked(LINK_SET,NOTIFY,"0"+CARD1 + " line " + (string)g_iLine2 + ": animation '" + llList2String(lParams, 2) + "' is not present.  Skipping.",g_kWearer);
                } else {
                    integer iIndex = llListFindList(g_lAnimCmds, llList2List(lParams, 0, 0));
                    if (~iIndex) {
                        g_lAnimCmds=llDeleteSubList(g_lAnimCmds,iIndex,iIndex);
                        g_lAnimSettings=llDeleteSubList(g_lAnimSettings,iIndex*4,iIndex*4+3);
                    }
                    g_lAnimCmds += llList2List(lParams, 0, 0);
                    g_lAnimSettings += llList2List(lParams, 1, 3);
                    g_lAnimSettings += [llList2String(lParams, 4)];
                    //Debug(llDumpList2String(g_lAnimCmds, ","));
                    //Debug(llDumpList2String(g_lAnimSettings, ","));
                }
            }
            if ( iCardComplete <2) {
                if (kID == g_kDataID1) {
                    if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD) {
                        g_iLine1++;
                        g_kDataID1 = llGetNotecardLine(CARD1, g_iLine1);
                    }
                } else if (kID == g_kDataID2) {
                    if (llGetInventoryType(CARD2) == INVENTORY_NOTECARD) {
                        g_iLine2++;
                        g_kDataID2 = llGetNotecardLine(CARD2, g_iLine2);
                    }
                }
            }
        }
    }

    run_time_permissions(integer perm) {
        if (perm & PERMISSION_TRIGGER_ANIMATION) {
            key kID = llGetPermissionsKey();
            //Debug("changed anim permissions\nPerm ID="+(string)kID+"g_kPartner="+(string)g_kPartner);
            if (kID == g_kPartner) {
                g_iPermissionTimeout=0;
                MoveToPartner();
            } else {
                llMessageLinked(LINK_SET,NOTIFY,"1"+"Sorry, but the request timed out.",kID);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(CARD1) != g_kCardID1) StartNotecards();
            if (llGetInventoryKey(CARD2) != g_kCardID2) StartNotecards();
        }
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
