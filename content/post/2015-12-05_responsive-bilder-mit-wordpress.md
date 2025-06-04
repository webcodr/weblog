---
date: 2012-08-13T22:23:38+01:00
title: "Responsive Bilder mit WordPress"
---
Aktuell wage ich erste Gehversuche mit responsiven Layouts in meinem [WordPress-Theme](https://github.com/MadCatme/mcw-blue). Ziel der Übung ist ein smartphone-taugliches Layout. Leider macht einem WordPress die Arbeit bei Bildern unnötig schwer.

## Automatische Bildskalierung mit CSS

Bilder müssen in responsiven Layouts automatisch mit der Breite des Anzeigegeräts skalieren. Feste Breiten würden hier zwangsläufig zu Darstellungsproblemen führen. Das klingt nun komplizierter als es ist. Mit drei Zeilen CSS lassen sich Bilder abhängig von der Breite ihres Eltern-Elements automatisch skalieren.

~~~ css
img {
	max-width: 100%;
}
~~~

Ein Bild darf also maximal so breit werden, wie seine vorgesehene Weite. Schrumpft das Eltern-Element durch Verkleinern des Viewports, wird das Bild automatisch mitskaliert. Wir müssen uns also um nichts weiter kümmern, da die Browser den Rest erledigen.

## Problemfall WordPress

Leider klappt die automatische Skalierung in WordPress nicht. Wenn man in einem Beitrag Bilder einfügt, setzt WordPress automatisch das `width`- bzw. `height`-Attribut auf das `img`-Element. Sobald auch nur eines von beiden gesetzt ist, wird eine automatische Größenanpassung verhindert. Die Attribute müssen also weg.

Wie immer, gibt es dafür zig verschiedene Möglichkeiten. Beispielsweise könnte man die überflüssigen Element-Eigenschaften per jQuery-Einzeiler entfernen. Wirklich schön ist das aber nicht. Es wäre doch viel besser, wenn man WordPress dazu bringen könnte, den Quelltext gleich ohne `width` und `height` auszuliefern.

Dank des Hook-Systems in WordPress geht das mit ein paar Zeilen Code in der Datei `functions.php` des Themes:

~~~ php
add_filter('the_content', 'removeImageDimensions');

function removeImageDimensions($html) {
	return preg_replace('/(width|height)=\"\d*\"\s/', '', $html);
}
~~~

Die Funktion `removeImageDimensions()` entfernt per regulärem Ausdruck unsere unerwünchten Gäste `width` und `height`. Mittels `add_filter()` wird der WordPress-Funktion `the_content()` (gibt den Inhalt eines Beitrags aus) unsere neue Funktion als Ausgabefilter zugewiesen. WordPress führt nun bei jedem Aufruf von `the_content()` unsere neue Funktion `removeImageDimensions()` aus, die den Rückgabewert von `the_content()` entsprechend verändert.

Damit steht responsiven Bildbreiten nun nichts mehr im Weg.
