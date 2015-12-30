////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           OpenCollarHUD - hudoptions                           //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//  HudOptions (Alexei Maven + Jessenia Mocha)
//  This script could be used to position all HUDs quite easy.  Please remember this is Open Source
//  Thus you need to Credit Open Collar / Alexei Maven / Jessenia Mocha and not sell it!
//  Special thanks to Betsy Hastings for her Cages!

//  This script was intended to make the Open Collar Owners HUD as customizable as possible for the user.
//  The second goal was to make it easy for the developers to make new add-ons, and minimize script changes.
//  The code in this script reflects the two above goals. There is a reason for every line.

//  Start Jess's OC modified menu injection

//Adjusted to OpenCollar name convention und format standards June 2015 Otto (garvin.twine)

integer CMD_TOUCH         = 100;
integer MENUNAME_REQUEST  = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU           = 3002;
integer DIALOG            = -9000;
integer DIALOG_RESPONSE   = -9001;
integer DIALOG_TIMEOUT    = -9002;

string UPMENU     = "BACK";
string g_sParentMenu = "Main";
string g_sHudMenu    = "HUD Style";
string g_sSubMenu1   = "Textures";
string g_sSubMenu2   = "Order";
string g_sSubMenu3   = "Tint";
string g_sCurrentMenu;

key g_kMenuID;

key Dialog(key kRcpt, string sPrompt, list lChoices, list lUtilityButtons, integer iPage) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRcpt + "|" + sPrompt + "|" + (string)iPage +
 "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
    return kID;
}

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

list g_lPrimOrder = [0, 1, 2, 5, 4, 3, 6];
//  List must always start with '0','1'
//  0:Spacer, 1:Root, 2:Menu, 3:Beckon, 4:Bookmarks, 5:Couples, 6:Leash
//  Spacer serves to even up the list with actual link numbers

integer g_iLayout;
integer g_iHidden;
integer g_iSPosition = 69; // Nuff'said =D
integer g_iOldPos;
integer g_iNewPos;
integer g_iTintable = FALSE;

PlaceTheButton(float fYoff, float fZoff) {
    integer i = 2;
    for (; i <= llGetListLength(g_lPrimOrder); ++i)
        llSetLinkPrimitiveParamsFast(llList2Integer(g_lPrimOrder,i), [PRIM_POSITION, <0.0, fYoff * (i - 1), fZoff * (i - 1)>]);
}

DoTextures(string sStyle) {
//  Texture Settings by Jessenia Mocha
//  Texture UUID's [ Root, Menu, Teleport, Cage, Couples, Leash ]
    list lBlueTex        = ["fe7844f7-1179-5ba1-eb46-d44d3bed5837",
                         "7d5ebb11-b3e2-4353-231b-c898c5645872",
                         "db24ef0e-ca57-9f8c-ee1a-28fec74619ad",
                         "520ae188-c472-ab7b-b1c6-d0fe53698c57",
                         "2c52eb24-26a0-5110-089a-570b1602aaaa",
                         "599c0404-5b79-a292-1c4f-83b655a81b43"];

    list lRedTex         = ["4d61335b-2b3d-e3d2-a6b9-e3fba73f9f8e",
                         "917d6349-a01b-1c1e-7c49-1b889fd81217",
                         "b75a0443-8f80-3889-f21d-8e895a34b2c0",
                         "d3a0b432-fbb6-44bd-4019-4fe75f17d2c4",
                         "c4ffeb2c-e779-b062-e254-b7afc9ca629e",
                         "d1684d22-627e-1370-987e-95e23c8a81a8"];

    list lGraySquareTex = ["0744de1c-a3bd-47db-b20f-2cb7b93a3ff1",
                         "09b69dd4-eb80-e2de-7dba-70c8337d283c",
                         "68ad78d3-8e7b-4025-d8b1-98560aa31123",
                         "d6835f43-2477-d638-e203-8a22daee09fb",
                         "e9a16c40-7561-5a69-f834-f2f613fde10a",
                         "c72aef83-a0f0-fece-be02-295473986e79"];

    list lGrayCircleTex = ["428f1dfc-251c-b204-da66-000082bee96f",
                         "6df113f7-c667-106b-e276-31dc1be37513",
                         "6b1a404f-db40-1aa2-7080-b4ab4235b963",
                         "92087a5d-5009-5993-fed9-0274bfacd899",
                         "e856db47-1017-6bc8-69be-525945fbdb08",
                         "2a35bdf7-9744-aedf-ff60-5a49b04c356d"];

    list lWhiteTintTex  = ["8408646f-2d35-3938-cba9-0808a12fcb80",
                         "eb1f670d-c34f-23cb-3beb-f859c3c0278e",
                         "a9245dc2-cca1-861e-c2da-e3cb071fb7a1",
                         "1ff141eb-a448-b5c3-942d-6531b5c9d047",
                         "a81b25f9-5ab1-dd02-5740-eb06ca5bf219",
                         "cf5b070b-f672-9488-81a4-945243ebb47d"];

//  Upon a texture change we should also reset the 'tint'
    llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1, 1, 1>, 1.0]);
//  If we don't select "White" as the style, remove g_iTintable flag
    if (sStyle != "White") g_iTintable = FALSE;
    integer iPrimNum = 5;
    integer i = 0;
    if (sStyle == "Gray Square") {
        do llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(lGraySquareTex,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        while((++i)<=iPrimNum);
    } else if (sStyle == "Gray Circle") {
        do llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(lGrayCircleTex,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        while((++i)<=iPrimNum);
    } else if (sStyle == "Red") {
        do  llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(lRedTex,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        while((++i)<=iPrimNum);
    } else if (sStyle == "Blue") {
        do  llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(lBlueTex,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        while((++i)<=iPrimNum);
    } else if (sStyle == "White") {
        do  llSetLinkPrimitiveParamsFast(i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(lWhiteTintTex,i), <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        while((++i)<=iPrimNum);
    }
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
        float fYoff = 0.037; float fZoff = 0.037; // This is the space between buttons
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
        if (iTempPos == iOldPos)
            lTemp += [iNewPos];
        else if (iTempPos == iNewPos)
            lTemp += [iOldPos];
        else
            lTemp += [iTempPos];
    }
    g_lPrimOrder = [];
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
    g_iLayout = 0;
    g_iSPosition = 69; // -- Don't we just love that position? *winks*
    g_iTintable = FALSE;
    g_iHidden = FALSE;
    DoTextures("White");
    llSleep(2.0);
    g_lPrimOrder = [0, 1, 2, 5, 4, 3, 6];
    DoHide();
    llSleep(1.0);
    DefinePosition();
    llSleep(2.0); // -- We want the position to be set before reset
    llOwnerSay("Finalizing HUD Reset... please wait a few seconds so all menus have time to initialize.");
    llResetScript();
}

default
{
    state_entry() {
        //llSleep(1.0);
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sHudMenu, "");
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
        else if (iNum == SUBMENU && sStr == g_sHudMenu) {
            g_sCurrentMenu = g_sHudMenu;
            string sPrompt = "\nCustomize your Owner HUD!\n\nwww.opencollar.at/ownerhud";
            list lButtons = ["Horizontal","Vertical","Textures","Order","RESET"];
            g_kMenuID = Dialog(llGetOwner(), sPrompt, lButtons, [UPMENU], 0);
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kMenuID) {
                list lParams = llParseString2List(sStr, ["|"], []);
                kID = (key)llList2String(lParams, 0);
                string sButton = llList2String(lParams, 1);
                integer iPage = (integer)llList2String(lParams, 2);
                integer iPrimCount = llGetListLength(g_lPrimOrder);
                string sPrompt;
                list lButtons;
                if (g_sCurrentMenu == g_sHudMenu) {   // -- Inside the 'Options' menu, or 'submenu'
//                  If we press the 'Back' and we are inside the Options menu, go back to OwnerHUD menu
                    if (sButton == UPMENU)
                        llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
                    else if (sButton == "Horizontal") {
                        g_iLayout = 0;
                        DefinePosition();
                    } else if (sButton == "Vertical") {
                        g_iLayout = 69;
                        DefinePosition();
                    } else if (sButton == "Textures") {
                        g_sCurrentMenu = g_sSubMenu1;
                        sPrompt = "\nThis is the menu for styles.\n";
                        sPrompt += "Selecting one of these options will\n";
                        sPrompt += "change the color of the HUD buttons.\n";
                        if (g_iTintable)
                            sPrompt+="Tint will allow you to change the HUD color\nto various shades via the 'Tint' menu.\n";
                        else
                            sPrompt += "If [White] is selected, an extra menu named 'Tint' will appear in this menu.\n";
                        lButtons = ["Gray Square","Gray Circle","Blue","Red","White"];
                        if (g_iTintable) lButtons += ["Tint","-","-"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    } else if (sButton == "Order") {
                        g_sCurrentMenu = g_sSubMenu2;
                        sPrompt = "\nThis is the order menu, simply select the\n";
                        sPrompt += "button which you want to re-order.\n\n";
                        lButtons = [];
                        integer i;
                        for (i=0;i<iPrimCount;++i)
                        {
                            integer _pos = llList2Integer(g_lPrimOrder,i);
                            if (_pos == 2) lButtons += ["Menu"];
                            else if (_pos == 3) lButtons += ["Couples"];
                            else if (_pos == 4) lButtons += ["Bookmarks"];
                            else if (_pos == 5) lButtons += ["Beckon"];
                            else if (_pos == 6) lButtons += ["Leash"];
                        }
                        lButtons += ["RESET"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    } else if (sButton == "RESET") {
                        sPrompt = "\nConfirm reset of the entire HUD.\n\n";
                        lButtons = ["Confirm","Cancel"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    }
                    else if (sButton == "Confirm")
                        DoReset();
                } else if (g_sCurrentMenu == g_sSubMenu1) {// -- Inside the 'Texture' menu, or 'submenu1'
                    if (sButton == UPMENU)
                        llMessageLinked(LINK_SET, SUBMENU, g_sHudMenu, kID);
                    else if ((sButton == "Gray Square") || (sButton == "Gray Circle") || (sButton == "Blue") || (sButton == "Red"))
                        DoTextures(sButton);
                    else if (sButton == "White") {
                        g_iTintable = TRUE;
                        DoTextures(sButton);
                    }
                    else if (sButton == "Tint") {
                        g_sCurrentMenu = g_sSubMenu3;
                        sPrompt = "\nSelect the color you wish to tint the HUD.\n";
                        sPrompt += "If you don't see a color you enjoy, simply edit\n";
                        sPrompt += "and select a color under the menu you wish.\n";
                        lButtons = ["Orange","Yellow","Pink","Purple","Sky Blue","Light Green","Cyan","Mint"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], iPage);
                    }
                } else if (g_sCurrentMenu == g_sSubMenu2) {
                    if (sButton == UPMENU)
                        llMessageLinked(LINK_SET, SUBMENU, g_sHudMenu, kID);
                    else if (sButton == "Menu") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [2]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Beckon") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [3]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Bookmarks") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [4]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Couples") {
                        g_iOldPos = llListFindList(g_lPrimOrder, [5]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i)
                        {
                            if (g_iOldPos != i)
                            {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    }
                    else if (sButton == "Leash")
                    {
                        g_iOldPos = llListFindList(g_lPrimOrder, [6]);
                        sPrompt = "\nSelect the new position for "+sButton+"\n\n";
                        lButtons = [];
                        integer i = 2;
                        for(;i<=iPrimCount;++i) {
                            if (g_iOldPos != i) {
                                integer iTemp = llList2Integer(g_lPrimOrder,i);
                                if (iTemp == 2) lButtons += ["Menu:"+(string)i];
                                else if (iTemp == 3) lButtons += ["Beckon:"+(string)i];
                                else if (iTemp == 4) lButtons += ["Bookmarks:"+(string)i];
                                else if (iTemp == 5) lButtons += ["Couples:"+(string)i];
                                else if (iTemp == 6) lButtons += ["Leash:"+(string)i];
                            }
                        }
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "RESET") {
                        sPrompt = "\nConfirm reset of the button order to default.\n\n";
                        lButtons = ["Confirm","Cancel"];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Confirm") {
                        g_lPrimOrder = [];
                        g_lPrimOrder = [0,1,2,3,4,5,6];
                        llOwnerSay("Order position reset to default.");
                        DefinePosition();
                    } else if (llSubStringIndex(sButton,":") >= 0) {   // Jess's nifty parsing trick for the menus
                        list lNewPosList = llParseString2List(sButton, [":"],[]);
                        g_iNewPos = llList2Integer(lNewPosList,1);
                        DoButtonOrder();
                    }
                } else if (g_sCurrentMenu == g_sSubMenu3) {    // -- Inside the 'Tint' menu, or 'g_sSubMenu3'
                    if (sButton == UPMENU) {
                        g_sCurrentMenu = g_sSubMenu1;
                        sPrompt = "\nThis is the menu for styles.\n";
                        sPrompt += "Selecting one of these options will\n";
                        sPrompt += "change the color of the HUD buttons.\n";
                        if (g_iTintable) sPrompt+="Tint will allow you to change the HUD color\nto various shades via the 'Tint' menu.\n";
                        else sPrompt += "If [White] is selected, an extra menu named 'Tint' will appear in this menu.\n";
                        lButtons = ["Gray Square","Gray Circle","Blue","Red","White"];
                        if (g_iTintable) lButtons += ["Tint"," "," "];
                        g_kMenuID = Dialog(kID, sPrompt, lButtons, [], iPage);
                    } else if (sButton == "Orange")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1, 0.49804, 0>, 1.0]);
                    else if (sButton == "Yellow")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1, 1, 0>, 1.0]);
                    else if (sButton == "Light Green")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0, 1, 0>, 1.0]);
                    else if (sButton == "Pink")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1, 0.58431, 1>, 1.0]);
                    else if (sButton == "Purple")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.50196, 0, 1>, 1.0]);
                    else if (sButton == "Sky Blue")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.52941, 0.80784, 1>, 1.0]);
                    else if (sButton == "Cyan")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0, 0.80784, 0.79216>, 1.0]);
                    else if (sButton == "Mint")
                        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.49020, 0.73725, 0.49412>, 1.0]);
                }
            }
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
        if (iChange & CHANGED_OWNER) {
            DoTextures("White");
            llResetScript();
        }
    }
}
