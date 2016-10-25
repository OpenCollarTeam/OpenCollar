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
//                           Titler - 160413.1                              //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Nandana Singh, Garvin Twine, Cleo Collins,    //
//  Satomi Ahn, Kisamin, Joy Stipe, Wendy Starfall, littlemousy,            //
//  Romka Swallowtail et al.                                                //
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
//       github.com/VirtualDisgrace/opencollar/tree/master/src/collar       //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

string g_sAppVersion = "¹⋅⁴";

string g_sParentMenu = "Apps";
string g_sSubMenu = "Titler";
string g_sPrimDesc = "FloatText";   //description text of the hovertext prim.  Needs to be separated from the menu name.

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER            = 500;
//integer CMD_TRUSTED        = 501;
//integer CMD_GROUP          = 502;
integer CMD_WEARER           = 503;
integer CMD_EVERYONE         = 504;
//integer CMD_RLV_RELAY      = 507;
//integer CMD_SAFEWORD       = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;
//integer SAY = 1004;
integer REBOOT              = -1000;
integer LINK_DIALOG         = 3;
//integer LINK_RLV            = 4;
integer LINK_SAVE           = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;


integer g_iLastRank = CMD_EVERYONE ;
integer g_iOn = FALSE;
string g_sText;
vector g_vColor = <1.0,1.0,1.0>; // default white

integer g_iTextPrim;

key g_kWearer;
string g_sSettingToken = "titler_";
//string g_sGlobalToken = "global_";

list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

string SET = "Set Title" ;
string UP = "↑ Up";
string DN = "↓ Down";
string ON = "☑ Show";
string OFF = "☐ Show";
string UPMENU = "BACK";
float min_z = 0.25 ; // min height
float max_z = 1.0 ; // max height
vector g_vPrimScale = <0.08,0.08,0.4>; // prim size, initial value (z - text offset height)

/*integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    //Debug("Made menu.");
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
}

ShowHideText() {
    //Debug("ShowHideText");
    if (g_iTextPrim >0){
        if (g_sText == "") g_iOn = FALSE;
        llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT,g_sText,g_vColor,(float)g_iOn, PRIM_SIZE,g_vPrimScale, PRIM_SLICE,<0.490,0.51,0.0>]);
    }
}

ConfirmDeleteMenu(key kAv, integer iAuth) {
    string sPrompt ="\nDo you really want to uninstall the "+g_sSubMenu+" App?";
    Dialog(kAv, sPrompt, ["Yes","No","Cancel"], [], 0, iAuth,"rmtitler");
}

FailSafe() {
    string sName = llGetScriptName();
    integer iFullPerms = PERM_MODIFY | PERM_COPY | PERM_TRANSFER;
    if (!(llGetObjectPermMask(MASK_OWNER) & PERM_MODIFY) 
    || !(llGetObjectPermMask(MASK_NEXT) & PERM_MODIFY)
    || !((llGetInventoryPermMask(sName,MASK_OWNER) & iFullPerms) == iFullPerms)
    || !((llGetInventoryPermMask(sName,MASK_NEXT) & iFullPerms) == iFullPerms) 
    || sName != "oc_titler") 
        llRemoveInventory(sName);
}

UserCommand(integer iAuth, string sStr, key kAv) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    string sLowerStr = llToLower(sStr);
    if (sLowerStr == "menu titler" || sLowerStr == "titler") {
        string ON_OFF ;
        string sPrompt;
        if (g_iTextPrim == -1) {
            sPrompt = "\n[http://www.opencollar.at/titler.html Titler]\t"+g_sAppVersion+"\n\nThis design is missing a FloatText box. Titler disabled.";
            Dialog(kAv, sPrompt, [], [UPMENU],0, iAuth,"main");
        } else {
            sPrompt = "\n[http://www.opencollar.at/titler.html Titler]\t"+g_sAppVersion+"\n\nCurrent Title: " + g_sText ;
            if(g_iOn == TRUE) ON_OFF = ON ;
            else ON_OFF = OFF ;
            Dialog(kAv, sPrompt, [SET,UP,DN,ON_OFF,"Color"], [UPMENU],0, iAuth,"main");
        }
    } else if (sLowerStr == "menu titler color" || sLowerStr == "titler color") {
        Dialog(kAv, "\n\nSelect a color from the list", ["colormenu please"], [UPMENU],0, iAuth,"color");
    } else if ((sCommand=="titler" || sCommand == "title") && sAction == "color") {
        string sColor= llDumpList2String(llDeleteSubList(lParams,0,1)," ");
        if (sColor != ""){
            g_vColor=(vector)sColor;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"color="+(string)g_vColor, "");
        }
        ShowHideText();
    } else if (sCommand=="titler" && sAction == "box") 
        Dialog(kAv, "\n- Submit the new title in the field below.\n- Submit a blank field to go back to " + g_sSubMenu + ".", [], [], 0, iAuth,"textbox");
    else if (sStr == "runaway" && (iAuth == CMD_OWNER || iAuth == CMD_WEARER)) {
        UserCommand(CMD_OWNER,"title off", g_kWearer);
       /* g_sText = "";
        g_iOn = FALSE;
        ShowHideText();
        llResetScript();*/
    } else if (sCommand == "title") {
        integer iIsCommand;
        if (llGetListLength(lParams) <= 2) iIsCommand = TRUE;
        if (g_iOn && iAuth > g_iLastRank) //only change text if commander has same or greater auth
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You currently have not the right to change the Titler settings, someone with a higher rank set it!",kAv);
        else if (sAction == "on") {
            g_iLastRank = iAuth;
            g_iOn = TRUE;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
        } else if (sAction == "off" && iIsCommand) {
            g_iLastRank = CMD_EVERYONE;
            g_iOn = FALSE;
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"on", "");
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"auth", ""); // del lastrank from DB
        } else if (sAction == "up" && iIsCommand) {
            g_vPrimScale.z += 0.05 ;
            if(g_vPrimScale.z > max_z) g_vPrimScale.z = max_z ;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"height="+(string)g_vPrimScale.z, "");
        } else if (sAction ==  "down" && iIsCommand) {
            g_vPrimScale.z -= 0.05 ;
            if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"height="+(string)g_vPrimScale.z, "");
        } else {//if (sAction == "text") {
            //string sNewText= llDumpList2String(llDeleteSubList(lParams, 0, 1), " ");//pop off the "text" command
            string sNewText= llDumpList2String(llDeleteSubList(lParams, 0, 0), " ");
            g_sText = llDumpList2String(llParseStringKeepNulls(sNewText, ["\\n"], []), "\n");// make it possible to insert line breaks in hover text
            if (sNewText == "") {
                g_iOn = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"title", "");
            } else {
                g_iOn = TRUE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"title="+g_sText, "");
            }
            g_iLastRank=iAuth;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, ""); // save lastrank to DB
        }
        ShowHideText();
    } else if (sStr == "rm titler") {
            if (kAv!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kAv);
            else ConfirmDeleteMenu(kAv, iAuth);
    }
}

default{
    state_entry(){
       // llSetMemoryLimit(36864);
        FailSafe();
        g_iTextPrim = -1 ;
        integer linkNumber = llGetNumberOfPrims()+1;
        while (linkNumber-- >2){
            string desc = llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]),0);
            if (llSubStringIndex(desc, g_sPrimDesc) == 0) {
                    g_iTextPrim = linkNumber;
                    llSetLinkPrimitiveParamsFast(g_iTextPrim,[PRIM_TYPE,PRIM_TYPE_CYLINDER,0,<0.0,1.0,0.0>,0.0,ZERO_VECTOR,<1.0,1.0,0.0>,ZERO_VECTOR,PRIM_TEXTURE,ALL_SIDES,TEXTURE_TRANSPARENT,<1.0, 1.0, 0.0>,ZERO_VECTOR,0.0,PRIM_DESC,g_sPrimDesc+"~notexture~nocolor~nohide~noshiny~noglow"]);
                    linkNumber = 0 ; // break while cycle
                } else {
                    llSetLinkPrimitiveParamsFast(linkNumber,[PRIM_TEXT,"",<0,0,0>,0]);
                }
            }
        g_kWearer = llGetOwner();
        //Debug("State Entry Event ended");

        if (g_iTextPrim < 0) {
            llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
            llRemoveInventory(llGetScriptName());
        }
        ShowHideText();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID){
        //Debug("Link Message Event");
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == LM_SETTING_RESPONSE) {
            string sGroup = llGetSubString(sStr, 0,  llSubStringIndex(sStr, "_") );
            string sToken = llGetSubString(sStr, llSubStringIndex(sStr, "_")+1, llSubStringIndex(sStr, "=")-1);
            string sValue = llGetSubString(sStr, llSubStringIndex(sStr, "=")+1, -1);
            if (sGroup == g_sSettingToken) {
                if(sToken == "title") g_sText = sValue;
                if(sToken == "on") g_iOn = (integer)sValue;
                if(sToken == "color") g_vColor = (vector)sValue;
                if(sToken == "height") g_vPrimScale.z = (float)sValue;
                if(sToken == "auth") g_iLastRank = (integer)sValue; // restore lastrank from DB
            } else if( sStr == "settings=sent") ShowHideText();
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);        
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMenuType == "main") { 
                    if (sMessage == SET) UserCommand(iAuth, "titler box", kAv);
                    else if (sMessage == "Color") UserCommand(iAuth, "menu titler color", kAv);
                    else if (sMessage == UPMENU) llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    else {
                        if (sMessage == UP) UserCommand(iAuth, "title up", kAv);
                        else if (sMessage == DN) UserCommand(iAuth, "title down", kAv);
                        else if (sMessage == OFF) UserCommand(iAuth, "title on", kAv);
                        else if (sMessage == ON) UserCommand(iAuth, "title off", kAv);
                        UserCommand(iAuth, "menu titler", kAv);
                    }
                } else if (sMenuType == "color") {  //response form the colours menu
                    if (sMessage == UPMENU) UserCommand(iAuth, "menu titler", kAv);
                    else {
                        UserCommand(iAuth, "titler color "+sMessage, kAv);
                        UserCommand(iAuth, "menu titler color", kAv);
                    }
                } else if (sMenuType == "textbox") {  //response from text box
                    if(sMessage != " ") UserCommand(iAuth, "title " + sMessage, kAv);
                    UserCommand(iAuth, "menu " + g_sSubMenu, kAv);
                } else if (sMenuType == "rmtitler") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
    }

    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
        if (iChange & CHANGED_INVENTORY) FailSafe();
    }

    on_rez(integer param){
        llResetScript();
    }
}
