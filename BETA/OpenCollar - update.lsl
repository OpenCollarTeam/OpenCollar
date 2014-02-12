////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - update                               //
//                                 version 3.952                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//3.935 Bugfix for sending collarversion to menu script, 1 and 0 instead of TRUE and FALSE;
//3.940 doesn't give regular updaters, informs user where to get an updater, and get updater button gives current updater

// This script does 4 things:
// 1 - On rez, check whether there's an update to the collar available.
// 2 - On command, ask appengine for an updater to be delivered.
// 3 - On command, do the handshaking necessary for updater object to install
// its shim script.
// 4 - On rez, check a file on Github for any important project news, and
// announce it to the wearer if it's new.  The timestamp of the last news
// report is remembered in the object desc.

// NOTE: As of version 3.706, the update script no longer uses object name or
// description to tell it the current collar version.  Instead, it looks in the
// "~version" notecard.  It compares the contents of that notecard with the
// text at https://raw.github.com/opencollar/OpenCollarUpdater/beta/LSL/~version.  If the
// version online is newer, then the wearer will be advised that an update is
// available.

// Update checking sequence:
// 1 - On rez, reset script.
// 2 - On start, read the version notecard.
// 3 - On getting version notecard contents, store in global var and request
// version from github.
// 4 - On getting version from github, compare to version from notecard.
// 5 - If github version is newer, then give option to have update delivered.
// 6 - On getting command to deliver updater, send http request to
// update.mycollar.org.

key wearer;

string g_sUpdaterName="OpenCollar Updater";
string g_sRelease_version;
string g_sHowToUpdate="Updaters are available at http://maps.secondlife.com/secondlife/Keraxic/51/192/1234 http://maps.secondlife.com/secondlife/Qandico/220/157/2600 https://www.primbay.com/product.php?id=1782591 https://marketplace.secondlife.com/p/OpenCollar-Updater/5493698 or any OpenCollar network vendor."; //put in appropriate message here.

integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_WEARER = 503;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer UPDATE = 10001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string PARENT_MENU = "Help/About";
string BTN_DO_UPDATE = "Update";
string BTN_GET_UPDATE = "Get Updater";
//string BTN_GET_VERSION = "Get Version";

key g_kMenuID;
string CTYPE = "collar";

integer g_iUpdateChan = -7483214;
integer g_iUpdateHandle;

key g_kConfirmUpdate;
key g_kUpdaterOrb;

// We check for the latest version number by looking at the "~version" notecard
// inside the 'release' branch of the collar's Github repo.
string version_check_url = "https://raw2.github.com/OpenCollar/OpenCollarUpdater/main/BETA/~version";
key github_version_request;

// A request to this URL will trigger delivery of an updater.  We omit the
// "version=blah" parameter because we don't want the server deciding whether
// we should get an updater or not.  We just want one.
//string delivery_url = "http://update.mycollar.org/updater/check?object=OpenCollarUpdater&update=yes";
//key appengine_delivery_request;

// The news system is back!  Only smarter this time.  News will be kept in a
// static file on Github to keep server load down.  This script will remember
// the date of the last time it reported news so it will only show things once.
// It will also not show things more than a week old.
string news_url = "https://raw2.github.com/OpenCollar/OpenCollarUpdater/main/BETA/news.md";
key news_request;

// store versions as strings and don't cast to float until the last minute.
// This ensures that we can display them in a nice way without a bunch of
// floating point garbage on the end.
string my_version = "0.0";
key my_version_request;

key g_kUpdater; // key of avi who asked for the update
integer g_iUpdatersNearBy = -1;
integer g_iWillingUpdaters = -1;

string last_news_time = "0";

Debug(string sMessage)
{
    //llOwnerSay(llGetScriptName() + ": " + sMessage);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == wearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

ConfirmUpdate(key kUpdater)
{
    //string sPrompt = "\n\nDo you want to update with " + llKey2Name(kUpdater) + " with object key:\n\n" + (string)kUpdater +"\n"
    string sPrompt = "\n3 Golden Rules for Updates:\n\n1.Create a Backup\n2.Rezzed is safer than Worn\n3.Low Lag regions make happy Updates\n\n(These rules apply to any kind of scripted item, not just collars or bondage and kink items!)\n\nATTENTION: Do not rez any other collars till the update has started.\n\nReady?";
    g_kConfirmUpdate = Dialog(wearer, sPrompt, ["Yes", "No"], [], 0, COMMAND_WEARER);
}

integer IsOpenCollarScript(string sName)
{
    if (llList2String(llParseString2List(sName, [" - "], []), 0) == "OpenCollar")
    {
        return TRUE;
    }
    return FALSE;
}

CheckForUpdate()
{
    Debug("checking for update");
    github_version_request = llHTTPRequest(version_check_url, [HTTP_METHOD, "GET"], "");
}

SayUpdatePin(key orb)
{
    integer pin = (integer)llFrand(99999998.0) + 1; //set a random pin
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(orb, g_iUpdateChan, "ready|" + (string)pin ); //give the ok to send update sripts etc...
}

string LeftOfDecimal(string str)
{
    integer idx = llSubStringIndex(str, ".");
    if (idx == -1)
    {
        return str;
    }
    return llGetSubString(str, 0, idx - 1);
}

string RightOfDecimal(string str)
{
    integer idx = llSubStringIndex(str, ".");
    if (idx == -1)
    {
        return "0";
    }
    return llGetSubString(str, idx + 1, -1);
}

integer SecondStringBigger(string s1, string s2)
{
    // first compare the pre-decimal parts.
    integer i1 = (integer)LeftOfDecimal(s1);
    integer i2 = (integer)LeftOfDecimal(s2);

    if (i2 == i1)
    {
        // pre-decimal parts are the same.  Need to compare the bits after.
        integer j1 = (integer)RightOfDecimal(s1);
        integer j2 = (integer)RightOfDecimal(s2);
        return j2 > j1;
    }
    else return i2 > i1;
}

// used in the 'objectversion' command.
integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan>0)
    {
        iChan=iChan*(-1);
    }
    if (iChan > -10000)
    {
        iChan -= 30000;
    }
    return iChan;
}

Init()
{
    // check if we're current version or not by reading notecard.
    my_version_request = llGetNotecardLine("~version", 0); 
    
    // check for news
    news_request = llHTTPRequest(news_url, [HTTP_METHOD, "GET"], "");

    // register menu buttons
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + BTN_DO_UPDATE, NULL_KEY);
    llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + BTN_GET_UPDATE, NULL_KEY);
    //llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + BTN_GET_VERSION, NULL_KEY);    
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string str, key id) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum > COMMAND_WEARER || iNum < COMMAND_OWNER) return FALSE; // sanity check
    list cmd_parts = llParseString2List(str, [" "], []);
    // handle menu clicks
    if (llList2String(cmd_parts, 0) == "menu")
    {
        string submenu = llGetSubString(str, 5, -1);
        if (submenu == BTN_DO_UPDATE) 
        {
            return UserCommand(iNum, "update", id);
        }
        else if (submenu == BTN_GET_UPDATE)
        {
            if (id == wearer)
            {
                 if(llGetInventoryType(g_sUpdaterName)==INVENTORY_OBJECT)
                    {
                        llGiveInventory(id,g_sUpdaterName);
                        if ((float)g_sRelease_version > (float)my_version)
                        {
                            Notify(id,"Look in your objects folder for your updater. Use this to change the packages in your collar, but please note that there is a newer updater than this one available.\n"+g_sHowToUpdate,FALSE);
                        }
                        else Notify(id,"Look in your objects folder for your updater. Use this to change the packages in your collar.",FALSE);
                    }
                    else Notify(id,"Sorry, the updater appears to be missing from your collar! \n"+g_sHowToUpdate,FALSE); 
            }
            else
            {
                Notify(id,"Only the wearer can request updates for the " + CTYPE + ".",FALSE);
            }
        }
       // else if (submenu == BTN_GET_VERSION)
       // {
       //    UserCommand(iNum, "version", id);
       // }
        else
        {
            return TRUE; // drop the command if it is not a menu handled here
        }
        llMessageLinked(LINK_ROOT, iNum, "menu "+PARENT_MENU, id);
    }
    else if (str == "update")
    {
        if (id == wearer)
        {
            string sVersion = llList2String(llParseString2List(llGetObjectDesc(), ["~"], []), 1);
            g_iUpdatersNearBy = 0;
            g_iWillingUpdaters = 0;
            g_kUpdater = id;
            Notify(id,"Searching for nearby updater",FALSE);
            g_iUpdateHandle = llListen(g_iUpdateChan, "", "", "");
            llWhisper(g_iUpdateChan, "UPDATE|" + sVersion);
            llSetTimerEvent(10.0); //set a timer to close the g_iListener if no response
        }
        else
        {
            Notify(id,"Only the wearer can update the " + CTYPE + ".",FALSE);
        }
    }
    else if (llList2String(cmd_parts, 0) == "version")
    {
        Notify(id, "I am running OpenCollar version " + my_version, FALSE);
    }
    else if (str == "objectversion")
    {
        // ping from an object, we answer to it on the object channel
        llSay(GetOwnerChannel(id,1111),(string)wearer+"\\version="+my_version);
    }
    return TRUE;
}

default
{
    state_entry()
    {
        Debug("state default");

        //check if we're in an updater.  if so, then just shut self down and
        //don't do regular startup routine.
        if (llSubStringIndex(llGetObjectName(), "Updater") != -1)
        {
            llSetScriptState(llGetScriptName(), FALSE);
        }
        // we just started up.  Remember owner.
        wearer = llGetOwner();
        Init();
    }

    dataserver(key id, string data)
    {
        if (id == my_version_request)
        {
            // we only ever read one notecard ("~version"), and it only ever has
            // one line.  So whatever we got back, that's our version.
            my_version = data;        
            //Debug("version:"+my_version);
            // now request the version from github.
            CheckForUpdate();            
        }
    }

    http_response(key id, integer status, list meta, string body)
    {
        // if we just got version information from github, then compare to what
        // we have in notecard.
        if (status == 200)
        { // be silent on failures.
            if (id == github_version_request)
            {
                // strip the newline off the end of the text
                g_sRelease_version = llGetSubString(body, 0, -2);
                //Deg_sRelease_versionbug("release:"+release_version);
                if ((float)g_sRelease_version > (float)my_version)
                {
                    string prompt = "\n\nYou are running OpenCollar version " +
                    my_version + ".  There is an update available.\n"+g_sHowToUpdate;
                    llDialog(llGetOwner(),prompt,["Ok!"],-23426245);
                    
                   // g_kMenuID = Dialog(wearer, prompt, [BTN_GET_UPDATE], ["Cancel"], 0, COMMAND_WEARER);
                   llMessageLinked(LINK_THIS,LM_SETTING_RESPONSE,"collarversion="+(string)my_version+"=0","");
                }
                else llMessageLinked(LINK_THIS,LM_SETTING_RESPONSE,"collarversion="+(string)my_version+"=1","");
            }
           // else if (id == appengine_delivery_request)
          //  {
           //     llOwnerSay("An updater will be delivered to you shortly.");
          //  }
            else if (id == news_request)
            {
                // We got a response back from the news page on Github.  See if
                // it's new enough to report to the user.
                string firstline = llList2String(llParseString2List(body, ["\n"], []), 0);
                list firstline_parts = llParseString2List(firstline, [" "], []);
                
                // The first line of a news item should always look like this:
                // # First News - 20111012
                // or optionally with a decimal like this:
                // # Second News of the Day - 20111012.2
                // So we can compare timestamps that way.  
                string this_news_time = llList2String(firstline_parts, -1);

                if (SecondStringBigger(last_news_time, this_news_time))
                {
                    string news = "Newsflash " + body;
                    Notify(llGetOwner(), news, FALSE);
                    // last news time is remembered in memory.  We used to
                    // store it in the desc but you can't write to that while
                    // worn.
                    last_news_time = this_news_time;
                } 
            }
        }
    }

    on_rez(integer param)
    {
        // only reset if owner has changed
        if (wearer != llGetOwner())
        {
            llResetScript();
        }
        
        // otherwise do the usual news, version, and menu stuff
        Init();
    }

    link_message(integer sender, integer num, string str, key id )
    {
        //the command was given by either owner, secowner, group member, or wearer
        if (UserCommand(num, str, id)) return;
        else if (num == MENUNAME_REQUEST)
        {
            if (str == PARENT_MENU)
            {
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + BTN_DO_UPDATE, NULL_KEY);
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + BTN_GET_UPDATE, NULL_KEY);
               // llMessageLinked(LINK_SET, MENUNAME_RESPONSE, PARENT_MENU + "|" + BTN_GET_VERSION, NULL_KEY);
            }
        }
        else if (num == DIALOG_RESPONSE)
        {
            if (id == g_kMenuID)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(str, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);

                if (sMessage == BTN_GET_UPDATE)
                {
                    if(llGetInventoryType(g_sUpdaterName)==INVENTORY_OBJECT)
                    {
                        llGiveInventory(kAv,g_sUpdaterName);
                        if ((float)g_sRelease_version > (float)my_version)
                        {
                            Notify(kAv,"Look in your objects folder for your updater. Use this to change the packages in your collar, but please note that there is a newer updater than this one available.\n"+g_sHowToUpdate,FALSE);
                        }
                        else Notify(kAv,"Look in your objects folder for your updater. Use this to change the packages in your collar.",FALSE);
                    }
                    else Notify(kAv,"Sorry, the updater appears to be missing from your collar! \n"+g_sHowToUpdate,FALSE);                              
                }
            }
            else if (id == g_kConfirmUpdate)
            {
                // User clicked the Yes I Want To Update button
                list lMenuParams = llParseString2List(str, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                if (sMessage == "Yes")
                {
                    SayUpdatePin(g_kUpdaterOrb);
                }
            }
        }
        else if (num == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(str, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "Global_CType") CTYPE = sValue;
        }
    }

    listen(integer channel, string name, key id, string message)
    {   //collar and updater have to have the same Owner else do nothing!
        Debug(message);
        if (llGetOwnerKey(id) == wearer)
        {
            list lTemp = llParseString2List(message, [","],[]);
            string sCommand = llList2String(lTemp, 0);
            if(message == "nothing to update")
            {
                g_iUpdatersNearBy++;
            }
            else if( message == "get ready")
            {
                g_iUpdatersNearBy++;
                g_iWillingUpdaters++;
                g_kUpdaterOrb = id;
                ConfirmUpdate(g_kUpdaterOrb); 
                g_iUpdatersNearBy = -1;
                g_iWillingUpdaters = -1;
                llSetTimerEvent(0);
            }
        }
    }

    timer()
    {
        Debug("timer");
        llSetTimerEvent(0.0);
        llListenRemove(g_iUpdateHandle);
        if (g_iUpdatersNearBy > -1)
        {
            if (!g_iUpdatersNearBy)
            {
                Notify(g_kUpdater,"No updaters found.  Please rez an updater within 10m and try again",FALSE);
            }
            else if (g_iWillingUpdaters > 1)
            {
                    Notify(g_kUpdater,"Multiple updaters were found within 10m.  Please remove all but one and try again",FALSE);
            }
            g_iUpdatersNearBy = -1;
            g_iWillingUpdaters = -1;
        }
    }
}
