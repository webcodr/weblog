function Create-Post {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )

    $date = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss+00:00")
    $fileDate = Get-Date -Format "yyyy-MM-dd"
    $slug = $Title -replace '[^A-Za-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', '' | ForEach-Object { $_.ToLower() }
    $filename = "content/post/${fileDate}_${slug}.md"
    $yamlTitle = $Title.Replace("'", "''")

    $content = @"
---
title: '$yamlTitle'
date: $date
topics: []
description: ""
---
"@

    $content | Out-File -FilePath $filename -Encoding UTF8 -NoClobber -ErrorAction Stop
}

# Call the function with command line arguments
if ($args.Count -gt 0) {
    Create-Post -Title ($args -join ' ')
}
