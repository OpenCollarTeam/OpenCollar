//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message

list g_lMenuNames = ["Main", "Help/Debug", "AddOns"];
list g_lMenus;//exists in parallel to g_lMenuNames, each entry containing a pipe-delimited string with the items for the corresponding menu
list g_lMenuPrompts = [
"Pick an option.\n",
"Click 'Guide' to receive a help notecard,\nClick 'ResetScripts' to reset the OpenCollar scripts without losing your settings.\nClick any other button for a quick popup help about the chosen topic.\n",
"Please choose your AddOn:\n"
];

list g_lMenuIDs;//3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
integer g_iMenuStride = 3;

//integer g_iListenChan = 1908789;
//integer g_iListener;
//integer g_iTimeOut = 60;

integer g_iScriptCount;//when the scriptcount changes, rebuild menus

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
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
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//5000 block is reserved for IM slaves

//string UPMENU = "↑";
//string MORE = "→";
string UPMENU = "^";
//string MORE = ">";
string GIVECARD = "Guide";
string HELPCARD = "OpenCollar Guide";
string REFRESH_MENU = "Fix Menus";
string RESET_MENU = "ResetScripts";

Debug(string text)
{
    //llOwnerSay(llGetScriptName() + ": " + text);
}

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

Menu(string sName, key kID, integer iAuth)
{
    integer iMenuIndex = llListFindList(g_lMenuNames, [sName]);
    Debug((string)iMenuIndex);    
    if (iMenuIndex != -1)
    {
        list lItems = llParseString2List(llList2String(g_lMenus, iMenuIndex), ["|"], []);

        string sPrompt = llList2String(g_lMenuPrompts, iMenuIndex);
        
        list lUtility = [];
        
        if (sName != "Main")
        {
            lUtility = [UPMENU];
        }
        
        key kMenuID = Dialog(kID, sPrompt, lItems, lUtility, 0, iAuth);
        
        integer iIndex = llListFindList(g_lMenuIDs, [kID]);
        if (~iIndex)
        {
            //we've alread given a menu to this user.  overwrite their entry
            g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
        }
        else
        {
            //we've not already given this user a menu. append to list
            g_lMenuIDs += [kID, kMenuID, sName];
        }
    }
}

integer KeyIsAv(key kID)
{
    return llGetAgentSize(kID) != ZERO_VECTOR;
}

MenuInit()
{
    g_lMenus = ["","",""];
    integer n;
    integer iStop = llGetListLength(g_lMenuNames);
    for (n = 0; n < iStop; n++)
    {
        string sName = llList2String(g_lMenuNames, n);
        if (sName != "Main")
        {
            //make each submenu appear in Main
            HandleMenuResponse("Main|" + sName);
            
            //request children of each submenu
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, sName, NULL_KEY);            
        }
    }
    //give the help menu GIVECARD and REFRESH_MENU buttons    
    HandleMenuResponse("Help/Debug|" + GIVECARD);
    HandleMenuResponse("Help/Debug|" + REFRESH_MENU);
    HandleMenuResponse("Help/Debug|" + RESET_MENU);       
    
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Main", ""); 
}

HandleMenuResponse(string entry)
{
    list lParams = llParseString2List(entry, ["|"], []);
    string sName = llList2String(lParams, 0);
    integer iMenuIndex = llListFindList(g_lMenuNames, [sName]);
    if (iMenuIndex != -1)
    {             
        Debug("we handle " + sName);
        string g_sSubMenu = llList2String(lParams, 1);
        //only add submenu if not already present
        Debug("adding button " + g_sSubMenu);
        list lGuts = llParseString2List(llList2String(g_lMenus, iMenuIndex), ["|"], []);
        Debug("existing buttons for " + sName + " are " + llDumpList2String(lGuts, ","));
        if (llListFindList(lGuts, [g_sSubMenu]) == -1)
        {
            lGuts += [g_sSubMenu];
            lGuts = llListSort(lGuts, 1, TRUE);
            g_lMenus = llListReplaceList(g_lMenus, [llDumpList2String(lGuts, "|")], iMenuIndex, iMenuIndex);
        }
    }    
    else
    {
        Debug("we don't handle " + sName);
    }
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    // SA: TODO delete this when transition is finished
    if (iNum == COMMAND_NOAUTH) {llMessageLinked(LINK_SET, iNum, sStr, kID); return TRUE;}
    // /SA
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llList2String(lParams, 0);

    if (sStr == "menu") Menu("Main", kID, iNum);
    else if (sCmd == "menu")
    {
        string sSubmenu = llGetSubString(sStr, 5, -1);
        if (llListFindList(g_lMenuNames, [sSubmenu]) != -1);
        Menu(sSubmenu, kID, iNum);
    }
    else if (sStr == "help") llGiveInventory(kID, HELPCARD);                
    else if (sStr == "addons") Menu("AddOns", kID, iNum);
    else if (sStr == "debug") Menu("Help/Debug", kID, iNum);
    else if (sCmd == "menuto") 
    {
        // SA: with the new authentification method, I do not like this request for auth at this stage.
        // what happens here is that up to this point, we consider that the wearer is the one
        // who issued "menuto", and then change auth to that of the clicker.
        // My opinion is that the wearer should never play a role in this and that there should be
        // only one request for auth: in the listener script.
        // This could already be done, but it would still be ugly to have this exception for "menuto"
        // in listener. I would rather have a generic way for another attachment to query an arbitrary
        // command (not only "menu") on behalf of an arbitrary avatar.
        // TODO: change the "HUD channel protocol" in order to make this possible.
        key kAv = (key)llList2String(lParams, 1);
        if (KeyIsAv(kAv)) llMessageLinked(LINK_SET, COMMAND_NOAUTH, "menu", kAv);
    }
    else if (sCmd == "refreshmenu")
    {
        llDialog(kID, "Rebuilding menu.  This may take several seconds.", [], -341321);
        //MenuInit();
        llResetScript();
    }
    return TRUE;
}

default
{
    state_entry()
    {
        llSleep(1.0);//delay sending this message until we're fairly sure that other scripts have reset too, just in case
        g_iScriptCount = llGetInventoryNumber(INVENTORY_SCRIPT);
        MenuInit();      
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        // SA: delete this after transition is finished
        if (iNum == COMMAND_NOAUTH) return;
        // /SA
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == MENUNAME_RESPONSE)
        {
            //sStr will be in form of "parent|menuname"
            //ignore unless parent is in our list of menu names
            HandleMenuResponse(sStr);
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            string parent = llList2String(lParams, 0);
            string child = llList2String(lParams, 1);
            integer iMenuIndex = llListFindList(g_lMenuNames, [parent]);
            if (iMenuIndex != -1)
            {
                list lGuts = llParseString2List(llList2String(g_lMenus, iMenuIndex), ["|"], []);
                integer gutiIndex = llListFindList(lGuts, [child]);
                //only remove if it's there
                if (gutiIndex != -1)        
                {
                    lGuts = llDeleteSubList(lGuts, gutiIndex, gutiIndex);
                    g_lMenus = llListReplaceList(g_lMenus, [llDumpList2String(lGuts, "|")], iMenuIndex, iMenuIndex);                    
                }        
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                //process response
                if (sMessage == UPMENU)
                {
                    Menu("Main", kAv, iAuth);
                }
                else
                {
                    if (sMessage == GIVECARD)
                    {
                        UserCommand(iAuth, "help", kAv);
                        Menu("Help/Debug", kAv, iAuth);
                    }
                    else if (sMessage == REFRESH_MENU)
                    {//send a command telling other plugins to rebuild their menus
                        UserCommand(iAuth, "refreshmenu", kAv);
                    }
                    else if (sMessage == RESET_MENU)
                    {//send a command to reset scripts
                        UserCommand(iAuth, "resetscripts", kAv);
                    }
                    else
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
    
    changed(integer iChange)
    {
        if (iChange & CHANGED_INVENTORY)
        {
            if (llGetInventoryNumber(INVENTORY_SCRIPT) != g_iScriptCount)
            {//a script has been added or removed.  Reset to rebuild menu
                llResetScript();
            }
        }
    }
}