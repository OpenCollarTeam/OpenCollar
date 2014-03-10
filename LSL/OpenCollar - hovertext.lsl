////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - hovertext                              //
//                                 version 3.953                                  //
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
integer UPDATE = 10001;

integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;


integer g_iLastRank = COMMAND_EVERYONE ;
integer g_iOn = FALSE;
string g_sText;
vector g_vColor;

integer g_iTextPrim ;

string g_sDBToken = "hovertext";

key g_kWearer;

// add for dialogs & buttons
string g_sHelpText = "\nTo set floating text via chat command, say _PREFIX_text followed by the title you wish to set.\nExample: _PREFIX_text I have text above my head!";

key g_kDialogID;
key g_kTBoxId;

string SET = "Set Title" ;
string UP = "Up";
string DN = "Down";
string ON = "☒ Show";
string OFF = "☐ Show";
string HELP = "Help";
string UPMENU = "BACK";
float min_z = 0.25 ; // min height
float max_z = 1.0 ; // max height
vector g_vPrimScale = <0.02,0.02,0.25>; // prim size, initial value

Debug(string sMsg)
{
   // llOwnerSay(llGetScriptName() + " (debug): " + sMsg);
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

SetText(string Text)
{
    // make it possible to insert line breaks in hover text
    list lTmp = llParseStringKeepNulls(Text, ["\\n"], []);
    g_sText = llDumpList2String(lTmp, "\n");
    ShowText();
}
    
ShowText()
{
    llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT, g_sText, g_vColor, 1.0]);
    g_iOn = TRUE;
}

HideText()
{
    llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT, g_sText, g_vColor, 0.0]);
    g_iOn = FALSE;
}

vector GetTextPrimColor()
{
    return llList2Vector(llGetLinkPrimitiveParams(g_iTextPrim, [PRIM_COLOR, ALL_SIDES]), 0) ;
}

GetTextPrimText()
{
    list params = llGetLinkPrimitiveParams(g_iTextPrim, [PRIM_TEXT]) ;
    g_sText = llList2String(params,0);
    //g_vColor = llList2Vector(params,1);
    if(llList2Float(params,2) > 0.0) g_iOn = TRUE;
    else g_iOn = FALSE;
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

Menu(key kAv, integer iAuth)
{
    string ON_OFF ;
    string sPrompt = "\nCurrent Title: " + g_sText ;
    if(g_iOn == TRUE) ON_OFF = ON ;
    else ON_OFF = OFF ;
    g_kDialogID = Dialog(kAv, sPrompt, [SET,UP,DN,ON_OFF], [HELP,UPMENU],0, iAuth);
}


integer CheckPrim()  // check prim link number
{
    string desc = llList2String(llGetLinkPrimitiveParams(g_iTextPrim, [OBJECT_DESC]), 0) ;
    if (llSubStringIndex(desc, g_sPrimDesc) == 0) return TRUE;
    else return FALSE ;
}


InitPrim()
{
    g_iTextPrim = -1 ;
    // find the text prim
    integer stop = llGetNumberOfPrims();
    //only bother if there are child prims
    if (stop)
    {
        integer n;
        // find the prim whose desc starts with "FloatText"
        for (n = 1; n <= stop; n++)
        {
            key id = llGetLinkKey(n);
            string desc = (string)llGetObjectDetails(id, [OBJECT_DESC]);
            if (llSubStringIndex(desc, g_sPrimDesc) == 0) g_iTextPrim = n;
        }            
    }
    
    if(g_iTextPrim != -1 )
    {
        // get Z-size from prim name
        g_vPrimScale.z = llList2Float(llGetLinkPrimitiveParams(g_iTextPrim, [PRIM_NAME]), 0) ;
        if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;    
        // set prim initial size & slice
        llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_SIZE, g_vPrimScale, PRIM_SLICE, <0.490,0.51,0.0>]);
    }    
}


integer UserCommand(integer iNum, string sStr, key kID) 
{
    if (iNum < COMMAND_OWNER || iNum > COMMAND_WEARER) return FALSE;
    
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    
    if (sStr == "menu " + g_sFeatureName)
    {
        Menu(kID, iNum);
    }
    else if (sCommand == "text")
    {
        lParams = llDeleteSubList(lParams, 0, 0);//pop off the "text" command
        string sNewText = llDumpList2String(lParams, " ");
        
        if (g_iOn)
        { //only change text if commander has smae or greater auth             
            if (iNum <= g_iLastRank)
            {
                if (sNewText == "")
                {
                    g_sText = "";
                    HideText();
                }
                else
                {
                    SetText(sNewText);
                    g_iLastRank = iNum;
                    //llMessageLinked(LINK_ROOT, LM_SETTING_SAVE, g_sDBToken + "=on:" + (string)iNum + ":" + llEscapeURL(sNewText), NULL_KEY);
                }
            }
            else
            {
                Notify(kID,"You currently have not the right to change the float text, someone with a higher rank set it!", FALSE);
            }
        }
        else
        {
            //set text
            if (sNewText == "")
            {
                g_sText = "";
                HideText();
            }
            else
            {
                SetText(sNewText);
                g_iLastRank = iNum;
                //llMessageLinked(LINK_ROOT, LM_SETTING_SAVE, g_sDBToken + "=on:" + (string)iNum + ":" + llEscapeURL(sNewText), NULL_KEY);
            }
        }
    }
    else if (sCommand == "textoff")
    {
        if (g_iOn)
        {
            //only turn off if commander auth is >= g_iLastRank
            if (iNum <= g_iLastRank)
            {
                g_iLastRank = COMMAND_EVERYONE;
                HideText();
            }
        }
        else
        {
            g_iLastRank = COMMAND_EVERYONE;
            HideText();
        }
    }
    else if (sCommand == "texton")
    {
        if( g_sText != "")
        {
            g_iLastRank = iNum;
            ShowText();
        }
    }
    else if (sStr == "runaway" && (iNum == COMMAND_OWNER || iNum == COMMAND_WEARER))
    {
        g_sText = "";
        HideText();
        llResetScript();
    }    
    return TRUE;
}

default
{
    state_entry()
    {
        InitPrim();        
        if(g_iTextPrim == -1 ) state NoHovertextPrim ;
        GetTextPrimText() ;
        g_vColor = GetTextPrimColor();
        g_kWearer = llGetOwner();
        //llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sFeatureName, NULL_KEY);
    }
    
    on_rez(integer start)
    {
        if(!CheckPrim()) InitPrim();  // check prim linknumber and init if vrong    
        if(g_iTextPrim == -1 ) state NoHovertextPrim ;
        GetTextPrimText() ;
        if(g_iOn && g_sText != "") ShowText();
        else HideText();
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID)) 
        {        
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sFeatureName, NULL_KEY);
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == g_kDialogID)
            {
                //got a menu response meant for us. pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == SET)
                {
                    g_kTBoxId = Dialog(kAv, "\n- Submit the new title in the field below.\n- Submit a blank field to go back to " + g_sFeatureName + ".", [], [], 0, iAuth);                    
                }
                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                }
                else if (sMessage == UP)
                {
                    g_vPrimScale.z += 0.05 ;
                    if(g_vPrimScale.z > max_z) g_vPrimScale.z = max_z ;
                    if(g_iTextPrim>0) llSetLinkPrimitiveParamsFast(g_iTextPrim,[PRIM_NAME,(string)g_vPrimScale.z, PRIM_SIZE,g_vPrimScale]);
                    if (g_iOn) ShowText();
                    Menu(kAv, iAuth);
                }
                else if (sMessage == DN)
                {
                    g_vPrimScale.z -= 0.05 ;
                    if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;
                    if(g_iTextPrim>0) llSetLinkPrimitiveParamsFast(g_iTextPrim,[PRIM_NAME,(string)g_vPrimScale.z, PRIM_SIZE,g_vPrimScale]);
                    if (g_iOn) ShowText();
                    Menu(kAv, iAuth);
                }
                else if (sMessage == OFF)
                {
                    UserCommand(iAuth, "texton", kAv);
                    Menu(kAv, iAuth);
                }
                else if (sMessage == ON)
                {
                    UserCommand(iAuth, "textoff", kAv);
                    Menu(kAv, iAuth);
                }
                else if (sMessage == HELP)
                {
                    //popup help on how to set label
                    llMessageLinked(LINK_ROOT, POPUP_HELP, g_sHelpText, kAv);
                }
            }
            else if (kID == g_kTBoxId) 
            {
                Debug(sStr);
                //got a menu response meant for us. pull out values
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                //if (sMessage == " ") UserCommand(iAuth, "textoff", kAv);
                //else if (sMessage) UserCommand(iAuth, "text " + sMessage, kAv);
                if(sMessage != "") UserCommand(iAuth, "text " + sMessage, kAv);
                Menu(kAv, iAuth);
            }
        }        
    }

    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
        if (iChange & CHANGED_LINK)
        {
            if(!CheckPrim()) InitPrim();  // check prim linknumber and init if vrong
        }
        if (iChange & CHANGED_COLOR)
        { //SA this event is triggered when text is changed (LSL bug?) so we need to check the color really changed if we want to avoid an endless loop            
            vector vNewColor = GetTextPrimColor();
            if (vNewColor != g_vColor)
            {
                g_vColor = vNewColor;
                if(g_iOn) ShowText();
            }
        }
    }
}

state NoHovertextPrim
{
    state_entry()
    {
        llOwnerSay("hovertext prim not found, function disabled!");
    }
    
    on_rez(integer start)
    {
        llResetScript() ;
    }
}
