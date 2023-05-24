/*
    A minimal re write of the AO System to use Linkset Data
    this script is intended to be a stand alone ao managed from linkset storage
    which would allow it to be populated by any interface script.
    Created: Mar 22 2023
    By: Phidoux (taya.Maruti)
    ------------------------------------
    | Contributers  and updates below  |
    ------------------------------------
    | Name | Date | comment            |
    ------------------------------------
    Phidoux (taya.Maruti) | 04/24/2023 | update linkset memory to reflect 128Kb of memory instead of 64Kb and allow individual numbers to be either (B)yte or (K)illo (B)yte
*/
recordMemory() // all scripts should use this  function to record thir memory.
{
    llLinksetDataWrite("memory_object",memoryMath());
    llLinksetDataWrite("memory_lsd",LinksetMemory());
    llLinksetDataWrite("memory_"+llGetScriptName(),(string)llGetUsedMemory());
}

string LinksetMemory()
{
    integer iMaxMemory = 131072;
    integer iFreeMemory = llLinksetDataAvailable();
    integer iUsedMemory = iMaxMemory-iFreeMemory;
    string sBit = "b";
    string fBit = "B";
    string uBit = "B";

    if( iMaxMemory>1024)
    {
        iMaxMemory = iMaxMemory/1024;
        sBit = "KB";
    }
    if(iFreeMemory>1024)
    {
        iFreeMemory = iFreeMemory/1024;
        fBit = "KB";
    }
    if(iUsedMemory>1024)
    {
        iUsedMemory = iUsedMemory/1024;
        uBit = "KB";
    }
    return (string)iUsedMemory+"("+uBit+")/"+(string)iFreeMemory+"("+fBit+")/"+(string)iMaxMemory+"("+sBit+")";
}

string memoryMath()
{
    integer iInventoryScripts = llGetInventoryNumber(INVENTORY_ALL);
    integer iCount = 0;
    integer iUsedMemory = 0;
    while(iCount < iInventoryScripts)
    {
        string sName = llGetInventoryName(INVENTORY_ALL,iCount);
        if(llGetInventoryType(sName) == INVENTORY_SCRIPT)
        {
            iUsedMemory += ((integer)llLinksetDataRead("memory_"+sName));
        }
        iCount++;
    }
    integer iMaxMemory = llList2Integer(llGetObjectDetails(llGetKey(),[OBJECT_SCRIPT_MEMORY]),0);
    integer iFreeMemory = iMaxMemory-iUsedMemory;
    string sBit = "B";
    string fBit = "B";
    string uBit = "B";

    if( iMaxMemory>1024)
    {
        iMaxMemory = iMaxMemory/1024;
        sBit = "KB";
    }
    if(iUsedMemory>1024)
    {
        iUsedMemory = iUsedMemory/1024;
        uBit = "KB";
    }
    if(iFreeMemory>1024)
    {
        iFreeMemory = iFreeMemory/1024;
        fBit = "KB";
    }
    return (string)iUsedMemory+"("+uBit+")/"+(string)iFreeMemory+"("+fBit+")/"+(string)iMaxMemory+"("+sBit+")";
}

printMemory(key kAv)
{
    integer iMaxMemory = (llList2Integer(llGetObjectDetails(llGetKey(),[OBJECT_SCRIPT_MEMORY]),0));
    integer iInventoryScripts = llGetInventoryNumber(INVENTORY_ALL);
    integer iCount = 0;
    string sScriptDetails;
    while(iCount < iInventoryScripts)
    {
        string sName = llGetInventoryName(INVENTORY_ALL,iCount);
        if(llGetInventoryType(sName) == INVENTORY_SCRIPT)
        {
            integer iMaxScript = iMaxMemory/llGetInventoryNumber(INVENTORY_SCRIPT);
            integer iUsedScript = (integer)llLinksetDataRead("memory_"+sName);
            integer iFreeScript = iMaxScript-iUsedScript;
            string sBit = "B";
            string fBit = "B";
            string uBit = "B";

            if( iMaxScript>1024)
            {
                iMaxScript = iMaxScript/1024;
                sBit = "KB";
            }
            if(iUsedScript>1024)
            {
                iUsedScript = iUsedScript/1024;
                uBit = "KB";
            }
            if(iFreeScript>1024)
            {
                iFreeScript = iFreeScript/1024;
                fBit = "KB";
            }
            if(sScriptDetails == "")
            {
                sScriptDetails = sName+": "+(string)iUsedScript+"("+uBit+")/"+(string)iFreeScript+"("+fBit+")/"+(string)iMaxScript+"("+sBit+")";
            }
            else
            {
                sScriptDetails += "\n"+sName+": "+(string)iUsedScript+"("+uBit+")/"+(string)iFreeScript+"("+fBit+")/"+(string)iMaxScript+"("+sBit+")";
            }
        }
        iCount++;
        sName = "";
    }
    llInstantMessage(kAv,
        "\n Memory: Used/Free/Max"+
        "\n Object Scripts: "+llLinksetDataRead("memory_object")+
        "\n Linkset: "+llLinksetDataRead("memory_lsd")+
        "\n|========================================|"+
        "\n"+sScriptDetails
    );
    iCount = 0;
    sScriptDetails = "";

}
default
{
    state_entry()
    {
        llSetTimerEvent(1);
        recordMemory();
    }
    timer()
    {
        // we send this out to make sure memory of all scripts is up to date.
        if((integer)llLinksetDataRead("memory_ping") < llGetUnixTime())
        {
            llLinksetDataWrite("memory_ping",(string)(llGetUnixTime()+300));
        }
    }
    link_message(integer iLink,integer iNum,string sMsg, key kID)
    {
        if(sMsg == "memory_print")
        {
            llOwnerSay("triggering memory Print");
            printMemory(kID);
        }
    }
    linkset_data(integer iAction, string sName, string sValue)
    {
        if(iAction == LINKSETDATA_UPDATE)
        {
            if (sName == "memory_ping")
            {
                //triggers the script to update its memory usage this should also be used in all scripts.
                recordMemory();
            }
            else if(~llSubStringIndex(sName,"memory_"))
            {
                // this script updates total memory used of object dependent on scripts with the record function.
                llLinksetDataWrite("memory_object",memoryMath());
            }
            else if (sName == "memory_print" && (key)sValue != NULL_KEY)
            {
                // this will trigger output of memory information that is availble
                llOwnerSay("triggering memory Print");
                printMemory(sValue);
                llLinksetDataWrite("memory_print",NULL_KEY);
            }
        }
        else if(iAction == LINKSETDATA_RESET)
        {
            llResetScript();
        }
    }
}
