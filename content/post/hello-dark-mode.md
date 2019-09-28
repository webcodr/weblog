---
date: 2019-09-25T22:20:12+02:00
title: "Hello, Dark Mode"
draft: false
---
Dark mode for Android and iOS? Hold my beer ...

It's quite simple to implement. Every modern browser can evaluate media queries in JavaScript with
`window.matchMedia()` and supports CSS variables.

I added the following to my application JavaScript file:

~~~ JavaScript
const preferColorSchemeResult
  = window.matchMedia('(prefers-color-scheme: dark)')

if (preferColorSchemeResult && preferColorSchemeResult.matches === true) {
  document.documentElement.setAttribute('data-theme', 'dark')
} else {
  document.documentElement.setAttribute('data-theme', 'light')
}
~~~

The script will set the data attribute `theme` on the document element (html) with the possible values
`dark` or `light` depending on the result of the media query.

There's no need for a polyfill, even IE 10 supports `window.matchMedia()`

Stylesheet changes is even simpler, since I already had introduced SCSS color variables a while ago. I just
had to replace them with CSS variables.

~~~ scss
// colors
$c_white: #fff;
$c_dark-grey: #4A4A4A;

:root {
  --container-background-color: #{$c_white};
  ...
}

[data-theme="dark"] {
  --container-background-color: #{darken($c_dark-grey, 20%)};
  ...
}
~~~

That's basically it. If you use SCSS, please take notice to use interpolations to map the SCSS
variables to CSS variables. This change in SassScript expressions was necessary to provide full
compatibility with plain CSS.

Since the theme selection is fully automated, I will provide a toggle possibiliry in a future
release for those of you who prefer the light mode. This can be easily achieved with a flag in local
storage and some minor changes in the JavaScript part.
