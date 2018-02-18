---
date: 2018-02-18T19:00:05+01:00
title: Interface monitoring with Wireshark on an EdgeRouter
---
Here is just a neat little trick to use Wireshark for monitoring interfaces on your EdgeRouter. This is incredibly useful for debugging purposes.

The following commands work on macOS or a Linux distribution only.

~~~ sh
ssh user@egderouter_ip 'sudo tcpdump -f -i eth0 -w -' | wireshark -k -i -
~~~

If you're monitoring the interface with your SSH connection to the EdgeRouter, you may want to ignore traffic on port 22.

~~~ sh
ssh user@egderouter_ip 'sudo tcpdump -f -i eth1 -w - not port 22' | wireshark -k -i -
~~~

