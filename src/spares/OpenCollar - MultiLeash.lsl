//////////////////////////////////////////////////////////////////////////////////////
//           Original development by Joy Stipe for OpenCollar Project               //
//////////////////////////////////////////////////////////////////////////////////////
// Licensed under the GPLv2 with additional requirements specific to Second Life®   //
// and other virtual metaverse environments.  ->  www.opencollar.at/license.html    //
//////////////////////////////////////////////////////////////////////////////////////
//		Drop this script into an attachment to have that attachment make leash(es)	//
//		See the first code line for the entry to use in the DESCRIPTION field of	//
//		links/prims where leash should come from; setting no link descriptsions to	//
//		that will result in only the prim that contains this script being the		//
//		emitter.																	//
//////////////////////////////////////////////////////////////////////////////////////

// the description of a prim that identifies it as where to leash
string sEMITTER = "leashpoint";

integer HUD_CHANNEL;
key kWEARER;
key kTARGET;
list lPARTICLES;
list lLINKS;

debug(string sText)
{
    //llOwnerSay(llGetScriptName() + " DEBUG: " + sText);
}

integer GetIsInteger(string in)
{
    integer i;
    if (llGetSubString(in, 0, 0) == "-")
    {
        if (llStringLength(in) < 2) return FALSE;
        i = 1;
    }
    list n = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
    for (; i < llStringLength(in); i++)
    {
        if (!~llListFindList(n, [llGetSubString(in, i, i)])) return FALSE;
    }
    return TRUE;
}

integer GetIsFloat(string in)
{
    list check = llParseString2List(in, ["."], []);
    if (llGetListLength(check) != 2) return FALSE;
    integer i;
    for (; i < 2; i++)
    {
        if (!GetIsInteger(llList2String(check, i))) return FALSE;
    }
    return TRUE;
}

integer GetIsVec(string in)
{
    if (llGetSubString(in, 0, 0) != "<") return FALSE;
    if (llGetSubString(in, -1, -1) != ">") return FALSE;
    in = llGetSubString(in, 1, -2);
    list check = llParseString2List(in, [","], []);
    if (llGetListLength(check) != 3) return FALSE;
    integer i;
    for (; i < 3; i ++)
    {
        string d = llStringTrim(llList2String(check, i), STRING_TRIM);
        if (!GetIsInteger(d) && !GetIsFloat(d)) return FALSE;
    }
    return TRUE;
}

integer GetIsKey(string in)
{
    if ((key)in) return TRUE;
    if ((key)in == NULL_KEY) return TRUE;
    return FALSE;
}

StartParticles()
{
    integer i;
    for (; i < llGetListLength(lLINKS); i++)
    {
        llLinkParticleSystem(llList2Integer(lLINKS, i), []);
        llLinkParticleSystem(llList2Integer(lLINKS, i), lPARTICLES);
    }
}

StopParticles()
{
    integer i;
    for (; i < llGetListLength(lLINKS); i++)
    {
        llLinkParticleSystem(llList2Integer(lLINKS, i), []);
    }
    kTARGET = NULL_KEY;
    lPARTICLES = [];
}

default
{
    state_entry()
    {
        lLINKS = [];
        integer i;
        for (; i <= llGetNumberOfPrims(); i++)
        {
            list d = llParseString2List(llList2String(llGetLinkPrimitiveParams(i, [28]), 0), ["~"], []);
            if (llList2String(d, 0) == sEMITTER) lLINKS += [i];
        }
        if (!llGetListLength(lLINKS)) lLINKS = [llGetLinkNumber()];
        StopParticles();
        llSleep(0.001);
        kWEARER = llGetOwner();
        HUD_CHANNEL = (integer)("0x" + llGetSubString((string)kWEARER, 2, 7)) + 1111;
        if (HUD_CHANNEL > 0) HUD_CHANNEL *= -1;
        if (HUD_CHANNEL > -10000) HUD_CHANNEL -= 30000;
        llListen(HUD_CHANNEL, "", "", "");
        if (kTARGET != NULL_KEY)
        {
            debug ("entry leash targeted");
            StartParticles();
        }
    }
    
    on_rez(integer iRez)
    {
        llResetScript();
    }
    
    listen(integer c, string n, key k, string s)
    {
        if (c == HUD_CHANNEL)
        {
            list parts = llParseString2List(s, ["\\"], []);
            key tar = (key)llList2String(parts, 0);
            string com = llList2String(parts, 1);
            string val = llList2String(parts, 2);
            if (com == "LeashUp")
            {
                kTARGET = tar;
                integer i;
                parts = llCSV2List(val);
                lPARTICLES = [];
                for (; i < llGetListLength(parts); i++)
                {
                    string bit = llList2String(parts, i);
                    if (GetIsInteger(bit)) lPARTICLES += [(integer)bit];
                    else if (GetIsFloat(bit)) lPARTICLES += [(float)bit];
                    else if (GetIsVec(bit)) lPARTICLES += [(vector)bit];
                    else if (GetIsKey(bit)) lPARTICLES += [(key)bit];
                    else lPARTICLES += [bit];
                }
                StartParticles();
            }
            else if (com == "Unleash")
            {
                StopParticles();
            }
        }
    }
}
