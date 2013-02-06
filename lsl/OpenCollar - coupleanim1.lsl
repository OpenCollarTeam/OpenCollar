//OpenCollar - coupleanim1
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.
//coupleanim1
string g_sParentMenu = "Animations";
string g_sSubMenu = "Couples";
string UPMENU = "^";
//string MORE = ">";
key g_kAnimmenu;
key g_kPart;
string g_sSensorMode;//will be set to "chat" or "menu" later
list g_lPartners;
integer g_iMenuTimeOut = 60;

key g_kWearer;

string STOP_COUPLES = "Stop";
string TIME_COUPLES = "Time";

integer g_iLine;
key g_kDataID;
string CARD1 = "coupleanims";
string CARD2 = "coupleanims_personal";
string g_sNoteCard2Read;

list g_lAnimCmds;//1-strided list of strings that will trigger
list g_lAnimSettings;//4-strided list of subAnim|domAnim|offset|text, running parallel to g_lAnimCmds,
//such that g_lAnimCmds[0] corresponds to g_lAnimSettings[0:3], and g_lAnimCmds[1] corresponds to g_lAnimSettings[4:7], etc

key g_kCardID1;//used to detect whether coupleanims card has changed
key g_kCardID2;
float g_fRange = 10.0;//only scan within this range for anim partners

vector UNIT_VECTOR = <1.0, 0.0, 0.0>;
float g_fWalkingDistance = 1.0; // How close to try to get to the target point while walking, in meters
float g_fWalkingTau = 1.5; // how hard to push me toward partner while walking
float g_fAlignTau = 0.05; // how hard to push me toward partner while aligning
float g_fAlignDelay = 0.6; // how long to let allignment settle (in seconds)

key g_kCmdGiver; // id of the avatar having issued the last command
integer g_iCmdAuth; // auth level of that avatar
integer g_iCmdIndex;
string g_sTmpName;
key g_kPartner;
string g_sPartnerName;
float g_fTimeOut = 20.0;//duration of anim
//i dont think this flag is needed at all
integer g_iTargetID; // remember the walk target to delete
string g_sDBToken = "coupletime";
string g_sSubAnim;
string g_sDomAnim;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;

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
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer ANIM_START = 7000;//send this with the name of an anim in the string part of the message to play the anim
integer ANIM_STOP = 7001;//send this with the name of an anim in the string part of the message to stop the anim
integer CPLANIM_PERMREQUEST = 7002;//id should be av's key, str should be cmd name "hug", "kiss", etc
integer CPLANIM_PERMRESPONSE = 7003;//str should be "1" for got perms or "0" for not.  id should be av's key
integer CPLANIM_START = 7004;//str should be valid anim name.  id should be av
integer CPLANIM_STOP = 7005;//str should be valid anim name.  id should be av

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;



Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    //key generation
    //just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string sOut;
    integer n;
    for (n = 0; n < 8; ++n)
    {
        integer iIndex = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        sOut += llGetSubString( "0123456789abcdef", iIndex, iIndex);
    }
    key kID = (sOut + "-0000-0000-0000-000000000000");
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
        + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

PartnerMenu(key kID, list kAvs, integer iAuth)
{
    string sPrompt = "Pick a partner.";
    g_kPart=Dialog(kID, sPrompt, kAvs, [UPMENU],0, iAuth);
}

CoupleAnimMenu(key kID, integer iAuth)
{
    string sPrompt = "Pick an animation to play.";
    list lButtons = g_lAnimCmds;//we're limiting this to 9 couple anims then
    lButtons += [TIME_COUPLES, STOP_COUPLES];
    g_kAnimmenu=Dialog(kID, sPrompt, lButtons, [UPMENU],0, iAuth);
}

TimerMenu(key kID, integer iAuth)
{
    string sPrompt = "Pick an time to play.";
    list lButtons = ["10", "20", "30"];
    lButtons += ["40", "50", "60"];
    lButtons += ["90", "120", "endless"];
    g_kPart=Dialog(kID, sPrompt, lButtons, [UPMENU],0, iAuth);
}


integer AnimExists(string sAnim)
{
    return llGetInventoryType(sAnim) == INVENTORY_ANIMATION;
}

integer ValidLine(list lParams)
{
    //valid if length = 4 or 5 (since text is optional) and anims exist
    integer iLength = llGetListLength(lParams);
    if (iLength < 4)
    {
        return FALSE;
    }
    else if (iLength > 5)
    {
        return FALSE;
    }
    else if (!AnimExists(llList2String(lParams, 1)))
    {
        llOwnerSay(CARD1 + " line " + (string)g_iLine + ": animation '" + llList2String(lParams, 1) + "' is not present.  Skipping.");
        return FALSE;
    }
    else if (!AnimExists(llList2String(lParams, 2)))
    {
        llOwnerSay(CARD1 + " line " + (string)g_iLine + ": animation '" + llList2String(lParams, 2) + "' is not present.  Skipping.");
        return FALSE;
    }
    else
    {
        return TRUE;
    }
}

integer StartsWith(string sHayStack, string sNeedle) // http://wiki.secondlife.com/wiki/llSubStringIndex
{
    return llDeleteSubString(sHayStack, llStringLength(sNeedle), -1) == sNeedle;
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

PrettySay(string sText)
{
    string sName = llGetObjectName();
    list lWords = llParseString2List(sText, [" "], []);
    llSetObjectName(llList2String(lWords, 0));
    lWords = llDeleteSubList(lWords, 0, 0);
    llSay(0, "/me " + llDumpList2String(lWords, " "));
    llSetObjectName(sName);
}

string FirstName(string sName)
{
    return llList2String(llParseString2List(sName, [" "], []), 0);
}

//added to stop eventual still going animations
StopAnims()
{
    if (AnimExists(g_sSubAnim))
    {
        llMessageLinked(LINK_SET, ANIM_STOP, g_sSubAnim, NULL_KEY);
    }

    if (AnimExists(g_sDomAnim))
    {
        llMessageLinked(LINK_SET, CPLANIM_STOP, g_sDomAnim, NULL_KEY);
    }

    g_sSubAnim = "";
    g_sDomAnim = "";
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

AlignWithPartner() {
    float offset = 10.0;
    if (g_iCmdIndex != -1) offset = (float)llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 2);
    list partnerDetails = llGetObjectDetails(g_kPartner, [OBJECT_POS, OBJECT_ROT]);
    vector partnerPos = llList2Vector(partnerDetails, 0);
    rotation partnerRot = llList2Rot(partnerDetails, 1);
    vector myPos = llList2Vector(llGetObjectDetails(llGetOwner(), [OBJECT_POS]), 0);

    vector target = partnerPos + (UNIT_VECTOR * partnerRot * offset); // target is <offset> meters in front of the partner
    target.z = myPos.z; // ignore height differences
    llMoveToTarget(target, g_fAlignTau);
    llSleep(g_fAlignDelay);
    llStopMoveToTarget();
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD)
        {//card is present, start reading
            g_kCardID1 = llGetInventoryKey(CARD1);

            //re-initialize just in case we're switching from other state
            g_iLine = 0;
            g_lAnimCmds = [];
            g_lAnimSettings = [];
            g_sNoteCard2Read = CARD1;
            g_kDataID = llGetNotecardLine(g_sNoteCard2Read, g_iLine);
        }
        else
        {
            //card isn't present, switch to nocard state
        }
    }
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == g_sDBToken)
            {
                g_fTimeOut = (float)sValue;
            }
        }
    }

    dataserver(key kID, string sData)
    {
        if (kID == g_kDataID)
        {
            if (sData == EOF)
            {
                if(g_sNoteCard2Read == CARD1)
                {
                    if(llGetInventoryType(CARD2) == INVENTORY_NOTECARD)
                    {
                        g_kCardID2 = llGetInventoryKey(CARD2);
                        g_sNoteCard2Read = CARD2;
                        g_iLine = 0;
                        g_kDataID = llGetNotecardLine(g_sNoteCard2Read, g_iLine);
                    }
                    else
                    {
                        //no Mycoupleanims notecard so...
                        state ready;
                    }
                }
                else
                {
                    Debug("done reading card");
                    state ready;
                }
            }
            else
            {
                list lParams = llParseString2List(sData, ["|"], []);
                //don't try to add empty or misformatted lines
                if (ValidLine(lParams))
                {
                    integer iIndex = llListFindList(g_lAnimCmds, llList2List(lParams, 0, 0));
                    if(iIndex == -1)
                    {
                        //add cmd, and text
                        g_lAnimCmds += llList2List(lParams, 0, 0);
                        //anim names, offset,
                        g_lAnimSettings += llList2List(lParams, 1, 3);
                        //text.  this has to be done by casting to string instead of list2list, else lines that omit text will throw off the stride
                        g_lAnimSettings += [llList2String(lParams, 4)];
                        Debug(llDumpList2String(g_lAnimCmds, ","));
                        Debug(llDumpList2String(g_lAnimSettings, ","));
                    }
                    else
                    {
                        iIndex = iIndex * 4;
                        //add cmd, and text
                        //g_lAnimCmds = llListReplaceList(g_lAnimCmds, llList2List(lParams, 0, 0), iIndex, iIndex);
                        //anim names, offset,
                        g_lAnimSettings = llListReplaceList(g_lAnimSettings, llList2List(lParams, 1, 3), iIndex, iIndex + 2);
                        //text.  this has to be done by casting to string instead of list2list, else lines that omit text will throw off the stride
                        g_lAnimSettings = llListReplaceList(g_lAnimSettings,[llList2String(lParams, 4)], iIndex + 3, iIndex + 3);
                        Debug(llDumpList2String(g_lAnimCmds, ","));
                        Debug(llDumpList2String(g_lAnimSettings, ","));
                    }
                }
                g_iLine++;
                g_kDataID = llGetNotecardLine(g_sNoteCard2Read, g_iLine);
            }
        }
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
}

state nocard
{
    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            if (llGetInventoryType(CARD1) == INVENTORY_NOTECARD)
            {//card is now present, switch to default state and read it.
                state default;
            }
            if (llGetInventoryType(CARD2) == INVENTORY_NOTECARD)
            {//card is now present, switch to default state and read it.
                state default;
            }
        }
    }

    on_rez(integer iParam)
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
}

state ready
{    //leaving this here due to delay of nc reading
    state_entry()
    {
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
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
            if (tmpiIndex != -1)
            {
                g_iCmdIndex = tmpiIndex;
                Debug(sCommand);
                //we got an anim command.
                //else set partner to commander
                if (llGetListLength(lParams) > 1)
                {
                    //we've been given a name of someone to kiss.  scan for it
                    g_sTmpName = llDumpList2String(llList2List(lParams, 1, -1), " ");//this makes it so we support even full names in the command
                    g_sSensorMode = "chat";
                    llSensor("", NULL_KEY, AGENT, g_fRange, PI);
                }
                else
                {
                    //no name given.  if commander is not sub, then treat commander as partner
                    if (kID == g_kWearer)
                    {
                        llMessageLinked(LINK_SET, POPUP_HELP, "Error: you didn't give the name of the person you want to animate.  To " + sCommand + " Nandana Singh, for example, you could say /_CHANNEL__PREFIX" + sCommand + " nan", g_kWearer);
                    }
                    else
                    {
                        g_kPartner = g_kCmdGiver;
                        g_sPartnerName = llKey2Name(g_kPartner);
                        //added to stop eventual still going animations
                        StopAnims();
                        llMessageLinked(LINK_SET, CPLANIM_PERMREQUEST, sCommand, g_kPartner);
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
        else if (iNum == CPLANIM_PERMRESPONSE)
        {
            if (sStr == "1")
            {
                MoveToPartner();
            }
            else if (sStr == "0")
            {
                //we did not get permission to animate
                llInstantMessage(g_kCmdGiver, g_sPartnerName + " did not accept your " + llList2String(g_lAnimCmds, g_iCmdIndex) + ".");
            }
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if(sToken == g_sDBToken)
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
                    TimerMenu(kAv, iAuth);
                }
                else
                {
                    integer iIndex = llListFindList(g_lAnimCmds, [sMessage]);
                    if (iIndex != -1)
                    {
                        g_kCmdGiver = kAv; g_iCmdAuth = iAuth;
                        g_iCmdIndex = iIndex;
                        g_sSensorMode = "menu";
                        llSensor("", NULL_KEY, AGENT, g_fRange, PI);
                    }
                }
            }
            else if (kID == g_kPart)
            {
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
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + (string)g_fTimeOut, NULL_KEY);
                    Notify (kAv, "Couple Anmiations play now for " + (string)llRound(g_fTimeOut) + " seconds.",TRUE);
                    CoupleAnimMenu(kAv, iAuth);
                }
                else if (sMessage == "endless")
                {
                    g_fTimeOut = 0.0;
                    llMessageLinked(LINK_SET, LM_SETTING_SAVE, g_sDBToken + "=" + (string)g_fTimeOut, NULL_KEY);
                    Notify (kAv, "Couple Anmiations play now for ever. Use the menu or type *stopcouples to stop them again.",TRUE);
                }
                else
                {
                    integer iIndex = llListFindList(g_lPartners, [sMessage]);
                    if (iIndex != -1)
                    {
                        g_kPartner = llList2String(g_lPartners, iIndex - 1);
                        g_sPartnerName = sMessage;
                        //added to stop eventual still going animations
                        StopAnims();
                        string cmdName = llList2String(g_lAnimCmds, g_iCmdIndex);
                        llMessageLinked(LINK_SET, CPLANIM_PERMREQUEST, cmdName, g_kPartner);
                        llOwnerSay("Offering to " + cmdName + " " + g_sPartnerName + ".");
                    }
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
            AlignWithPartner();
            //we've arrived.  let's play the anim and spout the text
            g_sSubAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4);
            g_sDomAnim = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 1);
            llMessageLinked(LINK_SET, ANIM_START, g_sSubAnim, NULL_KEY);
            llMessageLinked(LINK_SET, CPLANIM_START, g_sDomAnim, NULL_KEY);

            string text = llList2String(g_lAnimSettings, g_iCmdIndex * 4 + 3);
            if (text != "")
            {
                text = StrReplace(text, "_SELF_", FirstName(llKey2Name(g_kWearer)));
                text = StrReplace(text, "_PARTNER_", FirstName(g_sPartnerName));
                PrettySay(text);
            }
            llSetTimerEvent(g_fTimeOut);
        }

        timer()
        {
            StopAnims();
            llSetTimerEvent(0.0);
        }

        sensor(integer iNum)
        {
            Debug(g_sSensorMode);
            if (g_sSensorMode == "menu")
            {
                g_lPartners = [];
                list kAvs;//just used for menu building
                integer n;
                for (n = 0; n < iNum; n++)
                {
                    g_lPartners += [llDetectedKey(n), llDetectedName(n)];
                    kAvs += [llDetectedName(n)];
                }
                PartnerMenu(g_kCmdGiver, kAvs, g_iCmdAuth);
            }
            else if (g_sSensorMode == "chat")
            {
                //loop through detected avs, seeing if one matches g_sTmpName
                integer n;
                for (n = 0; n < iNum; n++)
                {
                    string sName = llDetectedName(n);
                    if (StartsWith(llToLower(sName), llToLower(g_sTmpName)) || llToLower(sName) == llToLower(g_sTmpName))
                    {
                        g_kPartner = llDetectedKey(n);
                        g_sPartnerName = sName;
                        string sCommand = llList2String(g_lAnimCmds, g_iCmdIndex);
                        //added to stop eventual still going animations
                        StopAnims();
                        llMessageLinked(LINK_SET, CPLANIM_PERMREQUEST, sCommand, g_kPartner);
                        llOwnerSay("Offering to " + sCommand + " " + g_sPartnerName + ".");
                        return;
                    }
                }
                //if we got to this point, then no one matched
                llInstantMessage(g_kCmdGiver, "Could not find '" + g_sTmpName + "' to " + llList2String(g_lAnimCmds, g_iCmdIndex) + ".");
            }
        }

        no_sensor()
        {
            if (g_sSensorMode == "chat")
            {
                llInstantMessage(g_kCmdGiver, "Could not find '" + g_sTmpName + "' to " + llList2String(g_lAnimCmds, g_iCmdIndex) + ".");
            }
            else if (g_sSensorMode == "menu")
            {
                llInstantMessage(g_kCmdGiver, "Could not find anyone nearby to " + llList2String(g_lAnimCmds, g_iCmdIndex) + ".");
                CoupleAnimMenu(g_kCmdGiver, g_iCmdAuth);
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

    }