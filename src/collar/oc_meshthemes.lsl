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

integer LINK_DIALOG         = 3;
integer LINK_UPDATE = -10;

integer DIALOG              = -9000;
integer DIALOG_RESPONSE     = -9001;
integer DIALOG_TIMEOUT      = -9002;

integer NOTIFY = 1002;


list g_lMenuIDs;  //menu information
integer g_iMenuStride=3;

integer g_iLine;
key g_kLineID;
string CARD = ".meshthemes";
key g_kCard;
string g_sReadingTheme;
list g_lThemes;
key g_kDialog;

ApplyFace(string sRule) {
    list lParts = llParseStringKeepNulls(sRule, ["|"], []);
    integer face = llList2Integer(lParts, 0);
    string tex = llList2String(lParts, 1);
    vector color = (vector)llList2String(lParts, 2);
    float alpha = llList2Float(lParts, 3);
    
    // See http://wiki.secondlife.com/wiki/LlSetPrimitiveParams#PRIM_BUMP_SHINY for shine/bump values
    integer shine = llList2Integer(lParts, 4); 
    integer bump = llList2Integer(lParts, 5);
    llSetLinkPrimitiveParamsFast(
        LINK_ROOT,
        [
            PRIM_TEXTURE, face, tex, <1,1,0>, <0,0,0>, 0,
            PRIM_COLOR, face, color, alpha,
            PRIM_BUMP_SHINY, face, shine, bump
        ]
    );
}

ApplyTheme(string sTheme, key kID) {
    integer idx = llListFindList(g_lThemes, [sTheme]);
    if (~idx) {
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"Applying the "+sTheme+" theme...",kID);
        
        list lLines = llParseStringKeepNulls(llList2String(g_lThemes, idx + 1), ["\n"], []);
        integer stop = llGetListLength(lLines);
        integer n;
        for (n = 0; n < stop; n++) {
            ApplyFace(llList2String(lLines, n));
        }
    } else {
        llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"There is no theme named " + sTheme,kID);
    }
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    g_kDialog = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, g_kDialog);
}

ThemeMenu(key kID, integer iAuth) {
    list lButtons = [];
    integer n;
    integer stop = llGetListLength(g_lThemes);
    for (n = 0; n < stop; n+=2) {
        lButtons += [llList2String(g_lThemes, n)];
    }
    Dialog(kID, "\n[Themes]\n\nChoose a theme:", lButtons, ["BACK"], 0, iAuth, "ThemeMenu~themes");
}

default
{
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_OWNER || iNum == CMD_WEARER) {
            if (llSubStringIndex(sStr, "theme ") == 0) {
                string sTheme = llGetSubString(sStr, 6, llStringLength(sStr));
                ApplyTheme(sTheme, kID);
            } else if (sStr == "menu Themes") {
                ThemeMenu(kID, iNum);
            }
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
        } else if (iNum == DIALOG_RESPONSE && kID == g_kDialog) {
            list lParts = llParseString2List(sStr, ["|"], []);
            key av = llList2Key(lParts, 0);
            string button = llList2String(lParts, 1);
            integer auth = llList2Integer(lParts, 3);
            if (button == "BACK") {
                llMessageLinked(LINK_THIS, auth, "menu Settings", av);
            } else {
                ApplyTheme(button, av);
                ThemeMenu(av, auth);
            }
        }
    }
    
    state_entry() {
        if (llGetInventoryType(CARD) == INVENTORY_NOTECARD) {
            g_kCard = llGetInventoryKey(CARD);
            g_iLine = 0;
            g_kLineID = llGetNotecardLine(CARD, g_iLine);            
        } else {
            // there's no .meshthemes card.  We don't belong here.
            llRemoveInventory(llGetScriptName());
        }

    }
    
    dataserver(key kID, string sData) {
        if (kID != g_kLineID) return;
        if (sData == EOF) return;
        
        if (llStringLength(sData)) {
            if (llSubStringIndex(sData, "|") == -1) {
                // no separators in the line.  It's a theme title
                g_sReadingTheme = sData;
            } else {
                // it's a face line.  add it to our list
                integer idx = llListFindList(g_lThemes, [g_sReadingTheme]);
                if (idx == -1) {
                    g_lThemes += [g_sReadingTheme, sData];
                } else {
                   g_lThemes = llListReplaceList(g_lThemes, [llList2String(g_lThemes, idx + 1) + "\n" + sData], idx + 1, idx + 1);
                }
            }
        }        
        g_iLine++;  
        g_kLineID = llGetNotecardLine(CARD, g_iLine);
    }
    
    changed (integer iChange) {
        if (llGetInventoryType(CARD) == INVENTORY_NOTECARD) {
            if (llGetInventoryKey(CARD) != g_kCard) {
                llResetScript();
            }
        }
    }
}
