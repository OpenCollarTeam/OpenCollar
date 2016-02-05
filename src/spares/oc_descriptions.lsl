//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//              ____                   ______      ____                     //
//             / __ \____  ___  ____  / ____/___  / / /___ ______           //
//            / / / / __ \/ _ \/ __ \/ /   / __ \/ / / __ `/ ___/           //
//           / /_/ / /_/ /  __/ / / / /___/ /_/ / / / /_/ / /               //
//           \____/ .___/\___/_/ /_/\____/\____/_/_/\__,_/_/                //
//               /_/                                                        //
//                                                                          //
//                        ,^~~~-.         .-~~~"-.                          //
//                       :  .--. \       /  .--.  \                         //
//                       : (    .-`<^~~~-: :    )  :                        //
//                       `. `-,~            ^- '  .'                        //
//                         `-:                ,.-~                          //
//                          .'                  `.                          //
//                         ,'   @   @            |                          //
//                         :    __               ;                          //
//                      ...{   (__)          ,----.                         //
//                     /   `.              ,' ,--. `.                       //
//                    |      `.,___   ,      :    : :                       //
//                    |     .'    ~~~~       \    / :                       //
//                     \.. /               `. `--' .'                       //
//                        |                  ~----~                         //
//                       new themes - 160204.1                              //
// ------------------------------------------------------------------------ //
//  Copyright (c) 2008 - 2016 Nandana Singh, Garvin Twine, Cleo Collins,    //
//  Satomi Ahn, Kisamin, Joy Stipe, Wendy Starfall, littlemousy,            //
//  Romka Swallowtail et al.                                                //
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
//         github.com/OpenCollar/opencollar/tree/master/src/collar          //
// ------------------------------------------------------------------------ //
//////////////////////////////////////////////////////////////////////////////

default {

    state_entry() {

        llOwnerSay("Start conversion... ");

        integer iLinkNum = llGetNumberOfPrims()+1;
        while (iLinkNum-- > 2) {
            string sDesc = llList2String(llGetLinkPrimitiveParams(iLinkNum, [PRIM_DESC]),0);
            sDesc = llStringTrim(sDesc, STRING_TRIM);

            if (sDesc != "(No Description)" && sDesc != "") {
                list lParams = llParseString2List(sDesc, ["~"], []);
                integer index ;

                if (llListFindList(lParams,["texture"]) == -1) {
                    index = llListFindList(lParams,["notexture"]);
                    if (index == -1) lParams += ["texture"] ;
                    else lParams = llDeleteSubList(lParams, index, index);
                }

                if (llListFindList(lParams,["color"]) == -1) {
                    index = llListFindList(lParams,["nocolor"]);
                    if (index == -1) lParams += ["color"] ;
                    else lParams = llDeleteSubList(lParams, index, index);
                }

                if (llListFindList(lParams,["shiny"]) == -1) {
                    index = llListFindList(lParams,["noshiny"]);
                    if (index == -1) index = llListFindList(lParams,["noshine"]);

                    if (index == -1) lParams += ["shiny"] ;
                    else lParams = llDeleteSubList(lParams, index, index);
                }

                if (llListFindList(lParams,["glow"]) == -1) {
                    index = llListFindList(lParams,["noglow"]);
                    if (index == -1) lParams += ["glow"] ;
                    else lParams = llDeleteSubList(lParams, index, index);
                }

                if (llListFindList(lParams,["hide"]) == -1) {
                    index = llListFindList(lParams,["nohide"]);
                    if (index == -1) lParams += ["hide"] ;
                    else lParams = llDeleteSubList(lParams, index, index);
                }

                string description = llDumpList2String(lParams,"~");
                llSetLinkPrimitiveParamsFast(iLinkNum,[PRIM_DESC, description]);
            }
        }
        llOwnerSay("Conversion done.");
        llRemoveInventory(llGetScriptName());
    }
}
