/*
This file is a part of OpenCollar.
Copyright ©2020


: Contributors :

Aria (Tashia Redrose)
    * Oct 2020       -       Created oc_themes
    
    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar

*/


string g_sParentMenu = "Apps";
string g_sSubMenu = "Themes";


integer g_iHide;

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;

integer NOTIFY = 1002;
integer REBOOT = -1000;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved
//str must be in form of "token=value"
//integer LM_SETTING_REQUEST = 2001;//when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE = 2002;//the settings script sends responses on this channel
integer LM_SETTING_DELETE = 2003;//delete token from settings
//integer LM_SETTING_EMPTY = 2004;//sent when a token has no value

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
//integer MENUNAME_REMOVE = 3003;

//integer RLV_CMD = 6000;
//integer RLV_REFRESH = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.

//integer RLV_OFF = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON = 6101; // send to inform plugins that RLV is enabled now, no message or key needed

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
string UPMENU = "BACK";
//string ALL = "ALL";

Dialog(key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kID + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);

    integer iIndex = llListFindList(g_lMenuIDs, [kID]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kID, kMenuID, sName], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kID, kMenuID, sName];
}

Menu(key kID, integer iAuth) {
    if(iAuth != CMD_OWNER && iAuth != CMD_WEARER){
        llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% to the themes", kID);
        llMessageLinked(LINK_SET, 0, "menu "+g_sParentMenu, kID);
        return;
    }
    string sPrompt = "\n[Themes App]";
    list lButtons = ["Apply Theme"];
    if(gp(llGetObjectPermMask(MASK_OWNER)) == "full")lButtons += ["New Theme"]; // SL has requirements for full perm or some parameters cannot be read by a script.

    Dialog(kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Main");
}

// Obtained from somewhere on the SL Wiki. TODO: Add credits for the origin of this function's code.
string gp(integer perm)
{
    integer fullPerms = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    integer copyModPerms = PERM_COPY | PERM_MODIFY;
    integer copyTransPerms = PERM_COPY | PERM_TRANSFER;
    integer modTransPerms = PERM_MODIFY | PERM_TRANSFER;
 
    string output = "";
 
    if ((perm & fullPerms) == fullPerms)
        output += "full";
    else if ((perm & copyModPerms) == copyModPerms)
        output += "copy & modify";
    else if ((perm & copyTransPerms) == copyTransPerms)
        output += "copy & transfer";
    else if ((perm & modTransPerms) == modTransPerms)
        output += "modify & transfer";
    else if ((perm & PERM_COPY) == PERM_COPY)
        output += "copy";
    else if ((perm & PERM_TRANSFER) == PERM_TRANSFER)
        output += "transfer";
    else
        output += "none";
 
    //  Remember, items in Second Life must have either
    //  PERM_COPY or PERM_TRANSFER when "talking about"
    //  owner perms or perms for next owner.
 
    return  output;
}

UserCommand(integer iNum, string sStr, key kID) {
    if (iNum!= CMD_OWNER && iNum != CMD_WEARER) return;
    if (iNum == CMD_OWNER && llToLower(sStr) == "runaway") {
        g_lOwner=[];
        g_lTrust=[];
        g_lBlock=[];
        return;
    }
    if (llToLower(sStr)==llToLower(g_sSubMenu) || llToLower(sStr) == "menu "+llToLower(g_sSubMenu)) Menu(kID, iNum);
    //else if (iNum!=CMD_OWNER && iNum!=CMD_TRUSTED && kID!=g_kWearer) RelayNotify(kID,"Access denied!",0);
    else {
        //integer iWSuccess = 0; 
        string sChangetype = llList2String(llParseString2List(sStr, [" "], []),0);
        //string sChangevalue = llList2String(llParseString2List(sStr, [" "], []),1);
        //string sText;
        /// [prefix] g_sSubMenu sChangetype sChangevalue
        
        if(sChangetype == "newtheme"){
            if(gp(llGetObjectPermMask(MASK_OWNER))=="full"){
                PrintCurrentProperties(kID);
            }
        } else if(sChangetype == "hide"){
            // Process collar hide
            if(kID == g_kWearer && !g_iAllowHide){
                llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% due to: Allow Hiding is blocked", kID);
                return;
            } else {
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_hide=1", "");
                ToggleCollarAlpha(FALSE);
            }
        } else if(sChangetype == "show"){
            if(kID == g_kWearer && !g_iAllowHide){
                llMessageLinked(LINK_SET, NOTIFY, "0%NOACCESS% due to: Allow Hiding is blocked", kID);
                return;
            } else{
                llMessageLinked(LINK_SET, LM_SETTING_SAVE, "global_hide=0", "");
                ToggleCollarAlpha(TRUE);
            }
        }
    }
}
integer g_iAllowHide = 1;
//integer g_iHidden;
ToggleCollarAlpha(integer iHide){ // iHide is inverted for the alpha masking. 
    integer i=0;
    integer end = llGetNumberOfPrims();
    for(i=1;i<=end;i++){
        string desc = llList2String(llGetLinkPrimitiveParams(i, [PRIM_DESC]),0);
        list lElements = llParseStringKeepNulls(desc,["~"],[]);
        if(llListFindList(lElements,["nohide"])==-1){
            llSetLinkAlpha(i, iHide, ALL_SIDES);
        }
        if(iHide){
            if(llListFindList(lElements, ["OpenLock"])!=-1){
                //llSay(0, "open lock prim found. Setting alpha: "+(string)(!g_iLocked));
                if(g_iLocked)
                    llSetLinkAlpha(i, FALSE, ALL_SIDES);
                else
                    llSetLinkAlpha(i, TRUE, ALL_SIDES);
            }
            if(llListFindList(lElements, ["ClosedLock"])!=-1 || llListFindList(lElements, ["Lock"]) != -1)
            {
                //llSay(0, "closed lock prim found. Setting alpha: "+(string)g_iLocked);
                if(g_iLocked)
                    llSetLinkAlpha(i, TRUE, ALL_SIDES);
                else
                    llSetLinkAlpha(i, FALSE, ALL_SIDES);
            }
        }
    }
}


list g_lDSRequests;
key NULL=NULL_KEY;
UpdateDSRequest(key orig, key new, string meta){
    if(orig == NULL){
        g_lDSRequests += [new,meta];
    }else {
        integer index = HasDSRequest(orig);
        if(index==-1)return;
        else{
            g_lDSRequests = llListReplaceList(g_lDSRequests, [new,meta], index,index+1);
        }
    }
}

string GetDSMeta(key id){
    integer index=llListFindList(g_lDSRequests,[id]);
    if(index==-1){
        return "N/A";
    }else{
        return llList2String(g_lDSRequests,index+1);
    }
}

integer HasDSRequest(key ID){
    return llListFindList(g_lDSRequests, [ID]);
}

DeleteDSReq(key ID){
    if(HasDSRequest(ID)!=-1)
        g_lDSRequests = llDeleteSubList(g_lDSRequests, HasDSRequest(ID), HasDSRequest(ID)+1);
    else return;
}

list g_lThemes;
ScanThemes(){
    g_lThemes = [];
    
    integer i=0;
    integer end = llGetInventoryNumber(INVENTORY_NOTECARD);
    for(i=0;i<end;i++){
        string item = llGetInventoryName(INVENTORY_NOTECARD, i);
        list lNameParts = llParseString2List(item,["."],[]);
        if(llList2String(lNameParts,1)=="theme"){
            if(llListFindList(g_lThemes,[llList2String(lNameParts,0)])==-1)g_lThemes+=[llList2String(lNameParts,0)];
        }
    }
    
    llMessageLinked(LINK_SET,NOTIFY,"0Found "+(string)llGetListLength(g_lThemes)+" themes", llGetOwner());
}

ThemeSelect(key kAv, integer iAuth){
    Dialog(kAv, "[Theme App]\n\nSelect the theme below that you want to apply", g_lThemes, [UPMENU], 0, iAuth, "Menu~Theme");
}
key g_kWearer;
list g_lMenuIDs;
integer g_iMenuStride;
list g_lOwner;
list g_lTrust;
list g_lBlock;
integer g_iLocked=FALSE;
string sBuffer = "";
E(key kID, string sMsg){
    sBuffer += "\n"+sMsg;
    if(llStringLength(sBuffer)>=700){
        llMessageLinked(LINK_SET,NOTIFY,"0"+sBuffer,kID);
        llSleep(0.05);
        sBuffer = "";
    }
}
EFlush(key kID){
    llMessageLinked(LINK_SET,NOTIFY,"0"+sBuffer,kID);
    sBuffer="";
}
PrintCurrentProperties(key kID){
    // Output the current properties using the theme notecard format
    E(kID, "Simply paste the content to follow into a notecard with a name you want, for example: for a theme to be named Test, (ex. Test.theme)");
    integer i=LINK_ROOT;
    integer end = llGetNumberOfPrims();
    
    for(i=1;i<=end;i++){
        E(kID, "["+(string)i+"/"+(string)llGetLinkName(i)+"/0]");
        E(kID, "#If you set the 0 at the end of the brackets above to a 1, then it will require that the prim's number (beginning of line), and the prims name (middle part) match. Otherwise if this is a zero, as it is by default, then the prim will only go off the prim number.");
        list lParams = llGetLinkPrimitiveParams(i, [PRIM_DESC, PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE, PRIM_NAME]);
        integer sides = llGetLinkNumberOfSides(i);
        E(kID, "desc = "+llList2String(lParams,0));
        E(kID, "pos = "+llList2String(lParams,1));
        E(kID, "rot = "+llList2String(lParams,2));
        E(kID, "scale = "+llList2String(lParams,3));
        E(kID, "name = "+llList2String(lParams,4));
        integer ix=0;
        for(ix=0;ix<sides;ix++){
            list lProperties = llGetLinkPrimitiveParams(i, [PRIM_COLOR, ix, PRIM_TEXTURE, ix, PRIM_GLOW, ix, PRIM_NORMAL,ix, PRIM_SPECULAR, ix, PRIM_FULLBRIGHT, ix, PRIM_BUMP_SHINY, ix]);
            E(kID, "!"+(string)ix+": color = "+llList2String(lProperties,0));
            E(kID, "!"+(string)ix+": alpha = "+llList2String(lProperties,1));
            E(kID, "!"+(string)ix+": shiny = "+llList2String(lProperties,19));
            E(kID, "!"+(string)ix+": bump = "+llList2String(lProperties,20));
            E(kID, "!"+(string)ix+": texture = "+llList2String(lProperties,2));
            E(kID, "!"+(string)ix+": texture_repeat = "+llList2String(lProperties,3));
            E(kID, "!"+(string)ix+": texture_offset = "+llList2String(lProperties,4));
            E(kID, "!"+(string)ix+": texture_rot = "+llList2String(lProperties,5));
            E(kID, "!"+(string)ix+": glow = "+llList2String(lProperties,6));
            E(kID, "!"+(string)ix+": normal = "+llList2String(lProperties,7));
            E(kID, "!"+(string)ix+": normal_repeat = "+llList2String(lProperties,8));
            E(kID, "!"+(string)ix+": normal_offset = "+llList2String(lProperties,9));
            E(kID, "!"+(string)ix+": normal_rot = "+llList2String(lProperties,10));
            E(kID, "!"+(string)ix+": specular = "+llList2String(lProperties,11));
            E(kID, "!"+(string)ix+": specular_repeat = "+llList2String(lProperties,12));
            E(kID, "!"+(string)ix+": specular_offset = "+llList2String(lProperties,13));
            E(kID, "!"+(string)ix+": specular_rot = "+llList2String(lProperties,14));
            E(kID, "!"+(string)ix+": specular_color = "+llList2String(lProperties,15));
            E(kID, "!"+(string)ix+": specular_glossiness = "+llList2String(lProperties,16));
            E(kID, "!"+(string)ix+": specular_environment = "+llList2String(lProperties,17));
            E(kID, "!"+(string)ix+": fullbright = "+llList2String(lProperties,18));
        }
        
    }
    
    E(kID, "#NOTE: Only include the parameters you actually NEED for your theme to apply to prevent hitting the notecard line/text limit!");

    EFlush(kID);
}

integer ALIVE = -55;
integer READY = -56;
integer STARTUP = -57;

string g_sTmp;
default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        //llScriptProfiler(PROFILE_SCRIPT_MEMORY);
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
        
        // Scan the inventory for theme notecards
        ScanThemes();
        
        //llOwnerSay("Free Memory: "+(string)llGetFreeMemory());
    }
    
    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            ScanThemes();
        }
    }
    
    dataserver(key kID, string sData){
        if(HasDSRequest(kID)!=-1){
            if(sData==EOF){
                //End of file
                string meta = GetDSMeta(kID);
                list lTmp = llParseString2List(meta,[":"],[]);
                if((g_sTmp != "" && g_sTmp != "{}"))E(llGetOwner(), "The following was not used for the prim : "+llList2String(lTmp,3)+"  : "+g_sTmp);
                g_sTmp=""; // clear any remaining temporary memory
                DeleteDSReq(kID);
                llMessageLinked(LINK_SET,NOTIFY, "0Theme notecard read", llGetOwner());
                if(llList2String(lTmp,4)!="0")
                    E(llGetOwner(), llList2String(lTmp,4)+" sections of this theme had errors.");
                
            } else {
                string sMeta = GetDSMeta(kID);
                list lTmp = llParseString2List(sMeta,[":"],[]);
                if(llList2String(lTmp,0)=="read_theme"){
                    integer iLine = (integer)llList2String(lTmp,1);
                    string noteLabel = llList2String(lTmp,2);
                    integer iPrim = (integer)llList2String(lTmp,3);
                    string sPrim;
                    integer iErrors = (integer)llList2String(lTmp,4);
                    iLine++;
                    
                    list lData = llParseString2List(sData, ["/"],["[","]"]);
                    if(llList2String(lData,0) == "[" && llList2String(lData,-1) == "]"){
                        if(g_sTmp!="" && g_sTmp!="{}"){
                            iErrors++;
                            E(llGetOwner(), "Data not used for prim ("+(string)iPrim+"): "+g_sTmp);
                        }
                        
                        g_sTmp=""; // Clear the temporary memory
                        iPrim = (integer)llList2String(lData,1);
                        sPrim = llList2String(lData,2);
                        if((llGetLinkName(iPrim)==sPrim && llList2String(lData,3)=="1") || llList2String(lData,3)=="0"){
                            // do nothing here. Just read next line, the params have already been adjusted.
                        }else {
                            iErrors++;
                            iPrim=-1; // Prevent settings from being applied until we reach the next prim.
                        }
                    }else {
                        if(iPrim==-1)jump over;
                        // parameter line
                        list lParam = [];
                        if(llGetSubString(sData,0,0)=="#"){
                            // comment line. Ignore it
                        }else {
                            list lProp = llParseStringKeepNulls(sData, [": ", " = "],["!"]);
                            if(llList2String(lProp,0)=="")lProp=llDeleteSubList(lProp,0,0);
                            
                            
                            if(llList2String(lProp,0)=="!"){
                                // Face parameter line
                                integer iFace = (integer)llList2String(lProp,1);
                                
                                if(llList2String(lProp,2) == "color"){
                                    g_sTmp = llJsonSetValue(g_sTmp,["color"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "alpha"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["alpha"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "texture"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["texture"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "texture_repeat"){
                                    g_sTmp = llJsonSetValue(g_sTmp,["texture_repeat"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "texture_offset"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["texture_offset"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "texture_rot"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["texture_rot"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "glow"){
                                    lParam += [PRIM_GLOW, iFace, (float)llList2String(lProp,3)];
                                } else if(llList2String(lProp,2) == "normal"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["normal"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "normal_repeat"){
                                    g_sTmp = llJsonSetValue(g_sTmp,["normal_repeat"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "normal_offset"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["normal_offset"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "normal_rot"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["normal_rot"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "specular"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "specular_repeat"){
                                    g_sTmp = llJsonSetValue(g_sTmp,["specular_repeat"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "specular_offset"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_offset"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "specular_rot"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_rot"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "specular_color"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_color"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "specular_glossiness"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_glossiness"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "specular_environment"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_environment"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "fullbright"){
                                    lParam += [PRIM_FULLBRIGHT, iFace, (integer)llList2String(lProp,3)];
                                } else if(llList2String(lProp,2) == "shiny"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["shiny"], llList2String(lProp,3));
                                } else if(llList2String(lProp,2) == "bump"){
                                    g_sTmp = llJsonSetValue(g_sTmp, ["bump"], llList2String(lProp,3));
                                }
                                //if(g_sTmp!="")
                                //    llSay(0, "Applier Json: "+g_sTmp);
                                
                                
                                if(llJsonValueType(g_sTmp, ["color"])!= JSON_INVALID && llJsonValueType(g_sTmp,["alpha"])!=JSON_INVALID){
                                    lParam += [PRIM_COLOR, iFace, (vector)llJsonGetValue(g_sTmp, ["color"]), (float)llJsonGetValue(g_sTmp,["alpha"])];
                                    g_sTmp = llJsonSetValue(g_sTmp, ["color"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp,["alpha"], JSON_DELETE);
                                }
                                if(llJsonValueType(g_sTmp,["texture"]) != JSON_INVALID && llJsonValueType(g_sTmp, ["texture_repeat"])!=JSON_INVALID && llJsonValueType (g_sTmp, ["texture_offset"])!=JSON_INVALID && llJsonValueType(g_sTmp,["texture_rot"])!=JSON_INVALID){
                                    lParam += [PRIM_TEXTURE, iFace, (key)llJsonGetValue(g_sTmp, ["texture"]), (vector)llJsonGetValue(g_sTmp, ["texture_repeat"]), (vector)llJsonGetValue(g_sTmp, ["texture_offset"]), (float)llJsonGetValue(g_sTmp, ["texture_rot"])];
                                    g_sTmp = llJsonSetValue(g_sTmp, ["texture"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["texture_repeat"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["texture_offset"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["texture_rot"], JSON_DELETE);
                                    
                                } 
                                if(llJsonValueType(g_sTmp,["normal"]) != JSON_INVALID&& llJsonValueType(g_sTmp, ["normal_repeat"])!=JSON_INVALID  && llJsonValueType (g_sTmp, ["normal_offset"])!=JSON_INVALID && llJsonValueType(g_sTmp,["normal_rot"])!=JSON_INVALID){
                                    lParam += [PRIM_NORMAL, iFace, (key)llJsonGetValue(g_sTmp, ["normal"]), (vector)llJsonGetValue(g_sTmp, ["normal_repeat"]), (vector)llJsonGetValue(g_sTmp, ["normal_offset"]), (float)llJsonGetValue(g_sTmp, ["normal_rot"])];
                                    g_sTmp = llJsonSetValue(g_sTmp, ["normal"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["normal_repeat"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["normal_offset"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["normal_rot"], JSON_DELETE);
                                    
                                } 
                                if(llJsonValueType(g_sTmp,["specular"]) != JSON_INVALID && llJsonValueType(g_sTmp, ["specular_repeat"])!=JSON_INVALID && llJsonValueType (g_sTmp, ["specular_offset"])!=JSON_INVALID && llJsonValueType(g_sTmp,["specular_rot"])!=JSON_INVALID && llJsonValueType(g_sTmp, ["specular_color"]) != JSON_INVALID && llJsonValueType(g_sTmp, ["specular_glossiness"]) != JSON_INVALID && llJsonValueType(g_sTmp,["specular_environment"])!=JSON_INVALID){
                                    lParam += [PRIM_SPECULAR, iFace, (key)llJsonGetValue(g_sTmp, ["specular"]), (vector)llJsonGetValue(g_sTmp, ["specular_repeat"]), (vector)llJsonGetValue(g_sTmp, ["specular_offset"]), (float)llJsonGetValue(g_sTmp, ["specular_rot"]), (vector)llJsonGetValue(g_sTmp, ["specular_color"]), (integer)llJsonGetValue(g_sTmp, ["specular_glossiness"]), (integer)llJsonGetValue(g_sTmp, ["specular_environment"])];
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_repeat"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_offset"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_rot"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_color"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_glossiness"], JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp, ["specular_environment"], JSON_DELETE);
                                    
                                }
                                
                                if(llJsonValueType(g_sTmp,["shiny"])!=JSON_INVALID && llJsonValueType(g_sTmp,["bump"])!=JSON_INVALID){
                                    lParam += [PRIM_BUMP_SHINY, iFace, (integer)llJsonGetValue(g_sTmp, ["shiny"]), (integer)llJsonGetValue(g_sTmp,["bump"])];
                                    g_sTmp = llJsonSetValue(g_sTmp,["shiny"],JSON_DELETE);
                                    g_sTmp = llJsonSetValue(g_sTmp,["bump"],JSON_DELETE);
                                }
                            } else {
                                // Prim parameter
                                if(llList2String(lProp,0)=="desc"){
                                    lParam += [PRIM_DESC, llList2String(lProp,1)];
                                } else if(llList2String(lProp,0) == "pos"){
                                    lParam += [PRIM_POS_LOCAL, (vector)llList2String(lProp,1)];
                                } else if(llList2String(lProp,0) == "rot"){
                                    lParam += [PRIM_ROT_LOCAL, (rotation)llList2String(lProp, 1)];
                                } else if(llList2String(lProp,0) == "scale"){
                                    lParam += [PRIM_SIZE, (vector)llList2String(lProp,1)];
                                } else if(llList2String(lProp,0)=="name"){
                                    lParam += [PRIM_NAME, llList2String(lProp,1)];
                                }
                            }
                        }
                        
                        if(llGetListLength(lParam)>0){
                            //llSay(0, "Apply : "+llDumpList2String(lParam,"~"));
                            llSetLinkPrimitiveParams(iPrim, lParam);
                            lParam=[];
                        }
                    }
                    @over;
                    UpdateDSRequest(kID, llGetNotecardLine(noteLabel+".theme", iLine), "read_theme:"+(string)iLine+":"+noteLabel+":"+(string)iPrim+":"+(string)iErrors);
                }
            }
        }
    }
    link_message(integer iSender,integer iNum,string sStr,key kID){
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
                integer iRespring = TRUE;
                if(sMenu == "Menu~Main"){
                    if(sMsg == UPMENU) {
                        iRespring=FALSE;
                        llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    } else if(sMsg == "New Theme"){
                        PrintCurrentProperties(kAv);
                    } else if(sMsg == "Apply Theme"){
                        iRespring=FALSE;
                        ThemeSelect(kAv,iAuth);
                    }
                    
                    
                    if(iRespring)Menu(kAv,iAuth);
                    
                } else if(sMenu == "Menu~Theme"){
                    if(sMsg == UPMENU){
                        iRespring=FALSE;
                        Menu(kAv,iAuth);
                    } else {
                        // Theme selection page, we now check for this theme and apply it
                        if(llGetInventoryType(sMsg+".theme")==INVENTORY_NOTECARD){
                            E(kAv, "Applying Theme to collar..");
                            g_lDSRequests=[];
                            UpdateDSRequest(NULL, llGetNotecardLine(sMsg+".theme",0), "read_theme:0:"+sMsg+":-1:0");
                        } else {
                            E(kAv, "No theme with that name could be found. This is an error: "+(string)llGetInventoryType(sMsg+".theme"));
                        }
                    }
                    
                    
                    if(iRespring)ThemeSelect(kAv,iAuth);
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
                if(sVar=="allowhide"){
                    g_iAllowHide=(integer)sVal;
                } else if(sVar == "hide"){
                    g_iHide = (integer)sVal;
                    ToggleCollarAlpha(!g_iHide);
                } else if(sVar == "locked"){
                    g_iLocked = (integer)sVal;
                    ToggleCollarAlpha(!g_iHide);
                }
            }/* else if(sToken == "auth"){
                if(sVar == "owner"){
                    g_lOwners = llParseString2List(sVal,[","],[]);
                }
            }*/
        } else if(iNum == LM_SETTING_DELETE){
            // This is received back from settings when a setting is deleted
            list lSettings = llParseString2List(sStr, ["_"],[]);
            if(llList2String(lSettings,0)=="global"){
                if(llList2String(lSettings,1) == "locked") {
                    g_iLocked=FALSE;
                    ToggleCollarAlpha(!g_iHide);
                }
            }
        } else if(iNum == REBOOT){
            // Reboot. We dont care if --f or not.
            llResetScript();
        }
        //llOwnerSay(llDumpList2String([iSender,iNum,sStr,kID],"^"));
    }
}
