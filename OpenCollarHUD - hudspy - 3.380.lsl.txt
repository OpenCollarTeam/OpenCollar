// Spy script for the OpenCollar Project (c)
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

integer timeout = 90;
//MESSAGE MAP
integer COMMAND_OWNER = 500;
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
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//5000 block is reserved for IM slaves

integer SET_SUB = -1000;
integer SEND_CMD = -1001;
integer SEND_CMD_PICK_SUB = -1002;
integer SEND_CMD_ALL_SUBS = -1003;

integer LOCALCMD_REQUEST = -2000;
integer LOCALCMD_RESPONSE = -2001;

string UPMENU = "^";
string MORE = ">";
string parentmenu = "Main";
string submenu = "Spy";
string currentmenu;

key owner = NULL_KEY;
key menuid;
string subName;
//integer menuchannel;
//integer menuhandle;

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


DialogSpy(key id)
{
    currentmenu = "spy";
    list buttons ;
    string text = "These are ONLY Primary Owner options:\n";
    text += "Trace turns on/off notices if the sub teleports.\n";
    text += "Radar turns on/off a recurring report of nearby avatars.\n";
    text += "Listen turns on/off if you get directly said what the sub says in public chat.\n";
    text += "Please be aware commands can take up to 60 secs to reach the subs-collar.\n";
    //text += "This menu will time out in " + (string)timeout + " seconds.";
    
    buttons += ["Listen On"];    
    buttons += ["Listen Off"];    
    buttons += ["Trace On"];    
    buttons += ["Trace Off"];
    buttons += ["Radar On"];    
    buttons += ["Radar Off"];
    list utility = [UPMENU];
    //buttons = RestackMenu(FillMenu(buttons));
    //menuchannel = -(integer)llFrand(9999.0) + 3000;
    //menuhandle = llListen(menuchannel, "", id, "");
    //llDialog(id, text, buttons, menuchannel);
    //llSetTimerEvent(timeout);
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
    llMessageLinked(LINK_SET, HTTPDB_SAVE, save, NULL_KEY);
    if(currentmenu == "spy")
    {
        llMessageLinked(LINK_SET, SUBMENU, submenu, id);
    }
}

default
{
    state_entry()
    {
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
            DialogSpy(id);
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
                {
                    llMessageLinked(LINK_SET, SUBMENU, parentmenu, id);
                }
                else if(message != " ")
                {
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, llToLower(message), id);
                    //DialogSpy(id);
                }
            }
        }
        else if (auth == DIALOG_TIMEOUT)
        {
            if (id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                llInstantMessage(id,"Menu timed out!");
                menuid = NULL_KEY;
            }
        }
    }
    
    on_rez(integer param)
    {     //should reset on rez to make sure the parent menu gets populated with our button
        llResetScript();
    }
}
