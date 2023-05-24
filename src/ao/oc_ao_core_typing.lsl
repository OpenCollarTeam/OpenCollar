/*
    A minimal re write of the AO System to use Linkset Data
    this script is intended to be a stand alone ao managed from linkset storage
    which would allow it to be populated by any interface script.
    Created: Febuary 5 2023
    By: Phidoux (taya.Maruti)
    ------------------------------------
    | Contributers  and updates below  |
    ------------------------------------
    | Name | Date | comment            |
    ------------------------------------
*/
//string g_sVersion = "1.2.0"; // version (major.minor(no greater than 9 if so rolle to major).bug)
float g_fTimer = 0.022;

TypingAO()
{
    if(llLinksetDataRead("Typing") != "" && llGetInventoryType(llLinksetDataRead("Typing")) == INVENTORY_ANIMATION && (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_typingctl"))
    {
        if(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_typing") || !(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
        {
            llStopAnimation(llLinksetDataRead("Typing"));
        }
        else
        {
            llStartAnimation(llLinksetDataRead("Typing"));
        }
    }
}

StopAO()
{
    llSetTimerEvent(0);
    if(llLinksetDataRead("Typing") != "")
    {
        llStopAnimation(llLinksetDataRead("Typing"));
    }
}

recordMemory()
{
    llLinksetDataWrite("memory_"+llGetScriptName(),(string)llGetUsedMemory());
}

check_settings(string sToken, string sDefaulVal)
{
    if(!~llListFindList(llLinksetDataListKeys(0,0),[sToken])) // token/key doesn't exist in the list of keys
    {
        llLinksetDataWrite(sToken, sDefaulVal);
    }
    else if(llLinksetDataRead(sToken) == "")
    {
        llLinksetDataWrite(sToken, sDefaulVal);
    }
}

default
{
    state_entry()
    {
        llSetTimerEvent(g_fTimer);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_typingctl",(string)TRUE);
        if(llGetAttached())
        {
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                if(!(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION))
                {
                    llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
                }
            }
        }
        recordMemory();
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {
            llSetTimerEvent(g_fTimer);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_typingctl",(string)TRUE);
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                if(!(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION))
                {
                    llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
                }
            }
            recordMemory();
        }
        else
        {
            // Turn off the ao when not worn.
            if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
            {
                llOwnerSay("Detaching so stoping animations!");
                llResetAnimationOverride("ALL");
            }
        }
    }

    run_time_permissions(integer iPerm)
    {
        if(iPerm & PERMISSION_TRIGGER_ANIMATION)
        {
        }
    }

    linkset_data(integer iAction,string sName,string sValue)
    {
        if( iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
            else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_power")
            {
                if((integer)sValue)
                {
                    llRequestPermissions(llGetOwner(),PERMISSION_TRIGGER_ANIMATION);
                }
                else
                {
                    if((llGetPermissions() & PERMISSION_TRIGGER_ANIMATION))
                    {
                        StopAO();
                    }
                }
            }
            else if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                if(sName == llToLower(llLinksetDataRead("addon_name"))+"_typing")
                {
                    TypingAO();
                }
            }
        }
        else if( iAction == LINKSETDATA_RESET)
        {
            llOwnerSay("Data reset so clearing AO");
            if(llGetPermissions()&PERMISSION_TRIGGER_ANIMATION)
            {
                StopAO();
            }
        }
    }
    timer()
    {
        integer iTyping = (llGetAgentInfo(llGetOwner())&AGENT_TYPING);
        if(iTyping != (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_typing"))
        {
            llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_typing",(string)iTyping);
        }
    }
}
