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
 
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
integer CMD_TRUSTED = 501;
integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
integer CMD_RLV_RELAY = 507;
integer CMD_SAFEWORD = 510;
integer CMD_RELAY_SAFEWORD = 511;
integer CMD_BLOCKED = 520;
integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
integer SAY = 1004;
integer REBOOT = -1000;
integer LINK_AUTH = 2;
integer LINK_DIALOG = 3;
integer LINK_RLV = 4;
integer LINK_SAVE = 5;
integer LINK_UPDATE = -10;
integer LM_SETTING_SAVE = 2000;
integer LM_SETTING_REQUEST = 2001;
integer LM_SETTING_RESPONSE = 2002;
integer LM_SETTING_DELETE = 2003;
integer LM_SETTING_EMPTY = 2004;
integer MENUNAME_REQUEST = 3000;
integer MENUNAME_RESPONSE = 3001;
integer MENUNAME_REMOVE = 3003;
integer RLV_CMD = 6000;
integer RLV_REFRESH = 6001;
integer RLV_CLEAR = 6002;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;
integer DIALOG_TIMEOUT = -9002;

key wearer;

string that_token = "global_";
integer locked;
integer hidden;

list closed_locks;
list open_locks;

show_hide_lock() {
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
        wearer = llGetOwner();
        get_locks();
    }
    on_rez(integer iStart) {
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
            }
        } else if (num == LM_SETTING_RESPONSE) {
            list params = llParseString2List(str,["="],[]);
            string this_token = llList2String(params,0);
            string value = llList2String(params,1);
            if (this_token == that_token+"locked") {
                locked = (integer)value;
                if (locked) llOwnerSay("@detach=n");
                show_hide_lock();
            }
        }
    }
    changed(integer changes) {
        if (changes & CHANGED_OWNER) llResetScript();
        if (changes & CHANGED_LINK) get_locks();
    }
}
