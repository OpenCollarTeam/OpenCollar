OpenCollar Release Notes
========================

These release notes should contain a list of bugfixes and new features for
every version of the collar that we release.  Minor development versions may be
hit and miss, but major releases (pushed to the whole group) should be complete.

3.716
-----

- Code cleanup in OpenCollar - leash.lsl. Deduplicated auth handling and
  notifications.  Added notifications for unleash.  Also contains new follow &
  followmenu commands.
- *clear bugfix for rlvsit, rlvtalk, rlvtp, and rlvmic.
- defaultsettings notecard read now supports multiple lines of same setting, to work around
  llGetNotecardLine()'s limit of 255 bytes. 
- defaultsettings notecard read reads to a separate list and merges into the
  main settings list when done, to allow for the above change to happen
  correctly. 
- defaultsettings Notecard reader forces send of all settings when done, as
  llGetNotecardLine() causes script sleep in the dataserver event, throwing it
  out of sync with the part of the script that would ordinarily send it. 


3.714
-----

- Removal of http settings DB.
- Introduction of new updater architecture, using bundles of scripts and items
  that are installed together.
- New chat command in leash module: <prefix>beckon allows an owner to beckon (pull over) the wearer without needing to be leashed.
- Fix bug in rlvsit module that caused the wrong object to be sat upon under certain circumstances.
