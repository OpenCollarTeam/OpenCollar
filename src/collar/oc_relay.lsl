/*
This file is a part of OpenCollar.
Copyright 2020

: Contributors :
Aria (Tashia Redrose)
    * Mar 2020      - Wrote collar plugin for Turbo Relay

et al.

Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


string g_sParentMenu = "RLV";
string g_sSubMenu = "Relay";
string g_sScriptVersion="7.4";
integer LINK_CMD_DEBUG=1999;
integer g_iRelayWorn = FALSE;

DebugOutput(key kDest, list lParams){
    llInstantMessage(kDest, llGetScriptName()+": "+llDumpList2String(lParams," "));
}
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS = 599;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[RLV Relay - Turbo Relay App]\n\n";
    if(g_iRelayWorn)sPrompt+="Relay is worn\n";
    else sPrompt+="Relay is not currently worn\n";
    
    sPrompt+= "Relay Mode: ";
    sPrompt += RelayMode2Str();
    
    
    list lButtons = ["Mode", "Safeword", "Get Relay",  "About"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

string RelayMode2Str(){
    string sPrompt;
    
    if(g_iMode==-1)sPrompt+="OFF";
    else if(g_iMode==0)sPrompt += "ASK";
    else if(g_iMode == 1) sPrompt += "Semi-Auto";
    else if(g_iMode == 2) sPrompt += "Auto (w/Blocks)";
    else if(g_iMode == 3) sPrompt += "Auto (w/oBlocks)";
    else sPrompt += "UNKNOWN";
    
    return sPrompt;
}


ModeMenu(key kID, integer iAuth){
    list lButtons = ["Ask", "Auto (w/Blocks)", "Auto (w/oBlocks)", "Semi-Auto", "OFF"];
    string sPrompt = "\n[RLV Relay - Turbo Relay App]\nCurrent Mode: "+RelayMode2Str()+"\n\nAsk\nSemi-Auto\tAuto Force, Ask Restrictions\nAuto (w/Blocks)\tAuto mode, but includes blacklist\nAuto (w/oBlocks)\tAuto mode with no blacklist (CAUTION)";

    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Mode");
}

SafewordMenu(key kID, integer iAuth){
    string sPrompt = "\n[RLV Relay - Turbo Relay App]\n\nCurrent safeword : "+g_sSafewordType;
    list lButtons = [">Instant<", ">SafewordOff<", ">Confirm<"];
    if(g_sSafewordType != "Hardcore"){
        lButtons += ["Safeword!"];
    }
    
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~SW");
}

ConfirmSW(key kID, integer iAuth){
    Dialog(kID, "Are you sure you want to safeword the relay?", ["Yes", "No"], [], 0, iAuth, "Conf~SW");
} 

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llSubStringIndex(sStr,llToLower(g_sSubMenu)) && sStr != "menu "+g_sSubMenu) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (sStr==g_sSubMenu || sStr == "menu "+g_sSubMenu) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
       // integer iWSuccess = 0; 
       // string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
       // string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
       // string sText;
        
    }
}

string g_sSafewordType = "Instant"; // Default safeword is instant
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
string g_sSafeword="RED";
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;

integer g_iMode=0;
integer g_iJustSaved=FALSE;
string RELAY_TOKEN = "relay_";
Commit(){
    // Save settings
    g_iJustSaved=TRUE;
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, RELAY_TOKEN + "mode="+(string)g_iMode, "");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, RELAY_TOKEN + "safewordType="+g_sSafewordType, "");
    
    // Send to relay
    Send();
}

Send(){
    // We only get values back from 'get', no acknowledgement is needed for a set operation
    llSay(CMD_RLV_RELAY, llList2Json(JSON_OBJECT, ["type", "mode", "cmd", "set", "value", g_iMode]));
}

SendSW(){
    llSay(CMD_RLV_RELAY, llList2Json(JSON_OBJECT, ["type", "none", "cmd", "safeword"]));
}

integer g_iRelayListener;
integer g_iHaveSettings;

SafewordChecks(key kID, integer iAuth){
    
    if(iAuth == CMD_OWNER){
        SendSW();
        SafewordMenu(kID, iAuth);
        return;
    } else if(iAuth == CMD_WEARER){
        // wearer, perform checks below
    }else{
        llMessageLinked(LINK_SET, NOTIFY, "0Only wearer or owner can execute the safeword", kID);
        SafewordMenu(kID, iAuth);
        return;
    }
    // check safeword mode, and act accordingly
    if(g_sSafewordType == "Instant"){
        SendSW();
    } else if(g_sSafewordType == "ConfirmSW"){
        ConfirmSW(kID, iAuth);
        return;
    } else if(g_sSafewordType == "Hardcore"){
        llMessageLinked(LINK_SET, NOTIFY, "0Safeword is disabled for relay. If you must, you can always use the collar safeword, which will release and deactivate the relay instantly.\n\n[Your current collar safeword is: '"+g_sSafeword+"']", kID);
        
    }
    
    SafewordMenu(kID, iAuth);
}
default
{
    on_rez(integer t){
        llResetScript(); // Restart pairing with relay
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "global_locked","");
        g_iRelayListener = llListen(CMD_RLV_RELAY, "", "", "");
        llSay(CMD_RLV_RELAY, llList2Json(JSON_OBJECT, ["type", "none", "cmd", "CONNECT"])); // Asks if there is a near relay, and tells it to connect. 
        // Relay will then download settings from the collar.
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
    }
    listen(integer iChannel, string sName, key kID, string sMsg){
        if(llGetOwnerKey(kID) == llGetOwner()){
            // proceed
            if(llJsonGetValue(sMsg, ["type"]) == "connect"){
                if(llJsonGetValue(sMsg, ["cmd"]) == "download"){
                    if(g_iHaveSettings) Send();
                    else llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
                    
                    g_iRelayWorn=TRUE;
                    
                }
            } else if(llJsonGetValue(sMsg, ["type"]) == "disconnect"){
                g_iRelayWorn=FALSE;
            } else if(llJsonGetValue(sMsg, ["type"]) == "update"){
                if(g_iHaveSettings)Send();
                else llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
            } else if(llJsonGetValue(sMsg, ["type"]) == "prompt"){
                Dialog(llGetOwner(), "[Relay]\n\n"+llJsonGetValue(sMsg, ["prompt"]), ["Yes", "No", "Blacklist"], [], 0, CMD_NOACCESS, "Conf~Relay");
            }
        }
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
                
                integer iRespring=TRUE;
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU) {
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    } else if(sMsg == "Mode"){
                        iRespring=FALSE;
                        ModeMenu(kAv, iAuth);
                    } else if(sMsg == "Safeword"){
                        // Open safeword menu
                        SafewordMenu(kAv, iAuth);
                        iRespring=FALSE;
                    } else if(sMsg == "Get Relay"){
                        llGiveInventory(kAv, "Turbo Safety RLV Relay");
                    } else if(sMsg == "About"){
                        llMessageLinked(LINK_SET, NOTIFY, "0The Turbo RLV Relay is written by secondlife:///app/agent/c9d1c876-b65f-4c59-84e2-5c492f94ad11/about and secondlife:///app/agent/5033978d-44f1-4177-9333-a0c9115fddeb/about\nThe contributors to OpenCollar's relay app can be viewed by looking at the copyright section of this script ("+llGetScriptName()+")", kAv);
                    }
                    
                    if(iRespring)
                        Menu(kAv, iAuth);
                } else if(sMenu == "Menu~Mode"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    }
                    
                    if(iAuth == CMD_OWNER){
                        
                        if(sMsg == "OFF") {
                            g_iMode=-1;
                        } else if(sMsg == "Ask"){
                            g_iMode=0;
                        } else if(sMsg == "Semi-Auto"){
                            g_iMode=1;
                        } else if(sMsg == "Auto (w/Blocks)"){
                            g_iMode=2;
                        } else if(sMsg == "Auto (w/oBlocks)"){
                            g_iMode=3;
                        }
                        
                        
                        Commit();
                    }else{
                        llMessageLinked(LINK_SET, NOTIFY, "0Only owner can change the relay mode", kAv);
                    }
                    
                    if(iRespring)
                        ModeMenu(kAv, iAuth);
                        
                        
                } else if(sMenu == "Menu~SW"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                    }
                    
                    if(iAuth == CMD_OWNER){
                        if(sMsg == ">Instant<") g_sSafewordType = "Instant";
                        else if(sMsg == ">Confirm<") g_sSafewordType = "ConfirmSW";
                        else if(sMsg == ">SafewordOff<")g_sSafewordType = "Hardcore";
                        
                        Commit();
                    }
                    
                    if(sMsg == "Safeword!"){
                        // Execute safeword
                        SafewordChecks(kAv,iAuth);
                        iRespring=FALSE;
                        //llSay(CMD_RLV_RELAY, llList2Json(JSON_OBJECT, ["type", "none", "cmd", "safeword"]));
                    }
                    
                    if(iRespring)
                        SafewordMenu(kAv, iAuth);
                } else if(sMenu == "Conf~SW"){
                    if(sMsg == "Yes"){
                        SendSW();
                    } else if(sMsg == "No"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Safeword canceled.", kAv);
                        if(iAuth!=CMD_NOACCESS)
                            SafewordMenu(kAv, iAuth);
                    }
                } else if(sMenu == "Conf~Relay"){
                    string V;
                    if(sMsg == "Yes"){
                        V="y";
                    } else if(sMsg == "No"){
                        V="n";
                    } else if(sMsg == "Blacklist"){
                        V="b";
                    }                        
                        
                    llSay(CMD_RLV_RELAY, llList2Json(JSON_OBJECT, ["type", "prompt_reply", "answer", V]));
                        
                }
            }
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "safeword"){
                    g_sSafeword=llList2String(lSettings,2);
                }
            } else if(llList2String(lSettings,0) == llGetSubString(RELAY_TOKEN,0,-2)){
                if(llList2String(lSettings,1) == "mode"){
                    g_iMode=(integer)llList2String(lSettings,2);
                } else if(llList2String(lSettings,1) == "safewordType"){
                    g_sSafewordType = llList2String(lSettings,2);
                }
            }
            
            if(sStr == "settings=sent"){
                g_iHaveSettings=TRUE;
                if(llGetTime()>=10)Send();
                
                llResetTime(); // don't spam the wearer or the relay!
            }
            else g_iHaveSettings=FALSE;
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="global")
                if(llList2String(lSettings,1) == "locked") g_iLocked=FALSE;
        } else if(iNum == CMD_SAFEWORD){
            SendSW();
            llMessageLinked(LINK_SET, NOTIFY, "0Collar Safeword used. Relay disabled for 30 seconds!", llGetOwner());
            llSay(CMD_RLV_RELAY, llList2Json(JSON_OBJECT, ["type", "mode", "cmd", "set", "value", -1]));
            llSleep(30);
            Send();
            llMessageLinked(LINK_SET, NOTIFY, "0Relay has been set back to its original mode", llGetOwner());
        } else if (iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            DebugOutput(kID, ["VERSION:", g_sScriptVersion]);
            if(onlyver)return;
            
            DebugOutput(kID, ["MODE:", g_iMode]);
            DebugOutput(kID, ["SAFEWORD TYPE:", g_sSafewordType]);
        } else if(iNum == REBOOT && sStr == "reboot")llResetScript();
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}