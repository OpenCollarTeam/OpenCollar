////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - bell                                //
//                                 version 3.989                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//scans for sounds starting with: bell_
//show/hide for elements named: Bell
//2009-01-30 Cleo Collins - 1. draft

string g_sSubMenu = "Bell";
string g_sParentMenu = "Apps";
key g_kDialogID;

list g_lLocalButtons = ["Next Sound","Vol +","Delay +","Ring it!","Vol -","Delay -"];
float g_fVolume=0.5; // volume of the bell
float g_fVolumeStep=0.1; // stepping for volume

float g_fSpeed=1.0; // Speed of the bell
float g_fSpeedStep=0.5; // stepping for Speed adjusting
float g_fSpeedMin=0.5; // stepping for Speed adjusting
float g_fSpeedMax=5.0; // stepping for Speed adjusting

integer g_iBellOn=0; // are we ringing. Off is 0, On = Auth of person which enabled
string g_sBellOn="ON"; // menu text of bell on
string g_sBellOff="OFF"; // menu text of bell off

integer g_iBellShow=FALSE; // is the bell visible
string g_sBellShow="SHOW"; //menu text of bell visible
string g_sBellHide="HIDE"; //menu text of bell hidden

list g_listBellSounds=["7b04c2ee-90d9-99b8-fd70-8e212a72f90d","b442e334-cb8a-c30e-bcd0-5923f2cb175a","1acaf624-1d91-a5d5-5eca-17a44945f8b0","5ef4a0e7-345f-d9d1-ae7f-70b316e73742","da186b64-db0a-bba6-8852-75805cb10008","d4110266-f923-596f-5885-aaf4d73ec8c0","5c6dd6bc-1675-c57e-0847-5144e5611ef9","1dc1e689-3fd8-13c5-b57f-3fedd06b827a"]; // list with bell sounds
key g_kCurrentBellSound ; // curent bell sound key
integer g_iCurrentBellSound; // curent bell sound sumber
integer g_iBellSoundCount; // number of avail bell sounds

key g_kLastToucher ; // store tocher key 
float g_fNextTouch ;  // store time for the next touch
float g_fTouch = 10.0 ; // timeout for touch chat notify

list g_lBellElements; // list with number of prims related to the bell

float g_fNextRing; // store time for the next ringing here;

key g_kWearer; // key of the current wearer to reset only on owner changes

integer g_iHasControl=FALSE; // dow we have control over the keyboard?

list g_lButtons;
integer g_iHide ; // global hide

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
//integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
//integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

//integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
//integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
//integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
//integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
//integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
//integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";//when your menu hears this, give the parent menu
string g_sScript;

string WEARERNAME;

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}


/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "("+(string)llGetSPMaxMemory()+") : " + sStr);
}
*/

DoMenu(key kID, integer iAuth)
{
    string sPrompt = "\n";
    // sPrompt += "(Menu will time out in " + (string)g_iTimeOut + " seconds.)\n";
    list lMyButtons;
    
    //fill in your button list here

    // Show buton for ringing the bell and add a text for it
    if (g_iBellOn>0) // the bell rings currently
    {
        lMyButtons+= g_sBellOff;
        sPrompt += "Bell is ringing";
    }
    else
    {
        lMyButtons+= g_sBellOn;
        sPrompt += "Bell is NOT ringing";
    }

    // Show button for showing/hidding the bell and add a text for it, if there is a bell
    if (g_iBellShow) // the bell is hidden
    {
        lMyButtons+= g_sBellHide;
        sPrompt += " and shown.\n\n";
    }
    else
    {
        lMyButtons+= g_sBellShow;
        sPrompt += " and NOT shown.\n\n";
    }

    // and show the volume and timing of the bell sound
    sPrompt += "The volume of the bell is now: "+(string)((integer)(g_fVolume*10))+"/10.\n";
    sPrompt += "The bell rings every "+llGetSubString((string)g_fSpeed,0,2)+" seconds when moving.\n";
    sPrompt += "Currently used sound: "+(string)(g_iCurrentBellSound+1)+"/"+(string)g_iBellSoundCount+"\n";
    sPrompt +="\nwww.opencollar.at/bell";

    lMyButtons += g_lLocalButtons + g_lButtons;

    g_kDialogID=Dialog(kID, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
}

SetBellElementAlpha()
{
    if (g_iHide) return ; // ***** if collar is hide, don't do anything 
    //loop through stored links, setting color if element type is bell
    
    integer n;
    integer iLinkElements = llGetListLength(g_lBellElements);
    for (n = 0; n < iLinkElements; n++)
    {
        llSetLinkAlpha(llList2Integer(g_lBellElements,n), (float)g_iBellShow, ALL_SIDES);
    }
}

BuildBellElementList()
{
    integer n;
    integer iLinkCount = llGetNumberOfPrims();
    list lParams;

    // clear list just in case
    g_lBellElements = [];

    //root prim is 1, so start at 2
    for (n = 2; n <= iLinkCount; n++)
    {
        // read description
        lParams=llParseString2List((string)llGetObjectDetails(llGetLinkKey(n), [OBJECT_DESC]), ["~"], []);
        // check inf name is baell name
        if (llList2String(lParams, 0)=="Bell")
        {
            // if so store the number of the prim
            g_lBellElements += [n];
            // Debug("added " + (string)n + " to elements");
        }
    }
    if (llGetListLength(g_lBellElements)==0){
        llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
        llRemoveInventory(llGetScriptName());
    }

}

PrepareSounds()
{
    // parse names of sounds in inventiory if those are for the bell
    integer i;
    integer m=llGetInventoryNumber(INVENTORY_SOUND);
    string s;
    for (i=0;i<m;i++)
    {
        s=llGetInventoryName(INVENTORY_SOUND,i);
        if (llSubStringIndex(s,"bell_")==0)
        {
            // sound found, add key to list
            g_listBellSounds+=llGetInventoryKey(s);
        }
    }
    // and set the current sound
    g_iBellSoundCount=llGetListLength(g_listBellSounds);
    g_iCurrentBellSound=0;
    g_kCurrentBellSound=llList2Key(g_listBellSounds,g_iCurrentBellSound);
}

SaveBellSettings()
{
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "on=" + (string)g_iBellOn, "");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "show=" + (string)g_iBellShow, "");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "sound=" + (string)g_iCurrentBellSound, "");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "vol=" + (string)llFloor(g_fVolume*10), "");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "speed=" + (string)llFloor(g_fSpeed*10), "");
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum > COMMAND_WEARER || iNum < COMMAND_OWNER) return FALSE; // sanity check
    string test=llToLower(sStr);
    if (sStr == "menu " + g_sSubMenu || sStr == "bell")
    {// the command prefix + bell without any extentsion is used in chat
        //give this plugin's menu to kID
        DoMenu(kID, iNum);
    }
    // we now chekc for chat commands
    else if (llSubStringIndex(test,"bell")==0)
    {
        // it is a chat commad for the bell so process it
        list lParams = llParseString2List(test, [" "], []);
        string sToken = llList2String(lParams, 1);
        string sValue = llList2String(lParams, 2);

        if (sToken=="volume")
        {
            integer n=(integer)sValue;
            if (n<1) n=1;
            if (n>10) n=10;
            g_fVolume=(float)n/10;
            SaveBellSettings();
            Notify(kID,"Bell volume set to "+(string)n, TRUE);
        }
        else if (sToken=="delay")
        {
            g_fSpeed=(float)sValue;
            if (g_fSpeed<g_fSpeedMin) g_fSpeed=g_fSpeedMin;
            if (g_fSpeed>g_fSpeedMax) g_fSpeed=g_fSpeedMax;
            SaveBellSettings();
            Notify(kID,"Bell delay set to "+llGetSubString((string)g_fSpeed,0,2)+" seconds.", TRUE);
        }
        else if (sToken=="show" || sToken=="hide")
        {
            if (sToken=="show")
            {
                g_iBellShow=TRUE;
                Notify(kID,"The bell is now visible.",TRUE);
            }
            else
            {
                g_iBellShow=FALSE;
                Notify(kID,"The bell is now invisible.",TRUE);
            }
            SetBellElementAlpha();
            SaveBellSettings();
        }
        else if (sToken=="on")
        {
            if (iNum!=COMMAND_GROUP)
            {
                if (g_iBellOn==0)
                {
                    g_iBellOn=iNum;
                    if (!g_iHasControl) llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
                    SaveBellSettings();
                    Notify(kID,"The bell rings now.",TRUE);
                }
            }
            else
            {
                Notify(kID,"Group users or Open Acces users cannot change the ring status of the bell.",TRUE);
            }
        }
        else if (sToken=="off")
        {
            if ((g_iBellOn>0)&&(iNum!=COMMAND_GROUP))
            {
                g_iBellOn=0;

                if (g_iHasControl)
                {
                    llReleaseControls();
                    g_iHasControl=FALSE;
                }

                SaveBellSettings();
                Notify(kID,"The bell is now quiet.",TRUE);
            }
            else
            {
                Notify(kID,"Group users or Open Access users cannot change the ring status of the bell.",TRUE);
            }
        }
        else if (sToken=="nextsound")
        {
            g_iCurrentBellSound++;
            if (g_iCurrentBellSound>=g_iBellSoundCount)
            {
                g_iCurrentBellSound=0;
            }
            g_kCurrentBellSound=llList2Key(g_listBellSounds,g_iCurrentBellSound);
            Notify(kID,"Bell sound changed, now using "+(string)(g_iCurrentBellSound+1)+" of "+(string)g_iBellSoundCount+".",TRUE);
        }
        // let the bell ring one time
        else if (sToken=="ring")
        {
            // update variable for time check
            g_fNextRing=llGetTime()+g_fSpeed;
            // and play the sound
            llPlaySound(g_kCurrentBellSound,g_fVolume);
        }

    }
    return TRUE;
}

string GetName(key uuid)
{
    string name = llGetDisplayName(uuid);
    if (name == "???" || name == "") name = llKey2Name(uuid);
    return name;
}
    
default
{
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        // key of the owner
        g_kWearer=llGetOwner();
        WEARERNAME = GetName(g_kWearer);

        // reset script time used for ringing the bell in intervalls
        llResetTime();

        // bild up list of prims with bell elements
        BuildBellElementList();

        PrepareSounds();
        SetBellElementAlpha();
        //llSetMemoryLimit(32768); //The risk is limited memory scenario when there is a local menu
    }
    
    on_rez(integer param)
    {
        g_kWearer=llGetOwner();
        if (g_iBellOn) llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            // the menu structure is to be build again, so make sure we get recognized
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
            g_lButtons = [] ; // flush submenu buttons
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
        }
        else if (iNum == MENUNAME_RESPONSE)
        {
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu)
            {//someone wants to stick something in our menu
                string button = llList2String(lParts, 1);
                if (llListFindList(g_lButtons, [button]) == -1)
                {
                    g_lButtons = llListSort(g_lButtons + [button], 1, TRUE);
                }
            }
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            list lParts = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParts, 0) == g_sSubMenu)
            {
            string button = llList2String(lParts, 1);
                integer iIndex = llListFindList(g_lButtons , [button]);
                if (iIndex != -1)
                {
                    g_lButtons = llDeleteSubList(g_lButtons , iIndex, iIndex);
                }
            }
        }
        else if ((iNum == LM_SETTING_RESPONSE || iNum == LM_SETTING_DELETE)
            && llSubStringIndex(sStr, "Global_WearerName") == 0 ) {
        integer iInd = llSubStringIndex(sStr, "=");
        string sValue = llGetSubString(sStr, iInd + 1, -1);
        //We have a broadcasted change to WEARERNAME to work with
        if (iNum == LM_SETTING_RESPONSE) WEARERNAME = sValue;
        else {
            g_kWearer = llGetOwner();
            WEARERNAME = GetName(g_kWearer);
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            // some responses from the DB are coming in, check if it is about bell values
            integer i = llSubStringIndex(sStr, "=");
            string sToken = llGetSubString(sStr, 0, i - 1);
            string sValue = llGetSubString(sStr, i + 1, -1);
            i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "on")
                {
                    g_iBellOn=(integer)sValue;
                    if (g_iBellOn && !g_iHasControl)
                    {
                        llRequestPermissions(g_kWearer,PERMISSION_TAKE_CONTROLS);
                    }
                    else if (!g_iBellOn && g_iHasControl)
                    {
                        llReleaseControls();
                        g_iHasControl=FALSE;
                    }
                }
                else if (sToken == "show")
                {
                    g_iBellShow=(integer)sValue;
                    SetBellElementAlpha();
                }
                else if (sToken == "sound")
                {
                    g_iCurrentBellSound=(integer)sValue;
                    g_kCurrentBellSound=llList2Key(g_listBellSounds,g_iCurrentBellSound);
                }
                else if (sToken == "vol") g_fVolume=(float)sValue/10;
                else if (sToken == "speed") g_fSpeed=(float)sValue/10;
            }
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum==DIALOG_RESPONSE)
        {
            //str will be a 2-element, pipe-delimited list in form pagenum|response
    
            if (kID == g_kDialogID)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAV = llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU)
                {
                    //give id the parent menu
                    llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAV);
                    return; // no "remenu"
                }
                else if (~llListFindList(g_lLocalButtons, [sMessage]))
                {
                    //we got a response for something we handle locally
                    if (sMessage == "Vol +") // pump up the volume and store the value
                    {
                        g_fVolume+=g_fVolumeStep;
                        if (g_fVolume>1.0) g_fVolume=1.0;                        
                        SaveBellSettings();
                    }
                    else if (sMessage == "Vol -") // be more quiet, and store the value
                    {
                        g_fVolume-=g_fVolumeStep;
                        if (g_fVolume<0.1) g_fVolume=0.1;                        
                        SaveBellSettings();
                    }
                    else if (sMessage == "Delay +") // dont annoy people and ring slower
                    {
                        g_fSpeed+=g_fSpeedStep;
                        if (g_fSpeed>g_fSpeedMax) g_fSpeed=g_fSpeedMax;
                        SaveBellSettings();
                    }
                    else if (sMessage == "Delay -") // annoy the hell out of the, ring plenty, ring often
                    {
                        g_fSpeed-=g_fSpeedStep;
                        if (g_fSpeed<g_fSpeedMin) g_fSpeed=g_fSpeedMin;
                        SaveBellSettings();
                    }
                    else if (sMessage == "Next Sound") // choose another sound for the bell
                    {
                        g_iCurrentBellSound++;
                        if (g_iCurrentBellSound>=g_iBellSoundCount) g_iCurrentBellSound=0;                        
                        g_kCurrentBellSound=llList2Key(g_listBellSounds,g_iCurrentBellSound);
                        SaveBellSettings();
                    }
                    //added a button to ring the bell. same call as when walking.
                    else if (sMessage == "Ring it!")
                    {
                        // update variable for time check
                        g_fNextRing=llGetTime()+g_fSpeed;
                        // and play the sound
                        llPlaySound(g_kCurrentBellSound,g_fVolume);
                        //Debug("Bing");
                    }
                }
                else if (sMessage == g_sBellOff || sMessage == g_sBellOn)
                    // someone wants to change if the bell rings or not
                {
                    string s;
                    if (g_iBellOn>0) s="bell off";
                    else s="bell on";                    
                    UserCommand(iAuth,s,kAV);
                }
                else if (sMessage == g_sBellShow || sMessage == g_sBellHide)
                    // someone wants to hide or show the bell
                {
                    g_iBellShow=!g_iBellShow;
                    SetBellElementAlpha();
                    SaveBellSettings();
                }
                else if (~llListFindList(g_lButtons, [sMessage]))
                {
                    //we got a submenu selection
                    //UserCommand(iAuth, "menu "+sMessage, kAV);
                    llMessageLinked(LINK_SET, iAuth, "menu " + sMessage, kAV);
                    return; // no main menu
                }
                // do we want to see the menu again?
                DoMenu(kAV, iAuth);
            }
        }
        else if(iNum=COMMAND_OWNER && sStr=="runaway")
        {
            llSleep(4);
            SetBellElementAlpha();
        }
    }

    control( key kID, integer nHeld, integer nChange )
        // we watch for movement from
    {
        // we dont want the bell to ring, so just exit
        if (!g_iBellOn) return;
        // Is the user holding down a movement key
        if ( nHeld & (CONTROL_LEFT|CONTROL_RIGHT|CONTROL_DOWN|CONTROL_UP|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT|CONTROL_FWD|CONTROL_BACK) )
        {
            // check if the time is ready for the next ring
            if (llGetTime()>g_fNextRing)
            {
                // update variable for time check
                g_fNextRing=llGetTime()+g_fSpeed;
                // and play the sound
                llPlaySound(g_kCurrentBellSound,g_fVolume);
                //Debug("Bing");
            }
        }
    }

    run_time_permissions(integer nParam)
        // we requested permissions, now we take control
    {
        if( nParam & PERMISSION_TAKE_CONTROLS)
        {
            //Debug("Bing");
            llTakeControls( CONTROL_DOWN|CONTROL_UP|CONTROL_FWD|CONTROL_BACK|CONTROL_LEFT|CONTROL_RIGHT|CONTROL_ROT_LEFT|CONTROL_ROT_RIGHT, TRUE, TRUE);
            g_iHasControl=TRUE;

        }
    }
    changed(integer change)
    {
        if(change & CHANGED_LINK) BuildBellElementList();
        else if (change & CHANGED_INVENTORY) PrepareSounds();
        if (change & CHANGED_COLOR) // ********************* 
        {
            integer iNewHide=!(integer)llGetAlpha(ALL_SIDES) ; //check alpha
            if (g_iHide != iNewHide){   //check there's a difference to avoid infinite loop
                g_iHide = iNewHide;
                SetBellElementAlpha(); // update hide elements 
            }
        }
/*        
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/        
    }
    

    touch_start(integer n)
    {
        if (g_iBellShow && !g_iHide && llListFindList(g_lBellElements,[llDetectedLinkNumber(0)]) != -1)
        {
            key toucher = llDetectedKey(0);
            g_fNextRing=llGetTime()+g_fSpeed;
            llPlaySound(g_kCurrentBellSound,g_fVolume);
            if (toucher != g_kLastToucher || llGetTime() > g_fNextTouch)
            {
                g_fNextTouch=llGetTime()+g_fTouch;
                g_kLastToucher = toucher;
                llSay(0, GetName(toucher) + " plays with the trinket on " + WEARERNAME + "'s collar." );
            }
        }
    }
}
