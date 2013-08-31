//OpenCollar - leashParticle
//leash particle script for the Open Collar Project (c)
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//Split from the leash script in April 2010 by Garvin Twine

// - MESSAGE MAP
//integer COMMAND_NOAUTH      = 0;
integer COMMAND_OWNER       = 500;
integer COMMAND_SECOWNER    = 501;
integer COMMAND_GROUP       = 502;
integer COMMAND_WEARER      = 503;
integer COMMAND_EVERYONE    = 504;
integer COMMAND_SAFEWORD    = 510;
integer POPUP_HELP          = 1001;
// -- SETTINGS
// - Setting strings must be in the format: "token=value"
integer LM_SETTING_SAVE             = 2000; // to have settings saved to settings store
integer LM_SETTING_REQUEST          = 2001; // send requests for settings on this channel
integer LM_SETTING_RESPONSE         = 2002; // responses received on this channel
integer LM_SETTING_DELETE           = 2003; // delete token from store
integer LM_SETTING_EMPTY            = 2004; // returned when a token has no value in the store
// -- MENU/DIALOG
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
integer MENUNAME_REMOVE     = 3003;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

integer LOCKMEISTER         = -8888;
integer LOCKGUARD           = -9119;
integer g_iLMListener;
integer g_iLMListernerDetach;

integer COMMAND_PARTICLE = 20000;
integer COMMAND_LEASH_SENSOR = 20001;

// --- menu tokens ---
string UPMENU       = "^";
string MORE         = ">";
string PARENTMENU   = "Leash";
string SUBMENU      = "L-Options";
string L_TEXTURE    = "Texture";
string L_DENSITY    = "Density";
string L_COLOR      = "Color";
string L_GRAVITY    = "Gravity";
string L_SIZE       = "Size";
string L_DEFAULTS   = "ResetDefaults";

list g_lSettings; //["tex", "texName", "size", "0.07", "color", "1,1,1", "gravity", "1.0", "density", "0.04", "Glow", "1"]

string g_sCurrentMenu = "";
key g_kDialogID;

string g_sCurrentCategory = "";
list g_lCategories = ["Blues", "Browns", "Grays", "Greens", "Purples", "Reds", "Yellows"];
list g_lColors;
list g_lAllColors = [
"Light Blue|<0.00000, 0.00000, 1.00000>
Dark Blue|<0.00000, 0.00000, 0.62745>
Midnight Blue|<0.08235, 0.10588, 0.32941>
Dark Slate Blue|<0.16863, 0.21961, 0.33725>
Sky Blue|<0.40000, 0.59608, 1.00000>
Light Cyan3|<0.68627, 0.78039, 0.78039>
Cadet Blue3|<0.46667, 0.74902, 0.78039>
Turquoise|<0.26275, 0.77647, 0.85882>
Light Steel Blue2|<0.71765, 0.80784, 0.92549>
Dark Gray Blue|<0.18039, 0.21176, 0.25490>",
"Orange|<1.00000, 0.50196, 0.25098>
Bright Orange|<0.97255, 0.50196, 0.09020>
Dark Orange|<0.76471, 0.33725, 0.09020>
Sienna|<0.97255, 0.45490, 0.19216>
Dark Sienna|<0.76471, 0.34510, 0.09020>
Brown|<0.50196, 0.25098, 0.00000>
Brown Sienna|<0.49412, 0.20784, 0.09020>
Dark Brown|<0.27843, 0.23137, 0.18431>
Sandy Brown|<0.93333, 0.60392, 0.30196>
Dark Drab|<0.33333, 0.30980, 0.21176>",
"Black|<0.00000, 0.00000, 0.00000>
Gray 1|<0.11111, 0.11111, 0.11111>
Gray 2|<0.22222, 0.22222, 0.22222>
Gray 3|<0.33333, 0.33333, 0.33333>
Gray 4|<0.44444, 0.44444, 0.44444>
Gray 5|<0.55556, 0.55556, 0.55556>
Gray 6|<0.66667, 0.66667, 0.66667>
Gray 7|<0.77778, 0.77778, 0.77778>
Gray 8|<0.88889, 0.88889, 0.88889>
White|<1.00000, 1.00000, 1.00000>",
"Pastel Green|<0.73333, 1.00000, 0.51372>
Forest Green|<0.50196, 0.50196, 0.00000>
Light Sea Green|<0.24314, 0.66275, 0.62353>
Medium Sea Green|<0.18824, 0.40392, 0.32941>
Dark Sea Green4|<0.38039, 0.48627, 0.34510>
Dark Green|<0.14510, 0.25490, 0.09020>
Yellow Green|<0.32157, 0.81569, 0.09020>
Olive4|<0.40000, 0.48627, 0.14902>
Chartreuse|<0.54118, 0.98431, 0.09020>
Olive3|<0.62745, 0.77255, 0.26667>",
"Light Purple|<1.00000, 0.00000, 0.50196>
Purple|<0.55686, 0.20784, 0.93725>
Dark Purple|<0.50196, 0.00000, 0.50196>
Plum|<0.72549, 0.23137, 0.56078>
Dark Orchid|<0.27059, 0.14510, 0.27451>
Magenta|<1.00000, 0.00000, 1.00000>
Light Plum|<0.90196, 0.66275, 0.92549>
Pale Violet Red|<0.81961, 0.39608, 0.52941>
Thistle|<0.91373, 0.81176, 0.92549>
Lavender|<0.89020, 0.89412, 0.98039>",
"Burgundy|<0.50196, 0.00000, 0.00000>
Red|<1.00000, 0.00000, 0.00000>
Pink|<0.98039, 0.68627, 0.74510>
Indian Red|<0.89804, 0.32941, 0.31765>
Firebrick|<0.75686, 0.10588, 0.09020>
Hot Pink|<0.96471, 0.37647, 0.67059>
Magenta|<1.00000, 0.00000, 1.00000>
Violet Red|<0.96471, 0.20784, 0.54118>
Pink2|<0.90588, 0.63137, 0.69020>
Dark Red|<0.27843, 0.01569, 0.05490>",
"Yellow|<1.00000, 1.00000, 0.00000>
Bright Yellow|<1.00000, 0.98824, 0.09020>
Pale Khaki|<1.00000, 0.95294, 0.50196>
Goldenrod|<0.92941, 0.85490, 0.45490>
Dark Goldenrod|<0.68627, 0.47059, 0.09020>
Gold|<0.83137, 0.62745, 0.09020>
Dark Gold|<0.91765, 0.75686, 0.09020>
Medium Gold|<0.99216, 0.81569, 0.09020>
Khaki|<0.67843, 0.66275, 0.43137>
Pastel Yellow|<1.00000, 1.00000, 0.44706>"
];

// ----- collar -----
//string g_sWearerName;
key g_kWearer;

key NULLKEY = "";
key g_kLeashedTo = ""; //NULLKEY;
key g_kLeashToPoint = ""; //NULLKEY;
key g_kParticleTarget = ""; //NULLKEY;
integer g_bLeasherInRange;
integer g_bInvisibleLeash = FALSE;
integer g_iAwayCounter;

integer g_bLeashActive;

//List of 4 leash/chain points, lockmeister names used (list has to be all lower case, prims dont matter, converting on compare to lower case)
//strided list... LM name, linkNumber, BOOL_ACVTIVE
list g_lLeashPrims;


//global integer used for loops
integer g_iLoop;

debug(string sText)
{
    //llOwnerSay(llGetScriptName() + " DEBUG: " + sText);
}
string GetScriptID()
{
    // strip away "OpenCollar - " leaving the script's individual name
    list parts = llParseString2List(llGetScriptName(), ["-"], []);
    return llStringTrim(llList2String(parts, 1), STRING_TRIM) + "_";
}
string PeelToken(string in, integer slot)
{
    integer i = llSubStringIndex(in, "_");
    if (!slot) return llGetSubString(in, 0, i);
    return llGetSubString(in, i + 1, -1);
}
FindLinkedPrims()
{
    integer linkcount = llGetNumberOfPrims();
    //root prim is 1, so start at 2
    for (g_iLoop = 2; g_iLoop <= linkcount; g_iLoop++)
    {
        string sPrimDesc = (string)llGetObjectDetails(llGetLinkKey(g_iLoop), [OBJECT_DESC]);
        list lTemp = llParseString2List(sPrimDesc, ["~"], []);
        integer iLoop;
        for (iLoop = 0; iLoop < llGetListLength(lTemp); iLoop++)
        {
            string sTest = llList2String(lTemp, iLoop);
            debug(sTest);
            //expected either "leashpoint" or "leashpoint:point"
            if (llGetSubString(sTest, 0, 9) == "leashpoint")
            {
                if (llGetSubString(sTest, 11, -1) == "")
                {
                    g_lLeashPrims += [sTest, (string)g_iLoop, "1"];
                }
                else
                {
                    g_lLeashPrims += [llGetSubString(sTest, 11, -1), (string)g_iLoop, "1"];
                }
            }
        }
    }
    //if we did not find any leashpoint... we unset the root as one
    if (!llGetListLength(g_lLeashPrims))
    {
        g_lLeashPrims = ["collar", LINK_THIS, "1"];
    }
}

//Particle system and variables

string g_sParticleTexture = "chain";
string g_sParticleTextureID; //we need the UUID for llLinkParticleSystem
float g_fLeashLength;
vector g_vLeashColor = <1,1,1>;
vector g_vLeashSize = <0.07, 0.07, 1.0>;
integer g_bParticleGlow = TRUE;
float g_fParticleAge = 3.0;
float g_fParticleAlpha = 1.0;
vector g_vLeashGravity = <0.0,0.0,-1.0>;
integer g_iParticleCount = 1;
float g_fBurstRate = 0.04;
//same g_lSettings but to store locally the default settings recieved from the defaultsettings note card, using direct string here to save some bits
list g_lDefaultSettings;

Particles(integer iLink, key kParticleTarget)
{
    //when we have no target to send particles to, dont create any
    if (kParticleTarget == NULLKEY)
    {
        return;
    }
    //taken out as vars to save memory
    //float fMaxSpeed = 3.0;          // Max speed each particle is spit out at
    //float fMinSpeed = 3.0;          // Min speed each particle is spit out at
    //these values do nothing when particles go to a target, the speed is determined by the particle age then
    //integer iFlags = PSYS_PART_INTERP_COLOR_MASK | PSYS_PART_INTERP_SCALE_MASK | PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_TARGET_POS_MASK;
    integer iFlags = PSYS_PART_FOLLOW_VELOCITY_MASK | PSYS_PART_TARGET_POS_MASK|PSYS_PART_FOLLOW_SRC_MASK;

    if (g_bParticleGlow) iFlags = iFlags | PSYS_PART_EMISSIVE_MASK;

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

StartParticles(key kParticleTarget)
{
    debug(llList2CSV(g_lLeashPrims));
    for (g_iLoop = 0; g_iLoop < llGetListLength(g_lLeashPrims); g_iLoop = g_iLoop + 3)
    {
        if ((integer)llList2String(g_lLeashPrims, g_iLoop + 2))
        {
            Particles((integer)llList2String(g_lLeashPrims, g_iLoop + 1), kParticleTarget);
        }
    }
    llSetTimerEvent(3.0);
    g_bLeashActive = TRUE;
}

StopParticles(integer iEnd)
{
    for (g_iLoop = 0; g_iLoop < llGetListLength(g_lLeashPrims); g_iLoop++)
    {
        llLinkParticleSystem((integer)llList2String(g_lLeashPrims, g_iLoop + 1), []);
    }
    if (iEnd)
    {
        g_bLeashActive = FALSE;
        g_kLeashedTo = NULLKEY;
        g_kLeashToPoint = NULLKEY;
        g_kParticleTarget = NULLKEY;
        llSensorRemove();
    }
}

integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan>0)
    {
        iChan=iChan*(-1);
    }
    if (iChan > -10000)
    {
        iChan -= 30000;
    }
    return iChan;
}
Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else if (llGetAgentSize(kID) != ZERO_VECTOR)
    {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
    else // remote request
    {
        llRegionSayTo(kID, GetOwnerChannel(g_kWearer, 1111), sMsg);
    }
}

string Vec2String(vector vVec)
{
    list lParts = [vVec.x, vVec.y, vVec.z];
    for (g_iLoop = 0; g_iLoop < 3; g_iLoop++)
    {
        string sStr = llList2String(lParts, g_iLoop);
        //remove any trailing 0's or .'s from sStr
        //while ((~(integer)llSubStringIndex(sStr, ".")) && (llGetSubString(sStr, -1, -1) == "0" || llGetSubString(sStr, -1, -1) == "."))
        while (~llSubStringIndex(sStr, ".") && (llGetSubString(sStr, -1, -1) == "0" || llGetSubString(sStr, -1, -1) == "."))
        {
            sStr = llGetSubString(sStr, 0, -2);
        }
        lParts = llListReplaceList(lParts, [sStr], g_iLoop, g_iLoop);
    }
    return "<" + llDumpList2String(lParts, ",") + ">";
}
string Float2String(float in)
{
    string out = (string)in;
    while (~llSubStringIndex(out, ".") && (llGetSubString(out, -1, -1) == "0" || llGetSubString(out, -1, -1) == ".")) out = llGetSubString(out, 0, -2);
    return out;
}

SaveSettings(string sToken, string sSave, integer bSaveToLocal)
{
    integer iIndex = llListFindList(g_lSettings, [sToken]);
    if (iIndex>=0)
    {
        g_lSettings = llListReplaceList(g_lSettings, [sSave], iIndex +1, iIndex +1);

    }
    else
    {
        g_lSettings = g_lSettings + [sToken, sSave];
    }
    if (bSaveToLocal)
    {
        llMessageLinked(LINK_THIS, LM_SETTING_SAVE, GetScriptID() + sToken + "=" + sSave, NULLKEY);
    }
}

SaveDefaultSettings(string sSetting, string sValue)
{
    integer index = llListFindList(g_lDefaultSettings, [sSetting]) +1;
    g_lDefaultSettings = llListReplaceList(g_lDefaultSettings, [sValue], index, index);
}

string GetDefaultSetting(string sSetting)
{
    integer index = llListFindList(g_lDefaultSettings, [sSetting]);
    return llList2String(g_lDefaultSettings, index + 1);
}

// Added bSave as a boolean, to make this a more versatile wrapper
SetTexture(string sIn, key kIn)
{
    g_sParticleTexture = sIn;
    if (llToLower(g_sParticleTexture) == "noleash")
    {
        g_bInvisibleLeash = TRUE;
    }
    else
    {
        g_bInvisibleLeash = FALSE;
    }
    debug("particleTexture= " + sIn);
    g_sParticleTextureID = llGetInventoryKey(sIn);
    debug("particleTextureID= " + (string)g_sParticleTextureID);
    if (kIn)
    {
        Notify(kIn, "Leash texture set to " + g_sParticleTexture, FALSE);
    }
    debug("activeleashpoints= " + (string)g_bLeashActive);
    if (g_bLeashActive)
    {
        if (g_bInvisibleLeash)
        {
            StopParticles(FALSE);
        }
        else
        {
            StartParticles(g_kParticleTarget);
        }
    }
}

integer KeyIsAv(key id)
{
    return llGetAgentSize(id) != ZERO_VECTOR;
}

//Menus

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

OptionsMenu(key kIn, integer iAuth)
{
    g_sCurrentMenu = SUBMENU;
    list lButtons = [L_TEXTURE, L_DENSITY, L_GRAVITY, L_COLOR, L_SIZE];
    if (g_bParticleGlow)
    {
        lButtons += "GlowOff";
    }
    else
    {
        lButtons += "GlowOn";
    }
    lButtons += [L_DEFAULTS];
    string sPrompt = "Leash Options (Owner Only)\n";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

DensityMenu(key kIn, integer iAuth)
{
    list lButtons = ["Default", "+", "-"];
    g_sCurrentMenu = L_DENSITY;
    string sPrompt = "Choose '+' for more and '-' for less particles\n'Default' to revert to the default\nCurrent Density = ";
    sPrompt += Float2String(-g_fBurstRate);// BurstRate is opposite the implied effect of density
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

GravityMenu(key kIn, integer iAuth)
{
    list lButtons = ["Default", "+", "-", "noGravity"];
    g_sCurrentMenu = L_GRAVITY;
    string sPrompt = "Choose '+' for more and '-' for less leash-gravity\n'Default' to revert to the default\nCurrent Gravity = ";
    sPrompt += Float2String(g_vLeashGravity.z) + "\nDefault: 1.0";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

SizeMenu(key kIn, integer iAuth)
{
    list lButtons = ["Default", "+", "-", "minimum"];
    g_sCurrentMenu = L_SIZE;
    string sPrompt = "Choose '+' for bigger and '-' for smaller size of the leash texture\n'Default' to revert to the default\n'minium' for the smallest possible\nCurrent Size = ";
    sPrompt += Float2String(g_vLeashSize.x) + "\nDefault: 0.07 (0.03 steps)";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

ColorCategoryMenu(key kIn, integer iAuth)
{
    //give kAv a dialog with a list of color cards
    string sPrompt = "Pick a Color Category.\n";
    g_sCurrentMenu = "L-ColorCat";
    g_kDialogID = Dialog(kIn, sPrompt, g_lCategories, [UPMENU], 0, iAuth);
}

ColorMenu(key kIn, integer iAuth)
{
    string sPrompt = "Pick a Color.\n";
    list lButtons = llList2ListStrided(g_lColors,0,-1,2);
    g_sCurrentMenu = L_COLOR;
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

TextureMenu(key kIn, integer iAuth)
{
    list lButtons = ["Default"];
    integer iLoop;
    string sName;
    integer iCount = llGetInventoryNumber(0);
    for (iLoop = 0; iLoop < iCount; iLoop++)
    {
        sName = llGetInventoryName(0, iLoop);
        if (sName == "chain" || sName == "rope")
        {
            lButtons += [sName];
        }
        else if (llGetSubString(sName, 0, 5) == "leash_")
        {
            sName = llDeleteSubString(sName, 0, 5);
            if (llStringLength(sName) > 24)
            {
                Notify(kIn, "Omitting '" + sName + "' from texture menu because it is too long.  Please rename it.", TRUE);
            }
            else
            {
                lButtons += [sName];
            }
        }
    }
    lButtons += ["noTexture", "noLeash"];
    g_sCurrentMenu = L_TEXTURE;
    string sPrompt = "Choose a texture\nnoTexture does default SL particle dots\nnoLeash means no particle leash at all\ncurrent Texture = ";
    sPrompt += g_sParticleTexture + "\n";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

LMSay()
{
    llShout(LOCKMEISTER, (string)llGetOwnerKey(g_kLeashedTo) + "collar");
    llShout(LOCKMEISTER, (string)llGetOwnerKey(g_kLeashedTo) +  "handle");
}

integer isInSimOrJustOutside(vector v)
{
    if(v == ZERO_VECTOR || v.x < -25 || v.x > 280 || v.y < -25 || v.y > 280)
        return FALSE;
    return TRUE;
}

default
{
    state_entry()
    {
<<<<<<< HEAD:LSL/OpenCollar - leashParticle.lsl
=======
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
>>>>>>> origin/evolution:LSL/OpenCollar - leashParticle.lsl
        g_lDefaultSettings = [L_TEXTURE, g_sParticleTexture, L_SIZE, "<0.07,0.07,0.07>", L_COLOR, "<1,1,1>", L_DENSITY, "0.04", L_GRAVITY, "<0.0,0.0,-1.0>", "Glow", "1"];
        StopParticles(TRUE);
        FindLinkedPrims();
        SetTexture(g_sParticleTexture, NULLKEY);
        llSleep(1.0);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENTMENU + "|" + SUBMENU, NULL_KEY);
        g_kWearer = llGetOwner();
        //llOwnerSay((string)llGetFreeMemory());
        SetTexture("chain", NULLKEY);
        if (g_kLeashedTo != NULLKEY)
        {
            debug ("entry leash targeted");
            StartParticles(g_kParticleTarget);
        }
    }
    on_rez(integer iRez)
    {
        llResetScript();
    }

    link_message(integer iSenderPrim, integer iNum, string sMessage, key kMessageID)
    {
        if (iNum == COMMAND_PARTICLE)
        {
            g_kLeashedTo = kMessageID;
            if (sMessage == "unleash")
            {
                llSetTimerEvent(0);
                g_bLeasherInRange = FALSE;
                StopParticles(TRUE);
                llListenRemove(g_iLMListener);
                llListenRemove(g_iLMListernerDetach);
            }
            else
            {
                debug("leash active");
                if (g_bInvisibleLeash)
                {// only start the sensor for the leasher
                    g_bLeasherInRange = TRUE;
                    llSetTimerEvent(3.0);
                }
                else
                {
                    integer bLeasherIsAv = (integer)llList2String(llParseString2List(sMessage, ["|"], [""]), 1);
                    g_bLeasherInRange = TRUE;
                    g_kParticleTarget = g_kLeashedTo;
                    StartParticles(g_kParticleTarget);
                    if (bLeasherIsAv)
                    {
                        llListenRemove(g_iLMListener);
                        llListenRemove(g_iLMListernerDetach);
                        if (llGetSubString(sMessage, 0, 10)  == "leashhandle")
                        {
                            g_iLMListener = llListen(LOCKMEISTER, "", "", (string)g_kLeashedTo + "handle ok");
                            g_iLMListernerDetach = llListen(LOCKMEISTER, "", "", (string)g_kLeashedTo + "handle detached");
                        }
                        else
                        {
                            g_iLMListener = llListen(LOCKMEISTER, "", "", "");
                        }
                        LMSay();
                    }
                }
            }
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            if (llToLower(sMessage) == llToLower(SUBMENU))
            {
                if(iNum == COMMAND_OWNER) OptionsMenu(kMessageID, iNum);
                else Notify(kMessageID, "Leash Options can only be changed by Collar Owners.", FALSE);
            }
            else if (sMessage == "menu "+SUBMENU)
            {
                if(iNum == COMMAND_OWNER) OptionsMenu(kMessageID, iNum);
                else
                {
                    Notify(kMessageID, "Leash Options can only be changed by Collar Owners.", FALSE);
                    llMessageLinked(LINK_SET, iNum, "menu "+PARENTMENU, kMessageID);
                }
            }
        }
        else if (iNum == MENUNAME_REQUEST)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENTMENU + "|" + SUBMENU, NULL_KEY);
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kMessageID == g_kDialogID)
            {
                list lMenuParams = llParseString2List(sMessage, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sButton = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sButton == UPMENU)
                {
                    if(g_sCurrentMenu == SUBMENU)
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu " + PARENTMENU, kAv);
                    }
                    else if (g_sCurrentMenu == L_COLOR)
                    {
                        ColorCategoryMenu(kAv, iAuth);
                    }
                    else
                    {
                        OptionsMenu(kAv, iAuth);
                    }
                }
                else if (g_sCurrentMenu == "L-Options")
                {
                    if (sButton == L_DEFAULTS)
                    {
                        SetTexture(GetDefaultSetting(L_TEXTURE), NULLKEY);
                        g_fBurstRate = (float)GetDefaultSetting(L_DENSITY);
                        g_vLeashGravity = (vector)GetDefaultSetting(L_GRAVITY);
                        g_vLeashSize = (vector)GetDefaultSetting(L_SIZE);
                        g_vLeashColor = (vector)GetDefaultSetting(L_COLOR);
                        g_bParticleGlow = (integer)GetDefaultSetting("Glow");
                        g_lSettings = g_lDefaultSettings;
                        Notify(kAv, "Leash-settings restored to collar defaults.", FALSE);
                        // Cleo: as we use standard, no reason to keep the local settings
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, GetScriptID() + "all", NULL_KEY);
                        if (!g_bInvisibleLeash && g_bLeashActive)
                        {
                            StartParticles(g_kParticleTarget);
                        }
                        OptionsMenu(kAv, iAuth);
                    }
                    else if (sButton == L_TEXTURE)
                    {
                        TextureMenu(kAv, iAuth);
                    }
                    else if (sButton == L_COLOR)
                    {
                        ColorCategoryMenu(kAv, iAuth);
                    }
                    else if (sButton == L_DENSITY)
                    {
                        DensityMenu(kAv, iAuth);
                    }
                    else if (sButton == L_GRAVITY)
                    {
                        GravityMenu(kAv, iAuth);
                    }
                    else if (sButton == L_SIZE)
                    {
                        SizeMenu(kAv, iAuth);
                    }
                    else if (llGetSubString(sButton, 0, 3) == "Glow")
                    {
                        g_bParticleGlow = !g_bParticleGlow;
                        SaveSettings("Glow", (string)g_bParticleGlow, TRUE);
                        if (!g_bInvisibleLeash && g_bLeashActive)
                        {
                            StartParticles(g_kParticleTarget);
                        }
                        OptionsMenu(kAv, iAuth);
                    }
                }
                else if (g_sCurrentMenu == "L-ColorCat")
                {
                    g_sCurrentCategory = sButton;
                    integer iIndex = llListFindList(g_lCategories,[sButton]);
                    g_lColors = llParseString2List(llList2String(g_lAllColors, iIndex), ["\n", "|"], []);
                    g_lColors = llListSort(g_lColors, 2, TRUE);
                    ColorMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_COLOR)
                {
                    integer iIndex = llListFindList(g_lColors, [sButton]) +1;
                    if (iIndex)
                    {
                        g_vLeashColor = (vector)llList2String(g_lColors, iIndex);
                        SaveSettings(L_COLOR, Vec2String(g_vLeashColor), TRUE);
                    }
                    if (!g_bInvisibleLeash && g_bLeashActive)
                    {
                        StartParticles(g_kParticleTarget);
                    }
                    ColorMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_TEXTURE)
                {
                    g_bInvisibleLeash = FALSE;
                    if (sButton == "Default")
                    {
                        SetTexture(GetDefaultSetting(L_TEXTURE), kAv);
                    }
                    else if (sButton == "chain")
                    {
                        SetTexture(sButton, kAv);
                    }
                    else if(sButton == "rope")
                    {
                        SetTexture(sButton, kAv);
                    }
                    else if (sButton == "noTexture")
                    {
                        SetTexture(sButton, kAv);
                    }
                    else if (sButton == "noLeash")
                    {
                        SetTexture(sButton, kAv);
                    }
                    else
                    {
                        sButton = "leash_" + sButton;
                        if (llGetInventoryKey(sButton)) //the texture exists
                        {
                            SetTexture(sButton, kAv);
                        }
                    }
                    SaveSettings(L_TEXTURE, g_sParticleTexture, TRUE);
                    TextureMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_DENSITY)
                {
                    if (sButton == "Default")
                    {
                        g_fBurstRate = (float)GetDefaultSetting(L_DENSITY);
                    }
                    else if (sButton == "+")
                    {
                        g_fBurstRate -= 0.01;
                    }
                    else if (sButton == "-")
                    {
                        g_fBurstRate += 0.01;
                    }
                    if (!g_bInvisibleLeash && g_bLeashActive)
                    {
                        StartParticles(g_kParticleTarget);
                    }
                    SaveSettings(L_DENSITY, Float2String(g_fBurstRate), TRUE);
                    DensityMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_GRAVITY)
                {
                    if (sButton == "Default")
                    {
                        g_vLeashGravity = (vector)GetDefaultSetting(L_GRAVITY);
                    }
                    else if (sButton == "+")
                    {
                        if (g_vLeashGravity == <0.0,0.0,-3.0>)
                            Notify(kAv, "You have already reached maximum gravity.", FALSE);
                        else g_vLeashGravity.z -= 0.1;
                    }
                    else if (sButton == "-")
                    {
                        if (g_vLeashGravity == <0.0,0.0,0.0>)
                            Notify(kAv, "You have already reached 0 leash-gravity.", FALSE);
                        else g_vLeashGravity.z += 0.1;
                    }
                    else if (sButton == "noGravity")
                    {
                        g_vLeashGravity = <0.0,0.0,0.0>;
                    }
                    if (!g_bInvisibleLeash && g_bLeashActive)
                    {
                        StartParticles(g_kParticleTarget);
                    }
                    SaveSettings(L_GRAVITY, Float2String(g_vLeashGravity.z), TRUE);
                    GravityMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_SIZE)
                {
                    if (sButton == "Default")
                    {
                        g_vLeashSize = (vector)GetDefaultSetting(L_SIZE);
                    }
                    else if (sButton == "+")
                    {
                        g_vLeashSize.x +=0.03;
                        g_vLeashSize.y +=0.03;
                    }
                    else if (sButton == "-")
                    {
                        if (g_vLeashSize == <0.04,0.04,0.0>)
                        {
                            Notify(kAv, "You have reached the minimum size for particles.", FALSE);
                        }
                        else
                        {
                            g_vLeashSize.x -=0.03;
                            g_vLeashSize.y -=0.03;
                        }
                    }
                    else if (sButton == "minimum")
                    {
                        g_vLeashSize = <0.04,0.04,0.0>;
                    }
                    if (!g_bInvisibleLeash && g_bLeashActive)
                    {
                        StartParticles(g_kParticleTarget);
                    }
                    SaveSettings(L_SIZE, Float2String(g_vLeashSize.x), TRUE);
                    SizeMenu(kAv, iAuth);
                }
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            debug ("LocalSettingsResponse: " + sMessage);
            integer i = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, i - 1);
            string sValue = llGetSubString(sMessage, i + 1, -1);
<<<<<<< HEAD:LSL/OpenCollar - leashParticle.lsl
=======
            i = llSubStringIndex(sToken, "_");
>>>>>>> origin/evolution:LSL/OpenCollar - leashParticle.lsl
            if (sToken == "leash_leashedto")
            {
                g_kLeashedTo = (key)llList2String(llParseString2List(sValue, [","], []), 0);
            }
            else if (PeelToken(sToken, 0) == GetScriptID())
            {
                sToken = PeelToken(sToken, 1);
                if (sToken == "Texture")
                {
                    SetTexture(sValue, NULLKEY);
                    SaveSettings(L_TEXTURE, sValue, FALSE);
                }
                else if (sToken == "Density")
                {
                    g_fBurstRate = (float)sValue;
                    SaveSettings(L_DENSITY, sValue, FALSE);
                }
                else if (sToken == "Gravity")
                {
                    g_vLeashGravity.z = (float)sValue;
                    sValue = Vec2String(g_vLeashGravity);
                    SaveSettings(L_GRAVITY, sValue, FALSE);
                }
                else if (sToken == "Size")
                {
                    g_vLeashSize.x = g_vLeashSize.y = (float)sValue;
                    SaveSettings(L_SIZE, sValue, FALSE);
                    sValue = Vec2String(g_vLeashSize);
                }
                else if (sToken == "Color")
                {
                    g_vLeashColor = (vector)sValue;
                    SaveSettings(L_COLOR, sValue, FALSE);
                }
                else if (sToken == "Glow")
                {
                    if (llToLower(sValue) == "off") g_bParticleGlow = FALSE;
                    else g_bParticleGlow = TRUE;
                }
                SaveDefaultSettings(sToken, sValue);
            }
<<<<<<< HEAD:LSL/OpenCollar - leashParticle.lsl
=======
            else if (sToken == "Global_CType") CTYPE = sValue;
>>>>>>> origin/evolution:LSL/OpenCollar - leashParticle.lsl
            // in case wearer is currently leashed
            if (sMessage == "settings=sent" && g_kLeashedTo != NULLKEY)
            {
                StartParticles(g_kParticleTarget);
            }
        }
        else if (iNum == LM_SETTING_DELETE)
        {
            if (sMessage == "leash_leashedto")
            {
                StopParticles(TRUE);
            }
        }
    }
    listen(integer iChannel, string sName, key kID, string sMessage)
    {
        if (iChannel == LOCKMEISTER)
        {
            //leash holder announced it got detached... send particles to avi
            if (sMessage == (string)g_kLeashedTo + "handle detached")
            {
                g_kParticleTarget = g_kLeashedTo;
                StartParticles(g_kParticleTarget);
            }
            // We heard from a leash holder. re-direct particles
            if (llGetOwnerKey(kID) == g_kLeashedTo)
            {
                sMessage = llGetSubString(sMessage, 36, -1);
                if (sMessage == "collar ok")
                {
                    g_kParticleTarget = kID;
                    StartParticles(g_kParticleTarget);
                }
                if (sMessage == "handle ok")
                {
                    g_kParticleTarget = kID;
                    StartParticles(g_kParticleTarget);
                }
            }
        }
    }

    timer()
    {
        if (isInSimOrJustOutside(llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0)) && llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(g_kLeashedTo,[OBJECT_POS]),0))<60)
        {
            if(!g_bLeasherInRange)
            {
//                llMessageLinked(LINK_THIS, COMMAND_LEASH_SENSOR, "Leasher in range", NULLKEY);
//                LMSay();
                if (g_iAwayCounter)
                {
                    g_iAwayCounter = 0;
                    llSetTimerEvent(3.0);
                }
                StartParticles(g_kParticleTarget);
                g_bLeasherInRange = TRUE;
                //hate this sleep but somehow sometimes this message seems to get lost...
//                llSleep(1.5);
                llMessageLinked(LINK_THIS, COMMAND_LEASH_SENSOR, "Leasher in range", NULLKEY);
                LMSay();
            }
            //actually not needed when using the new leash holder but to be sure not to dangle the leash but releash to avi
            if(llKey2Name(g_kParticleTarget) == "")
            {
                g_kParticleTarget = g_kLeashedTo;
                StartParticles(g_kParticleTarget);
                LMSay();
            }
        }
        else
        {
            if(g_bLeasherInRange)
            {
                StopParticles(FALSE);
                llMessageLinked(LINK_THIS, COMMAND_LEASH_SENSOR, "Leasher out of range", NULLKEY);
                if (g_iAwayCounter > 3)
                {
                    g_bLeasherInRange = FALSE;
                }
            }
            g_iAwayCounter++; //+1 every 3 secs
            if (g_iAwayCounter > 200) //10 mins
            {//slow down the sensor:
                g_iAwayCounter = 1;
                llSetTimerEvent(11.0);
            }
        }
    }
}