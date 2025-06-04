---
title: Real-world performance of the Apple M1 in software development
date: 2021-01-21T20:39:53.206Z
---
There are enough videos on YouTube out there to show how awesome the new Macs are, but I want to share my perspective as a software developer.

About six weeks ago, I was too hyped not to buy an ARM-based Mac, so I ordered a basic MacBook Air with 8 GB RAM (16 GB was hard to get at this time). As strange as it sounds, I don’t regret buying only 8 GB of RAM. On an Intel-based Mac this would be an absolute pain in the ass, even my old 15” MacBook Pro Late 2017 with 16 GB struggles sometimes with RAM usage.

It’s really amazing how good this small, passively cooled MacBook Air is keeping up. In many scenarios it even surpasses my MacBook Pro with ease. I never had an Intel-based MacBook Air, but the last time is used a dual-core CPU for development, was not pretty und that was a pretty decent i5 and not a ultra-low voltage i3.

## Speed, Speed, Speed

Unfortunately I couldn’t really develop software on the MacBook Air for a while, since Java and IntelliJ were not available for aarch64-based Macs. Of course I tried Rosetta 2, but at least for these two, it’s quite slow. NodeJS on the other hand is incredibly fast.

All this changed after my christmas vacation. IntelliJ was updated and thankfully Azul released a JDK 8 for ARM-Macs. A native version of Visual Studio Code is also available and quite fast.

So, no more introductions, here are some real-world scenarios and numbers.

I currently work on a Java project with a steadily growing codebase of Kotlin. It’s a little special, since another part of the application is written in Ruby. We’re using JRuby, so it’s bundled all together with a Vue-based frontend in a WAR-File with Maven.

### Maven Build Times

All build times are from fully cached dependencies, so there are no interferences from my internet connection.

Used devices:

* 15” MacBook Pro Late 2017: Intel Core-i7 7700HQ, 16 GB RAM
* 13” MacBook Air Late 2020: Apple M1, 8 GB RAM
* PC: AMD Ryzen 9 3950X, 32 GB RAM



| Device      | Build time with tests | Build time without tests |
| ----------- | --------------------- | ------------------------ |
| MacBook Pro | 223 s                 | 183 s                    |
| MacBook Air | 85 s                  | 63 s                     |
| PC          | 84 s                  | 66 s                     |



Well, a small, passively cooled MacBook Air is as fast as a full-blown and custom water-cooled 16-core monster of a PC. The MacBook Pro gets utterly destroyed. To get this straight: the cheapest notebook Apple makes, destroys a MacBook Pro that costs more than twice as much.

### Ruby Unit Test Times

The test suite contains 1,087 examples. Please keep in mind, that I had to use Rosetta 2 in order to get everything running on the MacBook Air, since not all used Ruby Gems are compatible with ARM at this time. All tests were run with Ruby 2.7.1.



| Device                     | Test duration |
| -------------------------- | ------------- |
| MacBook Pro native         | 1.9 s         |
| MacBook Air with Rosetta 2 | 1.1 s         |
| PC native                  | 1.3 s         |



Yeah, it’s quite fast, compared to a Suite of Java-based unit tests, but even here the MacBook Pro has no chance at all.

### Frontend Build Times

The frontend is a Vue-based single-page application. As with Ruby, I had to use NodeJS with Rosetta 2, since not all used modules are compatible with ARM.



| Device                     | Test duration |
| -------------------------- | ------------- |
| MacBook Pro native         | 27.8 s        |
| MacBook Air with Rosetta 2 | 20.7 s        |
| PC native                  | 20.6 s        |



Well, it’s more than obvious now, that the MacBook Pro has no chance at all against my MacBook Air. It’s not just the performance. After a few seconds of load, the MacBook Pro sounds like my F/A-18C in DCS immediately before a carrier launch, while the MacBook Air has no fan and therefore makes no noise at all.

And the battery life. Oh my god. Ten straight hours of development with IntelliJ and Visual Studio Code is entirely possible now, all while staying cool and quiet.

Even the dreaded battery murderer Google Meet is no problem anymore. My MacBook Pro on battery would last perhaps 2.5h max. The MacBook Air is capable of 8, perhaps even 9 hours of Meet. It’s as insane as an 8h long Meet itself.

Ah, yes, there is another thing: Meet does not cripple the performance anymore. The MacBook Air is totally usable with a Meet going on, while my MacBook Pro becomes sluggish as hell and is barely usable (even without Chrome and frakking Google Keystone).

## Conclusion

I will make it short: if your tools and languages are already supported or at least quite usable with Rosetta, go for it.  I would recommend 16 GB or more (depending on future models), if you want to buy one. I’m surprised that a 8 GB MacBook Air is that capable and to be honest, I don’t feel like there a going to be a problem for a while, but no one regrets more RAM …

### Air vs Pro

The 13” MacBook Pro is little faster over longer periods of load due to active cooling, it has more GPU-cores, the love or hated Touch Bar and a bigger battery. If you need this, go for it, but if you can wait, I’d recommend to wait for the new 14” and 16” Pro models. 

They will be real power houses with 8 instead of 4 Firestorm cores, vastly more RAM and even bigger batteries. And hey, perhaps they come with MagSafe and some other ports we MacBook users didn’t see for a while.