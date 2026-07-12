---
title: webcodr goes Netlify CMS
topics: [developer-tools, web-development]
description: Add Netlify CMS to a Hugo site for a Git-based publishing workflow that works across desktop and iPad.
date: 2020-10-31T22:54:24.430Z
---
Until today posts on webcodr were published via a simple git-based workflow. If I wanted to create a new posts, I had to open the repository in Visual Studio Code and created a markdown file. After pushing the commit with the new file, a GitHub hook notified Netlify to pull the repo and build and publish the site.

It was quite simple and effective, but lacks comfort and does not work on iOS/iPadOS devices. After buying a new iPad Air and Magic Keyboard, I wanted a pragmatic way to write posts without my MacBook or PC.

I always wanted to try Netlify CMS, so this was my chance. The transition was really simple. I followed the guide for Hugo-based sites and adjusted the config to work with Hugo. That‘s it. Netlify CMS works just fine with the already existing markdown files. Even custom frontmatter fields within the markdown files are no problem, just set them up in the config file.

A little more configuration in the Netlify admin panel is necessary, but the guide explains everything very well. It was just a matter of 15 minutes to get everything going.

If you use a static site generator and want to have a little more comfort, Netlify CMS makes it really simple. They provide guides for every major player like Gatsby, Jekyll or Nuxt and of course Hugo. You don‘t even have to use GitHub. GitLab and BitBucket are supported as well. As are more complex workflows for more than one editor, custom authentication with OAuth or custom media libraries.

## Editor

Netlify CMS supports markdown and has a basic, but decent editor with rich-text mode. But I wanted a little bit more, so I decided to write my posts in Ulysses — a specialized writing app with support of GitHub-flavored markdown, including syntax highlighting preview . It‘s available for macOS and iOS/iPadOS. All files and settings are synched via iCloud. So, once you have setup everything, you‘re good to go on any of your Apple devices.

Since Ulysses requires a subscription, I will use this to „force“ me writing more posts. 😁

I wrote this post entirely on my iPad Air and so far, I‘m quite happy with the new workflow. Of course I will not write every post this way. New posts with code examples will be easier to handle on a Mac or PC. (Hey Apple, how about IntelliJ on an iPad?)

btw: even as an enthusiast of mechanical keyboards I have to say, it‘s quite nice to type on a Magic Keyboard. I just have to get used to the smaller size. The Magic Keyboard for the 10.9“ iPad Air or 11“ iPad Pro is a compromise in size and some keys like tab, shift, backspace, enter and the umlaut keys (bracket keys on english keyboard layouts) are way smaller compared to normal-sized keyboards. It‘s bigger brother for the 13“ iPad Pro has a normal layout, but that monster of an iPad seems a bit excessive for my use case.
