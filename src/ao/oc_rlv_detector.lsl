integer s2Int(string input)
{
    return (integer)("0x"+llGetSubString(input,-8,-1));
}

integer Key2Chan(key id,string salt)
{
    integer chan = s2Int((string)id)+s2Int(salt)+llList2Integer(llParseString2List(llGetDate(),["-"],[]),2);
    while(chan > 2147483647)
    {
        chan = chan-2147483647;
    }
    if(chan <= 0)
    {
        // must always have a positive channel.
        chan = (integer)llFrand(2147483646)+1;
    }
    return chan;
}

recordMemory()
{
    llLinksetDataWrite("memory_"+llGetScriptName(),(string)llGetUsedMemory());
}

RLV_Listen()
{
    llOwnerSay("Checking for RLV please wait!");
    llLinksetDataWrite("rlv_channel",(string)Key2Chan(llGetOwner(),llGetDate()));
    llLinksetDataWrite("rlv_Listen",(string)llListen((integer)llLinksetDataRead("rlv_channel"),llKey2Name(llGetOwner()),llGetOwner(),""));
    llOwnerSay("@versionnew="+llLinksetDataRead("rlv_channel"));
    llLinksetDataWrite("rlv_timeout",(string)(llGetUnixTime()+30));
}

default
{
    state_entry()
    {
        recordMemory();
        if(llGetAttached())
        {
            RLV_Listen();
            llSetTimerEvent(1);
        }
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llResetScript();
        }
    }
    changed(integer iChange)
    {
        if(iChange & CHANGED_OWNER)
        {
            llLinksetDataReset();
        }
    }
    listen( integer iChan, string sName, key kID, string sMsg)
    {
        if(~llSubStringIndex(llToLower(sMsg),"rlv"))
        {
            llListenRemove((integer)llLinksetDataRead("rlv_listen"));
            state RLV_Ready;
        }
    }
    timer()
    {
        if(llGetUnixTime()>(integer)llLinksetDataRead("rlv_timeout"))
        {
            llListenRemove((integer)llLinksetDataRead("rlv_listen"));
            state RLV_Fail;
        }
    }
    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_RESET)
        {
            llListenRemove((integer)llLinksetDataRead("rlv_listen"));
            llResetScript();
        }
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
        }
    }
}

state RLV_Fail
{
    state_entry()
    {
        llLinksetDataWrite("glboal_rlv",(string)FALSE);
        llLinksetDataWrite("rlv_retry",(string)(llGetUnixTime()+3600));
        llOwnerSay("RLV is not availble please relog with rlv enabled, this script will retry in an hour!");
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llResetScript();
        }
    }
    changed(integer iChange)
    {
        if(iChange & CHANGED_OWNER)
        {
            llLinksetDataReset();
        }
    }
    timer()
    {
        if(llGetUnixTime() > (integer)llLinksetDataRead("rlv_retry"))
        {
            state default;
        }
    }

    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
        }
    }
}
state RLV_Ready
{
    state_entry()
    {
        llOwnerSay("RLV Successfully detected refresh in 1 hour");
        llLinksetDataWrite("global_rlv",(string)TRUE);
        llLinksetDataWrite("rlv_renew",llGetDate());
        llSetTimerEvent(1);
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llResetScript();
        }
    }
    changed(integer iChange)
    {
        if(iChange & CHANGED_OWNER)
        {
            llLinksetDataReset();
        }
    }
    linkset_data(integer iAction,string sName,string sValue)
    {
        if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
        }
    }
}
