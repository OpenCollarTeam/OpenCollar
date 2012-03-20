//OpenCollar - hovertext

string g_sParentMenu = "AddOns";
string g_sFeatureName = "FloatText";

//has to be same as in the update script !!!!
integer g_iUpdatePin = 4711;

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;
integer UPDATE = 10001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

vector g_vHideScale = <.02,.02,.02>;
vector g_vShowScale = <.02,.02,1.0>;

integer g_iLastRank = 0;
integer g_iOn = FALSE;
string g_sText;
vector g_vColor;

string g_sDBToken = "hovertext";

key g_kWearer;

Debug(string sMsg) {
    //llOwnerSay(llGetScriptName() + " (debug): " + sMsg);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    } else {
            llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
}

// Return  1 IF inventory is removed - llInventoryNumber will drop
integer SafeRemoveInventory(string sItem) {
    if (llGetInventoryType(sItem) != INVENTORY_NONE) {
        llRemoveInventory(sItem);
        return 1;
    }
    return 0;
}

ShowText(string sNewText) {
    // make it possible to insert line breaks in hover text
    list lTmp = llParseStringKeepNulls(sNewText, ["\\n"], []);
    g_sText = llDumpList2String(lTmp, "\n");
    list params = [PRIM_TEXT, g_sText, g_vColor, 1.0];

    if (g_iTextPrim > 1) {//don't scale the root prim
        params += [PRIM_SIZE, g_vShowScale];
    }
    
    llSetLinkPrimitiveParamsFast(g_iTextPrim, params);
    g_iOn = TRUE;
}

HideText() {
    Debug("hide text");
    list params = [PRIM_TEXT, "", g_vColor, 1.0];
    if (g_iTextPrim > 1) {
        params += [PRIM_SIZE, g_vHideScale];
    }
    llSetLinkPrimitiveParamsFast(g_iTextPrim, params);    
    g_iOn = FALSE;
}


// for storing the link number of the prim where we'll set text.
integer g_iTextPrim = -1;

vector GetTextPrimColor() {
    if ( g_iTextPrim == -1 ) {
        return  ZERO_VECTOR ;
    }
    list params = llGetLinkPrimitiveParams( g_iTextPrim, [PRIM_COLOR, ALL_SIDES] ) ;
    return llList2Vector( params, 0 ) ;
}

default {
    state_entry() {
        // find the text prim
        integer stop = llGetNumberOfPrims();
        //only bother if there are child prims
        if (stop) {
            integer n;
            // find the prim whose desc starts with "FloatText"
            for (n = 1; n <= stop; n++) {
                key id = llGetLinkKey(n);
                string desc = (string)llGetObjectDetails(id, [OBJECT_DESC]);
                if (llSubStringIndex(desc, g_sFeatureName) == 0) {
                    g_iTextPrim = n;
                }
            }
        }
        
        g_vColor = GetTextPrimColor();
        g_kWearer = llGetOwner();
        llSetText("", <1,1,1>, 0.0);
        if (llGetLinkNumber() > 1) {
            HideText();
        }
        llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sFeatureName, NULL_KEY);
    }
    
    on_rez(integer start) {
        if(g_iOn && g_sText != "") {
            ShowText(g_sText);
        } else {
            llSetText("", <1,1,1>, 0.0);
            if (llGetLinkNumber() > 1) {
                HideText();
            }
        }
    }
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llList2String(lParams, 0);
        string sValue = llToLower(llList2String(lParams, 1));
        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER) {
            if (sStr == "menu " + g_sFeatureName) {
                //popup help on how to set label
                llMessageLinked(LINK_ROOT, POPUP_HELP, "To set floating text , say _PREFIX_text followed by the text you wish to set.  \nExample: _PREFIX_text I have text above my head!", kID);
                llMessageLinked(LINK_ROOT, iNum, "menu " + g_sParentMenu, kID);
            } else if (sCommand == "text") {
                //llSay(0, "got text command");
                lParams = llDeleteSubList(lParams, 0, 0);//pop off the "text" command
                string sNewText = llDumpList2String(lParams, " ");
                if (g_iOn) {
                    //only change text if commander has smae or greater auth
                    if (iNum <= g_iLastRank) {
                        if (sNewText == "") {
                            g_sText = "";
                            HideText();
                        } else {
                            ShowText(sNewText);
                            g_iLastRank = iNum;
                            //llMessageLinked(LINK_ROOT, LM_SETTING_SAVE, g_sDBToken + "=on:" + (string)iNum + ":" + llEscapeURL(sNewText), NULL_KEY);
                        }
                    } else {
                        Notify(kID,"You currently have not the right to change the float text, someone with a higher rank set it!", FALSE);
                    }
                } else {
                    //set text
                    if (sNewText == "") {
                        g_sText = "";
                        HideText();
                    } else {
                        ShowText(sNewText);
                        g_iLastRank = iNum;
                        //llMessageLinked(LINK_ROOT, LM_SETTING_SAVE, g_sDBToken + "=on:" + (string)iNum + ":" + llEscapeURL(sNewText), NULL_KEY);
                    }
                }
            } else if (sCommand == "textoff") {
                if (g_iOn) {
                    //only turn off if commander auth is >= g_iLastRank
                    if (iNum <= g_iLastRank) {
                        g_iLastRank = COMMAND_WEARER;
                        HideText();
                    }
                } else {
                    g_iLastRank = COMMAND_WEARER;
                    HideText();
                }
            } else if (sCommand == "texton") {
                if( g_sText != "") {
                    g_iLastRank = iNum;
                    ShowText(g_sText);
                }
            } else if (sStr == "reset" && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER)) {
                g_sText = "";
                HideText();
                llResetScript();
            }
        } else if (iNum == MENUNAME_REQUEST) {
            llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sFeatureName, NULL_KEY);
        } else if (iNum == LM_SETTING_RESPONSE) {
            lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            Debug("sToken: " + sToken);
            if (sToken == g_sDBToken) {
                llMessageLinked(LINK_ROOT, LM_SETTING_DELETE, g_sDBToken , NULL_KEY);
            }
        }
    }

    changed(integer iChange) {
        if (iChange & CHANGED_OWNER) {
            llResetScript();
        }

        if (iChange & CHANGED_COLOR) { //SA this event is triggered when text is changed (LSL bug?) so we need to check the color really changed if we want to avoid an endless loop
            vector vNewColor = GetTextPrimColor();
            if (vNewColor != g_vColor)
            {
                g_vColor = vNewColor;
                if (g_iOn) {
                    ShowText(g_sText);
                }
            }
        }
    }
}