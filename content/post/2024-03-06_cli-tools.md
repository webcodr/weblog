---
title: Awsome CLI Tools
date: 2024-03-06T20:21:06.644Z
draft: false
---

There are some incredibly useful CLI tools out there. Here's a list with some awesome tools I'm using for my daily work.

## atuin

[Atuin](https://atuin.sh/) is a history replacement with a fuzzy finding search and sync/backup options (self-hosted if you need). It's written in Rust (blazingly fast!) and stores the history entries in a SQLite db. You can even import your current history from your shell. Atuin supports bash, zsh, fish and NuShell.

## bat

Need `cat` a lot? [Bat](https://github.com/sharkdp/bat) is a cat clone on steroids with syntax highlighting, themes, git integration and much more.

## eza

Everyone needs `ls` ? Nope, [eza](https://eza.rocks/) is much better. Colored output, icons via nerd fonts, git status tracking per file, tons of display options ...

## tldr

Reading an man page can be frustrating, why can't I just have the TL;DR version? Well, [tldr](https://tldr.sh/) does exactly that. Just use it like `man` and enjoy the TL;DR version of a man page.

## zoxide

As his siblings `cd` is a little dated and clunky. With [zoxide](https://github.com/ajeetdsouza/zoxide) you can easily jump to directories without typing the full path. It stores a history of your visited paths and you can jump via keywords to your directories.

## chezmoi

You're using multiple computers or just want a simple and reliable way to store your dot files? [Chezmoi](https://www.chezmoi.io/) is your friend and stores your dot files in a git repo with syncing capabilities to other devices. It's even possible to encrypt your files. If you have secrets in your dot files, chezmoi comes with integrations for many password managers to safely store your passwords, tokens etc.

## starship

Your shell looks boring? Just theme it with [starship](https://starship.rs/)! It's pretty easy to build your own and if you don't want to, there many themes available. Starship also has integrations for many dev tools to show the current git status or currently active versions of your runtime environments like NodeJS, Rust, Go, Java etc.

## fzf

Finding files with the usual suspects works fine, but [fzf](https://github.com/junegunn/fzf) can do this faster and much more intuitive. It's a fuzzy finding search within your current directory, processes, git commits, history (if you don't like Atuin) and much more.

## ripgrep

Ripgrep is a really fast regex-based search tool and can do much more than `grep` alone.

## btop

Another `top` variant? Yup, but [btop](https://github.com/aristocratos/btop) is way more like it's modern GUI-based colleagues on macOS or Windows with CPU and GPU usage, process trees, I/O and disk activities, battery status ...
