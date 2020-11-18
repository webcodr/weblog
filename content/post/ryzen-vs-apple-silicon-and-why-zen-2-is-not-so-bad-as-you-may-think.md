---
title: Ryzen vs Apple Silicon and why Zen 3 is not so bad as you may think
date: 2020-11-18T22:34:23.422Z
---
Apple‘s M1 is a very impressive piece of hardware. If you look at the benchmarks, like SPECperf or Cinebench, it‘s an absolute beast with a ridiculously low power consumption compared with a Ryzen 9 5950X.

## Zen 3 is that inefficient?

10 W vs 50 W looks really bad for AMD, but the answer to this question is a little more complicated than this raw comparison of power usage.

Here are basic things to know:

* Apple‘s M1 has four high power cores (Firestorm) and four high efficiency cores (Icestorm), this is called BIG.little architecture.
* AMD’s Ryzen 9 5950X is a traditional x86 CPU with 16 cores and 32 Threads

So what? The benchmarks are about single core performance and the Ryzen needs 40 W more. What a waste.

Right, but this says nothing about the efficiency of a single core. 

I don‘t have 5950X, but his older brother, the 3950X. Same core count and about the same power usage. While monitoring with HWINFO64 on a single core run of Cinebench R20 the used core needs about 10 - 12 W.

## Okay, but what happend to the other 38 watts?

As you may know AMD introduced a so called chiplet architecture with Ryzen 3000. A Ryzen 9 5950X has three dies. Two with 8 cores each and a separate chip that handles I/O like PCIe 4, DDR4 memory and the Infinity Fabric links to the CPU dies.

This I/O die consumes 15 to 17 W. It‘s a quite large chip produced in a 12 nm node by GlobalFoundries. That alone is a big reason for higher power usage compared to a modern node like TSMC‘s N7P (7 nm) used for the other two chiplets.

Why 12 nm? It‘s a compromise, since TSMCs 7 nm production capabilities are still somewhat limited and AMD takes a fairly large share of the capacity. All Zen 2 and 3 cores are produced in 7 nm, as is any modern AMD GPU and of course there are other customers as well.

I hope AMD will improve the I/O die with Zen 4 (Ryzen 6000) dramatically. A modern process node and a bunch of better energy saving functions would do the trick.

## There are still 21 W unaccounted for!

15 more cores are also unaccounted for. 21 divided by 15: about 1.4 W per core average. Seems a bit high, but possible. It depends on background tasks from the OS, the current Windows power plan etc.

To be fair, AMDs energy saving functions per core could a little bit better. They are not bad at well, but there‘s room for improvements.

## Process nodes

For a fair comparison we also have to include the process nodes. As mentioned above, Ryzen cores are manufactured in TSMC‘s 7 nm node. Unfortunately Apple is one step ahead in this category. The M1 and it‘s little brother A14 are already on 5 nm, again from TSMC.

This alone could account for up to 30% less power usage. There are no exact numbers available, but 20 to 30% would reasonable.

## Core architecture

Current Zen 3 cores and Apple‘s Firestorm cores have fundamental differences in architecture. Modern x86 cores are quite small but clock quite high. On a single core load like Cinebench R23 you will get about 5 GHz from 5950X while a Firestorm core will only clock to 3.2 GHz.

Wait, what? Firestorm with 3.2 GHz is about as fast as Zen 3 with 5 GHz? That can‘t be true. Yet it is. According to the benchmarks a Firestorm core can execute about twice the instructions per cycle (IPC) as a Zen 3 core.

Firestorm is an extremely wide core design with many processing units. This is complemented by a absurdly large L1 caches and re-order buffers. Much larger than on any x86 core ever.

This allows Apple to lower the clock speed significantly without compromising performance. Lower clock speeds also mean lower voltage and power usage.

But there‘s more: since the A13 (iPhone 11) Apple has quite many incremental power saving functions within every part their SoCs. They can lower the power usage to an absolute minimum or even can parts of the silicon on and off quite fast, to be ready when the user needs more computational power and as fast they turn it off.

Modern x86 CPUs have similar functions but not quite as advanced or in as many parts as current Apple SoCs. Remember AMD‘s I/O which has basically the same power usage all the time.

## Instruction set

x86 is old and can be quite cumbersome to use. Apple's CPUs are based on ARM, a more modern instruction set. The same tasks can be achieved with fewer commands. This means faster computation and less power usage. 

Under the hood current x86 CPUs have noting to do with their older cousins, but the instruction set is still the same. To be fair, over the years AMD and Intel added way more modern instructions like AVX for certain operations, but the core is still 40 years old.

## Conclusion

Taken all this into account, a Zen 3 is not that bad compared to a Firestorm core. Of course, Apple has advantages over x86, but they are more about the process node, different architecture or the instruction set, than about the efficiency of the cores itself.

Well, and then there‘s Intel. The quite slowly awakening giant is not without hope, but they are way behind Apple and AMD. As long as their high performance CPUs are stuck on 14 nm, they are ... to put it simply, fucked.

10 nm is on it‘s way, but there a still problems. The next release of desktop- and server-class CPUs will still be on 14 nm, but with a more efficient architecture backported from 10 nm CPUs. It will help, but they need a better process node and they need it asap.

10 nm could be ready for the big guys in 2021. At least new Xeons in 10 nm were announced. But the question is: how good is the node? Some of the already released 10 nm notebook CPUs are quite good, so Intel could be back in year or two.

They also plan to release Alder Lake in 2021, a BIG.little CPU design. That would be much appreciated on notebooks, but software has to be ready. Without a decent support of the operating systems, such a CPU will not work properly.

There‘s another problem: Intel‘s 7 nm node. According to YouTubers like AdoredTV or Moore‘s law is dead, 7 nm could be the 10 nm disaster all over again. Let‘s hope not. 

Three competing CPU vendors on par would be amazing. Not just for pricing, but also computational power. Look what AMD did in the past three years. If someone said in 2016 that AMD would kick Intel‘s and nVidia‘s ass in four years, he would have been called a mad man. The same with Apple.

2020 is a shitty year, but the hardware? Awesome would be an understatement.