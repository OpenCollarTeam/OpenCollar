////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           OpenCollar - leashholder                             //
//                                 version 3.940                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// based on a script by Ilse Mannonen

integer g_iMychannel = -8888;
string g_sListenfor;
string g_sResponse;

AnnounceLeashHolder()
{
    llSay(g_iMychannel, g_sResponse);
}

default
{
    state_entry()
    {
        g_sListenfor = (string)llGetOwner() + "handle";
        g_sResponse = (string)llGetOwner() + "handle ok";
        llListen(g_iMychannel, "", NULL_KEY, g_sListenfor);
        AnnounceLeashHolder();
        llSetTimerEvent(2.0);              
    }
    
    listen(integer channel, string name, key id, string message)
    {
        AnnounceLeashHolder();
        llSetTimerEvent(2.0);
    }
    attach(key kAttached)
    {
        if (kAttached == NULL_KEY)
        {
            llSay(g_iMychannel, (string)llGetOwner() + "handle detached");
        }
    }
    changed(integer change)
    {
        if (change & CHANGED_TELEPORT)
        {
            AnnounceLeashHolder();
            llSetTimerEvent(2.0);
        }
    }
    timer()
    {
        llSetTimerEvent(0.0);
        AnnounceLeashHolder();
    }
    on_rez(integer param)
    {
        llResetScript();
    }
}
