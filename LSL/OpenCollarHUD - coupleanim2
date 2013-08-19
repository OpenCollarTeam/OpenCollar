//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
key partner;
float timeout = 30.0;//time for the potential kissee to respond before we give up

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_OBJECT = 506;
integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av

string stopstring = "stop";
integer stopchannel = 99;
integer listener;
string anim;

debug(string str)
{
    //llSay(0,llGetScriptName() + ": " + str);
}

string FirstName(string name)
{
    return llList2String(llParseString2List(name, [" "], []), 0);
}

default
{    
    link_message(integer sender, integer num, string str, key id)
    {
        debug("linkmessage: " + str);        
        if (num == CPLANIM_PERMREQUEST)
        {
            partner = id;
            llRequestPermissions(partner, PERMISSION_TRIGGER_ANIMATION);
            llInstantMessage(partner, FirstName(llKey2Name(llGetOwner())) + " would like give you a " + str + ". Click [Yes] to accept." );            
            llSetTimerEvent(timeout);
        }
        else if (num == CPLANIM_START)
        {
            llStartAnimation(str);//note that we don't double check for permissions here, so if the coupleanim1 script sends its messages out of order, this might fail
            anim = str;
            listener = llListen(stopchannel, "", partner, stopstring);
            llInstantMessage(partner, "If you would like to stop the animation early, say /" + (string)stopchannel + stopstring + " to stop.");
            
        }
        else if (num == CPLANIM_STOP)
        {
            llStopAnimation(str);            
        }
    } 
    
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            key id = llGetPermissionsKey();
            if (id == partner)
            {
                llSetTimerEvent(0.0);
                llMessageLinked(LINK_THIS, CPLANIM_PERMRESPONSE, "1", partner);                
            }
            else
            {
                llInstantMessage(id, "Sorry, but the request timed out.");
            }
        }
    }
    
    timer()
    {
        llSetTimerEvent(0.0);
        llListenRemove(listener);
        llMessageLinked(LINK_THIS, CPLANIM_PERMRESPONSE, "0", partner);
        partner = NULL_KEY;
    }
    
    listen(integer channel, string name, key id, string message)
    {
        debug("listen: " + message + ", channel=" + (string)channel);
        llListenRemove(listener);
        if (channel == stopchannel)
        {//this abuses the GROUP auth a bit but i think it's ok.
            //debug("message on stop channel");
            llMessageLinked(LINK_THIS, COMMAND_GROUP, "stopcouples", id);
        }
    }
}
