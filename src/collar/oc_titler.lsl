////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - titler                               //
//                                 version 3.988                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Nandana Singh, Satomi Ahn, Romka Swallowtail, littlemousy, Wendy Starfall

string g_sParentMenu = "Apps";
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
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;


integer g_iLastRank = COMMAND_EVERYONE ;
integer g_iOn = FALSE;
string g_sText;
vector g_vColor = <1.0,1.0,1.0>; // default white 

integer g_iTextPrim;
string g_sScript= "titler_";

key g_kWearer;

key g_kDialogID;    //menu handle
key g_kColourDialogID;    //menu handle
key g_kTBoxId;      //text box handle

string SET = "Set Title" ;
string UP = "↑ Up";
string DN = "↓ Down";
string ON = "☒ Show";
string OFF = "☐ Show";
string UPMENU = "BACK";
float min_z = 0.25 ; // min height
float max_z = 1.0 ; // max height
vector g_vPrimScale = <0.02,0.02,0.5>; // prim size, initial value (z - text offset height)
list g_lColours=[
    "Magenta",<1.00000, 0.00000, 0.50196>,
    "Pink",<1.00000, 0.14902, 0.50980>,
    "Hot Pink",<1.00000, 0.05490, 0.72157>,
    "Firefighter",<0.88627, 0.08627, 0.00392>,
    "Sun",<1.00000, 1.00000, 0.18039>,
    "Flame",<0.92941, 0.43529, 0.00000>,
    "Matrix",<0.07843, 1.00000, 0.07843>,
    "Electricity",<0.00000, 0.46667, 0.92941>,
    "Violet Wand",<0.63922, 0.00000, 0.78824>,
    "Black",<0.00000, 0.00000, 0.00000>,
    "White",<1.00000, 1.00000, 1.00000>
];

//Debug(string sMsg) {llOwnerSay(llGetScriptName() + " (debug): " + sMsg);}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
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
        llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT,g_sText,g_vColor,(float)g_iOn, PRIM_SIZE,g_vPrimScale, PRIM_SLICE,<0.490,0.51,0.0>]);
    }
}

integer UserCommand(integer iAuth, string sStr, key kAv){
    if (iAuth < COMMAND_OWNER || iAuth > COMMAND_WEARER) return FALSE;
    
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));

    if (llToLower(sStr) == "menu titler") {
        string ON_OFF ;
        string sPrompt;
        if (g_iTextPrim == -1) {
            sPrompt="\nThis design is missing a FloatText box. Titler disabled.";
            sPrompt+= "\n\nwww.opencollar.at/titler";
            g_kDialogID = Dialog(kAv, sPrompt, [], [UPMENU],0, iAuth);
        } else {
            sPrompt = "\nCurrent Title: " + g_sText ;
            sPrompt+= "\n\nwww.opencollar.at/titler";
            if(g_iOn == TRUE) ON_OFF = ON ;
            else ON_OFF = OFF ;
            g_kDialogID = Dialog(kAv, sPrompt, [SET,UP,DN,ON_OFF,"Color"], [UPMENU],0, iAuth);
        }
    } else if (sStr=="menu titlercolor" || sStr=="titlercolor") {
        list lColourNames;
        integer numColours=llGetListLength(g_lColours)/2;
        while (numColours--){
            lColourNames+=llList2String(g_lColours,numColours*2);
        }
        g_kColourDialogID = Dialog(kAv, "\n\nSelect a colour from the list", lColourNames, [UPMENU],0, iAuth);
    } else if (sCommand=="titlercolor") {
        string sColour= llDumpList2String(llDeleteSubList(lParams,0,0)," ");
        integer colourIndex=llListFindList(g_lColours,[sColour]);
        if (~colourIndex){
            g_vColor=(vector)llList2String(g_lColours,colourIndex+1);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"color="+(string)g_vColor, "");
        }
        ShowHideText();
        
    } else if (sStr == "runaway" && (iAuth == COMMAND_OWNER || iAuth == COMMAND_WEARER)) {
        g_sText = "";
        g_iOn = FALSE;
        ShowHideText();
        llResetScript();
    } else if (llSubStringIndex(sCommand,"title")==0) {
        if (g_iOn && iAuth > g_iLastRank) { //only change text if commander has smae or greater auth             
            Notify(kAv,"You currently have not the right to change the Titler settings, someone with a higher rank set it!", FALSE);
        } else  if (sCommand == "title") {
            string sNewText= llDumpList2String(llDeleteSubList(lParams, 0, 0), " ");//pop off the "text" command
        
            g_sText = llDumpList2String(llParseStringKeepNulls(sNewText, ["\\n"], []), "\n");// make it possible to insert line breaks in hover text
            if (sNewText == "") {
                g_iOn = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"title", "");
            } else { 
                g_iOn = TRUE; 
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"title="+g_sText, "");
            }
            g_iLastRank=iAuth;            
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, ""); // save lastrank to DB
        } else if (sCommand == "titleoff") {
            g_iLastRank = COMMAND_EVERYONE;
            g_iOn = FALSE;
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"on", "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"auth", ""); // del lastrank from DB
        } else if (sCommand == "titleon") {
            g_iLastRank = iAuth;
            g_iOn = TRUE;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
        } else if (sCommand == "titleup") {
            g_vPrimScale.z += 0.05 ;
            if(g_vPrimScale.z > max_z) g_vPrimScale.z = max_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"height="+(string)g_vPrimScale.z, "");
        } else if (sCommand == "titledown") {
            g_vPrimScale.z -= 0.05 ;
            if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"height="+(string)g_vPrimScale.z, "");
        } else if (sCommand == "titlebox") {
            g_kTBoxId = Dialog(kAv, "\n- Submit the new title in the field below.\n- Submit a blank field to go back to " + g_sFeatureName + ".", [], [], 0, iAuth);
        }
        ShowHideText();
    }
    return TRUE;
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
                if (llList2Integer(llGetLinkPrimitiveParams(linkNumber,[PRIM_TYPE]),0)==PRIM_TYPE_BOX){
                    g_iTextPrim = linkNumber;
                    llSetLinkPrimitiveParamsFast(g_iTextPrim,[PRIM_DESC,g_sPrimDesc+"~notexture~nocolor~nohide"]);
                    linkNumber = 0 ; // break while cycle
                } else {
                    llSetLinkPrimitiveParamsFast(linkNumber,[PRIM_TEXT,"",<0,0,0>,0]);
                }
            }
        }
        g_kWearer = llGetOwner();
        //Debug("State Entry Event ended");
        
        if (g_iTextPrim < 0) {
            llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sFeatureName, "");
            llRemoveInventory(llGetScriptName());
        }
    } 
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        //Debug("Link Message Event");
        if (UserCommand(iNum, sStr, kID)) return;
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sFeatureName, "");
        } else if (iNum == LM_SETTING_RESPONSE) {
            string sGroup = llGetSubString(sStr, 0,  llSubStringIndex(sStr, "_") );
            string sToken = llGetSubString(sStr, llSubStringIndex(sStr, "_")+1, llSubStringIndex(sStr, "=")-1);
            string sValue = llGetSubString(sStr, llSubStringIndex(sStr, "=")+1, -1);
            if (sGroup == g_sScript) {
                if(sToken == "title") g_sText = sValue;
                if(sToken == "on") g_iOn = (integer)sValue;
                if(sToken == "color") g_vColor = (vector)sValue;
                if(sToken == "height") g_vPrimScale.z = (float)sValue;
                if(sToken == "auth") g_iLastRank = (integer)sValue; // restore lastrank from DB
            } else if( sStr == "settings=sent") ShowHideText();
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kDialogID) {   //response from our main menu
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == SET) {
                    UserCommand(iAuth, "titlebox", kAv);
                } else if (sMessage == "Color") {
                    UserCommand(iAuth, "menu titlercolor", kAv);
                } else if (sMessage == UPMENU) {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                } else {
                    if (sMessage == UP) UserCommand(iAuth, "titleup", kAv);
                    else if (sMessage == DN) UserCommand(iAuth, "titledown", kAv);
                    else if (sMessage == OFF) UserCommand(iAuth, "titleon", kAv);
                    else if (sMessage == ON) UserCommand(iAuth, "titleoff", kAv);
                    UserCommand(iAuth, "menu titler", kAv);
                }
            } else if (kID == g_kColourDialogID) {  //response form the colours menu
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                if (sMessage == UPMENU) {
                    UserCommand(iAuth, "menu titler", kAv);
                } else {
                    UserCommand(iAuth, "titlercolor "+sMessage, kAv);
                    UserCommand(iAuth, "menu titlercolor", kAv);
                }
                
            } else if (kID == g_kTBoxId) {  //response from text box
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                if(sMessage != "") UserCommand(iAuth, "title " + sMessage, kAv);
                UserCommand(iAuth, "menu " + g_sFeatureName, kAv);
            }
        }
    }

    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
    }
    
    on_rez(integer param){
        llResetScript();
    }
}
