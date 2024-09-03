/*
This file is a part of OpenCollar.
Created by Medea Destiny
Copyright ©2024 

: Contributors :

Medea (Medea Destiny)
    *May 2024   -   Created script 
Ping (Pingout Duffield)
    *Jul 2024   -   Fixed typos in variable %WEARER% -> %WEARERNAME%                            
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/


integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_SAFEWORD = 510;

//backwards compatibility stuff for float text;
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings

integer REBOOT = -1000;
string UPMENU = "BACK";
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;


integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer NOTIFY = 1002;

string LSDPrefix="timer"; //All LSD used by this script has this prefix.
integer LSD_REQUEST=-500; //Sends LSDPrefix when received, for flushing no longer used LSD.
integer LSD_RESPONSE=-501; //Reply to above

integer AUTH_WEARERLOCKOUT=602;

string g_sSubMenu = "Timer";
string g_sParentMenu = "Apps";
list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;
key g_kMenuUser;
key g_kWearer;


Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}
string buttonize(string token)
{
    string t=LSDRead(token);
    if(t=="0" || t=="") return "□ "+token;
    else return "▣ "+token;
    
}

mainMenu(key kAv, integer iAuth)
{
    list buttons;
   string sPrompt="Timer menu \n\n";
   
   
   if(LSDRead("TimerActive")=="1")
   {
       integer tl=(integer)LSDRead("LockTime")-(integer)llGetTime();
       if(tl<10) tl=10;
       sPrompt+="Active! Time left:"+timeDisplay(tl)+"\n\nClick 'EndNow' to end timer early, or 'Cancel' to stop the timer without triggering commands.\nPermissive mode allows collar users (apart from wearer) to end the timer even if they have lower auth than the timer setter. Titler shows time remaining as float text unless a title is set.";
       buttons+=["EndNow","Cancel",buttonize("Permissive")];
    }
    else 
    {
        buttons=["Time",buttonize("Lockout"),buttonize("Customs"),buttonize("Unleash"),buttonize("Unpose"),buttonize("Unsit"),buttonize("ClearRLV"),buttonize("Titler"),buttonize("Permissive"),"Start"];
        sPrompt+="Timer: "+timeDisplay((integer)LSDRead("LockTime"))+"\n\n'Start' to activate timer.  'Time' to change timer length. 'Lockout' locks wearer out of collar when timer active.\n  On timer end: 'ClearRLV' clears restrictions, 'Unsit' makes wearer stand (even strict sit if owner sets timer), 'Unpose' and 'Unleash' as they say, 'Custom' sets custom commands (checked if any set).\n  Permissive lets collar users (not wearer) to end timer even if lower auth than the setter. Titler shows time remaining as float text unless a title is set.";
    }
    Dialog(kAv,sPrompt,buttons,[UPMENU],0,iAuth,"timer~app");
}
customMenu(key kAv,integer iAuth)
{
    string text=LSDRead("Customs");
    if(text=="") text="None.";
    else text=llDumpList2String(llCSV2List(text),"\n");
    text="Enter chat commands (without prefix, e.g. 'preset clear dress' or 'tp home') separating commands with a comma. Leave blank to clear.\nCurrent: "+text;
    Dialog(kAv,text,[],[],0,iAuth,"timer~custom");
}  
timerMenu(key kAv, integer iAuth)
{
    Dialog(kAv,"Set timer time\n\nCurrent time: "+timeDisplay((integer)LSDRead("LockTime"))+"\n",["+1 min","+5 min","+30 min","-1 min","-5 min","-30 min","+1 hr","+6 hrs","-6 hrs","-1 hr"],[UPMENU],0,iAuth,"timer~timerset");
}

string LSDRead(string token)
{
    return llLinksetDataRead(LSDPrefix+"_"+token);
}
LSDWrite(string token, string val)
{
    llLinksetDataWrite(LSDPrefix+"_"+token,val);
}
/* LSD settings
timer_Lockout
timer_Unleash
timer_UnPose
timer_Unsit
timer_ClearRLV
timer_Customs
timer_TimerSetterKey
timer_LastAuth
timer_LockTime
timer_TimerActive
timer_Permissive
timer_Titler
*/
reset()
{
    list defaults=["Lockout","0","Unleash","0","Unpose","0","ClearRLV","0","Unsit","0","Customs","","TimerSetterKey","","LastAuth","0","LockTime","600","TimerActive","0","Permissive","0","Titler","0"];
    integer i=llGetListLength(defaults);
    integer x;
    while(x<i)
    {
        LSDWrite(llList2String(defaults,x),llList2String(defaults,x+1));
        x=x+2;
    }
    list t=llLinksetDataListKeys(0,0);
    i=llGetListLength(t);
    x=0;

}
string timeDisplay(integer secs)
{

    integer days=secs/86400;
    secs=secs%86400;
    integer hours=secs/3600;
    secs=secs%3600;
    integer mins=secs/60;
    secs=secs%60;

    list out;
    if(days) out+=[(string)days+"d"];
    if(hours) out+=[(string)hours+"h"];
    if(mins) out+=[(string)mins+"m"];
    if(secs || llGetListLength(out)==0) out+=[(string)secs+"s"];
    return llDumpList2String(out,", ");
}


    
UserCommand(integer iAuth, string sCmd, key kAv)
{
    if (iAuth <CMD_OWNER || iAuth>CMD_EVERYONE) return;
    sCmd=llToLower(sCmd);
    if (kAv==g_kWearer && sCmd == "runaway") 
    {
        stopTimer(FALSE);
        return;
    }
    if(sCmd==llToLower(g_sSubMenu) || sCmd=="menu timer")
    {
         mainMenu(kAv,iAuth);
         return;
    }
    list lParams=llParseString2List(sCmd,[" "],[]);
    if(llList2String(lParams,0)!="timer") return;
    integer remenu;
    if(llList2String(lParams,-1)=="remenu")
    {
        remenu=TRUE;
        lParams=llDeleteSubList(lParams,-1,-1);
    }
    string sCmd=llList2String(lParams,1);
    string sVal=llList2String(lParams,2);
    if(sVal=="on") sVal="1";
    else if(sVal=="off") sVal="0";
    if(sCmd=="permissive" && (sVal=="1" || sVal=="0"))
    {
        if(iAuth!=CMD_OWNER && kAv!=g_kWearer) llRegionSayTo(kAv,0,"Only wearer and owners can change this setting.");
        else if(LSDRead("TimerActive")=="1" && kAv==g_kWearer) llOwnerSay("You cannot change this while the timer is active.");
        else
        {
            LSDWrite("Permissive",sVal);
            llMessageLinked(LINK_THIS,NOTIFY,"1Setting timer permissive to "+llList2String(["off","on"],(integer)sVal)+".",kAv);
        }
    }
    else if(LSDRead("TimerActive")=="1")
    {
        if(iAuth>(integer)LSDRead("LastAuth")&& (LSDRead("Permissive")!="1" || kAv==g_kWearer))
        {
            llMessageLinked(LINK_THIS,NOTIFY,"0Timer has been set by a user with higher auth than you, you can't override the current timer or settings.",kAv);
            if(remenu==TRUE && (kAv!=g_kWearer || LSDRead("Lockout")=="0") ) mainMenu(kAv,iAuth);
            return;
        }
        if(sCmd=="endnow")
        {
            llMessageLinked(LINK_THIS,NOTIFY,"1%WEARERNAME%'s timer ended by secondlife:///app/agent/"+(string)kAv+"/about",kAv);
            stopTimer(TRUE);
        }
        else if(sCmd=="cancel")
        {
             llMessageLinked(LINK_THIS,NOTIFY,"1%WEARERNAME%'s timer cancelled by secondlife:///app/agent/"+(string)kAv+"/about",kAv);
            stopTimer(FALSE);
        }
        else llRegionSayTo(kAv,0,"Sorry, can't change that while timer is active.");
    }
    else if(sCmd=="start") startTimer(kAv,iAuth);
    else if(sCmd=="time")
    {
        if(sVal=="")
        {
            timerMenu(kAv,iAuth);
            return;
        }
        else
        {
            //function to attempt to derive correct seconds value
            //from whatever meaningful text input is given.
            sVal=(string)llList2List(lParams,2,-1);
            string sVal=(string)llList2List(lParams,2,-1);
            integer ti;
            list t=llParseString2List(sVal,[","],["hours","hrs","hr","hs","h"]);
            if(llGetListLength(t)>1)
            {
                ti+=(integer)llList2String(t,0)*3600;
                t=llDeleteSubList(t,0,1);
                sVal=(string)t;
            }
            t=llParseString2List(sVal,[],["minutes","mins","min","ms","m"]);
            if(llGetListLength(t)>1)
            {
                ti+=(integer)llList2String(t,0)*60;
                t=llDeleteSubList(t,0,1); 
                sVal=(string)t;
            }
            t=llParseString2List(sVal,[],["s"]);
            ti+=(integer)llList2String(t,0);
            if(ti) 
            {
                LSDWrite("LockTime",(string)ti);
                llMessageLinked(LINK_THIS,NOTIFY,"1Setting time to "+timeDisplay(ti)+".",kAv);
            }
            else llMessageLinked(LINK_THIS,NOTIFY,"0Invalid setting for timer time.",kAv);
        }
    }
    else if(sCmd=="customs")
    {
        if(sVal==""||sVal=="1"||sVal=="0") customMenu(kAv,iAuth);
        else
        {
            LSDWrite("Customs",sVal);
            llMessageLinked(LINK_THIS,NOTIFY,"0Timer custom commands changed to:\n"+llDumpList2String(llCSV2List(sVal),"\n"),kAv);
        }
        return;
    }
    else if(sVal=="1" || sVal=="0")
    {
        
        if(sCmd=="lockout")
        {
            if(kAv==g_kWearer)
            {
                LSDWrite("Lockout",sVal);
                if(sVal=="1") llOwnerSay("You will be locked out of your collar when the timer is active.");
                else llOwnerSay("Wearer lockout deactivated for timer");
            }
            else llMessageLinked(LINK_THIS,NOTIFY,"0Only wearer can modify timer self-lockout mode.",kAv);
        }
        else if(sCmd=="clearrlv")
        {
            LSDWrite("ClearRLV",sVal);
            llMessageLinked(LINK_THIS,NOTIFY,"1Setting timer ClearRLV to "+llList2String(["off","on"],(integer)sVal)+".",kAv);
        }
        else if(sCmd=="unpose")
        {
            LSDWrite("Unpose",sVal);
            llMessageLinked(LINK_THIS,NOTIFY,"1Setting timer Unpose to "+llList2String(["off","on"],(integer)sVal)+".",kAv);
        }
        else if(sCmd=="unleash")
        {
            LSDWrite("Unleash",sVal);
            llMessageLinked(LINK_THIS,NOTIFY,"1Setting timer Unleash to "+llList2String(["off","on"],(integer)sVal)+".",kAv);
        }
        else if(sCmd=="unsit")
        {
            LSDWrite("Unsit",sVal);
            llMessageLinked(LINK_THIS,NOTIFY,"1Setting timer Unsit to "+llList2String(["off","on"],(integer)sVal)+".",kAv);
        }
        else if(sCmd=="titler")
        {
            LSDWrite("Titler",sVal);
            llMessageLinked(LINK_THIS,NOTIFY,"1Setting timer titling "+llList2String(["off","on"],(integer)sVal)+".",kAv);
        }    
        else llRegionSayTo(kAv,0,"I didn't understand that command, sorry.");
            
    }
    if(remenu==TRUE &&(kAv!=g_kWearer || llLinksetDataRead("auth_WearerLockout")=="")) mainMenu(kAv,iAuth);
        


}
   
startTimer(key kAv, integer iAuth)
{
    integer time=(integer)LSDRead("LockTime");
    llSetTimerEvent(60);
    llResetTime();
    LSDWrite("TimerActive","1");
    LSDWrite("TimerSetterKey",(string)kAv);
    LSDWrite("LastAuth",(string)iAuth);
    if(LSDRead("Lockout")=="1")
    {
         list temp=llCSV2List(llLinksetDataRead("auth_WearerLockout"));
         if(llListFindList(temp,[LSDPrefix])==-1) temp+=[LSDPrefix];
         llLinksetDataWrite("auth_WearerLockout",llList2CSV(temp));
    }
    if(LSDRead("Titler")=="1" && g_iTitlerActive==FALSE) setText(TRUE);
    string msg=timeDisplay(time)+" timer Started!\nWhen the timer ends, the following commands will be issued:\n";
    string cmds;
    if(LSDRead("Unleash")=="1") cmds+="Unleash\n";
    if(LSDRead("Unpose")=="1") cmds+="Stop animations\n";
    if(LSDRead("ClearRLV")=="1") cmds+="Clear all restrictions\n";
    if(LSDRead("Unsit")=="1") cmds+="Unsit if seated (even with strict sit when timer set by owner)\n";
    list t=llCSV2List(LSDRead("Customs"));
    cmds+=llDumpList2String(t,"\n");
    if(cmds=="") cmds="None";
    llMessageLinked(LINK_THIS,NOTIFY,"1"+msg+cmds,kAv);
    
}
stopTimer(integer execute)
{
    llSetTimerEvent(0);
    list temp=llCSV2List(llLinksetDataRead("auth_WearerLockout"));
    integer i=llListFindList(temp,[LSDPrefix]);
    if(i!=-1) temp=llDeleteSubList(temp,i,i);
    llLinksetDataWrite("auth_WearerLockout",llList2CSV(temp));
    llMessageLinked(LINK_THIS,NOTIFY,"1%WEARERNAME%'s timelock has ended.",(key)LSDRead("TimerSetterKey"));
    LSDWrite("TimerActive","0");
    if(execute)
    {
        if(LSDRead("Unleash")=="1") llMessageLinked(LINK_THIS,CMD_ZERO,"unleash",(key)LSDRead("TimerSetterKey"));
        if(LSDRead("Unpose")=="1") llMessageLinked(LINK_THIS,CMD_ZERO,"stop",(key)LSDRead("TimerSetterKey"));
        if(LSDRead("ClearRLV")=="1") llMessageLinked(LINK_THIS,CMD_ZERO,"clear",(key)LSDRead("TimerSetterKey"));
        if(LSDRead("Unsit")=="1") llMessageLinked(LINK_THIS,CMD_ZERO,"unsit",(key)LSDRead("TimerSetterKey"));
        list cTemp=llCSV2List(LSDRead("Customs"));
        integer max=llGetListLength(cTemp);
        i=0;
        string cmd;
        while(i<max)
        {
            cmd=llStringTrim(llList2String(cTemp,i),STRING_TRIM);
            //llMessageLinked(LINK_THIS,(integer)LSDRead("LastAuth"),cmd,(key)LSDRead("TimerSetterKey"));
            llMessageLinked(LINK_THIS,CMD_ZERO,cmd,(key)LSDRead("TimerSetterKey"));
            ++i;
            llSleep(0.3); //short sleep to ensure commands go in order.
        }
    }
    LSDWrite("TimerSetterKey","");
    LSDWrite("LastAuth","0");
    setText(FALSE);
    
}

//stuff for floating text, will be much simpler with LSD elsewhere.
integer g_iTitlerActive;
vector g_vTitlerColor=<1,1,1>;
integer g_iTextPrim;
integer g_iTitlerOffset=8;
ScanFloatText()
{
    integer end = llGetNumberOfPrims();
    integer i;
    while(i<end)
    {
        ++i;
        string Params = (string)llGetLinkPrimitiveParams(i, [PRIM_NAME,PRIM_DESC]);
        if(llSubStringIndex(Params, "FloatText")!=-1)
        {
            g_iTextPrim = i;
            return;
        }
    }
    g_iTextPrim=LINK_THIS;
}       
setText(integer on)
{
    if(g_iTitlerActive) return;
    string msg;
    if(on==TRUE && LSDRead("TimerActive")=="1")
    {
        integer timeleft=(integer)LSDRead("LockTime")-(integer)llGetTime();
        timeleft=llRound((float)timeleft/60)*60; //Round to nearest minute as we only update each minute
        msg="Timer:\n"+timeDisplay(timeleft)+"  remaining.";
        integer i;
        while(i<g_iTitlerOffset)
        {
            ++i;
            msg+=" \n";
        }
    }
    llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT, msg, g_vTitlerColor, 1]);
}
    
integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;


integer g_iCollarActive;
integer g_iCatchup; //set if timer expires while collar not active.
default
{
    on_rez(integer iNum)
    {
        g_iCollarActive=FALSE;
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
        if(LSDRead("TimerActive")=="1") llSetTimerEvent(30); // recalc in timer, but let's leave a boot time buffer.
    }
    changed(integer change)
    {
        if (change & CHANGED_OWNER) llResetScript();
        if (change & CHANGED_LINK) ScanFloatText();
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        reset();
        ScanFloatText();
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),""); 
    }
    

    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE)
            UserCommand(iNum, sStr, kID);
        else if (iNum == DIALOG_TIMEOUT) 
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        }
         else if(iNum == LM_SETTING_RESPONSE)
         {
            if(sStr=="titler_show=1") g_iTitlerActive=TRUE;
            else if(llSubStringIndex(sStr,"titler_color")==0)
            {
                g_vTitlerColor=(vector)llGetSubString(sStr,13,-1);
                llSleep(1); // buffer because titler will clear title
                if(LSDRead("TimerActive")=="1" && LSDRead("Titler")=="1" && g_iTitlerActive==FALSE) setText(TRUE);
            }
            else if(llSubStringIndex(sStr,"titler_offset")==0)
            {
                g_iTitlerOffset=(integer)llGetSubString(sStr,14,-1);
                llSleep(1); // buffer because titler will clear title
                if(LSDRead("TimerActive")=="1" && LSDRead("Titler")=="1" && g_iTitlerActive==FALSE) setText(TRUE);
            }
         }
         else if(iNum == LM_SETTING_DELETE)
         {
             if(sStr=="titler_show")
             {
                 g_iTitlerActive=FALSE;
                 llSleep(1); // buffer because titler will clear title
                 if(LSDRead("TimerActive")=="1" && LSDRead("Titler")=="1") setText(TRUE);
             }
        }
        else if(iNum == LSD_REQUEST) llMessageLinked(LINK_SET,LSD_RESPONSE,LSDPrefix,"");
        else if(iNum == AUTH_WEARERLOCKOUT)
        {
            llOwnerSay("You cannot currently access your collar due to wearer lockout being set on an active timer.");
        }
        else if(iNum == REBOOT && sStr=="reboot")
                llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
        else if(iNum == READY)
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        else if(iNum == STARTUP)
        {
            g_iCollarActive=TRUE;
            if(g_iCatchup)
            {
                g_iCatchup=FALSE;
                stopTimer(TRUE);
            }
        }
        else if(iNum == CMD_SAFEWORD && LSDRead("TimerActive")=="1") 
        {
            llOwnerSay("Timer deactivated due to safeword");
            stopTimer(FALSE);
        }
        else if(iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1)
            {
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                //integer iRespring=TRUE;
                
                if(sMenu == "timer~app")
                {
                    if(sMsg == UPMENU)
                    {
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                        return;
                    } 
                    string sCmd;
                    string f=llGetSubString(sMsg,0,0);
                    if(f=="□") sCmd=llGetSubString(sMsg,1,-1)+" on";
                    else if(f=="▣") sCmd=llGetSubString(sMsg,1,-1)+" off";
                    if(sCmd=="") sCmd=sMsg;
                    UserCommand(iAuth,g_sSubMenu+" "+sCmd+" remenu",kAv);
                    
                }
                else if(sMenu=="timer~timerset")
                {
                    if(sMsg==UPMENU) mainMenu(kAv,iAuth);
                    else
                    {
                        list t=llParseString2List(sMsg,[" "],[]);
                        integer ti=(integer)llList2String(t,0);
                        if(llGetSubString(llList2String(t,1),0,0)=="h") ti*=3600;
                        else if(llGetSubString(llList2String(t,1),0,0)=="m") ti*=60;
                        ti+=(integer)LSDRead("LockTime");
                        if(ti<0) ti=0;
                        LSDWrite("LockTime",(string)ti);
                        timerMenu(kAv,iAuth);
                    }
                }
                else if(sMenu=="timer~custom")
                {
                    sMsg=llStringTrim(sMsg,STRING_TRIM);
                    LSDWrite("Customs",sMsg);
                    llMessageLinked(LINK_THIS,NOTIFY,"0Timer custom commands changed to:\n"+llDumpList2String(llCSV2List(sMsg),"\n"),kAv);
                    mainMenu(kAv,iAuth);
                }
            }
        }
        else if (iNum==CMD_SAFEWORD)
        {
            llMessageLinked(LINK_THIS,NOTIFY,"0Timer reset due to safeword.","");
            stopTimer(FALSE);
        }
        else if(iNum == -99999)
            if(sStr == "update_active")llResetScript();
    }
    timer()
    {
        integer timeleft=(integer)LSDRead("LockTime")-(integer)llGetTime();
        if(timeleft<30) //let's not be too fussy
        {
            if(!g_iCollarActive) g_iCatchup=TRUE;
            else stopTimer(TRUE);
            llSetTimerEvent(0);
        }
        
        if(LSDRead("Titler")=="1" && g_iTitlerActive==FALSE) setText(TRUE);
    }
   
}
