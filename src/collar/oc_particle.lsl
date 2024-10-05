// This file is part of OpenCollar.
// Copyright (c) 2008 - 2023 Lulu Pink, Nandana Singh, Garvin Twine,
// Cleo Collins, Satomi Ahn, Joy Stipe, Wendy Starfall, Romka Swallowtail,
// lillith xue, littlemousy, Nikki Lacrima et al.
// Licensed under the GPLv2.  See LICENSE for full details.
/*

 Nikki Lacrima
    Aug 2023: Updated for lockguard chain texture
    Sept 2024: Fix setting name for leash length
    
*/
string g_sScriptVersion = "8.3";
integer LINK_CMD_DEBUG=1999;
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;
//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;


integer g_iLeashedToAvatar=FALSE;

//integer POPUP_HELP          = 1001;
integer NOTIFY              = 1002;
//integer SAY                 = 1004;
integer REBOOT              = -1000;
// -- SETTINGS
integer LM_SETTING_SAVE     = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE   = 2003;
integer LM_SETTING_EMPTY            = 2004;
// -- MENU/DIALOG
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
//integer MENUNAME_REMOVE  = 3003;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

integer g_iChan_LOCKMEISTER = -8888;
integer g_iChan_LOCKGUARD   = -9119;
//integer g_iLMListener;
//integer g_iLMListernerDetach;

integer CMD_PARTICLE = 20000;


// --- menu tokens ---
string UPMENU       = "BACK";
string PARENTMENU   = "Leash";
string SUBMENU      = "Configure";
string L_COLOR      = "color";
string L_GRAVITY    = "gravity";
string L_SIZE       = "size";
string L_FEEL       = "feel";
string L_GLOW       = "shine";
string L_STRICT     = "strict";
string L_TURN       = "turn";
string L_DEFAULTS   = "RESET";
string L_CLASSIC_TEX= "Chain"; //texture name when using the classic particle stream
string L_RIBBON_TEX = "Silk"; //texture name when using the ribbon_mask particle stream
// Defalut leash particle, can read from defaultsettings:
// leashParticle=Shine~1~ParticleMode~Ribbon~R_Texture~Silk~C_Texture~Chain~Color~<1,1,1>~Size~<0.07,0.07,1.0>~Gravity~-0.7~C_TextureID~keyID~R_TextureID~keyID
list g_lDefaultSettings = [L_GLOW,"1",L_TURN,"0",L_STRICT,"0","particlemode","Ribbon","rtexture","Silk","ctexture","Chain",L_COLOR,"<1.0,1.0,1.0>",L_SIZE,"<0.04,0.04,1.0>",L_GRAVITY,"-1.0"];

string Uncheckbox(string Button){
    return llGetSubString(Button, llStringLength(llList2String(g_lCheckboxes, 0))+1, -1);
}

list g_lSettings=g_lDefaultSettings;

list g_lMenuIDs;
integer g_iMenuStride = 3;
key g_kWearer;

key NULLKEY;
key g_kLeashedTo;
key g_kLeashToPoint;
key g_kParticleTarget;

integer g_iLeashActive;
integer g_iTurnMode;
integer g_iStrictMode;
integer g_iStrictRank;
string g_sParticleMode = "Ribbon"; //modes can be: Ribbon, Classic and noParticle
string g_sRibbonTexture;
string g_sClassicTexture;
//List of 4 leash/chain points, lockmeister names used (list has to be all lower case, prims dont matter, converting on compare to lower case)
//strided list... LM name, linkNumber, BOOL_ACVTIVE
list g_lLeashPrims;

//global integer used for loops
integer g_iLoop;
string g_sSettingToken = "particle_";
//string g_sGlobalToken = "global_";
//Particle system and variables

string g_sParticleTexture = "Silk";
string g_sParticleTextureID; //we need the UUID for llLinkParticleSystem
string g_sChainParticleTexture; //default chains for Lock Guard
string g_sLeashParticleTexture;
//string g_sOccParticleTexture = "4cde01ac-4279-2742-71e1-47ff81cc3529";
string g_sLeashParticleMode;
vector g_vLeashColor = <1.00000, 1.00000, 1.00000>;
vector g_vLeashSize = <0.04, 0.04, 1.0>;
integer g_iParticleGlow = TRUE;
float g_fParticleAge = 3.5;
vector g_vLeashGravity = <0.0,0.0,-1.0>;
integer g_iParticleCount = 1;
float g_fBurstRate = 0.0;
//same g_lSettings but to store locally the default settings recieved from the defaultsettings note card, using direct string here to save some bits

//list g_lCurrentChains = [];

list g_lCollarPoints = [ // oc chain name, lockmeister name, lockguard name
    "fcollar"   , "collar"  , "collarfrontloop" , // Collar Front
    "lcollar"   , "lcollar" , "collarleftloop"  , // Collar Left
    "rcollar"   , "rcollar" , "collarrightloop" , // Collar Right
    "bcollar"   , "bcollar" , "collarbackloop"    // Collar Back
];
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

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sMenuName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex)
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sMenuName], iIndex, iIndex + g_iMenuStride - 1);
    else
        g_lMenuIDs += [kID, kMenuID, sMenuName];
}

FindLinkedPrims() {
    g_lLeashPrims = [];
    integer linkcount = llGetNumberOfPrims();
    integer i;

    for (i=-1; i<=linkcount;++i) {
        string sPrimName = llToLower(llStringTrim(llList2String(llGetLinkPrimitiveParams(i,[PRIM_NAME]),0),STRING_TRIM));
        if (sPrimName == "leashpoint" || sPrimName == "ooc") {
            g_lLeashPrims += ["fcollar", i];
            sPrimName = "fcollar";
        }
        integer iIndex = llListFindList(g_lCollarPoints,[sPrimName]);
        if (iIndex > -1) {
            g_lLeashPrims += [llList2String(g_lCollarPoints,iIndex),i];
            g_lLeashPrims += [llList2String(g_lCollarPoints,iIndex+1),i];
            g_lLeashPrims += [llList2String(g_lCollarPoints,iIndex+2),i];
        }
    }

    if (llListFindList(g_lLeashPrims,["fcollar"]) < 0){
        g_lLeashPrims += ["fcollar",LINK_ROOT, "collar", LINK_ROOT, "collarfrontloop", LINK_ROOT];
    }
}

Particles(integer iLink, key kParticleTarget, vector vScale) {
    //when we have no target to send particles to, dont create any
    if(g_sLeashParticleMode == "noParticle") {
        StopParticles(FALSE);
        return;
    }
    if (kParticleTarget == NULLKEY) return;

    integer iFlags = PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_SRC_MASK;

    if (g_sParticleMode == "Ribbon") iFlags = iFlags | PSYS_PART_RIBBON_MASK;
    if (g_iParticleGlow) iFlags = iFlags | PSYS_PART_EMISSIVE_MASK;

    list lTemp = [
        PSYS_PART_MAX_AGE,g_fParticleAge,
        PSYS_PART_FLAGS,iFlags,
        PSYS_PART_START_COLOR, g_vLeashColor,
        //PSYS_PART_END_COLOR, g_vLeashColor,
        PSYS_PART_START_SCALE,vScale,
        //PSYS_PART_END_SCALE,g_vLeashSize,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
        PSYS_SRC_BURST_RATE,g_fBurstRate,
        PSYS_SRC_ACCEL, g_vLeashGravity,
        PSYS_SRC_BURST_PART_COUNT,g_iParticleCount,
        //PSYS_SRC_BURST_SPEED_MIN,fMinSpeed,
        //PSYS_SRC_BURST_SPEED_MAX,fMaxSpeed,
        PSYS_SRC_TARGET_KEY,kParticleTarget,
        PSYS_SRC_MAX_AGE, 0,
        PSYS_SRC_TEXTURE, g_sParticleTextureID
        ];
    llLinkParticleSystem(iLink, lTemp);
}

StartParticles(key kParticleTarget) {
    //Debug(llList2CSV(g_lLeashPrims));
    StopParticles(FALSE);
    ////llWhisper(0, "start particles called for new target: "+(string)kParticleTarget);
    g_sParticleTextureID = g_sLeashParticleTexture;
    g_sParticleMode = g_sLeashParticleMode;

    integer iIndex = llListFindList(g_lLeashPrims,["collar"]);
    if (iIndex > -1) {
        Particles(llList2Integer(g_lLeashPrims,iIndex+1),kParticleTarget,g_vLeashSize);
        g_iLeashActive = TRUE;
    }
}

StopParticles(integer iEnd) {
    integer iIndex = llListFindList(g_lLeashPrims,["collar"]);
    if (iIndex > -1) {
        llLinkParticleSystem(llList2Integer(g_lLeashPrims,iIndex+1), []);
    }

    if (iEnd) {
        g_iLeashActive = FALSE;
        g_kLeashedTo = NULLKEY;
        g_kLeashToPoint = NULLKEY;
        g_kParticleTarget = NULLKEY;
        llSetTimerEvent(0.0);
       // llSensorRemove();
    }
}
/*
key findPrimKey(string sDesc)
{
    integer i;
    for (i=1;i<llGetNumberOfPrims()+1;++i)
    {
        if (llList2String(llGetLinkPrimitiveParams(i,[PRIM_NAME]),0) == sDesc) return llGetLinkKey(i);
    }
    return NULL_KEY;
}
doClearChain(string sChainCMD)
{
    if (sChainCMD == "all") {
        integer i;
        for (i=1;i<llGetNumberOfPrims()+1;++i)
        {
            llLinkParticleSystem(i,[]);
        }
        g_lCurrentChains = [];
    } else {
        list lRemChains = [];
        list lChains = llParseString2List(sChainCMD,["~"],[]); // Could be a string like "point=target~point=target..." or "point~point..."
        integer i;
        for (i=0;i<llGetListLength(lChains);++i) lRemChains += [llList2String(llParseString2List(llList2String(lChains,i),["="],[]),0)]; // Remove the targets out of the string
        for (i=1;i<llGetNumberOfPrims()+1;++i)
        {
            string sDesc = llList2String(llGetLinkPrimitiveParams(i,[PRIM_NAME]),0);
            if (llListFindList(lRemChains,[sDesc]) > -1) llLinkParticleSystem(i,[]);
            integer iIndex = llListFindList(g_lCurrentChains,[sDesc]);
            if (iIndex > -1) g_lCurrentChains = llDeleteSubList(g_lCurrentChains,iIndex,iIndex+1);
        }
    }
}
*/

string Vec2String(vector vVec) {
    list lParts = [vVec.x, vVec.y, vVec.z];
    for (g_iLoop = 0; g_iLoop < 3; g_iLoop++) {
        string sStr = llList2String(lParts, g_iLoop);
        //remove any trailing 0's or .'s from sStr
        while (~llSubStringIndex(sStr, ".") && (llGetSubString(sStr, -1, -1) == "0" || llGetSubString(sStr, -1, -1) == ".")) {
            sStr = llGetSubString(sStr, 0, -2);
        }
        lParts = llListReplaceList(lParts, [sStr], g_iLoop, g_iLoop);
    }
    return "<" + llDumpList2String(lParts, ",") + ">";
}

string Float2String(float in) {
    string out = (string)in;
    integer i = llSubStringIndex(out, ".");
    while (~i && llStringLength(llGetSubString(out, i + 2, -1)) && llGetSubString(out, -1, -1) == "0") {
        out = llGetSubString(out, 0, -2);
    }
    return out;
}

SaveSettings(string sToken, string sValue, integer iSaveToLocal) {
    integer iIndex = llListFindList(g_lSettings, [sToken]);
    if (iIndex>=0) g_lSettings = llListReplaceList(g_lSettings, [sValue], iIndex +1, iIndex +1);
    else g_lSettings += [sToken, sValue];

    if (sToken == "rtexture") {
        if (llToLower(llGetSubString(sValue,0,6)) == "!ribbon") L_RIBBON_TEX = llGetSubString(sValue, 8, -1);
        else L_RIBBON_TEX = sValue;
    }
    else if (sToken == "ctexture") {
        if (llToLower(llGetSubString(sValue,0,7)) == "!classic") L_CLASSIC_TEX = llGetSubString(sValue, 9, -1);
        else L_CLASSIC_TEX = sValue;
    }

    if (iSaveToLocal) llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken + sToken + "=" + sValue, "");
}

string GetDefaultSetting(string sToken) {
    integer index = llListFindList(g_lDefaultSettings, [sToken]);
    if (index != -1) return llList2String(g_lDefaultSettings, index + 1);
    else return "";
}

string GetSetting(string sToken) {
    integer index = llListFindList(g_lSettings, [sToken]);
    if (index != -1) return llList2String(g_lSettings, index + 1);
    else return GetDefaultSetting(sToken); // return from defaultsettings if not present
}
integer g_iLeashLength=2;
// get settings before StartParticles
GetSettings(integer iStartParticles) {
   // Debug("settings: "+llList2CSV(g_lSettings));
    g_sLeashParticleMode = GetSetting("particlemode");
    g_sParticleMode = g_sLeashParticleMode;
    g_sClassicTexture = GetSetting("ctexture");
    g_sRibbonTexture = GetSetting("rtexture");
    g_vLeashSize = (vector)GetSetting(L_SIZE);
    g_vLeashColor = (vector)GetSetting(L_COLOR);
    g_vLeashGravity.z = (float)GetSetting(L_GRAVITY);
    g_iParticleGlow = (integer)GetSetting(L_GLOW);
    if (g_sLeashParticleMode == "Classic") SetTexture(g_sClassicTexture, NULLKEY);
    else if (g_sLeashParticleMode == "Ribbon") SetTexture(g_sRibbonTexture, NULLKEY);
    if (iStartParticles &&  g_kLeashedTo != NULLKEY){
        llSleep(0.1);
        //llWhisper(0, "start particles from settings");
        StartParticles(g_kParticleTarget);
    }
}

// Added bSave as a boolean, to make this a more versatile wrapper
SetTexture(string sIn, key kIn) {
    g_sParticleTexture = sIn;
    g_sLeashParticleTexture=(string)NULL_KEY;
    if (sIn=="Silk") g_sLeashParticleTexture="cdb7025a-9283-17d9-8d20-cee010f36e90";
    else if (sIn=="Chain") g_sLeashParticleTexture="4cde01ac-4279-2742-71e1-47ff81cc3529";
    else if (sIn=="Leather") g_sLeashParticleTexture="8f4c3616-46a4-1ed6-37dc-9705b754b7f1";
    else if (sIn=="Rope") g_sLeashParticleTexture="9a342cda-d62a-ae1f-fc32-a77a24a85d73";
    else if (sIn=="totallytransparent") g_sLeashParticleTexture=TEXTURE_TRANSPARENT;
    else {
        if (llToLower(g_sParticleTexture) == "noleash") g_sLeashParticleMode = "noParticle";
        //Debug("particleTexture= " + sIn);
        g_sLeashParticleTexture = llGetInventoryKey(g_sParticleTexture);
        if(g_sLeashParticleTexture == NULL_KEY) g_sLeashParticleTexture=sIn; //for textures without full perm, we send the texture name. For this to work, texture must be in the emitter prim as well as in root, if different.
    }

    if(g_sLeashParticleTexture!=(string)NULL_KEY)return;

    if (g_sLeashParticleMode == "Ribbon") {
        if (llToLower(llGetSubString(sIn,0,6)) == "!ribbon") L_RIBBON_TEX = llGetSubString(sIn, 8, -1);
        else L_RIBBON_TEX = sIn;
        if (GetSetting("rtexture")) g_sLeashParticleTexture = GetSetting("rtexture");

        if (kIn)
            llMessageLinked(LINK_SET,NOTIFY,"0"+"Leash texture set to " + L_RIBBON_TEX,kIn);
    }
    else if (g_sLeashParticleMode == "Classic") {
        if (llToLower(llGetSubString(sIn,0,7)) == "!classic") L_CLASSIC_TEX =  llGetSubString(sIn, 9, -1);
        else L_CLASSIC_TEX = sIn;
        if (GetSetting("ctexture")) g_sLeashParticleTexture = GetSetting("ctexture");

        if (kIn) llMessageLinked(LINK_SET,NOTIFY,"0"+"Leash texture set to " + L_CLASSIC_TEX,kIn);
    } else  if (kIn) llMessageLinked(LINK_SET,NOTIFY,"0"+"Leash texture set to " + g_sParticleTexture,kIn);
    //Debug("particleTextureID= " + (string)g_sLeashParticleTexture);
    //Debug("activeleashpoints= " + (string)g_iLeashActive);
    g_sParticleMode = g_sLeashParticleMode;
    if (g_iLeashActive) {
        if (g_sLeashParticleMode == "noParticle") StopParticles(FALSE);
        else {
            //llWhisper(0, "texture change: restart particles");
            StartParticles(g_kParticleTarget);
        }
    }

}

//Menus

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}


ConfigureMenu(key kIn, integer iAuth) {
    list lButtons;
    lButtons += [Checkbox(g_iParticleGlow, L_GLOW), Checkbox(g_iTurnMode, L_TURN), Checkbox(g_iStrictMode, L_STRICT)];


    if (g_sLeashParticleMode == "Ribbon") lButtons += [Checkbox(FALSE,L_CLASSIC_TEX),Checkbox(TRUE,L_RIBBON_TEX),Checkbox(FALSE, "Invisible")];
    else if (g_sLeashParticleMode == "noParticle") lButtons += [Checkbox(FALSE,L_CLASSIC_TEX),Checkbox(FALSE,L_RIBBON_TEX),Checkbox(TRUE,"Invisible")];
    else if (g_sLeashParticleMode == "Classic")  lButtons += [Checkbox(TRUE,L_CLASSIC_TEX), Checkbox(FALSE, L_RIBBON_TEX), Checkbox(FALSE, "Invisible")];

    lButtons += [L_FEEL, L_COLOR];
    string sPrompt = "\n[Leash Configuration]\n\nCustomize the looks and feel of your leash.";
    Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth,"configure");
}

FeelMenu(key kIn, integer iAuth) {
    list lButtons = ["Bigger", "Smaller", L_DEFAULTS, "Heavier", "Lighter"];
    string sPrompt = "\nHere you can change the weight and size of your leash.";
    Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth,"feel");
}

ColorMenu(key kIn, integer iAuth) {
    string sPrompt = "\nChoose a color.";
    Dialog(kIn, sPrompt, ["colormenu please"], [UPMENU], 0, iAuth,"color");
}

integer LMNotSent=FALSE;
integer g_iGotLMReplies=FALSE;

LMSay() {
    g_iGotLMReplies=FALSE;
    g_iPotentialCoffle=FALSE;
    LMNotSent=TRUE;
    g_kParticleTarget=g_kLeashedTo;
    llResetTime();
    llSetTimerEvent(1.0);
}

DebugOutput(key kID, list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llInstantMessage(kID, llGetScriptName() +final);
}
integer g_iPotentialCoffle=FALSE;

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
    on_rez(integer iRez) {
        llResetScript();
    }

    state_entry() {
        g_kWearer = llGetOwner();
        llListen(g_iChan_LOCKGUARD,"",NULL_KEY,"");     // Lockguard Listener
        llListen(g_iChan_LOCKMEISTER,"",NULL_KEY,"");   // Lockmeister Listener
        FindLinkedPrims();
        StopParticles(TRUE);
        GetSettings(FALSE);
        g_sChainParticleTexture = "4cde01ac-4279-2742-71e1-47ff81cc3529"; // Chain texture for LockGuard
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sMessage, key kMessageID) {
        if (iNum == CMD_PARTICLE) {
            g_kLeashedTo = kMessageID;
            if (sMessage == "unleash") {
                StopParticles(TRUE);
            } else if (g_sLeashParticleMode != "noParticle") {
                integer bLeasherIsAv = (integer)llList2String(llParseString2List(sMessage, ["|"], [""]), 1);
                g_kParticleTarget = g_kLeashedTo;
                //llWhisper(0, "cmd_particle get: start new particles");
                StartParticles(g_kParticleTarget);
                if (bLeasherIsAv) LMSay();
            }
        } else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) {
            if (llToLower(sMessage) == "leash configure") {
                if(iNum <= CMD_TRUSTED || iNum==CMD_WEARER) ConfigureMenu(kMessageID, iNum);
                else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to configuring the leash particles",kMessageID);
            } else if (sMessage == "menu "+SUBMENU) {
                if(iNum <= CMD_TRUSTED || iNum==CMD_WEARER) ConfigureMenu(kMessageID, iNum);
                else {
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to leash configure menu",kMessageID);
                    llMessageLinked(LINK_SET, iNum, "menu "+PARENTMENU, kMessageID);
                }
            } else if (llToLower(sMessage) == "particle reset") {
                g_lSettings = []; // clear current settings
                if (kMessageID) llMessageLinked(LINK_SET,NOTIFY,"0"+"Leash-settings restored to %DEVICETYPE% defaults.",kMessageID);
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "all", "");
                GetSettings(TRUE);
            } else if (llToLower(sMessage) == "theme particle sent")
                GetSettings(TRUE);
        } else if (iNum == MENUNAME_REQUEST && sMessage == PARENTMENU)
            llMessageLinked(iSender, MENUNAME_RESPONSE, PARENTMENU + "|" + SUBMENU, "");
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kMessageID]);
            if (~iMenuIndex) {
                //Debug("Current menu:"+g_sCurrentMenu);
                list lMenuParams = llParseString2List(sMessage, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sButton = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sButton == UPMENU) {
                    if(sMenu == "configure") llMessageLinked(LINK_SET, iAuth, "menu " + PARENTMENU, kAv);
                    else ConfigureMenu(kAv, iAuth);
                } else  if (sMenu == "configure") {
                    string sButtonType = Uncheckbox(sButton);
                    if (sButton == L_COLOR) {
                        ColorMenu(kAv, iAuth);
                        return;
                    } else if (sButton == "feel") {
                        FeelMenu(kAv, iAuth);
                        return;
                    } else if(sButtonType == L_GLOW) {
                        g_iParticleGlow = 1-g_iParticleGlow;
                        SaveSettings(sButtonType, (string)g_iParticleGlow, TRUE);
                    } else if(sButtonType == L_TURN) {
                        g_iTurnMode = 1-g_iTurnMode;
                        if (g_iTurnMode) llMessageLinked(LINK_SET, iAuth, "turn on", kAv);
                        else llMessageLinked(LINK_SET, iAuth, "turn off", kAv);
                    } else if(sButtonType == L_STRICT) {
                        if (!g_iStrictMode) {
                            g_iStrictMode = TRUE;
                            g_iStrictRank = iAuth;
                            llMessageLinked(LINK_SET, iAuth, "strict on", kAv);
                        } else if (iAuth <= g_iStrictRank) {
                            g_iStrictMode = FALSE;
                            g_iStrictRank = iAuth;
                            llMessageLinked(LINK_SET, iAuth, "strict off", kAv);
                        } else llMessageLinked(LINK_SET, NOTIFY,"0%NOACCESS% to changing strict settings",kAv);
                    } else if(sButtonType == L_RIBBON_TEX) {

                        if (!(g_sLeashParticleMode == "Ribbon")) {
                            g_sLeashParticleMode = "Ribbon";
                            SetTexture(g_sRibbonTexture, kAv);
                            SaveSettings("rtexture", g_sRibbonTexture, TRUE);
                        } else {
                            g_sLeashParticleMode = "Classic";
                            SetTexture(g_sClassicTexture, kAv);
                            SaveSettings("ctexture", g_sClassicTexture, TRUE);
                        }
                        SaveSettings("particlemode", g_sLeashParticleMode, TRUE);
                    } else if(sButtonType == L_CLASSIC_TEX) {
                        if (!(g_sLeashParticleMode == "Classic")) {
                            g_sLeashParticleMode = "Classic";
                            SetTexture(g_sClassicTexture, kAv);
                            SaveSettings("ctexture", g_sClassicTexture, TRUE);
                        } else {
                            g_sLeashParticleMode = "Ribbon";
                            SetTexture(g_sRibbonTexture, kAv);
                            SaveSettings("rtexture", g_sRibbonTexture, TRUE);
                        }
                        SaveSettings("particlemode", g_sLeashParticleMode, TRUE);
                    } else if(sButtonType == "Invisible") {
                        if (!(g_sLeashParticleMode=="noParticle")) {
                            g_sLeashParticleMode = "noParticle";
                            g_sParticleTexture = "noleash";
                            SetTexture("noleash", kAv);
                        } else {
                            g_sLeashParticleMode = "Ribbon";
                            SetTexture(g_sRibbonTexture, kAv);
                            SaveSettings("rtexture", g_sRibbonTexture, TRUE);
                        }
                        SaveSettings("particlemode", g_sLeashParticleMode, TRUE);
                    }
                    if (g_sLeashParticleMode != "noParticle" && g_iLeashActive) {
                        //llWhisper(0, "lm get: start particles");
                        StartParticles(g_kParticleTarget);
                    }
                    else if (g_iLeashActive) StopParticles(FALSE);
                    else StopParticles(TRUE);
                    ConfigureMenu(kAv, iAuth);
                } else if (sMenu == "color") {
                    g_vLeashColor = (vector)sButton;
                    SaveSettings(L_COLOR, sButton, TRUE);
                    if (g_sLeashParticleMode != "noParticle" && g_iLeashActive) {
                        //llWhisper(0, "color changed. start particles");
                        StartParticles(g_kParticleTarget);
                    }
                    ColorMenu(kAv, iAuth);
                } else if (sMenu == "feel") {
                    if (sButton == L_DEFAULTS) {
                        if (g_sLeashParticleMode == "Ribbon") g_vLeashSize = (vector)GetDefaultSetting(L_SIZE);
                        else g_vLeashSize = (vector)GetDefaultSetting(L_SIZE) + <0.03,0.03,0.0>;
                        g_vLeashGravity.z = (float)GetDefaultSetting(L_GRAVITY);
                     } else if (sButton == "Bigger") {
                        g_vLeashSize.x +=0.03;
                        g_vLeashSize.y +=0.03;
                    } else if (sButton == "Smaller") {
                        g_vLeashSize.x -=0.03;
                        g_vLeashSize.y -=0.03;
                        if (g_vLeashSize.x < 0.04 && g_vLeashSize.y < 0.04) {
                            g_vLeashSize.x = 0.04 ;
                            g_vLeashSize.y = 0.04 ;
                            llMessageLinked(LINK_SET,NOTIFY,"0"+"The leash won't get much smaller.",kAv);
                        }
                    } else if (sButton == "Heavier") {
                        g_vLeashGravity.z -= 0.1;
                        if (g_vLeashGravity.z < -3.0) {
                            g_vLeashGravity.z = -3.0;
                            llMessageLinked(LINK_SET,NOTIFY,"0"+"That's the heaviest it can be.",kAv);
                        }
                    } else if (sButton == "Lighter") {
                        g_vLeashGravity.z += 0.1;
                        if (g_vLeashGravity.z > 0.0) {
                            g_vLeashGravity.z = 0.0 ;
                            llMessageLinked(LINK_SET,NOTIFY,"0"+"It can't get any lighter now.",kAv);
                        }
                    }
                    SaveSettings(L_GRAVITY, Float2String(g_vLeashGravity.z), TRUE);
                    SaveSettings(L_SIZE, Vec2String(g_vLeashSize), TRUE);
                    if (g_sLeashParticleMode != "noParticle" && g_iLeashActive){
                        //llWhisper(0, "Leash feel changed. start particles");
                        StartParticles(g_kParticleTarget);
                    }
                    FeelMenu(kAv, iAuth);
                }
            //} else {
                //Debug("Not our menu");
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kMessageID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LM_SETTING_RESPONSE) {
           // Debug ("LocalSettingsResponse: " + sMessage);
            integer i = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, i - 1);
            string sValue = llGetSubString(sMessage, i + 1, -1);


            i = llSubStringIndex(sToken, "_");
            if (sToken == "leash_leashedto") {
                g_iLeashActive=TRUE;
                g_kLeashedTo = (key)llList2String(llParseString2List(sValue, [","], []), 0);
            }
            else if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                // load current settings
                //Debug("Setting Response. "+sToken+sValue);
                //llWhisper(0, "Particle settings response: "+sToken+sValue);
                sToken = llGetSubString(sToken, i + 1, -1);
                SaveSettings(sToken, sValue, FALSE);
            } else if (llGetSubString(sToken, 0, i) == "leash_") {
                sToken = llGetSubString(sToken, i + 1, -1);
                //Debug(sToken + sValue);
                if (sToken == "strict") {
                    // Debug((string)iAuth);
                    g_iStrictMode = (integer)llGetSubString(sValue,0,0);
                    g_iStrictRank = (integer)llGetSubString(sValue,2,-1);
                } else if (sToken == "turn") {
                    g_iTurnMode = (integer)sValue;
                } else if(sToken == "leashlength"){
                    g_iLeashLength = (integer)sValue;
                }
            } else if(llGetSubString(sToken,0,i) == "global_"){
                sToken = llGetSubString(sToken,i+1,-1);
                if(sToken == "checkboxes")g_lCheckboxes = llCSV2List(sValue);
            }

                 //else if (sToken == "strictAuthError") {
              //  g_iStrictMode = TRUE;
                //ConfigureMenu(kMessageID, (integer)sValue);
           // }
            // in case wearer is currently leashed
            else if (sMessage == "settings=sent" || sMessage == "theme particle sent")
                GetSettings(TRUE);

        } else if (iNum == REBOOT && sMessage == "reboot") llResetScript();
       /* else if (iNum == LM_SETTING_DELETE) {
            if (sMessage == "leash_leashedto") StopParticles(TRUE);
        }*/
    }

    timer() {
        if(g_iGotLMReplies){
            if(llGetTime()>=60.0){
                LMSay();
            }

            return;
        }

        if (llGetOwnerKey(g_kParticleTarget) == g_kParticleTarget && llGetTime() >= 10.0 || !LMNotSent) { // This only checks if we are leashed to an avatar
            if(g_kLeashedTo) {
                g_iLeashedToAvatar=TRUE;
                llRegionSayTo(g_kLeashedTo,g_iChan_LOCKMEISTER,(string)g_kLeashedTo+"|LMV2|RequestPoint|collar");
                g_kParticleTarget = g_kLeashedTo;
                //llWhisper(0, "start particles from timer");
                StartParticles(g_kParticleTarget);
            }
            else if(!g_iLeashActive) llSetTimerEvent(0.0);
        } else {
            if(llGetTime()< 10.0 || LMNotSent)return;
            if(g_kLeashedTo){
                g_iLeashedToAvatar=FALSE;
                llRegionSayTo(g_kLeashedTo, g_iChan_LOCKMEISTER, (string)g_kLeashedTo+"|LMV2|RequestPoint|collar");
                g_kParticleTarget = g_kLeashedTo;
                //llWhisper(0, "start particles from timer else2");
                StartParticles(g_kParticleTarget);
            } else if(!g_iLeashActive) llSetTimerEvent(0);
        }


        if(llGetTime()>=2.0 && LMNotSent){
            llResetTime();
            LMNotSent=FALSE;

            llRegionSay(g_iChan_LOCKMEISTER, (string)g_kLeashedTo+"collar");
            llRegionSay(g_iChan_LOCKMEISTER, (string)g_kLeashedTo+"handle");
        }

    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChan_LOCKGUARD){
            // Implementation of the Lockguard V2 Protocol
            list lLGCmd = llParseString2List(llToLower(sMessage), [" "],[]);
            if (llList2String(lLGCmd,0) == "lockguard") {
                key kLGAv = llList2Key(lLGCmd,1);           // Request Avatar-UUID
                if (kLGAv != g_kWearer) {                   // Check that wearer is target
                    return; 
                }
                string sLGPoint = llList2String(lLGCmd,2);  // Request ChainPoint
                integer iLeashPrimIndex = llListFindList(g_lLeashPrims, [sLGPoint]);
                if ((iLeashPrimIndex<0) && (sLGPoint != "all")) return; // Invalid chain point
                integer iLeashPrim = llList2Integer(g_lLeashPrims,iLeashPrimIndex+1);
                integer iFCollarPrim =  llList2Integer(g_lLeashPrims,llListFindList(g_lLeashPrims, ["fcollar"])+1);
                key kLGTarget = NULL_KEY;
                integer iLGIndex=3;
                integer iIsLinking = FALSE;

                while (iLGIndex < llGetListLength(lLGCmd)) {
                    string sLGCMD = llList2String(lLGCmd,iLGIndex++);          // Request Command
                    if (sLGCMD == "link") {
                        if (g_iLeashActive && iLeashPrim == iFCollarPrim) return;   // Dont replace leash
                        kLGTarget = llList2Key(lLGCmd,iLGIndex++);             // Request Target
                        // check that we are within leash length
                        integer point = llList2Integer(llGetObjectDetails(kLGTarget, [OBJECT_ATTACHED_POINT]),0);
                        if(point == 0 || !g_iLeashedToAvatar){
                            if(llVecDist(llGetPos(), (vector)llList2String(llGetObjectDetails(kLGTarget, [OBJECT_POS]),0)) > g_iLeashLength){
                                return;
                            }
                        }
                        
                        iIsLinking = TRUE;
                    } else if (sLGCMD == "unlink") {
                        kLGTarget = NULL_KEY;       // Request Target
                        if (sLGPoint == "all") {
                            integer iCPIndex = 0;
                            // loop over collar points and unleash if not leashed to avatar on fcollar
                            while (iCPIndex < llGetListLength(g_lCollarPoints)) {
                                integer iPrimIndex = llListFindList(g_lLeashPrims, [llList2String(g_lCollarPoints,iCPIndex)]);
                                integer iPrim = llList2Integer(g_lLeashPrims,iPrimIndex+1);
                                if (!g_iLeashActive || iPrim != iFCollarPrim) { 
                                    llLinkParticleSystem(iPrim,[]);
                                }
                                iCPIndex += 3;
                            }
                        } else { 
                            if (!g_iLeashActive || iLeashPrim != iFCollarPrim) { 
                                llLinkParticleSystem(iLeashPrim,[]);
                            }
                        }
                    }  else if (sLGCMD == "gravity") {
                        g_vLeashGravity.z = -llList2Float(lLGCmd,iLGIndex++);
                    }  else if (sLGCMD == "life") {
                        g_fParticleAge = llList2Float(lLGCmd,iLGIndex++);
                    }  else if (sLGCMD == "color") {
                        g_vLeashColor.x = llList2Float(lLGCmd,iLGIndex++);
                        g_vLeashColor.y = llList2Float(lLGCmd,iLGIndex++);
                        g_vLeashColor.z = llList2Float(lLGCmd,iLGIndex++);
                    }  else if (sLGCMD == "size") {
                        g_vLeashSize.x = llList2Float(lLGCmd,iLGIndex++);
                        g_vLeashSize.y = llList2Float(lLGCmd,iLGIndex++);
                    }  else if (sLGCMD == "texture") {
                        g_sChainParticleTexture = llList2Key(lLGCmd,iLGIndex++);
                    }  else if (sLGCMD == "ping") {
                        llWhisper( g_iChan_LOCKGUARD, "lockguard " + (string)llGetOwner() + " " +  sLGPoint + " okay" );
                    }  else {
//                        llWhisper(0, "Unknown LockGuard command: "+sLGCMD);
                    }   
                }
                if (iIsLinking) {
                    g_sParticleMode = "Classic";
                    g_sParticleTextureID = g_sChainParticleTexture;
                    Particles(iLeashPrim, kLGTarget,g_vLeashSize);
                }

            }
        } else if (iChannel == g_iChan_LOCKMEISTER) {
            // Implementation of the LMV2 Protocol
            //llWhisper(0, sName+": "+sMessage);
            g_iGotLMReplies=TRUE;
            if(g_kParticleTarget!=g_kLeashedTo)return; // we already have a particle target... rescan in 1 minute
            key kLMKey = (key)llGetSubString(sMessage,0,35);
            list lLMCmd = llParseString2List(sMessage,["|"],[]);

            integer point = llList2Integer(llGetObjectDetails(kID, [OBJECT_ATTACHED_POINT]),0);
            if(point != 0 && g_iLeashedToAvatar){
                if(!g_iPotentialCoffle && (point ==  ATTACH_NECK || point == ATTACH_CHEST)){
                    // potentially a collar
                    g_iPotentialCoffle=TRUE;
                    //llWhisper(0, "Potential coffle detected. Giving other leash holders a chance before accepting");
                    return;
                }
                //llWhisper(0, "Leashed to avatar, and potential leashpoint ("+sName+") is an attachment");
                // this is likely a leash holder
                jump ovLMping;
            }



            // check that we are within leash length
            if(llVecDist(llGetPos(), (vector)llList2String(llGetObjectDetails(kID, [OBJECT_POS]),0)) > g_iLeashLength){
                //llWhisper(0, "Leashpoint: "+sName+" is out of leash length range. Refusing to accept");
                return;
            }

            @ovLMping;
            //llWhisper(0, "proceed with leashpoint: "+sName);
            if (kLMKey == g_kWearer){
                if (llGetListLength(lLMCmd) > 1) {  // A Lockmeister command
                    string sLMCMD = llList2String(lLMCmd,2);
                    string sLMPoint = llList2String(lLMCmd,3);

                    if (llListFindList(g_lLeashPrims,[sLMPoint]) > -1) {
                        if (sLMCMD == "RequestPoint") {
                            key kLink = llGetLinkKey(llList2Integer(g_lLeashPrims, llListFindList(g_lLeashPrims,[sLMPoint])+1));
                            if (kLink != NULL_KEY) llRegionSayTo(kID, g_iChan_LOCKMEISTER,(string)g_kWearer+"|LMV2|ReplyPoint|"+sLMPoint+"|"+(string)kLink);
                        }
                    }
                } else { // A Lockmeister Ping
                    string sLMPoint = llGetSubString(sMessage,36,-1);

                    if (llListFindList(g_lLeashPrims,[sLMPoint]) > -1) {
                        llRegionSayTo(kID, g_iChan_LOCKMEISTER, (string)g_kWearer+sLMPoint+" ok");
                    }
                }
            }

            // Implementation of the Leashholder Handling
            else if(sMessage ==(string)g_kWearer+"collar") llRegionSayTo(kID,g_iChan_LOCKMEISTER,(string)g_kWearer + "collar ok"); // Response to redirect Leash to collar LMV1
            else if(sMessage == (string)g_kWearer+"|LMV2|RequestPoint|collar") { // Response to redirect Leash to collar LMV2
                llRegionSayTo(kID, g_iChan_LOCKMEISTER, (string)g_kWearer+"|LMV2|ReplyPoint|collar|"+(string)llGetLinkKey(llList2Integer(g_lLeashPrims,1)));
            }
            else if (sMessage == (string)g_kLeashedTo + "handle detached") { // Redirect leash to Collar if the holder got detached
                g_kParticleTarget = g_kLeashedTo;
                LMSay();
                //llWhisper(0, "restart particles. handle detached");
                StartParticles(g_kParticleTarget);
                llRegionSayTo(g_kLeashedTo,g_iChan_LOCKMEISTER,(string)g_kLeashedTo+"|LMV2|RequestPoint|collar");
            }
            // We heard from a leash holder. re-direct particles
            if (llGetOwnerKey(kID) == g_kLeashedTo) {
                if(llGetSubString(sMessage,-2,-1)=="ok") {//it's an old style v1 LM reply
                    sMessage = llGetSubString(sMessage, 36, -1);
                    if (sMessage == "collar ok") {
                        g_kParticleTarget = kID;
                        //llWhisper(0, "start particles. collar ok msg got");
                        StartParticles(g_kParticleTarget);
                        llRegionSayTo(g_kLeashedTo,g_iChan_LOCKMEISTER,(string)g_kLeashedTo+"|LMV2|RequestPoint|collar");
                    }
                    if (sMessage == "handle ok") {
                        g_kParticleTarget = kID;
                        //llWhisper(0, "start particles. handle ok got");
                        StartParticles(g_kParticleTarget);
                        //llSetTimerEvent(0.0);
                    }
                }  else {//v2 style LM reply
                    list lTemp = llParseString2List(sMessage,["|"],[""]);
                    // lTemp should look like [g_kLeashto,"LMV2","ReplyPoint","handle",g_kParticleTarget]
                    // is it a v2 style LM reply?
                    if(llList2String(lTemp,1)=="LMV2" && llList2String(lTemp,2)=="ReplyPoint") {
                        g_kParticleTarget = (key)llList2String(lTemp,4);
                        //llWhisper(0, "LMv2 : start particles to new replypoint");
                        StartParticles(g_kParticleTarget);
                    }
                }
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            integer iNumberOfTextures = llGetInventoryNumber(INVENTORY_TEXTURE);
            integer iLeashTexture;
            if (iNumberOfTextures) {
                for (g_iLoop =0 ; g_iLoop < iNumberOfTextures; ++g_iLoop) {
                    string sName = llGetInventoryName(INVENTORY_TEXTURE, g_iLoop);
                    if (llToLower(llGetSubString(sName,0,6)) == "!ribbon") {
                        g_sRibbonTexture = sName;
                        L_RIBBON_TEX = llGetSubString(g_sRibbonTexture, 8, -1);
                        SaveSettings("rtexture", g_sRibbonTexture, TRUE);
                        iLeashTexture = iLeashTexture +1;
                    }
                    else if (llToLower(llGetSubString(sName,0,7)) == "!classic") {
                        g_sClassicTexture = sName;
                        L_CLASSIC_TEX = llGetSubString(g_sClassicTexture, 9, -1);
                        SaveSettings("ctexture", g_sClassicTexture, TRUE);
                        iLeashTexture = iLeashTexture +2;
                    }
                }
            }
            if (!iLeashTexture) {
                if (llSubStringIndex(GetSetting("ctexture"), "!")==0) SaveSettings("ctexture", "Chain", TRUE);
                if (llSubStringIndex(GetSetting("rtexture"), "!")==0) SaveSettings("rtexture", "Silk", TRUE);
            } else if (iLeashTexture == 1) {
                if (llSubStringIndex(GetSetting("ctexture"), "!")==0) SaveSettings("ctexture", "Chain", TRUE);
            } else if (iLeashTexture == 2) {
                if (llSubStringIndex(GetSetting("rtexture"), "!")==0) SaveSettings("rtexture", "Silk", TRUE);
            }
           // GetSettings(TRUE);
        }
      /*  if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }

}
