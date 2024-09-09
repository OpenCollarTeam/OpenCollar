/*// This file is part of OpenCollar.
//  Copyright (c) 2018 - 2019 Tashia Redrose, Silkie Sabra, lillith xue                            
// Licensed under the GPLv2.  See LICENSE for full details. 

medea (medea destiny)
    June 2021   -   Fix for issue #492 / issue #432, command to update camera settings (blur amount, 
                    maxcamera and mincamera) when numeric value changed via RLV/RLV settings/Camera 
                    used insufficent auth level and incorrect bitmask values to alter restriction while
                    active even though the setting was altered.
                -   Fix for issue #586, Dazzle set wrong restriction (was setting camunlock instead of
                    renderresolutiondivisor)
                -   Added comments explaining the restrictions settings to make life easier for future
                    contributors and people learning from reading OC scripts.
    Sept 2021   -   Fixes to comments above
                -   Corrected values for Rummage and Dress restrictions, added @emote=n to Talk restrictions #649
                -   Restored SetDebug, SetEnv and Mouselook restrictions which had gone missing.
                -   Added Camera settings & Muffle to restriction settings. Created shortcut to camera settings 
                    from camera restrictions category, and support correct BACK button behavior so it returns 
                    the user to whichever menu they arrived at that from #649
                -   MENU REDESIGN. At time of writing this is still being discussed, but at this moment the 
                    individual restrictions subcategory menus are placed below the presets, on the basis that 
                    standard UI design principles call for detailed, multi-page functions to go lower in the 
                    attention hierarchy that quick, single-click preset functions. Various buttons/terminologies
                    have been changed to try to make the whole thing more user-friendly. Also "macro" terminology
                    has been removed, and preset used only where necessary to differentiate. issues #649 & # 654
                -   Added ListRestrictions() function which converts restriction integer pairs into human-readable
                    lists of restrictions and given chat command "(prefix)restriction list". Also used by List 
                    Presets button, which lists what the preset restriction buttons actually do. #649
                -   Given extensive explanatory text in menus. ListRestrictions() function is used to print out all
                    restrictions the wearer is currently under, rather than requiring menu user to visit every 
                    category menu to find out.  #649
                -   "Daze" preset renamed to "Names/Map", "Dazzle" to "Blur", and "Rummage" to "Inventory" because
                    older names were downright confusing.  #649
                -   Changed some names in g_lRLVlist to be clearer #649
                -   Changed auth for adding/removing presets to CMD_OWNER AND CMD_TRUSTED to match the auth 
                    requirements of setting individual restrictions as short-term solution to issue #656. 
                -   Added Restore function to Customize menu to restore presets to defaults, per issue #663
                -   Rewritten dialog code to set individual restrictions, 'cos it was badly broken. Issue #664
    Feb 2022    -   Fix for #732: Empty g_lMacros list returned via LM_SETTING_RESPONSE parses as a list with a 
                    single empty element, thus messing up the list stride. Not sure why we're keeping nulls here,
                    but setting to empty list if list length is too short works.                                   
    April 2023  -   #947 Fix stray restriction to apply sittp rather than sit restriction                    
    Nov 2023    -   Chat command for applying restrictions had problems -- if the restriction itself is given
                    rather than the button name, it would break. Added sanity check to ApplyCommand function,
                    index of g_lRLVList is now checked to see if it gets an RLVCMD and if so converts to index
                    of ButtonText, and returns if hit is CategoryIndex. Ensure the full command is fed
                    to ApplyCommand, not just the first word -- ie (prefix) restriction add "TP Location"
                    shouldn't attempt to add just "TP". NOTE: This fix will also allow presets with a space
                    in the name to be accessed properly. 
                -   Changed filtering in UserCommand so that capitalization does not have to match (i.e it
                    will accept "Preset" as well as "preset". Now also passes rlv as a synonym for setting
                    restrictions which was coded but rejected before hit, but filters to only pass to 
                    ApplyCommand if there is a command following that is not "on" or "off" to avoid collision
                    with RLV menu
                -   Removed double menu for (prefix) restrictions
      Jun 2024  -   Extended chat command function above to allow for capitalization of individual restriction names.
Nikki Lacrima
      Sept 2024 -   Remove superflous llOwnerSay commands and replace g_lMenuIDs (Yosty patch PR #963)                 
                             
*/        
string g_sScriptVersion = "8.3";

string g_sParentMenu = "RLV";
string g_sSubMenu = "Restrictions";



integer g_iJustRezzed=FALSE;
//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

//integer TIMEOUT_READY = 30497;
//integer TIMEOUT_REGISTER = 30498;
//integer TIMEOUT_FIRED = 30499;



integer NOTIFY = 1002;

integer REBOOT = -1000;
integer LINK_CMD_DEBUG=1999;
integer LINK_CMD_RESTRICTIONS = -2576;
integer LINK_CMD_RESTDATA = -2577;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
//integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

//string g_sSettingToken = "rlvsuite_";

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
integer RLV_CLEAR = 6002;//RLV plugins should clear their restriction lists upon receiving this message.

integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
//integer DIALOG_TIMEOUT = -9002;



integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes= ["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}


// Default presets will look like the old oc_rlvsuite Buttons
list g_lMacros = ["Hear", 4, 0, "Talk" , 3, 0, "Touch", 0, 16384, "Stray", 29360128, 1048576, "Inventory", 1342179328, 96, "Dress", 0, 30, "IM", 384, 0, "Names/Map", 323584, 0, "Blur", 0, 33554432];
/*NOTE: When changing these values for defaults, they should also be changed in the restrictions~restore section of dialogue response in link_message event, where this variable is restored to default settings. This is hardcoded inthe dialog response to save storing defaults and current as separate permanent lists*/



integer g_lMaxMacros = 9;  // Maximum number of presets allowed

string g_sTmpMacroName = "";
list g_lCategory = ["Chat",
                    "Show/Hide",
                    "Teleport",
                    "Misc",
                    "Edit/Mod",
                    "Interact",
                    "Movement",
                    "Camera",
                    "Outfit"
                ];

list g_lUtilityNone = ["BACK"];
/*
 ****Understanding g_lRLVList and the restrictions mask****
All RLV restrictions are stored as a pair of bitmasks, g_iRestrictions1 and g_iRestrictions 2. 
If you look at g_lRLVList below, you will see this list forms a strided list in the format:
Button name, Category Value, RLV Command
The Category Value determines which subcategory of the restrictions menu the restriction will be listen in.
0=chat, 1= show/hide, 2=teleport, 3=misc, 4=edit/mod, 5=Interact, 6=movement, 7=camera and 8=outfit
Each restriction is given a binary value, which will be 2^index/3 -- divided by three because this is a list with a stride of 3, so each group of 3 values represents one restriction. The index used to provide the power value is listed
in the comments beside each group of 3 entries below. For example the sendIM restriction has the number 8 next to it, and so the binary value of sendim is 2^8, or 256. 
We can store 31 different restrictions in each of the two restrictions integers. Thus g_iRestrictions1 is the combined bitmask of all restrictions from emote (0) to rez (30). Restrictions above this value are stored in g_iRestrictions2,  starting from 2^0 (1). Thus the index is no longer 2^index/3, but 2^index/3-31. For example a list index of 93 (addattach) gives us 93/3-31 =0. 
The number in the comment beside the restriction line in g_lRLVList (i.e. See IM for the recim restriction we have 25 26) gives the index/3 value, and the bit that's used to store this. For calculating the integer value that represents a mask, you'd do (integer)llPow(2,bit-1); i.e. for bit 1 we get 2^0=1, for bit 2 we get 2^1=2 and so on.
Putting it all together: 
Imagine we have the restrictions sendIM, See IM, Start IM and Notecard in place.
The bit values for these are:
Send IM  = 8
See IM   = 9
Start IM = 10
Notecard =  5
Here we can see that g_iRestrictions1 will have bits 7,8 and 9 set and g_iRestrictions2 will have bit 5 set.
We can easily calculate these values:
g_iRestrictions1= 2^7 + 2^8 + 2^9 = 128+256+512 = 896
g_iRestrictions2= 2^4 = 16
We can test if a particular restiction is set with an AND conditional.
For example, to check if whisper restriction (Power value 4) we would do:
if(g_iRestrictions1 & llPow(2,4))
We can set a bit simply by adding the value of the power if not set or subtracting the value if set, or we can toggle the bit by XORing the integer with the bitmask value. NOTE that LSL uses ^ for XOR, not for powers. So 
g_iRestrictions1=g_iRestrictions1^llPow(2,5) will toggle the chatnormal restriction.
*/
integer g_iRestrictions1 = 0;
integer g_iRestrictions2 = 0;
list g_lRLVList = [   // ButtonText, CategoryIndex, RLVCMD          index | bit
    "EmoteTrunc"    , 0 , "emote"                               ,    // 0 1 - g_iRestrictions1
    "Send Chat"     , 0 , "sendchat"                            ,    // 1 2
    "See Chat"      , 0 , "recvchat"                            ,    // 2 3
    "See Emote"     , 0 , "recvemote"                           ,    // 3 4
    "Whisper"       , 0 , "chatwhisper"                         ,    // 4 5
    "Normal Chat"   , 0 , "chatnormal"                          ,    // 5 6
    "Shout"         , 0 , "chatshout"                           ,    // 6 7
    "Send IM"       , 0 , "sendim"                              ,    // 7 8
    "See IM"        , 0 , "recvim"                              ,    // 8 9
    "Start IM"      , 0 , "startim"                             ,    // 9 10
    "Gesture"       , 0 , "sendgesture"                         ,    // 10 11
    "Inventory"     , 1 , "showinv"                             ,    // 11 12
    "Minimap"       , 1 , "showminimap"                         ,    // 12 13
    "Worldmap"      , 1 , "showworldmap"                        ,    // 13 14
    "Location"      , 1 , "showloc"                             ,    // 14 15
    "Names"         , 1 , "shownames"                           ,    // 15 16
    "Nametags"      , 1 , "shownametags"                        ,    // 16 17
    "Nearby"        , 1 , "shownearby"                          ,    // 17 18
    "Text"          , 1 , "showhovertext"                       ,    // 18 19
    "Text HUD"      , 1 , "showhovertexthud"                    ,    // 19 20
    "Text World"    , 1 , "showhovertextworld"                  ,    // 20 21
    "Text All"      , 1 , "showhovertextall"                    ,    // 21 22
    "Landmark"      , 2 , "tplm"                                ,    // 22 23
    "TP Location"   , 2 , "tploc"                               ,    // 23 24
    "TP Local"      , 2 , "tplocal"                             ,    // 24 25
    "Accept TP"     , 2 , "tplure"                              ,    // 25 26
    "Offer TP"      , 2 , "tprequest"                           ,    // 26 27
    "Permissions"   , 3 , "acceptpermission"                    ,    // 27 28
    "Edit"          , 4 , "edit"                                ,    // 28 29
    "Edit Object"   , 4 , "editobj"                             ,    // 29 30
    "Rez"           , 4 , "rez"                                 ,    // 30 31
    "Add Attach"    , 8 , "addattach"                           ,    // 31  1 - g_iRestrictions2
    "Rem Attach"    , 8 , "remattach"                           ,    // 32  2
    "Add Cloth"     , 8 , "addoutfit"                           ,    // 33  3
    "Rem Cloth"     , 8 , "remoutfit"                           ,    // 34  4
    "Notecard"      , 4 , "viewnote"                            ,    // 35  5
    "Script"        , 4 , "viewscript"                          ,    // 36  6
    "Texture"       , 4 , "viewtexture"                         ,    // 37  7
    "Touch Far"     , 5 , "fartouch"                            ,    // 38  8
    "Interact"      , 5 , "interact"                            ,    // 39  9
    "Attachment"    , 5 , "touchattach"                         ,    // 40  10
    "Own Attach"    , 5 , "touchattachself"                     ,    // 41  11
    "Other Attach"  , 5 , "touchattachother"                    ,    // 42  12
    "Touch HUD"     , 5 , "touchhud"                            ,    // 43  13
    "Touch World"   , 5 , "touchworld"                          ,    // 44  14
    "Touch All"     , 5 , "touchall"                            ,    // 45  15
    "Fly"           , 6 , "fly"                                 ,    // 46  16
    "Jump"          , 6 , "jump"                                ,    // 47  17
    "Stand Up"      , 6 , "unsit"                               ,    // 48  18
    "Sit Down"      , 6 , "sit"                                 ,    // 49  19
    "Sit TP"        , 6 , "sittp"                               ,    // 50  20
    "Stand TP"      , 6 , "standtp"                             ,    // 51  21
    "Always Run"    , 6 , "alwaysrun"                           ,    // 52  22
    "Temp Run"      , 6 , "temprun"                             ,    // 53  23
    "Unlock Cam"    , 7 , "camunlock"                           ,    // 54  24
    "Blur View"     , 7 , "setdebug_renderresolutiondivisor"    ,    // 55  25
    "MaxDistance"   , 7 , "setcam_avdistmax"                    ,    // 56  26
    "MinDistance"   , 7 , "setcam_avdistmin"                    ,    // 57  27
    "Send Emote"    , 0 , "rediremote"                          ,    // 58  28 
    "Set Debug"     , 3 , "setdebug"                            ,    // 59  29
    "Environment"   , 3 , "setenv"                              ,    // 60  30
    "Mouselook"     , 7 , "camdistmax:0"                            // 61  31
//    "Idle"          , 3 , "allowidle"                           ,  // Unofficial command Not supported in all viewers
]; 

   

integer g_iBlurAmount = 5;
float g_fMaxCamDist = 2.0;
float g_fMinCamDist = 1.0;
integer g_bForceMouselook = FALSE;

integer g_iRLV = FALSE;

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, sName+"~"+llGetScriptName());
}

list ListRestrictions(integer r1, integer r2)
{
    list out;
    list out2;
    integer i;
    integer bit;
    while(i<31)
    {
        bit=(integer)llPow(2,i);
        if(r1&bit) out+=llList2String(g_lRLVList,i*3);
        if(r2&bit) out2+=llList2String(g_lRLVList,i*3+90);
        ++i;
    }
    if(out+out2==[]) return ["None"];
    else return out+out2;
}

Menu(key kID, integer iAuth) {
    
    list lButtons =[];
    integer i;
    for(i=0;i<llGetListLength(g_lMacros);i+=3){
        // calculate checkbox
        integer b1 = llList2Integer(g_lMacros,i+1);
        integer b2 = llList2Integer(g_lMacros, i+2);
        lButtons+=[Checkbox(bool((g_iRestrictions1 & b1 ) || ( g_iRestrictions2 & b2)), llList2String(g_lMacros,i))];
    }
    //for (i=0; i<llGetListLength(g_lMacros);i=i+3) lButtons += llList2String(g_lMacros,i);
    Dialog(kID, "\n[Restrictions]\nToggle restriction presets on/off. LIST PRESETS - shows what each button does. Access individual restrictions via the [ADVANCED] menu. [CUSTOMIZE] for restriction settings and customising the Restriction buttons in this menu.\nMore info: http://opencollar.cc/docs/RLV#restrictions\nCurrent Restrictions:"+llDumpList2String(ListRestrictions(g_iRestrictions1,g_iRestrictions2),", ")+".", lButtons, ["LIST PRESETS","[ADVANCED]","[CUSTOMIZE]","BACK"], 0, iAuth, "Restrictions~Main");
}
MenuManage(key kID, integer iAuth)
{
    string sPrompt="[Restriction settings]\nClick 'Save Preset' to save current restrictions as a preset button in the Restrictions menu. 'Del. Preset' to delete an existing button ("+(string)(llGetListLength(g_lMacros)/3)+"/"+(string)g_lMaxMacros+" used). 'Restore' will restore buttons to defaults.\n'Camera' to change camera/blur settings , and 'Muffle' to set speech muffling\nMore info: http://opencollar.cc/docs/RLV#customize\n.\n Current Restrictions:\n"+llDumpList2String(ListRestrictions(g_iRestrictions1,g_iRestrictions2),", ");
    Dialog(kID,sPrompt , ["Save Preset","Del. Preset","Restore","Camera","Muffle"], g_lUtilityNone, 0, iAuth, "Restrictions~Manage");
}
MenuDetailed(key kID, integer iAuth){
    string sPrompt = "\n[Restriction Categories]\nSet anyRLV restrictions individually from these category menus.\n Current Restrictions:\n"+llDumpList2String(ListRestrictions(g_iRestrictions1,g_iRestrictions2),", ");
    Dialog(kID, sPrompt, g_lCategory, ["[Clear All]"]+g_lUtilityNone, 0, iAuth, "Restrictions~Restrictions");
    
}

MenuCategory(key kID, integer iAuth, string sCategory)
{
    string sPrompt = "\n[Category "+sCategory+"]/nToggle individual restrictions on or off.\n Current Restrictions:\n"+llDumpList2String(ListRestrictions(g_iRestrictions1,g_iRestrictions2),", ");;
    list lUtility=g_lUtilityNone;
    if(sCategory=="Camera") lUtility=["Settings"]+lUtility;

    integer iCatIndex = llListFindList(g_lCategory,[sCategory]);
    
    list lMenu = [];
    integer i;
    
    for(i=0; i<llGetListLength(g_lRLVList); i+= 3){
        if(llList2Integer(g_lRLVList,i+1) == iCatIndex){
            
            integer Flag1 = llRound(llPow(2,(i/3)));
            integer Flag2 = 0;
            if((i/3)>=31){
                Flag1=0;
                Flag2 = llRound(llPow(2, (i/3)-30));
            }
            if(iAuth==CMD_OWNER || iAuth==CMD_TRUSTED){
                if((g_iRestrictions1 & Flag1) || (g_iRestrictions2 & Flag2)) lMenu+= [Checkbox(TRUE, llList2String(g_lRLVList, i))];
                else lMenu += [Checkbox(FALSE, llList2String(g_lRLVList,i))];
            }
            
        }
    }
    Dialog(kID, sPrompt, lMenu,lUtility, 0, iAuth, "Restrictions~Category");
}

MenuDelete(key kID, integer iAuth)
{
    if (iAuth == CMD_OWNER){
        list lButtons = [];
        integer i;
        for (i=0; i<llGetListLength(g_lMacros);i=i+3)
        {
            lButtons += llList2String(g_lMacros,i);
        }
        Dialog(kID, "Select a preset restrictions button you want to delete:", lButtons, g_lUtilityNone, 0, iAuth, "Restrictions~Delete");
    } else {
        llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS% to delete a restrictions preset", kID);
        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kID);
    }
}

list bitpos (integer flag1,integer flag2){
    list ret=[0,0];
    
    if(flag1>0){
        ret=llListReplaceList(ret,[llRound(llLog10(flag1)/llLog10(2))],0,0);
    }
    
    if(flag2>0){
        ret = llListReplaceList(ret,[llRound(llLog10(flag2)/llLog10(2))],1,1);
    }
    
    
    return ret;
}
        
        
string FormatCommand(string sCommand,integer bEnable)
{
    string sMod;
    if (bEnable) sMod = "=n";
    else sMod = "=y";
    
    if (sCommand == "setdebug_renderresolutiondivisor") {
        if (bEnable) sMod = ":"+(string)g_iBlurAmount+"=force";
        else sMod = ":1=force";
    } else if (sCommand == "setcam_avdistmax" && !g_bForceMouselook) {
        sCommand += ":"+(string)g_fMaxCamDist;
    } else if (sCommand == "setcam_avdistmin" && !g_bForceMouselook) {
        sCommand += ":"+(string)g_fMinCamDist;
    } else if ((sCommand == "setcam_avdistmax" || sCommand == "setcam_avdistmin") && g_bForceMouselook) {
        sCommand = "camdistmax:0";
    } else if (sCommand == "camdistmax:0"){
        if (bEnable) g_bForceMouselook = TRUE;
        else g_bForceMouselook = FALSE;
    } else if(sCommand == "rediremote")
    {
        sMod = ":38322"+sMod;
    }
       
    //llOwnerSay("Restriction '"+sCommand+"' has changed, sending message");
    llMessageLinked(LINK_SET, LINK_CMD_RESTRICTIONS, sCommand+"="+(string)bEnable+"=-1","");
    
    return sCommand+sMod;
}

ApplyAll(integer iMask1, integer iMask2, integer iBoot)
{
    list lResult = [];
    integer iMax1 = 1073741824;
    integer iMax2 = 1073741824;
    while (iMax1 > 0) {
        list pos = bitpos(iMax1, 0);
        integer iIndex = (llList2Integer(pos,0)*3)+2;
        
        
        if (iIndex > -1 && bool(iMax1 & iMask1) != bool(iMax1 & g_iRestrictions1)) {
            lResult += [FormatCommand(llList2String(g_lRLVList,iIndex), bool(iMax1 & iMask1))];
           // llSay(0, "lRLVListPart1.\npos: "+(string)pos+"\niIndex: "+(string)iIndex+"\nlResult[-1]: "+llList2String(lResult,-1));
        }
        iMax1 = iMax1 >> 1;
    }
    
    while (iMax2 > 0) {
        list pos = bitpos(0,iMax2);
        integer iIndex = ((llList2Integer(pos,1)+30)*3)+2;
        if (iIndex > -1 && bool(iMax2 & iMask2) != bool(iMax2 & g_iRestrictions2)) {
            lResult += [FormatCommand(llList2String(g_lRLVList,iIndex),bool(iMax2 & iMask2))];
          //  llSay(0, "lRLVListPart2.\npos: "+(string)pos+"\niIndex: "+(string)iIndex+"\nlResult[-1]: "+llList2String(lResult,-1));
        }
        iMax2 = iMax2 >> 1;
        
        
    }
    string sCommandList = llDumpList2String(lResult,",");
    lResult=[];

    llMessageLinked(LINK_SET,RLV_CMD,sCommandList,"Macros");
    g_iRestrictions1 = iMask1;
    g_iRestrictions2 = iMask2;
    
    if(!iBoot){
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_masks=" + (string)g_iRestrictions1+","+(string)g_iRestrictions2, "");
    }
}

ApplyCommand(string sCommand, integer iAdd,key kID, integer iAuth)
{
   // llSay(0, "Apply CMD "+sCommand+"|"+(string)iAdd);
    integer iMenuIndex = llListFindList(g_lRLVList,[sCommand]);
    if(iMenuIndex==-1)
    {
        //command not found, let's do a capitalization check
        integer max=llGetListLength(g_lRLVList);
        integer iter;
        while (iter<max && iMenuIndex==-1)
        {
            if(llToLower(llList2String(g_lRLVList,iter))==llToLower(sCommand)) iMenuIndex=iter;
            ++iter;
        }
        if(iMenuIndex==-1) return;
    }         
    if(!(iMenuIndex-1)%3) return; //Hit on CategorIndex, i.e someone tried (prefix) restriction add 1
    if(iMenuIndex%3) iMenuIndex-=2; //convert RLVCMD to ButtonText (i.e. tploc becomes TP Location)
    integer iActualIndex=iMenuIndex;
    integer iMenuIndex2;
    if(iMenuIndex/3>=31){
        iMenuIndex2 =(integer) llPow(2, (iMenuIndex/3)-30);
        iMenuIndex=0;
    }else {
        iMenuIndex2=0;
        iMenuIndex = (integer)llPow(2, iMenuIndex/3);
    }
   // llSay(0, "Apply CMD "+sCommand+"|"+(string)iAdd+"|actual="+(string)iActualIndex+"|"+(string)iMenuIndex+","+(string)iMenuIndex2);
    if (iActualIndex > -1) {
        integer allow=FALSE;
        if(iAuth==CMD_OWNER||iAuth==CMD_TRUSTED)allow=TRUE;
        
        if (allow){
            if (!iAdd) {
                if(iMenuIndex==0){
                    if(!(g_iRestrictions2 & iMenuIndex2)){
                        // STOP
                        //llSay(0, "BIT NOT SET. REFUSE TO LIFT NON_EXISTING RESTRICTION");
                        return;
                    }
                } else if(iMenuIndex2 ==0){
                    if(!(g_iRestrictions1 & iMenuIndex)){
                        //STOP
                        //llSay(0, "BIT NOT SET. REFUSE TO LIFT NON_EXISTING RESTRICTION");
                        return;
                    }
                }
                g_iRestrictions1 -= iMenuIndex;
                g_iRestrictions2 -= iMenuIndex2;
                
                llMessageLinked(LINK_SET,RLV_CMD,FormatCommand(llList2String(g_lRLVList,iActualIndex+2),FALSE),"Macros");
                if (kID != NULL_KEY) llOwnerSay(llList2String(g_lCategory, llList2Integer(g_lRLVList,iActualIndex+1))+" - "+llList2String(g_lRLVList,iActualIndex)+" is not restricted anymore!");
            } else {
                
                if(iMenuIndex==0){
                    if((g_iRestrictions2 & iMenuIndex2)){
                        // STOP
                       // llSay(0, "BIT SET. REFUSE EXISTING RESTRICTION");
                        return;
                    }
                } else if(iMenuIndex2 ==0){
                    if((g_iRestrictions1 & iMenuIndex)){
                        //STOP
                       // llSay(0, "BIT SET2. REFUSE EXISTING RESTRICTION");
                        return;
                    }
                }
                g_iRestrictions1 += iMenuIndex;
                g_iRestrictions2 += iMenuIndex2;
                
                llMessageLinked(LINK_SET,RLV_CMD,FormatCommand(llList2String(g_lRLVList,iActualIndex+2),TRUE),"Macros");
                if (kID != NULL_KEY) llOwnerSay(llList2String(g_lCategory, llList2Integer(g_lRLVList,iActualIndex+1))+" - "+llList2String(g_lRLVList,iActualIndex)+" is now restricted!");
            }
            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_masks=" + (string)g_iRestrictions1+","+(string)g_iRestrictions2, "");
        } else if (kID != NULL_KEY) llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS% to change '"+llList2String(g_lCategory, llList2Integer(g_lRLVList,iActualIndex+1))+" - "+llList2String(g_lRLVList,iActualIndex)+"'", kID);
    }
}


UserCommand(integer iNum, string sStr, key kID) {
    if (iNum<CMD_OWNER || iNum>CMD_EVERYONE) return;
    
    if (llToLower(sStr)=="restrictions" || llToLower(sStr) == "menu restrictions") Menu(kID, iNum);
    else if(llToLower(sStr)=="advanced" || llToLower(sStr) == "menu [advanced]")MenuDetailed(kID, iNum);
    else if(llToLower(sStr)=="customize" || llToLower(sStr) == "menu customize") MenuManage(kID,iNum);
    else if(llToLower(sStr)=="list presets") {
        integer x=llGetListLength(g_lMacros);
        integer i;
        string out="0List of preset buttons, and what individual restrictions they apply:";
        while(i<x) {
            out+="\n"+llList2String(g_lMacros,i)+": "+llDumpList2String(ListRestrictions(llList2Integer(g_lMacros,i+1),llList2Integer(g_lMacros,i+2)),", ");
            i=i+3;
        }
        llMessageLinked(LINK_SET,NOTIFY,out,kID);
    }else if(llSubStringIndex(llToLower(sStr),"menu category")==0) {
        sStr=llGetSubString(sStr,14,-1);
        if(~llListFindList(g_lCategory,[sStr])) MenuCategory(kID,iNum,sStr);
    }
    //if (llSubStringIndex(sStr,"preset") && llSubStringIndex(sStr,"restriction") && llSubStringIndex(sStr,"restrictions") && llSubStringIndex(sStr,"sit") && llSubStringIndex(sStr,"rlv") return;
    else { 
        list lCommands=llParseString2List(sStr,[" "],[]);
        string sChangetype = llToLower(llList2String(lCommands,0));
        if(llListFindList(["preset","restriction","restrictions","sit","rlv"],[sChangetype])==-1) return;
        string sChangekey = llList2String(lCommands,1);
        string sChangevalue = llDumpList2String(llList2List(lCommands,2,-1)," ");
        lCommands=[];
        //llOwnerSay(sChangetype+" | "+sChangekey);
        if (sChangetype == "preset") {
            integer iIndex = llListFindList(g_lMacros,[sChangevalue]);
            if (iIndex > -1) {
                if (iNum == CMD_OWNER || iNum==CMD_TRUSTED){
                    if (sChangekey == "add") {
                        llMessageLinked(LINK_SET, NOTIFY, "1"+"Restriction preset added: '"+sChangevalue+"'", kID);
                        ApplyAll(g_iRestrictions1 | llList2Integer(g_lMacros,iIndex+1),g_iRestrictions2 | llList2Integer(g_lMacros,iIndex+2),FALSE);
                    } else if (sChangekey == "replace") {
                        llMessageLinked(LINK_SET, NOTIFY, "1"+"Replaced current restrictions with preset '"+sChangevalue+"'", kID);
                        ApplyAll(llList2Integer(g_lMacros,iIndex+1),llList2Integer(g_lMacros,iIndex+2),FALSE);
                    } else if (sChangekey == "clear") {
                        llMessageLinked(LINK_SET, NOTIFY, "1"+"Restriction presets cleared '"+sChangevalue+"'", kID);
                        ApplyAll(g_iRestrictions1 ^ (g_iRestrictions1 & llList2Integer(g_lMacros,iIndex+1)),g_iRestrictions2 ^ (g_iRestrictions2 & llList2Integer(g_lMacros,iIndex+2)),FALSE);
                    } 
                } else llMessageLinked(LINK_SET, NOTIFY, "0"+"Insufficient authority to set restrictions!", kID);
            } else llInstantMessage(kID,"Restriction preset '"+sChangevalue+"' does not exist!");
        } else if (sChangetype == "restriction" || sChangetype == "rlv" || sChangetype=="restrictions") {
            if(sChangekey=="on" || sChangekey =="off" || sChangekey=="") return;
            if (sChangekey == "add") ApplyCommand(sChangevalue,TRUE, kID, iNum);
            else if (sChangekey == "rem" && iNum != CMD_WEARER) ApplyCommand(sChangevalue,FALSE, kID, iNum);
            else if (sChangekey == "list")
                 llMessageLinked(LINK_SET,NOTIFY,"0Current Restrictions:\n"+llDumpList2String(ListRestrictions(g_iRestrictions1,g_iRestrictions2),"\n"),kID);
        } //else if (sChangetype == "restrictions") Menu(kID,iNum);
    }
}

integer CheckboxState(string CheckboxLabel){
    list lTmp = llParseString2List(CheckboxLabel,[" "],[]);
    integer iPos = llListFindList(g_lCheckboxes, [llList2String(lTmp,0)]);
    if(iPos==-1){
        return FALSE;
    }else {
        return iPos;
    }
}

string CheckboxText(string CheckboxLabel){
    list lTmp = llParseString2List(CheckboxLabel, [" "],[]);
    return llList2String(lTmp,1);
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llMessageLinked(LINK_SET, ALIVE, llGetScriptName(),"");
         //       llOwnerSay("New:"+(string)llGetUsedMemory());
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
    state_entry()
    {
        //llScriptProfiler(TRUE);
        if(llGetStartParameter()!=0)llResetScript();
        g_iRLV = FALSE;
        //llSetTimerEvent(1);

        
    }
    
    on_rez(integer iRez){
        //g_iJustRezzed=TRUE;
        // Restrictions are likely not applied at the moment, reinit the variables
        //llResetTime();
        llResetScript();
        //llSetTimerEvent(1);
    }
    
    timer(){
        if(llGetTime()>=20 && g_iJustRezzed){
            llMessageLinked(LINK_SET, RLV_REFRESH, "",""); // refreshes rlvsuite restrictions
        }
        
        //llSetText("rlvsuite\n\n=> Free Memory: "+(string)llGetFreeMemory()+"\nProfiler Max used: "+(string)llGetSPMaxMemory()+"\nUsed Memory: "+(string)llGetUsedMemory()+"\nTotal Mem: "+(string)llGetMemoryLimit()+"\n \n \n \n \n \n \n \n \n", <0,1,0>,1);
    }
        
    link_message(integer iSender,integer iNum,string sStr,key kID){
       // llOwnerSay(llDumpList2String([iSender, iNum, llGetSPMaxMemory(), llGetFreeMemory()], " ^ "));
        // llOwnerSay("inum="+(string)iNum+" | kID="+(string)kID+"| sStr="+sStr);
        if(iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if(iNum == MENUNAME_REQUEST) {
            if(sStr == g_sParentMenu){
                
                
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu+"|"+ g_sSubMenu,"");  // Register menu "Restrictions"
            }
        } else if(iNum == DIALOG_RESPONSE){
            integer iPos = llSubStringIndex(kID, "~"+llGetScriptName());
            if(iPos>0){
                string sMenu = llGetSubString(kID, 0, iPos-1);
                list lMenuParams = llParseString2List(sStr, ["|"],[]);
                key kAv = llList2Key(lMenuParams,0);
                string sMsg = llList2String(lMenuParams,1);
                integer iAuth = llList2Integer(lMenuParams,3);
                
                //llOwnerSay("Memory Free: "+(string)llGetFreeMemory());
                //llOwnerSay("Memory Used: "+(string)llGetUsedMemory());
                
                
                if(sMenu == "Restrictions~Main"){ 
                    if(sMsg == "BACK") llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    else if (sMsg == "[CUSTOMIZE]") MenuManage(kAv,iAuth);
                    else if(sMsg == "[ADVANCED]") MenuDetailed(kAv,iAuth);
                    else if(sMsg == "LIST PRESETS")  {
                         UserCommand(iAuth,"list presets",kAv);
                         Menu(kAv,iAuth);
                    } else {
                        integer iChkbxState = CheckboxState(sMsg);
                        string sChkbxLbl = CheckboxText(sMsg);
                        
                        if(!iChkbxState){
                            // toggle the macro
                            UserCommand(iAuth, "preset add "+sChkbxLbl, kAv);
                        } else {
                            UserCommand(iAuth, "preset clear "+sChkbxLbl,kAv);
                        }
                        Menu(kAv,iAuth);
                    }
                } else if (sMenu == "Restrictions~Manage"){
                    if (sMsg == "Save Preset") {
                        if (iAuth == CMD_OWNER) {
                            if(g_iRestrictions1+g_iRestrictions2==0)  {
                                llRegionSayTo(kAv,0,"No restrictions are curently in place to save!");
                                MenuManage(kAv,iAuth);
                                return;
                            }
                            Dialog(kAv, "Save all current restrictions as a new preset button in the Restrictions menu. Current restrictions: "+llDumpList2String(ListRestrictions(g_iRestrictions1,g_iRestrictions2),", ")+".\nEnter the name of the new button or click submit without typing to cancel:", [], [], 0, iAuth,"Restrictions~textbox");
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                            MenuManage(kAv,iAuth);
                        }
                    } else if (sMsg == "Del. Preset") MenuDelete(kAv, iAuth);
                    else if( sMsg == "Camera") llMessageLinked(LINK_SET,iAuth,"menu managecamera",kAv);
                    else if( sMsg =="Muffle") llMessageLinked(LINK_SET,iAuth,"menu managechat",kAv);
                    else if (sMsg == "BACK") Menu(kAv, iAuth);
                    else if(sMsg=="Restore") Dialog(kAv,"Restore restriction buttons to the default set. ARE YOU SURE?",["Yes","No!"],[],0,iAuth,"Restrictions~Restore");
                } else if (sMenu == "Restrictions~Restore") {
                    if(sMsg=="Yes")  {
                        if(iAuth!=CMD_OWNER) llMessageLinked(LINK_SET,NOTIFY,"0Only an owner can restore buttons.",kAv);
                        else  {
                           g_lMacros = ["Hear", 4, 0, "Talk" , 3, 0, "Touch", 0, 16384, "Stray", 29360128, 524288, "Inventory", 1342179328, 96, "Dress", 0, 30, "IM", 384, 0, "Names/Map", 323584, 0, "Blur", 0, 33554432];
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                        }
                    }MenuManage(kAv,iAuth);    
                } else if (sMenu == "Restrictions~Restrictions"){
                    if(sMsg == "BACK") Menu(kAv,iAuth);
                    else if (sMsg == "[Clear All]") {
                        if (iAuth != CMD_WEARER && (iAuth == CMD_OWNER||iAuth==CMD_TRUSTED)) {
                            ApplyAll(0,0, FALSE);
                            MenuDetailed(kAv, iAuth);
                        } else {
                            llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                            MenuDetailed(kAv, iAuth);
                        }
                    }
                    else MenuCategory(kAv, iAuth, sMsg);
                
                } 
                else if (sMenu == "Restrictions~Category")
                {
                    if(sMsg == "BACK") MenuDetailed(kAv,iAuth);
                    else if(sMsg == "Settings") llMessageLinked(LINK_SET,iAuth,"menu managecamera2",kAv);
                    else 
                    {
                        integer iVal=CheckboxState(sMsg);
                        sMsg = llGetSubString( sMsg, llStringLength(llList2String(g_lCheckboxes,0))+1, -1);
                        if(llListFindList(g_lRLVList,[sMsg])>-1) 
                        {
                            if(iVal) 
                            {
                                if (iAuth != CMD_WEARER) ApplyCommand(sMsg,FALSE,kAv, iAuth);
                                else llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS%", kAv);
                            }
                            else ApplyCommand(sMsg,TRUE,kAv,iAuth);
                        }
                        MenuCategory(kAv, iAuth, llList2String(g_lCategory, llList2Integer(g_lRLVList,llListFindList(g_lRLVList,[sMsg])+1)));
                    }
                } else if (sMenu == "Restrictions~textbox") {
                    if(sMsg=="")  {
                        llRegionSayTo(kAv,0,"Cancelled save.");
                        MenuManage(kAv,iAuth);
                        return;
                    }
                    if (llListFindList(g_lMacros,[sMsg]) > -1) {
                        g_sTmpMacroName = sMsg;
                        Dialog(kAv, "A button named '"+sMsg+"' already exists!\n \nDo you want to override it?", ["YES","NO"], g_lUtilityNone, 0, iAuth, "Restrictions~Override");
                    } else {
                        if (llGetListLength(g_lMacros)/3 >= g_lMaxMacros) Dialog(kAv, "Out of button space, please delete one first.", ["OK"], g_lUtilityNone, 0, iAuth, "Restrictions~MaxMacro");
                        else {
                            sMsg = llGetSubString(sMsg,0,11);
                            sMsg = llDumpList2String(llParseStringKeepNulls((sMsg = "") + sMsg, [" "], []), "_");
                            g_lMacros += [sMsg, g_iRestrictions1, g_iRestrictions2];
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                            Menu(kAv,iAuth);
                        }
                    }
                } else if (sMenu == "Restrictions~MaxMacro") Menu(kAv,iAuth);
                else if (sMenu == "Restrictions~Override"){
                    if (sMsg == "YES"){
                        integer iIndex = llListFindList(g_lMacros,[g_sTmpMacroName]);
                        g_lMacros = llListReplaceList(g_lMacros, [g_sTmpMacroName,g_iRestrictions1,g_iRestrictions2], iIndex, iIndex+2);
                        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                        Menu(kAv,iAuth);
                    } else Dialog(kAv, "Enter the name of the new button:", [], [], 0, iAuth,"Restrictions~textbox");
                } else if (sMenu == "Restrictions~Delete"){
                    if (iAuth <= CMD_TRUSTED){
                        integer iIndex = llListFindList(g_lMacros,[sMsg]);
                        if (iIndex > -1) {
                            g_lMacros = llDeleteSubList(g_lMacros,iIndex, iIndex+2);
                            llMessageLinked(LINK_SET, LM_SETTING_SAVE, "rlvsuite_macros=" + llDumpList2String(g_lMacros,"^"), "");
                            Menu(kAv,iAuth);
                        } else Menu(kAv,iAuth);
                    } else {
                        llMessageLinked(LINK_SET, NOTIFY, "0"+"%NOACCESS%", kAv);
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    }
                }
            }
        } else if(iNum == -99999){
            if(sStr == "update_active")llResetScript();
        } else if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            
            //integer ind = llListFindList(g_lSettingsReqs, [llList2String(lParams,0)]);
            //if(ind!=-1)g_lSettingsReqs = llDeleteSubList(g_lSettingsReqs, ind,ind);
            
            
            if (llList2String(lParams, 0) == "rlvsuite_masks") {
                list lMasks = llParseString2List(llList2String(lParams, 1),[","],[]);
                if (g_iRLV) { // bad timing, RLV_ON was already called
                    integer iMask1 =  (integer)llList2String(lMasks, 0);
                    integer iMask2 = (integer)llList2String(lMasks, 1);
                    g_iRestrictions1 = 0;
                    g_iRestrictions2 = 0;
                    ApplyAll(iMask1,iMask2,TRUE);
                } else { // Just save the masks, they will be applied when RLV_ON or RLV_REFRESH is received
                    g_iRestrictions1 = llList2Integer(lMasks, 0);
                    g_iRestrictions2 = llList2Integer(lMasks, 1);
                }
            } else if (llList2String(lParams, 0) == "rlvsuite_macros") {
                g_lMacros = llParseStringKeepNulls(llList2String(lParams, 1), ["^"],[]);
                if(llGetListLength(g_lMacros)<3) g_lMacros=[];  
            }
            else if(llList2String(lParams,0) == "global_checkboxes") g_lCheckboxes = llCSV2List(llList2String(lParams,1));
        } else if (iNum == CMD_SAFEWORD || iNum == RLV_CLEAR || iNum == RLV_OFF){
            g_iRLV = FALSE;
            ApplyAll(0,0,FALSE);
        } else if (iNum == RLV_REFRESH || iNum == RLV_ON) {
            g_iRLV = TRUE;
            integer iMask1 = g_iRestrictions1;
            integer iMask2 = g_iRestrictions2;
            g_iRestrictions1 = 0;
            g_iRestrictions2 = 0;
            ApplyAll(iMask1,iMask2,TRUE);
        } else if (iNum == REBOOT && sStr == "reboot") {
            llResetScript();
      /*}else if(iNum == LINK_CMD_DEBUG){
            integer onlyver=0;
            if(sStr == "ver")onlyver=1;
            llInstantMessage(kID, llGetScriptName() +" SCRIPT VERSION: "+g_sScriptVersion);
            if(onlyver)return; // basically this command was: <prefix> versions
            
            llInstantMessage(kID, llGetScriptName() +" MEMORY USED: "+(string)llGetUsedMemory());
            llInstantMessage(kID, llGetScriptName() +" MEMORY FREE: "+(string)llGetFreeMemory());
            //Commenting this out for general release 'cos memory is tight.
            */
        } else if (iNum == LINK_CMD_RESTRICTIONS) {
            list lCMD = llParseString2List(sStr,["="],[]);
            if (llList2Integer(lCMD,2) > -1) ApplyCommand(llList2String(lCMD,0),llList2Integer(lCMD,1),kID,llList2Integer(lCMD,2));
        } else if (iNum == LINK_CMD_RESTDATA) {
            list lCMD = llParseString2List(sStr, ["="], []);
            if (llList2String(lCMD,0) == "BlurAmount") {
                integer bWasTrue = g_iRestrictions2 & (integer)(llPow(2,25));
                if (bWasTrue) ApplyCommand("Blur View",FALSE, NULL_KEY, 500);
                g_iBlurAmount = llList2Integer(lCMD,1);
                if (bWasTrue) ApplyCommand("Blur View",TRUE, NULL_KEY, 500);
            } else if (llList2String(lCMD,0) == "MaxCamDist") {
                integer bWasTrue = g_iRestrictions2 & (integer)(llPow(2,26));
                if (bWasTrue) ApplyCommand("MaxDistance",FALSE, NULL_KEY, 500);
                g_fMaxCamDist = llList2Float(lCMD,1);
                if (bWasTrue) ApplyCommand("MaxDistance",TRUE, NULL_KEY, 500);
            } else if (llList2String(lCMD,0) == "MinCamDist") { 
                integer bWasTrue = g_iRestrictions2 & (integer)(llPow(2,27));
                if (bWasTrue) ApplyCommand("MinDistance",FALSE, NULL_KEY, 500);
                g_fMinCamDist = llList2Float(lCMD,1);
                if (bWasTrue) ApplyCommand("MinDistance",TRUE, NULL_KEY, 500);
            }
        
        }
    }
    
}
