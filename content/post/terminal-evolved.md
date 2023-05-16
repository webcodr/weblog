---
title: Terminal evolved
date: 2023-05-15T19:22:14.215Z
---


I﻿ always saw myself as a casual user of the terminal. I preferred zsh with the Prezto framework within in iTerm 2 with tabs and that's about it. No more! A colleague of mine introduced me to kitty as terminal emulator, together with tmux and Neovim. That's a lot to swallow. I was never a fan of the vi/vim user experience and more of a mouse guy. Well, what should I say? It's awesome if you're getting used to it. Let me explain ...

## JFYI

kitty, tmux and nvim are available in Homebrew on macOS and should be also available in your favorite package manager on Linux. 

Be aware, that most examples contain some macOS-specific settings marked with corresponding comments, as I am a Mac user.

## kitty

iTerm 2 is a pretty good terminal emulator with many features and way better than Apple's sorry excuse of a terminal. To be fair, the macOS terminal app has gotten better over the years, but it still lacks essntial features like true color support. As good as iTerm 2 is, there's one catch: iTerm 2 is slow. GPU-accelerated alternatives like kitty render much faster. Don't get me wrong, iTerm 2 is no slouch and works well, but if you're on the way to a terminal power-user, you will notice it. Switching between tmux windows is much faster in kitty or other terminal emulators like Alacritty. The later is really nice app, but unfortunately has some trouble with macOS key bindings within tmux and I found no easy solution to that. Kitty works out of the box.

### Taming the kitten

Kitty's configuration is very well documented, but can be overwhelming. There are hundreds of options to explore. One of the most important is the font. Grab yourself a [nerd-font](https://www.nerdfonts.com/), add it to your OS and specify the font family. I'm using "Hack Nerd Font Mono" for this example. Just open your kitty config in `~/.config/kitty/kitty.conf` and add the following: 

```toml
# Replace with your preferred font
font_family			Hack Nerd Font Mono 
bold_font			auto
italic_font			auto
bold_italic_font	auto
# Replace with your preferred font size in points
font_size			17.0 
```

Save and reload the config via menu bar. Enjoy!

Now that's out of the way, how about some comfort features?

```toml
# Set how many lines the buffer can scroll back
scrollback_lines 10000 

# Auto-detect URLs
detect_url yes
# Open URLs with ctrl + click
mouse_map ctrl+left press ungrabbed,grabbed mouse_click_url 

# Copy the mouse selection directly to the clipboard
copy_on_select yes 
# Paste on right click
mouse_map right press grabbed,ungrabbed no-op
mouse_map right click grabbed,ungrabbed paste_from_clipboard

# Enable macOS copy & paste via CMD + c/v
map cmd+c copy_to_clipboard
map cmd+v paste_from_clipboard

# Jump to beginning and end of a word with alt and arrow keys (macOS)
map alt+left send_text all \x1b\x62
map alt+right send_text all \x1b\x66

# Jump to beginning and end of a line with cmd and arrow keys (macOS)
map cmd+left send_text all \x01
map cmd+right send_text all \x05

# Nicer titlebar on macOS
macos_titlebar_color background

# Make vim the default editor for the kitty config
editor vim
```

Want some color? No problem, there are hundreds of themes available just a Google search away. I prefer [Catppuccin Macchiato](https://github.com/catppuccin/catppuccin), but choose what ever you want. kitty config files support includes, so it's easy to add a theme:

```toml
include ./theme.conf
```

Add put the file `theme.conf` in the same directory as the kitty config and paste your theme of choice into the file.

## tmux

So, what the hell is tmux? If you need a terminal, tmux will be one of your best friends. Did you ever run something complex on the shell and accidently closed the terminal window or something similar happened during a SSH session? It sucks. 

tmux sessions to the rescue! A session will be open until you close it, so even if your internet connection breaks down during a SSH session, nothing will vanish. Just connect to the server again and re-join the tmux session. Everything will be as you left it. 

Just type `tmux new` or if you want to give the session a name `tmux new -s my_new_session` . Of course tmux can handle multiple sessions. To list all open sessions use `tmux ls` and to join a session type `tmux a -t session_name` . 

After opening a new session, tmux will display window 0. Need more windows? No problem. Need a window inside an window? No problem, they are called panes. Windows can be split in horizontal or vertical panes, as many and wild as you like.

Inside a tmux session you can trigger commands via a so-called prefix key following one or more keys to tell tmux what you want to do. The default prefix key is `ctrl + b` . To split your current window into two horizontal panes press `ctrl + b` followed by `%` , for a vertical split use `ctrl + b` and `"`.

To close a pane, just exit the shell of the pane with `exit`. You can switch panes with `ctrl + b` followed by an arrow key in the corresponding direction.

Our new best friend `ctrl + b` is not the most intuitive key combination. I recommend using `ctrl + a` and map the caps lock key to ctrl (pro-tip: macOS can do this for you without tools or customizable keyboard firmware). It's way faster and easier to press. Of course, you can map what ever key combination you, just beware of conflicts with other combinations like `cmd + space`. 

To change the command key, go to your tmux config in `~/.tmux.conf` and add the following lines:

```toml
unbind C-b
set -g prefix C-a
bind-key C-a send-prefix
```

This unbinds `ctrl + b` and sets the prefix key to `ctrl + a`. To reload the tmux config inside a session use `tmux source-file ~/.tmux.conf`. 

### More? More!

There is much more you can do. Here are some recommendations.

```toml
# Enable mouse support
set -g mouse on

# Set history limit to 100,000 lines
set-option -g history-limit 100000

# Enable true color support
set-option -sa terminal-overrides ",xterm*:Tc"

# Start windows and panes at 1, not 0
set -g base-index 1
set -g pane-base-index 1
set-window-option -g pane-base-index 1
set-option -g renumber-windows on

# Open new panes in the same directory as their parent pane
bind '"' split-window -v -c "#{pane_current_path}"
bind % split-window -h -c "#{pane_current_path}"

# Vim style pane selection
bind h select-pane -L
bind j select-pane -D 
bind k select-pane -U
bind l select-pane -R

# Shift arrow to switch windows
bind -n S-Left  previous-window
bind -n S-Right next-window

# Don't scroll down on copy via mouse
unbind -T copy-mode-vi MouseDragEnd1Pane
```

With mouse support you can resize panes with drag & drop and even get a context menu with a right click. By default tmux assigns numbers to windows for fast switching via `ctrl + b` and `number key`. Unfortunately the developers decided to begin with 0. This is technically correct, but on the keyboard it's quite unintuitive, so we can tell tmux to begin with 1. The rest is pretty much self-explanatory.

## Neovim

Why neo? Good old vim is extensible via vimscript. It works, but it's like bash: ugly as fuck. Neovim is a fork of vim and replaces vimscript with support for lua-based extensions. So it's still blazingly fast(tm) and much nicer to write extensions.

You could setup Neovim and the necessary extensions yourself, but won't recommend it in the beginning. Pre-build configs like [AstroNvim](https://astronvim.com/) or [NvChad](https://github.com/NvChad/NvChad) will massively speed up the process and have great defaults. It can be very overwhelming to get used to vim/nvim, so I would recommend to wait with your own config until you get more familiar with a keyboard-based editor.

### HELP! I can't quit vim!

Don't worry, you are not the first and will certainly not be the last. vim is a so-called modal-based editor. It has different modes like command, insert, visual etc. As you may have noticed, typing will not add text to the buffer. You need to press certain keys like `i`  to enter insert mode to edit text. There are other keys to go in insert mode and everyone of them has slightly different, but pretty useful function, like `o` which creates a new line below the cursor and starts insert mode.

To exit vim you to leave the insert mode by pressing `esc`. Now you are in command mode and can quit by typing `:` to enter the command line mode and hit `q` for quit, followed by enter to execute the command.

If you want to save a file, enter command line mode and use `w` for write. It's possible to chain certain commands. `wq` will save the file and quit vim.

Congratulations, you now know how to exit vim!

### Navigation

To move the cursor just use the arrow keys in most other editors. But there is more efficient key mapping in command mode: `h` (left), `j` (down), `k` (up) and `l` (right). No need to move your to the arrow keys anymore. To be honest, I'm still not comfortable with this way of navigation, but it's objectively more efficient than moving the right hand to the arrow keys.

Of course vim has way more navigation possibilities. For example, the cursor can jump forward by one word with `w` and backwards with `b`.  Press `$` to jump to the end of the current line or `0` to beginning. `G` navigates you to last line and `gg` jumps to the first line. And there is so much more to explore. I recommend a decent [vim cheat sheet](https://vim.rtorr.com/) to learn. But do yourself a favor and try not learn all keys at once. You will only become frustrated and give up more easily, it's just too much to learn everything in the beginning.

Netflix developer and Twitch Streamer [ThePrimagen](https://twitter.com/ThePrimeagen) designed a Neovim plug-in to learn the navigation commands as game. it's pretty good and fun: https://github.com/ThePrimeagen/vim-be-good

AstroNvim has many plug-in out of the box. Syntax highlighting, linting, auto-formatting etc. are all there, but you need to install the corresponding servers, parsers etc. 

To do this, enter command line mode and use `LspInstall` followed by the language name for installing a language server protocol. A language server for [Tree-Sitter](https://github.com/tree-sitter/tree-sitter) can be installed with `TSInstall` followed by the language name. If there nothing available, both commands will recommend plug-ins according to your input, if available.

Be aware, that LSPs and Tree-Sitter will not bring the necessary tools with them. If you install tooling for Rust, rust-analyzer has to be installed on the system. Same goes for ESlint, Prettier, Kotlin, Java etc.

## The End 

## ... for now

That was a lot unpack, but there is so much more to show to you. I will be back with more productivity tools and tips in the near future. Stay tuned!