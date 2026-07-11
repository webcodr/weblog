---
title: Find things even faster with srchr
date: 2026-07-05T20:28:50+00:00
---
Inspired by my last post about `rgp` and `fdp` I got the idea to combine both into a more powerful and easier tool called `srchr`.

It's a TUI written in Rust and uses similar or the same libraries as `rg`, `fd`, `fzf` and `bat`, but in one package. There are no external dependencies and it comes for macOS, Linux and Windows in aarch64 and x86-64.

Currently `srchr` is not available via package managers, but there's an installation script:

~~~ sh
curl -fsSL https://raw.githubusercontent.com/webcodr/srchr/main/install.sh | sh
~~~

I will also publish `srchr` on Homebrew, the AUR and perhaps some other package managers.

Beware, it's still under development and the UI is functional, but not finished yet. At the moment there is just a hardcoded Tokyp Night inspired color theme, but this will also change in the near future.

[srchr on GitHub](https://github.com/webcodr/srchr)

### Update

It's now available on Homebrew for macOS and Linux!

~~~ sh
brew install webcodr/tap/srchr
~~~
