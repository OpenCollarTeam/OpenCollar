/*
 * Total Power Exchange (TPE) Plugin for OpenCollar 8.x — FINAL, OWNER PROTECTED
 * - Prevents wearer from enabling TPE if no primary owner is set
 * - Menu dialog appears only once per click
 * - All TPE logic, debug, and owner check via oc_settings
 */

integer ALIVE               = -55;
integer READY               = -56;
integer STARTUP             = -57;
integer MENUNAME_REQUEST    = 3000;
integer MENUNAME_RESPONSE   = 3001;
integer CMD_ZERO            = 0;
integer CMD_SAFEWORD        = 510;
integer CMD_RELAY_SAFEWORD  = 511;
integer CMD_RLV_RELAY       = 507;

integer ISOWNED_REQUEST     = 7600;
integer ISOWNED_RESPONSE    = 7601;

integer gTPE_Enabled = FALSE;
key     gOwner;
integer gDialogChan = -999987;
key     gLastDialogUser;

float   gLastMenuTime = 0.0;

integer gAwaitingOwnerCheck = FALSE;
key     gPendingUser;

sendAPICmd(string cmd) {
    llMessageLinked(LINK_SET, CMD_ZERO, cmd, gOwner);
    llOwnerSay("[TPE] Command sent: " + cmd);
}

applyTPE() {
    llOwnerSay(
        "[TPE] ACTIVATING TPE:\n" +
        "• Public ON\n" +
        "• Safeword DISABLED\n" +
        "• Wearer controls BLOCKED\n" +
        "• RLV relay AUTOMATIC"
    );
    sendAPICmd("auth=public~1");
    llMessageLinked(LINK_SET, CMD_RLV_RELAY, "automatic", gOwner);
    llOwnerSay("[TPE] RLV relay set to automatic");
}

revertTPE() {
    llOwnerSay("[TPE] DEACTIVATING TPE: Restoring defaults.");
    sendAPICmd("auth=public~0");
}

showTPEMenu(key who) {
    float now = llGetUnixTime();
    if (now - gLastMenuTime < 1.0) return; // Prevent double-pop
    gLastMenuTime = now;

    gLastDialogUser = who;
    list btns = [];
    string msg = "[TPE]\nDANGEROUS PLUGIN!\nEnabling TPE disables ALL wearer controls and disables the safeword.\nProceed with caution!";
    if (!gTPE_Enabled)
        btns = ["TPE On"];
    else
        btns = ["TPE Off"];
    llListenRemove(gDialogChan);
    gDialogChan = llListen(gDialogChan, "", who, "");
    llDialog(who, msg, btns, gDialogChan);
    llOwnerSay("[TPE DEBUG] Showing TPE menu dialog to: " + (string)who);
}

requestOwnerStatus(key who) {
    gAwaitingOwnerCheck = TRUE;
    gPendingUser = who;
    llMessageLinked(LINK_SET, ISOWNED_REQUEST, "", who);
}

default {
    state_entry() {
        gOwner = llGetOwner();
        llOwnerSay("[TPE] Owner-protected plugin loaded. Awaiting menu interactions...");
    }

    link_message(integer sender, integer msg, string str, key id) {
        llOwnerSay(
            "[TPE DEBUG] link_message: msg=" + (string)msg +
            " str=\"" + str + "\" sender=" + (string)sender +
            " id=" + (string)id
        );

        if (msg == MENUNAME_REQUEST) {
            if (str == "Apps") {
                llOwnerSay("[TPE DEBUG] Registering 'Apps|TPE' under context 'Apps'");
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Apps|TPE", "Apps");
            }
            else if (str == "Apps|TPE" || str == "TPE") {
                llOwnerSay("[TPE DEBUG] Registering submenus 'Apps|TPE|On', 'Apps|TPE|Off' under context '" + str + "'");
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Apps|TPE|On", str);
                llMessageLinked(LINK_SET, MENUNAME_RESPONSE, "Apps|TPE|Off", str);
            }
            return;
        }

        if ((msg == 0 || msg == 500) && llToLower(str) == "menu tpe") {
            llOwnerSay("[TPE DEBUG] Handling 'menu TPE' request with custom menu dialog!");
            showTPEMenu(id);
            return;
        }

        if (msg == CMD_ZERO) {
            list parts = llParseString2List(str, ["|"], []);
            if (llGetListLength(parts) == 3 &&
                llList2String(parts,0) == "Apps" &&
                llList2String(parts,1) == "TPE") {
                string action = llList2String(parts,2);
                if (action == "On" && !gTPE_Enabled) {
                    requestOwnerStatus(id);
                    return;
                }
                if (action == "Off" && gTPE_Enabled) {
                    llDialog(id,
                        "[TPE]\nDisable Total Power Exchange?",
                        ["Yes", "No"], gDialogChan);
                    llListenRemove(gDialogChan);
                    gDialogChan = llListen(gDialogChan, "", id, "");
                    return;
                }
            }
            string lstr = llToLower(str);
            if (lstr == "tpe") {
                showTPEMenu(id);
                return;
            }
            if (lstr == "tpe on" && !gTPE_Enabled) {
                requestOwnerStatus(id);
                return;
            }
            if (lstr == "tpe off" && gTPE_Enabled) {
                llDialog(id, "[TPE] Are you sure you want to DISABLE TPE?", ["Yes", "No"], gDialogChan);
                llListenRemove(gDialogChan);
                gDialogChan = llListen(gDialogChan, "", id, "");
                return;
            }
        }

        // Handle ISOWNED_RESPONSE from oc_settings
        if (msg == ISOWNED_RESPONSE && gAwaitingOwnerCheck && id == gPendingUser) {
            gAwaitingOwnerCheck = FALSE;
            if (str == "0") {
                llOwnerSay("You can't lock yourself out of your collar. TPE requires a primary owner set.");
                return;
            } else {
                llDialog(id,
                    "[TPE] Are you SURE you want to ENABLE TPE?\nYou will lose all wearer controls and the safeword!\nThis is irreversible until the owner disables it.\nProceed?",
                    ["Yes", "No"], gDialogChan);
                llListenRemove(gDialogChan);
                gDialogChan = llListen(gDialogChan, "", id, "");
            }
            return;
        }

        if (gTPE_Enabled) {
            if (msg == CMD_SAFEWORD || msg == CMD_RELAY_SAFEWORD) {
                llOwnerSay("[TPE] Safeword blocked.");
                return;
            }
            if (msg == CMD_RLV_RELAY) {
                if (llSubStringIndex(str, "detach") != -1 || llSubStringIndex(str, "unbind") != -1) {
                    llOwnerSay("[TPE] Unbind attempt blocked: " + str);
                    return;
                }
            }
        }
    }

    listen(integer channel, string name, key id, string msg) {
        if (channel != gDialogChan) return;
        if (id != gOwner) return;
        if (msg == "TPE On" && !gTPE_Enabled) {
            requestOwnerStatus(id);
            return;
        }
        if (msg == "TPE Off" && gTPE_Enabled) {
            llDialog(id, "[TPE] Are you sure you want to DISABLE TPE?", ["Yes", "No"], gDialogChan);
            return;
        }
        if (msg == "Yes" && !gTPE_Enabled) {
            gTPE_Enabled = TRUE;
            applyTPE();
            llOwnerSay("[TPE] Enabled.");
            llListenRemove(gDialogChan);
            return;
        }
        if (msg == "Yes" && gTPE_Enabled) {
            gTPE_Enabled = FALSE;
            revertTPE();
            llOwnerSay("[TPE] Disabled.");
            llListenRemove(gDialogChan);
            return;
        }
        if (msg == "No") {
            llOwnerSay("[TPE] Action canceled.");
            llListenRemove(gDialogChan);
            return;
        }
    }

    changed(integer change) {
        if (change & (CHANGED_REGION | CHANGED_OWNER)) {
            llResetScript();
        }
    }

    on_rez(integer start_param) {
        llResetScript();
    }
}
