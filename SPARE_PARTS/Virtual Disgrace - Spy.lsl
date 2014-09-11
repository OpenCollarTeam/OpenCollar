////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            Virtual Disgrace - Spy                              //
//                                  version 1.1                                   //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
//        ©   2013 - 2014  Individual Collaborators and Virtual Disgrace™         //
// ------------------------------------------------------------------------------ //
//                       github.com/VirtualDisgrace/Collar                        //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Based on the OpenCollar - subspy 3.957
// Compatible with OpenCollar API   3.9.8
// and/or minimum Disgraced Version 1.3.2

string g_sChatBuffer;  //if this has anything in it at end of interval, then tell owners (if listen enabled)

integer g_iListener;

integer g_iTraceEnabled=FALSE;
integer g_iListenEnabled=FALSE;
integer g_iNotifyEnabled=TRUE;

//OC MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

//integer NOTIFY=1002;
//integer NOTIFY_OWNERS=1003;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string g_sScript = "subspy_";

string UPMENU = "BACK";

list g_lOwners;
string g_sWearerName;
key g_kWearer;

key g_kDialogSpyID;
integer serial;

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

DoReports(string sChatLine, integer sendNow, integer fromTimer) {
    if (!(g_iTraceEnabled||g_iListenEnabled)) return;
    
    integer iMessageLimit=500;
    //store chat
    if (g_iListenEnabled && sChatLine != "") {
        g_sChatBuffer += sChatLine+"\n";
    }

    string sLocation;
    if (g_iTraceEnabled) {
        vector vPos = llGetPos();
        //sLocation += " %WEARERNAME% is at " + llList2String(llGetParcelDetails(vPos, [PARCEL_DETAILS_NAME]),0) + " (" + llGetRegionName() + " <" + (string)((integer)vPos.x)+","+(string)((integer)vPos.y)+","+(string)((integer)vPos.z)+">).";
        sLocation += " "+g_sWearerName+" is at " + llList2String(llGetParcelDetails(vPos, [PARCEL_DETAILS_NAME]),0) + " (" + llGetRegionName() + " <" + (string)((integer)vPos.x)+","+(string)((integer)vPos.y)+","+(string)((integer)vPos.z)+">).";
    }
    string sHeader="["+(string)serial + "]"+sLocation+"\n";
    
    integer iMessageLength=llStringLength(sHeader)+llStringLength(g_sChatBuffer);
    if (iMessageLength > iMessageLimit || (g_sChatBuffer!="" && fromTimer) || sendNow) { //if we have too much chat, or the timer fired and we have something to report, or we got a sendnow
        //Debug("Sending report");
        while (iMessageLength > iMessageLimit){
            g_sChatBuffer=sHeader+g_sChatBuffer;
            iMessageLength=llStringLength(g_sChatBuffer);
            //Debug("message length:"+(string)iMessageLength);
            //Debug("header length:"+(string)llStringLength(sHeader));
            integer index=iMessageLimit;
            while (llGetSubString(g_sChatBuffer,index,index) != "\n"){
                index--;
            }
            //Debug("Found a return at "+(string) index);
            if (index <= llStringLength(sHeader)){
                index=iMessageLimit;
                while (llGetSubString(g_sChatBuffer,index,index) != " "){
                    index--;
                }
                if (index <= llStringLength(sHeader)) {
                    index=iMessageLimit;
                    //Debug("Found no breaks, breaking at "+(string) index);
                //} else {
                    //Debug("Found a space at "+(string) index);
                }
            }
            string sMessageToSend=llGetSubString(g_sChatBuffer,0,index);
            //Debug("send length:"+(string)llStringLength(sMessageToSend));
            NotifyOwners(sMessageToSend);
//            llMessageLinked(LINK_SET,NOTIFY_OWNERS,sMessageToSend,"ignoreNearby");
            serial++;
            sHeader="["+(string)serial + "]\n";
            
            g_sChatBuffer=llGetSubString(g_sChatBuffer,index+1,-1);
            iMessageLength=llStringLength(sHeader)+llStringLength(g_sChatBuffer);
            //Debug("remaining:"+(string)iMessageLength);
        }
        if (sendNow || fromTimer){
            sHeader="["+(string)serial + "]"+sLocation+"\n";
            NotifyOwners(sHeader+g_sChatBuffer);
            serial++;
//            llMessageLinked(LINK_SET,NOTIFY_OWNERS,sHeader+g_sChatBuffer,"ignoreNearby");
            g_sChatBuffer="";
            //Debug("Emptied buffer");
        }

        //make a warning for the user
        if (g_iNotifyEnabled){
            
        string activityWarning="Spy plugin is reporting your ";
        if (g_iTraceEnabled) activityWarning += "location ";
        if (g_iTraceEnabled && g_iListenEnabled)  activityWarning += "and ";
        if (g_iListenEnabled)  activityWarning += "chat activity ";
        activityWarning += "to your primary owners";
        Notify(g_kWearer,activityWarning,FALSE);
            
        }        
    } else {
        return;
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DialogSpy(key kID, integer iAuth) {
    string sPrompt="\nSpy\n";
    
    if (iAuth != COMMAND_OWNER) {
        sPrompt = "\nACCESS DENIED: Primary Owners Only\n";
        g_kDialogSpyID = Dialog(kID, sPrompt, [], [UPMENU], 0, iAuth);
        return;
    }
    list lButtons ;

    if(g_iNotifyEnabled) lButtons += ["☒ Notify"];
    else lButtons += ["☐ Notify"];
    
    if(g_iTraceEnabled) lButtons += ["☒ Trace"];
    else lButtons += ["☐ Trace"];
    
    if (g_iListenEnabled) lButtons += ["☒ Listen"];
    else lButtons += ["☐ Listen"];

    sPrompt += "\nTrace notifies if the wearer changes region.\nListen transmits directly what the wearer says in Nearby Chat.\nNotify reminds the wearer each time a report is sent to their owners.\n\nNOTE: The nearby chat of other parties and the wearers or other parties private IMs cannot be broadcasted.";

    g_kDialogSpyID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
//    llMessageLinked(LINK_SET,NOTIFY,(string)iAlsoNotifyWearer+sMsg,kID);
    if (kID == g_kWearer) {
        while (llStringLength(sMsg)>1000){
            string sSendString=llGetSubString(sMsg,0,1000);
            llOwnerSay(sSendString);
            sMsg=llGetSubString(sMsg,1001,-1);
        }
        llOwnerSay(sMsg);
    } else {
        //Debug("Notifying "+(string)kID);
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

NotifyOwners(string sMsg) {
    integer n;
    integer iStop = llGetListLength(g_lOwners);
    for (n = 0; n < iStop; n += 2) {
        key kAv = (key)llList2String(g_lOwners, n);
        //we don't want to bother the owner if he/she is right there, so check distance
        vector vOwnerPos = (vector)llList2String(llGetObjectDetails(kAv, [OBJECT_POS]), 0);
        if (vOwnerPos == ZERO_VECTOR || llVecDist(vOwnerPos, llGetPos()) > 20.0) {//vOwnerPos will be ZERO_VECTOR if not in sim
            //Debug("notifying " + (string)kAv);
            Notify(kAv, sMsg,FALSE);
        }
    }
}

integer UserCommand (integer iAuth, string sStr, key kID, integer remenu) {
    if (iAuth < COMMAND_OWNER || iAuth > COMMAND_WEARER) return FALSE;

    sStr = llToLower(sStr);
        if (sStr == "☐ trace" || sStr == "trace on") {
            if (kID==g_kWearer) {
                if (!g_iTraceEnabled) {
                    g_iTraceEnabled=TRUE;
                    Notify(kID,"\n\nTrace enabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "subspy_trace=1", "");
                }
            } else {
                Notify(kID,"\n\nOnly the wearer may enable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if(sStr == "☒ trace" || sStr == "trace off") {
            if (kID==g_kWearer) {
                if (g_iTraceEnabled){
                    g_iTraceEnabled=FALSE;
                    Notify(kID,"\n\nTrace disabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "subspy_trace", "");
                }
            } else {
                Notify(kID,"\n\nOnly the wearer may enable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if(sStr == "☐ listen" || sStr == "listen on") {
            if (iAuth == COMMAND_OWNER) {
                if (!g_iListenEnabled) {
                    g_iListenEnabled=TRUE;
                    Notify(kID,"\n\nChat Spy enabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "subspy_listen=1", "");
                    llListenRemove(g_iListener);
                    g_iListener = llListen(0, "", g_kWearer, "");
                }
            } else {
                Notify(kID,"\n\nOnly an owner may disable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if(sStr == "☒ listen" || sStr == "listen off") {
            if (iAuth == COMMAND_OWNER) {
                if (g_iListenEnabled) {
                    g_iListenEnabled=FALSE;
                    Notify(kID,"\n\nChat Spy disabled.\n",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "subspy_listen", "");
                    llListenRemove(g_iListener);
                    g_iListener = 0;
                }
            } else {
                Notify(kID,"\n\nOnly an owner may disable spy functions.\n",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if (sStr == "☐ notify" || sStr == "spynotify on") {
            if (kID==g_kWearer) {
                if (!g_iNotifyEnabled) {
                    g_iNotifyEnabled=TRUE;
                    Notify(kID,"Spy notifications enabled.",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "subspy_notify=1", "");
                }
            } else {
                Notify(kID,"Only the wearer may enable spy notifications",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if (sStr == "☒ notify" || sStr == "spynotify off") {
            if (kID==g_kWearer) {
                if (g_iNotifyEnabled){
                    g_iNotifyEnabled=FALSE;
                    Notify(kID,"Spy notifications disabled.",TRUE);
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "subspy_notify", "");
                }
            } else {
                Notify(kID,"Only the wearer may enable spy notifications",TRUE);
            }
            if (remenu) DialogSpy(kID,iAuth);
        } else if ("runaway" == sStr) {
            g_iListenEnabled=FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "subspy_listen", "");
            llListenRemove(g_iListener);
            g_iListener = 0;

            g_iTraceEnabled=FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, "subspy_trace", "");
        } else if (sStr == "spy" || sStr == "menu spy") DialogSpy(kID, iAuth);
    return TRUE;
}

default {
    state_entry() {
        g_kWearer = llGetOwner();
        g_sWearerName = llKey2Name(g_kWearer);
        g_lOwners = [g_kWearer, g_sWearerName];  // initially self-owned until we hear a db message otherwise
        llSetTimerEvent(300);
        //Debug("Starting");
    }

    listen(integer channel, string sName, key kID, string sMessage) {
        if(kID == g_kWearer && channel == 0) {
            //process emotes, replace with sub name
            //if(llGetSubString(sMessage, 0, 3) == "/me ") sMessage="%WEARERNAME%" + llGetSubString(sMessage, 3, -1);
            if(llGetSubString(sMessage, 0, 3) == "/me ") sMessage=g_sWearerName + llGetSubString(sMessage, 3, -1);
            //else sMessage="%WEARERNAME%: " + sMessage;
            else sMessage=g_sWearerName+": " + sMessage;
            DoReports(sMessage,FALSE,FALSE);
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (UserCommand(iNum, sStr, kID, FALSE)) {
            // do nothing more if TRUE
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == "auth_owner" && llStringLength(sValue) > 0) g_lOwners = llParseString2List(sValue, [","], []);
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            if (llSubStringIndex(sToken, "subspy_")==0) { //spy data
                if (sToken == "subspy_trace") {
                    if (!g_iTraceEnabled) {
                        g_iTraceEnabled=TRUE;
                        Notify(g_kWearer,"\n\nTrace enabled.\n",FALSE);
                    }
                } else if (sToken == "subspy_notify") {
                    if (!g_iNotifyEnabled) {
                        g_iNotifyEnabled=TRUE;
                        Notify(g_kWearer,"Notifications enabled.",FALSE);
                    }
                } else if (sToken == "subspy_listen") {
                    if (!g_iListenEnabled) {
                        g_iListenEnabled=TRUE;
                        Notify(g_kWearer,"\n\nChat Spy enabled.\n",FALSE);
                        llListenRemove(g_iListener);
                        g_iListener = llListen(0, "", g_kWearer, "");
                    }
                }
            } else if(sToken == "auth_owner" && llStringLength(sValue) > 0) { //owners list
                g_lOwners = llParseString2List(sValue, [","], []);
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == "Apps") {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Apps|Spy", "");
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kDialogSpyID) { //settings change from main spy
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iAuth = (integer)llList2String(lMenuParams, 3);

                if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu apps", kAv);
                else UserCommand(iAuth, sMessage, kAv, TRUE);
            }
        }
    }

    timer (){
        DoReports("",FALSE,TRUE);
    }

    attach(key kID) {
        if (kID) DoReports("",TRUE, FALSE);
    }

    changed(integer iChange) {
        if (iChange & CHANGED_REGION) DoReports("",TRUE,FALSE);
        if (iChange & CHANGED_OWNER) llResetScript();
/*        
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/        
    }
}
