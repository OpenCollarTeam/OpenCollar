//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//       Remote Options - 160126.1       .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, //
//  Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.   //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//Adjusted to OpenCollar name convention und format standards June 2015 Otto (garvin.twine)
//Updated Romka(romka.swallowtail)

// MESSAGE MAPS
integer CMD_TOUCH         = 100;
integer MENUNAME_REQUEST  = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU           = 3002;
integer DIALOG            = -9000;
integer DIALOG_RESPONSE   = -9001;
integer DIALOG_TIMEOUT    = -9002;

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
    "Minimize~e1482c7e-8609-fcb0-56d8-18c3c94d21c0",
    "Picture~4fb4a7fe-733b-fae7-810d-81e6784bc3c3",
    "Menu~f3ec1052-6ec4-04ba-d752-937a4d837bf8",
    "Couples~2a25fbfb-c2d3-e718-df84-9dcd175d5881",
    "Favorite~c5f69d7e-13ad-30dc-cd81-7509e5bdf9bc",
    "Bookmarks~3677746b-5bff-65bc-486f-a4ee01d1ef0d",
    "Restrictions~554bd266-018e-b577-72af-23f05d67e4a7",
    "Outfits~a04c713c-0531-024e-148b-8afbaa8eb816",
    "Folders~42cb5244-b62d-1403-07d2-97424ac3cf22",
    "Leash~b0c44ba4-ec7f-8cc6-7c26-44efa4bcd89c",
    "Unleash~7bcbf3a4-6bd4-329b-d1dc-87b422bb50cc",
    "Yank~c3343ece-30ae-5168-0cc2-b89f670b6826",
    "Sit~114ff31f-1887-0771-a414-7b65387fc6c0",
    "Stand~05ff2266-08ce-4408-1488-ba2c984ff674",
    "Rez~d5c985f6-a0cf-68a3-cc68-a5cd144f6200",
    "Pose~b2893dc1-2d38-5819-c8b1-6b7e931daad2",
    "Stop~88ea147b-939d-6462-adba-3c38cc0642f8",
    "Hudmenu~682cca8f-f1fe-f70e-f804-0a52a7838ddc",
    "[ Light ]",
    "Minimize~b59f9932-5de4-fc23-b5aa-2ab46d22c9a6",
    "Picture~86517d37-d251-06aa-0d57-127853f193b9",
    "Menu~52c3f4cf-e87e-dbdd-cf18-b2c4f6002a96",
    "Couples~dca287df-f0eb-1537-c903-ae29b76ef2fe",
    "Favorite~1bf5c34f-3831-2ebb-e3aa-3e5b3a924e5d",
    "Bookmarks~7d2a1943-ed4c-03b6-cdfe-90c03cc0a0a6",
    "Restrictions~05a38041-0c12-1966-e99a-61a11bc598b1",
    "Outfits~989b40c1-ba13-1d99-fd7d-5e4a72ccc837",
    "Folders~90fde3f4-14d9-7420-f2a8-5a9cd9cd7cad",
    "Leash~752f586b-a110-b951-4c9e-23beb0f97d2f",
    "Unleash~2aeecb18-8ca3-b64a-3e47-42ba5322198d",
    "Yank~50f5c540-d0bb-00b0-ce6c-23eb7b70bfa4",
    "Sit~4c5553b8-e3e1-f10f-8e8c-c9b3c6361954",
    "Stand~faa9824b-414e-97d9-91a6-db4ef08ba3eb",
    "Rez~2a284c71-6c96-b0fd-9415-963e4bca9ca0",
    "Pose~c48d0e15-db82-9799-c3e3-882d9669bca4",
    "Stop~fcb2ccd6-5ebe-dc16-5002-618601b66500",
    "Hudmenu~79f42937-65fb-8c3b-5a06-8f9d9cf21234"
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
            integer iTemp = llList2Integer(g_lPrimOrder,i);
            lButtons +=[llList2String(g_lButtons,iTemp)+":"+(string)i];
        }
    }
    g_kMenuID = Dialog(llGetOwner(), sPrompt, lButtons, [UPMENU], 0);
}

default
{
    state_entry() {
        //llSleep(1.0);
        FindButtons(); // collect buttons names
        DefinePosition();
        DoStyle("initialize");
        DoStyle(llList2String(g_lStyles, 0));
       // llOwnerSay("Finalizing HUD Reset... please wait a few seconds so all menus have time to initialize.");
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sHudMenu, "");
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
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sHudMenu, "");
        else if (iNum == SUBMENU && sStr == g_sHudMenu) DoMenu(g_sHudMenu);
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
    }
}
