---
date: 2024-10-07T20:00:00+02:00
title: "Fixing no A2DP with Bluetooth headsets on Linux"
draft: false
---

**Please beware that the following instructions are suitable for media consumption only! After this changes your headset can't make any calls without a dedicated microphone until you undo them.**

Having trouble with the audio quality of your Bluetooth headset on Linux? It sounds awful if you're listing to music and videos? Well, congratulations, I had the same problem and found a solution. At least if you're only into listening and won't make any calls. This works on Ubuntu or Ubuntu-based distributions like Pop!_OS or any other distribution that relies on Blue Z and Pipewire/WirePlumber for Bluetooth audio.

## What's wrong?

Bluetooth has different profiles for different things. If you want to make a call, your headset will switch to the Hands-free Profile (HFP). The available bandwidth will be shared for audio input and output and different audio codecs will be used. It's good for calls, but really shitty if you want to listen to music. The headset needs to switch to A2DP (Advanced Audio Distribution Profile) for good sound quality. This should happen automatically and HFP should only be active, if you're making a call. I had never trouble on macOS or Windows with this, but I'm trying Pop!_OS now. It worked for a few days, but today the headset would only connect with the HFP and streaming music or watching videos was as pleasant as dental treatment with a power drill.

Many searches later, I found out that WirePlumper (the session manager for the Pipewire multimedia framework) has some bugs that will trigger HFP on BT headsets even if there's no call. That's pretty annoying but at least somewhat easy to solve. There's a [solution in the Arch Linux Wiki](https://wiki.archlinux.org/title/Bluetooth_headset#Disable_PipeWire_HSP/HFP_profile), but it needs some modifications for Ubuntu-based distributions.

## The solution

First you need to create a directory path in your home directory:

~~~ sh
mkdir -p ~/.config/wireplumber/bluetooth.lua.d/
~~~

This will create an directory that allows you to override the default WirePlumper Bluetooth config without overwriting the original file.

Now copy the original config to the overwrite directory:

~~~ sh
cp /usr/share/wireplumber/bluetooth.lua.d/50-bluez-config.lua ~/.config/wireplumber/bluetooth.lua.d/
~~~

You can now edit the file in the override directory.

Beware that the original instructions from the Arch Linux Wiki contain a conf file, but at least with Ubuntu (and Pop!_OS) the config file is written in lua, so it's a completely different syntax.

Look for `bluez5.roles` -- it should be commented out. I would recommend not replace the comment and just put the following line below. It's easier to undo if something goes wrong or you need to enable HFS.

~~~ lua
["bluez5.roles"] = "[ a2dp_sink a2dp_source ]"
~~~

Save the file and restart the Bluetooth service:

~~~ sh
sudo systemctl restart bluetooth
~~~

Now reconnect your device and A2DP should be working fine.
