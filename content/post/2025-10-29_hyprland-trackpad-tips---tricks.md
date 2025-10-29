---
title: Hyprland Trackpad Tips & Tricks
date: 2025-10-29T22:57:34+00:00
---

For first time in my life I bought a PC notebook. I didn't even consider to boot in the pre-installed Windows 11 and installed Omarchy right away.

The HP ZBook has a quite good trackpad, even compared to MacBooks, but some things seemed off. No right-click with two fingers, instead it would only work in the lower right corner. And I absolutely hate tapping, I want real clicks.

Turns out, it's not the hardware. It's all configurable in Hyprland. In Omarchy you can find the settings in `.config/hypr/input`, sub-category `input:touchpad`.

Here are some handy options to tweak the settings:

~~~ bash
input {
  touchpad {
    # Enable two-finger clicks for right-clicking
    clickfinger_behaviour = true

    # Disable tapping
    tap-to-click = false

    # Enable natural scrolling
    natural_scroll = true

    # Disable the trackpad while typing (accidental tapping etc.)
    disable_while_typing = true
  }
}
~~~

There is even more like tapping maps, middle button emulation etc. -- you can find all options [here](https://wiki.hypr.land/Configuring/Variables/#touchpad).
