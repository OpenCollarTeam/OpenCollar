////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - label                                //
//                                 version 3.958                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// SatomiAhn Initial support for llTextBox. 

string g_sParentMenu = "AddOns";
string g_sSubMenu = "Label";
string g_sFontParent = "Appearance";
string g_sFontMenu = "Font";

key g_kWearer;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "AppearanceLock";

//opencollar MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer g_iCharLimit = 12;

string UPMENU = "BACK";
string CTYPE = "collar";
key g_kDialogID;
key g_kTBoxID;

string g_sLabelText = "OpenCollar";

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
key     TRANSPARENT     = "701917a8-d614-471f-13dd-5f4644e36e3c";
key     null_key        = NULL_KEY;
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
//    "Andale 1", "ccc5a5c9-6324-d8f8-e727-ced142c873da", //
//    "Andale 2", "8e10462f-f7e9-0387-d60b-622fa60aefbc", //not ideally aligned
    "Serif 1", "2c1e3fa3-9bdb-2537-e50d-2deb6f2fa22c",
    "Serif 2", "bf2b6c21-e3d7-877b-15dc-ad666b6c14fe",
    "LCD", "014291dc-7fd5-4587-413a-0d690a991ae1"
        ];

// All displayable characters.  Default to ASCII order.
string g_sCharIndex;
list g_lDecode=[]; // to handle special characters from CP850 page for european countries // SALAHZAR
string g_sScript;

/////////// END GLOBAL VARIABLES ////////////

Debug(string in)
{
    //llOwnerSay(in);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

FontMenu(key kID, integer iAuth)
{
    list lButtons=llList2ListStrided(g_lFonts,0,-1,2);
    string sPrompt = "\n\nSelect the font for the " + CTYPE + "'s label.\n\nNote: This feature requires a design with label prims. If the worn design doesn't have any of those, it is recommended to uninstall LooksLabel with the updater.";

    g_kDialogID=Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

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
ShowChars(integer link,vector grkID_offset)
{
    // SALAHZAR modified .1 to .05 to handle different sized texture
    llSetLinkPrimitiveParamsFast( link,[
        PRIM_TEXTURE, FACE, (string)g_kFontTexture, g_vRepeats, grkID_offset - g_vOffset, 0.0
            ]);
}

// SALAHZAR intelligent procedure to extract UTF-8 codes and convert to index in our "cp850"-like table
integer GetIndex(string sChar)
{
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


RenderString(integer iLink, string sStr)
{
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

GetLabelPrim(string sData)
{
    string sLabel;
    list lTmp;
    integer i;
    integer iLinkCount = llGetNumberOfPrims();
    for(i=2; i <= iLinkCount; i++)
    {
        sLabel = (string)llGetObjectDetails(llGetLinkKey(i), [OBJECT_NAME]);
        lTmp = llParseString2List(sLabel, ["~"],[]);
        sLabel = llList2String(lTmp,0);
        if(sLabel == "Label")
        {
            integer iCharPosition = (integer)llList2String(lTmp,1);
            RenderString(i, llGetSubString(sData, iCharPosition, iCharPosition));
        }
    }
}

string CenterJustify(string sIn, integer iCellSize)
{
    string sPadding;
    while(llStringLength(sPadding + sIn + sPadding) < iCellSize)
    {
        sPadding += " ";
    }
    return sPadding + sIn;
}

SetLabel(string sText)
{
    sText = CenterJustify(sText, g_iCharLimit);
    GetLabelPrim(sText);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

SetOffsets(key font)
{
    integer i = 2;
    for (; i < llGetNumberOfPrims(); i++)
    {
        // Compensate for label box-prims, which must use face 0. Others can be added as needed.
        list params = llGetLinkPrimitiveParams(i, [PRIM_DESC, PRIM_TYPE]);
        string desc = llGetSubString(llList2String(params, 0), 0, 4);
        if (desc == "Label")
        {
            integer t = (integer)llList2String(params, 1);
            if (t == PRIM_TYPE_BOX)
            {
                if (font == NULL_KEY) font = "bf2b6c21-e3d7-877b-15dc-ad666b6c14fe"; // LCD default for box
                g_vGridOffset = <-0.45, 0.425, 0.0>;
                g_vRepeats = <0.126, 0.097, 0>;
                g_vOffset = <0.036, 0.028, 0>;
                FACE = 0;
            }
            else if (t == PRIM_TYPE_CYLINDER)
            {
                if (font == NULL_KEY) font = "2c1e3fa3-9bdb-2537-e50d-2deb6f2fa22c"; // Serif default for cyl
                g_vGridOffset = <-0.725, 0.425, 0.0>;
                g_vRepeats = <1.434, 0.05, 0>;
                g_vOffset = <0.037, 0.003, 0>;
                FACE = 1;
            }
            integer o = llListFindList(g_lFonts, [(string)g_kFontTexture]);
            integer n = llListFindList(g_lFonts, [(string)font]);
            if (~o && o != n) // changing fonts - adjust for differences in font offsets
            {
                if (n < 8 && o == 9) g_vOffset.y += 0.0015;
                else if (o < 8 && n == 9) g_vOffset.y -= 0.0015;
            }
            Debug("Offset = " + (string)g_vOffset);
            i = llGetNumberOfPrims(); // quick & dirty break from loop
        }
    }
    g_kFontTexture = font;
}


integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum == COMMAND_OWNER)
    {
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llList2String(lParams, 0);

        if (sStr == "menu " + g_sSubMenu)
        {
            g_kTBoxID = Dialog(kID, "\n- Submit the new label in the field below.\n- Submit a few spaces to clear the label.\n- Submit a blank field to go back to "
 + g_sParentMenu + ".", [], [], 0, iNum);
        }
        else if (sStr == "menu " + g_sFontMenu)
        {
            //give font selection menu
            FontMenu(kID, iNum);
        }

        if (llGetSubString(sStr,0,13) == "lockappearance")
        {
            if(llGetSubString(sStr, -1, -1) == "0")
            {
                g_iAppLock  = FALSE;
            }
            else
            {
                g_iAppLock  = TRUE;
            }
        }
        else if (sCommand == "label")
        {
            if (g_iAppLock)
            {
                Notify(kID,"The appearance of the " + CTYPE + " is locked. You cannot access this menu now!", FALSE);
            }
            else
            {
                lParams = llDeleteSubList(lParams, 0, 0);
                g_sLabelText = llDumpList2String(lParams, " ");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "Text=" + g_sLabelText, "");
                SetLabel(g_sLabelText);
            }
        }
        else if (sCommand == "font")
        {
            if (g_iAppLock)
            {
                Notify(kID,"The appearance of the " + CTYPE + " is locked. You cannot access this menu now!", FALSE);
            }
            else FontMenu(kID, iNum);
        }
        return TRUE;
    }
    if ((iNum >= COMMAND_SECOWNER) && (iNum <= COMMAND_WEARER))
    {
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llList2String(lParams, 0);
        if (sCommand == "label") {} // do nothing here
        else if (sStr == "menu " + g_sSubMenu)
        {
            llMessageLinked(LINK_SET, iNum, "menu "+g_sParentMenu, kID);
        }
        else if (sStr == "menu " + g_sFontMenu)
        {
            llMessageLinked(LINK_SET, iNum, "menu "+g_sFontParent, kID);
        }
        else return TRUE;
        Notify(kID,"Only owners can change the label!", FALSE);
        return TRUE;
    }
    
    return FALSE ;
}

default
{
    state_entry()
    {   // Initialize the character index.
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        ResetCharIndex();
        SetOffsets(NULL_KEY);
        g_sLabelText = llList2String(llParseString2List(llKey2Name(llGetOwner()), [" "], []), 0);
        //no more needed
        //llSleep(1.0);
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sFontParent + "|" + g_sFontMenu, "");
    }

    on_rez(integer iNum)
    {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if ( UserCommand(iNum, sStr, kID) ) {}        
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "Text") g_sLabelText = sValue;
                else if (sToken == "Font") SetOffsets((key)sValue);
            }
            else if (sToken == g_sAppLockToken)
            {
                g_iAppLock = (integer)sValue;
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (sToken == "settings")
            {
                if (sValue == "sent")
                {
                    SetLabel(g_sLabelText);
                }
            }
        }
        else if (iNum == MENUNAME_REQUEST)
        {
            if (sStr == g_sParentMenu)
            {
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            }
            else if (sStr == g_sFontParent)
            {
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sFontParent + "|" + g_sFontMenu, "");
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID==g_kDialogID)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sFontParent, kAv);
                }
                else
                {
                    //we've got the name of a font. look up the texture id, and re-set label
                    integer iIndex = llListFindList(g_lFonts, [sMessage]);
                    if (iIndex != -1)
                    {
                        SetOffsets((key)llList2String(g_lFonts, iIndex + 1));
                        SetLabel(g_sLabelText);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "Font=" + (string)g_kFontTexture, "");
                    }
                    FontMenu(kAv, iAuth);
                }
            }
            else if (kID == g_kTBoxID) // TextBox response, extract values
            {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if(sMessage != "" )UserCommand(iAuth, "label " + sMessage, kAv);
                llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
            }
        }
    }
}
