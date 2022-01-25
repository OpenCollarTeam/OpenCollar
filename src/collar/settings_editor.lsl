/*
This file is a part of OpenCollar.
Copyright ©2020
: Contributors :
Aria (Tashia Redrose)
    *August 2020        -       *Created oc_states
                                *Due to significant issues with original implementation, States has been turned into a anti-crash
                                script instead of a script state manager.
                                *Repurpose oc_states to be anti-crash and a interactive settings editor.
Medea (Medea Destiny)
    *July 2021          -       *See issue #587: Added warning when script resets folders script that user should consider cleaning
                                up their #RLV 
    Sept 2021           -       Tighten timings and number of passes on reboot process and reduced sleep padding.                               
                                            
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_BLOCKED = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_NOACCESS=599;

integer TIMEOUT_READY = 30497;
integer TIMEOUT_REGISTER = 30498;
integer TIMEOUT_FIRED = 30499;

integer g_iVerbosityLevel = 1;


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

string g_sSubmenu = "EDITOR";

SettingsMenu(integer stridePos, key kAv, integer iAuth)
{
    if(g_iLoading){
        g_kMenuUser = kAv;
        g_iLastAuth = iAuth;
        llSetTimerEvent(1);
        return;
    }            
            
    string sText = "OpenCollar - Interactive Settings editor";
    list lBtns = [];
    if(iAuth != CMD_OWNER){
        sText+="\n\nOnly owner may use this feature";
        Dialog(kAv, sText, [], [UPMENU], 0, iAuth, "Menu~Main");
        return;
    }
    if(stridePos == 0){
        integer i=0;
        integer end = llGetListLength(g_lSettings);
        for(i=0;i<end;i+=3){
            if(llListFindList(lBtns,[llList2String(g_lSettings,i)])==-1)lBtns+=llList2String(g_lSettings,i);
        }                         
        sText+="\nCurrently viewing Tokens";
    } else if(stridePos==1){
        integer i=0;
        integer end = llGetListLength(g_lSettings);
        for(i=0;i<end;i+=3){
            if(llList2String(g_lSettings,i)==g_sTokenView){
                lBtns+=llList2String(g_lSettings,i+1);
            }
        }        
        sText+="\nCurrently viewing Variables for token '"+g_sTokenView+"'";
    } else if(stridePos == 2){
        integer iPos = llListFindList(g_lSettings,[g_sTokenView,g_sVariableView]);
        if(iPos==-1){
            // cannot do it
            lBtns=[];
            sText+="\nCurrently viewing the variable '"+g_sTokenView+"_"+g_sVariableView+"'\nNo data found";
        } else {
            lBtns = ["DELETE", "MODIFY"];
            sText = "\nCurrently viewing the variable '"+g_sTokenView+"_"+g_sVariableView+"'\nData contained in var: "+llList2String(g_lSettings, iPos+2);
        }
    } else if(stridePos==3){
        integer iPos = llListFindList(g_lSettings,[g_sTokenView,g_sVariableView]);
        sText+="\n\nPlease enter a new value for: "+g_sTokenView+"_"+g_sVariableView+"\n\nCurrent value: "+llList2String(g_lSettings, iPos+2);
        lBtns =[];
    } else if(stridePos==8){
        sText+= "\n\nPlease enter the token name";
        lBtns=[];
    } else if(stridePos == 9){
        sText += "\n\nPlease enter the variable name for '"+g_sTokenView;
        lBtns=[];
    }
    
    g_iLastStride=stridePos;
    Dialog(kAv, sText,lBtns, llCSV2List(llList2String(["+ NEW,"+UPMENU,""],lBtns==[])), 0, iAuth, "settings~edit~"+(string)stridePos);
    
}

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}
list g_lSettings;
integer g_iLoading;
//key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
//list g_lOwner;
//list g_lTrust;
key g_kMenuUser;
integer g_iLastAuth;
//list g_lBlock;
string g_sVariableView;
//integer g_iLocked=FALSE;
string g_sTokenView="";
integer g_iLastStride;
//integer g_iWaitMenu;


integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    state_entry()
    {
    }
    
    timer(){
        if(!g_iLoading){
            llSetTimerEvent(0);
            SettingsMenu(0,g_kMenuUser,g_iLastAuth);
        }
    }           
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT && sStr == "reboot --f")llResetScript();
        
        if(iNum>=CMD_OWNER && iNum <= CMD_EVERYONE){
            if(llToLower(sStr)=="settings edit" || sStr=="menu "+g_sSubmenu){
                SettingsMenu(0,kID,iNum);
            }
        } else if(iNum == MENUNAME_REQUEST && sStr == "Settings") {
            llMessageLinked(iSender, MENUNAME_RESPONSE, "Settings|"+g_sSubmenu,"");
        } else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRemenu=FALSE;
                
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU){
                        iRemenu=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu Settings", kAv);
                    }
                } else if(sMenu == "settings~edit~0"){
                    if(sMsg == UPMENU){
                        llMessageLinked(LINK_SET, iAuth, "menu Settings", kAv);
                        return;
                    } else if(sMsg == "+ NEW"){
                        SettingsMenu(8, kAv, iAuth);
                        return;
                    }
                    if(sMsg == "intern" || sMsg == "auth"){
                        llMessageLinked(LINK_SET, NOTIFY, "0Editing of the "+sMsg+" token is prohibited by the security policy", kAv);
                        SettingsMenu(0, kAv, iAuth);
                    } else {
                        g_sTokenView=sMsg;
                        SettingsMenu(1, kAv,iAuth);
                    }
                } else if(sMenu == "settings~edit~1"){
                    if(sMsg==UPMENU){
                        SettingsMenu(0,kAv,iAuth);
                        return;
                    }else if(sMsg == "+ NEW"){
                        SettingsMenu(9, kAv, iAuth);
                        return;
                    }
                    
                    g_sVariableView=sMsg;
                    SettingsMenu(2, kAv,iAuth);
                    
                } else if(sMenu == "settings~edit~2"){
                    if(sMsg == UPMENU){
                        SettingsMenu(1,kAv,iAuth);
                        return;
                    } else if(sMsg == "DELETE"){
                        integer iPosx = llListFindList(g_lSettings,[g_sTokenView,g_sVariableView]);
                        if(iPosx==-1){
                            SettingsMenu(2,kAv,iAuth);
                            return;
                        }
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sTokenView+"_"+g_sVariableView,"");
                        llMessageLinked(LINK_SET, RLV_REFRESH,"","");
                        llMessageLinked(LINK_SET, NOTIFY, "1"+g_sTokenView+"_"+g_sVariableView+" has been deleted from settings", kAv);
                        g_iLoading=TRUE;
                        g_lSettings=[];
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL","");
                        SettingsMenu(0,kAv,iAuth);
                        //llSetTimerEvent(1);
                        return;
                    } else if(sMsg == "MODIFY"){
                        SettingsMenu(3, kAv,iAuth);
                    }
                } else if(sMenu == "settings~edit~3"){
                    if(sMsg == UPMENU){
                        SettingsMenu(2,kAv,iAuth);
                    } else {
                        integer iPosx = llListFindList(g_lSettings, [g_sTokenView, g_sVariableView]);
                        if(iPosx == -1)SettingsMenu(2,kAv,iAuth);
                        else{
                            g_lSettings = llListReplaceList(g_lSettings, [sMsg], iPosx+2,iPosx+2);
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sTokenView+"_"+g_sVariableView+"="+sMsg,"");
                            llMessageLinked(LINK_SET, NOTIFY, "1Settings modified: "+g_sTokenView+"_"+g_sVariableView+"="+sMsg,kAv);
                            SettingsMenu(1,kAv,iAuth);
                            return;
                        }
                    }
                } else if(sMenu == "settings~edit~8"){
                    g_sTokenView=sMsg;
                    SettingsMenu(9, kAv,iAuth);
                } else if(sMenu == "settings~edit~9"){
                    g_sVariableView=sMsg;
                    g_lSettings += [g_sTokenView,g_sVariableView,"not set"];
                    
                    SettingsMenu(3, kAv,iAuth);
                }
            }
            
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lSettings,0);
            string sVar = llList2String(lSettings,1);
            string sVal = llList2String(lSettings, 2);
            if(sToken == "global"){
                if(sVar == "verbosity"){
                    g_iVerbosityLevel = (integer)sVal;
                }
            }
                            
            if(sStr == "settings=sent"){
                g_iLoading=FALSE;
                return;
            }
                  
            if(llListFindList(g_lSettings, [sToken, sVar, sVal]) == -1 )g_lSettings+=[sToken, sVar, sVal];
        
        }
    }
}
