// This file is part of OpenCollar.
// Copyright (c) 2007 - 2020 Schmobag Hogfather, Nandana Singh,
// Cleo Collins, Satomi Ahn, Joy Stipe, Wendy Starfall, littlemousy,
// Romka Swallowtail, Garvin Twine, and Tashia Redrose,  et al.
// Licensed under the GPLv2.  See LICENSE for full details.
/*
Medea Destiny -

    Sep 2021  - Optimised substitutions by shortcutting no match for % in string after %NOACCESS% and %WEARER%
              - Replaced GetTruncatedString function with far more optimised function
              - Restored dialog chatting over-long prompts in local, which seems to have got lost somewhere. Improved
                version of function now works with prompts of any length and does not break up words.
              - Changed prompt for button descriptions in local chat from "Please check..." to "See..." to trigger it less often
              - Added warning text to prompt when prompt is trunctated, so menu prompt text will now show "(CONT. IN LOCAL CHAT)"
    Mar 2024  - Emergency fix for extended sensor function flooding memory and crashing script

Nikki Lacrima
    Aug 2023  - Changed functions for clearing auth so  auth doesn't persist for open menus
    Sep 2024  - Invalidate all menus except wearer when public or group mode is turned off

*/
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer NOTIFY = 1002;
integer NOTIFY_OWNERS=1003;
integer SAY = 1004;
integer REBOOT = -1000;
//integer LOADPIN = -1904;
//integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
integer DIALOG_RENDER = -9013;


//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;


integer g_iVerbosityLevel=1;

integer g_iPagesize = 12;
string MORE = "►";
string PREV = "◄";
string UPMENU = "BACK"; // string to identify the UPMENU button in the utility lButtons
//string SWAPBTN = "swap";
//string SYNCBTN = "sync";
string BLANK = " ";
integer g_iTimeOut = 300;
integer g_iReapeat = 5;//how often the timer will go off, in seconds

list g_lMenus;//13-strided list in form listenChan, dialogid, listener, starttime, recipient, prompt, list buttons, utility buttons, currentpage, button digits, auth level,extra info, sorted
//where "list buttons" means the big list of choices presented to the user
//and "page buttons" means utility buttons that will appear on every page, such as one saying "go up one level"
//and "currentpage" is an integer meaning which page of the menu the user is currently viewing
integer g_iStrideLength = 13;
integer SENSORDIALOG = -9003;

string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}
key g_kWearer;
//string g_sSettingToken = "dialog_";
string g_sGlobalToken = "global_";
integer g_iListenChan=1;
string g_sPrefix;
string g_sDeviceType = "collar";
string g_sDeviceName;
string g_sWearerName;
list g_lOwners;


list g_lSensorDetails;
integer g_bSensorLock;
integer g_iSensorTimeout;

string SubstituteVars(string sMsg) {
        if (~llSubStringIndex(sMsg, "%NOACCESS"))
            sMsg = llDumpList2String(llParseStringKeepNulls(sMsg, ["%NOACCESS%"], []), "Access Denied");
        if (~llSubStringIndex(sMsg, "%WEARERNAME%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%WEARERNAME%"], []), g_sWearerName);
        if (llSubStringIndex(sMsg,"%")==-1) return sMsg; //Substitutions below are rare, this will save work most of the time.
        if (~llSubStringIndex(sMsg, "%PREFIX%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%PREFIX%"], []), g_sPrefix);
        if (~llSubStringIndex(sMsg, "%CHANNEL%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%CHANNEL%"], []), (string)g_iListenChan);
        if (~llSubStringIndex(sMsg, "%DEVICETYPE%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, ["%DEVICETYPE%"], []), g_sDeviceType);
        
        if(~llSubStringIndex(sMsg, "%DEVICENAME%"))
            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg="")+sMsg, ["%DEVICENAME%"],[]),g_sDeviceName);

        return sMsg;
}
Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if(g_iVerbosityLevel<1)return;
    if ((key)kID){
        sMsg = SubstituteVars(sMsg);
        string sObjectName = llGetObjectName();
        if (g_sDeviceName != sObjectName) llSetObjectName(g_sDeviceName);
        if (kID == g_kWearer) llOwnerSay(sMsg);
        else {
            if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
            else llInstantMessage(kID, sMsg);
            if (iAlsoNotifyWearer) llOwnerSay(sMsg);
        }
        llSetObjectName(sObjectName);
    }//else Debug("something went wrong in Notify, Msg: \""+sMsg+"\" is missing an ID to be sent to.");

    //llSay(0, "(debug collarmsg) "+sMsg);
}

NotifyOwners(string sMsg, string comments) {
    integer n;
    integer iStop = llGetListLength(g_lOwners);
    for (; n < iStop; ++n) {
        key kAv = (key)llList2String(g_lOwners, n);
        if (comments=="ignoreNearby") {
            //we don't want to bother the owner if he/she is right there, so check distance
            vector vOwnerPos = (vector)llList2String(llGetObjectDetails(kAv, [OBJECT_POS]), 0);
            if (vOwnerPos == ZERO_VECTOR || llVecDist(vOwnerPos, llGetPos()) > 20.0) {//vOwnerPos will be ZERO_VECTOR if not in sim
                //Debug("notifying " + (string)kAv);
                //Debug("Sending notify to "+(string)kAv);
                Notify(kAv, sMsg,FALSE);
            //} else {
                //Debug("Not sending notify to "+(string)kAv);
            }
        } else {
            //Debug("Sending notify to "+(string)kAv);
            Notify(kAv, sMsg,FALSE);
        }
    }
}

integer IsLikelyAvatar(key kID){
    if(llGetAgentSize(kID)!=ZERO_VECTOR)return TRUE;
    else if(llGetOwnerKey(kID) == kID)return TRUE;
    else return FALSE;
}

Say(string sMsg, integer iWhisper) {
    if(g_iVerbosityLevel<1)return;
    sMsg = SubstituteVars(sMsg);
    string sObjectName = llGetObjectName();
    llSetObjectName("");
    if (iWhisper) llWhisper(0,"/me "+sMsg);
    else llSay(0, sMsg);
    llSetObjectName(sObjectName);
}

list g_lColors = [
            "Red",<1.00000, 0.00000, 0.00000>,
            "Green",<0.00000, 1.00000, 0.00000>,
            "Blue",<0.00000, 0.50196, 1.00000>,
            "Yellow",<1.00000, 1.00000, 0.00000>,
            "Pink",<1.00000, 0.50588, 0.62353>,
            "Brown",<0.24314, 0.14902, 0.07059>,
            "Purple",<0.62353, 0.29020, 0.71765>,
            "Black",<0.00000, 0.00000, 0.00000>,
            "White",<1.00000, 1.00000, 1.00000>,
            "Barbie",<0.91373, 0.00000, 0.34510>,
            "Orange",<0.96078, 0.60784, 0.00000>,
            "Toad",<0.25098, 0.25098, 0.00000>,
            "Khaki",<0.62745, 0.50196, 0.38824>,
            "Pool",<0.14902, 0.88235, 0.94510>,
            "Blood",<0.42353, 0.00000, 0.00000>,
            "Gray",<0.70588, 0.70588, 0.70588>,
            "Anthracite",<0.08627, 0.08627, 0.08627>,
            "Midnight",<0.00000, 0.10588, 0.21176>
];

Dialog(key kRecipient, string sPrompt, list lMenuItems, list lUtilityButtons, integer iPage, key kID, integer iWithNums, integer iAuth, string extraInfo, integer iSorted)
{
    //calculate page start and end
    integer iNumitems = llGetListLength(lMenuItems);
    integer iStart = 0;
    integer iMyPageSize = g_iPagesize - llGetListLength(lUtilityButtons);
    if (extraInfo == "avimenu") { //we have to reduce buttons due to text length limitations we reach with URI
        iMyPageSize = iMyPageSize-3; // june 2015 Otto(garvin.twine)
        if (iNumitems == 8) iMyPageSize = iMyPageSize-1;
        //special cases again are 7 or 8 avis where we have to reduce "active" buttons again
        else if (iNumitems == 7) iMyPageSize = iMyPageSize-2;
    }
    string sPagerPrompt;
    if (iNumitems > iMyPageSize) {
        iMyPageSize=iMyPageSize-2;//we'll use two slots for the MORE and PREV button, so shrink the page accordingly

        integer numPages=(iNumitems-1)/iMyPageSize;
        if (iPage>numPages)iPage=0;
        else if (iPage<0) iPage=numPages;

        iStart = iPage * iMyPageSize;
        //multi page menu
        sPagerPrompt = sPagerPrompt + "\nPage "+(string)(iPage+1)+"/"+(string)(numPages+1);
    }
    integer iEnd = iStart + iMyPageSize - 1;
    if (iEnd >= iNumitems) iEnd = iNumitems - 1;
    integer iPagerPromptLen = GetStringBytes(sPagerPrompt);
    //Debug("start at "+(string)iStart+", end at "+(string)iEnd);

    //if we've been told to, calculate numbering from buttons supplied, inlined ButtonDigits function
    if (iWithNums == -1) {
        integer iNumButtons=llGetListLength(lMenuItems);
        iWithNums=llStringLength((string)iNumButtons);
        //if ( iNumButtons < 10 ) iWithNums = 1;
        //else if (iNumButtons < 100) iWithNums = 2;
        //else if (iNumButtons < 1000) iWithNums = 3; // more than 100 is unlikely, considering the size of a LM
        while (iNumButtons--) {
            if (GetStringBytes(llList2String(lMenuItems,iNumButtons))>18) {
                jump longButtonName;  //one of the options is too long for a button, thats all we need to know.
            }
        }
        iWithNums=0;
        @longButtonName;
    }
    //Debug("numbered list:"+(string)iWithNums);
    // create list of buttons to use, and number them if needed
    string sNumberedButtons;
    integer iNBPromptlen;
    list lButtons;  //list of buttons to be used in the dialog, sliced by page and maybe with numbers added, not the lMenuItems we were supplied
    if (iWithNums) { // put numbers in front of buttons: "00 Button1", "01 Button2", ...
        integer iCur;
        sNumberedButtons="\n"; //let's make this a linebreak instead
        integer iStartNum = (iPage*iMyPageSize);
        for (iCur = iStart; iCur <= iEnd; iCur++) {
            string sButton = llList2String(lMenuItems, iCur);
            if ((key)sButton) {
                //fixme: inlined single use key2name function
                if(IsLikelyAvatar((key)sButton)){
                    if(llGetAgentSize((key)sButton)==ZERO_VECTOR)
                        sButton = NameURI((key)sButton);
                    else
                        sButton = llGetDisplayName(sButton)+" ("+llKey2Name(sButton)+")";
                }
                else sButton=llKey2Name((key)sButton);
            }
            lButtons += [sButton];
        }

        iEnd = llGetListLength(lButtons);
        for(iCur=0;iCur<iEnd;iCur++){
            string sButton = llList2String(lButtons,iCur);
            //inlined single use Integer2String function
            string sButtonNumber = (string)iStartNum;
            iStartNum++;
            while (llStringLength(sButtonNumber)<iWithNums)
               sButtonNumber = "0"+sButtonNumber;
            sButton=sButtonNumber + " " + sButton;
            //Debug("ButtonNumber="+sButtonNumber);

            sNumberedButtons+=sButton+"\n";
            sButton = TruncateString(sButton, 24);
            if(llSubStringIndex(sButton, "secondlife://")!=-1) sButton = sButtonNumber;


            lButtons = llListReplaceList(lButtons, [sButton], iCur,iCur);
        }
        iNBPromptlen=GetStringBytes(sNumberedButtons);
    } else if (iNumitems > iMyPageSize) lButtons = llList2List(lMenuItems, iStart, iEnd);
    else  lButtons = lMenuItems;
    //Debug("buttons:"+llDumpList2String(lButtons,","));
    sPrompt = SubstituteVars(sPrompt);
    //make a prompt small enough to fit in the 512 limit for dialogs, prepare overflow for chat message
    integer iPromptlen=GetStringBytes(sPrompt);
    string sThisPrompt;
    string sThisChat;
    if (iPromptlen + iNBPromptlen + iPagerPromptLen < 512) //we can fit it all in the dialog
        sThisPrompt = sPrompt + sNumberedButtons + sPagerPrompt ;
    else if (iPromptlen + iPagerPromptLen < 512) { //we can fit in the whole prompt and pager info, but not the buttons list
        if (iPromptlen + iPagerPromptLen < 468) {
            sThisPrompt = sPrompt + "\nSee nearby chat for button descriptions.\n" + sPagerPrompt;
        } else
            sThisPrompt = sPrompt + sPagerPrompt;
        sThisChat = sNumberedButtons;
    } else {  //can't fit prompt and pager, so send truncated prompt, pager and chat full prompt and button list
        sThisPrompt=TruncateString(sPrompt,489-iPagerPromptLen)+"(CONT. IN LOCAL CHAT)"+sPagerPrompt;
        sThisChat = sPrompt+sNumberedButtons;
    }
    //Debug("chat prompt:"+sThisChat);
    if(sThisChat!="")
    {
        integer iChatLen=llStringLength(sThisChat);
        integer index=1020;
        while(iChatLen) {
            if(iChatLen<1020) {
                Notify(kRecipient,sThisChat,FALSE);
                iChatLen=0;
            }
            else {
                index=1020;
                while(llGetSubString(sThisChat,index,index)!=" ") {
                    --index;
                    }
                Notify(kRecipient,llGetSubString(sThisChat,0,index-1),FALSE);
                sThisChat=llGetSubString(sThisChat,index+1,-1);
                iChatLen=llStringLength(sThisChat);
            }
        }
        sThisChat="";
    }
                
    integer iChan=llRound(llFrand(10000000)) + 100000;
    while (~llListFindList(g_lMenus, [iChan])) iChan=llRound(llFrand(10000000)) + 100000;
    integer iListener = llListen(iChan, "", kRecipient, "");

    //send dialog to viewer
    if (llGetListLength(lMenuItems+lUtilityButtons)){
        list lNavButtons;
        if (iNumitems > iMyPageSize) lNavButtons=[PREV,MORE];
        if(g_iShowLevel)sThisPrompt += "\nAuth Level: "+(string)iAuth;
        list lPretty = PrettyButtons(lButtons, lUtilityButtons, lNavButtons);

        llMessageLinked(LINK_SET, DIALOG_RENDER, sThisPrompt + "|" + llDumpList2String(lPretty, "`") + "|" + (string)iAuth, "");

        llDialog(kRecipient, sThisPrompt, lPretty, iChan);
    }
    else{
        //llMessageLinked(LINK_SET, DIALOG+2, sThisPrompt+"|"+(string)iAuth, "");
        llTextBox(kRecipient, sThisPrompt, iChan);
    }

    llSetTimerEvent(g_iReapeat);
    integer ts = llGetUnixTime() + g_iTimeOut;

    //write entry in tracking list
    g_lMenus += [iChan, kID, iListener, ts, kRecipient, sPrompt, llDumpList2String(lMenuItems, "|"), llDumpList2String(lUtilityButtons, "|"), iPage, iWithNums, iAuth,extraInfo, iSorted];
    //Debug("Made Dialog");
}

integer IsUUIDList(list lTmp)
{
    integer i=0;
    integer end = llGetListLength(lTmp);
    for(i=0;i<end;i++){
        key item = (key)llList2String(lTmp,i);
        if(item) return TRUE;
    }
    return FALSE;
}

list SortUUIDList(list lToSort){
    integer i = 0;
    list lNameList = [];
    list lSorted;
    integer end = llGetListLength(lToSort);
    for(i=0;i<end;i++){
        string sButton = llList2String(lToSort,i);
        if(IsLikelyAvatar((key)sButton)){
            if(llGetAgentSize((key)sButton)==ZERO_VECTOR)
                sButton = NameURI((key)sButton);
            else
                sButton = llGetDisplayName(sButton)+" ("+llKey2Name(sButton)+")";
        }
        else sButton=llKey2Name((key)sButton);
        lNameList += [llList2String(lToSort,i), sButton];
        lSorted+=sButton;
    }
    //llSay(0, "lNameList : "+ llDumpList2String(lNameList, " - "));
    lToSort= [];
    lSorted = llListSort(lSorted, 1, TRUE);
    i=0;
    //llSay(0, "lSorted : "+ llDumpList2String(lSorted, " - "));
    list lFinal;
    end=llGetListLength(lSorted);
    for(i=0;i<end;i++){
        integer index = llListFindList(lNameList, [llList2String(lSorted,i)]);
        lFinal += [llList2String(lNameList, index-1)];
    }
    //llSay(0, "lFinal : "+ llDumpList2String(lFinal, " - "));
    lNameList=[];
    lSorted=[];
    return lFinal;
}

integer GetStringBytes(string sStr) {
    sStr = llEscapeURL(sStr);
    integer l = llStringLength(sStr);
    list lAtoms = llParseStringKeepNulls(sStr, ["%"], []);
    return l - 2 * llGetListLength(lAtoms) + 2;
}


string TruncateString(string sStr, integer iBytes) {
     return llBase64ToString(llGetSubString(llStringToBase64(sStr), 0, 4*(integer)(iBytes/3.0)-1));
     //Base64Encoding will produce a 4-character string for every 3 bytes of input. Thus trimming a base64-encoded string to 4/3rds length and decoding will give the correct byte length. Compared to the function this replaces, it saves a minimum of 510 bytes and is MANY times faster - with a 1200 character test string saving 6468 bytes of maximum memory use and completing in 0.134 seconds instead of 27.06 seconds.
}

list PrettyButtons(list lOptions, list lUtilityButtons, list iPagebuttons) { //returns a list formatted to that "options" will start in the top left of a dialog, and "utilitybuttons" will start in the bottom right
    list lSpacers;
    list lCombined = lOptions + lUtilityButtons + iPagebuttons;
    while (llGetListLength(lCombined) % 3 != 0 && llGetListLength(lCombined) < 12) {
        lSpacers += [BLANK];
        lCombined = lOptions + lSpacers + lUtilityButtons + iPagebuttons;
    }
    // check if a UPBUTTON is present and remove it for the moment
    integer u = llListFindList(lCombined, [UPMENU]);
    if (u != -1) lCombined = llDeleteSubList(lCombined, u, u);

    list lOut = llList2List(lCombined, 9, 11);
    lOut += llList2List(lCombined, 6, 8);
    lOut += llList2List(lCombined, 3, 5);
    lOut += llList2List(lCombined, 0, 2);
    //make sure we move UPMENU to the lower right corner
    if (u != -1) lOut = llListInsertList(lOut, [UPMENU], 2);

    return lOut;
}

CleanList() {
    //Debug("cleaning list");
    //loop through menus and remove any whose timeouts are in the past
    //start at end of list and loop down so that indices don't get messed up as we remove items
    integer iLength = llGetListLength(g_lMenus);
    integer n;
    integer iNow = llGetUnixTime();
    for (n = iLength - g_iStrideLength; n >= 0; n -= g_iStrideLength) {
        integer iDieTime = llList2Integer(g_lMenus, n + 3);
        //Debug("dietime: " + (string)iDieTime);
        if (iNow > iDieTime) {
            //Debug("menu timeout");
            key kID = llList2Key(g_lMenus, n + 1);
            llMessageLinked(LINK_SET, DIALOG_TIMEOUT, "", kID);
            RemoveMenuStride(n);
        }
    }
    if (g_iSensorTimeout>iNow){ //sensor took too long to return.  Ignore it, and do the next in the list
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,3);
        if (llGetListLength(g_lSensorDetails)>0) dequeueSensor();
    }
}


ClearUser(key kRCPT) {
    //find any strides belonging to user and remove them
    integer iIndex = llListFindList(g_lMenus, [kRCPT]);
    while (~iIndex) {
        //Debug("removed stride for " + (string)kRCPT);
        RemoveMenuStride(iIndex -4);
        //g_lMenus = llDeleteSubList(g_lMenus, iIndex - 4, iIndex - 5 + g_iStrideLength);
        iIndex = llListFindList(g_lMenus, [kRCPT]);
    }
    //Debug(llDumpList2String(g_lMenus, ","));
}

RemoveMenuStride(integer iIndex)  {     //fixme:  duplicates entire global lMenu list
    //tell this function the menu you wish to remove, identified by list index
    //it will close the listener, remove the menu's entry from the list, and return the new list
    //should be called in the listen event, and on menu timeout
    integer iListener = llList2Integer(g_lMenus, iIndex + 2);
    llListenRemove(iListener);
    g_lMenus=llDeleteSubList(g_lMenus, iIndex, iIndex + g_iStrideLength - 1);
}


dequeueSensor() {
    //get sStr of first set of sensor details, unpack it and run the apropriate sensor
    //Debug((string)llGetListLength(g_lSensorDetails));
    list lParams = llParseStringKeepNulls(llList2String(g_lSensorDetails,0), ["|"], []);
    //sensor information is encoded in the first 5 fields of the lButtons list, ready to feed to the sensor command,
    list lSensorInfo = llParseStringKeepNulls(llList2String(lParams, 3), ["`"], []);
  /*  Debug("Running sensor with\n"+
        llList2String(lSensorInfo,0)+"\n"+
        llList2String(lSensorInfo,1)+"\n"+
        (string)llList2Integer(lSensorInfo,2)+"\n"+
        (string)llList2Float(lSensorInfo,3)+"\n"+
        (string)llList2Float(lSensorInfo,4)
    );*/

    llSensor(llList2String(lSensorInfo,0),(key)llList2String(lSensorInfo,1),llList2Integer(lSensorInfo,2),llList2Float(lSensorInfo,3),llList2Float(lSensorInfo,4));
    g_iSensorTimeout=llGetUnixTime()+10;
    llSetTimerEvent(g_iReapeat);
}
integer g_iShowLevel;

//UserCommand (integer iAuth, string sCmd,  key kID){
//}
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        if (llGetStartParameter()!=0){
            state inUpdate;
        }
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
    on_rez(integer iParam){
        llResetScript();
    }


    timer() {
        CleanList();
        //if list is empty after that, then stop timer
        if (!llGetListLength(g_lMenus) && !llGetListLength(g_lSensorDetails)) {
            //Debug("no active dialogs, stopping timer");
            llSetTimerEvent(0.0);
        }
    }

    listen(integer iChan, string sName, key kID, string sMessage) {
        if(g_iVerbosityLevel>=3){
            llOwnerSay("Dialog Response\n\n[iChan = "+(string)iChan+", sName = "+sName+", kID = "+(string)kID+", sMessage = "+sMessage+"]");
        }


        integer iMenuIndex = llListFindList(g_lMenus, [iChan]);
        if (~iMenuIndex) {
            key kMenuID = llList2Key(g_lMenus, iMenuIndex + 1);
            key kAv = llList2Key(g_lMenus, iMenuIndex + 4);
            string sPrompt = llList2String(g_lMenus, iMenuIndex + 5);
            // SA: null strings should not be kept for dialog buttons
            list items = llParseString2List(llList2String(g_lMenus, iMenuIndex + 6), ["|"], []);
            list ubuttons = llParseString2List(llList2String(g_lMenus, iMenuIndex + 7), ["|"], []);
            integer iPage = llList2Integer(g_lMenus, iMenuIndex + 8);
            integer iDigits = llList2Integer(g_lMenus, iMenuIndex + 9);
            integer iAuth = llList2Integer(g_lMenus, iMenuIndex + 10);
            string sExtraInfo = llList2String(g_lMenus, iMenuIndex + 11);
            integer iSorted = llList2Integer(g_lMenus, iMenuIndex+12);

            RemoveMenuStride(iMenuIndex);

            if (sMessage == MORE) Dialog(kID, sPrompt, items, ubuttons, ++iPage, kMenuID, iDigits, iAuth, sExtraInfo, iSorted);
            else if (sMessage == PREV) Dialog(kID, sPrompt, items, ubuttons, --iPage, kMenuID, iDigits, iAuth, sExtraInfo, iSorted);
            else if (sMessage == BLANK) Dialog(kID, sPrompt, items, ubuttons, iPage, kMenuID, iDigits, iAuth, sExtraInfo, iSorted);
            else {
                string sAnswer;
                integer iIndex = llListFindList(ubuttons, [sMessage]);
                if (iDigits && !~iIndex) {
                    integer iBIndex = (integer) llGetSubString(sMessage, 0, iDigits);
                    sAnswer = llList2String(items, iBIndex);
                } else if (sExtraInfo == "colormenu") {
                    integer iColorIndex  =llListFindList(llList2ListStrided(g_lColors,0,-1,2),[sMessage]);
                    if (~iColorIndex) sAnswer = llList2String(llList2ListStrided(llDeleteSubList(g_lColors,0,0),0,-1,2),iColorIndex);
                    else sAnswer = sMessage;
                } else sAnswer = sMessage;
                if (sAnswer == "") sAnswer = " "; //to have an answer to deal with send " "

                llMessageLinked(LINK_SET, DIALOG_RESPONSE, (string)kAv + "|" + sAnswer + "|" + (string)iPage + "|" + (string)iAuth, kMenuID);
            }
        }
    }
    changed(integer iChange){
        if (iChange & CHANGED_OWNER) llResetScript();
    }


    sensor(integer num_detected){
        if(num_detected>16) num_detected=16;
        //LL just expanded sensor to up to 32 hits. Thanks LL, but there's a ton of content 
        //out there not designed to cope with that which are gonna stack-heap now. For now at least we'll trim back to 16.
        //get sensot request info from list
        list lParams=llParseStringKeepNulls(llList2String(g_lSensorDetails,0), ["|"], []);
        key kID = (key)llList2String(g_lSensorDetails,1);
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,1);

        list lButtons = llParseStringKeepNulls(llList2String(lParams, 3), ["`"], []);
        if (llList2Integer(lButtons,2)==(integer)AGENT) lParams += [TRUE,"avimenu"]; // sorted
        //sensor information is encoded in the first 5 fields of the lButtons list, we've run the sensor so we don't need that now.
        //6th field is "find" information
        //7th is boolean, 0 for return a dialog, 1 for return the first matching name
        string sFind=llList2String(lButtons,5);
       //Debug(sFind);
        integer bReturnFirstMatch=llList2Integer(lButtons,6);

        lButtons=[];
        integer i;
        for (; i<num_detected;i++){
            lButtons += llDetectedKey(i);
            if (bReturnFirstMatch || (sFind != "")) { //if we're supposed to be finding the first match,
                if (llSubStringIndex(llToLower(llDetectedName(i)),llToLower(sFind))==0
                    || llSubStringIndex(llToLower(llGetDisplayName(llDetectedKey(i))),llToLower(sFind))==0 ){
                    if (!bReturnFirstMatch) {
                        lButtons = [llDetectedKey(i)];
                        jump next;
                    }
                    llMessageLinked(LINK_SET, DIALOG_RESPONSE, llList2String(lParams,0) + "|" + (string)llDetectedKey(i)+ "|0|" + llList2String(lParams,5), kID);
                    //if we have more sensors to run, run another one now, else unlock subsys and quite
                    if (llGetListLength(g_lSensorDetails) > 0)
                        dequeueSensor();
                    else g_bSensorLock=FALSE;
                    return;
                }

            }
        }
        @next;
        //pack buttons back into a ` delimited list, and put it back into lParams
        string sButtons=llDumpList2String(lButtons,"`");
        lParams=llListReplaceList(lParams,[sButtons],3,3);
        //fake fresh dialog call with our new buttons in place, using the rest of the information we were sent
        llMessageLinked(LINK_THIS,DIALOG,llDumpList2String(lParams,"|"),kID);
        //if we have more sensors to run, run another one now, else unlock subsys and quite
        if (llGetListLength(g_lSensorDetails) > 0)
            dequeueSensor();
        else g_bSensorLock=FALSE;
    }

    no_sensor() {
        list lParams=llParseStringKeepNulls(llList2String(g_lSensorDetails,0), ["|"], []);
        key kID = (key)llList2String(g_lSensorDetails,1);
        g_lSensorDetails=llDeleteSubList(g_lSensorDetails,0,1);
        lParams=llListReplaceList(lParams,[""],3,3);
        //fake fresh dialog call with our new buttons in place, using the rest of the information we were sent
        llMessageLinked(LINK_THIS,DIALOG,llDumpList2String(lParams,"|"),kID);
        //if we have more sensors to run, run another one now, else unlock subsys and quit
        if (llGetListLength(g_lSensorDetails) > 0)
            dequeueSensor();
        else g_bSensorLock=FALSE;
    }



    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == SENSORDIALOG){
            //first, store all incoming parameters in a global sensor details list
            //test for locked sensor subsystem
            //if subsys locked, do nothing
            //if subsys open, run sensor with first set of details in the list, and set timeout
           // Debug(sStr);
            g_lSensorDetails+=[sStr, kID];
            if (! g_bSensorLock){
                g_bSensorLock=TRUE;
                dequeueSensor();
            }
        } else if (iNum == DIALOG) {
        //give a dialog with the options on the button labels
            //str will be pipe-delimited list with rcpt|prompt|page|backtick-delimited-list-buttons|backtick-delimited-utility-buttons|auth|sorted
            //Debug("DIALOG:"+sStr);
            string extraInfo = "";
            list lParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kRCPT = llGetOwnerKey((key)llList2String(lParams, 0));
            string sPrompt = llList2String(lParams, 1);
            integer iPage = (integer)llList2String(lParams, 2);
            if (iPage < 0 ) {
                extraInfo = "avimenu";
                iPage = 0;
            }
            list lButtons = llParseString2List(llList2String(lParams, 3), ["`"], []);
            if (llList2String(lButtons,0) == "colormenu please") {
                lButtons = llList2ListStrided(g_lColors,0,-1,2);
                extraInfo = "colormenu";
            }
            integer iDigits=-1;   //iDigits==-1 means Dialog should run idigits on the buttons
            list ubuttons = llParseString2List(llList2String(lParams, 4), ["`"], []);
            integer iAuth = CMD_ZERO;
            integer iSorted=FALSE;
            if (llGetListLength(lParams)>=6) iAuth = llList2Integer(lParams, 5);
            if (llGetListLength(lParams)>=7) iSorted = llList2Integer(lParams, 6);
            //first clean out any strides already in place for that user. prevents having lots of listens open if someone uses the menu several times while sat
            if(iSorted && IsUUIDList(lButtons))lButtons = SortUUIDList(lButtons);
            else if(iSorted && !IsUUIDList(lButtons))lButtons = llListSort(lButtons, 1, TRUE);

            if (llGetListLength(lParams)>=8) extraInfo = llList2String(lParams, 7);
            ClearUser(kRCPT);
            Dialog(kRCPT, sPrompt, lButtons, ubuttons, iPage, kID, iDigits, iAuth,extraInfo, iSorted);
        }

        else if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) return;
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);

            //integer ind = llListFindList(g_lSettingsReqs, [sToken]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);


            if (sToken == g_sGlobalToken+"devicetype") g_sDeviceType = sValue;
            else if (sToken == g_sGlobalToken+"devicename") {
                g_sDeviceName = sValue;
                //llSetObjectName(g_sDeviceName);
//                llSetLinkPrimitiveParamsFast(LINK_ROOT,[PRIM_NAME,g_sDeviceName]);
            } else if (sToken == g_sGlobalToken+"wearername") {
                if (llSubStringIndex(sValue, "secondlife:///app/agent"))
                    g_sWearerName =  "["+NameURI(g_kWearer)+" " + sValue + "]";
                else g_sWearerName = sValue;
            } else if (sToken == g_sGlobalToken+"prefix"){
                if (sValue != "") g_sPrefix=sValue;
            } else if (sToken == g_sGlobalToken+"channel") g_iListenChan = (integer)sValue;
            else if (sToken == "auth_owner") {
                list t_lOwners = llParseString2List(sValue, [","], []);
                integer iPos =0;
                integer iEnd = llGetListLength(g_lOwners);
                for(iPos=0;iPos<iEnd;iPos++){
                    // Clear users that are removed from owners list
                    if (llListFindList(t_lOwners,llList2List(g_lOwners,iPos,iPos))==-1)
                        ClearUser((key)llList2String(g_lOwners, iPos));
                }                
                g_lOwners = t_lOwners;
            } else if(sToken == g_sGlobalToken + "showlevel") g_iShowLevel = (integer)sValue;
            else if(sToken == "auth_block"){
                list lBlock = llParseString2List(sValue,[","],[]);

                integer iPos =0;
                integer iEnd = llGetListLength(lBlock);
                for(iPos=0;iPos<iEnd;iPos++){
                    ClearUser((key)llList2String(lBlock, iPos));
                }
            } else if(sToken == g_sGlobalToken+"verbosity"){
                g_iVerbosityLevel=(integer)sValue;
            }
        } else if (iNum == LM_SETTING_EMPTY) {
            if (sStr == "auth_owner") {
                // Invalidate all owner menus 
                integer iPos =0;
                integer iEnd = llGetListLength(g_lOwners);
                for(iPos=0;iPos<iEnd;iPos++){
                    ClearUser((key)llList2String(g_lOwners, iPos));
                }
                g_lOwners = [];
            } else if (sStr == "auth_public" || sStr == "auth_group") { // public or group mode cancelled
                // Invalidate all menus except wearers and owners
                integer i = llGetListLength(g_lMenus) - g_iStrideLength;
                while ( i>= 0) {
                    key kID = llList2Key(g_lMenus,i+4);
//                    if ((kID != g_kWearer) && llListFindList(g_lOwners, [(string)kID]) == -1) llOwnerSay("clear menus for "+llGetDisplayName(kID));
                    if ((kID != g_kWearer) && llListFindList(g_lOwners, [(string)kID]) == -1) RemoveMenuStride(i);
                    i -= g_iStrideLength;
                }
            }
        } else if (iNum == NOTIFY )    Notify(kID,llGetSubString(sStr,1,-1),(integer)llGetSubString(sStr,0,0));
        else if (iNum == SAY )         Say(llGetSubString(sStr,1,-1),(integer)llGetSubString(sStr,0,0));
        else if (iNum==NOTIFY_OWNERS) NotifyOwners(sStr,(string)kID);
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();

    }

    state_entry(){

        g_kWearer=llGetOwner();
        g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()), 0,1));
        g_sWearerName = NameURI(g_kWearer);
        g_sDeviceName = llList2String(llGetLinkPrimitiveParams(1,[PRIM_DESC]),0);
        if (g_sDeviceName == "" || g_sDeviceName =="(No Description)")
            g_sDeviceName = llList2String(llGetLinkPrimitiveParams(1,[PRIM_NAME]),0);
    }
}


state inUpdate{
    link_message(integer iSender, integer iNum, string sMsg, key kID){
        if(iNum == REBOOT)llResetScript();
        else if(iNum == 0){
            if(sMsg == "do_move"){

                if(llGetLinkNumber()==LINK_ROOT || llGetLinkNumber() == 0)return;

                llOwnerSay("Moving "+llGetScriptName()+"!");
                integer i=0;
                integer end=llGetInventoryNumber(INVENTORY_ALL);
                for(i=0;i<end;i++){
                    string item = llGetInventoryName(INVENTORY_ALL,i);
                    if(llGetInventoryType(item)==INVENTORY_SCRIPT && item!=llGetScriptName()){
                        llRemoveInventory(item);
                    }else if(llGetInventoryType(item)!=INVENTORY_SCRIPT){
                        llGiveInventory(kID, item);
                        llRemoveInventory(item);
                        i=-1;
                        end=llGetInventoryNumber(INVENTORY_ALL);
                    }
                }

                llRemoveInventory(llGetScriptName());
            }
        }
    }
}

