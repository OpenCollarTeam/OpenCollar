 
OpenCollar Attachment Configuration


-[Build an Attachment that Supports Chains]-

- Create a visual representation of your Object.
- This could be either a Mesh or a Prim build (Rigged mesh is not supported).
- Rez the Object to the ground
- create a prim (cube) for each Chain Attachment Point you want to support.
- Name the newly created Prims according the name-list (see Chain_Attachment_Names.pdf for details)
- First select the Prims, then select the Object and click the Link button.
- Make sure the Prims are highlighted blue and the visible Object is highlighted yellow (root)
- Check “Edit Linked” in the build menu and select the Prims.
- Go to “Texture” tab
- Click on the Texture and select “Transparent”
- Uncheck “Edit Linked”
- Add the oc_Attachment script (to the root prim)
- (optional) add “nohide” in the description of all prims that should not hide/unhide

-[Collar Attachment Points]-

The collar can have up to 4 chain attach points. They are created the same way the other attachments are.



-[Additional Lockguard and Lockmeister chain attachments]-

In order to keep the clipping of the chains with the body to a minimum, there are additional attachment point names for Lockguard and Lockmeister that are not in the official Documentation. Because of that they will not be used by most of the Furniture.

The attach point names can be mixed, so the furniture could send a Lockguard command with the Lockmeister attach point name and it would work. 
It is not recommended to do that!



-[Attachment Poses]-

In order to use Attachment poses, you need to create a Notecard. The sub-menu name will be the name of the Notecard you creates. Move the Notecard and the Animations into the Attachment, next to the oc_Attachment script.
Inside the Notecard you need to add a line for each Animation.
The Syntax is as follows:

Name: <Pose Name>

You can name the pose as you want. But be aware that there can be only 11 letters shown in the Dialog.

Anim: <Animation Name>

The name of the Animation.

Chains: <Chain Config>

Chain Configuration: A list of chain attach points where the chain should start and stop.

Restrictions: <RLV-Commands without the “@”>

A comma separated list of RLV-Restrictions that will be applied when the Pose is started. 
(There is a special command that can be used: “move” will block movement)

Syntax of the Chain Configuration:

startpoint=endpoint~startpoint=endpoint…

Empty lines and Lines beginning with # will be ignored.

Example Config:

Name:Belt
Anim:cuff-belt2
Chains:illac=lbelt~irlac=rbelt~iluac=bbelt~iruac=bbelt~bluac=bruac
Restrictions:touchall,showinv,viewnote,viewscript,viewtexture,edit

Name:Pinion
Anim:cuff-pinion
Chains:bluac=bruac~bruac=bbelt~bbelt=bluac~fluac=fllac~fruac=frlac~bllac=lbelt~brlac=rbelt
Restrictions:touchall,showinv,viewnote,viewscript,viewtexture,edit

Chain Config Example:

rlac=llac~ruac=luac

That would spawn a chain from the lower left arm cuff to the lower right arm cuff and another chain from the right upper arm cuff to the left upper arm cuff
(see Chain_Attachment_Names.pdf for a full list of possible chain-points)


Caveats: 

There can be only one chain starting from an attach point, but there can be several chains end at the same Chain point.

Additional Notecard Settings:

IgnoreHide:<value>

When value=1, ignore hide command from the Collar-plugin. (default is 0)

DefaultHide:<value>

When value=1, automatically hide the item. Only works when IgnoreHide is 1 (see above).

Button:<Button Name>

Add a Button to the Devices menu. A Submenu will be created with the same name than the notecard in the attachment. Inside this Submenu there will be the new Button.


-[Link Messages]-

-Send by oc_attachment

The oc_Attachment script will send some Link Messages with an integer of -1000 while working.
The string will be like that:

hide=<value>

value is 1 when the attachment is hiding, otherwise it is 0

restriction=<name>=<value>

If there is a restriction applied in the oc_rlvsuite (new version only) then this message will be send. Value is eighter 1 (restriction activated) or 0 (restriction deactivated)

menu=<Notecard Name>|<Button Name>

This message is send when a custom button, inside devices menu, was pressed.

-Received by oc_attachment

The script also listens to Link Messages with the integer set to -1000. The following commands are possible:

dohide=<value>

Hides/Shows the attachment. (1=hide 0=show).

dolock=<value>

Locks/Unlocks the attachment (1=lock 0=unlock)

doPose=<Notecard Name>|<Pose Name>

Start a pose specified in the Notecard.


-[Collar Poses]-

In order to see chains when a Pose of the Collar is running, you also need to create a Notecard named “Collar Poses” and put it into the root-prim of the Collar.
Inside this Notecard, you need to add all the names of the animations you want to have chains.
The syntax is as follows:

Anim:Animation Name
Chains:Chain Configuration
Restrictions:move,tploc,tplure,tplm

Animation Name: The name of the Animation
Chain Configuration: The list of chain-points (see Attachment Poses)
Restrictions: Restrictions that will be applied when the pose is active. 
(The special restriction “move” is also useable here. It will prevent the wearer from moving arround)
