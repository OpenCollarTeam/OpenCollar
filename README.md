OpenCollar Updater
==================

This project contains the code for the OpenCollar Updater.  It uses new
filenames that are more friendly to offline editing.  Version numbers have been
removed from the filenames, in favor of using an actual version control system
(Git).  

If you're new to Git, [start here] (http://help.github.com/).  Once you've forked this
project on Github and cloned your fork to your own computer, come back and
finish reading this.

All of the scripts and notecards necessary for the updater to function should
be present in the 'lsl' folder of this repository.  Animations, textures, and
other inventory types are not in this repo, and are only available inworld.

Setting Your Identity in Git
----------------------------

When you first clone the repository, you may wish to set up your user account
to use your Second Life name instead of whatever name might be in your global
git config.  You can do that like this:

    cd ocupdater/
    git config user.email "joe.resident@gmail.com"
    git config user.name "Joe Resident"

Staying in Sync
---------------

I used to have some instructions here for using Phoenix's export/import feature
to keep files in sync between your disk and SL.  That was really crashy and
buggy though, so I'm still looking for a good solution.

My best advice right now is this:

1. Fork the code on Github and clone your fork to your local machine.
2. Get a copy of the latest updater inside SL.
3. When editing a file in SL, use the external editor support so you can easily
   save your work both inworld and to your local working directory.

Contributing Changes
--------------------

Please submit all changes as Github pull requests.  We've tried accepting
modified scripts inworld, and have burnt out more than one release manager that
way.  It's a nightmare.  So for the sanity of all concerned, Github pull
requests are the *only* way that we will accept modifications to the OC
scripts.

I know Git will be intimidating for some people, especially those who have only
worked on scripts inside SL.  Please take the time to learn to work with Git
though.  It will be a huge help towards managing the project in a sane way. The
[documentation] (http://help.github.com/) is really pretty good.


The Part Where I Beg
--------------------

Note to third party viewer devs: It would be *really* awesome to have a way to
keep an inworld folder of scripts and notecards in sync with a folder on your
hard drive.  All of the current methods require jumping through some really
annoying hoops.

This is a test line because i could not think of anything cleaver to say.
