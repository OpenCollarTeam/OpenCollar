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
integer g_iPage = 0;
integer g_iNumberOfPages;

string UPMENU = "BACK";
//string b_sLock;
//string b_sAccess;
string b_sPower;
string b_sSitAny;
string b_sTyping;
// these buttons will be used for making loops.
//string b_sStandLoop;
//string b_sStandRand;
string b_sSitAO;
//string b_sSitLoop;
//string b_sSitRand;
//string b_sGSitLoop;
//string b_sGSitRand;
//string b_sWalkLoop;
//string b_sWalkRand;
//string b_sFloat;
list g_lCheckBoxes = ["▢","▣"];
list g_lCustomCards = [];
//

recordMemory()
{
    llLinksetDataWrite("memory_"+llGetScriptName(),(string)llGetUsedMemory());
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName)
{
    list g_lMenuIDs = llCSV2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu"));
    integer iChannel = llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenuIDs, [iChannel]))
    {
        iChannel = llRound(llFrand(10000000)) + 100000;
    }
    integer iListener = llListen(iChannel, "",kID, "");
    integer iTime = llGetUnixTime() + 180;
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
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
    string sPrompt = "|====="+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_addon")+" Main=====|"+
        "\n Version: "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_ver");
    // load toggle buttons.
    b_sPower = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))+"Power";
    b_sSitAny= llList2String(g_lCheckBoxes,(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere"))+"Sit Anywhere";
    b_sTyping = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_typingctl"))+"Typing";
    b_sSitAO = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitctl"))+"Sit AO";
    // set status information.
    sPrompt +=  "\nNotecard:"+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_card")+
                "\n"+llList2String(g_lCheckBoxes,(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_loaded"))+"Loaded"+
                "\n"+llList2String(g_lCheckBoxes,(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_online"))+"Collar Addon"+
                "\n"+b_sPower+
                "\n"+b_sSitAny+
                "\n"+b_sTyping
    ;
    // Populate Buttons list.
    list lButtons  = [b_sPower,"Load",b_sTyping,b_sSitAny,b_sSitAO,"Anims"];
    // Start dialog.
    Dialog(kID, sPrompt, lButtons, ["Admin", UPMENU], 0, iAuth, "Menu~Main");
}

MenuAnims(key kID, integer iAuth)
{
    string sPrompt = "|=====Animations=====|";
    // list lButtons  = ["GroundSit","Sitting","Standing","Swimming","Tail","Walking","Wings"]; // Swimming ao relates to float function but its not yet working.
    list lButtons  = ["GroundSit","Sitting","Standing","Tail","Walking","Wings"];
    // Start dialog.
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Anims");
}

MenuLoad(key kID, integer iPage, integer iAuth)
{
    if (!iPage)
    {
        g_iPage = 0;
    }
    string sPrompt = "\nLoad an animation set!";
    list lButtons;
    g_lCustomCards = [];
    integer iEnd = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer iCountCustomCards;
    string sNotecardName;
    integer i;
    while (i < iEnd)
    {
        sNotecardName = llGetInventoryName(INVENTORY_NOTECARD, i++);
        if (llSubStringIndex(sNotecardName,".") && sNotecardName != "")
        {
            if (!llSubStringIndex(sNotecardName,"SET"))
            {
                g_lCustomCards += [sNotecardName,"Wildcard "+(string)(++iCountCustomCards)];// + g_lCustomCards;
            }
            else if(llStringLength(sNotecardName) < 24)
            {
                lButtons += sNotecardName;
            }
            else
            {
                llOwnerSay(sNotecardName+"'s name is too long to be displayed in menus and cannot be used.");
            }
        }
    }
    i = 1;
    while (i <= 2*iCountCustomCards)
    {
        lButtons += llList2List(g_lCustomCards,i,i);
        i += 2;
    }
    list lStaticButtons = ["BACK"];
    if (llGetListLength(lButtons) > 11)
    {
        lStaticButtons = ["◄","►","BACK"];
        g_iNumberOfPages = llGetListLength(lButtons)/9;
        lButtons = llList2List(lButtons,iPage*9,iPage*9+8);
    }
    if (!llGetListLength(lButtons)){
        llOwnerSay("There aren't any animation sets installed!");
    }
    Dialog(kID, sPrompt, lButtons, lStaticButtons, iPage, iAuth,"Menu~Load");
}
/* Swimming ao or Floating in water is not functional at the moment.
MenuSwim(key kID, integer iAuth)
{
    string sPrompt = "|=====Swimming=====|";
    // load toggle buttons.
    b_sFloat = llList2String(g_lCheckBoxes,(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_floats"))+"Floats";
    // set status information.
    sPrompt +=  "\n"+b_sFloat+
                "\nAvitar Buoyency:"+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_buoyant")
    ;
    // Populate Buttons list.
    list lButtons  = [b_sFloat];
    // Start dialog.
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Swim");
}*/

MenuAdmin(key kID, integer iAuth)
{
    string sPrompt = "|=====Adnimistration=====|"+
        "\n Memory: Used/Free/Max"+
        "\n Object Scripts(KB): "+llLinksetDataRead("ObjectMemory")+
        "\n Linkset(Bytes): "+llLinksetDataRead("lsMemory")
    ;

    list lButtons  = ["Clear Memory","Print Memory","Print LSD"];
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
    //llOwnerSay("Prompting confirmation!");
    string sPrompt = "\n ao Confirmation Menu\n\n"+sQuery;
    string sQMenu = "Menu-Q"+sMenu;
    list lButtons = ["Yes","No"];
    Dialog(kID, sPrompt, lButtons, [], 0, iAuth, sQMenu);
}

default
{
    state_entry()
    {
        if(llGetAttached())
        {
            llLinksetDataWrite("auth_wearer",llGetOwner());
            recordMemory();
            if(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu") != "")
            {
                llOwnerSay("Clearing old menues!");
                llLinksetDataDelete(llToLower(llLinksetDataRead("addon_name"))+"_menu");
            }
            /*if(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_loaded") && !(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
            {
            }*/
            llSetTimerEvent(1);
        }
    }

    timer()
    {
        list g_lMenuIDs = llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_menu"),[","],[]);
        if(llGetListLength(g_lMenuIDs))
        {
            if(llGetUnixTime() > llList2Integer(g_lMenuIDs,3))
            {
                llListenRemove(llList2Integer(g_lMenuIDs,2));
                llLinksetDataDelete(llToLower(llLinksetDataRead("addon_name"))+"_menu");
                g_lCustomCards = [];
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
            g_lMenuIDs=[];
            integer iRespring = TRUE;
            if (sMenu == "Menu~Main")
            {
                if (sMsg == "Admin")
                {
                    MenuAdmin(kID, iAuth);
                    iRespring = FALSE;
                }
                else if (sMsg == "Anims")
                {
                    iRespring = FALSE;
                    MenuAnims(kID, iAuth);
                }
                else if (sMsg == "Load")
                {
                    MenuLoad(kID, 0, iAuth);
                    iRespring = FALSE;
                }
                else if(sMsg == b_sSitAO)
                {
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_sitctl",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitctl")));
                }
                else if(sMsg == b_sTyping)
                {
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_typingctl",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_typingctl")));
                }
                else if (sMsg == b_sPower)
                {
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_power",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power")));
                }
                else if( sMsg == b_sSitAny)
                {
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere")));
                }
                if(iRespring)
                {
                    Menu(kID,iAuth);
                }
            }
            else if( sMenu == "Menu~Anims")
            {
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    Menu(kID, iAuth);
                }
                else if( sMsg == "GroundSit")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"MenuGroundSit",kID);
                }
                else if( sMsg == "Sitting")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"MenuSitting",kID);
                }
                else if( sMsg == "Standing")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"MenuStanding",kID);
                }
                /*else if( sMsg == "Swimming")
                {
                    iRespring = FALSE;
                    MenuSwim(kID,iAuth);
                }*/
                else if( sMsg == "Tail")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"MenuTail",kID);
                }
                else if( sMsg == "Walking")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"MenuWalking",kID);
                }
                else if( sMsg == "Wings")
                {
                    iRespring = FALSE;
                    llMessageLinked(LINK_SET,iAuth,"MenuWings",kID);
                }
                if(iRespring)
                {
                    MenuAnims(kID,iAuth);
                }
            }
            else if( sMenu == "Menu~Load")
            {
                integer index = llListFindList(g_lCustomCards,[sMsg]);
                if (~index)
                {
                    sMsg = llList2String(g_lCustomCards,index-1);
                }
                if (llGetInventoryType(sMsg) == INVENTORY_NOTECARD)
                {
                    //UserCommand(iAuth,"ao load "+sMsg,kID);
                    if(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_card") != sMsg)
                    {
                        if(llGetInventoryType(sMsg) == INVENTORY_NOTECARD)
                        {
                            llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_loaded",(string)FALSE);
                            llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_card",sMsg);
                        }
                        else if (kID != "" && kID != NULL_KEY)
                        {
                            llInstantMessage(kID,"that card does not seem to exist!");
                            MenuLoad(kID,g_iPage,iAuth);
                        }
                    }
                    else if (kID != "" && kID != NULL_KEY)
                    {
                        llInstantMessage(kID,"Card is already loaded try a different one or clear memory");
                        MenuLoad(kID,g_iPage,iAuth);
                    }
                    return;
                }
                else if ((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_loaded")&& sMsg == "BACK")
                {
                    Menu(kID,iAuth);
                    g_lCustomCards = [];
                    return;
                }
                else if (sMsg == "►")
                {
                    if (++g_iPage > g_iNumberOfPages)
                    {
                        g_iPage = 0;
                    }
                }
                else if (sMsg == "◄")
                {
                    if (--g_iPage < 0)
                    {
                        g_iPage = g_iNumberOfPages;
                    }
                }
                else if (!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_loaded"))
                {
                     llOwnerSay("Please load an animation set first.");
                }
                else
                {
                    llOwnerSay("Could not find animation set: "+sMsg);
                }
                MenuLoad(kID,g_iPage,iAuth);
            }
            /*else if( sMenu == "Menu~Swim")
            {
                if (sMsg == UPMENU)
                {
                    iRespring = FALSE;
                    Menu(kID, iAuth);
                }
                else if (sMsg == b_sFloat)
                {
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_floats",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_floats")));
                }
                if(iRespring)
                {
                    MenuSwim(kID, iAuth);
                }
            }*/
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
                else if (sMsg == "Print Memory")
                {
                    llOwnerSay("Requestiong Memory");
                    llMessageLinked(LINK_SET,0,"memory_print",(string)kID);
                }
                else if (sMsg == "Print LSD")
                {
                    list lLSD = llListSort(llLinksetDataListKeys(0,llLinksetDataCountKeys()-1),1,TRUE);
                    integer iIndex = 0;
                    string sKey;
                    for(iIndex = 0; iIndex < llGetListLength(lLSD); iIndex++)
                    {
                        sKey = llList2String(lLSD,iIndex);
                        llInstantMessage(kID,sKey+"="+llLinksetDataRead(sKey));
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
                    //llOwnerSay("online status changed to "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_online"));
                    //Link("offline", 0, "", llGetOwnerKey((key)llLinksetDataRead(l_sCollar)));
                    //llLinksetDataDelete(l_sCollar);
                    //llLinksetDataDelete(l_sCollarName);
                }
                else if (sMsg == "CONNECT")
                {
                    iRespring = FALSE;
                    // if the collar disconects but is available we want the user to be able to connect it if they don't wish to safe word.
                    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_online",(string)TRUE);
                    //llOwnerSay("online status changed to "+llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_online"));
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
                        llOwnerSay("AO memory is being wiped and scripts being reset");
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
                Menu(kID,iNum);
            }
            else if(sMsg == "MenuAnims")
            {
                MenuAnims(kID,iNum);
            }
        }
    }

    linkset_data(integer iAction,string sName,string sVal)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
            else if(sName == llToLower(llLinksetDataRead("addon_name"))+"_loaded" && (integer)sVal)
            {
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_power",(string)TRUE);
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }
}
