// This file is part of OpenCollar.
// Copyright (c) 2009 - 2024 Cleo Collins, Nandana Singh, Satomi Ahn,   
// Joy Stipe, Wendy Starfall, Medea Destiny, littlemousy,         
// Romka Swallowtail, Garvin Twine et al. 
// Last updated: Trix (TrixAeo) 2024 - Uploaded new sounds.
// Licensed under the GPLv2.  See LICENSE for full details. 


//scans for sounds starting with: bell_
//show/hide for elements named: Bell
//2009-01-30 Cleo Collins - 1. draft

string g_sScriptVersion = "8.1";
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
string g_sAppVersion = "1.2";

/*
integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;
*/



string g_sSubMenu = "Bell";
string g_sParentMenu = "Apps";
list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

float g_fVolume=0.5; // volume of the bell
float g_fVolumeStep=0.1; // stepping for volume

float g_fNextRing;

integer g_iBellOn=0; // are we ringing. Off is 0, On = Auth of person which enabled
string g_sBellOn="ON"; // menu text of bell on
string g_sBellOff="OFF"; // menu text of bell off

integer g_iBellShow=FALSE; // is the bell visible
string g_sBellShow="SHOW"; //menu text of bell visible
string g_sBellHide="HIDE"; //menu text of bell hidden

// List of current sounds
// bell_brass_01.wav       9a1f0d2e-0f32-21f7-7d83-1aeb428ace4a
// bell_brass_02.wav       b6985bfd-72c0-5e19-5d83-88f6c9bbe151
// bell_cow_01.wav         5837c0d4-cdb5-21f5-8743-5801614383a8
// bell_cow_02.wav         86c7c7ec-1862-5328-f908-00d341e0a5d2
// bell_cow_03.wav         effb7813-18a3-7237-dcf0-873713e4a545
// bell_plastic_01.wav     f75aaed4-2415-d5a0-bd94-4bb32432b42f
// bell_silver_01.wav      f8be56c4-28c8-3095-4b61-d425467eb2cb
// bell_silver_02.wav      e0b061c0-9edd-6a49-cdd6-a197ab439391
// bell_silver_03.wav      378e5546-955d-b04f-8994-c7b0763b8f68

 list g_listBellSounds=["9a1f0d2e-0f32-21f7-7d83-1aeb428ace4a","b6985bfd-72c0-5e19-5d83-88f6c9bbe151","5837c0d4-cdb5-21f5-8743-5801614383a8",
"86c7c7ec-1862-5328-f908-00d341e0a5d2", "effb7813-18a3-7237-dcf0-873713e4a545", "f75aaed4-2415-d5a0-bd94-4bb32432b42f", "f8be56c4-28c8-3095-4b61-d425467eb2cb",
 "e0b061c0-9edd-6a49-cdd6-a197ab439391", "378e5546-955d-b04f-8994-c7b0763b8f68"];

key g_kCurrentBellSound; // curent bell sound key
integer g_iCurrentBellSound; // curent bell sound sumber
integer g_iBellSoundCount; // number of avail bell sounds

key g_kLastToucher ; // store toucher key
float g_fNextTouch ;  // store time for the next touch

list g_lBellElements; // list with number of prims related to the bell
list g_lGlows; // 2-strided list [integer link_num, float glow]

key g_kWearer; // key of the current wearer to reset only on owner changes

integer g_iHasControl=FALSE; // dow we have control over the keyboard?

integer g_iHide=1 ; // global hide. Default is visible, but the bell script inverts this value.

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;
integer SAY = 1004;

integer REBOOT = -1000;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
integer g_iHasBellPrims;
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
Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
}

BellMenu(key kID, integer iAuth) {
    string sPrompt = "\n[Bell]\t"+g_sAppVersion+"\n\n";
    list lMyButtons;
    if (g_iBellOn>0) {
        lMyButtons+= g_sBellOff;
        sPrompt += "Bell is ringing";
    } else {
        lMyButtons+= g_sBellOn;
        sPrompt += "Bell is silent";
    }
    if (g_iBellShow) {
        lMyButtons+= g_sBellHide;
        sPrompt += " and shown.\n\n";
    } else {
        lMyButtons+= g_sBellShow;
        sPrompt += " and hidden.\n\n";
    }
    sPrompt += "Bell Volume:  \t"+(string)((integer)(g_fVolume*10))+"/10\n";
    sPrompt += "Active Sound:\t"+(string)(g_iCurrentBellSound+1)+"/"+(string)g_iBellSoundCount+"\n";

    lMyButtons += ["Next Sound","Vol +","Vol -"];

    Dialog(kID, sPrompt, lMyButtons, [UPMENU], 0, iAuth, "BellMenu");
}

SetBellElementAlpha() {
    //loop through stored links, setting color if element type is bell
    integer n;
    integer iLinkElements = llGetListLength(g_lBellElements);
    for (n = 0; n < iLinkElements; n++) {
        if(!g_iHide){
            // Collar is hidden, just hide the bell
            llSetLinkAlpha(llList2Integer(g_lBellElements,n),0,ALL_SIDES);
            UpdateGlow(llList2Integer(g_lBellElements,n), 0);
        }else{
            llSetLinkAlpha(llList2Integer(g_lBellElements,n), (float)g_iBellShow, ALL_SIDES);
            UpdateGlow(llList2Integer(g_lBellElements,n), g_iBellShow);
        }
        //llOwnerSay("Set bell element ("+llList2String(g_lBellElements,n)+") = "+(string)g_iBellShow);
    }
}

UpdateGlow(integer link, integer alpha) {
    if (alpha == 0) {
        SavePrimGlow(link);
        llSetLinkPrimitiveParamsFast(link, [PRIM_GLOW, ALL_SIDES, 0.0]);  // set no glow;
    } else RestorePrimGlow(link);
}

SavePrimGlow(integer link) {
    float glow = llList2Float(llGetLinkPrimitiveParams(link,[PRIM_GLOW,0]),0);
    integer i = llListFindList(g_lGlows,[link]);
    if (i !=-1 && glow > 0) g_lGlows = llListReplaceList(g_lGlows,[glow],i+1,i+1);
    if (i !=-1 && glow == 0) g_lGlows = llDeleteSubList(g_lGlows,i,i+1);
    if (i == -1 && glow > 0) g_lGlows += [link, glow];
}

RestorePrimGlow(integer link) {
    integer i = llListFindList(g_lGlows,[link]);
    if (i != -1) llSetLinkPrimitiveParamsFast(link, [PRIM_GLOW, ALL_SIDES, llList2Float(g_lGlows, i+1)]);
}

BuildBellElementList() {
    list lParams;
    g_lBellElements = [];
    //root prim is 1, so start at 2
    integer i = 2;
    for (i=LINK_ROOT+1; i <= llGetNumberOfPrims(); i++) {
        lParams=llParseString2List((string)llGetLinkPrimitiveParams(i,[PRIM_DESC]), ["~"], []);
        if (llList2String(lParams, 0)=="Bell") {
            g_lBellElements += [i];
            // Debug("added " + (string)n + " to elements");
            //llOwnerSay("Added "+(string)i+" to elements");
        }
    } //Remove my menu and myself if no bell elements are found
    if (llGetListLength(g_lBellElements)) {
        g_iHasBellPrims = TRUE;
     /*  llMessageLinked(LINK_SET, LM_SETTING_DELETE,g_sSettingToken+"all","");
        llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
        llRemoveInventory(llGetScriptName());*/
    }
}

PrepareSounds() {
    integer i;
    string sSoundName;
    for (; i < llGetInventoryNumber(INVENTORY_SOUND); i++) {
        sSoundName = llGetInventoryName(INVENTORY_SOUND,i);
        if (llSubStringIndex(sSoundName,"bell_")==0) {
            g_listBellSounds+=llGetInventoryKey(sSoundName);
        }
    }
    g_iBellSoundCount=llGetListLength(g_listBellSounds);
    g_iCurrentBellSound=0;
    g_kCurrentBellSound=llList2Key(g_listBellSounds,g_iCurrentBellSound);
}

UserCommand(integer iNum, string sStr, key kID) { // here iNum: auth value, sStr: user command, kID: avatar id
   // Debug("command: "+sStr);
    sStr = llToLower(sStr);
    if (sStr == "menu bell" || sStr == "bell" || sStr == g_sSubMenu)
        BellMenu(kID, iNum);
    else if (llSubStringIndex(sStr,"bell")==0) {
        list lParams = llParseString2List(sStr, [" "], []);
        string sToken = llList2String(lParams, 1);
        string sValue = llList2String(lParams, 2);
        if (sToken=="volume") {
            integer n=(integer)sValue;
            if (n<1) n=1;
            if (n>10) n=10;
            g_fVolume=(float)n/10;
            llPlaySound(g_kCurrentBellSound,g_fVolume);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_vol=" + (string)llFloor(g_fVolume*10), "");
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Bell volume set to "+(string)n,kID);
        } else if (sToken=="show" || sToken=="hide") {
            if (sToken=="show") {
                g_iBellShow=TRUE;
                llMessageLinked(LINK_SET,NOTIFY,"1"+"The bell is now visible.",kID);
            } else  {
                g_iBellShow=FALSE;
                llMessageLinked(LINK_SET,NOTIFY,"1"+"The bell is now invisible.",kID);
            }
            SetBellElementAlpha();
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_show=" + (string)g_iBellShow, "");
        } else if (sToken=="on") {
            if (iNum!=CMD_GROUP) {
                if (g_iBellOn==0) {
                    g_iBellOn=iNum;
                    if (!g_iHasControl) llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_on=" + (string)g_iBellOn, "");
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"The bell rings now.",kID);
                }
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to bell",kID);
        } else if (sToken=="off") {
            if ((g_iBellOn>0)&&(iNum!=CMD_GROUP)) {
                g_iBellOn=0;
                if (g_iHasControl) {
                    llReleaseControls();
                    g_iHasControl=FALSE;
                }
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_on=" + (string)g_iBellOn, "");
                llMessageLinked(LINK_SET,NOTIFY,"1"+"The bell is now quiet.",kID);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to bell",kID);
        } else if (sToken=="nextsound") {
            g_iCurrentBellSound++;
            if (g_iCurrentBellSound>=g_iBellSoundCount) g_iCurrentBellSound=0;
            g_kCurrentBellSound=llList2Key(g_listBellSounds,g_iCurrentBellSound);
            llPlaySound(g_kCurrentBellSound,g_fVolume);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_sound=" + (string)g_iCurrentBellSound, "");
            llMessageLinked(LINK_SET,NOTIFY,"1"+"Bell sound changed, now using "+(string)(g_iCurrentBellSound+1)+" of "+(string)g_iBellSoundCount+".",kID);
        } else if (sToken=="ring") {
            g_fNextRing=llGetTime()+1.0;
            llPlaySound(g_kCurrentBellSound,g_fVolume);
        }
    } else if (sStr == "rm bell") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to remove bell",kID);
        else  Dialog(kID,"\nDo you really want to uninstall the "+g_sSubMenu+" App?", ["Yes","No","Cancel"], [], 0, iNum,"rmbell");
    }
    //Debug("command executed");
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
    on_rez(integer param) {
        //g_kWearer=llGetOwner();
        //if (g_iBellOn) llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
        llResetScript();
    }

    state_entry() {
       // llSetMemoryLimit(36864);
        g_kWearer=llGetOwner();
        llResetTime();  // reset script time used for ringing the bell in intervalls
        BuildBellElementList();
        PrepareSounds();
        SetBellElementAlpha();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
            UserCommand(iNum, sStr, kID);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAV = llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                // integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAV);
                    return;
                } else if (sMessage == "Vol +") {
                    g_fVolume+=g_fVolumeStep;
                    if (g_fVolume>1.0) g_fVolume=1.0;
                    llPlaySound(g_kCurrentBellSound,g_fVolume);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_vol=" + (string)llFloor(g_fVolume*10), "");
                } else if (sMessage == "Vol -") {
                    g_fVolume-=g_fVolumeStep;
                    if (g_fVolume<0.1) g_fVolume=0.1;
                    llPlaySound(g_kCurrentBellSound,g_fVolume);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE,  "bell_vol=" + (string)llFloor(g_fVolume*10), "");
                } else if (sMessage == "Next Sound") {
                    g_iCurrentBellSound++;
                    if (g_iCurrentBellSound>=g_iBellSoundCount) g_iCurrentBellSound=0;
                    g_kCurrentBellSound=llList2Key(g_listBellSounds,g_iCurrentBellSound);
                    llPlaySound(g_kCurrentBellSound,g_fVolume);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_sound=" + (string)g_iCurrentBellSound, "");
                } else if (sMessage == g_sBellOff || sMessage == g_sBellOn)
                    UserCommand(iAuth,"bell "+llToLower(sMessage),kAV);
                else if (sMessage == g_sBellShow || sMessage == g_sBellHide) {
                    if (g_iHasBellPrims) {
                        g_iBellShow = !g_iBellShow;
                        SetBellElementAlpha();
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "bell_show=" + (string)g_iBellShow, "");
                    } else llMessageLinked(LINK_SET, NOTIFY, "0"+"This %DEVICETYPE% has no visual bell element.", kAV);
                } else if (sMenuType == "rmbell") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_SET, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_SET, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAV);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_SET, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAV);
                    return;
                }
                BellMenu(kAV, iAuth);
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParam = llParseString2List(sStr,["_","="],[]);
            string sToken = llList2String(lParam,0);
            string sVar = llList2String(lParam,1);
            string sValue = llList2String(lParam,2);
            
            
            if (sToken == "bell") {
                //llOwnerSay("Process bell settings: "+sStr);
                if (sVar == "on") {
                    g_iBellOn=(integer)sValue;
                    if (g_iBellOn && !g_iHasControl)
                        llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
                    else if (!g_iBellOn && g_iHasControl) {
                        llReleaseControls();
                        g_iHasControl = FALSE;
                    }
                } else if (sVar == "show") {
                    //llOwnerSay("Updating bell visibility");
                    g_iBellShow=(integer)sValue;
                    SetBellElementAlpha();
                } else if (sVar == "sound") {
                    g_iCurrentBellSound = (integer)sValue;
                    g_kCurrentBellSound = llList2Key(g_listBellSounds,g_iCurrentBellSound);
                } else if (sVar == "vol") g_fVolume = (float)sValue/10;
            } else if(sToken == "global"){
                if(sVar == "hide"){
                    // Here we have the hidden status!
                    g_iHide = !((integer)sValue); // invert this so that true means hide
                    SetBellElementAlpha();
                }
            }
        
        } else if(iNum == CMD_OWNER && sStr == "runaway") {
            llSleep(4);
            SetBellElementAlpha();
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion+", APPVERSION: "+g_sAppVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            DebugOutput(kID, [" HAS BELL PRIMS:", g_iHasBellPrims]);
            DebugOutput(kID, [" BELL VISIBLE:", g_iBellShow]);
            DebugOutput(kID, [" BELL ON:", g_iBellOn]);
        } 
    }

    control( key kID, integer nHeld, integer nChange ) {
        if (!g_iBellOn) return;
        if(!g_iBellShow)return;
        //the user is pressing a movement key
        if ((nChange & (CONTROL_LEFT|CONTROL_RIGHT|CONTROL_DOWN|CONTROL_UP|CONTROL_FWD|CONTROL_BACK)) && llGetTime()>g_fNextRing)
            llPlaySound(g_kCurrentBellSound,g_fVolume);
        //the user is holding down a movement key and is running
        if ((nHeld & (CONTROL_FWD|CONTROL_BACK)) && (llGetAgentInfo(g_kWearer) & AGENT_ALWAYS_RUN)) {
             if (llGetTime()>g_fNextRing) {
                g_fNextRing=llGetTime()+1.0;
                llPlaySound(g_kCurrentBellSound,g_fVolume);
            }
        }
    }

    collision_start(integer iNum) {
        if (g_iBellOn)
            llPlaySound(g_kCurrentBellSound,g_fVolume);
    }

    run_time_permissions(integer nParam) {
        if( nParam & PERMISSION_TAKE_CONTROLS){
            //Debug("Bing");
            llTakeControls( CONTROL_DOWN|CONTROL_UP|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT, TRUE, TRUE);
            g_iHasControl=TRUE;
        }
    }

    touch_start(integer n) {
        if (g_iBellShow && !g_iHide && ~llListFindList(g_lBellElements,[llDetectedLinkNumber(0)])) {
            key toucher = llDetectedKey(0);
            if (toucher != g_kLastToucher || llGetTime() > g_fNextTouch) {
                //one touch every 10 secounds is enough dude
                g_fNextTouch = llGetTime()+10.0;
                g_kLastToucher = toucher;
                llPlaySound(g_kCurrentBellSound,g_fVolume);
                llMessageLinked(LINK_SET,SAY,"1"+ "secondlife:///app/agent/"+(string)toucher+"/about plays with the trinket on %WEARERNAME%'s %DEVICETYPE%.","");
            }
        }
    }

    changed(integer iChange) {
        if(iChange & CHANGED_LINK) BuildBellElementList();
        else if (iChange & CHANGED_INVENTORY) {
            PrepareSounds();
        }
        if (iChange & CHANGED_OWNER) llResetScript();
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
}
