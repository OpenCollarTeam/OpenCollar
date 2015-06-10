// Virtual Disgrace - Sobriquet - Version 1.5
// This software is property of Virtual Disgrace™.
// The rights of inspection, modification and redistribution
// for commercial means are exclusive to littlemousy, Wendy Starfall
// and other employees of Virtual Disgrace™ and www.virtualdisgrace.com

key     g_kMenuID;                             
key     g_kWearer;  
string g_sWearerName;
string g_sSettingToken = "sobriquet_";
string g_sGlobalToken = "global_";

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER                   = 500;
integer CMD_TRUSTED                 = 501;
//integer CMD_GROUP                 = 502;
integer CMD_WEARER                  = 503;
integer CMD_EVERYONE                = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD                = 510; 
//integer CMD_RELAY_SAFEWORD          = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY = 1002;

integer LM_SETTING_SAVE            = 2000; 
//integer LM_SETTING_REQUEST         = 2001;
integer LM_SETTING_RESPONSE        = 2002;
integer LM_SETTING_DELETE          = 2003;
//integer LM_SETTING_EMPTY           = 2004;
//integer LM_SETTING_REQUEST_NOCACHE = 2005;

integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
integer MENUNAME_REMOVE            = 3003;

integer RLV_CMD                    = 6000;
/*
integer RLV_REFRESH                = 6001; 
integer RLV_CLEAR                  = 6002; 
integer RLV_VERSION                = 6003; 
integer RLV_OFF                    = 6100; 
integer RLV_ON                     = 6101; 
integer RLV_QUERY                  = 6102; 
integer RLV_RESPONSE               = 6103; 
*/

integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer DIALOG_TIMEOUT             = -9002;

list g_lMenuIDs;
integer g_iMenuStride = 3;

integer g_iListenHandle;
integer g_iChannel;
integer g_iEnforce                 = 0;    //0 for off, auth number for on


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
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}
*/

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
} 

SobriquetMenu(key keyID, integer iAuth) {
    list lMyButtons = ["Rename"];
    if (g_iEnforce) lMyButtons+="☒ Enforce";
    else lMyButtons+="☐ Enforce";

    Dialog(keyID, "\n[http://www.virtualdisgrace.com/sobriquet Virtual Disgrace - Sobriquet]\n\nName: "+g_sWearerName, lMyButtons, ["BACK"], 0, iAuth, "SobriquetMenu");
}

RenameMenu(key keyID, integer iAuth) {
    Dialog(keyID, "\nEnter a name in the box and click Submit.\n\nSubmitting an empty box resets the name.", [], [], 0, iAuth, "RenameMenu");
}

SetSobriquet(integer newState, key kID){
    //Debug("SetSobriquet\nnewState:"+(string)newState+"\nkID:"+(string)kID+"\ng_iEnforce:"+(string)g_iEnforce);
    if (g_iEnforce && !newState) {
        if ((key)kID) llMessageLinked(LINK_SET,NOTIFY,"1"+"Sobriquet lifted.",kID);
        llListenRemove(g_iListenHandle);
        llMessageLinked(LINK_SET,RLV_CMD,"clear","VDsobriquet");
    } else if (!g_iEnforce && newState) {
        if (g_sWearerName!=""){
            if ((key)kID) llMessageLinked(LINK_SET,NOTIFY,"1"+"Sobriquet enforced.",kID);
            g_iChannel=2000000-(integer)llFrand(1000000);
            g_iListenHandle=llListen( g_iChannel, "", g_kWearer, "");
            llMessageLinked(LINK_SET,RLV_CMD,"sendchat=n,redirchat:"+(string)g_iChannel+"=add,rediremote:"+(string)g_iChannel+"=add","VDsobriquet");
        } else {
            if ((key)kID) llMessageLinked(LINK_SET,NOTIFY,"0"+"No name ser.",kID);
            newState = 0; //else it will be enforced though no name is set!!!
        }
    }
    g_iEnforce=newState;
}

UserCommand(integer iNum, string sStr, key kID, integer remenu) {
    string sStrLower=llToLower(sStr);
    if (sStrLower == "sobriquet" || sStrLower == "menu sobriquet") SobriquetMenu(kID, iNum);
    else if (llSubStringIndex(sStrLower,"sobriquet ")==0) {
        //Debug("sStrLower="+sStrLower);
        if (sStrLower=="sobriquet ☒ enforce"|| sStrLower == "sobriquet enforce off") {
            if (iNum <= CMD_TRUSTED ) {
                SetSobriquet(0,kID);
                llMessageLinked(LINK_THIS,LM_SETTING_DELETE,g_sSettingToken+"enforce","");
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
            if (remenu) SobriquetMenu(kID,iNum);
        } else if (sStrLower=="sobriquet ☐ enforce"|| sStrLower == "sobriquet enforce on") {
            if (iNum <= CMD_TRUSTED ) {
                SetSobriquet(iNum,kID);
                llMessageLinked(LINK_THIS,LM_SETTING_SAVE,g_sSettingToken+"enforce="+(string)iNum,"");
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
            if (remenu) SobriquetMenu(kID,iNum);
        }
        else if (sStrLower=="sobriquet rename") {
            if (iNum <= g_iEnforce || g_iEnforce == 0) {
                RenameMenu(kID,iNum);
            } else llMessageLinked(LINK_SET,NOTIFY,"0"+"%NOACCESS%",kID);
        }
    }
}

default {
    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer) llResetScript();
    }

    state_entry() {
        llSetMemoryLimit(32768); //2015-05-06 (12776 bytes free)
        g_kWearer = llGetOwner();
        SetSobriquet(0, g_kWearer);
        //Debug("Starting");
    }

    listen(integer channel, string name, key id, string message) { //can only be on our channel, from wearer
        string oldName = llGetLinkName(LINK_ROOT);
        llSetObjectName("");
        if (llGetSubString(message,0,2) == "/me") llSay(0,g_sWearerName + llGetSubString(message, 3, -1));
        else llSay(0, g_sWearerName +": " + message);
        llSetObjectName(oldName);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == "Apps") llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, "Apps|Sobriquet", "");
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sSettingToken+"enforce" ) SetSobriquet((integer)sValue,"");
            else if (sToken == g_sGlobalToken+"WearerName") {
                if (llSubStringIndex(sValue, "secondlife:///app/agent") == 0) {
                    g_sWearerName = "";
                    SetSobriquet(0,"");
                } else {
                    g_sWearerName = sValue;
                    SetSobriquet(g_iEnforce,"");
                }
            }
        } else if (iNum>=CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID, FALSE);
        else if (iNum == CMD_SAFEWORD || (sStr == "runaway" && iNum == CMD_OWNER)) SetSobriquet(0,kID);
        else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                //remove stride from g_lMenuIDs
                string sMenu=llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                
                
                if (sMenu=="SobriquetMenu") {
                    if (sMessage == "BACK") llMessageLinked(LINK_THIS, iAuth, "menu Apps", kAv);
                    else UserCommand(iAuth, "sobriquet "+sMessage, kAv, TRUE);
                } else if (sMenu=="RenameMenu") {
                    sMessage=llStringTrim(sMessage,STRING_TRIM);
                    if (sMessage=="") {
                        llMessageLinked(LINK_SET, iAuth, "name reset", kAv);
                        g_sWearerName = "";
                        SetSobriquet(0, kAv);
                        SobriquetMenu(kAv,iAuth);
                    } else {
                        llMessageLinked(LINK_SET, iAuth, "name "+sMessage, kAv);
                        g_sWearerName = sMessage;
                        SobriquetMenu(kAv,iAuth);
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
    }
/*        
    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }
*/        
}
