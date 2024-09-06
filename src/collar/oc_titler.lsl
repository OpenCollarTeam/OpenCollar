/*
This file is a part of OpenCollar.
Copyright 2021
: Contributors :
Aria (Tashia Redrose)
    * Mar 2020      - Fix bug where title would not detect the float text prim.
                    - Fixed bug where titler would display garbled text as a result of failing to decode base64
    * Jan 2020      - Rewrote titler to cleanup the code and make easier to read
    
Medea (Medea Destiny)
    Oct 2021    -   Refactored SAVE to only save changed settings. Added helpful menu text.
                    Added text2col() function that makes a sensible colour vector out of whatever
                    is thrown at it. Added Added validvector() function to confirm vectors are valid
                    before setting, used to make "[prefix] title color" command without following vector
                    provide colour menu rather than setting colour to black, and means that "[prefix]
                    title color red" will now pop up the color menu rather than setting the title text
                    to black. Text changes now set instantly rather than after 2.5 second delay.
   Sept 2023    -   Zero length titles via chat commands (i.e [prefix]title) were returning "title" as a title rather than opening the textbox as intended.  
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

string g_sParentMenu = "Apps";
string g_sSubMenu = "Titler";
string g_sVersion = "8.3"; // leave unmodified if not changed at all after release, otherwise change to next version number

DebugOutput(key kID, list ITEMS){
    integer i=0;
    integer end=llGetListLength(ITEMS);
    string final;
    for(i=0;i<end;i++){
        final+=llList2String(ITEMS,i)+" ";
    }
    llInstantMessage(kID, llGetScriptName() +" "+final);
}
integer LINK_CMD_DEBUG=1999;
integer g_iNoB64=FALSE; // Use base64 by default
integer g_iWasUpgraded=FALSE; // This will not harm anything if set to true after being upgraded. However, it should eventually be set to false again
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;



integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}
Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    string sPrompt = "\n[Titler]\n Use Up/Down to change the position of the title, Color to set text color, Set Title to set the title text. Show/Hide to choose whether the title should be displayed or not.";
    list lButtons = ["UP","DOWN", "Set Title", "Color", Checkbox(g_iShow, "Show")];
    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Titler");
}

ColorMenu(key kAv, integer iAuth){
    string sPrompt = "\n[Titler]\nColor selection";
    //list lButtons = ["White", "Green", "Yellow", "Cyan", "Blue", "Pink", "Orange"];
    Dialog(kAv, sPrompt, ["colormenu please"], [UPMENU, "Custom"], 0, iAuth, "Menu~Colors");
}

integer validvector(string input)
{
    list t=llParseString2List(input,[",","<",">"," "],[]);
    if(llGetListLength(t)!=3) return FALSE;
    t=llParseString2List(input,[",","<",">"," ","."],[]);
    string s=(string)t;
    integer x=llStringLength(s);
    while(x) {
        --x;
        if(llGetSubString(s,x,x)!="0" && (integer)llGetSubString(s,x,x)==0) return FALSE;
        }
    return TRUE;
}
        
vector text2col(string input)
{
    list t=llParseString2List(input,[",","<",">"," "],[]);
    integer norm;
    integer x;
    integer this;
    while(x<3)
    {
        this=llList2Integer(t,x);
        if(this<0) t=llListReplaceList(t,[0],x,x);
        else if(this>1) norm=TRUE;
        if(this>255) t=llListReplaceList(t,[255],x,x);
        ++x;
    }
    vector out=(vector)("<"+llList2CSV(t)+">");
    if(norm) out=out/255;
    return out;
}
        

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    //if (llSubStringIndex(llToLower(sStr),llToLower(g_sSubMenu)) && llToLower(sStr) != "menu "+llToLower(g_sSubMenu)) return;
    if (iNum == CMD_OWNER && sStr == "runaway") {
        g_lOwner = g_lTrust = g_lBlock = [];
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0;
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llToLower(llList2String(llParseString2List(sStr, [" "], []),1));
        string sParam = llList2String(llParseString2List(sStr, [" "], []),2);
        //string sText;
        if(iNum !=CMD_OWNER)return;

        if(sChangetype == "title"){
            if(sChangevalue == ""){
                Dialog(kID, "What should the title say?", [], [], 0, iNum, "Textbox~Title");
                return;
            }
            g_sTitle=llDumpList2String(llList2List(llParseString2List(sStr,[" "],[]), 1,-1)," ");
            Save(SAVE_TITLE);
        } else if(sChangetype == "titler"){
            if(sChangevalue == "color"){
                if(!validvector(sParam)) ColorMenu(kID,iNum);
                else {
                    g_vColor=text2col(sParam);
                    Save(SAVE_COLOR);
                }
            } else if(sChangevalue == "show"){
                g_iShow=TRUE;
                Save(SAVE_SHOW_HIDE);
            } else if(sChangevalue == "hide"){
                g_iShow=FALSE;
                Save(SAVE_SHOW_HIDE);
            } else if(sChangevalue == "up"){
                g_iOffset++;
                Save(SAVE_OFFSET);
            } else if(sChangevalue == "down"){
                g_iOffset--;
                if(g_iOffset<0)g_iOffset=0;
                Save(SAVE_OFFSET);
            }else if(sChangevalue == "plain"){
                g_iNoB64 = ! g_iNoB64;
                Save(SAVE_TITLE);

                string ToggleMsg = "0Titler plain text mode is now set to ";

                if(g_iNoB64) {
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_plain=1", "");
                    ToggleMsg += "PLAIN";
                } else {
                    ToggleMsg += "BASE64";
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "titler_plain", "");
                }
                llMessageLinked(LINK_SET, NOTIFY, ToggleMsg, kID);
            } else if(sChangevalue == "title"){
                g_sTitle = llDumpList2String(llList2List(llParseString2List(sStr,[" "],[]), 2,-1)," ");
                UserCommand(iNum, "title "+g_sTitle, kID);
            }
        }
    }
}
integer g_iShow=FALSE;

integer  SAVE_SHOW_HIDE = 1;
integer  SAVE_OFFSET = 2;
integer  SAVE_TITLE = 4;
integer  SAVE_COLOR = 8;

Save(integer what){
    if(what&SAVE_SHOW_HIDE){
        if(g_iShow)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_show=1","");
        else llMessageLinked(LINK_SET, LM_SETTING_DELETE, "titler_show","");
    }
    if(what&SAVE_OFFSET)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_offset="+(string)g_iOffset, "");
    if(what&SAVE_TITLE){
        if(!g_iNoB64)
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_title="+llStringToBase64(g_sTitle), "");
        else
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_title="+g_sTitle, "");
    }
    if(what&SAVE_COLOR)llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_color="+(string)g_vColor,"");


    Titler();
}

Titler(){
    // llSetTimerEvent(2.5);
    // Show the title if applicable after 5 seconds
    //Why should this be done with a delay??? Moving it here.
    if(g_iShow){
            string offsets = "";
            integer i=0;
            for(i=0;i<g_iOffset;i++){
                offsets+=" \n";
            }
            llSetLinkPrimitiveParams(g_iTextPrim, [PRIM_TEXT, g_sTitle+offsets, g_vColor, 1]);
    }else llSetLinkPrimitiveParams(g_iTextPrim, [PRIM_TEXT, "", ZERO_VECTOR, 0]);
}
key g_kWearer;
integer g_iOffset=8;
vector g_vColor = <1,1,1>;
string g_sTitle;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;
integer g_iTextPrim;

ScanFloatText(){
    integer i=LINK_ROOT;
    integer end = llGetNumberOfPrims();

    for(i=0;i<=end;i++){
        list Params = llGetLinkPrimitiveParams(i, [PRIM_NAME,PRIM_DESC]);
        if(llSubStringIndex(llList2String(Params,0), "FloatText")!=-1){
            g_iTextPrim = i;
            return;
        }

        if(llSubStringIndex(llList2String(Params,1), "FloatText")!=-1){
            g_iTextPrim=i;
            return;
        }
    }
    g_iTextPrim=LINK_THIS;
}

NukeOtherText(){
    integer i = 1;
    integer end = llGetNumberOfPrims();
    for(i=1;i<=end;i++){
        llSetLinkPrimitiveParamsFast(i,[PRIM_TEXT, "", ZERO_VECTOR,0]);
    }
}
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT){
            if(sStr == "reboot"){
                llResetScript();
            }
        } else if(iNum == READY){
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP){
            state active;
        }
    }
}
state active
{
    on_rez(integer t){
        llResetScript();
    }
    state_entry()
    {
        if(llGetStartParameter()!=0)llResetScript();
        llSetMemoryLimit(40000);
        g_kWearer = llGetOwner();

        NukeOtherText();
        //llOwnerSay((string)llGetUsedMemory());
    }

    changed(integer iChange){
        if(iChange&CHANGED_LINK){
            integer iCur = g_iTextPrim;
            ScanFloatText();
            if(g_iTextPrim!=iCur)NukeOtherText();
            Titler();

        }
    }

    link_message(integer iSender,integer iNum,string sStr,key kID){
        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                integer iRespring=TRUE;

                // There's really nothing that non-owner could change down here, so..
                if(iAuth != CMD_OWNER){
                    llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to titler options", kAv);
                    llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    return;
                }
                if(sMenu == "Menu~Titler"){

                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                    else if(sMsg == "UP"){
                        g_iOffset++;

                        Save(SAVE_OFFSET);
                    } else if(sMsg == "DOWN"){
                        g_iOffset--;
                        if(g_iOffset<0)g_iOffset=0;
                        Save(SAVE_OFFSET);
                    } else if(sMsg == Checkbox(g_iShow,"Show")){
                        g_iShow=!g_iShow;
                        Save(SAVE_SHOW_HIDE);

                    } else if(sMsg == "Set Title"){
                        iRespring=FALSE;
                        Dialog(kAv, "What should the title say?", [], [], 0, iAuth, "Textbox~Title");

                    } else if(sMsg == "Color")
                    {
                        // Open default colors menu
                        ColorMenu(kAv,iAuth);
                        iRespring=FALSE;
                    }

                    if(iRespring)Menu(kAv,iAuth);
                } else if(sMenu == "Menu~Colors"){
                    if(sMsg == UPMENU){
                        Menu(kAv, iAuth);
                        iRespring=FALSE;
                    } else if(sMsg == "Custom"){
                        Dialog(kAv, "[Titler Custom Color]\nType in a custom colour using the R,G,B format, i.e. '255,0,0' gives pure red.", [], [], 0, iAuth, "Textbox~Color");
                        iRespring=FALSE;
                    } else  {
                        g_vColor = (vector)sMsg;
                    }

                    if(iRespring)ColorMenu(kAv,iAuth);

                    Save(SAVE_COLOR);
                } else if(sMenu == "Textbox~Title"){
                    g_sTitle = sMsg;

                    // pop menu back up
                    Menu(kAv, iAuth);
                    Save(SAVE_TITLE);
                } else if(sMenu == "Textbox~Color"){
                    if(!validvector(sMsg)) {
                        llRegionSayTo(kAv,0,"Not a valid vector! Please try again.");
                        Dialog(kAv, "[Titler Custom Color]\nType in a custom colour using the R,G,B format, i.e. '255,0,0' gives pure red.", [], [], 0, iAuth, "Textbox~Color");
                        return;
                    }
                    g_vColor = text2col(sMsg);
                    ColorMenu(kAv,iAuth);
                    Save(SAVE_COLOR);
                }
            }
        }else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);


            //integer ind = llListFindList(g_lSettingsReqs, [llList2String(lSettings,0)+"_"+llList2String(lSettings,1)]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);


            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1)=="locked"){
                    g_iLocked=llList2Integer(lSettings,2);
                } else if(llList2String(lSettings,1) == "checkboxes"){
                    g_lCheckboxes = llCSV2List(llList2String(lSettings,2));
                }
            } else if(llList2String(lSettings,0) == "titler"){
                integer curPrim=g_iTextPrim;
                ScanFloatText();

                if(g_iTextPrim!=curPrim)NukeOtherText(); // permit changing the float text prim

                if(llList2String(lSettings,1) == "show"){
                    g_iShow=TRUE;
                }else if(llList2String(lSettings,1) == "offset"){
                    g_iOffset=(integer)llList2String(lSettings,2);
                }else if(llList2String(lSettings,1) == "title"){
                    if(!g_iNoB64)
                        g_sTitle = llBase64ToString(llList2String(lSettings,2)); // We can't really check if this is a base64 string
                    else
                        g_sTitle = llList2String(lSettings,2);

                    if(g_iWasUpgraded) {
                        g_sTitle = llList2String(lSettings,2);
                        if(!g_iNoB64)
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_title="+llStringToBase64(g_sTitle), "");
                        else
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_title="+g_sTitle, "");
                        g_iWasUpgraded=FALSE;
                    }
                } else if(llList2String(lSettings,1)=="color"){
                    g_vColor=(vector)llList2String(lSettings,2);
                } else if(llList2String(lSettings,1) == "on"){
                    // this was definitely a upgrade. Re-request!
                    g_iWasUpgraded=TRUE;
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");

                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "titler_auth", "");
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "titler_on", "");
                    llMessageLinked(LINK_SET, LM_SETTING_DELETE, "titler_height", "");

                    g_iShow=(integer)llList2String(lSettings,2);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "titler_show="+(string)g_iShow, "");
                } else if(llList2String(lSettings,1) == "plain"){
                    g_iNoB64 = TRUE;
                    llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "ALL", "");
                }
                Titler();
            }

        }else if(iNum == LM_SETTING_EMPTY){

            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);

        } else if(iNum == LM_SETTING_DELETE){
            list lPar = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);

            //integer ind = llListFindList(g_lSettingsReqs, [sStr]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);

            if(sToken=="global")
                if(sVar == "locked") g_iLocked=FALSE;
        } else if(iNum == LINK_CMD_DEBUG){
            // send data
            if(sStr == "ver"){
                // only version
                DebugOutput(kID, ["VERSION:",g_sVersion]);
                return;
            }

            DebugOutput(kID, ["SHOW",g_iShow]);
            DebugOutput(kID, ["TITLE:",g_sTitle]);
            DebugOutput(kID, ["COLOR:",g_vColor]);
            DebugOutput(kID, ["OFFSET:",g_iOffset]);
            DebugOutput(kID, ["FLOATTEXT:",g_iTextPrim]);
        } else if(iNum == REBOOT && sStr == "reboot")  llResetScript();
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}
