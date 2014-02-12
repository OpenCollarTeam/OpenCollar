////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - badwords                              //
//                                 version 3.952                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// SatomiAhn Initial support for llTextBox. 

//if list isn't blank, open listener on channel 0, with sub's key <== only for the first badword???
string DEFAULT = "Default";
string g_sDefaultAnim = "~shock";
string g_sBadWordAnim ;
list g_lBadWords;
string g_sPenance = "I didn't do it!";
integer g_iListener;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_SAFEWORD = 510;  // new for safeword

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;

integer ANIM_START = 7000;
integer ANIM_STOP = 7001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//5000 block is reserved for IM slaves
string CTYPE = "collar";

key g_kWearer;

key g_kDialog;
key g_kMainDialog;
key g_kAddBadwordTBox;
key g_kRemBadwordDialog;
key g_kSetAnimDialog;
key g_kSetPenanceTBox;

string g_sSubMenu = "Badwords";
string g_sParentMenu = "AddOns";

string UPMENU = "BACK";
string g_sIsEnabled = "badwordson=false";

//added to stop abdword anim only if it was started by using a badword
integer g_iHasSworn = FALSE;
string g_sScript;

Debug(string sMsg)
{
    //Notify(g_kWearer,llGetScriptName() + ": " + sMsg,TRUE);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

integer Enabled()
{
    integer iIndex = llSubStringIndex(g_sIsEnabled, "=");
    string sValue = llGetSubString(g_sIsEnabled, iIndex + 1, llStringLength(g_sIsEnabled) - 1);
    if(sValue == "true")
    {
        return TRUE;
    }
    else
    {
        return FALSE;
    }
}

DialogBadwords(key kID, integer iAuth)
{
    string sText;
    list lButtons = ["Set Penance", "Add Word", "Remove Word", "Set Animation"];
    if(Enabled())
    {
        lButtons += ["OFF"];
        sText += "Badwords are turned ON.\n";
    }
    else
    {
        lButtons += ["ON"];
        sText += "Badwords are turned OFF.\n";
    }
    sText += "'Add Word' add another badword.\n";
    sText += "'Remove Word' shows the list of badwords and allows removing them.\n";
    sText += "'Set Animation' select the animation to use as a punishment.\n";
    sText += "'Set Penance' write the penance the sub has to say to get released from the animation.\n";
    g_kDialog = g_kMainDialog = Dialog(kID, sText, lButtons, [UPMENU],0, iAuth);
}

DialogRemBadword(key kID, integer iAuth) // short subroutine, but presented as a function as it needs to be called back again after an answer
{
    string sText = "Select a badword to remove or clear them all.";
    g_kDialog = g_kRemBadwordDialog=Dialog(kID, sText, g_lBadWords, ["Clear All", UPMENU],0, iAuth);
}

DialogSelectAnim(key kID, integer iAuth)
{
    list lPoseList = [DEFAULT];
    integer iMax = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    string sName;
    for (i=0;i<iMax;i++)
    {
        sName=llGetInventoryName(INVENTORY_ANIMATION, i);
        //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
        if (sName != "" && llGetSubString(sName, 0, 0) != "~")
        {
            lPoseList+=[sName];
        }
    }    
    string sText = "Current punishment animation is: "+g_sBadWordAnim+"\n\n";
    sText += "Select a new animation to use as a punishment.\n\n";
    g_kDialog = g_kSetAnimDialog = Dialog(kID, sText, lPoseList, [UPMENU],0, iAuth);
}

DialogHelp(key kID, integer iAuth)
{
    string sMessage = "Usage of Badwords.\n";
    sMessage += "Put in front of each command your subs prefix then use them as followed:\n";
    sMessage += "badword <badword> where <badword> is the word you want to add.\n";
    sMessage += "rembadword <badword> where <badword> is the word you want to remove.\n";
    sMessage += "penance <what your sub has to say to get release from the badword anim.\n";
    sMessage += "badwordsanim <anim name> , make sure the animation is inside the " + CTYPE + ".";
    g_kDialog=Dialog(kID, sMessage, ["Ok"], [], 0, iAuth);
}

ListenControl()
{
    if(Enabled())
    {
        if (llGetListLength(g_lBadWords))
        {
            g_iListener = llListen(0, "", g_kWearer, "");
        }
    }
    else
    {
        llListenRemove(g_iListener);
    }
}

string DePunctuate(string sStr)
{
    string sLastChar = llGetSubString(sStr, -1, -1);
    if (sLastChar == "," || sLastChar == "." || sLastChar == "!" || sLastChar == "?")
    {
        sStr = llGetSubString(sStr, 0, -2);
    }
    return sStr;
}

integer HasSwear(string sStr)
{
    sStr = llToLower(sStr);
    list lWords = llParseString2List(sStr, [" "], []);
    integer n;
    for (n = 0; n < llGetListLength(lWords); n++)
    {
        string sWord = llList2String(lWords, n);
        sWord = DePunctuate(sWord);

        if (llListFindList(g_lBadWords, [sWord]) != -1)
        {
            return TRUE;
        }
    }
    return FALSE;
}

integer Contains(string sHayStack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return 0 <= llSubStringIndex(sHayStack, sNeedle);
}

string WordPrompt()
{
    string sName = llKey2Name(g_kWearer);
    string sPrompt = sName + " is forbidden from saying ";
    integer iLength = llGetListLength(g_lBadWords);
    if (!iLength)
    {
        sPrompt = sName + " is not forbidden from saying anything.";
    }
    else if (iLength == 1)
    {
        sPrompt += llList2String(g_lBadWords, 0);
    }
    else if (iLength == 2)
    {
        sPrompt += llList2String(g_lBadWords, 0) + " or " + llList2String(g_lBadWords, 1);
    }
    else
    {
        sPrompt += llDumpList2String(llDeleteSubList(g_lBadWords, -1, -1), ", ") + ", or " + llList2String(g_lBadWords, -1);
    }


    sPrompt += "\nThe penance phrase to clear the punishment anim is '" + g_sPenance + "'.";
    return sPrompt;
}

string right(string sSrc, string sDivider) {
    integer iIndex = llSubStringIndex( sSrc, sDivider );
    if(~iIndex)
        return llDeleteSubString( sSrc, 0, iIndex + llStringLength(sDivider) - 1);
    return sSrc;
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
}

// returns TRUE if eligible (AUTHED link message number)
integer UserCommand(integer iNum, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum > COMMAND_WEARER || iNum < COMMAND_OWNER) return FALSE; // sanity check
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    if (sStr == "menu "+g_sSubMenu)
    {
        DialogBadwords(kID, iNum);
    }
    else if (sStr == "settings")
    {
        Notify(kID, "Bad Words: " + llDumpList2String(g_lBadWords, ", "),FALSE);
        Notify(kID, "Bad Word Anim: " + g_sBadWordAnim,FALSE);
        Notify(kID, "Penance: " + g_sPenance,FALSE);
    }
    else if(iNum > COMMAND_OWNER)
    {
        if(sCommand == "badwords")
        {
            Notify(kID, "Sorry, only the owner can toggle badwords.",FALSE);
        }
    }
    else // COMMAND_OWNER only
    {
        string sValue = llList2String(lParams, 1);
        if(sStr == "badwords") DialogBadwords(kID, iNum);
        else if (sCommand == "badword")
        {
            //support owner adding words
            integer iOldLength = llGetListLength(g_lBadWords);
            list lNewBadWords = llDeleteSubList(llParseString2List(sStr, [" "], []), 0, 0);
            integer n;
            integer iLength = llGetListLength(lNewBadWords);
            for (n = 0; n < iLength; n++)
            {  //add new swear if not already in list
                string sNew = llList2String(lNewBadWords, n);
                sNew = DePunctuate(sNew);
                sNew = llToLower(sNew);
                if (llListFindList(g_lBadWords, [sNew]) == -1)
                {
                    g_lBadWords += [sNew];
                }
            }
            integer iNewLength = llGetListLength(g_lBadWords);
            if(!iOldLength && iNewLength)
            {
                g_sIsEnabled = "badwordson=true";
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sIsEnabled, NULL_KEY);
            }
            //save to database
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "badwords=" + llDumpList2String(g_lBadWords, ","), NULL_KEY);
            ListenControl();
            Notify(kID, WordPrompt(),TRUE);
        }
        else if (sCommand == "badwordsanim")
        {
            //Get all text after the command, strip spaces from start and end
            string sAnim = right(sStr, sCommand);
            sAnim = llStringTrim(sAnim, STRING_TRIM);
            if(sAnim == DEFAULT) sAnim = g_sDefaultAnim;
            if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
            {
                g_sBadWordAnim = sAnim;
                //Debug(g_sBadWordAnim);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "badwordsanim=" + g_sBadWordAnim, NULL_KEY);
                Notify(kID, "Punishment anim for bad words is now '" + g_sBadWordAnim + "'.",FALSE);
            }
            else
            {
                Notify(kID, llList2String(lParams, 1) + " is not a valid animation name.",FALSE);
            }
        }
        else if (sCommand == "penance")
        {
            string sPenance = llDumpList2String(llDeleteSubList(lParams, 0, 0), " ");
            if (sPenance == "")
            {
                Notify(kID, "The penance phrase to release the sub from the punishment anim is:\n" + g_sPenance,FALSE);
            }
            else
            {
                g_sPenance = llStringTrim(sPenance, STRING_TRIM);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "penance=" + g_sPenance, NULL_KEY);
                string sPrompt = WordPrompt();
                Notify(kID, sPrompt,TRUE);
            }

        }
        else if (sCommand == "rembadword")
        {    //support owner adding words
            list remg_lBadWords = llDeleteSubList(llParseString2List(sStr, [" "], []), 0, 0);
            integer n;
            integer iLength = llGetListLength(remg_lBadWords);
            for (n = 0; n < iLength; n++)
            {  //add new swear if not already in list
                string rem = llList2String(remg_lBadWords, n);
                integer iIndex = llListFindList(g_lBadWords, [rem]);
                if (iIndex != -1)
                {
                    g_lBadWords = llDeleteSubList(g_lBadWords, iIndex, iIndex);
                }
            }
            //save to sDatabase
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "badwords=" + llDumpList2String(g_lBadWords, ","), NULL_KEY);
            ListenControl();
            Notify(kID, WordPrompt(),TRUE);
        }
        else if (sCommand == "badwords")
        {
            if(sValue == "on")
            {
                if(llGetListLength(g_lBadWords))
                {
                    g_sIsEnabled = "badwordson=true";
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sIsEnabled, NULL_KEY);
                    ListenControl();
                    Notify(kID, "Badwords are now turned on for: " + llDumpList2String(g_lBadWords, ","),FALSE);
                }
                else
                    Notify(kID, "There are no badwords set. Define at least one badword before turning it on.",FALSE);

            }
            else if(sValue == "off")
            {
                g_sIsEnabled = "badwordson=false";
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sIsEnabled, NULL_KEY);
                ListenControl();
                Notify(kID, "Badwords are now turned off.",FALSE);
            }
            else if(sValue == "clearall")
            {
                g_lBadWords = [];
                g_sIsEnabled = "badwordson=false";
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sIsEnabled, NULL_KEY);
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "badwords=", NULL_KEY);
                ListenControl();
                //DialogBadwords(kID, iNum); This was duplicated since the dialog is called at the end of the link_message event.
                Notify(kID, "You cleared the badword list and turned it off.",FALSE);
            }
        }
    }
    return TRUE;
}

default
{     // no more needed
    //  state_entry()
    //  {
    //      llSleep(0.8);
    //      llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
    //  }
    on_rez(integer iParam)
    {
        llResetScript();
    }

    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer=llGetOwner();
        g_sBadWordAnim = g_sDefaultAnim ;
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);    
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "badwordson")
                {
                    g_sIsEnabled = "badwordson" + "=" + sValue;
                    ListenControl();
                }
                else if (sToken == "badwordsanim")
                {
                    g_sBadWordAnim = sValue;
                }
                else if (sToken == "badwords")
                {
                    //use lines in defaultsettings NC like this:
                    //User_badwords=badwordson~true~badwords~test-badword1,test-badword2,test-badword3~penance~tis 's the testpenance!
                    //did not test badwords with special char  - but:
                    //badwords holding ',' may give problems with dump settings and esp. with/in defaultsettings NC
                    g_lBadWords = llParseString2List(llToLower(sValue), [","], []);
                    ListenControl();
                }
                else if (sToken == "penance")
                {
                    g_sPenance = sValue;
                }
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if(iNum == COMMAND_SAFEWORD)
        { // safeword disables badwords !
            g_sIsEnabled = "badwords=false";
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + g_sIsEnabled, NULL_KEY);
            ListenControl();
        }
        else if (iNum == MENUNAME_REQUEST)
        {
            if (sStr == g_sParentMenu)
            {
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
            }
        }

        else if (iNum == DIALOG_RESPONSE)
        {
            if(kID != g_kDialog) return ;            
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMessage = llList2String(lMenuParams, 1);
            integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);
            if (kID == g_kMainDialog)
            {
                if(sMessage == "Ok") {} // Do nothing, just pop up the main menu again.
                else if (sMessage == UPMENU)
                { //give kID the parent menu
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                }
                else if(sMessage == "ON")
                {
                    UserCommand(iAuth, "badwords on", kAv);
                    DialogBadwords(kAv, iAuth);
                }
                else if(sMessage == "OFF")
                {
                    UserCommand(iAuth, "badwords off", kAv);
                    DialogBadwords(kAv, iAuth);
                }
                else if (sMessage == "Add Word")
                {
                    string sText = "\n- Submit the new badword in the field below.\n- Submit a blank field to go back to "
 + g_sParentMenu + ".";
                    g_kDialog = g_kAddBadwordTBox = Dialog(kAv, sText, [], [], 0, iAuth);
                }
                else if (sMessage == "Remove Word")
                {
                    if (g_lBadWords) DialogRemBadword(kAv, iAuth);
                    else
                    {
                        Notify(kAv, "The list of badwords is currently empty.", FALSE);
                        DialogBadwords(kAv, iAuth);
                    }
                }
                else if (sMessage == "Set Penance")
                {
                    
                    string sText = "\n- Submit the new penance in the field below.\n- Submit a blank field to go back to "
 + g_sParentMenu + ".";
                           sText += "\n\n- Current penance is: " + g_sPenance;
                    g_kDialog = g_kSetPenanceTBox=Dialog(kAv, sText, [], [],0, iAuth);
                }
                else if (sMessage == "Set Animation") DialogSelectAnim(kAv, iAuth);
            }
            else if (kID == g_kAddBadwordTBox)
            {
                if (sMessage) UserCommand(iAuth, "badword " + sMessage, kAv);
                DialogBadwords(kAv, iAuth);
            }
            else if (kID == g_kRemBadwordDialog)
            {
                if (sMessage == UPMENU) DialogBadwords(kAv, iAuth);
                else if (sMessage == "Clear All")
                {
                    UserCommand(iAuth, "badwords clearall", kAv);
                    DialogBadwords(kAv, iAuth);
                }
                else
                {
                    UserCommand(iAuth, "rembadword " + sMessage, kAv);
                    if (g_lBadWords) DialogRemBadword(kAv, iAuth);
                    else DialogBadwords(kAv, iAuth);
                }
            }
            else if (kID == g_kSetAnimDialog)
            {
                if (sMessage == UPMENU) {} // nothing to do
                else
                {
                    UserCommand(iAuth, "badwordsanim " + sMessage, kAv);
                }
                // in all cases
                DialogBadwords(kAv, iAuth);
            }
            else if (kID == g_kSetPenanceTBox)
            {
                if (sMessage) UserCommand(iAuth, "penance " + sMessage, kAv);
                DialogBadwords(kAv, iAuth);
            }
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage)
    {
        //release anim if penance & play anim if swear
        if (iChannel == 0)
        {
            if ((~(integer)llSubStringIndex(llToLower(sMessage), llToLower(g_sPenance))) && g_iHasSworn )
            { //stop anim
                llMessageLinked(LINK_SET, ANIM_STOP, g_sBadWordAnim, NULL_KEY);
                Notify(g_kWearer, "Penance accepted.",FALSE);
                g_iHasSworn = FALSE;
            }
            else if (Contains(sMessage, "rembadword"))
            {//subs could theoretically circumvent this feature by sticking "rembadowrd" in all chat, but it doesn't seem likely to happen often
                return;
            }
            else if (HasSwear(sMessage))
            {   //start anim
                llMessageLinked(LINK_SET, ANIM_START, g_sBadWordAnim, NULL_KEY);
                llWhisper(0, llList2String(llParseString2List(llKey2Name(g_kWearer), [" "], []), 0) + " has said a bad word and is being punished.");
                g_iHasSworn = TRUE;
            }
        }
    }
}
