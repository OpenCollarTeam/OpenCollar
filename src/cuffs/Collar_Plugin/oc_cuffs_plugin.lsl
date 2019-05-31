////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenNC - cuffs - 6.0.2b                             //
//                            version 6.0.2b                                      //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
//                   and other virtual metaverse environments.                    //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ©   2013 - 2016  OpenNC                                                        //
// ------------------------------------------------------------------------------ //
// Not now supported by OpenCollar at all                                         //
////////////////////////////////////////////////////////////////////////////////////

integer    g_nCmdHandle    = 0;            // command listen handler
integer g_nCmdChannelOffset = 0xCC0CC;       // offset to be used to make sure we do not interfere with other items using the same technique for
integer CUFF_CHANNEL; //custom channel to send to cuffs (our channel +1)

key kID;
string submenu = "Cuffs";
string parentmenu = "Apps";
key g_kDialogID;
list localbuttons = ["Cuff Menu", "ReSync"];

// chat command for opening the menu of the cuffs directly
key wearer;
string TURNON = "Sync  ON";
integer LINK_SAVE             = 5;
string TURNOFF = "Sync OFF";
integer LINK_UPDATE = -10;
string HIDEON = "Hide Cuffs";
string HIDEOFF = "Show Cuffs";
integer sync;
integer hide = FALSE;
integer wait = FALSE; //maybe not needed now but will leave in for this release
//MESSAGE MAP
integer COMMAND_OWNER = 500;
integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
string UPMENU = "BACK";

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_ALL_OTHERS, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page + "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}

DoMenu(key id) //build our menu here
{
    string prompt = "\n\nCollar to Cuff interface\n";
    list mybuttons = localbuttons;
    if (sync == TRUE)
    {
        mybuttons += TURNOFF;
        prompt += "The Collar will try and update the cuffs.\n";
    }
    else
    {
        mybuttons += TURNON;
        prompt += "The Collar will NOT update the cuffs.\n";
    }
    if (hide == FALSE)
    {
        mybuttons += HIDEON;
        prompt += "The Cuffs are not hidden from this menu.\n";
    }
    else
    {
        mybuttons += HIDEOFF;
        prompt += "The Cuffs ARE hidden from this menu.\n";
    }
    prompt += "Sync must be turned ON to ReSync.\n";
    prompt += "Pick an option.";
    g_kDialogID=Dialog(id, prompt, mybuttons, [UPMENU], 0);
}

integer nGetOwnerChannel(key wearer,integer nOffset)//This is the cuffs channel built from our UUID
{
    integer chan = (integer)("0x"+llGetSubString((string)wearer,2,7)) + nOffset;
    if (chan>0)
        chan=chan*(-1);
    if (chan > -10000)
        chan -= 30000;
    return chan;
}

default
{
    state_entry()
    {
        if (wearer != llGetOwner())
            sync = TRUE; //on new owener set sync to ON
        // wait for all script to be ready
        llSleep(0.6);
        wearer = llGetOwner();//who owns us
        llMessageLinked(LINK_SAVE, LM_SETTING_REQUEST, "C_Sync", wearer);
        CUFF_CHANNEL = nGetOwnerChannel(wearer,1110);//lets get our channel (same as collar +1)
        llMessageLinked(LINK_ALL_OTHERS, MENUNAME_REQUEST, submenu, NULL_KEY);
        llMessageLinked(LINK_ALL_OTHERS, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
    }

    on_rez(integer iParam)
    {
        if (wearer != llGetOwner())
            llResetScript();//on new owner reset script
    }
    link_message(integer iSender, integer iNum,string sMsg, key kID)
    {
        list lParams = llParseString2List(sMsg, ["|"], []);
        key user = llList2Key(lParams, 0);
        string sMsg1 = llList2String(lParams, 1);
        if (iNum == MENUNAME_REQUEST && sMsg == parentmenu)//adds us to the apps menu**
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu, NULL_KEY);
        if ((iNum == COMMAND_OWNER) && (sMsg == "runaway"))
            llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":runaway"); //ok full runaway seen!**
        else if (sMsg == "menu " + submenu)//lets give our menu**
            DoMenu(kID);
        else if ((sMsg1 =="LOCK") && (iNum == DIALOG_RESPONSE))//Lock our cuffs with the collar**
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "C_lock=1", NULL_KEY);
        else if ((sMsg1 =="UNLOCK") && (iNum == DIALOG_RESPONSE))//Unlock our cuffs with the collar**
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "C_lock=0", NULL_KEY);
        else if (sMsg == "C_Sync=0")//Sync off (our own syncing)**
            sync = FALSE;
        else if (sMsg == "C_Sync=1")//Sync on (our own syncing)**
            sync = TRUE;

        if (sync == TRUE)//only do this bit if sync is turned on
        {
            if (sMsg == "rlvsys_on=1" && iNum == LM_SETTING_SAVE)//RLV on
                llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":rlv on");  //Turn our cuffs RLV on**
            else if (sMsg == "rlvsys_on=0" && iNum == LM_SETTING_SAVE)//RLV off
                llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":rlv off"); //Turn our cuffs RLV off**
            else if ((sMsg == "C_lock=1") || (sMsg == "Global_locked=1"))//Lock on
                llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":lock"); //Lock our cuffs**
            else if ((sMsg == "C_lock=0") || (sMsg == "Global_locked"))//Lock off
                llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":unlock"); //Unlock oour cuffs**
            else
            {
                //Lets chop up at "=" to see if we want it
                list lParam = llParseString2List(sMsg, ["="], []);
                integer h = llGetListLength(lParam);
                string sMsg1a= llList2String(lParam, 0);
                if ( (sMsg1a == "auth_owner") || (sMsg1a == "auth_trust") || (sMsg1a == "auth_block") || (sMsg1a == "auth_group") || (sMsg1a == "auth_public"))
                    llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":" + sMsg);//Set access**
                else if (sMsg1a == "anim_currentpose")
                    llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":" + sMsg);//Send Animations**
                else
                {
                    list lParam1 = llParseString2List(sMsg1a, ["_"], []);
                    string sMsg1b= llList2String(lParam1, 0);
                    //Lets see if it's Themes info
                    if(sMsg1b == "color" || sMsg1b == "glow" || sMsg1b == "shiny" || sMsg1b == "texture")
                        llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":"+ sMsg);
                    else
                    {
                        list lParams = llParseString2List(sMsg, ["|"], []);
                        integer i = llGetListLength(lParams);
                        sMsg1= llList2String(lParams, 1);
//                        llOwnerSay(sMsg1);
                        if (sMsg1 =="☑ Stealth")
                        {
                            llRegionSayTo(wearer,CUFF_CHANNEL,(string)kID + ":show");//Show our cuffs **
                            hide = FALSE;
                        }
                        else if (sMsg1 =="☐ Stealth")
                        {
                            llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":hkIDe"); //hkIDe our cuffs **
                            hide = TRUE;
                        }
                    }
                }
            }
        }
        if ( iNum == DIALOG_RESPONSE)
        {
            if (kID==g_kDialogID)
            {
                list menuparams = llParseString2List(sMsg, ["|"], []);
                key AV = (key)llList2String(menuparams, 0);
                string message = llList2String(menuparams, 1);
                integer page = (integer)llList2String(menuparams, 2);
                if (message == UPMENU)
                    llMessageLinked(LINK_SET, 500, "menu "+ parentmenu, AV);//forcing to Auth level 500 to do a BACK
                else if (message == "Cuff Menu")//ask for the cuff menu
                    llRegionSayTo(wearer,CUFF_CHANNEL,(string)AV + ":menu|"+(string)AV);
                else if (message == TURNON)
                {
                    sync = TRUE;
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "C_Sync=1", NULL_KEY);
                    DoMenu(AV);
                }
                else if (message == TURNOFF)
                {
                    sync = FALSE;
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, "C_Sync=0", NULL_KEY);
                    DoMenu(AV);
                }
                else if (message == HIDEON)
                {
                    llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + "chkIDe");
                    hide = TRUE;
                    DoMenu(AV);
                }
                else if (message == HIDEOFF)
                {
                    llRegionSayTo(wearer,CUFF_CHANNEL,(string)wearer + ":show");
                    hide = FALSE;
                    DoMenu(AV);
                }
                else if (message == "ReSync")
                {//lets grab the saved settings so we can forward them on
                    llMessageLinked(LINK_SAVE, LM_SETTING_REQUEST,"ALL","");
                    DoMenu(AV);
                }
            }
        } else if(iNum == LINK_UPDATE){
            if(sMsg=="LINK_SAVE") LINK_SAVE=iSender;
        }
    }

}