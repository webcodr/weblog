#!/usr/bin/fish

function create_post
    set title $argv[1]
    set date (date -u +"%Y-%m-%dT%H:%M:%S+00:00")
    set file_date (date +%Y-%m-%d)
    set slug (echo $title | sed -e 's/[^A-Za-z0-9]/-/g' | tr '[:upper:]' '[:lower:]')
    set filename "content/post/"$file_date"_"$slug".md"

    echo "---" > $filename
    echo "title: "$title"" >> $filename
    echo "date: $date" >> $filename
    echo "---" >> $filename
end

create_post $argv
