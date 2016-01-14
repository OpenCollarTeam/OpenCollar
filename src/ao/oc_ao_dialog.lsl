//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//       AO Dialog - 150603.1            .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Nandana Singh, Wendy Starfall, littlemousy,   //
//  Garvin Twine et al.                                                     //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//           github.com/OpenCollar/opencollar/tree/master/src/ao            //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//an adaptation of Schmobag Hogfather's SchmoDialog script


//MESSAGE MAP
//integer CMD_ZERO = 0;
//integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CHAT = 505;//deprecated
//integer CMD_OBJECT = 506;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer SUBMENU = 3002;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLVR_CMD = 6010;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
//integer RLV_VERSION = 6003; //RLV Plugins can recieve the used rl viewer version upon receiving this message..

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer pagesize = 12;
string MORE = "►";
string PREV = "◄";
string UPMENU = "BACK"; // string to identify the UPMENU button in the utility buttons
//string SWAPBTN = "swap";
//string SYNCBTN = "sync";
string BLANK = " ";
integer timeout = 300;
integer repeat = 5;//how often the timer will go off, in seconds

list menus;//9-strided list in form listenchannel, dialogid, listener, starttime, recipient, prompt, list buttons, utility buttons, currentpage
//where "list buttons" means the big list of choices presented to the user
//and "page buttons" means utility buttons that will appear on every page, such as one saying "go up one level"
//and "currentpage" is an integer meaning which page of the menu the user is currently viewing

integer stridelength = 9;

key g_keyWearer;

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_keyWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}


list CharacterCountCheck(list in, key ID)
// checks if any of the times is over 24 characters and removes them if needed
{
    list out;
    string s;
    integer i;
    integer m=llGetListLength(in);
    for (i=0;i<m;i++)
    {
        s=llList2String(in,i);
        if (llStringLength(s)>24)
        {
            Notify(ID, "The following button is longer than 24 characters and has been removed (can be caused by the name length of the item in the collars inventory): "+s, TRUE);
        }
        else
        {
            out+=[s];
        }     
    }
    return out;
    
}


integer RandomUniqueChannel()
{
    integer out = llRound(llFrand(10000000)) + 100000;
    if (~llListFindList(menus, [out]))
    {
        out = RandomUniqueChannel();
    }
    return out;
}

Dialog(key recipient, string prompt, list menuitems, list utilitybuttons, integer page, key id)
{
    string thisprompt; //= " (Timeout in " + (string)timeout + " seconds.)";
    list buttons;
    list currentitems;
    integer numitems = llGetListLength(menuitems);
    integer start;
    integer mypagesize = pagesize - llGetListLength(utilitybuttons);
        
    //slice the menuitems by page
    if (numitems > mypagesize)
    {
        mypagesize=mypagesize-2;//we'll use two slots for the MORE and PREV button, so shrink the page accordingly
        start = page * mypagesize;
        integer end = start + mypagesize - 1;
        //multi page menu
        //currentitems = llList2List(menuitems, start, end);
        buttons = llList2List(menuitems, start, end);
        thisprompt = " Page "+(string)(page+1)+"/"+(string)(((numitems-1)/mypagesize)+1);
    }
    else
    {
        start = 0;
        buttons = menuitems;
    }
    
    // check promt lenghtes
    integer lprompt=llStringLength(prompt);
    if (lprompt>511)
    {
        Notify(recipient,"The dialog prompt message is longer than 512 characters. It wil be truncated to 512 characters.",TRUE);
        prompt=llGetSubString(prompt,0,510);
        thisprompt = prompt;
    }
    else if (lprompt + llStringLength(thisprompt)<= 512)
    {
        thisprompt= prompt + thisprompt;
    }
    else
    {
        thisprompt= prompt;
    }
    
    //integer stop = llGetListLength(currentitems);
    //integer n;
    //for (n = 0; n < stop; n++)
    //{
    //    string name = llList2String(menuitems, start + n);
    //    buttons += [name];
    //}
    

    
    buttons = SanitizeButtons(buttons);
    utilitybuttons = SanitizeButtons(utilitybuttons);
    
    integer channel = RandomUniqueChannel();
    integer listener = llListen(channel, "", recipient, "");
    llSetTimerEvent(repeat);
    if (numitems > mypagesize)
    {
        llDialog(recipient, thisprompt, PrettyButtons(buttons, utilitybuttons,[PREV,MORE]), channel);      
    }
    else
    {
        llDialog(recipient, thisprompt, PrettyButtons(buttons, utilitybuttons,[]), channel);
    }    
    integer ts = llGetUnixTime() + timeout;
    menus += [channel, id, listener, ts, recipient, prompt, llDumpList2String(menuitems, "|"), llDumpList2String(utilitybuttons, "|"), page];
}

list SanitizeButtons(list in)
{
    integer length = llGetListLength(in);
    integer n;
    for (n = length - 1; n >= 0; n--)
    {
        integer type = llGetListEntryType(in, n);
        if (llList2String(in, n) == "") //remove empty strings
        {
            in = llDeleteSubList(in, n, n);
        }        
        else if (type != TYPE_STRING)        //cast anything else to string
        {
            in = llListReplaceList(in, [llList2String(in, n)], n, n);
        }
    }
    return in;
}

list PrettyButtons(list options, list utilitybuttons, list pagebuttons)
{//returns a list formatted to that "options" will start in the top left of a dialog, and "utilitybuttons" will start in the bottom right
    list spacers;
    list combined = options + utilitybuttons + pagebuttons;
    while (llGetListLength(combined) % 3 != 0 && llGetListLength(combined) < 12)    
    {
        spacers += [BLANK];
        combined = options + spacers + utilitybuttons + pagebuttons;
    }
    // check if a UPBUTTON is present and remove it for the moment
    integer u = llListFindList(combined, [UPMENU]);
    if (u != -1)
    {
        combined = llDeleteSubList(combined, u, u);
    }
    
    list out = llList2List(combined, 9, 11);
    out += llList2List(combined, 6, 8);
    out += llList2List(combined, 3, 5);    
    out += llList2List(combined, 0, 2);    

    //make sure we move UPMENU to the lower right corner
    if (u != -1)
    {
        out = llListInsertList(out, [UPMENU], 2);
    }

    return out;    
}


list RemoveMenuStride(list menu, integer index)
{
    //tell this function the menu you wish to remove, identified by list index
    //it will close the listener, remove the menu's entry from the list, and return the new list
    //should be called in the listen event, and on menu timeout    
    integer listener = llList2Integer(menu, index + 2);
    llListenRemove(listener);
    return llDeleteSubList(menu, index, index + stridelength - 1);
}

CleanList()
{
    //debug("cleaning list");
    //loop through menus and remove any whose timeouts are in the past
    //start at end of list and loop down so that indices don't get messed up as we remove items
    integer length = llGetListLength(menus);
    integer n;
    integer now = llGetUnixTime();
    for (n = length - stridelength; n >= 0; n -= stridelength)
    {
        integer dietime = llList2Integer(menus, n + 3);
        //debug("dietime: " + (string)dietime);
        if (now > dietime)
        {
            debug("menu timeout");                
            key id = llList2Key(menus, n + 1);
            llMessageLinked(LINK_SET, DIALOG_TIMEOUT, "", id);
            menus = RemoveMenuStride(menus, n);
        }            
    } 
}

ClearUser(key rcpt)
{
    //find any strides belonging to user and remove them
    integer index = llListFindList(menus, [rcpt]);
    while (~index)
    {
        debug("removed stride for " + (string)rcpt);
        menus = llDeleteSubList(menus, index - 4, index - 5 + stridelength);
        index = llListFindList(menus, [rcpt]);
    }
    debug(llDumpList2String(menus, ","));
}

debug(string str)
{
    //llOwnerSay(llGetScriptName() + ": " + str);
}

default
{    
    state_entry()
    {
        g_keyWearer=llGetOwner();
    }

    on_rez(integer param)
    {
        llResetScript();
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == DIALOG)
        {//give a dialog with the options on the button labels
            //str will be pipe-delimited list with rcpt|prompt|page|backtick-delimited-list-buttons|backtick-delimited-utility-buttons
            debug(str);
            list params = llParseStringKeepNulls(str, ["|"], []);
            key rcpt = (key)llList2String(params, 0);
            string prompt = llList2String(params, 1);
            integer page = (integer)llList2String(params, 2);
            list lbuttons = CharacterCountCheck(llParseStringKeepNulls(llList2String(params, 3), ["`"], []), rcpt);
            list ubuttons = SanitizeButtons(llParseStringKeepNulls(llList2String(params, 4), ["`"], []));        
            
            //first clean out any strides already in place for that user.  prevents having lots of listens open if someone uses the menu several times while sat
            ClearUser(rcpt);
            //now give the dialog and save the new stride
            Dialog(rcpt, prompt, lbuttons, ubuttons, page, id);
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        integer menuindex = llListFindList(menus, [channel]);
        if (~menuindex)
        {
            key menuid = llList2Key(menus, menuindex + 1);
            key av = llList2Key(menus, menuindex + 4);
            string prompt = llList2String(menus, menuindex + 5);            
            list items = llParseStringKeepNulls(llList2String(menus, menuindex + 6), ["|"], []);
            list ubuttons = llParseStringKeepNulls(llList2String(menus, menuindex + 7), ["|"], []);
            integer page = llList2Integer(menus, menuindex + 8);    
            menus = RemoveMenuStride(menus, menuindex);       
                   
            if (message == MORE)
            {
                debug((string)page);
                //increase the page num and give new menu
                page++;
                integer thispagesize = pagesize - llGetListLength(ubuttons) - 2;
                if (page * thispagesize >= llGetListLength(items))
                {
                    page = 0;
                }
                Dialog(id, prompt, items, ubuttons, page, menuid);
            }
            else if (message == PREV)
            {
                debug((string)page);
                //increase the page num and give new menu
                page--;

                if (page < 0)
                {
                    integer thispagesize = pagesize - llGetListLength(ubuttons) - 2;

                    page = (llGetListLength(items)-1)/thispagesize;
                }
                Dialog(id, prompt, items, ubuttons, page, menuid);
            }
            else if (message == BLANK)
            {
                //give the same menu back
                Dialog(id, prompt, items, ubuttons, page, menuid);
            }            
            else
            {
                llMessageLinked(LINK_SET, DIALOG_RESPONSE, (string)av + "|" + message + "|" + (string)page, menuid);
            }  
        }
    }
    
    timer()
    {
        CleanList();    
        
        //if list is empty after that, then stop timer
        
        if (!llGetListLength(menus))
        {
            debug("no active dialogs, stopping timer");
            llSetTimerEvent(0.0);
        }
    }
}
