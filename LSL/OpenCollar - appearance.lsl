////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                            OpenCollar - appearance                             //
//                                 version 3.988                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

//handle appearance menu
//handle saving position on detach, and restoring it on httpdb_response

string g_sSubMenu = "Size/Position";
string g_sParentMenu = "Appearance";

string CTYPE = "collar";

list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

string POSMENU = "Position";
string ROTMENU = "Rotation";
string SIZEMENU = "Size";

float g_fSmallNudge=0.0005;
float g_fMediumNudge=0.005;
float g_fLargeNudge=0.05;
float g_fNudge=0.005; // g_fMediumNudge;
float g_fRotNudge;

// SizeScale

list SIZEMENU_BUTTONS = [ "-1%", "-2%", "-5%", "-10%", "+1%", "+2%", "+5%", "+10%", "100%" ]; // buttons for menu
list g_lSizeFactors = [-1, -2, -5, -10, 1, 2, 5, 10, -1000]; // actual size factors
list g_lPrimStartSizes; // area for initial prim sizes (stored on rez)
integer g_iScaleFactor = 100; // the size on rez is always regarded as 100% to preven problem when scaling an item +10% and than - 10 %, which would actuall lead to 99% of the original size
integer g_iSizedByScript = FALSE; // prevent reseting of the script when the item has been chnged by the script

integer g_iAppLock = FALSE;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
//integer POPUP_HELP = 1001;

//integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
                            //str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel
//integer LM_SETTING_DELETE = 2003;//delete token from DB
//integer LM_SETTING_EMPTY = 2004;//sent by httpdb script when a token has no value in the db

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//string UPMENU = "â†‘";//when your menu hears this, give the parent menu
string UPMENU = "BACK";

key g_kWearer;

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
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    //Debug("Made menu.");
    return kID;
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

integer MinMaxUnscaled(vector vSize, float fScale)
{
    if (fScale < 1.0)
    {
        if (vSize.x <= 0.01) return TRUE;
        if (vSize.y <= 0.01) return TRUE;
        if (vSize.z <= 0.01) return TRUE;
    }
    else
    {
        if (vSize.x >= 10.0) return TRUE;
        if (vSize.y >= 10.0) return TRUE;
        if (vSize.z >= 10.0) return TRUE;
    }
    return FALSE;
}

integer MinMaxScaled(vector vSize, float fScale)
{
    if (fScale < 1.0)
    {
        if (vSize.x < 0.01) return TRUE;
        if (vSize.y < 0.01) return TRUE;
        if (vSize.z < 0.01) return TRUE;
    }
    else
    {
        if (vSize.x > 10.0) return TRUE;
        if (vSize.y > 10.0) return TRUE;
        if (vSize.z > 10.0) return TRUE;
    }
    return FALSE;
}


Store_StartScaleLoop()
{
    g_lPrimStartSizes = [];
    integer iPrimIndex;
    vector vPrimScale;
    vector vPrimPosit;
    list lPrimParams;
    if (llGetNumberOfPrims()<2) 
    {
        vPrimScale = llGetScale();
        g_lPrimStartSizes += vPrimScale.x;
    }
    else
    {
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ )
        {
            lPrimParams = llGetLinkPrimitiveParams( iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
            vPrimScale=llList2Vector(lPrimParams,0);
            vPrimPosit=(llList2Vector(lPrimParams,1)-llGetRootPosition())/llGetRootRotation();
            g_lPrimStartSizes += [vPrimScale,vPrimPosit];
        }
    }
    g_iScaleFactor = 100;
}

ScalePrimLoop(integer iScale, integer iRezSize, key kAV)
{
    integer iPrimIndex;
    float fScale = iScale / 100.0;
    list lPrimParams; 
    vector vPrimScale;
    vector vPrimPos;
    vector vSize;
    if (llGetNumberOfPrims()<2) 
    {
        vSize = llList2Vector(g_lPrimStartSizes,0);
        if (MinMaxUnscaled(llGetScale(), fScale) || !iRezSize)
        {
            Notify(kAV, "The object cannot be scaled as you requested; prims are already at minimum or maximum size.", TRUE);
            return;
        }
        else if (MinMaxScaled(fScale * vSize, fScale) || !iRezSize)
        {
            Notify(kAV, "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.", TRUE);
            return;
        }
        else
        {
            llSetScale(fScale * vSize); // not linked prim
        }
    }
    else
    {
        if  (!iRezSize)
        {
            // first some checking
            for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ )
            {
                lPrimParams = llGetLinkPrimitiveParams( iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
                vPrimScale = llList2Vector(g_lPrimStartSizes, (iPrimIndex  - 1)*2);

                if (MinMaxUnscaled(llList2Vector(lPrimParams,0), fScale))
                {
                    Notify(kAV, "The object cannot be scaled as you requested; prims are already at minimum or maximum size.", TRUE);
                    return;
                }
                else if (MinMaxScaled(fScale * vPrimScale, fScale))
                {
                    Notify(kAV, "The object cannot be scaled as you requested; prims would surpass minimum or maximum size.", TRUE);
                    return;
                }
            }
        }
        Notify(kAV, "Scaling started, please wait ...", TRUE);
        g_iSizedByScript = TRUE;
        for (iPrimIndex = 1; iPrimIndex <= llGetNumberOfPrims(); iPrimIndex++ )
        {
//            lPrimParams = llGetLinkPrimitiveParams(iPrimIndex, [PRIM_SIZE, PRIM_POSITION]);
            vPrimScale = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1)*2);
            vPrimPos = fScale * llList2Vector(g_lPrimStartSizes, (iPrimIndex - 1)*2+1);
            if (iPrimIndex == 1) 
            {
                llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale]);
            }
            else 
            {
                llSetLinkPrimitiveParamsFast(iPrimIndex, [PRIM_SIZE, vPrimScale, PRIM_POSITION, vPrimPos]);
            }
        }
        g_iScaleFactor = iScale;
        g_iSizedByScript = TRUE;
        Notify(kAV, "Scaling finished, the "+CTYPE+" is now on "+ (string)g_iScaleFactor +"% of the rez size.", TRUE);
    }
}


ForceUpdate()
{
    //workaround for https://jira.secondlife.com/browse/VWR-1168
    llSetText(".", <1,1,1>, 1.0);
    llSetText("", <1,1,1>, 1.0);
}

vector ConvertPos(vector pos)
{
    integer ATTACH = llGetAttached();
    vector out ;
    if (ATTACH == 1) { out.x = pos.y; out.y = pos.z; out.z = pos.x; }
    else if (ATTACH == 5 || ATTACH == 20 || ATTACH == 21 ) { out.x = pos.x; out.y = -pos.z; out.z = pos.y ; }
    else if (ATTACH == 6 || ATTACH == 18 || ATTACH == 19 ) { out.x = pos.x; out.y = pos.z; out.z = -pos.y; }
    else out = pos ;
    return out ;
}

AdjustPos(vector vDelta)
{
    if (llGetAttached())
    {
        llSetPos(llGetLocalPos() + ConvertPos(vDelta));
        ForceUpdate();
    }
}

vector ConvertRot(vector rot)
{
    integer ATTACH = llGetAttached();
    vector out ;
    if (ATTACH == 1) { out.x = rot.y; out.y = rot.z; out.z = rot.x; }
    else if (ATTACH == 5 || ATTACH == 20 || ATTACH == 21) { out.x = rot.x; out.y = -rot.z; out.z = rot.y; }
    else if (ATTACH == 6 || ATTACH == 18 || ATTACH == 19) { out.x = rot.x; out.y = rot.z; out.z = -rot.y; }
    else out = rot ;
    return out ;
}

AdjustRot(vector vDelta)
{
    if (llGetAttached())
    {
        llSetLocalRot(llGetLocalRot() * llEuler2Rot(ConvertRot(vDelta)));
        ForceUpdate();
    }
}

RotMenu(key kAv, integer iAuth)
{
    string sPrompt = "\nAdjust the "+CTYPE+"'s rotation.\n\nNOTE: Arrows refer to the neck joint.";
    list lMyButtons = ["tilt up ↻", "left ↷", "tilt left ↙", "tilt down ↺", "right ↶", "tilt right ↘"];// ria change
    key kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, ROTMENU];
    if (iMenuIndex == -1)
    {
        g_lMenuIDs += lAddMe;
    }
    else
    {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
    }
}

PosMenu(key kAv, integer iAuth)
{
    string sPrompt = "\nAdjust the "+CTYPE+"'s position.\n\nNOTE: Arrows refer to the neck joint.\n\nCurrent nudge strength is: ";
    list lMyButtons = ["left ←", "up ↑", "forward ↳", "right →", "down ↓", "backward ↲"];// ria iChange
    if (g_fNudge!=g_fSmallNudge) lMyButtons+=["▸"];
    else sPrompt += "▸";
    if (g_fNudge!=g_fMediumNudge) lMyButtons+=["▸▸"];
    else sPrompt += "▸▸";
    if (g_fNudge!=g_fLargeNudge) lMyButtons+=["▸▸▸"];
    else sPrompt += "▸▸▸";
    
    key kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, POSMENU];
    if (iMenuIndex == -1)
    {
        g_lMenuIDs += lAddMe;
    }
    else
    {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);    
    }
}

SizeMenu(key kAv, integer iAuth)
{
    string sPrompt = "\nAdjust the "+CTYPE+"'s scale.\n\nIt is based on the size the "+CTYPE+" has upon rezzing. You can change back to this size by using '100%'.\n\nCurrent size: " + (string)g_iScaleFactor + "%\n\nWARNING: Make a backup copy of your "+CTYPE+" first! Considering the massive variation of designs, this feature is not granted to work in all cases. Possible rendering bugs mean having to right-click your "+CTYPE+" first to see the actual result.";
    key kMenuID = Dialog(kAv, sPrompt, SIZEMENU_BUTTONS, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, SIZEMENU];
    if (iMenuIndex == -1)
    {
        g_lMenuIDs += lAddMe;
    }
    else
    {
        g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
    }
    //Debug("FreeMem: " + (string)llGetFreeMemory());
}

DoMenu(key kAv, integer iAuth)
{
    list lMyButtons ;
    string sPrompt;
    if (g_iAppLock && iAuth != COMMAND_OWNER) {
        sPrompt = "\nThe appearance of the "+CTYPE+" has been locked.\n\nAn owner must unlock it to allow modification.";        
    } else {
        sPrompt = "\nChange the looks, adjustment and size of your "+CTYPE+".\n\nwww.opencollar.at/appearance";
        lMyButtons = [POSMENU, ROTMENU, SIZEMENU]; //["Position", "Rotation", "Size"];
    }
    
    key kMenuID = Dialog(kAv, sPrompt, lMyButtons, [UPMENU], 0, iAuth);
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kAv]);
    list lAddMe = [kAv, kMenuID, g_sSubMenu];
    if (iMenuIndex == -1) g_lMenuIDs += lAddMe;
    else g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);    
}

UserCommand(integer iNum, string sStr, key kID) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sValue = llToLower(llList2String(lParams, 1));
    if (sCommand == "menu" && llGetSubString(sStr, 5, -1) == g_sSubMenu)
    {
        //someone asked for our menu
        //give this plugin's menu to id
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the "+CTYPE+"'s appearance.", FALSE);
            llMessageLinked(LINK_SET, iNum, "menu " + g_sParentMenu, kID);
        }
        else DoMenu(kID, iNum);
    } else if (sCommand=="lockappearance") {
        g_iAppLock=(integer)sValue;
    } else if (sStr == "appearance")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the "+CTYPE+"'s appearance.", FALSE);
        }
        else DoMenu(kID, iNum);
    }
    else if (sStr == "rotation")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the "+CTYPE+"'s rotation.", FALSE);
        }
        else if (g_iAppLock)
        {
            Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
            DoMenu(kID, iNum);
        }
        else RotMenu(kID, iNum);
        }
    else if (sStr == "position")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the "+CTYPE+"'s position.", FALSE);
        }
        else if (g_iAppLock)
        {
            Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
            DoMenu(kID, iNum);
        }
        else PosMenu(kID, iNum);
    }
    else if (sStr == "size")
    {
        if (kID!=g_kWearer && iNum!=COMMAND_OWNER)
        {
            Notify(kID,"You are not allowed to change the "+CTYPE+"'s size.", FALSE);
        }
        else if (g_iAppLock)
        {
            Notify(kID,"The appearance of the "+CTYPE+" is locked. You cannot access this menu now!", FALSE);
            DoMenu(kID, iNum);
        }
        else SizeMenu(kID, iNum);
    }
}

default {
    on_rez(integer iParam) {
        llResetScript();
    }

    state_entry() {
        //llSetMemoryLimit(65536);  //this script needs to be profiled, and its memory limited
        g_kWearer = llGetOwner();       
        g_fRotNudge = PI / 32.0;//have to do this here since we can't divide in a global var declaration   

        Store_StartScaleLoop();
        //Debug("Starting");
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        }
        else if (iNum >= COMMAND_OWNER && iNum <= COMMAND_WEARER)
        {
            UserCommand( iNum, sStr, kID);
        }
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["="], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            if (sToken == "Appearance_Lock") g_iAppLock = (integer)sValue;
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                  
                if (sMenuType == g_sSubMenu)
                {
                    if (sMessage == UPMENU) llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == POSMENU) PosMenu(kAv, iAuth);
                    else if (sMessage == ROTMENU) RotMenu(kAv, iAuth);
                    else if (sMessage == SIZEMENU) SizeMenu(kAv, iAuth);
                }
                else if (sMenuType == POSMENU)
                {
                    if (sMessage == UPMENU)
                    {
                        DoMenu(kAv, iAuth);
                        return;
                    }
                    else if (llGetAttached())
                    {
                        if (sMessage == "forward ↳") AdjustPos(<g_fNudge, 0, 0>);
                        else if (sMessage == "left ←") AdjustPos(<0, g_fNudge, 0>);
                        else if (sMessage == "up ↑") AdjustPos(<0, 0, g_fNudge>);
                        else if (sMessage == "backward ↲") AdjustPos(<-g_fNudge, 0, 0>);
                        else if (sMessage == "right →") AdjustPos(<0, -g_fNudge, 0>);
                        else if (sMessage == "down ↓") AdjustPos(<0, 0, -g_fNudge>);
                        else if (sMessage == "▸") g_fNudge=g_fSmallNudge;
                        else if (sMessage == "▸▸") g_fNudge=g_fMediumNudge;
                        else if (sMessage == "▸▸▸") g_fNudge=g_fLargeNudge;
                    }
                    else Notify(kAv, "Sorry, position can only be adjusted while worn",FALSE);
                    PosMenu(kAv, iAuth);                    
                }
                else if (sMenuType == ROTMENU)
                {
                    if (sMessage == UPMENU)
                    {
                        DoMenu(kAv, iAuth);
                        return;
                    }
                    else if (llGetAttached())
                    {
                        if (sMessage == "tilt right ↘") AdjustRot(<g_fRotNudge, 0, 0>);
                        else if (sMessage == "tilt up ↻") AdjustRot(<0, g_fRotNudge, 0>);
                        else if (sMessage == "left ↶") AdjustRot(<0, 0, g_fRotNudge>);
                        else if (sMessage == "right ↷") AdjustRot(<0, 0, -g_fRotNudge>);
                        else if (sMessage == "tilt left ↙") AdjustRot(<-g_fRotNudge, 0, 0>);
                        else if (sMessage == "tilt down ↺") AdjustRot(<0, -g_fRotNudge, 0>);
                    }
                    else Notify(kAv, "Sorry, position can only be adjusted while worn", FALSE);
                    RotMenu(kAv, iAuth);                     
                }
                else if (sMenuType == SIZEMENU)
                {
                    if (sMessage == UPMENU)
                    {
                        DoMenu(kAv, iAuth);
                        return;
                    }
                    else
                    {
                        integer iMenuCommand = llListFindList(SIZEMENU_BUTTONS, [sMessage]);
                        if (iMenuCommand != -1)
                        {
                            integer iSizeFactor = llList2Integer(g_lSizeFactors, iMenuCommand);
                            if (iSizeFactor == -1000)
                            {
                                // ResSize requested
                                if (g_iScaleFactor == 100)
                                {
                                    Notify(kAv, "Resizing canceled; the "+CTYPE+" is already at original size.", FALSE); 
                                }
                                else
                                {
                                    ScalePrimLoop(100, TRUE, kAv);
                                }
                            }
                            else
                            {
                                ScalePrimLoop(g_iScaleFactor + iSizeFactor, FALSE, kAv);
                            }
                        }
                        SizeMenu(kAv, iAuth);
                    }
                }
            }            
        }
        else if (iNum == DIALOG_TIMEOUT)
        {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (iMenuIndex != -1)
            {
                //remove stride from g_lMenuIDs
                //we have to subtract from the index because the dialog id comes in the middle of the stride
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                          
            }            
        }
    } 
   
    timer()
    {
        // the timer is needed as the changed_size even is triggered twice
        llSetTimerEvent(0);
        if (g_iSizedByScript)
            g_iSizedByScript = FALSE;
    }
    
    changed(integer iChange)
    {
        if (iChange & (CHANGED_SCALE))
        {
            if (g_iSizedByScript)
            // the item had ben rescaled by the script, do NOT reset the script and store new positions
            {
                // ignore the event and trigger timer to reset flag. needed as we got the event twice after scaling
                llSetTimerEvent(0.5);
            }
            else
            // it was a user change, so we have to store the basic values again
            {
                Store_StartScaleLoop();
            }
        }
        if (iChange & (CHANGED_SHAPE | CHANGED_LINK))
        {
            Store_StartScaleLoop();
        }
/*
        if (iChange & CHANGED_REGION) {
            if (g_iProfiled) {
                llScriptProfiler(1);
                Debug("profiling restarted");
            }
        }
*/
    }
 }
