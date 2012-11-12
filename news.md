# OpenCollar 3.8 is here! - 20121112.1

Hello everybody. The next OpenCollar is finally here.

A few highlights for this release. On the user point of view:

1. The modular updater now has a web interface. To update, do as usual, but
instead of directly choosing bundles, click the link on the popup and select
bundles on the web page instead.

2. Dialog button labels are not shortened anymore. Whenever there is one button
with a too long label in current dialog, all choices will also appear in the 
chat console, prefixed by numbers. This means in particular you can now add 
owners having long names directly from the menu and that you do not need to
shorten your animation names or #RLV-shared folders names anymore.

3. The #RLV Browsing system is now more complete. For instance it makes it
possible to choose between adding and replacing folders. You can also un/lock 
folders. All possible actions on a folder are now located in the "Actions"
submenu in the menu of that folder. Moreover now 2 icons before each folder
name gives more info about the status of a folder. One icon for items directly
in the folder, the other for the whole subfolders tree. Each icon has 4 states
for empty/unworn/partially worn/totally worn. 

Highlights for addon developpers and collar designers:

1. The link message map has changed a lot. In particular, in the new workflow,
never it will be needed for a command chain to be authentified twice. If you want
to make plugins, it is advised you use the new plugin template, located at this URL:
https://github.com/SatomiAhn/ocupdater/blob/3.8/lsl/OpenCollar%20-%20plugin%20template.lsl
A few noticeable changes: SUBMENU and COMMAND_NOAUTH should not be used anymore,
for instance.

2. In relation to point 2 above, a consequence is that when sending messages to
the dialog helper, a plugin does not have to check label lengths anymore (or even 
the prompt length).

3. There is now a "touch" helper API. This API makes it possible to set different
actions on touching different prims of a collar. There are actually 2 ways of making
use of it: either by changing the prim descriptions so that touching the prim triggers
the action written in description, or have a plugin request for the next touch action
to be reported to it, associated with some random UUID, in a similar way dialog clicks
are reported when using the dialog helper.


For full release notes, it is possible to have a look at the git commit history here:
https://github.com/SatomiAhn/ocupdater/commits/3.8

A human-readable summarized changelog might be coming later.



Thank you!

Satomi