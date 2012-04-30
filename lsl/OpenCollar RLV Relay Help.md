Table of contents
-----------------
1. Introduction

2. User help
    1. Menu buttons
    2. Chat commands

3. Technical information for RLV scripters
    1. Features and specifications
    2. Caveats
    3. Want more fun?


*****

1. Introduction
===============

Restrained Love Viewer API (Application Programming Interface) is a Second Life viewer feature that allows rezzed objects that you own to speak to your viewer and ask it to perform certain actions (teleporting, force-sitting or stripping the avatar) or toggle certain restrictions (such as on chat or clothing). This is limited to *your* objects, however.

A Restrained Love Viewer relay, or just "relay", is  a script that listens for in-world object commands and transmits them to your viewer so that you can be controlled by objects belonging to *other* people. Of course, the task of the relay is not only to transmit such commands, but also to manage which objects should be allowed or not, and to keep track of the applied restrictions.

OpenCollar includes such a relay. The relay included in OpenCollar has a few particularities:

- In contrast to most older relays (prior to 2009), it allows several concurrent sources to communicate with your viewer and lock your relay.

- It has many access control options (both basic and more complicated modes, along with blacklists and whitelists).

- It optionally allows release from restrictions via safewording.

- It is integrated with the collar system in that (1) sources owned by owners are automatically accepted by the relay, and (2) owners can force the relay mode above a specified level of acceptance.


2. User help
============

1.1. Menu buttons
-----------------

(Don't be surprised if some of these buttons aren't always displayed, since, depending on the context, irrelevant ones are automatically hidden.)

In the main dialog:

* Auto: the relay accepts every future request (except from blacklisted devices).

* Ask: the relay asks before accepting future requests (except from whitelisted or blacklisted devices).

* Restricted: the relay rejects every future request (except from whitelisted devices and devices already controlling you).

* ( )/(*)Playful: enables/disables automatic acceptance of non-restraining commands (combines with the previous modes).

* ( )/(*)Land: enables/disables automatic acceptance of commands from devices belonging to the sim landowner.

* ( )/(*)Safeword: enables/disables the possibility to escape restriction by use of a safeword.

* Grabbed by: shows the list of devices currently controlling your avatar, and the list of restrictions enforced.

* Pending: shows the request dialog, in case there are pending requests.

* Help: gives this notecard.

* Safeword: clears all restrictions; equivalent to typing "[initials]relay safeword".

* Access lists: opens the access list management dialog, for removing trusted or banned sources.

* MinMode (owner only): pops up a submenu in which a primary owner can set minimal function levels for the relay. If the owner chooses the Restricted option here, for instance, the sub cannot go "under" it by disabling the relay completely, but can choose between Restricted and the options "above", namely Ask and Auto; while if the owner chooses the highest level, Auto, it may not be changed and neither Restricted nor Ask is available to the sub. Likewise, if the "lower" settings with safeword, not playful, and landowner not trusted are set in MinMode, they can be changed by the sub; but if the owner dictates that the safeword cannot be used, that the sub must be playful, and/or that landowner must be trusted, the sub cannot change these settings.

In the request dialog, which will pop up in Ask mode when an RLV source tries to lock the relay:

* Yes: accept this command (and other commands from the same device until unrestricted).

* No: rejects this command (and other commands from the same device in the following seconds).

* Trust Object: same as Yes, but adds the object to the whitelist.

* Ban Object: same as No, but adds the object to the blacklist.

* Trust Owner: same as Yes, but adds the owner of the object to the whitelist.

* Ban Owner: same as No, but adds the owner of the object to the blacklist.

* Trust User: same as Yes, but adds the avatar using the object to the whitelist.

* Ban User: same as No, but adds the avatar using the object to the blacklist.


1.2. Chat commands:
-------------------

* [initials]showrestrictions: shows the list of restrictions to which the wearer is subject, and the devices issuing these.

* [initials]relay [ask/auto/restricted/off]: toggles the selected mode.

* [initials]relay playful [on/off]: toggles playful submode.

* [initials]relay land [on/off]: toggles landowner submode.

* [initials]relay safeword [on/off]: toggles safewording.

* [initials]relay safeword: safewords.

* [initials]relay minmode [ask/auto/restrcted/off]: sets the minimal basic mode.

* [initials]relay minmode [playful/land/safeword] [on/off] (owner only): sets the minimal submodes.

* [initials]relay getdebug: starts relay debugging, i.e. forwards all relay chat to the person issuing this command

* [initials]relay stopdebug: stops relay debugging


3. Technical information for RLV scripters
==========================================

2.1. Features and specifications
--------------------------------

As an ORG (Open Relay Group) relay, this relay conforms to
[this specification](https://wiki.secondlife.com/wiki/LSL_Protocol/Restrained_Love_Open_Relay_Group)
- the [basic relay specification version 1.100](https://wiki.secondlife.com/wiki/LSL_Protocol/Restrained_Love_Relay)

- the [ORG additional requirements version 0003](https://wiki.secondlife.com/wiki/LSL_Protocol/Restrained_Love_Open_Relay_Group/ORG_Requirements)

- and to one optional "x-tension", [who, version 001](https://wiki.secondlife.com/wiki/LSL_Protocol/Restrained_Love_Open_Relay_Group/who)

In particular, this means that this relay will understand relay commands using a wildcard "ffffffff-ffff-ffff-ffff-ffffffffffff" instead of the avatar key, allowing efficient scanning and zone effects.

Also, through the x-tension who, this relay understands the meta-command !x-who, which allows RLV sources to specify who (which avatar) is now using the source to grab the relay. This information is reported in the Ask dialog prompt and can be used by the wearer to decide whether to accept being locked, and also maybe to blacklist or whitelist the avatar using the source.

2.2. Caveats
------------

This script uses a lot of memory, and even more when it has to decompose and analyze relay commands. Moreover, this relay manages several RLV sources (an arbitrary number of them) from only two scripts, which makes things even worse. We took great care in optimizing it the best we could, but it is not impossible that a stack-heap collision will still occur. If that happens:

- To make your relay work again, you will have to reset the script using the Tools menu of your viewer (alas, a script that crashed cannot be reset by another script).

- We would be glad if you could tell us where and how the crash happened, and report your incident on the [OpenCollar bug tracker](http://code.google.com/p/opencollar/issues). Any other bug in the relay or issue with the documentation should be reported there as well.

Also, due to the way RLV works, having several RLV sources managing from a single script (and hence a single prim) can trigger unexpected results. For instance, the command @getstatus would report all restrictions set by the collar, instead of just those set by the source sending the command. This is not something we can fix unless we restrict the relay to a single source (which would be a shame!) or unless we use a multiprim approach, which would be highly impractical in the OpenCollar context.

Some other bugs might arise, related to contradictory commands, restrictions and exceptions from different sources. This category of bugs can sometimes be mitigated in some way by using scripting tricks, so if you notice one of this kind please report it on the bug tracker so we can see if something can be done.

2.3. Want more fun?
-------------------

If you are interested in relays with advanced features, there is a HUD version of this relay (also open source), implementing even more fancy features from ORG. Look for "Satomi's Multi-Relay HUD" on the SL market place or grab it at the OpenCollar Temple if you want a copy of that relay.

If you want to to discuss relay features, you can comment on the [ORG wiki pages](https://wiki.secondlife.com/wiki/LSL_Protocol/Restrained_Love_Open_Relay_Group), and/or join the Restrained Love Open Relay Group in SecondLife.