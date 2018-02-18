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

***Update for Windows users***

After some fiddling around, I found a working solution for Windows 10 users. You just have to install the SSH client beta and Wireshark for Windows.

~~~ sh
ssh user@egderouter_ip "sudo tcpdump -f -i eth0 -w -" | "C:\Program Files\Wireshark\Wireshark.exe" -k -i -
~~~

Troubleshooting advice:

- The Windows SSH client will only work on command shells with admin privileges.
- Use only double quotes. The Windows command line doesn't like single quotes as well as a shell on unixoid operating systems.
- Adjust the path to Wireshark if it's not installed in the default directory.
- `CTRL + C` or `CTRL + X` will not work to terminate the SSC connection. You have to close the window instead.
