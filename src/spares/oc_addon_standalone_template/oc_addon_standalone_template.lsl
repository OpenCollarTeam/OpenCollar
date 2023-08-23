/*
    This file is a part of OpenCollar.
    Copyright ©2021
    : Contributors :
    Phidoux (taya.Maruti)
        * Aug 16 2023 - modified addon system to work as stand alone with cusomized menu support, based uppon AO 3.0.5
        * Aug 18 2023 - added the ability to call menu buttons from chat command.
        * Aug 18 2023 - added the collar sync toggles for collar settings.
        * Aug 20 2023 - Added comments.
        * Aug 20 2023 - Added a way to relay information between collar and other scripts in addon.
        * Aug 22 2023 - Fixed some issue with command relay.
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

//integer DIALOG                  = -9000; // send a message to oc_addon_menu to generate dialog.
//integer DIALOG_RESPONSE         = -9001; // reutrn the button pressed to the external script.
//integer DIALOG_TIMEOUT          = -9002;
integer MENU_REQUEST            = -9003; // Request a menu from another script.
integer MENU_REGISTER           = -9004; // Register a button to Main menu.
integer MENU_REMOVE             = -9005; // Remove a button from Main menu.
integer MENU_RESPONCE           = -9006; // Responce from Registration or Removal of button.

integer TO_COLLAR               = 9000; // Relay link messages to the collar from apps


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
    if ( iNum == CMD_BLOCKED && (iNum < CMD_OWNER || iNum > CMD_WEARER  || iNum != CMD_GROUP || !(integer)llLinksetDataRead("auth_open")))
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
            // Connect the addon to the collar
            llLinksetDataWrite("addon_online",(string)TRUE);
        }
        else if( sToken == "disconnect")
        {
            // Disconnect the addon from the collar
            llLinksetDataWrite ( "addon_online", (string) FALSE );
        }
        else if( ~llSubStringIndex(llToLower(llLinksetDataRead("menu_main")),sToken) || ~llSubStringIndex(llLinksetDataRead("menu_main"),sToken))
        {
            // if command exists as a button.
            if(sValue == "") // if the command has no following value treat as button.
            {
                llMessageLinked ( LINK_SET, MENU_REQUEST, (string)iNum + "|"+sToken, kID);
            }
            else // treat as comand.
            {
                llMessageLinked ( LINK_SET, iNum, sToken+" "+sValue, kID);
            }
        }
        else
        { 
            llMessageLinked ( LINK_SET, iNum, sToken+" "+sValue, kID);
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
        // if the wearer is kID always do CMD_WEARER.
        UserCommand ( CMD_WEARER, sMsg, kID );
    }
    else if ( llListFindList ( llParseString2List ( llLinksetDataRead ( "auth_owner" ), [ "," ], [] ), [ (string) kID ] ) != -1 )
    {
        // if the user is on Owner list set auth to CMD_OWNER.
        UserCommand ( CMD_OWNER, sMsg, kID );
    }
    else if ( llListFindList ( llParseString2List ( llLinksetDataRead ( "auth_trust" ), [ "," ], [] ), [ (string) kID ] ) != -1 )
    {
        // if the user is on Trusted list set the auth to CMD_TRUSTED.
        UserCommand ( CMD_TRUSTED, sMsg, kID );
    }
    else if ( llListFindList ( llParseString2List ( llLinksetDataRead ( "auth_block"), [ "," ], [] ), [ (string) kID ] ) != -1 )
    {
        llInstantMessage ( kID, "Sorry you are not authorized to use this" );
    }
    else if((integer)llLinksetDataRead( "auth_public" ))
    {
        // if public mode is enabled allow public
        UserCommand ( CMD_EVERYONE, sMsg, kID );
    }
}

goOnline ()
{
    // This is where we connect to the collar
    llLinksetDataWrite ( "collar_uuid", (string) NULL_KEY );
    // first we get the collar key for storage then we remove any listens that might be active from offline mode or pervious connections.
    if ( (integer) llLinksetDataRead ( "addon_listen" ) )
    {
        llListenRemove ( (integer) llLinksetDataRead ( "addon_listen" ) );
    }
    // then we generate a channel for the addon.
    API_CHANNEL = ( (integer) ( "0x" + llGetSubString ( (string) llGetOwner (), 0, 8 ) ) ) + 0xf6eb - 0xd2;
    // now we create the listen.
    llLinksetDataWrite ( "addon_listen", (string) llListen ( API_CHANNEL, "", "", "" ) );
    // then we tell the collar we are active.
    Link ( "online", 0, "", llGetOwner () ); // This is the signal to initiate communication between the addon and the collar
    // set the time out for a confirmation responce.
    llSetTimerEvent ( 10 );
    // set the last messages so that timer functions correctly.
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
}

default
{
    state_entry ()
    {
        // configure all default settings here.
        llLinksetDataWrite( "addon_ready", (string)FALSE);
        llLinksetDataWrite( "addon_name", g_sAddon );
        llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
        do_lock();
        check_settings ( "global_prefix", llToLower( llGetSubString ( llKey2Name( llGetOwner () ), 0, 1 ) ) );
        check_settings ( "addon_online", (string) TRUE ); // so that when addon mode is enabled it can be connected 
        check_settings ( "sync_prefix", (string)TRUE ); // allows the collar to syncronize prefix so the addon uses what your collar uses
        check_settings ( "sync_owner", (string) TRUE ); // allows the addon to use the same owners list as the collar
        check_settings ( "sync_trust", (string) TRUE ); // allows the addon to use the same trusted list as the collar
        check_settings ( "sync_block", (string) TRUE ); // allows the addon to use the same block list as the collar
        check_settings ( "sync_group", (string) TRUE ); // allows the addon to use the same group as the collar
        llOwnerSay ( "Checking status please wait!" );
        if ( (integer) llLinksetDataRead ( "addon_online" )  && (integer) llLinksetDataRead ( "addon_mode" ) ) // if in addon mode and online we try to connect
        {
            llLinksetDataWrite ( "addon_rezzed", (string) TRUE );
            llSetTimerEvent ( 30 );
            goOnline ();
        }
        else // otherwise we default to offline mode.
        {
            state offline;
        }
    }
    attach ( key kID )
    {
        if ( kID != NULL_KEY )
        {
            // just to make sure some settings are correct when addon is first attached.
            llLinksetDataWrite ( "addon_name", g_sAddon );
            llLinksetDataWrite ( "auth_wearer", (string) llGetOwner () );
            check_settings ( "global_prefix", llToLower ( llGetSubString ( llKey2Name ( llGetOwner () ), 0, 1 ) ) );
            do_lock();
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
            // if we get responce disconnect then set addon to online mode.
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
        // if the time out triggers clear connection information and set to offline mode.
        llSetTimerEvent ( 0 );
        llListenRemove( (integer) llLinksetDataRead ( "addon_listen" ) );
        llLinksetDataWrite ( "addon_onlineretry", (string) TRUE );
        state offline;
    }
}

state online
{
    state_entry ()
    {
        // we want to make sure some settings are set like disabling the retry timer.
        llLinksetDataWrite ( "addon_onlineretry", (string) FALSE );
        goOnline (); // go online aka connect to the collar.
        llSetTimerEvent ( 1 ); // set the timer for functions like pinging the collar.
        llOwnerSay ( "Connected to collar satus online" );
        if((integer)llLinksetDataRead("sync_prefix")) // allert the wearer to changes to prefix if any.
        {
            llOwnerSay ( g_sAddon + " in online mode, you can  use /1[collarprefix]" + llToLower(g_sAddon) +" commands" );
        }
        else
        {
            llOwnerSay ( g_sAddon + " in online mode, you can use /1" + llLinksetDataRead ( "global_prefix" ) + llToLower(g_sAddon) +" commands" );
        }
        llLinksetDataWrite( "addon_ready", (string)TRUE); // tell other scripts we are alive and ready.
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
            // we want to ensure stable connection with the collar so on a sim change we say hello
            Link ( "update", 0, "", (key) llLinksetDataRead ( "collar_uuid" ) );
        }
    }

    timer ()
    {
        if (llGetUnixTime() >= ( (integer) llLinksetDataRead("addon_LMLastSent") + 30 ) )
        {
            // we try to ensure the collar don't think we have disapeared with ping pong game.
            llLinksetDataWrite("addon_LMLastSent", (string) llGetUnixTime() );
            Link( "ping", 0, "", (key) llLinksetDataRead("collar_uuid") );
        }
        if (llGetUnixTime() > ( (integer)llLinksetDataRead("addon_LMLastRecv") + (5 * 60) ) && llLinksetDataRead("collar_uuid") != NULL_KEY)
        {
            // if the collar has not said any thing in a while we restart the connection.
            state default;
        }
        if ((key)llLinksetDataRead("collar_uuid") == NULL_KEY)
        {
            // because objects change uuid upon login we have to redo the connection.
            state default;
        }
    }

    link_message ( integer iLink, integer iNum, string sMsg, key kID )
    {
        if ( iNum <= CMD_WEARER && iNum >= CMD_OWNER )
        {
            // this is one way to call the collar menu.
            if( sMsg == "CollarMenu" )
            {
                Link ( "from_addon", iNum, "menu Addons", kID );
            }
        }
        else if (iNum == TO_COLLAR)
        {
            /* alternativly we can send messages to the collar using 
                llMessageLinked(TO_COLLAR,"(iNum/iAuth)^message",kID);
            */
            list lOutput = llParseString2List(sMsg,["^"],[]);
            iNum = llList2Integer(lOutput,0); // use iNum/iAuth embeded in message so that this call will function with TO_COLLAR being iNum in link message
            sMsg = llList2String(lOutput,1); // put every thing else as message to the collar.
            Link ( "from_addon", iNum, sMsg, kID); // send to collar.
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
                if( (integer) llLinksetDataRead ( "addon_rezzed" ) )
                {
                    
                    llLinksetDataDelete ( "addon_rezzed" );
                }
                llLinksetDataWrite ( "collar_uuid", (string) kID ); // save the collar id for authentication.
                llLinksetDataWrite ( "collar_name", (string) sName ); // save the collar name for authentication.
                llListenRemove ( (integer) llLinksetDataRead ( "addon_listen" ) ); // remove previous listen if any
                llLinksetDataWrite ( "addon_listen", (string) llListen ( API_CHANNEL, sName, kID, "" ) ); //generate new listen.
                llLinksetDataWrite ( "addon_LMLastRecv", (string) llGetUnixTime () ); // update recive timer
                Link ( "from_addon", LM_SETTING_REQUEST, "ALL", "" ); // ask for settings
                llLinksetDataWrite ( "addon_LMLastSent", (string) llGetUnixTime() ); // update send timer cause we asked for settings.
                llSetTimerEvent( 10 );// move the timer here in order to wait for collar responce.
            }
        }
        else
        {
            if ( sPacketType == "dc" && (key) llLinksetDataRead( "collar_uuid" ) == kID )
            {
                // if we are asked to disconnect retry connection we are in addon mode after all.
                sMsg = "";
                sName = "";
                iChannel = 0;
                state default;
            }
            else if ( sPacketType == "pong" && (key) llLinksetDataRead ( "collar_uuid" ) == kID )
            {
                // update the recived timer because collar responded to ping.
                llLinksetDataWrite ( "addon_LMLastRecv", (string) llGetUnixTime () );
            }
            else if ( sPacketType == "from_collar" )
            {
                // update the recived timer because collar sent settings.
                llLinksetDataWrite ( "addon_LMLastRecv", (string) llGetUnixTime () );
                // process link message if in range of addon
                if ( llVecDist ( llGetPos (), llList2Vector ( llGetObjectDetails ( kID, [ OBJECT_POS ] ), 0 ) ) <= 10.0 )
                {
                    integer iNum = (integer) llJsonGetValue ( sMsg, [ "iNum" ] );
                    string sStr  = llJsonGetValue ( sMsg, [ "sMsg" ] );
                    key kAv      = (key) llJsonGetValue ( sMsg, [ "kID" ] );
                    llMessageLinked(LINK_SET,iNum,sStr,kAv); // forward every thing so that other scripts can make use.
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
                                    // loop through keys given if more than one.
                                    if ( !~llSubStringIndex( llLinksetDataRead( "auth_owner"), llList2String( lAuth, iIndex)))
                                    {
                                        if ( llLinksetDataRead( "auth_owner") == "")
                                        {
                                            // if auth_owner is empty just add the frist key.
                                            llLinksetDataWrite( "auth_owner", llList2String( lAuth, iIndex));
                                        }
                                        else
                                        {
                                            // other wise append it to the end.
                                            llLinksetDataWrite( "auth_owner", llLinksetDataRead( "auth_owner")+","+llList2String( lAuth, iIndex));
                                        }
                                    }
                                }
                            }
                            if ( sVar == "trust" && (integer)llLinksetDataRead( "sync_trust"))
                            {
                                // see auth_owner.
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
                                
                                // see auth_owner.
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
                                // update group value if it is different.
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
                                // set the addons prefix to what the collar uses.
                                llLinksetDataWrite ( "global_prefix", sValue );
                            }
                            else if( sVar == "locked" && (integer)llLinksetDataRead("sync_lock"))
                            {
                                // make the lock state match the collar.
                                llLinksetDataWrite ( "addon_lock", sValue );
                            }
                        }
                        lPar = [];
                        sToken = "";
                        sVar = "";
                        sValue = "";
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
        Input_Auth(kID, g_sAddon); // collect key and ensure they have authorization.
    }

    linkset_data ( integer iAction, string sName, string sValue )
    {
        if( iAction == LINKSETDATA_UPDATE )
        {
            if(sName == "addon_online" || sName == "addon_mode" )
            {
                // if addon mode or online mode changes we want to disconnect, may not be workign right.
                state default;
            }
            else if( sName == "sync_lock" && (integer)sValue)
            {
                // if sync_lock is enabled lets make sure the setting is updated.
                Link ( "from_addon", LM_SETTING_REQUEST, "global_locked", "" );
            }
            else if( sName == "addon_lock")
            {
                // if lock is changed for any reason lets make it happen.
                do_lock();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            // if we reset the linkset data we should reset the script to set defaults.
            state default;
        }
    }
}

state offline
{
    state_entry ()
    {
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
        // inform user of their prefix configuration 
        llOwnerSay ( g_sAddon + " in offline mode, you can still use /1" + llLinksetDataRead ( "global_prefix" ) + llToLower(g_sAddon) +" commands" );
        // generate listen for offline mode chat commands.
        llLinksetDataWrite ( "addon_listen", (string) llListen ( 1, "", NULL_KEY, "" ) );
        llLinksetDataWrite( "addon_ready", (string)TRUE); // let other scripts know we are online.
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
