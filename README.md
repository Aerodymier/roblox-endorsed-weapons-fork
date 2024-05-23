# Roblox Endorsed Weapons Fork
This is a fork of Roblox's "Endorsed Weapons Kit".
It includes some bug/error fixes from the original kit, as well as new features which does not exist in Roblox's version.

If you wish, you can get the **original** kits from here:

Creator Hub page: https://create.roblox.com/docs/resources/weapons-kit

-> Pistol: https://create.roblox.com/store/asset/4842197274/Pistol

-> Submachine Gun: https://www.roblox.com/library/4842212980/Submachine-Gun

-> Grenade Launcher: https://www.roblox.com/library/4842201032/Grenade-Launcher

-> Rochet Launcher: https://www.roblox.com/library/4842186817/Rocket-Launcher

-> Sniper: https://www.roblox.com/library/4842218829/Sniper-Rifle

-> Shotgun: https://www.roblox.com/library/4842215723/Shotgun

-> Auto Rifle: https://www.roblox.com/library/4842207161/Auto-Rifle

-> Crossbow: https://www.roblox.com/library/4842204072/Crossbow

-> Railgun: https://www.roblox.com/library/4842190633/Railgun

# Installations
To get the forked model, you can follow these instructions:

## Instructions for Roblox Studio
Get the model here: https://www.roblox.com/library/8165353230/WeaponsSystemFork

Go to Roblox Studio, open a place and open your toolbox. Then go to the second tab and select "My Models". Drag the model you've taken from Roblox website to viewport or explorer. Place the folders to their respective places. For example, if a folder is under a model named "ReplicatedStorage", put it to ReplicatedStorage **without** including the model instance. If you are still unsure about the process, check out my video about it (https://youtu.be/5kGnpnJnUio) or inspect the place located in source code's PlaceBuild folder. Download and open it for an example.

You can also download the model file directly from "Releases" page.

## Instructions for Rojo Sync
Clone the repository, you will have all models as rbxmx and all scripts with their proper rojo formatting.

ServerStorage has TagList tags for weapons.

# Usage
Once you install it, it's done! Use the guns from Roblox's kit for other guns. Delete WeaponsSystem folder inside of them after you insert these guns. Alternatively, you can use your own guns, however do not forget to set them up like how Roblox has theirs set up. You should consider having Tag Editor (https://www.roblox.com/library/948084095/Tag-Editor) for custom guns so you can tag them as "WeaponsSystemWeapon".

If you have more questions, you can open an issue.

## Adding custom guns
Video tutorial: https://youtu.be/CO5inulxh6Y

Roblox has already done a really good job here with this page: https://developer.roblox.com/en-us/articles/weapons-kit
There's everything about configuration options in this page.

# Configuration
The configuration options in https://developer.roblox.com/en-us/articles/weapons-kit are here as well but there are some extras:

## Global configuration options
These are located in WeaponsSystemFolder's Configuration folder which should be in ReplicatedStorage.

1) You can set "friendly fire" which allows or disallows players on different teams to damage each other.

    > This is called FriendlyFireEnabled and has the value of **false** by default which disables friendly fire.

2) You can set if the weapon camera will stay on when you unequip the gun. This shift-lock cam might be helpful in some cases.

    If this property is set to **false**, the DisableCam script will get activated and if player hits the F key (and other appropriate buttons for console and mobile) the camera will get disabled.

    > This is called UseCamOnlyWhenEquipped and has the value of **true** by default which disables the camera when player unequips the gun.

## Gun configuration options
These are located in the Configuration folder of your specific weapon.

1) You can set a headshot multiplier for your guns which will multiply the gun's damage if player hits the enemy's character head.

    - Characters need to have their character head part named "Head" for this to be compatible.

    > If you want to set a headshot multiplier, put a NumberValue in your gun's Configuration folder, name it **HeadshotMultiplier** and set its value to the multiplier amount you want. Keep in mind that negative values and 0 might have side effects. Defaults to **1** which disables headshot multiplier.

## Client configuration options
This is a feature which is not present in original version, sometimes you might want to change the player walk speed in game and if this change is not done, the gun script will overwrite the walk speed you set for player (guns have walk speed settings for both aiming and sprinting, also the normal walk speed gets set when player stops interacting with the gun). There are some more configuration options and all of them are listed here:

These are located in ClientDefaultValues which is in WeaponsSystem folder's Assets folder. This folder gets parented to the player object once player joins, so that's where you can change these values from.

1) SprintingWalkSpeed [NumberValue]: The walk speed which will get applied when the player is sprinting.
2) NormalWalkSpeed [NumberValue]: The walk speed which will get applied when player stops interacting with their gun.
3) ZoomWalkSpeed [NumberValue]: The walk speed which will get applied when player starts zooming with a gun.
4) FieldofView [NumberValue]: The field of view which will be the base field of view for guns.

# Issues
I'd rather seeing all issues with this gun kit fork with GitHub's issues feature and not with anything else. I will try to take care of them as much as possible.
