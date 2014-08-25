////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           OpenCollarHUD - Ownermenu                            //
//                                 version 3.901                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//New Owner menu system added by North Glenwalker
//-----------------------------------------------------------------

// You can add any command you normally type on the command line to access the collar.
// EG if you force your sub into nadu, you would normally use /1<prefix>nadu
// see button 7 for this example.
// You need to reset the scripts after changes for the new settings to take effect

//This is where you change the text of each button, keep it short
string Button1 = "Cuffs";
string Button2 = "RlVmenu";
string Button3 = "Ballgag";
string Button4 = "NoCuffs";
string Button5 = "NoBallgag";
string Button6 = " ";        //This will give a blank button for spacing (it should not be empty)
string Button7 = "Nadu";     //example of pose button
string Button8 = "Release";  //and release from pose button
string Button9 = "Leather";  // an outfit called leather
string Button10 = "Button10";
string Button11 = "Button11";

//This is where you add the command you want the button to do
string cmd1 = "+cuffs";    //will attach the folder in #RLV called cuffs
string cmd2 = "rlv";   //will give you the collar RLV menu
string cmd3 = "+ballgag";  //will attach the folder named ballgag
string cmd4 = "-cuffs";    //will detach the #RLV folder called cuffs
string cmd5 = "-ballgag";  //will detach the #RLV folder called ballgag
string cmd6 = "cmd6";      //if the button is blank this can be anything but not empty.
string cmd7 = "nadu";      //example of forcing a sub into nadu.
string cmd8 = "release";   //release from pose
string cmd9 = "+leather";   // add RLV folder called leather
string cmd10 = "cmd10";
string cmd11 = "cmd11";


//DO NOT CHANGE ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU ARE DOING
//--------------------------------------------------------------------

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer SEND_CMD_PICK_SUB = -1002;

//Strings
string UPMENU = "^";

string parentmenu = "Main";

string currentmenu;
string submenu = "OwnerMenu";

key wearer;

key menuid;

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
 "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}


Dialogowner(key id)
{
    currentmenu = "OwnerMenu";
    list buttons ;
    string text = "This is where you can set up your own commands for the collar\n";
    text += "See the examples in OpenCollarHud - Ownermenu script";

    buttons += [Button1];
    buttons += [Button2];
    buttons += [Button3];
    buttons += [Button4];
    buttons += [Button5];
    buttons += [Button6];
    buttons += [Button7];
    buttons += [Button8];
    buttons += [Button9];
    buttons += [Button10];
    buttons += [Button11];
    list utility = [UPMENU];
    menuid = Dialog(id, text, buttons, utility, 0);
}

default
{
    state_entry()
    {
        wearer = llGetOwner();//Lets get the ID of who is wearing us
        llSleep(1.0);
//      llOwnerSay("Debug: state_entry Ownermenu, menu button");
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
    }

    link_message(integer sender, integer auth, string str, key id)
    {// only the primary owner can use this !!
        if (auth == MENUNAME_REQUEST && str == parentmenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        }
        else if (auth == SUBMENU && str == submenu)
        {
            Dialogowner(id);
        }
        else if (str == "OwnerMenu")
        {
            Dialogowner(id);
        }
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
//              OK lets send the command against the button
                else if (message == Button1)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd1), id);
                else if (message == Button2)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd2), id);
                else if (message == Button3)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd3), id);
                else if (message == Button4)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd4), id);
                else if (message == Button5)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd5), id);
                else if (message == Button6)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd6), id);
                else if (message == Button7)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd7), id);
                else if (message == Button8)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd8), id);
                else if (message == Button9)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd9), id);
                else if (message == Button10)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd10), id);
                else if (message == Button11)
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(cmd11), id);
            }
        }
        else if (auth == DIALOG_TIMEOUT)
        {
            if (id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                llOwnerSay("Owner Menu timed out!");
                menuid = NULL_KEY;
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_OWNER)
            llResetScript();
    }

    on_rez(integer start_param)
    {// should reset on rez to make sure the parent menu gets populated with our button
        llResetScript();
    }
}
