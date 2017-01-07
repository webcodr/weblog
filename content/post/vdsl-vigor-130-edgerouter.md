---
date: 2017-01-07T16:00:00+01:00
title: VDSL via Vigor 130 und EdgeRouter X
---
Meine Fritzbox 6490 ging mir ja schon länger auf den Zeiger, aber seit ca. acht Wochen geht auch die Verbindung von Vodafone bzw. Kabel Deutschland zunehmend zum Teufel. Passenderweise hat die Telekom hier vor ein paar Wochen den VDSL-Ausbau inkl. Vectoring abgeschlossen. Seit dem 4.1. steht die Leitung und ich bin bisher äußerst angetan. Es halbiert sich zwar die Bandbreite auf 100 Mbit/s down (dafür gibt's 40 statt 25 Mbit/s up), dafür ist die Leitung wesentlich stabiler. Genauers dazu schreibe ich in einem separaten Blog-Post in Kürze.

## Bisheriges Netzwerk

Die Internet-Verbindung wird über die Fritzbox 6490 aufgebaut, die sonst außer VoIP nichts tut. An der Fritte hängt mein Ubiquiti EdgeRouter X, der dann das eigentliche Netzwerk aufbaut. Das Netz verteilt sich vom Wohnzimmer aus über drei SoHo-Switches von Cisco und zwei Ubiquiti UniFi AC Lite Access Points an die jeweiligen Endgeräte.

Diese Konstellation führt zu doppeltem NAT. Hässlich, aber auch nicht weiter tragisch. Der EdgeRouter X kann Hardware-NAT und kostet höchstens 400 - 500 µs. Ein geringer Aufpreis für wesentlich mehr Kontrolle über mein Netzwerk. Nur die IPv6-Konfiguration zwischen Fritbox und EdgeRouter wollte einfach nicht klappen -- diese unendliche Geschichte will ich hier aber nicht weiter ausbreiten, hat sich eh erledigt.

## Neues Netzwerk

Mit VDSL sieht die Sache natürlich etwas anders aus. Der Telefonanschluss ist im Flur, also mussten erstmal Kabel gelegt werden ... bei dem Thema sind Mietwohnungen dezent scheiße. Von Kabelkanälen hatte zum Bauzeitpunkt kein Mensch was gehört.

Zum Testen der Verbindung kam erstmal ein Speedport 724 V von der Telekom zum Einsatz. Klingt doof? So übel ist die Kiste gar nicht, allerdings ging's auch nur mit doppeltem NAT, weil die Speedports leider keinen Modem-Betrieb mehr können und generell ist mein Nutzungsprofil doch etwas anspruchsvoller. Daher habe ich einen Vigor 130 von DrayTek gekauft und als Vectoring-taugliches VDSL-Modem im Einsatz. Der EdgeRouter wird nun einfach per PPPoE über den Vigor versorgt.

## Konfiguration

Kommen wir zum Herzstück des Posts, denn die Konfiguration ist zwar grundsätzlich einfach, hat aber auch ein paar Tücken -- insbesondere wenn IPv6 im Spiel ist.

### DrayTek Vigor 130

Der gute Vigor wird bereits als Modem inkl. VLAN-Tagging für die Telekom vorkonfiguriert geliefert. Man muss eigentlich nur die neueste Firmware einspielen und das war's.

### Ubiquiti EdgeRouter

Ausgangsbasis ist der EdgeRouter X mit EdgeOS 1.9.1. Es sollte grundsätzlich genauso mit einem größeren EdgeRouter und neueren EdgeOS-Versionen funktionieren.

#### Netzwerk-Setup

Ich gehe hierbei davon aus, dass jemand, der diesen Post liest zumindest Grundkenntnisse im Umgang eines EdgeRouters hat, also Default-IP, Default-Login-Daten, Web-Interface-Zugang usw.

Für die grundsätzliche Konfiguration bietet Ubiquiti zum Glück entsprechende Assistenten (Wizards) an, die den ganzen Vorgang vereinfachen und mir auch ersparen hier monströse Listings mit Firewall-Regeln zu posten.

Der Wizard "Basic Setup" macht grundsätzlich alles, was man braucht:

![EdgeRouter Screenshot 1](/images/edgerouter/1.png)

Als WAN-Port habe ich mich für `eth0` entschieden. Die Einwahl erfolgt über PPPoE mit den entsprechenden Login-Daten der Telekom. VLAN-Tagging ist hier nicht nötig, das übernimmt der Vigor bereits (VLAN 7). Die Default-Firewall sollte auf jeden Fall aktiviert werden, genauso wie DHCPv6 PD. Die Prefix Length ist mit `/56` bereits korrekt voreingestellt und auch hier gilt, dass die Firewall an sein sollte.

Die Option "Only use one LAN" wird deaktiviert. Anschließed wird das Netz für `eth1` konfiguriert. Ich nutze hier ein privates Klasse A-Netz. Für die Switching-Ports `eth2`, `eth3` und `eth4` gibt es ein separates Klasse A-Netz.

Unter "User Setup" verwende ich meine bestehenden User weiter. Sollte der EdgeRouter bisher nie konfiguriert worden sein, empfehle ich aber dringend einen neuen Nutzer mit eigenem Passwort anzulegen. Ein Router sollte nie über seine Standard-Zugangsdaten zugänglich sein.

Nach dem Speichern startet sich der EdgeRouter neu und ist anschließend über die IP 10.0.0.1 an `eth1` wieder erreichbar. Im Dashboard sollte nun relativ bald unter `pppoe0` die öffentliche IPv4-Adresse sichtbar sein und damit auch die Internet-Verbindung bestehen.

Grundsätzlich ist's damit getan, wenn einem IPv4 ausreicht.

Für mein privates Netzwerk nehme ich anschließend noch ein paar Einstellungen an der Firewall vor (Port-Weiterleitungen) und am DHCP-Server vor. Wenn man zufrieden ist, sollte man ein Backup der Konfiguration machen. Das geht unter "System" -> "Back Up Config".

#### IPv6

Leider unterstützt das Web-Interface bisher kaum IPv6, daher muss man ein paar Einstellungen via CLI vornehmen.

Unter macOS und Linux ist das einfach im Terminal im SSH möglich. Unter Windows bleibt einem aktuell nur das Linux Subsystem von Windows 10 oder ein SSH-Client wie PuTTY.

Beispiel:

~~~ bash
ssh user@10.0.0.1
~~~

Anschließend wird nach dem Passwort des Users gefragt.

Bei mir sieht die Sache so aus (Login über SSH-Alias mit Key):

~~~ bash
~ ❯❯❯ ssh edge                                                                                                                              
Welcome to EdgeOS

By logging in, accessing, or using the Ubiquiti product, you
acknowledge that you have read and understood the Ubiquiti
License Agreement (available in the Web UI at, by default,
http://192.168.1.1) and agree to be bound by its terms.

Linux 3.10.14-UBNT #1 SMP Mon Nov 14 03:56:39 PST 2016 mips
Welcome to EdgeOS
webcodr@ubnt:~$
~~~

Damit ist nun das CLI des EdgeRouters offen und man kann loslegen.

Folgendes muss eingegeben werden:

~~~
configure

set interfaces ethernet eth1 ipv6 dup-addr-detect-transmits 1
set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 interface eth1 host-address '::dead:beef'
set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 interface eth1 no-dns
set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 interface eth1 prefix-id 42
set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 interface eth1 service slaac
set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 prefix-length 56
set interfaces ethernet eth0 pppoe 0 dhcpv6-pd prefix-only
set interfaces ethernet eth0 pppoe 0 dhcpv6-pd rapid-commit enable
set interfaces ethernet eth0 pppoe 0 ipv6 address autoconf
set interfaces ethernet eth0 pppoe 0 ipv6 dup-addr-detect-transmits 1
set interfaces ethernet eth0 pppoe 0 ipv6 enable
set system offload hwnat enable
commit
save
~~~

Erläuterungen:

- `configure` startet das Konfiguration-System von EdgeOS/Vyatta
- `set interfaces ethernet eth1 ipv6 dup-addr-detect-transmits 1` legt die Anzahl fest, wie oft versucht wird doppelte IPv6-Addressen herauszufinden
- `set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 interface eth1 host-address '::dead:beef'` legt die Host-Adresse nach dem Adress-Prefix der Telekom fest. Ich finde `::dead:beef` ziemlich witzig, aber hier kann sich jeder selbst austoben, solange es im Hexadezimal-Bereich liegt.
- `set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 interface eth1 prefix-id 42` legt die Prefix-ID fest, die zusätzlich in die Adresse aufgenommen wird. Was außer 42 sollte es sonst sein? :D
- `set interfaces ethernet eth0 pppoe 0 dhcpv6-pd pd 0 interface eth1 service slaac` SLAAC steht für Stateless Address Autoconfiguration -- damit erzeugt der Port seine IP-Adresse anhand des Prefixes selbst
- `set interfaces ethernet eth0 pppoe 0 ipv6 address autoconf` aktiviert die automatische IPv6-Adress-Konfiguration für das PPPoE-Interface
- `set interfaces ethernet eth0 pppoe 0 ipv6 enable` aktiviert dann letztendlich IPv6
- `set system offload hwnat enable` aktiviert Hardware-NAT für IPv4
- `commit` wendet die neue Konfiguration an
- `save` speichert die neue Konfiguration ab

Nach `commit` starten sich die betroffenen Interfaces neu und es erfolgt eine neue Einwahl über PPPoE. Anschließend befinden sich im Dashboard unter `pppoe0` die IPv4-Adresse sowie die entsprechenden globalen und lokalen IPv6-Adressen.

Alternativ lässt sich das via CLI anschauen (außerhalb von configure):

~~~ bash
webcodr@ubnt:~$ show interfaces
Codes: S - State, L - Link, u - Up, D - Down, A - Admin Down
Interface    IP Address                        S/L  Description
---------    ----------                        ---  -----------
...
eth1         10.0.0.1/24                       u/u  Local 2
             2003:xxxx:xxxx:xx42::dead:beef/64
...
~~~

Alle Geräte im Netzwerk sollten nun eine oder mehrere IPv6-Adressen besitzen und via IPv6 ins Internet kommen. Das lässt sich sehr einfach über die Seite [ipv6-test.com](http://ipv6-test.com/) herausfinden.

#### Zugang zum Vigor-Web-Interface

Da der Vigor auf der IP-Adresse `192.168.1.1` rumhängt, kommen wir nun leider erstmal nicht an sein Web-Interface ran. Das lässt sich aber recht einfach in EdgeOS ändern:

Dazu muss `eth0` (über diesen Port der EdgeRouter ja am Vigor 130) eine IP-Adresse aus Netz des Vigors zugewiesen werden. Ich verwende hier `192.168.1.2/24`.

![EdgeRouter Screenshot 2](/images/edgerouter/2.png)

Das alleine reicht noch nicht, da die NAT bisher die Verbindung in das andere Netz nicht kennt. Unter "Firewall/NAT" -> "NAT" -> "Add Source NAT Rule", trägt man daher folgendes ein und speichert.

![EdgeRouter Screenshot 3](/images/edgerouter/3.png)

Anschließend sollte der Zugriff über die IP-Adresse `192.168.1.1` auf den Vigor sofort funktionieren.

So, das war's dann eigentlich schon. Ich hoffe, diese kleine Anleitung konnte dem ein oder anderen etwas weiterhelfen.

Da nicht alles davon auf meinem Mist gewachsen ist, möchte mich an dieser Stelle noch beim Autor des Blogs [TauSys](https://blog.tausys.de) bedanken. Falls jemand in og. Konfiguration noch Entertain miteinbeziehen möchte, sei ihm dieser [Post](https://blog.tausys.de/2016/02/22/edgerouter-am-telekom-internetanschluss-mit-entertain-und-ipv6/) wärmstens empfohlen.

Wer Interesse daran hat den Vigor 130 oder den EdgeRouter X zu kaufen und mich unterstützen möchte, kann folgende Amazon-Links benutzen. Vielen Dank!

[DrayTek Vigor 130](https://www.amazon.de/gp/product/B00F9E5LQA/ref=as_li_tl?ie=UTF8&camp=1638&creative=6742&creativeASIN=B00F9E5LQA&linkCode=as2&tag=web0b0-21)

[Ubiquiti EdgeRouter X](https://www.amazon.de/gp/product/B011N1IT2A/ref=as_li_tl?ie=UTF8&camp=1638&creative=6742&creativeASIN=B011N1IT2A&linkCode=as2&tag=web0b0-21)