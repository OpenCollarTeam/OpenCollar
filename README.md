OpenCollarUpdater Dev/Beta/RC
=============================

This project contains the code for the OpenCollar Updater.  It uses new
filenames that are more friendly to offline editing.  Version numbers have been
removed from the filenames, in favor of using an actual version control system
(Git).  

If you're new to Git, [start here] (http://help.github.com/).  Once you've
forked this project on Github and cloned your fork to your own computer, come
back and finish reading this. (Or if you're masochistic enough, you can skip
the clone part and edit directly on the web, one commit per file, if it works
for you.)

All of the scripts and notecards necessary for the updater to function should
be present in the LSL folder of this repository.  Animations, textures, and
other inventory types are not in this repo, and are only available inworld.

Staying in Sync
---------------

This may not be the perfect solution for everyone but for Firestorm users a
simple way to do it would be:

1. Download the github app. (windows.github.com or mac.github.com)
2. Fork the code on Github and clone your fork to your local machine.
3. Open the app and select the branch you would like to work on.
4. Get a copy of the latest updater inside SL.
5. When editing a file in SL, use the "save to hard disk" feature in the
   script editor so you can easily save your work to your local working directory.
   (i.e. on win7 this would be C:\Users\user\Documents\GitHub\OpenCollarUpdater\LSL)
6. Your changes should be immediately reflected in your github app and ready to commit!

Contributing Changes
--------------------

Please submit all changes as Github pull requests.  We've tried accepting
modified scripts inworld, and have burnt out more than one release manager that
way.  It's a nightmare.  So for the sanity of all concerned, Github pull
requests are the *only* way that we will accept modifications to the OC
scripts.

Git might be intimidating for some people, especially those who have only
worked on scripts inside SL.  Please take the time to learn to work with Git
though.  It will be a huge help towards managing the project in a sane way. The
[documentation] (http://help.github.com/) is really pretty good.
