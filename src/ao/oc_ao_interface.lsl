////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                          OpenCollarAttch - Interface                           //
//                                 version 3.900                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

integer interfaceChannel = -12587429;
integer objectchannel = -1812221819;//only send on this channel, not listen
integer listenHandle;
integer COMMAND_NOAUTH = 0;
integer COMMAND_AUTH = 42;
integer COMMAND_TO_COLLAR = 498; // -- Added to send commands TO the collar.
integer COMMAND_COLLAR = 499;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COLLAR_INT_REQ = 610;
integer COLLAR_INT_REP = 611;
integer collarIntegration;
key wearer;
key objectID;
string separator = "|";
list authList; //strided list [uuid, auth]
integer counter;
key collarID;
string messageType; // how the collar sends a message" "RequestReply", "CollarCommand"

debug(string message)
{
    //llOwnerSay(llGetScriptName() + " DEBUG: " + message);
}

// Yay for Cleo and Jessenia - Personal Object Channel
//===============================================================================
//= parameters   :    key owner            key of the person to send the message to
//=                   integer nOffset      Offset to make sure we use really a unique channel
//=
//= description  : Function which calculates a unique channel number based on the owner key, to reduce lag
//=
//= returns      : Channel number to be used
//===============================================================================
integer nGetOwnerChannel(key owner, integer nOffset)
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


init()
{
    objectID = llGetKey();
    objectchannel = nGetOwnerChannel(wearer,1111);
    //listen first to the full interfaceChannel and start to ping every 10 secs for a collar
    llListenRemove(listenHandle);
    listenHandle = llListen(interfaceChannel, "", "", "");
    //we dont know what was changed in the collar so lets starts fresh with our cache
    authList = [];
    collarID = NULL_KEY;
    collarIntegration = FALSE; // -- 3.381 to avoid double message on login
    llWhisper(interfaceChannel, "OpenCollar?");
    counter = 0;
    llSetTimerEvent(30.0);
}

default
{
    changed(integer c)
    {
        if(c & CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
    
    state_entry()
    {
        wearer = llGetOwner();
        interfaceChannel = (integer)("0x" + llGetSubString(wearer,30,-1));
        if (interfaceChannel > 0) interfaceChannel = -interfaceChannel;
        init();
    }
    on_rez(integer start)
    {
        if( wearer != llGetOwner())
        {
            llResetScript();
        }
        init();
    }
    link_message(integer sender, integer num, string str, key id)
    {
        //debug("LinkMsg: " + str);
        if (num == COLLAR_INT_REQ)
        {
            if (collarID != NULL_KEY)
            {
                if (str == "CollarOn")
                {
                    collarIntegration = TRUE;
                    authList = [];
                }
                else if (str == "CollarOff")
                {
                    collarIntegration = FALSE;
                    authList = [];
                }
            }
            else if (collarID == NULL_KEY)
            {
                if (str == "CollarOff")
                {
                    collarIntegration = FALSE;
                    authList = [];
                }
            }
            //send back if we know the collarID (means if != NULL_KEY we are able to interact fully
            llMessageLinked(LINK_THIS, COLLAR_INT_REP, str, collarID);
        }
        else if (num == COMMAND_TO_COLLAR)
        {
            llWhisper(objectchannel, str);
        }
        else if (num == COMMAND_NOAUTH)
        {
            if (collarIntegration)
            {
                integer index = llListFindList(authList, [(string)id]);
                if ( index == -1)
                {
                    llWhisper(interfaceChannel, "0|" + str + separator + (string)id + separator + (string)objectID);
                }
                else
                {
                    string auth = llList2String(authList, index + 1);
                    llMessageLinked(LINK_THIS, (integer)auth, str, id);
                }
            }
            else
            {
                llMessageLinked(LINK_THIS, COMMAND_OWNER, str, id);
            }
        }
        else if (num == COMMAND_AUTH && str == "ZHAO_RESET")
        {
            llSleep(2); // -- Don't reset immediately, ensure the Interface is ready for us
            llResetScript();
        }
    }
    listen(integer channel, string name, key id, string message)
    {
        //debug("Listen: " + message);
        //do nothing if wearer isnt owner of the object
        if (llGetOwnerKey(id) != wearer)
        {
            return;
        }
        //Collar announces itself
        if (message == "OpenCollar=Yes")
        {
            collarID = id;
            llListenRemove(listenHandle);
            listenHandle = llListen(interfaceChannel, "", collarID, "");
            //llMessageLinked(LINK_THIS, COLLAR_INT, message, "");
            llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOn", "");
            return;
        } //Collar said it got detached
        else if (message == "OpenCollar=No")
        {
            collarID = NULL_KEY;
            authList = [];
            llListenRemove(listenHandle);
            listenHandle = llListen(interfaceChannel, "", "", "");
            llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
            return;
        }
        //messageType + SEPARATOR + (string)num + SEPARATOR + msg + SEPARATOR + (string)id SEPARATOR + objectID
        integer index = llSubStringIndex(message, separator);
        messageType = llGetSubString(message, 0, index - 1);
        debug(messageType);
        if (messageType == "RequestReply")
        {
            key checkID = (key)llGetSubString(message, llStringLength(message) - 36, -1);
            debug("IDcheck= " + (string)checkID);
            if (checkID != objectID)
            {//if this isnt my id then the message was not for me
                return;
            }
            //cut off my own id, no more needed
            message = llGetSubString(message, 0, llStringLength(message) - 38);
        }
        //cut off the message type
        message = llGetSubString(message, index + 1, -1);
        debug(message);
        //check if we get a auth request at all here
        index = llSubStringIndex(message, separator);
        integer auth = (integer)llGetSubString(message, 0, index - 1);
        if (auth) 
        {//auth has to be an integer > 0 else it cannot be a collar message
            message = llGetSubString(message, index + 1, -1);
            index = llSubStringIndex(message, separator);
            string command = llGetSubString(message, 0, index - 1);
            //Collar tells me owners have changed reset my authList
            if (auth == COMMAND_COLLAR)
            {
                if (command == "OwnerChange")
                {
                    authList = [];
                }
                else if (command == "safeword")
                {
                    llMessageLinked(LINK_THIS, auth, message, "");
                }
                else
                {
                    llMessageLinked(LINK_THIS, auth, message, "");
                }
            }
            else
            {
                list parts = llParseStringKeepNulls(message, ["|"], []);
                key UUID = "";
                if (llGetListLength(parts) > 1)
                {
                    command = llDumpList2String(llListReplaceList(parts, [], -1, -1), "|");
                    UUID = (key)llList2String(parts, -1);
                }
                authList += [UUID, (string)auth];
                llMessageLinked(LINK_THIS, auth, command, UUID);
            }
        }
    }
    timer()
    {
        if (collarID != NULL_KEY)
        {
            
            if (llKey2Name(collarID) == "") //the collar is somehow gone...
            {//check 2 times again if the collar is really gone, then switch to CollarRequest mode
                if (counter <= 2)
                {
                    counter++;
                    llSetTimerEvent(10.0);
                }
                else if (collarIntegration)
                {
                    llSetTimerEvent(20.0);
                    collarID = NULL_KEY;
                    llListenRemove(listenHandle);
                    listenHandle = llListen(interfaceChannel, "", "", "");
                    counter = 0;
                    llWhisper(interfaceChannel, "OpenCollar?");
                    llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
                }
            }
        }
        else
        { // Else, we need to ensure the rest of the hud knows the collar is missing and needs to be refound.
            if (collarIntegration) // -- The collar is gone but we think it's still here
            {
                    llSetTimerEvent(20.0);
                    collarID = NULL_KEY;
                    llListenRemove(listenHandle);
                    listenHandle = llListen(interfaceChannel, "", "", "");
                    llWhisper(interfaceChannel, "OpenCollar?");
                    llMessageLinked(LINK_THIS, COLLAR_INT_REQ, "CollarOff", "");
            }
            else // -- We need to continue to ask if the collar is there
            {
                llWhisper(interfaceChannel, "OpenCollar?");
            }
        }
    }
}
