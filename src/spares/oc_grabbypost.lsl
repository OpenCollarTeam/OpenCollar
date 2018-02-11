// This file is part of OpenCollar.
// Copyright (c) 2013 - 2015 Toy Wylie et. al               
// Licensed under the GPLv2.  See LICENSE for full details. 


// Needs OpenCollar 6.x or higher to work

// Sends a "<wearer_uuid>:ping" message on the collar command channel:
// Collar answers with "<wearer_uuid>:pong"
// Sends a anchor command on the collar command channel to grab them

// constants
float RANGE=20.0;       // scanning range
float TIMEOUT=30.0;     // menu timeout
float WAIT_TIME=2.0;    // waiting time after the last confirmed collar
float LEASH_LENGTH=2.5; // leash length when grabbing

// menu system
integer menuListener=0;
integer menuChannel=0;
key menuUser=NULL_KEY;
integer scanning=FALSE;

list victimNames=[];    // list of victim names
list victimKeys=[];     // corresponding list of keys
list listeners=[];      // collar pong listeners per victim

//===============================================================================
//= parameters   :    key owner            key of the person to send the sMessage to
//=                    integer nOffset        Offset to make sure we use really a unique channel
//=
//= description  : Function which calculates a unique channel iNumber based on the owner key, to reduce lag
//=
//= returns      : Channel iNumber to be used
//===============================================================================
integer PersonalChannel(string sID, integer iOffset) {
    return -llAbs((integer)("0x"+llGetSubString(sID,-7,-1)) + iOffset);
}

// resets the menu dialog
resetDialog()
{
    // clear out any remaining collar listeners
    integer num=llGetListLength(listeners);
    integer index;
    for(index=0;index<num;index++)
    {
        llListenRemove(llList2Integer(listeners,index));
    }
    listeners=[];

    // clear out menu system data if needed
    if(menuListener)
    {
        llListenRemove(menuListener);
        menuListener=0;
        menuUser=NULL_KEY;

        llSetTimerEvent(0.0);
        victimNames=[];
        victimKeys=[];
    }
}

// send "No victims found" message to a person
notFound(key k)
{
    llRegionSayTo(k,0,"No victims were found within "+(string) ((integer) RANGE)+" m.");
}

// leash a victim
leash(key k)
{
    integer channel=PersonalChannel((string)k,0);
    llRegionSayTo(k,channel,"length "+(string) LEASH_LENGTH);
    llRegionSayTo(k,channel,"anchor "+(string) llGetKey());
}

default
{
    state_entry()
    {
    }

    touch_start(integer num)
    {
        key toucher=llDetectedKey(0);

        // lock the menu to the current menu user
        if(menuListener!=0 && menuUser!=toucher)
        {
            llRegionSayTo(toucher,0,"This menu is currently in use. Plesase wait a moment before trying again.");
            return;
        }

        // don't allow menu usage while scanning for collars
        if(scanning)
        {
            llRegionSayTo(toucher,0,"There is already a scan in progress, please wait for it to finish.");
            return;
        }

        // start with a fresh menu
        resetDialog();

        // remember menu user, get a new channel and set up listener
        menuUser=toucher;
        menuChannel=- ((integer) llFrand(1000000.0)+100000);
        menuListener=llListen(menuChannel,"",menuUser,"");

        // display the menu
        llDialog(menuUser,"Do you want to scan for nearby victims?\n\nScan radius is "+(string) ((integer) RANGE)+" m",["Scan"," ","Cancel"],menuChannel);

        // menu timeout
        llSetTimerEvent(TIMEOUT);
    }

    timer()
    {
        // if not scanning this was a menu timeout
        if(!scanning)
        {
            resetDialog();
            return;
        }

        // reset scanning mode
        llSetTimerEvent(0.0);
        scanning=FALSE;

        // check if anyone was picked up at all
        if(victimNames==[])
        {
            notFound(menuUser);
            resetDialog();
            return;
        }

        // cut button list so llDialog doesn't fail
        victimNames=llList2List(victimNames,0,9);
        victimKeys=llList2List(victimKeys,0,9);

        // list potential victims, watch 500 character limit on llDialog
        string body=llGetSubString("Select a target, or \"All\" to grab all those listed:\n\n"+llDumpList2String(victimNames,"\n"),0,500);

        // show list of potential victims
        llDialog(menuUser,body,["All", "Cancel"]+victimNames,menuChannel);

        // menu timeout
        llSetTimerEvent(TIMEOUT);
    }

    listen(integer c,string name,key k,string message)
    {
        // process menu button replies
        if(c==menuChannel)
        {
            // scan for victims
            if(message=="Scan")
            {
                llRegionSayTo(menuUser,0,"Scanning for OpenCollar compatible victims, please wait ...");
                llSensor("",NULL_KEY,AGENT,RANGE,PI);

                // set up scanning mode
                scanning=TRUE;
                return;
            }
            // grab all victims
            else if(message=="All")
            {
                integer num=llGetListLength(victimKeys);
                integer index;
                for(index=0;index<num;index++)
                {
                    leash(llList2Key(victimKeys,index));
                }
            }
            // clicked on a name or empty button
            else if(message!="Cancel")
            {
                // grab selected victim, if available in the list
                integer pos=llListFindList(victimNames,[message]);
                if(pos!=-1)
                {
                    leash(llList2Key(victimKeys,pos));
                }
            }

            // reset menu
            resetDialog();
            return;
        }

        // not a menu listener event, so this is a collar pong
        key wearer=llGetOwnerKey(k);

        // check for proper "<key>:pong" message
        if(message==((string) wearer+":pong"))
        {
            // get the collar wearer's name
            string wearerName=llKey2Name(wearer);

            // cut to max. 24 characters and add to the list of names
            victimNames+=[llGetSubString(wearerName,0,23)];
            // add to the list of keys
            victimKeys+=[wearer];

            // reset waiting time
            llSetTimerEvent(WAIT_TIME);
        }
    }

    no_sensor()
    {
        // nobody in scanning range
        notFound(menuUser);
        resetDialog();
    }

    sensor(integer num)
    {
        key k;
        integer channel;
        integer index;

        // go through the list of scanned avatars
        for(index=0;index<num;index++)
        {
            k=llDetectedKey(index);

            // do not include scanning user in the list
            if(k!=menuUser)
            {
                // calculate collar channel per victim and add a listener
                channel=PersonalChannel((string)k,0);
                listeners+=
                [
                    llListen(channel,"",NULL_KEY,"")
                ];

                // ping victim's collar
                llRegionSayTo(k,channel,(string)k+":ping");
            }
        }

        // initial waiting time after sending collar pings
        llSetTimerEvent(WAIT_TIME);
    }

    collision_start(integer num)
    {
        // grab bumping avatar
        leash(llDetectedKey(0));
    }
}
