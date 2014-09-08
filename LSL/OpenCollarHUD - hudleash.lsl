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

//North Glenwalker, Romka Swallowtail, Builder's Brewery, Wendy Starfall

//MESSAGE MAP

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer SEND_CMD_PICK_SUB = -1002;

//Strings
string UPMENU =     "MORE";

string parentmenu = "Main";
//string submenu =    "LeashMenu";
string Grab =       "Grab";
string Release =    "STOP";
string Follow =     "Follow";
//string Beckon =     "Yank";
//string Pass =       "Pass";
//string Post =       "Post";
string Still =      "Stay";
//string ForceSit =   "Sit";
//string Stand =      "Stand";
string Thaw =       "Unstay";

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
    string text = "\nLeash Quickmenu";

    buttons += ["Grab"];
    //buttons += ["Yank"];
    buttons += ["Follow"];
    buttons += ["STOP"];
    //buttons += ["Pass"];
    //buttons += ["Post"];
    buttons += ["Stay"];
    //buttons += ["Sit"];
    //buttons += ["Stand"];
    buttons += ["Unstay"];
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

       // llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, "");
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
            //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, "");

        //else if (auth == SUBMENU && str == submenu)
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
                else if (message == Grab)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "grab", "");
                else if (message == Release)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "unleash", "");
                else if (message == Follow)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "follow me", "");
                //else if (message == Beckon)
                 //   llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "beckon", "");
               // else if (message == Pass)
                 //   llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "leashto", "");
               // else if (message == Post)
                 //   llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "post", "");
                else if (message == Still)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "stay", "");
               // else if (message == ForceSit)
                 //   llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "sitnow", "");
              //  else if (message == Stand)
                 //   llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "standnow", "");
                else if (message == Thaw)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "unstay", "");
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