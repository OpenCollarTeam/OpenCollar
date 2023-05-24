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

// this list is of the animation states so that we can loop through and pick up each one from linkset data.
/*list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
    "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
    "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
    "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
    "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
];*/

wingsAO(string animState)
{

    if(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
    {
        if(llLinksetDataRead("wings_laststate") != animState && llLinksetDataRead(animState) != "")
        {
            if(llLinksetDataRead("wings_laststate") != "" && llLinksetDataRead(llLinksetDataRead("wings_laststate")) != "")
            {
                llStopAnimation(llLinksetDataRead(llLinksetDataRead("wings_laststate")));
            }
            llLinksetDataWrite("wings_laststate",animState);
            llStartAnimation(llLinksetDataRead(animState));
        }
    }
}

StopAO()
{
    llSetTimerEvent(0);
    if(llLinksetDataRead(llLinksetDataRead("wings_laststate")) != "")
    {
        llStopAnimation(llLinksetDataRead(llLinksetDataRead("wings_laststate")));
        llLinksetDataDelete("wings_laststate");
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
        
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_wingschange",(string)120);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_wingsrand",(string)TRUE);
        if(llGetAttached())
        {
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                if(llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                {
                    wingsAO("Wings "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_animstate"));
                }
                else
                {
                    llRequestPermissions(llGetOwner(),PERMISSION_OVERRIDE_ANIMATIONS | PERMISSION_TRIGGER_ANIMATION);
                }
            }
        }
        recordMemory();
    }
    attach(key kID)
    {
        if(kID != NULL_KEY)
        {

            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_wingschange",(string)120);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_wingsrand",(string)TRUE);
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                if(llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                {
                    wingsAO("Wings "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_animstate"));
                }
                else
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
                StopAO();
            }
        }
    }

    run_time_permissions(integer iPerm)
    {
        if(iPerm & PERMISSION_TRIGGER_ANIMATION)
        {
            wingsAO("Wings "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_animstate"));
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
                    wingsAO("Wings "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_animstate"));
                }
                else
                {
                    if(llGetPermissions()&PERMISSION_TRIGGER_ANIMATION)
                    {
                        StopAO();
                    }
                }
            }
            else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_animstate")
            {
                wingsAO("Wings "+sValue);
            }
            else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_wingstimer")
            {
                list lAnims = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Wings Standing"),[","],[]);
                integer i;
                if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_wingsdrand"))
                {
                    i = (integer)llFrand((llGetListLength(lAnims)-1));
                }
                else
                {
                    i = llListFindList(lAnims,[llLinksetDataRead("Wings Standing")])+1;
                    if ( i >= llGetListLength(lAnims))
                    {
                        i = 0;
                    }
                }
                string sAnim = llList2String(lAnims,i);
                if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION && sAnim != llLinksetDataRead("Wings Standing"))
                {
                    llLinksetDataWrite("Wings Standing",sAnim);
                }
                sAnim = "";
                lAnims = [];
                wingsAO("Wings "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_animstate"));
            }
        }
        else if( iAction == LINKSETDATA_RESET)
        {
            if(llGetPermissions()&PERMISSION_TRIGGER_ANIMATION)
            {
                StopAO();
            }
        }
    }

    timer()
    {
    }
}
