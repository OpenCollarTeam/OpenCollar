////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                               OpenCollar - menu                                //
//                                 version 3.951                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//3.934d fix for kID instead of kAv for inventory giving. Duh.


// 3.934 reimplemented Menuto function for hud channel. This seems to have been lost by the wayside in the interface channel mods. I've added a check to see if the object owner is the same as the menuto target key, as this will mean a new auth is not required and saves double authing in that situation (probably the most common). -MD
// 3.934 Menu changes. help/debug is now replaced with Options menu, operated from the settings script. Refresh menus is now done from the Options menu in settings, using llResetOtherScript instead of from here, to keep things simple. Info button in main menu is now a Help/About menu, which has links to wiki in a button in it, and gets the various help buttons formerly in the help/debug menu. Update script now sends the current version and whether there's an update available. The actual version number is now reported in main and in help/about, and the prompt text for all three menus is returned by a function now instead of stored in a list, which allows us to keep up to date, and notify in help/about prompt when an update is available.  -MD
//3.934 Added button in Help/About to give license notecard and another to open Defaultsettings help URL.

//on start, send request for submenu names
//on getting submenu name, add to list if not already present
//on menu request, give dialog, with alphabetized list of submenus
//on listen, send submenu link message

string g_sCollarVersion="(loading...)";
integer g_iLatestVersion=TRUE;


list g_lMenuNames = ["Main", "AddOns", "Help/About"];
list g_lMenus;//exists in parallel to g_lMenuNames, each entry containing a pipe-delimited string with the items for the corresponding menu
list g_lMenuPrompts;

list g_lMenuIDs;//3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
integer g_iMenuStride = 3;

//integer g_iListenChan = 1908789;
//integer g_iListener;
//integer g_iTimeOut = 60;

integer g_iScriptCount;//when the scriptcount changes, rebuild menus

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
                            //str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//5000 block is reserved for IM slaves

string UPMENU = "BACK";
//string MORE = ">";
string GIVECARD = "Quick Guide";
string HELPCARD = "OpenCollar Guide";
//string REFRESH_MENU = "Fix Menus";
string DEV_GROUP = "Join R&D";
string USER_GROUP = "Join Support";
string BUGS="Report Bug";
string DEV_GROUP_ID = "c5e0525c-29a9-3b66-e302-34fe1bc1bd43";
string USER_GROUP_ID = "0f6f3627-d9cb-a1db-b770-f66fce70d1ef";
//string UPDATE="Get Update";
string WIKI = "Website";
string WIKI_URL = "http://www.opencollar.at/";
string BUGS_URL = "http://www.opencollar.at/forum.html#!/support";
string LICENSECARD="OpenCollar License";
string LICENSE="License";
//string SETTINGSHELP="Settings Help";
//string SETTINGSHELP_URL="http://www.opencollar.at/";

Debug(string text)
{
    //llOwnerSay(llGetScriptName() + ": " + text);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

Menu(string sName, key kID, integer iAuth)
{
    integer iMenuIndex = llListFindList(g_lMenuNames, [sName]);
    Debug((string)iMenuIndex);    
    if (iMenuIndex != -1)
    {
        list lItems = llParseString2List(llList2String(g_lMenus, iMenuIndex), ["|"], []);

        string sPrompt = GetPrompt(iMenuIndex);
        
        list lUtility = [];
        
        if (sName != "Main")
        {
            lUtility = [UPMENU];
        }
        
        key kMenuID = Dialog(kID, sPrompt, lItems, lUtility, 0, iAuth);
        
        integer iIndex = llListFindList(g_lMenuIDs, [kID]);
        if (~iIndex)
        {
            //we've alread given a menu to this user.  overwrite their entry
            g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
        }
        else
        {
            //we've not already given this user a menu. append to list
            g_lMenuIDs += [kID, kMenuID, sName];
        }
    }
}

integer KeyIsAv(key kID)
{
    return llGetAgentSize(kID) != ZERO_VECTOR;
}

string GetPrompt(integer index) //return prompt for menu, index of g_lMenuNames
{
    if(index==0) return "\n\nWelcome to the Main Menu\nOpenCollar Version "+g_sCollarVersion; //main
    else if (index==1) return "\n\nThis menu grants access to features of Add-on scripts.\n"; //add-ons
    else //help/about
    {
        string sTemp="\nOpenCollar version "+g_sCollarVersion+"\n";
        if(!g_iLatestVersion) sTemp+="Update available!";
        return sTemp + "\n\nThe OpenCollar stock software bundle in this item is licensed under the GPLv2 with additional requirements specific to Second Life®.\n\n© 2008 - 2013 Individual Contributors and\nOpenCollar - submission set free™\n";
//moved to bugs button response
// \n\nPlease help us make things better and report bugs here:\n\nhttp://www.opencollar.at/forum.html#!/support\nhttps://github.com/OpenCollar/OpenCollarUpdater/issues\n\n(Creating a moot.it or github account is quick, simple, free and won't up your privacy. Forums could be fun.)";
    }
}
    
MenuInit()
{
    g_lMenus = ["","",""];
    integer n;
    integer iStop = llGetListLength(g_lMenuNames);
    for (n = 0; n < iStop; n++)
    {
        string sName = llList2String(g_lMenuNames, n);
        if (sName != "Main")
        {
            //make each submenu appear in Main
            HandleMenuResponse("Main|" + sName);
            
            //request children of each submenu
            llMessageLinked(LINK_SET, MENUNAME_REQUEST, sName, NULL_KEY);            
        }
    }
    //give the help menu GIVECARD and REFRESH_MENU buttons 
    HandleMenuResponse("Help/About|" + WIKI);  
    HandleMenuResponse("Help/About|" + GIVECARD);
    //HandleMenuResponse("Options|" + REFRESH_MENU);      
    HandleMenuResponse("Help/About|" + DEV_GROUP);
    HandleMenuResponse("Help/About|" + USER_GROUP);
    HandleMenuResponse("Help/About|" + BUGS);
    HandleMenuResponse("Help/About|" + LICENSE);
    //HandleMenuResponse("Help/About|" + SETTINGSHELP);
      
    llMessageLinked(LINK_SET, MENUNAME_REQUEST, "Main", ""); 
}

HandleMenuResponse(string entry)
{
    list lParams = llParseString2List(entry, ["|"], []);
    string sName = llList2String(lParams, 0);
    integer iMenuIndex = llListFindList(g_lMenuNames, [sName]);
    if (iMenuIndex != -1)
    {             
        Debug("we handle " + sName);
        string g_sSubMenu = llList2String(lParams, 1);
        //only add submenu if not already present
        Debug("adding button " + g_sSubMenu);
        list lGuts = llParseString2List(llList2String(g_lMenus, iMenuIndex), ["|"], []);
        Debug("existing buttons for " + sName + " are " + llDumpList2String(lGuts, ","));
        if (llListFindList(lGuts, [g_sSubMenu]) == -1)
        {
            lGuts += [g_sSubMenu];
            lGuts = llListSort(lGuts, 1, TRUE);
            g_lMenus = llListReplaceList(g_lMenus, [llDumpList2String(lGuts, "|")], iMenuIndex, iMenuIndex);
        }
    }    
    else
    {
        Debug("we don't handle " + sName);
    }
}

integer UserCommand(integer iNum, string sStr, key kID)
{
    // SA: TODO delete this when transition is finished
    if (iNum == COMMAND_NOAUTH) {llMessageLinked(LINK_SET, iNum, sStr, kID); return TRUE;}
    // /SA
    if (iNum == COMMAND_EVERYONE) return TRUE;  // No command for people with no privilege in this plugin.
    else if (iNum > COMMAND_EVERYONE || iNum < COMMAND_OWNER) return FALSE; // sanity check

    list lParams = llParseString2List(sStr, [" "], []);
    string sCmd = llList2String(lParams, 0);

    if (sStr == "menu") Menu("Main", kID, iNum);
    else if (sCmd == "menu")
    {
        string sSubmenu = llGetSubString(sStr, 5, -1);
        if (llListFindList(g_lMenuNames, [sSubmenu]) != -1);
        Menu(sSubmenu, kID, iNum);
    }
    else if (sStr == "license") llGiveInventory(kID, LICENSECARD);    
    else if (sStr == "help") llGiveInventory(kID, HELPCARD); 
    else if (sStr =="about" || sStr=="help/about") Menu("Help/About",kID,iNum);               
    else if (sStr == "addons") Menu("AddOns", kID, iNum);
   // else if (sStr == "options") Menu("Options", kID, iNum);
    //else if (sCmd == "refreshmenu")
    //{
    //    llDialog(kID, "\n\nRebuilding menu.\n\nThis may take several seconds.", [], -341321);
        //MenuInit();
    //    llResetScript();
   // }
    else if (sCmd == "menuto") 
    {
        // SA: with the new authentification method, I do not like this request for auth at this stage.
        // what happens here is that up to this point, we consider that the wearer is the one
        // who issued "menuto", and then change auth to that of the clicker.
        // My opinion is that the wearer should never play a role in this and that there should be
        // only one request for auth: in the listener script.
        // This could already be done, but it would still be ugly to have this exception for "menuto"
        // in listener. I would rather have a generic way for another attachment to query an arbitrary
        // command (not only "menu") on behalf of an arbitrary avatar.
        // TODO: change the "HUD channel protocol" in order to make this possible.
        key kAv = (key)llList2String(lParams, 1);
        if (KeyIsAv(kAv))
        {
            if(llGetOwnerKey(kID)==kAv) Menu("Main", kID, iNum);
            else  llMessageLinked(LINK_SET, COMMAND_NOAUTH, "menu", kAv);
        }
        //MD: Put this back in, we still need menuto function. The auth roundtrip is an issue which could be solved by parsing kAv in the listener for menuto, but this is really no good. We can't trust arbitrary objects to supply a key. This would allow people to make a menu spammer that let them send a menu to the collar's owner without the source of the request being auth'd. Probably we need to auth hud commands on the minumum auth of object owner/key sent. I think we can deal with this in 0c4.0 though.
    }
    return TRUE;
}

default
{
    state_entry()
    {
        llSleep(1.0);//delay sending this message until we're fairly sure that other scripts have reset too, just in case
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "collarversion", NULL_KEY);
        g_iScriptCount = llGetInventoryNumber(INVENTORY_SCRIPT);
        MenuInit();      
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        // SA: delete this after transition is finished
        if (iNum == COMMAND_NOAUTH) return;
        // /SA
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == MENUNAME_RESPONSE)
        {
            //sStr will be in form of "parent|menuname"
            //ignore unless parent is in our list of menu names
            HandleMenuResponse(sStr);
        }
        else if (iNum == MENUNAME_REMOVE)
        {
            //sStr should be in form of parentmenu|childmenu
            list lParams = llParseString2List(sStr, ["|"], []);
            string parent = llList2String(lParams, 0);
            string child = llList2String(lParams, 1);
            integer iMenuIndex = llListFindList(g_lMenuNames, [parent]);
            if (iMenuIndex != -1)
            {
                list lGuts = llParseString2List(llList2String(g_lMenus, iMenuIndex), ["|"], []);
                integer gutiIndex = llListFindList(lGuts, [child]);
                //only remove if it's there
                if (gutiIndex != -1)        
                {
                    lGuts = llDeleteSubList(lGuts, gutiIndex, gutiIndex);
                    g_lMenus = llListReplaceList(g_lMenus, [llDumpList2String(lGuts, "|")], iMenuIndex, iMenuIndex);                    
                }        
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                //process response
                
                if (sMessage == UPMENU)
                {
                    Menu("Main", kAv, iAuth);
                }
                else
                {
                    if (sMessage == GIVECARD)
                    {
                        llGiveInventory(kAv, HELPCARD);
                        Menu("Help/About", kAv, iAuth);
                    }
                    else if (sMessage == LICENSE)
                    {
                        if(llGetInventoryType(LICENSECARD)==INVENTORY_NOTECARD) llGiveInventory(kAv,LICENSECARD);
                        else llRegionSayTo(kAv,0,"License notecard missing from collar, sorry."); 
                        Menu("Help/About", kAv, iAuth);
                    }
                   // else if(sMessage == SETTINGSHELP)
                   // {
                   //     llSleep(0.2);
                   //     llLoadURL(kAv, "\n\nSettings can be permanently stored even over an update or script reset by saving them to the defaultsettings notecard inside your collar. For instructions, click the link ("+SETTINGSHELP_URL+").", SETTINGSHELP_URL);
                   //     return;
                   // }
                    else if (sMessage == WIKI)
                    {
                        llSleep(0.2);
                        llLoadURL(kAv, "\n\nVisit our homepage for help, discussion and news.\n", WIKI_URL);
                        return;
                    }
                    else if (sMessage == BUGS)
                    {
                        llDialog(kAv,"Please help us to improve OpenCollar by reporting any bugs you see bugs. Click to open our support board at: \n"+BUGS_URL+"\n Or even better, use our github resource where you can create issues for bug reporting  / feature requests. \n https://github.com/OpenCollar/OpenCollarUpdater/issues\n\n(Creating a moot.it or github account is quick, simple, free and won't up your privacy. Forums could be fun.)",[],-39457);
                        return;
                    }
                        
                    else if (sMessage == DEV_GROUP)
                    {
                        llInstantMessage(kAv,"\n\nJoin secondlife:///app/group/" + DEV_GROUP_ID + "/about " + "for scripter talk.\nhttp://www.opencollar.at/forum.html#!/tinkerbox\n\n");
                        Menu("Help/About", kAv, iAuth);
                    }
                    else if (sMessage == USER_GROUP)
                    {
                        llInstantMessage(kAv,"\n\nJoin secondlife:///app/group/" + USER_GROUP_ID + "/about " + "for friendly support.\nhttp://www.opencollar.at/forum.html#!/support\n\n");
                        Menu("Help/About", kAv, iAuth);
                    }
                    //else if (sMessage == REFRESH_MENU)
                    //{//send a command telling other plugins to rebuild their menus
                    //    UserCommand(iAuth, "refreshmenu", kAv);
                    //}
                    else
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMessage, kAv);
                    }
                }
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            if(sToken == "collarversion")
            {
                g_sCollarVersion=llList2String(lParams,1);
                //integer iLatest=(integer)llList2String(lParams,2);
                // if(iLatest!=g_iLatestVersion)
                //{
                //    if(!g_iLatestVersion) HandleMenuResponse("Help/About|" + UPDATE);
                //    else
                //    {
                //        list lGuts = llParseString2List(llList2String(g_lMenus,2), ["|"], []);
                //        integer gutiIndex = llListFindList(lGuts, [UPDATE]);
                //        if (gutiIndex != -1)        
                //        {
                //            lGuts = llDeleteSubList(lGuts, gutiIndex, gutiIndex);
                //            g_lMenus = llListReplaceList(g_lMenus, [llDumpList2String(lGuts, "|")], 2, 2);  
                //        }
                //     }
                //     g_iLatestVersion=iLatest; 
                //}
                //Changed my mind about the above code. I was going to be all smart about it, but frankly we want the updater button there all the time anyway, no reason not to have it. And I can't be bothered to mess around with re-routing the commands from update right now. :D -MD 
                g_iLatestVersion=(integer)llList2String(lParams,2);
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
    
    changed(integer iChange)
    {
        if (iChange & CHANGED_INVENTORY)
        {
            if (llGetInventoryNumber(INVENTORY_SCRIPT) != g_iScriptCount)
            {//a script has been added or removed.  Reset to rebuild menu
                llResetScript();
            }
        }
    }
}
