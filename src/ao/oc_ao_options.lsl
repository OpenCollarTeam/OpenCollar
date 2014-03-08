////////////////////////////////////////////////////////////////////////////////////
// ------------------------------------------------------------------------------ //
//                             OpenCollarAO - Options                             //
//                                 version 3.940                                  //
// ------------------------------------------------------------------------------ //
// Licensed under the GPLv2 with additional requirements specific to Second Life® //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html  //
// ------------------------------------------------------------------------------ //
// ©   2008 - 2013  Individual Contributors and OpenCollar - submission set free™ //
// ------------------------------------------------------------------------------ //
////////////////////////////////////////////////////////////////////////////////////

// HudOptions (Alexei Maven + Jessenia Mocha) 
// This script could be used to position all HUDs quite easy.  Please remember this is Open Source 
// Thus you need to Credit Open Collar / Alexei Maven / Jessenia Mocha + Keep it full perm and not sell it! =)

// This script was intended to make the Sub AO as customizable as possible for the user.
// The second goal was to make it easy for the developers to make new add-ons, and minimize script changes.
// The code in this script reflects the two above goals. There is a reason for every line. 

// Start Jess's OC modified menu injection

// -- HUD Message Map
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
//Added for the collar auth system:
integer COMMAND_NOAUTH = 0;
integer COMMAND_AUTH = 42; //used to send authenticated commands to be executed in the core script
integer COMMAND_COLLAR = 499; //added for collar or cuff commands to put ao to pause or standOff and SAFEWORD
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;
integer COLLAR_INT_REQ = 610;
integer COLLAR_INT_REP = 611;
integer COMMAND_UPDATE = 10001;
integer OPTIONS = 69; // Hud Options LM
integer AOLock;
integer AOPower = TRUE; // -- Power will always be on when scripts are reset as that is the default state of the AO
integer AOSit;

vector AOoffcolor = <0.5, 0.5, 0.5>;
vector AOoncolor = <1,1,1>;

string UNLOCK = " UNLOCK";
string LOCK = " LOCK";
string SITANYON = "ZHAO_SITANYWHERE_ON";
string SITANYOFF = "ZHAO_SITANYWHERE_OFF";

string UPMENU = "AO Menu";
string parentmenu = "Main";
string submenu = "Options";
string submenu1 = "Textures";
string submenu2 = "Order";
string submenu3 = "Tint";
string currentmenu;
string texture;

key menuid;


key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
 "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}


// Start HUD Options 
list attachPoints = [ATTACH_HUD_TOP_RIGHT, ATTACH_HUD_TOP_CENTER, ATTACH_HUD_TOP_LEFT, 
                     ATTACH_HUD_BOTTOM_RIGHT, ATTACH_HUD_BOTTOM, ATTACH_HUD_BOTTOM_LEFT];

list primOrder = [0,1,2,3,4]; // -- List must always start with '0','1' 
// -- 0:Spacer, 1:Root, 2:Power, 3:Sit Anywhere, 4:Menu
// -- Spacer serves to even up the list with actual link numbers

integer Layout = 1;
integer Hidden;
integer SPosition = 69; // Nuff'said =D
integer oldPos;
integer newPos;
integer tintable = FALSE;

DoPosition(float yOff, float zOff)
{   // Places the buttons
    integer i;
    integer LinkCount=llGetListLength(primOrder);
    for (i=2;i<=LinkCount;++i)
    { 
        llSetLinkPrimitiveParams(llList2Integer(primOrder,i), [PRIM_POSITION, <0.0, yOff * (i-1), zOff * (i-1)>]);
    }    
}

DoTextures(string _style)
{   // -- Texture Settings by Jessenia Mocha
    // -- Texture UUID's [ Root, Power, Sit, Menu ]
    list _blue        = ["fe7844f7-1179-5ba1-eb46-d44d3bed5837",
                         "b666c23b-a75a-e5b6-fd26-c17fbe921121",
                         "cb4ea616-6478-3f8d-2207-4daee93a01c3",
                         "7d5ebb11-b3e2-4353-231b-c898c5645872"];
    
    list _red         = ["4d61335b-2b3d-e3d2-a6b9-e3fba73f9f8e",
                         "202d091c-e6fb-533d-9cfe-19e098d883c6",
                         "4ba67464-ae2b-7271-8445-de393a551eba",
                         "917d6349-a01b-1c1e-7c49-1b889fd81217"];

    list _graysquare  = ["0744de1c-a3bd-47db-b20f-2cb7b93a3ff1",
                         "ffbc0c09-7741-015a-37cb-67e1d6c15111",
                         "dd4832fb-9583-7b50-aacc-6b80e7508ddb",
                         "09b69dd4-eb80-e2de-7dba-70c8337d283c"];

    list _graycircle  = ["428f1dfc-251c-b204-da66-000082bee96f",
                         "47ae23a3-e9e7-e045-3a65-5389f2038b9f",
                         "b7db4e46-443d-6da7-246b-4b9a1d9a16ca",
                         "6df113f7-c667-106b-e276-31dc1be37513"];
                         
    list _whitetint   = ["8408646f-2d35-3938-cba9-0808a12fcb80",
                         "cc3bb8fd-8ccd-18a1-b570-e7d3fbbda5e7",
                         "d95be5fe-1a7a-2b44-3713-948135054822",
                         "eb1f670d-c34f-23cb-3beb-f859c3c0278e"];
                         
    // -- Texture lists complete    
    llOwnerSay("Setting texture scheme to :: \""+_style+"\""); // -- More for debugging than anything else
    
    
    // -- If we don't select "White" as the style, remove tintable flag and reset AOcolors
    if(_style != "White") 
    {
        tintable = FALSE; // -- Turn off tint
        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0]);
    }

    // -- Get the actual texture setting ready
    // integer _primNum = llGetNumberOfPrims(); // -- Yes this can be used, however, since the textures are hard-coded, no point.
    integer _primNum = 3;
    integer _i = 0;
    texture = _style;
    
    if(_style == "Gray Square")
    {
        do
        {
            llSetLinkPrimitiveParams(_i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(_graysquare,_i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        while((++_i)<=_primNum);    
        
    }
    else if(_style == "Gray Circle")
    {
        do
        {
            llSetLinkPrimitiveParams(_i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(_graycircle,_i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        while((++_i)<=_primNum);        
    }
    else if(_style == "Red")
    {
        do
        {
            llSetLinkPrimitiveParams(_i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(_red,_i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        while((++_i)<=_primNum);        
    } 
    else if(_style == "Blue")
    {
        do
        {
            llSetLinkPrimitiveParams(_i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(_blue,_i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        while((++_i)<=_primNum);        
    }
    else if(_style == "White")
    {
        do
        {
            llSetLinkPrimitiveParams(_i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(_whitetint,_i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        while((++_i)<=_primNum);        
    }

}

DoHide()
{   // This moves the child prims under the root prim to hide them
    llSetLinkPrimitiveParams(LINK_ALL_OTHERS, [PRIM_POSITION, <1.0, 0.0,  0.0>]);
}

DefinePosition()                
{    
    integer Position = llListFindList(attachPoints, [llGetAttached()]);
    if(Position != SPosition) // Allows manual repositioning, without resetting it, if needed
    {
        // Set up the six root prim locations which all other posistions are based from
        list RootOffsets = [   
        <0.0,  0.02, -0.04>,    // Top right        (Position 0)
        <0.0,  0.00, -0.04>,    // Top middle       (Position 1)
        <0.0, -0.02, -0.04>,    // Top left         (Position 2)
        <0.0,  0.02,  0.10>,    // Bottom right     (Position 3)
        <0.0,  0.00,  0.07>,   // Bottom middle    (Position 4)
        <0.0, -0.02,  0.07>];  // Bottom left      (Position 5)
    
        llSetPos((vector)llList2String(RootOffsets, Position)); // Position the Root Prim on screen 
        SPosition = Position;           
    }
    if(!Hidden) // -- Fixes Issue 615: HUD forgets hide setting on relog.
    {
        float yOff = 0.037; float zOff = 0.037; // This is the space between buttons     
                                                                                                   
        if (Layout == 0 || Position == 1 || Position == 4) // Horizontal + top and bottom are always horizontal
        {         
            if(Position == 2 || Position == 5) // Left side needs to push buttons right
                yOff = yOff * -1;
                zOff = 0.0;  
        }        
        else // Vertical
        {       
            if(Position == 0 || Position == 2)  // Top needs push buttons down
                zOff = zOff * -1;  
                yOff = 0.0;
        }               
            
        DoPosition(yOff, zOff); // Does the actual placement 
    }
} 

DoButtonOrder()
{   // -- Set the button order and reset display
    // -- llOwnerSay("Old Position: "+(string)(oldPos)+" :: New Position: "+(string)(newPos));
    list _tempList = [];
    integer _oldPos = llList2Integer(primOrder,oldPos);
    // -- llOwnerSay("Position "+(string)oldPos+" in 'primOrder' is "+(string)_oldPos);
    integer _newPos = llList2Integer(primOrder,newPos);
    // -- llOwnerSay("Position "+(string)newPos+" in 'primOrder' is "+(string)_newPos);
    
    integer _length = llGetListLength(primOrder);
    integer i = 2;
    _tempList += [0,1];
    for(;i<_length;++i)
    {
        integer _tempPos = llList2Integer(primOrder,i);
                
        if(_tempPos == _oldPos)
        {
            _tempList += [_newPos];
        }
        else if(_tempPos == _newPos)
        {
            _tempList += [_oldPos];
        }
        else 
        {
            _tempList += [_tempPos];
        }
    }
    
    primOrder = [];
    primOrder = _tempList;
    oldPos = -1;
    newPos = -1;
    
    DefinePosition();
}

DetermineColors()
{
    AOoncolor = llGetColor(0);
    float x;
    float y;
    float z;
    
    x = (AOoncolor.x/2);
    y = (AOoncolor.y/2);
    z = (AOoncolor.z/2);
    AOoffcolor = <x,y,z>;
}

DoStatus()
{
    if(AOPower) // Apply white on/off setting to power prim
    {   
        llSetLinkColor(2, AOoncolor , ALL_SIDES); 
    }
    else
    {
        llSetLinkColor(2, AOoffcolor , ALL_SIDES);  
    }
    if(AOSit) // Apply white on/off setting to sit prim
    {   
        llSetLinkColor(3, AOoncolor , ALL_SIDES); 
    }
    else
    {
        llSetLinkColor(3, AOoffcolor , ALL_SIDES);  
    }
}

DoReset()
{   // -- Reset the entire HUD back to default

    Layout = 1;
    SPosition = 69; // -- Don't we just love that position? *winks*
    tintable = FALSE;
    Hidden = FALSE;
    AOLock = FALSE;
    AOPower = TRUE;
    AOSit = FALSE;
    DoTextures("White");
    llSleep(1.5);
    primOrder = [0,1,2,3,4];
    DoHide();
    llSleep(1.0);
    DefinePosition();
    DoStatus();
    llSleep(1.5); // -- We want the position to be set before reset
    llOwnerSay("Finalizing HUD Reset... please wait a few seconds so all menus have time to initialize.");
    llResetScript();
}    
// End HUD Options    

// Start standard 
default
{
    changed(integer c)
    {
        if (c & CHANGED_OWNER) // Nice way to do this and not break everything in here
        {
            DoTextures("White");
            llGiveInventory(llGetOwner(),"OpenCollar SubAO Help Image");
            llResetScript();
        }
        else if (c & CHANGED_COLOR)
        {
            DetermineColors(); // -- If we change color because of tint, we need to set the new AOoffcolor!
            DoStatus();
        }
    }  
    
    attach(key attached)
    {        
        if (attached==NULL_KEY)  // Being detached
        {
            // -- Hidden = FALSE; -- Fixes Issue 615:       HUD forgets hide setting on relog.
            return;
        }
        
        else if(llGetAttached() <= 30) // Check the attach point is a HUD position
        {
            llOwnerSay("Sorry, this device can only be placed on the HUD.");
            llRequestPermissions(attached, PERMISSION_ATTACH);
            llDetachFromAvatar();
            return;
        }
        else // It's being attached and the attachment point is a HUD position, DefinePosition()
        {
            DefinePosition();
        }
    } 
    
    state_entry()
    {
        llSleep(1.0);        
        llMessageLinked(LINK_SET, MENUNAME_RESPONSE, parentmenu + "|" + submenu + "|" + submenu1, NULL_KEY);
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        
        //llOwnerSay(llGetScriptName()+": ["+(string)num+"] "+str+" ("+(string)id+")");
        
        if(num == SUBMENU && str == submenu)
        {
            currentmenu = submenu;
            
            string text = "\nThis menu sets your HUD options.\n";
            text += "[Horizontal] sets the button layout to Horizontal.\n\n";
            text += "[Vertical] sets the button layout to Vertical.\n\n";
            text += "[Textures] opens a sub menu to choose button texture.\n\n";
            text += "[Order] opens the sub menus to reorder the buttons.\n\n";
            //text += "[Reset] Resets ALL custom HUD settings.\n";
            
            list buttons = [];
            buttons += ["Horizontal"];   
            buttons += ["Vertical"]; 
            buttons += ["Textures"];
            buttons += ["Order"];
            //buttons += [" "];
            //buttons += ["Reset"];
            //buttons += [" "];
            
            list utility = [UPMENU];

            menuid = Dialog(llGetOwner(), text, buttons, utility, 0);
        }
        
        else if (num == COMMAND_AUTH && str == "ZHAO_RESET")
        {
            DoReset();
        }    
        
        else if(num == OPTIONS)
        {
            // --  llOwnerSay("We hit the HUD Options, Options LM: "+str);
            
            if(str == LOCK)
            {
                // -- Position in link is 2
                if(texture == "") texture = "White"; // -- Redundancy sake "texture" should never be blank =)
                
                if(texture == "Gray Square")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "0237e900-7c8e-be25-1d21-e0901c4792c2" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]); 
                }
                else if(texture == "Gray Circle")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "bc394fb7-2b65-35ff-b0b9-837e079ea61b" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }
                else if(texture == "Red")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "a4532a86-4815-9938-df9f-67ba3cbf5aa9" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }
                else if(texture == "Blue")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "7ebbdb82-e6cf-27f9-e508-d3eb84cc2be4" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }
                else if(texture == "White")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "34aa44c9-56ae-4eaa-2895-1858adc5964f" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }
                // Collapse the HUD and set AOLOCK so clicking the hide button dosnt do anyhting
                if(!Hidden)
                {
                    Hidden = TRUE;
                    AOLock = TRUE;
                    DoHide();
                }                
            }
            else if(str == UNLOCK)
            {
                // -- Position in link is 2
                if(texture == "") texture = "White"; // -- Redundancy sake "texture" should never be blank =)
                
                if(texture == "Gray Square")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "0744de1c-a3bd-47db-b20f-2cb7b93a3ff1" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);    
                }
                else if(texture == "Gray Circle")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "428f1dfc-251c-b204-da66-000082bee96f" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }
                else if(texture == "Red")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "4d61335b-2b3d-e3d2-a6b9-e3fba73f9f8e" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }
                else if(texture == "Blue")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "fe7844f7-1179-5ba1-eb46-d44d3bed5837" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }
                else if(texture == "White")
                {
                    llSetLinkPrimitiveParams(1,[PRIM_TEXTURE, ALL_SIDES, "8408646f-2d35-3938-cba9-0808a12fcb80" , <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
                }                
                // Un-Collapse the HUD and set AOLOCK so the button works again
                Hidden = FALSE;
                AOLock = FALSE;
                DefinePosition();                             
            }
            else if(str == SITANYON)
            { 
                // -- Position in link is 3
                if(texture != "White")
                    llSetLinkColor(3, <1.0, 1.0, 1.0> , ALL_SIDES);
                else
                    llSetLinkColor(3, AOoffcolor , ALL_SIDES);
                AOSit = TRUE;
            }
            else if(str == SITANYOFF)
            {
                // -- Position in link is 3
                if(texture != "White")
                    llSetLinkColor(3, <0.5, 0.5, 0.5> , ALL_SIDES);
                else
                    llSetLinkColor(3, AOoncolor , ALL_SIDES);
                AOSit = FALSE;
            }
            else if(str == "ZHAO_AOOFF")
            {
                if(texture != "White")
                    llSetLinkColor(2, <0.5, 0.5, 0.5> , ALL_SIDES);
                else 
                    llSetLinkColor(2, AOoffcolor , ALL_SIDES);
                AOPower = FALSE;
            }
            else if(str == "ZHAO_AOON")
            {
                if(texture != "White")
                    llSetLinkColor(2, <1, 1, 1> , ALL_SIDES);
                else 
                    llSetLinkColor(2, AOoncolor , ALL_SIDES);
                AOPower = TRUE;
            }
        }            
        
        else if(num == DIALOG_RESPONSE)
        {            
            if(id == menuid)
            {
                list menuparams = llParseString2List(str, ["|"], []);
                id = (key)llList2String(menuparams, 0);
                string response = llList2String(menuparams, 1);
                integer page = (integer)llList2String(menuparams, 2);
                
                if(currentmenu == submenu)
                {   // -- Inside the 'Options' menu, or 'submenu'
                    if(response == UPMENU)
                    {   // If we press the '^' and we are inside the Options menu, go back to OwnerHUD menu
                        llMessageLinked(LINK_THIS, COMMAND_OWNER, "ZHAO_MENU", id);
                    }
                    else if(response == "Horizontal")
                    {
                        Layout = 0; 
                        DefinePosition();
                    }
                    else if(response == "Vertical")
                    {
                        Layout = 69;  // Because we love 69!
                        DefinePosition();
                    }
                    else if(response == "Textures")
                    {
                        currentmenu = submenu1;
                        string text = "This is the menu for styles.\n";
                        text += "Selecting one of these options will\n";
                        text += "change the color of the HUD buttons.\n";
                        if(tintable) text+="Tint will allow you to change the HUD color\nto various shades via the 'Tint' menu.\n";
                        if(!tintable)text += "If [White] is selected, an extra menu named 'Tint' will appear in this menu.\n";
                        // -- text += "This menu will time out in " + (string)timeout + " seconds.";
                    
                        list buttons = [];
                        buttons += ["Gray Square"];
                        buttons += ["Gray Circle"];
                        buttons += ["Blue"];
                        buttons += ["Red"];
                        buttons += ["White"];
                        if(tintable) buttons += ["Tint"," "," "];
                        
                        list utility = [UPMENU];
                    
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "Order")
                    {
                        currentmenu = submenu2;
                        
                        string text = "This is the order menu, simply select the\n";
                        text += "button which you want to re-order.\n\n";
                        // -- text += "This menu will time out in " + (string)timeout + " seconds.";
                        
                        list buttons = [];
                        integer i;
                        integer _count = llGetListLength(primOrder);
                        for (i=0;i<_count;++i)
                        {
                            integer _pos = llList2Integer(primOrder,i);
                            if(_pos == 2) buttons += ["Power"];
                            else if(_pos == 3) buttons += ["Sit Any"];
                            else if(_pos == 4) buttons += ["Menu"];
                        }
                        buttons += ["Reset"];
                        
                        list utility = [UPMENU];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                }
                
                if(currentmenu == submenu1)
                {   // -- Inside the 'Texture' menu, or 'submenu1'
                    if(response == UPMENU)
                    {   // -- If we press the '^' and we are inside the Texture menu, go back to Options menu
                        llMessageLinked(LINK_SET, SUBMENU, submenu, id);
                    }
                    else if(response == "Gray Square")
                    {
                        DoTextures(response);
                    }
                    else if(response == "Gray Circle")
                    {
                        DoTextures(response);
                    }
                    else if(response == "Blue")
                    {
                        DoTextures(response);
                    }
                    else if(response == "Red")
                    {
                        DoTextures(response);
                    }
                    else if(response == "White")
                    {
                        tintable = TRUE;
                        DoTextures(response);
                    }
                    else if(response == "Tint")
                    {
                        currentmenu = submenu3;
                        
                        string text = "Select the color you wish to tint the HUD.\n";
                        text += "If you don't see a color you enjoy, simply edit\n";
                        text += "and select a color under the menu you wish.\n";
                        
                        list buttons = [];
                        buttons += ["Orange"];
                        buttons += ["Yellow"];
                        buttons += ["Pink"];
                        buttons += ["Purple"];
                        buttons += ["Sky Blue"];
                        buttons += ["Light Green"];
                        buttons += ["Cyan"];
                        buttons += ["Mint"];                
                        
                        list utility = [UPMENU];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }    
                }
                
                if(currentmenu == submenu2)
                {    // -- Inside the 'Order' menu, or 'submenu2'
                    if(response == UPMENU)
                    {   // -- If we press the '^' and we are inside the Order menu, go back to Options menu
                        llMessageLinked(LINK_THIS, COMMAND_OWNER, "ZHAO_MENU", id);
                    }
                    else if(response == "Power")
                    {
                        oldPos = llListFindList(primOrder, [2]);
                        
                        string text = "Select the new position for "+response+"\n\n";
                        
                        list buttons = [];
                        
                        integer i = 2;
                        integer _count = llGetListLength(primOrder);
                        for(;i<=_count;++i)
                        {
                            if(oldPos != i) 
                            {
                                integer _temp = llList2Integer(primOrder,i);
                                if(_temp == 2) buttons += ["Power:"+(string)i];
                                else if(_temp == 3) buttons += ["Sit Any:"+(string)i];
                                else if(_temp == 4) buttons += ["Menu:"+(string)i];
                            }
                        }
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "Sit Any")
                    {
                        oldPos = llListFindList(primOrder, [3]);
                        string text = "Select the new position for "+response+"\n\n";
                        
                        list buttons = [];
                        
                        integer i = 2;
                        integer _count = llGetListLength(primOrder);
                        for(;i<=_count;++i)
                        {
                            if(oldPos != i) 
                            {
                                integer _temp = llList2Integer(primOrder,i);
                                if(_temp == 2) buttons += ["Power:"+(string)i];
                                else if(_temp == 3) buttons += ["Sit Any:"+(string)i];
                                else if(_temp == 4) buttons += ["Menu:"+(string)i];
                            }
                        }
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "Menu")
                    {
                        oldPos = llListFindList(primOrder, [4]);
                        string text = "Select the new position for "+response+"\n\n";
                        
                        list buttons = [];
                        
                        integer i = 2;
                        integer _count = llGetListLength(primOrder);
                        for(;i<=_count;++i)
                        {
                            if(oldPos != i) 
                            {
                                integer _temp = llList2Integer(primOrder,i);
                                if(_temp == 2) buttons += ["Power:"+(string)i];
                                else if(_temp == 3) buttons += ["Sit Any:"+(string)i];
                                else if(_temp == 4) buttons += ["Menu:"+(string)i];
                            }
                        }
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if (response == "Reset")
                    {
                        string text = "Confirm reset of the button order to default.\n\n";
                        list buttons = [];
                        buttons += ["Confirm"];
                        buttons += ["Cancel"];
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if (response == "Confirm")
                    {
                        primOrder = [];
                        primOrder = [0,1,2,3,4];
                        llOwnerSay("Order position reset to default.");
                        DefinePosition();
                    }
                    else if(llSubStringIndex(response,":") >= 0)
                    {   // Jess's nifty parsing trick for the menus
                        list _newPosList = llParseString2List(response, [":"],[]);
                        newPos = llList2Integer(_newPosList,1);
                        DoButtonOrder();
                    }
                }
                
                if(currentmenu == submenu3)
                {    // -- Inside the 'Tint' menu, or 'submenu3'
                    if(response == UPMENU)
                    {
                        currentmenu = submenu1;
                        string text = "This is the menu for styles.\n";
                        text += "Selecting one of these options will\n";
                        text += "change the color of the HUD buttons.\n";
                        if(tintable) text+="Tint will allow you to change the HUD color\nto various shades via the 'Tint' menu.\n";
                        if(!tintable)text += "If [White] is selected, an extra menu named 'Tint' will appear in this menu.\n";
                    
                        list buttons = [];
                        buttons += ["Gray Square"];
                        buttons += ["Gray Circle"];
                        buttons += ["Blue"];
                        buttons += ["Red"];
                        buttons += ["White"];
                        if(tintable) buttons += ["Tint"," "," "];
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "Orange")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1.00000, 0.49804, 0.00000>, 1.0]);
                    }
                    else if(response == "Yellow")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1.00000, 1.00000, 0.00000>, 1.0]);
                    }
                    else if(response == "Light Green")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.00000, 1.00000, 0.00000>, 1.0]);
                    }
                    else if(response == "Pink")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1.00000, 0.58431, 1.00000>, 1.0]);
                    }
                    else if(response == "Purple")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <0.50196, 0.00000, 1.00000>, 1.0]);
                    }
                    else if(response == "Sky Blue")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES,  <0.52941, 0.80784, 1.00000>, 1.0]);
                    }
                    else if(response == "Cyan")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES,    <0.00000, 0.80784, 0.79216>, 1.0]);
                    }
                    else if(response == "Mint")
                    {
                        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES,   <0.49020, 0.73725, 0.49412>, 1.0]);
                    }
                }
            }
        }
        
        else if(num == DIALOG_TIMEOUT)
        {
            if(id == menuid)
            {
                llInstantMessage(llGetOwner(),"Menu timed out!");                
            }
        }
        
        else if(str == "hide")
        {     
            if(!AOLock) 
            {   // This disables the hide button when locked       
                if(Hidden)
                { 
                    Hidden = !Hidden;
                    DefinePosition();                              
                }
                else
                {
                    Hidden = !Hidden;
                    DoHide();
                }
            }
        }
    }
}
