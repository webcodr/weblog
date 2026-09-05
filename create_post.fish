#!/usr/bin/fish

function create_post
    set title $argv[1]
    set date (date -u +"%Y-%m-%dT%H:%M:%S+00:00")
    set file_date (date +%Y-%m-%d)
    set slug (echo $title | sed -e 's/[^A-Za-z0-9]/-/g' -e 's/-\+/-/g' -e 's/^-//' -e 's/-$//' | tr '[:upper:]' '[:lower:]')
    set filename "content/post/"$file_date"_"$slug".md"

    set yaml_title (string replace --all "'" "''" -- "$title")
    begin
        printf '%s\n' '---'
        printf "title: '%s'\n" "$yaml_title"
        printf 'date: %s\n' "$date"
        printf '%s\n' 'topics: []' 'description: ""' '---'
    end >? "$filename"
end

create_post $argv
