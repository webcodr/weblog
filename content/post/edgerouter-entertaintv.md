---
date: 2018-02-07T22:00:00+01:00
title: Telekom EntertainTV mit Ubiquiti EdgeRouter X
---
Da bei Sky Deutschland nun auch noch die Formel 1 entfällt und zusätzlich in den letzten Jahren diverse Rechte, z.B. die Premier League, auch abhanden gekommen sind, habe ich mich dazu entschlossen auf EntertainTV von der Telekom umzusteigen.

In diesem Post erkläre ich meine EdgeRouter- bzw. Netzwerk-Konfiguration, da ein IPTV-System wie EntertainTV besondere Anforderungen stellt. Damit IPTV überhaupt funktionieren kann, muss die Telekom Multicasts verwenden. Im Gegensatz zu DVB-C oder DVB-S2, wird hier nicht jedem Kunden alles geschickt, um sich auszusuchen, was man anschaut. Man bekommt nur das geliefert, was auch tatsächlich angesehen wird. Multicasts erlauben hier die effiziente Verteilung von Paketen, ohne das eigene Netz zu überlasten.

Damit Multicasts funktionieren, muss auch die lokale Netzwerk-Hardware mitspielen. Darum empfiehlt die Telekom u.A. ihre IPTV-Receiver direkt mit dem Router zu verbinden. Das ist sicher kein Problem, wenn der Telefonanschluss im Wohnzimmer ist, aber gerade in älteren Wohnungen, ist das eher selten der Fall und Kabelkanäle sind auch rar. Sobald Switches oder Access Points ins Spiel kommen, müssen die Geräte das Internet Group Multicast Protocol in Version 3 (IGMPv3) unterstützen. Wenn sie das nicht tun, wird aus dem Multicast ein Broadcast an alle Geräte ins Netzwerk. Bei einem HD-Stream mit 10 Mbit/s und 20 Geräten im Netzwerk, würde man so 200 Mbit/s Last erzeugen. Das mag im LAN noch evtl. verschmerzbar sein, aber in einem WLAN sieht die Sache anders aus. Leider unterstützt insbesondere Consumer-Netzwerk-Hardware oft kein IGMP oder nur eine ältere Version, die ebenfalls ins Broadcasts resultiert.

Eine wirklich günstige Lösung gibt's dafür leider nicht. Man kann sich entweder mit entsprechend IGMP-fähiger Hardware helfen oder mit einem separaten Netz über ein VLAN. Dummerweise unterstützten Consumer-Geräte meist auch keine VLANs.

Ohne Managed Switches, die IGMPv3 und/oder VLANs unterstützen, kommt man hier leider nicht weit. Mein Netzwerk besteht daher nur noch aus Netzwerk-Hardware von Ubiquiti: ein EdgeRouter X, drei UniFi Switches und zwei UniFi Access Points.

## Konfiguration

Folgende Punkte beschreiben die Konfiguration der UniFi-Hardware und des EdgeRouters. Wie immer gilt: ich verwende einen EdgeRouter X, aber es sollte auch problemlos mit jedem anderen EdgeRouter funktionieren.

### UniFi

Der einfache Teil vorweg: für die UniFi-Geräte reicht es, IGMP Snooping in den Einstellungen unter `Networks` bzw. `Wireless Networks` für das jeweilige Netz zu aktivieren und die Geräte neu zu provisionieren.

Falls jemand ein UniFi Security Gateway als Router verwenden sollte, müssen noch weitere Einstellungen im CLI des Controllers vorgenommen werden, damit der IGMP Proxy läuft. Eine Anleitung dazu gibt's [hier](https://schreibers-blog.de/entertain-mit-unifi-hardware-und-switch/).

### EdgeRouter

Wie auch für das USG gilt, dass auf dem EdgeRouter ein IGMP Proxy laufen muss. Das verlangt Einstellungen, die nur über das CLI erfolgen können. Der Einfachheit halber, werde ich auch die entsprechenden Firewall-Regeln über das CLI beschreiben, da man die einfach kopieren und nach seinen Wünschen anpassen kann -- im Gegensatz zu einer Screenshot-Orgie.

#### Firewall

Grundsätzlich sollte jeder EdgeRouter min. zwei Firewall-Rulesets haben, in und local. Bei mir heißen sie `WAN_IN` sowie `WAN_LOCAL` und werden daher auch in diesem Beispiel verwendet. Das Modem hängt an `eth0` und die Verbindung wird über `eth1` ins restliche Netzwerk verteilt.

Die folgenden Firewall-Regeln richten sich an Nutzer von EntertainTV bzw. Telekom-Kunden im BNG. Wer noch nicht im BNG ist bzw. das alte Entertain nutzt, muss teilweise andere IP-Adressen freigeben und dazu VLAN 8 verwenden, weil im alten Netz die Internetverbindung (VLAN 7) und Entertain (VLAN 8) getrennt laufen, siehe den [Beitrag von TauSys](https://blog.tausys.de/2016/02/22/edgerouter-am-telekom-internetanschluss-mit-entertain-und-ipv6/).

Als erstes müssten IGMP und Multicast UDP-Pakete für `WAN_IN` erlaubt werden:

~~~ sh
set firewall name WAN_IN rule 1 action accept
set firewall name WAN_IN rule 1 description 'Allow IGMP'
set firewall name WAN_IN rule 1 log disable
set firewall name WAN_IN rule 1 protocol igmp
set firewall name WAN_IN rule 2 description 'Allow IPTV Multicast UDP'
set firewall name WAN_IN rule 2 destination address 224.0.0.0/4
set firewall name WAN_IN rule 2 log disable
set firewall name WAN_IN rule 2 protocol udp
~~~

Anschließend werden Multicast UDP-Pakete lokal für `WAN_LOCAL` erlaubt:

~~~ sh
set firewall name WAN_LOCAL rule 1 action accept
set firewall name WAN_LOCAL rule 1 description 'Allow Multicast'
set firewall name WAN_LOCAL rule 1 destination address 224.0.0.0/4
set firewall name WAN_LOCAL rule 1 log disable
set firewall name WAN_LOCAL rule 1 protocol all
~~~

Bitte beachtet, dass die Reihenfolge der Regeln entsprechend passt und die neuen Regeln immer vor der Drop-Regel stehen, die nicht erlaubte Pakete entsorgen soll.

Was hat es mit dem Netz `224.0.0.0/4` auf sich? Sehr vereinfacht gesagt: ein Bereich bestimmter IPv4-Adressen, die für Multicast-Verwaltung genutzt werden können.

#### IGMP Proxy

Der schon mehrfach genannte IGMP Proxy ist ein vergleichsweise simples Tool, um IGMP-Pakete an die entsprechenden Stellen weiterzuleiten. Ohnehin würden die Pakete im Router quasi hängenbleiben.

~~~ sh
set protocols igmp-proxy interface eth1 alt-subnet 0.0.0.0/0
set protocols igmp-proxy interface eth1 role downstream
set protocols igmp-proxy interface eth1 threshold 1
set protocols igmp-proxy interface eth1 whitelist 232.0.0.0/16
set protocols igmp-proxy interface pppoe0 alt-subnet 0.0.0.0/0
set protocols igmp-proxy interface pppoe0 role upstream
set protocols igmp-proxy interface pppoe0 threshold 1
~~~

Das Beispiel geht davon aus, dass die restlichen Geräte über `eth1` am EgdeRouter hängen. Falls jemand ein VLAN verwendet, wie ich es im vorherigen Post beschrieben habe, muss an das Interface noch die VLAN-ID angehängt werden, z.B. `eth1.10`.

Entertain bzw. EntertainTV funktionieren aktuell nur via IPv4, daher ist eine IPv6-Konfiguration nicht notwendig.

Das war's eigentlich schon. Ihr müsst nur noch einen Commit machen und speichern. Der IGMP Proxy sollte damit automatisch starten.

Ich hatte die ganze Konfiguration bereits anhand diverser Blog- und Foren-Posts im Vorraus gemacht und erstaunlicherweise hat sie auf Anhieb funktioniert. Es treten keinerlei Broadcast-Probleme auf. 

Falls Ihr den Verdacht habt, das lässt sich mit Wireshark sehr einfach überprüfen: einfach die aktive Netzwerk-Schnittstelle abfragen und auf Broadcasts bzw. ungewöhnlich viele UDP-Pakete achten, die von den EntertainTV-IP-Adressen kommen.

Wer Interesse hat, einen EdgeRouter X oder ein anderes der genannten Geräte zu kaufen und mich unterstützen möchte, kann folgende Amazon-Links benutzen. Vielen Dank!

[DrayTek Vigor 130](https://www.amazon.de/gp/product/B00F9E5LQA/ref=as_li_tl?ie=UTF8&camp=1638&creative=6742&creativeASIN=B00F9E5LQA&linkCode=as2&tag=web0b0-21)

[Ubiquiti EdgeRouter X](https://www.amazon.de/gp/product/B011N1IT2A/ref=as_li_tl?ie=UTF8&camp=1638&creative=6742&creativeASIN=B011N1IT2A&linkCode=as2&tag=web0b0-21)

[Ubiquiti UniFi AP AC Lite](https://www.amazon.de/Ubiquiti-Networks-2-4GHz-867Mbit-UAP-AC-LITE/dp/B016K4GQVG/ref=as_li_ss_tl?ie=UTF8&qid=1517615751&sr=8-1&keywords=unifi+ap+lite&dpID=31oux4k0ZCL&preST=_SY300_QL70_&dpSrc=srch&linkCode=ll1&tag=web0b0-21&linkId=4062e73def8bd2b9986a2077a000be6d)

[Ubiquiti UniFi US-8](https://www.amazon.de/Ubiquiti-Networks-US-8-UniFiSwitch-8/dp/B01N362YPG/ref=as_li_ss_tl?s=computers&ie=UTF8&qid=1517615825&sr=1-1&keywords=unifi+us-8&dpID=41tiJ33jrSL&preST=_SX300_QL70_&dpSrc=srch&linkCode=ll1&tag=web0b0-21&linkId=aaea6f79bbb3f230cf761ddd61e4f8a8)

[Ubiquiti UniFi US-8-60W POE](https://www.amazon.de/Ubiquiti-US-8-60W-UniFi-Switch-Grau/dp/B004BQCKXO/ref=as_li_ss_tl?s=computers&ie=UTF8&qid=1517615825&sr=1-2&keywords=unifi+us-8&dpID=31ilOcMTfRL&preST=_SX300_QL70_&dpSrc=srch&linkCode=ll1&tag=web0b0-21&linkId=fae5ac376c34e72a5c9d21332ea77898)
