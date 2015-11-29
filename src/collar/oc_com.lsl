//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                         Communicator - 151115.1                          //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Nandana Singh, Garvin Twine, Cleo Collins,    //
//  Master Starship, Satomi Ahn, Joy Stipe, Wendy Starfall, littlemousy,    //
//  Romka Swallowtail, Sumi Perl et al.                                     //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//         github.com/OpenCollar/opencollar/tree/master/src/collar          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

integer g_iPrivateListenChan = 1;
integer g_iPublicListenChan = TRUE;
string g_sPrefix = ".";

integer g_iLockMeisterChan = -8888;

integer g_iPublicListener;
integer g_iPrivateListener;
integer g_iLockMeisterListener;
integer g_iLeashPrim;

integer g_iHUDListener;
integer g_iHUDChan;

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;

//integer POPUP_HELP = 1001;
integer NOTIFY=1002;
integer NOTIFY_OWNERS=1003;
//integer SAY = 1004;
integer LINK_AUTH = 2;
integer LINK_DIALOG = 3;
integer LINK_SAVE = 5;
integer REBOOT = -1000;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
//integer LM_SETTING_EMPTY = 2004;

//integer MENUNAME_REQUEST = 3000;
//integer MENUNAME_RESPONSE = 3001;

integer TOUCH_REQUEST = -9500;
integer TOUCH_CANCEL = -9501;
integer TOUCH_RESPONSE = -9502;
integer TOUCH_EXPIRE = -9503;

string g_sSafeWord = "RED";

//added for attachment auth
integer g_iInterfaceChannel;
integer g_iListenHandleAtt;

integer AUTH_REQUEST = 600;
integer AUTH_REPLY = 601;

key g_kWearer;
//string g_sSettingToken = "com_";
string g_sGlobalToken = "global_";
string g_sDeviceName;
string g_sWearerName;
//list g_lOwners;

//globlals for supporting touch requests
list g_lTouchRequests; // 4-strided list in form of touchid, recipient, flags, auth level
integer g_iStrideLength = 4;

integer FLAG_TOUCHSTART = 0x01;
integer FLAG_TOUCHEND = 0x02;

integer g_iNeedsPose = FALSE;  // should the avatar be forced into a still pose for making touching easier
string g_sPOSE_ANIM = "turn_180";

integer g_iTouchNotify = FALSE;  // for Touch Notify

list g_lCore5Scripts = [2,"oc_auth",3,"oc_dialog",4,"oc_rlvsys",5,"oc_settings",6,"oc_anim",6,"oc_couples"];
list g_lFoundCore5Scripts;
integer INTEGRITY = -1050;
/*integer g_iProfiled;
Debug(string sStr) {
    //if you delete the first // from the preceeding and following  lines,
    //  profiling is off, debug is off, and the compiler will remind you to
    //  remove the debug calls from the code, we're back to production mode
    if (!g_iProfiled){
        g_iProfiled=1;
        llScriptProfiler(1);
    }
    llOwnerSay(llGetScriptName() + "(min free:"+(string)(llGetMemoryLimit()-llGetSPMaxMemory())+")["+(string)llGetFreeMemory()+"] :\n" + sStr);
}*/

string NameURI(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}

//functions from touch script
ClearUser(key kRCPT, integer iNotify) {
    //find any strides belonging to user and remove them
    integer iIndex = llListFindList(g_lTouchRequests, [kRCPT]);
    while (~iIndex) {
        if (iNotify) {
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
    for (iTrig = 0; iTrig < iNTrigs; iTrig+=g_iStrideLength) {
        if (llList2Key(g_lTouchRequests, iTrig + 1) == kToucher) {
            integer iTrigFlags = llList2Integer(g_lTouchRequests, iTrig + 2);
            if (((iTrigFlags & FLAG_TOUCHSTART) && sType == "touchstart")
                ||((iTrigFlags & FLAG_TOUCHEND)&& sType == "touchend")) {
                integer iAuth = llList2Integer(g_lTouchRequests, iTrig + 3);
                string sReply = (string) kToucher + "|" + (string) iAuth + "|" + sType +"|"+ (string) iLinkNumber;
                llMessageLinked(LINK_THIS, TOUCH_RESPONSE, sReply, llList2Key(g_lTouchRequests, iTrig));
            }
            if (sType =="touchend") ClearUser(kToucher, FALSE);
            return;
        }
    }

    string sDesc = llDumpList2String(llGetLinkPrimitiveParams(iLinkNumber,[PRIM_DESC])+llGetLinkPrimitiveParams(LINK_ROOT,[PRIM_DESC]),"~");

    list lDescTokens = llParseStringKeepNulls(sDesc, ["~"], []);
    integer iNDescTokens = llGetListLength(lDescTokens);
    integer iDescToken;
    for (iDescToken = 0; iDescToken < iNDescTokens; iDescToken++) {
        string sDescToken = llList2String(lDescTokens, iDescToken);
        if (sDescToken == sType || sDescToken == sType+":" || sDescToken == sType+":none") return;
        else if (!llSubStringIndex(sDescToken, sType+":")) {
            string sCommand = llGetSubString(sDescToken, llStringLength(sType)+1, -1);
            if (sCommand != "") llMessageLinked(LINK_AUTH, CMD_ZERO, sCommand, kToucher);
            return;
        }
    }
    if (sType == "touchstart") {
        llMessageLinked(LINK_AUTH, CMD_ZERO, "menu", kToucher);
        if (g_iTouchNotify && kToucher!=g_kWearer)
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n\nsecondlife:///app/agent/"+(string)kToucher+"/about touched your %DEVICETYPE%.\n",g_kWearer);
    }
}

UserCommand(key kID, integer iAuth, string sStr) {
    if (sStr == "ping") { // ping from an object, we answer to it on the object channel
        llRegionSayTo(kID,g_iHUDChan,(string)g_kWearer+":pong"); // sim wide response to owner hud
        return;
    }
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llList2String(lParams, 1); //llToLower(llList2String(lParams, 1));
    if (iAuth == CMD_OWNER || kID == g_kWearer) {  //handle changing prefix and channel from owner
        if (sCommand == "prefix") {
            if (sValue == "") {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n%WEARERNAME%'s prefix is \"%PREFIX%\"",kID);
                return;
            } else if (sValue == "reset") {
                g_sPrefix = llToLower(llGetSubString(llKey2Name(llGetOwner()), 0,1));
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sGlobalToken+"prefix", "");
            } else {
                g_sPrefix = sValue;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken+"prefix=" + g_sPrefix, "");
            }
            llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken+"prefix=" + g_sPrefix, "");
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"\n%WEARERNAME%'s prefix is \"%PREFIX%\".\nTouch the %DEVICETYPE% or say \"%PREFIX% menu\" for the main menu.\nSay '\"%PREFIX% help\" for a list of chat commands.",kID);
        }
        else if (sCommand == "device" && sValue == "name") {
            string sMessage;
            string sObjectName = llGetObjectName();
            string sCmdOptions = llDumpList2String(llDeleteSubList(lParams,0,1), " ");
            if (sValue == "") {
                sMessage = "\n"+sObjectName+"'s current device name is \"" + g_sDeviceName + "\".\nDevice Name command help:\n%PREFIX% device name [newname|reset]\n";
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMessage,kID);
            } else if (sCmdOptions == "reset") {
                g_sDeviceName = llGetObjectDesc();
                if (g_sDeviceName == "" || g_sDeviceName =="(No Description)") g_sDeviceName = llGetObjectName();
                sMessage = "The device name is reset to \""+g_sDeviceName+"\".";
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sGlobalToken+"DeviceName", "");
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken+"DeviceName="+g_sDeviceName, "");
            } else {
                g_sDeviceName = sCmdOptions;
                sMessage = sObjectName+"'s new device name is \""+ g_sDeviceName+"\".";
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken+"DeviceName="+g_sDeviceName, "");
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken+"DeviceName="+g_sDeviceName, "");
            }
            if (sValue) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMessage,kID);
        } else if (sCommand == "name") {
            if (iAuth != CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",kID);
            else {
                string sMessage;
                if (sValue=="") {  //Just let them know their current name
                    sMessage= "\n\nsecondlife:///app/agent/"+(string)g_kWearer+"/about's current name is " + g_sWearerName;
                    sMessage += "\nName command help: <prefix>name [newname|reset]\n";
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMessage,kID);
                } else if(sValue=="reset") { //unset Global_WearerName
                    sMessage=g_sWearerName+"'s name is reset to ";
                    g_sWearerName = NameURI(g_kWearer);
                    llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sGlobalToken+"WearerName", "");
                    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken+"WearerName="+g_sWearerName, "");
                    sMessage += g_sWearerName;
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMessage,kID);
                } else {
                    string sNewName = llDumpList2String(llList2List(lParams, 1,-1)," ") ;
                    sMessage=g_sWearerName+"'s new name is ";
                    g_sWearerName = "["+NameURI(g_kWearer)+" "+sNewName+"]";
                    sMessage += g_sWearerName;
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMessage,kID);
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken+"WearerName=" + sNewName, ""); //store
                    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken+"WearerName="+sNewName, "");
                }
            }
        } else if (sCommand == "channel") {
            integer iNewChan = (integer)sValue;
            if (sValue=="") {  //they left the param blank, report listener status
                string sMessage= "The %DEVICETYPE% is listening on channel";
                if (g_iPublicListenChan) sMessage += "s 0 and";
                sMessage += " "+(string)g_iPrivateListenChan+".";
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+sMessage,kID);
            } else if (iNewChan > 0) { //set new channel for private listener
                g_iPrivateListenChan =  iNewChan;
                llListenRemove(g_iPrivateListener);
                g_iPrivateListener = llListen(g_iPrivateListenChan, "", NULL_KEY, "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Now listening on channel " + (string)g_iPrivateListenChan + ".",kID);
                if (g_iPublicListenChan) { //save setting along with the state of thepublic listener (messy!)
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",TRUE", "");
                    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",TRUE", "");
                } else {
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",FALSE", "");
                    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",FALSE", "");
                }
            } else if (iNewChan == 0) { //enable public listener
                g_iPublicListenChan = TRUE;
                llListenRemove(g_iPublicListener);
                g_iPublicListener = llListen(0, "", NULL_KEY, "");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You enabled the public channel listener.\nTo disable it use -1 as channel command.",kID);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",TRUE", "");
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",TRUE", "");
            } else if (iNewChan == -1) {  //disable public listener
                g_iPublicListenChan = FALSE;
                llListenRemove(g_iPublicListener);
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You disabled the public channel listener.\nTo enable it use 0 as channel command, remember you have to do this on your channel /" +(string)g_iPrivateListenChan,kID);
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",FALSE", "");
                llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken + "channel=" + (string)g_iPrivateListenChan + ",FALSE", "");
            }
        } else if (kID == g_kWearer) {
            if (sCommand == "safeword") {
                if(llStringTrim(sValue, STRING_TRIM) != "") {
                    g_sSafeWord = sValue; // llList2String(lParams, 1);
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You set a new safeword: " + g_sSafeWord + ".",g_kWearer);
                    llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken + "safeword=" + g_sSafeWord, "");
                    llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken + "safeword=" + g_sSafeWord, "");
                } else
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Your safeword is: " + g_sSafeWord + ".",g_kWearer);
            }
            else if (sCommand == "busted") {
                if (sValue == "on") {
                    llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sGlobalToken+"touchNotify=1","");
                    g_iTouchNotify=TRUE;
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Touch notification is now enabled.",g_kWearer);
                } else if (sValue == "off") {
                    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,g_sGlobalToken+"touchNotify","");
                    g_iTouchNotify=FALSE;
                    llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Touch notification is now disabled.",g_kWearer);
                } else if (sValue == "") {
                    if (g_iTouchNotify) {
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Touch notification is now disabled.",g_kWearer);
                        llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,g_sGlobalToken+"touchNotify","");
                        g_iTouchNotify = FALSE;
                    } else {
                        llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"Touch notification is now enabled.",g_kWearer);
                        llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,g_sGlobalToken+"touchNotify=1","");
                        g_iTouchNotify = TRUE;
                    }
                }
            }
        }
    }
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
       // llSetMemoryLimit(49152);  //2015-05-06 (6180 bytes free)
        g_kWearer = llGetOwner();
        g_sWearerName = NameURI(g_kWearer);
        //g_sDeviceName = llGetObjectName();
        g_sDeviceName = llGetObjectDesc();
        if (g_sDeviceName == "" || g_sDeviceName =="(No Description)") g_sDeviceName = llGetObjectName();
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sGlobalToken+"DeviceName="+g_sDeviceName, "");
        llMessageLinked(LINK_SET, LM_SETTING_RESPONSE, g_sGlobalToken+"DeviceName="+g_sDeviceName, "");
        g_sPrefix = llToLower(llGetSubString(llKey2Name(g_kWearer), 0,1));
        //Debug("Default prefix: " + g_sPrefix);
        //inlined single use getOwnerChannel function
        g_iHUDChan = -llAbs((integer)("0x"+llGetSubString((string)g_kWearer,2,7)) + 1111);
        if (g_iHUDChan > -10000) g_iHUDChan -= 30000;
        g_iInterfaceChannel = (integer)("0x" + llGetSubString(g_kWearer,30,-1));
        if (g_iInterfaceChannel > 0) g_iInterfaceChannel = -g_iInterfaceChannel;
        g_iPublicListener = llListen(0, "", NULL_KEY, "");
        g_iPrivateListener = llListen(g_iPrivateListenChan, "", NULL_KEY, "");
        //g_iLockMeisterListener = llListen(g_iLockMeisterChan, "", NULL_KEY, (string)g_kWearer + "collar");
        g_iLockMeisterListener = llListen(g_iLockMeisterChan, "", "", "");
        //garvin attachments listener
        g_iListenHandleAtt = llListen(g_iInterfaceChannel, "", "", "");
        g_iHUDListener = llListen(g_iHUDChan, "", NULL_KEY ,"");
        integer iAttachPt = llGetAttached();
        if ((iAttachPt > 0 && iAttachPt < 31) || iAttachPt == 39) // if collar is attached to the body (thus excluding HUD and root/avatar center)
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION);
        //Debug("Starting");
    }

    attach(key kID) {
        if (kID == NULL_KEY)
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=No");
        else
            llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=Yes");
        integer iAttachPt = llGetAttached();
        if ((iAttachPt > 0 && iAttachPt < 31) || iAttachPt == 39) // if collar is attached to the body (thus excluding HUD and root/avatar center)
            llRequestPermissions(g_kWearer, PERMISSION_TRIGGER_ANIMATION);
    }

    listen(integer iChan, string sName, key kID, string sMsg)
    {
        if (iChan == g_iHUDChan) {
            //check for a ping, if we find one we request auth and answer in LMs with a pong
            if (sMsg==(string)g_kWearer + ":ping")
                llMessageLinked(LINK_AUTH, CMD_ZERO, "ping", llGetOwnerKey(kID));
            // it it is not a ping, it should be a command for use, to make sure it has to have the key in front of it
            else if (!llSubStringIndex(sMsg,(string)g_kWearer + ":")){
                sMsg = llGetSubString(sMsg, 37, -1);
                llMessageLinked(LINK_AUTH, CMD_ZERO, sMsg, llGetOwnerKey(kID));
            } else
                llMessageLinked(LINK_AUTH, CMD_ZERO, sMsg, llGetOwnerKey(kID));
            return;
        }
        if (iChan == g_iLockMeisterChan) {
            if(sMsg ==(string)g_kWearer+"collar")
                llSay(g_iLockMeisterChan,(string)g_kWearer + "collar ok");
            //new for LMV2
            if(sMsg == (string)g_kWearer+"|LMV2|RequestPoint|collar") {
    //this message is for us, it's claiming to be an LMV2 message, it's a "Request" message, and concerns the mooring_point we specified
     //message structure:   llGetOwner()|LMV2|RequestPoint|anchor_name
                if(g_iLeashPrim)
                    llRegionSayTo(kID, g_iLockMeisterChan, (string)g_kWearer+"|LMV2|ReplyPoint|collar|"+(string)llGetLinkKey(g_iLeashPrim));
                else
                    llRegionSayTo(kID, g_iLockMeisterChan, (string)g_kWearer+"|LMV2|ReplyPoint|collar|"+(string) llGetKey());
            }
            return;
        }
        if(llGetOwnerKey(kID) == g_kWearer) { // also works for attachments
            string sw = sMsg; // we'll have to shave pieces off as we go to test
            // safeword can be the safeword or safeword said in OOC chat "((SAFEWORD))"
            // and may include prefix
            if (llGetSubString(sw, 0, 3) == "/me ") sw = llGetSubString(sw, 4, -1);
            if (llGetSubString(sw, 0, 1) == "((" && llGetSubString(sw, -2, -1) == "))") sw = llGetSubString(sw, 2, -3);
            if (llSubStringIndex(sw, g_sPrefix)==0) sw = llGetSubString(sw, llStringLength(g_sPrefix), -1);
            if (sw == g_sSafeWord) {
                llMessageLinked(LINK_SET, CMD_SAFEWORD, "", "");
                llRegionSayTo(g_kWearer,g_iInterfaceChannel,"%53%41%46%45%57%4F%52%44");
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You used your safeword, your owners will be notified you did.",g_kWearer);
                llMessageLinked(LINK_DIALOG,NOTIFY_OWNERS,"Your sub %WEARERNAME% has used the safeword. Please check on their well-being in case further care is required.","");
                return;
            }
        }
        //added for attachment auth (garvin)
        if (iChan == g_iInterfaceChannel) {
            //Debug(sMsg);
            //do nothing if wearer isnt owner of the object
            if (llGetOwnerKey(kID) != g_kWearer) return;
            //play ping pong with the Sub AO
            if (sMsg == "OpenCollar?") llRegionSayTo(g_kWearer, g_iInterfaceChannel, "OpenCollar=Yes");
            else { // attachments can send auth request: llRegionSayTo(g_kWearer,g_InteraceChannel,"AuthRequest|UUID");
                if (llSubStringIndex(sMsg, "AuthRequest")==0) {
                    llMessageLinked(LINK_AUTH,AUTH_REQUEST,(string)kID+(string)g_iInterfaceChannel,llGetSubString(sMsg,12,-1));
                }
            }
        } else { //check for our prefix, or *
            if (!llSubStringIndex(sMsg, g_sPrefix)) sMsg = llGetSubString(sMsg, llStringLength(g_sPrefix), -1); //strip our prefix from command
            else if (!llSubStringIndex(sMsg, "/"+g_sPrefix)) sMsg = llGetSubString(sMsg, llStringLength(g_sPrefix)+1, -1); //strip our prefix plus a / from command
            else if (llGetSubString(sMsg, 0, 0) == "*") sMsg = llGetSubString(sMsg, 1, -1); //strip * (all collars wildcard) from command
            else if ((llGetSubString(sMsg, 0, 0) == "#") && (kID != g_kWearer)) sMsg = llGetSubString(sMsg, 1, -1); //strip # (all collars but me) from command
            else return;
            sMsg = llStringTrim(sMsg,STRING_TRIM_HEAD);
            if (kID == g_kWearer && llToLower(sMsg) == "verify") {
                llOwnerSay("Verifying core integrity...");
                llMessageLinked(LINK_ALL_OTHERS,INTEGRITY,"","");
                llSetTimerEvent(2);
                return;
            }
            //Debug("Got comand "+sMsg);
            llMessageLinked(LINK_AUTH, CMD_ZERO, sMsg, kID);
        }
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum >= CMD_OWNER && iNum <= CMD_WEARER) UserCommand(kID, iNum, sStr);
        else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == g_sGlobalToken+"prefix") {
                if (sValue != "") g_sPrefix=sValue;
            } else if (sToken == "leashpoint") g_iLeashPrim = (integer)sValue;
            else if (sToken == g_sGlobalToken+"DeviceName") g_sDeviceName = sValue;
            else if (sToken == g_sGlobalToken+"touchNotify") g_iTouchNotify = (integer)sValue; // for Touch Notify
            else if (sToken == g_sGlobalToken+"WearerName") {
                 if (llSubStringIndex(sValue, "secondlife:///app/agent"))
                    g_sWearerName = "["+NameURI(g_kWearer)+" " + sValue + "]";
            }
            else if (sToken == g_sGlobalToken+"safeword") g_sSafeWord = sValue;
            else if (sToken == g_sGlobalToken+"channel") {
                g_iPrivateListenChan = (integer)sValue;
                if (llGetSubString(sValue, llStringLength(sValue) - 5 , -1) == "FALSE") g_iPublicListenChan = FALSE;
                else g_iPublicListenChan = TRUE;
                llListenRemove(g_iPublicListener);
                if (g_iPublicListenChan == TRUE) g_iPublicListener = llListen(0, "", NULL_KEY, "");
                llListenRemove(g_iPrivateListener);
                g_iPrivateListener = llListen(g_iPrivateListenChan, "", NULL_KEY, "");
            }
        } else if (iNum == TOUCH_REQUEST) {   //str will be pipe-delimited list with rcpt|flags|auth
            list lParams = llParseStringKeepNulls(sStr, ["|"], []);
            key kRCPT = (key)llList2String(lParams, 0);
            integer iFlags = (integer)llList2String(lParams, 1);
            integer iAuth = (integer)llList2String(lParams, 2);
            ClearUser(kRCPT, TRUE);
            g_lTouchRequests += [kID, kRCPT, iFlags, iAuth];
            if (g_iNeedsPose) llStartAnimation(g_sPOSE_ANIM);
        } else if (iNum == TOUCH_CANCEL) {
            integer iIndex = llListFindList(g_lTouchRequests, [kID]);
            if (~iIndex) {
                g_lTouchRequests = llDeleteSubList(g_lTouchRequests, iIndex, iIndex - 1 + g_iStrideLength);
                if (g_iNeedsPose && [] == g_lTouchRequests) llStopAnimation(g_sPOSE_ANIM);
            }
        } //needed to be the same ID that send earlier pings or pongs
        else if (iNum == AUTH_REPLY) llRegionSayTo(kID, g_iInterfaceChannel, sStr);
        else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if (iNum == INTEGRITY) g_lFoundCore5Scripts += [iSender,sStr];
    }

    touch_start(integer iNum) {
        //Debug("touched");
        sendCommandFromLink(llDetectedLinkNumber(0), "touchstart", llDetectedKey(0));
    }

    touch_end(integer iNum) {
        sendCommandFromLink(llDetectedLinkNumber(0), "touchend", llDetectedKey(0));
    }

    run_time_permissions(integer iPerm) {
        if (iPerm & PERMISSION_TRIGGER_ANIMATION) g_iNeedsPose = TRUE;
    }

    timer() {
        llSetTimerEvent(0);
        string sMessage;
        integer i;
        list lTemp;
        g_lFoundCore5Scripts = llListSort(g_lFoundCore5Scripts,2,TRUE);
        do {
            if (!~llListFindList(g_lFoundCore5Scripts,llList2List(g_lCore5Scripts,i+1,i+1)))
                sMessage += "\n"+llList2String(g_lCore5Scripts,i+1) + " not found!";
            else if (~llListFindList(g_lCore5Scripts,llList2List(g_lFoundCore5Scripts,i,i+1)))
                lTemp += "(verified)";
            else lTemp += "(corrupted)";
            i = i + 2;
        } while (i<=10);
        i = llGetLinkNumber();
        if (i != 1) sMessage += "\n"+"Link number: "+(string)i+" ⟶ oc_com\t(corrupted)";
        if (sMessage == "" && !~llListFindList(lTemp,["(corrupted)"])) {
            sMessage = "Core is optimal!";
            lTemp = [];
            g_lFoundCore5Scripts = [];
        } else {
            sMessage = "\n\nCore corruption detected:\n"+sMessage;
            if (i == 1) sMessage += "\n"+"Link number: "+(string)i+" ⟶ oc_com\t(verified)";
        }
        while (g_lFoundCore5Scripts) {
            sMessage += "\n"+"Link number: "+ llList2String(g_lFoundCore5Scripts,0)+" ⟶ "+llList2String(g_lFoundCore5Scripts,1)+"\t "+llList2String(lTemp,0);
            g_lFoundCore5Scripts = llDeleteSubList(g_lFoundCore5Scripts,0,1);
            lTemp = llDeleteSubList(lTemp,0,0);
        }
        llOwnerSay(sMessage);
    }

    changed(integer iChange) {
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
}
