// This file is part of OpenCollar.
// Copyright (c) 2014 - 2016 Nandana Singh, Jessenia Mocha, Alexei Maven, 
// Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, 
// Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.  
// Licensed under the GPLv2.  See LICENSE for full details. 

//Adjusted to OpenCollar name convention und format standards June 2015 Otto (garvin.twine)
//Updated Romka(romka.swallowtail)

// MESSAGE MAPS
integer CMD_TOUCH         = 100;
//integer MENUNAME_REQUEST  = 3000;
//integer MENUNAME_RESPONSE = 3001;
integer SUBMENU           = 3002;
integer DIALOG            = -9000;
integer DIALOG_RESPONSE   = -9001;
//integer DIALOG_TIMEOUT    = -9002;

// Constants
string UPMENU         = "BACK";
string g_sParentMenu  = "Main";
string g_sHudMenu     = "HUD Style";
string g_sTextureMenu = "Theme";
string g_sOrderMenu   = "Order";

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

float g_fGap = 0.001; // This is the space between buttons
float g_Yoff = 0.002; // space between buttons and screen top/bottom border
float g_Zoff = 0.04; // space between buttons and screen left/right border

// Variables

vector g_vColor = <1,1,1>;
key g_kMenuID;
string g_sCurrentMenu;
string g_sCurrentTheme;
list g_lStyles;
list g_lButtons ; // buttons names for Order menu
list g_lPrimOrder ;
//  List must always start with '0','1'
//  0:Spacer, 1:Root, 2:Menu, 3:Couples, 4:Bookmarks, 5:Leash, 6:Beckon
//  Spacer serves to even up the list with actual link numbers

integer g_iVertical = TRUE;  // can be vertical?
integer g_iLayout = 1; // 0 - Horisontal, 1 - Vertical
integer g_iHidden = FALSE;
integer g_iSPosition = 69; // Nuff'said =D
integer g_iOldPos;
integer g_iNewPos;
integer g_iColumn = 1;  // 0 - Column, 1 - Alternate
integer g_iRows = 3;  // nummer of Rows: 1,2,3,4... up to g_iMaxRows
integer g_iMaxRows = 4; // maximal Rows in Columns

//**************************

key Dialog(key kRcpt, string sPrompt, list lChoices, list lUtilityButtons, integer iPage) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRcpt + "|" + sPrompt + "|" + (string)iPage +
 "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    return kID;
}

FindButtons() { // collect buttons names & links
    g_lButtons = [" ", "Minimize"] ; // 'Minimize' need for texture
    g_lPrimOrder = [0, 1];  //  '1' - root prim
    integer i;
    for (i=2; i<llGetNumberOfPrims()+1; ++i) {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_NAME]);
        g_lPrimOrder += i;
    }
    g_iMaxRows = llFloor(llSqrt(llGetListLength(g_lButtons)-1));
}

PlaceTheButton(float fYoff, float fZoff) {
    list lPrimOrder = llDeleteSubList(g_lPrimOrder, 0, 0);
    integer n = llGetListLength(lPrimOrder);
    vector pos ;
    integer i;
    float fXoff = 0.01; // small X offset
    for (i=1; i < n; ++i) {
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


DoStyle(string style) {

    list lTextures = [
    "[ Dark ]",
    "Minimize~",
    "Picture~",
    "Menu~",
    "Couples~",
    "Favorite~",
    "Bookmarks~",
    "Restrictions~",
    "Outfits~",
    "Folders~",
    "Leash~",
    "Unleash~",
    "Yank~",
    "Sit~",
    "Stand~",
    "Rez~",
    "Pose~",
    "Stop~",
    "Hudmenu~",
    "Acc-Gag~",
    "Acc-Blindfold~",
    "Acc-Cuffs~",
    "[ Light ]",
    "Minimize~",
    "Picture~",
    "Menu~",
    "Couples~",
    "Favorite~",
    "Bookmarks~",
    "Restrictions~",
    "Outfits~",
    "Folders~",
    "Leash~",
    "Unleash~",
    "Yank~",
    "Sit~",
    "Stand~",
    "Rez~",
    "Pose~",
    "Stop~",
    "Hudmenu~",
    "Acc-Gag~",
    "Acc-Blindfold~",
    "Acc-Cuffs~"
    ];

    integer i;
    while (i < llGetListLength(lTextures)) {
        string sData = llStringTrim(llList2String(lTextures,i),STRING_TRIM);
        if (sData!="" && llSubStringIndex(sData,"#") != 0) {
            if (llGetSubString(sData,0,0) == "[") {
                sData = llGetSubString(sData,llSubStringIndex(sData,"[")+1,llSubStringIndex(sData,"]")-1);
                sData = llStringTrim(sData,STRING_TRIM);
                if (style=="initialize") {  //reading notecard to determine style names
                    g_lStyles += sData;
                } else if (sData==style) {  //we just found our section
                    style="processing";
                    g_sCurrentTheme = sData;
                } else if (style=="processing") {  //we just found the start of the next section, we're
                    return;
                }
            } else if (style=="processing") {
                list lParams = llParseStringKeepNulls(sData,["~"],[]);
                string sButton = llStringTrim(llList2String(lParams,0),STRING_TRIM);
                integer link = llListFindList(g_lButtons,[sButton]);
                if (link > 0) {
                    sData = llStringTrim(llList2String(lParams,1),STRING_TRIM);
                    if (sData != "" && sData != ",") {
                        if (sButton == "Picture") llMessageLinked(LINK_SET, 111, sData, "");
                        else llSetLinkPrimitiveParamsFast(link,[PRIM_TEXTURE, ALL_SIDES, sData , <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0, PRIM_COLOR, ALL_SIDES, g_vColor, 1.0]);
                    }
                }
            }
        }
        i++;
    }
}

DefinePosition() {
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
    if (g_iHidden)  // -- Fixes Issue 615: HUD forgets hide setting on relog.
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION, <1.0, 0.0, 0.0>]);
    else {
        float fYoff = size.y + g_fGap; float fZoff = size.z + g_fGap; // This is the space between buttons
        if (iPosition == 0 || iPosition == 1 || iPosition == 2) fZoff = -fZoff;
        if (iPosition == 1 || iPosition == 2 || iPosition == 4 || iPosition == 5) fYoff = -fYoff;
        PlaceTheButton(fYoff, fZoff); // Does the actual placement
    }
}

DoButtonOrder() {   // -- Set the button order and reset display
    integer iOldPos = llList2Integer(g_lPrimOrder,g_iOldPos);
    integer iNewPos = llList2Integer(g_lPrimOrder,g_iNewPos);
    integer i = 2;
    list lTemp = [0,1];
    for(;i<llGetListLength(g_lPrimOrder);++i) {
        integer iTempPos = llList2Integer(g_lPrimOrder,i);
        if (iTempPos == iOldPos) lTemp += [iNewPos];
        else if (iTempPos == iNewPos) lTemp += [iOldPos];
        else lTemp += [iTempPos];
    }
    g_lPrimOrder = lTemp;
    g_iOldPos = -1;
    g_iNewPos = -1;
    DefinePosition();
}


DoMenu(string sMenu) {

    string sPrompt;
    list lButtons;
    list lUtils = [UPMENU];

    if (sMenu == "Horizontal >" || sMenu == "Vertical >") {
        g_iLayout = !g_iLayout;
        DefinePosition();
        sMenu = g_sHudMenu;
    }
    else if (sMenu == "Columns >" || sMenu == "Alternate >") {
        g_iColumn = !g_iColumn;
        DefinePosition();
        sMenu = g_sHudMenu;
    }
    else if (llSubStringIndex(sMenu,"Rows")==0) {
        // this feature is not mandatory, it just passes uneven rows.
        // for the simple can use only g_iRows++;
        integer n = llGetListLength(g_lPrimOrder)-1;
        do {
            g_iRows++;
        } while ((n/g_iRows)*(n/(n/g_iRows)) != n);
        //
        if (g_iRows > g_iMaxRows) g_iRows = 1;
        DefinePosition();
        sMenu = g_sHudMenu;
    }
    else if (sMenu == g_sTextureMenu) { // textures
        sPrompt = "\nCurrent button theme: " + g_sCurrentTheme;
        lButtons = g_lStyles;
    }
    else if (sMenu == g_sOrderMenu) { // Order
        sPrompt = "\nThis is the order menu, simply select the\n";
        sPrompt += "button which you want to re-order.\n\n";
        integer i;
        for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
            integer pos = llList2Integer(g_lPrimOrder,i);
            lButtons += llList2List(g_lButtons,pos,pos);
        }
        lUtils = ["Reset",UPMENU];
    }
    if (sMenu == g_sHudMenu) { // Main
        sPrompt = "\nCustomize your Remote!";
        lButtons = ["Rows: "+(string)g_iRows] ;
        if (g_iRows > 1) lButtons += llList2List(["Columns >","Alternate >"], g_iColumn, g_iColumn) ;
        else lButtons += [" - "] ;
        if (g_iVertical) lButtons += llList2List(["Horizontal >","Vertical >"], g_iLayout,g_iLayout) ;
        else lButtons += [" - "] ;
        lButtons += [g_sOrderMenu,g_sTextureMenu,"Reset"];
    }
    g_sCurrentMenu = sMenu;
    g_kMenuID = Dialog(llGetOwner(), sPrompt, lButtons, lUtils, 0);
}

OrderButton(string sButton)
{
    g_sCurrentMenu = g_sOrderMenu;
    list lButtons;
    string sPrompt;
    integer iTemp = llListFindList(g_lButtons,[sButton]);
    g_iOldPos = llListFindList(g_lPrimOrder, [iTemp]);

    sPrompt = "\nSelect the new position for swap with "+sButton+"\n\n";
    integer i;
    for(i=2;i<llGetListLength(g_lPrimOrder);++i) {
        if (g_iOldPos != i) {
            lButtons +=[llList2String(g_lButtons,llList2Integer(g_lPrimOrder,i))+":"+(string)i];
        }
    }
    g_kMenuID = Dialog(llGetOwner(), sPrompt, lButtons, [UPMENU], 0);
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}


default
{
    state_entry() {
        //llSleep(1.0);
        PermsCheck();
        FindButtons(); // collect buttons names
        DefinePosition();
        DoStyle("initialize");
        DoStyle(llList2String(g_lStyles, 0));
       // llOwnerSay("Finalizing HUD Reset... please wait a few seconds so all menus have time to initialize.");
    }

    attach(key kAttached) {
        integer iAttachPoint = llGetAttached();
//      if being detached
        if (kAttached == NULL_KEY)
            return;
        else if (iAttachPoint < 31 || iAttachPoint > 38) {//http://wiki.secondlife.com/wiki/LlAttachToAvatar attach point integer values - 31-38 are hud placements
            llOwnerSay("Sorry, this device can only be placed on the HUD. Attach code: " + (string)iAttachPoint);
            llRequestPermissions(kAttached, PERMISSION_ATTACH);
            llDetachFromAvatar();
            return;
        }
        else // It's being attached and the attachment point is a HUD position, DefinePosition()
            DefinePosition();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == SUBMENU && sStr == g_sHudMenu) DoMenu(g_sHudMenu);
        else if (iNum == DIALOG_RESPONSE && kID == g_kMenuID) {
            list lParams = llParseString2List(sStr, ["|"], []);
            //kID = (key)llList2String(lParams, 0);
            string sButton = llList2String(lParams, 1);
            //integer iPage = (integer)llList2String(lParams, 2);
            if (g_sCurrentMenu == g_sHudMenu) {   // -- Inside the 'Options' menu, or 'submenu'
                // If we press the 'Back' and we are inside the Options menu, go back to OwnerHUD menu
                if (sButton == UPMENU) {
                    llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
                    return;
                } else if (sButton == "Reset") {
                    llOwnerSay("Resetting the HUD-Style to the default.");
                    llResetScript();
                } else if (sButton == "Cancel") g_sCurrentMenu = g_sHudMenu;
                else g_sCurrentMenu = sButton;
            } else if (g_sCurrentMenu == g_sTextureMenu) {// -- Inside the 'Texture' menu, or 'submenu1'
                if (sButton == UPMENU) g_sCurrentMenu = g_sHudMenu;
                else DoStyle(sButton);
            } else if (g_sCurrentMenu == g_sOrderMenu) {
                if (sButton == UPMENU) g_sCurrentMenu = g_sHudMenu;
                else if (sButton == "Reset") {
                    FindButtons();
                    llOwnerSay("Order position reset to default.");
                    DefinePosition();
                } else if (llSubStringIndex(sButton,":") >= 0) { // Jess's nifty parsing trick for the menus
                    g_iNewPos = llList2Integer(llParseString2List(sButton,[":"],[]),1);
                    DoButtonOrder();
                } else {
                    OrderButton(sButton);
                    return;
                }
            }
            DoMenu(g_sCurrentMenu);
        } else if (iNum == CMD_TOUCH) {
            if (sStr == "hide") {
                g_iHidden = !g_iHidden;
                DefinePosition();
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_LINK) llResetScript();
        if (iChange & CHANGED_INVENTORY) PermsCheck();
    }
}
