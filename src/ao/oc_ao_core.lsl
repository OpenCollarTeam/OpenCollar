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
//float g_fTimer = 0.000000001; // need a fast timer for the ao

// this list is of the animation states so that we can loop through and pick up each one from linkset data.
list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
    "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
    "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
    "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
    "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
];

list g_lSwimStates = [
    "Flying","FlyingSlow","Hovering","Hovering Down","Hovering Up"
];

// this list is garbage collection to keep the script clean and to solve for a bug causing (: Could not find animation ''.) where a reandom blank animation was beeing injected.
list g_lIgnore = [
    "\\","\"","[","]",".","/"," ",
    "(",")","?","!","@","#","$","%",
    "^","&","*","'",":",";","|","<",
    ">",",","-","=","+","_",""
];

SetAO()
{
    /*
        This Section is greatly simplified because all its going to manage is the ao list
        form Linkset Data we will be able to do tricks in another script to manage things like
        swiming by replacing the fly/hover animations with swim ones so this section
        has no reason to care about a list.
    */
    if (llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS && (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power") && !(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere") )
    {
        integer i;
        integer iListLen = llGetListLength(g_lAnimStates);
        string sAnim;
        string sAnimState;
        integer iLoaded = 0;
        for (i = 0; i<iListLen; i++)
        {
            sAnimState = llList2String(g_lAnimStates,i);
            if(~llListFindList(g_lSwimStates,[sAnimState]) && (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_swiming"))
            {
                // if swimming convert the use the swim animations for these states.
                string sSwimState = "";
                if(sAnimState == "Flying" || sAnimState == "Running")
                {
                    sSwimState = "Swim Forward";
                }
                else if(sAnimState == "FlyingSlow" || sAnimState == "Walking")
                {
                    sSwimState = "Swim Slow";
                }
                else if(sAnimState == "Hovering" || sAnimState == "Striding" || sAnimState == "Falling Down")
                {
                    sSwimState = "Swim Hover";
                }
                else if(sAnimState == "Hovering Down")
                {
                    sSwimState = "Swim Down";
                }
                else if(sAnimState == "Hovering Up")
                {
                    sSwimState = "Swim Up";
                }
                if(llLinksetDataRead(sSwimState) != "") // only use the swim animation if it exists
                {
                    sAnim = llLinksetDataRead(sSwimState);
                }
                else
                {
                    sAnim = llLinksetDataRead(sAnimState);
                }
                sSwimState = "";
            }
            else
            {
                sAnim = llLinksetDataRead(sAnimState);
            }
            if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION && !~llListFindList(g_lIgnore,[sAnim]))
            {
                if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitctl"))
                {
                    llResetAnimationOverride(sAnimState);
                    llSleep(0.1);
                    llSetAnimationOverride(sAnimState, sAnim);
                }
                else if(sAnimState != "Sitting")
                {
                    llResetAnimationOverride(sAnimState);
                    llSleep(0.1);
                    llSetAnimationOverride(sAnimState, sAnim);
                }
                iLoaded++;
            }
            else if( sAnim != "")
            {
                // we may have to change this up a bit but for now this will alert us if any animations are not in the ao.
                llOwnerSay("Animation ("+sAnim+") could not be found.");
            }
        }
        //llOwnerSay((string)iLoaded+"/"+(string)iListLen+" Aniamtions were loaded");
        sAnim = "";
        sAnimState = "";
    }
}

StopAO()
{
    llSetTimerEvent(0);
    if(llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
    {
        if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere"))
        {
            llStopAnimation("Sitting on Ground");
        }
        llResetAnimationOverride("ALL");
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

gsitAO()
{
    if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere"))
    {
        llOwnerSay("Starting animation:"+llLinksetDataRead("Sitting on Ground"));
        llStartAnimation(llLinksetDataRead("Sitting on Ground"));
    }
    else
    {
        list lGSit = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Sitting on Ground"),[","],[]);
        integer iIndex;
        for(iIndex = 0; iIndex < (llGetListLength(lGSit)-1); iIndex++)
        {
            llStopAnimation(llList2String(lGSit,iIndex));
        }
        lGSit = [];
        llSleep(0.1);
        SetAO();
    }
}

default
{
    state_entry()
    {
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_wingschange",(string)120);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_wingsrand",(string)TRUE);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_standchange",(string)120);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_standrand",(string)TRUE);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere",(string)FALSE);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitctl",(string)FALSE);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitchange",(string)120);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitrand",(string)FALSE);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_gsitchange",(string)120);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_gsitrand",(string)FALSE);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_walkchange",(string)120);
        check_settings(llToLower(llLinksetDataRead("addon_name"))+"_walkrand",(string)TRUE);
        if(llGetAttached())
        {
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                llSetTimerEvent(1);
                if(llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
                {
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_animstate",llGetAnimation(llGetOwner()));
                    SetAO();
                    gsitAO();
                }
                else
                {
                    llRequestPermissions((key)llGetOwner(),PERMISSION_OVERRIDE_ANIMATIONS | PERMISSION_TRIGGER_ANIMATION);
                }
            }
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_standchange"))
            {
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_standtimer",(string)(llGetUnixTime()+(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_standchange")));
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
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_standchange",(string)120);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_standrand",(string)TRUE);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere",(string)FALSE);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitctl",(string)FALSE);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitchange",(string)120);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_sitrand",(string)FALSE);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_gsitchange",(string)120);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_gsitrand",(string)FALSE);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_walkchange",(string)120);
            check_settings(llToLower(llLinksetDataRead("addon_name"))+"_walkrand",(string)TRUE);
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                llSetTimerEvent(1);
                if((llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) && (llGetPermissions() & PERMISSION_TRIGGER_ANIMATION))
                {
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_animstate",llGetAnimation(llGetOwner()));
                    SetAO();
                    gsitAO();
                }
                else
                {
                    llRequestPermissions((key)llGetOwner(),PERMISSION_OVERRIDE_ANIMATIONS | PERMISSION_TRIGGER_ANIMATION);
                }
            }
            recordMemory();
        }
        else
        {
            llSetTimerEvent(0);
            // Turn off the ao when not worn.
            if(llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS && llGetPermissions() & PERMISSION_TRIGGER_ANIMATION)
            {
                llOwnerSay("Detaching so stoping animations!");
                //llResetAnimationOverride("ALL"); - wish it worked this way
            }
        }
    }

    run_time_permissions(integer iPerm)
    {
        if(iPerm & PERMISSION_OVERRIDE_ANIMATIONS)
        {
            SetAO();
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
            if(sName == llToLower(llLinksetDataRead("addon_name"))+"_power")
            {
                if((integer)sValue)
                {
                    llRequestPermissions(llGetOwner(),PERMISSION_OVERRIDE_ANIMATIONS | PERMISSION_TRIGGER_ANIMATION);
                    llOwnerSay("Powering AO on!");
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_animstate",llGetAnimation(llGetOwner()));
                    llSetTimerEvent(1);
                }
                else
                {
                    if(llGetPermissions()&PERMISSION_OVERRIDE_ANIMATIONS)
                    {
                        llOwnerSay("Power Removing Animations!");
                        llSetTimerEvent(0);
                        StopAO();
                    }
                }
            }
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
                if(llListFindList(g_lAnimStates,[sName]) != -1 && sValue != "" && !(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere"))
                {
                    llResetAnimationOverride(sName);
                    llSleep(0.1);
                    llSetAnimationOverride(sName,sValue);
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere")
                {
                    gsitAO();
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_swiming")
                {
                    SetAO();
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_standchange" && (integer)sValue)
                {
                    if((integer)sValue < 0)
                    {
                        sValue = "0";
                    }
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_standtimer",(string)(llGetUnixTime()+(integer)sValue));
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_sitctl" && !(integer)sValue)
                {
                    llResetAnimationOverride("Sitting");
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_walkchange" && (integer)sValue)
                {
                    if((integer)sValue < 0)
                    {
                        sValue = "0";
                    }
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_walktimer",(string)(llGetUnixTime()+(integer)sValue));
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_sitchange" && (integer)sValue)
                {
                    if((integer)sValue < 0)
                    {
                        sValue = "0";
                    }
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_sittimer",(string)(llGetUnixTime()+(integer)sValue));
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_gsitchange" && (integer)sValue)
                {
                    if((integer)sValue < 0)
                    {
                        sValue = "0";
                    }
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_gsittimer",(string)(llGetUnixTime()+(integer)sValue));
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_loaded" && (integer)sValue)
                {
                    SetAO();
                }
                else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere")
                {
                    SetAO();
                }
            }
        }
        else if( iAction == LINKSETDATA_RESET)
        {
            llOwnerSay("Data reset so clearing AO");
            if(llGetPermissions()&PERMISSION_OVERRIDE_ANIMATIONS)
            {
                StopAO();
            }
        }
    }
    timer()
    {
        // Detact if we are in water to enable the swimming anims.
        llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_animstate",llGetAnimation(llGetOwner()));
        if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_standchange") != 0 && llGetUnixTime() > (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_standtimer"))
        {
            list lAnims = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Standing"),[","],[]);
            integer i;
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_standrand"))
            {
                i = (integer)llFrand((llGetListLength(lAnims)-1));
            }
            else
            {
                i = llListFindList(lAnims,[llLinksetDataRead("Standing")])+1;
                if ( i >= llGetListLength(lAnims))
                {
                    i = 0;
                }
            }
            string sAnim = llList2String(lAnims,i);
            if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION && sAnim != llLinksetDataRead("Standing"))
            {
                llLinksetDataWrite("Standing",sAnim);
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_standtimer",(string)(llGetUnixTime()+(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_standchange")));
            }
            sAnim = "";
            lAnims = [];
        }
        else if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_walkchange") != 0 && llGetUnixTime() > (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_walktimer"))
        {
            list lAnims = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Walking"),[","],[]);
            integer i;
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_walkrand"))
            {
                i = (integer)llFrand((llGetListLength(lAnims)-1));
            }
            else
            {
                i = llListFindList(lAnims,[llLinksetDataRead("Walking")])+1;
                if ( i >= llGetListLength(lAnims))
                {
                    i = 0;
                }
            }
            string sAnim = llList2String(lAnims,i);
            if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION && sAnim != llLinksetDataRead("Walking"))
            {
                llLinksetDataWrite("Walking",sAnim);
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_walktimer",(string)(llGetUnixTime()+(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_walkchange")));
            }
            sAnim = "";
            lAnims = [];
        }
        else if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitchange") != 0 && (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitctl") && llGetUnixTime() > (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sittimer"))
        {
            list lAnims = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Sitting"),[","],[]);
            integer i;
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitrand"))
            {
                llOwnerSay("Choosing random animation for sit");
                i = (integer)llFrand((llGetListLength(lAnims)-1));
            }
            else
            {
                llOwnerSay("Choosing next animation for sitting");
                i = llListFindList(lAnims,[llLinksetDataRead("Sitting")])+1;
                if ( i >= llGetListLength(lAnims))
                {
                    i = 0;
                }
            }
            string sAnim = llList2String(lAnims,i);
            if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION && sAnim != llLinksetDataRead("Sitting"))
            {
                llOwnerSay("Changing Sit to "+sAnim);
                llLinksetDataWrite("Sitting",sAnim);
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_sittimer",(string)(llGetUnixTime()+(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitchange")));
            }
            sAnim = "";
            lAnims = [];
        }
        else if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_tailchange") != 0 && llGetUnixTime() > (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_tailtimer"))
        {
            list lAnims = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Tail Standing"),[","],[]);
            integer i;
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_tailrand"))
            {
                i = (integer)llFrand((llGetListLength(lAnims)-1));
            }
            else
            {
                i = llListFindList(lAnims,[llLinksetDataRead("Tail Standing")])+1;
                if ( i >= llGetListLength(lAnims))
                {
                    i = 0;
                }
            }
            string sAnim = llList2String(lAnims,i);
            if((llGetInventoryType(sAnim) & INVENTORY_ANIMATION) && sAnim != llLinksetDataRead("Tail Standing"))
            {
                llLinksetDataWrite("Tail Standing",sAnim);
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_tailtimer",(string)(llGetUnixTime()+(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_tailchange")));
            }
            sAnim = "";
            lAnims = [];
        }
        else if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_wingschange") != 0 && llGetUnixTime() > (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_wingstimer"))
        {
            list lAnims = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Wings Standing"),[","],[]);
            integer i;
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_wingsrand"))
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
            if((llGetInventoryType(sAnim) & INVENTORY_ANIMATION) && sAnim != llLinksetDataRead("Wings Standing"))
            {
                llLinksetDataWrite("Wings Standing",sAnim);
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_wingstimer",(string)(llGetUnixTime()+(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_wingschange")));
            }
            sAnim = "";
            lAnims = [];
        }
        else if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_gsitchange") != 0 && llGetUnixTime() > (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_gsittimer"))
        {
            list lAnims = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_Sitting on Ground"),[","],[]);
            integer i;
            if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_gsitrand"))
            {
                i = (integer)llFrand((llGetListLength(lAnims)-1));
            }
            else
            {
                i = llListFindList(lAnims,[llLinksetDataRead("Sitting on Ground")])+1;
                if ( i >= llGetListLength(lAnims))
                {
                    i = 0;
                }
            }
            string sAnim = llList2String(lAnims,i);
            llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_gsitold",llLinksetDataRead("Sitting on Ground"));
            if((llGetInventoryType(sAnim) & INVENTORY_ANIMATION) && sAnim != llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_gsitold"))
            {
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_gsittimer",(string)(llGetUnixTime()+(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_gsitchange")));
                llLinksetDataWrite("Sitting on Ground",sAnim);
                if((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere"))
                {
                    llStopAnimation(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_gsitold"));
                    llSleep(0.1);
                    llStartAnimation(sAnim);
            `   }
            }
            sAnim = "";
            lAnims = [];
        }
    }
}
