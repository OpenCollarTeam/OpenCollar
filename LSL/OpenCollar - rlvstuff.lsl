////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - rlvstuff                              //
//                                 version 3.992                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string g_sParentMenu = "RLV";

list g_lSettings; //3 strided list of prefix,option,value
list g_lChangedCategories;//list of categories that changed since last saved

integer g_lRLVcmds_stride=4;
list g_lRLVcmds=[ //4 strided list of menuname,command,prettyname,description
    "rlvsit_","unsit","Stand","Stand up if seated",
    "rlvsit_","sittp","Sit","Sit on objects >1.5m away",
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

//commands take effect immediately and are not stored, like: force sit and force stand
//4 strided list of menuname,cmd,prettyname,desc
integer g_lIdmtCmds_stride=4;
list g_lIdmtCmds = [
    "rlvsit_","sit","SitNow","Force Sit",
    "rlvsit_","forceunsit","StandNow","Force Stand"
];

list g_lMenuHelpMap = [
    "rlvsit_","sit",
    "rlvtp_","travel",
    "rlvtalk_","talk",
    "rlvtouch_","touch",
    "rlvmisc_","misc",
    "rlvview_","view"
];

string TURNON = "✔";
string TURNOFF = "✘";
string CTYPE = "collar";

float g_fScanRange = 20.0;//range we'll scan for scripted objects when doing a force-sit

// Variables used for sit memory function
string  g_sSitTarget = "";
integer g_iSitMode;
integer g_iSitListener;
float   g_fRestoreDelay = 1.0;
integer g_iRestoreCount = 0;
float   g_fPollDelay = 10.0;

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

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
string g_sScript_sit="rlvsit_";

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
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];

    //Debug("Made "+sName+" menu.");
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID, 0, sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

Menu(key kID, integer iAuth, string sMenuName) {
    //Debug("Making menu "+sMenuName);
    if (!g_iRLVOn) {
        Notify(kID, "RLV features are now disabled in this " + CTYPE + ". You can enable those in RLV submenu. Opening it now.", FALSE);
        llMessageLinked(LINK_SET, iAuth, "menu RLV", kID);
        return;
    }

    //build prompt showing current settings
    //make enable/disable buttons
    integer n;
    string sPrompt;
    list lButtons;
    
    n=llListFindList(g_lMenuHelpMap,[sMenuName]);
    if (~n){
        sPrompt="\nwww.opencollar.at/"+llList2String(g_lMenuHelpMap,n+1)+"\n";
    }

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

    //add immediate commands
    iStop = llGetListLength(g_lIdmtCmds);
    for (n = 0; n < iStop; n = n + g_lIdmtCmds_stride) {
        if (llList2String(g_lIdmtCmds, n)==sMenuName){
            lButtons += [llList2String(g_lIdmtCmds, n + 2)];
            sPrompt += "\n" + llList2String(g_lIdmtCmds, n + 2) + " = " + llList2String(g_lIdmtCmds, n + 3);
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

SetSetting(string sCategory, string sOption, string sValue){
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
            if (sTempRLVSetting=="unsit" && sTempRLVValue=="n") {  //permission to unsit revoked
                llSetTimerEvent(1.0);  //do timer event now to store name of seat, and start monitoring sitting
                g_iRestoreCount = 20;
                g_iSitMode=TRUE;
                //Debug("Got deny unsit command, re-sit if necessary");
            }
        }
        //output that string to viewer
        llMessageLinked(LINK_SET, RLV_CMD, llDumpList2String(lNewList, ","), NULL_KEY);
    }
}

SaveSettings() {    //save to DB
    list lCategorySettings;
    while (llGetListLength(g_lChangedCategories)){
        lCategorySettings=[];
        integer numSettings=llGetListLength(g_lSettings);
        while (numSettings){  //go through the list of all settings, and pull out any belonging to this category, store in temp list.
            numSettings -= 3;
            string sCategory=llList2String(g_lSettings,numSettings);
            if (sCategory==llList2String(g_lChangedCategories,-1)){
                lCategorySettings+=[llList2String(g_lSettings,numSettings+1),llList2String(g_lSettings,numSettings+2)];
            }
        }
        if (llGetListLength(lCategorySettings)>0) llMessageLinked(LINK_SET, LM_SETTING_SAVE, llList2String(g_lChangedCategories,-1) + "List=" + llDumpList2String(lCategorySettings, ","), "");
        else llMessageLinked(LINK_SET, LM_SETTING_DELETE, llList2String(g_lChangedCategories,-1) + "List", "");
        
        g_lChangedCategories=llDeleteSubList(g_lChangedCategories,-1,-1);
    }
}

ClearSettings(string _category) { //clear local settings list, delte from settings db
    integer numSettings=llGetListLength(g_lSettings);
    while (numSettings){
        numSettings-=3;
        string sCategory=llList2String(g_lSettings,numSettings);
        if (sCategory==_category || _category==""){
            g_lSettings=llDeleteSubList(g_lSettings,numSettings,numSettings+2);
            if (! ~llListFindList(g_lChangedCategories,[sCategory])) g_lChangedCategories+=sCategory;  //if there are no previous changes for thi category, add the category to the list of changed ones
        }
    }
    SaveSettings();
    //main RLV script will take care of sending @clear to viewer
}

UserCommand(integer iNum, string sStr, key kID, string fromMenu) {
    if (iNum > COMMAND_WEARER) return;  //nothing for lower than wearer here
    sStr=llStringTrim(sStr,STRING_TRIM);
    string sStrLower=llToLower(sStr);
    
    if (sStrLower == "sitmenu" || sStrLower == "menu sit") Menu(kID, iNum, "rlvsit_");
    else if (sStrLower == "rlvtp" || sStrLower == "menu travel") Menu(kID, iNum, "rlvtp_");
    else if (sStrLower == "rlvtalk" || sStrLower == "menu talk") Menu(kID, iNum, "rlvtalk_");
    else if (sStrLower == "rlvtouch" || sStrLower == "menu touch") Menu(kID, iNum, "rlvtouch_");
    else if (sStrLower == "rlvmisc" || sStrLower == "menu misc") Menu(kID, iNum, "rlvmisc_");
    else if (sStrLower == "rlvview" || sStrLower == "menu v̶i̶e̶w̶") Menu(kID, iNum, "rlvview_");
    else if (sStrLower == "sitnow") {
        if (!g_iRLVOn) {
            Notify(kID, "RLV features are now disabled in this " + CTYPE + ". You can enable those in RLV submenu. Opening it now.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
        } else {
            //give menu of nearby objects that have scripts in them
            //this assumes that all the objects you may want to force your sub to sit on
            //have scripts in them
            string sName="FindSeatMenu";
            key kMenuID = llGenerateKey();
            llMessageLinked(LINK_THIS, SENSORDIALOG, (string)kID + "|Pick the object on which you want the sub to sit.  If it's not in the list, have the sub move closer and try again.\n|0|``"+(string)(SCRIPTED|PASSIVE)+"`"+(string)g_fScanRange+"`"+(string)PI + "|BACK|" + (string)iNum, kMenuID);
            
            integer iIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1); //we've alread given a menu to this user.  overwrite their entry
            else g_lMenuIDs += [kID, kMenuID, sName]; //we've not already given this user a menu. append to list
        }
    } else {
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
            string sBehavior = llList2String(llParseString2List(sThisItem, ["=", ":"], []), 0);
            integer iBehaviourIndex=llListFindList(g_lRLVcmds, [sBehavior]);
            
            if (sStr == "standnow") {
                if (iNum == COMMAND_WEARER) llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                else {
                    sStr = "unsit=force";
                    if (GetSetting("rlvsit_","unsit")=="n") sStr = "unsit=y,unsit=force,unsit=n";
                    g_sSitTarget="";
                    //Debug("Removing tracked sit target");
                    llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
                }
            }
            else if (~iBehaviourIndex) {
                string sCategory=llList2String(g_lRLVcmds,iBehaviourIndex-1);
                if (llGetSubString(sCategory,-1,-1)=="_"){  //
                    //Debug(sBehavior+" is a behavior that we handle, from the "+sCategory+" category.");
                    //filter commands from wearer, if wearer is not owner
                    if (iNum == COMMAND_WEARER) llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                    else {
                        string sOption = llList2String(llParseString2List(sThisItem, ["="], []), 0);
                        string sValue = llList2String(llParseString2List(sThisItem, ["="], []), 1);
                        integer iIndex = llListFindList(g_lSettings, [sCategory,sOption]);
                        SetSetting(sCategory, sOption, sValue);
                    }
                }
            } else if (~llListFindList(llList2ListStrided(llDeleteSubList(g_lIdmtCmds,0,0),0,-1,g_lIdmtCmds_stride), [sBehavior])) {
                //Debug(sBehavior+" is an immediate command that we handle");
                //filter commands from wearer, if wearer is not owner
                if (iNum == COMMAND_WEARER) llOwnerSay("Sorry, but RLV commands may only be given by owner, secowner, or group (if set).");
                else llMessageLinked(LINK_SET, RLV_CMD, sStr, NULL_KEY);
            }
            else if (sBehavior == "clear" && iNum == COMMAND_OWNER) ClearSettings("");
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
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        g_kWearer = llGetOwner();
        //llSetTimerEvent(1.0);  //timer will be called by recieved settings as necessary
        //Debug("Starting");
    }
    
    timer() {
        if (!g_iRLVOn) return;  // Nothing to do if RLV isn't enabled
        if (GetSetting("rlvsit_","unsit")!="n") {  //we are allowed to stand, so switch off timer and return
            llSetTimerEvent(0.0);
            g_sSitTarget = "";
            //Debug("we are allowed to stand, so switch off timer, remove tracked sit target");
        } else {  //banned from standing up
            
            key kSitKey = llList2Key(llGetObjectDetails(g_kWearer, [OBJECT_ROOT]), 0);
            
            if (g_iSitMode) {  // Restore mode.  Find the seat and sit in it
                llSetTimerEvent(g_fRestoreDelay);
                if (g_sSitTarget == "") {  //If we have no seat, go back to monitoring
                    g_iSitMode = 0;
                    //Debug("You weren't sitting on anything");
                } else if ((string)kSitKey == g_sSitTarget) {   //sat in the right seat, go back to monitoring
                    g_iSitMode = 0;
                    //Debug("You're in the right seat, go back to monitoring");
                } else if (g_iRestoreCount > 0) {  // Count down retries...
                    llOwnerSay("You should be sitting on " + llKey2Name((key)g_sSitTarget));
                    g_iRestoreCount--;
                    string sSittpValue = GetSetting("rlvsit_","sittp");  // Save the value of sittp as we need to temporarily enable it for forcesit
                    llMessageLinked(LINK_THIS, RLV_CMD, "sittp=y,sit:" + g_sSitTarget + "=force,sittp=" + sSittpValue, NULL_KEY);
                } else {
                    llOwnerSay("Couldn't re-seat you on " + llKey2Name((key)g_sSitTarget));
                    //Debug("Removing tracked sit target");
                    g_iSitMode = 0;
                    g_sSitTarget = "";
                }
            } else {  //monitoring the sub's sitting activity
                llSetTimerEvent(g_fPollDelay);
                if (kSitKey == g_kWearer) {  //store "not sitting down"
                    g_sSitTarget = "";
                    //Debug("Not sitting down");
                } else {
                    g_sSitTarget = (string)kSitKey; //store ID of your seat.
                    //Debug("Sitting on " + llKey2Name((key)g_sSitTarget));
                }
            }
        }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|Sit", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|Travel", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|Talk", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|Touch", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|Misc", "");
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|V̶i̶e̶w̶", "");
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_EVERYONE) UserCommand(iNum, sStr, kID, "");
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
            else if (sToken == "Global_CType") CTYPE = sValue;
            //else Debug("not my token: "+category);
        } else if (iNum == RLV_REFRESH) {   //rlvmain just started up.  Tell it about our current restrictions
            g_iRLVOn = TRUE;
            UpdateSettings();
        }
        else if (iNum == RLV_CLEAR) ClearSettings("");    //clear db and local settings list
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
                
                if (sMenu == "FindSeatMenu") {
                    if (sMessage==UPMENU) Menu(kAv, iAuth, "rlvsit_");
                    else if ((key) sMessage) {
                        //Debug("Sending \""+"sit:" + sMessage + "=force\" to "+(string)kAv+" with auth "+(string)iAuth);
                        UserCommand(iAuth, "sit:" + sMessage + "=force", kAv, "rlvsit_");
                    }                            
                } else {
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == "SitNow") UserCommand(iAuth, "sitnow", kAv, "rlvsit_");
                    else if (sMessage == "StandNow") UserCommand(iAuth, "standnow", kAv, "rlvsit_");
                    else {
                        //we got a command to enable or disable something, like "Enable LM"
                        //get the actual command name by looking up the pretty name from the message
    
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
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            //remove stride from g_lMenuIDs
            //we have to subtract from the index because the dialog id comes in the middle of the stride
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                        
        }
    }
    
/*        
    changed(integer iChange)
    {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/        
}
