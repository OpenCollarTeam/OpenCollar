////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollarHUD - hudmenu                             //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message

list localcmds = ["menu","channel"];
list menunames = ["Main"];
integer listenchannel = 7;
integer listener;

//  exists in parallel to menunames, each entry containing a pipe-delimited string with the items for the corresponding menu
list menulists = [""];

//MESSAGE MAP
integer COMMAND_OWNER     = 500;
integer POPUP_HELP        = 1001;

integer COMMAND_UPDATE    = 10001;

integer MENUNAME_RESPONSE = 3001;
integer SUBMENU           = 3002;
integer MENUNAME_REMOVE   = 3003;
integer DIALOG            = -9000;
integer DIALOG_RESPONSE   = -9001;
integer DIALOG_TIMEOUT    = -9002;

integer SEND_CMD_PICK_SUB = -1002;

integer LOCALCMD_REQUEST  = -2000;
integer LOCALCMD_RESPONSE = -2001;

string UPMENU = "BACK";

SetListeners()
{
    llListenRemove(listener);
    listener = llListen(listenchannel, "", llGetOwner(), "");
}

string StringReplace(string src, string from, string to)
{
//  replaces all occurrences of 'from' with 'to' in 'src'.
//  Ilse: blame/applaud Strife Onizuka for this godawfully ugly though apparently optimized function

    integer len = (~-(llStringLength(from)));
    if(~len)
    {
        string  buffer = src;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(to)));

//      instead of a while loop, saves 5 bytes (and run faster).
        @loop;

        integer to_pos = ~llSubStringIndex(buffer, from);
        if(to_pos)
        {
            buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);

            jump loop;
        }
    }
    return src;
}

key wearer;
key menuid;

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
        "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}

Menu(string name, key id)
{
    integer menuindex = llListFindList(menunames, [name]);

    if (menuindex == -1) return;

//  this should be multipage in case there are more than 12 submenus, but for now single page
//  get submenu

    list buttons = llParseString2List(llList2String(menulists, menuindex), ["|"], []);
    list utility = [];
    string prompt = "\nOpenCollar Owner HUD\nVersion 3.980";
    menuid = Dialog(id, prompt, buttons, utility, 0);
}

default
{
    state_entry()
    {
        SetListeners();
        wearer = llGetOwner();
        llSleep(1.0);//delay sending this message until we're fairly sure that other scripts have reset too, just in case
        //need to populate main menu with buttons for all menus we provide other than "Main"
        integer stop = llGetListLength(menunames);
        llMessageLinked(LINK_SET, LOCALCMD_REQUEST, "", "");
        integer n;
        for (; n < stop; n++)
        {
            string name = llList2String(menunames, n);
            if (name != "Main")
            {
                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|" + name, "");
                llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, name + "|" + UPMENU, "");
            }
        }
        //add "CollarMenu", and RLVMenu buttons to main menu
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main| Collar", "");
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|Cage", "");
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|Pose", "");
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|RLV", "");
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|Sit", "");
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Main|Stand", "");
    }

    listen(integer channel, string name, key id, string message)
    {
        string cmd = llList2String(llParseString2List(message, [" "], []), 0);
        if (~llListFindList(localcmds, [cmd]))
            llMessageLinked(LINK_SET, COMMAND_OWNER, message, id);
        else
            llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, message, id);
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
        {
//          I made the root prim the "menu" prim, and the button action default to "menu."

            string button = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);


            if (button == "Bookmarks")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "bookmarks", "");
            else if (button == "Menu")
                Menu("Main", id);
            else if (button == "Beckon")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "beckon", "");
            else if (button == "Couples")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "couples", "");
            else if (button == "Leash")
                llMessageLinked(LINK_SET, COMMAND_OWNER,"LeashMenus", id);
            else if (llSubStringIndex(button,"Owner")>=0)
            {
                llMessageLinked(LINK_SET, COMMAND_OWNER,"hide","");
                llSleep(1);
            }
            else
                llMessageLinked(LINK_SET, COMMAND_OWNER,button, id);
        }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == COMMAND_OWNER)
        {
            list params = llParseString2List(str, [" "], []);
            string command = llList2String(params, 0);
            if (command == "channel")
            {
                integer newchannel = (integer)llList2String(params, 1);
                if (newchannel > 0)
                {
                    listenchannel =  newchannel;
                    SetListeners();
                    llOwnerSay("Say /" + (string)listenchannel + "menu to bring up the menu.");
                }
                
//                  they left the param blank or tried to use 0
                else
                    llOwnerSay("Error: 'channel' must be set to a number greater than 0.");
            }
            else if (command == "reset")
                llResetScript();
        }
//          replace _PREFIX_ with prefix, and _CHANNEL_ with (strin) channel
        else if (num == POPUP_HELP)
            llOwnerSay(StringReplace(str, "_CHANNEL_", (string)listenchannel));
        else if (num == LOCALCMD_RESPONSE)
        {
//          split string by ,

            list newcmds = llParseString2List(str, [","], []);

//          add each to list if not already in

            integer n;
            integer stop = llGetListLength(newcmds);
            for (n = 0; n < stop; n ++)
            {
                list cmd = llList2List(newcmds, n, n);
                if (llListFindList(localcmds, cmd) == -1)
                    localcmds += cmd;
            }
        }
        
        if (num == MENUNAME_RESPONSE)
        {
//          str will be in form of "parent|menuname"
//          ignore unless parent is in our list of menu names

            list params = llParseString2List(str, ["|"], []);
            integer menuindex = llListFindList(menunames, llList2List(params, 0, 0));
            if (~menuindex)
            {
                string submenu = llList2String(params, 1);

//              only add submenu if not already present
                list guts = llParseString2List(llList2String(menulists, menuindex), ["|"], []);

                if (~llListFindList(guts, [submenu])) return;

                guts += [submenu];
                guts = llListSort(guts, 1, TRUE);
                menulists = llListReplaceList(menulists, [llDumpList2String(guts, "|")], menuindex, menuindex);
            }
        }
        else if (num == MENUNAME_REMOVE)
        {
//          str should be in form of parentmenu|childmenu

            list    params    = llParseString2List(str, ["|"], []);
            string  parent    = llList2String(params, 0);
            string  child     = llList2String(params, 1);
            integer menuindex = llListFindList(menunames, [parent]);

            if (menuindex == -1) return;

            list    guts     = llParseString2List(llList2String(menulists, menuindex), ["|"], []);
            integer gutindex = llListFindList(guts, [child]);

//          only remove if it's there
            if (gutindex == -1) return;

            guts = llDeleteSubList(guts, gutindex, gutindex);
            menulists = llListReplaceList(menulists, [llDumpList2String(guts, "|")], menuindex, menuindex);
        }
        else if (num == SUBMENU)
        {
            if (llListFindList(menunames, [str]) != -1)
                Menu(str, id);
//          lets bring up the special collar menu's
            else if (str == "Collar")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "menu", "");
            else if (str == "Cage")
                llMessageLinked(LINK_SET, COMMAND_OWNER,"cagemenu","");
            else if (str == "Pose")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "pose", "");
            else if (str == "RLV")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "rlv", "");
            else if (str == "Sit")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "sitnow", "");
            else if (str == "Stand")
                llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "standnow", "");
        }
        else if (num == COMMAND_OWNER)
        {
            if (str == "menu")
                Menu("Main", id);
        }
        else if (num == LOCALCMD_REQUEST)
            llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, llDumpList2String(localcmds, ","), "");
        else if (num == DIALOG_RESPONSE)
        {
            if(id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                string message = llList2String(menuparams, 1);

                if (message == UPMENU)
                    Menu("Main", llGetOwner());
                else
                    llMessageLinked(LINK_SET, SUBMENU, message, llGetOwner());
            }
        }
       /* else if (num == DIALOG_TIMEOUT)
        {
            if(id == menuid)
                llOwnerSay("Main Menu timed out!");
        } */

    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
    }
}
