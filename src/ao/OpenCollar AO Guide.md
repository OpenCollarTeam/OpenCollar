# Guide for the OpenCollar Sub AO HUD Animation Overrider + Collar Interface

[Texture: OpenCollar SubAO Help Image]

## Collar Integration

To have the AO intergrated with OpenCollar work you need an OpenCollar Version 3.3 or higher.
Collar Integration allows the primary owner to lock the ao and uses the collar to authorize commands. The AO automaticly detects the collar.

Note: with older collars the owners still can acess the OpenCollar Sub AO menu

## If you need help

Please visit our website for the latest [OpenCollar user-guide](http://www.opencollar.at/user-guide.html). If you need help with the AO functions, read on. You can also join the OpenCollar Chatter group and ask questions there.

## How To Use

Right-click the OpenCollar Sub AO in your inventory and select `Wear`. It should attach itself to some point on your HUD (default is bottom right)

The 4 HUD Buttons: (Top to bottom when at default setting)

1. Main Menu - (square menu sheet) Opens up the SUB AOs menu. (* See Below)
2. Sit Anywhere - Allows you to sit anywhere.  White means on, gray means off.
3. The 'Power' button - Turns OpenCollar Sub AO on and off. White means on, gray means off. When OpenCollar Sub AO is off, it won't override your animations
4. Dock/Hide - (nadu girl) Docks/hides the three buttons. Pressing it again will undock/show the buttons.
  * If the user has collar integration enabled, a menu to select the AO Menu, Collar Menu, Couples Animations, and  HUD Options pops up.  If collar integration is off the menu will default to the standard AO Menu.

## Menus

The SUB AO Main menu: (with collar integration)

* `[AO]` - Opens the default menu for the Animation Overide. (AO)
* `[CollarMenu]` - Opens your collar's menu's.
* `[Couples]` - Opens your collar's couple animation menu to choose an animation.
* `[Options]` - Opens the new 1.7 HUD style/position/order options.

The AO menu: or ` AO `

* `[Help]` - Gives you this notecard
* `[Reset]` - Resets the scripts and ALL custom HUD options
* `[Update]` - Updates the OpenCollar Sub AO when your OpenCollar Sub AO is rezed next to an update orb that the same ownrr as the AO
* `[Lock]` - Locks the OpenCollar Sub AO. When the AO is locked the sub cannot change the settings. Anyone can lock the AO. The AO can only be locked when Collar Integration is active. When the collar is detached the AO will stay locked. The AO is unlocked when the wearer is wearing the collar and uses there safeword.
* `[Unlock]` - Unlocks the OpenCollar Sub AO. Only the primary owner can unlock the AO.
* `[Load]` - Lets you load an animation config notecard. You need to load a notecard after you make changes to it. You can use this to set up multiple animation 'sets' in different notecards, and switch between them
* `[Settings]` - Displays the current settings
* `[Next Stand]` - Cycles to the next 'Standing' animation, or a random 'Standing' animation, based on random/sequential setting (see below). On the random setting, this may end up choosing the same 'Standing' animation that's currently playing
* `[Sit On/Off]` - Selects whether the 'Sitting' animation is played when you sit on an object. Turn this off for vehicles, poseballs, and so on
* `[Rand/Seq]` - Selects whether 'Standing' animations are cycled randomly or sequentially (in the order specified in the config notecard)
* `[Stand Time]` - Lets you change the time between auto-cycling 'Standing' animations. 0 turns off stand auto-cycling
* `[Walks]` - Lets you choose a 'Walking' animation (if the AO has been set up with multiple choices for this animation)
* `[Sits]` - Same as above, for 'Sitting' animations
* `[Ground Sits]` - Same as above, for 'Sitting On Ground' animations
* `[HUD Options]` - Opens the new 1.7 HUD style/position/order options. (Only shows up if collar integration is disabled)

Collar Menu

This is a shortcut to your collar.  It's so you don't have to manually click your collar or type xxmenu.

Couples Animation
This is your standard couples animation menu.  See the collar documentaion if help is needed.

HUD Options

* `[Horizontal]` - Aligns the buttons in a horizontal layout.
* `[Vertical]` - Aligns the buttons in a Vertical layout. It will position the buttons in a horizontal plane when attached to the "top" or "bottom" HUD attach point automatically.
* `[Textures]` - Opens a sub menu to select textures for the buttons.
* `[Tint]` - Shows up when the non-glossy white texture is selected.  Works like the coloring on cuffs/collars. May also reset to default.
* `[Order]` - Allows re-ordering of the buttons. May also reset to default.


## Setup Instructions

This section tells you how to add/change animations.

* If you are wearing the OpenCollar Sub AO, detach it.
* Find the OpenCollar Sub AO in your inventory. If you have multiple OpenCollar Sub AOs, find the right one that you want to edit.
* Make sure you're on land where you can rez objects, and the auto return is several minutes long. If you're not sure, go to a sandbox.
* Press Ctrl-3 to bring up the edit window.
* Drag the OpenCollar Sub AO onto the ground. It should be highlighted for edit.
* On the Edit window, click the 'More' button, then the 'Content' tab. You are now viewing the content's of the OpenCollar Sub AO's inventory. If you have a lot of animations in the OpenCollar Sub AO's inventory, wait a while for this window to finish refreshing.
* Drag the animation(s) you want to add, from your own inventory, into the OpenCollar Sub AO's inventory. Wait for the to animations show up in the OpenCollar Sub AO's inventory. If you take the OpenCollar Sub AO back into your inventory too soon, you may lose animations due to SL inventory issues.
* Find the notecard for the set you want to edit, and drag it from the OpenCollar Sub AO's inventory into your inventory.
* In your inventory, rename this notecard. Call it "My Anims" or something like that. Keep the name small, it needs to fit on a dialog menu button.
* Open up the notecard. You'll see  lines in it that look like the following:

```text
[ Walking ]
[ Sitting ]
```

... and so on. If the notecard was already set up with animations, the lines will look like this:

```text
[ Walking ]MaleWalk1|MaleWalk2|DorkyWalk1
[ Sitting ]CrossLeggedSit|MaleSit1
```

* Find the line that corresponds to the animation you want to add. For example, let's say you're trying to add a new 'Sitting' animation. Find the line that starts with [ Sitting ]
* If the line doesn't have any animations in it, then at the end of the line, type the animation name. If the line already has some animation(s) in it, then at the end of this line, type the | character, and then type/paste the name of your animation. Make sure you don't add any spaces around the animation names. Look at the other lines in the notecard to see what it should look like. Make sure you spell the animation name right. Make sure you have the capitalization right. A good way to do this is to copy the animation's name by right-clicking on it and selecting 'Properties'. Once you are done, it should look like this:

```text
[ Sitting ]CrossLeggedSit|MaleSit1|NewAnimationYouAdded
```

* Repeat the previous step for all the animations you want to add. You can repeat lines if you need to. For example, if you want to add a large number of walks, you can split them up across multiple lines like this:

```text
[ Walking ]MaleWalk1|MaleWalk2|MaleWalk3
[ Walking ]MaleWalk4|MaleWalk5|MaleWalk6
```

Make sure that both lines start with `[ Walking ]`, and the script will combine the specified animations.

* Save this notecard.
* Drag the notecard you just created/saved from your inventory into the OpenCollar Sub AO's inventory.
* Take the OpenCollar Sub AO back into your inventory.
* Wear the OpenCollar Sub AO.
* Click the Menu button on the OpenCollar Sub AO.
* Click the 'Load' button in the dialog menu.
* Click the button that has the name of your new notecard in it.
* Wait for the OpenCollar Sub AO to tell you that it's finished loading the new notecard.
* Your new animations should now be activated. If you added a new walk/sit/ground sit (for example, you added a 3rd walk), you need to select that number on the corresponding menu (click on Walks, then select the 3rd walk).

If you run into any trouble trying to make this work, see my profile picks for instructions on how to report your problems and get help.

## Licensing Information

Please note that although this object allows you full technical permissions, you must still abide by the licensing terms specified below.

All the scripts are provided open source, under the GNU General Public License Version 2.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307, USA.

## Original ZHAO-II Documentation

Based on ZHAO-II
Note: ZHAO-II is not associated with OpenCollar Sub AO in any way. Please do not contact Ziggy or any of his friends/volunteers for support on OpenCollar Sub AO.

[Notecard: READ ME FIRST - ZHAO-II]

## Animation Credits

* Linda Kellie Henson
* [Roenik Newell](http://my.secondlife.com/roenik.newell)
* [Vanish Firecaster](http://my.secondlife.com/vanish.firecaster)
* [Nandana Singh](http://my.secondlife.com/nandana.singh)
* [Nadja Gufler](http://my.secondlife.com/nadja.gufler)
* [Marine Kelley](http://my.secondlife.com/marine.kelley)
* [Antoinette Lioncourt](http://my.secondlife.com/antoinette.lioncourt)
* [Beau Perkins](http://my.secondlife.com/beau.perkins)
* [Darien Caldwell](http://my.secondlife.com/darien.caldwell)
* [Freestyle Adamski](http://my.secondlife.com/freestyle.adamski)
* [Garvin Twine](http://my.secondlife.com/garvin.twine)
* [Gaudeon Wu](http://my.secondlife.com/gaudeon.wu)
* [Ilse Mannonen](http://my.secondlife.com/ilse.mannonen)
* [Madison McHenry](http://my.secondlife.com/madison.mchenry)
* [Stephe Ehrler](http://my.secondlife.com/stephe.ehrler)
* [Twitch Misfit](http://my.secondlife.com/twitch.misfit)
* [Whinge Languish](http://my.secondlife.com/whinge.languish)
* [Creamy Cooljoke](http://my.secondlife.com/creamy.cooljoke)
* [Vasa Vella](http://my.secondlife.com/vasa.vella)
