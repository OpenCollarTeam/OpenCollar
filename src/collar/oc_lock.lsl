 /*

 Copyright (c) 2017 virtualdisgrace.com

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. 
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

// This plugin is the tiny steam-engine behind the LOCK/UNLOCK button
// that lives in the oc_root. It can play different noises depending on
// lock/unlock action and reveal or hide a lock element on the device.
 
integer CMD_OWNER = 500;
integer CMD_WEARER = 503;
integer NOTIFY = 1002;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR = 6002;

key wearer;
string that_token = "global_";
integer locked;
integer hidden;

list closed_locks;
list open_locks;
list closed_locks_glows;
list open_locks_glows;

show_hide_lock() {
    if (hidden) return;
    integer i;
    integer links = llGetListLength(open_locks);
    for (;i < links; ++i) {
        llSetLinkAlpha(llList2Integer(open_locks,i),!locked,ALL_SIDES);
        update_glows(llList2Integer(open_locks,i),!locked);
    }
    links = llGetListLength(closed_locks);
    for (i=0; i < links; ++i) {
        llSetLinkAlpha(llList2Integer(closed_locks,i),locked,ALL_SIDES);
        update_glows(llList2Integer(closed_locks,i),locked);
    }
}

update_glows(integer link, integer alpha) {
    list glows;
    integer index;
    if (alpha) {
        glows = open_locks_glows;
        if (locked) glows = closed_locks_glows;
        index = llListFindList(glows,[link]);
        if (!~index) llSetLinkPrimitiveParamsFast(link,[PRIM_GLOW,ALL_SIDES,llList2Float(glows,index+1)]);
    } else {
        float glow = llList2Float(llGetLinkPrimitiveParams(link,[PRIM_GLOW,0]),0);
        glows = closed_locks_glows;
        if (locked) glows = open_locks_glows;
        index = llListFindList(glows,[link]);
        if (~index && glow > 0) glows = llListReplaceList(glows,[glow],index+1,index+1);
        if (~index && glow == 0) glows = llDeleteSubList(glows,index,index+1);
        if (!~index && glow > 0) glows += [link,glow];
        if (locked) open_locks_glows = glows;
        else closed_locks_glows = glows;
        llSetLinkPrimitiveParamsFast(link,[PRIM_GLOW,ALL_SIDES,0.0]);
    }
}

failsafe() {
    string name = llGetScriptName();
    if((key)name) return;
    if(name != "oc_lock") llRemoveInventory(name);
}

get_locks() {
    open_locks = [];
    closed_locks = [];
    integer i = llGetNumberOfPrims();
    string prim_name;
    for (;i > 1; --i) {
        prim_name = (string)llGetLinkPrimitiveParams(i,[PRIM_NAME]);
        if (prim_name == "Lock" || prim_name == "ClosedLock")
            closed_locks += i;
        else if (prim_name == "OpenLock")
            open_locks += i;
    }
}

default {
    state_entry() {
        //llSetMemoryLimit(20480);
        wearer = llGetOwner();
        get_locks();
        failsafe();
    }
    on_rez(integer iStart) {
        hidden = !(integer)llGetAlpha(ALL_SIDES);
        failsafe();
    }
    link_message(integer sender, integer num, string str, key id) {
        if (num == LINK_UPDATE) {
            if (str == "LINK_DIALOG") LINK_DIALOG = sender;
            else if (str == "LINK_RLV") LINK_RLV = sender;
            else if (str == "LINK_SAVE") LINK_SAVE = sender;
        } else if (num >= CMD_OWNER && num <= CMD_WEARER) {
            str = llToLower(str);
            if (str == "lock") {
                if (num == CMD_OWNER || id == wearer ) {
                    locked = TRUE;
                    llMessageLinked(LINK_SAVE,LM_SETTING_SAVE,that_token+"locked=1","");
                    llMessageLinked(LINK_ROOT,LM_SETTING_RESPONSE,that_token+"locked=1","");
                    llOwnerSay("@detach=n");
                    llMessageLinked(LINK_RLV,RLV_CMD,"detach=n","main");
                    llPlaySound("6b9da265-5fa5-d6c5-a5fb-0857d6d733ba",1.0);
                    show_hide_lock();
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"/me is locked.",id);
                } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);;
            } else if (str == "runaway" || str == "unlock") {
                if (num == CMD_OWNER)  {
                    locked = FALSE;
                    llMessageLinked(LINK_SAVE,LM_SETTING_DELETE,that_token+"locked","");
                    llMessageLinked(LINK_ROOT,LM_SETTING_RESPONSE,that_token+"locked=0","");
                    llOwnerSay("@detach=y");
                    llMessageLinked(LINK_RLV,RLV_CMD,"detach=y","main");
                    llPlaySound("9df6e604-b812-6f21-305c-e59a53d63a1f",1.0);
                    show_hide_lock();
                    llMessageLinked(LINK_DIALOG,NOTIFY,"1"+"/me is unlocked.",id);
                } else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);
            } else if (str == "show") hidden = FALSE;
            else if (str == "hide") hidden = TRUE;
        } else if (num == LM_SETTING_RESPONSE) {
            list params = llParseString2List(str,["="],[]);
            string this_token = llList2String(params,0);
            string value = llList2String(params,1);
            if (this_token == that_token+"locked") {
                locked = (integer)value;
                if (locked) llOwnerSay("@detach=n");
                show_hide_lock();
            }
        } else if (num == RLV_REFRESH || num == RLV_CLEAR) {
            if (locked) llMessageLinked(LINK_RLV, RLV_CMD,"detach=n","main");
            else llMessageLinked(LINK_RLV,RLV_CMD,"detach=y","main");
        } else if (num == REBOOT && str == "reboot") llResetScript();
    }
    changed(integer changes) {
        if (changes & CHANGED_OWNER) llResetScript();
        if (changes & CHANGED_LINK) get_locks();
        if (changes & CHANGED_COLOR) {
            integer new_hide = !(integer)llGetAlpha(ALL_SIDES);
            if (hidden != new_hide) {
                hidden = new_hide;
                show_hide_lock();
            }
        }
    }
}
