---
date: 2018-02-28T18:00:00+01:00
title: Telekom VDSL MTU und MSS Clamping für IPv4 und IPv6
---
Wer schon mal in die USA geflogen ist, kennt sicher das Electronic System for Travel Authorization (ESTA). Jeder Fluggast, der in USA einreist, umsteigt oder sie sogar nur überfliegt, muss sich dort anmelden und eine Erlaubnis einholen. Dieser Spaß kostet 14 US-Dollar und wird via `pay.gov` bezahlt.

Als ich letztes Jahr für eine Reise in USA einen ESTA-Antrag gestellt habe, war `pay.gov` für mich über die Telekom nicht erreichbar. Via Mobilfunk ging es merkwürdigerweise problemlos, also lag für mich das Problem bei der Telekom. Ein kurzer Austausch mit @telekom_hilft bei Twitter brachte leider keine Besserung, da der Zugriff `pay.gov` für den Support-Mitarbeiter einwandfrei funktionierte.

Ich hatte das Problem nicht weiter verfolgt, aber immer wieder mal ausprobiert, ob die Seite erreichbar ist. Bisher war das nie der Fall und es hat mich dann in den letzten Tagen der Ehrgeiz gepackt, endlich die Ursache zu finden.

Nach ein paar Google-Recherchen stand schnell fest, dass die Probleme nur via IPv6 auftreten. Mit IPv4 ging alles einwandfrei. Ich hatte schon früher an diese Möglichkeit gedacht, sie aber ausgeschlossen, weil die DNS-Einträge für `pay.gov` keinen AAAA Resource Record aufweist. Da mir der Browser gar nicht erst etwas anzeigt, weil die Verbindung bzw. der TLS Handshake gar nicht erst aufgebaut werden konnten, musste Wireshark ran.

Siehe da, der Zugriff erfolgt doch über IPv6 und die Pakete von `pay.gov` werden verworfen, weil sie ungültig sind. Nach weiteren Google-Suchen stand fest, dass irgendwas mit der Maximum Transfer Unit (MTU) bzw. der Maximum Segment Size (MSS) zu tun hat. Die MTU-Größe liegt bei DSL-Zugängen bei 1.492 Byte. Das errechnet sich aus dem maximalen Wert von 1.500 Byte abzüglich 8 Byte für den PPPoE-Header. Die MSS wird auf 1.452 Byte festgelegt, also 40 weitere Byte von der MTU abgezogen. 40 Byte sind die Maximallänge eines TCP/IPv4-Headers.

Ich hatte daher die MTU- und MSS-Werte im EdgeRouter überprüft und sie waren in Ordnung. Nach weiteren Recherchen war allerdings auch schnell klar, dass der EdgeRouter den Wert für MSS Clamping standardmäßig nur für IPv4 einstellt. Via CLI habe ich daher die Konfiguration für IPv6 nachgeholt. Und? Nichts, immer noch tot. Toll.

Blöderweise hatte ich verpennt, dass TCP/IPv6-Header eine maximale Länge von 60 Byte haben können und daher die MSS auf 1.432 Byte gestellt werden muss. Kaum war das erledigt, ließ sich `pay.gov` problemlos aufrufen.

Dieses Problem betrifft offenbar alle Seiten der US-Regierung unter der TLD `.gov`. Eigentlich sollte das so nicht passieren, da normalerweise der Client via ICMP übermitteln kann, dass die Pakete zu groß sind und der Server bitte kleinere schicken soll. Dummerweise lassen alle Seiten der US-Regierung überhaupt kein ICMP zu. Kann ich verstehen, aber in der Hinsicht ist's wirklich dumm, eben weil ICMP für IPv6 eine enorm wichtige Rolle spielt.

## TL;DR

Sollte jemand merkwürdige Probleme mit nicht aufrufbaren Websites haben oder immer wieder bestimmte Seiten beim ersten Laden sehr lange brauchen, z.B. weil der TLS-Handshake ungewöhnlich viel Zeit beansprucht, kann es ein Problem mit dem MSS Clamping sein.

Für IPv4 sollte es der EdgeRouter bereits richtig einstellen. Für IPv6 lässt es sich, wie üblich, nur via CLI konfigurieren:

~~~ sh
set firewall options mss-clamp6 interface-type pppoe
set firewall options mss-clamp6 mss 1432
~~~

Für IPv4 sollte es so aussehen:

~~~ sh
ubnt@ubnt# show firewall options mss-clamp
 interface-type pppoe
 mss 1452
~~~

Statt dem Interface Type `pppoe` kann auch `all` aktiv sein, das betrifft dann z.B. auch relevanten VPN-Protokolle.

Commit und speichern, Problem gelöst.
