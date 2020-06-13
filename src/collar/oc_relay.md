Date 2020-06-12
This is a checklist for shared work on the internal relay.  This way we will not duplicate work.

1) Add Ask Mode.  Single source.  If ask request is not answered, use dialog timeout signal to clear the request.
Do not allow pending requests to multiply.
2) Allow relay to listen to collar safeword.
3) Add relay safeword.  Name it "Refuse".
4) Make relay safeword when on auto pause the relay for 30 seconds
5) Make "helpless mode" with checkbox to turn off Refuse and also stop collar safeword (can this be done with a single setting?)
6) add checkbox to lock out wearer from changing relay settings
6) Relay needs to send a signal to rlvsuite, and rlvsuite needs to clear what restrictions it thinks it has set, 
then request them from settings. This will trigger it to re-issue all restrictions)
7) rlvsys: Allow RLV Clear All signal to clear relay restrictions
8) add blacklist.  Set limit for blacklisted sources.
9) add blacklist off mode for the truly hardcore
10) update chat commands: relay (to get the relay menu); relay off / relay on / relay ask / relay auto / refuse (to activate the relay safeword)
