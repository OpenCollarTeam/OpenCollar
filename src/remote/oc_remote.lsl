  
/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :

Aria (Tashia Redrose)
    * December 2020       -       Recreated oc_Remote
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

// this texture is a spritemap with all buttons on it, for faster texture
// loading than having separate textures for each button.
string BTN_TEXTURE = "243f5127-2fd1-7a8e-0c51-6603eeb9036f";

// There are 3 columns of buttons and 8 rows of buttons in the sprite map.
integer BTN_XS = 3;
integer BTN_YS = 9;


integer g_iVertical = TRUE;  // can be vertical?
integer g_iLayout = 1; // 0 - Horisontal, 1 - Vertical


float g_fGap = 0.005; // This is the space between buttons
float g_Yoff = 0.025; // space between buttons and screen top/bottom border
float g_Zoff = 0.05; // space between buttons and screen left/right border


list g_lMenuIDs;
integer g_iMenuStride;

string UPMENU="BACK";
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    
    llRegionSayTo(g_kCollar,llList2Integer(g_lAPIListeners,0), llList2Json(JSON_OBJECT, ["pkt_type", "from_addon", "addon_name", g_sAddon, "iNum", DIALOG, "sMsg", (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, "kID", kMenuID]));

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[OpenCollar Remote]";
    list lButtons = ["+ Favorite"];
    
    //llSay(0, "opening menu");
    Dialog(kID, sPrompt, lButtons, ["DISCONNECT", UPMENU], 0, iAuth, "Menu~Main");
}

SetButtonTexture(integer link, string name) {
    integer idx = llListFindList(BTNS, [name]);
    if (idx == -1) idx = llListFindList(BTNS, ["NONE"])/3;
    else idx=idx/3;
    integer x = idx % BTN_XS;
    integer y = idx / BTN_XS;
    vector scale = <1.0 / BTN_XS, 1.0 / BTN_YS, 0>;
    vector offset = <
        scale.x * (x - (BTN_XS / 2.0 - 0.5)), 
        scale.y * -1 * (y - (BTN_YS / 2.0 - 0.5)),
    0>;
    llSetLinkPrimitiveParamsFast(link, [
        PRIM_TEXTURE,
            ALL_SIDES,
            BTN_TEXTURE,
            scale,
            offset,
            0 ,
            PRIM_COLOR, ALL_SIDES, <1,1,1>, 1
    ]);   
}
string profile_key_prefix = "<meta name=\"imageid\" content=\"";
string profile_img_prefix = "<img alt=\"profile image\" src=\"http://secondlife.com/app/image/";
integer profile_key_prefix_length; // calculated from profile_key_prefix in state_entry()
integer profile_img_prefix_length; // calculated from profile_key_prefix in state_entry()
 
GetProfilePic(key id) //Run the HTTP Request then set the texture
{
    //key id=llDetectedKey(0); This breaks the function, better off not used
    string URL_RESIDENT = "http://world.secondlife.com/resident/";
    g_kPicReq=llHTTPRequest( URL_RESIDENT + (string)id,[HTTP_METHOD,"GET"],"");
}
key g_kPicReq;
// starting at the top left and moving to the right, the button sprites are in
// this order.
list BTNS = [
    "Minimize", "@hide", 1,
    "People", "@people", 2,
    "Menu", "menu", 4,
    "Couples", "menu Couples", 8,
    "Favorite", "@fav", 16,
    "Bookmarks", "menu Bookmarks", 32,
    "Lock", "lock", 64,
    "Outfits", "menu Outfits", 128,
    "Folders", "menu Folders", 256,
    "Unleash", "unleash", 512,
    "Leash", "grab", 1024,
    "Yank", "yank", 2048,
    "Sit", "sit", 4096,
    "Stand", "unsit", 8192,
    "Rez", "@rez", 16384,
    "Pose", "menu Pose", 32768,
    "Stop", "stop", 65536,
    "Hudmenu", "@menu", 131072,
    "Person", "@person", 262144,
    "Restrictions", "menu Restrictions", 524288,
    "Titler", "menu Titler", 1048576,
    "Detach", "menu Detach", 2097152,
    "Maximize", "@show", 4194304,
    "Macros", "menu Macros", 8388608,
    "Themes", "menu Themes", 16777216,
    "NONE", "@no", 0
];



list g_lAttachPoints = [
    ATTACH_HUD_TOP_RIGHT,
    ATTACH_HUD_TOP_CENTER,
    ATTACH_HUD_TOP_LEFT,
    ATTACH_HUD_BOTTOM_RIGHT,
    ATTACH_HUD_BOTTOM,
    ATTACH_HUD_BOTTOM_LEFT,
    ATTACH_HUD_CENTER_1,
    ATTACH_HUD_CENTER_2
    ];
    
    
integer g_iHidden = FALSE;
integer g_iSPosition; // Do not pre-allocate script memory by setting this variable, it is set at run-time.

list g_lPrimOrder ;
integer g_iColumn = 1;  // 0 - Column, 1 - Alternate
integer g_iRows = 3;  // nummer of Rows: 1,2,3,4... up to g_iMaxRows
integer g_iOldRows; // used during sensor to backup the row count
integer g_iMaxRows = 6; // maximal Rows in Columns
list g_lButtons ; // buttons names for Order menu
PositionButtons() {
    integer iPosition = llListFindList(g_lAttachPoints, [llGetAttached()]);
    vector size = llGetScale();
//  Allows manual repositioning, without resetting it, if needed
    if (iPosition != g_iSPosition && iPosition != -1) { //do this only when attached to the hud
        vector offset = <0, size.y/2+g_Yoff, size.z/2+g_Zoff>;
        if (iPosition==0||iPosition==1||iPosition==2) offset.z = -offset.z;
        if (iPosition==2||iPosition==5) offset.y = -offset.y;
        if (iPosition==1||iPosition==4) { g_iLayout = 0; g_iVertical = FALSE;}
        else { g_iLayout = 1; g_iVertical = TRUE; }
        llSetPos(offset); // Position the Root Prim on screen
        g_iSPosition = iPosition;
        //llSetLinkPrimitiveParams(1, [PRIM_SIZE, ZERO_VECTOR]);
    }
    if (g_iHidden) { // -- Fixes Issue 615: HUD forgets hide setting on relog.
        SetButtonTexture(1, "Maximize");
        //llSetLinkPrimitiveParams(LINK_ROOT, [PRIM_SIZE, <0.05,0.05,0.05>]);
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION, <1.0, 0.0, 0.0>]);
    } else {
        
        llSetLinkPrimitiveParamsFast(1, [
            PRIM_TEXTURE,
                ALL_SIDES,
                TEXTURE_TRANSPARENT,
                <1,1,1>,
                ZERO_VECTOR,
                0 ,
                PRIM_COLOR, ALL_SIDES, <1,1,1>, 1
        ]);   
        //SetButtonTexture(1, "Minimize");
        float fYoff = size.y + g_fGap; 
        float fZoff = size.z + g_fGap; // This is the space between buttons
        
        if (iPosition == 0 || iPosition == 1 || iPosition == 2) fZoff = -fZoff;
        if (iPosition == 1 || iPosition == 2 || iPosition == 4 || iPosition == 5) fYoff = -fYoff;
        //list lPrimOrder = llDeleteSubList(g_lPrimOrder, 0, 0);
        list lPrimOrder = g_lPrimOrder;
        integer n = llGetListLength(lPrimOrder);
        vector pos ;
        integer i;
        float fXoff = 0.01; // small X offset
        
        for (i=2; i < n+2; i++) {
            if (g_iColumn == 0) { // Column
                if (!g_iLayout) pos = <fXoff, fYoff*(i-(i/(n/g_iRows))*(n/g_iRows)), fZoff*(i/(n/g_iRows))>;
                else pos = <fXoff, fYoff*(i/(n/g_iRows)), fZoff*(i-(i/(n/g_iRows))*(n/g_iRows))>;
            } else if (g_iColumn == 1) { // Alternate
                if (!g_iLayout) pos = <fXoff, fYoff*(i/g_iRows), fZoff*(i-(i/g_iRows)*g_iRows)>;
                else  pos = <fXoff, fYoff*(i-(i/g_iRows)*g_iRows), fZoff*(i/g_iRows)>;
            }
            
            llSetLinkPrimitiveParamsFast(llList2Integer(lPrimOrder,i-2),[PRIM_POSITION,pos]);
        }
    }
}

TextureButtons() {
    integer i = llGetNumberOfPrims();

    while (i) {
        string name = llGetLinkName(i);
        /*if (i == 1) {
            if (g_iHidden) {
                name = "Maximize";
            } else {
                name = "Minimize";
            }
        }*/
        
        SetButtonTexture(i, name);
        i--;
    }
}


FindButtons() { // collect buttons names & links
    g_lButtons = ["Person"] ;
    g_lPrimOrder = [2];  
    integer i;
    for (i=LINK_ROOT+1; i<=llGetNumberOfPrims(); i++) {
        if(llGetLinkName(i)!="Object" && llGetLinkName(i)!="Person"){
            g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_NAME]);
            g_lPrimOrder += i;
        }
    }
    g_iMaxRows = llFloor(llSqrt(llGetListLength(g_lButtons)));
}


// for swapping buttons
integer g_iNewPos;
integer g_iOldPos;
DoButtonOrder() {   // -- Set the button order and reset display
    integer iOldPos = llList2Integer(g_lPrimOrder,g_iOldPos);
    integer iNewPos = llList2Integer(g_lPrimOrder,g_iNewPos);
    integer i = 2;
    list lTemp = [];
    for(;i<llGetListLength(g_lPrimOrder);i++) {
        integer iTempPos = llList2Integer(g_lPrimOrder,i);
        if (iTempPos == iOldPos) lTemp += [iNewPos];
        else if (iTempPos == iNewPos) lTemp += [iOldPos];
        else lTemp += [iTempPos];
    }
    g_lPrimOrder = lTemp;
    g_iOldPos = -1;
    g_iNewPos = -1;
    PositionButtons();
}

integer PicturePrim() {
    integer i = llGetNumberOfPrims();
    do {
        if (~llSubStringIndex((string)llGetLinkPrimitiveParams(i, [PRIM_DESC]),"Picture"))
            return i;
    } while (--i>1);
    return 0;
}
key g_kOwner;
integer g_iPicturePrim;

HideOthers()
{
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=LINK_ROOT+1;i<=end;i++){
        string name = llGetLinkName(i);
        if(llListFindList(g_lButtons, [name])==-1){
            llSetLinkPrimitiveParamsFast(i, [PRIM_SIZE, ZERO_VECTOR, PRIM_POS_LOCAL, ZERO_VECTOR]);
            
            llSetLinkPrimitiveParamsFast(i, [
                PRIM_TEXTURE,
                    ALL_SIDES,
                    TEXTURE_TRANSPARENT,
                    ZERO_VECTOR,
                    ZERO_VECTOR,
                    0 
            ]); 
        }
    }
}
FormatHUD()
{
    llSetText("FORMATTING REMOTE HUD", <1,0,0>,1);
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=LINK_ROOT+1; i<=end; i++){
        llSetText("Formatting HUD\nProgress: "+(string)(i*100/end)+"%",<1,0,0>,1);
        llSetLinkPrimitiveParamsFast(i,[PRIM_NAME, "Object"]);
    }
    llSetText("", ZERO_VECTOR,0);
}

list GetActiveButtons()
{
    list lTmp;
    integer i=0;
    integer end = llGetListLength(BTNS);
    for(i=2;i<end;i+=3)
    {
        integer bits = (integer)llList2String(BTNS, i);
        if(g_iBitMask&bits)
        {
            lTmp += llList2String(BTNS, i-2);
            //llOwnerSay( "Add: "+llList2String(BTNS,i-2));
        }
    }
    
    return lTmp;
}

integer g_iBitMask;

Recalc()
{    
    list active = GetActiveButtons();
    integer i=0;
    integer end = llGetListLength(active);
    llSetLinkPrimitiveParamsFast(1, [PRIM_SIZE, <0.05,0.05,0.05>]);
    llSetLinkPrimitiveParamsFast(2, [PRIM_NAME, "Person", PRIM_DESC, "Picture"]);
    for(i=0;i<end;i++)
    {
        if(llList2String(active,i)!="Person"){
            llSetLinkPrimitiveParamsFast(i+3, [PRIM_NAME, llList2String(active,i), PRIM_SIZE, <0.05,0.05,0.05>,
            
                PRIM_COLOR, ALL_SIDES, <1,1,1>, 1, PRIM_TEXT, "", ZERO_VECTOR, 0]);
            //llOwnerSay("Set prim: "+llList2String(active,i));
        }
    }
    FindButtons();
    g_iPicturePrim = PicturePrim();
    TextureButtons();
    PositionButtons();
    HideOthers();
}

integer ActivateAll()
{
    integer i=0;
    integer end = llGetListLength(BTNS);
    integer mask;
    for(i=2;i<end;i+=3)
    {
        mask += (integer)llList2String(BTNS,i);
    }
    return mask;
}

FormatPrim(){
    llSetText(">Processing Data", <1,0,0>,1);
    list active = GetActiveButtons();
    integer difference = llGetListLength(g_lButtons)-llGetListLength(active);
    do
    {
        llSetLinkPrimitiveParamsFast((integer)llList2String(g_lPrimOrder, -1), [PRIM_NAME, "Object"]);
        g_lPrimOrder = llDeleteSubList(g_lPrimOrder,-1,-1);
        difference--;
    } while (difference);

    g_lButtons = [];
    g_lPrimOrder=[];
    FindButtons();
    HideOthers();
    llSetText("",ZERO_VECTOR,0);
}

integer g_iOldMask;
list g_lOptions;

integer g_iScanned;

list g_lAPIListeners;
key g_kCollar=NULL_KEY;
StopAPIs()
{
    integer i=0;
    integer end = llGetListLength(g_lAPIListeners);
    for(i=1;i<end;i+=2){
        Link("offline", 0, "", llGetOwnerKey(g_kCollar));
        llListenRemove(llList2Integer(g_lAPIListeners, i));
    }
    g_lAPIListeners = [];
    g_kCollar=NULL_KEY;
    llSetTimerEvent(0);
}


StartAPI(key ID){
    integer API_CHANNEL = ((integer)("0x"+llGetSubString((string)ID,0,8)))+0xf6eb-0xd2;
    g_lAPIListeners = [API_CHANNEL,llListen(API_CHANNEL, "", "", "")];
    
    Link("online",0,"",ID);
}

string g_sAddon = "OC_Remote";
Link(string packet, integer iNum, string sStr, key kID){
    if(llList2Integer(g_lAPIListeners,0)==0)return; // nothing is set or connected!!!!!!!
    string pkt = llList2Json(JSON_OBJECT, ["pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "sMsg", sStr, "kID", kID]);
    if(g_kCollar!= "" && g_kCollar!= NULL_KEY) 
        llRegionSayTo(g_kCollar, llList2Integer(g_lAPIListeners,0), pkt);
    else
        llRegionSay(llList2Integer(g_lAPIListeners,0), pkt);
}



integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_BLOCKED = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value


integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;


integer g_iLMLastRecv;

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        return;
    }
    if (llToLower(sStr)==llToLower(g_sAddon) || llToLower(sStr) == "menu "+llToLower(g_sAddon)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        
        if(sChangetype == "remote")
        {
            Menu(kID, iNum);
        }
    }
}

list g_lFavorites;
key g_kProfilePic;
integer g_iRetexture;
default
{
    state_entry() {
        profile_key_prefix_length = llStringLength(profile_key_prefix);
        profile_img_prefix_length = llStringLength(profile_img_prefix);
        g_iBitMask = ActivateAll();
        llSetText("",ZERO_VECTOR,0);
        g_kOwner = llGetOwner();
        FormatHUD();
        Recalc();
        llSleep(1.0);//giving time for others to reset before populating menu
        llSetObjectName("OpenCollar Remote - 8.0");
        llOwnerSay("HUD is ready with "+(string)llGetFreeMemory()+"b free memory");
        g_lFavorites = [llGetOwner()];
    }
    
    attach(key id){
        if(id!=NULL_KEY){
            Recalc();
            llOwnerSay("Ready");
        }
    }
    
    changed(integer iChange){
        if(iChange&CHANGED_OWNER){
            llOwnerSay("Owner change detected. The HUD is now initializing factory defaults");
            llResetScript();
        }
    }
    
    on_rez(integer iRez){
        Recalc();
        llOwnerSay("Ready");
    }
    
    no_sensor()
    {
        llOwnerSay("No one was found nearby");
        g_iScanned=TRUE;
        
        g_lOptions=[];
        integer i=0;
        
        g_iOldMask = g_iBitMask;
        g_iBitMask = 4194304;
        FormatPrim();
        Recalc();
        
        
        integer iActualPrim=10;
        if(llListFindList(g_lButtons, [(string)llGetOwner()])==-1){
            g_lOptions += [(string)llGetOwner()];
            g_lButtons += [(string)llGetOwner(), (string)llGetOwner()];
            g_lPrimOrder += [iActualPrim, iActualPrim+1];
            llSetLinkPrimitiveParamsFast(iActualPrim, [PRIM_SIZE, <0.05,0.05,0.05>, PRIM_NAME, (string)llGetOwner()]);
            llSetLinkPrimitiveParamsFast(iActualPrim+1, [PRIM_TEXT, llGetDisplayName(llGetOwner()), <0,1,0>, 1, PRIM_SIZE, ZERO_VECTOR, PRIM_NAME, (string)llGetOwner()]);
        }
        TextureButtons();
        PositionButtons();
        HideOthers();
        
        g_iScanned = TRUE;
        i=0;
        integer end = llGetNumberOfPrims();
        string sOldName;
        llSleep(2);
        for(i=LINK_ROOT+1; i<=end;i++)
        {
            string sName = llGetLinkName(i);
            if(sName == sOldName){
                vector pos = (vector)llList2String(llGetLinkPrimitiveParams(i-1, [PRIM_POS_LOCAL]),0);
                vector oPos = (vector)llList2String(llGetLinkPrimitiveParams(i, [PRIM_POS_LOCAL]),0);
                
                
                llSetLinkPrimitiveParamsFast(i, [PRIM_TEXT, llGetDisplayName(llGetLinkName(i)), <0,1,0>, 1, PRIM_SIZE, ZERO_VECTOR, PRIM_POS_LOCAL, pos]);
                //llOwnerSay("Set position to: "+(string)pos+"\nOriginal pos: "+(string)oPos);
            }
            sOldName=sName;
            
        }
    }
    
    sensor(integer iNum)
    {
        g_lOptions=[];
        integer i=0;
        
        g_iOldMask = g_iBitMask;
        g_iBitMask = 4194304;
        FormatPrim();
        Recalc();
        
        integer iActualPrim=10;
        for(i=0;i<iNum;i++){
            g_lOptions += llDetectedKey(i);
            g_lButtons += [(string)llDetectedKey(i), (string)llDetectedKey(i)];
            g_lPrimOrder += [iActualPrim, iActualPrim+1];
            llSetLinkPrimitiveParamsFast(iActualPrim, [PRIM_SIZE, <0.05,0.05,0.05>, PRIM_NAME, (string)llDetectedKey(i)]);
            llSetLinkPrimitiveParamsFast(iActualPrim+1, [PRIM_TEXT, llGetDisplayName(llDetectedKey(i)), <0,1,0>, 1, PRIM_SIZE, ZERO_VECTOR, PRIM_NAME, (string)llDetectedKey(i)]);

            iActualPrim +=2;
        }
        if(llListFindList(g_lButtons, [(string)llGetOwner()])==-1){
            g_lOptions += [(string)llGetOwner()];
            g_lButtons += [(string)llGetOwner(), (string)llGetOwner()];
            g_lPrimOrder += [iActualPrim, iActualPrim+1];
            llSetLinkPrimitiveParamsFast(iActualPrim, [PRIM_SIZE, <0.05,0.05,0.05>, PRIM_NAME, (string)llGetOwner()]);
            llSetLinkPrimitiveParamsFast(iActualPrim+1, [PRIM_TEXT, llGetDisplayName(llGetOwner()), <0,1,0>, 1, PRIM_SIZE, ZERO_VECTOR, PRIM_NAME, (string)llGetOwner()]);
        }
        TextureButtons();
        PositionButtons();
        HideOthers();
        
        g_iScanned = TRUE;
        
        i=0;
        integer end = llGetNumberOfPrims();
        string sOldName;
        llSleep(2);
        for(i=LINK_ROOT+1; i<=end;i++)
        {
            string sName = llGetLinkName(i);
            if(sName == sOldName){
                vector pos = (vector)llList2String(llGetLinkPrimitiveParams(i-1, [PRIM_POS_LOCAL]),0);
                vector oPos = (vector)llList2String(llGetLinkPrimitiveParams(i, [PRIM_POS_LOCAL]),0);
                
                
                llSetLinkPrimitiveParamsFast(i, [PRIM_TEXT, llGetDisplayName(llGetLinkName(i)), <0,1,0>, 1, PRIM_SIZE, ZERO_VECTOR, PRIM_POS_LOCAL, pos]);
                //llOwnerSay("Set position to: "+(string)pos+"\nOriginal pos: "+(string)oPos);
            }
            sOldName=sName;
            
        }
        
    }
    
    timer()
    {
        if(llGetTime()>=10 && g_kCollar == NULL_KEY){
            llWhisper(0, "Selected target does not use opencollar or the API has failed. Timeout occured.");
            StopAPIs();
            llSetTimerEvent(0);
        }
        
        if(llGetUnixTime() >= g_iLMLastRecv + (3*60) && g_kCollar != NULL_KEY)
        {
            // OKAY
            Link("ping", 0, "", g_kCollar);
        }
        
        if(llGetTime()>=3 && g_iRetexture && g_kProfilePic!=NULL_KEY)
        {
            g_iRetexture=0;
            llSetLinkPrimitiveParams(g_iPicturePrim, [PRIM_TEXTURE, ALL_SIDES, g_kProfilePic, <1,1,0>, ZERO_VECTOR, 0]);
        }
    }
    
    touch_start(integer t){
        string sName = llGetLinkName(llDetectedLinkNumber(0));
        string sCmd = llList2String(BTNS, llListFindList(BTNS, [sName])+1);
        
        integer iImplemented = FALSE;
        
        if(g_iScanned && sCmd != "@show"){
            key av = (key)sName;
            sCmd = "@show";
            llOwnerSay("Attempting to connect ...");
            
            // Open the API Listener, stop any other API Listener
            g_iScanned=FALSE;
            
            StopAPIs();
            
            StartAPI(av);
            llResetTime();
            llSetTimerEvent(1);
        }
        if(sCmd == "@hide"){
            iImplemented=1;
            g_iOldMask = g_iBitMask;
            g_iBitMask = 4194304;
            FormatPrim();
            Recalc();
        } else if(sCmd == "@show"){
            iImplemented=1;
            g_iBitMask = g_iOldMask;
            g_iOldMask = 0;
            Recalc();
            g_iScanned=FALSE;
            
            if(g_kCollar!=NULL_KEY){
                llResetTime();
                g_iRetexture=1;
            }
        } else if(sCmd == "@people")
        {
            // Run a sensor sweep of those nearby within 20 meters.
            // The user will then have the option to pick from those names.
            StopAPIs();
            iImplemented=1;
            llSensor("", "", AGENT,  20, PI);
        } else if(sCmd == "@menu"){
            Link("from_addon", 0, "menu OC_Remote", llDetectedKey(0));
            iImplemented =1;
        } else if(sCmd == "@fav"){
            iImplemented=1;
            if(g_kCollar!=NULL_KEY){
                Link("offline", 0, "", llGetOwnerKey(g_kCollar));
                llOwnerSay("HUD has disconnected from the remote collar");
                g_kCollar=NULL_KEY;
                llSetTimerEvent(0);
                StopAPIs();
                llSetText("", ZERO_VECTOR,0);
            }
            g_lOptions=[];
            integer i=0;
            
            g_iOldMask = g_iBitMask;
            g_iBitMask = 4194304;
            FormatPrim();
            Recalc();
            
            
            integer end = llGetListLength(g_lFavorites);
            
            integer iActualPrim=10;
            for(i=0;i<end;i++){
                if(llGetAgentSize((key)llList2String(g_lFavorites,i))!=ZERO_VECTOR)
                {
                    // This user is in the region, display the box for them
                    key user = (key)llList2String(g_lFavorites,i);
                    g_lOptions += [(string)user];
                    g_lButtons += [(string)user, (string)user];
                    g_lPrimOrder += [iActualPrim, iActualPrim+1];
                    llSetLinkPrimitiveParamsFast(iActualPrim, [PRIM_SIZE, <0.05,0.05,0.05>, PRIM_NAME, (string)user]);
                    llSetLinkPrimitiveParamsFast(iActualPrim+1, [PRIM_TEXT, llGetDisplayName(user), <0,1,0>, 1, PRIM_SIZE, ZERO_VECTOR, PRIM_NAME, (string)user]);
                    iActualPrim+=2;
                }
            }
            TextureButtons();
            PositionButtons();
            HideOthers();
            
                
            g_iScanned = TRUE;
            
            i=0;
            end = llGetNumberOfPrims();
            string sOldName;
            llSleep(2);
            for(i=LINK_ROOT+1; i<=end;i++)
            {
                string sName = llGetLinkName(i);
                if(sName == sOldName){
                    vector pos = (vector)llList2String(llGetLinkPrimitiveParams(i-1, [PRIM_POS_LOCAL]),0);
                    vector oPos = (vector)llList2String(llGetLinkPrimitiveParams(i, [PRIM_POS_LOCAL]),0);
                    
                    
                    llSetLinkPrimitiveParamsFast(i, [PRIM_TEXT, llGetDisplayName(llGetLinkName(i)), <0,1,0>, 1, PRIM_SIZE, ZERO_VECTOR, PRIM_POS_LOCAL, pos]);
                    //llOwnerSay("Set position to: "+(string)pos+"\nOriginal pos: "+(string)oPos);
                }
                sOldName=sName;
                
            }
        } else if(sCmd == "@person")
        {
            iImplemented=1;
            if(g_kCollar!=NULL_KEY)
                llOwnerSay("You are connected to secondlife:///app/agent/"+(string)llGetOwnerKey(g_kCollar)+"/about's collar");
            else
                llOwnerSay("Not connected to a collar!");
        } else {
            Link("from_addon", 0, sCmd, llDetectedKey(0));
            iImplemented=1;
        }
        
        if(!iImplemented)
            llSetText("Not Implemented\nName: "+sName+"\nCmd: "+sCmd, <0,1,0>,1);
        else
            llSetText("", ZERO_VECTOR,0);
    }
    
    http_response(key kReq, integer iStat, list lMeta, string sBody)
    {
        if(g_kPicReq==kReq)
        {
            if(iStat==200){
                integer s1 = llSubStringIndex(sBody, profile_key_prefix);
                integer s1l = profile_key_prefix_length;
                if(s1 == -1)
                { // second try
                    s1 = llSubStringIndex(sBody, profile_img_prefix);
                    s1l = profile_img_prefix_length;
                }
                
                if(s1==-1)
                {
                    llOwnerSay("No profile picture found");
                    g_kProfilePic=NULL_KEY;
                }else{
                    s1+=s1l;
                
                    key UUID=llGetSubString(sBody, s1, s1 + 35);
                    g_kProfilePic = UUID;
                    
                    llSetLinkPrimitiveParams(g_iPicturePrim, [PRIM_TEXTURE, ALL_SIDES, g_kProfilePic, <1,1,0>, ZERO_VECTOR, 0]);
                }
                
            }else {
                g_kProfilePic=NULL_KEY;
                llOwnerSay("Error when retrieving profile picture");
            }
        }
    }
    
    listen(integer c,string n,key i,string m){
        //llOwnerSay( "message from collar: "+m);
        if(llJsonGetValue(m,["pkt_type"])=="approved" && g_kCollar==NULL_KEY){
            // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
            g_kCollar = i;
            GetProfilePic(llGetOwnerKey(i));
            llOwnerSay("Connected!");
            //Link("from_addon", LM_SETTING_REQUEST, "ALL","");
        } else if(llJsonGetValue(m,["pkt_type"])=="dc" && g_kCollar==i){
            g_kCollar=NULL_KEY;
            llResetScript(); // This addon is designed to always be connected because it is a test
        } else if(llJsonGetValue(m,["pkt_type"])=="pong" && g_kCollar==i)
        {
            g_iLMLastRecv = llGetUnixTime();
        } else if(llJsonGetValue(m,["pkt_type"])=="from_collar"){
            // process link message if in range of addon
            if(llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(i, [OBJECT_POS]),0))<=10.0){
                // process it!
                integer iNum = (integer)llJsonGetValue(m,["iNum"]);
                string sStr = llJsonGetValue(m,["sMsg"]);
                key kID = (key)llJsonGetValue(m,["kID"]);
                
                if(iNum == LM_SETTING_RESPONSE){
                    list lPar = llParseString2List(sStr, ["_","="],[]);
                    string sToken = llList2String(lPar,0);
                    string sVar = llList2String(lPar,1);
                    string sVal = llList2String(lPar,2);
                    
                    if(sToken == "auth"){
                        if(sVar == "owner"){
                            //llSay(0, "owner values is: "+sVal);
                        }
                    }
                } else if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE){
                    UserCommand(iNum, sStr, kID);
                    
                } else if (iNum == DIALOG_TIMEOUT) {
                    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
                    g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
                }else if(iNum == DIALOG_RESPONSE){
                    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
                    if(iMenuIndex!=-1){
                        string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                        list lMenuParams = llParseString2List(sStr, ["|"],[]);
                        key kAv = llList2Key(lMenuParams,0);
                        string sMsg = llList2String(lMenuParams,1);
                        integer iAuth = llList2Integer(lMenuParams,3);
                        
                        if(sMenu == "Menu~Main"){
                            if(sMsg == UPMENU) Link("from_addon", iAuth, "menu Addons", kAv);
                            else if(sMsg == "+ Favorite"){
                                llOwnerSay("Adding collar to favorites...");
                                if(llListFindList(g_lFavorites, [(string)llGetOwnerKey(g_kCollar)])==-1)g_lFavorites += [(string)llGetOwnerKey(g_kCollar)];
                            }
                            else if(sMsg == "DISCONNECT"){
                                Link("offline", 0, "",llGetOwnerKey(g_kCollar));
                                g_lMenuIDs=[];
                                g_kCollar=NULL_KEY;
                                llSetTimerEvent(0);
                                llSetText("",ZERO_VECTOR,0);
                                
                                llOwnerSay("HUD has been disconnected from the remote collar");
                            }
                        }
                    }
                }
            }
        }
    }
}
