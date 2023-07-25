/*
This file is a part of OpenCollar.
Copyright ©2021
: Contributors :
Aria (Tashia Redrose)
    * Oct 2020       -       Created oc_themes
Kristen Mynx
    * May 2022       -       Modify to oc_cuff_themes    
et al.
Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

integer API_CHANNEL = 0x60b97b5e;
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

    //llOwnerSay("Found "+(string)llGetListLength(g_lThemes)+" themes");
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
        llOwnerSay(sBuffer);
        llSleep(0.05);
        sBuffer = "";
    }
}
EFlush(key kID){
    llOwnerSay(sBuffer);
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

    state_entry()
    {
        g_kWearer = llGetOwner();

        // Scan the inventory for theme notecards
        ScanThemes();

        //llOwnerSay("Free Memory: "+(string)llGetFreeMemory());
        // so we can evesdrop on messages from the collar
        // specifically -9001 where a string matches a notecard ending in .theme
        API_CHANNEL = ((integer)("0x" + llGetSubString((string)llGetOwner(), 0, 8))) + 0xf6eb - 0xd2;
        llListen(API_CHANNEL, "", "", "");        
    }

    changed(integer iChange){
        if(iChange&CHANGED_INVENTORY){
            ScanThemes();
        }
    }
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(iNum == -1){ // oc_cuff sends this when it starts (which is also on_rez)
            llResetScript();
        }
        if (iNum == 32) // [New Theme] from oc_cuff script
        {
            PrintCurrentProperties(kID);
        }
    }
    listen(integer channel, string name, key id, string msg){
        if(channel==API_CHANNEL && llGetOwner() == llGetOwnerKey(id)){ // also be sure its a message from my collar
            string sPacketType = llJsonGetValue(msg, ["pkt_type"]);
            if (sPacketType == "from_collar"){
                integer iNum = (integer)llJsonGetValue(msg, ["iNum"]);
                string sMsg = llJsonGetValue(msg, ["sMsg"]);
                if (iNum == DIALOG_RESPONSE){
                    list lMenuParams = llParseString2List(sMsg, ["|"],[]);
                    integer iCmd = llList2Integer(lMenuParams,3);
                    if (iCmd >= CMD_OWNER && iCmd <= CMD_WEARER) // authorized
                    {
                        key kAv = llList2Key(lMenuParams,1);
                        string sMsg = llList2String(lMenuParams,1);
                        if(llGetInventoryType(sMsg+".theme")==INVENTORY_NOTECARD){
                            E(kAv, "Applying Theme to cuff..");
                            g_lDSRequests=[];
                            UpdateDSRequest(NULL, llGetNotecardLine(sMsg+".theme",0), "read_theme:0:"+sMsg+":-1:0");
                        }
                    }
                } else if(iNum == LM_SETTING_RESPONSE){
                    // Detect here the Settings
                    list lSettings = llParseString2List(sMsg, ["_","="],[]);
                    string sToken = llList2String(lSettings,0);
                    string sVar = llList2String(lSettings,1);
                    string sVal = llList2String(lSettings,2);
                    if(sToken=="global"){
                        if(sVar=="allowhide"){
                            g_iAllowHide=(integer)sVal;
                        }
                    }
                }
            }
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
                llOwnerSay("Theme notecard read");
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
}
