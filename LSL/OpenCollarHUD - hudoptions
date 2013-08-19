// HudOptions (Alexei Maven + Jessenia Mocha) 
// This script could be used to position all HUDs quite easy.  Please remember this is Open Source 
// Thus you need to Credit Open Collar / Alexei Maven / Jessenia Mocha and not sell it!
// Special thanks to Betsy Hastings for her Cages!

// This script was intended to make the Open Collar Owners HUD as customizable as possible for the user.
// The second goal was to make it easy for the developers to make new add-ons, and minimize script changes.
// The code in this script reflects the two above goals. There is a reason for every line. 

// Start Jess's OC modified menu injection

// -- HUD Message Map
integer MENUNAME_RESPONSE = 3001;
integer SUBMENU = 3002;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

string UPMENU = "^";
string parentmenu = "Main";
string submenu = "Options";
string submenu1 = "Textures";
string submenu2 = "Order";
string submenu3 = "Tint";
string currentmenu;

key menuid;

key ShortKey()
{    // just pick 8 random hex digits and pad the rest with 0.  Good enough for dialog uniqueness.
    string chars = "0123456789abcdef";
    integer length = 16;
    string out;
    integer n;
    for (n = 0; n < 8; n++)
    {
        integer index = (integer)llFrand(16);//yes this is correct; an integer cast rounds towards 0.  See the llFrand wiki entry.
        out += llGetSubString(chars, index, index);
    }
     
    return (key)(out + "-0000-0000-0000-000000000000");
}

key Dialog(key rcpt, string prompt, list choices, list utilitybuttons, integer page)
{
    key id = ShortKey();
    llMessageLinked(LINK_SET, DIALOG, (string)rcpt + "|" + prompt + "|" + (string)page +
 "|" + llDumpList2String(choices, "`") + "|" + llDumpList2String(utilitybuttons, "`"), id);
    return id;
}


// Start HUD Options 
list attachPoints = [ATTACH_HUD_TOP_RIGHT, ATTACH_HUD_TOP_CENTER, ATTACH_HUD_TOP_LEFT, 
                     ATTACH_HUD_BOTTOM_RIGHT, ATTACH_HUD_BOTTOM, ATTACH_HUD_BOTTOM_LEFT];

list primOrder = [0,1,2,3,4,5,6]; // -- List must always start with '0','1' 
// -- 0:Spacer, 1:Root, 2:Menu, 3:TPSubs, 4:Cage, 5:Couples, 6:Leash
// -- Spacer serves to even up the list with actual link numbers

integer Layout;
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
    // -- Texture UUID's [ Root, Menu, Teleport, Cage, Couples, Leash ]
    list _blue        = ["fe7844f7-1179-5ba1-eb46-d44d3bed5837",
                         "7d5ebb11-b3e2-4353-231b-c898c5645872",
                         "db24ef0e-ca57-9f8c-ee1a-28fec74619ad",
                         "520ae188-c472-ab7b-b1c6-d0fe53698c57",
                         "2c52eb24-26a0-5110-089a-570b1602aaaa",
                         "599c0404-5b79-a292-1c4f-83b655a81b43"];
    
    list _red         = ["4d61335b-2b3d-e3d2-a6b9-e3fba73f9f8e",
                         "917d6349-a01b-1c1e-7c49-1b889fd81217",
                         "b75a0443-8f80-3889-f21d-8e895a34b2c0",
                         "d3a0b432-fbb6-44bd-4019-4fe75f17d2c4",
                         "c4ffeb2c-e779-b062-e254-b7afc9ca629e",
                         "d1684d22-627e-1370-987e-95e23c8a81a8"];

    list _graysquare  = ["0744de1c-a3bd-47db-b20f-2cb7b93a3ff1",
                         "09b69dd4-eb80-e2de-7dba-70c8337d283c",
                         "68ad78d3-8e7b-4025-d8b1-98560aa31123",
                         "d6835f43-2477-d638-e203-8a22daee09fb",
                         "e9a16c40-7561-5a69-f834-f2f613fde10a",
                         "c72aef83-a0f0-fece-be02-295473986e79"];

    list _graycircle  = ["428f1dfc-251c-b204-da66-000082bee96f",
                         "6df113f7-c667-106b-e276-31dc1be37513",
                         "6b1a404f-db40-1aa2-7080-b4ab4235b963",
                         "92087a5d-5009-5993-fed9-0274bfacd899",
                         "e856db47-1017-6bc8-69be-525945fbdb08",
                         "2a35bdf7-9744-aedf-ff60-5a49b04c356d"];
                         
    list _whitetint   = ["8408646f-2d35-3938-cba9-0808a12fcb80",
                         "eb1f670d-c34f-23cb-3beb-f859c3c0278e",
                         "a9245dc2-cca1-861e-c2da-e3cb071fb7a1",
                         "1ff141eb-a448-b5c3-942d-6531b5c9d047",
                         "a81b25f9-5ab1-dd02-5740-eb06ca5bf219",
                         "cf5b070b-f672-9488-81a4-945243ebb47d"];
                         
    // -- Texture lists complete    
    llOwnerSay("Setting texture scheme to :: \""+_style+"\""); // -- More for debugging than anything else
    
    // -- Upon a texture change we should also reset the 'tint'
    llSetLinkPrimitiveParams(LINK_SET,[PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0]);
    
    // -- If we don't select "White" as the style, remove tintable flag
    if(_style != "White") tintable = FALSE;
    
    integer _primNum = 5;
    integer _i = 0;
    
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

    list _tempList = [];
    integer _oldPos = llList2Integer(primOrder,oldPos);
    integer _newPos = llList2Integer(primOrder,newPos);
    
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

DoReset()
{   // -- Reset the entire HUD back to default
    integer    n = llGetInventoryNumber(INVENTORY_ALL);
    string _script;
    do
    {
        _script = llGetInventoryName(INVENTORY_SCRIPT,n);
        if(_script != llGetScriptName() && _script != "")
        {
            llResetOtherScript(_script);
        }
    } while (--n >= 0);
    Layout = 0;
    SPosition = 69; // -- Don't we just love that position? *winks*
    tintable = FALSE;
    Hidden = FALSE;
    DoTextures("Gray Square");
    llSleep(2.0);
    primOrder = [0,1,2,3,4,5,6];
    DoHide();
    llSleep(1.0);
    DefinePosition();
    llSleep(2.0); // -- We want the position to be set before reset
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
            DoTextures("Gray Square");
            llGiveInventory(llGetOwner(),"OpenCollar Owner HUD Help Image");
            llResetScript();
        }
    }  
    
    attach(key attached)
    {        
        if (attached==NULL_KEY)  // Being detached
        {
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
        if(num == SUBMENU && str == submenu)
        {
            currentmenu = submenu;
            
            string text = "\nThis menu sets your HUD options.\n";
            text += "[Horizontal] sets the button layout to Horizontal.\n\n";
            text += "[Vertical] sets the button layout to Vertical.\n\n";
            text += "[Textures] opens a sub menu to choose button texture.\n\n";
            text += "[Order] opens the sub menus to reorder the buttons.\n\n";
            text += "[Reset] Resets ALL custom HUD settings.\n";
            
            list buttons = [];
            buttons += ["Horizontal"];   
            buttons += ["Vertical"]; 
            buttons += ["Textures"];
            buttons += ["Order"];
            buttons += [" "];
            buttons += ["Reset"];
            buttons += [" "];
            
            list utility = [UPMENU];

            menuid = Dialog(llGetOwner(), text, buttons, utility, 0);
        }
        
        if(num == DIALOG_RESPONSE)
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
                        llMessageLinked(LINK_SET, SUBMENU, parentmenu, id);
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
                        
                        list buttons = [];
                        integer i;
                        integer _count = llGetListLength(primOrder);
                        for (i=0;i<_count;++i)
                        {
                            integer _pos = llList2Integer(primOrder,i);
                            if(_pos == 2) buttons += ["Menu"];
                            else if(_pos == 3) buttons += ["TPSubs"];
                            else if(_pos == 4) buttons += ["Cage"];
                            else if(_pos == 5) buttons += ["Couples"];
                            else if(_pos == 6) buttons += ["Leash"];
                        }
                        buttons += ["Reset"];
                        
                        list utility = [UPMENU];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if (response == "Reset")
                    {
                        string text = "Confirm reset of the entire HUD.\n\n";
                        list buttons = [];
                        buttons += ["Confirm"];
                        buttons += ["Cancel"];
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if (response == "Confirm")
                    {
                        DoReset();
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
                        llMessageLinked(LINK_SET, SUBMENU, submenu, id);
                    }
                    else if(response == "Menu")
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
                                if(_temp == 2) buttons += ["Menu:"+(string)i];
                                else if(_temp == 3) buttons += ["TPSubs:"+(string)i];
                                else if(_temp == 4) buttons += ["Cage:"+(string)i];
                                else if(_temp == 5) buttons += ["Couples:"+(string)i];
                                else if(_temp == 6) buttons += ["Leash:"+(string)i];
                            }
                        }
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "TPSubs")
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
                                if(_temp == 2) buttons += ["Menu:"+(string)i];
                                else if(_temp == 3) buttons += ["TPSubs:"+(string)i];
                                else if(_temp == 4) buttons += ["Cage:"+(string)i];
                                else if(_temp == 5) buttons += ["Couples:"+(string)i];
                                else if(_temp == 6) buttons += ["Leash:"+(string)i];
                            }
                        }
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "Cage")
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
                                if(_temp == 2) buttons += ["Menu:"+(string)i];
                                else if(_temp == 3) buttons += ["TPSubs:"+(string)i];
                                else if(_temp == 4) buttons += ["Cage:"+(string)i];
                                else if(_temp == 5) buttons += ["Couples:"+(string)i];
                                else if(_temp == 6) buttons += ["Leash:"+(string)i];
                            }
                        }
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "Couples")
                    {
                        oldPos = llListFindList(primOrder, [5]);
                        string text = "Select the new position for "+response+"\n\n";  
                        list buttons = [];
                        
                        integer i = 2;
                        integer _count = llGetListLength(primOrder);
                        for(;i<=_count;++i)
                        {
                            if(oldPos != i) 
                            {
                                integer _temp = llList2Integer(primOrder,i);
                                if(_temp == 2) buttons += ["Menu:"+(string)i];
                                else if(_temp == 3) buttons += ["TPSubs:"+(string)i];
                                else if(_temp == 4) buttons += ["Cage:"+(string)i];
                                else if(_temp == 5) buttons += ["Couples:"+(string)i];
                                else if(_temp == 6) buttons += ["Leash:"+(string)i];
                            }
                        }
                        
                        list utility = [];
                        
                        menuid = Dialog(id, text, buttons, utility, page);
                    }
                    else if(response == "Leash")
                    {
                        oldPos = llListFindList(primOrder, [6]);
                        string text = "Select the new position for "+response+"\n\n"; 
                        list buttons = [];
                        
                        integer i = 2;
                        integer _count = llGetListLength(primOrder);
                        for(;i<=_count;++i)
                        {
                            if(oldPos != i) 
                            {
                                integer _temp = llList2Integer(primOrder,i);
                                if(_temp == 2) buttons += ["Menu:"+(string)i];
                                else if(_temp == 3) buttons += ["TPSubs:"+(string)i];
                                else if(_temp == 4) buttons += ["Cage:"+(string)i];
                                else if(_temp == 5) buttons += ["Couples:"+(string)i];
                                else if(_temp == 6) buttons += ["Leash:"+(string)i];
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
                        primOrder = [0,1,2,3,4,5,6];
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
        
        if(num == DIALOG_TIMEOUT)
        {
            if(id == menuid)
            {
                llOwnerSay("Options Menu timed out!");               
            }
        }
        
        if(str == "hide")
        {            
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
    
    timer()
    {
        //
    }
}