//OpenCollar - color - 3.520
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//color

//on getting color command, give menu to choose which element, followed by menu to pick color

list g_lElements;
string g_sCurrentElement = "";
string g_sCurrentCategory = "";
list g_lCategories = ["Blues", "Browns", "Grays", "Greens", "Purples", "Reds", "Yellows"];
list g_lColorSettings;
string g_sParentMenu = "Appearance";
string g_sSubMenu = "Colors";

string g_sDBToken = "colorsettings";

key g_kUser;
key g_kHTTPID;

list g_lColors;
integer g_iStridelength = 2;
integer g_iPage = 0;
integer g_iMenuPage;
integer g_iPagesize = 10;
integer g_iLength;
list g_lButtons;
list g_lNewButtons;

list g_lMenuIDs;

string g_sHTTPDB_Url = "http://data.mycollar.org/"; //defaul OC url, can be changed in defaultsettings notecard and wil be send by settings script if changed

integer g_iAppLock = FALSE;
string g_sAppLockToken = "AppLock";

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer CHAT = 505;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer HTTPDB_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer HTTPDB_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer HTTPDB_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer HTTPDB_DELETE = 2003;//delete token from DB
integer HTTPDB_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;



//5000 block is reserved for IM slaves

string UPMENU = "^";

key g_kWearer;

key ShortKey()
{//just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sChars = "0123456789abcdef";
    integer g_iLength = 16;
    string sOut;
    integer n;
    for (n = 0; n < 8; n++)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString(sChars, iIndex, iIndex);
    }

    return (key)(sOut + "-0000-0000-0000-000000000000");
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer g_iPage)
{
    key kID = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)g_iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`"), kID);
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

CategoryMenu(key kAv)
{
    //give kAv a dialog with a list of color cards
    string sPrompt = "Pick a Color.";
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lCategories, [UPMENU],0)];
}

ColorMenu(key kAv)
{
    string sPrompt = "Pick a Color.";
    list g_lButtons = llList2ListStrided(g_lColors,0,-1,2);
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lButtons, [UPMENU],0)];
}

ElementMenu(key kAv)
{
    string sPrompt = "Pick which part of the collar you would like to recolor";
    g_lButtons = llListSort(g_lElements, 1, TRUE);
    g_lMenuIDs+=[Dialog(kAv, sPrompt, g_lButtons, [UPMENU],0)];
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
    llMessageLinked(LINK_SET, HTTPDB_SAVE, g_sDBToken + "=" + llDumpList2String(g_lColorSettings, "~"), NULL_KEY);
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

    http_response(key kID, integer iStatus, list lMeta, string sBody)
    {
        if (kID == g_kHTTPID)
        {
            if (iStatus == 200)
            {
                //we'll have gotten several lines like "Chartreuse|<0.54118, 0.98431, 0.09020>"
                //parse that into 2-strided list of colorname, colorvector
                g_lColors = llParseString2List(sBody, ["\n", "|"], []);
                g_lColors = llListSort(g_lColors, 2, TRUE);
                ColorMenu(g_kUser);
            }
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (sStr == "reset" && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
        {
            //clear saved settings
            llMessageLinked(LINK_SET, HTTPDB_DELETE, g_sDBToken, NULL_KEY);
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
            else if (sStr == "colors")
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID,"You are not allowed to change the colors.", FALSE);
                    llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kID);
                }
                else if (g_iAppLock)
                {
                    Notify(kID,"The appearance of the collar is locked. You cannot access this menu now!", FALSE);
                }
                else
                {
                    g_sCurrentElement = "";
                    ElementMenu(kID);
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
        
        else if (iNum == HTTPDB_RESPONSE)
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
            else if (sToken == "HTTPDB")
            {
                g_sHTTPDB_Url = sValue;
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
        else if (iNum == SUBMENU && sStr == g_sSubMenu)
        {
            //we don't know the authority of the menu requester, so send a message through the auth system
            llMessageLinked(LINK_SET, COMMAND_NOAUTH, "colors", kID);
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
                integer g_iPage = (integer)llList2String(lMenuParams, 2);
                if (sMessage == UPMENU)
                {
                    if (g_sCurrentElement == "")
                    {
                        //main menu
                        llMessageLinked(LINK_SET, SUBMENU, g_sParentMenu, kAv);
                    }
                    else if (g_sCurrentCategory == "")
                    {
                        g_sCurrentElement = "";
                        ElementMenu(kAv);
                    }
                    else
                    {
                        g_sCurrentCategory = "";
                        CategoryMenu(kAv);
                    }
                }
                else if (g_sCurrentElement == "")
                {
                    //we just got the element name
                    g_sCurrentElement = sMessage;
                    g_iPage = 0;
                    g_sCurrentCategory = "";
                    CategoryMenu(kAv);
                }

                else if (g_sCurrentCategory == "")
                {
                    g_lColors = [];
                    g_sCurrentCategory = sMessage;
                    g_iPage = 0;
                    //ColorMenu(kID);
                    g_kUser = kAv;
                    //g_iLine = 0;
                    //sDatakID = llGetNotecardLine("colors-" + g_sCurrentCategory, g_iLine);
                    string sUrl = g_sHTTPDB_Url + "static/colors-" + g_sCurrentCategory + ".txt";
                    g_kHTTPID = llHTTPRequest(sUrl, [HTTP_METHOD, "GET"], "");
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
                    ColorMenu(kAv);
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

    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
}
