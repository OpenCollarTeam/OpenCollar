/*
    This file is a part of OpenCollar.
    Copyright ©2021
    : Contributors :
    Phidoux (taya.Maruti)
        * Aug 16 2023 - meged menu and dialog script to make a base menu and configured it to accept buttons
          from other scripts making the stand alone addon function similar to the plugin api of the collar,
          for easier use by scripters to get a project of the ground.
        * Aug 18 2023 - added lock and access denial.
        * Aug 18 2023 - Added ability to goggle individual sync options for authorizations.
*/

//integer CMD_ZERO                = 0;
//integer CMD_OWNER               = 500;
//integer CMD_TRUSTED             = 501;
//integer CMD_GROUP               = 502;
integer CMD_WEARER              = 503;
//integer CMD_EVERYONE            = 504;
//integer CMD_BLOCKED             = 598; // <--- Used in auth_request, will not return on a CMD_ZERO

integer DIALOG                  = -9000;
integer DIALOG_RESPONSE         = -9001;
//integer DIALOG_TIMEOUT         = -9002;
integer MENU_REQUEST            = -9003;
integer MENU_REGISTER           = -9004;
integer MENU_REMOVE             = -9005;
integer MENU_RESPONCE           = -9006;

list g_lMenuIDs;

//integer g_iMenuStride;
integer g_iPage = 0;
integer g_iNumberOfPages;

string UPMENU = "BACK";
list g_lCheckBoxes = ["▢","▣"];
string b_sLock;
string b_sAccess;
string b_sAddon;
string b_sSyncPrefix;
string b_sSyncOwner;
string b_sSyncTrust;
string b_sSyncBlock;
string b_sSyncGroup;
string b_sSyncLock;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iAuth, string sName)
{
    integer iChannel = llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenuIDs, [iChannel]))
    {
        iChannel = llRound(llFrand(10000000)) + 100000;
    }
    integer iListener = llListen(iChannel, "",kID, "");
    integer iTime = llGetUnixTime() + 180;
    if(llGetListLength(g_lMenuIDs))
    {
        integer iIndex = llListFindList(g_lMenuIDs, [kID]);
        if (~iIndex)
        {
            g_lMenuIDs = llListReplaceList(g_lMenuIDs,[kID, iChannel, iListener, iTime, sName, iAuth],iIndex,iIndex+5);
        }
        else
        {
            g_lMenuIDs += [kID, iChannel, iListener, iTime, sName, iAuth];
        }
    }
    else
    {
            g_lMenuIDs += [kID, iChannel, iListener, iTime, sName, iAuth];
    }
    llSetTimerEvent(180);
    llDialog(kID,sPrompt,SortButtons(lChoices,lUtilityButtons),iChannel);
}

list SortButtons(list lButtons, list lStaticButtons)
{
    list lSpacers;
    list lAllButtons = lButtons + lStaticButtons;
    //cutting off too many buttons, no multi page menus as of now
    while (llGetListLength(lAllButtons)>12)
    {
        lButtons = llDeleteSubList(lButtons,0,0);
        lAllButtons = lButtons + lStaticButtons;
    }
    while (llGetListLength(lAllButtons) % 3 != 0 && llGetListLength(lAllButtons) < 12)
    {
        lSpacers += "-";
        lAllButtons = lButtons + lSpacers + lStaticButtons;
    }
    integer i = llListFindList(lAllButtons, ["BACK"]);
    if (~i)
    {
        lAllButtons = llDeleteSubList(lAllButtons, i, i);
    }
    list lOut = llList2List(lAllButtons, 9, 11);
    lOut += llList2List(lAllButtons, 6, 8);
    lOut += llList2List(lAllButtons, 3, 5);
    lOut += llList2List(lAllButtons, 0, 2);
    if (~i)
    {
        lOut = llListInsertList(lOut, ["BACK"], 2);
    }
    lAllButtons = [];
    lButtons = [];
    lSpacers = [];
    lStaticButtons = [];
    return lOut;
}

Menu(key kID, integer iPage, integer iAuth)
{
    if (!iPage)
    {
        g_iPage = 0;
    }
    string sPrompt =    "|=====Main=====|";
    list lMenuButtons = llParseString2List(llLinksetDataRead("menu_main"),[","],[]);
    list lButtons   = [];
    list lUtilityButtons = ["Admin"];
    if (llGetListLength(lMenuButtons))
    {
        lButtons += lMenuButtons;
        if(llGetListLength(lButtons)>11)
        {
            lUtilityButtons = ["◄","Admin","►"];
            g_iNumberOfPages = llGetListLength(lButtons)/9;
            lButtons = llList2List(lButtons,iPage*9,iPage*9+8);
        }
    }
    else
    {
        lButtons = ["Example"];
    }
    Dialog(kID, sPrompt, lButtons, lUtilityButtons, iAuth, "Menu~Main");
}

Menu_Admin(key kID, integer iAuth)
{
    b_sLock         = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("addon_lock"))+"Lock";
    b_sAccess       = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("addon_noaccess"))+"NoAccess";
    string sPrompt  = "|=====Adnimistration=====|";
    list lButtons = [];
    list lUtilityButtons = [];// this is only here so we can set ultities to respect online and offline mode.
    if(iAuth == CMD_WEARER && (integer)llLinksetDataRead("addon_noaccess"))
    {
        sPrompt += "\n!!!NOT AUTHORIZED!!!";
        lButtons = ["-"];
        if((integer)llLinksetDataRead("addon_mode"))
        {
            if(!(integer)llLinksetDataRead("addon_online"))
            {
                lUtilityButtons = ["RESET","CONNECT"];
            }
            else
            {
                lUtilityButtons = ["RESET","Collar"];
            }
        }
        else
        {
            lUtilityButtons = ["RESET"];
        }
    }
    else
    {
        sPrompt +=  "\n"+b_sLock+" - Toggles the addon lock!"+
                    "\n"+b_sAccess+" - Toggles sub's access to menues!";
        lButtons = [b_sLock,b_sAccess,"Sync"];
        if((integer)llLinksetDataRead("addon_mode"))
        {
            if( (integer)llLinksetDataRead("addon_online")) // we only need certain buttons when they are nesissary.
            {
                lButtons += ["Collar"];
                lUtilityButtons = ["RESET","DISCONNECT"];
            }
            else
            {
                lUtilityButtons = ["RESET","CONNECT"];
            }
        }
        else
        {
            lUtilityButtons = ["RESET"];
        }
    }
    lUtilityButtons += [UPMENU];

    Dialog(kID, sPrompt, lButtons, lUtilityButtons, iAuth, "Admin~Main");
}

Menu_Sync(key kID, integer iAuth)
{
    b_sAddon        = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("addon_mode"))+"Addon";
    b_sSyncPrefix   = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("sync_prefix"))+"Prefix";
    b_sSyncOwner    = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("sync_owner"))+"Owners";
    b_sSyncTrust    = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("sync_trust"))+"Trusted";
    b_sSyncBlock    = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("sync_block"))+"Blocked";
    b_sSyncGroup    = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("sync_group"))+"Group";
    b_sSyncLock     = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead("sync_lock"))+"Lock";
    string sPrompt = "|=====Collar Sync=====|";
    list lButtons = [];
    if(iAuth == CMD_WEARER && (integer)llLinksetDataRead("addon_noaccess"))
    {
        sPrompt += "\n!!!NOT AUTHORIZED!!!";
        lButtons = ["-"];
    }
    else
    {
        sPrompt +=  "\n "+b_sAddon+" - Determines weather the addon will connect to the collar.";
        lButtons = [b_sAddon];
        if((integer)llLinksetDataRead("addon_mode"))
        {
            sPrompt += "\n"+b_sSyncPrefix+" - Addon assumes same prefix as collar when connected!"+
                    "\n"+b_sSyncLock+" - Addon lock will take on the same lock status as the collar!"+
                    "\n"+b_sSyncOwner+" - Addon will include owners from collar list!"+
                    "\n"+b_sSyncTrust+" - Addon will include trusted from collar list!"+
                    "\n"+b_sSyncBlock+" - Addon will include blocked from collar list!"+
                    "\n"+b_sSyncGroup+" - Addon Will include group from the collar list!";
            lButtons += [b_sSyncLock,b_sSyncPrefix,b_sSyncOwner,b_sSyncTrust,b_sSyncBlock,b_sSyncGroup];
        }
    }
    list lUtilityButtons = [UPMENU];

    Dialog(kID, sPrompt, lButtons, lUtilityButtons, iAuth, "Admin~Sync");
}

Menu_Confirm(key kID, integer iAuth)
{
    string sPrompt = "|=====Confirmation=====|"+
                     "\nAre you sure you want to reset scripts and memory?";
    list lButtons = ["Yes"];
    Dialog(kID, sPrompt, lButtons, ["No"], iAuth, "Reset~Query");
}

Add_MenuItem(string sButton)
{
    if( ~llListFindList(["-","Admin","◄","►",""," "],[sButton]) )
    {
        llMessageLinked(LINK_SET, MENU_RESPONCE, sButton+"|Invalid", "");
    }
    else if(~llSubStringIndex(llLinksetDataRead("menu_main"), sButton))
    {
        llMessageLinked(LINK_SET, MENU_RESPONCE, sButton+"|Exists", "");
    }
    else
    {
        if(llLinksetDataRead("menu_main") == "")
        {
            llLinksetDataWrite("menu_main",sButton);
        }
        else
        {
            llLinksetDataWrite("menu_main",llLinksetDataRead("menu_main")+","+sButton);
        }
        llMessageLinked(LINK_SET, MENU_RESPONCE, sButton+"|Added", "");
    }
}

Remove_MenuItem(string sButton)
{
    if(~llListFindList(["-","Admin","◄","►",""," "],[sButton]))
    {
        llMessageLinked(LINK_SET,MENU_RESPONCE,sButton+"|Invalid","");
        return;
    }
    list lMenu = llParseString2List(llLinksetDataRead("menu_main"),[","],[]);
    integer iButton = llListFindList(lMenu,[sButton]);
    if(iButton != -1)
    {
        lMenu = llDeleteSubList(lMenu,iButton,iButton);
        llLinksetDataWrite("menu_main",llDumpList2String(lMenu,","));
        llMessageLinked(LINK_SET,MENU_RESPONCE,sButton+"|Removed","");
    }
    else
    {
        llMessageLinked(LINK_SET,MENU_RESPONCE,sButton+"|NoButton","");
    }
    lMenu = [];
    sButton = "";
}

default
{
    timer()
    {
        integer n = llGetListLength(g_lMenuIDs) - 5;
        integer iNow = llGetUnixTime();
        for ( n; n>=0; n=n-5 )
        {
            integer iDieTime = llList2Integer(g_lMenuIDs,n+3);
            if ( iNow > iDieTime )
            {
                llInstantMessage(llList2Key(g_lMenuIDs,n-1),"Menu Timed out!");
                llListenRemove(llList2Integer(g_lMenuIDs,n+2));
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs,n,n+5);
            }
        }
        if(!llGetListLength(g_lMenuIDs))
        {
            llSetTimerEvent(0.0);
        }
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if (llListFindList(g_lMenuIDs,[kID,iChannel]) != -1)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            integer iAuth = llList2Integer(g_lMenuIDs,iMenuIndex+5);
            string sMenu = llList2String(g_lMenuIDs, iMenuIndex+4);
            llListenRemove(llList2Integer(g_lMenuIDs,iMenuIndex+2));
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs,iMenuIndex, iMenuIndex+5);
            integer iRespring = TRUE;
            if (sMenu == "Menu~Main")
            {
                if (sMsg == "Example")
                {
                    llInstantMessage(kID,"This is an example button!");
                }
                else if (sMsg == "Admin")
                {
                    iRespring = FALSE;
                    Menu_Admin(kID, iAuth);
                }
                else if (sMsg == "►")
                {
                    if (++g_iPage > g_iNumberOfPages) g_iPage = 0;
                }
                else if (sMsg == "◄")
                {
                    if (--g_iPage < 0) g_iPage = g_iNumberOfPages;
                }
                else
                {
                    iRespring = FALSE;
                    llMessageLinked( LINK_SET, MENU_REQUEST, (string)iAuth+"|"+sMsg, kID);
                }
                if(iRespring)
                {
                        Menu(kID, g_iPage, iAuth);
                }
            }
            else if( sMenu == "Admin~Main")
            {
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    Menu(kID, 0, iAuth);
                }
                else if (sMsg == b_sLock)
                {
                    llLinksetDataWrite("addon_lock",(string)(!(integer)llLinksetDataRead("addon_lock")));
                    if((integer)llLinksetDataRead("addon_lock"))
                    {
                        llSay(0,"The lock clicks as secondlife:///app/agent/"+(string)kID+"/about locks it!");
                    }
                    else
                    {
                        llSay(0,"The lock clicks as secondlife:///app/agent/"+(string)kID+"/about unlocks it!");
                    }
                }
                else if (sMsg == b_sAccess)
                {
                    llLinksetDataWrite("addon_noaccess",(string)(!(integer)llLinksetDataRead("addon_noaccess")));
                }
                else if (sMsg == "Sync")
                {
                    iRespring = FALSE;
                    Menu_Sync(kID,iAuth);
                }
                else if (sMsg == "RESET") // so we can clear memory in the event of bugs.
                {
                    iRespring = FALSE;
                    Menu_Confirm(kID,iAuth);
                }
                else if (sMsg == "Collar")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"CollarMenu",kID);
                }
                else if (sMsg == "DISCONNECT")
                {
                    iRespring = FALSE;
                    llLinksetDataWrite("addon_online",(string)FALSE);
                }
                else if (sMsg == "CONNECT")
                {
                    iRespring = FALSE;
                    // if the collar disconects but is available we want the user to be able to connect it if they don't wish to safe word.
                    llLinksetDataWrite("addon_online",(string)TRUE);
                }
                if(iRespring)
                {
                    Menu_Admin(kID,iAuth);
                }
            }
            else if(sMenu == "Admin~Sync")
            {
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    Menu_Admin(kID, iAuth);
                }
                else if (sMsg == b_sSyncLock)
                {
                    llLinksetDataWrite("sync_lock",(string)(!(integer)llLinksetDataRead("sync_lock")));
                }
                else if (sMsg == b_sSyncPrefix)
                {
                    llLinksetDataWrite("sync_prefix",(string)(!(integer)llLinksetDataRead("sync_prefix")));
                }
                else if (sMsg == b_sSyncOwner)
                {
                    llLinksetDataWrite("sync_owner",(string)(!(integer)llLinksetDataRead("sync_owner")));
                }
                else if (sMsg == b_sSyncTrust)
                {
                    llLinksetDataWrite("sync_trust",(string)(!(integer)llLinksetDataRead("sync_trust")));
                }
                else if (sMsg == b_sSyncBlock)
                {
                    llLinksetDataWrite("sync_block",(string)(!(integer)llLinksetDataRead("sync_block")));
                }
                else if (sMsg == b_sSyncGroup)
                {
                    llLinksetDataWrite("sync_group",(string)(!(integer)llLinksetDataRead("sync_group")));
                }
                else if (sMsg == b_sAddon)
                {
                    llLinksetDataWrite("addon_mode",(string)(!(integer)llLinksetDataRead("addon_mode")));
                }
                if(iRespring)
                {
                    Menu_Sync(kID,iAuth);
                }
            }
            else if(sMenu == "Reset~Query")
            {
                if( sMsg == "Yes")
                {
                    llOwnerSay("Addon memory is being wiped and scripts being reset");
                    llLinksetDataReset();
                }
                else if( sMsg == "No")
                {
                    Menu_Admin(kID, iAuth);
                }
            }
            else
            {
                // Return the output
                llMessageLinked( LINK_SET, DIALOG_RESPONSE, (string)iAuth+","+sMenu+","+sMsg, kID);
            }
        }
    }

    link_message(integer iLink, integer iNum,string sMsg, key kID)
    {
        if( iNum == DIALOG )
        {
            // Process and display menu.
            list lPar = llParseString2List(sMsg,["^"],[]);
            string sPrompt = llList2String(lPar,0);
            list lButtons = llParseString2List(llList2String(lPar,1),["`"],[]);
            list lUtilityButtons = llParseString2List(llList2String(lPar,2),["`"],[]);
            integer iAuth = llList2Integer(lPar,3);
            string sName = llList2String(lPar,4);
            Dialog( kID, sPrompt, lButtons, lUtilityButtons, iAuth, sName);
        }
        else if(iNum == MENU_REQUEST)
        {
            list lPar = llParseString2List(sMsg,["|"],[]);
            integer iAuth = llList2Integer(lPar,0);
            string sMenu = llList2String(lPar,1);
            if(sMenu == "MenuMain")
            {
                Menu(kID, 0, iAuth);
            }
        }
        else if(iNum == MENU_REGISTER)
        {
            //llOwnerSay("[addon register button request.]");
            Add_MenuItem(sMsg);
        }
        else if(iNum == MENU_REMOVE)
        {
            Remove_MenuItem(sMsg);
        }
    }
}
