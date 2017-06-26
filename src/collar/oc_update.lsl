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
//integer LM_SETTING_EMPTY = 2004;
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
integer upstream;
key id_installer;

update(){
    integer pin = (integer)llFrand(99999998.0) + 1;
    llSetRemoteScriptAccessPin(pin);
    integer chan_installer = -12345;
    if (upstream) chan_installer = -7483213;
    llRegionSayTo(id_installer,chan_installer,"ready|"+(string)pin);
}

key menu_id;

default {
    state_entry() {
        wearer = llGetOwner();
    }
    link_message(integer sender, integer num, string str, key id) {
        if (!llSubStringIndex(str,".- ... -.-") && id == wearer) {
            id_installer = (key)llGetSubString(str,-36,-1);
            menu_id = llGenerateKey();
            llMessageLinked(LINK_DIALOG,DIALOG,(string)wearer+"|\nReady to install?|0|Yes`No|Cancel|"+(string)CMD_WEARER,menu_id);
        } else if (num == DIALOG_RESPONSE) {
            if (id == menu_id) {
                list params = llParseString2List(str,["|"],[]);
                id = (key)llList2String(params,0);
                string button = llList2String(params,1);
                if (button == "Yes") update();
                else llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"cancelled",id);
            }
        } else if (num == LINK_UPDATE) {
            if (str == "LINK_DIALOG") LINK_DIALOG = sender;
            
    listen(integer chan, string name, key id, string sMessage) {
    }
    timer() {
    }
    on_rez(integer start) {
    }
}
