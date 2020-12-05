  
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


float g_fGap = 0.0075; // This is the space between buttons
float g_Yoff = 0.002; // space between buttons and screen top/bottom border
float g_Zoff = 0.04; // space between buttons and screen left/right border



SetButtonTexture(integer link, string name) {
    integer idx = llListFindList(BTNS, [name]);
    if (idx == -1) return;
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
            0 
    ]);   
}

// starting at the top left and moving to the right, the button sprites are in
// this order.
list BTNS = [
    "Minimize",
    "People",
    "Menu",
    "Couples",
    "Favorite",
    "Bookmarks",
    "Lock",
    "Outfits",
    "Folders",
    "Unleash",
    "Leash",
    "Yank",
    "Sit",
    "Stand",
    "Rez",
    "Pose",
    "Stop",
    "Hudmenu",
    "Person",
    "Restrictions",
    "Titler",
    "Detach",
    "Maximize",
    "Macros",
    "Themes"
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
    }
    if (g_iHidden) { // -- Fixes Issue 615: HUD forgets hide setting on relog.
        SetButtonTexture(1, "Maximize");
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION, <1.0, 0.0, 0.0>]);
    } else {
        llSetLinkTexture(1, TEXTURE_TRANSPARENT, ALL_SIDES);
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
        
        for (i=2; i < n; i++) {
            if (g_iColumn == 0) { // Column
                if (!g_iLayout) pos = <fXoff, fYoff*(i-(i/(n/g_iRows))*(n/g_iRows)), fZoff*(i/(n/g_iRows))>;
                else pos = <fXoff, fYoff*(i/(n/g_iRows)), fZoff*(i-(i/(n/g_iRows))*(n/g_iRows))>;
            } else if (g_iColumn == 1) { // Alternate
                if (!g_iLayout) pos = <fXoff, fYoff*(i/g_iRows), fZoff*(i-(i/g_iRows)*g_iRows)>;
                else  pos = <fXoff, fYoff*(i-(i/g_iRows)*g_iRows), fZoff*(i/g_iRows)>;
            }
            
            llSetLinkPrimitiveParamsFast(llList2Integer(lPrimOrder,i),[PRIM_POSITION,pos]);
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
    g_lButtons = [] ;  // This appears to artificially require to be set with the number of blank buttons in the sprite map. TODO: Find a way to fix this so it does not require this.
    g_lPrimOrder = [];  
    integer i;
    for (i=2; i<llGetNumberOfPrims(); i++) {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_NAME]);
        g_lPrimOrder += i;
    }
    g_iMaxRows = llFloor(llSqrt(llGetListLength(g_lButtons)-1));
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
default
{
    state_entry() {
        g_kOwner = llGetOwner();
        integer i=0;
        integer end = llGetListLength(BTNS);
        for(i=1;i<end;i++)
        {
            llSetLinkPrimitiveParams(i+2, [PRIM_NAME, llList2String(BTNS,i)]);
        }
        FindButtons(); // collect buttons names
        llSleep(1.0);//giving time for others to reset before populating menu
        
        g_iPicturePrim = PicturePrim();
        TextureButtons();
        //SetButtonTexture(3, "Menu");
        PositionButtons();
    }
}
