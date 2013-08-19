// Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
// coupleanim1
// string parentmenu = "Animations";
string parentmenu = "Main"; // changed for Owner HUD
string submenu = "Couples";
string UPMENU = "^";
string MORE = ">";
integer listener;
integer animmenuchannel = 9817243;
integer partnerchannel = 9817244;
string sensormode;// will be set to "chat" or "menu" later
string timermode;// set to "menu" or "anim" later
list partners;
integer menutimeout = 60;

string STOP_COUPLES = "Stop";
string TIME_COUPLES = "Time";

integer line;
key dataid;
string CARD1 = "coupleanims";
string CARD2 = "coupleanims_personal";
string noteCard2Read;

list animcmds;// 1-strided list of strings that will trigger
list animsettings;// 4-strided list of subanim|domanim|offset|text, running parallel to animcmds, 
// such that animcmds[0] corresponds to animsettings[0:3], and animcmds[1] corresponds to animsettings[4:7], etc
                  
key cardid1;// used to detect whether coupleanims card has changed
key cardid2;
float range = 10.0;// only scan within this range for anim partners
float tau = 1.5; // how hard to push sub toward 

key cmdgiver;
integer cmdindex;
string tmpname;
string currentmenu;
key partner;
string partnername;
float timeout = 20.0;// duration of anim
// i dont think this flag is needed at all
integer arrived;// a flag used to revent a flood of messages in the at_target event

string subanim;
string domanim;

// MESSAGE MAP

integer COMMAND_OWNER = 500;
integer POPUP_HELP = 1001;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer ANIM_START = 7000;// send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;// send this with the name of an anim in the string part of the message to stop the anim
integer CPLANIM_PERMREQUEST = 7002;// id should be av's key, str should be cmd name "hug", "kiss", etc
integer CPLANIM_PERMRESPONSE = 7003;// str should be "1" for got perms or "0" for not.  id should be av's key
integer CPLANIM_START = 7004;// str should be valid anim name.  id should be av
integer CPLANIM_STOP = 7005;// str should be valid anim name.  id should be av

integer LOCALCMD_REQUEST = -2000;
integer LOCALCMD_RESPONSE = -2001;
list localcmds = ["couples", "stopcouples"];

key wearer;
list menuids;//three strided list of avkey, dialogid, and menuname
integer menustride = 3;
// Use these to keep track of your current menu
// Use any variable name you desire
string PARTNERMENU = "PartnerMenu";
string ANIMMENU = "CoupleAnimMenu";

debug(string str)
{
    // llOwnerSay(llGetScriptName() + ": " + str);
}

key ShortKey()
{ // just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
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

PartnerMenu(key id, list avs)
{
    string text = "Pick a partner.";
    list utility;
    
    if (llGetListLength(avs) > 11)
    {
        avs = llList2List(avs, 0, 10);
    }
    list buttons = avs;// we're limiting this to 11 avs
    utility += [UPMENU];
    
    key menuid = Dialog(id, text, buttons, utility, 0);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, PARTNERMENU];

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

CoupleAnimMenu(key id)
{
    string text = "Pick an animation to play.";
    list utility;
    
    list buttons = animcmds; // we're limiting this to 9 couple anims then
    // -- buttons += [TIME_COUPLES, STOP_COUPLES, UPMENU];
    buttons += [TIME_COUPLES, STOP_COUPLES];
    utility += [UPMENU];
    
    key menuid = Dialog(id, text, buttons, utility, 0);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, ANIMMENU];

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

TimerMenu(key id)
{
    string text = "Pick an time to play.";
    list buttons = ["10", "20", "30"];
    buttons += ["40", "50", "60"];
    buttons += ["90", "120", "endless"];
    list utility = [UPMENU];

    key menuid = Dialog(id, text, buttons, utility, 0);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, PARTNERMENU];

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

integer AnimExists(string anim)
{
    return llGetInventoryType(anim) == INVENTORY_ANIMATION;
}

integer ValidLine(list params)
{
    // valid if length = 4 or 5 (since text is optional) and anims exist
    integer length = llGetListLength(params);
    if (length < 4)
    {
        return FALSE;
    }
    else if (length > 5)
    {
        return FALSE;
    }
    else if (!AnimExists(llList2String(params, 1)))
    {
        llOwnerSay(CARD1 + " line " + (string)line + ": animation '" + llList2String(params, 1) + "' is not present.  Skipping.");
        return FALSE;
    }
    else if (!AnimExists(llList2String(params, 2)))
    {
        llOwnerSay(CARD1 + " line " + (string)line + ": animation '" + llList2String(params, 2) + "' is not present.  Skipping.");        
        return FALSE;
    }
    else
    {
        return TRUE;
    }
}

integer startswith(string haystack, string needle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return llDeleteSubString(haystack, llStringLength(needle), -1) == needle;
}

string str_replace(string src, string from, string to)
{ // replaces all occurrences of 'from' with 'to' in 'src'.
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

PrettySay(string text)
{
    string name = llGetObjectName();
    list words = llParseString2List(text, [" "], []);
    llSetObjectName(llList2String(words, 0));
    words = llDeleteSubList(words, 0, 0);
    llSay(0, "/me " + llDumpList2String(words, " "));
    llSetObjectName(name);
}

string FirstName(string name)
{
    return llList2String(llParseString2List(name, [" "], []), 0);
}

// added to stop eventual still going animations
StopAnims()
{
    if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    {
        if (AnimExists(subanim))
        {
            llStopAnimation(subanim);
        }
    }
    if (AnimExists(domanim))
    {
        llMessageLinked(LINK_THIS, CPLANIM_STOP, domanim, NULL_KEY);
    }
    
    subanim = "";
    domanim = "";
}

StartAnim()
{
    if (AnimExists(subanim))
    {
        if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
        {
            llStartAnimation(subanim);
        }
        else
        {
            llRequestPermissions(wearer, PERMISSION_TRIGGER_ANIMATION);
            if (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
            {
                if (AnimExists(subanim))
                {
                    llStopAnimation(subanim);
                }
            }
        }
    }
}
     
default
{    
    state_entry()
    {
        wearer = llGetOwner();
        if(llGetAttached()) llRequestPermissions(wearer, PERMISSION_TRIGGER_ANIMATION);
        if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD)
        { // card is present, start reading
            cardid1 = llGetInventoryKey(CARD1);
            
            // re-initialize just in case we're switching from other state
            line = 0;
            animcmds = [];
            animsettings = [];
            noteCard2Read = CARD1;
            dataid = llGetNotecardLine(noteCard2Read, line);            
        }
        else
        {
            // card isn't present, switch to nocard state
        }
    }
    dataserver(key id, string data)
    {
        if (id == dataid)
        {
            if (data == EOF)
            {
                if(noteCard2Read == CARD1)
                {
                    if(llGetInventoryType(CARD2) == INVENTORY_NOTECARD)
                    {
                        cardid2 = llGetInventoryKey(CARD2);
                        noteCard2Read = CARD2;
                        line = 0;
                        dataid = llGetNotecardLine(noteCard2Read, line);
                    }
                    else
                    {
                        // no Mycoupleanims notecard so...
                        state ready;
                    }
                }
                else
                {
                    debug("done reading card");
                    state ready;
                }
            }
            else
            {
                list params = llParseString2List(data, ["|"], []);
                // don't try to add empty or misformatted lines                
                if (ValidLine(params))
                {
                    integer index = llListFindList(animcmds, llList2List(params, 0, 0));
                    if(index == -1)
                    {
                        // add cmd, and text
                        localcmds += llList2List(params, 0, 0);
                        animcmds += llList2List(params, 0, 0);
                        // anim names, offset, 
                        animsettings += llList2List(params, 1, 3);
                        // text.  this has to be done by casting to string instead of list2list, else lines that omit text will throw off the stride
                        animsettings += [llList2String(params, 4)];
                        debug(llDumpList2String(animcmds, ","));
                        debug(llDumpList2String(animsettings, ","));
                    }
                    else
                    {
                         index = index * 4;
                        // add cmd, and text
                        // anim names, offset, 
                        animsettings = llListReplaceList(animsettings, llList2List(params, 1, 3), index, index + 2);
                        // text.  this has to be done by casting to string instead of list2list, else lines that omit text will throw off the stride
                        animsettings = llListReplaceList(animsettings,[llList2String(params, 4)], index + 3, index + 3);
                        debug(llDumpList2String(animcmds, ","));
                        debug(llDumpList2String(animsettings, ","));
                    }
                }
                line++;
                dataid = llGetNotecardLine(noteCard2Read, line);
            }
        }
    }
}

state nocard
{
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD)
            { // card is now present, switch to default state and read it.
                state default;
            }
            if (llGetInventoryType(CARD2) == INVENTORY_NOTECARD)
            { // card is now present, switch to default state and read it.
                state default;
            }
        }
    }
}

state ready
{    // leaving this here due to delay of nc reading
    state_entry()
    {
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, llDumpList2String(localcmds, ","), NULL_KEY);
    }

    link_message(integer sender, integer num, string str, key id)
    {
        // if you don't care who gave the command, so long as they're one of the above, you can just do this instead:
        if (num == COMMAND_OWNER)
        {
            // the command was given by either owner, secowner, group member, or wearer
            list params = llParseString2List(str, [" "], []);
            cmdgiver = id;
            string cmd = llList2String(params, 0);
            integer tmpindex = llListFindList(animcmds, [cmd]);
            if (tmpindex != -1)
            {
                cmdindex = tmpindex;
                debug(cmd);
                // we got an anim cmd.  
                // else set partner to commander
                if (llGetListLength(params) > 1)
                {
                    // we've been given a name of someone to kiss.  scan for it
                    tmpname = llDumpList2String(llList2List(params, 1, -1), " ");//this makes it so we support even full names in the command
                    sensormode = "chat";
                    llSensor("", NULL_KEY, AGENT, range, PI);                    
                }
                else
                {
                    //  no name given.  if commander is not sub, then treat commander as partner
                    if (id == wearer)
                    {
                        llMessageLinked(LINK_THIS, POPUP_HELP, "Error: you didn't give the name of the person you want to animate.  To " + cmd + " Nandana Singh, for example, you could say /_CHANNEL_" + cmd + " nan", wearer);
                    }
                    else
                    {
                        partner = cmdgiver;
                        partnername = llKey2Name(partner);
                        // added to stop eventual still going animations
                        StopAnims();  
                        llMessageLinked(LINK_THIS, CPLANIM_PERMREQUEST, cmd, partner);      
                        llOwnerSay("Offering to " + cmd + " " + partnername + ".");
                    }
                }
            }
            else if (str == "stopcouples")
            {
                StopAnims();
            }
            else if (str == "couples")
            {
                CoupleAnimMenu(id);
            }          
        }
        else if (num == CPLANIM_PERMRESPONSE)
        {
            if (str == "1")
            {
                // we got permission to animate.  start moving to target
                float offset = (float)llList2String(animsettings, cmdindex * 4 + 2);
                vector pos = llList2Vector(llGetObjectDetails(partner, [OBJECT_POS]), 0);
                llTarget(pos, offset);
                llMoveToTarget(pos, tau);
                arrived = FALSE;
            }
            else if (str == "0")
            {
                // we did not get permission to animate
                llInstantMessage(cmdgiver, partnername + " did not accept your " + llList2String(animcmds, cmdindex) + ".");                
            }
        }
        else if (num == MENUNAME_REQUEST && str == parentmenu)
        {
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        }
        else if (num == SUBMENU && str == submenu)
        {
            CoupleAnimMenu(id);
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
                
                if (menutype == ANIMMENU)
                {
                    if (message == UPMENU)
                    {
                        llMessageLinked(LINK_THIS, SUBMENU, parentmenu, id);
                    }
                    else if (message == STOP_COUPLES)
                    {
                        StopAnims();
                        CoupleAnimMenu(id);
                    }             
                    else if (message == TIME_COUPLES)
                    {
                        TimerMenu(id);
                    }             
                    else
                    {
                        integer index = llListFindList(animcmds, [message]);
                        if (index != -1)
                        {
                            cmdgiver = id;
                            cmdindex = index;
                            sensormode = "menu";
                            llSensor("", NULL_KEY, AGENT, range, PI);                    
                        }
                    }
                }
                else if (menutype == PARTNERMENU)
                {
                    if (message == UPMENU)
                    {
                        CoupleAnimMenu(id);
                    }
                    else if ((integer)message > 0 && ((string)((integer)message) == message))
                    {
                        timeout = (float)((integer)message);
                        llOwnerSay("Couple Anmiations play now for " + (string)llRound(timeout) + " seconds.");
                        if (id != wearer)
                        {
                            llInstantMessage(id, "Couple Anmiations play now for " + (string)llRound(timeout) + " seconds.");
                        }
                        CoupleAnimMenu(id);
                    }
                    else if (message == "endless")
                    {
                        timeout = 0.0;
                        llOwnerSay("Couple Anmiations play now for ever. Use the menu or type *stopcouples to stop them again.");
                        if (id != wearer)
                        {
                            llInstantMessage(id, "Couple Anmiations play now for ever. Use the menu or type *stopcouples to stop them again.");
                        }
                        CoupleAnimMenu(id);
                    }           
                    else
                    {
                        integer index = llListFindList(partners, [message]);
                        if (index != -1)
                        {
                            partner = llList2String(partners, index - 1);
                            partnername = message;
                            // added to stop eventual still going animations
                            StopAnims();  
                            string cmdname = llList2String(animcmds, cmdindex);
                            llMessageLinked(LINK_THIS, CPLANIM_PERMREQUEST, cmdname, partner);      
                            llOwnerSay("Offering to " + cmdname + " " + partnername + ".");                    
                        }
                    }
                }
            }
        }
        else if (num == DIALOG_TIMEOUT)
        {
            integer menuindex = llListFindList(menuids, [id]);
            if (menuindex != -1)
            {
                llInstantMessage(llGetOwner(), "Couple Menu timed out!");
            }
        }
    }
    
    
    not_at_target()
    {
        if (!arrived)
        {
            // this might make us chase the partner.  we'll see.  that might not be bad
            float offset = (float)llList2String(animsettings, cmdindex * 4 + 2);        
            vector pos = llList2Vector(llGetObjectDetails(partner, [OBJECT_POS]), 0);
            llTarget(pos, offset);
            llMoveToTarget(pos, tau);                    
        }
        else
        {
            llStopMoveToTarget();
        }
    }
    
    at_target(integer tnum, vector targetpos, vector ourpos)
    {
        if (!arrived)
        {
            debug("arrived");
            llTargetRemove(tnum);
            llStopMoveToTarget();
            // we've arrived.  let's play the anim and spout the text
            subanim = llList2String(animsettings, cmdindex * 4);
            domanim = llList2String(animsettings, cmdindex * 4 + 1);        
            StartAnim();
            // llStartAnimation(subanim);
            llMessageLinked(LINK_THIS, CPLANIM_START, domanim, NULL_KEY);
            
            string text = llList2String(animsettings, cmdindex * 4 + 3);
            if (text != "")
            {
                text = str_replace(text, "_SELF_", FirstName(llKey2Name(wearer)));
                text = str_replace(text, "_PARTNER_", FirstName(partnername));            
                PrettySay(text);
            }
//             timermode = "anim";
            llSetTimerEvent(timeout);
            arrived = TRUE;
        }
    }
    
    timer()
    {
        StopAnims();
        llSetTimerEvent(0.0);       
    }
    
    sensor(integer num)
    {
        debug(sensormode);
        if (sensormode == "menu")
        {
            partners = [];
            list avs; // just used for menu building
            integer n;
            for (n = 0; n < num; n++)
            {
                partners += [llDetectedKey(n), llDetectedName(n)];
                avs += [llDetectedName(n)];
            }
            PartnerMenu(cmdgiver, avs);
        }
        else if (sensormode == "chat")
        {
            // loop through detected avs, seeing if one matches tmpname
            integer n;
            for (n = 0; n < num; n++)
            {
                string name = llDetectedName(n);
                if (startswith(llToLower(name), llToLower(tmpname)) || llToLower(name) == llToLower(tmpname))
                {
                    partner = llDetectedKey(n);
                    partnername = name;
                    string cmd = llList2String(animcmds, cmdindex);
                // added to stop eventual still going animations
                    StopAnims();  
                    llMessageLinked(LINK_THIS, CPLANIM_PERMREQUEST, cmd, partner);
                    llOwnerSay("Offering to " + cmd + " " + partnername + ".");                
                    return;
                }
            }
            // if we got to this point, then no one matched
            llInstantMessage(cmdgiver, "Could not find '" + tmpname + "' to " + llList2String(animcmds, cmdindex) + ".");             
        }               
    }
    
    no_sensor()
    {
        if (sensormode == "chat")
        {
            llInstantMessage(cmdgiver, "Could not find '" + tmpname + "' to " + llList2String(animcmds, cmdindex) + ".");
        }
        else if (sensormode == "menu")
        {
            llInstantMessage(cmdgiver, "Could not find anyone nearby to " + llList2String(animcmds, cmdindex) + ".");
            CoupleAnimMenu(cmdgiver);
        }
    }
    
    changed(integer change)
    {
        if( change & CHANGED_OWNER)
        {
            llResetScript();
        }
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(CARD1) != cardid1)
            {
                // because notecards get new uuids on each save, we can detect if the notecard has changed by seeing if the current uuid is the same as the one we started with
                // just switch states instead of restarting, so we can preserve any settings we may have gotten from db
                state default;
            }
            if (llGetInventoryKey(CARD2) != cardid1)
            {
                state default;
            }
        }
    }
}
