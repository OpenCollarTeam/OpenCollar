/*
This file is a part of OpenCollar
Licensed under the GPLv2.  See LICENSE for full details.

This plugin was created as an example for an OpenCollar Scripting lesson
by Aria (Tasha Redrose) who did the good parts of this script
and enhanced by Donja (DarkDonja Resident) who did the not so good parts.
*/

string g_sParentMenu = "Apps";
string g_sSubMenu    = "PublicSim";
string g_sPluginName = "publicsim";

// button captions
string g_sBTN_ENABLE_PUBLIC   = "Public";
string g_sBTN_ENABLE_RLV_AUTO = "RelayAuto";
string g_sBTN_REGION_ADD      = "Add Region";
string g_sBTN_REGIONS_LIST    = "list";
string g_sBTN_REGION_DELETE   = "remove";

// MESSAGE MAP
integer CMD_OWNER          = 500;
integer CMD_WEARER         = 503;

integer NOTIFY = 1002;

integer LINK_DIALOG = 3;
integer LINK_UPDATE = -10;

integer MENUNAME_REQUEST  = 3000;
integer MENUNAME_RESPONSE = 3001;

integer DIALOG          = -9000;
integer DIALOG_RESPONSE = -9001;


string UPMENU = "BACK";

// --- global variables
key     g_kWearer;
list    g_lMenuIDs;
integer g_iMenuStride;

integer g_iPublicModeEnabled;    // is public mode active
integer g_iRelayAutoEnabled;     // is RLV Relay Auto active
list    g_lRegionNames;          // stores region names

Dialog( key kID, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth, string sName ) {
    key kMenuID = llGenerateKey();
    llMessageLinked(
        LINK_DIALOG,
        DIALOG,
        (string)kID + "|" + sPrompt
        + "|" + (string)iPage
        + "|" + llDumpList2String( lChoices,        "`" )
        + "|" + llDumpList2String( lUtilityButtons, "`" )
        + "|" + (string)iAuth,
        kMenuID
    );

    integer iIndex = llListFindList( g_lMenuIDs, [ kID ] );
    if ( ~iIndex ) {
        g_lMenuIDs = llListReplaceList( g_lMenuIDs, [ kID, kMenuID, sName ], iIndex, iIndex + g_iMenuStride - 1 );
    }
    else {
        g_lMenuIDs += [ kID, kMenuID, sName ];
    }
}

string lbl( string sLabel, integer iTest ) {
    if ( iTest )    return "[x] " + sLabel;
    else            return "[ ] " + sLabel;
}

Menu( key kID, integer iAuth ) {
    integer iRegionsCount = llGetListLength(g_lRegionNames);

    string sPrompt  = "\n[" + g_sSubMenu + " App]\n\n"
        + "This App controls public access on certain Sims\n\n"
        + g_sBTN_ENABLE_PUBLIC + "     .. activates auto-public-mode\n"
        + g_sBTN_ENABLE_RLV_AUTO + "   .. activates relay-auto-mode\n"
        + g_sBTN_REGION_ADD + "   .. adds the current region\n";
    
    list   lButtons = [
        g_sBTN_REGION_ADD,
        lbl( g_sBTN_ENABLE_PUBLIC,   g_iPublicModeEnabled ),
        lbl( g_sBTN_ENABLE_RLV_AUTO, g_iRelayAutoEnabled  )
    ];
    if ( iRegionsCount ) {
        lButtons += [ g_sBTN_REGION_DELETE, g_sBTN_REGIONS_LIST ];
        sPrompt  += g_sBTN_REGION_DELETE + "   .. displays Dialog to remove a region\n"
            + g_sBTN_REGIONS_LIST + "        .. lists all stored regions\n\n"
            + (string)iRegionsCount + " region(s) stored";
    }
    if ( g_iPublicModeEnabled ) {
        sPrompt += "This Plugin is active\n";
    }
    else {
        sPrompt += "This Plugin is disabled\n";
    }
    
    Dialog( kID, sPrompt, lButtons, [ UPMENU ], 0, iAuth, "Menu~" + g_sSubMenu );
}

UserCommand( integer iNum, string sStr, key kID ) {
    
    if ( iNum < CMD_OWNER || iNum > CMD_WEARER ) {
        return;
    }
    else if ( llSubStringIndex( sStr, g_sPluginName )
        && ( sStr != "menu " + g_sSubMenu )
    ) {
        return;
    }
    else if ( iNum == CMD_OWNER && sStr == "runaway" ) {
        return;
    }
    
    if ( sStr == g_sSubMenu || sStr == "menu " + g_sSubMenu ) {
        Menu( kID, iNum );
    }
    
    else {
        if( iNum != CMD_OWNER ) {
            llMessageLinked( LINK_DIALOG, NOTIFY, "0%NOACCESS% to the " + g_sPluginName + " plugin's commands, must be owner", kID );
            return;
        }

        integer iWSuccess    = 0;
        list    words        = llParseString2List( sStr, [ " " ], [] );
        string  sChangetype  = llList2String( words, 1 );
        string  sChangevalue = llList2String( words, 2 );

        if( sChangetype == "list" ) {
            llMessageLinked( LINK_DIALOG, NOTIFY, "0"+ llDumpList2String( g_lRegionNames, "\n" ), kID );
        }
        else if ( sChangetype == "addregion" ) {
            string sRegionName = llGetRegionName();
            if ( -1 == llListFindList( g_lRegionNames, [ sRegionName ] ) ) { 
                g_lRegionNames += sRegionName;
                llMessageLinked( LINK_DIALOG, NOTIFY, "1Region " + sRegionName + " added", kID );
                CheckRegion();
            } 
        }
        else if ( sChangetype == "remove" ) {
            RemoveMenu( kID, iNum );
        }
    }
}

RemoveMenu( key kID, integer iAuth ) {
    string sPrompt = "[" + g_sSubMenu + " App]\\n \nSelect a region to remove";
    list lButtons = g_lRegionNames;
    Dialog( kID, sPrompt, lButtons, [UPMENU], 0, iAuth, "Menu~Remove" );
}

CheckRegion() {
    
    integer iTest = llListFindList( g_lRegionNames, [ llGetRegionName() ] );
    
    if( g_iPublicModeEnabled ){
        if ( iTest == -1 ) {
            llMessageLinked( LINK_ALL_OTHERS, CMD_OWNER, "public off", g_kWearer );
        }
        else {
            llMessageLinked( LINK_ALL_OTHERS, CMD_OWNER, "public on", g_kWearer );
        }
    }
    
    if ( g_iRelayAutoEnabled ) {
        if ( iTest==-1 ) {
            llMessageLinked( LINK_SET, 2002, "relay_mode=1090", NULL_KEY); // ask
            llOwnerSay( "Set RLV Relay to ask");
        }
        else {
            llMessageLinked( LINK_SET, 2002, "relay_mode=1123", NULL_KEY); // auto
            llOwnerSay( "Set RLV Relay to auto");
        }
    }
}

default {

    on_rez( integer t ) {
        if( llGetOwner() != g_kWearer ) {
            llResetScript();
        }
        else {
            llSleep(2);
            CheckRegion();
        }
    }

    state_entry() {
        g_kWearer = llGetOwner();
    }

    changed( integer iChange ) {
        if ( iChange & CHANGED_REGION || iChange & CHANGED_TELEPORT ) {
            CheckRegion();
        }
    }

    link_message( integer iSender, integer iNum, string sStr, key kID ){

        if ( iNum >= CMD_OWNER && iNum <= CMD_WEARER ) {
            UserCommand(iNum, sStr, kID);
        }
        else if ( iNum == MENUNAME_REQUEST && sStr == g_sParentMenu ) {
            llMessageLinked( iSender, MENUNAME_RESPONSE, g_sParentMenu + "|" + g_sSubMenu, "" );
        }

        else if ( iNum == DIALOG_RESPONSE ) {
            integer iMenuIndex = llListFindList( g_lMenuIDs, [ kID ] );
            if ( iMenuIndex == -1 ) {
                return;
            }

            string sMenu = llList2String( g_lMenuIDs, iMenuIndex + 1 );
            g_lMenuIDs = llDeleteSubList( g_lMenuIDs, iMenuIndex - 1, iMenuIndex - 2 + g_iMenuStride );
            list lMenuParams = llParseString2List( sStr, [ "|" ], [] );
            key     kAv   = llList2Key(     lMenuParams, 0 );
            string  sMsg  = llList2String(  lMenuParams, 1 );
            integer iAuth = llList2Integer( lMenuParams, 3 );
            integer iReMenu = TRUE;

            if( sMenu == "Menu~" + g_sSubMenu ) {
                if ( sMsg == UPMENU ) {
                    llMessageLinked(LINK_SET, iAuth, "menu "+g_sParentMenu, kAv);
                    return;
                }
                else if ( sMsg == g_sBTN_REGION_ADD ) {
                    UserCommand( iAuth, g_sPluginName + " addregion", kAv );
                }
                else if ( sMsg == g_sBTN_REGIONS_LIST ) {
                    UserCommand( iAuth, g_sPluginName + " list", kAv );
                }
                else if ( sMsg == "Remove" ) {
                    UserCommand( iAuth, g_sPluginName + " remove", kAv ); // Display a prompt for what region to remove
                    // Do not respring
                    iReMenu = FALSE;
                }
                else if ( sMsg == lbl( g_sBTN_ENABLE_PUBLIC, g_iPublicModeEnabled ) ) {
                    g_iPublicModeEnabled = 1 - g_iPublicModeEnabled;
                    if ( g_iPublicModeEnabled ) {
                        CheckRegion();
                    }
                }
                else if (sMsg == lbl( g_sBTN_ENABLE_RLV_AUTO, g_iRelayAutoEnabled ) ) {
                    g_iRelayAutoEnabled = 1 - g_iRelayAutoEnabled;
                    if (g_iRelayAutoEnabled) {
                        CheckRegion();
                    }
                }

                if ( iReMenu ) {
                    Menu( kAv, iAuth );
                }
            }

            else if ( sMenu == "Menu~Remove" ) {
                if ( sMsg == UPMENU ) {
                    Menu( kAv, iAuth );
                    return;
                }
                integer iPos = llListFindList( g_lRegionNames, [ sMsg ] );
                if ( iPos == -1 ) {
                    llMessageLinked( LINK_DIALOG, NOTIFY, "0Invalid selection", kAv );
                    RemoveMenu( kAv, iAuth );
                    return;
                }
                // Remove from list
                g_lRegionNames = llDeleteSubList( g_lRegionNames, iPos, iPos );
                if ( llGetListLength( g_lRegionNames ) == 0 ) {
                    CheckRegion();
                    g_iPublicModeEnabled = FALSE;
                }
                // Pop back to previous menu
                Menu( kAv, iAuth );
            }

        } // else if ( iNum == DIALOG_RESPONSE )

        else if ( iNum == LINK_UPDATE ) {
            if      ( sStr == "LINK_DIALOG" ) LINK_DIALOG = iSender;
        }
    
    } // link_message

} // default
