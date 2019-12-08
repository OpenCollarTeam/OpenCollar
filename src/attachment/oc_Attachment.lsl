
// This file is part of OpenCollar.
// Copyright (c) 2019 lillith xue      
// Licensed under the GPLv2.  See LICENSE for full details.

integer g_iChan_ocCmd;                      // OpenCollar CMD Channel
integer g_iChan_ocCmd_Offset = 0xCC0CC;     // OpenCollar CMD Channel Offset

integer g_iChan_OCChain = -9889;
integer g_iChan_Lockguard = -9119;          // Lockguard listen Channel 
integer g_iChan_Lockmeister = -8888;        // LockMeister listen Channel

integer LINK_CHAN_API = -1000;

key g_kWearer = NULL_KEY;

key g_kTexture = "4cde01ac-4279-2742-71e1-47ff81cc3529";
float g_fSizeX = 0.04;
float g_fSizeY = 0.04;
float g_fLife = 4.0;
float g_fGravity = 0.01;
float g_fMinSpeed = 0.090;
float g_fMaxSpeed = 0.090;
float g_fRed = 1;
float g_fGreen = 1;
float g_fBlue = 1;
integer g_bRibbon = FALSE;

string g_sNCName = "Poses";
integer g_iNCLine = 0;
key g_kNCQuery;

list g_lSelectedPose = [];
list g_lPoses = [];
list g_lActivePoseIndexes = [];

list g_lCategory = [];
integer g_iCategoryIndex = 0;

integer g_bLocked = FALSE;
integer g_bRLV = FALSE;
integer g_bHide = FALSE;
integer g_bTMPUnhide = FALSE;
integer g_bDoHide = TRUE;

integer g_iTargetedBy = 0;
list g_lCurrentChains = [];
list g_lHidePrims = [];

list g_lMyPoints = [];


list g_lPoints = [        // occ, lockmeister, lockguard, alt1, alt2
    "rlac"      , "rcuff"       , "rightwrist"          , "wrists"  , "allfour" ,   // right lower arm cuff
    "frlac"     , "frcuff"      , "frontrightwrist"     , ""        , ""        ,   // front right lower arm cuff
    "brlac"     , "brcuff"      , "backrightwrist"      , ""        , ""        ,   // back right lower arm cuff
    "irlac"     , "ircuff"      , "innerrightwrist"     , ""        , ""        ,   // inner right lower arm cuff
    
    "llac"      , "lcuff"       , "leftwrist"           , "wrists"  , "allfour" ,   // left lower arm cuff
    "fllac"     , "flcuff"      , "frontleftwrist"      , ""        , ""        ,   // front left lower arm cuff
    "bllac"     , "blcuff"      , "backleftwrist"       , ""        , ""        ,   // back left lower arm cuff
    "illac"     , "ilcuff"      , "innterleftwrist"     , ""        , ""        ,   // inner left lower arm cuff
    
    "ruac"      , "rbiceps"     , "rightupperarm"       , "arms"    , ""        ,   // right upper arm cuff
    "fruac"     , "frbiceps"    , "frontrightupperarm"  , ""        , ""        ,   // front right upper arm cuff
    "bruac"     , "brbiceps"    , "backrightupperarm"   , ""        , ""        ,   // back right upper arm cuff
    "iruac"     , "irbiceps"    , "innerrightupperarm"  , ""        , ""        ,   // inner right upper arm cuff
    
    "luac"      , "lbiceps"     , "leftupperarm"        , "arms"    , ""        ,   // left upper arm cuff
    "fluac"     , "flbiceps"    , "frontleftupperarm"   , ""        , ""        ,   // front left upper arm cuff
    "bluac"     , "blbiceps"    , "backleftupperarm"    , ""        , ""        ,   // back left upper arm cuff
    "iluac"     , "ilbiceps"    , "innerleftupperarm"   , ""        , ""        ,   // inner left uuper arm cuff
    
    "rllc"      , "rlcuff"      , "rightankle"          , "ankles"  , "allfour" ,   // right lower leg cuff
    "frllc"     , "frlcuff"     , "frontrightankle"     , ""        , ""        ,   // front right lower leg cuff
    "brllc"     , "brlcuff"     , "backrightankle"      , ""        , ""        ,   // back right lower leg cuff
    "irllc"     , "irlcuff"     , "innerrightankle"     , ""        , ""        ,   // inner right lower leg cuff
    
    "lllc"      , "llcuff"      , "leftankle"           , "ankles"  , "allfour" ,   // left lower leg cuff
    "flllc"     , "fllcuff"     , "frontleftankle"      , ""        , ""        ,   // front left lower leg cuff
    "blllc"     , "bllcuff"     , "backleftankle"       , ""        , ""        ,   // back left lower leg cuff
    "illlc"     , "illcuff"     , "innerleftankle"      , ""        , ""        ,   // inner left lower leg cuff
    
    "rulc"      , "rthigh"      , "rightupperthigh"     , "thighs"  , "rtigh"   ,   // right upper leg cuff
    "frulc"     , "frthigh"     , "frontrightupperthigh", ""        , ""        ,   // front right upper leg cuff
    "brulc"     , "brthigh"     , "backrightupperthigh" , ""        , ""        ,   // back right upper leg cuff
    "irulc"     , "irthigh"     , "innerrightupperthigh", ""        , ""        ,   // inner right upper leg cuff
    
    "lulc"      , "lthigh"      , "leftupperthigh"      , "thighs"  , "ltigh"   ,   // left upper leg cuff
    "flulc"     , "flthigh"     , "frontleftupperthigh" , ""        , ""        ,   // front left upper leg cuff
    "blulc"     , "blthigh"     , "backleftupperthigh"  , ""        , ""        ,   // back left upper leg cuff
    "ilulc"     , "ilthigh"     , "innerleftupperthigh" , ""        , ""        ,   // inner left upper leg cuff
    
    "fbelt"     , "fbelt"       , "frontbeltloop"       , ""        , ""        ,   // belt front
    "bbelt"     , "bbelt"       , "backbeltloop"        , ""        , ""        ,   // belt back
    "rbelt"     , "rfbelt"      , "rightbeltloop"       , "rbbelt"  , ""        ,   // belt right
    "lbelt"     , "lfbelt"      , "leftbeltloop"        , "lbbelt"  , ""        ,   // belt left
    
    "wingl"     , "lwing"       , "leftwing"            , "wings"   , ""        ,   // wing left
    "wingr"     , "rwing"       , "rightwing"           , "wings"   , ""        ,   // wing right
    
    "taill"     , "ltail"       , "lefttail"            , "tails"   , ""        ,   // tail left
    "tailr"     , "rtail"       , "righttail"           , "tails"   , ""        ,   // trail right
    
    "fcollar"   , "collar"      , "collarfrontloop"     , ""        , ""        ,   // Collar Front
    "lcollar"   , "lcollar"     , "collarleftloop"      , ""        , ""        ,   // Collar Left
    "rcollar"   , "rcollar"     , "collarrightloop"     , ""        , ""        ,   // Collar Right
    "bcollar"   , "bcollar"     , "collarbackloop"      , ""        , ""        ,    // Collar Back
    
    "lear"      , "lear"        , "leftearring"         , "ears"    , ""        ,   // left ear 
    "rear"      , "rear"        , "rightearring"        , "ears"    , ""        ,   // right ear 
    
    "nose"      , "nose"        , "nosering"            , ""        , ""        ,   // nose ring
    "lnose"     , "lnose"       , "leftnosering"        , ""        , ""        ,   // left nose 
    "rnose"     , "rnose"       , "rightnosering"       , ""        , ""        ,   // right nose 
    
    "ulip"      , "ulip"        , "upperlipring"        , "lips"    , ""        ,   // upper lip 
    "llip"      , "llip"        , "lowerlipring"        , "lips"    , ""        ,   // lower lip 
    
    "tongue"    , "tongue"      , "tonguering"          , ""        , ""        ,   // tongue 
    
    "gag"       , "gag"         , "gag"                 , ""        , ""        ,   // gag
    "lgag"      , "lbit"        , "leftgag"             , ""        , ""        ,   // left gag
    "rgag"      , "rbit"        , "rightgag"            , ""        , ""        ,   // right gag
    
    "thh"       , "thead"       , "topheadharness"      , ""        , ""        ,   // top head harness
    "fhh"       , "fhharness"   , "frontheadharness"    , ""        , ""        ,   // front head harness
    "bhh"       , "bhharness"   , "backheadharness"     , ""        , ""        ,   // back head harness
    "lhh"       , "lhharness"   , "leftheadharness"     , ""        , ""        ,   // left head harness
    "rhh"       , "rhharness"   , "rightheadharness"    , ""        , ""        ,   // right head harness
    
    "lnipple"   , "lnipple"     , "leftnipplering"      , "nipples" , ""        ,   // left nipple 
    "rnipple"   , "rnipple"     , "rightnipplering"     , "nipples" , ""        ,   // right nipple 
    
    "fh"        , "fharness"    , "harnessfrontloop"    , ""        , ""        ,   // front harness
    "bh"        , "back"        , "harnessbackloop"     , ""        , ""        ,   // back harness
    "lfh"       , "lfharness"   , "harnessleftloopfront", ""        , ""        ,   // left front harness
    "rfh"       , "rfharness"   , "harnessrightloopfront", ""       , ""        ,   // right front harness
    "lbh"       , "lbharness"   , "harnessleftloopback" , ""        , ""        ,   // left back harness
    "rbh"       , "rbharness"   , "harnessrightloopback", ""        , ""        ,   // right back harness
    "rsh"       , "rblade"      , "harnessrightshoulderloop", ""    , ""        ,   // right shoulder harness
    "lsh"       , "lblade"      , "harnessleftshoulderloop", ""     , ""        ,   // left shoulder harness
    
    "belly"     , "chest"       , "bellyring"           , ""        , ""        ,   // belly ring
    
    "clit"      , "pelvis"      , "clitring"            , ""        , ""        ,   // clit ring
    
    "llabia"    , "labia"       , "leftlabia"           , ""        , ""        ,   // left labia
    "rlabia"    , "rlabia"      , "rightlabia"          , ""        , ""        ,   // right labia
    
    "cock"      , "pelvis"      , "cockring"            , ""        , ""        ,   // cock
    "ball"      , "ball"        , "ballring"            , ""        , ""        ,   // balls
    "butt"      , "butt"        , "buttplug"            , ""        , ""            // buttplug
];

doChain(string sSource, key kTarget, integer bEnable) {
    integer iSource = llList2Integer(g_lMyPoints, llListFindList(g_lMyPoints,[sSource])+1);
    if (iSource > 1) {
        if (bEnable) {
            integer iBitField = PSYS_PART_TARGET_POS_MASK|PSYS_PART_FOLLOW_VELOCITY_MASK|PSYS_PART_FOLLOW_SRC_MASK;
            
            if (g_bRibbon) iBitField = iBitField | PSYS_PART_RIBBON_MASK;
            
            llLinkParticleSystem(iSource, [] );
            llLinkParticleSystem(iSource, [ 
                PSYS_PART_MAX_AGE, g_fLife, 
                PSYS_PART_FLAGS, iBitField, 
                PSYS_PART_START_COLOR, <g_fRed,g_fGreen,g_fBlue>,  
                PSYS_PART_START_SCALE, <g_fSizeX, g_fSizeY, 1>, 
                PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP, 
                PSYS_SRC_BURST_RATE, 0.000000, 
                PSYS_SRC_ACCEL, <0.00000, 0.00000, (g_fGravity*-1)>, 
                PSYS_SRC_BURST_PART_COUNT, 1,  
                PSYS_SRC_MAX_AGE, 0.000000,
                PSYS_SRC_TARGET_KEY,kTarget,
                PSYS_SRC_TEXTURE, g_kTexture ]);
            
            if (llListFindList(g_lCurrentChains,[sSource]) == -1) g_lCurrentChains += [sSource,kTarget];
            
            g_bTMPUnhide = TRUE;
            doHide();
            //llOwnerSay("doChain from '"+sSource+"' to '"+(string)kTarget+"'");
        } else {
            llLinkParticleSystem(iSource, [] );
            integer iIndex = llListFindList(g_lCurrentChains,[sSource]);
            if (iIndex > -1) g_lCurrentChains = llDeleteSubList(g_lCurrentChains,iIndex,iIndex+1);
            
            if (llGetListLength(g_lCurrentChains) < 1 && g_iTargetedBy < 1) {
                g_bTMPUnhide = FALSE;
                doHide();
            }
            //llOwnerSay("remove Chain from '"+sSource+"'");
        }
    }
}

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
            doChain(llList2String(llGetLinkPrimitiveParams(i,[PRIM_NAME]),0),NULL_KEY,FALSE);
        }
        g_iTargetedBy = 0;
    } else {
        list lRemChains = [];
        list lChains = llParseString2List(sChainCMD,["~"],[]);
        integer i;
        for (i=0;i<llGetListLength(lChains);++i) {
            list lChain = llParseString2List(llList2String(lChains,i),["="],[]);
            string sSource = llList2String(lChain,0);
            string sTarget = llList2String(lChain,1);
            
            lRemChains += [sSource];
            
            if (llListFindList(g_lMyPoints,[sTarget]) > -1) g_iTargetedBy = g_iTargetedBy - 1;
            
        }
        
        for (i=1;i<llGetNumberOfPrims()+1;++i)
        {
            string sDesc = llList2String(llGetLinkPrimitiveParams(i,[PRIM_NAME]),0);
            if (llListFindList(lRemChains,[sDesc]) > -1) doChain(sDesc,NULL_KEY,FALSE);
        }
    }
    integer i;
    for (i=0; i<llGetListLength(g_lActivePoseIndexes);++i){ // reapply pose chains
        doPose(llList2String(g_lPoses,llList2Integer(g_lActivePoseIndexes,i)));
    }
    
    if (g_iTargetedBy < 1 && llGetListLength(g_lCurrentChains) < 1){
        g_iTargetedBy = 0;
        g_bTMPUnhide = FALSE;
        doHide();
    }
}

ParseOcChains(string sChainCMD)
{
    list lChains = llParseString2List(sChainCMD,["~"],[]);
    integer i;
    for (i=0; i<llGetListLength(lChains);++i)
    {
        key kSource = g_kWearer;
        key kTarget = g_kWearer;
    
        list lChain = llParseString2List(llList2String(lChains,i),["="],[]);
        string sSource = llList2String(lChain,0);
        list lSource = llParseString2List(sSource,["/"],[]);
        if (llGetListLength(lSource) > 1){ 
            kSource = llList2Key(lSource,0);
            sSource = llList2String(lSource,1);
        }
        
        string sTarget = llList2String(lChain,1);
        list lTarget = llParseString2List(sTarget,["/"],[]);
        if (llGetListLength(lTarget) > 1) {
            kTarget = llList2Key(lTarget,0);
            sTarget = llList2String(lTarget,1);
        }
        
        if (llListFindList(g_lMyPoints,[sTarget]) > -1 && kTarget == g_kWearer) { // if we are the target, send our key
            llRegionSayTo(kSource,g_iChan_OCChain,"occhain:"+sSource+"="+(string)findPrimKey(sTarget));
            g_iTargetedBy++;
            g_bTMPUnhide = TRUE;
            doHide();
        }
        
    }
}

doOcChain(string sChainCMD)
{
    list lChain = llParseString2List(sChainCMD,["="],[]);
    string sSource = llList2String(lChain,0);
    key kTarget = llList2String(lChain,1);
    
    if (kTarget != NULL_KEY && kTarget != "") doChain(sSource,kTarget,TRUE);
}

doPose(string sPoseName){
    llRequestPermissions(g_kWearer,PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS);
    integer iPoseIndex = llListFindList(g_lPoses,[sPoseName]);
    if (iPoseIndex > -1) {
        if (llListFindList(g_lActivePoseIndexes,[iPoseIndex]) > -1) return; //undoPose(sPoseName);
        
        g_lActivePoseIndexes += [iPoseIndex];
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStartAnimation(llList2String(g_lPoses,iPoseIndex+1));
        else llOwnerSay("ERROR: Lost Animation permission!");
        ParseOcChains(llList2String(g_lPoses,iPoseIndex+2)); // do our own chains
        llRegionSayTo(g_kWearer,g_iChan_OCChain,"occhains:"+llList2String(g_lPoses,iPoseIndex+2)); // Tell the others to do chains
        list lCatPose = llParseString2List(sPoseName,["|"],[]);
        SendRLV(llList2String(g_lPoses,iPoseIndex+3),llList2String(lCatPose,0),TRUE);
    
    }
}

undoPose(string sPoseName){
    llRequestPermissions(g_kWearer,PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS);
    integer iPoseIndex = llListFindList(g_lPoses,[sPoseName]);
    if (iPoseIndex > -1) {
        integer iActiveIndex = llListFindList(g_lActivePoseIndexes,[iPoseIndex]);
        if (iActiveIndex > -1) g_lActivePoseIndexes = llDeleteSubList(g_lActivePoseIndexes,iActiveIndex,iActiveIndex);
        
        if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) llStopAnimation(llList2String(g_lPoses,iPoseIndex+1));
        doClearChain(llList2String(g_lPoses,iPoseIndex+2)); // do Clear our own Chains
        llRegionSayTo(g_kWearer,g_iChan_OCChain,"clearchain:"+llList2String(g_lPoses,iPoseIndex+2)); // Tell the others to clear chains
        list lCatPose = llParseString2List(sPoseName,["|"],[]);
        SendRLV(llList2String(g_lPoses,iPoseIndex+3),llList2String(lCatPose,0),FALSE);
    }
}


integer CheckBuild() {
    g_lMyPoints = [];
    g_lHidePrims = [];
    integer i;
    for (i=1; i<llGetNumberOfPrims()+1;++i) {
        string sDesc = llList2String(llGetLinkPrimitiveParams(i,[PRIM_NAME]),0);
        integer iIndex = llListFindList(g_lPoints, [sDesc]);
        if (iIndex > -1 && sDesc != "") {
            g_lMyPoints += llList2String(g_lPoints,iIndex);
            g_lMyPoints += i;
            if (llList2String(g_lPoints,iIndex+1) != "") g_lMyPoints += [llList2String(g_lPoints,iIndex+1),i];
            if (llList2String(g_lPoints,iIndex+2) != "") g_lMyPoints += [llList2String(g_lPoints,iIndex+2),i];
            if (llList2String(g_lPoints,iIndex+3) != "") g_lMyPoints += [llList2String(g_lPoints,iIndex+3),i];
            if (llList2String(g_lPoints,iIndex+4) != "") g_lMyPoints += [llList2String(g_lPoints,iIndex+4),i];
            llLinkParticleSystem(i, [] );
        } 
       
        integer bHideable = TRUE;
        sDesc = llList2String(llGetLinkPrimitiveParams(i,[PRIM_DESC]),0);
        list lParams = llParseString2List(sDesc,["~"],[]);
        integer j;
        for (j=0;j<llGetListLength(lParams);++j){
            if (llList2String(lParams,j) == "nohide") bHideable = FALSE;
        }
        if (bHideable) g_lHidePrims += [i];
    }
    
    if (llGetListLength(g_lMyPoints) > 0) g_lPoints = [];   // Free Memory
    else {
        llOwnerSay("ERROR: No chainpoint found!");
        return FALSE;
    }
    
    return TRUE;
}

init() {
    if (CheckBuild()) {
        g_iChan_ocCmd = (integer)("0x"+llGetSubString((string)g_kWearer,3,8)) + g_iChan_ocCmd_Offset;
        if (g_iChan_ocCmd>0) g_iChan_ocCmd=g_iChan_ocCmd*(-1);
        if (g_iChan_ocCmd > -10000) g_iChan_ocCmd -= 30000;
        
        //llOwnerSay("MyCHannel: "+(string)g_iChan_ocCmd);
        
        llListen(g_iChan_ocCmd, "", NULL_KEY, "");      // Listen to Collar Commands
        llListen(g_iChan_OCChain, "", NULL_KEY, "");    // Listen to OCChain Channel
        llListen(g_iChan_Lockguard, "", NULL_KEY, "");  // Listen to Lockguard Channel
        llListen(g_iChan_Lockmeister, "", NULL_KEY, "");// Listen to Lockmeister Channel
        
        doClearChain("all");
        
        g_lPoses = [];
        g_lSelectedPose = [];
        
        g_lCategory = getCategorys();
        g_iCategoryIndex = 0;
        if (llGetListLength(g_lCategory) > g_iCategoryIndex) {
            g_sNCName = llList2String(g_lCategory,g_iCategoryIndex);
            g_iNCLine = 0;
            llOwnerSay("Loading "+g_sNCName+"...");
            g_kNCQuery = llGetNotecardLine(g_sNCName,g_iNCLine);
        } else llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer + ":ping");
    }
}

list getCategorys() {
    list result = [];
    integer i;
    for (i=0; i<llGetInventoryNumber(INVENTORY_NOTECARD);++i) {
        result += [llGetInventoryName(INVENTORY_NOTECARD,i)];
    }
    return result;
}

refreshLock()
{
    if (g_bRLV) {
        if (g_bLocked) llOwnerSay("@detach=n");
        else llOwnerSay("@detach=y");
        
        llMessageLinked(LINK_SET,LINK_CHAN_API,"lock="+(string)g_bLocked,g_kWearer);
    }
}

SendRLV(string sRestrictions, string sCategory, integer bEnable)
{
    if (g_bRLV) {
        list lRestrictions = llParseString2List(sRestrictions,[","],[]);
        sRestrictions = "";
        integer i;
        if (bEnable) for (i=0; i<llGetListLength(lRestrictions);++i) {   
            if (llList2String(lRestrictions,i) == "move" || llList2String(lRestrictions,i) == "@move") doAnimLock(TRUE);
            lRestrictions = llListReplaceList(lRestrictions,[llList2String(lRestrictions,i)+"=n"],i,i);
        } else for (i=0; i<llGetListLength(lRestrictions);++i) {
            if (llList2String(lRestrictions,i) == "move" || llList2String(lRestrictions,i) == "@move") doAnimLock(FALSE);
            lRestrictions = llListReplaceList(lRestrictions,[llList2String(lRestrictions,i)+"=y"],i,i);
        }
    
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":rlvcmd:"+sCategory+":"+llDumpList2String(lRestrictions,","));
    }
}

doHide()
{
    integer iShow = 1;
    
    if (llGetListLength(g_lCurrentChains) < 1 && g_iTargetedBy < 1) g_bTMPUnhide = FALSE;
    
    if (!g_bHide) iShow = 1;
    else if (g_bHide && !g_bTMPUnhide) iShow = 0;
    else if (g_bHide && g_bTMPUnhide) iShow = 1;

    llMessageLinked(LINK_SET,LINK_CHAN_API,"hide="+(string)(!iShow),g_kWearer);

    integer i;
    for (i=0; i<llGetListLength(g_lHidePrims);++i) {
        llSetLinkAlpha(llList2Integer(g_lHidePrims,i),(float)iShow,ALL_SIDES);
    }
}

doAnimLock(integer bEnable)
{
    if (bEnable){
        if (llGetPermissions() & PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT|CONTROL_UP|CONTROL_DOWN,TRUE,FALSE);
        else llOwnerSay("ERROR: Lost Take Control permission!");
    } else {
        if (llGetPermissions() & PERMISSION_TAKE_CONTROLS) llReleaseControls();
        else llOwnerSay("ERROR: Lost Take Control permission!");
    }
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner(); // Init with llGetOwner(). Will be overriden on attach
        llRequestPermissions(g_kWearer,PERMISSION_TRIGGER_ANIMATION|PERMISSION_TAKE_CONTROLS);
        init();
    }
    
    attach(key kAv){
        if (kAv != NULL_KEY) {
            g_bRLV = FALSE; // We don't know yet if we are running with RLV
            llResetScript(); // We have a notecard, parse it again!
        } else {
            list lConfigs = getCategorys();
            integer i;
            for (i=0; i<llGetListLength(lConfigs);++i) llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":remmenu:"+llList2String(lConfigs,i));
        
            if (llGetListLength(g_lActivePoseIndexes) > 0){
                integer i;
                for (i=0;i<llGetListLength(g_lActivePoseIndexes);++i) undoPose(llList2String(g_lActivePoseIndexes,i)); // Stop all poses on detach, to also clear RLV
            }
        
            if (llGetListLength(g_lPoses) > 0){
                integer i;
                list lPoseNames = [];
                for (i=0;i<llGetListLength(g_lPoses);i+=4) lPoseNames += [llList2String(g_lPoses,i)];
                llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":remposes:"+llDumpList2String(lPoseNames,","));
            }
        }
    }
    
    changed(integer iChange){
        if (iChange & CHANGED_OWNER || iChange & CHANGED_LINK || iChange & CHANGED_INVENTORY) llResetScript();
    }
    
    run_time_permissions(integer iPerm)
    {
    }
    
    dataserver(key kQuery, string sData)
    {  
        if (kQuery == g_kNCQuery)
        {
            integer iFreeMem = llGetFreeMemory();
            if (sData != EOF && iFreeMem > 3000){
                
                if (sData != "" && sData != " " && llGetSubString(sData,0,0) != "#") {
                    list lKV = llParseString2List(sData,[":"],[]);
                    string sKey = llList2String(lKV,0);
                    string sValue = llList2String(lKV,1);
                    
                    if (llToLower(sKey) == "button"){ // Add a Button to the menu
                        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":addmenu:"+g_sNCName+"|"+sValue);
                    } else if (llToLower(sKey) == "ignorehide"){  // Don't hide with the other Attachments
                        g_bDoHide = !((integer)sValue);
                    } else if (llToLower(sKey) == "defaulthide"){ // Default hide state
                        g_bHide = (integer)sValue;
                        doHide();
                    } else if (llToLower(sKey) == "defaultlock"){ // Default lock state
                        g_bLocked = (integer)sValue;
                        refreshLock();
                    } else if (llToLower(sKey) == "posename"){
                        if (llGetListLength(g_lSelectedPose) > 0) llOwnerSay("Pose '"+llList2String(g_lSelectedPose,0)+"' in notecard '"+g_sNCName+"' is missing some settings! Skipping!");
                        g_lSelectedPose = [g_sNCName+"|"+sValue];
                    } else if (llToLower(sKey) == "poseanim"){
                        g_lSelectedPose += [sValue];
                    } else if (llToLower(sKey) == "posechains"){
                        g_lSelectedPose += [sValue];
                    } else if (llToLower(sKey) == "poserestrictions"){
                        g_lSelectedPose += [sValue];
                    } else if (llToLower(sKey) == "poseshow") {
                        g_lSelectedPose += [sValue];
                    } else {
                        llOwnerSay("Syntax error in Notecard '"+g_sNCName+"' at line "+(string)g_iNCLine);
                        llOwnerSay("Unknown Key '"+sKey+"'");
                    }
                    
                    if (llGetListLength(g_lSelectedPose) == 5) {
                        g_lPoses += llDeleteSubList(g_lSelectedPose,-1,-1);
                        if (llList2Integer(g_lSelectedPose,4)) llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":addpose:"+llList2String(g_lSelectedPose,0));
                        g_lSelectedPose = [];
                    }
                    
                }
                
                g_kNCQuery = llGetNotecardLine(g_sNCName,++g_iNCLine);
            } else {
                if (iFreeMem <= 3000) {
                    llOwnerSay("ERROR: Skipped reading '"+g_sNCName+"' because there is nearly no Script-Memory left.");
                    llOwnerSay("Consider moving some poses into another attachment!");
                }
                llOwnerSay("Loading "+g_sNCName+" Finished! "+(string)llGetFreeMemory()+"kb Free");
                g_iCategoryIndex++;
                if (llGetListLength(g_lCategory) > g_iCategoryIndex) {
                    g_sNCName = llList2String(g_lCategory,g_iCategoryIndex);
                    g_iNCLine = 0;
                    llOwnerSay("Loading "+g_sNCName+"...");
                    g_kNCQuery = llGetNotecardLine(g_sNCName,g_iNCLine);
                } else {
                    llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer + ":ping");
                    g_lCategory = [];
                    g_lSelectedPose = [];
                }
            }
        }
    }

    touch_start(integer total_number) {
        llRegionSayTo(g_kWearer,g_iChan_ocCmd,(string)g_kWearer+":menu:"+(string)llDetectedKey(0));
    }
    
    link_message(integer iSender, integer iChan, string sMsg, key kID){
        if (iChan == LINK_CHAN_API){
            list lCMD = llParseString2List(sMsg,["="],[]);
            string sKey = llList2String(lCMD,0);
            if (sKey == "dohide"){
                g_bHide = llList2Integer(lCMD,1);
                doHide();
            } else if (sKey == "dolock") {
                g_bLocked = llList2Integer(lCMD,1);
                refreshLock();
            } else if (sKey == "doPose") {
                doPose(llList2String(lCMD,1));
            }
        }
    }
    
    listen(integer iChan, string sName, key kID, string sMsg) {
        if (iChan == g_iChan_Lockguard) {
            list lLGCmd = llParseString2List(llToLower(sMsg), [" "],[]);
            if (llList2String(lLGCmd,0) == "lockguard") {
                key kLGAv = llList2Key(lLGCmd,1);           // Request Avatar-UUID
                string sLGPoint = llList2String(lLGCmd,2);  // Request ChainPoint
                string sLGCMD = llList2String(lLGCmd,3);    // Request Command
                key kLGTarget = llList2Key(lLGCmd,4);       // Request Target
                
                if (llListFindList(g_lMyPoints, [sLGPoint]) > -1 && kLGAv == g_kWearer) {
                    if (sLGCMD == "link") doChain(llList2String(g_lMyPoints,0) , kLGTarget, TRUE);
                    else if (sLGCMD == "unlink") doChain(llList2String(g_lMyPoints,0) , NULL_KEY, FALSE);
                    else if (sLGCMD == "ping") {
                        integer iIndex = llListFindList(g_lMyPoints,[sLGPoint]); // Only reply if we provide this point
                        if (iIndex > -1) llRegionSayTo(kID,g_iChan_Lockguard,"lockguard "+(string)g_kWearer+" "+sLGPoint+" okay"); // Not documented, but it is in the script
                    } else if (sLGCMD == "gravity") g_fGravity = llList2Float(lLGCmd,4);
                    else if (sLGCMD == "life") g_fLife = llList2Float(lLGCmd,4);
                    else if (sLGCMD == "color") {
                        g_fRed = llList2Float(lLGCmd,4);
                        g_fGreen = llList2Float(lLGCmd,5);
                        g_fBlue = llList2Float(lLGCmd,6);
                    } else if (sLGCMD == "size") {
                        g_fSizeX = llList2Float(lLGCmd,4);
                        g_fSizeY = llList2Float(lLGCmd,5);
                    } else if (sLGCMD == "texture") g_kTexture = llList2Key(lLGCmd,4);
                }
            }
            
        } else if (iChan == g_iChan_Lockmeister) {
            key kLMKey = (key)llGetSubString(sMsg,0,35);
            list lLMCmd = llParseString2List(sMsg,["|"],[]);
            if (kLMKey == g_kWearer){
                if (llGetListLength(lLMCmd) > 1) {
                    string sLMCMD = llList2String(lLMCmd,2);
                    string sLMPoint = llList2String(lLMCmd,3);
                    integer iIndex = llListFindList(g_lMyPoints,[sLMPoint]);
                    if (iIndex > -1) {
                        if (sLMCMD == "RequestPoint") {
                            key kLink = llGetLinkKey(llList2Integer(g_lMyPoints,iIndex+1));
                            if (kLink != NULL_KEY) llRegionSayTo(kID, g_iChan_Lockmeister,(string)g_kWearer+"|LMV2|ReplyPoint|"+sLMPoint+"|"+(string)kLink);
                        }
                    }
                } else {
                    string sLMPoint = llGetSubString(sMsg,36,-1);
                    if (llListFindList(g_lMyPoints,[sLMPoint]) > -1) {
                        llRegionSayTo(kID, g_iChan_Lockmeister, (string)g_kWearer+sLMPoint+" ok");
                    }
                }
            }
        } else if (iChan == g_iChan_OCChain) {
            //llOwnerSay("Got OC Command:"+sMsg);
            list lOcCMD = llParseString2List(sMsg, [":"],[]);
            string sCMD = llList2String(lOcCMD,0);
            if (sCMD == "occhains") ParseOcChains(llList2String(lOcCMD,1));
            else if (sCMD == "occhain") doOcChain(llList2String(lOcCMD,1));
            else if (sCMD == "chainkey") llRegionSayTo(kID,g_iChan_OCChain,llList2String(lOcCMD,1)+"="+(string)findPrimKey(llList2String(lOcCMD,1)));
            else if (sCMD == "clearchain") doClearChain(llList2String(lOcCMD,1));
        } else if (iChan == g_iChan_ocCmd) {
            list lOcCMD = llParseString2List(sMsg, [":"],[]);
            key kOcWearer = llList2Key(lOcCMD,0);
            string sCMD = llList2String(lOcCMD,1);  
            if (sCMD == "collarping") llResetScript();
            if (llGetOwnerKey(kID) == g_kWearer) {  // the following commands can only be send by Attachments!
                if (sCMD == "lock" && llGetOwnerKey(kID) == g_kWearer) {
                    g_bLocked = TRUE;
                    refreshLock();
                } else if (sCMD == "unlock" && llGetOwnerKey(kID) == g_kWearer) {
                    g_bLocked = FALSE;
                    refreshLock();
                } else if (sCMD == "clearpose") undoPose(llList2String(lOcCMD,2));
                else if (sCMD == "activeposes") {
                    list lNewPoses = llParseString2List(llList2String(lOcCMD,2),[","],[]);
                    integer i;
                    for (i=0;i<llGetListLength(lNewPoses);++i){ // Start poses that should be running
                        integer iPoseIndex = llListFindList(g_lPoses,[llList2String(lNewPoses,i)]);
                        if (iPoseIndex > -1) { // Is it our pose?
                            if (llListFindList(g_lActivePoseIndexes,[iPoseIndex]) == -1) doPose(llList2String(lNewPoses,i)); // Start the pose if not running
                        }
                    }
                }else if (sCMD == "hide" && g_bDoHide) {
                    g_bHide = llList2Integer(lOcCMD,2);
                    doHide();
                } else if (sCMD == "chaintex" && g_kTexture != llList2Key(lOcCMD,2)) {
                    g_kTexture = llList2Key(lOcCMD,2);
                    list lActiveChains = g_lCurrentChains;
                    doClearChain("all"); // Restart all Chains so the change can be seen live!
                    integer i;
                    for (i=0; i<llGetListLength(lActiveChains);i+=2) {
                        doChain(llList2String(lActiveChains,i),llList2Key(lActiveChains,i+1),TRUE);
                    }
                } else if (sCMD == "restriction"){
                    llMessageLinked(LINK_SET,LINK_CHAN_API,"restriction="+llList2String(lOcCMD,2),g_kWearer);
                } else if (sCMD == "RLV" && llGetOwnerKey(kID) == g_kWearer) {
                    g_bRLV = llList2Integer(lOcCMD,2);
                    refreshLock();
                    if (!g_bRLV) llOwnerSay("@clear");
                } else if (sCMD == "devicemenu") llMessageLinked(LINK_SET,LINK_CHAN_API,"menu="+llList2String(lOcCMD,2),g_kWearer);
            }
        }
    }
}
