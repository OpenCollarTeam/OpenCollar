/*
THIS FILE IS HEREBY RELEASED UNDER THE Public Domain
This script is released public domain, unlike other OC scripts for a specific and limited reason, because we want to encourage third party plugin creators to create for OpenCollar and use whatever permissions on their own work they see fit.  No portion of OpenCollar derived code may be used excepting this script,  without the accompanying GPLv2 license.
-Authors Attribution-
Aria (tiff589) - (July 2018-December 2019)
roan (Silkie Sabra) - (September 2018)
*/


string g_sParentMenu = "Apps";
string g_sSubMenu = "Menu Test";


//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
string ALL = "ALL";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName, integer iSort) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth + "|"+(string)iSort, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Menu App]";
    list lButtons = ["UUID-Avs", "UUID-Objs", "LongText", "ColorMenu", "ObjsSorted"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main",0);
}
LongTester(key kID, integer iAuth){
    string sPrompt = "\n[Long text tester]";
    list lButtons = [];
    integer i=0;
    integer end = 30;
    for(i=0;i<end;i++){
        lButtons += llMD5String((string)i, 0);
    }
    
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~LongText",0);
}

AvsTester (key kID, integer iAuth){
    string sPrompt = "\n[Avatar tester]";
    list lButtons = llGetAgentList(AGENT_LIST_REGION, []);
    Dialog(kID,sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Avs",0);
}
integer g_iSorted;
ObjsTester(key kID, integer iAuth){
    g_kTmpScan = kID;
    g_iSorted=FALSE;
    g_iTmpAuth = iAuth;
    llSensor("","", PASSIVE | SCRIPTED, 50, PI);
}
ObjsSortTester(key kID, integer iAuth){
    g_kTmpScan = kID;
    g_iSorted=TRUE;
    g_iTmpAuth = iAuth;
    llSensor("","", PASSIVE | SCRIPTED, 50, PI);
}
Colors(key kID, integer iAuth){
    Dialog(kID, "\n[Color Tester]", ["colormenu please"], [UPMENU], 0, iAuth, "Menu~Colors",0);
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llSubStringIndex(llToLower(sStr),llToLower(g_sSubMenu)) && llToLower(sStr) != "menu "+llToLower(g_sSubMenu)) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        g_lOwner=[];
        g_lTrust=[];
        g_lBlock=[];
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        /// [prefix] g_sSubMenu sChangetype sChangevalue
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;
key g_kTmpScan;
integer g_iTmpAuth;
default
{
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
    }
    sensor(integer n){
        list lIDS = [];
        integer i=0;
        for(i=0;i<n;i++){
            lIDS += llDetectedKey(i);
        }
        string sAppend;
        if(g_iSorted)sAppend="Sort";
        
        Dialog(g_kTmpScan, "\n[Object ID Test]", lIDS, [UPMENU],0,g_iTmpAuth, "Menu~Objs"+sAppend,g_iSorted);
    }
    
    no_sensor(){
        string sAppend="";
        if(g_iSorted)sAppend="Sort";
        Dialog(g_kTmpScan, "\n[Object ID Test]\n\nNothing found", [], [UPMENU], 0, g_iTmpAuth, "Menu~Objs", g_iSorted);
    }
    
    
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else if(sMsg == "LongText"){
                        LongTester(kAv,iAuth);
                    } else if(sMsg == "UUID-Avs"){
                        AvsTester(kAv,iAuth);
                    } else if(sMsg == "UUID-Objs"){
                        ObjsTester(kAv,iAuth);
                    } else if(sMsg == "ColorMenu"){
                        Colors(kAv,iAuth);
                    } else if(sMsg == "ObjsSorted"){
                        ObjsSortTester(kAv,iAuth);
                    }
                } else if(sMenu == "Menu~LongText"){
                    if(sMsg == UPMENU){
                        Menu(kAv,iAuth);
                        return;
                    } else {
                        llSay(0, "You selected: "+sMsg);
                    }
                    
                    
                    LongTester(kAv,iAuth);
                } else if(sMenu == "Menu~Avs"){
                    if(sMsg == UPMENU){
                        Menu(kAv,iAuth);
                        return;
                    }else{
                        llSay(0, "You selected: "+sMsg);
                    }
                    AvsTester(kAv,iAuth);
                } else if(sMenu == "Menu~Objs"){
                    if(sMsg == UPMENU){
                        Menu(kAv,iAuth);
                        return;
                    }else{
                        llSay(0, "You selected: "+sMsg);
                    }
                    
                    ObjsTester(kAv,iAuth);
                }else if(sMenu == "Menu~Colors"){
                    if(sMsg == UPMENU){
                        Menu(kAv,iAuth);
                        return;
                    }else{
                        llSay(0, "You selected: "+sMsg);
                    }
                    
                    Colors(kAv,iAuth);
                } else if(sMenu == "Menu~ObjsSort"){
                    if(sMsg == UPMENU){
                        Menu(kAv,iAuth);
                        return;
                    } else {
                        llSay(0, "You selected: "+sMsg);
                    }
                    
                    ObjsSortTester(kAv,iAuth);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}
