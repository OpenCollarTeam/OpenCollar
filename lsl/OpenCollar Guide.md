Introduction
=========

OpenCollar provides a way for one avatar to give up some measure of control of their SL life to another.  It allows for playing animations, leashing someone, and if you use the [RLV] (http://wiki.secondlife.com/wiki/LSL_Protocol/RestrainedLoveAPI ) extensions, much much more.

While the project is named OpenCollar and most items using it's script-set tend to take the form of a collar, it is in no way restricted to a neck-worn device.  There are rings, jewelry, bracelets and other objects that all fall under the umbrella term 'OpenCollar'.

Most OpenCollar commands can be given either by using the menu (touch the collar to get the menu initially) or by text chat.  In order to prevent text chat commands from accidentally executing on lots of collars at once, they use a prefix of the wearer's initials.  So if Greta Grumpsalot wanted to do the 'nadu' command, she would say 'ggnadu'.

In case of more recent Second Life account names (ie. greta101), the second letter for prefixes would always be 'r' as in 'Resident'. In greta101's case to execute the 'nadu' command, she way say 'grnadu'.


Using Chat Commands
=================

As mentioned above, almost all collar features can be driven with text chat commands, beginning with the wearer-specific prefix.  Assuming the collar wearer is named Greta Grumpsalot, here are some examples.

To leash Greta:
    
    ggleash
    
To make Greta kneel:

    ggkneel
    
To let Greta stand up again:

    ggrelease

One can keep the commands out of open chat by sending them to a different channel.  By default, OpenCollar listens to channel 1, so prefixing commands with '/1' will keep commands hidden from view.  This listening channel is something that is editable on a per wearer basis.

So to leash Greta without anyone seeing the text chat command:

    /1ggleash

Ownership
========

OpenCollar lets you decide who has permission to send commands to your collar.  These people are called "owners".  There's another class of secondary owners, or "secowners", who get more limited access (they can't add other owners, for example). And you can also allow anyone to use a subset of functions of your collar by allowing open access as well, if you so choose.

You can add owners to your collar using the Owners button in the main menu.  That will bring up a submenu for adding and removing people from your owners list.  When you use the menu options, the person you want to make your owner or secowner has to be online and near to you, so that the script can find them and present their name on a button for you to select.  The chat commands do not have this limitation, but you do have to spell your owner or secowner's name exactly (if they are recent SL inhabitants without a last name, this may require the 'Resident' last name)

You can use chat commands for adding and removing owners as well.

To add an owner to the collar (owner does not need to be near or online for it to work)
 
    <prefix>owner <full name>

To add a secowner (secondary owner) to the collar:

    <prefix>secowner <full name>

To allow members of your currently-active group to control your collar:

    <prefix>setgroup
    
This will set the group to your current group.  You may need to remove the collar for this to take effect, just detach it on the ground then reattach it back.

To remove your current owners and return the collar to default settings:

    <prefix>runaway

Control
======

To change the collar's prefix setting:

    <prefix>prefix <letters>
    
When changing the prefix make sure you note the new settings, as all commands will need to be done in the prefix you chose, the prefix is defaulted to the initials of the sub wearing the collar

To change the hidden channel on which the collar listens:

    <prefix>channel <number>
    
The default channel is /1.  The number must be greater than 0.

To show your current ownership settings:

    <prefix>settings

To lock the collar:

    <prefix>lock
    
Locking the collar means that if you remove it, your owner(s) will be sent an instant message saying that you took the collar off.  If you have RLV enabled, locking the collar prevents you from removing it at all.

To unlock the collar:

    <prefix>unlock

The collar can only be unlocked by someone of equal or higher rank than the person who locked it.  So if your owner locked it, a secowner can't unlock it.

Animations
=========

Poses can be activated through the menu or in open chat.

To trigger a menu listing the poses currently in the collar:

    <prefix>pose

To play one of the poses in the collar

    <prefix><animation>
    
Here `<animation>` is the name of one of the animations in the collar, like 'nadu' or 'kneel'.

To stop the current pose:

    <prefix>release

Couples Animations
----------------------------

In addition to the single-person poses in the collar, there are several animations intended for couples.

To trigger the couples animation menu:

    <prefix>couples

You'll then see a list of all couples animations in the collar.  After selecting one, you'll see another list, this one containing the names of all the people nearby.  You can then select the person you'd like to kiss/hug/whatever.

You can also trigger couples animations with chat commands.  To kiss someone, for example:

    <prefix>kiss <name>

You don't have to type out the whole name.  Usually the first few letters are enough for the collar to find the right person.


Leash
=====

An owner, secowner, (or if openaccess has been granted, anyone) can grab a virtual leash attached to the collar and haul the wearer around, so long as they are within chat range of the wearer when they issue the initial command.

To grab the leash:

    <prefix>grab

To pull the collar wearer to you:

    <prefix>yank

To release the leash:

    <prefix>unleash

You can change the length of the leash in meters with the following command:

    <prefix>length <number>
    
For example, `gglength 5` would change Greta's leash length to 5 meters (notice no brackets around the number).  Numbers smaller than 1 and larger than 18 won't work.

To get a leash holder (a hand-holdable attachment point for the leash chain):

    <prefix>giveholder

Updating and Installing Bundles
===============================

On release of new versions you will be automatically issued a scripted updater device. Alternatively you can install the current Beta available at the OpenCollar HQ.

Please make sure when running updates or installations to find a sim with Object Rezzing enabled and a sufficient delay for auto-returns (i.e. use the search to find a 'Sandbox').

1. Find the updating device in your inventory and rez it on the ground. (If you have just received it, it can be located in your Recent Items Tab, in the Objects folder.)

2. Remove your collar and rez it nearby the updating device. Make sure to rez one collar at a time to avoid confusion about which collar is updated and menu pop-up clutter.
 
3. Trigger the menu of your collar either by touching it or using the <prefix>menu command. Go to Help/Debug and click the Update button.
 
4. The collar will pop up a message asking you to verify that you want to update with the nearby updating device.  Click 'Yes'.

5. At this point you will receive a pop-up menu with a web link. Open this link and use the checkboxes to select which features/plugins you wish to update or install into your OpenCollar. Each of these is called a "bundle".

6. Click the "Start Update" button. You can watch the installation progress at the hovering text above the updating device.

7. You will be notified in text chat when your update is complete.  Please do not pick up either device until notified, or bad things(tm) might happen.
