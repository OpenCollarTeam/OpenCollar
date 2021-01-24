  
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
string BTN_TEXTURE = "da46036f-7f4d-59e5-3fcf-a43d692e3ea7";

// There are 3 columns of buttons and 8 rows of buttons in the sprite map.
integer BTN_XS = 3;
integer BTN_YS = 9;

integer UPDATE_AVAILABLE=FALSE;
integer g_iAmNewer=FALSE;
string NEW_VERSION = "";
string HUD_VERSION = "8.0.1000";

key g_kUpdateCheck = NULL_KEY;
DoCheckUpdate(){
    g_kUpdateCheck = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/remote.txt",[],"");
}

Compare(string V1, string V2){
    NEW_VERSION=V2;
    
    if(V1==V2){
        UPDATE_AVAILABLE=FALSE;
        return;
    }
    V1 = llDumpList2String(llParseString2List(V1, ["."],[]),"");
    V2 = llDumpList2String(llParseString2List(V2, ["."],[]), "");
    integer iV1 = (integer)V1;
    integer iV2 = (integer)V2;
    
    if(iV1 < iV2){
        UPDATE_AVAILABLE=TRUE;
        g_iAmNewer=FALSE;
    } else if(iV1 == iV2) return;
    else if(iV1 > iV2){
        UPDATE_AVAILABLE=FALSE;
        g_iAmNewer=TRUE;
        
        llSetText("", <1,0,0>,1);
    }
}
string MajorMinor(){
    list lTmp = llParseString2List(HUD_VERSION,["."],[]);
    return llList2String(lTmp,0)+"."+llList2String(lTmp,1);
}
integer g_iVertical = TRUE;  // can be vertical?
integer g_iLayout = 1; // 0 - Horisontal, 1 - Vertical


integer AUTH_REQUEST = 600;
//integer AUTH_REPLY=601;

float g_fGap = 0.005; // This is the space between buttons
float g_Yoff = 0.025; // space between buttons and screen top/bottom border
float g_Zoff = 0.05; // space between buttons and screen left/right border


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
    "Pose", "pose", 32768,
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
    

integer g_iSPosition; // Do not pre-allocate script memory by setting this variable, it is set at run-time.

list g_lPrimOrder ;
integer g_iColumn = 1;  // 0 - Column, 1 - Alternate
integer g_iRows = 3;  // nummer of Rows: 1,2,3,4... up to g_iMaxRows
//integer g_iOldRows; // used during sensor to backup the row count
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
        
        vector scale = <0.05,0.05,0.05>;
        if(!llGetAttached())scale = <0.25,0.25,0.25>;
        llSetLinkPrimitiveParamsFast(llList2Integer(lPrimOrder,i-2),[PRIM_POSITION,pos, PRIM_SIZE, scale]);
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
            g_lButtons += llList2String(llGetLinkPrimitiveParams(i, [PRIM_NAME]),0);
            g_lPrimOrder += i;
            //llOwnerSay(".\nPrim: "+llList2String(llGetLinkPrimitiveParams(i,[PRIM_NAME]),0)+"\nNumber: "+(string)i);
        }
    }
    g_iMaxRows = llFloor(llSqrt(llGetListLength(g_lButtons)));
}


// for swapping buttons
//integer g_iNewPos;
//integer g_iOldPos;
/*
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
*/

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
    
    vector scale = <0.05,0.05,0.05>;
    if(!llGetAttached())scale = <0.25,0.25,0.25>;
    

    llSetLinkPrimitiveParamsFast(1,[PRIM_NAME, "OpenCollar Remote - 8.0", PRIM_DESC, "", PRIM_SIZE, scale, PRIM_COLOR, ALL_SIDES, <1,1,1>,0, PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, ZERO_VECTOR, ZERO_VECTOR,0]);
    for(i=LINK_ROOT+1; i<=end; i++){
        llSetText("Formatting HUD\nProgress: "+(string)(i*100/end)+"%",<1,0,0>,1);
        llSetLinkPrimitiveParamsFast(i,[PRIM_NAME, "Object", PRIM_DESC, "", PRIM_SIZE, scale, PRIM_POS_LOCAL, ZERO_VECTOR, PRIM_COLOR, ALL_SIDES, <1,1,1>,1, PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, ZERO_VECTOR, ZERO_VECTOR,0]);
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
    //llSetLinkPrimitiveParamsFast(1, [PRIM_SIZE, <0.05,0.05,0.05>]);
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
    
    g_iRetexture=1;
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
    return mask-4194304;
}

FormatPrim(){
    llSetText(">Processing Data", <1,0,0>,1);
    list active = GetActiveButtons();
    integer difference = llGetListLength(g_lButtons)-llGetListLength(active);

    vector scale = <0.05,0.05,0.05>;
    if(!llGetAttached())scale = <0.25,0.25,0.25>;
        
    // Erase all prims
    difference = llGetNumberOfPrims();
    do
    {
        if(difference!=LINK_ROOT)
            llSetLinkPrimitiveParamsFast(difference,[PRIM_NAME, "Object", PRIM_DESC, "", PRIM_SIZE, scale, PRIM_POS_LOCAL, ZERO_VECTOR, PRIM_COLOR, ALL_SIDES, <1,1,1>,1, PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, ZERO_VECTOR, ZERO_VECTOR,0]);
        difference--;
    } while(difference);


    llSetLinkPrimitiveParamsFast(1,[PRIM_NAME, "OpenCollar Remote - 8.0", PRIM_DESC, "", PRIM_SIZE, scale, PRIM_COLOR, ALL_SIDES, <1,1,1>,0, PRIM_TEXTURE, ALL_SIDES, TEXTURE_BLANK, ZERO_VECTOR, ZERO_VECTOR,0]);



    g_lButtons = [];
    g_lPrimOrder=[];
    Recalc();
    g_iRetexture=1;
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

list g_lOptedLM = [];
string g_sAddon = "OC_Remote";
Link(string packet, integer iNum, string sStr, key kID){
    if(llGetListLength(g_lAPIListeners)==0)return;
    list packet_data = [ "pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID ];

    if (packet == "online" || packet == "update") // only add optin if packet type is online or update
    {
        llListInsertList(packet_data, [ "optin", llDumpList2String(g_lOptedLM, "~") ], -1);
    }

    string pkt = llList2Json(JSON_OBJECT, packet_data);
    if (g_kCollar != "" && g_kCollar != NULL_KEY)
    {
        llRegionSayTo(g_kCollar, llList2Integer(g_lAPIListeners,0), pkt);
    }
    else
    {
        llRegionSay(llList2Integer(g_lAPIListeners,0), pkt);
    }
}




integer g_iLMLastRecv;

list g_lFavorites;
key g_kProfilePic;
integer g_iRetexture;

integer g_iListener=-1;
integer g_iChannel;
Menu(key kID)
{
    if(g_iListener!=-1)llListenRemove(g_iListener);
    list numbers  =  [];
    integer i=0;
    integer end = llGetListLength(g_lOptions);
    if(end>=12)
    {
        end=12;
        llInstantMessage(kID, "Some options are removed from the menu due to the SL dialog limit");
    }
    string prompt;
    integer iOnlyText=0;
    @redo;
    for(i=0;i<end;i++)
    {
        numbers += [(string)i];
        if(llGetAgentSize((key)llList2String(g_lOptions,i))==ZERO_VECTOR || iOnlyText){
            prompt += (string)i+") "+llGetDisplayName((key)llList2String(g_lOptions, i))+" ("+llGetUsername((key)llList2String(g_lOptions,i))+")\n";
        }else{
            prompt += (string)i+") secondlife:///app/agent/"+llList2String(g_lOptions,i)+"/about\n";
        }
    }
    if(llStringLength(prompt) >= 512 && !iOnlyText){
        iOnlyText =1;
        numbers=[];
        prompt="";
        jump redo;
    } else if(llStringLength(prompt)>=512 && iOnlyText){
        llInstantMessage(kID, prompt);
        prompt = "Too many digits to display, check local chat for names";
    }
    g_iChannel = llRound(llFrand(5483822));
    g_iListener = llListen(g_iChannel, "", kID, "");
    llDialog(kID, "[OpenCollar Remote]\n"+prompt, numbers, g_iChannel);
}

integer g_iDisconnectNext=0;
integer LM_SETTING_REQUEST = 2001;
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
        g_lFavorites = [(string)llGetOwner()];
        llMessageLinked(LINK_SET,-10,"","");
        DoCheckUpdate();
    }
    
    attach(key id){
        if(id!=NULL_KEY){
            Recalc();
            llOwnerSay("Ready");
            DoCheckUpdate();
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
        DoCheckUpdate();
    }
    
    no_sensor()
    {
        llOwnerSay("No one was found nearby");
        
        g_lOptions=[];
        if(llListFindList(g_lButtons, [llGetOwner()])==-1){
            g_lOptions += [llGetOwner()];
        }
        Menu(llGetOwner());
    }
    
    sensor(integer iNum)
    {
        g_lOptions=[];
        integer i;
        for(i=0;i<iNum;i++){
            g_lOptions += llDetectedKey(i);
        }
        if(llListFindList(g_lButtons, [llGetOwner()])==-1){
            g_lOptions += [llGetOwner()];
        }
        Menu(llGetOwner());
    }
    
    timer()
    {
        llSetText("",ZERO_VECTOR,0);
        if(llGetTime()>=10 && g_kCollar == NULL_KEY){
            llWhisper(0, "Timeout occured.");
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
        
        if(llGetTime()>=5&&g_iDisconnectNext)
        {
            llOwnerSay("Disconnect cancelled");
            g_iDisconnectNext=0;
        }
    }
    
    touch_start(integer t){
        string sName = llGetLinkName(llDetectedLinkNumber(0));
        string sCmd = llList2String(BTNS, llListFindList(BTNS, [sName])+1);
        
        integer iImplemented = FALSE;
        
        if(sCmd == "@hide"){
            iImplemented=1;
            g_iOldMask = g_iBitMask;
            g_iBitMask = 4194304;
            FormatPrim();
            Recalc();
            
            g_iRetexture=1;
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
            //llMessageLinked(LINK_SET,-1,"","");
            iImplemented=1;
            llSensor("", "", AGENT,  20, PI);
        } else if(sCmd == "@menu"){
            Link("from_addon", 0, "menu OC_Remote", llDetectedKey(0));
            iImplemented =1;
        } else if(sCmd == "@fav"){
            iImplemented=1;
            //if(g_kCollar!=NULL_KEY){
            //    llMessageLinked(LINK_SET,-1,"","");
            //    llSetText("", ZERO_VECTOR,0);
            //}
            g_lOptions=[];
            
            integer end = llGetListLength(g_lFavorites);
            integer i;
            for(i=0;i<end;i++){
                if(llGetAgentSize((key)llList2String(g_lFavorites,i))!=ZERO_VECTOR)
                {
                    // This user is in the region, display the box for them
                    key user = (key)llList2String(g_lFavorites,i);
                    g_lOptions += [(string)user];
                }
            }
            
            Menu(llGetOwner());

        } else if(sCmd == "@person")
        {
            iImplemented=1;
            if(g_kCollar!=NULL_KEY)
                llOwnerSay("You are connected to secondlife:///app/agent/"+(string)llGetOwnerKey(g_kCollar)+"/about's collar");
            else
                llOwnerSay("Not connected to a collar!");
                
            if(g_iDisconnectNext && g_kCollar!=NULL_KEY){
                
                llMessageLinked(LINK_SET,-1,"","");
                g_iDisconnectNext=0;
                llOwnerSay("Disconnecting...");
            } else {
                llResetTime();
                llOwnerSay("Click me again to disconnect from this collar");
                g_iDisconnectNext = 1;
            }
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
        } else if(kReq == g_kUpdateCheck){
            if(iStat==200){
                Compare(HUD_VERSION, sBody);
                if(g_iAmNewer){
                    llOwnerSay("Your current remote version is newer than the release version");
                }
                
                if(UPDATE_AVAILABLE){
                    llOwnerSay("UPDATE AVAILABLE: A new remote update is available. Please obtain it from OpenCollar");
                }
            }else{
                llOwnerSay("An error was detected while checking for an update. The server returned a invalid status code");
            }
        }
    }
    
    listen(integer c,string n,key i,string m){
        //llWhisper(0,m);
        if(c==g_iChannel)
        {
            if(g_kCollar!=NULL_KEY){
                llMessageLinked(LINK_SET,-1, "", "");
                Link("offline", 0, "",llGetOwnerKey(g_kCollar));
                llSleep(2);
            }
            key user = (key)llList2String(g_lOptions, (integer)m);
            StopAPIs();
            StartAPI(user);
            
            llOwnerSay("Attempting to connect...");
            
            llResetTime();
            llSetTimerEvent(1);
            llListenRemove(g_iListener);
            g_iListener=-1;
            return;
        }
        //llOwnerSay( "message from collar: "+m);
        if(llJsonGetValue(m,["pkt_type"])=="approved" && g_kCollar==NULL_KEY){
            // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
            g_kCollar = i;
            GetProfilePic(llGetOwnerKey(i));
            llOwnerSay("Connected!");
            llMessageLinked(LINK_SET, 2, "", g_kCollar);
            Link("from_addon", LM_SETTING_REQUEST, "ALL","");
            Link("from_addon", AUTH_REQUEST, "check_auth_remote", llGetOwner());
            
        } else if(llJsonGetValue(m,["pkt_type"])=="dc" && g_kCollar==i){
            llMessageLinked(LINK_SET, -1, "", "");
        } else if(llJsonGetValue(m,["pkt_type"])=="pong" && g_kCollar==i)
        {
            g_iLMLastRecv = llGetUnixTime();
        } else if(llJsonGetValue(m,["pkt_type"])=="from_collar"){
            // process link message if in range of addon
            if(llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(i, [OBJECT_POS]),0))<=10.0){
                // process it!
                llMessageLinked(LINK_SET, 0, m, "");
            }
        } else if(llJsonGetValue(m, ["pkt_type"]) == "denied")
        {
            llMessageLinked(LINK_SET, -1, "", "");
            llOwnerSay("Collar denied access");
        }
    }
    link_message(integer iSender, integer iNum, string sMsg, key kID)
    {
        if(iNum == -1){
            if(g_kCollar!=NULL_KEY){
                llOwnerSay("HUD has been disconnected from the remote collar");
                Link("offline", 0, "",llGetOwnerKey(g_kCollar));
                g_kCollar=NULL_KEY;
                llSetTimerEvent(0);
                llSetText("",ZERO_VECTOR,0);
                Recalc();
            }    
        } else if(iNum == -2){ // Favorites
            if(sMsg == "add"){
                if(llListFindList(g_lFavorites, [(string)llGetOwnerKey(g_kCollar)])==-1)g_lFavorites += [(string)llGetOwnerKey(g_kCollar)];
            }else {
                integer index = llListFindList(g_lFavorites, [(string)llGetOwnerKey(g_kCollar)]);
                if(index!=-1){
                    g_lFavorites = llDeleteSubList(g_lFavorites, index,index);
                }
            }
        } else if(iNum ==1 ){ // Destination : collar
            Link(kID, (integer)llJsonGetValue(sMsg, ["num"]), llJsonGetValue(sMsg, ["msg"]), llJsonGetValue(sMsg, ["id"]));
        } else if(iNum == 2)
        {
            // Request the current bitmask
            llMessageLinked(LINK_SET, -3, (string)g_iBitMask, "");
            Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
        } else if(iNum == -5) // set bitmask
        {
            g_iOldMask = g_iBitMask;
            g_iBitMask = (integer)sMsg;
            FormatPrim();
            g_iRetexture=1;
        } else if(iNum == 3)
        {
            // request the button list
            llMessageLinked(LINK_SET, -4, llDumpList2String(BTNS, "`"), "");
        } else if(iNum == 4){
            g_iRows++;
            Recalc();
            llMessageLinked(LINK_SET, 7, (string)g_iRows+"`"+sMsg, kID);
        } else if(iNum == 5){
            g_iRows--;
            Recalc();
            llMessageLinked(LINK_SET, 7, (string)g_iRows+"`"+sMsg, kID);
        } else if(iNum == 6){
            llMessageLinked(LINK_SET, 7, (string)g_iRows+"`"+sMsg, kID);
        }
    }
}
