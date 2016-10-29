//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                          RLV Stuff - 161029.1                            //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Satomi Ahn, Nandana Singh, Joy Stipe,         //
//  Wendy Starfall, Master Starship, littlemousy, Romka Swallowtail,        //
//  Garvin Twine et al.                                                     //
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
//       github.com/VirtualDisgrace/opencollar/tree/master/src/spares       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

string g_sAppVersion = "¹⋅¹";

string g_sParentMenu = "RLV";

list g_lSettings; //3 strided list of prefix,option,value
list g_lChangedCategories;//list of categories that changed since last saved

integer g_lRLVcmds_stride=4;
list g_lRLVcmds=[ //4 strided list of menuname,command,prettyname,description
    "rlvtp_","tplm","Landmark","Teleport via Landmark",
    "rlvtp_","tploc","Slurl","Teleport via Slurl/Map",
    "rlvtp_","tplure","Lure","Teleport via offers",
    "rlvtp_","showworldmap","Map","View World-map",
    "rlvtp_","showminimap","Mini-map","View Mini-map",
    "rlvtp_","showloc","Location","See current location",
    "rlvtalk_","sendchat","Chat","Ability to Chat",
    "rlvtalk_","chatshout","Shout","Ability to Shout",
    "rlvtalk_","chatnormal","Whisper","Forced to Whisper",
    "rlvtalk_","startim","Start IMs","Initiate IM Sessions",
    "rlvtalk_","sendim","Send IMs","Respond to IMs",
    "rlvtalk_","recvim","Get IMs","Receive IMs",
    "rlvtalk_","recvchat","See Chat","Receive Chat",
    "rlvtalk_","recvemote","See Emote","Receive Emotes",
    "rlvtalk_","emote","Emote","Short Emotes if Chat blocked",
    "rlvtouch_","fartouch","Far","Touch objects >1.5m away",
    "rlvtouch_","touchworld","World","Touch in-world objects",
    "rlvtouch_","touchattach","Self","Touch your attachments",
    "rlvtouch_","touchattachother","Others","Touch others' attachments",
    "rlvmisc_","shownames","Names","See Avatar Names",
    "rlvmisc_","fly","Fly","Ability to Fly",
    "rlvmisc_","edit","Edit","Edit Objects",
    "rlvmisc_","rez","Rez","Rez Objects",
    "rlvmisc_","showinv","Inventory","View Inventory",
    "rlvmisc_","viewnote","Notecards","View Notecards",
    "rlvmisc_","viewscript","Scripts","View Scripts",
    "rlvmisc_","viewtexture","Textures","View Textures",
    "rlvmisc_","showhovertextworld","Hovertext","See hovertext like titles",
    "rlvview_","camdistmax:0","Mouselook","Leave Mouselook",
    "rlvview_","camunlock","Alt Zoom","Alt zoom/pan around",
    "rlvview_","camdrawalphamax:1","See","See anything at all"
];

list g_lMenuHelpMap = [
    "rlvstuff_","Stuff",
    "rlvtp_","Travel",
    "rlvtalk_","Talk",
    "rlvtouch_","Touch",
    "rlvmisc_","Misc",
    "rlvview_","View"
];

string TURNON = "✔";
string TURNOFF = "✘";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;

//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
//integer NOTIFY_OWNERS = 1003;
//integer LOADPIN = -1904;
integer REBOOT  = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV    = 4;
integer LINK_SAVE   = 5;
integer LINK_UPDATE = -10;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by setting script when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;

string UPMENU = "BACK";

key g_kWearer;

integer g_iRLVOn=FALSE;

list g_lMenuIDs;//3-strided list of avatars given menus, their dialog ids, and the name of the menu they were given
integer g_iMenuStride = 3;

/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    llMessageLinked(LINK_DIALOG,NOTIFY,(string)iAlsoNotifyWearer+sMsg,kID);
}

StuffMenu(key kID, integer iAuth) {
    Dialog(kID, "\n[http://www.opencollar.at/legacy-rlv.html Legacy RLV Stuff]\t"+g_sAppVersion, ["Misc","Touch","Talk","Travel","View"], [UPMENU], 0, iAuth, "rlvstuff");
}

Menu(key kID, integer iAuth, string sMenuName) {
    //Debug("Making menu "+sMenuName);
    if (!g_iRLVOn) {
        Notify(kID, "RLV features are now disabled in this %DEVICETYPE%. You can enable those in RLV submenu. Opening it now.", FALSE);
        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kID);
        return;
    }
    //build prompt showing current settings
    //make enable/disable buttons
    integer n;
    string sPrompt;
    list lButtons;

    n=llListFindList(g_lMenuHelpMap,[sMenuName]);
    if (~n) sPrompt="\n[http://www.opencollar.at/legacy-rlv.html Legacy RLV "+llList2String(g_lMenuHelpMap,n+1)+"]\n";

    integer iStop = llGetListLength(g_lRLVcmds);
    for (n = 0; n < iStop; n+=g_lRLVcmds_stride) {
        if (llList2String(g_lRLVcmds,n)==sMenuName){
            //see if there's a setting for this in the settings list
            string sCmd = llList2String(g_lRLVcmds, n+1);
            string sPretty = llList2String(g_lRLVcmds, n+2);
            string desc = llList2String(g_lRLVcmds, n+3);
            integer iIndex = llListFindList(g_lSettings, [sCmd]);

            if (iIndex == -1) {
                //if this cmd not set, then give button to enable
                lButtons += [TURNOFF + " " + sPretty];
                sPrompt += "\n" + sPretty + " = Enabled (" + desc + ")";
            } else {
                //else this cmd is set, then show in prompt, and make button do opposite
                //get value of setting
                string sValue = llList2String(g_lSettings, iIndex + 1);
                if (sValue == "y") {
                    lButtons += [TURNOFF + " " + sPretty];
                    sPrompt += "\n" + sPretty + " = Enabled (" + desc + ")";
                } else if (sValue == "n") {
                    lButtons += [TURNON + " " + sPretty];
                    sPrompt += "\n" + sPretty + " = Disabled (" + desc + ")";
                }
            }
        }
    }
    //give an Allow All button
    lButtons += [TURNON + " All"];
    lButtons += [TURNOFF + " All"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, sMenuName);
}

string GetSetting(string sCategory, string sParam) {
    integer iIndex = llListFindList(g_lSettings, [sCategory,sParam]);
    return llList2String(g_lSettings, iIndex + 2);
}

SetSetting(string sCategory, string sOption, string sValue) {
    integer iIndex=llListFindList(g_lSettings,[sCategory,sOption]);
    if (~iIndex) g_lSettings=llListReplaceList(g_lSettings, [sCategory, sOption, sValue], iIndex, iIndex+2); //there is already a setting, change it
    else g_lSettings+=[sCategory, sOption, sValue];  //no setting exists.. add one

    if (! ~llListFindList(g_lChangedCategories,[sCategory])) g_lChangedCategories+=sCategory;  //if there are no previous changes for thi category, add the category to the list of changed ones
}

UpdateSettings() {    //build one big string from the settings list, and send to to the viewer to reset rlv settings
    //llOwnerSay("TP settings: " + llDumpList2String(lSettings, ","));
    integer iSettingsLength = llGetListLength(g_lSettings);
    //Debug("Applying "+(string)(iSettingsLength/3)+" settings");
    if (iSettingsLength > 0) {
        list lTempSettings;
        string sTempRLVSetting;
        string sTempRLVValue;
        integer n;
        list lNewList;
        for (n = 0; n < iSettingsLength; n = n + 3) {
            sTempRLVSetting=llList2String(g_lSettings, n+1);
            sTempRLVValue=llList2String(g_lSettings, n + 2);
            lNewList += [ sTempRLVSetting+ "=" + sTempRLVValue];
            if (sTempRLVValue!="y")lTempSettings+=[sTempRLVSetting,sTempRLVValue];
        }
        //output that string to viewer
        llMessageLinked(LINK_RLV, RLV_CMD, llDumpList2String(lNewList, ","), NULL_KEY);
    }
}

SaveSettings() {
    list lCategorySettings;
    while (llGetListLength(g_lChangedCategories)) {
        lCategorySettings=[];
        integer numSettings=llGetListLength(g_lSettings);
        while (numSettings) {  //go through the list of all settings, and pull out any belonging to this category, store in temp list.
            numSettings -= 3;
            string sCategory=llList2String(g_lSettings,numSettings);
            if (sCategory==llList2String(g_lChangedCategories,-1)) {
                lCategorySettings+=[llList2String(g_lSettings,numSettings+1),llList2String(g_lSettings,numSettings+2)];
            }
        }
        if (llGetListLength(lCategorySettings)>0) llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, llList2String(g_lChangedCategories,-1) + "List=" + llDumpList2String(lCategorySettings, ","), "");
        else llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, llList2String(g_lChangedCategories,-1) + "List", "");

        g_lChangedCategories=llDeleteSubList(g_lChangedCategories,-1,-1);
    }
}

ClearSettings(string _category) { //clear settings list
    integer numSettings=llGetListLength(g_lSettings);
    while (numSettings) {
        numSettings-=3;
        string sCategory=llList2String(g_lSettings,numSettings);
        if (sCategory==_category || _category=="") {
            g_lSettings=llDeleteSubList(g_lSettings,numSettings,numSettings+2);
            if (! ~llListFindList(g_lChangedCategories,[sCategory])) g_lChangedCategories+=sCategory;  //if there are no previous changes for thi category, add the category to the list of changed ones
        }
    }
    SaveSettings();
    //main RLV script will take care of sending @clear to viewer
}

FailSafe() {
    string sName = llGetScriptName();
    if ((key)sName) return;
    if (!(llGetObjectPermMask(1) & 0x4000)
    || !(llGetObjectPermMask(4) & 0x4000)
    || !((llGetInventoryPermMask(sName,1) & 0xe000) == 0xe000)
    || !((llGetInventoryPermMask(sName,4) & 0xe000) == 0xe000)
    || sName != "oc_rlvstuff")
        llRemoveInventory(sName);
}

UserCommand(integer iNum, string sStr, key kID, string fromMenu) {
    if (iNum > CMD_WEARER) return;  //nothing for lower than wearer here
    sStr=llStringTrim(sStr,STRING_TRIM);
    string sStrLower=llToLower(sStr);
    if (sStrLower == "rm rlvstuff") {
        if (kID!=g_kWearer && iNum!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
        else Dialog(kID, "\nDo you really want to uninstall Legacy RLV Stuff?", ["Yes","No","Cancel"], [], 0, iNum,"rmrlvstuff");
    } else if (sStrLower == "rlvtp" || sStrLower == "menu travel") Menu(kID, iNum, "rlvtp_");
    else if (sStrLower == "rlvtalk" || sStrLower == "menu talk") Menu(kID, iNum, "rlvtalk_");
    else if (sStrLower == "rlvtouch" || sStrLower == "menu touch") Menu(kID, iNum, "rlvtouch_");
    else if (sStrLower == "rlvmisc" || sStrLower == "menu misc") Menu(kID, iNum, "rlvmisc_");
    else if (sStrLower == "rlvview" || sStrLower == "menu view") Menu(kID, iNum, "rlvview_");
    else if (sStrLower == "rlvstuff" || sStrLower == "menu stuff") StuffMenu(kID, iNum);
    else {
        //do simple pass through for chat commands
        //since more than one RLV command can come on the same line, loop through them
        list lItems = llParseString2List(sStr, [","], []);
        integer n;
        integer iStop = llGetListLength(lItems);
        list lChange;  //list containing the categories with changed settings
        for (n = 0; n < iStop; n++) {
            //split off the parameters (anything after a : or =)
            //and see if the thing being set concerns us
            string sThisItem = llList2String(lItems, n);
            string sBehavior = llList2String(llParseString2List(sThisItem, ["="], []), 0);
            integer iBehaviourIndex=llListFindList(g_lRLVcmds, [sBehavior]);

            if (~iBehaviourIndex) {
                string sCategory=llList2String(g_lRLVcmds,iBehaviourIndex-1);
                if (llGetSubString(sCategory,-1,-1)=="_"){  //
                    //Debug(sBehavior+" is a behavior that we handle, from the "+sCategory+" category.");
                    //filter commands from wearer, if wearer is not owner
                    if (iNum == CMD_WEARER) llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                    else {
                        string sOption = llList2String(llParseString2List(sThisItem, ["="], []), 0);
                        string sValue = llList2String(llParseString2List(sThisItem, ["="], []), 1);
                        integer iIndex = llListFindList(g_lSettings, [sCategory,sOption]);
                        SetSetting(sCategory, sOption, sValue);
                    }
                }
            } else if (sBehavior == "clear" && iNum == CMD_OWNER) ClearSettings("");
            //else Debug("We don't handle "+sBehavior);
        }

        if (llGetListLength(g_lChangedCategories)) {
            UpdateSettings();
            SaveSettings();
        }
        if (fromMenu!="") Menu(kID, iNum, fromMenu);
    }
}

default {
    on_rez(integer iParam) {
        llSetTimerEvent(0.0);  //timer will be called by recieved settings as necessary
    }

    state_entry() {
        g_kWearer = llGetOwner();
        FailSafe();
        //Debug("Starting");
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|Stuff", "");
        else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID, "");
        else if (iNum == LM_SETTING_RESPONSE) {
            //this is tricky since our db value contains equals signs
            //split string on both comma and equals sign
            //first see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer iChange = FALSE;

            string category=llList2String(llParseString2List(sToken,["_"],[]),0)+"_";
            if (~llListFindList(g_lMenuHelpMap,[category])){
                //Debug("got settings token: "+category);
                sToken=llList2String(llParseString2List(sToken,["_"],[]),1);
                if (sToken == "List") {
                    //throw away first element
                    //everything else is real settings (should be even number)
                    ClearSettings(category);
                    list lNewSettings = llParseString2List(sValue, [","], []);
                    while (llGetListLength(lNewSettings)){
                        list lTempSettings=[category,llList2String(lNewSettings,-2),llList2String(lNewSettings,-1)];
                        //Debug(llDumpList2String(lTempSettings,"  -  "));
                        g_lSettings+=lTempSettings;
                        lNewSettings=llDeleteSubList(lNewSettings,-2,-1);
                    }
                    UpdateSettings();
                }
            }
            //else Debug("not my token: "+category);
        } else if (iNum == RLV_REFRESH) {   //rlvmain just started up.  Tell it about our current restrictions
            g_iRLVOn = TRUE;
            UpdateSettings();
        }
        else if (iNum == RLV_CLEAR) ClearSettings("");    //clear settings list
        else if (iNum == RLV_OFF) g_iRLVOn=FALSE;        // rlvoff -> we have to turn the menu off too
        else if (iNum == RLV_ON) g_iRLVOn=TRUE;        // rlvon -> we have to turn the menu on again
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {    //it's one of our menus
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                if (sMenu == "rmrlvstuff") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_RLV, MENUNAME_REMOVE, g_sParentMenu + "|Stuff", "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+"Legacy RLV Stuff has been removed.", kAv);
                        ClearSettings("");
                        if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+"Legacy RLV Stuff remains installed.", kAv);
                } else if (sMenu == "rlvstuff") {
                    if (sMessage == UPMENU) llMessageLinked(LINK_RLV, iAuth, "menu "+g_sParentMenu, kAv);
                    else UserCommand(iAuth, "menu "+sMessage, kAv, "");
                }
                else if (sMessage == UPMENU) StuffMenu(kAv,iAuth);
                    //we got a command to enable or disable something, like "Enable LM"
                    //get the actual command name by looking up the pretty name from the message
                else {
                    list lParams = llParseString2List(sMessage, [" "], []);
                    string sSwitch = llList2String(lParams, 0);
                    string sCmd = llDumpList2String(llDeleteSubList(lParams,0,0)," ");
                    integer iIndex = llListFindList(g_lRLVcmds, [sCmd]);
                    if (sCmd == "All") {
                        //handle the "Allow All" and "Forbid All" commands
                        string ONOFF;
                        //decide whether we need to switch to "y" or "n"
                        if (sSwitch == TURNOFF) ONOFF = "n";  //enable all functions (ie, remove all restrictions
                        else if (sSwitch == TURNON) ONOFF = "y";
                        //loop through rlvcmds to create list
                        string sOut;
                        integer n;
                        integer iStop = llGetListLength(g_lRLVcmds);
                        for (n = 0; n < iStop; n+=g_lRLVcmds_stride) {
                            if (llList2String(g_lRLVcmds,n)==sMenu){
                                if (sOut != "")  sOut += ",";  //prefix all but the first value with a comma, so we have a comma-separated list
                                sOut += llList2String(g_lRLVcmds, n+1) + "=" + ONOFF;
                            }
                        }
                        UserCommand(iAuth, sOut, kAv, sMenu);
                    } else if (~iIndex && llList2String(g_lRLVcmds,iIndex-2)==sMenu) {
                        string sOut = llList2String(g_lRLVcmds, iIndex-1);
                        sOut += "=";
                        if (sSwitch == TURNON) sOut += "y";
                        else if (sSwitch == TURNOFF) sOut += "n";
                        //send rlv command out through auth system as though it were a chat command, just to make sure person who said it has proper authority
                        UserCommand(iAuth, sOut, kAv, sMenu);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            if (~iMenuIndex) g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_RLV") LINK_RLV = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) FailSafe();
        /*if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }*/
    }
}
