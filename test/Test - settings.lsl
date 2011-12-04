// test script for "Opencollar - settings"
//
// how to use:
// Put the "Opencollar - settings" script, the defaultsettings notecard,
// and this script in a cube, recompile/reset scripts and watch the output


integer HTTPDB_SAVE = 2000;
integer HTTPDB_REQUEST = 2001;
integer HTTPDB_RESPONSE = 2002;
integer HTTPDB_DELETE = 2003;
integer HTTPDB_EMPTY = 2004;
integer HTTPDB_REQUEST_NOCACHE = 2005;

// offset for local setting commands
// (currently sent in addition to HTTPDB responses)
integer LOCALSETTING_OFFSET = 500;

// timeout after which we are sure we got all messages from the settings script
float TIMEOUT = 0.5;

integer errors = 0;   // summary - number of detected errors
integer num_tcs = 0;  // summary - number of testcases

list tc_resp;   // responses are stored here


string tc_001_msg = "TC 001 - request notecard setting";
list tc_001_req = [HTTPDB_REQUEST, "rlvon"];
list tc_001_exp = [HTTPDB_RESPONSE, "rlvon=unset"];

string tc_002_msg = "TC 002 - store a setting";
list tc_002_req = [HTTPDB_SAVE, "name=value"];
list tc_002_exp = [];

string tc_003_msg = "TC 003 - retrieve a setting (from TC 002)";
list tc_003_req = [HTTPDB_REQUEST, "name"];
list tc_003_exp = [HTTPDB_RESPONSE, "name=value"];

string tc_004_msg = "TC 004 - delete a setting (from TC 002)";
list tc_004_req = [HTTPDB_DELETE, "name"];
list tc_004_exp = [];

string tc_005_msg = "TC 005 - verify deleted setting (from TC 004) gone";
list tc_005_req = [HTTPDB_REQUEST, "name"];
list tc_005_exp = [HTTPDB_EMPTY, "name"];

string tc_006_msg = "TC 006 - store multiple (5) settings";
list tc_006_req = [HTTPDB_SAVE, "n1=v1|n2=v2|n3=v3|n4=v4|n5=v5"];
list tc_006_exp = [];

string tc_007_msg = "TC 007 - retrieve a single setting (from TC 006)";
list tc_007_req = [HTTPDB_REQUEST, "n2"];
list tc_007_exp = [HTTPDB_RESPONSE, "n2=v2"];

string tc_008_msg = "TC 008 - retrieve multiple settings (multiple requests)";
list tc_008_req = [HTTPDB_REQUEST, "n1", HTTPDB_REQUEST, "n3"];
list tc_008_exp = [HTTPDB_RESPONSE, "n1=v1", HTTPDB_RESPONSE, "n3=v3"];

string tc_009_msg = "TC 009 - retrieve multiple settings (single request)";
list tc_009_req = [HTTPDB_REQUEST, "n2|n4|n5"];
list tc_009_exp = [HTTPDB_RESPONSE, "n2=v2|n4=v4|n5=v5"];

string tc_010_msg = "TC 010 - multiple retrieve, valid and invalid";
list tc_010_req = [HTTPDB_REQUEST, "n1|n2|nxxx"];
list tc_010_exp = [HTTPDB_RESPONSE, "n1=v1|n2=v2", HTTPDB_EMPTY, "nxxx"];

string tc_011_msg = "TC 011 - overwrite a setting";
list tc_011_req = [HTTPDB_SAVE, "n1=newval1"];
list tc_011_exp = [];

string tc_012_msg = "TC 012 - multiple retreive, check overwritten setting";
list tc_012_req = [HTTPDB_REQUEST, "n1|n2|nxxx|nzzz"];
list tc_012_exp = [HTTPDB_RESPONSE, "n1=newval1|n2=v2",
                   HTTPDB_EMPTY, "nxxx|nzzz"];

string tc_013_msg = "TC 013 - delete multiple settings";
list tc_013_req = [HTTPDB_DELETE, "n1|n2|n3"];
list tc_013_exp = [];

string tc_014_msg = "TC 014 - verify deletion (from TC 013)";
list tc_014_req = [HTTPDB_REQUEST, "n1|n2|n3|n4|n5"];
list tc_014_exp = [HTTPDB_RESPONSE, "n4=v4|n5=v5",
                   HTTPDB_EMPTY, "n1|n2|n3"];

string tc_015_msg = "TC 015 - check robustness - \"|name1=value1\"";
list tc_015_req = [HTTPDB_SAVE, "|name1=value1"];
list tc_015_exp = [];

string tc_016_msg = "TC 016 - check robustness - \"|name1\"";
list tc_016_req = [HTTPDB_REQUEST, "|name1"];
list tc_016_exp = [HTTPDB_RESPONSE, "name1=value1"];

string tc_017_msg = "TC 017 - check robustness - \"name2=value2|\"";
list tc_017_req = [HTTPDB_SAVE, "name2=value2|"];
list tc_017_exp = [];

string tc_018_msg = "TC 018 - check robustness - \"name2|\"";
list tc_018_req = [HTTPDB_REQUEST, "name2|"];
list tc_018_exp = [HTTPDB_RESPONSE, "name2=value2"];


send_req (list req)
{
    do {
        llMessageLinked (LINK_THIS, llList2Integer (req, 0),
                         llList2String (req, 1), "");
    }
    while ((req = llDeleteSubList (req, 0, 1)) != []);
}

list append_localsetting (list l)
{
    list res = l;
    integer ix = 0;
    integer cmd;

    do
    {
        cmd = llList2Integer (l, 0);
        if ((cmd == HTTPDB_RESPONSE) || (cmd == HTTPDB_EMPTY))
        {
            res = res + [cmd + LOCALSETTING_OFFSET, llList2String (l, 1)];
        }
    } 
    while (l = llDeleteSubList (l, 0, 1));

    return res;
}

integer check_response (list req, list exp)
{
    integer errs = 0;
    integer exp_ix;

    exp = append_localsetting (exp);
    exp = exp + req;

    //llOwnerSay ("check_response:\nreq: " + llList2CSV (req)
    //            + "\nexp: " + llList2CSV (exp)
    //            + "\ngot: " + llList2CSV (tc_resp));

    do {
        exp_ix = llListFindList (exp, llList2List (tc_resp, 0, 1));

        if (exp_ix == -1)
        {
            llOwnerSay (tc_001_msg + "FAIL - got unexpected message "
                        + llList2String (tc_resp, 0) + ", \""
                        + llList2String (tc_resp, 1) + "\"");
            errs = 1;
        }
        else
        {
            exp = llDeleteSubList (exp, exp_ix, exp_ix + 1);
        }
    }
    while ((tc_resp = llDeleteSubList (tc_resp, 0, 1)) != []);

    if (llGetListLength (exp) != 0)
    {
        do {
            llOwnerSay ("FAIL - missing message "
                        + llList2String (exp, 0) + ",\""
                        + llList2String (exp, 1) + "\"");
        }
        while ((exp = llDeleteSubList (exp, 0, 1)) != []);
        errs = 1;
    }

    return errs;
}

tc_entry (list req)
{
    tc_resp = [];
    send_req (req);
    llSetTimerEvent (TIMEOUT);
}

tc_timer (string msg, list req, list exp)
{
    integer res = check_response (req, exp);
    if (res == 0)
        llOwnerSay ("PASS: " + msg);
    errors = errors + res;
    num_tcs++;
}

default
{
    state_entry ()
    {
        llResetOtherScript ("OpenCollar - settings");
        llSetTimerEvent (TIMEOUT);
    }

    link_message (integer sender, integer num, string msg, key id)
    {
        // we ignore messages after reset
        llOwnerSay ("link_message: " + (string)num + " \"" + msg + "\"");
    }

    timer ()
    {
        state testcase_001;
    }
}

state testcase_001
{
    state_entry ()
    {
        tc_entry (tc_001_req);
    }

    link_message (integer sender, integer num, string msg, key id)
    {
        tc_resp = tc_resp + [num, msg];
        llSetTimerEvent (TIMEOUT);
    }

    timer ()
    {
        tc_timer (tc_001_msg, tc_001_req, tc_001_exp);
        state testcase_002;
    }
}

// further states written more compact - obfuscated lsl :-)
state testcase_002 { state_entry () { tc_entry (tc_002_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_002_msg, tc_002_req, tc_002_exp);
        state testcase_003; } }

state testcase_003 { state_entry () { tc_entry (tc_003_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_003_msg, tc_003_req, tc_003_exp);
        state testcase_004; } }

state testcase_004 { state_entry () { tc_entry (tc_004_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_004_msg, tc_004_req, tc_004_exp);
        state testcase_005; } }

state testcase_005 { state_entry () { tc_entry (tc_005_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_005_msg, tc_005_req, tc_005_exp);
        state testcase_006; } }

state testcase_006 { state_entry () { tc_entry (tc_006_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_006_msg, tc_006_req, tc_006_exp);
        state testcase_007; } }

state testcase_007 { state_entry () { tc_entry (tc_007_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_007_msg, tc_007_req, tc_007_exp);
        state testcase_008; } }

state testcase_008 { state_entry () { tc_entry (tc_008_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_008_msg, tc_008_req, tc_008_exp);
        state testcase_009; } }

state testcase_009 { state_entry () { tc_entry (tc_009_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_009_msg, tc_009_req, tc_009_exp);
        state testcase_010; } }

state testcase_010 { state_entry () { tc_entry (tc_010_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_010_msg, tc_010_req, tc_010_exp);
        state testcase_011; } }

state testcase_011 { state_entry () { tc_entry (tc_011_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_011_msg, tc_011_req, tc_011_exp);
        state testcase_012; } }

state testcase_012 { state_entry () { tc_entry (tc_012_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_012_msg, tc_012_req, tc_012_exp);
        state testcase_013; } }

state testcase_013 { state_entry () { tc_entry (tc_013_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_013_msg, tc_013_req, tc_013_exp);
        state testcase_014; } }

state testcase_014 { state_entry () { tc_entry (tc_014_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_014_msg, tc_014_req, tc_014_exp);
        state testcase_015; } }

state testcase_015 { state_entry () { tc_entry (tc_015_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_015_msg, tc_015_req, tc_015_exp);
        state testcase_016; } }

state testcase_016 { state_entry () { tc_entry (tc_016_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_016_msg, tc_016_req, tc_016_exp);
        state testcase_017; } }

state testcase_017 { state_entry () { tc_entry (tc_017_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_017_msg, tc_017_req, tc_017_exp);
        state testcase_018; } }

state testcase_018 { state_entry () { tc_entry (tc_018_req); }
    link_message (integer sender, integer num, string msg, key id) {
        tc_resp = tc_resp + [num, msg]; llSetTimerEvent (TIMEOUT); }
    timer () { tc_timer (tc_018_msg, tc_018_req, tc_018_exp);
        state summary; } }

state summary
{
    state_entry ()
    {
        llOwnerSay ((string)(num_tcs - errors) + " expected passes, "
                    + (string)errors + " unexpected failures");
    }

    link_message (integer sender, integer num, string msg, key id)
    {
        llOwnerSay ("link_message: " + (string)num + " \"" + msg + "\"");
    }
}
