---
date: 2018-02-03T00:00:00+01:00
title: EdgeRouter VLAN isolation
displayLanguage: en
---
In this post I will show you, how to create a VLAN with your EdgeRouter and how to fully isolate it from all your other networks.

The following configuration shows my VLAN setup for IPTV services, since the receivers do not need access to the other networks and an isolated network for IPTV can avoid trouble with multicast/IGMP. You don't use IPTV? No problem, you could use the config to create a guest network or for other untrusted devices.

I'm using an EdgeRouter X, but this configuration will work on any other EdgeRouter. The general approach should even work on a UniFi router like the USG.

## Network Setup

- `10.0.0.0/24`: home network on `eth1`
- `192.168.1.0/24`: management LAN for my DSL modem on `eth0`
- `10.0.1.0/24`: `eth2`, `eth3` and `eth4` as switched ports on the EdgeRouter X

My management LAN is connected to the other networks via a custom NAT rule.

The main LAN consists of the three UniFi switches (US-8 and US-8 POE) and two UniFi access points (AP AC Lite). UniFi switches are fully supporting VLANs, so I can terminate a VLAN to any switch port within the network.

Why private class A networks? Well, why not? And I like short IP addresses.

But the management LAN is a private class C network? Yeah, I'm leaving the modem on it's default network configuration to avoid trouble, if I ever have to reset it's config. I like to experiment with other firmware versions. Currently I'm trying a firmware for australian ISPs. So far it's working great and it disables some the VDSL error corrections from my ISP that can cause higher latencies.

## Here we go

The IPTV VLAN will be on `eth1` with VLAN ID 10 and will be terminated on a UniFi switch in the living room. If you need a guide, how to setup a VLAN on a UniFi switch and to assign it to a switch port, just click [here](https://help.ubnt.com/hc/en-us/articles/219654087-UniFi-Using-VLANs-with-UniFi-Wireless-Routing-Switching-Hardware#USW).

### Create the VLAN

  1. Go to the dashboard of your EdgeRouter, click on `Add Interface` and select `VLAN`:
       
     ![Create VLAN](/images/edgerouter-vlan-isolation/create_vlan.png)
     
  2. Go to section `SERVICES` and click `Add DHCP server`:
  
     ![Create VLAN DHCP server](/images/edgerouter-vlan-isolation/create_vlan_dhcp_server.png)
    
  3. Stay in `SERVICES`, go to the tab `DNS`, `Add Listen interface` and choose the interface of your VLAN:
  
     ![Create VLAN DNS forwarding](/images/edgerouter-vlan-isolation/create_vlan_dns_forwarding.png)

VLAN 10 is now ready to use, but it's not isolated from the other networks. The EdgeRouter's job is to route between networks. A device on VLAN 10 could access the LAN, your NAS for example.

### Isolate the VLAN from the rest

  1. Go to `FIREWALL/NAT`, then to `Firewall/NAT Groups` and create a new network group:
  
    ![Create Network Group](/images/edgerouter-vlan-isolation/create_network_group.png)
    
  2. Edit the new network group and add all networks except the VLAN:
  
     ![Create Network Group Add Networks](/images/edgerouter-vlan-isolation/create_network_group_add_networks.png)
     
  3. Go to `Firewall Policies` and click `Add Ruleset`:
  
     ![Create Firewall Ruleset](/images/edgerouter-vlan-isolation/create_firewall_ruleset.png)
     
  4. Edit the new ruleset and setup the interfaces:
  
     ![Create Firewall Ruleset Interfaces](/images/edgerouter-vlan-isolation/create_firewall_ruleset_interfaces.png)
     
  5. Add a new firewall rule:
  
     ![Create Firewall Rule](/images/edgerouter-vlan-isolation/create_isolation_firewall_rule.png)
     
     ![Create Firewall Rule Source](/images/edgerouter-vlan-isolation/create_isolation_firewall_rule_source.png)
     
     ![Create Firewall Rule Destination](/images/edgerouter-vlan-isolation/create_isolation_firewall_rule_destination.png)
     
  6. (optional) Add the network group to your custom NAT rules:
      
     ![Edit NAT rule configuration](/images/edgerouter-vlan-isolation/edit_nat_rule_configuration.png)
     
     If you're using custom NAT rules, you have to add your new network group to the rules to exclude the VLAN. Firewall rules alone will not isolate any networks from custom NAT rules.
     
That's it. VLAN 10 is now fully isolated from all other networks. The firewall will drop all packages from `eth.10` to the network group and my custom NAT rule will only work from networks of the group.

If you have interest in buying one of the above mentioned devices, please consider to support me through the following Amazon Germany ref links. Thank you!

[DrayTek Vigor 130](https://www.amazon.de/gp/product/B00F9E5LQA/ref=as_li_tl?ie=UTF8&camp=1638&creative=6742&creativeASIN=B00F9E5LQA&linkCode=as2&tag=web0b0-21)

[Ubiquiti EdgeRouter X](https://www.amazon.de/gp/product/B011N1IT2A/ref=as_li_tl?ie=UTF8&camp=1638&creative=6742&creativeASIN=B011N1IT2A&linkCode=as2&tag=web0b0-21)

[Ubiquiti UniFi AP AC Lite](https://www.amazon.de/Ubiquiti-Networks-2-4GHz-867Mbit-UAP-AC-LITE/dp/B016K4GQVG/ref=as_li_ss_tl?ie=UTF8&qid=1517615751&sr=8-1&keywords=unifi+ap+lite&dpID=31oux4k0ZCL&preST=_SY300_QL70_&dpSrc=srch&linkCode=ll1&tag=web0b0-21&linkId=4062e73def8bd2b9986a2077a000be6d)

[Ubiquiti UniFi US-8](https://www.amazon.de/Ubiquiti-Networks-US-8-UniFiSwitch-8/dp/B01N362YPG/ref=as_li_ss_tl?s=computers&ie=UTF8&qid=1517615825&sr=1-1&keywords=unifi+us-8&dpID=41tiJ33jrSL&preST=_SX300_QL70_&dpSrc=srch&linkCode=ll1&tag=web0b0-21&linkId=aaea6f79bbb3f230cf761ddd61e4f8a8)

[Ubiquiti UniFi US-8-60W POE](https://www.amazon.de/Ubiquiti-US-8-60W-UniFi-Switch-Grau/dp/B004BQCKXO/ref=as_li_ss_tl?s=computers&ie=UTF8&qid=1517615825&sr=1-2&keywords=unifi+us-8&dpID=31ilOcMTfRL&preST=_SX300_QL70_&dpSrc=srch&linkCode=ll1&tag=web0b0-21&linkId=fae5ac376c34e72a5c9d21332ea77898)
      