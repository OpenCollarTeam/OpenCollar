//OpenCollarHUD - hudmenu 3.8415 Evolution
//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message
list localcmds = ["menu"];
list menunames = ["Main"];
list menulists = [""];//exists in parallel to menunames, each entry containing a pipe-delimited string with the items for the corresponding menu
integer listenchannel = 1908789;
integer listener;
integer timeout = 90;
integer objectchannel = -1812221819;//only send on this channel, not listen

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer CHAT = 505;
integer COMMAND_UPDATE = 10001;
integer POPUP_HELP = 1001;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer MENUNAME_REMOVE = 3003;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SET_SUB = -1000;
integer SEND_CMD = -1001;
integer SEND_CMD_PICK_SUB = -1002;
integer SEND_CMD_ALL_SUBS = -1003;
integer SEND_CMD_NEARBY_SUBS = -1006;
integer LOCALCMD_REQUEST = -2000;
integer LOCALCMD_RESPONSE = -2001;

string UPMENU = "^";
string rlv = "rlv";//what have I added here?
key wearer;
key menuid;

key ShortKey()
{ //just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string chars = "0123456789abcdef";
    integer length = 16;
    string out;
    integer n;
    for (n = 0; n < 8; n++)
    {
        integer index = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        out += llGetSubString(chars, index, index);
    }

    return (key)(out + "-0000-0000-0000-000000000000");
}

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
        "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}

Menu(string name, key id)
{
    integer menuindex = llListFindList(menunames, [name]);

    if (menuindex != -1)
    {
        //this should be multipage in case there are more than 12 submenus, but for now single page
        //get submenu
        list buttons = llParseString2List(llList2String(menulists, menuindex), ["|"], []);
        list utility = [];
        string prompt = "Pick an option.";
        menuid = Dialog(id, prompt, buttons, utility, 0);
    }
}

debug(string str)
{
    // mm not much here
}

default
{
    state_entry()
    {
        wearer = llGetOwner();
        llSleep(1.0);//delay sending this message until we're fairly sure that other scripts have reset too, just in case
        //need to populate main menu with buttons for all menus we provide other than "Main"
        integer n;
        integer stop = llGetListLength(menunames);
        for (n = 0; n < stop; n++)
        {
            string name = llList2String(menunames, n);
            if (name != "Main")
            {
                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|" + name, NULL_KEY);
                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, name + "|" + UPMENU, NULL_KEY);
            }
        }
        //add "CollarMenu","CuffMenu" and RLVMenu buttons to main menu
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|CollarMenu", NULL_KEY);
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|UnDressMenu", NULL_KEY);
//        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|CuffMenu", NULL_KEY); //placeholder for now
    }

    touch_start(integer num)
    {
        key id = llDetectedKey(0);

        if ((llGetAttached() == 0)&& (id==wearer)) // Dont do anything if not attached to the HUD
        {
            llMessageLinked(LINK_THIS, COMMAND_UPDATE, "Update", id);
            return;
        }

        if (id == wearer)
        {   // I made the root prim the "menu" prim, and the button action default to "menu."
            string button = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
//ok if a button is pushed, which menu do we bring up!
            if (button == "TPSubs")
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER,"TPMenus", id);
            }         
            else if (button == "Menu")
            {
                Menu("Main", id);
            }
            else if (button == "Cage")
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER,"cagemenu",NULL_KEY);
            }
            else if (button == "Couples")
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER,"couples", id);
            }
            else if (button == "Leash")
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER,"LeashMenus", id);
            }
            else if (llSubStringIndex(button,"Owner")>=0)
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER,"hide",NULL_KEY);
                llSleep(1);
            }
            else
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER,button, id);
            }
        }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == MENUNAME_RESPONSE)
        {
            //str will be in form of "parent|menuname"
            //ignore unless parent is in our list of menu names
            list params = llParseString2List(str, ["|"], []);
            integer menuindex = llListFindList(menunames, llList2List(params, 0, 0));
            if (menuindex != -1)
            {
                string submenu = llList2String(params, 1);
                //only add submenu if not already present
                list guts = llParseString2List(llList2String(menulists, menuindex), ["|"], []);
                if (llListFindList(guts, [submenu]) == -1)
                {
                    guts += [submenu];
                    guts = llListSort(guts, 1, TRUE);
                    menulists = llListReplaceList(menulists, [llDumpList2String(guts, "|")], menuindex, menuindex);
                }
            }
        }
        else if (num == MENUNAME_REMOVE)
        {
            //str should be in form of parentmenu|childmenu
            list params = llParseString2List(str, ["|"], []);
            string parent = llList2String(params, 0);
            string child = llList2String(params, 1);
            integer menuindex = llListFindList(menunames, [parent]);
            if (menuindex != -1)
            {
                list guts = llParseString2List(llList2String(menulists, menuindex), ["|"], []);
                integer gutindex = llListFindList(guts, [child]);
                //only remove if it's there
                if (gutindex != -1)
                {
                    guts = llDeleteSubList(guts, gutindex, gutindex);
                    menulists = llListReplaceList(menulists, [llDumpList2String(guts, "|")], menuindex, menuindex);
                }
            }
        }
        else if (num == SUBMENU)
        {
            if (llListFindList(menunames, [str]) != -1)
            {
                Menu(str, id);
            }
//            lets bring up the special collar menu's
            else if (str == "CollarMenu")
            {
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "menu", NULL_KEY);
            }
            else if (str == "UnDressMenu")
            {
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "undress", NULL_KEY);
            }
            else if (str == "CuffMenu") //place holder for now
            {
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "cuff", NULL_KEY);
            }
        }
        else if (num == COMMAND_OWNER)
        {
            if (str == "menu")
            {
                Menu("Main", id);
            }
        }
        else if (num == LOCALCMD_REQUEST)
        {
            llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, llDumpList2String(localcmds, ","), NULL_KEY);
        }
        else if (num == DIALOG_RESPONSE)
        {
            if(id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                string message = llList2String(menuparams, 1);
                integer page = (integer)llList2String(menuparams, 2);

                if (message == UPMENU)
                {
                    Menu("Main", llGetOwner());
                }
                else
                {
                    llMessageLinked(LINK_SET, SUBMENU, message, llGetOwner());
                }
            }
        }
        else if (num == DIALOG_TIMEOUT)
        {
            if(id == menuid)
            {
                llOwnerSay("Main Menu timed out!");
            }
        }

    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            llResetScript();
        }
    }
}