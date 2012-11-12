//OpenCollar - label
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
string g_sParentMenu = "AddOns";
string g_sSubMenu = "Label";
string g_sFontParent = "Appearance";
string g_sFontMenu = "Font";

key g_kWearer;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "AppLock";

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

//string UPMENU = "â†‘";
//string MORE = "â†’";
string UPMENU = "^";

key g_kDialogID;

string g_sLabelText = "OpenCollar";
string g_sDesignPrefix;

list g_lDesignRot = ["oc_", <0.0, 0.0, -0.992462, 0.122556>];//strided list of default rotations for label prim 0, by dbprefix
float g_iRotIncrement = 11.75;

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
// only one face needed, for us face 1
integer FACE          = 1;

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
key g_kFontTexture = "bf2b6c21-e3d7-877b-15dc-ad666b6c14fe";//verily serif 40 etched, on white

list g_lFonts = [
    "Andale 1", "ccc5a5c9-6324-d8f8-e727-ced142c873da",
    "Andale 2", "8e10462f-f7e9-0387-d60b-622fa60aefbc",
    "Serif 1", "2c1e3fa3-9bdb-2537-e50d-2deb6f2fa22c",
    "Serif 2", "bf2b6c21-e3d7-877b-15dc-ad666b6c14fe",
    "LCD", "014291dc-7fd5-4587-413a-0d690a991ae1"
        ];

// All displayable characters.  Default to ASCII order.
string g_sCharIndex;
list g_lDecode=[]; // to handle special characters from CP850 page for european countries // SALAHZAR

/////////// END GLOBAL VARIABLES ////////////

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    //key generation
    //just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sOut;
    integer n;
    for (n = 0; n < 8; ++n)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString( "0123456789abcdef", iIndex, iIndex);
    }
    key kID = (sOut + "-0000-0000-0000-000000000000");
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
        + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

FontMenu(key kID, integer iAuth)
{
    list lButtons=llList2ListStrided(g_lFonts,0,-1,2);
    string sPrompt = "Select the font for the collar's label.  (Not all collars have a label that can use this feature.)";

    g_kDialogID=Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

ResetCharIndex() {

    g_sCharIndex  = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`";
    g_sCharIndex += "abcdefghijklmnopqrstuvwxyz{|}~\n\n\n\n\n";

    // special UTF-8 chars for European languages // SALAHZAR special chars according to a selection from CP850
    // these 80 chars correspond to the following chars in CP850 codepage: (some are not viewable in editor)
    // rows(11)="Ã‡Ã¼Ã©Ã¢Ã¤Ã Ã¥Ã§ÃªÃ«"
    // rows(12)="Ã¨Ã¯Ã®Ã¬Ã„Ã…Ã‰Ã¦Ã†â—„"
    // rows(13)="Ã¶Ã²Ã»Ã¹Ã¿Ã–ÃœÂ¢Â£Â¥"
    // rows(14)="â‚§Æ’Ã¡Ã­Ã³ÃºÃ±Ã‘ÂªÂº"
    // rows(15)="Â¿âŒÂ¬Â½Â¼Â¡Â«Â»Î±ÃŸ"
    // rows(16)="Î“Ï€Î£ÏƒÂµÏ„Î¦Î˜Î©Î´"
    // rows(17)="âˆžÏ†Îµâˆ©â‰¡Â±â‰¥â‰¤âŒ âŒ¡"
    // rows(18)="Ã·â‰ˆÂ°âˆ™Â·âˆšâ¿Â²â‚¬ "
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
    //return <-0.45 + 0.1 * iCol, 0.45 - 0.1 * iRow, 0.0>;
    return <-0.725 + 0.1 * iCol, 0.425 - 0.05 * iRow, 0.0>; // SALAHZAR modified vertical offsets for 512x1024 textures    // Lulu modified for cut cylinders
    //     return <-0.725 + 0.1 * iCol, 0.472 - 0.05 * iRow, 0.0>;
}

//ShowChars(integer link,vector grkID_offset1, vector grkID_offset2, vector grkID_offset3, vector grkID_offset4, vector grkID_offset5)
ShowChars(integer link,vector grkID_offset)
{
    // Set the primitive textures directly.

    // <-0.256, 0, 0>
    // <0, 0, 0>
    // <0.130, 0, 0>
    // <0, 0, 0>
    // <-0.74, 0, 0>

    // SALAHZAR modified .1 to .05 to handle different sized texture
    llSetLinkPrimitiveParamsFast( link,[
        PRIM_TEXTURE, FACE, (string)g_kFontTexture, <1.434, 0.05, 0>, grkID_offset - <0.037, 0, 0>, 0.0
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


RenderString(integer iLink, string sStr) {
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

            //rotate label prims depending on num of chars
            integer iIndex = llListFindList(g_lDesignRot, [g_sDesignPrefix]);
            if (iIndex != -1)//only correct for rotation if this design has an entry in g_lDesignRot
            {
                rotation rDefaultLabelRot = llList2Rot(g_lDesignRot, iIndex + 1);
                rotation rOddOffSet = ZERO_ROTATION;

                //offset by half the increment if odd num of chars
                if (!(llStringLength(g_sLabelText) % 2))
                {
                    rOddOffSet = llEuler2Rot(<0, 0, (g_iRotIncrement / 2.0) * DEG_TO_RAD>);
                }

                rotation rRot = rDefaultLabelRot * rOddOffSet * llEuler2Rot(<0, 0, g_iRotIncrement * iCharPosition *
                    DEG_TO_RAD>);
                llSetLinkPrimitiveParamsFast(i, [PRIM_ROTATION, ZERO_ROTATION * rRot / llGetLocalRot()]);
            }
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
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    } else {
            llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
}

default
{
    state_entry()
    {   // Initialize the character index.

        g_kWearer = llGetOwner();

        ResetCharIndex();
        g_sDesignPrefix = llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 2);

        g_sLabelText = llList2String(llParseString2List(llKey2Name(llGetOwner()), [" "], []), 0);
        //SetLabel(g_sLabelText); // do it after all settings are in.
        //no more needed
        llSleep(1.0);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sFontParent + "|" + g_sFontMenu, NULL_KEY);
    }

    on_rez(integer iNum)
    {
        llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == COMMAND_OWNER)
        {
            list lParams = llParseString2List(sStr, [" "], []);
            string sCommand = llList2String(lParams, 0);

            if (sStr == "menu " + g_sSubMenu)
            {
                //popup help on how to set label
                llMessageLinked(LINK_SET, iNum, "menu "+g_sParentMenu, kID);
                llMessageLinked(LINK_SET, POPUP_HELP, "To set the label on the collar, say _PREFIX_label followed by the text you wish to set.\nExample: _PREFIX_label I Rock!", kID);
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
                    Notify(kID,"The appearance of the collar is locked. You cannot access this menu now!", FALSE);
                }
                else
                {
                    lParams = llDeleteSubList(lParams, 0, 0);
                    g_sLabelText = llDumpList2String(lParams, " ");
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "label=" + g_sLabelText, NULL_KEY);
                    SetLabel(g_sLabelText);
                }
            }
            else if (sCommand == "font")
            {
                if (g_iAppLock)
                {
                    Notify(kID,"The appearance of the collar is locked. You cannot access this menu now!", FALSE);
                }
                else
                {
                    //give font selection menu
                    FontMenu(kID, iNum);
                }
            }
            //no more needed
            //else if (sStr == "reset")
            //            {
            //                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "label", NULL_KEY);
            //                llResetScript();
            //            }
            //
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
            else return;
            Notify(kID,"Only owners can change the label!", FALSE);
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "label")
            {
                g_sLabelText = sValue;
                //SetLabel(g_sLabelText); // do it after all settings are in.
                //llInstantMessage(llGetOwner(), "Loaded label " + sValue + " from database.");
            }
            else if (sToken == g_sDesignPrefix + "font")
            {
                g_kFontTexture = (key)sValue;
                //SetLabel(g_sLabelText); // do it after all settings are in.
            }
            else if (sToken == g_sAppLockToken)
            {
                g_iAppLock = (integer)sValue;
            }
            else if (sToken == "settings")
            {
                if (sValue == "sent")
                {
                    SetLabel(g_sLabelText);
                }
            }
        }
        /* //no more needed
            else if (iNum == COMMAND_WEARER && sStr == "reset")
            {
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "label", NULL_KEY);
                llResetScript();
            }
        */
            else if (iNum == MENUNAME_REQUEST)
            {
                if (sStr == g_sParentMenu)
                {
                    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
                }
                else if (sStr == g_sFontParent)
                {
                    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sFontParent + "|" + g_sFontMenu, NULL_KEY);
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
                        g_kFontTexture = (key)llList2String(g_lFonts, iIndex + 1);
                        SetLabel(g_sLabelText);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDesignPrefix + "font=" + (string)g_kFontTexture, NULL_KEY);
                    }
                    FontMenu(kAv, iAuth);
                }
            }
        }
    }

}