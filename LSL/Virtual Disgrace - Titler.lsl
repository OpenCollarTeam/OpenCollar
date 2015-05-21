////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                           Virtual Disgrace - Titler                            //
//                                  version 2.1                                   //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
//               Copyright © 2008 - 2015: Individual Contributors,                //
//            OpenCollar - submission set free™ and Virtual Disgrace™             //
// ------------------------------------------------------------------------------ //
//                       github.com/VirtualDisgrace/Collar                        //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// Based on OpenCollar - titler 3.988
// Compatible with OpenCollar API   3.9
// and/or minimum Disgraced Version 2.2.0

string g_sParentMenu = "Apps";
string g_sPrimDesc = "FloatText";   //description text of the hovertext prim.  Needs to be separated from the menu name.

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_SAFEWORD = 510;
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
string g_sType = "off";
string g_sLfmUser;//="virtualdisgrace";
integer g_iEvilListenHandle;
integer g_iEvilListenChannel;
key g_kHttpRequestKey;
string g_sLastFmResponseText="uninitialized";
integer g_iTicks;
string g_sCurrentTitleText;
string g_sNormalTitleText;
integer g_iLastHttpRequest;
string g_sLastFmTitle;

vector g_vColor = <1.000, 1.000, 0.000>; // default white 

integer g_iTextPrim=-1;
string g_sScript= "titler_";
float g_sEvilTimeout=60;
float g_sEvilDuration=1800;

key g_kWearer;
string g_sWearerName;

string g_sAuthError = "Access denied.";

key g_kDialogID;    //menu handle
key g_kColourDialogID;    //menu handle
key g_kTBoxId;      //text box handle
key g_kLfmUserBoxId;      //text box handle

string UPMENU = "BACK";
float min_z = 0.25 ; // min height
float max_z = 1.0 ; // max height
vector g_vPrimScale = <0.02,0.02,0.4>; // prim size, initial value (z - text offset height)

/*list g_lColours=[
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
];*/

/*
integer g_iProfiled=1;
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

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth){
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer){
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

Whisper(string sMessage) {
    string sObjectName = llGetObjectName();
    llSetObjectName("");
    llWhisper(0, "/me " + sMessage);
    llSetObjectName(sObjectName);
}

httpRequest() {
    if (g_sLfmUser != "" && g_sType=="lastfm"){
        //Debug("Sending http request:"+"http://ws.audioscrobbler.com/1.0/user/"+g_sLfmUser+"/recenttracks.txt");
        g_iLastHttpRequest=llGetUnixTime();
        g_kHttpRequestKey = llHTTPRequest("http://ws.audioscrobbler.com/1.0/user/"+g_sLfmUser+"/recenttracks.txt", [HTTP_MIMETYPE, "text/plain;charset=utf-8"], "");
    //} else {
        //Debug("Not sending http request");
    }
}

renderTitle(){
    if (g_sType=="lastfm") {
        if (llGetUnixTime()-10 > g_iLastHttpRequest) httpRequest();

        g_sLastFmTitle+=llGetSubString(g_sLastFmTitle,0,0);
        g_sLastFmTitle=llGetSubString(g_sLastFmTitle,1,-1);

        g_sCurrentTitleText="♬ " + llGetSubString(g_sLastFmTitle,0,22);
    } else if (g_sType=="off") {
        g_sCurrentTitleText="";
    } else if (g_sType=="normal") {
        g_sCurrentTitleText=g_sNormalTitleText;
    }

    //Debug("Rendering title:\""+g_sCurrentTitleText+"\"");
    //Debug("Rendering title ("+(string)g_iTextPrim+"):"+g_sCurrentTitleText);
    llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT,g_sCurrentTitleText,g_vColor,1.0, PRIM_SIZE,g_vPrimScale, PRIM_SLICE,<0.490,0.51,0.0>]);
}

UserCommand(integer iAuth, string sStr, key kAv){
    if (iAuth < COMMAND_OWNER || iAuth > COMMAND_WEARER) return;
    
    //first, jongle commands into a sane format
    if (llToLower(sStr) == "menu titler") sStr="title";
    else if (llToLower(sStr) == "menu titlercolor") sStr="title color";
    else if (sStr == "runaway" && (iAuth == COMMAND_OWNER || iAuth == COMMAND_WEARER)) {
        g_sType = "off";
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+g_sType, "");
        
        renderTitle();
        llResetScript();
    }
    
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));

    //now they are in standard form, process the commands
    if (sCommand == "title" || sCommand == "titler") {
        //Debug("Got command "+sStr);
        //this is a command for this script.  Drop the prefix, and grab the next word as the command
        lParams=llDeleteSubList(lParams,0,0);
        string sCommand = llToLower(llList2String(lParams, 0));
        
        if (iAuth > g_iLastRank) {    //only change titler settings if commander has same or greater auth             
            Notify(kAv,g_sAuthError, FALSE);
        } else if (sCommand=="color") {
            string sColor= llDumpList2String(llDeleteSubList(lParams,0,0)," ");
            if (sColor != "") {    //we got a colour, so set the colour
               // integer colourIndex=llListFindList(g_lColours,[sColour]);
               // if (~colourIndex){
                   //g_vColor=(vector)llList2String(g_lColours,colourIndex+1);
                   g_vColor=(vector)sColor;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"color="+(string)g_vColor, "");
                //}
                renderTitle();
            } else {    //no colour given, so pop the dialog.
              //  list lColourNames;
              //  integer numColours=llGetListLength(g_lColours)/2;
              //  while (numColours--){
              //      lColourNames+=llList2String(g_lColours,numColours*2);
               // }
                g_kColourDialogID = Dialog(kAv, "\nChoose a color!", ["colormenu please"], [UPMENU],0, iAuth);
                return;
            }
        } else if (sCommand == "on") {
            g_sType = "normal";
            g_iLastRank = iAuth;
            g_sCurrentTitleText = g_sNormalTitleText;
            evilListenerOff();
            llSetTimerEvent(0.0);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+g_sType, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
        } else if (sCommand == "off") {
            g_sType = "off";
            g_iLastRank = COMMAND_EVERYONE;
            g_sCurrentTitleText="";
            evilListenerOff();
            llSetTimerEvent(0.0);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+g_sType, "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"auth", ""); // del lastrank from DB
        } else if (sCommand == "lastfm") {
            string sAction= llList2String(lParams,1);
            if (sAction == "") {    //set lastfm mode on
                evilListenerOff();
                //Debug("doing "+sCommand);
                g_sType = "lastfm";
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+g_sType, "");
                g_sCurrentTitleText="";
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"title", "");
                g_iLastRank = iAuth;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
                renderTitle();
                llSetTimerEvent(0.2);
            } else {
                if (sAction == "set") {
                    if (llList2String(lParams,2)=="") { //no name given, pop dialog
                        g_kLfmUserBoxId = Dialog(kAv, "\n- Enter your last.fm ID in the field below.\n- Submit a blank field to go back to " + "Titler" + ".", [], [], 0, iAuth);
                        return;
                    } else {    //set ...        convert to .., and handle below.
                        lParams=llDeleteSubList(lParams,1,1);
                    }
                }
                        
                //we got a name, use it
                g_sLfmUser = llList2String(lParams, 1);
                //Debug("setting lastfm username to "+g_sLfmUser);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"lfmuser="+g_sLfmUser, "");
                g_iLastRank = iAuth;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
                if (g_sType=="lastfm"){
                    g_sCurrentTitleText="";
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript+"title", "");
                    httpRequest();
                }
            }
        } else if (sCommand == "evil") {
            //Debug("doing "+sCommand);
            llSetTimerEvent(0.2);
            g_sType = "evil";
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+g_sType, "");
            g_iLastRank = iAuth;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
            g_sCurrentTitleText="";
        } else if (sCommand == "up") {
            g_vPrimScale.z += 0.05 ;
            if(g_vPrimScale.z > max_z) g_vPrimScale.z = max_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"height="+(string)g_vPrimScale.z, "");
        } else if (sCommand == "down") {
            g_vPrimScale.z -= 0.05 ;
            if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"height="+(string)g_vPrimScale.z, "");
        } else {    //looks like we're setting the title, or popping a text box to ask for one
            if (sCommand=="") {    //<nothing>            pop main titler menu
                string sPrompt = "\n[http://www.virtualdisgrace.com/titler Virtual Disgrace - Titler]\n\nCurrent Title: " + g_sNormalTitleText;
                    
                string normalButton ;
                if(g_sType == "normal") normalButton = "☒ Normal" ;
                else normalButton = "☐ Normal" ;
                
                string lastFmButton ;
                if(g_sType == "lastfm") lastFmButton = "☒ last.fm" ;
                else lastFmButton = "☐ last.fm" ;
                
                string evilButton ;
                if(g_sType == "evil") evilButton = "☒ Evil" ;
                else evilButton = "☐ Evil" ;
                
                g_kDialogID = Dialog(kAv, sPrompt, ["Set Title","Color","last.fm ID",normalButton,evilButton,lastFmButton,"↑ Up","↓ Down"], [UPMENU],0, iAuth);
            } else {
                if (sCommand == "set") {
                    //Debug("set "+llList2String(lParams,1));
                    if (llList2String(lParams,1)=="") {
                        //Debug("set <nothing>, give text box");
                        g_kTBoxId = Dialog(kAv, "\n- Submit the new title in the field below.\n- Submit a blank field to go back to " + "Titler" + ".", [], [], 0, iAuth);
                        return;
                    } else {    //set ...        convert to .., and handle below.
                        lParams=llDeleteSubList(lParams,0,0);
                    }
                }
                
                //set standard title
                string sNewText= llDumpList2String(lParams, " ");
                //Debug("Setting title to "+sNewText);
                g_sNormalTitleText = llDumpList2String(llParseStringKeepNulls(sNewText, ["\\n"], []), "\n");// make it possible to insert line breaks in hover text
                g_sCurrentTitleText = g_sNormalTitleText;
                g_iLastRank = iAuth;
                g_sType = "normal";
                llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"title="+g_sCurrentTitleText, "");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"on="+g_sType, "");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"auth="+(string)g_iLastRank, ""); // save lastrank to DB
            }
        }
        renderTitle();
    }
    return;
}

evilListenerOff(){
    if (g_iEvilListenHandle){    //listener is set, so cancel it and stop timer
        llListenRemove(g_iEvilListenHandle);
        g_iEvilListenHandle=0;
        //llSetTimerEvent(0.0);
    }
}

default{
    on_rez(integer param){
        llResetScript();
    }
    
    state_entry(){
        llSetMemoryLimit(40960);  //2015-05-06 (5538 bytes free)
        g_sEvilDuration = 900 + (integer)llFrand(900);
        // find the text prim
        integer linkNumber = llGetNumberOfPrims()+1;
        while (linkNumber-- >2){
            string desc = llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]),0);
            if (llSubStringIndex(desc, g_sPrimDesc) == 0) {
                if (llList2Integer(llGetLinkPrimitiveParams(linkNumber,[PRIM_TYPE]),0)==PRIM_TYPE_BOX){
                    g_iTextPrim = linkNumber;
                    llSetLinkPrimitiveParamsFast(g_iTextPrim,[PRIM_DESC,g_sPrimDesc+"~notexture~nocolor~nohide~noshiny"]);
                    linkNumber = 0 ; // break while cycle
                } else {
                    llSetLinkPrimitiveParamsFast(linkNumber,[PRIM_TEXT,"",<0,0,0>,0]);
                }
            }
        }
        g_kWearer = llGetOwner();
        g_sWearerName = "secondlife:///app/agent/"+(string)g_kWearer+"/about";  //quick and dirty default, will get replaced by value from settings
        
        if (g_iTextPrim < 0) {    //remove script if there is no title prim
            llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + "Titler", "");
            llRemoveInventory(llGetScriptName());
        }
        g_sCurrentTitleText="";
        renderTitle();
       /*
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "titler_title", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "titler_on", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "titler_lfmuser", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "titler_color", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "titler_height", "");
        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "titler_auth", "");
*/
        //Debug("Starting");
    } 

    http_response(key _id, integer _status, list _meta, string _data) {
        if (_id == g_kHttpRequestKey) {
            _data = llGetSubString(_data, llSubStringIndex(_data, ",") + 1, llSubStringIndex(_data, "\n") - 1);
            if(_data != g_sLastFmResponseText) {
                //Debug("Got different response:\n"+_data);
                //Debug("Was:\n"+g_sLastFmResponseText);
                g_sLastFmResponseText = _data;
                g_sLastFmTitle = _data;
                while (llStringLength(g_sLastFmTitle) < 22) g_sLastFmTitle = " "+g_sLastFmTitle+" ";
                g_sLastFmTitle+= "   //   ";
                llSetTimerEvent(0.2);

                renderTitle();
            }
        }
    }
    
    timer(){
        if (g_sType=="evil"){
            if (g_iEvilListenHandle){    //listener is already set, so we cancel it, and start a 5 minute timer until it opens again
                llListenRemove(g_iEvilListenHandle);
                g_iEvilListenHandle=0;
                Whisper("Awww, no one gave "+g_sWearerName+" a new title.  You'll have another chance later");
                llSetTimerEvent(g_sEvilDuration);
            } else {    //no listener, so set one up with a timer for 1 minute listening for a new title
                g_iEvilListenChannel=10+(integer)llFrand(89);
                Whisper("Now is YOUR chance to give "+g_sWearerName+" a goofy title.  Type it on channel "+(string)g_iEvilListenChannel+"!");
                g_iEvilListenHandle=llListen(g_iEvilListenChannel, "", "", "");
                llSetTimerEvent(g_sEvilTimeout);
            }
        } else if (g_sType=="lastfm") renderTitle();
    }
    
    listen(integer channel, string name, key id, string message){
        if (g_sType=="evil"){
            //assume any text on our channel is a new title
            if (id == g_kWearer) {
                string sObjectName = llGetObjectName();
                llSetObjectName("");
                Whisper("Oh really? "+ g_sWearerName + " tried to change their own title, how silly is that?");
                llSetObjectName(sObjectName);
                return;
            } else {
                string sTitleGiver = "secondlife:///app/agent/" + (string)id + "/about";
                Whisper(g_sWearerName +" has been blessed with the title \""+message+"\" they should thank " + sTitleGiver + " thouroughly.");
            
                g_sNormalTitleText=message;
                g_sCurrentTitleText=message;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript+"title="+g_sCurrentTitleText, "");
                renderTitle();
            }
        }
        llListenRemove(g_iEvilListenHandle);
        g_iEvilListenHandle=0;
        llSetTimerEvent(g_sEvilDuration);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        //Debug("Link Message Event");
        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == COMMAND_SAFEWORD){
            UserCommand(500, "title off", "");
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_ROOT, MENUNAME_RESPONSE, g_sParentMenu + "|" + "Titler", "");
        } else if (iNum == LM_SETTING_RESPONSE) {
            //Debug("Got setting \""+sStr+"\"");
            if( sStr == "settings=sent") renderTitle();
            else {
                string sGroup = llGetSubString(sStr, 0, llSubStringIndex(sStr, "_") );
                sStr=llDeleteSubString(sStr, 0, llSubStringIndex(sStr, "_"));
                string sToken = llGetSubString(sStr, 0, llSubStringIndex(sStr, "=")-1 );
                string sValue=llDeleteSubString(sStr, 0, llSubStringIndex(sStr, "=") );
                //Debug("Got my setting \""+sToken+"\"=\""+sValue+"\"");
                if (sGroup == g_sScript) {
                    if(sToken == "title") {
                        g_sCurrentTitleText = sValue;
                        g_sNormalTitleText = sValue;
                    } else if(sToken == "on") {
                        g_sType = sValue;
                        if (g_sType=="evil") llSetTimerEvent(0.2);
                        else if (g_sType=="lastfm") httpRequest();
                    } else if(sToken == "lfmuser") g_sLfmUser = sValue;
                    else if(sToken == "color") g_vColor = (vector)sValue;
                    else if(sToken == "height") g_vPrimScale.z = (float)sValue;
                    else if(sToken == "auth") g_iLastRank = (integer)sValue; // restore lastrank from DB
                    renderTitle();
                } else if(sGroup == "Global_") {
                    //Debug("Got setting \""+sGroup+sToken+"="+sValue+"\"");
                    if (sToken == "WearerName") g_sWearerName = sValue;
                }
            }
        } else if (iNum == DIALOG_RESPONSE) {
            if (kID == g_kDialogID) {   //response from our main menu
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == "Set Title") UserCommand(iAuth, "title set", kAv);
                else if (sMessage == "Color") UserCommand(iAuth, "menu titlercolor", kAv);
                else if (sMessage == UPMENU) llMessageLinked(LINK_SET, 0, "menu " + g_sParentMenu, kAv);
                else if (sMessage == "last.fm ID") UserCommand(iAuth, "title lastfm set", kAv);
                else {
                    if (sMessage == "↑ Up") UserCommand(iAuth, "title up", kAv);
                    else if (sMessage == "↓ Down") UserCommand(iAuth, "title down", kAv);
                    else if (sMessage == "☐ Normal") UserCommand(iAuth, "title on", kAv);
                    else if (sMessage == "☒ Normal") UserCommand(iAuth, "title off", kAv);
                    else if (sMessage == "☐ last.fm") UserCommand(iAuth, "title lastfm", kAv);
                    else if (sMessage == "☒ last.fm") UserCommand(iAuth, "title off", kAv);
                    else if (sMessage == "☐ Evil") UserCommand(iAuth, "title evil", kAv);
                    else if (sMessage == "☒ Evil") UserCommand(iAuth, "title off", kAv);
                    UserCommand(iAuth, "menu titler", kAv);
                }
            } else if (kID == g_kColourDialogID) {  //response form the colours menu
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                if (sMessage == UPMENU) UserCommand(iAuth, "title", kAv);
                else {
                    UserCommand(iAuth, "title color "+sMessage, kAv);
                    UserCommand(iAuth, "title color", kAv);
                }
                
            } else if (kID == g_kTBoxId) {  //response from text box
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                if(sMessage != "") UserCommand(iAuth, "title set " + sMessage, kAv);
                UserCommand(iAuth, "menu " + "Titler", kAv);
            } else if (kID == g_kLfmUserBoxId) {  //response from text box
                list lMenuParams = llParseStringKeepNulls(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                
                if(sMessage != "") UserCommand(iAuth, "title lastfm set " + sMessage, kAv);
                UserCommand(iAuth, "menu titler", kAv);
            }
        }
    }

    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
        if (iChange & CHANGED_INVENTORY) 
            if (llGetInventoryType("OpenCollar - titler") == INVENTORY_SCRIPT) llRemoveInventory("OpenCollar - titler"); //gives error if not there
        if (iChange & CHANGED_REGION) {
            httpRequest();
/*
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
*/
        }
        if ((iChange & CHANGED_TELEPORT) && g_sType=="evil") {
            if (g_iEvilListenHandle) {
                llListenRemove(g_iEvilListenHandle);
                g_iEvilListenHandle=0;
            }
            llSetTimerEvent(198);
        }
    }
}
