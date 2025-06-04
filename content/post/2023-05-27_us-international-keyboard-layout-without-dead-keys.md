---
title: US International Keyboard Layout Without Dead Keys
date: 2023-05-27T21:36:06.644Z
---
Depending on your country's keyboard layout writing code can be quite annoying. The German ISO layout is an exceptional pain in the ass, as almost all relevant symbols require a modifier key, sometimes even two (I'm looking at you, Apple). German has some special characters (ä. ö, ü, ß) and it makes sense to have them readily available without modifier keys, but it just sucks for programming.

I decided to switch to the US ANSI layout and bought two new keyboards: a Keychron K3 Pro for my MacBook Pro (light and portable, perfect if I have to go to my company's office) and Keychron Q1 version 2 for my Windows PC. By the way, the Q1 is heavily modded and will be tweaked further in the coming weeks. I will write an article about the mods after the keyboard is finished.

Both keyboards work great, but to type German special characters I have to use the US international layout on Windows and there's a catch. Who would have thought, if Microsoft is involved? Certain keys like single quote/double quote or accents/tilde are so called dead keys.

If you press them, nothing will happen at first. Only after pressing the next key, the symbol will appear. So, if you want to type a text wrapped in double quotes, you press the the key and the double quote will appear, as soon as you type the first character of the actual text. It's annoying as fuck and drives me crazy.

## Solution

Unfortunately Microsoft does not ship an US international layout without dead keys for Windows. Most Linux distributions do exactly that, but I guess that's to easy for a big international corporation like Microsoft.

What to do? After a little bit of googling, I found a neat little tool, the Microsoft Keyboard Layout Creator. I've never heard of this program before but it's legit and works fine.

If you're having trouble with the dead keys like me, I recommend the following steps:

1. Download the [Microsoft Keyboard Layout Creator](https://www.microsoft.com/en-us/download/details.aspx?id=102134) from Microsoft's website
2. Open it and load the US international layout via `File` -> `Load Existing Keyboard...` 
3. All dead keys are shown with a light grey background. You can remove their dead key status via the context menu
4. Don't forget to activate the shift layer via the checkboxes left of the keyboard layout and disable the dead keys as well
5. Save your config
6. Build the layout via `Project` -> `Build DLL and Setup Package`
7. After the build finished, a dialog will ask you to open the build directory. Open it and run `setup.exe` to install the new layout
8. Restart Windows. This should not be necessary, but unfortunately Windows is Windows ...
9. Go to `Settings` -> `Time and Language` -> `Language and Region`
10. Select your preferred language and click the three dots and choose `Language options`
11. Use `Add a keyboard` and select `United States International - No Dead Keys`
12. I recommend to remove all other keyboard layouts, so they can't interfere

Now you should have a working US international layout without those annoying dead keys. Happy typing!