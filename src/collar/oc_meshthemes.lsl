// This file is part of OpenCollar.
// Copyright (c) 2017 Nirea Resident
// Licensed under the GPLv2.  See LICENSE for full details. 

// change here for OS and IW grids
// Do not change anything below here

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
// integer DIALOG_TIMEOUT      = -9002;

integer NOTIFY = 1002;


integer g_iLine;
key g_kLineID;
string CARD = ".meshthemes";
key g_kCard;
string g_sReadingTheme;
list g_lThemes;
key g_kDialog;

integer g_iCollarHidden;
list g_lGlows;

ApplyFace(string sRule) {
    list lParts = llParseStringKeepNulls(sRule, ["|"], []);
    integer face = llList2Integer(lParts, 0);
    string tex = llList2String(lParts, 1);
    vector color = (vector)llList2String(lParts, 2);
    float alpha = llList2Float(lParts, 3);
    
    // See http://wiki.secondlife.com/wiki/LlSetPrimitiveParams#PRIM_BUMP_SHINY for shine/bump values
    integer shine = llList2Integer(lParts, 4); 
    integer bump = llList2Integer(lParts, 5);
    float glow = llList2Float(lParts, 6);
    llSetLinkPrimitiveParamsFast(
        LINK_ROOT,
        [
            PRIM_TEXTURE, face, tex, <1,1,0>, <0,0,0>, 0,
            PRIM_COLOR, face, color, alpha,
            PRIM_BUMP_SHINY, face, shine, bump,
            PRIM_GLOW, face, glow
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

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
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
    Dialog(kID, "\n[Themes]\n\nChoose a theme:", lButtons, ["BACK"], 0, iAuth);
}

HideShow(string sCommand) {
    //get currently shown state
    integer iCurrentlyShown;
    if (sCommand == "show")       iCurrentlyShown = 1;
    else if (sCommand == "hide")  iCurrentlyShown = 0;
    else if (sCommand == "stealth") iCurrentlyShown = g_iCollarHidden;
    g_iCollarHidden = !iCurrentlyShown;  //toggle whole collar visibility

    //do the actual hiding and re/de-glowing of elements
    integer iLinkCount = llGetNumberOfPrims()+1;
    while (iLinkCount-- > 1) {
        //don't change things if collar is set hidden, unless we're doing the hiding now
        llSetLinkAlpha(iLinkCount,(float)(iCurrentlyShown),ALL_SIDES);
        //update glow settings for this link
        integer iGlowsIndex = llListFindList(g_lGlows,[iLinkCount]);
        if (iCurrentlyShown){  //restore glow if it is now shown
            if (~iGlowsIndex) {  //if it had a glow, restore it, otherwise don't
                float fGlow = (float)llList2String(g_lGlows, iGlowsIndex+1);
                llSetLinkPrimitiveParamsFast(iLinkCount, [PRIM_GLOW, ALL_SIDES, fGlow]);
            }
        } else {  //save glow and switch it off if it is now hidden
            float fGlow = llList2Float(llGetLinkPrimitiveParams(iLinkCount,[PRIM_GLOW,0]),0) ;
            if (fGlow > 0) {  //if it glows, store glow
                if (~iGlowsIndex) g_lGlows = llListReplaceList(g_lGlows,[fGlow],iGlowsIndex+1,iGlowsIndex+1) ;
                else g_lGlows += [iLinkCount, fGlow];
            } else if (~iGlowsIndex) g_lGlows = llDeleteSubList(g_lGlows,iGlowsIndex,iGlowsIndex+1); //remove glow from list
            llSetLinkPrimitiveParamsFast(iLinkCount, [PRIM_GLOW, ALL_SIDES, 0.0]);  // set no glow;
        }
    }
}

default
{
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == CMD_OWNER || iNum == CMD_WEARER) {

            list lParams = llParseString2List(sStr, [" "], []);
            string sCommand=llToLower(llList2String(lParams,0));
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
