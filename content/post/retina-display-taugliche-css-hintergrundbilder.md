---
date: 2012-08-12T22:22:40+01:00
title: "Retina-Display-taugliche Icons mit CSS-Hintergrundbildern"
---
Besitzer von Apple-Geräten mit Retina-Displays kennen das Dilemma: auf vielen Seiten sehen Hintergrundbilder, insbesondere Icons, reichlich unscharf aus. So erging es mir gleich doppelt mit meinem privaten Blog. Dank neuem iPad und MacBook Pro, vermatschen die Icons für externe Links.

Es gibt verschiedene Lösungsansätze für dieses Problem, beispielsweise Icons in vektorbasierten Formaten (SVG), die beliebig in jeder Pixeldichte skalieren können.

Da ich die [verwendeten Icons](http://www.iconarchive.com/show/farm-fresh-icons-by-fatcow.html) nur als Bilder vorliegen habe, kommt diese Lösung nicht in Betracht. Dank CSS-Media-Queries ist das aber kein großes Problem.

## Media-Queries?

Ein Media-Query ermöglicht es, innerhalb eines Stylesheets diverse Informationen zum aktuellen Anzeigegerät abzufragen. Dazu gehören unter Anderem die Minimal-Breite, die Ausrichtung (Portrait, Landscape), der Gerätetyp (Screen, Projection etc.), das Bildverhältnis oder in diesem Fall besonders wichtig, das Verhältnis zwischen vorhandenen und tatsächlich dargestellten Pixeln.

## Was machen eigentlich Retina-Displays?

Retina-Displays verdoppeln die Auflösung, während die dargestellten Elemente gleich groß bleiben. Bei normalen Displays ist dieses Verhältnis 1:1. Eine Grafik mit 100 Pixeln Breite wird also mit 100 Pixeln auf dem Monitor dargestellt. Auf Apple-Geräten mit Retina-Displays verdoppeln sich die 100 Pixel auf 200 Pixel -- das Verhältnis beträgt also 2:1.

Ist eine Grafik in der notwendigen Auflösung nicht verfügbar, wird das vorhandene Bild hochgerechnet und wirkt unscharf. Mit einem Media-Query können wir dem Browser eine höher aufgelöste Version zur Verfügung stellen, die genau das verhindert.

## An die Arbeit

~~~ css
@media only screen and (min--moz-device-pixel-ratio: 2),
only screen and (-o-min-device-pixel-ratio: 2),
only screen and (-webkit-min-device-pixel-ratio: 2),
only screen and (min-device-pixel-ratio: 2) {
	#content article .content p a.external {
		background-image: url("icons/external-url-32.png");
		background-size: 16px auto;
	}
}
~~~

Da die Media-Query-Eigenschaft `min-device-pixel-ratio` noch nicht vollständig in allen Browsern implementiert ist, setze ich die entsprechenden Präfix-Versionen vorher ein. So kann man sichergehen, dass die proprietäre als auch die standardisierte Eigenschaft greifen -- je nach aktuellem Stand der Browser-Implementation.

Mozilla greift hier zu einer recht seltsamen Präfix-Syntax, während Opera und Webkit sich an das bewährte Schema halten. Ob und wann der Internet Explorer die Eigenschaft unterstützt, konnte ich bisher nicht herausfinden.

Wie oben schon beschrieben, ist das Verhältnis von tatsächlichen Pixeln zu dargestellten Pixeln 2:1, daher wird es in der Bedingung mit einer `2` angegeben.

Innerhalb des Media-Queries kann ganz normales CSS verwendet werden. Ich tausche nun einfach das bisherige Hintergrundbild (16 x 16 Pixel) durch eine größere Version (32 x 32 Pixel) aus und setze die Größe des Hintergrundbildes auf 16 Pixel. Ansonsten würde der Browser eine falsche Annahme treffen und das Bild auf 64 x 64 Pixel hochrechnen. Damit wäre alles für die sprichwörtliche Katz.

Das war's schon. Sofern man ein passendes Gerät hat und der Browser die Media-Query-Eigenschaft unterstützt, bekommt man nun ein schön hoch aufgelöstes Icon zu sehen, das um Welten besser aussieht als der hochgerechnete Pixelmatsch.
