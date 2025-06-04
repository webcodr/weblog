---
date: 2013-04-06T22:29:53+01:00
title: Say Hello to Mango
---
## Was'n das?

Finger weg! Diese Mango schmeckt nicht.

Mango ist ein Object Document Mapper für MongoDB und PHP.

### Und MongoAppKit?

MongoAppKit hat ein Problem, denn es ist nicht nur ein ODM und kann noch so einiges mehr. Theoretisch kann man zwar die ODM-Komponente auch ohne den ganzen anderen Krempel nutzen, aber es bleibt eine große Abhängigkeit zu Silex, die man auch nicht so einfach wieder los wird.

Dies und das im Vergleich schlechte Handling bzw. der geringe Komfort von MongoAppKit, haben mich dazu bewogen mit Mango einen universell einsatzbaren und leicht handzuhabenden ODM zu entwickeln.

Mango wurde stark von Mongoid für Ruby inspiriert und soll dessen Funktionalität zumindest teilweise in PHP abbilden. Das ist einfacher gesagt als getan, denn Ruby bietet wesentlich elegantere Möglichkeiten diverse Probleme zu lösen, als es mit PHP derzeit machbar ist.

## Los geht's …

### Installation via Composer

~~~ bash
$ php composer.phar require webcodr/mango:*
~~~

### Ein Dokument anzulegen ist ein Kinderspiel

~~~ php
<?php

namespace MyProject\Model;

use Mango\Document;
use Mango\DocumentInterface;

class User implements DocumentInterface
{
    use Document;

    private function addFields()
    {
        $this->addField('name', ['type' => 'String']);
        $this->addField('email', ['type' => 'String']);
        $this->addField('created_at', ['type' => 'DateTime', 'index' => true, 'default' => 'now'];
        $this->addField('updated_at', ['type' => 'DateTime', 'index' => true, 'default' => 'now'];
    }
}
~~~

Es ist lediglich nötig, dass die Model-Klasse das Interface `DocumentInterface` implementiert und den Trait `Document` einbindet. In der Hook-Methode `addFields()` werden anschließend noch die Felder des Dokuments deklariert.

Mango nutzt etwas Magic: Der Klassenname des Models ist gleichzeitig auch der Name der Collection (klein geschrieben). Soll die Collection anders heißen bzw. das Model eine vorhandene nutzen, muss lediglich die Methode `getCollectionName()` überschrieben werden.

### Go, Mango, go!

~~~ php
<?php

use Mango\Mango;
use Mango\DocumentManager;

use Document\User;

$mango = new Mango('mongodb://localhost/galactica');
$dm = new DocumentManager($mango);
$user = new User();
$user->name = 'William Adama';
$user->email 'william.adama@bsg-75.mil';
$user->store();
~~~

Das Mango-Object erwartet eine gültige MongoDB URI, falls notwendig inkl. Benutzer, Passwort, Port usw.

Dem Document Manager kommt eine vergleichbare Aufgabe zu, wie dem Entity Manager in Doctrine2.

Für mehr Komfort holt sich eine Model-Klasse den Document Manager über eine statische Methode ab. Daher können Methoden wie `store()` direkt über die Model-Klasse abgewickelt werden.

### Dokumente abfragen

~~~ php
<?php

$user = User::where(['name' => 'William Adama']);
echo $user->count(); // = 1
echo $user->first()->email; // = william.adama@bsg-75.mil
~~~

Eine Abfrage kann einfach über die statische Methode `where()` ausgeführt werden. Die Syntax der Abfragen entspricht derzeit noch der normalen MongoDB Query API. Für die Zukunft plane ich aber eine Abstraktionsebene für die Abfragen, vergleichbar mit Mongoid.

Eine Abfrage kit `where()` oder `find()` gibt immer ein Cursor-Objekt zurück, das anhand der aufgerufenen Methode entscheiden kann, ob der Zugriff auf den MongoCursor oder das Abfrageergebnis in Form einer Instanz von MutableMap erfolgt.

In obigem Beispiel ist `count()` eine Methode des Cursors, während `first()` schon auf der Ergebnis zugreift. Wie MongoCursor kann auch die Cursor-Klasse von Mango einfach über das Ergebnis iterieren.

Durch die dynamische Unterscheidung zwischen MongoCursor- und Datenzugriff, können auf eine Instanz der Cursor-Klasse auch alle Methoden von MutableMap angewandt werden.

Beispielsweise:

~~~ php
<?php

User::where()->reverse()->slice(0, 2)->each(function($document) {
    echo $document->name;
});
~~~

Natürlich macht dieser Code wenig Sinn, da man das wesentlich effizienter über die Cursor-Methoden erledigen kann. Das Beispiel soll lediglich zeigen, was möglich wäre.

### Hydration

Mango sorgt automatisch dafür, dass die Dokumente im Ergebnis immer Instanzen ihrer jeweiligen Model-Klasse sind.

Die Hydration-Automatik sorgt außerdem dafür, dass die Daten intern als jeweilige Typ-Klasse von Mango gehalten werden.

Typ-Klassen halten die Daten und können sie in zwei Formaten zurückgeben. Konfiguriert man ein Feld als `DateTime` bekommt Mango intern beim Speichern automatisch ein MongoDate-Objekt. Greift man hingegen außerhalb von Mango auf den Wert zu, bekäme man in diesem Fall eine Instanz der Klasse DateTime zurück.

Soweit zum aktuellen Funktionsumfang von Mango. Es ist bei weitem noch nicht fertig, kann aber für kleine Projekte schon einsetzt werden. Ich verwende es selbst in der aktuellsten Version von CodrPress und es macht wesentlich mehr Spaß als MongoAppKit, ohne ein monströses Schlachtschiff wie Doctrine zu sein.

Natürlich gibt's Mango auch bei [GitHub](https://github.com/WebCodr/Mango).
