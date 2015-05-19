////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           OpenCollar - leashParticle                           //
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

//Split from the leash script in April 2010 by Garvin Twine
//Nandana Singh, Lulu Pink, Joy Stipe, Wendy Starfall
//Medea Destiny, Jean Severine, littlemousy, Romka Swallowtail

// - MESSAGE MAP
//integer COMMAND_NOAUTH      = 0;
integer COMMAND_OWNER       = 500;
integer COMMAND_SECOWNER    = 501;
//integer COMMAND_GROUP       = 502;
integer COMMAND_WEARER      = 503;
//integer COMMAND_EVERYONE    = 504;
//integer COMMAND_SAFEWORD    = 510;
//integer POPUP_HELP          = 1001;
// -- SETTINGS
// - Setting strings must be in the format: "token=value"
integer LM_SETTING_SAVE             = 2000; // to have settings saved to settings store
//integer LM_SETTING_REQUEST          = 2001; // send requests for settings on this channel
integer LM_SETTING_RESPONSE         = 2002; // responses received on this channel
integer LM_SETTING_DELETE           = 2003; // delete token from store
//integer LM_SETTING_EMPTY            = 2004; // returned when a token has no value in the store
// -- MENU/DIALOG
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
//integer MENUNAME_REMOVE     = 3003;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

integer LOCKMEISTER         = -8888;
//integer LOCKGUARD           = -9119;
integer g_iLMListener;
integer g_iLMListernerDetach;

integer COMMAND_PARTICLE = 20000;
integer COMMAND_LEASH_SENSOR = 20001;

list g_lColors = [
"Magenta",<1.00000, 0.00000, 0.50196>, "Pink",<1.00000, 0.14902, 0.50980>, "Hot Pink",<1.00000, 0.05490, 0.72157>,
"Firefighter",<0.88627, 0.08627, 0.00392>, "Sun",<1.00000, 1.00000, 0.18039>, "Flame",<0.92941, 0.43529, 0.00000>,
"Matrix",<0.07843, 1.00000, 0.07843>, "Electricity",<0.00000, 0.46667, 0.92941>, "Violet Wand",<0.63922, 0.00000, 0.78824>,

"Baby Blue",<0.75686, 0.75686, 1.00000>, "Wasabi",<0.47059, 1.00000, 0.65098>, "Lavender",<0.89020, 0.65882, 0.99608>,
"Baby Pink",<1.00000, 0.52157, 0.76078>, "Rose",<0.93333, 0.64314, 0.72941>, "Beige",<0.86667, 0.78039, 0.71765>,
"Earth",<0.39608, 0.27451, 0.18824>, "Ocean",<0.25882, 0.33725, 0.52549>, "Yolk",<0.98824, 0.73333, 0.29412>,

"Black",<0.00000, 0.00000, 0.00000>, "White",<1.00000, 1.00000, 1.00000>
];
// ----- collar -----
//string g_sWearerName;

// --- menu tokens ---
string UPMENU       = "BACK";
string PARENTMENU   = "Leash";
string SUBMENU      = "Configure";
string L_TEXTURE    = "Texture";
string L_COLOR      = "Color";
string L_GRAVITY    = "Gravity";
string L_SIZE       = "Size";
string L_FEEL       = "Feel";
string L_GLOW       = "Shine";
string L_STRICT     = "Strict";
string L_TURN       = "Turn";
string L_DEFAULTS   = "RESET";
string L_CLASSIC_TEX= "Chain"; //texture name when using the classic particle stream
string L_RIBBON_TEX = "Silk"; //texture name when using the ribbon_mask particle stream
string L_COSTUM_TEX_ID;
// Defalut leash particle, can read from defaultsettings:
// User_leashParticle=Shine~1~Turn~1~Strict~1~ParticleMode~Ribbon~R_Texture~Silk~C_Texture~Chain~Color~<1,1,1>~Size~<0.07,0.07,1.0>~Gravity~-0.7~C_TextureID~keyID~R_TextureID~keyID
list g_lDefaultSettings = [L_GLOW,"1",L_TURN,"0",L_STRICT,"0","ParticleMode","Ribbon","R_Texture","Silk","C_Texture","Chain",L_COLOR,"<1.0,1.0,1.0>",L_SIZE,"<0.04,0.04,1.0>",L_GRAVITY,"-1.0"]; 

list g_lSettings=g_lDefaultSettings;

string g_sCurrentMenu = "";
key g_kDialogID;
string g_sDeviceType = "collar";
key g_kWearer;

string g_sAuthError = "Access denied.";

key NULLKEY = "";
key g_kLeashedTo = ""; //NULLKEY;
key g_kLeashToPoint = ""; //NULLKEY;
key g_kParticleTarget = ""; //NULLKEY;
integer g_iLeasherInRange;
integer g_iAwayCounter;

integer g_iLeashActive;
integer g_iTurnMode;
integer g_iStrictMode;
string g_sParticleMode = "Ribbon"; //modes can be: Ribbon, Classic and noParticle
string g_sRibbonTexture;
string g_sClassicTexture;
//List of 4 leash/chain points, lockmeister names used (list has to be all lower case, prims dont matter, converting on compare to lower case)
//strided list... LM name, linkNumber, BOOL_ACVTIVE
list g_lLeashPrims;

//global integer used for loops
integer g_iLoop;
string g_sScript;

//Particle system and variables

string g_sParticleTexture = "Silk";
string g_sParticleTextureID; //we need the UUID for llLinkParticleSystem
vector g_vLeashColor = <1.00000, 1.00000, 1.00000>;
vector g_vLeashSize = <0.04, 0.04, 1.0>;   
integer g_iParticleGlow = TRUE;
float g_fParticleAge = 3.0;
float g_fParticleAlpha = 1.0;
vector g_vLeashGravity = <0.0,0.0,-1.0>;
integer g_iParticleCount = 1;
float g_fBurstRate = 0.0;
//same g_lSettings but to store locally the default settings recieved from the defaultsettings note card, using direct string here to save some bits

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

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    //Debug("Made menu.");
    return kID;
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

FindLinkedPrims() {
    integer linkcount = llGetNumberOfPrims();
    //root prim is 1, so start at 2
    for (g_iLoop = 2; g_iLoop <= linkcount; g_iLoop++) {
        string sPrimDesc = (string)llGetObjectDetails(llGetLinkKey(g_iLoop), [OBJECT_DESC]);
        list lTemp = llParseString2List(sPrimDesc, ["~"], []);
        integer iLoop;
        for (iLoop = 0; iLoop < llGetListLength(lTemp); iLoop++) {
            string sTest = llList2String(lTemp, iLoop);
            //Debug(sTest);
            //expected either "leashpoint" or "leashpoint:point"
            if (llGetSubString(sTest, 0, 9) == "leashpoint") {
                if (llGetSubString(sTest, 11, -1) == "") g_lLeashPrims += [sTest, (string)g_iLoop, "1"];
                else g_lLeashPrims += [llGetSubString(sTest, 11, -1), (string)g_iLoop, "1"];
            }
        }
    }
    //if we did not find any leashpoint... we unset the root as one
    if (!llGetListLength(g_lLeashPrims)) g_lLeashPrims = ["collar", LINK_THIS, "1"];
}

Particles(integer iLink, key kParticleTarget)
{
    //when we have no target to send particles to, dont create any
    if (kParticleTarget == NULLKEY) return;
    //taken out as vars to save memory
    //float fMaxSpeed = 3.0;          // Max speed each particle is spit out at
    //float fMinSpeed = 3.0;          // Min speed each particle is spit out at
    //these values do nothing when particles go to a target, the speed is determined by the particle age then
    integer iFlags = PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_SRC_MASK;
    
    if (g_sParticleMode == "Ribbon") iFlags = iFlags | PSYS_PART_RIBBON_MASK;
    if (g_iParticleGlow) iFlags = iFlags | PSYS_PART_EMISSIVE_MASK;

    list lTemp = [
        PSYS_PART_MAX_AGE,g_fParticleAge,
        PSYS_PART_FLAGS,iFlags,
        PSYS_PART_START_COLOR, g_vLeashColor,
        //PSYS_PART_END_COLOR, g_vLeashColor,
        PSYS_PART_START_SCALE,g_vLeashSize,
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
        //PSYS_PART_START_ALPHA, g_fParticleAlpha,
        //PSYS_PART_END_ALPHA, g_fParticleAlpha
        ];
    llLinkParticleSystem(iLink, lTemp);
}

StartParticles(key kParticleTarget) {
    //Debug(llList2CSV(g_lLeashPrims));
    StopParticles(FALSE);
    for (g_iLoop = 0; g_iLoop < llGetListLength(g_lLeashPrims); g_iLoop = g_iLoop + 3) {
        if ((integer)llList2String(g_lLeashPrims, g_iLoop + 2)) {
            Particles((integer)llList2String(g_lLeashPrims, g_iLoop + 1), kParticleTarget);
           if (g_sParticleMode == "Classic") g_iLoop = g_iLoop + 3;
        }
    }
    g_iLeashActive = TRUE;
}

StopParticles(integer iEnd) {
    for (g_iLoop = 0; g_iLoop < llGetListLength(g_lLeashPrims); g_iLoop++) {
        llLinkParticleSystem((integer)llList2String(g_lLeashPrims, g_iLoop + 1), []);
    }
    if (iEnd) {
        g_iLeashActive = FALSE;
        g_kLeashedTo = NULLKEY;
        g_kLeashToPoint = NULLKEY;
        g_kParticleTarget = NULLKEY;
        llSensorRemove();
    }
}

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

SaveSettings(string sToken, string sValue, integer iSaveToLocal, integer iAuth, key kAv) {
    integer iIndex = llListFindList(g_lSettings, [sToken]);
    if (iIndex>=0) g_lSettings = llListReplaceList(g_lSettings, [sValue], iIndex +1, iIndex +1);
    else g_lSettings += [sToken, sValue];
    if (sToken == L_STRICT) {
        if ((integer)sValue) llMessageLinked(LINK_SET, iAuth, "strict on", kAv);
        else  llMessageLinked(LINK_SET, iAuth, "strict off", kAv);
    }
    else if (sToken == L_TURN) {
         if ((integer)sValue) llMessageLinked(LINK_SET, iAuth, "turn on", kAv);
         else llMessageLinked(LINK_SET, iAuth, "turn off", kAv);
    }
    else if (sToken == "R_Texture") L_RIBBON_TEX == sValue;
    else if (sToken == "C_Texture") L_CLASSIC_TEX == sValue;    
    if (iSaveToLocal) llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + sToken + "=" + sValue, "");
}

SaveDefaultSettings(string sToken, string sValue) {
    integer index = llListFindList(g_lDefaultSettings, [sToken]);
    if (index>=0) g_lDefaultSettings = llListReplaceList(g_lDefaultSettings, [sValue], index+1, index+1);
    else g_lDefaultSettings += [sToken, sValue];
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

// get settings before StartParticles
GetSettings(integer iStartParticles) {
   // Debug("settings: "+llList2CSV(g_lSettings));
    g_sParticleMode = GetSetting("ParticleMode");
    g_sClassicTexture = GetSetting("C_Texture");
    g_sRibbonTexture = GetSetting("R_Texture");
    g_vLeashSize = (vector)GetSetting(L_SIZE);
    g_vLeashColor = (vector)GetSetting(L_COLOR);
    g_vLeashGravity.z = (float)GetSetting(L_GRAVITY);
    g_iParticleGlow = (integer)GetSetting(L_GLOW);
    g_iTurnMode = (integer)GetSetting(L_TURN);
    g_iStrictMode = (integer)GetSetting(L_STRICT);
    if (g_sParticleMode == "Classic") SetTexture(g_sClassicTexture, NULLKEY);
    else if (g_sParticleMode == "Ribbon") SetTexture(g_sRibbonTexture, NULLKEY);
    if (iStartParticles &&  g_kLeashedTo != NULLKEY){
        llSleep(0.1);
        StartParticles(g_kParticleTarget);
    }
}

// Added bSave as a boolean, to make this a more versatile wrapper
SetTexture(string sIn, key kIn) {
    g_sParticleTexture = sIn;
    if (sIn=="Silk") g_sParticleTextureID="cdb7025a-9283-17d9-8d20-cee010f36e90";
    else if (sIn=="Chain") g_sParticleTextureID="4cde01ac-4279-2742-71e1-47ff81cc3529";
    else if (sIn=="Leather") g_sParticleTextureID="8f4c3616-46a4-1ed6-37dc-9705b754b7f1";
    else if (sIn=="Rope") g_sParticleTextureID="9a342cda-d62a-ae1f-fc32-a77a24a85d73";
    else if (sIn=="totallytransparent") g_sParticleTextureID="bd7d7770-39c2-d4c8-e371-0342ecf20921";
    else {
        if (llToLower(g_sParticleTexture) == "noleash") g_sParticleMode = "noParticle"; 
        //Debug("particleTexture= " + sIn);
        g_sParticleTextureID = llGetInventoryKey(g_sParticleTexture);
        if(g_sParticleTextureID == NULL_KEY) g_sParticleTextureID=sIn; //for textures without full perm, we send the texture name. For this to work, texture must be in the emitter prim as well as in root, if different.
    }        
    if (g_sParticleMode == "Ribbon") {
        if (llToLower(llGetSubString(sIn,0,6)) == "!ribbon") L_RIBBON_TEX = llGetSubString(sIn, 8, -1);
        else L_RIBBON_TEX = sIn;
        if (GetSetting("R_TextureID")) g_sParticleTextureID = GetSetting("R_TextureID");
        if (kIn) Notify(kIn, "Leash texture set to " + L_RIBBON_TEX, FALSE);
    }
    else if (g_sParticleMode == "Classic") {
        if (llToLower(llGetSubString(sIn,0,7)) == "!classic") L_CLASSIC_TEX =  llGetSubString(sIn, 9, -1);
        else L_CLASSIC_TEX = sIn;
        if (GetSetting("C_TextureID")) g_sParticleTextureID = GetSetting("C_TextureID");
        if (kIn) Notify(kIn, "Leash texture set to " + L_CLASSIC_TEX, FALSE);
    } else  if (kIn) Notify(kIn, "Leash texture set to " + g_sParticleTexture, FALSE);
    //Debug("particleTextureID= " + (string)g_sParticleTextureID);
    //Debug("activeleashpoints= " + (string)g_iLeashActive);
    if (g_iLeashActive) {
        if (g_sParticleMode == "noParticle") StopParticles(FALSE);
        else StartParticles(g_kParticleTarget);
    }
}

integer KeyIsAv(key id) {
    return llGetAgentSize(id) != ZERO_VECTOR;
}

//Menus

ConfigureMenu(key kIn, integer iAuth) {
    g_sCurrentMenu = SUBMENU;
    list lButtons; 
    if (g_iParticleGlow) lButtons += "☑ Shine";
    else lButtons += "☐ Shine";
    if (g_iTurnMode) lButtons += "☑ Turn";
    else lButtons += "☐ Turn";
    if (g_iStrictMode) lButtons += "☑ Strict";
    else lButtons += "☐ Strict";
    if (g_sParticleMode == "Ribbon") lButtons += ["☐ "+L_CLASSIC_TEX,"☒ "+L_RIBBON_TEX,"☐ Invisible"];
    else if (g_sParticleMode == "noParticle") lButtons += ["☐ "+L_CLASSIC_TEX,"☐ "+L_RIBBON_TEX,"☒ Invisible"];
    else if (g_sParticleMode == "Classic")  lButtons += ["☒ "+L_CLASSIC_TEX,"☐ "+L_RIBBON_TEX,"☐ Invisible"];
    
    lButtons += [L_FEEL, L_COLOR];
    string sPrompt = "\nCustomize the looks and feel of your leash.";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

FeelMenu(key kIn, integer iAuth) {
    list lButtons = ["Bigger", "Smaller", L_DEFAULTS, "Heavier", "Lighter"];
    g_sCurrentMenu = L_FEEL;
    vector defaultsize = (vector)GetDefaultSetting(L_SIZE);    
    string sPrompt = "\nHere you can change the weight and size of your leash.";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

ColorMenu(key kIn, integer iAuth) {
    string sPrompt = "\nChoose a color.";
    list lButtons =llList2ListStrided(g_lColors,0,-1,2);
    g_sCurrentMenu = L_COLOR;
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

LMSay() {
    llShout(LOCKMEISTER, (string)llGetOwnerKey(g_kLeashedTo) + "collar");
    llShout(LOCKMEISTER, (string)llGetOwnerKey(g_kLeashedTo) +  "handle");
}

default {
    on_rez(integer iRez) {
        llResetScript();
    }

    state_entry() {
        llSetMemoryLimit(57344);  //2015-05-06 (7884 bytes free)
        g_sScript = "leashparticle_";
        g_kWearer = llGetOwner();
        FindLinkedPrims();
        StopParticles(TRUE);
        GetSettings(FALSE);    
        llListen(COMMAND_PARTICLE,"","","");    // ADDED FOR BETA 0.1
        //Debug("Starting");
    }
    
    link_message(integer iSenderPrim, integer iNum, string sMessage, key kMessageID) {
        if (iNum == COMMAND_PARTICLE) {
            g_kLeashedTo = kMessageID;
            if (sMessage == "unleash") {
                StopParticles(TRUE);
                llListenRemove(g_iLMListener);
                llListenRemove(g_iLMListernerDetach);
            }
            else {
                //Debug("leash active");
                if (g_sParticleMode != "noParticle") {
                    integer bLeasherIsAv = (integer)llList2String(llParseString2List(sMessage, ["|"], [""]), 1);
                    g_kParticleTarget = g_kLeashedTo;
                    StartParticles(g_kParticleTarget);
                    if (bLeasherIsAv) {
                        llListenRemove(g_iLMListener);
                        llListenRemove(g_iLMListernerDetach);
                        if (llGetSubString(sMessage, 0, 10)  == "leashhandle") {
                            g_iLMListener = llListen(LOCKMEISTER, "", "", (string)g_kLeashedTo + "handle ok");
                            g_iLMListernerDetach = llListen(LOCKMEISTER, "", "", (string)g_kLeashedTo + "handle detached");
                        }
                        else  g_iLMListener = llListen(LOCKMEISTER, "", "", "");

                        LMSay();
                    }
                }
            }
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER) {
            if (llToLower(sMessage) == llToLower(SUBMENU)) {
                if(iNum <= COMMAND_SECOWNER || iNum==COMMAND_WEARER) ConfigureMenu(kMessageID, iNum);
                else Notify(kMessageID,g_sAuthError, FALSE);
            }
            else if (sMessage == "menu "+SUBMENU) {
                if(iNum == COMMAND_OWNER || iNum==COMMAND_WEARER) ConfigureMenu(kMessageID, iNum);
                else {
                    Notify(kMessageID,g_sAuthError, FALSE);
                    llMessageLinked(LINK_SET, iNum, "menu "+PARENTMENU, kMessageID);
                }
            }
            else if (llToLower(sMessage) == "leashparticle reset") {
                g_lSettings = []; // clear current settings
                if (kMessageID) Notify(kMessageID, "Leash-settings restored to " + g_sDeviceType + " defaults.", FALSE);
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "all", "");
                GetSettings(TRUE); 
            }
        }
        else if (iNum == MENUNAME_REQUEST && sMessage == PARENTMENU) {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENTMENU + "|" + SUBMENU, "");
        }
        else if (iNum == DIALOG_RESPONSE) {
            if (kMessageID == g_kDialogID) {
                //Debug("Current menu:"+g_sCurrentMenu);
                list lMenuParams = llParseString2List(sMessage, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sButton = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sButton == UPMENU) {
                    if(g_sCurrentMenu == SUBMENU) llMessageLinked(LINK_SET, iAuth, "menu " + PARENTMENU, kAv);
                    else ConfigureMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == SUBMENU) {
                    string sButtonType = llGetSubString(sButton,2,-1);
                    string sButtonCheck = llGetSubString(sButton,0,0);
                    if (sButton == L_COLOR) {
                        ColorMenu(kAv, iAuth);
                        return;
                    } else if (sButton == "Feel") {
                        FeelMenu(kAv, iAuth);
                        return;
                    } else if(sButtonType == L_GLOW) {
                        if (sButtonCheck == "☐") g_iParticleGlow = TRUE;
                        else g_iParticleGlow = FALSE;
                        SaveSettings(sButtonType, (string)g_iParticleGlow, TRUE, 0, "");
                    } else if(sButtonType == L_TURN) {
                        if (sButtonCheck == "☐") g_iTurnMode = TRUE;
                        else g_iTurnMode = FALSE;
                        SaveSettings(sButtonType, (string)g_iTurnMode, FALSE, iAuth, kAv);
                    } else if(sButtonType == L_STRICT) {
                        if (sButtonCheck == "☐")  g_iStrictMode = TRUE;
                        else g_iStrictMode = FALSE;
                        SaveSettings(sButtonType, (string)g_iStrictMode, FALSE, iAuth, kAv);
                        return;
                    } else if(sButtonType == L_RIBBON_TEX) {
                        if (sButtonCheck == "☐") {
                            g_sParticleMode = "Ribbon"; 
                            SetTexture(g_sRibbonTexture, kAv);
                            SaveSettings("R_Texture", g_sRibbonTexture, TRUE,0,"");
                        } else {
                            g_sParticleMode = "Classic";
                            SetTexture(g_sClassicTexture, kAv);
                            SaveSettings("C_Texture", g_sClassicTexture, TRUE,0,"");
                        }
                        SaveSettings("ParticleMode",g_sParticleMode , TRUE,0,"");
                    } else if(sButtonType == L_CLASSIC_TEX) {
                        if (sButtonCheck == "☐") {
                            g_sParticleMode = "Classic";
                            SetTexture(g_sClassicTexture, kAv);
                            SaveSettings("C_Texture", g_sClassicTexture, TRUE,0,"");
                        } else {
                            g_sParticleMode = "Ribbon";
                            SetTexture(g_sRibbonTexture, kAv);
                            SaveSettings("R_Texture", g_sRibbonTexture, TRUE,0,"");
                        }
                        SaveSettings("ParticleMode", g_sParticleMode, TRUE,0,"");
                    } else if(sButtonType == "Invisible") {
                        if (sButtonCheck == "☐") {
                            g_sParticleMode = "noParticle";
                            g_sParticleTexture = "noleash";
                            SetTexture("noleash", kAv);
                        } else {
                            g_sParticleMode = "Ribbon";
                            SetTexture(g_sRibbonTexture, kAv);
                            SaveSettings("R_Texture", g_sRibbonTexture, TRUE,0,"");
                        }
                        SaveSettings("ParticleMode", g_sParticleMode, TRUE,0,"");
                    }
                    if (g_sParticleMode != "noParticle" && g_iLeashActive) StartParticles(g_kParticleTarget);
                    else if (g_iLeashActive) StopParticles(FALSE);
                    else StopParticles(TRUE);
                    ConfigureMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_COLOR) {
                    integer iIndex = llListFindList(g_lColors, [sButton]) +1;
                    llOwnerSay((string)llList2Vector(g_lColors, iIndex));
                    if (iIndex) {
                        g_vLeashColor = llList2Vector(g_lColors, iIndex);
                        SaveSettings(L_COLOR, Vec2String(g_vLeashColor), TRUE,0,"");
                    }
                    if (g_sParticleMode != "noParticle" && g_iLeashActive) StartParticles(g_kParticleTarget);

                    ColorMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_FEEL) {
                    if (sButton == L_DEFAULTS) {
                        if (g_sParticleMode == "Ribbon") g_vLeashSize = (vector)GetDefaultSetting(L_SIZE);
                        else g_vLeashSize = (vector)GetDefaultSetting(L_SIZE) + <0.03,0.03,0.0>;
                        g_vLeashGravity.z = (float)GetDefaultSetting(L_GRAVITY);
                     } 
                     else if (sButton == "Bigger") {
                        g_vLeashSize.x +=0.03;
                        g_vLeashSize.y +=0.03;
                    }
                    else if (sButton == "Smaller") {
                        g_vLeashSize.x -=0.03;
                        g_vLeashSize.y -=0.03;                        
                        if (g_vLeashSize.x < 0.04 && g_vLeashSize.y < 0.04) {
                            g_vLeashSize.x = 0.04 ;
                            g_vLeashSize.y = 0.04 ;
                            Notify(kAv, "The leash won't get much smaller.", FALSE);
                        }
                    }
                    else if (sButton == "Heavier") {
                        g_vLeashGravity.z -= 0.1;
                        if (g_vLeashGravity.z < -3.0) {
                            g_vLeashGravity.z = -3.0;
                            Notify(kAv, "That's the heaviest it can be.", FALSE);
                        } 
                    }
                    else if (sButton == "Lighter") {
                        g_vLeashGravity.z += 0.1;
                        if (g_vLeashGravity.z > 0.0) {
                            g_vLeashGravity.z = 0.0 ;
                            Notify(kAv, "It can't get any lighter now.", FALSE);
                        }
                    }
                    SaveSettings(L_GRAVITY, Float2String(g_vLeashGravity.z), TRUE,0,"");
                    SaveSettings(L_SIZE, Vec2String(g_vLeashSize), TRUE,0,"");
                    if (g_sParticleMode != "noParticle" && g_iLeashActive) StartParticles(g_kParticleTarget);
                    FeelMenu(kAv, iAuth);
                }

            } else {
                //Debug("Not our menu");
            }
        }
        else if (iNum == LM_SETTING_RESPONSE) {
           // Debug ("LocalSettingsResponse: " + sMessage);
            integer i = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, i - 1);
            string sValue = llGetSubString(sMessage, i + 1, -1);
            i = llSubStringIndex(sToken, "_");
            if (sToken == "leash_leashedto") g_kLeashedTo = (key)llList2String(llParseString2List(sValue, [","], []), 0);
            else if (llGetSubString(sToken, 0, i) == g_sScript) {
                // load current settings
                //Debug("Setting Response. "+sToken+sValue);
                sToken = llGetSubString(sToken, i + 1, -1);
                SaveSettings(sToken, sValue, FALSE,0,"");
             //   SaveDefaultSettings(sToken, sValue);
            }
            else if (llGetSubString(sToken, 0, i) == "leash_") {
                sToken = llGetSubString(sToken, i + 1, -1);
                //Debug(sToken + sValue);
                if (sToken == "strict"){
                    integer iAuth = (integer)llGetSubString(sValue, 2, 4);
                   // Debug((string)iAuth);
                    sValue = llGetSubString(sValue, 0, 0);
                    g_iStrictMode = (integer)sValue;
                    SaveSettings("Strict", sValue, FALSE,0,"");
                  //  SaveDefaultSettings("Strict", sValue);
                    ConfigureMenu(kMessageID, iAuth);
                } else if (sToken == "turn") {
                    g_iTurnMode = (integer)sValue;
                    SaveSettings("Turn", sValue, FALSE,0,"");
                 //   SaveDefaultSettings("Turn", sValue);
                }
            }
            else if (sToken == "strictAuthError"){
                g_iStrictMode = TRUE;
                ConfigureMenu(kMessageID, (integer)sValue);
            }
            else if (sToken == "Global_DeviceType") g_sDeviceType = sValue;
            // in case wearer is currently leashed
            else if (sMessage == "settings=sent") {
                GetSettings(TRUE);
            }
        }
        else if (iNum == LM_SETTING_DELETE) {
            if (sMessage == "leash_leashedto") StopParticles(TRUE);
        }
    }
    listen(integer iChannel, string sName, key kID, string sMessage)
    {
        if (iChannel == LOCKMEISTER) {
            //leash holder announced it got detached... send particles to avi
            if (sMessage == (string)g_kLeashedTo + "handle detached") {
                g_kParticleTarget = g_kLeashedTo;
                StartParticles(g_kParticleTarget);
            }
            // We heard from a leash holder. re-direct particles
            if (llGetOwnerKey(kID) == g_kLeashedTo) {
                sMessage = llGetSubString(sMessage, 36, -1);
                if (sMessage == "collar ok") {
                    g_kParticleTarget = kID;
                    StartParticles(g_kParticleTarget);
                }
                if (sMessage == "handle ok") {
                    g_kParticleTarget = kID;
                    StartParticles(g_kParticleTarget);
                }
            }
        }
        // ADDED BELOW FOR BETA 0.1  TOGGLES LEASH PARTICLES OFF IF COFFLES BEING USED.        
        else if(iChannel == COMMAND_PARTICLE) {
            if(llGetOwnerKey(kID) == g_kWearer) {
                integer currentglow;
                if(sMessage == "noLeash") {
                    currentglow = g_iParticleGlow;
                    g_iParticleGlow = FALSE;
                    SetTexture(sMessage, g_kWearer);
                    StartParticles(g_kParticleTarget);
                }
                if(sMessage == "Leather") {
                    g_iParticleGlow = currentglow;
                    SetTexture(sMessage, g_kWearer);
                    StartParticles(g_kParticleTarget);
                }      
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            integer iNumberOfTextures = llGetInventoryNumber(INVENTORY_TEXTURE);
            integer iLeashTexture;
            if (iNumberOfTextures) {
                for (g_iLoop =0 ; g_iLoop < iNumberOfTextures; ++g_iLoop){
                    string sName = llGetInventoryName(INVENTORY_TEXTURE, g_iLoop);
                    if (llToLower(llGetSubString(sName,0,6)) == "!ribbon") {
                        g_sRibbonTexture = sName;
                        L_RIBBON_TEX = llGetSubString(g_sRibbonTexture, 8, -1);
                        SaveSettings("R_Texture", g_sRibbonTexture, TRUE,0,"");
                        iLeashTexture = iLeashTexture +1;
                    }
                    else if (llToLower(llGetSubString(sName,0,7)) == "!classic"){
                        g_sClassicTexture = sName;
                        L_CLASSIC_TEX = llGetSubString(g_sClassicTexture, 9, -1);
                        SaveSettings("C_Texture", g_sClassicTexture, TRUE,0,"");
                        iLeashTexture = iLeashTexture +2;
                    }
                }
            } 
            if (!iLeashTexture) {
                if (llSubStringIndex(GetSetting("C_Texture"), "!")==0) SaveSettings("C_Texture", "Chain", TRUE,0,"");
                if (llSubStringIndex(GetSetting("R_Texture"), "!")==0) SaveSettings("R_Texture", "Silk", TRUE,0,"");
            } else if (iLeashTexture == 1) {
                if (llSubStringIndex(GetSetting("C_Texture"), "!")==0) SaveSettings("C_Texture", "Chain", TRUE,0,"");
            } else if (iLeashTexture == 2) {
                if (llSubStringIndex(GetSetting("R_Texture"), "!")==0) SaveSettings("R_Texture", "Silk", TRUE,0,"");
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
