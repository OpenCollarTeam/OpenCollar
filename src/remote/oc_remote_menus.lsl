  
/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :

Aria (Tashia Redrose)
    * December 2020       -       Recreated oc_Remote
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

list g_lMenuIDs;
integer g_iMenuStride;

string UPMENU="BACK";
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    
    LM("from_addon", DIALOG, (string)kID+"|"+sPrompt+"|"+(string)iPage+"|"+llDumpList2String(lChoices, "`")+"|"+llDumpList2String(lUtilityButtons, "`")+"|"+(string)iAuth, kMenuID);
    //llRegionSayTo(g_kCollar,llList2Integer(g_lAPIListeners,0), llList2Json(JSON_OBJECT, ["pkt_type", "from_addon", "addon_name", g_sAddon, "iNum", DIALOG, "sMsg", (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, "kID", kMenuID]));

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[OpenCollar Remote]";
    list lButtons = ["+ Favorite", "- Favorite"];
    
    //llSay(0, "opening menu");
    Dialog(kID, sPrompt, lButtons, ["DISCONNECT", UPMENU], 0, iAuth, "Menu~Main");
}

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


integer NOTIFY = 1002;
integer REBOOT = -1000;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

LM(string type, integer iNum, string sMsg, key kID)
{
    llMessageLinked(LINK_SET, 1, llList2Json(JSON_OBJECT, ["num", iNum, "msg", sMsg, "id", kID]), type);
}
string g_sAddon = "OC_Remote";


UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
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
        
        if(sChangetype == "remote")
        {
            Menu(kID, iNum);
        }
    }
}
default
{
    state_entry()
    {
        llOwnerSay("oc_remote_menus ready with "+(string)llGetFreeMemory()+" bytes free");
    }
    on_rez(integer t){llResetScript();}
    link_message(integer iSender, integer iNums, string sMsg, key kID)
    {
        if(iNums==0)
        {
            
            integer iNum = (integer)llJsonGetValue(sMsg,["iNum"]);
            string sStr = llJsonGetValue(sMsg,["sMsg"]);
            key kID = (key)llJsonGetValue(sMsg,["kID"]);
                
                
            if(iNum == LM_SETTING_RESPONSE){
                list lPar = llParseString2List(sStr, ["_","="],[]);
                string sToken = llList2String(lPar,0);
                string sVar = llList2String(lPar,1);
                string sVal = llList2String(lPar,2);
                    
                if(sToken == "auth"){
                    if(sVar == "owner"){
                        //llSay(0, "owner values is: "+sVal);
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
                        if(sMsg == UPMENU) LM("from_addon", iAuth, "menu Addons", kAv);
                        else if(sMsg == "+ Favorite"){
                            LM("from_addon", NOTIFY, "1New remote favorite added", llGetOwner());
                            llMessageLinked(LINK_SET, -2, "add", "");
                        }
                        else if(sMsg == "- Favorite"){
                            LM("from_addon", NOTIFY, "1Remote favorite removed", llGetOwner());
                            llMessageLinked(LINK_SET, -2, "rem", "");
                        }
                        else if(sMsg == "DISCONNECT"){
                            llMessageLinked(LINK_SET, -1, "", "");
                        }
                    }
                }
            }
        } else if(iNums ==-1){
            g_lMenuIDs=[];
            
        } else if(iNums==-10){
            llResetScript();
        }
    }
}
