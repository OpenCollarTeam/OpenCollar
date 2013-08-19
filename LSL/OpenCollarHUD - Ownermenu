// Owner Menu script for the OpenCollar Project (c)
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

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

integer timeout = 90;
//MESSAGE MAP
integer COMMAND_OWNER = 500;
integer COMMAND_WEARER = 503;
integer CHAT = 505;

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
integer LOCALCMD_REQUEST = -2000;
integer LOCALCMD_RESPONSE = -2001;

//Strings
string UPMENU = "^";
string MORE = ">";
string parentmenu = "Main";
string submenu = "OwnerMenu";
string currentmenu;
string subName;

//Keys
key wearer;
key owner = NULL_KEY;
key menuid;

list settings;

key ShortKey()
{    // just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
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

SendIM(key id, string str)
{
    if (id != NULL_KEY)
    {
        llInstantMessage(id, str);
    }
}

SaveSettings(string str, key id)
{
    list temp = llParseString2List(str, [" "], []);
    string option = llList2String(temp, 0);
    string value = llList2String(temp, 1);
    integer index = llListFindList(settings, [option]);
    if(index == -1)
    {
        settings += temp;
    }
    else
    {
        settings = llListReplaceList(settings, [value], index + 1, index + 1);
    }
    string save = llDumpList2String(settings, ",");
    if(currentmenu == "Ownermenu")
    {
        llMessageLinked(LINK_SET, SUBMENU, submenu, id);
    }
}

default
{
    state_entry()
    {
        wearer = llGetOwner();//Lets get the ID of who is wearing us
        llSleep(1.0);
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
    }
       
    link_message(integer sender, integer auth, string str, key id)
    {  //only the primary owner can use this !!
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
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                string message = llList2String(menuparams, 1);
                integer page = (integer)llList2String(menuparams, 2);
                
                if(message == UPMENU)
                {//lets go up a menu
                    llMessageLinked(LINK_SET, SUBMENU, parentmenu, id);
                }
                
// OK lets send the command against the button
      
                if(message == Button1)
                {
                    string message = cmd1;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button2)
                {
                    string message = cmd2;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button3)
                {
                    string message = cmd3;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button4)
                {
                    string message = cmd4;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button5)
                {
                    string message = cmd5;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button6)
                {
                    string message = cmd6;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button7)
                {
                    string message = cmd7;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button8)
                {
                    string message = cmd8;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button9)
                {
                    string message = cmd9;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button10)
                {
                    string message = cmd10;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                if(message == Button11)
                {
                    string message = cmd11;
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                }
                
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
        {
            llResetScript();
        }
    }    
    on_rez(integer param)
    {     //should reset on rez to make sure the parent menu gets populated with our button
        llResetScript();
    }
}
