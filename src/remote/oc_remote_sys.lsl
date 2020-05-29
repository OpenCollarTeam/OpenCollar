// This file is part of OpenCollar.
// Copyright (c) 2014 - 2016 Nandana Singh, Jessenia Mocha, Alexei Maven, 
// Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, 
// Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.  
// Licensed under the GPLv2.  See LICENSE for full details. 


//merged HUD-menu, HUD-leash and HUD-rezzer into here June 2015 Otto (garvin.twine)

string g_sDevStage="";
string g_sVersion = "1.6";
integer g_iUpdateAvailable;
key g_kWebLookup;

list g_lPartners;
list g_lNewPartnerIDs;
list g_lPartnersInSim;
string g_sActivePartnerID = "ALL"; //either an UUID or "ALL"

//  list of hud channel handles we are listening for, for building lists
list g_lListeners;

// Where I was last attached, to check for being moved to new point.
integer g_iLastAttached = -1;

string g_sMainMenu = "Main";

//  Notecard reading bits
string  g_sCard = ".partners";
key     g_kCardID = NULL_KEY;
key     g_kLineID;
integer g_iLineNr;

integer g_iListener;
integer g_iCmdListener;
integer g_iChannel = 7;

key g_kUpdater;
integer g_iUpdateChan = -7483210;

integer g_iPicturePrim;
key g_kPicRequest;
string g_sMetaFind = "<meta name=\"imageid\" content=\"";

//  MESSAGE MAP
integer MENUNAME_REQUEST     = 3000;
integer MENUNAME_RESPONSE    = 3001;
integer SUBMENU              = 3002;
integer ACC_CMD              = 7000;
integer DIALOG               = -9000;
integer DIALOG_RESPONSE      = -9001;
//integer DIALOG_TIMEOUT       = -9002;
integer CMD_REMOTE           = 10000;

string UPMENU          = "BACK";
string MENU_LIST_PARTNERS  = "List";
string MENU_REMOVE_PARTNER = "Remove";
string MENU_ALL_PARTNERS = "ALL";
string MENU_ADD_PARTNERS = "Add";
string MENU_LAYOUT = "Layout";
string MENU_ORDER = "Order";

list g_lMainMenuButtons = [" ◄ ",MENU_ALL_PARTNERS," ► ",MENU_ADD_PARTNERS, MENU_LIST_PARTNERS, MENU_REMOVE_PARTNER, "Collar Menu", "Rez", MENU_LAYOUT];
list g_lMenus = [];
key    g_kMenuID;
string g_sMenuType;

key    g_kRemovedPartnerID;
key    g_kOwner;

string  g_sRezObject;

// this texture is a spritemap with all buttons on it, for faster texture
// loading than having separate textures for each button.
string BTN_TEXTURE = "9cc45c63-647e-1287-fbc0-f2c7f41e5814";

// There are 3 columns of buttons and 8 rows of buttons in the sprite map.
integer BTN_XS = 3;
integer BTN_YS = 8;

// starting at the top left and moving to the right, the button sprites are in
// this order.
list BTNS = [
    "Minimize",
    "People",
    "Menu",
    "Couples",
    "Favorite",
    "Bookmarks",
    "Lock",
    "Outfits",
    "Folders",
    "Unleash",
    "Leash",
    "Yank",
    "Sit",
    "Stand",
    "Rez",
    "Pose",
    "Stop",
    "Hudmenu",
    "Person",
    "Restrictions",
    "Titler",
    "Detach",
    "Maximize"
];

list g_lAttachPoints = [
    ATTACH_HUD_TOP_RIGHT,
    ATTACH_HUD_TOP_CENTER,
    ATTACH_HUD_TOP_LEFT,
    ATTACH_HUD_BOTTOM_RIGHT,
    ATTACH_HUD_BOTTOM,
    ATTACH_HUD_BOTTOM_LEFT,
    ATTACH_HUD_CENTER_1,
    ATTACH_HUD_CENTER_2
    ];

float g_fGap = 0.001; // This is the space between buttons
float g_Yoff = 0.002; // space between buttons and screen top/bottom border
float g_Zoff = 0.04; // space between buttons and screen left/right border

integer g_iVertical = TRUE;  // can be vertical?
integer g_iLayout = 1; // 0 - Horisontal, 1 - Vertical
integer g_iHidden = FALSE;
integer g_iSPosition = 69; // Nuff'said =D

list g_lPrimOrder ;
integer g_iColumn = 1;  // 0 - Column, 1 - Alternate
integer g_iRows = 3;  // nummer of Rows: 1,2,3,4... up to g_iMaxRows
integer g_iMaxRows = 4; // maximal Rows in Columns
list g_lButtons ; // buttons names for Order menu

// for swapping buttons
integer g_iNewPos;
integer g_iOldPos;

string NameURI(string sID) {
    if ((key)sID)
        return "secondlife:///app/agent/"+sID+"/about";
    else return sID; //this way we can use the function also for "ALL" and dont need a special case for that everytime
}

integer PersonalChannel(string sID, integer iOffset) {
    integer iChan = -llAbs((integer)("0x"+llGetSubString(sID,-7,-1)) + iOffset);
    return iChan;
}

integer InSim(key kID) {
//  check if the AV is logged in and in Sim
    return (llGetAgentSize(kID) != ZERO_VECTOR);
}

list PartnersInSim() {
    list lTemp;
    integer i = llGetListLength(g_lPartners);
     while (i) {
        string sTemp = llList2String(g_lPartners,--i);
        if (InSim(sTemp))
            lTemp += sTemp;
    }
    return [MENU_ALL_PARTNERS]+lTemp;
}

SendCollarCommand(string sCmd) {
    g_lPartnersInSim = PartnersInSim();
    integer i = llGetListLength(g_lPartnersInSim);
    if (i > 1) {
        if ((key)g_sActivePartnerID) {
            if (!llSubStringIndex(sCmd,"acc-"))
                llMessageLinked(LINK_THIS,ACC_CMD,sCmd,g_sActivePartnerID);
            else
                llRegionSayTo(g_sActivePartnerID,PersonalChannel(g_sActivePartnerID,0), g_sActivePartnerID+":"+sCmd);
        } else if (g_sActivePartnerID == MENU_ALL_PARTNERS) {
            integer j = llGetListLength(g_lPartnersInSim);
             while (j > 1) { // g_lPartnersInSim has always one entry ["ALL"] do whom we dont want to send anything
                string sPartnerID = llList2String(g_lPartnersInSim,--j);
                if (!llSubStringIndex(sCmd,"acc-"))
                    llMessageLinked(LINK_THIS,ACC_CMD,sCmd,sPartnerID);
                else
                    llRegionSayTo(sPartnerID,PersonalChannel(sPartnerID,0),sPartnerID+":"+sCmd);
            }
        }
    } else llOwnerSay("None of your partners are in range.");
}

AddPartner(string sID) {
    if (~llListFindList(g_lPartners,[sID])) return;
    if ((key)sID != NULL_KEY) {//don't register any unrecognised
        g_lPartners+=[sID];//Well we got here so lets add them to the list.
        llOwnerSay("\n\n"+NameURI(sID)+" has been registered.\n");//Tell the owner we made it.
    }
}

RemovePartner(string sID) {
    integer index = llListFindList(g_lPartners,[sID]);
    if (~index) {
        g_lPartners=llDeleteSubList(g_lPartners,index,index);
        llOwnerSay(NameURI(sID)+" has been removed.");
        if (sID == g_sActivePartnerID) NextPartner(0,FALSE);
    }
}

Dialog(string sPrompt, list lChoices, list lUtilityButtons, integer iPage, string sMenuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET,DIALOG,(string)g_kOwner+"|"+sPrompt+"|"+(string)iPage+"|"+llDumpList2String(lChoices,"`")+"|"+llDumpList2String(lUtilityButtons,"`"),kID);
    g_kMenuID = kID;
    g_sMenuType = sMenuType;
}

MainMenu(){
    string sPrompt = "\n[OpenCollar Remote]\t"+g_sVersion+g_sDevStage;
    sPrompt += "\n\nSelected Partner: "+NameURI(g_sActivePartnerID);
    if (g_iUpdateAvailable) sPrompt += "\n\nUPDATE AVAILABLE: A new remote version is available";
    list lButtons = g_lMainMenuButtons + g_lMenus;
    Dialog(sPrompt, lButtons, [], 0, g_sMainMenu);
}

RezMenu() {
    Dialog("\nRez something!\n\nSelected Partner: "+NameURI(g_sActivePartnerID), BuildObjectList(),["BACK"],0,"RezzerMenu");
}

AddPartnerMenu() {
    string sPrompt = "\nWho would you like to add?\n";
    list lButtons;
    integer index;
    do {
        lButtons += llList2Key(g_lNewPartnerIDs,index);
    } while (++index < llGetListLength(g_lNewPartnerIDs));
    Dialog(sPrompt, lButtons, [MENU_ALL_PARTNERS,UPMENU], -1,"AddPartnerMenu");
}

StartUpdate() {
    integer pin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(g_kUpdater, g_iUpdateChan, "ready|" + (string)pin );
}

list BuildObjectList() {
    list lRezObjects;
    integer i;
    do lRezObjects += llGetInventoryName(INVENTORY_OBJECT,i);
    while (++i < llGetInventoryNumber(INVENTORY_OBJECT));
    return lRezObjects;
}

NextPartner(integer iDirection, integer iTouch) {
    g_lPartnersInSim = PartnersInSim();
    if ((llGetListLength(g_lPartnersInSim) > 1) && iDirection) {
        integer index = llListFindList(g_lPartnersInSim,[g_sActivePartnerID])+iDirection;
        if (index >= llGetListLength(g_lPartnersInSim)) index = 0;
        else if (index < 0) index = llGetListLength(g_lPartnersInSim)-1;
        g_sActivePartnerID = llList2String(g_lPartnersInSim,index);
    } else g_sActivePartnerID = MENU_ALL_PARTNERS;
    if ((key)g_sActivePartnerID)
        g_kPicRequest = llHTTPRequest("http://world.secondlife.com/resident/"+g_sActivePartnerID,[HTTP_METHOD,"GET"],"");
    else if (g_sActivePartnerID == MENU_ALL_PARTNERS)
        if (g_iPicturePrim) SetButtonTexture(g_iPicturePrim, "People");
    if(iTouch) {
        if (llGetListLength(g_lPartnersInSim) < 2) llOwnerSay("There is nobody nearby at the moment.");
        else llOwnerSay("\n\nSelected Partner: "+NameURI(g_sActivePartnerID)+"\n");
    }
}

integer PicturePrim() {
    integer i = llGetNumberOfPrims();
    do {
        if (~llSubStringIndex((string)llGetLinkPrimitiveParams(i, [PRIM_DESC]),"Picture"))
            return i;
    } while (--i>1);
    return 0;
}

PermsCheck() {
    string sName = llGetScriptName();
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY)) {
        llOwnerSay("You have been given a no-modify OpenCollar object.  This could break future updates.  Please ask the provider to make the object modifiable.");
    }

    if (!(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)) {
        llOwnerSay("You have put an OpenCollar script into an object that the next user cannot modify.  This could break future updates.  Please leave your OpenCollar objects modifiable.");
    }

    integer FULL_PERMS = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    if (!((llGetInventoryPermMask(sName,MASK_OWNER) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("The " + sName + " script is not mod/copy/trans.  This is a violation of the OpenCollar license.  Please ask the person who gave you this script for a full-perms replacement.");
    }

    if (!((llGetInventoryPermMask(sName,MASK_NEXT) & FULL_PERMS) == FULL_PERMS)) {
        llOwnerSay("You have removed mod/copy/trans permissions for the next owner of the " + sName + " script.  This is a violation of the OpenCollar license.  Please make the script full perms again.");
    }
}

SetButtonTexture(integer link, string name) {
    integer idx = llListFindList(BTNS, [name]);
    if (idx == -1) return;
    integer x = idx % BTN_XS;
    integer y = idx / BTN_XS;
    vector scale = <1.0 / BTN_XS, 1.0 / BTN_YS, 0>;
    vector offset = <
        scale.x * (x - (BTN_XS / 2.0 - 0.5)), 
        scale.y * -1 * (y - (BTN_YS / 2.0 - 0.5)),
    0>;
    llSetLinkPrimitiveParamsFast(link, [
        PRIM_TEXTURE,
            ALL_SIDES,
            BTN_TEXTURE,
            scale,
            offset,
            0 
    ]);   
}

TextureButtons() {
    integer i = llGetNumberOfPrims();

    while (i) {
        string name = llGetLinkName(i);
        if (i == 1) {
            if (g_iHidden) {
                name = "Maximize";
            } else {
                name = "Minimize";
            }
        }
        
        SetButtonTexture(i, name);
        i--;
    }
}

PositionButtons() {
    integer iPosition = llListFindList(g_lAttachPoints, [llGetAttached()]);
    vector size = llGetScale();
//  Allows manual repositioning, without resetting it, if needed
    if (iPosition != g_iSPosition && iPosition != -1) { //do this only when attached to the hud
        vector offset = <0, size.y/2+g_Yoff, size.z/2+g_Zoff>;
        if (iPosition==0||iPosition==1||iPosition==2) offset.z = -offset.z;
        if (iPosition==2||iPosition==5) offset.y = -offset.y;
        if (iPosition==1||iPosition==4) { g_iLayout = 0; g_iVertical = FALSE;}
        else { g_iLayout = 1; g_iVertical = TRUE; }
        llSetPos(offset); // Position the Root Prim on screen
        g_iSPosition = iPosition;
    }
    if (g_iHidden) { // -- Fixes Issue 615: HUD forgets hide setting on relog.
        SetButtonTexture(1, "Maximize");
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION, <1.0, 0.0, 0.0>]);
    } else {
        SetButtonTexture(1, "Minimize");
        float fYoff = size.y + g_fGap; float fZoff = size.z + g_fGap; // This is the space between buttons
        if (iPosition == 0 || iPosition == 1 || iPosition == 2) fZoff = -fZoff;
        if (iPosition == 1 || iPosition == 2 || iPosition == 4 || iPosition == 5) fYoff = -fYoff;
        list lPrimOrder = llDeleteSubList(g_lPrimOrder, 0, 0);
        integer n = llGetListLength(lPrimOrder);
        vector pos ;
        integer i;
        float fXoff = 0.01; // small X offset
        for (i=1; i < n; ++i) {
            if (g_iColumn == 0) { // Column
                if (!g_iLayout) pos = <fXoff, fYoff*(i-(i/(n/g_iRows))*(n/g_iRows)), fZoff*(i/(n/g_iRows))>;
                else pos = <fXoff, fYoff*(i/(n/g_iRows)), fZoff*(i-(i/(n/g_iRows))*(n/g_iRows))>;
            } else if (g_iColumn == 1) { // Alternate
                if (!g_iLayout) pos = <fXoff, fYoff*(i/g_iRows), fZoff*(i-(i/g_iRows)*g_iRows)>;
                else  pos = <fXoff, fYoff*(i-(i/g_iRows)*g_iRows), fZoff*(i/g_iRows)>;
            }
            llSetLinkPrimitiveParamsFast(llList2Integer(lPrimOrder,i),[PRIM_POSITION,pos]);
        }
    }
}

FindButtons() { // collect buttons names & links
    g_lButtons = [" ", "Minimize"] ; // 'Minimize' need for texture
    g_lPrimOrder = [0, 1];  //  '1' - root prim
    integer i;
    for (i=2; i<llGetNumberOfPrims()+1; ++i) {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_NAME]);
        g_lPrimOrder += i;
    }
    g_iMaxRows = llFloor(llSqrt(llGetListLength(g_lButtons)-1));
}

LayoutMenu() {
    string sPrompt = "\nCustomize your Remote!";
    list lButtons = ["Rows: "+(string)g_iRows] ;
    if (g_iRows > 1) lButtons += llList2List(["Columns >","Alternate >"], g_iColumn, g_iColumn) ;
    else lButtons += [" - "] ;
    if (g_iVertical) lButtons += llList2List(["Horizontal >","Vertical >"], g_iLayout,g_iLayout) ;
    else lButtons += [" - "] ;
    lButtons += [MENU_ORDER,"Reset"];
    Dialog(sPrompt, lButtons, [UPMENU], 0, MENU_LAYOUT);
}

OrderMenu() {
    list lButtons = [];
    string sPrompt = "\nThis is the order menu, simply select the\n";
    sPrompt += "button which you want to re-order.\n\n";
    integer i;
    for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
        integer pos = llList2Integer(g_lPrimOrder,i);
        lButtons += llList2List(g_lButtons,pos,pos);
    }
    Dialog(sPrompt, lButtons, ["Reset",UPMENU], 0, "Order");
}

DoButtonOrder() {   // -- Set the button order and reset display
    integer iOldPos = llList2Integer(g_lPrimOrder,g_iOldPos);
    integer iNewPos = llList2Integer(g_lPrimOrder,g_iNewPos);
    integer i = 2;
    list lTemp = [0,1];
    for(;i<llGetListLength(g_lPrimOrder);++i) {
        integer iTempPos = llList2Integer(g_lPrimOrder,i);
        if (iTempPos == iOldPos) lTemp += [iNewPos];
        else if (iTempPos == iNewPos) lTemp += [iOldPos];
        else lTemp += [iTempPos];
    }
    g_lPrimOrder = lTemp;
    g_iOldPos = -1;
    g_iNewPos = -1;
    PositionButtons();
}

NewButtonPositionMenu(string sButton)
{
    list lButtons;
    string sPrompt;
    integer iTemp = llListFindList(g_lButtons,[sButton]);
    g_iOldPos = llListFindList(g_lPrimOrder, [iTemp]);

    sPrompt = "\nSelect the new position for swap with "+sButton+"\n\n";
    integer i;
    for(i=2;i<llGetListLength(g_lPrimOrder);++i) {
        if (g_iOldPos != i) {
            lButtons +=[llList2String(g_lButtons,llList2Integer(g_lPrimOrder,i))+":"+(string)i];
        }
    }
    Dialog(sPrompt, lButtons, [UPMENU], 0, "Order");
}



default {
    state_entry() {
        g_kOwner = llGetOwner();
        PermsCheck();
        FindButtons(); // collect buttons names
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/remote.txt", [HTTP_METHOD, "GET"],"");
        llSleep(1.0);//giving time for others to reset before populating menu
        if (llGetInventoryKey(g_sCard)) {
            g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
            g_kCardID = llGetInventoryKey(g_sCard);
        }
        g_iListener=llListen(PersonalChannel(g_kOwner,0),"","",""); //lets listen here
        g_iCmdListener = llListen(g_iChannel,"",g_kOwner,"");
        llMessageLinked(LINK_SET,MENUNAME_REQUEST, g_sMainMenu,"");
        g_iPicturePrim = PicturePrim();
        TextureButtons();
        SetButtonTexture(3, "Menu");
        NextPartner(0,0);
        MainMenu();
        llOwnerSay("\n\nYou are wearing this OpenCollar Remote for the first time. I'm opening the remote menu where you can manage your partners. Make sure that your partners are near you and click Add to register them. To open the remote menu again, please select the gear (⚙) icon on your remote HUD.\n");
    }

    on_rez(integer iStart) {
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/remote.txt", [HTTP_METHOD, "GET"],"");
        // check if repositioning needed
        if (g_iLastAttached != llGetAttached())
        {
            g_iLastAttached = llGetAttached();
            PositionButtons();
        }
    }

    touch_start(integer iNum) {
        if (llGetAttached() && (llDetectedKey(0)==g_kOwner)) {// Dont do anything if not attached to the HUD
//          I made the root prim the "menu" prim, and the button action default to "menu."
            string sButton = llList2String(llGetLinkPrimitiveParams(llDetectedLinkNumber(0),[PRIM_DESC]),0);
            if (~llSubStringIndex(sButton,"remote")) {
                g_iHidden = !g_iHidden;
                PositionButtons();
            }
            else if (sButton == "hudmenu") MainMenu();
            else if (sButton == "rez") RezMenu();
            else if (~llSubStringIndex(sButton,"picture")) NextPartner(1,TRUE);
            else if (sButton == "bookmarks") llMessageLinked(LINK_THIS,0,"bookmarks menu","");
            else if (sButton == "tp save") llMessageLinked(LINK_THIS,0,sButton,"");
            else SendCollarCommand(sButton);
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChannel) {
            list lParams = llParseString2List(sMessage, [" "], []);
            string sCmd = llList2String(lParams,0);
            if (sMessage == "menu")
                MainMenu();
            else if (sCmd == "channel") {
                integer iNewChannel = (integer)llList2String(lParams,1);
                if (iNewChannel) {
                    g_iChannel = iNewChannel;
                    llListenRemove(g_iCmdListener);
                    g_iCmdListener = llListen(g_iChannel,"",g_kOwner,"");
                    llOwnerSay("Your new HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
                } else llOwnerSay("Your HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
            }
            else if (llToLower(sMessage) == "help")
                llOwnerSay("\n\nThe manual page can be found [here].\n");
            else if (sMessage == "reset") llResetScript();
        } else if (iChannel == PersonalChannel(g_kOwner,0) && llGetOwnerKey(kID) == g_kOwner) {
            if (sMessage == "-.. --- / .... ..- -..") {
                g_kUpdater = kID;
                Dialog("\nINSTALLATION REQUEST PENDING:\n\nAn update or app installer is requesting permission to continue. Installation progress can be observed above the installer box and it will also tell you when it's done.\n\nShall we continue and start with the installation?", ["Yes","No"], ["Cancel"], 0, "UpdateConfirmMenu");
            }
        } else if (llGetSubString(sMessage, 36, 40)==":pong") {
            if (!~llListFindList(g_lNewPartnerIDs, [llGetOwnerKey(kID)]) && !~llListFindList(g_lPartners, [(string)llGetOwnerKey(kID)]))
                g_lNewPartnerIDs += [llGetOwnerKey(kID)];
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams,0) == g_sMainMenu) {
                string sChild = llList2String(lParams,1);
                if (! ~llListFindList(g_lMenus, [sChild]))
                    g_lMenus = llListSort(g_lMenus+=[sChild], 1, TRUE);
            }
            lParams = [];
        } else if (iNum == SUBMENU && sStr == "Main") MainMenu();
        else if (iNum == CMD_REMOTE) SendCollarCommand(sStr);
        else if (iNum == DIALOG_RESPONSE && kID == g_kMenuID) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sMessage = llList2String(lParams, 1);
            integer i;
            if (g_sMenuType == "Main") {
                if (sMessage == "Collar Menu") SendCollarCommand("menu");
                else if (sMessage == "Rez")
                    RezMenu();
                else if (sMessage == MENU_REMOVE_PARTNER)
                    Dialog("\nWho would you like to remove?\n", g_lPartners, [UPMENU], -1,"RemovePartnerMenu");
                else if (sMessage == MENU_LIST_PARTNERS) {
                    string sText ="\n\nI'm currently managing: ";
                    integer iPartnerCount = llGetListLength(g_lPartners);
                    if (iPartnerCount) {
                        i=0;
                        do {
                            if (llStringLength(sText)>950) {
                                llOwnerSay(sText);
                                sText ="";
                            }
                            sText += NameURI(llList2Key(g_lPartners,i))+", " ;
                        } while (++i < iPartnerCount-1);
                        if (iPartnerCount>1)sText += " and "+NameURI(llList2Key(g_lPartners,i));
                        if (iPartnerCount == 1) sText = llGetSubString(sText,0,-3);
                    } else sText += "nobody :(";
                    llOwnerSay(sText);
                    MainMenu();
                } else if (sMessage == MENU_ADD_PARTNERS) {
                     // Ping for auth OpenCollars in the parcel
                     list lAgents = llGetAgentList(AGENT_LIST_PARCEL, []); //scan for who is in the parcel
                     llOwnerSay("Scanning for collar access....");
                     integer iChannel;
                     i =  llGetListLength(lAgents);
                     do {
                        kID = llList2Key(lAgents,--i);
                        if (kID != g_kOwner && !~llListFindList(g_lPartners,[(string)kID])) {
                            if (llGetListLength(g_lListeners) < 60) {//Only 65 listens can simultaneously be open in any single script (SL wiki)
                                iChannel = PersonalChannel(kID,0);
                                g_lListeners += [llListen(iChannel, "", "", "" )] ;
                                llRegionSayTo(kID, iChannel, (string)kID+":ping");
                            } else i=0;
                        }
                    } while (i);
                    llSetTimerEvent(2.0);
                } else if (sMessage == " ◄ ") {
                    NextPartner(-1,FALSE);
                    MainMenu();
                } else if (sMessage == " ► ") {
                    NextPartner(1,FALSE);
                    MainMenu();
                } else if (sMessage == MENU_ALL_PARTNERS) {
                    g_sActivePartnerID = MENU_ALL_PARTNERS;
                    NextPartner(0,FALSE);
                    MainMenu();
                } else if (sMessage == MENU_LAYOUT) {
                    LayoutMenu(); 
                } else if (~llListFindList(g_lMenus,[sMessage])) llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
            } else if (g_sMenuType == "RemovePartnerMenu") {
                integer index = llListFindList(g_lPartners, [sMessage]);
                if (sMessage == UPMENU) MainMenu();
                else if (sMessage == "Yes") {
                    RemovePartner(g_kRemovedPartnerID);
                    MainMenu();
                } else if (sMessage == "No") MainMenu();
                else if (~index) {
                    g_kRemovedPartnerID = (key)llList2String(g_lPartners, index);
                    Dialog("\nAre you sure you want to remove "+NameURI(g_kRemovedPartnerID)+"?", ["Yes", "No"], [UPMENU], 0,"RemovePartnerMenu");
                }
            } else if (g_sMenuType == "UpdateConfirmMenu") {
                if (sMessage=="Yes") StartUpdate();
                else {
                    llOwnerSay("Installation cancelled.");
                    return;
                }
            } else if (g_sMenuType == "RezzerMenu") {
                if (sMessage == UPMENU) MainMenu();
                else {
                    g_sRezObject = sMessage;
                    if (llGetInventoryType(g_sRezObject) == INVENTORY_OBJECT) {
                        vector myPos = llGetPos();
                        rotation myRot = llGetRot();
                 
                        // [23:06:21] nirea: is there something special about the startparam 10 in your changes, Taylor?
                        // [23:06:42] Taylor Paine: no, I just like it.
                        // [23:06:47] nirea: good enough :)
                        llRezObject(
                            g_sRezObject,
                            myPos + <2,0,-0.5>*myRot,
                            <0,0,0>,
                            <0,180,0,180>*myRot,
                            10
                        );
                    }
                }
            } else if (g_sMenuType == "AddPartnerMenu") {
                if (sMessage == MENU_ALL_PARTNERS) {
                    i = llGetListLength(g_lNewPartnerIDs);
                    key kNewPartnerID;
                    do {
                        kNewPartnerID = llList2Key(g_lNewPartnerIDs,--i);
                        if (kNewPartnerID) AddPartner(kNewPartnerID);
                    } while (i);
                } else if ((key)sMessage)
                    AddPartner(sMessage);
                g_lNewPartnerIDs = [];
                MainMenu();
            } else if (g_sMenuType == "Layout") {
                if (sMessage == UPMENU) {
                    MainMenu();
                } else if (sMessage == "Reset") {
                    // set all variables that TextureButtons relies on back to defaults.
                    g_iLayout = 1;
                    g_iColumn = 1;
                    g_iRows = 3;
                    PositionButtons();
                    TextureButtons();
                    LayoutMenu();                    
                } else if (sMessage == "Order") {
                    OrderMenu();
                } else if (sMessage == "Horizontal >" || sMessage == "Vertical >") {
                    g_iLayout = !g_iLayout;
                    PositionButtons();
                    LayoutMenu();
                }
                else if (sMessage == "Columns >" || sMessage == "Alternate >") {
                    g_iColumn = !g_iColumn;
                    PositionButtons();
                    LayoutMenu();
                }
                else if (llSubStringIndex(sMessage,"Rows")==0) {
                    // this feature is not mandatory, it just passes uneven rows.
                    // for the simple can use only g_iRows++;
                    integer n = llGetListLength(g_lPrimOrder)-1;
                    do {
                        g_iRows++;
                    } while ((n/g_iRows)*(n/(n/g_iRows)) != n);
                    //
                    if (g_iRows > g_iMaxRows) g_iRows = 1;
                    PositionButtons();
                    LayoutMenu();
                }
            } else if (g_sMenuType == "Order") {
                if (sMessage == UPMENU) {
                    LayoutMenu();
                } else if (sMessage == "Reset") {
                    FindButtons();
                    llOwnerSay("Order position reset to default.");
                    PositionButtons();
                } else if (llSubStringIndex(sMessage,":") >= 0) { // Jess's nifty parsing trick for the menus
                    g_iNewPos = llList2Integer(llParseString2List(sMessage,[":"],[]),1);
                    DoButtonOrder();
                } else {
                    NewButtonPositionMenu(sMessage);
                    return;
                }
            }
        }
    }

    timer() {
        if (llGetListLength(g_lNewPartnerIDs)) AddPartnerMenu();
        else llOwnerSay("\n\nYou currently don't have access to any nearby collars. Requirements to add partners are to either have them captured or their collar is set to public or they have you listed as an owner or trust role.\n");
        llSetTimerEvent(0);
        integer n = llGetListLength(g_lListeners);
        while (n--)
            llListenRemove(llList2Integer(g_lListeners,n));
        g_lListeners = [];
    }

    dataserver(key kRequestID, string sData) {
        if (kRequestID == g_kLineID) {
            if (sData == EOF) { //  notify the owner
                //llOwnerSay(g_sCard+" card loaded.");
                return;
            } else if ((key)sData) // valid lines contain only a valid UUID which is a key
                AddPartner(sData);
            g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);
        }
    }

    http_response(key kRequestID, integer iStatus, list lMeta, string sBody) {
        if (kRequestID == g_kWebLookup && iStatus == 200)  {
            if ((float)sBody > (float)g_sVersion) g_iUpdateAvailable = TRUE;
            else g_iUpdateAvailable = FALSE;
        } else if (kRequestID == g_kPicRequest) {
            integer iMetaPos =  llSubStringIndex(sBody, g_sMetaFind) + llStringLength(g_sMetaFind);
            string sTexture  = llGetSubString(sBody, iMetaPos, iMetaPos + 35);
            if ((key)sTexture == NULL_KEY) {
                SetButtonTexture(g_iPicturePrim, "Person");
            } else if (g_iPicturePrim) {
                llSetLinkPrimitiveParamsFast(g_iPicturePrim,[PRIM_TEXTURE, ALL_SIDES, sTexture,<1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
            }
        }
    }

    object_rez(key kID) {
        llSleep(0.5); // make sure object is rezzed and listens
        if (g_sActivePartnerID == MENU_ALL_PARTNERS)
            llRegionSayTo(kID,PersonalChannel(g_kOwner,1234),llDumpList2String(llDeleteSubList(PartnersInSim(),0,0),","));
        else
            llRegionSayTo(kID,PersonalChannel(g_kOwner,1234),g_sActivePartnerID);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(g_sCard) != g_kCardID) {
                // the .partners card changed.  Re-read it.
                g_iLineNr = 0;
                if (llGetInventoryKey(g_sCard)) {
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    g_kCardID = llGetInventoryKey(g_sCard);
                }
            }
        }
        if (iChange & CHANGED_OWNER) llResetScript();
        if (iChange & CHANGED_INVENTORY) PermsCheck();
    }
}
