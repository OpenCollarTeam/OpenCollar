// --- RLVLocator and Rezzer - 2.xxx
// --- released to the public with all permission under the
// --- condition that this header remains intact and the script
// --- may not be resold.
// --- Filters sensor result for RLV users and gives menu of avis  in range
// --- rezzes cage once selected.
// -----------------------------------------------------------
// ---
// --- 06-17-2009 by Betsy Hastings
// --- 
// -----------------------------------------------------------
// ------------------- constants & variables -----------------
// --- integer ---
integer commchannel = -987654321;
integer count = 0;
integer debugger = FALSE;
integer i;
integer index;
integer index1 = 0;
integer listener;
integer relaychannel = -1812221819;
integer relaylisten;
integer selectvictimchannel = 987212;
integer timeout = 70;
integer touched;
integer x;
integer y;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

// --- key ---
key owner_key;
key victimkey;
key menuid;

// --- float ---
float range=20.0;  // So we don't scan to far away

// --- list ---
list buttons;
list found = [];
list foundkeys = [];
list victims = [];
list lx  = [];
list ly = [];

// --- string ---
string cmd;
string message;
string msg = "";
string OwnerName;
string rlvenabled;
string prompt;
string tempname;
string temp_obj_name;
string victim;

// --- vector ---
vector pos;
rotation rot;

// --- functions ---
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

AvMenu(key id)//give list of people in victims list with RLV
{
    buttons = [];
    list utility = [];
    index = llGetListLength(victims);
    for (i = 0; i < index; i = i+2)
    {
        buttons += llGetSubString(llList2String(victims, i),0,(llSubStringIndex(llList2String(victims, i)," ")+1));
    }
    prompt = "Pick someone to cage.\n";
    prompt += "Choose from these " + (string)(index/2) + " avis, who have RLV enabled.";
    llSetTimerEvent(timeout);
    
    menuid = Dialog(id, prompt, buttons, utility, 0);
}

Choose_Cage(key id)
{
    buttons = [];
    list utility = [];
    index = llGetInventoryNumber(INVENTORY_OBJECT);
    for (i = 0; i < index; ++i)
    {
        msg = llToLower(llGetSubString(llGetInventoryName(INVENTORY_OBJECT,i),-4,-1));
        if (msg == "cage")
        {
            buttons += llGetInventoryName(INVENTORY_OBJECT,i);
        }
    }
    prompt += "Choose one of these cages to rez.";
    llSetTimerEvent(timeout);
    menuid = Dialog(id, prompt, buttons, utility, 0);
}

list ListCheck4Dup(list lx) // check the list, eliminating duplicates and sort
{
    index = llGetListLength(lx);
    for (x = 0; x < index; x++)
    {
        ly = llList2List(lx,x,x);
        lx = llDeleteSubList(lx,x,x);
        for (y = 0; y < llGetListLength(lx); ++y)
        {
            if(~llListFindList(lx,ly))
            {
                ly = [];
            }
            else
            {
                lx = lx + ly;
            }
        }
        index = llGetListLength(lx);
    }
    ly = llListSort(lx,2,TRUE);
    return ly;
}


set_to_default(integer x)
{
    if(x)
    {
        debug("cleaning up and getting ready...");
        lx = [];
        buttons = [];
        found = [];
        foundkeys = [];
        victims = [];
        rlvenabled = "";
        llSetTimerEvent(0.0);
        touched = 0;
        llSensorRemove();
        llListenControl(relaylisten,FALSE);
    }
}



debug(string bugger)
{
    if (debugger)
    {
        temp_obj_name = llGetObjectName();
        llSetObjectName(llGetScriptName());
        llOwnerSay(bugger);
        llSetObjectName(temp_obj_name);
    }
}


default
{
    on_rez(integer whatever)
    {
        llResetScript();
    }
    state_entry()
    {
        owner_key = llGetOwner();
        OwnerName = llKey2Name(owner_key);
        touched = 0;
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        if(str == "cagemenu")
        {
            llSleep(0.5);
            llOwnerSay("Scanning for avis with RLV within " + llGetSubString((string)range,0,3) + " Meters. (Please wait)");
            llSensor("",NULL_KEY,AGENT,range,PI);
        }
    }

    listen(integer channel,string name,key id,string message)
    {
        cmd = llGetSubString(message,0,6);
        if (channel == relaychannel && cmd == "locator")
        {

            rlvenabled=llKey2Name(llGetOwnerKey(id));
            index = llListFindList(found,[rlvenabled]);
            if(index > -1)  // we have found the name of the avi wearing a RLVrelay on the 'found' list the sensor event generated
            {
                tempname = llList2String(found,index);//(string)name of avi with RLV
                found = (found=[]) + llDeleteSubList(found,index,index); // take this avi out of list 'found'
                found = (found=[]) + llListInsertList(found,[tempname+" (RLV)"],index); //add ' (RLV)' after the name of avi using RLV and put it back in list duh
                victims += [rlvenabled , llGetOwnerKey(id)];// build 2 strided victims list that contains only avis we heared a response from the relay + key
            }
        }
    }

    sensor(integer total_number)
    {
        message = "Found "+(string)total_number+ " Avatars within Range\n";
        found = [];
        for(i=0;i<total_number;i++)
        {
            found = found + [llDetectedName(i)]; // add name to list 'found'
            message += llDetectedName(i)+"\n";
            relaylisten = llListen(relaychannel,"",NULL_KEY,"");
            llRegionSayTo((string)llDetectedKey(i),relaychannel,"locator,"+(string)llDetectedKey(i)+",!version");//query for a RLVRS...NG changed to RegionSayTo
        }
        llSetTimerEvent(1.0); //reduced this time since we are using RegionSayTo
        
    }

    no_sensor()
    {
        llOwnerSay("No avis within range at this time.");
        llResetScript();
    }

    timer()
    {
        llSetTimerEvent(0.0);
        llSensorRemove();
        llListenControl(relaylisten,FALSE);
        if(victims == []) // we heared no message from a RLVrelay
        {
            llOwnerSay("No RLV relays found. Check the sub has RLV relay installed it is turned on, and set to auto.");
            llResetScript();
        }
        else
        {
            msg = "";
            llOwnerSay ("Found "+(string)llGetListLength(found)+ " Avatars in Range. " + (string)(llGetListLength(victims)/2)+ " of these use RLV.");//NG lets say what we have found
            found = [];
            for(i = 0; i< llGetListLength(victims); i = i+2)
            {
                msg = msg + llList2String(victims,i)+"(RLV)\n";
                found += llList2List(victims,i,i);
            }
            state launch;
        }
    }
}

state launch
{
    state_entry()
    {
        ListCheck4Dup(found);
        found = ly;
        AvMenu(owner_key);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        if(num == DIALOG_RESPONSE)
        {
            if(id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                string message = llList2String(menuparams, 1);
                integer page = (integer)llList2String(menuparams, 2);            
                
                llSetTimerEvent(timeout);
                msg = llGetSubString(llToLower(message),-4,-1);
                index1 = llStringLength(message);
                index = llGetListLength(victims);
                if (msg == "cage")
                {
                    pos = llGetPos();
                    rot = llGetRot();
                    llRezObject(message,pos + <3.0,3.0,1.0>, <0.0,0.0,0.0>, rot, 0);
                }
                else if (msg != "cage")
                {
                    i=0;
                    while(i < index)
                    {
                        victim = (llGetSubString(llList2String(victims,i),0,index1-1));
                        if(victim == message)
                        {
                            llOwnerSay("Choose a cage for " + llList2String(victims,i) + ".");  
                            victimkey = llList2Key(victims,i+1);
                            Choose_Cage(owner_key);
                        }
                        i = i+2;
                    }
                }
               
                else 
                {
                    llOwnerSay("Please choose a victim or cage.");
                    llSetTimerEvent(0.1);
                }
            }
        }
        else if(num == DIALOG_TIMEOUT)
        {
            if(id == menuid)
            {
                llOwnerSay("Cager Menu timed out!");
            }
        }
    }

    object_rez(key id)
    {
        llSleep(0.5); // make sure object is rezzed and listens
        llSay(commchannel,"fetch"+(string)victimkey);
        llSetTimerEvent(0.1);
    }
    
    timer()
    {
        set_to_default(1);
        state default;
    }
}