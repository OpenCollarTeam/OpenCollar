////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollarHUD - hudspy                              //
//                                 version 3.901                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer SEND_CMD_PICK_SUB = -1002;

string UPMENU = "^";
string parentmenu = "Main";
string submenu = "Spy";
string currentmenu;

key menuid;

key ShortKey()
{// just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    return (key)(llGetSubString((string)llGenerateKey(), 0, 7) + "-0000-0000-0000-000000000000");
}

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
 "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}

DialogSpy(key id)
{
    currentmenu = "spy";
    list buttons ;
    string text = "These are ONLY Primary Owner options:\n";
    text += "Trace turns on/off notices if the sub teleports.\n";
    text += "Radar turns on/off a recurring report of nearby avatars.\n";
    text += "Listen turns on/off if you get directly said what the sub says in public chat.\n";
    text += "Please be aware commands can take up to 60 secs to reach the subs-collar.\n";

    buttons += ["Listen On"];
    buttons += ["Listen Off"];
    buttons += [" "]; //Space out the buttons
    buttons += ["Trace On"];
    buttons += ["Trace Off"];
    buttons += [" "];  //Space out the buttons
    buttons += ["Radar On"];
    buttons += ["Radar Off"];
    list utility = [UPMENU];
    menuid = Dialog(id, text, buttons, utility, 0);
}

default
{
    state_entry()
    {
        llSleep(1.0);
//      llOwnerSay("Debug: state_entry hudspy, menu button");
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
    }

    link_message(integer sender, integer auth, string str, key id)
    {// only the primary owner can use this !!
        if (auth == MENUNAME_REQUEST && str == parentmenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        }
        else if (auth == SUBMENU && str == submenu)
        {
            DialogSpy(id);
        }
        else if (auth == DIALOG_RESPONSE)
        {
            if (id == menuid)
            {
                list    menuparams = llParseString2List(str, ["|"], []);
                        id         = (key)llList2String(menuparams, 0);
                string  message    = llList2String(menuparams, 1);

                if (message == UPMENU)
                    llMessageLinked(LINK_SET, SUBMENU, parentmenu, id);
                else if (message != " ")
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
            }
        }
        else if (auth == DIALOG_TIMEOUT)
        {
            if (id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                     id         = (key)llList2String(menuparams, 0);

                llOwnerSay("Spy Menu timed out!");
                menuid = NULL_KEY;
            }
        }
    }

    on_rez(integer start_param)
    {// should reset on rez to make sure the parent menu gets populated with our button
        llResetScript();
    }
}
