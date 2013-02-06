// this script exists solely to take the hit on the 10 second freeze
// from llLoadURL.

integer LOAD_URL = -349321;

default {
    link_message(integer sender, integer num, string str, key id) {
        if (num == LOAD_URL && llGetAgentSize(id) != ZERO_VECTOR && str != "") {
            string message = "Open this link to select your bundles and continue the update process.";
            llLoadURL(id, message, str);            
        }
    }
}
