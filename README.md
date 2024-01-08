# GodotBulletML
An attempt at making BulletML usable in Native GDScript 2. Made in Godot 4.1
With optional 3D Support!!

This depends on [godot_xml](https://github.com/elenakrittik/GodotXML/)

# What's BulletML?
[BulletML](https://www.asahi-net.or.jp/~cs8k-cyu/bulletml/index_e.html) is a markup language created by Kenta Cho to use in Shmup / Bullet Hell Games. As a markup language, it can be used in different engines and parsers.
You can see the specs [here](https://www.asahi-net.or.jp/~cs8k-cyu/bulletml/bulletml_ref_e.html)

# How it works
I wanted to make something different from most other BulletML parsers & runners and try to keep memory footprint to a minimum. 
- An Emitter (GBML_Emitter) parses the BulletML File into a custom object (BulletMLObject) and reference things only when needed.
- The Emitter is Registered to a GMBL_Runner singleton that managest most of the execution.
- The Runner processes every active bullet and action each frame, checks for collisions via the Physics Server, and lifetime of the bullet
- The Runner runner also keeps an list of all the sorts of bullets spawned by which emitter, which uses it to pool the bullets.
- The Runner is also in charge of Spawning and Toggling (pooling) bullets, which will reference the Emitter's bullets and their data.

# How to Actually Use
The setup should be simple for both 2D and 3D.
- Set up your bullet objects.
    - Ideally these are a single-node affair, prefferably what's going to be rendered.
    - Set the shape of the the collider (no visuals, sorry!)
- Setup a scene.
- Either have GBML_Runner have be auto-loaded, or in the scene.
- Add your GBML_Emitter objects in their respective locations
    - Set your BulletML File to Parse (res://.../file.xml)
    - Set your bullets. The label will be referenced when a bullet of the same label (in the xml file) is fired.
        - ie `<bullet label="FireA">` will look for a bullet labeled "FireA" in your emitter's Bullet List.
    - Set up your targets and the active target number (optional)
- Test and Have Fun!


# TODO
- Add Param Support.
- **A lot.** Turns out this is actually quite incomplete. Feel free to PR.
