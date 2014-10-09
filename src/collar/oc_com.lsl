////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - listener                              //
//                                 version 3.990                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

integer g_iListenChan = 1;
integer g_iListenChan0 = TRUE;
string g_sPrefix = ".";
integer g_iPollForNameChange = 60; //seconds to poll for name change
integer g_iCustomName = FALSE; //this is our bit flag to see if we're using an LM_SETTING custom name

integer g_iLockMeisterChan = -8888;

integer g_iListener1;
integer g_iListener2;
integer g_iLockMeisterListener;

integer g_iHUDListener;
integer g_iHUDChan;
//list g_lHudComms;  //2 strided list of uuid and unixtime of something that communicated on the hud channel

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
integer NOTIFY=1002;
integer NOTIFY_OWNERS=1003;

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
integer g_iInterfaceChannel; // AO Backwards Compatibility
integer g_iListenHandleAtt;

integer ATTACHMENT_REQUEST = 600;
integer ATTACHMENT_RESPONSE = 601;
integer ATTACHMENT_FORWARD = 610;

key g_kWearer;
string g_sScript = "listener_";
string CTYPE = "collar";
string WEARERNAME;
list g_lOwners;

//globlals for supporting touch requests
list g_lTouchRequests; // 4-strided list in form of touchid, recipient, flags, auth level
integer g_iStrideLength = 4;

integer FLAG_TOUCHSTART = 0x01;
integer FLAG_TOUCHEND = 0x02;

integer g_iNeedsPose = FALSE;  // should the avatar be forced into a still pose for making touching easier
string g_sPOSE_ANIM = "turn_180";

integer g_iTouchNotify = FALSE;  // for Touch Notify


/*
integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to 
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+") :\n" + sStr);
}
*/

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
//    integer pos;
//    while (~pos=llSubStringIndex(sMsg, "%WEARERNAME%")) {
//        if (llStringLength(sMsg) == 12) { sMsg = WEARERNAME; }
//        else if (pos == 0) { sMsg = WEARERNAME+llGetSubString(sMsg, pos+12, -1); }
//        else if (pos == llStringLength(sMsg)-12) { sMsg = llGetSubString(sMsg, 0, pos-1)+WEARERNAME; }
//        else { sMsg = llGetSubString(sMsg, 0, pos-1)+WEARERNAME+llGetSubString(sMsg, pos+12, -1); }
//    }
    if ((key)kID){
        if (kID == g_kWearer) llOwnerSay(sMsg);
        else {
//            if (~llListFindList(g_lHudComms,[kID])){
//                llRegionSayTo(kID,g_iHUDChan,sMsg);
//            } else 
            if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
            else llInstantMessage(kID, sMsg);
            if (iAlsoNotifyWearer) llOwnerSay(sMsg);
        }
    //} else {
        //Debug("Bad key, can't notify:"+sMsg);
    }
}

NotifyOwners(string sMsg, string comments) {
    integer n;
    integer iStop = llGetListLength(g_lOwners);
    for (n = 0; n < iStop; n += 2) {
        key kAv = (key)llList2String(g_lOwners, n);
        if (comments=="ignoreNearby"){
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

//functions from touch script
ClearUser(key kRCPT, integer iNotify) {
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

sendCommandFromLink(integer iLinkNumber, string sType, key kToucher) {
    // check for temporary touch requests
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
    // check for permanent triggers (inlined sendPermanentCommandFromLink(iLinkNumber, sType, kToucher);)    
    //string sDesc = (string)llGetObjectDetails(llGetLinkKey(iLinkNumber), [OBJECT_DESC]);
    //sDesc += (string)llGetObjectDetails(llGetLinkKey(LINK_ROOT), [OBJECT_DESC]);
    
    string sDesc = llDumpList2String(llGetLinkPrimitiveParams(iLinkNumber,[PRIM_DESC])+llGetLinkPrimitiveParams(LINK_ROOT,[PRIM_DESC]),"~");
    
    list lDescTokens = llParseStringKeepNulls(sDesc, ["~"], []);
    integer iNDescTokens = llGetListLength(lDescTokens);
    integer iDescToken;
    for (iDescToken = 0; iDescToken < iNDescTokens; iDescToken++) {
        string sDescToken = llList2String(lDescTokens, iDescToken);
        if (sDescToken == sType || sDescToken == sType+":" || sDescToken == sType+":none") return;
        else if (!llSubStringIndex(sDescToken, sType+":")) {                
            string sCommand = llGetSubString(sDescToken, llStringLength(sType)+1, -1);
            if (sCommand != "") llMessageLinked(LINK_SET, COMMAND_NOAUTH, sCommand, kToucher);
            return;
        }
    }

    if (sType == "touchstart") {
        llMessageLinked(LINK_SET, COMMAND_NOAUTH, "menu", kToucher);
        if (g_iTouchNotify && kToucher!=g_kWearer) llOwnerSay("\n\nsecondlife:///app/agent/"+(string)kToucher+"/about touched your "+CTYPE+".\n");
    }
}


default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        WEARERNAME = llGetDisplayName(g_kWearer);
        if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME == llKey2Name(g_kWearer);
        
        list name = llParseString2List(llKey2Name(g_kWearer), [" "], []);
        g_sPrefix = llGetSubString(llList2String(name, 0), 0, 0);
        g_sPrefix += llGetSubString(llList2String(name, 1), 0, 0);
        g_sPrefix = llToLower(g_sPrefix);
        //Debug("Default prefix: " + g_sPrefix);

        //inlined single use getOwnerChannel function
        g_iHUDChan = -llAbs((integer)("0x"+llGetSubString((string)g_kWearer,2,7)) + 1111);
        if (g_iHUDChan > -10000) g_iHUDChan -= 30000;

        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
    
        //set up listeners... inlined existing function
        //public listener
        llListenRemove(g_iListener1);
        if (g_iListenChan0 == TRUE) g_iListener1 = llListen(0, "", NULL_KEY, "");

        //private listener
        llListenRemove(g_iListener2);
        g_iListener2 = llListen(g_iListenChan, "", NULL_KEY, "");

        //lockmeister listener
        llListenRemove(g_iLockMeisterListener);
        g_iLockMeisterListener = llListen(g_iLockMeisterChan, "", NULL_KEY, (string)g_kWearer + "collar");

        //garvin attachments listener
        llListenRemove(g_iListenHandleAtt);
        g_iListenHandleAtt = llListen(g_iInterfaceChannel, "", "", "");

        //owner hud listener
        llListenRemove(g_iHUDListener);
        g_iHUDListener = llListen(g_iHUDChan, "", NULL_KEY ,""); //reinstated
    
        integer iAttachPt = llGetAttached();
        if ((iAttachPt > 0 && iAttachPt < 31) || iAttachPt == 39) // if collar is attached to the body (thus excluding HUD and root/avatar center)
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION);
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "Global_prefix", "");
        //llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "channel", "");
        //Debug("Starting");
    }

    attach(key kID)
    {
        //g_kWearer = llGetOwner();
        if (kID == NULL_KEY)
        {
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=No");
        }
        else
        {
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=Yes");
        }
        integer iAttachPt = llGetAttached();
        if ((iAttachPt > 0 && iAttachPt < 31) || iAttachPt == 39) // if collar is attached to the body (thus excluding HUD and root/avatar center)
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION);
    }

    listen(integer iChan, string sName, key kID, string sMsg)
    {
        if (iChan == g_iHUDChan)
        {
//            //track hud channel users
//            integer hudIndex;
//            if (~hudIndex=llListFindList(g_lHudComms,[kID])){
//                g_lHudComms=llDeleteSubList(g_lHudComms,hudIndex,hudIndex+1);
//            }
//            g_lHudComms += [kID,llGetUnixTime()];
            
            //check for a ping, if we find one we request auth and answer in LMs with a pong
            if (sMsg==(string)g_kWearer + ":ping")
            {
                //llMessageLinked(LINK_SET, COMMAND_NOAUTH, "ping", kID);
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "ping", llGetOwnerKey(kID));
            }
            // an object wants to know the version, we check if it is allowed to
            else if (sMsg==(string)g_kWearer + ":version")
            {
                //llMessageLinked(LINK_SET, COMMAND_NOAUTH, "objectversion", kID);
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, "objectversion", llGetOwnerKey(kID));
            }
            // it it is not a ping, it should be a command for use, to make sure it has to have the key in front of it
            else if (!llSubStringIndex(sMsg,(string)g_kWearer + ":"))
            {
                sMsg = llGetSubString(sMsg, 37, -1);
                //llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, kID);
                llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, llGetOwnerKey(kID));
            }
            else
            {
//                //Debug("command: "+sMsg+" from "+(string)kID);
//                if (llGetOwnerKey(kID)==llGetOwner()){  //if the wearer's attachment requests it, then the command can be proxied for another user
//                    key sDestAv = llGetSubString(sMsg, 0, 35);
//                    if ((key)sDestAv){
//                        sMsg = llGetSubString(sMsg, 36, -1);
//                        kID=sDestAv;
//                        //Debug("command for foreign user");
//                    }
//                }
                //Debug("command: "+sMsg+" from "+(string)kID);
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
            if (llGetSubString(sw, 0, 3) == "/me ") sw = llGetSubString(sw, 4, -1);
            if (llGetSubString(sw, 0, 1) == "((" && llGetSubString(sw, -2, -1) == "))") sw = llGetSubString(sw, 2, -3);
            if (llSubStringIndex(sw, g_sPrefix)==0) sw = llGetSubString(sw, llStringLength(g_sPrefix), -1);
            if (sw == g_sSafeWord) {
                llMessageLinked(LINK_SET, COMMAND_SAFEWORD, "", "");
                
                llOwnerSay("You used your safeword, your owners will be notified you did.");
                NotifyOwners("Your sub " + WEARERNAME + " has used the safeword. Please check on their well-being in case further care is required.","");
                llMessageLinked(LINK_THIS, INTERFACE_RESPONSE, "safeword", "");
                return;
            }
        }
        //added for attachment auth (garvin)
        if (iChan == g_iInterfaceChannel)
        {
            //Debug(sMsg);
            //do nothing if wearer isnt owner of the object
            if (llGetOwnerKey(kID) != g_kWearer) return;
            //if (sMsg == "OpenCollar?") llWhisper(g_iInterfaceChannel, "OpenCollar=Yes");
            if (sMsg == "OpenCollar?") llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=Yes");
            else if (sMsg == "version") llMessageLinked(LINK_SET, COMMAND_WEARER, "attachmentversion", g_kWearer);  //main knows version number, main can respond to this request for us
            else {
                list lParams = llParseString2List(sMsg, ["|"], []);
                integer iAuth = llList2Integer(lParams, 0);
                
                if (iAuth == 0) //auth request
                {
                    string sCmd = llList2String(lParams, 1);
                    string sUserId= llGetSubString(llList2String(lParams, 2),0,35);
                    string sObjectId= llGetSubString(llList2String(lParams, 2),36,-1);
                    
                    //Debug("garvin auth for key"+sUserId);
                    //just send ATTACHMENT_REQUEST and ID to auth, as no script IN the collar needs the command anyway
                    llMessageLinked(LINK_SET, ATTACHMENT_REQUEST, sCmd+"|"+sUserId+"|"+sObjectId, (key)sUserId);
                }
                else if (iAuth == EXT_COMMAND_COLLAR) //command from attachment to AO
                {
                    llRegionSayTo(g_kWearer, g_iInterfaceChannel, sMsg);
                }
                else
                {
                    // we received a unkown command, so we just forward it via LM into the cuffs
                    llMessageLinked(LINK_SET, ATTACHMENT_FORWARD, sMsg, kID);
                }
            }
        } else { //check for our prefix, or *
            if (!llSubStringIndex(sMsg, g_sPrefix)) sMsg = llGetSubString(sMsg, llStringLength(g_sPrefix), -1); //strip our prefix from command
            else if (llGetSubString(sMsg, 0, 0) == "*") sMsg = llGetSubString(sMsg, 1, -1); //strip * (all collars wildcard) from command
            else if ((llGetSubString(sMsg, 0, 0) == "#") && (kID != g_kWearer)) sMsg = llGetSubString(sMsg, 1, -1); //strip # (all collars but me) from command
            else return;
            //Debug("Got comand "+sMsg);
            llMessageLinked(LINK_SET, COMMAND_NOAUTH, sMsg, kID);
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
            
            if (sStr == "ping") {  // ping from an object, we answer to it on the object channel
                llRegionSayTo(kID,g_iHUDChan,(string)g_kWearer+":pong"); // sim wide response to owner hud
            } else if (iNum == COMMAND_OWNER) {  //handle changing prefix and channel from owner
                if (sCommand == "prefix")
                {
                    string value = llList2String(lParams, 1);
                    if (value == "")
                    {
                        Notify(kID,"prefix: " + g_sPrefix, FALSE);
                        return;
                    }
                    g_sPrefix=value;
                    Notify(kID, "\n" + WEARERNAME + "'s prefix is '" + g_sPrefix + "'.\nTouch the " + CTYPE + " or say '" + g_sPrefix + "menu' for the main menu.\nSay '" + g_sPrefix + "help' for a list of chat commands.", FALSE);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, "Global_prefix=" + g_sPrefix, "");
                }
                else if (sCommand == "name")
                {
                    if (sValue=="") {  //Just let them know their current name
                        string message= "\n\n"+WEARERNAME+"'s current name is " + WEARERNAME;
                        message += "\nName command help: <prefix>name [newname|reset]\n";
                        Notify(kID, message, FALSE);
                    }
                    else if(sValue=="reset") { //unset Global_WearerName
                        string message=WEARERNAME+"'s new name is reset to ";
                        WEARERNAME = llGetDisplayName(g_kWearer);
                        if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME == llKey2Name(g_kWearer);
                        llMessageLinked(LINK_SET, LM_SETTING_DELETE, "Global_WearerName", "");  
                        message += WEARERNAME;
                        g_iCustomName = FALSE;
                        Notify(kID, message, FALSE);
                    }
                    else {
                        string message=WEARERNAME+"'s new name is ";
                        WEARERNAME = llDumpList2String(llList2List(lParams, 1,-1)," ");
                        message += WEARERNAME;
                        g_iCustomName = TRUE;
                        Notify(kID, message, FALSE);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "Global_WearerName=" + WEARERNAME, ""); //store            
                        llMessageLinked(LINK_SET, LM_SETTING_REQUEST, "Global_WearerName", ""); //force update scripts                        
                    }               
                }
                else if (sCommand == "channel")
                {
                    integer iNewChan = (integer)sValue;
                    if (sValue=="") {  //they left the param blank, report listener status
                        string message=CTYPE+" is listening on channel";
                        if (g_iListenChan0) message += "s 0 and";
                        message += " "+(string)g_iListenChan+".";
                        Notify(kID, message, FALSE);
                    } else if (iNewChan > 0) { //set new channel for private listener
                        g_iListenChan =  iNewChan;

                        llListenRemove(g_iListener2);
                        g_iListener2 = llListen(g_iListenChan, "", NULL_KEY, "");

                        Notify(kID, "Now listening on channel " + (string)g_iListenChan + ".", FALSE);
                        if (g_iListenChan0) //save setting along with the state of thepublic listener (messy!)
                        {
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",TRUE", "");
                        }
                        else
                        {
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",FALSE", "");
                        }
                    }
                    else if (iNewChan == 0) //enable public listener
                    {
                        g_iListenChan0 = TRUE;
                        llListenRemove(g_iListener1); 
                        g_iListener1 = llListen(0, "", NULL_KEY, "");
                        Notify(kID, "You enabled the public channel listener.\nTo disable it use -1 as channel command.", FALSE);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",TRUE", "");
                    }
                    else if (iNewChan == -1)  //disable public listener
                    {
                        g_iListenChan0 = FALSE;
                        llListenRemove(g_iListener1); 
                        Notify(kID, "You disabled the public channel listener.\nTo enable it use 0 as channel command, remember you have to do this on your channel /" +(string)g_iListenChan, FALSE);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "channel=" + (string)g_iListenChan + ",FALSE", "");
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
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "safeword=" + g_sSafeWord, "");
                    }
                    else
                    {
                        llOwnerSay("Your safeword is: " + g_sSafeWord + ".");
                    }
                }                
                else if (sCommand == "busted")
                {
                    if (sValue == "on")
                    {
                        llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"Global_touchNotify=1","");
                        g_iTouchNotify=TRUE;
                        llOwnerSay("Touch notification is now enabled.");
                    }                    
                    else if (sValue == "off")
                    {
                        llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"Global_touchNotify","");
                        g_iTouchNotify=FALSE;
                        llOwnerSay("Touch notification is now disabled.");
                    }
                    else if (sValue == "") 
                    {
                        if (g_iTouchNotify) {
                            llOwnerSay("Touch notification is now disabled.");
                            llMessageLinked(LINK_THIS,LM_SETTING_DELETE,"Global_touchNotify","");
                            g_iTouchNotify = FALSE;
                        }
                        else {
                            llOwnerSay("Touch notification is now enabled.");                           
                            llMessageLinked(LINK_THIS,LM_SETTING_SAVE,"Global_touchNotify=1","");
                            g_iTouchNotify = TRUE;
                        }
                    }
                }
            }
        } else if (iNum == LM_SETTING_SAVE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "auth_owner" && llStringLength(sValue) > 0) g_lOwners = llParseString2List(sValue, [","], []);
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            
            if (sToken == "Global_prefix")
            {
                if (sValue != "") g_sPrefix=sValue;
            }
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (sToken == "Global_touchNotify") g_iTouchNotify = (integer)sValue; // for Touch Notify
            else if (sToken == "Global_WearerName") WEARERNAME = sValue;
            else if (sToken == "auth_owner" && llStringLength(sValue) > 0) g_lOwners = llParseString2List(sValue, [","], []);
            else if (sToken == "listener_safeword") g_sSafeWord = sValue;
            else if (sToken == "listener_channel") {
                g_iListenChan = (integer)sValue;
                if (llGetSubString(sValue, llStringLength(sValue) - 5 , -1) == "FALSE") g_iListenChan0 = FALSE;
                else g_iListenChan0 = TRUE;
                
                llListenRemove(g_iListener1);
                if (g_iListenChan0 == TRUE) g_iListener1 = llListen(0, "", NULL_KEY, "");

                llListenRemove(g_iListener2);
                g_iListener2 = llListen(g_iListenChan, "", NULL_KEY, "");
            }
        }
        else if (iNum == POPUP_HELP)
        {
            //replace _PREFIX_ with prefix, and _CHANNEL_ with (strin) channel
            sStr = llDumpList2String(llParseStringKeepNulls((sStr = "") + sStr, ["_PREFIX_"], []), g_sPrefix);
            sStr = llDumpList2String(llParseStringKeepNulls((sStr = "") + sStr, ["_CHANNEL_"], []), (string)g_iListenChan);
            Notify(kID, sStr, FALSE);
        }
        //added for attachment auth (garvin)
        else if (iNum == ATTACHMENT_RESPONSE)
        {
            //Debug(sStr);
            //here the response from auth has to be:
            // llMessageLinked(LINK_SET, ATTACHMENT_RESPONSE, "auth", UUID);
            //where "auth" has to be (string)COMMAND_XY
            //reason for this is: i dont want to have all other scripts recieve a COMMAND+xy and check further for the command
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "RequestReply|" + sStr);
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
        } else if (iNum==NOTIFY){
            Notify(kID,llGetSubString(sStr,1,-1),(integer)llGetSubString(sStr,0,0));
        } else if (iNum==NOTIFY_OWNERS){
            NotifyOwners(sStr,(string)kID);
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
        if (iChange & CHANGED_OWNER) llResetScript();
/*        
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled){
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/        
    }

    timer()
    {
        if (g_iCustomName == FALSE) { //If we don't have a custom LM_SETTING Global_WearerName
            string sLoadDisplayName = llGetDisplayName(g_kWearer); //Load this once
            if (((sLoadDisplayName != "") && (sLoadDisplayName != "???")) && (sLoadDisplayName != WEARERNAME)) {
                //The displayname loaded correctly, and it's different than our current WEARERNAME
                //wearer changed their displayname since last timer event
                WEARERNAME = sLoadDisplayName;
                llMessageLinked(LINK_SET, LM_SETTING_DELETE, "Global_WearerName", "");  //force update other scripts
            }
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
