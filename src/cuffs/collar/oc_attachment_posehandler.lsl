// This file is part of OpenCollar.
// Copyright (c) 2018 - 2020 Tashia Redrose, Silkie Sabra, lillith xue, Chrissy Voir                           
// Licensed under the GPLv2.  See LICENSE for full details. 

integer NOTIFY = 1002;

integer REBOOT = -1000;

// This is wrong
string g_sParentMenu = "Cuff Menu";
//string g_sSubMenu = "Cuff Poses";
//string g_sParentMenu = "";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
string ALL = "ALL";
string g_sChecked = "☑";
string g_sUnChecked = "☐";

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value
integer LM_SETTING_REQUEST_EXTENSION = 2200;
integer LM_SETTING_RESPONSE_EXTENSION = 2201;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

// oc_attachment_posehandler operations
integer LM_CLEAR_ALL_POSES = 2250;
integer LM_APPLY_RLV = 2251;
integer LM_DO_POSE = 2252;
integer LM_UNDO_POSE = 2253;
integer LM_POSES_UCMD = 2254;
integer LM_POSE_RESET = 2255;
integer LM_POSES_MENU = 2256;
integer LM_ANIM_MENU = 2257;
integer LM_POSES_UPMENU = 2259;

integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;

integer CMD_POSEHANDLER = 599;

integer g_iNCLine;
key g_kNCQuery;
string g_sNCName = "Collar Pose";
integer g_iChan_ocCmd = -1;
integer g_iChan_OCChain = -9889;
list g_lCollarPoses = [];

/* Chrissy NOTE: g_lPoses is never initialized from NC, just from RPC so is empty */
list g_lPoses = [];
list g_lActivePoses = [];
list g_lSelectedPose = [];
string g_sCurrentCollarPose = "";

string g_sGlobalToken = "global"; 
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;

integer g_bMoveLock = FALSE;

debugMsg(string sStr)
{
    llOwnerSay("SPY:" + sStr);
}

string getCategoryPose(string sCategory)
{
    integer i;
    for (i=0;i<llGetListLength(g_lActivePoses);++i){
        list lPose = llParseString2List(llList2String(g_lActivePoses,i),["|"],[]);
        if (llList2String(lPose,0) == sCategory){
            return llList2String(g_lActivePoses,i);
        }
    }
    return "";
}

doClearAllPoses() {
    integer i;
    list lAPoses = g_lActivePoses;
    for (i=0;i<llGetListLength(lAPoses);++i){
        llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":clearpose:"+llList2String(lAPoses,i));
    }
    g_lActivePoses = [];
    llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_poses="+llDumpList2String(g_lActivePoses,","), NULL_KEY);
}

HandleSettings(string sStr) {
    list lParams = llParseString2List(sStr, ["="], []); // now [0] = "major_minor" and [1] = "value"
    string sToken = llList2String(lParams, 0); // now SToken = "major_minor"
    string sValue = llList2String(lParams, 1); // now sValue = "value"
    integer i = llSubStringIndex(sToken, "_");
    string sTokenMajor = llToLower(llGetSubString(sToken, 0, i));  // now sTokenMajor = "major"
    string sTokenMinor = llToLower(llGetSubString(sToken, i + 1, -1));  // now sTokenMinor = "minor"
    
    if (sTokenMajor == llToLower(g_sGlobalToken)) { // if "major_" = "global_"
        if (sTokenMinor == "poses") {
            llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":activeposes:"+sValue);
            g_lActivePoses = llParseString2List(sValue,[","],[]);
        }
    } else {
        if (sToken == "anim_currentpose") {
            string sAnimName = llList2String(llParseString2List(sValue,[","],[]),0);
            integer iIndex = llListFindList(g_lCollarPoses,[sAnimName]);
            if (iIndex > -1) {
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"clearchain:all");
                llMessageLinked(LINK_THIS,g_iChan_OCChain,"clearchain:all","");
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1));
                llMessageLinked(LINK_THIS,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1),"");
                applyRLV(sAnimName);
                g_sCurrentCollarPose = sAnimName;
            } else {
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"clearchain:all");
                applyRLV("");
                g_sCurrentCollarPose = "";
            }
        }
    }
}

HandleDeletes(string sStr) {
    list lParams = llParseString2List(sStr, ["_"], []); // now [0] = "major_minor" and [1] = "value"
    string sTokenMajor = llToLower(llList2String(lParams, 0)); // now STokenMajor = "major"
    string sTokenMinor = llToLower(llList2String(lParams, 1)); // now sTokenMinor = "minor"

    if (sTokenMajor == "anim") {
        if (sTokenMinor == "currentpose") {
            llRegionSayTo(g_kWearer,g_iChan_OCChain,"clearchain:all");
            llMessageLinked(LINK_THIS,g_iChan_OCChain,"clearchain:all","");
            applyRLV("");
            g_sCurrentCollarPose = "";
        }
    }
}

applyRLV(string sNewPose){
    integer iIndex = llListFindList(g_lCollarPoses,[g_sCurrentCollarPose]); // Remove old Restrictions
    if (iIndex > -1) {
            if (llList2String(g_lCollarPoses,iIndex+2) != ""){
            list lRestList = llParseString2List(llList2String(g_lCollarPoses,iIndex+2),[","],[]);
            list lRestrctions = [];
            integer i;
            for (i=0; i<llGetListLength(lRestList);++i){
                if (llList2String(lRestList,i) == "move"){
                    g_bMoveLock = FALSE;
                } else lRestrctions += [llList2String(lRestList,i)+"=y"];
            }
            llMessageLinked(LINK_SET,RLV_CMD,llDumpList2String(lRestrctions,","),"Collar Pose");
            llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
        }
    }
    
    iIndex = llListFindList(g_lCollarPoses,[sNewPose]); // Add new restrictions
    if (iIndex > -1) {
        if (llList2String(g_lCollarPoses,iIndex+2) != ""){
            list lRestList = llParseString2List(llList2String(g_lCollarPoses,iIndex+2),[","],[]);
            list lRestrctions = [];
            integer i;
            for (i=0; i<llGetListLength(lRestList);++i){
                if (llList2String(lRestList,i) == "move"){
                    g_bMoveLock = TRUE;
                } else lRestrctions += [llList2String(lRestList,i)+"=n"];
            }
            llMessageLinked(LINK_SET,RLV_CMD,llDumpList2String(lRestrctions,","),"Collar Pose");
            llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
        }
    }
}

doPose(string sPose, integer iAuth, key kID){
    string sCategory = llList2String(llParseString2List(sPose,["|"],[]),0);
    string sStopPose = getCategoryPose(sCategory);
    if (llGetListLength(g_lActivePoses) > 0 && iAuth == CMD_WEARER && sStopPose != "") llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kID);
        else {
            integer iActiveIndex = llListFindList(g_lActivePoses,[sPose]);
            if (iActiveIndex > -1) {
                llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":clearpose:"+sPose);
                g_lActivePoses = llDeleteSubList(g_lActivePoses,iActiveIndex,iActiveIndex);
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_poses="+llDumpList2String(g_lActivePoses,","), NULL_KEY);
            } else {
                if (sStopPose != "") {
                    llRegionSayTo(g_kWearer, g_iChan_ocCmd, (string)g_kWearer+":clearpose:"+sStopPose);
                    integer iStopPoseIndex = llListFindList(g_lActivePoses,[sStopPose]);
                    if (iStopPoseIndex > -1) g_lActivePoses = llDeleteSubList(g_lActivePoses,iStopPoseIndex,iStopPoseIndex);
                }
                g_lActivePoses += [sPose];
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, "cuffs_poses="+llDumpList2String(g_lActivePoses,","), NULL_KEY);
            }
            if (g_sCurrentCollarPose != "") { // Reapply current Collar pose Chains
                integer iIndex = llListFindList(g_lCollarPoses,[g_sCurrentCollarPose]);
                llRegionSayTo(g_kWearer,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1));
                llMessageLinked(LINK_THIS,g_iChan_OCChain,"occhains:"+llList2String(g_lCollarPoses,iIndex+1),"");
            }
        }
}

BulkRequest(string sSource) {
     string sRequest = llList2CSV([sSource,
                                "cuffs_chaintex",
                                "cuffs_synclock",
                                "global_locked",
                                "cuffs_poses",
                                "cuffs_lock",
                                "cuffs_hide"]);
     llMessageLinked(LINK_SET, LM_SETTING_REQUEST_EXTENSION, sRequest,g_kWearer);
}


ReadNotecard() {
    if (llGetInventoryType(g_sNCName) == INVENTORY_NOTECARD)
    {
        g_iNCLine = 0;
        g_kNCQuery = llGetNotecardLine(g_sNCName,g_iNCLine);
    } else llOwnerSay("ERROR: Notecard '"+g_sNCName+"' not found!");
}    

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

PosesMenu(key kID, integer iAuth){
    string sPrompt = "\n[Cuff Poses]";
    list lButtons = [];
    integer i;
    for (i=0; i<llGetListLength(g_lPoses);++i) {
        list lPose = llParseString2List(llList2String(g_lPoses,i),["|"],[]);
        if (llListFindList(lButtons,[llList2String(lPose,0)]) == -1) lButtons+=[llList2String(lPose,0)];
    }
    
    if (iAuth == CMD_WEARER) sPrompt += "\n \n!! WARNING !! \n \n You will not be able to stop Poses by yourself!";
    
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~CuffPoses");
}

PosesUCmd(key kID, string sStr) {
    list lUCmd = llParseString2List(sStr,[" "],[]);
    integer iWarn = llList2Integer(lUCmd,0);
    integer iAuth = llList2Integer(lUCmd,1);
    string sCmd = llList2String(lUCmd,3);
    string sPrefix = llList2String(lUCmd,2);

    string sRealPoseName = "";
    integer i;
    for (i=0; i<llGetListLength(g_lPoses);++i){
        list lPose = llParseString2List(llList2String(g_lPoses,i),["|"],[]);
        if (llList2String(lUCmd,4) != ""){
            if (llToLower(llList2String(lPose,1)) == llToLower(sCmd)+" "+llToLower(llList2String(lUCmd,4))) sRealPoseName = llList2String(g_lPoses,i);
        } else if (llToLower(llList2String(lPose,1)) == llToLower(sCmd)) sRealPoseName = llList2String(g_lPoses,i);
    }
    if (sRealPoseName) doPose(sRealPoseName,iAuth,kID);
    else if (iWarn) llMessageLinked(LINK_SET, NOTIFY, "0"+"Pose '"+sCmd+"' is not registered!", kID);
}

AnimMenu(key kID, integer iAuth, string sTarget){
    string sPrompt = "\n["+sTarget+" Poses]";
    list lButtons = [];
    list lUtility = [UPMENU];
    integer i;
    for (i=0;i<llGetListLength(g_lPoses);++i) {
        list lPose = llParseString2List(llList2String(g_lPoses,i),["|"],[]);
        if (llList2String(lPose,0) == sTarget) {
            if (llListFindList(g_lActivePoses,[llList2String(g_lPoses,i)]) > -1) lButtons += [g_sChecked+llList2String(lPose,1)];
            else lButtons += [g_sUnChecked+llList2String(lPose,1)];
        }
    }
    
    Dialog(kID, sPrompt, lButtons, lUtility, 0, iAuth, "Menu~"+sTarget);
}

default
{
    on_rez(integer t)
    {
        // llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":collarping");
        if(llGetOwner()!=g_kWearer) llResetScript();
    }

    state_entry()
    {
        if(llGetStartParameter()!=0)state inUpdate;
        g_lCollarPoses = [];
        g_kWearer = llGetOwner();
        g_iChan_ocCmd = (integer)("0x"+llGetSubString((string)g_kWearer,3,8)) + 0xCC0CC;
        if (g_iChan_ocCmd>0) g_iChan_ocCmd=g_iChan_ocCmd*(-1);
        if (g_iChan_ocCmd > -10000) g_iChan_ocCmd -= 30000;
        llListen(g_iChan_ocCmd,"",NULL_KEY,"");
        // llListen(g_iChan_OCChain,"",NULL_KEY,"");
        // llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":collarping");
        ReadNotecard();
    }

    run_time_permissions(integer iPerm){
        if (iPerm & PERMISSION_TAKE_CONTROLS){
            if (g_bMoveLock)llTakeControls(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT|CONTROL_UP|CONTROL_DOWN,TRUE,FALSE);
            else llReleaseControls();
        }
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        /*
        debugMsg((string)iSender +"|"+(string)iNum + "|" + (string)kID + "|" + sStr);
        if (iNum == -99999) if(sStr == "update_active") debugMsg("Update State");
        else if (iNum == DIALOG) debugMsg("Dialog REQ:" + (string)kID + "|" + sStr);
        else if (iNum == DIALOG_RESPONSE) debugMsg("Dialog RESP:" + (string)kID + "|" + sStr);
        */

        if(iNum == -99999){
            if(sStr == "update_active")state inUpdate;
        } else if (iNum == DIALOG_RESPONSE){
            list lParams = llParseString2List(sStr, ["|"],[]);
            key kAv = llList2Key(lParams,0);
            string sMsg = llList2String(lParams,1);
            integer iAuth = llList2Integer(lParams,3);
            // TODO: Fix the hack below - this is not the right way
            if (sMsg == UPMENU)
                llMessageLinked(LINK_THIS,AUTH_REQUEST,"cuffmenu",kAv);
        } else if (iNum < 2250 || iNum > 2260) return;
        else if (iNum == LM_POSES_MENU) {
            list lParams = llParseString2List(sStr, ["|"],[]);
            integer iAuth = llList2Integer(lParams, 0);
            string sMenu = llList2String(lParams, 1);
            //g_sParentMenu = sMenu;
            PosesMenu(kID, (integer)sStr);
        } else if (iNum == LM_POSE_RESET) llResetScript();
        else if (iNum == LM_APPLY_RLV) applyRLV(sStr);
        else if (iNum == LM_POSES_UCMD) PosesUCmd(kID, sStr);
        else if (iNum == LM_CLEAR_ALL_POSES) doClearAllPoses();
        else if (iNum = LM_ANIM_MENU) {
            list lParams = llParseString2List(sStr, ["|"],[]);
            integer iAuth = llList2Integer(lParams, 0);
            string sMenu = llList2String(lParams, 1);
            //g_sParentMenu = sMenu;
            string sTarget = llList2String(lParams, 2);
            AnimMenu(kID, iAuth, sTarget);
        } else if (iNum == LM_DO_POSE) {
            list lParams = llParseString2List(sStr, ["|"],[]);
            integer iAuth = llList2Integer(lParams, 0);
            string sPose = llList2String(lParams, 1);
            doPose(sPose, iAuth, kID);
        } else if (iNum == LM_UNDO_POSE) {
            list lParams = llParseString2List(sStr, ["|"],[]);
            integer iAuth = llList2Integer(lParams, 0);
            string sPose = llList2String(lParams, 1);
            //undoPose(sPose, iAuth, kID);
        }
    }

    dataserver(key kQuery, string sData){
        if (kQuery == g_kNCQuery) {
            if (sData != EOF) {
                if (llGetSubString(sData,0,0) != "#" && sData != "") {
                    list lAnim = llParseString2List(sData,[":"],[]);
                    string sCMD = llList2String(lAnim,0);
                    if (llToLower(sCMD) == "anim"){
                        if (llGetListLength(g_lSelectedPose) == 3) {
                            g_lCollarPoses += g_lSelectedPose;
                        }else if (llGetListLength(g_lSelectedPose) > 0) llOwnerSay("Error: pose '"+llList2String(lAnim,2)+"' is missing some parameters! Ignoring...");
                        g_lSelectedPose =[llList2String(lAnim,1)];
                    } else if (llToLower(sCMD) == "chains"){
                        g_lSelectedPose +=[llList2String(lAnim,1)];
                    } else if (llToLower(sCMD) == "restrictions"){
                        g_lSelectedPose +=[llList2String(lAnim,1)];
                    } else llOwnerSay("Syntax error: Unknown command '"+sCMD+"' at line "+(string)g_iNCLine);
                    
                }
                g_kNCQuery = llGetNotecardLine("Collar Pose",++g_iNCLine);
            } else {
                llOwnerSay("NCReader Finished Reading Notecard. "+(string)llGetFreeMemory()+" bytes free.");
                /* Pass any data back to oc_attachment_plugin or wherever via llLinkedMessage */
            }
        }
    }
    
    listen(integer iChan, string sName, key kID, string sMsg) {
        if (iChan == g_iChan_ocCmd){
            list lCMD = llParseString2List(sMsg,[":"],[]);
            key kCmdTarget = llList2Key(lCMD,0);
            if (kCmdTarget == g_kWearer) {
                string sCMD = llList2String(lCMD,1);
                string sParam = llList2String(lCMD,2);
                
                if (sCMD == "addpose") {
                    if (llListFindList(g_lPoses,[sParam]) == -1) g_lPoses += [sParam];
                } else if (sCMD == "remposes") {
                    list lPoseList = llParseString2List(sParam,[","],[]);
                    integer i;
                    for (i=0; i<llGetListLength(lPoseList);++i){
                        integer iDelIndex = llListFindList(g_lPoses,[llList2String(lPoseList,i)]);
                        if (iDelIndex > -1) g_lPoses = llDeleteSubList(g_lPoses,iDelIndex,iDelIndex);
                    }
                /*
                } else if (sCMD == "rlvcmd") {
                    llMessageLinked(LINK_SET,RLV_CMD,llList2String(lCMD,3),sParam);
                */
                } else if (sCMD == "requestpose") {
                    if (llListFindList(g_lPoses,[sParam]) > -1) doPose(sParam,CMD_OWNER,NULL_KEY);
                }
            }
        }
    }
    changed (integer iChange){
        if (iChange & CHANGED_INVENTORY) llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "anim_currentpose",g_kWearer); //llResetScript();
    }

}

state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
    }
}
