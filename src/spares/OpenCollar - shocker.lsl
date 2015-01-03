//OpenCollar - shocker
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

string g_sSubMenu = "Shocker";
string g_sParentMenu = "Apps";

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_SAFEWORD = 510;  // new for safeword

//integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

//integer RLV_CMD = 6000;

integer ANIM_START = 7000;
integer ANIM_STOP = 7001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

// menu buttons
string UPMENU = "BACK";
string HELP = "Quick Help";
string DEFAULT = "Default" ;

list g_lButtons = ["1 sec.","3 sec.","5 sec.","10 sec.","15 sec.","30 sec.","1 min.","Stop"];
list g_lTime = [1,3,5,10,15,30,60,0];

string g_sSetAnim = "Set Anim";
string g_sSetSound = "Set Sound";

string g_sDefaultAnim = "~shock";
//string g_sDefaultSound = "011ef7f4-40e8-28fe-4ea5-f2fda0883707";
string g_sDefaultSound = "4546cdc8-8682-6763-7d52-2c1e67e8257d";
string g_sNoSound = "silent" ;

string g_sShockAnim ;
string g_sShockSound;

string CTYPE = "collar";
string WEARERNAME;
string g_sScript = "shocker_";

key g_kWearer;
key g_kDialog;
key g_kAnimDialog;
key g_kSoundDialog;

integer g_iShock = FALSE ;

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
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}
*/

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_THIS, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|"
        + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

DialogShocker(key kID, integer iAuth)
{
    string sText = "Shocker!\n Your pet is naughty? Just punish him/her.\n";
    sText += "- Chose time to start punishment.\n" ;
    sText += "- 'Quick Help' will give you a brief help how to use shocker.\n";
    g_kDialog = Dialog(kID, sText, g_lButtons, [HELP,g_sSetAnim, g_sSetSound,UPMENU],0,iAuth);
}

DialogSelectAnim(key kID, integer iAuth)
{
    list lAnimList = [DEFAULT];
    integer iMax = llGetInventoryNumber(INVENTORY_ANIMATION);
    integer i;
    string sName;
    for (i=0;i<iMax;i++)
    {
        sName=llGetInventoryName(INVENTORY_ANIMATION, i);
        //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
        if (sName != "" && llGetSubString(sName, 0, 0) != "~") lAnimList += [sName];
    }
    string sText = "Current punishment animation is: "+g_sShockAnim+"\n\n";
    sText += "Select a new animation to use as a punishment.\n\n";
    g_kAnimDialog = Dialog(kID, sText, lAnimList, [UPMENU],0, iAuth);
}


DialogSelectSound(key kID, integer iAuth)
{
    list lSoundList = [DEFAULT];
    integer iMax = llGetInventoryNumber(INVENTORY_SOUND);
    integer i;
    string sName;
    for (i=0;i<iMax;i++)
    {
        sName=llGetInventoryName(INVENTORY_SOUND, i);
        //check here if the anim start with ~ or for some reason does not get a name returned (spares to check that all again in the menu ;)
        if (sName != "" && llGetSubString(sName, 0, 0) != "~") lSoundList += [sName];
    }
    lSoundList+=[g_sNoSound];
    string sText = "Current sound is: "+g_sShockSound+"\n\n";
    sText += "Select a new sound to use.\n\n";
    g_kSoundDialog = Dialog(kID, sText, lSoundList, [UPMENU],0, iAuth);
}

DialogHelp(key kID, integer iAuth)
{
    string sMessage = "Usage of Shocker.\n";
    sMessage += "Put in front of each command your subs prefix then use them as followed:\n";
    sMessage += "shock <seconds> where <seconds> is time in seconds to punish you pet.\n";
    sMessage += "shock 0/stop/off ,  is stop to punish you pet immediately.\n";
    sMessage += "shockanim <anim name> , make sure the animation is inside the collar.\n";
    sMessage += "shocksound <sound name> , make sure the sound is inside the collar.";

    g_kDialog = Dialog(kID, sMessage, ["Ok"], [], 0, iAuth);
    Notify(kID, sMessage, FALSE) ;
}

string right(string sSrc, string sDivider)
{
    integer iIndex = llSubStringIndex( sSrc, sDivider );
    if(~iIndex) return llDeleteSubString( sSrc, 0, iIndex + llStringLength(sDivider) - 1);
    return sSrc;
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

Shock(integer time, key kID)
{
    if (time > 0)
    {
        Notify(kID, WEARERNAME+" now shocked for "+(string)time+" seconds.", TRUE);
        if (g_sShockSound != g_sNoSound)
        {
            if (g_sShockSound == DEFAULT) llLoopSound( g_sDefaultSound, 1.0 );
            else llLoopSound( g_sShockSound, 1.0 );
        }
        g_iShock = TRUE ;
        llMessageLinked(LINK_THIS, ANIM_START, g_sShockAnim, "");
        llResetTime();
        llSetTimerEvent(time);
    }
    else if (g_iShock == TRUE)
    {
        Notify(kID, "shocker off.", TRUE);
        llSetTimerEvent(0);
        Stop();
    }
}

Stop()
{
    if (g_iShock)
    {
        if (g_sShockSound != g_sNoSound) llStopSound( );
        llMessageLinked(LINK_THIS, ANIM_STOP, g_sShockAnim, "");
        g_iShock = FALSE ;
    }
}


integer UserCommand(integer iAuth, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iAuth > COMMAND_WEARER || iAuth < COMMAND_OWNER) return FALSE; // sanity check

    if (sStr == "menu "+g_sSubMenu || sStr == "shocker")
    {
        if (iAuth == COMMAND_OWNER) DialogShocker(kID, iAuth);
        else Notify(kID, "Sorry, only the Owner can punish pet.",FALSE);
        return TRUE;
    }
    else if (iAuth == COMMAND_OWNER)
    {    
        list lParams = llParseString2List(sStr, [" "], []);
        string sCommand = llList2String(lParams, 0);
        string sValue = llList2String(lParams, 1);

        if (sStr == "shocker help") DialogHelp(kID, iAuth);
        else if (sCommand == "shock")
        {
	    if (sValue == "off" || sValue == "stop") Shock(0,kID);
            else Shock((integer)sValue,kID);
        }
        else if (sCommand == "shockanim")
        {
            //Get all text after the command, strip spaces from start and end
            string sAnim = right(sStr, sCommand);
            sAnim = llStringTrim(sAnim, STRING_TRIM);
            if (sAnim == DEFAULT) sAnim = g_sDefaultAnim;
            if (llGetInventoryType(sAnim) == INVENTORY_ANIMATION)
            {
                Stop();
                g_sShockAnim = sAnim;
                llMessageLinked(LINK_THIS, LM_SETTING_SAVE, g_sScript + "anim=" + g_sShockAnim, "");
                Notify(kID, "Punishment anim for shocker is now '" + g_sShockAnim + "'.",FALSE);
            }
            else Notify(kID, sAnim + " is not a valid animation name.",FALSE);            
        }
        else if (sCommand == "shocksound")
        {
            //Get all text after the command, strip spaces from start and end
            string sSound = right(sStr, sCommand);
            sSound = llStringTrim(sSound, STRING_TRIM);
            if (sSound == g_sNoSound) Notify(kID, "Punishment will be silently.",FALSE);
            else if (llGetInventoryType(sSound) != INVENTORY_SOUND)
            {
                Notify(kID, sSound + " is not a valid sound name.",FALSE);
                sSound = DEFAULT ;
            }
            g_sShockSound = sSound;
            llMessageLinked(LINK_THIS,LM_SETTING_SAVE,g_sScript+"sound="+g_sShockSound, "");
            Notify(kID, "Punishment sound for shocker is now '"+g_sShockSound+"'.",FALSE);
        }
    }
    return TRUE;
}

string GetName(key uuid)
{
    string name = llGetDisplayName(uuid);
    if (name == "???" || name == "") name = llKey2Name(uuid);
    return name;
}

default
{
    on_rez(integer iParam)
    {
        llResetScript();
    }

    state_entry()
    {
        g_kWearer = llGetOwner();
        WEARERNAME = GetName(g_kWearer);
        g_sScript = "shocker_";
        g_sShockAnim = g_sDefaultAnim;
        g_sShockSound = DEFAULT ;
    }

    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == LM_SETTING_DELETE && sStr == "Global_WearerName")
        {
            WEARERNAME = GetName(g_kWearer);
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sScript+"anim") g_sShockAnim = sValue;
            else if (sToken == g_sScript+"sound") g_sShockSound = sValue;
            else if (sToken == "Global_CType") CTYPE = sValue;
            else if (sToken == "Global_WearerName") WEARERNAME = sValue;
        }
        else if (iNum == COMMAND_SAFEWORD) Shock(0,kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_THIS, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum == DIALOG_RESPONSE && (kID==g_kDialog || kID==g_kAnimDialog || kID==g_kSoundDialog))
        {
            list lMenuParams = llParseString2List(sStr, ["|"], []);
            key kAv = (key)llList2String(lMenuParams, 0);
            string sMessage = llList2String(lMenuParams, 1);
            integer iPage = (integer)llList2String(lMenuParams, 2);
            integer iAuth = (integer)llList2String(lMenuParams, 3);
            if (kID == g_kDialog)
            {
                if (sMessage == "Ok") DialogShocker(kAv,iAuth);
                else if (sMessage == g_sSetAnim) DialogSelectAnim(kAv,iAuth);
                else if (sMessage == g_sSetSound) DialogSelectSound(kAv,iAuth);
                else if (sMessage == UPMENU) llMessageLinked(LINK_THIS, iAuth, "menu "+g_sParentMenu, kAv);
                else if (sMessage == HELP) DialogHelp(kAv,iAuth);
                else
                {
                    integer index = llListFindList(g_lButtons, [sMessage]);
                    if (index != -1)
                    {
                        integer shocktime = llList2Integer(g_lTime,index);
                        Shock(shocktime,kAv);
                        DialogShocker(kAv,iAuth);
                    }
                }
            }
            else if (kID == g_kAnimDialog)
            {
                if (sMessage != "") UserCommand(iAuth,"shockanim " + sMessage,kAv);
                DialogShocker(kAv,iAuth);
            }
            else if (kID == g_kSoundDialog)
            {
                if (sMessage != "") UserCommand(iAuth,"shocksound " + sMessage,kAv);
                DialogShocker(kAv,iAuth);
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0);
        Stop();
    }
}
