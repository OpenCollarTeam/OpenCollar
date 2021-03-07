/*
This file is a part of OpenCollar.
Copyright 2021

: Contributors :

Aria (Tashia Redrose)
    * March 2021         - Rewrote oc_installer_Core

et al.


Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

integer g_iUpdateChan = -7483213;
integer g_iLegacyUpdateChannel = -7483214;

list g_lDSRequests;
key NULL=NULL_KEY;
UpdateDSRequest(key orig, key new, string meta){
    if(orig == NULL){
        g_lDSRequests += [new,meta];
    }else {
        integer index = HasDSRequest(orig);
        if(index==-1)return;
        else{
            g_lDSRequests = llListReplaceList(g_lDSRequests, [new,meta], index,index+1);
        }
    }
}

string GetDSMeta(key id){
    integer index=llListFindList(g_lDSRequests,[id]);
    if(index==-1){
        return "N/A";
    }else{
        return llList2String(g_lDSRequests,index+1);
    }
}

integer HasDSRequest(key ID){
    return llListFindList(g_lDSRequests, [ID]);
}

DeleteDSReq(key ID){
    if(HasDSRequest(ID)!=-1)
        g_lDSRequests = llDeleteSubList(g_lDSRequests, HasDSRequest(ID), HasDSRequest(ID)+1);
    else return;
}


integer MinorNew = 805000;

string UPDATE_VERSION = "";
string UPDATER_NAME;
string UPDATER_SUMMARY;

TurnOffNonInstaller()
{
    integer i=0;
    integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
    for(i=0;i<end;i++)
    {
        string name = llGetInventoryName(INVENTORY_SCRIPT, i);
        list lParts = llParseString2List(name, ["_"],[]);
        if(llList2String(lParts,0)=="oc" && llList2String(lParts,1)=="installer"){
            llSetScriptState(name, TRUE);
        }
        else{
            llSetScriptState(name,FALSE);
        }
    }
}
PermChecks()
{
    integer i=0;
    integer end = llGetInventoryNumber(INVENTORY_SCRIPT);
    for(i=0;i<end;i++)
    {

        string name = llGetInventoryName(INVENTORY_SCRIPT, i);
        list lParts = llParseString2List(name, ["_"],[]);

        if(llList2String(lParts,0)=="oc")
        {
            // only check permissions on opencollar originating scripts
            if(getperms(name)!="full"){
                llWhisper(0, "FATAL ERROR: "+name+" is not full perms and is a official OpenCollar script, it's permissions are currently: "+getperms(name)+". This is a violation of the OpenCollar license");
                g_iUpdater=FALSE;
            }

        }
    }
}

integer g_iUpdater=TRUE;
key g_kParticleTarget;
integer g_iRainbowCycle;
list l_ParticleColours=[<1,0,0>,<1.0,0.5,0>,<1,1,0>,<0,1,0>,<0,0.25,1>,<0.25,0,1>,<0.5,0,1>,<1,0,0>];
Particles(key kTarget) {
    g_kParticleTarget=kTarget;
    vector a=llList2Vector(l_ParticleColours,g_iRainbowCycle);
    vector b=llList2Vector(l_ParticleColours,g_iRainbowCycle+1);
    g_iRainbowCycle++;
    if(g_iRainbowCycle>6) g_iRainbowCycle=0;
    llParticleSystem([
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
            PSYS_SRC_BURST_RADIUS,0,
            PSYS_SRC_ANGLE_BEGIN,0.1,
            PSYS_SRC_ANGLE_END,-0.1,
            PSYS_SRC_TARGET_KEY,g_kParticleTarget,
            PSYS_PART_START_COLOR,a,
            PSYS_PART_END_COLOR,b,
            PSYS_PART_START_ALPHA,1,
            PSYS_PART_END_ALPHA,1,
            PSYS_PART_START_GLOW,0,
            PSYS_PART_END_GLOW,0,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<0.500000,0.500000,0.000000>,
            PSYS_PART_END_SCALE,<0.231000,0.231000,0.000000>,
            PSYS_SRC_TEXTURE,"50f9fb96-f1b5-6357-02b4-5585bc4cc55b",
            PSYS_SRC_MAX_AGE,0,
            PSYS_PART_MAX_AGE,2.9,
            PSYS_SRC_BURST_RATE,0.1,
            PSYS_SRC_BURST_PART_COUNT,5,
            PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.1,
            PSYS_SRC_BURST_SPEED_MAX,0.9,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_EMISSIVE_MASK |
                PSYS_PART_INTERP_COLOR_MASK |
                PSYS_PART_INTERP_SCALE_MASK |
                PSYS_PART_TARGET_POS_MASK
        ]);
        llSensorRepeat("*&^","6b4092ce-5e5a-ff2e-42e0-3d4c1a069b2f",AGENT,0.1,0.1,0.6);
}
integer TotalDone;
string getperms(string inventory)
{
    integer perm = llGetInventoryPermMask(inventory,MASK_NEXT);
    integer fullPerms = PERM_COPY | PERM_MODIFY | PERM_TRANSFER;
    integer copyModPerms = PERM_COPY | PERM_MODIFY;
    integer copyTransPerms = PERM_COPY | PERM_TRANSFER;
    integer modTransPerms = PERM_MODIFY | PERM_TRANSFER;
    string output = "";
    if ((perm & fullPerms) == fullPerms)
        output += "full";
    else if ((perm & copyModPerms) == copyModPerms)
        output += "copy & modify";
    else if ((perm & copyTransPerms) == copyTransPerms)
        output += "copy & transfer";
    else if ((perm & modTransPerms) == modTransPerms)
        output += "modify & transfer";
    else if ((perm & PERM_COPY) == PERM_COPY)
        output += "copy";
    else if ((perm & PERM_TRANSFER) == PERM_TRANSFER)
        output += "transfer";
    else
        output += "none";
    return  output;
}
integer g_iBundleNumber = 0;
key g_kUpdateTarget;
list GetBundleInformation()
{
    integer iTmp = 0;
    integer i=0;
    integer end = llGetInventoryNumber(INVENTORY_NOTECARD);
    for(i=0;i<end;i++){
        string name=llGetInventoryName(INVENTORY_NOTECARD,i);
        list lParts = llParseString2List(name,["_"],[]);
        if(llList2String(lParts,0)=="BUNDLE")
        {
            if(iTmp == g_iBundleNumber)return [name, llList2String(lParts,-1)];
            iTmp++;
        }
    }
    return [];
}

integer SECURE_CHANNEL;


float g_iTotalItems;


StatusBar(float fCount) {
    fCount = 100*(fCount/g_iTotalItems);
    if (fCount > 100) fCount = 100;
    string sCount = ((string)((integer)fCount))+"%";
    if (fCount < 10) sCount = "░░"+sCount;
    else if (fCount < 45) sCount = "░"+sCount;
    else if (fCount < 100) sCount = "█"+sCount;
    string sStatusBar = "░░░░░░░░░░░░░░░░░░░░";
    integer i = (integer)(fCount/5);
    do { i--;
        sStatusBar = "█"+llGetSubString(sStatusBar,0,-2);
    } while (i>0);
    llSetText(llGetSubString(sStatusBar,0,7)+sCount+llGetSubString(sStatusBar,12,-1), <1,1,0>, 1.0);
    //return llGetSubString(sStatusBar,0,7)+sCount+llGetSubString(sStatusBar,12,-1);
}
integer g_iUpdatePin;

integer g_iPromptChannel;
integer g_iPromptListen;
key g_kPrompt;
string g_sPrompt;
list g_lPrompt;

integer g_iPrompt_tmpLine;
key g_kPrompt_tmpID;
string g_sPrompt_tmpName;
string g_sCurrentOption;
key g_kRelay;
key g_kRelayTarget;


integer g_iUpdateRunning=FALSE;
key g_kCollar;
integer g_iLegacyUpdate = FALSE;

integer g_iProcessedDeprecation = FALSE;
default
{
    state_entry()
    {
        TurnOffNonInstaller();
        PermChecks();
        if(!g_iUpdater){
            return;
        }
        //llWhisper(0, "Installer is ready with "+(string)llGetFreeMemory()+"b");
        llListen(g_iUpdateChan, "", "", "");
        llListen(g_iLegacyUpdateChannel, "", "", "");
        UpdateDSRequest(NULL, llGetNotecardLine(".name",0), "read_name_card|0");
        llParticleSystem([]);
        //llWhisper(0, "Calculating the number of assets contained in bundles...");

        g_iBundleNumber=0;
        list lTmp = GetBundleInformation();
        UpdateDSRequest(NULL, llGetNumberOfNotecardLines(llList2String(lTmp,0)), "total_assets_count");
        llSetLinkPrimitiveParams(2,[PRIM_TEXT,"",ZERO_VECTOR,0]);
    }

    dataserver(key kID, string sData)
    {
        if(HasDSRequest(kID)!=-1)
        {
            string meta = GetDSMeta(kID);
            list lMeta = llParseStringKeepNulls(meta,["|"],[]);
            if(llList2String(lMeta,0) == "read_name_card")
            {
                if(sData==EOF)
                {
                    DeleteDSReq(kID);

                    llSetText(UPDATER_NAME+"\n"+UPDATER_SUMMARY, <1,1,1>, 1);
                    llSetObjectName(UPDATER_NAME+" - "+UPDATER_SUMMARY);

                    return;
                }
                integer iLine = (integer)llList2String(lMeta,1);
                iLine++;
                list lTmp = llParseString2List(sData,[" - ", "&"],[]);
                UPDATER_NAME = llList2String(lTmp,0);
                UPDATER_SUMMARY = llList2String(lTmp,1);
                UPDATE_VERSION = llList2String(lTmp,2);


                UpdateDSRequest(kID, llGetNotecardLine(".name", iLine), "read_name_card|"+(string)iLine);
            } else if(llList2String(lMeta,0) == "read_bundle")
            {
                string bundle_name = llList2String(lMeta,1);
                integer iLine = (integer)llList2String(lMeta,2);
                string sBundleType = llList2String(lMeta,3);
                if(sData==EOF){
                    DeleteDSReq(kID);
                    // attempt to move on!

                    if(g_iBundleNumber==0 && g_iProcessedDeprecation){
                        g_iBundleNumber=999;
                    }
                    if(g_iBundleNumber==0 && !g_iProcessedDeprecation)g_iProcessedDeprecation=1;

                    g_iBundleNumber++;
                    list lBundle = GetBundleInformation();
                    if(lBundle==[] && g_iProcessedDeprecation && g_iBundleNumber!=1000){
                        g_iBundleNumber=0;
                        lBundle=GetBundleInformation();
                    }

                    if(lBundle==[])
                    {

                        // update completed
                        llSensorRemove();
                        llRegionSayTo(g_kUpdateTarget, SECURE_CHANNEL, "DONE");
                        llParticleSystem([]);

                        llSetText("DONE!\n \n████████100%████████", <0,1,0>, 1.0);
                        llSetTimerEvent(0);
                        llResetScript();
                    }else{
                        // request next bundle
                        UpdateDSRequest(NULL, llGetNotecardLine(llList2String(lBundle,0),0), "read_bundle|"+llList2String(lBundle,0)+"|0|"+llList2String(lBundle,1));
                    }
                } else {
                    // Not end of file, do bundle processing action
                    iLine++;
                    list lParts = llParseString2List(sData,["|"],[]);
                    string sOpt = llList2String(lParts,0);
                    string sName = llList2String(lParts,1);
                    key kNameID = llGetInventoryKey(sName);
                    TotalDone ++;
                    StatusBar((float)TotalDone);

                    g_sCurrentOption = sOpt;

                    if(!g_iLegacyUpdate)
                        llRegionSayTo(g_kUpdateTarget, SECURE_CHANNEL, llDumpList2String([sOpt, sName, kNameID, sBundleType, kID, iLine], "|")); // change for v8 updater - supply the dataserver ID and line number, since it will be required in order to increment
                    else{
                        if(sOpt=="SCRIPT")llRemoteLoadScriptPin(g_kCollar,sName,g_iUpdatePin, TRUE,1);
                        else llGiveInventory(g_kCollar, sName);

                        UpdateDSRequest(kID, llGetNotecardLine(bundle_name, iLine), "read_bundle|"+bundle_name+"|"+(string)iLine+"|"+sBundleType);
                    }
                }
            } else if(llList2String(lMeta,0)=="total_assets_count"){
                if(g_iBundleNumber==0)g_iTotalItems+=(integer)sData; // Bundle 0 gets processed twice, at the beginning, then at the end!
                g_iBundleNumber++;
                list lTmp = GetBundleInformation();
                g_iTotalItems += (integer)sData;

                if(lTmp==[]){
                    llWhisper(0, "Installer is ready with "+(string)llGetFreeMemory()+"b");
                    DeleteDSReq(kID);
                }
                else{
                    UpdateDSRequest(kID, llGetNumberOfNotecardLines(llList2String(lTmp,0)), "total_assets_count");
                }
            }
        }
    }

    changed(integer iChange)
    {
        if(iChange&CHANGED_INVENTORY)
        {
            llResetScript();
        }
    }
    no_sensor()
    {
        Particles(g_kParticleTarget);
    }

    timer()
    {
        if(llGetTime()>= 30 && g_iPromptListen!=-1)
        {
            llResetTime();
            llDialog(g_kPrompt, g_sPrompt, g_lPrompt, g_iPromptChannel);
        }
    }

    listen(integer c,string n,key i,string m){
        if(c==g_iUpdateChan || c==g_iLegacyUpdateChannel){
            //llWhisper(0, "Collar message on update channel: "+m);
            list lParam = llParseString2List(m,["|"],[]);
            if(m == "UPDATE" && c==g_iLegacyUpdateChannel && llGetOwner() == llGetOwnerKey(i))
            {
                llSay(0, "Operating in Legacy Update Mode");
                // Legacy Update Signal
                llPlaySound("d023339f-9a9d-75cf-4232-93957c6f620c",1.0);
                g_iLegacyUpdate = TRUE;
                llRegionSayTo(i,c,"get ready");
                g_iTotalItems = 0;
                g_iBundleNumber=999;
                UpdateDSRequest(NULL, llGetNumberOfNotecardLines("LEGACY_00-Core_REQUIRED"), "total_assets_count");
                return;
            }
            if(llList2String(lParam,0)=="UPDATE")
            {
                integer Ver = (integer)llDumpList2String(llParseString2List(llList2String(lParam,1),["."],[]),"");

                llPlaySound("d023339f-9a9d-75cf-4232-93957c6f620c",1.0);
                if(Ver<MinorNew || llGetOwnerKey(i) == llGetOwner())
                {
                    if(llGetOwnerKey(i)!=llGetOwner()){
                        llSay(0, "Sorry, your version does not support being updated using someone else's updater.");
                        return;
                    }
                    // Do update using old method!
                    //llOwnerSay( "Sending response: -.. ---|"+UPDATE_VERSION+"|");
                    if(Ver < 80) llRegionSayTo(i,c,"-.. ---|AppInstall|"); // 75, 74, etc
                    else llRegionSayTo(i, c, "-.. ---|"+UPDATE_VERSION+"|");
                    g_iUpdateRunning=TRUE;
                } else {
                    // Perform distance check, The person must be within 5 meters of this object
                    if(llVecDist(llGetPos(), llList2Vector(llGetObjectDetails(i,[OBJECT_POS]),0))<=5){


                        g_iUpdateRunning=TRUE;
                        g_kRelayTarget = i;
                        //llSay(0, "Using New Update style");
                        //llSay(0, "Send: [oc_installer_relay]");
                        llGiveInventory(i, "oc_installer_relay");

                        llRegionSayTo(i,c,"UPDATER RELAY");
                    }
                }
            } else if(llList2String(lParam,0) == "ready")
            {
                //llWhisper(0, "Collar installation pin code: "+llList2String(lParam,1)+"\n \n[Send: oc_update_shim]");
                if(!g_iLegacyUpdate){
                    g_kCollar = i;
                    g_iUpdatePin = (integer)llList2String(lParam,1);
                    llRemoteLoadScriptPin(i, "oc_update_shim", g_iUpdatePin, TRUE, 0); // 0 = from installer itself, 1 = from relay orb.
                }else{
                    // Do bundle!
                    g_iBundleNumber=999;
                    g_kCollar=i;
                    g_iUpdatePin = (integer)llList2String(lParam,1);
                    UpdateDSRequest(NULL, llGetNotecardLine("LEGACY_00-Core_REQUIRED",0), "read_bundle|LEGACY_00-Core_REQUIRED|0|REQUIRED");
                }
            } else if(llList2String(lParam,0)=="reallyready" && g_iUpdateRunning)
            {
                g_kUpdateTarget=i;
                SECURE_CHANNEL = (integer)llList2String(lParam,1);
                llListen(SECURE_CHANNEL, "", i, "");
                //llSay(0, "Now listening on the secure updater channel");
                //llSay(0, "Initiate particles");
                Particles(g_kUpdateTarget);
                //llSay(0, "Begin reading Bundles");
                g_iBundleNumber=0;
                list lBundleInf = GetBundleInformation();
                UpdateDSRequest(NULL, llGetNotecardLine(llList2String(lBundleInf,0),0), "read_bundle|"+llList2String(lBundleInf,0)+"|0|"+llList2String(lBundleInf,1)); // read_bundle|bundle_name|line_number|bundle_type
            } else if(llList2String(lParam,0) == "AnnounceRelay" && g_iUpdateRunning)
            {
                //llSay(0, "Asking relay to prepare");
                g_kRelay= i;
                llRegionSayTo(i, c+1, "PrepareRelay");
            } else if(llList2String(lParam,0) == "ReallyRelayReady" && g_iUpdateRunning)
            {
                //llSay(0, "Relay is ready to enter stage 2");
                //llSay(0, "Sending shim to relay");
                llGiveInventory(g_kRelay, "oc_update_shim");
                llRegionSayTo(g_kRelay, g_iUpdateChan+1, "ShimSent|"+(string)g_kRelayTarget+"|"+UPDATE_VERSION);
                // We do not yet have the collar's update pin. The relay will obtain this information so it can install the shim and get things moving!
            }
        }else if(c==SECURE_CHANNEL)
        {
            //llSay(0, "Message from shim on secure channel: "+m);
            list lOpt = llParseString2List(m,["|"],[]);
            if(llList2String(lOpt,0) == "SKIP")
            {
                // do nothing, we'll read next option down below
            } else if(llList2String(lOpt,0) == "GIVE")
            {
                llGiveInventory(i, llList2String(lOpt,1));
                //llWhisper(0, "Shim requested installation of: "+llList2String(lOpt,1));
                if(g_kRelay)llRegionSayTo(g_kRelay, g_iUpdateChan+1, "Send|GIVE|"+llList2String(lOpt,1));
            } else if(llList2String(lOpt,0) == "INSTALL")
            {
                if(g_kRelay=="")
                    llRemoteLoadScriptPin(i, llList2String(lOpt,1), g_iUpdatePin,TRUE, 1);
                else
                    llGiveInventory(i, llList2String(lOpt,1));

                if(g_kRelay)llRegionSayTo(g_kRelay, g_iUpdateChan+1, "Send|INSTALL|"+llList2String(lOpt,1));
            } else if(llList2String(lOpt,0) == "INSTALLSTOPPED")
            {
                if(g_kRelay=="")
                    llRemoteLoadScriptPin(i, llList2String(lOpt,1), g_iUpdatePin,FALSE,1);
                else
                    llGiveInventory(i, llList2String(lOpt,1));

                if(g_kRelay)llRegionSayTo(g_kRelay, g_iUpdateChan+1, "Send|INSTALLSTOPPED|"+llList2String(lOpt,1));
            } else if(llList2String(lOpt,0) == "PROMPT_INSTALL")
            {
                if(g_iPromptListen != -1)llListenRemove(g_iPromptListen);
                g_iPromptChannel = llRound(llFrand(4832999));
                g_iPromptListen = llListen(g_iPromptChannel, "", llGetOwnerKey(i), "");
                g_kPrompt = llGetOwnerKey(i);
                llResetTime();
                g_sPrompt="[OpenCollar Installer]\n \nCurrent Item: "+llList2String(lOpt,1)+"\n\nThis item is not currently installed. It is optional, would you like to install this script?\n\n* Do not use the ignore button, installation cannot proceed without a response";
                g_lPrompt = ["Install", "Skip"];
                llDialog(llGetOwnerKey(i), g_sPrompt, g_lPrompt, g_iPromptChannel);
                g_kPrompt_tmpID = (key)llList2String(lOpt,2);
                g_iPrompt_tmpLine = (integer)llList2String(lOpt,3);
                g_sPrompt_tmpName = llList2String(lOpt,1);
                llSetTimerEvent(1);
                return; // intentionally exit here
            } else if(llList2String(lOpt,0)=="PROMPT_REMOVE")
            {

                if(g_iPromptListen != -1)llListenRemove(g_iPromptListen);
                g_iPromptChannel = llRound(llFrand(4832999));
                g_iPromptListen = llListen(g_iPromptChannel, "", llGetOwnerKey(i), "");
                g_kPrompt = llGetOwnerKey(i);
                llResetTime();
                g_sPrompt="[OpenCollar Installer]\n \nCurrent Item: "+llList2String(lOpt,1)+"\n\nThis item is currently installed. It is optional, would you like to uninstall this script?\n\n* Do not use the ignore button, installation cannot proceed without a response";
                g_lPrompt = ["Remove", "Skip"];
                llDialog(llGetOwnerKey(i), g_sPrompt, g_lPrompt, g_iPromptChannel);
                g_kPrompt_tmpID = (key)llList2String(lOpt,2);
                g_iPrompt_tmpLine = (integer)llList2String(lOpt,3);
                g_sPrompt_tmpName = llList2String(lOpt,1);
                llSetTimerEvent(1);
                return; // intentionally exit here
            } else {
                //llSay(0, "Unimplemented command: "+llList2String(lOpt,0)+"; "+llList2String(lOpt,1));
            }


            string meta = GetDSMeta((key)llList2String(lOpt,2));
            list lMeta = llParseString2List(meta,["|"],[]);
            lMeta = llListReplaceList(lMeta,[llList2String(lOpt,3)],2,2);
            UpdateDSRequest((key)llList2String(lOpt,2), llGetNotecardLine(llList2String(lMeta,1), (integer)llList2String(lMeta,2)), llDumpList2String(lMeta,"|"));
        } else if(c == g_iPromptChannel)
        {
            // continue;
            if(g_iPromptListen!=-1){
                llListenRemove(g_iPromptListen);
                g_iPromptListen=-1;
                llSetTimerEvent(0);

                if(m == "Skip"){}
                else if(m == "Install" || m == "Remove")
                {
                    string type = "REQUIRED";
                    if(m == "Remove")type="DEPRECATED";
                    llRegionSayTo(g_kUpdateTarget, SECURE_CHANNEL, llDumpList2String([g_sCurrentOption, g_sPrompt_tmpName, llGetInventoryKey(g_sPrompt_tmpName), type, g_kPrompt_tmpID, g_iPrompt_tmpLine], "|")); // copied from the dataserver code
                    return;
                }

                string meta = GetDSMeta(g_kPrompt_tmpID);
                list lMeta = llParseString2List(meta,["|"],[]);
                lMeta = llListReplaceList(lMeta,[g_iPrompt_tmpLine],2,2);
                UpdateDSRequest(g_kPrompt_tmpID, llGetNotecardLine(llList2String(lMeta,1), (integer)llList2String(lMeta,2)), llDumpList2String(lMeta,"|"));
            }
        }
    }
}
