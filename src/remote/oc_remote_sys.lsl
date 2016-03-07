//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//       Remote System - 160307.1        .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2014 - 2015 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Master Starship, Wendy Starfall, North Glenwalker, Ray Zopf, Sumi Perl, //
//  Kire Faulkes, Zinn Ixtar, Builder's Brewery, Romka Swallowtail et al.   //
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
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

//merged HUD-menu, HUD-leash and HUD-rezzer into here June 2015 Otto (garvin.twine)

string g_sVersion = "160307.1";
string g_sFancyVersion = "⁶⋅⁰⋅¹";
integer g_iUpdateAvailable;
key g_kWebLookup;

list g_lPartners;
list g_lNewPartnerIDs;
list g_lPartnersInSim; 
string g_sActivePartnerID = "ALL"; //either an UUID or "ALL"

//  list of hud channel handles we are listening for, for building lists
list g_lListeners;

string g_sMainMenu = "Main";

//  Notecard reading bits
string  g_sCard = ".partners";
key     g_kCardID = NULL_KEY;
key     g_kLineID;
integer g_iLineNr;

integer g_iListener;
integer g_iCmdListener;
integer g_iChannel = 7;

key g_kUpdater;
integer g_iUpdateChan = -7483210;

integer g_iHidden;
integer g_iPicturePrim;
string g_sPictureID;
key g_kPicRequest;
string g_sMetaFind = "<meta name=\"imageid\" content=\"";
string g_sTextureALL ="4fb4a7fe-733b-fae7-810d-81e6784bc3c3";

//  MESSAGE MAP
integer CMD_TOUCH            = 100;

integer MENUNAME_REQUEST     = 3000;
integer MENUNAME_RESPONSE    = 3001;
integer SUBMENU              = 3002;

integer DIALOG               = -9000;
integer DIALOG_RESPONSE      = -9001;
integer DIALOG_TIMEOUT       = -9002;
integer CMD_REMOTE           = 10000;

string UPMENU          = "BACK";
string g_sListPartners  = "List";
string g_sRemovePartner = "Remove";
string g_sAllPartners = "ALL";
string g_sAddPartners = "Add";

list g_lMainMenuButtons = [" ◄ ",g_sAllPartners," ► ",g_sAddPartners, g_sListPartners, g_sRemovePartner, "Collar Menu", "Rez"];
list g_lMenus;
key    g_kMenuID;
string g_sMenuType;

key    g_kRemovedPartnerID;
key    g_kOwner;

string  g_sRezObject;


/*integer g_iProfiled=1;
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

string NameURI(string sID) {
    if ((key)sID)
        return "secondlife:///app/agent/"+sID+"/about";
    else return sID; //this way we can use the function also for "ALL" and dont need a special case for that everytime
}

integer PersonalChannel(string sID, integer iOffset) {
    integer iChan = -llAbs((integer)("0x"+llGetSubString(sID,-7,-1)) + iOffset);
    return iChan;
}

integer InSim(key kID) {
//  check if the AV is logged in and in Sim
    return (llGetAgentSize(kID) != ZERO_VECTOR);
}

list PartnersInSim() {
    list lTemp;
    integer i = llGetListLength(g_lPartners);
     while (i) {
        string sTemp = llList2String(g_lPartners,--i);
        if (InSim(sTemp))
            lTemp += sTemp;
    }
    return [g_sAllPartners]+lTemp;
}

SendCollarCommand(string sCmd) {
    g_lPartnersInSim = PartnersInSim();
    integer i = llGetListLength(g_lPartnersInSim);
    if (i > 1) {
        if ((key)g_sActivePartnerID)
            llRegionSayTo(g_sActivePartnerID,PersonalChannel(g_sActivePartnerID,0), g_sActivePartnerID+":"+sCmd);
        else if (g_sActivePartnerID == g_sAllPartners) {
            integer i = llGetListLength(g_lPartnersInSim);
             while (i > 1) { // g_lPartnersInSim has always one entry ["ALL"] do whom we dont want to send anything
                string sPartnerID = llList2String(g_lPartnersInSim,--i);
                llRegionSayTo(sPartnerID,PersonalChannel(sPartnerID,0),sPartnerID+":"+sCmd);
            }
        }
    } else llOwnerSay("None of your partners are in range.");
}

AddPartner(string sID) {
    if (~llListFindList(g_lPartners,[sID])) return;
    if ((key)sID != NULL_KEY) {//don't register any unrecognised
        g_lPartners+=[sID];//Well we got here so lets add them to the list.
        llOwnerSay("\n\n"+NameURI(sID)+" has been registered.\n");//Tell the owner we made it.
    }
}

RemovePartner(string sID) {
    integer index = llListFindList(g_lPartners,[sID]);
    if (~index) {
        g_lPartners=llDeleteSubList(g_lPartners,index,index);
        llOwnerSay(NameURI(sID)+" has been removed.");
        if (sID == g_sActivePartnerID) NextPartner(0,FALSE);
    }
}

Dialog(string sPrompt, list lChoices, list lUtilityButtons, integer iPage, string sMenuType) {
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET,DIALOG,(string)g_kOwner+"|"+sPrompt+"|"+(string)iPage+"|"+llDumpList2String(lChoices,"`")+"|"+llDumpList2String(lUtilityButtons,"`"),kID);
    g_kMenuID = kID;
    g_sMenuType = sMenuType;
}

MainMenu(){
    string sPrompt = "\n[http://www.opencollar.at/remote.html OpenCollar Remote]\t"+g_sFancyVersion;
    sPrompt += "\n\nSelected Partner: "+NameURI(g_sActivePartnerID);
    if (g_iUpdateAvailable) sPrompt += "\n\nUPDATE AVAILABLE: A new patch has been released.\nPlease install at your earliest convenience. Thanks!\n\nwww.opencollar.at/updates";
    list lButtons = g_lMainMenuButtons + g_lMenus;
    Dialog(sPrompt, lButtons, [], 0, g_sMainMenu);
}

RezMenu() {
    Dialog("\nRez something!\n\nSelected Partner: "+NameURI(g_sActivePartnerID), BuildObjectList(),["BACK"],0,"RezzerMenu");
}

AddPartnerMenu() {
    string sPrompt = "\nWho would you like to add?\n";
    list lButtons;
    integer index;
    do {
        lButtons += llList2Key(g_lNewPartnerIDs,index);
    } while (++index < llGetListLength(g_lNewPartnerIDs));
    Dialog(sPrompt, lButtons, [g_sAllPartners,UPMENU], -1,"AddPartnerMenu");
}

StartUpdate() {
    integer pin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(pin);
    llRegionSayTo(g_kUpdater, g_iUpdateChan, "ready|" + (string)pin );
}

list BuildObjectList() {
    list lRezObjects;
    integer i;
    do lRezObjects += llGetInventoryName(INVENTORY_OBJECT,i);
    while (++i < llGetInventoryNumber(INVENTORY_OBJECT));
    return lRezObjects;
}

NextPartner(integer iDirection, integer iTouch) {
    g_lPartnersInSim = PartnersInSim();
    if ((llGetListLength(g_lPartnersInSim) > 1) && iDirection) {
        integer index = llListFindList(g_lPartnersInSim,[g_sActivePartnerID])+iDirection;
        if (index >= llGetListLength(g_lPartnersInSim)) index = 0;
        else if (index < 0) index = llGetListLength(g_lPartnersInSim)-1;
        g_sActivePartnerID = llList2String(g_lPartnersInSim,index);
    } else g_sActivePartnerID = g_sAllPartners;
    if ((key)g_sActivePartnerID)
        g_kPicRequest = llHTTPRequest("http://world.secondlife.com/resident/"+g_sActivePartnerID,[HTTP_METHOD,"GET"],"");
    else if (g_sActivePartnerID == g_sAllPartners)
        if (g_iPicturePrim) llSetLinkPrimitiveParamsFast(g_iPicturePrim,[PRIM_TEXTURE, ALL_SIDES, g_sTextureALL,<1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
    if(iTouch) {
        if (llGetListLength(g_lPartnersInSim) < 2) llOwnerSay("There is nobody nearby at the moment.");
        else llOwnerSay("\n\nSelected Partner: "+NameURI(g_sActivePartnerID)+"\n");
    }
}

integer PicturePrim() {
    integer i = llGetNumberOfPrims();
    do {
        if (~llSubStringIndex((string)llGetLinkPrimitiveParams(i, [PRIM_DESC]),"Picture"))
            return i;
    } while (--i>1);
    return 0;
}

default {
    state_entry() {
        g_kOwner = llGetOwner();
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~remote", [HTTP_METHOD, "GET"],"");
        llSleep(1.0);//giving time for others to reset before populating menu
        if (llGetInventoryKey(g_sCard)) {
            g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
            g_kCardID = llGetInventoryKey(g_sCard);
        }
        g_iListener=llListen(PersonalChannel(g_kOwner,0),"","",""); //lets listen here
        g_iCmdListener = llListen(g_iChannel,"",g_kOwner,"");
        llMessageLinked(LINK_SET,MENUNAME_REQUEST, g_sMainMenu,"");
        g_iPicturePrim = PicturePrim();
        NextPartner(0,0);
    }
    
    on_rez(integer iStart) {
        g_kWebLookup = llHTTPRequest("https://raw.githubusercontent.com/VirtualDisgrace/Collar/live/web/~remote", [HTTP_METHOD, "GET"],"");
    }
    
    touch_start(integer iNum) {
        if (llGetAttached() && (llDetectedKey(0)==g_kOwner)) {// Dont do anything if not attached to the HUD
//          I made the root prim the "menu" prim, and the button action default to "menu."
            string sButton = llToLower((string)llGetLinkPrimitiveParams(llDetectedLinkNumber(0),[PRIM_DESC]));
            if (~llSubStringIndex(sButton,"remote"))
                llMessageLinked(LINK_SET, CMD_TOUCH,"hide","");
            else if (sButton == "hudmenu") MainMenu();
            else if (sButton == "rez") RezMenu();
            else if (~llSubStringIndex(sButton,"picture")) NextPartner(1,TRUE);
            else if (sButton == "bookmarks") llMessageLinked(LINK_THIS,0,"bookmarks menu","");
            else if (sButton == "tp save") llMessageLinked(LINK_THIS,0,sButton,"");
            else SendCollarCommand(sButton);
        }
    }

    listen(integer iChannel, string sName, key kID, string sMessage) {
        if (iChannel == g_iChannel) {
            list lParams = llParseString2List(sMessage, [" "], []);
            string sCmd = llList2String(lParams,0);
            if (sMessage == "menu")
                MainMenu();
            else if (sCmd == "channel") {
                integer iNewChannel = (integer)llList2String(lParams,1);
                if (iNewChannel) {
                    g_iChannel = iNewChannel;
                    llListenRemove(g_iCmdListener);
                    g_iCmdListener = llListen(g_iChannel,"",g_kOwner,"");
                    llOwnerSay("Your new HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
                } else llOwnerSay("Your HUD command channel is "+(string)g_iChannel+". Type /"+(string)g_iChannel+"menu to bring up your HUD menu.");
            }
            else if (llToLower(sMessage) == "help")
                llOwnerSay("\n\nThe manual page can be found [http://www.opencollar.at/remote.html here].\n");
            else if (sMessage == "reset") llResetScript();
        } else if (iChannel == PersonalChannel(g_kOwner,0) && llGetOwnerKey(kID) == g_kOwner) {
            if (sMessage == "-.. --- / .... ..- -..") {
                g_kUpdater = kID;
                Dialog("\nINSTALLATION REQUEST PENDING:\n\nAn update or app installer is requesting permission to continue. Installation progress can be observed above the installer box and it will also tell you when it's done.\n\nShall we continue and start with the installation?", ["Yes","No"], ["Cancel"], 0, "UpdateConfirmMenu");
            }
        } else if (llGetSubString(sMessage, 36, 40)==":pong") {
            if (!~llListFindList(g_lNewPartnerIDs, [llGetOwnerKey(kID)]) && !~llListFindList(g_lPartners, [(string)llGetOwnerKey(kID)]))
                g_lNewPartnerIDs += [llGetOwnerKey(kID)];
        } 
    }

    link_message(integer iSender, integer iNum, string sStr, key kID) {
        if (iNum == MENUNAME_RESPONSE) {
            list lParams = llParseString2List(sStr, ["|"], []);
            if (llList2String(lParams,0) == g_sMainMenu) {
                string sChild = llList2String(lParams,1);
                if (! ~llListFindList(g_lMenus, [sChild]))
                    g_lMenus = llListSort(g_lMenus+=[sChild], 1, TRUE);
            }
            lParams = [];
        } else if (iNum == SUBMENU && sStr == "Main") MainMenu();
        else if (iNum == CMD_REMOTE) SendCollarCommand(sStr);
        else if (iNum == 111) {
            g_sTextureALL = sStr;
            if (g_sActivePartnerID == g_sAllPartners) 
                llSetLinkPrimitiveParamsFast(g_iPicturePrim,[PRIM_TEXTURE, ALL_SIDES, g_sTextureALL , <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        } else if (iNum == DIALOG_RESPONSE && kID == g_kMenuID) {
            list lParams = llParseString2List(sStr, ["|"], []);
            string sMessage = llList2String(lParams, 1);
            integer i;
            if (g_sMenuType == "Main") {
                if (sMessage == "Collar Menu") SendCollarCommand("menu");
                else if (sMessage == "Rez")
                    RezMenu();
                else if (sMessage == g_sRemovePartner)
                    Dialog("\nWho would you like to remove?\n", g_lPartners, [UPMENU], -1,"RemovePartnerMenu");
                else if (sMessage == g_sListPartners) {
                    string sText ="\n\nI'm currently managing: ";
                    integer iPartnerCount = llGetListLength(g_lPartners);
                    if (iPartnerCount) {
                        i=0;
                        do {
                            if (llStringLength(sText)>950) {
                                llOwnerSay(sText);
                                sText ="";
                            }
                            sText += NameURI(llList2Key(g_lPartners,i))+", " ;
                        } while (++i < iPartnerCount-1);
                        if (iPartnerCount>1)sText += " and "+NameURI(llList2Key(g_lPartners,i));
                        if (iPartnerCount == 1) sText = llGetSubString(sText,0,-3);
                    } else sText += "nobody :(";
                    llOwnerSay(sText);
                    MainMenu();
                } else if (sMessage == g_sAddPartners) {
                     // Ping for auth OpenCollars in the parcel
                     list lAgents = llGetAgentList(AGENT_LIST_PARCEL, []); //scan for who is in the parcel
                     llOwnerSay("Scanning for collar access....");
                     integer iChannel;
                     i =  llGetListLength(lAgents);
                     do {
                        kID = llList2Key(lAgents,--i);
                        if (kID != g_kOwner && !~llListFindList(g_lPartners,[(string)kID])) {
                            if (llGetListLength(g_lListeners) < 60) {//Only 65 listens can simultaneously be open in any single script (SL wiki)
                                iChannel = PersonalChannel(kID,0);
                                g_lListeners += [llListen(iChannel, "", "", "" )] ;
                                llRegionSayTo(kID, iChannel, (string)kID+":ping");
                            } else i=0;
                        }
                    } while (i);
                    llSetTimerEvent(2.0);
                } else if (sMessage == " ◄ ") {
                    NextPartner(-1,FALSE);
                    MainMenu();
                } else if (sMessage == " ► ") {
                    NextPartner(1,FALSE);
                    MainMenu();
                } else if (sMessage == g_sAllPartners) {
                    g_sActivePartnerID = g_sAllPartners;
                    NextPartner(0,FALSE);
                    MainMenu(); 
                } else if (~llListFindList(g_lMenus,[sMessage])) llMessageLinked(LINK_SET,SUBMENU,sMessage,kID);
            } else if (g_sMenuType == "RemovePartnerMenu") {
                integer index = llListFindList(g_lPartners, [sMessage]);
                if (sMessage == UPMENU) MainMenu();
                else if (sMessage == "Yes") {
                    RemovePartner(g_kRemovedPartnerID);
                    MainMenu();
                } else if (sMessage == "No") MainMenu();
                else if (~index) {
                    g_kRemovedPartnerID = (key)llList2String(g_lPartners, index);
                    Dialog("\nAre you sure you want to remove "+NameURI(g_kRemovedPartnerID)+"?", ["Yes", "No"], [UPMENU], 0,"RemovePartnerMenu");
                }
            } else if (g_sMenuType == "UpdateConfirmMenu") {
                if (sMessage=="Yes") StartUpdate();
                else {
                    llOwnerSay("Installation cancelled.");
                    return;
                }
            } else if (g_sMenuType == "RezzerMenu") {
                    if (sMessage == UPMENU) MainMenu();
                    else { 
                        g_sRezObject = sMessage;
                        if (llGetInventoryType(g_sRezObject) == INVENTORY_OBJECT)
                            llRezObject(g_sRezObject,llGetPos() + <2, 2, 0>, ZERO_VECTOR, llGetRot(), 0);
                    }
            } else if (g_sMenuType == "AddPartnerMenu") {
                if (sMessage == g_sAllPartners) {
                    i = llGetListLength(g_lNewPartnerIDs);
                    key kNewPartnerID;
                    do {
                        kNewPartnerID = llList2Key(g_lNewPartnerIDs,--i);
                        if (kNewPartnerID) AddPartner(kNewPartnerID);
                    } while (i);
                } else if ((key)sMessage)
                    AddPartner(sMessage);
                g_lNewPartnerIDs = [];
                MainMenu();
            } 
        }
    }

    timer() {
        if (llGetListLength(g_lNewPartnerIDs)) AddPartnerMenu();
        else llOwnerSay("\n\nYou currently don't have access to any nearby collars. Requirements to add partners are to either have them captured or their collar is set to public or they have you listed as an owner or trust role. www.opencollar.at/remote\n");
        llSetTimerEvent(0);
        integer n = llGetListLength(g_lListeners);
        while (n--)
            llListenRemove(llList2Integer(g_lListeners,n));
        g_lListeners = [];
    }

    dataserver(key kRequestID, string sData) {
        if (kRequestID == g_kLineID) {
            if (sData == EOF) { //  notify the owner
                //llOwnerSay(g_sCard+" card loaded.");
                return;
            } else if ((key)sData) // valid lines contain only a valid UUID which is a key
                AddPartner(sData); 
            g_kLineID = llGetNotecardLine(g_sCard, ++g_iLineNr);
        }
    }
    
    http_response(key kRequestID, integer iStatus, list lMeta, string sBody) {
        if (kRequestID == g_kWebLookup && iStatus == 200)  {
            if ((float)sBody > (float)g_sVersion) g_iUpdateAvailable = TRUE;
            else g_iUpdateAvailable = FALSE;
        } else if (kRequestID == g_kPicRequest) {
            integer iMetaPos =  llSubStringIndex(sBody, g_sMetaFind) + llStringLength(g_sMetaFind);
            string sTexture  = llGetSubString(sBody, iMetaPos, iMetaPos + 35);
            if ((key)sTexture == NULL_KEY) sTexture = "ff3c4a89-8649-2bb0-6521-624be1305d29";
            if (g_iPicturePrim) llSetLinkPrimitiveParamsFast(g_iPicturePrim,[PRIM_TEXTURE, ALL_SIDES, sTexture,<1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0]);
        }
    }
    
    object_rez(key kID) {
        llSleep(0.5); // make sure object is rezzed and listens
        if (g_sActivePartnerID == g_sAllPartners) 
            llRegionSayTo(kID,PersonalChannel(g_kOwner,1234),llDumpList2String(llDeleteSubList(PartnersInSim(),0,0),","));
        else 
            llRegionSayTo(kID,PersonalChannel(g_kOwner,1234),g_sActivePartnerID);
    }
    
    changed(integer iChange) {
        if (iChange & CHANGED_INVENTORY) {
            if (llGetInventoryKey(g_sCard) != g_kCardID) {
                // the .partners card changed.  Re-read it.
                g_iLineNr = 0;
                if (llGetInventoryKey(g_sCard)) {
                    g_kLineID = llGetNotecardLine(g_sCard, g_iLineNr);
                    g_kCardID = llGetInventoryKey(g_sCard);
                }
            }
        }
        if (iChange & CHANGED_OWNER) llResetScript();
    }
}
