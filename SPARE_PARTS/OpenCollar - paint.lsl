////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                              OpenCollar - paint                                //
//                                 version 3.980                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2014  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
//                    github.com/OpenCollar/OpenCollarUpdater                     //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

string g_sSubMenu = "Paint";
string g_sParentMenu = "Main";
string CTYPE = "collar";
key g_kWearer;
string UPMENU = "BACK";

integer COMMAND_OWNER = 500;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

integer LM_SETTING_SAVE = 2000;//scripts send messages on this channel to have settings saved to httpdb
integer LM_SETTING_RESPONSE = 2002;//the httpdb script will send responses on this channel

integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

//script specific variables
list g_lMenuIDs;//3-strided list of avkey, dialogid, menuname
integer g_iMenuStride = 3;

integer g_iAllAlpha = 1 ;   //whole collar hide state
list g_lElementTypes;   //list of element types
list g_lElementTypesUnHideable; //llist of hideable state for g_lElementTypes
list g_lAlphaSettings;    //list of currently hidden state of g_lElementTypes
list g_lElementTypesLower; //lower case names, for chat command access

list g_lTexturesCard;
key g_iTexturesCardId;
key g_kNotecardReadRequest;
string g_sTexturesNotecardName="~paint";
integer g_iTexturesNotecardLine=0;

//standard OC functions
Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string menuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    
    integer iMenuIndex = llListFindList(g_lMenuIDs, [kRCPT]);
    list lAddMe = [kRCPT, kID, menuType];
    if (iMenuIndex == -1) g_lMenuIDs += lAddMe;
    else g_lMenuIDs = llListReplaceList(g_lMenuIDs, lAddMe, iMenuIndex, iMenuIndex + g_iMenuStride - 1);
} 

Notify(key kID, string sMsg, integer iAlsoNotifyWearer) {
    if (kID == g_kWearer) llOwnerSay(sMsg);
    else {
        llInstantMessage(kID,sMsg);
        if (iAlsoNotifyWearer) llOwnerSay(sMsg);
    }
}

Debug(string sStr){llOwnerSay(llGetScriptName() + ": " + sStr);}

//menu generators
ElementsMenu(key kAv, integer iAuth) {
    list lButtons;
    if (g_iAllAlpha) lButtons=["Invisible"];
    else lButtons=["Visible"];
    
    integer numElementTypes=llGetListLength(g_lElementTypes);
    while (numElementTypes--) lButtons += llList2String(g_lElementTypes,numElementTypes);
    
    Dialog(kAv,  "\nSelect an element from the list", lButtons, [UPMENU],0, iAuth, "ElementsMenu");
}

ElementMenu(key kAv, integer iAuth, string sMessage){
    list lButtons;
    integer elementIndex=llListFindList(g_lElementTypesLower,[sMessage]);
    if (! llList2Integer(g_lElementTypesUnHideable,elementIndex)){
        if (llList2Integer(g_lAlphaSettings,elementIndex)) lButtons=["Invisible"];
        else lButtons=["Visible"];
    }
    
    integer numFields=llGetListLength(g_lTexturesCard);
    while(numFields){
        numFields -= 4;
        string elementType=llToLower(llList2String(g_lTexturesCard,(numFields)+0));
        if (elementType==llToLower(sMessage)) {
            lButtons += llList2String(g_lTexturesCard,(numFields)+1);
        }
    }

    Dialog(kAv, "\nSelect a style for the '"+llList2String(g_lElementTypes,elementIndex)+"' elements", lButtons, [UPMENU], 0, iAuth, "element "+sMessage);
}

//script specific functions
buildElementTypes(){  //builds three lists, one of element names, matching one of nohide status for the element group, and a matching currentlyHidden list 
    g_lElementTypes=[];
    g_lElementTypesLower=[];
    g_lElementTypesUnHideable=[];
    g_lAlphaSettings=[];
    
    integer iLinkCount = llGetNumberOfPrims();
    while (iLinkCount-- > 2) {
        string description=llStringTrim(llList2String(llGetLinkPrimitiveParams(iLinkCount,[PRIM_DESC]),0),STRING_TRIM);
        list descriptionParts=llParseStringKeepNulls(description,["~"],[]);
        string type=llList2String(descriptionParts,0);
        if ( (llListFindList(descriptionParts,["nocolor"])==-1 || llListFindList(descriptionParts,["notexture"])==-1 || llListFindList(descriptionParts,["nohide"])==-1 ) && ( type != "" || type != "(No Description)") ) {
            integer elementIndex=llListFindList(g_lElementTypes,[type]);
            if (! ~elementIndex ){  //new element type, make list entries and set element index
                elementIndex=llGetListLength(g_lElementTypes);
                g_lElementTypes+=type;
                g_lElementTypesLower+=llToLower(type);
                g_lElementTypesUnHideable+=TRUE;
                g_lAlphaSettings+=TRUE;
            }
            if (llList2Integer(g_lElementTypesUnHideable,elementIndex)){   //all of this element type so far have been unhideable.  If this one is too, the element stays unhideable
                if (! ~llListFindList(descriptionParts, ["nohide"])){  //this element is hideable, therefore the element type as a whole is not unhideable
                    g_lElementTypesUnHideable=llListReplaceList(g_lElementTypesUnHideable,[FALSE],elementIndex,elementIndex);
                }
            }
        }
    }
}

setElementStyle(string elementType,string sMessage){
    //Debug("Setting style of "+elementType+" to "+sMessage);
    integer styleIndex=llListFindList(g_lTexturesCard,[elementType,sMessage]);
    //Debug("styleIndex "+(string)styleIndex);
    if (~styleIndex){
        key textureKey=llList2Key(g_lTexturesCard,styleIndex+2);
        vector color=(vector)llList2String(g_lTexturesCard,styleIndex+3);

        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "texture_"+elementType + "=" + (string)sMessage, "");
        
        integer numElements = llGetNumberOfPrims();
        while (numElements-- > 2) {
            string sDesc = llList2String(llGetLinkPrimitiveParams(numElements, [PRIM_DESC]),0);
            list descriptionParts = llParseString2List(sDesc, ["~"], []);
            string thisElementType=llList2String(descriptionParts, 0);
            if (elementType==llToLower(thisElementType)) {  //if this element is the type we're looking for
                //calculate and set new texture key
                list params ;
                if ((key)textureKey){
                    if (! ~llListFindList(descriptionParts,["notexture"])){
                        //Debug("Setting texture to "+(string)textureKey);
                        params += [PRIM_TEXTURE,ALL_SIDES,textureKey, <1.0,1.0,1.0>, <0.0,0.0,0.0>, 0.0] ;
                    }
                }                
                if (! ~llListFindList(descriptionParts, ["nocolor"]) ){                    
                    list oldColourParams=llGetLinkPrimitiveParams(numElements,[PRIM_COLOR,ALL_SIDES]);  //get current prim params
                    float alpha=llList2Float(oldColourParams,1);  //calculate the old alpha to re-apply                    
                    params += [PRIM_COLOR, ALL_SIDES, color, alpha];
                }
                if (llGetListLength(params) > 3) llSetLinkPrimitiveParamsFast(numElements, params);
            }
        }
    } else {
        //Debug("Can't do "+elementType+" to "+sMessage);
    }
}

ApplyElementAlpha(string element_to_set, integer iAlpha) {
    integer iLinkCount = llGetNumberOfPrims();
    //Debug(element_to_set+" "+ (string)iAlpha);    
    while (iLinkCount-- > 2) {
        string sDesc = llList2String(llGetLinkPrimitiveParams(iLinkCount, [PRIM_DESC]),0);
        list descriptionParts = llParseString2List(sDesc, ["~"], []);
        string elementType=llToLower(llList2String(descriptionParts, 0));
        if (elementType==llToLower(element_to_set) || element_to_set=="all"){  //if this element is the type we want to set, or we're hiding everything
            //Debug("Changing "+element_to_set);
            if (! ~llListFindList(descriptionParts, ["nohide"]) || element_to_set=="all"){  //unless the element is set to nohide, or we're hiding everything
                
                integer elementTypeIndex=llListFindList(g_lElementTypesLower, [elementType]);
                integer elementTypeVisible; //flag to say if this element type is currently visible
                if (~ elementTypeIndex){
                    elementTypeVisible=llList2Integer(g_lAlphaSettings,elementTypeIndex);
                }
                
                
                if (iAlpha && g_iAllAlpha && (elementTypeVisible || ~llListFindList(descriptionParts, ["nohide"]))){   //its a show, and collar is globally visible, and this element type is set visible
                        //Debug("Global visible, so set this element to visible");
                        llSetLinkAlpha(iLinkCount, (float)iAlpha, ALL_SIDES); //set element visibility
                } else {  //its a hide, or collar is globally hidden, or this item is set to be hidden
                    //Debug("Hide this element");
                    llSetLinkAlpha(iLinkCount, 0.0, ALL_SIDES); //set element visibility
                }
            } else {
                //Debug("Element set to nohide, and we're not setting global visible");
            }
        } else {
            //Debug (elementType + "!="+llToLower(element_to_set));
        }
    }
}

SetElementAlpha(string element_to_set, integer iAlpha) {
    element_to_set=llToLower(element_to_set);
    //Debug("Setting alpha for elements of type "+element_to_set+" to "+(string)iAlpha);
    //update element in list of settings
    if (element_to_set == "all"){ //mark entire collar's visibility
        g_iAllAlpha=iAlpha; 
    } else { //mark element type's visibility
        integer elementTypeIndex=llListFindList(g_lElementTypesLower, [element_to_set]);
        g_lAlphaSettings = llListReplaceList(g_lAlphaSettings, [iAlpha], elementTypeIndex, elementTypeIndex);
        llMessageLinked(LINK_SET, LM_SETTING_SAVE, "hide_"+element_to_set + "=" + (string)iAlpha, "");
    }
    ApplyElementAlpha(element_to_set,iAlpha);
}

integer UserCommand(integer iAuth, string sStr, key kAv, integer remenu) {
    if (iAuth > COMMAND_WEARER || iAuth < COMMAND_OWNER) return FALSE; // sanity check

    //Debug(sStr);
    sStr=llToLower(sStr);
    list lParams = llParseString2List(sStr, [" "], []);
    string sCommand = llList2String(lParams, 0);
    string sValue = llList2String(lParams, 1);

    if (iAuth == COMMAND_WEARER && sStr == "runaway") {
        SetElementAlpha("all",1);
    } else if (sStr == "menu paint" || sStr == "menu appearance" || sStr == "paint" || sStr == "appearance") {
        if (kAv!=g_kWearer && iAuth!=COMMAND_OWNER) {
            Notify(kAv,"You are not allowed to change the "+CTYPE+"'s appearance.", FALSE);
            llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
        }
        else ElementsMenu(kAv, iAuth);
    } else if (sCommand == "paint"){
        if (sValue=="invisible") {
            SetElementAlpha("all",0);
            if (remenu) ElementsMenu(kAv,iAuth);
        } else if (sValue == "visible") {
            SetElementAlpha("all",1);
            if (remenu) ElementsMenu(kAv,iAuth);
        } else if (~llListFindList(g_lElementTypesLower+"all",[sValue])){  //sValue is name of an element or "all"
            string sValue2=llToLower(llDumpList2String(llDeleteSubList(lParams, 0, 1)," "));
            if (sValue2==""){ //if they just name an element with no texture, then give them the menu
                ElementMenu(kAv,iAuth, sValue);
            } else {  //sValue2 == styleName, "show", "hide"  sValue == elementType
                if (sValue2 == "visible"){
                    SetElementAlpha(sValue,1);
                    if (remenu) ElementMenu(kAv,iAuth, sValue);
                } else if (sValue2 == "invisible"){
                    SetElementAlpha(sValue,0);
                    if (remenu) ElementMenu(kAv,iAuth, sValue);
                } else {  //sValue2 == styleName
                    //Debug("Got texture "+sValue2);
                    setElementStyle(sValue,sValue2);
                    if (remenu) ElementMenu(kAv,iAuth, sValue);
                }
            }
        } else {  //not the name of an element, or show, or hide, or all
            Notify(kAv,"Unrecognised command: "+sValue+" not in '"+llDumpList2String(g_lElementTypesLower,",")+"'",FALSE);
        }
    }

    return TRUE ;
}

default {
    state_entry() {
        g_kWearer = llGetOwner();       
        
        g_iAllAlpha=0;
        if (llGetAlpha(ALL_SIDES)>0) g_iAllAlpha=1;
        
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Appearance", "");
        
        buildElementTypes();
        if (llGetInventoryKey(g_sTexturesNotecardName)) {
            g_iTexturesCardId = llGetInventoryKey(g_sTexturesNotecardName);
            g_iTexturesNotecardLine=0;
            g_kNotecardReadRequest=llGetNotecardLine(g_sTexturesNotecardName,0);
        }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (UserCommand(iNum, sStr, kID, FALSE)) return;
        if (iNum == LM_SETTING_RESPONSE) {
            list lParams = llParseString2List(sStr, ["="], []);
            string sGroupToken = llList2String(lParams, 0);
            
            string sGroup = llList2String(llParseString2List(sGroupToken,["_"],[]),0);
            string sToken = llList2String(llParseString2List(sGroupToken,["_"],[]),1);
            string sValue = llList2String(lParams, 1);
            
            if (sToken == "CType") {
                CTYPE = sValue;
            } else if (sGroup == "invisible") {
                SetElementAlpha(sToken, (integer)sValue);
            } else if (sGroup == "colour") {
                setElementStyle(sToken, sValue);
            } else if (sGroup == "texture") {
                setElementStyle(sToken, sValue);
            }
        } else if (iNum == MENUNAME_REQUEST && sStr == g_sParentMenu) {
            llMessageLinked(LINK_SET, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "");
        } else if (iNum == LM_SETTING_SAVE) {
            //if we see a hide for something saved that we think is not currently hidden, then hide it, and store the new setting locally
            if (llSubStringIndex(sStr,"hide_")==0){
                list lSettingParts=llParseString2List(llGetSubString(sStr,5,-1),["="],[]);
                string element_to_set=llToLower(llList2String(lSettingParts,0));
                integer iAlpha=llList2Integer(lSettingParts,1);
                integer elementTypeIndex=llListFindList(g_lElementTypesLower,[element_to_set]);
                if (~elementTypeIndex){  //if its an element we recognise
                    if (llList2Integer(g_lAlphaSettings,elementTypeIndex)!=iAlpha){  //if the setting is not what we already know
                        //Debug("setting "+element_to_set+" to "+(string)iAlpha);
                        g_lAlphaSettings = llListReplaceList(g_lAlphaSettings, [iAlpha], elementTypeIndex, elementTypeIndex);
                        ApplyElementAlpha(element_to_set,iAlpha); //apply new setting to collar prims
                        //Debug(element_to_set+" now set to "+(string)llList2Integer(g_lAlphaSettings,elementTypeIndex));
                    } else {
                        //Debug(element_to_set+" already set to "+(string)iAlpha);
                    }
                } else {
                    //Debug("unknown element"+element_to_set);
                }
            } else {
                //Debug("something saved setting "+sStr);
            }
        } else if (iNum == DIALOG_RESPONSE) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) { //got a menu response meant for us.  pull out values
                list lMenuParams = llParseString2List(sStr, ["|"], []);
                key kAv = (key)llList2String(lMenuParams, 0);          
                string sMessage = llList2String(lMenuParams, 1);                                         
                integer iPage = (integer)llList2String(lMenuParams, 2);
                integer iAuth = (integer)llList2String(lMenuParams, 3);
                string sMenuType = llList2String(g_lMenuIDs, iMenuIndex + 1);
                
                //remove stride from g_lMenuIDs
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);     
                
                if (sMenuType == "ElementsMenu") {  //lists all elements in the collar
                    if (sMessage == UPMENU) {  //give kID the parent menu
                        llMessageLinked(LINK_SET, iAuth, "menu " + g_sParentMenu, kAv);
                    } else UserCommand(iAuth,"paint "+sMessage, kAv, TRUE);
                } else if (llSubStringIndex(sMenuType,"element ")==0){  //lists show/hide/themes for this element
                    string elementType=llGetSubString(sMenuType,8,-1);
                    if (sMessage == UPMENU){
                        ElementsMenu(kAv,iAuth);
                    } else UserCommand(iAuth,"paint "+elementType+" "+sMessage, kAv, TRUE);
                }
            }
        } else if (iNum == DIALOG_TIMEOUT) {
            integer iMenuIndex = llListFindList(g_lMenuIDs, [kID]);
            if (~iMenuIndex) {  //remove stride from g_lMenuIDs
                g_lMenuIDs = llDeleteSubList(g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride);                          
            }            
        }
    }
    
    dataserver(key id, string data){
        if (id == g_kNotecardReadRequest){
            if (data != EOF){
                data = llStringTrim(data,STRING_TRIM);
                if (data != ""){
                    list parts=llParseStringKeepNulls(data,["~",",","<",">"],[]);
                    string element=llList2String(parts,0);
                    string name=llList2String(parts,1);
                    key texKey=llList2Key(parts,2);
                    
                    vector colour;
                    if (llGetListLength(parts) < 6){
                        colour=<1.0,1.0,1.0>;
                    } else {
                        colour=(vector)("<"+llList2String(parts,4)+","+llList2String(parts,5)+","+llList2String(parts,6)+">");
                    }
                    
                    g_lTexturesCard+=[llToLower(element),llToLower(name),texKey,colour];
                    
                }
                g_kNotecardReadRequest=llGetNotecardLine(g_sTexturesNotecardName,++g_iTexturesNotecardLine);
            }
        }
    }
    
    changed (integer change){
        if (change & CHANGED_INVENTORY){
            if (g_iTexturesCardId != llGetInventoryKey(g_sTexturesNotecardName)){
                //Debug("Reading textures card");
                g_iTexturesCardId = llGetInventoryKey(g_sTexturesNotecardName);
                g_lTexturesCard=[];
                g_iTexturesNotecardLine=0;
                g_kNotecardReadRequest=llGetNotecardLine(g_sTexturesNotecardName,0);
            }
        }
    }
}
