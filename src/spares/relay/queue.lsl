// Queue Script by Da Chrome and Toy Wylie is licensed under a Creative Commons Attribution 3.0 Unported License. http://creativecommons.org/licenses/by/3.0/ Keep This Line Intact.
// You do NOT have to make derivative works open source.
// Queue Script, with ORG-compatible !who handling
// and Blacklisting System, with database lookup of names
// Experimental ORG support commented out in this version

// Constants

key WILDCARD="ffffffff-ffff-ffff-ffff-ffffffffffff"; // We use WILDCARD key for global clearing
list ORG_PARSE=["/"]; // Also to speed up list parsing, since inline created lists are process intensive to a degree
list EQUALS_PARSE=["="]; // For Semi Auto Mode
list NULL_LIST=[]; // Speeds up list emptying and empty list checking
integer MEMORY_LIMIT=61439; //Fine-tune to prevent Stackheap
integer PIN=-5875279; // Auto updater PIN (WIP)
list RLV_PARSE=["|"]; // Speeds up Parsing a little
key MESSAGE="Message";
//integer DEBUG=1; // Uncomment this and all //if(DEBUG) lines to enable debugging

// Variables

list blacklist; // Self Obvious
list blacklistNames; // For ease of use
list pendingBlacklist; // For Dataserver Lookup of Username
list pendingBlacklistDB; // Dataserver Key for the Username Lookup
list scannedKeys;
list scannedNames;
list queue=[]; //Strided List: [objectKey, commandList]
list controllers; // Needed to know which controllers are active
list whoAcceptedKeys; // To Auto Accept Objects from <user>
list commandList; // For fast detection of metas
list newRestrictions;
list metaFind; // To speed up metacommand searching
integer menuChannel;
integer menuListen;
integer menuTimeout=-1; // Every timer is independent
integer askTimeout=-1;  // Running on a heartbeat master
integer rejectTimeout=-1;
integer acceptTimeout=-1;
//integer handoverTimeout=-1;
integer dataserverTimeout=-1;
integer menuPages;
integer menuPage;
integer listPage;
integer primRelay;
//integer primORG;
integer startupMemory;
integer relayMode; //For Changing Between Ask, Auto, and Full Auto modes
integer power=1;
key permittedObject;
key rejectedObject;
//list handoverObjects;
string newCommands;
string lastControllers;
key newObject;
key ownerKey;
key whoKey;
init()
{
    ownerKey=llGetOwner();
    setPrims();
    llSetTimerEvent(1.0);
    if(llGetAttached()) llRequestPermissions(ownerKey,PERMISSION_TAKE_CONTROLS);
}
setPrims() //For setting the linked script prims
{
    primRelay=0;
//    primORG=0;
    integer v=0;
    integer w=llGetNumberOfPrims();
    while(++v<=w)
    {
        if(llGetLinkName(v)=="Relay") primRelay=v;
//        else if(llGetLinkName(v)=="ORG Extensions") primORG=v;
    }
}
powerOn()
{
    power=1;
}
powerOff()
{
    power=0;
    closeMenu();
    queue=NULL_LIST;
    whoAcceptedKeys=NULL_LIST;
}
updateQueue()
{
    commandList=[newCommands,ownerKey,llDumpList2String(newRestrictions,"|")];
    if(llGetListLength(queue)>2) queue=[newObject,llList2CSV(commandList)]+llDeleteSubList(queue,0,1);
    else if(llGetListLength(queue)==2) queue=[newObject,llList2CSV(commandList)];
    else queue=NULL_LIST;
}
list setupList()
{
    list buttons=["<<","<--",">>"];
    if(menuPage==7)
    {
        integer blacklistLength=llGetListLength(blacklistNames);
        if(llCeil(blacklistLength/8.0)<listPage) listPage=1;
        else if(listPage<1) listPage=llCeil(blacklistLength/8.0);
        integer end;
        if(listPage*8>=blacklistLength) end=blacklistLength-1;
        else end=listPage*8;
        integer x=listPage*8-8;
        do
        {
            buttons+=(string)x+":"+llList2String(blacklistNames,x);
        }
        while(++x<=end);
    }
    else
    {
        integer scannedLength=llGetListLength(scannedNames);
        if(llCeil(scannedLength/8.0)<listPage) listPage=1;
        else if(listPage<1) listPage=llCeil(scannedLength/8.0);
        integer end;
        if(listPage*8>=scannedLength) end=scannedLength-1;
        else end=listPage*8;
        integer x=listPage*8-8;
        do
        {
            buttons+=(string)x+":"+llList2String(scannedNames,x);
        }
        while(++x<=end);
    }
    return buttons;
}
closeMenu() // Closes the menu
{
    llListenRemove(menuListen);
    menuTimeout=-1;
    menuPage=0;
    llMessageLinked(LINK_ROOT,0,"BlackLight",NULL_KEY);
}
setMenu()
{
    menuChannel=(integer)(llFrand(1000)*1000+1000);
    menuListen=llListen(menuChannel,"",ownerKey,"");
    doMenu();
}
doMenu()
{
    menuTimeout=30;
    if(!menuPage)
    {
        llDialog(ownerKey,"Turbo Safety Relay Menu\n",["Add","Remove","Exit","List","Set Mode","Turn Off"],menuChannel);
    }
    else if(menuPage==1)
    {
        llDialog(ownerKey,"Turbo Safety Relay Menu\nAdd to Blacklist",["Scan User","Scan Object","<--","Input"],menuChannel);
    }
    else if(menuPage==2)
    {
        llDialog(ownerKey,"Turbo Safety Relay Menu\nRemove from Blacklist",["Input","Select","<--"],menuChannel);
    }
    else if(menuPage==3)
    {
        llTextBox(ownerKey,"Turbo Safety Relay Menu\nType one or more Keys or Usernames (if in-sim)\nTo Add to the Blacklist",menuChannel);
        menuTimeout+=90;
    }
    else if(menuPage==4)
    { //Scaned Users
        llDialog(ownerKey,"Turbo Safety Relay Menu\nChoose the User to blacklist.",setupList(),menuChannel);
    }
    else if(menuPage==5)
    { //Scanned Objects
        llDialog(ownerKey,"Turbo Safety Relay Menu\nChoose the Object to blacklist.",setupList(),menuChannel);
    }
    else if(menuPage==6)
    {
        llTextBox(ownerKey,"Turbo Safety Relay Menu\nType one or more Keys or Usernames (if in-sim)\nTo Remove from the Blacklist",menuChannel);
        menuTimeout+=90;
    }
    else if(menuPage==7)
    { // Remove with List
        llDialog(ownerKey,"Turbo Safety Relay Menu\nChoose the User or Object to remove.",setupList(),menuChannel);
    }
    else if(menuPage==8)
    {
        llDialog(ownerKey,"Turbo Safety Relay Menu\nAsk Mode: Asks for Permission\nSemi Auto: Allows Non-Restrictive RLV\nAutomatic: Allows RLV, Checks Blacklist\nFull Auto: Automatic, Ignores Blacklist (faster)",["Ask Mode","Semi Auto","<--","Automatic","Full Auto"],menuChannel);
    }
}
checkBlacklist(key id)
{
    integer index=llListFindList(controllers,[(string)id]);
    if(~index) llMessageLinked(primRelay,0,"Safety!",id);
    else
    {
        while(++index<3)
        {
            if(llGetOwnerKey(llList2Key(controllers,index))==id) llMessageLinked(primRelay,0,"Safety!",llList2Key(controllers,index));
        }
    }
}
addToBlacklist(integer index)
{
    key temp=llList2Key(scannedKeys,index);
    if(~llListFindList(blacklist,[temp])) llMessageLinked(LINK_ROOT,0,"Already Blacklisted",MESSAGE);
    else
    {
        if(llGetUsername(temp))
        {
            blacklist+=temp;
            string uname=llGetUsername(temp);
            if(llStringLength(uname)>21) uname=llDeleteSubString(uname,21,-1);
            blacklistNames+=uname;
            llMessageLinked(LINK_ROOT,0,"User "+llGetUsername(temp)+" blacklisted.",MESSAGE);
            checkBlacklist(temp);
        }
        else if(llKey2Name(temp))
        {
            blacklist+=temp;
            string name=llKey2Name(temp);
            if(llStringLength(name)>21) name=llDeleteSubString(name,21,-1);
            blacklistNames+=name;
            llMessageLinked(LINK_ROOT,0,"Object "+llKey2Name(temp)+" blacklisted.",MESSAGE);
            checkBlacklist(temp);
        }
        else
        {
            pendingBlacklist+=temp;
            pendingBlacklistDB+=llRequestUsername(temp);
            dataserverTimeout+=5;
        }
    }
}
addToBlacklistDirect(key temp)
{
    if(~llListFindList(blacklist,[temp])) llMessageLinked(LINK_ROOT,0,"Already Blacklisted",MESSAGE);
    else
    {
        if(llGetUsername(temp))
        {
            blacklist+=temp;
            string uname=llGetUsername(temp);
            if(llStringLength(uname)>21) uname=llDeleteSubString(uname,21,-1);
            blacklistNames+=uname;
            llMessageLinked(LINK_ROOT,0,"User "+llGetUsername(temp)+" blacklisted.",MESSAGE);
            checkBlacklist(temp);
        }
        else if(llKey2Name(temp))
        {
            blacklist+=temp;
            string name=llKey2Name(temp);
            if(llStringLength(name)>21) name=llDeleteSubString(name,21,-1);
            blacklistNames+=name;
            llMessageLinked(LINK_ROOT,0,"Object "+llKey2Name(temp)+" blacklisted.",MESSAGE);
            checkBlacklist(temp);
        }
        else
        {
            pendingBlacklist+=temp;
            pendingBlacklistDB+=llRequestUsername(temp);
            dataserverTimeout+=5;
        }
    }
}
removeFromBlacklist(integer index)
{
    llMessageLinked(LINK_ROOT,0,llList2String(blacklistNames,index)+" removed from blacklist",MESSAGE);
    blacklist=llDeleteSubList(blacklist,index,index);
    blacklistNames=llDeleteSubList(blacklistNames,index,index);
}
removeFromBlacklistDirect(string temp)
{
    if((key)temp)
    {
        integer working=1;
        while(working)
        {
            working=0;
            integer index=llListFindList(blacklist,[temp]);
            if(~index)
            {
                llMessageLinked(LINK_ROOT,0,llList2String(blacklistNames,index)+" removed from blacklist",MESSAGE);
                blacklist=llDeleteSubList(blacklist,index,index);
                blacklistNames=llDeleteSubList(blacklistNames,index,index);
                working=1;
            }
        }
    }
    else
    {
        integer working=1;
        while(working)
        {
            working=0;
            integer index=llListFindList(blacklistNames,[temp]);
            if(~index)
            {
                llMessageLinked(LINK_ROOT,0,llList2String(blacklistNames,index)+" removed from blacklist",MESSAGE);
                blacklist=llDeleteSubList(blacklist,index,index);
                blacklistNames=llDeleteSubList(blacklistNames,index,index);
                working=1;
            }
        }
    }
}
setControllers() // Clears !x-whos that don't matter
{
    if(controllers==NULL_LIST)
    {
        whoAcceptedKeys=NULL_LIST;
        return;
    }
    else if(whoAcceptedKeys!=NULL_LIST)
    {
        integer x;
        while(x<llGetListLength(whoAcceptedKeys))
        {
            integer index=llListFindList(controllers,llList2List(whoAcceptedKeys,x,x));
            if(index==-1) whoAcceptedKeys=llDeleteSubList(whoAcceptedKeys,x,x+1);
            x+=2;
        }
    }
}
clearWhoKey()
{
    if(whoAcceptedKeys!=NULL_LIST)
    {
        integer index=llListFindList(whoAcceptedKeys,[newObject]);
        if(~index) whoAcceptedKeys=llDeleteSubList(whoAcceptedKeys,index,index+1);
    }
}
processQueue()
{
    while(queue!=NULL_LIST && askTimeout==-1)
    {
        //if(DEBUG) llMessageLinked(LINK_ROOT,0,"Queue: "+llList2CSV(queue),MESSAGE);
        newObject=llList2Key(queue,0);
        commandList=llCSV2List(llList2String(queue,1));
        newCommands=llList2String(commandList,0);
        newRestrictions=llParseString2List(llList2String(commandList,2),RLV_PARSE,NULL_LIST);
        if(~llListFindList(pendingBlacklist,[newObject]))
        {  //Blacklisted items are silently dropped
            rejectObject(0);
        }
        else if(~llListFindList(pendingBlacklist,llGetObjectDetails(newObject,[OBJECT_OWNER])))
        {  //Blacklisted owner's items are silently dropped
            rejectObject(0);
        }
        else if(~llListFindList(blacklist,[newObject]))
        {  //Blacklisted items are silently dropped
            rejectObject(0);
        }
        else if(~llListFindList(blacklist,llGetObjectDetails(newObject,[OBJECT_OWNER])))
        {  //Blacklisted owner's items are silently dropped
            rejectObject(0);
        }
        else if(rejectedObject!=newObject)
        {  //Checks the denied object first
    //        if(llGetListLength(handoverObjects))
    //        {  // If there's objects in handover Queue (which this should never happen but in case of a rare instance where more than one object calls !x-handover at the same time)
    //            if(~llListFindList(handoverObjects,[newObject]))
    //            {
    //                acceptObject();
    //                return;
    //            }
    //        }
            integer working=1;
            while(working)
            {  // Notice the use of temp vars to cut down cpu
                //if(DEBUG) llMessageLinked(LINK_ROOT,0,"MetaChecking,"+(string)newObject+","+llList2CSV(newRestrictions),MESSAGE);
                working=0;
                metaFind=llParseString2List(llList2String(newRestrictions,0),ORG_PARSE,NULL_LIST);
                string metaCommand=llList2String(metaFind,0);
//                    if(metaCommand=="!x-delay")
//                    {
//                        llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+","+llDumpList2String(llDeleteSubList(newRestrictions,0,x-1),"|"),newObject);
//                        newRestrictions=llDeleteSubList(newRestrictions,x,-1);
//                        updateQueue();
//                        else
//                        {
//                            queue=llDeleteSubList(queue,0,1);
//                            return;
//                        }
//                    }
                if(metaCommand=="!x-who")
                {
                    if(llList2String(metaFind,1)=="clear") clearWhoKey();
                    else
                    {
                        whoKey=llList2Key(metaFind,1);
                        if(~llListFindList(pendingBlacklist,[whoKey]))
                        {  // Always check Blacklist first
                            rejectObject(2);
                        }  // And deny that user
                        if(~llListFindList(blacklist,[whoKey]))
                        {
                            rejectObject(2);
                        }
                        else if(llListFindList(whoAcceptedKeys,[whoKey])==-1)
                        {  // If a new Who, ask about it
                            if(relayMode<2)
                            {
                                if(llGetUsername(whoKey)) llMessageLinked(LINK_ROOT,0,llGetUsername(whoKey)+" wants to take control of your viewer using "+llKey2Name(newObject),MESSAGE);
                                else llMessageLinked(LINK_ROOT,0,"An unknown user wants to take control of your viewer using "+llKey2Name(newObject),MESSAGE);
                                llMessageLinked(LINK_ROOT,0,"Asking",whoKey);
                                newRestrictions=llDeleteSubList(newRestrictions,0,0);
                                updateQueue();
                                askTimeout=60;
                                return;
                            }
                            else
                            {
                                whoAcceptedKeys+=[newObject,whoKey];
                                acceptObject();
                            }
                        }
                        else
                        {
                            integer index=llListFindList(whoAcceptedKeys,[newObject]);
                            if(index==-1) whoAcceptedKeys+=[newObject,whoKey];
                            acceptObject();
                        }
                    }
                }
                else if(metaCommand=="!release")
                {
                    llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+",!release",newObject);
                    newRestrictions=llDeleteSubList(newRestrictions,0,0);
                    updateQueue();
                    working=1;
                }
                else if(metaCommand=="!version")
                {
                    llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+",!version",newObject);
                    newRestrictions=llDeleteSubList(newRestrictions,0,0);
                    updateQueue();
                    working=1;
                }
                else if(metaCommand=="!implversion")
                {
                    llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+",!implversion",newObject);
                    newRestrictions=llDeleteSubList(newRestrictions,0,0);
                    updateQueue();
                    working=1;
                }
                else if(metaCommand=="!x-orgversions")
                {
                    llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+",!x-orgversions",newObject);
                    newRestrictions=llDeleteSubList(newRestrictions,0,0);
                    updateQueue();
                    working=1;
                }
                else if(metaCommand=="!x-mode")
                {
                    llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+",!x-mode",newObject);
                    newRestrictions=llDeleteSubList(newRestrictions,0,0);
                    updateQueue();
                    working=1;
                }
                else if(!llSubStringIndex(metaCommand,"@version"))
                {
                    llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+","+llList2String(newRestrictions,0),newObject);
                    newRestrictions=llDeleteSubList(newRestrictions,0,0);
                    updateQueue();
                    working=1;
                }
                if(newRestrictions==NULL_LIST) working=0;
            }
            if(relayMode>1)
            {  //Auto Mode
                permittedObject=newObject;
                acceptTimeout=10;
                acceptObject();
            }
            else if(permittedObject==newObject)
            {  // Objects permitted are given 10 seconds to do restrictions before having to ask again
                acceptObject();
            }
            else if(~llListFindList(controllers,[(string)newObject]))
            {  // If there's objects active
                acceptObject();
            }
            else if(relayMode==1)
            {  //Semi Auto Mode (allows =force and =number)
                integer working=1;
                while(working)
                {
                    working=0;
                    string commandString=llList2String(newRestrictions,0);
                    string commandType=llGetSubString(commandString,llSubStringIndex(commandString,"=")+1,-1);
                    if(commandType=="force")
                    {
                        llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+","+commandString,newObject);
                        newRestrictions=llDeleteSubList(newRestrictions,0,0);
                        updateQueue();
                        working=1;
                    }
                    else if((integer)commandType)
                    {
                        llMessageLinked(primRelay,1,newCommands+","+(string)ownerKey+","+commandString,newObject);
                        newRestrictions=llDeleteSubList(newRestrictions,0,0);
                        updateQueue();
                        working=1;
                    }
                    else if(commandType=="0")
                    {
                        llMessageLinked(primRelay,0,newCommands+","+(string)ownerKey+","+commandString,newObject);
                        newRestrictions=llDeleteSubList(newRestrictions,0,0);
                        updateQueue();
                        working=1;
                    }
                    else if(commandType=="y" || commandType=="rem")
                    {
                        newRestrictions=llDeleteSubList(newRestrictions,0,0);
                        updateQueue();
                        working=1;
                    }
                }
            }
            //Filter for Spec Compliance
            if(newRestrictions!=NULL_LIST)
            {
                integer working=1;
                while(working)
                {
                    working=0;
                    string commandString=llList2String(newRestrictions,0);
                    string commandType=llGetSubString(commandString,llSubStringIndex(commandString,"=")+1,-1);
                    if(commandType=="y" || commandType=="rem")
                    {
                        newRestrictions=llDeleteSubList(newRestrictions,0,0);
                        updateQueue();
                        working=1;
                    }
                }
            }
            //Ask Mode operation
            if(newRestrictions!=NULL_LIST)
            {
                if(llGetOwnerKey(newObject)==ownerKey) llMessageLinked(LINK_ROOT,0,"Your "+llKey2Name(newObject)+" wants to take control of your viewer.",MESSAGE);
                else if(llGetUsername(llGetOwnerKey(newObject))) llMessageLinked(LINK_ROOT,0,llGetUsername(llGetOwnerKey(newObject))+"'s "+llKey2Name(newObject)+" wants to take control of your viewer.",MESSAGE);
                else llMessageLinked(LINK_ROOT,0,llKey2Name(newObject)+" wants to take control of your viewer.",MESSAGE);
                llMessageLinked(LINK_ROOT,0,"Asking",newObject);
                askTimeout=60;
                return;
            }
        }
        else
        {   //Rejected objects are ko'ed
            rejectObject(1);
        }
        if(newRestrictions==NULL_LIST) queue=llDeleteSubList(queue,0,1);
        //if(queue!=NULL_LIST && llList2Key(queue,0)=="") queue=llDeleteSubList(queue,0,1);
        //if(DEBUG) llMessageLinked(LINK_ROOT,0,"Queue, "+llList2CSV(queue),MESSAGE);
    }
}
rejectObject(integer denied)
{
    integer x;
    key reject=llList2Key(queue,0);
    if(denied==2) //Cancelling x-who
    {
        llMessageLinked(primRelay,0,llList2String(queue,1),reject);
        queue=llDeleteSubList(queue,0,1);
    }
    else
    { //Flushes rejects from the queue
        while(x<llGetListLength(queue))
        {
            if(llList2Key(queue,x)==rejectedObject)
            {
                if(denied) llMessageLinked(primRelay,0,llList2String(queue,x+1),rejectedObject);
                queue=llDeleteSubList(queue,x,x+1);
            }
            else if(llList2Key(queue,x)==reject)
            {
                if(denied) llMessageLinked(primRelay,0,llList2String(queue,x+1),reject);
                queue=llDeleteSubList(queue,x,x+1);
            }
            x+=2;
        }
    }
    newRestrictions=NULL_LIST;
    askTimeout=-1;
}
acceptObject()
{
    integer x;
    while(x<llGetListLength(queue))
    {
        if(llList2Key(queue,x)==newObject)
        {
            llMessageLinked(primRelay,1,llList2String(queue,x+1),newObject);
            queue=llDeleteSubList(queue,x,x+1);
        }
        x+=2;
    }
    newRestrictions=NULL_LIST;
    askTimeout=-1;
}
default
{
    state_entry()
    {
        init();
        startupMemory=llGetUsedMemory();
        //if(DEBUG) llMessageLinked(LINK_ROOT,0,"Memory Usage: "+(string)(startupMemory/1024)+"kb",MESSAGE);
    }
    on_rez(integer r)
    {
        init();
    }
    link_message(integer linkset, integer number, string message, key id)
    {
        if(linkset==LINK_ROOT)
        {
            if(message=="Yes")
            {
                askTimeout=-1;
                integer v=0;
                acceptTimeout=10;
                permittedObject=id;
                newObject=llList2Key(queue,0);
                if(whoKey==id)
                {
                    integer index=llListFindList(whoAcceptedKeys,[newObject]);
                    if(~index) whoAcceptedKeys=llList2List(whoAcceptedKeys,0,index)+[newObject]+llList2List(whoAcceptedKeys,index+2,-1);
                    else whoAcceptedKeys+=[newObject,whoKey];
                }
                acceptObject();
                if(queue!=NULL_LIST) processQueue();
            }
            else if(message=="No")
            {
                askTimeout=-1;
                rejectTimeout=10;
                rejectedObject=id;
                rejectObject(1);
                if(queue!=NULL_LIST) processQueue();
            }
            else if(message=="Blacklist")
            {
                if(id==WILDCARD)
                {
                    llMessageLinked(LINK_ROOT,1,"BlackLight",NULL_KEY);
                    setMenu();
                }
                else
                {
                    askTimeout=-1;
                    rejectTimeout=10;
                    rejectedObject=id;
                    addToBlacklistDirect(id);
                    rejectObject(0);
                    if(queue!=NULL_LIST) processQueue();
                }
            }
            else if(message=="SetMode") relayMode=number;
            else if(message=="PowerOn") powerOn();
            else if(message=="CheckBlacklist")
            {
                if(~llListFindList(blacklist,[id])) llMessageLinked(LINK_ROOT,0,"Blacklisted",id);
                else llMessageLinked(LINK_ROOT,0,"NotBlacklisted",id);
            }
        }
        else if(linkset==primRelay)
        {
            if(!llSubStringIndex(message,"Controllers, "))
            {
                //if(DEBUG) llMessageLinked(LINK_ROOT,0,"Caught Controllers",MESSAGE);
                if(id==NULL_KEY) //Just in case
                {
                    controllers=llDeleteSubList(llCSV2List(message),0,0);
                    //if(DEBUG) llMessageLinked(LINK_ROOT,0,"Set Controllers",MESSAGE);
                    setControllers();
                }
            }
//            else if(message=="HandoverObject")
//            {
//                handoverObjects+=id;
//                handoverTimeout=60;
//            }
            else if(message=="PowerOn") powerOn();
            else if(power)
            {
                if(message=="PowerOff") powerOff();
                else
                {
                    if(llGetUsedMemory()<MEMORY_LIMIT)
                    {
                        if(queue==NULL_LIST)
                        {
                            queue+=[id,message];
                            processQueue();
                        }
                        else queue+=[id,message];
                    }
                    else
                    {
                        llMessageLinked(primRelay,0,message,id);
                    }
                }
            }
        }
    }
    listen(integer channel, string name , key id, string message)
    {
        if(channel==menuChannel)
        {
            if(message=="<--")
            {
                if(menuPage<3 || menuPage==8) menuPage=0;
                else if(menuPage<6) menuPage=1;
                else menuPage=2;
                doMenu();
            }
            else if(!menuPage)
            {
                if(message=="Add")
                {
                    menuPage=1;
                    doMenu();
                }
                else if(message=="List")
                {
                    llMessageLinked(LINK_ROOT,0,"Blacklist\n----------------",MESSAGE);
                    integer x=~llGetListLength(blacklistNames);
                    while(++x)
                    {
                        llMessageLinked(LINK_ROOT,0,llList2String(blacklistNames,x)+", "+llList2String(blacklist,x),MESSAGE);
                    }
                    doMenu();
                }
                else if(message=="Remove")
                {
                    menuPage=2;
                    doMenu();
                }
                else if(message=="Set Mode")
                {
                    menuPage=8;
                    doMenu();
                }
                else if(message=="Turn Off")
                {
                    llMessageLinked(primRelay,0,"PowerOff",NULL_KEY);
                    closeMenu();
                }
                else if(message=="Exit") closeMenu();
            }
            else if(menuPage==1)
            {
                if(message=="Input")
                {
                    menuPage=3;
                    doMenu();
                }
                else if(message=="Scan User")
                {
                    menuPage=4;
                    llSensor("","",AGENT,20.0,PI);
                }
                else if(message=="Scan Object")
                {
                    menuPage=5;
                    llSensor("","",SCRIPTED,20.0,PI);
                }
            }
            else if(menuPage==2)
            {
                if(message=="Input")
                {
                    menuPage=6;
                    doMenu();
                }
                else if(message=="Select")
                {
                    menuPage=7;
                    doMenu();
                }
            }
            else if(menuPage==3)
            {
                if(message)
                {
                    list pending=llParseString2List(message,[",","\n"],[" "]);
                    integer x=~llGetListLength(pending);
                    while(++x)
                    {
                        addToBlacklistDirect(llList2Key(pending,x));
                    }
                }
                menuPage=1;
                doMenu();
                
            }
            else if(menuPage==4 || menuPage==5)
            {
                if(message=="<<")
                {
                    listPage--;
                    doMenu();
                }
                else if(message==">>")
                {
                    listPage++;
                    doMenu();
                }
                else
                {
                    integer index=(integer)llDeleteSubString(message,llSubStringIndex(message,":"),-1);
                    if(~index) addToBlacklist(index);
                    else llMessageLinked(LINK_ROOT,0,message+" not found",MESSAGE);
                    menuPage=1;
                    doMenu();
                }
            }
            else if(menuPage==6)
            {
                if(message)
                {
                    list pending=llParseString2List(message,[",","\n"],[" "]);
                    integer x=~llGetListLength(pending);
                    while(++x)
                    {
                        removeFromBlacklistDirect(llList2String(pending,x));
                    }
                }
                menuPage=2;
                doMenu();
            }
            else if(menuPage==7)
            {
                if(message=="<<")
                {
                    listPage--;
                    doMenu();
                }
                else if(message==">>")
                {
                    listPage++;
                    doMenu();
                }
                else
                {
                    integer index=(integer)llDeleteSubString(message,llSubStringIndex(message,":"),-1);
                    if(~index) removeFromBlacklist(index);
                    else llMessageLinked(LINK_ROOT,0,message+" not found",MESSAGE);
                    menuPage=2;
                    doMenu();
                }
            }
            else if(menuPage==8)
            {
                if(message=="Ask Mode") relayMode=0;
                else if(message=="Semi Auto") relayMode=1;
                else if(message=="Automatic") relayMode=2;
                else if(message=="Full Auto") relayMode=3;
                llMessageLinked(LINK_ALL_OTHERS,relayMode,"SetMode",NULL_KEY);
                menuPage=0;
                doMenu();
            }
        }
    }
    dataserver(key queryid, string data)
    {
        integer index=llListFindList(pendingBlacklistDB,[queryid]);
        if(~index)
        {
            if(~llListFindList(blacklist,llList2List(pendingBlacklist,index,index)))
            {
                blacklist+=llList2List(pendingBlacklist,index,index);
                string uname=data;
                if(llStringLength(uname)>21) uname=llDeleteSubString(uname,21,-1);
                blacklistNames+=uname;
                llMessageLinked(LINK_ROOT,0,"User "+data+" added to blacklist",MESSAGE);
                checkBlacklist(llList2Key(pendingBlacklist,index));
            }
            else llMessageLinked(LINK_ROOT,0,"Already Blacklisted",MESSAGE);
            pendingBlacklist=llDeleteSubList(pendingBlacklist,index,index);
            pendingBlacklistDB=llDeleteSubList(pendingBlacklistDB,index,index);
        }
    }
    timer()
    {
        if(!askTimeout)
        {
            llMessageLinked(LINK_ROOT,0,"Timeout",NULL_KEY);
            rejectedObject=llList2String(queue,0);
            rejectObject(1);
            llSleep(0.5);
            rejectedObject=NULL_KEY; // Patch to allow a new relay request from this object. It was not blacklisted -Aria
            if(queue!=NULL_LIST) processQueue();
        }
        if(~askTimeout) askTimeout--;
        //else if(queue!=NULL_LIST) processQueue();
        if(~menuTimeout) menuTimeout--;
        if(!menuTimeout) closeMenu();
        if(~rejectTimeout) rejectTimeout--;
        if(!rejectTimeout) rejectedObject=NULL_KEY;
        if(~acceptTimeout) acceptTimeout--;
        if(!acceptTimeout) permittedObject=NULL_KEY;
//        if(~handoverTimeout) handoverTimeout--;
//        if(!handoverTimeout) handoverObjects=NULL_LIST;
        if(~dataserverTimeout) dataserverTimeout--;
        if(!dataserverTimeout)
        {
            if(pendingBlacklistDB!=NULL_LIST)
            {
                if(llGetListLength(pendingBlacklist)==1) llMessageLinked(LINK_ROOT,0,llList2String(pendingBlacklist,0)+" may not be a valid user or the SL database timed out.",MESSAGE);
                else llMessageLinked(LINK_ROOT,0,"The following UUIDs may not be valid users or the SL database timed out:\n"+llDumpList2String(pendingBlacklist,"\n"),MESSAGE);
            }
            pendingBlacklist=NULL_LIST;
            pendingBlacklistDB=NULL_LIST;
        }
    }
    run_time_permissions(integer permissions)
    {
        if(PERMISSION_TAKE_CONTROLS & permissions) 
        {
            if(!(llGetAgentInfo(ownerKey) & AGENT_ON_OBJECT)) llTakeControls(CONTROL_ML_LBUTTON | 0,FALSE,TRUE);
        }
    }
    changed (integer change)
    {
        if(change & CHANGED_OWNER) llResetScript();
        if(change & CHANGED_LINK) setPrims();
    }
    sensor(integer total)
    {
        scannedKeys=NULL_LIST;
        scannedNames=NULL_LIST;
        integer x=-1;
        while(++x<total)
        {
            scannedKeys+=llDetectedKey(x);
            if(menuPage==4)
            {
                string uname=llGetUsername(llDetectedKey(x));
                if(llStringLength(uname)>21) uname=llDeleteSubString(uname,21,-1);
                scannedNames+=uname;
            }
            else
            {
                string name=llDetectedName(x);
                if(llStringLength(name)>21) name=llDeleteSubString(name,21,-1);
                scannedNames+=name;
            }
        }
        listPage=1;
        doMenu();
    }
    no_sensor()
    {
        menuPage=1;
        doMenu();
    }
}
