---
date: 2018-02-28T18:00:00+01:00
title: Telekom VDSL MTU und MSS Clamping für IPv4 und IPv6
---
[To English Version](#summary-in-english)

Wer schon mal in die USA geflogen ist, kennt sicher das Electronic System for Travel Authorization (ESTA). Jeder Fluggast, der in die USA einreist, dort umsteigt oder sie sogar nur überfliegt, muss sich dort anmelden und eine Erlaubnis einholen. Dieser Spaß kostet 14 US-Dollar und wird via `pay.gov` bezahlt.

Als ich letztes Jahr für eine Reise in USA einen ESTA-Antrag gestellt habe, war `pay.gov` für mich über die Telekom nicht erreichbar. Via Mobilfunk ging es merkwürdigerweise problemlos, also lag für mich das Problem bei der Telekom. Ein kurzer Austausch mit @telekom_hilft bei Twitter brachte leider keine Besserung, da der Zugriff auf `pay.gov` für den Support-Mitarbeiter einwandfrei funktionierte.

Ich hatte das Problem nicht groß weiter verfolgt, aber immer wieder mal ausprobiert, ob die Seite erreichbar ist. Bisher war das nie der Fall und es hat mich dann in den letzten Tagen der Ehrgeiz gepackt, endlich die Ursache zu finden.

Nach ein paar Google-Recherchen stand schnell fest, dass die Probleme nur mit IPv6 auftreten. Über IPv4 ging alles einwandfrei. IPv6 kam für mich als Ursache nicht in Frage, weil die DNS-Einträge für `pay.gov` keinen AAAA Resource Record aufweisen. Da man im Browser den Request nicht im Inspector verfolgen kann, weil die Verbindung bzw. der TLS Handshake gar nicht erst aufgebaut werden konnten, musste Wireshark ran.

Siehe da, der Zugriff erfolgt über IPv6 und die Pakete von `pay.gov` werden verworfen, weil sie ungültig sind. Nach weiteren Google-Suchen stand fest, dass die Ursachen mit der Maximum Transfer Unit (MTU) bzw. der Maximum Segment Size (MSS) zusammenhängen können. Die MTU-Größe liegt bei DSL-Zugängen bei 1.492 Byte: maximale MTU-Größe abzüglich PPPoE-Header-Größe, also 1.500 Byte - 8 Byte. Zur Berechnung des Schwellenwertes für MSS Clamping, wird von der tatsächlich MTU-Größe zusätzlich die maximale TCP/IP-Header-Größe abzogen: 1.492 Byte - 40 Byte = 1.452 Byte

Ich hatte daher die MTU- und MSS-Werte im EdgeRouter überprüft und sie waren in Ordnung. Nach weiteren Recherchen war klar, dass der EdgeRouter den Wert für MSS Clamping standardmäßig nur für IPv4 einstellt, da der Wert für IPv6 separat eingestellt werden muss. Gesagt, getan. Und? Nichts, der Verbindungsaufbau misslingt nach wie vor.

Blöderweise hatte ich vergessen, dass TCP/IPv6-Header eine maximale Länge von 60 Byte haben können und daher die MSS auf 1.432 Byte gestellt werden muss. Kaum war das erledigt, ließ sich `pay.gov` problemlos aufrufen.

Dieses Problem betrifft offenbar alle Seiten der US-Regierung unter der TLD `.gov`, kann aber auch bei anderen Websites auftreten. Es muss nicht zwangsläufig zum Totalausfall führen, da ein Client via ICMP mitteilen kann, dass der Server die Pakete weiter fragmentieren soll. In diesem konkreten Fall funktioniert das aber nicht korrekt, weil die Infrastruktur von `pay.gov` jegliche ICMP-Pakete ignoriert. Solche Maßnahmen werden oft getroffen, um kritische Systeme vor DDoS-Attacken zu schützen.

MSS Clamping ist eine Art Hack, um dieses Problem anderweitig zu lösen. Paket-Header werden bei der Verarbeitung im Router entsprechend angepasst und so dem Server mitgeteilt, dass er bitte kleinere Pakete als Antwort schicken soll.

So sehr ich die Motivation verstehe, ICMP-Pakete aus Sicherheitsgründen abzuweisen, ist es in diesem Fall eine ungünstige Entscheidung, da IPv6 für seine Funktionen wesentlich stärker von ICMP abhängig ist, als es IPv4 je war.

## TL;DR

Sollte jemand merkwürdige Probleme mit nicht aufrufbaren Websites haben oder immer wieder bestimmte Seiten beim ersten Laden sehr lange brauchen, z.B. weil der TLS-Handshake ungewöhnlich viel Zeit beansprucht, kann MSS Clamping Abhilfe schaffen.

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

Statt dem Interface Type `pppoe` kann auch `all` aktiv sein, das betrifft neben PPPoE dann z.B. auch relevanten VPN-Protokolle.

Commit und speichern, Problem gelöst.

**Hinweis:** Die MSS-Werte beziehen sich nur auf DSL-Verbindungen. Bei allen anderen Verbindungstypen, die kein PPPoE nutzen (z.B. Kabel), muss man die 8 Byte für den PPPoE-Header nicht abziehen und kommt auf auf 1.460 bzw. 1.440 Byte.

## Summary in English

Do you have strange loading problems with certain websites? They do not work at all or the first request takes a long time? Then consider MSS Clamping as a possible solution. 

In my case, `pay.gov` was impossible to reach via IPv6. If the server sends too big packets, your system can't process them correctly. Wireshark will help you to detect such faulty packets. 

MSS clamping will alter the packet headers within your router to tell the server the max allowed packet size without the usage of ICMP. It's kind of a hack, but it works fine and is sometimes the only solution, if the server blocks ICMP, as US government websites do.

In case of IPv4, the EdgeRouter's wizards did already all the work for you or you can use the MSS clamping GUI wizard after a manual configuration. Unfortunately and as always, there are no ways to configure any IPv6 features via the GUI. You have to rely on the CLI instead:

~~~ sh
set firewall options mss-clamp6 interface-type pppoe
set firewall options mss-clamp6 mss 1432
~~~

Your IPv4 MSS clamping config should look like this:

~~~ sh
ubnt@ubnt# show firewall options mss-clamp
 interface-type pppoe
 mss 1452
~~~

**Beware:** the above mentioned values are for DSL connections using PPPoE and are based on the following calculations:

- `MTU`: 1,500 bytes - 8 bytes (max. allowed MTU size - PPPoE header size) = 1,492 bytes
- `MSS`: 1,492 bytes (MTU value) - 40 bytes (TCP/IPv4 header size) or 60 bytes (TCP/IPv6 header size) = 1,452 bytes (IPv4) or 1,432 bytes (IPv6)

For other connection types without PPPoE, you don't have to subtract the PPPoE header size. Cable connections should work fine with 1,460 bytes for IPv4 and respectively 1,440 bytes for IPv6.

