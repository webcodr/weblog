---
date: 2013-02-02T22:28:05+01:00
title: Array almighty
---
Wenn man sich zulange nur mit PHP beschäftigt vergisst man schnell, dass man oft Dinge tut, die kaum in andere Sprachen übertragbar sind.

Letztens habe ich mir Scala etwas näher angesehen. Kurz am Rande: eine schöne Sprache, wenn auch die verschiedenen Syntax-Modi etwas verwirrend oder zumindest recht gewöhnungsbedürftig sind.

## Vorteil PHP

Scala bietet wie fast jede andere typisierte Sprache verschiedene Listen-Klassen für diverse Nutzungsfälle. In PHP gibt es das nicht. Man hat sein Array, das jederzeit veränderlich ist, jede noch so wilde Mischung von Datentypen akzeptiert und assoziative Schlüssel erlaubt. Es ist einfach umgemein praktisch.

## Vorteil Scala

Da PHP leider weit davon entfernt ist vollständig objekt-orientiert zu sein und darum ein Array leider keine Objekt ist, kann man Arrays nur mit diversen Funktionen bearbeiten.

Zwar funktioniert das einwandfrei, ist aber umständlich. Ein Array-Objekt, das entsprechende Methoden bietet, die sich am besten auch noch verkettet aufrufen lassen, wäre doch toll.

## PHP goes Scala/Java/Objective-C

Daher habe ich mich ans Werk gemacht und die bereits existierende Klasse `IterateableList` in MongoAppKit in drei neue Klassen des Namespaces `\MongoAppKit\Collection` aufgeteilt: `MutableMap` und `ArrayMap`.

Die Namen orientieren sich an ihren Pendants in Scala, Java oder auch Objective-C. Während alle die SPL-Interfaces `Countable` und `IteratorAggregate` implementieren, verwendet `ArrayMap` zusätzlich das Interface `ArrayAccess` und kann damit wie ein PHP-Array verwendet werden.

Außerdem implementieren alle drei die Magic Methods `__get()`, `__set()`, `__isset()` und `__unset`. Das erleichtert z.B. die Verwendung einer Liste in Twig, in dem keine Methode mehr angesprochen werden muss, um innerhalb eines Templates auf die Inhalte zuzugreifen.

Um diverse Array-Funktionen von PHP abzubilden implementieren alle drei die Methoden:

- `first()`: gibt das erste Element der Liste zurück
- `last()`: gibt das letzte Element der Liste zurück
- `reverse()`: dreht die Reihenfolge der Elemente innerhalb der Liste um
- `each()`: wendet eine Callback-Funktion mittels `array_walk` auf alle Elemente an, in der auch auf die Schlüssel zugegriffen werden kann
- `map()`: wendet eine Callback-Funktion mittels `array_map` auf alle Elemente an
- `slice()`: schneidet einen Teil der Elemente heraus und gibt sie in einem neuen Listen-Objekt zurück
- `filter()`: filtert die Elemente einer Liste anhand einer Callback-Funktion und gibt das Ergebnis in einem neuen Listen-Objekt zurück

## Fluent Interface

Um eine Verkettung von Methodenaufrufen zu ermöglichen gibt jede Methode, die sonst keinen Rückgabewert hätte, eine Referenz auf ihre Klasse zurück. Nur `slice()` und `filter()` geben eine neue Liste mit den herausgeschnittenen bzw. gefilterten Werten zurück.

Hier ein kleines Beispiel aus CodrPress, was man damit alles anstellen kann:

~~~ php
<?php

Post::where()->each(function($document) use ($app) {
    $md = $document->getProperty('body');
    $html = $app['markdown']->transform($md);
    $document->set('body_html', $html)->save();
});
~~~

Die statische Methode `Post::where()` liefert ohne Quert alle Posts als MutableMap-Objekt zurück. Auf die Rückgabe lässt sich sofort `each()` anwenden, das alle Elemente der Liste iteriert und die definierte Closure auf jedes Element einzeln anwendet.

In diesem Fall wird das rohe Markdown aus dem Feld `body` in HTML transformiert und im Feld `body_html` abgespeichert.

## Fazit

`MutableMap` und seine Sub-Klassen sparen viel Schreibarbeit durch ein simples und komfortables Fluent Interface -- einer Vorgehensweise, der in PHP leider viel zu wenig Beachtung geschenkt wird.

## Download

Die drei Klassen sind nicht länger Teil von MongoAppKit. Ich habe sie in ein separates [GitHub-Repository](https://github.com/WebCodr/Collection) und [Composer-Paket](https://packagist.org/packages/webcodr/collection) ausgelegt, um eine unkomplizierte Nutzung ohne MongoAppKit zu ermöglichen. Viel Spaß!
