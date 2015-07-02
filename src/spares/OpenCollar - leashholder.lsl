//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                            Lead - 150527.1                               //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//  Copyright (C) 2008 - 2015:    Individual Contributors                   //
//                                OpenCollar - submission set free(TM)      //
//                                and Virtual Disgrace(TM)                  //
// ------------------------------------------------------------------------ //
//  Source Code Repository:       github.com/OpenCollar/OC                  //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

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
        llSetMemoryLimit(10240);
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
