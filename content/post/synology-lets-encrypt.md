---
date: 2018-01-24T20:00:00+01:00
title: Synology DSM and Let's Encrypt Trouble
displayLanguage: en
---
This is just a quick note to all with problems to create Let's encrypt certificates with Synology DSM.

I had trouble for months with this. DSM returnd always that port 80 is closed, but my EdgeRouter config said otherwise and content from the Synology web server itself was accessible via port 80. So, no ISP issue either.

After some research, I used [acme.sh][1] with a DNS-based challenge on macOS and imported the certificate. Well, it works, but I wanted a real solution.

Again, after a little more than some reseach, I found a valuable hint. In dual-stack configurations with both, real IPv4 and IPv6 addresses, the Synology Let's Encrypt client uses IPv6 for the challenge. Of course port 80 was only opened for IPv4 connections. I opened the port and ... it didn't work. I'm not sure why, since I am no master of the CLI-based configuration of a router.

Next idea: turn off IPv6 in Synology's dynamic DNS service. Well, turns out, you can't configure which protocols the services will use. Turning off IPv6 in the network settings also didn't help.

The solution: use a dynamic DNS service that can configure the protocols or does not have IPv6 support. After some fiddling around with the list of supported services in DSM, I decided to use [NoIP][2]. And? It works, finally!

Why NoIP? Well, some of the supported services websites seemed ancient and frankly, I don't want to pay money just for creating a new certifacte every 90 days.

## Dear Synology devs

If you read this, please consider adding the DNS challenge option. This was proposed multiple times in the Synology forums since you introduced Let's Encrypt support and it would help in such situations, where port 80 cannot be accessed due to firewall or ISP issues like dual-stack lite. Thank you.

## TL;DR

If you're having trouble with Synology DSM, Let's Encrypt and port 80 error messages and you're using a dual-stack connection like me, turn off IPv6 for your dynamic DNS service or try to open your firewall for IPv6 port 80.

  [1]: https://github.com/Neilpang/acme.sh
  [2]: https://www.noip.com/