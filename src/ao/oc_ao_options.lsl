//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//        AO Options - 160120.1          .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Wendy Starfall, littlemousy, Romka Swallowtail, Garvin Twine et al.     //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//           github.com/OpenCollar/opencollar/tree/master/src/ao            //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// -- HUD Message Map
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//Added for the collar auth system:
integer CMD_NOAUTH = 0;
integer CMD_AUTH = 42; //used to send authenticated commands to be executed in the core script
//integer CMD_COLLAR = 499; //added for collar or cuff commands to put ao to pause or standOff and SAFEWORD
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer COLLAR_INT_REQ = 610;
//integer COLLAR_INT_REP = 611;
//integer CMD_UPDATE = 10001;
integer OPTIONS = 69; // Hud Options LM

string AOON = "ZHAO_AOON";
string AOOFF = "ZHAO_AOOFF";
string UNLOCK = " UNLOCK";
string LOCK = " LOCK";
string SITANYON = "ZHAO_SITANYWHERE_ON";
string SITANYOFF = "ZHAO_SITANYWHERE_OFF";

string UPMENU = "BACK";
//string g_sParentMenu = "Main";
string g_sHudMenu = "Options";
string g_sOrderMenu = "Order";
//string submenu3 = "Tint";

// Start HUD Options
list g_lAttachPoints = [ATTACH_HUD_TOP_RIGHT,
                    ATTACH_HUD_TOP_CENTER,
                    ATTACH_HUD_TOP_LEFT,
                    ATTACH_HUD_BOTTOM_RIGHT,
                    ATTACH_HUD_BOTTOM,
                    ATTACH_HUD_BOTTOM_LEFT];

float g_fGap = 0.001; // This is the space between buttons
float g_Yoff = 0.002; // space between buttons and screen top/bottom border
float g_Zoff = 0.04; // space between buttons and screen left/right border

list g_lButtons ; // buttons names for Order menu
list g_lPrimOrder = [0,1,2,3,4]; // -- List must always start with '0','1'
// -- 0:Spacer, 1:Root, 2:Power, 3:Sit Anywhere, 4:Menu
// -- Spacer serves to even up the list with actual link numbers

integer g_iLayout = 1;
integer g_iHidden = FALSE;
integer g_iPosition = 69; // Nuff'said =D
integer g_iOldPos;
integer g_iNewPos;

integer g_iAOLock = FALSE;
integer g_iAOPower = TRUE; // -- Power will always be on when scripts are reset as that is the default state of the AO
integer g_iAOSit = FALSE;
vector g_vAOoffcolor = <0.5,0.5,0.5>;
vector g_vAOoncolor = <1,1,1>;
string g_sDarkLock = "e633ced3-2327-4288-8d4f-7cc530be0faa";
string g_sLightLock = "8aadf1ed-63d1-2bc5-174b-7c074f676b88";

list g_lStyles;
string g_sTexture; // current style

list g_lMenuIDs;
integer g_iMenuStride=3;

Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page, string menu)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
 "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);

    integer index = llListFindList(g_lMenuIDs, [rcpt]);
    if (~index) g_lMenuIDs = llListReplaceList(g_lMenuIDs,[rcpt,id,menu],index,index+g_iMenuStride-1);
    else g_lMenuIDs += [rcpt,id,menu];
}

FindButtons() { // collect buttons names & links
    g_lButtons = [" ", "Minimize"] ; // 'Minimize' need for g_sTexture
    g_lPrimOrder = [0, 1];  //  '1' - root prim
    integer i;
    for (i=2; i<llGetNumberOfPrims()+1; ++i) {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_DESC]);
        g_lPrimOrder += i;
    }
}

DoPosition(float yOff, float zOff) {   // Places the buttons
    integer i;
    integer LinkCount=llGetListLength(g_lPrimOrder);
    for (i=2;i<=LinkCount;++i) {
        llSetLinkPrimitiveParamsFast(llList2Integer(g_lPrimOrder,i),[PRIM_POSITION,<0, yOff*(i-1), zOff*(i-1)>]);
    }
}

DoTextures(string style) {

    list lTextures = [
    "[ Dark ]",
    "Minimize~e1482c7e-8609-fcb0-56d8-18c3c94d21c0",
    "Power~e630e9e0-799e-6acc-e066-196cca7b37d4",
    "SitAny~251b2661-235e-b4d8-0c75-248b6bdf6675",
    "Menu~f3ec1052-6ec4-04ba-d752-937a4d837bf8",
    "[ Light ]",
    "Minimize~b59f9932-5de4-fc23-b5aa-2ab46d22c9a6",
    "Power~42d4d624-ca72-1c74-0045-f782d7409061",
    "SitAny~349340c5-0045-c32d-540e-52b6fb77af55",
    "Menu~52c3f4cf-e87e-dbdd-cf18-b2c4f6002a96"
    ];

    integer i;
    while (i < llGetListLength(lTextures)) {
        string sData = llStringTrim(llList2String(lTextures,i),STRING_TRIM);
        if (sData!="" && llSubStringIndex(sData,"#") != 0) {
            if (llGetSubString(sData,0,0) == "[") {
                sData = llGetSubString(sData,llSubStringIndex(sData,"[")+1,llSubStringIndex(sData,"]")-1);
                sData = llStringTrim(sData,STRING_TRIM);
                if (style=="initialize") {  //reading list to determine style names
                    g_lStyles += sData;
                } else if (sData==style) {  //we just found our section
                    style="processing";
                    g_sTexture = sData;
                } else if (style=="processing") {  //we just found the start of the next section, we're
                    return;
                }
            } else if (style=="processing") {
                list lParams = llParseStringKeepNulls(sData,["~"],[]);
                string sButton = llStringTrim(llList2String(lParams,0),STRING_TRIM);
                integer link = llListFindList(g_lButtons,[sButton]);
                if (link > 0) {
                    sData = llStringTrim(llList2String(lParams,1),STRING_TRIM);
                    if (sData != "" && sData != ",") {
                        llSetLinkPrimitiveParamsFast(link,[PRIM_TEXTURE, ALL_SIDES, sData, <1,1,0>, ZERO_VECTOR, 0]);
                    }
                }
            }
        }
        i++;
    }
}

DefinePosition() {
    integer iPosition = llListFindList(g_lAttachPoints, [llGetAttached()]);
    vector size = llGetScale();
//  Allows manual repositioning, without resetting it, if needed
    if (iPosition != g_iPosition && iPosition != -1) { //do this only when attached to the hud
        vector offset = <0, size.y/2+g_Yoff, size.z/2+g_Zoff>;
        if (iPosition==0||iPosition==1||iPosition==2) offset.z = -offset.z;
        if (iPosition==2||iPosition==5) offset.y = -offset.y;
        llSetPos(offset); // Position the Root Prim on screen
        g_iPosition = iPosition;
    }
    if (g_iHidden) llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION,<1,0,0>]);
    else {
        float fYoff = size.y + g_fGap;
        float fZoff = size.z + g_fGap;
        if (iPosition == 0 || iPosition == 1 || iPosition == 2) fZoff = -fZoff;
        if (iPosition == 1 || iPosition == 2 || iPosition == 4 || iPosition == 5) fYoff = -fYoff;
        if (iPosition == 1 || iPosition == 4) g_iLayout = 0;
        if (g_iLayout) fYoff = 0;
        else fZoff = 0;
        DoPosition(fYoff, fZoff);
    }
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
    DefinePosition();
}

DetermineColors() {
    g_vAOoncolor = llGetColor(0);
    g_vAOoffcolor.x = g_vAOoncolor.x/2;
    g_vAOoffcolor.y = g_vAOoncolor.y/2;
    g_vAOoffcolor.z = g_vAOoncolor.z/2;
    DoStatus();
}

DoStatus() {
    vector color;
    if (g_iAOPower) color = g_vAOoncolor;
    else color = g_vAOoffcolor;
    llSetLinkColor(llListFindList(g_lButtons,["Power"]), color, ALL_SIDES);
    if (g_iAOSit) color = g_vAOoncolor;
    else color = g_vAOoffcolor;
    llSetLinkColor(llListFindList(g_lButtons,["SitAny"]), color, ALL_SIDES);
}

MainMenu(key id) {
    string text = "\nCustomize your AO!";
    list buttons = ["Horizontal","Vertical","Order"];
    buttons += g_lStyles;
    Dialog(id, text, buttons, [UPMENU], 0, g_sHudMenu);
}

OrderMenu(key id) {
    string text = "This is the order menu, simply select the\n";
    text += "button which you want to re-order.\n\n";
    integer i;
    list buttons;
    for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
        integer pos = llList2Integer(g_lPrimOrder,i);
        buttons += llList2List(g_lButtons,pos,pos);
    }
    Dialog(id, text, buttons, ["Reset",UPMENU], 0, g_sOrderMenu);
}


default {
    changed(integer change) {
        if (change & CHANGED_OWNER) llResetScript();
        else if (change & CHANGED_LINK) llResetScript();
        else if (change & CHANGED_COLOR) {
            if (llGetColor(0) != g_vAOoncolor) { //If we change color because of tint, we need to set the new g_vAOoffcolor!
                DetermineColors();
            }
        }
    }

    attach(key attached) {
        if (attached == NULL_KEY) return;
        else if (llGetAttached() <= 30) {
            llOwnerSay("Sorry, this device can only be placed on the HUD.");
            llRequestPermissions(attached, PERMISSION_ATTACH);
            llDetachFromAvatar();
            return;
        } else DefinePosition();
    }

    state_entry() {
        FindButtons(); // collect buttons names
        DefinePosition();
        DoTextures("initialize");
        DoTextures(llList2String(g_lStyles, 0));
        DetermineColors();
        //llSleep(1.0);
        //llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sHudMenu, "");
    }

    link_message(integer sender, integer num, string str, key id) {
        if (num == SUBMENU && str == g_sHudMenu) MainMenu(id);
        else if (num == CMD_AUTH && str == "ZHAO_RESET") llResetScript();
        else if (num == OPTIONS) {
            // llOwnerSay("We hit the HUD Options, Options LM: "+str);
            if (str == LOCK && !g_iHidden) {
                // Collapse the HUD and set AOLOCK so clicking the hide button dosnt do anyhting
                g_iHidden = TRUE;
                g_iAOLock = TRUE;
                DefinePosition();
                integer iLink = llListFindList(g_lButtons,["Minimize"]);
                if (g_sTexture == "Dark")
                    llSetLinkPrimitiveParamsFast(iLink,[PRIM_TEXTURE, ALL_SIDES, g_sDarkLock, <1,1,0>, ZERO_VECTOR, 0]);
                else if (g_sTexture == "Light")
                    llSetLinkPrimitiveParamsFast(iLink,[PRIM_TEXTURE, ALL_SIDES, g_sLightLock, <1,1,0>, ZERO_VECTOR, 0]);
            } else if (str == UNLOCK) {
                // Un-Collapse the HUD and set AOLOCK so the button works again
                g_iHidden = FALSE;
                g_iAOLock = FALSE;
                DefinePosition();
                DoTextures(g_sTexture);
            } else if (str == SITANYON) g_iAOSit = TRUE;
            else if (str == SITANYOFF) g_iAOSit = FALSE;
            else if (str == AOOFF) g_iAOPower = FALSE;
            else if (str == AOON) g_iAOPower = TRUE;
            DoStatus();
        } else if (num == DIALOG_RESPONSE) {
            integer index = llListFindList(g_lMenuIDs, [id]);
            if (index == -1) return;

            list menuparams = llParseString2List(str, ["|"], []);
            id = (key)llList2String(menuparams, 0);
            string response = llList2String(menuparams, 1);
            //integer page = (integer)llList2String(menuparams, 2);
            
            string sMenu = llList2String(g_lMenuIDs,index+1);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs,index-1,index-2+g_iMenuStride);

            if (sMenu == g_sHudMenu) {
                if (response == UPMENU) {
                    //llMessageLinked(LINK_THIS, CMD_OWNER, "ZHAO_MENU", id);
                    llMessageLinked(LINK_THIS, CMD_OWNER, "OCAO_MENU", id);
                    return;
                } else if (response == "Horizontal") {
                    g_iLayout = 0;
                    DefinePosition();
                } else if (response == "Vertical") {
                    g_iLayout = 1;
                    DefinePosition();
                } else if (response == g_sOrderMenu) {
                    OrderMenu(id);
                    return;
                } else if (~llListFindList(g_lStyles,[response])) DoTextures(response);
                MainMenu(id);
            } else if (sMenu == g_sOrderMenu) {
                if (response == UPMENU) MainMenu(id);
                else if (response == "Reset") {
                    FindButtons();
                    llRegionSayTo(id,0,"Order position reset to default.");
                    DefinePosition();
                    OrderMenu(id);
                } else if (llSubStringIndex(response,":") >= 0) {
                    g_iNewPos = llList2Integer(llParseString2List(response,[":"],[]),1);
                    DoButtonOrder();
                    OrderMenu(id);
                } else {
                    list lButtons;
                    string sPrompt;
                    integer iTemp = llListFindList(g_lButtons,[response]);
                    g_iOldPos = llListFindList(g_lPrimOrder, [iTemp]);
                    sPrompt = "\nSelect the new position for swap with "+response+"\n\n";
                    integer i;
                    for (i=2;i<llGetListLength(g_lPrimOrder);++i) {
                        if (g_iOldPos != i) {
                            integer iTemp = llList2Integer(g_lPrimOrder,i);
                            lButtons +=[llList2String(g_lButtons,iTemp)+":"+(string)i];
                        }
                    }
                    Dialog(id, sPrompt, lButtons, [UPMENU], 0, g_sOrderMenu);
                }
            }
        } else if (num == DIALOG_TIMEOUT) {
            integer index = llListFindList(g_lMenuIDs, [id]);
            if (~index) g_lMenuIDs = llDeleteSubList(g_lMenuIDs,index-1,index-2+g_iMenuStride);
        }
        else if (str == "hide" && !g_iAOLock) {
            // This disables the hide button when locked
            g_iHidden = !g_iHidden;
            DefinePosition();
        }
    }
}
