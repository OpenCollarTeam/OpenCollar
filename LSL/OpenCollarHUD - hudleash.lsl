////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollarHUD - hudleash                            //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//New Leash menu system added by North Glenwalker

//MESSAGE MAP

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer SEND_CMD_PICK_SUB = -1002;

//Strings
string UPMENU =     "Back";

string parentmenu = "Main";
string submenu =    "LeashMenu";
string Leash =      "Leash";
string Follow =     "Follow";
string Release =    "Release";
string Post =       "Post";
string ForceSit =   "ForceSit";
string Stand =      "Stand";
string Bound =      "Bound";
string Unbound =    "Unbound";

string currentmenu;

//Keys
key wearer;

key menuid;

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
 "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}

Dialogleash(key id)
{
    currentmenu = "leashmenu";
    list buttons ;
    string text = "[Leash] Grab the leash of a/all sub(s)\n";
    text += "[Follow] Force a/all sub(s) to follow you without leash.\n";
    text += "[Post] Brings up the collar 'post' menu, so you may leash your sub to an item, like a leash post.\n";
    text += "[Release] UnLeash a/all subs.\n";
    text += "**NOTE** It is not recomended to leash a sub further then 20M away, but will work to a maximum of 60M in some cases.\n";
    text += "[ForceSit] Opens the ForceSit Collar Menu.\n";
    text += "[Stand] Forces the Subbie to Stand.\n";
    text += "[Bound] Attached the Bound folder in #RLV.\n";
    text += "[UnBound] Detaches the Bound folder in #RLV.\n";

    buttons += ["Leash"];
    buttons += ["Follow"];
    buttons += ["Post"];
    buttons += [" "];
    buttons += ["Release"];
    buttons += [" "];
    buttons += ["ForceSit"];
    buttons += ["Stand"];
    buttons += [" "];
    buttons += ["Bound"];
    buttons += ["Unbound"];
    list utility = [UPMENU];
    menuid = Dialog(id, text, buttons, utility, 0);
}

default
{
    state_entry()
    {
//      Lets get the ID of who is wearing us
        wearer = llGetOwner();
        llSleep(1.0);

        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, "");
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
    }

    link_message(integer sender, integer auth, string str, key id)
    {
//      only the primary owner can use this !!

        if (auth == MENUNAME_REQUEST && str == parentmenu)
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, "");

        else if (auth == SUBMENU && str == submenu)
            Dialogleash(id);

        else if (str == "LeashMenus")
            Dialogleash(id);

        else if (auth == DIALOG_RESPONSE)
        {
            if (id == menuid)
            {
                list   menuparams = llParseString2List(str, ["|"], []);
                       id         = (key)llList2String(menuparams, 0);
                string message    = llList2String(menuparams, 1);

//              lets go up a menu
                if (message == UPMENU)
                    llMessageLinked(LINK_SET, SUBMENU, parentmenu, id);
                else if (message == Leash)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower("leashto " + (string)wearer + " handle"), id);
                else if (message == Follow)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower("follow " + (string)wearer + " handle"), id);
                else if (message == Release)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "unleash", id);
//              brings up the Collar Post menu
                else if (message == Post)
                    llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "post", "");
//              brings up the Collar SitNow menu
                else if (message == ForceSit)
                    llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "sitnow", "");
//              forces the Collar wearer to stand
                else if (message == Stand)
                    llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "unsit=force", "");
//              attach a #RLV folder called bound
//              an idea from pandora15 - single button to attach an RLV folder containing items to bind/gag/pose/restrict at once
                else if (message == Bound)
                    llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "+bound", "");
                else if (message == Unbound)
                    llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "-bound", "");
            }
        }
        else if (auth == DIALOG_TIMEOUT)
        {
            if (id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                llOwnerSay("Leash Menu timed out!");
                menuid = NULL_KEY;
            }
        }
    }

    on_rez(integer param)
    {
        llResetScript();
    }
}