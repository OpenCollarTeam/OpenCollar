//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//       _   ___     __            __  ___  _                               //
//      | | / (_)___/ /___ _____ _/ / / _ \(_)__ ___ ________ ________      //
//      | |/ / / __/ __/ // / _ `/ / / // / (_-</ _ `/ __/ _ `/ __/ -_)     //
//      |___/_/_/  \__/\_,_/\_,_/_/ /____/_/___/\_, /_/  \_,_/\__/\__/      //
//                                             /___/                        //
//                                                                          //
//                                        _                                 //
//                                        \`*-.                             //
//                                         )  _`-.                          //
//                                        .  : `. .                         //
//                                        : _   '  \                        //
//                                        ; *` _.   `*-._                   //
//                                        `-.-'          `-.                //
//                                          ;       `       `.              //
//                                          :.       .        \             //
//                                          . \  .   :   .-'   .            //
//                                          '  `+.;  ;  '      :            //
//                                          :  '  |    ;       ;-.          //
//                                          ; '   : :`-:     _.`* ;         //
//    Remote Leashpost - 160123.1        .*' /  .*' ; .*`- +'  `*'          //
//                                       `*-*   `*-*  `*-*'                 //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2016 Garvin Twine                                         //
// ------------------------------------------------------------------------ //
//  This script is free software: you can redistribute it and/or modify     //
//  it under the terms of the GNU General Public License as published       //
//  by the Free Software Foundation, version 2.                             //
//                                                                          //
//  This script is distributed in the hope that it will be useful,          //
//  but WITHOUT ANY WARRANTY; without even the implied warranty of          //
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the            //
//  GNU General Public License for more details.                            //
//                                                                          //
//  You should have received a copy of the GNU General Public License       //
//  along with this script; if not, see www.gnu.org/licenses/gpl-2.0        //
// ------------------------------------------------------------------------ //
//  This script and any derivatives based on it must remain "full perms".   //
//                                                                          //
//  "Full perms" means maintaining MODIFY, COPY, and TRANSFER permissions   //
//  in Second Life(R), OpenSimulator and the Metaverse.                     //
//                                                                          //
//  If these platforms should allow more fine-grained permissions in the    //
//  future, then "full perms" will mean the most permissive possible set    //
//  of permissions allowed by the platform.                                 //
// ------------------------------------------------------------------------ //
//         github.com/OpenCollar/opencollar/tree/master/src/remote          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

// oc remote - LeashPost rez script 160112.1
// leashpost sends out a anchor to me command to all ID transmitted by the hud
// Otto(garvin.twine) 2016

integer g_iListener;

integer RemoteChannel(string sID,integer iOffset) {
    integer iChan = -llAbs((integer)("0x"+llGetSubString(sID,-7,-1)) + iOffset);
    return iChan;
}

default {
    on_rez(integer iStart) {
        llResetScript();
    }
    
    state_entry() {
        llSetMemoryLimit(16384);
        g_iListener = llListen(RemoteChannel(llGetOwner(),1234),"","","");
        list lTemp = llParseString2List(llGetObjectDesc(),["@"],[]);
        vector vRot = (vector)("<"+llList2String(lTemp,1)+">");
        vector vPos = (vector)("<"+llList2String(lTemp,2)+">");
        llSetRot(llEuler2Rot(vRot * DEG_TO_RAD));
        llSetPos(llGetPos()+vPos);
    }
    
    listen(integer iChannel, string sName, key kID, string sMessage) {
        llListenRemove(g_iListener);
        string sObjectID = (string)llGetKey();
        list lToLeash = llParseString2List(sMessage,[","],[]);
        integer i = llGetListLength(lToLeash);
        key kID;
        while (i) {
            kID = llList2Key(lToLeash,--i);
            llRegionSayTo(kID,RemoteChannel(kID,0),"anchor "+sObjectID);
        }
    }
}
