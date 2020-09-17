// This file is part of OpenCollar.
// Copyright (c) 2020 Reuben Shaffer II (aka Madman Magnifico).
// Licensed under the GPLv2.  See LICENSE for full details. 

// This is a full rewrite for OC v8
// I'm going to implement only the particle chains
// for the leash and LockGuard/LockMeister chains.

// It seems like the configuration menu may be better
// in oc_leash, since it shows as a submenu of Leash.

// These are some pretty standard OC core constants:
string g_sParentMenu = "Leash"; 
string g_sSubMenu = "Configure";
string COLLAR_VERSION = "8.0.0008"; // Provide enough room
// LEGEND: Major.Minor.Build RC Beta Alpha
integer UPDATE_AVAILABLE=FALSE;
string NEW_VERSION = "";
integer g_iAmNewer=FALSE;
integer g_iChannel=1;
string g_sPrefix;

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
//integer g_iLeashedToAvatar=FALSE;

//integer POPUP_HELP          = 1001;
integer NOTIFY              = 1002;
//integer SAY                 = 1004;
integer REBOOT              = -1000;
// -- SETTINGS
integer LM_SETTING_SAVE     = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE   = 2003;
//integer LM_SETTING_EMPTY            = 2004;
// -- MENU/DIALOG
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
//integer MENUNAME_REMOVE  = 3003;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

// standard LockMeister and LockGuard channels
integer g_iChan_LOCKMEISTER = -8888;
integer g_iChan_LOCKGUARD   = -9119;
//integer g_iLMListener;
//integer g_iLMListernerDetach;

string UPMENU = "BACK";

integer CMD_PARTICLE = 20000;

// not sure if I will use this - borrowed from earlier version
//list g_lDefaultSettings = [L_GLOW,"1",L_TURN,"0",L_STRICT,"0","particlemode","Ribbon","rtexture","Silk","ctexture","Chain",L_COLOR,"<1.0,1.0,1.0>",L_SIZE,"<0.04,0.04,1.0>",L_GRAVITY,"-1.0"];

// default particle textures
key g_kDefaultChain = "245ea72d-bc79-fee3-a802-8e73c0f09473";
key g_kDefaultSilk = "cdb7025a-9283-17d9-8d20-cee010f36e90";
key g_kDefaultRope = "9a342cda-d62a-ae1f-fc32-a77a24a85d73";
key g_kDefaultLeather = "8f4c3616-46a4-1ed6-37dc-9705b754b7f1";

// For particle settings, this is what I shall use:
// [key texture, vector size, float life, float gravity, vector color, integer glow, integer ribbon]
list g_lLeashSettings = [g_kDefaultChain, <0.0625, 0.0625, 1.0>, 1.0, -0.5, <1.0, 1.0, 1.0>, FALSE, FALSE];
/*
    So, we can configure the leash settings here in the collar.  I may end up implementing the actual menu here.
    LockMeister generates its own particle chains, I believe.
    LockGuard is a bit more powerful - it allows several chain settings to be configured.
    So, for the LockGuard chains, it seems we should use the lockguard settings if it gave us any and,
    if not, use our own "leash" settings instead.  The specifics on how to "merge" these two sets of
    parameters is unclear at this point, but should become more obvious by the time some testing is done.

    Anyway, the point is, we need to keep track of what LockGuard wants for particles on each attachment point.
    An empty list should indicate we use the current leash settings.

*/

// very LockGuard-specific
list g_lLGSettings = [];
key g_lLGTargets = [NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY];
key g_kLGDefaultChain = "40809979-b6be-2b42-e915-254ccd8d9a08";
key g_kLGDefaultRope = "bc586d76-c5b9-de10-5b66-e8840f175e0d";

// leash target
key g_kLeashTarget = NULL_KEY;

// LockGuard writers prefer that we use their defaults, so I'm going to put them here, but
// I'm going to see how this goes with collar defaults.  Hopefully they will be close enough
// to play well with most things at least.

list g_lLGPointIDs = [ "collarfrontloop", "collarleftloop", "collarrightloop", "collarbackloop" ];
list g_lLMPointIDs = [ "collar", "lcollar", "rcollar", "bcollar" ];

// we'll store the actual link numbers in this
list g_lPointLinks = [-1, -1, -1, -1];
list g_lMenuIDs;

// globals that we configure, but leash uses
integer g_iStrictMode = FALSE;
integer g_iTurnMode = FALSE;
integer g_iStrictRank;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + 2);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

// Menus - taken from old script and unused atm
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
    integer iGlow = llList2Integer(g_lLeashSettings, 5);
    integer iRibbon = llList2Integer(g_lLeashSettings, 6);
    lButtons += [Checkbox(iGlow, "Glow"), Checkbox(g_iTurnMode, "Turn"), Checkbox(g_iStrictMode, "Strict")];
    lButtons += [Checkbox(iRibbon, "Ribbon")];
    lButtons += [Checkbox(llList2String(g_lLeashSettings, 0) == g_kDefaultChain, "Classic")];
    lButtons += [Checkbox(llList2String(g_lLeashSettings, 0) == g_kDefaultSilk, "Silk")];
    lButtons += [Checkbox(llList2String(g_lLeashSettings, 0) == g_kDefaultRope, "Rope")];
    lButtons += [Checkbox(llList2String(g_lLeashSettings, 0) == g_kDefaultLeather, "Leather")];
    lButtons += [Checkbox(llList2String(g_lLeashSettings, 0) == TEXTURE_TRANSPARENT, "Invisible")];
    lButtons += ["Texture", "Color", "Feel"];
    string sPrompt = "\n[Leash Configuration]\n\nCustomize the looks and feel of your leash.";
    Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth, "leash/configure");
}

FeelMenu(key kIn, integer iAuth) {
    list lButtons = ["Bigger", "Smaller", L_DEFAULTS, "Heavier", "Lighter"];
    string sPrompt = "\nHere you can change the weight and size of your leash.";
    Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth, "leash/feel");
}

ColorMenu(key kIn, integer iAuth) {
    string sPrompt = "\nChoose a color.";
    Dialog(kIn, sPrompt, ["colormenu please"], [UPMENU], 0, iAuth, "leash/color");
}

TextureMenu(key kIn, integer iAuth) {
    // TODO
}

// setup function
GetPointLinks() {
    integer n = llGetNumberOfPrims();
    integer i;
    if (n == 1) {
        g_lPointLinks = [0, -1, -1, -1];
    } else for (i = 1; i <= n; ++i) {
        string linkname = llToLower(llGetLinkName(i));
        if (linkname == "fcollar" || linkname == "leashpoint" || linkname == "ooc") {
            g_lPointLinks = llListReplaceList(g_lPointLinks, [i], 0, 0);
        } else if (linkname == "bcollar") {
            g_lPointLinks = llListReplaceList(g_lPointLinks, [i], 3, 3);
        } else if (linkname == "lcollar") {
            g_lPointLinks = llListReplaceList(g_lPointLinks, [i], 1, 1);
        } else if (linkname == "rcollar") {
            g_lPointLinks = llListReplaceList(g_lPointLinks, [i], 2, 2);
        }
    }
}

// Particle chain start/stop
StartParticleChain(key kTarget, integer iLinkNum, list lParams) {
    key kTex;
    if (llList2String(lParams, 0) == "") kTex = llList2String(g_lLeashSettings, 0);
    else kTex = llList2String(lParams, 0);
    vector vSize;
    if (llList2String(lParams, 1) == "") vSize = llList2Vector(g_lLeashSettings, 1);
    else vSize = llList2Vector(lParams, 1);
    float fLife;
    if (llList2String(lParams, 2) == "") fLife = llList2Float(g_lLeashSettings, 2);
    else fLife = llList2Float(lParams, 2);
    float fGravity;
    if (llList2String(lParams, 3) == "") fGravity = llList2Float(g_lLeashSettings, 3);
    else fGravity = llList2Float(lParams, 3);
    vector vColor;
    if (llList2String(lParams, 4) == "") vColor = llList2Vector(g_lLeashSettings, 4);
    else vColor = llList2Vector(lParams, 4);
    
    // TODO: emissive and ribbon, which are not supported by LockGuard

    integer iPartFlags = PSYS_PART_TARGET_POS_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK;
    llLinkParticleSystem(iLinkNum, []);
    if (kTex == TEXTURE_TRANSPARENT) return;

    if (fGravity == 0.0) iPartFlags = iPartFlags | PSYS_PART_TARGET_LINEAR_MASK;

    llLinkParticleSystem(iLinkNum, [
        PSYS_PART_MAX_AGE, fLife,
        PSYS_PART_FLAGS, nBitField,
        PSYS_PART_START_COLOR, vColor,
        PSYS_PART_START_ALPHA, 1.0,
        PSYS_PART_START_SCALE, vSize,
        PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
        PSYS_SRC_BURST_RATE, 0.001,
        PSYS_SRC_ACCEL, <0.0, 0.0, fGravity>,
        PSYS_SRC_BURST_PART_COUNT, 10,
        PSYS_SRC_BURST_RADIUS, 0.0,
        PSYS_SRC_BURST_SPEED_MIN, 0.0,
        PSYS_SRC_BURST_SPEED_MAX, 0.0,
        PSYS_SRC_MAX_AGE, 0.0,
        PSYS_SRC_TARGET_KEY, kTarget,
        PSYS_SRC_TEXTURE, kTex
    ]);
}

StopParticleChain(integer iLinkNum) {
    llLinkParticleSystem(iLinkNum, []);
}

ClearAllChains() {
    g_lLGTargets = [NULL_KEY, NULL_KEY, NULL_KEY, NULL_KEY];
    g_kLeashTarget = NULL_KEY;
    integer i;
    for (i = 0; i < 4; ++i) StopParticleChain(llList2Integer(g_lPointLinks, i));
}

// For LockGuard settings and chains
list GetLockGuardSettings(integer iLeashPoint) {
    if (iLeashPoint > -1 && iLeashPoint < 4) return llList2List(g_lLGSettings, iLeashPoint * 5, iLeashPoint * 5 + 4);
    else return [];
}

SetLockGuardSettings(integer iLeashPoint, list lSettings) {
    while (llGetListLength(lSettings) < 5) lSettings += [""];
    if (iLeashPoint > -1 && iLeashPoint < 4)
        g_lLGSettings = llListReplaceList(g_lLGSettings, lSettings, iLeashPoint * 5, iLeashPoint * 5 + 4);
}

LockGuardLink(key kTarget, integer iLeashPoint) {
    integer iPointLink = llList2Integer(g_lPointLinks, iLeashPoint);
    if (iPointLink == -1) return;
    list lParams = GetLockGuardSettings(iLeashPoint);
    g_lLGTargets = llListReplaceList(g_lLGTargets, [kTarget], iLeashPoint, iLeashPoint);
    StartParticleChain(kTarget, llList2Integer(g_lPointLinks, iLeashPoint), lParams);
}

LockGuardUnlink(key kTarget, integer iLeashPoint) {
    integer iPointLink = llList2Integer(g_lPointLinks, iLeashPoint);
    if (iPointlink == -1) return;
    if (kTarget != llList2Key(g_lLGTargets, iLeashPoint)) return;
    StopParticleChain(llList2Integer(iPointLink);
    g_lLGTargets = llListReplaceList(g_lLGTargets, [NULL_KEY], iLeashPoint, iLeashPoint);
    // TODO: clear settings after unlinking
    // can the leash be hooked to anything beside front?
    if (iLeashPoint == 0) {
        if (g_kLeashTarget) StartParticleChain(g_kLeashTarget, llList2Integer(g_lPointLinks, iLeashPoint), g_lLeashSettings);
    }
}

integer StringBoolean(string sVal) {
    integer i = llListFindList(["no", "yes", "false", "true", "off", "on", "0", "1"], [sVal]);
    if (i == -1) return FALSE;
    else return (i%2);
}

// Simple float clamp function
float Clamp(float fVal, float fMin, float fMax) {
    if (fVal < fMin) return fMin;
    else if (fVal > fMax) return fMax;
    return fVal;
}

// Aria's LSL function for ternary string operation should be useful
string setor(integer iTest, string sTrue, string sFalse){
    if(iTest)return sTrue;
    else return sFalse;
}

// color to hex, hex to color
string ColorToHex(vector vColor) {
    string sOctets = "0123456789ABCDEF";
    integer iRed = (integer)(vColor.x * 255.0);
    integer iGrn = (integer)(vColor.y * 255.0);
    integer iBlu = (integer)(vColor.z * 255.0);
    return ( "#" + 
        llGetSubString(sOctets, iRed / 16, iRed / 16) + llGetSubString(sOctets, iRed % 16, iRed % 16),
        llGetSubString(sOctets, iGrn / 16, iGrn / 16) + llGetSubString(sOctets, iGrn % 16, iGrn % 16),
        llGetSubString(sOctets, iBlu / 16, iBlu / 16) + llGetSubString(sOctets, iBlu % 16, iBlu % 16),
    );
}

vector HexToColor(string sHexColor) {
    if (llGetSubString(sHexColor, 0, 0) == "#") sHexColor = llGetSubString(sHexColor, 1, -1);
    if (llStringLength(sHexColor == 6)) {
        integer iRed = (integer)("0x" + llGetSubString(sHexColor, 0, 1));
        integer iGrn = (integer)("0x" + llGetSubString(sHexColor, 2, 3));
        integer iBlu = (integer)("0x" + llGetSubString(sHexColor, 4, 5));
        return <((float)iRed) / 255.0, ((float)iGrn) / 255.0, ((float)iBlu) / 255.0>;
    } else if (llStringLength(sHexColor) == 3) {
        integer iRed = (integer)("0x" + llGetSubString(sHexColor, 0, 0));
        integer iGrn = (integer)("0x" + llGetSubString(sHexColor, 1, 1));
        integer iBlu = (integer)("0x" + llGetSubString(sHexColor, 2, 2));
        return <((float)iRed) / 15.0, ((float)iGrn) / 15.0, ((float)iBlu) / 15.0>;
    } else return ZERO_VECTOR;
}

UserCommand(integer iNum, string sStr, key kID) {
    if (sMessage == "menu "+SUBMENU) {
        if(iNum <= CMD_TRUSTED || iNum == CMD_WEARER) ConfigureMenu(kMessageID, iNum);
        else {
            llMessageLinked(LINK_SET, NOTIFY,"0"+"%NOACCESS% to leash configure menu", kMessageID);
            llMessageLinked(LINK_SET, iNum, "menu "+PARENTMENU, kMessageID);
        }
    } else {
        integer iRemenu = FALSE;
        string sSubMenu = "configure";
        integer iPartMod = FALSE;
        list lTokens = llParseString2List(sMessage, [" "], []);
        if (llToLower(llList2String(lTokens, 0)) == "leash/configure") {
            string sSubCmd = llToLower(llList2String(lTokens, 1));
            if (sSubCmd == "configure") {
                if (iNum <= CMD_TRUSTED || iNum == CMD_WEARER) ConfigureMenu(kMessageID, iNum);
                else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS% to configuring the leash particles", kMessageID);
            } else if (sSubCmd == "glow") {
                integer iNewGlow = StringBoolean(llToLower(llList2String(lTokens, 2)));
                g_lLeashSettings = llListReplaceList(g_lLeashSettings, [iNewGlow], 5, 5);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_glow="+(string)(iNewGlow), "");
                if (llToLower(llList2String(lTokens, 3)) == "remenu") iRemenu = TRUE;
                iPartMod = TRUE;
            } else if (sSubCmd == "turn") {
                g_iTurnMode = StringBoolean(llToLower(llList2String(lTokens, 2)));
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_turn="+(string)g_iTurnMode, "");
                if (llToLower(llList2String(lTokens, 3)) == "remenu") iRemenu = TRUE;
            } else if (sSubCmd == "strict") {
                g_iStrictMode = StringBoolean(llToLower(llList2String(lTokens, 2)));
                g_iStrictRank = iNum;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_strict="+(string)g_iStrictMode, "");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_strictrank="+(string)g_iStrictRank, "");
                if (llToLower(llList2String(lTokens, 3)) == "remenu") iRemenu = TRUE;
            } else if (sSubCmd == "ribbon") {
                integer iNewRibbon = StringBoolean(llToLower(llList2String(lTokens, 2)));
                g_lLeashSettings = llListReplaceList(g_lLeashSettings, [iNewRibbon], 6, 6);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_ribbon="+(string)(iNewRibbon), "");
                if (llToLower(llList2String(lTokens, 3)) == "remenu") iRemenu = TRUE;
                iPartMod = TRUE;
            } else if (sSubCmd == "invisible") {
                g_lLeashSettings = llListReplaceList(g_lLeashSettings, [g_kDefaultChain], 0, 0);
                if (llToLower(llList2String(lTokens, 3)) == "remenu") iRemenu = TRUE;
                iPartMod = TRUE;
            } else if (sSubCmd == "texture") {
                string sTexID = llList2String(lTokens, 2);
                integer iTexOK = FALSE;
                if (llToLower(sTexID) == "chain") {
                    g_lLeashSettings = llListReplaceList(g_lLeashSettings, [g_kDefaultChain], 0, 0);
                    iTexOK = TRUE;
                } else if (llToLower(sTexID) == "rope") {
                    g_lLeashSettings = llListReplaceList(g_lLeashSettings, [g_kDefaultRope], 0, 0);
                    iTexOK = TRUE;
                } else if (llToLower(sTexID) == "silk") {
                    g_lLeashSettings = llListReplaceList(g_lLeashSettings, [g_kDefaultSilk], 0, 0);
                    iTexOK = TRUE;
                } else if (llToLower(sTexID) == "leather") {
                    g_lLeashSettings = llListReplaceList(g_lLeashSettings, [g_kDefaultLeather], 0, 0);
                    iTexOK = TRUE;
                } else {
                    key kTmp = (key)sTexID;
                    if (kTmp) {
                        g_lLeashSettings = llListReplaceList(g_lLeashSettings, [kTmp], 0, 0);
                        iTexOK = TRUE;
                    } else {
                        if (llToLower(llList2String(lTokens, -1)) == "remenu")
                            sTexID = llDumpList2String(llList2List(lTokens, 2, -2), " ");
                        else sTexID = llDumpList2String(llList2List(lTokens, 2, -1), " ");
                        if (llGetInventoryType(sTexID) == INVENTORY_TEXTURE) {
                            sSubMenu = "leash/texture";
                            kTmp = llGetInventoryKey(sTexID);
                            if (kTmp) {
                                g_lLeashSettings = llListReplaceList(g_lLeashSettings, [kTmp], 0, 0);
                                iTexOK = TRUE;
                            } // else (handle non-full-perm textures: warn about them needing to be in all prims, etc?)
                        }
                    }
                }
                if (iTexOK)
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_texture="+llList2String(g_lLeashSettings, 0), "");
                    if (llToLower(llList2String(lTokens, -1)) == "remenu") iRemenu = TRUE;
                    iPartMod = TRUE;
                }
            } else if (sSubCmd == "color") {
                sSubMenu = "leash/color";
                g_lLeashSettings = llListReplaceList(g_lLeashSettings, [HexToColor(llList2String(lTokens, 2))], 4, 4);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_color="+llList2String(lTokens, 2), "");
                if (llToLower(llList2String(lTokens, -1)) == "remenu") iRemenu = TRUE;
                iPartMod = TRUE;
            } else if (sSubCmd == "size") {
                sSubMenu = "leash/feel";
                float fSizeX = (float)llList2String(lTokens, 2);
                float fSizeY = (float)llList2String(lTokens, 3);
                vector vNewSize = <Clamp(fSizeX, 0.03125, 4.0), Clamp(fSizeY, 0.03125, 4.0), 1.0>;
                g_lLeashSettings = llListReplaceList(g_lLeashSettings, [vNewSize], 1, 1);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_size="+(string)vNewSize, "");
                if (llToLower(llList2String(lTokens, 4)) == "remenu") iRemenu = TRUE;
                iPartMod = TRUE;
            } else if (sSubCmd == "gravity") {
                sSubMenu = "leash/feel";
                float fGrav = (float)llList2String(lTokens, 2);
                if (fGrav > 0.0) fGrav = 0.0 - fGrav;
                fGrav = Clamp(fGrav, -3.0, 0.0))
                g_lLeashSettings = llListReplaceList(g_lLeashSettings, [fGrav], 3, 3);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "leash_gravity="+(string)fGrav, "");
                if (llToLower(llList2String(lTokens, -1)) == "remenu") iRemenu = TRUE;
                iPartMod = TRUE;
            }
        }
        if (iPartMod) {
            integer iLeashedLG = FALSE;
            integer i;
            for (i = 0; i < 4; ++i) {
                key kLGtarget = llList2Key(g_lLGTargets, i);
                if (kLGtarget) {
                    if (i == 0) iLeashedLG = TRUE;
                    integer iPointLink = llList2Integer(g_lPointLinks, i);
                    list lParams = GetLockGuardSettings(i);
                    StartParticleChain(kLGtarget, llList2Integer(g_lPointLinks, i), lParams);
                }
            }
            if (!iLeashedLG) {
                if (g_kLeashTarget) StartParticleChain(g_kLeashTarget, 0, []);
            }
        }
        if (iRemenu) {
            llMessageLinked(LINK_SET, iNum, "menu "+sSubMenu, kMessageID);
        }
    }
    // I copied this from the old script until I figure out if I want to reimplement.
    // I'm not sure what theme particle sent exactly is
    /*
    else if (llToLower(sMessage) == "particle reset") {
        g_lSettings = []; // clear current settings
        if (kMessageID) llMessageLinked(LINK_SET, NOTIFY, "0"+"Leash-settings restored to %DEVICETYPE% defaults.", kMessageID);
        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken + "all", "");
        //GetSettings(TRUE);
    } else if (llToLower(sMessage) == "theme particle sent")
        //GetSettings(TRUE);
    */
}

default {
    on_rez(integer iRez) {
        llResetScript();
    }

    state_entry() {
        llListen(g_iChan_LOCKGUARD,"",NULL_KEY,"");     // Lockguard Listener
        llListen(g_iChan_LOCKMEISTER,"",NULL_KEY,"");   // Lockmeister Listener
        GetPointLinks();
        ClearAllChains();
        //GetSettings(FALSE);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if (iNum == CMD_PARTICLE) {
            if (sStr == "leash") {
                g_kLeashTarget = kID;
                key kLGTarget = llList2Key(g_lLGTargets, 0);
                if (kLGTarget) {
                    if (llGetAgentSize(kLGTarget) == ZERO_VECTOR) {
                        llRegionSayTo(llGetOwnerKey(kID), PUBLIC_CHANNEL, "You will grab the leash once it is released from " + llKey2Name(kLGTarget) + ".");
                    //} else {
                        //llRegionSayTo(kMessageID, PUBLIC_CHANNEL, "You will grab the leash once it is released from " + llKey2Name(kLGTarget) + ".");
                    }
                } else {
                    StartParticleChain(g_kLeashTarget, llList2Integer(g_lPointLinks, 0), []);
                    if (llGetAgentSize(g_kLeashTarget) == ZERO_VECTOR) {
                        llRegionSayTo(g_kLeashTarget, PUBLIC_CHANNEL, "You grab " + llKey2Name(llGetOwner()) + "'s leash.");
                    }
                }
            } else {
                g_kLeashTarget = NULL_KEY;
                key kLGTarget = llList2Key(g_lLGTargets, 0);
                if (kLGTarget) {
                    if (llGetAgentSize(kLGTarget) == ZERO_VECTOR) {
                        llRegionSayTo(llGetOwnerKey(kID), PUBLIC_CHANNEL, "You leave " + llKey2Name(llGetOwner()) + " chained to " + llKey2Name(kLGTarget) + ".");
                    }
                } else {
                    StopParticleChain(llList2Integer(g_lPointLinks, 0));
                    if (llGetAgentSize(kLGTarget) == ZERO_VECTOR) {
                        llRegionSayTo(llGetOwnerKey(kMessageID), PUBLIC_CHANNEL, "You detach " + llKey2Name(llGetOwner()) + "'s leash.");
                    }
                }
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1) {
                list lMenuParams = llParseString2List(sMessage, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sButton = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sButton == UPMENU) {
                    if(sMenu == "leash/configure") llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else ConfigureMenu(kAv, iAuth);
                } else  if (sMenu == "leash/configure") {
                    if (sButton == "Color") {
                        ColorMenu(kAv, iAuth);
                        return;
                    } else if (sButton == "Feel") {
                        FeelMenu(kAv, iAuth);
                        return;
                    } else if (sButton == "Texture") {
                        TextureMenu(kAv, iAuth);
                        return;
                    } else if(llGetSubString(sButton, 1, -1) == " Glow") {
                        llMessageLinked(LINK_SET, iAuth, "leash glow " + setor(llList2Integer(g_lLeashSettings, 5), "off", "on") + " remenu", kAv);
                    } else if(llGetSubString(sButton, 1, -1) == " Turn") {
                        llMessageLinked(LINK_SET, iAuth, "leash turn " + setor(g_iTurnMode, "off", "on") + " remenu", kAv);
                    } else if (llGetSubString(sButton, 1, -1) == " Strict") {
                        if (iAuth <= g_iStrictRank || !g_iStrictMode) {
                            llMessageLinked(LINK_SET, iAuth, "leash strict " + setor(g_iStrictMode, "off", "on") + " remenu", kAv);
                        } else llMessageLinked(LINK_SET, NOTIFY,"0%NOACCESS% to changing strict settings",kAv);
                    } else if (llGetSubString(sButton, 1, -1) == " Ribbon") {
                        llMessageLinked(LINK_SET, iAuth, "leash ribbon " + setor(llList2Integer(g_lLeashSettings, 6), "off", "on") + " remenu", kAv);
                    } else if (llGetSubString(sButton, 1, -1) == " Chain") {
                        llMessageLinked(LINK_SET, iAuth, "leash texture chain remenu", kAv);
                    } else if (llGetSubString(sButton, 1, -1) == " Rope") {
                        llMessageLinked(LINK_SET, iAuth, "leash texture rope remenu", kAv);
                    } else if (llGetSubString(sButton, 1, -1) == " Silk") {
                        llMessageLinked(LINK_SET, iAuth, "leash texture silk remenu", kAv);
                    } else if (llGetSubString(sButton, 1, -1) == " Leather") {
                        llMessageLinked(LINK_SET, iAuth, "leash texture leather remenu", kAv);
                    } else if (llGetSubString(sButton, 1, -1) == " Invisible") {
                        llMessageLinked(LINK_SET, iAuth, "leash invisible remenu", kAv);
                    }
                } else if (sMenu == "leash/color") {
                    llMessageLinked(LINK_SET, iAuth, "leash color " + ColorToHex((vector)sButton) + " remenu", kAv);
                } else if (sMenu == "leash/feel") {
                    if (sButton == "Defaults") {
                        llMessageLinked(LINK_SET, iAuth, "leash defaults remenu", kAv);
                    } else if (sButton == "Bigger") {
                        vector vLeashSize = llList2Vector(g_lLeashSettings, 1);
                        float fLeashX = Clamp(vLeashSize.x + 0.03125, 0.03125, 4.0);
                        float fLeashY = Clamp(vLeashSize.y + 0.03125, 0.03125, 4.0);
                        llMessageLinked(LINK_SET, iAuth, "leash size " + ((string)fLeashX) + " " + ((string)fLeashY) + " remenu", kAv);
                    } else if (sButton == "Smaller") {
                        vector vLeashSize = llList2Vector(g_lLeashSettings, 1);
                        float fLeashX = Clamp(vLeashSize.x - 0.03125, 0.03125, 4.0);
                        float fLeashY = Clamp(vLeashSize.y - 0.03125, 0.03125, 4.0);
                        llMessageLinked(LINK_SET, iAuth, "leash size " + ((string)fLeashX) + " " + ((string)fLeashY) + " remenu", kAv);
                    } else if (sButton == "Heavier") {
                        float fLeashGrav = llList2Float(g_lLeashSettings, 3);
                        llMessageLinked(LINK_SET, iAuth, "leash gravity " + ((string)Clamp(fLeashGrav - 0.1, -3.0, 0.0)) + " remenu", kAv);
                    } else if (sButton == "Lighter") {
                        float fLeashGrav = llList2Float(g_lLeashSettings, 3);
                        llMessageLinked(LINK_SET, iAuth, "leash gravity " + ((string)Clamp(fLeashGrav + 0.1, -3.0, 0.0)) + " remenu", kAv);
                    }
                } else if (sMenu == "leash/texture") {
                    // TODO
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kMessageID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LM_SETTING_RESPONSE) {
            /* TODO: Rewrite
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
                } else if(sToken == "length"){
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
            */
        } else if (iNum == LM_SETTING_DELETE) {
            // TODO: rewrite this too
        } else if (iNum == REBOOT && sMessage == "reboot") llResetScript();
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChan_LOCKGUARD){
            // LockGuard V2 Chains
            list lLGArgs = llParseString2List(llToLower(sMessage), [" "],[]);
            if (llList2String(lLGArgs, 0) == "lockguard") {
                key kLGAv = llList2Key(lLGArgs, 1);
                if (kLGAv == llGetOwner()) {
                    string sLGPoint = llList2String(lLGArgs, 2);
                    integer iCollarPoint = llListFindList(g_lLGPointIDs, [sLGPoint]);
                    if (iCollarPoint != -1) {
                        key kLGTarget = llList2Key(g_lLGTargets, iCollarPoint);
                        string sLGCmd = llList2String(lLGArgs, 3);
                        if (sLGCmd == "link") {
                            key kNewTarget = (key)llList2String(lLGArgs, 4);
                            if (kNewTarget) LockGuardLink(kNewTarget, iCollarPoint);
                        } else if (sLGCmd == "unlink") {
                            if (kLGTarget) LockGuardUnlink(kLGTarget, iCollarPoint);
                        } else if (sLGCmd == "gravity") {
                            float fGrav = (float)llList2String(lLGArgs, 4);
                            list lTmp = GetLockGuardSettings(iCollarPoint);
                            lTmp = llListReplaceList(lTmp, [Clamp(fGrav, 0.0, 3.0)], 3, 3);
                            SetLockGuardSettings(iCollarPoint, lTmp);
                            if (kLGTarget) LockGuardLink(kLGTarget, iCollarPoint);
                        } else if (sLGCmd == "life") {
                            float fLife = (float)llList2String(lLGArgs, 4);
                            list lTmp = GetLockGuardSettings(iCollarPoint);
                            lTmp = llListReplaceList(lTmp, [Clamp(fLife, 0.01, 30.0)], 2, 2);
                            SetLockGuardSettings(iCollarPoint, lTmp);
                            if (kLGTarget) LockGuardLink(kLGTarget, iCollarPoint);
                        } else if (sLGCmd == "color") {
                            float fRed = (float)llList2String(lLGArgs, 4);
                            float fGreen = (float)llList2String(lLGArgs, 5);
                            float fBlue = (float)llList2String(lLGArgs, 6);
                            vector vColor = <Clamp(fRed, 0.0, 1.0), Clamp(fGreen, 0.0, 1.0), Clamp(fBlue, 0.0, 1.0)>;
                            list lTmp = GetLockGuardSettings(iCollarPoint);
                            lTmp = llListReplaceList(lTmp, [vColor], 4, 4);
                            SetLockGuardSettings(iCollarPoint, lTmp);
                            if (kLGTarget) LockGuardLink(kLGTarget, iCollarPoint);
                        } else if (sLGCmd == "size") {
                            float fSizeX = (float)llList2String(lLGArgs, 4);
                            float fSizeY = (float)llList2String(lLGArgs, 5);
                            vector vNewSize = <Clamp(fSizeX, 0.03125, 4.0), Clamp(fSizeY, 0.03125, 4.0), 1.0>;
                            list lTmp = GetLockGuardSettings(iCollarPoint);
                            lTmp = llListReplaceList(lTmp, [vNewSize], 1, 1);
                            SetLockGuardSettings(iCollarPoint, lTmp);
                            if (kLGTarget) LockGuardLink(kLGTarget, iCollarPoint);
                        } else if (sLGCmd == "texture") {
                            string sNewTex = llList2String(lLGArgs, 4);
                            if (sNewTex == "rope") sNewTex = g_kLGDefaultRope;
                            else if (sNewTex == "chain") sNewTex = g_kLGDefaultChain;
                            key kNewTex = (key)sNewTex;
                            if (kNewTex) {
                                list lTmp = GetLockGuardSettings(iCollarPoint);
                                lTmp = llListReplaceList(lTmp, [kNewTex], 0, 0);
                                SetLockGuardSettings(iCollarPoint, lTmp);
                            }
                            if (kLGTarget) LockGuardLink(kLGTarget, iCollarPoint);
                        }
                    }
                }
            }
        } else if (iChannel == g_iChan_LOCKMEISTER) {
            // LockMeister v2 Chains
            // Leash Holders use this, it seems
            // TODO:
        }
    }
}


