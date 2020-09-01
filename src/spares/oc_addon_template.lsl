/*
THIS FILE IS HEREBY RELEASED UNDER THE Public Domain
This script is released public domain, unlike other OC scripts for a specific and limited reason, because we want to encourage third party plugin creators to create for OpenCollar and use whatever permissions on their own work they see fit.  No portion of OpenCollar derived code may be used excepting this script,  without the accompanying GPLv2 license.
-Authors Attribution-
Aria (tiff589) - (August 2020)
*/


integer API_CHANNEL = 0x60b97b5e;

list g_lCollars;
string g_sAddon = "Test Addon";


integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_BLOCKED = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value


integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

list g_lMenuIDs;
integer g_iMenuStride;

string UPMENU="BACK";
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    
    llRegionSayTo(g_kCollar,API_CHANNEL, llList2Json(JSON_OBJECT, ["pkt_type", "from_addon", "addon_name", g_sAddon, "iNum", DIALOG, "sMsg", (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, "kID", kMenuID]));

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Menu App]";
    list lButtons = ["A Button"];
    
    //llSay(0, "opening menu");
    Dialog(kID, sPrompt, lButtons, ["DISCONNECT", UPMENU], 0, iAuth, "Menu~Main");
}


UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llSubStringIndex(llToLower(sStr),llToLower(g_sAddon)) && llToLower(sStr) != "menu "+llToLower(g_sAddon)) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        return;
    }
    if (llToLower(sStr)==llToLower(g_sAddon) || llToLower(sStr) == "menu "+llToLower(g_sAddon)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        
    }
}
Link(string packet, integer iNum, string sStr, key kID){
    string pkt = llList2Json(JSON_OBJECT, ["pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID]);
    if(g_kCollar!= "" || g_kCollar!= NULL_KEY) 
        llRegionSayTo(g_kCollar, API_CHANNEL, pkt);
    else
        llRegionSay(API_CHANNEL, pkt);
}
key g_kCollar;
default
{
    state_entry()
    {
        API_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
        llListen(API_CHANNEL, "", "", "");
    }
    
    touch_start(integer t){
        // Send a settings request to the collar
        //llSay(0, "Packet sent to collar");
        g_kCollar=llDetectedKey(0);
        Link("online", 0, (string)llGetCreator(), llDetectedKey(0)); // todo: make collar actually use the kID value to filter who the addon is trying to ping. also todo: make sStr the creator value, to filter out wearer created addons by a optional settings flag.

        g_kCollar=""; // todo: replace this when a signal is added to tell the addon the collar accepted it

//        llWhisper(API_CHANNEL, llList2Json(JSON_OBJECT, ["pkt_type", "online", "addon_name", g_sAddon, "bridge", FALSE]));
    }
    
    listen(integer c,string n,key i,string m){
        //llWhisper(0, "message from collar: "+m);
        if(llJsonGetValue(m,["pkt_type"])=="ping"){
            if(g_kCollar==i){
                Link("pong", 0,"","");
            }
        } else if(llJsonGetValue(m,["pkt_type"])=="approved"){
            // request settings
            Link("from_addon", LM_SETTING_REQUEST, "ALL","");
        } else if(llJsonGetValue(m,["pkt_type"])=="from_collar"){
            // process link message if in range of addon
            if(llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(i, [OBJECT_POS]),0))<=10.0){
                // process it!
                if(g_kCollar == "" || g_kCollar==NULL_KEY)g_kCollar=i;
                else if(g_kCollar!=i)return;
                integer iNum = (integer)llJsonGetValue(m,["iNum"]);
                string sStr = llJsonGetValue(m,["sMsg"]);
                key kID = (key)llJsonGetValue(m,["kID"]);
                
                if(iNum == LM_SETTING_RESPONSE){
                    list lPar = llParseString2List(sStr, ["_","="],[]);
                    string sToken = llList2String(lPar,0);
                    string sVar = llList2String(lPar,1);
                    string sVal = llList2String(lPar,2);
                    
                    if(sToken == "auth"){
                        if(sVar == "owner"){
                            llSay(0, "owner values is: "+sVal);
                        }
                    }
                } else if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE){
                    UserCommand(iNum, sStr, kID);
                    
                } else if (iNum == DIALOG_TIMEOUT) {
                    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
                    g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
                }else if(iNum == DIALOG_RESPONSE){
                    integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
                    if(iMenuIndex!=-1){
                        string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                        g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                        list lMenuParams = llParseString2List(sStr, ["|"],[]);
                        key kAv = llList2Key(lMenuParams,0);
                        string sMsg = llList2String(lMenuParams,1);
                        integer iAuth = llList2Integer(lMenuParams,3);
                        
                        if(sMenu == "Menu~Main"){
                            if(sMsg == UPMENU) Link("from_addon", iAuth, "menu Addons", kAv);
                            else if(sMsg == "A Button") llSay(0, "This is a example addon.");
                            else if(sMsg == "DISCONNECT"){
                                Link("offline", 0, "","");
                                g_lMenuIDs=[];
                            }
                        }
                    }
                }
            }else{
                if(g_kCollar==i)g_kCollar="";
            }
        }
    }
}
