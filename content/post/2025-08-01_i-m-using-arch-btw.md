---
title: I'm using Arch btw
date: 2025-08-01T20:36:11+00:00
---

Well, that escalated quickly. One week ago I would have said never to touch Arch (except SteamOS). Nothing personal, it's just that I am primarily a Mac guy and never stayed with Linux that long. I really enjoyed Pop!_OS, System76 created a really nice flavour of Ubuntu, but it's still Ubuntu, so packages are often out of date and you always have to rely on custom repos or other means to get current versions. 

With Arch and its rolling release model the latest versions are almost immediately available. Sounds good? Of course there's a catch: breaking changes are also immediately available. Updating all dependencies can break many things at once and that can get very annoying pretty fast. From what I've heard the situation improved over the years, so if you're doing nothing too crazy, it should be okay.

A few days ago I discoverd [Omarchy](https://omarchy.org/) from DHH (creator of Ruby on Rails). He created an opinionated Arch setup for developers. Just install Arch via `archinstall` and run Omarchy's installation script and you're mostly done. Omarchy ships with Hyprland, a really efficient and fast tiling Wayland compositor that doesn't look like it's from the 1980s. There's all sorts of eyecandy, everything is customizable and there are also many cool plugins.

Setting up Hyprland and plugins on your own can be daunting task and a very time-consuming one as well. Omarchy to the rescue! It ships with a really good default configuration and is perfectly useable from the get-go, but that's only the beginning of the journey. DHH considers Omarchy a starting point for you own configuration and therefore made it very easy to customize the configuration for your needs. There is even a special Omarchy configuration tool for switching the global color theme (for Hyprland, Alacritty, Neovim etc.) or setting up fingerprint sensors for biometric authentication (should be working very well with Framework devices). 

Omarchy also installs many useful terminal and GUI programs, like Alacritty (terminal emulator), Neovim, Spotify, Lazygit, `fd` etc. All GUI programs are mapped to intuitive hotkeys, f.e. `SUPER` + `M` for Spotify or `SUPER` + `B` for the browser (Chromium by default). `SUPER` + `Space` displays the application launcher (like a simple version of Spotlight or Raycast). There's much more for controlling the current window size to move the focus, switch virtual desktops, fullscreen etc.

All hotkeys are easily customizable in `.config/hypr/bindings.conf`. You don't like Chromium? Just install your favorite browser with the Pacman (Arch's package manager) and update the variable `$browser` in the Hyprland config. That's it. The browser is also used for webapps mapped on hotkeys, ChatGPT f.e. is mapped on `SUPER` + `A`. 

A little example to change the music hotkey to Apple Music as webapp (there is no native Linux version).

~~~ bash
bindd = SUPER, M, Apple Music, exec, $webapp="https://music.apple.com/de/library/recently-added?l=en"
~~~

Pressing `SUPER` + `M` now opens a browser window without address bar etc. with the Apple Music webapp. Nice. I also changed `SUPER` + `A` from ChatGPT to Theo's awesome [T3.chat](https://t3.chat/).

That's for from all that Omarchy offers, but would be bit much to list every feature in this blog post. Omarchy has a pretty good documentation with many useful tips, troubleshooting advice etc. The troubleshooting section even has advice why I couldn't get Bluetooth working on my Minis Forum UM760 (the included MediaTek chipset has no Linux driver).

## TL;DR

If you're not afraid of Linux and want a decent base installation of Arch with many developer-focused feature, give Omarchy a chance!

### Updates

1. 2025-08-05: Omarchy 1.11 brings a new Hyprland config file structure and `bindd` command. I updated the file path for key bindings and the example for Apple Music accordingly.
