//listener
list localcmds = ["channel"];//commands that get passed to COMMAND_OWNER.  All others get passed through
integer listenchannel = 7;

integer listener;

//MESSAGE MAP
integer COMMAND_OWNER = 500;
integer POPUP_HELP = 1001;
integer SEND_CMD_PICK_SUB = -1002;
integer SEND_CMD_ALL_SUBS = -1003;

integer LOCALCMD_REQUEST = -2000;
integer LOCALCMD_RESPONSE = -2001;

SetListeners()
{
    llListenRemove(listener);  
    listener = llListen(listenchannel, "", llGetOwner(), "");
}

string StringReplace(string src, string from, string to)
{//replaces all occurrences of 'from' with 'to' in 'src'.
//Ilse: blame/applaud Strife Onizuka for this godawfully ugly though apparently optimized function
    integer len = (~-(llStringLength(from)));
    if(~len)
    {
        string  buffer = src;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(to)));
        @loop;//instead of a while loop, saves 5 bytes (and run faster).
        integer to_pos = ~llSubStringIndex(buffer, from);
        if(to_pos)
        {
            buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        }
    }
    return src;
}

default
{
    state_entry()
    {
        SetListeners();
        llSleep(1.0);//wait a sec before asking for localcmds so other scripts have a change to reset too
        llMessageLinked(LINK_SET, LOCALCMD_REQUEST, "", NULL_KEY);
    }
    
    listen(integer channel, string name, key id, string message)
    {
        string cmd = llList2String(llParseString2List(message, [" "], []), 0);
        if (~llListFindList(localcmds, [cmd]))
        {
            llMessageLinked(LINK_SET, COMMAND_OWNER, message, id);
        }
        else
        {
            llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, message, id);
        }
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        //handle changing prefix and channel from owner
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
                else
                {
                    //they left the param blank or tried to use 0
                    llOwnerSay("Error: 'channel' must be set to a number greater than 0.");
                }
            }
            else if (command == "reset")
            {
                llResetScript();
            }
        }
        else if (num == POPUP_HELP)
        {
            //replace _PREFIX_ with prefix, and _CHANNEL_ with (strin) channel
            str = StringReplace(str, "_CHANNEL_", (string)listenchannel);
            llOwnerSay(str);
        }
        else if (num == LOCALCMD_RESPONSE)
        {
            //split string by ,
            list newcmds = llParseString2List(str, [","], []);
            //add each to list if not already in
            integer n;
            integer stop = llGetListLength(newcmds);
            for (n = 0; n < stop; n ++)
            {
                list cmd = llList2List(newcmds, n, n);
                if (llListFindList(localcmds, cmd) == -1)
                {
                    localcmds += cmd;
                }
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
}
