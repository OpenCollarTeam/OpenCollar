//on touch, give menu of LMs
//on hearing number, request LM data
//on getting LM data, give TP command

string parentmenu = "Main";
string submenu = "TP";
list localcmds = ["autotp"];
key dataid;
string currentmenu;
string lmname;

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

//integer SET_SUB = -1000;
//integer SEND_CMD = -1001;
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

list menuids;//three strided list of avkey, dialogid, and menuname
integer menustride = 3;
string LMMENU = "LMMenu";
string MAINMENU = "MainMenu";


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
    string text = "Choose a destination.\n";
    text += "You can add more destinations by putting more landmarks in my contents.";
    
    text += "\n1 - " + CURRENT_LOCATION;
    buttons += ["1"];
    
    // add camera button
    text += "\n2 - " + CAMERA_LOCATION;
    text += "Please be aware the tp may take up to 60 seconds plus sl lag to happen.";
    buttons += ["2"];
    
    integer num_lms = llGetInventoryNumber(INVENTORY_LANDMARK);
    integer n;


//    if (num_lms > 9)  // changed limit to 9 since additional button used for cam
//    {
//        //we'll only show one page's worth of LMs.  If you want more, recode this
//       llOwnerSay("I can only show the first 10 landmarks in inventory.  If you want more, you'll have to re-write my script.");
//        num_lms = 9;
//    }

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
    
    if (autotp)
    {
        buttons += ["AutoTP Off"];
        if(autoTpALL)
        {
            
            text += "AutoTP is currently On for all subs.\n";
        }
        else
        {
            text += "AutoTP is currently On for " + autoTPsubName + ".\n";
        }
    }
    else
    {
        buttons += ["AutoTP On"];
        text += "AutoTP is currently Off.\n";
    }
    text += "Choose an option.\n";
    buttons += ["TP Now"];
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
        else if (num == COMMAND_OWNER)
        {
            if (str == "autotp on")
            {
                autotp = TRUE;
                 // as of now nothing is saved 
                // llMessageLinked(LINK_THIS, HTTPDB_SAVE, "autotp=1", NULL_KEY);
                llOwnerSay("Auto TP On.");
            }
            else if (str == "autotp off")
            {
                autotp = FALSE;
                 // as of now nothing is saved 
                // llMessageLinked(LINK_THIS, HTTPDB_SAVE, "autotp=0", NULL_KEY);            
                llOwnerSay("Auto TP Off.");            
            }            
            else if (str == "tpallhere")
            {
                TPAllHere();
            }
        }
        // as of now nothing is saved so nothing restored either TODO?
//        /*
//        else if (num == HTTPDB_RESPONSE)
//        {
//            debug("https response complete string: " + str);
//            list temp = llParseString2List(str, [":"], []);
//            string token = llList2String(temp, 0);
//            debug("https response token: " + token);
//            if (token == "autotp=1")
//            {
//                autotp = TRUE;
//                string forWho = llList2String(temp, 1);
//                if (forWho == ALLSUBS)
//                {
//                    autoTpALL = TRUE;
//                }
//                else
//                {
//                    autoTpALL = FALSE;
//                    integer index = llSubStringIndex(forWho, ",");
//                    autoTPsubKey = (key)llGetSubString(forWho, 0, index -1);
//                    autoTPsubName = llGetSubString(forWho, index + 1, -1);
//                }
//                        
//            }
//            else if (token == "autotp=0")
//            {
//                autoTpALL = FALSE;
//                autotp = FALSE;
//            }
//        }
//        */
        else if (num == LOCALCMD_REQUEST)
        {
            llMessageLinked(LINK_THIS, LOCALCMD_RESPONSE, llDumpList2String(localcmds, ","), NULL_KEY);
        }
        else if (num == CMD_AUTO_TP)
        {
            autotp = TRUE;
            if(str == ALLSUBS)
            {
                autoTpALL = TRUE;
                 // as of now nothing is saved 
                // llMessageLinked(LINK_THIS, HTTPDB_SAVE, "autotp=1:" + str, NULL_KEY);
                llOwnerSay("Auto TP On for all subs.");
            }
            else
            {
                autoTpALL = FALSE;
                if(id == wearer)
                {
                    llOwnerSay("Sorry you cannot turn on AutoTP for yourself.");
                    return;
                }
                autoTPsubKey = id;
                autoTPsubName = str;
                 // as of now nothing is saved 
                // llMessageLinked(LINK_THIS, HTTPDB_SAVE, "autotp=1:" + (string)autoTPsubKey + "," + autoTPsubName , NULL_KEY);
                llOwnerSay("AUto TP On for " + autoTPsubName + ".");
            }
            MainMenu(wearer);
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
                
                //debug((string)id+"("+llKey2Name(id)+") :: "+message);
                
                if(menutype == MAINMENU)
                {     
                    if (message == "TP Now")
                    {
                        LMMenu(id,page);
                    }
                    else if (message == "AutoTP On")
                    {
                        autotp = TRUE;
                        vector abspos = llGetPos() + llGetRegionCorner();
                        llMessageLinked(LINK_THIS, SEND_CMD_PICK_SUB, "autotp|"+ TPCmd(abspos), NULL_KEY);
                    }
                    else if (message == "AutoTP Off")
                    {
                        autotp = FALSE;
                        // -- as of now nothing is saved 
                        // -- llMessageLinked(LINK_THIS, HTTPDB_SAVE, "autotp=0", NULL_KEY);            
                        llOwnerSay("Auto TP Off.");          
                        MainMenu(id);                                      
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
                        // -- llInstantMessage(llGetOwner(), "TPing " + subname + " to current location.");
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
                llInstantMessage(llGetOwner(),"Menu timed out!");
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
