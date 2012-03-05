// OpenCollar - touch
//
// This script is under the GPLv2 license with additional requirement that when it is distributed,
// either as is or in a modified form, within SecondLife or any virtual world with similar permissions system,
// then its copies must keep all permissions allowed by the platform (in SecondLife: copy, transfer, modify).
//
// This script handles the touch_start and touch_end events and sends relevant commands as LMs to other plugins.
//

integer COMMAND_NOAUTH = 0;

integer TOUCH_REQUEST = -9500;
integer TOUCH_CANCEL = -9501;
integer TOUCH_RESPONSE = -9502;
integer TOUCH_EXPIRE = -9503;

list g_lTouchRequests; // 4-strided list in form of touchid, recipient, flags, auth level
integer g_iStrideLength = 4;

integer FLAG_TOUCHSTART = 0x01;
integer FLAG_TOUCHEND = 0x02;

integer g_iNeedsPose = FALSE;  // should the avatar be forced into a still pose for making touching easier
string g_sPOSE_ANIM = "turn_180";

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
        integer iAttachPt = llGetAttached();
        if ((iAttachPt > 0 && iAttachPt < 31) || iAttachPt == 39) // if collar is attached to the body (thus excluding HUD and root/avatar center)
            llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
    }
    
    run_time_permissions(integer iPerm)
    {
        if (iPerm & PERMISSION_TRIGGER_ANIMATION) g_iNeedsPose = TRUE;
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == TOUCH_REQUEST)
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
        sendCommandFromLink(llDetectedLinkNumber(0), "touchstart", llDetectedKey(0));
    }

    touch_end(integer iNum)
    {
        sendCommandFromLink(llDetectedLinkNumber(0), "touchend", llDetectedKey(0));
    }

    on_rez(integer iParam)
    {   // safe: does not need to keep settings across relogs (all settings are actually encoded in prim descriptions)
        llResetScript();
    }
    
    attach(key kId)
    {  // in case it would be attached after being rezed
        llResetScript();        
    }
}