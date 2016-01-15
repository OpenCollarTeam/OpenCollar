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
//        AO Options - 150603.1          .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2015 Nandana Singh, Jessenia Mocha, Alexei Maven,  //
//  Wendy Starfall, littlemousy, Romka Swallowtail, Garvin Twine et al.     //
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
//           github.com/OpenCollar/opencollar/tree/master/src/ao            //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// -- HUD Message Map
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;
//Added for the collar auth system:
integer CMD_NOAUTH = 0;
integer CMD_AUTH = 42; //used to send authenticated commands to be executed in the core script
//integer CMD_COLLAR = 499; //added for collar or cuff commands to put ao to pause or standOff and SAFEWORD
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
//integer CMD_WEARER = 503;
//integer CMD_EVERYONE = 504;
//integer COLLAR_INT_REQ = 610;
//integer COLLAR_INT_REP = 611;
//integer CMD_UPDATE = 10001;
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
{
    // -- Texture UUID's [ Root, Power, Sit, Menu ]
    list _dark=["e1482c7e-8609-fcb0-56d8-18c3c94d21c0","e630e9e0-799e-6acc-e066-196cca7b37d4","251b2661-235e-b4d8-0c75-248b6bdf6675","f3ec1052-6ec4-04ba-d752-937a4d837bf8"];
    
    list _light=["b59f9932-5de4-fc23-b5aa-2ab46d22c9a6","42d4d624-ca72-1c74-0045-f782d7409061","349340c5-0045-c32d-540e-52b6fb77af55","52c3f4cf-e87e-dbdd-cf18-b2c4f6002a96"];
                         
    // -- Texture lists complete    
    llOwnerSay("Setting texture scheme to :: \""+_style+"\""); // -- More for debugging than anything else
    
    
    // -- If we don't select "White" as the style, remove tintable flag and reset AOcolors
    /*if(_style != "White") 
    {
        tintable = FALSE; // -- Turn off tint
        llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0]);
    }*/

    // -- Get the actual texture setting ready
    // integer _primNum = llGetNumberOfPrims(); // -- Yes this can be used, however, since the textures are hard-coded, no point.
    integer _primNum = 3;
    integer _i = 0;
    texture = _style;
    
    if(_style == "Dark")
    {
        do
        {
            llSetLinkPrimitiveParams(_i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(_dark,_i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
        }
        while((++_i)<=_primNum);    
        
    }
    else if(_style == "Light")
    {
        do
        {
            llSetLinkPrimitiveParams(_i+1,[PRIM_TEXTURE, ALL_SIDES, llList2String(_light,_i), <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>, 0.0]);
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
        
        else if (num == CMD_AUTH && str == "ZHAO_RESET")
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
                        llMessageLinked(LINK_THIS, CMD_OWNER, "ZHAO_MENU", id);
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
                        buttons += ["Dark"];
                        buttons += ["Light"];
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
                    else if(response == "Dark")
                    {
                        DoTextures(response);
                    }
                    else if(response == "Light")
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
                        llMessageLinked(LINK_THIS, CMD_OWNER, "ZHAO_MENU", id);
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
