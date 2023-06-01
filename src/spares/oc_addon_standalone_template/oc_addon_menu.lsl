//integer CMD_ZERO            = 0;
integer CMD_OWNER           = 500;
//integer CMD_TRUSTED         = 501;
//integer CMD_GROUP           = 502;
integer CMD_WEARER          = 503;
//integer CMD_EVERYONE        = 504;
//integer CMD_BLOCKED         = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY       = 507;
//integer CMD_SAFEWORD        = 510;
//integer CMD_RELAY_SAFEWORD  = 511;
//integer CMD_NOACCESS        = 599;

//integer g_iMenuStride;
//integer g_iPage = 0;
//integer g_iNumberOfPages;

string UPMENU = "BACK";
list g_lCheckBoxes = ["▢","▣"];

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName)
{
    list g_lMenuIDs;
    if(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu") != "")
    {
        g_lMenuIDs = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu"),[","],[]);
    }
    integer iChannel = llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenuIDs, [iChannel]))
    {
        iChannel = llRound(llFrand(10000000)) + 100000;
    }
    integer iListener = llListen(iChannel, "",kID, "");
    integer iTime = llGetUnixTime() + 180;
    integer iIndex = llListFindList(g_lMenuIDs, [(string)kID]);
    if (~iIndex)
    {
        llListenRemove(llList2Integer(g_lMenuIDs,2));
        g_lMenuIDs = llListReplaceList(g_lMenuIDs,[kID, iChannel, iListener, iTime, sName, iAuth],iIndex,iIndex+4);
    }
    else
    {
        g_lMenuIDs = [kID, iChannel, iListener, iTime, sName, iAuth];
    }
    llDialog(kID,sPrompt,SortButtons(lChoices,lUtilityButtons),iChannel);
    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_menu",llDumpList2String(g_lMenuIDs,","));
    iPage = 0;
    g_lMenuIDs = [];
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

Menu(key kID, integer iAuth)
{
    string sPrompt =    "|====="+llLinksetDataRead("addon_name")+" Main=====|";
    list lButtons  = ["Addon Button"];
    Dialog(kID, sPrompt, lButtons, ["Admin"], 0, iAuth, "Menu~Main");
}

MenuAdmin(key kID, integer iAuth)
{
    string sPrompt =    "|=====Adnimistration=====|"+
                        "\nPrint LSD: Prints the Linkset Data keys=Value"+
                        "\nClear Memory: Reset LSD and forces all scripts to restart"+
                        "\nCollar: Brings up the collar menu when connected"+
                        "\nCONNECT: Connects the addon to the Collar"+
                        "\nDISCONNECT: Disconnects the Addon from the collar";
    list lButtons  = ["Clear Memory","Print LSD"];
    list lUtilityButtons = [];// this is only here so we can set ultities to respect online and offline mode.

    if( (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_online")) // we only need certain buttons when they are nesissary.
    {
        lUtilityButtons = ["Collar","DISCONNECT",UPMENU];
    }
    else
    {
        lUtilityButtons = ["CONNECT",UPMENU];
    }

    Dialog(kID, sPrompt, lButtons, lUtilityButtons, 0, iAuth, "Menu~Admin");
}

Menu_Confirm(key kID, integer iAuth, string sMenu, string sQuery)
{
    string sPrompt = "|=====Confirmation Menu=====|\n\nReason:"+sQuery;
    string sQMenu = "Menu-Q"+sMenu;
    list lButtons = ["Yes","No"];
    Dialog(kID, sPrompt, lButtons, [], 0, iAuth, sQMenu);
}

Notify(string sMsg,key kID)
{
    llInstantMessage(kID,sMsg);
    if(kID != llGetOwner())
    {
        llOwnerSay(sMsg);
    }
    sMsg ="";
    kID = "";
}

default
{
    state_entry()
    {
        if(llGetAttached())
        {
            llLinksetDataWrite("auth_wearer",llGetOwner());
            if(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu") != "")
            {
                llLinksetDataDelete(llToLower(llLinksetDataRead("addon_name"))+"_menu");
            }
            llSetTimerEvent(60);
        }
    }

    timer()
    {
        list g_lMenuIDs = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu"),[","],[]);
        if(llGetListLength(g_lMenuIDs))
        {
            if(llGetUnixTime() >= llList2Integer(g_lMenuIDs,3))
            {
                llListenRemove(llList2Integer(g_lMenuIDs,2));
                llLinksetDataDelete(llToLower(llLinksetDataRead("addon_name"))+"_menu");
                llOwnerSay("Closing Menu:"+llList2String(g_lMenuIDs,4));
            }
        }
        g_lMenuIDs=[];
    }

    listen(integer iChannel, string sName, key kID, string sMsg)
    {
        if (~llListFindList( llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu"),[","],[]),[(string)kID,(string)iChannel]))
        {
            list g_lMenuIDs = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu"),[","],[]);
            //llOwnerSay(llToLower(llLinksetDataRead("addon_name"))+"_menu"+" Data is\n["+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu")+"]\nand g_lMenuIDs Data is\n["+llDumpList2String(g_lMenuIDs,",")+"]");
            if(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu") == "")
            {
                llOwnerSay("Error Menu is Blank when it should not be!");
                g_lMenuIDs = [];
            }
            integer iMenuIndex = llListFindList(g_lMenuIDs, [(string)kID]);
            integer iAuth = llList2Integer(g_lMenuIDs,iMenuIndex+5);
            string sMenu = llList2String(g_lMenuIDs, iMenuIndex+4);
            llListenRemove(llList2Integer(g_lMenuIDs,iMenuIndex+2));
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs,iMenuIndex, iMenuIndex+4);
            llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_menu",llDumpList2String(g_lMenuIDs,","));
            llLinksetDataWrite("menu_user",(string)kID);
            g_lMenuIDs=[];
            integer iRespring = TRUE;
            if (sMenu == "Menu~Main") {
                if (sMsg == "Admin")
                {
                    iRespring = FALSE;
                    MenuAdmin(kID, iAuth);
                }
                else if(sMsg == "Addon Button")
                {
                    Notify("this is an example Button",kID);
                }
                if(iRespring)
                {
                    Menu(kID, iAuth);
                }
            }
            else if( sMenu == "Menu~Admin")
            {
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    Menu(kID, iAuth);
                }
                else if (sMsg == "Clear Memory")
                {
                    iRespring = FALSE;
                    Menu_Confirm(kID,iAuth,"mem","Would you like to clear LinksetData?");
                }
                else if (sMsg == "Print LSD")
                {
                    list lLSD = llListSort(llLinksetDataListKeys(0,llLinksetDataCountKeys()-1),1,TRUE);
                    integer iIndex = 0;
                    string sKey;
                    for(iIndex = 0; iIndex < llGetListLength(lLSD); iIndex++)
                    {
                        sKey = llList2String(lLSD,iIndex);
                        Notify(sKey+"="+llLinksetDataRead(sKey),kID);
                    }
                    sKey="";
                    lLSD = [];
                }
                else if (sMsg == "Collar")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"CollarMenu",kID);
                    //Link("from_addon", iAuth, "menu Addons", kID);
                }
                else if (sMsg == "DISCONNECT")
                {
                    iRespring = FALSE;
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_online",(string)FALSE);
                }
                else if (sMsg == "CONNECT")
                {
                    iRespring = FALSE;
                    // if the collar disconects but is available we want the user to be able to connect it if they don't wish to safe word.
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_online",(string)TRUE);
                    //state default;
                }
                if(iRespring)
                {
                    MenuAdmin(kID,iAuth);
                }
            }
            else if(~llSubStringIndex(sMenu,"Menu-Q"))
            {
                if( sMsg == "Yes")
                {
                    if(~llSubStringIndex(sMenu,"mem"))
                    {
                        Notify("Memory is being wiped and scripts are being reset!",kID);
                        llLinksetDataReset();
                    }
                }
                else if( sMsg == "No")
                {
                    if(~llSubStringIndex(sMenu,"mem"))
                    {
                        MenuAdmin(kID, iAuth);
                    }
                }
            }
        }
    }

    link_message(integer iLink, integer iNum,string sMsg, key kID)
    {
        if (iNum <= CMD_WEARER && iNum >= CMD_OWNER)
        {
            if(sMsg == "Menu")
            {
                if(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu") != "")
                {
                    llLinksetDataDelete(llToLower(llLinksetDataRead("addon_name"))+"_menu");
                }
                Menu(kID,iNum);
            }
        }
    }

    linkset_data(integer iAction,string sName,string sVal)
    {
        if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }
}
