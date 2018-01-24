// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Jessenia Mocha, Alexei Maven.  Wendy Starfall,
// littlemousy, Romka Swallowtail, Garvin Twine et al. 
// Licensed under the GPLv2.  See LICENSE for full details. 


string g_sDevStage = "dev1";
string g_sVersion = "2.0";
integer g_iUpdateAvailable;
key g_kWebLookup;

integer g_iInterfaceChannel = -12587429;
integer g_iHUDChannel = -1812221819;

key g_kWearer;
string g_sCard = "Girl";
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

//ao functions

SetAnimOverride() {
    if (llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        llResetAnimationOverride("ALL");
        integer i = 22; //llGetListLength(g_lAnimStates);
        string sAnim;
        string sAnimState;
        do {
            sAnimState = llList2String(g_lAnimStates,i);
            if (~llSubStringIndex(g_sJson_Anims,sAnimState)) {
                sAnim = llJsonGetValue(g_sJson_Anims,[sAnimState]);
                if (JsonValid(sAnim)) {
                    if (sAnimState == "Walking" && g_sWalkAnim != "")
                        sAnim = g_sWalkAnim;
                    else if (sAnimState == "Sitting" && !g_iSitAnimOn) jump next;
                    else if (sAnimState == "Sitting" && g_sSitAnim != "" && g_iSitAnimOn)
                        sAnim = g_sSitAnim;
                    else if (sAnimState == "Sitting on Ground" && g_sSitAnywhereAnim != "")
                        sAnim = g_sSitAnywhereAnim;
                    else if (sAnimState == "Standing")
                        sAnim = llList2String(llParseString2List(sAnim, ["|"],[]),0);
                    if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
                        llSetAnimationOverride(sAnimState, sAnim);
                    else llOwnerSay(sAnim+" could not be found.");
                    @next;
                }
            }
        } while (i--);
        llSetTimerEvent(g_iChangeInterval);
        if (!g_iStandPause) llRegionSayTo(g_kWearer,g_iHUDChannel,(string)g_kWearer+":antislide off ao");
        //llOwnerSay("AO ready ("+(string)llGetFreeMemory()+" bytes free memory)");
    }
}

SwitchStand() {
    if (g_iStandPause) return;
    if (llGetPermissions() & PERMISSION_OVERRIDE_ANIMATIONS) {
        string sCurAnim = llGetAnimationOverride("Standing");
        list lAnims = llParseString2List(llJsonGetValue(g_sJson_Anims,["Standing"]),["|"],[]);
        integer index;
        if (g_iShuffle) index = (integer)llFrand(llGetListLength(lAnims));
        else {
            index = llListFindList(lAnims,[sCurAnim]);
            if (index == llGetListLength(lAnims)-1) index = 0;
            else index += 1;
        }
        if (g_iReady) llSetAnimationOverride("Standing",llList2String(lAnims,index));
    }
}

ToggleSitAnywhere() {
    if (!g_iAO_ON) llOwnerSay("SitAnywhere is not possible while the AO is turned off.");
    else if (g_iStandPause)
        llOwnerSay("SitAnywhere is not possible while you are in a collar pose.");
    else {
        if (g_iSitAnywhereOn) {
            llSetTimerEvent(g_iChangeInterval);
            SwitchStand();
        } else {
            llSetTimerEvent(0.0);
            llSetAnimationOverride("Standing",g_sSitAnywhereAnim);
        }
        g_iSitAnywhereOn = !g_iSitAnywhereOn;
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

//menus

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, string sName) {
    integer iChannel = llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenuIDs, [iChannel]))
        iChannel = llRound(llFrand(10000000)) + 100000;
    integer iListener = llListen(iChannel, "",kID, "");
    integer iTime = llGetUnixTime() + 180;
    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs,[kID, iChannel, iListener, iTime, sName],iIndex,iIndex+4);
    else g_lMenuIDs += [kID, iChannel, iListener, iTime, sName];
    if (!g_iAO_ON || !g_iChangeInterval) llSetTimerEvent(20);
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

MenuAO(key kID) {
    string sPrompt = "\n[OpenCollar AO]\t"+g_sVersion+g_sDevStage;
    if (g_iUpdateAvailable) sPrompt+= "\n\nUPDATE AVAILABLE: A new patch has been released.\nPlease install at your earliest convenience. Thanks!";
    list lButtons = ["LOCK"];
    if (g_iLocked) lButtons = ["UNLOCK"];
    if (kID == g_kWearer) lButtons += "Collar Menu";
    else lButtons += "-";
    lButtons += ["Load","Sits","Ground Sits","Walks"];
    if (g_iSitAnimOn) lButtons += ["Sits ☑"];
    else lButtons += ["Sits ☐"];
    if (g_iShuffle) lButtons += "Shuffle ☑";
    else lButtons += "Shuffle ☐";
    lButtons += ["Stand Time","Next Stand"];
    if (kID == g_kWearer) lButtons += "HUD Style";
    Dialog(kID, sPrompt, lButtons, ["Cancel"], "AO");
}

MenuLoad(key kID, integer iPage) {
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
    Dialog(kID, sPrompt, lButtons, lStaticButtons,"Load");
}

MenuInterval(key kID) {
    string sInterval = "won't change automatically.";
    if (g_iChangeInterval) sInterval = "change every "+(string)g_iChangeInterval+" seconds.";
    Dialog(kID, "\nStands " +sInterval, ["Never","20","30","45","60","90","120","180"], ["BACK"],"Interval");
}

MenuChooseAnim(key kID, string sAnimState) {
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
    Dialog(kID, sPrompt, lButtons, ["BACK"],sAnimState);
}

MenuOptions(key kID) {
    Dialog(kID,"\nCustomize your AO!",["Horizontal","Vertical","Order"],["BACK"], "options");
}

OrderMenu(key kID) {
    string sPrompt = "\nWhich button do you want to re-order?";
    integer i;
    list lButtons;
    integer iPos;
    for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
        iPos = llList2Integer(g_lPrimOrder,i);
        lButtons += llList2List(g_lButtons,iPos,iPos);
    }
    Dialog(kID, sPrompt, lButtons, ["Reset","BACK"], "ordermenu");
}

//command handling

TranslateCollarCMD(string sCommand, key kID){
    if (!llSubStringIndex(sCommand,"ZHAO_")) {
        sCommand = llGetSubString(sCommand,5,-1);
        if (!~llSubStringIndex(sCommand,"load"))
            sCommand = llToLower(sCommand);
    } else return;
    if (!llSubStringIndex(sCommand,"stand")) {
        if (~llSubStringIndex(sCommand,"off")) {
            g_iStandPause = TRUE;
            if (llGetAnimationOverride("Standing") != "")
                llResetAnimationOverride("Standing");
            llResetAnimationOverride("Turning Left");
            llResetAnimationOverride("Turning Right");
            if (g_iSitAnywhereOn) {
                g_iSitAnywhereOn = FALSE;
                ShowStatus();
            }
        } else if (~llSubStringIndex(sCommand,"on")) {
            SetAnimOverride();
            g_iStandPause = FALSE;
        }
    } else if (~llSubStringIndex(sCommand,"menu")) {
            if (g_iReady) MenuAO(kID);
            else {
                Notify(kID,"Please load an animation set first.",TRUE);
                MenuLoad(kID,0);
            }
    } else if (!llSubStringIndex(sCommand,"ao"))
        Command(kID,llGetSubString(sCommand,2,-1));
}

Command(key kID, string sCommand) {
    list lParams = llParseString2List(sCommand,[" "],[]);
    sCommand = llList2String(lParams,0);
    string sValue = llList2String(lParams,1);
    if (!g_iReady) {
        Notify(kID,"Please load an animation set first.",TRUE);
        MenuLoad(kID,0);
        return;
    } else if (sCommand == "on") {
        SetAnimOverride();
        g_iAO_ON = TRUE;
        llSetTimerEvent(g_iChangeInterval);
        ShowStatus();
    } else if (sCommand == "off") {
        llResetAnimationOverride("ALL");
        g_iAO_ON = FALSE;
        llSetTimerEvent(0.0);
        ShowStatus();
    } else if (sCommand == "unlock") {
        g_iLocked = FALSE;
        llOwnerSay("@detach=y");
        llPlaySound("82fa6d06-b494-f97c-2908-84009380c8d1", 1.0);
        Notify(kID,"The AO has been unlocked.",TRUE);
    } else if (sCommand == "lock") {
        g_iLocked = TRUE;
        llOwnerSay("@detach=n");
        llPlaySound("dec9fb53-0fef-29ae-a21d-b3047525d312", 1.0);
        Notify(kID,"The AO has been locked.",TRUE);
    } else if (sCommand == "menu") MenuAO(kID);
    else if (sCommand == "load") {
        if (llGetInventoryType(sValue) == INVENTORY_NOTECARD) {
            g_sCard = sValue;
            g_iCardLine = 0;
            g_sJson_Anims = "{}";
            Notify(kID,"Loading animation set \""+g_sCard+"\".",TRUE);
            g_kCard = llGetNotecardLine(g_sCard, g_iCardLine);
        } else MenuLoad(kID,0);
    }
}

StartUpdate(key kID) {
    integer iPin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(iPin);
    llRegionSayTo(kID, -7483220, "ready|" + (string)iPin );
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


default {
    state_entry() {
        if (llGetInventoryType("oc_installer_sys")==INVENTORY_SCRIPT) return;
        g_kWearer = llGetOwner();
        PermsCheck();
        g_iInterfaceChannel = -llAbs((integer)("0x" + llGetSubString(g_kWearer,30,-1)));
        llListen(g_iInterfaceChannel, "", "", "");
        g_iHUDChannel = -llAbs((integer)("0x"+llGetSubString((string)llGetOwner(),-7,-1)));
        FindButtons();
        PositionButtons();
        TextureButtons();
        DetermineColors();
        MenuLoad(g_kWearer,0);
    }

    on_rez(integer iStart) {
        if (g_kWearer != llGetOwner()) llResetScript();
        if (g_iLocked) llOwnerSay("@detach=n");
        g_iReady = FALSE;
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/ao.txt", [HTTP_METHOD, "GET"],"");
        llRequestPermissions(g_kWearer,PERMISSION_OVERRIDE_ANIMATIONS);
    }

    attach(key kID) {
        if (kID == NULL_KEY) llResetAnimationOverride("ALL");
        else if (llGetAttached() <= 30) {
            llOwnerSay("Sorry, this device can only be attached to the HUD.");
            llRequestPermissions(kID, PERMISSION_ATTACH);
            llDetachFromAvatar();
        } else PositionButtons();
    }

    touch_start(integer total_number) {
        if(llGetAttached()) {
            if (!g_iReady) {
                MenuLoad(g_kWearer,0);
                llOwnerSay("Please load an animation set first.");
                return;
            }
            string sButton = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            if (sButton == "Menu")
                MenuAO(g_kWearer);
            else if (sButton == "SitAny") {
                ToggleSitAnywhere();
            } else if (llSubStringIndex(llToLower(sButton),"ao")>=0) {
                g_iHidden = !g_iHidden;
                PositionButtons();
            } else if (sButton == "Power") {
                if (g_iAO_ON) Command(g_kWearer,"off");
                else if (g_iReady) Command(g_kWearer,"on");
            }
        } else if (llDetectedKey(0) == g_kWearer) MenuAO(g_kWearer);
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iInterfaceChannel) {
            if (llGetOwnerKey(kID) != g_kWearer) return;
            if (sMessage == "-.. --- / .- ---") {
                StartUpdate(kID);
                return;
            } else if (!llGetAttached() && sMessage == "AO set installation") {
                sMessage = "";
                integer i = llGetInventoryNumber(INVENTORY_ANIMATION);
                while(i) {
                    sMessage += llGetInventoryName(INVENTORY_ANIMATION,--i);
                    if (llStringLength(sMessage) > 960) {
                        llRegionSayTo(kID,iChannel,sMessage);
                        sMessage = "";
                    }
                }
                llRegionSayTo(kID,iChannel,sMessage);
                llRegionSayTo(kID,iChannel,"@END");
                return;
            } //"CollarCommmand|499|ZHAO_STANDON" or "CollarCommmand|iAuth|ZHAO_MENU|commanderID"
            list lParams = llParseString2List(sMessage,["|"],[]);
            if (llList2String(lParams,0) == "CollarCommand") {
                if (llList2Integer(lParams,1) == 502)
                    Notify(llList2Key(lParams,3),"Access denied!",FALSE);
                else
                    TranslateCollarCMD(llList2String(lParams,2),llList2Key(lParams,3));
            }
        } else if (~llListFindList(g_lMenuIDs,[kID, iChannel])) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            string sMenuType = llList2String(g_lMenuIDs, iMenuIndex+4);
            llListenRemove(llList2Integer(g_lMenuIDs,iMenuIndex+2));
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs,iMenuIndex, iMenuIndex+4);
            if (llGetListLength(g_lMenuIDs) == 0 && (!g_iAO_ON || !g_iChangeInterval)) llSetTimerEvent(0.0);
            if (sMenuType == "AO") {
                if (sMessage == "Cancel") return;
                else if (sMessage == "-") MenuAO(kID);
                else if (sMessage == "Collar Menu") llRegionSayTo(g_kWearer,g_iHUDChannel,(string)g_kWearer+":menu");
                else if (~llSubStringIndex(sMessage,"LOCK")) {
                    Command(kID,llToLower(sMessage));
                    MenuAO(kID);
                } else if (sMessage == "HUD Style") MenuOptions(kID);
                else if (sMessage == "Load") MenuLoad(kID,0);
                else if (sMessage == "Sits") MenuChooseAnim(kID,"Sitting");
                else if (sMessage == "Walks") MenuChooseAnim(kID,"Walking");
                else if (sMessage == "Ground Sits") MenuChooseAnim(kID,"Sitting on Ground");
                else if (!llSubStringIndex(sMessage,"Sits")) {
                    if (~llSubStringIndex(sMessage,"☑")) {
                        g_iSitAnimOn = FALSE;
                        llResetAnimationOverride("Sitting");
                    } else if (g_sSitAnim != "") {
                        g_iSitAnimOn = TRUE;
                        if (g_iAO_ON) llSetAnimationOverride("Sitting",g_sSitAnim);
                    } else Notify(kID,"Sorry, the currently loaded animation set doesn't have any sits.",TRUE);
                    MenuAO(kID);
                } else if (sMessage == "Stand Time") MenuInterval(kID);
                else if (sMessage == "Next Stand") {
                    if (g_iAO_ON) SwitchStand();
                    MenuAO(kID);
                } else if (!llSubStringIndex(sMessage,"Shuffle")) {
                    if (~llSubStringIndex(sMessage,"☑")) g_iShuffle = FALSE;
                    else g_iShuffle = TRUE;
                    MenuAO(kID);
                }
            } else if (sMenuType == "Load") {
                integer index = llListFindList(g_lCustomCards,[sMessage]);
                if (~index) sMessage = llList2String(g_lCustomCards,index-1);
                if (llGetInventoryType(sMessage) == INVENTORY_NOTECARD) {
                    g_sCard = sMessage;
                    g_iCardLine = 0;
                    g_sJson_Anims = "{}";
                    g_kCard = llGetNotecardLine(g_sCard, g_iCardLine);
                    return;
                } else if (g_iReady && sMessage == "BACK") {
                    MenuAO(kID);
                    return;
                } else if (sMessage == "►") {
                    if (++g_iPage > g_iNumberOfPages) g_iPage = 0;
                } else if (sMessage == "◄") {
                    if (--g_iPage < 0) g_iPage = g_iNumberOfPages;
                } else if (!g_iReady) llOwnerSay("Please load an animation set first.");
                else llOwnerSay("Could not find animation set: "+sMessage);
                MenuLoad(kID,g_iPage);
            } else if (sMenuType == "Interval") {
                if (sMessage == "BACK") {
                    MenuAO(kID);
                    return;
                } else if (sMessage == "Never") {
                    g_iChangeInterval = FALSE;
                    llSetTimerEvent(g_iChangeInterval);
                } else if ((integer)sMessage >= 20) {
                    g_iChangeInterval = (integer)sMessage;
                    if (g_iAO_ON && !g_iSitAnywhereOn) llSetTimerEvent(g_iChangeInterval);
                }
                MenuInterval(kID);
            } else if (~llListFindList(["Walking","Sitting on Ground","Sitting"],[sMenuType])) {
                if (sMessage == "BACK") MenuAO(kID);
                else if (sMessage == "-") MenuChooseAnim(kID,sMenuType);
                else {
                    sMessage = llList2String(g_lAnims2Choose,((integer)sMessage)-1);
                    g_lAnims2Choose = [];
                    if (llGetInventoryType(sMessage) == INVENTORY_ANIMATION) {
                        if (sMenuType == "Sitting") g_sSitAnim = sMessage;
                        else if (sMenuType == "Sitting on Ground") g_sSitAnywhereAnim = sMessage;
                        else if (sMenuType == "Walking") g_sWalkAnim = sMessage;
                        if (g_iAO_ON && (sMenuType != "Sitting" || g_iSitAnimOn))
                            llSetAnimationOverride(sMenuType,sMessage);
                    } else llOwnerSay("No "+sMenuType+" animation set.");
                    MenuChooseAnim(kID,sMenuType);
                }
            } else if (sMenuType == "options") {
                if (sMessage == "BACK") {
                    MenuAO(kID);
                    return;
                } else if (sMessage == "Horizontal") {
                    g_iLayout = 0;
                    PositionButtons();
                } else if (sMessage == "Vertical") {
                    g_iLayout = 1;
                    PositionButtons();
                } else if (sMessage == "Order") {
                    OrderMenu(kID);
                    return;
                }
                MenuOptions(kID);
            } else if (sMenuType == "ordermenu") {
                if (sMessage == "BACK") MenuOptions(kID);
                else if (sMessage == "-") OrderMenu(kID);
                else if (sMessage == "Reset") {
                    FindButtons();
                    llOwnerSay("Order position reset to default.");
                    PositionButtons();
                    OrderMenu(kID);
                } else if (llSubStringIndex(sMessage,":") >= 0) {
                    DoButtonOrder(llList2Integer(llParseString2List(sMessage,[":"],[]),1));
                    OrderMenu(kID);
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
                    Dialog(kID, sPrompt, lButtons, ["BACK"],"ordermenu");
                }
            }
        }
    }

    timer() {
        if (g_iAO_ON && g_iChangeInterval) SwitchStand();
        integer n = llGetListLength(g_lMenuIDs) - 5;
        integer iNow = llGetUnixTime();
        for (n; n>=0; n=n-5) {
            integer iDieTime = llList2Integer(g_lMenuIDs,n+3);
            if (iNow > iDieTime) {
                llListenRemove(llList2Integer(g_lMenuIDs,n+2));
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs,n,n+4);
            }
        }
        if (!llGetListLength(g_lMenuIDs) && (!g_iAO_ON || !g_iChangeInterval)) llSetTimerEvent(0.0);
    }

    dataserver(key kRequest, string sData) {
        if (kRequest == g_kCard) {
            if (sData != EOF) {
                if (llGetSubString(sData,0,0) != "[") jump next;
                string sAnimationState = llStringTrim(llGetSubString(sData,1,llSubStringIndex(sData,"]")-1),STRING_TRIM);
                // Translate common ZHAOII, Oracul and AX anim state values
                if (sAnimationState == "Stand.1" || sAnimationState == "Stand.2" || sAnimationState == "Stand.3") sAnimationState = "Standing";
                else if (sAnimationState == "Walk.N") sAnimationState = "Walking";
                //else if (sAnimationState == "") sAnimationState = "Running";
                else if (sAnimationState == "Turn.L") sAnimationState = "Turning Left";
                else if (sAnimationState == "Turn.R") sAnimationState = "Turning Right";
                else if (sAnimationState == "Sit.N") sAnimationState = "Sitting";
                else if (sAnimationState == "Sit.G" || sAnimationState == "Sitting On Ground") sAnimationState = "Sitting on Ground";
                else if (sAnimationState == "Crouch") sAnimationState = "Crouching";
                else if (sAnimationState == "Walk.C" || sAnimationState == "Crouch Walking") sAnimationState = "CrouchWalking";
                else if (sAnimationState == "Jump.P" || sAnimationState == "Pre Jumping") sAnimationState = "PreJumping";
                else if (sAnimationState == "Jump.N") sAnimationState = "Jumping";
                //else if (sAnimationState == "") sAnimationState = "Soft Landing";
                //else if (sAnimationState == "") sAnimationState = "Taking Off";
                else if (sAnimationState == "Hover.N") sAnimationState = "Hovering";
                else if (sAnimationState == "Hover.U" || sAnimationState == "Flying Up") sAnimationState = "Hovering Up";
                else if (sAnimationState == "Hover.D" || sAnimationState == "Flying Down") sAnimationState = "Hovering Down";
                else if (sAnimationState == "Fly.N") sAnimationState = "Flying";
                else if (sAnimationState == "Flying Slow") sAnimationState = "FlyingSlow";
                else if (sAnimationState == "Land.N") sAnimationState = "Landing";
                else if (sAnimationState == "Falling") sAnimationState = "Falling Down";
                else if (sAnimationState == "Stand.U") sAnimationState = "Standing Up";
                //else if (sAnimationState == "") sAnimationState = "Striding";
                if (!~llListFindList(g_lAnimStates,[sAnimationState])) jump next;
                if (llStringLength(sData)-1 > llSubStringIndex(sData,"]")) {
                    sData = llGetSubString(sData,llSubStringIndex(sData,"]")+1,-1);
                    list lTemp = llParseString2List(sData, ["|",","],[]);
                    integer i = llGetListLength(lTemp);
                    while(i--) {
                        if (llGetInventoryType(llList2String(lTemp,i)) != INVENTORY_ANIMATION)
                            lTemp = llDeleteSubList(lTemp,i,i);
                    }
                    if (sAnimationState == "Sitting on Ground")
                        g_sSitAnywhereAnim = llList2String(lTemp,0);
                    else if (sAnimationState == "Sitting") {
                        g_sSitAnim = llList2String(lTemp,0);
                        if (g_sSitAnim != "") g_iSitAnimOn = TRUE;
                        else g_iSitAnimOn = FALSE;
                    } else if (sAnimationState == "Walking")
                        g_sWalkAnim = llList2String(lTemp,0);
                    else if (sAnimationState != "Standing") lTemp = llList2List(lTemp,0,0);
                    if (lTemp) g_sJson_Anims = llJsonSetValue(g_sJson_Anims, [sAnimationState],llDumpList2String(lTemp,"|"));
                }
                @next;
                g_kCard = llGetNotecardLine(g_sCard,++g_iCardLine);
            } else {
                g_iCardLine = 0;
                g_kCard = "";
                g_iSitAnywhereOn = FALSE;
                integer index = llListFindList(g_lCustomCards,[g_sCard]);
                if (~index) g_sCard = llList2String(g_lCustomCards,index+1)+" ("+g_sCard+")";
                g_lCustomCards = [];
                if (g_sJson_Anims == "{}") {
                    llOwnerSay("\""+g_sCard+"\" is an invalid animation set and can't play.");
                    g_iAO_ON = FALSE;
                } else {
                    llOwnerSay("The \""+g_sCard+"\" animation set was loaded successfully.");
                    g_iAO_ON = TRUE;
                }
                ShowStatus();
                llRequestPermissions(g_kWearer,PERMISSION_OVERRIDE_ANIMATIONS);
            }
        }
    }

    run_time_permissions(integer iFlag) {
        if (iFlag & PERMISSION_OVERRIDE_ANIMATIONS) {
            if (g_sJson_Anims != "{}") g_iReady = TRUE;
            else g_iReady =  FALSE;
            if (g_iAO_ON) SetAnimOverride();
            else llResetAnimationOverride("ALL");
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
        } else if (iChange & CHANGED_LINK) llResetScript();
        if (iChange & CHANGED_INVENTORY) PermsCheck();
    }
}
