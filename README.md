### Welcome to OpenCollar

OpenCollar is a set of LSL scripts and related content (such as animations,
sounds, textures, graphics and 3D models) created for SecondLife.  It has many
features, but most are centered on one avatar voluntarily giving some degree of
control to another.

### OpenCollar Needs Your Help

OpenCollar is non-profit and community driven.  Its creators and maintainers
donate their time and talents free of charge.  If you would like to give back,
consider taking a look at our [open
issues](https://github.com/OpenCollarTeam/OpenCollar/issues) and see where you
can pitch in.  You can also join the official OpenCollar group in Second Life
and ask the community there how you can help support the project.

#### Finding your way around this repo

This repository is separated into resources, source code and web queries. The
directory names are self-explanatory and each has a readme attached that tells
about specific details. Resource subdirectories inform which file formats we
work with and point to other free software that can be used to create such
content.

```
./opencollar/

    > res: Resource of creative content.

        > anims: Motions and Animations as .bvh and .avm binaries.
        > models: 3D Models as .dae and .blend binaries.
        > sounds: Sounds as .wav and .aup binaries.
        > textures: Images as .png and .xcf binaries.

    > src: Source code

        > ao: The source code for the animation overrider.
        > Apps: The source code for optional apps!
        > collar: The source code for the collar device.
        > installer: The source code for the package manager.
        > remote: The source code for the remote control HUD.
        > spares: Spares and snippets for research and development.
        > cuffs: Where the cuff source code is.
             > Collar_Plugin: The plugin which should reside in the collar itself.
             > Right_wrist: The scripts that go into the right wrist cuff. This is the main cuff source code.
             > Slave_cuffs: Other cuffs which should not contain the main scripts

    > web: Web queries.
```

#### Licensing Information

Scripts are all under the [GNU General Public License, version
2](http://www.gnu.org/licenses/gpl-2.0).  Other resources are either public
domain or under the [Creative Commons Attribution-ShareAlike 4.0 International
Public License](https://creativecommons.org/licenses/by-sa/4.0/)  For full
details, see the LICENSE file.
