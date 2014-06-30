////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - AO Link                               //
//                                 version 0.100                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// BETA VERSION NOTES ---------------------------------------------------
// Medea Destiny's AO interface script for OpenCollar
// This script is inteneded to be a drop-in for ZHAO-2 and Oracul AOs that are not
// already compatible with OpenCollar's AO interface. 

// Scope: The script tries to identify the AO type by checking script naming. It receives
// the ZHAO ON, ZHAO OFF and ZHAO Menu commands from the collar, and uses link messages to 
// send appropriate commands to the AO, depending on the detected collar type. It is not a
// complete replacement of the Sub AO as it cannot allow as complete access to the AO as
// that does, but it should provide most of the functionality while being very easy to add to 
// user's pre-existing AOs.

// When the AO is switched on, but the collar sends a command to switch it off, the script
// will take controls and detect for movement. While the avatar is trying to move, the AO will
// told to switch the AO back on again until movement ceases. 

// An alternative to this method would be to capture the AO's walk animation and play the animation
// itself as a walk overrider. The disadvantage of that is trying to capture the walk animation
// isn't straightforward, particular when there is more than one walk configured. The disadvantage
// of this method is that it does a lot more AO triggering. 

// Comments and bug reports to Medea Destiny, please!
//---------------------------------------------------------------------
integer type; 
//If left like this, script will try to determine AO type automatically.
//To force compatibility for a particular type of AO, change to:
// integer type=1; //for zhao2 type AOs
// integer type=2; // for Oracul type AOs
//----------------------------------------------------------------------
//Integer map for above
integer ZHAO=1; 
integer ORACUL=2;

// OC channel listener for comms from collar
integer g_iAOChannel = -782690;
integer g_iAOListenHandle;

//Menu handler for script's own ZHAO menu
integer g_iMenuHandle; 
integer g_iMenuChannel=-23423456; //dummy channel, changed to unique on attach
list g_lMenuUsers; //list of menu users to allow for multiple users of menu 
integer g_iMenuTimeout=60;

string g_sOraculstring; //configuration string for Oracul power on/off, 0 prepended for off, 1 prepended for on

//We use these two so that we can return the AO to its previous state. If the AO was already off when the OC tries to switch it off, we shouldn't switch it back on again.
integer g_iAOSwitch=TRUE; //monitor on/off from the AO's own state.
integer g_iOCSwitch=TRUE; //monitor on/off due to collar pauses (FALSE=paused, TRUE=unpaused)


integer g_iSitOverride=TRUE; //monitor AO sit override

integer g_iHasPerm; //Sanity check for permissions. If we have permissions, then script takes controls and restores AO while moving.


determineType() //function to determine AO type.
{
    llListenRemove(g_iAOListenHandle);
    type=0;
    integer x=llGetInventoryNumber(INVENTORY_SCRIPT);
    while(x)
    {
        --x;
        string t=llToLower(llGetInventoryName(INVENTORY_SCRIPT,x));
        if(~llSubStringIndex(t,"zhao")) //if we find a script with "zhao" in the name.
        {
            type=ZHAO;
            x=0;
            llOwnerSay("OC compatibility script configured for Zhao AO. Depending on your AO model, you may sometimes see your AO buttons get out of sync when the AO is accessed via the collar, just toggle a setting to restore it. NOTE! Toggling sit override now is highly recommended, but if you don't know what that means or don't have one, don't worry.");
            llMessageLinked(LINK_SET, 0, "ZHAO_AOON", "");
            
        }
        if(~llSubStringIndex(t,"oracul")) //if we find a script with "oracul" in the name.
        {
            type=ORACUL;
            x=0;
            llOwnerSay("OC compatibility script configured for Oracul AO. IMPORTANT: for proper functioning, you must now switch your AO on (switching it off first if necessary!)");
        }
    }
    if(type==0) llOwnerSay("Cannot identify AO type. The script:"+llGetScriptName()+" is intended to be dropped into a Zhao2 or Oracul AO hud.");
    else 
    {
       g_iAOListenHandle=llListen(g_iAOChannel,"","",""); //We identified type, start script listening!
    }
}


AOPause()
{
    if(g_iAOSwitch)
    {
        //Note: for ZHAO use LINK_THIS in pause functions, LINK_SET elsewhere. This is because ZHAOs which switch power on buttons by a script in the button reading the link messages are quite common. This avoids toggling the power switch when AO is only paused in those cases.
        if(type==ZHAO) llMessageLinked(LINK_THIS, 0, "ZHAO_AOOFF", "ocpause");//we use "ocpause" as a dummy key to identify our own linked messages so we can tell when an on or off comes from the AO rather than from the collar standoff, to sync usage.
        else if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_SET,0,"0"+g_sOraculstring,"ocpause");
    }
    g_iOCSwitch=FALSE;
    if(g_iAOSwitch==TRUE) llRequestPermissions(llGetOwner(),PERMISSION_TAKE_CONTROLS);//AO is supposed to be on, so we take controls here to allow it to be switched back on temporarily whilst moving.
}

AOUnPause()
{
    if(g_iAOSwitch)
    {
        if(type==ZHAO) llMessageLinked(LINK_THIS, 0, "ZHAO_AOON", "ocpause"); 
        else if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_SET,0,"1"+g_sOraculstring,"ocpause");
    }
    g_iOCSwitch=TRUE;
    if(llGetPermissionsKey()) llReleaseControls(); //if we took permissions, release them so the AO can do its own thing now.
}

zhaoMenu(key kMenuTo)
{
    //script's own menu for some ZHAO features. 
    //Open listener if no menu users are registered in g_lMenuUsers already, and add 
    //menu user to list if not already present.
    if(!llGetListLength(g_lMenuUsers)) g_iMenuHandle=llListen(g_iMenuChannel,"","","");
    if(llListFindList(g_lMenuUsers,[kMenuTo])==-1) g_lMenuUsers+=kMenuTo;
    string sSit="AO Sits ON";
    if(g_iSitOverride) sSit="AO Sits OFF";
    list lButtons=[sSit,"Load Notecard","Done","AO on","AO off","Next Stand"];
    llSetTimerEvent(g_iMenuTimeout);
    llDialog(kMenuTo,"AO options. Depending on model of AO, some may not work. Use OC Sub AO for more comprehensive control!",lButtons,g_iMenuChannel);   
}
                                   
default
{
    state_entry()
    {
       if(type==0) determineType();
       g_iMenuChannel=-(integer)llFrand(999999)-10000; //randomise menu channel
    }
    
    attach(key avatar)
    {
        if(avatar) //on attach
        {
            if(type==0) determineType();
            g_iMenuChannel=-(integer)llFrand(999999)-10000; //randomise menu channel 
        }  
    }
    
    listen(integer iChannel, string sName, key kID, string sMsg)
    {

        if(iChannel==g_iMenuChannel) // this is for our own limited ZHAO menu.
        {
            if(sMsg=="Done"||sMsg=="Cancel")
            {
                integer i=llListFindList(g_lMenuUsers,[kID]);
                if(i>-1) g_lMenuUsers=llDeleteSubList(g_lMenuUsers,i,i); //remove user from menu users list.
                if(!llGetListLength(g_lMenuUsers)) //remove listener if no menu users left
                {
                    llListenRemove(g_iMenuHandle);
                    llSetTimerEvent(0);
                }
                return; // we're done here!
            }
            else if(sMsg=="Load Notecard") //scan for notecards and provide a dialog to user
            {
                list lButtons;
                integer x=llGetInventoryNumber(INVENTORY_NOTECARD);
                while(x)
                {
                    x--;
                    string t=llGetInventoryName(INVENTORY_NOTECARD,x);
                   if(llSubStringIndex(llToLower(t),"read me")==-1 && llSubStringIndex(llToLower(t),"help")==-1 && llStringLength(t)<23) lButtons+=t; //we only take notecards without "help" or "read me" in the title and with short enough names to fit on a button.
                }
                if(llGetListLength(lButtons)>11)
                {
                    llRegionSayTo(kID,0,"Too many notecards found, displaying the first 11"); //ZHAO doesn't bother multi pages, so we won't.
                    lButtons=llDeleteSubList(lButtons,11,-1);
                }
                llSetTimerEvent(g_iMenuTimeout);
                llDialog(kID,"Pick an AO settings notecard to load, or click Cancel",lButtons+["Cancel"],g_iMenuChannel);
                
            }
            else if(sMsg=="AO Sits ON")
            {
                g_iSitOverride=TRUE; //this will get set by the link message anyway, but set here just in case remenu happens before link message is read.
                llMessageLinked(LINK_SET,0,"ZHAO_SITON","");
            }
            else if(sMsg=="AO Sits OFF")
            {
                g_iSitOverride=FALSE;
                llMessageLinked(LINK_SET,0,"ZHAO_SITOFF","");
            }
            else if(sMsg=="AO on")
            {
                if(g_iOCSwitch) llMessageLinked(LINK_SET,0,"ZHAO_AOON",""); // don't switch on AO if we are paused
                else llRequestPermissions(llGetOwner(),PERMISSION_TAKE_CONTROLS); //AO was switched on while we are paused, so we take permissions to allow unpausing whilst  movement
                g_iAOSwitch=TRUE;
            }
            else if(sMsg=="AO off")
            {
                llMessageLinked(LINK_SET,0,"ZHAO_AOOFF","");
                if(llGetPermissions()) llReleaseControls(); //if AO is off, we don't want to be checking controls.
            }
            else if(sMsg=="Next Stand") llMessageLinked(LINK_SET,0,"ZHAO_NEXTSTAND","");
            //check if sMsg is a notecard picked from Load Notecard menu, and send load command if so.
             else  if(llGetInventoryType(sMsg)==INVENTORY_NOTECARD) llMessageLinked(LINK_THIS,0,"ZHAO_LOAD|"+sMsg,"");
            //resend the menu where it makes sense.
            if(sMsg!="Done" && sMsg!="Cancel" && sMsg!="Load Notecard") zhaoMenu(kID);
            return;
        }
        else if(llGetOwnerKey(kID)!=llGetOwner()) return; //reject commands from other sources. 
        else if (iChannel==g_iAOChannel)
        {
            if(sMsg=="ZHAO_STANDON") AOUnPause();
            else if (sMsg=="ZHAO_STANDOFF") AOPause();
            else if (sMsg=="ZHAO_AOOFF")
            {
                if(type==ZHAO) llMessageLinked(LINK_SET,0,"ZHAO_AOOFF","");
                else llMessageLinked(LINK_SET,0,"0"+g_sOraculstring,"ocpause");
                if(llGetPermissions()) llReleaseControls();
            }
            else if (sMsg=="ZHAO_AOON")
            {
                if(g_iOCSwitch)// don't switch on AO if we are paused
                {
                    if(type==ZHAO) llMessageLinked(LINK_SET,0,"ZHAO_AOON",""); 
                    else llMessageLinked(LINK_SET,0,"1"+g_sOraculstring,"");
                }
                else llRequestPermissions(llGetOwner(),PERMISSION_TAKE_CONTROLS); //AO was switched on while we are paused, so we take permissions to allow unpausing whilst  moving.
                g_iAOSwitch=TRUE;
            } 
            else if (llGetSubString(sMsg,0,8)=="ZHAO_MENU")
            {
                key kMenuTo=(key)llGetSubString(sMsg,10,-1);
                if(type==ORACUL) llMessageLinked(LINK_SET,4,"",kMenuTo);
                else if (type==ZHAO) zhaoMenu(kMenuTo);
            }
        } 
    }
    
    link_message(integer iPrim, integer iNum, string sMsg, key kID)
    {
        if (type==ORACUL && iNum==0 && kID!="ocpause") //oracul power command
        {
                g_sOraculstring=llGetSubString(sMsg,1,-1); //store the config string for Oracul AO.
                g_iAOSwitch=(integer)llGetSubString(sMsg,0,1); //store the AO power state.
                if(!g_iAOSwitch && llGetPermissions()) llReleaseControls(); //stop checking controls if taken.    
        }

        else if(type==ZHAO) 
        {
            if (sMsg=="ZHAO_SITON") g_iSitOverride=TRUE;
            else if (sMsg=="ZHAO_SITOFF") g_iSitOverride=FALSE;
            else if(kID!="ocpause") //ignore pause commands sent by this script, we want to know what the "correct" state is.
            {
                if(sMsg=="ZHAO_AOON") g_iAOSwitch=TRUE;
                else if(sMsg=="ZHAO_AOOFF")
                {
                    g_iAOSwitch=FALSE;
                    if(llGetPermissions()) llReleaseControls(); //stop checking controls if taken.
                }
            }          
        }
    }
    
    run_time_permissions(integer perms)
    { 
        //we want to monitor for movement while the AO is temporarily off, so we can temporarily switch it back on again while a movement button is held.
        if(perms&PERMISSION_TAKE_CONTROLS) llTakeControls(CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT,TRUE,TRUE);
    }
    
    control(key id, integer level, integer edge)
    {
        if(!g_iAOSwitch||g_iOCSwitch) //if AO is turned off or OC hasn't requested a pause, we're not meant to be here.
        {
            llReleaseControls();
            return;
        }
        if(level&edge) //movement button pressed
        {
            
            if(type==ZHAO) llMessageLinked(LINK_THIS, 0, "ZHAO_AOON", "ocpause");
            else if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_THIS,0,"1"+g_sOraculstring,"ocpause");           
        }
        else if((!level)&edge) //movement button released
        {
            
            if(type==ZHAO) llMessageLinked(LINK_THIS, 0, "ZHAO_AOOFF", "ocpause");
            else if (type==ORACUL && g_sOraculstring!="") llMessageLinked(LINK_THIS,0,"0"+g_sOraculstring,"ocpause");
        }
    }
    
    timer()
    {
        llSetTimerEvent(0);
        llListenRemove(g_iMenuHandle);
        //inform current menu users of listener timeout.
        integer x=llGetListLength(g_lMenuUsers);
        while(x)
        {
            x--;
            key tKey=llList2Key(g_lMenuUsers,x);
            if(llGetAgentSize(tKey)) llRegionSayTo(tKey,0,"AO Menu timed out, try again."); //avoid IM spam by only notifying those in sim.
        }
        g_lMenuUsers=[]; //clear list
    }
    
    changed(integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
    }  
}
