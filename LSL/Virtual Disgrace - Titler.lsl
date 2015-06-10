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
//integer CMD_ZERO = 0;
integer CMD_OWNER          = 500;
//integer CMD_TRUSTED       = 501;
//integer CMD_GROUP       = 502;
integer CMD_WEARER          = 503;
integer CMD_EVERYONE        = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD        = 510; 
//integer CMD_RELAY_SAFEWORD= 511;
//integer CMD_BLOCKED = 520;

//integer SEND_IM = 1000; deprecated. each script should send its own IMs now. This is to reduce even the tiny bt of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;
integer NOTIFY = 1002;
integer SAY = 1004;
//integer UPDATE = 10001;

integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;


integer g_iLastRank = CMD_EVERYONE ;
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
integer g_iScrollOn;
string g_sScrollTitleText;
vector g_vCurrentColor;
integer g_iRainbow;
integer g_iCount;

vector g_vColor = <1.000, 1.000, 0.000>; // default white 

integer g_iTextPrim=-1;
//string g_sScript= "titler_";
float g_sEvilTimeout=60;
float g_sEvilDuration=1800;

key g_kWearer;
string g_sSettingToken = "titler_";
//string g_sGlobalToken = "global_";

key g_kDialogID;    //menu handle
key g_kColorDialogID;    //menu handle
key g_kTBoxId;      //text box handle
key g_kLfmUserBoxId;      //text box handle

string UPMENU = "BACK";
float min_z = 0.25 ; // min height
float max_z = 1.0 ; // max height
vector g_vPrimScale = <0.08,0.08,0.4>; // prim size, initial value (z - text offset height)

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
        if (g_iScrollOn) {
            g_sScrollTitleText += llGetSubString(g_sScrollTitleText,0,0);
            g_sScrollTitleText = llGetSubString(g_sScrollTitleText,1,-1);
            g_sCurrentTitleText = llGetSubString(g_sScrollTitleText,0,24);
        }
    } 
    if (g_sType!="evil" && g_iRainbow) {
        if (g_iCount > 3) {
            g_vCurrentColor = <llFrand(1.0),llFrand(1.0),llFrand(1.0)>;
            g_iCount = 0;
            llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT,g_sCurrentTitleText,g_vCurrentColor,1.0, PRIM_SIZE,g_vPrimScale, PRIM_SLICE,<0.490,0.51,0.0>]);
            return;
        }
        g_iCount++;
        if (!g_iScrollOn && g_sType!="lastfm") return;
    } else g_vCurrentColor = g_vColor;
    //Debug("Rendering title:\""+g_sCurrentTitleText+"\"");
    //Debug("Rendering title ("+(string)g_iTextPrim+"):"+g_sCurrentTitleText);
    llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT,g_sCurrentTitleText,g_vCurrentColor,1.0, PRIM_SIZE,g_vPrimScale, PRIM_SLICE,<0.490,0.51,0.0>]);
}

UserCommand(integer iAuth, string sStr, key kAv){
    if (iAuth < CMD_OWNER || iAuth > CMD_WEARER) return;
    
    //first, jongle commands into a sane format
    if (llToLower(sStr) == "menu titler") sStr="title";
    else if (llToLower(sStr) == "menu titlercolor") sStr="title color";
    else if (sStr == "runaway" && (iAuth == CMD_OWNER || iAuth == CMD_WEARER)) {
        g_sType = "off";
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"on="+g_sType, "");
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
        sCommand = llToLower(llList2String(lParams, 0));
        
        if (iAuth > g_iLastRank) {    //only change titler settings if commander has same or greater auth  
            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS", kAv);           
            //Notify(kAv,g_sAuthError, FALSE);
        } else if (sCommand=="color") {
            string sColor= llDumpList2String(llDeleteSubList(lParams,0,0)," ");
            if (sColor != "") {    //we got a colour, so set the colour
               g_vColor=(vector)sColor;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"color="+(string)g_vColor, "");
                renderTitle();
            } else {    //no colour given, so pop the dialog.
                g_kColorDialogID = Dialog(kAv, "\nChoose a color!", ["colormenu please"], [UPMENU],0, iAuth);
                return;
            }
        } else if (sCommand == "on") {
            g_sType = "normal";
            g_iLastRank = iAuth;
            g_sCurrentTitleText = g_sNormalTitleText;
            evilListenerOff();
            if (g_iRainbow || g_iScrollOn) llSetTimerEvent(0.2);
            else llSetTimerEvent(0.0);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"on="+g_sType, "");
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
        } else if (sCommand == "off") {
            g_sType = "off";
            g_iLastRank = CMD_EVERYONE;
            g_sCurrentTitleText="";
            evilListenerOff();
            llSetTimerEvent(0.0);
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"on="+g_sType, "");
            llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"auth", ""); // del lastrank from DB
        } else if (sCommand == "scroll") {
            if (llToLower(llList2String(lParams, 1)) == "on") {
                if (g_sType == "evil") {
                    llMessageLinked(LINK_SET,NOTIFY,"0"+"Titler scroll is in evil mode not supported.",kAv);
                    return;
                }
                g_iScrollOn = TRUE;
                g_sScrollTitleText = g_sNormalTitleText+" ";
                renderTitle();
                llSetTimerEvent(0.2);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"scroll="+(string)g_iScrollOn, "");
            } else if (llToLower(llList2String(lParams, 1)) == "off") {
                g_iScrollOn = FALSE;
                renderTitle();
                if (g_sType == "normal" && !g_iRainbow) llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"scroll", "");
            }
        } else if (sCommand == "rainbow") {
            if (g_sType == "evil") {
                llMessageLinked(LINK_SET,NOTIFY,"0"+"Rainbow is in evil mode not supported.",kAv);
                return;
            }
            if (llToLower(llList2String(lParams, 1)) == "on") {
                g_iRainbow = TRUE;
                renderTitle();
                llSetTimerEvent(0.2);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"rainbow="+(string)g_iRainbow, "");
            } else if (llToLower(llList2String(lParams, 1)) == "off") {
                g_iRainbow = FALSE;
                renderTitle();
                if (g_sType == "normal" && !g_iScrollOn) llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"rainbow", "");
            }
        } else if (sCommand == "lastfm") {
            string sAction= llList2String(lParams,1);
            if (sAction == "") {    //set lastfm mode on
                evilListenerOff();
                //Debug("doing "+sCommand);
                g_sType = "lastfm";
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"on="+g_sType, "");
                g_sCurrentTitleText="";
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"title", "");
                g_iLastRank = iAuth;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
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
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"lfmuser="+g_sLfmUser, "");
                g_iLastRank = iAuth;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
                if (g_sType=="lastfm"){
                    g_sCurrentTitleText="";
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"title", "");
                    httpRequest();
                }
            }
        } else if (sCommand == "evil") {
            //Debug("doing "+sCommand);
            if (g_iScrollOn) {
                g_iScrollOn = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"scroll", "");
            }
            if (g_iRainbow) {
                g_iRainbow = FALSE;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sSettingToken+"rainbow", "");
            }
            llSetTimerEvent(0.2);
            g_sType = "evil";
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"on="+g_sType, "");
            g_iLastRank = iAuth;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
            g_sCurrentTitleText="";
        } else if (sCommand == "up") {
            g_vPrimScale.z += 0.05 ;
            if(g_vPrimScale.z > max_z) g_vPrimScale.z = max_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"height="+(string)g_vPrimScale.z, "");
        } else if (sCommand == "down") {
            g_vPrimScale.z -= 0.05 ;
            if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"height="+(string)g_vPrimScale.z, "");
        } else {    //looks like we're setting the title, or popping a text box to ask for one
            if (sCommand=="") {    //<nothing>            pop main titler menu
                string sPrompt = "\n[http://www.virtualdisgrace.com/titler Virtual Disgrace - Titler]\n\nCurrent Title: " + g_sNormalTitleText;
                    
                string normalButton ;
                if(g_sType == "normal" || g_sType == "scroll") normalButton = "☒ Normal" ;
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
                if (g_iScrollOn || g_iRainbow) llSetTimerEvent(0.2);
                else llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"title="+g_sCurrentTitleText, "");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"on="+g_sType, "");
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, ""); // save lastrank to DB
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
        llSetMemoryLimit(45056);  
        g_sEvilDuration = 990 + (integer)llFrand(900);
        // find the text prim
        integer linkNumber = llGetNumberOfPrims()+1;
        while (linkNumber-- >2){
            string desc = llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]),0);
            if (llSubStringIndex(desc, g_sPrimDesc) == 0) {
                    g_iTextPrim = linkNumber;
                    llSetLinkPrimitiveParamsFast(g_iTextPrim,[PRIM_TYPE_CYLINDER,0,<0.0,1.0,0.0>,0.0,ZERO_VECTOR,<1.0,1.0,0.0>,ZERO_VECTOR,PRIM_DESC,g_sPrimDesc+"~notexture~nocolor~nohide~noshiny~noglow"]);
                    linkNumber = 0 ; // break while cycle
                } else {
                    llSetLinkPrimitiveParamsFast(linkNumber,[PRIM_TEXT,"",<0,0,0>,0]);
                }
            }
        g_kWearer = llGetOwner();
        //g_sWearerName = "secondlife:///app/agent/"+(string)g_kWearer+"/about";  //quick and dirty default, will get replaced by value from settings
        
        if (g_iTextPrim < 0) {    //remove script if there is no title prim
            llMessageLinked(LINK_SET, MENUNAME_REMOVE, g_sParentMenu + "|" + "Titler", "");
            llRemoveInventory(llGetScriptName());
        }
        g_sCurrentTitleText="";
        renderTitle();
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
                llMessageLinked(LINK_SET,SAY,"1"+"Awww, no one gave %WEARERNAME% a new title.  You'll have another chance later","");
                llSetTimerEvent(g_sEvilDuration);
            } else {    //no listener, so set one up with a timer for 1 minute listening for a new title
                g_iEvilListenChannel=10+(integer)llFrand(89);
                llMessageLinked(LINK_SET,SAY,"1"+"Now is YOUR chance to give %WEARERNAME% a goofy title.  Type it on channel "+(string)g_iEvilListenChannel+"!","");
                g_iEvilListenHandle=llListen(g_iEvilListenChannel, "", "", "");
                llSetTimerEvent(g_sEvilTimeout);
            }
        } else if (g_sType=="lastfm" || g_iScrollOn || g_iRainbow) renderTitle();
    }
    
    listen(integer channel, string name, key id, string message){
        if (g_sType=="evil"){
            //assume any text on our channel is a new title
            if (id == g_kWearer) {
                llMessageLinked(LINK_SET,SAY,"1"+"Oh really? %WEARERNAME% tried to change their own title, how silly is that?","");
                return;
            } else {
                string sTitleGiver = "secondlife:///app/agent/" + (string)id + "/about";
                llMessageLinked(LINK_SET,SAY,"1"+"%WEARERNAME% has been blessed with the title \""+message+"\" they should thank " + sTitleGiver + " thouroughly.","");
                g_sNormalTitleText=message;
                g_sCurrentTitleText=message;
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sSettingToken+"title="+g_sCurrentTitleText, "");
                renderTitle();
            }
        }
        llListenRemove(g_iEvilListenHandle);
        g_iEvilListenHandle=0;
        llSetTimerEvent(g_sEvilDuration);
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        //Debug("Link Message Event");
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if (iNum == CMD_SAFEWORD){
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
                if (sGroup == g_sSettingToken) {
                    if(sToken == "title") {
                        g_sCurrentTitleText = sValue;
                        g_sNormalTitleText = sValue;
                        g_sScrollTitleText = sValue;
                    } else if(sToken == "on") {
                        g_sType = sValue;
                        if (g_sType=="evil") llSetTimerEvent(0.2);
                        else if (g_sType=="lastfm") httpRequest();
                    } else if(sToken == "lfmuser") g_sLfmUser = sValue;
                    else if(sToken == "color") g_vColor = (vector)sValue;
                    else if(sToken == "height") g_vPrimScale.z = (float)sValue;
                    else if(sToken == "auth") g_iLastRank = (integer)sValue; // restore lastrank from DB
                    else if(sToken == "scroll") {
                        g_iScrollOn = (integer)sValue;
                        llSetTimerEvent(0.2);
                    } else if(sToken == "rainbow") {
                        g_iRainbow = (integer)sValue;
                        llSetTimerEvent(0.2);
                    }
                   // renderTitle();
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
            } else if (kID == g_kColorDialogID) {  //response form the colours menu
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
            if (llGetInventoryType("OpenCollar - titler") == INVENTORY_SCRIPT) llRemoveInventory("OpenCollar - titler"); 
        if (iChange & CHANGED_REGION) {
            httpRequest();
/*      if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }*/
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
