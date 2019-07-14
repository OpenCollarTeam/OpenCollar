// This file is part of OpenCollar.
// Copyright (c) 2008 - 2017 Nandana Singh, Garvin Twine, Cleo Collins,  
// Satomi Ahn, Kisamin, Joy Stipe, Wendy Starfall, littlemousy,      
// Romka Swallowtail, Mano Nevadan, and other contributors.  
// Licensed under the GPLv2.  See LICENSE for full details. 

string g_sScriptVersion = "7.2";
string g_sAppVersion = "1.5";

string g_sParentMenu = "Apps";
string g_sSubMenu = "Titler";
string g_sPrimDesc = "FloatText";   //description text of the hovertext prim.  Needs to be separated from the menu name.
string g_sPartDesc = "FloatPart";   //description text of the particle-emitting prim.

//MESSAGE MAP
//integer CMD_ZERO = 0;
integer CMD_OWNER            = 500;
//integer CMD_TRUSTED        = 501;
//integer CMD_GROUP          = 502;
integer CMD_WEARER           = 503;
integer CMD_EVERYONE         = 504;
//integer CMD_RLV_RELAY      = 507;
//integer CMD_SAFEWORD       = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;
integer LINK_CMD_DEBUG = 1999;
integer NOTIFY = 1002;
//integer SAY = 1004;
integer REBOOT              = -1000;
integer LINK_DIALOG         = 3;
//integer LINK_RLV            = 4;
integer LINK_SAVE           = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
//integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;


integer g_iLastRank = CMD_EVERYONE ;
integer g_iOn = FALSE;
string g_sText;
vector g_vColor = <1.0,1.0,1.0>; // default white
string g_sParticle = "";

integer g_iTextPrim;
integer g_iPartPrim;
vector g_vPartOffset = <0.0, 0.0, 0.2>;
vector g_vPartSize = <0.3, 0.3, 0.0>;

key g_kWearer;
string g_sSettingToken = "titler_";

list g_lMenuIDs;  //three strided list of avkey, dialogid, and menuname
integer g_iMenuStride = 3;

string SET = "Set Title" ;
string UP = "↑ Up";
string DN = "↓ Down";
string ON = "☑ Show";
string OFF = "☐ Show";
string UPMENU = "BACK";
float min_z = 0.25 ; // min height
float max_z = 1.0 ; // max height
vector g_vPrimScale = <0.08,0.08,0.4>; // prim size, initial value (z - text offset height)

list ATTACH_POINT_ROTATIONS = [
    ATTACH_BACK, <-90,0,0>,
    ATTACH_CHEST, <90,0,0>
];

Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string iMenuType) {
    key kMenuID = llGenerateKey();
    llMessageLinked(LINK_DIALOG, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kMenuID);
    integer iIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    if (~iIndex) g_lMenuIDs = llListReplaceList(g_lMenuIDs, [kRCPT, kMenuID, iMenuType], iIndex, iIndex + g_iMenuStride - 1);
    else g_lMenuIDs += [kRCPT, kMenuID, iMenuType];
}

ShowHideTitle() {
    if (g_iTextPrim >0){
        if (g_sText == "") g_iOn = FALSE;
        llSetLinkPrimitiveParamsFast(g_iTextPrim, [PRIM_TEXT,g_sText,g_vColor,(float)g_iOn, PRIM_SIZE,g_vPrimScale, PRIM_SLICE,<0.490,0.51,0.0>]);
    }
    if (g_iPartPrim > 0) {
        if (g_sParticle == "") {
          llLinkParticleSystem(g_iPartPrim,[]);
          if (g_iPartPrim == g_iTextPrim) {
            llSetLinkPrimitiveParamsFast(g_iTextPrim,
                                         [PRIM_POS_LOCAL, <0,0,0>]);
          }
        }
        else {
            rotation start = ZERO_ROTATION;
            integer idx = llListFindList(ATTACH_POINT_ROTATIONS, [llGetAttached()]);
            if (~idx) {
                start = llEuler2Rot(llList2Vector(ATTACH_POINT_ROTATIONS, idx + 1) * DEG_TO_RAD);
            }
            vector pos = (g_vPartOffset + <0.,0, g_vPrimScale.z>)/(start * llGetLocalRot());
            llSetLinkPrimitiveParamsFast(g_iPartPrim, [
                PRIM_POS_LOCAL, pos
            ]);
            llLinkParticleSystem(g_iPartPrim, [
                PSYS_SRC_PATTERN, PSYS_SRC_PATTERN_DROP,
                PSYS_PART_FLAGS,
                    PSYS_PART_EMISSIVE_MASK|
                    PSYS_PART_FOLLOW_SRC_MASK,
                PSYS_SRC_TEXTURE, g_sParticle,
                PSYS_SRC_BURST_RATE, 1,
                PSYS_PART_MAX_AGE, 8,
                PSYS_SRC_BURST_PART_COUNT, 1,
                PSYS_PART_START_SCALE, g_vPartSize
            ]);
        }
    }
}

ConfirmDeleteMenu(key kAv, integer iAuth) {
    string sPrompt ="\nDo you really want to uninstall the "+g_sSubMenu+" App?";
    Dialog(kAv, sPrompt, ["Yes","No","Cancel"], [], 0, iAuth,"rmtitler");
}

list g_lStdImagess = [
    "afk", "888ba27f-8d54-69f9-1455-d8cb13274dc9",
    "halo", "4dfc5618-d450-86cf-401b-ccf27152ed83",
    "naughty", "f4805503-17d5-0371-6511-e0e4f23b1823",
    "phone", "e2f59357-91fd-fe27-21c9-473dda1538bf",
    "quest", "7a9d082f-e547-3cef-b034-ea676bdca3ed",
    "sleep", "4c564db7-5a8e-56c0-fb57-ed8433c12228",
    "star", "be5ee4dc-2fbb-8cd9-1fac-bdab4ab93972"
];

list g_lImages;

AssembleTextures() {
  g_lImages = g_lStdImagess;
  integer iHowMany = llGetInventoryNumber(INVENTORY_TEXTURE);
  integer i;
  for (i=0; i<iHowMany; i++) {
    string name = llGetInventoryName(INVENTORY_TEXTURE, i);
    key k = llGetInventoryKey(name);
    g_lImages = g_lImages + [name, k];
  }
}

ImageMenu(key kAv, integer iAuth) {
  Dialog(
    kAv,
    "Hang an image overhead",
    ["OFF", "BIGGER", "SMALLER", "CUSTOM"] + llList2ListStrided(g_lImages, 0, -1, 2),
    [UPMENU],
    0,
    iAuth,
    "image"
  );
}

string FindImage(string name) {
  integer ind = llListFindList(g_lImages, [name]);
  if (ind < 0 || ind % 2 != 0) {
    return name;
  }
  return llList2String(g_lImages, ind+1);
}

TitlerMenu(key kAv, integer iAuth) {
    string ON_OFF ;
    string sPrompt;
    if (g_iTextPrim == -1) {
        sPrompt = "\n[Titler]\t"+g_sAppVersion+"\n\nThis design is missing a FloatText box. Titler disabled.";
        Dialog(kAv, sPrompt, [], [UPMENU],0, iAuth,"main");
    } else {
        sPrompt = "\n[Titler]\t"+g_sAppVersion+"\n\nCurrent Title: " + g_sText ;
        if(g_iOn == TRUE) ON_OFF = ON ;
        else ON_OFF = OFF ;
        Dialog(kAv, sPrompt, [SET,UP,DN,ON_OFF,"Color", "Image"], [UPMENU],0, iAuth,"main");
    }    
}

UserCommand(integer iAuth, string sStr, key kAv) {
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llToLower(llList2String(lParams, 0));
    string sAction = llToLower(llList2String(lParams, 1));
    string sLowerStr = llToLower(sStr);
    if (sLowerStr == "menu titler" || sLowerStr == "titler") {
        TitlerMenu(kAv, iAuth);
    } else if (sLowerStr == "menu titler color" || sLowerStr == "titler color") {
        Dialog(kAv, "\n\nSelect a color from the list", ["colormenu please"], [UPMENU],0, iAuth,"color");
    } else if ((sCommand=="titler" || sCommand == "title") && sAction == "color") {
        string sColor= llDumpList2String(llDeleteSubList(lParams,0,1)," ");
        if (sColor != ""){
            g_vColor=(vector)sColor;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"color="+(string)g_vColor, "");
        }
        ShowHideTitle();
    } else if (sCommand=="titler" && sAction == "box")
        Dialog(kAv, "\n- Submit the new title in the field below.\n- Submit a blank field to go back to " + g_sSubMenu + ".", [], [], 0, iAuth,"textbox");
    else if (sStr == "runaway" && (iAuth == CMD_OWNER || iAuth == CMD_WEARER)) {
        UserCommand(CMD_OWNER,"title off", g_kWearer);
    } else if (sCommand == "image") {
        
        if(g_sParticle == "" && g_iOn==FALSE) g_iLastRank = CMD_EVERYONE; 
        if(iAuth > g_iLastRank){
            llMessageLinked(LINK_DIALOG, NOTIFY, "0%NOACCESS% to change titler particles.", kAv);
            return;
        }
        g_iLastRank=iAuth;
      if (sAction == "") ImageMenu(kAv, iAuth);
      else if (sAction == "bigger") {
        float fNew = g_vPartSize.x + 0.1;
        if (fNew > 2.0) fNew = 2.0;
        g_vPartSize = < fNew, fNew, 0.0 >;
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"particlesize="+(string)g_vPartSize, "");
      } else if (sAction == "smaller") {
        float fNew = g_vPartSize.x - 0.1;
        if (fNew < 0.1) fNew = 0.1;
        g_vPartSize = < fNew, fNew, 0.0 >;
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"particlesize="+(string)g_vPartSize, "");
      } else if (sAction == "off") {
          if(!g_iOn)g_iLastRank=CMD_EVERYONE;
        g_sParticle = "";
        llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"particle", "");
      } else if (sAction == "custom") {
        Dialog(kAv, "\n- Enter a texture uuid to use as the image", [], [], 0, iAuth, "image");
      } else {
        g_sParticle = FindImage(llGetSubString(sStr, llStringLength("image "), -1));
        llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"particle="+g_sParticle, "");
      }
      ShowHideTitle();
    } else if (sCommand == "title") {
        integer iIsCommand;
        if (llGetListLength(lParams) <= 2) iIsCommand = TRUE;
        if(g_sParticle == "" && g_iOn==FALSE) g_iLastRank = CMD_EVERYONE; 
        if ( iAuth > g_iLastRank){ //only change text if commander has same or greater auth 
            llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"You currently have not the right to change the Titler settings, someone with a higher rank set it!",kAv);
            return;
        }
        else if (sAction == "on") {
            g_iLastRank = iAuth;
            g_iOn = TRUE;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, "");  // save lastrank to DB
        } else if (sAction == "off" && iIsCommand) {
             
            g_iLastRank = CMD_EVERYONE;
            g_iOn = FALSE;
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"on", "");
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"auth", ""); // del lastrank from DB
            
        } else if (sAction == "image") {
          string sNewText= llDumpList2String(llDeleteSubList(lParams, 0, 1), " ");
          g_sParticle = sNewText;
          if (sNewText == "") {
            llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"particle", "");
          } else {
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"particle="+g_sParticle, "");
          }
        } else if (sAction == "up" && iIsCommand) {
            g_vPrimScale.z += 0.05 ;
            if(g_vPrimScale.z > max_z) g_vPrimScale.z = max_z ;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"height="+(string)g_vPrimScale.z, "");
        } else if (sAction ==  "down" && iIsCommand) {
            g_vPrimScale.z -= 0.05 ;
            if(g_vPrimScale.z < min_z) g_vPrimScale.z = min_z ;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"height="+(string)g_vPrimScale.z, "");
        } else {//if (sAction == "text") {
            //string sNewText= llDumpList2String(llDeleteSubList(lParams, 0, 1), " ");//pop off the "text" command
            string sNewText= llDumpList2String(llDeleteSubList(lParams, 0, 0), " ");
            g_sText = llDumpList2String(llParseStringKeepNulls(sNewText, ["\\n"], []), "\n");// make it possible to insert line breaks in hover text
            if (sNewText == "") {
                g_iOn = FALSE;
                llMessageLinked(LINK_SAVE, LM_SETTING_DELETE, g_sSettingToken+"title", "");
            } else {
                g_iOn = TRUE;
                llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"title="+g_sText, "");
            }
            g_iLastRank=iAuth;
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"on="+(string)g_iOn, "");
            llMessageLinked(LINK_SAVE, LM_SETTING_SAVE, g_sSettingToken+"auth="+(string)g_iLastRank, ""); // save lastrank to DB
        }
        ShowHideTitle();
    } else if (sStr == "rm titler") {
            if (kAv!=g_kWearer && iAuth!=CMD_OWNER) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS% to uninstalling titler",kAv);
            else ConfirmDeleteMenu(kAv, iAuth);
    }
}

default{
    state_entry(){
        g_iTextPrim = -1 ;
        integer linkNumber = llGetNumberOfPrims()+1;
        while (linkNumber-- >2){
            string desc = llList2String(llGetLinkPrimitiveParams(linkNumber, [PRIM_DESC]),0);
            if (llSubStringIndex(desc, g_sPrimDesc) == 0) {
                    g_iTextPrim = linkNumber;
                    llSetLinkPrimitiveParamsFast(g_iTextPrim,[PRIM_TYPE,PRIM_TYPE_CYLINDER,0,<0.0,1.0,0.0>,0.0,ZERO_VECTOR,<1.0,1.0,0.0>,ZERO_VECTOR,PRIM_TEXTURE,ALL_SIDES,TEXTURE_TRANSPARENT,<1.0, 1.0, 0.0>,ZERO_VECTOR,0.0,PRIM_DESC,g_sPrimDesc+"~notexture~nocolor~nohide~noshiny~noglow"]);
                    llLinkParticleSystem(linkNumber, []);
          } else {
            if (llSubStringIndex(desc, g_sPartDesc) == 0) {
              g_iPartPrim = linkNumber;
              llSetLinkPrimitiveParamsFast(g_iPartPrim, [PRIM_TYPE,PRIM_TYPE_CYLINDER,0,<0.0,1.0,0.0>,0.95,ZERO_VECTOR,<1.0,1.0,0.0>,ZERO_VECTOR,PRIM_TEXTURE,ALL_SIDES,TEXTURE_TRANSPARENT,<1.0, 1.0, 0.0>,ZERO_VECTOR,0.0,PRIM_SIZE,<0.01,0.01,0.01>,PRIM_SLICE,<0.49,0.51,0.0>,PRIM_DESC,g_sPartDesc+"~notexture~nocolor~nohide~noshiny~noglow"]);
            }
            llSetLinkPrimitiveParamsFast(linkNumber,[PRIM_TEXT,"",<0,0,0>,0]);
            llLinkParticleSystem(linkNumber, []);
          }
        }
        // If there's only one prim, share.
        if (g_iPartPrim <= 0) {
          g_iPartPrim = g_iTextPrim;
        }
        g_kWearer = llGetOwner();
        AssembleTextures();

        if (g_iTextPrim < 0 && llSubStringIndex(llGetObjectName(), "Updater") == -1) {
            llMessageLinked(LINK_ROOT, MENUNAME_REMOVE, g_sParentMenu + "|" + g_sSubMenu, "");
            llRemoveInventory(llGetScriptName());
        }
        ShowHideTitle();
    }

    link_message(integer iSender, integer iNum, string sStr, key kID){
        if (iNum >= CMD_OWNER && iNum <= CMD_EVERYONE) UserCommand(iNum, sStr, kID);
        else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu)
            llMessageLinked(iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        else if (iNum == LM_SETTING_RESPONSE) {
            string sGroup = llGetSubString(sStr, 0,  llSubStringIndex(sStr, "_") );
            string sToken = llGetSubString(sStr, llSubStringIndex(sStr, "_")+1, llSubStringIndex(sStr, "=")-1);
            string sValue = llGetSubString(sStr, llSubStringIndex(sStr, "=")+1, -1);
            if (sGroup == g_sSettingToken) {
                if(sToken == "title") g_sText = sValue;
                if(sToken == "on") g_iOn = (integer)sValue;
                if(sToken == "color") g_vColor = (vector)sValue;
                if(sToken == "height") g_vPrimScale.z = (float)sValue;
                if(sToken == "auth") g_iLastRank = (integer)sValue; // restore lastrank from DB
                if(sToken == "particle") g_sParticle = sValue;
                if(sToken == "particlesize") g_vPartSize = (vector)sValue;
            } else if( sStr == "settings=sent") ShowHideTitle();
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);
                string sMessage = llList2String(lMenuParams, 1);
                //integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                if (sMenuType == "main") {
                    if (sMessage == SET) UserCommand(iAuth, "titler box", kAv);
                    else if (sMessage == "Color") UserCommand(iAuth, "menu titler color", kAv);
                    else if (sMessage == UPMENU) llMessageLinked(LINK_ROOT, iAuth, "menu " + g_sParentMenu, kAv);
                    else if (sMessage == "Uninstall") ConfirmDeleteMenu(kAv,iAuth);
                    else if (sMessage == "Image") ImageMenu(kAv,iAuth);
                    else {
                        if (sMessage == UP) UserCommand(iAuth, "title up", kAv);
                        else if (sMessage == DN) UserCommand(iAuth, "title down", kAv);
                        else if (sMessage == OFF) UserCommand(iAuth, "title on", kAv);
                        else if (sMessage == ON) UserCommand(iAuth, "title off", kAv);
                        UserCommand(iAuth, "menu titler", kAv);
                    }
                } else if (sMenuType == "color") {  //response form the colours menu
                    if (sMessage == UPMENU) UserCommand(iAuth, "menu titler", kAv);
                    else {
                        UserCommand(iAuth, "titler color "+sMessage, kAv);
                        UserCommand(iAuth, "menu titler color", kAv);
                    }
                } else if (sMenuType == "image") {
                  if (sMessage == "") {
                    UserCommand(iAuth, "image", kAv);
                  } else if (sMessage == UPMENU) {
                    TitlerMenu(kAv, iAuth);
                    return;
                  } else if (sMessage == "BIGGER") {
                    UserCommand(iAuth, "image bigger", kAv);
                  } else if (sMessage == "SMALLER") {
                    UserCommand(iAuth, "image smaller", kAv);
                  } else UserCommand(iAuth, "image "+llToLower(sMessage), kAv);
                  ShowHideTitle();
                  if (sMessage != "CUSTOM") {// don't remenu if we're giving a textbox already
                      ImageMenu(kAv, iAuth);
                  }
                }
                else if (sMenuType == "textbox") {  //response from text box
                    if(sMessage != " ") UserCommand(iAuth, "title " + sMessage, kAv);
                    UserCommand(iAuth, "menu " + g_sSubMenu, kAv);
                } else if (sMenuType == "rmtitler") {
                    if (sMessage == "Yes") {
                        llMessageLinked(LINK_ROOT, MENUNAME_REMOVE , g_sParentMenu + "|" + g_sSubMenu, "");
                        llMessageLinked(LINK_DIALOG, NOTIFY, "1"+g_sSubMenu+" App has been removed.", kAv);
                    if (llGetInventoryType(llGetScriptName()) == INVENTORY_SCRIPT) llRemoveInventory(llGetScriptName());
                    } else llMessageLinked(LINK_DIALOG, NOTIFY, "0"+g_sSubMenu+" App remains installed.", kAv);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex +3);  //remove stride from g_lMenuIDs
        } else if (iNum == LINK_UPDATE) {
            if (sStr == "LINK_DIALOG") LINK_DIALOG = iSender;
            else if (sStr == "LINK_SAVE") LINK_SAVE = iSender;
        } else if (iNum == REBOOT && sStr == "reboot") llResetScript();
        else if(iNum == LINK_CMD_DEBUG){
            integer iOnlyver=FALSE;
            if(sStr=="ver"){
                iOnlyver=TRUE;
            }
            llInstantMessage(kID, llGetScriptName()+" SCRIPT VERSION: "+g_sScriptVersion);
            if(iOnlyver)return;
            llInstantMessage(kID, llGetScriptName()+" TITLE TEXT: "+g_sText);
            llInstantMessage(kID, llGetScriptName()+" ON: "+(string)g_iOn);
            llInstantMessage(kID, llGetScriptName()+" PARTICLE: "+g_sParticle);
            llInstantMessage(kID, llGetScriptName()+" LAST AUTH: "+(string)g_iLastRank);

        }
    }

    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) llResetScript();
    }

    on_rez(integer param){
        llResetScript();
    }
}
