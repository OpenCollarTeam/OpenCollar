/*
This file is a part of OpenCollar.
Copyright 2020

: Contributors :
Aria (Tashia Redrose)
    * Mar 2020      - Wrote Turbo Relay plugin for OpenCollar compatibility

et al.

Licensed under the GPLv2. See LICENSE for full details.
https://github.com/OpenCollarTeam/OpenCollar
*/

integer CMD_RELAY = 507;
string MSG;
key g_kAsking;
integer g_iMode;

default
{
    on_rez(integer iNum){
        llResetScript();
    }
    state_entry(){
        llOwnerSay("Initializing Relay!\nDownloading settings from collar (if worn)");
        llListen(CMD_RELAY, "", "", "");
        llSay(CMD_RELAY, llList2Json(JSON_OBJECT, ["type", "connect", "cmd", "download"]));
    }
    
    listen(integer iChan, string sName, key kID, string sMsg){
        if(llGetOwnerKey(kID)!=llGetOwner())return;
        
        if(llJsonGetValue(sMsg,["type"]) == "none"){
            if(llJsonGetValue(sMsg, ["cmd"])=="CONNECT"){
                llSay(CMD_RELAY, llList2Json(JSON_OBJECT, ["type", "connect", "cmd", "download"]));
            } else if(llJsonGetValue(sMsg, ["cmd"])=="safeword"){
                // Safeword!
                llMessageLinked(LINK_SET, 0, "Safety!", "ffffffff-ffff-ffff-ffff-ffffffffffff");
            }
        } else if(llJsonGetValue(sMsg, ["type"]) == "mode"){
            if(llJsonGetValue(sMsg, ["cmd"]) == "set"){
                integer val = (integer)llJsonGetValue(sMsg,["value"]);
                if(g_iMode==val)return;
                if(val == -1){
                    // power off
                    llMessageLinked(LINK_SET, 0, "PowerOff", "");
                    
                } else if(val > -1){
                    // power on, and set mode
                    llMessageLinked(LINK_SET, 0, "PowerOn", "");
                    llMessageLinked(LINK_SET, val, "SetMode", "");
                }
            }
        } else if(llJsonGetValue(sMsg, ["type"]) == "prompt_reply"){
            if(llJsonGetValue(sMsg, ["answer"]) == "y"){
                llMessageLinked(LINK_SET, 0, "Yes", g_kAsking);
                g_kAsking=NULL_KEY;
                MSG="";
            } else if(llJsonGetValue(sMsg, ["answer"]) == "n"){
                llMessageLinked(LINK_SET, 0, "No", g_kAsking);
                g_kAsking=NULL_KEY;
                MSG="";
            } else if(llJsonGetValue(sMsg, ["answer"])=="b"){
                llMessageLinked(LINK_SET, 0, "Blacklist", g_kAsking);
                g_kAsking=NULL_KEY;
                MSG="";
            }
        }
    }
    
    link_message(integer iSender, integer iNum, string sStr, key kID){
        if(kID == "Message"){
            MSG=sStr;
        }
        
        if(sStr == "Asking"){
            g_kAsking = kID;
            llSay(CMD_RELAY, llList2Json(JSON_OBJECT, ["type", "prompt", "cmd", "ask", "prompt", MSG]));
        }
    }
}
