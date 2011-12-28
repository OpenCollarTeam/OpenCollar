/*
string broadcasturl = "http://web.mycollar.org/lookup/get/";
string cmdurl = "http://web.mycollar.org/";
string dburl = "http://web.mycollar.org/owners/getsubspages";
string removeurl = "http://data.mycollar.org/removesub/";

key broadcast_request;
key command_request;
string currenturl = "";
*/
key currentsub = "";

string g_sDialogUrl;

/*
RequestURL(key av)
{
    if(av == NULL_KEY) return;
    broadcast_request = llHTTPRequest(broadcasturl + "?key=" + (string)av, [HTTP_METHOD, "GET"], "");
    debug("Requesting URL for access: " + (string)av);
}
*/

list cmdqueue;// requset, id, cmd, type

/*
integer HTTP_IN_CMD = 1;
integer HTTP_IN_URL = 2;
*/

integer checkdelay = 600;

//on startup, get list of subs from db
//on receiving sendcmd link message, send to specified sub

integer debugging=FALSE; // show debug messages

//key httpid;
//key removeid;

list subs;//strided list in the form key,name
string tmpname; //used temporarily to store new owner or secowner name while retrieving key
list localcmds = ["removesub","listsubs", "reloadlist","help"];//these will be told to the listener on LOCALCMD_REQUEST, so it knows not to pass them through the remote

string parentmenu = "Main";
string submenu = "Subs";

key subkey = NULL_KEY;
string subname;

key queueid;

integer listenchannel = 802930;//just something i randomly chose
integer picksubchannel = 3264589;
integer removesubchannel = 32645891;
//integer objectchannel = -1812221819; // -- Depreciated with new personalized object channel
integer listener;
integer timeout = 90;
string pendingcmd;//save cmd here while we give the sub menu to decide who to send it to

//news system stuff
key newslistid;
list article_ids;

//MESSAGE MAP
integer COMMAND_OWNER = 500;

integer POPUP_HELP = 1001;

integer HTTPDB_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer HTTPDB_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer HTTPDB_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer HTTPDB_DELETE = 2003;//delete token from DB
integer HTTPDB_EMPTY = 2004;//sent when a token has no value in the httpdb

integer SUB_LIST = 2005;

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
integer CMD_AUTO_TP = -1004;
integer SEND_CMD_SUB = -1005;
integer SEND_CMD_NEARBY_SUBS = -1006;

integer LOCALCMD_REQUEST = -2000;
integer LOCALCMD_RESPONSE = -2001;

integer DIALOG_URL = -2002;

string UPMENU = "^";
string MORE = ">";

string listsubs = "List Subs";
string removesub="Remove Sub";
string reloadlist="Reload Subs";
string scansubs="Scan Subs";

string ALLSUBS = "*All*";
string currentmenu;
key removedSub;
key wearer;
string wearerName;
integer isAutoTPCommand = FALSE;
list menuids;//three strided list of avkey, dialogid, and menuname
integer menustride = 3;
// Use these to keep track of your current menu
// Use any variable name you desire
string MAINMENU = "SubMenu";
string PICKMENU = "PickSub";
string REMOVEMENU = "RemoveSub";

debug(string str)
{
    if (debugging) llOwnerSay(str);
}

// Yay for Cleo and Jessenia – Personal Object Channel!
integer getPersonalChannel(key owner, integer nOffset)
{
    integer chan = (integer)("0x"+llGetSubString((string)owner,2,7)) + nOffset;
    if (chan>0)
    {
        chan=chan*(-1);
    }
    if (chan > -10000)
    {
        chan -= 30000;
    }
    return chan;
}


integer InSim(key id)
{
    return llKey2Name(id) != "";
}

Popup(key id, string message)
{
    //one-way popup message.  don't listen for these anywhere
    llDialog(id, message, [], 298479);
}

SendIM(key dest, string message)
{ // I know this wrapper function looks lame, but it's here so we can transition to IM slaves driven by link message, if need be.
    // oh and it's legacy code from the collar, where we used to do that.
    llInstantMessage(dest, message);
}

SendCmd(key id, string cmd, integer all)
{
    // string subName = llKey2Name(id);
    subname = llList2String(subs,(llListFindList(subs,[(string)id]))+1);
    if (InSim(id))
    {
        cmd = (string)id + ":" + cmd;
        llRegionSay(getPersonalChannel(id,1111), cmd);
        if(!all)
        {
            llOwnerSay("Sending command '" + cmd + " to " + subname);
        }
        debug("llRegionSaying " + cmd);
    }
/*
    else
    {
        integer index = llListFindList(subs, [(string)id]);
        string path = (string)id;
        //queueid = llHTTPRequest(cmdurl + path, [HTTP_METHOD, "PUT"], cmd);
        string httpurl = llList2String(subs, index+2);
        if (llGetSubString(cmd, 0, 5) == "menuto")
        {
            cmd = "remotemenu:url:" + g_sDialogUrl;
        }
        if (httpurl == "None")
        {
            if (llGetUnixTime() > llList2Integer(subs, index + 3)+checkdelay)
            {
                queueid = llHTTPRequest(broadcasturl + "?key=" + (string)id, [HTTP_METHOD, "GET"], "");
                cmdqueue += [queueid, id, cmd, HTTP_IN_URL];
                debug("no url and not checked in last 10 min");
            }
            else
            {
                queueid = llHTTPRequest(cmdurl + path, [HTTP_METHOD, "PUT"], cmd);
                debug("no url and checked in last 10 min");
            }
        }
        else
        {
            queueid = llHTTPRequest(httpurl + "/" + (string)wearer, [HTTP_METHOD, "POST"], cmd);
            cmdqueue += [queueid, id, cmd, HTTP_IN_CMD];
            debug("trying url:"+httpurl + "/" + (string)wearer+" with cmd:"+cmd+" id:"+(string)id+" index:"+(string)index);
            debug(llDumpList2String(subs, "! "));
        }
        if(!all)
        {
//            if(llGetSubString(cmd, 0, 10) == "remotemenu:")
//            {
//                //do nothing
//            }
//            else 
            if(llGetSubString(cmd, 0, 5) == "menuto")
            {
                llOwnerSay("Sending command '" + cmd + " to " + subname + ". Please be aware "+ subname + " has to be online and the http/remote on for the menu to pop up.");
            }
//            else
//            {
//                llOwnerSay("Sending command '" + cmd + " to " + subname + ".Please be aware "+ subname + " has to be online and it may take up to 60 seconds for the command to reach the sub.");
//            }
        }
        debug("web queueing " + cmd + " for " + path);
    }
    */
}

SendNearbyCmd(string cmd)
{
    integer n;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
    {
        key id = (key)llList2String(subs, n);
        if(id != wearer && InSim(id)) //prevent to send commands to yourself, don't expose out-of-sim subs
        {
            SendCmd(id, cmd, TRUE);
            //llSay(objectchannel, cmd);
        }
    }
}

SendAllCmd(string cmd)
{
    integer n;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
    {
        key id = (key)llList2String(subs, n);
        if(id != wearer) //prevent to send commands to yourself
        {
            SendCmd(id, cmd, TRUE);
        }
    }
}

AddSub(key id, string name)
{
        
    if (llListFindList(subs,[id])!=-1) return;
    if( llStringLength(name) >= 24) name=llStringTrim(llGetSubString(name, 0, 23),STRING_TRIM);
    subs+=[id,name,"***","***"];
    llOwnerSay(name+" has been registered.");
}

RemoveSub(key subbie)
{
//    removeid = llHTTPRequest(removeurl+(string)subbie, [HTTP_METHOD, "DELETE"], "");
//    debug(removeurl+(string)subbie);
//    llOwnerSay("Request to remove your sub has been sent. Please wait ...");
    integer index = llListFindList(subs,[subbie]);
    if (index!=-1)
    {
        subs=llDeleteSubList(subs,index, index+3);
        SendCmd(subbie, "remowners "+wearerName, FALSE);
        SendCmd(subbie, "remsecowner "+wearerName, FALSE);
//        remsecowner
        
    }
}

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


SubMenu(key id) // Single page menu
{
    string text = "Pick an option.";
    //prompt += "  (Menu will time out in " + (string)timeout + " seconds.)\n";

    //list subs in prompt just fyi
    integer n;
    integer stop = llGetListLength(subs);
    text += "Current subs:";
    for (n = 0; n < stop; n = n + 4)
    {
        text += "\n" + llList2String(subs, n + 1);
    }

    list buttons;
    //add sub
    //buttons += [listsubs,removesub,reloadlist];
    buttons += [listsubs,removesub,scansubs];

    //parent menu
    list utility = [UPMENU];
    
    if(llStringLength(text) > 511) // Check text length so we can warn for it being too long before hand.
     {
         llOwnerSay("**** Too many submissives, not all names may appear. ****");
         text = llGetSubString(text,0,510);
     }
    key menuid = Dialog(id, text, buttons, utility, 0);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, MAINMENU];
    
    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(menuids, [id]);
    if (index == -1)
    {
        menuids += newstride;
    }
    else
    { //this person is already in the dialog list.  replace their entry
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    }    
    
}

PickSubMenu(key id, integer page) // Multi-page menu
{
    string text = "Pick the sub you wish to send the command to.";
    //prompt += "  (Menu will time out in " + (string)timeout + " seconds.)\n";
    list buttons = [ALLSUBS];
    //add subs
    integer n;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
    {
        buttons += [llList2String(subs, n + 1)];
    }
    //parent menu
    list utility = [UPMENU];
    
    key menuid = Dialog(id, text, buttons, utility, page);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, PICKMENU];
    
    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(menuids, [id]);
    if (index == -1)
    {
        menuids += newstride;
    }
    else
    { //this person is already in the dialog list.  replace their entry
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    }       
}

RemoveSubMenu(key id, integer page) // Multi-page menu
{
    string text = "Pick the sub you wish to remove from your hud. This will also delete you from the owners of the collar.";
    //prompt += "  (Menu will time out in " + (string)timeout + " seconds.)\n";
    //add subs
    integer n;
    list buttons;
    integer stop = llGetListLength(subs);
    for (n = 0; n < stop; n = n + 4)
    {
        buttons += [llList2String(subs, n + 1)];
    }

    //parent menu
    list utility = [UPMENU];
    
    key menuid = Dialog(id, text, buttons, utility, page);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, REMOVEMENU];
    
    // Check dialogs for previous entry and update if needed
    integer index = llListFindList(menuids, [id]);
    if (index == -1)
    {
        menuids += newstride;
    }
    else
    { //this person is already in the dialog list.  replace their entry
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    }
}

ConfirmSubRemove(key id) // Single page menu
{
    string text = "Please confirm that you really want to remove " + subname + " as your sub. This will also remove you from " + subname + "'s collar as owner.";

    list buttons = ["Yes", "No"];
    integer stop = llGetListLength(subs);
    list utility = [];
    
    key menuid = Dialog(id, text, buttons, utility, 0);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, REMOVEMENU];

    integer index = llListFindList(menuids, [id]);
    if (index == -1)
    {
        menuids += newstride;
    }
    else
    {
        menuids = llListReplaceList(menuids, newstride, index, index - 1 + menustride);
    } 
}

default
{
    state_entry()
    {
        wearer = llGetOwner();
        wearerName = llKey2Name(wearer);
        listener=llListen(getPersonalChannel(wearer,1111),"","","");
        
        subs = [];
        //httpid = llHTTPRequest(dburl, [HTTP_METHOD, "GET"], "");
        //newslistid = llHTTPRequest(”http://collardata.appspot.com/news/check”, [HTTP_METHOD, "GET"], “”); // — Depreciated 
        llOwnerSay("Type /7 help for a HUD Guide.");
        llSleep(1.0);//giving time for others to reset before populating menu
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
    }
    link_message(integer sender, integer num, string str, key id)
    {
        debug("Link Message: num=" + (string)num + " str=" + str);
        //authenticate messages on COMMAND_NOAUTH
        if (num == COMMAND_OWNER)
        {
            //only owner may do these things

            if (str == "listsubs")
            {
                //say subs
                list tmplist;
                integer n;
                integer length = llGetListLength(subs);
                for (n = 0; n < length; n = n + 4)
                {
                    tmplist += llList2List(subs, n + 1, n + 1);
                }
                llOwnerSay("Subs: " + llDumpList2String(tmplist, ", "));
            }
            else if (str == "help")
            {
                llGiveInventory(id, "OpenCollar Owner HUD Guide");
            }
        }
        else if (num == HTTPDB_RESPONSE)
        {
            list params = llParseString2List(str, ["="], []);
            string token = llList2String(params, 0);
            string value = llList2String(params, 1);
            if (token == "subs")
            {
                subs = llParseString2List(value, [","], []);
            }
        }
        else if (num == MENUNAME_REQUEST && str == parentmenu)
        {
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        }
        else if (num == SUBMENU && str == submenu)
        {
            //request sub list here if empty.  better than doing it on startup
            if (!llGetListLength(subs))
            {
                llMessageLinked(LINK_THIS, HTTPDB_REQUEST, "subs", NULL_KEY);
            }
            //give the Owner menu here.  should let the dialog do whatever the chat commands do
            SubMenu(id);
        }
        else if (num == SEND_CMD_SUB)
        {
            SendCmd(id, str, FALSE);
        }
        else if (num == SEND_CMD_PICK_SUB)
        {
            //if only one sub in list, send to that one
            //else give a sub menu and send cmd to the sub picked
            integer length = llGetListLength(subs);
            if (length > 2)
            {
                if(llGetSubString(str, 0, 6) == "autotp|")
                {
                    pendingcmd = llGetSubString(str, 6, -1);
                    isAutoTPCommand = TRUE;
                }
                else
                {
                    pendingcmd = str;
                    isAutoTPCommand = FALSE;
                }
                PickSubMenu(wearer,0);
            }
            else if (length == 2)
            {
                key sub = (key)llList2String(subs, 0);
                //string name = llList2String(subs, 1);
                SendCmd(sub, str, FALSE);
                //llOwnerSay("Sending command '" + str + " to " + name + ".Please be aware "+ name + " has to be online and it may take up to 60 seconds for the command to reach the sub.");
            }
            else
            {
                //you have 0 subs in list (empty), or 1 (which shouldn't ever happen)
                llMessageLinked(LINK_THIS, POPUP_HELP, "Cannot send command because you have no subs (according to the database).  Choose \"Reload Subs\" in the Subs menu after being set as owner or secowner on an OpenCollar.", wearer);
            }

        }
        else if (num == SEND_CMD_ALL_SUBS)
        {
            SendAllCmd(str);
        }
        else if (num == SEND_CMD_NEARBY_SUBS)
        {
            SendNearbyCmd(str);
        }
        else if (num == LOCALCMD_REQUEST)
        {
            llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, llDumpList2String(localcmds, ","), NULL_KEY);
        }
        else if (num == DIALOG_RESPONSE)
        {
            integer menuindex = llListFindList(menuids, [id]);
            if (menuindex != -1)
            {
                //got a menu response meant for us.  pull out values
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);          
                string message = llList2String(menuparams, 1);                                         
                integer page = (integer)llList2String(menuparams, 2);
                string menutype = llList2String(menuids, menuindex + 1);
                //remove stride from menuids
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                menuids = llDeleteSubList(menuids, menuindex - 1, menuindex - 2 + menustride);    
                
                if (menutype == MAINMENU)
                {
                    if (message == UPMENU)
                    {
                        llMessageLinked(LINK_THIS, SUBMENU, parentmenu, id);
                        return;
                    }
                    else if (message == listsubs)
                    {
                        llMessageLinked(LINK_THIS, COMMAND_OWNER, "listsubs", id);
                        SubMenu(id);
                    }
                    else if (message == removesub)
                    {
                        RemoveSubMenu(id,page);
                    }
                    else if (message == reloadlist)
                    {
                        /*
                        subs = [];
                        httpid = llHTTPRequest(dburl, [HTTP_METHOD, "GET"], "");
                        llOwnerSay( "The list of subs gets reloaded. Please wait a moment before you activate the hud again ...");
                        */
                    }
                    else if (message == scansubs)
                    {
                        llSensor("",NULL_KEY,AGENT,20,PI);
                        SubMenu(id);
                    }
                    
                }
                else if (menutype == REMOVEMENU)
                {
                    integer index = llListFindList(subs, [message]);
                    if (message == UPMENU)
                    {
                        SubMenu(wearer);
                    }
                    else if(message == "Yes")
                    {
                        RemoveSub(removedSub);
                    }
                    else if(message == "No")
                    {
                        return;
                    }
                    else if (index != -1)
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
                    {
                        SubMenu(wearer);
                    }
                    else if (message == ALLSUBS)
                    {
                        if(isAutoTPCommand)
                        {
                            llMessageLinked(LINK_THIS, CMD_AUTO_TP, message, NULL_KEY);
                        }
                        else
                        {
                            SendAllCmd(pendingcmd);
                        }
                        //llOwnerSay("Sending command '" + pendingcmd + "' to all subs.");
                    }
                    else if (index != -1)
                    {
                        subname = message;
                        key sub = (key)llList2String(subs, index - 1);
                        if(isAutoTPCommand)
                        {
                            llMessageLinked(LINK_THIS, CMD_AUTO_TP, message, sub);
                        }
                        else
                        {
                            SendCmd(sub, pendingcmd, FALSE);
                        }
                        //llOwnerSay("Sending command '" + pendingcmd + "' to " + message + ".");
                    }
                }
            }
        }
        else if (num == DIALOG_TIMEOUT)
        {
            integer menuindex = llListFindList(menuids, [id]);
            if (menuindex != -1)
            {
                llInstantMessage(llGetOwner(), "Menu timed out!");
            }
        }
        else if (num == DIALOG_URL)
        {
            g_sDialogUrl = str;
            debug("dialog url:"+str);
        }
    }
/*
    http_response(key id, integer status, list meta, string body)
    {
        integer cmdindex = llListFindList(cmdqueue, [id]);
        if (id == httpid)
        {
            if (status == 200)
            {
                if (llStringLength(body))
                {
                    list lTemp = llParseString2List(body, [","], []);
                    if (llList2String(lTemp, -2) == "more")
                    {
                        
                        httpid = llHTTPRequest(dburl+"?page="+llList2String(lTemp, -1), [HTTP_METHOD, "GET"], "");
                        lTemp = llDeleteSubList(lTemp, -2, -1);
                    }
                    subs += lTemp;
                    //send the list to the other script ie camera
                    llMessageLinked(LINK_SET, SUB_LIST, body, "");
                    //loop through subs, announcing them
                    integer n;
                    integer stop = llGetListLength(lTemp);
                    string out = "Loaded sub(s) ";
                    for (n = 0; n < stop; n = n + 4)
                    {
                        string subName = llList2String(lTemp, n + 1);
                        if (n)
                        {//precede all but first with comma, space
                            out += ", ";
                        }

                        out += subName;
                        if( llStringLength(subName) >= 24)
                        {
                            integer iIndex = llListFindList(subs, [subName]);
                            subs = llListReplaceList(subs, [llGetSubString(subName, 0, 23)], iIndex, iIndex);
                        }
                    }
                    out += " from database.";
                    llOwnerSay(out);
                }
                else
                {
                    llOwnerSay("No subs found in database.");
                }
            }
            else
            {
                llOwnerSay("Error: " + body);
            }
        }
        else if (id == newslistid)//is this used?
        {
            list articlekeys = llParseString2List(body, ["\n"], []);
            integer n;
            integer stop = llGetListLength(articlekeys);
            for (n = 0; n < stop; n++)
            {
                string articlekey = llList2String(articlekeys, n);
                article_ids += [llHTTPRequest("http://collardata.appspot.com/news/article/" + articlekey, [HTTP_METHOD, "GET"], "")];
            }
        }
        else if (id == removeid)
        {
            debug("Removing status:"+(string)status+";"+body);
            if (status==200)
            {
                if (body=="0")
                {
                    llOwnerSay("Sorry, no subs where removed!");
                }
                else
                {
                    string s;
                    string s2;
                    if (body =="1")
                    {
                        s="You have been removed as primary owner from ";
                        s2 = "primary owner";
                    }
                    else if (body =="2")
                    {
                        s="You have been removed as secondary owner from ";
                        s2 = "secondary owner";
                    }
                    if (body =="3")
                    {
                        s="You have been removed as primary and secondary owner from ";
                        s2 = "primary and secondary owner";
                    }
                    integer index = llListFindList(subs, [(string)removedSub]);
                    if(index != -1)
                    {
                        subs = llListReplaceList(subs, [], index -1, index);
                    }
                    llOwnerSay(s + subname + "'s collar. The sublist will now be reloaded!");
                    subs = [];
                    httpid = llHTTPRequest(dburl, [HTTP_METHOD, "GET"], "");
                    llInstantMessage(removedSub, wearerName + " has removed her/himself from your collar as " + s2 + ". To reflect this change in your collar you have to reattach your collar or " + wearerName + " will remain as " + s2 + " until your next relog.");
                    removedSub = NULL_KEY;

                }
            }
            else
            {
                llOwnerSay("Sorry, there where problems with removing subs");

            }
        }
        else if(cmdindex != -1)
        {
            string subid = llList2String(cmdqueue, cmdindex + 1);
            string cmd = llList2String(cmdqueue, cmdindex + 2);
            integer type = llList2Integer(cmdqueue, cmdindex + 3);
            if (type == HTTP_IN_URL)
            {
                integer subindex = llListFindList(subs, [llList2String(cmdqueue, cmdindex + 1)]);
                string currenturl = llList2String(subs, subindex + 2);
                if(body == "None" || body == currenturl)
                {
                    debug("no new url");
                    queueid = llHTTPRequest(cmdurl + subid, [HTTP_METHOD, "PUT"], cmd);
                    cmdqueue = llDeleteSubList(cmdqueue, cmdindex, cmdindex + 3);
                }
                else
                {
                    debug("trying new url:"+body);
                    queueid = llHTTPRequest(body + "/" + (string)wearer, [HTTP_METHOD, "POST"], cmd);
                    cmdqueue = llListReplaceList((cmdqueue = []) + cmdqueue, [queueid, subid, cmd, HTTP_IN_CMD], cmdindex, cmdindex + 3);
                }
                subs = llListReplaceList((subs = []) + subs, [body, llGetUnixTime()], subindex + 2, subindex + 3);
            }
            else if (type == HTTP_IN_CMD)
            {
                if (status == 404)
                {
                    debug("needs new url");
                    queueid = llHTTPRequest(broadcasturl + "?key=" + subid, [HTTP_METHOD, "GET"], "");
                    cmdqueue = llListReplaceList((cmdqueue = []) + cmdqueue, [queueid, subid, cmd, HTTP_IN_URL], cmdindex, cmdindex + 3);
                }
                else if (status == 200)
                {
                    if (body == "Command Recieved")
                    {
                        debug("url worked");
                        cmdqueue = llDeleteSubList(cmdqueue, cmdindex, cmdindex + 3);
                    }
                    else
                    {
                        debug("There was an error:" + body);
                        cmdqueue = llDeleteSubList(cmdqueue, cmdindex, cmdindex + 3);
                        queueid = llHTTPRequest(cmdurl + subid, [HTTP_METHOD, "PUT"], cmd);
                    }
                }
                else
                {
                    debug("There was an error status:" + (string)status +"\n body:"+ body);
                    cmdqueue = llDeleteSubList(cmdqueue, cmdindex, cmdindex + 3);
                    queueid = llHTTPRequest(cmdurl + subid, [HTTP_METHOD, "PUT"], cmd);
                }
            }
        }
        else
        {
            integer newsindex = llListFindList(article_ids, [id]);
            if (newsindex != -1)
            {
                llOwnerSay(body);
                article_ids = llDeleteSubList(article_ids, newsindex, newsindex);
            }
        }
    }
*/
    sensor(integer num)
    {
        integer i=num;
        while(i>0)
        {
            i--;
            key id=llDetectedKey(i);
            llSay(getPersonalChannel(id,1111),(string)id+":ping");
            //llSay(0,llDetectedName(i));
        }
    }
    listen(integer channel, string name, key id, string msg)
    {
        if (llGetSubString(msg,36,40)==":pong")
        {
            key subId=llGetOwnerKey(id);
            string subName=llKey2Name(subId);
            if (subName=="") subName="????";
            llOwnerSay(subName+" has been detected."); 
            AddSub(subId,subName);
        } 
    }
    on_rez(integer param)
    {
        if (llGetOwner()!=wearer) llResetScript();
    }
}