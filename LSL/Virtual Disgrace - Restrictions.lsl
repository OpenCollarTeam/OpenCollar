////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                       Virtual Disgrace - Restrictions                          //
//                                  version 1.8                                   //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
//        ©   2013 - 2015  Individual Collaborators and Virtual Disgrace™         //
// ------------------------------------------------------------------------------ //
//                       github.com/VirtualDisgrace/Collar                        //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Compatible with OpenCollar API   3.9
// and/or minimum Disgraced Version 2.x

string  SUBMENU_BUTTON              = "Restrictions"; // Name of the submenu
string  PLUGIN_CHAT_COMMAND         = "restrictions";
string  TERMINAL_BUTTON             = "Terminal";   //rlv command terminal button for TextBox
string  TERMINAL_CHAT_COMMAND       = "terminal";
string  COLLAR_PARENT_MENU          = "RLV";

key     g_kMenuID;                              // menu handler
key     g_kSitMenuID;                           // sit menu handler
key     g_kTerminalID;                          //Terminal menu handler
key     g_kWearer;  
//string g_sSettingToken                = "restrictions_";
//string g_sGlobalToken                 = "global_";
integer g_bSendRestricted;
integer g_bReadRestricted;
integer g_bHearRestricted;
integer g_bTalkRestricted;
integer g_bTouchRestricted;
integer g_bStrayRestricted;
integer g_bRummageRestricted;
integer g_bStandRestricted;
integer g_bDressRestricted;
integer g_bBlurredRestricted;
integer g_bDazedRestricted;

string bluriness;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER                   = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER                  = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD                = 510; 
integer CMD_RELAY_SAFEWORD          = 511;
//integer CMD_BLOCKED = 520;

integer NOTIFY                     = 1002;
integer LM_SETTING_SAVE            = 2000; 
//integer LM_SETTING_REQUEST         = 2001;
integer LM_SETTING_RESPONSE        = 2002; 
integer LM_SETTING_DELETE          = 2003; 
integer LM_SETTING_EMPTY           = 2004; 
//integer LM_SETTING_REQUEST_NOCACHE = 2005;

// messages for creating OC menu structure
integer MENUNAME_REQUEST           = 3000;
integer MENUNAME_RESPONSE          = 3001;
//integer MENUNAME_REMOVE            = 3003;

// messages for RLV commands
integer RLV_CMD                    = 6000;
integer RLV_REFRESH                = 6001; // RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR                  = 6002; // RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100;
integer RLV_ON = 6101; 

// messages to the dialog helper
integer DIALOG                     = -9000;
integer DIALOG_RESPONSE            = -9001;
integer SENSORDIALOG               = -9003;

integer g_iMenuCommand;

key g_kLastForcedSeat;
string g_sLastForcedSeat;
string g_sTerminalText            = "\n[http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI RLV Command Terminal]\n\nType one command per line without \"@\" sign.\n\n>_";

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


doRestrictions(){
    if (g_bSendRestricted)     llMessageLinked(LINK_THIS,RLV_CMD,"sendim=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"sendim=y","vdRestrict");
    
    if (g_bReadRestricted)     llMessageLinked(LINK_THIS,RLV_CMD,"recvim=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"recvim=y","vdRestrict");
    
    if (g_bHearRestricted)     llMessageLinked(LINK_THIS,RLV_CMD,"recvchat=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"recvchat=y","vdRestrict");
    
    if (g_bTalkRestricted)     llMessageLinked(LINK_THIS,RLV_CMD,"sendchat=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"sendchat=y","vdRestrict");
    
    if (g_bTouchRestricted)    llMessageLinked(LINK_THIS,RLV_CMD,"touchall=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"touchall=y","vdRestrict");
    
    if (g_bStrayRestricted)    llMessageLinked(LINK_THIS,RLV_CMD,"tplm=n,tploc=n,tplure=n,sittp=n,standtp=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"tplm=y,tploc=y,tplure=y,sittp=y,standtp=y","vdRestrict");
    
    if (g_bStandRestricted)    llMessageLinked(LINK_THIS,RLV_CMD,"unsit=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"unsit=y","vdRestrict");
    
    if (g_bRummageRestricted)  llMessageLinked(LINK_THIS,RLV_CMD,"showinv=n,viewscript=n,viewtexture=n,edit=n,rez=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"showinv=y,viewscript=y,viewtexture=y,edit=y,rez=y","vdRestrict");
    
    if (g_bDressRestricted)    llMessageLinked(LINK_THIS,RLV_CMD,"addattach=n,remattach=n,defaultwear=n,addoutfit=n,remoutfit=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"addattach=y,remattach=y,defaultwear=y,addoutfit=y,remoutfit=y","vdRestrict");
    
    if (g_bBlurredRestricted)  llMessageLinked(LINK_THIS,RLV_CMD,"setdebug_renderresolutiondivisor:16=force","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"setdebug_renderresolutiondivisor:1=force","vdRestrict");
    
    if (g_bDazedRestricted)    llMessageLinked(LINK_THIS,RLV_CMD,"shownames=n,showhovertextworld=n,showloc=n,showworldmap=n,showminimap=n","vdRestrict");
    else llMessageLinked(LINK_THIS,RLV_CMD,"shownames=y,showhovertextworld=y,showloc=y,showworldmap=y,showminimap=y","vdRestrict");
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DoMenu(key keyID, integer iAuth) {
    string sPrompt = "\n[http://www.virtualdisgrace.com/collar#restrictions Virtual Disgrace - Restrictions]";
    list lMyButtons;// = ["Force Sit"];
    
    if (g_bSendRestricted) lMyButtons += "☐ Send IMs";
    else lMyButtons += "☒ Send IMs";
    if (g_bReadRestricted) lMyButtons += "☐ Read IMs";
    else lMyButtons += "☒ Read IMs";
    if (g_bHearRestricted) lMyButtons += "☐ Hear";
    else lMyButtons += "☒ Hear";
    if (g_bTalkRestricted) lMyButtons += "☐ Talk";
    else lMyButtons += "☒ Talk";
    if (g_bTouchRestricted) lMyButtons += "☐ Touch";
    else lMyButtons += "☒ Touch";
    if (g_bStrayRestricted) lMyButtons += "☐ Stray";
    else lMyButtons += "☒ Stray";
    if (g_bRummageRestricted) lMyButtons += "☐ Rummage";
    else lMyButtons += "☒ Rummage";
    if (g_bDressRestricted) lMyButtons += "☐ Dress";
    else lMyButtons += "☒ Dress";
    lMyButtons += "RESET";
    if (g_bBlurredRestricted) lMyButtons += "Un-Dazzle";
    else lMyButtons += "Dazzle";
    if (g_bDazedRestricted) lMyButtons += "Un-Daze";
    else lMyButtons += "Daze";
    
    g_kMenuID = Dialog(keyID, sPrompt, lMyButtons, ["BACK"], 0, iAuth);
}

DoTerminalCommand(string sMessage, key kID) {
    string sCRLF= llUnescapeURL("%0A");
    list lCommands = llParseString2List(sMessage, [sCRLF], []);
    sMessage = llDumpList2String(lCommands, ",");
    llMessageLinked(LINK_THIS,RLV_CMD,sMessage,"vdTerminal");
    llMessageLinked(LINK_SET,NOTIFY,"0"+"Your command(s) were sent to %WEARERNAME%'s RL-Viewer:\n" + sMessage, kID);
    llMessageLinked(LINK_SET,NOTIFY,"0"+"secondlife:///app/agent/"+(string)kID+"/about" + " has changed your rlv restrictions.", g_kWearer);
}

releaseRestrictions() {
    g_bSendRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_send","");
    g_bReadRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_read","");
    g_bHearRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_hear","");
    g_bTalkRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_talk","");
    g_bStrayRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_touch","");
    g_bTouchRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_stray","");
    g_bRummageRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_stand","");
    g_bStandRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_rummage","");
    g_bDressRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_dress","");
    g_bBlurredRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_blurred","");
    g_bDazedRestricted=FALSE;
    llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_dazed","");
    
    doRestrictions();
}

UserCommand(integer iNum, string sStr, key kID, integer bFromMenu) {
    string sLowerStr=llToLower(sStr);
    if (iNum==CMD_WEARER) {
        if (sStr == PLUGIN_CHAT_COMMAND || sLowerStr == "sit" || sLowerStr == TERMINAL_CHAT_COMMAND) {
            llMessageLinked(LINK_SET,NOTIFY,"1"+"%NOACCESS%",kID);
        } else if (sLowerStr == "menu force sit" || sStr == "menu " + SUBMENU_BUTTON || sStr == "menu " + TERMINAL_BUTTON){
            llMessageLinked(LINK_SET,NOTIFY,"1"+"%NOACCESS%",kID);
            llMessageLinked(LINK_SET, iNum, "menu " + COLLAR_PARENT_MENU, kID);
        }
        return;
    } else if (sStr == PLUGIN_CHAT_COMMAND || sStr == "menu " + SUBMENU_BUTTON) {
        DoMenu(kID, iNum);
    } else if (sStr == TERMINAL_CHAT_COMMAND || sStr == "menu " + TERMINAL_BUTTON) {
        if (sStr == TERMINAL_CHAT_COMMAND) g_iMenuCommand = FALSE;
        else g_iMenuCommand = TRUE;
        g_kTerminalID = Dialog(kID, g_sTerminalText, [], [], 0, iNum);
    } else if (sLowerStr == "restrictions back")
        llMessageLinked(LINK_SET, iNum, "menu " + COLLAR_PARENT_MENU, kID);
    else if (sLowerStr == "restrictions reset" || sLowerStr == "allow all"){
        releaseRestrictions();
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☐ send ims" || sLowerStr == "allow sendim"){
        g_bSendRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_send","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Send IMs is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ send ims" || sLowerStr == "forbid sendim"){
        g_bSendRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_send=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Send IMs is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☐ read ims" || sLowerStr == "allow readim"){
        g_bReadRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_read","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Read IMs is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ read ims" || sLowerStr == "forbid readim"){
        g_bReadRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_read=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Read IMs is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☐ hear" || sLowerStr == "allow hear"){
        g_bHearRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_hear","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Hear is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ hear" || sLowerStr == "forbid hear"){
        g_bHearRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_hear=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Hear IMs is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☐ touch" || sLowerStr == "allow touch"){
        g_bTouchRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_touch","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Touch is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ touch" || sLowerStr == "forbid touch"){
        g_bTouchRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_touch=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Touch restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☐ stray" || sLowerStr == "allow stray"){
        g_bStrayRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_stray","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Stray is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ stray" || sLowerStr == "forbid stray"){
        g_bStrayRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_stray=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Stray is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
        //2015-04-10 added Otto
    } else if (sLowerStr == "restrictions ☐ stand" || sLowerStr == "allow stand"){
        g_bStrayRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_stand","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Stand up is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ stand" || sLowerStr == "forbid stand"){
        g_bStrayRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_stand=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Stand up is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);     
    } else if (sLowerStr == "restrictions ☐ talk" || sLowerStr == "allow talk"){
        g_bTalkRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_talk","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Talk is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ talk" || sLowerStr == "forbid talk"){
        g_bTalkRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_talk=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Talk is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☐ rummage" || sLowerStr == "allow rummage"){
        g_bRummageRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_rummage","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Rummage is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ rummage" || sLowerStr == "forbid rummage"){
        g_bRummageRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_rummage=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Rummage is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☐ dress" || sLowerStr == "allow dress"){
        g_bDressRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_dress","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Dress is un-restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions ☒ dress" || sLowerStr == "forbid dress"){
        g_bDressRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_dress=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Ability to Dress is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions un-dazzle" || sLowerStr == "undazzle"){
        g_bBlurredRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_blurred","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Vision is clear",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions dazzle" || sLowerStr == "dazzle"){
        g_bBlurredRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_blurred=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Vision is restricted",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions un-daze" || sLowerStr == "undaze"){
        g_bDazedRestricted=FALSE;
        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"restrictions_dazed","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Clarity is restored",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "restrictions daze" || sLowerStr == "daze"){
        g_bDazedRestricted=TRUE;
        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"restrictions_dazed=1","");
        doRestrictions();
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Confusion is imposed",kID);
        if (bFromMenu) DoMenu(kID,iNum);
    } else if (sLowerStr == "stand" || sLowerStr == "standnow"){
        llMessageLinked(LINK_THIS,RLV_CMD,"unsit=y,unsit=force","vdRestrict");
        llMessageLinked(LINK_SET,NOTIFY,"1"+"Get Up!",kID);
        llSleep(0.5);
        if (bFromMenu) llMessageLinked(LINK_SET, iNum, "menu force sit", kID);
    } else if (sLowerStr == "menu force sit" || sLowerStr == "sit" || sLowerStr == "sitnow"){
        integer agentInfo=llGetAgentInfo( g_kWearer );
        string sButton;
        string sitPrompt;
        if (agentInfo & AGENT_SITTING)
            sButton="Get Up!`BACK";
        else {
            vector avPos=llGetPos();
            list lastSeatInfo=llGetObjectDetails(g_kLastForcedSeat, [OBJECT_POS]);
            vector lastSeatPos=(vector)llList2String(lastSeatInfo,0);
            if (llVecDist(avPos,lastSeatPos)<20){
                sButton="Sit Back Down!`BACK";
                sitPrompt="\nLast forced to sit on "+g_sLastForcedSeat+"\n";
            } else 
                sButton="BACK";
        }
        llMessageLinked(LINK_THIS, SENSORDIALOG, (string)kID +"|"+sitPrompt+"\nChoose a seat:\n|0|``"+(string)(SCRIPTED|PASSIVE)+"`20`"+(string)PI +"|"+sButton+"|" + (string)iNum, g_kSitMenuID=llGenerateKey());
    } else if (sLowerStr == "clear") releaseRestrictions();
}



default {

    state_entry() {
        llSetMemoryLimit(49152); //2015-05-06 (11398 bytes free)
        g_kWearer = llGetOwner();
        //Debug("Starting");
    }

    on_rez(integer iParam) {
        if (llGetOwner()!=g_kWearer) llResetScript();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_REQUEST && sStr == COLLAR_PARENT_MENU) {
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + SUBMENU_BUTTON, "");
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|Force Sit", "");
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, COLLAR_PARENT_MENU + "|" + TERMINAL_BUTTON, "");
        } else if (iNum == LM_SETTING_EMPTY) {
            if (sStr=="restrictions_send"){
                g_bSendRestricted=FALSE;
            } else if (sStr=="restrictions_read"){
                g_bReadRestricted=FALSE;
            } else if (sStr=="restrictions_hear"){
                g_bHearRestricted=FALSE;
            } else if (sStr=="restrictions_talk"){
                g_bTalkRestricted=FALSE;
            } else if (sStr=="restrictions_touch"){
                g_bTouchRestricted=FALSE;
            } else if (sStr=="restrictions_stray"){
                g_bStrayRestricted=FALSE;
            } else if (sStr=="restrictions_stand"){
                g_bStandRestricted=FALSE;
            } else if (sStr=="restrictions_rummage"){
                g_bRummageRestricted=FALSE;
            } else if (sStr=="restrictions_blurred"){
                g_bBlurredRestricted=FALSE;
            } else if (sStr=="restrictions_dazed"){
                g_bDazedRestricted=FALSE;
            } 
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (~llSubStringIndex(sToken,"restrictions_")){
                if (sToken=="restrictions_send")          g_bSendRestricted=(integer)sValue;
                else if (sToken=="restrictions_read")     g_bReadRestricted=(integer)sValue;
                else if (sToken=="restrictions_hear")     g_bHearRestricted=(integer)sValue;
                else if (sToken=="restrictions_talk")     g_bTalkRestricted=(integer)sValue;
                else if (sToken=="restrictions_touch")    g_bTouchRestricted=(integer)sValue;
                else if (sToken=="restrictions_stray")    g_bStrayRestricted=(integer)sValue;
                else if (sToken=="restrictions_stand")    g_bStandRestricted=(integer)sValue;
                else if (sToken=="restrictions_rummage")  g_bRummageRestricted=(integer)sValue;
                else if (sToken=="restrictions_blurred")  g_bBlurredRestricted=(integer)sValue;
                else if (sToken=="restrictions_dazed")    g_bDazedRestricted=(integer)sValue;
            }
        }
        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID,FALSE);
        else if (iNum == RLV_ON || iNum == RLV_REFRESH)  doRestrictions();
        else if (iNum == RLV_OFF || iNum == RLV_CLEAR) releaseRestrictions();
        else if (iNum == CMD_SAFEWORD || iNum == CMD_RELAY_SAFEWORD) releaseRestrictions();
        else if (iNum == DIALOG_RESPONSE) {
            list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMessage = llList2String(lMenuParams, 1); 
            integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);
            //Debug("Sending restrictions "+sMessage);
            if (kID == g_kMenuID) UserCommand(iAuth, "restrictions "+sMessage,kAv,TRUE);   
            else if (kID == g_kSitMenuID) {
                if (sMessage=="BACK") llMessageLinked(LINK_SET, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
                else if (sMessage == "Sit Back Down!") {
                    llMessageLinked(LINK_THIS,RLV_CMD,"unsit=force","vdRestrict");
                    llSleep(0.5);
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Sit back down, and stay there!",kID);
                    llMessageLinked(LINK_THIS,RLV_CMD,"sit:"+(string)g_kLastForcedSeat+"=force","vdRestrict");
                    llSleep(0.5);
                    llMessageLinked(LINK_SET, iAuth, "menu force sit", kAv);
                } else if (sMessage == "Get Up!") UserCommand(iAuth, "stand", kAv, TRUE);
                else {
                    llMessageLinked(LINK_THIS,RLV_CMD,"unsit=force","vdRestrict");
                    llSleep(0.5);
                    llMessageLinked(LINK_SET,NOTIFY,"1"+"Sit down, and stay there!",kID);
                    g_kLastForcedSeat=(key)sMessage;
                    g_sLastForcedSeat=llKey2Name(g_kLastForcedSeat);
                    llMessageLinked(LINK_THIS,RLV_CMD,"sit:"+sMessage+"=force","vdRestrict");
                    llSleep(0.5);
                    llMessageLinked(LINK_SET, iAuth, "menu force sit", kAv);
                } 
            } else if (kID == g_kTerminalID) {
                    if (llStringLength(sMessage) > 4) DoTerminalCommand(sMessage, kAv);
                    if (g_iMenuCommand) llMessageLinked(LINK_SET, iAuth, "menu " + COLLAR_PARENT_MENU, kAv);
            }
        }
    }
    
/*    changed(integer iChange) {
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
    }*/        
}
