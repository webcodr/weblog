---
title: Using fd, rg, fzf and bat to find things fast
date: 2026-07-05T17:05:03+00:00
---

Modern terminal programs like `fd` or `rg` make it really easy to find stuff, but there's still room for improvement. In this post I will show you how to use fish to write to small functions with `fd`, `rg`, `fzf` and `bat` to search for file names and file content with an interactive list and even a preview in the terminal.

## I don't know that stuff?

First things first. If you already know `fd` or the other tools from above, feel free to skip this section.

- `fd` is a more user-friendly replacement for `find`
- `rg` or ripgrep is `grep` an steroids, respecting git ignore files and skips binaries or hidden files
- `fzf` is a command-line fuzzy finder. You basically can pipe everything into `fzf` and just type to filter the output
- `bat` is a modern version of `cat` with syntax highlighting and git integration

## Say hi to rgp and fdp

~~~ fish
function rgp
    set -l search_term $argv[1]

    if test -z "$search_term"
        echo "Usage: rgp <search_term>"

        return 1
    end

    rg -l $search_term | fzf --preview 'bat --color always {}' --bind 'enter:become("$EDITOR" {+})'
end

function fdp
    set -l search_term $argv[1]

    if test -z "$search_term"
        echo "Usage: fdp <search_term>"

        return 1
    end

    fd -tf $search_term | fzf --preview 'bat --color always {}' --bind 'enter:become("$EDITOR" {+})'
end
~~~

That's all you need. Put them into your fish config file or the fish functions folder.

## Usage

`rgp something` -- this will use `rg` to search recursively search the current directory for files with `something` inside. The result is piped into `fzf`. You know can filter the result further with `fzf` or select a file with the arrow keys and `bat` will give you a live preview of the file with syntax highlighting. Pressing `enter` will open the selected file with your default editor (environment variable `EDITOR`).

`fdp` works similar, but looks for file names instead of the file content and also pipes the result to `fzf` for further filtering, preview or opening the selected file.

Don't like fish? Here's a version that works with bsh or zsh. 

**Note**: the `local` keyword is not POSIX-compliant. If you need that, just remove it, but this makes `search_term` global, so use with care.

~~~ bash
rgp() {
    local search_term=$1

    if [ -z "$search_term" ]; then
        echo "Usage: rgp <search_term>"
        
        return 1
    fi

    rg -l "$search_term" | fzf --preview 'bat --color always {}' --bind 'enter:become("$EDITOR" {+})'
}

fdp() {
    local search_term=$1

    if [ -z "$search_term" ]; then
        echo "Usage: fdp <search_term>"
        
        return 1
    fi

    fd -tf "$search_term" | fzf --preview 'bat --color always {}' --bind 'enter:become("$EDITOR" {+})'
}
~~~
