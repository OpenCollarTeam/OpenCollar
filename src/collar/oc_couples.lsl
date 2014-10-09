////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollar - couples                               //
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

string g_sParentMenu = "Animations";
string g_sSubMenu = " Couples";
string UPMENU = "BACK";
//string MORE = ">";
key g_kAnimmenu;    //Dialog handle
key g_kPart;    //Dialog handle
key g_kTimerMenu;    //Dialog handle
integer g_iAnimTimeout;
integer g_iPermissionTimeout;

key g_kWearer;

string STOP_COUPLES = "STOP";
string TIME_COUPLES = "TIME";

integer g_iLine1;
integer g_iLine2;
key g_kDataID1;
key g_kDataID2;
string CARD1 = "coupleanims";
string CARD2 = "coupleanims_personal";
integer card1line1;
integer card1line2;
integer iCardComplete;

string WEARERNAME;

list g_lAnimCmds;//1-strided list of strings that will trigger
list g_lAnimSettings;//4-strided list of subAnim|domAnim|offset|text, running parallel to g_lAnimCmds,
//such that g_lAnimCmds[0] corresponds to g_lAnimSettings[0:3], and g_lAnimCmds[1] corresponds to g_lAnimSettings[4:7], etc

key g_kCardID1;//used to detect whether coupleanims card has changed
key g_kCardID2;
float g_fRange = 10.0;//only scan within this range for anim partners

float g_fWalkingDistance = 1.0; // How close to try to get to the target point while walking, in meters
float g_fWalkingTau = 1.5; // how hard to push me toward partner while walking
float g_fAlignTau = 0.05; // how hard to push me toward partner while aligning
float g_fAlignDelay = 0.6; // how long to let allignment settle (in seconds)

key g_kCmdGiver; // id of the avatar having issued the last command
integer g_iCmdAuth; // auth level of that avatar
integer g_iCmdIndex;
key g_kPartner;
string g_sPartnerName;
float g_fTimeOut = 20.0;//duration of anim

integer g_iTargetID; // remember the walk target to delete; target handle
string g_sSubAnim;
string g_sDomAnim;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
//integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
//integer COMMAND_EVERYONE = 504;
//integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
//integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
//integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
//integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
//integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;
integer SENSORDIALOG = -9003;

string g_sScript;
string g_sStopString = "stop";
integer g_iStopChan = 99;
integer g_iListener;    //stop listener handle

//Debug(string sStr){ llOwnerSay(llGetScriptName() + ": " + sStr);}

refreshTimer(){
    integer timeNow=llGetUnixTime();
    if (g_iAnimTimeout <= timeNow && g_iAnimTimeout > 0){
        //Debug("Anim timeout="+(string)g_iAnimTimeout+"\ntime now="+(string)timeNow);
        g_iAnimTimeout=0;
        StopAnims();
    } else if (g_iPermissionTimeout <= timeNow && g_iPermissionTimeout > 0){
        //Debug("Perm timeout="+(string)g_iPermissionTimeout+"\ntime now="+(string)timeNow);
        g_iPermissionTimeout=0;
        llListenRemove(g_iListener);
        //llMessageLinked(LINK_SET, CPLANIM_PERMRESPONSE, "0", g_kPartner);
        g_kPartner = NULL_KEY;
    }
    integer nextTimeout=g_iAnimTimeout;
    if (g_iPermissionTimeout < g_iAnimTimeout && g_iPermissionTimeout > 0){
        nextTimeout=g_iPermissionTimeout;
    }
    llSetTimerEvent(nextTimeout-timeNow);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

CoupleAnimMenu(key kID, integer iAuth)
{
    string sPrompt = "\nChoose an animation to play.\n\nAnimations will play " ;    
    if(g_fTimeOut == 0) sPrompt += "ENDLESS." ;
    else sPrompt += "for "+(string)llCeil(g_fTimeOut)+" seconds.";    
    sPrompt += "\n\nwww.opencollar.at/animations\n\n";
    list lButtons = g_lAnimCmds;//we're limiting this to 9 couple anims then
    lButtons += [TIME_COUPLES, STOP_COUPLES];
    g_kAnimmenu=Dialog(kID, sPrompt, lButtons, [UPMENU],0, iAuth);
}

string StrReplace(string sSrc, string from, string to)
{//replaces all occurrences of 'from' with 'to' in 'sSrc'.
    integer len = (~-(llStringLength(from)));
    if(~len)
    {
        string  buffer = sSrc;
        integer b_pos = -1;
        integer to_len = (~-(llStringLength(to)));
        @loop;//instead of a while loop, saves 5 bytes (and run faster).
        integer to_pos = ~llSubStringIndex(buffer, from);
        if(to_pos)
        {
            b_pos -= to_pos;
            sSrc = llInsertString(llDeleteSubString(sSrc, b_pos, b_pos + len), b_pos, to);
            b_pos += to_len;
            buffer = llGetSubString(sSrc, (-~(b_pos)), 0x8000);
            //buffer = llGetSubString(sSrc = llInsertString(llDeleteSubString(sSrc, b_pos -= to_pos, b_pos + len), b_pos, to), (-~(b_pos += to_len)), 0x8000);
            jump loop;
        }
    }
    return sSrc;
}

//added to stop eventual still going animations
StopAnims()
{
    if (llGetInventoryType(g_sSubAnim) == INVENTORY_ANIMATION) llMessageLinked(LINK_SET, ANIM_STOP, g_sSubAnim, "");
    if (llGetInventoryType(g_sDomAnim) == INVENTORY_ANIMATION)
    {
        if (llKey2Name(g_kPartner) != "") llStopAnimation(g_sDomAnim);
    }

    g_sSubAnim = "";
    g_sDomAnim = "";
}

Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else
    {
        if (llGetAgentSize(kID)) llRegionSayTo(kID,0,sMsg);
        else llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

// Calmly walk up to your partner and face them. Does not position the avatar precicely
MoveToPartner() {
    list partnerDetails = llGetObjectDetails(g_kPartner, [OBJECT_POS, OBJECT_ROT]);
    vector partnerPos = llList2Vector(partnerDetails, 0);
    rotation partnerRot = llList2Rot(partnerDetails, 1);
    vector partnerEuler = llRot2Euler(partnerRot);
    
    // turn to face the partner
    llMessageLinked(LINK_SET, RLV_CMD, "setrot:" + (string)(-PI_BY_TWO-partnerEuler.z) + "=force", NULL_KEY);
    
    g_iTargetID = llTarget(partnerPos, g_fWalkingDistance);
    llMoveToTarget(partnerPos, g_fWalkingTau);
}

default
{
    listen(integer channel, string sName, key kID, string sMessage)
    {
        //Debug("listen: " + sMessage + ", channel=" + (string)channel);
        llListenRemove(g_iListener);
        if (channel == g_iStopChan)
        {//this abuses the GROUP auth a bit but i think it's ok.
            //Debug("message on stop channel");
            llMessageLinked(LINK_SET, COMMAND_GROUP, "stopcouples", kID);
        }
    }
    state_entry()
    {
        //llOwnerSay("Coupleanim1, default state_entry: "+(string)llGetFreeMemory());
        g_sScript = "coupleanim_";
        g_kWearer = llGetOwner();
        WEARERNAME = llGetDisplayName(g_kWearer);
        if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME = llKey2Name(g_kWearer); //sanity check, fallback if necessary
        if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD)
        {//card is present, start reading
            g_kCardID1 = llGetInventoryKey(CARD1);
            g_iLine1 = 0;
            g_lAnimCmds = [];
            g_lAnimSettings = [];
            g_kDataID1 = llGetNotecardLine(CARD1, g_iLine1);
        }
        if (llGetInventoryType(CARD2) == INVENTORY_NOTECARD)
        {//card is present, start reading
            g_kCardID2 = llGetInventoryKey(CARD2);
            g_iLine2 = 0;
            g_kDataID2 = llGetNotecardLine(CARD2, g_iLine2);
        }
        
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
    }
    on_rez(integer start)
    {

        //added to stop anims after relog when you logged off while in an endless couple anim
        if (g_sSubAnim != "" && g_sDomAnim != "")
        {
             // wait a second to make sure the poses script reseted properly
             llSleep(1.0);
             StopAnims();
        }
        llResetScript();
    }
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        //if you don't care who gave the command, so long as they're one of the above, you can just do this instead:
        if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            //the command was given by either owner, secowner, group member, or wearer
            list lParams = llParseString2List(sStr, [" "], []);
            g_kCmdGiver = kID; g_iCmdAuth = iNum;
            string sCommand = llToLower(llList2String(lParams, 0));
            string sValue = llToLower(llList2String(lParams, 1));
            integer tmpiIndex = llListFindList(g_lAnimCmds, [sCommand]);
            if (tmpiIndex != -1)    //if the couple anim exists
            {
                g_iCmdIndex = tmpiIndex;
                //Debug(sCommand);
                //we got an anim command.
                if (llGetListLength(lParams) > 1)//we've been given a name of someone to kiss.  scan for it
                {
                    string sTmpName = llDumpList2String(llList2List(lParams, 1, -1), " ");//this makes it so we support even full names in the command
                    //llSensor("", NULL_KEY, AGENT, g_fRange, PI);  //replaced with call to sensor dialog
                    g_kPart=llGenerateKey();
                    llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|\nChoose a partner:\n|0|``"+(string)AGENT+"`"+(string)g_fRange+"`"+(string)PI +"`"+sTmpName+"`1"+ "|BACK|" + (string)iNum, g_kPart);
                }
                else        //no name given.  
                {
                    if (kID == g_kWearer)                    //if commander is not sub, then treat commander as partner
                    {
                        llMessageLinked(LINK_SET, POPUP_HELP, "Error: you didn't give the name of the person you want to animate.  To " + sCommand + " Nandana Singh, for example, you could say /_CHANNEL__PREFIX" + sCommand + " nan", g_kWearer);
                    }
                    else                //else set partner to commander
                    {
                        g_kPartner = g_kCmdGiver;
                        g_sPartnerName = llGetDisplayName(g_kPartner);
                        if (g_sPartnerName == "???" || g_sPartnerName == "") g_sPartnerName = llKey2Name(g_kWearer); //sanity check, fallback if necessary
                        //added to stop eventual still going animations
                        StopAnims();
                        //llMessageLinked(LINK_SET, CPLANIM_PERMREQUEST, sCommand, g_kPartner);
                        llRequestPermissions(g_kPartner, PERMISSION_TRIGGER_ANIMATION);
                        llOwnerSay("Offering to " + sCommand + " " + g_sPartnerName + ".");
                    }
                }
            }
            else if (sStr == "stopcouples")
            {
                StopAnims();
            }
            else if (sStr == "menu "+g_sSubMenu || sStr == "couples")
            {
                CoupleAnimMenu(kID, iNum);
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if ((iNum == LM_SETTING_RESPONSE || iNum == LM_SETTING_DELETE) 
                && llSubStringIndex(sStr, "Global_WearerName") == 0 ) {
            integer iInd = llSubStringIndex(sStr, "=");
            string sValue = llGetSubString(sStr, iInd + 1, -1);
            //We have a broadcasted change to WEARERNAME to work with
            if (iNum == LM_SETTING_RESPONSE) WEARERNAME = sValue;
            else {
                g_kWearer = llGetOwner();
                WEARERNAME = llGetDisplayName(g_kWearer);
                if (WEARERNAME == "???" || WEARERNAME == "") WEARERNAME == llKey2Name(g_kWearer);
            }
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == g_sScript + "timeout")
            {
                g_fTimeOut = (float)sValue;
            }
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == g_kAnimmenu)
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                }
                else if (sMessage == STOP_COUPLES)
                {
                    StopAnims();
                    CoupleAnimMenu(kAv, iAuth);
                }
                else if (sMessage == TIME_COUPLES)
                {
                    string sPrompt = "\nChoose the duration for couple animations.\n\nCurrent duration: ";
                    if(g_fTimeOut == 0) sPrompt += "ENDLESS." ;
                    else sPrompt += "for "+(string)llCeil(g_fTimeOut)+" seconds.";  
                    g_kTimerMenu=Dialog(kAv, sPrompt, ["10", "20", "30","40", "50", "60","90", "120", "ENDLESS"], [UPMENU],0, iAuth);
                }
                else
                {
                    integer iIndex = llListFindList(g_lAnimCmds, [sMessage]);
                    if (iIndex != -1)
                    {
                        g_kCmdGiver = kAv;
                        g_iCmdAuth = iAuth;
                        g_iCmdIndex = iIndex;
                        //llSensor("", NULL_KEY, AGENT, g_fRange, PI);
                        g_kPart=llGenerateKey();
                        llMessageLinked(LINK_THIS, SENSORDIALOG, (string)g_kCmdGiver + "|\nChoose a partner:\n|0|``"+(string)AGENT+"`"+(string)g_fRange+"`"+(string)PI + "|BACK|" + (string)iAuth, g_kPart);
                    }
                }
            }
            else if (kID == g_kPart)
            {
                //Debug("Response from partner"+sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU)
                {
                    CoupleAnimMenu(kAv, iAuth);
                }
                else
                {
                    //process return from sensordialog
                    g_kPartner = (key)sMessage;
                    g_sPartnerName = llGetDisplayName(g_kPartner);
                    if (g_sPartnerName == "???" || g_sPartnerName == "") WEARERNAME = llKey2Name(g_kPartner); //sanity check, fallback if necessary
                    StopAnims();
                    string sCommand = llList2String(g_lAnimCmds, g_iCmdIndex);
                    llRequestPermissions(g_kPartner, PERMISSION_TRIGGER_ANIMATION);
                    llOwnerSay("Offering to "+ sCommand +" "+ g_sPartnerName);
                    Notify(g_kPartner,  WEARERNAME + " would like to give you a " + sCommand + ". Click [Yes] to accept.", FALSE );
                }   
            }
            else if (kID == g_kTimerMenu)
            {
                //Debug("Response from timer menu"+sStr);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMessage == UPMENU)
                {
                    CoupleAnimMenu(kAv, iAuth);
                }
                else if ((integer)sMessage > 0 && ((string)((integer)sMessage) == sMessage))
                {
                    g_fTimeOut = (float)((integer)sMessage);
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "timeout=" + (string)g_fTimeOut, "");
                    Notify (kAv, "Couple Anmiations play now for " + (string)llRound(g_fTimeOut) + " seconds.",TRUE);
                    CoupleAnimMenu(kAv, iAuth);
                }
                else if (sMessage == "ENDLESS")
                {
                    g_fTimeOut = 0.0;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sScript + "timeout=0.0", "");
                    Notify (kAv, "Couple Anmiations play now forever. Use the menu or type *stopcouples to stop them again.",TRUE);
                    CoupleAnimMenu(kAv, iAuth);
                }
            }
        }
    }
    not_at_target()
    {
        //this might make us chase the partner.  we'll see.  that might not be bad
        llTargetRemove(g_iTargetID);
        MoveToPartner();
    }
    at_target(integer tiNum, vector targetpos, vector ourpos)
    {
        llTargetRemove(tiNum);
        llStopMoveToTarget();
        
        //AlignWithPartner
        float offset = 10.0;
        if (g_iCmdIndex != -1) offset = (float)llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 2);
        list partnerDetails = llGetObjectDetails(g_kPartner, [OBJECT_POS, OBJECT_ROT]);
        vector partnerPos = llList2Vector(partnerDetails, 0);
        rotation partnerRot = llList2Rot(partnerDetails, 1);
        vector myPos = llList2Vector(llGetObjectDetails(llGetOwner(), [OBJECT_POS]), 0);
    
        vector target = partnerPos + (<1.0, 0.0, 0.0> * partnerRot * offset); // target is <offset> meters in front of the partner
        target.z = myPos.z; // ignore height differences
        llMoveToTarget(target, g_fAlignTau);
        llSleep(g_fAlignDelay);
        llStopMoveToTarget();
        
        //we've arrived.  let's play the anim and spout the text
        g_sSubAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4);
        g_sDomAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 1);
        
        
        llMessageLinked(LINK_SET, ANIM_START, g_sSubAnim, "");
        llStartAnimation(g_sDomAnim);//note that we don't double check for permissions here, so if the coupleanim1 script sends its messages out of order, this might fail
        g_iListener = llListen(g_iStopChan, "", g_kPartner, g_sStopString);
        //llInstantMessage(g_kPartner, "If you would like to stop the animation early, say /" + (string)g_iStopChan + g_sStopString + " to stop.");
        Notify(g_kPartner, "If you would like to stop the animation early, say /" + (string)g_iStopChan + g_sStopString + " to stop.", FALSE);
    
        
        string text = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 3);
        if (text != "")
        {    
            string sName = llGetObjectName();
            string sObjectName;
            text = StrReplace(text,"_PARTNER_",g_sPartnerName);
            text = StrReplace(text,"_SELF_",WEARERNAME);
            llSetObjectName("");
            llSay(0, "/me " + text);
            llSetObjectName(sName);           
        }
        if (g_fTimeOut > 0.0){
            g_iAnimTimeout=llGetUnixTime()+(integer)g_fTimeOut;
        } else {
            g_iAnimTimeout=0;
        }
        refreshTimer();
    }
    timer()
    {
        refreshTimer();
    }
    dataserver(key kID, string sData)
    {
        if (sData == EOF){
            iCardComplete++;
        } else {
            list lParams = llParseString2List(sData, ["|"], []);
            //don't try to add empty or misformatted lines
            //valid if length = 4 or 5 (since text is optional) and anims exist
            integer iLength = llGetListLength(lParams);
            if (iLength == 4 || iLength == 5){
                if (!llGetInventoryType(llList2String(lParams, 1)) == INVENTORY_ANIMATION){
                    llOwnerSay(CARD1 + " line " + (string)g_iLine1 + ": animation '" + llList2String(lParams, 1) + "' is not present.  Skipping.");
                } else if (!llGetInventoryType(llList2String(lParams, 2)) == INVENTORY_ANIMATION){
                    llOwnerSay(CARD1 + " line " + (string)g_iLine2 + ": animation '" + llList2String(lParams, 2) + "' is not present.  Skipping.");
                } else {
                    integer iIndex = llListFindList(g_lAnimCmds, llList2List(lParams, 0, 0));
                    if (iIndex != -1){
                        g_lAnimCmds=llDeleteSubList(g_lAnimCmds,iIndex,iIndex);
                        g_lAnimSettings=llDeleteSubList(g_lAnimSettings,iIndex*4,iIndex*4+3);
                    }
                    //add cmd, and text
                    g_lAnimCmds += llList2List(lParams, 0, 0);
                    //anim names, offset,
                    g_lAnimSettings += llList2List(lParams, 1, 3);
                    //text.  this has to be done by casting to string instead of list2list, else lines that omit text will throw off the stride
                    g_lAnimSettings += [llList2String(lParams, 4)];
                    //Debug(llDumpList2String(g_lAnimCmds, ","));
                    //Debug(llDumpList2String(g_lAnimSettings, ","));
                }
            }
            if ( iCardComplete <2){
                if (kID == g_kDataID1){
                    g_iLine1++;
                    g_kDataID1 = llGetNotecardLine(CARD1, g_iLine1);
                } else if (kID == g_kDataID2){
                    g_iLine2++;
                    g_kDataID2 = llGetNotecardLine(CARD2, g_iLine2);
                }
            }
        }
    }
    changed(integer iChange)
    {
        if (iChange & CHANGED_INVENTORY)
        {
            if (llGetInventoryKey(CARD1) != g_kCardID1)
            {
                //because notecards get new uuids on each save, we can detect if the notecard has changed by seeing if the current uuid is the same as the one we started with
                //just switch states instead of restarting, so we can preserve any settings we may have gotten from db
                state default;
            }
            if (llGetInventoryKey(CARD2) != g_kCardID1)
            {
                state default;
            }
        }
    }
    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            key kID = llGetPermissionsKey();
            //Debug("changed anim permissions\nPerm ID="+(string)kID+"g_kPartner="+(string)g_kPartner);
            if (kID == g_kPartner)
            {
                g_iPermissionTimeout=0;
                MoveToPartner();
            }
            else
            {
                Notify(kID, "Sorry, but the request timed out.",TRUE);
            }
        }
    }
}
