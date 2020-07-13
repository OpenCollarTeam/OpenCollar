  
/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :

Aria (Tashia Redrose)
    *June 2020       -       Created oc_core
      * This combines oc_com, oc_auth, and oc_sys
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/


string g_sParentMenu = "";
string g_sSubMenu = "Main";
string COLLAR_VERSION = "8.0.0000"; // Provide enough room
integer UPDATE_AVAILABLE=FALSE;
string NEW_VERSION = "";
integer g_iAmNewer=FALSE;


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
integer CMD_NOACCESS=599;

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

list g_lMainMenu=["Plugins", "Addons", "Access", "Settings", "Help/About"];

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}
integer g_iHide=FALSE;
Settings(key kID, integer iAuth){
    string sPrompt = "OpenCollar\n\n[Settings]";
    list lButtons = ["Print", "Load", "Fix Menus", "Resize", Checkbox(g_iHide, "Hide")];
    Dialog(kID, sPrompt, lButtons, [UPMENU],0,iAuth, "Menu~Settings");
}
Menu(key kID, integer iAuth) {
    string sPrompt = "\nOpenCollar "+COLLAR_VERSION;
    list lButtons = [Checkbox(g_iLocked, "Lock")]+g_lMainMenu;
    
    if(UPDATE_AVAILABLE ) sPrompt += "\n\nUPDATE AVAILABLE: Your version is: "+COLLAR_VERSION+", The current release version is: "+NEW_VERSION;
    if(g_iAmNewer)sPrompt+="\n\nYour collar version is newer than the public release. This may happen if you are using a beta or pre-release copy.\nNote: Pre-Releases may have bugs";
    Dialog(kID, sPrompt, lButtons, [], 0, iAuth, "Menu~Main");
}
key g_kGroup = "";
integer g_iLimitRange=TRUE;
integer g_iPublic=FALSE;
AccessMenu(key kID, integer iAuth){
    string sPrompt = "\nOpenCollar Access Controls";
    list lButtons = ["+ Owner", "+ Trust", "+ Block", "- Owner", "- Trust", "- Block", Checkbox(bool((g_kGroup!="")), "Group"), Checkbox(g_iPublic, "Public")];

    lButtons += [Checkbox(g_iLimitRange, "Limit Range"), "Runaway", "Access List"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Auth");
}

HelpMenu(key kID, integer iAuth){
    string sPrompt = "\nOpenCollar "+COLLAR_VERSION+"\nVersion: "+setor(g_iAmNewer, "(Newer than release)", "")+" "+setor(UPDATE_AVAILABLE, "(Update Available)", "(Most current version)");
    list lButtons = ["Update"];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Help");
}

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["⬜","⬛"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}
    
UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        return;
    }
    if (sStr==g_sSubMenu || sStr == "menu "+g_sSubMenu || sStr == "menu") Menu(kID, iNum);
    if(sStr == "Access" || sStr == "menu Access") AccessMenu(kID,iNum);
    if(sStr == "Settings" || sStr == "menu Settings")Settings(kID,iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        string sText;
        if(sChangetype=="fix"){
            g_lMainMenu = ["-", "Plugins", "Addons", "Leash", "Access", "Settings", "Help/About"];
            
            llMessageLinked(LINK_SET,0,"initialize","");
        }
    }
}

key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
integer g_iLocked=FALSE;
Compare(string V1, string V2){
    NEW_VERSION=V2;
    
    if(V1==V2){
        UPDATE_AVAILABLE=FALSE;
        return;
    }
    V1 = llDumpList2String(llParseString2List(V1, ["."],[]),"");
    V2 = llDumpList2String(llParseString2List(V2, ["."],[]), "");
    integer iV1 = (integer)V1;
    integer iV2 = (integer)V2;
    
    if(iV1 < iV2){
        UPDATE_AVAILABLE=TRUE;
    } else if(iV1 == iV2) return;
    else if(iV1 > iV2){
        UPDATE_AVAILABLE=FALSE;
        g_iAmNewer=TRUE;
        
        llSetText("", <1,0,0>,1);
    }
}

key g_kUpdateCheck = NULL_KEY;
DoCheckUpdate(){
    g_kUpdateCheck = llHTTPRequest("https://raw.githubusercontent.com/OpenCollarTeam/OpenCollar/master/web/version.txt",[],"");
}


///The setor method is derived from a similar PHP proposed function, though it was denied, 
///https://wiki.php.net/rfc/ifsetor
///The concept is roughly the same though we're not dealing with lists in this method, so is just modified
///The ifsetor proposal would give a function which would be more like
///ifsetor(list[index], sTrue, sFalse)
///LSL can't check if a list item is set without a stack heap if it is out of range, this is significantly easier for us to just check for a integer boolean
string setor(integer iTest, string sTrue, string sFalse){
    if(iTest)return sTrue;
    else return sFalse;
}
default
{
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
        
        llSleep(15);
        llMessageLinked(LINK_SET, REBOOT, "reboot", "");// Reboot after 15 seconds
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        
        llMessageLinked(LINK_SET, 0, "initialize", llGetKey());
    }
    touch_start(integer iNum){
        llMessageLinked(LINK_SET, 0, "menu", llDetectedKey(0)); // Temporary until API v8's implementation is done, use v7 in the meantime
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_RESPONSE){
            list lPara = llParseString2List(sStr, ["|"],[]);
            string sName = llList2String(lPara,0);
            string sMenu = llList2String(lPara,1);
            if(sName == "Main"){
                if(llListFindList(g_lMainMenu, [sMenu])==-1){
                    g_lMainMenu = [sMenu] + g_lMainMenu;
                }
            }
        } else if(iNum == MENUNAME_REMOVE){
            // This is not really used much if at all in 7.x
            
            list lPara = llParseString2List(sStr, ["|"],[]);
            string sName = llList2String(lPara,0);
            string sMenu = llList2String(lPara,1);
            if(sName=="Main"){
                integer loc = llListFindList(g_lMainMenu, [sMenu]);
                if(loc!=-1){
                    g_lMainMenu = llDeleteSubList(g_lMainMenu, loc,loc);
                }
            }
            
        }
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
                    if(sMsg == "Access"){
                        iRespring=FALSE;
                        AccessMenu(kAv,iAuth);
                    } else if(sMsg == "Settings"){
                        iRespring=FALSE;
                        Settings(kAv,iAuth);
                    } else if(sMsg=="Help/About"){
                        iRespring=FALSE;
                        HelpMenu(kAv,iAuth);
                    } else {
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth,"menu "+ sMsg, kAv);
                    }
                     
                    
                    if(iRespring)Menu(kAv,iAuth);
                } else if(sMenu=="Menu~Auth"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else if(llGetSubString(sMsg,0,0) == "+"){
                        if(iAuth == CMD_OWNER){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "add "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        }
                        else
                            llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to adding a person", kAv);
                    } else if(llGetSubString(sMsg,0,0)=="-"){
                        if(iAuth == CMD_OWNER){
                            iRespring=FALSE;
                            llMessageLinked(LINK_SET, iAuth, "rem "+llToLower(llGetSubString(sMsg,2,-1)), kAv);
                        } else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to removing a person", kAv);
                    } else if(sMsg == "Access List"){
                        llMessageLinked(LINK_SET, iAuth, "print auth", kAv);
                    } else if(sMsg == Checkbox(bool((g_kGroup!="")), "Group")){
                        if(g_kGroup!=""){
                            g_kGroup="";
                            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_group", "");
                        }else{
                            g_kGroup = llList2Key(llGetObjectDetails(llGetKey(), [OBJECT_GROUP]),0);
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_group="+(string)g_kGroup, "");
                        }
                    } else if(sMsg == Checkbox(g_iPublic, "Public")){
                        g_iPublic=1-g_iPublic;
                        
                        if(g_iPublic)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_public=1", "");
                        else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_public","");
                    } else if(sMsg == Checkbox(g_iLimitRange, "Limit Range")){
                        g_iLimitRange=1-g_iLimitRange;
                        
                        if(g_iLimitRange)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "auth_limitrange=1","");
                        else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "auth_limitrange", "");
                    }
                    
                    
                    if(iRespring)AccessMenu(kAv,iAuth);
                } else if(sMenu == "Menu~Settings"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv, iAuth);
                    } else if(sMsg == "Print"){
                        llMessageLinked(LINK_SET, iAuth, "print settings", kAv);
                    } else if(sMsg == "Fix Menus"){
                        llMessageLinked(LINK_SET, iAuth, "fix", kAv);
                        llMessageLinked(LINK_SET, NOTIFY, "0Menus have been fixed", kAv);
                    } else if(sMsg == Checkbox(g_iHide,"Hide")){
                        g_iHide=1-g_iHide;
                        llMessageLinked(LINK_SET, iAuth, setor(g_iHide, "hide", "show"), kAv);
                    } else if(sMsg == "Load"){
                        llMessageLinked(LINK_SET, iAuth, sMsg, kAv);
                    } else if(sMsg == "Resize"){
                        // Resizer!!
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu Size/Position", kAv);
                    }
                    
                    
                    
                    if(iRespring)Settings(kAv,iAuth);
                } else if(sMenu == "Menu~Help"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    }
                    
                    if(iRespring)HelpMenu(kAv,iAuth);
                }
            }
        } else if(iNum == LM_SETTING_RESPONSE){
            list lPar = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            string sVal = llList2String(lPar,2);
            
            
            if(sToken=="global"){
                if(sVar=="locked"){
                    g_iLocked=(integer)sVal;
                }
            } else if(sToken == "auth"){
                if(sVar == "group"){
                    g_kGroup=(key)sVal;
                } else if(sVar == "public"){
                    g_iPublic = (integer)sVal;
                } else if(sVar == "limitrange"){
                    g_iLimitRange=(integer)sVal;
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            list lPar = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            
            if(sToken=="global"){
                if(sVar == "locked") g_iLocked=FALSE;
            } else if(sToken == "auth"){
                if(sVar == "group")g_kGroup="";
                else if(sVar == "public")g_iPublic=FALSE;
                else if(sVar == "limitrange")g_iLimitRange=TRUE;
            }
        } else if(iNum == REBOOT){
            if(sStr=="reboot"){
                llResetScript();
            }
        
        } else if(iNum == 0){
            // Auth request!
            if(sStr=="initialize"){
                llMessageLinked(LINK_SET, MENUNAME_REQUEST, g_sSubMenu, "");
                
                DoCheckUpdate();
            }
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
    http_response(key kRequest, integer iStatus, list lMeta, string sBody){
        if(iStatus==200)
            Compare(COLLAR_VERSION, sBody);
        else
            llOwnerSay("Could not check for an update. The server returned a unknown status code");
    }
}
