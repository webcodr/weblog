---
title: Find things even faster with srchr
date: 2026-07-05T20:28:50+00:00
---
Inspired by my last post about `rgp` and `fdp` I got the idea to combine both into a more powerful and easier to use shell script called `srchr` (well, at least it's short :D). 

It combines the results of `fd` and `rg` for fuzzy finding with `fzf`. The preview will be handled with `bat` as before, but it will jump to the first matching line if the file contains the search term. Your editor will also be opened on that line, if it supports vim-style line jumps `nvim +<line> <file>`. Otherwise the preview will start at the top of the file and your editor won't get the line jump command.

[You can find the script on GitHub.](https://github.com/webcodr/srchr)

## Requirements

- CLI tools: [fd](https://github.com/sharkdp/fd), [rg](https://github.com/BurntSushi/ripgrep), [fzf](https://github.com/junegunn/fzf), [bat](https://github.com/sharkdp/bat)
- Please use an editor that supports line jumps for opening files like (n)vim or helix and set `$EDITOR` accordingly.

