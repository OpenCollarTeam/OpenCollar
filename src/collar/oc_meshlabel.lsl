// This file is part of OpenCollar.
// Copyright (c) 2006 - 2016 Xylor Baysklef, Kermitt Quirk,
// Thraxis Epsilon, Gigs Taggart, Strife Onizuka, Huney Jewell,
// Salahzar Stenvaag, Lulu Pink, Nandana Singh, Cleo Collins, Satomi Ahn,
// Joy Stipe, Wendy Starfall, Romka Swallowtail, littlemousy,
// Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.


string g_sAppVersion = "¹⋅¹";

string g_sParentMenu = "Apps";
string g_sSubMenu = "Label";

key g_kWearer;

// MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;

integer REBOOT = -1000;

integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
//integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer g_iCharLimit = -1;

string UPMENU = "BACK";

string g_sTextMenu = "Set Label";
string g_sFontMenu = "Font";
string g_sColorMenu = "Color";

list g_lMenuIDs; // Three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

string g_sCharmap = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~¡¢£¤¥¦§¨©ª«¬®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿĀāĂăĄąĆćĈĉĊċČčĎďĐđĒēĔĕĖėĘęĚěĜĝĞğĠġĢģĤĥĦħĨĩĪīĬĭĮįİıĲĳĴĵĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏŐőŒœŔŕŖŗŘřŚśŜŝŞşŠšŢţŤťŦŧŨũŪūŬŭŮůŰűŲųŴŵŶŷŸŹźŻżŽžſƒƠơƯưǰǺǻǼǽǾǿȘșʼˆˇˉ˘˙˚˛˜˝˳̣̀́̃̉̏΄΅Ά·ΈΉΊΌΎΏΐΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩΪΫάέήίΰαβγδεζηθικλμνξοπρςστυφχψωϊϋόύώϑϒϖЀЁЂЃЄЅІЇЈЉЊЋЌЍЎЏАБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяѐёђѓєѕіїјљњћќѝўџѠѡѢѣѤѥѦѧѨѩѪѫѬѭѮѯѰѱѲѳѴѵѶѷѸѹѺѻѼѽѾѿҀҁ҂҃҄҅҆҈҉ҊҋҌҍҎҏҐґҒғҔҕҖҗҘҙҚқҜҝҞҟҠҡҢңҤҥҦҧҨҩҪҫҬҭҮүҰұҲҳҴҵҶҷҸҹҺһҼҽҾҿӀӁӂӃӄӅӆӇӈӉӊӋӌӍӎӏӐӑӒӓӔӕӖӗӘәӚӛӜӝӞӟӠӡӢӣӤӥӦӧӨөӪӫӬӭӮӯӰӱӲӳӴӵӶӷӸӹӺӻӼӽӾӿԀԁԂԃԄԅԆԇԈԉԊԋԌԍԎԏԐԑԒԓḀḁḾḿẀẁẂẃẄẅẠạẢảẤấẦầẨẩẪẫẬậẮắẰằẲẳẴẵẶặẸẹẺẻẼẽẾếỀềỂểỄễỆệỈỉỊịỌọỎỏỐốỒồỔổỖỗỘộỚớỜờỞởỠỡỢợỤụỦủỨứỪừỬửỮữỰựỲỳỴỵỶỷỸỹὍ–—―‗‘’‚‛“”„†‡•…‰′″‹›‼⁄ⁿ₣₤₧₫€℅ℓ№™Ω℮⅛⅜⅝⅞∂∆∏∑−√∞∫≈≠≤≥◊ﬁﬂﬃﬄ  ";

list g_lFonts = [
    "Solid", "91b730bc-b763-52d4-d091-260eddda3198",
    "Outlined", "c1481c75-15ea-9d63-f6cf-9abb6db87039"
];

key g_kFontTexture = "91b730bc-b763-52d4-d091-260eddda3198";

integer g_iX = 45;
integer g_iY = 19;

integer g_iFaces = 6;

float g_fScrollTime = 0.3;
integer g_iScrollPos;
string g_sScrollText;
list g_lLabelLinks;
list g_lLabelBaseElements;
list g_lGlows;

integer g_bScroll = FALSE;
integer g_bShow;
vector g_vColor = <1.0, 1.0, 1.0>;
integer g_iHide;

string g_sLabelText = "";
string g_sSettingToken = "label_";
//string g_sGlobalToken = "global_";

float g_fUReps;
float g_fVReps;

/*
integer g_bProfiled;
Debug(string sStr) {
    // If you delete the first // from the preceeding and following  lines,
    // profiling is off, debug is off, and the compiler will remind you to
    // remove the debug calls from the code, we're back to production mode
    if (!g_bProfiled) {
        g_bProfiled = TRUE;
        llScriptProfiler(TRUE);
    }
    llOwnerSay(llGetScriptName() + "(min free:" + (string)(llGetMemoryLimit() - llGetSPMaxMemory()) + ")[" + (string)llGetFreeMemory() + "] :\n" + sStr);
}
*/

integer GetIndex(string sChar) {
    integer i;
    if (sChar == "") {
        return 854;
    } else {
        i = llSubStringIndex(g_sCharmap, sChar);
    }

    if (i >= 0) {
        return i;
    } else {
        return 854;
    }
}

RenderString(integer iPos, string sChar) {  // iPos - position of character on label
    integer iFrame = GetIndex(sChar);  // no of character in table
    integer i = iPos / g_iFaces;
    integer iLink = llList2Integer(g_lLabelLinks, i);
    integer iFace = iPos - g_iFaces * i;
    integer iFrameY = iFrame / g_iX;
    integer iFrameX = iFrame - g_iX * iFrameY;
    float fUOffset = -0.5 + (g_fUReps / 2 + g_fUReps * iFrameX);
    float fVOffset = 0.5 - (g_fVReps / 2 + g_fVReps * iFrameY);
    llSetLinkPrimitiveParamsFast(iLink, [
        PRIM_TEXTURE, iFace, g_kFontTexture, <g_fUReps, g_fVReps, 0.0>, <fUOffset, fVOffset, 0.0>, 0.0
    ]);
}

SetColor() {
    integer i = 0;
    do {
        integer iLink = llList2Integer(g_lLabelLinks, i);
        float fAlpha = llList2Float(llGetLinkPrimitiveParams(iLink, [PRIM_COLOR, ALL_SIDES]), 1);
        llSetLinkPrimitiveParamsFast(iLink, [
            PRIM_COLOR, ALL_SIDES, g_vColor, fAlpha
        ]);
    } while (++i < llGetListLength(g_lLabelLinks));
}

// Find all 'Label' prims, count and store it's link numbers for fast work SetLabel() and timer
integer LabelsCount() {
    integer bOk = TRUE;
    g_lLabelLinks = [] ;
    g_lLabelBaseElements = [];

    string sLabel;
    list lTmp;
    integer iLink;
    integer iLinkCount = llGetNumberOfPrims();

    // Find all 'Label' prims and count it's
    for (iLink = 2; iLink <= iLinkCount; iLink++) {
        lTmp = llParseString2List(llList2String(llGetLinkPrimitiveParams(iLink, [PRIM_NAME]), 0), ["~"], []);
        sLabel = llList2String(lTmp, 0);
        if (sLabel == "MeshLabel") {
            g_lLabelLinks += 0; // Fill list witn nulls
            // Change prim description
            llSetLinkPrimitiveParamsFast(iLink, [
                PRIM_DESC,"Label~notexture~nocolor~nohide~noshiny"
            ]);
        } else if (sLabel == "LabelBase") {
            g_lLabelBaseElements += iLink;
        }
    }

    g_iCharLimit = llGetListLength(g_lLabelLinks) * 6;
    // Find all 'Label' prims and store it's links to list
    for (iLink = 2; iLink <= iLinkCount; iLink++) {
        lTmp = llParseString2List(llList2String(llGetLinkPrimitiveParams(iLink, [PRIM_NAME]), 0), ["~"], []);
        sLabel = llList2String(lTmp, 0);
        if (sLabel == "MeshLabel") {
            integer iLabel = (integer)llList2String(lTmp, 1);
            integer iLabelLink = llList2Integer(g_lLabelLinks, iLabel);
            if (iLabelLink == 0) {
                g_lLabelLinks = llListReplaceList(g_lLabelLinks, [iLink], iLabel, iLabel);
            } else {
                bOk = FALSE;
                llOwnerSay("Warning! Found duplicated label prims: " + sLabel + " with link numbers: " + (string)iLabelLink + " and " + (string)iLink);
            }
        }
    }

    if (!bOk) {
        if (~llSubStringIndex(llGetObjectName(), "Installer") && ~llSubStringIndex(llGetObjectName(), "Updater")) {
            return 1;
        }
    }

    return bOk;
}

SetLabelBaseAlpha() {
    if (g_iHide) {
        return;
    }

    // Loop through stored links, setting color if element type is bell
    integer i;
    integer iLinkElements = llGetListLength(g_lLabelBaseElements);
    for (i = 0; i < iLinkElements; i++) {
        llSetLinkAlpha(llList2Integer(g_lLabelBaseElements, i), (float)g_bShow, ALL_SIDES);
        UpdateGlow(llList2Integer(g_lLabelBaseElements, i), g_bShow);
    }
}

UpdateGlow(integer iLink, integer iAlpha) {
    integer iIndex;
    if (iAlpha == 0) {
        float fGlow = llList2Float(llGetLinkPrimitiveParams(iLink, [PRIM_GLOW, 0]), 0);
        iIndex = llListFindList(g_lGlows, [iLink]);
        if (~iIndex) {
            if (fGlow > 0) {
                g_lGlows = llListReplaceList(g_lGlows, [fGlow], iIndex + 1, iIndex + 1);
            } else {
                g_lGlows = llDeleteSubList(g_lGlows, iIndex, iIndex + 1);
            }
        } else {
            if (fGlow > 0) {
                g_lGlows += [iLink, fGlow];
            }
        }

        llSetLinkPrimitiveParamsFast(iLink, [
            PRIM_GLOW, ALL_SIDES, 0.0
        ]); // Set no glow;
    } else {
        iIndex = llListFindList(g_lGlows, [iLink]);
        if (~iIndex) {
            llSetLinkPrimitiveParamsFast(iLink, [
                PRIM_GLOW, ALL_SIDES, llList2Float(g_lGlows, iIndex + 1)
            ]);
        }
    }
}

SetLabel() {
    string sText;
    if (g_bShow) {
        sText = g_sLabelText;
    }

    string sPadding;
    if(g_bScroll) {
        while (llStringLength(sPadding) < g_iCharLimit) {
            sPadding += " ";
        }
        g_sScrollText = sPadding + sText;
        llSetTimerEvent(g_fScrollTime);
    } else {
        g_sScrollText = "";
        llSetTimerEvent(0);
        // Inlined single use CenterJustify function
        while (llStringLength(sPadding + sText + sPadding) < g_iCharLimit) {
            sPadding += " ";
        }
        sText = sPadding + sText;
        integer iCharPosition;
        for (; iCharPosition < g_iCharLimit; iCharPosition++) {
            RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition));
        }
    }
}

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    } else {
        g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
    }
}

string Checkbox(integer iValue, string sLabel) {
    if (iValue) return "☑ " + sLabel;
    else return "☐ " + sLabel;
}

MainMenu(key kID, integer iAuth) {
    list lButtons = [
        g_sTextMenu,
        g_sColorMenu,
        g_sFontMenu,

        Checkbox(g_bShow, "Show"),
        Checkbox(g_bScroll, "Scroll")
    ];

    string sPrompt = "\n[Label]\t" + g_sAppVersion + "\n\nCustomize the %DEVICETYPE%'s label!";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "main");
}

TextMenu(key kID, integer iAuth) {
    string sPrompt = "\n- Submit the new label in the field below.\n- Submit a few spaces to clear the label.\n- Submit a blank field to go back to " + g_sSubMenu + ".";
    Dialog(kID, sPrompt, [], [], 0, iAuth, "textbox");
}

ColorMenu(key kID, integer iAuth) {
    string sPrompt = "\n\nSelect a color from the list";
    Dialog(kID, sPrompt, ["colormenu please"], [UPMENU], 0, iAuth, "color");
}

FontMenu(key kID, integer iAuth) {
    list lButtons = llList2ListStrided(g_lFonts, 0, -1, 2);
    string sPrompt = "\n[Label]\n\nSelect the font for the %DEVICETYPE%'s label.";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "font");
}

ConfirmDeleteMenu(key kAv, integer iAuth) {
    string sPrompt = "\nDo you really want to uninstall the " + g_sSubMenu  +" App?";
    Dialog(kAv, sPrompt, ["Yes", "No", "Cancel"], [], 0, iAuth, "rmlabel");
}

UserCommand(integer iAuth, string sStr, key kAv) {
    //Debug("Command: " + sStr);
    string sLowerStr = llToLower(sStr);
    if (sStr == "rm label") {
        if (kAv != g_kWearer && iAuth != CMD_OWNER) {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kAv);
        } else {
            ConfirmDeleteMenu(kAv, iAuth);
        }
    } else if (iAuth == CMD_OWNER) {
        if (sLowerStr == "menu label" || sLowerStr == "label") {
            MainMenu(kAv, iAuth);
            return;
        }

        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llToLower(llList2String(lParams, 0));
        string sAction = llToLower(llList2String(lParams, 1));
        string sValue = llToLower(llList2String(lParams, 2));

        if (sCommand == "label") {
            if (sAction == "font") {
                string sFont = llDumpList2String(llDeleteSubList(lParams, 0, 1), " ");
                integer iIndex = llListFindList(g_lFonts, [sFont]);
                if (iIndex != -1) {
                    g_kFontTexture = (key)llList2String(g_lFonts, iIndex + 1);
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "font=" + (string)g_kFontTexture, "");
                } else {
                    FontMenu(kAv, iAuth);
                }
            } else if (sAction == "color") {
                string sColor = llDumpList2String(llDeleteSubList(lParams, 0, 1), " ");
                if (sColor != "") {
                    g_vColor = (vector)sColor;
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "color=" + (string)g_vColor, "");
                    SetColor();
                } else {
                    ColorMenu(kAv, iAuth);
                }
            } else if (sAction == "on" && sValue == "") {
                g_bShow = TRUE;
                SetLabelBaseAlpha();
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "show=" + (string)g_bShow, "");
            } else if (sAction == "off" && sValue == "") {
                g_bShow = FALSE;
                SetLabelBaseAlpha();
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "show=" + (string)g_bShow, "");
            } else if (sAction == "scroll") {
                if (sValue == "on") {
                    g_bScroll = TRUE;
                } else if (sValue == "off") {
                    g_bScroll = FALSE;
                }
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "scroll=" + (string)g_bScroll, "");
            } else {
                g_sLabelText = llStringTrim(llDumpList2String(llDeleteSubList(lParams, 0, 0), " "), STRING_TRIM);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "text=" + g_sLabelText, "");
                if (llStringLength(g_sLabelText) > g_iCharLimit) {
                    string sDisplayText = llGetSubString(g_sLabelText, 0, g_iCharLimit - 1);
                    llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "Unless your set your label to scroll it will be truncted at " + sDisplayText + ".", kAv);
                }
            }

            SetLabel();
        }
    } else if (iAuth >= CMD_TRUSTED && iAuth <= CMD_WEARER) {
        string sCommand = llToLower(llList2String(llParseString2List(sStr, [" "], []), 0));
        if (sLowerStr == "menu label") {
            llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kAv);
        } else if (sCommand == "label") {
            llMessageLinked(LINK_DIALOG, NOTIFY, "0" + "%NOACCESS%", kAv);
        }
    }
}

default {
    state_entry() {
        //llSetMemoryLimit(45056);
        g_kWearer = llGetOwner();
        g_fUReps = (float)1 / g_iX;
        g_fVReps = (float)1 / g_iY;
        LabelsCount();

        if (g_iCharLimit <= 0) {
            llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
            llRemoveInventory(llGetScriptName());
        }
        //SetLabel();
    }

    on_rez(integer iNum) {
        if (g_kWearer != llGetOwner()) {
            g_sLabelText = "";
            SetLabel();
        }
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) {
            UserCommand(iNum, sStr, kID);
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");

            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);

                if (sToken == "text") g_sLabelText = sValue;
                else if (sToken == "font") g_kFontTexture = (key)sValue;
                else if (sToken == "color") g_vColor = (vector)sValue;
                else if (sToken == "show") g_bShow = (integer)sValue;
                else if (sToken == "scroll") g_bScroll = (integer)sValue;
            } else if (sToken == "settings" && sValue == "sent") {
                SetColor();
                SetLabel();
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);

                if (sMenuType == "main") {
                    // Got a menu response meant for us.  pull out values
                    if (sMessage == UPMENU) {
                        llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    } else if (sMessage == g_sTextMenu) {
                        TextMenu(kAv, iAuth);
                    } else if (sMessage == g_sColorMenu) {
                        ColorMenu(kAv, iAuth);
                    } else if (sMessage == g_sFontMenu) {
                        FontMenu(kAv, iAuth);
                    } else if (sMessage == "☐ Show") {
                        UserCommand(iAuth, "label on", kAv);
                        MainMenu(kAv, iAuth);
                    } else if (sMessage == "☑ Show") {
                        UserCommand(iAuth, "label off", kAv);
                        MainMenu(kAv, iAuth);
                    } else if (sMessage == "☐ Scroll") {
                        UserCommand(iAuth, "label scroll on", kAv);
                        MainMenu(kAv, iAuth);
                    } else if (sMessage == "☑ Scroll") {
                        UserCommand(iAuth, "label scroll off", kAv);
                        MainMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "color") {
                    if (sMessage == UPMENU) {
                        MainMenu(kAv, iAuth);
                    } else {
                        UserCommand(iAuth, "label color " + sMessage, kAv);
                        ColorMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "font") {
                    if (sMessage == UPMENU) {
                        MainMenu(kAv, iAuth);
                    } else {
                        UserCommand(iAuth, "label font " + sMessage, kAv);
                        FontMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "textbox") { // TextBox response, extract values
                    if (sMessage != " ") {
                        UserCommand(iAuth, "label " + sMessage, kAv);
                    }

                    UserCommand(iAuth, "menu " + g_sSubMenu, kAv);
                } else if (sMenuType == "rmlabel") {
                    if (sMessage == "Yes") {
                        if (g_sScrollText) {
                            UserCommand(iAuth, "label scroll off", kAv);
                        }

                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1" + g_sSubMenu + " App has been removed.", kAv);
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) {
                            llRemoveInventory(llGetScriptName());
                        }
                    } else {
                        llMessageLinked(LINK_DIALOG, NOTIFY, "0" + g_sSubMenu + " App remains installed.", kAv);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex + 3); // Remove stride from g_lMenuIDs
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
        }
    }

    timer() {
        string sText = llGetSubString(g_sScrollText, g_iScrollPos, -1);
        integer iCharPosition;
        for (; iCharPosition < g_iCharLimit; iCharPosition++) {
            RenderString(iCharPosition, llGetSubString(sText, iCharPosition, iCharPosition));
        }

        g_iScrollPos++;
        if (g_iScrollPos > llStringLength(g_sScrollText)) {
            g_iScrollPos = 0;
        }
    }

    changed(integer iChange) {
        if(iChange & CHANGED_LINK) { // If links changed
            if (LabelsCount()) {
                SetLabel();
            }
        }

        if (iChange & CHANGED_COLOR) {
            integer bNewHide = !(integer)llGetAlpha(ALL_SIDES); // Check alpha
            if (g_iHide != bNewHide) { // Check there's a difference to avoid infinite loop
                g_iHide = bNewHide;
                SetLabelBaseAlpha(); // Update hide elements
            }
        }
    }
}
