/*
This file is a part of OpenCollar.
Copyright 2021

: Contributors :

Aria (Tashia Redrose)
    * March 2021         - Rewrote oc_update_shim

et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

string GetSetting(string sToken) {
    integer i = llListFindList(g_lSettings, [llToLower(sToken)]);
    if(i == -1)return "NOT_FOUND";
    return llList2String(g_lSettings, i + 1);
}

DelSetting(string sToken) { // we'll only ever delete user settings
    sToken = llToLower(sToken);
    integer i = llGetListLength(g_lSettings) - 1;
    if (SplitToken(sToken, 1) == "all") {
        sToken = SplitToken(sToken, 0);
      //  string sVar;
        for (; ~i; i -= 2) {
            if (SplitToken(llList2String(g_lSettings, i - 1), 0) == sToken)
                g_lSettings = llDeleteSubList(g_lSettings, i - 1, i);
        }
        return;
    }
    i = llListFindList(g_lSettings, [sToken]);
    if (~i) g_lSettings = llDeleteSubList(g_lSettings, i, i + 1);
}


// Get Group or Token, 0=Group, 1=Token
string SplitToken(string sIn, integer iSlot) {
    integer i = llSubStringIndex(sIn, "_");
    if (!iSlot) return llGetSubString(sIn, 0, i - 1);
    return llGetSubString(sIn, i + 1, -1);
}

// To add new entries at the end of Groupings
integer GroupIndex(string sToken) {
    sToken = llToLower(sToken);
    string sGroup = SplitToken(sToken, 0);
    integer i = llGetListLength(g_lSettings) - 1;
    // start from the end to find last instance, +2 to get behind the value
    for (; ~i ; i -= 2) {
        if (SplitToken(llList2String(g_lSettings, i - 1), 0) == sGroup) return i + 1;
    }
    return -1;
}

integer SettingExists(string sToken) {
    sToken = llToLower(sToken);
    if (~llListFindList(g_lSettings, [sToken])) return TRUE;
    return FALSE;
}

list SetSetting(string sToken, string sValue) {
    sToken = llToLower(sToken);
    integer idx = llListFindList(g_lSettings, [sToken]);
    if (~idx) return llListReplaceList(g_lSettings, [sValue], idx + 1, idx + 1);
    idx = GroupIndex(sToken);
    if (~idx) return llListInsertList(g_lSettings, [sToken, sValue], idx);
    return g_lSettings + [sToken, sValue];
}

list g_lSettings;
integer g_iPass=0;
integer g_iReady;
integer UPDATER = -99999;
integer REBOOT=-1000;
integer SECURE; // The secure channel
integer UPDATER_CHANNEL = -7483213;
integer RELAY_CHANNEL = -7483212;
integer g_iRelayActive;

integer LOADPIN = -1904;
list g_lLinkedScripts = [
    "oc_auth",
    "oc_anim",
    "oc_rlvsys",
    "oc_dialog",
    "oc_settings"
    ];

integer g_iRequiredPhase=FALSE;
CheckLinkedScripts()
{
    integer i=0;
    integer end = llGetListLength(g_lLinkedScripts);
    for(i=0;i<end;i++){
        llMessageLinked(LINK_ALL_OTHERS, LOADPIN, llList2String(g_lLinkedScripts,i), "");
    }
}
default
{
    state_entry()
    {
        SECURE = llRound(llFrand(8383288));
        llListen(SECURE, "", "", "");
        //llWhisper(0, "Update Shim is now active. Requesting all settings");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
        llSetTimerEvent(10);
        llMessageLinked(LINK_SET, UPDATER, "update_active", "");
        g_iRelayActive = llGetStartParameter();
    }
    timer()
    {
        if(llGetTime()>=10 && g_iPass!=3 && !g_iReady){
            g_iPass++;
            llOwnerSay("Settings not yet ready. Requesting again (attempt "+(string)g_iPass+")");
            llResetTime();
            llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
        } else if(llGetTime()>=10 && g_iPass>=3 && !g_iReady)
        {
            llSetTimerEvent(0);
            g_iReady=TRUE;
            if(!g_iRelayActive)
                llSay(UPDATER_CHANNEL, "reallyready|"+(string)SECURE);
            else
                llSay(RELAY_CHANNEL, "reallyready|"+(string)SECURE);
        }
    }
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if(iNum == LM_SETTING_RESPONSE)
        {
            if(sStr!="settings=sent"){
                list lTmp = llParseString2List(sStr, ["="],[]);
                if(g_iRelayActive){
                    if(llToLower(llList2String(lTmp,0))=="leash_leashedto")return;
                    if(llToLower(llList2String(lTmp,0))=="leash_leashedtoname")return;
                }
                SetSetting(llList2String(lTmp,0), llList2String(lTmp,1));
                llResetTime();
            }else{
                // settings recieved!
                g_iReady=TRUE;
                if(!g_iRelayActive)
                    llSay(UPDATER_CHANNEL, "reallyready|"+(string)SECURE);
                else
                    llSay(RELAY_CHANNEL, "reallyready|"+(string)SECURE);
                //llSay(0, "Settings finished downloading... update shim ready, leaving update state, not yet implemented");
                //llMessageLinked(LINK_SET, REBOOT, "", "");
                //llRemoveInventory(llGetScriptName());
            }
        } else if(iNum == LOADPIN)
        {
            list lTmp = llParseString2List(sStr, ["@"],[]);
            llRemoteLoadScriptPin(kID, "oc_linkprim_hammer", (integer)llList2String(lTmp,0), TRUE, 825);
        }
    }
    listen(integer c,string n,key i,string m)
    {
        if(c == SECURE)
        {
            list lCmd = llParseString2List(m,["|"],[]);
            if(llList2String(lCmd,0) == "DONE")
            {
                llOwnerSay("Installation is now finishing");
                //llSay(0, "Installation done signal received!");
                //llSay(0, "Restoring settings, then removing shim");
                llResetOtherScript("oc_settings");
                llResetOtherScript("oc_states");
                llOwnerSay("Restoring settings...");
                llSleep(15);
                llMessageLinked(LINK_SET,REBOOT,"","");
                llSleep(10);

                integer ix=0;
                integer end = llGetListLength(g_lSettings);
                for(ix=0;ix<end;ix+=2)
                {
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, llList2String(g_lSettings,ix)+"="+llList2String(g_lSettings,ix+1), "origin");
                }
                llSetRemoteScriptAccessPin(0);

                llOwnerSay("Installation Completed!");
                llRemoveInventory(llGetScriptName());
            } else {
                //llSay(0, "Unimplemented updater command: "+m);
                list lOpts = llParseString2List(m,["|"],[]);
                string sOption = llList2String(lOpts,0);
                string sName = llList2String(lOpts,1);
                key kNameID = (key)llList2String(lOpts,2);
                string sBundleType = llList2String(lOpts,3);
                key kDSID = (key)llList2String(lOpts,4);
                integer iDSLine = (integer)llList2String(lOpts,5);

                integer bItemMatches = TRUE;
                if(llGetInventoryType(sName)==INVENTORY_NONE || llGetInventoryKey(sName)!=kNameID)bItemMatches=FALSE;
                string sResponse = "SKIP"; // Default command when the option is not yet implemented
                @recheck;
                if(sBundleType == "REQUIRED")
                {
                    g_iRequiredPhase=TRUE;
                    if(sOption == "ITEM")
                    {
                        if(!bItemMatches){
                            if(llGetInventoryType(sName)!=INVENTORY_NONE)
                                llRemoveInventory(sName);
                            sResponse="GIVE";
                        }
                    } else if(sOption == "SCRIPT")
                    {
                        if(!bItemMatches){
                            sResponse="INSTALL";
                        }
                    }
                    else if(sOption == "STOPPEDSCRIPT")
                    {
                        if(!bItemMatches)sResponse="INSTALLSTOPPED";
                    } else {
                        llWhisper(0, "Unrecognized updater signal for required bundle: "+sOption+"|"+sName);
                    }
                } else if(sBundleType == "DEPRECATED")
                {
                    if(g_iRequiredPhase){
                        g_iRequiredPhase=FALSE;
                        CheckLinkedScripts();
                    }
                    if(sOption == "LIKE"){
                        // special handling
                        integer X = 0;
                        integer X_end = llGetInventoryNumber(INVENTORY_ALL);
                        for(X=0;X<X_end;X++)
                        {
                            string sTmpName = llGetInventoryName(INVENTORY_ALL,X);
                            if(llSubStringIndex(sTmpName,sName)!=-1){
                                llRemoveInventory(sTmpName);
                                X=-1;
                                X_end=llGetInventoryNumber(INVENTORY_ALL);
                            }
                        }
                    }else{
                        if(llGetInventoryType(sName)!=INVENTORY_NONE)llRemoveInventory(sName);
                    }
                } else if(sBundleType == "OPTIONAL")
                {
                    // if item does not match, and exists in inventory, update it without a prompt.
                    // if item does not exist or is the same as the updater version, ask the user
                    if(!bItemMatches && llGetInventoryType(sName)!=INVENTORY_NONE)
                    {
                        sBundleType = "REQUIRED";
                        jump recheck;
                    } else {
                        sResponse="PROMPT";
                        if(llGetInventoryType(sName)==INVENTORY_NONE)sResponse+="_INSTALL";
                        else sResponse+="_REMOVE";
                    }
                }

                llRegionSayTo(i, SECURE, llDumpList2String([sResponse, sName, kDSID, iDSLine], "|"));
            }
        }
    }
}
