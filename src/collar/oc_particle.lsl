////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           OpenCollar - leashParticle                           //
//                                 version 3.988                                  //
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
string UPMENU       = "BACK";
//string MORE         = ">";
string PARENTMENU   = "Leash";
string SUBMENU      = "Particle";
string L_TEXTURE    = "Texture";
string L_DENSITY    = "Density";
string L_COLOR      = "Color";
string L_GRAVITY    = "Gravity";
string L_SIZE       = "Size";
string L_LIFE       = "Life";   // ADDED FOR ST
string L_GLOW       = "Glow";
string L_DEFAULTS   = "ResetDefaults";

// Defalut leash particle, can read from defaultsettings:
// User_leashDefaults=Texture~chain~Size~<0.07,0.07,1.0>~Color~<1,1,1>~Density~-0.04~Gravity~-1.1~Life~3.0~Glow~1
list g_lDefaultSettings = [L_TEXTURE,"chain", L_SIZE,"<0.07,0.07,1.0>", L_COLOR,"<1,1,1>", L_DENSITY,"-0.04", L_GRAVITY,"-1.0", L_LIFE, "3.0", L_GLOW, "0"]; 

list g_lSettings;

string g_sCurrentMenu = "";
key g_kDialogID;

string g_sCurrentCategory = "";
list g_lCategories = ["Shades", "Bright", "Soft"];
list g_lColors;
list g_lAllColors = [
"Light Shade|<0.82745, 0.82745, 0.82745>
Gray Shade|<0.70588, 0.70588, 0.70588>
Dark Shade|<0.20784, 0.20784, 0.20784>
Brown Shade|<0.65490, 0.58431, 0.53333>
Red Shade|<0.66275, 0.52549, 0.52549>
Blue Shade|<0.64706, 0.66275, 0.71765>
Green Shade|<0.62353, 0.69412, 0.61569>
Pink Shade|<0.74510, 0.62745, 0.69020>
Gold Shade|<0.69020, 0.61569, 0.43529>
Black|<0.00000, 0.00000, 0.00000>
White|<1.00000, 1.00000, 1.00000>",
"Magenta|<1.00000, 0.00000, 0.50196>
Pink|<1.00000, 0.14902, 0.50980>
Hot Pink|<1.00000, 0.05490, 0.72157>
Firefighter|<0.88627, 0.08627, 0.00392>
Sun|<1.00000, 1.00000, 0.18039>
Flame|<0.92941, 0.43529, 0.00000>
Matrix|<0.07843, 1.00000, 0.07843>
Electricity|<0.00000, 0.46667, 0.92941>
Violet Wand|<0.63922, 0.00000, 0.78824>
Black|<0.00000, 0.00000, 0.00000>
White|<1.00000, 1.00000, 1.00000>",
"Baby Blue|<0.75686, 0.75686, 1.00000>
Baby Pink|<1.00000, 0.52157, 0.76078>
Rose|<0.93333, 0.64314, 0.72941>
Beige|<0.86667, 0.78039, 0.71765>
Earth|<0.39608, 0.27451, 0.18824>
Ocean|<0.25882, 0.33725, 0.52549>
Yolk|<0.98824, 0.73333, 0.29412>
Wasabi|<0.47059, 1.00000, 0.65098>
Lavender|<0.89020, 0.65882, 0.99608>
Black|<0.00000, 0.00000, 0.00000>
White|<1.00000, 1.00000, 1.00000>"
];

// ----- collar -----
//string g_sWearerName;
string CTYPE = "collar";
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
string g_sScript;

debug(string sText)
{
    //llOwnerSay(llGetScriptName() + " DEBUG: " + sText);
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
//vector g_vLeashSize = <0.22, 0.17, 0.0>;    // CHANGED FROM DEFAULT <0.07, 0.07, 1.0>, JEAN SEVERINE 2012-02-22
vector g_vLeashSize = <0.07, 0.07, 1.0>;    // CHANGED back
integer g_bParticleGlow = TRUE;
float g_fParticleAge = 1.0;
float g_fParticleAlpha = 1.0;
vector g_vLeashGravity = <0.0,0.0,-1.0>;
integer g_iParticleCount = 1;
float g_fBurstRate = 0.04;
//same g_lSettings but to store locally the default settings recieved from the defaultsettings note card, using direct string here to save some bits


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

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
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
    integer i = llSubStringIndex(out, ".");
    while (~i && llStringLength(llGetSubString(out, i + 2, -1)) && llGetSubString(out, -1, -1) == "0")
    {
        out = llGetSubString(out, 0, -2);
    }
    return out;
}

SaveSettings(string sToken, string sValue, integer bSaveToLocal)
{
    integer iIndex = llListFindList(g_lSettings, [sToken]);
    if (iIndex>=0) 
    {
        g_lSettings = llListReplaceList(g_lSettings, [sValue], iIndex +1, iIndex +1);
    }
    else
    {
        g_lSettings += [sToken, sValue];
    }    
    if (bSaveToLocal)
    {
        llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + sToken + "=" + sValue, "");
    }
}

SaveDefaultSettings(string sToken, string sValue)
{
    integer index = llListFindList(g_lDefaultSettings, [sToken]);
    if (index>=0)
    {
        g_lDefaultSettings = llListReplaceList(g_lDefaultSettings, [sValue], index+1, index+1);
    }
    else
    {
        g_lDefaultSettings += [sToken, sValue];
    }
}

string GetDefaultSetting(string sToken)
{
    integer index = llListFindList(g_lDefaultSettings, [sToken]);
    return llList2String(g_lDefaultSettings, index + 1);
}

string GetSetting(string sToken)
{
    integer index = llListFindList(g_lSettings, [sToken]);
    if (index != -1) return llList2String(g_lSettings, index + 1);
    else return GetDefaultSetting(sToken); // return from defaultsettings if not present
}

// get settings before StartParticles
GetSettings()
{
    g_fBurstRate = (float)GetSetting(L_DENSITY);
    g_vLeashGravity.z = (float)GetSetting(L_GRAVITY);
    g_vLeashSize = (vector)GetSetting(L_SIZE);
    g_fParticleAge = (float)GetSetting(L_LIFE);  // ADDED FOR ST
    g_vLeashColor = (vector)GetSetting(L_COLOR);
    //g_bParticleGlow = (integer)GetSetting(L_GLOW);
    string glow = llToLower(GetSetting(L_GLOW));
    if (glow == "off" || glow == "0") g_bParticleGlow = 0 ;
    if (glow == "on" || glow == "1") g_bParticleGlow = 1 ;
    SetTexture(GetSetting(L_TEXTURE), NULLKEY);
}

// Added bSave as a boolean, to make this a more versatile wrapper
SetTexture(string sIn, key kIn)
{
    g_sParticleTexture = sIn;
    if (sIn=="chain"){
        g_sParticleTextureID="4cde01ac-4279-2742-71e1-47ff81cc3529";
    } else if (sIn=="rope"){
        g_sParticleTextureID="9a342cda-d62a-ae1f-fc32-a77a24a85d73";
    } else if (sIn=="totallytransparent"){
        g_sParticleTextureID="bd7d7770-39c2-d4c8-e371-0342ecf20921";
    } else {
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
        if(g_sParticleTextureID == NULL_KEY) g_sParticleTextureID=sIn; //for textures without full perm, we send the texture name. For this to work, texture must be in the emitter prim as well as in root, if different.
    }        
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
    list lButtons = [L_TEXTURE, L_DENSITY, L_GRAVITY, L_COLOR, L_SIZE, L_LIFE];
    if (g_bParticleGlow)
    {
        lButtons += "GlowOff";
    }
    else
    {
        lButtons += "GlowOn";
    }
    lButtons += [L_DEFAULTS];
    string sPrompt = "\nCustomize the looks and feel of your leash.";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

DensityMenu(key kIn, integer iAuth)
{
    list lButtons = ["+", "−", "Default"];
    g_sCurrentMenu = L_DENSITY;
    string Default = GetDefaultSetting(L_DENSITY);
    string sPrompt = "\nChoose + for more and − for less particles\n'Default' to revert to the default: "+Default;
    sPrompt += "\n\nCurrent Density = "+Float2String(g_fBurstRate) ;// BurstRate is opposite the implied effect of density
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

GravityMenu(key kIn, integer iAuth)
{
    list lButtons = ["+", "−", "Default", "noGravity"];
    g_sCurrentMenu = L_GRAVITY;
    string Default = GetDefaultSetting(L_GRAVITY);
    string sPrompt = "\nChoose + for more and − for less leash-gravity\n'Default' to revert to the default: "+Default; 
    sPrompt += "\n\nCurrent Gravity = "+Float2String(g_vLeashGravity.z) ;
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

SizeMenu(key kIn, integer iAuth)
{
    list lButtons = ["X+", "Y+", "Default", "X-", "Y-", "MIN"];   // ADDED FOR ST changed "minimum" to "MIN"
    g_sCurrentMenu = L_SIZE;
    vector defaultsize = (vector)GetDefaultSetting(L_SIZE);    
    string sPrompt = "\nChoose '+' for bigger and '-' for smaller size of the leash texture";
    sPrompt += "\n'Default' to revert to the default size: "+Float2String(defaultsize.x)+" x "+Float2String(defaultsize.y);
    sPrompt += "\n'MIN' for the smallest possible: 0.04 x 0.04\n" ; 
    sPrompt += "\nCurrent Size = "+ Float2String(g_vLeashSize.x)+" x "+Float2String(g_vLeashSize.y) + "  (0.03 steps)";
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

LifeMenu(key kIn, integer iAuth)   // ADDED FOR ST
{
    list lButtons = ["+0.1", "+0.5", "Default", "-0.1", "-0.5", "MIN"];
    g_sCurrentMenu = L_LIFE;
    string sPrompt = "\nChoose '+' for longer or '-' for shorter life,";
    sPrompt += "\n'Default' to revert to the default life: "+GetDefaultSetting(L_LIFE); 
    sPrompt += "\n'MIN' for the shortest life: 0.1\n";
    sPrompt += "\nCurrent Life = "+llGetSubString((string)g_fParticleAge,0,2);
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

ColorCategoryMenu(key kIn, integer iAuth)
{
    //give kAv a dialog with a list of color cards
    string sPrompt = "\nChoose a color category.";
    g_sCurrentMenu = "L-ColorCat";
    g_kDialogID = Dialog(kIn, sPrompt, g_lCategories, [UPMENU], 0, iAuth);
}

ColorMenu(key kIn, integer iAuth)
{
    string sPrompt = "\nChoose a color.";
    list lButtons = llList2ListStrided(g_lColors,0,-1,2);
    g_sCurrentMenu = L_COLOR;
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

TextureMenu(key kIn, integer iAuth)
{
    list lButtons = ["Default", "chain","rope"];
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
    string sPrompt = "\nChoose a texture\nnoTexture does default SL particle dots\nnoLeash means no particle leash at all\n\nCurrent Texture = ";
    sPrompt += g_sParticleTexture;
    g_kDialogID = Dialog(kIn, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

LMSay()
{
    llShout(LOCKMEISTER, (string)llGetOwnerKey(g_kLeashedTo) + "collar");
    llShout(LOCKMEISTER, (string)llGetOwnerKey(g_kLeashedTo) +  "handle");
}

default
{
    state_entry()
    {
        g_sScript = "leashParticle_";
        g_kWearer = llGetOwner();
        FindLinkedPrims();
        StopParticles(TRUE);
        //SetTexture(g_sParticleTexture, NULLKEY);
        //llSleep(1.0);
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENTMENU + "|" + SUBMENU, "");
                
        //SetTexture("chain", NULLKEY);
        //if (g_kLeashedTo != NULLKEY)
       // {
       //     debug ("entry leash targeted");
         //   StartParticles(g_kParticleTarget);
        //}        
        llListen(COMMAND_PARTICLE,"","","");    // ADDED FOR BETA 0.1
        //llOwnerSay((string)llGetFreeMemory());
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
                StopParticles(TRUE);
                llListenRemove(g_iLMListener);
                llListenRemove(g_iLMListernerDetach);
            }
            else
            {
                debug("leash active");
                if (! g_bInvisibleLeash)
                {
                    integer bLeasherIsAv = (integer)llList2String(llParseString2List(sMessage, ["|"], [""]), 1);
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
                else Notify(kMessageID, "Leash Options can only be changed by " + CTYPE + " Owners.", FALSE);
            }
            else if (sMessage == "menu "+SUBMENU)
            {
                if(iNum == COMMAND_OWNER) OptionsMenu(kMessageID, iNum);
                else
                {
                    Notify(kMessageID, "Leash Options can only be changed by " + CTYPE + " Owners.", FALSE);
                    llMessageLinked(LINK_SET, iNum, "menu "+PARENTMENU, kMessageID);
                }
            }
        }
        else if (iNum == MENUNAME_REQUEST && sMessage == PARENTMENU)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENTMENU + "|" + SUBMENU, "");
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
                else if (g_sCurrentMenu == "Particle")
                {
                    if (sButton == L_DEFAULTS)
                    {
                        g_lSettings = []; // clear current settings
                        Notify(kAv, "Leash-settings restored to " + CTYPE + " defaults.", FALSE);
                        // Cleo: as we use standard, no reason to keep the local settings
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "all", "");
                        if (!g_bInvisibleLeash && g_bLeashActive)
                        {
                            GetSettings(); // get settings before 
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
                    else if (sButton == L_LIFE) // ADDED FOR ST
                    {
                        LifeMenu(kAv, iAuth);
                    }
                    else if (llGetSubString(sButton, 0, 3) == L_GLOW)
                    {
                        g_bParticleGlow = !g_bParticleGlow;
                        SaveSettings(L_GLOW, (string)g_bParticleGlow, TRUE);
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
                        if (llGetInventoryType(sButton)==INVENTORY_TEXTURE) //the texture exists
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
                    else if (sButton == "−")
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
                        g_vLeashGravity.z = (float)GetDefaultSetting(L_GRAVITY);
                    }
                    else if (sButton == "+")
                    {
                        g_vLeashGravity.z -= 0.1;
                        if (g_vLeashGravity.z < -3.0)
                        {
                            g_vLeashGravity.z = -3.0;
                            Notify(kAv, "You have already reached maximum gravity.", FALSE);
                        } 
                    }
                    else if (sButton == "−")
                    {
                        g_vLeashGravity.z += 0.1;
                        if (g_vLeashGravity.z > 0.0)
                        {
                            g_vLeashGravity.z = 0.0 ;
                            Notify(kAv, "You have already reached 0 leash-gravity.", FALSE);
                        }
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
                    else if (sButton == "X+")
                    {
                        g_vLeashSize.x +=0.03;
                    }
                    else if (sButton == "Y+")
                    {
                        g_vLeashSize.y +=0.03;
                    }
                    else if (sButton == "X-")
                    {
                        g_vLeashSize.x -=0.03;                        
                        if (g_vLeashSize.x < 0.04)
                        {
                            g_vLeashSize.x = 0.04 ;
                            Notify(kAv, "You have reached the minimum size for particles.", FALSE);
                        }
                    }
                    else if (sButton == "Y-")
                    {
                        g_vLeashSize.y -=0.03;
                        if (g_vLeashSize.y < 0.04)
                        {
                            g_vLeashSize.y = 0.04 ;
                            Notify(kAv, "You have reached the minimum size for particles.", FALSE);
                        }
                    }
                    else if (sButton == "MIN")  // ADDED FOR ST changed "minimum" to "MIN"
                    {
                        g_vLeashSize = <0.04,0.04,0.0>;
                    }
                    if (!g_bInvisibleLeash && g_bLeashActive)
                    {
                        StartParticles(g_kParticleTarget);
                    }
                    SaveSettings(L_SIZE, Vec2String(g_vLeashSize), TRUE);
                    SizeMenu(kAv, iAuth);
                }
                else if (g_sCurrentMenu == L_LIFE)  // ADDED FOR ST
                {
                    if (sButton == "Default")
                    {
                        g_fParticleAge = (float)GetDefaultSetting(L_LIFE);
                    }
                    else if (sButton == "+0.5")
                    {
                        g_fParticleAge += 0.5;
                    }
                    else if (sButton == "-0.5")
                    {
                        //if (g_fParticleAge <= 0.5)
                        //{
                        //    Notify(kAv, "Use the -0.1 button to reach minimum particle life.", FALSE);
                        //}
                        //else
                        //{
                            g_fParticleAge -= 0.5;
                        //}
                        
                        if (g_fParticleAge < 0.1)
                        {
                            g_fParticleAge = 0.1;
                            Notify(kAv, "You have reached minimum particle life.", FALSE);
                        }
                    }
                    else if (sButton == "+0.1")
                    {
                        g_fParticleAge += 0.1;
                    }
                    else if (sButton == "-0.1")
                    {
                        g_fParticleAge -= 0.1;
                        if (g_fParticleAge < 0.1)
                        {
                            g_fParticleAge = 0.1;
                            Notify(kAv, "You have reached minimum particle life.", FALSE);
                        }
                    }
                    else if (sButton == "MIN")
                    {
                        g_fParticleAge = 0.1;
                    }
                    if (!g_bInvisibleLeash && g_bLeashActive)
                    {
                        StartParticles(g_kParticleTarget);
                    }
                    SaveSettings(L_LIFE, Float2String(g_fParticleAge), TRUE);
                    LifeMenu(kAv,iAuth);
                }
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            debug ("LocalSettingsResponse: " + sMessage);
            integer i = llSubStringIndex(sMessage, "=");
            string sToken = llGetSubString(sMessage, 0, i - 1);
            string sValue = llGetSubString(sMessage, i + 1, -1);
            i = llSubStringIndex(sToken, "_");
            if (sToken == "leash_leashedto")
            {
                g_kLeashedTo = (key)llList2String(llParseString2List(sValue, [","], []), 0);
            }
            else if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                // load current settings
                sToken = llGetSubString(sToken, i + 1, -1);                
                SaveSettings(sToken, sValue, FALSE);
                SaveDefaultSettings(sToken, sValue);
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
            // in case wearer is currently leashed
            else if (sMessage == "settings=sent")             
            {
                GetSettings(); // get settings before
                if (g_kLeashedTo != NULLKEY) StartParticles(g_kParticleTarget);
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
        // ADDED BELOW FOR BETA 0.1  TOGGLES LEASH PARTICLES OFF IF COFFLES BEING USED.        
        else if(iChannel == COMMAND_PARTICLE)
        {
            if(llGetOwnerKey(kID) == g_kWearer)
            {
                integer currentglow;
                
                if(sMessage == "noLeash")
                {
                    currentglow = g_bParticleGlow;
                    g_bParticleGlow = FALSE;
                    SetTexture(sMessage, g_kWearer);
                    StartParticles(g_kParticleTarget);
                }
                
                if(sMessage == "chain")
                {
                    g_bParticleGlow = currentglow;
                    SetTexture(sMessage, g_kWearer);
                    StartParticles(g_kParticleTarget);
                }      
            }
        }
    }
}
