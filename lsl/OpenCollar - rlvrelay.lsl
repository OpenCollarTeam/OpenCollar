//OpenCollar - rlvrelay
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

integer RELAY_CHANNEL = -1812221819;
integer g_iRlvListener;

//MESSAGE MAP
//integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
//integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
//integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507; // now will be used from rlvrelay to rlvmain, for ping only
integer COMMAND_SAFEWORD = 510;
integer COMMAND_RELAY_SAFEWORD = 511;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
                            //str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string g_sParentMenu = "RLV";
string g_sSubMenu = "Relay";

string UPMENU = "^";

string ALL = "*All*";

key g_kWearer;

key g_kMenuID;
key g_kMinModeMenuID;
key g_kAuthMenuID;
key g_kListMenuID;
key g_kListID;

integer g_iGarbageRate = 180; //garbage collection rate

list g_lSources=[];
//list users=[];
list g_lTempWhiteList=[];
list g_lTempBlackList=[];
list g_lTempUserWhiteList=[];
list g_lTempUserBlackList=[];
list g_lObjWhiteList=[];
list g_lObjBlackList=[];
list g_lAvWhiteList=[]; // keys stored as string since strings is what you get when restoring settings
list g_lAvBlackList=[]; // same here (this fixes issue 1253)
list g_lObjWhiteListNames=[];
list g_lObjBlackListNames=[];
list g_lAvWhiteListNames=[];
list g_lAvBlackListNames=[];

integer g_iRLV=FALSE;
list g_lQueue=[];
integer g_iQApproxSize; //Approximation of the queue size (in bytes)
integer QSTRIDES=3;
integer g_iListener=0;
integer g_iAuthPending = FALSE;
integer g_iRecentSafeword;
string g_sListType;

//relay specific message map
integer CMD_ADDSRC = 11;
integer CMD_REMSRC = 12;

string g_sDBToken="relay";

//collar owners, secowners and blacklist caching
//string g_sOwnerssToken = "owner";
//string g_sSecOwnerssToken = "secowners";
//string g_sBlackListsToken = "blacklist";

list g_lCollarOwnersList;
list g_lCollarSecOwnersList;
list g_lCollarBlackList;


//settings
integer g_iMinBaseMode = 0;
integer g_iMinSafeMode = 1;
integer g_iMinLandMode = 0;
integer g_iMinPlayMode = 0;
integer g_iBaseMode = 2;
integer g_iSafeMode = 1;
integer g_iLandMode = 1;
integer g_iPlayMode = 0;

key g_kDebugRcpt = NULL_KEY; // recipient key for relay chat debugging (useful since you cannot eavesdrop llRegionSayTo)



// Sanitizes a key coming from the outside, so that only valid
// keys are returned, and invalid ones are mapped to NULL_KEY
key SanitizeKey(string uuid)
{
    if ((key)uuid) return llToLower(uuid);
    return NULL_KEY;
}

string Mode2String(integer iMin)
{
    string sOut;
    if (iMin)
    { 
        if (!g_iMinBaseMode) sOut+="off";
        else if (g_iMinBaseMode==1) sOut+="restricted";
        else if (g_iMinBaseMode==2) sOut+="ask";
        else if (g_iMinBaseMode==3) sOut+="auto";
        if (!g_iMinSafeMode) sOut+=", without safeword";
        else sOut+=", with safeword";
        if (g_iMinPlayMode) sOut+=", playful";
        else sOut+=", not playful";
        if (g_iMinLandMode) sOut+=", landowner trusted.";
        else sOut+=", landowner not trusted.";
    }
    else
    { 
        if (!g_iBaseMode) sOut+="off";
        else if (g_iBaseMode==1) sOut+="restricted";
        else if (g_iBaseMode==2) sOut+="ask";
        else if (g_iBaseMode==3) sOut+="auto";
        if (!g_iSafeMode) sOut+=", without safeword";
        else sOut+=", with safeword";
        if (g_iPlayMode) sOut+=", playful";
        else sOut+=", not playful";
        if (g_iLandMode) sOut+=", landowner trusted.";
        else sOut+=", landowner not trusted.";
    }
    return sOut;
}

notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) {
        llOwnerSay(sMsg);
    } else {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) {
            llOwnerSay(sMsg);
        }
    }
}

SaveSettings()
{
    string sNewSettings=g_sDBToken+"=mode:"
        +(string)(512 * g_iMinPlayMode + 256 * g_iMinLandMode + 128 * g_iMinSafeMode + 32 * g_iMinBaseMode
        + 16 * g_iPlayMode + 8 * g_iLandMode + 4 * g_iSafeMode + g_iBaseMode);
//    if ( g_lObjWhiteList != [] ) sNewSettings+=",objwhitelist:"+llDumpList2String(g_lObjWhiteList,"/");
//    if ( g_lObjBlackList != [] ) sNewSettings+=",objblacklist:"+llDumpList2String(g_lObjBlackList,"/");
    if ( g_lAvWhiteList != [] ) sNewSettings+=",avwhitelist:"+llDumpList2String(g_lAvWhiteList,"/")
        +",avwhitelistnames:"+llDumpList2String(g_lAvWhiteListNames,"/");
    if ( g_lAvBlackList != [] ) sNewSettings+=",avblacklist:"+llDumpList2String(g_lAvBlackList,"/")
        +",avblacklistnames:"+llDumpList2String(g_lAvBlackListNames,"/");
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, sNewSettings, NULL_KEY);
}

UpdateSettings(string sSettings)
{
    list lArgs = llParseString2List(sSettings,[","],[]);
    integer i;
    for (i=0;i<(lArgs!=[]);++i)
    {
        list setting=llParseString2List(llList2String(lArgs,i),[":"],[]);
        string var=llList2String(setting,0);
        list vals=llParseString2List(llList2String(setting,1),["/"],[]);
        if (var=="mode")
        {
            integer iMode=llList2Integer(setting,1);
            g_iBaseMode = iMode        & 3;
            g_iSafeMode = (iMode >> 2) & 1;
            g_iLandMode = (iMode >> 3) & 1;
            g_iPlayMode = (iMode >> 4) & 1;
            g_iMinBaseMode = (iMode >> 5) & 3;
            g_iMinSafeMode = (iMode >> 7) & 1;
            g_iMinLandMode = (iMode >> 8) & 1;
            g_iMinPlayMode = (iMode >> 9) & 1;
        }
//        else if (var=="objwhitelist") g_lObjWhiteList=vals;
//        else if (var=="objblacklist") g_lObjBlackList=vals;
//        else if (var=="objwhitelistnames") g_lObjWhiteListNames=vals;
//        else if (var=="objblacklistnames") g_lObjBlackListNames=vals;
        else if (var=="avwhitelist") g_lAvWhiteList=vals;
        else if (var=="avblacklist") g_lAvBlackList=vals;
        else if (var=="avwhitelistnames") g_lAvWhiteListNames=vals;
        else if (var=="avblacklistnames") g_lAvBlackListNames=vals;
    }
}


integer Auth(key object, key user)
{
    integer iAuth=1;
    key kOwner = llGetOwnerKey(object);
    //object auth
    integer iSourceIndex=llListFindList(g_lSources,[object]);
    if (~iSourceIndex) {}
    else if (~llListFindList(g_lTempBlackList+g_lObjBlackList,[object])) return -1;
    else if (~llListFindList(g_lAvBlackList,[(string)kOwner])) return -1;
    else if (~llListFindList(g_lCollarBlackList,[(string)kOwner])) return -1;
    else if (g_iBaseMode==3) {}
    else if (g_iLandMode && llGetOwnerKey(object)==llGetLandOwnerAt(llGetPos())) {}
    else if (~llListFindList(g_lTempWhiteList+g_lObjWhiteList,[object])) {}
    else if (~llListFindList(g_lAvWhiteList,[(string)kOwner])) {}
    else if (~llListFindList(g_lCollarOwnersList+g_lCollarSecOwnersList,[(string)kOwner])) {}
//    else if (g_iBaseMode==1) return -1; we should not block playful in restricted mode
    else iAuth=0;
    //user auth
    if (user)
    {
//        if (~iSource_iIndex&&user==(key)llList2String(users,iSource_iIndex)) {}
//        else if (user==g_kLastUser) {}
//        else
        if (~llListFindList(g_lAvBlackList+g_lTempUserBlackList,[user])) return -1;
        else if (~llListFindList(g_lCollarBlackList,[(string)user])) return -1;
        else if (g_iBaseMode == 3) {}
        else if (~llListFindList(g_lAvWhiteList+g_lTempUserWhiteList,[user])) {}
        else if (~llListFindList(g_lCollarOwnersList+g_lCollarSecOwnersList,[(string)user])) {}
//        else if (g_iBaseMode==1) return -1;
        else return 0;
    }

    return iAuth;
}


Dequeue()
{
    string sCommand;
    string sCurIdent;
    key kCurID;
    while (sCommand=="")
    {
        if (g_lQueue==[])
        {
            llSetTimerEvent(g_iGarbageRate);
            g_iQApproxSize = 0;
            return;
        }
        sCurIdent=llList2String(g_lQueue,0);
        kCurID=llList2String(g_lQueue,1);
        sCommand=HandleCommand(sCurIdent,kCurID,llList2String(g_lQueue,2),FALSE);
        g_lQueue = llDeleteSubList(g_lQueue, 0, QSTRIDES-1);
    }
    g_lQueue=[sCurIdent,kCurID,sCommand]+g_lQueue;
    list lButtons=["Yes","No","Trust Object","Ban Object","Trust Owner","Ban Owner"];
    string sOwner=llKey2Name(llGetOwnerKey(kCurID));
    if (sOwner!="") sOwner= ", owned by "+sOwner+",";
    string sPrompt=llKey2Name(kCurID)+sOwner+" wants to control your viewer.";
    if (llGetSubString(sCommand,0,6)=="!x-who/")
    {
        lButtons+=["Trust User","Ban User"];
        sPrompt+="\n"+llKey2Name(llGetSubString(sCommand,7,42))+" is currently using this device.";
    }
    sPrompt+="\nDo you want to allow this?";
    g_iAuthPending = TRUE;
    g_kAuthMenuID = Dialog(g_kWearer, sPrompt, lButtons, [], 0, COMMAND_WEARER); // should be enough to dequeue...
}


string HandleCommand(string sIdent, key kID, string sCom, integer iAuthed)
{
    list lCommands=llParseString2List(sCom,["|"],[]);
    sCom = llList2String(lCommands, 0);
    integer iGotWho = FALSE; // has the user been specified up to now?
    key kWho;
    integer i;
    for (i=0;i<(lCommands!=[]);++i)
    {
        sCom = llList2String(lCommands,i);
        list lSubArgs = llParseString2List(sCom,["="],[]);
        string sVal = llList2String(lSubArgs,1);
        string sAck = "ok";
        if (sCom == "!release" || sCom == "@clear") llMessageLinked(LINK_SET,RLV_CMD,"clear",kID);
        else if (sCom == "!version") sAck = "1100";
        else if (sCom == "!implversion") sAck = "OpenCollar 3.7";
        else if (sCom == "!x-orgversions") sAck = "ORG=0003/who=001";
        else if (llGetSubString(sCom,0,6)=="!x-who/") {kWho = SanitizeKey(llGetSubString(sCom,7,42)); iGotWho=TRUE;}
        else if (llGetSubString(sCom,0,0) == "!") sAck = "ko"; // ko unknown meta-commands
        else if (llGetSubString(sCom,0,0) != "@")
        {
            llOwnerSay("Bad RLV relay command from "+llKey2Name(kID)+". \nCommand: "+sIdent+","+(string)g_kWearer+","+llDumpList2String(lCommands,"|")+"\nFaulty subcommand: "+sCom+"\nPlease report to the maker of this device."); //added this after issue 984
            //if (iIsWho) return llList2String(lCommands,0)+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            //else return llDumpList2String(llList2List(lCommands,i,-1),"|");
            //better try to execute the rest of the command, right?
            sAck=""; //not ko'ing as some old bug in chorazin cages would make them go wrong. Otherwise "ko" looks closer in spirit to the relay spec. (issue 514)
        }//probably an ill-formed command, not answering
        else if ((!llSubStringIndex(sCom,"@version"))||(!llSubStringIndex(sCom,"@get"))||(!llSubStringIndex(sCom,"@findfolder"))) //(IsChannelCmd(sCom))
        {
            if ((integer)sVal) llMessageLinked(LINK_SET,RLV_CMD, llGetSubString(sCom,1,-1), kID); //now with RLV 1.23, negative channels can also be used
            else sAck="ko";
        }
        else if (g_iPlayMode&&llGetSubString(sCom,0,0)=="@"&&sVal!="n"&&sVal!="add")
            llMessageLinked(LINK_SET,RLV_CMD, llGetSubString(sCom,1,-1), kID);
        else if (!iAuthed)
        {
            if (iGotWho) return "!x-who/"+(string)kWho+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            else return llDumpList2String(llList2List(lCommands,i,-1),"|");
        }
        else if ((lSubArgs!=[])==2)
        {
            string sBehav=llGetSubString(llList2String(lSubArgs,0),1,-1);
            if (sVal=="force"||sVal=="n"||sVal=="add"||sVal=="y"||sVal=="rem"||sBehav=="clear")
            {
                llMessageLinked(LINK_SET,RLV_CMD,sBehav+"="+sVal,kID);
            }
            else sAck="ko";
        }
        else
        {
            llOwnerSay("Bad RLV relay command from "+llKey2Name(kID)+". \nCommand: "+sIdent+","+(string)g_kWearer+","+llDumpList2String(lCommands,"|")+"\nFaulty subcommand: "+sCom+"\nPlease report to the maker of this device."); //added this after issue 984
            //if (iIsWho) return llList2String(lCommands,0)+"|"+llDumpList2String(llList2List(lCommands,i,-1),"|");
            //else return llDumpList2String(llList2List(lCommands,i,-1),"|");
            //better try to execute the rest of the command, right?
            sAck=""; //not ko'ing as some old bug in chorazin cages would make them go wrong. Otherwise "ko" looks closer in spirit to the relay spec. (issue 514)
        }//probably an ill-formed command, not answering
        if (sAck) sendrlvr(sIdent, kID, sCom, sAck);
    }
    return "";
}

sendrlvr(string sIdent, key kID, string sCom, string sAck)
{
    llRegionSayTo(kID, RELAY_CHANNEL, sIdent+","+(string)kID+","+sCom+","+sAck);
    if (g_kDebugRcpt == g_kWearer) llOwnerSay("From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);    
    else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt, DEBUG_CHANNEL, "From relay: "+sIdent+","+(string)kID+","+sCom+","+sAck);    
}

SafeWord()
{
    if (g_iSafeMode)
    {
        llMessageLinked(LINK_SET, COMMAND_RELAY_SAFEWORD, "","");
        notify(g_kWearer, "You have safeworded",TRUE);
        g_lTempBlackList=[];
        g_lTempWhiteList=[];
        g_lTempUserBlackList=[];
        g_lTempUserWhiteList=[];
        integer i;
        for (i=0;i<(g_lSources!=[]);++i)
        {
            sendrlvr("release", llList2Key(g_lSources, i), "!release", "ok");
        }
        g_lSources=[];
        g_iRecentSafeword = TRUE;
        refreshRlvListener();
        llSetTimerEvent(30.);
    }
    else
    {
        notify(g_kWearer, "Sorry, safewording is disabled now!", TRUE);
    }
}

//----Menu functions section---//
Menu(key kID, integer iAuth)
{
    string sPrompt = "\nCurrent mode is: " + Mode2String(FALSE);
    list lButtons = llDeleteSubList(["Off", "Restricted", "Ask", "Auto"],g_iBaseMode,g_iBaseMode);
    if (g_lSources != []) lButtons = llDeleteSubList(lButtons,0,0);
    if (g_iPlayMode) lButtons+=["(*)Playful"];
    else lButtons+=["( )Playful"];
    if (g_iLandMode) lButtons+=["(*)Land"];
    else lButtons+=["( )Land"];
    if (g_lSources!=[])
    {
        sPrompt+="\nCurrently grabbed by "+(string)(g_lSources!=[])+" object";
        if (g_lSources==[1]) sPrompt+="."; // Note: only list LENGTH is compared here
        else sPrompt+="s.";
        lButtons+=["Grabbed by"];
        if (g_iSafeMode) lButtons+=["Safeword"];
    }
    else if (kID == g_kWearer)
    {
        if (g_iSafeMode) lButtons+=["(*)Safeword"];
        else lButtons+=["( )Safeword"];
    }
    if (g_lQueue!=[])
    {
        sPrompt+="\nYou have pending requests.";
        lButtons+=["Pending"];
    }
    lButtons+=["Access Lists", "MinMode", "Help"];
    sPrompt+="\n\nMake a choice:";
    g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

MinModeMenu(key kID, integer iAuth)
{
    list lButtons = llDeleteSubList(["Off", "Restricted", "Ask", "Auto"],g_iMinBaseMode,g_iMinBaseMode);
    string sPrompt = "\nCurrent minimal authorized relay mode is: " + Mode2String(TRUE);
    if (g_iMinPlayMode) lButtons+=["(*)Playful"];
    else lButtons+=["( )Playful"];
    if (g_iMinLandMode) lButtons+=["(*)Land"];
    else lButtons+=["( )Land"];
    if (g_iMinSafeMode) lButtons+=["(*)Safeword"];
    else lButtons+=["( )Safeword"];
    sPrompt+="\n\nChoose a new minimal mode the wearer won't be allowed go under.\n(owner only)";
    g_kMinModeMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

ListsMenu(key kID, integer iAuth)
{
    string sPrompt="What list do you want to remove items from?";
    list lButtons=["Trusted Object","Banned Object","Trusted Avatar","Banned Avatar",UPMENU];
    sPrompt+="\n\nMake a choice:";
    g_kListMenuID = Dialog(kID, sPrompt, lButtons, [], 0, iAuth);
}

PListsMenu(key kID, string sMsg, integer iAuth)
{
    list lOList;
    list lOListNames;
    string sPrompt;
    if (sMsg==UPMENU)
    {
        Menu(kID, iAuth);
        return;
    }
    else if (sMsg=="Trusted Object")
    {
        lOList=g_lObjWhiteList;
        lOListNames=g_lObjWhiteListNames;
        sPrompt="What object do you want to stop trusting?";
        if (lOListNames == []) sPrompt+="\n\nNo object in list.";
        else  sPrompt+="\n\nObserve chat for the list.";
    }
    else if (sMsg=="Banned Object")
    {
        lOList=g_lObjBlackList;
        lOListNames=g_lObjBlackListNames;
        sPrompt="What object do you want not to ban anymore?";
        if ( lOListNames == []) sPrompt+="\n\nNo object in list.";
        else sPrompt+="\n\nObserve chat for the list.";
    }
    else if (sMsg=="Trusted Avatar")
    {
        lOList=g_lAvWhiteList;
        lOListNames=g_lAvWhiteListNames;
        sPrompt="What avatar do you want to stop trusting?";
        if (lOListNames == []) sPrompt+="\n\nNo avatar in list.";
        else sPrompt+="\n\nObserve chat for the list.";
    }
    else if (sMsg=="Banned Avatar")
    {
        lOList=g_lAvBlackList;
        lOListNames=g_lAvBlackListNames;
        sPrompt="What avatar do you want not to ban anymore?";
        if (lOListNames == []) sPrompt+="\n\nNo avatar in list.";
        else sPrompt+="\n\nObserve chat for the list.";
    }
    else return;
    g_sListType=sMsg;

    list lButtons=[ALL];
    integer i;
    for (i=0;i<(lOList!=[]);++i)
    {
        lButtons+=(string)(i+1);
        llInstantMessage(kID, (string)(i+1)+": "+llList2String(lOListNames,i)+", "+llList2String(lOList,i));
    }
    sPrompt+="\n\nMake a choice:";
    g_kListID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
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

RemListItem(string sMsg, integer iAuth)
{
    integer i=((integer) sMsg) -1;
    if (g_sListType=="Banned Avatar")
    {
        if (sMsg==ALL) {g_lAvBlackList=[];g_lAvBlackListNames=[];return;}
        if  (i<(g_lAvBlackList!=[]))
        { 
            g_lAvBlackList=llDeleteSubList(g_lAvBlackList,i,i);
            g_lAvBlackListNames=llDeleteSubList(g_lAvBlackListNames,i,i);
        }
    }
    else if (g_sListType=="Banned Object")
    {
        if (sMsg==ALL) {g_lObjBlackList=[];g_lObjBlackListNames=[];return;}
        if  (i<(g_lObjBlackList!=[]))
        {
            g_lObjBlackList=llDeleteSubList(g_lObjBlackList,i,i);
            g_lObjBlackListNames=llDeleteSubList(g_lObjBlackListNames,i,i);
        }
    }
    else if (iAuth==COMMAND_WEARER && g_iMinBaseMode > 0)
    {
        notify(g_kWearer,"Sorry, your owner does not allow you to remove trusted sources.",TRUE);
    }
    else if (g_sListType=="Trusted Object")
    {
        if (sMsg==ALL) {g_lObjWhiteList=[];g_lObjWhiteListNames=[];return;}
        if  (i<(g_lObjWhiteList!=[]))
        {
            g_lObjWhiteList=llDeleteSubList(g_lObjWhiteList,i,i);
            g_lObjWhiteListNames=llDeleteSubList(g_lObjWhiteListNames,i,i);
        }
    }
    else if (g_sListType=="Trusted Avatar")
    {
        if (sMsg==ALL) {g_lAvWhiteList=[];g_lAvWhiteListNames=[];return;}
        if  (i<(g_lAvWhiteList!=[])) 
        { 
            g_lAvWhiteList=llDeleteSubList(g_lAvWhiteList,i,i);
            g_lAvWhiteListNames=llDeleteSubList(g_lAvWhiteListNames,i,i);
        }
    }
}

refreshRlvListener()
{
    llListenRemove(g_iRlvListener);
    if (g_iRLV && g_iBaseMode && !g_iRecentSafeword)
        g_iRlvListener = llListen(RELAY_CHANNEL, "", NULL_KEY, "");
}


CleanQueue()
{
    //clean newly iNumed events, while preserving the order of arrival for every device
    list lOnHold=[];
    integer i=0;
    while (i<(g_lQueue!=[])/QSTRIDES)  //GetQLength()
    {
        string sIdent = llList2String(g_lQueue,0); //GetQident(0)
        key kObj = llList2String(g_lQueue,1); //GetQObj(0);
        string sCommand = llList2String(g_lQueue,2); //GetQCom(0);
        key kUser = NULL_KEY;
        integer iGotWho = llGetSubString(sCommand,0,6)=="!x-who/";
        if (iGotWho) kUser=SanitizeKey(llGetSubString(sCommand,7,42));
        integer iAuth=Auth(kObj,kUser);
        if(~llListFindList(lOnHold,[kObj])) ++i;
        else if(iAuth==1 && (kUser!=NULL_KEY || !iGotWho)) // !x-who/NULL_KEY means unknown user
        {
            g_lQueue = llDeleteSubList(g_lQueue,i,i+QSTRIDES-1); //DeleteQItem(i);
            HandleCommand(sIdent,kObj,sCommand,TRUE);
        }
        else if(iAuth==-1)
        {
            g_lQueue = llDeleteSubList(g_lQueue,i,i+QSTRIDES-1); //DeleteQItem(i);
            list lCommands = llParseString2List(sCommand,["|"],[]);
            integer j;
            for (j=0;j<(lCommands!=[]);++j)
                sendrlvr(sIdent,kObj,llList2String(lCommands,j),"ko");
        }
        else
        {
            ++i;
            lOnHold+=[kObj];
        }
    }
    //end of cleaning, now check if there is still events in queue and act accordingly
    Dequeue();
}

// returns TRUE if it was a user command, FALSE if it is a LM from another subsystem
integer UserCommand(integer iNum, string sStr, key kID)
{
    if (iNum<COMMAND_OWNER || iNum>COMMAND_WEARER) return FALSE;
    if (llSubStringIndex(sStr,"relay") && sStr != "menu "+g_sSubMenu) return TRUE;
    if (!g_iRLV)
    {
        notify(kID, "RLV features are now disabled in this collar. You can enable those in RLV submenu. Opening it now.", FALSE);
        llMessageLinked(LINK_SET, iNum, "menu RLV", kID);
    }
    else if (sStr=="relay" || sStr == "menu "+g_sSubMenu) Menu(kID, iNum);
    else if ((sStr=llGetSubString(sStr,6,-1))=="minmode") MinModeMenu(kID, iNum);
    else if (iNum!=COMMAND_OWNER&&kID!=g_kWearer)
        llInstantMessage(kID, "Sorry, only the wearer of the collar or their owner can change the relay options.");
    else if (sStr=="safeword") SafeWord();
    else if (sStr=="relay getdebug")
    {
        g_kDebugRcpt = kID;
        notify(kID, "Relay messages will be forwarded to "+llKey2Name(kID)+".", TRUE);
        return TRUE;
    }
    else if (sStr=="relay stopdebug")
    {
        g_kDebugRcpt = NULL_KEY;
        notify(kID, "Relay messages will not forwarded anymore.", TRUE);
        return TRUE;
    }
    else if (sStr=="pending")
    {
        if (g_lQueue != []) Dequeue();
        else llOwnerSay("No pending relay request for now.");
    }
    else if (sStr=="access") ListsMenu(kID, iNum);
    else if (iNum == COMMAND_OWNER && !llSubStringIndex(sStr,"minmode"))
    {
        sStr=llGetSubString(sStr,8,-1);
        integer iOSuccess = 0;
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        if (sChangetype=="safeword")
        {
            if (sChangevalue == "on") g_iMinSafeMode = TRUE;
            else if (sChangevalue == "off")
            {
                g_iMinSafeMode = FALSE;
                g_iSafeMode = FALSE;
            }
            else iOSuccess = 3;
        }
        else if (sChangetype=="land")
        {
            if (sChangevalue == "off") g_iMinLandMode = FALSE;
            else if (sChangevalue == "on")
            {
                g_iMinLandMode = TRUE;
                g_iLandMode = TRUE;
            }
            else iOSuccess = 3;
        }
        else if (sChangetype=="playful")
        {
            if (sChangevalue == "off") g_iMinPlayMode = FALSE;
            else if (sChangevalue == "on")
            {
                g_iMinPlayMode = TRUE;
                g_iPlayMode = TRUE;
            }
            else iOSuccess = 3;
        }
        else 
        {
            integer modetype = llListFindList(["off", "restricted", "ask", "auto"], [sChangetype]);
            if (~modetype)
            {
                g_iMinBaseMode = modetype;
                if (modetype > g_iBaseMode) g_iBaseMode = modetype;
            }
            else  iOSuccess = 3;
        }
        if (!iOSuccess)
        {
            notify(kID, llKey2Name(g_kWearer)+"'s relay minimal authorized mode is successfully set to: "+Mode2String(TRUE), TRUE);
            SaveSettings();
            refreshRlvListener();
        }
        else notify(kID, "Unknown relay mode.", FALSE);
    }
    else
    {
        integer iWSuccess = 0; //0: successful, 1: forbidden because of minmode, 2: forbidden because grabbed, 3: unrecognized commad
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        if (sChangetype=="safeword")
        {
            if (sChangevalue == "on")
            {
                if (g_iMinSafeMode == FALSE) iWSuccess = 1;
                else if (g_lSources!=[]) iWSuccess = 2;
                else g_iSafeMode = TRUE;
            }
            else if (sChangevalue == "off") g_iSafeMode = FALSE;
            else iWSuccess = 3;
        }
        else if (sChangetype=="land")
        {
            if (sChangevalue == "off")
            {
                if (g_iMinLandMode == TRUE) iWSuccess = 1;
                else g_iLandMode = FALSE;
            }
            else if (sChangevalue == "on") g_iLandMode = TRUE;
            else iWSuccess = 3;
        }
        else if (sChangetype=="playful")
        {
            if (sChangevalue == "off")
            {
                if (g_iMinPlayMode == TRUE) iWSuccess = 1;
                else g_iPlayMode = FALSE;
            }
            else if (sChangevalue == "on") g_iPlayMode = TRUE;
            else iWSuccess = 3;
        }
        else 
        {
            integer modetype = llListFindList(["off", "restricted", "ask", "auto"], [sChangetype]);
            if (~modetype)
            {
                if (modetype >= g_iMinBaseMode) g_iBaseMode = modetype;
                else iWSuccess = 1;
            }
            else iWSuccess = 3;
        }
        if (!iWSuccess) notify(kID, "Your relay mode is successfully set to: "+Mode2String(FALSE), TRUE);
        else if (iWSuccess == 1) notify(kID, "Minimal mode previously set by owner does not allow this setting. Change it or have it changed first.", TRUE);
        else if (iWSuccess == 2) notify(kID, "Your relay is being locked by at least one object, you cannot disable it or enable safewording now.", TRUE);
        else if (iWSuccess == 3) notify(kID, "Invalid command, please read the manual.", FALSE);
        SaveSettings();
        refreshRlvListener();
    }
    return TRUE;
}

default
{
    state_entry()
    {
        g_kWearer = llGetOwner();
        g_lSources=[];
        llSetTimerEvent(g_iGarbageRate); //start garbage collection timer
    }

    link_message(integer iSender_iNum, integer iNum, string sStr, key kID )
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, NULL_KEY);
        }
        else if (iNum==CMD_ADDSRC)
        {
            g_lSources+=[kID];
        }
        else if (iNum==CMD_REMSRC)
        {
            integer i= llListFindList(g_lSources,[kID]);
            if (~i) g_lSources=llDeleteSubList(g_lSources,i,i);
        }
        else if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == LM_SETTING_RESPONSE)
        {   //this is tricky since our db value contains equals signs
            //split string on both comma and equals sign
            //first see if this is the token we care about
            list lParams = llParseString2List(sStr, ["="], []);
            string iToken = llList2String(lParams, 0);
            if (iToken == g_sDBToken)
            {
                //throw away first element
                //everything else is real settings (should be even number)
                UpdateSettings(llList2String(lParams, 1));
            }
            else if (iToken == "owner")
            {
                g_lCollarOwnersList = llParseString2List(llList2String(lParams, 1), [","], []);
            }
            else if (iToken == "secowners")
            {
                g_lCollarSecOwnersList = llParseString2List(llList2String(lParams, 1), [","], []);
            }
            else if (iToken == "blacklist")
            {
                g_lCollarBlackList = llParseString2List(llList2String(lParams, 1), [","], []);
            }
        }
        else if (iNum == LM_SETTING_SAVE)
        {   //this is tricky since our db sValue contains equals signs
            //split string on both comma and equals sign
            //first see if this is the sToken we care about
            list lParams = llParseString2List(sStr, ["="], []);
            string iToken = llList2String(lParams, 0);
            if (iToken == "owner")
            {
                g_lCollarOwnersList = llParseString2List(llList2String(lParams, 1), [","], []);
            }
            else if (iToken == "secowners")
            {
                g_lCollarSecOwnersList = llParseString2List(llList2String(lParams, 1), [","], []);
            }
            else if (iToken == "blacklist")
            {
                g_lCollarBlackList = llParseString2List(llList2String(lParams, 1), [","], []);
            }
        }
        // rlvoff -> we have to turn the menu off too
        else if (iNum == RLV_OFF)
        {
            g_iRLV=FALSE;
            refreshRlvListener();
        }
        // rlvon -> we have to turn the menu on again
        else if (iNum == RLV_ON)
        {
            g_iRLV=TRUE;
            refreshRlvListener();
        }
        else if (iNum==RLV_REFRESH)
        {
            g_iRLV=TRUE;
            refreshRlvListener();
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (~llListFindList([g_kMenuID, g_kMinModeMenuID, g_kListMenuID, g_kListID, g_kAuthMenuID], [kID]))
            {
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = llList2Key(lMenuParams, 0);
                string sMsg = llList2String(lMenuParams, 1);
                integer iPage = llList2Integer(lMenuParams, 2);
                integer iAuth = llList2Integer(lMenuParams, 3);
                if (kID==g_kMenuID || kID == g_kMinModeMenuID)
                {
                    llSetTimerEvent(g_iGarbageRate);
                    integer iIndex=llListFindList(["Auto","Ask","Restricted","Off","Safeword", "( )Safeword", "(*)Safeword","( )Playful","(*)Playful","( )Land","(*)Land"],[sMsg]);
                    if (sMsg=="Pending") UserCommand(iAuth, "relay pending", kAv);
                    else if (sMsg=="Access Lists") UserCommand(iAuth, "relay access", kAv);
                    else if (~iIndex)
                    {
                        string sInternalCommand = "relay ";
                        if (kID == g_kMinModeMenuID) sInternalCommand += "minmode ";
                        sInternalCommand += llList2String(["auto","ask","restricted","off","safeword","safeword on","safeword off","playful on", "playful off","land on","land off"],iIndex);
                        UserCommand(iAuth, sInternalCommand, kAv);
                        if (kID == g_kMinModeMenuID) MinModeMenu(kAv, iAuth);
                        else Menu(kAv, iAuth);
                    }
                    else if (sMsg=="Grabbed by")
                    {
                        llMessageLinked(LINK_SET, iAuth,"showrestrictions",kAv);
                        Menu(kAv, iAuth);
                    }
                    else if (sMsg=="MinMode") MinModeMenu(kAv, iAuth);
                    else if (sMsg=="Help")
                    {
                        llGiveInventory(kAv,"OpenCollar RLV Relay Help");
                        Menu(kAv, iAuth);
                    }
                    else if (sMsg==UPMENU)
                    {
                        if (kID == g_kMenuID) llMessageLinked(LINK_SET,iAuth,"menu "+g_sParentMenu,kAv);
                        else Menu(kAv, iAuth);
                    }
                }
                else if (kID==g_kListMenuID)
                {
                    llSetTimerEvent(g_iGarbageRate);
                    PListsMenu(kAv,sMsg, iAuth);
                }
                else if (kID==g_kListID)
                {
                    llSetTimerEvent(g_iGarbageRate);
                    if (sMsg==UPMENU)
                    {
                        ListsMenu(kAv, iAuth);
                    }
                    else 
                    {
                        RemListItem(sMsg, iAuth);
                        ListsMenu(kAv, iAuth);
                    }
                }
                else if (kID==g_kAuthMenuID)
                {
                    llSetTimerEvent(g_iGarbageRate);
                    g_iAuthPending = FALSE;
                    key kCurID=llList2String(g_lQueue,1); //GetQObj(0);
                    string sCom = llList2String(g_lQueue,2);  //GetQCom(0));
                    key kUser = NULL_KEY;
                    integer iSave=TRUE;
                    if (llGetSubString(sCom,0,6)=="!x-who/") kUser = SanitizeKey(llGetSubString(sCom,7,42));
                    if (sMsg=="Yes")
                    {
                        g_lTempWhiteList+=[kCurID];
                        if (kUser) g_lTempUserWhiteList+=[(string)kUser];
                        iSave=FALSE;
                    }
                    else if (sMsg=="No")
                    {
                        g_lTempBlackList+=[kCurID];
                        if (kUser) g_lTempUserBlackList+=[(string)kUser];
                        iSave=FALSE;
                    }
                    else if (sMsg=="Trust Object")
                    {
                        if (!~llListFindList(g_lObjWhiteList, [kCurID]))
                        {
                            g_lObjWhiteList+=[kCurID];
                            g_lObjWhiteListNames+=[llKey2Name(kCurID)];
                        }
                    }
                    else if (sMsg=="Ban Object")
                    {
                        if (!~llListFindList(g_lObjBlackList, [kCurID]))
                        {
                            g_lObjBlackList+=[kCurID];
                            g_lObjBlackListNames+=[llKey2Name(kCurID)];
                        }
                    }
                    else if (sMsg=="Trust Owner")
                    {
                        if (!~llListFindList(g_lAvWhiteList, [(string)llGetOwnerKey(kCurID)]))
                        {
                            g_lAvWhiteList+=[(string)llGetOwnerKey(kCurID)];
                            g_lAvWhiteListNames+=[llKey2Name(llGetOwnerKey(kCurID))];
                        }
                    }
                    else if (sMsg=="Ban Owner")
                    {
                        if (!~llListFindList(g_lAvBlackList, [(string)llGetOwnerKey(kCurID)]))
                        {
                            g_lAvBlackList+=[(string)llGetOwnerKey(kCurID)];
                            g_lAvBlackListNames+=[llKey2Name(llGetOwnerKey(kCurID))];
                        }
                    }
                    else if (sMsg=="Trust User")
                    {
                        if (!~llListFindList(g_lAvWhiteList, [(string)kUser]))
                        {
                            g_lAvWhiteList+=[(string)kUser];
                            g_lAvWhiteListNames+=[llKey2Name(kUser)];
                        }
                    }
                    else if (sMsg=="Ban User")
                    {
                        if (!~llListFindList(g_lAvBlackList, [(string)kUser]))
                        {
                            g_lAvBlackList+=[(string)kUser];
                            g_lAvBlackListNames+=[llKey2Name(kUser)];
                        }
                    }
                    if (iSave) SaveSettings();
                    CleanQueue();
                }
            }
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            if (kID == g_kAuthMenuID)
            {
                g_iAuthPending = FALSE;
                llOwnerSay("Relay authorization dialog expired. You can make it appear again with command \"<prefix>relay pending\".");
            }
        }
    }

    listen(integer iChan, string who, key kID, string sMsg)
    {
//        if (llGetSubString(sMsg,-43,-1)==","+(string)g_kWearer+",!pong") //sloppy matching; the protocol document is stricter, but some in-world devices do not respect it
//        {llOwnerSay("Forwarding "+sMsg+" to rlvmain");
//            llMessageLinked(LINK_SET, COMMAND_RLV_RELAY, sMsg, kID);
            // send the ping to rlvmain to manage restrictions of this old source
//        }
/*        else if (llStringLength(sMsg)> 700)
        { //too long command, will make the relay crash in ask mode
            sMsg="";
            llOwnerSay("Dropping a too long command from " + llKey2Name(kID)+". Maybe a malicious device?. Relay frozen for the next 20s.");
            g_iRecentSafeword=TRUE;
            refreshRlvListener();
            llSetTimerEvent(30.);
            return;
        }*/
//        else
//        { //in other cases we analyze the command here
        list lArgs=llParseString2List(sMsg,[","],[]);
        sMsg = "";  // free up memory in case of large messages
        if ((lArgs!=[])!=3) return;
        if (llList2Key(lArgs,1)!=g_kWearer && llList2String(lArgs,1)!="ffffffff-ffff-ffff-ffff-ffffffffffff") return; // allow FFF...F wildcard
        string sIdent=llList2String(lArgs,0);
        sMsg=llToLower(llList2String(lArgs,2));
        if (g_kDebugRcpt == g_kWearer) llOwnerSay("To relay: "+sIdent+","+sMsg);
        else if (g_kDebugRcpt) llRegionSayTo(g_kDebugRcpt, DEBUG_CHANNEL, "To relay: "+sIdent+","+sMsg);
        if (sMsg == "!pong")
        {//sloppy matching; the protocol document is stricter, but some in-world devices do not respect it
            llMessageLinked(LINK_SET, COMMAND_RLV_RELAY, "ping,"+(string)g_kWearer+",!pong", kID);
            return;
        }
        lArgs = [];  // free up memory in case of large messages

        key kUser = NULL_KEY;
        if (llGetSubString(sMsg,0,6)=="!x-who/") kUser=SanitizeKey(llGetSubString(sMsg,7,42));
        integer iAuth=Auth(kID,kUser);
        if (iAuth==-1) return;
        else if (iAuth==1) {HandleCommand(sIdent,kID,sMsg,TRUE); llSetTimerEvent(g_iGarbageRate);}
        else if (g_iBaseMode == 2)
        {
            if (g_iQApproxSize < 2500) //keeps margin for this event + next arriving chat message
            {
                g_iQApproxSize += llStringLength(sIdent+ sMsg);
                g_lQueue += [sIdent, kID, sMsg];
                sMsg = ""; sIdent="";
                if (!g_iAuthPending) Dequeue();
            }
            else
            {
                llOwnerSay("Relay queue saturated. Dropping all requests from "+ llKey2Name(kID) +". Relay frozen for the next 20s.");
                sMsg = ""; sIdent="";
                g_lTempBlackList+=[kID];
                if (kUser) g_lTempUserBlackList+=[kUser];
                CleanQueue();
                g_iRecentSafeword = TRUE;
                refreshRlvListener();
                llSetTimerEvent(30.);
            }
        }
        else if (g_iPlayMode) {HandleCommand(sIdent,kID,sMsg,FALSE); llSetTimerEvent(g_iGarbageRate);}
    }

    on_rez(integer iNum)
    {
        llResetScript();
    }

    timer()
    {
        if (g_iRecentSafeword)
        {
            g_iRecentSafeword = FALSE;
            refreshRlvListener();
        }
        //garbage collection
        vector vMyPos = llGetRootPosition();
        integer i;
        for (i=0;i<(g_lSources!=[]);++i)
        {
            key kID = llList2Key(g_lSources,i);
            vector vObjPos = llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]),0);
            if (vObjPos == <0, 0, 0> || llVecDist(vObjPos, vMyPos) > 100) // 100: max shout distance
                llMessageLinked(LINK_SET,RLV_CMD,"clear",kID);
        }
        llSetTimerEvent(g_iGarbageRate);
        g_lTempBlackList=[];
        g_lTempWhiteList=[];
        if (g_lSources == [])
        { //dont clear already authorized users before done with current session
            g_lTempUserBlackList=[];
            g_lTempUserWhiteList=[];
        }
    }
}