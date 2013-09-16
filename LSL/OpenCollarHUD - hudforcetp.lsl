//on touch, give menu of LMs
//on hearing number, request LM data
//on getting LM data, give TP command
//Currently only works within Region (NG)
string parentmenu = "Main";
string submenu = "TelePort";
list localcmds = ["autotp"];
key dataid;
string currentmenu;
string lmname;
list menuids;//three strided list of avkey, dialogid, and menuname
integer menustride = 3;
string LMMENU = "LMMenu";
string MAINMENU = "MainMenu";

integer page = 0;
integer pagesize = 12;
string MORE = ">";
string UPMENU = "^";
string CURRENT_LOCATION = "*Here*";
string CAMERA_LOCATION = "*Camera Location*";

integer autotp;
integer menuchannel;

//MESSAGE MAP
integer COMMAND_OWNER = 500;

integer POPUP_HELP = 1001;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SEND_CMD_PICK_SUB = -1002;
integer SEND_CMD_ALL_SUBS = -1003;
integer SEND_CMD = -1001;
integer CMD_AUTO_TP = -1004;
integer SEND_CMD_SUB = -1005;
integer LOCALCMD_REQUEST = -2000;
integer LOCALCMD_RESPONSE = -2001;

key autoTPsubKey;
string autoTPsubName;
string ALLSUBS = "*All*";
integer autoTpALL = FALSE;


debug(string str)
{
    llOwnerSay(llGetScriptName() + ": " + str);
}

string TPCmd(vector abspos)
{
    return "tpto:" + (string)abspos.x + "/" + (string)abspos.y + "/" + (string)abspos.z + "=force";
}

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

LMMenu(key id, integer page)
{
    // reworked by CindyCD42 Fairey to add menu entry to "TP to camera location" as button 2
    currentmenu = "lmmenu";
    // create a list
    list buttons;
    list utility;
    string text = "";
    text += "Choose a destination.";
    
    text += "\n1 - " + CURRENT_LOCATION;
    buttons += ["1"];
    
    // add camera button
    text += "\n2 - " + CAMERA_LOCATION;
    buttons += ["2"];
    
    integer num_lms = llGetInventoryNumber(INVENTORY_LANDMARK);
    integer n;

    for (n=0;n<num_lms;n++)
    {
        string name = llGetInventoryName(INVENTORY_LANDMARK,n);
        if (name != "")
        {
            //show only the first part of the name, before the comma
            name = llList2String(llParseString2List(name, [","], []), 0);
            
            //cap names at 30 chars to avoid hitting 512 char prompt length limit
            if (llStringLength(name) > 30)
            {
                name = llGetSubString(name, 0, 29);
            }
            // add 3 instead of 2 to compensate for additional button for cam
            text += "\n" + (string)(n + 3) + " - " + name ;
            buttons += [(string)(n + 3)];
        }
    }  
    text += "\n";
    
    if(llStringLength(text) > 511) 
    {
        llOwnerSay("**** Too many landmarks. Please consider reduce the number of landmarks or renaming them to shorter names. Some landmarks may not appear. ****");
        text = llGetSubString(text,0,510);
    }
    
    utility = [UPMENU];    
    
    key menuid = Dialog(id, text, buttons, utility, page);
    
    // UUID , Menu ID, Menu
    list newstride = [id, menuid, LMMENU];
    
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

MainMenu(key id)
{   
    string text;
    list buttons;
    list utility;
    
    currentmenu = "main";
    
    text += "Choose an option.\n";
    buttons += ["TP Now"];
    buttons += ["TP Help"];
    utility = [UPMENU];   

    key menuid = Dialog(id, text, buttons, utility, page);
    
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

TPAllHere()
{
    vector abspos = llGetRegionCorner() + llGetPos();
    llMessageLinked(LINK_THIS, SEND_CMD_ALL_SUBS, TPCmd(abspos), NULL_KEY);
    if(!autotp)
    {                
        llOwnerSay("Sending teleport command to subs.");    
    }
}

key wearer;
default
{    
    state_entry()
    {
        wearer = llGetOwner();
        if (llGetAttached())
        {
            llRequestPermissions(wearer, PERMISSION_TRACK_CAMERA);
        }
        llSleep(1.0);
        llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == SUBMENU && str == submenu)
        {
            MainMenu(wearer);
        }
//NG        
            else if (str == "TPMenus")
            {
                LMMenu(id,page);
            }  
//NG   
        else if (num == COMMAND_OWNER)
        {
             if (str == "tpallhere")
            {
                TPAllHere();
            }
        }
        else if (num == LOCALCMD_REQUEST)
        {
            llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, llDumpList2String(localcmds, ","), NULL_KEY);
        }
        else if(num == DIALOG_RESPONSE)
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
                                
                if(menutype == MAINMENU)
                {     
                    if (message == "TP Now")
                    {
                        LMMenu(id,page);
                    }
                 else if (message == "TP Help")
            {
                llGiveInventory(id, "OpenCollar Owner HUD TPHelp");
            }
                    else if (message == UPMENU)
                    {
                        llMessageLinked(LINK_THIS, SUBMENU, parentmenu, id);
                    }
                }
                else if(menutype == LMMENU)
                {           
                    if (message == UPMENU)
                    {
                        MainMenu(id);
                    }
                    else if (message == "1")
                    {
                        // -- we got message to TP the sub right here
                        vector abspos = llGetPos() + llGetRegionCorner();
                        llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, TPCmd(abspos), NULL_KEY);
                    }
                    else if ( message == "2" )
                    {
                        // we got a message to tp the sub to our current camera location
                        // First - make sure we have permission to track the camera and get it if not.
                        if ( !(llGetPermissions() & PERMISSION_TRACK_CAMERA))
                        {
                            // permission not obtained yet, complain
                            llOwnerSay("Cannot track camera.  Permission not granted.");
                        }
                        else
                        {
                            // we already have permission to use the camera - send command   
                            vector abspos = llGetCameraPos() + llGetRegionCorner();
                            llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, TPCmd(abspos), NULL_KEY);   
                            llOwnerSay("TPing sub to cam position");
                        }
                    }    
                    else
                    {
                        // -- we picked a LM, get the data from it
                        integer lmnum = (integer)message - 3;// have to minus 3 because menu had no 0, and 1 was taken by "current location", and 2 taken by camera location
                        lmname = llGetInventoryName(INVENTORY_LANDMARK, lmnum);
                        dataid = llRequestInventoryData(lmname);
                    }
                }
            }
        }
        else if(num == DIALOG_TIMEOUT)
        {
            // we check menuids for the id returned by the dialog script
            // if it matches one, the index will be >0
            integer menuindex = llListFindList(menuids, [id]);
            
            // if it's greater than 0, we know it's for us (this script)
            if (menuindex != -1)
            {
                llOwnerSay("TP Menu timed out!");
            }
        }
    }
    
    dataserver(key id, string data)
    {
        if (id == dataid)
        {
            vector abspos = llGetRegionCorner() + (vector)data;
            llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, TPCmd(abspos), NULL_KEY);          
        }
    }    
    
    changed(integer change)
    {
        if (change & CHANGED_OWNER)
        {
            llResetScript();
        }
        else if (change & CHANGED_TELEPORT)
        {
            if (autotp)
            {
                if (autoTpALL)
                {
                    TPAllHere();
                }
                else
                {
                    vector abspos = llGetPos() + llGetRegionCorner();
                    llMessageLinked(LINK_THIS, SEND_CMD_SUB, TPCmd(abspos), autoTPsubKey) ;
                }
            }           
        }
    }
    
    on_rez(integer param)
    {
        llResetScript();
    }    
}
