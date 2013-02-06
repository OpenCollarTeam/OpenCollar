// Thanks to Schmobag Hogfather for the original schmottp framework adapted
// here.  Licensed under GPL.

string myurl;
string base = "http://opencollar.github.com/updater/";

integer HTTP_RESPONSE = -85432;
integer GIVE_LINK = -349857;
integer LOAD_URL = -349321;

string NAMESEP = "~";
string NAMEPRE = "OpenCollarUpdaterWeb";

// You need to put a random string here.  You can make one in Linux with this:
// head /dev/urandom | uuencode -m - | sed -n 2p | cut -c1-${1:-32};
// If you're not in linux, try http://goo.gl/KW36t
// string SECRET = "";
string SECRET = "5puCKfsOFovjYLlMhR8p9eun5MRMMqQS";

integer mychannel;

list routes;

debug(string text) {
    //llOwnerSay(llGetScriptName() + ": " + text);
}

BuildRoutes() {
    integer script_count = llGetInventoryNumber(INVENTORY_SCRIPT);
    if (script_count <= 1) {
        llOwnerSay("No plugins found");
        return;
    }
    //clear the route list first
    routes = [];
    
    //now build the new one
    integer n;
    for (n = 0; n < script_count; n++) {
        string name = llGetInventoryName(INVENTORY_SCRIPT, n);
        list parts = llParseStringKeepNulls(name, [NAMESEP], []);
        // valid plugins have 3 parts, the first named .octtp, and the last a
        // non-0 integer
        if (llGetListLength(parts) == 3 && 
            llList2String(parts, 0) == NAMEPRE && 
            (integer)llList2String(parts, 2) != 0) {
            
            string routename = llList2String(parts, 1);
            integer channel = (integer)llList2String(parts, 2);
            //only add route if name and channel not already present in list
            if (llListFindList(routes, [routename]) != -1) {
                llOwnerSay("Path " + routename + " already present in list. Skipping.");
            } else if (llListFindList(routes, [channel]) != -1) {
                llOwnerSay("Channel " + (string)channel + " already present in list. Skipping.");
            } else {
                routes += [routename, channel];
            }
        }
    }
    debug(llDumpList2String(routes, "\n"));
}

string List2JS(list things) {
    string inner = llDumpList2String(things, ",");
    return "[" + inner + "]";
}

string GetCallback(string qstring) {
    list qparams = llParseString2List(qstring, ["&", "="], []);
    return GetParam(qparams, "callback");
}

string GetParam(list things, string tok) {
    //return "" if not found
    integer index = llListFindList(things, [tok]);
    if (index == -1) {
        return "";
    } else {
        return llList2String(things, index + 1);
    }
}

string WrapCallback(string resp, string callback) {
    return callback + "(" + resp + ")";
}

string BuildURL(string toucher) {
    string url = base + "?url=" + llEscapeURL(myurl);
    url += "&av=" + toucher;
    url += "&tok=" + llMD5String(toucher + SECRET, 0);
    return url;
}

integer CheckToken(string av, string tok) {

    return llMD5String(av + SECRET, 0) == tok;
}

default
{
    state_entry() {
        if (SECRET == "") {
            llOwnerSay("ERROR: Before you can use me, you need to open up the " + llGetScriptName() + " script and put a secret random string in the SECRET variable.");
        } else {
            llRequestURL();
            BuildRoutes();
            //set my channel from my script name
            string myname = llGetScriptName();
            list parts = llParseStringKeepNulls(myname, [NAMESEP], []);
            mychannel = (integer)llList2String(parts, -1);                    
        }
    }
    
    on_rez( integer param ) {
        llRequestURL();
    }
 
    changed( integer changes ) {
        if( changes & (CHANGED_REGION|CHANGED_TELEPORT|CHANGED_REGION_START)) {
            llRequestURL();            
        }
        
        if (changes & CHANGED_INVENTORY) {
            BuildRoutes();
        }
    }    
    
    http_request(key id, string method, string body) {
        if (method == "URL_REQUEST_GRANTED") {
            myurl = body;
        } else {
            string qstring = llGetHTTPHeader(id, "x-query-string");
            list qparams = llParseString2List(qstring, ["&", "="], []);
            string av = GetParam(qparams, "av");
            string tok = GetParam(qparams, "tok");
            
            // Check the validity of the token passed in.
            if (CheckToken(av, tok)) {
                string path = llGetHTTPHeader(id, "x-path-info");
                list pathparts = llParseString2List(path, ["/"], []);
                // see if this top level path corresponds to a channel
                // (integer) in ROUTES.  if so, send link message on that
                // channel
                string root = llList2String(pathparts, 0);
                integer index = llListFindList(routes, [root]);
                
                if (index != -1) {
                    //we have a valid route for this request.  So let's send it
                    //out stick the query string in the str field
                    llMessageLinked(LINK_SET, llList2Integer(routes, index + 1), qstring, id);
                }                
            } else {
                llHTTPResponse(id, 403, "Bad Key");
            }
        }
    }
    
    link_message(integer sender, integer num, string str, key id) {       
        if (num == HTTP_RESPONSE) {
            llHTTPResponse(id, 200, str);
        } else if (num == mychannel) {
            //build a list of urls from routes
            integer stop = llGetListLength(routes);
            integer n;
            list paths;
            for (n = 0; n < stop; n+= 2) {
                paths += ["\"" + myurl + "/" + llList2String(routes, n) + "\""];
            }
            string json = List2JS(paths);
            string callback = GetCallback(str);
            llMessageLinked(LINK_SET, HTTP_RESPONSE, WrapCallback(json, callback), id);    
        } else if (num == GIVE_LINK) {
            // Give URL to person identified as id in link message
            llMessageLinked(LINK_SET, LOAD_URL, BuildURL(id), id);
        }
    }
}
