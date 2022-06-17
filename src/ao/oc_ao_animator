// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Jessenia Mocha, Alexei Maven.  Wendy Starfall,
// littlemousy, Romka Swallowtail, Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.
/*-Authors Attribution-
Taya Maruti - (May 2021)
*/


//integer CMD_ZERO            = 0;
//integer CMD_OWNER           = 500;
//integer CMD_TRUSTED         = 501;
//integer CMD_GROUP           = 502;
//integer CMD_WEARER          = 503;
//integer CMD_EVERYONE        = 504;
//integer CMD_BLOCKED         = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY       = 507;
//integer CMD_SAFEWORD        = 510;
//integer CMD_RELAY_SAFEWORD  = 511;
//integer CMD_NOACCESS        = 599;
integer AO_SETTINGS=40500;
integer AO_SETOVERRIDE=40501;
integer AO_GETOVERRIDE=40502;
integer AO_GIVEOVERRIDE=40503;
integer AO_NOTECARD = 40504;
integer AO_STATUS = 40505;
integer AO_ANTISLIDE=40506;

integer CMD_USER;
key g_kWearer;

list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
        "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
        "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
        "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
        "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
        ];

string g_sJson_Anims = "{}";
string g_sWalkAnim;
integer g_iSitAnimOn;
string g_sSitAnim;
integer g_iSitAnywhereOn;
string g_sSitAnywhereAnim;
integer g_iShuffle;
integer g_iStandPause;
integer g_iChangeInterval = 45;
integer g_iReady;
integer g_iAO_ON;
integer g_iCardLine;
key g_kCard;
string g_sCard = "Default";
list g_lCustomCards;

//ao functions

integer JsonValid(string sTest) {
    if (~llSubStringIndex(JSON_FALSE+JSON_INVALID+JSON_NULL,sTest))
        return FALSE;
    return TRUE;
}

SetAnimOverride() {
    if (llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        llResetAnimationOverride("ALL");
        integer i = 22; //llGetListLength(g_lAnimStates);
        string sAnim;
        string sAnimState;
        do {
            sAnimState = llList2String(g_lAnimStates,i);
            if (~llSubStringIndex(g_sJson_Anims,sAnimState)) {
                sAnim = llJsonGetValue(g_sJson_Anims,[sAnimState]);
                if (JsonValid(sAnim)) {
                    if (sAnimState == "Walking" && g_sWalkAnim != "")
                        sAnim = g_sWalkAnim;
                    else if (sAnimState == "Sitting" && !g_iSitAnimOn) jump next;
                    else if (sAnimState == "Sitting" && g_sSitAnim != "" && g_iSitAnimOn)
                        sAnim = g_sSitAnim;
                    else if (sAnimState == "Sitting on Ground" && g_sSitAnywhereAnim != "")
                        sAnim = g_sSitAnywhereAnim;
                    else if (sAnimState == "Standing")
                        sAnim = llList2String(llParseString2List(sAnim, ["|"],[]),0);
                    if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
                        llSetAnimationOverride(sAnimState, sAnim);
                    else llOwnerSay(sAnim+" could not be found.");
                    @next;
                }
            }
        } while (i--);
        llSetTimerEvent(g_iChangeInterval);
        if (!g_iStandPause) llMessageLinked(LINK_THIS,AO_ANTISLIDE,(string)g_kWearer+":antislide off ao",llGetOwner());
        //llOwnerSay("AO ready ("+(string)llGetFreeMemory()+" bytes free memory)");
    }
}

SwitchStand() {
    if (g_iStandPause) return;
    if (llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        string sCurAnim = llGetAnimationOverride("Standing");
        list lAnims = llParseString2List(llJsonGetValue(g_sJson_Anims,["Standing"]),["|"],[]);
        integer index;
        if (g_iShuffle) index = (integer)llFrand(llGetListLength(lAnims));
        else {
            index = llListFindList(lAnims,[sCurAnim]);
            if (index == llGetListLength(lAnims)-1) index = 0;
            else index += 1;
        }
        if (g_iReady) llSetAnimationOverride("Standing",llList2String(lAnims,index));
    }
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}

default {
    state_entry() {
        g_kWearer = llGetOwner();
        PermsCheck();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if( iNum == AO_SETTINGS){
            list lPar     = llParseString2List(sStr, ["=","|"], []);
            string sVar   = llList2String(lPar, 0);
            string sVal   = llList2String(lPar, 1);
            string sVal2  = llList2String(lPar, 2);
            if( sVar == "UPDATE"){
                SetAnimOverride();
            }
            else if( sVar == "iSitAnimOn"){
                g_iSitAnimOn = (integer)sVal;
            }
            else if( sVar == "sWalkAnim"){
                g_sWalkAnim = sVal;
                SetAnimOverride();
            }
            else if( sVar == "iSitAnywhereOn"){
                g_iSitAnywhereOn = (integer)sVal;
            }
            else if( sVar == "sString_Anim"){
                g_sSitAnim = sVal;
            }
            else if( sVar == "sSitAnywhereAnim"){
                g_sSitAnywhereAnim = sVal;
            }
            else if( sVar == "iShuffle"){
                g_iShuffle = (integer)sVal;
            }
            else if( sVar == "iStandPause"){
                g_iStandPause = (integer)sVal;
            }
            else if( sVar == "iChangeInterval"){
                g_iChangeInterval = (integer)sVal;
                llSetTimerEvent(g_iChangeInterval);
            }
            else if(sVar == "iAO_ON"){
                g_iAO_ON = (integer)sVal;
                if(g_iAO_ON){
                    llRequestPermissions(g_kWearer,PERMISSION_OVERRIDE_ANIMATIONS);
                    SetAnimOverride();
                }
                else {
                    llSetTimerEvent(0);
                    //llResetAnimationOverride("ALL");
                }
            }
        }
        else if( iNum == AO_SETOVERRIDE){
            list lPar     = llParseString2List(sStr, [":","="], []);
            string sToken  = llList2String(lPar, 0);
            string sVar   = llList2String(lPar, 1);
            string sVal  = llList2String(lPar, 2);
            if(sToken == "switchstand"){
                SwitchStand();
            }
            else if(sToken == "set"){
                llSetAnimationOverride(sVar,sVal);
            }
            else if(sToken == "RESET"){
                llResetAnimationOverride(llToUpper(sVar));
            }
        }
        else if( iNum == AO_GETOVERRIDE){
            if( sStr == "" | sStr == "all"){
                llMessageLinked(LINK_THIS,AO_GIVEOVERRIDE,g_sJson_Anims,kID);
            }
            else if(~llSubStringIndex(g_sJson_Anims,sStr)){
                list lAnims = llParseString2List(llJsonGetValue(g_sJson_Anims,[sStr]),["|"],[]);
                llMessageLinked(LINK_THIS,AO_GIVEOVERRIDE,"{"+sStr+llDumpList2String(lAnims,"|")+"}",kID);
            }
            else {
                llMessageLinked(LINK_THIS,AO_GIVEOVERRIDE,"404",kID);
            }
        }
        else if( iNum == AO_NOTECARD){
            list lPar     = llParseString2List(sStr, ["|"], []);
            string sVal   = llList2String(lPar, 0);
            integer iVal  = llList2Integer(lPar, 1);
            if(llGetInventoryType(sVal) == INVENTORY_NOTECARD){
                if(iVal == 0){
                    g_sJson_Anims = "{}";
                }
                g_sCard = sVal;
                g_iCardLine = iVal;
                g_kCard = llGetNotecardLine(g_sCard, g_iCardLine);
            }
        }
    }

    timer() {
        if (g_iAO_ON && g_iChangeInterval) SwitchStand();
    }

    run_time_permissions(integer iFlag) {
        if (iFlag & PERMISSION_OVERRIDE_ANIMATIONS) {
            if (g_sJson_Anims != "{}") g_iReady = TRUE;
            else g_iReady =  FALSE;
            if (g_iAO_ON) SetAnimOverride();
            else llResetAnimationOverride("ALL");
        }
    }
    
    on_rez(integer start_pram){
        if(g_iAO_ON){
            llRequestPermissions(g_kWearer,PERMISSION_OVERRIDE_ANIMATIONS);
            SwitchStand();
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_LINK) {
            if(g_iReady){
                if(g_iAO_ON){
                    llRequestPermissions(g_kWearer,PERMISSION_OVERRIDE_ANIMATIONS);
                    SwitchStand();
                }
            }
        }
        if (iChange & CHANGED_INVENTORY) PermsCheck();
    }
    
    
    dataserver(key kRequest, string sData) {
        if (kRequest == g_kCard) {
            if (sData != EOF) {
                if (llGetSubString(sData,0,0) != "[") jump next;
                string sAnimationState = llStringTrim(llGetSubString(sData,1,llSubStringIndex(sData,"]")-1),STRING_TRIM);
                // Translate common ZHAOII, Oracul and AX anim state values
                if (sAnimationState == "Stand.1" || sAnimationState == "Stand.2" || sAnimationState == "Stand.3") sAnimationState = "Standing";
                else if (sAnimationState == "Walk.N") sAnimationState = "Walking";
                else if (sAnimationState == "Running") sAnimationState = "Running";
                else if (sAnimationState == "Turn.L") sAnimationState = "Turning Left";
                else if (sAnimationState == "Turn.R") sAnimationState = "Turning Right";
                else if (sAnimationState == "Sit.N") sAnimationState = "Sitting";
                else if (sAnimationState == "Sit.G" || sAnimationState == "Sitting On Ground") sAnimationState = "Sitting on Ground";
                else if (sAnimationState == "Crouch") sAnimationState = "Crouching";
                else if (sAnimationState == "Walk.C" || sAnimationState == "Crouch Walking") sAnimationState = "CrouchWalking";
                else if (sAnimationState == "Jump.N" || sAnimationState == "Jumping") sAnimationState = "Jumping";
                //else if (sAnimationState == "Takeoff") sAnimationState = "Taking Off";
                else if (sAnimationState == "Hover.N") sAnimationState = "Hovering";
                else if (sAnimationState == "Hover.U" || sAnimationState == "Flying Up") sAnimationState = "Hovering Up";
                else if (sAnimationState == "Hover.D" || sAnimationState == "Flying Down") sAnimationState = "Hovering Down";
                else if (sAnimationState == "Fly.N") sAnimationState = "Flying";
                else if (sAnimationState == "Flying Slow") sAnimationState = "FlyingSlow";
                else if (sAnimationState == "Land.N") sAnimationState = "Landing";
                else if (sAnimationState == "Falling") sAnimationState = "Falling Down";
                /* ----------------------------------------------------------------------- */
                // Meeded for competition events like those held in pony play
                else if (sAnimationState == "Striding") sAnimationState = "Striding";
                else if (sAnimationState == "Soft Landing") sAnimationState = "Soft Landing";
                else if (sAnimationState == "Jump.P" || sAnimationState == "Pre Jumping") sAnimationState = "PreJumping";
                else if (sAnimationState == "Stand.U") sAnimationState = "Standing Up";
                /* ----------------------------------------------------------------------- */
                if (!~llListFindList(g_lAnimStates,[sAnimationState])) jump next;
                if (llStringLength(sData)-1 > llSubStringIndex(sData,"]")) {
                    sData = llGetSubString(sData,llSubStringIndex(sData,"]")+1,-1);
                    list lTemp = llParseString2List(sData, ["|",","],[]);
                    integer i = llGetListLength(lTemp);
                    while(i--) {
                        if (llGetInventoryType(llList2String(lTemp,i)) != INVENTORY_ANIMATION)
                            lTemp = llDeleteSubList(lTemp,i,i);
                    }
                    if (sAnimationState == "Sitting on Ground"){
                        g_sSitAnywhereAnim = llList2String(lTemp,0);
                        llMessageLinked(LINK_THIS,AO_STATUS,"UPDATE:sSitAnywhereAnim="+g_sSitAnywhereAnim,llGetOwner());
                    }
                    else if (sAnimationState == "Sitting") {
                        g_sSitAnim = llList2String(lTemp,0);
                        llMessageLinked(LINK_THIS,AO_STATUS,"UPDATE:sSitAnim="+g_sSitAnim,llGetOwner());
                        if (g_sSitAnim != "") g_iSitAnimOn = TRUE;
                        else g_iSitAnimOn = FALSE;
                        llMessageLinked(LINK_THIS,AO_STATUS,"UPDATE:iSitAnimOn="+(string)g_iSitAnimOn,llGetOwner());
                    } else if (sAnimationState == "Walking"){
                        g_sWalkAnim = llList2String(lTemp,0);
                        llMessageLinked(LINK_THIS,AO_STATUS,"UPDATE:sWaLkAnim="+g_sWalkAnim,llGetOwner());
                    }
                    else if (sAnimationState != "Standing") lTemp = llList2List(lTemp,0,0);
                    if (lTemp) g_sJson_Anims = llJsonSetValue(g_sJson_Anims, [sAnimationState],llDumpList2String(lTemp,"|"));
                }
                @next;
                g_kCard = llGetNotecardLine(g_sCard,++g_iCardLine);
            } else {
                g_iCardLine = 0;
                g_kCard = "";
                g_iSitAnywhereOn = FALSE;
                llMessageLinked(LINK_THIS,AO_STATUS,"UPDATE:iSitAnywhereOn="+(string)g_iSitAnywhereOn,llGetOwner());
                integer index = llListFindList(g_lCustomCards,[g_sCard]);
                if (~index) g_sCard = llList2String(g_lCustomCards,index+1)+" ("+g_sCard+")";
                g_lCustomCards = [];
                if (g_sJson_Anims == "{}") {
                    llOwnerSay("\""+g_sCard+"\" is an invalid animation set and can't play.");
                    g_iAO_ON = FALSE;
                    llMessageLinked(LINK_THIS,AO_STATUS,"UPDATE:iAO_ON="+(string)g_iAO_ON,llGetOwner());
                } else {
                    llOwnerSay("The \""+g_sCard+"\" animation set was loaded successfully.");
                    g_iAO_ON = TRUE;
                    llMessageLinked(LINK_THIS,AO_GIVEOVERRIDE,g_sJson_Anims,llGetOwner());
                    llMessageLinked(LINK_THIS,AO_STATUS,"UPDATE:iAOOn="+(string)g_iAO_ON,llGetOwner());
                }
                llRequestPermissions(g_kWearer,PERMISSION_OVERRIDE_ANIMATIONS);
            }
        }
    }
}
