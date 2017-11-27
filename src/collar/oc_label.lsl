//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                           Label - 161030.1                               //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2006 - 2016 Xylor Baysklef, Kermitt Quirk,                //
//  Thraxis Epsilon, Gigs Taggart, Strife Onizuka, Huney Jewell,            //
//  Salahzar Stenvaag, Lulu Pink, Nandana Singh, Cleo Collins, Satomi Ahn,  //
//  Joy Stipe, Wendy Starfall, Romka Swallowtail, littlemousy,              //
//  Garvin Twine et al.                                                     //
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
//       github.com/VirtualDisgrace/opencollar/tree/master/src/collar       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

string g_sAppVersion = "¹⋅⁶";

string g_sParentMenu = "Apps";
string g_sSubMenu = "Label";

key g_kWearer;
string g_sSettingToken = "label_";
//string g_sGlobalToken = "global_";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER            = 500;
integer CMD_TRUSTED          = 501;
//integer CMD_GROUP          = 502;
integer CMD_WEARER           = 503;
//integer CMD_EVERYONE       = 504;
//integer CMD_RLV_RELAY      = 507;
//integer CMD_SAFEWORD       = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
//integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
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

list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

//key g_kDialogID;
//key g_kTBoxID;
//key g_kFontID;
//key g_kColorID;

integer g_iScroll = FALSE;
integer g_iShow = FALSE;
vector g_vColor;
integer g_iHide;

string g_sLabelText = "";

float g_iRotIncrement = 11.75;
// defaults for cylinders
vector g_vGridOffset;
vector g_vRepeats;
vector g_vOffset;

////////////////////////////////////////////
// Changed for the OpenColar label, only one face per prim on a cut cylinder,
// HEAVILY reduced to what we need, else functions removed for easier reading
// Lulu Pink 11/2008
//
// XyzzyText v2.1.UTF8 (UTF8-support) by Salahzar Stenvaag
// XyzzyText v2.1 Script (Set Line Color) by Huney Jewell
// XyzzyText v2.0 Script (5 Face, Single Texture)
//
// Heavily Modified by Thraxis Epsilon, Gigs Taggart 5/2007 and Strife Onizuka 8/2007
// Rewrite to allow one-script-per-object operation w/ optional slaves
// Enable prim-label functionality
// Enabled Banking
//
// Modified by Kermitt Quirk 19/01/2006
// To add support for 5 face prim instead of 3
//
// Core XyText Originally Written by Xylor Baysklef
//
//
////////////////////////////////////////////

/////////////// CONSTANTS ///////////////////
// XyText Message Map.
integer DISPLAY_STRING      = 204000;
integer DISPLAY_EXTENDED    = 204001;
integer REMAP_INDICES       = 204002;
integer RESET_INDICES       = 204003;
//integer SET_FADE_OPTIONS    = 204004;
integer SET_FONT_TEXTURE    = 204005;
//integer SET_LINE_COLOR      = 204006;
//integer SET_COLOR           = 204007;
integer RESCAN_LINKSET      = 204008;

// This is an extended character escape sequence.
string  ESCAPE_SEQUENCE = "\\e";

// This is used to get an index for the extended character.
string  EXTENDED_INDEX  = "12345";

// Face numbers.
// only one face needed. -1 lets setup function know that it hasn't run yet
integer FACE          = -1;

// Used to hide the text after a fade-out.
//key     TRANSPARENT     = "701917a8-d614-471f-13dd-5f4644e36e3c";
//key     null_key        = NULL_KEY;
///////////// END CONSTANTS ////////////////

///////////// GLOBAL VARIABLES ///////////////
// This is the key of the font we are displaying.
//key     gFontTexture        = "b2e7394f-5e54-aa12-6e1c-ef327b6bed9e";
// 48 pixel font key     g_kFontTexture        = "f226766c-c5ac-690e-9018-5a37367ae95a";
// 38 pixel font
//key g_kFontTexture= "ac955f98-74bb-290f-7eb6-dca54e5e4491";
//key g_kFontTexture= "e5efeead-c69e-eb81-e7bd-dad2bb787d2b"; // Bitstream Vera Monotype // SALAHZAR

//key g_kFontTexture= "41b57e2d-e60b-01f0-8f23-e109f532d01d"; //oldEnglish Chars
//key g_kFontTexture = "0d3c99c1-5df4-638c-0f51-ed8591ae8b93";  //Bitstream Vera Serif
//key g_kFontTexture = "a37110e0-5a1f-810d-f999-d0b88568adf0";  //Apple Chancery
//key g_kFontTexture = "020f8783-0d0d-88e3-487d-df3e07d068e7"; //Lucida Bright
//key g_kFontTexture = "fa87184c-35ca-5143-fe24-cdf70e427a09"; // monotype Corsiva
//key g_kFontTexture = "34835ebf-b13a-a054-46bc-678d0849025c"; // DejaVu Sans Mono
//key g_kFontTexture = "316b2161-0669-1796-fec2-976526a29efd";//Andale Mono, Etched
//key g_kFontTexture = "f38c6993-d85e-cffb-fce9-7aed87b80c2e";//andale mono etched 45 point
//key g_kFontTexture = "bf2b6c21-e3d7-877b-15dc-ad666b6c14fe";//verily serif 40 etched, on white
key g_kFontTexture = NULL_KEY;
list g_lFonts = [
    "Andale 1", "ccc5a5c9-6324-d8f8-e727-ced142c873da", //
    "Andale 2", "8e10462f-f7e9-0387-d60b-622fa60aefbc", //not ideally aligned
    "Serif 1", "2c1e3fa3-9bdb-2537-e50d-2deb6f2fa22c",
    "Serif 2", "bf2b6c21-e3d7-877b-15dc-ad666b6c14fe",
    "LCD", "014291dc-7fd5-4587-413a-0d690a991ae1"
        ];

// All displayable characters.  Default to ASCII order.
string g_sCharIndex;
list g_lDecode=[]; // to handle special characters from CP850 page for european countries // SALAHZAR
//string g_sScript;

/////////// END GLOBAL VARIABLES ////////////

/*
integer g_iProfiled=1;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

ResetCharIndex() {

    g_sCharIndex  = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`";
    g_sCharIndex += "abcdefghijklmnopqrstuvwxyz{|}~\n\n\n\n\n";

    g_lDecode= [ "%C3%87", "%C3%BC", "%C3%A9", "%C3%A2", "%C3%A4", "%C3%A0", "%C3%A5", "%C3%A7", "%C3%AA", "%C3%AB" ];
    g_lDecode+=[ "%C3%A8", "%C3%AF", "%C3%AE", "%C3%AC", "%C3%84", "%C3%85", "%C3%89", "%C3%A6", "%C3%AE", "xxxxxx" ];
    g_lDecode+=[ "%C3%B6", "%C3%B2", "%C3%BB", "%C3%B9", "%C3%BF", "%C3%96", "%C3%9C", "%C2%A2", "%C2%A3", "%C2%A5" ];
    g_lDecode+=[ "%E2%82%A7", "%C6%92", "%C3%A1", "%C3%AD", "%C3%B3", "%C3%BA", "%C3%B1", "%C3%91", "%C2%AA", "%C2%BA"];
    g_lDecode+=[ "%C2%BF", "%E2%8C%90", "%C2%AC", "%C2%BD", "%C2%BC", "%C2%A1", "%C2%AB", "%C2%BB", "%CE%B1", "%C3%9F" ];
    g_lDecode+=[ "%CE%93", "%CF%80", "%CE%A3", "%CF%83", "%C2%B5", "%CF%84", "%CE%A6", "%CE%98", "%CE%A9", "%CE%B4" ];
    g_lDecode+=[ "%E2%88%9E", "%CF%86", "%CE%B5", "%E2%88%A9", "%E2%89%A1", "%C2%B1", "%E2%89%A5", "%E2%89%A4", "%E2%8C%A0", "%E2%8C%A1" ];
    g_lDecode+=[ "%C3%B7", "%E2%89%88", "%C2%B0", "%E2%88%99", "%C2%B7", "%E2%88%9A", "%E2%81%BF", "%C2%B2", "%E2%82%AC", "" ];

    // END // SALAHZAR

}

vector GetGridOffset(integer iIndex) {
    // Calculate the offset needed to display this character.
    integer iRow = iIndex / 10;
    integer iCol = iIndex % 10;
    // Return the offset in the texture.
    return <g_vGridOffset.x + 0.1 * iCol, g_vGridOffset.y - 0.05 * iRow, g_vGridOffset.z>; // SALAHZAR modified vertical offsets for 512x1024 textures    // Lulu modified for cut cylinders
    //     return <-0.725 + 0.1 * iCol, 0.472 - 0.05 * iRow, 0.0>;
}

//ShowChars(integer link,vector grkID_offset1, vector grkID_offset2, vector grkID_offset3, vector grkID_offset4, vector grkID_offset5)
ShowChars(integer link,vector grkID_offset) {
    // SALAHZAR modified .1 to .05 to handle different sized texture
    float alpha = llList2Float(llGetLinkPrimitiveParams( link,[PRIM_COLOR,FACE]),1);
    llSetLinkPrimitiveParamsFast( link,[
        PRIM_TEXTURE, FACE, (string)g_kFontTexture, g_vRepeats, grkID_offset - g_vOffset, 0.0,
        PRIM_COLOR, FACE, g_vColor, alpha]);
}

// SALAHZAR intelligent procedure to extract UTF-8 codes and convert to index in our "cp850"-like table
integer GetIndex(string sChar) {
    integer  iRet=llSubStringIndex(g_sCharIndex, sChar);
    if(iRet>=0) return iRet;
    // special char do nice trick :)
    string sEscaped=llEscapeURL(sChar);
    integer iFound=llListFindList(g_lDecode, [sEscaped]);
    // Return blank if not found
    if(iFound<0) return 0;
    // return correct index
    return 100+iFound;
}
// END SALAHZAR


RenderString(integer iLink, string sStr) {
    if(iLink <= 0) return; // check for negative and zero linknumber
    // Get the grid positions for each pair of characters.
    vector GridOffset1 = GetGridOffset( GetIndex(llGetSubString(sStr, 0, 0)) ); // SALAHZAR intermediate function
    // Use these grid positions to display the correct textures/offsets.
    //   ShowChars(iLink,GridOffset1, GridOffset2, GridOffset3, GridOffset4, GridOffset5);
    ShowChars(iLink,GridOffset1);
}

integer ConvertIndex(integer iIndex) {
    // This converts from an ASCII based index to our indexing scheme.
    if (iIndex >= 32) // ' ' or higher
        iIndex -= 32;
    else { // index < 32
        // Quick bounds check.
        if (iIndex > 15)
            iIndex = 15;

        iIndex += 94; // extended characters
    }

    return iIndex;
}

/////END XYTEXT FUNCTIONS

// add for text scroll
float g_fScrollTime = 0.2 ;
integer g_iSctollPos ;
string g_sScrollText;
list g_lLabelLinks ;
list g_lLabelBaseElements;
list g_lGlows;

// find all 'Label' prims, count and store it's link numbers for fast work SetLabel() and timer
integer LabelsCount() {
    integer ok = TRUE ;
    g_lLabelLinks = [] ;
    g_lLabelBaseElements = [];
    string sLabel;
    list lTmp;
    integer iLink;
    integer iLinkCount = llGetNumberOfPrims();

    //find all 'Label' prims and count it's
    for(iLink=2; iLink <= iLinkCount; iLink++) {
        sLabel = llList2String(llGetLinkPrimitiveParams(iLink,[PRIM_NAME]),0);
        lTmp = llParseString2List(sLabel, ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if(sLabel == "Label") {
            g_lLabelLinks += [0]; // fill list witn nulls
            //change prim description
            llSetLinkPrimitiveParamsFast(iLink,[PRIM_DESC,"Label~notexture~nocolor~nohide~noshiny"]);
        } else if (sLabel == "LabelBase") g_lLabelBaseElements += iLink;
    }
    g_iCharLimit = llGetListLength(g_lLabelLinks);
    //find all 'Label' prims and store it's links to list
    for(iLink=2; iLink <= iLinkCount; iLink++) {
        sLabel = llList2String(llGetLinkPrimitiveParams(iLink,[PRIM_NAME]),0);
        lTmp = llParseString2List(sLabel, ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if(sLabel == "Label") {
            integer iLabel = (integer)llList2String(lTmp,1);
            integer link = llList2Integer(g_lLabelLinks,iLabel);
            if(link == 0) g_lLabelLinks = llListReplaceList(g_lLabelLinks,[iLink],iLabel,iLabel);
            else {
                ok = FALSE;
                llOwnerSay("Warning! Found duplicated label prims: "+sLabel+" with link numbers: "+(string)link+" and "+(string)iLink);
            }
        }
    }
    return ok;
}

SetLabelBaseAlpha() {
    if (g_iHide) return ;
    //loop through stored links, setting color if element type is bell
    integer n;
    integer iLinkElements = llGetListLength(g_lLabelBaseElements);
    for (n = 0; n < iLinkElements; n++) {
        llSetLinkAlpha(llList2Integer(g_lLabelBaseElements,n), (float)g_iShow, ALL_SIDES);
        UpdateGlow(llList2Integer(g_lLabelBaseElements,n), g_iShow);
    }
}

UpdateGlow(integer iLink, integer iAlpha) {
    if (iAlpha == 0) {
        SavePrimGlow(iLink);
        llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, 0.0]);  // set no glow;
    } else RestorePrimGlow(iLink);
}

SavePrimGlow(integer iLink) {
    float fGlow = llList2Float(llGetLinkPrimitiveParams(iLink,[PRIM_GLOW,0]),0);
    integer i = llListFindList(g_lGlows,[iLink]);
    if (i !=-1 && fGlow > 0) g_lGlows = llListReplaceList(g_lGlows,[fGlow],i+1,i+1);
    if (i !=-1 && fGlow == 0) g_lGlows = llDeleteSubList(g_lGlows,i,i+1);
    if (i == -1 && fGlow > 0) g_lGlows += [iLink, fGlow];
}

RestorePrimGlow(integer iLink) {
    integer i = llListFindList(g_lGlows,[iLink]);
    if (i != -1) llSetLinkPrimitiveParamsFast(iLink, [PRIM_GLOW, ALL_SIDES, llList2Float(g_lGlows, i+1)]);
}

SetLabel() {
    string sText ;
    if (g_iShow) sText = g_sLabelText;

    string sPadding;
    if(g_iScroll==TRUE) {// || llStringLength(g_sLabelText) > g_iCharLimit)
        // add some blanks
        while(llStringLength(sPadding) < g_iCharLimit) sPadding += " ";
        g_sScrollText = sPadding + sText;
        llSetTimerEvent(g_fScrollTime);
    } else {
        g_sScrollText = "";
        llSetTimerEvent(0);
        //inlined single use CenterJustify function
        while(llStringLength(sPadding + sText + sPadding) < g_iCharLimit) sPadding += " ";
        string sText = sPadding + sText;
        integer iCharPosition;
        for(iCharPosition=0; iCharPosition < g_iCharLimit; iCharPosition++)
            RenderString(llList2Integer(g_lLabelLinks, iCharPosition), llGetSubString(sText, iCharPosition, iCharPosition));
    }
    //Debug("Label set.");
}

SetOffsets(key font) {
    // get 1-st link number from list
    integer link = llList2Integer(g_lLabelLinks, 0);
    // Compensate for label box-prims, which must use face 0. Others can be added as needed.
    list params = llGetLinkPrimitiveParams(link, [PRIM_DESC, PRIM_TYPE]);
    string desc = llGetSubString(llList2String(params, 0), 0, 4);
    if (desc == "Label") {
        integer t = (integer)llList2String(params, 1);
        if (t == PRIM_TYPE_BOX) {
            if (font == NULL_KEY) font = "bf2b6c21-e3d7-877b-15dc-ad666b6c14fe"; // LCD default for box
            g_vGridOffset = <-0.45, 0.425, 0.0>;
            g_vRepeats = <0.126, 0.097, 0>;
            g_vOffset = <0.036, 0.028, 0>;
            FACE = 0;
        } else if (t == PRIM_TYPE_CYLINDER) {
            if (font == NULL_KEY) font = "2c1e3fa3-9bdb-2537-e50d-2deb6f2fa22c"; // Serif default for cyl
            g_vGridOffset = <-0.725, 0.425, 0.0>;
            g_vRepeats = <1.434, 0.05, 0>;
            g_vOffset = <0.037, 0.003, 0>;
            FACE = 1;
        }
        integer o = llListFindList(g_lFonts, [(string)g_kFontTexture]);
        integer n = llListFindList(g_lFonts, [(string)font]);
        if (~o && o != n) {// changing fonts - adjust for differences in font offsets
            if (n < 8 && o == 9) g_vOffset.y += 0.0015;
            else if (o < 8 && n == 9) g_vOffset.y -= 0.0015;
        }
        //Debug("Offset = " + (string)g_vOffset);
    }
    g_kFontTexture = font;
}

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    //Debug("Made menu.");
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
}

MainMenu(key kID, integer iAuth) {
    list lButtons= [g_sTextMenu, g_sColorMenu, g_sFontMenu];
    if (g_iShow) lButtons += ["☑ Show"];
    else lButtons += ["☐ Show"];

    if (g_iScroll) lButtons += ["☑ Scroll"];
    else lButtons += ["☐ Scroll"];

    string sPrompt = "\n[http://www.opencollar.at/label.html Label]\t"+g_sAppVersion+"\n\nCustomize the %DEVICETYPE%'s label!";
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth,"main");
}

TextMenu(key kID, integer iAuth) {
    string sPrompt = "\n[http://www.opencollar.at/label.html Label]\n\n- Submit the new label in the field below.\n- Submit a few spaces to clear the label.\n- Submit a blank field to go back to " + g_sSubMenu + ".";
    Dialog(kID, sPrompt, [], [], 0, iAuth,"textbox");
}

ColorMenu(key kID, integer iAuth) {
    string sPrompt = "\n\nSelect a colour from the list";
    Dialog(kID, sPrompt, ["colormenu please"], [UPMENU], 0, iAuth,"color");
}

FontMenu(key kID, integer iAuth) {
    list lButtons=llList2ListStrided(g_lFonts,0,-1,2);
    string sPrompt = "\n[http://www.opencollar.at/label.html Label]\n\nSelect the font for the %DEVICETYPE%'s label.";

    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth,"font");
}

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_label")
        llRemoveInventory(sName);
}

UserCommand(integer iAuth, string sStr, key kAv) {
    string sLowerStr = llToLower(sStr);
    if (sStr == "rm label") {
        if (kAv!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kAv);
        else Dialog(kAv, "\nDo you really want to uninstall the "+g_sSubMenu+" App?", ["Yes","No","Cancel"], [], 0, iAuth,"rmlabel");
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
                lParams = llDeleteSubList(lParams, 0, 1);
                string font = llDumpList2String(lParams, " ");
                integer iIndex = llListFindList(g_lFonts, [font]);
                if (iIndex != -1) {
                    SetOffsets((key)llList2String(g_lFonts, iIndex + 1));
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "font=" + (string)g_kFontTexture, "");
                }
                else FontMenu(kAv, iAuth);
            } else if (sAction == "color") {
                string sColor= llDumpList2String(llDeleteSubList(lParams,0,1)," ");
                if (sColor != "") {
                    g_vColor=(vector)sColor;
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"color="+(string)g_vColor, "");
                }
            } else if (sAction == "on" && sValue == "") {
                g_iShow = TRUE;
                SetLabelBaseAlpha();
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"show="+(string)g_iShow, "");
            } else if (sAction == "off" && sValue == "") {
                g_iShow = FALSE;
                SetLabelBaseAlpha();
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"show="+(string)g_iShow, "");
            } else if (sAction == "scroll") {
                if (sValue == "on") g_iScroll = TRUE;
                else if (sValue == "off") g_iScroll = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"scroll="+(string)g_iScroll, "");
            } else {
                g_sLabelText = llStringTrim(llDumpList2String(llDeleteSubList(lParams,0,0)," "),STRING_TRIM);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken + "text=" + g_sLabelText, "");
                if (llStringLength(g_sLabelText) > g_iCharLimit) {
                    string sDisplayText = llGetSubString(g_sLabelText, 0, g_iCharLimit-1);
                    llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Unless your set your label to scroll it will be truncted at "+sDisplayText+".", kAv);
                }
            }
            SetLabel();
        }
    } else if (iAuth >= CMD_TRUSTED && iAuth <= CMD_WEARER){
        string sCommand = llToLower(llList2String(llParseString2List(sStr, [" "], []), 0));
        if (sStr=="menu "+g_sSubMenu) {
            llMessageLinked(LINK_ROOT, iAuth, "menu "+g_sParentMenu, kAv);
            llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kAv);
        } else if (sCommand=="labeltext" || sCommand == "labelfont" || sCommand == "labelcolor" || sCommand == "labelshow")
            llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"%NOACCESS%", kAv);
    }
}

default
{
    state_entry() {
        g_kWearer = llGetOwner();
        FailSafe();
        //first count the label prims.
        integer ok = LabelsCount();
        SetOffsets(NULL_KEY);
        ResetCharIndex();
        if (g_iCharLimit <= 0) {
            llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
            llRemoveInventory(llGetScriptName());
        }
        g_sLabelText = llList2String(llParseString2List(llKey2Name(g_kWearer), [" "], []), 0);
        SetLabel();
    }

    on_rez(integer iNum) {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sSettingToken) {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "text") g_sLabelText = sValue;
                else if (sToken == "font") SetOffsets((key)sValue);
                else if (sToken == "color") g_vColor = (vector)sValue;
                else if (sToken == "show") g_iShow = (integer)sValue;
                else if (sToken == "scroll") g_iScroll = (integer)sValue;
            }
            else if (sToken == "settings" && sValue == "sent") SetLabel();
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMenuType=="main") {
                    if (sMessage == UPMENU) llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == g_sTextMenu) TextMenu(kAv, iAuth);
                    else if (sMessage == g_sColorMenu) ColorMenu(kAv, iAuth);
                    else if (sMessage == g_sFontMenu) FontMenu(kAv, iAuth);
                    else if (sMessage == "☐ Show") {
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
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else {
                        UserCommand(iAuth, "label color "+sMessage, kAv);
                        ColorMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "font") {
                    if (sMessage == UPMENU) MainMenu(kAv, iAuth);
                    else {
                        UserCommand(iAuth, "label font " + sMessage, kAv);
                        FontMenu(kAv, iAuth);
                    }
                } else if (sMenuType == "textbox") {// TextBox response, extract values
                    if (sMessage != " ") UserCommand(iAuth, "label " + sMessage, kAv);
                    UserCommand(iAuth, "menu " + g_sSubMenu, kAv);
                } else if (sMenuType == "rmlabel") {
                    if (sMessage == "Yes") {
                        if (g_sScrollText) UserCommand(iAuth, "label scroll off", kAv);
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    timer() {
        string sText = llGetSubString(g_sScrollText, g_iSctollPos, -1);
        integer iCharPosition;
        for(iCharPosition=0; iCharPosition < g_iCharLimit; iCharPosition++)
            RenderString(llList2Integer(g_lLabelLinks, iCharPosition), llGetSubString(sText, iCharPosition, iCharPosition));
        g_iSctollPos++;
        if (g_iSctollPos > llStringLength(g_sScrollText)) g_iSctollPos = 0 ;
    }

    changed(integer iChange) {
        if(iChange & CHANGED_LINK) {
            if (LabelsCount()==TRUE) SetLabel();
        }
        if (iChange & CHANGED_COLOR) {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
            if (g_iHide != iNewHide){   //check there's a difference to avoid infinite loop
                g_iHide = iNewHide;
                SetLabelBaseAlpha(); // update hide elements
            }
        }
        if (iChange & CHANGED_INVENTORY) FailSafe();
/*        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }
}
