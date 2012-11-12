//OpenCollar - color
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//color

//on getting color command, give menu to choose which element, followed by menu to pick color

list g_lElements;
string g_sCurrentElement = "";
string g_sCurrentCategory = "";
list g_lCategories = ["Blues", "Browns", "Grays", "Greens", "Purples", "Reds", "Yellows"];

list g_lAllColors = [
"Light Blue|<0.00000, 0.00000, 1.00000>
Dark Blue|<0.00000, 0.00000, 0.62745>
Midnight Blue|<0.08235, 0.10588, 0.32941>
Dark Slate Blue|<0.16863, 0.21961, 0.33725>
Sky Blue|<0.40000, 0.59608, 1.00000>
Light Cyan3|<0.68627, 0.78039, 0.78039>
Cadet Blue3|<0.46667, 0.74902, 0.78039>
Turquoise|<0.26275, 0.77647, 0.85882>
Light Steel Blue2|<0.71765, 0.80784, 0.92549>
Dark Gray Blue|<0.18039, 0.21176, 0.25490>",
"Orange|<1.00000, 0.50196, 0.25098>
Bright Orange|<0.97255, 0.50196, 0.09020>
Dark Orange|<0.76471, 0.33725, 0.09020>
Sienna|<0.97255, 0.45490, 0.19216>
Dark Sienna|<0.76471, 0.34510, 0.09020>
Brown|<0.50196, 0.25098, 0.00000>
Brown Sienna|<0.49412, 0.20784, 0.09020>
Dark Brown|<0.27843, 0.23137, 0.18431>
Sandy Brown|<0.93333, 0.60392, 0.30196>
Dark Drab|<0.33333, 0.30980, 0.21176>",
"Black|<0.00000, 0.00000, 0.00000>
Gray 1|<0.11111, 0.11111, 0.11111>
Gray 2|<0.22222, 0.22222, 0.22222>
Gray 3|<0.33333, 0.33333, 0.33333>
Gray 4|<0.44444, 0.44444, 0.44444>
Gray 5|<0.55556, 0.55556, 0.55556>
Gray 6|<0.66667, 0.66667, 0.66667>
Gray 7|<0.77778, 0.77778, 0.77778>
Gray 8|<0.88889, 0.88889, 0.88889>
White|<1.00000, 1.00000, 1.00000>",
"Pastel Green|<0.73333, 1.00000, 0.51372>
Forest Green|<0.50196, 0.50196, 0.00000>
Light Sea Green|<0.24314, 0.66275, 0.62353>
Medium Sea Green|<0.18824, 0.40392, 0.32941>
Dark Sea Green4|<0.38039, 0.48627, 0.34510>
Dark Green|<0.14510, 0.25490, 0.09020>
Yellow Green|<0.32157, 0.81569, 0.09020>
Olive4|<0.40000, 0.48627, 0.14902>
Chartreuse|<0.54118, 0.98431, 0.09020>
Olive3|<0.62745, 0.77255, 0.26667>",
"Light Purple|<1.00000, 0.00000, 0.50196>
Purple|<0.55686, 0.20784, 0.93725>
Dark Purple|<0.50196, 0.00000, 0.50196>
Plum|<0.72549, 0.23137, 0.56078>
Dark Orchid|<0.27059, 0.14510, 0.27451>
Magenta|<1.00000, 0.00000, 1.00000>
Light Plum|<0.90196, 0.66275, 0.92549>
Pale Violet Red|<0.81961, 0.39608, 0.52941>
Thistle|<0.91373, 0.81176, 0.92549>
Lavender|<0.89020, 0.89412, 0.98039>",
"Burgundy|<0.50196, 0.00000, 0.00000>
Red|<1.00000, 0.00000, 0.00000>
Pink|<0.98039, 0.68627, 0.74510>
Indian Red|<0.89804, 0.32941, 0.31765>
Firebrick|<0.75686, 0.10588, 0.09020>
Hot Pink|<0.96471, 0.37647, 0.67059>
Magenta|<1.00000, 0.00000, 1.00000>
Violet Red|<0.96471, 0.20784, 0.54118>
Pink2|<0.90588, 0.63137, 0.69020>
Dark Red|<0.27843, 0.01569, 0.05490>",
"Yellow|<1.00000, 1.00000, 0.00000>
Bright Yellow|<1.00000, 0.98824, 0.09020>
Pale Khaki|<1.00000, 0.95294, 0.50196>
Goldenrod|<0.92941, 0.85490, 0.45490>
Dark Goldenrod|<0.68627, 0.47059, 0.09020>
Gold|<0.83137, 0.62745, 0.09020>
Dark Gold|<0.91765, 0.75686, 0.09020>
Medium Gold|<0.99216, 0.81569, 0.09020>
Khaki|<0.67843, 0.66275, 0.43137>
Pastel Yellow|<1.00000, 1.00000, 0.44706>"
];

list g_lColorSettings;



string g_sParentMenu = "Appearance";
string g_sSubMenu = "Colors";

string g_sDBToken = "colorsettings";

list g_lColors;
integer g_iStridelength = 2;
integer g_iLength;
list g_lButtons;
list g_lNewButtons;

list g_lMenuIDs;
key g_kTouchID;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "AppLock";

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
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

integer TOUCH_REQUEST = -9500;
integer TOUCH_CANCEL = -9501;
integer TOUCH_RESPONSE = -9502;
integer TOUCH_EXPIRE = -9503;


//5000 block is reserved for IM slaves

string UPMENU = "^";

key g_kWearer;

key ShortKey()
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
    return (key) (sOut + "-0000-0000-0000-000000000000");
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
        + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

key TouchRequest(key kRCPT,  integer iTouchStart, integer iTouchEnd, integer iAuth)
{
    key kID = ShortKey();
    integer iFlags = 0;
    if (iTouchStart) iFlags = iFlags | 0x01;
    if (iTouchEnd) iFlags = iFlags | 0x02;
    llMessageLinked(LINK_SET, TOUCH_REQUEST, (string)kRCPT + "|" + (string)iFlags + "|" + (string)iAuth, kID);
    return kID;
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

CategoryMenu(key kAv, integer iAuth)
{
    //give kAv a dialog with a list of color cards
    string sPrompt = "Pick a Color.";
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lCategories, [UPMENU],0, iAuth)];
}

ColorMenu(key kAv, integer iAuth)
{
    string sPrompt = "Pick a Color.";
    list g_lButtons = llList2ListStrided(g_lColors,0,-1,2);
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lButtons, [UPMENU],0, iAuth)];
}

ElementMenu(key kAv, integer iAuth)
{
    string sPrompt = "Pick which part of the collar you would like to recolor.\n\nChoose *Touch* if you want to select the part by directly clicking on the collar.";
    g_lButtons = llListSort(g_lElements, 1, TRUE);
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lButtons, ["*Touch*", UPMENU],0, iAuth)];
}

string ElementType(integer iLinkNumber)
{
    string sDesc = (string)llGetObjectDetails(llGetLinkKey(iLinkNumber), [OBJECT_DESC]);
    //each prim should have <elementname> in its description, plus "nocolor" or "notexture", if you want the prim to
    //not appear in the color or texture menus
    list lParams = llParseString2List(sDesc, ["~"], []);
    if ((~(integer)llListFindList(lParams, ["nocolor"])) || sDesc == "" || sDesc == " " || sDesc == "(No Description)")
    {
        return "nocolor";
    }
    else
    {
        return llList2String(lParams, 0);
    }
}


LoadColorSettings()
{
    //llOwnerSay(llDumpList2String(g_lColorSettings, ","));
    //loop through links, setting each's color according to entry in g_lColorSettings list
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    for (n = 2; n <= iLinkCount; n++)
    {
        string element = ElementType(n);
        integer iIndex = llListFindList(g_lColorSettings, [element]);
        vector vColor = (vector)llList2String(g_lColorSettings, iIndex + 1);
        //llOwnerSay(llList2String(g_lColorSettings, iIndex + 1));
        if (iIndex != -1)
        {
            //set link to new color
            llSetLinkColor(n, vColor, ALL_SIDES);
            //llSay(0, "setting link " + (string)n + " to color " + (string)vColor);
        }
    }
}

BuildElementList()
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        string sElement = ElementType(n);
        if (!(~llListFindList(g_lElements, [sElement])) && sElement != "nocolor")
        {
            g_lElements += [sElement];
            //llSay(0, "added " + sElement + " to elements");
        }
    }
}

SetElementColor(string sElement, vector vColor)
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    for (n = 2; n <= iLinkCount; n++)
    {
        string thiselement = ElementType(n);
        if (thiselement == sElement)
        {
            //set link to new color
            //llSetLinkPrimitiveParams(n, [PRIM_COLOR, ALL_SIDES, color, 1.0]);
            llSetLinkColor(n, vColor, ALL_SIDES);
        }
    }
    //create shorter string from the color vectors before saving
    string sStrColor = Vec2String(vColor);
    //change the g_lColorSettings list entry for the current element
    integer iIndex = llListFindList(g_lColorSettings, [sElement]);
    if (iIndex == -1)
    {
        g_lColorSettings += [sElement, sStrColor];
    }
    else
    {
        g_lColorSettings = llListReplaceList(g_lColorSettings, [sStrColor], iIndex + 1, iIndex + 1);
    }
    //save to httpdb
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + llDumpList2String(g_lColorSettings, "~"), NULL_KEY);
    //g_sCurrentElement = "";
}



integer StartsWith(string sHayStack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return llDeleteSubString(sHayStack, llStringLength(sNeedle), -1) == sNeedle;
}

string Vec2String(vector vVec)
{
    list lParts = [vVec.x, vVec.y, vVec.z];

    integer n;
    for (n = 0; n < 3; n++)
    {
        string sStr = llList2String(lParts, n);
        //remove any trailing 0's or .'s from sStr
        while ((~(integer)llSubStringIndex(sStr, ".")) && (llGetSubString(sStr, -1, -1) == "0" || llGetSubString(sStr, -1, -1) == "."))
        {
            sStr = llGetSubString(sStr, 0, -2);
        }
        lParts = llListReplaceList(lParts, [sStr], n, n);
    }
    return "<" + llDumpList2String(lParts, ",") + ">";
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        //get dbprefix from object desc, so that it doesn't need to be hard coded, and scripts between differently-primmed collars can be identical
        string sPrefix = llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 2);
        if (sPrefix != "")
        {
            g_sDBToken = sPrefix + g_sDBToken;
        }

        //loop through non-root prims, build element list
        BuildElementList();
        // no more needed
        // we need to unify the initialization of the menu system for 3.5
        llSleep(1.0);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (sStr == "reset" && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
        {
            //clear saved settings
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
            llResetScript();
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            if (sStr == "settings")
            {
                Notify(kID, "Color Settings: " + llDumpList2String(g_lColorSettings, ","),FALSE);
            }
            else if (StartsWith(sStr, "setcolor"))
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the colors.", FALSE);
                }
                else if (g_iAppLock)
                {
                    Notify(kID,"The appearance of the collar is locked. You cannot access this menu now!", FALSE);
                }
                else
                {
                    list lParams = llParseString2List(sStr, [" "], []);
                    string sElement = llList2String(lParams, 1);
                    lParams = llParseString2List(sStr, ["<"], []);
                    vector vColor = (vector)("<"+llList2String(lParams, 1));
                    SetElementColor(sElement, vColor);
                }
            }
            else if (sStr == "menu "+ g_sSubMenu || sStr == "colors")
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the colors.", FALSE);
                    llMessageLinked(LINK_SET, iNum, "menu "+g_sParentMenu, kID);
                }
                else if (g_iAppLock)
                {
                    Notify(kID,"The appearance of the collar is locked. You cannot access this menu now!", FALSE);
                    llMessageLinked(LINK_SET, iNum, "menu "+g_sParentMenu, kID);
                }
                else
                {
                    g_sCurrentElement = "";
                    ElementMenu(kID, iNum);
                }
            }
            else if (llGetSubString(sStr,0,13) == "lockappearance")
            {
                if (iNum == COMMAND_OWNER)
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
            }

        }
        
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sDBToken)
            {
                g_lColorSettings = llParseString2List(sValue, ["~"], []);
                //llInstantMessage(llGetOwner(), "Loaded color settings.");
                LoadColorSettings();
            }
            else if (sToken == g_sAppLockToken)
            {
                g_iAppLock = (integer)sValue;
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                g_lMenuIDs=llDeleteSubList(g_lMenuIDs,iMenuIndex,iMenuIndex);
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU)
                {
                    if (g_sCurrentElement == "")
                    {
                        //main menu
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if (g_sCurrentCategory == "")
                    {
                        g_sCurrentElement = "";
                        ElementMenu(kAv, iAuth);
                    }
                    else
                    {
                        g_sCurrentCategory = "";
                        CategoryMenu(kAv, iAuth);
                    }
                }
                else if (sMessage == "*Touch*")
                {
                    Notify(kAv, "Please touch the part of the collar you want to recolor.", FALSE);
                    g_kTouchID = TouchRequest(kAv, TRUE, FALSE, iAuth);
                }
                else if (g_sCurrentElement == "")
                {
                    //we just got the element name
                    g_sCurrentElement = sMessage;
                    g_sCurrentCategory = "";
                    CategoryMenu(kAv, iAuth);
                }

                else if (g_sCurrentCategory == "")
                {
                    g_lColors = [];
                    g_sCurrentCategory = sMessage;
                    integer iIndex = llListFindList(g_lCategories,[sMessage]);
                    //sDatakID = llGetNotecardLine("colors-" + g_sCurrentCategory, g_iLine);
                    //we'll have gotten several lines like "Chartreuse|<0.54118, 0.98431, 0.09020>"
                    //parse that into 2-strided list of colorname, colorvector
                    g_lColors = llParseString2List(llList2String(g_lAllColors, iIndex), ["\n", "|"], []);
                    g_lColors = llListSort(g_lColors, 2, TRUE);
                    ColorMenu(kAv,iAuth);
                }
                else if (~(integer)llListFindList(g_lColors, [sMessage]))
                {
                    //found a color, now set it
                    integer iIndex = llListFindList(g_lColors, [sMessage]);
                    vector vColor = (vector)llList2String(g_lColors, iIndex + 1);
                    //llSay(0, "color = " + (string)vColor);
                    //loop through links, setting color if element type matches what we're changing
                    //root prim is 1, so start at 2
                    SetElementColor(g_sCurrentElement, vColor);
                    //ElementMenu(kID);
                    ColorMenu(kAv, iAuth);
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                g_lMenuIDs=llDeleteSubList(g_lMenuIDs,iMenuIndex,iMenuIndex);
            }
        }
        else if (iNum == TOUCH_RESPONSE)
        {
            if (kID == g_kTouchID)
            {
                list lParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lParams, 0);
                integer iAuth = (integer)llList2String(lParams, 1);
                integer iLinkNumber = (integer)llList2String(lParams, 3);
                
                string sElement = ElementType(iLinkNumber);
                if (sElement != "nocolor")
                {
                    CategoryMenu(kAv, iAuth);
                    g_sCurrentElement = sElement;
                    Notify(kAv, "You selected \""+sElement+"\".", FALSE);
                }
                else
                {
                    Notify(kAv, "You selected a prim which is not colorable. You can try again.", FALSE);
                    ElementMenu(kAv, iAuth);
                }
            }
        }
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
}