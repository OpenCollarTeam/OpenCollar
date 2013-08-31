//OpenCollar - getavi
//Licensed under the GPLv2, with the additional requirement that these scripts remain "full perms" in Second Life.  See "OpenCollar License" for details.

// Format: REQ script asks for "add" TYPE from RCV script, with an optional name
// .... we return RCV=this script, REQ = back to, "add", TYPE, new key 
// string message = llList2CSV([RCV, REQ, "add", TYPE, name);
// llLinkedMessage(LINK_THIS, integer AUTH, message, key MenuUser)

key g_kWearer;

//MESSAGE MAP
integer COMMAND_NOAUTH = 0;
integer COMMAND_OWNER = 500;
integer COMMAND_SECOWNER = 501;
integer COMMAND_GROUP = 502;
integer COMMAND_WEARER = 503;
integer COMMAND_EVERYONE = 504;

integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

integer g_iRemenu = FALSE;
//dialog handler
key g_kMenuID;
key g_kDialoger; //the person using the dialog.
integer g_iDialogerAuth; //auth of the person using the dialog
string REQ; // requesting script
string TYPE; // requesting for what use?
list AVIS;

Debug(string sStr)
{
    //llOwnerSay(llGetScriptName() + ": " + sStr);
}

integer GetOwnerChannel(key kOwner, integer iOffset)
{
    integer iChan = (integer)("0x"+llGetSubString((string)kOwner,2,7)) + iOffset;
    if (iChan>0)
    {
        iChan=iChan*(-1);
    }
    if (iChan > -10000)
    {
        iChan -= 30000;
    }
    return iChan;
}
Notify(key kID, string sMsg, integer iAlsoNotifyWearer)
{
    if (kID == g_kWearer)
    {
        llOwnerSay(sMsg);
    }
    else if (llGetAgentSize(kID) != ZERO_VECTOR)
    {
        llInstantMessage(kID, sMsg);
        if (iAlsoNotifyWearer)
        {
            llOwnerSay(sMsg);
        }
    }
    else // remote request
    {
        llRegionSayTo(kID, GetOwnerChannel(g_kWearer, 1111), sMsg);
    }
}

string GetScriptID()
{
    // strip away "OpenCollar - " leaving the script's individual name
    list parts = llParseString2List(llGetScriptName(), ["-"], []);
    return llStringTrim(llList2String(parts, 1), STRING_TRIM) + "_";
}

list FindAvis(string in, list ex)
{
    list out = llGetAgentList(AGENT_LIST_REGION, []);
    string name;
    integer i = llGetListLength(out) - 1;
<<<<<<< HEAD:LSL/OpenCollar - getavi.lsl
    integer x = 0;
=======
>>>>>>> origin/evolution:LSL/OpenCollar - getavi.lsl
    while(~i)
    {
        name = llKey2Name(llList2Key(out, i));
        if (llSubStringIndex(llToLower(name), llToLower(in)) == -1)
            out = llDeleteSubList(out, i, i);
        i--;
    }
    Debug("first pass results: " + llList2CSV(out));
    i = llGetListLength(out) - 1;
    while (~i)
    {
        if (~llListFindList(ex, [llList2String(out, i)]))
            out = llDeleteSubList(out, i, i);
        i--;
    }
    Debug("second pass results: " + llList2CSV(out));
    return out;
}

key Dialog(key kRCPT, string sPrompt, list lChoices, list lUtilityButtons, integer iPage, integer iAuth)
{
    key kID = llGenerateKey();
    llMessageLinked(LINK_SET, DIALOG, (string)kRCPT + "|" + sPrompt + "|" + (string)iPage + "|" 
    + llDumpList2String(lChoices, "`") + "|" + llDumpList2String(lUtilityButtons, "`") + "|" + (string)iAuth, kID);
    return kID;
}

NamesMenu(key kID, list lAvs, integer iAuth)
{
    string sPrompt = "Select an avatar to add";
    g_kMenuID = Dialog(kID, sPrompt, lAvs, [], 0, iAuth);
}

integer UserCommand(integer auth, string comm, key user)
{
    if (auth < COMMAND_OWNER || auth > COMMAND_WEARER) return FALSE;
    list lists = llParseString2List(comm, ["|"], []);
    list params = llCSV2List(llList2String(lists, 0));
    if (llGetListLength(params) < 4) return FALSE;
    if (llList2String(params, 0) != GetScriptID()) return FALSE;
    if (llList2String(params, 2) != "add") return FALSE;
    REQ = llList2String(params, 1);
    TYPE = llList2String(params, 3);
    string name = "";
    if (llGetListLength(params) > 4)
    {
        name = llDumpList2String(llDeleteSubList(params, 0, 3), " ");
        Debug("Searching for: " + name);
    }
    list exclude = llCSV2List(llList2String(lists, 1));
    AVIS = FindAvis(name, exclude);
    integer i = llGetListLength(AVIS);
    if (!i)
    {
        string mess = "Could not find any avatars ";
        if (name != "") mess += "starting with \"" + name + "\" ";
        Notify(user, mess + "in the region", FALSE);
    }
    else if (i == 1 && llList2Key(AVIS, 0) == user) 
    {
        string sPrompt = "You are the only one in this region. Add yourself?";
        g_kMenuID = Dialog(user, sPrompt, ["Yes", "No"], [], 0, auth);
    }
    else NamesMenu(user, AVIS, auth);
    return TRUE;
}

SendKey(integer auth, key avi, key user)
{
    string out = llList2CSV([REQ, GetScriptID(), "add", TYPE, (string)avi]);
    llMessageLinked(LINK_THIS, auth, out, user);
}

default
{
    on_rez(integer r)
    {
        llResetScript();
    }
    state_entry()
    {
<<<<<<< HEAD:LSL/OpenCollar - getavi.lsl
=======
        g_sScript = llStringTrim(llList2String(llParseString2List(llGetScriptName(), ["-"], []), 1), STRING_TRIM) + "_";
>>>>>>> origin/evolution:LSL/OpenCollar - getavi.lsl
        g_kWearer = llGetOwner();
        AVIS = [];
    }
    link_message(integer link, integer num, string mess, key id)
    {
<<<<<<< HEAD:LSL/OpenCollar - getavi.lsl
=======
        integer i;
        list params = llParseString2List(mess, ["|"], []);
>>>>>>> origin/evolution:LSL/OpenCollar - getavi.lsl
        if (num == DIALOG_RESPONSE && id == g_kMenuID)
        {
            list params = llParseString2List(mess, ["|"], []);
            key user = (key)llList2String(params, 0);
            string name = llList2String(params, 1);
            integer auth = (integer)llList2String(params, 3);
            if (name == "Yes")
            {
                SendKey(auth, llList2Key(AVIS, 0), user);
                return;
            }
            else if (name == "No") return;
            for (; i < llGetListLength(AVIS); i++)
            {
                key avi = llList2Key(AVIS, i);
                if (avi == name)
                {
                    SendResult(avi);
                    return;
                }
            }
            // if we got here, something went wrong
            Debug("Button clicked did not match any buttons made");
        }
        else if (UserCommand(num, mess, id)) return;
    }
}