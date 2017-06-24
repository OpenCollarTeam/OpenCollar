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

//MESSAGE MAP
integer CMD_ZERO = 0;
integer CMD_OWNER = 500;
//integer CMD_TRUSTED = 501;
//integer CMD_GROUP = 502;
integer CMD_WEARER = 503;
integer CMD_EVERYONE = 504;
//integer CMD_RLV_RELAY = 507;
//integer CMD_SAFEWORD = 510;
//integer CMD_RELAY_SAFEWORD = 511;
//integer CMD_BLOCKED = 520;
integer NOTIFY = 1002;
integer NOTIFY_OWNERS = 1003;
//integer SAY = 1004;
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

integer version;

integer locked;

list these_menus;

dialog(key id, string context, list buttons, list arrows, integer page, integer auth, string name) {
    key that_menu = llGenerateKey();
    llMessageLinked(LINK_DIALOG,DIALOG,(string)id+"|"+context+"|"+(string)page+"|"+llDumpList2String(buttons,"`")+"|"+llDumpList2String(arrows,"`")+"|"+(string)auth,that_menu);
    integer index = llListFindList(these_menus,[id]);
    if (~index) 
        these_menus = llListReplaceList(these_menus,[id,that_menu,name],index,index + 2);
    else 
        these_menus += [id,that_menu,name];
}

list apps;
list adjusters;
integer menu_anim;
integer menu_rlv;
integer menu_kidnap;

menu_root(key id, integer auth) {
    string context = "\n/root";
    list these_buttons = ["Apps"];
    if (menu_anim) these_buttons += "Animations";
    else these_buttons += "-";
    if (menu_kidnap) these_buttons += "Capture";
    else these_buttons += "-";
    these_buttons += ["Leash"];
    if (menu_rlv) these_buttons += "RLV";
    else these_buttons += "-";
    these_buttons += ["Access","Settings","About"];
    if (locked) these_buttons = "UNLOCK" + these_buttons;
    else these_buttons = "LOCK" + these_buttons;
    dialog(id,context,these_buttons,[],0,auth,"Main");
}

menu_settings(key id, integer auth) {
}

menu_apps(key id, integer auth) {
}

menu_about(key id) {
}

commands(integer auth, string str, key id, integer clicked) {
    list params = llParseString2List(str,[" "],[]);
    string cmd = llToLower(llList2String(params,0));
    str = llToLower(str);
    if (cmd == "menu") {
        string submenu = llToLower(llList2String(params,1));
        if (submenu == "main" || submenu == "") menu_root(id,auth);
        else if (submenu == "apps") menu_apps(id,auth);
        else if (submenu == "settings") {
            if (auth != CMD_OWNER && auth != CMD_WEARER) {
                llMessageLinked(LINK_DIALOG,NOTIFY,"0"+"%NOACCESS%",id);
                menu_root(id,auth);
            } else menu_settings(id,auth);
        }
    } else if (str == "about") menu_about(id);
    else if (str == "apps") menu_apps(id,auth);
    else if (str == "settings") {
        if (auth == CMD_OWNER || auth == CMD_WEARER) menu_settings(id,auth);
    }
}

make_menus() {
    menu_anim = FALSE;
    menu_rlv = FALSE;
    menu_kidnap = FALSE;
    adjusters = [];
    apps = [] ;
    llMessageLinked(LINK_SET,MENUNAME_REQUEST,"Main","");
    llMessageLinked(LINK_SET,MENUNAME_REQUEST,"Apps","");
    llMessageLinked(LINK_SET,MENUNAME_REQUEST,"Settings","");
    llMessageLinked(LINK_ALL_OTHERS,LINK_UPDATE,"LINK_REQUEST","");
}

init() {
    llSetTimerEvent(1.0);
}

default {
    state_entry() {
        wearer = llGetOwner();
        init();
    }
    on_rez(integer iStart) {
        init();
    }
    link_message(integer sender, integer num, string str, key id) {
        list params;
        if (num == MENUNAME_RESPONSE) {
            params = llParseString2List(str,["|"],[]);
            string parentmenu = llList2String(params,0);
            string submenu = llList2String(params,1);
            if (parentmenu == "Apps") {
                if (!~llListFindList(apps, [submenu])) {
                    apps += [submenu];
                    apps = llListSort(apps,1,TRUE);
                }
            } else if (str == "Main|Animations") menu_anim = TRUE;
            else if (str == "Main|RLV") menu_rlv = TRUE;
            else if (str == "Main|Capture") menu_kidnap = TRUE;
            else if (str == "Settings|Size/Position") adjusters = ["Position","Rotation","Size"];
        } else if (num == MENUNAME_REMOVE) {
            params = llParseString2List(str,["|"],[]);
            string parentmenu = llList2String(params,0);
            string submenu = llList2String(params,1);
            if (parentmenu == "Apps") {
                integer index = llListFindList(apps,[submenu]);
                if (~index) apps = llDeleteSubList(apps,index,index);
            } else if (submenu == "Size/Position") adjusters = [];
        } else if (num == DIALOG_RESPONSE) {
            integer menuindex = llListFindList(these_menus,[id]);
            if (~menuindex) {
                params = llParseString2List(str,["|"],[]);
                id = (key)llList2String(params,0);
                string button = llList2String(params,1);
                integer page = (integer)llList2String(params,2);
                integer auth = (integer)llList2String(params,3);
                string menu = llList2String(these_menus,menuindex + 1);
                these_menus = llDeleteSubList(these_menus,menuindex - 1,menuindex + 1);
                if (menu == "Main"){
                    if (button == "LOCK" || button== "UNLOCK")
                        llMessageLinked(LINK_ROOT,auth,button,id);
                    else if (button == "About") menu_about(id);
                    else if (button == "Apps") menu_apps(id,auth);
                    else llMessageLinked(LINK_SET,auth,"menu "+button,id);
                }
            }
        } else if (num >= CMD_OWNER && num <= CMD_WEARER) commands(num,str,id,FALSE);
        else if (num == REBOOT && str == "reboot") llResetScript();
    }
    changed(integer changes) {
        if (changes & CHANGED_OWNER) llResetScript();
    }
    timer() {
        make_menus();
        llSetTimerEvent(0.0);
    }
}
