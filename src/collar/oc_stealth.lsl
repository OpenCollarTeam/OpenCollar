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

// This plugin can be used to hide the whole device (and to show it again).

integer CMD_OWNER = 500;
integer CMD_WEARER = 503;
integer NOTIFY = 1002;
integer REBOOT = -1000;
integer LINK_DIALOG = 3;
integer LINK_UPDATE = -10;

integer hidden;
list glowy;

stealth (string str) {
    if (str == "hide") hidden = TRUE;
    else if (str == "show") hidden = FALSE;
    else hidden = !hidden;
    llSetLinkAlpha(LINK_SET,(float)(!hidden),ALL_SIDES);
    integer count;
    if (hidden) {
        count = llGetNumberOfPrims();
        float glow;
        for (;count > 0; --count) {
            glow = llList2Float(llGetLinkPrimitiveParams(count,[PRIM_GLOW,0]),0);
            if (glow > 0) glowy += [count,glow];
        }
        llSetLinkPrimitiveParamsFast(LINK_SET,[PRIM_GLOW,ALL_SIDES,0.0]);
    } else {
        integer i;
        count = llGetListLength(glowy);
        for (;i < count;i += 2)
            llSetLinkPrimitiveParamsFast(llList2Integer(glowy,i),[PRIM_GLOW,ALL_SIDES,llList2Float(glowy,i+1)]);
        glowy = [];
    }
}

failsafe() {
    string name = llGetScriptName();
    if ((key)name) return;
    if (name != "oc_stealth") llRemoveInventory(name);
}

init() {
    hidden = !(integer)llGetAlpha(ALL_SIDES);
    failsafe();
}

default {
    state_entry() {
        init();
    }
    on_rez(integer start) {
        init();
    }
    link_message(integer sender, integer num, string str, key id) {
        if (num == LINK_UPDATE &&  str == "LINK_DIALOG") LINK_DIALOG = sender;
        else {
            string lowerstr = llToLower(str);
            if (lowerstr == "hide" || lowerstr == "show" || lowerstr == "stealth") {
                if (num == CMD_OWNER || num == CMD_WEARER) stealth(lowerstr);
                else if ((key)id) llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);
            } else if (num == REBOOT && str == "reboot") llResetScript();
        }
    }
    changed(integer changes) {
        if (changes & CHANGED_OWNER) llResetScript();
        if (changes & CHANGED_INVENTORY) failsafe();
    }
}
