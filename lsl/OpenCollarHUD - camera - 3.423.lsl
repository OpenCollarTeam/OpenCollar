//provides menu with 3 commands:
    //SyncSub gets the wearer's current camera pos and rot, then sends camto <pos> <rot> command to sub on object channel
    //Sync2Sub picks a channel, sets up a listener on it, chats out the camdump command, listens for pos and rot, then sets the dom's cam when it hears back
    //Clear - clears the dom's camera settings
    
string mymenu = "Camera";
string parentmenu = "Main";    
    
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

string UPMENU = "^";
string MORE = ">";

//these two flags are used for overloading the timer to handle both menu timeouts and collar pos/rot listen timeouts.
integer menutimeout;
integer timeout = 60;
integer listener;
integer menuchannel;
integer collarchannel;
integer collarlistener;
list subs;
integer syncingsubs;//true if we're broadcasting camto commands to subs
key currentsub;//sub we're currently listening to if syncing from one
float repeat = 0.5;

//menu commands
string SYNCSUB = "SyncSub";
string SYNCSELF = "SyncSelf";
string CLEARSUB = "ClearSub";
string CLEARSELF = "ClearSelf";

key menuid;

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
Menu(key id)
{
    string text = "Pick an option.\nSyncSub - make the sub see what you see\mSyncSelf - See what the sub is looking at.\n";
    list buttons = [SYNCSUB, CLEARSUB, SYNCSELF, CLEARSELF];
    list utility = [UPMENU];
    menuid = Dialog(llGetOwner(), text, buttons, utility, 0);
}


string str_replace(string src, string from, string to)
{//replaces all occurrences of 'from' with 'to' in 'src'.
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
//            b_pos -= to_pos;
//            src = llInsertString(llDeleteSubString(src, b_pos, b_pos + len), b_pos, to);
//            b_pos += to_len;
//            buffer = llGetSubString(src, (-~(b_pos)), 0x8000);
            buffer = llGetSubString(src = llInsertString(llDeleteSubString(src, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        }
    }
    return src;
}

CamFocus(vector campos, rotation camrot)
{
    vector startpos = llGetCameraPos();    
    rotation startrot = llGetCameraRot();
    float steps = 8.0;
    //Keep steps a float, but make sure its rounded off to the nearest 1.0
    steps = (float)llRound(steps);
 
    //Calculate camera position increments
    vector posStep = (campos - startpos) / steps;
 
    //Calculate camera rotation increments
    //rotation rotStep = (camrot - startrot);
    //rotStep = <rotStep.x / steps, rotStep.y / steps, rotStep.z / steps, rotStep.s / steps>;
 
 
    float cStep = 0.0; //Loop through motion for cStep = current step, while cStep <= Total steps
    for(; cStep <= steps; ++cStep)
    {
        //Set next position in tween
        vector nextpos = startpos + (posStep * cStep);
        rotation nextrot = slerp( startrot, camrot, cStep / steps);
 
        //Set camera parameters
        llSetCameraParams([
            CAMERA_ACTIVE, 1, //1 is active, 0 is inactive
            CAMERA_BEHINDNESS_ANGLE, 0.0, //(0 to 180) degrees
            CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
            CAMERA_DISTANCE, 0.0, //(0.5 to 10) meters
            CAMERA_FOCUS, nextpos + llRot2Fwd(nextrot), //Region-relative position
            CAMERA_FOCUS_LAG, 0.0 , //(0 to 3) seconds
            CAMERA_FOCUS_LOCKED, TRUE, //(TRUE or FALSE)
            CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
            CAMERA_POSITION, nextpos, //Region-relative position
            CAMERA_POSITION_LAG, 0.0, //(0 to 3) seconds
            CAMERA_POSITION_LOCKED, TRUE, //(TRUE or FALSE)
            CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
            CAMERA_FOCUS_OFFSET, ZERO_VECTOR //<-10,-10,-10> to <10,10,10> meters
        ]);
    }
}
 
rotation slerp( rotation a, rotation b, float f ) {
    float angleBetween = llAngleBetween(a, b);
    if ( angleBetween > PI )
        angleBetween = angleBetween - TWO_PI;
    return a*llAxisAngle2Rot(llRot2Axis(b/a)*a, angleBetween*f);
}//Written by Francis Chung, Taken from http://forums.secondlife.com/showthread.php?p=536622

SyncSubCam()
{
    //send command to sync sub's cam to dom's
    string cmd = "camto " + str_replace((string)llGetCameraPos(), " ", "") + " " + str_replace((string)llGetCameraRot(), " ", "");
    llMessageLinked(LINK_SET, SEND_CMD_NEARBY_SUBS, cmd, "");    
}
    
default
{
    on_rez(integer param)
    {
        llResetScript();
    }
    
    state_entry()
    {
        if (llGetAttached())
        {
            llRequestPermissions(llGetOwner(), PERMISSION_TRACK_CAMERA | PERMISSION_CONTROL_CAMERA);
        }
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + mymenu, "");
    }
    
    run_time_permissions(integer perms)
    {
        if (perms & PERMISSION_CONTROL_CAMERA)
        {
            llClearCameraParams();
        }
    }

    link_message(integer sender, integer num, string str, key id)
    {
        if (num == MENUNAME_REQUEST && str == parentmenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, mymenu, "");
        }
        else if (num == SUBMENU && str == mymenu)
        {
            Menu(id);
        }
        else if (num == SUB_LIST)
        {
            subs = llParseString2List(str, [","], []);
        }
        
        if(num == DIALOG_RESPONSE)
        {
            if(id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                key av = (key)llList2String(menuparams, 0);
                string response = llList2String(menuparams, 1);
                integer page = (integer)llList2String(menuparams, 2);
                
                if (response == UPMENU)
                {
                    llMessageLinked(LINK_SET, SUBMENU, parentmenu, av);
                    return;
                }
                else if (response == SYNCSUB)
                {
                    SyncSubCam();
                    syncingsubs = TRUE;
                    llSetTimerEvent(repeat);
                    Menu(av);
                }
                else if (response == CLEARSUB)
                {
                    //send command to sub to clear cam settings.
                    llMessageLinked(LINK_SET, SEND_CMD_NEARBY_SUBS, "cam clear", "");
                    syncingsubs = FALSE;
                    Menu(av);                
                }
                else if (response == SYNCSELF)
                {
                    //sync to sub's cam.  first must get sub's cam settings from a camdump command
                    collarchannel = -llRound(llFrand(10000000) + 1000);//replace this later with integer derived from sub's key
                    llListenRemove(collarlistener);
                    collarlistener = llListen(collarchannel, "", "", "");
                    llMessageLinked(LINK_SET, SEND_CMD_PICK_SUB, "camdump " + (string)collarchannel + " 1", "");   
                    //no menu here, since we'll be getting the pick sub menu         
                }
                else if (response == CLEARSELF)
                {
                    //need to tell sub's collar to stop broadcasting
                    llMessageLinked(LINK_SET, SEND_CMD_SUB, "camdump -1 0", currentsub);
                    
                    //and also stop ourself from listening
                    llListenRemove(collarlistener);
                    collarlistener = 0;
                    llClearCameraParams();
                    llOwnerSay("Cleared camera settings.");
                    Menu(av);                
                }
            }
        }
        
        if(num == DIALOG_TIMEOUT)
        {
            if(id == menuid)
            {
                menuid = NULL_KEY;
            }
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == collarchannel)
        {
            //we heard the sub's collar give a pos/rot.  sanity check them and sync
            if (~llListFindList(subs, [(string)llGetOwnerKey(id)]))
            {
                currentsub = llGetOwnerKey(id);
                //was one of our subs.  sync
                list params = llParseString2List(message, [" "], []);
                vector pos = (vector)llList2String(params, 0);
                rotation rot = (rotation)llList2String(params, 1);
                if (pos != ZERO_VECTOR && rot != ZERO_ROTATION)
                {
                    CamFocus(pos, rot);
                }
            }
        }
    }
    
    timer()
    {
        if (syncingsubs)
        {
            SyncSubCam();
        }
        else
        {
            llSetTimerEvent(0.0);
        }
    }
}
