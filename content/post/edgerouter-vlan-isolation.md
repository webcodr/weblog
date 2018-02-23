---
date: 2018-02-03T00:00:00+01:00
title: EdgeRouter VLAN isolation
displayLanguage: en
---
In this post I will show you, how to create a VLAN with your EdgeRouter and how to fully isolate it from all your other networks.

The following configuration shows my VLAN setup for IPTV services, since the receivers do not need access to the other networks and an isolated network for IPTV can avoid trouble with multicast/IGMP. You don't use IPTV? No problem, you could use the config to create a guest network or for other untrusted devices.

I'm using an EdgeRouter X, but this configuration will work on any other EdgeRouter. The general approach should even work on a UniFi router like the USG.

## Update (15. February 2018)

I have completely rewritten the firewall configuration guide, since the first version had a substantial flaw: it will cut the access from the VLAN to your LAN, but the VLAN can connect to all router services. So, someone could open an SSH connection to your EdgeRouter and that's bad.

If you have already followed the old guide, please delete the ruleset and use the new guide to create a proper firewall config.

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

### Create network group

  1. Go to `FIREWALL/NAT`, then to `Firewall/NAT Groups` and create a new network group:
  
    ![Create Network Group](/images/edgerouter-vlan-isolation/create_network_group.png)
    
  2. Edit the new network group and add all networks except the VLAN:
  
     ![Create Network Group Add Networks](/images/edgerouter-vlan-isolation/create_network_group_add_networks.png)

### A quick guide to firewall directions

Before you create the firewall rulesets, you should know and understand the firewall ruleset directions: 

- `IN`: traffic entering the router from an interface
- `OUT`: traffic exiting the router to an interface
- `LOCAL`: traffic entering the router and destined to router itself (internal services, like DNS, DHCP, VPN etc.)

I will also provide a short explanation for each firewall ruleset and its direction.

If you're having trouble to understand the directions, there is a very helpful diagram in the [Ubiquiti forums](https://community.ubnt.com/t5/EdgeMAX/Layman-s-firewall-explanation/m-p/1436103#M91494).

### Create firewall ruleset VLAN10_ISOLATION_IN

The following firewall ruleset blocks traffic into all networks of your network group, but will allow already established connections.

Direction `IN` means any traffic from `eth1.10` to any other of your EdgeRouter's interfaces.

  1. Go to `Firewall Policies` and click `Add Ruleset`:
  
     ![Create Firewall Ruleset IN](/images/edgerouter-vlan-isolation/create_firewall_ruleset_in.png)
     
  2. Edit the new ruleset and setup the interfaces:
  
     ![Create Firewall Ruleset IN Interfaces](/images/edgerouter-vlan-isolation/create_firewall_ruleset_in_interfaces.png)
     
  3. Add a new firewall rule to allow established and related packets:
  
     ![Create Firewall IN Rule 1 Basic](/images/edgerouter-vlan-isolation/create_firewall_ruleset_in_rule1_basic.png)
     
     ![Create Firewall IN Rule 1 Advanced](/images/edgerouter-vlan-isolation/create_firewall_ruleset_in_rule1_adv.png)
  
  4. Add a new firewall rule to drop packets into network group `LAN`:

    ![Create Firewall IN Rule 2 Basic](/images/edgerouter-vlan-isolation/create_firewall_ruleset_in_rule2_basic.png)
    
    ![Create Firewall IN Rule 2 Advanced](/images/edgerouter-vlan-isolation/create_firewall_ruleset_in_rule2_dest.png)
  
  5. Your firewall ruleset should look like this:
  
    ![Create Firewall IN Rules](/images/edgerouter-vlan-isolation/create_firewall_ruleset_in_rules.png)

### Create firewall ruleset VLAN10_ISOLATION_LOCAL

This ruleset will block any traffic to your EdgeRouters services, with the exception of DNS and DHCP. 

Direction `LOCAL` means any traffic from `eth1.10` directly to your EdgeRouter and its services.

  1. Create another firewall ruleset like `VLAN10_ISOLATION_IN`:
  
     ![Create Firewall Ruleset LOCAL](/images/edgerouter-vlan-isolation/create_firewall_ruleset_local.png)
     
  2. Edit the new ruleset and setup the interfaces:
  
     ![Create Firewall Ruleset LOCAL Interfaces](/images/edgerouter-vlan-isolation/create_firewall_ruleset_local_interfaces.png)
     
  3. Add a new firewall rule to allow DNS:
  
     ![Create Firewall LOCAL Rule 1 Basic](/images/edgerouter-vlan-isolation/create_firewall_ruleset_local_rule1_basic.png)
     
     ![Create Firewall LOCAL Rule 1 Advanced](/images/edgerouter-vlan-isolation/create_firewall_ruleset_local_rule1_dest.png)
  
  4. Add a new firewall rule to allow DHCP:

    ![Create Firewall LOCAL Rule 2 Basic](/images/edgerouter-vlan-isolation/create_firewall_ruleset_local_rule2_basic.png)
    
    ![Create Firewall LOCAL Rule 2 Advanced](/images/edgerouter-vlan-isolation/create_firewall_ruleset_local_rule2_dest.png)
  
  5. Your firewall ruleset should look like this:
  
    ![Create Firewall IN Rules](/images/edgerouter-vlan-isolation/create_firewall_ruleset_local_rules.png)

### Optional: assign network groups to custom NAT rules

![Edit NAT rule configuration](/images/edgerouter-vlan-isolation/edit_nat_rule_configuration.png)

If you're using custom NAT rules, you have to add your new network group to the rules to exclude the VLAN. Firewall rules alone will not isolate any networks from custom NAT rules.
     
That's it. VLAN 10 is now fully isolated from all other networks. The firewall will drop all packages from `eth.10` to the network group and my custom NAT rule will only work from networks of the group.
      