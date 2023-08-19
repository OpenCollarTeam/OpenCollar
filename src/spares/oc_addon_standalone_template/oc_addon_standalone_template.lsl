/*
    This file is a part of OpenCollar.
    Copyright ©2021
    : Contributors :
    Phidoux (taya.Maruti)
        * Agust 16 2023 - modified addon system to work as stand alone with cusomized menu support, based uppon AO 3.0.5
        * Agust 18 2023 - added the ability to call menu buttons from chat command.
        * Agust 18 2023 - added the collar sync toggles for collar settings.
*/

integer API_CHANNEL             = 0x60b97b5e;

//list g_lCollars;
string g_sAddon                 = "Standalone";

//integer CMD_ZERO                = 0;
integer CMD_OWNER               = 500;
integer CMD_TRUSTED             = 501;
integer CMD_GROUP               = 502;
integer CMD_WEARER              = 503;
integer CMD_EVERYONE            = 504;
integer CMD_BLOCKED             = 598; // <--- Used in auth_request, will not return on a CMD_ZERO
//integer CMD_RLV_RELAY           = 507;
//integer CMD_SAFEWORD            = 510;
//integer CMD_RELAY_SAFEWORD      = 511;
//integer CMD_NOACCESS            = 599;

//integer LINK_CMD_RESTRICTIONS   = -2576;
//integer RLV_CMD                 = 6000;
//integer RLV_REFRESH             = 6001;//RLV plugins should reinstate their restrictions upon receiving this message.
//integer RLV_CLEAR               = 6002;//RLV plugins should clear their restriction lists upon receiving this message.
//integer RLV_VERSION             = 6003; //RLV Plugins can recieve the used RLV viewer version upon receiving this message..
//integer RLVA_VERSION            = 6004; //RLV Plugins can recieve the used RLVa viewer version upon receiving this message..
//integer RLV_CMD_OVERRIDE        =6010; //RLV Plugins can send one-shot (force) commands with a list of restrictions to temporarily lift if required to ensure that the one-shot commands can be executed

//integer RLV_OFF                 = 6100; // send to inform plugins that RLV is disabled now, no message or key needed
//integer RLV_ON                  = 6101; // send to inform plugins that RLV is enabled now, no message or key needed
//integer AUTH_REQUEST            = 600;
//integer AUTH_REPLY              = 601;

//integer LM_SETTING_SAVE         = 2000; //scripts send messages on this channel to have settings saved, <string> must be in form of "token=value"
integer LM_SETTING_REQUEST      = 2001; //when startup, scripts send requests for settings on this channel
integer LM_SETTING_RESPONSE     = 2002; //the settings script sends responses on this channel
//integer LM_SETTING_DELETE       = 2003; //delete token from settings
//integer LM_SETTING_EMPTY        = 2004; //sent when a token has no value

//integer DIALOG                  = -9000;
//integer DIALOG_RESPONSE         = -9001;
//integer DIALOG_TIMEOUT          = -9002;
integer MENU_REQUEST            = -9003;
integer MENU_REGISTER           = -9004;
integer MENU_REMOVE             = -9005;
integer MENU_RESPONCE           = -9006;

/*
 * Since Release Candidate 1, Addons will not receive all link messages without prior opt-in.
 * To opt in, add the needed link messages to g_lOptedLM = [], they'll be transmitted on
 * the initial registration and can be updated at any time by sending a packet of type `update`
 * Following LMs require opt-in:
 * [ALIVE, READY, STARTUP, CMD_ZERO, MENUNAME_REQUEST, MENUNAME_RESPONSE, MENUNAME_REMOVE, SAY, NOTIFY, DIALOG, SENSORDIALOG]
 */
list g_lOptedLM         = [];
string g_sLockSound     = "dec9fb53-0fef-29ae-a21d-b3047525d312";
string g_sUnlockSound   = "82fa6d06-b494-f97c-2908-84009380c8d1";

UserCommand ( integer iNum, string sStr, key kID )
{
    if ( iNum != CMD_BLOCKED && (iNum < CMD_OWNER || iNum > CMD_WEARER  || iNum == CMD_GROUP || (integer)llLinksetDataRead("auth_open")))
    {
        llInstantMessage ( kID, "you are not authorized to access this addon!" );
        return;
    }
    if ( llSubStringIndex ( llToLower ( sStr ), llToLower ( g_sAddon ) ) && llToLower( sStr ) != "menu " + llToLower ( g_sAddon ) )
    {
        return;
    }
    if ( iNum == CMD_OWNER && llToLower ( sStr ) == "runaway" )
    {
        llLinksetDataReset ();
        return;
    }
    if ( llToLower ( sStr ) == llToLower ( g_sAddon ) || llToLower ( sStr ) == "menu " + llToLower ( g_sAddon ) )
    {
        llMessageLinked ( LINK_SET, MENU_REQUEST, (string) iNum + "|MenuMain", kID );
    }
    else
    {
        list lCommands  = llParseString2List ( sStr, [ " " ], [ g_sAddon, llToLower ( g_sAddon ) ] );
        string sToken   = llToLower ( llList2String ( lCommands, 1 ) );
        string sValue   = llList2String( lCommands, 2 );
        llLinksetDataWrite ( "menu_user", (string) kID );
        if( sToken == "lock")
        {
            llSay(0,"The lock clicks as secondlife:///app/agent/"+(string)kID+"/about locks it!");
            llLinksetDataWrite("addon_lock",(string)TRUE);
        }
        else if( sToken == "unlock")
        {
            llSay(0,"The lock clicks as secondlife:///app/agent/"+(string)kID+"/about unlocks it!");
            llLinksetDataWrite("addon_lock",(string)FALSE);
        }
        else if( sToken == "connect")
        {
            llLinksetDataWrite("addon_online",(string)TRUE);
        }
        else if( sToken == "disconnect")
        {
            llLinksetDataWrite ( "addon_online", (string) FALSE );
        }
        else if( ~llSubStringIndex(llToLower(llLinksetDataRead("menu_main")),sValue))
        {
            // if the command exists in main menu as a button make the call as if clicking the button.
            llMessageLinked ( LINK_SET, MENU_REQUEST, (string)iNum + "|"+sValue, kID);
        }
        else
        {
            llInstantMessage ( kID, "Wrong comand or you are not authroized" );
        }
        sValue = "";
        sToken = "";
        lCommands = [];
    }
}


Link ( string packet, integer iNum, string sStr, key kID )
{
    list packet_data = [ "pkt_type", packet, "iNum", iNum, "addon_name", g_sAddon, "bridge", FALSE, "sMsg", sStr, "kID", kID ];

    if ( packet == "online" || packet == "update" )
    {
        // only add optin if packet type is online or update
        packet_data += [ "optin", llDumpList2String( g_lOptedLM, "~" ) ];
    }

    string pkt = llList2Json ( JSON_OBJECT, packet_data );
    if ( (key) llLinksetDataRead ( "collar_uuid" ) != "" && (key) llLinksetDataRead ( "collar_uuid" ) != NULL_KEY )
    {
        llRegionSayTo ( (key) llLinksetDataRead ( "collar_uuid" ), API_CHANNEL, pkt );
    }
    else
    {
        llRegionSay ( API_CHANNEL, pkt );
    }

    // Sanitation to keep memory usage low.
    packet_data = [];
    pkt         = "";
    packet      = "";
    sStr        = "";
}

Input_Auth(key kID, string sMsg)
{
    //llOwnerSay("[Addon processing input]");
    if ( kID == llGetOwner () )
    {
        UserCommand ( CMD_WEARER, sMsg, kID );
    }
    else if ( llListFindList ( llParseString2List ( llLinksetDataRead ( "auth_owner" ), [ "," ], [] ), [ (string) kID ] ) != -1 )
    {
        UserCommand ( CMD_OWNER, sMsg, kID );
    }
    else if ( llListFindList ( llParseString2List ( llLinksetDataRead ( "auth_trust" ), [ "," ], [] ), [ (string) kID ] ) != -1 )
    {
        UserCommand ( CMD_TRUSTED, sMsg, kID );
    }
    else
    {
        llInstantMessage ( kID, "Sorry you are not authorized to use this" );
    }
}

goOnline ()
{
    llLinksetDataWrite ( "collar_uuid", (string) NULL_KEY );
    if ( (integer) llLinksetDataRead ( "addon_listen" ) )
    {
        llListenRemove ( (integer) llLinksetDataRead ( "addon_listen" ) );
    }
    API_CHANNEL = ( (integer) ( "0x" + llGetSubString ( (string) llGetOwner (), 0, 8 ) ) ) + 0xf6eb - 0xd2;
    llLinksetDataWrite ( "addon_listen", (string) llListen ( API_CHANNEL, "", "", "" ) );
    Link ( "online", 0, "", llGetOwner () ); // This is the signal to initiate communication between the addon and the collar
    llSetTimerEvent ( 10 );
    llLinksetDataWrite ( "addon_LMLastRecv", (string) llGetUnixTime () );
    llLinksetDataWrite ( "addon_LMLastSent", (string) llGetUnixTime () );
}

do_lock()
{
    if((integer)llLinksetDataRead("addon_lock"))
    {
        llPlaySound(g_sLockSound,1);
        llOwnerSay("@Detach=n");
    }
    else 
    {
        llPlaySound(g_sUnlockSound,1);
        llOwnerSay("@Detach=y");
    }
}

Notify ( string sMsg, key kID )
{
    llInstantMessage ( kID, sMsg );
    if ( kID != llGetOwner () )
    {
        llOwnerSay ( sMsg );
    }
    sMsg    ="";
    kID     = "";
}

check_settings ( string sToken, string sDefaulVal )
{
    if( !~llListFindList ( llLinksetDataListKeys ( 0, 0 ), [ sToken ] ) ) // token/key doesn't exist in the list of keys
    {
        llLinksetDataWrite ( sToken, sDefaulVal );
    }
    else if ( llLinksetDataRead ( sToken ) == "" )
    {
        llLinksetDataWrite ( sToken, sDefaulVal );
    }
}

default
{
    state_entry ()
    {
        llLinksetDataWrite( "addon_ready", (string)FALSE);
        llLinksetDataWrite( "addon_name", g_sAddon );
        llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
        do_lock();
        check_settings ( "global_prefix", llToLower( llGetSubString ( llKey2Name( llGetOwner () ), 0, 1 ) ) );
        check_settings ( "addon_online", (string) TRUE );
        check_settings ( "sync_prefix", (string)TRUE );
        check_settings ( "sync_owner", (string) TRUE );
        check_settings ( "sync_trust", (string) TRUE );
        check_settings ( "sync_block", (string) TRUE );
        check_settings ( "sync_group", (string) TRUE );
        llOwnerSay ( "Checking status please wait!" );
        if ( (integer) llLinksetDataRead ( "addon_online" )  && (integer) llLinksetDataRead ( "addon_mode" ) )
        {
            llLinksetDataWrite ( "addon_moderezzed", (string) TRUE );
            llSetTimerEvent ( 30 );
            goOnline ();
        }
        else
        {
            state offline;
        }
    }
    attach ( key kID )
    {
        if ( kID != NULL_KEY )
        {
            llLinksetDataWrite ( "addon_name", g_sAddon );
            llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
            do_lock();
            check_settings ( "global_prefix", llToLower ( llGetSubString ( llKey2Name ( llGetOwner () ), 0, 1 ) ) );
        }
    }

    listen ( integer iChannel, string sName, key kID, string sMsg )
    {
        if ( llGetOwnerKey ( kID ) != llGetOwner () )
        {
            // this check only works on addons owned by the collar wearer, like clothing or personal furnature.
           return;
        }
        string sPacketType = llJsonGetValue ( sMsg, [ "pkt_type" ] );
        if ( sPacketType == "approved" )
        {
            // if we get responce disconnect then set ao to online mode.
            llListenRemove ( (integer) llLinksetDataRead ( "addon_listen" ) );
            Link ( "offline", 0, "", llGetOwnerKey ( (key) llLinksetDataRead ( "collar_uuid" ) ) );
            llLinksetDataDelete ( "collar_uuid" );
            llLinksetDataDelete ( "collar_name" );
            llSetTimerEvent ( 0 );
            sMsg        = "";
            sName       = "";
            iChannel    = 0;
            state online;
        }
        sMsg        = "";
        sName       = "";
        iChannel    = 0;
    }

    timer ()
    {

        llSetTimerEvent ( 0 );
        llListenRemove( (integer) llLinksetDataRead ( "addon_listen" ) );
        llLinksetDataWrite ( "addon_onlineretry", (string) TRUE );
        state offline;
    }

    linkset_data ( integer iAction, string sName, string sValue)
    {
        if ( iAction == LINKSETDATA_UPDATE )
        {
            if( sName == "addon_loaded" )
            {
                llResetScript();
            }
        }
    }
}

state online
{
    state_entry ()
    {
        llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
        llLinksetDataWrite ( "addon_onlineretry", (string) FALSE );
        goOnline ();
        llSetTimerEvent ( 1 );
        llOwnerSay ( "Connected to collar satus online" );
        if((integer)llLinksetDataRead("sync_prefix"))
        {
            llOwnerSay ( g_sAddon + " in online mode, you can  use /1[collarprefix]" + llToLower(g_sAddon) +" commands" );
        }
        else
        {
            llOwnerSay ( g_sAddon + " in online mode, you can use /1" + llLinksetDataRead ( "global_prefix" ) + llToLower(g_sAddon) +" commands" );
        }
        llLinksetDataWrite( "addon_ready", (string)TRUE);
    }
    
    attach ( key kID )
    {
        if ( kID != NULL_KEY )
        {
            llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
            check_settings ( "global_prefix", llToLower ( llGetSubString ( llKey2Name ( llGetOwner () ), 0, 1 ) ) );
            do_lock();
        }
    }

    changed ( integer change )
    {
        if ( change & CHANGED_REGION )
        {
            Link ( "update", 0, "", (key) llLinksetDataRead ( "collar_uuid" ) );
        }
    }

    timer ()
    {
        if (llGetUnixTime() >= ( (integer) llLinksetDataRead("addon_LMLastSent") + 30 ) )
        {
            llLinksetDataWrite("addon_LMLastSent", (string) llGetUnixTime() );
            Link( "ping", 0, "", (key) llLinksetDataRead("collar_uuid") );
            Link( "from_addon", LM_SETTING_REQUEST, "addon_card", "" );
        }
        if (llGetUnixTime() > ( (integer)llLinksetDataRead("addon_LMLastRecv") + (5 * 60) ) && llLinksetDataRead("collar_uuid") != NULL_KEY)
        {
            state default;
        }
        if ((key)llLinksetDataRead("collar_uuid") == NULL_KEY)
        {
            state default;
        }
    }

    link_message ( integer iLink, integer iNum, string sMsg, key kID )
    {
        if ( iNum <= CMD_WEARER && iNum >= CMD_OWNER )
        {
            if( sMsg == "CollarMenu" )
            {
                Link ( "from_addon", iNum, "menu Addons", kID );
            }
        }
    }

    listen ( integer iChannel, string sName, key kID, string sMsg )
    {
        if ( llLinksetDataRead ( "collar_name" ) == sName && llGetOwnerKey ( kID ) != llGetOwner () )
        {
            // this check only works on addons owned by the collar wearer, like clothing or personal furnature.
            return;
        }
        string sPacketType = llJsonGetValue ( sMsg, [ "pkt_type" ] );
        if ( (key) llLinksetDataRead ( "collar_uuid" ) == NULL_KEY )
        {
            if ( sPacketType == "approved" )
            {
                // This signal, indicates the collar has approved the addon and that communication requests will be responded to if the requests are valid collar LMs.
                if( (integer) llLinksetDataRead ( "addon_moderezzed" ) )
                {
                    llLinksetDataDelete ( "addon_moderezzed" );
                }
                llLinksetDataWrite ( "collar_uuid", (string) kID );
                llLinksetDataWrite ( "collar_name", (string) sName );
                llListenRemove ( (integer) llLinksetDataRead ( "addon_listen" ) );
                llLinksetDataWrite ( "addon_listen", (string) llListen ( API_CHANNEL, sName, kID, "" ) );
                llLinksetDataWrite ( "addon_LMLastRecv", (string) llGetUnixTime () );
                Link ( "from_addon", LM_SETTING_REQUEST, "ALL", "" );
                llLinksetDataWrite ( "addon_LMLastSent", (string) llGetUnixTime() );
                llSetTimerEvent( 10 );// move the timer here in order to wait for collar responce.
            }
        }
        else
        {
            if ( sPacketType == "dc" && (key) llLinksetDataRead( "collar_uuid" ) == kID )
            {
                sMsg = "";
                sName = "";
                iChannel = 0;
                state default;
            }
            else if ( sPacketType == "pong" && (key) llLinksetDataRead ( "collar_uuid" ) == kID )
            {
                llLinksetDataWrite ( "addon_LMLastRecv", (string) llGetUnixTime () );
            }
            else if ( sPacketType == "from_collar" )
            {
                llLinksetDataWrite ( "addon_LMLastRecv", (string) llGetUnixTime () );
                // process link message if in range of addon
                if ( llVecDist ( llGetPos (), llList2Vector ( llGetObjectDetails ( kID, [ OBJECT_POS ] ), 0 ) ) <= 10.0 )
                {
                    integer iNum = (integer) llJsonGetValue ( sMsg, [ "iNum" ] );
                    string sStr  = llJsonGetValue ( sMsg, [ "sMsg" ] );
                    key kAv      = (key) llJsonGetValue ( sMsg, [ "kID" ] );
                    if ( iNum >= CMD_OWNER && iNum <= CMD_WEARER )
                    {
                        UserCommand ( iNum, sStr, kAv );
                    }
                    else if ( iNum == LM_SETTING_RESPONSE)
                    {
                        list lPar       = llParseString2List ( sStr, [ "_", "=" ], [] );
                        string sToken   = llList2String ( lPar, 0 );
                        string sVar     = llList2String ( lPar, 1 );
                        string sValue   = llList2String ( lPar, 2 );
                        if ( sToken == "auth" )
                        {
                            if ( sVar == "owner"  && (integer)llLinksetDataRead( "sync_owner"))
                            {
                                //llOwnerSay("[addon auth_owener]"+sStr);
                                list lAuth = llParseString2List( sValue, [","], []);
                                integer iIndex;
                                integer iEnd = llGetListLength(lAuth);
                                //llOwnerSay("[addon auth_owner count]"+(string)iEnd);
                                for(iIndex = 0; iIndex < iEnd; iIndex++)
                                {
                                    if ( !~llSubStringIndex( llLinksetDataRead( "auth_owner"), llList2String( lAuth, iIndex)))
                                    {
                                        if ( llLinksetDataRead( "auth_owner") == "")
                                        {
                                            llLinksetDataWrite( "auth_owner", llList2String( lAuth, iIndex));
                                        }
                                        else
                                        {
                                            llLinksetDataWrite( "auth_owner", llLinksetDataRead( "auth_owner")+","+llList2String( lAuth, iIndex));
                                        }
                                    }
                                }
                            }
                            if ( sVar == "trust" && (integer)llLinksetDataRead( "sync_trust"))
                            {
                                list lAuth = llParseString2List(sValue,[","],[]);
                                integer iIndex;
                                integer iEnd = llGetListLength(lAuth);
                                for(iIndex = 0; iIndex < iEnd; iIndex++)
                                {
                                    if ( !~llSubStringIndex( llLinksetDataRead ("auth_trust"), llList2String( lAuth, iIndex)))
                                    {
                                        if ( llLinksetDataRead( "auth_trust") == "")
                                        {
                                            llLinksetDataWrite ("auth_trust", llList2String( lAuth, iIndex));
                                        }
                                        else
                                        {
                                            llLinksetDataWrite( "auth_trust", llLinksetDataRead("auth_trust")+","+llList2String( lAuth, iIndex));
                                        }
                                    }
                                }
                            }
                            if ( sVar == "block" && (integer)llLinksetDataRead("sync_block"))
                            {
                                
                                //llOwnerSay("[addon auth_block]"+sStr);
                                list lAuth = llParseString2List(sValue,[","],[]);
                                integer iIndex;
                                integer iEnd = llGetListLength(lAuth);
                                for(iIndex = 0; iIndex < iEnd; iIndex++)
                                {
                                    if ( !~llSubStringIndex( llLinksetDataRead ("auth_block"), llList2String( lAuth, iIndex)))
                                    {
                                        if ( llLinksetDataRead( "auth_block") == "")
                                        {
                                            llLinksetDataWrite ("auth_block", llList2String( lAuth, iIndex));
                                        }
                                        else
                                        {
                                            llLinksetDataWrite( "auth_block", llLinksetDataRead("auth_block")+","+llList2String( lAuth, iIndex));
                                        }
                                    }
                                }
                            }
                            if ( sVar == "group" && (integer)llLinksetDataRead("sync_group"))
                            {
                                if( sValue != llLinksetDataRead ( "auth_group" ) )
                                {
                                    llLinksetDataWrite ( "auth_group", sValue );
                                }
                            }
                        }
                        else if( sToken == "global" )
                        {
                            if ( sVar == "prefix"  && (integer)llLinksetDataRead("sync_prefix"))
                            {
                                llLinksetDataWrite ( "global_prefix", sValue );
                            }
                            else if( sVar == "locked" && (integer)llLinksetDataRead("sync_lock"))
                            {
                                llLinksetDataWrite ( "addon_lock", sValue );
                            }
                        }
                        lPar = [];
                        sToken = "";
                        sVar = "";
                        sValue = "";
                    }
                    else if ( iNum >= CMD_OWNER && iNum <= CMD_EVERYONE )
                    {
                        UserCommand ( iNum, sStr, kAv );
                    }
                    sStr = "";
                }
            }
        }
        sPacketType = "";
        sMsg = "";
        sName = "";
        iChannel = 0;
    }

    touch_end ( integer iDetected )
    {
        key kID = llDetectedKey ( 0 );
        Input_Auth(kID, g_sAddon);
    }

    linkset_data ( integer iAction, string sName, string sValue )
    {
        if( iAction == LINKSETDATA_UPDATE )
        {
            if(sName == "addon_online" || sName == "addon_mode" )
            {
                state default;
            }
            else if( sName == "sync_lock" && (integer)sValue)
            {
                Link ( "from_addon", LM_SETTING_REQUEST, "global_locked", "" );
            }
            else if( sName == "addon_lock")
            {
                do_lock();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            state default;
        }
    }
}

state offline
{
    state_entry ()
    {
        llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
        if(llLinksetDataRead ( "addon_mode" ) )
        {
            // retry connection every 5 minutes.
            llSetTimerEvent ( 300 );
        }
        else
        {
            // assume ofline mode.
            llLinksetDataWrite ( "addon_online", (string) FALSE );
            llSetTimerEvent ( 0 );
        }
        llOwnerSay ( g_sAddon + " in offline mode, you can still use /1" + llLinksetDataRead ( "global_prefix" ) + llToLower(g_sAddon) +" commands" );
        llLinksetDataWrite ( "addon_listen", (string) llListen ( 1, "", NULL_KEY, "" ) );
        llLinksetDataWrite( "addon_ready", (string)TRUE);
    }
    
    timer ()
    {
        state default;
    }
    
    attach ( key kID )
    {
        if ( kID != NULL_KEY )
        {
            if ( kID != llGetOwner () )
            {
                llLinksetDataReset ();
            }
            else
            {
                llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
                check_settings ( "global_prefix", llToLower ( llGetSubString ( llKey2Name ( llGetOwner () ), 0, 1 ) ) );
                do_lock();
            }
        }
    }

    listen ( integer iChannel, string sName, key kID, string sMsg )
    {
        if ( ~llSubStringIndex ( llToLower ( sMsg ), llLinksetDataRead ( "global_prefix" ) ) )
        {
            //llOwnerSay(sMsg);
            sMsg = llDeleteSubString ( sMsg, 0, 1 );
            //llOwnerSay(sMsg);
            Input_Auth(kID,sMsg);
        }
    }

    touch_start ( integer iDetected )
    {
        key kID = llDetectedKey ( 0 );
        Input_Auth(kID, g_sAddon);
    }

    linkset_data( integer iAction, string sName, string sValue )
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "addon_online" || sName == "addon_mode")
            {
                state default;
            }
            else if( sName == "addon_lock")
            {
                do_lock();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            state default;
        }
    }
}
