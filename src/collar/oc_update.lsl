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

// This plugin can be used to receive updates through the OpenCollar Six
// Installer. The user has to confirm before any installations can start.
// Whether patches from the upstream can be installed or not is optional.

integer CMD_WEARER = 503;
integer NOTIFY = 1002;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_UPDATE = -10;
integer DIALOG = -9000;
integer DIALOG_RESPONSE = -9001;

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

failsafe() {
    string name = llGetScriptName();
    if((key)name) return;
    if((upstream && name != "oc_update")) llRemoveInventory(name);
}

default {
    state_entry() {
        //llSetMemoryLimit(16384);
        wearer = llGetOwner();
        failsafe();
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
        } else if (num == REBOOT && str == "reboot") llResetScript();
    }
    on_rez(integer start) {
        if (llGetOwner() != wearer) llResetScript();
        failsafe();
    }
}
