////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollarHUD - hudmain                             //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//  no gridwide TP, probably because of llRegionSayTo in SendCmd()
//  to enhance: check if command is a forced tp - then use llInstantMessage if sub is not in same SIM - but this is probably slow, laggy and error prone
//  and do not forget to check if avi is online, before sending out a gridwide tp...

string g_sDialogUrl;

//  strided list in the form key,name
list subs = [];

//  these will be told to the listener on LOCALCMD_REQUEST, so it knows not to pass them through the remote
list localcmds = ["reset","help"];

//  list of hud channel handles we are listening for, for building lists
list LISTENERS;

string parentmenu = "Main";   //  where we return to
string submenu    = "   MANAGE";   //  which menu are we
key    subkey     = NULL_KEY; //  clear the sub uuid
string subname;               //  what is the name of the sub
list   AGENTS;                //  list of AV's to ping

//  Notecard reading bits

string  configurationNotecardName = ".subs";
key     notecardQueryId;
integer line;

integer listener;

//  save cmd here while we give the sub menu to decide who to send it to
string pendingcmd;

//  MESSAGE MAP
integer COMMAND_OWNER        = 500;
integer POPUP_HELP           = 1001;

integer MENUNAME_REQUEST     = 3000;
integer MENUNAME_RESPONSE    = 3001;
integer SUBMENU              = 3002;

integer DIALOG               = -9000;
integer DIALOG_RESPONSE      = -9001;
integer DIALOG_TIMEOUT       = -9002;

integer SEND_CMD_PICK_SUB    = -1002;
integer SEND_CMD_ALL_SUBS    = -1003;
integer SEND_CMD_SUB         = -1005;
integer SEND_CMD_NEARBY_SUBS = -1006;

integer LOCALCMD_REQUEST     = -2000;
integer LOCALCMD_RESPONSE    = -2001;
integer DIALOG_URL           = -2002;

string UPMENU       = "BACK";

string listcollars  = "List";
string removesub    = "Remove";
//string list   = "Reload Menu";
string scansubs     = "Add";
string loadnotecard = "Load";
string dumpsubs     = "Print";
string ALLSUBS      = " ALL";

string wearerName;
key    removedSub;
key    wearer;

//  three strided list of avkey, dialogid, and menuname
list menuids;
integer menustride = 3;

//  Use these to keep track of your current menu
//  Use any variable name you desire

string MAINMENU   = "SubMenu";
string PICKMENU   = "PickSub";
string REMOVEMENU = "RemoveSub";

// Yay for Cleo and Jessenia – Personal Object Channel!
integer getPersonalChannel(key owner, integer nOffset)
{
    integer chan = (integer)("0x"+llGetSubString((string)owner,2,7)) + nOffset;
    if (0 < chan)
    {
        chan = chan*(-1);
    }
    if (chan > -10000)
    {
        chan -= 30000;
    }
    return chan;
}

integer InSim(key id)
{
//  check if the AV is logged in and in Sim

    return (llGetAgentSize(id) != ZERO_VECTOR);
}

SendCmd(key id, string cmd)
{
    subname = llList2String(subs, (llListFindList(subs, [(string)id])) + 1);

    if (InSim(id))
    {
        llRegionSayTo(id,getPersonalChannel(id,1111), (string)id + ":" + cmd);

       /* if (llGetSubString(cmd, 0, 6)=="leashto")
            llOwnerSay("Sending to "+ llGetDisplayName(id) + "'s collar - leashto " + llGetDisplayName(llGetSubString(cmd,8,43)));
        else if (llGetSubString(cmd, 0, 5)=="follow")
            llOwnerSay("Sending to "+ llGetDisplayName(id) + "'s collar - follow " + llGetDisplayName(llGetSubString(cmd, 7, 42)));
        else
            llOwnerSay("Sending to "+ llGetDisplayName(id) + "'s collar - " + cmd); */
    }
    else
    {
        llOwnerSay("\n\nSorry!\n\nI can't find "+subname+" in this region.\n");
        PickSubMenu(wearer, 0);
    }
}

SendNearbyCmd(string cmd)
{
    integer n;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
    {
        key id = (key)llList2String(subs, n);
        if (id != wearer && InSim(id)) //Don't expose out-of-sim subs
            SendCmd(id, cmd);
    }
}

SendAllCmd(string cmd)
{
    integer n;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
    {
        key id = (key)llList2String(subs, n);
        if (id != wearer && InSim(id)) //Prevent out of sim sending
            SendCmd(id, cmd);
    }
}

AddSub(key id, string name)
{

    if (~llListFindList(subs,[id]))
        return;
    if ( llStringLength(name) >= 24)
        name=llStringTrim(llGetSubString(name, 0, 23),STRING_TRIM);//only store first 24 char$ of subs name
    if (name!="????")//don't register any unrecognised names
    {
        if (id!="00000000-0000-0000-0000-000000000000")//Don't register any invalid ID's
        {
            subs+=[id,name,"***","***"];//Well we got here so lets add them to the list.
            llOwnerSay("\n\n"+name+" has been registered.\n");//Tell the owner we made it.
        }
    }
}

RemoveSub(key subbie)
{
    integer index = llListFindList(subs,[subbie]);
    if (~index)
    {
        subs=llDeleteSubList(subs,index, index+3);
        SendCmd(subbie, "remowners "+wearerName);
        SendCmd(subbie, "remsecowner "+wearerName);
    }
}


key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
 "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}

SubMenu(key id) // Single page menu
{
    string text;
    //list subs in prompt just fyi
    integer n;
    integer stop = llGetListLength(subs);
    text += "\nCurrently managing:\n";
    for (n = 0; n < stop; n = n + 4)
        text += "\n" + llList2String(subs, n + 1);
    text += "\n";
    list buttons;
    //add sub
    buttons += [scansubs,listcollars,removesub,loadnotecard,dumpsubs];
    //parent menu
    list utility = [UPMENU];

    if (llStringLength(text) > 511) // Check text length so we can warn for it being too long before hand.
     {
         llOwnerSay("**** Too many Collars registered, not all names may appear. ****");
         text = llGetSubString(text,0,510);
     }
    key menuid = Dialog(id, text, buttons, utility, 0);

    // UUID , Menu ID, Menu
    list newstride = [id, menuid, MAINMENU];

    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(menuids, [id]);

//  this person is already in the dialog list.  replace their entry
    if (~index)
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    else
        menuids += newstride;
}

PickSubMenu(key id, integer page) // Multi-page menu
{
    string text = "\nWho will receive this command?";
    list buttons = [ALLSUBS];
    //add subs
    integer n;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
        buttons += [llList2String(subs, n + 1)];
    //parent menu
    list utility = [UPMENU];

    key menuid = Dialog(id, text, buttons, utility, page);

    // UUID , Menu ID, Menu
    list newstride = [id, menuid, PICKMENU];

    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(menuids, [id]);

//  this person is already in the dialog list.  replace their entry
    if (~index)
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    else
        menuids += newstride;
}

RemoveSubMenu(key id, integer page) // Multi-page menu
{
    string text = "\nWho would you like to remove?\n\nNOTE: This will also remove you as their owner.";

    //add subs
    integer n;
    list buttons;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
        buttons += [llList2String(subs, n + 1)];

    //parent menu
    list utility = [UPMENU];

    key menuid = Dialog(id, text, buttons, utility, page);

    // UUID , Menu ID, Menu
    list newstride = [id, menuid, REMOVEMENU];

    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(menuids, [id]);

//  this person is already in the dialog list.  replace their entry
    if (~index)
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    else
        menuids += newstride;
}

ConfirmSubRemove(key id) // Single page menu
{
    string text = "\nAre you sure you want to remove " + subname + "?\n\nNOTE: This will also remove you as their owner.";

    list buttons = ["Yes", "No"];
    list utility = [UPMENU];

    key menuid = Dialog(id, text, buttons, utility, 0);

//  UUID , Menu ID, Menu
    list newstride = [id, menuid, REMOVEMENU];

    integer index = llListFindList(menuids, [id]);
    if (~index)
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    else
        menuids += newstride;
}

//NG lets send pings here and listen for pong replys
SendCommand(key id)
{
    if (llGetListLength(LISTENERS) >= 60)
        return;  // lets not cause "too many listen" error

    integer channel = getPersonalChannel(id, 1111);
    llRegionSayTo(id, channel, (string)id+ ":ping");
    LISTENERS += [ llListen(channel, "", "", "" )] ;// if we have a reply on the channel lets see what it is.
    llSetTimerEvent(5);// no reply by now, lets kick off the timer
}
processConfiguration(string data)
{
//  if we are at the end of the file
    if (data == EOF)
    {
    //  notify the owner
        llOwnerSay(configurationNotecardName+" card parsed");
        return;
    }
    if (data != "")//  if we are not working with a blank line
    {
        if (llSubStringIndex(data, "#") != 0)//  if the line does not begin with a comment
        {
            integer i = llSubStringIndex(data, "=");//  find first equal sign
            if (~i)//  if line contains equal sign
            {
                string name = llGetSubString(data, 0, i - 1);//  get name of name/value pair
                string value = llGetSubString(data, i + 1, -1);//  get value of name/value pair
                list temp = llParseString2List(name, [" "], []);
                name = llDumpList2String(temp, " ");//  trim name
                name = llToLower(name);//  make name lowercase (case insensitive)
                temp = llParseString2List(value, [" "], []);
                value = llDumpList2String(temp, " ");//  trim value
                if (name == "subname")//  subname
                    subname = value;
                else if (name == "subid")//  subid
                    subkey = value;
                else//  unknown name
                    llOwnerSay("\n\nUnknown configuration value: " + name + " on line " + (string)line);
            }
            else//  line does not contain equal sign
                llOwnerSay("\n\nConfiguration could not be read on line " + (string)line);
        }
    }
    if (subname=="")
        subname="????";
    if (subkey=="")
        subkey="00000000-0000-0000-0000-000000000000";
    AddSub(subkey,subname);
    notecardQueryId = llGetNotecardLine(configurationNotecardName, ++line);//  read the next line
}

default
{
    state_entry()
    {
        wearer = llGetOwner();  //Who are we
        wearerName = llKey2Name(wearer);  //thats our real name
        listener=llListen(getPersonalChannel(wearer,1111),"",NULL_KEY,""); //lets listen here

        llSleep(1.0);//giving time for others to reset before populating menu
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, "");
        //llOwnerSay("Type /7help for a HUD Guide, /7update for a update Guild, or /7owner for an Owners menu Setup Guide");
    }

    changed(integer change)
    {
//      reload on notcard changes should happen automaticly

        if (change & CHANGED_INVENTORY)
        {
            //llOwnerSay("\n\nReloading the "+configurationNotecardName+" card\n!");
            line = 0;
            notecardQueryId = llGetNotecardLine(configurationNotecardName, line);
        }

        if (change & CHANGED_OWNER)
            llResetScript();
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == MENUNAME_REQUEST && str == parentmenu)
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, "");
        //authenticate messages on COMMAND_NOAUTH
        if (num == COMMAND_OWNER)
        {
            //only owner may do these things

            if (str == "help")   llOwnerSay("\n\n\t[http://www.opencollar.at/ownerhud.html Owner HUD Manual]\n");
            //else if (str == "update") llGiveInventory(id, "OpenCollar Owner Update Guide");
            //else if (str == "owner")  llGiveInventory(id, "OpenCollar Owner HUD Ownermenu Guide");
            else if (str =="reset")
            {
                subs = [];
                //llOwnerSay("Type /7help for a HUD Guide, /7update for a update Guild, or /7owner for an Owners menu Setup Guide");
                llResetScript();
            }
        }
//          give the Owner menu here.  should let the dialog do whatever the chat commands do
        else if (num == SUBMENU && str == submenu)
            SubMenu(id);
        else if (num == SEND_CMD_SUB)
            SendCmd(id, str);
        else if (num == SEND_CMD_PICK_SUB)
        {
//          give a sub menu and send cmd to the sub picked
            integer length = llGetListLength(subs);
            if (length > 6)
            {
                pendingcmd = str;
                PickSubMenu(wearer,0);
            }
            else if (length == 4)
            {
                key sub = (key)llList2String(subs, 0);
                SendCmd(sub, str);
            }
            else
            {
//              you have 0 subs in list (empty)
                llMessageLinked(LINK_THIS, POPUP_HELP, "\n\nAdd someone first! I'm not currently managing anyone.\n\nwww.opencollar.at/owner-hud\n", wearer);
            }

        }
        else if (num == SEND_CMD_ALL_SUBS)
            SendAllCmd(str);
        else if (num == SEND_CMD_NEARBY_SUBS)
            SendNearbyCmd(str);
        else if (num == LOCALCMD_REQUEST)
            llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, llDumpList2String(localcmds, ","), "");
        else if (num == DIALOG_RESPONSE)
        {
            integer menuindex = llListFindList(menuids, [id]);
            if (~menuindex)
            {
//              got a menu response meant for us.  pull out values

                list    menuparams = llParseString2List(str, ["|"], []);
                        id         = (key)llList2String(menuparams, 0);
                string  message    = llList2String(menuparams, 1);
                integer page       = (integer)llList2String(menuparams, 2);
                string  menutype   = llList2String(menuids, menuindex + 1);

//              remove stride from menuids
//              we have to subtract from the index because the dialog id comes in the middle of the stride

                menuids = llDeleteSubList(menuids, menuindex - 1, menuindex - 2 + menustride);

                if (menutype == MAINMENU)
                {
                    if (message == UPMENU)
                    {
                        llMessageLinked(LINK_THIS, SUBMENU, parentmenu, id);
                        return;
                    }
                    else if (message == listcollars)  //Lets List out subs
                    {
                        list tmplist;
                        integer n;
                        integer length = llGetListLength(subs);
                        for (n = 0; n < length; n = n + 4)
                        tmplist += llList2List(subs, n + 1, n + 1);
                        llOwnerSay("\n\nI'm currently managing:\n\n" + llDumpList2String(tmplist, ", "));
                        SubMenu(id); //return to SubMenu
                    }
                    else if (message == removesub)  // Ok lets remove the sub from the Hud
                        RemoveSubMenu(id,page);
                    else if (message == loadnotecard)  // Ok lets load the subs from the notecard
                    {
                        if (llGetInventoryType(configurationNotecardName) != INVENTORY_NOTECARD)
                        {
                            //  notify owner of missing file
                            llOwnerSay("\n\nThe" + configurationNotecardName +" card couldn't be found in my inventory.\n");
                            return;
                        }
                        line = 0;
                        notecardQueryId = llGetNotecardLine(configurationNotecardName, line);
                        SubMenu(id); //return to SubMenu
                    }
                    else if (message == scansubs) //lets add new subbies
                    {
                     // Ping for auth OpenCollars in the region
                     //llOwnerSay("Starting to scan for collars");
                     AGENTS = llGetAgentList(AGENT_LIST_REGION, []); //scan for who is in the region.
                     integer i;
                     for (; i < llGetListLength(AGENTS); i++) //build a list of who to scan
                     {
                        // Lets not ping oursevles
                        // 1) wasteful
                        // 2) when ping reply listeners are added, then removed, our personal channel is removed
                        if (llList2Key(AGENTS,i) != wearer)
                            SendCommand(llList2Key(AGENTS, i)); //kick off "sendCommand" for each uuid
                     }
                     SubMenu(id); //return to SubMenu
                    }
                    else if (message == dumpsubs) //lets do a dump for adding to the Subs Notecard
                    {
                        string text = "\n#copy and paste this into your Subs notecard.\n# You need to add the name and Key of each person you wish to add to the hud.\n";
                        text+= "# The subname can be shortened to a name you like\n# The subid is their Key which can be obtained from their profile";
                        text+= "\n# This only adds the names to your hud, it does not mean you have access to their collar\n# Empty lines and lines beginning with '#' are ignored";
                        //lets pull the keys and names from the subs list
                        list tmplist;
                        integer n;
                        integer length = llGetListLength(subs);
                        for (n = -1; n < length; n = n + 4)
                        {
                            tmplist = llList2List(subs, n + 2, n + 2);
                            text+="\nsubname =  " + llDumpList2String(tmplist,"");
                            tmplist = llList2List(subs, n + 1, n + 1);
                            text+= "\nsubid = " + llDumpList2String(tmplist,"");
                        }
                        llOwnerSay(text);
                    }
                }
                else if (menutype == REMOVEMENU) // OK we want to remove a sub from the Hud
                {
                    integer index = llListFindList(subs, [message]);
                    if (message == UPMENU)
                        SubMenu(wearer);
                    else if (message == "Yes")
                        RemoveSub(removedSub);
                    else if (message == "No")
                        return;
                    else if (~index)
                    {
                        removedSub = (key)llList2String(subs, index - 1);
                        subname = llList2String(subs, index);
                        ConfirmSubRemove(id);
                    }
                }
                else if (menutype == PICKMENU)
                {
                    integer index = llListFindList(subs, [message]);
                    if (message == UPMENU)
                        SubMenu(wearer);
                    else if (message == ALLSUBS)
                        SendAllCmd(pendingcmd);
                    else if (~index)
                    {
                        subname = message;
                        key sub = (key)llList2String(subs, index - 1);
                        SendCmd(sub, pendingcmd);
                    }
                }
            }
        }
        /* else if (num == DIALOG_TIMEOUT)
        {
            integer menuindex = llListFindList(menuids, [id]);
            if (~menuindex)
                llOwnerSay("Main Menu timed out!");
        } */
        else if (num == DIALOG_URL)
            g_sDialogUrl = str;
    }

//  Now we have recieved something back from a ping lets break it down and see if it's for us.
    listen(integer channel, string name, key id, string msg)
    {
        if (llGetSubString(msg, 36, 40)==":pong")
        {
            key    subId   = llGetOwnerKey(id);
            string subName = llKey2Name(subId);

            if (subName == "")
                subName="????";

            //llOwnerSay(subName+" has been detected.");
            AddSub(subId,subName);
        }
    }

    on_rez(integer start_param)
    {
        llSleep(2.0);

        //llOwnerSay("Type these commands on channel 7:\n\t/7help for a HUD Guide\n\t/7update for an update Guide\n\t/7owner for an owners menu Setup Guide");
    }

//  clear things after ping
    timer()
    {
        llSetTimerEvent(0);
        AGENTS = [];
        integer n = llGetListLength(LISTENERS) - 1;
        for (; n >= 0; n--)
            llListenRemove(llList2Integer(LISTENERS,n));
        LISTENERS = [];
    }

    dataserver(key request_id, string data)
    {
        if (request_id == notecardQueryId)
            processConfiguration(data);
    }
}