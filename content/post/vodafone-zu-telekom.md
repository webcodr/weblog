---
date: 2017-01-07T21:00:00+01:00
title: Adios, Kabel-Internet
---
Wie im Guide zum Vigor 130 bzw. EdgeRouter X schon angedeutet, bin ich von meiner bisherigen Vodafone/Kabel Deutschland-Verbindung zur Telekom mit VDSL 100 gewechselt.

Damit halbiert sich mein Downstream, da Vodafone hier 200 Mbit/s anbietet und VDSL mit Vectoring bekanntlich nur max. 100 Mbit/s hergibt. Als Trostpflaster gibt's aber immerhin 15 Mbit/s mehr Upstream.

Für Entscheidung war das aber alles zweitranging. In den letzten Monaten gab es immer mehr Probleme mit der Kabel-Verbindung, sei's durch merkwürdiges Verhalten der Fritzbox 6490, zunehmender Last im Kabelsegment oder mit Routing/Peering der Kabel-Infrastruktur.

Gerade letzteres habe ich eigentlich erst richtig gemerkt, als der Vergleich zur Telekom möglich war.

Die Symptome:

- Als der Anschluss auf 200 Mbit/s geschaltet wurde, waren stabile Downloadraten von 23 - 25 MB/s in Steam die Regel. Inzwischen sind sie nur noch die Ausnahme und nur außerhalb der Hauptlastzeiten möglich. Gilt nicht nur für Steam, generell für alle Downloads.

- Wenn Steam die Bandbreite nicht auslasten kann, öffnet es zusätzliche TCP-Verbindungen. Können schon mal an die 50 - 70 Stück sein. Ab dem Punkt steigt   die Fritzbox langsam aus, weil sie mit NAT nicht mehr hinterher kommt. Ping-Zeiten steigen deutlich an, Surfen nebenbei macht keinen Spaß mehr ... der EdgeRouter X lächelt dank Hardware-NAT nur müde.

- Teils massive Probleme mit Ping-Zeiten und Packet Loss in Battlefield 1, manchmal völlig unspielbar. Lag für mich immer an EA, bis ich ein paar Runden via VDSL gespielt habe ...

- Apple Music war richtig lahm, Streaming von Filmen aus dem iTunes Store war auf PC und Mac ein Graus bis unbrauchbar, Downloads im App Store waren mal pfeilschnell, dann wieder unglaublich langsam usw. -- hatte ich alles auf Apple geschoben, aber wie schon bei Battlefield 1 lag's an Vodafone. Gleiches gilt auch für teils extrem langsam Downloads aus dem PlayStattion Network.

- Ich schaue gerne die Reviews von [SF Debris](http://sfdebris.com/), es war aber zunehmend schwer sich die Videos überhaupt anzusehen. Die Seite lädt im Vodafone-Netz extrem lahm und die Videos brauchen gefühlte Ewigkeit, bis mal ein bisschen matschiges 240p zu sehen ist. Über die Telekom starten die Videos sofort -- in HD.

- Vermehrt Probleme mit YouTube, manchmal so schlimm, dass selbst Videos in SD nicht mehr flüssig liefen.

- Starke Schwankungen bei den Ping-Zeiten, auch ohne Last.

Ein Vergleich:

**Vodafone**

~~~ bash
~ ❯❯❯ ping -c 100 google.de
PING google.de (172.217.21.195): 56 data bytes
64 bytes from 172.217.21.195: icmp_seq=0 ttl=53 time=21.271 ms
...
64 bytes from 172.217.21.195: icmp_seq=99 ttl=53 time=28.892 ms

--- google.de ping statistics ---
100 packets transmitted, 100 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 19.163/30.845/111.265/15.526 ms
~~~

**Telekom**

~~~ bash
~ ❯❯❯ ping -c 100 google.de
PING google.de (172.217.21.163): 56 data bytes
64 bytes from 172.217.21.163: icmp_seq=0 ttl=57 time=21.731 ms
...
64 bytes from 172.217.21.163: icmp_seq=99 ttl=57 time=21.594 ms

--- google.de ping statistics ---
100 packets transmitted, 100 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 21.482/21.760/22.146/0.156 ms
~~~

Mit IPv6 schaut's für Vodafone sogar noch etwas schlechter aus.

Diese Ping-Messungen habe ich an einem frühen Nachmittag ausgeführt, also sollte sich die Last im Segmet bzw. Netz doch in Grenzen gehalten haben.

Meine Diagnose:

1. Die Fritzbox 6490 mag für Normalnutzer okay sein, aber nicht für mich. Den Bridge-Modus lässt Vodafone leider durch Einschnitte in FritzOS nicht mehr zu und ein reines Kabelmodem für EURODOCSIS 3.0 zu finden ist ein Ding der Unmöglichkeit.

2. Mein zuständiges Kabel-Segment wird zunehmend überlastet. Früher war ich hier der einzige weit und breit mit einer Internet-Verbindung über Kabel. Da es zumindest bis Dezember 2016 auch keine Alternativen für anständige Bandbreiten gab, geht in dem Segment nun zunehmend die Post ab.

3. Das interne Routing von Vodafone geht z.T. über sehr viele Hops, sowohl mit IPv4 als auch IPv6. Das ist grundsätzlich nicht weiter schlimm, aber es erhöht die Anfälligkeit für Fehler und Packet Loss.

4. Der vermutlich schwerwiegendste Punkt: das Peering in andere Netze ist z.T. eine Katastrophe. Alle og. Probleme mit den Servern von Apple, EA, Google/YouTube, Sony usw. liegen daran. Über den Punkt kann ich nicht mehr hinwegsehen. Bandbreiten und Ping-Schwankungen sind eine Sache, aber wenn ich für mich wichtige Dienste nicht mehr richtig nutzen kann, ist der Ofen wirklich aus.

Kabel Deutschland bzw. jetzt Vodafone hatte ich fast acht Jahre ohne größere Probleme, aber da ich auch beruflich auf die Internetverbindung angewiesen bin, muss ich an der Stelle den Stecker ziehen.

Vodafone wird mit Sicherheit an den Problemen arbeiten -- dauert halt. Eine Segment-Aufteilung kann sich über mehrere Monate bis ein Jahr ziehen. Internes Routing lässt sich auch nicht von heute auf morgen verbessern, ebenso das Peering.

Man hat es hier mit den Angeboten für 200 Mbit/s bzw. in vielen Haushalten auch schon 400 Mbit/s wohl übertrieben ohne die Infrastruktur dahinter auszubauen.

Zumindest im Mobilfunk-Bereich hat Vodafone in den letzten Jahren einiges deutlich verbessert. Schaffen sie im Kabelnetz hoffentlich auch noch. Konkurrenz belebt das Geschäft.

Solange bin ich aber wieder Telekom-Kunde. VDSL mit Vectoring ist nur eine Übergangslösung bis FTTH im großen Stil kommt, aber bin nicht mehr auf ein Shared Medium wie Kabel angewiesen und ab dem MSAN hängt man im BNG, dem neuen, verdammt flotten Backbone-Netz der Telekom.

Außerdem kann ich meine Wunsch-Hardware nutzen, auch wenn es nicht viele Vectoring-taugliche DSL-Modems da draußen gibt.

Für die meisten tut's der übliche Speedport, der mir zumindest in seinem Verhalten unter Last besser gefällt als die Fritzbox. Der Vergleich hinkt natürlich etwas, da die Fritte deutlich mehr kann.

In Sachen WLAN sind sie beide ziemlich meh, besonders im Vergleich zu meinen früheren AirPorts oder jetzt UniFi Access Points -- ist natürlich wieder unfair. Gibt weit teurere Consumer-Geräte, die viel schlimmer sind, siehe [Ars Technica](http://arstechnica.com/gadgets/2016/09/the-router-rumble-ars-diy-build-faces-better-tests-tougher-competition/).