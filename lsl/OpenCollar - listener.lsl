//OpenCollar - listener
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//listener

integer g_iListenChan = 1;
integer g_iListenChan0 = TRUE;
string g_sPrefix = ".";

integer g_iHUDChan = -1334245234; // instead this should be the new channel to be used by any object not from the wearer itself. For attachments of the wearer use the interface channel. This channel wil be personlaized below

integer g_iLockMeisterChan = -8888;

integer g_iListener1;
integer g_iListener2;
integer g_iLockMesiterListener;
integer g_iHUDListener;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;  // new for safeword
//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the httpdb

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

//5000 block is reserved for IM slaves

//EXTERNAL MESSAGE MAP
integer EXT_COMMAND_COLLAR = 499;

// new g_sSafeWord
string g_sSafeWord = "SAFEWORD";

//added for attachment auth
integer g_iInterfaceChannel = -12587429;
integer g_iListenHandleAtt;

integer ATTACHMENT_REQUEST = 600;
integer ATTACHMENT_RESPONSE = 601;
integer ATTACHMENT_FORWARD = 610;

key g_kWearer;
string g_sSeparator = "|";
string g_iAuth;
string UUID;
string g_sCmd;


//===============================================================================
//= parameters   :    key owner            key of the person to send the message to
//=                    integer nOffset        Offset to make sure we use really a unique channel
//=
//= description  : Function which calculates a unique channel number based on the owner key, to reduce lag
//=
//= returns      : Channel number to be used
//===============================================================================
integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan>0)
    {
        iChan=iChan*(-1);
    }
    if (iChan > -10000)
    {
        iChan -= 30000;
    }
    return iChan;
}

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + " Debug: " + sStr);
}

SetListeners()
{
    llListenRemove(g_iListener1);
    llListenRemove(g_iListener2);
    llListenRemove(g_iLockMesiterListener);
    llListenRemove(g_iListenHandleAtt);

    llListenRemove(g_iHUDListener);

    if(g_iListenChan0 == TRUE)
    {
        g_iListener1 = llListen(0, "", NULL_KEY, "");
    }
    g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
    if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
    g_iListenHandleAtt = llListen(g_iInterfaceChannel, "", "", "");
    g_iListener2 = llListen(g_iListenChan, "", NULL_KEY, "");
    g_iLockMesiterListener = llListen(g_iLockMeisterChan, "", NULL_KEY, (string)g_kWearer + "collar");

    g_iHUDListener = llListen(g_iHUDChan, "", NULL_KEY ,"");

}

string AutoPrefix()
{
    list sName = llParseString2List(llKey2Name(g_kWearer), [" "], []);
    return llToLower(llGetSubString(llList2String(sName, 0), 0, 0)) + llToLower(llGetSubString(llList2String(sName, 1), 0, 0));
}

string StringReplace(string sSrc, string sFrom, string sTo)
{//replaces all occurrences of 'sFrom' with 'sTo' in 'sSrc'.
    //Ilse: blame/applaud Strife Onizuka for this godawfully ugly though apparently optimized function
    integer iLen = (~-(llStringLength(sFrom)));
    if(~iLen)
    {
        string  sBuffer = sSrc;
        integer iBufPos = -1;
        integer iToLen = (~-(llStringLength(sTo)));
        @loop;//instead of a while loop, saves 5 bytes (and run faster).
        integer iToPos = ~llSubStringIndex(sBuffer, sFrom);
        if(iToPos)
        {
            iBufPos -= iToPos;
            sSrc = llInsertString(llDeleteSubString(sSrc, iBufPos, iBufPos + iLen), iBufPos, sTo);
            iBufPos += iToLen;
            sBuffer = llGetSubString(sSrc, (-~(iBufPos)), 0x8000);
            //sBuffer = llGetSubString(sSrc = llInsertString(llDeleteSubString(sSrc, iBufPos -= iToPos, iBufPos + iLen), iBufPos, sTo), (-~(iBufPos += iToLen)), 0x8000);
            jump loop;
        }
    }
    return sSrc;
}

integer StartsWith(string sHayStack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return llDeleteSubString(sHayStack, llStringLength(sNeedle), -1) == sNeedle;
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

string CollarVersion()
{
    // checks if the version of the collar
    // return the version of the collar or 0.000 if the version could not be detected

    list lParams = llParseString2List(llGetObjectDesc(), ["~"], []);
    string sName = llList2String(lParams, 0);
    string sVersion = llList2String(lParams, 1);

    if (sName == "" || sVersion == "")
    {
        return "0.000";
    }
    else if ((float)sVersion)
    {
        return llGetSubString((string)sVersion,0,4);
    }
    return "0.000";
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        g_sPrefix = AutoPrefix();

        g_iHUDChan = GetOwnerChannel(g_kWearer, 1111); // persoalized channel for this sub

        //llInstantMessage(, "Prefix set to '" + g_sPrefix + "'.", g_kWearer);
        SetListeners();
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "prefix", NULL_KEY);
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "channel", NULL_KEY);
    }

    attach(key kID)
    {
        if (kID == NULL_KEY)
        {
            llWhisper(g_iInterfaceChannel, "OpenCollar=No");
        }
        else
        {
            llWhisper(g_iInterfaceChannel, "OpenCollar=Yes");
        }
    }

    listen(integer sChan, string sName, key kID, string sMsg)
    {
        // new object/HUD channel block
        if (sChan == g_iHUDChan)
        {
            //check for a ping, if we find one we request auth and answer in LMs with a pong
            if (sMsg==(string)g_kWearer + ":ping")
            {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "ping", llGetOwnerKey(kID));
            }
            // an object wants to know the version, we check if it is allowed to
            if (sMsg==(string)g_kWearer + ":version")
            {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "objectversion", llGetOwnerKey(kID));
            }
            // it it is not a ping, it should be a command for use, to make sure it has to have the key in front of it
            else if (StartsWith(sMsg, (string)g_kWearer + ":"))
            {
                sMsg = llGetSubString(sMsg, 37, -1);
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, kID);
            }
            else
            {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, llGetOwnerKey(kID));
            }
        }

        else if (sChan == g_iLockMeisterChan)
        {
            llWhisper(g_iLockMeisterChan,(string)g_kWearer + "collar ok");
        }
        else if((kID == g_kWearer) && ((sMsg == g_sSafeWord)||(sMsg == "(("+g_sSafeWord+"))")))
        { // safeword can be the safeword or safeword said in OOC chat "((SAFEWORD))"
            llMessageLinked(LINK_SET, COMMAND_SAFEWORD, "", NULL_KEY);
            llOwnerSay("You used your safeword, your owner will be notified you did.");
        }
        //added for attachment auth (garvin)
        else if (sChan == g_iInterfaceChannel)
        {
            Debug(sMsg);
            //do nothing if wearer isnt owner of the object
            if (llGetOwnerKey(kID) != g_kWearer) return;
            if (sMsg == "OpenCollar?")
            {
                llWhisper(g_iInterfaceChannel, "OpenCollar=Yes");
                return;
            }
            else if (sMsg == "version")
            {
                llWhisper(g_iInterfaceChannel, "version="+CollarVersion());
                return;
            }
            //(string)g_iNum + SEPARATOR + sMsg + SEPARATOR + (string)UserID + (string)objectID
            integer iIndex = llSubStringIndex(sMsg, g_sSeparator);
            g_iAuth = llGetSubString(sMsg, 0, iIndex - 1);
            if (g_iAuth == "0") //auth request
            {
                g_sCmd = llGetSubString(sMsg, iIndex + 1, -1);
                iIndex = llSubStringIndex(g_sCmd, g_sSeparator);
                UUID = llGetSubString(g_sCmd, iIndex + 1, llStringLength(sMsg) - 40);
                Debug(UUID);
                //just send ATTACHMENT_REQUEST and ID to auth, as no script IN the collar needs the command anyway
                llMessageLinked(LINK_SET, ATTACHMENT_REQUEST, "", (key)UUID);
            }
            else if (g_iAuth == (string)EXT_COMMAND_COLLAR) //command from attachment to AO
            {
                llWhisper(g_iInterfaceChannel, sMsg);
            }

            else
            {
                // we received a unkown command, so we just forward it via LM into the cuffs
                llMessageLinked(LINK_SET, ATTACHMENT_FORWARD, sMsg, kID);
            }

        }
        else
        { //check for our prefix, or *
            if (StartsWith(sMsg, g_sPrefix))
            {
                //trim
                sMsg = llGetSubString(sMsg, llStringLength(g_sPrefix), -1);
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, kID);
            }
            else if (llGetSubString(sMsg, 0, 0) == "*")
            {
                sMsg = llGetSubString(sMsg, 1, -1);
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, kID);
            }
            // added # as prefix for all subs aroubd BUT yourself
            else if ((llGetSubString(sMsg, 0, 0) == "#") && (kID != g_kWearer))
            {
                sMsg = llGetSubString(sMsg, 1, -1);
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, kID);
            }
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {

        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            list lParams = llParseString2List(sStr, [" "], []);
            string sCommand = llToLower(llList2String(lParams, 0));
            string sValue = llToLower(llList2String(lParams, 1));
            if (sStr == "settings")
                // answer for settings command
            {
                Notify(kID,"prefix: " + g_sPrefix, FALSE);
                Notify(kID,"channel: " + (string)g_iListenChan, FALSE);
            }
            else if (sStr == "ping")
                // ping from an object, we answer to it on the object channel
            {
                llSay(GetOwnerChannel(kID,1111),(string)g_kWearer+":pong");
            }
            //handle changing prefix and channel from owner
            else if (iNum == COMMAND_OWNER)
            {
                if (sCommand == "prefix")
                {
                    string sNewPrefix = llList2String(lParams, 1);
                    if (sNewPrefix == "auto")
                    {
                        g_sPrefix = AutoPrefix();
                    }
                    else if (sNewPrefix != "")
                    {
                        g_sPrefix = sNewPrefix;
                    }
                    SetListeners();
                    Notify(kID, "\n" + llKey2Name(g_kWearer) + "'s prefix is '" + g_sPrefix + "'.\nTouch the collar or say '" + g_sPrefix + "menu' for the main menu.\nSay '" + g_sPrefix + "help' for a list of chat commands.", FALSE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "prefix=" + g_sPrefix, NULL_KEY);
                }
                else if (sCommand == "channel")
                {
                    integer iNewChan = (integer)llList2String(lParams, 1);
                    if (iNewChan > 0)
                    {
                        g_iListenChan =  iNewChan;
                        SetListeners();
                        Notify(kID, "Now listening on channel " + (string)g_iListenChan + ".", FALSE);
                        if (g_iListenChan0)
                        {
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "channel=" + (string)g_iListenChan + ",TRUE", NULL_KEY);
                        }
                        else
                        {
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "channel=" + (string)g_iListenChan + ",FALSE", NULL_KEY);
                        }
                    }
                    else if (iNewChan == 0)
                    {
                        g_iListenChan0 = TRUE;
                        SetListeners();
                        Notify(kID, "You enabled the public channel listener.\nTo disable it use -1 as channel command.", FALSE);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "channel=" + (string)g_iListenChan + ",TRUE", NULL_KEY);
                    }
                    else if (iNewChan == -1)
                    {
                        g_iListenChan0 = FALSE;
                        SetListeners();
                        Notify(kID, "You disabled the public channel listener.\nTo enable it use 0 as channel command, remember you have to do this on your channel /" +(string)g_iListenChan, FALSE);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "channel=" + (string)g_iListenChan + ",FALSE", NULL_KEY);
                    }
                    else
                    {  //they left the param blank
                        Notify(kID, "Error: 'channel' must be given a number.", FALSE);
                    }
                }
                //                else if(kID == g_kWearer)
                //                {
                //                    if (sCommand == "safeword")
                //                    {   // new for safeWord
                //                        string sValue = llList2String(lParams, 1);
                //                        if(llStringTrim(sValue, STRING_TRIM) != "")
                //                        {
                //                            g_sSafeWord = sValue;
                //                            llOwnerSay("You set a new safeword: " + sValue + ".");
                //                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "safeword=" + sValue, NULL_KEY);
                //                        }
                //                        else
                //                        {
                //                            llOwnerSay("Your safeword is: " + g_sSafeWord + ".");
                //                        }
                //                    }
                //                    else if (sStr == g_sSafeWord)
                //                    { //safeWord used with prefix
                //                        llMessageLinked(LINK_SET, COMMAND_SAFEWORD, "", NULL_KEY);
                //                        llOwnerSay("You used your safeword, your owner will be notified you dkID.");
                //                    }
                //                }
            }
            if (kID == g_kWearer)
            {
                if (sCommand == "safeword")
                {   // new for safeword
                    if(llStringTrim(sValue, STRING_TRIM) != "")
                    {
                        g_sSafeWord = llList2String(lParams, 1);
                        llOwnerSay("You set a new safeword: " + g_sSafeWord + ".");
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "safeword=" + g_sSafeWord, NULL_KEY);
                    }
                    else
                    {
                        llOwnerSay("Your safeword is: " + g_sSafeWord + ".");
                    }
                }
                else if (sStr == g_sSafeWord)
                { //safeword used with prefix
                    llMessageLinked(LINK_SET, COMMAND_SAFEWORD, "", NULL_KEY);
                    llOwnerSay("You used your safeword, your owner will be notified you did.");
                }
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "prefix")
            {
                //prefix is the only token for which the httpdb will send a blank value, just so that
                //this script can know it's time to send the helpful popup.
                g_sPrefix = sValue;
                //llInstantMessage(g_kWearer, "Loaded prefix " + g_sPrefix + " from database.");
                SetListeners();
                //Notify(g_kWearer "\nPrefix set to '" + g_sPrefix + "'.\nTouch the collar or say '" + g_sPrefix + "menu' for the main menu.\nSay '" + g_sPrefix + "help' for a list of chat commands.");
            }
            else if (sToken == "channel")
            {
                g_iListenChan = (integer)sValue;
                if (llGetSubString(sValue, llStringLength(sValue) - 5 , -1) == "FALSE")
                {
                    g_iListenChan0 = FALSE;
                }
                else
                {
                    g_iListenChan0 = TRUE;
                }
                //llInstantMessage(g_kWearer, "Commands may be given on channel " + sValue + ".");
                SetListeners();
            }
            else if (sToken == "safeword")
            {
                g_sSafeWord = sValue;
                //                llOwnerSay("Your g_sSafeWord " + g_sSafeWord + " was loaded from the httpdb.");
            }
        }
        //        else if (iNum == LM_SETTING_EMPTY && sStr == "prefix")
        //        {
        //            SetListeners();
        //            Notify(g_kWearer, "\nPrefix set to '" + g_sPrefix + "'.\nTouch the collar or say '" + g_sPrefix + "menu' for the main menu.\nSay '" + g_sPrefix + "help' for a list of chat commands.");
        //        }
        else if (iNum == POPUP_HELP)
        {
            //replace _PREFIX_ with prefix, and _CHANNEL_ with (strin) channel
            sStr = StringReplace(sStr, "_PREFIX_", g_sPrefix);
            sStr = StringReplace(sStr, "_CHANNEL_", (string)g_iListenChan);
            Notify(kID, sStr, FALSE);
        }
        //added for attachment auth (garvin)
        else if (iNum == ATTACHMENT_RESPONSE)
        {
            Debug(sStr);
            //here the response from auth has to be:
            // llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, "auth", UUID);
            //where "auth" has to be (string)COMMAND_XY
            //reason for this is: i dont want to have all other scripts recieve a COMMAND+xy and check further for the command
            llWhisper(g_iInterfaceChannel, "RequestReply|" + sStr + g_sSeparator + g_sCmd);
        }
    }
    //no more self resets
    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    on_rez(integer iParam)
    {
        llResetScript();
    }
}