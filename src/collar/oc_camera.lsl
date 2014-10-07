////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - camera                               //
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

//allows dom to set different camera mode
//responds to commands from modes list

key g_kWearer;
integer g_iLastNum;
string g_sMyMenu = "Camera";
string g_sParentMenu = "Apps";
key g_kMenuID;
string g_sCurrentMode = "default";
float g_fReapeat = 0.5;

//these 4 are used for syncing dom to us by broadcasting cam pos/rot
integer g_iSync2Me;//TRUE if we're currently dumping cam pos/rot iChanges to chat so the owner can sync to us
vector g_vCamPos;
rotation g_rCamRot;
integer g_rBroadChan;

//a 2-strided list in the form modename,camparams, where camparams is a serialized list
list g_lModes = [
"default", "|/?!@#|12|0",//[CAMERA_ACTIVE, FALSE]
"human", "|/?!@#|12|1|8/0.000000|9/0.000000|7/2.500000|6/0.050000|22|0|11/0.000000|0/20.000000|5/0.000000|21|0|10/0.000000|1@<0.000000, 0.000000, 0.350000>",
"1stperson", "|/?!@#|12|1|7/0.500000|1@<2.500000, 0.000000, 1.000000>", //CAMERA_ACTIVE, TRUE, CAMERA_DISTANCE, 0.5,CAMERA_FOCUS_OFFSET, <2.5,0,1.0>]]
"ass", "|/?!@#|12|1|7/0.500000",//[CAMERA_ACTIVE, TRUE, CAMERA_DISTANCE, 0.5]
"far", "|/?!@#|12|1|7/10.000000", //[CAMERA_ACTIVE, TRUE,CAMERA_DISTANCE, 10.0]]
"god", "|/?!@#|12|1|7/10.000000|0/80.000000", //[CAMERA_ACTIVE, TRUE,CAMERA_DISTANCE, 10.0,CAMERA_PITCH, 80.0]]
"ground", "|/?!@#|12|1|0/-15.000000",//[CAMERA_ACTIVE, TRUE, CAMERA_PITCH, -15.0]
"worm", "|/?!@#|12|1|7/0.500000|1@<0.000000, 0.000000, -0.750000>|0/-15.000000" //[CAMERA_ACTIVE, TRUE,CAMERA_DISTANCE, 0.5,CAMERA_FOCUS_OFFSET, <0,0,-0.75>, CAMERA_PITCH, -15.0]
];

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COMMAND_RLV_RELAY = 507;
integer COMMAND_SAFEWORD = 510;  // new for safeword
integer COMMAND_BLACKLIST = 520;

//integer SEND_IM = 1000; deprecated.  each script should send its own IMs now.  This is to reduce even the tiny bt of lag caused by having IM slave scripts
integer POPUP_HELP = 1001;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to settings store
                            //str must be in form of "token=value"
integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script will send responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from store
integer LM_SETTING_EMPTY = 2004;//sent when a token has no value in the settings store

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "BACK";
//string MORE = ">";
string g_sScript;

CamMode(string sMode)
{
    llClearCameraParams();
    integer iIndex = llListFindList(g_lModes, [sMode]);
    string lParams = llList2String(g_lModes, iIndex + 1);    
    llSetCameraParams(TightListTypeParse(lParams));  
    g_sCurrentMode = sMode;
}

ClearCam()
{
    if (llGetPermissions()&PERMISSION_CONTROL_CAMERA) llClearCameraParams();
    g_iLastNum = 0;    
    g_iSync2Me = FALSE;
    llMessageLinked(LINK_SET, LM_SETTING_DELETE, g_sScript + "all", "");    
}

CamFocus(vector g_vCamPos, rotation g_rCamRot)
{
    vector vStartPose = llGetCameraPos();    
    rotation rStartRot = llGetCameraRot();
    float fSteps = 8.0;
    //Keep fSteps a float, but make sure its rounded off to the nearest 1.0
    fSteps = (float)llRound(fSteps);
 
    //Calculate camera position increments
    vector vPosStep = (g_vCamPos - vStartPose) / fSteps;
 
    //Calculate camera rotation increments
    //rotation rStep = (g_rCamRot - rStartRot);
    //rStep = <rStep.x / fSteps, rStep.y / fSteps, rStep.z / fSteps, rStep.s / fSteps>;
 
 
    float fCurrentStep = 0.0; //Loop through motion for fCurrentStep = current step, while fCurrentStep <= Total steps
    for(; fCurrentStep <= fSteps; ++fCurrentStep)
    {
        //Set next position in tween
        vector vNextPos = vStartPose + (vPosStep * fCurrentStep);
        rotation rNextRot = Slerp( rStartRot, g_rCamRot, fCurrentStep / fSteps);
 
        //Set camera parameters
        llSetCameraParams([
            CAMERA_ACTIVE, 1, //1 is active, 0 is inactive
            CAMERA_BEHINDNESS_ANGLE, 0.0, //(0 to 180) degrees
            CAMERA_BEHINDNESS_LAG, 0.0, //(0 to 3) seconds
            CAMERA_DISTANCE, 0.0, //(0.5 to 10) meters
            CAMERA_FOCUS, vNextPos + llRot2Fwd(rNextRot), //Region-relative position
            CAMERA_FOCUS_LAG, 0.0 , //(0 to 3) seconds
            CAMERA_FOCUS_LOCKED, TRUE, //(TRUE or FALSE)
            CAMERA_FOCUS_THRESHOLD, 0.0, //(0 to 4) meters
            CAMERA_POSITION, vNextPos, //Region-relative position
            CAMERA_POSITION_LAG, 0.0, //(0 to 3) seconds
            CAMERA_POSITION_LOCKED, TRUE, //(TRUE or FALSE)
            CAMERA_POSITION_THRESHOLD, 0.0, //(0 to 4) meters
            CAMERA_FOCUS_OFFSET, ZERO_VECTOR //<-10,-10,-10> to <10,10,10> meters
        ]);
    }
}
 
rotation Slerp( rotation a, rotation b, float f ) {
    float fAngleBetween = llAngleBetween(a, b);
    if ( fAngleBetween > PI )
        fAngleBetween = fAngleBetween - TWO_PI;
    return a*llAxisAngle2Rot(llRot2Axis(b/a)*a, fAngleBetween*f);
}//Written by Francis Chung, Taken from http://forums.secondlife.com/showthread.php?p=536622

LockCam()
{
    llSetCameraParams([
        CAMERA_ACTIVE, TRUE,
        //CAMERA_POSITION, llGetCameraPos()
        CAMERA_POSITION_LOCKED, TRUE
    ]);  
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
} 

CamMenu(key kID, integer iAuth)
{
    string sPrompt = "\nCurrent camera mode is " + g_sCurrentMode + ".\n\nwww.opencollar.at/camera";
    list lButtons = ["CLEAR"];
    integer n;
    integer stop = llGetListLength(g_lModes);    
    for (n = 0; n < stop; n +=2)
    {
        lButtons += [Capitalize(llList2String(g_lModes, n))];
    }
    
    lButtons += ["FREEZE"];
    g_kMenuID = Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth);
}

string Capitalize(string sIn)
{
    return llToUpper(llGetSubString(sIn, 0, 0)) + llGetSubString(sIn, 1, -1);
}

string StrReplace(string sSrc, string sFrom, string sTo)
{//replaces all occurrences of 'sFrom' with 'sTo' in 'sSrc'.
    integer iLen = (~-(llStringLength(sFrom)));
    if(~iLen)
    {
        string  sBuffer = sSrc;
        integer iBufPos = -1;
        integer iToLen = (~-(llStringLength(sTo)));
        @loop;//instead of a while loop, saves 5 bytes (and run faster).
        integer iToPos = ~llSubStringIndex(sBuffer, sFrom);
        if(iToPos)
        {
//            iBufPos -= iToPos;
//            sSrc = llInsertString(llDeleteSubString(sSrc, iBufPos, iBufPos + iLen), iBufPos, sTo);
//            iBufPos += iToLen;
//            sBuffer = llGetSubString(sSrc, (-~(iBufPos)), 0x8000);
            sBuffer = llGetSubString(sSrc = llInsertString(llDeleteSubString(sSrc, iBufPos -= iToPos, iBufPos + iLen), iBufPos, sTo), (-~(iBufPos += iToLen)), 0x8000);
            jump loop;
        }
    }
    return sSrc;
}

//These TightListType functions allow serializing a list to a string, and deserializing it back, while preserving variable type information.  We use them so we can have a list of camera modes, where each mode is itself a list
integer TightListTypeLength(string sInput)
{
    string sSeperators = llGetSubString(sInput,(0),6);
    return ((llParseStringKeepNulls(llDeleteSubString(sInput,(0),5), [],[sInput=llGetSubString(sSeperators,(0),(0)),
           llGetSubString(sSeperators,1,1),llGetSubString(sSeperators,2,2),llGetSubString(sSeperators,3,3),
           llGetSubString(sSeperators,4,4),llGetSubString(sSeperators,5,5)]) != []) + (llSubStringIndex(sSeperators,llGetSubString(sSeperators,6,6)) < 6)) >> 1;
}
 
integer TightListTypeEntryType(string sInput, integer iIndex)
{
    string sSeperators = llGetSubString(sInput,(0),6);
    return llSubStringIndex(sSeperators, sInput) + ((sInput = llList2String(llList2List(sInput + llParseStringKeepNulls(llDeleteSubString(sInput,(0),5), [],[sInput=llGetSubString(sSeperators,(0),(0)), llGetSubString(sSeperators,1,1),llGetSubString(sSeperators,2,2),llGetSubString(sSeperators,3,3), llGetSubString(sSeperators,4,4),llGetSubString(sSeperators,5,5)]), (llSubStringIndex(sSeperators,llGetSubString(sSeperators,6,6)) < 6) << 1, -1),  iIndex << 1)) != "");
}
 
list TightListTypeParse(string sInput) {
    list lPartial;
    if(llStringLength(sInput) > 6)
    {
        string sSeperators = llGetSubString(sInput,(0),6);
        integer iPos = ([] != (lPartial = llList2List(sInput + llParseStringKeepNulls(llDeleteSubString(sInput,(0),5), [],[sInput=llGetSubString(sSeperators,(0),(0)), llGetSubString(sSeperators,1,1),llGetSubString(sSeperators,2,2),llGetSubString(sSeperators,3,3), llGetSubString(sSeperators,4,4),llGetSubString(sSeperators,5,5)]), (llSubStringIndex(sSeperators,llGetSubString(sSeperators,6,6)) < 6) << 1, -1)));
        integer iType = (0);
        integer iSubPos = (0);
        do
        {
            list s_Current = (list)(sInput = llList2String(lPartial, iSubPos= -~iPos));//TYPE_STRING || TYPE_INVALID (though we don't care about invalid)
            if(!(iType = llSubStringIndex(sSeperators, llList2String(lPartial,iPos))))//TYPE_INTEGER
                s_Current = (list)((integer)sInput);
            else if(iType == 1)//TYPE_FLOAT
                s_Current = (list)((float)sInput);
            else if(iType == 3)//TYPE_KEY
                s_Current = (list)((key)sInput);
            else if(iType == 4)//TYPE_VECTOR
                s_Current = (list)((vector)sInput);
            else if(iType == 5)//TYPE_ROTATION
                s_Current = (list)((rotation)sInput);
            lPartial = llListReplaceList(lPartial, s_Current, iPos, iSubPos);
        }while((iPos= -~iSubPos) & 0x80000000);
    }
    return lPartial;
}
 
string TightListTypeDump(list lInput, string sSeperators) {//This function is dangerous
    sSeperators += "|/?!@#$%^&*()_=:;~`'<>{}[],.\n\" qQxXzZ\\";
    string sCumulator = (string)(lInput);
    integer iCounter = (0);
    do
        if(~llSubStringIndex(sCumulator,llGetSubString(sSeperators,iCounter,iCounter)))
            sSeperators = llDeleteSubString(sSeperators,iCounter,iCounter);
        else
            iCounter = -~iCounter;
    while(iCounter<6);
    sSeperators = llGetSubString(sSeperators,(0),5);
 
        sCumulator =  "";
 
    if((iCounter = (lInput != [])))
    {
        do
        {
            integer iType = ~-llGetListEntryType(lInput, iCounter = ~-iCounter);
 
            sCumulator = (sCumulator = llGetSubString(sSeperators,iType,iType)) + llList2String(lInput,iCounter) + sCumulator;
        }while(iCounter);
    }
    return sSeperators + sCumulator;
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

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

SaveSetting(string sToken)
{
    sToken = g_sScript + sToken;
    string sValue = (string)g_iLastNum;
    llMessageLinked(LINK_SET, LM_SETTING_SAVE, sToken + "=" + sValue, "");
}

ChatCamParams(integer chan)
{
    g_vCamPos = llGetCameraPos();
    g_rCamRot = llGetCameraRot();
    string sPosLine = StrReplace((string)g_vCamPos, " ", "") + " " + StrReplace((string)g_rCamRot, " ", ""); 
    //if not channel 0, say to whole region.  else just say locally   
    if (chan)
    {
        llRegionSay(chan, sPosLine);                    
    }
    else
    {
        llSay(chan, sPosLine);
    }
}

integer UserCommand(integer iNum, string sStr, key kID) // here iNum: auth value, sStr: user command, kID: avatar id
{
    if (iNum > COMMAND_WEARER || iNum < COMMAND_OWNER) return FALSE; // sanity check
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    string sValue = llList2String(lParams, 1);
    string sValue2 = llList2String(lParams, 2);
    if (sStr == "menu " + g_sMyMenu) {
        CamMenu(kID, iNum);
    }
    else if (sCommand == "cam" || sCommand == "camera")
    {
        if (sValue == "")
        {
            //they just said *cam.  give menu
            CamMenu(kID, iNum);
            return TRUE;
        }
        if (!(llGetPermissions() & PERMISSION_CONTROL_CAMERA))
        {
            Notify(kID, "Permissions error: Can not control camera.", FALSE);
            return TRUE;
        }
        if (g_iLastNum && iNum > g_iLastNum)
        {
            Notify(kID, "Sorry, cam settings have already been set by someone outranking you.", FALSE);
            return TRUE;
        }   
        Debug("g_iLastNum=" + (string)g_iLastNum);                        
        if (sValue == "clear")
        {
            ClearCam();
            Notify(kID, "Cleared camera settings.", TRUE);
        }
        else if (sValue == "freeze")
        {
            LockCam();
            Notify(kID, "Freezing current camera position.", TRUE);
            g_iLastNum = iNum;                    
            SaveSetting("freeze");                          
        }
        else if ((vector)sValue != ZERO_VECTOR && (vector)sValue2 != ZERO_VECTOR)
        {
            Notify(kID, "Setting camera focus to " + sValue + ".", TRUE);
            //CamFocus((vector)sValue, (vector)sValue2);
            g_iLastNum = iNum;                        
            Debug("newiNum=" + (string)iNum);
        }
        else
        {
            integer iIndex = llListFindList(g_lModes, [sValue]);
            if (iIndex != -1)
            {
                CamMode(sValue);
                g_iLastNum = iNum;
                Notify(kID, "Set " + sValue + " camera mode.", TRUE);
                SaveSetting(sValue);
            }
            else
            {
                Notify(kID, "Invalid camera mode: " + sValue, FALSE);
            }
        }
    } 
    else if (sCommand == "camto")
    {
        if (!g_iLastNum || iNum <= g_iLastNum)
        {
            CamFocus((vector)sValue, (rotation)sValue2);
            g_iLastNum = iNum;                    
        }
        else
        {
            Notify(kID, "Sorry, cam settings have already been set by someone outranking you.", FALSE);
        }
    }
    else if (sCommand == "camdump")
    {
        g_rBroadChan = (integer)sValue;
        integer g_fReapeat = (integer)sValue2;
        ChatCamParams(g_rBroadChan);
        if (g_fReapeat)
        {
            g_iSync2Me = TRUE;
            llSetTimerEvent(g_fReapeat);
        }
    }
    else if ((iNum == COMMAND_OWNER  || kID == g_kWearer) && sStr == "runaway")
    {
        ClearCam();
        llResetScript();
    }
    return TRUE;
}

default
{
    on_rez(integer iNum)
    {
        llResetScript();
    }    
    
    state_entry()
    {
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
        if (llGetAttached())
        {
            llRequestPermissions(llGetOwner(), PERMISSION_CONTROL_CAMERA | PERMISSION_TRACK_CAMERA);
        }
        g_kWearer = llGetOwner();
    }
    
    run_time_permissions(integer iPerms)
    {
        if (iPerms & (PERMISSION_CONTROL_CAMERA | PERMISSION_TRACK_CAMERA))
        {
            llClearCameraParams();
        }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID)
    {
        //only respond to owner, secowner, group, wearer
        if (UserCommand(iNum, sStr, kID)) return;
        else if (iNum == COMMAND_SAFEWORD)
        {
            ClearCam();
            llResetScript();
        }
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
        {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sMyMenu, "");
        }    
        else if (iNum == LM_SETTING_RESPONSE)
        {
            list lParams = llParseString2List(sStr, ["=", ","], []);
            string sToken = llList2String(lParams, 0);
            string sValue = llList2String(lParams, 1);
            integer i = llSubStringIndex(sToken, "_");
            if (llGetSubString(sToken, 0, i) == g_sScript)
            {
                sToken = llGetSubString(sToken, i + 1, -1);
                if (llGetPermissions() & PERMISSION_CONTROL_CAMERA)
                {
                    if (sToken == "freeze") LockCam();
                    else if (~llListFindList(g_lModes, [sToken])) CamMode(sToken);
                    g_iLastNum = (integer)sValue;
                }
            }           
        }
        else if (iNum == DIALOG_RESPONSE)
        {
            if (kID == g_kMenuID)
            {
                //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                // integer iPage = (integer)llList2String(lMenuParams, 2); 
                integer iAuth = (integer)llList2String(lMenuParams, 3); 
                if (sMessage == UPMENU)
                {
                    llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                }
                else
                {
                    UserCommand(iAuth, "cam " + llToLower(sMessage), kAv);
                    CamMenu(kAv, iAuth);
                }                              
            }
        }
    }
    
    timer()
    {       
        //handle cam pos/rot changes 
        if (g_iSync2Me)
        {
            vector vNewPos = llGetCameraPos();
            rotation rNewRot = llGetCameraRot();
            if (vNewPos != g_vCamPos || rNewRot != g_rCamRot)
            {
                ChatCamParams(g_rBroadChan);
            }
        }
        else
        {
            llSetTimerEvent(0.0);            
        }
    }    
}
