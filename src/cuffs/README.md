
OpenCollar Attachment Configuration
=============


[Build an Attachment that Supports Chains]
======


- Create a visual representation of your Object.
- This could be either a Mesh or a Prim build (Rigged mesh is not supported).
- Rez the Object to the ground
- create a prim (cube) for each Chain Attachment Point you want to support.
- Name the newly created Prims according the name-list (see Naming Guide.md for details)
- First select the Prims, then select the Object and click the Link button.
- Make sure the Prims are highlighted blue and the visible Object is highlighted yellow (root)
- Check “Edit Linked” in the build menu and select the Prims.
- Go to “Texture” tab
- Click on the Texture and select “Transparent”
- Uncheck “Edit Linked”
- Add your poses notecard (If applicable)
- Add the cuff configuration notecard
- Add the oc_cuff script to the object


[oc_cuff_pose]
======

This script is necessary in any cuff that does NOT use the NoPose flag. This script is responsible for the cuff pose animations, and for sending out the collar pose chains if relevant


[RLV]
======


- On the pose restrictions line, do not put the @ symbol, otherwise the restriction string is written out as it would be normally
- PoseRestrictions:touchall=n,fly=n
