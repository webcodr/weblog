---
title: Fix Omarchy Gaming (Vulkan)
date: 2025-10-31T21:48:59+00:00
---

After setting up my new notebook, I wanted to try some games on Steam. Works like a charm on my mini PC with Omarchy, but not this time. After starting a game, it takes a few seconds and nothing, the game silently crashes.

After fiddling and searching around, Proton logging etc., still no cause in sight. Then I tried Doom 2016 and it worked! But why? Doom starts with an OpenGL renderer, after switching to Vulkan it behaves like the other games. So there's something wrong with Vulkan?

Vulkan Tools (Arch package `vulkan-tools`) to the rescue! After running `vulkaninfo` it became pretty clear that something important was missing: the Radeon Vulkan driver. No driver, no Vulkan. No Vulkan, no Proton ...

Thankfully it's easy to fix, just install the missing packages:

~~~ bash
sudo pacman -S vulkan-radeon mesa mesa-vdpau lib32-vulkan-radeon lib32-mesa
~~~

It should work immediately after the installation. There's already a GitHub issue with a pull request to solve this, but it's open for a weeks now and it's not clear, when the fix will be merged and released.

I don't know why it's no problem with my other PC, but I have installed Omarchy the old way on this machine (Arch Install and the Omarchy setup script). My best guess is that the bug was introduced with Omarchy's ISO setup.

## How does it run?

Well, that Ryzen AI MAX+ 390 is an absolute beast. Doom 2016 runs with over 100 fps with max settings on the internal display (2880x1800) and still far beyond 60 fps in 4K on my main monitor. Just don't use fullscreen mode, it flickers like hell (known problem of Doom 2016 with the Vulkan renderer).

The HP ZBook Ultra no gaming notebook, but it has a really powerful APU and is still a quite compact and light device on the level of a 14" MacBook Pro. I don't want a 250 W 4 kg behemoth of a notebook.
