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
