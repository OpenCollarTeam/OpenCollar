# OpenCollar 3.8 is here! - 20121112.1

Hello everybody. The next OpenCollar is finally here.

A few highlights for this release. On the user point of view:

1. The modular updater now has a web interface. To update, just carefully
follow all displayed instructions!

2. Whenever a dialog button has a too long label in current dialog (long
avatar name, long folder name... ), all choices will also appear in the chat
console.

3. \#RLV Browsing system features a new 'Actions' submenu, making it possible
to choose between adding and replacing folders and even un/locking them. Moreover
2 icons before each folder name give more info about the worn status of a folder
and subfolders.

Highlights for addon developpers and collar designers:

1. The link message map has changed a lot. In particular, in the new workflow,
never it will be needed for a command chain to be authentified twice. It is advised
you look at the new template:
https://github.com/SatomiAhn/ocupdater/blob/3.8/lsl/OpenCollar%20-%20plugin%20template.lsl

2. New "touch" helper API. This makes it possible to set different actions on touching
different prims of a collar. Those can be set either through prim descriptions or through
an API similar to that of the dialog helper.

For full release notes, it is possible to have a look at the git commit history here:
https://github.com/SatomiAhn/ocupdater/commits/3.8

Thank you!

Satomi