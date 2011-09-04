OpenCollar Updater
==================

This project contains the code for the OpenCollar Updater.  It uses new
filenames that are more friendly to offline editing.  Version numbers have been
removed from the filenames, in favor of using an actual version control system
(Git).

All of the scripts and notecards necessary for the updater to function should
be present in the 'lsl' folder of this repository.  Animations, textures, and
other inventory types are not in this repo, and are only available inworld.

When you first clone the repository, you may wish to set up your user account
to use your Second Life name instead of whatever name might be in your global
git config.  You can do that like this:

    cd ocupdater/
    git config user.email "joe.resident@gmail.com"
    git config user.name "Joe Resident"

You'll probably also want to be able to sync the scripts inworld.  I suggest
using the [Phoenix Viewer] [1]'s 'Import Linkset' feature.  This
requires that you have an xml file from an exported object.  There is an
'updater.xml' file included in the repository for this purpose.  Before running
the import, you'll need to make an `updater_assets` folder containing the
scripts and notecards, with special uuids in the names.  There's a script for
that.  This requires that you have Python's lxml library installed.

    python lsl2xml.py updater.xml

With that done, you should be able to launch Phoenix and do `File -> Import
Linkset` in the menu, then select the updater.xml file from the ocupdater
repository.  You should get a red and black object inworld, with all the OC
scripts inside.

If you're like me, Phoenix will import the scripts just fine, but choke on the
notecards.  So you might have to do those manually.

There's one more step.  All of the scripts you just imported are probably
compiled for the LSL2 runtime rather than Mono.  So select the object you just
imported, and do `Tools -> Recompile Scripts in Selection -> Mono`.

When you're actually working on the scripts, you'll need a way to sync them
back to disk if you want to push them to Github and share your changes back to
the project.  There are two options there:

1.  In Phoenix, right click the updater and select `More -> More -> Export` to
    create a new exported object.  Then use the xml2lsl.py script to move the
    scripts from your new assets folder into your git repo (and also rename
    them to be human readable).
2.  Run [Imprudence] [2] when you're working on OC scripts, and use the `Export
    Text` and `Import Text` features built into its script editor in order to
    manually keep your inworld version of the scripts in sync with your on-disk
    version.  (This is what I do currently, since Phoenix object export seems
    to crash me most times I try it.)

Note to third party viewer devs: It would be *really* awesome to have a way to
keep an inworld folder of scripts and notecards in sync with a folder on your
hard drive.  All of the current methods require jumping through some really
annoying hoops.

[1]: http://www.phoenixviewer.com/  "Phoenix Viewer"
[2]: http://wiki.kokuaviewer.org/wiki/Downloads "Imprudence"
