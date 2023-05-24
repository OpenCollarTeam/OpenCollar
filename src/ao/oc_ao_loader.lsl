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

// Load note cards and set aniamtin states

integer g_iCardLine = 0;

key g_kCard;

list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
    "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
    "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
    "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
    "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
];

list g_lWingStates = [
    "Wings Crouching","Wings CrouchWalking","Wings Falling Down","Wings Flying","Wings FlyingSlow",
    "Wings Hovering","Wings Hovering Down","Wings Hovering Up","WingsJumping","Wings Landing",
    "Wings PreJumping","Wings Running","Wings Standing","Wings Sitting","Wings Sitting on Ground","Wings Standing Up",
    "Wings Striding","Wings Soft Landing","Wings Taking Off","Wings Turning Left","Wings Turning Right","Wings Walking"
];

list g_lTailStates = [
    "Tail Crouching","Tail CrouchWalking","Tail Falling Down","Tail Flying","Tail FlyingSlow",
    "Tail Hovering","Tail Hovering Down","Tail Hovering Up","TailJumping","Tail Landing",
    "Tail PreJumping","Tail Running","Tail Standing","Tail Sitting","Tail Sitting on Ground","Tail Standing Up",
    "Tail Striding","Tail Soft Landing","Tail Taking Off","Tail Turning Left","Tail Turning Right","Tail Walking"
];


list g_lSwimStates = ["Swim Forward","Swim Hover","Swim Slow","Swim Up","Swim Down"];

recordMemory()
{
    llLinksetDataWrite("memory_"+llGetScriptName(),(string)llGetUsedMemory());
}

//
default
{
    state_entry()
    {
        recordMemory();
    }
    linkset_data(integer iAction, string sName, string sVal)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
            else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_card" && sVal != "" && llGetInventoryType(sVal) == INVENTORY_NOTECARD && !(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_loaded"))
            {
                llOwnerSay("loading note card "+sVal);
                llResetTime();
                g_iCardLine = 0;
                g_kCard = llGetNotecardLine(sVal,g_iCardLine);
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }

    dataserver(key kRequest, string sData)
    {
        if (kRequest == g_kCard)
        {
            if (sData != EOF)
            {
                if (llGetSubString(sData,0,0) != "[")
                {
                     jump next;
                }
                string sAnimationState = llStringTrim(llGetSubString(sData,1,llSubStringIndex(sData,"]")-1),STRING_TRIM);
                // Translate common ZHAOII, Oracul and AX anim state values
                if (sAnimationState == "Stand.1" || sAnimationState == "Stand.2" || sAnimationState == "Stand.3")
                {
                    sAnimationState = "Standing";
                }
                else if (sAnimationState == "Walk.N")
                {
                    sAnimationState = "Walking";
                }
                else if (sAnimationState == "Running")
                {
                    sAnimationState = "Running";
                }
                else if (sAnimationState == "Turn.L")
                {
                    sAnimationState = "Turning Left";
                }
                else if (sAnimationState == "Turn.R")
                {
                    sAnimationState = "Turning Right";
                }
                else if (sAnimationState == "Sit.N")
                {
                    sAnimationState = "Sitting";
                }
                else if (sAnimationState == "Sit.G" || sAnimationState == "Sitting On Ground")
                {
                    sAnimationState = "Sitting on Ground";
                }
                else if (sAnimationState == "Crouch" || sAnimationState == "Crouching")
                {
                    sAnimationState = "Crouching";
                }
                else if (sAnimationState == "Walk.C" || sAnimationState == "Crouch Walking")
                {
                    sAnimationState = "CrouchWalking";
                }
                else if (sAnimationState == "Jump.N" || sAnimationState == "Jumping")
                {
                    sAnimationState = "Jumping";
                }
                else if (sAnimationState == "Takeoff")
                {
                    sAnimationState = "Taking Off";
                }
                else if (sAnimationState == "Hover.N")
                {
                    sAnimationState = "Hovering";
                }
                else if (sAnimationState == "Hover.U" || sAnimationState == "Flying Up")
                {
                    sAnimationState = "Hovering Up";
                }
                else if (sAnimationState == "Hover.D" || sAnimationState == "Flying Down")
                {
                    sAnimationState = "Hovering Down";
                }
                else if (sAnimationState == "Fly.N")
                {
                    sAnimationState = "Flying";
                }
                else if (sAnimationState == "Flying Slow")
                {
                    sAnimationState = "FlyingSlow";
                }
                else if (sAnimationState == "Land.N")
                {
                    sAnimationState = "Landing";
                }
                else if (sAnimationState == "Falling")
                {
                    sAnimationState = "Falling Down";
                }
                else if (sAnimationState == "Jump.P" || sAnimationState == "Pre Jumping")
                {
                    sAnimationState = "PreJumping";
                }
                else if (sAnimationState == "Stand.U")
                {
                    sAnimationState = "Standing Up";
                }
                if (!~llListFindList(g_lAnimStates,[sAnimationState]) && !~llListFindList(g_lWingStates,[sAnimationState]) && !~llListFindList(g_lTailStates,[sAnimationState]) && !~llListFindList(g_lSwimStates,[sAnimationState]) && sAnimationState != "Typing")
                {
                    jump next;
                }
                if (llStringLength(sData)-1 > llSubStringIndex(sData,"]"))
                {
                    sData = llGetSubString(sData,llSubStringIndex(sData,"]")+1,-1);
                    list lTemp = llParseString2List(sData, ["|",","],[]);
                    string sAnim = sData;
                    if(~llSubStringIndex(sData,"|") || ~llSubStringIndex(sData,","))
                    {
                        llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_"+sAnimationState,llDumpList2String(lTemp,","));
                        sAnim = llList2String(lTemp,0);
                    }
                    if(llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
                    {
                        llLinksetDataWrite(sAnimationState,sAnim);
                    }
                }
                @next;
                g_kCard = llGetNotecardLine(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_card"),++g_iCardLine);
            }
            else
            {
                llOwnerSay(
                    "Note Card "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_card")+" Loaded into Linkset Data in "+(string)llGetTime()+"s"+
                    "\nLinksetMemory free: "+(string)llLinksetDataAvailable()+"bytes"
                );

                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_loaded",(string)TRUE);
                g_kCard = "";
            }
        }
        recordMemory();
    }
}
