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
//       Remote Options - 151231.3       .*' /  .*' ; .*`- +'  `*'          //
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
string g_sTextureMenu = "Textures";
string g_sOrderMenu   = "Order";
string g_sTintMenu    = "Tint";

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

float g_fGap = 0.002; // This is the space between buttons

// Variables

vector g_vColor = <1,1,1>;
key g_kMenuID;
string g_sCurrentMenu;
list g_lButtons ; // buttons names for Order menu
list g_lPrimOrder = [0, 1, 2, 3, 4, 5, 6];
//  List must always start with '0','1'
//  0:Spacer, 1:Root, 2:Menu, 3:Couples, 4:Bookmarks, 5:Leash, 6:Beckon
//  Spacer serves to even up the list with actual link numbers

integer g_iLayout = 0;
integer g_iHidden = FALSE;
integer g_iSPosition = 69; // Nuff'said =D
integer g_iOldPos;
integer g_iNewPos;
integer g_iTintable = FALSE;

//**************************

key Dialog(key kRcpt, string sPrompt, list lChoices, list lUtilityButtons, integer iPage) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRcpt + "|" + sPrompt + "|" + (string)iPage +
 "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    return kID;
}

FindButtons() { // collect buttons names
    g_lPrimOrder = [0, 1];
    g_lButtons = [" ", " "] ;
    integer i;
    for (i=2; i<llGetNumberOfPrims()+1; i++) {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_DESC]);
        g_lPrimOrder += i ;
    }
}

PlaceTheButton(float fYoff, float fZoff) {
    integer i = 2;
    for (; i < llGetListLength(g_lPrimOrder); ++i)
        llSetLinkPrimitiveParamsFast(llList2Integer(g_lPrimOrder,i), [PRIM_POSITION, <0.0, fYoff * (i - 1), fZoff * (i - 1)>]);
}

DoStyle(string sStyle) {

    list lWhiteTintTex  = ["8408646f-2d35-3938-cba9-0808a12fcb80",
                         "eb1f670d-c34f-23cb-3beb-f859c3c0278e",
                         "a81b25f9-5ab1-dd02-5740-eb06ca5bf219",
                         "1ff141eb-a448-b5c3-942d-6531b5c9d047",
                         "cf5b070b-f672-9488-81a4-945243ebb47d",
                         "a9245dc2-cca1-861e-c2da-e3cb071fb7a1"];

    list lGraySquareTex = ["0744de1c-a3bd-47db-b20f-2cb7b93a3ff1",
                         "09b69dd4-eb80-e2de-7dba-70c8337d283c",
                         "e9a16c40-7561-5a69-f834-f2f613fde10a",
                         "d6835f43-2477-d638-e203-8a22daee09fb",
                         "c72aef83-a0f0-fece-be02-295473986e79",
                         "68ad78d3-8e7b-4025-d8b1-98560aa31123"];

    list lGrayCircleTex = ["428f1dfc-251c-b204-da66-000082bee96f",
                         "6df113f7-c667-106b-e276-31dc1be37513",
                         "e856db47-1017-6bc8-69be-525945fbdb08",
                         "92087a5d-5009-5993-fed9-0274bfacd899",
                         "2a35bdf7-9744-aedf-ff60-5a49b04c356d",
                         "6b1a404f-db40-1aa2-7080-b4ab4235b963"];

    list lBlueTex        = ["fe7844f7-1179-5ba1-eb46-d44d3bed5837",
                         "7d5ebb11-b3e2-4353-231b-c898c5645872",
                         "2c52eb24-26a0-5110-089a-570b1602aaaa",
                         "520ae188-c472-ab7b-b1c6-d0fe53698c57",
                         "599c0404-5b79-a292-1c4f-83b655a81b43",
                         "db24ef0e-ca57-9f8c-ee1a-28fec74619ad"];

    list lRedTex         = ["4d61335b-2b3d-e3d2-a6b9-e3fba73f9f8e",
                         "917d6349-a01b-1c1e-7c49-1b889fd81217",
                         "c4ffeb2c-e779-b062-e254-b7afc9ca629e",
                         "d3a0b432-fbb6-44bd-4019-4fe75f17d2c4",
                         "d1684d22-627e-1370-987e-95e23c8a81a8",
                         "b75a0443-8f80-3889-f21d-8e895a34b2c0"];
//  Upon a texture change we should also reset the 'tint'

    list textures;
    if (sStyle == "White") textures = lWhiteTintTex;
    if (sStyle == "Gray Square") textures = lGraySquareTex;
    if (sStyle == "Gray Circle") textures = lGrayCircleTex;
    if (sStyle == "Blue Circle") textures = lBlueTex;
    if (sStyle == "Red Circle") textures = lRedTex;

    if (sStyle == "White") g_iTintable = TRUE;
    else g_iTintable = FALSE;

    if (g_iTintable) llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, g_vColor, 1.0]);
    else llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0]);

    integer iPrimNum = 5;
    integer i = 0;
    do llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(textures,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
    while((++i)<=iPrimNum);
}

DoHide() {
//  This moves the child prims under the root prim to hide them
    llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION, <1.0, 0.0, 0.0>]);
}

DefinePosition() {
    integer iPosition = llListFindList(g_lAttachPoints, [llGetAttached()]);
//  Allows manual repositioning, without resetting it, if needed
    if (iPosition != g_iSPosition) {
        // Set up the six root prim locations which all other posistions are based from
       /* list lRootOffsets = [
            <0.0,  0.02, -0.04>,    // Top right        (Position 0)
            <0.0,  0.00, -0.04>,    // Top middle       (Position 1)
            <0.0, -0.02, -0.04>,    // Top left         (Position 2)
            <0.0,  0.02,  0.10>,    // Bottom right     (Position 3)
            <0.0,  0.00,  0.07>,    // Bottom middle    (Position 4)
            <0.0, -0.02,  0.07>];   // Bottom left      (Position 5)*/
        //llSetPos((vector)llList2String(RootOffsets, Position)); // Position the Root Prim on screen
        g_iSPosition = iPosition;
    }
    if (!g_iHidden) { // -- Fixes Issue 615: HUD forgets hide setting on relog.
        vector size = llGetScale();
        float fYoff = size.y + g_fGap; float fZoff = size.z + g_fGap; // This is the space between buttons
        if (g_iLayout == 0 || iPosition == 1 || iPosition == 4) {// Horizontal + top and bottom are always horizontal
            if (iPosition == 2 || iPosition == 5) // Left side needs to push buttons right
                fYoff = fYoff * -1;
            fZoff = 0.0;
        } else {// Vertical
            if (iPosition == 0 || iPosition == 2)  // Top needs push buttons down
                fZoff = fZoff * -1;
            fYoff = 0.0;
        }
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

DoReset() {   // -- Reset the entire HUD back to default
    integer i = llGetInventoryNumber(INVENTORY_SCRIPT) -1;
    string sScript;
    do {
        sScript = llGetInventoryName(INVENTORY_SCRIPT,i);
        if (sScript != llGetScriptName() && sScript != "")
            llResetOtherScript(sScript);
    } while (--i > 0);

    llResetScript();
}

DoMenu(string sMenu) {

    string sPrompt;
    list lButtons;
    list lUtils = [UPMENU];

    if (sMenu == "Horizontal") {
        g_iLayout = 0;
        DefinePosition();
        sMenu = g_sHudMenu;
    }
    else if (sMenu == "Vertical") {
        g_iLayout = 69;
        DefinePosition();
        sMenu = g_sHudMenu;
    }

    if (sMenu == "RESET") {
        sPrompt = "\nConfirm reset of the entire HUD.\n\n";
        sPrompt += "!!!!!! W A R N I N G !!!!!!";
        sPrompt += "\nAll Subs not saved in '.subs' notecard will be removed from Subs list!\n";
        sPrompt += "\nAre You sure?";
        lButtons = ["Confirm","Cancel"];
        sMenu = g_sHudMenu;
        lUtils = [];
    }
    else if (sMenu == g_sHudMenu) { // Main
        sPrompt = "\nCustomize your Remote!";
        lButtons = ["Horizontal","Vertical","RESET",g_sOrderMenu,g_sTextureMenu];
    }
    else if (sMenu == g_sTextureMenu) { // textures
        sPrompt = "\nThis is the menu for styles.\n";
        sPrompt += "Selecting one of these options will\n";
        sPrompt += "change the color of the HUD buttons.\n";
        if (g_iTintable)
           sPrompt += "\nTint will allow you to change the HUD color\nto various shades via the '" + g_sTintMenu + "' menu.\n";
        else
            sPrompt += "\nIf [White] is selected, an extra menu named '" + g_sTintMenu +"' will appear in this menu.\n";
        lButtons = ["White","Gray Square","Gray Circle","Blue Circle","Red Circle"];
        if (g_iTintable) lButtons += [g_sTintMenu];
    }
    else if (sMenu == g_sOrderMenu) { // Order
        sPrompt = "\nThis is the order menu, simply select the\n";
        sPrompt += "button which you want to re-order.\n\n";

        integer i;
        for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
            integer pos = llList2Integer(g_lPrimOrder,i);
            lButtons += llList2List(g_lButtons,pos,pos);
        }
        lUtils = ["RESET",UPMENU];
    }
    else if (sMenu == g_sTintMenu) { // Tint
        sPrompt = "\nSelect the color you wish to tint the HUD.\n";
        sPrompt += "If you don't see a color you enjoy, simply edit\n";
        sPrompt += "and select a color under the menu you wish.\n";
        lButtons = ["colormenu please"];
    }
    g_sCurrentMenu = sMenu;
    g_kMenuID = Dialog(llGetOwner(), sPrompt, lButtons, lUtils, 0);
}

OrderButton(string sButton)
{
    g_sCurrentMenu = g_sOrderMenu;
    list lButtons;
    string sPrompt;

    if (sButton == "RESET") {
        sPrompt = "\nConfirm reset of the button order to default.\n\n";
        lButtons = ["Confirm","Cancel"];
        g_kMenuID = Dialog(llGetOwner(), sPrompt, lButtons, [], 0);
        return;
    } else {
        integer iTemp = llListFindList(g_lButtons,[sButton]);
        g_iOldPos = llListFindList(g_lPrimOrder, [iTemp]);
    }

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
        DoStyle("White");
        DoHide();
        DefinePosition();
        llOwnerSay("Finalizing HUD Reset... please wait a few seconds so all menus have time to initialize.");
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
                } else if (sButton == "Confirm") DoReset();
                else if (sButton == "Cancel") g_sCurrentMenu = g_sHudMenu;
                else g_sCurrentMenu = sButton;
            } else if (g_sCurrentMenu == g_sTextureMenu) {// -- Inside the 'Texture' menu, or 'submenu1'
                if (sButton == UPMENU) g_sCurrentMenu = g_sHudMenu;
                else if (sButton == g_sTintMenu) g_sCurrentMenu = g_sTintMenu;
                else  DoStyle(sButton);
            } else if (g_sCurrentMenu == g_sOrderMenu) {
                if (sButton == UPMENU) g_sCurrentMenu = g_sHudMenu;
                else if (sButton == "Confirm") {
                    FindButtons();
                    llOwnerSay("Order position reset to default.");
                    DefinePosition();
                } else if (sButton == "Cancel") g_sCurrentMenu = g_sOrderMenu;
                else if (llSubStringIndex(sButton,":") >= 0) { // Jess's nifty parsing trick for the menus
                    g_iNewPos = llList2Integer(llParseString2List(sButton,[":"],[]),1);
                    DoButtonOrder();
                } else {
                    OrderButton(sButton);
                    return;
                }
            } else if (g_sCurrentMenu == g_sTintMenu) {
                if (sButton == UPMENU) g_sCurrentMenu = g_sTextureMenu;
                else if ((vector)sButton) {
                    g_vColor = (vector)sButton;
                    llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, g_vColor, 1.0]);
                }
            }
            DoMenu(g_sCurrentMenu);
        } else if (iNum == CMD_TOUCH) {
            if (sStr == "hide") {
                if (g_iHidden) {
                    g_iHidden = !g_iHidden;
                    DefinePosition();
                } else {
                    g_iHidden = !g_iHidden;
                    DoHide();
                }
            }
        }
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_LINK) llResetScript();
    }
}
