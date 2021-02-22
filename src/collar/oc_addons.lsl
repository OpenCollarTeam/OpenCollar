
/*
This file is a part of OpenCollar.
Copyright ©2021


: Contributors :

Aria (Tashia Redrose)
    *January 2021       -       Created oc_addons


et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/

string g_sParentMenu = "Main";
string g_sSubMenu = "Addons";

string COLLAR_VERSION = "8.0.3000";

string Auth2Str(integer iAuth){
    if(iAuth == CMD_OWNER)return "Owner";
    else if(iAuth == CMD_TRUSTED)return "Trusted";
    else if(iAuth == CMD_GROUP)return "Group";
    else if(iAuth == CMD_WEARER)return "Wearer";
    else if(iAuth == CMD_EVERYONE)return "Public";
    else if(iAuth == CMD_BLOCKED)return "Blocked";
    else if(iAuth == CMD_NOACCESS)return "No Access";
    else return "Unknown = "+(string)iAuth;
}

integer in_range(key kID){
    if(!g_iLimitRange)return TRUE;
    if(kID == g_kWearer)return TRUE;
    else{
        vector pos = llList2Vector(llGetObjectDetails(kID, [OBJECT_POS]),0);
        if(llVecDist(llGetPos(),pos) <=20.0)return TRUE;
        else return FALSE;
    }
}

integer CalcAuth(key kID, integer iVerbose){
    string sID = (string)kID;
    // First check
    if(llGetListLength(g_lOwner) == 0 && kID==g_kWearer)
        return CMD_OWNER;
    else{
        if(llListFindList(g_lBlock,[sID])!=-1)return CMD_BLOCKED;
        if(llListFindList(g_lOwner, [sID])!=-1)return CMD_OWNER;
        if(llListFindList(g_lTrust,[sID])!=-1)return CMD_TRUSTED;
        if(g_kTempOwner == kID) return CMD_TRUSTED;
        if(kID==g_kWearer)return CMD_WEARER;
        if(in_range(kID) && iVerbose){
            if(g_kGroup!=NULL_KEY){
                if(llSameGroup(kID))return CMD_GROUP;
            }

            if(g_iPublic)return CMD_EVERYONE;
        } else if(!in_range(kID) && !iVerbose){
            if(g_iPublic)return CMD_EVERYONE;
        }else{
            if(iVerbose)
                llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% because you are out of range", kID);
        }
    }


    return CMD_NOACCESS;
}
key g_kGroup=NULL_KEY;
list g_lOwner;
integer NOTIFY = 1002;
list g_lBlock;
list g_lTrust;
key g_kTempOwner;
integer g_iPublic;
integer g_iLimitRange=1;

integer g_iAddons=TRUE;
integer API_CHANNEL = 0x60b97b5e;
integer GENERAL_API_CHANNEL = 0x60b97b5e;
//MESSAGE MAP
list g_lActiveListeners;
DoListeners(){

    integer i=0;
    integer end = llGetListLength(g_lActiveListeners);
    for(i=0;i<end;i++){
        llListenRemove(llList2Integer(g_lActiveListeners, i));
    }

    if(g_iAddons)
        g_lActiveListeners+=[llListen(API_CHANNEL, "","",""), llListen(GENERAL_API_CHANNEL, "", "", "scan")];
}


integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_BLOCKED = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
integer CMD_NOACCESS=599;

//integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

list StrideOfList(list src, integer stride, integer start, integer end)
{
    list l = [];
    integer ll = llGetListLength(src);
    if(start < 0)start += ll;
    if(end < 0)end += ll;
    if(end < start) return llList2List(src, start, start);
    while(start <= end)
    {
        l += llList2List(src, start, start);
        start += stride;
    }
    return l;
}

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

AddonsMenu(key kID, integer iAuth){
    integer i=0;
    integer end = llGetListLength(g_lAddons);
    list lOpts = [];
    for(i=0;i<end;i+=5){
        if(!llList2Integer(g_lAddons,i+4)){
            lOpts += llList2String( g_lAddons, i+1 );
        }
    }
    Dialog(kID, "[Addons]\n\nThese are addons you have worn, or rezzed that are compatible with OpenCollar and have requested collar access", lOpts, [UPMENU],0,iAuth,"addons");
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_WEARER) return;
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) AddonsMenu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0;
        //string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        //string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        //string sText;
        /// [prefix] g_sSubMenu sChangetype sChangevalue
        if(sStr == "kick_all_wearer_addons" && iNum == CMD_OWNER){
            integer X =0;
            integer x_end = llGetListLength(g_lAddons);
            for(X=0;X<x_end;X+=4){
                key kAddon = (key)llList2String(g_lAddons,X);
                if(llGetOwnerKey(kAddon)==g_kWearer){
                    // -> Kick the addon
                    SayToAddonX(kAddon, "dc", 0, "", llGetOwner());
                    g_lAddons = llDeleteSubList(g_lAddons, X, X+4);
                    X=-1;
                    x_end = llGetListLength(g_lAddons);
                }
            }
        }
    }
}

list g_lAddonFiltered = [];
integer MENUNAME_REMOVE = 3003;

integer g_iWearerAddonLimited=TRUE;
integer g_iPendingNoMenu;
string g_sPendingAddonOptin;
integer g_iWearerAddons=TRUE;
SayToAddon(string pkt, integer iNum, string sStr, key kID){
    llRegionSay(API_CHANNEL, llList2Json(JSON_OBJECT, ["addon_name", "OpenCollar", "pkt_type", pkt, "iNum", iNum, "sMsg", sStr, "kID", kID]));
}
SayToAddonX(key k, string pkt, integer iNum, string sStr, key kID){
    llRegionSayTo(k, API_CHANNEL, llList2Json(JSON_OBJECT, ["addon_name", "OpenCollar", "pkt_type", pkt, "iNum", iNum, "sMsg", sStr, "kID", kID]));
}
list g_lAddons;
key g_kAddonPending;
string g_sAddonName;
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
integer g_iLocked=FALSE;

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

integer SENSORDIALOG = -9003;
integer SAY = 1004;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        g_lAddonFiltered = [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG];
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == REBOOT){
            if(sStr == "reboot"){
                llResetScript();
            }
        } else if(iNum == READY){
            llMessageLinked(LINK_SET, ALIVE, llGetScriptName(), "");
        } else if(iNum == STARTUP){
            state active;
        }
    }
}
state active
{
    on_rez(integer t){
        if(llGetOwner()!=g_kWearer) llResetScript();
    }
    state_entry()
    {
        g_kWearer = llGetOwner();
        API_CHANNEL = ((integer)("0x"+llGetSubString((string)llGetOwner(),0,8)))+0xf6eb-0xd2;
        DoListeners();

        SayToAddon("dc", 0, "", llGetOwner());
        SayToAddon("online", 0, "", llGetOwner());
        llSetTimerEvent(15);

    }

    timer(){


        if(llGetTime()>=60){
            // flush the alive addons and ping all addons
            llResetTime();
            integer deadStamp = (5*60);

            integer i=0;
            integer end = llGetListLength(g_lAddons);
            for(i=0;i<end;i+=5){
                integer lastSeen = (integer)llList2String(g_lAddons, i+2);
                if(llGetUnixTime()>lastSeen+deadStamp){
                    SayToAddonX((key)llList2String(g_lAddons,i), "dc", 0, "", llGetOwner());
                    llMessageLinked(LINK_SET, NOTIFY, "0Addon: "+llList2String(g_lAddons,i+1)+" has been removed because it has not been seen for 5 minutes or more.", g_kWearer);
                    g_lAddons = llDeleteSubList(g_lAddons, i, i+4);
                    i=-4; // if we change the stride of the list this must be updated
                    end=llGetListLength(g_lAddons);
                }
            }
        }
    }

    listen(integer c, string n,key i,string m){
        if(c==API_CHANNEL){
            //llWhisper(0, m);
            // All addons as of 8.0.00004 must include a ping and pong. This lets the collar know an addon is alive and not to automatically remove it.
            // Addon key will be placed in a temporary list that will be cleared once the timer checks over all the information.
            string PacketType = llJsonGetValue(m,["pkt_type"]);

            if(PacketType=="ping" && llJsonGetValue(m,["kID"])==(string)llGetKey()){
                //llSay(0, "Alive signal seen from addon: "+(string)i);
                integer index = llListFindList(g_lAddons, [i]);
                if(index==-1){
                    return;
                } else {
                    g_lAddons = llListReplaceList(g_lAddons, [llGetUnixTime()], index+2, index+2);
                    SayToAddonX(i, "pong", 0, "", llGetKey());
                }
                return;
            } else if(PacketType == "from_collar")return; // We should never listen to another collar's LMs, wearer should not be wearing more than one anyway.
            else if(PacketType == "online"){
                // this is a initial handshake
                if(llJsonGetValue(m,["kID"])==(string)llGetOwner()){

                    // begin to pass stuff to link messages!
                    // first- Check if a pairing was done with this addon, if not ask the user for confirmation, add it to Addons, and then move on
                    integer noMenu = (integer)llJsonGetValue(m,["noMenu"]);
                    if(noMenu!= 1)noMenu=0;

                    if(llListFindList(g_lAddons, [i])==-1 && llGetOwnerKey(i)!=g_kWearer){
                        integer AddonOwnerAuth = CalcAuth(llGetOwnerKey(i),FALSE);
                        if(AddonOwnerAuth == CMD_OWNER || AddonOwnerAuth == CMD_TRUSTED){

                            g_lAddons += [i, llJsonGetValue(m,["addon_name"]), llGetUnixTime(), llJsonGetValue(m,["optin"]), noMenu];
                            SayToAddonX(i, "approved", 0, "", "");
                            llMessageLinked(LINK_SET, NOTIFY, "0Addon connected successfully: "+llJsonGetValue(m,["addon_name"]), g_kWearer);
                        }
                        else{
                            g_kAddonPending = i;
                            g_sPendingAddonOptin = llJsonGetValue(m,["optin"]);
                            g_sAddonName = llJsonGetValue(m,["addon_name"]);
                            g_iPendingNoMenu=noMenu;
                            Dialog(g_kWearer, "[ADDON]\n\nAn object named: "+n+"\nAddon Name: "+g_sAddonName+"\nOwned by: secondlife:///app/agent/"+(string)llGetOwnerKey(i)+"/about\n\nHas requested internal collar access. Grant it?", ["Yes", "No"],[],0,CMD_WEARER,"addon~add");
                            return;
                        }
                    }else if(llListFindList(g_lAddons, [i])==-1 && llGetOwnerKey(i) == g_kWearer){
                        // Add the addon and be done with
                        if(!g_iWearerAddons){
                            SayToAddonX(i, "denied", 0, "", "");
                            llMessageLinked(LINK_SET, NOTIFY, "0Addon ("+llJsonGetValue(m,["addon_name"])+") denied because wearer owned addons is disallowed by settings", g_kWearer);
                            return;
                        }
                        g_lAddons += [i, llJsonGetValue(m,["addon_name"]), llGetUnixTime(), llJsonGetValue(m,["optin"]), noMenu];
                        SayToAddonX(i, "approved", 0, "", "");
                        llMessageLinked(LINK_SET, NOTIFY, "0Addon connected successfully: "+llJsonGetValue(m,["addon_name"]), g_kWearer);
                    } else if(llListFindList(g_lAddons,[i])!=-1){
                        SayToAddonX(i, "approved", 0, "", "");
                    }
                }
            } else if(PacketType == "offline"){
                // unpair
                if(llJsonGetValue(m,["kID"])==(string)llGetOwner()){
                    integer iPos = llListFindList(g_lAddons, [i]);
                    if(iPos==-1)return;
                    else{
                        g_lAddons = llDeleteSubList(g_lAddons, iPos, iPos+4);
                    }
                }
            }
            else if(PacketType == "from_addon"){
                // begin to pass stuff to link messages!
                // first- Check if a pairing was done with this addon, if not ask the user for confirmation, add it to Addons, and then move on

                if(llListFindList(g_lAddons, [i])==-1)return; //<--- deny further action. Addon not registered

                integer iNum = (integer)llJsonGetValue(m,["iNum"]);
                string sMsg = llJsonGetValue(m,["sMsg"]);
                key kID = llJsonGetValue(m,["kID"]);

                if((iNum == LM_SETTING_DELETE || iNum == LM_SETTING_SAVE)&& llGetOwnerKey(i)==g_kWearer && g_iWearerAddonLimited){
                    //string sTest = llToLower(sMsg);
                    if(llSubStringIndex(sMsg, "auth_")!=-1)return;
                    if(llSubStringIndex(sMsg,"intern_")!=-1)return;
                }

                llMessageLinked(LINK_SET, iNum, sMsg,kID);



                return;
            } else if(PacketType == "update"){
                if(llListFindList(g_lAddons, [i])==-1)return;

                string updateNums = llJsonGetValue(m,["optin"]);
                integer index = llListFindList(g_lAddons, [i]);
                g_lAddons = llListReplaceList(g_lAddons, [ updateNums], index+3, index+3);
            }
        } else if(c == GENERAL_API_CHANNEL){
            if(m=="scan"){
                llRegionSayTo(i,c,"ack|"+COLLAR_VERSION);
            }
        }
    }

    link_message(integer iSender,integer iNum,string sStr,key kID){

        if(llGetListLength(g_lAddons)>0){
            if(llListFindList(g_lAddonFiltered, [iNum])!=-1){
                // check if any addons want this link number
                // filtering list proposed by Caraway Ohmai via Discord
                integer i=0;
                integer say;
                integer end = llGetListLength (g_lAddons);
                for(i=0;i<end;i+=4){
                    //string Nums = llList2String(g_lAddons, i+3);
                    list Nums = llParseString2List( llList2String(g_lAddons, i+3), ["~"], []);
                    //if(llSubStringIndex(Nums, (string)iNum)!=-1){
                    if(llListFindList(Nums, [(string)iNum]) != -1){
                        say=1;
                    }
                }
                if(say)SayToAddon("from_collar", iNum, sStr,kID);
            }else
                SayToAddon("from_collar", iNum, sStr, kID);
//                llRegionSay(API_CHANNEL, llList2Json(JSON_OBJECT, ["addon_name", "OpenCollar", "iNum", iNum, "sMsg", sStr, "kID", kID, "pkt_type", "from_collar"]));
        }


        if(iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");
        else if(iNum == DIALOG_RESPONSE){
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if(iMenuIndex!=-1){
                string sMenu = llList2String(g_lMenuIDs, iMenuIndex+1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex-1, iMenuIndex-2+g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);


                if(sMenu == "addons"){
                    if(sMsg == UPMENU){
                        llMessageLinked(LINK_SET,0,"menu",kAv);
                    } else {
                        // Call this addon
                        llMessageLinked(LINK_SET, iAuth, "menu "+sMsg, kAv);
                    }
                } else if(sMenu == "addon~add"){
                    // process reply
                    if(sMsg == "No"){
                        SayToAddonX(g_kAddonPending, "denied", 0, "","");
                        return;
                    }else {
                        // Yes
                        SayToAddonX(g_kAddonPending, "approved", 0, "", "");
                        g_lAddons += [g_kAddonPending, g_sAddonName, llGetUnixTime(), g_sPendingAddonOptin, g_iPendingNoMenu];
                    }
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if(iNum == LM_SETTING_RESPONSE){
            // Detect here the Settings
            list lSettings = llParseString2List(sStr, ["_","="],[]);
            string sToken = llList2String(lSettings,0);
            string sVar = llList2String(lSettings,1);
            string sVal = llList2String(lSettings,2);

            if(sToken=="global"){
                if(sVar=="locked"){
                    g_iLocked=(integer)sVal;
                }else if(sVar == "weareraddon"){
                    g_iWearerAddons=(integer)sVal;
                } else if(sVar == "addonlimit"){
                    g_iWearerAddonLimited=(integer)sVal;
                } else if(sVar == "addons"){
                    g_iAddons = (integer)sVal;
                    DoListeners();
                }
            }else if(sToken == "auth"){
                if(sVar == "owner"){
                    g_lOwner=llParseString2List(sVal, [","],[]);
                } else if(sVar == "trust"){
                    g_lTrust = llParseString2List(sVal,[","],[]);
                } else if(sVar == "block"){
                    g_lBlock = llParseString2List(sVal,[","],[]);
                } else if(sVar == "public"){
                    g_iPublic=(integer)sVal;
                } else if(sVar == "group"){
                    g_kGroup = (key)sVal;
                } else if(sVar == "limitrange"){
                    g_iLimitRange = (integer)sVal;
                } else if(sVar == "tempowner"){
                    g_kTempOwner = (key)sVal;
                }
            }
        } else if(iNum == LM_SETTING_DELETE){
            // This is recieved back from settings when a setting is deleted
            list lPar = llParseString2List(sStr, ["_"],[]);
            string sToken = llList2String(lPar,0);
            string sVar = llList2String(lPar,1);
            if(sToken=="global"){
                if(sVar == "locked") {
                    g_iLocked=FALSE;

                } else if(sVar == "weareraddon"){
                    g_iWearerAddons=1;
                } else if(sVar == "addonlimit"){
                    g_iWearerAddonLimited=1;
                } else if(sVar == "addons"){
                    g_iAddons=1;
                }
            } else if(sToken == "auth"){
                if(sVar == "owner"){
                    g_lOwner=[];
                } else if(sVar == "trust"){
                    g_lTrust = [];
                } else if(sVar == "block"){
                    g_lBlock = [];
                } else if(sVar == "public"){
                    g_iPublic=FALSE;
                } else if(sVar == "group"){
                    g_kGroup = NULL_KEY;
                } else if(sVar == "limitrange"){
                    g_iLimitRange = TRUE;
                } else if(sVar == "tempowner"){
                    g_kTempOwner = "";
                }
            }
        } else if(iNum == REBOOT){

            SayToAddon("dc",0,"",llGetOwner());
            llResetScript();
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}
