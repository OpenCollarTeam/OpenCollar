////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - listener                              //
//                                 version 3.955                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//3.941 - littlemousy - combined listen script with touch script, so all input to collar goes through a single script.  Should save us some memory.
integer g_iListenChan = 1;
integer g_iListenChan0 = TRUE;
string g_sPrefix = ".";

integer g_iLockMeisterChan = -8888;

integer g_iListener1;
integer g_iListener2;
integer g_iLockMeisterListener;

integer g_iHUDListener;
integer g_iHUDChan;

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

integer INTERFACE_REQUEST = -9006;
integer INTERFACE_RESPONSE = -9007;

integer TOUCH_REQUEST = -9500;
integer TOUCH_CANCEL = -9501;
integer TOUCH_RESPONSE = -9502;
integer TOUCH_EXPIRE = -9503;


//5000 block is reserved for IM slaves

//EXTERNAL MESSAGE MAP
integer EXT_COMMAND_COLLAR = 499;

// new g_sSafeWord
string g_sSafeWord = "RED";

//added for attachment auth
integer g_iInterfaceChannel = -12587429; // AO Backwards Compatibility
integer g_iListenHandleAtt;

integer ATTACHMENT_REQUEST = 600;
integer ATTACHMENT_RESPONSE = 601;
integer ATTACHMENT_FORWARD = 610;

key g_kWearer;
string g_sSeparator = "|";
string g_iAuth;
string UUID;
string g_sCmd;
string g_sScript;
string CTYPE = "collar";

//globlals for supporting touch requests
list g_lTouchRequests; // 4-strided list in form of touchid, recipient, flags, auth level
integer g_iStrideLength = 4;

integer FLAG_TOUCHSTART = 0x01;
integer FLAG_TOUCHEND = 0x02;

integer g_iNeedsPose = FALSE;  // should the avatar be forced into a still pose for making touching easier
string g_sPOSE_ANIM = "turn_180";

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + " Debug: " + sStr);
}

SetListeners()
{
    llListenRemove(g_iListener1);
    llListenRemove(g_iListener2);
    llListenRemove(g_iLockMeisterListener);
    llListenRemove(g_iListenHandleAtt);

    if(g_iListenChan0 == TRUE)
    {
        g_iListener1 = llListen(0, "", NULL_KEY, "");
    }
    g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
    if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
    g_iListenHandleAtt = llListen(g_iInterfaceChannel, "", "", "");
    g_iListener2 = llListen(g_iListenChan, "", NULL_KEY, "");
    g_iLockMeisterListener = llListen(g_iLockMeisterChan, "", NULL_KEY, (string)g_kWearer + "collar");
    g_iHUDListener = llListen(g_iHUDChan, "", NULL_KEY ,""); //reinstated
}

SetPrefix(string sValue)
{
    if (sValue != "auto") g_sPrefix = sValue;
    else
    {
        list name = llParseString2List(llKey2Name(g_kWearer), [" "], []);
        string init = llGetSubString(llList2String(name, 0), 0, 0);
        init += llGetSubString(llList2String(name, 1), 0, 0);
        g_sPrefix = llToLower(init);
    }
    Debug("Prefix set to: " + g_sPrefix);
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



integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = -llAbs((integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset);
    if (iChan > -10000) iChan -= 30000;
    return iChan;
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

//functions from touch script
ClearUser(key kRCPT, integer iNotify)  
{
    //find any strides belonging to user and remove them
    integer iIndex = llListFindList(g_lTouchRequests, [kRCPT]);
    while (~iIndex)
    {
        if (iNotify)
        {
            key kID = llList2Key(g_lTouchRequests, iIndex -1);
            integer iAuth = llList2Integer(g_lTouchRequests, iIndex + 2);
            llMessageLinked(LINK_THIS, TOUCH_EXPIRE, (string) kRCPT + "|" + (string) iAuth,kID);
        }
        g_lTouchRequests = llDeleteSubList(g_lTouchRequests, iIndex - 1, iIndex - 2 + g_iStrideLength);
        iIndex = llListFindList(g_lTouchRequests, [kRCPT]);
    }
    if (g_iNeedsPose && [] == g_lTouchRequests) llStopAnimation(g_sPOSE_ANIM);
}

integer sendPermanentCommandFromLink(integer iLinkNumber, string sType, key kToucher)
{
    string sCommand;
    string sDesc = (string)llGetObjectDetails(llGetLinkKey(iLinkNumber), [OBJECT_DESC]);
    list lDescTokens = llParseStringKeepNulls(sDesc, ["~"], []);
    integer iNDescTokens = llGetListLength(lDescTokens);
    integer iDescToken;
    for (iDescToken = 0; iDescToken < iNDescTokens; iDescToken++)
    {
        string sDescToken = llList2String(lDescTokens, iDescToken);
        if (sDescToken == sType || sDescToken == sType+":" || sDescToken == sType+":none") return TRUE;
        else if (!llSubStringIndex(sDescToken, sType+":"))
        {                
            sCommand = llGetSubString(sDescToken, llStringLength(sType)+1, -1);
            if (sCommand != "") llMessageLinked(LINK_SET, COMMAND_NOAUTH, sCommand, kToucher);
            return TRUE;
        }
    }
    return FALSE;
}

sendCommandFromLink(integer iLinkNumber, string sType, key kToucher)
{
    // check for temporary touch requests
    list lTriggers;
    integer iTrig;
    integer iNTrigs = llGetListLength(g_lTouchRequests);
    for (iTrig = 0; iTrig < iNTrigs; iTrig+=g_iStrideLength)
    {
        if (llList2Key(g_lTouchRequests, iTrig + 1) == kToucher)
        {
            integer iTrigFlags = llList2Integer(g_lTouchRequests, iTrig + 2);
            if (((iTrigFlags & FLAG_TOUCHSTART) && sType == "touchstart")
                ||((iTrigFlags & FLAG_TOUCHEND)&& sType == "touchend"))
            {
                integer iAuth = llList2Integer(g_lTouchRequests, iTrig + 3);
                string sReply = (string) kToucher + "|" + (string) iAuth + "|" + sType +"|"+ (string) iLinkNumber;
                llMessageLinked(LINK_THIS, TOUCH_RESPONSE, sReply, llList2Key(g_lTouchRequests, iTrig));
            }
            if (sType =="touchend") ClearUser(kToucher, FALSE);
            return;
        }
    }
    // check for permanent triggers
    if (sendPermanentCommandFromLink(iLinkNumber, sType, kToucher)) return;
    if (iLinkNumber != LINK_ROOT)
    {
        if (sendPermanentCommandFromLink(LINK_ROOT, sType, kToucher)) return;
    }
    if (sType == "touchstart") llMessageLinked(LINK_SET, COMMAND_NOAUTH, "menu", kToucher);
}


default
{
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        g_kWearer = llGetOwner();
        SetPrefix("auto");
        g_iHUDChan = GetOwnerChannel(g_kWearer, 1111); // reinstated. personalized channel for this sub
        SetListeners();
        integer iAttachPt = llGetAttached();
        if ((iAttachPt > 0 && iAttachPt < 31) || iAttachPt == 39) // if collar is attached to the body (thus excluding HUD and root/avatar center)
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION);
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "Global_prefix", NULL_KEY);
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "channel", NULL_KEY);
    }

    attach(key kID)
    {
        g_kWearer = llGetOwner();
        if (kID == NULL_KEY)
        {
            llWhisper(g_iInterfaceChannel, "OpenCollar=No");
        }
        else
        {
            llWhisper(g_iInterfaceChannel, "OpenCollar=Yes");
        }
        integer iAttachPt = llGetAttached();
        if ((iAttachPt > 0 && iAttachPt < 31) || iAttachPt == 39) // if collar is attached to the body (thus excluding HUD and root/avatar center)
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION);
    }

    listen(integer iChan, string sName, key kID, string sMsg)
    {
        if (iChan == g_iHUDChan)
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
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, llGetOwnerKey(kID));
            }
            else
            {
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, llGetOwnerKey(kID));
            }
            return;
        }
        if (iChan == g_iLockMeisterChan)
        {
            llWhisper(g_iLockMeisterChan,(string)g_kWearer + "collar ok");
            return;
        }
        if(llGetOwnerKey(kID) == g_kWearer) // also works for attachments
        {
            string sw = sMsg; // we'll have to shave pieces off as we go to test
            // safeword can be the safeword or safeword said in OOC chat "((SAFEWORD))"
            // and may include prefix
            if (llGetSubString(sw, 0, 1) == "((" && llGetSubString(sw, -2, -1) == "))")
                sw = llGetSubString(sw, 2, -3);
            if (StartsWith(sw, g_sPrefix))
                sw = llGetSubString(sw, llStringLength(g_sPrefix), -1);
            if (sw == g_sSafeWord)
            {
                llMessageLinked(LINK_SET, COMMAND_SAFEWORD, "", NULL_KEY);
                llOwnerSay("You used your safeword, your owner will be notified you did.");
                return;
            }
        }
        //added for attachment auth (garvin)
        if (iChan == g_iInterfaceChannel)
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
        if (iNum==INTERFACE_RESPONSE)
        {
            if (sStr == "safeword") llRegionSay(g_iHUDChan, "safeword");
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
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
                llSay(g_iHUDChan,(string)g_kWearer+":pong");
            }
            //handle changing prefix and channel from owner
            else if (iNum == COMMAND_OWNER)
            {
                if (sCommand == "prefix")
                {
                    string value = llList2String(lParams, 1);
                    if (value == "")
                    {
                        Notify(kID,"prefix: " + g_sPrefix, FALSE);
                        return;
                    }
                    SetPrefix(value);
                    SetListeners();
                    Notify(kID, "\n" + llKey2Name(g_kWearer) + "'s prefix is '" + g_sPrefix + "'.\nTouch the " + CTYPE + " or say '" + g_sPrefix + "menu' for the main menu.\nSay '" + g_sPrefix + "help' for a list of chat commands.", FALSE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "Global_prefix=" + g_sPrefix, NULL_KEY);
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
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",TRUE", NULL_KEY);
                        }
                        else
                        {
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",FALSE", NULL_KEY);
                        }
                    }
                    else if (iNewChan == 0)
                    {
                        g_iListenChan0 = TRUE;
                        SetListeners();
                        Notify(kID, "You enabled the public channel listener.\nTo disable it use -1 as channel command.", FALSE);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",TRUE", NULL_KEY);
                    }
                    else if (iNewChan == -1)
                    {
                        g_iListenChan0 = FALSE;
                        SetListeners();
                        Notify(kID, "You disabled the public channel listener.\nTo enable it use 0 as channel command, remember you have to do this on your channel /" +(string)g_iListenChan, FALSE);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",FALSE", NULL_KEY);
                    }
                    else
                    {  //they left the param blank
                        Notify(kID, "Error: 'channel' must be given a number.", FALSE);
                    }
                }
            }
            if (kID == g_kWearer)
            {
                if (sCommand == "safeword")
                {   // new for safeword
                    if(llStringTrim(sValue, STRING_TRIM) != "")
                    {
                        g_sSafeWord = llList2String(lParams, 1);
                        llOwnerSay("You set a new safeword: " + g_sSafeWord + ".");
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "safeword=" + g_sSafeWord, NULL_KEY);
                    }
                    else
                    {
                        llOwnerSay("Your safeword is: " + g_sSafeWord + ".");
                    }
                }
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (sToken == "Global_prefix")
            {
                if (sValue == "") sValue = "auto";
                SetPrefix(sValue);
                SetListeners();
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (sToken == "channel")
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
                }
            }
        }
        //        else if (iNum == LM_SETTING_EMPTY && sStr == "prefix")
        //        {
        //            SetPrefix("auto");
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
        else if (iNum == TOUCH_REQUEST)
        {   //str will be pipe-delimited list with rcpt|flags|auth
            list lParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kRCPT = (key)llList2String(lParams, 0);
            integer iFlags = (integer)llList2String(lParams, 1);
            integer iAuth = (integer)llList2String(lParams, 2);            
            ClearUser(kRCPT, TRUE);            
            g_lTouchRequests += [kID, kRCPT, iFlags, iAuth];
            if (g_iNeedsPose) llStartAnimation(g_sPOSE_ANIM);
        }
        else if (iNum == TOUCH_CANCEL)
        {
            integer iIndex = llListFindList(g_lTouchRequests, [kID]);
            if (~iIndex)
            {
                g_lTouchRequests = llDeleteSubList(g_lTouchRequests, iIndex, iIndex - 1 + g_iStrideLength);
                if (g_iNeedsPose && [] == g_lTouchRequests) llStopAnimation(g_sPOSE_ANIM);
            }
        }

    }
    touch_start(integer iNum)
    {
        //Debug("touched");
        sendCommandFromLink(llDetectedLinkNumber(0), "touchstart", llDetectedKey(0));
    }

    touch_end(integer iNum)
    {
        sendCommandFromLink(llDetectedLinkNumber(0), "touchend", llDetectedKey(0));
    }

    //no more self resets
    changed(integer iChange)
    {
        if (iChange & CHANGED_OWNER)
        {
            llResetScript();
        }
    }

    run_time_permissions(integer iPerm)
    {
        if (iPerm & PERMISSION_TRIGGER_ANIMATION) g_iNeedsPose = TRUE;
    }
    
    on_rez(integer iParam)
    {
        llResetScript();
    }
}
