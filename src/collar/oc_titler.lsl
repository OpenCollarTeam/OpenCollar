////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - titler                               //
//                                 version 3.958                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// SatomiAhn Initial support for llTextBox. 
// Romka Swallowtail add some buttons =^_^=

string g_sParentMenu = "AddOns";
string g_sFeatureName = "Titler";
string g_sPrimDesc = "FloatText";   //description text of the hovertext prim.  Needs to be separated from the menu name.

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
//integer SEND_IM = 1000; deprecated. each script should send its own IMs now. This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;
//integer UPDATE = 10001;

integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;


integer g_iLastRank = COMMAND_EVERYONE ;
integer g_iOn = FALSE;
string g_sText;
vector g_vColor = <1.0,1.0,1.0>; // default white 

integer g_iTextPrim;
string g_sScript;
string CTYPE = "collar";

key g_kWearer;

key g_kDialogID;    //menu handle
key g_kTBoxId;      //text box handle

string SET = "Set Title" ;
string UP = "↑ Up";
string DN = "↓ Down";
string ON = "☒ Show";
string OFF = "☐ Show";
string HELP = "Help";
string UPMENU = "BACK";
float min_z = 0.25 ; // min height
float max_z = 1.0 ; // max height
vector g_vPrimScale = <0.02,0.02,0.5>; // prim size, initial value (z - text offset height)
vector g_vPrimSlice = <0.490,0.51,0.0>; // prim slice

//Debug(string sMsg) {llOwnerSay(llGetScriptName() + " (debug): " + sMsg);}


Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth){
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

ShowHideText(){
    //Debug("ShowHideText");
    //llSleep(1.0); // not sure that it should be
    if (g_iTextPrim >0){
        if (g_sText == "") g_iOn = FALSE;
        llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT,g_sText,g_vColor,(float)g_iOn, PRIM_SIZE,g_vPrimScale, PRIM_SLICE,g_vPrimSlice]);
    }
}

integer UserCommand(integer iNum, string sStr, key kID){
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);

    if (sStr == "menu " + g_sFeatureName) {
        string ON_OFF ;
        string sPrompt;
        if (g_iTextPrim == -1) {
            sPrompt="\nMissing hovertext prim.  Titler plugin disabled";
        }
        sPrompt = "\nCurrent Title: " + g_sText ;
        if(g_iOn == TRUE) ON_OFF = ON ;
        else ON_OFF = OFF ;
        g_kDialogID = Dialog(kID, sPrompt, [SET,UP,DN,ON_OFF], [HELP,UPMENU],0, iNum);
    } else if (sStr == "runaway" && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER)) {
        g_sText = "";
        g_iOn = FALSE;
        ShowHideText();
        llResetScript();
    } else  if (g_iOn && iNum > g_iLastRank) { //only change text if commander has smae or greater auth             
        Notify(kID,"You currently have not the right to change the float text settings, someone with a higher rank set it!", FALSE);
    } else {
        if (sCommand == "text") {
            string sNewText= llDumpList2String(llDeleteSubList(lParams, 0, 0), " ");//pop off the "text" command
        
            g_sText = llDumpList2String(llParseStringKeepNulls(sNewText, ["\\n"], []), "\n");// make it possible to insert line breaks in hover text
            if (sNewText == "") {
                g_iOn = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"text", "");
            } else { 
                g_iOn = TRUE; 
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"text="+g_sText, "");
            }
            g_iLastRank=iNum;            
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, ""); // save lastrank to DB
        } else if (sCommand == "textoff") {
            g_iLastRank = COMMAND_EVERYONE;
            g_iOn = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"on", "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"auth", ""); // del lastrank from DB
        } else if (sCommand == "texton") {
            g_iLastRank = iNum;
            g_iOn = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
        } else if (sCommand == "textup") {
            g_vPrimScale.z += 0.05 ;
            if(g_vPrimScale.z > max_z) g_vPrimScale.z = max_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"height="+(string)g_vPrimScale.z, "");
        } else if (sCommand == "textdown") {
            g_vPrimScale.z -= 0.05 ;
            if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"height="+(string)g_vPrimScale.z, "");
        }
        ShowHideText();
    }
    return TRUE;
}

string GetScriptID() {
    // strip away "OpenCollar - " leaving the script's individual name
    return llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
}

// Get from Group_Token=Value , 0=Group, 1=Token, 2=Value
string SplitTokenValue(string in, integer slot) {
    string out ;
    if (slot==0) out = llGetSubString(in, 0,  llSubStringIndex(in, "_") );
    else if (slot==1) out = llGetSubString(in, llSubStringIndex(in, "_")+1, llSubStringIndex(in, "=")-1);
    else if (slot==2) out = llGetSubString(in, llSubStringIndex(in, "=")+1, -1);
    return out ;
}

default{
    state_entry(){
        //llOwnerSay("state entry:"+(string)llGetFreeMemory());

        //get colour, description and 
        g_iTextPrim = -1 ;
        // find the text prim
        integer linkNumber = llGetNumberOfPrims()+1;
        while (linkNumber-- >2){
            string desc = llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]),0);
            if (llSubStringIndex(desc, g_sPrimDesc) == 0) {
                g_iTextPrim = linkNumber;
                linkNumber = 0 ; // break while cylle
            }
        }
        g_sScript = GetScriptID();
        g_kWearer = llGetOwner();
        //Debug("State Entry Event ended");
    } 
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        //Debug("Link Message Event");
        if (UserCommand(iNum, sStr, kID)) return;
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sFeatureName, "");
        } else if (iNum == LM_SETTING_RESPONSE) {
            string sGroup = SplitTokenValue(sStr, 0);
            string sToken = SplitTokenValue(sStr, 1);
            string sValue = SplitTokenValue(sStr, 2);
            if (sGroup == g_sScript) {
                if(sToken == "text") g_sText = sValue;
                //if(sToken == "color") g_vColor = (vector)sValue;
                if(sToken == "on") g_iOn = (integer)sValue;
                if(sToken == "height") g_vPrimScale.z = (float)sValue;
                if(sToken == "auth") g_iLastRank = (integer)sValue; // restore lastrank from DB
            } else if (sGroup+sToken == "Global_CType") CTYPE = sValue;        
            else if( sStr == "settings=sent") ShowHideText();
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kDialogID) {
                //got a menu response meant for us. pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == SET) {
                    g_kTBoxId = Dialog(kAv, "\n- Submit the new title in the field below.\n- Submit a blank field to go back to " + g_sFeatureName + ".", [], [], 0, iAuth);                    
                } else if (sMessage == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                } else {
                    if (sMessage == HELP) {
                        //popup help on how to set label
                        llMessageLinked(LINK_ROOT, POPUP_HELP, "\nTo set floating text via chat command, say _PREFIX_text followed by the title you wish to set.\nExample: _PREFIX_text I have text above my head!", kAv);
                    } else if (sMessage == UP) UserCommand(iAuth, "textup", kAv);
                    else if (sMessage == DN) UserCommand(iAuth, "textdown", kAv);
                    else if (sMessage == OFF) UserCommand(iAuth, "texton", kAv);
                    else if (sMessage == ON) UserCommand(iAuth, "textoff", kAv);
                    UserCommand(iAuth, "menu " + g_sFeatureName, kAv);
                }
            } else if (kID == g_kTBoxId) {
                //Debug(sStr);
                //got a menu response meant for us. pull out values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                //if (sMessage == " ") UserCommand(iAuth, "textoff", kAv);
                //else if (sMessage) UserCommand(iAuth, "text " + sMessage, kAv);
                if(sMessage != "") UserCommand(iAuth, "text " + sMessage, kAv);
                UserCommand(iAuth, "menu " + g_sFeatureName, kAv);
            }
        }        
        //Debug("Link Message Event ended");
    } 

    changed(integer iChange){
        //Debug("Changed event");
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
        if (iChange & CHANGED_COLOR){
            vector vNewColor=llList2Vector(llGetLinkPrimitiveParams(g_iTextPrim,[PRIM_COLOR,ALL_SIDES]),0);
            //Debug("testing color, was "+(string)g_vColor+" now "+(string)vNewColor);
            if (vNewColor!=g_vColor){
                //Debug("Set color");
                g_vColor=vNewColor;
                ShowHideText();
            } else { 
                //Debug("No color change");
            }
        }
        //Debug("Sleeping at end of changed event\n\n");
        //llSleep(1.0);
    }
    
    on_rez(integer param){
        llResetScript();
    }
}
