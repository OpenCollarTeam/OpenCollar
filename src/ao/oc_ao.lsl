// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Jessenia Mocha, Alexei Maven.  Wendy Starfall,
// littlemousy, Romka Swallowtail, Garvin Twine et al.
// Licensed under the GPLv2.  See LICENSE for full details.
/*-Authors Attribution-
Taya Maruti - (May 2021)
*/

integer API_CHANNEL = 0x60b97b5e;

//list g_lCollars;
string g_sAddon = "AO";

//integer CMD_ZERO            = 0;
integer CMD_OWNER           = 500;
integer CMD_TRUSTED         = 501;
integer CMD_GROUP           = 502;
integer CMD_WEARER          = 503;
integer CMD_EVERYONE        = 504;
//integer CMD_BLOCKED         = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY       = 507;
//integer CMD_SAFEWORD        = 510;
//integer CMD_RELAY_SAFEWORD  = 511;
//integer CMD_NOACCESS        = 599;

//integer LM_SETTING_SAVE     = 2000; //scripts send messages on this channel to have settings saved, <string> must be in form of "token=value"
integer LM_SETTING_REQUEST  = 2001; //when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002; //the settings script sends responses on this channel
//integer LM_SETTING_DELETE   = 2003; //delete token from settings
//integer LM_SETTING_EMPTY    = 2004; //sent when a token has no value

integer DIALOG          = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT  = -9002;

//------------------------------------//
integer AO_SETTINGS=40500;
integer AO_SETOVERRIDE=40501;
integer AO_GETOVERRIDE=40502;
integer AO_GIVEOVERRIDE=40503;
integer AO_NOTECARD = 40504;
integer AO_STATUS = 40505;
integer AO_ANTISLIDE=40506;
//------------------------------------//
list g_lOptedLM     = [];
integer g_iMenuStride;

string UPMENU = "BACK";
integer g_iLockAuth=504;

string g_sDevStage = "";
string g_sVersion = "2.2";
integer g_iUpdateAvailable;
key g_kWebLookup;

key g_kWearer;
string g_sCard = "default";
integer g_iCardLine;
key g_kCard;
integer g_iReady;

list g_lAnimStates = [ //http://wiki.secondlife.com/wiki/LlSetAnimationOverride
        "Crouching","CrouchWalking","Falling Down","Flying","FlyingSlow",
        "Hovering","Hovering Down","Hovering Up","Jumping","Landing",
        "PreJumping","Running","Standing","Sitting","Sitting on Ground","Standing Up",
        "Striding","Soft Landing","Taking Off","Turning Left","Turning Right","Walking"
        ];

string g_sJson_Anims = "{}";
integer g_iAO_ON;
integer g_iSitAnimOn;
string g_sSitAnim;
integer g_iSitAnywhereOn;
string g_sSitAnywhereAnim;
string g_sWalkAnim;
integer g_iChangeInterval = 45;
integer g_iLocked;
integer g_iShuffle;
integer g_iStandPause;

list g_lMenuIDs;
list g_lAnims2Choose;
list g_lCustomCards;
integer g_iPage;
integer g_iNumberOfPages;
key g_kCollar=NULL_KEY;
integer g_iLMLastRecv;
integer g_iLMLastSent;
/*
Debug(string sStr) {
    llScriptProfiler(1);
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

//options



// this texture is a spritemap with all buttons on it, for faster texture
// loading than having separate textures for each button.
string BTN_TEXTURE = "fb9a678d-c692-400e-e08c-9e0e85503925";

// There are 3 columns of buttons and 8 rows of buttons in the sprite map.
integer BTN_XS = 3;
integer BTN_YS = 2;

// starting at the top left and moving to the right, the button sprites are in
// this order.
list BTNS = [
    "Minimize",
    "Maximize",
    "Power",
    "Menu",
    "SitAny"
];

float g_fGap = 0.001; // This is the space between buttons
float g_Yoff = 0.002; // space between buttons and screen top/bottom border
float g_Zoff = 0.04; // space between buttons and screen left/right border

list g_lButtons ; // buttons names for Order menu
list g_lPrimOrder = [0,1,2,3,4]; // -- List must always start with '0','1'
// -- 0:Spacer, 1:Root, 2:Power, 3:Sit Anywhere, 4:Menu
// -- Spacer serves to even up the list with actual link numbers

integer g_iLayout = 1;
integer g_iHidden = FALSE;
integer g_iPosition = 69;
integer g_iOldPos;

vector g_vAOoffcolor = <0.5,0.5,0.5>;
vector g_vAOoncolor = <1,1,1>;

integer JsonValid(string sTest) {
    if (~llSubStringIndex(JSON_FALSE+JSON_INVALID+JSON_NULL,sTest))
        return FALSE;
    return TRUE;
}

FindButtons() { // collect buttons names & links
    g_lButtons = [" ", "Minimize"] ;
    g_lPrimOrder = [0, 1];  //  '1' - root prim
    integer i;
    for (i=2; i<=llGetNumberOfPrims(); ++i) {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_DESC]);
        g_lPrimOrder += i;
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
    integer iPosition = llGetAttached();
    vector vSize = llGetScale();
//  Allows manual repositioning, without resetting it, if needed
    if (iPosition != g_iPosition && iPosition > 30) { //do this only when attached to the hud
        vector vOffset = <0.01, vSize.y/2+g_Yoff, vSize.z/2+g_Zoff>;
        if (iPosition == ATTACH_HUD_TOP_RIGHT || iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_LEFT) vOffset.z = -vOffset.z;
        if (iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_BOTTOM_LEFT) vOffset.y = -vOffset.y;
        llSetPos(vOffset); // Position the Root Prim on screen
        g_iPosition = iPosition;
    }
    if (g_iHidden) {
        SetButtonTexture(1, "Maximize");
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION,<1,0,0>]);
    } else {
        SetButtonTexture(1, "Minimize");
        float fYoff = vSize.y + g_fGap;
        float fZoff = vSize.z + g_fGap;
        if (iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_RIGHT)
            fZoff = -fZoff;
        if (iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_BOTTOM || iPosition == ATTACH_HUD_BOTTOM_LEFT)
            fYoff = -fYoff;
        if (iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_BOTTOM) g_iLayout = 0;
        if (g_iLayout) fYoff = 0;
        else fZoff = 0;
        integer i;
        integer LinkCount=llGetListLength(g_lPrimOrder);
        for (i=2;i<=LinkCount;++i) {
            llSetLinkPrimitiveParamsFast(llList2Integer(g_lPrimOrder,i),[PRIM_POSITION,<0.01, fYoff*(i-1), fZoff*(i-1)>]);
        }
    }
}

DoButtonOrder(integer iNewPos) {   // -- Set the button order and reset display
    integer iOldPos = llList2Integer(g_lPrimOrder,g_iOldPos);
    iNewPos = llList2Integer(g_lPrimOrder,iNewPos);
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
    PositionButtons();
}

DetermineColors() {
    g_vAOoncolor = llGetColor(0);
    g_vAOoffcolor = g_vAOoncolor/2;
    ShowStatus();
}

ShowStatus() {
    vector vColor = g_vAOoffcolor;
    if (g_iAO_ON) vColor = g_vAOoncolor;
    llSetLinkColor(llListFindList(g_lButtons,["Power"]), vColor, ALL_SIDES);
    if (g_iSitAnywhereOn) vColor = g_vAOoncolor;
    else vColor = g_vAOoffcolor;
    llSetLinkColor(llListFindList(g_lButtons,["SitAny"]), vColor, ALL_SIDES);
}

ToggleSitAnywhere() {
    if (!g_iAO_ON) llOwnerSay("SitAnywhere is not possible while the AO is turned off.");
    else if (g_iStandPause)
        llOwnerSay("SitAnywhere is not possible while you are in a collar pose.");
    else {
        if (g_iSitAnywhereOn) {
            llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"switchstand",llGetOwner());
        } else {
            llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"set:Standing="+g_sSitAnywhereAnim,llGetOwner());
        }
        g_iSitAnywhereOn = !g_iSitAnywhereOn;
        llMessageLinked(LINK_THIS,AO_SETTINGS,"iSitAnywhereOn="+(string)g_iSitAnywhereOn,llGetOwner());
        ShowStatus();
    }
}

Notify(key kID, string sStr, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sStr);
    else {
        llRegionSayTo(kID,0,sStr);
        if (iAlsoNotifyWearer) llOwnerSay(sStr);
    }
}
 
//menus integer iPage,
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iAuth, string sName) {
    integer iChannel = llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenuIDs, [iChannel]))
        iChannel = llRound(llFrand(10000000)) + 100000;
    integer iListener = llListen(iChannel, "",kID, "");
    integer iTime = llGetUnixTime() + 180;
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs,[kID, iChannel, iListener, iTime, sName, iAuth],iIndex,iIndex+4);
    else g_lMenuIDs += [kID, iChannel, iListener, iTime, sName,iAuth];
   // if (!g_iAO_ON || !g_iChangeInterval) llSetTimerEvent(20);
    llDialog(kID,sPrompt,SortButtons(lChoices,lUtilityButtons),iChannel);
}

list SortButtons(list lButtons, list lStaticButtons) {
    list lSpacers;
    list lAllButtons = lButtons + lStaticButtons;
    //cutting off too many buttons, no multi page menus as of now
    while (llGetListLength(lAllButtons)>12) {
        lButtons = llDeleteSubList(lButtons,0,0);
        lAllButtons = lButtons + lStaticButtons;
    }
    while (llGetListLength(lAllButtons) % 3 != 0 && llGetListLength(lAllButtons) < 12) {
        lSpacers += "-";
        lAllButtons = lButtons + lSpacers + lStaticButtons;
    }
    integer i = llListFindList(lAllButtons, ["BACK"]);
    if (~i) lAllButtons = llDeleteSubList(lAllButtons, i, i);
    list lOut = llList2List(lAllButtons, 9, 11);
    lOut += llList2List(lAllButtons, 6, 8);
    lOut += llList2List(lAllButtons, 3, 5);
    lOut += llList2List(lAllButtons, 0, 2);
    if (~i) lOut = llListInsertList(lOut, ["BACK"], 2);
    return lOut;
}

MenuAO(key kID,integer iAuth) {
    string sPrompt = "\n[OpenCollar AO]\t"+g_sVersion+g_sDevStage;
    if (g_iUpdateAvailable) sPrompt+= "\n\nUPDATE AVAILABLE: A new patch has been released.\nPlease install at your earliest convenience. Thanks!";
    list lButtons = ["Load","Sits","Ground Sits","Walks"];
    if (g_iSitAnimOn) lButtons += ["Sits ☑"];
    else lButtons += ["Sits ☐"];
    if (g_iShuffle) lButtons += "Shuffle ☑";
    else lButtons += "Shuffle ☐";
    lButtons += ["Stand Time","Next Stand","Admin Menu"];
    if (kID == g_kWearer) lButtons += "HUD Style";
    Dialog(kID, sPrompt, lButtons, ["Cancel"], iAuth, "AO");
}

MenuAdmin(key kID,integer iAuth) {
    string sPrompt = "\n[OpenCollar AO]\t"+g_sVersion+g_sDevStage;
    list lButtons = ["LOCK"];
    if (g_iLocked) lButtons = ["UNLOCK"];
    else lButtons += "-";
    if (g_kCollar != NULL_KEY) lButtons += ["Collar Menu","DISCONNECT"];
    Dialog(kID, sPrompt, lButtons, ["Cancel","BACK"], iAuth, "Admin");
}

MenuLoad(key kID, integer iPage,integer iAuth) {
    if (!iPage) g_iPage = 0;
    string sPrompt = "\nLoad an animation set!";
    list lButtons;
    g_lCustomCards = [];
    integer iEnd = llGetInventoryNumber(INVENTORY_NOTECARD);
    integer iCountCustomCards;
    string sNotecardName;
    integer i;
    while (i < iEnd) {
        sNotecardName = llGetInventoryName(INVENTORY_NOTECARD, i++);
        if (llSubStringIndex(sNotecardName,".") && sNotecardName != "") {
            if (!llSubStringIndex(sNotecardName,"SET"))
                g_lCustomCards += [sNotecardName,"Wildcard "+(string)(++iCountCustomCards)];// + g_lCustomCards;
            else if(llStringLength(sNotecardName) < 24) lButtons += sNotecardName;
            else llOwnerSay(sNotecardName+"'s name is too long to be displayed in menus and cannot be used.");
        }
    }
    i = 1;
    while (i <= 2*iCountCustomCards) {
        lButtons += llList2List(g_lCustomCards,i,i);
        i += 2;
    }
    list lStaticButtons = ["BACK"];
    if (llGetListLength(lButtons) > 11) {
        lStaticButtons = ["◄","►","BACK"];
        g_iNumberOfPages = llGetListLength(lButtons)/9;
        lButtons = llList2List(lButtons,iPage*9,iPage*9+8);
    }
    if (!llGetListLength(lButtons)) llOwnerSay("There aren't any animation sets installed!");
    Dialog(kID, sPrompt, lButtons, lStaticButtons,iAuth,"Load");
}

MenuInterval(key kID,integer iAuth) {
    string sInterval = "won't change automatically.";
    if (g_iChangeInterval) sInterval = "change every "+(string)g_iChangeInterval+" seconds.";
    Dialog(kID, "\nStands " +sInterval, ["Never","20","30","45","60","90","120","180"], ["BACK"],iAuth,"Interval");
}

MenuChooseAnim(key kID, string sAnimState, integer iAuth) {
    string sAnim = g_sSitAnywhereAnim;
    if (sAnimState == "Walking") sAnim = g_sWalkAnim;
    else if (sAnimState == "Sitting") sAnim = g_sSitAnim;
    string sPrompt = "\n"+sAnimState+": \""+sAnim+"\"\n";
    g_lAnims2Choose = llListSort(llParseString2List(llJsonGetValue(g_sJson_Anims,[sAnimState]),["|"],[]),1,TRUE);
    list lButtons;
    integer iEnd = llGetListLength(g_lAnims2Choose);
    integer i;
    while (++i<=iEnd) {
        lButtons += (string)i;
        sPrompt += "\n"+(string)i+": "+llList2String(g_lAnims2Choose,i-1);
    }
    Dialog(kID, sPrompt, lButtons, ["BACK"],iAuth,sAnimState);
}

MenuOptions(key kID,integer iAuth) {
    Dialog(kID,"\nCustomize your AO!",["Horizontal","Vertical","Order"],["BACK"],iAuth, "options");
}

OrderMenu(key kID,integer iAuth) {
    string sPrompt = "\nWhich button do you want to re-order?";
    integer i;
    list lButtons;
    integer iPos;
    for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
        iPos = llList2Integer(g_lPrimOrder,i);
        lButtons += llList2List(g_lButtons,iPos,iPos);
    }
    Dialog(kID, sPrompt, lButtons, ["Reset","BACK"],iAuth, "ordermenu");
}

//command handling

Command(key kID, string sCommand,integer iNum) {
    //llOwnerSay("first check:"+sCommand+"from:"+(string)iNum);
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) {
        if(iNum == AO_SETOVERRIDE){
            if (sCommand == "on") {
                g_iAO_ON = TRUE;
                llMessageLinked(LINK_THIS,AO_SETTINGS,"iAO_ON="+(string)g_iAO_ON,kID);
                llMessageLinked(LINK_THIS,AO_SETTINGS,"start",kID);
                ShowStatus();
            } else if (sCommand == "off") {
                g_iAO_ON = FALSE;
                llMessageLinked(LINK_THIS,AO_SETTINGS,"iAO_ON="+(string)g_iAO_ON,kID);
                llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"RESET:ALL",kID);
                //llResetAnimationOverride("ALL");
                ShowStatus();
            } else {
                return;
            }
        }
        else {
            return;
        }
    }
    if (llSubStringIndex(llToLower(sCommand), llToLower(g_sAddon)) && llToLower(sCommand) != "menu " + llToLower(g_sAddon)) return;
    if (iNum == CMD_OWNER && llToLower(sCommand) == "runaway") {
        llOwnerSay("run away!");
        Command(kID,g_sAddon+"unlock",iNum);
        return;
    }

    if (llToLower(sCommand) == llToLower(g_sAddon) || llToLower(sCommand) == "menu "+llToLower(g_sAddon))
    {
        llOwnerSay("spawn Menu!");
        MenuAO(kID, iNum);
    }// else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) Notify(kID,"Access denied!",TRUE);
    else
    {
        //integer iWSuccess   = 0;
        //string sChangetype  = llList2String(llParseString2List(sCommand, [" "], []),0);
        //string sChangevalue = llList2String(llParseString2List(sCommand, [" "], []),1);
        //string sText;
        list lParams = llParseString2List(sCommand,[" "],[g_sAddon]);
        sCommand = llList2String(lParams,1);
        string sValue = llList2String(lParams,2);
        if (!g_iReady) {
            Notify(kID,"Please load an animation set first.",TRUE);
            MenuLoad(kID,0,iNum);
            return;
        } else if (sCommand == "on") {
            g_iAO_ON = TRUE;
            llMessageLinked(LINK_THIS,AO_SETTINGS,"iAO_ON="+(string)g_iAO_ON,kID);
            llMessageLinked(LINK_THIS,AO_SETTINGS,"start",kID);
            ShowStatus();
        } else if (sCommand == "off") {
            g_iAO_ON = FALSE;
            llMessageLinked(LINK_THIS,AO_SETTINGS,"iAO_ON="+(string)g_iAO_ON,kID);
            llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"RESET:ALL",kID);
            //llResetAnimationOverride("ALL");
            ShowStatus();
        } else if (sCommand == "unlock"){
            if( iNum <= g_iLockAuth){
                g_iLocked = FALSE;
                llOwnerSay("@detach=y");
                llPlaySound("82fa6d06-b494-f97c-2908-84009380c8d1", 1.0);
                Notify(kID,"The AO has been unlocked.",TRUE);
            } else Notify(kID,"Sorry Authorization denied!",TRUE);
        } else if (sCommand == "lock" ){
            if( iNum <= g_iLockAuth) {
                g_iLockAuth = iNum;
                g_iLocked = TRUE;
                llOwnerSay("@detach=n");
                llPlaySound("dec9fb53-0fef-29ae-a21d-b3047525d312", 1.0);
                Notify(kID,"The AO has been locked.",TRUE);
            }else Notify(kID,"Sorry Authorization denied!",TRUE);
        } else if (sCommand == "menu") MenuAO(kID,iNum);
        else if (sCommand == "load") {
            if (llGetInventoryType(sValue) == INVENTORY_NOTECARD) {
                g_sCard = sValue;
                g_iCardLine = 0;
                g_sJson_Anims = "{}";
                Notify(kID,"Loading animation set \""+g_sCard+"\".",TRUE);
                llMessageLinked(LINK_THIS,AO_NOTECARD,g_sCard+"|"+(string)g_iCardLine,kID);
            } else MenuLoad(kID,0,iNum);
        }
    }
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


Link(string packet, integer iNum, string sStr, key kID){
    list packet_data = [ "pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID ];

    if (packet == "online" || packet == "update") // only add optin if packet type is online or update
    {
        llListInsertList(packet_data, [ "optin", llDumpList2String(g_lOptedLM, "~") ], -1);
    }

    string pkt = llList2Json(JSON_OBJECT, packet_data);
    if (g_kCollar != "" && g_kCollar != NULL_KEY)
    {
        llRegionSayTo(g_kCollar, API_CHANNEL, pkt);
    }
    else
    {
        llRegionSay(API_CHANNEL, pkt);
    }
}

initialize(){
    if (llGetInventoryType("oc_installer_sys")==INVENTORY_SCRIPT) return;
    g_kWearer = llGetOwner();
    PermsCheck();
    API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
    llListen(API_CHANNEL, "", "", "");
    FindButtons();
    PositionButtons();
    TextureButtons();
    DetermineColors();
    //g_kCard = llGetNotecardLine(g_sCard, g_iCardLine);
    llMessageLinked(LINK_THIS,AO_NOTECARD,g_sCard+"|"+(string)g_iCardLine,g_kWearer);
    Link("online", 0, "", llGetOwner()); // This is the signal to initiate communication between the addon and the collar
    llSetTimerEvent(5);
    g_iLMLastRecv = llGetUnixTime();
}

softreset(){
    g_kCollar = NULL_KEY;
    API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
    llListen(API_CHANNEL, "", "", "");
    Link("online", 0, "", llGetOwner()); // This is the signal to initiate communication between the addon and the collar
    g_iLMLastRecv = llGetUnixTime();
    FindButtons();
    PositionButtons();
    TextureButtons();
    DetermineColors();
}

shutdown(){
    Link("offline", 0, "", llGetOwnerKey(g_kCollar));
    g_lMenuIDs = [];
    g_kCollar = NULL_KEY;
}

default {
    state_entry() {
        initialize();
        //MenuLoad(g_kWearer,0,CMD_WEARER);
    }

    on_rez(integer iStart) {
        if (g_kWearer != llGetOwner()) llResetScript();
        if (g_iLocked) llOwnerSay("@detach=n");
        g_iReady = FALSE;
        llMessageLinked(LINK_THIS,AO_SETTINGS,"UPDATE",g_kWearer);
        llMessageLinked(LINK_THIS,AO_GETOVERRIDE,"all",g_kWearer);
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/ao.txt", [HTTP_METHOD, "GET"],"");
        //llRequestPermissions(g_kWearer,PERMISSION_OVERRIDE_ANIMATIONS);
    }

    attach(key kID) {
        if (kID == NULL_KEY) llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"RESET_ALL",kID);//llResetAnimationOverride("ALL");
        else if (llGetAttached() <= 30) {
            llOwnerSay("Sorry, this device can only be attached to the HUD.");
            llRequestPermissions(kID, PERMISSION_ATTACH);
            llDetachFromAvatar();
        } else {
            PositionButtons();
            llMessageLinked(LINK_THIS,AO_GETOVERRIDE,"all",g_kWearer);
            llMessageLinked(LINK_THIS,AO_SETTINGS,"UPDATE",g_kWearer);
        }
    }

    touch_start(integer total_number) {
        if(llGetAttached()) {
            if (!g_iReady) {
                //MenuLoad(g_kWearer,0,CMD_WEARER);
                //llOwnerSay("Please load an animation set first.");
                llOwnerSay("system not loaded yet!");
                return;
            }
            string sButton = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            if (sButton == "Menu")
                MenuAO(g_kWearer,CMD_WEARER);
            else if (sButton == "SitAny") {
                ToggleSitAnywhere();
            } else if (llSubStringIndex(llToLower(sButton),"ao")>=0) {
                g_iHidden = !g_iHidden;
                PositionButtons();
            } else if (sButton == "Power") {
                if (g_iAO_ON) Command(g_kWearer,g_sAddon+"off",CMD_WEARER);
                else if (g_iReady) Command(g_kWearer,g_sAddon+"on",CMD_WEARER);
            }
        } else if (llDetectedKey(0) == g_kWearer) MenuAO(g_kWearer,CMD_WEARER);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if( iNum == AO_STATUS ){
            //llOwnerSay(sStr);
            list lPar     = llParseString2List(sStr, [":","="], []);
            string sToken  = llList2String(lPar, 0);
            string sVar   = llList2String(lPar, 1);
            string sVal   = llList2String(lPar, 2);
            if(sToken == "UPDATE"){
                if( sVar == "iSitAnimOn"){
                    g_iSitAnimOn = (integer)sVal;
                }
                else if( sVar == "sWalkAnim"){
                    g_sWalkAnim = sVal;
                }
                else if( sVar == "sSitAnim"){
                    g_sSitAnim = sVal;
                }
                else if( sVar == "iSitAnywhereOn"){
                    g_iSitAnywhereOn = (integer)sVal;
                }
                else if( sVar == "sSitAnywhereAnim"){
                    g_sSitAnywhereAnim = sVal;
                }
                else if(sVar == "iAOOn"){
                    g_iAO_ON = (integer)sVal;
                }
                ShowStatus();
            }
        }
        if( iNum == AO_GIVEOVERRIDE){
            if(JsonValid(sStr)){
                g_iReady = TRUE;
                g_sJson_Anims=sStr;
            }
            else {
                g_iReady = FALSE;
                llOwnerSay("Json not valid!");
            }
            ShowStatus();
        }
        if( iNum == AO_ANTISLIDE){
            llMessageLinked(LINK_THIS,AO_ANTISLIDE,"AOantislide off",g_kWearer);
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if(JsonValid(sMessage)){
            string sPacketType = llJsonGetValue(sMessage, ["pkt_type"]);
            if (sPacketType == "approved" && g_kCollar == NULL_KEY)
            {
                // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
                g_kCollar = kID;
                g_iLMLastRecv = llGetUnixTime();
                Link("from_addon", LM_SETTING_REQUEST, "ALL", "");
            }
            else if (sPacketType == "dc" && g_kCollar == kID)
            {
                softreset();
            }
            else if (sPacketType == "pong" && g_kCollar == kID)
            {
                g_iLMLastRecv = llGetUnixTime();
            }   
            else if(sPacketType == "from_collar")
            {
                // process link message if in range of addon
                if (llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]), 0)) <= 10.0)
                {
                    integer iNum = (integer) llJsonGetValue(sMessage, ["iNum"]);
                    string sStr  = llJsonGetValue(sMessage, ["sMsg"]);
                    key kID      = (key) llJsonGetValue(sMessage, ["kID"]);
                    if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
                    {
                        Command(kID, sStr, iNum);
                    }
                    else if ( iNum == AO_SETOVERRIDE){
                        Command(kID, sStr, iNum);
                    }
                }
            }
        }
        if (~llListFindList(g_lMenuIDs,[kID, iChannel])) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            integer iAuth = llList2Integer(g_lMenuIDs,iMenuIndex+5);
            string sMenuType = llList2String(g_lMenuIDs, iMenuIndex+4);
            llListenRemove(llList2Integer(g_lMenuIDs,iMenuIndex+2));
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs,iMenuIndex, iMenuIndex+4);
            //if (llGetListLength(g_lMenuIDs) == 0 && (!g_iAO_ON || !g_iChangeInterval)) llSetTimerEvent(0.0);
            if (sMenuType == "AO") {
                if (sMessage == "Cancel") return;
                else if (sMessage == "-") MenuAO(kID,iAuth);
                else if (sMessage == "Admin Menu") MenuAdmin(kID,iAuth);
                else if (sMessage == "HUD Style") MenuOptions(kID,iAuth);
                else if (sMessage == "Load") MenuLoad(kID,0,iAuth);
                else if (sMessage == "Sits") MenuChooseAnim(kID,"Sitting",iAuth);
                else if (sMessage == "Walks") MenuChooseAnim(kID,"Walking",iAuth);
                else if (sMessage == "Ground Sits") MenuChooseAnim(kID,"Sitting on Ground",iAuth);
                else if (!llSubStringIndex(sMessage,"Sits")) {
                    if (~llSubStringIndex(sMessage,"☑")) {
                        g_iSitAnimOn = FALSE;
                        llMessageLinked(LINK_THIS,AO_SETTINGS,"iSitAnimOn="+(string)g_iSitAnimOn,kID);
                        llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"RESET:Sitting",kID);
                    } else if (g_sSitAnim != "") {
                        g_iSitAnimOn = TRUE;
                        if (g_iAO_ON) llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"set:Sitting="+g_sSitAnim,kID);
                    } else Notify(kID,"Sorry, the currently loaded animation set doesn't have any sits.",TRUE);
                    MenuAO(kID,iAuth);
                } else if (sMessage == "Stand Time") MenuInterval(kID,iAuth);
                else if (sMessage == "Next Stand") {
                    if (g_iAO_ON) llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"switchstand",llGetOwner());
                    MenuAO(kID,iAuth);
                } else if (!llSubStringIndex(sMessage,"Shuffle")) {
                    if (~llSubStringIndex(sMessage,"☑")) g_iShuffle = FALSE;
                    else g_iShuffle = TRUE;
                    llMessageLinked(LINK_THIS,AO_SETTINGS,"iShuffle="+(string)g_iShuffle,kID);
                    MenuAO(kID,iAuth);
                }
            } else if (sMenuType == "Load") {
                integer index = llListFindList(g_lCustomCards,[sMessage]);
                if (~index) sMessage = llList2String(g_lCustomCards,index-1);
                if (llGetInventoryType(sMessage) == INVENTORY_NOTECARD) {
                    g_sCard = sMessage;
                    g_iCardLine = 0;
                    g_sJson_Anims = "{}";
                    llMessageLinked(LINK_THIS,AO_NOTECARD,g_sCard+"|"+(string)g_iCardLine,kID);
                    return;
                } else if (g_iReady && sMessage == "BACK") {
                    MenuAO(kID,iAuth);
                    return;
                } else if (sMessage == "►") {
                    if (++g_iPage > g_iNumberOfPages) g_iPage = 0;
                } else if (sMessage == "◄") {
                    if (--g_iPage < 0) g_iPage = g_iNumberOfPages;
                } else if (!g_iReady) llOwnerSay("Please load an animation set first.");
                else llOwnerSay("Could not find animation set: "+sMessage);
                MenuLoad(kID,g_iPage,iAuth);
            } else if (sMenuType == "Interval") {
                if (sMessage == "BACK") {
                    MenuAO(kID,iAuth);
                    return;
                } else if (sMessage == "Never") {
                    g_iChangeInterval = FALSE;
                    llMessageLinked(LINK_THIS,AO_SETTINGS,"iChangeInterval="+(string)g_iChangeInterval,kID);
                } else if ((integer)sMessage >= 20) {
                    g_iChangeInterval = (integer)sMessage;
                    if (g_iAO_ON && !g_iSitAnywhereOn) llMessageLinked(LINK_THIS,AO_SETTINGS,"iChangeInterval="+(string)g_iChangeInterval,kID); 
                }
                MenuInterval(kID,iAuth);
            } else if (~llListFindList(["Walking","Sitting on Ground","Sitting"],[sMenuType])) {
                if (sMessage == "BACK") MenuAO(kID,iAuth);
                else if (sMessage == "-") MenuChooseAnim(kID,sMenuType,iAuth);
                else {
                    sMessage = llList2String(g_lAnims2Choose,((integer)sMessage)-1);
                    g_lAnims2Choose = [];
                    if (llGetInventoryType(sMessage) == INVENTORY_ANIMATION) {
                        if (sMenuType == "Sitting") {
                            g_sSitAnim = sMessage;
                            llMessageLinked(LINK_THIS,AO_SETTINGS,"sSitAnim="+g_sSitAnim,kID);
                        }
                        else if (sMenuType == "Sitting on Ground") {
                            g_sSitAnywhereAnim = sMessage;
                            llMessageLinked(LINK_THIS,AO_SETTINGS,"sSitAnywhereAnim="+g_sSitAnywhereAnim,kID);
                        }
                        else if (sMenuType == "Walking"){
                            g_sWalkAnim = sMessage;
                            llMessageLinked(LINK_THIS,AO_SETTINGS,"sWalkAnim="+g_sWalkAnim,kID);
                            
                        }
                        if (g_iAO_ON && (sMenuType != "Sitting" || g_iSitAnimOn)) llMessageLinked(LINK_THIS,AO_SETOVERRIDE,"set:"+sMenuType+"="+sMessage,kID);
                    } else llOwnerSay("No "+sMenuType+" animation set.");
                    MenuChooseAnim(kID,sMenuType,iAuth);
                }
            } else if (sMenuType == "options") {
                if (sMessage == "BACK") {
                    MenuAO(kID,iAuth);
                    return;
                } else if (sMessage == "Horizontal") {
                    g_iLayout = 0;
                    PositionButtons();
                } else if (sMessage == "Vertical") {
                    g_iLayout = 1;
                    PositionButtons();
                } else if (sMessage == "Order") {
                    OrderMenu(kID,iAuth);
                    return;
                }
                MenuOptions(kID,iAuth);
            } else if (sMenuType == "ordermenu") {
                if (sMessage == "BACK") MenuOptions(kID,iAuth);
                else if (sMessage == "-") OrderMenu(kID,iAuth);
                else if (sMessage == "Reset") {
                    FindButtons();
                    llOwnerSay("Order position reset to default.");
                    PositionButtons();
                    OrderMenu(kID,iAuth);
                } else if (llSubStringIndex(sMessage,":") >= 0) {
                    DoButtonOrder(llList2Integer(llParseString2List(sMessage,[":"],[]),1));
                    OrderMenu(kID,iAuth);
                } else {
                    list lButtons;
                    string sPrompt;
                    integer iTemp = llListFindList(g_lButtons,[sMessage]);
                    g_iOldPos = llListFindList(g_lPrimOrder, [iTemp]);
                    sPrompt = "\nWhich slot do you want to swap for the "+sMessage+" button.";
                    integer i;
                    for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
                        if (g_iOldPos != i) {
                            lButtons +=[llList2String(g_lButtons,llList2Integer(g_lPrimOrder,i))+":"+(string)i];
                        }
                    }
                    Dialog(kID, sPrompt, lButtons, ["BACK"],iAuth,"ordermenu");
                }
            } else if (sMenuType == "Admin") {
                if (sMessage == "Cancel") return;
                else if (sMessage == "Collar Menu") Link("from_addon",iAuth,"menu ",kID);
                else if (~llSubStringIndex(sMessage,"LOCK")) {
                    Command(kID,g_sAddon+llToLower(sMessage),iAuth);
                    MenuAdmin(kID,iAuth);
                } else if( sMessage == "DISCONNECT" ) shutdown();
                else if (sMessage == "BACK") MenuAO(kID,iAuth);
            }  
        }
    }

    timer() {
        if (llGetUnixTime() >= (g_iLMLastSent + 30))
        {
            g_iLMLastSent = llGetUnixTime();
            Link("ping", 0, "", g_kCollar);
        }

        if (llGetUnixTime() > (g_iLMLastRecv + (5 * 60)) && g_kCollar != NULL_KEY)
        {
            softreset();
        }

        if (g_kCollar == NULL_KEY) Link("online", 0, "", llGetOwner());
        integer n = llGetListLength(g_lMenuIDs)-6;
        integer iNow = llGetUnixTime();
        for (n; n>=0; n=n-6) {
            integer iDieTime = llList2Integer(g_lMenuIDs,n+3);
            if (iNow > iDieTime) {
                llListenRemove(llList2Integer(g_lMenuIDs,n+2));
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs,n,n+4);
            }
        }
    }

    http_response(key kRequestID, integer iStatus, list lMeta, string sBody) {
        if (kRequestID == g_kWebLookup && iStatus == 200)  {
            if ((float)sBody > (float)g_sVersion) g_iUpdateAvailable = TRUE;
            else g_iUpdateAvailable = FALSE;
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_COLOR) {
            if (llGetColor(0) != g_vAOoncolor) DetermineColors();
        } else if (iChange & CHANGED_LINK) initialize();
        if (iChange & CHANGED_INVENTORY) {
            llMessageLinked(LINK_THIS,AO_NOTECARD,g_sCard+"|"+(string)g_iCardLine,g_kWearer);
            softreset();
            PermsCheck();
        }
    }
}
