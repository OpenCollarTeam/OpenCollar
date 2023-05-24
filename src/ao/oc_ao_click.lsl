/*
    A minimal re write of the AO System to use Linkset Data
    this script is intended to be a stand alone ao managed from linkset storage
    which would allow it to be populated by any interface script.
    Created: Mar 21 2023
    By: Phidoux (taya.Maruti)
    ------------------------------------
    | Contributers  and updates below  |
    ------------------------------------
    | Name | Date | comment            |
    ------------------------------------
*/

// this texture is a spritemap with all buttons on it, for faster texture
// loading than having separate textures for each button.
string BTN_TEXTURE = "fb9a678d-c692-400e-e08c-9e0e85503925";

// There are 3 columns of buttons and 8 rows of buttons in the sprite map.
integer BTN_XS = 3;
integer BTN_YS = 2;

// starting at the top left and moving to the right, the button sprites are in
// this order.
list BTNS = [
    "Minimize",
    "Maximize",
    "Power",
    "Menu",
    "SitAny"
];

float g_fGap = 0.001; // This is the space between buttons
float g_Yoff = 0.002; // space between buttons and screen top/bottom border
float g_Zoff = 0.04; // space between buttons and screen left/right border

list g_lButtons ; // buttons names for Order menu
//list g_lPrimOrder = [0,1,2,3,4]; // -- List must always start with '0','1'
// -- 0:Spacer, 1:Root, 2:Power, 3:Sit Anywhere, 4:Menu
// -- Spacer serves to even up the list with actual link numbers

//integer g_iLayout = 1;
//integer g_iHidden = FALSE;
//integer g_iPosition = 69;
//integer g_iOldPos;

vector g_vAOoffcolor = <0.5,0.5,0.5>;
vector g_vAOoncolor = <1,1,1>;

FindButtons()// collect buttons names & links
{
    g_lButtons = [" ", "Minimize"] ;
    list g_lPrimOrder = [0, 1];  //  '1' - root prim
    integer i;
    for (i=2; i<=llGetNumberOfPrims(); ++i)
    {
        g_lButtons += llGetLinkPrimitiveParams(i, [PRIM_DESC]);
        g_lPrimOrder += i;
    }
    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_primorder",llDumpList2String(g_lPrimOrder,","));
    g_lPrimOrder = [];
}

SetButtonTexture(integer link, string name)
{
    integer idx = llListFindList(BTNS, [name]);
    if (idx == -1)
    {
        return;
    }
    integer x = idx % BTN_XS;
    integer y = idx / BTN_XS;
    vector scale = <1.0 / BTN_XS, 1.0 / BTN_YS, 0>;
    vector offset = <
        scale.x * (x - (BTN_XS / 2.0 - 0.5)),
        scale.y * -1 * (y - (BTN_YS / 2.0 - 0.5)),
    0>;
    llSetLinkPrimitiveParamsFast(link, [
        PRIM_TEXTURE,
            ALL_SIDES,
            BTN_TEXTURE,
            scale,
            offset,
            0
    ]);
}

TextureButtons()
{
    integer i = llGetNumberOfPrims();

    while (i)
    {
        string name = llGetLinkName(i);
        if (i == 1)
        {
            if ((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_toggle")) //g_iHidden)
            {
                name = "Maximize";
            }
            else
            {
                name = "Minimize";
            }
        }

        SetButtonTexture(i, name);
        i--;
    }
}

PositionButtons()
{
    integer iPosition = llGetAttached();
    vector vSize = llGetScale();
    //  Allows manual repositioning, without resetting it, if needed
    if (iPosition != (integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_position") && iPosition > 30)//do this only when attached to the hud
    {
        vector vOffset = <0.01, vSize.y/2+g_Yoff, vSize.z/2+g_Zoff>;
        if (iPosition == ATTACH_HUD_TOP_RIGHT || iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_LEFT)
        {
            vOffset.z = -vOffset.z;
        }
        if (iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_BOTTOM_LEFT)
        {
            vOffset.y = -vOffset.y;
        }
        llSetPos(vOffset); // Position the Root Prim on screen
        llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_position",(string)iPosition);
    }
    if ((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_toggle")) //(g_iHidden)
    {
        SetButtonTexture(1, "Maximize");
        llSetLinkPrimitiveParamsFast(LINK_ALL_OTHERS, [PRIM_POSITION,<1,0,0>]);
    }
    else
    {
        SetButtonTexture(1, "Minimize");
        float fYoff = vSize.y + g_fGap;
        float fZoff = vSize.z + g_fGap;
        if (iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_RIGHT)
        {
            fZoff = -fZoff;
        }
        if (iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_TOP_LEFT || iPosition == ATTACH_HUD_BOTTOM || iPosition == ATTACH_HUD_BOTTOM_LEFT)
        {
            fYoff = -fYoff;
        }
        if (iPosition == ATTACH_HUD_TOP_CENTER || iPosition == ATTACH_HUD_BOTTOM)
        {
            llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_layout",(string)0);
        }
        if (llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_layout"))
        {
            fYoff = 0;
        }
        else
        {
            fZoff = 0;
        }
        integer i;
        integer LinkCount=llGetListLength(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]));
        for (i=2;i<=LinkCount;++i)
        {
            llSetLinkPrimitiveParamsFast(llList2Integer(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]),i),[PRIM_POSITION,<0.01, fYoff*(i-1), fZoff*(i-1)>]);
        }
    }
}

/*DoButtonOrder(integer iNewPos)// -- Set the button order and reset display
{
    integer iOldPos = llList2Integer(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]),(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_oldpose"));
    iNewPos = llList2Integer(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]),iNewPos);
    integer i = 2;
    list lTemp = [0,1];
    for(;i<llGetListLength(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]));++i)
    {
        integer iTempPos = llList2Integer(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]),i);
        if (iTempPos == iOldPos)
        {
            lTemp += [iNewPos];
        }
        else if (iTempPos == iNewPos)
        {
            lTemp += [iOldPos];
        }
        else
        {
            lTemp += [iTempPos];
        }
    }
    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_primorder",llDumpList2String(lTemp,","));
    llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_oldpose",(string)-1);
    PositionButtons();
    lTemp = [];
}*/

DetermineColors()
{
    g_vAOoncolor = llGetColor(0);
    g_vAOoffcolor = g_vAOoncolor/2;
    ShowStatus();
}

ShowStatus()
{
    vector vColor = g_vAOoffcolor;
    if ((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power"))
    {
        vColor = g_vAOoncolor;
    }
    llSetLinkColor(llListFindList(g_lButtons,["Power"]), vColor, ALL_SIDES);
    if ((integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere"))
    {
        vColor = g_vAOoncolor;
    }
    else
    {
        vColor = g_vAOoffcolor;
    }
    llSetLinkColor(llListFindList(g_lButtons,["SitAny"]), vColor, ALL_SIDES);
}
/*
MenuInterval(key kID,integer iAuth)
{
    string sInterval = "won't change automatically.";
    if (g_iChangeInterval)
    {
        sInterval = "change every "+(string)g_iChangeInterval+" seconds.";
    }
    Dialog(kID, "\nStands " +sInterval, ["Never","20","30","45","60","90","120","180"], ["BACK"],iAuth,"Interval");
}

MenuChooseAnim(key kID, string sAnimState, integer iAuth)
{
    string sAnim = g_sSitAnywhereAnim;
    if (sAnimState == "Walking")
    {
        sAnim = g_sWalkAnim;
    }
    else if (sAnimState == "Sitting")
    {
        sAnim = g_sSitAnim;
    }
    string sPrompt = "\n"+sAnimState+": \""+sAnim+"\"\n";
    g_lAnims2Choose = llListSort(llParseString2List(llJsonGetValue(g_sJson_Anims,[sAnimState]),["|"],[]),1,TRUE);
    list lButtons;
    integer iEnd = llGetListLength(g_lAnims2Choose);
    integer i;
    while (++i<=iEnd)
    {
        lButtons += (string)i;
        sPrompt += "\n"+(string)i+": "+llList2String(g_lAnims2Choose,i-1);
    }
    Dialog(kID, sPrompt, lButtons, ["BACK"],iAuth,sAnimState);
}

MenuOptions(key kID,integer iAuth)
{
    Dialog(kID,"\nCustomize your AO!",["Horizontal","Vertical","Order"],["BACK"],iAuth, "options");
}

OrderMenu(key kID,integer iAuth)
{
    string sPrompt = "\nWhich button do you want to re-order?";
    integer i;
    list lButtons;
    integer iPos;
    for (i=2;i<llGetListLength(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]));++i)
    {
        iPos = llList2Integer(llParseString2List(llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_primorder"),[","],[]),i);
        lButtons += llList2List(g_lButtons,iPos,iPos);
    }
    Dialog(kID, sPrompt, lButtons, ["Reset","BACK"],iAuth, "ordermenu");
}
*/

recordMemory()
{
    llLinksetDataWrite("memory_"+llGetScriptName(),(string)llGetUsedMemory());
}

default
{
    state_entry()
    {
        recordMemory();
        FindButtons();
        PositionButtons();
        TextureButtons();
        DetermineColors();
    }

    attach(key kID)
    {
        if (kID != NULL_KEY)
        {
            llResetScript();
        }
    }

    linkset_data(integer iAction, string sName, string sValue)
    {

        if(iAction == LINKSETDATA_UPDATE)
        {
            if(sName == "memory_ping")
            {
                recordMemory();
            }
            else
            {
                ShowStatus();
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }

    touch_start(integer total_number)
    {
        if(llGetAttached())
        {
            string sButton = (string)llGetObjectDetails(llGetLinkKey(llDetectedLinkNumber(0)),[OBJECT_DESC]);
            if (sButton == "Menu")
            {
                //MenuAO(g_kWearer,CMD_WEARER);
                if(llDetectedKey(0) == llGetOwner())
                {
                    llMessageLinked(LINK_SET,503,sButton,llDetectedKey(0));
                }
            }
            else if (sButton == "SitAny")
            {
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_sitanywhere")));
            }
            else if (~llSubStringIndex(llToLower(sButton),"ao"))
            {
                //g_iHidden = !g_iHidden;
                //llOwnerSay("button to toggle ao touched");
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_toggle",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_toggle")));
                PositionButtons();
            }
            else if (sButton == "Power")
            {
                llLinksetDataWrite(llToLower(llLinksetDataRead("addon_name"))+"_power",(string)(!(integer)llLinksetDataRead(llToLower(llLinksetDataRead("addon_name"))+"_power")));
                ShowStatus();
            }
        }
    }
}
