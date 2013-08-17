//OpenCollar - texture
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life. See "OpenCollar License" for details.
//color

//set textures by uuid, and save uuids instead of texture names to DB

//on getting texture command, give menu to choose which element, followed by menu to pick texture

list g_lElements;
string s_CurrentElement = "";
list g_lTextures;
list g_lTextureDefaults;
string g_sParentMenu = "Appearance";
string g_sSubMenu = "Textures";
string CTYPE = "collar";
integer iLength;
list lButtons;
list g_lNewButtons;//is this used? 2010/01/14 Starship

//dialog handles
key g_kElementID;
key g_ktextureID;
//touch request handle
key g_kTouchID;

integer g_iAppLock = FALSE;
string g_sAppLockToken = "Appearance_Lock";

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated. each script should send its own IMs now. This is to reduce even the tiny bt of lag caused by having IM slave scripts
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
string g_sScript;

// texture name element divider, put constant in so can be changed throughout the script with one change.
string SEPARATOR = "~";
// set FALSE to enable basic AND special texture names for all elements, TRUE for ONLY special textures per element.
// TRUE will still use basic textures for a given element WHEN that element has no special textures named in the collar.
integer EXCLUSIVE = TRUE;

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

string GetDefaultTexture(string ele)
{
    integer i = llListFindList(g_lTextureDefaults, [ele]);
    if (~i) return llList2String(g_lTextureDefaults, i + 1);
    return NULL_KEY;
}

integer GetIsLeashTex(string sInvName)
{
    if (llGetSubString(sInvName, 0, 5) == "leash_") return TRUE;
    if (sInvName == "chain" || sInvName == "rope" || sInvName == "!totallytransparent") return TRUE;
    return FALSE;
}

string GetShortName(string sTex) // strip all prefixes from a texture name
{
    return llList2String(llParseString2List(sTex, [SEPARATOR], []), -1);
}

string GetLongName(string ele, string sTex) // find the full texture name given element + shortname
{
    list work = BuildTextureNames(FALSE);
    string test;
    integer l = 0;
    for (; l < llGetListLength(work); l++)
    {
        test = llList2String(work, l);
        if (~llSubStringIndex(test, sTex))
        {
            if (!GetElementHasTexs(ele) || ~llSubStringIndex(test, llToLower(ele) + SEPARATOR)) return test;
        }
    }
    return ""; // this should only happen if chat command is used with invalid texture
}

list BuildTextureNames(integer short) // set short TRUE to lop off all prefixes in return list, FALSE to carry full texture name
{
    list out = [];
    string name;
    integer l = 0;
    for (; l < llGetInventoryNumber(INVENTORY_TEXTURE); l++)
    {
        name = llGetInventoryName(INVENTORY_TEXTURE, l);
        if (!GetIsLeashTex(name)) // we want to ignore particle textures
        {
            if (short) name = GetShortName(name);
            out += [name];
        }
    }
    return out;
}

integer GetElementHasTexs(string ele) // check if textures exist with labels for the specified element
{
    ele = llToLower(ele) + SEPARATOR;
    integer l = 0;
    for (; l < llGetInventoryNumber(INVENTORY_TEXTURE); l++)
    {
        if (~llSubStringIndex(llGetInventoryName(INVENTORY_TEXTURE, l), ele)) return TRUE;
    }
    return FALSE;
}

list BuildTexButtons()
{
    list tex = BuildTextureNames(FALSE);
    list out = [];
    if (~llListFindList(g_lTextureDefaults, [s_CurrentElement])) out = ["Default"];
    string ele = llToLower(s_CurrentElement) + SEPARATOR;
    string but;
    integer l = 0;
    for (; l < llGetListLength(tex); l++)
    {
        but = llList2String(tex, l);
        if (EXCLUSIVE && GetElementHasTexs(s_CurrentElement))
        {
            if (~llSubStringIndex(but, ele)) but = GetShortName(but);
            else but = "";
        }
        else if (~llSubStringIndex(but, SEPARATOR))
        {
            if (~llSubStringIndex(but, ele)) but = GetShortName(but);
            else but = "";
        }
        if (but != "") out += [but];
    }
    return out;
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

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

key TouchRequest(key kRCPT, integer iTouchStart, integer iTouchEnd, integer iAuth)
{
    key kID = llGenerateKey();
    integer iFlags = 0;
    if (iTouchStart) iFlags = iFlags | 0x01;
    if (iTouchEnd) iFlags = iFlags | 0x02;
    llMessageLinked(LINK_SET, TOUCH_REQUEST, (string)kRCPT + "|" + (string)iFlags + "|" + (string)iAuth, kID);
    return kID;
}

TextureMenu(key kID, integer iPage, integer iAuth)
{
    string sPrompt = "Choose the texture to apply.";
    g_ktextureID = Dialog(kID, sPrompt, BuildTexButtons(), [UPMENU], iPage, iAuth);
}

ElementMenu(key kAv, integer iAuth)
{
    string sPrompt = "Pick which part of the " + CTYPE + " you would like to retexture.\n\nChoose *Touch* if you want to select the part by directly clicking on the collar.";
    lButtons = llListSort(g_lElements, 1, TRUE);
    g_kElementID = Dialog(kAv, sPrompt, lButtons, ["*Touch*", UPMENU], 0, iAuth);
}

string ElementType(integer iLinkNum)
{
    string sDesc = (string)llGetObjectDetails(llGetLinkKey(iLinkNum), [OBJECT_DESC]);
    //prim desc will be elementtype~notexture(maybe)
    list lParams = llParseString2List(sDesc, ["~"], []);
    if ((~(integer)llListFindList(lParams, ["notexture"])) || sDesc == "" || sDesc == " " || sDesc == "(No Description)")
    {
        return "notexture";
    }
    else
    {
        return llList2String(llParseString2List(sDesc, ["~"], []), 0);
    }
}
// -- Deprecated "LoadTextureSettings" --
integer StartsWith(string sHayStack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return llDeleteSubString(sHayStack, llStringLength(sNeedle), -1) == sNeedle;
}

SetElementTexture(string sElement, string sTex)
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    for (n = 2; n <= iLinkCount; n++)
    {
        string thiselement = ElementType(n);
        if (thiselement == sElement) llSetLinkTexture(n, sTex, ALL_SIDES);
    }

    //change the textures list entry for the current element
    integer iIndex = llListFindList(g_lTextures, [sElement]);
    if (~iIndex) g_lTextures = llListReplaceList(g_lTextures, [sTex], iIndex + 1, iIndex + 1);
    else g_lTextures += [s_CurrentElement, sTex];
    //save to settings
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + sElement + "=" + sTex, NULL_KEY);
}
string DumpSettings(string sep)
{
    string out;
    integer i = 0;
    for (; i < llGetListLength(g_lTextures); i += 2)
    {
        out += sep + "Texture" + llList2String(g_lTextures, i);
        out += "=" + llList2String(g_lTextures, i + 1);
    }
    return out;
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
		g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        //loop through non-root prims, build element list
        integer n;
        integer iLinkCount = llGetNumberOfPrims();

        //root prim is 1, so start at 2
        for (n = 2; n <= iLinkCount; n++)
        {
            string sElement = ElementType(n);
            if (!(~llListFindList(g_lElements, [sElement])) && sElement != "notexture")
            {
                g_lElements += [sElement];
                //llSay(0, "added " + sElement + " to g_lElements");
            }
        }
        // we need to unify the initialization of the menu system for 3.5
        llSleep(1.0);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        //owner, secowner, group, and wearer may currently change colors
        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            if (sStr == "textures" || sStr == "menu "+g_sSubMenu)
            {
                if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
                {
                    Notify(kID, "You are not allowed to change the textures.", FALSE);
                    if (!llSubStringIndex(sStr, "menu "))
                        llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
                }
                else if (g_iAppLock)
                {
                    Notify(kID, "The appearance of the " + CTYPE + " is locked. You cannot access this menu now!", FALSE);
                    if (!llSubStringIndex(sStr, "menu "))
                        llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
                }
                else
                {
                    s_CurrentElement = "";
                    ElementMenu(kID, iNum);
                }
            }
            else if (llGetSubString(sStr,0,13) == "lockappearance")
            {
                if (iNum == COMMAND_OWNER)
                {
                    if(llGetSubString(sStr, -1, -1) == "0") g_iAppLock = FALSE;
                    else g_iAppLock = TRUE;
                }
            }
            else if (sStr == "reset" && (iNum == COMMAND_OWNER || kID == g_kWearer))
            {
                //clear saved settings
                //llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sDBToken, NULL_KEY);
                llResetScript();
            }
            else if (kID != g_kWearer && iNum != COMMAND_OWNER) return;
            if (sStr == "settings") Notify(kID, "Texture Settings: " + DumpSettings("\n"), FALSE);
            else if (g_iAppLock)
            {
                Notify(kID, "The appearance of the " + CTYPE + " is locked. You cannot access this menu now!", FALSE);
            }
            else
            {
                list lParams = llParseString2List(sStr, [" "], []);
                string sElement = llList2String(lParams, 1);
                string sTex = llList2String(lParams, 2);
                // subroutine to make chat entry of element non-case sensitive
                string test;
                integer l = 2;
                for (; l <= llGetNumberOfPrims(); l++)
                {
                    test = ElementType(l);
                    if (llToLower(test) == llToLower(sElement))
                    {
                        sElement = test;
                        jump break;
                    }
                }
                @break;
                SetElementTexture(sElement, sTex);
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
			integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                i = llListFindList(g_lTextureDefaults, [sToken]);
                if (~i) g_lTextureDefaults = llListReplaceList(g_lTextureDefaults, [sValue], i + 1, i + 1);
                else g_lTextureDefaults += [sToken, sValue];
            }
			else if (sToken == g_sAppLockToken) g_iAppLock = (integer)sValue;
			else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (llListFindList([g_kElementID, g_ktextureID], [kID]) != -1)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                if (kID == g_kElementID)
                {//they just chose an element, now choose a texture
                    if (sMessage == UPMENU)
                    {
                        //main menu
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if (sMessage == "*Touch*")
                    {
                        Notify(kAv, "Please touch the part of the " + CTYPE + " you want to retexture. You can press ctr+alt+T to see invisible parts.", FALSE);
                        g_kTouchID = TouchRequest(kAv, TRUE, FALSE, iAuth);
                    }
                    else
                    {
                        //we just got the element name
                        s_CurrentElement = sMessage;
                        TextureMenu(kAv, iPage, iAuth);
                    }
                }
                else if (kID == g_ktextureID)
                {
                    if (sMessage == UPMENU)
                    {
                        s_CurrentElement = "";
                        ElementMenu(kAv, iAuth);
                    }
                    else
                    {
                        //got a texture name
                        string sTex = GetLongName(s_CurrentElement, sMessage);
                        if (sMessage == "Default") sTex = GetDefaultTexture(s_CurrentElement);
                        SetElementTexture(s_CurrentElement, sTex);
                        TextureMenu(kAv, iPage, iAuth);
                    }
                }
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
                if (sElement != "notexture")
                {
                    TextureMenu(kAv, 0, iAuth);
                    Notify(kAv, "You selected \""+sElement+"\".", FALSE);
                }
                else
                {
                    Notify(kAv, "You selected a prim which is not texturable. You can try again.", FALSE);
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
