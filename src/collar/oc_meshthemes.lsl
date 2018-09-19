// This file is part of OpenCollar.
// Copyright (c) 2017 Nirea Resident
// Licensed under the GPLv2.  See LICENSE for full details.

integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer LINK_DIALOG = 3;
integer LINK_UPDATE = -10;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;

integer NOTIFY = 1002;


integer g_iLine;
key g_kLineID;
string CARD = ".meshthemes";
key g_kCard;
string g_sReadingTheme;
list g_lThemes;
key g_kDialog;

integer g_bCollarHidden;
list g_lGlows;

ApplyFace(string sRule) {
    list lParts = llParseStringKeepNulls(sRule, ["|"], []);
    integer iFace = llList2Integer(lParts, 0);
    string sTex = llList2String(lParts, 1);
    vector vColor = (vector)llList2String(lParts, 2);
    float fAlpha = llList2Float(lParts, 3);

    // See http://wiki.secondlife.com/wiki/LlSetPrimitiveParams#PRIM_BUMP_SHINY for shine/bump values
    integer iShine = llList2Integer(lParts, 4);
    integer iBump = llList2Integer(lParts, 5);
    float fGlow = llList2Float(lParts, 6);

    llSetLinkPrimitiveParamsFast(LINK_ROOT, [
        PRIM_TEXTURE, iFace, sTex, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0,
        PRIM_COLOR, iFace, vColor, fAlpha,
        PRIM_BUMP_SHINY, iFace, iShine, iBump,
        PRIM_GLOW, iFace, fGlow
    ]);
}

ApplyTheme(string sTheme, key kID) {
    integer iIndex = llListFindList(g_lThemes, [sTheme]);
    if (~iIndex) {
        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "Applying the " + sTheme + " theme...", kID);

        list lLines = llParseStringKeepNulls(llList2String(g_lThemes, iIndex + 1), ["\n"], []);
        integer iLength = llGetListLength(lLines);
        integer i;
        for (; i < iLength; i++) {
            ApplyFace(llList2String(lLines, i));
        }
    } else {
        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + "There is no theme named " + sTheme, kID);
    }
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    g_kDialog = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, g_kDialog);
}

ThemeMenu(key kID, integer iAuth) {
    list lButtons = [];
    integer i;
    integer iLength = llGetListLength(g_lThemes);
    for (; i < iLength; i += 2) {
        lButtons += llList2String(g_lThemes, i);
    }
    Dialog(kID, "\n[Themes]\n\nChoose a theme:", lButtons, ["BACK"], 0, iAuth);
}

HideShow(string sCommand) {
    // Get currently shown state
    integer bCurrentlyShown;
    if (sCommand == "show") {
        bCurrentlyShown = TRUE;
    } else if (sCommand == "hide") {
        bCurrentlyShown = FALSE;
    } else if (sCommand == "stealth") {
        bCurrentlyShown = g_bCollarHidden;
    }

    g_bCollarHidden = !bCurrentlyShown; // Toggle whole collar visibility

    // Do the actual hiding and re/de-glowing of elements
    integer iLinkCount = llGetNumberOfPrims() + 1;
    while (iLinkCount-- > 1) {
        // Don't change things if collar is set hidden, unless we're doing the hiding now
        llSetLinkAlpha(iLinkCount, (float)(bCurrentlyShown), ALL_SIDES);
        // Update glow settings for this link
        integer iGlowsIndex = llListFindList(g_lGlows, [iLinkCount]);
        if (bCurrentlyShown){ // Restore glow if it is now shown
            if (~iGlowsIndex) { // If it had a glow, restore it, otherwise don't
                float fGlow = (float)llList2String(g_lGlows, iGlowsIndex + 1);
                llSetLinkPrimitiveParamsFast(iLinkCount, [
                    PRIM_GLOW, ALL_SIDES, fGlow
                ]);
            }
        } else { // Save glow and switch it off if it is now hidden
            float fGlow = llList2Float(llGetLinkPrimitiveParams(iLinkCount, [PRIM_GLOW, 0]), 0);
            if (fGlow > 0) { // If it glows, store glow
                if (~iGlowsIndex) {
                    g_lGlows = llListReplaceList(g_lGlows, [fGlow], iGlowsIndex + 1, iGlowsIndex + 1);
                } else {
                    g_lGlows += [iLinkCount, fGlow];
                }
            } else if (~iGlowsIndex) {
                g_lGlows = llDeleteSubList(g_lGlows, iGlowsIndex, iGlowsIndex + 1); // Remove glow from list
            }

            llSetLinkPrimitiveParamsFast(iLinkCount, [
                PRIM_GLOW, ALL_SIDES, 0.0
            ]); // Set no glow;
        }
    }
}

default
{
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_OWNER || iNum == CMD_WEARER) {
            list lParams = llParseString2List(sStr, [" "], []);
            string sCommand = llToLower(llList2String(lParams, 0));
            if (sCommand == "theme") {
                ApplyTheme(llList2String(lParams, 1), kID);
            } else if (sStr == "menu Themes") {
                ThemeMenu(kID, iNum);
            } else if (sCommand == "hide" || sCommand == "show" || sCommand == "stealth") {
                HideShow(sCommand);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
        } else if (iNum == DIALOG_RESPONSE && kID == g_kDialog) {
            list lParts = llParseString2List(sStr, ["|"], []);
            key kAv = llList2Key(lParts, 0);
            string sButton = llList2String(lParts, 1);
            integer iAuth = llList2Integer(lParts, 3);
            if (sButton == "BACK") {
                llMessageLinked(LINK_THIS, iAuth, "menu Settings", kAv);
            } else {
                ApplyTheme(sButton, kAv);
                ThemeMenu(kAv, iAuth);
            }
        }
    }

    state_entry() {
        if (llGetInventoryType(CARD) == INVENTORY_NOTECARD) {
            g_kCard = llGetInventoryKey(CARD);
            g_iLine = 0;
            g_kLineID = llGetNotecardLine(CARD, g_iLine);
        } else {
            // There's no .meshthemes card.  We don't belong here.
            llRemoveInventory(llGetScriptName());
        }
    }

    dataserver(key kID, string sData) {
        if (kID != g_kLineID || sData == EOF) {
            return;
        }

        if (llStringLength(sData)) {
            if (llSubStringIndex(sData, "|") == -1) {
                // No separators in the line.  It's a theme title
                g_sReadingTheme = sData;
            } else {
                // It's a face line.  add it to our list
                integer iIndex = llListFindList(g_lThemes, [g_sReadingTheme]);
                if (iIndex == -1) {
                    g_lThemes += [g_sReadingTheme, sData];
                } else {
                    g_lThemes = llListReplaceList(g_lThemes, [llList2String(g_lThemes, iIndex + 1) + "\n" + sData], iIndex + 1, iIndex + 1);
                }
            }
        }
        g_iLine++;
        g_kLineID = llGetNotecardLine(CARD, g_iLine);
    }

    changed(integer iChange) {
        if (llGetInventoryType(CARD) == INVENTORY_NOTECARD) {
            if (llGetInventoryKey(CARD) != g_kCard) {
                llResetScript();
            }
        }
    }
}
